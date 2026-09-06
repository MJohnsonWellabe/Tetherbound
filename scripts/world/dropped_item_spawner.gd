extends Node

## Stage B Wave 3 lane 3.E. The one thing in a world that turns a committed
## `item_dropped` op into a `dropped_item.gd` on the ground.
##
## `world_ledger.gd` calls this op `scene` scope, and its header says why:
## "a fact whose live mirror lives in a scene node that owns its own format and
## cannot be written from a pure state object". A dropped stack is exactly that
## -- `WorldState` has nowhere to put a prop -- so the ledger commits the fact
## and this node draws it, on every peer, off the same delta.
##
## ## Why it hangs off the WORLD and not off `Game`
##
## It carries the realm of the world it was attached to, and ignores an
## `item_dropped` op stamped with any other realm. That is D97 read the way
## `storage_container.gd::realm()` reads it: the realm of a thing comes from the
## thing, not from a global "where is the local player right now". It also means
## the spawner and every stack it drew are freed together when the world is,
## which is the correct lifetime -- an `item_dropped` op is scene scope, is not
## in `WorldState`, and does not survive a reload (see the handover in
## `ralph/reports/MP-3E-TRADING-0906/REPORT.md`).
##
## Attached from each world root's `_ready()` with one line, the same way
## `ledger_rpc.gd::attach()` is mounted from `game_state.gd`, and idempotent for
## the same reason: any caller may ask without coordinating who asks first.

const DROPPED_ITEM := preload("res://scripts/world/dropped_item.gd")
const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")

const NODE_NAME := "DroppedItems"

## One spawner per world; the group is how a caller with only a `SceneTree`
## finds the realm it is standing in without reading a global.
const GROUP := &"dropped_item_spawner"

var realm: String = "meadows"


## Find or mount the spawner under `world`. Returns the node, or `null` when
## there is no world to hang it off.
static func attach(world: Node, world_realm: String = "meadows") -> Node:
	if world == null:
		return null
	var existing := world.get_node_or_null(NodePath(NODE_NAME))
	if existing != null:
		existing.set("realm", world_realm)
		return existing
	var node: Node = (load("res://scripts/world/dropped_item_spawner.gd") as GDScript).new()
	node.name = NODE_NAME
	node.set("realm", world_realm)
	world.add_child(node)
	return node


## The realm of the world this process is standing in, read off the spawner
## rather than off `Game.current_realm` -- so an intent stamped with it is
## stamped from the place the drop is happening (D97), the same source
## `storage_container.gd` reads a chest's realm from.
##
## Falls back to "meadows" when no world has attached a spawner, which is the
## realm every headless fixture in this repo builds.
static func realm_of(tree: SceneTree) -> String:
	if tree == null:
		return "meadows"
	for node in tree.get_nodes_in_group(GROUP):
		if is_instance_valid(node):
			return str(node.get("realm"))
	return "meadows"


## Where a stack this peer drops should land: the local player's own feet.
##
## Found through the spawner because the spawner's PARENT is the world root, and
## `<world>/Player` is where every other reader in this repo looks for the local
## body (`gate_f_probe.gd::player()`, `playground_world.gd::local_rig()`). A
## caller with only a `SceneTree` then does not have to know which world scene
## is standing.
static func drop_origin(tree: SceneTree) -> Vector3:
	if tree == null:
		return Vector3.ZERO
	for node in tree.get_nodes_in_group(GROUP):
		if not is_instance_valid(node):
			continue
		var world := (node as Node).get_parent()
		if world == null:
			continue
		var body := world.get_node_or_null(^"Player")
		if body != null and body is Node3D:
			return (body as Node3D).global_position
	return Vector3.ZERO


func _ready() -> void:
	name = NODE_NAME
	add_to_group(GROUP)
	_connect_ledger()


func _connect_ledger() -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return
	var transport: Node = game.get("ledger") as Node
	if transport == null:
		return
	if not transport.is_connected("delta_applied", _on_delta_applied):
		transport.connect("delta_applied", _on_delta_applied)


## Every peer runs this off the same committed delta, so the stack is drawn once
## per process because the ledger committed once -- never once per process that
## decided to draw something.
func _on_delta_applied(delta: Dictionary) -> void:
	for raw: Variant in WORLD_LEDGER.scene_ops(delta):
		var op := raw as Dictionary
		if str(op.get("op", "")) != "item_dropped":
			continue
		if str(op.get("realm", "")) != realm:
			continue
		_spawn(op)


func _spawn(op: Dictionary) -> void:
	var txn := str(op.get("txn_id", ""))
	var item := str(op.get("item", ""))
	var n := int(op.get("count", 0))
	if txn.is_empty() or item.is_empty() or n <= 0:
		return
	# A delta replayed into a process that already drew this stack. The ledger's
	# own `_seen_txns` refuses a second COMMIT; this is the drawing half of the
	# same guard, and it is what keeps a re-sent delta from doubling the props
	# on screen even though it could never double the items.
	if _already_drawn(txn):
		return
	var node: Node3D = DROPPED_ITEM.new()
	# A txn id carries colons, which Godot silently rewrites in a node name.
	# Doing it here means the name in a remote debugger matches the id in a log.
	node.name = "Dropped_%s" % txn.validate_node_name()
	add_child(node)
	node.call("setup", txn, item, n, realm, _position(op.get("position")))


func _already_drawn(txn: String) -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	for node in tree.get_nodes_in_group(DROPPED_ITEM.GROUP):
		if is_instance_valid(node) and str(node.call("txn_id")) == txn:
			return true
	return false


## `WorldState` stores positions as plain arrays so they survive JSON, and an op
## that crossed the wire arrives as one -- with every number a float.
static func _position(raw: Variant) -> Vector3:
	if typeof(raw) == TYPE_VECTOR3:
		return raw as Vector3
	if typeof(raw) == TYPE_ARRAY and (raw as Array).size() == 3:
		var a := raw as Array
		return Vector3(float(a[0]), float(a[1]), float(a[2]))
	return Vector3.ZERO
