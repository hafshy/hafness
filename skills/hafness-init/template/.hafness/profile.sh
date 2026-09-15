# Hafness stack profile — written by /hafness-init, sourced by verify.sh.
#
# REVIEW THIS BEFORE ANYTHING RUNS. A wrong command here makes every gate result
# meaningless: a green run that tested nothing is worse than a red one.
#
# This file is the single source of truth for what gets executed. verify.sh runs
# exactly what is set below and nothing else — there is no second list to keep in sync.
#
# Rules:
#   - Leave a variable EMPTY if the command was not found. Never guess.
#   - An empty variable is skipped, not failed.
#   - The trailing comment on each line records WHERE it was found. Keep it honest —
#     it is how you audit a detection you did not watch happen.

HAF_STACK=""        # e.g. swift-package   found: Package.swift

HAF_BUILD=""        # e.g. swift build     found: Package.swift
HAF_TEST=""         # e.g. swift test      found: Tests/
HAF_LINT=""         # e.g. swiftlint --strict   found: .swiftlint.yml
HAF_TYPECHECK=""    # e.g. pnpm tsc --noEmit    found: tsconfig.json

# Extra checks beyond the four above. One "label|command" per line.
# Same rule: only what really exists here.
HAF_EXTRA=(
  # "schema|swift run GenerateSchema --check"
)
