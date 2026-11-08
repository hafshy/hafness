# Hafness — map

Routing only. Explanations belong in `rules/` or a folder's README. ≤ 60 lines, linted.

## Start every session

1. Read `state/current.md` — in flight, next action, open risks, board link.
2. Read `tasks.md` and the spec in flight. A task left `doing`, not escalated: session was cut off.
3. Print the next action. Do not open a source file before this.

## The loop

    init → [research] → describe → [review] → plan → implement → [feedback] ↺

| Step | Command | Writes |
|---|---|---|
| init | `/hafness-init` | `profile.sh`, the history and board hooks, the first board |
| research | `/hafness-research <topic>` — optional; describe and plan research when needed | `research/<slug>.md` |
| describe | `/hafness-describe <what you want>` | `specs/F-nnn.md`, status `draft` |
| review | the operator, optional — "reviewed" | spec status `reviewed` |
| plan | `/hafness-plan F-nnn` | `plans/F-nnn.md` + rows in `tasks.md` |
| implement | `/hafness-implement F-nnn` | code, a run block in `log/`, tasks `done` |
| feedback | `/hafness-feedback F-nnn <text>` — optional | `feedback.md`, revision tasks + plan update |
| board | `/hafness-board` — only when the operator asks; the loop never publishes | the link in `current.md` |

Every step ends the same way: rewrite `state/current.md`, then `bash .hafness/board.sh`.

## Files

`FILES.md` names every file in `.hafness/` and its job. Read it only when you need it.

## Replies

Short. At most 5 lines plus the closing card a skill gives: what changed, what is next.
Never restate a file you wrote; the operator reads it on the board. Paste `verify.sh`
output only on FAIL; on PASS, the verdict and run id are enough.

## Definition of done

A spec is `done` when `verify.sh --log` prints `HAFNESS_VERIFY: PASS` with no check skipped
as slow (a `--slow` run, if `profile.sh` names any) and every one of its tasks carries that
run id. Feedback is optional; it reopens the spec with new tasks.
A missing verdict line is a FAIL, never a pass.

Specs, plans and tasks are drafts for a human to read: after writing one, stop and say
what it will cause. The operator may edit any of them; the edit wins.
