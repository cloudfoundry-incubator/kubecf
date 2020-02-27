package cc

// secgroup.go contains the code necessary to interact with the CF API to set
// up default running / staging security groups.

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"strconv"

	"credhub_setup/pkg/quarks"
)

// securityGroupRule is a single rule in a security group definition.
type securityGroupRule struct {
	Protocol    string `json:"protocol"`
	Destination string `json:"destination"`
	Ports       string `json:"ports"`
	Log         bool   `json:"log"`
	Description string `json:"description"`
}

// securityGroupEntity is a security group definition excluding standard
// metadata.
type securityGroupEntity struct {
	Name  string              `json:"name"`
	Rules []securityGroupRule `json:"rules"`
}

// SecurityGroupDefinition is a security group definition as returned from the
// CF API.
type SecurityGroupDefinition struct {
	Metadata struct {
		GUID string `json:"guid"`
	} `json:"metadata"`
	Entity securityGroupEntity `json:"entity"`
}

// EndpointInfo describes an endpoint we should expose in the application
// security groups, consisting of a host name, a port, and a description.  The
// host name, however, is expressed as the IP addresses it resolves to.
type EndpointInfo struct {
	Addresses   []string
	Port        int
	Description string
}

// lifecycleType is the lifecycle phase of of a security group, either
// lifecycleRunning or lifecycleStaging.
type lifecycleType string

const (
	// SecurityGroupName is the name of the security group to create / update.
	SecurityGroupName = "credhub-internal"

	// The phases for the security group to bind to.
	lifecycleRunning = lifecycleType("running")
	lifecycleStaging = lifecycleType("staging")
)

// BuildSecurityGroup constructs the security group entity (as required to be
// uploaded to the CC API) for apps to be able to communicate with CredHub,
// given the addresses for CredHub and the port it's listening on.
func BuildSecurityGroup(endpoints []EndpointInfo) securityGroupEntity {
	var entries []securityGroupRule
	for _, endpoint := range endpoints {
		for _, addr := range endpoint.Addresses {
			desc := endpoint.Description
			if desc == "" {
				desc = "CredHub service access"
			}
			entries = append(entries, securityGroupRule{
				Protocol:    "tcp",
				Destination: addr,
				Ports:       strconv.Itoa(endpoint.Port),
				Description: desc,
			})
		}
	}
	return securityGroupEntity{
		Name:  SecurityGroupName,
		Rules: entries,
	}
}

// GetExistingSecurityGroup returns the GUID of the existing security group, if
// there is one; otherwise, returns the empty string.
func GetExistingSecurityGroup(ctx context.Context, client *http.Client, baseURL *url.URL) (string, error) {
	existingURL := &url.URL{
		Path: "/v2/security_groups",
	}
	existingURL = baseURL.ResolveReference(existingURL)
	query := existingURL.Query()
	query.Set("q", fmt.Sprintf("name:%s", SecurityGroupName))
	existingURL.RawQuery = query.Encode()
	fmt.Printf("Checking for existing groups via %s\n", existingURL)
	resp, err := client.Get(existingURL.String())
	if err != nil {
		return "", fmt.Errorf("failed to get existing security groups: %w", err)
	}

	var responseData struct {
		Resources []SecurityGroupDefinition `json:"resources"`
	}
	err = json.NewDecoder(resp.Body).Decode(&responseData)
	if err != nil {
		return "", fmt.Errorf("failed to get existing security groups: %w", err)
	}

	fmt.Printf("Got security groups: %+v\n", responseData)
	for _, resource := range responseData.Resources {
		if resource.Entity.Name == SecurityGroupName {
			return resource.Metadata.GUID, nil
		}
	}

	return "", nil
}

// CreateOrUpdateSecurityGroup creates a new security group, or updates an
// existing security group if one already exists.  The security group definition
// is read from the io.Reader.
func CreateOrUpdateSecurityGroup(ctx context.Context, client *http.Client, baseURL *url.URL, contentReader io.Reader) (string, error) {
	groupID, err := GetExistingSecurityGroup(ctx, client, baseURL)
	if err != nil {
		return "", err
	}
	var updateURL *url.URL
	var method string
	if groupID == "" {
		updateURL = &url.URL{
			Path: "/v2/security_groups",
		}
		method = http.MethodPost
	} else {
		updateURL = &url.URL{
			Path: fmt.Sprintf("/v2/security_groups/%s", groupID),
		}
		method = http.MethodPut
	}
	updateURL = baseURL.ResolveReference(updateURL)
	req, err := http.NewRequestWithContext(ctx, method, updateURL.String(), contentReader)
	if err != nil {
		return "", fmt.Errorf("failed to create or update security group: could not create request: %w", err)
	}
	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to create or update security group: %w", err)
	}

	if resp.StatusCode < 200 || resp.StatusCode >= 400 {
		err = fmt.Errorf("got unexpected response: %s", resp.Status)
		return "", fmt.Errorf("failed to create or update security group: %w", err)
	}

	var resultingSecurityGroup SecurityGroupDefinition
	err = json.NewDecoder(resp.Body).Decode(&resultingSecurityGroup)
	if err != nil {
		err = fmt.Errorf("failed to read response: %w", err)
		return "", fmt.Errorf("failed to create or update security group: %w", err)
	}
	fmt.Printf("Succesfully updated security group: %s / %+v\n", resp.Status, resultingSecurityGroup)

	return resultingSecurityGroup.Metadata.GUID, nil
}

// bindDefaultSecurityGroup binds the security group with the given GUID to both
// the staging and running lifecycle phases as a default security group (i.e.
// across all spaces).
func bindDefaultSecurityGroup(ctx context.Context, lifecycle lifecycleType, groupID string, client *http.Client, baseURL *url.URL) error {
	bindURL := baseURL.ResolveReference(&url.URL{
		Path: fmt.Sprintf("/v2/config/%s_security_groups/%s", lifecycle, groupID),
	})
	req, err := http.NewRequestWithContext(ctx, http.MethodPut, bindURL.String(), nil)
	if err != nil {
		return fmt.Errorf("failed to bind %s security group: could not create request: %w", lifecycle, err)
	}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to bind %s security group: %w", lifecycle, err)
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 400 {
		err = fmt.Errorf("got unexpected response: %s", resp.Status)
		return fmt.Errorf("failed to bind %s security group: %w", lifecycle, err)
	}
	fmt.Printf("Successfully bound %s security group: %s\n", lifecycle, resp.Status)
	return nil
}

// SetupCredHubApplicationSecurityGroups does all of the work to ensure an
// appropriate security group exists and is bound to the appropriate lifecycle
// phases.  It requres the addresses and port that the target (CredHub) is
// listening on.
func SetupCredHubApplicationSecurityGroups(ctx context.Context, client *http.Client, endpoints []EndpointInfo) error {
	link, err := quarks.ResolveLink(ctx, ccEntanglementName, ccEntanglementName)
	if err != nil {
		return fmt.Errorf("failed to setup security groups: %w", err)
	}

	hostname, err := link.Read("cc.internal_service_hostname")
	if err != nil {
		return fmt.Errorf("failed to setup security groups: could not read internal CC host name: %w", err)
	}
	port, err := link.Read("cc.public_tls.port")
	if err != nil {
		return fmt.Errorf("failed to setup security groups: could not read internal CC port: %w", err)
	}

	baseURL := &url.URL{
		Scheme: "https",
		Host:   net.JoinHostPort(string(hostname), string(port)),
	}

	contents := BuildSecurityGroup(endpoints)
	contentBytes, err := json.Marshal(contents)
	if err != nil {
		return fmt.Errorf("failed to setup security groups: marshaling security groups: %w", err)
	}
	contentReader := bytes.NewReader(contentBytes)

	groupID, err := CreateOrUpdateSecurityGroup(ctx, client, baseURL, contentReader)
	if err != nil {
		return fmt.Errorf("failed to setup security groups: %w", err)
	}

	for _, lifecycle := range []lifecycleType{lifecycleRunning, lifecycleStaging} {
		err = bindDefaultSecurityGroup(ctx, lifecycle, groupID, client, baseURL)
		if err != nil {
			return fmt.Errorf("failed to setup security groups: %w", err)
		}
	}

	return nil
}
