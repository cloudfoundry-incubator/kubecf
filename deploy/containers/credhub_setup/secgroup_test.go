package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
)

type mockCC struct {
	*http.ServeMux
	securityGroups []*securityGroupDefinition
	defaultGroups  map[string]map[string]struct{}
}

func newMockCC() *mockCC {
	m := &mockCC{
		ServeMux: http.NewServeMux(),
		defaultGroups: map[string]map[string]struct{}{
			"staging": make(map[string]struct{}),
			"running": make(map[string]struct{}),
		},
	}
	m.HandleFunc("/v2/security_groups", m.handleNoID)
	m.HandleFunc("/v2/security_groups/", m.handleUpdate)
	m.HandleFunc("/v2/config/staging_security_groups/",
		func(w http.ResponseWriter, r *http.Request) {
			m.handleBind("staging", w, r)
		})
	m.HandleFunc("/v2/config/running_security_groups/",
		func(w http.ResponseWriter, r *http.Request) {
			m.handleBind("running", w, r)
		})

	return m
}

func (m *mockCC) handleNoID(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		m.handleList(w, r)
	case http.MethodPost:
		m.handleCreate(w, r)
	default:
		w.WriteHeader(http.StatusMethodNotAllowed)
		_, _ = w.Write([]byte(fmt.Sprintf("method %s not allowed", r.Method)))
	}
}

func (m *mockCC) handleList(w http.ResponseWriter, r *http.Request) {
	groups := make([]*securityGroupDefinition, 0, len(m.securityGroups))
	query := r.URL.Query().Get("q")
	if query == "" {
		copy(groups, m.securityGroups)
	} else {
		if !strings.HasPrefix(query, "name:") {
			w.WriteHeader(http.StatusBadRequest)
			_, err := w.Write([]byte(fmt.Sprintf("Invalid query %s", query)))
			if err != nil {
				fmt.Printf("Error writing invalid query response: %v", err)
			}
			return
		}
		query = strings.TrimPrefix(query, "name:")
		for _, group := range m.securityGroups {
			if group.Entity.Name == query {
				groups = append(groups, group)
			}
		}
	}

	result := map[string]interface{}{
		"resources": groups,
	}
	err := json.NewEncoder(w).Encode(result)
	if err != nil {
		fmt.Printf("Error writing query response: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		_, _ = w.Write([]byte(fmt.Sprintf("could not write query response: %v", err)))
		return
	}
}

func (m *mockCC) handleCreate(w http.ResponseWriter, r *http.Request) {
	newGroup := securityGroupDefinition{}
	err := json.NewDecoder(r.Body).Decode(&newGroup.Entity)
	if err != nil {
		msg := fmt.Sprintf("could not read entity: %v", err)
		fmt.Printf("%s\n", msg)
		w.WriteHeader(http.StatusBadRequest)
		_, _ = w.Write([]byte(msg))
		return
	}
	// nobody said the GUID actually has to be a GUID...
	newGroup.Metadata.GUID = fmt.Sprintf("%d", time.Now().UnixNano())

	m.securityGroups = append(m.securityGroups, &newGroup)
	w.WriteHeader(http.StatusCreated)
	err = json.NewEncoder(w).Encode(&newGroup)
	if err != nil {
		msg := fmt.Sprintf("could not write new group: %v", err)
		fmt.Printf("%s\n", msg)
		_, _ = w.Write([]byte(msg))
	}
}

func (m *mockCC) handleUpdate(w http.ResponseWriter, r *http.Request) {
	groupID := m.getGroupIDFromRequest(r)
	group, err := m.findGroupByID(groupID)
	if err != nil {
		msg := fmt.Sprintf("error finding group by ID: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		_, _ = w.Write([]byte(msg))
		fmt.Printf("%s\n", msg)
		return
	}
	if group == nil {
		msg := fmt.Sprintf("could not find group id %s", groupID)
		w.WriteHeader(http.StatusNotFound)
		w.Write([]byte(msg))
		return
	}

	err = json.NewDecoder(r.Body).Decode(&group.Entity)
	if err != nil {
		msg := fmt.Sprintf("could not read entity: %v", err)
		fmt.Printf("%s\n", msg)
		w.WriteHeader(http.StatusBadRequest)
		_, _ = w.Write([]byte(msg))
		return
	}

	w.WriteHeader(http.StatusCreated)
	err = json.NewEncoder(w).Encode(group)
	if err != nil {
		msg := fmt.Sprintf("could not write new group: %v", err)
		fmt.Printf("%s\n", msg)
		_, _ = w.Write([]byte(msg))
	}
}

func (m *mockCC) handleBind(lifeCycle string, w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}
	groupID := m.getGroupIDFromRequest(r)
	group, err := m.findGroupByID(groupID)
	if err != nil {
		msg := fmt.Sprintf("could not get group by ID %s: %v", groupID, err)
		fmt.Printf("%s\n", msg)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(msg))
		return
	}
	if group == nil {
		w.WriteHeader(http.StatusNotFound)
		return
	}
	m.defaultGroups[lifeCycle][groupID] = struct{}{}
	w.WriteHeader(http.StatusAccepted)
}

func (m *mockCC) getGroupIDFromRequest(r *http.Request) string {
	index := strings.LastIndex(r.URL.Path, "/")
	if index >= 0 {
		return r.URL.Path[index+1:]
	}
	return r.URL.Path
}

func (m *mockCC) findGroup(fn func(*securityGroupDefinition) bool) (*securityGroupDefinition, error) {
	var result *securityGroupDefinition
	for _, group := range m.securityGroups {
		if fn(group) {
			if result != nil {
				return nil, fmt.Errorf("multiple groups with same matcher")
			}
			result = group
		}
	}
	return result, nil
}

func (m *mockCC) findGroupByID(groupID string) (*securityGroupDefinition, error) {
	group, err := m.findGroup(func(group *securityGroupDefinition) bool {
		return group.Metadata.GUID == groupID
	})
	if err != nil {
		return nil, fmt.Errorf("error finding group %s by ID: %w", groupID, err)
	}
	return group, nil
}

func TestGetExistingSecurityGroup(t *testing.T) {
	t.Parallel()
	mockCCInstance := newMockCC()
	server := httptest.NewServer(mockCCInstance)
	defer server.Close()

	ctx := context.Background()
	baseURL, err := url.Parse(server.URL)
	require.NoError(t, err, "could not parse server URL")
	client := server.Client()
	groupID, err := getExistingSecurityGroup(ctx, client, baseURL)
	require.NoError(t, err, "could not get group ID")
	require.Empty(t, groupID, "got unexpected group ID")

	newEntity := buildSecurityGroup(
		[]portInfo{portInfo{addresses: []string{"1"}, port: 80}})
	entityBytes, err := json.Marshal(newEntity)
	require.NoError(t, err, "could not marshal sample data")
	entityReader := bytes.NewReader(entityBytes)
	createdID, err := createOrUpdateSecurityGroup(ctx, client, baseURL, entityReader)
	require.NoError(t, err, "could not create security group")
	require.NotEmpty(t, createdID, "empty group ID returned after creation")

	createdGroup, err := mockCCInstance.findGroupByID(createdID)
	require.NoError(t, err, "error finding group by ID")
	require.NotNil(t, createdGroup, "could not find created group")
	require.Equal(t, createdGroup.Entity, newEntity)

	updatedEntity := buildSecurityGroup(
		[]portInfo{portInfo{addresses: []string{"hello"}, port: 443}})
	entityBytes, err = json.Marshal(updatedEntity)
	require.NoError(t, err, "could not marshal sample data")
	entityReader = bytes.NewReader(entityBytes)
	updatedID, err := createOrUpdateSecurityGroup(ctx, client, baseURL, entityReader)
	require.NoError(t, err, "could not update security group")
	require.Equal(t, createdID, updatedID, "got different ID on update")

	updatedGroup, err := mockCCInstance.findGroupByID(updatedID)
	require.NoError(t, err, "error finding group by ID")
	require.NotNil(t, updatedGroup, "could not find updated group")
	require.Equal(t, updatedGroup.Entity, updatedEntity)
}

func TestSetupCredHubApplicationSecurityGroups(t *testing.T) {
	t.Parallel()

	mockCCInstance := newMockCC()
	server := httptest.NewTLSServer(mockCCInstance)
	defer server.Close()

	baseURL, err := url.Parse(server.URL)
	require.NoError(t, err, "could not parse server URL")

	endpointData := ccEndpointLinkData{}
	endpointData.CC.InternalServiceHostname = baseURL.Hostname()
	port, err := strconv.Atoi(baseURL.Port())
	require.NoError(t, err, "could not convert port number")
	endpointData.CC.PublicTLS.Port = port

	fakeMount, err := generateFakeMount("deployment-name", t)
	require.NoError(t, err, "could not set up temporary mount directorry")
	defer fakeMount.cleanup()
	err = fakeMount.writeLink("cloud_controller_https_endpoint", endpointData)
	require.NoError(t, err, "could not write fake CC mount")

	ctx := context.WithValue(context.Background(), overrideMountRoot, fakeMount.workDir)
	client := server.Client()

	err = setupCredHubApplicationSecurityGroups(ctx, client,
		[]portInfo{portInfo{addresses: []string{"1"}, port: 22}})
	require.NoError(t, err, "could not set up credhub security groups")

	group, err := mockCCInstance.findGroup(func(group *securityGroupDefinition) bool {
		return group.Entity.Name == securityGroupName
	})
	require.NoError(t, err, "could not find group %s by name", securityGroupName)
	require.NotNil(t, group, "group %s was not found", securityGroupName)
	require.Len(t, group.Entity.Rules, 1, "unexpected rules")
	rule := group.Entity.Rules[0]
	require.Equal(t, "1", rule.Destination)
	require.Equal(t, "22", rule.Ports)

	for _, lifecycle := range []string{"running", "staging"} {
		container := mockCCInstance.defaultGroups[lifecycle]
		require.Contains(t, container, group.Metadata.GUID,
			"group not set as %s", lifecycle)
	}

	// Do it again and check for updates
	err = setupCredHubApplicationSecurityGroups(ctx, client,
		[]portInfo{portInfo{addresses: []string{"irc"}, port: 6667}})
	require.NoError(t, err, "could not set up credhub security groups")

	group, err = mockCCInstance.findGroup(func(group *securityGroupDefinition) bool {
		return group.Entity.Name == securityGroupName
	})
	require.NoError(t, err, "could not find group %s by name", securityGroupName)
	require.NotNil(t, group, "group %s was not found", securityGroupName)
	require.Len(t, group.Entity.Rules, 1, "unexpected rules")
	rule = group.Entity.Rules[0]
	require.Equal(t, "irc", rule.Destination)
	require.Equal(t, "6667", rule.Ports)

	for _, lifecycle := range []string{"running", "staging"} {
		container := mockCCInstance.defaultGroups[lifecycle]
		require.Contains(t, container, group.Metadata.GUID,
			"group not set as %s", lifecycle)
	}
}
