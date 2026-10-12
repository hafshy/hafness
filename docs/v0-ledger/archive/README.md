# Archive

Closed contracts and their full detail, moved out of the hot files so they stop costing
context on every session start.

**The order matters.** When a feature closes:

1. Write the full detail to `archive/<feature-id>.md`.
2. Link it from that feature's Evidence cell in `scope/FEATURES.md`.
3. *Then* delete the inline detail from the contract.

In that order, so an interrupted session never loses the proof. A feature marked `done`
whose Evidence cell points at a file that is not here is a defect, not a formatting nit —
`verify.sh` fails on it.

Nothing here is ever read during normal work. It exists for the moment you ask "why did I
do it that way in March".
