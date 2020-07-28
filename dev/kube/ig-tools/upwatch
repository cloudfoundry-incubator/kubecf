#!/usr/bin/env ruby
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
# `No resources`, that just means that the namespace is empty.
##
# Note: The user has to stop the tool explicitly, via Ctrl-C. It does
# not stop on its own, except for the error handling above.

require 'open3'

def main
  track thenamespace
end

def thenamespace
  usage if ARGV.length != 1
  ARGV.first
end

def usage
  STDERR.puts "Usage: upwatch namespace"
  exit 1
end

def track (ns)
  # per igroup state (last state seen). events are emitted when
  # current state is different from last state.
  $igstate = {}

  # Main loop. Retrieve and display state, detect changes and emit
  # events.
  $waiting = true
  while $waiting do
    next if !getstate ns
    # $state contains new state
    current = Time.now

    # Clear terminal to ensure that display begins at the top/home
    # position.
    puts "\033\[H\033\[J"

    # Iterate over current state/pods.
    $state.split("\n").each do |line|
      # Hide empty lines.
      next if line.empty?
      # Extract pod state elements
      (igroup, counts, istate, restarts, age) = line.split
      # Hide header line
      next if istate == "STATUS"
      istate = canonical istate, counts
      init        current, igroup, istate
      statechange current, igroup, istate
      puts "#{prefix istate}#{line}#{reset}"
    end
    STDOUT.flush
  end
end

# Animation. Generates feedback that the tool is still properly
# operating, and not stuck.
def ani
  $count ||= 0
  labels = [
	".    ",
	" .   ",
	"  .  ",
	"   . ",
	"    .",
	"   ..",
	"  .. ",
	" ..  ",
	"..   ",
	"...  ",
	" ... ",
	"  ...",
	" ....",
	".... ",
	"... .",
	".. ..",
	". ...",
	" ....",
	"  ...",
	".  ..",
	"..  .",
	"...  ",
	"..   ",
	".   .",
	"   ..",
	"    .",
	"   . ",
	"  .  ",
	" .   "
  ]
  $count += 1
  $count = 0 if $count >= labels.length
  labels[$count]
end

# Query current state
def getstate (ns)
  sleep 0.1 # 1/10 second = 100 millis
  $waiting = false
  cmd = "kubectl get pods --namespace #{ns}"
  Open3.popen3(cmd) do |_, stdout, stderr, wait_thr|
    if wait_thr.value.success?
        $state = stdout.read
        true
    else
      msg = stderr.read
      print "\r\033\[K\033\[31m#{ani}\033\[0m: #{msg}"
      STDOUT.flush
      exit 1 if msg !~ /No resources found.*/
      $waiting = true
      false
    end
  end
end

# Convert base kube state for a pod into a canonical form enablign the
# tracking of partial readiness.
def canonical (state, counts)
  return state if state != "Running"
  (ready, requested) = counts.split('/')
  return "Ready" if ready.to_i == requested.to_i
  "Run:#{ready}/#{requested}"
end

def reset
  "\033\[0m"
end

def red
  "\033\[31m"
end

# Initialize internal state
def init (current, igroup, istate)
  return if $igstate[igroup]
  achange current, igroup, istate
end

# Detect state changes, and emit events
def statechange (current, igroup, istate)
  return if $igstate[igroup] == istate
  achange current, igroup, istate
end

# Emit a state difference as event
def achange (current, igroup, istate)
    $igstate[igroup] = istate
    STDERR.puts "change #{current.to_i} #{istate} #{igroup}"
    STDERR.flush
end

# Helper for pod/state display
def prefix (istate)
    return "      " if istate == "Ready"
    return "      " if istate == "Completed"
    $waiting = true
    "#{ani} #{red}"
end

main
exit
