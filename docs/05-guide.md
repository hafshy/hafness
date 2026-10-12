# Hafness Field Guide

**You say what you want. The gate says when it's done.**

Hafness is a harness for AI coding agents, built for one person. It gives the agent a fixed
way of working: write down what you asked for, plan which files it will touch, build only
inside those files, and prove the result with checks it cannot switch off. Everything it
writes is plain markdown, and all of it appears on one board you can open in a browser.

The interactive version of this guide, with a working board preview and a file explorer, is
[05-guide.html](05-guide.html). Every example here follows one illustrative project: a
habit-tracker iOS app built from an empty Xcode project.

---

## The loop

Seven steps, three of them optional. Each step is one command you type in Claude Code.

    init → [research] → describe → [review] → plan → implement → [feedback] ↺

Square brackets mark optional steps. Feedback goes back to implement.

| # | Step | You type | Who acts | Writes |
|---|---|---|---|---|
| 1 | Init | `/hafness-init` | the agent | `.hafness/`, `profile.sh`, the hook, `.gitignore` lines |
| 2 | Research · optional | `/hafness-research <topic>` | the agent | `research/<slug>.md` |
| 3 | Describe | `/hafness-describe <what you want>` | starts with you | `specs/F-001.md`, status `draft` |
| 4 | Review · optional | `reviewed` | you | spec status `reviewed` |
| 5 | Plan | `/hafness-plan F-001` | the agent | `plans/F-001.md`, rows in `tasks.md` |
| 6 | Implement | `/hafness-implement F-001` | the agent, held by the gate | your code, a run block, tasks and spec `done` |
| 7 | Feedback · optional | `/hafness-feedback F-001 <what you saw>` | starts with you | `feedback.md`, new tasks, spec `planned` |

### 1. Init — once per project

```
/hafness-init
```

- Copies the `.hafness/` folder into your project.
- Detects your stack and writes `profile.sh`, using only commands it actually found on your machine.
- Installs a hook that logs every prompt to `history.md`, and keeps that log out of git.
- Runs the gate once and draws the first board.

**Then it stops.** Read `profile.sh` before anything runs. It's the list of commands that
decide pass or fail. An empty line is honest: it found no test target, so it wrote none.

```sh
HAF_STACK="xcode"        # found: Habits.xcodeproj
HAF_BUILD="xcodebuild -scheme Habits \
  -destination 'generic/platform=iOS Simulator' build"
                         # found: xcodebuild -list
HAF_TEST=""              # no test target in xcodebuild -list
HAF_LINT=""              # no .swiftlint.yml
```

### 2. Research — optional, before you commit to anything

```
/hafness-research <topic>
```

- Looks at how others solve it, what the platform already provides, and what your project already has.
- Every finding names its source. Anything without a source is labelled as an assumption.
- Describe and plan also do this on their own when a request would otherwise rest on a guess.

**Then it stops.** You get a one-line recommendation and a note on the board.

```markdown
# When does a habit's day end?

## Findings
- Most streak apps count by the device's local calendar day, not 24-hour windows. (source: app docs)
- Calendar.current.isDateInToday handles DST. (source: Apple Foundation docs)

## Recommendation
Count by local calendar day; store check-offs as dates.
```

### 3. Describe — each new feature

```
/hafness-describe habit tracker: create habits, check them off daily, see a streak per habit
```

- Asks questions only if an answer would change what gets built: at most five, one at a
  time, each with a suggested default.
- Writes a spec in your language: requirements, how you'll know it works, what's out of
  scope, and every assumption it made.
- Never names files or frameworks unless you did. That's the plan's job.

**Then it stops.** Check the Assumptions first. Edit anything, or tell it what to change.

```markdown
# F-001 — Habits with daily check-off and streaks

Status: draft

## Requirements
- R1 When I add a habit, the app shall list it on the home screen.
- R2 When I check a habit off, the app shall count today as done.
- R3 When I open a habit, the app shall show its streak in days.

## How you'll know
- Add "Read", check it off, reopen the app: still checked today.

## Assumptions
- Data stays on the device; no account, no sync.
```

### 4. Review — optional, any time before planning

- You read the spec on the board, Assumptions first.
- Edit the markdown directly if you like. Your edit wins.
- Say "reviewed" and the status changes. Planning works with or without it.

You're checking that it understood you, not how it will build.

### 5. Plan — after describing

```
/hafness-plan F-001
```

- Reads your code now, for the first time.
- Writes the approach, the real files that will change, the tempting files it won't
  touch, the risks, and how each "How you'll know" item will be shown.
- Splits the work into small tasks. Each task's **Scope** is a fence: the gate fails on
  any change outside it.

**Then it stops.** Edit anything you disagree with. Otherwise, implement.

```
| ID    | Spec  | Task                              | Status | Scope                     | Run |
| T-001 | F-001 | Habit model and local store       | todo   | Habits/Models/            | —   |
| T-002 | F-001 | Habit list screen, add and delete | todo   | Habits/Views/HabitList/   | —   |
| T-003 | F-001 | Daily check-off                   | todo   | Habits/Models/, …         | —   |
| T-004 | F-001 | Streak calculation and display    | todo   | Habits/Views/HabitDetail/ | —   |
```

### 6. Implement — after planning

```
/hafness-implement F-001
```

- Asks for a clean git tree first, so the fence has a fair baseline.
- Moves each task to `doing` (you can watch it on the board) and works inside its Scope only.
- Runs the logged gate. PASS makes the tasks and the spec `done`. FAIL means fix and retry.
  The third failure escalates to you.
- Needs a file outside every Scope? It stops and asks. It never widens the fence itself.

**Then it stops.** A card tells you what changed, how to see it, what stayed untouched,
and anything it couldn't verify. Try it.

```
--- harness format     ok
--- scope fence        ok
--- build              ok
--- test               skipped — not found in this project
HAFNESS_VERIFY: PASS
HAFNESS_RUN: r-0002
```

### 7. Feedback — optional, only when it isn't what you meant

```
/hafness-feedback F-001 streak resets if I check off after midnight
```

- Records your words exactly, then how it read them.
- If the behaviour changes, it updates the spec first. The spec stays the source of truth.
- Adds tasks that revise what was built, updates the plan, and reopens the spec. Then
  implement again, with a fresh budget of three attempts.
- Sounds like a new feature instead? It asks: reopen this spec, or start a new one.

If it's right, do nothing: it's already done. Next idea: `/hafness-describe …`

```markdown
## FB-001 · 2026-10-08 · F-001 · planned

> streak resets if I check off after midnight

**Read as** a check-off just after midnight counted toward the next day and broke the
streak. Count by local calendar day.

**Tasks** T-005
```

---

## Who decides what

You judge intent. The agent owns the details. The gate holds it to them.

| You decide | The agent handles | The gate enforces |
|---|---|---|
| What you want built, in your own words | Research, when a request would otherwise rest on a guess | Every harness file keeps its format |
| Whether the spec's assumptions are right (review is optional) | Writing the spec, the plan and the tasks | Changes stay inside the files the plan named |
| What the gate runs: you read `profile.sh` once, after setup | Choosing file paths, and fencing each task to them | Your project's own build, test and lint pass |
| Anything risky: force-pushes, migrations, new dependencies, releases, anything that sends a message | Writing the code, task by task | Three failed attempts stop the agent and hand the problem to you |
| Whether to give feedback once it's done | Running the gate, fixing what fails, keeping the resume point and the board current | A task is `done` only with a passing run behind it |

You are never asked to approve file paths or budgets. Those are the agent's job, and a
script checks them. When a check passes, the work is done. Feedback is there for when the
result isn't what you meant.

---

## The board

One page that shows everything in flight. The board is redrawn after every command and
every prompt from the markdown files in `.hafness/`. It's a single self-contained HTML
file: open `.hafness/board.html` from disk, or follow the private claude.ai link the agent
publishes.

What it looks like for the habit tracker, midway through its second feature (example data):

```
Hafness board · xcode                         ┌ Next action ─────────────────────────────┐
habits                                        │ /hafness-implement F-002. Attempt 2 of 3: │
Last gate [r-0004 FAIL] · In flight: F-002    │ the build failed in NotificationScheduler │
                                              └───────────────────────────────────────────┘
┌Research┐┌Describe┐┌Review──────┐┌Plan───────┐┌Implement───┐┌Feedback─────┐
│   1    ││   3    ││   1        ││   1       ││   2        ││   0         │
│ notes  ││ specs  ││ for review ││ tasks todo││ in progress││ open        │
└────────┘└────────┘└────────────┘└───────────┘└────────────┘└─────────────┘
 Features 3 │ Tasks 8 │ Research 1 │ Feedback 1 │ History 6 │ Runs 4
─────────────────────────────────────────────────────────────────────────────
 F-001 Habits with daily check-off and streaks              [done]
   Described ▬ Reviewed ▬ Planned ▬ Building ▬ Done          5/5 tasks · last run r-0003 PASS
 F-002 Daily reminder at a chosen time                      [building]
   Described ▬ Reviewed ▬ Planned ▬ Building ▭ Done          0/3 tasks · last run r-0004 FAIL
 F-003 Weekly summary screen                                [draft]
```

1. **Status line.** The last gate verdict and the feature being worked on.
2. **Next action.** The single thing to do next, copied from `state/current.md`.
3. **The loop strip.** A count for each step. It turns amber while work is in progress or
   feedback is open.
4. **Tabs.**

| Tab | Shows |
|---|---|
| Features | one card per spec: its stage, task progress, last run, and the spec and plan in full |
| Tasks | a kanban of every task (todo, doing, done, blocked) with its Scope and run id |
| Research | the research notes |
| Feedback | your feedback, quoted, and what each one became |
| History | every prompt you typed, tagged when it ran a Hafness command |
| Runs | every gate run with its attempt and verdict |

The markdown is the source of truth. Edit a spec or a task row by hand and the next redraw
shows it. Never edit `board.html`: the next redraw overwrites it.

---

## The gate

One script decides pass or fail. `.hafness/verify.sh` runs three groups of checks in order
and prints one line the agent cannot reword: `HAFNESS_VERIFY: PASS` or `FAIL`. If that line
is missing, the run counts as a fail.

| Order | Group | Checks |
|---|---|---|
| 1 | **Harness format** — the paperwork is in order | The map stays under 60 lines and names every file. Task rows, spec status lines, feedback and run-log headers match their formats. A `done` task cites a run that passed. A `done` spec has no open tasks. |
| 2 | **Scope fence** — nothing changed outside the plan | Every changed file must sit inside the Scope of a task in progress. The gate's own files (`verify.sh`, `profile.sh`, `policy.md`) count too, unless a task names them. |
| 3 | **Your project** — it builds, and the tests pass | Build, test, lint and typecheck, exactly as written in `profile.sh`, plus any extra checks you added there. A profile with nothing runnable refuses to pass. |

Three ways a run ends:

| Verdict | What happens |
|---|---|
| **PASS** — done | Each task in progress becomes `done` and carries the run id. The spec becomes `done`. The agent stops with a card telling you how to try it. |
| **FAIL** — fix and retry | The agent fixes the failing check and runs the gate again. It never widens the scope or edits the gate to get a pass. The gate counts the attempts itself. |
| **ESCALATED** — your call | The third failure stops the agent. It writes what it tried and what the evidence said, then waits for you. |

### Reading a run-log header

    ## r-0004 · 10:12 · F-002 · attempt 1/3 · FAIL · 2m44s

| Part | Meaning |
|---|---|
| `r-0004` | The run id. The gate numbers runs itself, so ids never collide or get reused. A task marked done must cite one of these, and it must be a PASS. |
| `10:12` | When the run started, local time. Each day's runs go in `log/<date>.md`, oldest first. |
| `F-002` | The spec this run was for. |
| `attempt 1/3` | The gate counts this itself: this spec's runs since its last PASS, plus one. The budget comes from the plan. The agent can't reset it by passing a different number. |
| `FAIL` | The verdict: PASS, FAIL, or ESCALATED once a failure uses up the budget. |
| `2m44s` | How long the checks took. |

### The scope fence, by example

Two tasks of F-002 are in progress:

- **T-006** Schedule the daily notification — Scope `Habits/Notifications/`
- **T-007** Reminder time picker in Settings — Scope `Habits/Views/Settings/`

| Changed file | Fence |
|---|---|
| `Habits/Notifications/NotificationScheduler.swift` | ok, inside T-006 |
| `Habits/Views/Settings/ReminderPicker.swift` | ok, inside T-007 |
| `.hafness/tasks.md` | ok, harness bookkeeping is always allowed |
| `Habits/Models/Habit.swift` | **fails**, no task in progress covers it |
| `.hafness/profile.sh` | **fails**, it's the gate's own config and no task names it |

```
--- scope fence
    changed outside the Scope of every doing task:
      Habits/Models/Habit.swift
    FAILED (scope fence)
```

---

## Every file

What setup adds to your project. Everything lives in one `.hafness/` folder, plus two short
pointer files and one hook. It's all markdown or shell, so you can read every file before
anything runs.

**Review** ●●● read before anything runs · ● read once · ○ read when curious · — never

```
your-project/
├── CLAUDE.md                 pointer: read .hafness/HAFNESS.md first
├── AGENTS.md                 the same pointer, for other agents
├── .claude/settings.json     gains one prompt hook
├── .gitignore                gains history.md and board.html
└── .hafness/
    ├── HAFNESS.md            the map
    ├── state/
    │   ├── current.md        the resume point
    │   └── decisions.md      the decision log
    ├── research/             one note per topic
    ├── specs/                one spec per feature
    ├── plans/                one plan per spec
    ├── tasks.md              every task, its Scope and run id
    ├── feedback.md           your feedback, quoted
    ├── profile.sh            what the gate runs
    ├── verify.sh             the gate
    ├── board.sh → board.html the board
    ├── history.sh → history.md  every prompt
    ├── policy.md             stop-and-ask and never lists
    ├── rules/                rules for one area, loaded on demand
    └── log/
        ├── <date>.md         one block per gate run
        └── journal.md        lessons, and where they went
```

### Next to your code

| File | Job | Written by | Review |
|---|---|---|---|
| `CLAUDE.md` | Three lines telling Claude to read `.hafness/HAFNESS.md` first. A pointer, never a second set of instructions. | `/hafness-init` (added to the top if one exists) | ● |
| `AGENTS.md` | The same pointer, for agents other than Claude. | `/hafness-init` | ● |
| `.claude/settings.json` | Gains one prompt hook that runs `.hafness/history.sh`. Your existing settings and hooks are kept. | `/hafness-init` (merged, never overwritten) | ● |
| `.gitignore` | Gains two lines, so your prompt history and the board that embeds it stay on your machine. Delete them if you want them committed. | `/hafness-init` | ○ |

### Read every session

| File | Job | Written by | Review |
|---|---|---|---|
| `HAFNESS.md` | The map: the loop, every file and its job, and what done means. Capped at 60 lines and checked, so it stays a map. | `/hafness-init` | ● |
| `state/current.md` | The resume point: what's in flight, the next action, open risks, the last run, and the board link. | every command, at the end | ● |
| `state/decisions.md` | Every decision, what it rejected, and why. When it disagrees with chat, this file wins. | the agent, as it decides | ○ |

### The work

| File | Job | Written by | Review |
|---|---|---|---|
| `research/` | One sourced note per topic: findings, options, a recommendation, sources. | `/hafness-research`, or describe and plan when needed | ○ |
| `specs/` | One spec per feature: what it does and why, never which files. | `/hafness-describe` | ● Assumptions first |
| `plans/` | One plan per spec: approach, files, files it won't touch, risks, verification, attempt budget. | `/hafness-plan`, updated by `/hafness-feedback` | ○ |
| `tasks.md` | Every task for every spec, with status, Scope and run id. The Scope column is the fence. | `/hafness-plan`, `/hafness-feedback`, `/hafness-implement` | ○ |
| `feedback.md` | Your feedback, quoted exactly, how the agent read it, and the tasks it became. | `/hafness-feedback` | ○ |

### The gate

| File | Job | Written by | Review |
|---|---|---|---|
| `profile.sh` | Exactly which commands decide pass or fail. The highest-stakes file: a wrong command here makes every later result meaningless. | `/hafness-init`, then you | ●●● |
| `verify.sh` | Format checks, then the scope fence, then whatever `profile.sh` declares. One exit code and one verdict line. | shipped with Hafness, rarely edited | ● when it changes |

### Board and history

| File | Job | Written by | Review |
|---|---|---|---|
| `board.sh` | Builds `board.html` from the markdown. Runs after every command and every prompt. | shipped with Hafness | — |
| `board.html` | The board. Generated, self-contained, opens from disk. Never edit it by hand. | `board.sh` only | open it |
| `history.sh` | The prompt hook. Appends each prompt to `history.md`, tags Hafness commands, redraws the board. Never prints, never blocks a prompt. | shipped with Hafness | — |
| `history.md` | Every prompt you typed in this project. Gitignored by default. If you paste a secret, delete the entry and rotate the secret. | `history.sh` | ○ |

### Policy, rules and ledger

| File | Job | Written by | Review |
|---|---|---|---|
| `policy.md` | What always needs your yes (force-push, migrations, releases, new dependencies, anything that sends) and what never happens (reading secrets, disabling a check to pass). | you | ● once |
| `rules/` | Rules for one area, like `swift.md` or `testing.md`. Loaded only when a plan touches those paths. | you, from lessons learned | ○ |
| `log/<date>.md` | One block per gate run. The gate writes the header; the agent adds which tasks ran, what changed, and what's next. Append only. | `verify.sh --log`, then `/hafness-implement` | ○ |
| `log/journal.md` | Lessons from runs that failed or passed badly, and where each one was promoted. | you or the agent | ○ |

---

## Picking up later

A new session never has to ask where you were. Open a new terminal with no chat history.
The agent reads `state/current.md`, checks whether the last session stopped halfway through
a task, and prints four lines before it touches any code:

> **In flight** · F-002 — Daily reminder at a chosen time (building)
> **Next action** · `/hafness-implement F-002`, attempt 2 of 3
> **Open risks** · No UI test target, so the gate only builds and runs unit tests
> **Board** · claude.ai/artifact/…

You don't have to explain anything again, and that's the test of the whole harness.

---

## When something goes wrong twice

Turn the lesson into a boundary. Write what happened in `log/journal.md`, then put the fix
where it belongs. A rule the agent keeps ignoring is a sign it should have been a check.

| The lesson is | Put it in |
|---|---|
| A judgement call. Loaded only when a plan touches that area. | `rules/swift.md` |
| Checkable by a script. Becomes one more line the gate runs. | `HAF_EXTRA` in `profile.sh` |
| Something that must never happen. The agent stops and asks, every time. | `policy.md` |

```sh
# profile.sh: a lesson promoted to a check
HAF_EXTRA=(
  "no-ui-in-models|! grep -rl 'import SwiftUI' Habits/Models"
)
```

---

## Commands

Install once:

```bash
npx skills add hafshy/hafness -a claude-code -y
```

Then seven commands:

| Command | What it does |
|---|---|
| `/hafness-init` | Once per project. Sets up `.hafness/`, finds your build and test commands, draws the first board. |
| `/hafness-research <topic>` | Optional. A sourced one-page note before you commit to anything. |
| `/hafness-describe <what you want>` | Your idea becomes a spec: what it does and why, never which files. |
| `reviewed` | Optional. Say it after reading a spec to mark it reviewed. |
| `/hafness-plan F-001` | The spec becomes a plan and a list of tasks, each fenced to its files. |
| `/hafness-implement F-001` | Builds task by task and runs the gate. A pass makes the spec done. |
| `/hafness-feedback F-001 <what you saw>` | Optional. Turns what you saw into new tasks and reopens the spec. |
