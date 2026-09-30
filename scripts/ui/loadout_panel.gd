extends CanvasLayer

## Controller-first Loadout tab, reusable by the Altar and registered camps.
## No optimistic equips; service completion alone advances displayed slots.
const SERVICE := preload("res://scripts/creatures/loadout_service.gd")
const MOVES := preload("res://scripts/creatures/move_db.gd")
const MASTERY := preload("res://scripts/creatures/move_mastery.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const TOKENS := preload("res://scripts/ui/ui_tokens.gd")
var _service: Node = null
var _moves: RefCounted = null
var _station_key: String = ""
var _creature_uid: String = ""
var _slot: String = ""
var _pending_id: String = ""
var _open := false
var _closing := false
var _status: String = ""
var _root: Control = null
var _mouse_before: int = Input.MOUSE_MODE_CAPTURED

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	_moves = MOVES.load_default()
	_service = SERVICE.ensure(get_tree())
	_service.connect("completed", _on_completed)
	add_to_group(INPUT_OWNER.GROUP)
	visible = false

func open(station_key: String) -> bool:
	if _open or _closing or INPUT_OWNER.current(get_tree()) != null \
			or not bool(_service.call("station_available", station_key)): return false
	var game := get_node_or_null(^"/root/Game")
	var party: RefCounted = game.get("party") if game != null else null
	if party == null or int(party.call("size")) == 0 or int(party.call("size")) > 5: return false
	_station_key = station_key
	_creature_uid = str((party.call("at", 0) as RefCounted).get("uid"))
	_slot = ""
	_status = "Choose a slot, then a known move."
	_mouse_before = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_open = true
	visible = true
	INPUT_OWNER.set_world_hud_visible(get_tree(), false)
	_rebuild()
	return true

func is_open() -> bool: return _open
func owns_input() -> bool: return _open or _closing

func close() -> void:
	if not _open: return
	INPUT_OWNER.suppress_pause_reopen(get_tree())
	_open = false
	_closing = true
	visible = false
	Input.mouse_mode = _mouse_before
	INPUT_OWNER.set_world_hud_visible(get_tree(), true)

func _process(_delta: float) -> void:
	if _closing and not Input.is_action_pressed("menu_cancel") and not Input.is_action_pressed("ui_cancel"):
		_closing = false
	if _open and _pending_id.is_empty() and not bool(_service.call("station_available", _station_key)):
		close()

func _unhandled_input(event: InputEvent) -> void:
	if not _open: return
	if event.is_action_pressed("menu_cancel") or event.is_action_pressed("ui_cancel"):
		if _pending_id.is_empty():
			if not _slot.is_empty():
				_slot = ""
				_rebuild()
			else: close()
		get_viewport().set_input_as_handled()

func _creature() -> RefCounted:
	var game := get_node_or_null(^"/root/Game")
	var party: RefCounted = game.get("party") if game != null else null
	if party != null:
		for creature: RefCounted in party.call("members"):
			if str(creature.get("uid")) == _creature_uid: return creature
	return null

func _button(parent: Node, text: String, callback: Callable, enabled: bool = true) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.add_theme_font_size_override("font_size", TOKENS.FONT_BODY)
	button.disabled = not enabled or not _pending_id.is_empty()
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _rebuild() -> void:
	if _root != null:
		remove_child(_root)
		_root.queue_free()
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, .65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 36)
	_root.add_child(margin)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", TOKENS.panel_box(TOKENS.BG_PANEL, TOKENS.BORDER))
	margin.add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	panel.add_child(layout)
	var title := Label.new()
	title.text = "Loadout"
	title.add_theme_font_size_override("font_size", TOKENS.FONT_TITLE)
	layout.add_child(title)
	var status := Label.new()
	status.text = "Host pending…" if not _pending_id.is_empty() else _status
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(status)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 24)
	layout.add_child(columns)
	var party_column := VBoxContainer.new()
	party_column.custom_minimum_size.x = 240
	columns.add_child(party_column)
	var game := get_node_or_null(^"/root/Game")
	var party: RefCounted = game.get("party") if game != null else null
	var first: Button = null
	if party != null:
		for creature: RefCounted in party.call("members"):
			var uid := str(creature.get("uid"))
			var button := _button(party_column, str(creature.call("label")), _select_creature.bind(uid))
			if first == null: first = button
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	columns.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	var selected := _creature()
	if selected != null:
		if _slot.is_empty():
			for slot: String in ["quick", "charged", "utility"]:
				var move := str(selected.get("move_" + slot))
				var button := _button(list, "%s · %s" % [slot.capitalize(), _move_details(selected, move)], _select_slot.bind(slot))
				if slot == "quick": first = button
			var ultimate := str(selected.get("move_ultimate"))
			var fixed := Label.new()
			fixed.text = "Signature ultimate · " + (_move_details(selected, ultimate) if not ultimate.is_empty() else "Breakthrough needed")
			fixed.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			list.add_child(fixed)
		else:
			var first_move: Button = null
			if _slot == "utility": first = _button(list, "Unequip utility", _equip.bind(""))
			for move: String in selected.get("known_moves"):
				if str(_moves.call("slot", move)) != _slot: continue
				var button := _button(list, _move_details(selected, move), _equip.bind(move))
				if first_move == null: first_move = button
			if _slot != "utility" and first_move != null: first = first_move
	var hint := Label.new()
	hint.text = "A Choose / Equip · B Back / Leave · Edits save at this station"
	layout.add_child(hint)
	TOKENS.make_text_legible(_root)
	if first != null and _pending_id.is_empty(): first.call_deferred("grab_focus")

func _move_details(creature: RefCounted, move: String) -> String:
	if move.is_empty(): return "Empty"
	var row: Dictionary = _moves.call("move", move)
	return "%s · Rank %d · Power %g · Cost %g · Cooldown %gs · %s" % [
		str(_moves.call("display_name", move)), MASTERY.rank_for(creature, move),
		float(row.get("power", 0)), float(row.get("energy_cost", row.get("cost", 0))),
		float(row.get("cooldown", 0)), str(row.get("description", row.get("effect", "")))]

func _select_creature(uid: String) -> void:
	if not _pending_id.is_empty(): return
	_creature_uid = uid
	_slot = ""
	_rebuild()

func _select_slot(slot: String) -> void:
	if not _pending_id.is_empty(): return
	_slot = slot
	_rebuild()

func _equip(move: String) -> void:
	if not _pending_id.is_empty() or _slot.is_empty(): return
	var creature := _creature()
	if creature == null: close(); return
	var request := {"edit_id": Crypto.new().generate_random_bytes(16).hex_encode(),
		"creature_uid": _creature_uid, "expected_revision": int(creature.get("loadout_revision"))}
	for slot: String in ["quick", "charged", "utility"]: request[slot] = str(creature.get("move_" + slot))
	request[_slot] = move
	_pending_id = str(request.edit_id)
	_rebuild()
	_service.call("submit", _station_key, request)

func _on_completed(edit_id: String, result: Dictionary) -> void:
	if edit_id != _pending_id: return
	_pending_id = ""
	_slot = ""
	_status = "Equipped and saved." if bool(result.get("ok", false)) else "Not equipped: " + str(result.get("reason", "refused"))
	if _open: _rebuild()
