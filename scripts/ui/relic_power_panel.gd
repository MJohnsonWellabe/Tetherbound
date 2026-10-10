extends CanvasLayer

## F31#2 / UX §shrine: the relic power screen. Opens at any Shrine Room
## pedestal outside combat (and after a hang). One row per relic THIS
## character has hung, each with its power in one line; the active one is
## marked; pressing a row makes it the one active power (RD-20's one-active
## rule; the selection moved here from the old Realm Heart sockets). In a
## session the choice goes to the host (`Session.request_relic_power`) and
## applies locally only once accepted, so host-run fights see the same power.
## Built the same pause-and-release way as creature_bed_panel.gd.

const UITokens := preload("res://scripts/ui/ui_tokens.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const LOCAL_PAUSE := preload("res://scripts/ui/local_pause.gd")
const INPUT_GLYPH := preload("res://scripts/ui/input_glyph.gd")
const HEARTS := preload("res://autoload/realm_heart_state.gd")
const ORDER := preload("res://scripts/data/biome_order.gd")

var game: Node = null
var _column: VBoxContainer = null
var _message: Label = null
var _rows: Array[Button] = []
var _open := false
var _closing_cancel := false
var _pending_heart := ""
var _pending_character := ""
var _pending_session: Node


func _ready() -> void:
	game = get_node_or_null(^"/root/Game")
	_build_shell()
	visible = false
	add_to_group(INPUT_OWNER.GROUP)


func is_open() -> bool:
	return _open


func owns_input() -> bool:
	return _open or _closing_cancel


## The hearts this character may choose: those whose relic it has hung.
static func choices(hearts: RefCounted, relics_hung: Array) -> Array[String]:
	var out: Array[String] = []
	for id: String in hearts.call("ordered_realm_ids"):
		if not (hearts.call("heart", id) as Dictionary).is_empty() and HEARTS.hung_allows(id, relics_hung):
			out.append(id)
	return out


func open(message: String = "") -> void:
	if not _open and INPUT_OWNER.current(get_tree()) != null: return
	_closing_cancel = false
	if not _open:
		_open = true
		visible = true
		LOCAL_PAUSE.hold(get_tree())
		INPUT_OWNER.set_world_hud_visible(get_tree(), false)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		process_mode = Node.PROCESS_MODE_ALWAYS
	_message.text = message
	_refresh()


func close() -> void:
	if not _open:
		return
	_clear_pending_choice()
	_open = false
	visible = false
	var release_world := INPUT_OWNER.current(get_tree()) == null
	_closing_cancel = Input.is_action_pressed("menu_cancel")
	if release_world:
		INPUT_OWNER.set_world_hud_visible(get_tree(), true)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		LOCAL_PAUSE.release(get_tree())


func _process(_delta: float) -> void:
	if _closing_cancel and not Input.is_action_pressed("menu_cancel"):
		_closing_cancel = false
	if _open and Input.is_action_just_pressed("menu_cancel"):
		INPUT_OWNER.suppress_pause_reopen(get_tree())
		close()


func _hung() -> Array:
	var local: RefCounted = game.get("local") if game != null else null
	var personal: Variant = local.get("redesign_character") if local != null else null
	return (personal as Dictionary).get("relics_hung", []) if personal is Dictionary else []


func _refresh() -> void:
	var focused := _rows.find(get_viewport().gui_get_focus_owner()) if get_viewport() != null else -1
	for child in _column.get_children():
		child.queue_free()
	_rows.clear()
	var hearts: RefCounted = game.get("realm_hearts") if game != null else null
	if hearts == null:
		return
	var active := str(hearts.call("active_id"))
	for id: String in choices(hearts, _hung()):
		var heart: Dictionary = hearts.call("heart", id)
		var power: Dictionary = heart.get("power", {})
		var button := Button.new()
		button.custom_minimum_size = Vector2(560, 56)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = "%s%s — %s: %s" % ["● " if id == active else "○ ", str(heart.get("display_name", id)),
			str(power.get("display_name", "")), str(power.get("description", ""))]
		button.add_theme_font_size_override("font_size", UITokens.FONT_BODY)
		button.pressed.connect(_choose.bind(id))
		_column.add_child(button)
		_rows.append(button)
	if _rows.is_empty():
		var none := Label.new()
		none.text = "No relic hangs here yet. Hang a relic to carry its power."
		none.add_theme_font_size_override("font_size", UITokens.FONT_BODY)
		none.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
		_column.add_child(none)
		return
	_rows[clampi(focused, 0, _rows.size() - 1)].call_deferred("grab_focus")


func _choose(id: String) -> void:
	if not _open or not _pending_heart.is_empty(): return
	var hearts: RefCounted = game.get("realm_hearts")
	var session: Node = game.get("session")
	if session != null and session.has_method("request_relic_power") and bool(session.call("is_active")):
		# Bind and listen before submitting: the solo/host saved decision can
		# arrive inside request_relic_power, and it is announced only once.
		_pending_heart = id
		_pending_character = _character_id()
		_pending_session = session
		if not session.is_connected("homestead_action_completed", _on_reply):
			session.connect("homestead_action_completed", _on_reply)
		var verdict: Dictionary = session.call("request_relic_power", id)
		if _pending_heart != id: return # Inline completion already presented it.
		if not reply_final(verdict):
			_message.text = "Asking the host…"
			return
		_clear_pending_choice()
		if verdict.get("ok") != true and not chosen_already(verdict):
			_message.text = _refusal(verdict)
			return
	_apply(hearts, id)


func _on_reply(op: String, intent: Dictionary, result: Dictionary) -> void:
	if op != "relic_power" or str(intent.get("heart_id", "")) != _pending_heart:
		return
	if not _open or _character_id() != _pending_character or game.get("session") != _pending_session:
		_clear_pending_choice()
		return
	if not reply_final(result):
		_message.text = "Asking the host to save your choice..."
		return # A guest's first reply is the host's checkpoint; the saved decision follows.
	var id := _pending_heart
	_clear_pending_choice()
	if result.get("ok") == true or chosen_already(result):
		_apply(game.get("realm_hearts"), id)
	else:
		_message.text = _refusal(result)


func _character_id() -> String:
	var local: RefCounted = game.get("local") if is_instance_valid(game) else null
	return str(local.get("character_id")) if local != null else ""


func _clear_pending_choice() -> void:
	if is_instance_valid(_pending_session) and _pending_session.is_connected("homestead_action_completed", _on_reply):
		_pending_session.disconnect("homestead_action_completed", _on_reply)
	_pending_heart = ""
	_pending_character = ""
	_pending_session = null


func _exit_tree() -> void:
	_clear_pending_choice()


func _apply(hearts: RefCounted, id: String) -> void:
	var session: Node = game.get("session")
	# Session installs the accepted owner record before announcing success.
	# A screen callback may display it, but may never select a power itself
	# while the authority owns this character (including solo/host sessions).
	var accepted := str(hearts.call("active_id")) == id if session != null and bool(session.call("is_active")) \
		else bool(hearts.call("activate_hung", id, _hung()))
	if accepted:
		var heart: Dictionary = hearts.call("heart", id)
		_message.text = "%s is your active power." % str((heart.get("power", {}) as Dictionary).get("display_name", id))
	else:
		_message.text = "That relic is not hung yet."
	_refresh()


## Replies that only say the host is still deciding: the saved decision (a
## guest's after its owner-passive checkpoint) follows. Any other reply ends
## the request.
const IN_PROGRESS := ["awaiting_saved_decision", "owner_passive_checkpoint_pending", "owner_passive_original_pending"]

static func reply_final(result: Dictionary) -> bool:
	return not result.is_empty() and (result.get("ok") == true or str(result.get("code", "")) not in IN_PROGRESS)


## The host saved nothing new because this power is already the active one
## (or this exact choice was already saved): a no-op, not an error.
static func chosen_already(result: Dictionary) -> bool:
	# A replay of the saved original is the same decision, already applied.
	return str(result.get("code", "")) in ["relic_power_unchanged", "reconcile_original_decision"]


static func _refusal(verdict: Dictionary) -> String:
	match str(verdict.get("code", "")):
		"relic_not_hung": return "That relic is not hung yet."
		"actual_shrine_pedestal_required", "source_or_revision_changed": return "Stand at a shrine pedestal and try again."
	return str(verdict.get("reason", verdict.get("code", "The choice was not saved.")))


func _build_shell() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var box := UITokens.panel_box(UITokens.BG_PANEL, UITokens.BORDER)
	box.content_margin_left = 24
	box.content_margin_top = 20
	box.content_margin_right = 24
	box.content_margin_bottom = 20
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", box)
	panel.custom_minimum_size = Vector2(620, 0)
	center.add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)
	var title := Label.new()
	title.text = "Relic Power"
	title.add_theme_font_size_override("font_size", UITokens.FONT_HEADING)
	title.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	outer.add_child(title)
	var sub := Label.new()
	sub.text = "Carry one hung relic's power."
	sub.add_theme_font_size_override("font_size", UITokens.FONT_BODY)
	sub.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	outer.add_child(sub)
	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", 6)
	outer.add_child(_column)
	_message = Label.new()
	_message.add_theme_font_size_override("font_size", UITokens.FONT_BODY)
	_message.add_theme_color_override("font_color", UITokens.SUCCESS)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_message)
	var hint := RichTextLabel.new()
	hint.bbcode_enabled = true
	hint.fit_content = true
	hint.scroll_active = false
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.text = "%s  Leave" % INPUT_GLYPH.icon("cancel", 24)
	hint.add_theme_font_size_override("normal_font_size", UITokens.FONT_TINY)
	hint.add_theme_color_override("default_color", UITokens.TEXT_MUTED)
	outer.add_child(hint)
