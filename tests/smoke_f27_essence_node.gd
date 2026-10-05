extends "res://tests/smoke_f32_material_sites.gd"

## F27#1 actual-path witness for the attuned essence node source: the shipped
## Meadows essence node is mounted by the production resource adapter, reached
## by the physical controller driver, gathered with `interact`, and settled
## through the host stock transaction to the owner's disk with an accepted
## journal and receipt. Reuses smoke_f32_material_sites' isolated saver,
## driver and disk helpers; unlike that smoke, no registry fixture is needed
## because essence nodes are shipped canonical renewable sites.
##
##   godot --headless --path . --script tests/smoke_f27_essence_node.gd [-- --site=essence_meadows_ground_01]
##
## Disclosed fixtures (as the F32 smoke): one owned Terrapup, opening free
## play, a 6m start beside the node. Not an earned route or two-peer proof.
const NODES := preload("res://scripts/world/essence_node_catalog.gd")


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		_args[parts[0]] = parts[1] if parts.size() == 2 else true
	_realm = "meadows"
	var id := str(_args.get("site", "essence_meadows_ground_01"))
	_output = "user://f27_essence_node_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	DirAccess.make_dir_recursive_absolute(_output)
	create_timer(540.0).timeout.connect(func() -> void:
		if not _finished:
			_check(false, "native watchdog expired")
			_finish())
	_game = root.get_node_or_null(^"Game")
	_saver = SAVE.new(_output.path_join("working"))
	_game.set("save_system", _saver)
	_game.call("reset_for_new_game")
	_game.set("current_realm", _realm)
	_game.get("local").set("character_id", "f27-node-owner")
	_game.get("world").set("world_id", "f27-node-world")
	_game.get("party").call("add", preload("res://scripts/creatures/creature_species.gd").spawn("terrapup"))
	_game.get("progression").call("set_flag", "opening:beat:free_play")
	var spec := NODES.by_id(_realm, id, NODES.read())
	if not _check(not spec.is_empty(), id + " is a shipped essence node"):
		_finish(); return
	if not _check(change_scene_to_file(SCENES[_realm]) == OK, "request actual baked realm scene"):
		_finish(); return
	for frame in 2400:
		await process_frame
		if current_scene != null and current_scene.has_method("shell_build_complete") \
			and current_scene.call("shell_build_complete") == true:
			_world = current_scene as Node3D
			break
	if not _check(_world != null, "actual realm procedural build completed"):
		_finish(); return
	_player = _game.call("find_player") as CharacterBody3D
	_resources = _game.get("session").get_node_or_null(^"FoundationComposition/Resources")
	if not _check(_player != null and _resources != null, "production player and resource adapter mounted"):
		_finish(); return
	_resources.get_node(^"SourceService").connect("settled", _on_settled)
	_driver = DRIVER.new()
	_driver.set("_tree", self)
	_driver.set("_world", _world)
	_driver.set("_game", _game)
	_driver.set("_player", _player)
	var rig := _world.get_node_or_null(^"CameraRig") as Node3D
	_driver.set("_rig", rig)
	_driver.set("_arbiter", get_first_node_in_group(&"interaction_arbiter"))
	if not _check(rig != null and _driver.get("_arbiter") != null and _driver.call("_resolve_move_bindings") == true,
		"physical controller driver resolves production camera and arbiter"):
		_finish(); return
	_driver.set("_nav", NAV.new(self, _player, rig, Callable(_driver, "_send_stick")))
	await _frames(30)
	await _essence_site(id, spec)
	_finish()


func _essence_site(id: String, spec: Dictionary) -> void:
	var result := {"id": id, "controller_approach": false, "accepted_disk_gather": false}
	_report.sites.append(result)
	_resources.get("_mount_retry").erase(_realm)
	_resources.call("_mount_realm", _realm, _player)
	var node: Node3D = _resources.call("_source", _realm, id)
	if not _check(node != null, id + " production world mount placed the essence node"): return
	var prompt := node.get_node_or_null(^"Interactable") as Node3D
	if not _check(prompt != null, id + " actual gather prompt exists"): return
	var start := Vector2(node.global_position.x, node.global_position.z) + Vector2(0, 6)
	var ground := float(_world.call("ground_height_at", start.x, start.y))
	_player.set_physics_process(false)
	_player.global_position = Vector3(start.x, ground + 0.2, start.y)
	_player.velocity = Vector3.ZERO
	var rig := _world.get_node_or_null(^"CameraRig") as Node3D
	if rig != null:
		rig.global_position = _player.global_position
		rig.reset_physics_interpolation()
	for frame in 8:
		await process_frame
		await physics_frame
	_player.set_physics_process(true)
	_player.reset_physics_interpolation()
	await _frames(6)
	for frame in 180:
		await physics_frame
		if _player.is_on_floor(): break
	var before: Vector3 = _player.global_position
	var arrived: bool = await _driver.call("_walk_to", node.global_position, 1.6, 600)
	result.walked_metres = Vector2(before.x, before.z).distance_to(Vector2(_player.global_position.x, _player.global_position.z))
	result.controller_approach = arrived and result.walked_metres >= 3.0
	if not _check(result.controller_approach, id + " controller approach walked %.1fm" % result.walked_metres): return
	if not _check(await _driver.call("_prompt_holds_the_line", prompt.get_instance_id()), id + " the essence prompt wins ordinary interaction"): return
	_saver.call("finish_fallback")
	if not _check(_saver.call("save_world_prepared", _game, str(_game.get("world").world_id)) == true \
		and _saver.call("save_character_prepared", _game, str(_game.get("local").character_id)) == true,
		id + " pre-gather owner and world saved to isolated disk"): return
	var before_disk := _disk("before_" + id)
	await _driver.call("_tap_action", &"interact")
	for frame in 600:
		if _settled.has(id): break
		await physics_frame
	result.settlement = _settled.get(id, {})
	if not _check(ADAPTER.saved_decision(result.settlement.get("verdict", {})), id + " gather reaches real owner save and ACK"): return
	var after_disk := _disk("after_" + id)
	var row: Dictionary = {}
	for value: Variant in after_disk.world.get("reward_deliveries", {}).values():
		if value is Dictionary and value.get("action") == "resource" and value.get("intent", {}).get("request", {}).get("site_id") == id: row = value
	var gained := {}
	for item: String in spec.outputs:
		gained[item] = _count(after_disk.character, item) - _count(before_disk.character, item)
	result.gained = gained
	var exact: bool = row.get("status") == "accepted" \
		and after_disk.character.get("redesign_character", {}).get("transaction_receipts", []).has(row.get("receipt", ""))
	for item: String in spec.outputs: exact = exact and int(gained[item]) == int(spec.outputs[item])
	result.accepted_disk_gather = exact
	_check(exact, id + " disk gained exactly %s with an accepted journal and receipt (gained %s)" % [str(spec.outputs), str(gained)])
	if exact: print("F27_ESSENCE_NODE: PASS %s paid %s on the production gather path" % [id, str(gained)])
