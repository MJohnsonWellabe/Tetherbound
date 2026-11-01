# Tidewake beach scenes r1 (arm s2) vs main: CPU verdict

- **When:** 31 Oct 2026, about 4:45 PM CT.
- **Branch:** `tb/tidewake-look`. Code and assets at `18dc30e6`+, scene data at the s2 commit ("focal pieces closer to the spot, approach-foreground clearings").
- **Renderer:** CPU (Mesa llvmpipe), Compatibility, 1280x720, `phase2_capture_locations.gd --biome=water --times=day --views=approach,close --seed=2042` on the 22 non-Veilfall location stands.
- **Arms:**
  - Main: no new sections.
  - Arm: `--tidewake-look-sections=beach_scene_candidate,beach_declutter_candidate`.

## What the arm changes

- **`beach_scene_candidate`:** one Meshy 1031 focal piece per named location (beach hut, beach bar, fishing shack, market stall, lookout tower, canoe rack).
  - Each sits about 6 m past the spot, beside the route line.
  - Each has a box collider and a `grass_clear` disc.
  - Model-less clearings clean the sand at the spot and in front of the approach stand.
- **`beach_declutter_candidate`:** the inhabited-dock hamlets.
  - The mixed cottages are replaced by two Meshy beach huts.
  - About 25 props cut to 4: shelter, net rack, lit torch, lobster pots.
  - The pier deck keeps its bollards, one crate stack and the lantern.

## Judging

- **Batch:** three fresh code-blind judges.
  - Standard `JUDGE_PROMPT.md`.
  - `anchor_tiles.py --pairs 3 --include craft --include f36_0_npc:C1 --seed 3107`.
  - One set per island: a 2x2 of its two sites, approach and close.
- **Recorded defects:** "Cluttered scenes: scattered props, pebbles and grass tufts compete for attention"; "Named location reads as a generic slope with no clear focal building or landmark".
- **Fit:** linear, slope 0.981, intercept 1.043, r 0.856, anchor RMSE 0.51. Confirming batch (top anchor 7.53). No warnings.

## Results (mapped CPU Bar A, mean of three)

| Island | Main | Arm | Delta |
|---|---|---|---|
| gull_rest | 5.29 | 6.17 | **+0.88** |
| salt_crown | 5.03 | 5.78 | **+0.75** |
| tidal_cradle | 5.16 | 5.81 | **+0.65** |
| drowned_garden | 5.55 | 6.11 | **+0.56** |
| lantern_cove | 5.49 | 6.01 | **+0.52** |
| first_shore | 5.59 | 6.08 | +0.49 |
| deep_watch | 5.39 | 5.78 | +0.39 |
| sluice_isle | 5.42 | 5.81 | +0.39 |
| reedhaven | 6.14 | 6.44 | +0.30 |
| brine_steps | 6.27 | 6.40 | +0.13 |
| shellwatch | 6.11 | 5.95 | -0.16 |
| **All 11** | **5.59** | **6.03** | **+0.45** |

- The arm is higher on 10 of 11 islands, and every judge scored it higher on those 10.
- **The "named location" defect:** PRESENT on main moves to PARTIAL on the arm at almost every island.
- **The "cluttered" defect:** mostly unchanged in the judges' calls. They read the bare dunes and even grass as the problem, not props.

## GPU request

The six islands gull_rest, salt_crown, tidal_cradle, drowned_garden, lantern_cove and first_shore average +0.64. These go to the GPU as arm **TW-look-1** (`tb/tidewake-1-on`); see `ralph/reports/GPU-PASS/NOTE.md`.

## What the judges still name (round-2 inputs)

1. **Lone huts on slopes:** single huts perch on dune slopes with no path, dock or cluster.
   - Fixes: seat them on flat ground; make small 2-3 piece groups, for example a hut, a canoe rack and nets.
2. **Bare sand:**
   - Flat mid-tone sand with no value variation.
   - Even grass carpets on the main side, or none at all.
   - Ask: grass grouped into dune-edge clumps, driftwood and rock groups.
3. **Scene problems outside this lane's scope:**
   - Shellwatch: the dock pump station crowds the close view. That is a dock action station and stays.
   - Deep Watch: an untextured dark dune wall.
   - Shallow-water ring banding.
   - Flat sky with no haze. That is the lighting lane's.

Frames are not committed (repo-size rule). `_sheet_r1.jpg` shows four winning islands, main (left) against the arm (right).
