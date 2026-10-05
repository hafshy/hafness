# Handoff — Hafness

**Read this once.** It is orientation: why the design is shaped the way it is, what is
already settled, and what will bite you. It does not track live state.

**Live state is [`.hafness/state/current.md`](.hafness/state/current.md)** — what is in
flight and what to do next. Read that every session. If this file and that one ever
disagree, that one wins, and this file is stale.

Written 2026-09-15 at the end of the design phase. Updated 2026-10-05 for the v1 loop.

---

## 1. What Hafness is

A single-operator harness for AI coding agents. The model is the reasoning engine; Hafness
is the environment around it — what it can see, what it can touch, what survives between
sessions, what counts as evidence, and when a run must stop.

It ships as a **Claude Code plugin** that also installs with one `npx skills add`: a routing
skill, six `/hafness-<verb>` skills, and a `.hafness/` directory copied into each project.
Everything it writes is drawn on one generated HTML board.

Built for one person. No collaboration machinery, deliberately — see
[docs/03-comparison.md](docs/03-comparison.md) for what was cut and why.

## 2. The one principle everything follows from

Encode every important rule twice: once as prose the agent understands (the reason), once
as a mechanical check it cannot bypass (the boundary).

A prose rule is guidance. A script is a boundary.

Every design choice below is this principle applied somewhere. When you are unsure what to
do, ask which half is missing — the explanation or the check.

## 3. Status

| | |
|---|---|
| v0 | Built 2026-09-15 (F-001…F-008, run `r-0001`). Its ledger is in `docs/v0-ledger/`. |
| v1 | The loop and the board (F-009), 2026-10-05. |
| Self-hosting | Active — this repo carries its own `.hafness/` and board. |
| Gate | `bash .hafness/verify.sh` exits 0 here. |
| Real use | None yet. The first `/hafness-init` in a real repo is the honest test. |

## 4. Settled decisions

Full entries with what each one rejected are in
[`.hafness/state/decisions.md`](.hafness/state/decisions.md). In brief:

1. **Six subsystems** — Contract, Map, Sensors, State, Policy, Ledger. Jobs 3 and 5 from the
   source article collapse into Sensors for a single operator.
2. **Stack-agnostic**, profile-detected. Not iOS-first, despite most work being iOS.
3. **Every generated file is human-readable.** No JSON anywhere in the design.
4. **`profile.sh`, not `profile.md`** — shell variables sourced by `verify.sh`, so the list
   of commands and the thing that runs them are one file.
5. **`HAFNESS.md` names every file**, capped at 60 lines, linted both directions.
6. **A plugin, not a bare skill.** This reversed an earlier choice.

7. **v1: you approve intent and judge results; the agent owns paths.** Contract sign-off,
   the rubric and receipts are gone; task Scope is enforced by a fence in `verify.sh`.

Do not silently revisit these. If one turns out wrong while building, write the reversal
into `decisions.md` with what forced it — that file is the record, not the chat.

## 5. The shape, in one pass

| Step | Command | Writes | The boundary |
|---|---|---|---|
| init | `/hafness-init` | `profile.sh`, history hook, board | you review `profile.sh` |
| research | `/hafness-research` | `research/<slug>.md` | optional |
| describe | `/hafness-describe` | `specs/F-nnn.md` | ≤ 5 questions; review optional |
| plan | `/hafness-plan` | `plans/F-nnn.md`, rows in `tasks.md` | each task carries a Scope |
| implement | `/hafness-implement` | code, a run block | the gate and the scope fence |
| feedback | `/hafness-feedback` | `feedback.md`, tasks or acceptance | only you move `built` to `done` |

Every command ends by rewriting `state/current.md` and redrawing the board. `policy.md`
applies throughout. The v0 diagrams in [docs/02-flows.md](docs/02-flows.md) still explain
the gate's three exits (pass, retry within budget, escalate), which v1 keeps.

## 6. How to work in this repo

**Hafness harnesses itself.** The specs, tasks, state, run log and board for *building*
Hafness live in `.hafness/` here, under the rules Hafness defines. This is deliberate: it
dogfoods the design and it gives the phase-one gate a real test subject.

Two consequences:

- **v0 was built by hand in one session** (`r-0001`), and v1 (F-009) was built in one
  session after a design conversation. Everything after it should go through the loop.
- **When the gate complains about this repo, fix the repo.** Disabling a check to get a
  pass is on `policy.md`'s never list, and doing it here would be the project failing at
  the one thing it exists to prevent.

## 7. First action

Read [`.hafness/state/current.md`](.hafness/state/current.md), or open `.hafness/board.html`.

## 8. What will bite you

**The plugin manifest was the only unverified assumption in the design — now checked.**
Result: `commands/` is legacy, skills are the unit, and `npx skills add` is the install path.
Command names became `/hafness-<verb>` (npx-safe). The one thing still assumed is that the
installer copies `template/.hafness/` with its dot; F-001 tests that.

**The scope fence compares against the last commit.** Uncommitted work from before a task
trips it. `/hafness-implement` asks for a clean tree first; a per-task base commit is the
upgrade if that gets annoying.

**The history hook logs everything typed**, into a committed file. It needs `python3` to
parse the hook input, and it must never print: a prompt hook's stdout joins the conversation.

**The board is a generated view.** Hand edits to `board.html` vanish on the next prompt.
Edit the markdown.

**The format lint is strict.** Adding a file under `.hafness/` without naming it in
`HAFNESS.md` fails. This is intentional.

**Empty is skipped, not failed** in `profile.sh` — but a profile with nothing runnable
refuses to pass at all. If a stack goes undetected, the gate says so rather than going green.

## 9. Where things are

| | |
|---|---|
| Orientation | this file |
| Live state | `.hafness/state/current.md` |
| Board | `.hafness/board.html` |
| Specs and tasks | `.hafness/specs/`, `.hafness/tasks.md` |
| Decisions | `.hafness/state/decisions.md` |
| v0 design | [docs/01-design.md](docs/01-design.md), [docs/02-flows.md](docs/02-flows.md) |
| Comparison | [docs/03-comparison.md](docs/03-comparison.md) |
| File reference | [docs/04-files.md](docs/04-files.md) |
| v0 ledger | `docs/v0-ledger/` |
| Scaffold shipped to projects | `skills/hafness-init/template/` |

## 10. Not decided yet

Open on purpose. Do not treat silence here as a decision already made.

- **Phase-three hook format** — how `policy.md` becomes enforcement patterns a hook reads.
  The shape is agreed (prose keeps the reason, a pattern file carries the boundary); the
  format is not.
- **Whether `verify.sh` ships as a plugin asset or is generated per project.** Currently
  shipped. Generation would let `init` tailor the lint; shipping keeps one version to fix.
- **Cross-project journal** — how a lesson from one repo becomes a candidate rule in the
  next. Listed in the later tier with no mechanism behind it.
- **Worktree isolation per spec** — wanted, unspecified.
- **Live reload of the local board** — today you refresh the page.
- **Whether to fork edts-harness instead.** Still a live option, argued in
  [docs/03-comparison.md](docs/03-comparison.md). Building fresh is the right call for
  design practice and a one-person shape; forking is right if a working harness this month
  matters more. v1 has diverged far enough that this is now mostly moot.

## 11. Sources

- rari, *Harness Engineering* — https://x.com/0xwhrrari/status/2093685107534000560
- walkinglabs/learn-harness-engineering — https://github.com/walkinglabs/learn-harness-engineering
- edtsmobile/edts-harness — https://github.com/edtsmobile/edts-harness
