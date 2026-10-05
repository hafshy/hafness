---
name: hafness-init
description: Install the Hafness harness into this project — copy .hafness/, detect the stack, write profile.sh, install the prompt-history hook, draw the first board, then stop for review.
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
| `*.xcodeproj` / `*.xcworkspace` | `xcode` | `xcodebuild -scheme <S> -destination 'generic/platform=iOS Simulator' build` | `xcodebuild test -scheme <S> -destination 'platform=iOS Simulator,name=<D>'` only if `xcodebuild -list` shows a test target | `swiftlint --strict` if `.swiftlint.yml` | — |
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

## 4. Install the history hook

Running `/hafness-init` is the operator's request for this hook; say that you are adding it.
Merge into `<project>/.claude/settings.json` (create it if absent; keep every existing key
and hook):

```json
{ "hooks": { "UserPromptSubmit": [ { "hooks": [
  { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.hafness/history.sh\"" }
] } ] } }
```

If an identical entry is already there, leave it. The hook takes effect from the next
prompt; say so.

## 5. Gate, board, stop

Run `bash .hafness/verify.sh` and show the output verbatim. Run `bash .hafness/board.sh`.
If this session has an Artifact tool, publish `.hafness/board.html` (icon `board`) and write
the returned URL under `## Board` in `state/current.md`. Set **Next action** to
`/hafness-describe <what you want to build>`. Then stop with:

> Review `.hafness/profile.sh` before anything runs. A wrong command there makes every later
> result meaningless. The board is at <URL or path>. When the profile is right, describe
> what you want: `/hafness-describe …` — or `/hafness-research <topic>` first.

If the stack was `unknown`, say plainly that the gate will refuse to pass until the operator
fills in at least one check by hand. Do not invent one.
