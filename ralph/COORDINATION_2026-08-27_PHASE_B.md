# Coordination — 2026-08-27 — Gate F Phase B opened

Owner decision, 2026-08-27: run Phase B **now**, on the evidence that exists,
rather than waiting for X02–X06/X08. ("Option A".)

## State at the decision

Gate F's evidence lives on **`ralph/GATE-F-RUN-20260827`**, unmerged to `main`.
Candidate `f082bdf6265760ca9835e1065361fbbf87475d69`.

| lane | state |
|---|---|
| S01–S10 journey | **COMPLETE** — 839 PASS / 202 FAIL (80.6%), every segment handed off, no §A blocker |
| X01 controller/menu matrix | 1085 / 118 over 975 probes (87.9% of cells behave) |
| X07 world/regional audit | 79 of 80 frames, colour-verified clean, stopped as a **cost** blocker (~31 h remaining) |
| X02–X06, X08 | **not run** |

## Why a separate session, and why not the operator's

`GATE_F_PROTOCOL.md` §Model roles makes reviewer/operator separation
**mandatory**, and §14 forbids giving the reviewer developer excuses or proposed
fixes before its first judgment. The operator session
(`session_01RG7KvPNBDWN9NCU4JqqJRX`, idle not archived) carries three days of
step-script post-mortems; reusing it would poison exactly the blindness §16.2
exists to protect. Opus performs the role formerly assigned to Fable — the role
is defined by isolation and inputs, not by model.

**Session `session_01RCwDiUFpDaHFATN5o9oEGc`**, branch `ralph/GATE-F-PHASE-B`,
seeded from `ralph/GATE-F-RUN-20260827`. Quarantined until §16.2 is discharged:
the lane log, both Gate F handovers, the historical snapshot, `BACKLOG.md`,
`DONE.md`, `BLOCKED.md`, `ACTIVE_TASKS.md`, `ASSESSMENT_2026-08-23.md`, the owner
playtests, and the three older run directories. Segment `notes/` are allowed —
§14 names operator notes as an input.

## The gate placed on every backlog item

**Adjudicate game defect vs. harness artifact before writing the item.** This run
has already produced three high-confidence "game defects" that were withdrawn on
measurement: the catch step-script killing the creature it was meant to weaken
(~35 failures), the StarterPicker focus theory (a step-script targeting the house
origin 3.3 m below the loft), and the Start/drop collision theory (whose fix
passed both with and without the patch). The three findings that dominate the run
— input ownership never handed back, no fight ever staging, the South Bridge
never opening — are all shaped like that trap, so each is adjudicated on evidence
before it becomes a task.

## Two constraints carried into Phase B

**No chapter-time projection exists from this run.** Only S05 produced usable §D
pacing evidence. S06–S10's 115 km is retry churn inside a pocket — 95% of S10's
rows sit within 40 m of the bridge line. Nothing may be inferred against the 3–4 h
D42 target from elapsed wall clock.

**X07's ~9,416 ms/frame is not a game performance number.** llvmpipe, no GPU,
762,058 props. Device frame rate stays [OWNER-ONLY].

## What is NOT closed by this

X02–X06 and X08 never ran. Items those segments would have exercised are a
**coverage gap**, not a clean bill of health, and Phase B is instructed to label
them as such rather than count them NOT REPRODUCED. Whether to resume the
operator lane for them in parallel is the next coordination call; note that X02
(build), X03 (catching) and X04 (combat) seed from journey saves that cannot
supply a party of 5 or an opened crossing, so some of that scope may be
unrunnable until the blockers above are resolved.
