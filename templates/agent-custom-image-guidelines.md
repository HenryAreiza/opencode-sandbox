# AI Agent Guidelines: Maintaining Custom OpenCode Sandbox Environments

**Target Audience:** AI Coding Agents (OpenCode, Claude Code, Cursor, Copilot, etc.) operating within an OpenCode Docker Sandbox.  
**Version:** 1.0.0  
**Scope:** Guidelines for creating, updating, and synchronizing project-specific Docker sandbox environments located in `opencode-sandbox/`.

---

## 1. Overview & Core Philosophy

This repository supports custom, project-isolated Docker sandbox environments. When working inside an OpenCode sandbox session, agents often need to install compilers, runtime libraries, linters, or system tools.

To ensure work remains reproducible and container environments remain up-to-date across restarts or across different developer machines:

> **Core Mandate:** Any in-session modification to the environment (installing packages, system utilities, or dependencies) **must be synchronized immediately** into the project's `opencode-sandbox/` directory.

---

## 2. Directory Structure & File Conventions

The `opencode-sandbox/` folder in the project root holds all custom environment definitions:

```text
my-project/
├── opencode-sandbox/
│   ├── Dockerfile         # (Required) Custom image build definition
│   ├── packages.txt       # (Optional) Alpine/System OS package list (one per line)
│   └── requirements.txt   # (Optional) Python dependencies list
├── spec/
│   └── AGENT_GUIDELINES.md # (This guidelines document)
└── ...
```

---

## 3. Synchronization Rules for AI Agents

Whenever you execute a command that installs or modifies tools in the running container, apply the following synchronization rules:

### 3.1 System Packages (APK / APT)
- **Session Action:** Running `sudo apk add <pkg>` or `sudo apt-get install <pkg>`.
- **Sync Requirement:** 
  - If `opencode-sandbox/packages.txt` is used by the Dockerfile, append the package name to `opencode-sandbox/packages.txt` (one per line, lowercase).
  - If packages are installed directly in `opencode-sandbox/Dockerfile`, add the package to the relevant `apk add` / `apt-get` layer.

### 3.2 Python Packages & CLI Tools
- **Session Action:** Running `pip install <pkg>` or `uv pip install <pkg>`.
- **Sync Requirement:**
  - If `opencode-sandbox/requirements.txt` exists and is meant for sandbox tooling, append the package and pinned version to `opencode-sandbox/requirements.txt`.
  - If the package is a project dependency, update the project's primary manifest (`pyproject.toml`, `requirements.txt`, etc.).

### 3.3 Node.js / Rust / Go / Other Global Tools
- **Session Action:** Running `npm install -g <pkg>`, `cargo install <pkg>`, `go install <pkg>`, etc.
- **Sync Requirement:**
  - Add the corresponding `RUN` command or step into `opencode-sandbox/Dockerfile` so the tool is automatically installed on future image builds.

### 3.4 Environment Variables & Configuration Files
- **Session Action:** Exporting environment variables or creating configuration files in `/etc/` or `/home/opencode/`.
- **Sync Requirement:**
  - Add `ENV KEY=VALUE` statements or `COPY` instructions into `opencode-sandbox/Dockerfile`.

---

## 4. User Notification & Rebuild Guidance

1. **Inform the User:** When you update any file under `opencode-sandbox/`, proactively notify the user in your final response:
   - Example: *"I have installed `<tool>` and updated `opencode-sandbox/packages.txt`. To bake this permanently into your custom image, you can run `opencode-sandbox --rebuild` next time."*
2. **Do Not Disrupt Ongoing Work:** Changes made during the interactive session are immediately usable in the current container; rebuilding is only needed for fresh or non-persistent environments.

---

## 5. Dockerfile Best Practices for Agents

When creating or modifying `opencode-sandbox/Dockerfile`:

1. **Base Image:**
   - Always derive from `opencode-sandbox:latest` or `ghcr.io/anomalyco/opencode:latest` to preserve OpenCode runtime capabilities.
2. **User Permissions & Non-Root Execution:**
   - Preserve `ARG USER_ID=1000` and `ARG GROUP_ID=1000` handling so files created in the workspace maintain correct host ownership.
   - Switch to `USER ${USER_NAME}` before the final `WORKDIR /workspace`.
3. **Layer Cleanliness:**
   - Combine package installations and clear caches in the same `RUN` layer (e.g. `rm -rf /var/cache/apk/* /tmp/*`).
4. **Deterministic Builds:**
   - Prefer version pinning where reproducibility is essential.

---

## 6. Version Control & Git Recommendations

- **Team Repositories:** Commit `opencode-sandbox/` to version control so all contributors share identical developer tooling.
- **Personal Customization:** If the custom sandbox is intended purely for personal local use, `opencode-sandbox/` may be added to the project's `.gitignore`.
