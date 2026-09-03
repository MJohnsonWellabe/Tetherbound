extends SceneTree

## GRASS-REROLL. The temporal probe: does the ground cover CHANGE as the camera
## moves?
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_probe_grass_walk.gd -- --out=shots/reroll_before
##
## NEVER with `--headless` and a real rendering driver: that combination hangs
## forever with no error (docs/AGENT_WORKFLOW.md, "Art pipeline traps").
##
## WHY A SECOND GRASS TOOL. `tools/_probe_grass_pass.gd` answers "does the
## meadow look right", and it answers it from stills. The owner's 2026-08-28
## complaint is not about a still -- "the grass rerenders like every step" is a
## defect that only exists BETWEEN frames, and a sheet of four beautiful
## viewpoints cannot show it present or absent. This tool takes a SEQUENCE.
##
## TWO SEQUENCES, and the first one is the measurement.
##
##   `held-NN`  The capture camera does not move. AT ALL. What moves is the
##              camera the grass field is bound to -- a dummy Camera3D stepped
##              along the view line in `HELD_STEP` metres. So the viewpoint,
##              the terrain LOD, the props, the light and the frame are
##              byte-identical between exposures, and the ONLY thing that can
##              differ is what the ring did when its centre moved. A diff
##              between two `held` frames is the re-roll, isolated, with
##              nothing else in it. `HELD_STEP * HELD_FRAMES` deliberately
##              spans several `snap` cells so the defect has to show up.
##
##   `walk-NN`  Both cameras move together, a metre at a time: what a player
##              walking actually sees. Parallax means these frames are not
##              comparable pixel-for-pixel, and that is the point of having the
##              held sequence as well -- this one shows whether the fix reads
##              as calm to a human eye, the other one proves what changed.
##
## WIND IS SWITCHED OFF for the whole pass. Left on, every blade moves between
## every pair of frames and no reader can tell a re-roll from a breeze. The
## look question -- density, colour, silhouette, the gust front -- belongs to
## `_probe_grass_pass.gd`, which is unchanged and still runs with wind.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"

const BOOT_FRAMES := 90
const SETTLE_FRAMES := 45
const ARRIVE_FRAMES := 20
const POSE_FRAMES := 4
const FOV := 70.0

## The seat. Band 1 open meadow, ten metres off the authored route so the
## bottom of the frame is meadow rather than the worn path -- two blind passes
## in a row measured the trail's palette and reported it as the meadow's.
const SITE_EYE := Vector2(8.0, 90.0)
const SITE_LOOK := Vector2(-40.0, 180.0)
const OFF_ROUTE := 10.0

## The framing. 1.6m is a walking eye; aiming 14m ahead puts both the near
## field (where a single tuft is resolvable, so a re-roll is unmistakable) and
## the middle distance (where the drifts read) in one frame.
const EYE_UP := 1.6
const EYE_BACK := 2.4
const AHEAD := 14.0

## `snap` in grass_field.json is 2.0m, so 0.5m steps cross a cell boundary
## every fourth frame and twelve frames span six metres -- three crossings.
## Sized so the defect cannot hide between samples.
const HELD_STEP := 0.5
const HELD_FRAMES := 12
## The walking sequence is coarser because it is judged by eye, not by diff.
const WALK_STEP := 1.0
const WALK_FRAMES := 8

var _field: RefCounted = null
var _world: Node = null
var _player: Node3D = null
var _camera: Camera3D = null
var _follow: Camera3D = null
var _grass: Node3D = null
var _look: Node = null
var _weather: Node = null
var _out_dir := "res://shots/reroll"


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
	print("[reroll] writing to %s" % _out_dir)

	_field = HEIGHTFIELD.new()
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in BOOT_FRAMES:
		await physics_frame
	print("[reroll] world up, boot settled")

	var rig: Node = _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	_hide_huds()

	_player = _world.get_node_or_null(^"Player") as Node3D
	if _player == null:
		print("no Player node; the frames would have no 1.80m ruler in them")
		quit(1)
		return

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

	_grass = _world.get_node_or_null(^"GrassField") as Node3D
	if _grass == null:
		print("FAIL no GrassField node -- grass_field.json says enabled=%s" % [
			str(_grass != null)])
		print("     Nothing to probe. Turn the field on and re-run.")
		quit(1)
		return

	# The dummy the FIELD follows. Separate from the capture camera on purpose:
	# stepping this one while the capture camera stands still is what isolates
	# the ring's own behaviour from every other thing that changes in a frame.
	_follow = Camera3D.new()
	_follow.fov = FOV
	_world.add_child(_follow)
	_grass.call("bind", terrain, _follow)

	_silence_the_wind()
	await _pin("day")

	# Seat the player off the route, on ordinary meadow.
	var toward := (SITE_LOOK - SITE_EYE).normalized()
	var aside := Vector2(-toward.y, toward.x)
	var seat := SITE_EYE + aside * OFF_ROUTE
	_place(seat, _field.height_at(seat.x, seat.y))
	_frame(_camera, seat - toward * EYE_BACK, EYE_UP, seat + toward * AHEAD)
	for i in ARRIVE_FRAMES:
		await physics_frame
	_place(seat, _surface(seat))
	_frame(_camera, seat - toward * EYE_BACK, EYE_UP, seat + toward * AHEAD)
	for i in SETTLE_FRAMES:
		await physics_frame
	print("[reroll] seated at (%.1f, %.1f), ground %.2f" % [seat.x, seat.y, _surface(seat)])
	_report_rings()

	# ---- Sequence one: the capture camera is nailed down. -------------------
	var eye := seat - toward * EYE_BACK
	var at := seat + toward * AHEAD
	_frame(_camera, eye, EYE_UP, at)
	for i in HELD_FRAMES:
		var centre := seat + toward * (HELD_STEP * float(i))
		_frame(_follow, centre, EYE_UP, centre + toward * AHEAD)
		await _expose("held-%02d" % i)
	print("[reroll] held sequence: %d frames, ring centre walked %.1fm, camera did not move" % [
		HELD_FRAMES, HELD_STEP * float(HELD_FRAMES - 1)])

	# ---- Sequence two: both move, which is what a player sees. --------------
	for i in WALK_FRAMES:
		var here := seat + toward * (WALK_STEP * float(i))
		_place(here, _surface(here))
		var weye := here - toward * EYE_BACK
		_frame(_camera, weye, EYE_UP, here + toward * AHEAD)
		_frame(_follow, weye, EYE_UP, here + toward * AHEAD)
		for j in 3:
			await physics_frame
		await _expose("walk-%02d" % i)
	print("[reroll] walk sequence: %d frames, %.1fm travelled" % [
		WALK_FRAMES, WALK_STEP * float(WALK_FRAMES - 1)])

	print("")
	print("re-roll pass written to %s" % _out_dir)
	print("Wind was OFF for every frame: any difference between two `held-`")
	print("frames is the ring re-rolling and nothing else.")
	quit(0)


## Wind off, everywhere in the field. Not a look judgement -- with it on, every
## blade has moved between any two frames and the sequence cannot answer the
## question it exists to answer.
func _silence_the_wind() -> void:
	for node: Node in [_grass] + _grass.get_children():
		var vis := node as GeometryInstance3D
		if vis == null:
			continue
		var mat := vis.material_override as ShaderMaterial
		if mat == null:
			continue
		for key: String in ["wind_strength", "gust", "sway"]:
			mat.set_shader_parameter(key, 0.0)


## What the ring actually stood up, printed so the sheet carries its own cost
## figure rather than needing the reader to trust a config file.
func _report_rings() -> void:
	var total := 0
	for node: Node in [_grass] + _grass.get_children():
		var mmi := node as MultiMeshInstance3D
		if mmi == null or mmi.multimesh == null:
			continue
		total += mmi.multimesh.instance_count
		print("  ring %-18s %8d instances" % [node.name, mmi.multimesh.instance_count])
	print("  ring %-18s %8d instances" % ["TOTAL", total])


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


func _hide_huds() -> void:
	for node in _world.get_children():
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
	for node in root.get_children():
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false


func _expose(name: String) -> void:
	_hide_huds()
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
	_player.global_position = Vector3(at.x, ground + 0.4, at.y)
	if _player is CharacterBody3D:
		(_player as CharacterBody3D).velocity = Vector3.ZERO


func _frame(cam: Camera3D, eye: Vector2, up: float, target: Vector2) -> void:
	cam.global_position = Vector3(eye.x, _surface(eye) + up, eye.y)
	cam.look_at(Vector3(target.x, _surface(target), target.y), Vector3.UP)


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
