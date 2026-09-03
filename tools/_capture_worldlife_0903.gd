extends SceneTree

## WORLD-LIFE-0903. One-off evidence capture: the Gate Meadow and Long Field
## stands, with the wild population actually there in frame (not staged).
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver \
##     opengl3 --resolution 1280x720 --script tools/_capture_worldlife_0903.gd
##
## Two eyes, each a player-height stand ON the road (per
## `terrain_playground.json` trail.bands[0]) looking at one of this pass's
## repositioned/added clusters:
##   - Gate Meadow (arc~130m): the new order-1075 Trailpup herd.
##   - Long Field (arc~1595m): order-1032's Bramblebun, moved to 12m lateral.
## Saved side by side as one contact sheet, `_sheet_life.png` (the only PNG
## name this repo's own .gitignore lets through under ralph/reports/).

const SCENE := "res://scenes/world/meadows_playground.tscn"
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const OUT_DIR := "res://ralph/reports/WORLD-LIFE-0903"

const BOOT_FRAMES := 240
const SETTLE_FRAMES := 90
const POSE_FRAMES := 4
const FOV := 70.0
const STAND_BACK_M := 3.5
const EYE_UP_M := 1.7

const STANDS := [
	{"id": "gate-meadow", "eye": Vector2(-2.0, 108.8), "toward": Vector2(5.9, 113.0)},
	{"id": "long-field", "eye": Vector2(334.5, 894.3), "toward": Vector2(328.2, 904.5)},
]

var _world: Node3D
var _player: Node3D
var _camera: Camera3D
var _field: RefCounted
var _director: Node = null
var _images: Array[Image] = []


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_field = HEIGHTFIELD.new()
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in BOOT_FRAMES:
		await physics_frame

	_player = _world.get_node_or_null(^"Player")
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _player == null or _director == null:
		print("FAIL: scene is missing Player or EncounterDirector")
		quit(1)
		return

	var look: Node = _world.get_node_or_null(^"WorldLook")
	if look != null:
		look.set_process(false)
		look.set_physics_process(false)
		look.call("apply_time", "day")
	var weather: Node = _world.get_node_or_null(^"WorldWeather")
	if weather != null:
		weather.set_process(false)
		weather.set_physics_process(false)
		weather.call("set_weather", "clear")

	_camera = Camera3D.new()
	_camera.fov = FOV
	_camera.far = 4000.0
	_world.add_child(_camera)
	_camera.make_current()

	var terrain: Node = _world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", _camera)

	var rig: Node = _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)

	for stand: Variant in STANDS:
		await _shoot(stand as Dictionary)

	_write_contact_sheet()
	print("wrote %s/_sheet_life.png (%d stands)" % [OUT_DIR, _images.size()])
	quit(0)


func _surface(at: Vector2) -> float:
	var analytic: float = _field.height_at(at.x, at.y)
	var space: PhysicsDirectSpaceState3D = (_world as Node3D).get_world_3d().direct_space_state
	if space == null:
		return analytic
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, analytic + 400.0, at.y), Vector3(at.x, analytic - 400.0, at.y))
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return analytic
	return (hit["position"] as Vector3).y


func _hide_huds() -> void:
	for node in _world.get_children():
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
	for node in root.get_children():
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false


func _shoot(stand: Dictionary) -> void:
	var id := str(stand["id"])
	var eye: Vector2 = stand["eye"]
	var toward: Vector2 = stand["toward"]
	var eye_ground := _surface(eye)
	_player.global_position = Vector3(eye.x, eye_ground + 0.4, eye.y)
	if _player is CharacterBody3D:
		(_player as CharacterBody3D).velocity = Vector3.ZERO

	var facing := (toward - eye).normalized()
	var cam2 := eye - facing * STAND_BACK_M
	var cam_ground := _surface(cam2)
	_camera.global_position = Vector3(cam2.x, cam_ground + EYE_UP_M, cam2.y)
	_camera.look_at(Vector3(toward.x, eye_ground + EYE_UP_M, toward.y), Vector3.UP)

	for i in SETTLE_FRAMES:
		await physics_frame
	_hide_huds()
	_camera.look_at(Vector3(toward.x, eye_ground + EYE_UP_M, toward.y), Vector3.UP)
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw

	var eye3 := Vector3(eye.x, eye_ground, eye.y)
	var nearby := 0
	var species_seen: Dictionary = {}
	for w: Variant in (_director.call("wild_creatures") as Array):
		var body := w as Node3D
		if body == null or not is_instance_valid(body) or not body.visible:
			continue
		if not bool(body.call("is_alive")):
			continue
		if body.global_position.distance_to(eye3) > 40.0:
			continue
		nearby += 1
		species_seen[str(body.get("species_id"))] = true
	print("[%s] %d wild bodies within 40m of the stand, %d distinct species: %s" % [
		id, nearby, species_seen.size(), ", ".join(species_seen.keys())])

	var image := root.get_texture().get_image()
	if image == null:
		print("  FAIL %s: viewport returned no image" % id)
		return
	image.save_png("%s/%s.png" % [OUT_DIR, id])
	print("  wrote %s/%s.png" % [OUT_DIR, id])
	_images.append(image)


func _write_contact_sheet() -> void:
	if _images.is_empty():
		return
	var w := _images[0].get_width()
	var h := _images[0].get_height()
	var sheet := Image.create(w * _images.size(), h, false, _images[0].get_format())
	for i in _images.size():
		var frame: Image = _images[i]
		if frame.get_format() != sheet.get_format():
			frame = frame.duplicate()
			frame.convert(sheet.get_format())
		sheet.blit_rect(frame, Rect2i(0, 0, w, h), Vector2i(w * i, 0))
	sheet.save_png("%s/_sheet_life.png" % OUT_DIR)
