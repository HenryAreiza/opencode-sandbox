#!/usr/bin/env bash
set -e

IMAGE_NAME="opencode-sandbox:latest"
PERSISTENT_HOME="${HOME}/.opencode-docker"

# Ensure host config/home persistence directory exists
mkdir -p "${PERSISTENT_HOME}"

# Forward common API keys from host environment
ENV_FLAGS=()
[ -n "${OPENAI_API_KEY}" ] && ENV_FLAGS+=(-e OPENAI_API_KEY="${OPENAI_API_KEY}")
[ -n "${ANTHROPIC_API_KEY}" ] && ENV_FLAGS+=(-e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}")
[ -n "${OPENCODE_API_KEY}" ] && ENV_FLAGS+=(-e OPENCODE_API_KEY="${OPENCODE_API_KEY}")

exec docker run -it --rm \
  "${ENV_FLAGS[@]}" \
  -v "${PERSISTENT_HOME}:/home/opencode" \
  -v "${PWD}:/workspace" \
  -w /workspace \
  "${IMAGE_NAME}" "$@"
