---
name: hafness-research
description: Research a topic (web, docs, this codebase) into a short note on the board. Optional to type - /hafness-describe and /hafness-plan research on their own when a request needs it. Usage - /hafness-research <topic>
disable-model-invocation: true
---

# /hafness-research $ARGUMENTS

Research is optional to type. It exists so `/hafness-describe` and `/hafness-plan` start
from evidence instead of memory — and when nobody ran it, they do the same research
themselves whenever the request would otherwise rest on a guess. Running it yourself is for
a topic you want explored before you know what to ask for.

## Research

Find what the operator would want to know before committing to a spec: how others solve
it, what the platform already provides, what this codebase already has, what it costs.
Use web search when the session has it, and the code in this repo. Every finding names its
source; a finding you cannot source is an assumption — label it that way.

Stay within the topic. This is a note, not a report: aim for a page.

## Write

`.hafness/research/<slug>.md`, following `research/README.md` exactly: the question in plain
words as the title, Findings, Options, Recommendation, Sources. Do not write a spec or tasks.

## Finish

1. `state/current.md`: **Next action** → `/hafness-describe <the thing, informed by research/<slug>.md>`.
2. `bash .hafness/board.sh`; if this session has an Artifact tool, publish `board.html`
   (with the URL under `## Board` if one is there, else new — and record the URL).
3. Stop:

> Research note on the board: `research/<slug>.md`. Recommendation: <one line>.
> `/hafness-describe …` when you are ready.
