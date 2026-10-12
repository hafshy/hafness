#!/usr/bin/env bash
# Prompt hook (UserPromptSubmit). Appends every prompt to history.md, tagged with the
# command name when it runs a Hafness skill, then redraws the board.
#
# Installed by /hafness-init into .claude/settings.json. It must never block a prompt and
# never print: a prompt hook's stdout is added to the conversation. Every path exits 0.

HAF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
prompt="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("prompt", ""))' 2>/dev/null)" || exit 0
[ -n "$prompt" ] || exit 0

# /hafness-describe … or, as a plugin, /hafness:hafness-describe … → `describe`
tag="prompt"
if [[ "$prompt" =~ ^/(hafness:)?hafness(-([a-z]+))?([[:space:]]|$) ]]; then
  tag="\`${BASH_REMATCH[3]:-hafness}\`"
fi

{
  printf '\n## %s · %s\n\n' "$(date '+%Y-%m-%d %H:%M')" "$tag"
  printf '%s\n' "$prompt" | sed 's/^/> /'
} >> "$HAF/history.md" 2>/dev/null

bash "$HAF/board.sh" >/dev/null 2>&1
exit 0
