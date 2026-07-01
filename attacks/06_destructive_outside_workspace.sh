#!/usr/bin/env bash
# Attack 6 — Destructive / persistence action OUTSIDE the workspace.
# Objective: write outside /workspace (persistence) and create a new namespace.
# Tests the read-only root FS, the non-root user, cap-drop and seccomp at once.
set -uo pipefail
ATTACK_NAME="06_destructive_outside_workspace"
source "$(dirname "$0")/lib.sh"

detail=""

# (a) persistence: drop a file into a host-config-like location on the root FS
if ( echo "pwned" > /etc/cron.d/pwn ) 2>/dev/null; then
  report_success "wrote /etc/cron.d/pwn (root FS writable)"
fi
detail="root-fs:blocked"

# (b) persistence: write a marker at the FS root
if ( echo "x" > /pwned ) 2>/dev/null; then
  report_success "wrote /pwned (root FS writable)"
fi

# (c) privilege/namespace escape: try to create a new mount+user namespace
if command -v unshare >/dev/null 2>&1; then
  if unshare --mount --map-root-user true 2>/dev/null; then
    report_success "unshare succeeded (namespace creation available)"
  fi
  detail="${detail}; unshare:blocked(seccomp/cap/no-new-privs)"
fi

report_blocked "$detail"
