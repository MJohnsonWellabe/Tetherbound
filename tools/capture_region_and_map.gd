extends SceneTree

## Verifies two fixes from the same playtest pass, over live gameplay:
##   1. autoload/map_state.gd + scripts/ui/playground_hud.gd: the owner's
##      "name some of the areas and uncover them like fortnite maps do" --
##      entering a named region should show a location banner.
##   2. scripts/ui/tab_map.gd: the full map tab's terrain rendered solid white
##      no matter how long a capture waited (tools/capture_map_tab.gd, up to
##      90 settle frames) -- root-caused to the FOG overlay texture being
##      rebuilt fresh on every redraw instead of cached like the terrain
##      texture already was, so it kept re-rolling the same "brand new
##      ImageTexture samples as white for one frame" race tab_map.gd's own
##      header already knew about for the terrain. Fixed by caching the fog
##      texture on map_state.revision the same way the terrain is cached.
##      This capture proves both: a real player who has actually explored
##      the village square and Grandpa's Meadow should see them named on the
##      full map, over real (not white) terrain.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script tools/capture_region_and_map.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/_diag"
const SETTLE_FRAMES := 240


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
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var game := root.get_node_or_null(^"/root/Game")
	if game == null:
		push_error("Game autoload not found")
		quit(1)
		return
	var map_state: RefCounted = game.get("map")
	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D

	var written: Array[String] = []
	var failures: Array[String] = []

	# --- (a) region banner: enter Practice Meadow for the first time ---
	#
	# NOT village_square: its centre (10,-10) sits only ~14m from the
	# player's own spawn (0,0), well inside its own 26m discovery radius --
	# so game_state.gd's own periodic map.update_region() call already fires
	# and gets consumed during the SETTLE_FRAMES wait above, before this
	# script ever runs, proving nothing about the banner itself. Practice
	# Meadow's centre (30,-40) is ~50m out, outside every authored region's
	# radius at spawn, so walking the player there is a genuine first entry.
	if player != null:
		player.global_position = Vector3(30.0, player.global_position.y, -40.0)
	map_state.mark_visited(Vector3(30.0, 0.0, -40.0))
	map_state.update_region(Vector3(30.0, 0.0, -40.0))
	for i in 6:
		await process_frame
	await _shoot("region_banner", written, failures)

	# --- (b) full map: a realistic day-1 footprint through two named regions,
	# same reveal capture_map_tab.gd seeds, plus entering Grandpa's Meadow so
	# a second region label has something to draw.
	map_state.reveal_circle(Vector3(-6.0, 0.0, -13.0), 55.0)
	for point in [Vector3(-22.0, 0.0, -16.0), Vector3(10.0, 0.0, -10.0), Vector3(27.5, 0.0, -16.0)]:
		map_state.mark_visited(point)
	map_state.update_region(Vector3(-22.0, 0.0, -16.0))
	game.call("set_objective", "Restore the Old Mill Crossing", Vector3(200.0, 0.0, -140.0))

	var menu: CanvasLayer = game.call("menu")
	if menu == null:
		push_error("the autoload did not stand up the menu")
		quit(1)
		return
	menu.call("open", "map")
	for i in 30:
		await process_frame
	await _shoot("map_tab_regions", written, failures)

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
	for i in 8:
		await process_frame
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
	print("  %-20s -> %s" % [name, path])
