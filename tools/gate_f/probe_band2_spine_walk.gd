extends SceneTree

## N10-HARNESS-TESTS-0905. Does the band 2 spine actually walk, leg by leg, out
## of the Old Quarry and along the ranger camp spur?
##
##   godot --headless --path . --script tools/gate_f/probe_band2_spine_walk.gd
##
## S06's own route used to cut straight from the quarry at (403, 1794) toward
## the Warrens mouth, and that line does not go: measured on this branch, a
## single `move_to` burned all 30,000 walking frames with 0 held and stopped
## 734.2 m short at (340.0, 4.0, 1834.0), the route trace showing 544
## play-seconds inside a 78 m x 66 m band with `dead_travel_m` climbing to
## 1,986 m. W21-HARNESS-FIGHTS-0904 measured the same signature 14 m away
## (711 s, 1,258 m of dead travel at (336.2, 1.3, 1820.6)) and attributed it to
## navigator state left behind by a just-placed workbench; there is no
## workbench on this branch and it happens anyway, so the site is the cause.
##
## `data/config/terrain_playground.json`'s `trail.bands[band2_stone_and_root]`
## authors the route the world was built around. This walks its points with the
## real `stick_navigator.gd::walk_to()` -- the same call every Gate F journey
## step uses -- and reports each leg on its own, so a leg that does not go is
## named rather than hidden inside one long failure.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")

const START := Vector3(403.0, 0.0, 1794.0)
## The spine from the quarry, then the camp spur's own two ends with the anvil
## between them -- exactly the waypoints S06-30b..S06-30b4 and S06-49a now walk.
const LEGS: Array[Vector2] = [
	Vector2(330.0, 1950.0),
	Vector2(180.0, 2050.0),
	Vector2(20.0, 2130.0),
	Vector2(-150.0, 2210.0),
	Vector2(-259.6, 2257.4),
	Vector2(-310.0, 2320.0),
	Vector2(-420.0, 2470.0),
]
const BUDGET_FRAMES := 12000
const CLOSE_ENOUGH := 6.0
const SETTLE_FRAMES := 300

var _player: CharacterBody3D = null
var _rig: Node3D = null
var _stick := Vector2.ZERO


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame
	_player = _find_player(world)
	_rig = world.get_node_or_null(^"CameraRig") as Node3D
	if _player == null or _rig == null:
		print("PROBE FAIL: player=%s rig=%s" % [str(_player), str(_rig)])
		quit(1)
		return

	var ground := _player.global_position.y
	_player.global_position = Vector3(START.x, ground + 1.0, START.z)
	_player.velocity = Vector3.ZERO
	_rig.global_position = _player.global_position
	for i in 120:
		await physics_frame

	var nav: RefCounted = NAVIGATOR.new(self, _player, _rig,
		func(x: float, y: float) -> void:
			_stick = Vector2(x, y)
			_drive_stick())

	print("=== band 2 spine walk probe ===")
	print("start (%.1f, %.2f, %.1f); %d legs, %d frames and %.1f m each"
		% [_player.global_position.x, _player.global_position.y, _player.global_position.z,
			LEGS.size(), BUDGET_FRAMES, CLOSE_ENOUGH])
	var failed := 0
	for leg: Vector2 in LEGS:
		var target := Vector3(leg.x, _player.global_position.y, leg.y)
		var from := _player.global_position
		var frame0 := Engine.get_physics_frames()
		var arrived: bool = await nav.walk_to(target, BUDGET_FRAMES, CLOSE_ENOUGH)
		var spent := Engine.get_physics_frames() - frame0
		var at := _player.global_position
		var short := Vector2(at.x - leg.x, at.z - leg.y).length()
		if not arrived:
			failed += 1
		print("  %-7s (%.1f, %.1f) -> (%.1f, %.1f): %s in %d frames, %.1f m short, %d confined reset(s)"
			% [("ARRIVED" if arrived else "FAILED"), from.x, from.z, leg.x, leg.y,
				"walked %.1f m" % Vector2(at.x - from.x, at.z - from.z).length(),
				spent, short, int(nav.confined_resets())])
	print("VERDICT: %d of %d legs walked" % [LEGS.size() - failed, LEGS.size()])
	quit(1 if failed > 0 else 0)


func _drive_stick() -> void:
	Input.action_release("move_forward")
	Input.action_release("move_back")
	Input.action_release("move_left")
	Input.action_release("move_right")
	if _stick.y < -0.2:
		Input.action_press("move_forward", -_stick.y)
	elif _stick.y > 0.2:
		Input.action_press("move_back", _stick.y)
	if _stick.x < -0.2:
		Input.action_press("move_left", -_stick.x)
	elif _stick.x > 0.2:
		Input.action_press("move_right", _stick.x)


func _find_player(node: Node) -> CharacterBody3D:
	if node is CharacterBody3D and node.name == "Player":
		return node as CharacterBody3D
	for child in node.get_children():
		var hit := _find_player(child)
		if hit != null:
			return hit
	return null
