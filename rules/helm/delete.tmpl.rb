#!/usr/bin/env ruby

# frozen_string_literal: true

require 'open3'

# Variable interpolation via Bazel template expansion.
helm = '[[helm]]'
install_name = '[[install_name]]'
namespace = '[[namespace]]'

stdout, stderr, status = Open3.capture3(
  helm, 'delete', install_name,
  '--namespace', namespace
)
unless status.success?
  puts stderr
  exit 1
end

puts stdout
