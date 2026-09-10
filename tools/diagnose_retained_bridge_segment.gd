extends SceneTree

## Diagnostic-only replay of the earned South Bridge segment from a copied
## retained save. Before running, copy a slot with tournament_won and an
## undefeated bridge guardian to user://diagnostic_bridge_copy/slot_0.json.
## This changes no production state and does not grant progress.

const SAVE := preload("res://scripts/save/save_game.gd")

class TraceBridge:
	extends "res://tests/helpers/meadows_earned_bridge_segment.gd"

	var _observer_running := false
	var _observer_done := true
	var _gate_press_count := 0

	# The copied autosave was written at the South Bridge after the original
	# fresh run had already traversed the complete village-to-bridge approach.
	# Skip only that completed road prelude. Do not move the player: prove the
	# retained pose is still on the village bank and near the authored crossing,
	# then run the base gate press, guardian walk/dialogue, recovery, combat,
	# reward, unlock and physical crossing unchanged.
	func _travel_and_cross(_route: Array[Vector2], crossing: Dictionary) -> bool:
		var carve: Dictionary = crossing.get("carve", {}) as Dictionary
		var raw_centre: Array = carve.get("centre", []) as Array
		if raw_centre.size() != 2:
			return _fail("BRIDGE TRACE could not resolve the authored crossing centre")
		var centre := Vector2(float(raw_centre[0]), float(raw_centre[1]))
		var here := Vector2(_player.global_position.x, _player.global_position.z)
		if here.distance_to(centre) > 30.0 or _depth() >= 0.0:
			return _fail("BRIDGE TRACE copied pose is not near the village bank: %s" % here)
		print("BRIDGE TRACE skips completed approach only; retained village-bank pose=", here,
			" crossing=", centre, " distance=", here.distance_to(centre), " depth=", _depth())
		return await super._travel_and_cross([], crossing)

	func _press_gate(prompt: Node3D) -> bool:
		_gate_press_count += 1
		var provider: Object = _arbiter.call("winning_provider")
		var direct_offer: Dictionary = prompt.call("interaction_offer", _player.global_position)
		var row := {
			"press": _gate_press_count,
			"phase": "locked_challenge" if _gate_press_count == 1 else "post_victory_unlock",
			"player": str(_player.global_position),
			"gate_prompt": str(prompt.global_position),
			"gate_distance": _player.global_position.distance_to(prompt.global_position),
			"gate_radius": float(prompt.get("radius")),
			"gate_enabled": bool(prompt.get("enabled")),
			"gate_actionable": bool(prompt.get("actionable")),
			"gate_direct_offer": direct_offer,
			"gate_los": prompt.call("_has_line_of_sight", _player.global_position) \
				if prompt.has_method("_has_line_of_sight") else "not_callable",
			"bridge_open": bool(_bridge.call("is_open")),
			"arbiter_enabled": bool(_arbiter.call("enabled")),
			"winner_provider": _node_identity(provider),
			"winner_offer": _arbiter.call("winner"),
		}
		print("BRIDGE GATE OFFER BEFORE ", JSON.stringify(row))
		if provider != prompt or not bool((_arbiter.call("winner") as Dictionary).get("actionable", false)):
			_print_nearby_providers()
		return await super._press_gate(prompt)

	func _print_nearby_providers() -> void:
		var providers: Dictionary = _arbiter.get("_provider_set") as Dictionary
		var nearby: Array[Dictionary] = []
		for candidate: Variant in providers:
			var node := candidate as Node3D
			if node == null or not is_instance_valid(node):
				continue
			var distance := _player.global_position.distance_to(node.global_position)
			if distance > 8.0:
				continue
			var offer: Dictionary = node.call("interaction_offer", _player.global_position)
			nearby.append({"provider": _node_identity(node), "position": str(node.global_position),
				"distance": distance, "offer": offer})
		print("BRIDGE GATE NEARBY PROVIDERS ", JSON.stringify(nearby))

	func _node_identity(value: Object) -> String:
		var node := value as Node
		if node == null or not is_instance_valid(node):
			return "<none>"
		return "%s (%s#%s)" % [node.get_path(), node.name, node.get_instance_id()]

	func run(tree: SceneTree, world: Node3D, game: Node) -> Dictionary:
		_observer_running = true
		_observer_done = false
		_observe.call_deferred()
		var out: Dictionary = await super.run(tree, world, game)
		_observer_running = false
		while not _observer_done:
			await tree.physics_frame
		print("BRIDGE TRACE RETURN counters=", {"hits": _guardian_hits,
			"wins": _guardian_wins, "active": _guardian_active},
			" director=", _director_row(), " result=", JSON.stringify(out))
		return out

	func _observe() -> void:
		var live_tree := Engine.get_main_loop() as SceneTree
		while _observer_running and (_tree == null or _director == null or _combat == null):
			await live_tree.physics_frame
		if not _observer_running:
			_observer_done = true
			return
		var last := ""
		while _observer_running and is_instance_valid(_world):
			for _frame in 60:
				await _tree.physics_frame
				if not _observer_running:
					break
			if not _observer_running:
				break
			var row := {"frame": Engine.get_physics_frames(),
				"guardian_active": _guardian_active, "hits": _guardian_hits,
				"wins": _guardian_wins, "director": _director_row(),
				"combat": _combat_row(), "defeated": _has("defeated_south_bridge_grunt")}
			var encoded := JSON.stringify(row)
			if encoded != last:
				print("BRIDGE TRACE STATE ", encoded)
				last = encoded
		_observer_done = true

	func _director_row() -> Dictionary:
		if _director == null:
			return {}
		return {"active": bool(_director.call("trainer_battle_active")),
			"id": str(_director.call("trainer_battle_id")),
			"left": int(_director.call("trainer_creatures_left")),
			"usable_blocker": str(_director.call("usable_ally_blocker"))}

	func _combat_row() -> Dictionary:
		if _combat == null:
			return {}
		var director_ally: RefCounted = _director.call("ally_instance") as RefCounted \
			if _director != null else null
		var active_ally: RefCounted = _combat.call("active_creature") as RefCounted
		var enemy: RefCounted = _combat.call("enemy") as RefCounted
		return {"fighting": bool(_combat.call("is_fighting")),
			"outcome": str(_combat.call("outcome")),
			"action": str(_combat.get("_action")),
			"director_ally": _creature_row(director_ally),
			"active_ally": _creature_row(active_ally),
			"same_ally": director_ally == active_ally,
			"enemy_hp": float(enemy.get("hp")) if enemy != null else -1.0}

	func _creature_row(creature: RefCounted) -> Dictionary:
		if creature == null or not is_instance_valid(creature):
			return {}
		return {"instance_id": creature.get_instance_id(),
			"species_id": str(creature.get("species_id")),
			"level": int(creature.get("level")),
			"hp": float(creature.get("hp")),
			"max_hp": float(creature.get("max_hp")),
			"fainted": bool(creature.get("fainted"))}


func _init() -> void:
	_run.call_deferred()


var _bridge_trace: TraceBridge


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		push_error("BRIDGE TRACE missing Game")
		quit(2)
		return
	var source_slot := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--source-slot="):
			source_slot = arg.trim_prefix("--source-slot=")
	if source_slot.is_empty() or not FileAccess.file_exists(source_slot):
		push_error("BRIDGE TRACE requires an existing --source-slot=<absolute slot_0.json>")
		quit(2)
		return
	var copied_dir := "user://diagnostic_bridge_copy"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(copied_dir))
	var bytes := FileAccess.get_file_as_bytes(source_slot)
	var copy := FileAccess.open(copied_dir + "/slot_0.json", FileAccess.WRITE)
	if copy == null:
		push_error("BRIDGE TRACE could not create isolated copied slot")
		quit(2)
		return
	copy.store_buffer(bytes)
	copy.close()
	game.set("save_system", SAVE.new(copied_dir))
	if not bool(game.call("load_game", 0)):
		push_error("BRIDGE TRACE could not load copied slot 0")
		quit(2)
		return
	print("BRIDGE TRACE DIAGNOSTIC ONLY copied save; no continuity claim")
	change_scene_to_file("res://scenes/world/meadows_playground.tscn")
	await scene_changed
	for _frame in 120:
		await physics_frame
	var world := current_scene as Node3D
	_bridge_trace = TraceBridge.new()
	var result: Dictionary = await _bridge_trace.run(self, world, game)
	_bridge_trace = null
	quit(0 if bool(result.get("passed", false)) else 1)
