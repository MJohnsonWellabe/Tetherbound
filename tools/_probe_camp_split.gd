extends SceneTree

## OWNER-0902-CAMP-SPLIT verification probe. One-shot, not shipped as a test:
## arms tent/campfire/bedroll/creature_bed through the real catalogue+placer
## path in the live Meadows world, confirms each pieces's registration in
## GameState.placed_buildings, and exercises the campfire's Craft prompt and
## the bedroll's Rest prompt end to end.
##
##   godot --headless --path . --script tools/_probe_camp_split.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 200

var _failures: Array[String] = []
var _world: Node
var _game: Node
var _player: CharacterBody3D
var _placer: Node


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
	_game = root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_placer = get_first_node_in_group("build_placer")
	if _game == null or _player == null or _placer == null:
		_fail("Meadows did not stand up Game, Player, and BuildPlacer")
		_report()
		return

	var director := _world.find_child("SequenceDirector", true, false)
	if director != null and director.has_method("_set_beat"):
		director.call("_set_beat", "free_play")

	_game.set("free_build", false)
	var inventory: RefCounted = _game.get("inventory")
	inventory.call("add", "wood", 30)
	inventory.call("add", "stone", 30)
	inventory.call("add", "fiber", 30)

	await _teleport_to(Vector3(90.0, 0.0, 90.0))

	var progression: RefCounted = _game.get("progression")
	if bool(progression.call("has", "home_built")):
		_fail("home_built already set before anything was placed")

	var tent := await _place("tent", Vector3(90.0, 0.0, 90.0))
	var campfire := await _place("campfire", Vector3(92.0, 0.0, 90.0))
	var bedroll := await _place("bedroll", Vector3(94.0, 0.0, 90.0))
	if tent == null or campfire == null or bedroll == null:
		_report()
		return
	print("tent/campfire/bedroll all placed independently through the real menu+placer")

	if bool(progression.call("has", "home_built")):
		_fail("home_built fired with the campsite alone; a Creature Bed is also required")

	var bed := await _place("creature_bed", Vector3(96.0, 0.0, 90.0))
	if bed == null:
		_report()
		return
	if not bool(progression.call("has", "home_built")):
		_fail("home_built did not fire once tent+campfire+bedroll+creature_bed were all standing")
	else:
		print("home_built fired once all four required pieces were standing")

	_check_placed_buildings_ids()
	await _check_campfire_craft(campfire)
	await _check_bedroll_rest(bedroll)

	_report()


func _check_placed_buildings_ids() -> void:
	var ids: Array = []
	for entry: Variant in (_game.get("placed_buildings") as Array):
		if entry is Dictionary:
			ids.append(str((entry as Dictionary).get("id", "")))
	for wanted in ["tent", "campfire", "bedroll", "creature_bed"]:
		if not ids.has(wanted):
			_fail("GameState.placed_buildings has no '%s' entry after a real placement (%s)" % [wanted, str(ids)])
	if not _failures.is_empty():
		return
	print("GameState.placed_buildings carries all four real ids: %s" % str(ids))


func _place(id: String, at: Vector3) -> Node3D:
	await _teleport_to(at)
	_game.set("pending_build", id)
	for i in 20:
		await physics_frame
	if not bool(_placer.get("_ghost_ok")):
		_fail("'%s' ghost is red at %s (reason: %s)" % [id, at, str(_placer.get("_ghost_reason"))])
		return null
	var before: Array[Node] = get_nodes_in_group("placed_building")
	Input.action_press("build_place")
	await physics_frame
	await physics_frame
	Input.action_release("build_place")
	for i in 15:
		await physics_frame
	_game.set("pending_build", "")
	for i in 5:
		await physics_frame
	for node: Node in get_nodes_in_group("placed_building"):
		if before.has(node):
			continue
		if str(node.get_meta("building_id", "")) == id:
			print("placed '%s' through the real catalogue+placer" % id)
			return node as Node3D
	_fail("arming and pressing build_place for '%s' planted nothing" % id)
	return null


func _check_campfire_craft(campfire: Node3D) -> void:
	var prompt := campfire.get_node_or_null(^"CraftInteractable") as Node3D
	if prompt == null:
		_fail("placed campfire has no Craft prompt")
		return
	# Fire the same signal a real interact press does.
	prompt.emit_signal("activated")
	for i in 10:
		await process_frame
	var panel: Node = null
	for node: Node in root.get_children():
		var script := node.get_script() as Script
		if script != null and script.resource_path.ends_with("craft_panel.gd") \
				and node.has_method("is_open") and bool(node.call("is_open")):
			panel = node
			break
	if panel == null:
		_fail("the campfire's Craft prompt did not open craft_panel.gd")
		return
	print("campfire Craft prompt opened the real craft panel")
	panel.call("close")


func _check_bedroll_rest(bedroll: Node3D) -> void:
	var prompt := bedroll.get_node_or_null(^"Interactable") as Node3D
	if prompt == null:
		_fail("placed bedroll has no Rest prompt")
		return
	var day_before := int(_game.get("day"))
	var vitals: RefCounted = _player.get("vitals")
	if vitals != null:
		vitals.set("health", 20.0)
	prompt.emit_signal("activated")
	var waited := 0.0
	while waited < 3.0:
		await process_frame
		waited += 1.0 / 60.0
	if int(_game.get("day")) != day_before + 1:
		_fail("the bedroll's Rest prompt did not advance the day (%d -> %d)" % [day_before, int(_game.get("day"))])
		return
	if vitals != null and float(vitals.get("health")) < float(vitals.get("max_health")):
		_fail("the bedroll's Rest prompt did not heal the trainer")
		return
	print("bedroll Rest prompt advanced the day and healed the trainer")


func _teleport_to(at: Vector3) -> void:
	var y := float(_world.call("ground_height_at", at.x, at.z)) if _world.has_method("ground_height_at") else 0.0
	_player.global_position = Vector3(at.x, y + 0.2, at.z)
	_player.velocity = Vector3.ZERO
	for i in 12:
		await physics_frame


func _fail(message: String) -> void:
	_failures.append(message)
	print("FAIL: %s" % message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("CAMP SPLIT PROBE: PASS")
		quit(0)
		return
	print("CAMP SPLIT PROBE: FAIL (%d)" % _failures.size())
	for failure in _failures:
		print("  - %s" % failure)
	quit(1)
