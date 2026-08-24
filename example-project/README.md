# Example Project: Custom Ubuntu 24.04 Sandbox

This example demonstrates how `opencode-sandbox` automatically detects, builds, and manages custom project-specific environments.

---

## Test Scenarios

Navigate into this directory before running any test commands:
```bash
cd example-project

```

### Scenario 1: Automatic Custom Image Build & Default Persistence

Run OpenCode in this directory. The runner automatically detects `./opencode-sandbox/Dockerfile`, builds the custom image with your host UID/GID, and creates a deterministic persistent container.

```bash
opencode-sandbox

```

* **Verify inside container:**
* OpenCode runs inside Ubuntu 24.04.
* Run `python3 main.py` inside the terminal.
* Run `sudo apt-get update` to confirm passwordless sudo.


* **Exit:** Type `/exit` or hit `Ctrl+D`.
* **Re-run:** Running `opencode-sandbox` again immediately attaches/resumes the existing container without rebuilding.

---

### Scenario 2: Ephemeral (Disposable) Execution

Run a one-off session that discards the container on exit (`--rm`):

```bash
opencode-sandbox --ephemeral

```

* Changes written to project files persist on your host machine.
* Any uncommitted system packages installed via `sudo apt-get` disappear when the session ends.

---

### Scenario 3: Named Containers (Multi-Session Coexistence)

Assign an explicit container name to work on multiple tasks in parallel without conflicts:

```bash
# Terminal 1: Feature branch work
opencode-sandbox --name example-feature-auth

# Terminal 2: Bugfix work
opencode-sandbox --name example-bugfix-api

```

---

### Scenario 4: Port Forwarding

Expose container ports to your host machine using the `--` delimiter:

```bash
# Expose port 8000
opencode-sandbox -p 8000:8000 --

# Expose port and pass an initial prompt
opencode-sandbox -p 5000:5000 -- run "Run main.py"

```

---

### Scenario 5: Modifying Packages & Rebuilding

1. Add a new package (e.g., `jq`) to `./opencode-sandbox/packages.txt`.
2. Force a rebuild:
```bash
opencode-sandbox --rebuild

```
