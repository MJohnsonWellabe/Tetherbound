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
## A guest's first view is an async request: the list built empty waits for it.
var _awaiting_view := false
## A guest's cook/feed refused only for the moment (its own earlier owner
## checkpoint, such as the cook just before this feed, is still settling) is
## sent again with the same original intent. Bounded; then the row is released
## with a retry message, so a press is never silently dropped.
const RETRY_CODES := ["owner_passive_original_pending", "owner_passive_prior_transaction_pending",
	"owner_passive_readmit_pending"]
const RETRY_SECONDS := 1.0
const RETRIES := 60
var _retries_left := 0
var _retry_wait := -1.0
## The scene the panel was opened in. Leaving it, or closing the panel, ends
## the resends: a feed never commits after the player has walked away.
var _retry_scene: WeakRef

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
	# Keep the focused row on screen; long cook/feed lists run past the view.
	scroll.follow_focus = true
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
	_retry_scene = weakref(_current_scene()) if _current_scene() != null else null
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
	_awaiting_view = state.is_empty()
	if state.is_empty():
		_message.text = "Character transaction reconciliation is not ready."
	elif _mode == "duel":
		var duel_names := party_labels(state.get("party", []))
		for index in (state.get("party", []) as Array).size():
			var card: Dictionary = state.party[index]
			var uid := str(card.uid)
			_button("%s · Lv %d" % [duel_names[index], int(card.level)],
				func() -> void: _duel(uid), bool(card.get("fainted", false)) or bool(card.get("resting", false)))
	elif _mode == "cook":
		for id: String in BREAKTHROUGH.feasts().get("recipes", {}):
			var row: Dictionary = BREAKTHROUGH.feasts().recipes[id]
			if not state.redesign_character.feast_recipes.has(row.feast_id): continue
			_button(str(row.name) + " · " + str(row.cost), func() -> void: _cook(id))
		_button("Feed creatures", _open_feed_from_kitchen)
	else:
		var feed_names := party_labels(state.get("party", []))
		for index in (state.get("party", []) as Array).size():
			var card: Dictionary = state.party[index]
			var uid := str(card.uid)
			var mirror: Dictionary = state.redesign_character.creatures.get(uid, {})
			var label := "%s · %s" % [feed_names[index], BREAKTHROUGH.status(card, mirror)]
			for stack: Variant in state.get("inventory", []):
				if not stack is Dictionary: continue
				var item := str(stack.id)
				var def: Dictionary = BREAKTHROUGH.feasts().items.get(item, {})
				if not feast_matches_current_cap(card, mirror, def): continue
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
	_link_focus()
	for node: Node in _list.get_children():
		if node is Button and not node.disabled:
			node.grab_focus()
			break

## Chain the rows explicitly so up/down always steps to the next enabled row,
## including rows scrolled out of view (spatial search stopped at the view).
func _link_focus() -> void:
	var rows: Array[Button] = []
	for node: Node in _list.get_children():
		if node is Button and not node.disabled and not node.is_queued_for_deletion():
			rows.append(node)
	for index in rows.size():
		var row := rows[index]
		row.focus_neighbor_top = row.get_path_to(rows[index - 1]) if index > 0 else NodePath(".")
		row.focus_neighbor_bottom = row.get_path_to(rows[index + 1]) if index + 1 < rows.size() else NodePath(".")
		row.focus_previous = row.focus_neighbor_top
		row.focus_next = row.focus_neighbor_bottom

## A row names its creature: its nickname, or its species when unnamed (an
## empty nickname used to leave the row blank). Rows that would still read
## the same, such as two unnamed Bramblebun, carry their party slot.
static func party_labels(cards: Array) -> Array[String]:
	var names: Array[String] = []
	var counts := {}
	for card: Variant in cards:
		var nickname := str((card as Dictionary).get("nickname", "")).strip_edges() if card is Dictionary else ""
		var name := nickname if not nickname.is_empty() else str((card as Dictionary).get("species_id", "")).capitalize() if card is Dictionary else ""
		names.append(name)
		counts[name] = int(counts.get(name, 0)) + 1
	for index in names.size():
		if int(counts[names[index]]) > 1:
			names[index] = "%s (%d)" % [names[index], index + 1]
	return names


## Only offer a feast at this individual's current locked tier. Level stays
## unchanged after feeding, so level alone would re-offer the consumed tier.
static func feast_matches_current_cap(card: Dictionary, mirror: Dictionary, definition: Dictionary) -> bool:
	if definition.get("kind") != "ascension_feast": return false
	var tiers: Array = mirror.get("breakthroughs", [])
	var cap := BREAKTHROUGH.level_cap(tiers)
	return cap > 0 and int(mirror.get("cap_level", -1)) == cap and int(card.get("level", -1)) == cap \
		and int(definition.get("breaks_level", -1)) == cap and not tiers.has(int(definition.get("tier", -1)))

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
	if _pending_action.is_empty():
		_retries_left = RETRIES
		_retry_wait = -1.0
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
	if action == _pending_action and original == _pending_intent and action in ["feast_cook", "feast_feed"] \
			and result.get("ok") != true and result.get("terminal_refusal") != true \
			and str(result.get("code", "")) in RETRY_CODES:
		if _retries_left > 0 and _retry_context_live():
			_retries_left -= 1
			_retry_wait = RETRY_SECONDS
			if is_instance_valid(_message): _message.text = "Saving your earlier action first…"
		else:
			_release_for_retry()
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

func _process(delta: float) -> void:
	if _retry_wait < 0.0: return
	_retry_wait -= delta
	if _retry_wait > 0.0: return
	_retry_wait = -1.0
	if _pending_action not in ["feast_cook", "feast_feed"]: return
	if not _retry_context_live():
		_release_for_retry()
		return
	# The same original intent: the host's checkpoint admits it once, so a
	# resend can never feed or cook twice.
	_send(_pending_action, _pending_intent.duplicate(true))
	if not _pending_action.is_empty() and is_instance_valid(_message): _message.text = "Saving your earlier action first…"

## A resend needs the open panel, its producer and source, in the scene it
## was opened in.
func _retry_context_live() -> bool:
	if not visible or not is_instance_valid(_service) or not is_instance_valid(_source): return false
	return _retry_scene == null or _retry_scene.get_ref() == _current_scene()

func _current_scene() -> Node:
	return get_tree().current_scene if is_inside_tree() else null

## Out of momentary retries: nothing was saved; free the row for a new press.
func _release_for_retry() -> void:
	_retry_wait = -1.0
	_pending_action = ""
	_pending_intent = {}
	if is_instance_valid(_message): _message.text = "Your earlier action is still saving. Press again to retry."

## The producer's personal view arrived. Rebuild only a list that was built
## without one; a shown list keeps its buttons (and re-reading cannot loop).
func view_arrived() -> void:
	if visible and _awaiting_view and _pending_action.is_empty() and not _preparing_duel:
		_rebuild()

func _unhandled_input(event: InputEvent) -> void:
	if visible and is_cancel(event):
		get_viewport().set_input_as_handled()
		close()

## menu_cancel is the controller's B; built-in ui_cancel has no pad binding.
static func is_cancel(event: InputEvent) -> bool:
	return event.is_action_pressed("menu_cancel") or event.is_action_pressed("ui_cancel")

func _cancel_duel_preparation() -> void:
	_duel_generation += 1
	_preparing_duel = false
	if _pending_action == "master_duel":
		_pending_action = ""
		_pending_intent = {}

func close() -> void:
	# A refused press waiting to be resent was not admitted: release it now.
	if _retry_wait >= 0.0: _release_for_retry()
	_cancel_duel_preparation()
	INPUT.suppress_pause_reopen(get_tree())
	hide()
