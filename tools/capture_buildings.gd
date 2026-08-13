extends SceneTree

## Frames of the built structures — the farmhouse, the workshop, the
## cottages, the well, the square — for the settlement's visual passes
## (R9.4 originally; reframed for EV6's Medieval Village rebuild).
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_buildings.gd
##
## WHY THIS EXISTS. The owner named buildings as one of the two weak points
## going into R9.4, and nothing in tools/ frames them. survey.gd shoots five
## fixed exploration viewpoints and judges composition; capture_site_shots.gd
## stages the download page and picks its framings to flatter; and
## capture_wayfinding.gd is about the signpost and the distant stronghold.
## None of them puts a barn in the middle of the frame at the distance a
## player actually walks past it, which is the only way to find out whether
## the Quaternius farm pack holds up against the Palworld bar the rubric
## sets.
##
## Every eye here is at or near 1.7m — standing height for the 1.80m trainer
## — because a building judged from a drone is a building judged wrong. The
## two exceptions are labelled.
##
## The interior frame is deliberately included: R7.2 dressed the ground floor
## past "undressed grey box" and that work has never been through a blind
## critic.
##
## Same honest limits as tools/survey.gd: Compatibility renderer
## (docs/decisions/D06), software rendering, so composition, silhouette,
## proportion and colour relationships are trustworthy here and fine lighting
## judgements are not.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/buildings"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const FOV := 70.0

## Kept in sync by hand with data/config/village.json and playground_world.gd's
## HOUSE_AT, the same way capture_wayfinding.gd keeps its two constants — a
## survey tool has no business importing gameplay scripts' private state.
const HOUSE_AT := Vector2(-22.0, -16.0)
const WELL_AT := Vector2(10.0, -10.0)
const WORKSHOP_AT := Vector2(2.0, 2.0)
const COTTAGE_A_AT := Vector2(18.0, -2.0)
const COTTAGE_B_AT := Vector2(21.0, -14.0)

const VIEWPOINTS := [
	{
		# The farmhouse from the yard, off-axis so the roof pitch and the
		# doorway wall are both in frame. This is the first building any
		# player sees and the one they see most. After EV6 it is also the
		# family test: does the procedural house still belong beside the
		# Medieval Village kit, or does it read as a fourth vernacular?
		"name": "01-farmhouse-from-yard",
		"eye": Vector2(-8.0, -24.0), "eye_h": 1.7,
		"target": HOUSE_AT, "target_h": 3.0,
	},
	{
		# The walk the opening actually makes: out of the door, east toward
		# the square. Tests whether the house and the settlement read as one
		# place or as two unrelated asset drops.
		"name": "02-house-to-square",
		"eye": Vector2(-11.0, -15.0), "eye_h": 1.7,
		"target": WELL_AT, "target_h": 2.0,
	},
	{
		# Standing at the well, looking at the workshop. Eye height, the
		# distance you stand at when an NPC is talking to you. The open arch
		# bay and the EV7 work_area cluster should read as one working yard.
		"name": "03-square-at-the-well",
		"eye": Vector2(12.0, -14.0), "eye_h": 1.7,
		"target": WORKSHOP_AT, "target_h": 3.5,
	},
	{
		# The settlement's east side read as a group — both cottages and the
		# workshop in one frame. Clustering vs. scatter is rubric criterion 3
		# and it cannot be judged one building at a time.
		"name": "04-cottage-cluster",
		"eye": Vector2(24.0, -22.0), "eye_h": 2.2,
		"target": Vector2(9.0, -3.0), "target_h": 3.0,
	},
	{
		# The composed well at conversation distance. It replaced the old
		# third-outlier pantile well AND the windmill as the square's marker;
		# a curb, two posts and a tile canopy have to read as "well", not
		# "shrine", from exactly this range.
		"name": "05-well-close",
		"eye": Vector2(14.5, -14.0), "eye_h": 1.6,
		"target": WELL_AT, "target_h": 1.8,
	},
	{
		# cottage_a's gable front — door, window, corner timbers, border
		# skirt — at the range a player walks past it.
		# Eye moved off (13,-7.5): that spot is the signpost's own footing
		# (SIGNPOST_AT is 13.5,-7) and the first render was a close-up of its
		# post with the cottage behind it.
		# Second move: (11.8,-9.5) still put the signpost dead on the eye-to-
		# cottage line; from further east the post falls out of the lane.
		"name": "08-cottage-front",
		"eye": Vector2(16.5, -8.5), "eye_h": 1.7,
		"target": COTTAGE_A_AT, "target_h": 2.5,
	},
	{
		# The whole settlement at the range you first see it from, walking in
		# from the practice meadow. Slightly raised (4m) on purpose: this is
		# the one frame here that asks "does this read as a village?" rather
		# than "does this building hold up?".
		"name": "06-settlement-approach",
		"eye": Vector2(34.0, -48.0), "eye_h": 4.0,
		"target": Vector2(12.0, -8.0), "target_h": 3.0,
	},
	{
		# Inside the farmhouse ground floor, looking at where Grandpa stands.
		# R7.2's interior dressing has never faced a blind critic. Eye height
		# and target are derived from the house's own markers below, because
		# the interior is small enough that a hand-typed world coordinate
		# lands inside a wall.
		"name": "07-farmhouse-interior",
		"eye": Vector2.ZERO, "eye_h": 0.0,
		"target": Vector2.ZERO, "target_h": 0.0,
		"from_markers": ["door", "grandpa"],
	},
	{
		# The same room looking the OTHER way — the east (door) wall and the
		# furniture against it (the wardrobe corner, the gear table). Frame 07
		# stands near the door looking at Grandpa, so everything on this wall
		# was behind the camera in every interior pass; the furniture fix's
		# blind critic saw this corner only by accident. EV6-remainder-polish.
		"name": "09-interior-east-wall",
		"eye": Vector2.ZERO, "eye_h": 0.0,
		"target": Vector2.ZERO, "target_h": 0.0,
		"from_markers": ["grandpa", "door"],
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
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var field: RefCounted = HEIGHTFIELD.new()

	if look != null:
		look.call("apply_time", "day")

	# The house node, for the interior frame's markers. Found by type rather
	# than by a node path, because playground_world.gd builds it at runtime
	# and the name is not part of any contract.
	var house: Node3D = _find_house(world)
	if house == null:
		print("NOTE: no house node found; the interior frame will be skipped")

	# Park the player far below the first eye, the same way survey.gd and
	# capture_wayfinding.gd do — straight down from a real XZ keeps it inside
	# the region Terrain3D is streaming.
	if player != null:
		var park: Vector2 = VIEWPOINTS[0]["eye"]
		player.global_position = Vector3(park.x, field.height_at(park.x, park.y) - 500.0, park.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	var written: Array[String] = []
	var failures: Array[String] = []

	for entry: Variant in VIEWPOINTS:
		var view: Dictionary = entry
		var name: String = str(view["name"])

		var eye: Vector3
		var target: Vector3

		if view.has("from_markers"):
			if house == null:
				print("  %-26s -> skipped (no house)" % name)
				continue
			var keys: Array = view["from_markers"]
			# Stand back from the door marker, at eye height, looking at where
			# Grandpa waits. The 0.9 lerp pulls the eye off the doorway itself
			# so the frame shows the room rather than the frame of the door.
			var door: Vector3 = house.call("marker", str(keys[0]))
			var subject: Vector3 = house.call("marker", str(keys[1]))
			eye = door.lerp(subject, 0.35) + Vector3(0, 1.6, 0)
			target = subject + Vector3(0, 1.2, 0)
		else:
			var eye_xz: Vector2 = view["eye"]
			var target_xz: Vector2 = view["target"]
			eye = Vector3(eye_xz.x, field.height_at(eye_xz.x, eye_xz.y) + float(view["eye_h"]), eye_xz.y)
			target = Vector3(
				target_xz.x,
				field.height_at(target_xz.x, target_xz.y) + float(view["target_h"]),
				target_xz.y)

		camera.global_position = eye
		camera.look_at(target, Vector3.UP)

		for i in 20:
			await physics_frame
		for i in POSE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw

		var image := root.get_texture().get_image()
		if image == null:
			failures.append("%s: viewport returned no image" % name)
			continue

		var path := "%s/%s.png" % [OUT_DIR, name]
		var error := image.save_png(path)
		if error != OK:
			failures.append("%s: save_png failed (%d)" % [name, error])
			continue

		written.append(path)
		print("  %-26s -> %s" % [name, path])

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")

	if not failures.is_empty():
		print("")
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


## The house is built at runtime and its node name is not a contract; find it
## by the one method only it has.
func _find_house(node: Node) -> Node3D:
	if node is Node3D and node.has_method("marker"):
		return node as Node3D
	for child in node.get_children():
		var found := _find_house(child)
		if found != null:
			return found
	return null
