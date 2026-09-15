# Policy — what the harness authorizes, not the model

The agent may propose any of these. It may not perform them without an explicit yes in the
current session. Permission is per action, never generalized from a previous yes.

## Stop and ask

- `git push --force`, `git reset --hard`, branch deletion, history rewrite
- Committing to the default branch
- Any database migration, seed, or destructive query
- Release builds, version bumps, tag creation, publishing a package
- Anything that sends: email, chat message, webhook, push notification
- Installing a dependency not already in the lockfile
- Creating or modifying CI configuration, hooks, or scheduled jobs
- Editing anything under `.hafness/policy.md` itself

## Never

- Reading, printing, or committing secrets, `.env` files, keychains, provisioning profiles
- Disabling a check to make `verify.sh` pass
- Editing `log/` in place — it is append-only
- Marking a feature done without an evidence id

## Rule

If an action is expensive, irreversible, or touches another person, it stops here.
Do not ask one probabilistic system to invent the plan, approve the risk, and execute the
side effect.
