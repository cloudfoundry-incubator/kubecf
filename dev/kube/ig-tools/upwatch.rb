#!/usr/bin/env ruby
# frozen_string_literal: true

##
# Given a namespace to watch this tool iteratively calls `kubectl get
# pods` on the namespace to determine its current state and update its
# internal state. Differences between current and internal state
# (before it gets updated) are written to !stderr! as a series of
# events. This kind of series can be processed by the other two tools,
# `extent` and `sequence`. The first computes the size of the time
# interval covered by the events, the other creates a diagram
# visualizing the sequencing.
##
# The events are printed to stderr because stdout is used to
# continuously display the (changing) current state. Including some
# animation to ensure feedback of proper operation even when the state
# is unchanging.
##
# Note: The tool aborts if `kubectl` fails with an error (except for
# `No resources`, that just means that the namespace is empty).
##
# Note: The tool will stop on error, or if all pods are ready.

require 'open3'

def main
  track thenamespace
end

def thenamespace
  usage if ARGV.length != 1
  ARGV.first
end

def usage
  STDERR.puts 'Usage: upwatch <namespace>'
  exit 1
end

def track(namespace)
  puts "Tracking namespace #{namespace}"
  # Last seen state per pod. Events are emitted when current state is different
  # from last seen state.
  known_pod_state = Hash.new { |h, k| h[k] = 'Unknown' }

  # Main loop. Retrieve and display state, detect changes and emit
  # events.
  loop do
    timestamp = Time.now.to_i
    state = getstate namespace
    next unless state

    # Clear terminal to ensure that display begins at the top/home position.
    puts "\e\[2J\e\[HTracking namespace #{namespace}"
    break unless update state, timestamp, known_pod_state
  end
end

# Parse the output from kubectl, updating the state; returns true if we are
# expecting more changes, false otherwise.
def update(state, timestamp, known_pod_state)
  # Skip empty lines
  completed = state.lines.map(&:chomp).reject(&:empty?).map do |line|
    # Extract pod state elements
    (pod_name, counts, pod_state,) = line.split
    next true if pod_state == 'STATUS' # Drop the header line

    pod_state = canonicalize_state pod_state, counts
    detect_state_change timestamp, pod_name, pod_state, known_pod_state

    puts "#{prefix pod_state}#{line}#{reset}"
    complete? pod_state
  end
  # If we only have 3 items, wait for more (to filter out database + seeder)
  completed.length < 3 || !completed.all?
end

$ani = [
  '.    ', ' .   ', '  .  ', '   . ', '    .',
  '   ..', '  .. ', ' ..  ', '..   ',
  '...  ', ' ... ', '  ...',
  ' ....', '.... ', '... .', '.. ..', '. ...', ' ....',
  '  ...', '.  ..', '..  .', '...  ',
  '..   ', '.   .', '   ..',
  '    .', '   . ', '  .  ', ' .   '
].cycle

# Animation. Generates feedback that the tool is still properly
# operating, and not stuck.
def ani
  $ani.next
end

# Query current state; returns the state output on success.  Aborts the program
# on any error.
def getstate(namespace)
  sleep 0.1 # 1/10 second = 100 millis
  cmd = "kubectl get pods --namespace #{namespace}"
  stdout, stderr, status = Open3.capture3(cmd)
  return stdout if status.success?

  puts "\r\e[K\e[31m#{ani}\e[0m: #{stderr}"
  STDOUT.flush
  exit 1
end

# Convert base kube state for a pod into a canonical form enabling the
# tracking of partial readiness.
def canonicalize_state(state, counts)
  return state unless state == 'Running'

  (ready, requested) = counts.split('/')
  return 'Ready' if ready.to_i == requested.to_i

  "Run:#{ready}/#{requested}"
end

def reset
  "\033\[0m"
end

def red
  "\033\[31m"
end

# Detect state changes, and emit events
def detect_state_change(timestamp, pod_name, pod_state, known_pod_state)
  return if known_pod_state[pod_name] == pod_state

  known_pod_state[pod_name] = pod_state
  STDERR.puts "change #{timestamp} #{pod_state} #{pod_name}"
end

def complete?(istate)
  %w[Ready Completed].include? istate
end

# Helper for pod/state display
def prefix(istate)
  complete?(istate) ? '      ' : "#{ani} #{red}"
end

begin
  main
rescue Interrupt
  nil
end
