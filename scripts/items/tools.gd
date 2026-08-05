extends Node

## What the trainer is holding, and what happens when they swing it.
##
## Three files meet here and none of them knows about the other two:
##
##   - `scripts/items/inventory.gd` owns slots, stacks and durability, and knows
##     nothing about the world.
##   - `scripts/world/harvestable.gd` owns the meadow's props and knows nothing
##     about an inventory.
##   - This owns the SWING: which tool is in hand, what a swing costs it, and
##     where the wood ends up.
##
## That split is what lets the other two be tested with no scene at all, and it
## is why `harvest()` next door returns what a swing WOULD produce rather than
## producing it.
##
## A TOOL IS NEVER A WEAPON. `GAME_DESIGN.md` §19: tools "cannot damage pals or
## humans", and CLAUDE.md's "Human cannot fight" is a hard rule. There is no
## damage number in this file, nothing here looks for a creature, and nothing
## here can be aimed at one — `harvestable.gd` only knows about trees, timber,
## boulders, stones and bushes. The day this file grows a `hit(target)` the hard
## rule has been broken by whoever added it.
##
## THE INVENTORY IS SOMEBODY ELSE'S. This file never builds one. It reaches the
## trainer's through a duck-typed surface — a node called `TrainerInventory`, or
## a player with an `inventory()` accessor — and if neither is there it REFUSES
## the swing and says so. An inventory of its own would be a second bag that
## disagrees with the real one about what the player is carrying.

const DEFS := preload("res://scripts/items/item_defs.gd")

## One contributor to the single save envelope; `save_director` finds it by this
## constant. See `autoload/save_manager.gd` for why there is only one file.
const SAVE_DOMAIN := "tools"

## `tool_cycle` has been bound in `project.godot` since M0 and was read by
## nothing — `build_mode.gd` used to borrow it and its own comment records giving
## it back. This is what it is for.
const CYCLE_ACTION := "tool_cycle"

## The swing shares a button with the quick attack, deliberately.
##
## `combat_manager.gd` documents the principle: "Engage and charged attack are
## the same physical button." On a handheld there are not enough face buttons for
## a verb that is only ever available in one context, and outside a fight and
## outside build mode this button does nothing at all. The guards in
## `_physics_process` are what keep the three uses from overlapping.
const SWING_ACTION := "combat_quick"

## Refusal tokens, not sentences (`party.gd`'s idiom). Everything
## `harvestable.gd` can refuse is passed through unchanged, so a HUD maps one set.
const REFUSED_NO_INVENTORY := "no_inventory"
const REFUSED_NO_WORLD := "no_harvestables"
const REFUSED_TOOL_BROKEN := "tool_broken"
const REFUSED_BAG_FULL := "bag_full"

const REFUSALS := [
	REFUSED_NO_INVENTORY,
	REFUSED_NO_WORLD,
	REFUSED_TOOL_BROKEN,
	REFUSED_BAG_FULL,
]

## Bare hands. Not a tool, not an item, and not an empty slot — a real, selectable
## position in the cycle, because berries and fallen timber are gathered by hand
## and a player should not have to unequip to pick a berry.
const HANDS := ""

signal swung(result: Dictionary)
signal refused(reason: String)
signal equipped_changed(item_id: String)

@export var player_path: NodePath
@export var harvestable_path: NodePath
## The `TrainerInventory` node, when the scene names one. Left empty means "look
## for it", which is what happens in the shipping scene.
@export var inventory_path: NodePath
## Both optional. A swing must not fire while a fight or build mode owns the
## same button.
@export var build_path: NodePath
@export var combat_path: NodePath

var _player: Node3D = null
var _harvestable: Node = null
var _build: Node = null
var _combat: Node = null

## The item id of what is in hand, NOT a slot index.
##
## An index goes stale the moment the player reorders their bag or the axe breaks
## and is replaced; an id survives both, survives a save, and is what the HUD
## wants to draw anyway. The slot is looked up when it is needed.
var _equipped: String = HANDS
var _refusal: String = ""
var _swings: int = 0


func _ready() -> void:
	_player = get_node_or_null(player_path) as Node3D
	_harvestable = get_node_or_null(harvestable_path)
	_build = get_node_or_null(build_path)
	_combat = get_node_or_null(combat_path)
	# Registered here as well as being found by `save_director`'s tree scan, for
	# the reason `harvestable._register()` gives: this node is created at runtime
	# rather than living in the scene file, and a node added a frame after that
	# scan would be a system that works all session and is not in the save.
	# `SaveManager.register()` is idempotent by design.
	var manager := get_node_or_null(^"/root/SaveManager")
	if manager != null:
		manager.call("register", SAVE_DOMAIN, self)


## Wire this up directly, rather than through exported paths.
##
## The seam a test uses and the seam whatever eventually mounts this node in the
## world scene can use — `save_director.bind()` keeps the same one for the same
## reason: a system that can only be wired through the editor is a system that
## cannot be exercised without one.
func bind(trainer: Node3D, harvestable: Node, build: Node = null, combat: Node = null) -> void:
	_player = trainer
	_harvestable = harvestable
	if build != null:
		_build = build
	if combat != null:
		_combat = combat


## --- what is in hand --------------------------------------------------------

func equipped() -> String:
	return _equipped


func equipped_name() -> String:
	return "Hands" if _equipped == HANDS else DEFS.display_name(_equipped)


## The slot the equipped tool is in, or -1 for bare hands and for a tool that is
## no longer in the bag.
func equipped_slot() -> int:
	if _equipped == HANDS:
		return -1
	return _slot_of(_equipped)


func equipped_stack() -> RefCounted:
	var bag := _bag()
	var slot := equipped_slot()
	if bag == null or slot < 0:
		return null
	return bag.call("at", slot)


func is_broken() -> bool:
	var stack := equipped_stack()
	return stack != null and bool(stack.call("is_broken"))


## Fraction of durability left, or 1.0 for bare hands and for anything that is
## not durable — so a HUD bar reads "full" rather than "empty" when there is
## nothing to wear out.
func durability_fraction() -> float:
	var stack := equipped_stack()
	return 1.0 if stack == null else float(stack.call("durability_fraction"))


## Put something specific in hand. Refused for an item the trainer is not
## carrying, so the HUD cannot end up drawing an axe nobody owns.
func equip(item_id: String) -> bool:
	if item_id == HANDS:
		_set_equipped(HANDS)
		return true
	if not DEFS.is_tool_item(item_id) or _slot_of(item_id) < 0:
		return false
	_set_equipped(item_id)
	return true


## The cycle: hands first, then every tool in the bag in slot order.
##
## Hands are IN the list rather than being an unequip button, because they are a
## real gathering option and because a wheel you can get stuck in the wrong half
## of is worse than one extra stop.
func hand_cycle() -> Array[String]:
	var out: Array[String] = [HANDS]
	var bag := _bag()
	if bag == null:
		return out
	var slots: Array = bag.call("slots")
	for i in slots.size():
		var stack: Variant = slots[i]
		if stack == null:
			continue
		var id := str((stack as RefCounted).get("item_id"))
		if DEFS.is_tool_item(id) and not out.has(id):
			out.append(id)
	return out


## Step through the cycle. What `tool_cycle` does.
func cycle(step: int = 1) -> String:
	var order := hand_cycle()
	var at := order.find(_equipped)
	if at < 0:
		at = 0
	_set_equipped(order[posmod(at + step, order.size())])
	return _equipped


func _set_equipped(item_id: String) -> void:
	if item_id == _equipped:
		return
	_equipped = item_id
	equipped_changed.emit(_equipped)


func _slot_of(item_id: String) -> int:
	var bag := _bag()
	if bag == null:
		return -1
	var slots: Array = bag.call("slots")
	for i in slots.size():
		var stack: Variant = slots[i]
		if stack != null and str((stack as RefCounted).get("item_id")) == item_id:
			return i
	return -1


## --- swinging ---------------------------------------------------------------

func last_refusal() -> String:
	return _refusal


func swings() -> int:
	return _swings


## Where a swing lands: in front of the trainer, at half the harvest reach.
##
## The same shape as `build_mode._aim_point()` and for the same reason — this is
## a controller-first game and there is no mouse-look action in the input map at
## all, so what you are aiming at is what you are facing.
func aim_point() -> Vector3:
	if _player == null or not is_instance_valid(_player):
		return Vector3.ZERO
	var forward := -_player.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		forward = Vector3.FORWARD
	var reach := 3.2
	if _harvestable != null and _harvestable.has_method("reach"):
		reach = float(_harvestable.call("reach"))
	return _player.global_position + forward.normalized() * (reach * 0.5)


## What the trainer is looking at, for an interaction prompt. Read-only.
func target() -> Dictionary:
	if _harvestable == null or not _harvestable.has_method("inspect"):
		return {}
	return _harvestable.call("inspect", aim_point())


## Take one swing at `point`, or at whatever is in front of the trainer.
##
## THE ORDER MATTERS AND IS THE WHOLE FUNCTION:
##   1. refuse a broken tool before anything moves — §19 wants durability to be a
##      real cost, and a broken axe that keeps chopping is not one;
##   2. ask the world what the swing produces, which spends the prop's use;
##   3. put the yield in the bag, and PUT THE PROP BACK if the bag refuses it, so
##      a full inventory cannot silently strip the meadow;
##   4. only then wear the tool down, because a swing that produced nothing must
##      not have cost anything either.
func swing(point: Vector3 = Vector3.INF) -> Dictionary:
	_refusal = ""
	var bag := _bag()
	var purse := _purse()
	if bag == null or purse == null:
		_refusal = REFUSED_NO_INVENTORY
		refused.emit(_refusal)
		return {"ok": false, "refusal": _refusal}
	if _harvestable == null or not _harvestable.has_method("harvest"):
		_refusal = REFUSED_NO_WORLD
		refused.emit(_refusal)
		return {"ok": false, "refusal": _refusal}

	var slot := equipped_slot()
	if _equipped != HANDS and slot < 0:
		# The tool was dropped, stored or destroyed while it was in hand.
		_set_equipped(HANDS)
		slot = -1
	if slot >= 0:
		var stack: RefCounted = bag.call("at", slot)
		if stack != null and bool(stack.call("is_broken")):
			_refusal = REFUSED_TOOL_BROKEN
			refused.emit(_refusal)
			return {"ok": false, "refusal": _refusal}

	var at := point if point != Vector3.INF else aim_point()
	var result: Dictionary = _harvestable.call("harvest", at, _equipped)
	if not bool(result.get("ok", false)):
		_refusal = str(result.get("refusal", ""))
		refused.emit(_refusal)
		return result

	var item := str(result.get("item", ""))
	var count := int(result.get("count", 0))
	if count > 0 and not bool(purse.call("add", item, count)):
		_harvestable.call("put_back", result)
		_refusal = REFUSED_BAG_FULL
		refused.emit(_refusal)
		return {"ok": false, "refusal": _refusal, "item": item, "count": count}

	var wear := int(result.get("durability", 0))
	if slot >= 0 and wear > 0:
		_wear(slot, wear)
	result["tool"] = _equipped
	result["tool_broke"] = slot >= 0 and is_broken()
	_swings += 1
	swung.emit(result)
	return result


## Blunt the tool in `slot`.
##
## Through the FAÇADE where there is one, and only through the bare inventory
## otherwise. The façade emits `changed` when it is told about a change, and a
## durability bar that only updates when something else happens to move is the
## kind of bug that reads as "the axe broke without warning".
func _wear(slot: int, amount: int) -> void:
	var facade := _facade()
	if facade != null and facade.has_method("use_tool"):
		facade.call("use_tool", slot, amount)
		return
	var bag := _bag()
	if bag != null:
		bag.call("use_tool", slot, amount)


## --- input ------------------------------------------------------------------

## Read in `_physics_process`, never `_process`.
##
## `encounter_director` records what getting this wrong costs:
## `Input.is_action_just_pressed()` is scoped to the frame the press was recorded
## in, so two systems reading it from different loops each see half the presses.
## Build mode reads the same button from `_physics_process`; so does this.
func _physics_process(_delta: float) -> void:
	if not can_act():
		return
	if Input.is_action_just_pressed(CYCLE_ACTION):
		cycle(1)
	if Input.is_action_just_pressed(SWING_ACTION):
		swing()


## Whether the trainer's hands are their own right now.
##
## Build mode and combat both borrow `combat_quick`, and a menu means the player
## is not in the world at all. Checked here, in one place, rather than each of
## those having to know this file exists.
func can_act() -> bool:
	if get_tree() != null and get_tree().paused:
		return false
	if _build != null and _build.has_method("is_open") and bool(_build.call("is_open")):
		return false
	if _combat != null and _combat.has_method("is_fighting") and bool(_combat.call("is_fighting")):
		return false
	return true


## --- reaching the trainer's inventory ---------------------------------------
##
## The fixed surface, duck-typed with `has_method` guards the way the UI reaches
## its systems. TWO objects, because they answer different questions:
##
##   `_bag()`   the `scripts/items/inventory.gd` instance — slots, durability,
##              `use_tool`. Nothing else can say which slot the axe is in.
##   `_purse()` whatever should be TOLD about an acquisition — the façade node if
##              there is one, so its own bookkeeping and signals run, and the bag
##              itself otherwise.
##
## Neither is cached across calls. The trainer's inventory is built by another
## system and may arrive after this node does; a cached null would mean gathering
## never worked for the whole session.


func _facade() -> Object:
	var node := get_node_or_null(inventory_path)
	if node == null:
		var parent := get_parent()
		if parent != null:
			node = parent.get_node_or_null(^"TrainerInventory")
	if node != null and node.has_method("add") and node.has_method("count_of"):
		return node
	return null


func _bag() -> Object:
	var facade := _facade()
	if facade != null and facade.has_method("inventory"):
		var held: Variant = facade.call("inventory")
		if held is RefCounted and (held as RefCounted).has_method("use_tool"):
			return held
	if facade != null and facade.has_method("use_tool") and facade.has_method("slots"):
		return facade
	if _player != null and is_instance_valid(_player) and _player.has_method("inventory"):
		var mine: Variant = _player.call("inventory")
		if mine is RefCounted and (mine as RefCounted).has_method("use_tool"):
			return mine
	return null


func _purse() -> Object:
	var facade := _facade()
	if facade != null:
		return facade
	return _bag()


## --- the `tools` save domain ------------------------------------------------
##
## One string: what was in hand. The tools themselves are the inventory's to
## save, and re-deriving "which slot" on load is what makes this survive the
## player having reorganised their bag between sessions.


func save_data() -> Dictionary:
	return {"equipped": _equipped}


func load_data(data: Dictionary) -> void:
	var wanted := str(data.get("equipped", HANDS))
	# Through `equip()`, so a save naming a tool the trainer no longer has comes
	# back as empty hands rather than as a phantom axe.
	if not equip(wanted):
		_set_equipped(HANDS)
