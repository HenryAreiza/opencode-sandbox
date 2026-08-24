# Specification: OpenCode Sandbox Environment Maintenance

## 1. Context & Purpose

This workspace runs inside a sandboxed container managed by `opencode-sandbox`.
When projects require custom environments (system libraries, language runtimes, compilers, headers), configuration files are stored locally under:

```text
<project-root>/opencode-sandbox/
├── Dockerfile
└── packages.txt   # (or distribution-specific dependency manifests)

```

As an AI agent with passwordless `sudo` access, you will frequently install, upgrade, or remove dependencies at runtime to fulfill implementation requirements.

**Objective:** Ensure that any runtime modification made to the running container is mirrored back into `<project-root>/opencode-sandbox/` so the container build definition remains deterministic, reproducible, and up to date across rebuilds.

---

## 2. Agent Operational Rules

### Rule 1: Dual-Action Synchronization

Whenever you execute a system package installation or removal command in the active shell (e.g., `sudo apt-get install`, `sudo apk add`, `sudo dnf install`), you **MUST** immediately update the corresponding manifest in `<project-root>/opencode-sandbox/`.

* **Never** install a permanent build dependency without recording it.
* **Always** place dependencies in their dedicated file (`packages.txt`, `requirements.txt`, or directly in `Dockerfile` if custom build steps/repos are required).

### Rule 2: Non-Destructive Base Requirements

When editing `<project-root>/opencode-sandbox/Dockerfile`, never remove base sandbox prerequisites:

1. **User UID/GID mapping:** Keep build arguments `USER_ID`, `GROUP_ID`, and `USER_NAME`.
2. **Sudoers configuration:** The non-root user must retain passwordless sudo (`NOPASSWD:ALL`).
3. **Working directory & Entrypoint:** Ensure `WORKDIR /workspace` and `ENTRYPOINT ["opencode"]` remain defined.

### Rule 3: Inform the User on State Changes

Whenever you update environment manifests:

1. State which packages or system tools were added/removed.
2. Remind the user that if they recreate or launch this project on another machine, `opencode-sandbox --rebuild` will regenerate this exact environment.

---

## 3. Supported Patterns & Manifest Structures

### Pattern A: Package-List Based (Ubuntu / Debian / Alpine)

If `<project-root>/opencode-sandbox/packages.txt` exists:

* Append newly installed packages to `packages.txt` under the relevant comment section.
* Keep entries alphabetized and remove temporary or redundant packages.

**Example Action:**

```bash
# Agent runs runtime command:
sudo apt-get install -y libpq-dev

# Agent updates ./opencode-sandbox/packages.txt:
# [Database drivers]
# libpq-dev

```

### Pattern B: Custom Toolchains / Repositories

If a tool requires adding a third-party PPA, custom GPG keys, or downloading pre-compiled binaries:

* Update `<project-root>/opencode-sandbox/Dockerfile` directly.
* Keep cache cleanups (`rm -rf /var/lib/apt/lists/*` or `rm -rf /var/cache/apk/*`) at the end of `RUN` layers to minimize image footprint.

---

## 4. Verification Checklist

Before completing a task that involved environment changes, confirm:

* [ ] All newly installed CLI tools or shared libraries are listed in `./opencode-sandbox/packages.txt` or `./opencode-sandbox/Dockerfile`.
* [ ] No hardcoded host paths or personal secrets (tokens, SSH keys) were written to `./opencode-sandbox/`.
* [ ] The updated Dockerfile builds cleanly without interactive prompts (use `-y` and `DEBIAN_FRONTEND=noninteractive`).

