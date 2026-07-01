#!/usr/bin/env bash
###############################################################################
# lib.sh — shared helpers for the attack scripts.
#
# Every attack prints EXACTLY ONE machine-parseable line:
#   RESULT|<name>|SUCCESS|<detail>     -> the malicious objective was achieved
#   RESULT|<name>|BLOCKED|<detail>     -> the hardening stopped it
# Scripts always exit 0 so the harness can run them all in sequence.
###############################################################################

: "${ATTACK_NAME:=unknown}"

report_success() { echo "RESULT|${ATTACK_NAME}|SUCCESS|${1:-}"; exit 0; }
report_blocked() { echo "RESULT|${ATTACK_NAME}|BLOCKED|${1:-}"; exit 0; }

# First line of a file (for compact error messages).
firstline() { head -n1 "$1" 2>/dev/null | tr -d '\r'; }
