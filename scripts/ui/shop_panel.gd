extends CanvasLayer

## D39 (OF31). Mira's store: what she sells on the left, what she will buy off
## you on the right, coins counted along the top.
##
## Owner: "Make one of the villagers the merchant. He has a store in his house.
## He'll buy and sell goods from you."
##
## Deliberately the same screen `storage_panel.gd` already is -- two columns,
## one press moves one unit, built entirely in code, opened by pausing and
## releasing the mouse -- because a shop IS a transfer screen with a price
## attached, and the player has already learned that screen at a chest. Same
## `UITokens` palette, same slot boxes, same "rebuilt every refresh rather than
## diffed" call (this only exists while paused in front of a merchant).
##
## Every number on screen comes from `scripts/trade/trade_db.gd`, which reads
## data/config/trade.json. There is no price literal in this file, and adding
## one would put the economy in the UI.
##
## Controller-first: rows are real `Button`s with `focus_mode = FOCUS_ALL`, so
## the pad's own focus navigation walks them and `menu_confirm` presses them --
## the same reason `craft_panel.gd` grabs focus on its first row when it opens.

const UITokens := preload("res://scripts/ui/ui_tokens.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const TRADE_DB := preload("res://scripts/trade/trade_db.gd")
const ROW_ICON_PX := 24
const PRICE_COLUMN_PX := 70

## Panel D39 (OF31 defect sweep, frame 20): with Coin: 0 and a full 17-item
## catalogue, the unbounded panel grew past 1080px tall and clipped both its
## own rounded corners and the "Leave" hint off the bottom of the screen --
## the CenterContainer this sits in only centers a child, it never bounds one.
## A fixed panel height plus a ScrollContainer around the rows (same fix
## tab_settings.gd/tab_quest_log.gd already use for their own unbounded lists)
## keeps the panel on screen regardless of how many items trade.json lists,
## with the coin/title header and the Leave hint permanently visible outside
## the scrolling region.
const PANEL_HEIGHT := 860

var game: Node = null

var _trade: RefCounted = null
var _root: Control = null
var _title: Label = null
var _purse: Label = null
var _buy_column: VBoxContainer = null
var _sell_column: VBoxContainer = null
var _columns_scroll: ScrollContainer = null
var _message: Label = null
var _rows: Array[Button] = []
var _open: bool = false
var _vendor_id: String = ""
var _mouse_before: int = Input.MOUSE_MODE_VISIBLE
var _paused_before: bool = false


func _ready() -> void:
	game = get_node_or_null(^"/root/Game")
	_trade = TRADE_DB.new()
	_build_shell()
	visible = false
	# RG4 (owner: "The builds even with free build on won't place. Except a
	# workbench."). `input_owner.gd`'s own header has claimed since OW10 that
	# this panel already joins its GROUP alongside craft/storage/swap/
	# creature_bed; it never did. This panel pausing the tree hid the gap for
	# any poller that only runs in-tree, but left `INPUT_OWNER.current()`
	# blind to it -- nothing generic could tell it was open, or recover if
	# this panel's own close() was ever skipped, which is exactly the failure
	# shape a real RG4-style report -- "nothing works, no explanation" --
	# takes: the trader's shop screen (auto-opened at the end of a greeting,
	# not something the player deliberately chose to enter) is the one modal
	# in the whole panel family invisible to the shared "who owns input"
	# answer every other gate in the game already trusts.
	add_to_group(INPUT_OWNER.GROUP)


func is_open() -> bool:
	return _open


func vendor_id() -> String:
	return _vendor_id


## `vendor` is a key in data/config/trade.json's `vendors` -- "mira" today.
func open(vendor: String) -> void:
	_vendor_id = vendor
	if _open:
		_refresh()
		return
	_open = true
	visible = true
	_mouse_before = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_paused_before = get_tree().paused
	get_tree().paused = true
	# A station panel is a modal surface, and the exploration HUD was drawn
	# straight over the top of it -- the creature block, roster, vitals,
	# hotbar and minimap all still painting across this panel's own rows. It
	# went unnoticed because the UI survey used to shoot these panels with no
	# world loaded at all, so there was no HUD in the frame to collide with.
	INPUT_OWNER.set_world_hud_visible(get_tree(), false)
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
	# RG1: release is determined by the live ownership graph, not by the
	# pause bit this panel happened to observe when it opened. A cached
	# true value can come from a previous modal in the same handoff and
	# restoring it after every visible panel is gone freezes the world.
	if INPUT_OWNER.current(get_tree()) == null:
		# Only once nothing else owns the screen -- restoring on any close
		# would put the HUD back over a panel that is still open underneath.
		INPUT_OWNER.set_world_hud_visible(get_tree(), true)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_tree().paused = false


func _process(_delta: float) -> void:
	if not _open:
		return
	if Input.is_action_just_pressed("menu_cancel"):
		INPUT_OWNER.suppress_pause_reopen(get_tree())
		close()


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
	# Height is a floor AND the effective ceiling here: PanelContainer only
	# ever grows past custom_minimum_size for a child that actually demands
	# more, and the one child that could (the row scroll below) is a
	# ScrollContainer, which never reports its content's full height as its
	# own minimum -- that is the whole mechanism scrolling relies on. So this
	# number is really "how tall the panel gets", not a mere hint.
	panel.custom_minimum_size = Vector2(720, PANEL_HEIGHT)
	center.add_child(panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	outer.add_child(header)

	_title = Label.new()
	_title.text = "Store"
	_title.add_theme_font_size_override("font_size", UITokens.FONT_HEADING)
	_title.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	header.add_child(_title)

	_purse = Label.new()
	_purse.add_theme_font_size_override("font_size", UITokens.FONT_BODY)
	_purse.add_theme_color_override("font_color", UITokens.WARNING)
	header.add_child(_purse)

	# Seventeen items in trade.json's stocked list (and growing) do not fit
	# unpaginated in one column at this font size -- the shop used to just
	# keep drawing rows past the panel's own bottom edge. One shared scroll
	# for both columns, same "one container for the whole tab" shape
	# tab_settings.gd/tab_quest_log.gd already use, rather than a second
	# hand-rolled scroll mechanism per column.
	_columns_scroll = ScrollContainer.new()
	_columns_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_columns_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(_columns_scroll)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	_columns_scroll.add_child(columns)

	var buy_side := VBoxContainer.new()
	buy_side.add_theme_constant_override("separation", 8)
	buy_side.custom_minimum_size = Vector2(330, 0)
	columns.add_child(buy_side)
	var buy_label := Label.new()
	buy_label.text = "For sale — press to buy one"
	buy_label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	buy_label.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	buy_side.add_child(buy_label)
	_buy_column = VBoxContainer.new()
	_buy_column.add_theme_constant_override("separation", 6)
	buy_side.add_child(_buy_column)

	var sell_side := VBoxContainer.new()
	sell_side.add_theme_constant_override("separation", 8)
	sell_side.custom_minimum_size = Vector2(330, 0)
	columns.add_child(sell_side)
	var sell_label := Label.new()
	sell_label.text = "Your satchel — press to sell one"
	sell_label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	sell_label.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	sell_side.add_child(sell_label)
	_sell_column = VBoxContainer.new()
	_sell_column.add_theme_constant_override("separation", 6)
	sell_side.add_child(_sell_column)

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


func _inventory() -> RefCounted:
	return game.get("inventory") if game != null else null


func _items() -> RefCounted:
	return game.get("items") if game != null else null


func _refresh() -> void:
	if _trade == null or _buy_column == null:
		return
	var inventory := _inventory()
	var db := _items()
	if inventory == null or db == null:
		return

	if _title != null:
		_title.text = _trade.call("vendor_title", _vendor_id)
	if _purse != null:
		var coin := str(_trade.call("currency_id"))
		_purse.text = "%s: %d" % [str(db.call("item_name", coin)), int(inventory.call("count", coin))]

	# Buying or selling changes both columns, so the rows are rebuilt -- which
	# destroys the focused Button under a pad user's thumb. Remembering WHICH
	# row was focused and taking it back afterwards is the difference between
	# a controller-first shop and one that drops you back to nowhere after
	# every single purchase.
	var focused := _focused_row_index()
	_rows.clear()
	_rebuild_buy_side(db, inventory)
	_rebuild_sell_side(db, inventory)
	UITokens.make_text_legible(_root)
	if focused >= 0 and not _rows.is_empty():
		var landing: Button = _rows[clampi(focused, 0, _rows.size() - 1)]
		landing.call_deferred("grab_focus")


func _focused_row_index() -> int:
	for i in _rows.size():
		var row: Button = _rows[i]
		if is_instance_valid(row) and row.has_focus():
			return i
	return -1


## What the vendor will hand over, in data/config/trade.json's own order.
func _rebuild_buy_side(db: RefCounted, inventory: RefCounted) -> void:
	for child in _buy_column.get_children():
		child.queue_free()
	var coin := str(_trade.call("currency_id"))
	var purse := int(inventory.call("count", coin))
	var listed := 0
	for raw: Variant in (_trade.call("stocked_ids", _vendor_id) as Array):
		var item_id := str(raw)
		var price := int(_trade.call("buy_price", _vendor_id, item_id))
		var affordable := purse >= price
		var row := _row(
			db, item_id,
			str(db.call("item_name", item_id)), str(price),
			affordable
		)
		row.pressed.connect(func() -> void: _on_buy(item_id))
		_buy_column.add_child(row)
		_rows.append(row)
		listed += 1
	if listed == 0:
		_buy_column.add_child(_empty_label("(nothing for sale today)"))


## Everything in the satchel the vendor has a price for. Driven off the
## SATCHEL, so an item you do not carry never appears -- the same rule
## storage_panel.gd's own columns keep.
func _rebuild_sell_side(db: RefCounted, inventory: RefCounted) -> void:
	for child in _sell_column.get_children():
		child.queue_free()
	var listed := 0
	for raw: Variant in (_trade.call("traded_ids", _vendor_id) as Array):
		var item_id := str(raw)
		if not bool(_trade.call("buys", _vendor_id, item_id)):
			continue
		var have := int(inventory.call("count", item_id))
		if have <= 0:
			continue
		var price := int(_trade.call("sell_price", _vendor_id, item_id))
		var row := _row(
			db, item_id,
			"%s x%d" % [str(db.call("item_name", item_id)), have], "+%d" % price,
			true
		)
		row.pressed.connect(func() -> void: _on_sell(item_id))
		_sell_column.add_child(row)
		_rows.append(row)
		listed += 1
	if listed == 0:
		_sell_column.add_child(_empty_label("(nothing she wants)"))


## `name_text` and `price_text` are two separate labels, not one concatenated
## string -- a single label with hand-placed spaces between name and price
## (the old shape) only lines up for names of one particular length, which is
## why the buy column's prices used to sit ragged, immediately after each
## name rather than in a shared column. `price_text` gets a fixed-width,
## right-aligned label instead, so every price in the column shares one edge
## regardless of name length.
##
## `enabled == false` (nothing in the purse for this item's price) dims BOTH
## the icon and a dedicated "disabled" stylebox, not just the text color --
## text alone read as "every row looks the same" at handheld scale (OF31
## sweep, frame 20: "a column of identical white circles"), because the icon
## itself carried no affordability signal at all.
func _row(db: RefCounted, item_id: String, name_text: String, price_text: String, enabled: bool) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(310, 52)
	button.focus_mode = Control.FOCUS_ALL
	button.text = ""
	button.disabled = not enabled
	button.add_theme_stylebox_override("normal", UITokens.slot_box(false))
	button.add_theme_stylebox_override("hover", UITokens.slot_box(false))
	button.add_theme_stylebox_override("pressed", UITokens.slot_box(true))
	button.add_theme_stylebox_override("focus", UITokens.slot_box(true))
	button.add_theme_stylebox_override("disabled", _disabled_row_box())
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var pad := MarginContainer.new()
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_theme_constant_override("margin_left", 10)
	pad.add_theme_constant_override("margin_right", 10)
	button.add_child(pad)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	pad.add_child(row)

	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(ROW_ICON_PX, ROW_ICON_PX)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _icon_texture(db, item_id)
	icon.modulate = Color(1, 1, 1, 1) if enabled else Color(1, 1, 1, 0.35)
	row.add_child(icon)

	var name_label := Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.text = name_text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# VIS-UI-r5: `clip_text` alone clips at the label edge with no affordance --
	# every TM name got beheaded once the price column took its own fixed
	# width. `text_overrun_behavior` adds the ellipsis; `clip_text` still
	# needed alongside it or the label keeps requesting its full unclipped
	# width from the row.
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", UITokens.FONT_BODY)
	name_label.add_theme_color_override(
		"font_color", UITokens.TEXT_PRIMARY if enabled else UITokens.TEXT_MUTED
	)
	row.add_child(name_label)

	var price_label := Label.new()
	price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_label.text = price_text
	price_label.custom_minimum_size = Vector2(PRICE_COLUMN_PX, 0)
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	price_label.add_theme_font_size_override("font_size", UITokens.FONT_BODY)
	price_label.add_theme_color_override(
		"font_color", UITokens.TEXT_PRIMARY if enabled else UITokens.TEXT_MUTED
	)
	row.add_child(price_label)

	button.focus_entered.connect(func() -> void:
		if _columns_scroll != null:
			_columns_scroll.ensure_control_visible(button)
	)
	return button


## A visibly flatter, more transparent version of the ordinary row box --
## `disabled = true` alone (default engine disabled style, since nothing here
## overrode it before) did not read as "you can't afford this" next to the
## row's own focus/normal styleboxes, which is what let a Coin: 0 catalogue
## draw seventeen rows that all looked alike.
func _disabled_row_box() -> StyleBoxFlat:
	var box := UITokens.slot_box(false).duplicate() as StyleBoxFlat
	box.bg_color = Color(box.bg_color, box.bg_color.a * 0.4)
	return box


func _empty_label(text: String) -> Label:
	var empty := Label.new()
	empty.text = "  %s" % text
	empty.add_theme_font_size_override("font_size", UITokens.FONT_BODY)
	empty.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	return empty


## --- the transactions ----------------------------------------------------------
##
## Both go through `trade_db.gd`. This panel never adds or removes an item
## itself, so there is exactly one place the coin arithmetic lives and
## tests/test_trade.gd tests the same code the button presses.

func buy_one(item_id: String) -> String:
	var reason := str(_trade.call("buy", _inventory(), _vendor_id, item_id, 1))
	_say(reason, item_id, "Bought %s.")
	_refresh()
	return reason


func sell_one(item_id: String) -> String:
	var reason := str(_trade.call("sell", _inventory(), _vendor_id, item_id, 1))
	_say(reason, item_id, "Sold %s.")
	_refresh()
	return reason


func _on_buy(item_id: String) -> void:
	buy_one(item_id)


func _on_sell(item_id: String) -> void:
	sell_one(item_id)


func _say(reason: String, item_id: String, success_format: String) -> void:
	if _message == null:
		return
	var db := _items()
	var item_name := str(db.call("item_name", item_id)) if db != null else item_id
	if reason == TRADE_DB.OK:
		_message.add_theme_color_override("font_color", UITokens.SUCCESS)
		_message.text = success_format % item_name
	else:
		_message.add_theme_color_override("font_color", UITokens.WARNING)
		_message.text = TRADE_DB.refusal_text(reason, item_name)


func _icon_texture(db: RefCounted, id: String) -> Texture2D:
	if db == null or id.is_empty():
		return null
	var path := str(db.call("definition", id).get("icon", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
