extends CanvasLayer

## Stage B Wave 3 lane 3.E. The receiver's half of a trade, on screen.
##
## One line of text and two buttons, in the corner, shown when
## `trade_offer.gd` emits `offer_received` and hidden the moment the offer
## resolves for any reason -- accepted, declined, withdrawn, or the other
## player disconnecting.
##
## ## Why it does NOT pause the world
##
## Every other modal in this game (`storage_panel.gd`, `craft_panel.gd`) pauses
## the tree, releases the mouse and joins `input_owner.gd`'s group, because the
## player walked up to a thing and opened it. An offer is the opposite: it
## arrives unasked, while the receiver is doing something else, possibly in a
## fight. Freezing somebody's game because a friend pressed Give would be a
## griefing tool, so this is a HUD prompt that sits there and waits. The player
## can ignore it entirely and it costs them nothing -- no items are held in
## escrow on either side while it is up (`trade_offer.gd`'s header).
##
## It is created lazily by `trade_offer.gd` on the first offer this peer
## receives, the same one-instance-built-lazily pattern
## `storage_container.gd::_panel` uses, so a process nobody ever offers
## anything to never builds it.

const UITokens := preload("res://scripts/ui/ui_tokens.gd")

const NODE_NAME := "TradeOfferPanel"

var _transport: Node = null
var _root: Control = null
var _headline: Label = null
var _accept: Button = null
var _decline: Button = null
var _txn_id: String = ""


## Find or mount the panel under the tree root, wired to `transport`.
static func attach(transport: Node) -> Node:
	if transport == null or not transport.is_inside_tree():
		return null
	var root := transport.get_tree().root
	var existing := root.get_node_or_null(NodePath(NODE_NAME))
	if existing != null:
		return existing
	var node: Node = (load("res://scripts/ui/trade_offer_panel.gd") as GDScript).new()
	node.name = NODE_NAME
	node.set("_transport", transport)
	root.add_child(node)
	return node


func _ready() -> void:
	name = NODE_NAME
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false
	if _transport != null:
		if not _transport.is_connected("offer_received", _on_offer_received):
			_transport.connect("offer_received", _on_offer_received)
		if not _transport.is_connected("offer_resolved", _on_offer_resolved):
			_transport.connect("offer_resolved", _on_offer_resolved)
		# An offer that arrived before this panel existed -- which is every
		# first offer, because the transport builds the panel from inside its
		# own signal handler.
		var waiting: Dictionary = _transport.call("incoming")
		if not waiting.is_empty():
			_show(waiting)


func is_open() -> bool:
	return visible


# --- the offer conversation ----------------------------------------------------

func _on_offer_received(offer: Dictionary) -> void:
	_show(offer)


func _on_offer_resolved(txn_id: String, _ok: bool, _reason: String) -> void:
	if txn_id == _txn_id:
		_hide()


func _show(offer: Dictionary) -> void:
	_txn_id = str(offer.get("txn_id", ""))
	_headline.text = "%s offers you %s." % [_who(int(offer.get("from", 0))),
		_what(str(offer.get("item", "")), int(offer.get("count", 0)))]
	visible = true
	_accept.grab_focus()


func _hide() -> void:
	_txn_id = ""
	visible = false


func _on_accept() -> void:
	if _transport == null or _txn_id.is_empty():
		return
	var answer: Dictionary = _transport.call("accept")
	# A refusal here is this peer's own satchel saying no. `trade_offer.gd` has
	# already told the giver; the receiver is told too, because "nothing
	# happened" is the one outcome a player will read as a bug.
	var reason := str(answer.get("reason", ""))
	if not bool(answer.get("ok", false)) and not reason.is_empty():
		var game := get_node_or_null(^"/root/Game")
		if game != null:
			game.call("push_world_message", reason)
	_hide()


func _on_decline() -> void:
	if _transport == null or _txn_id.is_empty():
		return
	_transport.call("decline")
	_hide()


# --- presentation ---------------------------------------------------------------

func _who(peer_id: int) -> String:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return "Someone"
	var session: Variant = game.get("session")
	if session == null:
		return "Someone"
	for raw: Variant in ((session as Node).call("peers") as Array):
		var row := raw as Dictionary
		if int(row.get("peer_id", 0)) != peer_id:
			continue
		var shown := str(row.get("display_name", "")).strip_edges()
		return shown if not shown.is_empty() else "Someone"
	return "Someone"


func _what(item: String, count: int) -> String:
	var shown := item
	var game := get_node_or_null(^"/root/Game")
	if game != null:
		var db: RefCounted = game.get("items") as RefCounted
		if db != null:
			shown = str(db.call("item_name", item))
	return shown if count <= 1 else "%d %s" % [count, shown]


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var frame := PanelContainer.new()
	frame.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	frame.position = Vector2(-40.0, 0.0)
	frame.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	frame.grow_vertical = Control.GROW_DIRECTION_BOTH
	var box := StyleBoxFlat.new()
	box.bg_color = UITokens.BG_PANEL
	box.border_color = UITokens.BORDER
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	box.set_content_margin_all(16)
	frame.add_theme_stylebox_override("panel", box)
	_root.add_child(frame)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	frame.add_child(column)

	_headline = Label.new()
	_headline.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	_headline.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	_headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_headline.custom_minimum_size = Vector2(380.0, 0.0)
	column.add_child(_headline)

	_accept = _button("Accept", UITokens.SUCCESS)
	_accept.pressed.connect(_on_accept)
	column.add_child(_accept)

	_decline = _button("No thanks", UITokens.TEXT_SECONDARY)
	_decline.pressed.connect(_on_decline)
	column.add_child(_decline)


func _button(text: String, tint: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(380.0, 52.0)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", UITokens.FONT_BUTTON)
	button.add_theme_color_override("font_color", tint)
	return button
