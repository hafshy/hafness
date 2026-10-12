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
| T-001 | F-009 | Write the v1 map and the spec, plan, research, task, feedback and history formats | done | `skills/hafness-init/template/`, `.hafness/` | r-0002 |
| T-002 | F-009 | Extend verify.sh with task, spec, feedback and history lint and the scope fence | done | `skills/hafness-init/template/.hafness/verify.sh`, `.hafness/verify.sh` | r-0002 |
| T-003 | F-009 | Write board.sh and history.sh | done | `skills/hafness-init/template/.hafness/`, `.hafness/` | r-0002 |
| T-004 | F-009 | Replace start, contract, handoff with research, describe, implement, feedback; rewrite init, plan, router | done | `skills/` | r-0002 |
| T-005 | F-009 | Cover hook, board, lint and fence in the self-host test | done | `test/selfhost.sh` | r-0002 |
| T-006 | F-009 | Migrate this repo's .hafness and move the v0 ledger to docs | done | `.hafness/`, `docs/v0-ledger/` | r-0002 |
| T-007 | F-009 | Rewrite README and HANDOFF for v1; mark v0 design docs | done | `README.md`, `HANDOFF.md`, `docs/`, `.claude-plugin/plugin.json` | r-0002 |
