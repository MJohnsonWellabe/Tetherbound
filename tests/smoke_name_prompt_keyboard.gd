extends SceneTree

## OF25: "the keyboard in game still sucks. Just make it use the real
## keyboard." Reproduces the reported case directly, headless:
##
##   godot --headless --path . --script tests/smoke_name_prompt_keyboard.gd
##
## Before the fix, every keystroke into the naming panel ALSO fired whatever
## polled game action shared that key -- typing `i` opened the pause menu
## over the panel (`inventory`'s default key), and Enter both confirmed the
## panel AND registered as a `menu_confirm` poll the same frame. Neither of
## those is visible from calling `name_entry.gd`'s methods directly
## (`tests/test_name_entry.gd`, unchanged by this pass and still the
## validator's own coverage) -- they are both about whether a REAL key event
## reaching a REAL, focused `LineEdit` also leaks into everything else in the
## game still polling `Input.is_action_just_pressed()`, which only a booted
## scene with the real `Game` autoload's real pause menu can show.
##
## Opens the panel the same way `sequence_director.gd::_on_starter_picker_chosen`
## does -- `name_prompt.open(subject)` -- rather than driving the whole opening
## up to that point (`tests/smoke_opening.gd`, a sibling task's file this pass
## does not touch). That call is the seam between the story and the panel; the
## story reaching it is smoke_opening's job, and this is what happens once it
## does.

const NAME_PROMPT_SCENE := "res://scenes/ui/name_prompt.tscn"

## A handful of frames for `_ready()` to run and the `Game` autoload's own
## boot (`_mount_menu()`) to land -- no terrain, no player, nothing else in
## this scene, so nothing here needs `smoke_opening.gd`'s 300-frame settle.
const SETTLE_FRAMES := 10

var _failures: Array[String] = []
var _prompt: CanvasLayer = null
var _game: Node = null
var _menu: Object = null
var _confirms: int = 0
var _confirmed_names: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	_prompt = (load(NAME_PROMPT_SCENE) as PackedScene).instantiate()
	root.add_child(_prompt)
	for i in SETTLE_FRAMES:
		await physics_frame

	if not _collect_nodes():
		_report()
		return

	_prompt.connect("confirmed", _on_confirmed)

	await _typing_a_colliding_letter_lands_in_the_field_not_the_menu()
	await _enter_confirms_exactly_once()

	_report()


func _collect_nodes() -> bool:
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_fail("the Game autoload is not in the tree; project.godot's [autoload] block is the thing to look at")
		return false
	if not _game.has_method("menu"):
		_fail("the Game autoload has no menu() -- see autoload/game_state.gd")
		return false
	_menu = _game.call("menu")
	if _menu == null:
		_fail("the Game autoload did not stand up the pause menu")
		return false
	if not _prompt.has_method("open") or not _prompt.has_signal("confirmed"):
		_fail("scripts/ui/name_prompt.gd does not parse -- see the SCRIPT ERROR above")
		return false
	return true


func _on_confirmed(creature_name: String) -> void:
	_confirms += 1
	_confirmed_names.append(creature_name)


## `I` is a real letter a real name can contain, and it is also `inventory`'s
## default key (project.godot) -- the exact reported case. Injected as a real
## `InputEventKey`, not `Input.action_press`: the naming field is a `LineEdit`
## now, reading through Godot's own Control input pipeline, and only a
## genuine key event exercises that path the way archive/docs/HANDOFF.md §10 already
## requires for every other piece of UI navigation in this suite.
func _typing_a_colliding_letter_lands_in_the_field_not_the_menu() -> void:
	_prompt.call("open", "Test")
	# Past `OPEN_GUARD_FRAMES` and the mode having been applied for real.
	for i in 6:
		await physics_frame

	if not bool(_prompt.call("is_open")):
		_fail("opening the naming prompt directly (as the sequence director does) left it closed")
		return
	if bool(_menu.call("is_open")):
		_fail("the pause menu is already open before anything was typed; cannot isolate the reported case")
		return

	await _send_key(KEY_I, "i".unicode_at(0))
	for i in 4:
		await physics_frame

	var typed := str(_prompt.call("current_text"))
	if not typed.to_lower().contains("i"):
		_fail("typing 'I' did not land in the naming field; it reads '%s'" % typed)
	else:
		print("keyboard: typed 'I', the field reads '%s'" % typed)

	if bool(_menu.call("is_open")):
		_fail("typing 'I' into the naming field also opened the pause menu")
		return
	print("keyboard: typing 'I' did not open the pause menu")


## Enter is bound to BOTH `_field`'s own native submit and the grid's
## `menu_confirm` poll (project.godot: KEY_ENTER is `menu_confirm`'s default).
## Before OF25, a keyboard press of it fired both paths in the same frame.
func _enter_confirms_exactly_once() -> void:
	if not bool(_prompt.call("is_open")):
		_fail("the naming prompt closed on its own before Enter was ever pressed")
		return

	var before := _confirms
	await _send_key(KEY_ENTER, 13)
	for i in 8:
		await physics_frame

	var fired := _confirms - before
	if fired != 1:
		_fail("pressing Enter once fired 'confirmed' %d time(s); expected exactly 1" % fired)
		return
	print("keyboard: Enter confirmed exactly once, named '%s'" % str(_confirmed_names[_confirmed_names.size() - 1]))

	if bool(_prompt.call("is_open")):
		_fail("the naming prompt is still open after Enter confirmed it")
		return
	print("keyboard: the naming prompt closed")


## Press and release, the same shape `smoke_opening.gd`'s own `_press` uses --
## a real down event then a real up event, with a settle frame on each side.
func _send_key(keycode: int, unicode: int) -> void:
	var down := InputEventKey.new()
	down.pressed = true
	down.keycode = keycode
	down.physical_keycode = keycode
	down.unicode = unicode
	Input.parse_input_event(down)
	await physics_frame

	var up := InputEventKey.new()
	up.pressed = false
	up.keycode = keycode
	up.physical_keycode = keycode
	Input.parse_input_event(up)
	await physics_frame


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("name prompt keyboard: OK -- a real key reaches the field and nothing else.")
		quit(0)
		return
	for line in _failures:
		print("name prompt keyboard FAIL: %s" % line)
	quit(1)
