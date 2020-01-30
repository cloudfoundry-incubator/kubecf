#!/usr/bin/env ruby

git_root = `git rev-parse --show-toplevel`.strip!
hash = `git ls-tree -z HEAD #{git_root}/deploy/containers/credhub_setup`.split[2]
hash = "#{hash}-dirty" unless `git status -z #{git_root}/deploy/containers/credhub_setup/`.empty?
puts "STABLE_CONTAINERS_CREDHUB_SETUP #{hash}"
