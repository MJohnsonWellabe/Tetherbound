extends "res://tests/test_case.gd"

## R3.1 / VERSION 2. Save/load round-trips — `scripts/save/save_game.gd`.
##
## Every failure here is one a player would meet as lost progress: a party
## that comes back with the wrong HP, a satchel that reshuffles slots on
## reload, a version bump that bricks an old save instead of leaving it
## alone. `FakeGame` below stands in for the `Game` autoload — it needs no
## scene tree, no menu, nothing `save_game.gd` does not actually read or
## write (`day`, `party`, `inventory`, `placed_buildings`, `death_satchels`,
## `map`, `satiety`, `farm_plots`, and — only when a test opts in — a live
## `player_vitals()`).
##
## Writes to a dedicated `user://test_saves_format/` directory rather than the
## real `user://saves/`, wiped before every test, so this file cannot leave
## behind a slot a later run — or a real playthrough on the same machine —
## would mistake for a real save.

const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const TOURNAMENT := preload("res://scripts/world/tournament.gd")
const CONDITION := preload("res://scripts/creatures/creature_condition.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const PARTY := preload("res://autoload/party.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const MAP_STATE := preload("res://autoload/map_state.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const REALM_HEART_STATE := preload("res://autoload/realm_heart_state.gd")
const SPLIT_FIXTURE := preload("res://tests/helpers/split_save_fixture.gd")

const TEST_DIR := "user://test_saves_format/"

## Stands in for `scripts/player/player_vitals.gd` — save_game.gd only ever
## reads/writes a `satiety`/`max_satiety` pair on whatever `player_vitals()`
## returns, so this bare-bones double is enough to exercise the "live vitals
## reachable" half of the satiety seam without a scene tree.
class FakeVitals:
	extends RefCounted
	var satiety: float = 100.0
	var max_satiety: float = 100.0

class FakeLocal:
	extends RefCounted
	var character_id: String = ""
	var display_name: String = ""
	var chosen_character: String = "trainer"
	var satchel_escrow: Dictionary = {}

class FakeGame:
	extends RefCounted
	var day: int = 1
	var party: RefCounted = null
	var inventory: RefCounted = null
	var placed_buildings: Array = []
	## R7.6 / VERSION 9. The berry farm's beds.
	var farm_plots: Array = []
	var death_satchels: Array = []
	## HARVEST-ALL / VERSION 10. Permanently-chopped vegetation.
	var harvested_vegetation: Dictionary = {}
	## RG9 / VERSION 11. Chopped-but-not-yet-gathered felled pickups.
	var felled_vegetation: Dictionary = {}
	## T3-ENCOUNTER / VERSION 15. Which world this save's rolled wild population
	## is. Present on the fake precisely because the whole rolled-population
	## design rests on it round-tripping: the population is DERIVED from this one
	## integer, so a seed that failed to survive a save would silently hand the
	## player a different world on every reload, with every creature they had
	## walked to somewhere else.
	var world_seed: int = 0
	var saved_player_pose: Dictionary = {}
	## N14 / VERSION 19. The day/night clock in elapsed seconds, or a negative
	## number for "no carried clock -- open at the authored morning". Present on
	## the fake for the same reason `world_seed` is: the whole point of the key
	## is that it round-trips, so a fake that did not carry it would let a saver
	## which dropped it pass.
	var clock_elapsed_seconds: float = -1.0
	var map: RefCounted = null
	var progression: RefCounted = null
	## Cloudreach Phase 1 / VERSION 17.
	var realm_hearts: RefCounted = null
	var current_realm: String = "meadows"
	var pending_realm_entry: String = ""
	## Fallback satiety — round-tripped directly when `_vitals` below is null,
	## mirroring the real `Game.satiety` field's job.
	var satiety: float = 100.0
	## Set by a test to exercise the "live vitals reachable" branch of the
	## satiety seam; left null to exercise the fallback branch instead.
	var _vitals: RefCounted = null
	var world: RefCounted = null
	var local: RefCounted = null

	func player_vitals() -> RefCounted:
		return _vitals

var db: RefCounted = null
var saver: RefCounted = null


func before_each() -> void:
	db = ITEM_DB.new()
	saver = SAVE_GAME.new(TEST_DIR)
	_wipe_test_dir()


func after_each() -> void:
	_wipe_test_dir()


func _wipe_test_dir() -> void:
	SPLIT_FIXTURE.wipe(TEST_DIR)


func _game(seed_party: bool = true) -> RefCounted:
	var game := FakeGame.new()
	game.party = PARTY.new()
	game.inventory = INVENTORY.new(db)
	game.progression = PROGRESSION_STATE.new()
	game.realm_hearts = REALM_HEART_STATE.new()
	game.world = SPLIT_FIXTURE.IdHolder.new()
	game.local = FakeLocal.new()
	if seed_party:
		var creature: RefCounted = CREATURE.from_species("terrapup", {
			"display_name": "Terrapup", "type": "ground", "base_hp": 100.0,
			"base_attack": 20.0, "base_defence": 20.0,
		})
		creature.nickname = "Biscuit"
		creature.take_damage(35.0)
		game.party.add(creature)
	return game


func test_save_then_load_round_trips_the_selected_character_body() -> void:
	var written := _game(false)
	written.local.chosen_character = "lyra"
	assert_true(saver.save(written, 1))
	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	assert_eq(str(read.local.chosen_character), "lyra")


func test_save_then_load_round_trips_realm_and_active_heart() -> void:
	var written := _game(false)
	written.progression.set_flag("realm_heart_meadows_earned")
	assert_true(written.realm_hearts.place("meadows", written.progression))
	assert_true(written.realm_hearts.activate("meadows", written.progression))
	written.current_realm = "cloudreach"
	written.pending_realm_entry = "cloudreach_gate_arrival"
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	assert_eq(read.current_realm, "cloudreach")
	assert_eq(read.pending_realm_entry, "cloudreach_gate_arrival")
	assert_eq(read.realm_hearts.active_id(), "meadows")
	assert_eq(read.realm_hearts.stamina_capacity_multiplier(), 2.0)


func test_slot_count_is_between_three_and_five() -> void:
	# R3.1's own brief: "3-5 slots".
	assert_true(SAVE_GAME.SLOT_COUNT >= 3 and SAVE_GAME.SLOT_COUNT <= 5)


func test_a_fresh_slot_has_nothing_to_load() -> void:
	assert_false(saver.has_slot(0))
	assert_false(saver.load_slot(_game(), 0))
	assert_eq(saver.slot_info(0), {})


func test_save_then_load_round_trips_player_pose() -> void:
	var written := _game()
	written.saved_player_pose = {
		"position": [123.25, 7.5, -88.0],
		"model_yaw": 1.25,
		"camera_yaw": -0.75,
		"camera_pitch": -0.2,
	}
	assert_true(saver.save(written, 1))
	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	assert_eq(read.saved_player_pose.get("position"), [123.25, 7.5, -88.0])
	assert_almost_eq(float(read.saved_player_pose.get("model_yaw")), 1.25)
	assert_almost_eq(float(read.saved_player_pose.get("camera_yaw")), -0.75)
	assert_almost_eq(float(read.saved_player_pose.get("camera_pitch")), -0.2)


func test_malformed_player_pose_falls_back_as_one_unit() -> void:
	var written := _game()
	written.saved_player_pose = {
		"position": [12.0, 4.0, -9.0],
		"model_yaw": 0.4,
		"camera_yaw": 1.2,
		"camera_pitch": -0.3,
	}
	assert_true(saver.save(written, 1))
	var path: String = saver.slot_path(1)
	var file := FileAccess.open(path, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	# A position that would float-convert to the origin was the dangerous case:
	# the rest of an otherwise valid save must load, but no partial pose applies.
	data["player_pose"] = {
		"position": ["not-a-number", 4.0, -9.0],
		"model_yaw": 0.4,
		"camera_yaw": 1.2,
		"camera_pitch": -0.3,
	}
	_write_legacy_slot_json(1, data)

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	assert_eq(read.saved_player_pose, {}, "a malformed pose should use the world's authored spawn")


func test_version_11_save_loads_without_inventing_a_player_pose_refused_by_redesign() -> void:
	var written := _game()
	written.saved_player_pose = {
		"position": [50.0, 3.0, 25.0],
		"model_yaw": 0.2,
		"camera_yaw": 0.7,
		"camera_pitch": -0.1,
	}
	assert_true(saver.save(written, 1))
	var path: String = saver.slot_path(1)
	var file := FileAccess.open(path, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	data["version"] = 11
	data.erase("player_pose")
	_write_legacy_slot_json(1, data)

	var read := _game(false)
	_assert_old_slot_refused_unchanged(read, 1)


func test_save_then_load_round_trips_the_day_counter() -> void:
	var written := _game()
	written.day = 7
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	assert_eq(read.day, 7)


func test_save_then_load_round_trips_the_party() -> void:
	var written := _game()
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	assert_eq(read.party.size(), 1)
	var creature: RefCounted = read.party.at(0)
	assert_eq(str(creature.get("species_id")), "terrapup")
	assert_eq(str(creature.get("nickname")), "Biscuit")
	assert_almost_eq(float(creature.get("hp")), 65.0)
	# 100, exactly what `_game()`'s fixture set `base_hp` to, not
	# `species.json`'s real terrapup value of 120: a load trusts the save's
	# own `base_hp` (GAME-F4), the same "an instance's saved stats are as-is"
	# rule this class holds for every other field --
	# `creature_instance.gd::recompute_stats_from_base()` explains why
	# unconditionally overwriting from the species catalogue here was a
	# regression, not the fix. The saved `hp` survives as a number and is
	# clamped to the recomputed maximum, which is why 65 is untouched. See the
	# level-up test below for what the base_hp/max_hp mismatch bug used to do.
	assert_almost_eq(float(creature.get("max_hp")), 100.0)


## The defect this file exists to catch, and the one it did not.
##
## GATE-F-LEG-S10AB, 2026-08-31. `base_hp`/`base_attack`/`base_defence` are
## what `creature_instance.gd::_apply_level_stats()` recomputes every stat
## from, and this format has never written them to a slot. A loaded creature
## therefore carried the class defaults of 1.0 while its `max_hp` came back
## from the file looking perfectly healthy -- and the moment it LEVELLED, the
## recompute ran from a base of 1.0 and its maximum collapsed to about 2.
##
## Measured in the Meadows Hall gauntlet on the frame the elite's first
## creature fell and the victory XP landed: three party members went from
## 218.4, 256.8 and 218.4 max HP to 2.14, 2.2 and 2.14, and the chapter's
## climax became unwinnable. Every existing round-trip test above passed
## throughout, because none of them levelled a creature after loading it --
## which is exactly the gap this test closes.
func test_a_loaded_creature_can_level_up_without_its_stats_collapsing() -> void:
	var written := _game()
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	var creature: RefCounted = read.party.at(0)
	var before := float(creature.get("max_hp"))
	assert_true(before > 50.0, "a loaded terrapup should carry a real maximum, not the class default")

	# Enough XP to be certain of at least one level, whatever the curve is
	# tuned to. `gain_xp` is the production path: it is what every victory
	# award calls.
	var cfg: Dictionary = PROGRESSION.config()
	var gained: int = int(creature.call("gain_xp", 100000, cfg))
	assert_true(gained > 0, "the creature did not level at all; the test proves nothing")

	var after := float(creature.get("max_hp"))
	assert_true(after > before,
		("levelling a LOADED creature took its max HP from %.2f to %.2f. Base stats were "
		+ "not restored on load, so _apply_level_stats recomputed from base_hp = 1.0.")
		% [before, after])
	assert_true(float(creature.get("attack")) > 1.5,
		"a levelled creature's attack collapsed to the class default")
	assert_true(float(creature.get("defence")) > 1.5,
		"a levelled creature's defence collapsed to the class default")


## GATE-F-LEG-S07's own version of the same regression coverage, found the
## same day driving a hand-seeded level 9-13 party instead of a level-3
## terrapup: `base_hp`/`base_attack`/`base_defence` drive every level-up
## recompute (`creature_instance.gd::_apply_level_stats`, called from
## `gain_xp`) but were never written to a save at all until this fix -- a
## loaded creature kept `CreatureInstance`'s own bare class defaults
## (1.0/1.0/1.0) until it next levelled, at which point a real, played-in
## creature's stats collapsed to roughly the level multiplier alone.
func test_a_loaded_creature_survives_its_next_level_up() -> void:
	var written := _game(false)
	var creature: RefCounted = CREATURE.from_species("ripplet", {
		"display_name": "Ripplet", "type": "water",
		"base_hp": 105.0, "base_attack": 24.0, "base_defence": 17.0,
	})
	var cfg0 := {"level": {"growth_per_level": {"hp": 0.06, "attack": 0.05, "defence": 0.05}}}
	creature.level = 13
	creature.call("_apply_level_stats", cfg0)
	creature.hp = creature.max_hp
	written.party.add(creature)
	var written_max_hp := float(creature.get("max_hp"))
	assert_almost_eq(written_max_hp, 180.6, 0.5)
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	var loaded: RefCounted = read.party.at(0)
	# The save/load round trip alone must not have touched it.
	assert_almost_eq(float(loaded.get("max_hp")), written_max_hp, 0.5)
	assert_almost_eq(float(loaded.get("base_hp")), 105.0, 0.5)
	assert_almost_eq(float(loaded.get("base_attack")), 24.0, 0.5)
	assert_almost_eq(float(loaded.get("base_defence")), 17.0, 0.5)

	# The regression: a level-up right after load must recompute from the
	# creature's REAL base stats, not from CreatureInstance's class defaults.
	var cfg := {"level": {"cap": 50, "growth_per_level": {"hp": 0.06, "attack": 0.05, "defence": 0.05}},
		"individuality": {"variance_pct": 0.0}}
	var levels_gained: int = loaded.call("gain_xp", 1000000, cfg)
	assert_true(levels_gained > 0)
	# At iv=0.5 (no variance) the level-up recompute is exact: base_hp *
	# (1 + 0.06 * (level-1)), same for attack/defence. A creature whose base
	# stats reverted to CreatureInstance's own defaults (1.0/1.0/1.0) would
	# land at roughly 1/100th of these regardless of level.
	assert_true(float(loaded.get("max_hp")) > 100.0)
	assert_true(float(loaded.get("attack")) > 20.0)
	assert_true(float(loaded.get("defence")) > 15.0)


## The repair reads the catalogue, so a species it does not know must leave the
## file's own numbers alone rather than zeroing a creature the player owns.
func test_a_species_the_catalogue_forgot_keeps_what_the_save_said() -> void:
	var written := _game()
	written.party.at(0).species_id = "no_such_species"
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	var creature: RefCounted = read.party.at(0)
	assert_almost_eq(float(creature.get("max_hp")), 100.0)
	assert_almost_eq(float(creature.get("hp")), 65.0)


## GATE-F-LEG-S08's own version of the same regression coverage as
## `test_save_then_load_round_trips_base_stats_and_survives_a_level_up`
## further down this file (same name collision, resolved by keeping that one
## canonical and this species/shape instead: a pre-GAME-F4 save with none of
## the three fields at all, repaired from `species.json`'s meadowhart entry
## rather than terrapup's).
func test_save_then_load_repairs_missing_base_stats_from_species_json_refused_by_redesign() -> void:
	# An old-format save (VERSION < the one that added base_hp/attack/defence)
	# carries none of the three. `_array_to_party` must repair them from
	# species.json rather than leaving them at 1.0/1.0/1.0.
	var game := FakeGame.new()
	game.party = PARTY.new()
	game.inventory = INVENTORY.new(db)
	game.progression = PROGRESSION_STATE.new()
	game.day = 1
	assert_true(DirAccess.make_dir_recursive_absolute(TEST_DIR) == OK)
	var path: String = str(saver.call("slot_path", 1))
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"version": 15, "day": 1,
		"party": [{
			"species_id": "meadowhart", "display_name": "Meadowhart", "creature_type": "ground",
			"max_hp": 218.5, "attack": 28.0, "defence": 29.75, "hp": 218.5,
			"level": 16, "xp": 0,
		}],
		"inventory": [], "hotbar": [], "placed_buildings": [], "farm_plots": [],
		"death_satchels": [], "satiety": 100.0, "map": {}, "progression": {},
	}))
	file.close()

	_assert_old_slot_refused_unchanged(game, 1)


func test_a_save_with_no_base_stats_reconstructs_them_from_species() -> void:
	var written := _game(false)
	var creature: RefCounted = CREATURE.from_species("terrapup", {
		"display_name": "Terrapup", "type": "ground", "base_hp": 100.0,
		"base_attack": 20.0, "base_defence": 20.0,
	})
	written.party.add(creature)
	assert_true(saver.save(written, 1))

	var path := TEST_DIR.path_join("slot_1.json")
	var file := FileAccess.open(path, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	var party: Array = data["party"]
	(party[0] as Dictionary).erase("base_hp")
	(party[0] as Dictionary).erase("base_attack")
	(party[0] as Dictionary).erase("base_defence")
	data["party"] = party
	_write_legacy_slot_json(1, data)

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	var loaded: RefCounted = read.party.at(0)
	# terrapup's real base_hp (species.json) is 120.0, not the 100.0 generic
	# fallback -- proves this reconstructed from the species table rather than
	# from a hardcoded default.
	assert_almost_eq(float(loaded.get("base_hp")), 120.0, 0.5)


func test_save_then_load_replaces_whatever_party_the_loading_game_already_had() -> void:
	var written := _game()
	assert_true(saver.save(written, 1))

	var read := _game(true)
	read.party.at(0).nickname = "Should not survive"
	assert_true(saver.load_slot(read, 1))
	assert_eq(read.party.size(), 1)
	assert_eq(str(read.party.at(0).get("nickname")), "Biscuit")


func test_save_then_load_round_trips_inventory_slot_positions() -> void:
	var written := _game()
	written.inventory.set_slot(3, {"id": "wood", "n": 12})
	written.inventory.set_slot(9, {"id": "stone", "n": 4})
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	assert_eq(read.inventory.stack_at(3), {"id": "wood", "n": 12})
	assert_eq(read.inventory.stack_at(9), {"id": "stone", "n": 4})
	assert_true(read.inventory.is_slot_empty(0))


func test_save_then_load_round_trips_tool_durability() -> void:
	var written := _game()
	written.inventory.set_slot(5, {"id": "axe", "n": 1, "durability": 3})
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	assert_eq(int(read.inventory.stack_at(5).get("durability", -1)), 3)


func test_save_then_load_round_trips_placed_buildings() -> void:
	var written := _game()
	written.placed_buildings = [
		{"id": "tent", "position": [1.0, 0.0, -2.5]},
		{"id": "storage", "position": [4.25, 0.0, 6.0]},
	]
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	assert_eq(read.placed_buildings.size(), 2)
	assert_eq(str((read.placed_buildings[0] as Dictionary).get("id")), "tent")
	assert_eq((read.placed_buildings[1] as Dictionary).get("position"), [4.25, 0.0, 6.0])


## R7.6 / VERSION 9. A sown bed ripens off `day` rather than off a timer in a
## loaded scene, so the day it was sown has to survive a quit — losing it
## costs the player the entire wait they were sitting through.
func test_save_then_load_round_trips_farm_plots() -> void:
	var written := _game()
	written.farm_plots = [
		{"state": "sown", "ripe_on_day": 4},
		{"state": "tilled", "ripe_on_day": 0},
	]
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	assert_eq(read.farm_plots.size(), 2)
	assert_eq(str((read.farm_plots[0] as Dictionary).get("state")), "sown")
	assert_eq(int((read.farm_plots[0] as Dictionary).get("ripe_on_day")), 4)
	assert_eq(str((read.farm_plots[1] as Dictionary).get("state")), "tilled")


## HARVEST-ALL / VERSION 10. A chopped tree that comes back after a quit has
## not been chopped — this is the property the whole feature depends on.
func test_save_then_load_round_trips_permanently_harvested_vegetation() -> void:
	var written := _game()
	written.harvested_vegetation = {
		"trees": Marshalls.raw_to_base64(PackedByteArray([0b00000101])),
		"rocks": Marshalls.raw_to_base64(PackedByteArray([0b00000010, 0b00000000])),
	}
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	assert_eq(read.harvested_vegetation.get("trees"), Marshalls.raw_to_base64(PackedByteArray([0b00000101])))
	assert_eq(read.harvested_vegetation.get("rocks"), Marshalls.raw_to_base64(PackedByteArray([0b00000010, 0b00000000])))


func test_v9_save_migrates_with_nothing_harvested_refused_by_redesign() -> void:
	var v9_data := {
		"version": 9,
		"day": 11,
		"party": [],
		"inventory": [],
		"placed_buildings": [],
		"farm_plots": [],
		"death_satchels": [],
		"satiety": 80.0,
		"map": {},
		"progression": {},
	}
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var file := FileAccess.open(saver.slot_path(1), FileAccess.WRITE)
	file.store_string(JSON.stringify(v9_data))
	file = null

	var read := _game(false)
	read.map = MAP_STATE.new()
	read.map.configure({})
	read.progression = PROGRESSION_STATE.new()
	_assert_old_slot_refused_unchanged(read, 1)


func test_save_then_load_round_trips_the_world_seed() -> void:
	var written := _game()
	written.world_seed = 90210
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	assert_eq(read.world_seed, 90210,
		"the world seed did not survive a save; every reload would build a different world")


## And the migration, which is the case that actually ships: 0 is the AUTHORED
## world -- the seed at which the roller is never entered -- so a save written
## before rolled populations existed comes back into exactly the world it was
## saved from rather than an approximation of it.
func test_a_save_predating_rolled_populations_loads_the_authored_world_refused_by_redesign() -> void:
	var v14_data := {
		"version": 14,
		"day": 11,
		"party": [],
		"inventory": [],
		"hotbar": [],
		"placed_buildings": [],
		"farm_plots": [],
		"death_satchels": [],
		"satiety": 80.0,
		"map": {},
		"progression": {},
		"harvested_vegetation": {},
		"felled_vegetation": {},
	}
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var file := FileAccess.open(saver.slot_path(1), FileAccess.WRITE)
	file.store_string(JSON.stringify(v14_data))
	file = null

	var read := _game(false)
	read.map = MAP_STATE.new()
	read.map.configure({})
	read.progression = PROGRESSION_STATE.new()
	read.world_seed = 4242  # deliberately dirty, so a no-op migration would show
	_assert_old_slot_refused_unchanged(read, 1)


func test_save_then_load_round_trips_felled_vegetation() -> void:
	var written := _game()
	written.harvested_vegetation = {"trees": Marshalls.raw_to_base64(PackedByteArray([0b00000001]))}
	written.felled_vegetation = {
		"trees#0": {"item": "wood", "amount": 3, "position": [4.0, 1.0, -2.0]},
	}
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	assert_true(read.felled_vegetation.has("trees#0"))
	var record: Dictionary = read.felled_vegetation["trees#0"]
	assert_eq(str(record.get("item")), "wood")
	assert_eq(int(record.get("amount")), 3)
	assert_eq(record.get("position"), [4.0, 1.0, -2.0])


func test_v10_save_migrates_with_nothing_felled_refused_by_redesign() -> void:
	var v10_data := {
		"version": 10,
		"day": 11,
		"party": [],
		"inventory": [],
		"placed_buildings": [],
		"farm_plots": [],
		"death_satchels": [],
		"satiety": 80.0,
		"map": {},
		"progression": {},
		"harvested_vegetation": {},
	}
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var file := FileAccess.open(saver.slot_path(1), FileAccess.WRITE)
	file.store_string(JSON.stringify(v10_data))
	file = null

	var read := _game(false)
	read.map = MAP_STATE.new()
	read.map.configure({})
	read.progression = PROGRESSION_STATE.new()
	_assert_old_slot_refused_unchanged(read, 1)


func test_every_readable_save_version_actually_loads() -> void:
	for version in range(1, SAVE_GAME.VERSION + 1):
		var written := _game()
		written.day = 7
		assert_true(saver.save(written, 2), "could not write the fixture")
		# Rewrite the version stamp in place: a real v6 file differs from a v9
		# one in more than this, but every migration above is defensive about
		# missing keys (that is what "nothing to migrate FROM" means), so the
		# version number alone is enough to prove the DISPATCH reaches them.
		var path: String = saver.slot_path(2)
		var file := FileAccess.open(path, FileAccess.READ)
		var data: Dictionary = JSON.parse_string(file.get_as_text())
		file.close()
		data["version"] = version
		_write_legacy_slot_json(2, data)

		var read := _game(false)
		if version <= SAVE_GAME.RESET_MAX_VERSION:
			_assert_old_slot_refused_unchanged(read, 2)
		else:
			assert_true(saver.load_slot(read, 2), "the current schema remains readable")
			assert_eq(read.day, 7, "current save retains its day")


func test_save_then_load_round_trips_a_placed_buildings_rotation() -> void:
	# BG1: `GameState.register_building` now takes a `yaw_deg`, stored as a
	# plain extra key on the same dictionary — save_game.gd itself does not
	# know or care about `yaw_deg` specifically, it round-trips whatever the
	# dictionary holds, so this proves the whole entry survives unharmed
	# rather than re-testing register_building's own shape.
	var written := _game()
	written.placed_buildings = [
		{"id": "wall", "position": [2.0, 0.0, 0.0], "yaw_deg": 90.0},
	]
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	assert_eq(read.placed_buildings.size(), 1)
	assert_almost_eq(float((read.placed_buildings[0] as Dictionary).get("yaw_deg", -1.0)), 90.0)


func test_save_then_load_round_trips_a_placed_buildings_state_payload() -> void:
	# R3.1-remainder: a placed storage chest's own contents ride along as an
	# opaque `state` key on its own placed_buildings entry -- save_game.gd
	# does not know or care what is inside it, the same as `yaw_deg` above.
	# GameState is what populates/consumes this key for real (via
	# build_placer.gd's sync_state_to_game / restore_from_game); this proves
	# only that save_game.gd itself carries the nested payload through a real
	# JSON round trip unharmed, whatever shape it turns out to hold.
	var written := _game()
	written.placed_buildings = [
		{"id": "storage", "position": [1.0, 0.0, 2.0], "state": [{"id": "wood", "n": 5}, null]},
	]
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	var entry := read.placed_buildings[0] as Dictionary
	var state: Array = entry.get("state", [])
	assert_eq(state.size(), 2)
	assert_eq((state[0] as Dictionary).get("id"), "wood")
	assert_eq(state[1], null)


func test_load_on_an_older_save_with_no_yaw_deg_does_not_crash_or_lose_the_entry() -> void:
	# A save written before BG1 shipped rotation has plain {id, position}
	# entries and no `yaw_deg` key at all. `save_game.gd` treats
	# `placed_buildings` opaquely, so this is really proving BG1 did not
	# quietly require a version bump `docs/decisions/D15`'s "carry on, do not
	# brick the player" rule would otherwise be broken by.
	var written := _game()
	written.placed_buildings = [{"id": "tent", "position": [0.0, 0.0, 0.0]}]
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	assert_eq(read.placed_buildings.size(), 1)
	assert_eq(str((read.placed_buildings[0] as Dictionary).get("id")), "tent")
	assert_false((read.placed_buildings[0] as Dictionary).has("yaw_deg"))


func test_load_on_a_missing_slot_returns_false_and_leaves_the_game_untouched() -> void:
	var game := _game()
	game.day = 4
	assert_false(saver.load_slot(game, 2))
	assert_eq(game.day, 4)
	assert_eq(game.party.size(), 1)


func test_load_on_a_corrupt_file_returns_false_and_leaves_the_game_untouched() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var file := FileAccess.open(saver.slot_path(1), FileAccess.WRITE)
	file.store_string("not valid json{{{")
	file = null

	var game := _game()
	game.day = 9
	assert_false(saver.load_slot(game, 1))
	assert_eq(game.day, 9)


func test_load_on_a_newer_version_refuses_and_leaves_the_game_untouched() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var file := FileAccess.open(saver.slot_path(1), FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": SAVE_GAME.VERSION + 1, "day": 99}))
	file = null

	var game := _game()
	game.day = 2
	assert_false(saver.load_slot(game, 1))
	assert_eq(game.day, 2, "a newer save must be left alone, not guessed at")


func test_version_twenty_five_pending_escrow_migrates_without_inventing_provenance_refused_by_redesign() -> void:
	var written := _game(false)
	written.local.character_id = "legacy-escrow-character"
	var escrow := {"pending-death": {
		"kind": "death_satchel_transfer", "status": "pending",
		"world_id": "slot-1", "character_id": "legacy-escrow-character",
		"stacks": [{"id": "wood", "n": 2}],
		"intent": {"kind": "death_satchel_transfer", "txn_id": "pending-death",
			"world_id": "slot-1", "character_id": "legacy-escrow-character",
			"stacks": [{"id": "wood", "n": 2}]},
	}}
	var payload: Dictionary = saver.snapshot(written)
	payload["version"] = 25
	payload["satchel_escrow"] = escrow
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var file := FileAccess.open(saver.slot_path(1), FileAccess.WRITE)
	file.store_string(JSON.stringify(payload))
	file.close()

	var loaded := _game(false)
	_assert_old_slot_refused_unchanged(loaded, 1)


func test_save_and_load_reject_an_out_of_range_slot() -> void:
	assert_false(saver.save(_game(), -1))
	assert_false(saver.save(_game(), SAVE_GAME.SLOT_COUNT))
	assert_false(saver.load_slot(_game(), -1))
	assert_false(saver.load_slot(_game(), SAVE_GAME.SLOT_COUNT))


func test_slot_info_reports_day_and_party_size_without_touching_the_caller() -> void:
	var written := _game()
	written.day = 3
	assert_true(saver.save(written, 2))

	var info: Dictionary = saver.slot_info(2)
	assert_eq(int(info.get("day")), 3)
	assert_eq(int(info.get("party_size")), 1)


func test_has_slot_reflects_what_was_actually_written() -> void:
	assert_false(saver.has_slot(0))
	saver.save(_game(), 0)
	assert_true(saver.has_slot(0))


func test_slots_are_independent_of_each_other() -> void:
	var first := _game()
	first.day = 1
	var second := _game(false)
	second.day = 42
	assert_true(saver.save(first, 0))
	assert_true(saver.save(second, 1))

	assert_eq(saver.slot_info(0).get("day"), 1)
	assert_eq(saver.slot_info(1).get("day"), 42)


# --- VERSION 2: creature progression, satiety, map, building yaw -----------------


func test_save_then_load_round_trips_creature_progression_and_moves() -> void:
	var written := _game()
	var creature: RefCounted = written.party.at(0)
	creature.level = 7
	creature.xp = 23
	creature.bond = 44
	creature.move_quick = "tackle"
	creature.move_charged = "slam"
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	var loaded: RefCounted = read.party.at(0)
	assert_eq(int(loaded.get("level")), 7)
	assert_eq(int(loaded.get("xp")), 23)
	assert_eq(int(loaded.get("bond")), 44)
	assert_eq(str(loaded.get("move_quick")), "tackle")
	assert_eq(str(loaded.get("move_charged")), "slam")


func test_save_then_load_round_trips_satiety_through_live_vitals() -> void:
	var written := _game()
	written._vitals = FakeVitals.new()
	written._vitals.satiety = 37.0
	assert_true(saver.save(written, 1))

	var read := _game(false)
	read._vitals = FakeVitals.new()
	assert_true(saver.load_slot(read, 1))
	assert_almost_eq(float(read._vitals.satiety), 37.0)


func test_save_then_load_round_trips_satiety_through_the_fallback_field() -> void:
	# No live vitals reachable on either side -- the headless-caller path.
	var written := _game()
	written.satiety = 42.0
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	assert_almost_eq(read.satiety, 42.0)


func test_save_then_load_round_trips_map_discovery() -> void:
	var written := _game()
	written.map = MAP_STATE.new()
	written.map.configure({})
	written.map.mark_visited(Vector3(10.0, 0.0, 10.0))
	assert_true(saver.save(written, 1))

	var read := _game(false)
	read.map = MAP_STATE.new()
	read.map.configure({})
	assert_true(saver.load_slot(read, 1))
	assert_true(read.map.is_discovered(Vector3(10.0, 0.0, 10.0)))
	assert_false(read.map.is_discovered(Vector3(-100.0, 0.0, -100.0)))


func test_save_then_load_round_trips_building_yaw() -> void:
	var written := _game()
	written.placed_buildings = [
		{"id": "tent", "position": [1.0, 0.0, -2.5], "yaw_deg": 90.0},
	]
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	var entry := read.placed_buildings[0] as Dictionary
	assert_almost_eq(float(entry.get("yaw_deg")), 90.0)


func test_v1_save_migrates_creatures_satiety_map_and_building_yaw_on_load_refused_by_redesign() -> void:
	var v1_data := {
		"version": 1,
		"day": 5,
		"party": [{
			"species_id": "terrapup",
			"display_name": "Terrapup",
			"creature_type": "ground",
			"nickname": "Old Save Creature",
			"max_hp": 120.0,
			"attack": 22.0,
			"defence": 20.0,
			"hp": 90.0,
			"energy": 0.0,
			"fainted": false,
		}],
		"inventory": [null, {"id": "wood", "n": 5}],
		"placed_buildings": [{"id": "tent", "position": [1.0, 0.0, 2.0]}],
	}
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var file := FileAccess.open(saver.slot_path(1), FileAccess.WRITE)
	file.store_string(JSON.stringify(v1_data))
	file = null

	var read := _game(false)
	read.map = MAP_STATE.new()
	read.map.configure({})
	read.progression = PROGRESSION_STATE.new()
	_assert_old_slot_refused_unchanged(read, 1)


func test_a_version_newer_than_this_build_is_refused() -> void:
	# R3.2: hardcoded to "version 4" before this build's own VERSION became 4,
	# which made this test start asserting the exact opposite of its own
	# intent the moment that bump landed. SAVE_GAME.VERSION + 1 keeps this
	# test meaning "newer than we can read" across every future bump instead
	# of needing a matching edit each time.
	var future_version: int = int(SAVE_GAME.VERSION) + 1
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var file := FileAccess.open(saver.slot_path(1), FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": future_version, "day": 55}))
	file = null

	var game := _game()
	game.day = 1
	assert_false(saver.load_slot(game, 1),
		"version %d is newer than this build's VERSION %d -- refuse it" % [future_version, SAVE_GAME.VERSION])
	assert_eq(game.day, 1)


# --- VERSION 3: SB9 progression flags ---------------------------------------


func test_save_then_load_round_trips_progression_flags() -> void:
	var written := _game()
	written.progression = PROGRESSION_STATE.new()
	written.progression.set_flag("bridge_unlocked")
	written.progression.set_flag("trainer_mira_defeated")
	assert_true(saver.save(written, 1))

	var read := _game(false)
	read.progression = PROGRESSION_STATE.new()
	assert_true(saver.load_slot(read, 1))
	assert_true(read.progression.has("bridge_unlocked"))
	assert_true(read.progression.completed("trainer_mira_defeated"))
	assert_false(read.progression.has("never_set"))


func test_completed_cloudreach_legacy_water_rewards_retarget_once_on_flat_load() -> void:
	var written := _game(false)
	var payload: Dictionary = saver.call("snapshot", written)
	payload["progression"] = {"flags": [
		"cloudreach_chapter_complete", "realm_key_water", "waterward_route_revealed",
		"unrelated_world_flag",
	]}
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var file := FileAccess.open(saver.slot_path(1), FileAccess.WRITE)
	file.store_string(JSON.stringify(payload))
	file.close()

	var first := _game(false)
	assert_true(saver.load_slot(first, 1))
	for id: String in ["realm_key_stormwood", "stormward_route_revealed",
			"cloudreach_reward_retargeted_stormwood", "unrelated_world_flag"]:
		assert_true(first.progression.has(id), "flat repair lost '%s'" % id)
	assert_false(first.progression.has("realm_key_water"))
	assert_false(first.progression.has("waterward_route_revealed"))

	# A saved repaired payload cannot re-run or recreate either old alias.
	assert_true(saver.save(first, 1))
	var second := _game(false)
	assert_true(saver.load_slot(second, 1))
	assert_false(second.progression.has("realm_key_water"))
	assert_false(second.progression.has("waterward_route_revealed"))
	assert_true(second.progression.has("cloudreach_reward_retargeted_stormwood"))


# --- VERSION 5: individuality and traits (R4.2) -----------------------------


func test_save_then_load_round_trips_individuality_and_traits() -> void:
	var written := _game()
	var creature: RefCounted = written.party.at(0)
	creature.iv_hp = 0.9
	creature.iv_attack = 0.1
	creature.iv_defence = 0.5
	creature.trait_primary = "bold"
	creature.trait_secondary = "calm"
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	var loaded: RefCounted = read.party.at(0)
	assert_almost_eq(float(loaded.get("iv_hp")), 0.9, 0.0001)
	assert_almost_eq(float(loaded.get("iv_attack")), 0.1, 0.0001)
	assert_almost_eq(float(loaded.get("iv_defence")), 0.5, 0.0001)
	assert_eq(str(loaded.get("trait_primary")), "bold")
	assert_eq(str(loaded.get("trait_secondary")), "calm")


func test_v4_save_migrates_with_average_individuality_and_no_traits_refused_by_redesign() -> void:
	var v4_data := {
		"version": 4,
		"day": 8,
		"party": [{
			"species_id": "terrapup",
			"display_name": "Terrapup",
			"creature_type": "ground",
			"nickname": "Pre-R4.2 Save",
			"max_hp": 120.0, "attack": 22.0, "defence": 20.0,
			"hp": 90.0, "energy": 0.0, "fainted": false,
			"level": 4, "xp": 10, "bond": 20,
			"move_quick": "pebble_toss", "move_charged": "stone_rush",
		}],
		"inventory": [],
		"placed_buildings": [],
		"death_satchels": [],
		"satiety": 80.0,
		"map": {},
		"progression": {},
	}
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var file := FileAccess.open(saver.slot_path(1), FileAccess.WRITE)
	file.store_string(JSON.stringify(v4_data))
	file = null

	var read := _game(false)
	read.map = MAP_STATE.new()
	read.map.configure({})
	read.progression = PROGRESSION_STATE.new()
	_assert_old_slot_refused_unchanged(read, 1)


func test_save_then_load_round_trips_shiny() -> void:
	var written := _game()
	var creature: RefCounted = written.party.at(0)
	creature.shiny = true
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	var loaded: RefCounted = read.party.at(0)
	assert_true(bool(loaded.get("shiny")))


func test_save_then_load_round_trips_a_non_shiny_creature_too() -> void:
	# The reverse case: `shiny` defaults false on `_game()`'s own creature, so
	# this proves `false` round-trips honestly rather than every load reading
	# as truthy because a bare presence check would.
	var written := _game()
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	assert_false(bool(read.party.at(0).get("shiny")))


func test_v5_save_migrates_with_shiny_false_refused_by_redesign() -> void:
	var v5_data := {
		"version": 5,
		"day": 9,
		"party": [{
			"species_id": "terrapup",
			"display_name": "Terrapup",
			"creature_type": "ground",
			"nickname": "Pre-OF27 Save",
			"max_hp": 120.0, "attack": 22.0, "defence": 20.0,
			"hp": 90.0, "energy": 0.0, "fainted": false,
			"level": 4, "xp": 10, "bond": 20,
			"move_quick": "pebble_toss", "move_charged": "stone_rush",
			"iv_hp": 0.6, "iv_attack": 0.4, "iv_defence": 0.5,
			"trait_primary": "bold", "trait_secondary": "",
		}],
		"inventory": [],
		"placed_buildings": [],
		"death_satchels": [],
		"satiety": 80.0,
		"map": {},
		"progression": {},
	}
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var file := FileAccess.open(saver.slot_path(1), FileAccess.WRITE)
	file.store_string(JSON.stringify(v5_data))
	file = null

	var read := _game(false)
	read.map = MAP_STATE.new()
	read.map.configure({})
	read.progression = PROGRESSION_STATE.new()
	_assert_old_slot_refused_unchanged(read, 1)


func test_v2_save_migrates_with_a_fresh_progression_store_refused_by_redesign() -> void:
	var v2_data := {
		"version": 2,
		"day": 6,
		"party": [],
		"inventory": [],
		"placed_buildings": [],
		"satiety": 80.0,
		"map": {},
	}
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var file := FileAccess.open(saver.slot_path(1), FileAccess.WRITE)
	file.store_string(JSON.stringify(v2_data))
	file = null

	var read := _game(false)
	read.progression = PROGRESSION_STATE.new()
	_assert_old_slot_refused_unchanged(read, 1)


func test_a_half_fought_bracket_survives_a_save() -> void:
	var game := _game()
	game.progression.set_flag("tournament_team_ready")
	game.progression.set_flag("tournament_training_ready")
	game.progression.set_flag("tournament_entered")
	game.progression.set_flag("tournament_quarter_won")
	assert_true(saver.save(game, 0))

	var loaded := _game()
	assert_true(saver.load_slot(loaded, 0))
	for flag: String in ["tournament_entered", "tournament_quarter_won"]:
		assert_true(bool(loaded.progression.has(flag)),
			"'%s' did not survive the save; the player is back outside the bracket" % flag)
	assert_false(bool(loaded.progression.has("tournament_semi_won")),
		"a round nobody has fought came back won")


## The board reads the same bracket after the reload -- the player is still
## standing in the semi-final, not sent back to the draw.
func test_the_board_reads_the_same_bracket_after_a_reload() -> void:
	var game := _game()
	game.progression.set_flag("tournament_entered")
	game.progression.set_flag("tournament_quarter_won")
	var before := TOURNAMENT.status_line(game.progression)
	assert_true(saver.save(game, 0))

	var loaded := _game()
	assert_true(saver.load_slot(loaded, 0))
	assert_eq(TOURNAMENT.status_line(loaded.progression), before,
		"the board forgot where the player was in the bracket")


## The first-clear reward is guarded by the defeat flag, so what makes it
## unfarmable across a reload is that flag surviving. A won final that came
## back unwon would pay its coins and its saddle pattern a second time.
func test_a_won_tournament_cannot_be_reloaded_into_a_second_payout() -> void:
	var game := _game()
	game.progression.set_flag("tournament_won")
	game.progression.set_flag("recipe_saddle")
	game.inventory.add("coin", 40)
	assert_true(saver.save(game, 0))

	var loaded := _game()
	assert_true(saver.load_slot(loaded, 0))
	assert_true(bool(loaded.progression.has("tournament_won")),
		"the victory flag did not survive; the final would pay out again")
	assert_true(bool(loaded.progression.has("recipe_saddle")),
		"the saddle pattern did not survive the save")
	assert_eq(int(loaded.inventory.count("coin")), 40,
		"the reward did not come back exactly once")


## RG19-spec/D68. Condition is part of the save now, and a team that was fed
## and rested before saving must not come back hungry -- that would refuse a
## qualified player their own tournament after a reload.
func test_condition_survives_a_save() -> void:
	var game := _game()
	var creature: RefCounted = game.party.at(0)
	creature.set("nourishment", 91.0)
	# Rest adds the configured +12 mood before the round trip; seed 76 so the
	# expected persisted post-rest value remains the intentionally non-max 88.
	creature.set("happiness", 76.0)
	CONDITION.note_rest_completed(creature, CONDITION.config())

	# `note_rest_completed` pays its own mood (`happiness.on_rest_completed`,
	# clamped at the meter's max), so the file is asked to carry what the
	# creature holds NOW, not the 88 set two lines up -- the original
	# assertion against 88.0 would have gone red the first time this test
	# actually ran. Both values must also differ from `creature_instance.gd`'s
	# own defaults (70 / 55), or a loader that dropped the keys would pass.
	var fed_before := float(creature.get("nourishment"))
	var happy_before := float(creature.get("happiness"))
	var rest_left_before := float(creature.get("rested_seconds_left"))
	assert_true(rest_left_before > 0.0, "the fixture never started the rest clock; the test proves nothing")
	assert_true(absf(fed_before - 70.0) > 1.0 and absf(happy_before - 55.0) > 1.0,
		"the fixture matches the class defaults; a loader that ignored the file would pass")
	assert_true(saver.save(game, 0))

	var loaded := _game()
	assert_true(saver.load_slot(loaded, 0))
	var back: RefCounted = loaded.party.at(0)
	assert_almost_eq(float(back.get("nourishment")), fed_before, 0.001, "the team came back hungry")
	assert_almost_eq(float(back.get("happiness")), happy_before, 0.001, "the team came back miserable")
	assert_true(bool(back.get("rested")), "a rested team came back tired")
	assert_almost_eq(float(back.get("rested_seconds_left")), rest_left_before, 0.001,
		"the rest clock did not survive; 'rested' would lapse on the wrong schedule")


## A save written before the condition model existed loads as a creature that
## was never measured, not as one that is starving.
func test_a_pre_condition_save_loads_at_the_configured_start_refused_by_redesign() -> void:
	var game := _game()
	assert_true(saver.save(game, 0))

	# Rewrite the slot as VERSION 12: the format immediately before D68.

	# Through `slot_path()`, not a hand-built name: the original
	# `"%ssave_0.json"` never matched the saver's `slot_%d.json`, so the
	# rewrite below opened nothing and the test aborted there.
	var path: String = saver.slot_path(0)
	var file := FileAccess.open(path, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text()) as Dictionary
	file.close()
	data["version"] = 12
	for raw: Variant in (data.get("party", []) as Array):
		(raw as Dictionary).erase("nourishment")
		(raw as Dictionary).erase("happiness")
		(raw as Dictionary).erase("rested_seconds_left")
	_write_legacy_slot_json(0, data)

	var loaded := _game()

	# Dirty the in-memory creature first, so "came back at the configured
	# start" cannot be the loader leaving the party it found alone.
	loaded.party.at(0).set("nourishment", 3.0)
	loaded.party.at(0).set("happiness", 2.0)
	_assert_old_slot_refused_unchanged(loaded, 0)


func test_save_then_load_round_trips_base_stats_and_survives_a_level_up() -> void:
	var distinct_definition := {
		"display_name": "Terrapup", "type": "ground",
		"base_hp": 105.0, "base_attack": 26.0, "base_defence": 19.0,
	}
	var written := _game(false)
	var creature: RefCounted = CREATURE.from_species("terrapup", distinct_definition)
	creature.level = 3
	written.party.add(creature)
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	var loaded: RefCounted = read.party.at(0)
	assert_almost_eq(float(loaded.get("base_hp")), 105.0, 0.001,
		"base_hp did not survive the save; the next level-up will rebuild stats from the class default of 1.0")
	assert_almost_eq(float(loaded.get("base_attack")), 26.0, 0.001)
	assert_almost_eq(float(loaded.get("base_defence")), 19.0, 0.001)

	# The defect's own signature: levelling a LOADED creature must land on
	# exactly the same stats as levelling the identical creature that was
	# never saved at all -- not a collapse toward the class default of 1.0.
	var cfg := PROGRESSION.config()
	var reference: RefCounted = CREATURE.from_species("terrapup", distinct_definition)
	reference.level = 3
	reference.gain_xp(reference.xp_to_next(cfg), cfg)
	loaded.gain_xp(loaded.xp_to_next(cfg), cfg)

	assert_eq(int(loaded.get("level")), int(reference.get("level")),
		"level-up did not land on the same level as the unsaved reference")
	assert_almost_eq(float(loaded.get("max_hp")), float(reference.get("max_hp")), 0.01,
		"GAME-F4: a loaded creature's first level-up collapsed toward the class default instead of growing normally")
	assert_almost_eq(float(loaded.get("attack")), float(reference.get("attack")), 0.01)
	assert_almost_eq(float(loaded.get("defence")), float(reference.get("defence")), 0.01)


## The migration case: a save written before this fix has no `base_hp`/
## `base_attack`/`base_defence` keys at all (every real fixture in
## `ralph/reports/` is this shape). `_array_to_party` must repair them from
## `species.json` by `species_id` -- the `apply_species_definition` repair two
## comments on this class already promised and neither ever implemented --
## rather than leaving the class default of 1.0 standing until the next
## level-up destroys the creature.
func test_a_pre_gamef4_save_migrates_base_stats_from_species_json_refused_by_redesign() -> void:
	var v15_data := {
		"version": 15,
		"day": 12,
		"world_seed": 0,
		"party": [{
			"species_id": "terrapup",
			"display_name": "Terrapup",
			"creature_type": "ground",
			"nickname": "Pre-GAME-F4 Save",
			"max_hp": 141.6, "attack": 27.28, "defence": 24.0,
			"hp": 141.6, "energy": 0.0, "fainted": false,
			"level": 3, "xp": 0, "bond": 0,
			"move_quick": "pebble_toss", "move_charged": "stone_rush",
		}],
		"inventory": [],
		"hotbar": [],
		"placed_buildings": [],
		"farm_plots": [],
		"death_satchels": [],
		"satiety": 80.0,
		"map": {},
		"progression": {},
		"harvested_vegetation": {},
		"felled_vegetation": {},
	}
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var file := FileAccess.open(saver.slot_path(1), FileAccess.WRITE)
	file.store_string(JSON.stringify(v15_data))
	file = null

	var read := _game(false)
	read.map = MAP_STATE.new()
	read.map.configure({})
	read.progression = PROGRESSION_STATE.new()
	_assert_old_slot_refused_unchanged(read, 1)


func test_the_hour_survives_a_save_and_reload() -> void:
	var written := _game(false)
	# 19:40 on `art.json`'s 600-second day: late enough to be a different look
	# from 08:00, and deliberately NOT a keyframe hour, so a loader that snapped
	# to the nearest authored preset instead of restoring the real elapsed time
	# would fail this.
	var evening := 600.0 * (19.0 + 40.0 / 60.0) / 24.0
	written.clock_elapsed_seconds = evening
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(read.clock_elapsed_seconds < 0.0,
		"the fixture already holds a clock; a loader that ignored the file would pass")
	assert_true(saver.load_slot(read, 1))
	assert_almost_eq(read.clock_elapsed_seconds, evening, 0.001,
		"the clock did not survive the save: a Continue puts the player back at 08:00 and night never falls")


## A save written before VERSION 19 has no memory of the hour, and the migration
## must say so rather than invent one -- the sentinel opens that save at the
## authored morning, exactly as the old build did.
func test_a_pre_clock_save_loads_with_no_carried_hour_refused_by_redesign() -> void:
	var written := _game(false)
	written.clock_elapsed_seconds = 480.0
	assert_true(saver.save(written, 1))

	var raw := _read_slot_json(1)
	assert_true(raw.has("clock_elapsed_seconds"), "VERSION 19 must write the clock key")
	raw.erase("clock_elapsed_seconds")
	raw["version"] = 18
	_write_slot_json(1, raw)

	var read := _game(false)
	read.clock_elapsed_seconds = 123.0
	_assert_old_slot_refused_unchanged(read, 1)


func test_a_corrupt_clock_falls_back_to_no_carried_hour() -> void:
	for junk: Variant in ["nineteen", null, {"hour": 19}, [19.0], true]:
		var written := _game(false)
		written.clock_elapsed_seconds = 480.0
		assert_true(saver.save(written, 1))
		var raw := _read_slot_json(1)
		raw["clock_elapsed_seconds"] = junk
		_write_slot_json(1, raw)

		var read := _game(false)
		assert_true(saver.load_slot(read, 1), "a corrupt clock must not refuse the whole save")
		assert_true(read.clock_elapsed_seconds < 0.0,
			"a corrupt clock (%s) restored as something other than the sentinel" % [junk])


func _read_slot_json(slot: int) -> Dictionary:
	var file := FileAccess.open(saver.slot_path(slot), FileAccess.READ)
	assert_true(file != null, "slot %d was never written" % slot)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}


func _write_slot_json(slot: int, data: Dictionary) -> void:
	_write_legacy_slot_json(slot, data)


## Tests that rewrite a current save into an older/corrupt FLAT fixture must
## remove the current split pair too. Once `split_locator` exists, production
## correctly treats the split files as authority and ignores edits to the flat
## recovery copy; leaving them present would test that safety rule instead of
## the migration named by the test.
func _write_legacy_slot_json(slot: int, data: Dictionary) -> void:
	var ids: Array[String] = ["slot-%d" % slot, "legacy-slot-%d" % slot]
	var locator: Variant = data.get(SAVE_GAME.SPLIT_LOCATOR_KEY)
	if locator is Dictionary:
		for key: String in ["world_id", "character_id"]:
			var id := str((locator as Dictionary).get(key, ""))
			if not id.is_empty() and not ids.has(id):
				ids.append(id)
	for id: String in ids:
		(saver.call("worlds") as RefCounted).call("delete", id)
		(saver.call("characters") as RefCounted).call("delete", id)
	data.erase(SAVE_GAME.SPLIT_LOCATOR_KEY)
	var file := FileAccess.open(saver.slot_path(slot), FileAccess.WRITE)
	assert_true(file != null, "could not rewrite slot %d" % slot)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))


func test_party_codec_preserves_uid_and_ordered_tournament_selection() -> void:
	var source := PARTY.new()
	for i in 5:
		source.add(CREATURE.from_species("terrapup", {
			"display_name": "Member %d" % i, "type": "ground", "base_hp": 100.0,
			"base_attack": 20.0, "base_defence": 20.0}))
	assert_true(source.set_tournament_selection([2, 4, 0]))
	var ids: Array[String] = source.tournament_selection_ids()
	var encoded: Array = saver._party_to_array(source)

	var restored := PARTY.new()
	saver._array_to_party(encoded, restored)
	saver._restore_tournament_selection(ids, restored)
	assert_eq(restored.tournament_selection_ids(), ids)
	assert_eq(str(restored.tournament_selection()[0].display_name), "Member 2")


func test_duplicate_saved_uids_are_reminted_and_invalidate_selection() -> void:
	var source := PARTY.new()
	for i in 3:
		source.add(CREATURE.from_species("terrapup", {
			"display_name": "Member %d" % i, "type": "ground", "base_hp": 100.0,
			"base_attack": 20.0, "base_defence": 20.0}))
	var encoded: Array = saver._party_to_array(source)
	var duplicate := str((encoded[0] as Dictionary).uid)
	(encoded[1] as Dictionary).uid = duplicate
	(encoded[2] as Dictionary).uid = duplicate

	var restored := PARTY.new()
	saver._array_to_party(encoded, restored)
	saver._restore_tournament_selection([duplicate,
		str(restored.at(1).uid), str(restored.at(2).uid)], restored)
	assert_eq(restored.tournament_selection(), [], "ambiguous saved identity fails closed")
	var seen: Dictionary = {}
	for creature: RefCounted in restored.members():
		assert_true(CREATURE.valid_uid(str(creature.uid)))
		assert_false(seen.has(creature.uid), "every loaded creature is left uniquely addressable")
		seen[creature.uid] = true


func test_v26_migration_keeps_progression_and_defaults_unregistered() -> void:
	var flags := {"flags": ["tournament_team_ready", "tournament_training_ready",
		"tournament_quarter_won"]}
	var migrated: Dictionary = saver._migrate_v26({"version": 26, "progression": flags})
	assert_eq(int(migrated.version), 27)
	assert_eq(migrated.tournament_selection, [])
	assert_eq(migrated.progression, flags, "readiness milestones and bracket wins remain sticky")


func test_disk_save_load_preserves_five_owned_uids_selection_order_and_round_flags() -> void:
	var written := _game(false)
	for i in 5:
		written.party.add(CREATURE.from_species("terrapup", {
			"display_name": "Entrant %d" % i, "type": "ground", "base_hp": 100.0,
			"base_attack": 20.0, "base_defence": 20.0}))
	assert_true(written.party.set_tournament_selection([3, 0, 4]))
	var selected_ids: Array[String] = written.party.tournament_selection_ids()
	for flag: String in ["tournament_team_ready", "tournament_training_ready", "tournament_quarter_won"]:
		written.progression.set_flag(flag)
	assert_true(saver.save(written, 0))

	var loaded := _game(false)
	assert_true(saver.load_slot(loaded, 0))
	assert_eq(loaded.party.size(), 5, "disk reload must retain the complete owned five")
	assert_eq(loaded.party.tournament_selection_ids(), selected_ids,
		"disk reload must retain the registered order by durable UID")
	assert_eq(str(loaded.party.tournament_selection()[0].get("display_name")), "Entrant 3")
	for flag: String in ["tournament_team_ready", "tournament_training_ready", "tournament_quarter_won"]:
		assert_true(loaded.progression.has(flag), "round/readiness flag '%s' was lost" % flag)

## RD-35 supersedes migration-through-load. Historical direct migration-helper
## tests remain; old fixtures exercise typed refusal and preserve every live value.
func _assert_old_slot_refused_unchanged(game: Object, slot: int) -> void:
	var path: String = saver.slot_path(slot)
	var disk_before := FileAccess.get_file_as_bytes(path)
	var modified_before := FileAccess.get_modified_time(path)
	var live_before: Dictionary = saver.snapshot(game).duplicate(true)
	var world_ids: Array = saver.worlds().list_ids().duplicate()
	var character_ids: Array = saver.characters().list_ids().duplicate()
	assert_false(saver.load_slot(game, slot), "RD-35 refuses the old schema")
	assert_eq(str(saver.last_load_result.get("code", "")), "incompatible_old_version")
	assert_true(str(saver.last_load_result.get("message", "")).to_lower().contains("start a new game"))
	assert_eq(saver.snapshot(game), live_before, "refusal changes no live state")
	assert_eq(FileAccess.get_file_as_bytes(path), disk_before, "refusal preserves original bytes")
	assert_eq(FileAccess.get_modified_time(path), modified_before, "refusal never rewrites the file")
	assert_eq(saver.worlds().list_ids(), world_ids, "refusal mints no split world")
	assert_eq(saver.characters().list_ids(), character_ids, "refusal mints no portable character")
