extends SceneTree

## The four Gate F visual-pass sites, re-shot from the camera the game would
## actually put there, so the defects can be diagnosed instead of guessed at.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_capture_gate_f_defect_sites.gd
##
## `ralph/reports/GATE_F_VISUAL_PASS_2026-08-26.md` names four things this
## session has to see before it can fix any of them: a solid black unshaded
## sphere in the sky at `hall`, a camera inside the hillside at `the_rise`,
## Team Tether reading teal rather than oxblood at `the_tether_relay`, and a
## placeholder box above the trainer's head at `grandpas_village`. The frames
## behind that report are not in the repository -- only the §H recorder frames
## and the contact sheet are -- so they are re-taken here.
##
## THE CAMERA IS RECONSTRUCTED, NOT INVENTED. Each site is X07's own teleport
## position and its own `face` target, and the eye is placed where
## `camera_rig.gd` would put it for that pair: `camera.distance` behind the
## player along the look bearing, `camera.height` up, tilted by
## `camera.pitch_start_deg`, all read from movement.json rather than typed here.
## That is what makes `the_rise`'s "the camera is inside the hillside" a
## question this tool can answer at all -- a free camera parked at a pretty
## viewpoint would simply not reproduce it.
##
## `ground_height_at` is asked of the world for both ends, so a site on a slope
## gets an eye at eye height above ITS ground rather than above sea level.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const MOVEMENT := "res://data/config/movement.json"
const OUT := "res://shots/gate_f_defects"
const SETTLE_FRAMES := 240
const SHOT_SETTLE_FRAMES := 40

## site -> [player x, player z, look-at x, look-at z]. Straight out of
## tools/gate_f/segments/X07.json: the `teleport` args and the block's own
## `face` args, unmodified.
const SITES := {
	"grandpas_village": [6.0, -22.0, 6.0, -82.0],
	"the_rise": [88.0, -43.0, 88.0, -103.0],
	"the_tether_relay": [348.0, 3756.0, 348.0, 3696.0],
	"hall": [150.0, 7595.0, 150.0, 7535.0],
}


func _init() -> void:
	_run()


func _run() -> void:
	var cfg: Dictionary = {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MOVEMENT))
	if parsed is Dictionary:
		cfg = (parsed as Dictionary).get("camera", {})
	var distance := float(cfg.get("distance", 5.2))
	var height := float(cfg.get("height", 1.75))
	var pitch := deg_to_rad(float(cfg.get("pitch_start_deg", -12.0)))

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await process_frame

	# HUD off: this is a composition and materials question, and the report's
	# HUD findings are already recorded separately.
	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
		stack.append_array(node.get_children())

	var camera := Camera3D.new()
	camera.fov = 70.0
	camera.far = 4000.0
	root.add_child(camera)
	camera.make_current()
	if world.get("_terrain") != null and (world.get("_terrain") as Node).has_method("set_camera"):
		(world.get("_terrain") as Node).call("set_camera", camera)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for site: String in SITES.keys():
		var spec: Array = SITES[site]
		var here := Vector2(float(spec[0]), float(spec[1]))
		var look := Vector2(float(spec[2]), float(spec[3]))
		var bearing := (look - here).normalized()

		var ground := _ground(world, here)
		var look_ground := _ground(world, look)
		# The rig sits BEHIND the body along the look bearing, lifted by the
		# camera height plus whatever the start pitch raises the arm's end.
		var back := here - bearing * distance * cos(pitch)
		var eye := Vector3(back.x, ground + height - distance * sin(pitch), back.y)
		var aim := Vector3(look.x, look_ground + 1.0, look.y)

		camera.global_position = eye
		camera.look_at(aim)
		for i in SHOT_SETTLE_FRAMES:
			await process_frame
		var image := root.get_texture().get_image()
		image.save_png("%s/%s.png" % [OUT, site])
		print("shot %-20s eye (%.1f, %.2f, %.1f) ground %.2f -> %s.png" % [
			site, eye.x, eye.y, eye.z, ground, site])

	print("done: %d frames in %s" % [SITES.size(), OUT])
	quit(0)


## Whatever in the tree answers `ground_height_at`, the same duck-typed lookup
## every other world script in this repo uses.
func _ground(world: Node, at: Vector2) -> float:
	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node.has_method("ground_height_at"):
			return float(node.call("ground_height_at", at.x, at.y))
		stack.append_array(node.get_children())
	return 0.0
