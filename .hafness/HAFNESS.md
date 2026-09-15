# Hafness — map

Routing only. If you are tempted to explain something here, it belongs in `rules/`.
Hard limit: 60 lines, linted by `verify.sh`. The index below is routing, not explanation —
that is why it earns the space.

## Start every session

1. Read `state/current.md` — in flight, next action, open risks.
2. Read today's file in `log/`.
3. Read the open contract in `scope/contracts/`.
4. Print the next action. Do not open a source file before this.

## Generated files are drafts

Every file you generate is written for a human to read and is a draft until signed off.
After writing one, stop, say what it will cause, and wait. No bounded contract, no work.

## Every file in this harness

| Path | Job |
|---|---|
| `HAFNESS.md` | this map — routing, nothing else |
| `policy.md` | what needs approval, what is forbidden |
| `rubric.md` | what counts as good, scored |
| `profile.sh` | what will actually run; sourced by `verify.sh` |
| `verify.sh` | the gate — format lint, then the project checks |
| `rules/` | domain rules, loaded on demand only |
| `scope/FEATURES.md` | the backlog: deps, status, evidence |
| `scope/contracts/` | one bounded task each, signed off before work |
| `state/current.md` | in flight, next action, open risks |
| `state/decisions.md` | decision log — supersedes chat |
| `log/` | one dated file per day, one block per run |
| `log/journal.md` | lessons, promoted into rules or checks |
| `log/receipts/` | how each run produced its output |
| `archive/` | closed contracts, out of the hot path |

A file under `.hafness/` that is not named above is undocumented, and `verify.sh` fails.

## Load on demand only

`rules/*.md` — only the ones the current contract's file scope implicates.

## Definition of done

1. `verify.sh` exits 0 and prints `HAFNESS_VERIFY: PASS`.
2. The run is in `log/` (written by `verify.sh --log`) and its id is in the feature's Evidence cell.
3. The rubric score meets the threshold.
4. A receipt exists in `log/receipts/`.

Any one missing means not done. A missing verdict line is a FAIL, never a pass.

## Before the session ends

Run `/hafness-handoff`. State must not be older than the last run.
