---
name: hafness-init
description: Install the Hafness harness into this project — copy .hafness/, detect the stack, write profile.sh, install the history and board hooks, draw the first board, then stop for review.
disable-model-invocation: true
---

# /hafness-init

## 1. Refuse if already installed

If `.hafness/` exists in the project root, stop: "Hafness is already installed. Edit
`.hafness/profile.sh` by hand or delete the directory first." Do nothing else.

## 2. Copy the template

`template/` sits next to this SKILL.md. Copy:

- `template/.hafness/` → `<project>/.hafness/`
- `template/CLAUDE.md` → `<project>/CLAUDE.md` — if one exists, **prepend** the template's
  three lines instead of overwriting.
- `template/AGENTS.md` → same rule.

## 3. Detect the stack — only what is actually here

Fill `.hafness/profile.sh`. Rules, in order of importance:

1. **Never guess.** Write a command only if its marker file exists *and* the tool is on
   `PATH` (`command -v`). Otherwise leave the variable empty.
2. Every non-empty line ends with `# found: <marker>` naming what you saw.
3. One stack. If two markers match, pick the one at the project root and mention the other
   in the `HAF_STACK` comment.

| Marker | `HAF_STACK` | BUILD | TEST | LINT | TYPECHECK |
|---|---|---|---|---|---|
| `Package.swift` | `swift-package` | `swift build` | `swift test` if `Tests/` exists | `swiftlint --strict` if `.swiftlint.yml` | — |
| `*.xcodeproj` / `*.xcworkspace` | `xcode` | `xcodebuild -scheme <S> -destination 'generic/platform=iOS Simulator' build` only if TEST stays empty | `xcodebuild test -scheme <S> -destination 'platform=iOS Simulator,name=<D>'` only if `xcodebuild -list` shows a test target | `swiftlint --strict` if `.swiftlint.yml` | — |
| `package.json` | `node` | `<pm> run build` if scripts.build | `<pm> test` if scripts.test | `<pm> run lint` if scripts.lint | `<pm> run typecheck` if scripts.typecheck, else `<pm> exec tsc --noEmit` if `tsconfig.json` |
| `go.mod` | `go` | `go build ./...` | `go test ./...` | `go vet ./...` | — |
| `pyproject.toml` | `python` | — | `pytest` if `tests/` or pytest in config | `ruff check .` if ruff in config | `mypy .` if mypy in config |
| `Cargo.toml` | `rust` | `cargo build` | `cargo test` | `cargo clippy -- -D warnings` if `cargo clippy --version` works | — |
| none | `unknown` | — | — | — | — |

`<S>` for Xcode: the first scheme from `xcodebuild -list`. `<D>`: an available iPhone from
`xcrun simctl list devices available` — never a name you did not see there. `<pm>` for
node: `pnpm` if `pnpm-lock.yaml`, `yarn` if `yarn.lock`, `bun` if `bun.lockb`, else `npm`.

Anything project-specific beyond these four goes in `HAF_EXTRA` as `"label|command"`, same
rule: only what really exists.

Keep the gate fast — it runs on every attempt:

- Xcode: when TEST is set, leave BUILD empty — `xcodebuild test` builds first, and a BUILD for
  a different destination compiles everything a second time. Use one `-derivedDataPath`, add
  `-quiet`, and `-only-testing:` the unit-test target; a UI-test target goes in `HAF_EXTRA` as
  its own check, and in `HAF_SLOW`.
- More than one app in the repo (say `ios/` and `web/`): give each app's checks paths in
  `HAF_PATHS`, so a change to one does not run the others' suites.
- Anything that drives a simulator or a browser end to end (UI tests, e2e suites) goes in
  `HAF_SLOW`: skipped on retries, run once with `--slow` before the spec is done.
- Leave `HAF_TIMEOUT_MIN=20` unless a check is known to take longer; say so if you raise it.

## 4. Install the hooks

Running `/hafness-init` is the operator's request for these hooks; say that you are adding them.
The history hook logs every prompt; the board hook redraws `board.html` after every edit
under `.hafness/`, silently, so the board stays current without the agent spending tokens on it.
Merge into `<project>/.claude/settings.json` (create it if absent; keep every existing key
and hook):

```json
{ "hooks": {
  "UserPromptSubmit": [ { "hooks": [
    { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.hafness/history.sh\"" }
  ] } ],
  "PostToolUse": [ { "matcher": "Write|Edit|MultiEdit", "hooks": [
    { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.hafness/board.sh\" --hook" }
  ] } ]
} }
```

If an identical entry is already there, leave it. The hooks take effect from the next
prompt; say so.

Append these two lines to `<project>/.gitignore` (create it if absent, skip lines already there):

    .hafness/history.md
    .hafness/board.html

`history.md` holds every prompt typed, and the board embeds it. Both stay on this machine
(and in the private published board). Tell the operator: delete the lines to commit them.

## 5. Gate, board, stop

Run `bash .hafness/verify.sh` and show the output verbatim (it is short: `ok` per check). Run `bash .hafness/board.sh`.
Do not publish the board; the operator opens `.hafness/board.html` locally, or runs
`/hafness-board` for a shareable link. Set **Next action** to
`/hafness-describe <what you want to build>`. Then stop with:

> Review `.hafness/profile.sh` before anything runs. A wrong command there makes every later
> result meaningless. The board is `.hafness/board.html` (`/hafness-board` for a link). When the profile is right, describe
> what you want: `/hafness-describe …` — or `/hafness-research <topic>` first.

If the stack was `unknown`, say plainly that the gate will refuse to pass until the operator
fills in at least one check by hand. Do not invent one.
