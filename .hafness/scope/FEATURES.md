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
| F-001 | Plugin scaffold — manifest, six skill stubs, template moved, npx-installable | — | archived | — | r-0001 · archive/F-001.md |
| F-002 | `/hafness-init` — detect stack, write profile.sh, scaffold .hafness/ | F-001 | archived | — | r-0001 · archive/F-002.md |
| F-003 | `/hafness-start` — resume cold from files alone | F-002 | archived | — | r-0001 · archive/F-003.md |
| F-004 | `/hafness-plan` — goal to FEATURES.md rows | F-002 | archived | — | r-0001 · archive/F-004.md |
| F-005 | `/hafness-contract` — feature to bounded contract, stop for sign-off | F-004 | archived | — | r-0001 · archive/F-005.md |
| F-006 | Run-log writer — folded into F-007 | — | dropped | — | — |
| F-007 | `/hafness-handoff` — run gate, append run block + receipt, write current.md, archive | F-002 | archived | — | r-0001 · archive/F-007.md |
| F-008 | Self-host check — Hafness's own repo passes its own gate | F-007 | archived | — | r-0001 · archive/F-008.md |

---

## F-001 — Plugin scaffold

**Done when**

- [ ] A valid plugin manifest exists and the plugin loads in Claude Code
- [ ] The `hafness` skill is present and its SKILL.md routes to `.hafness/HAFNESS.md`
- [ ] Five commands exist as stubs that print what they will do and exit: `init`, `start`, `plan`, `contract`, `handoff`
- [ ] `template/` ships as plugin assets so `init` has something to copy
- [ ] `verify.sh` still exits 0 in this repo

**Notes**

Stubs, not implementations. The point is to settle the plugin's shape and command naming
before any of them do work — a rename after four commands exist is four renames.

## F-002 — `/hafness-init`

**Done when**

- [ ] Detects stack from Package.swift, xcodeproj, package.json, go.mod, pyproject, Cargo.toml
- [ ] Writes `profile.sh` with only commands it actually found, each with a `# found:` comment
- [ ] Leaves a variable empty rather than guessing
- [ ] Copies `.hafness/` and writes `CLAUDE.md` + `AGENTS.md` pointers
- [ ] Refuses to run in a repo that already has a `.hafness/`
- [ ] Stops for review before the first run, per the draft rule in HAFNESS.md

## F-003 — `/hafness-start`

**Done when**

- [ ] Reads `state/current.md`, today's log, and the open contract — in that order
- [ ] Prints the next action before opening any source file
- [ ] Refuses to proceed when no contract is signed off
- [ ] Proven by resuming a half-finished feature in a cold session with no chat history

## F-004 — `/hafness-plan`

**Done when**

- [ ] Turns a goal into rows with ids, deps, and a done-criterion each
- [ ] Writes the per-feature detail sections in table order
- [ ] Derives `blocked` from deps rather than setting it by hand
- [ ] Stops for review of the whole plan before anything is contracted
- [ ] Output passes the FEATURES.md format lint

## F-005 — `/hafness-contract`

**Done when**

- [ ] Expands one feature into in-scope paths, out-of-scope paths, evidence, budget
- [ ] Refuses a feature whose deps are not `done`
- [ ] Writes the contract path back into the feature's Contract cell
- [ ] Stops for sign-off and does not proceed on its own

## F-006 — Run-log writer

Dropped 2026-09-15 — folded into F-007. See `state/decisions.md`.

## F-007 — `/hafness-handoff`

**Done when**

- [ ] Runs `verify.sh`, captures exit code, duration, files touched, failing check verbatim
- [ ] Appends one block per run under the fixed header grammar
- [ ] Never edits an existing block
- [ ] Output passes the run-log grammar lint
- [ ] Rewrites `state/current.md` with in-flight, next action, open risks
- [ ] Writes a receipt to `log/receipts/` for the run, pass or fail
- [ ] Archives closed contracts in the documented order: write, link, then delete inline
- [ ] Refuses to end a session with state older than the last run

## F-008 — Self-host check

**Done when**

- [ ] This repo's own `verify.sh` exits 0 with real checks, not just the format lint
- [ ] A throwaway repo can be initialised, planned, contracted, and handed off end to end
- [ ] The phase-one gate is met: a cold session resumes a half-finished feature unaided
