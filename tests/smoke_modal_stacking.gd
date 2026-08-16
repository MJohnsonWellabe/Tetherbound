extends SceneTree

## Can the pause shell open on top of a screen the player must answer?
##
##   godot --headless --path . --script tests/smoke_modal_stacking.gd
##
## The blind playtest pressed the menu button while the starter orbs were up and
## got both at once: the shell opened, paused the tree, and the picker — which
## is not `PROCESS_MODE_ALWAYS`, so the pause stops it processing but not
## drawing — kept its title and its "look / choose" hints on screen through the
## menu, over a selector that could no longer be answered. The same hole was
## open under a conversation.
##
## `game_menu.gd::open()` used to refuse for exactly two reasons (already open,
## fight in progress); the only thing keeping it off a modal was that modal
## calling `hold_input()` itself, which `name_prompt.gd` did and the other two
## did not. The rule now lives in `open()`, asked of `STORY_MODAL_GROUP`, so a
## fourth modal cannot forget to opt in — and this test is what says so: it
## drives the real button rather than calling `open()`, and it checks the
## on-screen reason appeared, because a refusal nobody can see is the silent
## no-op `_flash_refusal()` exists to prevent.
##
## No world scene. The shell is an autoload and both modals are ordinary
## CanvasLayers; booting the meadow would add four minutes of terrain to a check
## about one guard.

const PICKER_SCENE := "res://scenes/ui/starter_picker.tscn"
const DIALOGUE_SCENE := "res://scenes/ui/dialogue_panel.tscn"
const OPENING_CONFIG := "res://data/config/opening.json"
## Grandpa's briefing — any real conversation id would do; this one is the first
## the opening plays, so a rename of it is worth failing on.
const CONVERSATION := "grandpa_house"

var _failures: Array[String] = []
var _menu: CanvasLayer = null


func _init() -> void:
	_run()


func _run() -> void:
	# `_init()` runs before the autoloads are mounted, so asking for `Game` right
	# away finds nothing and reports it as a missing autoload — a false failure
	# that would look exactly like project.godot's `[autoload]` block breaking.
	for i in 4:
		await process_frame

	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("FAIL: the Game autoload is not in the tree")
		quit(1)
		return
	_menu = game.call("menu")
	if _menu == null:
		print("FAIL: the autoload did not stand up the menu")
		quit(1)
		return

	await _check_the_shell_opens_with_nothing_in_the_way()
	await _check_the_shell_refuses_over_the_starter_picker()
	await _check_the_shell_refuses_over_a_conversation()

	print("")
	if _failures.is_empty():
		print("modal stacking smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)


func _fail(message: String) -> void:
	_failures.append(message)


## The control. Without this, every check below would pass on a menu that never
## opens at all — the "passes because the feature is absent" failure
## ralph/conventions.md names.
func _check_the_shell_opens_with_nothing_in_the_way() -> void:
	await _press("inventory")
	if not bool(_menu.call("is_open")):
		_fail("the menu does not open even with nothing on screen; the checks below prove nothing")
		return
	_menu.call("close")
	for i in 4:
		await process_frame
	print("control: the shell opens and closes with no modal up")


func _check_the_shell_refuses_over_the_starter_picker() -> void:
	var picker := _instantiate(PICKER_SCENE)
	if picker == null:
		return
	picker.call("open", _species())
	await process_frame
	if not bool(picker.call("is_open")):
		_fail("the starter picker would not open; nothing was tested")
		picker.queue_free()
		return

	await _press("inventory")
	if bool(_menu.call("is_open")):
		_fail(
			"the pause shell opened on top of the starter picker. The picker keeps DRAWING while "
			+ "the tree is paused, so its title and hints ghost through the menu over a selector "
			+ "the player can no longer answer."
		)
		_menu.call("close")
	else:
		_expect_reason("the starter picker")

	# And the same button through its other route: the shortcut keys read a
	# separate branch of `_read_actions`, and a guard fixed on one of them only
	# is a guard that holds until somebody presses Escape instead.
	await _press("menu_cancel")
	if bool(_menu.call("is_open")):
		_fail("`menu_cancel` opened the shell over the starter picker even though `inventory` was refused")
		_menu.call("close")

	picker.call("close")
	picker.queue_free()
	for i in 4:
		await process_frame

	await _press("inventory")
	if not bool(_menu.call("is_open")):
		_fail("the shell would not open after the picker closed; the guard latched instead of being asked per press")
		return
	_menu.call("close")
	for i in 4:
		await process_frame
	print("picker: shell refused while open, allowed again after it closed")


func _check_the_shell_refuses_over_a_conversation() -> void:
	var panel := _instantiate(DIALOGUE_SCENE)
	if panel == null:
		return
	if not bool(panel.call("start", CONVERSATION)):
		_fail("conversation '%s' would not start; data/dialogue no longer has it under that id" % CONVERSATION)
		panel.queue_free()
		return
	await process_frame
	if not bool(panel.call("is_open")):
		_fail("the dialogue panel reported the conversation started but is not open")
		panel.queue_free()
		return

	await _press("inventory")
	if bool(_menu.call("is_open")):
		_fail("the pause shell opened on top of an active conversation; Grandpa keeps talking behind it")
		_menu.call("close")
	else:
		_expect_reason("a conversation")

	panel.call("close")
	panel.queue_free()
	for i in 4:
		await process_frame
	print("dialogue: shell refused while a conversation was on screen")


## A refusal the player cannot see is the same broken-looking dead button
## `_flash_refusal()` was written to stop, so the hint is part of the pass.
func _expect_reason(what: String) -> void:
	var hint: Label = _menu.get_node_or_null(^"RefusalHint") as Label
	if hint == null:
		_fail("the shell refused over %s with no RefusalHint node to explain it" % what)
		return
	if not hint.visible or hint.text.is_empty():
		_fail("the shell refused over %s silently; the button just looks broken" % what)
		return
	print("refused over %s: \"%s\"" % [what, hint.text])


func _instantiate(path: String) -> CanvasLayer:
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		_fail("%s does not load" % path)
		return null
	var node := scene.instantiate() as CanvasLayer
	root.add_child(node)
	return node


func _species() -> Array[String]:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(OPENING_CONFIG))
	var out: Array[String] = []
	if typeof(parsed) != TYPE_DICTIONARY:
		return out
	var starters: Variant = (parsed as Dictionary).get("starters", {})
	if typeof(starters) != TYPE_DICTIONARY:
		return out
	for id in (starters as Dictionary).get("species", []):
		out.append(str(id))
	return out


## Both paths, because the shell uses both: `Input.action_press` for its own
## polling and a parsed event for the focus half of a controller menu
## (docs/HANDOFF.md §10, and smoke_menu.gd is where that was learned).
##
## Process frames, not physics: `game_menu.gd` reads its actions in `_process`.
func _press(action: String) -> void:
	Input.action_press(action)
	_send(action, true)
	await process_frame
	await process_frame
	Input.action_release(action)
	_send(action, false)
	for i in 4:
		await process_frame


func _send(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)
