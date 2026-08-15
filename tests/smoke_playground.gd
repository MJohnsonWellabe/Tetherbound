extends SceneTree

## Runtime smoke check for the M1 playground.
##
##   godot --headless --path . --script tests/smoke_playground.gd
##
## Loads the real main scene, lets physics run, and asserts the things that
## would otherwise only be discovered by launching the game:
##
##   * the Terrain3D extension loaded and the baked data was found
##   * the player was placed ON the ground rather than inside or above it
##   * the player is standing on collision, not falling forever
##
## This is not a unit test and does not live under the `test_*` discovery glob,
## because it boots an entire scene and takes seconds rather than milliseconds.
## It is the closest thing to "does it actually run" that a headless machine
## can produce, and it is the check that would have caught a terrain bake that
## silently produced no collision.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const MAX_DROP := 60.0


func _init() -> void:
	_run()


func _run() -> void:
	var packed: PackedScene = load(SCENE)
	if packed == null:
		print("FAIL: could not load %s" % SCENE)
		quit(1)
		return

	var world: Node = packed.instantiate()
	root.add_child(world)

	# Terrain3D streams regions in over several frames and builds collision
	# after that, so a single frame proves nothing.
	for i in SETTLE_FRAMES:
		await physics_frame

	var failures: Array[String] = []

	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain == null:
		failures.append("no Terrain node: the Terrain3D extension or its baked data is missing")
	else:
		var data: Object = terrain.get("data")
		if data == null:
			failures.append("Terrain3D produced no data object")
		else:
			# get_region_count() is a METHOD. An earlier version of this check
			# read a `region_count` property, got null, skipped the assertion,
			# and reported OK while no terrain was loaded at all. Anything that
			# can silently return null must be range-checked, not truthiness-
			# checked.
			var regions: int = int(data.call("get_region_count"))
			print("regions loaded: %d" % regions)
			if regions <= 0:
				failures.append("terrain loaded zero regions; the bake is missing or empty")

			# Prove the heightfield actually contains the authored shape rather
			# than a flat default.
			var sample_a: float = data.call("get_height", Vector3(40.0, 0.0, 40.0))
			var sample_b: float = data.call("get_height", Vector3(-120.0, 0.0, 130.0))
			print("height samples: %.2f, %.2f" % [sample_a, sample_b])
			if is_nan(sample_a) or is_nan(sample_b):
				failures.append("terrain returned NaN heights")
			elif absf(sample_a - sample_b) < 1.0:
				failures.append("terrain looks flat: two distant samples differ by <1m")

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null:
		failures.append("no Player node in the scene")
	else:
		var pos := player.global_position
		print("player at %.1f, %.1f, %.1f  on_floor=%s  vy=%+.2f" % [
			pos.x, pos.y, pos.z, player.is_on_floor(), player.velocity.y
		])
		if not player.is_on_floor():
			failures.append("player is not on the floor after %d physics frames; " % SETTLE_FRAMES +
				"terrain collision is probably not being generated")
		# The meaningful check is not "is y non-zero" — the spawn pad flattens the
		# origin to roughly zero on purpose, so that heuristic was wrong. What
		# matters is that the player's feet are near the GROUND at their own XZ,
		# and that they have left the scene's placeholder drop height.
		if terrain != null:
			var data_ref: Object = terrain.get("data")
			if data_ref != null:
				var ground: float = data_ref.call("get_height", Vector3(pos.x, 0.0, pos.z))
				print("ground beneath player: %.2f (player %.2f, gap %.2f)" % [ground, pos.y, pos.y - ground])
				# ABOVE the terrain is legal now — the opening stands the player
				# on the farmhouse's loft floor, 4m over the heightfield. What
				# stays illegal is BELOW it (fell through the world) or floating
				# without a floor (is_on_floor is asserted above). The old
				# symmetric 2m band predates buildings.
				if pos.y - ground < -1.0:
					failures.append("player is %.1fm UNDER the terrain surface" % (ground - pos.y))
				elif pos.y - ground > 12.0:
					failures.append("player is %.1fm above the terrain; nothing in the world is that tall to stand on" % (pos.y - ground))
		if pos.y > 30.0:
			failures.append("player never fell from the scene's placeholder height")
		if pos.y < -MAX_DROP:
			failures.append("player fell through the world to y=%.1f" % pos.y)
		if is_nan(pos.y):
			failures.append("player position is NaN")

		var vitals: RefCounted = player.get("vitals")
		if vitals == null:
			failures.append("player has no vitals")
		elif vitals.health <= 0.0:
			failures.append("player died on spawn: the drop height is dealing fall damage")

	failures.append_array(await _the_perf_overlay_reports_numbers(world))
	failures.append_array(await _the_hotbar_heals_a_creature(world))
	failures.append_array(await _the_torch_shows_a_visible_prop_when_lit(world))
	failures.append_array(await _build_open_opens_the_menu_from_the_world(world))

	print("")
	if failures.is_empty():
		print("smoke: OK")
		quit(0)
	else:
		for line in failures:
			print("smoke FAIL: %s" % line)
		quit(1)


## The F3 readout has to produce real numbers, not an empty box.
##
## This exists because the overlay is the instrument three shipped performance
## fixes went without (`SA1`, `SA1-lod`, the shadow-atlas cut, all still
## "on-device confirmation open"). An instrument that silently reports nothing
## is worse than no instrument: it looks like evidence.
##
## The frame times themselves are meaningless here — this is llvmpipe, and
## `D06` is explicit that software rendering cannot measure frame time honestly.
## What is checked is the PLUMBING: that F3 cycles, that the counters are wired,
## and that the render monitors are populated under `gl_compatibility` at all.
func _the_perf_overlay_reports_numbers(world: Node) -> Array[String]:
	var found: Array[String] = []
	var hud: CanvasLayer = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud == null:
		return ["no PlaygroundHUD in the scene"] as Array[String]

	var readout: Label = hud.get_node_or_null(^"Root/DebugReadout") as Label
	if readout == null:
		return ["the HUD has no DebugReadout label"] as Array[String]

	if readout.visible:
		found.append("the debug readout starts visible; it is meant to be behind F3")

	# Drive the real handler rather than poking the level directly, so a
	# rebinding or an early-return in `_input` fails this too.
	var f3 := InputEventKey.new()
	f3.keycode = KEY_F3
	f3.pressed = true
	hud.call("_input", f3)

	if not readout.visible:
		found.append("F3 did not show the debug readout")

	# The text is only rebuilt on the 0.1 s throttle, so give it frames.
	for i in 20:
		await process_frame

	var text := readout.text
	print("")
	print("--- perf overlay ---")
	print(text)

	for token in ["fps", "draw calls", "video mem", "vsync", "3d scale"]:
		if not text.contains(token):
			found.append("the perf readout is missing its '%s' line" % token)

	# The one number that must be non-zero, and the reason this assertion is
	# here at all: if `RENDER_TOTAL_DRAW_CALLS_IN_FRAME` reads 0 under
	# Compatibility then every render counter in the overlay is decorative, and
	# the owner would be reading zeroes off the Ally and drawing conclusions.
	#
	# Only asserted when something is actually being rasterised. Under
	# `--headless` Godot loads the dummy rendering driver, which draws nothing
	# and reports nothing, so a zero there is correct rather than broken. Run
	# this under xvfb with `--rendering-driver opengl3` to exercise the check:
	#
	#   xvfb-run -a godot --path . --rendering-driver opengl3 \
	#     --script tests/smoke_playground.gd
	#
	# which is the same way tools/survey.sh gets a real GL context (D06).
	var draws: float = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var rendering := RenderingServer.get_video_adapter_name() != ""
	print("draw calls this frame: %d  (rendering: %s)" % [int(draws), rendering])
	if not rendering:
		print("headless dummy driver — render counters not asserted")
	elif draws <= 0.0:
		found.append("RENDER_TOTAL_DRAW_CALLS_IN_FRAME reads 0 with a live adapter; " +
			"the render monitors are not populated and the overlay reports nothing")

	# Second press is the FULL level, third returns to hidden.
	hud.call("_input", f3)
	hud.call("_input", f3)
	if readout.visible:
		found.append("F3 did not cycle back to hidden after three presses")

	return found


## OF16: owner-reported "still can't use potions" -- HD2's hotbar quick-use
## path (`playground_hud.gd::_use_hotbar_slot()`) shipped with zero smoke
## coverage, unlike `tab_backpack.gd`'s Use verb, which `smoke_menu.gd`'s
## `_check_backpack_target_picker()` already drives end to end. Re-verified
## both paths against current main by hand before writing this: the backpack
## menu path passes cleanly, and this hotbar path also heals correctly in
## isolation -- no live regression reproduced. This closes the coverage gap
## either way, so a future regression on the untested path fails CI instead
## of surfacing only as another playtest report.
func _the_hotbar_heals_a_creature(world: Node) -> Array[String]:
	var found: Array[String] = []
	var game: Node = world.get_node_or_null(^"/root/Game")
	if game == null:
		return ["no Game autoload; cannot drive the hotbar heal check"] as Array[String]

	var party: RefCounted = game.get("party")
	var inventory: RefCounted = game.get("inventory")
	if party == null or inventory == null:
		return ["Game exposes no party/inventory; cannot drive the hotbar heal check"] as Array[String]

	if int(party.call("size")) == 0:
		var creature: RefCounted = game.call("make_creature", "terrapup")
		if creature == null:
			return ["could not build a creature from species.json"] as Array[String]
		party.call("add", creature)

	var target: RefCounted = party.call("at", 0)
	target.set("hp", 1.0)

	inventory.call("add", "potion_small", 1)
	var slot: int = int(inventory.call("find_slot", "potion_small"))
	if slot < 0 or slot > 4:
		found.append("potion_small landed outside the hotbar's mirrored slots 0-4 (slot %d)" % slot)
		return found

	var hud: CanvasLayer = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud == null:
		return ["no PlaygroundHUD in the scene"] as Array[String]
	# `_refresh_game_ref()` normally runs on the HUD's own poll cadence; force
	# it so the just-added party/inventory refs are live before the press.
	if hud.has_method("_refresh_game_ref"):
		hud.call("_refresh_game_ref")

	var action := "hotbar_%d" % (slot + 1)
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	await process_frame
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
	for i in 4:
		await process_frame

	if float(target.get("hp")) <= 1.0:
		found.append("pressing %s on a heal item did not heal the injured creature via the hotbar" % action)
	if int(inventory.call("count", "potion_small")) != 0:
		found.append("the hotbar heal press did not spend the potion")

	return found


## OF24, owner clarification: "what I was really talking about is one you
## carry around to light the way" -- `scripts/player/torch.gd` had been an
## invisible SpotLight since R0.11, and no test ever would have caught that
## a lit torch drew nothing, because none checked for a visible PROP, only
## the light's own boolean state. Toggles the real torch action (at most
## twice: once to flip it on if it happened to spawn unlit, once more is
## never reached once `is_on()` reads true) and asserts the prop node this
## pass added (`torch.prop_node()`) actually exists and is visible -- a light
## with no prop behind it would pass every check that came before this one.
func _the_torch_shows_a_visible_prop_when_lit(world: Node) -> Array[String]:
	var found: Array[String] = []
	var player: Node = world.get_node_or_null(^"Player")
	if player == null:
		return ["no Player node; cannot check the carried torch"] as Array[String]
	var torch: Node = player.get("torch")
	if torch == null:
		return ["Player has no torch (scripts/player/torch.gd did not attach)"] as Array[String]

	for attempt in 2:
		if bool(torch.call("is_on")):
			break
		Input.action_press(&"torch_toggle")
		await physics_frame
		await physics_frame
		Input.action_release(&"torch_toggle")
		for i in 6:
			await physics_frame

	if not bool(torch.call("is_on")):
		return ["could not get the carried torch lit to check its prop"] as Array[String]

	if not torch.has_method("prop_node"):
		return ["torch.gd exposes no prop_node() accessor for the visible prop"] as Array[String]
	var prop: Node = torch.call("prop_node")
	if prop == null or not is_instance_valid(prop):
		found.append("the torch is lit but carries no visible prop node (a light with nothing to see)")
		return found
	if not (prop as Node3D).visible:
		found.append("the torch is lit but its prop node is not visible")
	else:
		print("torch lit: visible prop '%s' present" % prop.name)

	# Leave the torch off so nothing after this in the run (or a future check
	# added after this one) inherits a torch this check lit.
	if bool(torch.call("is_on")):
		Input.action_press(&"torch_toggle")
		await physics_frame
		await physics_frame
		Input.action_release(&"torch_toggle")
		for i in 4:
			await physics_frame
	return found


## OF24: the hammer hotkey. `build_open` is meant to open the real build menu
## straight from exploration, no trip through the pause menu's Build tab
## first -- `smoke_free_build.gd` already proves the Build-tab door works,
## this proves the world door does too, through the same shared
## `build_menu.gd::get_or_make()` lookup `tab_build.gd` was rewritten to use.
func _build_open_opens_the_menu_from_the_world(world: Node) -> Array[String]:
	var found: Array[String] = []
	var hud: CanvasLayer = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud == null:
		return ["no PlaygroundHUD in the scene"] as Array[String]

	const BUILD_MENU_GROUP := "build_menu"
	for node in get_nodes_in_group(BUILD_MENU_GROUP):
		if node.has_method("is_open") and bool(node.call("is_open")):
			node.call("close")
			await physics_frame

	Input.action_press(&"build_open")
	await physics_frame
	await physics_frame
	Input.action_release(&"build_open")
	for i in 10:
		await physics_frame

	var menu: Node = null
	for node in get_nodes_in_group(BUILD_MENU_GROUP):
		menu = node
		break
	if menu == null or not bool(menu.call("is_open")):
		found.append("pressing build_open in the world did not open the build menu")
		return found
	print("build_open opened the build menu straight from the world")

	# Leave the world how the run found it.
	menu.call("close")
	for i in 5:
		await physics_frame
	return found

