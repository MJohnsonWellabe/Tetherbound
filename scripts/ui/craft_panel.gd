extends CanvasLayer

## R2.4. The campfire's craft screen: every base-tier recipe, its cost, and
## whether the satchel can afford it right now.
##
## Built entirely in code, the way `tab_build.gd` builds its own list —
## there is no paired `.tscn` and does not need one. Not a pause-menu tab:
## `data/recipes/recipes.json`'s own comment and R2.4's brief both scope
## crafting to "at the campfire or workbench", so this only exists while
## standing at one, opened and closed the same way `game_menu.gd` opens
## itself — pause the tree, release the mouse, restore both on close.
##
## Godot's built-in `ui_up`/`ui_down`/`ui_accept` (bound to d-pad, stick and
## gamepad A by default, same physical inputs this project's own
## `menu_confirm` names) drive real `Button` focus navigation, so there is no
## hand-rolled cursor here — see `game_menu.gd`'s own reliance on the same
## default chain.
##
## Layout: spec §15's three-zone Tetherbound treatment (list / hero / detail),
## the same shape `tab_build.gd` already uses for the build catalogue, but in
## `UITokens`' cool palette rather than that tab's warm brass — this is a
## campfire screen, not a build-menu one, and D28 draws that line at the
## token set, not just at the font. "Selected" is simply "focused": with a
## handful of recipes and pad-only navigation there is no separate hover
## state worth tracking, so the left row's focus stylebox IS the highlight
## `_describe` reads off of.

const UITokens := preload("res://scripts/ui/ui_tokens.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
## D102: pausing the tree is a solo-only act. See local_pause.gd.
const LOCAL_PAUSE := preload("res://scripts/ui/local_pause.gd")
const PRESENTATION_CONFIG := "res://data/config/craft_presentation.json"

const STATUS_SECONDS := 2.4
const ROW_ICON_PX := 40
const CENTER_ICON_PX := 96
const INGREDIENT_ICON_PX := 24
## Was 64: too tight even for a single-line cost summary at FONT_BODY (name)
## + FONT_TINY (cost) with the row's own 6px top/bottom padding, which is why
## rows overflowed on ordinary recipes, not just ones with unusually long
## ingredient lists. 80 is the smallest height that fits both labels at their
## real line heights with room to spare; `_make_row`'s `clip_contents = true`
## is the hard backstop for whatever this estimate still gets wrong.
const ROW_HEIGHT := 80

## Six rows' worth of the left column visible at once, the rest reached by
## scrolling. `known_recipe_ids()` (autoload/game_state.gd) returns every
## recipe with no `unlocked_by` flag from the first minute -- 13 of
## data/recipes/recipes.json's 14 entries today -- so the list zone's real
## content height (14 * ROW_HEIGHT + separations, over 1200px) routinely
## exceeds what fits in the panel alongside the hero/detail columns. A fixed
## cap here is what makes `_build_list_zone`'s ScrollContainer actually bound
## the panel's height instead of just being a scrollbar around content that
## still forces the panel taller than the screen (same mechanism as
## shop_panel.gd's PANEL_HEIGHT/scroll pairing).
const LIST_VISIBLE_HEIGHT := 6 * ROW_HEIGHT + 5 * 8

const STATION_RULES := preload("res://scripts/build/station_rules.gd")
const CAMP_RULES := preload("res://scripts/build/forward_camp_rules.gd")
const STATION_NEXT := preload("res://scripts/build/station_next_upgrade.gd")
var _station: Node3D
var _station_mode := false
var _station_intent: Dictionary = {}
var _station_operation := ""
var _station_source: WeakRef
var _station_source_key := ""
var _view_refresh_pending := false
var _presented_station_view: Dictionary = {}
var _presented_gear_context: Dictionary = {}
var _upgrade_label: Label
var _station_buttons: Array[Button] = []
var _producer: Node
var _original_revision := -1
var _gear_cfg: Dictionary = {}
var _gear_rules: Script
var _refining_amount := 1
var _refining_label: Label

func open_station(station: Node3D) -> void:
	if not is_instance_valid(station) or STATION_RULES.config().get("runtime_enabled") != true: return
	var session: Node = game.get("session") as Node if game != null else null
	if session == null or not session.has_method("homestead_submit_action") \
			or not session.has_method("homestead_personal_view"): return
	if not _station_intent.is_empty() and (station != _original_station() or session != _producer): return
	if session != _producer: _disconnect_station_producer()
	_producer=session
	_gear_cfg={}
	_gear_rules=null
	var gear_path := "res://scripts/creatures/creature_gear.gd"
	if FileAccess.file_exists("res://data/config/gear.json") and ResourceLoader.exists(gear_path):
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/gear.json"))
		if raw is Dictionary and raw.get("feature_flags",{}).get("runtime_enabled") == true:
			_gear_cfg=raw
			_gear_rules=load(gear_path) as Script
	if _producer.has_signal("homestead_action_completed") \
			and not _producer.is_connected("homestead_action_completed",_station_completed):
		_producer.connect("homestead_action_completed",_station_completed)
	if _producer.has_signal("homestead_personal_view_completed") \
			and not _producer.is_connected("homestead_personal_view_completed",_station_view_completed):
		_producer.connect("homestead_personal_view_completed",_station_view_completed)
	open(station)

func _station_view() -> Dictionary:
	if not is_instance_valid(_producer) or not _producer.has_method("homestead_personal_view") \
			or game == null or game.get("session") != _producer: return {}
	var raw: Variant = _producer.call("homestead_personal_view")
	return raw if raw is Dictionary else {}

func _original_station() -> Node3D:
	return _station_source.get_ref() as Node3D if _station_source != null else null

func _station_view_completed() -> void:
	if not _open or not is_instance_valid(_station) or _view_refresh_pending: return
	_view_refresh_pending=true
	call_deferred("_refresh_station_view")

## Notification only: re-read the producer's authenticated current cache.
## A new quote never rebases, retries or releases the original transaction.
func _refresh_station_view() -> void:
	_view_refresh_pending=false
	if not _open or not is_instance_valid(_station) or not is_instance_valid(_producer) \
			or game == null: return
	var view := _station_view()
	var context := _gear_context(view)
	if view == _presented_station_view and context == _presented_gear_context: return
	_presented_station_view=view.duplicate(true)
	_presented_gear_context=context.duplicate(true)
	_rebuild_station_presentation()

func _rebuild_station_presentation() -> void:
	var message := _status.text if is_instance_valid(_status) else ""
	var remaining := _status_left
	var focus := get_viewport().gui_get_focus_owner() as Button
	var focus_key := str(focus.get_meta("station_focus_key","")) if is_instance_valid(focus) and _station_buttons.has(focus) else ""
	var recipe_id := _recipe_ids[_selected] if _selected >= 0 and _selected < _recipe_ids.size() else ""
	_build()
	_status.text=message
	_status_left=remaining
	var recipe_index := _recipe_ids.find(recipe_id)
	if recipe_index >= 0: _selected=recipe_index
	for button: Button in _station_buttons:
		if not button.disabled and not focus_key.is_empty() and str(button.get_meta("station_focus_key","")) == focus_key:
			button.call_deferred("grab_focus")
			return
	if not _station_intent.is_empty():
		for button: Button in _station_buttons:
			if not button.disabled and button.text == "Retry original transaction":
				button.call_deferred("grab_focus")
				return
	if not _rows.is_empty(): _rows[clampi(_selected,0,_rows.size()-1)].call_deferred("grab_focus")
	else:
		for button: Button in _station_buttons:
			if not button.disabled:
				button.call_deferred("grab_focus")
				return

func _disconnect_station_producer() -> void:
	if not is_instance_valid(_producer): return
	if _producer.has_signal("homestead_action_completed") and _producer.is_connected("homestead_action_completed",_station_completed):
		_producer.disconnect("homestead_action_completed",_station_completed)
	if _producer.has_signal("homestead_personal_view_completed") and _producer.is_connected("homestead_personal_view_completed",_station_view_completed):
		_producer.disconnect("homestead_personal_view_completed",_station_view_completed)

func _exit_tree() -> void:
	_disconnect_station_producer()

func _build_station_controls(outer: VBoxContainer) -> void:
	_station_buttons.clear()
	_upgrade_label=Label.new()
	_upgrade_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_upgrade_label.add_theme_font_size_override("font_size",UITokens.FONT_READ)
	outer.add_child(_upgrade_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(780,210 if _station.get_meta("building_id","") == "forge" else 80)
	scroll.follow_focus = true
	if not _gear_cfg.is_empty() and _station.get_meta("building_id","") in ["workbench","altar"]: scroll.custom_minimum_size.y=210
	if _station.get_meta("building_id","") in ["farm","den"]: scroll.custom_minimum_size.y=460
	var viewport_height := get_viewport().get_visible_rect().size.y
	scroll.custom_minimum_size.y=minf(scroll.custom_minimum_size.y,maxf(120,viewport_height*0.28 if _station.get_meta("building_id","") == "forge" else viewport_height*0.5))
	outer.add_child(scroll)
	var controls := VBoxContainer.new()
	controls.custom_minimum_size.x=740
	scroll.add_child(controls)
	var id: String = str(_station.get_meta("building_id",""))
	match id:
		"forward_camp":
			var info := Label.new()
			info.text="Travel meals and field kits only. Feasts: homestead Kitchen. Tier gear and refining: homestead Forge."
			info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			controls.add_child(info)
			if _station.get("camp_part") == "workbench":
				_station_button(controls,"Edit creature move loadouts",func() -> void:
					var source := _station
					close()
					source.call("open_loadouts"))
		"kitchen": _station_button(controls,"Cook learned Ascension Feasts",_open_feasts)
		"forge":
			_refining_label=Label.new()
			_refining_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			controls.add_child(_refining_label)
			_change_refining_amount(0)
			_station_button(controls,"Fewer refining units",func() -> void: _change_refining_amount(-1))
			_station_button(controls,"More refining units",func() -> void: _change_refining_amount(1))
			var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/recipes/recipes_forge.json"))
			if raw is Dictionary:
				for recipe_id: String in raw.get("recipes",{}):
					var name: String = str(raw.recipes[recipe_id].get("name",recipe_id))
					_station_button(controls,"Refine "+name,func() -> void: _start_refining(recipe_id),"refine:"+recipe_id)
		"altar": _station_button(controls,"Creature training",_open_altar)
		"den":
			var view := _station_view()
			var party: Variant = view.get("party")
			if party is Array and party.size() <= 5:
				for row: Variant in party:
					if not row is Dictionary or not row.get("uid") is String: continue
					var uid: String = row.uid
					var label: String = str(row.get("nickname",row.get("species_id",uid)))
					var action := "wake" if row.get("resting") == true else "rest"
					_station_button(controls,action.capitalize()+" "+label,func() -> void: _station_action("den",{"creature_uid":uid,"action":action}),"den_rest:"+uid)
					_station_button(controls,"Groom "+label,func() -> void: _station_action("groom",{"creature_uid":uid}),"groom:"+uid)
		"farm":
			_station_button(controls,"Till plot",func() -> void: _farm_action("till",""))
			_station_button(controls,"Sow berries",func() -> void: _farm_action("sow","berries"))
			var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/farm.json"))
			if raw is Dictionary:
				var crops: Variant = raw.get("crops",{})
				if crops is Dictionary:
					for crop: String in raw.get("crop_order",crops.keys()):
						if crop == "berries" or not crops.has(crop): continue
						_station_button(controls,str(crops[crop].get("sow_label","Sow "+crop.replace("_"," "))),func() -> void: _farm_action("sow",crop))
			_station_button(controls,"Harvest ripe crop",func() -> void: _farm_action("harvest",""))
	_build_gear_controls(controls,id)
	_station_button(controls,"Retry original transaction",_retry_station)
	for i: int in _station_buttons.size():
		if i > 0: _station_buttons[i].focus_neighbor_top=_station_buttons[i].get_path_to(_station_buttons[i-1])
		if i+1 < _station_buttons.size(): _station_buttons[i].focus_neighbor_bottom=_station_buttons[i].get_path_to(_station_buttons[i+1])
	if not _rows.is_empty() and not _station_buttons.is_empty():
		_rows[-1].focus_neighbor_bottom=_rows[-1].get_path_to(_station_buttons[0])
		_station_buttons[0].focus_neighbor_top=_station_buttons[0].get_path_to(_rows[-1])
	_refresh_next_upgrade()

## Read the admitted personal projection for choices only. F33 re-derives
## ownership, recipe, costs, return room and actual station inside its stage.
func _build_gear_controls(controls: VBoxContainer, station_id: String) -> void:
	if _gear_cfg.is_empty() or _gear_rules == null: return
	var view := _station_view()
	var inventory: Variant = view.get("inventory")
	if not inventory is Array: return
	var personal: Variant = view.get("redesign_character")
	if not personal is Dictionary: return
	if station_id == "workbench":
		var equipment: Variant = view.get("equipment")
		if not equipment is Dictionary: return
		for slot: String in ["helmet","upper_body","lower_body","boots","backpack"]:
			var equipped: Variant = equipment.get(slot)
			if not equipped is String: continue
			if not equipped.is_empty():
				_gear_button(controls,"Remove "+_gear_name(equipped),"trainer_unequip","",slot,"")
			for id: String in _gear_inventory_ids(inventory):
				var db := _items()
				var item: Dictionary = db.call("definition",id) if db != null else {}
				if item.get("kind") == "armor" and item.get("armor_slot") == slot and int(db.call("stack_size",id)) == 1:
					_gear_button(controls,"Wear "+_gear_name(id),"trainer_equip","",slot,id)
	elif station_id in ["den","forge","altar"]:
		var party: Variant = view.get("party")
		if not party is Array or party.size() > 5: return
		for row: Variant in party:
			if not row is Dictionary or not row.get("uid") is String: continue
			var uid: String = row.uid
			var gear: Variant = _gear_rules.call("gear_for",view,uid)
			if not gear is Dictionary: continue
			var companion: String = str(row.get("nickname",row.get("species_id",uid)))
			for slot: String in ["harness","charm"]:
				var equipped: Variant = gear.get(slot)
				if not equipped is String: continue
				if station_id == "den":
					if not equipped.is_empty():
						_gear_button(controls,"Remove %s from %s" % [_gear_name(equipped),companion],"unequip",uid,slot,"")
					for id: String in _gear_inventory_ids(inventory):
						var item: Dictionary = _gear_cfg.get("items",{}).get(id,{})
						if item.get("kind") == "creature_gear" and item.get("gear_slot") == slot:
							_gear_button(controls,"Give %s to %s" % [_gear_name(id),companion],"equip",uid,slot,id)
				else:
					var upgrade: Dictionary = _gear_cfg.get("upgrades",{}).get(equipped,{})
					var piece: Dictionary = _gear_cfg.get("items",{}).get(equipped,{})
					var made_here := station_id == ("forge" if slot == "harness" else "altar")
					if not equipped.is_empty() and piece.get("kind") == "creature_gear" and made_here \
							and (upgrade.is_empty() or upgrade.get("station_id") == station_id):
						_gear_button(controls,"Upgrade %s's %s" % [companion,slot.capitalize()],"upgrade",uid,slot,equipped,companion)

func _gear_inventory_ids(inventory: Array) -> Array[String]:
	var result: Array[String] = []
	for stack: Variant in inventory:
		if stack is Dictionary and stack.get("id") is String and stack.get("n",0) > 0 and not result.has(stack.id): result.append(stack.id)
	return result

func _gear_name(id: String) -> String:
	var db := _items()
	if db != null: return str(db.call("item_name",id))
	return str(_gear_cfg.get("items",{}).get(id,{}).get("name",id.replace("_"," ").capitalize()))

## Hints use the producer's authenticated actual-source quote. The UI cannot
## substitute its player, guessed proximity or world revision for this seam.
func _gear_context(view: Dictionary) -> Dictionary:
	if not is_instance_valid(_station) or not is_instance_valid(_producer) or game == null \
			or game.get("session") != _producer or not _producer.has_method("homestead_gear_context"): return {}
	var raw: Variant = _producer.call("homestead_gear_context",_station,int(view.get("registry_revision", -1)))
	if not raw is Dictionary: return {}
	var revision: Variant = view.get("registry_revision")
	var id := str(_station.get_meta("building_id",""))
	var key := "%s:meadows:%s" % [id,str(_station.get_meta("building_uid",""))]
	if not STATION_RULES.number(revision) or float(revision) != floor(float(revision)) or revision < 0 \
			or not view.get("character_id") is String or view.character_id.is_empty() \
			or raw.get("character_id") != view.character_id or raw.get("expected_revision") != revision \
			or raw.get("station_id") != id or raw.get("source_key") != key: return {}
	return raw

func _gear_hint(fields: Dictionary) -> Dictionary:
	if _gear_rules == null or not _gear_rules.has_method("preflight") or _items() == null:
		return {"available":false,"reason":"Gear details are unavailable."}
	var view := _station_view()
	var context := _gear_context(view)
	var raw: Variant = _gear_rules.call("preflight",view,fields,context,_items(),_gear_cfg)
	var hint: Dictionary = raw if raw is Dictionary else {}
	if context.is_empty():
		hint["available"]=false
		hint["reason"]="Waiting for the host's station details."
	return hint

func _gear_button(controls: VBoxContainer, label: String, action: String, uid: String, slot: String, id: String, companion: String = "") -> void:
	var fields := {"action":action,"creature_uid":uid,"slot":slot,"item_id":id}
	var hint := _gear_hint(fields)
	if action == "upgrade":
		label=(_gear_name(id) if _gear_cfg.get("upgrades",{}).get(id,{}).is_empty() else str(hint.get("label",label))) \
			+(" for "+companion if not companion.is_empty() else "")
	_station_button(controls,label,func() -> void: _gear_action(fields),JSON.stringify(["gear",action,uid,slot,id]))
	var button: Button = _station_buttons[-1]
	button.set_meta("station_available",hint.get("available") is bool and hint.available == true)
	button.disabled=button.get_meta("station_available") != true or not _station_intent.is_empty()
	var parts: Array[String] = []
	if action == "upgrade":
		if int(hint.get("required_tier",0)) > 0: parts.append("Requires station tier %d" % int(hint.required_tier))
		var inventory: Array = _station_view().get("inventory",[])
		for cost: Variant in hint.get("cost",[]):
			if not cost is Dictionary: continue
			var have := 0
			for stack: Variant in inventory:
				if stack is Dictionary and stack.get("id") == cost.get("id"): have+=int(stack.get("n",0))
			parts.append("%d %s (have %d)" % [int(cost.get("n",0)),_gear_name(str(cost.get("id",""))),have])
		if hint.get("personal_known") == false and not _gear_cfg.get("upgrades",{}).get(id,{}).is_empty():
			parts.append(str(_gear_rules.call("refusal_text","personal_recipe_locked",_gear_cfg)))
	if hint.get("available") != true:
		var reason := str(hint.get("reason","Gear details are unavailable."))
		var explanation := str(_gear_rules.call("refusal_text",reason,_gear_cfg)) if _gear_rules.has_method("refusal_text") else reason
		if not parts.has(explanation): parts.append(explanation)
	if not parts.is_empty():
		var details := Label.new()
		details.text=". ".join(parts)
		details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		details.add_theme_font_size_override("font_size",UITokens.FONT_READ)
		_station_button(controls,"Details: "+label,func() -> void:
			_status.text=details.text
			_status_left=STATUS_SECONDS,JSON.stringify(["gear_details",action,uid,slot,id]))
		var reader: Button = _station_buttons[-1]
		reader.set_meta("station_readonly",true)
		controls.add_child(details)
		reader.focus_entered.connect(func() -> void:
			var scroll := controls.get_parent() as ScrollContainer
			if scroll != null: scroll.ensure_control_visible(details))

func _gear_action(fields: Dictionary) -> void:
	if not _station_intent.is_empty(): return
	var hint := _gear_hint(fields)
	if not hint.get("available") is bool or hint.available != true:
		var reason := str(hint.get("reason","Gear details are unavailable."))
		_status.text=str(_gear_rules.call("refusal_text",reason,_gear_cfg)) if _gear_rules != null \
			and _gear_rules.has_method("refusal_text") else reason
		_status_left=STATUS_SECONDS
		_station_view_completed()
		return
	_station_action("gear",fields)

func _station_button(parent: VBoxContainer, label: String, action: Callable, focus_key: String = "") -> void:
	var button := Button.new()
	button.text=label
	button.set_meta("station_focus_key",focus_key if not focus_key.is_empty() else label)
	button.custom_minimum_size=Vector2(740,42)
	button.add_theme_font_size_override("font_size",UITokens.FONT_READ)
	button.pressed.connect(action)
	parent.add_child(button)
	button.focus_entered.connect(func() -> void:
		var scroll := parent.get_parent() as ScrollContainer
		if scroll != null: scroll.ensure_control_visible(button))
	_station_buttons.append(button)

func _refresh_next_upgrade() -> void:
	if _upgrade_label == null or not is_instance_valid(_station): return
	var view := _station_view()
	var world: RefCounted = game.get("world") if game != null else null
	var upgrade := STATION_NEXT.for_building(STATION_RULES.config(),game.get("placed_buildings"),str(_station.get_meta("building_uid","")),
		str(world.get("world_id")) if world != null else "",view,game.get("items").call("buildable","greenhouse").get("cost",[])) if game != null else {}
	_upgrade_label.visible=upgrade.get("visible") == true
	if _upgrade_label.visible:
		_upgrade_label.text="Next upgrade: %s — %s. %s" % [str(upgrade.get("name","")),str(upgrade.get("unlocks","")),str(upgrade.get("missing_requirement",""))]
	var gear_context := _gear_context(view) if not _gear_cfg.is_empty() else {}
	for button: Button in _station_buttons:
		if button.get_meta("station_readonly",false) == true:
			button.disabled=false
		elif button.text == "Retry original transaction":
			button.disabled=_station_intent.is_empty() and _retained_station_transaction().is_empty()
		else:
			var revision: Variant = view.get("registry_revision")
			button.disabled=not _station_intent.is_empty() or not STATION_RULES.number(revision) \
				or float(revision) != floor(float(revision)) or revision < 0 or button.get_meta("station_available",true) != true
			if button.has_meta("station_available") and gear_context.is_empty(): button.disabled=true

func _farm_action(action: String, crop: String) -> void:
	if not is_instance_valid(_station): return
	var view := _station_view()
	var uid: String = str(_station.get_meta("building_uid",""))
	var stock: Variant = view.get("farm_stock_revisions",{}).get(uid)
	if not STATION_RULES.number(stock) or float(stock) != floor(float(stock)):
		_status.text="The host's crop state is unavailable."
		return
	_station_action("farm",{"plot_id":uid,"action":action,"crop_id":crop,"expected_stock_revision":int(stock)})

func _station_action(op: String, fields: Dictionary) -> void:
	if not _station_intent.is_empty(): return
	var view := _station_view()
	var revision: Variant = view.get("registry_revision")
	if not STATION_RULES.number(revision) or float(revision) != floor(float(revision)) or revision < 0:
		_status.text="The character's saved station state is unavailable."
		return
	_original_revision=int(revision)
	if not is_instance_valid(_station): return
	_station_source=weakref(_station)
	_station_source_key="%s:%s:%s" % [str(_station.get_meta("building_id","")),str(_station.get_meta("realm","")),str(_station.get_meta("building_uid",""))]
	_station_operation=op
	_station_intent=fields.duplicate(true)
	_station_intent["craft_id" if op == "station_craft" else "action_id"]=Crypto.new().generate_random_bytes(16).hex_encode()
	_retry_station()

func _retry_station() -> void:
	if not is_instance_valid(_producer): return
	if _station_intent.is_empty():
		var retained := _retained_station_transaction()
		if retained.is_empty(): return
		_station_intent = retained.intent.duplicate(true)
		_station_operation = retained.action
		_original_revision = int(retained.original_revision)
		_station_source = weakref(_station) if is_instance_valid(_station) else null
	# A removed node may be null. The producer must reconcile the retained
	# original journal before fresh-source validation; null cannot start work.
	var raw: Variant = _producer.call("homestead_submit_action",_station_operation,_station_intent.duplicate(true),_original_station(),_original_revision)
	if raw is Dictionary: _station_completed(_station_operation,_station_intent.duplicate(true),raw)
	else: _status.text="Waiting for the original station transaction."

func _retained_station_transaction() -> Dictionary:
	if not is_instance_valid(_producer) or not _producer.has_method("retained_training_transaction"): return {}
	return _producer.call("retained_training_transaction", ["station_craft", "den", "gear", "loadout", "camp_rest"])

## Trusted producer callback only. A displayed success needs both saves/ACK;
## unknown, contradictory and lost-ACK replies retain the original identity.
func _station_completed(op: String, original: Dictionary, result: Dictionary) -> void:
	if _station_intent.is_empty() or op != _station_operation or original != _station_intent: return
	var reason := str(result.get("reason",result.get("code","Waiting for the original station transaction.")))
	_status.text=str(_gear_rules.call("refusal_text",reason,_gear_cfg)) if op == "gear" \
		and _gear_rules != null and _gear_rules.has_method("refusal_text") else reason
	var terminal: bool = result.get("settled") is bool and result.settled == true \
		and result.get("durable") is bool and result.durable == true
	if terminal and result.get("ok") is bool and result.ok == true:
		_status.text="Completed. Saved to your character."
		_station_intent={}
	elif result.get("ok") is bool and result.ok == false \
			and result.get("terminal_refusal") is bool and result.terminal_refusal == true:
		_station_intent={}
	if _station_intent.is_empty() and _open:
		_status_left=STATUS_SECONDS
		_rebuild_station_presentation()
	_refresh_next_upgrade()

func _open_feasts() -> void:
	if not _station_intent.is_empty() or not is_instance_valid(_producer) \
			or not _producer.has_method("homestead_breakthrough_service"): return
	var service: Variant = _producer.call("homestead_breakthrough_service")
	if service is Node and service.has_method("open_kitchen"):
		var source := _station
		close()
		service.call("open_kitchen",source)

func _open_altar() -> void:
	if not _station_intent.is_empty() or not is_instance_valid(_station): return
	var interaction := _station.get_node_or_null(^"AltarInteraction")
	if interaction != null and interaction.has_method("_open"):
		close()
		interaction.call("_open")

func _start_refining(recipe: String) -> void:
	if not _station_intent.is_empty() or not is_instance_valid(_producer) \
			or not _producer.has_method("homestead_start_refining"): return
	var source := _station
	var amount := _refining_amount
	close() # Present channel runs in the world; another modal cancels it.
	var result: Variant = _producer.call("homestead_start_refining",source,recipe,amount)
	if result is Dictionary and game != null:
		game.call("push_world_message",str(result.get("reason","Refining started; stay beside the Forge.")))

func _change_refining_amount(delta: int) -> void:
	_refining_amount=clampi(_refining_amount+delta,1,int(STATION_RULES.config().forge.maximum_manual_units))
	_refining_label.text="Refine %d units — each completes while you stay beside the Forge" % _refining_amount
var game: Node = null

var _root: Control = null
var _list_scroll: ScrollContainer = null
var _rows: Array[Button] = []
var _cost_labels: Array[Label] = []
var _recipe_ids: Array[String] = []
var _selected: int = 0

var _center_icon: TextureRect = null
var _center_name: Label = null
var _ingredients_col: VBoxContainer = null
var _output_line: Label = null
var _craft_hint: Label = null
var _status: Label = null
var _status_left: float = 0.0

var _open: bool = false
var _mouse_before: int = Input.MOUSE_MODE_VISIBLE
var _paused_before: bool = false
var _presentation: Dictionary = {}
var _readable_recipe_rows := false
var _readable_action_hints := false


func _ready() -> void:
	game = get_node_or_null(^"/root/Game")
	var presentation: Variant = JSON.parse_string(FileAccess.get_file_as_string(PRESENTATION_CONFIG))
	if presentation is Dictionary:
		_presentation = presentation
	_readable_recipe_rows = bool(_presentation.get("readable_recipe_rows", false))
	_readable_action_hints = bool(_presentation.get("readable_action_hints", false))
	_build()
	visible = false
	# RG4: `input_owner.gd`'s own header has claimed since OW10 that this
	# panel already joins its GROUP alongside storage/swap/creature_bed/shop
	# -- it never did. Pausing the tree hid the gap for every poller that
	# only runs in-tree (build_placer.gd among them), but it left
	# `INPUT_OWNER.current()` blind to this panel: nothing generic can tell
	# it is open, or recover cleanly if its own close() is ever skipped.
	add_to_group(INPUT_OWNER.GROUP)


func is_open() -> bool:
	return _open


## OF30. The list of recipes the player knows can GROW between two visits to a
## campfire — Tam writes the orb recipe down and the row has to be there the
## next time this opens. `_build()` runs once in `_ready()`, so the check is
## here: rebuild only when the known set has actually changed, which is never
## on the common path and exactly once on the interesting one.
## No Game autoload means no item database either (`_items()` reads it off the
## same node), so there is nothing to list and every other method here already
## degrades to drawing an empty panel rather than erroring.
func _known_ids() -> Array:
	if game == null:
		return []
	var ids: Array = game.call("known_recipe_ids") as Array
	if not is_instance_valid(_station):
		if STATION_RULES.config().get("runtime_enabled") != true: return ids
		var field: Array = STATION_RULES.config().recipe_routes.get("field_allowed",[])
		return ids.filter(func(id: Variant) -> bool: return field.has(str(id)))
	var station_id: String = str(_station.get_meta("building_id", ""))
	var result: Array = []
	var cfg := STATION_RULES.config()
	var db := _items()
	for raw: Variant in ids:
		var recipe: Dictionary = db.call("recipe",str(raw))
		if station_id == CAMP_RULES.ID:
			if CAMP_RULES.recipe(str(raw),recipe,str(_station.get("camp_part"))).get("ok") == true: result.append(raw)
			continue
		if recipe.has("personal_gear_tier") or _gear_cfg.get("recipes",{}).has(str(raw)):
			if _gear_rules == null or _gear_rules.call("recipe_known",_station_view(),recipe,_gear_cfg) != true: continue
		var route := STATION_RULES.recipe_route(cfg,str(raw),recipe)
		if route.get("ok") == true and route.station_id == station_id: result.append(raw)
	return result


func _known_ids_differ_from_the_list_on_screen() -> bool:
	var known: Array = _known_ids()
	if known.size() != _recipe_ids.size():
		return true
	for i in known.size():
		if str(known[i]) != _recipe_ids[i]:
			return true
	return false


func open(station: Node3D = null) -> void:
	if _open:
		return
	if not _station_intent.is_empty() and (not is_instance_valid(station) or station != _original_station()):
		return # Keep unresolved original source/intent; no competing craft.
	_station = station
	_station_mode=is_instance_valid(station)
	if is_instance_valid(_station) or _known_ids_differ_from_the_list_on_screen():
		_build()
	if is_instance_valid(_station):
		_presented_station_view=_station_view().duplicate(true)
		_presented_gear_context=_gear_context(_presented_station_view).duplicate(true)
	_open = true
	visible = true
	_mouse_before = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_paused_before = get_tree().paused
	# D102: a true pause solo, a no-op in a session. The player who opened
	# this panel still has their world verbs stood down either way --
	# `input_owner.gd`'s group does that, and always did.
	LOCAL_PAUSE.hold(get_tree())
	# A station panel is a modal surface, and the exploration HUD was drawn
	# straight over the top of it -- the creature block, roster, vitals,
	# hotbar and minimap all still painting across this panel's own rows. It
	# went unnoticed because the UI survey used to shoot these panels with no
	# world loaded at all, so there was no HUD in the frame to collide with.
	INPUT_OWNER.set_world_hud_visible(get_tree(), false)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_poll()
	if not _rows.is_empty():
		_rows[0].grab_focus()
		_select(0)
	elif is_instance_valid(_station):
		for button: Button in _station_buttons:
			if not button.disabled:
				button.grab_focus()
				break


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	# RG1: release is determined by the live ownership graph, not by the
	# pause bit this panel happened to observe when it opened. A cached
	# true value can come from a previous modal in the same handoff and
	# restoring it after every visible panel is gone freezes the world.
	if INPUT_OWNER.current(get_tree()) == null:
		# Only once nothing else owns the screen -- restoring on any close
		# would put the HUD back over a panel that is still open underneath.
		INPUT_OWNER.set_world_hud_visible(get_tree(), true)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		LOCAL_PAUSE.release(get_tree())


func _build() -> void:
	for child in get_children():
		child.queue_free()
	_rows.clear()
	_cost_labels.clear()
	_recipe_ids.clear()

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var box := UITokens.panel_box(UITokens.BG_PANEL, UITokens.BORDER)
	box.content_margin_left = 28
	box.content_margin_top = 22
	box.content_margin_right = 28
	box.content_margin_bottom = 20

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", box)
	panel.custom_minimum_size = Vector2(float(_presentation.get("panel_width", 1080)) if _readable_recipe_rows else 880.0, 0)
	center.add_child(panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 14)
	panel.add_child(outer)

	var title := Label.new()
	title.text = str(_station.get_meta("building_id", "")).capitalize() if is_instance_valid(_station) else "Craft"
	title.add_theme_font_size_override("font_size", UITokens.FONT_TITLE)
	title.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	outer.add_child(title)

	var zones := HBoxContainer.new()
	zones.add_theme_constant_override("separation", 22)
	outer.add_child(zones)

	if not is_instance_valid(_station) or _station.get_meta("building_id", "") not in ["den", "farm"]:
		zones.add_child(_build_list_zone())
		zones.add_child(_build_center_zone())
		zones.add_child(_build_right_zone())
	else:
		_status = Label.new()
		_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		outer.add_child(_status)
	if is_instance_valid(_station): _build_station_controls(outer)

	var hint := Label.new()
	hint.text = "Leave: %s" % _cancel_glyph()
	hint.add_theme_font_size_override("font_size", UITokens.FONT_PROMPT if _readable_action_hints else UITokens.FONT_TINY)
	hint.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY if _readable_action_hints else UITokens.TEXT_MUTED)
	outer.add_child(hint)

	UITokens.make_text_legible(_root)
	_describe(0)


## LEFT: one row per recipe — output icon, name, and an affordability-coloured
## cost summary, exactly the fields `_poll` and `_describe` keep live.
##
## OF30: KNOWN recipes, not all of them. A locked recipe is absent rather than
## greyed — a greyed row with no way to explain itself ("come back when someone
## has taught you this") is the silent-refusal shape OF23 was raised about, and
## an orb recipe the player has never been told exists has nothing to say yet.
func _build_list_zone() -> Control:
	var side := VBoxContainer.new()
	var list_width := float(_presentation.get("list_width", 480)) if _readable_recipe_rows else 300.0
	side.custom_minimum_size = Vector2(list_width, 0)

	# Bounded scroll, not an unbounded VBoxContainer directly in `side`: with
	# every unlocked-by-default recipe known from the start, this list is
	# routinely taller than LIST_VISIBLE_HEIGHT, and an unbounded column here
	# was pushing the whole panel past the screen the same way shop_panel.gd's
	# rows did (OF31 sweep) -- it just read as "empty" instead of "clipped"
	# because the row-building crash below (`text_overrun_behavior`, fixed
	# alongside this) had been leaving `_rows` empty, so nothing was tall
	# enough to notice.
	_list_scroll = ScrollContainer.new()
	var list_height := float(LIST_VISIBLE_HEIGHT)
	if _readable_recipe_rows:
		var visible_rows := maxi(1, int(_presentation.get("visible_rows", 3)))
		list_height = visible_rows * float(_presentation.get("row_height", 208)) + (visible_rows - 1) * 8.0
	if is_instance_valid(_station):
		# Leave room for the single upgrade line and actual station controls.
		# Existing explicit D-pad links keep clipped recipe rows reachable.
		list_height=minf(list_height,maxf(float(ROW_HEIGHT),get_viewport().get_visible_rect().size.y*0.38))
	_list_scroll.custom_minimum_size = Vector2(list_width, list_height)
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(_list_scroll)

	var rows_col := VBoxContainer.new()
	rows_col.add_theme_constant_override("separation", 8)
	rows_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_scroll.add_child(rows_col)

	var db := _items()
	for id: Variant in _known_ids():
		var recipe_id := str(id)
		_recipe_ids.append(recipe_id)
		var recipe: Dictionary = db.call("recipe", recipe_id) if db != null else {}
		rows_col.add_child(_make_row(recipe_id, recipe))

	# Godot's default D-pad focus search is geometric, and it does not treat a
	# ScrollContainer's clip boundary any differently from the edge of the
	# screen: a row past LIST_VISIBLE_HEIGHT is excluded from the search
	# entirely until it is actually scrolled into view -- which
	# `ensure_control_visible` (in `_make_row`) can only do once focus has
	# already reached that row. That deadlock silently capped D-pad Down at
	# the sixth recipe (measured: `smoke_craft_panel_controller.gd` on Small
	# Potion, recipe index 10). Same fix `tab_settings.gd::_link_vertical`
	# already uses for its own scrolled debug-teleport list: chain each row to
	# its immediate neighbours explicitly so Up/Down never has to cross the
	# clip boundary via the spatial search at all.
	for i in _rows.size():
		if i > 0:
			_rows[i].focus_neighbor_top = _rows[i].get_path_to(_rows[i - 1])
		if i + 1 < _rows.size():
			_rows[i].focus_neighbor_bottom = _rows[i].get_path_to(_rows[i + 1])

	return side


func _make_row(id: String, recipe: Dictionary) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(300, ROW_HEIGHT)
	if _readable_recipe_rows:
		button.custom_minimum_size = Vector2(float(_presentation.get("list_width", 480)), float(_presentation.get("row_height", 208)))
	button.focus_mode = Control.FOCUS_ALL
	button.text = ""
	button.add_theme_stylebox_override("normal", UITokens.slot_box(false))
	button.add_theme_stylebox_override("hover", UITokens.slot_box(false))
	button.add_theme_stylebox_override("pressed", UITokens.slot_box(true))
	button.add_theme_stylebox_override("focus", UITokens.slot_box(true))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# `Button` is not a `Container` and never asks its children how tall they
	# want to be, so a cost line long enough to wrap past ROW_HEIGHT does not
	# grow the row -- it just draws past its own bottom edge. Godot then
	# paints the NEXT row's Button (added after this one, so drawn on top of
	# it) directly over that overflow, which is what a blind visual-judge
	# pass read as "ingredients spill into the next row's title" with
	# "orphaned ghost strings" behind the rows, and the last row printing
	# over the footer. `clip_contents` makes the overflow impossible instead
	# of merely unlikely: whatever the row's real content turns out to need,
	# nothing it draws can ever leave this Button's own rect.
	button.clip_contents = true

	var pad := MarginContainer.new()
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_theme_constant_override("margin_left", 10)
	pad.add_theme_constant_override("margin_right", 10)
	pad.add_theme_constant_override("margin_top", 6)
	pad.add_theme_constant_override("margin_bottom", 6)
	button.add_child(pad)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	pad.add_child(row)

	var output: Dictionary = recipe.get("output", {})
	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(ROW_ICON_PX, ROW_ICON_PX)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _icon_texture(str(output.get("id", "")))
	row.add_child(icon)

	var text_col := VBoxContainer.new()
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_col.add_theme_constant_override("separation", 2)
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_col)

	var name := Label.new()
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name.text = str(recipe.get("name", id))
	# VIS-UI-r5: this label had no overrun handling, so `button.clip_contents`
	# (above) chopped a long recipe name off mid-word at the row edge with no
	# affordance -- "Ironwood Haft (Axe" and nothing to signal more text
	# existed. Same ellipsis pattern `cost_label` already uses below.
	name.autowrap_mode = TextServer.AUTOWRAP_OFF
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name.clip_text = true
	if _readable_recipe_rows:
		name.clip_text = false
		name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name.max_lines_visible = 2
	name.add_theme_font_size_override("font_size", UITokens.FONT_READ if _readable_recipe_rows else UITokens.FONT_BODY)
	name.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	text_col.add_child(name)

	var cost_label := Label.new()
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_label.text = _cost_line(recipe)
	# Single line, ellipsis on overflow -- NOT word-wrap. Word-wrap made the
	# line grow with ingredient count, which is what blew past ROW_HEIGHT in
	# the first place (see `_make_row`'s `clip_contents` comment); wrapping
	# also used to just get chopped wherever the row's real height ran out,
	# which is the "lists truncate on a hanging comma" a blind visual-judge
	# pass caught -- a raw cut mid-list reads as broken text, not as "there's
	# more". Ellipsis is bounded and honest about being a summary; the full,
	# untruncated ingredient list is still shown in the right-hand detail
	# column (`_describe`) for whichever row is focused.
	cost_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	cost_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	cost_label.clip_text = true
	if _readable_recipe_rows:
		cost_label.clip_text = false
		cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cost_label.max_lines_visible = 4
	cost_label.add_theme_font_size_override("font_size", UITokens.FONT_READ if _readable_recipe_rows else UITokens.FONT_TINY)
	text_col.add_child(cost_label)
	_cost_labels.append(cost_label)

	button.pressed.connect(func() -> void: _craft(id))
	var index := _rows.size()
	button.focus_entered.connect(func() -> void:
		_select(index)
		if _list_scroll != null:
			_list_scroll.ensure_control_visible(button)
	)
	_rows.append(button)
	return button


## CENTER: the selected recipe's output, large — the one thing the player is
## actually deciding whether to spend materials on.
func _build_center_zone() -> Control:
	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 10)
	side.custom_minimum_size = Vector2(200, 0)
	side.alignment = BoxContainer.ALIGNMENT_CENTER
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_center_icon = TextureRect.new()
	_center_icon.custom_minimum_size = Vector2(CENTER_ICON_PX, CENTER_ICON_PX)
	_center_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_center_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	side.add_child(_center_icon)

	_center_name = Label.new()
	_center_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _readable_recipe_rows:
		_center_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_center_name.add_theme_font_size_override("font_size", UITokens.FONT_SECTION if _readable_recipe_rows else UITokens.FONT_HEADING)
	_center_name.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	side.add_child(_center_name)

	return side


## RIGHT: what it costs, whether the satchel has it, what it does, and how to
## commit — the detail column `tab_build.gd`'s own list/detail split already
## proved out for the same "can I afford this" decision.
func _build_right_zone() -> Control:
	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 10)
	side.custom_minimum_size = Vector2(280, 0)
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var ingredients_header := Label.new()
	ingredients_header.text = "Ingredients"
	ingredients_header.add_theme_font_size_override("font_size", UITokens.FONT_SECTION if _readable_recipe_rows else UITokens.FONT_TINY)
	ingredients_header.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	side.add_child(ingredients_header)

	_ingredients_col = VBoxContainer.new()
	_ingredients_col.add_theme_constant_override("separation", 6)
	side.add_child(_ingredients_col)

	_output_line = Label.new()
	_output_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_output_line.add_theme_font_size_override("font_size", UITokens.FONT_READ if _readable_recipe_rows else UITokens.FONT_LABEL)
	_output_line.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	side.add_child(_output_line)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", UITokens.FONT_READ if _readable_recipe_rows else UITokens.FONT_LABEL)
	side.add_child(_status)

	_craft_hint = Label.new()
	_craft_hint.text = "Craft: A / Enter"
	_craft_hint.add_theme_font_size_override("font_size", UITokens.FONT_PROMPT if _readable_action_hints else UITokens.FONT_TINY)
	_craft_hint.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY if _readable_action_hints else UITokens.TEXT_MUTED)
	side.add_child(_craft_hint)

	return side


func _cancel_glyph() -> String:
	# input_glyph.gd (HD1/EV9) covers the exploration/combat prompts named in
	# their own briefs; this screen is neither, so it names the action rather
	# than assuming that glyph set already reaches here.
	return "B / Esc"


func _process(delta: float) -> void:
	if not _open:
		return
	if Input.is_action_just_pressed("menu_cancel"):
		INPUT_OWNER.suppress_pause_reopen(get_tree())
		close()
		return
	if is_instance_valid(_station):
		if not _gear_cfg.is_empty() and _gear_context(_station_view()) != _presented_gear_context: _station_view_completed()
		_refresh_next_upgrade()
	elif _station_mode:
		_status.text="Waiting for the original station transaction to reconcile." if not _station_intent.is_empty() else "This station is no longer available."
		for button: Button in _rows: button.disabled=true
		for button: Button in _station_buttons:
			button.disabled=button.text != "Retry original transaction" or (_station_intent.is_empty() and _retained_station_transaction().is_empty())
		return
	if _status_left > 0.0:
		_status_left -= delta
		if _status_left <= 0.0:
			_status.text = ""
	_poll()


func _craft(id: String) -> void:
	if not _station_intent.is_empty() or (_station_mode and not is_instance_valid(_station)): return
	if is_instance_valid(_station):
		if _station.get_meta("building_id","") == CAMP_RULES.ID:
			var legal := CAMP_RULES.recipe(id,_items().call("recipe",id),str(_station.get("camp_part")))
			if legal.get("ok") != true:
				_status.text=legal.reason
				return
		_station_action("station_craft", {"recipe_id":id})
		return
	# Once enabled, home station recipes cannot fall through the campfire's
	# legacy inventory-only craft path; host producer remains the only writer.
	if STATION_RULES.config().get("runtime_enabled") == true and not STATION_RULES.config().recipe_routes.get("field_allowed",[]).has(id):
		_status.text = "Use the homestead station for this recipe."
		return
	var ok := bool(game.call("craft", id)) if game != null else false
	var db := _items()
	var name := str(db.call("recipe", id).get("name", id)) if db != null else id
	_status.text = "Crafted a %s." % name if ok else "Not enough materials for %s." % name
	_status.add_theme_color_override("font_color", UITokens.SUCCESS if ok else UITokens.DANGER)
	_status_left = STATUS_SECONDS
	_poll()


## Focus moved onto a different row: redraw the hero/detail columns for it.
func _select(index: int) -> void:
	_selected = index
	_describe(index)


func _poll() -> void:
	var db := _items()
	if db == null:
		return
	for i in _rows.size():
		if i >= _recipe_ids.size():
			continue
		var id := _recipe_ids[i]
		var affordable: bool = bool(game.call("can_craft", id)) if game != null else false
		if is_instance_valid(_station):
			var route := STATION_RULES.recipe_route(STATION_RULES.config(),id,_items().call("recipe",id))
			var cfg := STATION_RULES.config()
			var tier := STATION_RULES.effective_tier(cfg,game.get("placed_buildings"),str(_station.get_meta("building_uid", "")))
			if _station.get_meta("building_id","") == CAMP_RULES.ID:
				route=CAMP_RULES.recipe(id,_items().call("recipe",id),str(_station.get("camp_part")))
				tier={"ok":CAMP_RULES.record(game.get("placed_buildings"),str(_station.get_meta("building_uid",""))).get("ok") == true,"effective_tier":0}
			affordable = affordable and _station_intent.is_empty() and tier.get("ok") == true and route.get("ok") == true and int(tier.get("effective_tier",0)) >= int(route.get("required_tier",9))
		var colour := UITokens.SUCCESS if affordable else UITokens.DANGER
		if i < _cost_labels.size():
			_cost_labels[i].add_theme_color_override("font_color", colour)
			if _readable_recipe_rows:
				_cost_labels[i].text = _cost_line(db.call("recipe", id))
	_describe(_selected)


## Fills the center hero and right detail columns for recipe `index`.
func _describe(index: int) -> void:
	if _center_name == null or index < 0 or index >= _recipe_ids.size():
		return
	var db := _items()
	if db == null:
		return
	var id := _recipe_ids[index]
	var recipe: Dictionary = db.call("recipe", id)
	var output: Dictionary = recipe.get("output", {})
	var output_id := str(output.get("id", ""))

	_center_icon.texture = _icon_texture(output_id)
	_center_name.text = str(recipe.get("name", id))

	for child in _ingredients_col.get_children():
		child.queue_free()

	var inventory := _inventory()
	var raw: Variant = recipe.get("cost", [])
	for entry: Variant in (raw as Array if typeof(raw) == TYPE_ARRAY else []):
		var requirement := entry as Dictionary
		var item_id := str(requirement.get("id", ""))
		var need := int(requirement.get("n", 0))
		var have: int = int(inventory.call("count", item_id)) if inventory != null else 0
		var enough := have >= need
		_ingredients_col.add_child(_make_ingredient_row(item_id, need, have, enough))

	_output_line.text = "Makes: %s — %s" % [str(recipe.get("name", id)), str(recipe.get("blurb", ""))]


func _make_ingredient_row(item_id: String, need: int, have: int, enough: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(INGREDIENT_ICON_PX, INGREDIENT_ICON_PX)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _icon_texture(item_id)
	row.add_child(icon)

	var db := _items()
	var name := str(db.call("item_name", item_id)) if db != null else item_id
	var label := Label.new()
	label.text = "%s %d / have %d" % [name, need, have]
	label.add_theme_font_size_override("font_size", UITokens.FONT_SECTION if _readable_recipe_rows else UITokens.FONT_BODY)
	label.add_theme_color_override("font_color", UITokens.SUCCESS if enough else UITokens.DANGER)
	row.add_child(label)

	return row


func _cost_line(recipe: Dictionary) -> String:
	var db := _items()
	var inventory := _inventory()
	var parts: Array[String] = []
	var raw: Variant = recipe.get("cost", [])
	for entry in (raw as Array if typeof(raw) == TYPE_ARRAY else []):
		var requirement := entry as Dictionary
		var id := str(requirement.get("id", ""))
		var need := int(requirement.get("n", 0))
		var have: int = int(inventory.call("count", id)) if inventory != null else 0
		var name := str(db.call("item_name", id)) if db != null else id
		# Ownership counts remain in the selected recipe's ingredient panel.
		# The list needs a short, distinguishable preview of every requirement.
		parts.append("%d %s (have %d)" % [need, name, have])
	return ", ".join(parts)


## `id`'s 64px silhouette from `data/items/items.json`'s own `icon` field, or
## null for an unknown item — a null `TextureRect.texture` just draws nothing,
## the same "degrade, never crash" rule `item_db.gd`'s header comment states
## for every other unknown-id lookup in this file.
func _icon_texture(id: String) -> Texture2D:
	var db := _items()
	if db == null or id.is_empty():
		return null
	var path := str(db.call("definition", id).get("icon", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _items() -> RefCounted:
	return game.get("items") if game != null else null


func _inventory() -> RefCounted:
	return game.get("inventory") if game != null else null
