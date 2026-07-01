#!/usr/bin/env bash
###############################################################################
# run.sh — single entry point.
#
#   ./run.sh            # preflight + build + demo + table  (everything)
#   ./run.sh preflight  # checks only
#   ./run.sh build      # build the image only
#   ./run.sh demo       # run the before/after attacks
#   ./run.sh table      # (re)generate results/RESULTS.md
#   ./run.sh bonus      # run the egress-allowlist-bypass bonus
#   ./run.sh clean      # stop containers + remove .run/   (clean --all = full)
#
# If the project sits on a Windows drive mount (/mnt/...), this script first
# syncs it to the native WSL filesystem (reliable single-file bind mounts and
# correct Unix permissions) and re-runs there.
###############################################################################
set -euo pipefail
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NATIVE_ROOT="${AGENTIC_NATIVE_DIR:-$HOME/.local/share/agentic-hardening}"

if [[ "$SRC_DIR" == /mnt/* ]]; then
  echo "[run] source on Windows mount: $SRC_DIR"
  echo "[run] syncing to native WSL fs: $NATIVE_ROOT"
  mkdir -p "$NATIVE_ROOT"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete --exclude '.run/' --exclude 'results/' "$SRC_DIR"/ "$NATIVE_ROOT"/
  else
    tmp="$NATIVE_ROOT.tmp.$$"; rm -rf "$tmp"; mkdir -p "$tmp"
    cp -a "$SRC_DIR"/. "$tmp"/
    rm -rf "$tmp/.run" "$tmp/results"
    rm -rf "$NATIVE_ROOT"; mv "$tmp" "$NATIVE_ROOT"
  fi
  # normalise CRLF -> LF and restore exec bits on shell scripts
  find "$NATIVE_ROOT" -type f -name '*.sh' -exec sed -i 's/\r$//' {} + 2>/dev/null || true
  find "$NATIVE_ROOT" -type f -name '*.sh' -exec chmod +x {} + 2>/dev/null || true
  sed -i 's/\r$//' "$NATIVE_ROOT/docker/entrypoint.sh" 2>/dev/null || true
  # run on the native fs, then mirror results/ back so they are visible in the
  # original (Windows) workspace.
  set +e
  bash "$NATIVE_ROOT/run.sh" "$@"
  rc=$?
  set -e
  if [[ -d "$NATIVE_ROOT/results" ]]; then
    echo "[run] copying results back to $SRC_DIR/results"
    rm -rf "$SRC_DIR/results"
    cp -a "$NATIVE_ROOT/results" "$SRC_DIR/results" 2>/dev/null || true
  fi
  exit $rc
fi

cd "$SRC_DIR"
find . -type f -name '*.sh' -exec sed -i 's/\r$//' {} + 2>/dev/null || true
chmod +x scripts/*.sh run.sh 2>/dev/null || true

CMD="${1:-all}"
case "$CMD" in
  preflight) bash scripts/00_preflight.sh ;;
  build)     bash scripts/00_preflight.sh && bash scripts/01_build.sh ;;
  demo)      bash scripts/02_run_demo.sh ;;
  table)     bash scripts/03_make_table.sh ;;
  bonus)     bash bonus/run_bonus.sh ;;
  clean)     bash scripts/99_cleanup.sh "${2:-}" ;;
  all)
    bash scripts/00_preflight.sh
    bash scripts/01_build.sh
    bash scripts/02_run_demo.sh
    bash scripts/03_make_table.sh
    echo
    echo "Done. See results/RESULTS.md"
    ;;
  *) echo "usage: ./run.sh [all|preflight|build|demo|table|bonus|clean]"; exit 2 ;;
esac
