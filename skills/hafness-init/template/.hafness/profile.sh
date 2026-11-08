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

# Minutes one check may run before it, and everything it started, is stopped and failed.
# A hung simulator or test then fails the gate instead of holding it for hours.
HAF_TIMEOUT_MIN=20

# Optional: run a check only when a changed file is under one of its paths. One
# "label|prefix prefix…" per line; a check not listed always runs. Use it when the repo holds
# more than one app, so an iOS change does not run the web suite. `verify.sh --all` runs
# everything, and so does a clean tree or a change to profile.sh or verify.sh.
HAF_PATHS=(
  # "ios test|ios/ shared/"
)

# Optional: slow checks — UI journeys, e2e suites, anything that drives a simulator or a
# browser. One label per line. Skipped on ordinary gate runs, so retries stay quick; they
# run with `verify.sh --slow` once the fast checks pass, and a spec is done only then.
HAF_SLOW=(
  # "ios ui"
)
