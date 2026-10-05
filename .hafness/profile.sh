# Hafness stack profile — this repo builds Hafness itself.
#
# REVIEW THIS BEFORE ANYTHING RUNS. A wrong command here makes every gate result
# meaningless: a green run that tested nothing is worse than a red one.
#
# verify.sh sources this file and runs exactly what is set below, nothing else.
# Leave a variable EMPTY if the command does not exist yet. Empty is skipped, not failed.

HAF_STACK="claude-plugin"   # found: this repo is the Hafness plugin source

HAF_BUILD=""                # nothing to build — markdown and shell
HAF_TEST="bash test/selfhost.sh"   # found: test/selfhost.sh
HAF_LINT="for f in .hafness/*.sh test/selfhost.sh; do bash -n \"\$f\" || exit 1; done"   # found: all shell
HAF_TYPECHECK=""            # not applicable

HAF_EXTRA=(
  "docs-links|! grep -rhoE '\]\(([0-9a-zA-Z._/-]+\.md)\)' docs README.md HANDOFF.md | sed -E 's/.*\((.*)\)/\1/' | while read -r l; do [ -e \"docs/\$l\" ] || [ -e \"\$l\" ] || echo \"broken: \$l\"; done | grep ."
)
