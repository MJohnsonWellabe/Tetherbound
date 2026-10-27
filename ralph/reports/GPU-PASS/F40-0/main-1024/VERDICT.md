# F40#0 Cloudreach matrix on GPU: High and Medium, the Cloudreach baseline (24 Oct 2026)

**Verdict:** the F40#0 matrix evidence is DELIVERED. **No stand maps to 7.5 at either preset: all 11 judged stands FAIL.**

- **Coverage:** **328 of 384 frames at each preset.**
  - The 56 missing frames are views the game refused to teleport to (`Game.debug_teleport_to refused destination`, fail closed).
  - broken_skyroad_arch has no frames at all; the other 11 stands each have 24 or 32.
- **Best:** **galefoot_waycamp 6.60.**
- **Worst:** **stormward_overlook 4.60** and **old_wind_observatory 4.74**.
- **High vs Medium:** the two presets score the same on every stand; the largest gap is 0.09 at the_high_perches. Every fix below is content, not a quality preset.
- **Fight:** the F40 fight is still capturing. It will be added to this folder as `fight/`.

## Tier

Tiers follow the owner's direction of 24 Oct, using the lower of the two preset scores.

| Tier | Stands |
|---|---|
| **below 6** (11) | summit_eyrie 5.62, three_bells_bridge 5.54, the_high_perches 5.43, realm_gate_crag 5.26, sky_shrine 5.20, windscar_beacon 5.08, cliffhold 5.02, windscar_flight_aerie 4.91, old_wind_observatory 4.74, stormward_overlook 4.60, fight 4.45 (`fight/`) |
| **6–7** (1) | galefoot_waycamp 6.60 |
| 7–7.5 / 7.5 and above | none |

## Run

- **Source:** main 24dfec7b9, the shipping state. The manifests show the F40 preview candidates off and `cliffhold_detail_candidate` on, with revision `f40-sanctuary-and-route-masses-r1`.
- **Capture:** `tools/capture_cloudreach_f40_matrix.gd --biome=cloudreach --preset=<High|Medium> --source-commit=24dfec7b9… --piece=1-48 | 49-96`.
  - The plan is 12 stands × 4 views × 4 times (dawn, day, golden, night) × 2 weathers, at 1920x1080.
  - Forward+ on a GTX 1060, with an isolated APPDATA per preset.
- **Medium crash:** the Medium run for pieces 1–48 crashed (`0xC000001D`, illegal instruction) after stand 02. I re-ran pieces 17–48, which completed. The backtrace has no symbols. It did not recur, so I'm treating it as a one-off.
- **Missing views:**
  - **broken_skyroad_arch (stand 04):** all 32 views refused, so it has no frames.
  - **three_bells_bridge, galefoot_waycamp and windscar_flight_aerie:** all 8 approach views refused at each.
  - **Wild sites off their authored positions, left out (fail closed):** two of them. `windscar_floor_loop_15` is 98 units off; `broken_causeway_main_03` is 62 units off.
  - Details are in `coverage.json` and `manifest_summary_*.json`.

## Yardstick

- **Sets:** one per stand, High vs Medium on the same up-to-6 frame ids, in 3 batches.
  - Frame preference: day/golden/night clear approach, day rain gameplay, reverse and detail. `site_table.json` and `yardstick/b*/candidates.json` list the frames.
- **Anchors:** `anchor_tiles.py --pairs 4 --include f36_0_npc:C1` per batch.
- **Judges:** three fresh code-blind judges per batch, each given `JUDGE_PROMPT.md` verbatim.
- **Recorded defects:**
  - the four F38#5 generic defects (magenta, placeholder, floating, clipping);
  - **P2-021** and **P2-023** on every stand;
  - stand-specific catalog items: P2-022 summit, P2-024 beacon / observatory / aerie, P2-025 shrine / perches, P2-049 overlook / aerie, P2-053 bridge / aerie, P2-102 perches.

| Batch | Slope | Intercept | r | Anchor RMSE | Confirming | Warnings |
|---|---|---|---|---|---|---|
| b1 | 0.914 | 1.669 | 0.84 | 0.66 | yes | none |
| b2 | 0.953 | 1.238 | 0.94 | 0.43 | yes | none |
| b3 | 0.839 | 2.112 | 0.86 | 0.61 | yes | none |

## Per stand (mapped Bar A; PASS needs 7.5 or more at both presets with the defects gone)

**Mag** = flat magenta slabs. **Place** = placeholder materials. Defect states are the majority across the three judges and both presets; ties go to the worse state.

| Stand | High | Medium | Verdict | Mag | Place | Floating | Clipping | Catalog items |
|---|---|---|---|---|---|---|---|---|
| galefoot_waycamp | **6.60** | **6.60** | FAIL | FIXED | FIXED | FIXED | PARTIAL | P2-021 PARTIAL, P2-023 PARTIAL |
| summit_eyrie | 5.62 | 5.62 | FAIL | FIXED | PARTIAL | FIXED | FIXED | P2-021 PRESENT, P2-023 PRESENT, **P2-022 PARTIAL** |
| three_bells_bridge | 5.54 | 5.54 | FAIL | **PARTIAL** | PARTIAL | FIXED | FIXED | P2-021 PRESENT, P2-023 PRESENT, **P2-053 PRESENT** |
| the_high_perches | 5.52 | 5.43 | FAIL | FIXED | FIXED | PARTIAL | PARTIAL | P2-021 PARTIAL, P2-023 PARTIAL, **P2-025 PRESENT**, P2-102 PARTIAL |
| realm_gate_crag | 5.26 | 5.26 | FAIL | FIXED | PARTIAL | FIXED | FIXED | P2-021 PRESENT, P2-023 PRESENT |
| sky_shrine | 5.20 | 5.20 | FAIL | FIXED | PARTIAL | FIXED | FIXED | P2-021 PRESENT, P2-023 PRESENT, **P2-025 PRESENT** |
| windscar_beacon | 5.08 | 5.08 | FAIL | FIXED | PARTIAL | FIXED | FIXED | P2-021 PRESENT, P2-023 PRESENT, **P2-024 PRESENT** |
| cliffhold | 5.02 | 5.02 | FAIL | FIXED | **PRESENT** | FIXED | **PRESENT** | P2-021 PARTIAL, P2-023 PARTIAL |
| windscar_flight_aerie | 4.91 | 4.91 | FAIL | FIXED | PARTIAL | FIXED | FIXED | P2-021 PRESENT, P2-023 PRESENT, **P2-024 PRESENT**, P2-053 PARTIAL, P2-049 FIXED |
| old_wind_observatory | 4.74 | 4.74 | FAIL | FIXED | PARTIAL | PRESENT (tie) | PARTIAL | P2-021 PRESENT, P2-023 PARTIAL, **P2-024 PRESENT** |
| stormward_overlook | 4.60 | 4.60 | FAIL | FIXED | **PRESENT** | **PRESENT** | FIXED | P2-021 PRESENT, P2-023 PRESENT, **P2-049 PRESENT** |
| broken_skyroad_arch | – | – | no frames | | | | | all 32 views refused at both presets |

## F40#5 defect scan: catalog items on GPU

| Item | State | Where |
|---|---|---|
| **P2-021** open terrain (grass fields lead the route) | **PRESENT** at 8 of 11 stands, PARTIAL at 3 (galefoot, perches, cliffhold) | Every judge's first top change, in all three batches |
| **P2-023** blunt island undersides, straight extruded edges | **PRESENT** at 7, PARTIAL at 4 | Especially realm_gate_crag's overhang slab and the reverse-view cliffs |
| P2-022 summit aviary | PARTIAL | The rotunda's windows are now lit at night, but it still sits small at the end of a dirt track on a lawn |
| P2-024 weak landmark detail | **PRESENT** at all 3 stands (beacon, observatory, aerie) | A lone wooden arch; trunks hide the observatory; the aerie is an empty slope |
| P2-025 grass through paving | **PRESENT** (shrine, perches) | Grass grows through the compass-ring plaza |
| P2-049 dark strips | **PRESENT** at stormward_overlook, FIXED at the aerie | |
| P2-053 cyan markers | **PRESENT** at three_bells_bridge, PARTIAL at the aerie | A saturated cyan T-post in the reverse view |
| P2-102 mushroom past the rim | PARTIAL | The judges could not confirm whether its stem is supported at sheet size |
| P2-106, P2-033 | not judged | Neither the terrace edge clouds nor ground pickups are in these production views |

**New defects, not in the catalog:**
- **Cliffhold approach camera.** All three approach frames (day, golden, night) put the camera on a blank, untextured brown wall: clipping and placeholder are both PRESENT. Its gameplay and reverse views hold the best architecture in Cloudreach.
- **High Perches tutorial text.** Large italic world-space text ("…footing. Follow the path →") is clipped at the right edge of the reverse frames.
- **Stormward Overlook hedge cubes.** Dark mossy hedge cubes float beside the bannered arch.
- **Three Bells Bridge magenta glow.** A magenta glow sits at the left frame edge (magenta PARTIAL). This is the bright violet flare I also see at the perches.
- **Old Wind Observatory cameras.** Every view is boxed in by trunks and a pillar. Tilted orange plank props, with blue strips and a cyan post on the grass.

## Path to 7.5 (judge of record's advice)

**Sources:**
- the judges' notes and top changes (`yardstick/b*/j*.json`);
- my own review of the High frames.

**The core finding:** these production cameras do not show Cloudreach as a sky realm. The trainer stands on a flat grass lawn, and the floating land, the void and the cloud sea appear only in the distance or in reverse views.

### Shared fixes that move many stands

| # | Fix | Kind | Stands |
|---|---|---|---|
| C1 | **Break the lawns into layered land.** Pale stratified stone tiers, ledges and drops at the route edge, so the cloud sea and floating islands are in frame. P2-021 is every judge's first top change, in all three batches. | scene (terrain and placement), then new_art for tier meshes | all 11 |
| C2 | **Sculpt the island undersides and cliff shelves.** Tapering, organic rock instead of blunt slabs and straight extruded strata (P2-023). | new_art | all 11, especially realm_gate_crag, summit, beacon, aerie |
| C3 | **Re-seat the production cameras.** Move cliffhold's approach camera off the wall. Move the observatory and perches cameras off the trunks. Frame each landmark with sky. | scene | cliffhold, old_wind_observatory, the_high_perches |
| C4 | **Hero landmarks at the Sky Aviary board's level** for the three weak destinations: a beacon spire instead of a lone wooden arch; a visible observatory; an aerie perch with launch structure. | new_art | windscar_beacon, old_wind_observatory, windscar_flight_aerie |
| C5 | **Clean-up.** Remove the overlook's floating hedge cubes and dark strips. Clear grass from the shrine and perch paving. Keep the perches' world text inside the frame. Tone the cyan bridge post into the palette. Remove the magenta edge glow. | scene | stormward_overlook, sky_shrine, the_high_perches, three_bells_bridge |
| C6 | **Aerial haze and cloud layers between the islands.** Cloudreach's time-of-day grades already read; night is legible and blue, unlike Meadows. Distance haze is what's missing. | scene | all |

### Per stand

| Stand | Gap | What gets it to 7.5 |
|---|---|---|
| galefoot_waycamp | 0.90 | Closest. The cottages, stratified rock and lantern-lit night already work. Add a floating-land vista beyond the village (C1, C6). Break up the straight-cut ledges (C2). Move the detail camera off the house wall. |
| summit_eyrie | 1.88 | P2-022: raise the rotunda onto a layered stone sanctuary, so it's not small on a lawn. Remove the grey faceted boulder. Add C1 and C2 around the approach path. |
| three_bells_bridge | 1.96 | Remove the cyan T-post (P2-053) and the magenta edge glow. Replace the square dirt decal and the flat grass foreground with ledges toward the sea stacks (C1). |
| the_high_perches | 1.98 | Clear the grass from the compass-ring paving (P2-025). Keep the tutorial text in frame. Move the cameras off the giant trunk (C3). Ground or cut the rim mushroom (P2-102). Show the drop and the cloud sea (C1). |
| realm_gate_crag | 2.24 | Replace the realm-gate overhang (a blunt brown slab) with sculpted rock (C2). Break the dirt-stripe lawn into layered approach terraces (C1). |
| sky_shrine | 2.30 | The shrine shows only in the reverse view. Frame the approach on the shrine, clear the grass from its paving (P2-025), and replace the empty plain (C1). |
| windscar_beacon | 2.42 | A beacon spire landmark (C4). Hang the banners from poles, not mid-air. Sculpt the reverse-view cliffs (C2). |
| cliffhold | 2.48 | **Almost all camera work.** The approach camera sits on a blank wall (C3). The gameplay and reverse views are the best architecture in Cloudreach. Texture the flat orange plaza slab. |
| windscar_flight_aerie | 2.59 | There is no aerie in view: build or frame an aerie perch and launch structure (C4). The slope with one tree needs C1. |
| old_wind_observatory | 2.76 | Get the cameras out of the trunks (C3). Show the observatory (C4). Remove the plank props and the blue strips on the grass. |
| stormward_overlook | 2.90 | Remove the floating hedge cubes and dark strips (C5, P2-049). An overlook needs a drop: add a ledge edge to the void with the storm sky beyond (C1). |

**Suggested order for the lanes:**
1. C3 and C5. They are scene-only and quick, and they lift cliffhold, the observatory, the perches and the overlook, the four lowest stands apart from the aerie.
2. C1 and C6 across all stands. These are the biggest lever.
3. The new art: C2, C4 and the summit sanctuary.

## Files

- `_sheet_f40_gpu_main.png` (1.37 MB): Medium frames, from best to worst:
  - galefoot golden;
  - summit day;
  - sky_shrine day;
  - perches reverse with the clipped text;
  - cliffhold approach on the wall;
  - stormward overlook approach.
- `site_table.json`, `coverage.json`, `manifest_summary_*.json`.
- `yardstick/b1`–`b3`:
  - `key.json`, `sets.md`, `candidates.json`, `recorded_defects.txt`, `judge_prompt_filled.txt`;
  - `j1`–`j3` (the judges' own blocks);
  - `batch.json`, `mapped.json`.
- `build_yard_f40.ps1.txt`.
- Per-frame captures stay local.
