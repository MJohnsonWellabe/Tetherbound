extends Node

## The party's place in the world.
##
## `party.gd` is a `RefCounted` on purpose — no nodes, so it survives a scene
## change and can be tested headlessly. But something has to own it, keep it
## alive, put it in the save file and let the rest of the scene find it. That is
## all this is: a holder, a save contributor, and a forwarding surface.
##
## It deliberately adds no rules of its own. The five-pal cap, the refusal
## tokens and the record format all live in `party.gd`, and a manager that
## re-implemented any of them would be a second place for the hard rule to be
## true — which is one more than a hard rule can survive.
##
## `TECHNICAL_START.md` names `PartyManager` in its core systems list; this is
## that, kept as thin as the name allows.

const PARTY := preload("res://scripts/pals/party.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")

## The key this system owns inside `SaveManager`'s one envelope.
const SAVE_DOMAIN := "party"

signal changed()
signal refused(token: String)

var party: RefCounted = null


func _ready() -> void:
	party = PARTY.new()
	_register()


## Godot attaches autoloads only after a `--script` entry point's `_init()`
## returns, and every smoke and session builds its world inside `_init()`. So
## `_ready()` here can run in a tree that has no `/root/SaveManager` yet, and
## registering once at startup would silently never happen.
##
## `SaveManager.register()` is idempotent for exactly this reason, so the cheap
## fix is to try again at the point of use. `structures.gd` hit this first and
## solved it the same way; this comment exists so the third system to need it
## does not have to rediscover it.
func _save_manager() -> Node:
	var manager: Node = get_node_or_null(^"/root/SaveManager")
	if manager != null:
		_register(manager)
	return manager


func _register(manager: Node = null) -> void:
	var target: Node = manager if manager != null else get_node_or_null(^"/root/SaveManager")
	if target != null and target.has_method("register"):
		target.call("register", SAVE_DOMAIN, self)


## --- save contributor -----------------------------------------------------

func save_data() -> Dictionary:
	return {"members": party.to_records(), "active": party.active_index}


func load_data(data: Dictionary) -> void:
	party = PARTY.from_records(data.get("members", []))
	party.set_active(int(data.get("active", 0)))
	changed.emit()


## --- the forwarding surface -----------------------------------------------
##
## Every one of these is one line and does nothing but delegate. That is the
## point: a caller holding the manager and a caller holding the party get the
## same answers, so there is no "which one is authoritative" question to get
## wrong later.

func add(instance: RefCounted) -> bool:
	var accepted: bool = party.add(instance)
	if accepted:
		changed.emit()
	else:
		refused.emit(party.last_refusal())
	return accepted


func size() -> int:
	return party.size()


func capacity() -> int:
	return party.capacity()


func is_full() -> bool:
	return party.is_full()


func members() -> Array:
	return party.members()


func at(index: int) -> RefCounted:
	return party.at(index)


func active() -> RefCounted:
	return party.active()


func last_refusal() -> String:
	return party.last_refusal()


func remove_at(index: int) -> bool:
	var removed: bool = party.remove_at(index)
	if removed:
		changed.emit()
	return removed


func set_active(index: int) -> bool:
	var moved: bool = party.set_active(index)
	if moved:
		changed.emit()
	return moved


func cycle_active(step: int = 1) -> bool:
	var moved: bool = party.cycle_active(step)
	if moved:
		changed.emit()
	return moved


func clear() -> void:
	party.clear()
	changed.emit()


func to_records() -> Array:
	return party.to_records()


## Mirrors `party.active_index` as a property so a caller can read it without
## knowing a manager is in the way.
var active_index: int:
	get:
		return party.active_index if party != null else 0
	set(value):
		set_active(value)


## Save and reload through the shared envelope. Thin wrappers, matching what
## `structures.gd` exposes, so a caller does not have to know which slot the
## game is using.
func save() -> bool:
	var manager := _save_manager()
	return bool(manager.call("save", 0)) if manager != null else false


func load_saved() -> int:
	var manager := _save_manager()
	if manager == null:
		return 0
	manager.call("load_slot", 0)
	return party.size()
