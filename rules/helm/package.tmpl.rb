require "fileutils"
require "open3"

# Variables expanded by Bazel.
package_dir = "[[package_dir]]"
multipath_sep = "[[multipath_sep]]"
tarsStr = "[[tars]]"
generatedStr = "[[generated]]"
helm = "[[helm]]"
output_tgz = "[[output_tgz]]"

# Variables expanded by gomplate.
git_commit_short = '{{ (ds "workspace_status").STABLE_GIT_COMMIT_SHORT }}'
git_branch = '{{ (ds "workspace_status").STABLE_GIT_BRANCH }}'

# Create the temporary build directory for joining all the pieces required for packaging.
tmp_build_dir = File.join("tmp", "build")
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
  `tar xf "#{file}" -C "#{build_dir}"`
end

# Copy the generated files into the temporary build directory.
generated = generatedStr.split(multipath_sep)
generated.each do |file|
  file = File.readlink(file) while File.ftype(file) == "link"
  FileUtils.cp(file, build_dir)
end

`"#{helm}" init --client-only`

# Handle chart versioning based on git state.
version = "v0.0.0-#{git_commit_short}"

# A semver that matches what Helm uses.
# https://github.com/Masterminds/semver/blob/910aa146bd66780c2815d652b92a7fc5331e533c/version.go#L41-L43
semver_regex = /^v?([0-9]+)(\.[0-9]+)?(\.[0-9]+)?(-([0-9A-Za-z\-]+(\.[0-9A-Za-z\-]+)*))?(\+([0-9A-Za-z\-]+(\.[0-9A-Za-z\-]+)*))?$/
if git_branch.match(semver_regex)
  version = git_branch
end

# Package and return the output path.
package_cmd = "'#{helm}' package '#{build_dir}' --version='#{version}' --app-version='#{version}'"
package_output = Open3.popen3(package_cmd) do |stdin, stdout, stderr, wait_thread|
  stderr.each {|l| STDERR.puts l }
  status = wait_thread.value
  raise if not status.success?

  stdout.read[/Successfully packaged chart and saved it to: (.*)/, 1]
end

# Move the created package to the expected output tgz path provided by Bazel.
FileUtils.mv(package_output, output_tgz)
