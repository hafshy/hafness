---
name: hafness
description: Working in a repo that has a .hafness/ directory. Routes to the harness map and prints the resume point before any other file is read.
---

If `.hafness/HAFNESS.md` does not exist, say so and offer `/hafness-init`. Stop.

Otherwise read it and follow it. It is the only routing file; do not read source files
before it tells you to. Never restate it — it is loaded by reading it, not by summarising.

At the start of a session, after the reads `HAFNESS.md` asks for, print the resume point in
four lines, no preamble:

- **In flight** — spec id and title, or "nothing"
- **Next action** — verbatim from `state/current.md`
- **Open risks** — from `current.md`, or "none"
- **Board** — the published URL from `current.md`, else `.hafness/board.html`
