extends "res://tests/smoke_four_biome_continuous.gd"

## Diagnostic-only wrapper around the canonical fresh continuous smoke.
## It changes no input, timing, assertions, state or fixture. ThrowAim nodes are
## discovered through SceneTree.node_added before `_ready()`, then their public
## lifecycle/result signals and frame-by-frame state transitions are recorded.
##
## godot --headless --path . --script tools/probe_continuous_aim_lifecycle.gd \
##   -- --through-rest

var _watched: Dictionary = {}


func _run() -> void:
	if not node_added.is_connected(_on_node_added):
		node_added.connect(_on_node_added)
	if not physics_frame.is_connected(_sample_throw_states):
		physics_frame.connect(_sample_throw_states)
	# Normally no ThrowAim exists before the opening world mounts, but retain
	# any already-added node if boot ordering changes.
	for node: Node in root.find_children("*", "Node", true, false):
		_on_node_added(node)
	await super._run()


func _on_node_added(node: Node) -> void:
	if node == null or _watched.has(node.get_instance_id()):
		return
	var script := node.get_script() as Script
	if script == null or script.resource_path != "res://scripts/combat/throw_aim.gd":
		return
	var id := node.get_instance_id()
	_watched[id] = {
		"node": node,
		"last_state": int(node.get("state")),
		"last_guard": float(node.get("_guard")),
		"last_windup": float(node.get("_windup")),
		"last_report": {},
	}
	node.connect(&"aim_entered", _on_aim_entered.bind(node))
	node.connect(&"aim_exited", _on_aim_exited.bind(node))
	node.connect(&"throw_refused", _on_throw_refused.bind(node))
	node.connect(&"orb_struck", _on_orb_struck.bind(node))
	node.connect(&"orb_missed", _on_orb_missed.bind(node))
	_print_event("node_added_pre_ready", node, {"inside_tree": node.is_inside_tree(),
		"ready": node.is_node_ready()})


func _sample_throw_states() -> void:
	for id: int in _watched.keys():
		var entry: Dictionary = _watched[id]
		var node: Node = entry.get("node") as Node
		if not is_instance_valid(node):
			_watched.erase(id)
			continue
		var current := int(node.get("state"))
		var guard := float(node.get("_guard"))
		var windup := float(node.get("_windup"))
		var report: Dictionary = node.call("aim_report") if node.has_method("aim_report") else {}
		if current != int(entry.last_state):
			_print_event("state_transition", node, {"from": int(entry.last_state), "to": current,
				"previous_report": entry.last_report, "guard_before_sample": guard,
				"windup_before_sample": windup})
		entry["last_state"] = current
		entry["last_guard"] = guard
		entry["last_windup"] = windup
		entry["last_report"] = report.duplicate(true)
		_watched[id] = entry


func _on_aim_entered(node: Node) -> void:
	_print_event("aim_entered", node)


func _on_aim_exited(node: Node) -> void:
	var entry: Dictionary = _watched.get(node.get_instance_id(), {}) as Dictionary
	_print_event("aim_exited", node, {"last_sampled_state": int(entry.get("last_state", -1)),
		"last_sampled_report": entry.get("last_report", {}), "signal_stack": get_stack()})


func _on_throw_refused(reason: String, node: Node) -> void:
	_print_event("throw_refused", node, {"reason": reason, "signal_stack": get_stack()})


func _on_orb_struck(target: Node3D, offset: float, node: Node) -> void:
	_print_event("orb_struck", node, {"target": str(target.get_path()) if is_instance_valid(target) else "<freed>",
		"offset": offset})


func _on_orb_missed(message: String, node: Node) -> void:
	_print_event("orb_missed", node, {"message": message})


func _print_event(kind: String, node: Node, extra: Dictionary = {}) -> void:
	var target: Node = node.get("_target") as Node
	var manager := node.get_parent()
	var payload := {
		"kind": kind,
		"physics_frame": Engine.get_physics_frames(),
		"process_frame": Engine.get_process_frames(),
		"ticks_msec": Time.get_ticks_msec(),
		"throw_path": str(node.get_path()) if node.is_inside_tree() else "<not-in-tree>",
		"manager_path": str(manager.get_path()) if manager != null and manager.is_inside_tree() else "<none>",
		"state": int(node.get("state")),
		"cooldown": float(node.get("_cooldown")),
		"guard": float(node.get("_guard")),
		"windup": float(node.get("_windup")),
		"target": str(target.get_path()) if is_instance_valid(target) else "<none>",
		"orb_live": is_instance_valid(node.get("_orb") as Node),
		"aim_report": node.call("aim_report") if node.has_method("aim_report") else {},
		"inputs": _input_snapshot(),
	}
	payload.merge(extra, true)
	print("AIM LIFECYCLE " + JSON.stringify(payload))


func _input_snapshot() -> Dictionary:
	var result := {}
	for action: StringName in [&"combat_throw", &"interact", &"combat_quick", &"combat_run",
			&"menu_cancel", &"look_left", &"look_right", &"look_up", &"look_down",
			&"move_left", &"move_right", &"move_forward", &"move_back"]:
		result[str(action)] = {"pressed": Input.is_action_pressed(action),
			"just_pressed": Input.is_action_just_pressed(action),
			"just_released": Input.is_action_just_released(action),
			"strength": Input.get_action_strength(action)}
	return result
