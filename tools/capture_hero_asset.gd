extends SceneTree

## Render an installed hero object from four angles, in the engine that will
## actually draw it.
##
##   xvfb-run -a -s "-screen 0 1280x1280x24" ~/godot-bin/godot --path . \
##     --rendering-driver opengl3 --resolution 1280x1280 \
##     --script tools/capture_hero_asset.gd -- <res://path.glb> <out-stem>
##
## The pipeline's own turntable (tools/art_pipeline/blender/turntable.py) is the
## right tool for JUDGING CANDIDATES — orthographic, one camera for all of them,
## angles named to match the concept crops. This is not that. Blender is not
## installed in every environment this project gets worked in, and more to the
## point a Blender render answers "what did the generator make" while this
## answers a different question: what does the asset look like THROUGH THIS
## GAME'S RENDERER, with gl_compatibility (D01) and the project's own import
## settings applied. Those two answers have come apart before — the pylon's
## baked emission mask looked right everywhere except in Godot, where
## gl_compatibility ignored the mask and flooded the mesh.
##
## Deliberately loads ONE model and no world. The world-booting captures need
## minutes under software GL and have timed out repeatedly on this box; a single
## GLB on a plain backdrop renders in seconds, which is why this exists as its
## own tool rather than as another flag on one of those.

const ANGLES := [
	{"name": "front", "yaw": 0.0},
	{"name": "side", "yaw": 90.0},
	{"name": "back", "yaw": 180.0},
	{"name": "three_quarter", "yaw": 40.0},
]
const PITCH_DEG := 14.0
const SETTLE := 8


func _init() -> void:
	_run()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("usage: --script tools/capture_hero_asset.gd -- <res://model.glb> <out-stem>")
		quit(1)
		return
	var path := args[0]
	var stem := args[1]
	if not ResourceLoader.exists(path):
		print("no such model: %s" % path)
		quit(1)
		return

	var world := Node3D.new()
	root.add_child(world)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("#20242b")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("#8fa3bb")
	e.ambient_light_energy = 1.35
	env.environment = e
	world.add_child(env)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42.0, -35.0, 0.0)
	key.light_energy = 2.1
	world.add_child(key)

	var model := (load(path) as PackedScene).instantiate() as Node3D
	world.add_child(model)

	# Frame from the model's own bounds, so one tool suits a 4m relay and a
	# 15m machine without a per-asset number.
	var bounds := _bounds(model)
	var centre := bounds.get_center()
	var reach: float = maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))

	var camera := Camera3D.new()
	camera.far = maxf(400.0, reach * 12.0)
	world.add_child(camera)
	camera.make_current()

	for entry: Variant in ANGLES:
		var angle: Dictionary = entry
		var yaw := deg_to_rad(float(angle["yaw"]))
		var pitch := deg_to_rad(PITCH_DEG)
		var back := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
		var eye := centre + back * reach * 1.15
		camera.look_at_from_position(eye, centre)
		for i in SETTLE:
			await process_frame
		var out := "res://shots/%s_%s.png" % [stem, str(angle["name"])]
		root.get_viewport().get_texture().get_image().save_png(out)
		print("saved %s" % out)
	quit(0)


func _bounds(node: Node3D) -> AABB:
	var total := AABB()
	var seeded := false
	for child in node.find_children("*", "VisualInstance3D", true, false):
		var visual := child as VisualInstance3D
		var into := node.global_transform.affine_inverse() * visual.global_transform
		var box: AABB = into * visual.get_aabb()
		total = box if not seeded else total.merge(box)
		seeded = true
	return total
