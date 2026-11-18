# Current

Updated: 2026-11-18

## In flight

nothing — F-009 done; the 2026-11-08 token and gate-time changes landed outside the loop
(see `state/decisions.md`)

## Next action

1. First real use: `/hafness-init` in an iOS repo.
2. Optional: install the history and board hooks in this repo (`.claude/settings.json`).
3. Optional: `/hafness-feedback F-009 …` if anything in the loop should change.

## Open risks

- Every skill is prose; `verify.sh` (lint + scope fence) is the only boundary. The skills'
  "refuse" steps are guidance until a hook enforces them.
- The scope fence compares against HEAD, so uncommitted work from before a task trips it.
- The history hook needs `python3` and logs everything typed. Init gitignores `history.md`
  and `board.html`; this repo still commits `board.html` and runs neither hook.
- The loop skills (describe, plan, implement, feedback) have not yet been driven end to end
  in a fresh session; `test/selfhost.sh` covers the scripts, not the prose.

## Last run

r-0003 · PASS · 2026-10-12

## Board

Local: `.hafness/board.html`. Not published — `/hafness-board` publishes on request.
