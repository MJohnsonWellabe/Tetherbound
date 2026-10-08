extends "res://scripts/ui/system_screen.gd"

## Reads the owned UID, actual learnset/mastery and canonical gear carrier.
## Equip remains at the Den/Workbench through the existing craft producer.
const MOVES := preload("res://scripts/creatures/move_db.gd")
const MASTERY := preload("res://scripts/creatures/move_mastery.gd")
const GEAR := preload("res://scripts/creatures/creature_gear.gd")
var _game: Node
var _uid := ""
var _tab := "Loadout"
var _tabs: Array[String] = ["Loadout", "Mastery", "Gear"]
var _moves: RefCounted
var _slot := ""
var _station_key := ""
var _loadout_service: Node
var _pending_edit := ""
var _pending_durable := false
var _choose_owned := false
var _gear_section := "Companion"
var level_route := Callable()
var traits_route := Callable()

## Narrow F23 producer seam: service owns station/character binding,
## submit/reconcile and saved receipt validation. UI never calls host_commit.
func configure_loadout_service(service: Node, station_key: String) -> bool:
	if not _pending_edit.is_empty() or not is_instance_valid(service) or station_key.is_empty(): return false
	for method: String in ["quote_loadout", "submit_loadout", "reconcile_loadout"]:
		if not service.has_method(method): return false
	if not service.has_signal("loadout_completed"): return false
	if is_instance_valid(_loadout_service) and _loadout_service.is_connected("loadout_completed", _loadout_completed):
		_loadout_service.disconnect("loadout_completed", _loadout_completed)
	_loadout_service = service
	_station_key = station_key
	service.connect("loadout_completed", _loadout_completed)
	return true

func open(game: Node, uid: String, tab: String = "Loadout", loadout_only: bool = false) -> bool:
	if not _pending_edit.is_empty() or config().get("enabled") != true or game == null: return false
	_game = game
	_uid = uid
	_choose_owned = loadout_only
	# assign(): a ternary of literals is an untyped Array, refused by Array[String].
	_tabs.assign(["Loadout"] if loadout_only else ["Loadout", "Mastery", "Gear"])
	if not loadout_only and level_route.is_valid() and traits_route.is_valid(): _tabs.assign(["Level", "Loadout", "Traits", "Mastery", "Gear"])
	_tab = tab if _tabs.has(tab) else "Loadout"
	if _owned() == null or not begin("Companion", "A Choose · LB/RB Details · B Back"): return false
	_moves = MOVES.load_default()
	_rebuild()
	return true

func _owned() -> RefCounted:
	if not is_instance_valid(_game): return null
	var party: Variant = _game.get("party")
	if not party is RefCounted: return null
	var members: Variant = party.call("members")
	if not members is Array or members.size() > 5: return null
	for creature: RefCounted in members:
		if str(creature.get("uid")) == _uid: return creature
	return null

func _rebuild() -> void:
	var focus := clear_body()
	var creature := _owned()
	if creature == null:
		close()
		return
	heading.text = "%s · %s" % [str(creature.call("label")), _tab]
	if _choose_owned:
		for member: RefCounted in _game.get("local").party.call("members"):
			button(body, ("● " if str(member.uid) == _uid else "") + str(member.call("label")),
				_select_owned.bind(str(member.uid)), "creature:" + str(member.uid), _pending_edit.is_empty())
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	body.add_child(tabs)
	for tab: String in _tabs:
		button(tabs, ("● " if tab == _tab else "") + tab, _select_tab.bind(tab), "tab:" + tab)
	var local: RefCounted = _game.get("local")
	if _tab == "Loadout":
		var columns := HBoxContainer.new()
		columns.add_theme_constant_override("separation", 24)
		body.add_child(columns)
		var slots := VBoxContainer.new()
		slots.custom_minimum_size.x = 380
		slots.add_theme_constant_override("separation", 6)
		columns.add_child(slots)
		for slot: String in ["quick", "charged", "utility", "ultimate"]:
			var id := str(creature.get("move_" + slot))
			var choice := button(slots, "%s · %s" % [slot.capitalize(), "Empty" if id.is_empty() else _moves.call("display_name", id)], _choose_slot.bind(slot), "slot:" + slot, _pending_edit.is_empty())
			choice.custom_minimum_size.y = 52
		var scroll := ScrollContainer.new()
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.follow_focus = true
		columns.add_child(scroll)
		var detail := VBoxContainer.new()
		detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		detail.add_theme_constant_override("separation", 8)
		scroll.add_child(detail)
		var selected := _slot if not _slot.is_empty() else "quick"
		var current := str(creature.get("move_" + selected))
		line(detail, "Signature ultimate · Read only" if selected == "ultimate" else selected.capitalize() + " move", TOKENS.FONT_PROMPT)
		if not current.is_empty(): _move_line(current, creature, detail)
		if not _slot.is_empty() and _slot != "ultimate":
			line(detail, "Known " + _slot + " moves")
			for id: String in creature.get("known_moves"):
				if _moves.call("slot", id) == _slot:
					button(detail, "Equip " + str(_moves.call("display_name", id)), _equip.bind(id), "move:" + id, is_instance_valid(_loadout_service) and _pending_edit.is_empty())
		status.text = "Waiting for the host to save this loadout." if not _pending_edit.is_empty() else "Choose a slot, then a legal known move." if is_instance_valid(_loadout_service) else "Loadout changes are unavailable at this station."
		if not _pending_edit.is_empty(): button(body, "Check original loadout change", _reconcile_loadout, "reconcile")
	elif _tab == "Mastery":
		status.text = "Mastery grows from host-confirmed landed uses."
		var thresholds: Array = MASTERY.config().get("rank_thresholds", [])
		var ranks := GridContainer.new()
		ranks.columns = 2
		ranks.add_theme_constant_override("h_separation", 24)
		ranks.add_theme_constant_override("v_separation", 12)
		body.add_child(ranks)
		for id: String in creature.get("known_moves"):
			var rank := MASTERY.rank_for(creature, id)
			var uses := int((creature.get("move_mastery_uses") as Dictionary).get(id, 0))
			var card := VBoxContainer.new()
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ranks.add_child(card)
			button(card, "%s · Rank %d / 5" % [_moves.call("display_name", id), rank], func() -> void: pass, "mastery:" + id)
			if rank < 5 and thresholds.size() == 5:
				line(card, "%d / %d landed uses · Next: +%.0f%% damage" % [uses, int(thresholds[rank]), float(MASTERY.config().get("damage_per_rank", 0)) * 100])
			else: line(card, "Mastered")
	else:
		status.text = "Harness and Charm: Den · Trainer gear: Workbench."
		var sections := HBoxContainer.new()
		sections.add_theme_constant_override("separation", 8)
		body.add_child(sections)
		for section: String in ["Companion", "Trainer", "Protection", "Pouch"]:
			button(sections, ("● " if section == _gear_section else "") + section, _select_gear_section.bind(section), "gear:" + section)
		var readouts := GridContainer.new()
		readouts.columns = 2
		readouts.add_theme_constant_override("h_separation", 24)
		readouts.add_theme_constant_override("v_separation", 8)
		body.add_child(readouts)
		var personal: Variant = local.get("redesign_character") if local != null else null
		var carrier := {"redesign_character": personal}
		var equipped := GEAR.gear_for(carrier, _uid) if personal is Dictionary else {}
		var cfg := GEAR.config()
		for slot: String in (["harness", "charm"] if _gear_section == "Companion" else []):
			var id := str(equipped.get(slot, ""))
			var piece: Dictionary = cfg.get("items", {}).get(id, {})
			var entry := VBoxContainer.new()
			readouts.add_child(entry)
			line(entry, "%s · %s" % [slot.capitalize(), "Empty" if id.is_empty() else str(piece.get("name", id))], TOKENS.FONT_PROMPT)
			if not piece.is_empty(): line(entry, "Tier %d · Upgrade +%d" % [int(piece.get("gear_tier", 0)), int(piece.get("gear_upgrade", 0))])
		var modifiers := GEAR.modifiers(equipped, cfg)
		if _gear_section == "Companion":
			for field: String in modifiers:
				line(readouts, "%s: +%.0f%%" % [field.replace("_", " ").capitalize(), (float(modifiers[field]) - 1) * 100])
		var equipment: RefCounted = local.get("equipment") if local != null else null
		if equipment != null and _gear_section == "Trainer":
			for slot: String in ["helmet", "upper_body", "lower_body", "boots", "backpack"]:
				var id := str(equipment.call("equipped_in", slot))
				line(readouts, "%s · %s" % [slot.replace("_", " ").capitalize(), "Empty" if id.is_empty() else id.replace("_", " ").capitalize()])
		if equipment != null and _gear_section == "Protection":
			for hazard: String in ["fall", "storm", "drowning", "currents", "cold", "terrain"]:
				line(readouts, "%s reduction: %.0f%%" % [hazard.capitalize(), float(equipment.call("hazard_reduction", hazard)) * 100])
		if equipment != null and _gear_section == "Pouch":
			var commands: Dictionary = equipment.call("command_pouch_profile")
			line(body, "Tether Command pouch · Tier %d · %d slots\nMeter gain ×%.2f · Snare slows to %.0f%% speed · Catch bonus +%.0f%%" % [
				int(equipment.call("command_pouch_tier")), int(commands.get("pouch_size", 0)), float(commands.get("meter_rate", 1)),
				float(commands.get("movement_multiplier", 1)) * 100, float(commands.get("catch_bonus", 0)) * 100])
		for item: Control in readouts.get_children():
			item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	finish(focus if not focus.is_empty() else "tab:" + _tab)

func _select_gear_section(section: String) -> void:
	_gear_section = section
	_rebuild()

func _select_owned(uid: String) -> void:
	if not _choose_owned or not _pending_edit.is_empty(): return
	var previous := _uid
	_uid = uid
	if _owned() == null:
		_uid = previous
		return
	_slot = ""
	_rebuild()

func _move_line(id: String, creature: RefCounted, parent: Node = null) -> void:
	if parent == null: parent = body
	var row: Dictionary = _moves.call("move", id)
	var cost := "Energy %d" % int(row.energy_cost) if row.has("energy_cost") else "Wind %d" % int(row.wind_cost) if row.has("wind_cost") else "Cost uses combat profile"
	var cooldown := "Cooldown %.1fs" % float(row.cooldown_s) if row.has("cooldown_s") else "Recovery %.2fs" % float(row.recovery) if row.has("recovery") else "Timing uses combat profile"
	line(parent, "%s · %s · Power %.2f · %s · %s · Mastery %d/5\n%s" % [
		_moves.call("display_name", id), str(row.get("slot", "")).capitalize(), float(row.get("power", 1)),
		cost, cooldown, MASTERY.rank_for(creature, id), str(row.get("description", ""))])

func _select_tab(tab: String) -> void:
	if tab in ["Level", "Traits"]:
		if not _pending_edit.is_empty(): return
		var route := level_route if tab == "Level" else traits_route
		if route.is_valid():
			close()
			_closing = false # Incoming screen owns the same input edge.
			route.call()
		return
	_tab = tab
	_rebuild()

func _choose_slot(slot: String) -> void:
	_slot = slot
	_rebuild()

func _equip(move: String) -> void:
	var creature := _owned()
	if creature == null or not is_instance_valid(_loadout_service) or not _pending_edit.is_empty(): return
	if not _slot in ["quick", "charged", "utility"] or _moves.call("slot", move) != _slot \
			or not (creature.get("known_moves") as Array).has(move): return
	_pending_edit = Crypto.new().generate_random_bytes(16).hex_encode()
	_pending_durable = false
	var request := {"edit_id": _pending_edit, "expected_revision": int(creature.get("loadout_revision")), "creature_uid": _uid}
	for slot: String in ["quick", "charged", "utility"]:
		request[slot] = move if slot == _slot else str(creature.get("move_" + slot))
	_rebuild()
	_loadout_service.call("submit_loadout", _station_key, request)

func _reconcile_loadout() -> void:
	if is_instance_valid(_loadout_service) and not _pending_edit.is_empty():
		_loadout_service.call("reconcile_loadout", _pending_edit)

func _loadout_completed(edit_id: String, result: Dictionary) -> void:
	if edit_id != _pending_edit or _pending_edit.is_empty(): return
	if result.get("durable") == true: _pending_durable = true
	if result.get("resolved") != true or not result.get("ok") is bool: return
	if result.get("ok") == true and (result.get("saved") != true or result.get("durable") != true): return
	if result.get("ok") == false and _pending_durable: return
	_pending_edit = ""
	_pending_durable = false
	if _shown:
		_rebuild()
		status.text = "Loadout changed and saved." if result.get("ok") == true else str(result.get("reason", "The loadout change was refused."))

func _unhandled_input(event: InputEvent) -> void:
	if _shown and (event.is_action_pressed("menu_tab_left") or event.is_action_pressed("menu_tab_right")):
		var direction := -1 if event.is_action_pressed("menu_tab_left") else 1
		_select_tab(_tabs[(_tabs.find(_tab) + direction + _tabs.size()) % _tabs.size()])
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)

func _process(delta: float) -> void:
	super._process(delta)
	if _shown and _owned() == null: close()

func _exit_tree() -> void:
	if is_instance_valid(_loadout_service) and _loadout_service.is_connected("loadout_completed", _loadout_completed):
		_loadout_service.disconnect("loadout_completed", _loadout_completed)
	super._exit_tree()
