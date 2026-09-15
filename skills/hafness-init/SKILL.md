---
name: hafness-init
description: Install the Hafness harness into this project — copy .hafness/, detect the stack, write profile.sh, then stop for review.
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

Then delete `.hafness/log/2026-09-15.md` — it is a worked example of two run blocks, and
leaving it makes the first real run `r-0293`. The grammar it demonstrates is written into
every log file `verify.sh --log` creates.

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
| `*.xcodeproj` / `*.xcworkspace` | `xcode` | `xcodebuild -scheme <S> -destination 'generic/platform=iOS Simulator' build` | `xcodebuild test -scheme <S> -destination 'platform=iOS Simulator,name=iPhone 17'` only if `xcodebuild -list` shows a test target | `swiftlint --strict` if `.swiftlint.yml` | — |
| `package.json` | `node` | `<pm> run build` if scripts.build | `<pm> test` if scripts.test | `<pm> run lint` if scripts.lint | `<pm> run typecheck` if scripts.typecheck, else `<pm> exec tsc --noEmit` if `tsconfig.json` |
| `go.mod` | `go` | `go build ./...` | `go test ./...` | `go vet ./...` | — |
| `pyproject.toml` | `python` | — | `pytest` if `tests/` or pytest in config | `ruff check .` if ruff in config | `mypy .` if mypy in config |
| `Cargo.toml` | `rust` | `cargo build` | `cargo test` | `cargo clippy -- -D warnings` if `cargo clippy --version` works | — |
| none | `unknown` | — | — | — | — |

`<S>` for Xcode: the first scheme from `xcodebuild -list`. `<pm>` for node: `pnpm` if
`pnpm-lock.yaml`, `yarn` if `yarn.lock`, `bun` if `bun.lockb`, else `npm`.

Anything project-specific beyond these four goes in `HAF_EXTRA` as `"label|command"`, same
rule: only what really exists.

## 4. Run the gate once and stop

Run `bash .hafness/verify.sh`, show the output verbatim, then stop with:

> Review `.hafness/profile.sh` before anything runs. A wrong command there makes every later
> result meaningless. When it is right, `/hafness-plan <goal>` starts the backlog.

If the stack was `unknown`, say plainly that the gate will refuse to pass until the operator
fills in at least one check by hand. Do not invent one.
