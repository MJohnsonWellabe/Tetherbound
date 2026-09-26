extends SceneTree

## B2 (#229): every authored Band 2 rootstone can be reached and prised out by
## ordinary controller movement. Cloudreach's earned chain stalled ~4 m short
## of order 16, which stood inside solid ground behind foundation_0's wall.
##
##   godot --headless --path . --script tests/smoke_quarry_rootstones.gd
##
## Staged start, real route: a fresh game with a seeded five and a pickaxe on
## the hotbar, the player placed on the Band 2 road at its quarry join. From
## there the earned Warrens segment's own quarry loop runs unchanged: stick
## input to each deposit in authored order, the real pickaxe equip, the real
## interact/swing, and the configured yield. Wild fights on the way are piloted
## the same way the earned chain pilots them. Exit 0 only if every deposit is
## harvested.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SEGMENT := preload("res://tests/helpers/meadows_earned_warrens_segment.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const SAVE_DIR := "user://smoke_quarry_rootstones/"
const PARTY := ["terrapup", "trailpup", "bramblebun", "burrowback", "meadowhart"]
const SETTLE_FRAMES := 240


class QuarryOnly extends "res://tests/helpers/meadows_earned_warrens_segment.gd":
	## Only the quarry leg of `_travel`: road to the quarry join, then every
	## rootstone stop through the same QuarryInput the earned chain uses.
	func run_quarry(tree: SceneTree, world: Node3D, game: Node) -> Dictionary:
		_tree = tree
		_world = world
		_game = game
		_player = world.get_node_or_null("Player") as CharacterBody3D
		_rig = world.get_node_or_null("CameraRig") as Node3D
		_director = world.get_node_or_null("EncounterDirector")
		_combat = world.get_node_or_null("CombatManager")
		_arbiter = tree.get_first_node_in_group("interaction_arbiter")
		if _player == null or _rig == null or _director == null or _combat == null or _arbiter == null:
			_fail("quarry smoke: live traversal or combat dependencies are missing")
			return result()
		_input = INPUTS.new()
		_input._tree = tree
		_nav = NAV.new(tree, _player, _rig, _stick)
		_combat.connect("entered", _on_entered)
		_combat.connect("hit_landed", _on_hit)
		_combat.connect("exited", _on_exit)
		_completed = await _quarry()
		_stick(0.0, 0.0)
		return result()

	func _quarry() -> bool:
		var stops := rootstone_stops(_read(HARVEST))
		var road := trail_points(_read(TERRAIN), "bands", "band2_stone_and_root")
		if stops.is_empty() or road.is_empty():
			return _fail("quarry smoke: no authored rootstone or Band 2 trail")
		var centre := Vector2.ZERO
		for row: Dictionary in stops:
			centre += _v2(row.at)
		centre /= float(stops.size())
		var join := nearest_index(road, centre)
		var start := road[maxi(join - 1, 0)]
		_player.global_position = Vector3(start.x, float(_world.call("ground_height_at", start.x, start.y)) + 1.0, start.y)
		_player.velocity = Vector3.ZERO
		for _i in 30:
			await _tree.physics_frame
		if not await _walk_ground(road[join]):
			return false
		var gather := QuarryInput.new()
		gather._tree = _tree
		gather._world = _world
		gather._game = _game
		gather._player = _player
		gather._rig = _rig
		gather._arbiter = _arbiter
		gather.walk = _walk
		if not gather._resolve_move_bindings():
			return _fail("quarry smoke: no controller movement binding")
		gather._nav = NAV.new(_tree, _player, _rig, gather._send_stick)
		for row: Dictionary in stops:
			var at := _v2(row.at)
			if not await _walk_ground(at, 2.2):
				return false
			var node := gather._authored_node_at(at, "rootstone")
			if node == null:
				return _fail("quarry smoke: no unspent authored rootstone at " + str(at))
			var amount := int(node.call("resource_amount"))
			var expected := int((_game.get("items") as RefCounted).call("harvest_yield", "rootstone", amount, true, false))
			var before := _count("rootstone")
			if not await gather._harvest_node(node, "rootstone", true):
				return _fail("quarry smoke: pickaxe/rootstone input failed at %s: %s" % [at, gather.failures])
			if expected <= 0 or _count("rootstone") - before != expected:
				return _fail("quarry smoke: order %d at %s yielded %d, expected %d" % [
					int(row.order), at, _count("rootstone") - before, expected])
			_receipt("quarry_rootstone", {"order": int(row.order), "at": at,
				"player": _player.global_position, "yield": expected})
		return true


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var game := root.get_node_or_null(^"/root/Game")
	if game == null:
		_finish(["no Game autoload"])
		return
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	game.set("save_system", SAVE_GAME.new(SAVE_DIR))
	game.call("reset_for_new_game")
	var party: RefCounted = game.get("party")
	party.call("clear")
	for species_id: String in PARTY:
		var member: RefCounted = SPECIES.spawn(species_id)
		if member == null or not bool(party.call("add", member)):
			_finish(["could not seed party member " + species_id])
			return
		member.call("set_level", 13, JSON.parse_string(FileAccess.get_file_as_string("res://data/config/progression.json")))
		member.set("hp", member.get("max_hp"))
	var inventory: RefCounted = game.get("inventory")
	if int(inventory.call("count", "pickaxe")) <= 0:
		inventory.call("add", "pickaxe", 1)
	if int(game.call("hotbar_slot_of", "pickaxe")) < 0:
		game.call("autofill_hotbar")
	if int(game.call("hotbar_slot_of", "pickaxe")) < 0:
		game.call("assign_hotbar", 0, "pickaxe")
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for _i in SETTLE_FRAMES:
		await physics_frame
	var director := world.get_node_or_null(^"EncounterDirector")
	if director != null:
		director.call("summon_active_creature")
	var segment := QuarryOnly.new()
	var result: Dictionary = await segment.run_quarry(self, world, game)
	_finish(result.failures if not bool(result.passed) else [])


func _finish(failures: Array) -> void:
	if failures.is_empty():
		print("quarry rootstones smoke test passed")
		quit(0)
		return
	for line in failures:
		print("  FAIL: %s" % line)
	print("quarry rootstones smoke test FAILED")
	quit(1)
