extends SceneTree

## The full map tab (D33 / spec §6A.12, scripts/ui/tab_map.gd), over live
## gameplay, for the visual critic loop. Owner playtest report: "the larger
## map in the menus shows nothing but black."
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script tools/capture_map_tab.gd
##
## Two frames, both after the SAME modest, realistic day-1 exploration
## footprint (not `reveal_all` — that would prove nothing about what a real
## player sees early on):
##   map_tab_day1.png  - a day-1-sized explored patch around the house/
##                        village, same reveal capture_minimap.gd seeds.
##   map_tab_fresh.png - a brand new save, only the player's own spawn point
##                        revealed. The worst case, and the one most likely
##                        to look like "nothing but black" if the fog is
##                        wrong rather than just honestly mostly-unexplored.

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
	menu.call("open", "map")
	# tab_map.gd's own SETTLE_FRAMES=6 self-expiring redraw exists exactly
	# for a documented software-rendering race (a freshly baked ImageTexture
	# is not guaranteed uploaded to the GPU before the SAME frame samples
	# it, measured as "terrain renders solid white"). The first capture of
	# this tab rendered exactly that white square, still, after 10 frames —
	# so this waits far longer to separate "needs more frames in a uniquely
	# slow sandbox" from "the mitigation does not actually work."
	for i in 90:
		await process_frame
	await _shoot("map_tab_fresh", written, failures)
	menu.call("close")
	for i in 4:
		await process_frame

	# --- (b) a realistic day-1 footprint: house, village, a walk down one
	# road --- same reveal capture_minimap.gd seeds, so the two screens are
	# judged against the same explored area rather than two different ones.
	map_state.reveal_circle(Vector3(-6.0, 0.0, -13.0), 55.0)
	for point in [Vector3(-22.0, 0.0, -16.0), Vector3(10.0, 0.0, -10.0), Vector3(27.5, 0.0, -16.0)]:
		map_state.mark_visited(point)
	game.call("set_objective", "Restore the Old Mill Crossing", Vector3(200.0, 0.0, -140.0))
	menu.call("open", "map")
	for i in 90:
		await process_frame
	await _shoot("map_tab_day1", written, failures)

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
