extends SceneTree

## GATEB-FLAGS (68-CHAPTER/17-RG18). Drives each of the four real trigger
## sites this task wired and asserts the CONTRACT flag data/progression/
## objectives.json names actually lands in `progression`'s flag store.
##
## Every check here was run against pre-wiring `main` while this file was
## being written and failed for the expected reason: `creature_bed.gd::
## build_real`, `player_bed.gd::_pass_the_night`, `build_placer.gd::
## restore_from_game`/`_place` and `harvest_node.gd::_on_gathered` set none
## of these flags before this task's changes, so the corresponding
## `progression.has(...)` came back false where this file now asserts true.
##
## Same harness shape as `smoke_gate_a_build_house.gd`: a flat world, the
## real `Game` autoload, a real `BuildPlacer`. This file drives the
## trigger METHODS directly (`build_real`, `_pass_the_night`,
## `restore_from_game`, `gather`) rather than replaying physical input --
## the flags under test are about what those calls DO, not about controller
## feel, which is `smoke_gate_a_build_house.gd`'s job already.

const BUILD_PLACER := preload("res://scripts/build/build_placer.gd")
const PLAYER_BED := preload("res://scripts/build/player_bed.gd")
const CREATURE_BED := preload("res://scripts/build/creature_bed.gd")
const HARVEST_NODE := preload("res://scripts/world/harvest_node.gd")
const HOME_PROGRESS := preload("res://scripts/build/home_progress.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")

## Never touch a player's real save directory from a regression: passing the
## night through player_bed.gd's real `_on_rest` autosaves.
const TEST_DIR := "user://test_saves_gateb_flags/"

class FlatWorld extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0

var _game: Node
var _world: Node3D
var _player: Node3D
var _placer: Node
var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_wipe_test_dir()
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_fail("Game autoload is missing")
		_finish()
		return
	# Never touch a player's real save directory from a regression.
	_game.set("save_system", SAVE_GAME.new(TEST_DIR))
	_game.set("pending_build", "")
	_game.set("free_build", false)
	_game.set("placed_buildings", [])
	var progression: RefCounted = _game.get("progression")
	# Clear every flag a previous test file may have left set, without
	# touching inventory/items/anything else `progression` is not.
	progression.call("load_data", {})

	_world = FlatWorld.new()
	root.add_child(_world)
	_player = Node3D.new()
	_player.name = "Player"
	_world.add_child(_player)
	_placer = BUILD_PLACER.new()
	_placer.name = "BuildPlacer"
	_placer.set("player_path", NodePath("../Player"))
	_world.add_child(_placer)
	await physics_frame

	_check_creature_bed_flag()
	_check_three_creature_beds()
	_check_home_built_flag()
	await _check_player_slept_flag()
	_check_materials_gathered_flag()

	_finish()


func _check_creature_bed_flag() -> void:
	var progression: RefCounted = _game.get("progression")
	if bool(progression.call("has", "creature_bed_built")):
		_fail("creature_bed_built was already set before any bed was placed")
	var bed := CREATURE_BED.new()
	bed.name = "TestBed"
	_world.add_child(bed)
	bed.call("build_real")
	if not bool(progression.call("has", "creature_bed_built")):
		_fail("creature_bed.gd::build_real did not set creature_bed_built")


## TUTORIAL-CHAIN (OP23-04) / owner directive 2026-08-23 section 1: the ladder
## asks for a Creature Bed per tournament entrant, and the counted rung fills
## from these three flags. Driven the same way `_check_home_built_flag()` below
## drives `home_built` -- `register_building` is the exact bookkeeping
## `build_placer._place` performs after a real placement, and
## `restore_from_game` is the call site that reads it -- so this is a faithful
## replay of "three beds are standing", not a shortcut around the trigger.
##
## Verified to fail against pre-TUTORIAL-CHAIN `main`: nothing set
## `creature_bed_built_2` or `_3`, so the second assertion below came back
## false where it now asserts true.
func _check_three_creature_beds() -> void:
	var progression: RefCounted = _game.get("progression")
	for id: String in ["creature_bed_built", "creature_bed_built_2", "creature_bed_built_3"]:
		progression.call("set_flag", id, false)
	_game.set("placed_buildings", [])

	# Two beds standing is TWO flags. A count that latches all three off one
	# placement would tick the rung the moment the player builds their first
	# bed, which is the defect the directive is about.
	for i in 2:
		_game.call("register_building", "creature_bed", Vector3(float(i) * 3.0, 0.0, 20.0))
	_placer.call("restore_from_game", _game)
	if not bool(progression.call("has", "creature_bed_built_2")):
		_fail("two placed Creature Beds did not set creature_bed_built_2")
	if bool(progression.call("has", "creature_bed_built_3")):
		_fail("creature_bed_built_3 fired with only two beds standing; the rung would "
			+ "read 3/3 and close a step the player has not finished")

	_game.call("register_building", "creature_bed", Vector3(6.0, 0.0, 20.0))
	_placer.call("restore_from_game", _game)
	if not bool(progression.call("has", "creature_bed_built_3")):
		_fail("a third placed Creature Bed did not set creature_bed_built_3; the "
			+ "ladder's bed rung can never complete")
	_game.set("placed_buildings", [])


## Drives `build_placer.gd::restore_from_game` -- the same `maybe_set_home_
## built` call site `_place` uses, and the one that also has to answer
## correctly for an out-of-order/older save (spec's own persistence rule).
## `register_building` is the exact bookkeeping `_place` performs after a
## real placement, so filling `placed_buildings` this way and then asking
## the placer to rebuild from it is a faithful replay of "the required
## pieces are standing," not a shortcut around the trigger under test.
func _check_home_built_flag() -> void:
	var progression: RefCounted = _game.get("progression")
	var required: Dictionary = HOME_PROGRESS.required_pieces()
	if required.is_empty():
		_fail("data/config/progression.json's home.required_pieces is empty -- nothing to test")
		return
	var i := 0
	for id: String in required.keys():
		for _c in int(required[id]):
			_game.call("register_building", id, Vector3(i * 3.0, 0.0, 0.0))
			i += 1
	if bool(progression.call("has", "home_built")):
		_fail("home_built was set by register_building alone, before the placer ever ran")
	_placer.call("restore_from_game", _game)
	if not bool(progression.call("has", "home_built")):
		_fail("build_placer.gd::restore_from_game did not set home_built once every required piece was standing")
	# One short of any single required piece must NOT read as a home --
	# proves this is a real threshold, not a flag that latches on any build.
	progression.call("set_flag", "home_built", false)
	_game.set("placed_buildings", [])
	var first_id := str(required.keys()[0])
	for id: String in required.keys():
		var copies := int(required[id])
		if id == first_id:
			copies -= 1
		for _c in copies:
			_game.call("register_building", id, Vector3(i * 3.0, 0.0, 0.0))
			i += 1
	_placer.call("restore_from_game", _game)
	if bool(progression.call("has", "home_built")):
		_fail("home_built fired one '%s' short of the required count" % first_id)


func _check_player_slept_flag() -> void:
	var progression: RefCounted = _game.get("progression")
	if bool(progression.call("has", "player_slept_at_home")):
		_fail("player_slept_at_home was already set before resting")
	var bed := PLAYER_BED.new()
	bed.name = "TestBedroll"
	_world.add_child(bed)
	bed.call("build_real")
	bed.call("_on_rest")
	# FADE_SECONDS is 1.2s and `_pass_the_night` fires at the midpoint of the
	# real tween; wait past that without waiting for the whole fade-back-in.
	await create_timer(1.0).timeout
	if not bool(progression.call("has", "player_slept_at_home")):
		_fail("player_bed.gd's rest interaction did not set player_slept_at_home")


## Drives the real gathering completion path, `harvest_node.gd::_on_gathered`
## (via its public `gather()`), through the exact tool-gated pickup a player
## uses -- not a direct inventory.add.
func _check_materials_gathered_flag() -> void:
	var progression: RefCounted = _game.get("progression")
	var inventory: RefCounted = _game.get("inventory")
	var items: RefCounted = _game.get("items")
	progression.call("set_flag", "home_materials_gathered", false)
	var threshold: Dictionary = HOME_PROGRESS.materials_threshold(items)
	if threshold.is_empty():
		_fail("home.required_pieces resolved to no material cost at all -- nothing to test")
		return
	# Every required id sits exactly ONE short of the threshold except wood,
	# which starts at zero and gets pushed over by the one real gather below.
	for id: String in threshold.keys():
		var have := int(inventory.call("count", id))
		if have > 0:
			inventory.call("remove", id, have)
		var target: int = int(threshold[id]) if id != "wood" else int(threshold[id]) - 1
		if target > 0:
			inventory.call("add", id, target)
	if bool(progression.call("has", "home_materials_gathered")):
		_fail("home_materials_gathered was set while wood sat one short of the threshold")

	_game.set("equipped_tool", "axe")
	inventory.call("add", "axe", 1)
	var node := HARVEST_NODE.new()
	_world.add_child(node)
	node.call("setup", {"item": "wood", "amount": 5, "label": "Gather"})
	node.call("gather")

	if not bool(progression.call("has", "home_materials_gathered")):
		_fail("harvest_node.gd's gather completion did not set home_materials_gathered once wood crossed the threshold")


func _wipe_test_dir() -> void:
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir():
			dir.remove(name)
		name = dir.get_next()
	dir.list_dir_end()


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _finish() -> void:
	_wipe_test_dir()
	if _world != null and is_instance_valid(_world):
		_world.queue_free()
	if _failures.is_empty():
		print("GATEB FLAGS SMOKE: PASS")
		quit(0)
	else:
		print("GATEB FLAGS SMOKE: FAIL (%d)" % _failures.size())
		for failure in _failures:
			print("  - %s" % failure)
		quit(1)
