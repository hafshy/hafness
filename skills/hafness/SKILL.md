---
name: hafness
description: Working in a repo that has a .hafness/ directory. Routes to the harness map before any other file is read.
---

If `.hafness/HAFNESS.md` exists, read it and follow it. It is the only routing file; do not
read source files before it tells you to.

If it does not exist, say so and offer `/hafness-init`.

Never restate what `HAFNESS.md` says — it is loaded into context by reading it, not by you
summarising it.
