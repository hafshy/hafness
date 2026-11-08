#!/usr/bin/env bash
# Hafness gate. One script, one exit code, one machine-parseable verdict.
# Format lint, then the scope fence, then whatever profile.sh declares.
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

# --log <feature|—>: also append a run block to log/<today>.md.
# The header, the attempt and the budget are worked out here, not by the agent, so none
# of them can drift: attempt = this feature's runs since its last PASS, plus one;
# budget = `Attempts:` in plans/<feature>.md, else 3.
# --slow: also run the checks named in HAF_SLOW (UI journeys, e2e suites). They are skipped
#         otherwise, so a fix-and-retry loop never repeats them; a spec is done only on a
#         --slow PASS.
# --all:  run every check — slow ones too, and those whose paths (HAF_PATHS) saw no change.
ALL=0; SLOW=0; args=()
for a in "$@"; do
  case "$a" in --all) ALL=1; SLOW=1 ;; --slow) SLOW=1 ;; *) args+=("$a") ;; esac
done
set -- "${args[@]:-}"

LOG_FEATURE=""; LOG_ATTEMPT=""; LOG_BUDGET=""
if [ "${1:-}" = "--log" ]; then
  LOG_FEATURE="${2:?--log needs <feature|—>}"
  # Only a full PASS resets the count. A PASS whose **Checks** line skipped slow checks
  # neither resets nor counts, so slow failures still climb to ESCALATED.
  LOG_ATTEMPT="$(cat "$HAF"/log/[0-9]*.md 2>/dev/null | awk -v f=" $LOG_FEATURE " '
    function settle() { if (pend == "PASS") n = 0; pend = "" }
    /^## r-[0-9]+ · / { settle(); if (index($0, " ·" f "·")) { if (/ · PASS · /) pend = "PASS"; else n++ } }
    /^\*\*Checks\*\* / && pend == "PASS" && !/skipped, slow: none/ { pend = "" }
    END { settle(); print n + 1 }')"
  LOG_BUDGET="$(grep -m1 -oE '^Attempts: [0-9]+' "$HAF/plans/$LOG_FEATURE.md" 2>/dev/null | grep -oE '[0-9]+$')"
  LOG_BUDGET="${LOG_BUDGET:-3}"
fi

FAILED=0
# Each check's full output goes to a file, never to the agent's context: a passing check
# prints "ok"; a failing one prints all of a short output, or the error lines and the tail
# of a long one (a failed xcodebuild is thousands of lines), plus the path to the full log.
OUTDIR="${TMPDIR:-/tmp}/hafness-verify.$$"; mkdir -p "$OUTDIR"
run() {
  local label="$1"; shift
  local out="$OUTDIR/${label// /-}.log" t0=$SECONDS took
  CUR_OUT="$out"
  echo "--- ${label}"
  if "$@" >"$out" 2>&1; then took=$((SECONDS - t0)); echo "    ok ($((took/60))m$(printf %02d $((took%60)))s)"; return 0; fi
  FAILED=1
  [ -f "$out.timeout" ] && echo "    timed out after ${HAF_TIMEOUT_MIN:-20} min and was stopped — a hung simulator or test, not a slow one"
  if [ "$(wc -l < "$out")" -le 40 ]; then
    cat "$out"
  else
    grep -iE 'error|fail|fatal|panic|exception|assert' "$out" | head -25
    echo "    … last lines:"; tail -n 15 "$out"
  fi
  echo "    FAILED (${label}) — full output: $out"
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

  # Every file in the harness must be named in the map or its file index (FILES.md). An
  # undocumented file is one the next session will not know to read — or will half-remember.
  if [ -f "$HAF/HAFNESS.md" ]; then
    local rel undoc="" map
    map="$(cat "$HAF/HAFNESS.md" "$HAF/FILES.md" 2>/dev/null)"
    while IFS= read -r rel; do
      case "$rel" in
        HAFNESS.md) continue ;;
        log/[0-9]*.md) grep -q '`log/`' <<<"$map" && continue ;;
        specs/*) grep -q '`specs/`' <<<"$map" && continue ;;
        plans/*) grep -q '`plans/`' <<<"$map" && continue ;;
        research/*) grep -q '`research/`' <<<"$map" && continue ;;
        rules/*) grep -q '`rules/`' <<<"$map" && continue ;;
        .DS_Store|*/.DS_Store) continue ;;
      esac
      grep -qF -- "\`$rel\`" <<<"$map" || undoc="$undoc $rel"
    done < <(cd "$HAF" && find . -type f | sed 's|^\./||' | sort)
    if [ -n "$undoc" ]; then
      echo "    files not named in HAFNESS.md or FILES.md:"
      for rel in $undoc; do echo "      $rel"; done
      bad=1
    fi
  fi

  # tasks.md column contract — also for tasks-done.md, where done specs' rows go.
  for f in "$HAF/tasks.md" "$HAF/tasks-done.md"; do
    [ -f "$f" ] || continue
    local want='| ID | Spec | Task | Status | Scope | Run |'
    if ! grep -qxF "$want" "$f"; then
      echo "    $(basename "$f") header drifted"
      echo "      expected: $want"
      bad=1
    fi
    # Row shape: 6 columns between the outer pipes.
    if awk -F'|' '/^\| T-/ && NF != 8' "$f" | grep -q .; then
      awk -F'|' '/^\| T-/ && NF != 8 {print "      malformed row: " $0}' "$f"
      echo "    tasks.md has rows with the wrong number of columns"
      bad=1
    fi
    if awk -F'|' '/^\| T-/ && $5 !~ /^ *(todo|doing|done|blocked|dropped) *$/' "$f" | grep -q .; then
      awk -F'|' '/^\| T-/ && $5 !~ /^ *(todo|doing|done|blocked|dropped) *$/ {print "      " $2 "has status" $5}' "$f"
      echo "    tasks.md has an unknown status"
      bad=1
    fi
    # done must carry the run id that proved it.
    local passed unproven
    passed="$(grep -hoE '^## r-[0-9]+ · .* · PASS · ' "$HAF"/log/[0-9]*.md 2>/dev/null | grep -oE '^## r-[0-9]+' | cut -c4-)"
    unproven="$(awk -F'|' '/^\| T-/ && $5 ~ /done/ {gsub(/[ `]/, "", $2); gsub(/[ `]/, "", $7); print $2, $7}' "$f" \
      | while read -r id rid; do grep -qxF -- "$rid" <<< "$passed" || echo "      $id: '$rid' is not a PASS run in log/"; done)"
    if [ -n "$unproven" ]; then
      echo "    a task is done without a passing run behind it:"
      printf '%s\n' "$unproven"
      bad=1
    fi
    if awk -F'|' '/^\| T-/ {for(i=2;i<=7;i++) if($i ~ /^[[:space:]]*$/) {print; break}}' "$f" | grep -q .; then
      echo "    tasks.md has blank cells — use — instead"
      bad=1
    fi
  done

  # Every spec opens with its id and carries a known status.
  # done means verified: the spec has tasks, and every live one is done — so, by the
  # check above, carries a PASS run.
  local id left
  for f in "$HAF"/specs/F-*.md; do
    [ -e "$f" ] || continue
    id="$(basename "$f" .md)"
    if grep -qx 'Status: done' "$f"; then
      left="$(awk -F'|' -v id="$id" '/^\| T-/ { gsub(/ /, ""); if ($3 == id) { n++; if ($5 != "done" && $5 != "dropped") l = l " " $2 } }
        END { print (n ? l : " (no tasks)") }' "$HAF/tasks.md" 2>/dev/null)"
      [ -z "$left" ] || { echo "    $id: done, but not every task is:$left"; bad=1; }
    fi
    head -1 "$f" | grep -qE '^# F-[0-9]+ — .+' || { echo "    $(basename "$f"): first line must be '# F-nnn — <title>'"; bad=1; }
    grep -qE '^Status: (draft|reviewed|planned|building|done|dropped)$' "$f" \
      || { echo "    $(basename "$f"): missing or unknown 'Status:' line"; bad=1; }
  done

  # Feedback and history headers: readable, but still one regex each.
  lint_headers() {              # lint_headers <file> <regex>
    [ -f "$1" ] || return 0
    local drift; drift="$(grep '^## ' "$1" | grep -vE "$2" || true)"
    [ -z "$drift" ] && return 0
    echo "    header does not match the grammar in $(basename "$1"):"
    printf '%s\n' "$drift" | sed 's/^/      /'
    return 1
  }
  lint_headers "$HAF/feedback.md" '^## FB-[0-9]+ · [0-9]{4}-[0-9]{2}-[0-9]{2} · F-[0-9]+ · (open|planned|done)$' || bad=1
  lint_headers "$HAF/history.md" '^## [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2} · (prompt|`[a-z]+`)$' || bad=1

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

# --- scope fence: changed files must sit inside the Scope of a task in progress ---
# ponytail: compares against HEAD, so uncommitted work from before the task trips it.
# Commit before /hafness-implement for a clean baseline; a per-task base commit if that bites.
ROOT="$(dirname "$HAF")"
changed_files() {               # every file changed since HEAD, plus untracked ones
  git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 || return 0
  (cd "$ROOT" && { git diff --name-only HEAD 2>/dev/null || git ls-files; git ls-files --others --exclude-standard; } | sort -u)
}

scope_fence() {
  local root scopes changed file pat ok out=""
  root="$ROOT"
  [ -f "$HAF/tasks.md" ] || return 0
  scopes="$(awk -F'|' '/^\| T-/ && $5 ~ /doing/ {print $6}' "$HAF/tasks.md" \
    | tr ',' '\n' | tr -d '`' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | grep -vx '—' | grep . || true)"
  if [ -z "$scopes" ]; then echo "    no task in progress — fence not armed"; return 0; fi
  if ! git -C "$root" rev-parse --git-dir >/dev/null 2>&1; then echo "    not a git repo — fence skipped"; return 0; fi
  changed="$(changed_files)"
  while IFS= read -r file; do
    case "$file" in
      # The gate's own files: in scope only when a doing task names them exactly.
      .hafness/verify.sh|.hafness/profile.sh|.hafness/policy.md)
        grep -qxF "$file" <<< "$scopes" || out="$out $file"; continue ;;
      ''|.hafness/*|CLAUDE.md|AGENTS.md) continue ;;
    esac
    ok=0
    while IFS= read -r pat; do
      case "$pat" in
        */) [[ "$file" == "$pat"* ]] && ok=1 ;;
        *)  [[ "$file" == $pat ]] && ok=1 ;;
      esac
    done <<< "$scopes"
    [ "$ok" -eq 1 ] || out="$out $file"
  done <<< "$changed"
  [ -z "$out" ] && return 0
  echo "    changed outside the Scope of every doing task:"
  for file in $out; do echo "      $file"; done
  return 1
}
run "scope fence" scope_fence

# --- project checks: whatever profile.sh declares, nothing else -------------
if [ ! -f "$HAF/profile.sh" ]; then
  echo "no profile.sh — run /hafness-init to detect the stack"
  echo "HAFNESS_VERIFY: FAIL"
  exit 2
fi
# shellcheck source=/dev/null
. "$HAF/profile.sh"

# Each check gets HAF_TIMEOUT_MIN minutes (default 20), then it and everything it started are
# stopped: a hung xcodebuild or simulator fails the gate instead of holding it for hours.
killtree() { local c; for c in $(pgrep -P "$1" 2>/dev/null); do killtree "$c"; done; kill -TERM "$1" 2>/dev/null; }
with_timeout() {                # with_timeout <command…>
  local out="$CUR_OUT" pid w rc
  "$@" & pid=$!
  ( sleep $(( ${HAF_TIMEOUT_MIN:-20} * 60 )); touch "$out.timeout"; killtree "$pid" ) >/dev/null 2>&1 & w=$!
  wait "$pid" 2>/dev/null; rc=$?  # 2>/dev/null: no "Terminated" job notice when it is stopped
  killtree "$w" 2>/dev/null; wait "$w" 2>/dev/null
  return "$rc"
}

# A check listed in HAF_PATHS ("label|prefix prefix…") runs only when a changed file sits
# under one of its prefixes. Everything runs with --all, when nothing changed (a clean tree
# proves nothing by skipping), or when profile.sh or verify.sh changed.
CHANGED="$(changed_files)"
SELECT=1
{ [ "$ALL" -eq 1 ] || [ -z "$CHANGED" ] || grep -qxE '.hafness/(profile|verify).sh' <<<"$CHANGED"; } && SELECT=0
RAN=""; SKIPPED=""; SLOWSKIPPED=""
is_slow() { local e; for e in "${HAF_SLOW[@]:-}"; do [ "$e" = "$1" ] && return 0; done; return 1; }
paths_for() {                   # paths_for <label> → its prefixes, or nothing
  local e
  for e in "${HAF_PATHS[@]:-}"; do [ "${e%%|*}" = "$1" ] && { echo "${e#*|}"; return; }; done
}
touched() {                     # touched <prefixes> → 0 if a changed file is under one
  local p f
  for p in $1; do
    while IFS= read -r f; do [[ -n "$f" && "$f" == "$p"* ]] && return 0; done <<< "$CHANGED"
  done
  return 1
}

DEFINED=0
SEEN=" "
check() {                       # check <label> <command string>
  local label="$1" cmd="${2:-}" paths
  SEEN="$SEEN$label "
  [ -n "$cmd" ] || { echo "--- ${label}"; echo "    skipped — not found in this project"; return 0; }
  DEFINED=1
  paths="$(paths_for "$label")"
  if [ "$SELECT" -eq 1 ] && [ -n "$paths" ] && ! touched "$paths"; then
    echo "--- ${label}"; echo "    skipped — nothing changed under $paths"
    SKIPPED="$SKIPPED, $label"; return 0
  fi
  if [ "$SLOW" -eq 0 ] && is_slow "$label"; then
    echo "--- ${label}"; echo "    skipped — slow; runs with --slow before the spec is done"
    SLOWSKIPPED="$SLOWSKIPPED, $label"; return 0
  fi
  RAN="$RAN, $label"
  run "$label" with_timeout bash -c "$cmd"
}

check "build"     "${HAF_BUILD:-}"
check "test"      "${HAF_TEST:-}"
check "lint"      "${HAF_LINT:-}"
check "typecheck" "${HAF_TYPECHECK:-}"

for entry in "${HAF_EXTRA[@]:-}"; do
  [ -n "$entry" ] || continue
  check "${entry%%|*}" "${entry#*|}"
done

# A label in HAF_PATHS or HAF_SLOW that names no check is a typo that silently does nothing.
stray=""
for e in "${HAF_PATHS[@]:-}"; do [ -z "$e" ] || [[ "$SEEN" == *" ${e%%|*} "* ]] || stray="$stray, ${e%%|*}"; done
for e in "${HAF_SLOW[@]:-}"; do [ -z "$e" ] || [[ "$SEEN" == *" $e "* ]] || stray="$stray, $e"; done
if [ -n "$stray" ]; then
  echo "--- profile labels"
  echo "    HAF_PATHS or HAF_SLOW names a check that does not exist: ${stray#, }"
  echo "    FAILED (profile labels)"; FAILED=1
fi

if [ "$DEFINED" -eq 0 ]; then
  echo "profile.sh declares no runnable checks — a harness that verifies nothing is not a harness"
  echo "HAFNESS_VERIFY: FAIL"
  exit 2
fi

if [ "$FAILED" -eq 0 ]; then VERDICT=PASS; EXIT=0; else VERDICT=FAIL; EXIT=1; fi
[ "$FAILED" -eq 0 ] && rm -rf "$OUTDIR"   # keep logs only when something failed
echo "HAFNESS_VERIFY: $VERDICT"

# --- run log: one block per run, header written mechanically -------------------
if [ -n "$LOG_FEATURE" ]; then
  [ "$VERDICT" = FAIL ] && [ "$LOG_ATTEMPT" -ge "$LOG_BUDGET" ] && VERDICT=ESCALATED
  # Only block headers count — prose mentioning an id does not.
  last="$(grep -hoE '^## r-[0-9]{4}' "$HAF"/log/[0-9]*.md 2>/dev/null | cut -c4- | sort | tail -1)"
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
  none() { [ -n "${1#, }" ] && echo "${1#, }" || echo none; }
  printf '**Checks** ran: %s · skipped, no change under their paths: %s · skipped, slow: %s\n' \
    "$(none "$RAN")" "$(none "$SKIPPED")" "$(none "$SLOWSKIPPED")" >> "$today"
  echo "HAFNESS_RUN: $run_id · attempt $LOG_ATTEMPT/$LOG_BUDGET · $VERDICT"
fi
exit "$EXIT"
