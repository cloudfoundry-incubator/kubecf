#!/usr/bin/env ruby

# frozen_string_literal: true

# Variable interpolation via Bazel template expansion.
helm = '[[helm]]'
install_name = '[[install_name]]'
namespace = '[[namespace]]'

args = [helm, 'delete', install_name, '--namespace', namespace]

puts "CMD #{args}"

exit Process.wait2(Process.spawn(*args)).last.exitstatus
