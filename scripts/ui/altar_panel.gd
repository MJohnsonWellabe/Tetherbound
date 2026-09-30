extends CanvasLayer

## F27 chosen leveling. Foundation injects the typed host station service.
## This surface never debits inventory, changes a level or persists a receipt.
## Required service contract:
## station_available(station_key) -> bool (actual registered Altar/reach)
## quote_essence_spend(station_key, owned_uid) -> Dictionary (display only)
## submit_essence_spend(station_key, request) -> void
## essence_spend_completed(spend_id, result) after owner state promotion.
## Pending rebind also requires reconcile_essence_spend(spend_id): query the
## same original admitted character's durable decision, never submit a new id.
## Completion requires resolved:true for a final saved promotion or a known
## refusal. Unknown/in-flight/owner-save recovery remains resolved:false.
## Quote: ok, creature_uid, level, cap, expected_character_revision,
## payments:[{id, name, cost, available}]. Never submit quoted cost/balance/cap.
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const TOKENS := preload("res://scripts/ui/ui_tokens.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const READOUT := preload("res://scripts/ui/creature_training_readout.gd")
const PARTY := preload("res://autoload/party.gd")

var _service: Node = null
var _station_key := ""
var _creature_uid := ""
var _pending_id := ""
var _quote: Dictionary = {}
var _quote_code := "quote_unavailable"
var _pending_durable := false
var _open := false
var _closing := false
var _status := "Choose who grows, then choose their essence or a Tether Candy."
var _root: Control = null
var _mouse_before: int = Input.MOUSE_MODE_CAPTURED


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	add_to_group(INPUT_OWNER.GROUP)
	visible = false


func configure_service(service: Node) -> bool:
	if (_open and _pending_id.is_empty()) or not is_instance_valid(service): return false
	for method: String in ["station_available", "quote_essence_spend", "submit_essence_spend", "reconcile_essence_spend"]:
		if not service.has_method(method): return false
	if not service.has_signal("essence_spend_completed"): return false
	if _open: close()
	if is_instance_valid(_service) and _service.is_connected("essence_spend_completed", _on_completed):
		_service.disconnect("essence_spend_completed", _on_completed)
	_service = service
	if not _service.is_connected("essence_spend_completed", _on_completed):
		_service.connect("essence_spend_completed", _on_completed)
	if not _pending_id.is_empty():
		# Connect before asking: recovery may complete synchronously. The id and
		# original intent stay intact until this exact transaction resolves.
		_service.call("reconcile_essence_spend", _pending_id)
	return true


func open(station_key: String) -> bool:
	if not is_inside_tree() or _open or _closing or not _pending_id.is_empty() \
			or INPUT_OWNER.current(get_tree()) != null or not _station_available(station_key): return false
	var party := _party()
	if party == null or int(party.call("size")) < 1 or int(party.call("size")) > PARTY.MAX_CREATURES: return false
	var first: RefCounted = party.call("at", 0)
	if first == null: return false
	_station_key = station_key
	_creature_uid = str(first.get("uid"))
	_status = "Choose who grows, then choose their essence or a Tether Candy."
	_mouse_before = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_open = true
	visible = true
	INPUT_OWNER.set_world_hud_visible(get_tree(), false)
	_refresh_quote()
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
	_release_presentation()
	# An in-flight request keeps its id. Closing cannot undo host promotion.


func _release_presentation() -> void:
	if not is_inside_tree(): return
	# Exclude this closing surface when deciding whether another modal owns HUD.
	remove_from_group(INPUT_OWNER.GROUP)
	if INPUT_OWNER.current(get_tree()) == null:
		Input.mouse_mode = _mouse_before
		INPUT_OWNER.set_world_hud_visible(get_tree(), true)
	add_to_group(INPUT_OWNER.GROUP)


func _exit_tree() -> void:
	if _open:
		_open = false
		_closing = false
		_release_presentation()
	if is_instance_valid(_service) and _service.is_connected("essence_spend_completed", _on_completed):
		_service.disconnect("essence_spend_completed", _on_completed)


func _process(_delta: float) -> void:
	if _closing and not Input.is_action_pressed("menu_cancel") and not Input.is_action_pressed("ui_cancel"):
		_closing = false
	if _open and not _station_available(_station_key): close()


func _unhandled_input(event: InputEvent) -> void:
	if not _open: return
	if event.is_action_pressed("menu_cancel") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _station_available(station_key: String) -> bool:
	if not is_instance_valid(_service): return false
	var available: Variant = _service.call("station_available", station_key)
	return available is bool and available == true


func _party() -> RefCounted:
	var game := get_node_or_null(^"/root/Game")
	return game.get("party") if game != null else null


func _creature() -> RefCounted:
	var party := _party()
	if party != null:
		for creature: RefCounted in party.call("members"):
			if str(creature.get("uid")) == _creature_uid: return creature
	return null


func _refresh_quote() -> void:
	_quote = {}
	_quote_code = "station_unavailable"
	if not _station_available(_station_key) or _creature() == null: return
	var raw: Variant = _service.call("quote_essence_spend", _station_key, _creature_uid)
	if raw is Dictionary and raw.get("ok") is bool and raw.ok == true and raw.get("creature_uid") == _creature_uid \
			and raw.get("payments") is Array and raw.payments.size() <= 3 and ESSENCE._integer(raw.get("level"), 1, 60) \
			and ESSENCE._integer(raw.get("cap"), 1, 60) \
			and ESSENCE._integer(raw.get("expected_character_revision"), 0, 2147483646) \
			and int(raw.level) <= int(raw.cap):
		var seen := {}
		for payment: Variant in raw.payments:
			if not _valid_payment(payment) or seen.has(payment.id):
				_quote_code = "quote_unavailable"
				return
			seen[payment.id] = true
		if int(raw.level) < int(raw.cap) and raw.payments.is_empty():
			_quote_code = "quote_unavailable"
			return
		_quote = raw.duplicate(true)
		for field: String in ["level", "cap", "expected_character_revision"]: _quote[field] = int(_quote[field])
		_quote_code = ""
	elif raw is Dictionary:
		_quote_code = str(raw.get("code", "quote_unavailable"))
	else:
		_quote_code = "quote_unavailable"


func _message(code: String) -> String:
	if is_instance_valid(_service) and _service.has_method("refusal_text"):
		return str(_service.call("refusal_text", code))
	return "Leveling is unavailable for this companion. Your choice has not been confirmed."


func _button(parent: Node, text: String, callback: Callable, enabled: bool = true) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.add_theme_font_size_override("font_size", TOKENS.FONT_BODY)
	button.disabled = not enabled or not _pending_id.is_empty()
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _label(parent: Node, text: String, size: int = TOKENS.FONT_BODY) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label


func _rebuild(prefer_payment: bool = false) -> void:
	var focus_key := ""
	var focused: Control = get_viewport().gui_get_focus_owner()
	if is_instance_valid(focused) and _root != null and _root.is_ancestor_of(focused):
		focus_key = str(focused.get_meta("altar_focus_key", ""))
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
	_label(layout, "Altar · Chosen leveling", TOKENS.FONT_TITLE)
	_label(layout, _status)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 24)
	layout.add_child(columns)
	var roster := VBoxContainer.new()
	roster.custom_minimum_size.x = 240
	columns.add_child(roster)
	var party := _party()
	var first: Button = null
	var selected_roster: Button = null
	var roster_buttons: Array[Button] = []
	var payment_buttons: Array[Button] = []
	var first_payment: Button = null
	if party != null:
		for creature: RefCounted in party.call("members"):
			var uid := str(creature.get("uid"))
			var button := _button(roster, "%s · Level %d" % [str(creature.call("label")), int(creature.get("level"))], _select_creature.bind(uid))
			button.set_meta("altar_focus_key", "creature:" + uid)
			roster_buttons.append(button)
			if uid == _creature_uid: selected_roster = button
			if first == null: first = button
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	columns.add_child(scroll)
	var choices := VBoxContainer.new()
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices.add_theme_constant_override("separation", 8)
	scroll.add_child(choices)
	var selected := _creature()
	if selected == null:
		_label(choices, "That companion is no longer in your team.")
	elif _quote.is_empty():
		_label(choices, _message(_quote_code))
	else:
		_label(choices, "%s · Level %d / cap %d" % [str(selected.call("label")), int(_quote.level), int(_quote.cap)], TOKENS.FONT_HEADING)
		if int(_quote.level) >= int(_quote.cap):
			_label(choices, "Current ceiling · Level 60 is the highest tier this journey." if int(_quote.cap) == 60 else "Breakthrough needed · Reach the next tier with an Ascension Feast.")
		else:
			_label(choices, "Raise to level %d. Each payment raises one level." % (int(_quote.level) + 1))
			for payment: Variant in _quote.payments:
				if not _valid_payment(payment): continue
				var cost := int(payment.cost)
				var available := int(payment.available)
				var enough := available >= cost
				var text := "%s · Cost %d · Have %d%s" % [str(payment.name), cost, available, "" if enough else " · Need more"]
				var button := _button(choices, text, _spend.bind(str(payment.id)), enough)
				button.set_meta("altar_focus_key", "payment:" + str(payment.id))
				payment_buttons.append(button)
				if enough and first_payment == null: first_payment = button
	if selected != null:
		var game := get_node_or_null(^"/root/Game")
		var player: RefCounted = game.get("local") if game != null else null
		var readout := READOUT.inspect_owned(player, selected)
		if not str(readout.essence_text).is_empty(): _label(choices, readout.essence_text)
		if not str(readout.trait_text).is_empty(): _label(choices, readout.trait_text)
	_label(layout, "A Choose / Raise level · B Leave")
	TOKENS.make_text_legible(_root)
	_wire_focus(roster_buttons, payment_buttons, selected_roster)
	if selected_roster != null: first = selected_roster
	if prefer_payment and first_payment != null: first = first_payment
	else:
		for button: Button in roster_buttons + payment_buttons:
			if not button.disabled and str(button.get_meta("altar_focus_key", "")) == focus_key:
				first = button
				break
	if first != null and not first.disabled: first.call_deferred("grab_focus")


func _wire_focus(roster: Array[Button], payments: Array[Button], selected: Button) -> void:
	var enabled_roster: Array[Button] = []
	var enabled_payments: Array[Button] = []
	for button: Button in roster:
		if not button.disabled: enabled_roster.append(button)
	for button: Button in payments:
		if not button.disabled: enabled_payments.append(button)
	var roster_target: Button = selected if selected != null and not selected.disabled else (enabled_roster[0] if not enabled_roster.is_empty() else null)
	var payment_target: Button = enabled_payments[0] if not enabled_payments.is_empty() else null
	for column: Array in [enabled_roster, enabled_payments]:
		for index: int in column.size():
			var button: Button = column[index]
			button.focus_neighbor_top = button.get_path_to(column[(index + column.size() - 1) % column.size()])
			button.focus_neighbor_bottom = button.get_path_to(column[(index + 1) % column.size()])
			button.focus_previous = button.focus_neighbor_top
			button.focus_next = button.focus_neighbor_bottom
			button.focus_neighbor_left = button.get_path_to(roster_target if column == enabled_payments and roster_target != null else button)
			button.focus_neighbor_right = button.get_path_to(payment_target if column == enabled_roster and payment_target != null else button)



func _valid_payment(raw: Variant) -> bool:
	if not raw is Dictionary or not raw.get("id") is String or not raw.get("name") is String \
			or raw.name.is_empty() or not ESSENCE._integer(raw.get("cost"), 1, 2147483647) \
			or not ESSENCE._integer(raw.get("available"), 0, 2147483647): return false
	if raw.id == "tether_candy": return int(raw.cost) == 1
	var creature := _creature()
	if creature == null: return false
	for type_id: String in [str(creature.get("creature_type")), str(creature.get("secondary_type"))]:
		if not type_id.is_empty() and raw.id == ESSENCE.essence_item(type_id): return true
	return false


func _select_creature(uid: String) -> void:
	if not _pending_id.is_empty(): return
	_creature_uid = uid
	_refresh_quote()
	_rebuild(true)


func _spend(payment_item: String) -> void:
	if not _pending_id.is_empty() or _quote.is_empty() or not _station_available(_station_key): return
	var creature := _creature()
	if creature == null or int(creature.get("level")) != int(_quote.level):
		_status = "Your team changed. Choose the payment again."
		_refresh_quote()
		_rebuild()
		return
	var permitted := false
	for payment: Variant in _quote.payments:
		if _valid_payment(payment) and payment.id == payment_item and int(payment.available) >= int(payment.cost): permitted = true
	if not permitted or int(_quote.level) >= int(_quote.cap): return
	_pending_id = Crypto.new().generate_random_bytes(16).hex_encode()
	_pending_durable = false
	_status = "Waiting for the host to save this level. B leaves this screen."
	var request := {"spend_id": _pending_id, "creature_uid": _creature_uid,
		"expected_level": int(_quote.level), "payment_item": payment_item,
		"expected_character_revision": int(_quote.expected_character_revision)}
	_rebuild()
	_service.call("submit_essence_spend", _station_key, request)


func _on_completed(spend_id: String, result: Dictionary) -> void:
	if spend_id != _pending_id or _pending_id.is_empty(): return
	if result.get("durable") == true: _pending_durable = true
	var terminal := result.get("resolved") == true and result.get("ok") is bool
	if result.get("ok") == true and (result.get("saved") != true or result.get("durable") != true):
		terminal = false
	if result.get("ok") == false and _pending_durable: terminal = false
	if not terminal:
		_status = str(result.get("reason", _message(str(result.get("code", "awaiting_saved_decision")))))
		if _open: _rebuild()
		return
	_pending_id = ""
	_pending_durable = false
	_status = "Level raised and saved." if result.ok == true else str(result.get("reason", _message(str(result.get("code", "refused")))))
	if _open:
		_refresh_quote()
		_rebuild()
