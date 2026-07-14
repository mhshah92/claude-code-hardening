# Claude Code Security Baseline

This project provides a managed security baseline for Claude Code across macOS, Linux/WSL2 and Windows.

## Threat model

Designed to reduce risk from:
- Accidental prompts
- Prompt injection
- Overly-permissive agent execution

Not designed to protect against:
- Local administrators
- Root users
- Modified Claude Code binaries

## Notes

- Permission rules should be customized for your organization.
- macOS uses Seatbelt sandboxing.
- Linux/WSL2 uses Bubblewrap.
- Native Windows currently lacks equivalent OS-level sandbox enforcement.
