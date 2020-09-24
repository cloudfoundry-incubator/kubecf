#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'rotate-secrets'

RSpec.describe(SecretRotator) do
  def instance
    @instance ||= described_class.new
  end

  before :each do
    # Default to having a good setup
    allow(ENV).to receive(:[]).with('NAMESPACE').and_return 'namespace'
    allow(ENV).to receive(:[]).with('DEPLOYMENT').and_return 'deployment'
    allow(File).to receive(:exist?).with(described_class::CA_CERT_PATH).and_return true
  end

  describe '#namespace' do
    it 'returns the namespace' do
      expect(ENV).to receive(:[]).with('NAMESPACE').and_return 'ns'
      expect(instance.namespace).to eq 'ns'
    end

    it 'errors out if namespace is not set' do
      expect(ENV).to receive(:[]).with('NAMESPACE').and_return nil
      expect { instance.namespace }.to raise_error(/NAMESPACE not set/)
    end
  end

  describe '#deployment' do
    it 'returns the deployment name' do
      expect(ENV).to receive(:[]).with('DEPLOYMENT').and_return 'dp'
      expect(instance.deployment).to eq 'dp'
    end

    it 'errors out if deployment name is not set' do
      expect(ENV).to receive(:[]).with('DEPLOYMENT').and_return nil
      expect { instance.deployment }.to raise_error(/DEPLOYMENT not set/)
    end
  end

  describe '#ssl_options' do
    it 'returns empty options if the CA cert is missing' do
      allow(File).to receive(:exist?).with(described_class::CA_CERT_PATH).and_return false
      expect(instance.ssl_options).to be_empty
    end

    it 'returns options with the CA cert path' do
      expect(instance.ssl_options).to eq(ca_file: described_class::CA_CERT_PATH)
    end
  end

  describe '#client' do
    it 'creates a Kubernetes client' do
      expected_client = {}
      expect(Kubeclient::Client).to receive(:new).with(
        'https://kubernetes.default.svc',
        'v1',
        auth_options: { bearer_token_file: described_class::TOKEN_PATH },
        ssl_options: { ca_file: described_class::CA_CERT_PATH }
      ).once.and_return expected_client
      expect(instance.client).to be expected_client

      # call it again should not ask for a new client
      expect(instance.client).to be expected_client
    end
  end

  describe '#quarks_client' do
    it 'creates a Kubernetes client' do
      expected_client = {}
      expect(Kubeclient::Client).to receive(:new).with(
        'https://kubernetes.default.svc/apis/quarks.cloudfoundry.org',
        'v1alpha1',
        auth_options: { bearer_token_file: described_class::TOKEN_PATH },
        ssl_options: { ca_file: described_class::CA_CERT_PATH }
      ).once.and_return expected_client
      expect(instance.quarks_client).to be expected_client

      # call it again should not ask for a new client
      expect(instance.quarks_client).to be expected_client
    end
  end

  describe '#secrets' do
    it 'returns the QuarksSecret names' do
      expected_names = %w[one two three]
      secrets = expected_names.map do |name|
        double('QuarksSecret').tap do |secret|
          expect(secret).to receive_message_chain(:metadata, :name).and_return name
        end
      end

      expect(instance)
        .to receive_message_chain(:quarks_client, :get_quarks_secrets)
        .with(
          namespace: 'namespace',
          selector: 'quarks.cloudfoundry.org/deployment-name=deployment'
        )
        .and_return(secrets)

      expect(instance.secrets).to eq expected_names
    end
  end

  describe '#configmap' do
    it 'returns the desired config map' do
      expect(instance).to receive(:secrets).and_return %w[one two]
      allow(Time).to receive(:now).and_return 123
      expect(instance.configmap.to_h).to eq(
        metadata: {
          namespace: 'namespace',
          name: 'rotate.all-secrets-123',
          labels: { 'quarks.cloudfoundry.org/secret-rotation': 'true' }
        },
        data: { secrets: %w[one two].to_json }
      )
    end
  end

  describe '#rotate' do
    it 'attempts to create a config map' do
      configmap = {}
      expect(instance).to receive(:configmap).and_return configmap
      expect(instance)
        .to receive_message_chain(:client, :create_config_map)
        .with(be(configmap))
      instance.rotate
    end
  end
end
