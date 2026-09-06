extends Node

## Stage B Wave 3 lane 3.E. THE OFFER: the conversation that happens BEFORE a
## `transfer_item` intent exists.
##
## CLAUDE.md: players trade items, never creatures. Nothing in this file can
## move a creature; the only intent it ever submits is `transfer_item`, and
## `world_ledger.gd` only knows how to move an item id and a count with it.
##
## ## Why an offer is not a ledger intent
##
## The ledger arbitrates the MOVE. It cannot arbitrate the offer, because the
## question an offer asks -- "do you want this, and have you got room for it?"
## -- can only be answered by the peer being offered to: `world_ledger.gd`'s
## header is explicit that the host cannot see a client's satchel. So the offer
## is a two-message conversation between the two players, and only its ACCEPTED
## outcome becomes an intent. This node carries that conversation and nothing
## else; it re-implements no rule from `world_ledger.gd`, and it never writes an
## inventory.
##
## ## The flow, and where the anti-duplication guarantee actually sits
##
##   1. the giver calls `offer(to_peer, item, count)`, which mints a `txn_id`
##      and sends `_rpc_offer` to that peer. NOTHING moves. No escrow.
##   2. the receiver sees `offer_received`, checks its OWN satchel for room,
##      and calls `accept()` or `decline()`.
##   3. an accept comes back to the giver as `_rpc_reply`. The giver -- who is
##      the only process that can see its own satchel -- re-checks that it still
##      holds the stack, then submits ONE `transfer_item` intent carrying that
##      same `txn_id`.
##   4. the ledger refuses a second commit of that `txn_id` with `duplicate`,
##      and commits an `item_take` addressed to the giver and an `item_grant`
##      addressed to the receiver. `ledger_rpc.gd::_apply_player_ops()` applies
##      each peer's own half when the delta lands.
##
## Step 4 is where "no stack is ever duplicated" lives, and it is lane 3.A's
## code, proven in `tests/test_world_ledger_races.gd`. Steps 1-3 are allowed to
## be lossy; they are not allowed to be creative.
##
## ## A disconnect mid-offer
##
## Nothing is held in escrow at any point, which is the whole reason a
## disconnect mid-offer cannot duplicate or destroy anything: an unaccepted
## offer is a message, and the items are in the giver's satchel the entire time.
## A peer that vanishes before accepting leaves the giver holding exactly what
## it started with. A peer that vanishes after accepting cannot deliver its
## accept, so no intent is ever submitted. Both sides additionally forget an
## offer the moment the other peer disconnects (`_on_peer_disconnected`), so a
## reconnecting player is not asked to answer a conversation nobody remembers.
##
## The one window that is NOT closed by this: the receiver disconnecting in the
## milliseconds between sending its accept and the delta landing. The grant is
## then addressed to a peer that is gone. There is no way to close it from the
## consumer side -- the host would have to hold the stack, and holding it means
## seeing it, which is the thing `world_ledger.gd` cannot do. The giver checks
## the receiver is still connected immediately before submitting, which narrows
## it to one network hop. It is recorded as a handover in
## `ralph/reports/MP-3E-TRADING-0906/REPORT.md`.
##
## ## Where this node lives
##
## `/root/Game/Session/TradeOffer`, beside `LedgerRpc` and for the same reason:
## the node path has to be IDENTICAL in every process or the RPCs do not
## resolve at all. `attach()` is idempotent.
##
## Solo: `offer()` refuses with a sentence and nothing else in this file ever
## runs. There is no second code path for solo to rot down -- solo simply has
## nobody to offer to.

const SESSION := preload("res://scripts/net/session.gd")
const SPAWNER := preload("res://scripts/world/dropped_item_spawner.gd")
const OFFER_PANEL := preload("res://scripts/ui/trade_offer_panel.gd")

const NODE_NAME := "TradeOffer"
const CHANNEL_LEDGER := SESSION.CHANNEL_LEDGER

## Somebody is offering this peer something. `offer` is
## `{"txn_id", "from", "item", "count", "realm"}`.
signal offer_received(offer: Dictionary)

## An offer this peer is part of ended, on either side. `ok` is whether items
## actually moved; `reason` is one player-facing sentence, or "" when the answer
## was a plain "no thanks".
signal offer_resolved(txn_id: String, ok: bool, reason: String)


## The offer this peer has OUT, waiting on an answer:
## `{"txn_id", "to", "item", "count", "realm"}`. Empty when there is none.
var _outgoing: Dictionary = {}

## The offer this peer has been SENT and has not answered yet. Same shape with
## `from` instead of `to`.
var _incoming: Dictionary = {}


## Find or mount the offer transport under the session. Returns the node, or
## `null` when there is no `Game` to hang it off.
static func attach(game: Node) -> Node:
	if game == null:
		return null
	var parent: Node = game.get("session") as Node
	if parent == null:
		parent = game
	var existing := parent.get_node_or_null(NodePath(NODE_NAME))
	if existing != null:
		return existing
	var node: Node = (load("res://scripts/ui/trade_offer.gd") as GDScript).new()
	node.name = NODE_NAME
	parent.add_child(node)
	return node


## The live transport for this process, mounting it if this is the first ask.
static func of(game: Node) -> Node:
	return attach(game)


func _ready() -> void:
	name = NODE_NAME
	process_mode = Node.PROCESS_MODE_ALWAYS
	var api := multiplayer
	if api != null and not api.peer_disconnected.is_connected(_on_peer_disconnected):
		api.peer_disconnected.connect(_on_peer_disconnected)


# --- the giver's side ---------------------------------------------------------------

## Offer `count` of `item` to `to_peer`. Returns
## `{"ok": bool, "txn_id": String, "reason": String}` -- `ok` only means the
## offer was SENT, never that anything moved.
func offer(to_peer: int, item: String, count: int) -> Dictionary:
	if item.is_empty() or count <= 0:
		return _sent(false, "", "There is nothing there to give.")
	if not _connected_to(to_peer):
		return _sent(false, "", "They are not in this world any more.")
	var game := _game()
	if game == null:
		return _sent(false, "", "The world is not ready yet.")
	var satchel: RefCounted = game.get("inventory") as RefCounted
	if satchel == null or int(satchel.call("count", item)) < count:
		return _sent(false, "", "You are not carrying that any more.")
	if not _outgoing.is_empty():
		return _sent(false, "", "You are already waiting on an answer.")

	var txn := _mint_txn()
	var realm := SPAWNER.realm_of(get_tree())
	_outgoing = {"txn_id": txn, "to": to_peer, "item": item, "count": count, "realm": realm}
	rpc_id(to_peer, "_rpc_offer", txn, item, count, realm)
	return _sent(true, txn, "")


## Withdraw an offer that has not been answered. Nothing moved, so nothing has
## to be put back.
func cancel_offer() -> void:
	if _outgoing.is_empty():
		return
	var txn := str(_outgoing.get("txn_id", ""))
	var to_peer := int(_outgoing.get("to", 0))
	_outgoing = {}
	if _connected_to(to_peer):
		rpc_id(to_peer, "_rpc_withdraw", txn)
	offer_resolved.emit(txn, false, "")


## The offer this peer has out, or an empty Dictionary.
func outgoing() -> Dictionary:
	return _outgoing.duplicate()


# --- the receiver's side ------------------------------------------------------------

## The offer waiting on this peer's answer, or an empty Dictionary.
func incoming() -> Dictionary:
	return _incoming.duplicate()


## Say yes. The satchel check is HERE, on the only process that can see this
## satchel, and a refusal for want of room goes back as one sentence the giver
## can read -- never as a silent drop, and never as items on the floor.
func accept() -> Dictionary:
	if _incoming.is_empty():
		return _sent(false, "", "Nobody is offering you anything.")
	var txn := str(_incoming.get("txn_id", ""))
	var item := str(_incoming.get("item", ""))
	var n := int(_incoming.get("count", 0))
	var from_peer := int(_incoming.get("from", 0))
	var game := _game()
	var satchel: RefCounted = null
	if game != null:
		satchel = game.get("inventory") as RefCounted
	if satchel == null:
		return _reply_no(txn, from_peer, "The world is not ready yet.")
	if not bool(satchel.call("has_room_for", item, n)):
		return _reply_no(txn, from_peer, "Their satchel is full.")
	if not _connected_to(from_peer):
		return _reply_no(txn, from_peer, "They are not in this world any more.")
	_incoming = {}
	rpc_id(from_peer, "_rpc_reply", txn, true, "")
	return _sent(true, txn, "")


## Say no. A plain decline carries no sentence -- there is nothing to explain.
func decline() -> Dictionary:
	if _incoming.is_empty():
		return _sent(false, "", "Nobody is offering you anything.")
	return _reply_no(str(_incoming.get("txn_id", "")), int(_incoming.get("from", 0)), "")


func _reply_no(txn: String, to_peer: int, reason: String) -> Dictionary:
	_incoming = {}
	if _connected_to(to_peer):
		rpc_id(to_peer, "_rpc_reply", txn, false, reason)
	offer_resolved.emit(txn, false, reason)
	return _sent(false, txn, reason)


# --- rpc --------------------------------------------------------------------------------

## Giver -> receiver. The sender id comes from the transport, never from the
## payload, so a peer cannot offer "as" somebody else -- the same rule
## `ledger_rpc.gd::_rpc_intent` follows.
@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_offer(txn_id: String, item: String, count: int, realm: String) -> void:
	var from_peer := multiplayer.get_remote_sender_id()
	if txn_id.is_empty() or item.is_empty() or count <= 0 or from_peer == 0:
		return
	if not _incoming.is_empty():
		# Already deciding on somebody else's offer. Refuse the second rather
		# than replace the first, so an offer a player is looking at cannot be
		# swapped under their finger.
		rpc_id(from_peer, "_rpc_reply", txn_id, false, "They are busy with another trade.")
		return
	_incoming = {"txn_id": txn_id, "from": from_peer, "item": item,
		"count": count, "realm": realm}
	# Built on the FIRST offer this peer ever receives and reused after that, so
	# a process nobody offers anything to never builds it. The panel reads
	# `incoming()` in its own `_ready`, which is why the signal below can be
	# emitted after it and still reach a panel that did not exist a line ago.
	OFFER_PANEL.attach(self)
	offer_received.emit(_incoming.duplicate())


## Giver -> receiver: never mind.
@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_withdraw(txn_id: String) -> void:
	if str(_incoming.get("txn_id", "")) != txn_id:
		return
	_incoming = {}
	offer_resolved.emit(txn_id, false, "")


## Receiver -> giver. THE one place a `transfer_item` intent is ever born.
@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_reply(txn_id: String, accepted: bool, reason: String) -> void:
	var from_peer := multiplayer.get_remote_sender_id()
	if str(_outgoing.get("txn_id", "")) != txn_id:
		return
	if int(_outgoing.get("to", 0)) != from_peer:
		# An answer from somebody who was never asked.
		return
	var offered := _outgoing
	_outgoing = {}
	if not accepted:
		var game := _game()
		if game != null and not reason.is_empty():
			game.call("push_world_message", reason)
		offer_resolved.emit(txn_id, false, reason)
		return
	_submit_transfer(offered)


# --- committing the accepted offer ----------------------------------------------------

## The giver's own submit. `from` is this peer and `to` is the receiver, both
## explicit, and `realm` is the realm the offer was made in (D97) -- never read
## off a global at commit time.
##
## NOTHING is moved here. The `item_take` the ledger commits is a `player` op
## addressed to this peer and `ledger_rpc.gd::_apply_player_ops()` applies it
## when the delta lands; a satchel written here as well would pay twice.
func _submit_transfer(offered: Dictionary) -> void:
	var txn := str(offered.get("txn_id", ""))
	var item := str(offered.get("item", ""))
	var n := int(offered.get("count", 0))
	var to_peer := int(offered.get("to", 0))
	var game := _game()
	if game == null:
		offer_resolved.emit(txn, false, "The world is not ready yet.")
		return
	var satchel: RefCounted = game.get("inventory") as RefCounted
	if satchel == null or int(satchel.call("count", item)) < n:
		# Spent, dropped or traded away while the offer was out. Say so rather
		# than submit an intent whose take would silently move nothing.
		var gone := "You are not carrying that any more."
		game.call("push_world_message", gone)
		if _connected_to(to_peer):
			rpc_id(to_peer, "_rpc_withdraw", txn)
		offer_resolved.emit(txn, false, gone)
		return
	if not _connected_to(to_peer):
		var left := "They are not in this world any more."
		game.call("push_world_message", left)
		offer_resolved.emit(txn, false, left)
		return

	var transport: Node = game.get("ledger") as Node
	if transport == null:
		offer_resolved.emit(txn, false, "The world is not ready yet.")
		return
	var verdict: Dictionary = transport.call("submit", {
		"kind": "transfer_item",
		"realm": str(offered.get("realm", "meadows")),
		"txn_id": txn,
		"item": item,
		"count": n,
		"from": _local_peer_id(),
		"to": to_peer,
	})
	if bool(verdict.get("ok", false)):
		offer_resolved.emit(txn, true, "")
		return
	if bool(verdict.get("pending", false)):
		# A client waiting on the host. `ledger_rpc.gd` pushes the refusal
		# sentence itself if one comes back; the delta is the success signal and
		# it moves the satchel without this file's help.
		return
	offer_resolved.emit(txn, false, str(verdict.get("reason", "")))


# --- disconnects ------------------------------------------------------------------------

## Forget any offer the departed peer was part of. Nothing is in escrow, so
## there is nothing to give back -- this only stops a player being asked to
## answer a conversation whose other side is gone.
func _on_peer_disconnected(peer_id: int) -> void:
	if not _outgoing.is_empty() and int(_outgoing.get("to", 0)) == peer_id:
		var out_txn := str(_outgoing.get("txn_id", ""))
		_outgoing = {}
		offer_resolved.emit(out_txn, false, "They left before answering.")
	if not _incoming.is_empty() and int(_incoming.get("from", 0)) == peer_id:
		var in_txn := str(_incoming.get("txn_id", ""))
		_incoming = {}
		offer_resolved.emit(in_txn, false, "They left before you answered.")


# --- internals ----------------------------------------------------------------------------

## Unique per offer, and unique across peers: the ledger refuses a repeated
## `txn_id` with `duplicate`, so two peers minting the same string would refuse
## each other's honest trades. Peer id + a monotonic clock + a roll is enough
## that a collision needs the same peer, the same microsecond and the same roll.
func _mint_txn() -> String:
	return "trade:%d:%d:%d" % [_local_peer_id(), Time.get_ticks_usec(), randi()]


## Whether an rpc to `peer_id` can actually reach anybody. False solo, false in
## a headless test with no peer, and false for a peer that has left.
func _connected_to(peer_id: int) -> bool:
	if peer_id == 0 or not is_inside_tree():
		return false
	var api := multiplayer
	if api == null or not api.has_multiplayer_peer():
		return false
	if peer_id == api.get_unique_id():
		return false
	return api.get_peers().has(peer_id)


func _local_peer_id() -> int:
	var game := _game()
	if game == null:
		return SESSION.HOST_PEER_ID
	var session: Variant = game.get("session")
	if session == null:
		return SESSION.HOST_PEER_ID
	return int((session as Node).call("local_peer_id"))


func _game() -> Node:
	return get_node_or_null(^"/root/Game")


static func _sent(ok: bool, txn_id: String, reason: String) -> Dictionary:
	return {"ok": ok, "txn_id": txn_id, "reason": reason}
