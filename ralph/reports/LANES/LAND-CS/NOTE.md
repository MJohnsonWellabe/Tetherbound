# LANE-LAND-CS NOTE (branch `tb/land-cs`; world look in Cloudreach and Stormwood)

## LANDING READY (13 Nov 20:30 UTC): `tb/land-cs-overlook-land` ab992dd4
One branch for both overlook arms, as the coordinator asked (verdicts: LANE-JUDGE, tb/judge ae67d0a5, both SHIP). Cut from main 874835ea.
- `overlook_ridge_join_1113` ON (overlook set 4.86 -> 5.28, 3/3) and `ruin_collision_1113` ON with the two reviewed walk stands (F40#15 walk pair 4.23 -> 5.60, 3/3). Each has `_why_on` and an ON pin test.
- **They compose:** five overlook route frames captured on CPU with both on; no z-fighting or overlap at the join, no translucent planes, 0 script errors. Sheet in `LAND-CS-OVERLOOK-LAND/`.
- 50 tests, 0 failed; overlook route smoke PASS with both on.
- It supersedes `tb/land-cs-overlook-join-land` and `tb/land-cs-overlook-solid-land`; do not land those.

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
