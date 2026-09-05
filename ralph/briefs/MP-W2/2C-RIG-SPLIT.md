# Lane 2.C — Per-peer rig and remote trainers (Opus)

**Base:** the Wave 2 branch after 2.A lands. **Contracts:** decision D101, D97's authored spawn
containers, plan row 2.C, the ENet spike's spawn/authority rules
(`ralph/reports/MP-0C-SPIKE-ENET-0905/`), inventory §2 (player-name lookups) and §5 (camera
sites) in `docs/specs/MP_ASSUMPTION_INVENTORY.md`. Read `ralph/briefs/MP-W1/COMMON.md`.

**Player-visible outcome.** Two people on a LAN see each other walk around the Meadows: a
remote trainer body with the right model, animation state and a nameplate, interpolated
smoothly; each peer's own camera, HUD and input behave exactly as solo does.

**Files you own:** new `scenes/player/local_rig.tscn` (Player + CameraRig + FlyController +
HUD binding) and `scenes/player/remote_trainer.tscn` (model, animation state, nameplate,
`MultiplayerSynchronizer`), both world `.tscn` files (replace the `Player`/`CameraRig` siblings
with the rig; author `Spawned/Trainers`, `Spawned/Creatures`, `Spawned/Items` containers and a
`MultiplayerSpawner` per container), `scripts/world/playground_world.gd` and
`cloudreach_world.gd` (rig wiring, `set_camera` from the local rig), every exported `*_path`
that pointed at `Player`/`CameraRig` (`encounter_director`, `sequence_director`,
`riding_controller`, `interaction_arbiter`, `world_weather`, `playground_hud`),
`scripts/world/interactable.gd` (LOS exclusion uses the local rig, not `_arbiter._player`),
the name-lookup sites in inventory §2 (route through `Game.local_player()` or the
`local_player` group), `scripts/net/trainer_spawn.gd` (host spawns a trainer per peer with
authority set inside `spawn_function` before tree entry), `tests/smoke_net_movement_two_peers.gd`,
and your report. **Do not** touch `combat_manager.gd` or the ally-creature paths (4.B).

**Deliverables.** The rig; the remote scene; host-spawned trainers on join and despawn on leave;
synchronizer set = position, yaw, animation state, sprint, carried; interpolation on remotes;
nameplate from the registry's display name; every camera-keyed subsystem reads the local rig
(coordinate with 2.E — it owns `grass_field.gd`, scatter streaming, weather, perimeter,
minimap wiring; you own the rig they read). Tolerance numbers fixed here: a remote is
"seen" within **1.5 m at rest, 4.0 m in motion** of the owner's reported position
(`multiplayer.json` `test_budgets`).

**Proof.** `smoke_net_movement_two_peers.gd` (# peers: 2): both peers walk 20 m with `stick`;
each probes its own position and the other's remote-body position; assert within tolerance;
nameplates present; hashes equal; negative control against the previous wave head. Solo:
`smoke_playground`, `smoke_input`, `smoke_traversal`, `smoke_mouse_look`, `smoke_combat_camera`,
`smoke_cloudreach_arrival_walk`, `smoke_gate_b_continuous` (core) green first attempt; the
`^ERROR:` set unchanged.
