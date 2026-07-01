#!/usr/bin/env bash
# 99 — Cleanup. Stops containers, removes .run/. With --all also removes
# results/ and the built image.
source "$(dirname "$0")/lib.sh"
cd "$ROOT"

compose -f compose/docker-compose.vuln.yml     down -v >/dev/null 2>&1 || true
compose -f compose/docker-compose.hardened.yml down -v >/dev/null 2>&1 || true
if [ -f "$ROOT/bonus/docker-compose.bonus.yml" ]; then
  compose -f bonus/docker-compose.bonus.yml down -v >/dev/null 2>&1 || true
fi
rm -rf "$ROOT/.run"
ok "stopped containers and networks; removed .run/"

if [ "${1:-}" = "--all" ]; then
  rm -rf "$ROOT/results"
  docker rmi agentic-hardening:latest >/dev/null 2>&1 || true
  ok "removed results/ and image agentic-hardening:latest"
fi
