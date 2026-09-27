extends SceneTree

## Deterministic proof of `gate_a_material_route.gd::cross_village_fence_toward`
## on the exact leg CI run 36267784789 lost.
##
## The continuous run reaches the open-spine fiber stop at (-5, 141) only when
## the nearby authored fiber has not already filled the bill (it depends on
## whether the NPC segment spent (-10, -14) first), so a green continuous run
## does not by itself show the fence crossing ever ran. This stages the player
## at the CI failure's own start pose, (29.9, -31.9) inside the fence, and walks
## the helper's real leg out through a village gate to (-5, 141) and back in to
## the Village Square, with parsed controller input through the live InputMap.
## Staging (flags, the drop-in position) is fixture setup; every step of travel
## is the route helper's own navigator.

const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"
const ROUTE := preload("res://tests/helpers/gate_a_material_route.gd")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const BUILD_ROUTE := preload("res://tests/helpers/gate_a_build_segment.gd")
const STORY_LEDGER := preload("res://scripts/story/story_ledger.gd")
const START_XZ := Vector2(29.9, -31.9)
const OUTSIDE_STOP_XZ := Vector2(-5.0, 141.0)
const SETTLE_FRAMES := 300
const DROP_HEIGHT := 6.0

var _failures: Array[String] = []
var _world: Node3D
var _game: Node
var _player: CharacterBody3D
var _rig: Node3D


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(WORLD_SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	for _i in SETTLE_FRAMES:
		await physics_frame
	_game = root.get_node_or_null(^"/root/Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	if _game == null or _player == null or _rig == null:
		_finish(["the world booted without a Game autoload, a player or a camera rig"])
		return
	if not await _stage():
		_finish(_failures)
		return

	var route = ROUTE.new()
	route._tree = self
	route._world = _world
	route._game = _game
	route._player = _player
	route._rig = _rig
	if not route._resolve_move_bindings():
		_finish(route.failures)
		return
	route._nav = NAVIGATOR.new(self, _player, _rig, route._send_stick)

	var outside := _ground(OUTSIDE_STOP_XZ)
	if not await route.cross_village_fence_toward(outside):
		_finish(route.failures if not route.failures.is_empty() else ["the crossing out returned false with no failure recorded"])
		return
	var arrived: bool = await route._walk_to(outside, 1.65, route._travel_budget(outside))
	var short_by := _flat(outside)
	print("FENCE CROSSING — out: arrived=%s at %s (%.2fm from (-5, 141))" % [
		arrived, str(_player.global_position.round()), short_by])
	if not arrived:
		_failures.append("controller could not reach (-5, 141) through a village gate (stopped %.1fm short)" % short_by)

	var square: Vector2 = BUILD_ROUTE.BUILD_ROUTE_XZ[0]
	var home := _ground(square)
	if _failures.is_empty():
		if not await route.cross_village_fence_toward(home):
			_finish(route.failures if not route.failures.is_empty() else ["the crossing back returned false with no failure recorded"])
			return
		arrived = await route._walk_to(home, 2.0, route._travel_budget(home))
		print("FENCE CROSSING — back: arrived=%s at %s (%.2fm from the Village Square)" % [
			arrived, str(_player.global_position.round()), _flat(home)])
		if not arrived:
			_failures.append("controller could not come back in to the Village Square (stopped %.1fm short)" % _flat(home))
	for line: Variant in route.transcript:
		print("FENCE CROSSING — route | %s" % str(line))
	var crossings := 0
	for line: Variant in route.transcript:
		if str(line).begins_with("passed "):
			crossings += 1
	if _failures.is_empty() and crossings != 2:
		_failures.append("expected one gate crossing out and one back in, transcript shows %d" % crossings)
	_finish(_failures)


func _stage() -> bool:
	var progression: RefCounted = _game.get("progression")
	for flag: String in ["opening:beat:road", "opening:starter_granted", "road_gate_open",
			"tam_tools_given"]:
		progression.call("set_flag", flag)
	var sequence := _world.find_child("SequenceDirector", true, false)
	if sequence != null and sequence.has_method("_set_beat"):
		sequence.call("_set_beat", "free_play")
	for panel_name: String in ["DialoguePanel", "NamePrompt", "StarterPicker"]:
		var panel := _world.find_child(panel_name, true, false)
		if panel != null and panel.has_method("is_open") and bool(panel.call("is_open")) \
				and panel.has_method("close"):
			panel.call("close")
	# Fixture: open the village gates. A world booted straight from the scene
	# has no session for the story ledger to commit the key's world flag to, so
	# this uses `village_boundary.gd::open_permanently()` -- the production
	# seam the Warden's fall opens them through. The continuous run opens them
	# with the real key (`gate_a_material_route.gd::_unlock_road_gate`).
	var trail_node := _world.find_child("TrailGate", true, false)
	var verdict := {}
	if trail_node != null:
		verdict = STORY_LEDGER.set_world_flag(trail_node, "road_gate_open")
		if not bool(trail_node.call("is_open")) and trail_node.get_parent().has_method("open_permanently"):
			trail_node.get_parent().call("open_permanently")
	print("FENCE CROSSING — staging: TrailGate found=%s ledger verdict=%s parent=%s" % [
		trail_node != null, str(verdict), str(trail_node.get_parent().name) if trail_node != null else "-"])
	for _i in 30:
		await physics_frame
	var trail := _world.find_child("TrailGate", true, false)
	if trail == null or not bool(trail.call("is_open")):
		_failures.append("TrailGate is not open after road_gate_open was set; the fence has no way through")
		return false
	var y := float(_world.call("ground_height_at", START_XZ.x, START_XZ.y)) + DROP_HEIGHT
	_player.global_position = Vector3(START_XZ.x, y, START_XZ.y)
	_player.velocity = Vector3.ZERO
	for _i in 180:
		await physics_frame
		if _player.is_on_floor():
			break
	for _i in 30:
		await physics_frame
	if not _player.is_on_floor() or not bool(_player.call("locomotion_enabled")):
		_failures.append("the staged player at the CI start pose is not grounded with locomotion")
		return false
	return true


func _ground(at: Vector2) -> Vector3:
	return Vector3(at.x, float(_world.call("ground_height_at", at.x, at.y)), at.y)


func _flat(target: Vector3) -> float:
	return Vector2(target.x - _player.global_position.x, target.z - _player.global_position.z).length()


func _finish(failures: Array) -> void:
	print("")
	if failures.is_empty():
		print("gate A fence crossing: OK — out through a village gate to (-5, 141) and back to the square")
		quit(0)
		return
	for line: Variant in failures:
		print("gate A fence crossing FAIL: %s" % str(line))
	quit(1)
