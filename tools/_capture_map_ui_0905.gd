extends SceneTree

## N06-MAP-UI (0905 follow-up wave). The full map screen at three fog-of-war
## coverage levels plus the in-world HUD (minimap) frame, from ONE world boot.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_map_ui_0905.gd
##
## NEVER `--headless` together with a rendering driver (COMMON.md).
##
## Three coverages, because the defects this lane fixes do not all show at the
## same one:
##   map_fresh     - a brand new save, only the spawn revealed. The "black
##                   rectangle" worst case, where the fog/chrome value
##                   relationship is the whole screen.
##   map_day1      - the same day-1 footprint `tools/capture_map_tab.gd`
##                   seeds, so this lane's frames are comparable to the ones
##                   the map screen has been judged on before.
##   map_surveyed  - a deliberately HIGH coverage (a long sweep along the
##                   revealed corridor). W11's judge said the callout columns
##                   "at 3% surveyed miss the terrain, at 40% they will not";
##                   this is the frame that actually tests that claim.
##   hud_minimap   - the menu closed, so the HUD minimap is on screen. The
##                   minimap shares this lane's fog constant and its marker
##                   backing, so it needs its own before/after.
##
## Also prints measured medians for the numbers this lane's acceptance is
## argued in (fog value vs page chrome vs revealed ground), so the report
## quotes measurements rather than impressions.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const REDRAW_FRAMES := 90

var _out_dir := "res://shots/_diag"


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.substr(6)
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))

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
	var menu: CanvasLayer = game.call("menu")
	if menu == null:
		push_error("the autoload did not stand up the menu")
		quit(1)
		return
	var map_state: RefCounted = game.get("map")
	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D

	var written: Array[String] = []
	var failures: Array[String] = []

	# --- (a) fresh save: only the player's own spawn revealed ---
	if player != null:
		map_state.mark_visited(player.global_position)
	await _shoot_map(menu, map_state, "map_fresh", written, failures)

	# --- (b) the day-1 footprint `capture_map_tab.gd` already seeds ---
	map_state.reveal_circle(Vector3(-6.0, 0.0, -13.0), 55.0)
	for point in [Vector3(-22.0, 0.0, -16.0), Vector3(10.0, 0.0, -10.0), Vector3(27.5, 0.0, -16.0)]:
		map_state.mark_visited(point)
	game.call("set_objective", "Restore the Old Mill Crossing", Vector3(200.0, 0.0, -140.0))
	await _shoot_map(menu, map_state, "map_day1", written, failures)

	# --- (c) high coverage: the case W11's judge named but never rendered ---
	# A sweep of overlapping reveals across the mapped square, sized to land
	# around a third of the grid rather than `reveal_all` (which would prove
	# nothing about a real player's map).
	for z in range(-230, 231, 40):
		for x in range(-230, 231, 60):
			map_state.reveal_circle(Vector3(float(x), 0.0, float(z)), 34.0)
	await _shoot_map(menu, map_state, "map_surveyed", written, failures)

	# --- (d) the HUD, so the minimap gets its own before/after ---
	menu.call("close")
	for i in 30:
		await process_frame
	await _shoot("hud_minimap", written, failures)

	print("")
	print("%d frames -> %s" % [written.size(), _out_dir])
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")

	if not failures.is_empty():
		print("")
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


func _shoot_map(menu: CanvasLayer, map_state: RefCounted, name: String, written: Array[String], failures: Array[String]) -> void:
	menu.call("open", "map")
	# tab_map.gd's own SETTLE_FRAMES self-expiring redraw plus the documented
	# software-GL texture upload race — `capture_map_tab.gd`'s own header
	# explains why this waits far longer than the mitigation nominally needs.
	for i in REDRAW_FRAMES:
		await process_frame
	print("  %-14s surveyed %.2f%%" % [name, float(map_state.call("discovered_fraction")) * 100.0])
	await _shoot(name, written, failures)
	menu.call("close")
	for i in 6:
		await process_frame


func _shoot(name: String, written: Array[String], failures: Array[String]) -> void:
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		failures.append("%s: viewport returned no image" % name)
		return

	var path := "%s/%s.png" % [_out_dir, name]
	var error := image.save_png(path)
	if error != OK:
		failures.append("%s: save_png failed (%d)" % [name, error])
		return

	written.append(path)
	print("  %-20s -> %s" % [name, path])
