# Hafness — map

Routing only. Explanations belong in `rules/` or a folder's README. ≤ 60 lines, linted.

## Start every session

1. Read `state/current.md` — in flight, next action, open risks, board link.
2. Read `tasks.md` and the spec in flight. A task left `doing`, not escalated: session was cut off.
3. Print the next action. Do not open a source file before this.

## The loop

    init → [research] → describe → [review] → plan → implement → feedback ↺

| Step | Command | Writes |
|---|---|---|
| init | `/hafness-init` | `profile.sh`, the history hook, the first board |
| research | `/hafness-research <topic>` — optional; describe and plan research when needed | `research/<slug>.md` |
| describe | `/hafness-describe <what you want>` | `specs/F-nnn.md`, status `draft` |
| review | the operator, optional — "reviewed" | spec status `reviewed` |
| plan | `/hafness-plan F-nnn` | `plans/F-nnn.md` + rows in `tasks.md` |
| implement | `/hafness-implement F-nnn` | code, a run block in `log/`, tasks `done` |
| feedback | `/hafness-feedback F-nnn <text>` | `feedback.md`, revision tasks + plan update, or acceptance |

Every step ends the same way: rewrite `state/current.md`, run `bash .hafness/board.sh`,
then publish `board.html` if this session has an Artifact tool (URL kept in `current.md`).

## Every file in this harness

| Path | Job |
|---|---|
| `HAFNESS.md` | this map — routing, nothing else |
| `policy.md` | what needs approval, what is forbidden |
| `profile.sh` | what will actually run; sourced by `verify.sh` |
| `verify.sh` | the gate — format lint, scope fence, then the project checks |
| `board.sh` | renders `board.html` from the markdown below |
| `board.html` | the board — generated, never edited by hand |
| `history.sh` | prompt hook — appends every prompt to `history.md` |
| `history.md` | every prompt, tagged when it is a Hafness command |
| `research/` | optional research notes, one per topic |
| `specs/` | one spec per feature — what and why |
| `plans/` | one plan per spec — how, which files |
| `tasks.md` | every task: status, scope, run id |
| `feedback.md` | the operator's feedback on built work |
| `rules/` | domain rules, loaded on demand only |
| `state/current.md` | in flight, next action, open risks, board link |
| `state/decisions.md` | decision log — supersedes chat |
| `log/` | one dated file per day, one block per gate run |
| `log/journal.md` | lessons, promoted into rules or checks |

A file under `.hafness/` that is not named above is undocumented, and `verify.sh` fails.

## Definition of done

A spec is `built` when `verify.sh --log` prints `HAFNESS_VERIFY: PASS` and every one of its
tasks carries that run id. It is `done` only when the operator accepts it through feedback.
A missing verdict line is a FAIL, never a pass.

Specs, plans and tasks are drafts for a human to read: after writing one, stop and say
what it will cause. The operator may edit any of them; the edit wins.
