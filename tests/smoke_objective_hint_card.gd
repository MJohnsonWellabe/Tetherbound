extends SceneTree

## OBJECTIVE-HINT-ON-HUD (`HIST-036`, OP23-04 / OP23-09). Does the hint the
## quest log has always carried actually reach the screen, and does the card it
## reaches it on fit where it is put?
##
##   godot --headless --path . --script tests/smoke_objective_hint_card.gd
##
## `quest_log.gd::tracked_hint()` was written, tested and drawn by nothing for
## months, because the obvious home for it -- a second line under the HUD's
## objective block -- does not fit. `tools/_probe_objective_hint_height.gd`
## measured that: at the block's 380px inner width every authored hint wraps to
## four to six lines (212-318px) against 310px of total space between the
## minimap and the bottom dock, before the tracked line above it is counted.
##
## So the hint ships as a centred timed card, and this file is what stops that
## card from becoming the next overlap. It drives the REAL HUD over a REAL
## `Game` at the authoring resolution and measures `get_global_rect()`, not
## authored offsets -- the same distinction `smoke_prompt_hotbar_dock.gd`'s own
## header draws, and for the same reason: a Control forced past its minimum
## size grows its cached rect and never writes that growth back.
##
## The band the card has to live in is bounded by two things that MOVE, which
## is why this is a smoke test and not arithmetic in `test_hud_widgets.gd`:
## the region banner above it, and the bottom dock below it -- a bottom-aligned
## VBox that grows UPWARD as the hotbar's message row appears and the
## contextual prompt wraps. Both of those are driven here, and the card is
## measured against the dock in its tallest state, not its quiet one.

const HUD_SCENE := "res://scenes/ui/playground_hud.tscn"
const PLAYGROUND_HUD := preload("res://scripts/ui/playground_hud.gd")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const PROGRESSION := preload("res://autoload/progression_state.gd")
const SETTLE := 8

## The same wrapping prompt `smoke_prompt_hotbar_dock.gd` uses to push the dock
## into its tallest state. Copied rather than shared because that file is a
## standalone SceneTree script with no importable surface, and a constant that
## two tests silently disagreed about would be worse than two copies.
const LONG_PROMPT := "[img=36x36]res://assets/ui/input_prompts/keyboard_r.png[/img]   Put Thunderbristle Junior away        [img=36x36]res://assets/ui/input_prompts/keyboard_e.png[/img]   Talk to the Warden of the Upper Meadows about the relay"

var _failures: Array[String] = []
var _screen := Vector2i(1920, 1080)
var _hud: Node = null
var _card: Control = null
var _hotbar: Control = null
var _banner: Label = null


func _init() -> void:
	_run()


func _run() -> void:
	for i in SETTLE:
		await process_frame
	_screen = Vector2i(
		int(ProjectSettings.get_setting("display/window/size/viewport_width", 1920)),
		int(ProjectSettings.get_setting("display/window/size/viewport_height", 1080)),
	)
	root.size = _screen
	for i in SETTLE:
		await process_frame

	var packed: PackedScene = load(HUD_SCENE)
	if packed == null:
		print("FAIL: could not load %s" % HUD_SCENE)
		quit(1)
		return
	_hud = packed.instantiate()
	root.add_child(_hud)
	for i in SETTLE:
		await process_frame

	_card = _hud.find_child("ObjectiveHintCard", true, false) as Control
	_hotbar = _hud.find_child("HotbarPanel", true, false) as Control
	_banner = _hud.get(&"_region_banner") as Label
	if _card == null or _hotbar == null or _banner == null:
		print("FAIL: HUD is missing ObjectiveHintCard, HotbarPanel or the region banner")
		quit(1)
		return
	_reveal_the_left_column()

	await _check_every_authored_hint_fits_its_band()
	await _check_the_hint_actually_reaches_the_card()
	_check_an_unauthored_rung_shows_nothing()
	await _check_the_card_stands_down_on_its_own()
	await _check_the_objective_plate_holds_its_own_text()

	_report()


## The load-bearing assertion. Every hint the chapter authors, at the card's
## real width, against the dock in its TALLEST state -- not the quiet one that
## would let a card 200px too tall pass.
func _check_every_authored_hint_fits_its_band() -> void:
	_push_the_dock_to_its_tallest()
	for i in SETTLE:
		await process_frame
	var dock_top := _hotbar.get_global_rect().position.y
	var banner_bottom := _banner.get_global_rect().end.y
	var neighbours := _visible_neighbours()
	if neighbours.size() < 3:
		_fail("only %d visible HUD neighbours found -- the overlap check is not exercising the real HUD" % neighbours.size())
		return
	var names: Array[String] = []
	for entry: Variant in neighbours:
		names.append(str((entry as Dictionary)["name"]))
	print("        measured against %d visible widgets: %s" % [names.size(), ", ".join(names)])

	var hints := _authored_hints()
	if hints.size() < 5:
		_fail("only %d authored hints found -- this test is not exercising the chapter" % hints.size())
		return

	var tallest := 0.0
	var tallest_hint := ""
	for hint: String in hints:
		_hud.call("_reveal_objective_hint", hint)
		for i in 2:
			await process_frame
		if not _card.visible:
			_fail("the card did not reveal for an authored hint: %s" % hint)
			return
		var rect := _card.get_global_rect()
		if rect.size.y > tallest:
			tallest = rect.size.y
			tallest_hint = hint
		if rect.position.y < banner_bottom - 0.5:
			_fail("the card overlaps the region banner (card top %.0f, banner bottom %.0f) for: %s" % [
				rect.position.y, banner_bottom, hint,
			])
			return
		if rect.end.y > dock_top + 0.5:
			_fail("the card runs into the bottom dock (card bottom %.0f, hotbar top %.0f) for: %s" % [
				rect.end.y, dock_top, hint,
			])
			return
		# Centred, and inside the horizontal safe area at both edges.
		if absf(rect.get_center().x - float(_screen.x) * 0.5) > 1.0:
			_fail("the card is not centred: %s" % rect)
			return
		if rect.position.x < 0.0 or rect.end.x > float(_screen.x):
			_fail("the card runs off the canvas: %s" % rect)
			return
		# And clear of every other visible HUD widget, not just the two that
		# bound the band. A first render of this card at the width the hint
		# measurements alone wanted (1140) cleared the banner and the dock and
		# still put its corner over the objective block's plate; both HUD
		# columns run the full height of the screen, so "between the banner and
		# the dock" is not the same as "in the clear".
		for entry: Variant in neighbours:
			var other := entry as Dictionary
			var other_rect: Rect2 = other["rect"]
			if rect.intersects(other_rect):
				_fail("the card overlaps %s (card %s, %s %s) for: %s" % [
					other["name"], rect, other["name"], other_rect, hint,
				])
				return

	print("  ok    %d authored hints all fit: tallest card %.0fpx, band %.0f-%.0f (%.0fpx spare)" % [
		hints.size(), tallest, banner_bottom, dock_top, dock_top - banner_bottom - tallest,
	])
	print("        tallest was: %s" % tallest_hint)


## Non-vacuity, in the direction that matters: the checks above would all pass
## against a card that draws an empty string. This drives the real path --
## `Game.objective_hint` -> `_update_objective()` -> the card's own label --
## and reads the text back off the label.
func _check_the_hint_actually_reaches_the_card() -> void:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		_fail("Game autoload is missing; the wiring check cannot run")
		return
	var hints := _authored_hints()
	if hints.is_empty():
		_fail("no authored hints to drive the wiring check with")
		return
	var hint: String = hints[0]

	# Through `Game`, not through the HUD: `set_objective()` deliberately
	# clears the hint (a posed objective has no authored `how`), so the field
	# is written directly, which is what `_process()` does on a real flag
	# change. The tracked text must differ from what the HUD last saw or
	# `_update_objective()` short-circuits and nothing is proved.
	game.set("objective_hint", hint)
	game.set("objective_text", "A rung this test invented, to force a change.")
	for i in 4:
		await process_frame

	var label := _hud.get(&"_objective_hint_label") as Label
	if label == null:
		_fail("the card has no hint label")
		return
	if not _card.visible:
		_fail("a changed objective with an authored hint did not reveal the card")
		return
	if label.text != hint:
		_fail("the card drew %s, not the hint Game published (%s)" % [label.text, hint])
		return
	print("  ok    Game.objective_hint reaches the card's own label")


## Every beat past tournament entry authors no `how` (OP23-04's directive is
## the opening ladder), and `quest_log.gd::tracked_hint()`'s own header says a
## caller must draw an empty hint as NOTHING, never as a blank line. This is
## that contract.
func _check_an_unauthored_rung_shows_nothing() -> void:
	_hud.call("_reveal_objective_hint", "")
	if _card.visible:
		_fail("an empty hint still revealed the card")
		return
	_hud.call("_reveal_objective_hint", "   ")
	if _card.visible:
		_fail("a whitespace-only hint still revealed the card")
		return
	print("  ok    a rung with no authored hint draws nothing")


## The card is a timed reveal, not new permanent chrome -- that is the whole
## reason `HIST-036` could ship at all against OP23-09. A card that reveals and
## never leaves is the defect, not the fix.
func _check_the_card_stands_down_on_its_own() -> void:
	_hud.call("_reveal_objective_hint", "Short one.")
	if not _card.visible:
		_fail("the stand-down check could not reveal the card first")
		return
	var until := float(_hud.get(&"_objective_hint_until"))
	if until <= 0.0:
		_fail("the card revealed without arming its own deadline")
		return
	# Wind the deadline into the past rather than sleeping through it: the
	# duration is content-derived (base + per word) and a test that waited it
	# out would be a multi-second sleep asserting the clock, not the logic.
	_hud.set(&"_objective_hint_until", 0.001)
	_hud.call("_tick_objective_hint")
	if _card.visible:
		_fail("the card was still up after its deadline passed")
		return
	if float(_hud.get(&"_objective_hint_until")) != 0.0:
		_fail("the card hid but left its deadline armed")
		return
	print("  ok    the card stands down on its own deadline")


## Found while measuring `HIST-036` rather than looked for, and it is a defect
## in its own right: `OBJECTIVE_BLOCK_HEIGHT` (170) is a fixed number that
## leaves 94px of interior for the tracked line, and the opening's own line
## ("Open the village gate and follow the road in.") measures 159px wrapped at
## the block's 380px inner width. A `Label` does not clip by default, so the
## overflow drew straight out through the bottom of the block's backing plate
## and onto the terrain -- which is precisely the "floating on sky and terrain,
## one lighting change from vanishing" failure HUD-POPUP added that plate to
## fix, recurring for any line long enough to wrap past three rows.
##
## Driven with the real worst-case string off `objectives.json` rather than an
## invented long one, so this asserts the shipped chapter fits, not a
## hypothetical.
func _check_the_objective_plate_holds_its_own_text() -> void:
	var game := root.get_node_or_null(^"Game")
	var block := _hud.get(&"_objective_block") as Control
	var label := _hud.get(&"_objective_text_label") as Label
	if game == null or block == null or label == null:
		_fail("HUD/Game did not expose the objective block for the plate check")
		return

	var worst := ""
	var log_reader: RefCounted = QUEST_LOG.new()
	var progression: RefCounted = PROGRESSION.new()
	for raw: Variant in (log_reader.call("main_entries", progression) as Array):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var text := str((raw as Dictionary).get("label", ""))
		if text.length() > worst.length():
			worst = text
	if worst.is_empty():
		_fail("no authored objective lines to drive the plate check with")
		return

	game.set("objective_text", worst)
	for i in 4:
		await process_frame

	var block_rect := block.get_global_rect()
	var label_rect := label.get_global_rect()
	if label_rect.end.y > block_rect.end.y + 0.5:
		_fail("the objective text runs out through the bottom of its own plate (text ends %.0f, plate ends %.0f) for: %s" % [
			label_rect.end.y, block_rect.end.y, worst,
		])
		return
	print("  ok    the objective plate holds its longest authored line (%.0fpx of text in a %.0fpx plate)" % [
		label_rect.size.y, block_rect.size.y,
	])


## Every visible HUD widget the card could land on, with the name to blame in
## a failure. Read live off the tree rather than listed by hand, so a widget
## added to this HUD later is covered without anyone remembering to add it.
func _visible_neighbours() -> Array:
	var out: Array = []
	var hud_root := _hud.get_node_or_null(^"Root") as Control
	if hud_root == null:
		return out
	for child: Node in hud_root.get_children():
		var control := child as Control
		if control == null or control == _card or not control.visible:
			continue
		var rect := control.get_global_rect()
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		out.append({"name": control.name, "rect": rect})
	return out


## Reveal the party strip. It is the left column's WIDEST occupant and it is
## hidden by default (`GF-B-006` -- the strip no longer reveals with an empty
## roster), so a card measured against a HUD where it never appeared would be
## measured against the wrong screen. A catch changes the party and the
## objective in the same instant, so these two are genuinely on screen
## together.
func _reveal_the_left_column() -> void:
	var game := root.get_node_or_null(^"Game")
	var party: RefCounted = game.get("party") if game != null else null
	if party != null:
		for species in ["terrapup", "ripplet", "bramblebun", "mosshell", "tuskroot"]:
			var creature: RefCounted = game.call("make_creature", species, "")
			if creature != null:
				party.call("add", creature)
	var strip := _hud.get_node_or_null(^"Root/PartyStrip")
	if strip != null:
		if strip.has_method("update_from_party") and party != null:
			strip.call("update_from_party", party)
		if strip.has_method("set_pinned"):
			strip.call("set_pinned", true)
		strip.call("show_strip")


## Push the bottom dock into the tallest state it reaches in play: the hotbar's
## message row showing AND the contextual prompt wrapped to two lines. Both are
## what `smoke_prompt_hotbar_dock.gd` found had beaten two earlier hand-measured
## fixes, so both are what the card's band is measured against.
func _push_the_dock_to_its_tallest() -> void:
	var message := _hud.find_child("Message", true, false) as Label
	if message != null:
		message.text = "Nothing on that slot"
		message.visible = true
	var prompt := _hud.find_child("Prompt", true, false) as RichTextLabel
	if prompt != null:
		prompt.text = LONG_PROMPT


## Every `how` the chapter authors, resolved through `quest_log.gd` exactly as
## `Game` resolves it, so this measures the real strings and not a sample.
func _authored_hints() -> Array[String]:
	var out: Array[String] = []
	var log_reader: RefCounted = QUEST_LOG.new()
	var progression: RefCounted = PROGRESSION.new()
	for raw: Variant in (log_reader.call("main_entries", progression) as Array):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var hint := str((raw as Dictionary).get("how", ""))
		if not hint.is_empty():
			out.append(hint)
	return out


func _fail(message: String) -> void:
	_failures.append(message)
	print("  FAIL  %s" % message)


func _report() -> void:
	print("")
	print("objective hint card, measured at %s" % _screen)
	if _failures.is_empty():
		print("PASS: the objective hint reaches the screen and its card fits its band")
		quit(0)
		return
	print("%d failure(s)" % _failures.size())
	quit(1)
