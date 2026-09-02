extends SceneTree

## Two questions, one world stand-up, because standing the Meadows up is the
## expensive part and this lane has two changes to judge:
##
##   1. LEAF-CUT. Do the generated bushes read as leaves now, or still as a heap
##      of quads? Four rounds failed on this, every one of them by changing size,
##      count, tint or lighting instead of the SILHOUETTE. So this shoots them
##      from close enough that a single leaf's outline is several pixels across
##      -- `_probe_grass_field.gd`'s own near shot is at 1.2m up looking 9m
##      ahead, where a 0.85m bush is a smudge and any silhouette passes.
##   2. EDGE SHORTEN. Does the grass carpet now SINK into the terrain at the
##      ring's edge instead of stopping at it? The owner's words on the previous
##      state were that "the transition from real grass to paint is still very
##      noticable", so this shoots a long down-slope view where the whole 42-72m
##      fade is in frame at once and the seam, if there is still one, has
##      nowhere to hide.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_probe_leaf_cut.gd -- --out=shots/leaf_r1
##
## NEVER with `--headless` and a real rendering driver: that combination hangs
## forever with no error (docs/AGENT_WORKFLOW.md, "Art pipeline traps").

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const GRASS_FIELD := preload("res://scripts/world/grass_field.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"

const BOOT_FRAMES := 90
const SETTLE_FRAMES := 30
const POSE_FRAMES := 8

## Band 1 open meadow, ten metres off the travel route. A camera standing ON the
## trail photographs the trail -- that mistake cost two critics' answers on this
## lane already and the offset is why it does not recur.
const AT := Vector2(8.0, 90.0)
const TOWARD := Vector2(-40.0, 180.0)
const OFF_ROUTE := 10.0

## name, fov, eye offset back along the view, eye height, look distance, look height
const SHOTS := [
	# Low and close: a 0.85m bush at 2.2m still fills a third of the frame
	# height, which is the scale at which a leaf outline is judgeable. The eye
	# is at 1.00m and NOT lower, deliberately -- at 0.55m the lens sits INSIDE
	# the understorey and photographs single leaves a hand's width from the near
	# plane, unlit against sky with their outlines off-frame. A blind critic read
	# that first capture as "unlit flat leaf cards floating in the sky" and
	# ranked it a shipping-blocking bug. It is not one: the game's camera rides a
	# SpringArm well above bush height and cannot reach that pose. It was this
	# probe photographing the inside of a plant.
	["01-bush-low", 55.0, 2.2, 1.00, 6.0, 0.35],
	# Standing over it, the read a player actually gets while walking.
	["02-bush-stand", 62.0, 2.4, 1.55, 8.0, 0.30],
	# The whole ring in one frame: eye up high, looking down and out past the
	# 42m fade start to the 72m edge and the painted terrain beyond it.
	["03-ring-edge", 70.0, 0.0, 6.5, 95.0, -6.0],
	["04-ring-edge-low", 70.0, 0.0, 1.7, 95.0, -1.0],
]

var _field: RefCounted = null
var _world: Node = null
var _player: Node3D = null
var _camera: Camera3D = null
var _look: Node = null
var _weather: Node = null
var _out_dir := "res://shots/leaf"


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
	print("[leaf] world up")

	var rig: Node = _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	for node in _all(_world):
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false

	_player = _world.get_node_or_null(^"Player") as Node3D
	_camera = Camera3D.new()
	_camera.far = 4000.0
	_world.add_child(_camera)
	_camera.make_current()

	var terrain: Node = _world.get_node_or_null(^"Terrain")
	if terrain == null:
		print("FAIL: no Terrain node; the field has nothing to sample")
		quit(1)
		return
	if terrain.has_method("set_camera"):
		terrain.call("set_camera", _camera)
	_look = _world.get_node_or_null(^"WorldLook")
	_weather = _world.get_node_or_null(^"WorldWeather")

	# The thing under test, hung off the world root rather than baked into the
	# scene so this probe cannot leave anything behind in a .tscn. `enabled` in
	# the shipped config is false and stays false -- turning it on is an owner
	# decision made against an ROG Ally.
	var grass := MultiMeshInstance3D.new()
	grass.set_script(GRASS_FIELD)
	grass.set("force_enabled", true)
	grass.name = "GrassFieldProbe"
	_world.add_child(grass)
	await physics_frame
	grass.call("bind", terrain, _camera)
	for i in SETTLE_FRAMES:
		await physics_frame

	await _pin("day")

	var toward := (TOWARD - AT).normalized()
	var off_dir := Vector2(-toward.y, toward.x)
	var eye := AT + off_dir * OFF_ROUTE
	_place(eye, _surface(eye))
	for i in SETTLE_FRAMES:
		await physics_frame

	for entry: Variant in SHOTS:
		var shot: Array = entry as Array
		await _expose(str(shot[0]), float(shot[1]),
				eye - toward * float(shot[2]), float(shot[3]),
				eye + toward * float(shot[4]), float(shot[5]))

	print("")
	print("written to %s" % _out_dir)
	print("Software rendering under the Compatibility renderer: composition,")
	print("density and silhouette are trustworthy; frame times are not.")
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


func _expose(name: String, fov: float, eye: Vector2, up: float,
		target: Vector2, target_up: float) -> void:
	_camera.fov = fov
	_camera.global_position = Vector3(eye.x, _surface(eye) + up, eye.y)
	_camera.look_at(Vector3(target.x, _surface(target) + target_up, target.y), Vector3.UP)
	# The field follows the CAPTURE camera and only re-centres once the camera
	# has crossed a whole snap cell, so give it frames to notice before the
	# shutter or the first frame photographs the ring where the last one left it.
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		print("FAIL %s: viewport returned no image" % name)
		return
	if image.save_png("%s/%s.png" % [_out_dir, name]) != OK:
		print("FAIL %s: save_png" % name)
	else:
		print("  %s" % name)


func _place(at: Vector2, ground: float) -> void:
	if _player == null:
		return
	_player.global_position = Vector3(at.x, ground + 0.4, at.y)
	if _player is CharacterBody3D:
		(_player as CharacterBody3D).velocity = Vector3.ZERO


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
