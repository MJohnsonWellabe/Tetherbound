extends Node

## The trainer's bag, in the world.
##
## `scripts/items/inventory.gd` has been complete and tested since M8 — slots,
## stacks, all-or-nothing adds, tool durability, free repair, save records — and
## nothing in the shipping scene ever made one. The same shape as the save system
## before `save_director.gd`: a finished system with no owner is a system the
## player never meets. This is the owner.
##
## It is a HOLDER, a save contributor and a forwarding surface, and it adds no
## rules of its own — `party_manager.gd` is the same three things around
## `party.gd`, for the same reason. Every rule about slots and stacks stays in
## `inventory.gd`, because a manager that re-implemented one would be a second
## place the rule is true, which is one more than a rule can survive.
##
## THERE IS NO WEIGHT HERE EITHER. `inventory.gd`'s header explains why at length
## and `tests/test_inventory.gd` has a tripwire on the refusal tokens. Nothing in
## this file counts, sums or refuses anything by mass, and the only thing that can
## refuse an add is running out of slots.
##
## IT CANNOT HOLD A PAL. It holds item ids from the item tables and nothing else.
## The five-pal cap lives in `party.gd`; this is not a way around it, and a
## `storage` station that one day shows a chest will be a view onto another
## inventory, never a box for creatures.
##
## THE INTERFACE OTHER SYSTEMS CALL, and which must not change name:
##     inventory() -> RefCounted     the inventory.gd instance itself
##     add(item_id, count) -> bool
##     remove(item_id, count) -> bool
##     count_of(item_id) -> int
##     last_refusal() -> String
## M8's gathering and its build costs are written against exactly those, and
## `scripts/pals/recovery.gd` spends revival draughts through the same node — its
## `inventory_path` points here, which is what its own header asked for: "point
## `inventory_path` at whatever ends up owning the trainer's bag (M9's survival
## loop is where it belongs) and this node stops making one."

const INVENTORY := preload("res://scripts/items/inventory.gd")
const EQUIPMENT := preload("res://scripts/player/equipment.gd")
const DEFS := preload("res://scripts/items/item_defs.gd")

const CONFIG_PATH := "res://data/config/survival.json"

## The key this system owns inside `SaveManager`'s one envelope (D14).
const SAVE_DOMAIN := "inventory"

## Why `eat()` or `repair()` said no, as stable tokens. Tokens and not sentences,
## for `party.gd`'s reason: this file has no business knowing how a refusal is
## worded, and the UI cannot shorten a sentence written here into a toast.
const REFUSED_EMPTY_SLOT := "empty_slot"
const REFUSED_NOT_FOOD := "not_food"
const REFUSED_NO_TRAINER := "no_trainer"
const REFUSED_BAD_FOOD_DATA := "bad_food_data"
const REFUSED_NOT_DURABLE := "not_durable"
const REFUSED_NOT_AT_HOME := "no_repair_station"

signal changed()
signal refused(token: String)
## Somebody ate something. `seconds` is how long the bonus lasts, so a HUD can
## announce it without recomputing anything.
signal ate(item_id: String, seconds: float)

## The trainer, for eating — the meal lands on their vitals, not here. Defaults to
## the sibling the shipping scene has; a test scene points it elsewhere or leaves
## it, and eating then refuses with a token rather than crashing.
@export var player_path: NodePath = NodePath("../Player")

## Home, for free repair. §19 repairs a tool "for free at appropriate station",
## and `is_at_home()` is what "at a station" means until a workbench exists —
## see `repair()`.
@export var home_path: NodePath = NodePath("../Home")

var _inventory: RefCounted = null
var _equipment: RefCounted = null
var _config: Dictionary = {}

## THIS file's refusal, when the last no came from a rule here rather than from
## the inventory. Cleared by every operation that can set it, so `last_refusal()`
## can never report the reason a berry was refused an hour ago.
var _refusal: String = ""

## Set once the starting kit has been handed over, so a load that arrives after
## `_ready()` does not get a second one, and so `load_data()` can say the kit is
## spent without it being re-granted next frame.
var _kit_given: bool = false


func _ready() -> void:
	_inventory = INVENTORY.new()
	_equipment = EQUIPMENT.new()
	_grant_starting_kit()
	_register()


## Same lazy re-registration as `party_manager`, `structures` and `recovery`,
## and for the same reason — D14: under `--script` the autoloads are attached only
## after the entry point's `_init()` returns, so `_ready()` here can run in a tree
## with no `/root/SaveManager` in it at all. `register()` is idempotent for
## exactly this case, so the cheap fix is to try again at the point of use.
func _save_manager() -> Node:
	var manager: Node = get_node_or_null(^"/root/SaveManager")
	if manager != null:
		_register(manager)
	return manager


func _register(manager: Node = null) -> void:
	var target: Node = manager if manager != null else get_node_or_null(^"/root/SaveManager")
	if target != null and target.has_method("register"):
		target.call("register", SAVE_DOMAIN, self)


## --- the interface everything else calls -----------------------------------

## The inventory itself. Handed out rather than hidden, because a caller that
## wants to walk the slots — the inventory screen, a satchel being filled —
## should not need a forwarding method per question.
func inventory() -> RefCounted:
	if _inventory == null:
		_inventory = INVENTORY.new()
	return _inventory


func equipment() -> RefCounted:
	if _equipment == null:
		_equipment = EQUIPMENT.new()
	return _equipment


func add(item_id: String, count: int = 1) -> bool:
	_refusal = ""
	var took: bool = inventory().add(item_id, count)
	if took:
		changed.emit()
	else:
		refused.emit(last_refusal())
	return took


func remove(item_id: String, count: int = 1) -> bool:
	_refusal = ""
	var spent: bool = inventory().remove(item_id, count)
	if spent:
		changed.emit()
	else:
		refused.emit(last_refusal())
	return spent


func count_of(item_id: String) -> int:
	return inventory().count_of(item_id)


func has(item_id: String, amount: int = 1) -> bool:
	return inventory().has(item_id, amount)


## Why the last operation was refused. One token, from `inventory.gd`'s enumerated
## set or from this file's — the caller switches on it, and the UI translates it.
func last_refusal() -> String:
	return _refusal if not _refusal.is_empty() else str(inventory().last_refusal())


func slot_count() -> int:
	return inventory().slot_count()


func at(index: int) -> RefCounted:
	return inventory().at(index)


func used_slots() -> int:
	return inventory().used_slots()


func is_full() -> bool:
	return inventory().is_full()


## Put an existing stack back, keeping its durability — what looting a satchel
## does. Returns false when there is no room, and the stack is untouched.
func place(stack: RefCounted, index: int = -1) -> bool:
	_refusal = ""
	var landed: bool = inventory().place(stack, index)
	if landed:
		changed.emit()
	return landed


## Wear a tool by one use. M8's gathering calls this; how much a swing costs
## belongs to whatever swings it, not here.
func use_tool(index: int, amount: int = 1) -> bool:
	_refusal = ""
	var used: bool = inventory().use_tool(index, amount)
	if used:
		changed.emit()
	else:
		refused.emit(last_refusal())
	return used


## Rearranging, forwarded so the screen does not have to reach past this node for
## half its verbs and through it for the other half.
func move_slot(from_index: int, to_index: int) -> bool:
	var moved: bool = inventory().move(from_index, to_index)
	if moved:
		changed.emit()
	return moved


## --- eating ----------------------------------------------------------------

## Eat what is in a slot. One of it, and only if it is food.
##
## GAME_DESIGN.md §18 and CLAUDE.md: FOOD BUFFS, NO STARVATION METER. Eating
## grants a timed bonus on the trainer's own numbers and not eating costs
## nothing — there is no hunger anywhere in this file, nothing counts down while
## the player does not eat, and no state exists below "has eaten nothing".
##
## The item is spent only if the meal was actually applied, so a refusal never
## silently eats a berry.
func eat(index: int) -> bool:
	_refusal = ""
	var stack: RefCounted = at(index)
	if stack == null:
		_refusal = REFUSED_EMPTY_SLOT
		refused.emit(_refusal)
		return false
	var item_id := str(stack.item_id)
	var block := DEFS.food(item_id)
	if block.is_empty():
		_refusal = REFUSED_NOT_FOOD
		refused.emit(_refusal)
		return false

	var vitals: RefCounted = _vitals()
	if vitals == null:
		# Named as wiring rather than as something the player did wrong. A bag with
		# no trainer attached is a mistake in the scene.
		_refusal = REFUSED_NO_TRAINER
		refused.emit(_refusal)
		return false

	if not vitals.eat(item_id, block, food_seconds_scale()):
		_refusal = REFUSED_BAD_FOOD_DATA
		refused.emit(_refusal)
		return false

	inventory().remove_at(index, 1)
	changed.emit()
	ate.emit(item_id, float(block.get("seconds", 0.0)) * food_seconds_scale())
	return true


func is_food(index: int) -> bool:
	var stack: RefCounted = at(index)
	return stack != null and DEFS.is_food(str(stack.item_id))


## --- free repair ------------------------------------------------------------

## §19: tools "repair for free at appropriate station". Free is the whole promise
## — no materials, no partial restore, no cost of any kind — and `inventory.gd`
## already implements it. What this adds is WHERE.
##
## THE STATION IS THE BASE. `pieces.json` has no workbench: `station.gd` lists it
## as waiting on crafting recipes, and stubbing one in to be a repair point would
## be the empty-station pattern that file refuses. So the appropriate station is
## home — the bed the player built, which `home.gd` already knows how to find and
## which `recovery.gd` already uses to mean "the place your things get better".
##
## REPAIRING ANYWHERE WAS THE ALTERNATIVE AND IT IS WORSE. A tool that repairs in
## the field makes durability a button you press occasionally rather than a reason
## to go home, and M9 asks for durability as a real cost. Refusing when there is
## no home at all is the same answer `recovery` gives — build a bed — and it is
## what makes the first shelter matter.
##
## A test harness with no Home node wired repairs anywhere, so the rule never
## stands between a unit test and the arithmetic it is checking.
func repair(index: int) -> bool:
	_refusal = ""
	var stack: RefCounted = at(index)
	if stack == null or not stack.is_durable():
		_refusal = REFUSED_NOT_DURABLE if stack != null else REFUSED_EMPTY_SLOT
		refused.emit(_refusal)
		return false
	if not can_repair_here():
		_refusal = REFUSED_NOT_AT_HOME
		refused.emit(_refusal)
		return false
	var fixed: bool = inventory().repair(index)
	if fixed:
		changed.emit()
	return fixed


## Is the trainer somewhere a tool can be repaired? True when no home node is
## wired at all, which is the headless case.
func can_repair_here() -> bool:
	var home: Node = get_node_or_null(home_path)
	if home == null or not home.has_method("is_at_home"):
		return true
	var trainer: Node3D = _player() as Node3D
	if trainer == null:
		return false
	return bool(home.call("is_at_home", trainer.global_position))


## --- the trainer -----------------------------------------------------------

func _player() -> Node:
	return get_node_or_null(player_path)


func _vitals() -> RefCounted:
	var trainer: Node = _player()
	if trainer == null:
		return null
	var vitals: Variant = trainer.get("vitals")
	return vitals if vitals is RefCounted else null


## --- config ----------------------------------------------------------------

func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("survival.json missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_config = parsed
	return _config


func food_seconds_scale() -> float:
	var food: Dictionary = config().get("food", {})
	return maxf(0.0, float(food.get("seconds_scale", 1.0)))


## What the trainer starts a new game holding.
##
## GRANTED ONCE, AND ONLY TO A NEW GAME. `SaveDirector` restores slot 0 a frame
## after the scene is built, and `load_data()` replaces these contents wholesale —
## so a returning player gets what they had, including an empty bag if they spent
## it all, and never a fresh axe every time they launch.
##
## The three revival draughts used to be seeded by `recovery.gd` into a private
## bag, because nothing owned the trainer's inventory. Something does now.
func _grant_starting_kit() -> void:
	if _kit_given:
		return
	_kit_given = true
	var kit: Dictionary = config().get("starting_kit", {})
	var items: Variant = kit.get("items", {})
	if not items is Dictionary:
		return
	for item_id: String in (items as Dictionary).keys():
		if item_id.begins_with("_"):
			continue
		var count := int((items as Dictionary)[item_id])
		if count <= 0:
			continue
		if not DEFS.has(item_id):
			# Loud: a starting kit naming an item that does not exist is a typo in
			# data, and a player who silently starts with no axe has no way to know.
			push_warning("starting kit names '%s', which is not in the item tables" % item_id)
			continue
		inventory().add(item_id, count)


## --- save contributor -------------------------------------------------------

func save_data() -> Dictionary:
	return {
		"slots": inventory().to_records(),
		"worn": equipment().to_records(),
	}


func load_data(data: Dictionary) -> void:
	_inventory = INVENTORY.from_records(data.get("slots", []))
	_equipment = EQUIPMENT.from_records(data.get("worn", []))
	_kit_given = true
	changed.emit()


## Save and reload through the shared envelope, matching what `party_manager` and
## `structures` expose so a caller does not have to know which slot is in use.
func save() -> bool:
	var manager := _save_manager()
	return bool(manager.call("save", 0)) if manager != null else false
