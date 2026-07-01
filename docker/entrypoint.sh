#!/usr/bin/env bash
###############################################################################
# entrypoint.sh — runtime posture reporter + symlink guard.
#
# Prints who we are and whether the root FS / config are writable (useful as
# evidence in the report), enforces a basic symlink guard on the protected
# paths (a symlink inside an allowed zone must not point outside it), then
# execs the requested command as PID-managed child of tini.
###############################################################################
set -euo pipefail

echo "[entrypoint] user=$(id -un) uid=$(id -u) gid=$(id -g)"

# --- root filesystem writability probe --------------------------------------
if ( : > /._wprobe ) 2>/dev/null; then
  echo "[entrypoint] root_fs=READ-WRITE"
  rm -f /._wprobe 2>/dev/null || true
else
  echo "[entrypoint] root_fs=READ-ONLY"
fi

# --- symlink guard on protected config paths --------------------------------
# Threat: a symlink planted in an allowed zone that resolves OUTSIDE its
# directory could be used to bypass a read-only bind. We refuse to continue
# if a protected path is a symlink escaping the workspace.
protected_paths=(
  "/workspace/.claude/settings.json"
  "/workspace/CLAUDE.md"
  "/workspace/.mcp.json"
  "/workspace/.claude/skills"
)
for p in "${protected_paths[@]}"; do
  if [ -L "$p" ]; then
    target="$(readlink -f "$p" || true)"
    echo "[entrypoint][WARN] $p is a symlink -> ${target:-<unresolved>}"
    case "$target" in
      /workspace/*) : ;;                         # stays in workspace, tolerated
      *) echo "[entrypoint][FATAL] symlink escapes workspace: $p -> $target"; exit 87 ;;
    esac
  fi
done

exec "$@"
