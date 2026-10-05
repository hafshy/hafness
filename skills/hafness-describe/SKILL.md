---
name: hafness-describe
description: Turn what the operator wants into a spec (what and why, never files) on the board. Usage - /hafness-describe <what you want, in your own words>
disable-model-invocation: true
---

# /hafness-describe $ARGUMENTS

If `.hafness/` does not exist, offer `/hafness-init` and stop.

## 1. Read

`state/current.md`, the specs already in `specs/` (to continue the numbering and avoid
duplicates), and any `research/*.md` the request touches. Not source files yet — a spec
is about behavior, and reading code first pulls it toward what is easy to build.

## 2. Ask, only if it matters

If an answer would change what gets built, ask — at most five questions, one at a time,
each naming what changes with the answer and offering your default. If the request is
clear enough, ask nothing and record your guesses under Assumptions instead.

## 3. Write the spec

`.hafness/specs/F-nnn.md` (next free id), following `specs/README.md` exactly, `Status: draft`.

- **Summary** — one paragraph, in the operator's language, not yours.
- **Requirements** — `R1 When …, the app shall …`. Behavior a user would notice.
- **How you'll know** — things the operator can do or see to check it works. This is what
  feedback will be measured against, so make each item concrete.
- **Out of scope** and **Assumptions** — every guess, listed. The operator checks these first.

Too big for one plan (more than about eight tasks)? Split it into several specs with their
own ids, and say how they depend on each other in each Summary.

Never name files or frameworks unless the operator did. That is the plan's job.

## 4. Finish

1. `state/current.md`: **In flight** → `F-nnn — <title> (draft)`. **Next action** →
   `review F-nnn (optional), then /hafness-plan F-nnn`.
2. `bash .hafness/verify.sh` — the spec must pass the format lint; fix the spec, never the lint.
3. `bash .hafness/board.sh`; if this session has an Artifact tool, publish `board.html`
   (with the URL under `## Board` if one is there, else new — and record the URL).
4. Stop:

> Spec F-nnn is on the board. Check the Assumptions first. Edit it or tell me what to
> change; say "reviewed" if you want it marked. `/hafness-plan F-nnn` when ready.

When the operator says "reviewed" (or similar) later, set `Status: reviewed` and redraw the board.
