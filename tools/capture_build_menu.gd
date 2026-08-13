extends SceneTree

## D34's Valheim-style build menu and placement feedback (spec 12-13),
## captured the same way `tools/capture_menu_panels.gd` captures the pause
## menu's tabs: real world, real `Game` autoload, real inventory, screenshot.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_build_menu.gd
##
## Four frames:
##   build_menu_structures - the build menu, Structures tab, grid + strip
##   build_menu_furniture  - the same menu, Furniture tab (a second
##                           category, proving the tab switch actually
##                           rebuilds the grid rather than just relabeling)
##   build_placement_grid  - a wall ghost armed and placed in the world, the
##                           local placement grid visible under it
##   build_placement_snap  - a second wall's ghost near the first, close
##                           enough to trigger the neighbour-snap dots

const SCENE := "res://scenes/world/meadows_playground.tscn"
const BUILD_MENU := preload("res://scripts/ui/build_menu.gd")
const OUT_DIR := "res://shots/_diag"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 10


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

	var game := root.get_node_or_null(^"Game")
	if game == null:
		push_error("Game autoload not in the tree")
		quit(1)
		return

	# Re-staged outdoors (owner review: the old frames were shot indoors at
	# the bed — no ghost/grid visible, world blown-out amber). Open ground
	# south of the village reads as ordinary daylight gameplay and gives the
	# ghost/grid plenty of flat, unobstructed terrain to draw over.
	var player_for_teleport := world.get_node_or_null(^"Player") as CharacterBody3D
	if player_for_teleport != null:
		var outdoor_xz := Vector2(10.0, -25.0)
		var outdoor_height: float = world.call("ground_height_at", outdoor_xz.x, outdoor_xz.y)
		player_for_teleport.global_position = Vector3(outdoor_xz.x, outdoor_height + 1.0, outdoor_xz.y)
		player_for_teleport.velocity = Vector3.ZERO
		for i in 40:
			await physics_frame

	var inventory: RefCounted = game.get("inventory")
	if inventory != null:
		inventory.call("add", "wood", 200)
		inventory.call("add", "stone", 200)
		inventory.call("add", "fiber", 200)
		# Just short on one resource so the strip's DANGER-red row actually
		# shows up in the screenshot rather than every row reading SUCCESS.
		inventory.call("remove", "stone", 197)

	var written: Array[String] = []
	var failures: Array[String] = []

	# --- the menu itself, two categories -------------------------------------
	var menu := BUILD_MENU.new()
	root.add_child(menu)
	menu.call("open")
	menu.call("_select_category", 2)  # structures
	for i in POSE_FRAMES:
		await process_frame
	await _shoot("build_menu_structures", written, failures)

	menu.call("_select_category", 3)  # furniture
	for i in POSE_FRAMES:
		await process_frame
	await _shoot("build_menu_furniture", written, failures)

	menu.call("close")
	menu.queue_free()
	for i in 10:
		await process_frame

	# --- placement in the world, grid + one wall already standing -----------
	var placer := world.get_node_or_null(^"BuildPlacer")
	var player := world.get_node_or_null(^"Player") as Node3D
	if placer == null or player == null:
		failures.append("no BuildPlacer or Player in the world")
	else:
		inventory.call("add", "stone", 200)
		game.set("pending_build", "wall")
		for i in POSE_FRAMES * 3:
			await physics_frame
		await _shoot("build_placement_grid", written, failures)

		Input.action_press("build_place")
		await physics_frame
		await physics_frame
		Input.action_release("build_place")
		for i in 15:
			await physics_frame

		# Arm a second wall and aim close to the first so the neighbour-snap
		# dots have something within range to draw.
		game.set("pending_build", "wall")
		var forward: Vector3 = -player.global_transform.basis.z
		var camera_rig := world.get_node_or_null(^"CameraRig")
		if camera_rig != null and camera_rig.has_method("planar_basis"):
			forward = -(camera_rig.call("planar_basis") as Basis).z
		player.global_position += forward * 0.4 + Vector3(0.3, 0.0, 0.0)
		for i in POSE_FRAMES * 3:
			await physics_frame
		await _shoot("build_placement_snap", written, failures)
		game.set("pending_build", "")

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


func _shoot(name: String, written: Array[String], failures: Array[String]) -> void:
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		failures.append("%s: viewport returned no image" % name)
		return

	var path := "%s/%s.png" % [OUT_DIR, name]
	var error := image.save_png(path)
	if error != OK:
		failures.append("%s: save_png failed (%d)" % [name, error])
		return

	written.append(path)
	print("  %-22s -> %s" % [name, path])
