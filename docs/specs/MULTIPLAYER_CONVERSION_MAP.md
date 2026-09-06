# Multiplayer conversion map

**Status:** Stage B lane 0.A output, 2026-09-05; the directive's M0 deliverable ("a conversion
map, not another speculative rewrite plan"). One row per system: what class of state it is,
which wave and lane converts it, and the test that proves the conversion. Update rows as lanes
land; a row is **done** only when its proving test exists, was seen red, and is green on `main`.

Sources: `docs/MULTIPLAYER_DIRECTIVE.md` §19 (risks), `docs/specs/MP_ASSUMPTION_INVENTORY.md`
(counts), `docs/specs/MP_STATE_SEAM.md` (containers), `docs/specs/MP_NET_HARNESS_CONTRACT.md`
(instrument), decisions D95–D107, and the spike reports
`ralph/reports/MP-0C-SPIKE-ENET-0905/` and `MP-0D-SPIKE-HOSTCOST-0905/` (numbers in §4).

State classes: **W** world (host-authoritative, in `WorldState`), **P** player (per peer, in
`PlayerState`), **S** session (registry, realm occupancy, sleep vote — lives only while hosted),
**T** transient (per-process runtime; never replicated as state, at most mirrored as events).

---

## 1. State and persistence

| System | Today | Class | Wave · lane | Proving test |
|---|---|---|---|---|
| Story flags (`progression_state.gd`, 55 writer sites) | one global dict | W + P by scope (D99) | 1.A data, 1.B | `test_flag_scopes`, `test_merged_progression` |
| Party, creature instances, bond, XP | `Game.party` | P | 1.B (facade) | `test_characterize_party_and_inventory` |
| Inventory, hotbar, equipped tool, equipment | `Game.*` | P | 1.B | same |
| Satiety / vitals | `Game.satiety` + `PlayerVitals` | P | 1.B | `smoke_backpack_player_eats` |
| Map fog, landmarks, dynamic markers, regions, alpha pins | `Game.map`, statics | P (per realm) | 1.B, 5.C | `test_characterize_map_state` (expected value changes), `smoke_net_fog_is_personal` |
| Realm Heart earned/placed | flags | W | 1.B, 5.B | `smoke_net_hearts` |
| Realm Heart active power | `realm_hearts._active_id` | P | 1.B | `test_character_save_format` |
| Progression feed (banners, ticks) | `static var` | P | 1.B | `test_characterize_progression_feed` |
| Day counter, clock | `Game.day`, `clock_elapsed_seconds` | W (host truth, D105) | 1.B, 2.A, 5.D | `smoke_clock_survives_a_reload`, `smoke_net_sleep_vote` |
| Placed buildings (+ chest contents in record `state`) | `Game.placed_buildings` | W | 1.B, 3.C | `smoke_net_shared_building` |
| Farm plots | `Game.farm_plots` | W | 1.B, 6.E | Cloudreach/farm smokes |
| Death satchels | `Game.death_satchels`, no owner | W with `owner` (D104) | 1.B, 3.C, 4.E | `smoke_net_satchel_is_owners` |
| Harvested / felled vegetation | bitsets + dict | W | 1.B, 3.B | `smoke_net_gather_no_duplication` |
| World pickups taken (`cache:`/`pickup:`/`tm:` flags) | flags | W | 3.B | `smoke_net_pickup_race` |
| Harvest node depletion (`harvest_node:` flags) | flag + live respawn timer | W (timer T, host) | 3.B | same |
| Once-only wilds (`wild_once_`) | flag | W | 4.B | `smoke_wild_streaming` |
| Trainer defeated / reward flags | flags | W (rewards per participant, D106) | 4.D | `smoke_net_boss_rewards_each_participant` |
| Tutorial / opening beats, home objectives, readiness | flags | P (home flags granted to all, D99) | 1.B, 5.A | `smoke_net_behind_character_joins_ahead_world` |
| Saddle fitted | flag | P | 1.B, 6.B | `smoke_net_riding` |
| Player pose, realm, pending entry | `Game.saved_player_pose`, `current_realm` | P | 1.B | `test_character_save_format` |
| World seed, world id | `Game.world_seed` | W | 1.B, 1.C | `test_world_save_format` |
| Save file | one `slot_<n>.json`, v22 | W file + P file (D100) | 1.C | `test_legacy_slot_split_never_touches_the_original`, `test_split_key_coverage_equals_v22` |
| Autosave ownership | 4 sites, any actor | host writes world, each peer its character | 2.A | `smoke_net_host_exit_saves` |
| Preferences (`free_build`, `debug_teleport`, `auto_run`) | `user://settings.json` | T (client-local) | — | unchanged |

## 2. Session, input, presentation

| System | Today | Class | Wave · lane | Proving test |
|---|---|---|---|---|
| Transport, peer registry, handshake, snapshot, reconnect, host exit | none | S (D95) | 2.A | `test_peer_registry`, `smoke_net_host_join_leave`, `smoke_net_reconnect_keeps_character`, `smoke_net_late_join_modified_world`, `smoke_net_host_exit_saves` |
| Host/Join UI, LAN beacon, Players tab | none | T | 2.B | `smoke_net_menu_controller`, `test_menu_data` |
| Local rig (Player + CameraRig + Fly + HUD) vs remote trainer | one `Player` sibling of `CameraRig`; 47 name lookups | T (D101) | 2.C | `smoke_net_movement_two_peers` + solo boot/input/traversal smokes |
| Input ownership (`input_owner.gd`) | tree-global single answer | T (one local player per process — unchanged) | — | existing menu smokes |
| Tree pause (6 panels, 36 sites) | `get_tree().paused` | T, solo-only (D102) | 2.D | `test_panels_pause_only_when_solo`, `smoke_net_menu_does_not_freeze_peer` |
| Direct `Input.*` polling (239 sites, 29 files) | reads the local device | T (each process polls for its own local player — unchanged) | — | the net harness injects real events per peer |
| Camera-keyed world subsystems (Terrain3D camera, grass, scatter collision, weather, perimeter, 23 sites) | one camera / one player | T keyed on local rig | 2.E | solo boot smokes; `smoke_collision_streaming` |
| Movement replication and host sanity validation | none | T mirrored (owner-simulated, D96) | 3.F | `test_movement_validator`, `smoke_net_movement_two_peers` |
| HUD, party strip, minimap, combat HUD | reads `Game.*` and named nodes | T (per local player) | 2.C, 4.B | existing HUD smokes |
| VFX, audio, companion reactions on remote bodies | local only | T mirrored as events | 6.D | `smoke_vfx_lifecycle`, blind judge |

## 3. Gameplay verbs and encounters

| System | Today | Class | Wave · lane | Proving test |
|---|---|---|---|---|
| World ledger (intents → validated commits → deltas) | none | W mutation path (D103) | 3.A | `test_world_ledger_races` |
| Pickups, harvest, vegetation | flags written by any actor | via ledger | 3.B | `smoke_net_pickup_race`, `smoke_net_gather_no_duplication` |
| Building placement / dismantle | `build_placer.gd` local | via ledger + spawner | 3.C | `smoke_net_shared_building` (with reload) |
| Storage chests | `storage_state.gd`, unversioned | via `storage_txn(expected_revision)` | 3.D | `smoke_net_storage_concurrency` |
| Item trading, dropped items | none | via ledger (D107) | 3.E | `smoke_net_trade` |
| Crafting stations, campfire, workbench | local, pause the tree | shared by default; local inventory | 2.D, 3.C | `smoke_craft_panel_controller` |
| Creature deployment / recall / switch | one `AllyCreature`, director-owned | P-owned body, host-spawned (D96) | 4.B | `smoke_net_deploy_two_creatures` |
| Wild clusters, streaming, respawn, aggression | keyed on one player | host-simulated on FULL_GAME collision, union of occupants (D96 amended) | 4.B | `smoke_wild_streaming`, `smoke_aggression`, S2 tick numbers |
| Combat: strikes, damage, enemy strikes, switching, fleeing | one manager, one body each side, local RNG | host-validated intents, host RNG (D96) | 4.C | `test_encounter_host_rejects_friendly_strike`, `smoke_net_shared_wild_fight`, `smoke_net_friendly_fire_is_zero`, solo `smoke_combat` + baseline tolerance |
| Catching | decided in `_on_orb_struck` locally | host re-derives and rolls; first commit owns | 4.C | `test_catch_arbitration`, `smoke_net_catch_race` |
| Trainer battles, tournament, bosses, Warden, captains | data-driven on `_enemy_owned` | shared encounter; world defeat flag once; `reward_grant` per participant | 4.D | `smoke_net_shared_trainer_fight`, `smoke_net_shared_boss`, `smoke_net_boss_rewards_each_participant` |
| Multiplayer scaling | none | data in `multiplayer.json` (D106) | 4.A, 4.F | `smoke_combat_baseline` 1/2/4 |
| Death, satchel, respawn | `player_death.gd`, immediate | downed → revive → death (D104) | 4.E | `smoke_net_revive`, `smoke_net_death_does_not_reset_encounter` |
| Story triggers, dialogue effects, NPC prompts, gates/bridges/relay/shrine restore | one panel, one player, one lockout | local dialogue; effects via ledger; deltas re-run restore | 5.A | `smoke_net_gate_opens_for_both`, `smoke_net_behind_character_joins_ahead_world` |
| Sleep, night, creature-bed rest | any actor advances the day | host vote (D105) | 5.D | `smoke_net_sleep_vote` |
| Realm transitions, multi-realm occupancy | `change_scene_to_file` | realm shells on host (D97); refused in sessions until 6.A | 2.A guard, 6.A | `smoke_net_split_realms`, `smoke_net_realm_owner_disconnect_mid_fight` |
| Riding | one mount, local | owner-simulated mount, replicated | 6.B | `smoke_net_riding` |
| Fly (incl. loaner, airspace, anchors) | local state machine | owner-simulated; anchor validated on host | 6.C | `smoke_net_fly` |
| Cloudreach chapter runtime, camps, farming | local mutations | via ledger | 6.E | Cloudreach shard |
| Late join, reconnect, portability, jitter, 3/4 peers | none | S | 7.A | `smoke_net_late_join_modified_world`, `smoke_net_character_joins_second_world`, `smoke_net_three/four_peer_session`, jittered runs |
| Solo regression, performance, owner kit, acceptance | — | — | 0.E, 7.B, 7.C, 7.D | `verify-solo-regression`, `run_all_smokes.sh`, `MULTIPLAYER_ACCEPTANCE.md` |

## 4. Numbers the spikes supplied

Filled in from the lane reports when they land; until then the harness uses the provisional
defaults in `MP_NET_HARNESS_CONTRACT.md` §8.

| Measurement | Value | Source |
|---|---|---|
| ENet RPC round trip, two headless processes on one box (min / median / max) | 4.2 / 6.9 / 40 ms loopback; reproduced by Fable at 6.8 / 6.9 / 13.8 | `MP-0C-SPIKE-ENET-0905` |
| Frames for a spawner spawn and a synchronizer update to reach a client | spawn 2–34 frames (2 in the reproduction); synchronized position 2–3 frames; ~143 MB RSS per bare peer process; 1 host + 3 clients in 4.1 s | same |
| `OS.create_process` inherits `XDG_DATA_HOME` from the parent | yes, and `OS.set_environment` before the call is honoured; reap by polling `OS.is_process_running` | same |
| One / two / four concurrent headless Meadows boots: wall-clock and peak RSS | 50–60 s warm, 84 s cold, flat across 1/2/4-way; 3.2 GB VmHWM each, **12.85 GB** for four | `MP-0D-SPIKE-HOSTCOST-0905` |
| Host physics-frame cost with clusters active around 1 / 2 / 4 occupants | active wild bodies 8 → 15 → 23 (sub-linear, production streaming); frame-time delta below the box's noise (20–27 ms band) | same |
| 40 wild bodies: `move_and_slide` vs heightfield-grounded | heightfield via `.call()` is **+11 ms median** (twice); D96 amended — host uses FULL_GAME collision instead | same |
| Simulation-only Meadows shell: RSS and frame time vs full boot | post-hoc free: −30 % median frame time, −1.2 % memory (floor; vegetation/terrain untouched); D97 amended — skip-build flag, re-measured in Wave 6 | same |
| Terrain3D full collision: RSS delta; runtime camera re-target builds collision elsewhere: yes/no | FULL_GAME: +16.1 MB, 3.06 s, whole map; re-targeting `set_camera` builds collision at the new spot within 180 frames | same |
| CI budget: 2-peer smoke wall clock on a 4-vCPU runner; 3/4-peer off-CI | 2-peer: 300 s budget (cold boot ~85 s × 2 + steps); 3/4-peer nightly and owner kit only (12.85 GB leaves no margin on a 16 GB runner) | same |

## 5. Directive §19 risks, each with an owner

| Risk named in the directive | Row(s) above |
|---|---|
| global `Game` combines world and player state | §1 all rows; D98 |
| current save combines world/player persistence | Save file; D100 |
| player/world input assumes one local player | Input ownership, direct polling — unchanged by design (one local player per process) |
| several UI panels pause the scene tree | Tree pause; D102 |
| combat managers may assume one active controlled creature | Combat; D96 |
| EncounterDirector may assume one encounter owner | Wild clusters, Creature deployment; D96 |
| SequenceDirector/story triggers may assume one triggering player | Story triggers |
| map/progression assumes one viewer | Map fog; Story flags |
| building/storage do not currently need concurrency controls | Building, Storage; D103 |
| world/visibility architecture designed around one camera | Camera-keyed subsystems; D101 |
| riding/Fly authority is currently single-player | Riding, Fly |
| autosave ownership is currently singular | Autosave ownership; D100 |
| terrain/scatter/culling must cope with separated players | Camera-keyed subsystems, Realm transitions; D96, D97 |
