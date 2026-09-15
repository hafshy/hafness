# Hafness

A single-operator harness for AI coding agents.

The model is the reasoning engine. Hafness is the environment around it: what it can see,
what it can touch, what survives between sessions, what counts as evidence, and when a run
must stop.

Six skills and one `.hafness/` directory. Stack-agnostic. Built for one person.

## Install

One command, into the project you are working on:

```bash
npx skills add hafshy/hafness -a claude-code -y
```

Or for every project on this machine:

```bash
npx skills add hafshy/hafness -a claude-code -g -y
```

(Also loads as a Claude Code plugin: `claude --plugin-dir /path/to/hafness`.)

## Use

```
/hafness-init                 # once per project: copy .hafness/, detect the stack, write profile.sh
/hafness-plan <goal>          # goal → FEATURES.md rows with deps and done-criteria; stops for review
/hafness-contract F-003       # one feature → a bounded contract; stops for sign-off
/hafness-start                # every session: read state, print the next action, then work
/hafness-handoff              # end of session: gate, run block, receipt, state, archive
```

The loop is: **init once → plan → contract → (start → work → handoff)\* → next contract.**

Three places it stops and waits for you, on purpose:

1. After `init` — review `.hafness/profile.sh`. It is the list of commands that will decide
   pass or fail. A wrong one makes every later result meaningless.
2. After `plan` — read the backlog before anything is contracted.
3. After `contract` — tick `- [x] Operator approved`. No contract, no work.

`done` is not the agent's opinion. It is `bash .hafness/verify.sh` exiting 0, a run block
in `.hafness/log/`, a receipt, and a rubric score. Missing any one means not done.

## Walkthrough — building a product with it

Say you are starting a habit-tracker iOS app in an empty Xcode project. This is the whole
lifecycle, what you type and where it stops.

### Day 0 — install and initialise

```bash
cd ~/code/habits
npx skills add hafshy/hafness -a claude-code -y
claude
```

```
/hafness-init
```

Claude copies `.hafness/`, `CLAUDE.md` and `AGENTS.md` in, looks at the tree, finds
`Habits.xcodeproj`, and writes `.hafness/profile.sh`:

```sh
HAF_STACK="xcode"                                   # found: Habits.xcodeproj
HAF_BUILD="xcodebuild -scheme Habits -destination 'generic/platform=iOS Simulator' build"   # found: xcodebuild -list
HAF_TEST=""                                         # no test target in xcodebuild -list
HAF_LINT=""                                         # no .swiftlint.yml
```

Then it runs `bash .hafness/verify.sh` once and **stops**. Your job: read `profile.sh`.
Empty is honest — it found no test target, so it wrote none. Add one when a test target
exists; do not let it be invented.

### Day 0 — plan

```
/hafness-plan habit tracker: create habits, check them off daily, see a streak per habit
```

Claude writes rows into `.hafness/scope/FEATURES.md`:

```
| F-001 | Habit model + local store           | —     | backlog | — | — |
| F-002 | Habit list screen, add and delete   | F-001 | blocked | — | — |
| F-003 | Daily check-off                     | F-002 | blocked | — | — |
| F-004 | Streak calculation + display        | F-003 | blocked | — | — |
```

and a `Done when` list under each, then **stops**. Your job: read the plan. Wrong split,
missing feature, criterion that is not checkable — edit the file or say so. Nothing is
contracted yet.

### Day 1 — contract one feature

```
/hafness-contract F-001
```

Claude writes `.hafness/scope/contracts/F-001.md`: goal, in-scope paths (`Habits/Models/`,
`HabitsTests/`), out-of-scope paths (`Habits/Views/` — tempting, not this feature),
done-criteria, evidence required, a budget of 3 attempts, and an unticked sign-off box.
Then it **stops**. Your job: read it, tick `- [x] Operator approved` (or say "approved").

### Day 1 — work

```
/hafness-start
```

Claude reads `state/current.md`, today's log, the contract — and prints four lines:
in flight, next action, open risks, contract status. Only then does it open a source file.
It sets F-001 to `in_progress` and works within the contract's paths. If it wants to touch
`Habits/Views/`, the contract says no; if it wants to `git push --force`, `policy.md` says
stop and ask.

When it reaches a stopping point — done, or you are out of time:

```
/hafness-handoff
```

Claude runs `bash .hafness/verify.sh --log F-001 1 3`. The gate builds the project and
writes the run header to `.hafness/log/2026-09-16.md` itself:

```
## r-0001 · 14:02 · F-001 · attempt 1/3 · PASS · 1m48s
```

Claude finishes the block (files touched, rubric score, receipt path), writes
`log/receipts/r-0001.md`, moves F-001 through `verified` → `done` → `archived` with
`r-0001` in its Evidence cell, unblocks F-002, rewrites `state/current.md`, and confirms
the block passes the lint. Session over.

If the gate had **failed**: the block says `FAIL`, names the failing check verbatim, F-001
stays `in_progress`, and `current.md`'s next action is that check. Attempt 2 of 3.
If attempt 3 fails: `ESCALATED`. Claude writes what it tried and what the evidence said,
and stops. It does not widen the scope to get a pass. You decide — revise the contract,
raise the budget, or drop it.

### Day 2 — resume cold

New terminal, no chat history:

```
/hafness-start
```

> **In flight** — nothing
> **Next action** — contract F-002; F-001 archived under r-0001
> **Open risks** — no test target yet; the gate is build-only
> **Contract** — none signed off

Nothing had to be re-explained. That is the test of the whole harness.

```
/hafness-contract F-002
```

…and the loop continues, one contract at a time, until F-004 is archived.

### When something goes wrong

A run failed in a way that will happen again — say Claude keeps putting view logic in the
model. Write it down in `.hafness/log/journal.md`, then put the boundary where it belongs:

- a judgement call → `rules/swift.md` (loaded only when a contract touches Swift)
- a quality bar → a row in `rubric.md`
- mechanically checkable → a line in `profile.sh`'s `HAF_EXTRA`, e.g.
  `"no-ui-in-models|! grep -rl 'import SwiftUI' Habits/Models"`
- must never happen → `policy.md`

A rule that keeps getting ignored is evidence it should have been a check. Promote it.

### What `.hafness/` holds

| Path | Job |
|---|---|
| `HAFNESS.md` | the map — routing and a file index, ≤ 60 lines, linted |
| `profile.sh` | exactly what will run, sourced by `verify.sh`; review it |
| `verify.sh` | the gate: format lint, then the project checks; `--log` appends a run block |
| `policy.md` | stop-and-ask list and never list — the agent may not edit it |
| `rubric.md` | what counts as good, scored 1–5 across five dimensions |
| `rules/` | domain rules, loaded only when a contract touches those files |
| `scope/FEATURES.md` | the backlog |
| `scope/contracts/` | one bounded task each |
| `state/current.md` | in flight · next action · open risks — the resume point |
| `state/decisions.md` | decision log; supersedes chat |
| `log/` | append-only run log, fixed header grammar, plus receipts and journal |
| `archive/` | closed contracts, out of the hot path |

Everything is markdown or shell — meant to be read before it runs. Full reference:
[docs/04-files.md](docs/04-files.md).

## The one principle

Encode every important rule twice: once as prose the agent understands (the reason), once
as a mechanical check it cannot bypass (the boundary). A prose rule is guidance. A script
is a boundary.

## This repo

Hafness harnesses itself: the backlog, contracts and run log for building it live in this
repo's own `.hafness/`. Start a session with [.hafness/state/current.md](.hafness/state/current.md);
orientation is in [HANDOFF.md](HANDOFF.md). `bash .hafness/verify.sh` is the gate here too.

```
.claude-plugin/plugin.json        plugin manifest
skills/hafness/                   routing skill
skills/hafness-{init,start,plan,contract,handoff}/
skills/hafness-init/template/     what init copies into a project
test/selfhost.sh                  the template passes its own gate
docs/                             design, flows, comparison, file reference
```

| Doc | What it covers |
|---|---|
| [docs/01-design.md](docs/01-design.md) | The six subsystems, layout, feature catalog, build order |
| [docs/02-flows.md](docs/02-flows.md) | Flowcharts — session loop, task generation, gate logic, rule promotion |
| [docs/03-comparison.md](docs/03-comparison.md) | Hafness vs harness-creator vs edts-harness |
| [docs/04-files.md](docs/04-files.md) | Every file: purpose, who writes it, what to review before a run |

## Sources

- rari, *Harness Engineering: How to Build AI Agents That Don't Fall Apart* — https://x.com/0xwhrrari/status/2093685107534000560
- walkinglabs/learn-harness-engineering (`harness-creator` skill) — https://github.com/walkinglabs/learn-harness-engineering
- edtsmobile/edts-harness — https://github.com/edtsmobile/edts-harness
