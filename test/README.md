# Test Suite & Manual Validation Guide

This directory contains validation procedures and a ready-to-test sample project for the OpenCode Docker Sandbox runner (`opencode-sandbox` / `opencode-runner.sh`).

---

## Directory Structure

```text
test/
├── README.md               # This validation guide
└── example-project/        # Specialized custom environment sample
    ├── opencode-sandbox/
    │   ├── Dockerfile      # Custom Dockerfile for example project
    │   ├── packages.txt    # Custom system package list
    │   └── requirements.txt# Custom Python packages
    ├── AGENT_GUIDELINES.md # Embedded agent synchronization guidelines
    ├── main.py             # Sample application utilizing environment tools
    └── README.md           # Example project description
```

---

## Test Scenarios & Step-by-Step Validation

### Scenario 1: Default Base Image Execution (Standard Project)

**Objective:** Verify that running `opencode-sandbox` in a directory without an `opencode-sandbox/` folder uses the standard base image (`opencode-sandbox:latest`).

1. Create and enter a clean directory without custom Docker configuration:
   ```bash
   mkdir -p /tmp/test-standard-proj
   cd /tmp/test-standard-proj
   ```
2. Launch the sandbox:
   ```bash
   opencode-sandbox
   ```
3. **Expected Result:**
   - The runner detects no `opencode-sandbox/Dockerfile`.
   - Uses `opencode-sandbox:latest`.
   - Mounts `/tmp/test-standard-proj` to `/workspace` and assigns container name `opencode-sandbox-test-standard-proj-<hash>`.

---

### Scenario 2: Custom Image Auto-Discovery & Incremental Build

**Objective:** Verify that entering a project with `opencode-sandbox/Dockerfile` automatically builds and tags a custom image.

1. Navigate to the example project:
   ```bash
   cd /workspace/test/example-project  # or path/to/opencode-sandbox/test/example-project
   ```
2. Launch the sandbox:
   ```bash
   opencode-sandbox
   ```
3. **Expected Result:**
   - The runner detects `./opencode-sandbox/Dockerfile`.
   - Automatically builds `opencode-sandbox-custom-example-project-<hash>:latest` on the first run.
   - Installs the packages listed in `opencode-sandbox/packages.txt` and `opencode-sandbox/requirements.txt`.
   - Starts the session inside the custom environment.

---

### Scenario 3: Container Persistence Across Terminal Sessions

**Objective:** Verify that containers persist by default and preserve modified state across sessions.

1. Enter the example project and start a session:
   ```bash
   cd /workspace/test/example-project
   opencode-sandbox
   ```
2. Inside the session, install a temporary tool or create a file in `/tmp`:
   ```bash
   touch /tmp/session-marker.txt
   echo "persistent-test" > /tmp/session-marker.txt
   ```
3. Exit OpenCode (or exit the container session).
4. Run `docker ps -a` on the host:
   ```bash
   docker ps -a --filter "name=opencode-sandbox-example-project"
   ```
   *Notice the container exists with status `Exited` (not deleted).*
5. Re-run `opencode-sandbox`:
   ```bash
   opencode-sandbox
   ```
6. Verify inside the session that `/tmp/session-marker.txt` is still present:
   ```bash
   cat /tmp/session-marker.txt
   ```
7. **Expected Result:**
   - The runner outputs `Starting stopped container: opencode-sandbox-example-project-<hash>`.
   - All state in the container filesystem is preserved across restarts.

---

### Scenario 4: Ephemeral Mode Invocation (`--ephemeral`)

**Objective:** Verify that `--ephemeral` creates an isolated container and automatically cleans it up on exit (`--rm`).

1. Run with the `--ephemeral` flag:
   ```bash
   cd /workspace/test/example-project
   opencode-sandbox --ephemeral
   ```
2. Inside the session, exit immediately.
3. Check `docker ps -a`:
   ```bash
   docker ps -a --filter "name=ephemeral"
   ```
4. **Expected Result:**
   - The container was assigned an ephemeral name (`opencode-sandbox-...-ephemeral-<PID>`).
   - The container was automatically removed upon exit.
5. Alternatively, test using the environment variable:
   ```bash
   OPENCODE_EPHEMERAL=true opencode-sandbox
   ```

---

### Scenario 5: Multi-Project Concurrent Container Coexistence

**Objective:** Verify that two separate projects can run in parallel without container name or image tag collisions.

1. In Terminal 1:
   ```bash
   mkdir -p /tmp/project-alpha
   cd /tmp/project-alpha
   opencode-sandbox
   ```
2. In Terminal 2 (simultaneously):
   ```bash
   mkdir -p /tmp/project-beta
   cd /tmp/project-beta
   opencode-sandbox
   ```
3. In Terminal 3 (host check):
   ```bash
   docker ps --filter "name=opencode-sandbox-"
   ```
4. **Expected Result:**
   - Both containers run simultaneously:
     - `opencode-sandbox-project-alpha-<hash1>`
     - `opencode-sandbox-project-beta-<hash2>`
   - No naming collisions or port/mount interference.

---

### Scenario 6: Custom Image Rebuild (`--rebuild`)

**Objective:** Verify that modifying package files and passing `--rebuild` triggers an incremental rebuild.

1. Navigate to the example project:
   ```bash
   cd /workspace/test/example-project
   ```
2. Edit `opencode-sandbox/packages.txt` and add a new package (e.g. `htop`).
3. Run with `--rebuild`:
   ```bash
   opencode-sandbox --rebuild
   ```
4. **Expected Result:**
   - The runner triggers `docker build` for `opencode-sandbox-custom-example-project-<hash>:latest`.
   - The updated image includes `htop`.

---

### Scenario 7: Passing Custom Docker Options (`--` Delimiter)

**Objective:** Verify that custom Docker flags (ports, volume mounts, memory constraints) work seamlessly alongside runner flags.

1. Run with custom port mappings and memory limits:
   ```bash
   opencode-sandbox -p 9000:8000 -m 2g -- "Review this project"
   ```
2. Run with ephemeral mode and docker options:
   ```bash
   opencode-sandbox --ephemeral -p 9000:8000 --
   ```
3. **Expected Result:**
   - Docker options before `--` are passed directly to `docker run`.
   - Prompt/arguments after `--` are forwarded to OpenCode.
