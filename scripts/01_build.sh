#!/usr/bin/env bash
# 01 — Build the hardened agent image (Claude Code installed inside).
source "$(dirname "$0")/lib.sh"
cd "$ROOT"

log "Building image agentic-hardening:latest (this installs Claude Code via npm)"
docker build -t agentic-hardening:latest "$ROOT/docker"
ok "image built"

log "Recording the deployed agent version"
mkdir -p "$ROOT/results"
ver="$(timeout 40 docker run --rm --network none --entrypoint claude agentic-hardening:latest --version 2>/dev/null | tr -d '\r' || true)"
[ -n "$ver" ] || ver="installed (version probe skipped)"
echo "$ver" > "$ROOT/results/agent-version.txt"
ok "claude-code: $ver"
