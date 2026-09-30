extends CanvasLayer

## F27 chosen leveling. Foundation injects the typed host station service.
## This surface never debits inventory, changes a level or persists a receipt.
## Required service contract:
## station_available(station_key) -> bool (actual registered Altar/reach)
## quote_essence_spend(station_key, owned_uid) -> Dictionary (display only)
## submit_essence_spend(station_key, request) -> void
## essence_spend_completed(spend_id, result) after owner state promotion.
## Quote: ok, creature_uid, level, cap, expected_character_revision,
## payments:[{id, name, cost, available}]. Never submit quoted cost/balance/cap.
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const TOKENS := preload("res://scripts/ui/ui_tokens.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const PARTY := preload("res://autoload/party.gd")

var _service: Node = null
var _station_key := ""
var _creature_uid := ""
var _pending_id := ""
var _quote: Dictionary = {}
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
	if _open or not _pending_id.is_empty() or not is_instance_valid(service): return false
	for method: String in ["station_available", "quote_essence_spend", "submit_essence_spend"]:
		if not service.has_method(method): return false
	if not service.has_signal("essence_spend_completed"): return false
	if is_instance_valid(_service) and _service.is_connected("essence_spend_completed", _on_completed):
		_service.disconnect("essence_spend_completed", _on_completed)
	_service = service
	if not _service.is_connected("essence_spend_completed", _on_completed):
		_service.connect("essence_spend_completed", _on_completed)
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
	return is_instance_valid(_service) and bool(_service.call("station_available", station_key))


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
	if not _station_available(_station_key) or _creature() == null: return
	var raw: Variant = _service.call("quote_essence_spend", _station_key, _creature_uid)
	if raw is Dictionary and bool(raw.get("ok", false)) and raw.get("creature_uid") == _creature_uid \
			and raw.get("payments") is Array and raw.get("level") is int \
			and raw.get("cap") is int and raw.get("expected_character_revision") is int:
		_quote = raw.duplicate(true)


func _button(parent: Node, text: String, callback: Callable, enabled: bool = true) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.add_theme_font_size_override("font_size", TOKENS.FONT_BODY)
	button.disabled = not enabled or not _pending_id.is_empty()
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
	_label(layout, "Altar · Chosen leveling", TOKENS.FONT_TITLE)
	_label(layout, "Waiting for host… B leaves this screen." if not _pending_id.is_empty() else _status)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 24)
	layout.add_child(columns)
	var roster := VBoxContainer.new()
	roster.custom_minimum_size.x = 240
	columns.add_child(roster)
	var party := _party()
	var first: Button = null
	if party != null:
		for creature: RefCounted in party.call("members"):
			var uid := str(creature.get("uid"))
			var button := _button(roster, "%s · Level %d" % [str(creature.call("label")), int(creature.get("level"))], _select_creature.bind(uid))
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
		_label(choices, "Leveling is unavailable. Your items and companion remain unchanged.")
	else:
		_label(choices, "%s · Level %d / cap %d" % [str(selected.call("label")), int(_quote.level), int(_quote.cap)], TOKENS.FONT_HEADING)
		if int(_quote.level) >= int(_quote.cap):
			_label(choices, "Breakthrough needed · Reach the next tier with an Ascension Feast.")
		else:
			_label(choices, "Raise to level %d. Each payment raises one level." % (int(_quote.level) + 1))
			var first_payment: Button = null
			for payment: Variant in _quote.payments:
				if not _valid_payment(payment): continue
				var cost := int(payment.cost)
				var available := int(payment.available)
				var enough := available >= cost
				var text := "%s · Cost %d · Have %d%s" % [str(payment.name), cost, available, "" if enough else " · Need more"]
				var button := _button(choices, text, _spend.bind(str(payment.id)), enough)
				if enough and first_payment == null: first_payment = button
			if first_payment != null: first = first_payment
	_label(layout, "A Choose / Raise level · B Leave · Spend saves at this Altar")
	TOKENS.make_text_legible(_root)
	if first != null and not first.disabled: first.call_deferred("grab_focus")


func _valid_payment(raw: Variant) -> bool:
	if not raw is Dictionary or not raw.get("id") is String or not raw.get("name") is String \
			or not raw.get("cost") is int or not raw.get("available") is int \
			or int(raw.cost) < 1 or int(raw.available) < 0: return false
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
	_rebuild()


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
	var request := {"spend_id": _pending_id, "creature_uid": _creature_uid,
		"expected_level": int(_quote.level), "payment_item": payment_item,
		"expected_character_revision": int(_quote.expected_character_revision)}
	_rebuild()
	_service.call("submit_essence_spend", _station_key, request)


func _on_completed(spend_id: String, result: Dictionary) -> void:
	if spend_id != _pending_id or _pending_id.is_empty(): return
	_pending_id = ""
	var reason := str(result.get("reason", result.get("code", "refused")))
	var messages := {"station_unavailable": "Return to the Altar outside combat to raise a level.",
		"station_missing": "The Altar is no longer here.", "insufficient_items": "You need more of that essence.",
		"breakthrough_needed": "This companion needs a breakthrough before another level.",
		"stale_level": "Your companion's level changed. Choose the payment again.",
		"stale_revision": "Your team or items changed. Choose the payment again.",
		"save_failed": "Couldn't save. Your items and companion remain unchanged.",
		"owner_save_failed": "Your character could not save the accepted change. Reconnect to recover it."}
	_status = "Level raised and saved." if bool(result.get("ok", false)) else str(messages.get(reason, "Couldn't raise that level. Refresh your team before trying again."))
	if _open:
		_refresh_quote()
		_rebuild()
