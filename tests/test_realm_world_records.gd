extends "res://tests/test_case.gd"

const GAME := preload("res://autoload/game_state.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const RECORDS := preload("res://scripts/world/realm_world_records.gd")
const DEATH := preload("res://scripts/world/player_death.gd")
const PLACER := preload("res://scripts/build/build_placer.gd")
const HOME := preload("res://scripts/build/home_progress.gd")
const DIR := "user://test_realm_world_records/"
var game: Node
var saves: RefCounted


func before_each() -> void:
	game = GAME.new()
	game.reset_for_new_game()
	saves = SAVE.new(DIR)


func after_each() -> void:
	game.free()
	for slot in SAVE.SLOT_COUNT:
		if FileAccess.file_exists(saves.slot_path(slot)):
			DirAccess.remove_absolute(saves.slot_path(slot))


func test_legacy_migration_defaults_to_meadows_not_current_realm_and_preserves_indices() -> void:
	var original := {"version": 19, "current_realm": "cloudreach",
		"placed_buildings": [{"id": "storage", "state": [{"id": "axe", "n": 1, "durability": 3}]}, null,
			{"id": "bedroll", "realm": "cloudreach", "position": [1, 700, 2]}],
		"death_satchels": [{"position": [1,2,3], "state": [{"id": "wood", "n": 2}]}],
		"realm_maps": {"meadows": {"visited_b64": "abc"}}, "realm_hearts": {"active": "meadows"},
		"player_pose": {"traversal": {"mode": "flying"}}}
	var migrated: Dictionary = saves._migrate_to_current(original, 19, 0)
	assert_eq(migrated.version, SAVE.VERSION)
	assert_eq(migrated.placed_buildings[0].realm, "meadows")
	assert_eq(migrated.placed_buildings[1], null)
	assert_eq(migrated.placed_buildings[2].realm, "cloudreach")
	assert_eq(migrated.death_satchels[0].realm, "meadows")
	for key: String in ["realm_maps", "realm_hearts", "player_pose"]:
		assert_eq(migrated[key], original[key])
	assert_eq(migrated.placed_buildings[0].state, original.placed_buildings[0].state)
	assert_false(original.placed_buildings[0].has("realm"), "migration never mutates caller data")
	assert_eq(RECORDS.normalized("malformed"), [])


func test_real_save_there_and_back_preserves_multiple_satchels_and_buildings() -> void:
	for realm: String in ["meadows", "cloudreach"]:
		game.current_realm = realm
		game.register_building("bedroll", Vector3(1, 700 if realm == "cloudreach" else 0, 2), 90)
		for i in 2:
			var index: int = game.register_death_satchel(Vector3(i, 1, 5))
			game.death_satchels[index].state = [{"id": "axe", "n": 1, "durability": i + 3}]
	var buildings: Array = game.placed_buildings.duplicate(true)
	var satchels: Array = game.death_satchels.duplicate(true)
	for realm: String in ["cloudreach", "meadows", "cloudreach"]:
		game.current_realm = realm
		game.bind_realm_map()
		assert_true(saves.save(game, 0))
		game.placed_buildings.clear()
		game.death_satchels.clear()
		assert_true(saves.load_slot(game, 0))
		assert_eq(game.current_realm, realm)
		assert_eq(game.placed_buildings, buildings)
		assert_eq(JSON.parse_string(JSON.stringify(game.death_satchels)), JSON.parse_string(JSON.stringify(satchels)), "JSON preserves numeric values, not integer Variant tags")
		assert_eq(RECORDS.for_realm(game.placed_buildings, realm).size(), 1)
		assert_eq(RECORDS.for_realm(game.death_satchels, realm).size(), 2)


func test_home_selection_and_cloudreach_authored_camps_cannot_cross_realms_or_unlocks() -> void:
	var records := [{"id": "bedroll", "realm": "cloudreach", "position": [1,700,2]},
		{"id": "bedroll", "position": [5,0,6]}]
	assert_eq(DEATH.resolve_home(records, Vector3.ZERO), Vector3(5,0,6))
	assert_eq(DEATH.resolve_home(records, Vector3.ZERO, "cloudreach"), Vector3(1,700,2))
	assert_eq(DEATH.resolve_home([records[1]], Vector3(4,600,8), "cloudreach"), Vector3(4,600,8))
	var camps := [{"position": [0,100,0], "requires_flag": ""},
		{"position": [0,800,0], "requires_flag": "upper_open"}]
	var resolver := func(at: Vector3) -> float: return at.y
	assert_eq(DEATH.resolve_safe_camp(camps, game.progression, Vector3(0,800,0), Vector3.ZERO, resolver), Vector3(2,101,2))
	game.progression.set_flag("upper_open")
	assert_eq(DEATH.resolve_safe_camp(camps, game.progression, Vector3(0,800,0), Vector3.ZERO, resolver), Vector3(2,801,2))
	assert_eq(DEATH.resolve_safe_camp(camps, game.progression, Vector3.ZERO, Vector3(1,2,3), func(_at: Vector3) -> float: return NAN), Vector3(1,2,3))


func test_cloudreach_records_do_not_block_snap_or_satisfy_meadows_home() -> void:
	game.free_build = true
	var records := [{"id": "floor", "realm": "cloudreach", "position": [0,0,0]}]
	var ground := func(_at: Vector3) -> float: return 0.0
	assert_true(PLACER.evaluate_placement(game, "floor", Vector3.ZERO, records, ground).ok)
	game.current_realm = "cloudreach"
	assert_true(PLACER.evaluate_placement(game, "floor", Vector3.ZERO, records, ground).snapped_to_neighbour,
		"same-realm floor participates in structural snapping; foreign floor did not")
	var required: Dictionary = HOME.required_pieces()
	for id: String in required:
		for i in int(required[id]):
			game.register_building(id, Vector3(i,800,3))
	HOME.maybe_set_home_built(game)
	HOME.maybe_set_creature_beds(game)
	assert_false(game.progression.has("home_built"))
	assert_false(game.progression.has("creature_bed_built"))
	game.current_realm = "meadows"
	for id: String in required:
		for i in int(required[id]):
			game.register_building(id, Vector3(i,0,3))
	HOME.maybe_set_home_built(game)
	HOME.maybe_set_creature_beds(game)
	assert_true(game.progression.has("home_built"))
	assert_true(game.progression.has("creature_bed_built"))
	var meadows_counts: Dictionary = HOME.pieces_built(game.placed_buildings)
	game.current_realm = "cloudreach"
	game.register_building("bedroll", Vector3(3,800,2))
	assert_eq(HOME.pieces_built(game.placed_buildings), meadows_counts)
	assert_true(game.progression.has("home_built"))
