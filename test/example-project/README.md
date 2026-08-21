# Example Project (Custom Sandbox Testing)

This is a sample project demonstrating the custom Docker sandbox functionality of `opencode-sandbox`.

## Features
- **Custom Dockerfile:** Located at `opencode-sandbox/Dockerfile`.
- **System Packages:** Listed in `opencode-sandbox/packages.txt` (`curl`, `jq`, `figlet`, `cowsay`).
- **Python Dependencies:** Listed in `opencode-sandbox/requirements.txt` (`requests`, `rich`).
- **AI Agent Guidelines:** Documented in `AGENT_GUIDELINES.md`.

## How to Test

1. Navigate to this directory:
   ```bash
   cd test/example-project
   ```
2. Launch OpenCode Sandbox:
   ```bash
   opencode-sandbox
   ```
3. Inside the session, run:
   ```bash
   python main.py
   figlet "OpenCode"
   ```
4. Test rebuild workflow:
   ```bash
   opencode-sandbox --rebuild
   ```
