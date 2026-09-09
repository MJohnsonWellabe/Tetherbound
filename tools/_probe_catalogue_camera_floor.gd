extends SceneTree

## Native regression for the catalogue survey's production-camera contract.
## It distinguishes authored floors from terrain, retains the old invalid
## below-floor calculation as a negative control, and exercises the actual
## camera_rig.gd SpringArm3D against a real physics obstruction.

const CAMERA_RIG := preload("res://scripts/player/camera_rig.gd")
const SURVEY := preload("res://tools/catalogue_survey.gd")

const FLOOR_Y := 6.0
const TERRAIN_Y := 0.0
const CAMERA_DISTANCE := 5.2

var _failures: Array[String] = []


class FixtureWorld extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return TERRAIN_Y


class AuthoredFloor extends Node3D:
	func built_floor_height_at(x: float, z: float) -> float:
		if absf(x) <= 2.0 and absf(z) <= 2.0:
			return FLOOR_Y
		if absf(x - 10.0) <= 2.0 and absf(z) <= 2.0:
			return -4.0
		return NAN


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := FixtureWorld.new()
	world.name = "FixtureWorld"
	root.add_child(world)
	var floor_claim := AuthoredFloor.new()
	floor_claim.name = "AuthoredFloor"
	world.add_child(floor_claim)
	var player := CharacterBody3D.new()
	player.name = "Player"
	world.add_child(player)

	var elevated := SURVEY.resolve_capture_ground(player, 0.0, 0.0, TERRAIN_Y)
	_expect(is_equal_approx(elevated, FLOOR_Y),
		"authored elevated floor must replace terrain")
	var buried := SURVEY.resolve_capture_ground(player, 10.0, 0.0, 2.0)
	_expect(is_equal_approx(buried, -4.0),
		"authored floor below terrain must win outright, not max()")
	var old_camera_y := maxf(TERRAIN_Y + 2.5, TERRAIN_Y + 1.6)
	_expect(old_camera_y < elevated,
		"negative control must reproduce the old below-floor camera placement")

	player.global_position = Vector3(0.0, elevated, 0.0)
	var rig := CAMERA_RIG.new() as SpringArm3D
	rig.name = "CameraRig"
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	rig.add_child(camera)
	world.add_child(rig)
	rig.call("set_target", player, {
		"distance": CAMERA_DISTANCE,
		"height": 1.75,
		"pitch_start_deg": 0.0,
	})
	var forward := Vector2(0.0, -1.0)
	var yaw := SURVEY.capture_yaw(forward)
	_expect(is_zero_approx(yaw), "route-facing helper must put this fixture camera behind its target")
	rig.set("yaw", yaw)
	rig.rotation = Vector3(0.0, yaw, 0.0)
	rig.global_position = player.global_position
	for _frame in 4:
		await process_frame
		await physics_frame
	var clear_distance := camera.global_position.distance_to(rig.global_position)
	_expect(absf(clear_distance - CAMERA_DISTANCE) <= 0.05,
		"production spring arm must reach its clear configured distance")
	var camera_offset_xz := Vector2(
		camera.global_position.x - player.global_position.x,
		camera.global_position.z - player.global_position.z)
	_expect(camera_offset_xz.dot(forward) < -CAMERA_DISTANCE + 0.05,
		"production camera must sit behind the requested route heading")
	_expect(camera.global_position.y > elevated,
		"production camera must remain above the authored floor")

	var wall := StaticBody3D.new()
	wall.name = "CameraObstruction"
	var wall_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.0, 4.0, 0.5)
	wall_shape.shape = box
	wall.add_child(wall_shape)
	wall.position = Vector3(0.0, elevated + 1.75, 2.6)
	world.add_child(wall)
	for _frame in 4:
		await physics_frame
		await process_frame
	var obstructed_distance := camera.global_position.distance_to(rig.global_position)
	_expect(obstructed_distance < clear_distance - 0.5,
		"production SpringArm3D must shorten against a real obstruction")
	_expect(camera.global_position.z < wall.global_position.z,
		"camera must stay on the trainer side of the obstruction")

	if _failures.is_empty():
		print("CATALOGUE CAMERA FIXTURE PASS: elevated %.2f old-camera %.2f clear %.2f obstructed %.2f"
			% [elevated, old_camera_y, clear_distance, obstructed_distance])
		quit(0)
	else:
		for failure: String in _failures:
			push_error(failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
