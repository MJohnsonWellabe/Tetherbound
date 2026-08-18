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
## Reproduces the real case: the player walks up to a harvestable placement
## the way `_face()` actually leaves them (Model turned to face it, body
## untouched), then swings. Equips an axe and pre-owns a pickaxe too, so
## whichever resource is nearest is never refused on tool-gating grounds --
## this check is about the cone connecting, not about yield math already
## covered by test_inventory.gd.
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

	# "harvestable" (harvest_logic.gd::GROUP) is shared with farm_plot.gd,
	# whose own `gather()` tills/sows/picks a bed and needs a hoe -- a real
	# collision with this check's own tool setup below, which owns an axe and
	# a pickaxe but no hoe. Restricted to the two scripts that actually cover
	# "stones or trees" (the owner's own words): vegetation's own scattered
	# points and harvest_node.gd's authored tutorial spots.
	var best: Node3D = null
	var best_distance := INF
	for node: Node in world.get_tree().get_nodes_in_group("harvestable"):
		if not is_instance_valid(node) or not (node is Node3D):
			continue
		var script: Script = node.get_script() as Script
		if script != HARVEST_POINT_SCRIPT and script != HARVEST_NODE_SCRIPT:
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

	inventory.call("add", "axe", 1)
	inventory.call("add", "pickaxe", 1)
	game.set("equipped_tool", "axe")
	for i in 4:
		await process_frame

	# Both tools already owned (not necessarily equipped -- harvest_logic.gd
	# gates yield on ownership, not on which is in hand), so whichever
	# resource `best` actually is, the gather is never refused for the wrong
	# tool -- this check is only about the cone connecting.
	#
	# The total item count across every slot, not `used_slots()`: a fresh
	# game already starts holding wood (62) and stone (18)
	# (`game_state.gd::_starter_kit` or equivalent), so a successful gather of
	# either just tops up an EXISTING stack rather than opening a new slot --
	# `used_slots()` would silently read "no change" on a swing that actually
	# connected and false-failed this check on a build with nothing wrong.
	var total_before := _inventory_item_total(inventory)

	if not bool(hold.call("swing")):
		found.append("tool_hold.swing() refused to start with a tool equipped and nothing else swinging")
		return found

	# The swing resolves at its own midpoint (tool_hold.gd::SWING_SECONDS), so
	# give it real _process frames, not physics frames -- _resolve_swing() runs
	# from _process(), same as the input poll that starts it in real play.
	for i in 30:
		await process_frame
		if not bool(hold.call("is_swinging")):
			break

	var total_after := _inventory_item_total(inventory)
	# A connected gather always changes something observable: the satchel's
	# total item count goes up (a gather never removes anything), or the
	# target is gone outright (HARVEST-ALL's permanent removal). Neither
	# happens on a whiff.
	var gathered := total_after > total_before or not is_instance_valid(best)
	if not gathered:
		found.append("swinging at a harvestable node found %.2fm from the original spawn, " % best_distance +
			"after walking up to face it (Model turned, body untouched -- the real _face() shape), " +
			"connected to nothing -- the cone test is not using the player's real facing")
	else:
		print("swing connected: satchel total %d -> %d, target valid=%s" %
			[total_before, total_after, is_instance_valid(best)])

	return found


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

	inventory.call("add", "axe", 1)
	inventory.call("add", "pickaxe", 1)
	game.set("equipped_tool", "axe")
	for i in 4:
		await process_frame

	if not bool(hold.call("swing")):
		return ["tool_hold.swing() refused the chop with a tool equipped"] as Array[String]
	for i in 30:
		await process_frame
		if not bool(hold.call("is_swinging")):
			break

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
	for i in 30:
		await process_frame
		if not bool(hold.call("is_swinging")):
			break

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
