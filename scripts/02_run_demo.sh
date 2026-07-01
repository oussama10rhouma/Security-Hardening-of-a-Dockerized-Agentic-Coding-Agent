#!/usr/bin/env bash
# 02 — Run the before/after demo: same attacks, vulnerable vs hardened agent.
source "$(dirname "$0")/lib.sh"
cd "$ROOT"

prepare_repo() {
  local mode="$1" dst="$ROOT/.run/$1/repo"
  rm -rf "$ROOT/.run/$1"
  mkdir -p "$dst/.claude"
  cp -a "$ROOT/workspace/." "$dst/"
  cp -a "$ROOT/config/.claude/." "$dst/.claude/"
  cp -a "$ROOT/config/CLAUDE.md"  "$dst/CLAUDE.md"
  cp -a "$ROOT/config/.mcp.json"  "$dst/.mcp.json"
  # make the working copy writable by the container's non-root uid (10001):
  # in the hardened profile, READ-ONLY enforcement then comes purely from the
  # :ro bind mounts, NOT from file permissions — which is exactly the point.
  chmod -R a+rwX "$dst"
  mkdir -p "$ROOT/results/$mode"
}

log "Preparing fresh working copies under .run/"
prepare_repo vuln
prepare_repo hardened
mkdir -p "$ROOT/.run/vuln/secrets"
printf 'FAKE_API_KEY=sk-DEMO-0000-DO-NOT-USE-1234567890\n' > "$ROOT/.run/vuln/secrets/fake_api_key"
ok "working copies ready"

# --------------------------- VULNERABLE -----------------------------------
log "=== Attacks against the VULNERABLE agent (expect: all SUCCEED) ==="
rm -f "$ROOT/results/vuln/exfil.log" 2>/dev/null || true
compose -f compose/docker-compose.vuln.yml run --rm agent \
  bash /opt/attacks/run_all_attacks.sh 2>&1 | tee "$ROOT/results/vuln/agent.log" || true
compose -f compose/docker-compose.vuln.yml down -v >/dev/null 2>&1 || true
ok "vulnerable run complete -> results/vuln/agent.log"

# --------------------------- HARDENED -------------------------------------
log "=== Attacks against the HARDENED agent (expect: all BLOCKED) ==="
export SECCOMP_PROFILE="$(realpath "$ROOT/seccomp/agent-seccomp.json")"
ok "using seccomp profile: $SECCOMP_PROFILE"
compose -f compose/docker-compose.hardened.yml run --rm agent \
  bash /opt/attacks/run_all_attacks.sh 2>&1 | tee "$ROOT/results/hardened/agent.log" || true
compose -f compose/docker-compose.hardened.yml down -v >/dev/null 2>&1 || true
ok "hardened run complete -> results/hardened/agent.log"

# ---------------------- on-disk integrity check ----------------------------
log "Checking config integrity on disk (post-run)"
{
  echo "# Integrity check (post-run)"
  echo
  echo "## Vulnerable copy (.run/vuln/repo) — attacker markers => config TAMPERED:"
  grep -RHnE 'attacker\.local|Always allow Bash|AUTO-APPROVE|pwn-mcp' "$ROOT/.run/vuln/repo" 2>/dev/null \
    || echo "  (none found?!)"
  echo
  echo "## Hardened copy (.run/hardened/repo) — attacker markers (should be NONE):"
  grep -RHnE 'attacker\.local|Always allow Bash|AUTO-APPROVE|pwn-mcp' "$ROOT/.run/hardened/repo" 2>/dev/null \
    || echo "  (none — config intact)"
  echo
  echo "## Baseline integrity markers still present in hardened copy:"
  grep -RHnE 'INTEGRITY-MARKER|integrity_marker' "$ROOT/.run/hardened/repo" 2>/dev/null \
    || echo "  (markers missing!)"
} > "$ROOT/results/integrity.txt"
cat "$ROOT/results/integrity.txt"

ok "demo complete"
