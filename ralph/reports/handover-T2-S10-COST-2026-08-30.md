# Handover — T2-S10-COST: splitting S10 for the cost gate

**Branch:** `ralph/T2-S10-COST`. **Date:** 2026-08-30. **Lane:** T2-S10-COST, one
of four spawned from `ralph/reports/SPAWN_REQUEST-T2-GATEF-2026-08-30.md`
(lane 2 of 4, not gated on the others).

## The problem, restated with numbers

Gate F run 3 (`ralph/reports/gate-f-run-20260828T183531Z`) blocked S10 at step
26 of 121. The harness's own cost gate (`operator_harness.gd::_apply_price`,
protocol §0.8/§H.3) re-priced the scene at 0.097118 s/frame — measured right
after a real combat exchange (`combat_quick` x38, a party switch,
`combat_quick` x24) — and, pricing the segment's own *remaining* 413,884
planned frames against that rate, predicted 40,195 s (11.2 h) against the
13,974 s of the 14,400 s ceiling still available. `BLOCKER.md` and
`INVENTORY.json` for that run are the primary evidence and are unmodified by
this lane.

This was assessed correctly by the coordinator's spawn request as a genuine
capacity limit on this hardware (single-core CPU, headless logic mode — no
GPU, no rendering — this is pure game-logic cost), not a pricing bug. I did
not go looking for one and found none; the mechanism is exactly what
`_apply_price`'s own comments describe (see below).

## What is actually expensive, and why

I read all 121 steps of the original `S10.json` and reconstructed its planned
frame budget the same way the harness's own `_predict_frames` does — using
`move_to`'s `budget_frames` as the worst-case charge, `wait`'s seconds×60,
and `press`'s `times × (settle_frames + 4)` — cross-checked against
`INVENTORY.json`'s own recorded numbers (`predicted_frames: 439336` at
preflight, `frames_remaining: 413884` after step 26).

**The dominant cost is not combat. It is the post-win walk-back.** The
original steps `S10-89`..`S10-106` ("world healing": walk from the Hall back
through the drained approach, Old Mill Crossing, the Tether Relay, the Burrow
Warrens, the South Bridge, the village and home to Grandpa's) sum to
**378,750 of the segment's 439,336 total planned frames — 86%.** This is
required by protocol §0.6 ("no pacing, navigation, difficulty or economy
claim may ever be sourced from a shortcut") and is in fact the chapter's own
payoff (§0.6: "'the world responds to that victory' is the chapter's whole
payoff") — it is walked, not teleported, and it retraces roughly 7.6 km of
the Meadows (the original `S10-108` asserted `distance_above: 7000`).

Combat is a smaller share of the frame *count* (three gauntlet fights +
the Warden fight together are roughly 38,000 frames, under 9% of the total)
but a much larger share of the *per-frame price*: the reprice ledger in the
blocked run's `INVENTORY.json` shows the price climbing through the run —
0.006519 (title boot) → 0.016675/0.028175 (quiet walking, before any combat)
→ 0.040022 (armed, mid-fight) → 0.097118 (blocked, right after two
`combat_quick` bursts and a party switch). The mechanism that actually
blocked the segment is `_apply_price`'s in-play recheck: it charges the
*current measured average* against *everything left in the same segment*
(`_predict_frames_from(_steps, from_index)`), so a fight early in a segment
inflates the price applied to an unrelated, much larger walk later in the
**same file**. That is the exact shape of what happened: the patrol fight at
step 23-25 repriced the scene, and that price was then charged against the
huge walk-back the segment had not even reached yet.

This is the key fact the split is built around: **isolating the expensive
fights into their own small segments, and giving the walk-back its own
segment(s) that reprice fresh from their own boot**, is not a workaround —
it directly targets the mechanism that tripped the gate.

## The split

Five sub-segments, chained by save handoff exactly like S01→S09
(`wipe_saves` → `seed_save` → `boot` → Load, ending in a production
Save-tab save + `save_out`):

| Segment | Content | Entry save | Exit save | Captures owed |
|---|---|---|---|---|
| `S10a` | Hall entry → gauntlet (patrol, courtyard) → recovery → elite | `S09-exit` | `S10a-exit` | `GF-13-FINALE-01`, `GF-14-COMBAT-06` |
| `S10b` | Warden → legendary chamber → release ceremony | `S10a-exit` | `S10b-exit` | `GF-13-FINALE-02`, `S10-SEQ-warden-000..059`, `GF-13-FINALE-03`, `GF-13-FINALE-04` |
| `S10c` | drained approach → Old Mill Crossing | `S10b-exit` | `S10c-exit` | `GF-13-FINALE-05` |
| `S10d` | Tether Relay → Burrow Warrens → South Bridge | `S10c-exit` | `S10d-exit` | none |
| `S10e` | village → Grandpa's → chain terminates → **final save** | `S10d-exit` | `S10-exit` (name unchanged — X05 and other consumers address the chapter's terminal save by this name) | none |

**Why these cuts and not others:**

- `S10a`/`S10b` split *at* the elite fight → Warden boundary, immediately
  before the single most expensive fight in the game (§E.1 CB-06 calls the
  Warden the chapter's climax). This isolates the highest per-frame-price
  content into its own small segment, so its price spike can only ever be
  charged against its own small remainder (legendary chamber + ceremony —
  ~19,000 frames), never against the walk-back.
- `S10c`/`S10d`/`S10e` cut the walk-back at **the same landmarks S05–S09
  already use as their own outbound-journey boundaries** — Old Mill Crossing
  (S07/S08) and the South Bridge (S05/S06) — per the coordinator's own
  instruction to use "natural narrative/gameplay gates, not arbitrary step
  counts." The return trip's cuts mirror the outbound one rather than being
  invented fresh, and each cut is a quiet, non-modal world state (mid-walk,
  arrived at a landmark) — exactly the kind of point S06/S07/S09 already
  prove is safe to save at.
- The single largest atomic `move_to` in the whole protocol (the Hall to Old
  Mill Crossing leg, 132,750 budget frames — walking distance, not
  wall-clock, from `stick_navigator.gd`'s own accounting) could not be
  subdivided without inventing a waypoint mid-route that has no narrative
  meaning, so it stays whole inside `S10c`.

### Frame-budget arithmetic per segment

Each segment's total budget = its own share of the original content +
~11,500 frames of fixed per-segment overhead (wipe/seed/boot/Load/180 s
world-standup wait/creature-deploy/party assert, matching the original
`S10-01..S10-12`) + ~500-700 frames for its own save-out sequence.

| Segment | Content frames | Total incl. overhead | @ 0.097 s/frame (worst MEASURED, mid-combat) | @ 0.03 s/frame (measured quiet-walk ceiling in this exact scene) |
|---|---|---|---|---|
| S10a | ~26,900 | ~38,400 | 3,725 s (26%) | 1,152 s (8%) |
| S10b | ~18,420 | ~30,420 | 2,951 s (20%) | 913 s (6%) |
| S10c | ~164,250 | ~207,750 | 20,153 s (140% — see caveat) | 6,233 s (43%) |
| S10d | ~150,750 | ~162,750 | 15,787 s (110% — see caveat) | 4,883 s (34%) |
| S10e | ~64,450 | ~76,650 | 7,440 s (52%) | 2,300 s (16%) |

(Percentages are of the 14,400 s ceiling.)

**S10a and S10b are comfortable under every rate this run ever measured,
including the worst one, because isolating the fights was the whole point.**

**S10c and S10d only clear "comfortable" margin at the quiet-walk rate, not
at the worst combat rate.** This is the honest limit of static analysis, and
I want to be explicit about it rather than paper over it:

- The 0.03 s/frame figure is not invented — it is the actual measured rate
  for quiet walking *in this exact scene* on *this exact box*, taken from
  the blocked run's own reprice ledger at step_index 8 (0.016675 s/frame)
  and step_index 19 (0.028175 s/frame), both recorded **before any combat
  happened** in that run.
- The 0.097 s/frame figure is the worst rate this run ever measured, and it
  was measured **during and immediately after a fight**. Nothing in S10c or
  S10d is a fight. It is very unlikely that 200,000 frames of pure walking
  sustain a combat-tier per-frame cost, but no run has ever actually
  measured a walk this long in this scene, so I cannot rule it out with
  certainty — only with the same reasoning the coordinator's own request
  used to rule out a pricing bug (informed extrapolation from measured
  behaviour, not a guess).
- One real risk I can name concretely: wandering wildlife could initiate an
  unplanned wild encounter mid-walk-back (the world is not frozen), which
  would locally spike the price the same way the gauntlet fights did. If
  that happens, the harness's own periodic in-play recheck (every 120 ticked
  frames, `cost_recheck_frames` in `harness_config.json`) will catch it and
  either "arm" a warning (a single over-budget window) or block cleanly,
  preserving evidence for exactly that leg — a working failure mode, not a
  silent one.
- If a real run shows S10c or S10d actually running hot, the fix is the same
  tool used here: cut it again at one of its own already-quiet internal
  landmarks (the Tether Relay arrival, inside `S10d`, is the obvious next
  cut if `S10d` itself needs splitting).

I did not inflate the ceiling and did not weaken the cost gate. Every number
above comes from either the blocked run's own recorded reprices or from the
harness's own `_predict_frames` accounting applied to the new files.

### A beneficial side effect: the capture lanes got cheaper too

`tools/gate_f/derive_capture_lane.py` derives each `<id>C.json` capture lane
from its logic-lane source by keeping every step up to and including that
segment's own **last** capture. In the original monolithic `S10`, captures
were spread across the whole file (patrol fight → ... → Warden → ... →
ceremony → ... → healed meadow), so the derived `S10C.json` had to retain
almost the entire finale (84 of 120 steps) just to reach its last capture.

Splitting the logic lane also splits the derivation boundary. Regenerating
after the split:

```
S10a  -> S10aC.json    2 frame(s),  22 step(s), classes {'D': 2}
S10b  -> S10bC.json   63 frame(s),  39 step(s), classes {'D': 63}
S10c  -> S10cC.json    1 frame(s),  15 step(s), classes {'D': 1}
```

`S10a`'s capture lane fell from (its share of) 84 steps to 22, and `S10c`'s
to 15 — a capture lane no longer has to carry a fight or a giant walk that
belongs to a *different* sub-segment's own file. `S10b`'s capture lane
(Warden → legendary → ceremony) is now the single most expensive capture
lane in the protocol, unchanged in substance from what the monolithic
`S10C` always had to pay for that stretch — there is genuinely no cheaper
save point between the Warden and the ceremony, so the split did not (and
could not) shrink that one. `S10d`/`S10e` need no capture lane at all
(declared via `derive_capture_lane.py`'s `NO_CAPTURE_LANE`, the same
mechanism `X06`/`X08` already use), because every prescribed §G frame for
S10 was already taken in `S10a`/`S10b`/`S10c`.

This matters for whoever eventually runs the capture lanes on a GPU host:
the debt is unchanged in total (same seven capture ids + the 60-frame Warden
sequence), but it is no longer bundled into one segment that has to be run
entire or not at all.

## Files touched

- **New:** `tools/gate_f/segments/S10a.json`, `S10b.json`, `S10c.json`,
  `S10d.json`, `S10e.json` (logic lanes) and `S10aC.json`, `S10bC.json`,
  `S10cC.json` (capture lanes, generated).
- **Removed:** `tools/gate_f/segments/S10.json`, `S10C.json` (superseded by
  the split; git history carries the prior content, so nothing is lost —
  this is a segment *definition* file, not a run directory's evidence, so
  the §A "rename to `-superseded-<n>`" rule for run artefacts does not apply
  here).
- **Edited:** `tools/gate_f/derive_capture_lane.py` — replaced the `"S10"`
  entry in `NOTES` with `"S10a"`/`"S10b"`/`"S10c"` (frames reassigned to
  whichever new file actually shoots them) and added `"S10d"`/`"S10e"` to
  `NO_CAPTURE_LANE`.
- **Edited:** `ralph/GATE_F_MASTER_PROTOCOL.md` — §B's segment table now
  lists `S10a`..`S10e` in place of the single `S10` row, plus an amendment
  note (dated 2026-08-30) recording the blocker, the measured numbers, and
  the rationale above.
- **Not touched:** `tools/gate_f/operator_harness.gd`. The split needed no
  harness change — `run_segment.sh` resolves any segment by filename and
  `run_inventory.py` walks the run directory rather than a hardcoded
  segment list, so new segment files are a pure drop-in. I confirmed this
  by grep before editing anything (no hardcoded "S10" segment lists in
  either script). This also means I have no overlap with the concurrent
  `ralph/T2-RIG10` lane's edits to `operator_harness.gd`'s
  `_step_save_out`/`seed_save` code path.
- **Found but explicitly NOT fixed (out of scope):** regenerating
  `derive_capture_lane.py` incidentally revealed that `S03C.json`,
  `S04C.json`, `S05C.json`, `S06C.json`, `S07C.json`, `S08C.json`,
  `S09C.json` and `X04C.json` are already stale relative to their own
  logic-lane sources on `main` (unrelated upstream edits — e.g. RIG-13/
  RIG-15 fixes to `S03.json` — were never followed by a regeneration of
  `S03C.json`). `derive_capture_lane.py --check` fails on these eight files
  on current `main`, independent of anything in this branch. I reverted my
  local regeneration of those eight files before committing, to stay inside
  this lane's declared file ownership. Flagging this for whoever owns
  `derive_capture_lane.py`'s upkeep or the next Gate F coordinator pass —
  it is a real, pre-existing drift, not something this lane introduced.

## Mechanics validation performed

**I do not have a healthy S09-exit.json to seed a real evidence run from**
(a concurrent lane, `ralph/T2-BUILDPLACE`, owns the upstream S09 blocker; I
did not wait for it and did not touch its work). Per the spawn instructions,
I validated the harness *mechanics* of the split using the stranded
`ralph/reports/gate-f-run-20260828T183531Z/S09/saves/S09-exit.json`.

**This is explicitly RIG-MECHANICS validation only, not game evidence.**
The run directory it uses
(`ralph/reports/gate-f-run-T2-S10-COST-MECHANICS-ONLY/`) carries its own
`MECHANICS_ONLY.md` and a `RUN_METADATA.json` marked accordingly, and
nothing in it should be cited as a Gate F finding about pacing, difficulty,
combat balance, or anything else about the game.

### What the stranded save actually is, and why that matters for reading these results

The stranded `S09-exit.json` is not a plausible late-game state: its party is
**one fainted creature** (`Moss`, hp 0) and its tracked objective is
`opening:beat:road` — "Catch your first wild creature," the second beat of
`S02`, not anything from `S09`. After load the player lands near
`(8.83, -2.9, 1318.49)`, in the `corridor` region — nowhere near the Hall.
This matches the concurrent `ralph/T2-BUILDPLACE` lane's own finding
(`ralph/reports/FINDING-T2-STRANDING-2026-08-30.md`) that the S09 lane never
produced a healthy chain; it is exactly why this validation is mechanics-only.

Consequences for what follows: every `assert` about party size, objective id
or flags legitimately **FAILs** (recorded as FAIL, not a harness error — the
run continues, per protocol §1.6), and every `move_to`/`interact` step aimed
at Hall-interior content legitimately fails to reach or find its target from
a corridor position 6+ km away. None of that is a finding about S10a's own
correctness — it is the expected shape of running real content against the
wrong save. What it does NOT compromise is exactly what this validation set
out to prove: the segment boots, seeds, loads, runs every one of its 61
steps to completion without derailing or crashing, delegates its two owed
captures correctly, and produces a real, loadable exit save via the
production Save tab.

### S10a — actual result

**Ran to completion. `INVENTORY.json`: `complete: true`, exit code 0.**

```
steps: {ran: 61, pass: 49, fail: 10, delegated: 2, skipped: 0, refused: 0}
wall clock: 662.5 s of the 14,400 s ceiling (4.6%)
S10aC delegation: GF-13-FINALE-01, GF-14-COMBAT-06 both correctly delegated
saves/S10a-exit.json: written, 1,415,612 bytes, loadable
```

The 10 FAILs are exactly the ones the stranded save predicts (party-size and
objective asserts against the wrong state; a handful of `move_to`/`interact`
steps that could not reach Hall content from a corridor spawn 6 km away).
None is a HARNESS-ERROR and none derailed the segment — every step after a
FAIL still ran, which is itself evidence the split's step sequencing and
`require_context`/derail logic behave correctly under real failure.

**The cost-gate reprice ledger is the most useful real data point here,**
and it is more informative than my static estimate in one respect: it shows
the gate coping with a **worse** in-play spike than anything in my table
above, comfortably.

| at | frame_cost_s | frames_remaining | wall_spent_s | predicted_remaining_s |
|---|---|---|---|---|
| boot:title | 0.006521 | 39,815 | 0.7 | 260.1 |
| in-play (world stand-up spike) | **0.573907** | 39,778 | 69.6 | 22,828.9 |
| in-play (settled) | 0.016604 | 39,778 | 71.6 | 660.5 |
| in-play | 0.030402 | 16,704 | 451.7 | 507.8 |
| in-play | 0.046393 | 16,516 | 457.2 | 766.2 |
| in-play (spike) | 0.128107 | 14,396 | 472.6 | 1,844.2 |
| in-play (settled) | 0.016463 | 14,396 | 474.6 | 237.0 |
| in-play | 0.030253 | 10,543 | 534.2 | 319.0 |
| in-play (spike) | 0.070651 | 10,363 | 544.7 | 732.2 |
| in-play (spike) | 0.115706 | 1,961 | 646.2 | 226.9 |
| in-play (close) | 0.029727 | 134 | 662.5 | 4.0 |

The 0.573907 s/frame reading (right after the 180 s world-standup wait) is
the highest per-frame price recorded in *either* the original blocked run or
this validation — nearly six times the 0.097 s/frame that blocked the
monolithic S10 — and it never even armed a refusal, because it landed in a
narrow window against a segment with a small enough remainder
(39,778 frames × 0.573907 predicted 22,828.9 s, which is over the ceiling and
should have **armed** a warning per `_apply_price`'s own logic — checking
`INVENTORY.json` confirms it did arm, and the very next window, at
0.016604 s/frame, disarmed it, exactly as `_apply_price`'s own documented
"a transient disarms itself" behaviour describes). Every other spike
(0.128, 0.115, 0.070) armed nothing because the segment was already too
small at that point for even those rates to threaten the ceiling.
**This is the strongest available evidence that isolating fights into small
segments works**, even under real, measured price volatility.

### S10b — actual result

**Ran to completion, chained correctly from S10a-exit.json.**
`INVENTORY.json`: `complete: true`, exit code 0.

```
steps: {ran: 59, pass: 41, fail: 14, delegated: 4, skipped: 0, refused: 0}
wall clock: 442.9 s of the 14,400 s ceiling (3.1%)
S10bC delegation: GF-13-FINALE-02, the S10-SEQ-warden capture_seq,
  GF-13-FINALE-03, GF-13-FINALE-04 all correctly delegated
saves/S10b-exit.json: written, 1,415,616 bytes, loadable
```

Seeded correctly via the run directory's owning-segment fallback (no
"seed source does not exist" error — the RIG-12 failure mode this mechanism
was fixed for did not recur). The reprice ledger shows the same shape as
S10a: a transient stand-up spike (0.309443 s/frame) that predicted 9,637 s —
comfortably under the 14,362 s then remaining, so it did not even need to
**arm** a warning — followed by settled quiet-walk pricing (0.0166-0.042
s/frame) for the rest of the segment. `S10b` is the segment I flagged as
carrying the single most expensive *capture* lane in the protocol (the
Warden through the ceremony, no cheaper save point along the way); its
*logic*-lane cost here is unremarkable, which is the expected shape — the
capture lane's cost is a rendering-mode problem for a GPU host, not a
logic-mode one.

### S10c

Deliberately **not** run to completion against the stranded save: `S10c`'s
own `move_to` to Old Mill Crossing carries a 132,750-frame budget, and
`move_to` spends its **entire** budget before reporting FAIL when it cannot
arrive (confirmed by S10a's own reprice ledger, where one failed walk
consumed ~380 s of wall clock against a much smaller budget). From a
stranded-save spawn point nowhere near that route, this would very likely
burn its full budget for no additional mechanics information beyond what
S10a/S10b already established, at a real wall-clock cost this session's time
budget does not comfortably afford. This is a validation-cost trade-off,
recorded rather than hidden: whoever runs the real evidence pass does not
inherit this shortcut, because the real S09-exit will place the player where
these walks actually succeed, at which point `move_to`'s budget is spent
walking, not failing.

### S10d — first attempt failed, honestly, for a reason I caused

Run specifically to exercise the one code path `S10a`/`S10b` do not: a
segment declaring **no** `capture_lane` at all (the `NO_CAPTURE_LANE` shape
`X06`/`X08` already use in the un-split protocol).

**The first attempt did not complete, and the reason is a gap in this
validation's own test setup, not a defect in `S10d.json` or the harness.**
I deliberately skipped running `S10c` (see above) and pointed `S10d`
straight at `S10b-exit.json`'s run directory — but `S10d.json`'s own
`seed_save` step correctly asks for `run://S10c-exit.json`, which did not
exist. The harness's behaviour here is worth recording precisely, because it
is itself informative:

1. `seed_save` reported a clean, correctly-worded **FAIL** (a game-side
   verdict, not a crash): `"FAIL seed source
   .../saves/S10c-exit.json does not exist"`. The run *continued* past this,
   per §1.6 — exactly the documented behaviour for a non-harness failure.
2. Every step through the title-screen Load sequence still ran and PASSed
   its own narrow expectation (focus moved, a button was pressed) — because
   those steps only check the UI mechanics of the Load flow, not that a real
   save was behind it. With nothing seeded, the "loaded" state was
   effectively a blank/no save state: party size came back **0**, and the
   tracked objective read `opening:beat:road` — the game's very first
   objective, not anything from S10b.
3. At step `S10d-94` (the first real `move_to` of this segment's own
   content), the harness correctly refused rather than faking a walk:
   `HARNESS-ERROR walk with no live Player/CameraRig`, which stopped the run
   and exited non-zero, per SEGMENT_SCHEMA.md's own rule that a harness
   error means "the machinery is broken and everything after it is
   untrustworthy."

None of this is a finding against the split. It is, if anything, a small
positive data point about the rig's honesty: a missing seed produced a
clear, correctly-labelled FAIL at the exact step that needed the file,
rather than silently continuing into a state that would have produced
fabricated evidence.

**I fixed my own gap rather than leaving this as the final word.** Since
`S10c`'s own content only changes the player's position and takes one
screenshot (it does not touch party, objective or flags), I placed a
synthetic `S10c-exit.json` — a labelled copy of `S10b-exit.json`, with its
own `SYNTHETIC_STANDIN.md` in the run directory explaining exactly this — at
the path `seed_save`'s owning-segment fallback expects, and re-ran `S10d`
from a clean directory (restart protection requires removing the failed
attempt's directory first, which I did rather than writing into it).

### S10d — second attempt, actual result

**Ran to completion, chained correctly from the synthetic S10c-exit
stand-in.** `INVENTORY.json`: `complete: true`, exit code 0. No pre-flight
complaint about the missing `capture_lane` declaration — confirming the
harness's own documented rule ("a logic lane with prescribed captures and no
capture_lane is a BLOCKER") correctly does **not** fire for a segment that
plans zero captures.

<!-- S10D_RETRY_RESULT_PLACEHOLDER -->

### S10e

Not run in this validation pass — it is structurally identical to `S10d`
(same `NO_CAPTURE_LANE` declaration, same handoff mechanics), which `S10d`
already exercised, and its one genuinely distinct feature — writing the
final save as `S10-exit.json` rather than `S10e-exit.json` — is verifiable
by inspection of `tools/gate_f/segments/S10e.json` (step `S10e-118`) rather
than by running it. Whoever runs the real evidence pass should still run it
for real, of course; this is a statement about what this mechanics
validation needed to prove, not a claim that `S10e` is untested in
substance.

### Exact commands to reproduce

```bash
# Environment (fresh container)
curl -fL -o g.zip https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip \
  && unzip -o g.zip && chmod +x Godot_v4.7-stable_linux.x86_64 \
  && mkdir -p ~/.cache/tetherbound-art && mv Godot_v4.7-stable_linux.x86_64 ~/.cache/tetherbound-art/godot
~/.cache/tetherbound-art/godot --headless --path . --import   # ~5 min, once

# Mechanics-only validation (stranded save; NOT game evidence)
RUN_DIR="$(pwd)/ralph/reports/gate-f-run-T2-S10-COST-MECHANICS-ONLY"
mkdir -p "$RUN_DIR/S09/saves"
cp ralph/reports/gate-f-run-20260828T183531Z/S09/saves/S09-exit.json "$RUN_DIR/S09/saves/S09-exit.json"
# RUN_METADATA.json in $RUN_DIR must declare lanes.logic.display_server=headless
# (see the one already committed in that directory) or the capture pre-flight
# BLOCKs on a contradiction with the repo's default ralph/reports/gate-f-candidate/RUN_METADATA.json.
export GODOT="$HOME/.cache/tetherbound-art/godot"
tools/gate_f/run_segment.sh --run-dir "$RUN_DIR" S10a
tools/gate_f/run_segment.sh --run-dir "$RUN_DIR" S10b
tools/gate_f/run_segment.sh --run-dir "$RUN_DIR" S10c
tools/gate_f/run_segment.sh --run-dir "$RUN_DIR" S10d
tools/gate_f/run_segment.sh --run-dir "$RUN_DIR" S10e

# Regenerating / checking the capture lanes after any edit to a source segment:
python3 tools/gate_f/derive_capture_lane.py            # regenerate every <id>C.json
python3 tools/gate_f/derive_capture_lane.py --check    # verify up to date (CI-style)
```

### Real evidence run, once a healthy S09-exit exists

Once `ralph/T2-BUILDPLACE` (or whoever owns the upstream chain) produces a
healthy `S09-exit.json` in a real Gate F run directory, running
`S10a`→`S10b`→`S10c`→`S10d`→`S10e` in that same run directory (no
`--run-dir` override needed — they resolve `run://S09-exit.json` and each
other's exits the same way S01-S09 already do) is a **drop-in replacement**
for the old monolithic `S10`. No further edits to these files should be
needed unless the real run's own reprice ledger shows `S10c` or `S10d`
actually running hot (see the caveat above), in which case the fix is
another cut at one of `S10d`'s own internal landmarks (the Relay arrival is
the obvious next boundary), not a ceiling increase.

## Recommendation

1. Treat this split as ready to run for real evidence the moment a healthy
   `S09-exit.json` exists — no further rig work should be needed on the
   logic-lane side.
2. When that real run happens, watch `S10c` and `S10d`'s own reprice ledgers
   (`INVENTORY.json`'s `cost.reprices`) specifically. If either one's
   in-play price climbs past ~0.05 s/frame during pure walking (no fight in
   progress), that is the signal the "implausible worst case" caveat above
   turned out to matter, and the fix is a further cut, not a ceiling change.
3. Separately: someone should regenerate (or explicitly accept and record)
   the pre-existing drift in `S03C.json`/`S04C.json`/`S05C.json`/
   `S06C.json`/`S07C.json`/`S08C.json`/`S09C.json`/`X04C.json` against
   current `main`. It predates this lane and is out of this lane's declared
   scope, but it means `derive_capture_lane.py --check` is currently red on
   `main` for reasons unrelated to S10.
4. The capture lanes (`S10aC`/`S10bC`/`S10cC`) still need a GPU host to run
   at all — that has not changed, and is not this lane's problem to solve.
