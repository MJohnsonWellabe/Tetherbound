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
## Waited for AFTER the AlphaPins node exists, not instead of waiting for it.
const SETTLE_FRAMES := 120
## `playground_world.gd::_ready()` awaits process frames throughout and only
## reaches its `add_child(ALPHA_PINS.new())` line after `_build_settlement()`,
## which internally builds the village, the trainers, the stronghold and the
## stronghold climax. A fixed frame budget is not a way to wait for that: the
## first run of this file spent 240 physics frames and was still inside
## `_build_settlement()`, so it looked for the node before the world had made
## one and reported "no alpha pinned" for a feature that was working. Wait for
## the NODE.
const READY_TIMEOUT_MS := 2400000

const TARGET := Vector3(-180.0, 0.0, 2250.0)
## 120 m short of the cluster centre, on the corridor axis: comfortably inside
## the 300 m radius, which is what makes the alpha pin itself.
const STAND := Vector3(-180.0, 0.0, 2130.0)
## Where the player stands for the FRAME, once the pin has landed.
##
## The first frame put the player at STAND and the two marks landed on top of
## each other: `tab_map.gd::_draw_player()` runs after the icon pass, and at the
## whole-Meadows fit 120 m is about seven pixels, so the player marker sat
## squarely over the alpha glyph and a blind judge read the pin as a cyan
## teardrop -- the player marker -- rather than the red chevron it is.
##
## Walking back down the corridor separates them by roughly 50 px AND is the
## better evidence: the pin is supposed to stay after the player leaves, so a
## frame taken 850 m away shows the persistence the directive actually asks for.
const VIEW_FROM := Vector3(-180.0, 0.0, 1400.0)


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

	# Wait until the world's own _ready() has reached its alpha-pin hook.
	var pins: Node = null
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while pins == null and Time.get_ticks_msec() < deadline:
		await process_frame
		pins = _find_alpha_pins(world)
	if pins == null:
		push_error("the world never added an AlphaPins node — playground_world.gd's hook line did not run")
		quit(1)
		return
	print("[probe] AlphaPins node appeared after %.1f s of world boot" % [
		(Time.get_ticks_msec() - (deadline - READY_TIMEOUT_MS)) / 1000.0])
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
	for step in 240:
		var along := here.lerp(STAND, float(step + 1) / 240.0)
		map_state.mark_visited(along)
		# A walked corridor is revealed to either side of the walker, not as a
		# one-cell thread; a hairline trail is what made the first frame read as
		# 97% fog with a scratch in it.
		map_state.reveal_circle(along, 90.0)
	map_state.reveal_circle(STAND, 260.0)

	print("[probe] its player_path=%s resolves to %s" % [
		str(pins.get("player_path")), str(pins.get_node_or_null(pins.get("player_path")))])
	print("[probe] clusters loaded: %d" % (pins.get("_clusters") as Array).size())

	# Everything that decides whether `_process` can reach `tick()` at all.
	print("[probe] paused=%s time_scale=%.2f process_mode=%d is_processing=%s can_process=%s" % [
		str(paused), Engine.time_scale, pins.process_mode,
		str(pins.is_processing()), str(pins.can_process())])
	print("[probe] interval_s=%s elapsed_before=%s" % [
		str(pins.get("_interval_s")), str(pins.get("_elapsed"))])

	# Hold the body at the stand point for the whole wait. A one-shot assignment
	# cannot tell "the node never ticked" apart from "something moved the body
	# back", and those want different fixes.
	var until := Time.get_ticks_msec() + 6000
	var frames := 0
	while Time.get_ticks_msec() < until:
		player.global_position = STAND
		await process_frame
		frames += 1
	print("[probe] %d frames held at %s; body ended at %s" % [
		frames, str(STAND), str(player.global_position)])
	# If `_elapsed` moved, `_process` ran and the interval is the question; if it
	# did not, `_process` never fired and the interval is irrelevant.
	print("[probe] elapsed_after=%s (a value that moved means _process ran)" % [
		str(pins.get("_elapsed"))])

	var pinned: int = int(map_state.call("alpha_pin_count"))
	if pinned <= 0:
		# Cross-check: drive the node's own tick() by hand. If THIS pins, the
		# logic is right and the node is simply not being processed; if it does
		# not, the logic itself is wrong in a real world.
		pins.call("tick")
		var after: int = int(map_state.call("alpha_pin_count"))
		print("[probe] a hand-driven tick() pinned %d — so the node's _process %s" % [
			after, "is not running" if after > 0 else "is not the problem"])
		pinned = after
	if pinned <= 0:
		push_error("no alpha pinned from %s — nothing to capture" % str(STAND))
		quit(1)
		return
	for pin: Dictionary in (map_state.call("alpha_pins") as Array):
		print("pinned: order %d, '%s' at %s" % [
			int(pin.get("order", 0)), str(pin.get("display_name", "")),
			str(pin.get("position", Vector2.ZERO))])

	# Walk back out of the radius before the frame. The pin must NOT clear —
	# only the once-flag clears it — so this doubles as a live check that
	# leaving does not unpin, which no test covers from a real world.
	player.global_position = VIEW_FROM
	var settle := Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < settle:
		player.global_position = VIEW_FROM
		await process_frame
	var still: int = int(map_state.call("alpha_pin_count"))
	if still < pinned:
		push_error("the pin cleared when the player walked away — it must survive leaving")
		quit(1)
		return
	print("[probe] %d pin(s) still set from %.0f m away" % [
		still, Vector2(VIEW_FROM.x, VIEW_FROM.z).distance_to(Vector2(TARGET.x, TARGET.z))])

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


## The node `playground_world.gd` adds with `add_child(ALPHA_PINS.new())`, which
## therefore carries an engine-assigned name and can only be found by its script.
func _find_alpha_pins(world: Node) -> Node:
	for child: Node in world.get_children():
		var script: Script = child.get_script() as Script
		if script != null and str(script.resource_path).ends_with("alpha_pins.gd"):
			return child
	return null
