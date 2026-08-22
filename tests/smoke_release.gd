extends SceneTree

## Does the release ceremony (R4.10) actually run, on real input, and does the
## five-creature rule hold through every beat of it?
##
##   godot --headless --path . --script tests/smoke_release.gd
##
## tests/test_party.gd proves the model layer: a full party refuses a sixth,
## remove_at + add produces the expected five. None of that shows whether the
## ceremony REACHES the screen when a catch overflows the belt, whether a
## controller can drive it, or whether the player can dodge the choice by
## closing the menu — and each of those is a way this ships broken. Drives the
## real scene with injected input, `parse_input_event` included, because a
## poll-only test reports a working menu while the stick moves nothing
## (conventions.md, testing traps).
##
## Trigger coverage is split deliberately: `smoke_catching.gd` proves a real
## combat catch reaches `Game.party` through `_resolve_catch`; this file picks
## up at the seam that path fills when the belt is full — `Game.pending_catch`
## — and proves everything from there to the final five.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
## Frames the Game autoload's `_watch_pending_catch` gets to notice the seam
## and open the menu. It acts on the first unpaused frame; this is slack, not
## a timing contract.
const WATCH_FRAMES := 60

var _failures: Array[String] = []
var _game: Node = null
var _menu: CanvasLayer = null
var _tab: Node = null
var _tab_index: int = -1
var _party: RefCounted = null

var _keepers: Array[RefCounted] = []
var _newcomer: RefCounted = null


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	_game = root.get_node_or_null(^"Game")
	if _game == null:
		print("FAIL: the Game autoload is not in the tree")
		quit(1)
		return
	_menu = _game.call("menu")
	_party = _game.get("party")
	if _menu == null or _party == null:
		print("FAIL: the autoload has no menu or no party")
		quit(1)
		return
	if not _find_creatures_tab():
		_report()
		return

	_fill_the_belt()
	_squeeze()

	await _check_the_ceremony_opens_itself()
	await _check_the_six_are_presented()
	await _check_inspection_drives_the_detail_column()
	await _check_the_menu_cannot_be_left()
	await _check_closing_by_code_reopens_the_ceremony()
	await _check_choosing_is_not_yet_releasing()
	await _check_keeping_backs_out()
	await _check_releasing_a_belt_member_resolves()
	await _check_the_goodbye_beat_ends_on_the_new_belt()
	await _check_a_second_squeeze_can_release_the_newcomer()
	_report()


func _find_creatures_tab() -> bool:
	var tabs: Array = _menu.get("_tabs")
	for i in tabs.size():
		if str((tabs[i] as Dictionary).get("id", "")) == "creatures":
			_tab_index = i
			_tab = (_menu.get("_bodies") as Array)[i]
			return true
	_fail("no creatures tab is registered in menu.json")
	return false


## Five distinct keepers through the real GameState, exactly full.
func _fill_the_belt() -> void:
	var n := 0
	while not bool(_party.call("is_full")):
		n += 1
		var creature: RefCounted = _game.call("make_creature", "terrapup", "Keeper %d" % n)
		if creature == null:
			_fail("could not build a creature from species.json")
			return
		_party.call("add", creature)
	_keepers.clear()
	for i in int(_party.call("size")):
		_keepers.append(_party.call("at", i))


## The catch that would be a sixth: parked on the seam `_resolve_catch` fills,
## never on the party.
func _squeeze() -> void:
	_newcomer = _game.call("make_creature", "bramblebun", "Newest")
	_game.set("pending_catch", _newcomer)


func _check_the_ceremony_opens_itself() -> void:
	for i in WATCH_FRAMES:
		await process_frame
		if bool(_menu.call("is_open")):
			break
	if not bool(_menu.call("is_open")):
		_fail("a catch on the seam never opened the menu; the ceremony is unreachable in play")
		return
	if int(_menu.get("_index")) != _tab_index:
		_fail("the menu opened on tab %d, not the creatures tab" % int(_menu.get("_index")))
	for i in 6:
		await process_frame
	if str(_tab.get("_release_stage")) != "choose":
		_fail("the ceremony did not enter its choose beat (stage '%s')" % str(_tab.get("_release_stage")))
		return
	if int(_party.call("size")) != 5:
		_fail("entering the ceremony changed the party size to %d" % int(_party.call("size")))
	if _game.get("pending_catch") == null:
		_fail("entering the ceremony consumed the pending catch before any choice")
	print("the ceremony opens itself on the creatures tab, party untouched")


func _check_the_six_are_presented() -> void:
	var rows: Array = _tab.get("_rows")
	if rows.size() != 5:
		_fail("the belt drew %d rows, not 5 — the sixth must never be a belt row" % rows.size())
	var pending_wrap: Control = _tab.get("_pending_wrap")
	if pending_wrap == null or not pending_wrap.visible:
		_fail("the newcomer's row is not on screen during the choose beat")
	var focused := _focused_control()
	if focused != _tab.get("_pending_button"):
		_fail("focus does not start on the newcomer (it starts on %s)" % (focused.name if focused != null else "nothing"))
	else:
		print("six on screen: five belt rows plus the newcomer's row, focus on the newcomer")


func _check_inspection_drives_the_detail_column() -> void:
	var name_label: Label = _tab.get("_detail_name")
	if name_label == null:
		_fail("no detail name label to inspect against")
		return
	if name_label.text.find("Newest") < 0:
		_fail("the detail column does not open on the newcomer (shows '%s')" % name_label.text)

	# Up from the newcomer lands on the last belt row, and the detail column
	# follows — the comparison loop a real decision needs.
	await _press("ui_up")
	var keeper_label := str((_keepers[4] as RefCounted).call("label"))
	if name_label.text.find(keeper_label) < 0:
		_fail("ui_up did not move inspection to %s (shows '%s')" % [keeper_label, name_label.text])

	# And up from the TOP row wraps back to the newcomer instead of escaping
	# into the shell's tab row — the fence that keeps the ceremony closed.
	for i in 5:
		await _press("ui_up")
	if _focused_control() != _tab.get("_pending_button"):
		_fail("walking up past row 0 escaped the ceremony's rows")
	else:
		print("inspection: the stick walks all six and the detail column follows, fenced")


func _check_the_menu_cannot_be_left() -> void:
	await _press("menu_cancel")
	if not bool(_menu.call("is_open")):
		_fail("menu_cancel closed the menu mid-ceremony; the choice can be dodged")
		return
	var index_before := int(_menu.get("_index"))
	await _press("menu_tab_left")
	if int(_menu.get("_index")) != index_before:
		_fail("menu_tab_left changed tab mid-ceremony")
	await _press("menu_tab_right")
	if int(_menu.get("_index")) != index_before:
		_fail("menu_tab_right changed tab mid-ceremony")
	if str(_tab.get("_release_stage")) != "choose":
		_fail("shell input knocked the ceremony out of its choose beat")
	else:
		print("the shell is held: no close, no tab away")


## Any route out — here, a direct close() nobody's input map can even reach —
## puts the ceremony straight back on screen. This is `_watch_pending_catch`'s
## whole job.
func _check_closing_by_code_reopens_the_ceremony() -> void:
	_menu.call("close")
	for i in WATCH_FRAMES:
		await process_frame
		if bool(_menu.call("is_open")):
			break
	if not bool(_menu.call("is_open")):
		_fail("a forced close stayed closed; the ceremony can be escaped by any code path that closes the menu")
		return
	for i in 6:
		await process_frame
	if str(_tab.get("_release_stage")) != "choose":
		_fail("the reopened ceremony is not back in its choose beat")
	if _focused_control() != _tab.get("_pending_button"):
		_fail("the reopened ceremony did not put focus back on the newcomer")
	else:
		print("a forced close reopens the ceremony by itself")


func _check_choosing_is_not_yet_releasing() -> void:
	# Choose the newcomer (focus is already there): the farewell question must
	# spend nothing.
	await _press("ui_accept")
	if str(_tab.get("_release_stage")) != "confirm":
		_fail("pressing the newcomer's row did not open the farewell question")
		return
	if int(_party.call("size")) != 5 or _game.get("pending_catch") == null:
		_fail("opening the farewell question already changed the party or consumed the catch")
	var focused := _focused_control()
	if focused != _tab.get("_farewell_keep"):
		_fail("the farewell question does not focus 'Keep them' first; a mashed A releases forever")
	else:
		print("the farewell question opens with nothing spent, focus on the safe answer")


func _check_keeping_backs_out() -> void:
	# The B route first…
	await _press("menu_cancel")
	if str(_tab.get("_release_stage")) != "choose":
		_fail("menu_cancel did not back out of the farewell question")
		return
	# …then the button route.
	await _press("ui_accept")  # re-open on the newcomer, still focused
	if str(_tab.get("_release_stage")) != "confirm":
		_fail("could not reopen the farewell question for the keep-button half")
		return
	await _press("ui_accept")  # 'Keep them' holds focus
	if str(_tab.get("_release_stage")) != "choose":
		_fail("the 'Keep them' button did not back out of the farewell question")
	if int(_party.call("size")) != 5 or _game.get("pending_catch") == null:
		_fail("backing out of the farewell question changed the party or consumed the catch")
	else:
		print("keeping backs out both ways — B and the button — with nothing spent")


func _check_releasing_a_belt_member_resolves() -> void:
	var released: RefCounted = _keepers[1]
	(_tab.get("_rows")[1] as Button).grab_focus()
	await process_frame
	await _press("ui_accept")
	if str(_tab.get("_release_stage")) != "confirm":
		_fail("pressing belt row 1 did not open the farewell question")
		return
	var body_label: Label = _tab.get("_farewell_body")
	if body_label != null and body_label.text.find("Lv ") < 0:
		_fail("the farewell question for a belt member does not restate what is being given up")

	await _press("ui_down")  # Keep them -> Let them go
	if _focused_control() != _tab.get("_farewell_release"):
		_fail("ui_down did not reach the 'Let them go' button")
		return
	await _press("ui_accept")

	if str(_tab.get("_release_stage")) != "done":
		_fail("confirming the release did not reach the goodbye beat")
		return
	if int(_party.call("size")) != 5:
		_fail("the resolved party holds %d, not 5" % int(_party.call("size")))
	if _game.get("pending_catch") != null:
		_fail("the release resolved but the catch is still on the seam")
	var members: Array = _party.call("members")
	if members.has(released):
		_fail("the released creature is still in the party")
	if not members.has(_newcomer):
		_fail("the newcomer never joined the party after the release")
	elif _party.call("at", 4) != _newcomer:
		_fail("the newcomer is in the party but not in the freed last holder")
	else:
		print("releasing a belt member: released gone for good, newcomer on the belt, five exactly")


func _check_the_goodbye_beat_ends_on_the_new_belt() -> void:
	var title: Label = _tab.get("_farewell_title")
	if title == null or title.text.find("goes free") < 0:
		_fail("the goodbye beat does not say who went free (shows '%s')" % (title.text if title != null else ""))
	if _focused_control() != _tab.get("_farewell_done"):
		_fail("the goodbye beat did not focus its own close button")
	await _press("ui_accept")
	if str(_tab.get("_release_stage")) != "":
		_fail("closing the goodbye beat did not end the ceremony")
		return
	var pending_wrap: Control = _tab.get("_pending_wrap")
	if pending_wrap != null and pending_wrap.visible:
		_fail("the newcomer's row is still on screen after the ceremony")
	# The shell is alive again: the same button that could not close the menu
	# mid-ceremony closes it now.
	await _press("menu_cancel")
	if bool(_menu.call("is_open")):
		_fail("the menu cannot be closed after the ceremony ended")
	elif paused:
		_fail("the tree is still paused after the ceremony ended and the menu closed")
	else:
		print("the ceremony ends on the new belt and gives the menu back")


## The other honest answer: the newcomer was not worth a holder. The belt must
## come through unchanged.
func _check_a_second_squeeze_can_release_the_newcomer() -> void:
	var second: RefCounted = _game.call("make_creature", "terrapup", "Second")
	_game.set("pending_catch", second)
	for i in WATCH_FRAMES:
		await process_frame
		if bool(_menu.call("is_open")):
			break
	for i in 6:
		await process_frame
	if str(_tab.get("_release_stage")) != "choose":
		_fail("a second squeeze did not restart the ceremony")
		return
	var before: Array = _party.call("members")

	await _press("ui_accept")  # focus starts on the newcomer's row
	if str(_tab.get("_release_stage")) != "confirm":
		_fail("could not open the farewell question on the second newcomer")
		return
	var body_label: Label = _tab.get("_farewell_body")
	if body_label != null and body_label.text.find("never on the belt") < 0:
		_fail("the newcomer's farewell question reads like a belt member's")
	await _press("ui_down")
	await _press("ui_accept")

	if str(_tab.get("_release_stage")) != "done":
		_fail("releasing the newcomer did not reach the goodbye beat")
		return
	if _game.get("pending_catch") != null:
		_fail("releasing the newcomer left the catch on the seam")
	if _party.call("members") != before:
		_fail("releasing the newcomer changed the belt")
	else:
		print("releasing the newcomer instead: the belt comes through untouched")
	await _press("ui_accept")
	await _press("menu_cancel")


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


func _focused_control() -> Control:
	var viewport := root.get_viewport()
	return viewport.gui_get_focus_owner() if viewport != null else null


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("release ceremony smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)
