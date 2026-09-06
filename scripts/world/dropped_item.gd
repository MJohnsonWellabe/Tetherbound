extends Node3D

## Stage B Wave 3 lane 3.E. A STACK LYING ON THE GROUND: what `drop_item`
## leaves behind, and what anybody standing near it can pick up.
##
## Before this lane, `autoload/inventory.gd::drop_slot()` deleted the stack and
## said so in its own comment ("in case a future world-pickup entity wants to
## spawn from it; none exists yet"). This is that entity.
##
## ## Who spawns it, and why it is not spawned by the dropper
##
## Nobody spawns one directly. `world_ledger.gd::_drop_item()` commits a `scene`
## op -- `{"op": "item_dropped", "txn_id", "item", "count", "position", "from"}`
## -- alongside the `item_take` that empties the dropper's satchel, and
## `dropped_item_spawner.gd` turns that op into one of these on EVERY peer that
## hears the delta, the dropper included. So the prop exists once per process
## because the ledger committed once, not once per process that decided to draw
## something. A dropper that spawned its own prop and then also heard the delta
## would draw two.
##
## ## Picking it up is a `claim_pickup`, not a second drop intent
##
## The ledger already arbitrates exactly this shape: one flag, first writer
## wins, the loser told `already_taken`, and the item granted to whoever won.
## The flag is `dropped:<txn_id>` -- the drop's own transaction id, which is
## unique by construction and already the thing the ledger refuses a replay of.
## Two players lunging for the same stack is then the same race as two players
## lunging for the same cache, decided by the same lines.
##
## A full satchel is refused HERE, before the intent goes anywhere: `has_room_for`
## is a question about this peer's own satchel and no other peer can answer it
## (`world_ledger.gd`'s header: the host cannot see a client's satchel). The
## stack stays on the ground and keeps offering, the way `item_cache_pickup.gd`
## and `harvest_node.gd` already refuse rather than vanish into a full bag.
##
## ## What it deliberately does NOT carry
##
## Tool durability. The `item_dropped` op carries an item id and a count and
## nothing else, and `scripts/net/world_ledger.gd` is lane 3.A's file. So a worn
## axe dropped and picked back up returns at full durability. See
## `ralph/reports/MP-3E-TRADING-0906/REPORT.md` for the handover.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const PICKUP_GLOW := preload("res://scripts/world/pickup_glow.gd")

## The world flag that means "this dropped stack has been claimed". Realm is
## already inside the txn id's uniqueness, so it is not repeated here.
const FLAG_PREFIX := "dropped:"

## Every live dropped stack in this process. The net smoke counts what the world
## is holding through this group, and `pick_up_nearest()` finds its target
## through it.
const GROUP := &"dropped_item"

## How high above the committed drop position the prop sits, so a stack dropped
## at the player's feet is not half-buried in the terrain.
const REST_HEIGHT_M := 0.25

var _txn_id: String = ""
var _item_id: String = ""
var _count: int = 1
var _realm: String = "meadows"
var _claimed: bool = false
var _prompt: Node3D = null
var _visual: Node3D = null


## The world fact "this dropped stack is gone". Static so the spawner, the
## entity and the tests all name it in one place.
static func flag_id(txn_id: String) -> String:
	return FLAG_PREFIX + txn_id


## Everything an `item_dropped` op carries. Called by the spawner immediately
## after `add_child`, so the node is in the tree and `global_position` sticks.
func setup(txn_id: String, item_id: String, count: int, realm: String, at: Vector3) -> void:
	_txn_id = txn_id
	_item_id = item_id
	_count = maxi(1, count)
	_realm = realm
	global_position = at + Vector3.UP * REST_HEIGHT_M
	add_to_group(GROUP)

	_build_visual()

	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.position = Vector3.UP * 0.4
	_prompt.call("configure", "Pick up %s" % _label(), 2.4, true)
	_prompt.connect("activated", pick_up)
	add_child(_prompt)

	# A stack somebody already claimed while this peer was still applying the
	# delta that created it. Cheap to ask, and the alternative is a prop that
	# offers a pickup the ledger will refuse.
	if _already_claimed():
		_deactivate()
	_connect_ledger()


func txn_id() -> String:
	return _txn_id


func item_id() -> String:
	return _item_id


func count() -> int:
	return _count if not _claimed else 0


func realm() -> String:
	return _realm


# --- picking it up ---------------------------------------------------------------

## Submit the claim. Returns `world_ledger.gd`'s verdict shape, the same as
## `storage_container.gd::submit_deposit()`: `ok` solo and on a host, `pending`
## on a client with the host still to answer, and otherwise a refusal whose
## `reason` is one sentence to show.
##
## NOTHING moves here on `pending`. The `item_grant` the ledger commits is a
## `player` op addressed to this peer, and `ledger_rpc.gd::_apply_player_ops()`
## is what puts it in the satchel when the delta lands -- on the host inside
## `submit()`, on a client when `_rpc_delta` arrives. A satchel written here as
## well would hold two of everything picked up.
func pick_up() -> Dictionary:
	if _claimed:
		return _refusal("That is already gone.")
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return _refusal("The world is not ready yet.")
	var transport: Node = game.get("ledger") as Node
	var satchel: RefCounted = game.get("inventory") as RefCounted
	if transport == null or satchel == null:
		return _refusal("The world is not ready yet.")

	if not bool(satchel.call("has_room_for", _item_id, _count)):
		# Refused with a sentence, and the stack stays where it is. Only this
		# peer can answer this question, so it is asked before the intent is
		# minted rather than after the host has already committed a grant into
		# a satchel that cannot hold it.
		var full := "Your satchel is full."
		game.call("push_world_message", full)
		return _refusal(full)

	var verdict: Dictionary = transport.call("submit", {
		"kind": "claim_pickup",
		"realm": _realm,
		"flag": flag_id(_txn_id),
		"item": _item_id,
		"count": _count,
	})
	if bool(verdict.get("ok", false)):
		# Host or solo: the delta has already been applied and the flag is set.
		# `_on_delta_applied` would have caught this too; doing it here as well
		# is harmless (`_deactivate` is idempotent) and keeps the solo press
		# feeling instant rather than one signal hop late.
		_deactivate()
	elif not bool(verdict.get("pending", false)):
		var reason := str(verdict.get("reason", ""))
		if not reason.is_empty():
			game.call("push_world_message", reason)
	return verdict


## The nearest unclaimed dropped stack within `radius` of `from`, or null. The
## interact prompt is the shipping path; this is what the net smoke presses
## with, and what a caller with a position but no prompt (a controller-driven
## "grab" verb) would use.
static func nearest(tree: SceneTree, from: Vector3, radius: float = 4.0) -> Node3D:
	if tree == null:
		return null
	var best: Node3D = null
	var best_d := radius
	for raw in tree.get_nodes_in_group(GROUP):
		if not is_instance_valid(raw) or not (raw is Node3D):
			continue
		var node: Node3D = raw
		if bool(node.get("_claimed")):
			continue
		var d := node.global_position.distance_to(from)
		if d <= best_d:
			best_d = d
			best = node
	return best


# --- the ledger conversation -------------------------------------------------------

func _connect_ledger() -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return
	var transport: Node = game.get("ledger") as Node
	if transport == null:
		return
	if not transport.is_connected("delta_applied", _on_delta_applied):
		transport.connect("delta_applied", _on_delta_applied)


## Somebody's claim committed. Every peer runs this, the claimer included, so
## the stack disappears from every screen off the same delta rather than off
## whoever happened to press.
func _on_delta_applied(delta: Dictionary) -> void:
	if _claimed:
		return
	var mine := flag_id(_txn_id)
	for raw: Variant in (delta.get("ops", []) as Array):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var op := raw as Dictionary
		if str(op.get("op", "")) != "flag" or str(op.get("scope", "")) != "world":
			continue
		if str(op.get("id", "")) == mine and bool(op.get("value", true)):
			_deactivate()
			return


func _already_claimed() -> bool:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return false
	var progression: RefCounted = game.get("progression") as RefCounted
	return progression != null and bool(progression.call("has", flag_id(_txn_id)))


func _deactivate() -> void:
	if _claimed:
		return
	_claimed = true
	if _prompt != null and is_instance_valid(_prompt):
		_prompt.call("set_enabled", false)
	PICKUP_GLOW.detach(self)
	remove_from_group(GROUP)
	visible = false
	queue_free()


# --- presentation --------------------------------------------------------------------

func _label() -> String:
	var name_of := _item_id
	var game := get_node_or_null(^"/root/Game")
	if game != null:
		var db: RefCounted = game.get("items") as RefCounted
		if db != null:
			name_of = str(db.call("item_name", _item_id))
	if _count > 1:
		return "%d %s" % [_count, name_of]
	return name_of


## A plain tinted box under the shared pickup highlight. Deliberately NOT a
## per-item model: a dropped stack is any of a hundred item ids, and
## `item_cache_pickup.gd`'s own comment records why a per-prop light does not
## scale. The item's own colour is what makes one dropped stack readable from
## another, which is the same answer every other pickup in this game gives.
func _build_visual() -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.26, 0.26, 0.26)
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = _item_colour()
	mesh.material_override = material
	_visual = mesh
	add_child(_visual)
	PICKUP_GLOW.attach(self, _item_colour())


func _item_colour() -> Color:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return Color(0.85, 0.72, 0.35)
	var db: RefCounted = game.get("items") as RefCounted
	return db.call("colour", _item_id) if db != null else Color(0.85, 0.72, 0.35)


func _refusal(reason: String) -> Dictionary:
	return {
		"ok": false, "kind": "claim_pickup", "peer": 0, "code": "offline",
		"reason": reason, "pending": false, "delta": {"seq": 0, "realm": "", "ops": []},
	}
