# Tether Machine suspension and shutdown

**DRY RUN — does not count as earned chapter proof.** Draft [#365](https://github.com/MJohnsonWellabe/Tetherbound/pull/365), based on current main `ce1a3c6e576c5e0bf99c5ee543258794be302b00`. X04 / F05, ART_DIRECTION Bars A/B. Claude owns merge.

The installed hero had thin strip-like suspension and no real rune emission; its CoreLight also remained active after freeing. The candidate adds two upper-core suspension chains (30 closed links), brass anchor fittings and four small runic plaques. All new geometry stays above the creature space. The existing source mesh, albedo, scale, facing, collision and cage measurements remain unchanged.

The reference is `docs/art/reference/15_Legendary_Tether_Machine.png`, used for direction only. Hardware is authored with Blender 4.2.9 through `tools/art_pipeline/build_machine_hardware.py`; no generation service or credits used for this addition. Provenance and hashes are beside the GLB.

## Validation

- Independent source/asset review (`first_shore_fence`): **7,280 triangles / four surfaces**, 30 closed links, no degenerate faces, reversed normals, open/nonmanifold edges or chain crossings. All 28 adjacent chain pairs checked. Bounds X ±4.858400, Y13.233000–18.027000, Z ±0.742320 remain within the original machine bounds and above the Y11.732381 crown underside.
- `tests/smoke_machine_finish.gd`: **15 checks, zero failures**, native Compatibility, clean stderr on the final asset. Covers nonempty cage measurement, unchanged geometry, independent material instances, live flag, existing flag at load, idempotence and physical fittings remaining. The load check exercises the existing watcher with an already-set flag; it does not claim a fresh full save/load campaign run.
- Native stage and Hall capture: `tools/capture_tether_machine.gd`, **26 frames at1920×1080**, Godot4.7 `5b4e0cb0f`, Compatibility/OpenGL3.3, GTX1060 3GB driver560.94. Matched baseline/candidate stage at four azimuths; Hall entrance, old reveal stand and side, day/night; candidate release endpoint, day/night; four original-presentation control frames. All runs exited0 with no mechanical skips. Four old-reveal frames remain visually occluded and provide no focus/readability proof. Native frame hashes, cameras and20 passing runtime checks (10 candidate,10 control) are in `tether-machine-evidence.json`; `_sheet_tether_machine.jpg` is a preview only.
- The production Hall run checks source dais4.063849, crown11.732381, original base cylinder5.6×2.7, active emission/light before release, both disabled after release, fittings visible, and unchanged measured geometry. The game's release path places the creature10.55m from the axis. These are fixture checks, not earned combat, motion acceptance or Ally performance proof.

## Independent visual disposition

`draught_visual_judge` viewed matched native images and board15 without reading code. The suspension layout passed at four stage angles and Hall entrance/side day/night: plausible arch-to-crown connections, seated small mounts, subordinate cyan accents, no new visible float, severe intersection or overglow. The released endpoint shows the creature on the foreground floor and the white restraints absent. Movement quality is not established by stills.

Final rune base colour separates dark inlay from emitted light so the powered-down material no longer relies on bright cyan pigment. The final code-blind comparison passed: held day/night retains restrained cyan symbols, while released day/night shows faint dark teal inscriptions. The exposed right plaque establishes the inactive state even where the freed creature obscures the left. No glow/focus regression; prior scoped suspension approval stands.

**Whole-machine Bars A/B remain open.** Reflective marbling, coarse warped structure, thin side profile, diagrammatic restraint rings and strong night highlights remain. The old reveal stand is heavily occluded by the near pillar; its frames cannot establish prisoner or hardware readability. Freed creature upper extremities leave the entrance frame. Do not treat the scope pass as machine or chapter acceptance.

## Rejected approach and renderer finding

A broad iron shader removed baked glare but flattened the source into a faceted blockout; large lower plaques competed with the prisoner and their chains looked decorative. Both were rejected and removed. The final candidate retains the original body materials and limits additions to the upper suspension and small plaques.

Two hardware instances with copied unlit surface overrides reproduced a Godot4.7 material-RID diagnostic during deletion. An isolated probe established that clearing overrides before destruction removes that error. The new hardware-only MeshInstance3D script does this at `NOTIFICATION_PREDELETE`; live state and reparenting are untouched. Independent source review found no blocker. Focused headless and final Compatibility smoke runs are clean.

**The full world still logs eight GLES3 material-null teardown errors.** A controlled run with new Hardware removed and the original withdrawal list restored reproduces the same eight diagnostics, while its10 checks and4 frames pass. This distinguishes the broader pre-existing teardown problem from the isolated new-hardware lifetime issue; it does not close that engine defect. Both candidate and control log `material_casts_shadows`, `material_is_animated`, `material_get_instance_shader_parameters`, and `material_update_dependency` twice. Do not call the whole-world run error-free. The control is reproducible with `--baseline-machine --only=machine_entrance`; it changes presentation only in the capture process, never production config on disk.

## Reproduce

Import with the project's normal Godot editor import first. Serialize render/import writers using the workspace render lock. Run from an isolated profile:

```text
Godot_v4.7-stable_win64.exe --path . --rendering-method gl_compatibility --resolution 1920x1080 --fixed-fps 60 --script tools/capture_tether_machine.gd -- --out=res://shots/machine-final
Godot_v4.7-stable_win64.exe --path . --rendering-method gl_compatibility --resolution 1920x1080 --fixed-fps 60 --script tools/capture_tether_machine.gd -- --section=region --region=meadows --out=res://shots/machine-final-world
Godot_v4.7-stable_win64.exe --path . --rendering-method gl_compatibility --script tests/smoke_machine_finish.gd
```
