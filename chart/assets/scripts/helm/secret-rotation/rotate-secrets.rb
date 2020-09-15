#!/usr/bin/env ruby
# frozen_string_literal: true

# This script is used to generate a ConfigMap to rotate all secrets in the
# deployment.

require 'English'
require 'kubeclient'
require 'json'
require 'open3'
require 'time'
require 'yaml'

# SecretRotator will rotate all quarks secrets for the current deployment
class SecretRotator
  # Path to the Kubernetes API server CA certificate
  CA_CERT_PATH = '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt'

  # Path to the Kubernetes service account token
  TOKEN_PATH = '/var/run/secrets/kubernetes.io/serviceaccount/token'

  # HTTP status code when a resource already exists
  HTTP_STATUS_CONFLICT = 409

  # The namespace the QuarksSecrets is in, and the same to create the ConfigMap
  def namespace
    @namespace ||= ENV['NAMESPACE'] || raise('NAMESPACE not set')
  end

  # The BOSHDeployment name
  def deployment
    @deployment ||= ENV['DEPLOYMENT'] || raise('DEPLOYMENT not set')
  end

  # Authentication options to create a Kubernetes client
  def auth_options
    { bearer_token_file: TOKEN_PATH }
  end

  # SSL options to create a Kubernetes client
  def ssl_options
    @ssl_options ||= {}.tap do |options|
      options[:ca_file] = CA_CERT_PATH if File.exist? CA_CERT_PATH
    end
  end

  # Kubernetes client to access default APIs
  def client
    @client ||= Kubeclient::Client.new(
      'https://kubernetes.default.svc',
      'v1',
      auth_options: auth_options,
      ssl_options: ssl_options
    )
  end

  # Kubernetes client to access Quarks APIs
  def quarks_client
    @quarks_client ||= Kubeclient::Client.new(
      'https://kubernetes.default.svc/apis/quarks.cloudfoundry.org',
      'v1alpha1',
      auth_options: auth_options,
      ssl_options: ssl_options
    )
  end

  # The selector used to find interesting secrets
  def secret_selector
    "quarks.cloudfoundry.org/deployment-name=#{deployment}"
  end

  # The names of the QuarksSecrets to rotate
  def secrets
    quarks_client
      .get_quarks_secrets(namespace: namespace, selector: secret_selector)
      .map { |secret| secret.metadata.name }
  end

  # The ConfigMap resource to be created
  def configmap
    @configmap ||= Kubeclient::Resource.new(
      metadata: {
        namespace: namespace,
        # Set a unique-ish name to help running this multiple times
        name: "rotate.all-secrets-#{Time.now.to_i}",
        labels: { 'quarks.cloudfoundry.org/secret-rotation': 'true' }
      },
      data: { secrets: secrets.to_json }
    )
  end

  # Trigger rotation of all QuarksSecrets
  def rotate
    client.create_config_map configmap
  end
end

SecretRotator.new.rotate if $PROGRAM_NAME == __FILE__
