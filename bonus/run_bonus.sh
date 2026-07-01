#!/usr/bin/env bash
# Runs the bonus twice: naive allowlist (exfil succeeds) then content-inspecting
# gateway (exfil blocked).
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/lib.sh"
cd "$ROOT"

# fresh working copy + secret
rm -rf "$ROOT/.run/bonus"
mkdir -p "$ROOT/.run/bonus/repo/.claude" "$ROOT/.run/bonus/secrets" "$ROOT/results/bonus"
cp -a "$ROOT/workspace/." "$ROOT/.run/bonus/repo/"
cp -a "$ROOT/config/.claude/." "$ROOT/.run/bonus/repo/.claude/"
cp -a "$ROOT/config/CLAUDE.md" "$ROOT/.run/bonus/repo/CLAUDE.md"
cp -a "$ROOT/config/.mcp.json" "$ROOT/.run/bonus/repo/.mcp.json"
chmod -R a+rwX "$ROOT/.run/bonus/repo"
printf 'FAKE_API_KEY=sk-DEMO-0000-DO-NOT-USE-1234567890\n' > "$ROOT/.run/bonus/secrets/fake_api_key"

export SECCOMP_PROFILE="$(realpath "$ROOT/seccomp/agent-seccomp.json")"
C="bonus/docker-compose.bonus.yml"

run_variant() {
  local inspect="$1" label="$2"
  log "=== BONUS variant: $label (INSPECT=$inspect) ==="
  rm -f "$ROOT/results/bonus/exfil.log" 2>/dev/null || true
  INSPECT="$inspect" compose -f "$C" run --rm agent \
    bash /opt/bonus/attack_exfil_via_allowed_domain.sh 2>&1 | tee "$ROOT/results/bonus/${label}.log" || true
  echo "--- gateway log (results/bonus/exfil.log) ---"
  [ -s "$ROOT/results/bonus/exfil.log" ] && cat "$ROOT/results/bonus/exfil.log" || echo "(empty)"
  INSPECT="$inspect" compose -f "$C" down -v >/dev/null 2>&1 || true
  echo
}

run_variant 0 naive
run_variant 1 mitigated

log "Bonus done. Logs in results/bonus/"
echo "Expected: naive=SUCCESS (exfil via allowed domain), mitigated=BLOCKED (content inspection)."
