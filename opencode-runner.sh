#!/usr/bin/env bash
set -e

# --- 1. Defaults & Environment Setup ---
PERSISTENT_HOME="${HOME}/.opencode-docker"
mkdir -p "${PERSISTENT_HOME}"

is_true() {
    [[ "$1" == "true" || "$1" == "1" || "$1" == "yes" ]]
}

show_help() {
    cat <<EOF
Usage: $(basename "$0") [RUNNER_FLAGS] [-- [DOCKER_OPTS]] [APP_ARGS]

OpenCode Runner: A utility to run OpenCode in a Dockerized sandbox.

RUNNER_FLAGS:
  --ephemeral              Enable ephemeral mode (removes container on exit).
  --persist                Enable persistent mode (default).
  --rebuild                Force rebuild of custom project Docker image.
  --name <name>            Override container name.
  --image <image>          Override Docker image tag/name.
  -h, --help               Display this help message.

DOCKER_OPTS (parsed before '--' when '--' delimiter is used):
  Custom docker run options (e.g., -p 8080:8000, -v /host:/mnt, -m 4g).

APP_ARGS (parsed after '--', or non-flag arguments if no '--' delimiter is used):
  Arguments or starting prompt passed to 'opencode' inside the container.

ENVIRONMENT VARIABLES:
  OPENCODE_EPHEMERAL      Enable ephemeral mode (true/1/yes).
  OPENCODE_PERSIST        Enable persistent and persistent mode (true/1/yes).
  OPENCODE_REBUILD        Force rebuild (true/1/yes).
  OPENCODE_IMAGE          Default image override.
  OPENCODE_CONTAINER_NAME Default container name override.
  OPENAI_API_KEY          Forwarded to container.
  ANTHROPIC_API_KEY       Forwarded to container.
  OPENCODE_API_KEY        Forwarded to container.

EXAMPLES:
  $(basename "$0")                       # Run in default persistent mode
  $(basename "$0") --ephemeral            # Run in ephemeral mode
  $(basename "$0") --rebuild              # Force rebuild custom image
  $(basename "$0") -p 8080:8000 --        # Pass custom docker options
  $(basename "$0") "Review this codebase" # Pass starting prompt to OpenCode
  $(basename "$0") -p 8080:8000 -- "Review codebase" # Pass both docker flags & prompt
  $(basename "$0") --name my-dev-env      # Override container name
EOF
    exit 0
}

# --- 2. Initial State from Environment ---
EPHEMERAL=false
if is_true "${OPENCODE_EPHEMERAL}"; then EPHEMERAL=true; fi

REBUILD=false
if is_true "${OPENCODE_REBUILD}"; then REBUILD=true; fi

PERSIST=true
if is_true "${OPENCODE_PERSIST}"; then PERSIST=true; fi

NAME_OVERRIDE="${OPENCODE_CONTAINER_NAME:-}"
IMAGE_OVERRIDE="${OPENCODE_IMAGE:-}"

# --- 3. Argument Parsing Logic ---
DOCKER_OPTS=()
APP_ARGS=()
PRE_DELIMITER_ARGS=()
POST_DELIMITER_ARGS=()
HAS_DELIMITER=false
FOUND_DELIMITER=false

# 1. Split arguments by '--' delimiter
for arg in "$@"; do
    if [[ "$arg" == "--" && "$FOUND_DELIMITER" = false ]]; then
        FOUND_DELIMITER=true
        HAS_DELIMITER=true
        continue
    fi
    
    if [ "$FOUND_DELIMITER" = true ]; then
        POST_DELIMITER_ARGS+=("$arg")
    else
        PRE_DELIMITER_ARGS+=("$arg")
    fi
done

# 2. Parse arguments
# If HAS_DELIMITER is true, PRE_DELIMITER_ARGS contains runner flags and docker opts.
# POST_DELIMITER_ARGS contains APP_ARGS.
# If HAS_DELIMITER is false, PRE_DELIMITER_ARGS contains runner flags and (optionally) app args.

i=0
while [ $i -lt ${#PRE_DELIMITER_ARGS[@]} ]; do
    arg="${PRE_DELIMITER_ARGS[$i]}"
    case "$arg" in
        --ephemeral)
            EPHEMERAL=true
            PERSIST=false
            ;;
        --persist)
            PERSIST=true
            EPHEMERAL=false
            ;;
        --rebuild)
            REBUILD=true
            ;;
        --name=*|--name)
            if [[ "$arg" == *=* ]]; then
                NAME_OVERRIDE="${arg#*=}"
            else
                i=$((i+1))
                NAME_OVERRIDE="${PRE_DELIMITER_ARGS[$i]}"
            fi
            ;;
        --image=*|--image)
            if [[ "$arg" == *=* ]]; then
                IMAGE_OVERRIDE="${arg#*=}"
            else
                i=$((i+1))
                IMAGE_OVERRIDE="${PRE_DELIMITER_ARGS[$i]}"
            fi
            ;;
        -h|--help)
            show_help
            ;;
        *)
            if [ "$HAS_DELIMITER" = true ]; then
                DOCKER_OPTS+=("$arg")
            else
                APP_ARGS+=("$arg")
            fi
            ;;
    esac
    i=$((i+1))
done

# If delimiter exists, the part after '--' are the APP_ARGS.
if [ "$HAS_DELIMITER" = true ]; then
    APP_ARGS=("${POST_DELIMITER_ARGS[@]}")
fi

# --- 4. Project Identification ---
DIR_NAME="$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9._-' '-')"
DIR_HASH="$(printf "%s" "$PWD" | sha256sum | head -c 8)"
SLUG="${DIR_NAME}-${DIR_HASH}"

# --- 5. Image Discovery & Build ---
IMAGE_NAME="${IMAGE_OVERRIDE:-}"
CUSTOM_DOCKERFILE="$PWD/opencode-sandbox/Dockerfile"

if [ -f "$CUSTOM_DOCKERFILE" ]; then
    if [ -z "$IMAGE_NAME" ]; then
        IMAGE_NAME="opencode-sandbox-custom-${SLUG}:latest"
    fi
    
    IMAGE_EXISTS=false
    if docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
        IMAGE_EXISTS=true
    fi

    if [ "$REBUILD" = true ] || [ "$IMAGE_EXISTS" = false ]; then
        echo "Building custom sandbox image: $IMAGE_NAME..."
        docker build --build-arg USER_ID="$(id -u)" --build-arg GROUP_ID="$(id -g)" -t "$IMAGE_NAME" -f "$CUSTOM_DOCKERFILE" "$PWD/opencode-sandbox"
    fi
else
    if [ -z "$IMAGE_NAME" ]; then
        IMAGE_NAME="opencode-sandbox:latest"
    fi
fi

# --- 6. Container Lifecycle & Persistence ---
CONTAINER_NAME="${NAME_OVERRIDE:-}"
if [ -z "$CONTAINER_NAME" ]; then
    if [ "$EPHEMERAL" = true ]; then
        CONTAINER_NAME="opencode-sandbox-${SLUG}-ephemeral-$$"
    else
        CONTAINER_NAME="opencode-sandbox-${SLUG}"
    fi
fi

# Environment variables to forward
ENV_FLAGS=()
[ -n "${OPENAI_API_KEY}" ] && ENV_FLAGS+=(-e OPENAI_API_KEY="${OPENAI_API_KEY}")
[ -n "${ANTHROPIC_API_KEY}" ] && ENV_FLAGS+=(-e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}")
[ -n "${OPENCODE_API_KEY}" ] && ENV_FLAGS+=(-e OPENCODE_API_KEY="${OPENCODE_API_KEY}")

# Common volume/workdir flags
COMMON_FLAGS=(
    -v "${PERSISTENT_HOME}:/home/opencode"
    -v "${PWD}:/workspace"
    -w /workspace
)

# Run logic
if [ "$EPHEMERAL" = true ]; then
    RUN_CMD=(docker run -it --rm)
    RUN_CMD+=("--name" "$CONTAINER_NAME")
    RUN_CMD+=("${ENV_FLAGS[@]}")
    RUN_CMD+=("${DOCKER_OPTS[@]}")
    RUN_CMD+=("${COMMON_FLAGS[@]}")
    RUN_CMD+=("$IMAGE_NAME")
    RUN_CMD+=("${APP_ARGS[@]}")
    exec "${RUN_CMD[@]}"
else
    # Persistent mode logic
    if docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
        # Container exists
        CONTAINER_RUNNING="$(docker container inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null || echo "false")"
        if [ "$CONTAINER_RUNNING" = "true" ]; then
            # Running: exec into it
            echo "Attaching to running container: $CONTAINER_NAME"
            exec docker exec -it "$CONTAINER_NAME" opencode "${APP_ARGS[@]}"
        else
            # Stopped: start and exec (or start -ai if no app args)
            echo "Starting stopped container: $CONTAINER_NAME"
            if [ ${#APP_ARGS[@]} -gt 0 ]; then
                docker start "$CONTAINER_NAME" >/dev/null
                exec docker exec -it "$CONTAINER_NAME" opencode "${APP_ARGS[@]}"
            else
                exec docker start -ai "$CONTAINER_NAME"
            fi
        fi
    else
        # Does not exist: run new one
        RUN_CMD=(docker run -it)
        RUN_CMD+=("--name" "$CONTAINER_NAME")
        RUN_CMD+=("${ENV_FLAGS[@]}")
        RUN_CMD+=("${DOCKER_OPTS[@]}")
        RUN_CMD+=("${COMMON_FLAGS[@]}")
        RUN_CMD+=("$IMAGE_NAME")
        RUN_CMD+=("${APP_ARGS[@]}")
        exec "${RUN_CMD[@]}"
    fi
fi
