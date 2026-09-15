# Hafness vs. the reference harnesses

Three harnesses, measured against the seven jobs from rari's *Harness Engineering*. The
useful question is not which is best — it is which jobs each one actually covers, and
whether the gaps are the ones you feel.

| | **harness-creator** | **edts-harness** | **Hafness** |
|---|---|---|---|
| Author | WalkingLabs | EDTS | You |
| Purpose | Teach harness engineering, 0 → 1 | Ship a company-standard harness | One person's daily driver |
| Audience | Learners | Teams | A single operator |
| Install | Skill in a tutorial repo | `npx skills add edtsmobile/edts-harness` | Skill + `.hafness/` |
| Subsystem model | 5 | 9 artifacts, 4 modes | 6 |
| Artifacts | 5 templates | 9 files | 1 directory, 12ish files |
| Stack profiles | Generic | 9, one file each, no code change to add | Detected, generic fallback |
| Maturity | Tutorial-grade | v1 complete, 25 tests, self-auditing | Design only |

---

## Coverage against the seven jobs

| # | Job | harness-creator | edts-harness | Hafness |
|---|---|---|---|---|
| 1 | Request → contract | Partial — scope via deps + done-criteria in `feature_list.json` | Partial — `FEATURES.md` epics + dependency graph | **Full** — per-task contract with scope, non-scope, evidence, budget |
| 2 | Give a map | Yes — `AGENTS.md` / `CLAUDE.md` startup path | Yes — `CLAUDE.md` pointer → `AGENTS.md` router, one source of truth | Yes — `HAFNESS.md` <= 50 lines + on-demand `rules/` |
| 3 | Right tools, right environment | Partial — `init.sh` | Yes — `verify.sh` with only real, discovered commands | Yes — same rule, adopted |
| 4 | Durable state | Yes — `progress.md`, `feature_list.json` | Yes — `state/<name>.md` per person, `CONSTITUTION.md` always in context | Yes — one `current.md` + `decisions.md` |
| 5 | Sensors before autonomy | Yes — explicit runnable verification | **Strongest** — `HARNESS_VERIFY: PASS/FAIL` machine-parseable, plus `evaluator-rubric.md` maker-checker | Yes — borrows both |
| 6 | Permissions outside the model | **No** | **No** | **Full** — `policy.md` deny list, stop-and-ask |
| 7 | Traces + local recovery | Partial — `session-handoff.md` | Partial — `JOURNAL.md` lessons, `archive/` history | **Full** — markdown run trace with a fixed header grammar + per-run receipts + journal |

**The pattern that matters:** both references are strong on jobs 2–5 and weak on 1, 6, and 7.
That is not sloppiness — those three are the jobs that are hardest to do for *someone else's*
repo. A contract needs to know what you consider out of scope. A deny list needs to know what
you consider irreversible. A trace format needs to know what you will want to query later.
They are exactly the jobs a personal harness can do well and a distributed one cannot.

That is the honest case for building Hafness rather than installing one of these.

---

## What Hafness takes

**From edts-harness**

- **Never invent a check.** Only list a verification step if the real command was found in
  the project. "A check that can't run is worse than no check."
- **A machine-parseable verdict.** `HARNESS_VERIFY: PASS/FAIL` printed by the script, so
  the gate parses a line rather than interpreting prose. Hafness renames it `HAFNESS_VERIFY`.
- **The evaluator rubric as a separate yardstick** — grading whether finished work is
  actually good, not merely structurally present. This is the distinction that stops a
  green test suite from certifying the wrong feature.
- **Archiving as a written, ordered procedure** — write the archive file, link it, *then*
  delete the inline detail, so an interrupted session never loses the proof.
- **Audit catches skipped procedure.** A feature marked done with a broken evidence link is
  reported as a real defect, not a formatting nit.
- **One source of truth.** `CLAUDE.md` is a pointer, never a second set of instructions.
- **Self-governance.** edts-harness carries its own generated harness and its test suite
  generates a fresh harness into a throwaway repo and audits it. Hafness should do the same
  — that is the "harness benchmark" in the later tier.

**From harness-creator**

- **The five-subsystem decomposition** — instructions, state, verification, scope, lifecycle
  — is the skeleton Hafness's six are a rearrangement of.
- **Scoring the subsystems rather than eyeballing them.** `validate-harness.mjs` grades each
  and names the weak one; `/hafness-audit` copies the idea.
- **Keep instruction files short** and prefer state-file updates over chat history.
- **Require evidence before marking a feature done** — the rule Hafness turns into a hard
  gate with an evidence id.
- **Benchmarking a harness at all.** The existence of `run-benchmark.mjs` is the argument
  that a harness change should have evidence behind it.

---

## What Hafness rejects, and why

| Rejected | Source | Reason |
|---|---|---|
| `state/<name>.md` per person | edts-harness | The sharding exists so git never conflicts between two people's state. With one person it is a directory that only ever holds one file |
| `FEATURES.md` "By owner" column | edts-harness | One owner |
| `migrate` mode | edts-harness | It exists because the skill lands in repos that already have a harness. Yours start empty |
| Full file set in every project, no tiers | edts-harness | Deliberate there — it makes every team's harness the same shape. Pointless for one person; Hafness's v0/v1/later tiers are the opposite call, on purpose |
| Multi-agent coordination pattern | harness-creator | One builder, one evaluator. Swarms produce disagreement you then referee |
| Tutorial scaffolding, 13 localized READMEs | harness-creator | It is a teaching repo; you are the only reader |
| Tool registry as a separate subsystem | harness-creator | Claude Code already owns the tool layer. Duplicating it is a second source of truth |

---

## Where Hafness goes further

1. **The contract is a first-class artifact.** Neither reference binds a *single run*. They
   bind a backlog — features with dependencies and done-criteria — which stops scope drift
   across a project but not within a session. A contract with explicit out-of-scope paths
   and an attempt budget is the missing unit.
2. **Policy exists at all.** Job 6 is unimplemented in both. An agent that can force-push or
   fire a release build is relying on a probabilistic system to approve its own side effects.
3. **The trace is both readable and parseable.** `JOURNAL.md` and `progress.md` are prose
   with no grammar, so nothing can query them. Hafness fixes the *header line* rather than
   the file format, so a run log reads like a work diary and still answers "which rule broke
   most often this month" with one regex — and `verify.sh` lints the grammar so it cannot drift.
4. **Change receipts.** Neither produces a per-run record of what changed and what evidence
   justified it. Without one, a model upgrade is unmeasurable and a regression is unattributable.
5. **Budget and escalation are defined states.** `escalated` is a real status in Hafness's
   lifecycle, not an unhandled path.

---

## Where the references are still ahead

Stated plainly, because this is the part that should change your plan if anything does.

- **edts-harness works today.** v1 scope complete, 15/15 features, 25/25 tests, self-audit
  scoring 100, nine stack profiles. Hafness is a document.
- **Nine stack profiles is real coverage** you would rebuild one at a time.
- **Agent-agnostic.** edts-harness generates `AGENTS.md` with `CLAUDE.md` as a pointer and
  takes attribution from git config, so it runs the same under Claude Code, Codex, or Cursor.
  Hafness starts Claude-Code-shaped; that is a portability debt, not a feature.
- **`migrate` is genuinely hard** and already solved there.
- **It is already governed by its own harness** — the strongest evidence any of these three
  has that the design works.

### The option worth weighing

You work at EDTS and `edts-harness` is an EDTS skill. Forking it and adding the three
missing subsystems — Contract, Policy, Ledger — on top of its nine files would get you a
working harness in a fraction of the time, and the additions are the interesting part
anyway. The trade is that its shape is built around a team, so you would carry the
per-person state sharding and the owner columns as dead weight.

Building Hafness fresh is the right call if you want the design practice and a harness
shaped to exactly one person. It is the wrong call if what you want is a working harness
this month.

---

## Sources

- rari, *Harness Engineering: How to Build AI Agents That Don't Fall Apart* — https://x.com/0xwhrrari/status/2093685107534000560
- walkinglabs/learn-harness-engineering — https://github.com/walkinglabs/learn-harness-engineering
- edtsmobile/edts-harness — https://github.com/edtsmobile/edts-harness
