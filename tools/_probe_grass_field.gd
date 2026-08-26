extends SceneTree

## GRASS-FIELD spike, step 1: does a camera-relative grass carpet sit on the
## real Meadows terrain, under the renderer this project actually ships?
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_probe_grass_field.gd -- --out=shots/field_r0
##
## NEVER with `--headless` and a real rendering driver: that combination hangs
## forever with no error (ralph/conventions.md, "Art pipeline traps").
##
## This is a GO/NO-GO, and it is deliberately the cheapest possible version of
## the question. It stands the real world up, hangs a `GrassField` off it with
## `force_enabled` (the shipped config's `enabled` is false and stays false),
## points it at the live Terrain3D node and the capture camera, and photographs
## the same eyes `tools/_probe_grass_pass.gd` uses so the frames sit beside
## WORLD-GRASS's own sheets honestly.
##
## What it has to prove, in order, before any of the rest of the plan is worth
## doing:
##   1. the shader COMPILES under GL Compatibility -- no compute, no
##      RenderingDevice, no subsurface scattering, all three of which Godot
##      lists as unsupported there and `D01` locks this project to;
##   2. the blades land ON the terrain rather than on a plane at y=0 or a few
##      metres under it, which is what a wrong region lookup produces silently;
##   3. the control-map mask keeps them off the painted paths.
##
## It also prints the ground height the shader should be finding at each eye,
## sampled on the CPU from the same heightfield, so a frame that looks wrong can
## be checked against a number instead of argued about.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const GRASS_FIELD := preload("res://scripts/world/grass_field.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"

const BOOT_FRAMES := 90
const SETTLE_FRAMES := 30
const ARRIVE_FRAMES := 20
const POSE_FRAMES := 6
const FOV := 70.0
const BACK := 4.2
const UP := 2.4
const NEAR_UP := 1.2
const NEAR_BACK := 2.6
const NEAR_AHEAD := 9.0
## Same off-route offset WORLD-GRASS's own pass settled on, and for the same
## reason: a camera standing ON the trail photographs road, not meadow.
const OFF_ROUTE := 10.0
const OFF_UP := 1.6

const VIEWPOINTS := [
	["01-band1-open-meadow", Vector2(8.0, 90.0), Vector2(-40.0, 180.0)],
	["02-band2-forest-floor", Vector2(310.0, 1660.0), Vector2(400.0, 1800.0)],
	["03-band3-crossing", Vector2(-152.0, 4170.0), Vector2(-100.0, 4350.0)],
	["04-band4-high-pasture", Vector2(-280.0, 6460.0), Vector2(-70.0, 6720.0)],
]

var _field: RefCounted = null
var _world: Node = null
var _player: Node3D = null
var _camera: Camera3D = null
var _look: Node = null
var _weather: Node = null
var _grass: MultiMeshInstance3D = null
var _out_dir := "res://shots/field"


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = "res://" + arg.substr(6).trim_prefix("res://")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))

	_field = HEIGHTFIELD.new()
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in BOOT_FRAMES:
		await physics_frame
	print("[field] world up")

	var rig: Node = _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	for node in _all(_world):
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false

	_player = _world.get_node_or_null(^"Player") as Node3D
	_camera = Camera3D.new()
	_camera.fov = FOV
	_camera.far = 4000.0
	_world.add_child(_camera)
	_camera.make_current()

	var terrain: Node = _world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", _camera)
	_look = _world.get_node_or_null(^"WorldLook")
	_weather = _world.get_node_or_null(^"WorldWeather")

	# The thing under test. Hung off the world root rather than baked into the
	# scene, so this probe cannot leave anything behind in a .tscn.
	_grass = MultiMeshInstance3D.new()
	_grass.set_script(GRASS_FIELD)
	_grass.set("force_enabled", true)
	_grass.name = "GrassFieldProbe"
	_world.add_child(_grass)
	await physics_frame
	if terrain == null:
		print("FAIL: no Terrain node; the field has nothing to sample")
		quit(1)
		return
	_grass.call("bind", terrain, _camera)
	for i in SETTLE_FRAMES:
		await physics_frame

	# `--only=<substring>` shoots just the matching viewpoints. Iterating on a
	# shader wants one frame in two minutes, not eleven in twenty.
	var only := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.substr(7)

	await _pin("day")
	for entry: Variant in VIEWPOINTS:
		var shot: Array = entry as Array
		if only == "" or only in str(shot[0]):
			await _shoot(shot)

	print("")
	print("grass-field spike written to %s" % _out_dir)
	print("Software rendering under the Compatibility renderer: composition,")
	print("density and silhouette are trustworthy; frame times are not a")
	print("performance measurement.")
	quit(0)


func _pin(time: String) -> void:
	if _weather != null:
		_weather.set_process(true)
		_weather.set_physics_process(true)
		_weather.call("set_weather", "clear")
	if _look != null:
		_look.set_process(true)
		_look.set_physics_process(true)
		_look.call("apply_time", time)
	for i in 30:
		await physics_frame
	if _weather != null:
		_weather.set_process(false)
		_weather.set_physics_process(false)
	if _look != null:
		_look.set_process(false)
		_look.set_physics_process(false)


func _shoot(shot: Array) -> void:
	var name: String = str(shot[0])
	var eye: Vector2 = shot[1]
	var target: Vector2 = shot[2]
	var toward := (target - eye).normalized()

	_place(eye, _field.height_at(eye.x, eye.y))
	_frame(eye - toward * BACK, _field.height_at(eye.x, eye.y), UP,
			target, _field.height_at(target.x, target.y), 2.0)
	for i in ARRIVE_FRAMES:
		await physics_frame
	var ground := _surface(eye)
	_place(eye, ground)
	for i in SETTLE_FRAMES:
		await physics_frame

	await _expose("%s-eye" % name, eye - toward * BACK, UP, eye + toward * 40.0, 2.0)
	await _expose("%s-near" % name, eye - toward * NEAR_BACK, NEAR_UP,
			eye + toward * NEAR_AHEAD, 0.0)

	var off_dir := Vector2(-toward.y, toward.x)
	var off := eye + off_dir * OFF_ROUTE
	_place(off, _surface(off))
	for i in 20:
		await physics_frame
	await _expose("%s-off" % name, off - toward * NEAR_BACK, OFF_UP,
			off + toward * NEAR_AHEAD, 0.0)

	# The number the frame can be checked against. If the blades are not sitting
	# near this, the region lookup in the shader is wrong -- which is exactly the
	# failure that does not error.
	print("  %-22s ground: analytic %.2f  raycast %.2f  (blades should meet this)" % [
		name, _field.height_at(eye.x, eye.y), ground])


func _expose(name: String, eye: Vector2, up: float, target: Vector2, target_up: float) -> void:
	for node in _world.get_children():
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
	_frame(eye, _surface(eye), up, target, _surface(target), target_up)
	# The field follows the CAPTURE camera, and it only re-centres when the
	# camera has moved a whole snap cell -- so give it a frame to notice before
	# the shutter, or the first frame at a new eye photographs the ring still
	# sitting where the last one was.
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		print("FAIL %s: viewport returned no image" % name)
		return
	if image.save_png("%s/%s.png" % [_out_dir, name]) != OK:
		print("FAIL %s: save_png" % name)


func _place(at: Vector2, ground: float) -> void:
	if _player == null:
		return
	_player.global_position = Vector3(at.x, ground + 0.4, at.y)
	if _player is CharacterBody3D:
		(_player as CharacterBody3D).velocity = Vector3.ZERO


func _frame(eye: Vector2, eye_ground: float, up: float,
		target: Vector2, target_ground: float, target_up: float) -> void:
	_camera.global_position = Vector3(eye.x, eye_ground + up, eye.y)
	_camera.look_at(Vector3(target.x, target_ground + target_up, target.y), Vector3.UP)


func _surface(at: Vector2) -> float:
	var analytic: float = _field.height_at(at.x, at.y)
	var space: PhysicsDirectSpaceState3D = (_world as Node3D).get_world_3d().direct_space_state
	if space == null:
		return analytic
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, analytic + 400.0, at.y), Vector3(at.x, analytic - 400.0, at.y))
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return analytic
	return float((hit["position"] as Vector3).y)


func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_all(child))
	return out
