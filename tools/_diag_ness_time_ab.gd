extends SceneTree

## Diagnostic only, not committed to the fix. Tests whether Warder Ness's
## face-black-void defect is driven by data/config/art.json's
## per-time-of-day `character_emission_floor` (1.0 day/golden, 0.5 night/dawn)
## crushing an already-dark face texture region toward the ACES tonemap toe,
## by pinning the clock to each named time and shooting the same close-up.

const NPC := preload("res://scripts/npc/npc_body.gd")
const TRAINER_NPC := preload("res://scripts/world/trainer_npc.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 120
const TALK_RANGE := 3.8
const EYE_HEIGHT := 1.62
const LOOK_HEIGHT := 1.25
const OUT_DIR := "res://ralph/reports/audit/diag-time-ab"

var _world: Node = null
var _camera: Camera3D = null

func _init() -> void:
	_run()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
	print("[diag-ab] settled")

	_camera = Camera3D.new()
	_world.add_child(_camera)
	_camera.fov = 48.0
	_camera.make_current()

	for node in _world.find_children("*", "CanvasLayer", true, false):
		(node as CanvasLayer).visible = false
	for node in root.find_children("*", "CanvasLayer", true, false):
		(node as CanvasLayer).visible = false

	for node in _world.find_children("*", "", true, false):
		if node.get_class() == "Terrain3D":
			node.call("set_camera", _camera)
			break
	for node in _world.find_children("WorldWeather", "", true, false):
		node.set_process(false)

	for node in _world.find_children("*", "", true, false):
		if node.is_in_group("player") and node is Node3D:
			(node as Node3D).global_position = Vector3(0.0, -400.0, 600.0)

	var look := _world.find_child("WorldLook", true, false)

	var centre := Vector3(13.0, 0.0, 9.0)
	centre.y = _ground(centre)

	var cfg := TRAINER_NPC.model_config({"rank": "officer", "base": "officer_b"})
	var body: Node3D = NPC.new()
	body.name = "DiagNess"
	_world.add_child(body)
	body.call("setup_from_config", cfg, null)
	body.call("stand_at", centre.x, centre.z)
	body.rotation.y = 0.0

	for i in 12:
		await physics_frame

	for time_name in ["day", "golden", "dawn", "night"]:
		if look != null:
			look.call("apply_time", time_name)
		for i in 20:
			await physics_frame
		await _shoot_from(
			body.global_position + Vector3(0.0, 0.0, TALK_RANGE),
			body.global_position,
			"ness-%s" % time_name)

	print("Frames written to %s" % OUT_DIR)
	quit(0)


func _shoot_from(stand: Vector3, target: Vector3, file: String) -> void:
	var eye := stand
	eye.y = _ground(stand) + EYE_HEIGHT
	var look := target
	look.y = _ground(target) + LOOK_HEIGHT
	_camera.global_position = eye
	_camera.look_at(look, Vector3.UP)
	for i in 4:
		await physics_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "%s/%s.png" % [OUT_DIR, file]
	image.save_png(path)
	var at := _camera.unproject_position(target)
	var half := 20
	var x0 := int(clampf(at.x - half, 0.0, float(image.get_width() - 1)))
	var x1 := int(clampf(at.x + half, 0.0, float(image.get_width() - 1)))
	var y0 := int(clampf(at.y - half - 40, 0.0, float(image.get_height() - 1)))
	var y1 := int(clampf(at.y - half, 0.0, float(image.get_height() - 1)))
	var total := 0.0
	var count := 0
	for y in range(y0, y1):
		for x in range(x0, x1):
			var c := image.get_pixel(x, y)
			total += 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			count += 1
	print("wrote %s  face-patch luma %.1f/255 (%d px)" % [
		path.get_file(), (total / count * 255.0) if count > 0 else -1.0, count])


func _ground(at: Vector3) -> float:
	if _world != null and _world.has_method("ground_height_at"):
		return float(_world.call("ground_height_at", at.x, at.z))
	return 0.0
