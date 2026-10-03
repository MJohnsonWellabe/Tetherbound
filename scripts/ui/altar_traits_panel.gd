extends CanvasLayer

const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const TRAITS := preload("res://scripts/creatures/traits.gd")
const TOKENS := preload("res://scripts/ui/ui_tokens.gd")
const SCREEN := preload("res://scripts/ui/system_screen.gd")
var _service: Node
var _station := ""
var _root: PanelContainer
var _body: VBoxContainer
var _status: Label
var _creature: OptionButton
var _seed: OptionButton
var _slot: OptionButton
var _payment: OptionButton
var _distil: OptionButton
var _teach: Button
var _release: Button
var _quote: Dictionary = {}
var _shown := false
var _closing := false
var _mouse_before := Input.MOUSE_MODE_VISIBLE
var return_to := Callable()
var _opened_context: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	add_to_group(INPUT_OWNER.GROUP)
	_root = PanelContainer.new()
	var candidate: bool = SCREEN.config().get("enabled") == true
	if candidate:
		_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var inset := int(SCREEN.config().get("safe_margin", 48))
		_root.offset_left = inset
		_root.offset_top = inset
		_root.offset_right = -inset
		_root.offset_bottom = -inset
		_root.theme = load("res://assets/ui/theme/tetherbound_theme.tres")
		_root.add_theme_stylebox_override("panel", TOKENS.panel_box(TOKENS.BG_DEEP, TOKENS.BORDER))
	else:
		_root.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		_root.position = Vector2(100,60)
		_root.custom_minimum_size = Vector2(700,640)
	add_child(_root)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if not candidate: scroll.custom_minimum_size = Vector2(700,640)
	scroll.follow_focus = true
	_root.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation",12)
	scroll.add_child(_body)
	_line("Altar · Traits and Seeds",TOKENS.FONT_TITLE if candidate else 26)
	_line("Teach your companions. Releasing a caught creature is permanent.",20)
	_creature = _choice("Companion")
	_creature.item_selected.connect(func(_index: int) -> void: _refresh())
	_status = _line("",20)
	_seed = _choice("Trait Seed")
	_slot = _choice("Taught slot · old trait is destroyed")
	_payment = _choice("Pay with type essence")
	_teach = _button("Teach chosen seed",_submit_teach)
	_distil = _choice("One trait to distil when releasing")
	_release = _button("Release companion and distil chosen trait",_submit_release)
	_button("Back",close)
	_root.hide()

func _line(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",maxi(size,TOKENS.FONT_READ) if SCREEN.config().get("enabled") == true else size)
	_body.add_child(label)
	return label

func _choice(title: String) -> OptionButton:
	_line(title,20)
	var button := OptionButton.new()
	button.custom_minimum_size.y = 66 if SCREEN.config().get("enabled") == true else 38
	button.add_theme_font_size_override("font_size",TOKENS.FONT_PROMPT if SCREEN.config().get("enabled") == true else 20)
	_body.add_child(button)
	return button

func _button(title: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.add_theme_font_size_override("font_size",TOKENS.FONT_PROMPT if SCREEN.config().get("enabled") == true else 20)
	button.custom_minimum_size.y = 66 if SCREEN.config().get("enabled") == true else 40
	button.pressed.connect(callback)
	_body.add_child(button)
	return button

func open(service: Node, station_key: String) -> bool:
	if not is_instance_valid(service) or _closing or (not _shown and INPUT_OWNER.current(get_tree()) != null): return false
	for method: String in ["quote","submit","busy","creature_choices"]:
		if not service.has_method(method): return false
	if not service.has_signal("action_completed"): return false
	if is_instance_valid(_service) and _service != service and _service.is_connected("action_completed",_completed):
		_service.disconnect("action_completed",_completed)
	if is_instance_valid(_service) and _service != service and _service.has_signal("quote_updated") and _service.is_connected("quote_updated", _quote_updated):
		_service.disconnect("quote_updated", _quote_updated)
	_service = service
	_station = station_key
	if not _service.is_connected("action_completed",_completed): _service.connect("action_completed",_completed)
	if _service.has_signal("quote_updated") and not _service.is_connected("quote_updated", _quote_updated):
		_service.connect("quote_updated", _quote_updated)
	var previous_uid := str(_selected(_creature)) if _creature.item_count > 0 else ""
	_creature.clear()
	for row: Dictionary in _service.call("creature_choices"):
		_creature.add_item(row.name)
		_creature.set_item_metadata(_creature.item_count-1,row.uid)
		if row.uid == previous_uid: _creature.select(_creature.item_count-1)
	if _creature.item_count == 0: return false
	if not _shown:
		_opened_context = SCREEN.character_context(get_node_or_null(^"/root/Game"))
		_mouse_before = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		INPUT_OWNER.set_world_hud_visible(get_tree(),false)
	_shown = true
	_closing = false
	_root.show()
	_refresh()
	_creature.grab_focus()
	return true

func close() -> void:
	if not _shown: return
	INPUT_OWNER.suppress_pause_reopen(get_tree())
	_shown = false
	_closing = true
	_root.hide()
	_release_presentation()

func _release_presentation() -> void:
	if not is_inside_tree(): return
	remove_from_group(INPUT_OWNER.GROUP)
	if INPUT_OWNER.current(get_tree()) == null:
		Input.mouse_mode = _mouse_before
		INPUT_OWNER.set_world_hud_visible(get_tree(),true)
	add_to_group(INPUT_OWNER.GROUP)

func _exit_tree() -> void:
	if _shown:
		_shown = false
		_closing = false
		_release_presentation()
	if is_instance_valid(_service) and _service.is_connected("action_completed",_completed):
		_service.disconnect("action_completed",_completed)
	if is_instance_valid(_service) and _service.has_signal("quote_updated") and _service.is_connected("quote_updated", _quote_updated):
		_service.disconnect("quote_updated", _quote_updated)

func _quote_updated(station_key: String, uid: String) -> void:
	if _shown and station_key == _station and uid == str(_selected(_creature)):
		_refresh()

func owns_input() -> bool:
	return _shown or _closing

func _process(_delta: float) -> void:
	if _shown and SCREEN.character_context(get_node_or_null(^"/root/Game")) != _opened_context:
		return_to = Callable()
		close()
	if _closing and not Input.is_action_pressed("ui_cancel") and not Input.is_action_pressed("menu_cancel") and not Input.is_action_pressed("ui_accept"):
		_closing = false
		if return_to.is_valid(): return_to.call_deferred()

func _unhandled_input(event: InputEvent) -> void:
	if _shown and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("menu_cancel")):
		close()
		get_viewport().set_input_as_handled()

func _selected(button: OptionButton) -> Variant:
	return button.get_item_metadata(button.selected) if button.selected >= 0 else null

func _refresh() -> void:
	if not _shown: return
	_release.text = "Release companion and distil chosen trait"
	if _release.has_meta("confirmed_uid"): _release.remove_meta("confirmed_uid")
	_quote = _service.call("quote",_station,str(_selected(_creature)))
	for button: OptionButton in [_seed,_slot,_payment,_distil]: button.clear()
	_teach.disabled = true
	_release.disabled = true
	if _quote.get("ok") != true:
		_status.text = "Traits unavailable: %s" % _quote.get("code","authority_missing")
		return
	var text: Array[String] = []
	for row: Dictionary in _quote.get("traits",[]): text.append("%s (%s): %s" % [row.display_name,row.rarity,row.description])
	_status.text = "\n".join(text) if not text.is_empty() else "No active traits"
	for row: Dictionary in _quote.get("seeds",[]):
		_seed.add_item("%s · %s · %s" % [row.display_name,row.rarity,row.description])
		_seed.set_item_metadata(_seed.item_count-1,row.id)
	for slot: int in _quote.get("unlocked_slots",[]):
		var old: String = _quote.get("taught_traits",{}).get(str(slot),"")
		_slot.add_item("Slot %s · %s · %s essence" % [slot,"empty" if old == "" else TRAITS.definition(old).get("display_name",old),slot*int(_quote.essence_cost_per_slot)])
		_slot.set_item_metadata(_slot.item_count-1,slot)
	for item: String in _quote.get("payment_items",[]):
		_payment.add_item(item.trim_prefix("essence_").capitalize()+" Essence")
		_payment.set_item_metadata(_payment.item_count-1,item)
	_distil.add_item("Essence only")
	_distil.set_item_metadata(0,"")
	for row: Dictionary in _quote.get("traits",[]):
		_distil.add_item("%s · %s" % [row.display_name,row.rarity])
		_distil.set_item_metadata(_distil.item_count-1,row.id)
	_teach.disabled = _seed.item_count == 0 or _slot.item_count == 0 or _payment.item_count == 0 or _service.call("busy")
	_release.disabled = _quote.get("release_allowed") != true or _service.call("busy")

func _intent(action: String, trait_id: String, slot: int, payment: String) -> Dictionary:
	var random := Crypto.new().generate_random_bytes(16)
	return {"action_id":"trait-"+random.hex_encode(),"action":action,
		"creature_uid":str(_selected(_creature)),"trait_id":trait_id,"slot":slot,
		"payment_item":payment,"expected_character_revision":_quote.expected_character_revision}

func _submit_teach() -> void:
	if _teach.disabled: return
	_submit(_intent("teach",str(_selected(_seed)),int(_selected(_slot)),str(_selected(_payment))))

func _submit_release() -> void:
	if _release.disabled: return
	# Explicit named second tap confirms a permanent roster removal.
	if not _release.has_meta("confirmed_uid") or _release.get_meta("confirmed_uid") != _selected(_creature):
		_release.set_meta("confirmed_uid",_selected(_creature))
		_release.text = "Release %s? This can't be undone. A confirms; B leaves." % _creature.get_item_text(_creature.selected)
		return
	_release.remove_meta("confirmed_uid")
	_submit(_intent("release",str(_selected(_distil)),-1,""))

func _submit(request: Dictionary) -> void:
	_teach.disabled = true
	_release.disabled = true
	_status.text = "Saving trait transaction…"
	_service.call("submit",_station,request)

func _completed(result: Dictionary) -> void:
	if not _shown: return
	if result.get("ok") == true:
		open(_service,_station)
	else:
		_status.text = "Waiting for owner save and acknowledgement" if result.get("recoverable") == true else "Action refused: %s" % result.get("code","unavailable")
		if not _service.call("busy"): _refresh()
