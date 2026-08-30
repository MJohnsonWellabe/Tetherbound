# T5-PLAY → GATE-F-RUN7: what I changed under `tools/gate_f/` before the boundary

**Written for GATE-F-RUN7 and the coordinator, 2026-08-30 14:27Z.**

The coordinator's boundary — *"from now on `tools/gate_f/**` belongs to
GATE-F-RUN7"* — arrived at 14:27Z. **I have stopped.** But I had already made
changes there between 11:20Z and 14:10Z, in the course of getting a run to move
at all, and one of them is in the file we share. This is the "precisely what and
why" the directive asks for, filed retroactively for the edits that predate it.

**Take, adapt or discard any of it. None of it is defended.** Where it collides
with yours, yours wins — I am not going to re-touch these files.

---

## 1. `operator_harness.gd` — the shared file. ONE change: CD-7d.

**This is the collision risk. Read it first.**

Three hunks, all inside the cost-gate machinery, nothing else touched:

| where | change |
|---|---|
| state block (~line 291) | added `COST_SAMPLE_WINDOW = 9`, `COST_SAMPLES_BEFORE_REFUSAL = 3`, `var _cost_samples: Array[float]` |
| `_cost_recheck()` | pushes each window's `observed` into that ring; calls `_apply_price` with `_cost_median()` instead of `observed`; new `_cost_median()` helper below it |
| `_apply_price()` | new optional 7th arg `observed_raw`, recorded as `observed_window_s` + `samples` in the ledger row; refusal now also requires ≥3 samples (`too_few_samples`) |

**Why.** `_apply_price` predicts `remaining_frames × now` from a single
120-frame window. S03 was refused at **step 136 of 406** predicting **5.7 h**
from a window that priced 0.2027 s/frame. Its own `route.csv` — which carries
play *and* wall time per row — puts the sustained rate at **0.0167 s/frame,
wall/play ratio 1.0**, flat across the segment. True remaining cost ≈ **29
minutes**. The gate was wrong by ~12×.

CD-7c's arm-then-confirm did not catch it: a one-off spanning *more* than 120
frames (a fight staging, an arena build) reads high in two consecutive windows
and the second confirms the first.

**If you want the finding without my patch**, the reproduction is free and needs
no code: read any segment's `telemetry/route.csv`, take `wall` minus `play`
between successive rows, and compare against
`INVENTORY.json::preflight.measured_frame_cost_s_in_scene`. On this candidate
they disagree by an order of magnitude, and route.csv is the one telling the
truth.

**What I deliberately did NOT do:** raise `segment_cost_ceiling_s`. Raising a
ceiling to get past a gate that is misreading is how a real regression gets
hidden later. The raw window price is still written to the ledger for the same
reason.

---

## 2. `segments/S02.json` — two stale anchors. Please keep these, or re-derive them.

Both are integration drift from `ralph/T5-OPENING` (`7da75ac7`) landing beside
`ralph/T2-GATEF-RUN6` in `LAND-0830I`. **Without both fixes the chapter cannot
leave band 0**, because `road_gate.gd` builds a `StaticBody3D` with sealed wings
— a closed gate is a hard block, and `road_gate_open` propagates unset through
every downstream exit save.

| step | was | now | source of truth |
|---|---|---|---|
| `S02-49` | `[31.2, -8.4]` | `[30.7, -15.9]` | `playground_world.gd::GATE_KEY_AT` |
| `S02-51` | `[27.5, -16.0]` | `[38.7, -19.9]`, `close_enough` 3.0→2.0 | `data/config/village_boundary.json`, RoadGate entry |

`S02-51`'s old value was `playground_world.gd::GATE_AT`, which T5-OPENING turned
into **dead code** — still declared, places nothing, and its neighbouring comment
still describes a geometry that no longer exists.

I also added **`S02-50a`**, an assert that `pickup:castle_gate_key` is set right
after the pickup press. A `press` step passes when input is *injected*, not when
anything received it, so without it the failure surfaced five steps later at
`S02-54` looking like a gate defect — which it is not. If you keep one thing from
this file, keep that assert; it is the class T5-FEEL named.

**Proved, not argued:** `tools/gate_f/diag/probe_road_gate.gd` (new, item 3)
stands the player 2.9 m out with the key and gets `arbiter.activate()=true`,
`road_gate_open=true`, key consumed. **The gate itself is fine.**

---

## 3. New files — additive, nothing of yours changed

| file | what it is |
|---|---|
| `run_chain.sh` | plays S01→S10e into ONE run dir so each exit save seeds the next; stops if a segment writes no exit save rather than running the next against stale state |
| `chain_pacing.py` | play vs wall clock, dead-travel peaks (movement-filtered), encounter cadence, per-segment verdicts from `INVENTORY.json` |
| `chain_defects.py` | every FAIL from `notes/`, grouped by failure shape so one defect at nine anchors is one line |
| `chain_party.py` | roster history across the exit saves — the A2/A8 evidence |
| `diag/probe_road_gate.gd` | the gate probe above |

`run_chain.sh` exists because the handoff is only a chain if every segment writes
into the same `GATE_F_RUN_DIR`, and six attempts ran segments one at a time.

---

## 4. One thing I hit that is not mine to fix, and is not in any of the above

**The global freeze record refuses every fresh logic-lane run.**
`_freeze_display_claim()` falls back to
`ralph/reports/gate-f-candidate/RUN_METADATA.json`, which carries a flat
`"display_server": "X11 under xvfb-run"` and **no `lanes` block**. Every headless
segment is CD-8b-refused about one second in, before step 1. S01 and S02 both
died that way on my first attempt.

The refusal is correct; the *default* is wrong. Nothing in `run_segment.sh --help`
says a per-run freeze record is required, and the script does not write one.
Worked around here by hand-writing
`ralph/reports/gate-f-run-T5-PLAY/RUN_METADATA.json` before the run — which is
what the harness's own comment demands ("a run that wants a logic lane must SAY
SO IN THE FREEZE RECORD BEFORE THE RUN"). **Routing this to you rather than
patching it**: either give the global record a `lanes` block, or have
`run_segment.sh` write a run-local one from the invocation it is about to make.
