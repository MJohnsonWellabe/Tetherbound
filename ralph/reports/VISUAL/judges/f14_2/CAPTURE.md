# F14#2 / V-TW-1 capture context (lane lead only: do NOT give this to the judge)

## X/Y mapping (randomised per stand)

| Stand | X | Y |
|---|---|---|
| S1 | before (currents live, calm_scale 1.0) | after (`water_currents_restored`, calm_scale 0.5) |
| S2 | after | before |
| S3 | after | before |
| S4 | after | before |

## Run used

- render.yml run **36312890159** (label `vis-f14-2-current-restore-r3`), artifact 10930400433, dispatched on `main`, 1920x1080, mode=render (xvfb + opengl3 Compatibility on the llvmpipe runner). Took 934 s; `VIS CURRENT RESTORE OK failures=0`.
- checkout_ref `a54d2b29166ab64de343b165e391dac152fc2759` (tb/vis). It contains origin/main 4316362e. Relative to that build, the only game-side differences are two one-line edits outside Tidewake (`data/config/cloudreach_chapter.json` and `data/config/cloudreach_finale.json`), plus this tool. No water script, shader or config differs.
- script `tools/vis_capture_current_restore.gd`, args `--out=shots/vis_f14_2`.
- Raw, state-named frames: `/tmp/claude-0/-home-user-Tetherbound/17284e0f-c457-5bb8-96a5-6e50038613d5/scratchpad/f14_2_run3/tree/shots/vis_f14_2/`. Full log: `run.log` in the same folder.

## Poses (production CameraRig/Camera3D: fov 70, far 6500, production environment)

The eye is 40 m to the side of the current midpoint and 25 m back along the route, 16 m above the sea, looking at the midpoint (y 0).

| Stand | Current (authored) | Eye | Target | Time | Speed before → after (`current_at`) |
|---|---|---|---|---|---|
| S1 | tidal_cradle_to_salt_crown_direct (1.3 m/s) | (472.10, 16, 1922.53) | (425, 0, 1920) | day | 1.300 → 0.325 |
| S2 | salt_crown_to_sluice_isle_direct (1.3) | (497.99, 16, 2578.70) | (489, 0, 2625) | day | 1.300 → 0.325 |
| S3 | sluice_isle_to_veilfall_direct (1.8) | (598.60, 16, 3499.38) | (551.5, 0, 3502) | day | 1.800 → 0.450 |
| S4 | same as S1 | same as S1 | same as S1 | golden | 1.300 → 0.325 |

In every shot the logged camera position equals the stand eye. The logged calm_scale is 1.000 before and 0.500 after, in every frame.

## Shortcuts (disclosed)

- **Flag set directly.** `water_currents_restored` is set or cleared on `Game.world.flags` in one loaded world at the same pose. The tool waits 1.4 s for the view's 1 s poll and checks calm_scale. The real settlement path and its persistence are proven by `tests/smoke_tidewake_b_current_restore.gd`, not here.
- **Fixture flags.** The tool sets the smoke test's fixture, plus `water_dock_salt_crown_landing_charted` and `water_dock_sluice_isle_both_controls_disabled`. Without those two, S2 and S3 sit inside closed-gate tide races: `current_at` read 6.0 m/s in run 1. Any run that reaches the Guardian has both flags.
- **Pinned shader clock.** Software frames take several seconds each, so the shader TIME of two captures cannot be held to 1 s apart (run 1's pairs were about 25 s apart). At runtime the tool clones `water_current_flow`, `water` (sea) and `water_tide_race`, changes TIME to a `vis_time` uniform and leaves the code otherwise unchanged. Pinned values: t0 = 100.0 and t1 = 101.0 in both states, so before t0 and after t0 share the same clock.
- **Paused scene.** The CameraRig subtree is process-disabled and the Camera3D is posed directly. The trainer is hidden, parked below the eye and disabled. The WorldLook clock is frozen and all CanvasLayers (HUD) are hidden. This is not a rig-driven gameplay framing.

## Limitations and confounds for the reader

- **Unpinned motion.** Wild creatures in the water, the sky clouds and other TIME users keep real, unpinned time. Creatures visibly move between t0 and t1 and between states; this is not the current change.
- **Distance and view.** The ribbon's alpha fades between 180 and 520 m. Only the near half of each route is in view, at a grazing, elevated side view.
- **Software rendering.** All frames are llvmpipe/Compatibility. None are from a GPU or the ROG Ally.
- **Unusable earlier runs.**
  - Run 1 (36310803523, SHA 2bfb329): CameraRig is a SpringArm3D, and its internal physics step re-placed the Camera3D at the arm end near the spawn, so every frame showed First Shore land. `set_physics_process(false)` does not stop it. The same bug very likely explains the "terrain not streamed / no ribbons" frames in `ralph/reports/TIDEWAKE/b/f14_2_current_restore/PROOF.md`, where the smoke test pauses the rig the same way.
  - Run 2 (36312822533): cancelled and superseded.
- **GPU backup.** The backup request was sent to the lead: sha a54d2b29, same script and args.
