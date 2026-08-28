extends SceneTree

## `HIST-014` — "the world HUD ghosts under the dialogue panel."
##
##   godot --headless --path . --script tests/smoke_dialogue_clears_the_world_hud.gd
##
## The reported symptom: while Grandpa is talking, *"RB — Call out Terrapup"*
## shows through the top edge of his dialogue box. The root cause the register
## names is that the five station panels were wired to
## `input_owner.gd::set_world_hud_visible()` and the dialogue panel was not —
## and the entry flags an open design question before the fix: **a conversation
## is not a menu, so hiding the whole HUD may not be what is wanted.**
##
## This file does not answer that question. It asserts the thing the question is
## downstream of: whatever the HUD chooses to keep on screen during a
## conversation must not composite through the box. That holds whether the HUD
## is hidden wholesale later or left where it is.
##
## Verified on current `main` before writing anything: the *reported* symptom is
## already gone, by a different route than the register expected.
## `_yield_bottom_to_build_menu()` hides both the hotbar and the contextual
## prompt on `INPUT_OWNER.current(tree) != null`, and
## `_exploration_legend_should_show()` stands the legend down on the same
## predicate — and `dialogue_panel.gd` joins `INPUT_OWNER.GROUP`. So all three
## bottom-dock widgets, the prompt among them, already leave while a
## conversation owns input. Nothing else the HUD draws reaches the box's band.
##
## What was missing is a test saying so, which is what this is: the guard is on
## the OUTCOME (no visible world-HUD widget intersects the dialogue box) rather
## than on the mechanism, so a later lane is free to answer the design question
## either way without this file having an opinion about how.

const HUD_SCENE := "res://scenes/ui/playground_hud.tscn"
const DIALOGUE_SCENE := "res://scenes/ui/dialogue_panel.tscn"
const SETTLE := 8

## Grandpa downstairs, the morning the game starts — the conversation the
## reported symptom was seen in.
const CONVERSATION := "grandpa_house"

var _failures: Array[String] = []
var _screen := Vector2i(1920, 1080)
var _hud: Node = null
var _dialogue: Node = null


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

	# A stand-in world, so `set_world_hud_visible()` has something to resolve
	# against if a later lane does wire the dialogue panel to it — this file
	# passes either way, which is the point.
	var world := Node.new()
	world.name = "StageWorld"
	root.add_child(world)
	current_scene = world

	var hud_packed: PackedScene = load(HUD_SCENE)
	var dialogue_packed: PackedScene = load(DIALOGUE_SCENE)
	if hud_packed == null or dialogue_packed == null:
		print("FAIL: could not load the HUD or the dialogue panel scene")
		quit(1)
		return
	_hud = hud_packed.instantiate()
	_hud.name = "PlaygroundHUD"
	world.add_child(_hud)
	_dialogue = dialogue_packed.instantiate()
	world.add_child(_dialogue)
	for i in SETTLE:
		await process_frame

	_seed_the_hud()
	for i in SETTLE:
		await process_frame

	if not await _open_the_conversation():
		_report()
		return
	_check_nothing_visible_reaches_the_box()
	await _check_the_hud_comes_back()

	_report()


## The HUD has to have something to draw before "nothing overlaps" means
## anything: an empty HUD passes every rect check trivially. A five-creature
## roster revealed, a contextual prompt with real text in it, and the hotbar
## stocked is the state the reported symptom was seen in.
func _seed_the_hud() -> void:
	var game := root.get_node_or_null(^"Game")
	var party: RefCounted = game.get("party") if game != null else null
	if party != null:
		for species in ["terrapup", "ripplet", "bramblebun", "mosshell", "tuskroot"]:
			var creature: RefCounted = game.call("make_creature", species, "")
			if creature != null:
				party.call("add", creature)
	var strip := _hud.get_node_or_null(^"Root/PartyStrip")
	if strip != null:
		if strip.has_method("set_pinned"):
			strip.call("set_pinned", true)
		strip.call("show_strip")
	var prompt := _hud.find_child("Prompt", true, false) as RichTextLabel
	if prompt != null:
		prompt.text = "[img=36x36]res://assets/ui/input_prompts/keyboard_r.png[/img]   Call out Terrapup"


func _open_the_conversation() -> bool:
	if not bool(_dialogue.call("start", CONVERSATION)):
		_fail("could not start the '%s' conversation; nothing to measure against" % CONVERSATION)
		return false
	for i in SETTLE:
		await process_frame
	if not bool(_dialogue.call("is_open")):
		_fail("the dialogue panel did not report itself open")
		return false
	print("  ok    '%s' is on screen" % CONVERSATION)
	return true


func _check_nothing_visible_reaches_the_box() -> void:
	var box := _dialogue.find_child("Box", true, false) as Control
	if box == null:
		# The box is the panel's own plated child; fall back to the panel's
		# root rather than silently measuring nothing.
		box = _dialogue.get_child(0) as Control
	if box == null or box.get_global_rect().size.y <= 0.0:
		_fail("could not find the dialogue box's rect")
		return
	var box_rect := box.get_global_rect()

	var hud_root := _hud.get_node_or_null(^"Root") as Control
	if hud_root == null:
		_fail("HUD has no Root")
		return

	var drawn := _drawn_controls(hud_root)
	var measured := drawn.size()
	var offenders: Array[String] = []
	for entry: Variant in drawn:
		var item := entry as Dictionary
		var rect: Rect2 = item["rect"]
		if rect.intersects(box_rect):
			offenders.append("%s (%s) %s" % [item["name"], item["class"], rect])
	if measured < 3:
		_fail("only %d visible HUD widgets during the conversation -- this check is not measuring a populated HUD" % measured)
		return
	if not offenders.is_empty():
		_fail("world HUD draws through the dialogue box %s: %s" % [box_rect, ", ".join(offenders)])
		return
	print("  ok    %d visible HUD widgets, none reaching the box %s" % [measured, box_rect])


## And the other half: whatever left has to come back. A conversation that
## permanently took the hotbar away would pass the check above and be worse
## than the defect.
func _check_the_hud_comes_back() -> void:
	var hotbar := _hud.find_child("HotbarPanel", true, false) as Control
	if hotbar == null:
		_fail("HUD has no HotbarPanel")
		return
	if hotbar.visible:
		_fail("the hotbar was never stood down during the conversation; the restore check would pass vacuously")
		return
	_dialogue.call("close")
	for i in SETTLE:
		await process_frame
	if not hotbar.visible:
		_fail("the hotbar did not come back after the conversation closed")
		return
	print("  ok    the bottom dock stands down for the conversation and comes back after it")


## Every visible Control in the HUD that actually PAINTS something.
##
## Rect-vs-rect on direct children is not enough and is wrong in both
## directions. Too coarse: `Root/BottomDock` is a full-width `VBoxContainer`
## that spans the dialogue box's whole band and paints nothing at all -- a
## first run of this file failed on it while every one of its three children
## was correctly stood down. Too shallow: a single label left drawing inside a
## container whose own rect happens to sit elsewhere would be missed. So the
## tree is walked, and the pure layout/grouping types are skipped by class --
## they have no stylebox and no text, and their rects describe where their
## children MAY go, not where anything is drawn.
func _drawn_controls(node: Node) -> Array:
	const LAYOUT_ONLY := [
		"Control", "BoxContainer", "VBoxContainer", "HBoxContainer",
		"MarginContainer", "CenterContainer", "GridContainer", "Container",
	]
	var out: Array = []
	for child: Node in node.get_children():
		var control := child as Control
		if control != null and control.is_visible_in_tree() \
				and not LAYOUT_ONLY.has(control.get_class()):
			var rect := control.get_global_rect()
			if rect.size.x > 0.0 and rect.size.y > 0.0:
				out.append({
					"name": control.name if not control.name.is_empty() else control.get_class(),
					"class": control.get_class(),
					"rect": rect,
				})
		# Descended into regardless of whether the parent was counted: a hidden
		# container hides its children (`is_visible_in_tree()` catches that),
		# but a layout-only container that was skipped still has children that
		# draw.
		out.append_array(_drawn_controls(child))
	return out


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	print("dialogue vs world HUD, measured at %s" % _screen)
	if _failures.is_empty():
		print("PASS: nothing the world HUD draws composites through the dialogue box")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)
