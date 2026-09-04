# Ops — secrets & machine auth

## 1Password service account (this machine)

The machine's 1Password service account token is used on demand, never stored on disk.

- **Setup (one-time):** `op-sa-setup` — hidden-prompt capture, validates via `op service-account ratelimit` before storing the token as an API Credential item ("1Password Service Account Token") in the **Employee** vault. Requires the service account to already exist (1Password > Developer > Service Accounts).
- **Per-shell use:** `opsa` (zsh function in zshrc) — exports `OP_SERVICE_ACCOUNT_TOKEN` fetched at call time via `op-sa` (reads the Employee vault item through the desktop app integration). Personal `op` usage in other shells is unaffected; with the var set, `op` commands in that shell run as the service account.
- **Supported under the token:** `op read`, `op inject`, `op run`, `op item`, `op document` (service-account vaults). Management commands (`op user`, `op group`, `op connect`, `op events-api`, `op vault edit`) are not.
- **Rotation:** create/replace the token in the 1Password app, then re-run `op-sa-setup` (delete the old item first if reusing the title).
- Gotcha: `op whoami` reports "not signed in" under desktop app integration — test auth with a real command (`op vault list`), not `whoami`.
