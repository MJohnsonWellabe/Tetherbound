extends Node

## Finite, client-only receiver replacement. The host's normal travel is not
## rewritten here. Pins/interlocks cover these short transactions, never fights.
const SCOPE := preload("res://scripts/net/realm_replication_scope.gd")
const HISTORY := preload("res://scripts/net/realm_receiver_history.gd")
const ORIGINS := preload("res://scripts/net/realm_spawn_origins.gd")
const TIMEOUT_MS := 120000
var scopes: Array[Node] = []
var transactions: Dictionary = {}
var history := HISTORY.new()
var origins := ORIGINS.new()
var retired_receivers: Dictionary:
	get:
		return history.denied
	set(value):
		history.denied = value
var epoch := 1
var _serial := 0
var _local: Dictionary = {}
var _host_move: Array[String] = []
var _pending: Array[Dictionary] = []
var _awaiting_install: Dictionary = {}
var _joining: Dictionary = {}
var _policy_revision := 0

func _ready() -> void:
	name = "RealmTransition"
	process_mode = Node.PROCESS_MODE_ALWAYS

func session() -> Node:
	return get_parent()

func active() -> bool:
	return bool(session().call("is_active"))

func host() -> bool:
	return bool(session().call("is_host"))

func me() -> int:
	return int(session().call("local_peer_id"))

func register_scope(scope: Node) -> void:
	if not scopes.has(scope):
		scopes.append(scope)
		scope.connect("inventory_changed", _check_local_drain)

func unregister_scope(scope: Node) -> void:
	scopes.erase(scope)

func reset() -> void:
	epoch += 1
	transactions.clear()
	history.reset()
	origins.reset()
	_pending.clear()
	_awaiting_install.clear()
	_joining.clear()
	_policy_revision += 1
	_host_move.clear()
	# Old awaiters capture epoch and fail without keeping a refusal that would
	# poison the next session's first request.
	_local.clear()

func context_valid(captured_epoch: int) -> bool:
	return epoch == captured_epoch and active()

## Read-only failure receipt. Counts distinguish installation, sender-fence
## quorum and actual receiver inventory without weakening any of those gates.
func diagnostic_state() -> Dictionary:
	var rounds: Array = []
	for token: String in transactions:
		var tx: Dictionary = transactions[token]
		var acks: Dictionary = tx.get("acks", {})
		var missing: Array[String] = []
		if host():
			for sender: int in tx.peers:
				for receiver: int in tx.peers:
					if sender == receiver:
						continue
					for channel: int in [0, 1]:
						var key := "%d:%d:%d" % [sender, receiver, channel]
						if not acks.has(key):
							missing.append(key)
		rounds.append({"token": token, "phase": tx.phase, "round": tx.round,
			"peers": tx.peers, "installed": (tx.get("installed", {}) as Dictionary).keys(),
			"fences_started": tx.get("fences_started", false), "acks": acks.size(),
			"missing_fences": missing, "receiver_ready": tx.get("receiver_ready", false)})
	var inventory: Array = []
	for scope: Node in scopes:
		if is_instance_valid(scope):
			inventory.append({"path": str(scope.get_path()), "realm": scope.get("realm"),
				"received": scope.call("received_count"), "bodies": (scope.call("bodies") as Array).size(),
				"unsupported": scope.call("unsupported_bodies")})
	return {"active": active(), "host": host(), "process_enabled": is_processing(),
		"can_process": can_process(), "epoch": epoch, "local": _local.duplicate(true),
		"pending": _pending.duplicate(true), "awaiting_install": _awaiting_install.duplicate(true),
		"rounds": rounds, "inventory": inventory}

func _peers() -> Array[int]:
	var result: Array[int] = []
	for row: Dictionary in session().call("peers"):
		result.append(int(row.peer_id))
	return result

func _overlaps(from: String, to: String) -> bool:
	if _host_move.has(from) or _host_move.has(to):
		return true
	for tx: Dictionary in transactions.values():
		if from in [str(tx.from), str(tx.to)] or to in [str(tx.from), str(tx.to)]:
			return true
	return false

func begin_host(from: String, to: String) -> bool:
	var captured := epoch
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	while active() and _overlaps(from, to):
		if Time.get_ticks_msec() >= deadline:
			return false
		await get_tree().process_frame
		if not context_valid(captured):
			return false
	if not context_valid(captured):
		return false
	_host_move.assign([from, to])
	return true

func end_host() -> void:
	_host_move.clear()

func begin_client(from: String, to: String) -> bool:
	if not active() or host() or not _local.is_empty():
		return false
	if not _prepare_inventory(from):
		return false
	_serial += 1
	var request := _serial
	var captured := epoch
	_local = {"request": request, "phase": "waiting", "from": from, "to": to}
	_request.rpc_id(1, request, to)
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	while context_valid(captured) and str(_local.get("phase", "")) != "loading":
		if _local.has("error") or Time.get_ticks_msec() >= deadline:
			# A refusal received before a grant has no scene traffic to unwind.
			if str(_local.get("phase", "")) == "cancelled":
				_local["begin_outcome"] = "aborted" if _local.has("token") else "refused"
				return false
			_local["settling"] = true
			_cancel_request.rpc_id(1, request, captured, str(_local.get("token", "")))
			var settlement_deadline := Time.get_ticks_msec() + TIMEOUT_MS
			while context_valid(captured) and int(_local.get("request", -1)) == request \
					and not _local.has("begin_outcome"):
				if Time.get_ticks_msec() >= settlement_deadline:
					_local["begin_outcome"] = "settlement_timeout"
					break
				await get_tree().process_frame
			return false
		await get_tree().process_frame
	if context_valid(captured) and _local.has("error"):
		_local["begin_outcome"] = "recovery_required"
	return context_valid(captured) and not _local.has("error") and str(_local.get("phase", "")) == "loading"

func begin_failure_outcome() -> String:
	return str(_local.get("begin_outcome", "refused"))

func finish_client(realm: String) -> bool:
	if _local.is_empty() or not active():
		return false
	var captured := epoch
	var token := str(_local.get("token", ""))
	_receiver_ready.rpc_id(1, token, realm)
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	while context_valid(captured) and str(_local.get("phase", "")) != "done":
		if _local.has("error") or Time.get_ticks_msec() >= deadline:
			return false
		await get_tree().process_frame
	var success := context_valid(captured) and str(_local.get("phase", "")) == "done"
	if success:
		_local.clear()
	return success

func owns_announcement(from: String, to: String) -> bool:
	if _local.is_empty() or not active() or host():
		return false
	if to != str(_local.get("to", "")):
		if not prepare_rollback(to):
			return true # Never fall through to uncoordinated detach/announcement.
		_retarget.rpc_id(1, str(_local.get("token", "")), to)
		_local["to"] = to
	return true

func prepare_rollback(realm: String) -> bool:
	var token := str(_local.get("token", ""))
	if not active() or host() or token.is_empty() or not transactions.has(token) \
			or realm != str(_local.get("from", "")) or str(_local.get("phase", "")) != "loading":
		return false
	# Only this still-unadmitted transaction may reopen its readiness attempt.
	# Receiver and origin denials remain until matching successful readiness.
	_local.erase("error")
	return true

func clear_local() -> void:
	if begin_failure_outcome() == "settlement_timeout":
		return # Retain identity/gates until explicit session reset or recovery.
	if str(_local.get("phase", "")) in ["done", "cancelled", "waiting"]:
		_local.clear()

@rpc("any_peer", "call_remote", "reliable", 0)
func _request(request: int, to: String) -> void:
	if not host():
		return
	var peer := multiplayer.get_remote_sender_id()
	if peer <= 1 or not _peers().has(peer):
		return
	var from := str(session().call("realm_of", peer))
	var game := get_node_or_null("/root/Game")
	var hearts: Variant = game.get("realm_hearts") if game != null else null
	if from.is_empty() or from == to or hearts == null or str(hearts.call("scene_for_realm", to)).is_empty():
		_refused.rpc_id(peer, request, "invalid_realm")
		return
	if not _prepare_inventory(from):
		_refused.rpc_id(peer, request, "unsupported_replication_inventory")
		return
	for tx: Dictionary in transactions.values():
		if int(tx.mover) == peer:
			_refused.rpc_id(peer, request, "already_crossing")
			return
	for queued: Dictionary in _pending:
		if int(queued.mover) == peer:
			return
	_pending.append({"mover": peer, "request": request, "from": from, "to": to})

@rpc("authority", "call_remote", "reliable", 0)
func _refused(request: int, reason: String) -> void:
	if int(_local.get("request", -1)) == request:
		_local["error"] = reason
		_local["phase"] = "cancelled"

func _grant(row: Dictionary) -> void:
	_serial += 1
	var token := "%d:%d:%d" % [epoch, int(row.mover), _serial]
	var tx := row.duplicate(true)
	tx.merge({"token": token, "phase": "requests_closed", "round": 1,
		"peers": _peers(), "acks": {}, "installed": {1: true}, "fences_started": false,
		"history_epoch": history.epoch,
		"target_deny": history.token_for(int(row.mover), str(row.to)),
		"origin_denies": origins.capture(int(row.mover), str(row.to)),
		"deadline": Time.get_ticks_msec() + TIMEOUT_MS}, true)
	transactions[token] = tx
	_broadcast(tx)
	_maybe_start_fences(token)

func _broadcast(tx: Dictionary) -> void:
	_policy_revision += 1
	var payload := tx.duplicate(true)
	payload.erase("acks")
	payload.erase("installed")
	payload["origin_rows"] = origins.rows.duplicate(true)
	payload["retired_receivers"] = retired_receivers.duplicate(true)
	_install.rpc(payload)
	_install_local(payload)

@rpc("authority", "call_remote", "reliable", 0)
func _install(tx: Dictionary) -> void:
	_install_local(tx)
	if str(tx.phase) in ["requests_closed", "closed"] and tx.peers.has(me()):
		_awaiting_install[str(tx.token)] = int(tx.round)
		_flush_installed()

func _directors(realm: String) -> Array[Node]:
	var result: Array[Node] = []
	for scope: Node in scopes:
		if not is_instance_valid(scope) or str(scope.get("realm")) != realm:
			continue
		var director: Variant = scope.get("producer")
		if is_instance_valid(director) and not result.has(director):
			result.append(director)
	return result

func _flush_installed() -> void:
	for token: String in _awaiting_install.keys().duplicate():
		if not transactions.has(token):
			_awaiting_install.erase(token)
			continue
		var tx: Dictionary = transactions[token]
		var settled := true
		if int(tx.mover) == me() and str(tx.phase) == "requests_closed":
			for director: Node in _directors(str(tx.from)):
				if not bool(director.call("realm_transition_results_settled")):
					settled = false
		if settled:
			_installed.rpc_id(1, token, int(_awaiting_install[token]))
			_awaiting_install.erase(token)

@rpc("any_peer", "call_remote", "reliable", 0)
func _installed(token: String, round_id: int) -> void:
	if not host() or not transactions.has(token):
		return
	var tx: Dictionary = transactions[token]
	var sender := multiplayer.get_remote_sender_id()
	if int(tx.round) != round_id or not tx.peers.has(sender):
		return
	tx.installed[sender] = true
	_maybe_start_fences(token)

func _maybe_start_fences(token: String) -> void:
	var tx: Dictionary = transactions[token]
	if bool(tx.fences_started) or tx.installed.size() != tx.peers.size():
		return
	tx.fences_started = true
	_start_fences.rpc(token, int(tx.round))
	_send_fences(token, int(tx.round))

@rpc("authority", "call_remote", "reliable", 0)
func _start_fences(token: String, round_id: int) -> void:
	if transactions.has(token) and int(transactions[token].round) == round_id \
			and transactions[token].peers.has(me()):
		_send_fences(token, round_id)

func _install_local(tx: Dictionary) -> void:
	var token := str(tx.token)
	if not host():
		transactions[token] = tx.duplicate(true)
		origins.rows = (tx.get("origin_rows", {}) as Dictionary).duplicate(true)
		retired_receivers = (tx.get("retired_receivers", retired_receivers) as Dictionary).duplicate(true)
	if int(tx.mover) == me() and int(tx.request) == int(_local.get("request", -1)):
		_local["token"] = token
		_local["phase"] = str(tx.phase)
	for scope: Node in scopes:
		if is_instance_valid(scope):
			scope.call("refresh_visibility")

func _send_fences(token: String, round_id: int) -> void:
	if not transactions.has(token):
		return
	for peer: int in transactions[token].peers:
		if peer != me():
			_fence_zero.rpc_id(peer, token, round_id)
			_fence_one.rpc_id(peer, token, round_id)

@rpc("any_peer", "call_remote", "reliable", 0)
func _fence_zero(token: String, round_id: int) -> void:
	_received_fence(token, round_id, 0, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 1)
func _fence_one(token: String, round_id: int) -> void:
	_received_fence(token, round_id, 1, multiplayer.get_remote_sender_id())

func _received_fence(token: String, round_id: int, channel: int, sender: int) -> void:
	if not transactions.has(token):
		# All recipients acknowledge phase installation before any sender can
		# emit a fence. An unknown token therefore cannot be a current receipt.
		return
	if host():
		_ack_here(token, round_id, channel, sender, me())
	else:
		_ack.rpc_id(1, token, round_id, channel, sender)

@rpc("any_peer", "call_remote", "reliable", 0)
func _ack(token: String, round_id: int, channel: int, sender: int) -> void:
	if host():
		_ack_here(token, round_id, channel, sender, multiplayer.get_remote_sender_id())

func _ack_here(token: String, round_id: int, channel: int, sender: int, receiver: int) -> void:
	if not transactions.has(token):
		return
	var tx: Dictionary = transactions[token]
	if int(tx.round) != round_id or channel not in [0, 1] or sender == receiver \
			or not tx.peers.has(sender) or not tx.peers.has(receiver):
		return
	tx.acks["%d:%d:%d" % [sender, receiver, channel]] = true
	_maybe_advance(token)

func _maybe_advance(token: String) -> void:
	if not host() or not transactions.has(token):
		return
	var tx: Dictionary = transactions[token]
	var needed: int = tx.peers.size() * (tx.peers.size() - 1) * 2
	if tx.acks.size() < needed:
		return
	if str(tx.phase) == "requests_closed":
		# Prior request callbacks have run. Withdraw this participant only;
		# their final replies are enqueued before the second response fences.
		for director: Node in _directors(str(tx.from)):
			director.call("realm_transition_departing", int(tx.mover))
		tx.phase = "closed"
		tx.round = 2
		tx.acks = {}
		tx.installed = {1: true}
		tx.fences_started = false
		_broadcast(tx)
		_maybe_start_fences(token)
	elif str(tx.phase) == "closed":
		tx.phase = "draining"
		_broadcast(tx)
		_despawn_fence.rpc_id(int(tx.mover), token)

@rpc("authority", "call_remote", "reliable", 0)
func _despawn_fence(token: String) -> void:
	if token == str(_local.get("token", "")) and transactions.has(token):
		_local["despawn_fence"] = true
		_check_local_drain()

func _check_local_drain() -> void:
	if not active() or host() or not bool(_local.get("despawn_fence", false)) \
			or bool(_local.get("drained", false)):
		return
	var from := str(_local.get("from", ""))
	for scope: Node in scopes:
		if not is_instance_valid(scope) or str(scope.get("realm")) != from:
			continue
		if int(scope.call("received_count")) != 0 or not (scope.call("bodies") as Array).is_empty():
			return
	_local["drained"] = true
	_drained.rpc_id(1, str(_local.token))

@rpc("any_peer", "call_remote", "reliable", 0)
func _drained(token: String) -> void:
	if not _mover_message(token) or str(transactions[token].phase) != "draining":
		return
	var tx: Dictionary = transactions[token]
	history.retire(int(tx.mover), str(tx.from), token)
	tx.phase = "loading"
	tx.deadline = Time.get_ticks_msec() + TIMEOUT_MS
	for director: Node in _directors(str(tx.from)):
		director.call("realm_transition_committed", int(tx.mover))
	session().call("_apply_realm_change", int(tx.mover), str(tx.from), str(tx.to))
	_broadcast(tx)

func _mover_message(token: String) -> bool:
	return host() and transactions.has(token) \
		and int(transactions[token].mover) == multiplayer.get_remote_sender_id()

@rpc("any_peer", "call_remote", "reliable", 0)
func _receiver_ready(token: String, realm: String) -> void:
	if _mover_message(token) and str(transactions[token].phase) == "loading" \
			and str(transactions[token].to) == realm:
		transactions[token]["receiver_ready"] = true

@rpc("any_peer", "call_remote", "reliable", 0)
func _retarget(token: String, realm: String) -> void:
	if not _mover_message(token) or not _prepare_retarget(token, realm):
		return
	var tx: Dictionary = transactions[token]
	session().call("_apply_realm_change", int(tx.mover), str(session().call("realm_of", int(tx.mover))), realm)
	_broadcast(tx)

func _prepare_retarget(token: String, realm: String) -> bool:
	if not transactions.has(token):
		return false
	var tx: Dictionary = transactions[token]
	if str(tx.phase) != "loading" or realm != str(tx.from) or realm == str(tx.to) \
			or history.token_for(int(tx.mover), str(tx.from)) != token \
			or history.token_for(int(tx.mover), str(tx.to)) != str(tx.target_deny):
		return false
	# Never open the abandoned destination while its queued-for-deletion bodies
	# still exist. This receiver never proved that destination ready. The deny
	# survives completion until a later matching readiness (or disconnect/reset).
	history.retire(int(tx.mover), str(tx.to), token + "@abandoned:" + str(tx.to))
	_policy_revision += 1
	tx.to = realm
	tx.target_deny = history.token_for(int(tx.mover), realm)
	tx.origin_denies = origins.capture(int(tx.mover), realm)
	tx.phase = "loading"
	tx.erase("receiver_ready")
	tx.erase("failure_reported")
	tx.deadline = Time.get_ticks_msec() + TIMEOUT_MS
	return true

func outgoing_allowed(owner: int, realm: String, observer: int, origin: String = "") -> bool:
	if not origins.allowed(origin, observer):
		return false
	if (retired_receivers.get(observer, {}) as Dictionary).has(realm):
		return false
	for tx: Dictionary in transactions.values():
		if realm == str(tx.from) and (owner == int(tx.mover) or observer == int(tx.mover)):
			return false
		if realm == str(tx.to) and observer == int(tx.mover) and str(tx.phase) != "admitted":
			return false
	return true

func admission_allowed(realm: String, observer: int, owner: int = 0, origin: String = "") -> bool:
	if not origins.allowed(origin, observer):
		return false
	if (retired_receivers.get(observer, {}) as Dictionary).has(realm):
		return false
	for tx: Dictionary in transactions.values():
		if realm == str(tx.to) and observer == int(tx.mover) and str(tx.phase) != "admitted":
			return false
		if realm == str(tx.from) and str(tx.phase) in ["draining", "loading", "admitted"] \
				and (observer == int(tx.mover) or owner == int(tx.mover)):
			return false
	return true

func scene_rpc_allowed(realm: String, observer: int, completing: bool = false) -> bool:
	if (retired_receivers.get(observer, {}) as Dictionary).has(realm):
		return false
	for tx: Dictionary in transactions.values():
		if realm == str(tx.to) and (observer == int(tx.mover) or me() == int(tx.mover)) \
				and str(tx.phase) != "admitted":
			return false
		if realm != str(tx.from):
			continue
		if me() == int(tx.mover):
			return completing and str(tx.phase) == "requests_closed"
		if observer == int(tx.mover) and str(tx.phase) != "requests_closed":
			return false
	return true

func body_rpc_allowed(realm: String, observer: int, origin: String) -> bool:
	return origins.allowed(origin, observer) and scene_rpc_allowed(realm, observer)

## Called only by host spawn producers, never from a peer's deployment data.
## The origin is copied into the authoritative spawner payload and immutable
## thereafter. An owner's later creature deployment retains its live cohort.
func stamp_spawn(owner: int, realm: String) -> String:
	if not host() or not active():
		return ""
	for tx: Dictionary in transactions.values():
		if int(tx.mover) == owner and str(tx.to) == realm:
			var origin := "%s@%s" % [str(tx.token), realm]
			if not origins.rows.has(origin):
				origins.create(origin, realm, owner, session().call("peers"))
				_policy_revision += 1
				_origin_install.rpc(origin, origins.rows[origin])
			return origin
	for origin: String in origins.rows:
		var row: Dictionary = origins.rows[origin]
		if int(row.owner) == owner and str(row.realm) == realm:
			return origin
	return ""

func track_origin_body(origin: String, body: Node) -> void:
	if host() and not origin.is_empty():
		origins.track(origin, body)

func prepare_joined_sender(peer: int) -> bool:
	if not host() or not active():
		return false
	if transactions.is_empty() and retired_receivers.is_empty() and origins.rows.is_empty():
		return false
	_send_joined_policy(peer)
	return true

func _send_joined_policy(peer: int) -> void:
	_serial += 1
	var permit := "%d:join:%d:%d" % [epoch, peer, _serial]
	_joining[peer] = {"permit": permit, "revision": _policy_revision}
	var current: Dictionary = transactions.duplicate(true)
	for tx: Dictionary in current.values():
		tx.erase("acks")
		tx.erase("installed")
	_joined_sender_policy.rpc_id(peer, permit, current, retired_receivers, origins.rows)

@rpc("authority", "call_remote", "reliable", 0)
func _joined_sender_policy(permit: String, current: Dictionary, retired: Dictionary, origin_rows: Dictionary) -> void:
	transactions = current.duplicate(true)
	retired_receivers = retired.duplicate(true)
	origins.rows = origin_rows.duplicate(true)
	for scope: Node in scopes:
		if is_instance_valid(scope):
			scope.call("refresh_visibility")
	_joined_sender_applied.rpc_id(1, permit)

@rpc("any_peer", "call_remote", "reliable", 0)
func _joined_sender_applied(permit: String) -> void:
	if not host():
		return
	var peer := multiplayer.get_remote_sender_id()
	if not _joining.has(peer) or str(_joining[peer].permit) != permit:
		return
	if int(_joining[peer].revision) != _policy_revision:
		_send_joined_policy(peer)
		return
	_joining.erase(peer)
	# Only now may the ordinary snapshot unlock the joining world's scene
	# producers and peer_joined create its host-spawned owner State bodies.
	session().call("_finish_peer_hello", peer)

@rpc("authority", "call_remote", "reliable", 0)
func _origin_install(origin: String, row: Dictionary) -> void:
	if not origins.rows.has(origin):
		origins.rows[origin] = row.duplicate(true)

@rpc("authority", "call_remote", "reliable", 0)
func _origin_retired(origin: String) -> void:
	origins.rows.erase(origin)

func pins_realm(realm: String) -> bool:
	for tx: Dictionary in transactions.values():
		if realm in [str(tx.from), str(tx.to)]:
			return true
	return false

func deliver_trainer_reward(peer: int, payload: Dictionary) -> void:
	if host() and active() and _peers().has(peer):
		_trainer_reward.rpc_id(peer, payload)

@rpc("authority", "call_remote", "reliable", 1)
func _trainer_reward(payload: Dictionary) -> void:
	var game := get_node_or_null("/root/Game")
	if game != null:
		preload("res://scripts/net/trainer_reward_delivery.gd").apply(game.get("party"), game, payload)

func _world_for(realm: String) -> Node:
	if not is_inside_tree():
		return null
	for child: Node in get_tree().root.get_children():
		if child.has_method("world_realm") and str(child.call("world_realm")) == realm:
			return child
	return null

func _prepare_inventory(realm: String) -> bool:
	var world := _world_for(realm)
	if world == null:
		return false
	var spawners := world.find_children("*", "MultiplayerSpawner", true, false)
	if spawners.is_empty():
		return false
	for source: Node in spawners:
		var scope := SCOPE.attach(source as MultiplayerSpawner, realm)
		if not (scope.call("unsupported_bodies") as Array).is_empty():
			return false
	return true

func _target_ready(realm: String) -> bool:
	var world := _world_for(realm)
	return world != null and (not world.has_method("shell_build_complete") \
		or bool(world.call("shell_build_complete"))) and _prepare_inventory(realm)

func _process(_delta: float) -> void:
	if not active():
		return
	_check_local_drain()
	if not host():
		_flush_installed()
		return
	for origin: String in origins.collect_dead():
		_policy_revision += 1
		_origin_retired.rpc(origin)
	for queued: Dictionary in _pending.duplicate():
		if not _overlaps(str(queued.from), str(queued.to)):
			_pending.erase(queued)
			_grant(queued)
	for token: String in transactions.keys().duplicate():
		var tx: Dictionary = transactions[token]
		if Time.get_ticks_msec() >= int(tx.deadline) and not bool(tx.get("failure_reported", false)):
			_fail_transaction(token, "realm_transition_timeout")
			continue
		if str(tx.phase) == "loading" and bool(tx.get("receiver_ready", false)) and _target_ready(str(tx.to)):
			if not history.admit_ready(int(tx.mover), str(tx.to), str(tx.target_deny), int(tx.history_epoch)):
				continue
			origins.admit_ready(int(tx.mover), str(tx.to), tx.origin_denies)
			tx.phase = "admitted"
			_broadcast(tx)
			_finish.rpc(token, retired_receivers)
			_finish_local(token, retired_receivers)

@rpc("authority", "call_remote", "reliable", 0)
func _finish(token: String, retired: Dictionary) -> void:
	_finish_local(token, retired)

func _finish_local(token: String, retired: Dictionary) -> void:
	# Reliable duplicates or a delayed old completion cannot replace newer
	# receiver history. Only an installed live transaction can finish.
	if not transactions.has(token):
		return
	retired_receivers = retired.duplicate(true)
	transactions.erase(token)
	_policy_revision += 1
	_awaiting_install.erase(token)
	if token == str(_local.get("token", "")):
		_local["phase"] = "done"
		for director: Node in _directors(str(_local.get("to", ""))):
			director.call("realm_transition_arrived")
	for scope: Node in scopes:
		if is_instance_valid(scope):
			scope.call("refresh_visibility")

@rpc("any_peer", "call_remote", "reliable", 0)
func _cancel_request(request: int, caller_epoch: int, known_token: String) -> void:
	if not host():
		return
	var peer := multiplayer.get_remote_sender_id()
	for queued: Dictionary in _pending.duplicate():
		if int(queued.mover) == peer and int(queued.request) == request:
			_pending.erase(queued)
			_cancel_settled.rpc_id(peer, request, caller_epoch, "", "refused")
			return
	for token: String in transactions.keys().duplicate():
		var tx: Dictionary = transactions[token]
		if int(tx.mover) == peer and int(tx.request) == request:
			var loading := str(tx.phase) == "loading"
			_fail_transaction(token, "cancelled")
			_cancel_settled.rpc_id(peer, request, caller_epoch, token,
				"recovery_required" if loading else "aborted")
			return
	# Request and cancellation share reliable channel 0. With no queued/live
	# request left, any earlier abort/refusal was enqueued before this receipt.
	_cancel_settled.rpc_id(peer, request, caller_epoch, known_token,
		"refused" if known_token.is_empty() else "aborted")

@rpc("authority", "call_remote", "reliable", 0)
func _cancel_settled(request: int, caller_epoch: int, token: String, outcome: String) -> void:
	if not context_valid(caller_epoch) or int(_local.get("request", -1)) != request \
			or not bool(_local.get("settling", false)) \
			or token != str(_local.get("token", "")) \
			or _local.has("begin_outcome"):
		return
	if outcome not in ["refused", "aborted", "recovery_required"]:
		return
	if outcome == "recovery_required" and (not transactions.has(token) \
			or str(_local.get("phase", "")) != "loading"):
		return
	_local["begin_outcome"] = outcome
	if outcome in ["refused", "aborted"]:
		_local["phase"] = "cancelled"

func _fail_transaction(token: String, reason: String) -> void:
	if not transactions.has(token):
		return
	var tx: Dictionary = transactions[token]
	if str(tx.phase) == "loading":
		# The receiver may already be absent. Keep both realms pinned and
		# admission shut while Game rebuilds its rollback receiver.
		tx.failure_reported = true
		_transition_failed.rpc_id(int(tx.mover), token, reason)
		return
	_abort_token.rpc(token, reason)
	_abort_token_local(token, reason)

@rpc("authority", "call_remote", "reliable", 0)
func _transition_failed(token: String, reason: String) -> void:
	if str(_local.get("token", "")) == token:
		_local["error"] = reason

@rpc("authority", "call_remote", "reliable", 0)
func _abort_token(token: String, reason: String) -> void:
	_abort_token_local(token, reason)

func _abort_token_local(token: String, reason: String) -> void:
	if not transactions.has(token):
		return
	transactions.erase(token)
	_policy_revision += 1
	_awaiting_install.erase(token)
	if str(_local.get("token", "")) == token:
		_local["error"] = reason
		_local["phase"] = "cancelled"
	for scope: Node in scopes:
		if is_instance_valid(scope):
			scope.call("refresh_visibility")

func peer_disconnected(peer: int) -> void:
	_joining.erase(peer)
	_policy_revision += 1
	history.disconnect_peer(peer)
	origins.disconnect_peer(peer)
	for queued: Dictionary in _pending.duplicate():
		if int(queued.mover) == peer:
			_pending.erase(queued)
	for token: String in transactions.keys().duplicate():
		var tx: Dictionary = transactions[token]
		if int(tx.mover) == peer:
			transactions.erase(token)
			_awaiting_install.erase(token)
		else:
			tx.peers.erase(peer)
			if not host():
				continue
			tx.installed.erase(peer)
			for key: String in (tx.get("acks", {}) as Dictionary).keys().duplicate():
				var pair := key.split(":")
				if int(pair[0]) == peer or int(pair[1]) == peer:
					tx.acks.erase(key)
			_maybe_start_fences(token)
			_maybe_advance(token)
	for scope: Node in scopes:
		if is_instance_valid(scope):
			scope.call("refresh_visibility")
