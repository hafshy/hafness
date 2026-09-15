# Hafness — v0 design

Personal harness for AI coding agents. One operator. Form: Claude Code plugin (skill + commands + files).
Stack-agnostic, profile-detected. Status: design, unbuilt.

## Premise

When an agent forgets a decision, reaches for the wrong tool, or declares success without
running anything, the reflex is to edit the prompt, then swap the model, then widen the
context window. None of those touch the actual defect: the environment around the model is
underspecified.

> The environment was underspecified.
> — OpenAI, *Harness engineering: leveraging Codex in an agent-first world*, cited in rari's *Harness Engineering*

## Core principle

Encode every important rule twice:

1. As prose the agent understands — the reason.
2. As a mechanical check it cannot bypass — the boundary.

A prose rule is guidance. A script is a boundary. Everything below follows from that split.

## Second principle: every generated file is reviewable

Nothing this harness generates is written in a machine format. `FEATURES.md`, `profile.sh`,
the contracts, the run log, the receipts — all readable, all meant to be read before
anything executes. A generated file is a **draft until signed off**.

The cost is real: markdown drifts where JSON cannot. The answer is the first principle
applied to the harness itself — each readable file states its format contract in its own
header, and `verify.sh` lints that contract mechanically. Structure the *line*, not the
file. A run-log header of

    ## r-0291 · 09:42 · F-014 · attempt 2/3 · FAIL · 4m12s

reads as prose and parses with one regex. That is the whole trick.

## Seven jobs, six subsystems

The article names seven jobs a production harness has to do. Jobs 3 (tools) and 5 (sensors)
collapse into one subsystem for a single operator, because the verification layer is the
same file doing both. Nothing is left as "the agent will remember."

| # | Job | Subsystem | Artifact | Enforcement |
|---|---|---|---|---|
| 1 | Turn the request into a contract | **Contract** | `scope/contracts/<id>.md` | No contract file, no work |
| 2 | Give the agent a map | **Map** | `HAFNESS.md` + `rules/` | Root file <= 50 lines; audit fails bloat |
| 3 | Expose the right tools | **Sensors** | `verify.sh` | One script, one exit code |
| 4 | Externalize memory into durable state | **State** | `state/current.md`, `decisions.md` | Written before session end |
| 5 | Add sensors before autonomy | **Sensors** | `verify.sh` + `rubric.md` | No `done` without a recorded pass |
| 6 | Enforce permissions outside the model | **Policy** | `policy.md` | Stop-and-ask on the deny list |
| 7 | Record traces and recover locally | **Ledger** | `log/*.md`, `receipts/`, `journal.md` | Append-only; receipt per run |

## The six subsystems

### CTR — Contract

Turns a request into a bounded object before anything is touched. Names the goal, the files
in scope, the files explicitly out of scope, the done-criteria, and the attempt budget.
Without it an agent can finish a different job and still report success.

- Writes: `scope/contracts/<id>.md`
- Reads: `scope/FEATURES.md`
- Gate: contract exists and is signed off

### MAP — Map

A short root guide that says where to look, not what everything is. Detailed knowledge lives
next to the code it governs and loads only when the current contract needs it. A map
preserves context; a manual eats it.

- Writes: `HAFNESS.md`, `rules/*.md`
- Reads: repo tree, stack profile
- Gate: root file <= 50 lines

### SNS — Sensors

The environment produces evidence about the artifact; the agent does not get to grade
itself. Stack detection writes the real commands — `swift test`, `pnpm test`, `go vet`,
`ruff` — into one script with one exit code.

**Never invent a check.** Only list a check if the real command was found in the project.
A check that cannot run is worse than no check. (Borrowed from edts-harness.)

- Writes: `verify.sh`, `rubric.md`
- Emits: `HAFNESS_VERIFY: PASS` / `FAIL` plus captured output
- Gate: exit 0 required for `done`

### STA — State

Durable memory outside the context window. What is in flight, what the next action is, what
open risks exist, and every decision that would otherwise live only in a transcript. The
next session inherits the work, not a retelling of the chat.

- Writes: `state/current.md`, `state/decisions.md`
- Reads: ledger tail, contracts
- Gate: written before session end

### POL — Policy

Authorization lives outside the model. The agent may propose a force-push, a schema
migration, a release build, a message to someone; the harness decides whether it happens.
Never ask one probabilistic system to plan, approve, and execute the same side effect.

- Writes: `policy.md`
- Covers: git, network, releases, secrets, anything that sends
- Gate: stop-and-ask on the deny list

### LDG — Ledger

An append-only trail per run: what was attempted, what the sensors said, what changed, what
it cost. Plus a journal where a failure becomes a candidate rule. Without traces a failure
is a mystery; with them it is input for the next harness version.

Written as markdown with a fixed header grammar, so it reads like a work diary and still
greps like a log.

- Writes: `log/*.md`, `log/receipts/`, `log/journal.md`
- Mode: append-only, never edited
- Gate: receipt per run, pass or fail

## Repo layout

```
CLAUDE.md                  # 3 lines: "read .hafness/HAFNESS.md first"
AGENTS.md                  # same content, for non-Claude agents
.hafness/
├── HAFNESS.md             # the map — routing + file index, <= 60 lines
├── policy.md              # deny list, approval boundaries
├── rubric.md              # what "done" scores against
├── profile.sh             # what will actually run — sourced by verify.sh
├── verify.sh              # the gate — format lint, then project checks
├── rules/
│   ├── README.md          # what belongs here
│   └── swift.md           # loaded only when touching Swift
├── scope/
│   ├── FEATURES.md        # backlog table + done-criteria per feature
│   └── contracts/
│       └── F-014.md       # the bounded object for one task
├── state/
│   ├── current.md         # in flight · next action · open risks
│   └── decisions.md       # decision log, supersedes chat
├── log/
│   ├── 2026-09-14.md      # append-only trace, fixed header grammar
│   ├── journal.md         # lessons -> candidate rules
│   └── receipts/
│       ├── README.md      # what a receipt contains
│       └── r-0291.md      # change receipt for one run
└── archive/
    ├── README.md          # the ordered archiving procedure
    └── F-012.md           # closed contract detail
```

Every path above is named in `HAFNESS.md`, and `verify.sh` fails if a file under
`.hafness/` is not — so the map cannot drift from what is on disk, in either direction.
Full per-file reference in [04-files.md](04-files.md).

One file per job, one job per file. If you cannot say which subsystem a file belongs to, it
does not belong in `.hafness/`.

## The loop belongs to the harness

"Keep trying until it works" is not a control system. The agent decides *how* to repair the
gap; Hafness decides *whether another attempt is allowed*. The budget and escalation path
live in the contract, not in the agent's judgment.

See [02-flows.md](02-flows.md) for the diagrams.

1. **Load state** (STA) — read `state/current.md`, today's log tail, the open contract. Print the next action before reading any source file.
2. **Contract** (CTR) — if the task has no bounded contract, write one and stop for sign-off.
3. **Act** (MAP · POL) — load only the rules the contract's file scope implicates. Policy checks run before any side effect, not after.
4. **Sense** (SNS) — run `verify.sh`. It lints the harness's own file formats first, then runs the project checks. Capture stdout, stderr, exit code, duration verbatim. No summarising.
5. **Gate** (SNS) — exit 0 and rubric score above threshold, or it is not done. Non-zero returns to step 3 while attempts remain; budget spent escalates to the operator.
6. **Receipt + handoff** (LDG · STA) — write what changed, what the evidence was, what is still open. Append, never overwrite.

## Feature catalog

### v0 — close the loop

| Sub | Feature | Why |
|---|---|---|
| MAP | Stack detection → `profile.sh` | Sniff Package.swift / xcodeproj / package.json / go.mod / pyproject; write shell variables holding exactly what will run. `verify.sh` sources it, so there is no second list to keep in sync |
| CTR | `/hafness-plan` — goal to feature list | **Task generation.** Turns a loose goal into `FEATURES.md` rows with ids, dependency edges, and a done-criterion each. Stops for review before anything is contracted |
| CTR | `/hafness-contract` — bound one task | Expands one feature into in-scope paths, out-of-scope paths, acceptance evidence, attempt budget. Stops for sign-off |
| STA | `/hafness-start` — resume cold | Reads state, log tail, open contract; prints the next action |
| SNS | `verify.sh` as the only done-gate | One script, one exit code. Also lints the harness's own format contracts, so readable files cannot drift out of parseability |
| LDG | Append-only markdown run log | One block per run under a fixed header: run id, time, feature, attempt, verdict, duration. Reads as a diary, parses with one regex |
| STA | `/hafness-handoff` — close the session | Writes `current.md`, appends the receipt, archives finished contracts |

### v1 — make failure useful

| Sub | Feature | Why |
|---|---|---|
| LDG | Change receipts | Diff stat, the evidence that justified `done`, decisions taken, what was deliberately not done. Makes a model upgrade comparable and a regression attributable |
| SNS | Separate evaluator pass | A second agent reads contract + diff + rubric and scores the work — the builder approving its own output is the failure mode the rubric exists to prevent |
| CTR | Loop control: budget & escalation | Attempts, wall-clock, token budget declared in the contract. On exhaustion, write the escalation note and stop |
| LDG | `/hafness-journal` — failure to rule | After a bad run, draft the lesson and propose where it lives: `rules/`, the rubric, or a new check in `verify.sh` |
| MAP | Rule promotion | Turn a prose rule that keeps getting ignored into a mechanical check |
| POL | Explicit deny list | Force-push, secret files, release builds, anything that sends |
| ALL | `/hafness-audit` — score the six | Present / partial / missing per subsystem; report drift — bloated map, stale state, features marked done with no evidence id |
| MAP | Context budget | Declare per contract what may be loaded. Prevents the map becoming the manual it replaced |

### Later — earn the complexity

| Sub | Feature | Why |
|---|---|---|
| POL | Hooks as real enforcement | PreToolUse / PostToolUse hooks that block rather than advise. Where Hafness stops being documentation the agent can ignore |
| CTR | Worktree per contract | A bad run is thrown away rather than reverted. Separates the hands from the history |
| SNS | Visual sensors | Simulator or browser screenshots into the run record, so UI work has evidence instead of an assertion |
| LDG | Local trace viewer | One HTML file generated from the JSONL: runs, pass rate, time per contract, which rules keep breaking |
| LDG | Cross-project journal | Lessons from one repo become candidate rules in the next |
| SNS | Harness benchmark | A fixed task set replayed against two harness versions, so a change to Hafness itself has evidence |

## Deliberate omissions

Both reference harnesses carry machinery for teams. One person means that machinery is cost
with no return — and every file the agent reads is context it does not spend on the work.

| Cut | Why |
|---|---|
| Per-person state files | One `state/current.md`, not `state/<name>.md`. The sharding avoids merge conflicts that will never happen here |
| Review workflow | No PR templates, no reviewer assignment. The rubric and evaluator pass do the quality job |
| Human onboarding docs | The map is written for the agent; you already know the repo |
| Team dashboard | The trace viewer is a local file you open when curious, not a service that has to stay up |
| Multi-agent orchestration | One builder, one evaluator, at most. Swarms generate disagreement you then have to referee |
| Config surface | Detected profile plus six markdown files. If something needs configuring, it needs deleting |
| `migrate` mode | edts-harness needs it because it lands in repos with existing harnesses. Yours are greenfield |

## Build order

Each phase has a gate that must be true before the next one starts.

**Phase one — close the loop**
Stack detection, a `verify.sh` that actually runs, `FEATURES.md` + one contract, start /
handoff commands, markdown run log.
*Gate:* a cold session resumes a half-finished feature and finishes it without you
re-explaining anything.

**Phase two — make failure useful**
Change receipts, rubric + evaluator pass, attempt budget & escalation, journal → candidate
rule, audit command.
*Gate:* a failed run has produced a rule or check that would have caught it, at least three
times.

**Phase three — earn the complexity**
Hooks that block, worktree isolation, visual sensors, trace viewer, cross-project journal.
*Gate:* only build the piece a specific logged incident demanded. No phase-three work
without a receipt pointing at it.

## Readiness check

Run this against Hafness itself once phase one is built. Several `no` answers mean a better
model will not save you — it will only make the failures more expensive.

- [ ] Can a fresh session resume the work from files alone, with no chat history?
- [ ] Is there a bounded contract, or can the task quietly redefine itself mid-run?
- [ ] Does `done` depend on a command's exit code rather than the agent's opinion?
- [ ] Is there a budget and an escalation path, or does the loop run until you notice?
- [ ] Does anything irreversible stop and ask before it happens?
- [ ] Can you reconstruct last Tuesday's run from the ledger without guessing?
- [ ] Has a past failure become a check, or is it still only a sentence in a markdown file?
- [ ] Is the harness still smaller than the failure surface it controls?
