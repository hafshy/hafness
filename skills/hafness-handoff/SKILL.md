---
name: hafness-handoff
description: Close a Hafness session — run the gate with a logged run block, write the receipt, mark the feature, archive, rewrite state.
disable-model-invocation: true
---

# /hafness-handoff

Every step writes to `.hafness/`. Append-only files are appended, never edited.

## 1. Find the run's coordinates

- **Feature** — the row that is `in_progress` (or `contracted` if work started without
  `/hafness-start`). None → feature is `—`.
- **Attempt** — count of run blocks for that feature across `log/*.md`, plus one.
- **Budget** — `Attempts:` from the contract. No contract → 1.

## 2. Run the gate, logged

    bash .hafness/verify.sh --log <feature> <attempt> <budget>

It appends the block header and the verdict line to `log/<today>.md` itself and prints
`HAFNESS_RUN: r-nnnn`. Show the full output verbatim. Do not summarise, do not re-run to
get a better result.

## 3. Finish the block

Append to the same block, one `**Key** value` line each:

- **Touched** files changed this run (`git diff --stat --name-only` if git, else list)
- **Failed check** — on FAIL only: the check label and the failing line, verbatim
- **Read** contract id and any `rules/*.md` loaded
- **Rubric** — on PASS only: `nn/25` and the five scores. Self-scored; say so.
- **Receipt** `log/receipts/r-nnnn.md`
- **Next** one line: what the next session does first

## 4. Write the receipt

`log/receipts/r-nnnn.md` with the five headings from `log/receipts/README.md`: Changed,
Evidence, Decided, Not done, Cost. Pass or fail alike.

## 5. Move the feature

- **PASS and rubric ≥ threshold** (`rubric.md`: no dimension below 3, total ≥ 20):
  status `verified` → `done`, Evidence cell `r-nnnn`. Then archive, in this order:
  write `archive/<id>.md` (the contract's full text plus the run ids), set Evidence to
  `r-nnnn · archive/<id>.md`, set status `archived`, *then* delete
  `scope/contracts/<id>.md`. Unblock rows whose deps are now all `archived`: `blocked` → `backlog`.
- **PASS, rubric below threshold** — treat as FAIL; the block's **Failed check** is `rubric`.
- **FAIL, attempts < budget** — status `in_progress`. Next action is the failing check.
- **ESCALATED** — status `escalated`. Add **Escalation** to the block: what was tried,
  what the evidence said, what the operator must decide. Do not widen scope to get a pass.

## 6. Decisions and state

Any decision made this session that is not in `state/decisions.md` — append it in the
file's format. Then rewrite `state/current.md`: Updated (today), In flight, Next action,
Open risks, Last run (`r-nnnn · verdict`).

## 7. Refuse to end early

Re-read `state/current.md`. If **Last run** does not name the run id you just logged, the
handoff is not done — fix it. Then run `bash .hafness/verify.sh` once more: the block you
wrote must pass the grammar lint. Only then say the session is closed.
