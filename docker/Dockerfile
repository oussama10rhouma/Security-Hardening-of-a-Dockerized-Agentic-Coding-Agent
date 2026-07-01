# syntax=docker/dockerfile:1.7
###############################################################################
# Hardened image for a REAL coding agent: Claude Code (Anthropic).
#
# Design principle: the IMAGE stays minimal and identical for both the
# "vulnerable" and "hardened" deployments. ALL the isolation is applied at
# *run time* (read-only rootfs, read-only config mounts, non-root user,
# cap-drop, seccomp, no egress, resource limits) via docker-compose.
# This makes the before/after comparison rigorous: same image, the run-time
# posture is the only variable.
###############################################################################
FROM node:22-bookworm-slim AS base

# --- OS packages: needed by the agent + the deterministic attack harness ----
# util-linux provides `unshare` so we can DEMONSTRATE that seccomp/cap-drop
# block namespace creation in the hardened profile.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      jq \
      tini \
      util-linux \
 && rm -rf /var/lib/apt/lists/*

# --- Install the REAL coding agent: Claude Code -----------------------------
# Pinned via build-arg for reproducibility (default: latest published).
ARG CLAUDE_CODE_VERSION=latest
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} \
 && (claude --version || true)

# --- Dedicated NON-ROOT user (defense in depth) -----------------------------
ARG AGENT_UID=10001
ARG AGENT_GID=10001
RUN groupadd --gid ${AGENT_GID} agent \
 && useradd  --uid ${AGENT_UID} --gid ${AGENT_GID} --create-home --shell /bin/bash agent

# Mount points that will receive RO/RW binds + tmpfs at run time.
RUN mkdir -p /workspace /home/agent/.claude \
 && chown -R agent:agent /workspace /home/agent

# Posture reporter + symlink guard, then hand off to the requested command.
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh \
 && chmod 0555 /usr/local/bin/entrypoint.sh

ENV HOME=/home/agent \
    CLAUDE_CONFIG_DIR=/home/agent/.claude \
    NODE_ENV=production

USER agent
WORKDIR /workspace

# tini as PID 1 => correct signal handling and zombie reaping.
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
