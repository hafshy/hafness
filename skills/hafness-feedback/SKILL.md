---
name: hafness-feedback
description: Record the operator's feedback on built work — accept it as done, or turn it into new scoped tasks on the board. Usage - /hafness-feedback F-nnn <what you saw or want changed>
disable-model-invocation: true
---

# /hafness-feedback $ARGUMENTS

No spec id given? Use the spec in flight in `state/current.md`; if none is clear, ask.

## 1. Record it

Append to `.hafness/feedback.md`, continuing the highest `FB-nnn`:

    ## FB-nnn · YYYY-MM-DD · F-nnn · open

    > the operator's words, exactly — every line quoted

    **Read as** what you understood, in one or two lines.

## 2. Accept, or turn it into tasks

**Acceptance** ("accept", "looks good", "ship it"): header status → `accepted`, spec
`Status:` → `done`. Nothing else.

**Change requests**: compare against the spec's "How you'll know".

- A change to *what* the feature does → update the spec's Requirements and "How you'll
  know" first, and say so. The spec stays the source of truth.
- Then append tasks to `tasks.md` (same row format and Scope rules as `/hafness-plan`),
  each one tracing back to this entry. Add **Tasks** `T-nnn, …` to the entry; status → `planned`.
- Spec `Status:` → `planned`.

When `/hafness-implement` later finishes those tasks with a PASS, it sets this entry `done`.

Unclear feedback: ask one question before writing tasks. Never guess what "it feels off" means.

## 3. Finish

1. `state/current.md`: **Next action** → `/hafness-implement F-nnn` (or the next spec, if accepted).
2. `bash .hafness/verify.sh` — the format lint must pass.
3. `bash .hafness/board.sh`; if this session has an Artifact tool, publish `board.html`
   (with the URL under `## Board` if one is there, else new — and record the URL).
4. Stop: name the entry, what it became (accepted, or the new task ids), and the next command.
