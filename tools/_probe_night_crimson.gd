extends SceneTree

## Why does the world turn CRIMSON at night, and is Environment.adjustment_*
## the cause?
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_probe_night_crimson.gd
##
## Measured first, from tools/_capture_day_night_transition.gd's own twelve-hour
## sweep (mean channel values over the whole frame, one fixed viewpoint):
##
##     hour  17.90   R  86.4  G 104.1  B  85.8   R/B 1.01
##     hour  20.50   R  54.0  G  95.2  B 107.0   R/B 0.50   <- cool, correct
##     hour  22.00   R 135.0  G  48.1  B  39.5   R/B 3.42   <- blood red
##     hour  23.90   R 120.1  G  36.1  B  33.1   R/B 3.62
##
## The dusk ramp is smooth and cool right up to 20.50 and then FLIPS between
## 20.50 and 22.00. Nothing in art.json can explain that by blending: `night`'s
## own palette is cool throughout (#1b2d5c sky, #3d5285 horizon, #2a3b6e
## ambient, #b7c6ea sun) and `golden`'s is warm, so every intermediate is
## between a warm and a cool, never past either.
##
## What DOES change at exactly that point is a snap, not a blend.
## world_look.gd::_blend_dict lerps numbers and colours but has no meaningful
## blend for a boolean, so it snaps one at t >= 0.5. `night` is the only preset
## that sets `adjustment_enabled`, `golden` is at hour 18 and `night` at hour 0,
## so t = 0.5 falls at hour 21.0 -- between the last cool frame and the first
## red one.
##
## This probe boots the world once, pins hour 22, and shoots the same frame
## twice: once as shipped, once with `Environment.adjustment_enabled` forced
## off and nothing else touched. If the second frame is cool, the colour-grade
## is the cause; if both are red, it is not and this is the wrong tree.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/night_crimson"
const SETTLE_FRAMES := 240
const SHOT_SETTLE := 12
const HOUR := 22.0

# The same viewpoint the sweep above used, so the numbers are comparable.
const EYE := Vector2(-250.0, 2266.0)
const EYE_H := 1.8
const TARGET := Vector2(-258.0, 2258.0)
const TARGET_H := 0.9


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var world: Node = (load(SCENE) as PackedScene).instantiate()
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
	var look: Node = world.get_node_or_null(^"WorldLook")
	if look == null:
		print("no WorldLook")
		quit(1)
		return
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if player != null:
		player.global_position = Vector3(EYE.x + 5000.0, -500.0, EYE.y + 5000.0)

	var camera := Camera3D.new()
	camera.fov = 70.0
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()
	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)

	var field: RefCounted = HEIGHTFIELD.new()
	camera.global_position = Vector3(EYE.x, field.height_at(EYE.x, EYE.y) + EYE_H, EYE.y)
	camera.look_at(Vector3(TARGET.x, field.height_at(TARGET.x, TARGET.y) + TARGET_H, TARGET.y), Vector3.UP)

	var cycle: RefCounted = look.get("_cycle")
	if cycle != null:
		look.set("_elapsed_seconds", float(cycle.call("elapsed_for_hour", HOUR)))
	look.call("_apply_blended", HOUR)
	# The clock must not walk off the pinned hour between the two frames, or
	# the comparison is between two different times as well as two settings.
	look.set_process(false)
	look.set_physics_process(false)

	await _shoot(camera, "as-shipped")

	var env: Environment = _environment(world, camera)
	if env == null:
		print("no Environment found; cannot isolate the colour grade")
		quit(1)
		return
	print("as shipped at hour %.1f: adjustment_enabled=%s brightness=%.3f contrast=%.3f saturation=%.3f" % [
		HOUR, str(env.adjustment_enabled), env.adjustment_brightness,
		env.adjustment_contrast, env.adjustment_saturation])
	env.adjustment_enabled = false
	await _shoot(camera, "grade-off")

	print("done -> %s" % OUT_DIR)
	quit(0)


func _shoot(camera: Camera3D, label: String) -> void:
	for i in SHOT_SETTLE:
		await process_frame
	var image := root.get_texture().get_image()
	image.save_png("%s/%s.png" % [OUT_DIR, label])
	var r := 0.0
	var g := 0.0
	var b := 0.0
	var step := 7
	var n := 0
	for y in range(0, image.get_height(), step):
		for x in range(0, image.get_width(), step):
			var c := image.get_pixel(x, y)
			r += c.r
			g += c.g
			b += c.b
			n += 1
	var count := maxf(float(n), 1.0)
	print("%-12s R %.1f  G %.1f  B %.1f   R/B %.2f" % [
		label, r / count * 255.0, g / count * 255.0, b / count * 255.0,
		(r / count) / maxf(b / count, 0.0001)])


## The live Environment: the camera's own, or the WorldEnvironment's.
func _environment(world: Node, camera: Camera3D) -> Environment:
	if camera.environment != null:
		return camera.environment
	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is WorldEnvironment:
			return (node as WorldEnvironment).environment
		stack.append_array(node.get_children())
	return null
