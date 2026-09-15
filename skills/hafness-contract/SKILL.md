---
name: hafness-contract
description: Bind one feature into a contract with scope, non-scope, evidence and budget, then stop for sign-off. Usage - /hafness-contract F-nnn
disable-model-invocation: true
---

# /hafness-contract $ARGUMENTS

## Refuse when

- the id is not in `.hafness/scope/FEATURES.md`
- its status is not `backlog` or `escalated`
- any dep is not `done` or `archived` — name the dep and stop

## Write `scope/contracts/<id>.md`

Follow the shape of `scope/contracts/EXAMPLE.md` exactly. Fill it from the repo, not from
imagination:

- **Goal** one sentence — what is true after that is not true now
- **In scope** real paths. Look at the tree; list files or directories that will change.
- **Out of scope** real paths that are adjacent and tempting. This half prevents drift.
- **Done criteria** the feature's `Done when` list, plus `verify.sh exits 0`
- **Acceptance evidence** what the ledger must contain: a `PASS` run block, and anything
  specific (a screenshot path, a command's output)
- **Budget** attempts 3, wall clock 45 min, on exhaustion stop — unless the operator said otherwise
- **Sign-off** `- [ ] Operator approved`, unticked

## Update the row

Status → `contracted`, Contract cell → `scope/contracts/<id>.md`. Run `bash .hafness/verify.sh`.

## Stop

> Contract drafted at `<path>`. Read it. Tick `- [x] Operator approved` or say "approved"
> and I will tick it. No work starts before that.

Never tick the box yourself without an explicit yes in this session.
