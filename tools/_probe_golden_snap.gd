extends SceneTree

## One-off probe (T1-SKY): is the driven blend at hour~18 still wrong after
## the weather-pin/sun-disc/cloud-tint fixes, or does even a direct
## apply_time("golden") SNAP look this muted from the ranger-camp viewpoint
## _capture_day_night_transition.gd uses? Same EYE/TARGET/HORIZON as that
## tool, so this is a true same-viewpoint, same-framing comparison.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/day_night"
const SETTLE_FRAMES := 240
const FOV := 70.0

const EYE := Vector2(-250.0, 2266.0)
const EYE_H := 1.8
const TARGET := Vector2(-258.0, 2258.0)
const TARGET_H := 0.9
const HORIZON := 0.32


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var packed: PackedScene = load(SCENE)
	var world: Node = packed.instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	var hud: CanvasLayer = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var look: Node = world.get_node_or_null(^"WorldLook")
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var field: RefCounted = HEIGHTFIELD.new()
	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)

	if weather != null:
		weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)

	if player != null:
		var far_xz := EYE + Vector2(5000.0, 5000.0)
		player.global_position = Vector3(far_xz.x, field.height_at(far_xz.x, far_xz.y) + 1.0, far_xz.y)

	var eye_ground: float = field.height_at(EYE.x, EYE.y)
	var target_ground: float = field.height_at(TARGET.x, TARGET.y)
	var eye := Vector3(EYE.x, eye_ground + EYE_H, EYE.y)
	var target := Vector3(TARGET.x, target_ground + TARGET_H, TARGET.y)
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)
	camera.rotation = Vector3(_pitch_for_horizon(HORIZON), camera.rotation.y, 0.0)

	if look != null:
		look.call("apply_time", "golden")
	for i in 20:
		await physics_frame
	await RenderingServer.frame_post_draw
	var image: Image = get_root().get_viewport().get_texture().get_image()
	var path := "%s/probe-golden-snap-rangercamp.png" % OUT_DIR
	image.save_png(path)
	print("wrote -> %s" % path)
	quit(0)


func _pitch_for_horizon(fraction: float) -> float:
	var half := tan(deg_to_rad(FOV) * 0.5)
	return -atan((0.5 - clampf(fraction, 0.05, 0.95)) * 2.0 * half)
