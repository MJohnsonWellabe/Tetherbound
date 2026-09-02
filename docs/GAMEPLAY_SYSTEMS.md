# Tetherbound Gameplay Systems — Source of Truth

Status: consolidated reference, drafted from a code+data inventory pass (read-only,
no engine run). One system per section: the rule it implements, the key scripts,
the data that tunes it, the input actions, and the tests that cover it. Read this
before touching any of these systems. Where the underlying inventory could not
trace a claim, this document says "not yet documented" rather than guessing.

Architecture note that applies to every section below: there is exactly one
autoload, `Game` (`autoload/game_state.gd`, `project.godot` line 38, comment:
"the project's one singleton"). It composes five plain (non-autoload) classes —
`autoload/party.gd`, `autoload/inventory.gd`, `autoload/item_db.gd`,
`autoload/progression_state.gd`, `autoload/map_state.gd`. The Meadows is one
continuous scene (`scenes/world/meadows_playground.tscn`, root script
`scripts/world/playground_world.gd`), not a set of discretely loaded regions;
"regions" are Z-axis corridor bands whose per-band JSON is merged at boot by
`scripts/data/band_content.gd`.

---

## Movement / camera

- Rule: controller-first (CLAUDE.md hard rule); Palworld-style control parity (D35).
- Scripts: `scripts/player/player_controller.gd`, `scripts/player/camera_rig.gd`
  (SpringArm3D-based), `scripts/player/player_vitals.gd`.
- Data: `data/config/movement.json` (walk speed etc.).
- Input actions: `move_forward/back/left/right` (or `move_*`), `look_*`, `jump`,
  `sprint`, `auto_run`.
- Tests: not itemized separately in the inventory pass beyond smoke coverage
  implied by world-boot smokes; no dedicated `test_player_controller.gd` found —
  not yet documented.

## Interaction

- Rule: a single input-owner arbitration group prevents world verbs from firing
  while a menu/dialogue owns input (see Softlock guard below).
- Scripts: `scripts/world/interaction_arbiter.gd`, `scripts/world/prompt_arbiter.gd`,
  `scripts/world/interactable.gd` (base class), `scripts/ui/input_owner.gd`
  (shared `&"input_owner"` group contract).
- Wiring: `InteractionArbiter` node in `meadows_playground.tscn`.
- Input actions: `interact`.
- Tests: not yet documented (no dedicated interaction test file identified).

## Dialogue

- Rule: D43 — dialogue writes flags, and recipes are gated by them. Linear
  lines only; comments in the data explicitly state a "no-branching rule."
- Scripts: `scenes/ui/dialogue_panel.tscn` + `scripts/ui/dialogue_panel.gd`,
  a `dialogue_runner.gd`, and the effect interpreter
  `scripts/story/sequence_director.gd` (`_drain_effects()`).
- Data: `data/dialogue/opening.json`, `village.json`, `trainers.json`,
  `relay.json`, `stronghold.json`, `meadows_freed.json`, plus per-band files
  under `data/dialogue/bands/`. Effect DSL: `give:<item>:<n>`, `flag:<id>`,
  `shop:<goods|creatures>:<vendor>`, `battle:<trainer_id>`.
- Content: 130 conversations, 339 lines total (summed across all dialogue JSON).
- Tests: `tests/test_dialogue_runner.gd`, `tests/test_band_dialogue.gd`,
  `tests/smoke_dialogue_clears_the_world_hud.gd`.

## Objectives / quest direction

- Rule: linear "next thing to do," not a branching quest tree — matches the
  Meadows-as-corridor structure (D50-the-meadows-is-a-corridor-not-a-square).
- Scripts: `scripts/world/quest_log.gd` (`guided_entries()`, `current_index()`).
- Data: `data/progression/objectives.json` — 27 "main" entries, 6 "local"
  entries (33 total).
- Wiring: `Game.set_objective()` (`autoload/game_state.gd:713`).
- Tests: `tests/test_quest_log.gd`.

## Wild encounters

- Rule: no hard rule directly names encounters; escalation follows the
  chapter progression curve (`docs/specs/MEADOWS_PROGRESSION_CURVE.md`,
  `data/config/chapter_curve.json`).
- Scripts: `scripts/combat/spawn_tables.gd`, `scripts/combat/encounter_director.gd`
  (2207 lines — the largest combat file).
- Wiring: `EncounterDirector` node in `meadows_playground.tscn` with
  `player_path`/`manager_path`/`camera_rig_path`.
- Data: per-band `data/config/bands/<band>/spawns.json` (band1: 68, band2: 57,
  band3: 54, band4: 81, band5: 23 entries — 283 total), plus legacy/global
  `data/config/spawns.json` and `data/config/spawn_tables.json`.
- Tests: `tests/test_spawn_tables.gd`, `tests/test_spawns_data.gd`.

## Combat (real-time, piloted)

- Rule: D07 — combat is piloted, not commanded; human never fights (CLAUDE.md
  hard rule); no shields (CLAUDE.md hard rule); D32 — mid-combat switching is
  allowed.
- Scripts: `scripts/combat/combat_manager.gd` (1922 lines, the core loop —
  arena setup, camera takeover, action resolution, victory, switching),
  `scripts/combat/combat_ai.gd`, `scripts/combat/combat_math.gd`,
  `scripts/combat/type_chart.gd`, `scripts/combat/combat_arena.gd`,
  `scripts/combat/move_projectile.gd`, `scripts/combat/target_marker.gd`,
  `scripts/combat/telegraph_glow.gd`, `scripts/combat/impact_flash.gd`.
- Data: `data/config/combat.json`, `data/config/type_chart.json`.
- Input actions: `combat_quick`, `combat_charged`, `combat_throw`, `combat_run`
  (flee), `party_cycle` (switch active creature).
- Wiring: `CombatManager` + `EncounterDirector` nodes in the world scene;
  `CombatHUD` (`scenes/combat/combat_hud.tscn`) instanced alongside
  `PlaygroundHUD`.
- Tests: `tests/test_combat_math.gd`, `tests/test_combat_ai.gd`,
  `tests/test_combat_progression.gd`, `tests/smoke_combat.gd`,
  `tests/smoke_combat_camera.gd`, `tests/smoke_combat_hud_left_column.gd`.

## Catching

- Rule: D08 — catching costs you your pal (a party slot is spent to throw);
  D31 — capture odds are an explicit percent; catching is available during
  wild combat (CLAUDE.md hard rule); trainer-owned creatures cannot be caught
  (CLAUDE.md hard rule).
- Scripts: `scripts/combat/catch_math.gd`, `scripts/combat/orb.gd`
  (`scenes/combat/orb.tscn`, projectile), `scripts/combat/throw_aim.gd`
  (aim-mode camera/reticle), `scripts/combat/throw_preview.gd`.
- Data: `data/config/catching.json` — chance formula
  (`species_rate * hp_factor * orb_multiplier * accuracy_bonus`), 3 orb tiers
  (`orb_basic` x1.0, `orb_greater` x1.6, `orb_prime` x2.0), throw physics,
  aim-camera profile, wobble/resolve timings, faint-linger (4s).
- Items: `orb_basic`/`orb_greater`/`orb_prime` in `data/items/items.json`,
  crafted via `data/recipes/recipes_rootstone.json` / `recipes_ironwood.json`.
- Input actions: `combat_throw` (+ aim-mode look/confirm).
- Tests: `tests/test_catch_math.gd`, `tests/smoke_catching.gd`,
  `tests/smoke_controller_catching.gd`, `tests/smoke_catch_aim_slowdown.gd`,
  `tests/smoke_party_count_after_catches.gd`.

## Party / five-creature cap

- Rule: CLAUDE.md hard rule — player can own only five creatures total; never
  implement storage, a reserve box, or a hidden sixth slot.
- Scripts: `autoload/party.gd` (`const MAX_CREATURES := 5`; `add()` returns
  false when full). `active_index()`/`set_active()`/`cycle_active()` (bound to
  `party_cycle`), `best_index()`/`set_best()` ("Best Creature"), `all_fainted()`.
- No reserve/box/PC script exists anywhere in `scripts/` or `autoload/` —
  confirmed by repo-wide search, matching the hard rule.
- Release flow: not confirmed as a dedicated `release()` function in
  `party.gd` in this pass — likely surfaced via a swap/team UI panel calling
  `remove_at()`. Not yet documented at the exact call-site level.
- Input actions: `party_cycle`.
- Tests: `tests/test_party.gd`, `tests/test_party_seam.gd`,
  `tests/smoke_party_count_after_catches.gd`, `tests/smoke_hud_no_sixth_slot.gd`.

## Creature care / rest / bond

- Rule: D40 — fainting needs a revive; D70-bond-is-a-milestone-ladder-not-a-meter.
- Scripts: `scripts/world/night_rest.gd`, `scripts/ui/creature_bed_panel.gd`,
  `scripts/world/meadow_healing.gd`, `scripts/world/rest_point.gd`.
- Data: `data/config/bond_milestones.json`, `data/config/creature_condition.json`,
  `data/config/meadow_healing.json`.
- Wiring: `Game._tick_creature_bed_recovery()` /
  `complete_creature_bed_rests()` (`autoload/game_state.gd:746, 770`).
- Tests: not itemized individually in the inventory pass beyond save-format
  coverage of bond milestones — not yet documented.

## Satiety

- Rule: CLAUDE.md hard rule — light satiety only, slow drain, food
  restores/buffs, soft drawbacks when low, no starvation death. D29 —
  satiety is a light hunger.
- Scripts: `scripts/player/player_vitals.gd` (`vitals.tick_satiety(delta)`,
  called every physics frame from `player_controller.gd`).
- Data: `data/config/vitals.json`.
- Wiring: `Game.player_vitals()` (`autoload/game_state.gd:697`, fallback
  satiety storage when no live player node). No death-on-satiety logic found.
- Tests: not yet documented (no dedicated satiety test file identified in
  this pass).

## XP / levels / progression

- Rule: D30 — pal progression; D42 — the chapter is 3-4 hours (pacing tuned
  around this curve); `docs/specs/MEADOWS_PROGRESSION_CURVE.md` is the authoritative
  numeric band.
- Data: `data/config/progression.json` — keys: `level` (7 entries),
  `xp_award` (4), `creature_bed` (2), `bond` (1), `individuality` (2),
  `traits` (1), `evolution` (1), `migration` (1), `elixirs` (2 — D47, rare and
  capped), `home` (1).
- Reader: `scripts/creatures/progression.gd` (per
  `docs/specs/MEADOWS_PROGRESSION_CURVE.md`; individual functions not re-traced in
  this pass).
- Tests: `tests/test_combat_progression.gd`, `tests/test_chapter_curve.gd`
  (per `docs/specs/MEADOWS_PROGRESSION_CURVE.md`), plus `tests/test_trainers_data.gd`
  guard tests and `tools/_probe_pacing.py` as a re-runnable pacing measurement.

## Moves / TMs / traits / evolution

- Rule: D44 — a TM is an item and it is spent; D37 — individuality and
  traits are flavour, not balance; D17 — an evolution is always larger;
  D71 — Mudsnout branches into Tuskroot or Ashtusk.
- Scripts: `scripts/creatures/move_db.gd`, `scripts/creatures/trait_db.gd`,
  `scripts/creatures/evolution.gd`, `scripts/creatures/creature_species.gd`,
  `scripts/creatures/bond_milestones.gd`.
- Data: `data/moves/moves.json` (48 moves), `data/moves/tms.json` (14 TMs),
  `data/traits/traits.json` (8 traits), `data/creatures/species.json`
  (evolution fields `evolves_from`/`evolves_into`/`evolves_into_variants`),
  `data/creatures/aspect_variants.json`, `data/creatures/shiny_colourways.json`
  (10 colourways, cosmetic only).
- Tests: not itemized individually beyond `tests/test_combat_progression.gd`
  and species/content tests referenced elsewhere — not yet documented at
  per-system granularity.

## Creature species / runtime body

- Scripts: `scripts/creatures/creature_body.gd` (1549 lines, the
  piloted/AI body), `scripts/creatures/wild_creature.gd`,
  `scripts/creatures/creature_instance.gd`, `scripts/creatures/creature_animator.gd`,
  `scripts/creatures/creature_visual.gd`, `scripts/creatures/creature_condition.gd`,
  `scripts/creatures/follower_creature.gd`, `scripts/creatures/alpha_aura.gd`.
- Data: `data/creatures/species.json` — 25 species; per-species fields
  `display_name, type[, type_secondary], base_hp, base_attack, base_defence,
  catch_rate, aggressive, moves, best_creature, placeholder[, rideable]`.
  `data/creatures/species_pending.json` exists but is an empty stub
  (`species: {}`).
- Legendary: `veridian` (Ground type, `rideable.requires_item == ""` — "the
  legendary voluntarily joins").
- Constraint: **no new creature meshes for Meadows** (CLAUDE.md hard rule) —
  differentiation is materials/scale/animation/VFX/habitat/behavior/traits
  only.

## Trainers (NPC fights)

- Scripts: `scripts/world/trainer_npc.gd`.
- Data: per-band `data/config/bands/<band>/trainers.json` — band1: 9, band2:
  4, band3: 5, band4: 5, band5: 6 (29 field trainers total), plus
  `data/config/trainers.json` (flow/prompt config, not a roster) and
  village-NPC battle branches (Mira/Oskar/Tam `_challenge` conversations
  wired to `battle:<trainer_id>` dialogue effects) layered on top.
- Escalation: trainer levels climb from 2 to the Warden's level-20 ace across
  15 critical-path fights (`docs/specs/MEADOWS_PROGRESSION_CURVE.md`), guarded by
  `tests/test_trainers_data.gd` (no >4-level jump; nothing in the stronghold
  out-levels the boss).
- Tests: `tests/test_trainers_data.gd`.

## Team Tether (grunts, pylons, relay)

- Rule: D49 — the machine is generated without its prisoner; D45 — the
  drained-ground grammar; D55 — a severed spoke may not block the road it is
  not severing; D41 — the stations drain the land.
- Scripts: `scripts/world/tether_relay.gd` (1728 lines), `scripts/world/tether_sigil.gd`,
  `scripts/world/severed_spokes.gd` (1253 lines), `scripts/world/rift_collapse.gd`.
- Data: `data/config/tether_relay.json`, `data/config/relay_site.json`,
  `data/dialogue/relay.json`.
- Tests: not itemized in the inventory pass beyond general world/band smokes
  — not yet documented.

## Warden boss

- Rule: CLAUDE.md — the Warden mesh is already rebuilt from the owner-supplied
  board-16 character sheet (`assets/characters/warden/warden_lod0.glb`); do not
  reopen historical "unmodelled face" notes.
- Scripts: `scripts/world/stronghold_climax.gd` (658 lines) — `_place_warden()`,
  `warden_body()`, `_seen_warden_defeat` flag.
- Data: `data/config/stronghold_climax.json` (`warden` key block),
  `data/config/stronghold.json` (`warden_arena` chamber in `KEEP_CHAMBERS`,
  `scripts/world/stronghold.gd:1350`).
- Wiring: `_build_stronghold_climax()` in `playground_world.gd:1509`.
- Tests: not itemized individually in the inventory pass — not yet documented.

## Legendary roster choice

- Data: `veridian` in `data/creatures/species.json` — design comment frames
  this as "the legendary voluntarily joins" in the stronghold's chamber; a
  `legendary_chamber` exists in `KEEP_CHAMBERS` (`scripts/world/stronghold.gd:1350`).
- Status: data + chamber present; the choice UI/flow script itself was not
  individually traced beyond `stronghold_climax.gd` in this pass — not yet
  documented.

## Tournament (village)

- Scripts: `scripts/world/tournament.gd` (870 lines) — `build(world)`,
  bracket repaint (`_repaint_bracket`), gating checks (`team_ready`,
  `training_ready`, `condition_ready`, `team_fed`, `required_party_size`,
  `required_level`), `bracket_state()`.
- Data: `data/config/tournament.json` — `entry`(5 fields), `board`(4),
  `marshal`(2), `rounds`(3), `bracket`(8), `simulated`(4).
- Wiring: `playground_world.gd:1093` (`tournament.name = "Tournament"`,
  `.call("build")`) — reachable from the village build pass.
- Tests: `tests/test_tournament.gd`, `tests/smoke_tournament_bracket.gd`.

## Gathering

- Rule: D60 — every tree and stone is harvestable and stays gone;
  D67 — chopping a tree stands a felled pickup, not a payout; D64 —
  clearings and footprints are cut per band too.
- Scripts: `scripts/world/harvest_node.gd`, `scripts/world/harvest_logic.gd`,
  `scripts/world/vegetation_harvest_point.gd`, `scripts/world/felled_resource.gd`
  (respawn/felled piles, save VERSION 10/11).
- Data: per-band `data/config/bands/<band>/harvest.json` — band1: 40, band2:
  26, band3: 31, band4: 26, band5: 8 (131 nodes total); global
  `data/config/harvest.json` now holds 0 nodes (moved per-band, marked
  "BAND-SPLIT" in `playground_world.gd` comments).
- Tests: not itemized individually in the inventory pass beyond world-build
  smokes — not yet documented.

## Inventory

- Rule: CLAUDE.md hard rule — slot/stack inventory, no carry-weight system.
- Scripts: `autoload/inventory.gd` (`const SLOT_COUNT := 24`,
  `const HOTBAR_SLOTS := 6`). Note: 5 keybound `hotbar_1..5` input actions
  vs. 6 `HOTBAR_SLOTS` constant — worth re-checking if precision matters.
- UI: `scripts/ui/tab_backpack.gd` (2303 lines).
- Data: `data/items/items.json` (56 items).
- Input actions: `inventory`, `hotbar_1`..`hotbar_5`, `backpack_drop`.
- Tests: `tests/test_inventory.gd`.

## Crafting

- Rule: D41 — the stations drain the land; D43 — recipes gated by dialogue
  flags.
- Scripts: `scripts/ui/craft_panel.gd` (station UI, pauses the tree).
- Data: `data/recipes/recipes.json` (7, base tier), `recipes_rootstone.json`
  (5), `recipes_ironwood.json` (4) — 16 recipes total across 3 material tiers.
- Tests: `tests/smoke_craft_panel_controller.gd`.

## Building

- Rule: D34 — build system v2; D28-of4 — real castle and build grid;
  D50 — the hoe gates tilling and nothing else; D53 — the torch is carried,
  not built.
- Scripts: `scripts/build/build_placer.gd` (1123 lines), `scripts/build/build_grid.gd`,
  `scripts/build/build_snap_contract.gd`, `scripts/build/build_piece.gd`,
  `scripts/build/build_door.gd`, `scripts/world/building_prefabs.gd`,
  `scripts/world/built_floor.gd`, `scripts/build/storage_container.gd`,
  `scripts/world/storage_state.gd`, `scripts/ui/build_menu.gd` (deliberately
  does NOT pause the tree — "Valheim feel," per `input_owner.gd` comment).
- Data: `data/items/buildables.json` (11 buildables),
  `data/config/building_prefabs.json` (20 prefabs).
- Input actions: `build_place`, `build_cancel`, `build_rotate_left`,
  `build_rotate_right`, `build_snap_cycle`.
- Tests: `tests/test_build_catalogue.gd`, `tests/test_build_grid.gd`,
  `tests/test_build_placer_preview.gd`, `tests/test_free_build.gd`,
  `tests/test_register_building.gd`, `tests/smoke_build_menu_footprint.gd`,
  `tests/smoke_build_menu_pad_pick.gd`, `tests/smoke_build_owns_creature_cycle.gd`,
  `tests/smoke_build_wins_while_hammer_is_out.gd`, `tests/smoke_free_build.gd`,
  `tests/smoke_gate_a_build_house.gd`, `tests/smoke_gate_a_build_segment_meadows.gd`,
  `tests/test_gate_a_build_segment_contract.gd`.
- Note: D16 — free-build is temporary scaffolding (not a shipped player-facing
  mode).

## Trade / shop

- Rule: D39 — the village economy.
- Scripts: `scripts/world/shop_interior.gd`, `scripts/ui/shop_panel.gd`,
  `scripts/trade/creature_trade.gd`, `scripts/trade/trade_db.gd`.
- Data: `data/config/trade.json` — vendors Mira (goods), Oskar (creatures),
  Bram (goods).
- Tests: `tests/test_trade.gd`, `tests/smoke_village_trade.gd`.

## Death satchel

- Rule: CLAUDE.md hard rule — multiple death satchels persist.
- Scripts: `scripts/world/death_satchel.gd`, `scripts/world/player_death.gd`.
- Wiring: `Game.register_death_satchel()` (`autoload/game_state.gd:842`) —
  save format VERSION 4 supports multiple persisted satchels.
- Tests: `tests/test_player_death.gd`.

## Day/night and weather

- Scripts: `scripts/world/day_cycle.gd` (`hour_at()`, `preset_at()`,
  `interpolate_at()`, `is_dark()`), `scripts/world/world_weather.gd` (wired
  as `WorldWeather` node).
- Wiring: `Game.advance_day()` (`autoload/game_state.gd:534`).
- Tests: `tests/test_day_cycle.gd`, `tests/test_world_weather.gd`.

## Riding

- Rule: D48 — riding is a world verb and costs no stamina.
- Scripts: `scripts/world/riding_controller.gd` (511 lines) — mountable
  creatures (meadowhart, legendary veridian), tack requirement, speed
  multiplier, climb-slope override.
- Wiring: `riding_controller.gd` attached to `meadows_playground.tscn`.
- Tests: `tests/smoke_riding.gd`.
- Note: no dedicated fast-travel/waypoint teleport system was found; riding
  is the stated traversal-speed solution (chapter_curve.json commentary:
  "riding... dramatically improves revisiting known areas").

## Map / minimap

- Rule: D33 — one map database.
- Scripts: `scripts/world/map_baker.gd`, `autoload/map_state.gd` (707 lines,
  fog-of-war/database), `scripts/ui/tab_map.gd` (1123 lines).
- Data: `data/config/map_landmarks.json` (reveal_radius 80m, minimap_span_m
  90m, starting_reveal 9 landmarks pre-known).
- Input actions: `map`, `map_zoom_in`, `map_zoom_out`.
- Tests: `tests/test_map_baker.gd`, `tests/test_map_fog.gd`,
  `tests/test_map_icons.gd`, `tests/test_map_landmarks.gd`,
  `tests/test_map_state.gd`, `tests/test_map_zoom_persistence.gd`,
  `tests/test_minimap_terrain_region.gd`, `tests/smoke_gate_a_map_cycle.gd`.

## Save / load

- Scripts: `scripts/save/save_game.gd` (974 lines, VERSION=16, SLOT_COUNT=5,
  AUTOSAVE_SLOT=0), called from `Game.save_game()`
  (`autoload/game_state.gd:923`) and `Game.load_game()` (`:988`).
- Storage: JSON files at `user://saves/` (one per slot).
- Serialized: party (individuality rolls, traits, shiny), inventory/hotbar,
  progression flags, satiety, map fog/database, death satchels, placed
  buildings, felled vegetation, farm-plot/bed state, player pose, world_seed,
  bond milestones. 16 documented migration steps (e.g. V1 party shape → V16
  bond milestones).
- Autosave: `Game._tick_autosave()` (`autoload/game_state.gd:566`) fires
  periodically into slot 0; also written on rest/camp actions.
- Rule: D27 — save format and where it lives.
- Tests: `tests/test_save_format.gd`, `tests/smoke_save_persistence.gd`,
  `tests/test_autosave_fallback.gd`.

## HUD / menus / settings

- Scripts: `scripts/ui/playground_hud.gd` (3904 lines, top-level HUD),
  `scripts/ui/tab_backpack.gd`, `scripts/ui/tab_creatures.gd` (1824 lines),
  `scripts/ui/tab_map.gd`, `scripts/ui/tab_settings.gd` (1014 lines),
  `scripts/ui/party_strip.gd` (1014 lines), `scripts/ui/combat_hud.gd`
  (1274 lines), `scripts/ui/game_menu.gd` (pause shell, mounted by
  `Game._mount_menu()`, `autoload/game_state.gd:501`).
- Panels that pause the tree: `craft_panel.gd`, `storage_panel.gd`,
  `swap_panel.gd`, `game_menu.gd`, `creature_bed_panel.gd`, `shop_panel.gd`.
  `build_menu.gd` deliberately does not pause.
- Rule: D28 — a UI token module (shared styling).
- Settings storage: `user://settings.json` (`free_build`, `debug_teleport`,
  `auto_run` keys documented in `autoload/game_state.gd` comments); the
  settings-menu scene itself was not directly inspected in this pass — not
  yet documented beyond the data path.
- Tests: `tests/test_hud_widgets.gd`, `tests/smoke_hud_handheld_legibility.gd`,
  `tests/smoke_hud_no_sixth_slot.gd`, `tests/smoke_combat_hud_left_column.gd`,
  `tests/smoke_station_panels_hide_world_hud.gd`, `tests/smoke_menu.gd`,
  `tests/smoke_menu_focus.gd`, `tests/smoke_menu_open_does_not_offer_to_drop.gd`,
  `tests/smoke_menu_owns_dpad.gd`, `tests/test_menu_data.gd`,
  `tests/smoke_settings.gd`.

---

## Controller input mapping

- Rule: controller-first (CLAUDE.md hard rule); D15 — remappable controls and
  the first user file; D68 — the authored controller map has no held buttons;
  D35 — Palworld control parity.
- Config: `project.godot` `[input]` block — every action has both a keyboard
  and a joypad binding (`InputEventJoypadButton`/`InputEventJoypadMotion`).
  All defined actions were confirmed referenced somewhere in
  scripts/scenes/autoload (no unused input action found).
- Additional context data: `data/config/input_contexts.json`.

## Interaction/input ownership (softlock guard)

- Mechanism: `scripts/ui/input_owner.gd` — a shared `&"input_owner"` Godot
  group contract. World-verb pollers call `INPUT_OWNER.current(get_tree())`
  and refuse to act while a panel in that group reports itself open. Most
  panels additionally pause `get_tree()` while open, and every panel that
  captures the mouse stores/restores `Input.mouse_mode` on open/close.
- History: `build_menu.gd` deliberately does not pause the tree (world stays
  live behind it), which historically caused a real reported softlock (a
  joypad button 0 press both selected a build piece and made the player jump
  underneath the menu — see `player_controller.gd` comment citing "RG5 owner
  playtest 2026-08-18"). The `input_owner.gd` gate was written to close that
  bug.
- `suppress_pause_reopen()` (`input_owner.gd`) guards against a controller
  "B" press that closes one panel also re-opening the pause shell on the
  same input edge.
- Caution for new panels: a new UI panel that does not join the
  `input_owner` group, or does not restore `mouse_mode` on every exit path,
  will reproduce this class of bug. No such panel was found in this pass,
  but exhaustive per-exit-path verification was not performed.
- Tests: `tests/smoke_wake_softlock.gd`.

---

## Systems present but outside the requested list

- `scripts/world/farm_logic.gd` / `farm_plot.gd` — berry farm, plantable/
  harvestable beds (`data/config/farm.json`, save VERSION 9).
- `scripts/world/burrow_warrens.gd` (3327 lines), `scripts/world/stronghold.gd`
  (4847 lines) — hand-built dungeon interiors with their own chamber graphs.
- `scripts/world/world_look.gd` — shared look/aim-direction utility used by
  camera, combat aim, and interaction.
- `scripts/audio/world_audio.gd`, `audio_manager.gd` — 6 audio buses
  (Master, Music, Ambience, SFX, Creatures, UI), config `data/config/audio.json`.
- `scripts/world/old_quarry.gd`, `river.gd`, `river_nest_clear.gd`,
  `cart_repair.gd`, `mill_crossing.gd`, `watchtower_landmark.gd`,
  `torch_prop.gd`, `pickup_glow.gd`, `key_pickup.gd`, `tm_pickup.gd`,
  `item_cache_pickup.gd`, `item_gate.gd` — region set-piece/puzzle scripts,
  not documented individually here.

---

## Caveats

Drafted from a read-only, code+data inventory pass (no Godot editor or game
run). "Implemented" claims trace to `scripts/`, `autoload/`, `scenes/`,
`data/`, `project.godot`, or `tests/`. Party release-flow exact call site,
the settings-menu scene, and per-system test coverage for gathering/care/
relay/Warden were not traced to the same depth as the rest — flagged "not
yet documented" above rather than asserted.
