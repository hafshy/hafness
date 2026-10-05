#!/usr/bin/env bash
# Renders board.html from the markdown in .hafness/. The markdown is the source of truth;
# the board is a view of it. Never edit board.html by hand — the next run overwrites it.
#
# One self-contained file: every source document is embedded as a <script type="text/…">
# block and drawn in the browser, so it opens from disk and publishes as an Artifact as is.
# ponytail: markdown is rendered by marked from cdnjs; offline, documents show as plain text.

set -uo pipefail
HAF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAME="$(basename "$(dirname "$HAF")" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')"
OUT="$HAF/board.html"

embed() {                       # embed <type> <path relative to .hafness/>
  [ -f "$HAF/$2" ] || return 0
  printf '<script type="text/%s" data-path="%s">' "$1" "$2"
  sed 's#</[sS][cC][rR][iI][pP][tT]#<\\/script#g' "$HAF/$2"
  printf '</script>\n'
}

{
printf '<!doctype html>\n<meta charset="utf-8">\n'
printf '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n'
printf '<meta name="generated" content="%s">\n' "$(date '+%Y-%m-%d %H:%M')"
printf '<title>%s Board</title>\n' "$NAME"
cat <<'HTML'
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,600;12..96,700&family=Atkinson+Hyperlegible:wght@400;700&family=JetBrains+Mono:wght@400;600&display=swap">
<style>
/* Layout: header with the resume point, the loop as a strip of counts, then one panel per tab. */
:root {
  --bg: #F3F6F8; --surface: #FFFFFF; --sunk: #E9EEF2; --ink: #14202A; --muted: #586977; --line: #D6DEE4;
  --agent: #2F5D8A; --agent-bg: #E6EFF8; --gate: #9C5800; --gate-bg: #FCEBCF;
  --ask: #6B4FA3; --ask-bg: #EFEAF8; --check: #22704F; --check-bg: #E1F2E9; --bad: #B3261E; --bad-bg: #FBE4E2;
  --display: "Bricolage Grotesque", "Avenir Next", system-ui, sans-serif;
  --body: "Atkinson Hyperlegible", "Segoe UI", system-ui, sans-serif;
  --mono: "JetBrains Mono", ui-monospace, "SF Mono", Menlo, monospace;
  color-scheme: light;
}
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) {
  --bg: #0E151B; --surface: #16202A; --sunk: #111A22; --ink: #E4ECF1; --muted: #93A5B2; --line: #283643;
  --agent: #8DB8E4; --agent-bg: #1A2B3C; --gate: #F2AE4A; --gate-bg: #3A2A12;
  --ask: #B9A2EC; --ask-bg: #2A2340; --check: #66C79B; --check-bg: #15332A; --bad: #F2867E; --bad-bg: #3D1C1A;
  color-scheme: dark; } }
:root[data-theme="dark"] {
  --bg: #0E151B; --surface: #16202A; --sunk: #111A22; --ink: #E4ECF1; --muted: #93A5B2; --line: #283643;
  --agent: #8DB8E4; --agent-bg: #1A2B3C; --gate: #F2AE4A; --gate-bg: #3A2A12;
  --ask: #B9A2EC; --ask-bg: #2A2340; --check: #66C79B; --check-bg: #15332A; --bad: #F2867E; --bad-bg: #3D1C1A;
  color-scheme: dark; }
* { box-sizing: border-box; }
html, body { margin: 0; }
body { background: var(--bg); color: var(--ink); font: 15px/1.55 var(--body); }
.wrap { max-width: 1180px; margin: 0 auto; padding-inline: 20px; padding-block: 32px 72px; display: grid; gap: 28px; }
h1, h2, h3 { font-family: var(--display); line-height: 1.15; margin: 0; text-wrap: balance; }
h1 { font-size: clamp(1.9rem, 4.5vw, 2.7rem); letter-spacing: -0.02em; }
h3 { font-size: 1.08rem; }
p { margin: 0; }
code, .mono { font-family: var(--mono); font-size: 0.84em; }
a { color: var(--agent); }
button { font: inherit; color: inherit; }
:focus-visible { outline: 2px solid var(--gate); outline-offset: 2px; }
.eyebrow { font: 600 0.7rem/1.2 var(--mono); letter-spacing: 0.12em; text-transform: uppercase; color: var(--muted); }
.muted { color: var(--muted); }

/* header */
.top { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1.4fr); gap: 20px 32px; align-items: end; }
.top .title { display: grid; gap: 6px; }
.next { background: var(--surface); border: 1px solid var(--line); border-left: 3px solid var(--gate); border-radius: 8px; padding: 14px 16px; display: grid; gap: 6px; }
.next .md p { margin: 0; }
.facts { display: flex; flex-wrap: wrap; gap: 6px 18px; font-size: 0.86rem; color: var(--muted); }
@media (max-width: 760px) { .top { grid-template-columns: 1fr; } }

/* the loop strip */
.loop { display: flex; flex-wrap: wrap; align-items: stretch; gap: 6px; }
.stage { flex: 1 1 120px; background: var(--surface); border: 1px solid var(--line); border-radius: 8px; padding: 10px 12px; display: grid; gap: 2px; min-width: 0; }
.stage b { font: 700 1.5rem/1.1 var(--display); font-variant-numeric: tabular-nums; }
.stage span { font-size: 0.8rem; color: var(--muted); }
.stage code { font-size: 0.72rem; color: var(--muted); }
.stage.hot { border-color: var(--gate); background: var(--gate-bg); }

/* tabs */
.tabs { display: flex; gap: 4px; border-bottom: 1px solid var(--line); overflow-x: auto; }
.tabs button { background: none; border: 0; border-bottom: 2px solid transparent; padding: 10px 14px; cursor: pointer; color: var(--muted); white-space: nowrap; }
.tabs button[aria-selected="true"] { color: var(--ink); border-bottom-color: var(--ink); font-weight: 700; }
.tabs .count { font: 0.72rem var(--mono); margin-left: 6px; color: var(--muted); }
.panel { display: grid; gap: 14px; }
.empty { border: 1px dashed var(--line); border-radius: 8px; padding: 28px; text-align: center; color: var(--muted); }
.empty code { color: var(--ink); }

/* pills */
.pill { display: inline-block; font: 600 0.7rem/1 var(--mono); letter-spacing: 0.04em; padding: 4px 7px; border-radius: 999px; white-space: nowrap; background: var(--sunk); color: var(--muted); }
.s-reviewed, .s-open { background: var(--ask-bg); color: var(--ask); }
.s-planned, .s-todo { background: var(--agent-bg); color: var(--agent); }
.s-building, .s-doing { background: var(--gate-bg); color: var(--gate); }
.s-built, .s-PASS, .s-done, .s-accepted { background: var(--check-bg); color: var(--check); }
.s-blocked, .s-FAIL, .s-ESCALATED { background: var(--bad-bg); color: var(--bad); }
.s-dropped { text-decoration: line-through; }

/* features */
.features { display: grid; grid-template-columns: repeat(auto-fill, minmax(340px, 1fr)); gap: 14px; }
.feature { background: var(--surface); border: 1px solid var(--line); border-radius: 10px; padding: 16px; display: grid; gap: 12px; align-content: start; min-width: 0; }
.fhead { display: grid; grid-template-columns: auto 1fr auto; gap: 10px; align-items: baseline; }
.fhead .id { font: 600 0.8rem var(--mono); color: var(--muted); }
.track { list-style: none; margin: 0; padding: 0; display: grid; grid-template-columns: repeat(6, 1fr); gap: 3px; }
.track li { font-size: 0.66rem; color: var(--muted); display: grid; gap: 4px; min-width: 0; }
.track li::before { content: ""; height: 4px; border-radius: 2px; background: var(--sunk); }
.track li.on::before { background: var(--agent); }
.track li.now { color: var(--ink); font-weight: 700; }
.track li.now::before { background: var(--gate); }
.track.done li::before { background: var(--check); }
.fmeta { display: flex; flex-wrap: wrap; gap: 4px 14px; font-size: 0.82rem; color: var(--muted); }
details { border-top: 1px solid var(--line); padding-top: 8px; }
summary { cursor: pointer; font-weight: 700; font-size: 0.88rem; }
.md { font-size: 0.92rem; overflow-wrap: anywhere; }
.md h1 { font-size: 1.2rem; } .md h2 { font-size: 1rem; margin-top: 14px; } .md h3 { font-size: 0.95rem; }
.md p, .md ul, .md ol { margin: 8px 0; } .md ul, .md ol { padding-left: 1.2em; }
.md pre { background: var(--sunk); padding: 10px; border-radius: 6px; overflow-x: auto; }
.md table { border-collapse: collapse; display: block; overflow-x: auto; font-size: 0.85rem; }
.md th, .md td { border: 1px solid var(--line); padding: 4px 8px; text-align: left; }
.md blockquote { margin: 8px 0; padding-left: 12px; border-left: 3px solid var(--line); color: var(--muted); }

/* tasks */
.filter { display: flex; gap: 10px; align-items: center; font-size: 0.88rem; }
.filter select { font: inherit; padding: 4px 8px; border-radius: 6px; border: 1px solid var(--line); background: var(--surface); color: var(--ink); }
.kanban { display: grid; grid-template-columns: repeat(4, minmax(220px, 1fr)); gap: 12px; overflow-x: auto; padding-bottom: 4px; }
.col { background: var(--sunk); border-radius: 10px; padding: 10px; display: grid; gap: 8px; align-content: start; min-width: 0; }
.col h3 { font-size: 0.82rem; font-family: var(--mono); text-transform: uppercase; letter-spacing: 0.08em; color: var(--muted); display: flex; justify-content: space-between; }
.task { background: var(--surface); border: 1px solid var(--line); border-radius: 8px; padding: 10px 12px; display: grid; gap: 6px; }
.task .row { display: flex; gap: 8px; justify-content: space-between; font: 0.74rem var(--mono); color: var(--muted); }
.task .scope { font: 0.72rem/1.4 var(--mono); color: var(--muted); overflow-wrap: anywhere; }
.col.doing .task { border-left: 3px solid var(--gate); }
.col.blocked .task { border-left: 3px solid var(--bad); }

/* lists: research, feedback, history, runs */
.list { display: grid; gap: 10px; }
.item { background: var(--surface); border: 1px solid var(--line); border-radius: 8px; padding: 12px 14px; display: grid; gap: 8px; min-width: 0; }
.item .row { display: flex; flex-wrap: wrap; gap: 6px 12px; align-items: center; font-size: 0.8rem; color: var(--muted); }
.item details { border: 0; padding: 0; }
.quote { white-space: pre-wrap; overflow-wrap: anywhere; font-size: 0.92rem; }
.tag { font: 600 0.72rem var(--mono); padding: 3px 7px; border-radius: 5px; background: var(--ask-bg); color: var(--ask); }
.tag.plain { background: var(--sunk); color: var(--muted); }
.day { font: 600 0.74rem var(--mono); color: var(--muted); letter-spacing: 0.08em; text-transform: uppercase; margin-top: 8px; }
.scroll { overflow-x: auto; border: 1px solid var(--line); border-radius: 8px; background: var(--surface); }
table.runs { border-collapse: collapse; width: 100%; min-width: 560px; font-size: 0.88rem; }
table.runs th, table.runs td { text-align: left; padding: 8px 12px; border-bottom: 1px solid var(--line); font-variant-numeric: tabular-nums; }
table.runs th { font: 600 0.7rem var(--mono); letter-spacing: 0.08em; text-transform: uppercase; color: var(--muted); }
table.runs tr:last-child td { border-bottom: 0; }
footer { font-size: 0.8rem; color: var(--muted); }
</style>
HTML
embed markdown state/current.md
embed markdown tasks.md
embed markdown feedback.md
embed markdown history.md
embed plain profile.sh
for dir in specs plans research; do
  for f in "$HAF/$dir"/*.md; do
    [ -e "$f" ] || continue
    [ "$(basename "$f")" = README.md ] && continue
    embed markdown "$dir/$(basename "$f")"
  done
done
for f in "$HAF"/log/[0-9]*.md; do
  [ -e "$f" ] && embed markdown "log/$(basename "$f")"
done
cat <<'HTML'
<div class="wrap">
  <header class="top">
    <div class="title"><div class="eyebrow" id="eyebrow">Hafness board</div><h1 id="name"></h1><div class="facts" id="facts"></div></div>
    <div class="next" id="next"></div>
  </header>
  <nav class="loop" id="loop" aria-label="The loop"></nav>
  <nav class="tabs" role="tablist" id="tabs"></nav>
  <main id="panel" class="panel"></main>
  <footer id="foot"></footer>
</div>
<script src="https://cdnjs.cloudflare.com/ajax/libs/marked/12.0.2/marked.min.js"></script>
<script>
const docs = {};
document.querySelectorAll("script[data-path]").forEach(s => { docs[s.dataset.path] = s.textContent.replace(/<\\\/script/gi, "<" + "/script"); });
const esc = s => String(s).replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
const md = t => window.marked ? marked.parse(t) : `<pre>${esc(t)}</pre>`;
const ticks = s => s.replace(/`/g, "");
const sections = t => { const o = {}; (t || "").split(/^## /m).slice(1).forEach(c => { const i = c.indexOf("\n"); o[c.slice(0, i).trim()] = c.slice(i + 1).trim(); }); return o; };
const byPath = re => Object.keys(docs).filter(p => re.test(p)).sort();

// --- parse the markdown into board data ----------------------------------------
const STAGES = ["draft", "reviewed", "planned", "building", "built", "done"];
const STAGE_LABEL = ["Described", "Reviewed", "Planned", "Building", "Built", "Accepted"];
const specs = byPath(/^specs\/F-\d+\.md$/).map(p => {
  const t = docs[p], id = p.match(/F-\d+/)[0];
  const title = ((t.split("\n")[0] || "").split(" — ")[1] || id).trim();
  const status = ((t.match(/^Status:\s*(\w+)/m) || [])[1] || "draft");
  const body = t.split("\n").slice(1).join("\n").replace(/^Status:.*$/m, "");
  return { id, title, status, body, plan: docs[`plans/${id}.md`] };
});
const tasks = (docs["tasks.md"] || "").split("\n").filter(l => /^\| T-/.test(l)).map(l => {
  const [id, spec, task, status, scope, run] = l.split("|").slice(1, -1).map(c => c.trim());
  return { id, spec, task, status, scope: ticks(scope), run };
});
const feedback = (docs["feedback.md"] || "").split(/^## (?=FB-)/m).slice(1).map(c => {
  const [head, ...rest] = c.split("\n"), [id, date, spec, status] = head.split(" · ").map(s => s.trim());
  return { id, date, spec, status, body: rest.join("\n").trim() };
});
const prompts = (docs["history.md"] || "").split(/^## (?=\d{4}-)/m).slice(1).map(c => {
  const [head, ...rest] = c.split("\n"), [when, tag] = head.split(" · ").map(s => s.trim());
  return { when, tag: ticks(tag || "prompt"), skill: /^`/.test(tag || ""), text: rest.join("\n").replace(/^> ?/gm, "").trim() };
}).reverse();
const runs = byPath(/^log\/\d{4}-\d{2}-\d{2}\.md$/).flatMap(p => {
  const date = p.slice(4, 14);
  return [...docs[p].matchAll(/^## (r-\d+) · (\d\d:\d\d) · (\S+) · attempt (\d+)\/(\d+) · (PASS|FAIL|ESCALATED) · (.+)$/gm)]
    .map(m => ({ id: m[1], date, time: m[2], spec: m[3], attempt: `${m[4]}/${m[5]}`, verdict: m[6], dur: m[7] }));
}).reverse();
const research = byPath(/^research\/.+\.md$/).map(p => ({ path: p, title: ((docs[p].match(/^# (.+)$/m) || [])[1] || p), body: docs[p].replace(/^# .+\n/, "") }));
const cur = sections(docs["state/current.md"]);
const stack = ((docs["profile.sh"] || "").match(/^HAF_STACK="([^"]*)"/m) || [])[1] || "unknown";

// --- header and loop strip ------------------------------------------------------
document.getElementById("name").textContent = document.title.replace(/ Board$/, "");
document.getElementById("eyebrow").textContent = `Hafness board · ${stack}`;
const lastRun = runs[0];
document.getElementById("facts").innerHTML = [
  lastRun ? `Last gate <span class="pill s-${lastRun.verdict}">${lastRun.id} ${lastRun.verdict}</span>` : "No gate runs yet",
  `In flight: ${esc(ticks(cur["In flight"] || "nothing").split("\n")[0])}`,
].map(x => `<span>${x}</span>`).join("");
document.getElementById("next").innerHTML = `<div class="eyebrow">Next action</div><div class="md">${md(cur["Next action"] || "Not recorded.")}</div>`;

const count = s => specs.filter(x => x.status === s).length;
const openFb = feedback.filter(f => f.status === "open" || f.status === "planned").length;
const loop = [
  ["Research", research.length, "notes", "/hafness-research"],
  ["Describe", specs.length, "specs", "/hafness-describe"],
  ["Review", count("draft"), "waiting for review", "optional"],
  ["Plan", tasks.filter(t => t.status === "todo").length, "tasks to do", "/hafness-plan"],
  ["Implement", tasks.filter(t => t.status === "doing").length, "in progress", "/hafness-implement"],
  ["Feedback", count("built"), "built, waiting for you", "/hafness-feedback"],
];
document.getElementById("loop").innerHTML = loop.map(([n, v, what, cmd]) =>
  `<div class="stage ${v && (n === "Implement" || n === "Feedback") ? "hot" : ""}"><span>${n}</span><b>${v}</b><span>${what}</span><code>${cmd}</code></div>`).join("");

// --- panels ---------------------------------------------------------------------
const empty = (msg, cmd) => `<div class="empty">${msg}${cmd ? `<br><code>${cmd}</code>` : ""}</div>`;
const taskCard = t => `<div class="task"><div class="row"><span>${esc(t.id)} · ${esc(t.spec)}</span><span>${t.run !== "—" ? esc(t.run) : ""}</span></div><div>${esc(t.task)}</div>${t.scope !== "—" ? `<div class="scope">${esc(t.scope)}</div>` : ""}</div>`;

const panels = {
  features: { label: "Features", n: specs.length, draw: () => !specs.length ? empty("No specs yet. Describe what you want to build.", "/hafness-describe <what you want>") :
    `<div class="features">${specs.map(s => {
      const ts = tasks.filter(t => t.spec === s.id && t.status !== "dropped"), done = ts.filter(t => t.status === "done").length;
      const fb = feedback.filter(f => f.spec === s.id && (f.status === "open" || f.status === "planned")).length;
      const run = runs.find(r => r.spec === s.id), at = STAGES.indexOf(s.status);
      return `<article class="feature">
        <div class="fhead"><span class="id">${s.id}</span><h3>${esc(s.title)}</h3><span class="pill s-${esc(s.status)}">${esc(s.status)}</span></div>
        <ol class="track ${s.status === "done" ? "done" : ""}">${STAGE_LABEL.map((l, i) => `<li class="${i < at ? "on" : i === at ? "now" : ""}">${l}</li>`).join("")}</ol>
        <div class="fmeta"><span>${done}/${ts.length} tasks done</span>${fb ? `<span>${fb} open feedback</span>` : ""}${run ? `<span>last run ${run.id} ${run.verdict}</span>` : ""}</div>
        <details><summary>Spec</summary><div class="md">${md(s.body)}</div></details>
        ${s.plan ? `<details><summary>Plan</summary><div class="md">${md(s.plan.replace(/^# .+\n/, ""))}</div></details>` : ""}
        ${ts.length ? `<details><summary>Tasks</summary><div class="list">${ts.map(taskCard).join("")}</div></details>` : ""}
      </article>`; }).join("")}</div>` },
  tasks: { label: "Tasks", n: tasks.filter(t => t.status !== "dropped").length, draw: () => {
    if (!tasks.length) return empty("No tasks yet. Plan a spec to create them.", "/hafness-plan F-001");
    const ids = [...new Set(tasks.map(t => t.spec))];
    const pick = window.taskFilter || "all", shown = tasks.filter(t => pick === "all" || t.spec === pick);
    return `<div class="filter"><label for="spec-filter">Spec</label><select id="spec-filter"><option value="all">All specs</option>${ids.map(i => `<option ${i === pick ? "selected" : ""}>${esc(i)}</option>`).join("")}</select></div>
      <div class="kanban">${["todo", "doing", "done", "blocked"].map(st => { const c = shown.filter(t => t.status === st);
        return `<section class="col ${st}"><h3>${st}<span>${c.length}</span></h3>${c.map(taskCard).join("") || `<span class="muted" style="font-size:.82rem">Nothing here.</span>`}</section>`; }).join("")}</div>`; } },
  research: { label: "Research", n: research.length, draw: () => !research.length ? empty("No research notes. Research is optional, before describing.", "/hafness-research <topic>") :
    `<div class="list">${research.map(r => `<div class="item"><details><summary>${esc(r.title)}</summary><div class="md">${md(r.body)}</div></details><div class="row mono">${esc(r.path)}</div></div>`).join("")}</div>` },
  feedback: { label: "Feedback", n: feedback.length, draw: () => !feedback.length ? empty("No feedback yet. Try a built feature, then tell the agent what you think.", "/hafness-feedback F-001 <what you saw>") :
    `<div class="list">${feedback.slice().reverse().map(f => `<div class="item"><div class="row"><b>${esc(f.id)}</b><span>${esc(f.spec)}</span><span>${esc(f.date)}</span><span class="pill s-${esc(f.status)}">${esc(f.status)}</span></div><div class="md">${md(f.body)}</div></div>`).join("")}</div>` },
  history: { label: "History", n: prompts.length, draw: () => {
    if (!prompts.length) return empty("No prompts logged yet. The history hook records every prompt from here on.");
    const only = !!window.skillsOnly, rows = prompts.filter(h => !only || h.skill); let day = "";
    return `<div class="filter"><label><input type="checkbox" id="skills-only" ${only ? "checked" : ""}> Hafness commands only</label></div>
      <div class="list">${rows.map(h => { const d = h.when.slice(0, 10), head = d !== day ? `<div class="day">${d}</div>` : ""; day = d;
        return `${head}<div class="item"><div class="row"><span class="mono">${esc(h.when.slice(11))}</span><span class="tag ${h.skill ? "" : "plain"}">${esc(h.tag)}</span></div><div class="quote">${esc(h.text)}</div></div>`; }).join("")}</div>`; } },
  runs: { label: "Runs", n: runs.length, draw: () => !runs.length ? empty("No gate runs yet. Implementing a spec runs the gate.", "/hafness-implement F-001") :
    `<div class="scroll"><table class="runs"><thead><tr><th>Run</th><th>When</th><th>Spec</th><th>Attempt</th><th>Verdict</th><th>Took</th></tr></thead><tbody>${runs.map(r =>
      `<tr><td class="mono">${r.id}</td><td>${r.date} ${r.time}</td><td>${esc(r.spec)}</td><td>${r.attempt}</td><td><span class="pill s-${r.verdict}">${r.verdict}</span></td><td>${esc(r.dur)}</td></tr>`).join("")}</tbody></table></div>` },
};

const tabs = document.getElementById("tabs"), panel = document.getElementById("panel");
function show(key) {
  if (!panels[key]) key = "features";
  tabs.querySelectorAll("button").forEach(b => b.setAttribute("aria-selected", b.dataset.key === key));
  panel.innerHTML = panels[key].draw();
  const sel = document.getElementById("spec-filter"); if (sel) sel.onchange = e => { window.taskFilter = e.target.value; show("tasks"); };
  const box = document.getElementById("skills-only"); if (box) box.onchange = e => { window.skillsOnly = e.target.checked; show("history"); };
  if (location.hash.slice(1) !== key) history_replace(key);
}
function history_replace(key) { try { window.history.replaceState(null, "", "#" + key); } catch (e) {} }
tabs.innerHTML = Object.entries(panels).map(([k, p]) => `<button role="tab" data-key="${k}">${p.label}<span class="count">${p.n}</span></button>`).join("");
tabs.onclick = e => { const b = e.target.closest("button"); if (b) show(b.dataset.key); };
show(location.hash.slice(1));
const gen = document.querySelector('meta[name="generated"]');
document.getElementById("foot").innerHTML = `Generated ${gen ? gen.content : ""} by <code>.hafness/board.sh</code> from the markdown in <code>.hafness/</code>. Edit the markdown, not this page.${cur["Board"] && /^https?:/.test(cur["Board"]) ? ` · <a href="${esc(cur["Board"])}">Published board</a>` : ""}`;
</script>
HTML
} > "$OUT.tmp" && mv "$OUT.tmp" "$OUT"
echo "board: $OUT"
