#!/usr/bin/env ruby

# frozen_string_literal: true

require 'json'

# Variable interpolation via Bazel template expansion.
helm = '[[helm]]'
install_name = '[[install_name]]'
chart_package = '[[chart_package]]'
namespace = '[[namespace]]'
install = '[[install]]' == 'True'
reuse_values = '[[reuse_values]]' == 'True'
values_paths = '[[values_paths]]'
path_split_delim = '[[path_split_delim]]'
set_values = JSON.parse('[[set_values]]')

args = [
  helm, 'upgrade', install_name, chart_package,
  '--namespace', namespace
]

args.append('--install') if install
args.append('--reuse-values') if reuse_values

values = values_paths.split(path_split_delim).map do |path|
  ['--values', path]
end
args.concat(*values)

set_values = set_values.map do |key, value|
  ['--set', "#{key}=#{value}"]
end
args.concat(*set_values)

puts "CMD #{args}"

exit Process.wait2(Process.spawn(*args)).last.exitstatus
