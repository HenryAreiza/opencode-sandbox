# OpenCode Docker Sandbox

A secure, containerized sandbox for running [OpenCode](https://opencode.ai) with filesystem isolation, automatic UID/GID permission mapping, passwordless `sudo` privileges, persistent container sessions, and project-specific custom environments.

---

## Features

- **Filesystem Isolation:** Only mounts the current working directory (`$PWD`) into the container.
- **Clean Host File Ownership:** Runs using your host's exact `UID:GID` mapping so files created by OpenCode or tools inside the container are never locked as `root`.
- **In-Container Sudo:** The agent can run `sudo apt install <package>` or `sudo apk add <package>` during sessions to install required system tools on the fly.
- **Persistent Containers by Default:** Keeps containers alive after exiting so background processes, installed tools, and caches persist between sessions.
- **Per-Project Custom Environments:** Automatically detects `./opencode-sandbox/Dockerfile` in any project repository to build and launch tailored OS and toolchain images (e.g., Ubuntu, Debian, specialized runtimes) without global conflicts.
- **AI Agent Auto-Sync Specification:** Includes a Spec-Driven Development guide (`spec/opencode-sandbox-agents-guide.md`) instructing AI agents to record runtime environment changes back into the project's sandbox manifest.
- **Persistent Global State:** OpenCode authentication, configs, and shell history persist under `~/.opencode-docker`.

---

## Repository Structure

```text
.
├── Dockerfile                             # Default global sandbox image (Alpine + Python + build tools)
├── packages.txt                           # Default global package manifest
├── opencode-runner.sh                     # Dynamic container lifecycle runner script
├── Makefile                               # Build, install, update, and cleanup workflows
├── spec/
│   └── opencode-sandbox-agents-guide.md   # SDD specification for AI agent environment maintenance
└── example-project/                       # Complete demonstration of a custom Ubuntu 24.04 sandbox
    ├── opencode-sandbox/
    │   ├── Dockerfile
    │   └── packages.txt
    ├── main.py
    └── README.md

```

---

## Quick Start

### 1. Clone & Build Global Image

```bash
git clone https://github.com/HenryAreiza/opencode-sandbox.git
cd opencode-sandbox
make build

```

### 2. Install Runner to PATH

```bash
make install

```

*Make sure `~/.local/bin` is in your `PATH` (common on modern Linux/WSL distributions).*

#### Adding `~/.local/bin` to your PATH (if required)

If running `opencode-sandbox` says `command not found`, add `~/.local/bin` to your shell configuration:

```bash
# For Bash (~/.bashrc):
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# For Zsh (~/.zshrc):
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

```

---

## Usage & Execution Modes

Navigate to any project directory on your host machine:

```bash
cd /path/to/my-project

```

### 1. Interactive Session (Default Persistent Mode)

Launch or resume the project's persistent container:

```bash
opencode-sandbox

```

* If running for the first time, it starts a persistent container named `opencode-sandbox-<project-slug>`.
* If exiting and running again later, it automatically reattaches/resumes the existing container.

### 2. Ephemeral / Disposable Mode

Run a disposable container that automatically cleans itself up (`--rm`) upon exit:

```bash
opencode-sandbox --ephemeral

```

### 3. Named Containers (Parallel Workflows)

Run multiple parallel containers on the same repository without name collisions:

```bash
# Terminal 1: Feature development
opencode-sandbox --name project-feature-auth

# Terminal 2: Bug fixing
opencode-sandbox --name project-bugfix-api

```

### 4. Non-Interactive CLI Prompts

To pass prompts directly without entering the interactive TUI, use OpenCode's `run` subcommand:

```bash
opencode-sandbox run "Analyze the project structure and summarize the architecture"

```

---

## Passing Custom Docker Options

Use the `--` delimiter to pass arbitrary `docker run` options (ports, volumes, resource limits, host bindings) before OpenCode commands:

```bash
# Expose ports to host
opencode-sandbox -p 8080:8000 --

# Publish multiple ports and pass a starting prompt
opencode-sandbox -p 3000:3000 -p 8080:8000 -- run "Run the test suite"

# Limit container resources
opencode-sandbox --cpus 2 -m 4g --

# Mount an extra directory from host
opencode-sandbox -v /path/to/shared:/shared --

```

> **Note:** `host.docker.internal` is pre-configured automatically, allowing OpenCode to communicate with host services (like a local Ollama instance or local databases) at `http://host.docker.internal:<PORT>`.

---

## Project-Specific Custom Environments

For projects requiring specialized distributions (e.g., Ubuntu, Debian, specific C libraries, CUDA), place an `opencode-sandbox` folder in the root of your project:

```text
my-project/
├── opencode-sandbox/
│   ├── Dockerfile
│   └── packages.txt
├── src/
└── ...

```

When you run `opencode-sandbox` inside `my-project/`, the runner will:

1. Detect `opencode-sandbox/Dockerfile`.
2. Automatically build a unique image tagged `opencode-custom-<project-slug>:latest` matching your host UID/GID.
3. Launch your project inside that custom environment.

### Forcing a Rebuild

If you edit `opencode-sandbox/packages.txt` or `opencode-sandbox/Dockerfile`, force a rebuild using:

```bash
opencode-sandbox --rebuild

```

### Guiding AI Agents to Keep Custom Environments Updated

To instruct AI coding agents to automatically sync system-level package changes back into `opencode-sandbox/packages.txt` whenever they run `sudo apt install` or similar commands:

Copy `spec/opencode-sandbox-agents-guide.md` into your project's docs or specs and reference it in your agent prompt or `AGENTS.md`.

---

## API Keys & Provider Setup

Export your provider keys in your host shell profile (`~/.bashrc` or `~/.zshrc`):

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."
export OPENCODE_API_KEY="opencode-..."
export OLLAMA_BASE_URL="http://host.docker.internal:<PORT>/v1"

```

The runner automatically forwards these environment variables into the container.

---

## Updating the Default Sandbox

To pull upstream OpenCode releases, refresh default packages, and rebuild the base global image:

```bash
make update

```

---

## Uninstallation & Cleanup

To remove the installed runner binary and the default Docker image:

```bash
make clean

```

*(Optional)* To clear persistent OpenCode login credentials, sessions, and caches:

```bash
rm -rf ~/.opencode-docker

```

