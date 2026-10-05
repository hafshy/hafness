# Receipts

One file per run, named for its run id: `r-0291.md`.

A receipt is not a summary of the work — it is the record of *how the output was produced*,
so that a model upgrade is comparable and a regression is attributable.

Each one carries:

- **Changed** — diff stat, files touched
- **Evidence** — what verify.sh said, and which checks actually ran
- **Decided** — choices made during the run, and what they rule out
- **Not done** — what was deliberately left, so the next session does not redo the thinking
- **Cost** — attempts used against budget, wall clock

Written at the gate, for passes and failures alike. A run with no receipt did not happen.
