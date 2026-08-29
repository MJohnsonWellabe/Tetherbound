extends SceneTree

## T1-NIGHT. One-shot A/B for the stair-step artefact Judge 2 flagged at
## hour-22.00 (moonlit/shadow boundaries quantising into large rectangular
## blocks, bottom-left of frame): is it `lights_and_shadows/directional_shadow/
## size` (SA1 halved this 4096 -> 2048 for ROG Ally VRAM, project.godot's own
## comment says "raise it back if shadow edges visibly stair-step on device;
## that is the trade being made here"), or something the atlas size cannot
## explain (a `_comment_exposure_ev4_lighting` entry in art.json already
## records raising it back to 4096 producing a "pixel-identical edge" for a
## DIFFERENT shadow artefact near the Barn -- so this is not assumed, it is
## tested, same as that precedent)?
##
## Shoots the exact _capture_day_night_transition.gd hour-22.00 viewpoint at
## the shipped 2048 atlas, then calls RenderingServer.
## directional_shadow_atlas_set_size(4096) at runtime (no project.godot edit,
## no restart needed -- this is a live render-target resize) and shoots again
## from the identical camera/hour state. A real difference in the stair-step
## rectangles between the two frames means atlas size is a real, cheap lever;
## no difference rules it out the same way the Barn precedent did.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_probe_shadow_atlas.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/day_night"
const SETTLE_FRAMES := 240
const SETTLE_AFTER_CHANGE := 20
const FOV := 70.0
const HOUR := 22.0

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
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return

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

	if look == null:
		push_error("no WorldLook node; cannot drive time of day")
		quit(1)
		return

	if weather != null:
		if weather.has_method("set_weather"):
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

	var cycle: RefCounted = look.get("_cycle")
	var length: float = 600.0
	if cycle != null:
		length = float(cycle.get("day_length_seconds"))
	var elapsed: float = (HOUR / 24.0) * length
	look.set("_elapsed_seconds", elapsed)
	look.call("_apply_blended", HOUR)
	for i in 10:
		await physics_frame
	await RenderingServer.frame_post_draw
	_shoot("shadow-atlas-2048-hour-22.00")

	RenderingServer.directional_shadow_atlas_set_size(4096, true)
	for i in SETTLE_AFTER_CHANGE:
		await physics_frame
	await RenderingServer.frame_post_draw
	_shoot("shadow-atlas-4096-hour-22.00")

	print("")
	print("frames -> %s" % OUT_DIR)
	print("Software rendering (D06/D01) -- see tools/survey.sh's own caveat.")
	quit(0)


func _pitch_for_horizon(fraction: float) -> float:
	var half := tan(deg_to_rad(FOV) * 0.5)
	return -atan((0.5 - clampf(fraction, 0.05, 0.95)) * 2.0 * half)


func _shoot(name: String) -> void:
	var image: Image = get_root().get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [OUT_DIR, name]
	image.save_png(path)
	print("  %-32s -> %s" % [name, path])
