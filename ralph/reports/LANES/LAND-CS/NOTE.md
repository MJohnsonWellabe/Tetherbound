# LANE-LAND-CS NOTE (branch `tb/land-cs`; world look in Cloudreach and Stormwood)

## LANDING READY (14 Nov 02:45 UTC): `tb/land-cs-soiloff-land` 043e33593
- SOILOFF SHIPS (G-land-cs-soiloff): F41#22 5.33 -> 6.03 (+0.70, 3/3), F41#24 5.29 -> 6.23 (+0.94, 3/3); glass, rod_line, stormheart level.
- Cut from current main 94fe423d3; only `forest_layers_1113` ON with `_why_on`; ON pin; 45 Stormwood ground tests, 0 failed; READY.md. Presentation only (no route smoke needed).
- TURFGRAIN matrix no-loss: level (G-lcs-turf-matrix), so PR #963 stands.
- In progress: WALL-BAND round 2 (`band_depth_m` 3.0: pale band only in the top 3 m under the rim), CPU capture of the Realm Gate and Three Bells bridge frames running.

## URGENT FOR PR #963 (14 Nov 01:55 UTC): WALL-BAND withdrawn, pushed to the PR branch
- LANE-JUDGE amended G-below6-wall-band-main to **DO NOT SHIP**: the F40#8 no-loss check loses on the Three Bells bridge, 6.29 -> 5.86 (−0.43, 0/3); the band repaints a whole cliff face as grey with faceted brown patches.
- I pushed `tb/land-cs-cloudreach-land` 0096977e0: `wall_top_band_1113` OFF with `_why_off`, its test now an OFF pin, READY.md amended. TURFGRAIN unchanged and still ON. 23 tests, 0 failed. **CI on #963 needs to run on this head before merging.**
- F40#1 HELD: BELOW6-WALL-BAND, F40#1 +0.32 stands; round 2 must limit the band to rim and wall-top geometry (height band or normal mask) and re-judge with the Three Bells bridge frame.
- F40#8 next ask (not taken yet): mute the gold-cone pointer post behind the trainer.

## STATE (14 Nov 01:40 UTC)
- **Landed on main:** overlook join + solid ruin (#954, inherited), RIMGLOW (#961), OVERLOOK-SEAMS (#962). **In CI:** TURFGRAIN + WALL-BAND (PR #963). The single-arm land branches are not needed.
- `tb/land-cs` dbbfc7842 contains main 94fe423d3. Against main it differs only by flag-off arms (`forest_layers_1113`, `paver`-free now, `rim_pickup_seat_1114`, `master_floor_1114` parked, `candidates_1113` arch stand) and their tests and reports.
- **Waiting on the GPU:** SOILOFF (F41#22/#24). **Held, CPU-ready:** ARCHSTAND (F40#3), RIMSEAT (F40#17). **Held for a combined re-judge:** GATE-TERRACE round 2 (to build: taller risers, no loops).

## LANDINGS READY (14 Nov 02:30 UTC): TURFGRAIN and WALL-BAND
- **Combined, as asked: `tb/land-cs-cloudreach-land` 5e926e829** (from main 1405def4d; both flags ON, gate terraces OFF; 58 tests, 0 failed). Land this instead of the two single branches below.
- **`tb/land-cs-turfgrain-land` 59feea6b**: `turf_detail_1113` ON. G-land-cs-turfgrain-rows: F40#1 +0.20, F40#4 +0.19, F40#7 +0.24, each 3/3, no loss. 53 tests, 0 failed.
- **`tb/land-cs-wallband-land` 996efab0**: `wall_top_band_1113` ON (BELOW6 arm). G-below6-wall-band-main: F40#1 6.19 -> 6.51 (+0.32, 3/3), no loss. 45 tests, 0 failed. Landed alone: LANE-JUDGE asks to re-judge it with GATE-TERRACE before both land, so `gate_crag_terrace_1113` stays OFF.
- Both cut from main 1405def4; different keys in cloudreach_visual.json, so either order.
- **GATE-TERRACE (thin 2/3, +0.20): HELD** for a combined re-judge with the band on. Its next ask: chunky risers with height, drop the loops across the lawn.
- Next asks I will work: TURFGRAIN tiles to speckle near the camera (break it with macro variation); the wall band needs strata and a broken top edge, on every disc-rim island edge.

## LANDING READY (14 Nov 01:40 UTC): `tb/land-cs-seams-land` 3abd3fa9
- OVERLOOK-SEAMS SHIPS (LANE-JUDGE G-land-cs-overlook-seams): F40#15 5.10 -> 5.41 (+0.31, 3/3), overlook other views +0.31 (3/3).
- **Disclosed:** High Perches no-loss −0.30 (0/3), which LANE-JUDGE attributes to wyvern staging and did not count; a fixed-seed re-capture is offered. Your call before merging.
- Cut from current main; flag ON with `_why_on`; ON pin; `test_cloudreach_stormward_overlook` paver count 4 -> 0; 18 tests, 0 failed; overlook route smoke PASS.
- Two slots free now (RIMGLOW and SEAMS judged): ARCHSTAND (F40#3) and MASTERFLOOR (F40#17) are CPU-ready.

## New arm, held: LAND-CS-MASTERFLOOR (F40#17, 14 Nov 01:10 UTC)
- The "orange checker disc" on the upper platform is `MasterT4/ArenaFloor` (pixel probe): the worn-ground soil overlay with a 2 m dirt-path tile at #9b805f. The arm gives Master floors a 7 m tile and a muted earth tint (#80776a); other yards unchanged. CPU: the checker is gone. CPU-ready and held.
- The "griffin clipping the tower" is the player's own Galecrest companion (`AllyCreature`), so it is companion placement for LANE-BEINGS or LANE-THINGS, not this lane.

## LANDING READY (14 Nov 00:30 UTC): `tb/land-cs-rimglow-land` 1b9bd1ed
- RIMGLOW SHIPS (LANE-JUDGE G-land-cs-rimglow): F40#17 6.03 -> 6.61 (+0.58, 3/3); court no-loss level (-0.04, noise).
- Cut from current main; flag ON with `_why_on`; ON pin test; 75 pickup and mushroom tests, 0 failed; READY.md with STATUS: land.
- A RIMGLOW slot is free: ARCHSTAND (F40#3) can take it.
- Next on F40#17 from the judges: the orange checker platform top (scene, mine), the orange lip cluster's base (mine), the griffin clipping the tower (LANE-BEINGS, perch), the night grade (CLOUDNIGHT r2).

## Tried and failed, and held arms (indexed bullets, 14 Nov 00:20 UTC)
- F40#15 PARKED: lift the ridge above the ledge crown (`overlook_ridge_join_1113.sink_m` -0.12); no change to the dark wedge on CPU.
- F40#15 PARKED: remove the ridge join's 4 m route exemption (temporary switch); the wedge is unchanged, only the pavers sink.
- F40#15 PARKED: `edge_1113` (join over every cap-0 pad, from 1.5 m inside the rim); no visible change, reverted. Ridge vertices are about 4 m apart, so a lift cannot reach the ledge face between them.
- F40#15 PARKED: `overlook_ledge_drop_1113` (overlook ledge and pad 0.18 m lower); no visible change, reverted. Next try must first confirm the ledge face moves (print its heights).
- F40#15 PARKED (no cause found): "rampart and tower over the void" at walk_03. Ground probe under every corner of both ruined wings and both piers finds crown turf (1109.7 to 1111.5), none over the void; the right wall stands at the lip and reads as overhanging from the low walk_03 camera. One real fault: `StormwardRuinedWing01` floats 0.2 to 0.5 m above its ground (bottom 1110.22). Seating it is small and not sent alone.
- F40#15 SHIPPED: LAND-CS-OVERLOOK-SEAMS, 5.10 -> 5.41 (3/3); landing branch tb/land-cs-seams-land.
- F40#1 PARKED: re-cluster the Cloudreach grass tufts by overlay (`ground_cover.cluster_frequency` 0.55, `cluster_threshold` 0.9); no visible change on CPU, not sent.
- F40#1, F40#3, F40#4, F40#7, F40#11 PARKED: the F26 course rock surface on the owner's granite (no pale retint); not built, because the same surface lost 0/3 inside `pale_strata` and judges preferred the textured earth.
- F40#1, F40#4, F40#7 SHIPPED: LAND-CS-TURFGRAIN (+0.20, +0.19, +0.24, 3/3 each); landing tb/land-cs-turfgrain-land. Matrix stands F40#0/#19/#21 not judged yet.
- F40#1, F40#8 PARKED (as is): BELOW6-WALL-BAND. F40#1 +0.32 (3/3) but F40#8 loses 6.29 -> 5.86 (0/3, cliff face repainted). Withdrawn from PR #963.
- F40#1 HELD: BELOW6-GATE-TERRACE (+0.20, 2/3, curbs read as generated contour lines); re-judge with the wall band on.
- F40#3 HELD: LAND-CS-ARCHSTAND (skyroad arch stand from the island's south rim), CPU-ready, waiting for a queue slot.
- F40#17 HELD: LAND-CS-RIMSEAT (tan rim find 1.2 m back from the lip; overlay glow 0.3), CPU-ready, waiting for a queue slot.
- F40#17 PARKED: rim finds respaced widely (CPU round 1 of RIMSEAT, not sent): two clusters left the fixed frame.
- F40#17 PARKED: LAND-CS-MASTERFLOOR (Master T4 arena floor soil tile and tint). G-land-cs-masterfloor: level, 6.04 -> 6.13 (+0.09, 1/3, 2 ties); judges call the platform background, not the subject. LANE-JUDGE: no more rounds on the platform top for F40#17.
- F40#17 SHIPPED: LAND-CS-RIMGLOW, 6.03 -> 6.61 (3/3); landing branch tb/land-cs-rimglow-land.
- F41#22, F41#24 SHIPPED: LAND-CS-SOILOFF (+0.70, +0.94, 3/3); landing tb/land-cs-soiloff-land.
- F40#6 PARKED (owner decision): the mount upright over open cloud; no arm from this lane.

## New arm, held: LAND-CS-RIMGLOW (F40#17, now 5.61; 13 Nov 23:55 UTC)
- The "toy-like glow blobs" are the shared pickup glow's 0.7 m halo round the three small rim patches (the patches shipped 12 Nov at about 0.6x the old cap; the halo was not resized). The arm scales the glow at those three placements only (0.45); they still glow (owner OP-0830-3). CPU: the balls are gone. CPU-ready and held.
- The night navy grade on this row is THINGS-CLOUDNIGHT round 2's target.

## New arm, held: LAND-CS-ARCHSTAND (F40#3, 13 Nov 23:30 UTC)
- The skyroad arch frame "shows no landmark" because the stand is 8 m from the arch, between its legs: the "two blocky cliff faces" are the legs. The arch's island is about 15 m across, so the tool cannot back off. A stand override from the arch centre toward the south rim frames the whole arch; the band frame broken_causeways 04, which had no stand at all, now captures too. Capture tooling only. CPU-ready and held for the queue.
- F40#6: the remaining defect (the mount upright over open cloud) is recorded as an owner decision; not touched.

## Cloudreach "faceted brown cliff" (F40#2, #4, #7, #11 in G-rescore-stale-ext-cloudreach): finding, no arm (13 Nov 22:45 UTC)
- The rock banks render warm tan (route_day bank RGB 167/146/103), not the owner's 6 Sep option-A grey-green granite (`geology.stone_light` #8a8f82). Cause: `cloudreach_rock.gdshaderinc` multiplies the granite palette by the rock scree texture (`albedo = stone * mix(0.82, tex * 1.28, 0.52)`), whose brown cast sets the hue.
- The fix path already exists: the F26 course surface (`cloudreach_rock_courses`, art.json `cloudreach_rock_surface`, OFF) strips the texture hue and paints the palette with metre-scale beds.
- **Not built:** it was GPU-judged inside the cause lane's `pale_strata` (G-newapproach-cloudreach-cause-no-cloudsea): F40#1 and F40#3 lost 0/3, the lips read "smooth, untextured clay-like", and judges preferred base's "textured earth". The untried variant (courses on the owner's granite, no pale retint) removes the same texture hue the judges preferred, so I am not spending a GPU slot on it without a new reason.

## F40#17 is stale on the board (13 Nov 21:50 UTC)
The High Perches rim dressing shipped at 6.01 -> 6.94 (3/3; G-below6-mushrooms) and is on main (`tests/test_below6_perch_rim_landed.gd`, #949). Two judges gave 7.04 and 7.17. It needs a re-score on main (High, then Medium if High is 7.5 or above), not a new arm.

## F40#15 dark wedge and walk_02 feet strip: PARKED after four failed attempts (13 Nov 22:30 UTC)
- The probe names the overlook ledge's own body (`LandmarkLedge/StratifiedCliffBody`) a few cm in front of the ridge turf: the wedge is the ledge's side face standing above the lower ridge.
- Attempt 1: join `sink_m` -0.12 (lift the ridge above the crown). No change.
- Attempt 2: remove the join's 4 m route exemption (temporary code switch). No change to the wedge; only the pavers sink out of sight. So the wedge is outside the join's ease band or not on the ridge rows it lifts.
- **Same family at walk_02 (probe, 13 Nov 21:30):** the thin dark strip at the trainer's feet is the route ledge `SummitOverlookLoop_Ledge3/StratifiedCliffBody`, its surface within 1 to 6 cm of the ridge turf (`Ridge003`) along the ray. So both the wedge and this strip are ledge bodies whose edges stand a few cm proud of the lifted ridge, showing their rock side band.
- Attempt 3 (probe-led): the wedge points are ridge 1108.46-1108.58 and the ledge side face (normal_y 0.10) up to 1108.64, at about 20.6 m from the overlook centre, just inside the larger cap-0 pad's 20.68 m rim (the other cap-0 pad is 13.12 m). A flag-off change made the join consider every cap-0 pad, take the highest lift and start 1.5 m inside the rim. No visible change on CPU at route_day or vista_dusk, so I reverted it. Most likely `SummitOverlookLoopCliffShoulders/Ridge003` rows are not built through `_overlook_join_height` at all (another ridge builder, or the rows are pinned elsewhere).
- Why lifting fails: `Ridge003` is a `_route_ridge` piece (`SummitOverlookLoopCliffShoulders`); its rows are 7 vertices across and about 4 m apart near features, and the join moves only those vertices. A face crossing between them is out of reach.
- Attempt 4 (coordinator's OVERLOOK-LEDGES idea, tuck the ledge): a flag-off `overlook_ledge_drop_1113` lowered the overlook's `ledge_y` (mesa and pad) by 0.18 m. No visible change on CPU (mean pixel difference 2.7 at route_day, inside the 1.7 to 5.7 run-to-run noise of the other experiments). Reverted. Not verified that the drop reaches this mesa: its crown follows the two sloped hidden crown strips per vertex, possibly in absolute height.
- Before any next try: print `LandmarkLedge` global y and the crown vertex heights near (-421, 1108.6, 5629.4) with and without the change, so a change is confirmed to move the face before a capture is spent.
- Older note: read which ridge vertices sit under the wedge and their distance from the ledge rim (the join only lifts between rim and rim + 9 m), or lower the ledge's edge band instead.

## HEAD FOR THE GPU LANE (13 Nov 20:20 UTC): `tb/land-cs` 6b5b789f or later (later commits touch only report files)
- Contains main b8622117c (#954). Against main it differs only by three flag-off blocks (`forest_layers_1113`, `turf_detail_1113`, `paver_strips_1113`), their code and tests, and report files, so base frames from this head are main's.
- **Scope (coordinator, 20:03):** Cloudreach rows plus the queued SOILOFF (F41#22/#24). LANE-PLACES has the other Stormwood rows; I start no new Stormwood arms.
- **Order:** F40#15 (wedge, then grey ramp), F40#2 6.15, F40#17 6.18, F40#16 6.19, F40#3 and F40#6 6.33, F40#9 6.48.

## OVERLOOK LANDED (#954, main b8622117c); next F40#15 arm ready (13 Nov 21:10 UTC)
- Both overlook ships are on main (the coordinator landed the two single branches). `tb/land-cs-overlook-land` is not needed.
- **New arm LAND-CS-OVERLOOK-SEAMS** (F40#15, 5.60): a pixel probe names the plank and slab strips at route_day, vista_dusk, walk_02 and walk_03 as the four `approach_pavers`, buried by the ridge join except for a sunken strip. The arm stops building them; the strips are gone on CPU at all four frames. No collision change. **CPU-ready and held**: SOILOFF and TURFGRAIN are my two waiting arms.
- Not fixed yet: the dark wedge (the ledge's own edge standing proud near the trail) and the walk_03 grey ramp (the ridge shoulder's rock flank).

## TO THE COORDINATOR (13 Nov 17:50 UTC; direct message refused, so it is here)
The session message to the coordinator was refused ("needs proof of a trusted device"), so this NOTE is my channel until that works.
- **Arm LAND-CS-SOILOFF, `tb/land-cs`, rows F41#22/#24 (riders F41#5, #12, #2).** Please queue it in THINGS-STORMPOOL round 2's slot and drop stormpool: same rows, and it removes the patches that arm only made matte.
- **Arm LAND-CS-TURFGRAIN, `tb/land-cs`, rows F40#1, F40#7, F40#0/#19/#21, F40#4.** CPU-ready and held: the inherited arms already fill the two-waiting limit. Queue it when a Cloudreach slot frees; it can share a boot with any other `tb/land-cs` overlay.

## Coordinator's turfgrain check (13 Nov 18:00 UTC): PASS
On `tb/land-cs` with main 874835ea (#951 and #952) merged, flag on, Compatibility renderer (`opengl3`, `gl_compatibility`), Realm Gate approach: 0 shader errors, 0 script errors, and the lawn shows the same grain as the arm frame before the merge (fine contrast 15.3 both times; base 6.8). So Low shades the turf the same way.

## State, 13 Nov 2026 about 16:50 UTC
- Branch cut from `origin/tb/coord-wrapup-1113` (c673d528); main did not contain #951 yet. I merge `origin/main` once it lands.
- No ship yet. Two new arms pushed: LAND-CS-SOILOFF (Stormwood ground) and LAND-CS-TURFGRAIN (Cloudreach lawn).

## Waiting on the GPU
| Arm | Rows | Status |
|---|---|---|
| LAND-CS-SOILOFF | F41#22, F41#24 (6.46); riders F41#5, F41#12, F41#2 | New. Cause confirmed by switch-off on CPU. Asks to take THINGS-STORMPOOL round 2's place. |
| LAND-CS-RIMGLOW | F40#17 | SHIP 6.03 -> 6.61; landing branch pushed. |
| LAND-CS-ARCHSTAND | F40#3 (6.33) | New, CPU-ready, held. |
| LAND-CS-OVERLOOK-SEAMS | F40#15 (5.60) | New, CPU-ready, held until a slot frees. |
| LAND-CS-TURFGRAIN | F40#1, F40#7, F40#0/#19/#21, F40#4 | New, CPU-ready, held until a slot frees. |
| BELOW6-OVERLOOK-JOIN, BELOW6-OVERLOOK-SOLID | F40#15 | SHIP verdicts; one landing branch pushed (see top). |
| BELOW6-WALL-BAND, BELOW6-GATE-TERRACE | F40#1 | Inherited, queued. |
| THINGS-CLOUDNIGHT round 2 | F40#0, F40#19, F40#21 | Inherited, queued. |
| THINGS-WETPATH3 | F40#21 and paths | Inherited, not judged. |
| THINGS-STORMPOOL round 2 | F41#22, F41#24 | Inherited. Superseded by SOILOFF: withdraw it. |

The inherited arms already exceed two waiting, so I send nothing else until verdicts come back. Further arms are built to CPU-ready and held here.

## Findings
- **Stormwood black cut-outs and the Break slab are the `wet_soil` forest layer** (1,400 opaque near-black discs with a scissored rim), not the terrain pool zones. Switching the layer off removes them at forest and giant. Detail in `LAND-CS-SOILOFF/ARM.md`.
- **Cloudreach "uniform lawn with lone blades"** (3/3, `G-rescore-f40-0-sample`) has two parts. The tufts are at their configured density (probe: 2.23 million tufts, 2.1 to 4.8 per m²; the three largest islands hit the 135,000 cap). The lawn under them is flat because `cloudreach_turf.gdshaderinc` cuts the grass texture's contrast to 0.52. TURFGRAIN restores the fine detail only. Re-clustering the tufts by overlay did not change the frame.
- **Cloudreach has three grass systems:** `cloudreach_ground_cover.gd` (patch ellipses and route segments), the look pass's ellipse dressing, and its `turf_fill` (0.35 per m² everywhere, owner 6 Sep: grass must be continuous). All use the seven-blade tuft.
- **Night clear still reads as a blue-washed day** in the GPU frames (gate and sky shrine, 23:00): saturated blue sky, bright green lawn, glowing orange trail. CLOUDNIGHT round 2 is the queued answer; not re-examined here.

## Next
1. F40#15 follow-up from the judges (now 5.60): find what draws the dark slab at the trainer's feet in walk_02, the dark plank and green-top slabs and the grey ramp wedge in walk_03, and the dark wedge beside the path; then the open-backed wall slabs.
2. On the SOILOFF and TURFGRAIN verdicts: land, or revise through the same flags.
3. Stormwood F41#10 Glass Sink (6.01) and F41#1 Stormheart (6.54).

## Runbook additions
- First boot of a fresh container needs `godot --headless --path . --import` (about 20 minutes).
- `capture_stormwood_f10_matrix.gd --stands=forest,giant --phases=calm --no-aftermath` on CPU: about 10 minutes; Break frames add 1 to 8 minutes each.
- `phase2_capture_locations.gd --biome=cloudreach --subset=<name> --times=day` on CPU: about 2 minutes to boot, then under a minute a frame. `--subset=sky_shrine` also matches the High Perches district; stop the run once the frames you need are written.
- Run one Godot at a time: two at once were killed for memory.
- List-valued config (such as `forest_layers`) needs a by-name patch flag for overlays; `forest_layers_1113.layers.<name>` is that for Stormwood.
