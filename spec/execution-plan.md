# Spec-Driven Development (SDD) Execution Plan: Custom Docker Images & Container Persistence

**Document Version:** 1.0.0  
**Status:** Approved for Implementation  
**Target System:** OpenCode Docker Sandbox (`opencode-runner.sh`, templates, docs, test suite)  
**Parent Guidelines:** `spec/guidelines.txt`

---

## 1. Specification & Requirements Summary

### 1.1 Objectives
1. **Custom Project Environments:** Allow downstream projects to supply their own Docker environment via an `opencode-sandbox/` subfolder (containing `Dockerfile`, package manifests, etc.) in the project root.
2. **Coexistence & Name Collision Avoidance:** Ensure multiple containers and custom images across various projects can run simultaneously without name or tag conflicts.
3. **Container Persistence by Default:** Keep containers created and reusable after session close by default (non-ephemeral), with configurable ephemeral execution via CLI flag (`--ephemeral`) or environment variable (`OPENCODE_EPHEMERAL=true`).
4. **AI Agent Guidelines Specification:** Provide a standardized markdown specification that project owners can place in their project's specs so AI coding agents know how to maintain and update the `opencode-sandbox/` environment files across changes.
5. **Testing Suite:** Provide a self-contained `test/` directory with a ready-to-test sample project and clear manual validation procedures.
6. **Backward Compatibility & Documentation:** Keep all existing runner and Docker options functional while documenting all new capabilities in `README.md`.

---

## 2. Technical Architecture & Design

### 2.1 Workspace Detection & Custom Image Build Flow
- When `opencode-sandbox.sh` / `opencode-runner.sh` executes from `$PWD`:
  - Detect whether `$PWD/opencode-sandbox/Dockerfile` exists.
  - If **present**:
    - Project Identifier: `slug=$(basename "$PWD")-$(printf "%s" "$PWD" | sha256sum | head -c 8)`
    - Image Tag: `opencode-sandbox-custom-${slug}:latest`
    - Check if image exists or trigger an incremental build with `--build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g)`.
  - If **absent**:
    - Fall back to standard `opencode-sandbox:latest`.

### 2.2 Container Lifecycle & Persistence Strategy
- **Container Identifier:** `opencode-sandbox-${slug}` (or with PID suffix when in ephemeral mode).
- **Persistent Mode (Default):**
  - If container exists and is running: attach or execute interactive session.
  - If container exists and is stopped: start and attach (`docker start -ai`).
  - If container does not exist: create and run without `--rm` flag.
- **Ephemeral Mode (`--ephemeral` / `OPENCODE_EPHEMERAL=1`):**
  - Run with `--rm` flag, removing container on exit.
- **Delimiter & Argument Handling:**
  - Preserve `--` delimiter syntax for passing custom `docker run` options.
  - Support runner-specific flags (`--ephemeral`, `--persist`, `--rebuild`, `--name`, `--help`) seamlessly before passing prompt / OpenCode arguments.

---

## 3. Work Breakdown Structure (Implementer Tasks)

### Phase 1: Runner Core Logic Refactoring
**Task 1.1: CLI Argument & Flag Parsing Engine**
- Implement option parser for runner flags (`--ephemeral`, `--persist`, `--rebuild`, `--help`) before the `--` docker flag delimiter and application arguments.
- Read environment variables (`OPENCODE_EPHEMERAL`, `OPENCODE_PERSIST`, `OPENCODE_REBUILD`, `OPENCODE_IMAGE`).

**Task 1.2: Project Identification & Collision Prevention**
- Implement deterministic path-based hashing (`sha256sum` truncated to 8 chars) paired with sanitized project folder names.
- Derive unique container names and image tags to enable simultaneous multi-project coexistence.

**Task 1.3: Custom Image Discovery and Build Automation**
- Detect `./opencode-sandbox/Dockerfile`.
- Execute automated build context using `./opencode-sandbox` with appropriate build arguments and tags.

**Task 1.4: Container Persistence & Re-attachment Logic**
- Implement container existence verification (`docker container inspect`).
- Implement lifecycle branching: `docker start -ai` for existing stopped containers, `docker exec` / attach for running containers, `docker run` for new containers.

---

### Phase 2: Agent Guidelines Specification
**Task 2.1: Create Standard Guidelines Document**
- Author `spec/agent-custom-image-guidelines.md` and `templates/agent-custom-image-guidelines.md`.
- Specify agent rules:
  1. Detect in-session package installations (e.g., `apk add`, `apt-get`, `pip install`, `npm install -g`, `cargo install`).
  2. Synchronize changes into `opencode-sandbox/Dockerfile`, `opencode-sandbox/packages.txt`, and `opencode-sandbox/requirements.txt`.
  3. Inform users when a container restart/rebuild is recommended.

---

### Phase 3: Test Environment & Example Project
**Task 3.1: Create Test Suite Directory Structure**
- Scaffold `test/` directory.
- Create `test/example-project/` representing a specialized environment (e.g., Python + Node.js + custom CLI utilities).
- Add `test/example-project/opencode-sandbox/Dockerfile`, `packages.txt`, `requirements.txt`, `AGENT_GUIDELINES.md`, and `main.py`.

**Task 3.2: Create Test Execution Guide**
- Author `test/README.md` providing step-by-step instructions for manual testing:
  - Scenario 1: Default base image execution.
  - Scenario 2: Custom image auto-discovery & build.
  - Scenario 3: Container persistence across terminal sessions.
  - Scenario 4: Ephemeral mode invocation (`--ephemeral`).
  - Scenario 5: Multi-project concurrent container coexistence.

---

### Phase 4: Documentation & Integration
**Task 4.1: Update Repository Documentation (`README.md`)**
- Document custom container feature and directory conventions.
- Document persistent vs. ephemeral container behavior and flags.
- Document multi-container concurrent workflows.
- Provide instructions on adopting the agent guidelines template in downstream projects.
- Preserve all existing commands, build steps, and workflows.

**Task 4.2: Build Script & Ignore Rule Refinement**
- Update `.gitignore` and `Makefile` if necessary to support testing and template paths.

---

### Phase 5: Verification & Quality Assurance
**Task 5.1: Static Validation**
- Validate bash script syntax via `bash -n opencode-runner.sh`.
- Validate mock argument configurations and dry-run flag checks.
- Verify file permissions (`chmod +x opencode-runner.sh`).

---

## 4. Execution Readiness & Launch Prompt

The implementation plan is structured and ready to be executed in sequence by `@implementer` subagents.
