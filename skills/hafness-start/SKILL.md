---
name: hafness-start
description: Resume a Hafness project cold — read state, today's log, the open contract; print the next action before touching source.
---

# /hafness-start

If `.hafness/` does not exist, offer `/hafness-init` and stop.

## 1. Read, in this order, nothing else

1. `.hafness/state/current.md`
2. `.hafness/log/<today>.md` — if absent, the newest dated file in `log/`
3. `.hafness/scope/FEATURES.md` — the table only
4. Every file in `.hafness/scope/contracts/` whose feature is `contracted`, `in_progress`
   or `escalated` in the table

Do not open a source file yet.

## 2. Print the resume point

Four lines, no preamble:

- **In flight** — feature id and title, or "nothing"
- **Next action** — verbatim from `current.md`
- **Open risks** — from `current.md`, or "none"
- **Contract** — path and whether `- [x] Operator approved` is ticked

## 3. Gate on sign-off

No contract, or the box is unticked → stop. Offer `/hafness-contract <id>` for the first
`backlog` feature whose deps are all `done` or `archived`, or ask the operator to tick the box.
Do not start work.

Ticked → set the row's status to `in_progress` if it is `contracted`, load only the
`rules/*.md` files the contract's in-scope paths implicate, and begin with the next action.
When you reach a stopping point, `/hafness-handoff`.
