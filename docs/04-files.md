# Hafness — file reference

Every file in v1, what it is for, who writes it, and whether you need to review it before
anything runs.

`verify.sh` enforces this list: any file under `.hafness/` that is not named in
`HAFNESS.md` fails the format lint.

## Legend

**Written by** — who creates or changes it.
**Review** — ● must be read before anything executes · ○ read when you are curious · — never
**Format** — and what enforces it.

---

## Repo root

| File | Job | Written by | Review |
|---|---|---|---|
| `README.md` | Entry point: the loop, the board, a walkthrough | you | ○ |
| `docs/01-design.md`, `docs/02-flows.md` | The v0 design and flows, kept for the reasoning | you | ○ |
| `docs/03-comparison.md` | Hafness vs harness-creator vs edts-harness | you | ○ |
| `docs/04-files.md` | This file | you | ○ |
| `docs/05-guide.md`, `docs/05-guide.html` | The field guide for users, in markdown and as an interactive page | you | ○ |
| `docs/v0-ledger/` | The v0 backlog, archived contracts, receipt and rubric | — | — |
| `.claude-plugin/plugin.json` | Plugin manifest: name, version, description | you | — |
| `skills/<name>/SKILL.md` | `hafness` (routing) and `hafness-{init,research,describe,plan,implement,feedback}` | you | ○ |
| `skills/hafness-init/template/` | The scaffold `init` copies into a project | you | — |
| `test/selfhost.sh` | The template passes its own gate; hook, board, lint and fence work | you | — |

---

## The pointers and the hook

| File | Job | Written by | Review | Format |
|---|---|---|---|---|
| `CLAUDE.md` | Three lines: read `.hafness/HAFNESS.md` first | `/hafness-init` | ● once | markdown |
| `AGENTS.md` | Identical content, for non-Claude agents | `/hafness-init` | ● once | markdown |
| `.claude/settings.json` | Gains one `UserPromptSubmit` hook running `.hafness/history.sh` | `/hafness-init` | ● once | JSON, merged, never overwritten |

The pointers are never a second set of instructions. The hook entry is the only thing
Hafness writes outside `.hafness/` besides them.

---

## `.hafness/` — the harness

### Read every session

| File | Job | Written by | Review | Format |
|---|---|---|---|---|
| `HAFNESS.md` | The map: the loop, the file index, definition of done | `/hafness-init` | ● | markdown · ≤ 60 lines, linted |
| `state/current.md` | In flight, next action, open risks, last run, board link | every command, at the end | ● | markdown |
| `state/decisions.md` | Append-only decision log. Supersedes chat | the agent, on each decision | ○ | markdown, fixed entry shape |

`state/current.md` is the resume point. The test of the whole harness is whether a cold
session can read it and continue without you re-explaining anything.

### The work

| File | Job | Written by | Review | Format |
|---|---|---|---|---|
| `research/<slug>.md` | One sourced note per topic: findings, options, recommendation | `/hafness-research`, or describe/plan when needed | ○ | markdown, shape in `research/README.md` |
| `specs/F-nnn.md` | What and why for one feature: requirements, how you'll know, assumptions | `/hafness-describe` | ● Assumptions first | markdown · first line and `Status:` linted |
| `plans/F-nnn.md` | How: approach, files, not touching, risks, verification, budget | `/hafness-plan` | ○ | markdown, shape in `plans/README.md` |
| `tasks.md` | Every task: spec, status, Scope, run id | `/hafness-plan`, `/hafness-feedback`, `/hafness-implement` | ○ | markdown table · columns, statuses, run ids linted |
| `feedback.md` | Your words, quoted; how the agent read them; what they became | `/hafness-feedback` | ○ | markdown · header grammar linted |

Spec statuses: `draft → reviewed → planned → building → done`. Review is optional.
`done` means the gate passed with every task in it; the lint refuses `done` while a task is open.
Feedback is optional and reopens a spec.

A task's **Scope** is enforced. While any task is `doing`, the scope fence in `verify.sh`
fails on a changed file that falls outside the Scope of every `doing` task. Paths ending in
`/` match the whole folder; others are shell globs.

### The board and the history

| File | Job | Written by | Review | Format |
|---|---|---|---|---|
| `board.sh` | Embeds every markdown file into one HTML page | shipped, rarely edited | — | bash |
| `board.html` | The board: Features, Tasks, Research, Feedback, History, Runs | `board.sh` only | open it | generated, never edited |
| `history.sh` | The prompt hook: append, tag, redraw | shipped | — | bash, never prints, always exits 0 |
| `history.md` | Every prompt, tagged with the command name when it is a Hafness command | `history.sh` | ○ | markdown · header grammar linted |

The markdown is the source of truth; the board is a view. Because every document is
embedded, the page opens from disk with no server and publishes as an Artifact unchanged.
Markdown rendering loads from cdnjs; offline, documents show as plain text.

`history.md` contains everything typed. `/hafness-init` gitignores it and `board.html`
(which embeds it); delete those lines to commit them. If a secret is pasted, delete the
entry and rotate the secret.

### The gate

| File | Job | Written by | Review | Format |
|---|---|---|---|---|
| `profile.sh` | Shell variables holding exactly what will run | `/hafness-init` | ●●● | shell · `HAF_STACK` required, linted |
| `verify.sh` | Format lint, scope fence, then the project checks. One exit code | shipped, rarely edited | ● on change | bash |

`profile.sh` is the highest-stakes file in the harness. A wrong command here makes every
later result meaningless: a green run that tested nothing is worse than a red one.
`verify.sh` sources it and runs nothing else. Empty means skipped, not failed; a profile
with nothing runnable refuses to pass at all.

### Policy and rules

| File | Job | Written by | Review | Format |
|---|---|---|---|---|
| `policy.md` | Stop-and-ask list, never-do list | you | ● once, then on change | markdown |
| `rules/README.md` | What belongs in this directory | shipped | — | markdown |
| `rules/<domain>.md` | Domain rules: `swift.md`, `git.md`, `testing.md` | you | ○ | markdown |

Rules load **on demand only**, for the paths the current plan touches.

### Ledger

| File | Job | Written by | Review | Format |
|---|---|---|---|---|
| `log/<date>.md` | One block per gate run | header by `verify.sh --log`, rest by `/hafness-implement` | ○ | markdown · fixed header grammar, linted |
| `log/journal.md` | Lessons, and where each was promoted | you or the agent | ○ | markdown, fixed entry shape |

The run-log header is fixed so the file stays greppable while staying readable:

    ## r-0004 · 09:42 · F-002 · attempt 2/3 · FAIL · 4m12s

---

## What the gate actually checks

`harness_lint()` and `scope_fence()` in `verify.sh` run before any project check.

| Check | Fails when |
|---|---|
| Map size | `HAFNESS.md` exceeds 60 lines |
| Map completeness | a file under `.hafness/` is not named in `HAFNESS.md` |
| Task table | the header drifted, a row has the wrong column count, a cell is blank, or a status is unknown |
| Task evidence | a task is `done` and its run id is not a PASS block in `log/` |
| Spec done | a spec is `done` while one of its tasks is not |
| Specs | a spec's first line is not `# F-nnn — <title>`, or its `Status:` is missing or unknown |
| Feedback, history | a `##` header does not match its grammar |
| Profile | `profile.sh` has no `HAF_STACK`, or an unterminated command string |
| Run log | a `##` header does not match the grammar |
| Scope fence | a file changed since the last commit lies outside the Scope of every `doing` task; `verify.sh`, `profile.sh` and `policy.md` count unless a task names them exactly |

The fence compares against the last commit, so `/hafness-implement` asks for a clean tree
before it starts.

---

## Files that are deliberately absent

| Not here | Why |
|---|---|
| contracts | Replaced by task rows whose Scope the fence enforces; you approve intent, not paths |
| `rubric.md`, receipts | A self-scored rubric was never evidence. The run block is |
| `state/<name>.md` | Per-person sharding avoids merge conflicts you will never have |
| any `.json` in `.hafness/` | Every case has a format that is both readable and trivially parseable |
| `.gitkeep` | Replaced by `README.md` files that explain their own directory |
