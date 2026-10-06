extends Control
## Controller-first ordinary-input adapter; no optimistic mutation or receipt
## acknowledgement. A retry retains its original craft ID until reconciliation.
const INPUT := preload("res://scripts/ui/input_owner.gd")
const BREAKTHROUGH := preload("res://scripts/creatures/breakthrough.gd")
const EVOLUTION := preload("res://scripts/creatures/evolution.gd")
var _service: Node
var _source: Node
var _mode := ""
var _master := ""
var _list: VBoxContainer
var _message: Label
var _craft_id := ""
var _recipe := ""
var _pending_action := ""
var _pending_intent: Dictionary = {}
var _duel_generation := 0
var _preparing_duel := false

func _ready() -> void:
	add_to_group(INPUT.GROUP)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.06, 0.09, 0.12, 0.96)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(80, 60)
	scroll.size = Vector2(1050, 570)
	add_child(scroll)
	_list = VBoxContainer.new()
	_list.custom_minimum_size = Vector2(1000, 500)
	scroll.add_child(_list)
	_message = Label.new()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.custom_minimum_size.x = 850
	_message.position = Vector2(80, 650)
	add_child(_message)
	hide()

func owns_input() -> bool:
	return visible

func is_open() -> bool:
	return visible

func open(service: Node, mode: String, source: Node, master_id: String) -> void:
	if INPUT.current(get_tree()) != null and INPUT.current(get_tree()) != self: return
	_service = service
	_cancel_duel_preparation()
	_source = source
	_mode = mode
	_master = master_id
	show()
	_rebuild()

func _rebuild() -> void:
	for node: Node in _list.get_children():
		_list.remove_child(node)
		node.queue_free()
	_message.text = ""
	var title := Label.new()
	title.text = {"duel": "Choose your one creature · No switching · Retry any loss", "cook": "Kitchen · Cook an Ascension Feast", "feed": "Feed one creature · Lift its cap"}.get(_mode, "")
	_list.add_child(title)
	if _mode == "cook" and _service.has_method("retained_transaction"):
		var retained: Dictionary = _service.call("retained_transaction", ["feast_cook"])
		if not retained.is_empty():
			_button("Retry original transaction", func() -> void: _retry_retained_feast(retained.intent))
	var state: Dictionary = _service.call("view")
	if state.is_empty():
		_message.text = "Character transaction reconciliation is not ready."
	elif _mode == "duel":
		for card: Dictionary in state.get("party", []):
			var uid := str(card.uid)
			_button("%s · Lv %d" % [str(card.get("nickname", card.species_id)), int(card.level)],
				func() -> void: _duel(uid), bool(card.get("fainted", false)) or bool(card.get("resting", false)))
	elif _mode == "cook":
		for id: String in BREAKTHROUGH.feasts().get("recipes", {}):
			var row: Dictionary = BREAKTHROUGH.feasts().recipes[id]
			if not state.redesign_character.feast_recipes.has(row.feast_id): continue
			_button(str(row.name) + " · " + str(row.cost), func() -> void: _cook(id))
		_button("Feed creatures", _open_feed_from_kitchen)
	else:
		for card: Dictionary in state.get("party", []):
			var uid := str(card.uid)
			var mirror: Dictionary = state.redesign_character.creatures.get(uid, {})
			var label := "%s · %s" % [str(card.get("nickname", card.species_id)), BREAKTHROUGH.status(card, mirror)]
			for stack: Variant in state.get("inventory", []):
				if not stack is Dictionary: continue
				var item := str(stack.id)
				var def: Dictionary = BREAKTHROUGH.feasts().items.get(item, {})
				if def.get("kind") != "ascension_feast" or int(def.breaks_level) != int(card.level): continue
				var planning := card.duplicate(true)
				planning.evolution_choices = mirror.get("evolution_choices", {}).duplicate(true)
				var offer: Dictionary = EVOLUTION.feast_offer(planning, int(def.tier))
				if offer.get("choice_required", false):
					_button(label + " · " + def.name + " · Stay (permanent this tier)", func() -> void: _feed(uid, item, "stay"))
					for branch: Dictionary in offer.get("branches", []):
						if str(branch.get("extra_ingredient", "")) != str(def.get("catalyst", "")): continue
						var target := str(branch.get("target", branch.get("to_species", "")))
						_button(label + " · Evolve to " + target, func() -> void: _feed(uid, item, "evolve"))
					continue
				_button(label + " · " + def.name, func() -> void: _feed(uid, item, ""))
	_button("Back", close)
	for node: Node in _list.get_children():
		if node is Button and not node.disabled:
			node.grab_focus()
			break

func _button(label: String, action: Callable, disabled: bool = false) -> void:
	var button := Button.new()
	button.text = label
	button.disabled = disabled
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(action)
	_list.add_child(button)

func _cook(recipe: String) -> void:
	if _pending_action == "feast_cook":
		_send(_pending_action, _pending_intent.duplicate(true))
		return
	if _recipe != recipe or _craft_id.is_empty():
		_recipe = recipe
		_craft_id = Crypto.new().generate_random_bytes(16).hex_encode()
	_send("feast_cook", {"recipe_id": recipe, "craft_id": _craft_id})

func _open_feed_from_kitchen() -> void:
	# Presentation transition only. The same bound service reads the owner's
	# actual feast stacks and submits the existing typed personal feed action.
	if _mode != "cook" or not is_instance_valid(_service) or not _service.has_method("open_feed"): return
	_service.call("open_feed")

func _retry_retained_feast(original: Dictionary) -> void:
	if not original.get("recipe_id") is String or not original.get("craft_id") is String: return
	_recipe = original.recipe_id
	_craft_id = original.craft_id
	_send("feast_cook", original.duplicate(true))

func _feed(uid: String, item: String, choice: String) -> void:
	_send("feast_feed", {"creature_uid": uid, "feast_item": item, "choice": choice})

func _duel(uid: String) -> void:
	if not visible or _mode != "duel" or _preparing_duel or not _pending_action.is_empty(): return
	var generation := _duel_generation
	var service := _service
	var source := _source
	var intent := {"master_id": _master, "creature_uid": uid}
	_preparing_duel = true
	_message.text = "Calling out your chosen companion…"
	var result: Dictionary = await service.call("prepare_duel", uid, source)
	if generation != _duel_generation or not visible or _mode != "duel" \
			or not is_instance_valid(service) or service != _service or source != _source: return
	_preparing_duel = false
	if result.get("ok") != true:
		_message.text = str(result.get("reason", result.get("code", "Deployment refused.")))
		return
	_send("master_duel", intent)

func _send(op: String, intent: Dictionary) -> void:
	if not _pending_action.is_empty() and (op != _pending_action or intent != _pending_intent):
		_message.text = "Waiting for your original character transaction to save."
		return
	_pending_action = op
	_pending_intent = intent.duplicate(true)
	var result: Dictionary = _service.call("submit", op, intent, _source)
	_message.text = str(result.get("reason", result.get("code", "Awaiting durable character save…")))
	# Admission starts combat; it is not a saved Master win. Release this
	# chooser once the actual producer returned a real encounter identity so
	# its input ownership cannot hold the newly started fight behind a menu.
	if op == "master_duel" and result.get("ok") == true \
		and result.get("encounter_id") is String and not result.encounter_id.is_empty():
		_pending_action = ""
		_pending_intent = {}
		close()
		return
	accept_completion(op, intent, result)

## The authenticated producer emits this only after the existing owner-save
## settlement. An unrelated or delayed transaction must never clear the ID
## belonging to the next cook; retries keep their original immutable intent.
func accept_completion(action: String, original: Dictionary, result: Dictionary) -> bool:
	if action == _pending_action and original == _pending_intent \
			and result.get("ok") == false and result.get("terminal_refusal") == true:
		_pending_action = ""
		_pending_intent = {}
		if action == "feast_cook": _craft_id = ""
		if is_instance_valid(_message): _message.text = str(result.get("reason", result.get("code", "Character transaction refused.")))
		return true
	if action != _pending_action or original != _pending_intent \
			or result.get("ok") != true or result.get("settled") != true \
			or result.get("durable") != true or result.get("owner_saved") != true \
			or result.get("owner_acknowledged") != true:
		return false
	_pending_action = ""
	_pending_intent = {}
	if action == "feast_cook": _craft_id = ""
	if visible:
		if _mode == "duel": close()
		else: _rebuild()
	return true

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()

func _cancel_duel_preparation() -> void:
	_duel_generation += 1
	_preparing_duel = false
	if _pending_action == "master_duel":
		_pending_action = ""
		_pending_intent = {}

func close() -> void:
	_cancel_duel_preparation()
	INPUT.suppress_pause_reopen(get_tree())
	hide()
