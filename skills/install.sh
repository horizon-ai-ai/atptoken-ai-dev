#!/bin/sh
set -eu

TARGET="${1:-codex}"
BASE_URL="${ATP_SKILLS_BASE_URL:-https://atptoken.ai/skills}"
FORCE="${ATP_SKILLS_FORCE:-0}"
SKILLS="atptoken-gateway atptoken-openai atptoken-anthropic atptoken-gemini atptoken-image atptoken-video atptoken-audio"

usage() {
  echo "Usage: install.sh [codex|claude|both]" >&2
  echo "Set ATP_SKILLS_FORCE=1 to replace an existing ATP skill." >&2
}

install_file() {
  url="$1"
  destination="$2"

  if [ -f "$destination" ] && [ "$FORCE" != "1" ]; then
    echo "skip: $destination already exists (set ATP_SKILLS_FORCE=1 to replace)"
    return 0
  fi

  temporary="${destination}.tmp.$$"
  trap 'rm -f "$temporary"' EXIT HUP INT TERM
  curl -fsSL "$url" -o "$temporary"
  mv "$temporary" "$destination"
  trap - EXIT HUP INT TERM
}

install_root() {
  root="$1"
  mkdir -p "$root"

  for skill in $SKILLS; do
    destination="$root/$skill"
    mkdir -p "$destination"
    install_file "$BASE_URL/$skill/SKILL.md" "$destination/SKILL.md"
  done

  references="$root/atptoken-gateway/references"
  mkdir -p "$references"
  install_file "$BASE_URL/atptoken-gateway/references/errors.md" "$references/errors.md"
  install_file "$BASE_URL/atptoken-gateway/references/files.md" "$references/files.md"
}

case "$TARGET" in
  codex)
    install_root "${CODEX_HOME:-$HOME/.codex}/skills"
    ;;
  claude)
    install_root "${CLAUDE_HOME:-$HOME/.claude}/skills"
    ;;
  both)
    install_root "${CODEX_HOME:-$HOME/.codex}/skills"
    install_root "${CLAUDE_HOME:-$HOME/.claude}/skills"
    ;;
  *)
    usage
    exit 2
    ;;
esac

echo "ATP skills installed for $TARGET."
