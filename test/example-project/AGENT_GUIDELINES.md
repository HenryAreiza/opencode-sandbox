# AI Agent Guidelines for Example Project

This file guides AI Coding Agents on maintaining the custom sandbox environment files in `opencode-sandbox/`.

## Agent Instructions

1. **Package Installations:**
   - If you install system packages via `apk add <pkg>`, append `<pkg>` to `opencode-sandbox/packages.txt`.
   - If you install Python packages via `pip install <pkg>`, append `<pkg>` to `opencode-sandbox/requirements.txt`.
   - If you install other tools, add their installation instructions to `opencode-sandbox/Dockerfile`.

2. **Rebuild Notification:**
   - After updating any files in `opencode-sandbox/`, notify the user:
     *"Environment files updated. Re-run with `opencode-sandbox --rebuild` to bake these changes into the container image."*

3. **User ID and Ownership:**
   - Ensure created files match host ownership. Do not alter non-root user setup in `opencode-sandbox/Dockerfile`.
