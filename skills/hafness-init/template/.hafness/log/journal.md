# Journal

Lessons from failed or badly-passing runs. A lesson that generalizes gets promoted:
to `rules/` if it is a judgement call, to `profile.sh`'s `HAF_EXTRA` if it is
mechanically checkable, to `policy.md` if it must never happen.

Format:

    ## YYYY-MM-DD — <lesson in one line>
    Run: <evidence id>
    What happened:
    Why the harness allowed it:
    Promoted to: rules/ | HAF_EXTRA | policy | not promoted (one-off)

---
