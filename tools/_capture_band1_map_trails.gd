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
## chapter (village -> road gate -> the Rise crest -> the Pond Circuit loop ->
## the Long Field -> the bridge approach -> South Bridge) using the same
## debug-only `reveal_circle` capture_map_tab.gd already relies on for its
## own "day 1" frame, at a wider radius along more of the corridor.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/_diag"
const SETTLE_FRAMES := 240

## A generous walked-corridor reveal along Band 1's own route (arc 0-2400,
## terrain_playground.json / trail.bands[0] and the pond_circuit loop), not a
## reveal_all() cheat -- each point is somewhere the route contract or the
## composition plan actually puts the player, so the revealed shape traces
## the corridor a real first playthrough leaves fogged-in, at a radius wide
## enough that neighbouring trail geometry (the Pond Circuit loop's far leg,
## the Long Field's two groves) is not clipped at the reveal's own edge.
const REVEAL_RADIUS := 90.0
const WALKED_POINTS := [
	Vector3(0.0, 0.0, 0.0),        # village square
	Vector3(9.0, 0.0, 40.0),       # road gate / Gate Meadow
	Vector3(-228.0, 0.0, 331.0),   # the Rise crest (comp3 eye)
	Vector3(-320.0, 0.0, 378.0),   # pond reveal (comp7 eye)
	Vector3(-382.8, 0.0, 355.5),   # the discovery cache (tm_rock_throw)
	Vector3(-387.0, 0.0, 442.0),   # pond arrival (comp5 eye)
	Vector3(-395.0, 0.0, 545.0),   # pond_circuit far leg
	Vector3(-260.0, 0.0, 630.0),   # pond_circuit rejoin leg
	Vector3(-190.0, 0.0, 650.0),   # pond_circuit rejoins the spine
	Vector3(0.0, 0.0, 900.0),      # the Long Field
	Vector3(344.0, 0.0, 935.0),    # the trail camp
	Vector3(0.0, 0.0, 1250.0),     # bridge approach / fence line
	Vector3(9.0, 0.0, 1300.0),     # South Bridge rim
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

	for point in WALKED_POINTS:
		map_state.reveal_circle(point, REVEAL_RADIUS)
		map_state.mark_visited(point)

	menu.call("open", "map")
	# tab_map.gd's own SETTLE_FRAMES=6 self-expiring redraw exists for a
	# documented software-rendering race (a freshly baked ImageTexture is not
	# guaranteed uploaded to the GPU before the same frame samples it) --
	# capture_map_tab.gd waits 90 frames for the same reason; matched here.
	for i in 90:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		push_error("viewport returned no image")
		quit(1)
		return

	var path := "%s/band1_map_trails.png" % OUT_DIR
	var error := image.save_png(path)
	if error != OK:
		push_error("save_png failed (%d)" % error)
		quit(1)
		return

	print("band1_map_trails -> %s" % path)
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")
	quit(0)
