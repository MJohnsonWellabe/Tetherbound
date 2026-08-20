extends CanvasLayer

## D39 (OF31). Oskar's creature swap: his one, for one of yours.
##
## Owner: "Make the villagers so I can trade with them. Creatures and
## materials..." -- and the owner's answer to how creature trades work was a
## SWAP, not a purchase. So this screen has no prices on it at all: it shows
## what Oskar is offering today, lists your party, and asks which one you are
## handing over.
##
## Two presses, never one. Picking a party row does NOT trade -- it opens a
## confirm block naming both creatures, and the trade happens on the second
## press. Giving away a creature you have levelled is the most irreversible
## thing the village can do to a save, and the pause menu's own release
## ceremony (D38) already set the precedent that it takes a deliberate second
## input.
##
## The five-cap and the never-empty rule are NOT enforced here -- they live in
## `scripts/trade/creature_trade.gd::swap()`, which does the whole thing as one
## remove-then-add transaction. This panel only ever asks it and shows what it
## says back, which is why the invariant test can be a unit test.
##
## Built and opened the same way `shop_panel.gd`/`storage_panel.gd` are: in
## code, paused, mouse released, rows as real focusable `Button`s so a pad can
## walk them.

const UITokens := preload("res://scripts/ui/ui_tokens.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const TRADE_DB := preload("res://scripts/trade/trade_db.gd")
const CREATURE_TRADE := preload("res://scripts/trade/creature_trade.gd")
const PARTY := preload("res://autoload/party.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const SPECIES_PATH := "res://data/creatures/species.json"

var game: Node = null

var _trade: RefCounted = null
var _root: Control = null
var _title: Label = null
var _offer_column: VBoxContainer = null
var _party_column: VBoxContainer = null
var _message: Label = null
var _rows: Array[Button] = []
var _open: bool = false
var _trader_id: String = ""
var _pending_index: int = -1
var _offer: Dictionary = {}
var _offer_creature: RefCounted = null
var _mouse_before: int = Input.MOUSE_MODE_VISIBLE
var _paused_before: bool = false


func _ready() -> void:
	game = get_node_or_null(^"/root/Game")
	_trade = TRADE_DB.new()
	_build_shell()
	visible = false
	# RG4: see craft_panel.gd's own comment on this line -- `input_owner.gd`
	# has claimed since OW10 that this panel already joins its GROUP; it
	# never did.
	add_to_group(INPUT_OWNER.GROUP)


func is_open() -> bool:
	return _open


func trader_id() -> String:
	return _trader_id


## The creature standing behind today's offer. Built once per open, so the
## thing shown and the thing received are the same object.
func offer_creature() -> RefCounted:
	return _offer_creature


func open(trader: String) -> void:
	_trader_id = trader
	_pending_index = -1
	_build_offer()
	if _open:
		_refresh()
		return
	_open = true
	visible = true
	_mouse_before = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_paused_before = get_tree().paused
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _message != null:
		_message.text = ""
	_refresh()
	if not _rows.is_empty():
		_rows[0].grab_focus()


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	_pending_index = -1
	# RG1: release is determined by the live ownership graph, not by the
	# pause bit this panel happened to observe when it opened. A cached
	# true value can come from a previous modal in the same handoff and
	# restoring it after every visible panel is gone freezes the world.
	if INPUT_OWNER.current(get_tree()) == null:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_tree().paused = false


func _process(_delta: float) -> void:
	if not _open:
		return
	if Input.is_action_just_pressed("menu_cancel"):
		# Back out of the confirm first, out of the panel second. A cancel that
		# closed the whole screen from a confirm would make "I picked the wrong
		# one" cost a whole conversation.
		if _pending_index >= 0:
			_pending_index = -1
			_refresh()
			return
		INPUT_OWNER.suppress_pause_reopen(get_tree())
		close()


## --- today's offer -------------------------------------------------------------

func _config() -> Dictionary:
	if _trade == null:
		return {}
	return _trade.call("config") as Dictionary


func _day() -> int:
	return int(game.get("day")) if game != null else 1


func _species_definition(species_id: String) -> Dictionary:
	var file := FileAccess.open(SPECIES_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var table: Variant = (parsed as Dictionary).get("species", {})
	if typeof(table) != TYPE_DICTIONARY:
		return {}
	var entry: Variant = (table as Dictionary).get(species_id, {})
	return entry as Dictionary if typeof(entry) == TYPE_DICTIONARY else {}


func _build_offer() -> void:
	_offer = CREATURE_TRADE.offer_for_day(_config(), _trader_id, _day())
	_offer_creature = null
	if _offer.is_empty():
		return
	# Already taken this rotation? Then there is nothing standing behind the
	# offer, and the panel says so rather than showing a creature it will
	# refuse to hand over.
	if _swap_taken():
		return
	_offer_creature = CREATURE_TRADE.offered_creature(
		_offer, _species_definition(str(_offer.get("species", ""))), _trader_id, PROGRESSION.config()
	)


func _progression() -> RefCounted:
	return game.get("progression") if game != null else null


func _swap_taken() -> bool:
	var progression := _progression()
	if progression == null or _offer.is_empty():
		return false
	return bool(progression.call("has",
		CREATURE_TRADE.swap_flag(_trader_id, int(_offer.get("period", 0)))))


## --- the screen ----------------------------------------------------------------

func _build_shell() -> void:
	for child in get_children():
		child.queue_free()
	_rows.clear()

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
	box.corner_radius_top_left = 14
	box.corner_radius_top_right = 14
	box.corner_radius_bottom_left = 14
	box.corner_radius_bottom_right = 14
	box.content_margin_left = 24
	box.content_margin_top = 20
	box.content_margin_right = 24
	box.content_margin_bottom = 20

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", box)
	panel.custom_minimum_size = Vector2(760, 0)
	center.add_child(panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)

	_title = Label.new()
	_title.text = "Swap"
	_title.add_theme_font_size_override("font_size", UITokens.FONT_HEADING)
	_title.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	outer.add_child(_title)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	outer.add_child(columns)

	var offer_side := VBoxContainer.new()
	offer_side.add_theme_constant_override("separation", 8)
	offer_side.custom_minimum_size = Vector2(330, 0)
	columns.add_child(offer_side)
	var offer_label := Label.new()
	offer_label.text = "Oskar offers"
	offer_label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	offer_label.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	offer_side.add_child(offer_label)
	_offer_column = VBoxContainer.new()
	_offer_column.add_theme_constant_override("separation", 4)
	offer_side.add_child(_offer_column)

	var party_side := VBoxContainer.new()
	party_side.add_theme_constant_override("separation", 8)
	party_side.custom_minimum_size = Vector2(360, 0)
	columns.add_child(party_side)
	var party_label := Label.new()
	party_label.text = "Your creatures — press to offer one"
	party_label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	party_label.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	party_side.add_child(party_label)
	_party_column = VBoxContainer.new()
	_party_column.add_theme_constant_override("separation", 6)
	party_side.add_child(_party_column)

	_message = Label.new()
	_message.add_theme_font_size_override("font_size", UITokens.FONT_BODY)
	_message.add_theme_color_override("font_color", UITokens.SUCCESS)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_message)

	var hint := Label.new()
	hint.text = "Leave: B / Esc"
	hint.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	hint.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	outer.add_child(hint)


func _refresh() -> void:
	if _offer_column == null or _party_column == null:
		return
	if _title != null:
		_title.text = str(CREATURE_TRADE.trader(_config(), _trader_id).get("title", "Swap"))
	_rows.clear()
	_draw_offer()
	if _pending_index >= 0:
		_draw_confirm()
	else:
		_draw_party()
	UITokens.make_text_legible(_root)


## Text, not a rendered creature. The offer is genuinely new information (a
## species you may never have seen), so it is spelled out -- species, level and
## the three stats a player can compare against their own party row.
func _draw_offer() -> void:
	for child in _offer_column.get_children():
		child.queue_free()
	if _offer_creature == null:
		_offer_column.add_child(_text_line(
			CREATURE_TRADE.refusal_text(
				CREATURE_TRADE.REFUSED_TAKEN if _swap_taken() else CREATURE_TRADE.REFUSED_NO_OFFER
			),
			UITokens.TEXT_MUTED
		))
		return
	_offer_column.add_child(_text_line(
		"%s   Lv %d" % [str(_offer_creature.call("label")), int(_offer_creature.get("level"))],
		UITokens.TEXT_PRIMARY
	))
	_offer_column.add_child(_text_line(
		str(_offer_creature.get("creature_type")).capitalize(), UITokens.TEXT_SECONDARY
	))
	_offer_column.add_child(_text_line("HP %d" % int(round(float(_offer_creature.get("max_hp")))), UITokens.TEXT_SECONDARY))
	_offer_column.add_child(_text_line("Attack %d" % int(round(float(_offer_creature.get("attack")))), UITokens.TEXT_SECONDARY))
	_offer_column.add_child(_text_line("Defence %d" % int(round(float(_offer_creature.get("defence")))), UITokens.TEXT_SECONDARY))
	_offer_column.add_child(_text_line("A straight swap. No coins.", UITokens.TEXT_MUTED))


func _draw_party() -> void:
	for child in _party_column.get_children():
		child.queue_free()
	var party: RefCounted = game.get("party") if game != null else null
	if party == null:
		return
	var last_one := int(party.call("size")) <= 1
	for i in PARTY.MAX_CREATURES:
		var creature: RefCounted = party.call("at", i)
		if creature == null:
			continue
		var button := _row_button(
			"  %d.  %s   Lv %d" % [i + 1, str(creature.call("label")), int(creature.get("level"))],
			not last_one and _offer_creature != null
		)
		var index := i
		button.pressed.connect(func() -> void: _on_pick(index))
		_party_column.add_child(button)
		_rows.append(button)
	if last_one:
		_party_column.add_child(_text_line(
			CREATURE_TRADE.refusal_text(CREATURE_TRADE.REFUSED_LAST_CREATURE), UITokens.WARNING
		))

	# RG6 (owner: "Menus don't read every input still."). `open()` grabs
	# focus once, right after its own first `_refresh()` -- but backing out
	# of a pending confirm (`_process`'s `menu_cancel` handler above) calls
	# `_refresh()` again on its own, straight into this function, with no
	# grab_focus after it. That rebuilds every party row fresh and leaves
	# nothing focused: a controller player who picked a creature, changed
	# their mind, and backed out landed on a screen where the stick and
	# d-pad did nothing at all.
	if not _rows.is_empty():
		_rows[0].grab_focus()


func _draw_confirm() -> void:
	for child in _party_column.get_children():
		child.queue_free()
	var party: RefCounted = game.get("party") if game != null else null
	var giving: RefCounted = party.call("at", _pending_index) if party != null else null
	if giving == null or _offer_creature == null:
		_pending_index = -1
		_draw_party()
		return

	_party_column.add_child(_text_line(
		"Give %s for %s?" % [str(giving.call("label")), str(_offer_creature.call("label"))],
		UITokens.TEXT_PRIMARY
	))
	_party_column.add_child(_text_line("You will not get them back.", UITokens.TEXT_MUTED))

	var confirm := _row_button("  Trade", true)
	confirm.pressed.connect(func() -> void: confirm_swap())
	_party_column.add_child(confirm)
	_rows.append(confirm)

	var cancel := _row_button("  Keep %s" % str(giving.call("label")), true)
	cancel.pressed.connect(func() -> void:
		_pending_index = -1
		_refresh())
	_party_column.add_child(cancel)
	_rows.append(cancel)
	confirm.call_deferred("grab_focus")


func _text_line(text: String, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", UITokens.FONT_BODY)
	label.add_theme_color_override("font_color", colour)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _row_button(text: String, enabled: bool) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(340, 52)
	button.focus_mode = Control.FOCUS_ALL
	button.text = text
	button.disabled = not enabled
	button.clip_text = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", UITokens.FONT_BODY)
	button.add_theme_stylebox_override("normal", UITokens.slot_box(false))
	button.add_theme_stylebox_override("hover", UITokens.slot_box(false))
	button.add_theme_stylebox_override("pressed", UITokens.slot_box(true))
	button.add_theme_stylebox_override("focus", UITokens.slot_box(true))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button


## --- the trade -----------------------------------------------------------------

## Choose which of yours is on the table. Does NOT trade.
func pick(index: int) -> void:
	_on_pick(index)


func _on_pick(index: int) -> void:
	_pending_index = index
	if _message != null:
		_message.text = ""
	_refresh()


## Second press. Returns "" on success or a `creature_trade.gd` refusal reason,
## so a smoke test can assert the refusal rather than reading the label.
func confirm_swap() -> String:
	var party: RefCounted = game.get("party") if game != null else null
	if party == null or _offer_creature == null:
		return CREATURE_TRADE.REFUSED_NO_OFFER
	var giving: RefCounted = party.call("at", _pending_index)
	var given_label := str(giving.call("label")) if giving != null else ""
	var reason := str(CREATURE_TRADE.swap(party, _pending_index, _offer_creature))
	if _message != null:
		if reason == CREATURE_TRADE.OK:
			_message.add_theme_color_override("font_color", UITokens.SUCCESS)
			_message.text = "%s goes with Oskar. %s is yours." % [
				given_label, str(_offer_creature.call("label"))
			]
		else:
			_message.add_theme_color_override("font_color", UITokens.WARNING)
			_message.text = CREATURE_TRADE.refusal_text(reason)
	if reason == CREATURE_TRADE.OK:
		# One swap per rotation, recorded where every other one-time village
		# event is recorded (D43's flag store) so it survives a save and a
		# re-open of this panel. See `creature_trade.swap_flag()` for why.
		var progression := _progression()
		if progression != null:
			progression.call("set_flag",
				CREATURE_TRADE.swap_flag(_trader_id, int(_offer.get("period", 0))))
		_offer_creature = null
	_pending_index = -1
	_refresh()
	return reason
