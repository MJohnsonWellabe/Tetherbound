# F38#0 / F26#3 Meadows matrix on GPU: High and Medium (24 Oct 2026)

**Verdict: the F38#0 matrix evidence is DELIVERED; F26#3 (Meadows) is REOPENED.**
- **Frames:**
  - High: **354 / 528** planned, 174 stands rejected by the tool.
  - Medium: **355 / 528**, 173 rejected.
  - Both presets are over the 200-frame requirement.
- **Scores:** no site maps to 7.5 at either preset.
  - Best: **village_road 6.73 High / 7.09 Medium** and **band3 river lock 1, 6.89 / 6.86**.
  - Worst: the `arch_*` stands, **3.5–5.3**. Most of their frames have the production camera inside or pressed against geometry.
- **High vs Medium:** the two presets scored the same, or within 0.4, on every site.

## Tier

Tiers follow the owner's direction of 24 Oct. Each site takes the lower of its two preset scores.

| Tier | Sites |
|---|---|
| **below 6** (18) | ironwood_1 5.97, arch_home, stone_and_root_1, hall_front, stronghold_0, farm_to_hall, fight 5.34, shrine_room, river_lock_0, arch_biome8, arch_stormwood, hall_nave, arch_tidewake, stronghold_1, arch_cloudreach, arch_biome5, arch_biome7, arch_biome6 3.53 |
| **6–7** (4) | village_road 6.73, band3_the_river_lock_1 6.86, band1_lower_meadows_1 6.32, band4_upper_meadows_ironwood_0 6.20 |
| 7–7.5 | none |
| 7.5 and above | none |

## Run

- **Source:** main 779422f10 (#729 included).
- **Capture:** `tools/capture_f38_matrix.gd --seed=2042 --f38-preset=<High|Medium>` with no baseline/candidate flag. On main the catalog presentation ships enabled, so that is the shipping state.
  - 22 sites × 3 times × 2 weathers × 4 views, at 1920x1080.
  - Forward+ on a GTX 1060, with an isolated APPDATA per preset.
  - Queue: `f38_queue.ps1.txt`.
- **Rejected stands:** the tool's own rule rejects a stand with "no supported production-camera stand among 1 candidates". Those rows are kept as missing evidence (`manifest_summary_*.json`).
  - band2_stone_and_root_0 has **no frames**.
  - village_road, hall_front, shrine_room, arch_home and band4_ironwood_1 have **6 frames each**.
- **Fight:** `tools/capture_f38_fight.gd --trainer=south_bridge_grunt,warden_aldis --frames=32 --interval=0.5 --attack --dodge --tell-frames`, at High (84 frames) and Medium (85 frames).

## Yardstick

- **Sets:** one per site, High vs Medium on the same up-to-6 frame ids (day/golden/night clear, rain, approach/gameplay/reverse/detail; `coverage.json` lists each site's frames), plus the fight at High vs Medium. That makes 22 sets in 5 batches.
- **Anchors:** each batch has its own `anchor_tiles.py --pairs 4 --include f36_0_npc:C1`.
- **Judges:** three fresh code-blind judges per batch, each given `JUDGE_PROMPT.md` (main) verbatim. Each also saved its own JSON block to the judge folder; one judge read an image's pixel size with a single shell call inside its folder.
- **Recorded defects:** the four F38#5 generic defects (magenta slabs, placeholder materials, floating bodies, clipping). Exterior sites also carry the world-visible catalog items P2-014 and P2-005, with P2-003 at the stronghold and P2-006 at the river lock and village. The fight carries P2-062, P2-063, P2-064 and P2-016.

| Batch | Slope | Intercept | r | Anchor RMSE | Confirming | Warnings |
|---|---|---|---|---|---|---|
| b1 | 0.809 | 2.236 | 0.93 | 0.36 | yes | arch sets extrapolated below the anchors' range |
| b2 | 0.925 | 1.751 | 0.91 | 0.52 | yes | – |
| b3 | 0.857 | 1.945 | 0.88 | 0.58 | yes | – |
| b4 | 1.086 | 0.388 | 0.91 | 0.49 | yes | – |
| b5 | 0.905 | 1.692 | 0.92 | 0.37 | yes | – |

## Per site (mapped Bar A; PASS needs 7.5 or more on both presets with the defects gone)

Defect columns give the majority state across the three judges and both presets.

| Site | High | Medium | Verdict | Magenta | Placeholder | Floating | Clipping | Catalog items |
|---|---|---|---|---|---|---|---|---|
| village_road | 6.73 | **7.09** | FAIL | FIXED | FIXED | FIXED | FIXED | P2-014 FIXED, P2-005 PARTIAL, P2-006 PARTIAL |
| band3_the_river_lock_1 | 6.89 | 6.86 | FAIL | FIXED | PARTIAL | FIXED | FIXED | P2-014 FIXED, P2-005 PARTIAL, P2-006 PARTIAL |
| band1_lower_meadows_1 | 6.32 | 6.32 | FAIL | FIXED | FIXED | FIXED | FIXED | P2-014 PARTIAL, P2-005 PARTIAL |
| band4_upper_meadows_ironwood_0 | 6.29 | 6.20 | FAIL | FIXED | PARTIAL | FIXED | FIXED | P2-014 FIXED, P2-005 PARTIAL |
| band4_upper_meadows_ironwood_1 | 5.97 | 6.12 | FAIL | FIXED | PARTIAL | FIXED | FIXED | P2-014 FIXED, P2-005 PARTIAL |
| arch_home | 5.85 | 5.85 | FAIL | FIXED | FIXED | FIXED | PARTIAL | – |
| band2_stone_and_root_1 | 5.82 | 5.82 | FAIL | FIXED | PARTIAL | FIXED | FIXED | **P2-014 PRESENT, P2-005 PRESENT** |
| hall_front | 5.82 | 5.82 | FAIL | FIXED | FIXED | PARTIAL | FIXED | – |
| band5_stronghold_approach_0 | 5.66 | 5.63 | FAIL | FIXED | PARTIAL | FIXED | FIXED | **P2-003 PRESENT, P2-005 PRESENT** |
| farm_to_hall | 5.60 | 5.60 | FAIL | FIXED | PARTIAL | FIXED | PARTIAL | P2-005 PARTIAL |
| fight (grunt + Warden) | 5.34 | 5.55 | FAIL | PARTIAL | – | – | – | P2-062 PARTIAL, P2-063 PARTIAL, P2-064 PARTIAL, **P2-016 PRESENT** |
| shrine_room | 5.53 | 5.53 | FAIL | FIXED | PARTIAL | FIXED | FIXED | – |
| band3_the_river_lock_0 | 5.29 | 5.29 | FAIL | FIXED | **PRESENT** | FIXED | **PRESENT** | **P2-005 PRESENT, P2-006 PRESENT** |
| arch_biome8 | 5.26 | 5.26 | FAIL | FIXED | PARTIAL | FIXED | **PRESENT** | – |
| arch_stormwood | 4.87 | 4.87 | FAIL | FIXED | PARTIAL | FIXED | PARTIAL | – |
| hall_nave | 4.77 | 4.77 | FAIL | FIXED | **PRESENT** | FIXED | **PRESENT** | – |
| arch_tidewake | 4.62 | 4.62 | FAIL | FIXED | PARTIAL | FIXED | **PRESENT** | – |
| band5_stronghold_approach_1 | 4.59 | 4.59 | FAIL | FIXED | PARTIAL | PARTIAL | PARTIAL | P2-003 PARTIAL, P2-005 PARTIAL |
| arch_cloudreach | 4.29 | 4.29 | FAIL | FIXED | **PRESENT** | FIXED | **PRESENT** | – |
| arch_biome5 | 4.15 | 4.15 | FAIL | FIXED | **PRESENT** | FIXED | **PRESENT** | – |
| arch_biome7 | 3.99 | 3.99 | FAIL | FIXED | PARTIAL | FIXED | **PRESENT** | – |
| arch_biome6 | 3.53 | 3.53 | FAIL | FIXED | PARTIAL | FIXED | **PRESENT** | – |
| band2_stone_and_root_0 | – | – | no frames | | | | | stand rejected at both presets |

## F38#5 defect scan: what the lanes should fix first

1. **Production cameras at the arch stands and two interiors.** Clipping is PRESENT at 8 sites:
   - arch_biome5/6/7/8, arch_cloudreach, arch_tidewake, hall_nave and river_lock_0.
   - The reverse views are black (camera inside rock or walls), approach views press against rock or blank plaster walls, and fight camera frames clip foliage.
   - This is the largest single source of low scores, and it is a camera/stand problem rather than an art one.
2. **The Hall's white light-shaft quads and orb chains** (hall_nave, hall_front, shrine_room, arch_home, arch_stormwood interiors).
   - The same Forward+ additive shafts as F17#6, plus floating orb chains.
   - Placeholder is PRESENT at hall_nave, and the shafts cut across the trainer.
   - Interior grades also barely change between day, golden and night.
3. **P2-005 ground carpet:** PRESENT or PARTIAL at every exterior site (10/10). Judges ask for groves, edges, clearings, clustered flowers and ground-material variation.
4. **P2-003 stronghold:** PRESENT at band5_0. The base is a dark speck behind the pylons; band5_1 is near-black with giant flat banners.
5. **River lock 0:** flat beige ground, hex-slab blockout in the reverse view, and P2-006 flat water PRESENT.
6. **P2-014 mountains:** mostly FIXED (8/10). Still PRESENT at band2_stone_and_root_1, where faceted cliff planes have dark slashes.
7. **Fight:**
   - the magenta telegraphs are now pale outlines (PARTIAL);
   - the HUD covers the bottom third;
   - the ally crowds the opponent (P2-062 PARTIAL);
   - hurt poses keep the idle silhouette (P2-016 PRESENT).

## Path to 7.5 (judge of record's advice)

**Sources:**
- the three judges' per-set notes and their batch `top_changes` (in `yardstick/b*/j*.json`);
- my own review of the frames.

**Gap:** how far each site's best preset is below 7.5.

High and Medium score the same, so none of this is a quality-preset problem. Every fix below is content: cameras, dressing, lighting or art. **Kind:**
- *scene* means placement, config, grade or camera work with existing assets;
- *new_art* means a new mesh or material.

### Levers that move many sites at once

| # | Fix | Kind | Sites it unblocks |
|---|---|---|---|
| L1 | **Re-seat the production cameras.** No camera inside or against rock, walls or foliage. Every view frames the landmark with sky and distance, not a blank wall or bare slope. | scene | all 8 `arch_*` stands, hall_nave, river_lock_0, the fight (trunk/canopy fade) |
| L2 | **Replace the opaque white light-shaft quads and orb chains** with soft volumetric or fog-card shafts, or remove them. | scene | hall_nave, hall_front, shrine_room, arch_home, arch_stormwood, arch_biome7/8, arch_cloudreach |
| L3 | **Interior time-of-day grade.** Night darker and cooler than day, rain distinct. Today night renders as bright as day, or brighter. | scene | farm_to_hall, hall_front, shrine_room, arch_home, hall_nave |
| L4 | **Break the grass carpet (P2-005)** into groves, edges and clearings, with clustered wildflowers, path wear and dirt/moss/rock ground variation. | scene | all 10 exterior sites |
| L5 | **Aerial depth.** Fog, cool blue distance and layered hills, plus golden-hour shafts and a readable moonlit night. | scene | all exterior sites, especially band1, ironwood_0/1, village_road, river_lock_1 |
| L6 | **The plaster "window-strip" walls at the arch stands** need textured facades and real window light, not blank walls with blown emissive slabs. | new_art | arch_cloudreach, arch_tidewake, arch_biome5 |

### Per site

| Site | Best | Gap | What gets it to 7.5 |
|---|---|---|---|
| village_road | 7.09 M | 0.41 | **Closest of all.** Put villagers, chimney smoke and lit life on the empty road. Fix the night-rain grade, which reads as grey overcast day. Add blue distance fog. Break up the uniform verges (L4, L5). |
| band3_the_river_lock_1 | 6.89 H | 0.61 | Give the water a surface, banks and reeds instead of a flat blue band (P2-006). Vary the tree silhouettes away from a single uniform wall. Add atmosphere to the sky and grade (L5). Cluster the evenly scattered flowers. |
| band1_lower_meadows_1 | 6.32 | 1.18 | Fill the empty flat-green distance with layered hills and haze (L5). Turn the carpet into groves and clusters (L4). Add props. Brighten the dim night and rain grades. |
| band4_upper_meadows_ironwood_0 | 6.29 H | 1.21 | Replace the faceted, blobby canopies with real leaf-card canopies (new_art). Give the flat tree-line horizon sky variation and haze (L5). Add a landmark or settlement glimpse. Lift the murky night grade. |
| band4_upper_meadows_ironwood_1 | 6.12 M | 1.38 | Add sun shafts and depth fog in the grove. Open sky glimpses. Lift the value range, since night goes almost black. Fix the faceted leaf chunks. Keep the trainer readable above the grass. |
| arch_home | 5.85 | 1.65 | Remove the light-shaft slabs across the pillars (L2). Give a real interior day/golden/night difference (L3). Add at least one exterior view. |
| band2_stone_and_root_1 | 5.82 | 1.68 | Replace the faceted cliff planes with dark slashes (P2-014 PRESENT) with sculpted, stratified rock (new_art). Remove the hard white vertical beam. Apply L4. |
| hall_front | 5.82 | 1.68 | Remove the floating white orb chain (L2). Give the grade a real time-of-day and weather shift (L3). |
| band5_stronghold_approach_0 | 5.66 H | 1.84 | **P2-003:** a hero stronghold that dominates the skyline, with walls, gate and towers, instead of a dark speck behind the pylons (new_art). Add depth layering to the empty plain (L4, L5). |
| farm_to_hall | 5.60 | 1.90 | Five of its six frames are one orange-washed interior. Grade it per time and weather (L3). Fix the smeared wood-grain ceiling texture. Its one exterior frame is already close. |
| fight (grunt + Warden) | 5.55 M | 1.95 | Slim the HUD and move it off the bottom third. Frame or scale the ally so it never covers the opponent (P2-062). Replace the outline and flash-disc telegraphs with grounded effects: dust, stone, sparks (P2-063/064). Add distinct hurt poses (P2-016). Add foliage fade on the fight camera (L1). |
| shrine_room | 5.53 | 1.97 | Remove the white slabs in the doorway (L2). At night it renders paler than day, so fix the grade (L3). |
| band3_the_river_lock_0 | 5.29 | 2.21 | Replace the flat beige ground and hex-slab blockout in the reverse view with textured banks and terrain. Give the water a surface (P2-006). Move the gameplay camera off the arch wall (L1). Unify the props, which read as separate asset packs. |
| arch_biome8 | 5.26 | 2.24 | Its approach views are already decent. The black reverse view (L1), the foliage-choked camera and the white door emissives (L2) sink it. |
| arch_stormwood | 4.87 | 2.63 | Frame a landmark, not a bare grass bank or blank wall (L1). Remove the white shafts in the interior reverse view (L2). |
| hall_nave | 4.77 | 2.73 | **A strong nave sunk by one defect:** large white quads slash across a third of the frame and over the trainer (L2, placeholder PRESENT). The reverse view clips (L1). Grade it per time (L3). |
| arch_tidewake | 4.62 | 2.88 | The reverse camera is inside rock (L1). The flat wall with stamped windows needs a facade (L6). |
| band5_stronghold_approach_1 | 4.59 | 2.91 | It is near-black: open the value range and show sky. Scale down the giant flat banners. Make the fortified mass read (new_art, the same stronghold as band5_0). Break up the dark-green ground (L4). |
| arch_cloudreach | 4.29 | 3.21 | A blank plaster wall in every frame (L6). The reverse camera is jammed against a pillar (L1). The white slabs need fixing (L2). Night reads like day. |
| arch_biome5 | 4.15 | 3.35 | A doorless box on a lawn (L6), with the reverse camera inside geometry (L1). |
| arch_biome7 | 3.99 | 3.51 | Three of its six frames are black reverse views (L1). The courtyard needs sky and the white doorway slabs removed (L2). |
| arch_biome6 | 3.53 | 3.97 | Five of its six frames are the camera inside rock or black (L1). It likely clears 5 from L1 alone, then needs L4 and L5. |

**Suggested order for the lanes:**
1. L1 and L2 first. They are scene-only and lift the 13 lowest sites the most.
2. Then village_road and river_lock_1, the two sites within 0.6 of the bar.
3. Then L4 and L5 across the exteriors.
4. Then the new_art items: the stronghold, the arch facades, the cliffs and the canopies.

## Files

- `_sheet_f38_gpu_main.png`: Medium, from best to worst: village_road golden, river_lock_1 day, stone_and_root_1, hall_nave gameplay with the white quads, arch_biome6 with the camera in rock (152 KB).
- `site_table.json`, `coverage.json`, `manifest_summary_High.json`, `manifest_summary_Medium.json`.
- `yardstick/b1`–`b5`:
  - `key.json`, `sets.md`, `candidates.json`, `recorded_defects.txt`, `judge_prompt_filled.txt`;
  - `j1`–`j3` (the judges' own blocks);
  - `batch.json`, `mapped.json`.
- `f38_queue.ps1.txt`, `build_yard_f38.ps1.txt`.
- Per-frame captures stay local.
