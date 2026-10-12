# Tasks

Every task, for every spec. Written by `/hafness-plan` and `/hafness-feedback`, moved by
`/hafness-implement`. The board's Tasks view is this table.

**Status** `todo` · `doing` · `done` · `blocked` · `dropped`

**Rules**

- `done` needs a run id: the `log/` block whose gate passed with this task in it.
- **Scope** is the fence. While a task is `doing`, `verify.sh` fails if a changed file falls
  outside the Scope of every `doing` task. Paths ending in `/` match the whole folder.
- Use `—` for empty, never a blank cell. The header and column order are fixed.

| ID | Spec | Task | Status | Scope | Run |
|----|------|------|--------|-------|-----|
