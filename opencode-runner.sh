#!/usr/bin/env bash
set -e

# --- 1. Defaults & Directory Setup ---
PERSISTENT_HOME="${HOME}/.opencode-docker"
mkdir -p "${PERSISTENT_HOME}"

show_help() {
    cat <<EOF
Usage: $(basename "$0") [RUNNER_FLAGS] [[DOCKER_OPTS] --] [APP_ARGS]

OpenCode Sandbox Runner: Manages isolated, persistent or ephemeral OpenCode containers.

RUNNER_FLAGS:
  --ephemeral              Run an ephemeral container (auto-removes with --rm on exit).
  --rebuild                Force rebuild the project-specific custom Docker image.
  --name <name>            Override the container name.
  --image <image>          Override the Docker image name/tag.
  -h, --help               Display this help message.

DOCKER_OPTS (passed before '--' when the '--' delimiter is used):
  Standard docker run options (e.g., -p 8080:8000, --cpus 2, -m 4g).

APP_ARGS (passed after '--', or as trailing arguments if no delimiter is used):
  Starting prompts or CLI arguments forwarded directly to 'opencode'.

EXAMPLES:
  $(basename "$0")                                     # Launch default/custom persistent sandbox
  $(basename "$0") --ephemeral                         # Launch disposable container
  $(basename "$0") --rebuild                           # Rebuild ./opencode-sandbox custom image
  $(basename "$0") -p 8080:8000 --                     # Expose container port to host
  $(basename "$0") "Refactor main.py"                  # Pass initial prompt directly
  $(basename "$0") -p 3000:3000 -- "Run tests"         # Expose port and pass starting prompt
EOF
    exit 0
}

# --- 2. Initial State ---
PERSIST=true
REBUILD=false
NAME_OVERRIDE=""
IMAGE_OVERRIDE=""

DOCKER_OPTS=()
APP_ARGS=()
PRE_DELIMITER_ARGS=()
POST_DELIMITER_ARGS=()
HAS_DELIMITER=false

# --- 3. Argument Separation & Parsing ---
# Split around the double-dash '--' delimiter
for arg in "$@"; do
    if [[ "$arg" == "--" && "$HAS_DELIMITER" = false ]]; then
        HAS_DELIMITER=true
        continue
    fi
    if [ "$HAS_DELIMITER" = true ]; then
        POST_DELIMITER_ARGS+=("$arg")
    else
        PRE_DELIMITER_ARGS+=("$arg")
    fi
done

# Parse pre-delimiter runner flags and docker options
i=0
while [ $i -lt ${#PRE_DELIMITER_ARGS[@]} ]; do
    arg="${PRE_DELIMITER_ARGS[$i]}"
    case "$arg" in
        --ephemeral|--rm)
            PERSIST=false
            ;;
        --rebuild)
            REBUILD=true
            ;;
        --name)
            i=$((i + 1))
            NAME_OVERRIDE="${PRE_DELIMITER_ARGS[$i]}"
            ;;
        --name=*)
            NAME_OVERRIDE="${arg#*=}"
            ;;
        --image)
            i=$((i + 1))
            IMAGE_OVERRIDE="${PRE_DELIMITER_ARGS[$i]}"
            ;;
        --image=*)
            IMAGE_OVERRIDE="${arg#*=}"
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
    i=$((i + 1))
done

if [ "$HAS_DELIMITER" = true ]; then
    APP_ARGS=("${POST_DELIMITER_ARGS[@]}")
fi

# --- 4. Project Identity & Container Naming ---
# Generate a deterministic slug based on directory name and path hash
DIR_NAME="$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9._-' '-')"

if command -v sha256sum >/dev/null 2>&1; then
    DIR_HASH="$(printf "%s" "$PWD" | sha256sum | head -c 8)"
elif command -v shasum >/dev/null 2>&1; then
    DIR_HASH="$(printf "%s" "$PWD" | shasum -a 256 | head -c 8)"
else
    DIR_HASH="$(printf "%s" "$PWD" | cksum | awk '{print $1}')"
fi

SLUG="${DIR_NAME}-${DIR_HASH}"

# --- 5. Image Resolution & Auto-Build ---
CUSTOM_SANDBOX_DIR="$PWD/opencode-sandbox"
CUSTOM_DOCKERFILE="$CUSTOM_SANDBOX_DIR/Dockerfile"
IMAGE_NAME="${IMAGE_OVERRIDE:-}"

if [ -f "$CUSTOM_DOCKERFILE" ]; then
    if [ -z "$IMAGE_NAME" ]; then
        IMAGE_NAME="opencode-custom-${SLUG}:latest"
    fi

    IMAGE_EXISTS=false
    if docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
        IMAGE_EXISTS=true
    fi

    if [ "$REBUILD" = true ] || [ "$IMAGE_EXISTS" = false ]; then
        echo "==> Building custom sandbox image: $IMAGE_NAME..."
        docker build \
            --build-arg USER_ID="$(id -u)" \
            --build-arg GROUP_ID="$(id -g)" \
            -t "$IMAGE_NAME" \
            -f "$CUSTOM_DOCKERFILE" \
            "$CUSTOM_SANDBOX_DIR"
    fi
else
    if [ -z "$IMAGE_NAME" ]; then
        IMAGE_NAME="opencode-sandbox:latest"
    fi
fi

# --- 6. Container Lifecycle Management ---
CONTAINER_NAME="${NAME_OVERRIDE:-}"
if [ -z "$CONTAINER_NAME" ]; then
    if [ "$PERSIST" = true ]; then
        CONTAINER_NAME="opencode-sandbox-${SLUG}"
    else
        CONTAINER_NAME="opencode-sandbox-${SLUG}-ephemeral-$$"
    fi
fi

# Forward host LLM API keys
ENV_FLAGS=()
[ -n "${OPENAI_API_KEY}" ] && ENV_FLAGS+=(-e OPENAI_API_KEY="${OPENAI_API_KEY}")
[ -n "${ANTHROPIC_API_KEY}" ] && ENV_FLAGS+=(-e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}")
[ -n "${OPENCODE_API_KEY}" ] && ENV_FLAGS+=(-e OPENCODE_API_KEY="${OPENCODE_API_KEY}")
[ -n "${OLLAMA_BASE_URL}" ] && ENV_FLAGS+=(-e OLLAMA_BASE_URL="${OLLAMA_BASE_URL}")

COMMON_MOUNTS=(
    --add-host host.docker.internal:host-gateway
    -v "${PERSISTENT_HOME}:/home/opencode"
    -v "${PWD}:/workspace"
    -w /workspace
)

if [ "$PERSIST" = false ]; then
    # Ephemeral execution
    exec docker run -it --rm \
        --name "$CONTAINER_NAME" \
        "${ENV_FLAGS[@]}" \
        "${DOCKER_OPTS[@]}" \
        "${COMMON_MOUNTS[@]}" \
        "$IMAGE_NAME" "${APP_ARGS[@]}"
else
    # Persistent container execution
    if docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
        CONTAINER_RUNNING="$(docker container inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null || echo "false")"
        if [ "$CONTAINER_RUNNING" = "true" ]; then
            echo "==> Attaching to running container: $CONTAINER_NAME"
            exec docker exec -it "${ENV_FLAGS[@]}" "$CONTAINER_NAME" opencode "${APP_ARGS[@]}"
        else
            echo "==> Resuming stopped container: $CONTAINER_NAME"
            docker start "$CONTAINER_NAME" >/dev/null
            exec docker exec -it "${ENV_FLAGS[@]}" "$CONTAINER_NAME" opencode "${APP_ARGS[@]}"
        fi
    else
        # First-time persistent run
        exec docker run -it \
            --name "$CONTAINER_NAME" \
            "${ENV_FLAGS[@]}" \
            "${DOCKER_OPTS[@]}" \
            "${COMMON_MOUNTS[@]}" \
            "$IMAGE_NAME" "${APP_ARGS[@]}"
    fi
fi
