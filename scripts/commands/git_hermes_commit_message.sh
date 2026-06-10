#!/usr/bin/env bash
set -euo pipefail

error() {
  echo "Error: $*" >&2
  exit 1
}

command -v git >/dev/null 2>&1 || error "git is not installed or not on PATH."
command -v hermes >/dev/null 2>&1 || error "hermes is not installed or not on PATH."
command -v python3 >/dev/null 2>&1 || error "python3 is not installed or not on PATH."

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "${repo_root}" ]] || error "not inside a git repository."

if git -C "${repo_root}" diff --cached --quiet --exit-code; then
  echo "No staged changes to generate a commit message for." >&2
  exit 1
fi

prompt="$(cat <<EOF
You are generating a commit message for staged git changes.

Repository path:
${repo_root}

Instructions:
- Inspect ONLY staged changes.
- Use commands like:
  git -C "${repo_root}" diff --cached --stat
  git -C "${repo_root}" diff --cached --name-status
  git -C "${repo_root}" diff --cached --no-ext-diff
- Ignore unstaged and untracked changes.
- Return the commit message wrapped exactly like this:
  COMMIT_MESSAGE_START
  <commit message>
  COMMIT_MESSAGE_END
- Do not put markdown, explanation, or prose outside those markers.
- Use Conventional Commit format.
- Keep the subject under 72 characters.
- Use the most accurate type: feat, fix, refactor, docs, test, chore, build, ci.
- Prefer domain behavior over implementation details.
- Do not include ticket IDs, PR numbers, or branch names unless explicitly present in the staged content.
- Do not add co-author trailers.
- Add a short body only if it materially improves the commit message.
EOF
)"

stdout_file="$(mktemp)"
stderr_file="$(mktemp)"
cleanup() {
  rm -f "${stdout_file}" "${stderr_file}"
}
trap cleanup EXIT

if ! hermes chat \
  --quiet \
  --source tool \
  --toolsets terminal,file \
  --query "${prompt}" \
  >"${stdout_file}" 2>"${stderr_file}"; then
  echo "Error: hermes failed to generate a commit message." >&2
  if [[ -s "${stderr_file}" ]]; then
    cat "${stderr_file}" >&2
  fi
  if [[ -s "${stdout_file}" ]]; then
    cat "${stdout_file}" >&2
  fi
  exit 1
fi

python3 - "${stdout_file}" "${stderr_file}" <<'PY'
import re
import sys
from pathlib import Path

stdout_path = Path(sys.argv[1])
stderr_path = Path(sys.argv[2])
text = stdout_path.read_text(errors="replace")

ansi_re = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
clean = ansi_re.sub("", text).replace("\r", "\n")
lines = [line.strip() for line in clean.splitlines()]

start = None
end = None
for idx, line in enumerate(lines):
    if line == "COMMIT_MESSAGE_START":
        start = idx + 1
    elif line == "COMMIT_MESSAGE_END" and start is not None:
        end = idx
        break

if start is not None and end is not None:
    message = "\n".join(lines[start:end]).strip()
    if message:
        print(message)
        raise SystemExit(0)

# Fallback for models that ignore the requested markers but still output a
# Conventional Commit message. Use the last matching line to avoid reasoning
# preamble noise from show_reasoning-enabled Hermes configs.
commit_re = re.compile(
    r"^(feat|fix|refactor|docs|test|chore|build|ci|perf|style|revert)"
    r"(\([^)]+\))?!?:\s+.+"
)
match_indexes = [idx for idx, line in enumerate(lines) if commit_re.match(line)]
if match_indexes:
    idx = match_indexes[-1]
    message_lines = []
    for line in lines[idx:]:
        if line.startswith("session_id:"):
            continue
        if line in {"COMMIT_MESSAGE_START", "COMMIT_MESSAGE_END"}:
            continue
        message_lines.append(line)
    message = "\n".join(message_lines).strip()
    if message:
        print(message)
        raise SystemExit(0)

print("Error: could not extract a Conventional Commit message from Hermes output.", file=sys.stderr)
if stderr_path.exists() and stderr_path.stat().st_size:
    print("--- hermes stderr ---", file=sys.stderr)
    print(stderr_path.read_text(errors="replace"), file=sys.stderr)
if clean.strip():
    print("--- hermes stdout ---", file=sys.stderr)
    print(clean.strip(), file=sys.stderr)
raise SystemExit(1)
PY
