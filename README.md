# OpenCode Docker Sandbox

A secure, containerized sandbox for running [OpenCode](https://opencode.ai) with file-system isolation, Python 3.14 pre-installed, non-root file ownership, passwordless `sudo` privileges, custom project environments, and persistent container lifecycles.

## Features

- **Filesystem Isolation:** Only mounts the current working directory (`$PWD`) into the container.
- **Clean File Ownership:** Runs using your host UID/GID; no `root`-owned files left behind.
- **In-Container Sudo:** The agent can run `sudo apk add <package>` or system package managers during sessions to install required tools.
- **Custom Project Environments:** Downstream projects can define specialized Docker environments in an `opencode-sandbox/` subfolder.
- **Persistent Containers by Default:** Keeps containers created and reusable after session close so in-session modifications persist, with configurable ephemeral execution.
- **Collision-Free Multi-Project Coexistence:** Deterministic path-based hashing ensures multiple distinct projects run simultaneously without image or container name collisions.
- **Persistent State:** Saves OpenCode authentication, configs, and session history under `~/.opencode-docker`.
- **AI Agent Integration:** Standardized guidelines template so AI agents automatically maintain and synchronize custom sandbox definitions.

---

## Quick Start

### 1. Clone & Build Base Image
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

If running `opencode-sandbox` says "command not found", add `~/.local/bin` to your shell configuration:

```bash
# For Bash (~/.bashrc):
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# For Zsh (~/.zshrc):
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Alternatively, add an alias to your shell profile (`~/.bashrc` or `~/.zshrc`):

```bash
alias opencode-docker="/path/to/opencode-sandbox/opencode-runner.sh"
```

---

## Usage

Navigate to any project directory and run:

```bash
opencode-sandbox
```

Pass commands or starting prompts directly:

```bash
opencode-sandbox "Analyze the architecture in this repo"
```

### Passing Custom Docker Options

Use `--` as a delimiter to pass standard `docker run` flags (ports, volumes, resource constraints) directly to Docker:

```bash
# Expose ports
opencode-sandbox -p 8080:8000 --

# Limit memory and pass a starting prompt
opencode-sandbox -m 4g -- "Review this codebase"

# Mount an extra directory
opencode-sandbox -v /path/to/shared:/shared --
```

---

## Container Lifecycle & Persistence

By default, `opencode-sandbox` operates in **persistent mode**:
- When you exit a session, the container is stopped rather than destroyed.
- When you re-enter the project directory and run `opencode-sandbox`, the existing container is restarted and reattached, preserving any tools or system configurations installed during previous sessions.

### Ephemeral Mode (`--ephemeral`)
To run a one-off session where the container is automatically destroyed upon exit (`--rm`):

```bash
opencode-sandbox --ephemeral
```

Or set the environment variable:
```bash
export OPENCODE_EPHEMERAL=true
```

### Command-Line Flags & Environment Variables

| Flag / Option | Environment Variable | Description |
|---|---|---|
| `--persist` | `OPENCODE_PERSIST=1` | Enable persistent container mode (default). |
| `--ephemeral` | `OPENCODE_EPHEMERAL=1` | Run ephemeral container, removing on exit. |
| `--rebuild` | `OPENCODE_REBUILD=1` | Force rebuild of project custom Docker image. |
| `--name <name>` | `OPENCODE_CONTAINER_NAME` | Override container name. |
| `--image <tag>` | `OPENCODE_IMAGE` | Override Docker image tag. |
| `-h`, `--help` | — | Display help information and options. |

---

## Custom Project Environments (`opencode-sandbox/`)

Projects requiring specialized runtimes, system dependencies, or compilers can define their own container environment by placing an `opencode-sandbox/` folder in the project root:

```text
my-project/
├── opencode-sandbox/
│   ├── Dockerfile         # Custom image definition
│   ├── packages.txt       # System OS packages
│   └── requirements.txt   # Python dependencies
├── src/
└── ...
```

### Automatic Discovery & Collision-Free Naming
When you run `opencode-sandbox` inside a project containing `opencode-sandbox/Dockerfile`:
1. The runner automatically detects the custom Dockerfile.
2. It generates a deterministic, collision-free slug based on the workspace path (e.g. `my-project-3a8f1b2c`).
3. It incrementally builds the custom image `opencode-sandbox-custom-my-project-3a8f1b2c:latest` if it does not already exist.
4. Multiple different projects can run concurrently without any container or image name collisions.

To force a rebuild of the custom image after modifying configuration files:
```bash
opencode-sandbox --rebuild
```

---

## AI Agent Integration Guidelines

When AI Coding Agents (such as OpenCode, Claude Code, or Cursor) operate inside a custom sandbox, they may install packages during execution.

To ensure that in-session changes are preserved for future builds:
1. Copy the reusable template from `templates/agent-custom-image-guidelines.md` into your project's specification directory (e.g., `spec/AGENT_GUIDELINES.md` or `.opencode/guidelines/custom-image.md`).
2. Point your AI agent to this document.
3. The agent will automatically synchronize any package installations (`apk add`, `pip install`, `npm install -g`) into `opencode-sandbox/packages.txt`, `opencode-sandbox/requirements.txt`, or `opencode-sandbox/Dockerfile`.

---

## Customizing the Global Base Image

If you are not using project-specific environments and want to add tools to the default global image:

1. Open `packages.txt` in this repository and append desired packages:
   ```text
   nodejs
   npm
   ripgrep
   ```

2. Rebuild the image:
   ```bash
   make build
   ```

---

## API Keys

Export your provider keys in your shell profile (`~/.bashrc` or `~/.zshrc`):

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."
export OPENCODE_API_KEY="opencode-..."
```

The runner script automatically forwards them into the container.

---

## Updating OpenCode & Dependencies

Because Docker caches base images locally, running `make build` will not automatically check for upstream updates.

To pull the latest official OpenCode base image, refresh all system packages from `packages.txt`, and rebuild without cache:

```bash
make update
```

---

## Testing & Validation Suite

A complete test suite and validation guide are available in the [`test/`](test/) directory:
- [Test Guide (`test/README.md`)](test/README.md): Detailed scenarios for validating base image runs, custom project environments, persistence, ephemeral mode, and multi-project coexistence.
- [Example Project (`test/example-project/`)](test/example-project/): A ready-to-test sample project with custom system utilities, Python packages, and agent guidelines.

---

## Uninstallation & Cleanup

To completely remove the installed runner binary and the local base Docker image:

```bash
make clean
```

*(Optional)* To also clear persistent OpenCode login credentials, sessions, and caches:

```bash
rm -rf ~/.opencode-docker
```
