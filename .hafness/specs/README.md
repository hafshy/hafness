# Specs

One file per feature: `F-nnn.md`. Written by `/hafness-describe`. **What and why** — never
which files. The operator reads these, so write for a person, not for the agent.

**Status** `draft` · `reviewed` · `planned` · `building` · `done` · `dropped`

- `draft` → `reviewed` only on the operator's word. Review is optional; plan accepts either.
- `done` means the gate passed with every task in it. Feedback is optional and reopens it.

**Format contract** — `verify.sh` fails if the first line or the `Status:` line drifts.

    # F-nnn — <title>

    Status: draft

    ## Summary
    One paragraph a person could repeat to a friend.

    ## Requirements
    - R1 When <situation>, the app shall <behavior>.

    ## How you'll know
    - Things the operator can run or look at to see it working.

    ## Out of scope
    - Adjacent things this spec does not cover.

    ## Assumptions
    - Every guess the agent made. The operator checks these first.
