# F13#5 Tidewake currents, docks and Veilfall distance: re-capture and code-blind judge (5:36 AM CT Tue 13 Oct)

Capture: tb/ev-visual 26f948ad, tools/capture_tidewake_f13_5.gd (Compatibility, 1280x720, production camera, day; disclosed teleport poses and mid-chapter story flags), 16 frames; sheet _sheet-r5.png. One fresh code-blind judge, frames and docs/reference only.

**Verdict: FAIL** — (a) Veilfall distance PASS, (b) inhabited docks FAIL, (c) currents FAIL. Holds for the F39 catalog pass; this lane records and stops.
- (a) Veilfall reads on the horizon from First Shore and gains scale and cliff detail at Tidal Cradle and Sluice Isle. Minor: heavy fog at First Shore; at Sluice Isle the companion fills half the frame and clips the trainer and fence.
- (b) Six of seven docks are the same short pier with 2-3 tiny NPCs and crates; no boats, lights or stalls; docks distinguishable only by backdrop. Greybox: pale-blue cube on a tan slab at Shellwatch, a white slab at Salt Crown, a large cube/box/stick at Sluice Isle (the eastern sluice). Large empty sand foregrounds.
- (c) The three currents read as calm water with a dozen white flecks hovering above the surface that shift a few pixels between the 0.5 s pair; no streaks, foam bands or direction; the strongest current (1.3 m/s) looks the same as the 0.3 m/s ones.
- Other: overlapping creatures at Sluice Isle; a ghosted see-through creature in the first current's second frame. No oxblood.

## Restart Look: next fixed F13#5/F39 route prepared, native UNRUN

15October, current restart-look source5e9f2fe29f15af24956794af13bc7603100eb75a (evidence-only successors do not change these game/capture files). Same tb/look checkout/task; no revival of the archived Tidewake lane, stage access, new runner or capture edits. F38 remains OPEN/render-blocked and its5.67 round is VOID for acceptance.

**Preserved failure, not readiness:** the original full-world e006388448964301fb538209d132ff721bab1db3 run rendered one shore-day image at1920x1080/Forward+ on Godot4.7/GTX1060, then failed natural shutdown at180s. Its actual stdout reports fixed_views_returned/quit_requested/quit_returned near59.6s and world/Game tree exits near73.0s; those markers do not prove process exit. The successful one-region isolation does not exonerate the full scene. Compared with that source, current water_world.gd, water_vegetation.gd and grass_field.gd have no source delta. The capture script adds optional shutdown observations and binds ground cover to the fixed camera before capture; normal quit remains unchanged. The retained runtime interpolation patch may remove its deprecated-call warning, but is not evidence of a shutdown repair. No new readiness or supported natural-exit claim is made.

**Actual required local resources:** current Water scene loads res://data/terrain/water. Only its manifest was materialized;32 tracked files were missing. Normal Git restore from currentHEAD restored precisely those missing files at04:55:12CT:31 terrain3d region resources and surface_height.res. No existing file overwritten, no bake/import/source change. The committed manifest records31 regions while water_world.json declares78; this discrepancy is retained, not normalized or silently certified. All13 configured Water vegetation model sources and their existing imported scene/mesh references are present. Presence does not prove runtime/world completeness. This restoration is new to this checkout; it does not itself repair the historical teardown failure.

**Existing commands for a future grant — NOT executed.** All use executable C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64.exe and APPDATA=D:/tetherbound/restart-look/.artifacts/f17-direct/user, own checkout, Forward+/Vulkan. Windows launch retains WindowStyle Hidden and the grant's actual child bound; no existing180s failed shutdown cap is raised by this preparation. Each actual argv and pushedSHA must be recorded at execution. No candidate is persisted ON.

Required existing parser for the capture script's changes since the preserved native attempt, only once native authority is granted:
```text
--headless --path D:/tetherbound/restart-look --check-only --script res://tools/capture_tidewake_f13_5.gd
--log-file D:/tetherbound/restart-look/.artifacts/look30-tidewake-parser.log
```
Only the coordinator's specifically allowed `Identifier not found: Game` autoload false positive may be classified as such; no other parser failure is waived.

F13#5 function matrix, Medium baseline (High uses --preset=High and a distinct high-baseline output/log):
```text
--path D:/tetherbound/restart-look --rendering-method forward_plus --rendering-driver vulkan --resolution 1920x1080
--log-file D:/tetherbound/restart-look/.artifacts/look30-f13-medium-baseline.log
--script res://tools/capture_tidewake_f13_5.gd --
--out=D:/tetherbound/restart-look/.artifacts/look30-f13-medium-baseline
--preset=Medium --only=veilfall,docks,currents
```
This unchanged path has3 Veilfall views,7 mandatory dock views and3 currents with shore/swimmer four-frame strips:34 expected JPGs, not the old16-frame count. It uses production CameraRig, disclosed mid-chapter flags and live current drift. Actual raster size, loaded terrain/vegetation, errors, frame count and natural exit remain unproved. It does not supply >=200 frames or full F39 weather/fight coverage. A later matched current-cue candidate arm adds only the already-existing --tidewake-current-candidate and a fresh candidate output/log; that preview changes the cue, not current strength or dock art.

Preserved fixed current-cue sample (four human-swimming views), if selected by root instead of the full function matrix:
```text
--path D:/tetherbound/restart-look --rendering-method forward_plus --rendering-driver vulkan --resolution 1920x1080
--log-file D:/tetherbound/restart-look/.artifacts/look30-t2-medium-baseline.log
--script res://tools/capture_tidewake_f13_5.gd --
--out=D:/tetherbound/restart-look/.artifacts/look30-t2-medium-baseline --preset=Medium
--camera-set=res://tools/visual_judge/camera_sets/T2-current.json --capture-size=1920x1080
--source-sha=<actual-pushed-HEAD-at-launch>
```
A candidate adds only --tidewake-current-candidate and fresh paths; do not add --restored-currents to an adverse-current comparison. Fixed F39 look sample uses the same command with --camera-set=res://tools/visual_judge/camera_sets/F39-look.json and fresh look30-f39-<preset>-<arm> paths; its6 clear-weather views are an initial sample only. The existing process-local --tidewake-look-candidate selects that look arm; it is distinct from the current cue and shoreline candidate and should not be bundled into an unattributable change. Medium/High remain explicit and separate.

The placeholders above are the actual execution-time Git identity, not a stage/source-admission protocol. No source pin, job manifest, hash inventory, validator, teardown collector or new harness was created. The full existing capture_f39_tidewake_matrix.gd route is preserved separately, not claimed ready through these small samples. Current tidewake_look.enabled, water_current_cue.enabled and water_dune_cover.shore_ecology_candidate.enabled remain false. Historical dock/current failures still need real game improvement and three fresh blind judges; no old single-judge verdict closes them. **Await root Look30 decision/grant; unresolved full-world shutdown must be explicitly retained if a direct attempt is authorized. No native since turn26 release.**