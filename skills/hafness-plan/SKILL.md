---
name: hafness-plan
description: Turn a goal into FEATURES.md rows with ids, deps and done-criteria, then stop for review. Usage - /hafness-plan <goal>
disable-model-invocation: true
---

# /hafness-plan $ARGUMENTS

Read `.hafness/scope/FEATURES.md` and `.hafness/state/current.md`. Note the highest
existing `F-nnn`; continue from there. If the only row is the shipped example
(`F-001 | Example — delete this once real work starts`), replace it.

## Decompose

Split the goal into features an agent can finish in one contract each. For every one:

- **ID** next `F-nnn`
- **Title** one line, imperative
- **Deps** ids it cannot start without, or `—`
- **Status** `backlog`; `blocked` if any dep is not `done` or `archived`. Derived, never chosen.
- **Contract** `—` · **Evidence** `—`

Then a detail section per feature, appended in table order:

    ## F-nnn — <title>

    **Done when**

    - [ ] three to six statements, each checkable by `verify.sh` or the rubric
    - [ ] written now, before the work — a criterion invented afterwards is a description of whatever happened

## Write, lint, stop

Append the rows and sections. Run `bash .hafness/verify.sh`; the format lint must pass —
fix the file, never the lint. Then stop:

> Plan written. Review the table and the done-criteria. Nothing is contracted yet.
> `/hafness-contract <id>` binds one feature.
