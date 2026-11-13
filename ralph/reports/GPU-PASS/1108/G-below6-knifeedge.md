# G-below6-knifeedge: stray black strip removed at the Three Bells bridge (F40#8, F40#15; F40#0 road ends no-loss; GPU High)

## Verdict: SHIP. F40#8 gains +0.76 with 3/3 preferring the arm; every other set is level and nothing loses.

| Set | Base | Arm | Gain | Prefer arm | Arm per judge (mapped) |
|---|---|---|---|---|---|
| **F40#8 row** (Three Bells bridge, day, golden, night) | 5.61 | **6.37** | **+0.76** | 3/3 | 6.37, 6.37, 6.37 |
| F40#15 row (overlook walk_03, aerie vista dusk) | 5.77 | 5.77 | 0.00 | identical | 5.89, 5.53, 5.89 |
| Overlook and aerie routes (no-loss) | 5.53 | 5.53 | 0.00 | identical | 5.53, 5.53, 5.53 |
| F40#0 road ends (gate and summit, no-loss) | 6.45 | 6.45 | 0.00 | identical | 6.49, 6.61, 6.25 |

- **What the arm fixes (3/3).** Base has "a long black rail strip cutting diagonally across the grass from the bottom-left to the bridge" in all three times of day, red-brown at golden hour. The arm has none, and no judge sees a new gap or hole.
- **F40#8 clears the 6 floor** (5.61 → 6.37). The +0.76 lets it land on its own.
- **F40#8's recorded defect stays PARTIAL on both sides (3/3).**
  - The marker post beside the trainer is now "pale blue-grey with an orange tip", so it is no longer saturated cyan. But it is "a plain cylinder that competes with the trainer and reads as a placeholder", and it turns flat light cyan at night.
  - No yellow pointer or aerie ring is visible in these frames.
  - The next lever is an authored marker mesh in the aviary family (new art).
- **F40#15: the strips are already gone on base.** All three judges mark its recorded defect FIXED on both sides, and no black strips are visible in walk_03 or the aerie vista. So the row's board score is stale for that defect: the current-main read is 5.77.
  - What holds it now is a "huge flat stone wall slab" filling a third of frame 1, a bare grass bevel at the void with no lip or rocks, and a tiled cloud sea (3/3).
  - The giant cobbles belong to the masonry arm, which comes next.
- **No loss.** The overlook, aerie and road-end sets score the same per judge.

## What still holds the Cloudreach rows (3/3 unless noted)
1. **Flat ground.** Untextured grass planes, hard straight dirt-strip roads, and a dark seam line across the ground at the trainer's feet in the overlook route_day frame (2/3).
2. **Placeholder architecture.** "Floating, untextured stone wall boxes", "flat unshaded blue and yellow banner slabs", a placeholder hanging ring on the arch, and blocky flat-cut cliffs. All three call this new art (aviary-family walls, banners and markers).
3. **Gate road rubble.** "A dense heap of identical grey boulders" the trainer stands inside, which reads as scatter, not a path. The summit dome is the best landmark in the batch.

## Pooled current-main lines
No earlier GPU panel of these rows is on main. This batch's bases are the current-main reads at High: F40#8 5.61, F40#15 5.77, F40#0 road ends 6.45.

## Frames
- **Sources:** `tb/gpu-frames-1108`, High, `tb/below6` e948b35aa on both sides.
  - **base:** no overlay.
  - **arm:** `BELOW6-KNIFEEDGE/overlay.json`.
- **Sections:**
  - `G-below6-knife-bridge` (11de0b4d6)
  - `G-below6-knife-f40-15` (46dee6378)
  - `G-below6-knife-gate` (ad01b8691)
  - `G-below6-knife-summit` (b9b4ca021)
- **Health:** 0 script errors. The f40-15 tool exits 1 with a 7/10 survey because the aerie's walk_01–03 have no production camera stand on either side; that is not the arm.
- **Render check (mean difference per frame):**
  - Bridge 5.5 day, 2.7 golden, 4.0 night.
  - f40-15 frames 0.4–5.3.
  - Gate 0.7–0.9.
  - Summit 2.9–5.6, which is run timing (the HUD clock differs).
  - By eye, the bridge strip is gone on the arm.
- **Sets:**
  - F40#8: the three bridge close frames, stacked.
  - F40#15: overlook walk_03_day and aerie vista_dusk.
  - Routes: overlook walk_01_day, overlook route_day and aerie route_day.
  - F40#0: 2×2 grid of gate approach, gate gameplay, summit approach and summit reverse.

## Batch `G-kn`
- Three code-blind judges, standard prompt, four candidate sets.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.197, intercept −0.448, r 0.917, anchor RMSE 0.55. No warnings.
- Yardstick: `yardstick_g_below6_knifeedge/`.

**Raw Bar A (judges a, b, c):**

| Set | Base | Arm |
|---|---|---|
| F40#8 row | 5.2, 5.0, 5.0 | 5.7, 5.7, 5.7 |
| F40#15 row | 5.3, 5.0, 5.3 | 5.3, 5.0, 5.3 |
| Overlook and aerie routes | 5.0, 5.0, 5.0 | 5.0, 5.0, 5.0 |
| F40#0 road ends | 5.8, 5.9, 5.6 | 5.8, 5.9, 5.6 |

Bar B: no on every candidate set (3/3).
