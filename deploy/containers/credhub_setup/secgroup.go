package main

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
)

// ccEndpointLinkData describes the data returned from the cloud controller BOSH
// link (ccEntanglementName)
type ccEndpointLinkData struct {
	CC struct {
		InternalServiceHostname string `json:"internal_service_hostname"`
		PublicTLS               struct {
			CACert string `json:"ca_cert"`
			Port   int    `json:"port"`
		} `json:"public_tls"`
	} `json:"cc"`
}

// securityGroupRule is a single rule in a security group definition
type securityGroupRule struct {
	Protocol    string `json:"protocol"`
	Destination string `json:"destination"`
	Ports       string `json:"ports"`
	Log         bool   `json:"log"`
	Description string `json:"description"`
}

// securityGroupEntity is a security group definition excluding standard
// metadata
type securityGroupEntity struct {
	Name  string              `json:"name"`
	Rules []securityGroupRule `json:"rules"`
}

// securityGroupDefinition is a security group definition as returned from the
// CF API
type securityGroupDefinition struct {
	Metadata struct {
		GUID string `json:"guid"`
	} `json:"metadata"`
	Entity securityGroupEntity `json:"entity"`
}

// lifecycleType is the lifecycle phase of of a security group, either
// lifecycleRunning or lifecycleStaging.
type lifecycleType string

const (
	// The name of the security group to create / update
	securityGroupName = "credhub-internal"

	// The name of the BOSH link
	ccEntanglementName = "cloud_controller_https_endpoint"

	// The phases for the security group to bind to
	lifecycleRunning = lifecycleType("running")
	lifecycleStaging = lifecycleType("staging")
)

// buildSecurityGroup constructs the security group entity (as required to be
// uploaded to the CC API) for apps to be able to communicate with CredHub,
// given the addresses for CredHub and the port it's listening on.
func buildSecurityGroup(ports []portInfo) securityGroupEntity {
	var entries []securityGroupRule
	for _, info := range ports {
		for _, addr := range info.addresses {
			desc := info.description
			if desc == "" {
				desc = "CredHub service access"
			}
			entries = append(entries, securityGroupRule{
				Protocol:    "tcp",
				Destination: addr,
				Ports:       fmt.Sprintf("%d", info.port),
				Description: desc,
			})
		}
	}
	return securityGroupEntity{
		Name:  securityGroupName,
		Rules: entries,
	}
}

// getExistingSecurityGroup returns the GUID of the existing security group, if
// there is one; otherwise, returns the empty string.
func getExistingSecurityGroup(ctx context.Context, client *http.Client, baseURL *url.URL) (string, error) {
	existingURL := &url.URL{
		Path: "/v2/security_groups",
	}
	existingURL = baseURL.ResolveReference(existingURL)
	query := existingURL.Query()
	query.Set("q", fmt.Sprintf("name:%s", securityGroupName))
	existingURL.RawQuery = query.Encode()
	fmt.Printf("Checking for existing groups via %s\n", existingURL)
	resp, err := client.Get(existingURL.String())
	if err != nil {
		return "", fmt.Errorf("could not get existing security groups: %w", err)
	}

	var responseData struct {
		Resources []securityGroupDefinition `json:"resources"`
	}
	err = json.NewDecoder(resp.Body).Decode(&responseData)
	if err != nil {
		return "", fmt.Errorf("could not read existing security groups: %w", err)
	}

	fmt.Printf("Got security groups: %+v\n", responseData)
	for _, resource := range responseData.Resources {
		if resource.Entity.Name == securityGroupName {
			return resource.Metadata.GUID, nil
		}
	}

	return "", nil
}

// createOrUpdateSecurityGroup creates a new security group, or updates an
// existing security group if one already exists.  The security group definition
// is read from the io.Reader.
func createOrUpdateSecurityGroup(ctx context.Context, client *http.Client, baseURL *url.URL, contentReader io.Reader) (string, error) {
	groupID, err := getExistingSecurityGroup(ctx, client, baseURL)
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
		return "", fmt.Errorf("could not create update request: %w", err)
	}
	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("could not submit update request: %w", err)
	}

	if resp.StatusCode < 200 || resp.StatusCode >= 400 {
		return "", fmt.Errorf("got response %s", resp.Status)
	}

	var resultingSecurityGroup securityGroupDefinition
	err = json.NewDecoder(resp.Body).Decode(&resultingSecurityGroup)
	if err != nil {
		return "", fmt.Errorf("updated security group (%s) but failed to read response: %w", resp.Status, err)
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
		return fmt.Errorf("failed to create %s security group request: %w", lifecycle, err)
	}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("could not set %s security group: %w", lifecycle, err)
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 400 {
		return fmt.Errorf("error setting %s security group: %s", lifecycle, resp.Status)
	}
	fmt.Printf("Successfully bound %s security group: %s\n", lifecycle, resp.Status)
	return nil
}

// setupCredHubApplicationSecurityGroups does all of the work to ensure an
// appropriate security group exists and is bound to the appropriate lifecycle
// phases.  It requres the addresses and port that the target (CredHub) is
// listening on.
func setupCredHubApplicationSecurityGroups(ctx context.Context, client *http.Client, ports []portInfo) error {
	var link ccEndpointLinkData
	err := resolveLink(ctx, ccEntanglementName, &link)
	if err != nil {
		return fmt.Errorf("could not get CC link: %w", err)
	}
	baseURL := &url.URL{
		Scheme: "https",
		Host: net.JoinHostPort(
			link.CC.InternalServiceHostname,
			fmt.Sprintf("%d", link.CC.PublicTLS.Port),
		),
	}

	contents := buildSecurityGroup(ports)
	contentBytes, err := json.Marshal(contents)
	if err != nil {
		return fmt.Errorf("could not build security group definition: %w", err)
	}
	contentReader := bytes.NewReader(contentBytes)

	groupID, err := createOrUpdateSecurityGroup(ctx, client, baseURL, contentReader)
	if err != nil {
		return err
	}

	for _, lifecycle := range []lifecycleType{lifecycleRunning, lifecycleStaging} {
		err = bindDefaultSecurityGroup(ctx, lifecycle, groupID, client, baseURL)
		if err != nil {
			return err
		}
	}

	return nil
}
