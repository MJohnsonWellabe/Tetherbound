extends SceneTree

## OP-0830-1. Frames of the village's new edge, for the mandatory blind-judge
## pass (`ralph/conventions.md`) — new geometry in the world, so a look is not
## enough, and "the collider holds" is not the same claim as "the player can see
## why it holds". Spec §1E is explicit that invisible collision may only SUPPORT
## a visible boundary; these frames are how that half is checked.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_village_boundary.gd
##
## Same honest limits as `tools/survey.gd` and `tools/capture_road_gate.gd`:
## Compatibility renderer (D06), software rendering — composition and silhouette
## are trustworthy, fine lighting judgements are not. And the coordinator's own
## warning for this round: this harness has been seen to render world frames
## with NO grass geometry at all and a haze the build does not have, so check any
## frame for real grass before trusting what it says about the ground.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const BOUNDARY := preload("res://scripts/world/village_boundary.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/T5-OPENING/shots"

const SETTLE_FRAMES := 300
const POSE_FRAMES := 4
const FOV := 70.0

## Read from the same file the fence is built from, so a moved gate moves its
## own frame instead of quietly photographing empty grass.
const SQUARE := Vector2(10.0, -10.0)

const VIEWPOINTS := [
	{
		# The owner's own move: standing in the square and walking out. Due +z
		# was one of the nine bearings that escaped before this
		# (`tools/_probe_village_gate_escape.gd`). Is there now something there,
		# and does it read as the edge of a village rather than as a wall?
		"name": "01-square-looking-north",
		"eye": Vector2(10.0, -12.0), "eye_h": 1.7,
		"target": Vector2(6.0, 24.0), "target_h": 1.0,
	},
	{
		# The approach to the gate along The Rise road, from inside. Does the
		# fence run off both ends of the leaf — the thing SA7's own header
		# claimed and the world did not have?
		"name": "02-gate-approach-from-inside",
		"eye": Vector2(28.0, -14.0), "eye_h": 1.7,
		"target": "gate:RoadGate", "target_h": 1.2,
	},
	{
		# Interaction range, off-axis, so the leaf's face and the fence either
		# side of it are both in frame.
		"name": "03-gate-closeup",
		"eye": Vector2(34.5, -15.5), "eye_h": 1.7,
		"target": "gate:RoadGate", "target_h": 1.0,
	},
	{
		# From outside, looking back: the village as a place with a wall round
		# it, which is what makes the gate mean anything.
		"name": "04-gate-from-outside",
		"eye": Vector2(48.0, -26.0), "eye_h": 1.8,
		"target": "gate:RoadGate", "target_h": 1.2,
	},
	{
		# The key, at the range a player actually spots it from — and it should
		# be wearing the shared pickup highlight the T5-FEEL lane landed for
		# OP-0830-2/3, not relying on its own 18cm silhouette.
		"name": "05-the-key-from-the-road",
		"eye": Vector2(24.0, -14.0), "eye_h": 1.7,
		"target": Vector2(30.7, -15.9), "target_h": 0.3,
	},
	{
		# The other gate, on The Pond road. Two leaves, one lock — a road that
		# met the fence with no gate in it would read as a broken world.
		"name": "06-pond-gate",
		"eye": Vector2(-14.0, 14.0), "eye_h": 1.7,
		"target": "gate:PondGate", "target_h": 1.2,
	},
	{
		# A long stretch with no gate in it, from inside. This is the frame that
		# says whether 250m of fence reads as one built line or as scattered
		# panels.
		"name": "07-the-line-itself",
		"eye": Vector2(-10.0, 8.0), "eye_h": 1.7,
		"target": Vector2(-34.0, 4.0), "target_h": 1.0,
	},
]


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
	if look != null:
		look.call("apply_time", "day")

	var field: RefCounted = HEIGHTFIELD.new()
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if player != null:
		# Out of every frame, the way capture_road_gate.gd parks it.
		player.global_position = Vector3(SQUARE.x, field.height_at(SQUARE.x, SQUARE.y) - 500.0, SQUARE.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	var panels := 0
	var boundary := world.find_child("VillageBoundary", true, false)
	if boundary != null:
		for child: Node in boundary.get_children():
			if str(child.name).begins_with("FencePanel_"):
				panels += 1
	print("village boundary: %d fence panels, %d gates" % [
		panels, boundary.call("gate_positions").size() if boundary != null else 0])

	var written: Array[String] = []
	var failures: Array[String] = []
	for entry: Variant in VIEWPOINTS:
		var view: Dictionary = entry
		var name_key := str(view["name"])
		var eye_xz: Vector2 = view["eye"]
		var target_xz := _resolve(view["target"], world)
		if target_xz == Vector2.INF:
			failures.append("%s: could not resolve target %s" % [name_key, str(view["target"])])
			continue
		var eye := Vector3(eye_xz.x, field.height_at(eye_xz.x, eye_xz.y) + float(view["eye_h"]), eye_xz.y)
		var target := Vector3(target_xz.x,
			field.height_at(target_xz.x, target_xz.y) + float(view["target_h"]), target_xz.y)
		camera.global_position = eye
		camera.look_at(target, Vector3.UP)
		# Re-applied per frame, not once before the loop. Under software
		# rendering a seven-viewpoint pass takes ~8 minutes of wall clock and
		# `day_cycle.gd` keeps running through it: the first run of this tool
		# produced frames 01-03 at midday and 04-06 at sunset, which makes any
		# colour comparison between them meaningless and reads at a glance like
		# the harness haze this file's own header warns about.
		if look != null:
			look.call("apply_time", "day")

		for i in 20:
			await physics_frame
		for i in POSE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw

		var image := root.get_texture().get_image()
		if image == null:
			failures.append("%s: viewport returned no image" % name_key)
			continue
		var path := "%s/%s.png" % [OUT_DIR, name_key]
		var error := image.save_png(path)
		if error != OK:
			failures.append("%s: save_png failed (%d)" % [name_key, error])
			continue
		written.append(path)
		print("  %-30s -> %s" % [name_key, path])

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	print("Software rendering. Frame times from this harness are NOT a performance measurement,")
	print("and this harness has rendered grassless world frames before -- check for real grass.")
	if not failures.is_empty():
		for line: String in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


## A viewpoint target is either a literal (x,z) or "gate:<node name>", looked up
## on the built world so a re-sited gate photographs itself.
func _resolve(target: Variant, world: Node) -> Vector2:
	if target is Vector2:
		return target as Vector2
	var text := str(target)
	if not text.begins_with("gate:"):
		return Vector2.INF
	var node := world.find_child(text.substr(5), true, false) as Node3D
	if node == null:
		return Vector2.INF
	return Vector2(node.global_position.x, node.global_position.z)
