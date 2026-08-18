#!/usr/bin/env bash
set -e

IMAGE_NAME="opencode-sandbox:latest"
PERSISTENT_HOME="${HOME}/.opencode-docker"

mkdir -p "${PERSISTENT_HOME}"

# Forward API keys
ENV_FLAGS=()
[ -n "${OPENAI_API_KEY}" ] && ENV_FLAGS+=(-e OPENAI_API_KEY="${OPENAI_API_KEY}")
[ -n "${ANTHROPIC_API_KEY}" ] && ENV_FLAGS+=(-e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}")
[ -n "${OPENCODE_API_KEY}" ] && ENV_FLAGS+=(-e OPENCODE_API_KEY="${OPENCODE_API_KEY}")

DOCKER_OPTS=()
APP_ARGS=()
HAS_DELIMITER=false

# Check if the double-dash delimiter '--' exists in arguments
for arg in "$@"; do
  if [ "$arg" = "--" ]; then
    HAS_DELIMITER=true
    break
  fi
done

if [ "$HAS_DELIMITER" = true ]; then
  # Split arguments around '--'
  while [ $# -gt 0 ]; do
    if [ "$1" = "--" ]; then
      shift
      APP_ARGS=("$@")
      break
    else
      DOCKER_OPTS+=("$1")
      shift
    fi
  done
else
  # No delimiter: treat all arguments as OpenCode arguments
  APP_ARGS=("$@")
fi

exec docker run -it --rm \
  "${ENV_FLAGS[@]}" \
  "${DOCKER_OPTS[@]}" \
  -v "${PERSISTENT_HOME}:/home/opencode" \
  -v "${PWD}:/workspace" \
  -w /workspace \
  "${IMAGE_NAME}" "${APP_ARGS[@]}"
