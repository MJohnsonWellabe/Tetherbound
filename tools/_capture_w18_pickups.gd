extends SceneTree

## W18-DENSITY-B4-B5: fixed frames of the band 4/5 candy tiers in place, at
## normal play distance, for the code-blind judge (docs/AGENT_WORKFLOW.md §7).
## Same shape as tools/_capture_band4_sites.gd -- real frames, no HUD, no
## touch-ups. The camera stands where a walking player's eye would be
## (1.7 m up, 7 m off) and looks at the pickup the loader actually placed
## (`BandPickup_<id>`), so a moved coordinate moves the frame with it.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_capture_w18_pickups.gd
##
## Then: godot --headless --path . --script tools/contact_sheet.gd -- --dir=res://shots/w18_pickups

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT := "res://shots/w18_pickups"
const SETTLE_FRAMES := 240
const EYE_M := 1.7

## name -> [pickup id, distance m, bearing deg (0 = camera stands south of the
## pickup looking north), optional fov]. Three tiers on the same ground (the
## Highfield) so the only thing that differs between the first three frames
## is the tier; then the Rare at normal play distance and the band 5 Rare
## against the Hall.
const SHOTS := {
	"b4-rare-herd-bull-7m": ["b4_candy_herd_bull_highfield", 7.0, 200.0],
	"b4-great-wind-ridge-7m": ["b4_candy_wind_ridge_crest", 7.0, 200.0],
	"b4-good-south-paddock-7m": ["b4_candy_highfield_south_paddock", 7.0, 200.0],
	"b4-rare-herd-bull-12m": ["b4_candy_herd_bull_highfield", 12.0, 160.0],
	"b4-rare-spur-corner-9m": ["b4_candy_watchtower_spur_corner", 9.0, 120.0],
	"b5-rare-doorstep-9m": ["b5_candy_doorstep_alpha", 9.0, 180.0],
}


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await process_frame

	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
		stack.append_array(node.get_children())

	var camera := Camera3D.new()
	camera.fov = 62.0
	camera.far = 2000.0
	root.add_child(camera)
	camera.make_current()
	if world.get("_terrain") != null and (world.get("_terrain") as Node).has_method("set_camera"):
		(world.get("_terrain") as Node).call("set_camera", camera)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var shot := 0
	for name: String in SHOTS.keys():
		var spec: Array = SHOTS[name]
		var pickup := world.get_node_or_null(NodePath("BandPickup_%s" % str(spec[0]))) as Node3D
		if pickup == null:
			print("MISSING pickup %s; frame %s skipped" % [str(spec[0]), name])
			continue
		var target: Vector3 = pickup.global_position + Vector3.UP * 0.35
		var distance := float(spec[1])
		var bearing := deg_to_rad(float(spec[2]))
		var eye := pickup.global_position + Vector3(sin(bearing) * distance, 0.0, cos(bearing) * distance)
		var ground := float(world.call("ground_height_at", eye.x, eye.z))
		if is_nan(ground):
			ground = pickup.global_position.y
		eye.y = ground + EYE_M
		camera.global_position = eye
		camera.look_at(target)
		camera.fov = float(spec[3]) if spec.size() > 3 else 62.0
		# Let the terrain and scatter stream around the new stand before reading.
		for i in 90:
			await process_frame
		var image := root.get_texture().get_image()
		image.save_png("%s/%s.png" % [OUT, name])
		print("shot -> %s.png  (pickup at %s, eye at %s)" % [name, str(pickup.global_position), str(eye)])
		shot += 1

	print("done: %d frames in %s" % [shot, OUT])
	quit(0)
