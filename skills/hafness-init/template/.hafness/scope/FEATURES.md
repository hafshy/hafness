# Features

The backlog. Written by `/hafness-plan`, reviewed by you, then bound one at a time into a
contract. Nothing here is executed until the contract for it is signed off.

**Status** `backlog` · `blocked` · `contracted` · `in_progress` · `escalated` · `verified` · `done` · `archived` · `dropped`

**Rules**

- No transition from `in_progress` straight to `done`. `verified` is the only door, and an
  evidence id is the key.
- `blocked` is derived from Deps, never set by hand.
- `escalated` means the budget was spent and the run stopped honestly. Not an error.
- `done` or `archived` with an empty Evidence cell is a defect. `verify.sh` fails on it.

**Format contract** — the table header and column order are fixed. `verify.sh` lints this
file and fails on drift. Use `—` for empty, never a blank cell.

| ID | Title | Deps | Status | Contract | Evidence |
|----|-------|------|--------|----------|----------|
| F-001 | Example — delete this once real work starts | — | backlog | — | — |

---

## F-001 — Example

**Done when**

- [ ] Written before the work, not after
- [ ] Checkable by `verify.sh` or the rubric

**Notes**

One section per feature, in table order. The table is for scanning; this is where the
done-criteria get room to be specific enough to argue with.
