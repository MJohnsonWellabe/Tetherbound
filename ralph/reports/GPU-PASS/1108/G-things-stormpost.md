# G-things-stormpost: wild-creature clearance at Stormwood dialogue posts, with dressing (F41#15; GPU High)

## Verdict: SHIP
- **F41#15** rises from 5.13 to **6.97** (+1.84). All three judges prefer the arm, and the row clears the 6 floor.
- **Stormwood ride-along dialogue** (Sera and Tamsin) rises from 5.79 to 6.97 (+1.18). All three judges prefer the arm.
- **The inventory-camera controls** are level (5.60 → 5.60; one judge each way).

## Frames
`tb/gpu-frames-1108` bf3f89a85, High.
- **Capture:** `phase2_capture_dialogue.gd --biome=stormwood --seed=2042 --fixed-fps 20`.
- **Build:** `tb/things` b628efddf on both sides, imported for `stormheart_heartwood_core.gdshader`.
- **Sides:**
  - **base:** `THINGS-STORMPOST/overlay_base.json`, with the three dressing flags off (= main).
  - **arm:** `overlay_arm.json`, which turns on `combat.json arena.wild_post_clearance_1112` and turns the dressing on (warm deck wood, cloth banners, aged heartwood).
- **Frames:** 12 per side: 6 `__dialogue` frames plus 6 inventory controls. Dialogue blend is 1.000 on all frames. 0 script errors and 0 blank frames.
- **Camera rule unchanged:** the conversation clearance camera rule keeps `exclude_realms ["stormwood"]` on both sides. The gain comes from moving the wild creatures, not from the camera.

**GPU lane pre-check, nearest wild creature to the speaker (base → arm):**

| Speaker | Base | Arm |
|---|---|---|
| Nysa | stormraven at 1.6–2.0 m | 16.8 m |
| Sera | tanglevolt at 2.0 m | 26.3 m |
| Tamsin ash ring | stormraven at 2.9–4.1 m | 16.5 m |
| Marrow and stormreader Tamsin | 46–58 m | 46–58 m (unchanged) |

**Render check (mean difference, pixels changed):**

| Set | Mean difference | Pixels changed |
|---|---|---|
| Row | 19.3 | 40% |
| Ride-along | 20.8 | 28% |
| Controls | 3.0 | 6% |

## Batch `G-spo`
- **Judges:** three code-blind judges, standard prompt.
- **Sets:**
  - the F41#15 row, three frames stacked: Marrow, Marrow dynamo_core, Nysa;
  - the ride-along, three frames stacked: Sera, stormreader Tamsin, Tamsin ash ring;
  - the six inventory controls, as a 3×2 grid.
- **Anchors:** craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.4188, intercept −1.9679, r 0.929, RMSE 0.512. No warnings.

## Results

| Set | Base raw → mapped | Arm raw → mapped | Gain | Prefer arm |
|---|---|---|---|---|
| **F41#15 row** | 4.9, 5.0, 5.1 → 5.13 | 6.3, 6.3, 6.3 → **6.97** | **+1.84** | 3/3 |
| **Stormwood dialogue ride-along** | 5.4, 5.4, 5.6 → 5.79 | 6.3, 6.2, 6.4 → **6.97** | **+1.18** | 3/3 |
| Inventory controls | 5.6, 5.0, 5.4 → 5.60 | 5.5, 5.1, 5.4 → 5.60 | 0.00 | 1/3 (1 tie, 1 prefers base by 0.1) |

**Recorded defect** (F41#15, "large foreground creatures ... hide the named speaker"): **FIXED 3/3 on the arm**. On base it was PRESENT 2/3 and PARTIAL 1/3.

**What the judges see:**
- **Nysa, base (3/3):** "two giant blue lightning-spotted birds fill the frame and almost completely hide Officer Nysa".
- **Nysa, arm (3/3):** "Nysa stands clear and centred, with bears and crows staged behind her".
- **Sera, base (3/3):** "a huge purple and white lightning-veined creature fills more than half the frame".
- **Sera, arm (3/3):** "Sera is cleanly framed, with the storm forest and towers behind her".
- **Deck, arm (3/3):** "warm natural wood ... reads much better with the copper and storm palette". Base had "lilac-pink" planks and an "orange trunk".

## What still holds F41#15 and the Stormwood dialogue rows down (3/3, both sides)
1. **The player at the left edge is blown out to white** in every dialogue frame (bloom or overexposure). Marrow's hair also blooms white.
2. **Flat light and grade:** a flat lavender sky and flat-textured trunk walls. The panel cuts the speakers off at the waist.
3. **Inventory controls:**
   - A pink, flesh-toned trunk or root fills the right foreground of two frames (camera in geometry).
   - The grass is a flat carpet.
   - The bears are pink.
   - The NPCs are tiny and pale.

## Recommendation
1. **Land it:** `wild_post_clearance_1112` and the dressing (#15 rises from 5.13 to 6.97, +1.84, 3/3). This supersedes the ride-along verdicts in `G-below6-stormdress.md` and `G-below6-stormdeck.md`.
2. **Next for F41#15, toward 7.5:** clamp bloom on the near player and on character hair. That is the remaining blow-out the judges name first.
