# Hafness — files

Every file in `.hafness/` and its job. Read this only when you need to know what a file
is for; `HAFNESS.md` routes, this indexes.

| Path | Job |
|---|---|
| `HAFNESS.md` | the map — routing, nothing else |
| `FILES.md` | this index |
| `policy.md` | what needs approval, what is forbidden |
| `profile.sh` | what will actually run; sourced by `verify.sh` |
| `verify.sh` | the gate — format lint, scope fence, then the project checks |
| `board.sh` | renders `board.html` from the markdown below; `--hook` redraws after edits |
| `board.html` | the board — generated, never edited by hand |
| `history.sh` | prompt hook — appends every prompt to `history.md` |
| `history.md` | every prompt, tagged when it is a Hafness command |
| `research/` | optional research notes, one per topic |
| `specs/` | one spec per feature — what and why |
| `plans/` | one plan per spec — how, which files |
| `tasks.md` | open tasks: status, scope, run id |
| `tasks-done.md` | tasks of done specs, moved here so `tasks.md` stays short |
| `feedback.md` | the operator's feedback on done work |
| `rules/` | domain rules, loaded on demand only |
| `state/current.md` | in flight, next action, open risks, board link |
| `state/decisions.md` | decision log — supersedes chat |
| `log/` | one dated file per day, one block per gate run |
| `log/journal.md` | lessons, promoted into rules or checks |

A file under `.hafness/` named neither here nor in `HAFNESS.md` is undocumented, and `verify.sh` fails.
