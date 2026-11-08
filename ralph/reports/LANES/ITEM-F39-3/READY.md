STATUS: pending (Tidewake route smokes still running; becomes land when they pass)
BRANCH: tb/item-f39-3  HEAD: see the commit that adds this READY (pushed head)

Lane LANE-MESHY, F39#3 named destination read (idea 3, coordinator 8 Nov): Drowned Garden Terraces.

**Ships ON.** The gain beats the noise floor for this frame type (0.00) and 3 of 3 judges prefer the arm.

## Change (data only)
`data/config/tidewake_destination_read.json`:
- The three loose `wd_terrace_low/mid/high` blocks are replaced by a 9-block stepped planted terrace, `wd_terrace_t{1,2,3}_{l,c,r}`.
- Model: the same installed meshy-1022 `drowned_garden_terrace_wall`.
- Tiers: 2.0, 3.6 and 4.8 m tall. The back tiers' widths are held by `stretch_xz` 0.75 to 0.8.
- Placement: rows run parallel to `drowned_garden_exploration_spine`, with the front face 2.2 m off the spine centreline. The spine's half-width is 2 m, so the trail stays clear.
- Colliders: box `collider_fraction` [0.9, 0.9, 0.8], the same as the landmark walls.
- The note is in `_why_on_f39_3_terraces`.
- No code, terrain, route, spawn or durable-state change.

## Why this lever
- The route_day camera at (1114.3, 2218.4) only sees the destination_read walls.
- Both OFF terrace candidates sit behind or outside this view, so switching them on cannot change the frame:
  - `water_garden_terraces_blockout`, at (1120-1132, 2201-2207).
  - The claude ring at origin (1200, 2240).
- v1 used no height step. The sand falls away behind the crest, so it read as one long wall; it was rejected by eye and not judged.

## Gate and footprint
- Visibility sheet: `_sheet_visibility_v2.jpg`.
- The coordinator approved one round on the drowned_garden route_day frame. The other two F39#3 frames are unchanged.
- Footprint probe: `footprint_probe.txt`, with its script in `footprint_probe.py.txt`. It checks every `data/config` placement against the 9 colliders, with a 1 m margin for points and a 2 m margin for polylines.
- The only overlaps are the three replaced blocks and a grass-only plaza clearing.
- The spine misses every block with 2 m to spare.
- All encounters, the harvest point, lures and NPCs are at least 15 m away.

## Round (`qj/F39-3-stack-v2/`)
- Mapped **6.20 -> 6.84 (+0.64)**. Raw base 4.9 / 5.2 / 5.4, arm 5.5 / 5.9 / 6.0.
- All three judges preferred the arm. The defect went from PRESENT x3 to PARTIAL x3.
- Fit: slope 1.02, r 0.78, RMSE 0.73.
- CPU only. **GPU re-baseline owed** (High first).

## Pre-ready check (merged tree, main cd368f07 merged; main touched no related file)
- `run_tests.gd --only=` every test that greps the touched config or the landmark builder: test_tidewake_look_profile, test_water_landmark_destinations, test_water_landmark_trimesh_collision and test_water_look_model_preload. Result: **17 tests, 287 assertions, 0 failed**.
- test_texture_import_policy and test_creature_model_flags (HELD): **5 tests, 2752 assertions, 0 failed**.
- `smoke_water_garden_records`: 40 checks, 0 failures.
- Tidewake route smokes: see the line below.
- JSON parse: tidewake_destination_read.json OK.

## Judges' remaining asks (all three)
- The kit is still uniform white brick, with no arches, pools or flooded beds, so the place doesn't read as "drowned".
- The foreground is an empty sand plane.
- The hut looks half-buried next to the wall.
- Their top new_art ask: a hero half-flooded stepped terrace with arches and water between the steps.

**Next idea:** standing water between the tiers, using the installed water.gdshader pool the claude ring already uses, plus a darker wet-stone tint on the lower tier. Pull the beach hut 2 m clear of the wall.

## Files
- `data/config/tidewake_destination_read.json`
- `ralph/reports/LANES/ITEM-F39-3/**`
