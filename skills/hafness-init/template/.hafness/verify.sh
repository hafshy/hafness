#!/usr/bin/env bash
# Hafness gate. One script, one exit code, one machine-parseable verdict.
#
# RULE: never add a check whose command was not found in this project.
# A check that cannot run is worse than no check. Delete it, do not stub it.
#
# Every file this harness generates is human-readable so you can review it before
# anything runs. Readable formats drift, so the format contract is linted below —
# that is the same rule written twice: prose in the file, a check in this script.

set -uo pipefail
HAF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
START=$SECONDS

# --log <feature|—> <attempt> <budget>: also append a run block to log/<today>.md.
# The header line is written here, not by the agent, so the grammar cannot drift.
LOG_FEATURE=""; LOG_ATTEMPT=""; LOG_BUDGET=""
if [ "${1:-}" = "--log" ]; then
  LOG_FEATURE="${2:?--log needs <feature|—> <attempt> <budget>}"
  LOG_ATTEMPT="${3:?--log needs <attempt>}"
  LOG_BUDGET="${4:?--log needs <budget>}"
fi

FAILED=0
run() {
  local label="$1"; shift
  echo "--- ${label}"
  if "$@"; then echo "    ok"; else echo "    FAILED (${label})"; FAILED=1; fi
}

# --- harness self-lint: the format contract ----------------------------------
harness_lint() {
  local bad=0
  local f

  # The map must stay a map.
  f="$HAF/HAFNESS.md"
  if [ -f "$f" ] && [ "$(wc -l < "$f")" -gt 60 ]; then
    echo "    HAFNESS.md is over 60 lines — the map is becoming a manual"
    bad=1
  fi

  # Every file in the harness must be named in the map. An undocumented file is one
  # the next session will not know to read — or worse, will half-remember.
  if [ -f "$HAF/HAFNESS.md" ]; then
    local rel undoc=""
    while IFS= read -r rel; do
      case "$rel" in
        HAFNESS.md) continue ;;
        log/[0-9]*.md) grep -q '`log/`' "$HAF/HAFNESS.md" && continue ;;
        scope/contracts/*) grep -q '`scope/contracts/`' "$HAF/HAFNESS.md" && continue ;;
        log/receipts/*) grep -q '`log/receipts/`' "$HAF/HAFNESS.md" && continue ;;
        archive/*) grep -q '`archive/`' "$HAF/HAFNESS.md" && continue ;;
        rules/*) grep -q '`rules/`' "$HAF/HAFNESS.md" && continue ;;
      esac
      grep -qF -- "\`$rel\`" "$HAF/HAFNESS.md" || undoc="$undoc $rel"
    done < <(cd "$HAF" && find . -type f | sed 's|^\./||' | sort)
    if [ -n "$undoc" ]; then
      echo "    files not named in HAFNESS.md:"
      for rel in $undoc; do echo "      $rel"; done
      bad=1
    fi
  fi

  # FEATURES.md column contract.
  f="$HAF/scope/FEATURES.md"
  if [ -f "$f" ]; then
    local want='| ID | Title | Deps | Status | Contract | Evidence |'
    if ! grep -qxF "$want" "$f"; then
      echo "    FEATURES.md header drifted"
      echo "      expected: $want"
      bad=1
    fi
    # Row shape: 6 columns between the outer pipes.
    if awk -F'|' '/^\| F-/ && NF != 8 {print "      malformed row: " $0}' "$f" | grep -q .; then
      awk -F'|' '/^\| F-/ && NF != 8 {print "      malformed row: " $0}' "$f"
      echo "    FEATURES.md has rows with the wrong number of columns"
      bad=1
    fi
    # done/archived must carry an evidence id.
    if awk -F'|' '/^\| F-/ && $5 ~ /done|archived/ && $7 ~ /^[[:space:]]*(—|-)?[[:space:]]*$/ {print}' "$f" | grep -q .; then
      echo "    a feature is done or archived with no evidence id:"
      awk -F'|' '/^\| F-/ && $5 ~ /done|archived/ && $7 ~ /^[[:space:]]*(—|-)?[[:space:]]*$/ {print "      " $2}' "$f"
      bad=1
    fi
    # Empty cells must be an em dash, never blank.
    if awk -F'|' '/^\| F-/ {for(i=2;i<=7;i++) if($i ~ /^[[:space:]]*$/) {print; break}}' "$f" | grep -q .; then
      echo "    FEATURES.md has blank cells — use — instead"
      bad=1
    fi
  fi

  # profile.sh must declare a stack and at least one runnable check.
  f="$HAF/profile.sh"
  if [ -f "$f" ]; then
    if ! grep -q '^HAF_STACK=' "$f"; then
      echo "    profile.sh is missing HAF_STACK"
      bad=1
    fi
    if grep -qE '^HAF_(BUILD|TEST|LINT|TYPECHECK)="[^"]*\$' "$f"; then
      echo "    profile.sh has an unterminated command string"
      bad=1
    fi
  fi

  # Run-log header grammar. Readable, but still one regex.
  local grammar='^## r-[0-9]+ · [0-9]{2}:[0-9]{2} · (F-[0-9]+|—) · attempt [0-9]+/[0-9]+ · (PASS|FAIL|ESCALATED) · .+$'
  local drift
  for f in "$HAF"/log/[0-9]*.md; do
    [ -e "$f" ] || continue
    drift="$(grep '^## ' "$f" | grep -vE "$grammar" || true)"
    if [ -n "$drift" ]; then
      echo "    run-log header does not match the grammar in $(basename "$f"):"
      printf '%s\n' "$drift" | sed 's/^/      /'
      bad=1
    fi
  done

  return $bad
}

run "harness format" harness_lint

# --- project checks: whatever profile.sh declares, nothing else -------------
if [ ! -f "$HAF/profile.sh" ]; then
  echo "no profile.sh — run /hafness-init to detect the stack"
  echo "HAFNESS_VERIFY: FAIL"
  exit 2
fi
# shellcheck source=/dev/null
. "$HAF/profile.sh"

DEFINED=0
check() {                       # check <label> <command string>
  local label="$1" cmd="${2:-}"
  [ -n "$cmd" ] || { echo "--- ${label}"; echo "    skipped — not found in this project"; return 0; }
  DEFINED=1
  run "$label" bash -c "$cmd"
}

check "build"     "${HAF_BUILD:-}"
check "test"      "${HAF_TEST:-}"
check "lint"      "${HAF_LINT:-}"
check "typecheck" "${HAF_TYPECHECK:-}"

for entry in "${HAF_EXTRA[@]:-}"; do
  [ -n "$entry" ] || continue
  check "${entry%%|*}" "${entry#*|}"
done

if [ "$DEFINED" -eq 0 ]; then
  echo "profile.sh declares no runnable checks — a harness that verifies nothing is not a harness"
  echo "HAFNESS_VERIFY: FAIL"
  exit 2
fi

if [ "$FAILED" -eq 0 ]; then VERDICT=PASS; EXIT=0; else VERDICT=FAIL; EXIT=1; fi
echo "HAFNESS_VERIFY: $VERDICT"

# --- run log: one block per run, header written mechanically -------------------
if [ -n "$LOG_FEATURE" ]; then
  [ "$VERDICT" = FAIL ] && [ "$LOG_ATTEMPT" -ge "$LOG_BUDGET" ] && VERDICT=ESCALATED
  # Only block headers and receipt filenames count — prose mentioning an id does not.
  last="$({ grep -hoE '^## r-[0-9]{4}' "$HAF"/log/[0-9]*.md 2>/dev/null | cut -c4-
            ls "$HAF/log/receipts" 2>/dev/null | grep -oE '^r-[0-9]{4}'; } | sort | tail -1)"
  next=$(( 10#${last#r-} + 1 ))
  run_id="$(printf 'r-%04d' "$next")"
  today="$HAF/log/$(date +%F).md"
  dur=$(( SECONDS - START ))
  if [ ! -f "$today" ]; then
    printf '# %s\n\nAppend only. Never edit a block once written. One block per run.\n\n' "$(date +%F)" > "$today"
    printf '    ## <run-id> · <HH:MM> · <feature-id> · attempt <n>/<budget> · <PASS|FAIL|ESCALATED> · <duration>\n\n---\n' >> "$today"
  fi
  printf '\n## %s · %s · %s · attempt %s/%s · %s · %dm%02ds\n\n**Verdict** `HAFNESS_VERIFY: %s` (exit %d)\n' \
    "$run_id" "$(date +%H:%M)" "$LOG_FEATURE" "$LOG_ATTEMPT" "$LOG_BUDGET" "$VERDICT" $((dur/60)) $((dur%60)) \
    "$([ "$EXIT" -eq 0 ] && echo PASS || echo FAIL)" "$EXIT" >> "$today"
  echo "HAFNESS_RUN: $run_id"
fi
exit "$EXIT"
