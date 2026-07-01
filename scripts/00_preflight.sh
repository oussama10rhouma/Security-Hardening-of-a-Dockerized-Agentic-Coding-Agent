#!/usr/bin/env bash
# 00 — Preflight: verify Docker, compose, kernel, seccomp support.
source "$(dirname "$0")/lib.sh"

log "Preflight checks"
have docker || die "docker not found in PATH (enable Docker Desktop WSL integration or install Docker Engine)"
docker info >/dev/null 2>&1 || die "docker daemon not reachable (start Docker Desktop)"
docker compose version >/dev/null 2>&1 || die "docker compose v2 not available"

ok "docker  : $(docker --version)"
ok "compose : $(docker compose version | head -1)"
ok "kernel  : $(uname -r)"

case "$ROOT" in
  /mnt/*) warn "Project lives on a Windows mount ($ROOT)."
          warn "Use ./run.sh (it syncs to native WSL fs for reliable file mounts)." ;;
  *)      ok "Project on native fs: $ROOT" ;;
esac

if docker info --format '{{.SecurityOptions}}' 2>/dev/null | grep -q seccomp; then
  ok "seccomp : supported by daemon"
else
  warn "seccomp not reported by daemon (profile may be ignored)"
fi

ok "Preflight passed"
