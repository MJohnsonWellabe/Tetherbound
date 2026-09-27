# Cloudreach route stalls: root causes (Cloudreach-B)

The stalls were diagnosed at `a307e0f9`. All three are product bugs in files the main Cloudreach lane owns; Cloudreach-B changed no product file. The probes are in `probes/`. Run each from the repo root:

```
XDG_DATA_HOME=$(mktemp -d) godot --headless --path . --script ralph/reports/CLOUDREACH/b/route-stall-root-causes/probes/<file> -- --mode=<shrine|b2>
```

The build uses Godot's default 3D physics, not Jolt.

## 1. Shrine-dais stall (the stall in F06#3's disclosed failed run): corner trap at the west SkyPillar

- **Geometry.** `scripts/world/cloudreach_world.gd:4216-4219` builds each `SkyPillar` as a 2.2 m collision box, running from the ground up through the dais top. The west pillar spans x 1099.4–1101.6 and z 2941.4–2943.6.
- **Where the player is caught.** The trainer's 0.4 m capsule stands on the dais at (1099.003, 1051.301, 2941.399). That is 0.4 m from the pillar's west face and 0.001 m (the safe margin) outside its south face.
- **What fails.** From that point, any horizontal move with an x component is swept into a hit on the Dais top, with normal (0,1,0), almost at once. `move_and_slide` slides along a floor normal, which changes nothing, and repeats six times. The result is zero motion, velocity unchanged, and `is_on_wall()` false.
- **Why nothing frees the player.** All of the controller's escape paths need a wall or a sealed box, so the player stays stuck for good:
  - `_try_step_up` returns early without `is_on_wall()` (`scripts/player/player_controller.gd:520-521`).
  - `_unwedge` returns early without `is_on_wall()` (`:474`).
  - `_entombed_at` is false, because other directions are clear.
- **Reproduction.** The probe drives the recorded stick at the recorded position:
  - 300 of 300 frames give zero motion, `wall=false` and six floor contacts. Velocity is (4.957, 0, -0.653), matching the failing run exactly.
  - From that spot, motion toward the target, +x, -x and diagonal +x-z are all blocked by `Dais/Collision` n=(0,1,0). Only -z is free.
  - The same moves lifted 0.35 m are all free.
  - Cutting the pillar to start at the dais top leaves it still stuck (240/240 frames).
  - Swapping the pillar for a cylinder walks to the target.
- **Why the F06#2 exhausted-fall launch fails.** The same pillar overlaps the Fly companion's launch shape at the landing spot. The launch probe names `Landmarks/SkyShrineHeartstone/SkyPillar/Collision` and refuses with "Find a clear launch with room for your companion overhead."
- **Proposed fix (player controller).** Let `_try_step_up` also run when a grounded slide made less than `UNWEDGE_PROGRESS` of its planned horizontal motion, not only against a wall. The probe shows the raised 0.35 m sweep is clear. The step-up stays fully swept, so no barrier becomes passable.
- **Fallback fix.** Build the two `SkyPillar` colliders as cylinders.

## 2. B2: the `ravine_wind` wild pair stands on the Windscar road without the trainer-corridor exemption

- **Placement.** `data/config/cloudreach_encounters.json:273-284` places `ravine_wind`, at (220, 556, 3333), on the `windscar_floor_loop` segment (373, 610, 3262)→(120, 520, 3380). Its `_why_flight_aerie_composition_0911` note says this was deliberate.
- **The pair.** `ravine_wind_0` is a Galecrest with radius 1.08. `ravine_wind_1` is a Cloudfang with radius 1.35. They wander within 8 m of home, leashed, and freeze to face a trainer within 9 m (`scripts/creatures/wild_creature.gd:217-223`). So they stand still in the lane.
- **Missing exemption.** Other road-sited wild pairs stop colliding with the trainer through `keep_trainer_corridor_clear` (`scripts/combat/cloudreach_encounter_director.gd:243`). That is applied only when a site carries the comment key `_why_road_visibility_0907` (`:402-404`). `ravine_wind` lacks that key, so it collides.
- **Why the walk failed.** The road is more than 20 m wide there, so room is not the problem. The harness detour most likely failed because the second body of the pair, 2.4 m away, pinned the 2.2 m tangent arc.
- **Proposed fix (encounter director and data).** Key the corridor exemption on an explicit site field rather than a comment key, and set it for `ravine_wind`.

## 3. B3: `roost_perches` resolves 1.5 km away, onto the Voss summit road

- **Resolution path.** `cloudreach_world_runtime.gd:201-203` (`resolved_encounter_data`) passes each wild site through `_resource_position` (`scripts/world/cloudreach_world.gd:2429`).
- **Wrong fallback.** The authored spot for `roost_perches`, (970, 1050, 3450), has no ground: `ground_height_near` returns NaN. The fallback then binds the site to the nearest route surface anywhere on the map, which is (503.2, 986.06, 4891.1) on the Voss summit road.
- **Not a leash failure.** The wild's home is set there too. The committed `cadence-f07/runtime_upper_before.txt:100` shows `blocker_home` (502.2, 986.5, 4891.1). The leash is working correctly and holds the pair at a wrong home, where it collides without a corridor exemption.
- **Proposed fix (data and resolution).**
  - Re-author `roost_perches` onto real High Roost ground. The probe found ground height 1020.0 at the `high_roost_perches` landmark (900, 1020, 2700).
  - Make wild-site resolution fail closed when the result lands more than about 45 m from the authored spot.
  - Add a test that every wild site resolves near its authored position.

## 4. B1: the lower-west shelf (not re-probed)

`LowerOverlookLoopCliffShoulders/Ridge002RockShoulder38/VegetatedGeologicalShelf2` at (-128.4, 205.5, 704.5) has overhanging collision (normal about (0.01, -0.48, -0.88)) across the arrival route to `lower_west_anchor`. See `../blocker-lower-west/README.md`.
