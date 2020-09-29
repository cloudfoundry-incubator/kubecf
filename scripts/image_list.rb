# frozen_string_literal: true

require 'json'
require 'open3'
require 'set'
require 'tempfile'
require 'yaml'

# Make Hash act like OpenStruct for key lookups
class Hash
  def respond_to_missing?(symbol, _include_all)
    [symbol, symbol.to_s].any? { |key| key? key }
  end

  def method_missing(symbol, *args)
    [symbol, symbol.to_s].each do |key|
      return self[key] if key? key
    end
    super
  end

  def deep_merge!(other)
    merge! other do |_key, old, new|
      if old.respond_to? :deep_merge!
        old.deep_merge! new
      else
        new
      end
    end
  end
end

# deep_populate_nil_values is useful for setting the nil values found under the
# feature flags in the values.yaml.
def deep_populate_nil_values(hash)
  hash.each do |k, v|
    deep_populate_nil_values(v) if v.is_a?(Hash)
    hash[k] = 'kubecf' if v.nil?
  end
end

chart = ARGV.first

# Inspect the chart to obtain the values YAML.
values_stdout, status = Open3.capture2('helm', 'inspect', 'values', chart)
raise 'Could not read values' unless status.success?

values = YAML.safe_load(values_stdout)
values['releases'] ||= {}

# Process the override values file
values.deep_merge! YAML.load_file(ENV['VALUES']) if ENV.key? 'VALUES'

# Enable all tests.
values.testing.keys.each do |key|
  values.testing[key]['enabled'] = true
end

# The output object.
output = {
  # The release images.
  images: Set[],
  # The stemcells found on the images being used.
  stemcells: Set[],
  # The repository bases found on the images being used.
  repository_bases: Set[]
}

# Process the non-BOSH releases.
values.releases.each_pair do |release_name, release|
  # Filter out the '$defaults' key as it's not a release.
  next if release_name == '$defaults'

  # Filter out the releases that don't specify the 'image' key. I.e. if the
  # 'image' key is not specified, it's assumed that the release will be
  # captured in the BOSH-release processing below.
  next unless release.key?('image')

  repository_base = release.image.repository.rpartition('/').first
  output.repository_bases.add repository_base
  output.images.add "#{release.image.repository}:#{release.image.tag}"
end

# HelmRenderer renders the helm chart
class HelmRenderer
  def initialize(chart:, values:)
    @chart = chart
    @values = values
    @documents = []

    # Provide required value to avoid schema validation failure
    values['system_domain'] = 'example.com'
    # Eirini will throw an error unless a compatible stack is selected
    values['install_stacks'] = ['sle15']
    Tempfile.open(['values-', '.yaml']) do |values_file|
      values_file.write values.to_yaml
      values_file.close
      template_cmd = "helm template cf #{chart} --values #{values_file.path}"
      Open3.popen3(template_cmd) do |_, stdout, stderr, wait_thr|
        YAML.load_stream(stdout) do |doc|
          next if doc.nil?

          @documents << doc
        end
        raise stderr.read unless wait_thr.value.success?
      end
    end
  end
  attr_reader :chart, :values, :documents

  # Find a resource from the documents
  def find(kind: nil, name: nil)
    raise 'No documents' if documents.empty?

    documents.find do |doc|
      (kind.nil? || doc.kind.casecmp?(kind.to_s)) &&
        (name.nil? || doc.metadata.name == name.to_s)
    end
  end
end

### Classes to find images from specific kube types

# Generic base class
class Resource
  def initialize(resources:, doc:)
    @resources = resources
    @doc = doc
  end
  attr_reader :resources, :doc

  # images used by this resource
  def images
    []
  end

  def repository_bases
    Set.new images.map do |image|
      index = image.rindex('/')
      index.nil? ? '' : image[0..(index - 1)]
    end
  end

  # Output object compatible with the global
  def output
    { images: images, stemcells: [], repository_bases: repository_bases }
  end
end

# BOSHDeployment resources require rendering all of the ops files
class BOSHDeployment < Resource
  def manifest
    ref = doc.spec.manifest
    # ref.type is configmap/secret
    @manifest ||= resources.find(kind: ref.type, name: ref.name)
  end

  def interpolated
    return @interpolated unless @interpolated.nil?

    result = nil
    Tempfile.open(['ops-', '.yaml']) do |ops_file|
      doc.spec.ops.each do |op|
        ops_doc = resources.find(kind: op.type, name: op.name)
        contents = ops_doc.data.ops
        if contents.match?(/(?:^|\n)---/)
          raise <<~ERROR
            The ops-file #{op.name} should not have multiple YAML documents:
            #{contents}
          ERROR
        end

        ops_file.puts contents
      end

      # Interpolate the manifest using the ops-file.
      Tempfile.open(['manifest-', '.yaml']) do |manifest_file|
        manifest_file.puts manifest.data.manifest
        manifest_file.close
        interpolate_cmd = <<~CMD
          bosh interpolate #{manifest_file.path} --ops-file #{ops_file.path}
        CMD
        env = { 'HOME' => Dir.pwd }
        Open3.popen3(env, interpolate_cmd) do |_, stdout, stderr, wait_thr|
          result = stdout.read
          raise stderr.read unless wait_thr.value.success?
        end
      end
    end
    @interpolated = YAML.safe_load(result, [Symbol])
  end

  def default_stemcell
    @default_stemcell ||= interpolated.stemcells.find do |stemcell|
      stemcell.alias == 'default'
    end
  end

  def output
    @output ||= {}.tap do |result|
      result[:images] = Set.new
      result[:stemcells] = Set.new
      result[:repository_bases] = Set.new
      interpolated.releases.each do |release|
        result.repository_bases.add release.url
        stemcell = release.fetch('stemcell', default_stemcell)
        stemcell_tag = "#{stemcell.os}-#{stemcell.version}"
        result.stemcells.add stemcell_tag
        image_repository = "#{release.url}/#{release.name}"
        image_tag = "#{stemcell_tag}-#{release.version}"
        release_image = "#{image_repository}:#{image_tag}"
        result.images.add release_image
      end
    end
  end
end

# https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#podspec-v1-core
class PodSpec
  def initialize(doc:)
    @doc = doc
  end

  attr_reader :doc

  def containers
    %w[initContainers containers ephemeralContainers].flat_map do |k|
      doc.fetch(k, [])
    end
  end

  def images
    @images ||= containers.flat_map(&:image)
  end
end

# Standard classes
%w[DaemonSet Deployment Job].each do |class_name|
  Object.const_set(class_name, Class.new(Resource) do
    def images
      @images ||= PodSpec.new(doc: doc.spec.template.spec).images
    end
  end)
end

# Quarks classes
%w[QuarksJob QuarksStatefulSet].each do |class_name|
  Object.const_set(class_name, Class.new(Resource) do
    def images
      @images ||= PodSpec.new(doc: doc.spec.template.spec.template.spec).images
    end
  end)
end

# Hack for Eirini recipe images
# https://github.com/cloudfoundry-incubator/eirini-release/blob/d87444b10e17/helm/eirini/templates/configmap.yaml#L20-L34
class ConfigMap < Resource
  def images
    return [] unless doc.data.key? 'opi.yml'

    opi_config = YAML.safe_load doc.data['opi.yml']
    %w[downloader_image executor_image uploader_image].map do |key|
      opi_config.opi.fetch(key, nil)
    end.compact
  end
end

# Running through all permutations takes very long, and makes it impractical to
# add additional feature flags. Some flag combinations also could throw errors.
# So far running with features either all enabled or all disabled generates
# the complete set of used images and is nearly instantaneous.
features = values.features.keys
permutations = [false, true].map do |v|
  features.map { |x| [x, v] }.to_h
end

# Iterate over all permutations, rendering the chart to obtain all possible
# images.
permutations.each do |permutation|
  # Create the values YAML based on the current permutation.
  values = values.clone
  permutation.keys.each do |feature|
    values.features[feature]['enabled'] = permutation[feature]
  end
  # embedded_database and external_database are mutually exclusive
  # it is more likely that embedded database will require an additional
  # image than external_database.
  values.features['embedded_database']['enabled'] = true
  values.features['external_database']['enabled'] = false
  deep_populate_nil_values(values.features)

  # Render the Helm chart.
  docs = HelmRenderer.new(chart: chart, values: values)
  # Sanity check: we should have at least _one_ BDPL
  raise 'Could not find BDPL' if docs.find(kind: :BOSHDeployment).nil?

  # Iterate through all objects and get images from them if we know how
  docs.documents.each do |doc|
    next unless Object.constants.include? doc.kind.to_sym

    clazz = Object.const_get(doc.kind)
    next unless clazz.ancestors.include? Resource

    obj = clazz.new(resources: docs, doc: doc)
    output.keys.each do |key|
      output[key].merge obj.output[key]
    end
  end
end

# Convert outputs to arrays for JSON output
output.keys.each do |key|
  output[key] = output[key].to_a.sort if output[key].is_a?(Set)
end

puts output.to_json
