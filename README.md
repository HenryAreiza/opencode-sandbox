# OpenCode Docker Sandbox

A secure, containerized sandbox for running [OpenCode](https://opencode.ai) with file-system isolation, Python 3.14 pre-installed, non-root file ownership, and passwordless `sudo` privileges.

## Features

- **Filesystem Isolation:** Only mounts the current working directory (`$PWD`) into the container.
- **Clean File Ownership:** Runs using your host UID/GID; no `root`-owned files left behind.
- **In-Container Sudo:** The agent can run `sudo apt install <package>` during sessions to install required tools.
- **Customizable:** Add tools to `packages.txt` to bake them directly into the Docker image.
- **Persistent State:** Saves OpenCode authentication, configs, and session history under `~/.opencode-docker`.

---

## Quick Start

### 1. Clone & Build
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

Navigate to any project and run:

```bash
opencode-sandbox

```

Pass commands or prompts directly:

```bash
opencode-sandbox "Analyze the architecture in this repo"

```

### Passing Custom Docker Options

Use `--` as a delimiter to pass any standard `docker run` flags (ports, volumes, resource constraints) directly to Docker:

```bash
# Expose ports
opencode-sandbox -p 8080:8000 --

# Limit memory and pass a starting prompt
opencode-sandbox -m 4g -- "Review this codebase"

# Mount an extra directory
opencode-sandbox -v /path/to/shared:/shared --

```

---

## Customization

### Adding System Packages

1. Open `packages.txt` and append desired packages:
```text
nodejs
npm
ripgrep

```

2. Rebuild the image:
```bash
make build

```

### API Keys

Export your provider keys in your shell profile (`~/.bashrc` or `~/.zshrc`):

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."

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

## Uninstallation & Cleanup

To completely remove the installed runner binary and the local Docker image:

```bash
make clean

```

*(Optional)* To also clear persistent OpenCode login credentials, sessions, and caches:

```bash
rm -rf ~/.opencode-sandbox

```

