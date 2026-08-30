# T5-PLAY — defects found while playing the chapter

Live log. Each entry says what was observed, where, and what it costs a player
(or, for a RIG entry, what it costs the evidence). Ranked at the end of
`PLAYTHROUGH-2026-08-30.md`, not here.

Severity words follow the Gate F protocol: **BLOCKER** (cannot proceed),
**SHIP** (a player-facing defect that would be reported), **RIG** (the
instrument, not the game).

---

## RIG-T5-1 — every logic-lane run in a fresh run directory refuses at step 0

**Severity:** RIG, BLOCKER-shaped for anyone trying to start a run.

`operator_harness.gd::_freeze_display_claim()` reads two places, nearest first:
the run directory's own `RUN_METADATA.json`, then the global
`ralph/reports/gate-f-candidate/RUN_METADATA.json`. That global record is the
2026-08-27 freeze. It carries a **flat** `"display_server": "X11 under
xvfb-run"` and **no `lanes` block** — so a logic-lane segment run headless is
compared against a claim of X11 and refused by CD-8b:

```
gate-f harness ERROR: capture pre-flight BLOCKER: the freeze record
contradicts this process: the freeze record at
ralph/reports/gate-f-candidate/RUN_METADATA.json says
display_server=X11 under xvfb-run; this process has none
```

Every segment fails this way, in about one second, before a single step runs.
S01 and S02 both did on this lane's first attempt.

**Why it matters beyond this lane.** The refusal is correct behaviour — CD-8b
exists because a run once claimed X11 while producing headless artefacts — but
the *default* is wrong: the nearest freeze record is a stale global one that
contradicts the lane the harness itself calls normal ("the evidence split makes
a run that is headless for its logic lane and X11 for its capture lane the
normal shape"). So the documented, supported way to run is refused unless the
operator already knows to hand-write a per-run freeze record first. Nothing in
`run_segment.sh --help` says so, and `run_segment.sh` does not write one.

**What this lane did:** wrote
`ralph/reports/gate-f-run-T5-PLAY/RUN_METADATA.json` declaring the logic lane
honestly, *before* the run started — which is what the harness's own comment
requires ("a run that wants a logic lane must SAY SO IN THE FREEZE RECORD
BEFORE THE RUN"). Not amended mid-run.

**Suggested fix (not made here, out of scope):** either give the global
candidate record a `lanes` block naming the headless logic lane, or have
`run_segment.sh` write a run-local freeze record from the invocation it is
actually about to make.

---
