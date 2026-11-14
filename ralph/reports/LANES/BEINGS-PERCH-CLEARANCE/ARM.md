# BEINGS-PERCH-CLEARANCE: the companion no longer stands inside a High Perches needle (F40#17)

**Status: CPU-ready, waiting for a GPU slot.**

**Row:** F40#17, High Perches. It scored 6.61 after RIMGLOW (G-land-cs-rimglow).

**Defect, quoted (3/3):** "griffin clipping into the tower wall, with a floating wing piece". LANE-LAND-CS's probe named it as the player's own Galecrest (`AllyCreature`), and the coordinator routed it to this lane.

## Cause, and how it was confirmed
Reproduced on CPU. In `crown-rim-out` the Galecrest is half inside the needle. In `crown-court` only a wing pokes out of the wall; that is the "floating wing piece".

Two probes on those frames, both run as temporary hooks over `phase2_capture_cloudreach_high_perch.gd` and not committed:
- **What the companion stands in.** The companion is at (916.7, 1020.1, 2693.2). Its collision capsule radius is 1.08 m and its rendered footprint radius is 2.28 m (wings). Sphere queries at both radii against static geometry return nothing.
- **What the wall is.** The wall is `HighRoostPerches/RoostNeedle5`, a 16 m needle about 8 m across, with no collider. The only collider there is the ledge floor. The companion's centre is about 3.3 m from the needle's axis, inside its roughly 4 m radius.

The six needles are visual-only on purpose: `cloudreach_world.gd` says "F08#3: the six visual-only needles". So the Cloudreach follow validator (`cloudreach_encounter_director.gd verified_follow_spot` → `_recall_body_fits`) correctly finds the spot clear. Nothing tells it the needle is there.

## Change
New flag `companion_needle_clearance` in `data/config/cloudreach_high_perches_visual.json`, OFF, with `margin_m` 0.3. When it is on:
- `cloudreach_world.gd _build_high_perches`: each needle joins `follower_creature.gd KEEP_CLEAR_GROUP`, with radius = base radius + margin. This is the mechanism the Crossing Hall pedestals use.
- `cloudreach_encounter_director.gd _recall_spot`: a candidate follow or recall spot whose rendered footprint (`footprint_radius`, so the wings count) overlaps a keep-clear zone is skipped.

The needles stay visual-only, so there is no change to collision, traversal, camera, Fly or authority. With the flag off the group is empty in Cloudreach, so nothing changes.

## CPU before and after
`_sheet_r1.jpg` shows crown rim-out and crown court, day and night, base on the left and arm on the right.
- **Base:** the Galecrest is inside the needle in rim-out, and a wing pokes out of the wall in court.
- **Arm:** the Galecrest is out of the needle (out of frame in rim-out), and in court it stands clear beside the trainer with both wings showing.

The other eight frames (arrival far, lip and landed; departure lookback) vary run to run without the flag, because wild creatures wander. Two flag-off runs differ as much as base against arm there, so pair only the crown frames.

## By-eye line for the GPU lane
`high-perches-crown-court-day`: the Galecrest stands on open grass beside the trainer with both wings visible, and no wing piece sticks out of the needle wall. In `crown-rim-out` no griffin overlaps the needle.

## Tests
- `tests/test_beings_perch_clearance_flag.gd` (3 tests, 0 failed).
- `smoke_cloudreach_follower_edge` (16 checks), `smoke_cloudreach_recall_level` (133 checks) and `smoke_cloudreach_companion_fall` (36 checks) are green with the flag both off and on.

## Ownership note
`cloudreach_world.gd` is also edited by LANE-LAND-CS (MASTERFLOOR in `dress_master_site`). This change is one flagged block in `_build_high_perches` plus two constants, and does not overlap theirs.

## Risks
- With the companion out of `crown-rim-out`, the frame loses its creature. A judge may not miss it, since the defect is gone.
