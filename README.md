# Claude Code — org-level hardening

Managed settings that lock down Claude Code on macOS: blocks reading secrets/credentials,
blocks curl/wget/rm -rf/force-push, disables permission-bypass mode, restricts to managed
permission rules and hooks only, and turns on bash sandboxing with a network domain allowlist.

## Files
- `managed-settings.json` — the policy itself, for manual placement or reference.
- `install.sh` — deploys `managed-settings.json` to `/Library/Application Support/ClaudeCode/`,
  backing up any existing file first and validating the JSON before locking down permissions.
- `rollback.sh` — removes the hardened settings, offering to restore the most recent backup
  if one exists.

## Usage

    chmod +x install.sh rollback.sh
    ./install.sh
    ./rollback.sh   # to undo

## Important limitation
This is enforcement by convention, not tamper-proofing: anyone with local sudo/admin on the
machine can edit or delete `managed-settings.json` directly. This only holds as a real control
if end users do NOT have local admin rights, or if the policy is delivered via MDM / server-managed
settings rather than trusted from a local file that an admin user could edit.

## Verify after installing
Open a Claude Code session in any project and run `/permissions` to confirm the managed deny
rules are listed. Then test that a local `.claude/settings.local.json` trying to re-allow a
denied command (e.g. `curl`) has no effect — that's the proof the floor actually holds.
