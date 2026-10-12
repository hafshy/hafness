---
name: hafness-feedback
description: Optional. Turn the operator's feedback on done work into new scoped tasks on the board, reopening the spec. Usage - /hafness-feedback F-nnn <what you saw or want changed>
disable-model-invocation: true
---

# /hafness-feedback $ARGUMENTS

No spec id given? Use the spec in flight in `state/current.md`; if none is clear, ask.

Feedback is optional: a spec is `done` once its gate passes. Feedback reopens it. If what
the operator wants is a new feature rather than a change to this one, write nothing yet and
ask: "Reopen F-nnn with this, or start a new spec?" — on new spec, offer
`/hafness-describe <their words>, building on F-nnn`.

## 1. Record it

Append to `.hafness/feedback.md`, continuing the highest `FB-nnn`:

    ## FB-nnn · YYYY-MM-DD · F-nnn · open

    > the operator's words, exactly — every line quoted

    **Read as** what you understood, in one or two lines.

## 2. Turn it into tasks

Compare it against the spec's "How you'll know". Praise with nothing to change ("looks
good") needs no entry; say so and stop.

- A change to *what* the feature does → update the spec's Requirements and "How you'll
  know" first, and say so. The spec stays the source of truth.
- Then append tasks to `tasks.md` (same row format and Scope rules as `/hafness-plan`),
  each one tracing back to this entry. Add **Tasks** `T-nnn, …` to the entry; status → `planned`.
  Revising work that is already built is expected: a task's Scope may name files earlier
  tasks built. Read those files first, so the task says what changes in them.
- Bring `plans/<id>.md` up to date with the new tasks: add their paths to **Files**, take
  them out of **Not touching** (and say so — that list was a promise), extend
  **Verification** for any new "How you'll know" item, and append one line under
  **Revisions**: `- FB-nnn — <what changes in the approach> (T-nnn, …)`. If the change needs
  research no note covers, write that research note first, as `/hafness-plan` does.
- Spec `Status:` → `planned`.

When `/hafness-implement` later finishes those tasks with a PASS, it sets this entry `done`.

Unclear feedback: ask one question before writing tasks. Never guess what "it feels off" means.

## 3. Finish

1. `state/current.md`: **Next action** → `/hafness-implement F-nnn`.
2. `bash .hafness/verify.sh` — the format lint must pass.
3. `bash .hafness/board.sh`; if this session has an Artifact tool, publish `board.html`
   (with the URL under `## Board` if one is there, else new — and record the URL).
4. Stop: name the entry, the new task ids, and the next command.
