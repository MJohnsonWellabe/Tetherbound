# MP state seam — the World/Player split that lane 1.B implements

**Status:** Stage B lane 0.A output, 2026-09-05. This is the contract for Wave 1 lane 1.B (Opus)
and the reference for 1.C (save split). It fixes *what* the containers hold, *how* the existing
`Game.*` surface keeps working, and *which* flag goes where. Decisions behind it: D-MP4, D-MP5,
D-MP6 in `docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` §3. Raw material:
`docs/specs/MP_ASSUMPTION_INVENTORY.md` (§1 field usage, §8/§8b flag writers).

Rule of the seam: **the pure modules do not change.** `party.gd`, `inventory.gd`,
`creature_instance.gd`, `item_db.gd`, `player_equipment.gd`, `quest_log.gd`, `day_cycle.gd`
keep their APIs. What changes is who *holds* them.

---

## 1. Containers

### `autoload/world_state.gd` — `WorldState` (`RefCounted`)

What has happened to this world. One per hosted world; the host's is authoritative, every peer
holds a replica that only `apply_delta()` (Wave 3) may mutate.

| Field | Type | Today on `Game` | Notes |
|---|---|---|---|
| `world_id` | `String` | — (new) | Stable id minted on New World; the world save's directory name. |
| `world_seed` | `int` | `world_seed` | |
| `day` | `int` | `day` | Host truth from Wave 2. |
| `clock_elapsed_seconds` | `float` | `clock_elapsed_seconds` | `CLOCK_UNSET` sentinel kept. |
| `flags` | `ProgressionState` | the world half of `progression` | World-scoped ids only (§3). |
| `placed_buildings` | `Array` | `placed_buildings` | Records unchanged; chest `state` stays inside the record. |
| `farm_plots` | `Array` | `farm_plots` | |
| `death_satchels` | `Array` | `death_satchels` | Each record gains `owner: <character_id>` (D-MP10); `realm_world_records.normalized()` stamps `owner: ""` on legacy records. |
| `harvested_vegetation` | `Dictionary` | same | |
| `felled_vegetation` | `Dictionary` | same | |
| `revision` | `int` | — | Bumped on every mutation; the merged progression view sums it. |

Methods moved verbatim from `game_state.gd`: `register_building()`, `register_death_satchel()`
(new `owner` and explicit `realm` parameters — no read of `current_realm`), `farm_plot_at()`,
`set_farm_plot()`, `advance_day()` (the counter half; the tree side effects stay in `Game`),
`save_data()` / `load_data()` (the world half of today's `save_game.gd` dict, §4).

### `autoload/player_state.gd` — `PlayerState` (`RefCounted`)

This trainer and team. One per peer; the local one is `Game.local`; the host also holds every
connected peer's in `Game.players`.

| Field | Type | Today on `Game` | Notes |
|---|---|---|---|
| `character_id` | `String` | — (new) | Stable id minted on New Character; the character save's directory name. |
| `display_name` | `String` | — | Nameplate. |
| `party` | `Party` | `party` | Unchanged module. |
| `inventory` | `Inventory` | `inventory` | |
| `equipment` | `PlayerEquipment` | `player_equipment` | Still not persisted, by existing design. |
| `hotbar` | `Array[String]` | `hotbar` | Item ids, as today. |
| `equipped_tool` | `String` | `equipped_tool` | Not saved, as today. |
| `satiety` | `float` | `satiety` | |
| `pose` | `Dictionary` | `saved_player_pose` | `{realm, position, model_yaw, camera_yaw, camera_pitch, traversal}` |
| `realm` | `String` | `current_realm` | **Per player from now on**: which realm this peer is in. |
| `pending_realm_entry` | `String` | `pending_realm_entry` | |
| `flags` | `ProgressionState` | the player half of `progression` | Player-scoped ids only (§3). |
| `maps` | `Dictionary[String → MapState]` | `_realm_map_instances` | Fog, landmarks, dynamic markers, regions **and alpha pins**, per realm. |
| `hearts` | `RealmHeartState` | `realm_hearts` | Its `_active_id` is the player's; `is_earned/is_placed` read **world** flags (pass `Game.world.flags`). |
| `feed` | `ProgressionFeed` | the static `progression_feed.gd` | Becomes an instance (§2). |
| `pending_catch` | `RefCounted` | `pending_catch` | Never saved, as today. |
| `pending_build` | `String` | `pending_build` | |
| `objective_text`, `objective_hint` | `String` | same | Derived per player by `quest_log`. |
| `quest_log` | `QuestLog` | `quest_log` | Reads the merged view (§2), so main entries see world flags and local entries see player flags. |

Methods moved: `hotbar_can_hold/assign_hotbar/hotbar_slot_of/autofill_hotbar`, `make_creature()`
(the party half), `bind_realm_map()/ensure_realm_map()` → `map_for(realm)`, `save_data()` /
`load_data()` (the character half, §4).

### `Game` keeps

`items` (immutable `ItemDB`), `save_system` (replaced by two savers in 1.C), preferences
(`free_build`, `debug_teleport`, `auto_run` — client-local settings, not state), the menu mount,
`_process` ticking, the four tree-sync seams (`_sync_placed_building_state`, `_sync_death_satchel_state`,
`_sync_harvest_state`, `_sync_clock_state` — now writing into `world`), `find_player()` promoted
to `local_player()` (same search until 2.C rebinds it to the local rig), and the new
`world: WorldState`, `local: PlayerState`, `players: Dictionary[int → PlayerState]` (host: every
peer including itself under peer id 1; client: only itself).

---

## 2. The forwarding facade — no call site breaks

Every property the inventory's §1 lists stays readable and writable on `Game` with the same
name and type. Implemented as GDScript property accessors (`var party: RefCounted: get = _get_party`
or an explicit getter/setter pair), each a one-liner into `local` or `world`:

| `Game.<x>` | Forwards to | Direction |
|---|---|---|
| `party`, `inventory`, `player_equipment`, `hotbar`, `equipped_tool`, `satiety`, `saved_player_pose`, `pending_catch`, `pending_build`, `objective_text`, `objective_hint`, `quest_log`, `realm_hearts`, `map` | `local.<x>` (`map` → `local.map_for(local.realm)`) | read/write |
| `current_realm`, `pending_realm_entry` | `local.realm`, `local.pending_realm_entry` | read/write |
| `day`, `clock_elapsed_seconds`, `world_seed`, `placed_buildings`, `farm_plots`, `death_satchels`, `harvested_vegetation`, `felled_vegetation` | `world.<x>` | read/write (writes are refused on a client from Wave 3 — until then they pass through) |
| `progression` | `MergedProgression` (below) | read; `set_flag` routes |

**`MergedProgression`** (`autoload/merged_progression.gd`, `RefCounted`), constructed once by
`Game` over `(world.flags, local.flags)`:

- `has(id)` / `completed(id)`: true if either store has it. (A world flag can never collide with
  a player flag by construction of the scope table, so "either" is exact.)
- `set_flag(id, value := true)`: `scope_of(id)` → write to `world.flags` or `local.flags`.
  `scope_of` returning `""` is a `push_error("unscoped flag: %s" % id)` **and** a write to
  `world.flags` so the game does not stall; `test_flag_scopes.gd` guarantees that path is never
  taken by shipped data.
- `all_set()`: union.
- `revision`: `world.flags.revision + local.flags.revision` — the existing `Game._process` poll
  redraws the objective line on either store moving.
- `save_data()` / `load_data()`: **not provided**; callers that want to persist go through the
  two savers. A call is a `push_error` so a missed site is loud.

`progression_feed.gd` loses its `static var`s: the five statics become instance fields, the
static methods become instance methods, and `Game.push_progression_event()` /
`progression_feed_revision()` / `peek_progression_events()` / `take_progression_events()` forward
to `local.feed`. The pure helpers (`xp_remaining`, `xp_near`, `xp_fraction`, `tick_verb`,
`level_up_changes`, `moment_text`, `is_moment`, `is_tick`) may stay static; they read config only.

`map_state.gd` loses `static var _grid_x/_grid_z/_origin`: the extent becomes instance fields
set by `configure()` (Meadows) or `configure_cloudreach()` (Cloudreach). `cloudreach_map_state.gd`'s
overrides of `cell_grid_x/cell_grid_z/cell_size/world_to_cell/cell_at` then collapse to setting
those fields. `alpha_pins` move from a top-level save key into each `MapState`'s `save_data()`
under `alpha_pins` (1.C's migration moves the key; `alpha_pin_save_data()` stays as the accessor).

The three `static var _panel` singletons (`death_satchel.gd:38`, `storage_container.gd:20`,
`creature_bed.gd:366`) are fine as-is: one process has one local player and one panel.

---

## 3. Flag scopes

`data/progression/flag_scopes.json`:

```json
{
  "_comment": "Every story flag id is world or player. Prefixes end with ':' or '_'. An id matching nothing is a test failure.",
  "world": { "ids": [...], "prefixes": [...] },
  "player": { "ids": [...], "prefixes": [...] }
}
```

`progression_state.gd` gains `static func scope_of(id: String) -> String` (exact id first, then
longest matching prefix, else `""`) and the table is loaded once. `objectives.json` entries gain
`"scope": "world" | "player"` and `test_flag_scopes.gd` asserts each entry's `flag_id` and
`retired_by` agree with the table.

The table Fable settled (lane 1.A enters it; anything a later lane finds is added under the same
rule, never defaulted):

| Scope | Ids and prefixes | Why |
|---|---|---|
| **world** | `defeated_warden`, `legendary_freed`, `legendary_settled`, `south_bridge_open`, `road_gate_open`, `hall_approach_open`, `realm_key_cloudreach`, `realm_gate_cloudreach_unlocked`, `realm_heart_meadows_earned`, `realm_heart_meadows_placed`, `tournament_won`, every trainer `defeat_flag` and `TRAINERS.reward_flags()` id, every `item_gate.gd` `flag_id`, every `realm_gate.gd` `unlock_flag`, the relay `console_flag()` ids, `river_nest_clear.gd`/`cart_repair.gd` `MET_FLAG`, `meadow_healing.gd` flags, the Warrens prize and clear flags, Cloudreach `physical_state_flags` and captain defeat flags. Prefixes: `cache:`, `pickup:`, `tm:`, `harvest_node:`, `wild_once_`. | Something happened to the world once. Rule 2, 5, 6. |
| **player** | `tournament_team_ready`, `tournament_training_ready`, `tournament_condition_ready`, `tournament_team_fed`, `tournament_entered`, `tam_tools_given`, `player_slept_at_home`, `home_built`, `home_materials_gathered`, `creature_bed_built` and `creature_bed_built_<n>`, `legendary_joined`, `alpha_pins.gd` `INTRO_FLAG`, `swap_panel.gd` `CREATURE_TRADE.swap_flag`, every `riding_controller.saddle_fitted_flag(species)`. Prefixes: `opening:beat:`, `cloudreach_payout:`. | Tutorial, personal readiness, personal payoffs. Rules 3, 14. `home_*`/`creature_bed_*` are **granted to every connected peer** when the world gains the pieces (D-MP5); until Wave 3's `grant_player_flag` exists, solo writes them to the local store exactly as today. |

Writer sites that must name a store explicitly rather than go through the merged view, because
the *actor* is not the local player (1.B edits these): `night_rest.gd:77` (`player_slept_at_home`
for each sleeper — host-side from Wave 5; local until then), `home_progress.gd:138/193/208`
(grant-to-all), `stronghold_climax.gd:922/941` (`legendary_joined` into the party-owner's store),
`realm_heart_state.gd:60` (`place()` writes a world flag: pass `Game.world.flags`, not the merged
view, so a client cannot write it locally from Wave 3).

---

## 4. Save partition (for 1.C)

Today's `save_game.gd` v22 keys, partitioned. The key-coverage test asserts union = v22 set,
intersection = ∅, and that every key below is produced by exactly one saver.

| v22 key | Goes to | Note |
|---|---|---|
| `version` | both | Each file has its own `version`, starting at 1. |
| `day`, `clock_elapsed_seconds`, `world_seed`, `placed_buildings`, `farm_plots`, `death_satchels`, `harvested_vegetation`, `felled_vegetation` | **world.json** | `death_satchels[i].owner` added, `""` on migration. |
| `progression` | **split by scope** | `world.json: flags`, `character.json: flags`. |
| `party`, `inventory`, `hotbar`, `satiety`, `player_pose`, `current_realm` (→ `realm`), `pending_realm_entry`, `realm_hearts`, `realm_maps`, `alpha_pins` (→ inside each realm map), `map` (legacy alias → dropped after migration, the realm map is canonical) | **character.json** | |

`world.json` additionally carries `world_id`, `display_name`, `created_at`, `last_played`;
`character.json` carries `character_id`, `display_name`, `last_world_id`. Legacy split: on
loading a `user://saves/slot_<n>.json` the loader writes
`user://worlds/legacy-slot-<n>/world.json` and `user://characters/legacy-slot-<n>/character.json`,
**leaves the original byte-identical**, and records `migrated_from: slot_<n>` in both. The title
screen lists legacy slots under a "Legacy saves" heading until they are opened once.

Autosave ownership: `Game._tick_autosave()` and the rest/realm autosaves call
`save_world()` **only if `Session.is_host()`** (always true solo) and `save_character()` always.
Until 2.A exists, `is_host()` is a stub returning true.

---

## 5. What 1.B must prove

1. `tests/test_characterize_*.gd` from lane 0.E: each is broken deliberately once on the new tree
   and seen red for its reason, then green. The `map_state` static-extent test is the one whose
   expected value **changes** (two instances no longer share the extent); that change is the
   evidence the hazard is gone.
2. `tests/test_flag_scopes.gd`: every id in `objectives.json`, `trainers.json` (`defeat_flag`,
   reward flags, `victory_conversation`-adjacent flags), the pickup/harvest/gate prefixes and the
   38 + 17 writer sites in the inventory §8/§8b resolves to `world` or `player`; the test enumerates
   the writer-site literals from a fixture list it keeps beside the table.
3. `tests/test_merged_progression.gd`: `has` sees both stores; `set_flag` routes by scope; an
   unscoped id pushes an error and lands in world; `revision` moves when either store moves.
4. Full unit suite green; `verify-solo-regression`'s 46 smokes green on first attempt;
   `tools/run_all_smokes.sh` on the lane head with its summary in the report, every red explained.
5. No player-facing behaviour changes in solo. The report lists every place a forwarding property
   was bypassed for an explicit store, with the reason.
