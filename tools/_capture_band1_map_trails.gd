extends SceneTree

## BAND1-DISCOVERY-0903 evidence: the full map tab (scripts/ui/tab_map.gd)
## after Band 1 (village -> the Rise -> the Pond -> South Bridge) has been
## walked, so `52-MAP-all-authored-trails-visible.md`'s acceptance ("every
## meaningful authored Meadows trail family reaches the map baker" /
## "the owner can navigate the corridor using the map without encountering
## visible ground trails that simply do not exist on it") can be checked by
## eye for this band specifically, at the ROG Ally's own 1280x800.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_band1_map_trails.gd
##
## `map_baker.gd`'s route overlay (`_overlay_authored_routes`) already unions
## `paths.routes`, `paths.approaches`, `spokes.routes`, `crossings`,
## `trail.bands`, `trail.loops` and `trail.shortcuts` into one polyline list
## (`playground_heightfield.gd::road_polylines()`); this capture does not
## exercise a different code path than a real playthrough would, it only
## reveals the fog a real Band 1 walk would have earned by this point in the
## chapter, using the same debug-only `reveal_circle` capture_map_tab.gd
## already relies on for its own "day 1" frame -- at EVERY waypoint of
## `trail.bands[0]` (the real Band 1 spine polyline) and `trail.loops[0]`
## (the Pond Circuit loop), not a handful of hand-picked stands, so
## consecutive circles overlap and the trail reads as one continuous line
## rather than disconnected blobs.
##
## Two frames: the whole-Meadows view (zoom 1, what a player sees by
## default) and a zoomed Band 1 view (the tab's own 8x zoom level, panned
## by teleporting the player to the Pond -- `tab_map.gd::
## _follow_player_if_not_panned()` re-centres on the player itself, the
## same mechanism a real zoomed-in player already relies on) so the
## individual trail segments (the spine's bend at the Rise, the Pond
## Circuit's own loop shape) are legible rather than a few pixels wide.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TERRAIN_CONFIG := "res://data/config/terrain_playground.json"
const OUT_DIR := "res://shots/_diag"
const SETTLE_FRAMES := 240

const REVEAL_RADIUS := 55.0


func _band1_walked_points() -> Array[Vector3]:
	var out: Array[Vector3] = []
	var file := FileAccess.open(TERRAIN_CONFIG, FileAccess.READ)
	if file == null:
		return out
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return out
	var cfg: Dictionary = parsed
	var trail: Dictionary = cfg.get("trail", {})
	for band: Variant in trail.get("bands", []):
		if str((band as Dictionary).get("id", "")) == "band1_lower_meadows":
			for point: Variant in (band as Dictionary).get("points", []):
				out.append(Vector3(float(point[0]), 0.0, float(point[1])))
	for loop: Variant in trail.get("loops", []):
		if str((loop as Dictionary).get("id", "")) == "pond_circuit":
			for point: Variant in (loop as Dictionary).get("points", []):
				out.append(Vector3(float(point[0]), 0.0, float(point[1])))
	# The discovery cache itself, off the spine and off the loop.
	out.append(Vector3(-382.8, 0.0, 355.5))
	return out


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
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D

	var walked := _band1_walked_points()
	if walked.is_empty():
		push_error("band1_lower_meadows / pond_circuit not found in %s" % TERRAIN_CONFIG)
		quit(1)
		return
	for point in walked:
		map_state.reveal_circle(point, REVEAL_RADIUS)
		map_state.mark_visited(point)

	var written: Array[String] = []
	var failures: Array[String] = []

	# --- (a) whole-Meadows view, zoom 1 -- what a player sees by default ---
	menu.call("open", "map")
	# tab_map.gd's own SETTLE_FRAMES=6 self-expiring redraw exists for a
	# documented software-rendering race (a freshly baked ImageTexture is not
	# guaranteed uploaded to the GPU before the same frame samples it) --
	# capture_map_tab.gd waits 90 frames for the same reason; matched here.
	for i in 90:
		await process_frame
	await RenderingServer.frame_post_draw
	await _shoot("band1_map_trails_overview", written, failures)
	menu.call("close")
	for i in 4:
		await process_frame

	# --- (b) zoomed Band 1 view, panned to the Pond by teleporting the
	# player there before opening -- tab_map.gd's own
	# `_follow_player_if_not_panned()` re-centres the view on the player
	# every poll() while zoomed and not manually panned, the same mechanism
	# a real player already relies on to see their own neighbourhood zoomed
	# in; this does not add a second camera/pan mechanism. `state()` in
	# menu_tab.gd is literally `menu.get("game")` -- the Game autoload --
	# and tab_map.gd reads/writes its own remembered zoom as the autoload's
	# plain `map_last_zoom: float` property (autoload/game_state.gd:377), so
	# setting it directly here is the same call the tab's own zoom-in input
	# handler makes, not a second mechanism.
	if player != null:
		player.global_position = Vector3(-320.0, 0.0, 420.0)
	game.set("map_last_zoom", 8.0)
	menu.call("open", "map")
	for i in 90:
		await process_frame
	await RenderingServer.frame_post_draw
	await _shoot("band1_map_trails_zoomed", written, failures)

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
	for i in 4:
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
	print("  %-30s -> %s" % [name, path])
