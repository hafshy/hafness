# Hafness

A single-operator harness for AI coding agents, with a board.

The model is the reasoning engine. Hafness is the environment around it: what it can see,
what it can touch, what survives between sessions, what counts as evidence, and when a run
must stop. Everything it writes (specs, plans, tasks, feedback, gate runs, every prompt you
type) is markdown, and all of it is drawn on one HTML board you can open or share.

Seven skills and one `.hafness/` directory. Stack-agnostic. Built for one person.

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
/hafness-init                       # once: copy .hafness/, detect the stack, install the history hook, draw the board
/hafness-research <topic>           # optional: describe and plan also research on their own when needed
/hafness-describe <what you want>   # your idea → a spec (what and why) on the board
/hafness-plan F-001                 # spec → plan + scoped tasks on the board
/hafness-implement F-001            # build task by task, run the gate; a pass is done
/hafness-feedback F-001 <text>      # optional: turn what you saw into new tasks
```

The loop: **init → [research] → describe → [review] → plan → implement → [feedback] ↺**

You are asked one thing, and it is something you know better than the agent: **what you
want** (describe, and an optional review of the spec). When the result is not what you
meant, say so with feedback. You are never asked to approve file paths or budgets.
Those are the agent's job, and the gate holds it to them.

`done` is not the agent's opinion. A spec is `done` when `bash .hafness/verify.sh` passes
with every task inside its scope, and the lint refuses `done` while any of its tasks is not.

## The board

`.hafness/board.html` is redrawn after every command and every prompt. It is one
self-contained file: open it from disk, or (when the session has the Artifact tool) it is
published to a private claude.ai link that updates in place.

| Tab | Shows |
|---|---|
| Features | one card per spec: its stage, task progress, open feedback, and the spec and plan in full |
| Tasks | a kanban of every task (todo, doing, done, blocked) with its scope and run id |
| Research | the research notes |
| Feedback | your feedback, quoted, and what each one became |
| History | every prompt you typed, tagged when it ran a Hafness command |
| Runs | every gate run with its verdict |

The markdown is the source of truth. Edit a spec or a task row by hand and the next redraw
shows it. Never edit `board.html`.

## Walkthrough: a habit tracker

Say you are starting a habit-tracker iOS app in an empty Xcode project.

### Install and initialise

```bash
cd ~/code/habits
npx skills add hafshy/hafness -a claude-code -y
claude
```

```
/hafness-init
```

Claude copies `.hafness/` in, finds `Habits.xcodeproj`, and writes `.hafness/profile.sh`:

```sh
HAF_STACK="xcode"                                   # found: Habits.xcodeproj
HAF_BUILD="xcodebuild -scheme Habits -destination 'generic/platform=iOS Simulator' build"   # found: xcodebuild -list
HAF_TEST=""                                         # no test target in xcodebuild -list
HAF_LINT=""                                         # no .swiftlint.yml
```

It adds the history hook to `.claude/settings.json`, runs the gate once, draws the board,
and **stops**. Read `profile.sh`: it is the list of commands that decide pass or fail.
Empty is honest. It found no test target, so it wrote none.

### Describe

```
/hafness-describe habit tracker: create habits, check them off daily, see a streak per habit
```

If something would change what gets built, Claude asks (at most five questions, one at a
time, each with a default). Then it writes `.hafness/specs/F-001.md`:

```markdown
# F-001 — Habits with daily check-off and streaks

Status: draft

## Requirements
- R1 When I add a habit, the app shall list it on the home screen.
- R2 When I check a habit off, the app shall count today as done for it.
- R3 When I open a habit, the app shall show its current streak in days.

## How you'll know
- Add "Read", check it off, reopen the app: still checked today.

## Assumptions
- Data stays on the device; no account, no sync.
```

The spec is on the board, in the Features tab, with its stage at **Described**. Check the
Assumptions, edit anything, and say "reviewed" if you want it marked. Review is optional.

### Plan

```
/hafness-plan F-001
```

Now Claude reads the code. It writes `.hafness/plans/F-001.md` (approach, files, what it
won't touch, risks, how each "How you'll know" item gets shown) and adds tasks:

```
| T-001 | F-001 | Habit model and local store     | todo | `Habits/Models/`              | — |
| T-002 | F-001 | Habit list screen, add and delete | todo | `Habits/Views/HabitList/`    | — |
| T-003 | F-001 | Daily check-off                  | todo | `Habits/Models/`, `Habits/Views/HabitList/` | — |
| T-004 | F-001 | Streak calculation and display   | todo | `Habits/Models/Streak.swift`, `Habits/Views/HabitDetail/` | — |
```

The board's Tasks tab shows them as a kanban. Each task's Scope is a fence: while a task is
`doing`, the gate fails on any changed file outside it.

### Implement

```
/hafness-implement F-001
```

Claude moves each task to `doing` (you can watch it move on the board), builds inside its
scope, then runs the logged gate:

```
--- harness format     ok
--- scope fence        ok
--- build              ok
HAFNESS_VERIFY: PASS
HAFNESS_RUN: r-0001
```

The tasks go to `done` with `r-0001` in their Run cell, the spec goes to **Done**, and
Claude stops with a card telling you how to try it.

If the gate **fails**, Claude fixes the failing check and runs it again, up to the plan's
budget of three attempts. On the third failure it stops as `ESCALATED`, writes what it tried
and what the evidence said, and waits for you. It never widens the scope to get a pass. If
it needs a file outside every task's scope, it asks first.

### Feedback

You run the app and try it.

```
/hafness-feedback F-001 streak resets if I check off after midnight
```

Claude records your words in `feedback.md`, writes how it read them, updates the spec if
the behavior changed, adds tasks that revise what was built, and updates the plan to match.
`/hafness-implement F-001` picks it up with a fresh attempt budget. If what you ask for is
really a new feature, Claude asks first: reopen F-001, or start a new spec. No feedback
needed when it is right. Next idea: `/hafness-describe …`.

### Resume cold

New terminal, no chat history. The routing skill reads `state/current.md` and prints:

> **In flight** — nothing
> **Next action** — /hafness-describe the next feature; F-001 done
> **Open risks** — no test target yet; the gate is build-only
> **Board** — https://claude.ai/artifact/…

Nothing had to be re-explained. That is the test of the whole harness.

If the last session stopped halfway (tasks still `doing`, no gate run), the resume point
says so first and the next action becomes finishing them with `/hafness-implement`.

### When something goes wrong twice

Write the lesson in `.hafness/log/journal.md`, then put the boundary where it belongs:

- a judgement call → `rules/swift.md` (loaded only when a plan touches Swift)
- mechanically checkable → a line in `profile.sh`'s `HAF_EXTRA`, e.g.
  `"no-ui-in-models|! grep -rl 'import SwiftUI' Habits/Models"`
- must never happen → `policy.md`

A rule that keeps getting ignored is evidence it should have been a check.

## What `.hafness/` holds

| Path | Job |
|---|---|
| `HAFNESS.md` | the map: the loop and a file index, ≤ 60 lines, linted |
| `profile.sh` | exactly what will run, sourced by `verify.sh`; review it |
| `verify.sh` | the gate: format lint, scope fence, then the project checks; `--log` appends a run block |
| `policy.md` | stop-and-ask list and never list |
| `board.sh` → `board.html` | draws the board from the markdown |
| `history.sh` → `history.md` | prompt hook; every prompt, tagged when it is a Hafness command |
| `research/`, `specs/`, `plans/` | one file per topic, per feature, per plan; each folder's README is its format |
| `tasks.md` | every task: status, scope, run id |
| `feedback.md` | your feedback, quoted, and what it became |
| `state/current.md` | in flight · next action · open risks · board link |
| `state/decisions.md` | decision log; supersedes chat |
| `log/` | append-only gate runs, plus the journal |

Everything is markdown or shell, meant to be read before it runs. Full reference:
[docs/04-files.md](docs/04-files.md).

## The one principle

Encode every important rule twice: once as prose the agent understands (the reason), once
as a mechanical check it cannot bypass (the boundary). A prose rule is guidance. A script
is a boundary. In v1 that is how scope works: the plan says which files, and the fence in
`verify.sh` makes it true.

## This repo

Hafness harnesses itself: the specs, tasks, run log and board for building it live in this
repo's own `.hafness/`. Open `.hafness/board.html`, or start with
[.hafness/state/current.md](.hafness/state/current.md). Orientation is in
[HANDOFF.md](HANDOFF.md). `bash .hafness/verify.sh` is the gate here too.

```
.claude-plugin/plugin.json        plugin manifest
skills/hafness/                   routing skill
skills/hafness-{init,research,describe,plan,implement,feedback}/
skills/hafness-init/template/     what init copies into a project
test/selfhost.sh                  the template passes its own gate; hook, board, fence work
docs/                             design, flows, comparison, file reference
docs/v0-ledger/                   the v0 backlog, contracts and receipts, kept for the record
```

| Doc | What it covers |
|---|---|
| [docs/01-design.md](docs/01-design.md) | The v0 design: six subsystems, layout, feature catalog |
| [docs/02-flows.md](docs/02-flows.md) | v0 flowcharts: session loop, gate logic, rule promotion |
| [docs/03-comparison.md](docs/03-comparison.md) | Hafness vs harness-creator vs edts-harness |
| [docs/04-files.md](docs/04-files.md) | Every v1 file: purpose, who writes it, what to review |

## Sources

- rari, *Harness Engineering: How to Build AI Agents That Don't Fall Apart* — https://x.com/0xwhrrari/status/2093685107534000560
- walkinglabs/learn-harness-engineering (`harness-creator` skill) — https://github.com/walkinglabs/learn-harness-engineering
- edtsmobile/edts-harness — https://github.com/edtsmobile/edts-harness
- The loop survey behind v1: GitHub Spec Kit, Kiro, OpenSpec, Superpowers, GSD, BMAD Method,
  Compound Engineering, Taskmaster, Anthropic's *Effective harnesses for long-running agents*, Ralph
