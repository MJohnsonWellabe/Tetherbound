extends SceneTree

## RG3. Exercises the real exploration HUD and Game menu with raw device
## events, without paying the full Meadows terrain build for a UI contract.
##
##   godot --headless --path . --script tests/smoke_exploration_legend.gd

const HUD_SCENE := preload("res://scenes/ui/playground_hud.tscn")
const ARBITER_SCRIPT := preload("res://scripts/world/interaction_arbiter.gd")
const PLAYGROUND_HUD := preload("res://scripts/ui/playground_hud.gd")

var _failures: Array[String] = []
var _world: Node3D = null
var _hud: CanvasLayer = null
var _arbiter: Node = null
var _legend: Control = null
var _label: RichTextLabel = null
var _prompt: RichTextLabel = null
var _game: Node = null
var _party: RefCounted = null


class _TalkProvider:
	func interaction_offer(_from: Vector3) -> Dictionary:
		return {"label": "Talk to Test", "distance": 1.0, "priority": 5, "actionable": true}
	func interaction_activate() -> void:
		pass


func _init() -> void:
	_run()


func _run() -> void:
	# SceneTree scripts enter _init before project autoloads finish joining root.
	# Yield once before asking for the same Game singleton production uses.
	await process_frame
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_fail("Game autoload is missing")
		_report()
		return
	_party = _game.get("party") as RefCounted
	if _party == null:
		_fail("Game party is missing")
		_report()
		return
	_party.call("clear")

	_world = Node3D.new()
	_world.name = "LegendWorld"
	root.add_child(_world)
	current_scene = _world
	var player := CharacterBody3D.new()
	player.name = "Player"
	_world.add_child(player)
	_arbiter = ARBITER_SCRIPT.new()
	_arbiter.name = "InteractionArbiter"
	_arbiter.set("player_path", NodePath("../Player"))
	_world.add_child(_arbiter)
	_hud = HUD_SCENE.instantiate() as CanvasLayer
	_world.add_child(_hud)
	for i in 5:
		await process_frame

	# OP21-11: the legend moved from `Root/ExplorationLegend` into
	# `Root/BottomDock`, directly under the hotbar — see
	# `playground_hud.gd::_build_exploration_legend`'s own header.
	_legend = _hud.get_node_or_null(^"Root/BottomDock/ExplorationLegend") as Control
	_label = _hud.get_node_or_null(^"Root/BottomDock/ExplorationLegend/Margin/Label") as RichTextLabel
	_prompt = _hud.get_node_or_null(^"Root/BottomDock/Prompt") as RichTextLabel
	if _legend == null or _label == null or _prompt == null:
		_fail("HUD did not build ExplorationLegend under BottomDock, its label, or the contextual prompt")
		_report()
		return

	await _check_action_availability_and_width()
	await _check_live_device_switch()
	await _check_context_prompt_stays_independent()
	await _check_recall_prompt_owns_duplicate()
	await _check_modal_ownership()

	# The bound/order checks in `_check_authored_layout` are the one place
	# this file cares what the real canvas size is. `root.size` set on frame
	# zero (as this used to do, before the harness has actually finished
	# spinning up) does not stick -- headless still reports 64x64 and never
	# reconciles -- and never got caught because the legend's old fixed
	# top-left position happened to sit inside [0,1920]x[0,1080] regardless
	# of how far the aspect="expand" canvas actually extends underneath a
	# too-small window. The relocated, bottom-anchored legend is not that
	# forgiving, so this now sets the size for real: several settle frames
	# first (`smoke_build_menu_footprint.gd`'s own proven order), then the
	# assignment, then several more before trusting any rect it measures.
	for i in 10:
		await process_frame
	root.size = Vector2i(1920, 1080)
	for i in 10:
		await process_frame
	if root.size != Vector2i(1920, 1080):
		_fail("viewport would not take the authored 1920x1080 size (got %s)" % root.size)
		_report()
		return

	_check_authored_layout()
	_report()


## The natural early-game states: no creature before adoption, one usable
## starter, an unusable second slot, and the less-obvious exact cycle case
## where the selected slot is fainted but one different slot is usable.
func _check_action_availability_and_width() -> void:
	if not _legend.visible:
		_fail("exploration legend is not visible in an unowned normal world")
	for expected in ["Map", "Satchel", "Build"]:
		if not _label.text.contains(expected):
			_fail("exploration legend is missing '%s'" % expected)
	for unavailable in ["Call Out", "Put Away", "Change Creature"]:
		if _label.text.contains(unavailable):
			_fail("empty-party legend advertises unavailable '%s'" % unavailable)
	for path in ["keyboard_m.png", "keyboard_i.png"]:
		if not _label.text.contains(path):
			_fail("keyboard legend did not resolve live glyph asset '%s'" % path)
	if _label.text.contains("Talk") or _label.text.contains("Gather") or _label.text.contains("Open"):
		_fail("persistent legend duplicates a contextual world verb")
	var empty_width := _legend.custom_minimum_size.x

	var first: RefCounted = _game.call("make_creature", "terrapup", "Biscuit")
	if first == null or not bool(_party.call("add", first)):
		_fail("could not add the usable starter fixture")
		return
	await _settle_legend()
	if not _label.text.contains("Call Out") or _label.text.contains("Change Creature"):
		_fail("one usable active creature did not show only its actionable Call Out verb")
	var one_width := _legend.custom_minimum_size.x
	if one_width <= empty_width:
		_fail("adding Call Out did not grow the content-fit legend (%.1f <= %.1f)" % [one_width, empty_width])

	var second: RefCounted = _game.call("make_creature", "bramblebun", "Moss")
	if second == null:
		_fail("could not make the alternate creature fixture")
		return
	second.call("take_damage", float(second.get("max_hp")) * 2.0)
	if not bool(_party.call("add", second)):
		_fail("could not add the unavailable alternate fixture")
		return
	await _settle_legend()
	if _label.text.contains("Change Creature"):
		_fail("LB stayed visible when the only different party slot was fainted")

	# Fainting and healing the instances does not move Party.revision. The HUD
	# still has to notice the availability edge, and with slot zero invalid a
	# single usable slot one IS a valid cycle target even though the usable
	# member count is only one.
	first.call("take_damage", float(first.get("max_hp")) * 2.0)
	second.call("heal_fully")
	await _settle_legend()
	if _label.text.contains("Call Out"):
		_fail("Call Out stayed visible for a fainted selected creature")
	if not _label.text.contains("Change Creature"):
		_fail("LB was hidden with one usable alternate to a fainted selected slot")
	if not bool(_party.call("cycle_active", 1)) or int(_party.call("active_index")) != 1:
		_fail("the availability rule disagrees with Party.cycle_active(1)")
	await _settle_legend()
	if not _label.text.contains("Call Out") or _label.text.contains("Change Creature"):
		_fail("cycling onto the sole usable member did not restore the one-creature action set")

	first.call("heal_fully")
	await _settle_legend()
	if not _label.text.contains("Call Out") or not _label.text.contains("Change Creature"):
		_fail("two usable party members did not expose both creature controls")
	var full_width := _legend.custom_minimum_size.x
	if full_width <= one_width:
		_fail("adding Change Creature did not grow the content-fit legend (%.1f <= %.1f)" % [full_width, one_width])
	if full_width > PLAYGROUND_HUD.LEGEND_SIZE.x + 0.5:
		_fail("content-fit legend exceeded its established %.1fpx full-action width" % PLAYGROUND_HUD.LEGEND_SIZE.x)
	if not bool(_party.call("set_resting", 0, true)):
		_fail("could not mark the alternate slot resting")
	await _settle_legend()
	if _label.text.contains("Change Creature"):
		_fail("LB stayed visible when the only different party slot was resting")
	_party.call("set_resting", 0, false)
	await _settle_legend()
	if not _label.text.contains("Change Creature"):
		_fail("LB did not return when the rested alternate became usable")


func _check_live_device_switch() -> void:
	var pad := InputEventJoypadButton.new()
	pad.device = 0
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	Input.parse_input_event(pad)
	for i in 3:
		await process_frame
	for path in ["xbox_button_view.png", "xbox_button_y.png", "xbox_rb.png", "xbox_lb.png"]:
		if not _label.text.contains(path):
			_fail("controller legend did not update to '%s'" % path)

	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = true
	Input.parse_input_event(key)
	for i in 3:
		await process_frame
	if not _label.text.contains("keyboard_m.png") or _label.text.contains("xbox_button_view.png"):
		_fail("legend did not switch back to keyboard presentation after keyboard input")


func _check_context_prompt_stays_independent() -> void:
	var provider := _TalkProvider.new()
	_arbiter.call("register", provider)
	for i in 4:
		await process_frame
	if not _prompt.text.contains("Talk to Test"):
		_fail("contextual interaction prompt no longer renders independently")
	if _label.text.contains("Talk to Test"):
		_fail("contextual interaction leaked into the persistent legend")


func _check_recall_prompt_owns_duplicate() -> void:
	_hud.call("_on_prompt_changed", "Call out Biscuit")
	await _settle_legend()
	if _label.text.contains("Call Out") or _label.text.contains("Put Away"):
		_fail("specific recall prompt did not suppress the legend's duplicate RB verb")
	if not _label.text.contains("Change Creature"):
		_fail("specific recall prompt suppressed the independent LB verb")
	_hud.call("_on_prompt_changed", "")
	await _settle_legend()
	if not _label.text.contains("Call Out"):
		_fail("fallback RB verb did not return when the specific recall prompt cleared")


func _check_modal_ownership() -> void:
	_arbiter.call("set_enabled", false)
	for i in 3:
		await process_frame
	if _legend.visible:
		_fail("story/modal arbiter ownership left the exploration legend visible")
	_arbiter.call("set_enabled", true)
	for i in 3:
		await process_frame
	if not _legend.visible:
		_fail("legend did not return when story/modal ownership ended")

	var game := root.get_node(^"Game")
	var menu: Node = game.call("menu")
	if not bool(menu.call("open", "backpack")):
		_fail("production full-screen menu refused to open in the legend harness")
		return
	for i in 3:
		await process_frame
	if _hud.visible or _legend.is_visible_in_tree():
		_fail("full-screen menu left the exploration legend over its surface")
	menu.call("close")
	for i in 3:
		await process_frame
	if not _hud.visible or not _legend.visible:
		_fail("closing the full-screen menu did not restore the exploration legend")


func _check_authored_layout() -> void:
	var legend_rect := _legend.get_global_rect()
	var content_height := _label.get_content_height()
	var measure := _hud.get(&"_exploration_legend_measure") as RichTextLabel
	if _label.size.y < content_height or _label.size.y < PLAYGROUND_HUD.LEGEND_GLYPH_PX:
		_fail("exploration legend clips its %d px glyph row (label %.1f px, content %.1f px)" % [
			PLAYGROUND_HUD.LEGEND_GLYPH_PX, _label.size.y, content_height,
		])
	if measure == null:
		_fail("exploration legend has no unconstrained content measure")
	else:
		var expected_width := minf(
			measure.get_content_width() + float(_hud.call("_exploration_legend_horizontal_chrome")),
			PLAYGROUND_HUD.LEGEND_SIZE.x)
		if absf(_legend.custom_minimum_size.x - expected_width) > 0.5:
			_fail("legend minimum %.1fpx does not match measured live content %.1fpx" % [
				_legend.custom_minimum_size.x, expected_width,
			])
		if absf(legend_rect.size.x - expected_width) > 0.5:
			_fail("right-aligned legend settled to %.1fpx instead of measured %.1fpx" % [
				legend_rect.size.x, expected_width,
			])
	# BottomDock itself is the legend's own parent now (OP21-11), so it is
	# deliberately not in this overlap set — everything else the legend must
	# still stay clear of.
	for path in [^"Root/Minimap", ^"Root/ObjectiveBlock"]:
		var control := _hud.get_node_or_null(path) as Control
		if control != null and control.visible and legend_rect.intersects(control.get_global_rect()):
			_fail("exploration legend overlaps %s at 1920x1080" % str(control.get_path()))
	if legend_rect.position.x < 0.0 or legend_rect.position.y < 0.0 \
			or legend_rect.end.x > 1920.0 or legend_rect.end.y > 1080.0:
		_fail("exploration legend leaves the authored 1920x1080 safe canvas")

	# OP21-11's literal ask: "should sit under the hotbar." BottomDock is a
	# VBoxContainer, so this is a real layout contract, not a coincidence of
	# one frame's numbers -- the hotbar's bottom edge must sit at or above the
	# legend's top edge, and the legend's own bottom edge at or above the
	# contextual prompt's top edge.
	var hotbar := _hud.get_node_or_null(^"Root/BottomDock/HotbarPanel") as Control
	if hotbar == null:
		_fail("HotbarPanel missing; cannot verify the legend sits under it")
		return
	var hotbar_rect := hotbar.get_global_rect()
	var prompt_rect := _prompt.get_global_rect()
	if legend_rect.position.y < hotbar_rect.end.y - 0.5:
		_fail("exploration legend does not sit under the hotbar (legend top %.1f, hotbar bottom %.1f)" % [
			legend_rect.position.y, hotbar_rect.end.y,
		])
	if prompt_rect.position.y < legend_rect.end.y - 0.5:
		_fail("contextual prompt does not sit under the relocated legend (prompt top %.1f, legend bottom %.1f)" % [
			prompt_rect.position.y, legend_rect.end.y,
		])


func _settle_legend() -> void:
	for _frame in 4:
		await process_frame


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("PASS: exploration legend is persistent, live-glyph driven, modal-safe, and independent of contextual prompts")
		quit(0)
		return
	for failure: String in _failures:
		print("FAIL: %s" % failure)
	quit(1)
