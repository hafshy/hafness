# Plans

One file per spec: `F-nnn.md`, same id. Written by `/hafness-plan`. **How**, and which files.
The tasks it produces go into `../tasks.md`; this file holds the reasoning behind them.

    # Plan F-nnn — <title>

    ## Approach
    Three to six sentences. The shape of the change, and why this shape.

    ## Files
    - `path/` — what changes there. This list becomes the tasks' Scope.

    ## Not touching
    - `path/` — adjacent and tempting. The scope fence enforces it.

    ## Risks
    - What could go wrong and what the agent will do about it.

    ## Verification
    How each "How you'll know" item in the spec gets shown: a `verify.sh` check, a
    command, a screenshot.

    ## Budget
    Attempts: 3
