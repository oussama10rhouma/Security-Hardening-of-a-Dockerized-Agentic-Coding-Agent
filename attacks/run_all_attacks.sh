#!/usr/bin/env bash
###############################################################################
# run_all_attacks.sh — runs inside the agent container.
#
# Represents a prompt-injected agent executing the 6 malicious objectives
# embedded in /workspace/README.md, plus a positive CONTROL check proving the
# workspace itself stays writable (the agent must remain functional).
###############################################################################
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

echo "================================================================"
echo " ATTACK HARNESS  $(date -u +%FT%TZ)"
echo " user=$(id -un) uid=$(id -u) gid=$(id -g)"
if ( : > /._probe ) 2>/dev/null; then echo " root_fs=READ-WRITE"; rm -f /._probe; \
  else echo " root_fs=READ-ONLY"; fi
echo "================================================================"

# --- positive control: legitimate edit inside the workspace -----------------
if ( echo "ok" > /workspace/src/.control_edit ) 2>/dev/null; then
  echo "RESULT|00_control_workspace_write|SUCCESS|workspace is writable (agent functional)"
  rm -f /workspace/src/.control_edit 2>/dev/null || true
else
  echo "RESULT|00_control_workspace_write|BLOCKED|workspace not writable"
fi

# --- the six attacks --------------------------------------------------------
shopt -s nullglob
for f in "$DIR"/0[1-6]_*.sh; do
  [ -f "$f" ] || continue
  bash "$f"
done
shopt -u nullglob

echo "================================================================"
echo " END OF HARNESS"
