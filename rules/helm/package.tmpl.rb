require "fileutils"
require "open3"
require "tmpdir"

# Variables expanded by Bazel.
package_dir = "[[package_dir]]"
multipath_sep = "[[multipath_sep]]"
tarsStr = "[[tars]]"
generatedStr = "[[generated]]"
version = "[[version]]"
helm = "[[helm]]"
output_tgz = "[[output_tgz]]"

# Variables expanded by gomplate.
git_commit_short = '{{ (ds "workspace_status").STABLE_GIT_COMMIT_SHORT }}'

# Create the temporary build directory for joining all the pieces required for packaging.
tmp_build_dir = Dir.mktmpdir("build-", Dir.getwd)
begin
  build_dir = File.join(tmp_build_dir, package_dir)
  FileUtils.mkdir_p(build_dir)

  # Copy the source static files to the temporary build directory.
  Dir.glob(File.join(package_dir, "**", "*")) do |file|
    dest = File.join(tmp_build_dir, file)
    file = File.readlink(file) while File.ftype(file) == "link"
    if File.ftype(file) == "directory"
      FileUtils.mkdir_p(dest)
    else
      FileUtils.cp(file, dest)
    end
  end

  # Extract the tar files into the temporary build directory.
  tars = tarsStr.split(multipath_sep)
  tars.each do |file|
    file = File.readlink(file) while File.ftype(file) == "link"
    pid = Process.spawn("tar xf '#{file}' -C '#{build_dir}'")
    _, status = Process.wait2 pid
    exit 1 unless status.success?
  end

  # Copy the generated files into the temporary build directory.
  generated = generatedStr.split(multipath_sep)
  generated.each do |file|
    file = File.readlink(file) while File.ftype(file) == "link"
    FileUtils.cp(file, build_dir)
  end

  # A semver that matches what Helm uses.
  # https://github.com/Masterminds/semver/blob/910aa146bd66780c2815d652b92a7fc5331e533c/version.go#L41-L43
  semver_regex = /^v?([0-9]+)(\.[0-9]+)?(\.[0-9]+)?(-([0-9A-Za-z\-]+(\.[0-9A-Za-z\-]+)*))?(\+([0-9A-Za-z\-]+(\.[0-9A-Za-z\-]+)*))?$/

  # Handle chart versioning based on git state if version doesn't match semver.
  version = "v0.0.0-#{git_commit_short}" unless version.match(semver_regex)

  # Package and return the output path.
  package_cmd = <<-EOS
    '#{helm}' dep up '#{build_dir}' &&
    '#{helm}' package '#{build_dir}' \
      --version='#{version}' \
      --app-version='#{version}'
  EOS
  stdout_str, status = Open3.capture2(package_cmd)
  exit 1 unless status.success?
  package_output = stdout_str[/Successfully packaged chart and saved it to: (.*)/, 1]

  # Move the created package to the expected output tgz path provided by Bazel.
  FileUtils.mv(package_output, output_tgz)
ensure
  FileUtils.remove_entry tmp_build_dir
end
