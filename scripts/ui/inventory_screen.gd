extends "res://scripts/ui/screen.gd"

## The bag: twenty-four slots, what is worn, and what you have eaten.
##
## Reads `TrainerInventory` and draws it. Owns no state of its own except which
## cell the cursor is on — `party_screen.gd`'s discipline, and its reason: a menu
## that keeps its own copy of the inventory is a menu that can disagree with the
## inventory, and the first time that happens is the first time somebody picks
## something up with the screen open.
##
## THREE PANELS, because M9 asks for three things and hiding two of them behind a
## tab nobody presses is how "armor slots architecture" becomes a feature the
## owner never sees:
##
##   * the GRID — slot/stack inventory, §19
##   * WORN — §18's five equipment slots, empty, and saying so in words
##   * FED — the food buffs in effect, and the sentence that says not eating
##     costs nothing. That line is on the screen deliberately: a survival game
##     trains players to expect a hunger bar, and the only way to tell them there
##     is not one is to say so where they look for it.
##
## ONE VERB, and it changes with what the cursor is on. `screen_stack.gd` hands a
## screen exactly `navigate`, `confirm` and `cancel`, on purpose, so that no
## screen polls raw input behind the stack's back — which means A is the only
## button available and the footer has to say what it will do THIS time. Eat, or
## Repair, or a dimmed prompt explaining why neither.
##
## NO MOUSE. There is no drag, no click target and no hover; this is a
## controller-first game and the grid is walked with the stick. Split and merge
## exist in `inventory.gd` and are deliberately not surfaced — they need a
## held-stack cursor, which is a second interaction model, and nothing in the
## slice needs them yet.

const DEFS := preload("res://scripts/items/item_defs.gd")
const EQUIPMENT := preload("res://scripts/player/equipment.gd")

## Cells across. 24 slots (items.json `inventory.slots`) read as 6x4, which is
## what a controller can walk without the cursor travelling for a second and a
## half — items.json says exactly that beside the number.
const COLUMNS := 6

## How long a refusal stays on screen, matching `party_screen.NOTICE_SECONDS`.
const NOTICE_SECONDS := 2.5

@export var inventory_path: NodePath
@export var player_path: NodePath
## The recovery system and the party, for the one verb in this bag that acts on
## a CREATURE rather than on the trainer: using a revival draught. The owner
## fainted a pal, opened this screen holding three draughts, and found no way to
## spend one — `recovery.revive_with_item()` existed, was tested, and nothing a
## player could press ever called it. The rules stay in `recovery.gd`; this
## screen only picks who and says what happened.
##
## Defaults resolve from where `screen_stack.tscn` is instanced in the world
## scene. In a test scene they resolve to nothing and the verb refuses in words,
## which is the same honest degradation `_bag()` already has.
@export var recovery_path: NodePath = NodePath("../../Recovery")
@export var party_path: NodePath = NodePath("../../Party")

var _cells: Array[PanelContainer] = []
var _bars: Array[ProgressBar] = []
var _fills: Array[StyleBoxFlat] = []
var _template: PanelContainer = null
var _notice: String = ""
var _notice_left: float = 0.0

@onready var _grid: GridContainer = $Body/Left/Grid
@onready var _capacity: Label = $Body/Left/Capacity
@onready var _detail: PanelContainer = $Body/Right/Detail
@onready var _detail_name: Label = $Body/Right/Detail/Pad/Lines/What
@onready var _detail_body: RichTextLabel = $Body/Right/Detail/Pad/Lines/About
@onready var _worn: PanelContainer = $Body/Right/Worn
@onready var _worn_body: RichTextLabel = $Body/Right/Worn/Pad/Lines/Slots
@onready var _fed: PanelContainer = $Body/Right/Fed
@onready var _fed_body: RichTextLabel = $Body/Right/Fed/Pad/Lines/Buffs


func _ready() -> void:
	# Cells are built BEFORE the base class runs, exactly as the party screen
	# builds its rows: `screen.gd` walks the whole tree once to outline and shadow
	# every label, and a cell duplicated after that walk would be the one
	# unreadable thing on the screen.
	_build_cells()
	for panel: PanelContainer in [_detail, _worn, _fed]:
		panel.add_theme_stylebox_override("panel", STYLE.panel_style(STYLE.ROW_BG, STYLE.PANEL_EDGE))
	super()


func _build_cells() -> void:
	_template = _grid.get_node_or_null(^"CellTemplate") as PanelContainer
	if _template == null:
		push_error("inventory screen has no CellTemplate to duplicate")
		return
	_grid.remove_child(_template)
	_grid.columns = COLUMNS

	for i in _slot_count():
		var cell := _template.duplicate() as PanelContainer
		cell.name = "Cell%d" % i
		cell.visible = true
		var fill := STYLE.bar_style(STYLE.HEALTH_FULL)
		var bar := cell.get_node(^"Pad/Lines/Wear") as ProgressBar
		STYLE.dress_bar(bar, fill)
		_grid.add_child(cell)
		_cells.append(cell)
		_bars.append(bar)
		_fills.append(fill)


# ------------------------------------------------------------------- the data

## The inventory node, checked by method rather than by class — it is another
## file's node and this screen should keep working if it grows a base class.
func _bag() -> Node:
	var node := get_node_or_null(inventory_path)
	if node == null or not node.has_method("inventory"):
		return null
	return node


func _inventory() -> RefCounted:
	var bag := _bag()
	return bag.call("inventory") as RefCounted if bag != null else null


func _equipment() -> RefCounted:
	var bag := _bag()
	if bag == null or not bag.has_method("equipment"):
		return null
	return bag.call("equipment") as RefCounted


func _vitals() -> RefCounted:
	var player := get_node_or_null(player_path)
	if player == null:
		return null
	var vitals: Variant = player.get("vitals")
	return vitals if vitals is RefCounted else null


## The recovery node, checked by the two methods this screen actually calls —
## `_bag()`'s discipline: another file's node, verified by surface not by class.
func _recovery() -> Node:
	var node := get_node_or_null(recovery_path)
	if node == null or not node.has_method("revive_with_item") \
			or not node.has_method("revival_item"):
		return null
	return node


func _party() -> Node:
	var node := get_node_or_null(party_path)
	if node == null or not node.has_method("members"):
		return null
	return node


## Is this stack the revival item? Asked of recovery — the id is that system's
## config, not this screen's — with the shipped id as the fallback so the verb
## still reads right in a scene with no recovery wired.
func _is_revival_item(item_id: String) -> bool:
	var recovery := _recovery()
	if recovery != null:
		return item_id == str(recovery.call("revival_item"))
	return item_id == "revival_draught"


## The first fainted pal in party order — "first" so the choice is predictable:
## the same order the party screen lists them in.
func _first_fainted() -> RefCounted:
	var party := _party()
	if party == null:
		return null
	var members: Variant = party.call("members")
	if not members is Array:
		return null
	for entry: Variant in (members as Array):
		var pal := entry as RefCounted
		if pal != null and bool(pal.get("fainted")):
			return pal
	return null


## How many cells to draw. Asked of the inventory when there is one, and of the
## item table when there is not, so a screen loaded into a test scene before the
## bag exists still draws an honest empty grid rather than nothing at all.
func _slot_count() -> int:
	var inventory := _inventory()
	return int(inventory.slot_count()) if inventory != null else DEFS.slot_count()


func _stack_at(index: int) -> RefCounted:
	var inventory := _inventory()
	return inventory.at(index) if inventory != null else null


# --------------------------------------------------------------------- drawing

func screen_title() -> String:
	var inventory := _inventory()
	if inventory == null:
		return "Inventory"
	return "Inventory    %d / %d slots used" % [inventory.used_slots(), inventory.slot_count()]


## The footer. A is the only button a screen gets, so its label is whatever the
## cursor is on right now — and it is DIMMED rather than blanked when there is
## nothing to do, for `ui_style.verb()`'s reason: a prompt that disappears reads
## as a missing glyph, and one that greys out reads as an answer.
func hints() -> Array[Array]:
	var verb := _verb_for(focus_index())
	var rows: Array[Array] = []
	rows.append(["Stick", "Move", true])
	rows.append(["A", verb["label"], bool(verb["ready"])])
	rows.append(["B", "Back", true])
	return rows


func focus_count() -> int:
	return _cells.size()


func refresh() -> void:
	_notice_left = maxf(0.0, _notice_left - get_process_delta_time())
	if _notice_left <= 0.0:
		_notice = ""

	for i in _cells.size():
		_draw_cell(i)
	_draw_capacity()
	_draw_detail(focus_index())
	_draw_worn()
	_draw_fed()


func _draw_capacity() -> void:
	var inventory := _inventory()
	if inventory == null:
		_capacity.text = "no bag wired to this screen"
		return
	# THE ONE NUMBER THIS SCREEN MAY SHOW ABOUT CAPACITY IS SLOTS. There is no
	# weight, no load and no encumbrance anywhere in the game (CLAUDE.md, §19,
	# D17), so there is nothing else here to draw.
	# Not the slot count again — the title already carries that. This is the line
	# that says what the ONLY limit is.
	_capacity.text = "slots are the only limit  ·  nothing you carry weighs anything"


func _draw_cell(index: int) -> void:
	var cell := _cells[index]
	var focused := index == focus_index()
	var name_label := cell.get_node(^"Pad/Lines/Name") as Label
	var count_label := cell.get_node(^"Pad/Lines/Foot/Count") as Label
	var kind_label := cell.get_node(^"Pad/Lines/Foot/Kind") as Label
	var wear := _bars[index]

	var stack := _stack_at(index)
	if stack == null:
		# An empty slot is DRAWN, not left blank: the party screen's empty rows
		# taught the same lesson — absence reads as a bug, a drawn empty box reads
		# as "there is room here".
		cell.add_theme_stylebox_override("panel", STYLE.panel_style(
			STYLE.ROW_FOCUS_BG if focused else STYLE.ROW_EMPTY_BG,
			STYLE.ROW_FOCUS_EDGE if focused else STYLE.ROW_EMPTY_EDGE
		))
		name_label.text = "—"
		name_label.modulate = Color(0.62, 0.64, 0.60)
		count_label.text = ""
		kind_label.text = ""
		wear.visible = false
		return

	cell.add_theme_stylebox_override("panel", STYLE.panel_style(
		STYLE.ROW_FOCUS_BG if focused else STYLE.ROW_BG,
		STYLE.ROW_FOCUS_EDGE if focused else STYLE.PANEL_EDGE
	))
	var item_id := str(stack.item_id)
	name_label.text = DEFS.display_name(item_id)
	# A broken tool is named in the same red its empty wear bar would be, because
	# an empty bar and a full-looking name is a cell nobody reads as "this does not
	# work any more".
	name_label.modulate = STYLE.HEALTH_LOW if bool(stack.is_broken()) else Color.WHITE
	# A count is drawn only when there is more than one. "Axe x1" is noise on every
	# tool in the game.
	count_label.text = "x%d" % int(stack.count) if int(stack.count) > 1 else ""
	kind_label.text = _kind_word(item_id)

	wear.visible = bool(stack.is_durable())
	if wear.visible:
		var fraction: float = float(stack.durability_fraction())
		wear.value = fraction * 100.0
		_fills[index].bg_color = STYLE.HEALTH_LOW.lerp(STYLE.HEALTH_FULL, fraction)


## One word for what a thing is, on a cell where there is room for one word.
func _kind_word(item_id: String) -> String:
	if DEFS.is_food(item_id):
		return "food"
	match DEFS.category(item_id):
		DEFS.CATEGORY_TOOL:
			return "tool"
		DEFS.CATEGORY_ORB:
			return "orb"
		DEFS.CATEGORY_CONSUMABLE:
			return "use"
		_:
			return "material"


func _draw_detail(index: int) -> void:
	if _bag() == null:
		_detail_name.text = "No bag"
		_detail_body.text = (
			"[color=#%s]This screen is pointed at a trainer inventory through its "
			% STYLE.INK_DIM
			+ "[b]inventory_path[/b] and nothing is there. That is expected in a test "
			+ "scene; it is a wiring mistake in the world.[/color]"
		)
		return

	var stack := _stack_at(index)
	if stack == null:
		_detail_name.text = "Empty slot"
		_detail_body.text = "[color=#%s]%s[/color]" % [
			STYLE.INK_DIM,
			"Nothing here. Wood, stone, fiber and berries stack; tools take a slot "
			+ "each and keep their own wear.\n\nSlots are the only limit there is. "
			+ "Nothing you pick up weighs anything, and a full pack never slows you "
			+ "down."
		]
		_append_notice()
		return

	var item_id := str(stack.item_id)
	_detail_name.text = DEFS.display_name(item_id)
	var lines: Array[String] = []
	lines.append("[color=#%s]%s[/color]" % [STYLE.INK_DIM, _kind_line(item_id, stack)])

	if DEFS.is_consumable(item_id) and not DEFS.is_food(item_id):
		# The revival draught is the only one of these. Saying what it is NOT is the
		# useful half: a consumable the trainer cannot eat looks like a bug on a
		# screen whose one verb is Eat.
		lines.append("")
		lines.append("[color=#%s]%s[/color]" % [
			STYLE.INK_DIM,
			"Used up when something spends it. Not something the trainer eats — a "
			+ "draught is for a pal that has fainted."
		])
		# And the live half: WHO pressing A would revive, right now, in the same
		# words the press will use. A verb whose target is a surprise is a verb
		# nobody dares press with one draught left.
		if _is_revival_item(item_id):
			var fainted := _first_fainted()
			lines.append("")
			if fainted != null:
				lines.append("[color=#%s]%s is down — using this revives them.[/color]" % [
					STYLE.GOOD, _pal_name(fainted)
				])
			else:
				lines.append("[color=#%s]No one is fainted right now.[/color]" % STYLE.INK_DIM)

	if stack.is_durable():
		lines.append("")
		lines.append("Condition   [b]%d / %d[/b]" % [int(stack.durability), int(stack.max_durability())])
		if bool(stack.is_broken()):
			lines.append("[color=#%s]Broken. It still repairs — free — at home.[/color]" % STYLE.WARN)
		else:
			lines.append("[color=#%s]Repairs free at home. Nothing is spent and nothing is lost.[/color]"
				% STYLE.INK_DIM)

	if DEFS.is_food(item_id):
		lines.append("")
		lines.append_array(_food_lines(item_id))

	_detail_body.text = "\n".join(lines)
	_append_notice()


func _kind_line(item_id: String, stack: RefCounted) -> String:
	if stack.is_durable():
		return "Tool  ·  one per slot"
	return "%s  ·  %d of %d in this slot" % [
		_kind_phrase(item_id), int(stack.count), int(stack.stack_limit())
	]


## The longer word, for the panel that has room for one. `_kind_word` is what a
## 140-pixel cell can fit and is not always a noun — "use" is a fine corner label
## and a poor sentence opener.
func _kind_phrase(item_id: String) -> String:
	if DEFS.is_food(item_id):
		return "Food"
	match DEFS.category(item_id):
		DEFS.CATEGORY_TOOL:
			return "Tool"
		DEFS.CATEGORY_ORB:
			return "Orb"
		DEFS.CATEGORY_CONSUMABLE:
			return "Consumable"
		_:
			return "Material"


## What eating this would do, in words, from the item's own data.
##
## Written as a POSITIVE and never as a lack. There is no line here that says how
## hungry you are, because there is no hunger: GAME_DESIGN.md §18 is a buff system
## and CLAUDE.md forbids the other kind outright.
func _food_lines(item_id: String) -> Array[String]:
	var block := DEFS.food(item_id)
	var seconds := float(block.get("seconds", 0.0)) * _seconds_scale()
	var lines: Array[String] = []
	lines.append("[color=#%s]Eating it, for %s:[/color]" % [STYLE.GOOD, _clock(seconds)])
	for pair: Array in [
		["max_health", "maximum health"],
		["max_stamina", "maximum stamina"],
		["stamina_regen", "stamina a second"],
	]:
		var amount := float(block.get(str(pair[0]), 0.0))
		if amount > 0.0:
			lines.append("   +%s  %s" % [_round(amount), str(pair[1])])
	var left := _food_left(item_id)
	if left > 0.0:
		lines.append("[color=#%s]In effect for another %s. Eating again resets the clock.[/color]" % [
			STYLE.INK_DIM, _clock(left)
		])
	return lines


func _draw_worn() -> void:
	var equipment := _equipment()
	var lines: Array[String] = []
	for slot: String in EQUIPMENT.SLOTS:
		var stack: RefCounted = equipment.at(slot) if equipment != null else null
		if stack == null:
			lines.append("[color=#%s]%s   —   empty[/color]" % [
				STYLE.INK_DIM, EQUIPMENT.slot_name(slot)
			])
		else:
			lines.append("%s   —   %s" % [
				EQUIPMENT.slot_name(slot), DEFS.display_name(str(stack.item_id))
			])
	lines.append("")
	# The honest state of the milestone, said out loud rather than left as five
	# empty rows the player has to interpret. Kept to two lines: this panel shares
	# a column with the item detail, and every line here is a line that one loses.
	lines.append("[color=#%s]No armour exists yet; the slots persist.[/color]" % STYLE.INK_DIM)
	_worn_body.text = "\n".join(lines)


func _draw_fed() -> void:
	var vitals := _vitals()
	if vitals == null:
		_fed_body.text = "[color=#%s]no trainer wired to this screen[/color]" % STYLE.INK_DIM
		return

	var buffs: Array = vitals.food_buffs()
	if buffs.is_empty():
		# THE SENTENCE THAT SAYS THERE IS NO HUNGER. Every survival game the owner
		# has played has a meter here, and the only way to say "this one does not"
		# is to say it where they would look for one.
		_fed_body.text = "[color=#%s]%s[/color]" % [
			STYLE.INK_DIM,
			"You have not eaten. That costs you nothing — food is a bonus here, "
			+ "never a meter to keep topped up."
		]
		return

	# TWO LINES PER MEAL, name-and-clock then bonuses. One line was tried and the
	# clock wrapped onto a line of its own on the widest meal, which reads as a
	# stray number under somebody else's row.
	var lines: Array[String] = []
	for entry: Variant in buffs:
		var meal: Dictionary = entry
		var parts: Array[String] = []
		for pair: Array in [
			["max_health", "health"],
			["max_stamina", "stamina"],
			["stamina_regen", "regen"],
		]:
			var amount := float(meal.get(str(pair[0]), 0.0))
			if amount > 0.0:
				parts.append("+%s %s" % [_round(amount), str(pair[1])])
		lines.append("[color=#%s]%s[/color]   [color=#%s]%s left[/color]" % [
			STYLE.GOOD,
			DEFS.display_name(str(meal.get("item", ""))),
			STYLE.INK_DIM,
			_clock(float(meal.get("left", 0.0))),
		])
		lines.append("    %s" % "   ".join(parts))
	_fed_body.text = "\n".join(lines)


func _append_notice() -> void:
	if _notice == "":
		return
	_detail_body.text += "\n\n[color=#%s]%s[/color]" % [STYLE.WARN, _notice]


# --------------------------------------------------------------------- the verb

## What A does on this cell, and whether it can be pressed.
##
## Computed in one place and used by both the footer and `on_activate`, so the
## prompt cannot promise something the press does not do — which is the failure
## the combat HUD's dimmed verbs were introduced to fix.
func _verb_for(index: int) -> Dictionary:
	var stack := _stack_at(index)
	if stack == null:
		return {"action": "", "label": "Use", "ready": false}
	var item_id := str(stack.item_id)
	if DEFS.is_food(item_id):
		return {"action": "eat", "label": "Eat", "ready": true}
	if _is_revival_item(item_id):
		# Ready only when the press would actually work — dimmed otherwise, and
		# the press still answers in words either way, exactly like Repair away
		# from home.
		return {"action": "revive", "label": "Use", "ready": _first_fainted() != null}
	if stack.is_durable():
		return {"action": "repair", "label": "Repair", "ready": _can_repair()}
	if EQUIPMENT.is_wearable(item_id):
		return {"action": "equip", "label": "Wear", "ready": true}
	return {"action": "", "label": "Use", "ready": false}


func _can_repair() -> bool:
	var bag := _bag()
	if bag == null or not bag.has_method("can_repair_here"):
		return false
	return bool(bag.call("can_repair_here"))


## Spend a draught on the first fainted pal, through `recovery.revive_with_item`.
##
## Every rule stays in recovery.gd — who counts as down, what it costs, how much
## health they come back on. This function only chooses the target, forwards,
## and puts the outcome into words: the success says WHO so the player is not
## left checking the party screen, and every refusal is a sentence rather than
## silence, because "I pressed it and nothing happened" is indistinguishable
## from a bug.
func _use_revival_draught() -> void:
	var recovery := _recovery()
	if recovery == null:
		_say("nothing here can wake a pal — no recovery system is wired to this screen")
		return
	var fainted := _first_fainted()
	if fainted == null:
		_say("no one is fainted — the draught keeps for when a pal goes down")
		return
	if bool(recovery.call("revive_with_item", fainted)):
		var left := int(recovery.call("revival_items_left"))
		_say("%s came round — %d left" % [_pal_name(fainted), left])
		return
	_say(_recovery_refusal_words(str(recovery.call("last_refusal"))))


## The pal's own answer to "what are you called", falling back to something a
## sentence can hold rather than to an empty string.
func _pal_name(pal: RefCounted) -> String:
	if pal != null and pal.has_method("display"):
		return str(pal.call("display"))
	return "the pal"


## recovery.gd's refusal tokens, in player voice — the same translation duty
## `_refusal_words` below does for the bag's tokens.
func _recovery_refusal_words(token: String) -> String:
	match token:
		"not_down":
			return "no one is fainted — the draught keeps for when a pal goes down"
		"no_revival_item":
			return "no revival draughts left — a pal bed at home is the other way back"
		"not_a_pal":
			return "there is no pal that can drink it"
		_:
			return "the draught cannot be used right now"


func on_activate(index: int) -> void:
	var bag := _bag()
	if bag == null:
		_say("there is no bag to use")
		return
	var verb := _verb_for(index)
	match str(verb["action"]):
		"eat":
			if not bool(bag.call("eat", index)):
				_say(_refusal_words(str(bag.call("last_refusal"))))
		"revive":
			_use_revival_draught()
		"repair":
			if bool(bag.call("repair", index)):
				_say("repaired, free of charge")
			else:
				_say(_refusal_words(str(bag.call("last_refusal"))))
		"equip":
			# No garment in the game declares a slot, so this is unreachable today
			# and is written anyway: the day one does, wearing it is already here.
			var stack := _stack_at(index)
			var equipment := _equipment()
			if equipment == null or stack == null:
				_say("there is nothing to wear that with")
				return
			if not bool(equipment.equip(stack)):
				_say(_refusal_words(str(equipment.last_refusal())))
				return
			_inventory().remove_at(index, int(stack.count))
		_:
			var stack := _stack_at(index)
			if stack == null:
				_say("that slot is empty")
			else:
				_say("%s is not something you use from here" % DEFS.display_name(str(stack.item_id)))


## A refusal token, in player voice.
##
## The tokens are for code to switch on; these are the sentences. Putting a bare
## `no_repair_station` on screen is the mistake `combat_hud` had to undo twice.
## An unrecognised token falls back to a general line rather than being printed —
## a token nobody has translated yet is still a token.
func _refusal_words(token: String) -> String:
	match token:
		"no_repair_station":
			return "you can only repair at home — build a bed, then come back"
		"not_durable":
			return "that is not a tool; there is nothing to repair"
		"not_food":
			return "that is not something you can eat"
		"empty_slot":
			return "that slot is empty"
		"inventory_full":
			return "no room — every slot is taken"
		"not_wearable":
			return "there is no armour in the Meadows yet"
		"slot_occupied":
			return "you are already wearing something there"
		"no_trainer":
			return "this screen is not wired to the trainer"
		_:
			return "that cannot be done right now"


# --------------------------------------------------------------- getting about

## A GRID, so left and right move the cursor rather than nudging a value.
##
## `screen.gd.navigate()` steps a one-dimensional list vertically and hands
## horizontal to `on_nudge`, which is right for a list of five pals and wrong for
## twenty-four cells in six columns. `rename_screen.gd` overrides it for the same
## reason and keeps the base index in step at the end, so `confirm()` still works
## exactly as `screen.gd` documents it.
##
## Both axes WRAP. Walking off the right of a row lands on the left of the next
## one down, which is how a bag is read; walking off the bottom comes back to the
## top, because a cursor that stops dead reads as the stick having disconnected.
func navigate(dx: int, dy: int) -> void:
	var count := focus_count()
	if count <= 0:
		return
	var index := focus_index()
	if dx != 0:
		# Row-wise wrap: the whole grid is one sequence read left to right.
		index = posmod(index + dx, count)
	if dy != 0:
		index = posmod(index + dy * COLUMNS, count)
	set_focus_index(index)


func on_pushed() -> void:
	_notice = ""
	_notice_left = 0.0


func _say(message: String) -> void:
	_notice = message
	_notice_left = NOTICE_SECONDS


# ------------------------------------------------------------------- formatting

func _clock(seconds: float) -> String:
	var whole := int(maxf(0.0, seconds))
	return "%d:%02d" % [whole / 60, whole % 60]


func _round(amount: float) -> String:
	return "%d" % roundi(amount) if is_equal_approx(amount, roundf(amount)) else "%.1f" % amount


func _seconds_scale() -> float:
	var bag := _bag()
	if bag == null or not bag.has_method("food_seconds_scale"):
		return 1.0
	return float(bag.call("food_seconds_scale"))


func _food_left(item_id: String) -> float:
	var vitals := _vitals()
	return 0.0 if vitals == null else float(vitals.food_seconds_left(item_id))
