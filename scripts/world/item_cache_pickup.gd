extends Node3D

## T3-PICKUPS. A one-time, non-renewable item find: the mechanism
## `key_pickup.gd` already proves (item_id -> satchel, a `pickup:<id>` flag
## that survives reload, refuse-not-vanish on a full satchel) with the one
## piece that doesn't generalise -- a literal key-shaped mesh -- swapped for
## a plain prop, loaded the same PackedScene-vs-Mesh way
## `harvest_node.gd::_build_visual()` and `props.gd::place()` already load
## every glTF in this project.
##
## Why not just call `key_pickup.gd` directly: its `setup(item_id, label)`
## really is generic (nothing in its persistence logic is key-specific), but
## `_build_visual()` hard-builds a shaft-and-ring key regardless of what
## `item_id` names. A permanent elixir sitting in the world as a brass key
## would read as a bug, not a find. This file exists ONLY to swap that one
## piece; the flag/inventory contract below is deliberately the same shape,
## not a second design.
##
## `data/items/items.json` has no `_comment` claiming every world item must
## be a `key_pickup`/`tm_pickup` -- both are already item-id-driven, both
## already coexist as separate one-time pickup props, and CLAUDE.md's own
## reuse rule is "prefer existing infrastructure", not "there may be only
## one file". No new inventory, currency, recipe or loot system is added:
## this is a third THIN PROP wired to the one satchel every pickup already
## shares.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const PICKUP_GLOW := preload("res://scripts/world/pickup_glow.gd")
## OP-0905-18: a no-op unless `_item_id` is a known evolution catalyst.
const PROGRESSION_FEED := preload("res://scripts/creatures/progression_feed.gd")
## D103 / Stage B lane 3.B. See `_on_picked_up()`: this find is claimed through
## the world ledger now, not written here.
const LEDGER_CLAIM := preload("res://scripts/world/ledger_claim.gd")

const FLAG_PREFIX := "cache:"

## The ledger said no, with one sentence a player can act on and the machine tag
## behind it. The same surface `storage_container.gd::storage_refused` gives its
## own panel (lane 3.D): `ledger_claim.gd` already SHOWS the sentence, so nothing
## has to connect to this -- it exists so a caller that wants to know WHY (a
## test, or a future prompt that wants to say "somebody beat you to it" in its
## own voice) is not left reading HUD text.
signal claim_refused(code: String, reason: String)


var _item_id: String = ""
var _label: String = ""
var _model_path: String = ""
var _model_scale: float = 1.0
var _placement_id := ""
var _realm_id := "meadows"
var _count := 1
var _taken := false
var _visual: Node3D = null
var _prompt: Node3D = null
## True between submitting a `claim_pickup` and hearing back. It is what tells
## "MY claim committed" from "somebody else's did" when the delta lands on both
## peers -- the only difference between the two is which player's satchel the
## ledger's own `item_grant` op was addressed to.
var _claiming := false


func setup(item_id: String, label: String, model_path: String, model_scale: float = 1.0,
		placement_id: String = "", realm_id: String = "meadows", count: int = 1) -> void:
	_item_id = item_id
	_label = label
	_model_path = model_path
	_model_scale = model_scale
	_placement_id = placement_id
	_realm_id = realm_id
	_count = maxi(1, count)
	add_to_group("progression_restore")
	_build_visual()
	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.position = Vector3.UP * 0.6
	_prompt.call("configure", _label, 2.4, true)
	_prompt.connect("activated", _on_picked_up)
	add_child(_prompt)
	LEDGER_CLAIM.listen(self, _on_delta_applied)
	_listen_for_refusals()
	var game := get_node_or_null(^"/root/Game")
	if was_taken(game, _item_id, _placement_id, _realm_id):
		_deactivate()


## Keep main's public placement key and historic Meadows flag format.
## Non-Meadows locations are realm-qualified so stacked worlds stay isolated.
func _key() -> String:
	if _placement_id.is_empty():
		return _item_id
	return _placement_id if _realm_id == "meadows" else _realm_id + ":" + _placement_id


static func flag_id(item_id: String, placement_id: String = "", realm_id: String = "meadows") -> String:
	if not placement_id.is_empty():
		if realm_id == "meadows":
			return FLAG_PREFIX + placement_id
		return "%s%s:%s" % [FLAG_PREFIX, realm_id, placement_id]
	return FLAG_PREFIX + item_id


static func was_taken(game: Node, item_id: String, placement_id: String = "", realm_id: String = "meadows") -> bool:
	if game == null or item_id == "":
		return false
	var progression: RefCounted = game.get("progression")
	return progression != null and bool(progression.call("has", flag_id(item_id, placement_id, realm_id)))


func restore_progression_from_game(game: Node) -> void:
	if was_taken(game, _item_id, _placement_id, _realm_id):
		_deactivate()


func _deactivate() -> void:
	_taken = true
	if _prompt != null and is_instance_valid(_prompt):
		_prompt.call("set_enabled", false)
	PICKUP_GLOW.detach(self)
	visible = false
	queue_free()


## The find's own colour, from `data/items/items.json` -- the same source
## `key_pickup.gd::_item_colour()` reads, so two pickup props marking the same
## item can never disagree about what colour it is.
func _item_colour() -> Color:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return Color(0.85, 0.72, 0.35)
	var items: RefCounted = game.get("items")
	return items.call("colour", _item_id) if items != null else Color(0.85, 0.72, 0.35)


## Same PackedScene-vs-Mesh branch harvest_node.gd::_build_visual() and
## props.gd::place() already use for this exact glTF pack -- a bare
## `load()` result assigned straight to `MeshInstance3D.mesh` type-fails
## silently on a multi-part scene.
func _build_visual() -> void:
	if _model_path != "" and ResourceLoader.exists(_model_path):
		var resource: Resource = load(_model_path)
		if resource is PackedScene:
			var wrapper := Node3D.new()
			wrapper.add_child((resource as PackedScene).instantiate())
			wrapper.scale = Vector3.ONE * _model_scale
			_visual = wrapper
		elif resource is Mesh:
			var mesh := MeshInstance3D.new()
			mesh.mesh = resource as Mesh
			mesh.scale = Vector3.ONE * _model_scale
			_visual = mesh
	if _visual == null:
		var fallback := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3.ONE * 0.3
		fallback.mesh = box
		_visual = fallback
		push_warning("item_cache_pickup: '%s' did not load as a Mesh or PackedScene" % _model_path)
	add_child(_visual)

	# OP-0830-3. This used to carry an `OmniLight3D` of its own -- the
	# "short-range presence cue" tm_pickup.gd's header argues for, and the
	# reasoning was sound: a one-time find is met at dusk or in cover as often
	# as in the open. What was wrong with it is that it was THIS PROP'S answer.
	# Five pickup scripts each had a different one (or none), so whether a find
	# was visible depended on which script drew it, and the owner's report is
	# that most of them are not. It also does not scale: the world holds well
	# over a hundred pickups and OP-0830-6 is an open ROG performance defect, so
	# a light each is exactly the thing this lane's order rules out by name.
	#
	# Replaced by the shared highlight, which is two MultiMeshes for every
	# pickup in the game and rides ABOVE the grass canopy rather than trying to
	# out-shine it. The item's own colour still drives the tint, so a cache
	# still reads as its own find rather than as a generic marker.
	PICKUP_GLOW.attach(self, _item_colour())


## D103, Stage B lane 3.B. This used to grant the item and write the
## `cache:<id>` flag itself. Both are the ledger's now: a `claim_pickup` INTENT
## goes up, the host arbitrates it, and the committed delta carries the flag
## (world scope, every peer) and the `item_grant` (player scope, the one peer
## who won). Nothing here changes until that delta lands -- so two players
## reaching the same cache produce exactly one grant, and the loser sees the
## find simply stay where it is rather than a pickup that vanished and paid
## nothing.
##
## Solo is not a second path. `submit()` on a solo player is a host with nobody
## to tell: it commits in-process, emits the delta before it returns, and
## `_on_delta_applied()` below has already run by the time this function
## continues -- which is why `_taken` is re-checked rather than assumed.
##
## The satchel check stays HERE, before the intent. The host cannot see a
## client's satchel (`world_ledger.gd`'s header says so outright), so "is there
## room" is the one question only this peer can answer, and a full satchel must
## still refuse visibly rather than spending the world's only copy of a find.
func _on_picked_up() -> void:
	if _taken or _claiming:
		return
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; a cache was found but has nowhere to go")
		return
	var inventory: RefCounted = game.get("inventory")
	if inventory == null:
		push_error("no inventory; a cache was found but has nowhere to go")
		return
	if not bool(inventory.call("has_room_for", _item_id, _count)):
		# Refused, visibly, same as key_pickup.gd/harvest_node.gd: stays in
		# the world and keeps offering rather than vanishing into a full
		# satchel.
		game.call("push_world_message", "Satchel is full.")
		return
	_claiming = true
	var verdict := LEDGER_CLAIM.submit(self, {
		"kind": "claim_pickup",
		"realm": _realm_id,
		"flag": flag_id(_item_id, _placement_id, _realm_id),
		"item": _item_id,
		"count": _count,
	})
	if not LEDGER_CLAIM.in_flight(verdict):
		# A refusal we can act on now (`already_taken` from a race this peer
		# lost on the host, or an offline transport). `ledger_claim.gd::submit`
		# has already said the sentence; the find stays standing and keeps
		# offering.
		_claiming = false
		claim_refused.emit(str(verdict.get("code", "")), str(verdict.get("reason", "")))


## The committed delta. Host, client and solo all arrive here, which is the
## point: removal is driven by the delta, never by the intent, so a lost race
## looks like the pickup staying put and a won one looks exactly like it always
## did. The `item_grant` half was applied by `ledger_rpc.gd` before this fired.
func _on_delta_applied(delta: Dictionary) -> void:
	if not LEDGER_CLAIM.sets_world_flag(delta, flag_id(_item_id, _placement_id, _realm_id)):
		return
	# `_taken` is checked after the flag, not before it: on a client
	# `ledger_rpc.gd::_rpc_delta` runs the `progression_restore` sweep before it
	# emits `delta_applied`, so this node can already be deactivated by the time
	# we arrive and the claim still has to be closed out.
	# OP-0905-18: the catalyst line belongs to the peer whose claim this was,
	# not to everyone the delta reaches, so it is read off `_claiming` before
	# that is cleared. A no-op for every item that is not a known evolution
	# catalyst (heartstone/sunstone) -- see progression_feed.gd's own comment.
	var was_mine := _claiming
	_claiming = false
	if was_mine:
		PROGRESSION_FEED.announce_catalyst_pickup(_item_id)
	if not _taken:
		_deactivate()


## A refusal that crossed the wire. A client's `submit()` only ever answers
## "pending", so `ledger_rpc.gd::intent_refused` is the ONLY way it hears
## `already_taken` -- and `_rpc_verdict` is addressed to the one peer whose
## intent it was, so a refusal arriving here is always ours. Gated on
## `_claiming` for the same reason `storage_container.gd` gates its own: only a
## node with a claim in flight has anything to drop.
func _on_intent_refused(kind: String, code: String, reason: String, _detail: Dictionary) -> void:
	if kind != "claim_pickup" or not _claiming:
		return
	_claiming = false
	claim_refused.emit(code, reason)


func _listen_for_refusals() -> void:
	var transport := LEDGER_CLAIM.transport(self)
	if transport == null:
		return
	if not transport.is_connected("intent_refused", _on_intent_refused):
		transport.connect("intent_refused", _on_intent_refused)


## The transport is an autoload child at an identical path in every process, so
## it is already there when this node enters the tree. Connected here as well as
## in `setup()` because a caller that sets the node up BEFORE adding it to the
## tree would otherwise never hear a delta at all -- `listen()` is idempotent.
func _ready() -> void:
	LEDGER_CLAIM.listen(self, _on_delta_applied)
	_listen_for_refusals()
