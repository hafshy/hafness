# Hafness — file reference

Every file, what it is for, who writes it, who reads it, and whether you need to review it
before anything runs.

`verify.sh` enforces this list: any file under `.hafness/` that is not named in
`HAFNESS.md` fails the format lint. The documentation cannot drift from what is on disk,
in either direction — adding an undocumented file fails, and deleting a row from the map
for a file that still exists fails too.

## Legend

**Written by** — who creates or changes it.
**Review** — ● must be read before anything executes · ○ read when you are curious · — never
**Format** — and what enforces it.

---

## Repo root

| File | Job | Written by | Review |
|---|---|---|---|
| `README.md` | Entry point: what Hafness is, status, links to these docs | you | ○ |
| `docs/01-design.md` | Six subsystems, layout, feature catalog, build order | you | ○ |
| `docs/02-flows.md` | Six flowcharts of how the harness runs | you | ○ |
| `docs/03-comparison.md` | Hafness vs harness-creator vs edts-harness | you | ○ |
| `docs/04-files.md` | This file | you | ○ |
| `.claude-plugin/plugin.json` | Plugin manifest — name, version, description | you | — |
| `skills/<name>/SKILL.md` | The six skills: `hafness` (routing) and `hafness-{init,start,plan,contract,handoff}` | you | ○ |
| `skills/hafness-init/template/` | The scaffold `init` copies into a project | you | — |
| `test/selfhost.sh` | The template passes its own gate; skills and manifest are well-formed | you | — |

---

## The two pointers

| File | Job | Written by | Review | Format |
|---|---|---|---|---|
| `CLAUDE.md` | Three lines: read `.hafness/HAFNESS.md` first | `/hafness-init` | ● once | markdown |
| `AGENTS.md` | Identical content, for non-Claude agents | `/hafness-init` | ● once | markdown |

Both are pointers, never a second set of instructions. Two sources of truth for how an agent
starts is the failure edts-harness avoids by making `CLAUDE.md` a one-line pointer, and it is
worth copying exactly.

---

## `.hafness/` — the harness

### Read every session

| File | Job | Written by | Review | Format |
|---|---|---|---|---|
| `HAFNESS.md` | The map. Routing, the file index, definition of done | `/hafness-init` | ● | markdown · ≤ 60 lines, linted |
| `state/current.md` | In flight, next action, open risks | `/hafness-handoff` | ● | markdown |
| `state/decisions.md` | Append-only decision log. Supersedes chat | the agent, on each decision | ○ | markdown, fixed entry shape |

`state/current.md` is the resume point. The test of the whole harness is whether a cold
session can read it and continue without you re-explaining anything.

### The gate

| File | Job | Written by | Review | Format |
|---|---|---|---|---|
| `profile.sh` | Shell variables holding exactly what will run | `/hafness-init` | ●●● | shell · `HAF_STACK` required, linted |
| `verify.sh` | Format lint, then the project checks. One exit code | shipped, rarely edited | ● on change | bash |
| `rubric.md` | What counts as good, scored 1–5 across five dimensions | you | ○ | markdown table |

`profile.sh` is the highest-stakes file in the harness. A wrong command here makes every
later result meaningless — a green run that tested nothing is worse than a red one. It is
the single source of truth: `verify.sh` sources it and runs nothing else, so there is no
second list to keep in sync. Empty means skipped, not failed; a profile with nothing
runnable refuses to pass at all.

The `# found:` comment on each line records where detection saw it. That comment is how you
audit a detection you did not watch happen.

### Scope

| File | Job | Written by | Review | Format |
|---|---|---|---|---|
| `scope/FEATURES.md` | The backlog: id, title, deps, status, contract, evidence | `/hafness-plan` | ● | markdown · fixed column order, linted |
| `scope/contracts/<id>.md` | One bounded task: scope, non-scope, criteria, budget | `/hafness-contract` | ● | markdown |

Two review stops, not one. The plan is read as a whole before any feature is picked up; the
contract is signed off before that feature is worked.

`scope/contracts/EXAMPLE.md` ships as a template. Delete it once real work starts.

### Policy

| File | Job | Written by | Review | Format |
|---|---|---|---|---|
| `policy.md` | Stop-and-ask list, never-do list | you | ● once, then on change | markdown |

The only file the agent may never edit. When phase three adds hooks, the enforcement
patterns become a separate file — `policy.md` keeps the *reason*, the pattern file carries
the *boundary*. Two files holding different things, not the same thing twice.

### Rules

| File | Job | Written by | Review | Format |
|---|---|---|---|---|
| `rules/README.md` | What belongs in this directory | shipped | — | markdown |
| `rules/<domain>.md` | Domain rules — `swift.md`, `git.md`, `testing.md` | you, or `/hafness-journal` | ○ | markdown |

Loaded **on demand only**, scoped to the files the current contract touches. Loading all of
them turns the map back into a manual. A rule that keeps getting ignored is evidence it
should have been a check in `verify.sh` — that is the promotion path.

### Ledger

| File | Job | Written by | Review | Format |
|---|---|---|---|---|
| `log/<date>.md` | One block per run | header by `verify.sh --log`, rest by the agent | ○ | markdown · fixed header grammar, linted |
| `log/journal.md` | Lessons, and where each was promoted | `/hafness-journal` | ○ | markdown, fixed entry shape |
| `log/receipts/README.md` | What a receipt contains | shipped | — | markdown |
| `log/receipts/r-<id>.md` | How one run produced its output | the agent, at the gate | ○ | markdown |
| `archive/README.md` | The ordered archiving procedure | shipped | — | markdown |
| `archive/<feature>.md` | Closed contract detail, out of the hot path | `/hafness-handoff` | — | markdown |

The run-log header is fixed so the file stays greppable while staying readable:

    ## r-0291 · 09:42 · F-014 · attempt 2/3 · FAIL · 4m12s

Structure the *line*, not the file. That is what lets the ledger be prose you can read and
data you can query, without storing it twice.

`log/2026-09-15.md` ships as a worked example of two runs — a failure and the retry that
passed. Delete it once real runs start.

---

## What the lint actually checks

All of it lives in `harness_lint()` in `verify.sh`, and it runs before any project check.

| Check | Fails when |
|---|---|
| Map size | `HAFNESS.md` exceeds 60 lines |
| Map completeness | a file under `.hafness/` is not named in `HAFNESS.md` |
| Backlog header | `FEATURES.md` column order drifted |
| Backlog rows | a row has the wrong number of columns |
| Backlog blanks | a cell is empty rather than `—` |
| Evidence | a feature is `done` or `archived` with no evidence id |
| Profile | `profile.sh` has no `HAF_STACK`, or an unterminated command string |
| Run log | a `##` header does not match the grammar |

Each of these is a rule that also exists in prose, in the file it governs. That is the
harness's one principle applied to itself: the guide explains the reason, the check enforces
the boundary.

---

## Files that are deliberately absent

| Not here | Why |
|---|---|
| `state/<name>.md` | Per-person sharding avoids merge conflicts you will never have |
| `CONSTITUTION.md` | `policy.md` plus `rules/` cover it without a file that is always in context |
| any `.json` | Every case has a format that is both readable and trivially parseable |
| `.gitkeep` | Replaced by `README.md` files that explain their own directory |
| a config file | Detected profile plus the files above. If something needs configuring, it needs deleting |
