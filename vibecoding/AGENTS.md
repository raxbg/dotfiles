# OpenCode Dotfiles - Agent Guide

## Commands
- No build/lint/test commands (dotfiles repo)
- Docker-based development with `run.sh`
- Build image: `docker build -t opencode:latest .`

## Code Style
- Shell scripts: Use bash, POSIX-compliant
- Docker: Use node:24-slim base image
- JSON: Use standard JSON formatting
- Naming: kebab-case for files, UPPER_CASE for env vars
- Comments: Use `#` for shell, `//` for JSON (where allowed)

## File Structure
- `Dockerfile` - Container configuration
- `opencode.json` - OpenCode CLI configuration
- `run.sh` - Docker runner script
- No Cursor/Copilot rules found