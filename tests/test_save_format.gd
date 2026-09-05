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

const TEST_DIR := "user://test_saves_format/"

## Stands in for `scripts/player/player_vitals.gd` — save_game.gd only ever
## reads/writes a `satiety`/`max_satiety` pair on whatever `player_vitals()`
## returns, so this bare-bones double is enough to exercise the "live vitals
## reachable" half of the satiety seam without a scene tree.
class FakeVitals:
	extends RefCounted
	var satiety: float = 100.0
	var max_satiety: float = 100.0

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
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			dir.remove(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()


func _game(seed_party: bool = true) -> RefCounted:
	var game := FakeGame.new()
	game.party = PARTY.new()
	game.inventory = INVENTORY.new(db)
	game.progression = PROGRESSION_STATE.new()
	game.realm_hearts = REALM_HEART_STATE.new()
	if seed_party:
		var creature: RefCounted = CREATURE.from_species("terrapup", {
			"display_name": "Terrapup", "type": "ground", "base_hp": 100.0,
			"base_attack": 20.0, "base_defence": 20.0,
		})
		creature.nickname = "Biscuit"
		creature.take_damage(35.0)
		game.party.add(creature)
	return game


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
	var out := FileAccess.open(path, FileAccess.WRITE)
	out.store_string(JSON.stringify(data, "\t"))
	out.close()

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	assert_eq(read.saved_player_pose, {}, "a malformed pose should use the world's authored spawn")


func test_version_11_save_loads_without_inventing_a_player_pose() -> void:
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
	var out := FileAccess.open(path, FileAccess.WRITE)
	out.store_string(JSON.stringify(data, "\t"))
	out.close()

	var read := _game(false)
	assert_true(saver.load_slot(read, 1), "the pre-RG7 format should migrate")
	assert_eq(read.saved_player_pose, {}, "an old save should retain normal authored-spawn fallback")


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
func test_save_then_load_repairs_missing_base_stats_from_species_json() -> void:
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

	assert_true(saver.load_slot(game, 1))
	var loaded: RefCounted = game.party.at(0)
	assert_almost_eq(float(loaded.get("base_hp")), 115.0)
	assert_almost_eq(float(loaded.get("base_attack")), 16.0)
	assert_almost_eq(float(loaded.get("base_defence")), 17.0)


## GATE-F-LEG-S07's own version of the same species-lookup fallback coverage:
## a save written before this fix has no `base_hp`/`base_attack`/
## `base_defence` keys at all and must reconstruct them from `species.json`
## rather than falling back to `CreatureInstance`'s own bare class defaults.
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
	var out := FileAccess.open(path, FileAccess.WRITE)
	out.store_string(JSON.stringify(data, "\t"))
	out.close()

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


func test_v9_save_migrates_with_nothing_harvested() -> void:
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
	assert_true(saver.load_slot(read, 1))

	assert_eq(read.day, 11)
	assert_eq(read.harvested_vegetation, {}, "a save predating HARVEST-ALL has nothing chopped yet")


## T3-ENCOUNTER / VERSION 15. The world seed IS the rolled wild population:
## `encounter_director.gd` derives every rolled cluster's species from
## (world_seed, order) rather than storing it, which is what lets a rolled world
## need no per-creature persistence. The whole of that rests on this one integer
## surviving a save.
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
func test_a_save_predating_rolled_populations_loads_the_authored_world() -> void:
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
	assert_true(saver.load_slot(read, 1))
	assert_eq(read.world_seed, 0,
		"a save predating rolled populations must load the authored world, not whatever was in memory")


## RG9 / VERSION 11. A tree chopped but never picked up must come back on
## reload with its felled pile still standing -- the wood the chop already
## earned must not silently vanish just because the player saved before
## walking over to collect it.
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


func test_v10_save_migrates_with_nothing_felled() -> void:
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
	assert_true(saver.load_slot(read, 1))

	assert_eq(read.day, 11)
	assert_eq(read.felled_vegetation, {}, "a save predating RG9 has nothing felled-but-ungathered yet")


## The gap this file did not have a test for, and which shipped: `load_slot`
## used to dispatch migrations through a hand-written per-version `if/elif`
## ladder that carried branches for versions 1-5 and none for 6 or 7, so a
## save written between the hotbar change and the elixir one was REFUSED even
## though `_migrate_v6` and `_migrate_v7` both existed and worked. R7.6
## replaced the ladder with a loop; this asserts the property the ladder could
## not keep — EVERY version this build claims to read actually loads.
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
		var out := FileAccess.open(path, FileAccess.WRITE)
		out.store_string(JSON.stringify(data, "\t"))
		out.close()

		var read := _game(false)
		assert_true(saver.load_slot(read, 2),
			"a version %d save did not load, but this build claims to read %d"
				% [version, SAVE_GAME.VERSION])
		assert_eq(read.day, 7, "a version %d save loaded but lost its day" % version)


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


func test_v1_save_migrates_creatures_satiety_map_and_building_yaw_on_load() -> void:
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
	assert_true(saver.load_slot(read, 1))

	assert_eq(read.day, 5)

	var creature: RefCounted = read.party.at(0)
	assert_eq(str(creature.get("nickname")), "Old Save Creature")
	assert_eq(int(creature.get("level")), 3, "migration.v1_creature_level from progression.json")
	assert_eq(int(creature.get("xp")), 0)
	assert_eq(int(creature.get("bond")), 0)
	assert_eq(str(creature.get("move_quick")), "pebble_toss", "terrapup's own species.json moves")
	assert_eq(str(creature.get("move_charged")), "stone_rush")

	assert_eq(read.inventory.stack_at(1), {"id": "wood", "n": 5})

	assert_eq(read.placed_buildings.size(), 1)
	var building := read.placed_buildings[0] as Dictionary
	assert_almost_eq(float(building.get("yaw_deg", -1.0)), 0.0)

	assert_almost_eq(read.satiety, 100.0, 0.0001, "a v1 save has no satiety on record; migrate to full")
	assert_almost_eq(read.map.discovered_fraction(), 0.0, 0.0001, "a v1 save predates the map; fog stays fresh")
	assert_eq(read.progression.all_set(), [], "a v1 save predates progression flags too; nothing to recover")


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


func test_v4_save_migrates_with_average_individuality_and_no_traits() -> void:
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
	assert_true(saver.load_slot(read, 1))

	assert_eq(read.day, 8)
	var creature: RefCounted = read.party.at(0)
	assert_eq(str(creature.get("nickname")), "Pre-R4.2 Save")
	assert_almost_eq(float(creature.get("iv_hp")), 0.5, 0.0001, "a save predating R4.2 reads as perfectly average")
	assert_almost_eq(float(creature.get("iv_attack")), 0.5, 0.0001)
	assert_almost_eq(float(creature.get("iv_defence")), 0.5, 0.0001)
	assert_eq(str(creature.get("trait_primary")), "", "a save predating R4.2 has no trait to recover")
	assert_eq(str(creature.get("trait_secondary")), "")


# --- VERSION 6: shiny (OF27) -------------------------------------------------


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


func test_v5_save_migrates_with_shiny_false() -> void:
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
	assert_true(saver.load_slot(read, 1))

	assert_eq(read.day, 9)
	var creature: RefCounted = read.party.at(0)
	assert_eq(str(creature.get("nickname")), "Pre-OF27 Save")
	assert_false(bool(creature.get("shiny")), "a save predating OF27 reads as not shiny, never retroactively rare")
	# The fields VERSION 5 already carried must still be intact after the
	# extra migration step -- a shiny migration that clobbers individuality
	# would be its own regression.
	assert_almost_eq(float(creature.get("iv_hp")), 0.6, 0.0001)
	assert_eq(str(creature.get("trait_primary")), "bold")


func test_v2_save_migrates_with_a_fresh_progression_store() -> void:
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
	assert_true(saver.load_slot(read, 1))
	assert_eq(read.day, 6)
	assert_almost_eq(read.satiety, 80.0)
	assert_eq(read.progression.all_set(), [], "a v2 save predates progression flags; nothing to recover")


## --- the tournament across a save (26-RG19) -----------------------------------

## 26-RG19's own acceptance list: "save/load does not duplicate rewards or
## regress to pre-tournament objective." The bracket is nothing but flags and
## a satchel, so this is the whole of that requirement -- and until now
## nothing tested it at all.
func test_a_half_fought_bracket_survives_a_save() -> void:
	var game := _game()
	game.progression.set_flag("tournament_team_ready")
	game.progression.set_flag("tournament_training_ready")
	game.progression.set_flag("tournament_entered")
	game.progression.set_flag("tournament_quarter_won")
	assert_true(saver.save_game(game, 0))

	var loaded := _game()
	assert_true(saver.load_game(loaded, 0))
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
	assert_true(saver.save_game(game, 0))

	var loaded := _game()
	assert_true(saver.load_game(loaded, 0))
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
	assert_true(saver.save_game(game, 0))

	var loaded := _game()
	assert_true(saver.load_game(loaded, 0))
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
	creature.set("happiness", 88.0)
	CONDITION.note_rest_completed(creature, CONDITION.config())
	assert_true(saver.save_game(game, 0))

	var loaded := _game()
	assert_true(saver.load_game(loaded, 0))
	var back: RefCounted = loaded.party.at(0)
	assert_almost_eq(float(back.get("nourishment")), 91.0, 0.001, "the team came back hungry")
	assert_almost_eq(float(back.get("happiness")), 88.0, 0.001, "the team came back miserable")
	assert_true(bool(back.get("rested")), "a rested team came back tired")


## A save written before the condition model existed loads as a creature that
## was never measured, not as one that is starving.
func test_a_pre_condition_save_loads_at_the_configured_start() -> void:
	var game := _game()
	assert_true(saver.save_game(game, 0))

	# Rewrite the slot as VERSION 12: the format immediately before D68.
	var path := "%ssave_0.json" % TEST_DIR
	var file := FileAccess.open(path, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text()) as Dictionary
	file.close()
	data["version"] = 12
	for raw: Variant in (data.get("party", []) as Array):
		(raw as Dictionary).erase("nourishment")
		(raw as Dictionary).erase("happiness")
		(raw as Dictionary).erase("rested_seconds_left")
	var out := FileAccess.open(path, FileAccess.WRITE)
	out.store_string(JSON.stringify(data))
	out.close()

	var loaded := _game()
	assert_true(saver.load_game(loaded, 0), "a version 12 save no longer loads at all")
	var back: RefCounted = loaded.party.at(0)
	var cfg: Dictionary = CONDITION.config()
	assert_almost_eq(float(back.get("nourishment")),
		float(cfg.get("nourishment", {}).get("start", 70.0)), 0.001,
		"a creature from before the model came back starving rather than unmeasured")
	assert_almost_eq(float(back.get("happiness")),
		float(cfg.get("happiness", {}).get("start", 55.0)), 0.001)


# --- GAME-F4: base stats must survive a save/load, or the next level-up ------
# destroys the creature (`_apply_level_stats` recomputes max_hp/attack/defence
# FROM base_hp/base_attack/base_defence every time; those three were never
# written to the save at all, so a loaded creature silently carried the class
# default of 1.0 until its next level-up, elixir or evolve rebuilt it from
# that -- a level 4 Terrapup with 1.18 max hp instead of ~124. Measured in
# play and reproduced here without a world.


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
func test_a_pre_gamef4_save_migrates_base_stats_from_species_json() -> void:
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
	assert_true(saver.load_slot(read, 1))

	var creature: RefCounted = read.party.at(0)
	# terrapup's real data/creatures/species.json entry, not the 100/20/20
	# shorthand this file's own `_game()` fixture uses for a fresh instance.
	assert_almost_eq(float(creature.get("base_hp")), 120.0, 0.001,
		"a save predating GAME-F4 must repair base_hp from species.json, not leave it at the class default of 1.0")
	assert_almost_eq(float(creature.get("base_attack")), 22.0, 0.001)
	assert_almost_eq(float(creature.get("base_defence")), 20.0, 0.001)

	# Prove it the way the audit did: level the migrated creature up and
	# confirm it grows instead of collapsing toward the class default.
	var cfg := PROGRESSION.config()
	creature.gain_xp(int(creature.call("xp_to_next", cfg)), cfg)
	assert_true(float(creature.get("max_hp")) > 10.0,
		"GAME-F4: a migrated creature's first level-up collapsed its stats toward the class default of 1.0")
