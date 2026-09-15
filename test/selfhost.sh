#!/usr/bin/env bash
# Self-host check: the shipped template produces a harness that passes its own gate,
# the run-log writer emits a block the lint accepts, and the plugin/skills are well-formed.
# ponytail: assert-style bash, no framework. Add a case when a real run breaks something.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TPL="$ROOT/skills/hafness-init/template"
fail() { echo "  FAIL: $*"; exit 1; }

# 1. manifest parses and names the plugin
python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert d["name"]=="hafness"' \
  "$ROOT/.claude-plugin/plugin.json" || fail "plugin.json invalid"

# 2. every skill has frontmatter name == its directory
for d in "$ROOT"/skills/*/; do
  n="$(basename "$d")"
  grep -qx "name: $n" "$d/SKILL.md" || fail "skills/$n/SKILL.md frontmatter name != $n"
done
[ "$(ls -d "$ROOT"/skills/*/ | wc -l)" -eq 6 ] || fail "expected 6 skills"

# 3. template and root verify.sh are the same script
cmp -s "$ROOT/.hafness/verify.sh" "$TPL/.hafness/verify.sh" || fail "template verify.sh drifted from root"

# 4. a fresh project from the template passes its own gate once one check exists
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
cp -R "$TPL/." "$tmp/"
[ -d "$tmp/.hafness" ] || fail "template copy lost .hafness/"
[ -f "$tmp/.hafness/log/2026-09-15.md" ] || fail "template lost its example log"
rm "$tmp/.hafness/log/2026-09-15.md"   # as /hafness-init does
perl -pi -e 's/^HAF_STACK=""/HAF_STACK="test"/; s/^HAF_TEST=""/HAF_TEST="true"/' "$tmp/.hafness/profile.sh"
out="$(bash "$tmp/.hafness/verify.sh" --log F-001 1 3 2>&1)"; rc=$?
[ $rc -eq 0 ] || fail "fresh template gate failed:\n$out"
grep -q 'HAFNESS_VERIFY: PASS' <<<"$out" || fail "no PASS verdict"
grep -q 'HAFNESS_RUN: r-0001' <<<"$out" || fail "first real run should be r-0001, got: $(grep HAFNESS_RUN <<<"$out")"
out="$(bash "$tmp/.hafness/verify.sh" --log F-001 2 3 2>&1)"
grep -q 'HAFNESS_RUN: r-0002' <<<"$out" || fail "second run should be r-0002"
# the block it wrote must pass the grammar lint on the next run
bash "$tmp/.hafness/verify.sh" >/dev/null 2>&1 || fail "written run block failed the grammar lint"
# a template with nothing runnable must refuse to pass
cp -R "$TPL/." "$tmp/empty/"
bash "$tmp/empty/.hafness/verify.sh" >/dev/null 2>&1 && fail "empty profile passed the gate"

echo "  selfhost ok"
