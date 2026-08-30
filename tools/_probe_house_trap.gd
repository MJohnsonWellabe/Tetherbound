extends SceneTree

## OP-0830-4 reproduction: what is the player TOLD once the opening shuts them
## in with Grandpa?
##
##   godot --headless --path . --script tools/_probe_house_trap.gd
##
## The owner's report is that after the first conversation you are trapped in
## the house with nothing telling you that talking to Grandpa again is what
## releases you. `tests/smoke_opening.gd` passes through this beat by looking
## Grandpa up in the scene tree by name and walking to him -- knowledge no
## player has. So this asks the player's own questions, at each beat the door
## is shut:
##
##   * what does the tracked objective line say?
##   * is Grandpa's prompt actually being OFFERED from where the player stands?
##   * what happens when they walk at the door?
##
## Diagnostic only. Prints; never asserts.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300

var _world: Node = null
var _game: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _director: Node = null
var _arbiter: Node = null
var _dialogue: CanvasLayer = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_game = root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_arbiter = _world.get_tree().get_first_node_in_group("interaction_arbiter")
	for child: Node in _world.get_children():
		var script: Script = child.get_script()
		if script == null:
			continue
		var path := str(script.resource_path)
		if path.ends_with("sequence_director.gd"):
			_director = child
		elif path.ends_with("dialogue_panel.gd"):
			_dialogue = child as CanvasLayer
	if _dialogue == null:
		_dialogue = _world.get_tree().get_first_node_in_group("dialogue_panel") as CanvasLayer
	if _director == null or _player == null:
		print("no director/player; probe cannot run")
		quit(1)
		return

	var house := _world.get_node_or_null(^"GrandpaHouse")

	for beat: String in ["wake", "house", "return_starter"]:
		print("\n=== forced to beat '%s' ===" % beat)
		_force(beat)
		for i in 20:
			await physics_frame
		print("  beat now: %s" % str(_director.call("beat")))
		print("  tracked objective: '%s'" % _tracked())
		print("  tracked hint:      '%s'" % _tracked_hint())
		print("  door gate solid:   %s" % str(_door_solid(house)))
		var g := _grandpa_prompt()
		if g == null:
			print("  Grandpa prompt:    NOT FOUND in the tree")
		else:
			var d: float = _player.global_position.distance_to(g.global_position)
			var offer: Dictionary = g.call("interaction_offer", _player.global_position)
			print("  Grandpa prompt:    label='%s' enabled=%s radius=%.1f  player %.1fm away  offering=%s" % [
				str(g.get("label")), str(g.get("enabled")), float(g.get("radius")), d,
				"YES" if not offer.is_empty() else "no"])
		print("  arbiter is showing: '%s'" % str(_arbiter.call("prompt")) if _arbiter != null else "  no arbiter")

	# The trap itself: at `return_starter`, walk at the door like a player who
	# has been given no other instruction, and report what happens.
	print("\n=== at 'return_starter', walking at the door ===")
	_force("return_starter")
	for i in 20:
		await physics_frame
	if house != null:
		var door: Vector3 = house.call("marker", "door")
		await _walk_toward(door, 500)
		print("  stopped %.2fm from the door marker" % _player.global_position.distance_to(door))
		print("  dialogue open: %s" % str(_dialogue.call("is_open")) if _dialogue != null else "  no dialogue panel")
		print("  arbiter is showing: '%s'" % str(_arbiter.call("prompt")) if _arbiter != null else "")
		print("  tracked objective: '%s'" % _tracked())
		var g := _grandpa_prompt()
		if g != null:
			var offer: Dictionary = g.call("interaction_offer", _player.global_position)
			print("  from the door, Grandpa is %.1fm away and offering=%s" % [
				_player.global_position.distance_to(g.global_position),
				"YES" if not offer.is_empty() else "no"])
	quit(0)


func _force(beat: String) -> void:
	var progression: RefCounted = _game.get("progression") if _game != null else null
	if progression != null:
		progression.call("set_flag", "opening:beat:" + beat)
	_director.call("_force_restore_beat", beat)
	_director.call("_refresh_prompts")
	_director.call("_refresh_door_gate")


func _tracked() -> String:
	var log_: RefCounted = _game.get("quests") if _game != null else null
	if log_ == null:
		log_ = _game.get("quest_log")
	var progression: RefCounted = _game.get("progression")
	if log_ == null or progression == null:
		return "<no quest log on Game>"
	return str(log_.call("tracked_text", progression))


func _tracked_hint() -> String:
	var log_: RefCounted = _game.get("quests") if _game != null else null
	if log_ == null:
		log_ = _game.get("quest_log")
	var progression: RefCounted = _game.get("progression")
	if log_ == null or progression == null:
		return ""
	return str(log_.call("tracked_hint", progression))


func _door_solid(house: Node) -> String:
	if house == null:
		return "<no house>"
	var gate := house.get_node_or_null(^"DoorGate")
	if gate == null:
		return "<no DoorGate>"
	for child: Node in gate.get_children():
		if child is CollisionShape3D:
			return "solid" if not (child as CollisionShape3D).disabled else "open"
	return "<no shape>"


func _grandpa_prompt() -> Node3D:
	return _find_prompt(_world, ["grandpa"])


func _find_prompt(node: Node, needles: Array) -> Node3D:
	for child: Node in node.get_children():
		var script: Script = child.get_script()
		if script != null and str(script.resource_path).ends_with("interactable.gd"):
			var label := str(child.get("label")).to_lower()
			for needle: String in needles:
				if label.contains(needle):
					return child as Node3D
		var found := _find_prompt(child, needles)
		if found != null:
			return found
	return null


func _walk_toward(point: Vector3, frames: int) -> void:
	for i in frames:
		var to := point - _player.global_position
		to.y = 0.0
		if to.length() <= 0.8:
			break
		_rig.set("yaw", atan2(-to.x, -to.z))
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	for i in 10:
		await physics_frame
