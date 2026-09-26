extends Node

## Owner ruling 2026-09-26, "rejoin returns to exact spot" (MULTIPLAYER
## §Return-home placement). A guest's saved pose is only its own to resume in
## the SAME host world: the one whose instance the character last stood in
## (`last_world_instance_id`). A guest builds its world BEFORE the socket opens
## (`join_driver.gd`), so which world it joined is unknown when the pose would
## normally apply. `title_screen.gd::_begin_join()` therefore takes the pose off
## the live character before the build and mounts this node; once the host
## snapshot is applied it compares instances and either seats the saved pose
## (then re-runs the realm's sealed-gate placement) or leaves the authored
## regional spawn the world already chose.

const ENFORCE_METHOD := "enforce_sealed_placement"
## `teleport_body()`: commit a jump without a kinematic sweep. Seating a saved
## pose can move the guest kilometres from its regional spawn; set as a plain
## position, GodotPhysics sweeps the body across the whole jump and the next
## `move_and_slide()` against Terrain3D collision measured ~4.4 s (F14#3).
const REMOTE_CREATURE := preload("res://scripts/creatures/remote_creature.gd")

## {"pose": saved_player_pose, "world_instance_id": the instance it was saved in}
var _candidate: Dictionary = {}
var _decided := false
var _outcome := ""
## Where the world had placed the player (its regional spawn) when deciding.
var _placed_at: Array = []


## The whole decision, pure: the pose to seat, or {} for the regional spawn.
## - `candidate.world_instance_id` must be a non-empty string equal to the host
##   snapshot's instance (`WorldState.reward_delivery_namespace`);
## - the pose must name the realm this guest is standing in, with a finite
##   position (anything else is not a place in this world).
static func decide(candidate: Dictionary, host_instance: Variant, current_realm: String) -> Dictionary:
	var saved_instance: Variant = candidate.get("world_instance_id", null)
	if typeof(saved_instance) != TYPE_STRING or (saved_instance as String).is_empty():
		return {}
	if typeof(host_instance) != TYPE_STRING or saved_instance != host_instance:
		return {}
	var pose: Variant = candidate.get("pose", {})
	if not pose is Dictionary or (pose as Dictionary).is_empty():
		return {}
	if str((pose as Dictionary).get("realm", "meadows")) != current_realm:
		return {}
	var at: Variant = (pose as Dictionary).get("position", [])
	if not at is Array or (at as Array).size() < 3:
		return {}
	for axis: Variant in (at as Array).slice(0, 3):
		if not (axis is float or axis is int) or not is_finite(float(axis)):
			return {}
	return (pose as Dictionary).duplicate(true)


func configure(candidate: Dictionary) -> void:
	_candidate = candidate.duplicate(true)


## "exact", "regional", or "" while undecided. Read by the proof harness.
func outcome() -> String:
	return _outcome


## The world's own placement at decision time, before any saved pose.
func placed_at() -> Array:
	return _placed_at.duplicate()


func _process(_delta: float) -> void:
	if _decided:
		return
	var game := get_parent()
	var session: Node = game.get("session") if game != null else null
	var driver := game.get_node_or_null(^"JoinDriver") if game != null else null
	if session == null:
		queue_free()
		return
	# `handshake_snapshot_applied()`, not `snapshot_ready()`: a torn-down or
	# cancelled attempt resets the latter to true while this peer still holds
	# its own pre-snapshot world, and a retrying JoinDriver dials again.
	if not bool(session.call("handshake_snapshot_applied")):
		if driver == null or not bool(driver.call("is_running")):
			# The join ended without a host snapshot: nothing to seat.
			_decided = true
			queue_free()
		return
	_decided = true
	set_process(false)
	var world: Variant = game.get("world")
	var host_instance: Variant = (world as RefCounted).get("reward_delivery_namespace") if world != null else null
	var player := game.call("_find_player") as Node3D if game.has_method("_find_player") else null
	if player != null:
		_placed_at = [player.global_position.x, player.global_position.y, player.global_position.z]
	var pose := decide(_candidate, host_instance, str(game.get("current_realm")))
	if pose.is_empty():
		_outcome = "regional"
		print("[rejoin] regional spawn (saved in %s, host world %s)" % [
			str(_candidate.get("world_instance_id", "")), str(host_instance)])
		return
	game.set("saved_player_pose", pose)
	if not bool(game.call("apply_loaded_player_pose")):
		_outcome = "regional"
		print("[rejoin] saved pose could not be applied; regional spawn kept")
		return
	var seated := game.call("_find_player") as PhysicsBody3D if game.has_method("_find_player") else null
	if seated != null:
		REMOTE_CREATURE.teleport_body(seated, seated.global_position)
	var scene := get_tree().current_scene
	if scene != null and scene.has_method(ENFORCE_METHOD):
		scene.call(ENFORCE_METHOD)
	_outcome = "exact"
	print("[rejoin] same host world %s: seated the saved pose" % str(host_instance))
