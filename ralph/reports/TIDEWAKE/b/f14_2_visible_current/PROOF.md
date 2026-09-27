# F14#2 visible current restoration (V-TW-1, V-VIS-12)

ACCEPTANCE §6.1 F14: "the water/current network visibly changes and persists".
The state and persistence were already proven in `../f14_2_current_restore/`.
The look was not: VIS's code-blind judge (`tb/vis` `ralph/reports/VISUAL/judges/f14_2/VERDICT.md`) could not tell the states apart, because only `calm_scale` changed.

## Change (existing shader, config and view script only; no new meshes or textures)

- `shaders/water_current_flow.gdshader`: four new float uniforms. `streak_density` sets the fraction of foam lanes that carry dashes. `dash_fill` sets the dash length within a lane. `fleck_amount` sets the chop flecks between lanes. `brightness` is a colour gain. The defaults keep the old look.
- `data/config/water_veilfall.json` `current_flow.state_shader`: one parameter set per state.

  | uniform | live (before) | restored (after) |
  |---|---|---|
  | calm_scale | 1.0 | 0.5 (`restored_calm_scale`, unchanged) |
  | opacity | 0.95 | 0.40 |
  | lane_opacity | 0.22 | 0.04 |
  | streak_density | 1.0 | 0.25 |
  | dash_fill | 0.85 | 0.20 |
  | fleck_amount | 0.9 | 0.05 |
  | speed_scale | 2.4 | 0.65 |
  | min_speed_m_s | 0.6 | 0.15 |
  | brightness | 1.15 | 0.85 |

  At the 1.3 m/s sample current, the streak drift is 1.73 m/s before and 0.29 m/s after, about 6x slower.
- `scripts/world/water_current_flow_view.gd`: `state_parameters(restored)` returns the full set. It is applied from `water_currents_restored`, the same world flag that drives `calm_scale`, on build (load or reload) and on every flag change (1 s poll). The flag is a replicated world fact, so every peer shows the same state. The world flag store is loaded in place, so the view's reference stays valid.

## Tests

- New `tests/test_water_current_flow_states.gd` (4 tests, 57 assertions) checks four things:
  - each named parameter differs by a minimum ratio: speed at least 3x, foam opacity and coverage at least 2x;
  - the drift ratio at 1.3 m/s is at least 3x;
  - the material uniforms follow the flag when it is set and when it is cleared;
  - a view rebuilt over a restored store starts restored.
- `tests/smoke_tidewake_b_current_restore.gd` now also asserts every uniform against its state set at three points: before, after the real Guardian decline settlement, and after the production save/reload rebuild. The smoke run went from 20 checks to 77, with 0 failures (`smoke_result.txt`).
- `--only=water,tidewake`: before 437 tests, 114093 assertions, 0 failed; after 441 tests, 114150 assertions, 0 failed.

## Capture

```
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
  --resolution 1280x720 --script tools/capture_tidewake_b_current_restore.gd -- --out=<dir>
```

The tool is derived from `tb/vis` `tools/vis_capture_current_restore.gd`. It uses stand S1 over `tidal_cradle_to_salt_crown_direct_current`, with eye (472.10, 16, 1922.53) looking at (425, 0, 1920). It uses the production CameraRig/Camera3D (fov 70) at `day` time with the WorldLook clock frozen, and terrain streamed (30 settle frames plus 2 s). Frames: `S1_live_t0/t1`, `S1_restored_t0/t1` (t1 = t0 + 0.5 s shader time). `capture_log.txt` logs the pose, the applied uniforms per state and calm_scale for each frame.

Disclosed shortcuts, all inherited from the VIS tool:
- `water_currents_restored` is set and cleared through the world ledger flag store at one pose. The real settlement path is in the smoke test.
- The fixture flags are the smoke test's set plus the Salt Crown and Sluice Isle dock facts.
- The shader clock is pinned: a runtime clone of the shader replaces TIME with a uniform.
- The rig is process-disabled and the camera is posed directly.
- The trainer and HUD are hidden.
- The frames are software GL (llvmpipe, Compatibility), not a GPU or the ROG Ally.

## Code-blind judge

A fresh `claude -p --safe-mode --tools Read` ran in an isolated temp folder containing only `A.jpg`, `B.jpg` and the prompt. The frame order was randomised; the mapping is in `JUDGE_FRAME_MAP.txt` (A = live, B = restored).

**Iteration 1 verdict (`JUDGE_VERDICT.md`): PASS.**
- The judge named A as rougher and B as calmer. That is correct.
- Confidence: high.
- It said the difference is "noticeable at a glance".
- It found no other differences between the frames.

No tuning iteration was needed.
