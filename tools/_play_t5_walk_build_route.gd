extends SceneTree

## T5-CARE: walk the opening's build route with the stick and watch the floor.
##
##   godot --headless --path . --script tools/_play_t5_walk_build_route.gd
##
## `tests/smoke_gate_a_build_segment_meadows.gd` fails on `ralph/LAND-0830I`,
## and the world itself prints the reason:
##
##   [world_perimeter_corridor] player fell below the world at 14, -133, -19
##
## `tools/_probe_t5_holes2.gd` ruled out a static hole: a capsule dropped down
## every suspect column rests on the terrain. So the question is whether a
## MOVING player falls through terrain that a stationary one stands on -- i.e.
## whether terrain collision residency keeps up with a walk. That is a section I
## core-verb reliability question and it is upstream of every section H
## building verdict, because it is the walk TO the build patch.
##
## Drives the same `stick_navigator.gd` the production harnesses use, over the
## same authored waypoints, and samples the player's altitude every physics
## frame.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const SETTLE_FRAMES := 300
## `gate_a_build_segment.gd::BUILD_ROUTE_XZ`, verbatim.
const ROUTE: Array = [
	Vector2(10.0, -13.0),
	Vector2(18.0, -24.0),
	Vector2(30.0, -40.0),
]
## How far below the local ground counts as "went through the floor".
const FALL_MARGIN := 3.0

var _world: Node3D
var _player: CharacterBody3D
var _rig: Node3D
var _nav = null
var _worst_below := 0.0
var _worst_at := Vector3.ZERO
var _fell := false
var _samples := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	# The same fixture state the build segment sets, so this reproduces ITS run
	# rather than a different one.
	game.get("progression").call("set_flag", "opening:beat:free_play")
	_world = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	if _player == null or _rig == null:
		print("T5 WALK: BLOCKED — no player/camera rig")
		quit(1)
		return
	print("")
	print("=== T5 build-route walk ===")
	print("  natural spawn: %s" % str(_player.global_position))

	# Stand at the route entry the way the build segment's fixture does.
	var ground := float(_world.call("ground_height_at", ROUTE[0].x, ROUTE[0].y))
	_player.global_position = Vector3(ROUTE[0].x, ground + 1.0, ROUTE[0].y)
	_player.velocity = Vector3.ZERO
	for i in 90:
		await physics_frame
	print("  placed at the Village Square apron, settled to %s (ground_height_at=%.2f)" % [
		str(_player.global_position), ground])

	_nav = NAVIGATOR.new(self, _player, _rig, Callable(self, "_sample"))

	for i in range(1, ROUTE.size()):
		var xz := ROUTE[i] as Vector2
		var target := Vector3(xz.x, _player.global_position.y, xz.y)
		print("  walking to waypoint %d (%.0f, %.0f) from %s ..." % [
			i, xz.x, xz.y, str(_player.global_position)])
		var arrived: bool = await _nav.walk_to(target, 3600, 0.8)
		var flat := Vector2(_player.global_position.x, _player.global_position.z).distance_to(xz)
		print("    %s at %s, %.2fm from the waypoint" % [
			"ARRIVED" if arrived else "DID NOT ARRIVE", str(_player.global_position), flat])
		if not arrived:
			break

	print("")
	print("  sampled %d physics frames of walking" % _samples)
	if _fell:
		print("  VERDICT: FAIL — the player went through the floor while walking.")
		print("    worst was %.2fm below local ground at %s" % [_worst_below, str(_worst_at)])
	else:
		print("  VERDICT: the player stayed on the floor for the whole route "
			+ "(worst dip %.2fm below local ground at %s)" % [_worst_below, str(_worst_at)])
	quit(0)


## Called by the navigator every frame it drives. Compares the player's feet to
## the world's own height at the column they are over.
func _sample() -> void:
	_samples += 1
	var p := _player.global_position
	if p.y < -50.0:
		_fell = true
		_worst_below = maxf(_worst_below, 999.0)
		_worst_at = p
		return
	var ground := float(_world.call("ground_height_at", p.x, p.z))
	var below := ground - p.y
	if below > _worst_below:
		_worst_below = below
		_worst_at = p
	if below > FALL_MARGIN:
		_fell = true
