# Decisions

Append only. This file, not the chat, is the record. One entry per decision.

Format:

    ## YYYY-MM-DD — <decision in one line>
    Context: what forced the choice
    Chose: what was decided
    Rejected: what was not, and why
    Reverses: <earlier decision id, if any>

---

## 2026-09-14 — Six subsystems, not five or nine

Context: the article names seven jobs; harness-creator uses five subsystems; edts-harness
ships nine artifacts.
Chose: six — Contract, Map, Sensors, State, Policy, Ledger. Jobs 3 and 5 collapse into
Sensors because for one operator the verification layer is one file doing both.
Rejected: copying either reference's model wholesale. Both are built for more than one
person and neither implements the permissions job at all.

## 2026-09-14 — Stack-agnostic from day one

Context: most of my work is iOS, so an iOS-first profile was the obvious default.
Chose: stack-agnostic, profile-detected.
Rejected: iOS-first. The detection layer is the same work either way, and a harness that
only runs in one stack cannot be tested against a throwaway repo.

## 2026-09-15 — Every generated file is human-readable

Context: I review generated files before letting an implementation run.
Chose: no machine formats. FEATURES.md, profile.sh, contracts, run log, receipts are all
readable. Each states its format contract in its own header, and verify.sh lints it.
Rejected: JSON for the backlog and JSONL for the run log. The auditability they bought is
recovered by fixing the header *line* grammar instead of the file format.

## 2026-09-15 — profile.sh, not profile.md

Context: listing the commands in markdown and also writing them into verify.sh created two
sources of truth for the same data.
Chose: shell variables in profile.sh, sourced by verify.sh. Readable, reviewable, no parsing.
Rejected: profile.md with a table. It described what would run instead of being it.

## 2026-09-15 — HAFNESS.md must name every file, capped at 60 lines

Context: four files existed that no document mentioned.
Chose: a complete file index in the map, cap raised 50 → 60, and a lint that fails when a
file is unnamed or a row names a file that does not exist.
Rejected: a separate INDEX.md. An index is routing, which is what a map is for.

## 2026-09-15 — Plugin with slash commands, not a bare skill

Context: the substrate was chosen as "skill + files", but all four docs were written with
`/hafness:plan` syntax, which is plugin command syntax.
Chose: a plugin bundling the skill plus five commands. Deliberate per-session invocation
suits commands better than description-matching, and it leaves the door open for hooks in
phase three.
Rejected: a pure skill invoked by phrase, like edts-harness. Simpler to distribute, but it
would have meant rewriting the command names across every document.

## 2026-09-15 — Skills, not commands; `/hafness-<verb>`; installable via `npx skills add`

Context: F-001's open question. Current docs mark `commands/` legacy ("use `skills/` for
new plugins"), and `npx skills add` — the one-line install edts-harness uses — only
installs `skills/*/SKILL.md` directories. A skill named `init` would install as bare
`/init` and collide with the built-in.
Chose: five skills named `hafness-init`, `hafness-start`, `hafness-plan`,
`hafness-contract`, `hafness-handoff`, plus the `hafness` routing skill. `template/`
moves inside `skills/hafness-init/` so the installer carries it. `.claude-plugin/plugin.json`
stays (one file) so `claude --plugin-dir .` and phase-three hooks still work. Install
command for users is `npx skills add <owner>/hafness -a claude-code -y`. No marketplace.
Rejected: `commands/*.md` (legacy, not installable by npx); bare `<verb>` names
(collision); a marketplace (a second install path to maintain for one person).
Reverses: nothing — amends "Plugin with slash commands" (2026-09-15): still a plugin,
the commands are now skills.

## 2026-09-15 — F-006 folded into F-007

Context: the run-log writer has no caller except handoff and is never invoked by a user.
Chose: F-006 → `dropped`, its done-criteria move under F-007, F-007 deps → F-002.
Rejected: keeping the row and marking it done on F-007's evidence — a feature nobody can
run is not a feature. Id kept, not renumbered, so references stay valid.

## 2026-09-15 — Run-log header is written by `verify.sh --log`, not by the agent

Context: the header line is the one regex-linted thing in the ledger. Prose telling the
agent to type it correctly is the weaker half of the rule.
Chose: `verify.sh --log <feature> <attempt> <budget>` appends the header and verdict line
itself and prints `HAFNESS_RUN: r-nnnn`; the agent appends the rest of the block.
Rejected: a separate `scripts/gate.sh` inside the handoff skill — a second file that
would need to find `verify.sh` anyway; the gate already owns the exit code and the clock.

## 2026-09-15 — v0 built in one session under blanket approval

Context: operator said "start build them all" after the F-001 sign-off.
Chose: build F-001…F-008 in one pass, one run block `r-0001`, one receipt, every row's
Evidence cell pointing at it. Contracts F-002…F-008 written short and signed off by that
sentence. Rubric fidelity scored 3, not 5, to say so.
Rejected: eight staged runs — eight identical gate results would be theater, not evidence.

## 2026-10-05 — v1 loop: ask and try instead of sign-off, everything on a board
Context: approving contracts made of file paths was uncomfortable, and v0 was approved in
one blanket "start build them all". A survey of ten loops (Spec Kit, Kiro, OpenSpec,
Superpowers, GSD, BMAD, Compound Engineering, Taskmaster, Anthropic's long-running harness,
Ralph) showed people approve intent and judge results; agents own paths.
Chose: init → [research] → describe → [review] → plan → implement → feedback. Specs, plans,
tasks, feedback, runs and every prompt render to `board.html`, published as an Artifact when
possible. Kept `verify.sh`, `profile.sh`, `policy.md`, the run log. Task Scope is enforced by
a fence in `verify.sh`. Commands keep the `hafness-` prefix; history is a UserPromptSubmit hook.
Rejected: contract sign-off (judging paths is the agent's job); rubric and receipts (a
self-scored rubric was never evidence; the run block and the operator's acceptance are);
short `/describe` names (collide with other installed skills).
Reverses: the contract-as-first-class-artifact choice in docs/01-design.md.
