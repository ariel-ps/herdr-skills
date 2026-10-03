#!/usr/bin/env sh
# Install all skills under skills/ from GitHub or a local checkout.
set -eu

REPO="${HERDR_SKILLS_REPO:-ariel-ps/herdr-skills}"
REF="${HERDR_SKILLS_REF:-main}"
SUBPATH="${HERDR_SKILLS_SUBPATH:-skills}"
MODE="${1:-}"

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
repo_root=$(CDPATH='' cd -- "$script_dir/../../.." && pwd -P)
skills_root="$repo_root/skills"

install_local() {
  if [ ! -d "$skills_root" ]; then
    echo "herdr-skills: missing $skills_root" >&2
    exit 1
  fi
  for agent_dir in \
    "${HOME}/.cursor/skills" \
    "${HOME}/.agents/skills" \
    "${HOME}/.claude/skills" \
    "${HOME}/.codex/skills"
  do
    mkdir -p "$agent_dir"
    for skill_path in "$skills_root"/*/; do
      [ -f "${skill_path}SKILL.md" ] || continue
      name=$(basename "$skill_path")
      rm -rf "${agent_dir}/${name}"
      cp -R "$skill_path" "${agent_dir}/${name}"
      echo "installed ${name} -> ${agent_dir}/${name}"
    done
  done
}

install_remote() {
  if ! command -v npx >/dev/null 2>&1; then
    echo "herdr-skills: npx not found; clone the repo and run: sh $0 --local" >&2
    exit 1
  fi
  # Pin ref via tree URL when not main (skills CLI resolves owner/repo/subpath).
  source="${REPO}/${SUBPATH}"
  if [ "$REF" != "main" ]; then
    source="https://github.com/${REPO}/tree/${REF}/${SUBPATH}"
  fi
  npx --yes skills add "$source" --all -g -y \
    --agent cursor,claude-code,codex 2>/dev/null \
    || npx --yes skills add "$source" --all -g -y
  npx --yes skills add herdrdev/herdr --skill herdr -g -y 2>/dev/null \
    || true
}

case "$MODE" in
  --local)
    install_local
    ;;
  --remote|"")
    install_remote
    ;;
  *)
    echo "usage: $0 [--local|--remote]" >&2
    exit 1
    ;;
esac

echo "herdr-skills: done"
