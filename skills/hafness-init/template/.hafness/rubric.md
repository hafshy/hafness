# Rubric — is the finished work actually good, not merely present

Scored by a reader who did not write the code. Threshold: no dimension below 3, total >= 20.

| # | Dimension | 1 | 3 | 5 |
|---|---|---|---|---|
| 1 | Contract fidelity | Did something else | Did the thing, wandered outside scope | Exactly the contract, nothing more |
| 2 | Evidence | Claimed, not shown | Tests run, thin coverage of the change | The evidence would catch the bug this fixes |
| 3 | Blast radius | Touched files outside scope | Touched only in-scope files | Smallest diff that satisfies the contract |
| 4 | Failure handling | Errors swallowed | Errors surfaced | Errors surfaced with the context to act on |
| 5 | Fit | Ignores existing patterns | Mostly consistent | Indistinguishable from the surrounding code |

## Automatic fail

- A check was weakened, skipped, or deleted to get a pass
- `done` claimed with no evidence id in `log/`
- A decision was made and not written to `state/decisions.md`
