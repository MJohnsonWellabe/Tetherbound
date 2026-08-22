extends SceneTree

## OP21-15 visual evidence: the full map (`scripts/ui/tab_map.gd`) and the
## HUD minimap (`scripts/ui/minimap.gd`), at the ROG Ally's actual handheld
## acceptance resolution (1280x800), not the project's 1920x1080 authoring
## canvas — the owner's "currently unusable" report was specifically about
## reading this screen on a small physical panel, and the project's
## `window/stretch/mode = canvas_items` means a 1920x1080-authored frame
## looks meaningfully roomier than what actually ships to the device.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script tools/capture_map_handheld.gd
##
## Four frames:
##   map_handheld_default.png  - whole-Meadows fit, the tab's own open state.
##   map_handheld_zoomed.png   - RT pressed once; proves the OP21-15 zoom
##                                fix centres/scales on the PLAYER, not the
##                                map's static geometric centre.
##   map_handheld_trails.png   - zoomed near the village/relay road network,
##                                the 52-MAP authored-trails regression case.
##   minimap_handheld.png      - the HUD minimap at the same resolution, to
##                                confirm 14-RG15 movement-up orientation is
##                                unregressed by this pass.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/_diag"
const SETTLE_FRAMES := 240
const RESOLUTION := Vector2i(1280, 800)


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	root.size = RESOLUTION

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
	root.size = RESOLUTION
	for i in 10:
		await process_frame

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

	# A realistic day-1-ish footprint: house, village, a walk down the relay
	# road, so the frame shows real terrain/road/landmark variety rather than
	# either "all black" or "fully revealed."
	map_state.reveal_circle(Vector3(-6.0, 0.0, -13.0), 55.0)
	for point in [Vector3(-22.0, 0.0, -16.0), Vector3(10.0, 0.0, -10.0), Vector3(27.5, 0.0, -16.0), Vector3(150.0, 0.0, 400.0), Vector3(300.0, 0.0, 3200.0)]:
		map_state.mark_visited(point)
	game.call("set_objective", "Restore the Old Mill Crossing", Vector3(200.0, 0.0, -140.0))

	# --- (a) default: whole-Meadows fit, at handheld resolution ---
	menu.call("open", "map")
	for i in 90:
		await process_frame
	await _shoot("map_handheld_default", written, failures)

	# --- (b) zoomed on the player: proves the OP21-15 centring fix ---
	# Drives the tab's OWN state directly (`_zoom`, then `poll()` — the exact
	# function the real per-frame loop calls) rather than simulating a
	# joypad press: `smoke_gate_a_map_cycle.gd` already proves RT/LT and
	# `Input.is_action_just_pressed` wiring end-to-end with real
	# `InputEventJoypadMotion` events; this tool exists to render the
	# RESULT of a zoom step, and a first pass here that used
	# `Input.action_press` silently never flipped `_zoom` at all (the
	# "just pressed" edge did not land inside this script's own frame
	# timing), producing three byte-identical screenshots. Setting `_zoom`
	# and calling the tab's real `poll()` exercises the exact same
	# `_follow_player_if_not_panned()` path a real RT press would, with
	# neither doubt about frame timing nor a hidden second mechanism.
	var bodies: Array = menu.get("_bodies")
	var map_tab: Control = bodies[int(menu.get("_index"))] as Control
	if map_tab != null:
		map_tab.set("_zoom", 4.0)
		for i in 10:
			map_tab.call("poll")
			await process_frame
	await _shoot("map_handheld_zoomed", written, failures)

	# --- (c) authored trails: pan the manual view to the village/relay road
	# network at local zoom (52-MAP's regression case) ---
	if map_tab != null:
		map_tab.set("_manual_pan", true)
		map_tab.set("_pan_world", map_tab.call("_pan_world_for_player", Vector3(150.0, 0.0, 1800.0)))
		map_tab.call("_clamp_pan")
		var trails_canvas: Control = map_tab.get("_canvas") as Control
		if trails_canvas != null:
			trails_canvas.queue_redraw() # manual state edits bypass poll()'s own redraw triggers
		for i in 4:
			map_tab.call("poll") # _manual_pan is already true, so this will not un-pan
			await process_frame
	await _shoot("map_handheld_trails", written, failures)

	menu.call("close")
	for i in 10:
		await process_frame

	# --- (d) minimap regression check, same resolution ---
	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	var camera := Camera3D.new()
	camera.fov = 70.0
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()
	if player != null:
		var eye_xz := Vector2(player.global_position.x - 9.0, player.global_position.z - 4.0)
		var ground_height: float = world.call("ground_height_at", eye_xz.x, eye_xz.y)
		camera.global_position = Vector3(eye_xz.x, ground_height + 3.4, eye_xz.y)
		camera.look_at(player.global_position + Vector3.UP, Vector3.UP)
	for i in 10:
		await process_frame
	await _shoot("minimap_handheld", written, failures)

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
	print("  %-20s -> %s (%dx%d)" % [name, path, image.get_width(), image.get_height()])
