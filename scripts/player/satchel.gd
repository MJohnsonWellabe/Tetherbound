extends Node3D

## Everything the trainer has ever dropped by dying, and where it fell.
##
## GAME_DESIGN.md §22, in full: carried inventory drops into a satchel at the
## death location; OLD SATCHELS DO NOT MOVE; SEVERAL CAN COEXIST; each stays
## marked on the map and the minimap; no XP and no levels are lost. CLAUDE.md
## repeats the middle of that as a hard rule — "Multiple death satchels persist".
##
## So this is a LIST, never a variable. The single most likely way to break the
## rule is to write `_satchel` instead of `_satchels` and have the second death
## quietly delete the first bag, which is the one bug in this file that a player
## could not recover from. Everything below is written against a list: `drop()`
## appends, nothing overwrites, and `tests/test_satchel.gd` dies at exactly the
## line that would let a second death take the first bag.
##
## A satchel is DATA plus a marker. The data is an `inventory.gd` — the same
## container the trainer carries, sized to what fell into it, which is why a
## 40%-worn axe comes back out of a satchel 40% worn. The marker is a placeholder
## box built in code; there is no bag model in the project and a placeholder is
## fine for proving the mechanic (CLAUDE.md, Prototyping).
##
## IT NEVER TAKES ANYTHING BY ITSELF. `scripts/player/death.gd` decides what falls
## and calls `drop()`; this file does not listen to the player dying, does not
## know what killed them and does not touch the trainer's bag. One thing decides,
## one thing stores.

const INVENTORY := preload("res://scripts/items/inventory.gd")
const STACK := preload("res://scripts/items/item_stack.gd")
const CONFIG_PATH := "res://data/config/survival.json"

## The key this system owns inside `SaveManager`'s one envelope (D14).
##
## A satchel that does not survive a relaunch has EATEN the player's inventory,
## which is strictly worse than never having dropped one. This domain is the
## reason it does.
const SAVE_DOMAIN := "satchels"

signal dropped(satchel: RefCounted)
## `moved` is how many stacks made it into the trainer's bag and `left` how many
## are still in the satchel because there was no room.
signal looted(satchel: RefCounted, moved: int, left: int)
signal emptied(satchel: RefCounted)

## The trainer, for "am I close enough to reach into it". Optional: without one,
## nothing is automatic and `loot()` still works when something calls it.
@export var player_path: NodePath = NodePath("../Player")
## Where looted items go. The same node M8's gathering adds to.
@export var inventory_path: NodePath = NodePath("../TrainerInventory")
## For putting a marker on the ground rather than at the height the player
## happened to die at. Optional.
@export var world_path: NodePath = NodePath("..")

var _satchels: Array[RefCounted] = []
## Marker nodes, keyed by satchel id, so a looted satchel can take its own marker
## away without a search.
var _markers: Dictionary = {}
var _next_id: int = 1
var _config: Dictionary = {}


func _ready() -> void:
	_register()


func _save_manager() -> Node:
	var manager: Node = get_node_or_null(^"/root/SaveManager")
	if manager != null:
		_register(manager)
	return manager


## Lazy re-registration, D14. Under `--script` the autoloads attach only after the
## entry point's `_init()` returns, so `_ready()` can run in a tree with no
## SaveManager in it; `register()` is idempotent for exactly this.
func _register(manager: Node = null) -> void:
	var target: Node = manager if manager != null else get_node_or_null(^"/root/SaveManager")
	if target != null and target.has_method("register"):
		target.call("register", SAVE_DOMAIN, self)


## --- one satchel ------------------------------------------------------------

## What fell out of somebody, where, and when.
##
## An `inventory.gd` inside rather than a bare Array of stacks, because the two
## things a satchel has to do are exactly what that file already does: hold stacks
## in slots, and write itself into a save record. Its own header names a death
## satchel as the caller allowed to ask for a different slot count.
class Satchel extends RefCounted:

	var id: int = 0
	var where: Vector3 = Vector3.ZERO
	## Wall-clock seconds, only so a UI can say "older" and "newer" between two
	## bags on the same hillside. Nothing decides anything from it — satchels do
	## not expire. §22 says old satchels do not move, and a timer that deleted one
	## would be the same loss as moving it.
	var created_unix: int = 0
	var items: RefCounted = null

	func count() -> int:
		return 0 if items == null else items.used_slots()

	func is_empty() -> bool:
		return items == null or items.is_empty()

	## What is in it, as live stacks, for a UI to list.
	func stacks() -> Array:
		var out: Array = []
		if items == null:
			return out
		for entry: Variant in items.slots():
			if entry != null:
				out.append(entry)
		return out

	func to_record() -> Dictionary:
		return {
			"id": id,
			"x": where.x,
			"y": where.y,
			"z": where.z,
			"at": created_unix,
			"items": [] if items == null else items.to_records(),
		}


## Rebuild one satchel from its record.
##
## On the OUTER script rather than beside `to_record()` in the class it builds,
## because a static method of an inner class cannot reliably reach its own type to
## instantiate it. The pair is documented together instead: the whole failure mode
## of a save is one side writing a key the other side does not read, so any edit
## to `to_record()` above belongs in the same commit as an edit here.
static func satchel_from_record(record: Dictionary) -> RefCounted:
	var raw: Variant = record.get("items", [])
	var records: Array = raw if raw is Array else []
	var satchel: RefCounted = Satchel.new()
	satchel.id = int(record.get("id", 0))
	satchel.where = Vector3(
		float(record.get("x", 0.0)), float(record.get("y", 0.0)), float(record.get("z", 0.0))
	)
	satchel.created_unix = int(record.get("at", 0))
	satchel.items = INVENTORY.from_records(records, maxi(1, records.size()))
	return satchel


## Lift a whole stack OUT of an inventory, wear and all.
##
## `inventory.gd` has `remove_at()`, which empties the stack in place, and
## `place()`, which takes a stack — and the obvious combination of the two is a
## bug that reads as correct: hand `place()` the live stack, then `remove_at()`
## the slot it came from, and the object now sitting in the destination is the one
## you just emptied. Measured, twice, in two different milestones: a satchel that
## dropped three stacks and held nothing, and a chest that swallowed an axe.
##
## So the stack is COPIED through its own save record — the one path in the
## project that is already required to carry durability across — and the original
## slot is then cleared. A 40%-worn axe comes out 40% worn.
static func take_stack(items: RefCounted, index: int) -> RefCounted:
	if items == null:
		return null
	var stack: RefCounted = items.at(index)
	if stack == null or stack.is_empty():
		return null
	var lifted: RefCounted = STACK.from_record(stack.to_record())
	if lifted == null:
		return null
	items.remove_at(index, int(stack.count))
	return lifted


## --- dropping ---------------------------------------------------------------

## Put a pile of stacks on the ground at `where`, as a new satchel.
##
## APPENDS. There is no code path in this file that replaces or removes an
## existing satchel except looting it empty, and that is the hard rule
## ("Multiple death satchels persist") expressed as an absence.
##
## An empty pile still makes a satchel, and deliberately: dying with nothing
## should still leave a marker where you fell, because "where did I die" is the
## question the marker answers and the answer is not less true for being cheap.
## `death.gd` is where the decision not to bother would belong, not here.
func drop(where: Vector3, stacks: Array) -> RefCounted:
	var satchel: RefCounted = Satchel.new()
	satchel.id = _next_id
	_next_id += 1
	satchel.where = where
	satchel.created_unix = int(Time.get_unix_time_from_system())
	satchel.items = INVENTORY.new(maxi(1, stacks.size()))
	for entry: Variant in stacks:
		var stack: RefCounted = entry as RefCounted
		if stack == null or stack.is_empty():
			continue
		if not satchel.items.place(stack):
			push_warning("a satchel could not hold everything that fell into it")
	_satchels.append(satchel)
	_show(satchel)
	dropped.emit(satchel)
	return satchel


## --- reading ----------------------------------------------------------------

## Every satchel, oldest first. A copy of the list — the satchels inside are the
## live ones, the same discipline `party.members()` and `inventory.slots()` use.
func satchels() -> Array:
	return _satchels.duplicate()


func count() -> int:
	return _satchels.size()


func at(index: int) -> RefCounted:
	return _satchels[index] if index >= 0 and index < _satchels.size() else null


func by_id(id: int) -> RefCounted:
	for satchel in _satchels:
		if int(satchel.id) == id:
			return satchel
	return null


## The nearest satchel within `radius`, or null. What "press X to open" asks.
func nearest(point: Vector3, radius: float = -1.0) -> RefCounted:
	var reach := radius if radius > 0.0 else loot_range()
	var best: RefCounted = null
	var best_distance := reach
	for satchel in _satchels:
		var distance: float = (satchel.where as Vector3).distance_to(point)
		if distance <= best_distance:
			best_distance = distance
			best = satchel
	return best


## --- looting ----------------------------------------------------------------

## Take everything out of a satchel that will fit in the trainer's bag.
##
## PARTIAL ON PURPOSE, unlike `inventory.add()`. All-or-nothing is right for a
## crafting cost, where half a payment is a bug; it is wrong here, because a
## player standing over their own belongings with two free slots should get two
## slots' worth rather than a refusal. What does not fit stays in the satchel and
## the satchel stays where it is.
##
## Stacks are moved WHOLE with `place()`, not re-added by id, so the worn axe
## comes back worn — `inventory.add()` would build a fresh one from the item
## definition and quietly repair it.
func loot(satchel: RefCounted, into: Object = null) -> int:
	if satchel == null:
		return 0
	var bag: Object = into if into != null else get_node_or_null(inventory_path)
	if bag == null or not bag.has_method("place"):
		return 0

	var moved := 0
	for i in satchel.items.slot_count():
		if satchel.items.at(i) == null:
			continue
		# Lifted out FIRST, as a copy that carries its own wear, and only put back
		# in the satchel if the bag would not take it. The other order — place the
		# live stack, then clear the slot — empties the very stack it just handed
		# over; `take_stack()` above records where that was measured.
		var lifted := take_stack(satchel.items, i)
		if lifted == null:
			continue
		if bool(bag.call("place", lifted)):
			moved += 1
		else:
			satchel.items.place(lifted, i)

	var left: int = satchel.count()
	looted.emit(satchel, moved, left)
	if left == 0:
		_forget(satchel)
	return moved


## An emptied satchel goes away — its marker, its map pin and its record.
##
## This is the ONE thing that removes a satchel, and it only happens because the
## player carried its contents away. Nothing else in the file removes one: not a
## timer, not a cap on how many may exist, not a new death.
func _forget(satchel: RefCounted) -> void:
	_satchels.erase(satchel)
	var marker: Variant = _markers.get(int(satchel.id))
	if marker is Node and is_instance_valid(marker):
		(marker as Node).queue_free()
	_markers.erase(int(satchel.id))
	emptied.emit(satchel)


## --- reaching one in the world ---------------------------------------------

## `interact` opens the satchel you are standing over.
##
## The same action that engages a wild pal, and that is not a clash in practice:
## engaging needs a creature within six metres and this needs a bag within two and
## a half, and a satchel is not usually lying under a wild pal. It is guarded
## anyway — nothing is looted while the trainer's locomotion is suspended, which
## is exactly the set of states where the button belongs to something else: a
## fight, build mode, or an open menu.
func _physics_process(_delta: float) -> void:
	if _satchels.is_empty():
		return
	if not Input.is_action_just_pressed("interact"):
		return
	var trainer: Node3D = get_node_or_null(player_path) as Node3D
	if trainer == null:
		return
	if trainer.has_method("locomotion_enabled") and not bool(trainer.call("locomotion_enabled")):
		return
	var satchel := nearest(trainer.global_position)
	if satchel != null:
		loot(satchel)


## --- the marker in the world ------------------------------------------------

## A placeholder bag: a small dark box on the ground where you fell.
##
## PLACEHOLDER, and named as one. There is no satchel model in the project and
## CLAUDE.md allows placeholder art to prove a mechanic — but it also says not to
## judge the look of the game by one. What matters here is that the thing is
## visible from a distance and stands out from grass, because a satchel you cannot
## find is a satchel that ate your inventory.
func _show(satchel: RefCounted) -> void:
	var marker := Node3D.new()
	marker.name = "Satchel%d" % int(satchel.id)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.55, 0.45, 0.4)
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	# Leather brown, and slightly emissive so it does not go black in the shadow of
	# the tree you died under.
	material.albedo_color = Color(0.31, 0.19, 0.11)
	material.roughness = 0.85
	material.emission_enabled = true
	material.emission = Color(0.35, 0.22, 0.10)
	material.emission_energy_multiplier = 0.25
	mesh.material_override = material
	mesh.position = Vector3(0.0, 0.22, 0.0)
	marker.add_child(mesh)
	add_child(marker)
	# `global_position` is only meaningful once this node is in the scene tree, and
	# a unit test builds satchels outside one. Local is the same thing here — this
	# node sits at the world origin — and it keeps the engine from logging an
	# is_inside_tree error for every bag in a headless run.
	var where := _on_the_ground(satchel.where)
	if is_inside_tree():
		marker.global_position = where
	else:
		marker.position = where
	_markers[int(satchel.id)] = marker


## The ground under a point, when the world can be asked. D09: never raycast for
## ground — `ground_height_at` reads the heightmap, which is the one source that
## cannot disagree with itself.
func _on_the_ground(point: Vector3) -> Vector3:
	var world: Node = get_node_or_null(world_path)
	if world == null or not world.has_method("ground_height_at"):
		return point
	var ground: float = float(world.call("ground_height_at", point.x, point.z))
	if is_nan(ground):
		return point
	return Vector3(point.x, ground, point.z)


func _rebuild_markers() -> void:
	for marker: Variant in _markers.values():
		if marker is Node and is_instance_valid(marker):
			(marker as Node).queue_free()
	_markers.clear()
	for satchel in _satchels:
		_show(satchel)


## --- config -----------------------------------------------------------------

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


func loot_range() -> float:
	var death: Dictionary = config().get("death", {})
	return maxf(0.5, float(death.get("loot_range", 2.6)))


## --- save contributor -------------------------------------------------------

func save_data() -> Dictionary:
	var records: Array = []
	for satchel in _satchels:
		records.append(satchel.to_record())
	return {"satchels": records, "next_id": _next_id}


func load_data(data: Dictionary) -> void:
	_satchels.clear()
	var highest := 0
	for entry: Variant in data.get("satchels", []):
		if not entry is Dictionary:
			continue
		var satchel: RefCounted = satchel_from_record(entry as Dictionary)
		# A satchel whose every item has been deleted from the tables would come
		# back as an empty marker nobody can clear, so it is dropped instead. Any
		# other satchel is restored exactly where it fell.
		if satchel.is_empty():
			continue
		_satchels.append(satchel)
		highest = maxi(highest, int(satchel.id))
	_next_id = maxi(int(data.get("next_id", 1)), highest + 1)
	_rebuild_markers()
