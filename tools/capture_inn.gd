extends SceneTree

## R7.9's own blind-critique render: exterior, doorway approach and interior
## frames of the inn, and nothing else in the settlement.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_inn.gd
##
## Deliberately NOT tools/capture_buildings.gd's whole-settlement survey.
## ralph/NOTES.md's own R7.8 record: a narrowly-scoped visual check is both
## faster to write and immune to the world's coming relocation if the camera
## reads its framing off the actually-placed node's own global_transform
## rather than a hand-typed world coordinate. `village.json`'s `at`/`yaw_deg`
## for the inn are read here only to FIND the placed node by name prefix
## (the same way smoke_traversal.gd's own VILLAGE_DOOR_PREFABS check does);
## every camera position below is derived from that node's live transform and
## its interior's own `bar_position()`, never from a second copy of the
## coordinate.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/inn"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const FOV := 70.0


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

	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var field: RefCounted = HEIGHTFIELD.new()

	var inn := _find_inn(world)
	if inn == null:
		push_error("no placed 'inn_*' node under Village; nothing to shoot")
		quit(1)
		return

	var interior: Node3D = inn.get_node_or_null(^"Interior") as Node3D
	var door_local := Vector3(0.0, 0.0, 5.0) # building_prefabs.json's own inn.door.at
	var door_global: Vector3 = inn.to_global(door_local)
	var bar_global: Vector3 = interior.call("bar_position") if interior != null else inn.global_position

	# Park the player far below the first eye, same as capture_buildings.gd.
	if player != null:
		var park := Vector2(door_global.x, door_global.z)
		player.global_position = Vector3(park.x, field.height_at(park.x, park.y) - 500.0, park.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	var front_offset := Vector3(0, 0, 1).rotated(Vector3.UP, inn.rotation.y)
	var side_offset := Vector3(1, 0, 0).rotated(Vector3.UP, inn.rotation.y)

	var viewpoints: Array[Dictionary] = [
		{
			"name": "01-inn-exterior-front",
			"eye": inn.global_position + front_offset * 14.0 + side_offset * 5.0 + Vector3(0, 1.7, 0),
			"target": inn.global_position + Vector3(0, 3.0, 0),
		},
		{
			"name": "02-inn-exterior-corner",
			"eye": inn.global_position + front_offset * 9.0 - side_offset * 8.0 + Vector3(0, 2.0, 0),
			"target": inn.global_position + Vector3(0, 3.0, 0),
		},
		{
			"name": "03-inn-doorway",
			"eye": door_global + front_offset * 6.0 + Vector3(0, 1.6, 0),
			"target": door_global + Vector3(0, 1.4, 0),
		},
		{
			"name": "04-inn-interior-bar",
			"eye": door_global.lerp(bar_global, 0.35) + Vector3(0, 1.6, 0),
			"target": bar_global + Vector3(0, 1.2, 0),
		},
		{
			# R7.9 round 3: the first two passes of this viewpoint shifted eye
			# AND target by the same side offset, which is a parallel slide,
			# not a turn -- the camera kept looking straight down the
			# bar-to-door axis and never actually turned toward the guest
			# tables sitting off that axis at local x=+-1.5. Framed here in
			# the room's own local space (inn.to_global(), the same seam
			# bar_position()/door_global already use) from near the door,
			# looking back across both tables toward the bar.
			"name": "05-inn-interior-tables",
			"eye": inn.to_global(Vector3(0.0, 1.8, 3.7)),
			"target": inn.to_global(Vector3(0.0, 0.9, 0.3)),
		},
	]

	var written: Array[String] = []
	var failures: Array[String] = []

	for entry: Variant in viewpoints:
		var view: Dictionary = entry
		var name: String = str(view["name"])
		camera.global_position = view["eye"]
		camera.look_at(view["target"], Vector3.UP)

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


## The inn is built at runtime by village.gd from village.json's `structures`
## list; its node name is "inn_<index>", the same naming convention
## smoke_traversal.gd's own VILLAGE_DOOR_PREFABS check relies on.
func _find_inn(world: Node) -> Node3D:
	var village: Node = world.get_node_or_null(^"Village")
	if village == null:
		return null
	for child in village.get_children():
		if (child as Node).name.begins_with("inn_"):
			return child as Node3D
	return null
