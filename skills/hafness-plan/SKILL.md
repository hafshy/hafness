---
name: hafness-plan
description: Plan how to build one spec — approach, files, risks — and break it into scoped tasks on the board. Usage - /hafness-plan F-nnn
disable-model-invocation: true
---

# /hafness-plan $ARGUMENTS

## Refuse when

- `specs/<id>.md` does not exist — offer `/hafness-describe`
- its status is not `draft`, `reviewed`, or `planned` (re-planning) — say what it is and stop

## 1. Read

The spec, any `research/*.md` it relies on, then the code the spec touches. Now is when
source files are read. Load only the `rules/*.md` files the planned paths implicate.

## 2. Write the plan

`.hafness/plans/<id>.md`, following `plans/README.md` exactly. Fill it from the repo, not
from imagination:

- **Files** — real paths that will change. Look at the tree.
- **Not touching** — real paths that are adjacent and tempting.
- **Verification** — for every item in the spec's "How you'll know": which `verify.sh` check,
  command, or screenshot will show it. An item nothing can show is a risk; list it there.
- **Budget** — `Attempts: 3` unless the operator said otherwise.

## 3. Write the tasks

Append rows to `.hafness/tasks.md`, continuing the highest `T-nnn`:

    | T-nnn | <spec id> | <one line, imperative> | todo | `path/`, `other/file.swift` | — |

- Small: one sitting each, in the order they should be done.
- **Scope** — only the paths from the plan's Files list this task needs. The scope fence
  fails the gate on any change outside the Scope of the tasks in progress, so be exact.
- `blocked` instead of `todo` if it waits on another spec that is not `done`.

Re-planning: mark the old unfinished tasks `dropped`, never delete rows.

## 4. Finish

1. Spec `Status:` → `planned`.
2. `state/current.md`: **In flight** → `<id> — <title> (planned, n tasks)`. **Next action** →
   `/hafness-implement <id>`. Plan risks go under **Open risks**.
3. `bash .hafness/verify.sh` — the format lint must pass; fix the files, never the lint.
4. `bash .hafness/board.sh`; if this session has an Artifact tool, publish `board.html`
   (with the URL under `## Board` if one is there, else new — and record the URL).
5. Stop:

> Plan and <n> tasks for <id> are on the board. Each task's Scope is the fence the gate
> will hold me to. Edit anything you disagree with. `/hafness-implement <id>` when ready.
