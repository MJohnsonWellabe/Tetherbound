# Continuous Through Bridge 01 — failed

Run: `.artifacts/broad-visual-0910/runs/continuous-through-bridge-first`

The root wrapper records UTC `2026-09-10T05:44:13.2634608Z` through
`2026-09-10T05:55:52.6076237Z`, with `exit_code: 1`, `errors: []`, and arguments
`--headless --script tools/probe_continuous_aim_lifecycle.gd -- --through-bridge`.
The campaign result reports `elapsed_seconds: 688.294`. `engine.log` contains no
`ERROR`, `SCRIPT ERROR`, `push_error`, or assertion lines. `stderr.log` contains
only the `instance_reset_physics_interpolation() is deprecated` warning.

## Observed execution

- The opening path completed through the live Bramblebun catch, village key
  gate, and exploration handoff. The NPC/gather path also completed: axe,
  pickaxe, and knife each returned `+4` of the expected resource, and world
  control returned after the NPC/modal exits.
- `FRESH STAGE ENTRY stage=materials` was reached at frame `27975`.
  Two wood interactions credited `+3` each, taking earned wood to `10/18`.
- The next target was `Vegetation/@Node3D@45616` at
  `(78.98997, -2.175245, -44.09865)`. At frame `35525`, the materials stage
  returned failure: `wood swing credited nothing`; the arbiter winner was
  `Interactable#1592560501437 @(79.5, -45.4)` while the requested target was
  `Interactable#2675966066422 @(79.0, -44.1)`, with axe equipped and node stock
  `3`.
- The final result is `campaign_complete:false`, `requested_prefix_passed:false`,
  `reached:"earned_team"`, and `failures:["wood swing credited nothing ..."]`.
  No `stage=camp`, `stage=rest`, tournament, or bridge traversal proof appears
  after the materials failure. `south_bridge_dressing placed 1 of 1` is a world
  dressing placement, not traversal proof.

The scratch save was held at
`C:/Projects/Tetherbound/.artifacts/broad-visual-0910/runs/continuous-through-bridge-first/profile/Godot/app_userdata/Tetherbound/four_biome_fresh_16060_2595`
(`user://four_biome_fresh_16060_2595/slot_0.json`). This report records the
failure only; it does not infer a source fix. The wood failure remains with the
Sol `creature_pipeline` lane for diagnosis.

## AIM lifecycle

Across 43 `AIM LIFECYCLE` records: `aim_entered=7`, `aim_exited=7`,
`orb_struck=7`, and state transitions `0→1`, `1→2`, `2→0` occurred seven times
each. There were zero `menu_cancel.just_pressed`, zero `menu_cancel.pressed`,
zero `throw_refused`, and zero `orb_missed` records. Each aim exit proceeded to
an orb strike; no old-aim-cancellation recurrence appears in this log.

## Coverage limit

The run's coverage summary is `complete_coverage:false`, with
`observed_travel_m:1685.18775552402`, `samples:155`, `below_two_samples:121`,
and `undersampled_intervals:1`. It explicitly cautions that counts describe
observed travel only; indoor/road membership is unknown and unvisited routes
remain unproved.

