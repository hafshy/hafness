# Current

Updated: 2026-09-15

## In flight

Nothing. v0 (F-001…F-008) is built and archived under `r-0001`.

## Next action

1. `git init`, commit, push to `hafshy/hafness` so `npx skills add hafshy/hafness` resolves.
   Until then install from the local path: `npx skills add /path/to/Harness -a claude-code -y`.
2. First real use: `/hafness-init` in an iOS repo. That run is the first honest test of the
   detection table and will most likely produce the first `rules/swift.md` and the first
   journal entry.
3. v1 backlog is unplanned. `/hafness-plan` from the v1 table in `docs/01-design.md` when
   a real run has produced a reason to — not before.

## Open risks

- Every skill is prose; only `verify.sh` is a boundary. The "refuse" steps in `start`,
  `contract`, `handoff` are guidance until a hook enforces them (phase three, on evidence).
- The rubric threshold (no dimension < 3, total ≥ 20) is still a guess. First few real
  runs should calibrate it; write the move to `decisions.md`.
- The Xcode row of the detection table names a simulator (`iPhone 17`) that may not exist
  on a given machine. `init` should check `xcrun simctl list` — not done; fix when it bites.
- Nested `claude -p` could not authenticate here, so the end-to-end was walked by hand from
  the installed SKILL.md prose, not driven by a fresh session.

## Last run

r-0001 · PASS · 2026-09-15 · receipt `log/receipts/r-0001.md`
