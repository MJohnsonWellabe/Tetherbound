extends Control

## One toast queue for everything the game wants to say in passing.
##
## THE PROBLEM THIS FILE EXISTS FOR. The owner's playtest verdict was that the
## systems work invisibly: XP lands as a number that silently moves, an autosave
## is a disk write nobody sees, and every refusal token this project carefully
## routes through signals — `party.gd` invented the idiom — died unheard in
## those signals. Each system could grow its own popup, and three popups drawn
## by three owners is how a screen ends up covered.
##
## So: ONE queue, many callers. The HUD connects the signals
## (`playground_hud.gd`); this decides what is on screen. Two rules do all the
## work:
##
##   QUEUE, DON'T STACK. At most MAX_VISIBLE toasts are drawn; later arrivals
##   wait in FIFO order and are promoted as slots free up. A burst of ten events
##   is ten moments in sequence, not a wall.
##
##   COALESCE, DON'T REPEAT. A toast carries a coalesce KEY (pickups key by
##   item, XP by pal, refusals by token, saves by the one "save" key). A new
##   toast whose key matches a live one — visible OR still queued — merges into
##   it: amounts sum, the text is rebuilt, the timer resets. Three swings of the
##   axe read "+9 Wood", not three "+3 Wood"s. A LEVEL-UP HAS NO KEY on
##   purpose: `encounter_director` emits one signal per level because "each one
##   is its own moment", and coalescing them here would undo that decision.
##
## Colours and text treatments all come from `ui_style.gd`; nothing here picks
## a colour of its own. Drawing only happens inside the tree — `tick()` is the
## logic seam, callable headless with no scene at all, which is what
## `tests/test_toasts.gd` drives.

const STYLE := preload("res://scripts/ui/ui_style.gd")
const DEFS := preload("res://scripts/items/item_defs.gd")

## TUNABLE. Three, because the frame that motivated the cap had a pickup, an XP
## award and a save land together and anything taller starts covering the
## minimap's column of the screen.
const MAX_VISIBLE := 3
## TUNABLE. The waiting room. Beyond this the OLDEST waiting toast that is not
## a level-up is dropped — old news loses to new news, but a level-up is never
## thrown away to make room for a pickup.
const MAX_PENDING := 6

const KIND_INFO := "info"
const KIND_PICKUP := "pickup"
const KIND_XP := "xp"
const KIND_LEVELUP := "levelup"
const KIND_SAVE := "save"
const KIND_REFUSAL := "refusal"

## TUNABLE. Seconds on screen per kind. The save tick is deliberately the
## shortest and the level-up the longest: one is bookkeeping, the other is the
## reason the session existed.
const LIFETIMES := {
	KIND_INFO: 3.5,
	KIND_PICKUP: 3.0,
	KIND_XP: 3.5,
	KIND_LEVELUP: 5.0,
	KIND_SAVE: 2.0,
	KIND_REFUSAL: 3.0,
}

## Entrance slide and exit fade, in seconds. Computed from a toast's age in
## `_layout()` rather than tweened, so the whole thing stays drivable from
## `tick()` with no tree.
const ENTER_TIME := 0.18
const EXIT_TIME := 0.35

## Refusal tokens -> sentences. THIS IS THE OTHER END OF `party.gd`'s IDIOM:
## the world emits tokens because "the world has no business knowing how a
## refusal is worded", which means somebody has to own the wording, and until
## now nobody did — the tokens died in their signals. Unknown tokens fall back
## to the token humanized, so a new refusal is never invisible, just unpolished.
const REFUSAL_TEXT := {
	"nothing_there": "Nothing to gather there",
	"spent": "Stripped bare — it will regrow",
	"needs_tool": "That needs the right tool",
	"wrong_tool": "Wrong tool for that",
	"no_scatter": "Nothing here can be gathered",
	"no_harvestables": "Nothing here can be gathered",
	"no_inventory": "No bag to put that in",
	"tool_broken": "That tool is broken",
	"bag_full": "Bag is full",
	"inventory_full": "Bag is full",
	"party_full": "Party is full",
}

## Visible toasts, oldest first, and the queue behind them. Each is a
## Dictionary: kind, key, text, age, life, plus the fields its text is rebuilt
## from (item/count, name/amount, level) and `label` (a Label, or null when
## running with no tree).
var _active: Array[Dictionary] = []
var _pending: Array[Dictionary] = []


func _process(delta: float) -> void:
	tick(delta)


## --- what callers say -------------------------------------------------------


## "+3 Wood". Coalesces per item id.
func pickup(item_id: String, count: int) -> void:
	if count <= 0:
		return
	_push({
		"kind": KIND_PICKUP, "key": "pickup:%s" % item_id,
		"item": item_id, "count": count,
	})


## "Bramblit +44 XP". Coalesces per pal name; amounts sum.
func xp(pal_name: String, amount: int) -> void:
	if amount <= 0:
		return
	_push({
		"kind": KIND_XP, "key": "xp:%s" % pal_name,
		"name": pal_name, "amount": amount,
	})


## "Bramblit reached Lv 5!" — with the flourish, and NEVER coalesced.
func level_up(pal_name: String, level: int) -> void:
	_push({"kind": KIND_LEVELUP, "key": "", "name": pal_name, "level": level})


## The autosave tick. Subtle by design: no plate, dim ink, gone in two seconds.
## One key, so back-to-back writes read as one save.
func saved(_reason: String = "") -> void:
	_push({"kind": KIND_SAVE, "key": "save"})


## A refusal token, worded. Coalesces per token, so hammering the swing button
## at the wrong tree refreshes one toast rather than papering the corner.
func refusal(token: String) -> void:
	if token.is_empty():
		return
	_push({"kind": KIND_REFUSAL, "key": "refusal:%s" % token, "text": refusal_text(token)})


## Anything else. `key` optional; empty never coalesces.
func info(text: String, key: String = "") -> void:
	_push({"kind": KIND_INFO, "key": key, "text": text})


static func refusal_text(token: String) -> String:
	return str(REFUSAL_TEXT.get(token, token.replace("_", " ").capitalize()))


## --- the queue --------------------------------------------------------------


func _push(toast: Dictionary) -> void:
	toast["age"] = 0.0
	toast["life"] = float(LIFETIMES.get(str(toast["kind"]), 3.5))
	toast["label"] = null
	toast["text"] = _text_of(toast)

	var key := str(toast.get("key", ""))
	if not key.is_empty():
		var live := _find(key)
		if not live.is_empty():
			# THE COALESCING RULE: same key, still live -> merge and refresh.
			live["count"] = int(live.get("count", 0)) + int(toast.get("count", 0))
			live["amount"] = int(live.get("amount", 0)) + int(toast.get("amount", 0))
			live["age"] = 0.0
			live["text"] = _text_of(live)
			_dress(live)
			return

	if _active.size() < MAX_VISIBLE:
		_activate(toast)
		return
	_pending.append(toast)
	while _pending.size() > MAX_PENDING:
		var drop := _oldest_droppable()
		if drop < 0:
			break
		_pending.remove_at(drop)


## The oldest queued toast that is not a level-up; a level-up only if there is
## nothing else to drop.
func _oldest_droppable() -> int:
	for i in _pending.size():
		if str(_pending[i]["kind"]) != KIND_LEVELUP:
			return i
	return 0 if not _pending.is_empty() else -1


## A live toast with this key — visible or queued — or {}.
func _find(key: String) -> Dictionary:
	for toast in _active:
		if str(toast.get("key", "")) == key:
			return toast
	for toast in _pending:
		if str(toast.get("key", "")) == key:
			return toast
	return {}


func _text_of(toast: Dictionary) -> String:
	match str(toast["kind"]):
		KIND_PICKUP:
			return "+%d %s" % [int(toast.get("count", 0)), DEFS.display_name(str(toast.get("item", "")))]
		KIND_XP:
			return "%s +%d XP" % [str(toast.get("name", "")), int(toast.get("amount", 0))]
		KIND_LEVELUP:
			return "%s reached Lv %d!" % [str(toast.get("name", "")), int(toast.get("level", 0))]
		KIND_SAVE:
			return "Saved"
	return str(toast.get("text", ""))


func _activate(toast: Dictionary) -> void:
	toast["age"] = 0.0
	_active.append(toast)
	if is_inside_tree():
		_dress(toast)


## Advance every toast, expire the old, promote the waiting.
##
## Split from `_process` so a test can run the whole lifecycle in one call with
## no tree, no clock and no renderer — the same seam `harvestable.tick()` and
## `save_director.tick()` keep for the same reason.
func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	var still: Array[Dictionary] = []
	for toast in _active:
		toast["age"] = float(toast["age"]) + delta
		if float(toast["age"]) >= float(toast["life"]):
			var label: Label = toast.get("label")
			if label != null and is_instance_valid(label):
				label.queue_free()
			continue
		still.append(toast)
	_active = still
	while _active.size() < MAX_VISIBLE and not _pending.is_empty():
		_activate(_pending.pop_front())
	if is_inside_tree():
		_layout()


## --- what a test reads ------------------------------------------------------


func active_count() -> int:
	return _active.size()


func pending_count() -> int:
	return _pending.size()


func active_texts() -> Array[String]:
	var out: Array[String] = []
	for toast in _active:
		out.append(str(toast["text"]))
	return out


func active_kinds() -> Array[String]:
	var out: Array[String] = []
	for toast in _active:
		out.append(str(toast["kind"]))
	return out


## --- drawing ----------------------------------------------------------------
##
## Everything below runs only inside the tree. Position and alpha are computed
## from each toast's age every frame rather than tweened, so the animation
## cannot outlive or contradict the queue that owns it.


func _dress(toast: Dictionary) -> void:
	if not is_inside_tree():
		return
	var label: Label = toast.get("label")
	if label == null or not is_instance_valid(label):
		label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		add_child(label)
		toast["label"] = label
	label.text = str(toast["text"])

	var kind := str(toast["kind"])
	match kind:
		KIND_LEVELUP:
			label.add_theme_font_size_override("font_size", 30)
			label.add_theme_color_override("font_color", Color("#" + STYLE.GOOD))
			label.add_theme_stylebox_override("normal",
				_plate(STYLE.ROW_FOCUS_BG, STYLE.ROW_FOCUS_EDGE))
		KIND_SAVE:
			label.add_theme_font_size_override("font_size", 18)
			label.add_theme_color_override("font_color", Color("#" + STYLE.INK_DIM))
		KIND_REFUSAL:
			label.add_theme_font_size_override("font_size", 22)
			label.add_theme_color_override("font_color", Color("#" + STYLE.WARN))
			label.add_theme_stylebox_override("normal",
				_plate(STYLE.ROW_BG, STYLE.ROW_EMPTY_EDGE))
		_:
			label.add_theme_font_size_override("font_size", 22)
			label.add_theme_color_override("font_color", Color("#" + STYLE.INK))
			label.add_theme_stylebox_override("normal",
				_plate(STYLE.ROW_BG, STYLE.ROW_EMPTY_EDGE))
	STYLE.make_legible(label)
	label.reset_size()


## `ui_style.panel_style` with room for the text to breathe. The geometry stays
## the style file's; only the content margins are this file's business.
static func _plate(fill: Color, edge: Color) -> StyleBoxFlat:
	var box := STYLE.panel_style(fill, edge)
	box.content_margin_left = 12.0
	box.content_margin_right = 12.0
	box.content_margin_top = 4.0
	box.content_margin_bottom = 4.0
	return box


func _layout() -> void:
	var y := 0.0
	for toast in _active:
		var label: Label = toast.get("label")
		if label == null or not is_instance_valid(label):
			_dress(toast)
			label = toast.get("label")
			if label == null:
				continue
		var age := float(toast["age"])
		var life := float(toast["life"])

		# Entrance: slide in from the right and fade up. Exit: fade out in place.
		var entering := clampf(age / ENTER_TIME, 0.0, 1.0)
		var slide := (1.0 - ease(entering, 0.4)) * 46.0
		var alpha := entering
		var left := life - age
		if left < EXIT_TIME:
			alpha = clampf(left / EXIT_TIME, 0.0, 1.0)

		# The level-up flourish: a scale overshoot in the first third of a
		# second, pivoted on the label's own centre.
		var scale := 1.0
		if str(toast["kind"]) == KIND_LEVELUP and age < 0.4:
			scale = 1.0 + 0.30 * (1.0 - age / 0.4) * sin((age / 0.4) * PI)
		label.pivot_offset = label.size * 0.5
		label.scale = Vector2.ONE * scale

		label.position = Vector2(size.x - label.size.x - 8.0 + slide, y)
		label.modulate = Color(1.0, 1.0, 1.0, alpha)
		y += label.size.y * scale + 8.0
