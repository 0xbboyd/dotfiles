# Ops — secrets & machine auth

## 1Password service account (this machine)

The machine's 1Password service account token backs two paths:

1. **Interactive shells:** on-demand fetch, never on disk.
2. **Hermes (process-wide):** token stored in `~/.hermes/.env` (0600). Hermes loads `.env` into every process at startup (`env_loader.py`, override=true), so `op` inside Hermes sessions/cron/agents runs as the service account and never touches the desktop app / polkit. This — not the `secrets.onepassword` flag — is the polkit fix.

Note: `secrets.onepassword.enabled` (the `op://` reference-resolution layer) is **disabled** on this host — with no reference mappings it only printed a misleading "run setup" nag on every Hermes command. The token path above works independently. Re-enable with `hermes secrets onepassword setup` only when mapping `ENV_VAR=op://...` references (requires re-storing the token via `hermes secrets onepassword token` too).

- **Setup (one-time):** `op-sa-setup` — hidden-prompt capture, validates via `op service-account ratelimit` before storing the token as an API Credential item ("1Password Service Account Token") in the **Employee** vault. Requires the service account to already exist (1Password > Developer > Service Accounts).
- **Per-shell use:** `opsa` (zsh function in zshrc) — exports `OP_SERVICE_ACCOUNT_TOKEN` fetched at call time via `op-sa` (reads the Employee vault item through the desktop app integration). Personal `op` usage in other shells is unaffected; with the var set, `op` commands in that shell run as the service account.
- **Hermes integration:** `hermes secrets onepassword setup` enables but does NOT persist the token — append it to `~/.hermes/.env` (or use `hermes secrets onepassword token`). Map secrets with `hermes secrets onepassword set ENV_VAR "op://<vault>/<item>/<field>"`; they resolve at Hermes startup (300s cache). Preview with `sync`.
- **Vault scoping:** the service account can only see its granted vaults (Backend, dev, Engineering, Integrations, ...) — NOT Employee. Automation secrets go in service-account vaults; personal secrets stay in Employee, reachable only through the desktop app / `opsa` path.
- **Personal op inside Hermes sessions:** with the token env set process-wide, `op` in Hermes terminal sessions runs as the service account. For personal vaults, `unset OP_SERVICE_ACCOUNT_TOKEN` first — desktop app integration takes over.
- **Supported under the token:** `op read`, `op inject`, `op run`, `op item`, `op document` (service-account vaults). Management commands (`op user`, `op group`, `op connect`, `op events-api`, `op vault edit`) are not.
- **Rotation:** create/replace the token in the 1Password app, then re-run `op-sa-setup` (delete the old item first if reusing the title) and update `~/.hermes/.env` (`hermes secrets onepassword token`).
- Gotcha: `op whoami` reports "not signed in" under desktop app integration — test auth with a real command (`op vault list`), not `whoami`.
