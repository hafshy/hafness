---
name: hafness-implement
description: Build a planned spec task by task inside each task's scope, run the logged gate; a pass makes it done. Usage - /hafness-implement F-nnn
disable-model-invocation: true
---

# /hafness-implement $ARGUMENTS

## Refuse when

- the spec has no `todo` or `doing` tasks in `tasks.md` — offer `/hafness-plan <id>`
- its status is `draft` or `reviewed` — it has no plan yet; offer `/hafness-plan <id>`

## 1. Clean baseline

The scope fence compares against the last commit. If `git status` shows changes outside
`.hafness/`, tell the operator and ask them to commit or stash first. Do not commit for
them without an explicit yes — `policy.md` applies.

Exception: an interrupted session. Tasks of this spec still `doing` mean the last session
stopped before its gate. Their uncommitted changes inside those tasks' Scope are that work —
keep them and resume. Changes outside every such Scope still need the operator's call.

## 2. Work, task by task

Spec `Status:` → `building`. First any task of this spec still `doing` (finish it), then
each `todo` task, in table order:

1. Set it `doing`, run `bash .hafness/board.sh` so the board shows what is in progress.
2. Do the work, inside the task's **Scope** only. Read the plan, not the whole repo.
3. Leave it `doing` — `done` needs a run id, and only the gate gives one.

Needing a file outside every Scope means the plan was wrong. Stop and ask. On a yes, add
the path to the task's Scope cell and append the decision to `state/decisions.md`. Never
work around the fence; never edit `verify.sh` or `profile.sh` to get a pass.

Anything on `policy.md`'s stop-and-ask list: stop and ask, every time.

Between gates, keep runs short. The gate is the full check; while you work:

- Run the narrowest thing that answers the question: one test (`-only-testing:Target/Class/test`,
  a single test file), or a build. Not the whole suite, not a UI journey.
- Simulator or UI-journey runs outside the gate: at most 3 per task. Still failing after the
  third → stop, say what you tried and what you saw, and ask the operator. Never loop on
  screenshots or retry the same run hoping it passes.
- Say before you start anything you expect to take more than 5 minutes.

## 3. Gate, logged

The gate counts attempts itself (this spec's runs since its last PASS, plus one, so a
revision from feedback starts a fresh budget) and reads the budget from the plan's
`Attempts:` — never read `log/` to count them. Run:

    bash .hafness/verify.sh --log <id>

On PASS, report only the last two lines; on FAIL, show the output verbatim (it is already
trimmed to the failing lines). It writes the block header and verdict to `log/<today>.md`
and prints `HAFNESS_RUN: r-nnnn · attempt n/budget · PASS|FAIL|ESCALATED`. Append to that
block, one `**Key** value` line each:
**Tasks** (the T-ids), **Touched** (`git diff --name-only HEAD`), **Failed check** (on FAIL:
label and failing line, verbatim), **Next** (one line).

- **PASS, slow checks skipped** (the output has `skipped — slow`) — the fast checks hold;
  now run the slow ones once: `bash .hafness/verify.sh --log <id> --slow`. That run is the
  one that counts, and its verdict is handled by these same rules.
- **PASS** (nothing skipped as slow) — every `doing` task of this spec → `done` with the run
  id in its Run cell. Spec → `done`. Any `planned` entry in `feedback.md` whose tasks are now
  all `done` → `done`. Then move this spec's rows from `tasks.md` to the end of
  `tasks-done.md` (create it with the same header line and `|---|` row if absent), so
  `tasks.md` holds only open work.
- **FAIL, attempt < budget** — fix the failing check and gate again. Tasks stay `doing`.
- **ESCALATED** — stop. Add **Escalation** to the block: what was tried, what the evidence
  said, what the operator must decide. Do not widen scope to get a pass.

## 4. Finish

1. `state/current.md`: **In flight**, **Next action** (`/hafness-describe the next feature`,
   or the failing check), **Open risks**, **Last run** `r-nnnn · verdict`.
2. Any decision made this session → `state/decisions.md`.
3. `bash .hafness/board.sh` to redraw the local board. Never publish it here: that is
   `/hafness-board`, only when the operator asks.
4. On PASS, stop with the try-it card, built from the spec's "How you'll know":

> **<id> · <title> · done**
> **What changed** one line, in the operator's words
> **How to see it** the steps from "How you'll know"
> **Stayed out** the plan's Not touching list — the fence held
> **Guesses** anything unverified (e.g. no test target, so the gate only builds)
>
> Want something changed? `/hafness-feedback <id> <what you saw>`. Otherwise, next:
> `/hafness-describe …`.
