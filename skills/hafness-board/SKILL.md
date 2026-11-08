---
name: hafness-board
description: Publish the Hafness board as a private claude.ai link, or update the existing one. Only on request - the loop never publishes, because publishing makes the agent read the whole board. Usage - /hafness-board
disable-model-invocation: true
---

# /hafness-board

The board is `.hafness/board.html`, redrawn by `board.sh` (and by the board hook after every
edit under `.hafness/`). Opening that file costs nothing. This command exists only to give
the operator a link to share, so run it only when they ask.

1. `bash .hafness/board.sh`, so the page matches the markdown.
2. No Artifact tool in this session: say so, give the path `.hafness/board.html`, stop.
3. Publish `.hafness/board.html`. If `state/current.md` has a URL under `## Board`, publish to
   that URL (update in place); otherwise publish new with icon `board` and write the returned
   URL under `## Board`.
4. Stop with one line: the URL, and that it is a snapshot — run `/hafness-board` again to
   refresh it.
