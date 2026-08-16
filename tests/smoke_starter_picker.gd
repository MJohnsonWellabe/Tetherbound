extends SceneTree

## Can the orb picker be confirmed when the confirm shares a frame with an arrow?
##
##   godot --headless --path . --script tests/smoke_starter_picker.gd
##
## The blind playtest's one P0: the picker opened, the arrows moved the
## highlight, and the A button did nothing at all, so the opening could not be
## finished and the game could not be reached. The cause is not in the confirm
## path — `_confirm()` was always correct — it is that
## `scripts/ui/starter_picker.gd` used to read its three actions as one
## `if/elif/elif` chain, confirm LAST:
##
##     if ui_right: _move(1)
##     elif ui_left: _move(-1)
##     elif menu_confirm: _confirm()
##
## `is_action_just_pressed` is true for exactly one physics frame. Any frame
## that carries a direction AND a confirm therefore loses the confirm outright —
## not deferred to the next tick, gone, because by the next tick its just-pressed
## window has closed. And with the highlight already clamped at either end of the
## row `_move()` returns early, so the frame that swallowed the confirm changes
## nothing on screen either: the player sees a picker that reacts to the stick
## and ignores the button.
##
## A pad makes that collision easy — the physics tick is 16ms wide and a thumb
## rolling from the stick onto A lands inside one constantly — which is why the
## picker is driven here the way the bug happens, both actions pressed with no
## frame between them, rather than the frames-apart presses
## tests/smoke_opening.gd sends.
##
## The picker is instantiated on its own rather than through the meadow scene.
## Everything this checks lives in `_physics_process` and `_confirm()`; booting
## the world would add four minutes of terrain and walking to a check about two
## button reads.

const PICKER_SCENE := "res://scenes/ui/starter_picker.tscn"
const OPENING_CONFIG := "res://data/config/opening.json"

## Past `starter_picker.gd::OPEN_GUARD_FRAMES` (2) with room to spare, so a
## press cannot be eaten by the deafness the picker opens with.
const SETTLE_FRAMES := 8

var _failures: Array[String] = []
var _picker: CanvasLayer = null
var _chosen: Array[int] = []


func _init() -> void:
	_run()


func _run() -> void:
	var scene: PackedScene = load(PICKER_SCENE) as PackedScene
	if scene == null:
		print("FAIL: %s does not load; there is no picker to drive" % PICKER_SCENE)
		quit(1)
		return
	_picker = scene.instantiate() as CanvasLayer
	root.add_child(_picker)
	await process_frame

	await _check_the_confirm_survives_a_same_frame_arrow()
	await _check_the_arrows_still_move_on_their_own()

	print("")
	if _failures.is_empty():
		print("starter picker smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)


func _fail(message: String) -> void:
	_failures.append(message)


func _species() -> Array[String]:
	var text := FileAccess.get_file_as_string(OPENING_CONFIG)
	var parsed: Variant = JSON.parse_string(text)
	var out: Array[String] = []
	if typeof(parsed) != TYPE_DICTIONARY:
		return out
	var starters: Variant = (parsed as Dictionary).get("starters", {})
	if typeof(starters) != TYPE_DICTIONARY:
		return out
	for id in (starters as Dictionary).get("species", []):
		out.append(str(id))
	return out


## The regression itself. Both actions go down with no physics frame between
## them, which is the only way to reproduce it: presses a frame or more apart
## have always worked, which is exactly why this shipped.
func _check_the_confirm_survives_a_same_frame_arrow() -> void:
	if not await _open_picker():
		return

	Input.action_press("ui_right")
	Input.action_press("menu_confirm")
	for i in 3:
		await physics_frame
	Input.action_release("ui_right")
	Input.action_release("menu_confirm")
	for i in 10:
		await physics_frame

	if bool(_picker.call("is_open")):
		_fail(
			"pressing `ui_right` and `menu_confirm` on the SAME physics frame left the picker open. "
			+ "The confirm was swallowed by the direction read — see this file's header. "
			+ "A player rolling a thumb from the stick onto A cannot finish the opening."
		)
		return
	if _chosen.is_empty():
		_fail("the picker closed on a same-frame confirm but never emitted `chosen`; no starter was picked")
		return

	var index: int = _chosen[0]
	var count := _species().size()
	if index < 0 or index >= count:
		_fail("`chosen` reported orb %d, which is not one of the %d on screen" % [index, count])
		return
	print("same-frame `ui_right`+`menu_confirm`: picker closed, chose orb %d of %d" % [index, count])


## The other half of the same fix: making the reads independent must not have
## cost the arrows their own effect. Without this, a picker whose directions
## were dead would still pass the check above.
func _check_the_arrows_still_move_on_their_own() -> void:
	if not await _open_picker():
		return

	var before := int(_picker.get("_index"))
	await _press("ui_right")
	var after := int(_picker.get("_index"))
	if after == before:
		_fail("`ui_right` on its own moved the highlight from %d to %d; the orbs cannot be browsed" % [before, after])
	else:
		print("`ui_right` alone: highlight moved %d -> %d" % [before, after])

	await _press("ui_left")
	if int(_picker.get("_index")) != before:
		_fail("`ui_left` did not undo the `ui_right`; the highlight is at %d, not %d" % [
			int(_picker.get("_index")), before
		])

	await _press("menu_confirm")
	if bool(_picker.call("is_open")):
		_fail("`menu_confirm` on its own did not close the picker")


func _open_picker() -> bool:
	_chosen.clear()
	var species := _species()
	if species.size() < 2:
		_fail("%s lists %d starters; a picker with fewer than two cannot test a move" % [
			OPENING_CONFIG, species.size()
		])
		return false
	_picker.call("open", species)
	if not _picker.is_connected("chosen", _on_chosen):
		_picker.connect("chosen", _on_chosen)
	if not bool(_picker.call("is_open")):
		_fail("open() did not open the picker")
		return false
	for i in SETTLE_FRAMES:
		await physics_frame
	return true


func _on_chosen(index: int) -> void:
	_chosen.append(index)


## Action state only, no parsed event. The picker reads every one of its actions
## by polling `Input.is_action_just_pressed` in `_physics_process` — it holds no
## focus and has no `_gui_input` — and a parsed event can register a physics
## frame later than the action state, which is one of the ways two presses meant
## to be apart end up in the same frame (tests/smoke_opening.gd's own
## `_press_polled` names the same race).
func _press(action: String) -> void:
	Input.action_press(action)
	for i in 3:
		await physics_frame
	Input.action_release(action)
	for i in 6:
		await physics_frame
