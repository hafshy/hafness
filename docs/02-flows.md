# Hafness — flows

Six diagrams. Together they define what actually happens when Hafness runs, including the
paths most harnesses leave undefined: what happens when the gate fails, and what happens
when the budget runs out.

Subsystem codes: **CTR** Contract · **MAP** Map · **SNS** Sensors · **STA** State · **POL** Policy · **LDG** Ledger

---

## 1. The session loop

The spine. Everything else hangs off this. Note that there are exactly three ways out of the
gate — pass, retry, escalate — and all three write to the ledger. A run never ends silently.

```mermaid
flowchart TD
    START(["Session starts"]) --> LOAD["Load state<br/><b>STA</b><br/>current.md · log tail · open contract"]
    LOAD --> PRINT["Print next action<br/><i>before reading any source file</i>"]
    PRINT --> HASC{"Bounded contract<br/>exists?"}

    HASC -- no --> DRAFT["Draft contract<br/><b>CTR</b><br/>scope · non-scope · done-criteria · budget"]
    DRAFT --> SIGN>"STOP — wait for operator sign-off"]
    SIGN --> ACT

    HASC -- yes --> ACT["Act<br/><b>MAP</b> load only rules the<br/>contract's file scope implicates"]

    ACT --> SIDE{"About to cause<br/>a side effect?"}
    SIDE -- yes --> POL{"On the deny list?<br/><b>POL</b>"}
    POL -- yes --> ASK>"STOP — ask operator"]
    ASK --> ACT
    POL -- no --> DO["Proceed"]
    SIDE -- no --> DO
    DO --> SENSE["Sense<br/><b>SNS</b><br/>lint harness formats, run project checks,<br/>capture output verbatim"]

    SENSE --> LOG1[/"Append run block to log/*.md<br/><b>LDG</b>"/]
    LOG1 --> GATE{"Gate<br/><b>SNS</b>"}

    GATE -- "exit 0 AND rubric >= threshold" --> RECEIPT["Write change receipt<br/><b>LDG</b>"]
    GATE -- "fail AND attempts < budget" --> BUMP["attempt += 1"]
    BUMP --> ACT
    GATE -- "fail AND budget spent" --> ESC["Write escalation note<br/><b>LDG</b><br/>what was tried · what the evidence said"]

    ESC --> HANDOFF
    RECEIPT --> MARK["Mark feature done<br/>with evidence id"]
    MARK --> HANDOFF["Handoff<br/><b>STA</b> write current.md<br/>archive closed contracts"]
    HANDOFF --> END(["Session ends"])

    style GATE fill:#0B5E63,color:#fff,stroke:#0B5E63
    style SIGN fill:#fff3cd,stroke:#8E6512,color:#000
    style ASK fill:#fff3cd,stroke:#8E6512,color:#000
    style ESC fill:#f8d7da,stroke:#9B3A2B,color:#000
```

**The important edge is the one most harnesses skip:** `fail AND budget spent`. Without it,
"retry" is the only failure path and the loop runs until you happen to notice.

---

## 2. Task generation

How a loose goal becomes something an agent can be held to. Two separate steps on purpose —
planning produces many features, a contract binds exactly one. Collapsing them is what lets
a task quietly redefine itself mid-run.

```mermaid
flowchart LR
    GOAL["Loose goal<br/><i>'add offline mode'</i>"] --> PLAN["/hafness-plan<br/><b>CTR</b>"]
    PLAN --> DECOMP["Decompose"]
    DECOMP --> F1["F-012<br/>cache layer"]
    DECOMP --> F2["F-013<br/>sync queue"]
    DECOMP --> F3["F-014<br/>conflict UI"]

    F1 --> JSON[("scope/FEATURES.md<br/>id · title · deps<br/>done-criteria · status")]
    F2 --> JSON
    F3 --> JSON

    JSON --> REVIEW>"STOP — operator reviews the plan"]
    REVIEW --> PICK{"Pick one<br/>with deps met"}
    PICK --> CONTRACT["/hafness-contract F-014<br/><b>CTR</b>"]
    CONTRACT --> C1["in-scope paths"]
    CONTRACT --> C2["out-of-scope paths"]
    CONTRACT --> C3["acceptance evidence"]
    CONTRACT --> C4["attempt budget"]
    C1 --> SIGNOFF>"Operator sign-off"]
    C2 --> SIGNOFF
    C3 --> SIGNOFF
    C4 --> SIGNOFF
    SIGNOFF --> LOOP(["Enter the session loop"])

    style JSON fill:#DCE9E9,stroke:#0B5E63,color:#000
    style REVIEW fill:#fff3cd,stroke:#8E6512,color:#000
    style SIGNOFF fill:#fff3cd,stroke:#8E6512,color:#000
```

Every feature carries a **done-criterion written before the work starts**. A criterion
invented after the fact is just a description of whatever happened.

Two stops, not one. The plan is reviewed as a whole before any feature is picked up, and the
contract is signed off before that feature is worked. `FEATURES.md` is markdown precisely so
the first stop is a real review and not a glance at a JSON blob.

---

## 3. Gate logic

The gate is the single place where "done" is decided, and it is deliberately dumb — it reads
an exit code and a score, not an argument.

```mermaid
flowchart TD
    IN(["verify.sh has run"]) --> EXIT{"exit code"}
    EXIT -- "non-zero" --> FAILED["FAIL"]
    EXIT -- "0" --> PARSE{"HAFNESS_VERIFY<br/>line present?"}
    PARSE -- no --> BROKEN["FAIL — treat a missing<br/>verdict as a failure,<br/>never as a pass"]
    PARSE -- yes --> EVID{"Evidence id<br/>recorded in ledger?"}
    EVID -- no --> BROKEN2["FAIL — a pass nobody<br/>wrote down did not happen"]
    EVID -- yes --> RUBRIC{"Rubric score<br/>>= threshold?"}
    RUBRIC -- no --> QUAL["FAIL — structurally<br/>present, not actually good"]
    RUBRIC -- yes --> PASS["PASS"]

    FAILED --> BUDGET
    BROKEN --> BUDGET
    BROKEN2 --> BUDGET
    QUAL --> BUDGET{"attempts < budget?"}
    BUDGET -- yes --> RETRY(["Retry — agent chooses<br/>how to repair"])
    BUDGET -- no --> ESCALATE(["Escalate to operator"])
    PASS --> DONE(["Receipt + mark done"])

    style PASS fill:#0B5E63,color:#fff,stroke:#0B5E63
    style DONE fill:#0B5E63,color:#fff,stroke:#0B5E63
    style ESCALATE fill:#f8d7da,stroke:#9B3A2B,color:#000
```

Three of the four failure paths exist to close loopholes an agent will otherwise find:
a suppressed exit code, a verdict line that never printed, and work that passes tests
while missing the point.

---

## 4. Failure becomes infrastructure

This is the compounding part. Repairing the output fixes one run; repairing the class
improves every run after it.

```mermaid
flowchart TD
    FAIL(["A run failed<br/>or passed badly"]) --> JOURNAL["/hafness-journal<br/><b>LDG</b><br/>draft the lesson"]
    JOURNAL --> GEN{"Does it<br/>generalize?"}
    GEN -- "one-off" --> NOTE["Note in journal.md<br/>and stop"]
    GEN -- "will recur" --> WHERE{"Where does the<br/>boundary belong?"}

    WHERE -- "a judgement call" --> RULE["rules/*.md<br/><b>MAP</b><br/>prose the agent reads"]
    WHERE -- "a quality bar" --> RUB["rubric.md<br/><b>SNS</b><br/>evaluator scores it"]
    WHERE -- "mechanically checkable" --> CHECK["new check in verify.sh<br/><b>SNS</b><br/>agent cannot bypass"]
    WHERE -- "must never happen" --> DENY["policy.md deny list<br/><b>POL</b><br/>stop-and-ask"]

    RULE --> IGNORED{"Ignored again<br/>later?"}
    IGNORED -- yes --> CHECK
    IGNORED -- no --> KEEP(["Stays as guidance"])

    CHECK --> PERM(["Permanent.<br/>The next agent does not<br/>need to remember the incident"])
    RUB --> PERM
    DENY --> PERM

    style CHECK fill:#0B5E63,color:#fff,stroke:#0B5E63
    style PERM fill:#DCE9E9,stroke:#0B5E63,color:#000
```

The `IGNORED -> CHECK` edge is the rule-promotion path: prose that keeps getting ignored is
evidence that it should have been a script.

---

## 5. Who reads and writes what

The subsystems are separate so that failure is survivable: if the working copy dies the
history survives; if the model changes the policy stays inspectable.

```mermaid
flowchart LR
    subgraph IN["Read at session start"]
        CUR["state/current.md"]
        DEC["state/decisions.md"]
        TAIL["log tail"]
        CON["open contract"]
    end

    subgraph WORK["During the run"]
        MAPF["HAFNESS.md<br/>rules/*.md"]
        POLF["policy.md"]
        VER["verify.sh"]
        RUB["rubric.md"]
    end

    subgraph OUT["Append at session end"]
        JSONL["log/*.md"]
        REC["log/receipts/*.md"]
        JOU["log/journal.md"]
        ARCH["archive/"]
    end

    CUR --> AGENT(("Agent"))
    DEC --> AGENT
    TAIL --> AGENT
    CON --> AGENT
    MAPF -.->|"on demand only"| AGENT
    POLF --> AGENT
    AGENT --> VER
    VER --> RUB
    RUB --> AGENT
    AGENT --> JSONL
    AGENT --> REC
    AGENT --> JOU
    AGENT --> ARCH
    AGENT --> CUR2["state/current.md<br/><i>rewritten</i>"]

    style AGENT fill:#0B5E63,color:#fff,stroke:#0B5E63
```

`rules/*.md` is the only dotted edge: it loads **on demand only**, scoped to the files the
contract touches. That dotted line is the difference between a map and a manual.

---

## 6. A feature's lifecycle

Status transitions in the Status column of `FEATURES.md`. There is no edge from `in-progress` straight to
`done` — the only way in is through `verified`, and the only way to `verified` is a recorded
passing run.

```mermaid
stateDiagram-v2
    [*] --> backlog: /hafness-plan
    backlog --> blocked: dependency unmet
    blocked --> backlog: dependency closes
    backlog --> contracted: /hafness-contract + sign-off
    contracted --> in_progress: session starts work
    in_progress --> in_progress: gate fail, attempts remain
    in_progress --> escalated: budget spent
    escalated --> contracted: operator revises scope or budget
    escalated --> dropped: operator cancels
    in_progress --> verified: gate pass, evidence id recorded
    verified --> done: receipt written
    done --> archived: /hafness-handoff
    archived --> [*]
    dropped --> [*]
```

`escalated` is a real state, not an error. A run that stops and says what it tried is worth
more than one that keeps going.
