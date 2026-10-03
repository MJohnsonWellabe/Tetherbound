extends Node
const BACKGROUND_TRACE := preload("res://scripts/net/background_work_trace.gd")
const ALTAR_TRACE := preload("res://scripts/net/altar_commit_trace.gd")
signal transaction_boundary(observation: Dictionary)

## Exact identity at the real writer edge, for ROOT's deterministic loss
## witnesses. This is observation only; it cannot ACK, save or grant anything.
func _observe_training_boundary(row: Dictionary, phase: String) -> void:
	transaction_boundary.emit({"phase": phase, "kind": row.kind, "action": row.action,
		"character_id": row.character_id, "world_namespace": row.world_namespace,
		"session_id": row.session_id, "delivery_id": row.delivery_id, "receipt": row.receipt,
		"journal_revision": row.journal_revision, "character_revision": row.character_revision})

func _observe_portal_boundary(row: Dictionary, phase: String, epoch: String) -> void:
	transaction_boundary.emit({"phase": phase, "kind": row.kind, "action": "portal_key",
		"character_id": row.character_id, "world_namespace": row.world_instance_id,
		"session_id": epoch, "delivery_id": row.receipt, "receipt": row.receipt,
		"biome": row.biome, "key_slot": row.key_slot})
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const WORLD_STATE := preload("res://autoload/world_state.gd")
const HOMESTEAD_BUILDING := preload("res://scripts/net/homestead_building_delivery.gd")
const ACTOR_VITALS := preload("res://scripts/net/actor_vitals_delivery.gd")

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
var _training_publications: Dictionary = {}
var _actor_vitals_publications: Dictionary = {}
var _actor_vitals_session_id := Crypto.new().generate_random_bytes(16).hex_encode()
const SATCHEL_ESCROW := preload("res://scripts/net/satchel_escrow.gd")
const REWARD_DELIVERY := preload("res://scripts/net/reward_delivery.gd")
const SATCHEL_RULES := preload("res://scripts/world/death_satchel_rules.gd")
var _satchel_retry_at: Dictionary = {}
var _satchel_poll := 0.0
var _reward_retry_at: Dictionary = {}

## Internal alpha service uses the existing host-world CAS and BOOL writer.
## No body is published by this method, and no portable reward is granted.
func commit_alpha_plan(plan: Dictionary, capture_offer: Dictionary = {}) -> Dictionary:
	_ensure_ledger()
	var game := _game()
	if game == null or game.call("is_host") != true or ledger == null or ledger.world != game.world: return {"ok": false, "durable": false}
	var world: RefCounted = game.world
	var saver: RefCounted = game.save_system
	var session: Node = game.session
	if saver == null or saver.call("fallback_busy") == true: return {"ok": false, "durable": false}
	var world_id := str(world.world_id)
	var namespace_id := str(world.reward_delivery_namespace)
	var epoch := str(session.call("_altar_current_epoch"))
	if not capture_offer.is_empty():
		if not preload("res://scripts/repeatables/alpha_respawns.gd").valid_plan(plan, world.redesign_world, namespace_id): return {"ok": false, "durable": false}
		if plan.get("operation") != "alpha_resolve" or not preload("res://scripts/net/foundation_event.gd").valid(capture_offer, namespace_id, world_id) \
			or capture_offer.session_id != epoch or capture_offer.duties.size() != 1 or capture_offer.duties[0].action != "capture_offer" \
			or capture_offer.duties[0].context.capture_traits.captured_from.spawn_id != plan.site_id \
			or capture_offer.duties[0].context.capture_traits.captured_from.spawn_generation != plan.source.generation \
			or not plan.source.region_characters.has(capture_offer.duties[0].character_id): return {"ok": false, "durable": false, "code": "alpha_capture_binding_changed"}
	game.call("_sync_clock_state")
	var before: Dictionary = world.call("save_data")
	var revision := int(world.revision)
	var sequence := int(ledger.seq)
	var result: Dictionary = ledger.call("commit_alpha_plan", plan)
	if result.get("ok") != true: return {"ok": false, "durable": false, "code": "alpha_stale_plan"}
	var offer_result: Dictionary = {}
	if not capture_offer.is_empty():
		offer_result = ledger.call("commit_foundation_event", capture_offer)
		if offer_result.get("ok") != true:
			world.call("load_data", before)
			world.revision = revision
			ledger.seq = sequence
			return {"ok": false, "durable": false, "code": "alpha_capture_offer_refused"}
	if saver.call("save_world_prepared", game, world_id) != true:
		world.call("load_data", before)
		world.revision = revision
		ledger.seq = sequence
		return {"ok": false, "durable": false, "code": "alpha_world_save_failed"}
	if game.world != world or game.save_system != saver or game.session != session \
		or str(world.world_id) != world_id or str(world.reward_delivery_namespace) != namespace_id \
		or str(session.call("_altar_current_epoch")) != epoch: return {"ok": false, "durable": false, "code": "alpha_owner_changed"}
	publish_journaled_delta(result.delta)
	if not offer_result.is_empty() and offer_result.get("duplicate") != true: publish_journaled_delta(offer_result.delta)
	return {"ok": true, "durable": true}

## Host-internal append, before personal actions/terminal source cleanup.
## A failed atomic world write restores the same ledger state and sequence.
func journal_foundation_event(source: String, duties: Array) -> Dictionary:
	_ensure_ledger()
	var game := _game()
	if game == null or game.call("is_host") != true or ledger == null: return {"ok": false, "durable": false}
	var world: RefCounted = game.get("world")
	var saver: RefCounted = game.get("save_system")
	if saver == null or saver.call("fallback_busy") == true: return {"ok": false, "durable": false}
	var row := preload("res://scripts/net/foundation_event.gd").make(world, game.get("session").call("_altar_current_epoch"), source, duties)
	if row.is_empty(): return {"ok": false, "durable": false}
	var before: Dictionary = world.call("save_data")
	var revision := int(world.revision)
	var sequence := int(ledger.seq)
	var result: Dictionary = ledger.call("commit_foundation_event", row)
	if result.get("ok") != true: return {"ok": false, "durable": false}
	if result.get("duplicate") != true:
		if saver.call("save_world_prepared", game, world.world_id) != true:
			world.call("load_data", before)
			world.revision = revision
			ledger.seq = sequence
			return {"ok": false, "durable": false}
		publish_journaled_delta(result.delta)
	return {"ok": true, "durable": true, "delivery_id": row.delivery_id}

func _process(delta: float) -> void:
	_satchel_poll -= delta
	if _satchel_poll > 0.0:
		return
	_satchel_poll = 0.5
	var trace := BACKGROUND_TRACE.begin("ledger.poll")
	var satchel_trace := BACKGROUND_TRACE.begin("ledger.reconcile_satchel")
	reconcile_satchel_escrow()
	BACKGROUND_TRACE.end("ledger.reconcile_satchel", satchel_trace)
	var rewards_trace := BACKGROUND_TRACE.begin("ledger.reconcile_rewards")
	reconcile_reward_deliveries()
	BACKGROUND_TRACE.end("ledger.reconcile_rewards", rewards_trace)
	var portals_trace := BACKGROUND_TRACE.begin("ledger.reconcile_portals")
	reconcile_portal_deliveries()
	BACKGROUND_TRACE.end("ledger.reconcile_portals", portals_trace)
	BACKGROUND_TRACE.end("ledger.poll", trace)

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
	var altar: Dictionary = _altar_building_request(intent, peer_id)
	if altar.get("intercept") == true:
		var session: Node = _game().get("session")
		if altar.get("homestead") == true:
			if session == null or not session.has_method("host_homestead_building"):
				return _pending(intent, false, "Homestead building is not ready yet.")
			return session.call("host_homestead_building", peer_id, altar.request)
		if session == null: return _pending(intent, false, "Altar building is not ready yet.")
		return session.call("host_altar_building", peer_id, altar.request)
	var satchel_transaction := kind in ["death_satchel_create", "death_satchel_transfer"]
	var durable_world_transaction := satchel_transaction or kind in ["reward_grant", "water_dock_action", "river_nest_clear", "ripplet_sunken_claim"]
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
	if kind == "ripplet_sunken_claim":
		intent = intent.duplicate(true)
		intent["_ripplet_actor"] = {}
		var root := get_tree().current_scene
		var service := root.get_node_or_null("RippletWaterService") if root != null else null
		if service == null:
			for node: Node in get_tree().get_nodes_in_group("ripplet_water_service"):
				service = node
				break
		if service != null: intent["_ripplet_actor"] = service.actor_context(peer_id, str(intent.get("creature_uid", "")))
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
		if kind in ["reward_grant", "water_dock_action", "river_nest_clear", "ripplet_sunken_claim"] or not world_id.is_empty():
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
				if kind == "ripplet_sunken_claim": failure_reason = "The sunken find could not save. Nothing was claimed."
				return {"ok": false, "pending": false, "kind": str(intent.kind), "peer": peer_id,
					"code": "journal_failed", "reason": failure_reason,
					"world_instance_id": SATCHEL_ESCROW.world_instance(ledger.world),
					"txn_id": str(intent.get("txn_id", "")), "uid": str(intent.get("uid", "")), "delta": {"ops": []}}
	# A host recipient can durably ACK while its player op is applied. Publish
	# the pending journal first so its later acceptance delta cannot overtake it
	# on the same reliable ledger channel.
	if kind in ["reward_grant", "river_nest_clear", "ripplet_sunken_claim"]:
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
## Internal host door only, never a packet intent. WorldState application is
## pure; no delta publication or portable save occurs inside this prepared CAS.
func journal_actor_vitals_prepared(peer_id: int, character: String, accepted: Dictionary) -> Dictionary:
	var game := _game()
	if game == null or not bool(game.call("is_host")) or ledger == null \
			or ledger.get("world") != game.get("world") or character.is_empty() \
			or character != _registered_character(peer_id):
		return {"ok": false, "code": "not_admitted", "durable": false}
	var world: RefCounted = game.get("world")
	var saver: RefCounted = game.get("save_system")
	var world_namespace := str(world.get("reward_delivery_namespace"))
	var world_id := str(world.get("world_id"))
	if saver == null or not saver.has_method("save_world_prepared") \
			or bool(saver.call("fallback_busy")) or world_namespace.is_empty() or world_id.is_empty():
		return {"ok": false, "code": "world_not_prepared", "durable": false}
	var id := ACTOR_VITALS.delivery_id(world_namespace, character, str(accepted.get("uid", "")))
	var row := ACTOR_VITALS.next_record(world_id, world_namespace, _actor_vitals_session_id,
		character, str(accepted.get("uid", "")), float(accepted.get("max_hp", -1.0)),
		float(accepted.get("expected_hp", -1.0)), bool(accepted.get("expected_fainted", false)),
		float(accepted.get("hp", -1.0)), bool(accepted.get("fainted", false)),
		int(accepted.get("character_revision", -1)), accepted.get("receipt", {}),
		world.get("reward_deliveries").get(id))
	if row.is_empty():
		return {"ok": false, "code": "invalid_vitals_journal", "durable": false}
	var before: Dictionary = world.call("save_data")
	var before_revision := int(world.get("revision"))
	var before_seq := int(ledger.get("seq"))
	var verdict: Dictionary = ledger.call("commit_actor_vitals_delivery", row, peer_id)
	if not bool(verdict.get("ok", false)):
		return verdict
	if not bool(saver.call("save_world_prepared", game, world_id)):
		world.call("load_data", before)
		world.set("revision", before_revision)
		ledger.set("seq", before_seq)
		return {"ok": false, "code": "journal_failed", "durable": false}
	# Only this detached publication token is transient. The absolute row is
	# already in the existing durable world document and remains recovery truth.
	_actor_vitals_publications[id] = {"peer": peer_id, "row": row.duplicate(true),
		"delta": verdict.delta.duplicate(true)}
	return {"ok": true, "durable": true, "delivery_id": id,
		"journal_revision": row.journal_revision, "receipt": row.receipt.duplicate(true)}


## The exact actor is committed before this door. Losing this call or a
## disconnect never refunds accepted HP: reconcile the existing durable row.
func publish_actor_vitals(peer_id: int, character: String, uid: String, receipt: Dictionary) -> bool:
	var game := _game()
	if game == null or not bool(game.call("is_host")) or ledger == null \
			or character.is_empty() or character != _registered_character(peer_id):
		return false
	var world: RefCounted = game.get("world")
	var id := ACTOR_VITALS.delivery_id(str(world.get("reward_delivery_namespace")), character, uid)
	var pending: Variant = _actor_vitals_publications.get(id)
	var latest: Variant = world.get("reward_deliveries").get(id)
	if not pending is Dictionary or int(pending.peer) != peer_id \
			or not ACTOR_VITALS.valid(latest, character, str(world.get("reward_delivery_namespace"))) \
			or not ACTOR_VITALS.equivalent(latest, pending.row) \
			or not ACTOR_VITALS.equivalent(latest.receipt, receipt):
		return false
	_actor_vitals_publications.erase(id)
	publish_journaled_delta(pending.delta)
	return true


func _process_actor_vitals(delivery: Dictionary) -> void:
	var game := _game()
	if game == null or not _character_writes_ready() \
			or str(game.get("local").character_id) != str(delivery.get("character_id", "")):
		return
	var result := ACTOR_VITALS.apply_owner(game, delivery)
	if not bool(result.get("ok", false)):
		return # Exact world journal stays pending; real bool-save retries later.
	if bool(game.call("is_host")):
		_accept_actor_vitals(str(delivery.delivery_id), int(delivery.journal_revision), delivery.receipt, _local_peer_id())
	elif _can_rpc():
		rpc_id(HOST_PEER_ID, "_rpc_actor_vitals_ack", str(delivery.delivery_id), int(delivery.journal_revision), delivery.receipt)


## The fully validated snapshot is applied, but readiness/final snapshot ACK
## remain closed until each pending owned absolute value actually saves. This
## explicit receipt path does not enable ordinary pre-handshake autosaves.
func reconcile_actor_vitals_before_ready() -> bool:
	var game := _game()
	if game == null or game.get("local") == null or game.get("world") == null:
		return false
	var character := str(game.get("local").character_id)
	if character.is_empty():
		return false
	var world: RefCounted = game.get("world")
	for raw: Variant in world.get("reward_deliveries").values():
		if not raw is Dictionary or raw.get("kind") != "actor_vitals" \
				or raw.get("character_id") != character or raw.get("status") != "pending":
			continue
		var result := ACTOR_VITALS.apply_owner(game, raw)
		if not bool(result.get("ok", false)):
			return false
		if bool(game.call("is_host")):
			if not _accept_actor_vitals(str(raw.delivery_id), int(raw.journal_revision), raw.receipt, _local_peer_id()):
				return false
		elif _can_rpc():
			if rpc_id(HOST_PEER_ID, "_rpc_actor_vitals_ack", str(raw.delivery_id), int(raw.journal_revision), raw.receipt) != OK:
				return false
		else:
			return false
	return true


@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_actor_vitals_ack(id: String, revision: int, receipt: Dictionary) -> void:
	var game := _game()
	if game != null and bool(game.call("is_host")):
		_accept_actor_vitals(id, revision, receipt, multiplayer.get_remote_sender_id())


func _accept_actor_vitals(id: String, revision: int, receipt: Dictionary, peer_id: int) -> bool:
	var game := _game()
	if game == null or not bool(game.call("is_host")) or ledger == null:
		return false
	var world: RefCounted = game.get("world")
	var character := _registered_character(peer_id)
	# valid(..., owner="") intentionally means shape-only elsewhere. An ACK
	# transport must never use that optional argument as admitted ownership.
	if character.is_empty():
		return false
	var row: Variant = world.get("reward_deliveries").get(id)
	if not row is Dictionary or row.get("character_id") != character \
			or not ACTOR_VITALS.valid(row, character, str(world.get("reward_delivery_namespace"))) \
			or not ACTOR_VITALS.equivalent(row.journal_revision, revision) \
			or not ACTOR_VITALS.equivalent(row.receipt, receipt):
		return false
	if row.status == "accepted":
		return true # Existing accepted world write is the durable duplicate proof.
	var saver: RefCounted = game.get("save_system")
	if saver == null or not saver.has_method("save_world_prepared") or bool(saver.call("fallback_busy")):
		return false
	var before: Dictionary = world.call("save_data")
	var before_revision := int(world.get("revision"))
	var before_seq := int(ledger.get("seq"))
	var verdict: Dictionary = ledger.call("accept_actor_vitals_delivery", id, character, revision, receipt, peer_id)
	if not bool(verdict.get("ok", false)):
		return false
	if not bool(saver.call("save_world_prepared", game, str(world.get("world_id")))):
		world.call("load_data", before)
		world.set("revision", before_revision)
		ledger.set("seq", before_seq)
		return false
	var session: Node = game.get("session")
	if session == null or not bool(session.call("host_ack_creature_vitals", peer_id,
		str(row.creature_uid), int(row.character_revision), receipt)):
		return false # Accepted world row remains authoritative recovery truth.
	publish_journaled_delta(verdict.delta)
	return true


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
	var flag_game := _game()
	if flag_game != null and flag_game.get("session") != null: flag_game.get("session").call("foundation_record_personal_flags", delta)
	var game := _game()
	if game == null:
		return
	var local: Variant = game.get("local")
	if local == null:
		return
	for raw: Variant in WORLD_LEDGER.player_ops_for(delta, _local_peer_id()):
		var op := raw as Dictionary
		match str(op.get("op", "")):
			"creature_training_settle":
				if op.get("delivery") is Dictionary:
					call_deferred("_process_creature_training", op.delivery.duplicate(true))
			"actor_vitals_settle":
				if op.get("delivery") is Dictionary:
					_process_actor_vitals(op.delivery)
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
	for raw: Variant in game.get("world").reward_deliveries.values():
		if raw is Dictionary and raw.get("kind") in ["creature_training", "altar_building"] and raw.get("character_id") == character_id:
			_process_creature_training(raw)
		if raw is Dictionary and raw.get("kind") == "actor_vitals" and raw.get("status") == "pending":
			_process_actor_vitals(raw)
	for delivery: Dictionary in REWARD_DELIVERY.pending_for_character(game.get("world"), character_id):
		if not delivery.get("kind") in ["actor_vitals", "creature_training", "altar_building", "portal_unlock"]:
			_process_reward_delivery(delivery)
	# Once accepted, the portable character escrow remains the source of truth
	# until a full bag has room, including while visiting another world.
	for raw: Variant in game.get("local").satchel_escrow.values():
		if raw is Dictionary and str(raw.get("kind", "")) == "reward_delivery" \
				and str(raw.get("status", "")) == "grant_due":
			_process_reward_delivery(raw as Dictionary)


func _owner_training_blocks_character_write(game: Node) -> bool:
	if game == null or not game.get("local") is RefCounted: return true
	var session: Variant = game.get("session")
	if not session is Node or not session.has_method("_owner_training_mutation_blocked"): return true
	var blocked: Variant = session.call("_owner_training_mutation_blocked", game.get("local"))
	return not blocked is bool or blocked


func _process_reward_delivery(delivery: Dictionary) -> void:
	if _owner_training_blocks_character_write(_game()): return # Existing durable reward row retries after settlement.
	if delivery.get("kind") == "creature_training" or str(delivery.get("delivery_id", "")).begins_with("creature_training:"):
		return # Typed revision/receipt ACK only, never ordinary reward escrow.
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


## Internal prepared transaction. No owner save, delta signal or RPC during
## the hidden registry stage. Same WorldLedger and atomic WorldSave as vitals.
func journal_creature_training_prepared(peer: int, character: String, accepted: Dictionary) -> Dictionary:
	var game := _game()
	if game == null or not bool(game.call("is_host")) or ledger == null \
			or ledger.get("world") != game.get("world") or character.is_empty() \
			or character != _registered_character(peer) or accepted.get("character_id") != character:
		return {"ok": false, "durable": false, "code": "not_admitted"}
	var world: RefCounted = game.get("world")
	var saver: RefCounted = game.get("save_system")
	if saver == null or not saver.has_method("save_world_prepared") or saver.call("fallback_busy") == true:
		return {"ok": false, "durable": false, "code": "world_not_prepared"}
	var id := ESSENCE.training_delivery_id(world.reward_delivery_namespace, character)
	var row: Dictionary
	if accepted.get("action") in preload("res://scripts/net/character_action_rules.gd").ACTIONS or accepted.get("action") in preload("res://scripts/net/foundation_actions.gd").ACTIONS:
		# No candidate from an intent/RPC can enter this arm. The same hidden
		# registry's private token must still bind its exact accepted stage.
		var owner_session: Node = game.get("session")
		if owner_session == null or owner_session.call("character_action_stage_matches", peer, accepted) != true:
			return {"ok": false, "durable": false, "code": "action_stage_changed"}
		var codec: Script = preload("res://scripts/net/foundation_delivery.gd") if accepted.get("action") in preload("res://scripts/net/foundation_actions.gd").ACTIONS else preload("res://scripts/net/character_action_delivery.gd")
		row = codec.make_record(
			world.world_id, world.reward_delivery_namespace, str(owner_session.call("foundation_event_stage_epoch", accepted)),
			accepted, world.reward_deliveries.get(id), preload("res://scripts/net/character_record_rules.gd").errors)
	else:
		row = ESSENCE.next_training_delivery(world.world_id, world.reward_delivery_namespace,
			_actor_vitals_session_id, accepted, world.reward_deliveries.get(id), ESSENCE.config(),
			PROGRESSION.config(), TEACHING.available_moves, TEACHING.character_loadout_mirror)
	if row.is_empty() or not WORLD_STATE.training_row_valid(row, world.reward_delivery_namespace, world.world_id):
		return {"ok": false, "durable": false, "code": "invalid_training_journal"}
	var session: Node=game.get("session")
	if session==null or session.call("training_actor_baseline_ready",peer,row)!=true: return {"ok":false,"code":"training_actor_baseline_not_ready"}
	var before: Dictionary = world.call("save_data")
	var before_revision := int(world.get("revision"))
	var before_seq := int(ledger.get("seq"))
	var verdict: Dictionary = ledger.call("commit_creature_training_delivery", row, peer)
	if verdict.get("ok") != true: return verdict
	if saver.call("save_world_prepared", game, world.world_id) != true:
		world.call("load_data", before)
		world.set("revision", before_revision)
		ledger.set("seq", before_seq)
		return {"ok": false, "durable": false, "code": "training_journal_failed"}
	_training_publications[id] = {"peer": peer, "row": row.duplicate(true), "delta": verdict.delta.duplicate(true)}
	return {"ok": true, "durable": true, "delivery_id": id, "journal_revision": row.journal_revision}


func publish_creature_training(peer: int, character: String, receipt: String) -> bool:
	var game := _game()
	if game == null or not bool(game.call("is_host")) or character.is_empty() \
			or character != _registered_character(peer): return false
	var world: RefCounted = game.get("world")
	var id := ESSENCE.training_delivery_id(world.reward_delivery_namespace, character)
	var pending: Dictionary = _training_publications.get(id, {})
	var latest: Variant = world.reward_deliveries.get(id)
	if pending.is_empty() or pending.peer != peer or not WORLD_STATE.training_row_valid(latest,
		world.reward_delivery_namespace, world.world_id) or latest.receipt != receipt \
		or not ESSENCE._equivalent(latest, pending.row): return false
	_observe_training_boundary(latest, "after_host_write_before_delivery")
	# Observers may interrupt a process; never publish a replaced decision.
	if not ESSENCE._equivalent(world.reward_deliveries.get(id), latest): return false
	_training_publications.erase(id)
	publish_journaled_delta(pending.delta)
	return true


func _process_creature_training(row: Dictionary) -> void:
	var game := _game()
	if game == null or game.get("local") == null or game.get("world") == null: return
	var session: Node = game.get("session")
	var world: RefCounted = game.get("world")
	var player: RefCounted = game.get("local")
	if session == null or not WORLD_STATE.training_row_valid(row, world.reward_delivery_namespace, world.world_id) \
			or row.character_id != player.get("character_id") \
			or not ESSENCE._equivalent(world.reward_deliveries.get(row.delivery_id), row): return
	if row.status == "accepted":
		if bool(game.call("is_host")):
			_accept_creature_training(row.delivery_id, int(row.journal_revision), row.receipt, _local_peer_id())
		else:
			session.call("_settle_owner_training_accepted", player, world, row)
		return
	# Bootstrap installs the real world before this arm. It intentionally does
	# not require handshake_snapshot_applied, which waits on this owner save.
	if session.call("_altar_current_epoch") == "": return
	var outcome: Dictionary
	if row.kind == "altar_building": outcome = session.call("apply_altar_building_owner", row)
	elif preload("res://scripts/net/character_record_rules.gd").training_version(row) in [2, 3]: outcome = preload("res://scripts/net/character_action_owner.gd").apply_owner(game, row)
	else: outcome = ESSENCE.apply_training_owner(game, row, TEACHING.available_moves, TEACHING.character_loadout_mirror)
	if outcome.get("ok") != true or outcome.get("saved") != true: return
	_observe_training_boundary(row, "after_owner_write_before_ack")
	if not ESSENCE._equivalent(world.reward_deliveries.get(row.delivery_id), row): return
	if bool(game.call("is_host")):
		_accept_creature_training(row.delivery_id, int(row.journal_revision), row.receipt, _local_peer_id())
	elif _can_rpc():
		rpc_id(HOST_PEER_ID, "_rpc_creature_training_ack", str(session.call("_altar_current_epoch")),
			row.delivery_id, int(row.journal_revision), row.receipt)


@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_creature_training_ack(epoch: String, id: String, revision: int, receipt: String) -> void:
	var game := _game()
	if game == null or not bool(game.call("is_host")): return
	var session: Node = game.get("session")
	if session == null or epoch != session.call("_altar_current_epoch"): return
	_accept_creature_training(id, revision, receipt, multiplayer.get_remote_sender_id())


func _accept_creature_training(id: String, revision: int, receipt: String, peer: int) -> bool:
	var game := _game()
	if game == null or not bool(game.call("is_host")) or ledger == null: return false
	var character := _registered_character(peer)
	var world: RefCounted = game.get("world")
	var row: Variant = world.reward_deliveries.get(id)
	if character.is_empty() or not WORLD_STATE.training_row_valid(row, world.reward_delivery_namespace, world.world_id) \
			or row.character_id != character or row.receipt != receipt or int(row.journal_revision) != revision: return false
	var session: Node = game.get("session")
	if row.status == "accepted":
		if session == null or session.call("host_ack_creature_training", peer, row) != true: return false
		_publish_training_acceptance(peer, row)
		session.call("_deliver_training_decision", peer, row)
		return true
	var saver: RefCounted = game.get("save_system")
	if saver == null or saver.call("fallback_busy") == true: return false
	if session == null or session.call("training_actor_baseline_ready",peer,row)!=true: return false
	var before: Dictionary = world.call("save_data")
	var before_revision := int(world.get("revision"))
	var before_seq := int(ledger.get("seq"))
	var verdict: Dictionary = ledger.call("accept_creature_training_delivery", id, character, revision, receipt, peer)
	if verdict.get("ok") != true: return false
	if saver.call("save_world_prepared", game, world.world_id) != true:
		world.call("load_data", before)
		world.set("revision", before_revision)
		ledger.set("seq", before_seq)
		return false
	var accepted: Dictionary = world.reward_deliveries[id].duplicate(true)
	# Keep publication identity in the existing transient delivery queue if
	# actor handoff fails. The saved row remains the sole recovery truth.
	_training_publications[id] = {"peer": peer, "row": accepted.duplicate(true), "delta": verdict.delta.duplicate(true)}
	# Only the saved accepted row unlocks authority. A lost result is recoverable
	# from this same row, never from a boolean the client claimed in an intent.
	if session == null or session.call("host_ack_creature_training", peer, accepted) != true: return false
	_publish_training_acceptance(peer, accepted)
	session.call("_deliver_training_decision", peer, accepted)
	return true


func reconcile_creature_training_before_ready() -> bool:
	var game := _game()
	if game == null or game.get("local") == null or game.get("world") == null: return false
	var world: RefCounted = game.get("world")
	var character := str(game.get("local").character_id)
	var row: Dictionary = WORLD_STATE.training_owner_row(world.reward_deliveries, world.reward_delivery_namespace, world.world_id, character)
	if row.is_empty():
		for raw: Variant in world.reward_deliveries.values():
			if raw is Dictionary and raw.get("character_id") == character and raw.get("kind") in ["creature_training", "altar_building"]: return false
		return true
	var id: String = row.delivery_id
	_process_creature_training(row)
	# A pending world row keeps admission/readiness shut until both bool writes
	# are accepted. Session resumes its existing bootstrap on accepted response.
	row = game.get("world").reward_deliveries.get(id)
	return row is Dictionary and row.status == "accepted" \
		and game.get("local").redesign_character.transaction_receipts.has(row.receipt) \
		and not _owner_training_blocks_character_write(game)


## Only called after private actor handoff and registry ACK. A process restart
## needs no transient delta: its validated bootstrap carries the accepted row.
func _publish_training_acceptance(peer: int, row: Dictionary) -> void:
	var pending: Dictionary = _training_publications.get(row.delivery_id, {})
	if pending.is_empty(): return
	if pending.get("peer") != peer or not ESSENCE._equivalent(pending.get("row"), row) \
		or row.get("status") != "accepted": return
	_training_publications.erase(row.delivery_id)
	publish_journaled_delta(pending.delta)


## Only the Altar subset of existing building ingress is intercepted. An
## index or a forged paid flag cannot fall through to legacy free placement.
func _altar_building_request(intent: Dictionary, peer: int) -> Dictionary:
	var kind := str(intent.get("kind", ""))
	var character := _registered_character(peer)
	if kind == "place_building" and intent.get("id") == "altar":
		var allowed := ["kind", "realm", "id", "position", "yaw_deg", "paid", "txn_id", "available_materials"]
		for key: Variant in intent:
			if not allowed.has(key): return {"intercept": true, "request": {}}
		if intent.has("available_materials") and (not intent.available_materials is Dictionary or not intent.available_materials.is_empty()):
			return {"intercept": true, "request": {}}
		var request := intent.duplicate(true)
		request.erase("available_materials")
		return {"intercept": true, "request": request}
	# F31: every gated homestead station/attachment uses the same paid journal
	# with a version-2 record. A legacy free placement is never reachable.
	if kind == "place_building" and HOMESTEAD_BUILDING.requires_journal(intent.get("id")):
		for key: Variant in intent:
			if not HOMESTEAD_BUILDING.PLACE_REQUEST_FIELDS.has(key) and key != "available_materials":
				return {"intercept": true, "homestead": true, "request": {}}
		if intent.has("available_materials") and (not intent.available_materials is Dictionary or not intent.available_materials.is_empty()):
			return {"intercept": true, "homestead": true, "request": {}}
		var homestead_request := intent.duplicate(true)
		homestead_request.erase("available_materials")
		return {"intercept": true, "homestead": true, "request": homestead_request}
	if kind != "dismantle": return {}
	var world: RefCounted = ledger.world
	var uid := str(intent.get("uid", ""))
	var index := int(world.call("building_index_of", uid)) if not uid.is_empty() else -1
	if index < 0 and intent.get("index") is int: index = int(intent.index)
	var target_is_altar: bool = index >= 0 and index < world.placed_buildings.size() \
		and world.placed_buildings[index].get("id") == "altar"
	var target_is_homestead: bool = index >= 0 and index < world.placed_buildings.size() \
		and world.placed_buildings[index] is Dictionary \
		and (HOMESTEAD_BUILDING.requires_journal(world.placed_buildings[index].get("id")) \
			or HOMESTEAD_BUILDING.record_valid(world.placed_buildings[index]))
	var id := WORLD_STATE.altar_build_id(world.reward_delivery_namespace, character, str(intent.get("txn_id", "")))
	var frozen: Variant = world.reward_deliveries.get(id)
	var frozen_building: bool = frozen is Dictionary and frozen.get("kind") == "altar_building"
	if not target_is_altar and not target_is_homestead and not frozen_building: return {}
	# A retried txn follows its frozen row's own version; otherwise the target.
	var homestead: bool = HOMESTEAD_BUILDING.row_valid(frozen, world.reward_delivery_namespace, world.world_id) \
		if frozen_building else target_is_homestead
	for key: Variant in intent:
		if not ["kind", "realm", "uid", "index", "txn_id"].has(key): return {"intercept": true, "homestead": homestead, "request": {}}
	var request := intent.duplicate(true)
	request.erase("index") # Never authoritative; UID is required by the typed door.
	return {"intercept": true, "homestead": homestead, "request": request}


func journal_altar_building_prepared(peer: int, stage: Dictionary, request: Dictionary) -> Dictionary:
	var game := _game()
	var session: Node = game.get("session") if game != null else null
	var character := _registered_character(peer)
	if game == null or not bool(game.call("is_host")) or session == null or ledger == null \
		or ledger.world != game.get("world") or character.is_empty() or stage.get("character_id") != character:
		return {"ok": false, "durable": false, "code": "not_admitted"}
	var authority: RefCounted = session.get("_character_authority")
	if authority == null or not ESSENCE._equivalent(authority.call("staged_creature_training", stage), stage):
		return {"ok": false, "durable": false, "code": "stale_building_stage"}
	var world: RefCounted = game.get("world")
	var saver: RefCounted = game.get("save_system")
	if saver == null or saver.call("fallback_busy") == true or not saver.has_method("save_world_prepared"):
		return {"ok": false, "durable": false, "code": "world_not_prepared"}
	var id := WORLD_STATE.altar_build_id(world.reward_delivery_namespace, character, stage.action_id)
	var cfg := ESSENCE.config()
	if world.reward_deliveries.has(id) or not ESSENCE._integer(cfg.get("maximum_transaction_receipts"), 1, 65536):
		return {"ok": false, "durable": false, "code": "building_receipt_conflict"}
	var building_rows := 0
	for raw: Variant in world.reward_deliveries.values():
		if raw is Dictionary and raw.get("kind") == "altar_building": building_rows += 1
	if building_rows >= int(cfg.maximum_transaction_receipts): return {"ok": false, "durable": false, "code": "building_receipt_budget"}
	# Version 2 only for a canonical F31 Homestead record; Altar rows stay v1.
	var row := {"version": HOMESTEAD_BUILDING.VERSION if HOMESTEAD_BUILDING.record_valid(stage.record) else 1,
		"kind": "altar_building", "delivery_id": id,
		"world_id": world.world_id, "world_namespace": world.reward_delivery_namespace,
		"session_id": _actor_vitals_session_id, "character_id": character,
		"action": stage.action, "action_id": stage.action_id,
		"intent": {"request": request.duplicate(true), "record": stage.record.duplicate(true), "cost": stage.cost.duplicate(true)},
		"before": ESSENCE.training_projection(stage.before), "after": ESSENCE.training_projection(stage.state),
		"receipt": stage.receipt, "character_revision": stage.character_revision, "journal_revision": 1, "status": "pending"}
	if not WORLD_STATE.altar_build_row_valid(row, world.reward_delivery_namespace, world.world_id):
		return {"ok": false, "durable": false, "code": "invalid_building_journal"}
	var before: Dictionary = world.call("save_data")
	var before_revision := int(world.revision)
	var before_seq := int(ledger.seq)
	var before_seen: Dictionary = ledger.get("_seen_txns").duplicate(true)
	var verdict: Dictionary = ledger.call("commit_altar_building", row, peer)
	if verdict.get("ok") != true: return verdict
	# Applied journal and building op must BOTH match before the atomic writer.
	var building_index := int(world.call("building_index_of", stage.record.uid))
	var placed_ok := building_index >= 0 and ESSENCE._equivalent(world.placed_buildings[building_index], stage.record)
	var save_trace := ALTAR_TRACE.begin("journal.prepared_world_write")
	if not ESSENCE._equivalent(world.reward_deliveries.get(id), row) \
		or (stage.action == "place_building" and not placed_ok) \
		or (stage.action == "dismantle" and building_index >= 0) \
		or saver.call("save_world_prepared", game, world.world_id) != true:
		ALTAR_TRACE.end("journal.prepared_world_write", save_trace, "guard_or_bool_refused")
		world.call("load_data", before)
		world.set("revision", before_revision)
		ledger.set("seq", before_seq)
		ledger.set("_seen_txns", before_seen)
		return {"ok": false, "durable": false, "code": "building_journal_failed"}
	ALTAR_TRACE.end("journal.prepared_world_write", save_trace, "saved")
	var retain_trace := ALTAR_TRACE.begin("journal.retain_publication")
	_training_publications[id] = {"peer": peer, "row": row.duplicate(true), "delta": verdict.delta.duplicate(true)}
	ALTAR_TRACE.end("journal.retain_publication", retain_trace)
	return {"ok": true, "durable": true, "delivery_id": id, "verdict": verdict}


func publish_altar_building(peer: int, character: String, id: String, receipt: String) -> bool:
	var identity_trace := ALTAR_TRACE.begin("publish.identity")
	var game := _game()
	if game == null or not bool(game.call("is_host")) or character.is_empty() \
		or _registered_character(peer) != character:
		ALTAR_TRACE.end("publish.identity", identity_trace, "refused")
		return false
	ALTAR_TRACE.end("publish.identity", identity_trace)
	var world: RefCounted = game.get("world")
	var row: Variant = world.reward_deliveries.get(id)
	var saved: Dictionary = _training_publications.get(id, {})
	var validate_trace := ALTAR_TRACE.begin("publish.canonical_row")
	if not WORLD_STATE.altar_build_row_valid(row, world.reward_delivery_namespace, world.world_id) \
		or row.character_id != character or row.receipt != receipt or saved.get("peer") != peer \
		or not ESSENCE._equivalent(saved.get("row"), row):
		ALTAR_TRACE.end("publish.canonical_row", validate_trace, "refused")
		return false
	ALTAR_TRACE.end("publish.canonical_row", validate_trace)
	var boundary_trace := ALTAR_TRACE.begin("publish.host_boundary_callbacks")
	_observe_training_boundary(row, "after_host_write_before_delivery")
	ALTAR_TRACE.end("publish.host_boundary_callbacks", boundary_trace)
	# Observe only the real saved boundary; never publish a changed decision.
	var original_trace := ALTAR_TRACE.begin("publish.original_row_recheck")
	if not ESSENCE._equivalent(world.reward_deliveries.get(id), saved.row):
		ALTAR_TRACE.end("publish.original_row_recheck", original_trace, "refused")
		return false
	ALTAR_TRACE.end("publish.original_row_recheck", original_trace)
	_training_publications.erase(id)
	var delivery_trace := ALTAR_TRACE.begin("publish.original_delta_delivery")
	publish_journaled_delta(saved.delta)
	ALTAR_TRACE.end("publish.original_delta_delivery", delivery_trace)
	return true


const PORTAL_DELIVERY := preload("res://scripts/net/portal_delivery.gd")
var _portal_publications: Dictionary = {}
var _portal_retry_at: Dictionary = {}


## Save the same host carrier BEFORE an owner sees a debit. Caller must have
## staged the corresponding admitted registry CAS and flushed fallback first.
func journal_portal_delivery_prepared(peer: int, character: String, biome: String, slot: int) -> Dictionary:
	_ensure_ledger()
	var game := _game()
	if game == null or not bool(game.call("is_host")) or character != _registered_character(peer):
		return {"ok": false, "durable": false, "code": "not_admitted"}
	var world: RefCounted = game.get("world")
	var saver: RefCounted = game.get("save_system")
	if world == null or saver == null or saver.call("fallback_busy") == true: return {"ok": false, "code": "world_not_prepared"}
	var row := PORTAL_DELIVERY.row(world, character, biome, slot)
	if row.is_empty(): return {"ok": false, "code": "invalid_portal_row"}
	var prior: Variant = world.reward_deliveries.get(row.receipt)
	if prior != null:
		if not PORTAL_DELIVERY.valid(prior, character, world.reward_delivery_namespace): return {"ok": false, "code": "invalid_prior_portal"}
		return {"ok": true, "durable": true, "duplicate": true, "row": prior.duplicate(true)}
	var before: Dictionary = world.save_data()
	var revision := int(world.revision)
	var sequence := int(ledger.seq)
	var verdict: Dictionary = ledger.call("commit_portal_delivery", row, peer)
	if verdict.get("ok") != true: return verdict
	if saver.call("save_world_prepared", game, world.world_id) != true:
		world.load_data(before)
		world.revision = revision
		ledger.seq = sequence
		return {"ok": false, "durable": false, "code": "portal_world_save_failed"}
	_portal_publications[row.receipt] = {"peer": peer, "character": character, "delta": verdict.delta.duplicate(true)}
	return {"ok": true, "durable": true, "duplicate": false, "row": row.duplicate(true)}


func publish_portal_delivery(peer: int, character: String, receipt: String) -> bool:
	var game := _game()
	if game == null or not bool(game.call("is_host")) or character != _registered_character(peer): return false
	var world: RefCounted = game.get("world")
	var row: Variant = world.reward_deliveries.get(receipt)
	if not PORTAL_DELIVERY.valid(row, character, world.reward_delivery_namespace): return false
	_observe_portal_boundary(row, "after_host_write_before_delivery", str(game.get("session").call("_altar_current_epoch")))
	if not PORTAL_DELIVERY.equivalent(world.reward_deliveries.get(receipt), row): return false
	var publication: Dictionary = _portal_publications.get(receipt, {})
	if not publication.is_empty():
		if publication.peer != peer or publication.character != character: return false
		_portal_publications.erase(receipt)
		publish_journaled_delta(publication.delta)
	if peer == _local_peer_id():
		_process_portal_delivery(row.duplicate(true))
	elif _can_rpc():
		rpc_id(peer, "_rpc_portal_delivery", str(game.get("session").call("_altar_current_epoch")), row.duplicate(true))
	return true


@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_portal_delivery(generation: String, row: Dictionary) -> void:
	var game := _game()
	if game == null or generation.is_empty() or not _character_writes_ready(): return
	var session: Node = game.get("session")
	if session == null or generation != session.call("_altar_current_epoch"): return
	# The row must already exist in the authoritative delta/snapshot. A packet
	# cannot replace its frozen item, world, character, biome or debit slot.
	var world: RefCounted = game.get("world")
	var canonical: Variant = world.reward_deliveries.get(row.get("receipt"))
	if not PORTAL_DELIVERY.equivalent(canonical, row): return
	_process_portal_delivery(row, generation)


func _process_portal_delivery(row: Dictionary, generation: String = "") -> void:
	var game := _game()
	if game == null or not _character_writes_ready(): return
	var session: Node = game.get("session")
	if session == null: return
	var current_generation := str(session.call("_altar_current_epoch"))
	if bool(game.call("is_host")) and generation.is_empty(): generation = current_generation
	if generation.is_empty() or generation != current_generation: return
	var world: RefCounted = game.get("world")
	var player: RefCounted = game.get("local")
	if world == null or player == null or not PORTAL_DELIVERY.valid(row, player.character_id, world.reward_delivery_namespace): return
	if row.status == "accepted": return
	var canonical: Variant = world.reward_deliveries.get(row.receipt)
	if not PORTAL_DELIVERY.equivalent(canonical, row): return
	var result := PORTAL_DELIVERY.settle_owner(game, row.duplicate(true))
	if result.get("ok") != true: return
	_observe_portal_boundary(row, "after_owner_write_before_ack", current_generation)
	if game.get("world") != world or game.get("local") != player or session.call("_altar_current_epoch") != current_generation \
		or not PORTAL_DELIVERY.equivalent(world.reward_deliveries.get(row.receipt), row): return
	var now := Time.get_ticks_msec()
	if now < int(_portal_retry_at.get(row.receipt, 0)): return
	_portal_retry_at[row.receipt] = now + 1000
	var echo := row.duplicate(true)
	if bool(game.call("is_host")):
		_accept_portal_delivery(echo, _local_peer_id(), current_generation)
	elif _can_rpc() and not generation.is_empty():
		rpc_id(HOST_PEER_ID, "_rpc_portal_delivery_ack", generation, echo)


@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_portal_delivery_ack(generation: String, row: Dictionary) -> void:
	var game := _game()
	if game != null and bool(game.call("is_host")):
		_accept_portal_delivery(row, multiplayer.get_remote_sender_id(), generation)


func _accept_portal_delivery(echo: Dictionary, peer: int, generation: String) -> bool:
	_ensure_ledger()
	var game := _game()
	if game == null or not bool(game.call("is_host")) or game.get("session") == null or generation != game.get("session").call("_altar_current_epoch"): return false
	var character := _registered_character(peer)
	var world: RefCounted = game.get("world")
	if character.is_empty() or world == null or not PORTAL_DELIVERY.valid(echo, character, world.reward_delivery_namespace): return false
	var prior: Variant = world.reward_deliveries.get(echo.receipt)
	if not PORTAL_DELIVERY.valid(prior, character, world.reward_delivery_namespace): return false
	var expected: Dictionary = prior.duplicate(true)
	expected.status = "pending"
	if not PORTAL_DELIVERY.equivalent(echo, expected): return false
	if prior.status == "accepted":
		_publish_portal_acceptance(peer, prior)
		return true
	var saver: RefCounted = game.get("save_system")
	if saver == null or saver.call("fallback_busy") == true: return false
	var before: Dictionary = world.save_data()
	var revision := int(world.revision)
	var sequence := int(ledger.seq)
	var accepted: Dictionary = prior.duplicate(true)
	accepted.status = "accepted"
	var verdict: Dictionary = ledger.call("accept_portal_delivery", accepted, peer)
	if verdict.get("ok") != true: return false
	if saver.call("save_world_prepared", game, world.world_id) != true:
		world.load_data(before)
		world.revision = revision
		ledger.seq = sequence
		return false
	publish_journaled_delta(verdict.delta)
	_publish_portal_acceptance(peer, accepted)
	return true


func _publish_portal_acceptance(peer: int, row: Dictionary) -> void:
	var game := _game()
	var session: Node = game.get("session") if game != null else null
	if session != null: session.call("_portal_delivery_accepted", peer, row.duplicate(true))


func reconcile_portal_deliveries() -> void:
	var game := _game()
	if game == null or not _character_writes_ready(): return
	var world: RefCounted = game.get("world")
	if world == null: return
	for row: Variant in world.reward_deliveries.values():
		if not row is Dictionary or row.get("kind") != PORTAL_DELIVERY.KIND: continue
		if not PORTAL_DELIVERY.valid(row, "", world.reward_delivery_namespace): continue
		if bool(game.call("is_host")):
			var session: Node = game.get("session")
			if session == null: continue
			# Offline solo has no peer registry entry. Bind the same actual local
			# character explicitly, then handle only the remote roster below.
			if row.character_id == game.get("local").character_id:
				if row.status == "pending": publish_portal_delivery(_local_peer_id(), row.character_id, row.receipt)
				elif row.status == "accepted": _publish_portal_acceptance(_local_peer_id(), row)
			for peer: int in session.call("registry").peer_ids():
				if peer == _local_peer_id(): continue
				if _registered_character(peer) == row.character_id:
					if row.status == "pending": publish_portal_delivery(peer, row.character_id, row.receipt)
					elif row.status == "accepted": _publish_portal_acceptance(peer, row)
		elif row.character_id == game.get("local").character_id and row.status == "pending":
			# Host retries the bound epoch packet; a snapshot alone cannot invent
			# a current sender-generation ACK. Owner durability may recover now.
			_process_portal_delivery(row)


func journal_opening_home_key_prepared(peer: int, source: Node) -> Dictionary:
	_ensure_ledger()
	var game := _game()
	if game == null or not bool(game.call("is_host")) or source == null or peer != _local_peer_id(): return {"durable": false}
	var session: Node = game.get("session")
	var world: RefCounted = game.get("world")
	var player: RefCounted = game.get("local")
	var saver: RefCounted = game.get("save_system")
	if session == null or session.call("portal_runtime_ready") != true or world == null or player == null or saver == null or saver.call("fallback_busy") == true: return {"durable": false}
	if source.get("_f18_opening_conversation_id") != "grandpa_first_catch" or game.call("original_starter_uid") == "" or _registered_character(peer) != player.character_id: return {"durable": false}
	var row := REWARD_DELIVERY.make_record(world.world_id, world.reward_delivery_namespace, "home_key:grant:" + player.character_id, player.character_id, "home_key", 1, "home_key_given")
	if row.is_empty(): return {"durable": false}
	var prior: Variant = world.reward_deliveries.get(row.delivery_id)
	if prior is Dictionary:
		if prior.character_id != player.character_id or prior.source != row.source or prior.get("stacks") != row.stacks: return {"durable": false}
		_process_reward_delivery(prior.duplicate(true))
		return {"durable": true, "duplicate": true}
	var before: Dictionary = world.save_data()
	var revision := int(world.revision)
	var sequence := int(ledger.seq)
	var verdict: Dictionary = ledger.call("_commit", [{"op": "reward_delivery_journal", "scope": "world", "realm": "meadows", "delivery_id": row.delivery_id, "delivery": row}], "opening_home_key", peer, "meadows")
	if verdict.get("ok") != true: return {"durable": false}
	if saver.call("save_world_prepared", game, world.world_id) != true:
		world.load_data(before)
		world.revision = revision
		ledger.seq = sequence
		return {"durable": false}
	publish_journaled_delta(verdict.delta)
	_process_reward_delivery(row)
	return {"durable": true, "duplicate": false}
