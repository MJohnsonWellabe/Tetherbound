extends Node

## Stage B Wave 3 lane 3.A. THE LEDGER TRANSPORT: intents up, deltas down.
##
## D103's other half. `scripts/net/world_ledger.gd` decides; this file only
## carries. It holds one `WorldLedger` over `Game.world` and does exactly three
## things with it: commit on the host, broadcast the delta, apply an arriving
## delta on a client. No rule from `world_ledger.gd` is repeated here -- if a
## refusal reason lives in two files, the two files eventually disagree.
##
## ## One code path, solo included (execution plan §7)
##
## `submit()` is the only entry point, and solo runs it the same way a host
## does: `Game.is_host()` is true, the ledger commits in-process, the delta is
## applied, and the broadcast is skipped because `Game.is_multi_peer()` is
## false. There is no "solo branch" that could rot -- solo is a host with
## nobody to tell.
##
##     var verdict := ledger.submit({"kind": "claim_pickup", "realm": realm,
##         "flag": FLAG, "item": "elixir", "count": 1})
##     if not verdict.ok and not verdict.pending:
##         Game.push_world_message(verdict.reason)
##
## On a CLIENT `submit()` returns `{"ok": false, "pending": true, ...}`: the host
## has not answered yet. A refusal comes back later on `intent_refused`, which
## is the signal a consumer shows the player. A consumer must therefore not
## treat `pending` as failure -- lane 3.B's pickups optimistically hide nothing
## until the delta lands, which is also what makes a lost race look like the
## pickup simply staying put.
##
## ## Where this node lives
##
## `/root/Game/Session/LedgerRpc`, mounted by `attach()`. The node path has to be
## IDENTICAL in every process or the RPCs do not resolve at all -- the same
## reason `session.gd` is a fixed child of the one autoload rather than a second
## autoload. `attach()` is idempotent, so any consumer lane can call it without
## coordinating who mounts it first, and nothing in `game_state.gd` had to change
## to add it.
##
## D95's channels: ledger traffic rides `CHANNEL_LEDGER`, never the snapshot
## channel, so a joiner's world snapshot cannot queue behind somebody's gather.

const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")
const SESSION := preload("res://scripts/net/session.gd")
## OP-0905-18: a no-op unless the granted item is a known evolution catalyst.
## Called from `_apply_player_ops()`'s `item_grant` case, which is already
## filtered to ops addressed to THIS peer -- the announcement must not fire for
## every peer who merely sees the world flag change, only the one who actually
## received the item.
const PROGRESSION_FEED := preload("res://scripts/creatures/progression_feed.gd")

const NODE_NAME := "LedgerRpc"
const CHANNEL_LEDGER := SESSION.CHANNEL_LEDGER
const HOST_PEER_ID := SESSION.HOST_PEER_ID

## A delta was applied on THIS peer, host or client. Lane 3.B/3.C/3.E's live
## scene nodes listen for this to move a prop that a pure state object cannot
## reach -- `WorldLedger.scene_ops(delta)` is the filter they want.
signal delta_applied(delta: Dictionary)

## The host said no. `reason` is one player-facing sentence; `code` is the
## machine tag (`world_ledger.gd`'s header lists them). `detail` is the whole
## verdict, for the refusals that carry a number the loser needs -- today
## `stale_revision`, which names the `container` and the `revision` the host
## actually holds so the caller can re-quote it instead of guessing.
##
## Godot lets a handler take FEWER arguments than the signal emits, so the
## three-argument handlers written before `detail` existed keep working
## untouched; nothing has to care about a field it does not read.
signal intent_refused(kind: String, code: String, reason: String, detail: Dictionary)

var ledger: RefCounted = null


## Find or mount the transport under the session. Returns the node, or `null`
## when there is no `Game` to hang it off (a pure unit test, which should be
## talking to `WorldLedger` directly anyway).
static func attach(game: Node) -> Node:
	if game == null:
		return null
	var parent: Node = game.get("session") as Node
	if parent == null:
		parent = game
	var existing := parent.get_node_or_null(NodePath(NODE_NAME))
	if existing != null:
		return existing
	var node: Node = (load("res://scripts/net/ledger_rpc.gd") as GDScript).new()
	node.name = NODE_NAME
	parent.add_child(node)
	return node


func _ready() -> void:
	name = NODE_NAME
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_ledger()


# --- the one entry point --------------------------------------------------------

## Submit an intent. Host and solo commit it here and now; a client sends it and
## gets a pending verdict. The returned Dictionary is always
## `world_ledger.gd`'s verdict shape.
func submit(intent: Dictionary) -> Dictionary:
	_ensure_ledger()
	var game := _game()
	if ledger == null:
		return _pending(intent, false, "The world is not ready yet.")
	if game != null and not bool(game.call("is_host")):
		if not _can_rpc():
			return _pending(intent, false, "You are not connected to this world.")
		rpc_id(HOST_PEER_ID, "_rpc_intent", intent)
		return _pending(intent, true, "")
	return _commit_here(intent, _local_peer_id())


## Host-side commit + broadcast, shared by `submit()` and `_rpc_intent()` so the
## local player and a remote one are arbitrated by literally the same lines.
func _commit_here(intent: Dictionary, peer_id: int) -> Dictionary:
	var verdict: Dictionary = ledger.call("commit", intent, peer_id)
	if not bool(verdict.get("ok", false)):
		return verdict
	var delta: Dictionary = verdict.get("delta", {}) as Dictionary
	# The host's own ledger already applied the delta to `Game.world` inside
	# `commit()`; what is left here is the per-peer half and the broadcast.
	_apply_player_ops(delta)
	delta_applied.emit(delta)
	if _can_rpc() and _is_multi_peer():
		rpc("_rpc_delta", delta)
	return verdict


# --- rpc ------------------------------------------------------------------------

## Client -> host. Never trusted with a decision: the host re-validates from its
## own world, and the sender id comes from the transport, not from the payload,
## so a peer cannot claim a pickup "as" somebody else.
@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_intent(intent: Dictionary) -> void:
	var game := _game()
	if game != null and not bool(game.call("is_host")):
		return
	_ensure_ledger()
	if ledger == null:
		return
	var sender := multiplayer.get_remote_sender_id()
	var verdict := _commit_here(intent, sender)
	if not bool(verdict.get("ok", false)):
		# The whole verdict crosses, not three strings pulled out of it. A
		# refusal that carries a number the loser needs (`stale_revision`) is
		# useless if the transport flattens it on the way.
		rpc_id(sender, "_rpc_verdict", verdict)


## Host -> everyone. A committed delta. This is the only thing that changes a
## client's world; `WorldState.apply_delta()` is the only thing it changes it
## with.
@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_delta(delta: Dictionary) -> void:
	_ensure_ledger()
	if ledger == null:
		return
	ledger.call("apply", delta)
	_apply_player_ops(delta)
	_restore_progression()
	delta_applied.emit(delta)


## Host -> the one peer whose intent was refused.
@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_verdict(verdict: Dictionary) -> void:
	var code := str(verdict.get("code", ""))
	var reason := str(verdict.get("reason", ""))
	# A refusal that names a container's current revision is applied to this
	# peer's own ledger before anyone is told about it. Otherwise a joiner that
	# has never seen a write to that chest keeps quoting 0 against a host
	# holding N, and is refused for the rest of the session (lane 3.D, F2).
	if code == "stale_revision" and verdict.has("container") and verdict.has("revision"):
		_ensure_ledger()
		if ledger != null:
			ledger.call("adopt_storage_revision",
				str(verdict.get("container", "")), int(verdict.get("revision", 0)))
	intent_refused.emit(str(verdict.get("kind", "")), code, reason, verdict)
	var game := _game()
	if game != null and not reason.is_empty():
		game.call("push_world_message", reason)


# --- applying the per-peer half ---------------------------------------------------

## Player-scope ops addressed to THIS peer, against `PlayerState`. The filter is
## `WorldLedger.player_ops_for()` -- static and pure, so the unit tests ask the
## same question of the same code rather than re-deriving "did both peers get
## it" in the test file.
func _apply_player_ops(delta: Dictionary) -> void:
	var game := _game()
	if game == null:
		return
	var local: Variant = game.get("local")
	if local == null:
		return
	for raw: Variant in WORLD_LEDGER.player_ops_for(delta, _local_peer_id()):
		var op := raw as Dictionary
		match str(op.get("op", "")):
			"flag":
				var flags: Variant = (local as RefCounted).get("flags")
				if flags != null:
					(flags as RefCounted).call("set_flag", str(op.get("id", "")),
						bool(op.get("value", true)))
			"item_grant":
				var inv: Variant = (local as RefCounted).get("inventory")
				if inv != null:
					(inv as RefCounted).call("add", str(op.get("item", "")),
						int(op.get("count", 1)))
				PROGRESSION_FEED.announce_catalyst_pickup(str(op.get("item", "")))
			"item_take":
				var satchel: Variant = (local as RefCounted).get("inventory")
				if satchel != null:
					(satchel as RefCounted).call("remove", str(op.get("item", "")),
						int(op.get("count", 1)))


## The same reconciliation `apply_world_snapshot()` runs: a client whose Meadows
## is already standing has to be TOLD which pickup is gone, not merely handed the
## flag. Group-driven, so nothing here has to know which consumer lane converted
## which prop.
func _restore_progression() -> void:
	var game := _game()
	if game == null or not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("progression_restore"):
		if node.has_method("restore_progression_from_game"):
			node.call("restore_progression_from_game", game)


# --- internals --------------------------------------------------------------------

func _ensure_ledger() -> void:
	var game := _game()
	if game == null:
		return
	var world: Variant = game.get("world")
	if world == null:
		return
	if ledger == null:
		ledger = WORLD_LEDGER.new(world as RefCounted)
	elif ledger.get("world") != world:
		# `Game.reset_for_new_game()` keeps the WorldState's object identity, so
		# this only fires if something really did swap the world out from under
		# us -- and a ledger pointing at a dead world is worse than a new one.
		ledger = WORLD_LEDGER.new(world as RefCounted)


func _pending(intent: Dictionary, pending: bool, reason: String) -> Dictionary:
	return {
		"ok": false, "kind": str(intent.get("kind", "")), "peer": _local_peer_id(),
		"code": "pending" if pending else "offline", "reason": reason,
		"pending": pending, "delta": {"seq": 0, "realm": "", "ops": []},
	}


## Whether an rpc on this node can reach anybody. False solo and in every
## headless test, where `rpc()` with no peer is an error rather than a no-op.
func _can_rpc() -> bool:
	if not is_inside_tree():
		return false
	var api := multiplayer
	return api != null and api.has_multiplayer_peer()


func _is_multi_peer() -> bool:
	var game := _game()
	return game != null and bool(game.call("is_multi_peer"))


func _local_peer_id() -> int:
	var game := _game()
	if game == null:
		return HOST_PEER_ID
	var session: Variant = game.get("session")
	if session == null:
		return HOST_PEER_ID
	return int((session as Node).call("local_peer_id"))


func _game() -> Node:
	return get_node_or_null(^"/root/Game")
