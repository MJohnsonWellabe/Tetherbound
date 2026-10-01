extends "res://tests/helpers/water_earned_opening_segment.gd"

## Portal arrival adapter; retains the original live lesson, contact and five-owned checks.
func run(tree: SceneTree, actual_world: Node3D, actual_game: Node) -> Dictionary:
	_tree = tree
	world = actual_world
	game = actual_game
	if tree == null or world == null or game == null or tree.current_scene != world \
			or str(game.get("current_realm")) != "water" or not str(game.get("pending_realm_entry")).is_empty() \
			or not world.has_method("shell_build_complete") or not world.shell_build_complete():
		_fail("Earned Water opening requires the retained ready natural Water arrival")
		return result()
	var portal: Dictionary = game.call("portal_view", "tidewake")
	if portal.get("character_open") != true or not game.world.flags.has("legendary_freed") or game.get("pending_catch") != null:
		_fail("F49 Tidewake requires the actual personal Tidewake portal unlock and earned Meadows finale")
		return result()
	player = world.get_node_or_null("Player")
	camera = world.get_node_or_null("CameraRig")
	_arbiter = world.get_node_or_null("InteractionArbiter")
	initial_party_ids = _party_ids()
	if player == null or camera == null or _arbiter == null or not retained_five(initial_party_ids, initial_party_ids) \
			or INPUT_OWNER.current(tree) != null:
		_fail("Earned Water opening requires live controls and five distinct retained creatures")
		return result()
	navigator = NAV.new(tree, player, camera, _stick)
	var previous_scale := Engine.time_scale
	var previous_hz := Engine.physics_ticks_per_second
	await tree.process_frame
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	await tree.process_frame
	_deadline_ms = Time.get_ticks_msec() + LESSON_MS
	await _run_live()
	_stick(0, 0)
	if is_instance_valid(_arbiter) and _arbiter.activated.is_connected(_on_activated):
		_arbiter.activated.disconnect(_on_activated)
	await tree.process_frame
	Engine.time_scale = previous_scale
	Engine.physics_ticks_per_second = previous_hz
	return result()

