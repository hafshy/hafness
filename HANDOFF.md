# Handoff — Hafness, design → build

**Read this once.** It is orientation: why the design is shaped the way it is, what is
already settled, and what will bite you. It does not track live state.

**Live state is [`.hafness/state/current.md`](.hafness/state/current.md)** — what is in
flight and what to do next. Read that every session. If this file and that one ever
disagree, that one wins, and this file is stale.

Written 2026-09-15 at the end of the design phase; status table updated the same day when v0 was built.

---

## 1. What Hafness is

A single-operator harness for AI coding agents. The model is the reasoning engine; Hafness
is the environment around it — what it can see, what it can touch, what survives between
sessions, what counts as evidence, and when a run must stop.

It ships as a **Claude Code plugin** that also installs with one `npx skills add`: a routing
skill, five `/hafness-<verb>` skills, and a `.hafness/` directory copied into each project.

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
| Design | Complete. Four documents, all current. |
| Backlog | Eight v0 features, seeded with deps and done-criteria. |
| Built | v0 complete — F-001…F-008, run `r-0001`. Not yet in git. |
| Self-hosting | Active — this repo carries its own `.hafness/`. |
| Gate | `bash .hafness/verify.sh` exits 0 here today. |

What exists and works: the six skills, the plugin manifest, `verify.sh --log`, the
template, `test/selfhost.sh`, and this repo's own harness. What does not exist: git history,
a pushed remote, any v1 feature, any `rules/*.md`.

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

Do not silently revisit these. If one turns out wrong while building, write the reversal
into `decisions.md` with what forced it — that file is the record, not the chat.

## 5. The shape, in one pass

Six subsystems, each owning one artifact and one enforcement point:

| Code | Owns | Enforced by |
|---|---|---|
| CTR | `scope/contracts/<id>.md` | no contract, no work |
| MAP | `HAFNESS.md` + `rules/` | ≤ 60 lines, names every file |
| SNS | `profile.sh` + `verify.sh` + `rubric.md` | exit code is the gate |
| STA | `state/current.md` + `decisions.md` | written before session end |
| POL | `policy.md` | stop-and-ask on the deny list |
| LDG | `log/` + `receipts/` + `journal.md` | append-only, receipt per run |

The loop: load state → contract → act → sense → gate → receipt → handoff. Three exits from
the gate — pass, retry within budget, escalate — and all three write to the ledger.
Diagrams in [docs/02-flows.md](docs/02-flows.md).

## 6. How to work in this repo

**Hafness harnesses itself.** The backlog, contracts, state and run log for *building*
Hafness live in `.hafness/` here, under the rules Hafness defines. This is deliberate: it
dogfoods the design and it gives the phase-one gate a real test subject.

Two consequences:

- **v0 was built by hand in one session** (`r-0001`), following `HAFNESS.md` as prose,
  because the skills did not exist yet. Everything after it should go through the loop.
- **When the gate complains about this repo, fix the repo.** Disabling a check to get a
  pass is an automatic rubric failure by the harness's own rules, and doing it here would
  be the project failing at the one thing it exists to prevent.

## 7. First action

Read [`.hafness/state/current.md`](.hafness/state/current.md). v0 is built; the next action
is to get it into git and use it on a real repo.

## 8. What will bite you

**The plugin manifest was the only unverified assumption in the design — now checked.**
Result: `commands/` is legacy, skills are the unit, and `npx skills add` is the install path.
Command names became `/hafness-<verb>` (npx-safe). The one thing still assumed is that the
installer copies `template/.hafness/` with its dot; F-001 tests that.

**The rubric threshold is a guess.** `no dimension below 3, total >= 20` in `rubric.md` was
picked to be plausible, not calibrated. Expect to move it once a few real runs have been
scored, and write the move into `decisions.md`.

**`policy.md` and `rubric.md` are hand-written, not generated**, so they do not currently
carry the drafts-until-signed-off rule. When `/hafness-journal` starts proposing edits to
them in v1, they will need it. Easy to forget.

**The format lint fails in both directions.** Adding a file under `.hafness/` without naming
it in `HAFNESS.md` fails; so does leaving a row for a file you deleted. This is intentional.

**Empty is skipped, not failed** in `profile.sh` — but a profile with nothing runnable
refuses to pass at all. If a stack goes undetected, the gate says so rather than going green.

## 9. Where things are

| | |
|---|---|
| Orientation | this file |
| Live state | `.hafness/state/current.md` |
| Backlog | `.hafness/scope/FEATURES.md` |
| Decisions | `.hafness/state/decisions.md` |
| Design | [docs/01-design.md](docs/01-design.md) |
| Flows | [docs/02-flows.md](docs/02-flows.md) |
| Comparison | [docs/03-comparison.md](docs/03-comparison.md) |
| File reference | [docs/04-files.md](docs/04-files.md) |
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
- **Worktree isolation per contract** — wanted, unspecified.
- **Whether to fork edts-harness instead.** Still a live option, argued in
  [docs/03-comparison.md](docs/03-comparison.md). Building fresh is the right call for
  design practice and a one-person shape; forking is right if a working harness this month
  matters more. Revisit honestly if F-001 through F-003 drag.

## 11. Sources

- rari, *Harness Engineering* — https://x.com/0xwhrrari/status/2093685107534000560
- walkinglabs/learn-harness-engineering — https://github.com/walkinglabs/learn-harness-engineering
- edtsmobile/edts-harness — https://github.com/edtsmobile/edts-harness
