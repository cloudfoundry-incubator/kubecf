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
  def all_secrets
    quarks_client
      .get_quarks_secrets(namespace: namespace, selector: secret_selector)
      .map { |secret| secret.metadata.name }
  end

  def excluded_secrets
    [
      # Do not rotate the various CC DB encryption related secrets; that has
      # effects on the data in the databases.  These need to be rotated manually.
      /^var-ccdb-key-label/,
      'var-cc-db-encryption-key',
      # Do not rotate the PXC root password: we can't restart the database pod
      # afterwards if we do (because the database root password isn't actually
      # updated).
      'var-pxc-root-password',
      # Since we don't restart the PXC container, we can't update its CA cert.
      'var-pxc-ca'
    ]
  end

  def secrets
    all_secrets.sort.reject do |secret|
      excluded_secrets.any? { |excluded| excluded === secret } # rubocop:disable Style/CaseEquality
    end
  end

  def configmap_name
    @configmap_name ||= "rotate.all-secrets.#{Time.now.to_i}"
  end

  # The ConfigMap resource to be created
  def configmap
    @configmap ||= Kubeclient::Resource.new(
      metadata: {
        namespace: namespace,
        # Set a unique-ish name to help running this multiple times
        name: configmap_name,
        labels: { 'quarks.cloudfoundry.org/secret-rotation': 'true' }
      },
      data: { secrets: JSON.pretty_generate(secrets) }
    )
  end

  # Trigger rotation of all QuarksSecrets
  def rotate
    client.create_config_map configmap
    puts "Created secret rotation configmap #{configmap_name} with #{secrets.length} secrets:"
    secrets.each { |secret| puts "    #{secret}" }
  end
end

SecretRotator.new.rotate if $PROGRAM_NAME == __FILE__
