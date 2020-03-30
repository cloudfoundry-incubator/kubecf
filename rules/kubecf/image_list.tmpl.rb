# frozen_string_literal: true

# This is a template script to be used by the 'image_list' Bazel rule.

require 'json'
require 'open3'
require 'set'
require 'tempfile'
require 'yaml'

# deep_populate_nil_values is useful for setting the nil values found under the
# feature flags in the values.yaml.
def deep_populate_nil_values(hash)
  hash.each do |k, v|
    deep_populate_nil_values(v) if v.is_a?(Hash)
    hash[k] = 'kubecf' if v.nil?
  end
end

# Variable interpolation via Bazel template expansion.
helm = '[[helm]]'
bosh = '[[bosh]]'
chart = '[[chart]]'
output_path = '[[output_path]]'

# Inspect the chart to obtain the values YAML.
values_cmd = "#{helm} inspect values #{chart}"
values = Open3.popen3(values_cmd) do |_, stdout, stderr, wait_thr|
  values = YAML.safe_load(stdout.read)
  raise stderr.read unless wait_thr.value.success?

  values
end

# Enable all tests.
values['testing'].keys.each do |key|
  values['testing'][key]['enabled'] = true
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
values['releases'].keys.each do |release_name|
  # Filter out the 'defaults' key as it's not a release.
  next if release_name == 'defaults'

  release = values['releases'][release_name]

  # Filter out the releases that don't specify the 'image' key. I.e. if the
  # 'image' key is not specified, it's assumed that the release will be
  # captured in the BOSH-release processing below.
  next unless release.key?('image')

  image_key = release['image']
  repository = image_key['repository']
  repository_base = repository[0..(repository.rindex('/') - 1)]
  output[:repository_bases].add?(repository_base)
  tag = image_key['tag']
  image = "#{repository}:#{tag}"
  output[:images].add?(image)
end

# Create all permutations for enabling and disabling the features.
features = values['features'].keys
permutations = [true, false].repeated_permutation(features.size)
                            .map { |v| features.zip(v).to_h }

# Iterate over all permutations, rendering the chart to obtain all possible
# images.
permutations.each do |permutation|
  # Create the values YAML based on the current permutation.
  values = values.clone
  permutation.keys.each do |feature|
    values['features'][feature]['enabled'] = permutation[feature]
  end
  deep_populate_nil_values(values['features'])

  values_file = Tempfile.new('values.yaml')
  manifest_file = Tempfile.new('manifest.yaml')
  interpolated_file = Tempfile.new('manifest_interpolated.yaml')
  begin
    # Render the Helm chart.
    File.write(values_file.path, values.to_yaml)
    template_cmd = "#{helm} template cf #{chart} --values #{values_file.path}"
    template = { documents: [] }
    Open3.popen3(template_cmd) do |_, stdout, stderr, wait_thr|
      YAML.load_stream(stdout) do |doc|
        next if doc.nil?

        template[:documents].append(doc)
      end
      raise stderr.read unless wait_thr.value.success?
    end

    # Get the BOSHDeployment YAML document.
    bdpl = template[:documents].find do |doc|
      doc['kind'].downcase == 'boshdeployment'
    end

    # Get the cf-deployment manifest and write it to a temp file.
    bdpl_manifest = bdpl['spec']['manifest']
    manifest_name = bdpl_manifest['name']
    manifest_type = bdpl_manifest['type'] # configmap/secret
    manifest_doc = template[:documents].find do |doc|
      doc_kind = doc['kind'].downcase
      doc_name = doc['metadata']['name']
      doc_kind == manifest_type && doc_name == manifest_name
    end
    File.write(manifest_file.path, manifest_doc['data']['manifest'])

    # Apply the ops-files to the cf-deployment manifest.
    ops_file = Tempfile.new('ops.yaml')
    begin
      # Concatenate all ops-files referenced in the BOSHDeployment into a single
      # YAML file.
      open(ops_file.path, 'w') do |f|
        bdpl['spec']['ops'].each do |ops|
          ops_doc = template[:documents].find do |doc|
            doc_kind = doc['kind'].downcase
            doc_name = doc['metadata']['name']
            doc_kind == ops['type'] && doc_name == ops['name']
          end

          contents = ops_doc['data']['ops']
          if contents.match?(/(?:^|\n)---/)
            raise <<~ERROR
              The ops-file should not have multiple YAML documents:
              #{contents}
            ERROR
          end

          f << contents
          f << "\n"
        end
        f.close
      end

      # Interpolate the manifest using the ops-file.
      interpolate_cmd = <<~CMD
        #{bosh} interpolate #{manifest_file.path} \
          --ops-file #{ops_file.path}
      CMD
      env = { 'HOME' => Dir.pwd }
      Open3.popen3(env, interpolate_cmd) do |_, stdout, stderr, wait_thr|
        File.write(interpolated_file.path, stdout.read)
        raise stderr.read unless wait_thr.value.success?
      end
    ensure
      ops_file.close
      ops_file.unlink
    end

    # Load the interpolated manifest and calculate the BOSH releases image
    # repository and tags.
    interpolated = YAML.safe_load(File.open(interpolated_file.path), [Symbol])
    default_stemcell = interpolated['stemcells'].find do |stemcell|
      stemcell['alias'] == 'default'
    end
    interpolated['releases'].each do |release|
      output[:repository_bases].add?(release['url'])
      stemcell = release['stemcell']
      stemcell = default_stemcell if stemcell.nil?
      stemcell_tag = "#{stemcell['os']}-#{stemcell['version']}"
      output[:stemcells].add?(stemcell_tag)
      image_repository = "#{release['url']}/#{release['name']}"
      image_tag = "#{stemcell_tag}-#{release['version']}"
      release_image = "#{image_repository}:#{image_tag}"
      output[:images].add?(release_image)
    end
  ensure
    values_file.close
    values_file.unlink
    manifest_file.close
    manifest_file.unlink
    interpolated_file.close
    interpolated_file.unlink
  end
end

output.keys.each do |key|
  output[key] = output[key].to_a.sort if output[key].is_a?(Set)
end

File.write(output_path, output.to_json)
