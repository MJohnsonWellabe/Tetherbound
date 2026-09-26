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
const SATCHEL_ESCROW := preload("res://scripts/net/satchel_escrow.gd")
const REWARD_DELIVERY := preload("res://scripts/net/reward_delivery.gd")
const SATCHEL_RULES := preload("res://scripts/world/death_satchel_rules.gd")
var _satchel_retry_at: Dictionary = {}
var _satchel_poll := 0.0
var _reward_retry_at: Dictionary = {}

func _process(delta: float) -> void:
	_satchel_poll -= delta
	if _satchel_poll > 0.0:
		return
	_satchel_poll = 0.5
	reconcile_satchel_escrow()
	reconcile_reward_deliveries()

func drop_satchel(at: Vector3, realm: String) -> Dictionary:
	var game := _game()
	var txn := SATCHEL_ESCROW.begin_drop(game.get("local"), game.get("world"), at, realm, bool(game.call("is_host")))
	return _submit_satchel_escrow(txn)

func transfer_satchel(uid: String, direction: String, item: String, count: int, expected: int = -1) -> Dictionary:
	_ensure_ledger()
	var game := _game()
	if expected < 0:
		expected = ledger.storage_revision("satchel:" + uid)
	var txn := SATCHEL_ESCROW.begin_transfer(game.get("local"), game.get("world"), uid, direction, item, count, expected, bool(game.call("is_host")))
	return _submit_satchel_escrow(txn)

func _persist_satchel_character() -> bool:
	var game := _game()
	# Legacy session-less fixtures have no split-save identity. Real named
	# characters journal escrow before sending an irreversible host request.
	if str(game.get("local").character_id).is_empty() or str(game.get("world").world_id).is_empty():
		return true
	var saver: RefCounted = game.get("save_system")
	return saver != null and bool(saver.call("save_character", game, str(game.get("local").character_id)))

func _submit_satchel_escrow(txn: String) -> Dictionary:
	var game := _game()
	if txn.is_empty() or not game.get("local").satchel_escrow.has(txn):
		return {"ok": false, "pending": false, "reason": "Those items will not fit, or a satchel move is already pending."}
	var row: Dictionary = game.get("local").satchel_escrow[txn]
	if not SATCHEL_ESCROW.intent_matches(row, game.get("local"), game.get("world")):
		var legacy := SATCHEL_ESCROW.is_legacy_unresolved(row, game.get("local"))
		return {"ok": false, "pending": true,
			"code": "legacy_unresolved" if legacy else "wrong_world",
			"reason": "This older pending satchel move needs its original world's receipt." \
				if legacy else "That pending satchel move belongs to a different world."}
	if not _persist_satchel_character():
		return {"ok": false, "pending": true, "reason": "Your pending satchel move is waiting for the character save."}
	_satchel_retry_at[txn] = Time.get_ticks_msec() + 3000
	var verdict := submit(row.intent)
	if not verdict.get("ok", false) and not verdict.get("pending", false):
		_handle_satchel_verdict(verdict)
	return verdict

func _settle_satchel_receipts() -> void:
	var game := _game()
	var changed := false
	if game != null:
		changed = SATCHEL_ESCROW.reconcile(game.get("local"), game.get("world"))
	if game != null:
		for row: Variant in game.get("local").satchel_escrow.values():
			if not row is Dictionary:
				continue
			if SATCHEL_ESCROW.is_personal_outcome(row, game.get("local")) \
					and not bool(row.get("room_message_shown", false)):
				game.call("push_world_message", "Your recovered items are safe. Make room in your satchel to receive them.")
				row["room_message_shown"] = true
				changed = true
			elif SATCHEL_ESCROW.is_legacy_unresolved(row, game.get("local")) \
					and not bool(row.get("unresolved_message_shown", false)):
				game.call("push_world_message",
					"An older pending satchel move needs its original world's receipt before it can be resolved.")
				row["unresolved_message_shown"] = true
				changed = true
	if changed:
		_persist_satchel_character()

func _accept_satchel_recovery(verdict: Dictionary) -> bool:
	var snapshot: Variant = verdict.get("satchel_recovery_snapshot")
	var game := _game()
	if game == null:
		return false
	var txn := str(verdict.get("txn_id", ""))
	var row: Variant = game.get("local").satchel_escrow.get(txn)
	if not row is Dictionary or not _satchel_verdict_matches(verdict, row as Dictionary, game):
		return false
	if not snapshot is Dictionary or not snapshot.get("world") is Dictionary:
		return false
	var snapshot_world := snapshot.get("world") as Dictionary
	var snapshot_instance: Variant = snapshot_world.get("reward_delivery_namespace", null)
	if typeof(snapshot_instance) != TYPE_STRING \
			or snapshot_instance != verdict.get("world_instance_id"):
		return false
	if snapshot is Dictionary and not bool(game.call("is_host")) and int(snapshot.get("seq", -1)) >= int(ledger.seq):
		game.call("apply_world_snapshot", snapshot_world)
		ledger.seq = int(snapshot.seq)
	_settle_satchel_receipts()
	return true


func _satchel_verdict_matches(verdict: Dictionary, row: Dictionary, game: Node) -> bool:
	var verdict_instance: Variant = verdict.get("world_instance_id", null)
	return SATCHEL_ESCROW.belongs(row, game.get("local"), game.get("world")) \
		and typeof(verdict_instance) == TYPE_STRING \
		and not (verdict_instance as String).is_empty() \
		and verdict_instance == SATCHEL_ESCROW.row_instance(row) \
		and verdict_instance == SATCHEL_ESCROW.world_instance(game.get("world"))


func _handle_satchel_verdict(verdict: Dictionary) -> bool:
	var game := _game()
	if game == null:
		return false
	var txn := str(verdict.get("txn_id", ""))
	var row: Variant = game.get("local").satchel_escrow.get(txn)
	if not row is Dictionary:
		return false
	# A stale request can reach a host after the client changed worlds. Never
	# turn that host's refusal into a refund of items possibly committed elsewhere.
	if str(verdict.get("code", "")) == "wrong_world" \
			or not _satchel_verdict_matches(verdict, row as Dictionary, game):
		_settle_satchel_receipts()
		return false
	var changed := _accept_satchel_recovery(verdict) \
		if str(verdict.get("code", "")) == "duplicate" \
		else SATCHEL_ESCROW.refuse(game.get("local"), game.get("world"), txn)
	if changed:
		_persist_satchel_character()
	return changed

func reconcile_satchel_escrow() -> void:
	var game := _game()
	# This transport is process-always and can outlive/reset ahead of Game's
	# per-world state. Unit runners also mount it without constructing a world.
	# Escrow has nothing to reconcile until both halves exist.
	if game == null or game.get("local") == null or game.get("world") == null:
		return
	var session: Node = game.get("session")
	if session != null and session.has_method("snapshot_ready") and not bool(session.call("snapshot_ready")):
		return
	_settle_satchel_receipts()
	for key: Variant in game.get("local").satchel_escrow.keys():
		var row: Variant = game.get("local").satchel_escrow[key]
		if not row is Dictionary or not SATCHEL_ESCROW.belongs(row, game.get("local"), game.get("world")) or str(row.get("status", "")) != "pending":
			continue
		if not row.get("intent") is Dictionary or str(row.intent.get("realm", "")) != str(game.get("current_realm")):
			continue
		if not bool(row.get("origin_host", false)) and (session == null or not session.has_method("is_active") or not bool(session.call("is_active"))):
			continue
		if Time.get_ticks_msec() >= int(_satchel_retry_at.get(str(key), 0)):
			_submit_satchel_escrow(str(key))


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
	# Fixed under the persistent ledger on every peer, including hosts playing
	# another realm while their Water simulation shell arbitrates Aquaryn.
	var alpha_transport := preload("res://scripts/net/water_alpha_transport.gd").new()
	alpha_transport.name = "WaterAlphaTransport"
	add_child(alpha_transport)
	var veilfall_transport := preload("res://scripts/net/water_veilfall_transport.gd").new()
	veilfall_transport.name = "WaterVeilfallTransport"
	add_child(veilfall_transport)
	var capture_claims := preload("res://scripts/net/water_capture_claims.gd").new()
	capture_claims.name = "WaterCaptureClaims"
	add_child(capture_claims)


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
	var kind := str(intent.get("kind", ""))
	var satchel_transaction := kind in ["death_satchel_create", "death_satchel_transfer"]
	var durable_world_transaction := satchel_transaction or kind in ["reward_grant", "water_dock_action", "river_nest_clear"]
	var before_satchel: Dictionary = {}
	if durable_world_transaction:
		before_satchel = {"world": ledger.world.save_data(), "seq": ledger.seq,
			"world_revision": int(ledger.world.get("revision")),
			"revisions": ledger.get("_storage_revisions").duplicate(true), "seen": ledger.get("_seen_txns").duplicate(true)}
	if satchel_transaction:
		intent = intent.duplicate(true)
		intent["_satchel_actor"] = _water_actor_context(peer_id, intent)
	if kind == "reward_grant":
		intent = intent.duplicate(true)
		intent["world_id"] = str(ledger.world.get("world_id"))
		intent["_reward_recipients"] = _reward_recipients(intent, peer_id)
		# A guest's grant is judged against the host's own view of where that
		# guest stands (world_ledger.gd `client_grant_refusal`), never a position
		# or realm the request carries.
		if peer_id != WORLD_LEDGER.HOST_PEER:
			intent["_reward_actor"] = _water_actor_context(peer_id, {})
	if str(intent.get("kind", "")) in ["water_dock_action", "water_personal_pickup"]:
		intent = intent.duplicate(true)
		# Never accept actor identity, realm or position from the request. The
		# host resolves its local rig or the sender's owned trainer proxy.
		intent["_water_actor"] = _water_actor_context(peer_id, intent)
	if kind == "river_nest_clear":
		intent = intent.duplicate(true)
		intent["_doss_actor"] = _water_actor_context(peer_id, intent)
	# Every kind can write world flags, so every intent carries the admitted
	# identity; a claimed `_actor_character_id` is always overwritten.
	intent = with_host_actor(intent, _registered_character(peer_id))
	var verdict: Dictionary = ledger.call("commit", intent, peer_id)
	if satchel_transaction:
		var host_instance: Variant = ledger.world.get("reward_delivery_namespace")
		verdict["world_instance_id"] = host_instance as String \
			if typeof(host_instance) == TYPE_STRING else ""
		verdict["txn_id"] = str(intent.get("txn_id", ""))
		verdict["uid"] = str(intent.get("uid", ""))
		if str(verdict.get("code", "")) == "duplicate":
			# A lost acknowledgement is a reconciliation, never a refund. The
			# host sends its current durable snapshot, so the client can recover
			# the receipt even when the original creation/transfer delta was lost.
			verdict["satchel_recovery_snapshot"] = {"seq": ledger.seq, "world": ledger.world.save_data()}
	if not bool(verdict.get("ok", false)):
		return verdict
	var delta: Dictionary = verdict.get("delta", {}) as Dictionary
	if durable_world_transaction:
		var satchel_game := _game()
		var world_id := str(satchel_game.get("world").world_id)
		# Reward and dock publication always require a durable world file. Death-
		# satchel fixtures historically allow an unnamed session, so preserve only
		# that legacy path.
		if kind in ["reward_grant", "water_dock_action", "river_nest_clear"] or not world_id.is_empty():
			var saver: RefCounted = satchel_game.get("save_system")
			if saver == null or not bool(saver.call("save_world", satchel_game, world_id)):
				# No personal settlement or publication happened yet. Roll back
				# the synchronous in-memory commit as one unit, including receipt
				# bookkeeping, so a later retry cannot mistake it for durable work.
				ledger.world.load_data(before_satchel.world)
				ledger.world.set("revision", int(before_satchel.world_revision))
				ledger.seq = before_satchel.seq
				ledger.set("_storage_revisions", before_satchel.revisions)
				ledger.set("_seen_txns", before_satchel.seen)
				var failure_reason := "The world could not save this reward. Nothing was delivered." \
					if kind == "reward_grant" else (
						"The world could not save this dock change. Nothing was changed." \
						if kind == "water_dock_action" else (
							"The world could not save Doss's repair. Your items remain safe." \
							if kind == "river_nest_clear" else "The world could not save this satchel move. Your items remain safe."))
				return {"ok": false, "pending": false, "kind": str(intent.kind), "peer": peer_id,
					"code": "journal_failed", "reason": failure_reason,
					"world_instance_id": SATCHEL_ESCROW.world_instance(ledger.world),
					"txn_id": str(intent.get("txn_id", "")), "uid": str(intent.get("uid", "")), "delta": {"ops": []}}
	# A host recipient can durably ACK while its player op is applied. Publish
	# the pending journal first so its later acceptance delta cannot overtake it
	# on the same reliable ledger channel.
	if kind in ["reward_grant", "river_nest_clear"]:
		delta_applied.emit(delta)
		if _can_rpc() and _is_multi_peer():
			rpc("_rpc_delta", delta)
		_apply_player_ops(delta)
		_settle_satchel_receipts()
	else:
		_apply_player_ops(delta)
		_settle_satchel_receipts()
		delta_applied.emit(delta)
		if _can_rpc() and _is_multi_peer():
			rpc("_rpc_delta", delta)
	return verdict


func _reward_recipients(intent: Dictionary, requesting_peer: int) -> Array:
	var requested: Array = []
	var raw: Variant = intent.get("peers")
	if requesting_peer != WORLD_LEDGER.HOST_PEER:
		# A guest may only ever ask for its OWN reward. Whatever `peers`/`peer`
		# it names, the host pays the sender and nobody else, so a client can
		# neither push a grant onto another character nor spend their claim.
		requested.append(requesting_peer)
	elif raw is Array:
		for entry: Variant in raw:
			var id := int(entry)
			if id > 0 and not requested.has(id):
				requested.append(id)
	elif intent.has("peer"):
		requested.append(int(intent.get("peer", requesting_peer)))
	else:
		requested.append(requesting_peer)
	var game := _game()
	var session: Variant = game.get("session") if game != null else null
	var registry: Variant = session.call("registry") if session != null and session.has_method("registry") else null
	var out: Array = []
	for target: int in requested:
		var character_id := ""
		if registry != null:
			var row: Dictionary = (registry as RefCounted).call("row", target)
			character_id = str(row.get("character_id", ""))
		if character_id.is_empty() and target == _local_peer_id() and game != null:
			character_id = str(game.get("local").character_id)
		if not character_id.is_empty():
			out.append({"peer": target, "character_id": character_id})
	return out


## A copy of `intent` whose actor identity is the host's answer, whatever the
## request claimed.
static func with_host_actor(intent: Dictionary, character_id: String) -> Dictionary:
	var out := intent.duplicate(true)
	out["_actor_character_id"] = character_id
	return out


## The stable character id the session admitted for `peer_id`, or "".
static func registered_character(peer_id: int, local_peer_id: int,
		local_character_id: String, roster: Object) -> String:
	if peer_id == local_peer_id:
		return local_character_id
	if roster == null or not roster.has_method("row"):
		return ""
	return str((roster.call("row", peer_id) as Dictionary).get("character_id", ""))


func _registered_character(peer_id: int) -> String:
	var game := _game()
	if game == null:
		return ""
	var local: Variant = game.get("local")
	var local_character := str(local.get("character_id")) if local is Object else ""
	var session: Variant = game.get("session")
	var roster: Variant = (session as Object).call("registry") \
		if session is Object and (session as Object).has_method("registry") else null
	return registered_character(peer_id, _local_peer_id(), local_character,
		roster as Object if roster is Object else null)


func _water_actor_context(peer_id: int, intent: Dictionary) -> Dictionary:
	var game := _game()
	if game == null:
		return {}
	var actor: Node3D
	var realm := ""
	var character := ""
	if peer_id == _local_peer_id():
		actor = game.call("_find_player") as Node3D
		realm = str(game.get("current_realm"))
		character = str(game.get("local").character_id)
	else:
		for proxy: Node in get_tree().get_nodes_in_group("remote_trainer"):
			if proxy.get_multiplayer_authority() == peer_id:
				actor = proxy as Node3D
				realm = str(proxy.get("net_realm"))
				character = str(proxy.get("character_id"))
				break
	if actor == null:
		return {}
	var context := {"peer": peer_id, "character_id": character, "realm": realm,
		"position": actor.global_position,
		"personal_claimed": intent.get("personal_claimed", false) == true,
		"inventory": intent.get("inventory", {}) if intent.get("inventory", {}) is Dictionary else {},
		"inventory_slots": intent.get("inventory_slots", []) if intent.get("inventory_slots", []) is Array else []}
	if str(intent.get("kind", "")) == "water_personal_pickup" and get_tree().current_scene != null:
		var service := get_tree().current_scene.get_node_or_null("WaterPickups")
		if service != null and service.has_method("node_for"):
			var pickup: Node3D = service.call("node_for", str(intent.get("pickup_id", "")))
			if pickup != null:
				context["pickup_position"] = pickup.global_position
	return context


## A realm authority has already committed and durably journaled these ops.
## Keep publication identical to ordinary ledger commits, including local
## player application. Never exposed as a remotely callable commit shortcut.
func publish_journaled_delta(delta: Dictionary) -> void:
	if not bool(_game().call("is_host")) or delta.get("ops", []).is_empty():
		return
	_apply_player_ops(delta)
	delta_applied.emit(delta)
	if _can_rpc() and _is_multi_peer():
		rpc("_rpc_delta", delta)


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
	# Only admitted session members may ask. A transport peer that is still in
	# its handshake, or lingering after a refusal or kick so its reason can be
	# delivered, is not a player in this world.
	var session: Variant = game.get("session") if game != null else null
	if session is Object and (session as Object).has_method("registry") \
			and bool((session as Object).call("is_active")):
		var roster: Variant = (session as Object).call("registry")
		if roster is Object and not bool((roster as Object).call("has", sender)):
			return
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
	var game := _game()
	var session: Variant = game.get("session") if game != null else null
	# Session owns the chunked-snapshot boundary. A true return means this
	# delta arrived after that boundary and must wait until the baseline world
	# is installed; applying even its player ops early would expose a joining
	# character before the handshake is complete. Sessions without the new seam
	# (and pre-boundary traffic) return false and retain the established path.
	if session is Object and (session as Object).has_method("queue_bootstrap_delta") \
			and bool((session as Object).call("queue_bootstrap_delta", delta)):
		return
	apply_remote_delta(delta)


## Session replays accepted bootstrap deltas through this same entry after it
## installs the snapshot, before it raises `snapshot_ready()`. Keeping the
## actual mutation path here preserves ledger sequence, player-op, scene and
## receipt behavior for ordinary and replayed deltas alike.
func apply_remote_delta(delta: Dictionary) -> void:
	_ensure_ledger()
	if ledger == null:
		return
	ledger.call("apply", delta)
	_apply_player_ops(delta)
	_settle_satchel_receipts()
	_restore_progression()
	delta_applied.emit(delta)


## Host -> the one peer whose intent was refused.
@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_verdict(verdict: Dictionary) -> void:
	var satchel_verdict := str(verdict.get("kind", "")) in ["death_satchel_create", "death_satchel_transfer"]
	var satchel_applied := true
	if satchel_verdict:
		satchel_applied = _handle_satchel_verdict(verdict)
	var code := str(verdict.get("code", ""))
	var reason := str(verdict.get("reason", ""))
	# A refusal that names a container's current revision is applied to this
	# peer's own ledger before anyone is told about it. Otherwise a joiner that
	# has never seen a write to that chest keeps quoting 0 against a host
	# holding N, and is refused for the rest of the session (lane 3.D, F2).
	if code == "stale_revision" and (not satchel_verdict or satchel_applied) \
			and verdict.has("container") and verdict.has("revision"):
		_ensure_ledger()
		if ledger != null:
			ledger.call("adopt_storage_revision",
				str(verdict.get("container", "")), int(verdict.get("revision", 0)))
	intent_refused.emit(str(verdict.get("kind", "")), code, reason, verdict)
	var game := _game()
	if game != null and not reason.is_empty():
		game.call("push_world_message", reason)


## Character durability is the acknowledgement boundary. The host trusts only
## the sender's registry row, never a character id supplied in the packet.
@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_reward_delivery_ack(delivery_id: String) -> void:
	var game := _game()
	if game == null or not bool(game.call("is_host")):
		return
	_accept_reward_delivery(delivery_id, multiplayer.get_remote_sender_id())


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
			"reward_delivery":
				var delivery: Variant = op.get("delivery", {})
				if delivery is Dictionary and _character_writes_ready():
					_process_reward_delivery(delivery as Dictionary)
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


func _character_writes_ready() -> bool:
	var game := _game()
	if game == null:
		return false
	var session: Variant = game.get("session")
	if session == null or not session.has_method("is_active") or not bool(session.call("is_active")):
		return true
	if session.has_method("mode") and str(session.call("mode")) == "client":
		return session.has_method("handshake_snapshot_applied") \
			and bool(session.call("handshake_snapshot_applied"))
	return true


func reconcile_reward_deliveries() -> void:
	var game := _game()
	if game == null or game.get("local") == null or game.get("world") == null \
			or not _character_writes_ready():
		return
	var character_id := str(game.get("local").character_id)
	if character_id.is_empty():
		return
	# A reconnect learns pending host receipts from the admitted world snapshot.
	for delivery: Dictionary in REWARD_DELIVERY.pending_for_character(game.get("world"), character_id):
		_process_reward_delivery(delivery)
	# Once accepted, the portable character escrow remains the source of truth
	# until a full bag has room, including while visiting another world.
	for raw: Variant in game.get("local").satchel_escrow.values():
		if raw is Dictionary and str(raw.get("kind", "")) == "reward_delivery" \
				and str(raw.get("status", "")) == "grant_due":
			_process_reward_delivery(raw as Dictionary)


func _process_reward_delivery(delivery: Dictionary) -> void:
	var game := _game()
	if game == null or not _character_writes_ready():
		return
	var player: RefCounted = game.get("local")
	var id := str(delivery.get("delivery_id", ""))
	if id.is_empty() or str(delivery.get("character_id", "")) != str(player.get("character_id")):
		return
	var before_slots := SATCHEL_RULES.slots(player.get("inventory"))
	var flags: RefCounted = player.get("flags")
	var before_flags: Dictionary = flags.call("save_data") if flags != null else {}
	var before_escrow: Dictionary = player.get("satchel_escrow").duplicate(true)
	var outcome: Dictionary = REWARD_DELIVERY.apply(player, delivery)
	if not bool(outcome.get("ok", false)):
		return
	var row: Dictionary = player.get("satchel_escrow").get(id, {})
	var show_room_message := false
	if not bool(outcome.get("settled", false)) and not bool(row.get("room_message_shown", false)):
		row["room_message_shown"] = true
		outcome["changed"] = true
		show_room_message = true
	if bool(outcome.get("changed", false)) and not _persist_reward_character(game):
		SATCHEL_ESCROW.apply_slots(player.get("inventory"), before_slots)
		if flags != null:
			flags.call("load_data", before_flags)
		player.set("satchel_escrow", before_escrow)
		return
	if show_room_message:
		game.call("push_world_message", "Your earned reward is safe. Make room in your satchel to receive it.")
	if bool(outcome.get("settled", false)) and bool(outcome.get("changed", false)):
		for stack: Variant in delivery.get("stacks", []):
			if stack is Dictionary:
				PROGRESSION_FEED.announce_catalyst_pickup(str((stack as Dictionary).get("id", "")))
	_ack_reward_delivery(id)


func _persist_reward_character(game: Node) -> bool:
	var character_id := str(game.get("local").character_id)
	if character_id.is_empty():
		return false
	var saver: RefCounted = game.get("save_system")
	return saver != null and bool(saver.call("save_character", game, character_id))


func _ack_reward_delivery(delivery_id: String) -> void:
	var game := _game()
	if game == null:
		return
	var current: Variant = game.get("world").reward_deliveries.get(delivery_id)
	if not current is Dictionary or str((current as Dictionary).get("status", "")) != "pending":
		return
	var now := Time.get_ticks_msec()
	if now < int(_reward_retry_at.get(delivery_id, 0)):
		return
	_reward_retry_at[delivery_id] = now + 3000
	if bool(game.call("is_host")):
		_accept_reward_delivery(delivery_id, _local_peer_id())
	elif _can_rpc():
		rpc_id(HOST_PEER_ID, "_rpc_reward_delivery_ack", delivery_id)


func _accept_reward_delivery(delivery_id: String, sender_peer: int) -> bool:
	var game := _game()
	if game == null:
		return false
	var session: Variant = game.get("session")
	var registry: Variant = session.call("registry") if session != null and session.has_method("registry") else null
	var character_id := ""
	if registry != null:
		var registry_row: Dictionary = (registry as RefCounted).call("row", sender_peer)
		character_id = str(registry_row.get("character_id", ""))
	if character_id.is_empty() and sender_peer == _local_peer_id():
		character_id = str(game.get("local").character_id)
	var deliveries: Dictionary = game.get("world").reward_deliveries
	var raw: Variant = deliveries.get(delivery_id)
	if character_id.is_empty() or not raw is Dictionary \
			or str((raw as Dictionary).get("character_id", "")) != character_id:
		return false
	var before_world: Dictionary = game.get("world").save_data()
	var before_revision := int(game.get("world").revision)
	var before_seq := int(ledger.seq)
	var verdict: Dictionary = ledger.call("accept_reward_delivery", delivery_id, character_id, sender_peer)
	if not bool(verdict.get("ok", false)):
		return false
	var delta: Dictionary = verdict.get("delta", {})
	if (delta.get("ops", []) as Array).is_empty():
		return true
	var saver: RefCounted = game.get("save_system")
	if saver == null or not bool(saver.call("save_world", game, str(game.get("world").world_id))):
		game.get("world").load_data(before_world)
		game.get("world").revision = before_revision
		ledger.seq = before_seq
		return false
	publish_journaled_delta(delta)
	return true


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
