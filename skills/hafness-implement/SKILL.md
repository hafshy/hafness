---
name: hafness-implement
description: Build a planned spec task by task inside each task's scope, run the logged gate, and leave it built for the operator to try. Usage - /hafness-implement F-nnn
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

## 2. Work, task by task

Spec `Status:` → `building`. For each `todo` task of this spec, in table order:

1. Set it `doing`, run `bash .hafness/board.sh` so the board shows what is in progress.
2. Do the work, inside the task's **Scope** only. Read the plan, not the whole repo.
3. Leave it `doing` — `done` needs a run id, and only the gate gives one.

Needing a file outside every Scope means the plan was wrong. Stop and ask. On a yes, add
the path to the task's Scope cell and append the decision to `state/decisions.md`. Never
work around the fence; never edit `verify.sh` or `profile.sh` to get a pass.

Anything on `policy.md`'s stop-and-ask list: stop and ask, every time.

## 3. Gate, logged

Attempt = number of run blocks for this spec across `log/*.md`, plus one. Budget = the
plan's `Attempts:`. Run:

    bash .hafness/verify.sh --log <id> <attempt> <budget>

Show the output verbatim. It writes the block header and verdict to `log/<today>.md` and
prints `HAFNESS_RUN: r-nnnn`. Append to that block, one `**Key** value` line each:
**Tasks** (the T-ids), **Touched** (`git diff --name-only HEAD`), **Failed check** (on FAIL:
label and failing line, verbatim), **Next** (one line).

- **PASS** — every `doing` task of this spec → `done` with the run id in its Run cell.
  Spec → `built`. Any `planned` entry in `feedback.md` whose tasks are now all `done` → `done`.
- **FAIL, attempt < budget** — fix the failing check and gate again. Tasks stay `doing`.
- **ESCALATED** — stop. Add **Escalation** to the block: what was tried, what the evidence
  said, what the operator must decide. Do not widen scope to get a pass.

## 4. Finish

1. `state/current.md`: **In flight**, **Next action** (`try <id>, then /hafness-feedback <id> …`,
   or the failing check), **Open risks**, **Last run** `r-nnnn · verdict`.
2. Any decision made this session → `state/decisions.md`.
3. `bash .hafness/board.sh`; if this session has an Artifact tool, publish `board.html`
   (with the URL under `## Board` if one is there, else new — and record the URL).
4. On PASS, stop with the try-it card, built from the spec's "How you'll know":

> **<id> · <title> · built, waiting for you**
> **What changed** one line, in the operator's words
> **How to see it** the steps from "How you'll know"
> **Stayed out** the plan's Not touching list — the fence held
> **Guesses** anything unverified (e.g. no test target, so the gate only builds)
>
> Try it, then `/hafness-feedback <id> <what you saw>` — or "accept" if it is right.
