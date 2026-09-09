# Survey camera diagnosis — 2026-09-09

Root/Astra triage of the blind Meadows verdict. This is a capture-tool defect,
not a demonstrated production Hall placement defect. No visual repair is accepted
until corrected frames are surveyed and independently judged.

## Direct evidence

- `JUDGE-MEADOWS.md` reports apparently floating people/supplies in both Hall
  frames and unusable close-geometry obstruction in both Burrow frames.
- The Hall manifest in `shots/catalogue/meadows/round-20260909T002752Z/`
  records trainer Y **6.172043800354** and camera Y **5.517372131348** for
  both day and night: the camera is **0.654672 m below the trainer's feet**.
- The same engine log reports the stronghold's built floor at **Y 6.17**.
  The camera therefore sits inside/below the built floor, while the trainer
  stands on its actual collision surface. The frame shows the underlying
  meadow through the interior of the floor geometry, making supported objects
  look suspended. This proves an invalid viewing position; it does not prove
  that every Hall prop is correctly placed.
- `tools/catalogue_survey.gd::_prepare_capture_shell` disables the production
  `CameraRig` and substitutes an unprotected `Camera3D`.
- `_capture_row` anchors that camera to `world.ground_height_at` before the
  trainer finishes settling. `playground_world.gd::ground_height_at` explicitly
  returns Terrain3D height, not a building floor. The camera never follows the
  trainer's resulting height and has no geometry collision handling.
- Production `camera_rig.gd` is a `SpringArm3D`: it follows the actual target
  and uses the engine's obstruction handling. `built_floor.gd::resolve` already
  supplies the authored building-floor override, including floors below terrain
  in the Warrens. A maximum-of-terrain-and-floor rule would be incorrect there.

## Classification and bounded implementation brief

**Systemic / capture infrastructure / in-engine.** The same camera derivation
serves all four biomes. No new art, scale change, Hall prop relocation, lighting
change, or parked loading/profiling change is justified by this finding.

On the shared audit-resume branch, a Sol implementation lane owns only the
catalogue capture tooling, a small meaningful camera/floor regression fixture,
and its evidence report. Reuse the actual production camera rig and its collision
handling rather than recreating a second camera solver. Preserve canonical
destination IDs/coordinates, day/night timing, ordinary HUD, distinct outputs,
and no progression/save injection. Resolve any audit-only placement against the
existing built-floor contract and record settled trainer/camera transforms.

Validate with a small native fixture that distinguishes an elevated floor from
terrain and a camera obstruction; retain a negative control for the old invalid
camera placement. Do not run a full world alongside the active fresh campaign.
After its lease is available, re-survey every affected biome with the corrected
shared method, assemble before/after sheets with unchanged frame identities,
and use a code-blind judge. Preserve all original frames/verdicts. Obstructed
locations remain unassessed until usable evidence exists; capture counts alone
do not close that gap.

The Meadows verdict's visible night, material, creature and composition findings
remain findings. This diagnosis does not dismiss them or claim any acceptance bar.
