---
name: hafness
description: Working in a repo that has a .hafness/ directory. Routes to the harness map and prints the resume point before any other file is read.
---

If `.hafness/HAFNESS.md` does not exist, say so and offer `/hafness-init`. Stop.

Otherwise read it and follow it. It is the only routing file; do not read source files
before it tells you to. Never restate it — it is loaded by reading it, not by summarising.

At the start of a session, after the reads `HAFNESS.md` asks for, check whether the last
session stopped halfway. `state/current.md` is only rewritten when a command finishes, so
it can be out of date:

- **Interrupted** — a task in `tasks.md` is `doing`, and its spec's newest run block in
  `log/` is not `ESCALATED`. A finished `/hafness-implement` moves its tasks to `done`;
  only an escalation leaves them `doing` on purpose, waiting for the operator.
- **Stale** — the newest run block in `log/` is not the **Last run** in `current.md`.

If either holds, print it first, naming the tasks or the run, and replace the next action
with `/hafness-implement <spec>` to finish and gate them (or, for a stale-only state, read
that run block and act on its **Next** line). Fix `current.md` to match before anything else.

Then print the resume point in four lines, no preamble:

- **In flight** — spec id and title, or "nothing"
- **Next action** — verbatim from `state/current.md`, or the resume action above
- **Open risks** — from `current.md`, or "none"
- **Board** — the published URL from `current.md`, else `.hafness/board.html`
