# F14#2: the current network visibly changes and persists

Criterion: ACCEPTANCE §6.1 F14, "the water/current network visibly changes and persists".
Test: `tests/smoke_tidewake_b_current_restore.gd`, branch `tb/tidewake-b-f14-2-current-restore`.
Commit: the evidence commit on this branch; the PR evidence table gives the full SHA.
This change touches no product code. It adds one test and this evidence.

## Commands

```
# headless (numeric proof, CI-safe)
XDG_DATA_HOME=$(mktemp -d) godot --headless --path . --script tests/smoke_tidewake_b_current_restore.gd
# rendered (adds before/after PNGs; Compatibility renderer on llvmpipe under xvfb)
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --resolution 1280x720 \
  --script tests/smoke_tidewake_b_current_restore.gd -- --capture=<dir>
```

Godot 4.7 in the Linux container. Results: `headless_result.txt` (20 checks, 0 failures) and `render_result.txt`.

## 1. The flag comes from the real freeing path

Fixture, stated in the test header. `water_guardian_freed` is set, together with the four earlier dock facts and `water_aquaryn_resolved`. Those docks are opened long before the Veilfall in any real run. With them set, the sampled current is an ordinary open route rather than a closed-gate tide race.

The test never writes `water_currents_restored`. The player is placed at the freed Guardian prompt. The production chamber's Decline is pressed and then confirmed with a second press after the 500 ms guard (`water_veilfall.gd request_guardian_decline()`). That calls `water_guardian_reward.gd refuse()`, which appends the one-time `SETTLEMENT` flags.

The test checks that the flag is absent before the confirm and present after it. It also checks that the flag is in the world journal on disk (`save_system._worlds.read(world_id)`).

The accept route (invite, then roster farewell) publishes the same flag. That route is covered by the existing `tests/smoke_water_guardian_ceremony.gd`, which asserts the flag in memory and in the world journal.

## 2. The visible and physical change (numbers from the production scene)

| | `WaterVeilfall/WaterCurrentFlow` shader `calm_scale` | `water_world.current_at((425, 0, 1920))` speed, Tidal Cradle to Salt Crown direct |
|---|---|---|
| before settlement | 1.000 | 1.3000 m/s |
| after settlement (the view polls once per 1 s) | 0.500 (= `current_flow.restored_calm_scale`) | 0.3250 m/s (× `post_liberation_strength_multiplier` 0.25) |
| after save, reset and reload into a rebuilt scene | 0.500 | 0.3250 m/s |

What `calm_scale` 0.5 does in `shaders/water_current_flow.gdshader`:

- It halves the streak drift speed.
- It multiplies the ribbon mask by mix(0.55, 1, 0.5) = 0.775. The foam and lane become about 22 % less opaque.

## 3. Persistence

`tests/helpers/water_chain_reload.gd` runs the title-screen Continue order:

1. production `Game.save_game(1)`
2. destroy the Water scene
3. `reset_for_new_game()`, which is checked to have dropped the flag
4. `Game.load_game(1)`
5. instantiate a new `water_archipelago.tscn`

On the rebuilt world, all three hold:

- the flag is present;
- the new WaterCurrentFlow is built with `calm_scale` 0.5;
- `current_at` returns the same calm 0.325 m/s.

## Captures

The rendered run passed all 24 checks, including the four capture checks (`render_result.txt`). It ran on the Compatibility renderer under xvfb on llvmpipe (Mesa software rendering), and the JPGs were converted from 1280x720 PNGs. Frames:

- `overview_before.jpg`
- `shore_before.jpg`
- `overview_after_reload.jpg`
- `shore_after_reload.jpg`

**Verdict, stated plainly: the visible change is NOT proven by these frames.**

- In both "before" frames the sea around the Tidal Cradle → Salt Crown current shows no readable WaterCurrentFlow foam ribbon. The only white marks are the gate-seal race effects near the shores.
- The "after_reload" frames are not comparable. In the rebuilt world, terrain streaming had not loaded the islands around the fixed pose: the overview shows open sea, and the player was frozen away from the load anchor. Neither after frame shows ribbons either.
- The restored change is only half the drift speed and about 22 % less opacity. It would be subtle in a still frame even if the ribbons were readable.

What is proven is the state behind the view: the shader parameter, the physics and persistence.

Per coordinator/owner direction (visuals ceded to Codex), I did not change the ribbon look. The gap is filed as row **W1** in `ralph/reports/VISUAL/AUDIT.md`. The code-blind judge should treat F14#2's "visibly" as open.

## Honest limits

- The fixture pre-sets `water_guardian_freed` and the five earlier gate facts; the Nerissa and Guardian fights themselves are not replayed here.
- The settlement route shown is the Decline. The Accept route's flag and journal write are covered by `smoke_water_guardian_ceremony.gd`, not by this test.
- The captures use the production `CameraRig/Camera3D` node with its production fov, far plane and environment. Its rig follow logic is paused, and it is posed at a fixed eye/target with the WorldLook clock frozen at "day". This is not a rig-driven gameplay framing.
- The "after" frames come from the reloaded world. Their terrain had not streamed in, so the pose comparison fails; see Captures.
- Local rendering is software llvmpipe. The `render.yml` workflow_dispatch (mode=render) was not dispatched.
- Civilian dock exchange and the departure scene (WORLD regional conclusion) are not built, and are not claimed here.
