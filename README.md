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
