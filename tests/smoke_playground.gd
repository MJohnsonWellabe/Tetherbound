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
const TERRAIN_BAKE_TOLERANCE := 0.35
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const HARVEST_POINT_SCRIPT := preload("res://scripts/world/vegetation_harvest_point.gd")
const HARVEST_NODE_SCRIPT := preload("res://scripts/world/harvest_node.gd")
const FELLED_RESOURCE_SCRIPT := preload("res://scripts/world/felled_resource.gd")


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

			failures.append_array(_relocated_pond_bake_matches_recipe(data))

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
	# Automatic-lighting check FIRST, and deliberately: the prop check right
	# after this one ends by toggling the torch off, which sets torch.gd's
	# own `_manual_override` -- once that latches, `_is_on()` takes the
	# manual branch forever after (by design; see torch.gd's own header on
	# manual "winning over the automatic behaviour until toggled again"),
	# and a night check running after it would see a manually-forced state
	# rather than the automatic one it exists to prove.
	failures.append_array(await _the_torch_lights_itself_automatically_at_night(world))
	failures.append_array(await _the_torch_shows_a_visible_prop_when_lit(world))
	failures.append_array(await _swinging_the_tool_connects_after_walking_up_to_a_tree(world))
	failures.append_array(await _chopping_stands_a_felled_pickup_that_pays_out_on_a_second_gather(world))
	failures.append_array(await _an_authored_tool_gather_reports_the_exact_pickup(world))
	failures.append_array(await _a_full_satchel_gather_still_says_so(world))
	failures.append_array(await _a_swing_plays_the_chop_and_lands_on_its_impact_frame(world))
	failures.append_array(await _build_open_opens_the_menu_from_the_world(world))
	failures.append_array(await _the_recall_prompt_never_overlaps_the_hotbar(world))
	failures.append_array(await _the_berry_farm_can_be_worked(world))

	print("")
	if failures.is_empty():
		print("smoke: OK")
		quit(0)
	else:
		for line in failures:
			print("smoke FAIL: %s" % line)
		quit(1)


## The terrain recipe is not the terrain the player walks on: Terrain3D loads
## committed region resources baked from that recipe. Gate A raised the
## relocated mill/ranger pads after restoring the pond surface, but the first
## repair changed only terrain_playground.json. The live village asks this
## baked data where to stand its buildings, while water.gd asks the analytic
## heightfield where to trim its surface, so stale region files can put a
## building several metres below the water inside a dry mesh cutout. Hold the
## two sources together at both structures' centres and representative corners.
func _relocated_pond_bake_matches_recipe(data: Object) -> Array[String]:
	var found: Array[String] = []
	var field: RefCounted = HEIGHTFIELD.new()
	var samples := {
		"mill centre": Vector2(-382.0, 514.0),
		"mill south-west footprint": Vector2(-385.2, 510.8),
		"mill south-east footprint": Vector2(-378.8, 510.8),
		"mill north-west footprint": Vector2(-385.2, 517.2),
		"mill north-east footprint": Vector2(-378.8, 517.2),
		"ranger centre": Vector2(-350.0, 507.0),
		"ranger south-west footprint": Vector2(-353.2, 504.2),
		"ranger south-east footprint": Vector2(-346.8, 504.2),
		"ranger north-west footprint": Vector2(-353.2, 509.8),
		"ranger north-east footprint": Vector2(-346.8, 509.8),
	}
	for label: String in samples:
		var point: Vector2 = samples[label]
		var intended: float = field.height_at(point.x, point.y)
		var baked: float = float(data.call("get_height", Vector3(point.x, 0.0, point.y)))
		if is_nan(baked):
			found.append("relocated pond bake returned NaN at %s %s" % [label, point])
			continue
		var delta := absf(baked - intended)
		print("pond bake %-30s intended=%7.2f baked=%7.2f delta=%.3f" % [
			label, intended, baked, delta
		])
		if delta > TERRAIN_BAKE_TOLERANCE:
			found.append(
				"relocated pond bake is stale at %s: baked %.2f, recipe %.2f (delta %.2fm)"
				% [label, baked, intended, delta]
			)
	return found


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

	# The bar is assignable now, so this binds the potion explicitly instead of
	# hoping the satchel dropped it into one of the mirrored slots 0-4. That
	# old check was itself a symptom of the mirror: which button healed you
	# depended on bag order, which is exactly what the owner asked to be rid of
	# and what the blind playtest's PT-11 caught rebinding itself underfoot.
	var slot := 0
	if not bool(game.call("assign_hotbar", slot, "potion_small")):
		found.append("assigning potion_small to an action slot was refused")
		return found
	if int(game.call("hotbar_slot_of", "potion_small")) != slot:
		found.append("potion_small did not stay on the slot it was assigned to")
		return found

	# The material rule, checked where a player would actually hit it.
	if bool(game.call("assign_hotbar", 1, "wood")):
		found.append("wood was allowed onto an action slot; raw materials must be refused")
		return found

	# Owner board (docs/reference/owner-board-2026-08-15-systems-and-castle.png,
	# "UI / SYSTEM FIXES CHECKLIST"): "Hotbar: consumables + tools only". An
	# orb (`kind: gear`) is thrown through combat's own throw_aim.gd, never
	# the bar, and `_use_hotbar_slot()` has no branch for `gear` at all -- a
	# hotbar slot would only ever answer "is not something you can use here."
	if bool(game.call("assign_hotbar", 1, "orb_basic")):
		found.append("orb_basic (kind: gear) was allowed onto an action slot; " +
			"only tool/consumable/food may occupy the hotbar")
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
## the light's own boolean state. OW12 (2026-08-16) made the torch a real
## satchel item, `kind: "tool"`, and the light now stays dark unless it is
## the equipped tool -- see torch.gd's own header -- so this granted one and
## equipped it directly (the same shortcut `_the_hotbar_heals_a_creature`
## above takes for its potion) rather than routing through a village
## conversation nothing hands one over from yet. Toggles the real torch
## action (at most twice: once to flip it on if it happened to spawn unlit,
## once more is never reached once `is_on()` reads true) and asserts the
## prop node this pass added (`torch.prop_node()`) actually exists and is
## visible -- a light with no prop behind it would pass every check that
## came before this one.
func _the_torch_shows_a_visible_prop_when_lit(world: Node) -> Array[String]:
	var found: Array[String] = []
	var player: Node = world.get_node_or_null(^"Player")
	if player == null:
		return ["no Player node; cannot check the carried torch"] as Array[String]
	var torch: Node = player.get("torch")
	if torch == null:
		return ["Player has no torch (scripts/player/torch.gd did not attach)"] as Array[String]

	var game: Node = world.get_node_or_null(^"/root/Game")
	if game == null:
		return ["no Game autoload; cannot equip the torch to check it"] as Array[String]
	var inventory: RefCounted = game.get("inventory")
	if inventory == null:
		return ["Game exposes no inventory; cannot equip the torch to check it"] as Array[String]
	inventory.call("add", "torch", 1)
	game.set("equipped_tool", "torch")

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

	# RG22, owner directive: "The torch doesn't go in your hand like a axe
	# does. It should." `torch.gd` used to build its OWN separate copy of
	# this prop, bone-attached to Hips, alongside `tool_hold.gd`'s real
	# in-hand one -- both named "TorchProp", so the check above passed
	# against either one without noticing the duplicate. This is the
	# regression guard: `torch.prop_node()` must be the SAME node
	# `tool_hold.gd` put in the hand, not a second one of its own.
	var hold: Node = player.get("tool_hold")
	if hold != null and hold.has_method("prop_node"):
		var hand_prop: Node = hold.call("prop_node")
		if hand_prop == null or prop != hand_prop:
			found.append("torch.prop_node() (%s) is not the same node tool_hold.gd put in the hand (%s) -- " %
				[prop, hand_prop] + "the torch is building its own separate prop again instead of reaching into the hand")

	# Leave the torch off and unequipped so nothing after this in the run (or a
	# future check added after this one) inherits a torch this check lit.
	if bool(torch.call("is_on")):
		Input.action_press(&"torch_toggle")
		await physics_frame
		await physics_frame
		Input.action_release(&"torch_toggle")
		for i in 4:
			await physics_frame
	game.set("equipped_tool", "")
	return found


## Gate A gathering feedback.  The authored first-day nodes are a separate
## payout path from vegetation's felled_resource.gd pickups.  The latter
## already queued `+X Wood`; the former silently changed the satchel and hid
## their prop.  Exercise a real authored wood node through the live tool swing
## and then read the HUD row that consumes Game's one-shot message queue.  A
## direct queue read would false-pass if the HUD never surfaced it.
func _an_authored_tool_gather_reports_the_exact_pickup(world: Node) -> Array[String]:
	var found: Array[String] = []
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var model := player.get_node_or_null(^"Model") as Node3D if player != null else null
	var hold: Node = player.get("tool_hold") if player != null else null
	var game := world.get_node_or_null(^"/root/Game")
	var hud := world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	var message := hud.get_node_or_null(^"Root/BottomDock/HotbarPanel/Margin/Layout/Message") as Label \
		if hud != null else null
	if player == null or model == null or hold == null or game == null or message == null:
		return ["authored gather feedback is missing Player/Model/ToolHold/Game/HUD message wiring"] as Array[String]

	var authored: Node3D = null
	for node: Node in get_nodes_in_group("harvestable"):
		if node is Node3D and node.get_script() == HARVEST_NODE_SCRIPT \
				and str(node.get("_item_id")) == "wood" \
				and float(node.get("_respawn_left")) <= 0.0:
			authored = node as Node3D
			break
	if authored == null:
		return ["the live world has no authored wood node for pickup-feedback verification"] as Array[String]

	var inventory: RefCounted = game.get("inventory")
	if inventory == null:
		return ["Game exposes no inventory for authored pickup-feedback verification"] as Array[String]
	if int(inventory.call("find_slot", "axe")) < 0:
		inventory.call("add", "axe", 1)
	game.set("equipped_tool", "axe")
	_face_and_stand_near(player, model, authored.global_position, world)
	for i in 6:
		await process_frame

	# Remove a stale toast from an earlier smoke check.  The assertion below
	# reads only what this swing makes the HUD show.
	game.call("take_pending_world_message")
	message.text = ""
	message.visible = false
	var before := int(inventory.call("count", "wood"))
	if not bool(hold.call("swing")):
		return ["the equipped axe refused to swing at an authored wood node"] as Array[String]
	# A frame count assumed the pre-PERF-ROG per-frame cost; the interaction
	# arbiter rewrite (main) cut that from ~20ms to ~0.024ms, so headless
	# frames now advance far more real seconds per await than before, and a
	# fixed count no longer reliably covers the swing's own real-time
	# duration. Wait on real elapsed time instead.
	var swing_deadline_ms := Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < swing_deadline_ms:
		await process_frame
		if not bool(hold.call("is_swinging")) and message.visible:
			break
	var credited := int(inventory.call("count", "wood")) - before
	if credited <= 0:
		found.append("the authored wood swing credited no wood")
	else:
		var expected := "+%d Wood" % credited
		if not message.visible:
			found.append("authored wood credited %d but the HUD pickup row stayed hidden" % credited)
		elif message.text != expected:
			found.append("authored wood credited %d but HUD said '%s' instead of '%s'" % [
				credited, message.text, expected])
		else:
			print("authored gather feedback: %s" % message.text)
	return found


## INTERACT-SWEEP-0903. `harvest_node.gd`/`key_pickup.gd`/`felled_resource.gd`/
## `farm_plot.gd` each carried a `has_room_for()` refusal whose own comment
## claimed "refused, visibly" while the code beneath it did nothing but
## `return` -- the prompt stayed up, which is not feedback about the press
## that was just made, it is the absence of any. A player pressing interact
## on a full satchel saw exactly what a dropped press looks like: nothing.
## `item_cache_pickup.gd`/`tm_pickup.gd` already spoke ("Satchel is full.")
## on the identical refusal, so the fix makes the other four match them
## instead of merely asserting they already did.
##
## Proven on `harvest_node.gd`'s own authored berries spot (bare-handed:
## berries carry no `gathered_with`, so this isolates the has_room_for
## refusal from the axe/tool gating `_an_authored_tool_gather_reports_the_
## exact_pickup` above already exercises) with the satchel filled to its
## last slot by hand.
func _a_full_satchel_gather_still_says_so(world: Node) -> Array[String]:
	var found: Array[String] = []
	var game := world.get_node_or_null(^"/root/Game")
	var hud := world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	var message := hud.get_node_or_null(^"Root/BottomDock/HotbarPanel/Margin/Layout/Message") as Label \
		if hud != null else null
	if game == null or message == null:
		return ["full-satchel feedback check is missing Game/HUD message wiring"] as Array[String]
	var inventory: RefCounted = game.get("inventory")
	if inventory == null:
		return ["Game exposes no inventory for full-satchel feedback verification"] as Array[String]

	var berry_node: Node3D = null
	for node: Node in get_nodes_in_group("harvestable"):
		if node is Node3D and node.get_script() == HARVEST_NODE_SCRIPT \
				and str(node.get("_item_id")) == "berries" and is_instance_valid(node):
			berry_node = node as Node3D
			break
	if berry_node == null:
		return ["the live world has no authored berries node for full-satchel verification"] as Array[String]

	# Every catalogued item but the one this check gathers, so filling slots
	# never collides with the thing being tested for room. More ids than any
	# satchel has slots for; already-occupied ids just top off an existing
	# stack rather than opening a new one, so this loop still converges.
	var filler_ids: Array[String] = [
		"coin", "wood", "stone", "fiber", "berry_seeds", "rootstone", "ironwood",
		"potion_large", "field_sigil", "ridge_sigil", "river_sigil", "saddle_frame",
		"saddle", "orb_basic", "orb_greater", "potion_small", "revive", "axe",
		"pickaxe", "hammer", "knife", "hoe", "fishing_rod", "torch",
	]
	for id in filler_ids:
		if bool(inventory.call("is_full")):
			break
		inventory.call("add", id, 1)
	if not bool(inventory.call("is_full")):
		return ["could not fill the satchel for the full-satchel feedback check"] as Array[String]
	if bool(inventory.call("has_room_for", "berries", int(berry_node.call("resource_amount")))):
		return ["satchel reports full but still has room for berries; test fixture is wrong"] as Array[String]

	game.call("take_pending_world_message")
	message.text = ""
	message.visible = false
	var before := int(inventory.call("count", "berries"))
	berry_node.call("gather")
	for i in 6:
		await process_frame

	if int(inventory.call("count", "berries")) != before:
		found.append("a full satchel still accepted a berries gather")
	if not message.visible or message.text != "Satchel is full.":
		found.append(
			"a full-satchel gather press produced no 'Satchel is full.' feedback (text='%s' visible=%s)"
			% [message.text, message.visible])
	else:
		print("full-satchel feedback: %s" % message.text)
	return found


## RG2, owner-reported ROG playtest: "I can pull out a pickaxe and such but I
## can't swing at the stones or trees or anything."
##
## `tool_hold.gd::_resolve_swing()` tests the cone against
## `get_parent().global_transform.basis` -- the Player `CharacterBody3D`
## itself. But the player's rotation lives on `Model`, not on that root:
## `player_controller.gd::_face()` only ever writes `_model.rotation.y`, and
## `combat_manager.gd`'s own placement code says so directly ("the controller
## owns the model's yaw during exploration"). The `CharacterBody3D` never
## rotates from however it spawned, so the swing's hit cone was checking the
## direction the trainer was born facing, not the direction they walked up
## facing -- exactly the "point-blank swings whiff" shape the owner reported.
## `interact` never had this bug because `interaction_arbiter.gd` is pure
## proximity, no facing check at all, which is why the interact prompt kept
## working while the swing silently never did.
##
## Reproduces the real case on an authored tutorial node: the player owns the
## whole tool set, visibly holds the WRONG one, and swings. Nothing may be
## rewarded or damaged until the required tool is actually drawn. The second
## swing equips the right prop and proves the same live hit-window path pays
## the resource and wears exactly that held tool.
func _swinging_the_tool_connects_after_walking_up_to_a_tree(world: Node) -> Array[String]:
	var found: Array[String] = []
	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null:
		return ["no Player node; cannot check the swing"] as Array[String]
	var hold: Node = player.get("tool_hold")
	if hold == null:
		return ["Player has no tool_hold (scripts/player/tool_hold.gd did not attach)"] as Array[String]
	var model: Node3D = player.get_node_or_null(^"Model") as Node3D
	if model == null:
		return ["Player has no Model child; cannot check facing"] as Array[String]

	var game: Node = world.get_node_or_null(^"/root/Game")
	if game == null:
		return ["no Game autoload; cannot equip a tool to check the swing"] as Array[String]
	var inventory: RefCounted = game.get("inventory")
	if inventory == null:
		return ["Game exposes no inventory; cannot equip a tool to check the swing"] as Array[String]
	var items: RefCounted = game.get("items")
	if items == null:
		return ["Game exposes no item database; cannot resolve the required held tool"] as Array[String]

	# This check owns the authored-node route. The chop-then-gather check below
	# independently exercises vegetation's standing/felled route.
	var best: Node3D = null
	var best_distance := INF
	for node: Node in world.get_tree().get_nodes_in_group("harvestable"):
		if not is_instance_valid(node) or not (node is Node3D):
			continue
		if (node.get_script() as Script) != HARVEST_NODE_SCRIPT:
			continue
		var item_id := str(node.get("_item_id"))
		if str(items.call("gathered_with", item_id)).is_empty():
			continue
		var distance := player.global_position.distance_to((node as Node3D).global_position)
		if distance < best_distance:
			best_distance = distance
			best = node
	if best == null:
		return ["no tree/rock harvest point anywhere in the loaded world; cannot check the swing"] as Array[String]

	# Walk the player up to it: 1.5m out, the way a real approach would stop
	# short of the trunk rather than inside it. Only the XZ line to the target
	# moves -- Y is resampled from the terrain so this does not embed the
	# player underground on a slope.
	var target_pos: Vector3 = best.global_position
	var to_target := target_pos - player.global_position
	to_target.y = 0.0
	var approach := to_target.normalized() if to_target.length() > 0.01 else Vector3.FORWARD
	var stand_at: Vector3 = target_pos - approach * 1.5
	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null:
		var data: Object = terrain.get("data")
		if data != null:
			var ground: float = data.call("get_height", Vector3(stand_at.x, 0.0, stand_at.z))
			if not is_nan(ground):
				stand_at.y = ground + 1.0
	player.global_position = stand_at
	player.velocity = Vector3.ZERO
	# The real turn `_face()` performs while walking -- Model only, body left
	# exactly as it spawned. This is the faithful repro of the live bug.
	var facing := approach
	model.rotation.y = atan2(facing.x, facing.z)
	for i in 6:
		await physics_frame

	for tool_id in ["axe", "pickaxe", "knife"]:
		inventory.call("add", tool_id, 1)
	var required_tool := str(items.call("gathered_with", str(best.get("_item_id"))))
	var wrong_tool := "pickaxe" if required_tool != "pickaxe" else "axe"
	game.set("equipped_tool", wrong_tool)
	for i in 4:
		await process_frame

	if hold.call("prop_node") == null:
		return ["the wrong equipped tool has no visible held prop; the swing path is not player-readable"] as Array[String]
	var total_before_wrong := _inventory_item_total(inventory)
	var required_slot := int(inventory.call("find_slot", required_tool))
	var wrong_slot := int(inventory.call("find_slot", wrong_tool))
	var required_durability_before := int(inventory.call("durability_at", required_slot))
	var wrong_durability_before := int(inventory.call("durability_at", wrong_slot))

	if not bool(hold.call("swing")):
		found.append("tool_hold.swing() refused to start with the wrong tool visibly equipped")
		return found
	if float(model.get("_tool_swing_for")) <= 0.0:
		found.append("tool_hold.swing() did not trigger the trainer's visible tool-swing animation path")

	# The tool's cooldown is time-based, not frame-based. A fixed number of
	# uncapped headless frames can be shorter than SWING_SECONDS, which leaves
	# this wrong-tool swing active and makes the next, correct swing
	# look falsely refused as an overlap. Wait through the real animation window.
	if not (await _wait_for_tool_swing(hold)):
		return ["the wrong-tool swing never completed; cannot verify the next tool swap"] as Array[String]

	if _inventory_item_total(inventory) != total_before_wrong:
		found.append("holding %s gathered %s even though %s was required" %
			[wrong_tool, str(best.get("_item_id")), required_tool])
	if int(inventory.call("durability_at", required_slot)) != required_durability_before:
		found.append("the hidden %s lost durability during a visible %s swing" % [required_tool, wrong_tool])
	if int(inventory.call("durability_at", wrong_slot)) != wrong_durability_before:
		found.append("the wrong held %s lost durability on a refused hit" % wrong_tool)

	game.set("equipped_tool", required_tool)
	for i in 4:
		await process_frame
	if hold.call("prop_node") == null:
		return ["the required equipped %s has no visible held prop" % required_tool] as Array[String]
	var total_before_correct := _inventory_item_total(inventory)
	var durability_before_correct := int(inventory.call("durability_at", required_slot))
	if not bool(hold.call("swing")):
		return ["tool_hold.swing() refused the correct visibly equipped %s" % required_tool] as Array[String]
	if not (await _wait_for_tool_swing(hold)):
		return ["the correct %s swing never completed" % required_tool] as Array[String]
	if _inventory_item_total(inventory) <= total_before_correct:
		found.append("the correctly held %s swing connected to authored %s but granted no reward" %
			[required_tool, str(best.get("_item_id"))])
	if int(inventory.call("durability_at", required_slot)) != durability_before_correct - 1:
		found.append("the correctly held %s did not lose exactly one durability" % required_tool)
	print("equipped-tool gate: %s refused, %s rewarded and wore once" % [wrong_tool, required_tool])

	return found


## OP21-24. The owner played the shipped build and reported that he "still does
## not see a convincing chopping swing", with the axe held wrong. The mechanism
## behind that was not a tuning value: `trainer_model.gd` had no chop role, so a
## tool swing played the THROW clip, and the gather resolved at an arbitrary
## halfway point of a duration that had nothing to do with the visible motion.
##
## Every check here would have passed vacuously on a `clip_for()` fallback, so
## each asserts the specific thing rather than truthiness:
##
##   1. the trainer rig actually carries an authored `chop` -- a re-bake that
##      drops it would otherwise silently fall back to the throw and this whole
##      defect would come back looking fixed;
##   2. a real swing puts the BODY in the chop role, not the throw role;
##   3. the AnimationPlayer is really playing that clip;
##   4. it is not looping -- a one-shot on loop swings forever;
##   5. the gather resolves on the clip's impact frame, not before it. Timed,
##      not asserted structurally: the swing is started and the inventory is
##      read while the axe is still on the way DOWN, which is exactly when the
##      old midpoint resolve would already have paid out.
func _a_swing_plays_the_chop_and_lands_on_its_impact_frame(world: Node) -> Array[String]:
	var found: Array[String] = []
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var game := root.get_node_or_null(^"/root/Game")
	if player == null or game == null:
		return ["no Player/Game; cannot verify the chop swing"] as Array[String]
	var model := player.get_node_or_null(^"Model") as Node3D
	var hold: Node = player.get("tool_hold")
	if model == null or hold == null:
		return ["the player has no Model/ToolHold; the chop cannot be verified"] as Array[String]
	var items: RefCounted = game.get("items")
	var inventory: RefCounted = game.get("inventory")
	if items == null or inventory == null:
		return ["Game exposes no items/inventory; cannot equip a tool for the chop"] as Array[String]

	var anim := model.call("animation_player") as AnimationPlayer
	if anim == null:
		return ["the trainer has no AnimationPlayer"] as Array[String]
	if not anim.has_animation("chop"):
		# Reported and returned rather than folded in with the rest: every check
		# below would pass on the throw fallback, and a green result there is
		# the exact false positive this item is about.
		return ["the trainer rig carries no 'chop' clip -- animate_humanoid.py's " +
			"CLIPS entry never made it into trainer_lod0.glb, so every tool swing " +
			"is playing the throw again"] as Array[String]

	# Same approach the authored-node check above uses: stand at a real harvest
	# point and face it with Model only, because that is what `_face()` turns
	# during a real walk-up and what the swing cone is measured against.
	var best: Node3D = null
	var best_distance := INF
	for node: Node in world.get_tree().get_nodes_in_group("harvestable"):
		if not is_instance_valid(node) or not (node is Node3D):
			continue
		if (node.get_script() as Script) != HARVEST_NODE_SCRIPT:
			continue
		if str(items.call("gathered_with", str(node.get("_item_id")))).is_empty():
			continue
		var distance := player.global_position.distance_to((node as Node3D).global_position)
		if distance < best_distance:
			best_distance = distance
			best = node as Node3D
	if best == null:
		return ["no tool-gated harvest point in the world; cannot time the chop's impact"] as Array[String]

	var to_target := best.global_position - player.global_position
	to_target.y = 0.0
	var approach := to_target.normalized() if to_target.length() > 0.01 else Vector3.FORWARD
	var stand_at: Vector3 = best.global_position - approach * 1.5
	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null:
		var data: Object = terrain.get("data")
		if data != null:
			var ground: float = data.call("get_height", Vector3(stand_at.x, 0.0, stand_at.z))
			if not is_nan(ground):
				stand_at.y = ground + 1.0
	player.global_position = stand_at
	player.velocity = Vector3.ZERO
	model.rotation.y = atan2(approach.x, approach.z)
	for i in 6:
		await physics_frame

	var required_tool := str(items.call("gathered_with", str(best.get("_item_id"))))
	inventory.call("add", required_tool, 1)
	game.set("equipped_tool", required_tool)
	for i in 4:
		await process_frame
	if hold.call("prop_node") == null:
		return ["the equipped %s has no visible held prop; there is nothing to swing" % required_tool] as Array[String]

	var required_slot := int(inventory.call("find_slot", required_tool))
	var durability_before := int(inventory.call("durability_at", required_slot))
	var seconds := float(hold.call("swing_seconds")) if hold.has_method("swing_seconds") else 0.625

	if not bool(hold.call("swing")):
		return ["tool_hold.swing() refused a swing with the %s visibly equipped" % required_tool] as Array[String]
	var started := float(Time.get_ticks_msec())
	# One physics frame, then one process frame: trainer_model.gd picks the
	# role in _physics_process, and _process there re-plays the clip on it.
	# Checked HERE, mid-swing, not after the poll loop below runs to
	# completion -- a first version of this check read role/anim only after
	# waiting for is_swinging() to go false, by which point the swing was
	# already OVER and had reverted to idle, so "does a swing show the chop"
	# was silently answered by the state after the swing rather than during it.
	await physics_frame
	await process_frame

	var role := String(model.call("_role_for_state"))
	if role != "chop":
		found.append("a tool swing put the trainer in the '%s' role, not 'chop' -- " % role +
			"the body is playing some other motion while the axe swings")
	if anim.current_animation != "chop":
		found.append("the trainer is playing '%s' during a tool swing, not the chop clip" %
			anim.current_animation)
	else:
		var clip := anim.get_animation("chop")
		if clip != null and clip.loop_mode != Animation.LOOP_NONE:
			found.append("the chop clip is playing on loop; a one-shot swing that loops " +
				"never returns the body to idle")

	# When the gather actually resolves, as a fraction of the swing. Measured
	# off the required tool's DURABILITY dropping by one -- the same signal the
	# equipped-tool-gate check above already trusts for "did this swing
	# connect" -- polled every frame rather than off `swing_connected`. A
	# GDScript lambda closure captures an outer local BY VALUE at definition
	# time; an assignment made inside the callable does not write back to this
	# function's own variable, so a first version of this check that tried to
	# time the signal that way silently never saw its own connection.
	var connected_at := -1.0
	while bool(hold.call("is_swinging")):
		if connected_at < 0.0 and int(inventory.call("durability_at", required_slot)) != durability_before:
			connected_at = (float(Time.get_ticks_msec()) - started) / 1000.0
		await process_frame
	if connected_at < 0.0 and int(inventory.call("durability_at", required_slot)) != durability_before:
		connected_at = (float(Time.get_ticks_msec()) - started) / 1000.0

	# The hit lands when the axe is IN the wood. `art.json`'s
	# `trainer.tool_swing.impact_fraction` is where that is, and the tolerance
	# below is deliberately tighter than the gap to the old behaviour (0.5, the
	# bare midpoint of the swing) so this check can actually tell the two apart
	# rather than passing on either.
	var impact := 0.6
	if hold.get("_swing_impact_fraction") != null:
		impact = float(hold.get("_swing_impact_fraction"))
	if connected_at < 0.0:
		found.append("the swing never connected to the %s standing 1.5m in front of it" % str(best.name))
	else:
		var fraction := connected_at / maxf(seconds, 0.001)
		print("chop swing: role=%s clip=%s impact at %.2f of %.3fs (want ~%.2f)" % [
			role, anim.current_animation, fraction, seconds, impact])
		if fraction < impact - 0.08:
			found.append("the gather resolved %.2f through the swing but the axe does not " % fraction +
				"reach the wood until %.2f -- the reward lands before the visible hit" % impact)
		elif fraction > impact + 0.20:
			found.append("the gather resolved %.2f through the swing, well past the %.2f " % [fraction, impact] +
				"impact pose -- the hit reads as disconnected from the action")
	return found


## `tool_hold.gd` resolves its impact and ends its cooldown from `_process()`
## using elapsed seconds. Smoke runs headless and uncapped in CI, so frame
## counts are not a valid stand-in for that duration. The extra process frame
## lets ToolHold consume the timer's final elapsed slice before the caller
## asks whether the next action is legal.
##
## The wait is ASKED of the swing rather than hard-coded. It was a flat 0.60s,
## which was 0.15s of margin over the old 0.45s swing and would have gone
## NEGATIVE the moment OP21-24 retimed the swing to the chop clip's own 0.625s
## -- reporting "the swing never completed" for a swing that was simply still
## running. A duration this test does not own is a duration it should read.
func _wait_for_tool_swing(hold: Node) -> bool:
	var seconds := 0.45
	if hold.has_method("swing_seconds"):
		seconds = float(hold.call("swing_seconds"))
	await create_timer(seconds + 0.15).timeout
	await process_frame
	return not bool(hold.call("is_swinging"))


## RG9, owner directive: "You shouldn't be able to gather a standing tree.
## You should have to chop it. Then it becomes downed wood. Then you gather
## that. Same for stone." Chops a real standing point exactly like the check
## above, then confirms two things the unit-level tests cannot: a real
## `felled_resource.gd` pickup actually appears in the live world where the
## tree/rock stood (not just that `vegetation.gd::_felled` gained an entry),
## and a SECOND swing on that pickup is what actually pays the resource into
## the satchel -- the chop itself must not.
func _chopping_stands_a_felled_pickup_that_pays_out_on_a_second_gather(world: Node) -> Array[String]:
	var found: Array[String] = []
	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null:
		return ["no Player node; cannot check chop-then-gather"] as Array[String]
	var hold: Node = player.get("tool_hold")
	var model: Node3D = player.get_node_or_null(^"Model") as Node3D
	if hold == null or model == null:
		return ["Player is missing tool_hold or Model; cannot check chop-then-gather"] as Array[String]
	var game: Node = world.get_node_or_null(^"/root/Game")
	if game == null:
		return ["no Game autoload; cannot check chop-then-gather"] as Array[String]
	var inventory: RefCounted = game.get("inventory")
	if inventory == null:
		return ["Game exposes no inventory; cannot check chop-then-gather"] as Array[String]
	var items: RefCounted = game.get("items")
	if items == null:
		return ["Game exposes no item database; cannot check chop-then-gather"] as Array[String]

	var standing: Node3D = null
	var best_distance := INF
	for node: Node in world.get_tree().get_nodes_in_group("harvestable"):
		if not is_instance_valid(node) or not (node is Node3D):
			continue
		if (node.get_script() as Script) != HARVEST_POINT_SCRIPT:
			continue
		var distance := player.global_position.distance_to((node as Node3D).global_position)
		if distance < best_distance:
			best_distance = distance
			standing = node
	if standing == null:
		return ["no standing tree/rock chop point anywhere in the loaded world"] as Array[String]

	var chop_pos: Vector3 = standing.global_position
	_face_and_stand_near(player, model, chop_pos, world)

	for tool_id in ["axe", "pickaxe", "knife"]:
		inventory.call("add", tool_id, 1)
	var required_tool := str(items.call("gathered_with", str(standing.get("_item_id"))))
	var wrong_tool := "pickaxe" if required_tool != "pickaxe" else "axe"
	var required_slot := int(inventory.call("find_slot", required_tool))
	var wrong_slot := int(inventory.call("find_slot", wrong_tool))
	var required_durability_before := int(inventory.call("durability_at", required_slot))
	var wrong_durability_before := int(inventory.call("durability_at", wrong_slot))
	game.set("equipped_tool", wrong_tool)
	for i in 4:
		await process_frame
	if hold.call("prop_node") == null:
		return ["the wrong vegetation tool %s produced no visible held prop" % wrong_tool] as Array[String]
	if not bool(hold.call("swing")):
		return ["tool_hold.swing() refused the wrong %s before the vegetation gate could be tested" % wrong_tool] as Array[String]
	if not (await _wait_for_tool_swing(hold)):
		return ["the refused vegetation %s swing never completed" % wrong_tool] as Array[String]
	if not is_instance_valid(standing):
		return ["a visible %s swing felled vegetation that requires %s" % [wrong_tool, required_tool]] as Array[String]
	if int(inventory.call("durability_at", required_slot)) != required_durability_before:
		return ["the hidden %s lost durability during a refused vegetation %s swing" % [required_tool, wrong_tool]] as Array[String]
	if int(inventory.call("durability_at", wrong_slot)) != wrong_durability_before:
		return ["the wrong held %s lost durability on refused vegetation" % wrong_tool] as Array[String]

	game.set("equipped_tool", required_tool)
	for i in 4:
		await process_frame
	if hold.call("prop_node") == null:
		return ["vegetation requires %s but equipping it produced no visible held prop" % required_tool] as Array[String]

	if not bool(hold.call("swing")):
		return ["tool_hold.swing() refused the chop with the required %s equipped" % required_tool] as Array[String]
	if not (await _wait_for_tool_swing(hold)):
		return ["the required vegetation %s swing never completed" % required_tool] as Array[String]

	if is_instance_valid(standing):
		return ["chopping the standing point did not remove it -- fell() did not run"] as Array[String]

	var felled: Node3D = null
	for node: Node in world.get_tree().get_nodes_in_group("harvestable"):
		if not is_instance_valid(node) or not (node is Node3D):
			continue
		if (node.get_script() as Script) != FELLED_RESOURCE_SCRIPT:
			continue
		if (node as Node3D).global_position.distance_to(chop_pos) < 3.0:
			felled = node
			break
	if felled == null:
		return ["chopping stood no felled_resource.gd pickup near the chop -- the tree/rock just vanished"] as Array[String]

	var total_before := _inventory_item_total(inventory)
	_face_and_stand_near(player, model, felled.global_position, world)
	for i in 4:
		await process_frame
	if not bool(hold.call("swing")):
		return ["tool_hold.swing() refused to swing at the felled pickup"] as Array[String]
	if not (await _wait_for_tool_swing(hold)):
		return ["the felled pickup swing never completed"] as Array[String]

	var total_after := _inventory_item_total(inventory)
	if total_after <= total_before:
		found.append("swinging at the felled pickup %.2fm from the chop connected to nothing -- " %
			felled.global_position.distance_to(chop_pos) +
			"chop-then-gather stands a pickup but never pays out")
	else:
		print("chop-then-gather: satchel total %d -> %d after gathering the felled pickup" %
			[total_before, total_after])
	return found


## Shared by both chop-then-gather checks above: teleport 1.5m out from
## `target_pos` along the line from the player's current position, resample
## the ground under the new spot, and turn `Model` (not `body`) to face it --
## the exact `_face()` shape a real walk-up leaves the player in.
func _face_and_stand_near(player: CharacterBody3D, model: Node3D, target_pos: Vector3, world: Node) -> void:
	var to_target := target_pos - player.global_position
	to_target.y = 0.0
	var approach := to_target.normalized() if to_target.length() > 0.01 else Vector3.FORWARD
	var stand_at: Vector3 = target_pos - approach * 1.5
	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null:
		var data: Object = terrain.get("data")
		if data != null:
			var ground: float = data.call("get_height", Vector3(stand_at.x, 0.0, stand_at.z))
			if not is_nan(ground):
				stand_at.y = ground + 1.0
	player.global_position = stand_at
	player.velocity = Vector3.ZERO
	model.rotation.y = atan2(approach.x, approach.z)


## Sum of every slot's `n` -- see the call site's own comment for why a raw
## total, not `used_slots()`, is what actually detects "did a gather happen".
func _inventory_item_total(inventory: RefCounted) -> int:
	var total := 0
	for i in int(inventory.call("slot_count")):
		var stack: Dictionary = inventory.call("stack_at", i)
		total += int(stack.get("n", 0))
	return total


## OF18: torch.gd's `_world_look` used to be looked up exactly once, in
## `_ready()` -- the same call frame `player_controller.gd::_ready()` builds
## this node from. `Player` sits before `WorldLook` in every
## playground scene's own node order (meadows_playground.tscn), so that
## one-shot lookup always ran before `world_look.gd::_ready()` had added
## itself to the "day_cycle" group it is found through -- `_world_look`
## cached null forever, and the owner's own requested "torch already there
## at night, no crafting required" fix silently never fired, for the entire
## life of the feature. Found by `tools/capture_torch_night.gd` printing
## identical near-zero luminance for "day", "night, auto" and "night, after
## two manual toggles" alike. This is the smoke check that would have
## caught it at the time: set night, touch NOTHING else BUT equip the torch,
## and the torch must already be lit -- no toggle input anywhere in this
## function.
##
## RG22 added the "BUT equip the torch" half. Owner design (OW12's own
## header, restated by RG22's fix): an unequipped torch is an inert satchel
## row, same as an unequipped axe -- "no crafting required" was never "no
## equip step required". Before RG22, `torch.gd` never actually checked
## equip state at all (a real bug this file's own header names), so this
## check originally passed by accident, against a torch that would light
## itself whether or not it was ever drawn. Equipping first is what makes
## this check test the CORRECT design rather than the old, unintentionally
## permissive one.
func _the_torch_lights_itself_automatically_at_night(world: Node) -> Array[String]:
	var found: Array[String] = []
	var player: Node = world.get_node_or_null(^"Player")
	if player == null:
		return ["no Player node; cannot check the automatic torch"] as Array[String]
	var torch: Node = player.get("torch")
	if torch == null:
		return ["Player has no torch (scripts/player/torch.gd did not attach)"] as Array[String]
	var look: Node = world.get_node_or_null(^"WorldLook")
	if look == null:
		return ["no WorldLook node; cannot check the automatic torch"] as Array[String]
	var game: Node = world.get_node_or_null(^"/root/Game")
	if game == null:
		return ["no Game autoload; cannot equip the torch to check it"] as Array[String]
	var inventory: RefCounted = game.get("inventory")
	if inventory == null:
		return ["Game exposes no inventory; cannot equip the torch to check it"] as Array[String]
	inventory.call("add", "torch", 1)
	game.set("equipped_tool", "torch")

	look.call("apply_time", "night")
	for i in 10:
		await physics_frame
	if not bool(torch.call("is_on")):
		found.append("the equipped torch did not light itself at night with no toggle pressed " +
			"(_world_look likely cached null again -- see torch.gd's _is_on() comment)")

	game.set("equipped_tool", "")

	# Restore day so nothing else in this run inherits a night scene.
	look.call("apply_time", "day")
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


## OF17: owner-reported, twice -- the creature_recall control (drawn by
## `encounter_director.gd::_creature_control_offer()` through PlaygroundHUD's
## shared `Root/Prompt` line) rendered ON TOP of the hotbar instead of beside
## or above it. Root cause, found by measuring `Root/HotbarPanel`'s live
## `get_global_rect()` rather than trusting its authored offsets: it is NOT a
## fixed-height box. Godot never lets a Control's actual size fall below its
## own computed minimum size, offsets or no offsets -- and `Root/HotbarPanel
## /Margin/Layout/Message` (`_show_hotbar_message()`: "repaired, free.", a
## heal readout, "Nobody on the belt yet.", every hotbar-slot response) is
## `visible = false` most of the time but joins the `VBoxContainer` as a real
## row the instant it shows, pushing the panel's minimum -- and therefore its
## actual -- height up by a measured 30px. A static pixel gap tuned against
## the panel's QUIET height (which the previous two fixes for this same
## report both were) still reads as clear in the editor and in a screenshot
## taken between messages, and still closes to a sliver -- or less -- the
## moment a player presses a hotbar slot for real. That is the "renders ON
## TOP of the hotbar" the owner saw a second time.
##
## Fixed by widening `HotbarPanel`'s own offsets another 20px (see that
## node's tscn comment) so the gap survives the message row's growth with
## room to spare, and by this check driving that exact growth for real
## (`hud.call("_show_hotbar_message", ...)`, the genuine call site every
## hotbar response uses) rather than only the two quiet states the first fix
## was screenshotted against.
##
## `_creature_control_offer()`'s label is pulled directly rather than trusted
## off `Root/Prompt`'s live text: `meadows_playground` opens on the
## wake-up-in-bed beat, whose "Get up" offer legitimately outranks the
## creature-control fallback on priority for a fresh world, so reading
## `Root/Prompt` here would assert against an unrelated story prompt instead
## of this one. Assigning the label directly to `Root/Prompt` (the same node
## `_on_prompt_changed` writes in the real game) still measures the actual
## Control the player sees, just decoupled from which offer happens to be
## winning arbitration in this particular boot.
##
## Drives three states: nobody out ("Call out X"), a creature out ("Put X
## away"), and a creature out WHILE the hotbar message row is showing -- the
## combination that actually closes the gap -- asserting the two Controls'
## live rects never intersect in any of them.
##
## Combat is not separately driven here: `HotbarPanel`/`Root/Prompt`'s own
## offsets are not conditioned on `is_fighting` anywhere in playground_hud.gd
## (only hotbar INPUT is gated, per that file's `_read_hotbar_input` header),
## so a fight changes neither rect this check reads -- if the states below
## pass, mid-fight passes too. `smoke_creature_control.gd` already covers the
## mid-fight dismiss/recall REFUSAL itself; duplicating a full encounter here
## would only slow this file down for no new coverage.
func _the_recall_prompt_never_overlaps_the_hotbar(world: Node) -> Array[String]:
	var found: Array[String] = []
	var hud: CanvasLayer = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	var director: Node = world.get_node_or_null(^"EncounterDirector")
	var game: Node = world.get_node_or_null(^"/root/Game")
	if hud == null or director == null or game == null:
		return ["missing PlaygroundHUD/EncounterDirector/Game; " +
			"cannot drive the recall prompt check"] as Array[String]

	var hotbar: Control = hud.find_child("HotbarPanel", true, false) as Control
	var prompt_label: RichTextLabel = hud.find_child("Prompt", true, false) as RichTextLabel
	var message: Label = hud.find_child("Message", true, false) as Label
	if hotbar == null or prompt_label == null or message == null:
		return ["PlaygroundHUD is missing HotbarPanel, Prompt or the hotbar Message row"] \
			as Array[String]

	var party: RefCounted = game.get("party")
	if party == null:
		return ["Game exposes no party; cannot drive the recall prompt check"] as Array[String]
	if int(party.call("size")) == 0:
		var creature: RefCounted = game.call("make_creature", "terrapup")
		if creature == null:
			return ["could not build a creature from species.json"] as Array[String]
		party.call("add", creature)

	var saved_prompt_text := prompt_label.text
	var saved_message_visible := message.visible
	var saved_message_text := message.text

	if director.call("ally_instance") != null:
		director.call("dismiss_active_creature")
	for i in 10:
		await physics_frame
	found.append_array(await _assert_offer_clear_of_hotbar(director, hotbar, prompt_label, "Call out"))

	await director.call("summon_active_creature")
	for i in 20:
		await physics_frame
	found.append_array(await _assert_offer_clear_of_hotbar(director, hotbar, prompt_label, "Put"))

	# The state that actually reproduces OF17: a hotbar response ("repaired,
	# free.", a heal readout, ...) grows the panel by a real, measured amount
	# right while the recall prompt is showing underneath it.
	hud.call("_show_hotbar_message", "Wooden Axe repaired, free.")
	for i in 4:
		await process_frame
	found.append_array(await _assert_offer_clear_of_hotbar(
		director, hotbar, prompt_label, "Put", " (hotbar message showing)"))

	# Leave the world (and the labels this check borrowed) how the run found it.
	director.call("dismiss_active_creature")
	prompt_label.text = saved_prompt_text
	message.visible = saved_message_visible
	message.text = saved_message_text
	return found


func _assert_offer_clear_of_hotbar(
	director: Node, hotbar: Control, prompt_label: RichTextLabel, expect_substring: String,
	context: String = ""
) -> Array[String]:
	var found: Array[String] = []
	var offer: Dictionary = director.call("_creature_control_offer")
	var label := str(offer.get("label", ""))
	print("recall offer%s: '%s'" % [context, label])
	if not label.contains(expect_substring):
		found.append("expected the recall offer to contain '%s', got '%s'%s" %
			[expect_substring, label, context])
		return found

	prompt_label.text = label
	for i in 2:
		await process_frame

	if hotbar.visible and prompt_label.visible:
		var r_hotbar: Rect2 = hotbar.get_global_rect()
		var r_prompt: Rect2 = prompt_label.get_global_rect()
		print("hotbar rect %s   prompt rect %s   intersects=%s%s" %
			[r_hotbar, r_prompt, r_hotbar.intersects(r_prompt), context])
		if r_hotbar.intersects(r_prompt):
			found.append("recall prompt rect %s overlaps the hotbar rect %s%s" %
				[r_prompt, r_hotbar, context])
	return found



## R7.6. The berry farm's whole loop, driven end to end in the real world:
## till a bed with a hoe in the satchel, sow a seed into it, sleep a day, and
## pick berries out of it.
##
## This is the check that would catch what a unit test structurally cannot.
## `tests/test_farming.gd` pins the state machine, but every way this feature
## can be broken while that suite stays green lives out here: beds placed off
## the ground and skipped by the placer, a plot never registering its index
## against `Game.farm_plots`, an interactable that never attaches to the
## arbiter, a model path that loads as the wrong resource type. The scene has
## to actually build the farm and the farm has to actually pay out.
##
## Driven through each plot's own `gather()` -- the single verb both the
## interact prompt and a tool swing route through (`farm_plot.gd`'s header) --
## rather than by simulating a button press, for the same reason
## `_the_hotbar_heals_a_creature` calls the real handler: this is the code
## path both inputs share, so proving it proves both.
func _the_berry_farm_can_be_worked(world: Node) -> Array[String]:
	var found: Array[String] = []
	var game: Node = world.get_node_or_null(^"/root/Game")
	if game == null:
		return ["no Game autoload; cannot drive the farm check"] as Array[String]
	var inventory: RefCounted = game.get("inventory")
	if inventory == null:
		return ["Game exposes no inventory; cannot drive the farm check"] as Array[String]

	var farm: Node3D = world.get_node_or_null(^"BerryFarm") as Node3D
	if farm == null:
		return ["no BerryFarm node in the world; the farm was never placed"] as Array[String]
	var beds := farm.get_children()
	print("")
	print("--- berry farm ---")
	print("beds placed: %d" % beds.size())
	if beds.size() < 2:
		found.append("the farm placed %d beds; farm.json asks for more" % beds.size())
	if beds.is_empty():
		return found

	var bed: Node3D = beds[0] as Node3D
	# Every bed must have found ground. `_place_farm_plots` skips one it
	# cannot stand up, so a farm that quietly lost half its beds to a terrain
	# change shows here as a count, but a bed at a nonsense height would not.
	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.get("data") != null:
		for entry: Node in beds:
			var at: Vector3 = (entry as Node3D).global_position
			var ground: float = (terrain.get("data") as Object).call(
				"get_height", Vector3(at.x, 0.0, at.z))
			if absf(at.y - ground) > 0.5:
				found.append("bed '%s' sits %.2fm off the ground at its own xz" %
					[entry.name, at.y - ground])

	# A bed must offer SOMETHING even with an empty satchel -- a farm that
	# goes silent when the player has nothing is the OF20 failure.
	var interactable: Node3D = bed.get_node_or_null(^"Interactable") as Node3D
	if interactable == null:
		return (found + ["the bed has no Interactable child; it can never be pressed"]) as Array[String]
	for i in 3:
		await process_frame
	var empty_handed := str(interactable.get("label"))
	print("empty-handed label: '%s'" % empty_handed)
	if empty_handed.is_empty():
		found.append("a bed with nothing in the satchel offers no prompt line at all")
	if bool(interactable.get("actionable")):
		found.append("a bed the player cannot work is marked actionable: '%s'" % empty_handed)

	# Till. Needs a working hoe OWNED, not equipped (docs/decisions/D50).
	inventory.call("add", "hoe", 1)
	var hoe_slot: int = int(inventory.call("find_slot", "hoe"))
	var durability_before: int = int(inventory.call("durability_at", hoe_slot))
	bed.call("gather")
	var state_after_till := str(game.call("farm_plot_at", 0).get("state"))
	print("after till: state=%s  hoe durability %d -> %d" %
		[state_after_till, durability_before, int(inventory.call("durability_at", hoe_slot))])
	if state_after_till != "tilled":
		found.append("tilling with a hoe in the satchel left the bed '%s'" % state_after_till)
	if int(inventory.call("durability_at", hoe_slot)) >= durability_before:
		found.append("tilling did not wear the hoe down")

	# Sow. Spends exactly one seed and needs no hoe.
	inventory.call("add", "berry_seeds", 2)
	bed.call("gather")
	var state_after_sow := str(game.call("farm_plot_at", 0).get("state"))
	var seeds_left: int = int(inventory.call("count", "berry_seeds"))
	print("after sow: state=%s  seeds left %d" % [state_after_sow, seeds_left])
	if state_after_sow != "sown":
		found.append("sowing a seed into tilled ground left the bed '%s'" % state_after_sow)
	if seeds_left != 1:
		found.append("sowing one bed spent %d seeds, not 1" % (2 - seeds_left))

	# Not pickable today. This is R7.6's "on a LATER day" in the live world.
	var berries_before: int = int(inventory.call("count", "berries"))
	bed.call("gather")
	if int(inventory.call("count", "berries")) != berries_before:
		found.append("a bed sown this very day paid out berries immediately")

	# Sleep. `camp.gd`'s rest is what calls this in a real playthrough.
	var day_before: int = int(game.get("day"))
	game.call("advance_day")
	for i in 3:
		await process_frame
	var ripe_label := str(interactable.get("label"))
	print("day %d -> %d, label now '%s'" % [day_before, int(game.get("day")), ripe_label])
	if str(game.call("farm_plot_at", 0).get("state")) != "sown":
		found.append("the SAVED state changed on the day rolling over; " +
			"ripening is meant to be recomputed from the day, not written back")

	# Pick. Bare-handed pays the full yield -- berries are not tool-gated.
	bed.call("gather")
	var gained: int = int(inventory.call("count", "berries")) - berries_before
	var state_after_pick := str(game.call("farm_plot_at", 0).get("state"))
	print("after pick: +%d berries, state=%s" % [gained, state_after_pick])
	if gained <= 0:
		found.append("picking a ripe bed paid out no berries at all")
	if state_after_pick != "tilled":
		found.append("a picked bed went to '%s'; D50 says it stays worked soil" %
			state_after_pick)

	return found
