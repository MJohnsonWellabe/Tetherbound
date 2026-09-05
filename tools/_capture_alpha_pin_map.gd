extends SceneTree

## CL-W1 acceptance frame — the full map tab with a live alpha pin on it.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_alpha_pin_map.gd
##
## Nothing here places a marker by hand. The real `AlphaPins` node that
## `playground_world.gd` adds is left to do its own job: the player body is put
## inside the authored radius of Band 2's order 2011 (trailpup, centre
## [-180, 0, 2250]) and the node's own `_process` clock pins it. What the frame
## shows is therefore the feature, not a mock of it.
##
## Fog is revealed along the route a player would have walked to get there,
## because a pin judged against solid black would be judged against nothing.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/_diag"
const SETTLE_FRAMES := 240

const TARGET := Vector3(-180.0, 0.0, 2250.0)
## 120 m short of the cluster centre, on the corridor axis: comfortably inside
## the 300 m radius and not standing on top of the pin, so the marker and the
## player arrow are distinguishable in the frame.
const STAND := Vector3(-180.0, 0.0, 2130.0)


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
	if player == null or map_state == null:
		push_error("no Player body or no MapState to drive")
		quit(1)
		return

	# The route a player takes to reach this alpha, revealed the way walking it
	# would reveal it.
	map_state.reveal_circle(Vector3(-6.0, 0.0, -13.0), 60.0)
	var here := Vector3(-6.0, 0.0, -13.0)
	for step in 60:
		map_state.mark_visited(here.lerp(STAND, float(step + 1) / 60.0))
	map_state.reveal_circle(STAND, 220.0)

	player.global_position = STAND
	# Let the real AlphaPins node's own clock reach a tick (check_interval_s is
	# 0.5 s of accumulated delta, not a frame count — see smoke_alpha_pins.gd).
	var until := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < until:
		await process_frame

	var pinned: int = int(map_state.call("alpha_pin_count"))
	if pinned <= 0:
		push_error("no alpha pinned from %s — nothing to capture" % str(STAND))
		quit(1)
		return
	for pin: Dictionary in (map_state.call("alpha_pins") as Array):
		print("pinned: order %d, '%s' at %s" % [
			int(pin.get("order", 0)), str(pin.get("display_name", "")),
			str(pin.get("position", Vector2.ZERO))])

	var menu: CanvasLayer = game.call("menu")
	if menu == null:
		push_error("the autoload did not stand up the menu")
		quit(1)
		return
	menu.call("open", "map")
	# tab_map.gd's own documented software-rendering upload race: wait long
	# enough that a white square means a real defect, not an unready texture.
	for i in 120:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		push_error("viewport returned no image")
		quit(1)
		return
	var path := "%s/alpha_pin_full_map.png" % OUT_DIR
	var error := image.save_png(path)
	if error != OK:
		push_error("save_png failed (%d)" % error)
		quit(1)
		return
	print("wrote %s at %dx%d with %d pin(s)" % [path, image.get_width(), image.get_height(), pinned])
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")
	quit(0)
