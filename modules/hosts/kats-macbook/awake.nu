#!/usr/bin/env nu
# Hold idle system sleep only while a specific Tailscale peer is online.
#
# `tailscale debug watch-ipn` provides the event stream, so nothing is polled
# while the peer's state is unchanged. Each event re-reads `tailscale status`.
# An offline observation starts three delayed confirmations at 15, 30, and 45
# seconds; the sleep assertion is released only after the third, and any online
# observation cancels the countdown. `caffeinate -i -w` is bound to this
# process, so the assertion cannot outlive the agent.

const PEER_DNS = "kats-phone-2a.tailc9942.ts.net."
const CONFIRM_DELAY = 15sec
const CONFIRM_CHECKS = 3

def log [message: string] {
  print $"[kats-awake] (date now | format date '%H:%M:%S') ($message)"
}

def peer-online []: nothing -> bool {
  let bin = "tailscale"
  try {
    let status = (^$bin status --json | from json)
    let peers = ($status.Peer? | default {})
    ($status.BackendState? == "Running") and ($peers | values | any {|peer|
      ($peer.DNSName? == $PEER_DNS) and ($peer.Online? == true)
    })
  } catch {|error|
    log $"status probe failed: ($error.msg)"
    false
  }
}

# Concatenated pretty-printed JSON objects: a root object closes with an
# unindented `}` line. Nested braces are always indented.
def frame-events []: list<string> -> list<string> {
  generate {|line, buffer|
    if $line == "}" {
      {out: ($buffer | append $line | str join "\n"), next: []}
    } else {
      {next: ($buffer | append $line)}
    }
  } []
}

def main [] {
  job spawn {
    try {
      ^tailscale debug watch-ipn --initial-status
      | lines
      | frame-events
      | each {|_event| "changed" | job send 0 }
      | ignore
    }
    "disconnected" | job send 0
  } | ignore

  mut keepawake: any = null
  mut deadline: any = null
  mut confirms = 0

  loop {
    let message = if $deadline == null {
      job recv
    } else {
      let remaining = $deadline - (date now)
      try { job recv --timeout ([$remaining 0ns] | math max) } catch { "timeout" }
    }
    if $message == "disconnected" {
      break
    }

    if (peer-online) {
      if $keepawake == null {
        $keepawake = (job spawn { ^/usr/bin/caffeinate -i -w $nu.pid })
        log "phone online; preventing idle sleep"
      }
      $deadline = null
      $confirms = 0
    } else if $keepawake != null {
      if $deadline == null {
        $deadline = (date now) + $CONFIRM_DELAY
        log "phone offline; starting three 15-second confirmations"
      } else if (date now) >= $deadline {
        $confirms = $confirms + 1
        log $"phone offline: ($confirms)/($CONFIRM_CHECKS)"
        if $confirms == $CONFIRM_CHECKS {
          job kill $keepawake
          $keepawake = null
          $deadline = null
          log "released idle sleep"
        } else {
          $deadline = (date now) + $CONFIRM_DELAY
        }
      }
    }
  }

  if $keepawake != null { job kill $keepawake }
  error make {msg: "Tailscale event stream disconnected"}
}
