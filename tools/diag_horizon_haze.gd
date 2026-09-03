extends SceneTree

## EV8: the world past the 512m bake reads as a pale, sharply-edged wall
## instead of atmosphere (see docs/CURRENT_STATE.md EV8 / R9.4-remainder-2). This
## renders 03-rise-overlook -- the frame that shows the defect worst -- once
## per fog variant in a single scene load, to find a haze treatment that reads
## as depth rather than as an absence, without re-fogging the midground R9.4
## already tuned.
##
## Writes shots/_diag/<name>.png. Nothing here is part of the survey; delete
## the output when the question is answered.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/_diag"
const SETTLE_FRAMES := 240

# Exact 03-rise-overlook framing from tools/survey.gd, so results compare
# directly against the survey's own baseline frame.
const EYE := Vector2(190.0, -60.0)
const EYE_H := 11.0
const TARGET := Vector2(-60.0, 60.0)
const TARGET_H := 0.0
const HORIZON := 0.24
const FOV := 70.0

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

	var rig: Node = _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	var hud: CanvasLayer = _world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false

	_camera = Camera3D.new()
	_camera.fov = FOV
	_camera.far = 2000.0
	_world.add_child(_camera)
	_camera.make_current()
	_pose()

	var look: Node = _world.get_node_or_null(^"WorldLook")
	if look != null:
		look.call("apply_time", "day")

	var env: Environment = (_world.get_node_or_null(^"WorldEnvironment") as WorldEnvironment).environment

	await _shoot("00-baseline")

	# A: aerial perspective alone, pushed hard. Blends fog toward the sky
	# colour with distance -- if the pale band is a sky-adjacent luminance,
	# this should fold it toward the sky rather than leaving a hard edge.
	var base_aerial := env.fog_aerial_perspective
	for aerial in [0.6, 0.85, 1.0]:
		env.fog_aerial_perspective = aerial
		await _shoot("A-aerial-%.2f" % aerial)
	env.fog_aerial_perspective = base_aerial

	# B: height fog, concentrated near the terrain's own elevation band, so
	# the horizon gets thicker haze without re-fogging the sky above or the
	# near/mid ground below eye height.
	var base_height := env.fog_height
	var base_height_density := env.fog_height_density
	for combo in [[0.0, 0.02], [0.0, 0.05], [10.0, 0.05]]:
		env.fog_height = combo[0]
		env.fog_height_density = combo[1]
		await _shoot("B-height-%.0f-%.2f" % [combo[0], combo[1]])
	env.fog_height = base_height
	env.fog_height_density = base_height_density

	# C: aerial perspective + height fog together, moderate on each so
	# neither alone has to do all the work.
	env.fog_aerial_perspective = 0.7
	env.fog_height = 0.0
	env.fog_height_density = 0.03
	await _shoot("C-combo")
	env.fog_aerial_perspective = base_aerial
	env.fog_height = base_height
	env.fog_height_density = base_height_density

	# D: fog_light_energy up, to check whether the pale band is fog picking
	# up excess sun scatter rather than a density/blend problem.
	var base_sun_scatter := env.fog_sun_scatter
	env.fog_sun_scatter = 0.0
	await _shoot("D-no-sun-scatter")
	env.fog_sun_scatter = base_sun_scatter

	print("done -> %s" % OUT_DIR)
	quit(0)


func _pose() -> void:
	var field: RefCounted = HEIGHTFIELD.new()
	var eye_ground: float = field.height_at(EYE.x, EYE.y)
	var target_ground: float = field.height_at(TARGET.x, TARGET.y)
	_camera.global_position = Vector3(EYE.x, eye_ground + EYE_H, EYE.y)
	_camera.look_at(Vector3(TARGET.x, target_ground + TARGET_H, TARGET.y), Vector3.UP)
	var half := tan(deg_to_rad(FOV) * 0.5)
	var pitch := -atan((0.5 - clampf(HORIZON, 0.05, 0.95)) * 2.0 * half)
	_camera.rotation = Vector3(pitch, _camera.rotation.y, 0.0)


func _shoot(name: String) -> void:
	for i in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png("%s/%s.png" % [OUT_DIR, name])
	print("shot -> %s.png" % name)
