extends Node

## Stage B Wave 2 lane 2.A. THE SESSION: host, join, leave, and the handshake.
##
## Mounted by `game_state.gd::_ready()` as `/root/Game/Session`. A child of the
## one autoload rather than a second autoload (the one-autoload rule), and a
## `Node` rather than a `RefCounted` because it needs `multiplayer`, RPCs and a
## `_process` tick. The node path is identical in every process, which is what
## makes its RPCs resolve at all.
##
## D95 is the transport contract: `ENetMultiplayerPeer`, listen server, up to
## four peers, TWO transfer channels -- `CHANNEL_LEDGER` for ledger/encounter
## traffic and `CHANNEL_SNAPSHOT` for the world snapshot, so a joiner's snapshot
## never queues behind somebody's movement. Nothing outside this file calls
## `multiplayer.` to open or close a peer.
##
## ## Solo is a one-peer session
##
## `title_screen.gd::_enter_world()` calls `host()` on both Start New Game and
## Load, so there is exactly one code path into play. A solo player is a host
## with no clients: `is_host()` true, `peer_count()` 1, `is_multi_peer()` false.
##
## `is_host()` is deliberately true when there is NO session at all. Every
## headless test, capture tool and editor run that never hosts anything still
## has to be allowed to write its world -- "not a client" is the honest question
## the four D100 autosave sites are actually asking, and answering it with
## `multiplayer.is_server()` would have made every one of them false in exactly
## those contexts (that call needs a live peer to mean anything).
##
## ## Spike gotchas honoured here
## (`ralph/reports/MP-0C-SPIKE-ENET-0905/REPORT.md`)
##
##   1. Every flag a signal sets lives in `_box`, a Dictionary -- a GDScript
##      lambda captures an outer `bool` BY VALUE, so a polling loop reading a
##      bare local hangs forever with no error. `join()`'s two waits read `_box`.
##   2. Peer ids are large random 32-bit numbers; only the listen server is 1.
##      `peer_registry.gd` keys on the real id and logs it verbatim.
##   3. Authority is set inside a `spawn_function`, never after tree entry.
##      No spawner here yet (2.C owns the rigs); noted so it is not forgotten.

const PEER_REGISTRY := preload("res://scripts/net/peer_registry.gd")
const REALM_SHELLS := preload("res://scripts/net/realm_shells.gd")
const REALM_TRANSITION := preload("res://scripts/net/realm_transition.gd")
const SNAPSHOT_TRANSFER := preload("res://scripts/net/snapshot_transfer.gd")
const CHARACTER_IDENTITY := preload("res://scripts/save/character_identity.gd")
const BUILD_FINGERPRINT := preload("res://scripts/net/build_fingerprint.gd")
## Kept as text rather than preloading steam_lobby.gd, which Session must not
## depend on. test_steam_lobby.gd pins the two strings together.
const STEAM_PROTOCOL_REFUSAL := "This connection uses an incompatible Tetherbound protocol."
const CONFIG_PATH := "res://data/config/multiplayer.json"
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"

## D95's two channels. Godot adds its own three system channels beneath these,
## so transfer_channel 1 and 2 are ENet channels 3 and 4 on the wire.
const CHANNEL_LEDGER := 1
const CHANNEL_SNAPSHOT := 2

## Frames a leaving host keeps its socket open so the reliable `session_ended`
## broadcast reaches everyone. Six at 60 Hz is 100 ms -- two orders of magnitude
## over the 6.9 ms median loopback RTT the ENet spike measured, and still
## imperceptible to the player who just chose to quit.
const CLOSE_FLUSH_FRAMES := 6
## Terminal reasons (refusal, kick, snapshot abort, host exit) are reliable
## RPCs. ENet's disconnect discards reliable packets the other side has not
## acknowledged yet, so on a lossy link a fixed frame count can drop the
## reason. The client learns nothing, and with the long realm-loading
## peer timeout it waits out the generic handshake timeout. Instead the
## host keeps the link up after CLOSE_FLUSH_FRAMES until the other side
## closes it (clients tear down as soon as a terminal reason arrives) or
## these bounds pass. Measured on the harness proxy at 30% loss and
## 150+-30 ms delay: ralph/reports/INVITE-COOP.
const REFUSAL_LINGER_S := 10.0
const HOST_CLOSE_LINGER_S := 5.0
## A client that says goodbye keeps its old transport open this long for the
## host to close the link. The host closes only after it has read the goodbye;
## closing from the client side straight away lets ENet discard the unread
## goodbye with the disconnect. Only the detached transport waits: the session
## itself ends at once (`_lingering_peer`).
const GOODBYE_LINGER_S := 1.5

const HOST_PEER_ID := PEER_REGISTRY.HOST_PEER_ID

signal peer_joined(peer_id: int, character_id: String)
signal peer_left(peer_id: int)
## Wave 6 lane 6.A. Somebody crossed a realm boundary without leaving the
## session. Emitted on every peer, from the replicated registry, so a world
## scene can reconcile what it draws without asking who moved.
signal peer_realm_changed(peer_id: int, from_realm: String, to_realm: String)
## Host-local terminal edge for a coordinated client departure. The registry
## changes at `peer_realm_changed`; old authoritative bodies may be retained
## invisibly until this later receiver-ready boundary drains their final state.
signal peer_realm_departure_settled(peer_id: int, from_realm: String, to_realm: String)
signal snapshot_applied()
signal stormwood_strike_received(event: Dictionary)
signal stormwood_arch_arrival(event: Dictionary)
signal stormwood_encounter_message(event: Dictionary)
signal session_ended(reason: String)
## Emitted only after the active MultiplayerPeer has been detached and closed.
## A platform lobby can use this edge to leave its discovery lobby without
## racing the host's reliable session-ended flush.
signal transport_closed()

## "" (no session), "host" or "client". The single source of truth for
## `is_host()`; `multiplayer.is_server()` is only consulted inside RPC bodies,
## where a live peer is guaranteed to exist.
var _mode: String = ""
var _peer: MultiplayerPeer = null
var _transport_kind := ""
## World-first joins load their destination before constructing a peer. During
## that measured load window they are already prospective clients: they must
## neither act as authority nor save the temporary local world/character.
var _preparing_client := false
var _registry: RefCounted = PEER_REGISTRY.new()
var _config: Dictionary = {}
var _clock_accum: float = 0.0
var _capacity: int = 0

## Spike finding 2 (the real one): a Dictionary state box for every flag a
## signal callback sets and a polling loop reads. `connected`, `snapshot` and
## `failed` are all set from signal or RPC context, and read by callers polling
## `snapshot_ready()` / `is_active()` a frame at a time.
##
## NOTHING in this file is a coroutine, deliberately. Every public entry point
## returns immediately and the caller polls -- a step arm with a frame budget, a
## UI screen with a spinner. An `await` inside `host()`/`join()`/`leave()` would
## have to survive being reached through `Object.call()` (which is how
## `game_state.gd` and `peer_runner.gd` both reach this file, since there is no
## `class_name` to type against), and a suspended call through `call()` is
## exactly the kind of thing that works until it silently does not.
##
## `snapshot` starts TRUE, not false: it is the answer to "may this process act
## in the world", and a solo or session-less process may. Only `join()` closes
## it, and only the host's snapshot reopens it.
var _box: Dictionary = {
	"connected": false,
	"snapshot": true,
	"handshake_snapshot_applied": false,
	"failed": false,
	"host_rejected": false,
	"failure_reason": "",
	"ended": "",
}

## The character summary `join()` was given, sent the moment ENet reports the
## connection up (`_on_connected_to_server`).
var _pending_hello: Dictionary = {}

## Frames left before a leaving host may close its socket. A reliable
## `session_ended` broadcast has to get off the wire before the peer under it
## goes away, and counting frames in `_process` is how that happens without
## this function becoming a coroutine. After the frames, the host still waits
## for every remote peer to close (they tear down on the reason) or for
## `_closing_deadline_ms`, whichever is first.
var _closing_frames: int = 0

## A leaving client's old transport, detached from this Session and polled on
## its own until the host closes it or GOODBYE_LINGER_S passes. The session is
## already over (`is_active()` false, `session_ended` emitted), so the title can
## host, load or join again straight away.
var _lingering_peer: MultiplayerPeer = null
var _lingering_deadline_ms := 0
var _closing_deadline_ms: int = 0
var _closing_reason: String = ""

## Unadmitted, kicked or aborted transport peer -> `{frames, deadline_ms}`.
## The per-peer form of the host-close lifecycle above: queue the terminal
## reason, keep the socket alive for at least CLOSE_FLUSH_FRAMES, and then
## until the peer closes it (`_on_peer_disconnected` erases the entry) or
## the refusal deadline passes. These peers are not in the registry while
## they linger, so they are never admitted and never receive a snapshot.
var _rejected_disconnect_frames: Dictionary = {}

## Admitted peers that said goodbye before closing (`leave()` on a client).
## Their disconnect frees the seat at once instead of reserving it for the
## reconnect window. A lost goodbye only means the seat is held, which is the
## safe direction.
var _departing_peers: Dictionary = {}

## One snapshot chunk may be in flight per joining peer. The receiver boundary
## is raised only by BEGIN on the ledger channel; chunks remain independently
## ordered on the snapshot channel and are acknowledged one at a time.
var _snapshot_sends: Dictionary = {}
var _next_snapshot_transfer_id := 1
var _snapshot_receive: RefCounted = SNAPSHOT_TRANSFER.new()
var _snapshot_receive_id := 0
var _early_snapshot_chunk: Dictionary = {}
var _bootstrap_boundary := false
var _bootstrap_deltas: Array[Dictionary] = []
var _bootstrap_delta_bytes := 0
var _latest_bootstrap_registry: Dictionary = {}
var _bootstrap_registry_received := false
var _pending_snapshot_ack: Dictionary = {}

## Wave 6 lane 6.A: `/root/Game/Session/Realms`, the host's headless shells.
## Mounted in `_ready()` so its node path is identical in every process, the
## same reason `LedgerRpc` is mounted with the session rather than by its
## first consumer.
var _realms: Node = null
var realm_transition: Node = null


func _ready() -> void:
	name = "Session"
	process_mode = Node.PROCESS_MODE_ALWAYS
	_config = _load_config()
	realm_transition = REALM_TRANSITION.new()
	add_child(realm_transition)
	_realms = REALM_SHELLS.new()
	add_child(_realms)
	var api := multiplayer
	if api != null:
		api.peer_connected.connect(_on_peer_connected)
		api.peer_disconnected.connect(_on_peer_disconnected)
		api.connected_to_server.connect(_on_connected_to_server)
		api.connection_failed.connect(_on_connection_failed)
		api.server_disconnected.connect(_on_server_disconnected)


func _load_config() -> Dictionary:
	# `FileAccess.open` on `res://data/config/*.json`, the same way
	# `spawn_tables.gd::config()` and every other config reader in this repo
	# does it -- not `ResourceLoader`, which would treat the file as an import.
	var f := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var section: Variant = (parsed as Dictionary).get("session", {})
	return section if typeof(section) == TYPE_DICTIONARY else {}


func config() -> Dictionary:
	return _config.duplicate(true)


func _cfg(key: String, fallback: Variant) -> Variant:
	var v: Variant = _config.get(key, fallback)
	return v if v != null else fallback


func default_port() -> int:
	return int(_cfg("port", 27015))


func max_peers() -> int:
	return int(_cfg("max_peers", 4))


# --- public API ---------------------------------------------------------------

## Open a listen server. Returns whether the port was bound.
##
## Never fatal: a failed bind (another process already on the port, a locked
## down box) leaves the session inactive, which is a solo game that cannot be
## joined -- not a game that refuses to start. `title_screen.gd` relies on that.
func host(port: int = -1, peers: int = -1) -> bool:
	if is_active():
		return is_host()
	var use_port := port if port > 0 else default_port()
	var cap := peers if peers > 0 else max_peers()
	var p := ENetMultiplayerPeer.new()
	# create_server() counts transport CLIENTS, while `cap` counts admitted peers
	# including the host. Keep one spare transport-only handshake seat so a join
	# against a full registry reaches admission and receives `session_full`; the
	# registry remains hard-capped at `cap`, so this never creates a fifth player.
	var err := p.create_server(use_port, maxi(1, cap), int(_cfg("channel_count", 2)))
	if err != OK:
		push_warning("Session.host: could not bind udp/%d (err %d); staying offline-solo" % [use_port, err])
		return false
	if not host_with_peer(p, cap, "enet"):
		p.close()
		return false
	print("[session] hosting on udp/%d (cap %d, channels %d); local peer id %d"
		% [use_port, cap, int(_cfg("channel_count", 2)), multiplayer.get_unique_id()])
	return true


## Install an already-created listen peer. Platform discovery/relay adapters
## create their own MultiplayerPeer, but admission, identity and snapshots must
## still pass through this Session rather than growing a parallel handshake.
func host_with_peer(peer: MultiplayerPeer, cap: int = -1,
		transport_kind: String = "steam") -> bool:
	if is_active():
		return is_host() and _peer == peer
	if not transport_peer_valid(peer, true):
		push_warning("Session.host_with_peer: peer is not a connected server with peer id 1")
		return false
	var use_cap := cap if cap > 0 else max_peers()
	if use_cap < 1 or use_cap > max_peers():
		push_warning("Session.host_with_peer: capacity %d is outside 1..%d"
			% [use_cap, max_peers()])
		return false
	_peer = peer
	multiplayer.multiplayer_peer = peer
	_mode = "host"
	_transport_kind = transport_kind.strip_edges().to_lower()
	if _transport_kind.is_empty():
		_transport_kind = "custom"
	_capacity = use_cap
	_box["connected"] = true
	_box["snapshot"] = true
	_box["handshake_snapshot_applied"] = false
	_box["failed"] = false
	_box["host_rejected"] = false
	_box["failure_reason"] = ""
	_box["ended"] = ""
	_registry.call("clear")
	_registry.call("add", HOST_PEER_ID, _local_character_id(), _local_display_name(),
		_local_realm(), _local_appearance_id())
	# Hash the content now, while the host is opening, so the first joiner's
	# hello does not pay for it (build_fingerprint.gd caches per process).
	BUILD_FINGERPRINT.current()
	if _realms != null:
		_realms.call("reconcile")
	print("[session] hosting via %s (cap %d); local peer id %d"
		% [_transport_kind, use_cap, multiplayer.get_unique_id()])
	return true


## Dial a host. Returns whether the client socket was created -- NOT whether
## the handshake finished. The caller polls `snapshot_ready()`, which stays
## false until the host's world snapshot has actually been applied; that is
## deliverable 3's "a joiner may not send intents before `snapshot_applied`",
## and it is a state anything can ask at any time rather than a moment only the
## one caller that awaited `join()` ever saw.
##
## `handshake_failed()` distinguishes "still waiting" from "this will never
## finish" so a polling caller does not have to run its budget out to learn the
## connection was refused.
func join(ip: String, port: int = -1, character_summary: Dictionary = {}) -> bool:
	if is_active():
		leave()
		if is_active():
			return false
	var use_port := port if port > 0 else default_port()
	var p := ENetMultiplayerPeer.new()
	var err := p.create_client(ip, use_port, int(_cfg("channel_count", 2)))
	if err != OK:
		push_warning("Session.join: create_client(%s, %d) failed err=%d" % [ip, use_port, err])
		return false
	if not join_with_peer(p, character_summary, "enet"):
		p.close()
		return false
	print("[session] dialling %s:%d as '%s' (%s)"
		% [ip, use_port, _local_display_name(), _local_character_id()])
	return true


## Install an already-created client peer. The peer may still be CONNECTING;
## `_on_connected_to_server()` drives the same hello path used by ENet.
func join_with_peer(peer: MultiplayerPeer, character_summary: Dictionary = {},
		transport_kind: String = "steam") -> bool:
	if is_active():
		leave()
		if is_active():
			return false
	if not transport_peer_valid(peer, false):
		push_warning("Session.join_with_peer: peer is disconnected or identifies as a server")
		return false
	_peer = peer
	multiplayer.multiplayer_peer = peer
	var game := _game()
	if game != null and game.has_method("relinquish_world_save_ownership"):
		game.call("relinquish_world_save_ownership")
	_mode = "client"
	_preparing_client = false
	_transport_kind = transport_kind.strip_edges().to_lower()
	if _transport_kind.is_empty():
		_transport_kind = "custom"
	_box["connected"] = false
	_box["snapshot"] = false
	_box["handshake_snapshot_applied"] = false
	_box["failed"] = false
	_box["host_rejected"] = false
	_box["failure_reason"] = ""
	_box["ended"] = ""
	_registry.call("clear")

	# D100's portable half, on the way IN. Before the summary is built, so a
	# restored character's own realm and display name are what this peer
	# announces rather than the blank ones a fresh process holds. See
	# `_restore_character_here()` for why this is here and not after the
	# snapshot.
	_adopt_character_id(str(character_summary.get("character_id", "")))
	_restore_character_here(str(character_summary.get("character_id", "")))

	var summary := character_summary.duplicate(true)
	if not summary.has("character_id"):
		summary["character_id"] = _local_character_id()
	if not summary.has("display_name"):
		summary["display_name"] = _local_display_name()
	if not summary.has("realm"):
		summary["realm"] = _local_realm()
	if not summary.has("appearance_id"):
		summary["appearance_id"] = _local_appearance_id()
	# Always this process's own fingerprint: a caller cannot claim another build.
	summary["build"] = BUILD_FINGERPRINT.current()
	_pending_hello = summary
	print("[session] dialling via %s as '%s' (%s)"
		% [_transport_kind, str(summary["display_name"]), str(summary["character_id"])])
	return true


## Pure validation kept public for focused transport adapter tests. A client
## peer is allowed to be CONNECTING; a server must already be CONNECTED.
static func transport_peer_valid(peer: MultiplayerPeer, hosting: bool) -> bool:
	if peer == null:
		return false
	var status := peer.get_connection_status()
	if status == MultiplayerPeer.CONNECTION_DISCONNECTED:
		return false
	if hosting and status != MultiplayerPeer.CONNECTION_CONNECTED:
		return false
	var unique_id := peer.get_unique_id()
	return unique_id == HOST_PEER_ID if hosting else unique_id > HOST_PEER_ID


func transport_kind() -> String:
	return _transport_kind


static func transport_uses_enet_timeouts(peer: MultiplayerPeer) -> bool:
	return peer is ENetMultiplayerPeer


## A connection attempt is not durable play. Until the authoritative world
## snapshot lands, refusal/cancel/timeout must leave the selected portable
## character byte-for-byte untouched.
func client_character_save_ready() -> bool:
	return _mode == "client" and bool(_box.get("handshake_snapshot_applied", false))


## Close authority and snapshot gates while JoinDriver builds the destination
## world, without claiming an active session or attempting RPCs before a peer
## exists. Idempotent for the one pending join attempt.
func prepare_client_join() -> bool:
	if is_active():
		return _mode == "client"
	var game := _game()
	if game != null and game.has_method("relinquish_world_save_ownership"):
		game.call("relinquish_world_save_ownership")
	_preparing_client = true
	_box["snapshot"] = false
	_box["handshake_snapshot_applied"] = false
	_box["failed"] = false
	_box["host_rejected"] = false
	_box["failure_reason"] = ""
	_box["ended"] = ""
	return true


func cancel_client_join_preparation() -> void:
	if is_active():
		return
	_preparing_client = false
	_box["snapshot"] = true


## True once a joiner's handshake has definitively failed (connection refused,
## or the peer torn down under it). Never true on a host or a solo process.
func handshake_failed() -> bool:
	return bool(_box.get("failed", false))


## A specific host refusal when one was delivered. Existing polling callers can
## keep using `handshake_failed()`; invite/join UI can present this text instead
## of waiting for or collapsing into the generic handshake timeout.
func handshake_failure_reason() -> String:
	return str(_box.get("failure_reason", ""))


## True only when the host delivered an admission verdict. Transport failures
## remain retryable under JoinDriver's existing retry_for_s budget.
func handshake_rejected_by_host() -> bool:
	return bool(_box.get("host_rejected", false))


## Leave, whichever end this is.
##
## Host (deliverable 4): save the world, tell everyone, let ENet flush, close.
## Client: save its own character, close. A client never writes the world --
## that is D100, and it is enforced at the four autosave sites through
## `Game.is_host()`, not by hoping a client never reaches one.
func leave(reason: String = "left") -> void:
	if not is_active() or _closing_frames > 0:
		return
	if is_host():
		_save_world_here()
		if int(_registry.call("size")) > 1:
			# One round trip's worth of frames so the reliable `session_ended`
			# packet actually leaves before the socket closes under it. Counted
			# down in `_process`; see `_closing_frames`.
			rpc("_rpc_session_ended", reason)
			_closing_reason = reason
			_closing_frames = CLOSE_FLUSH_FRAMES
			_closing_deadline_ms = Time.get_ticks_msec() + int(
				1000.0 * float(_cfg("host_close_linger_s", HOST_CLOSE_LINGER_S)))
			return
	else:
		_save_character_here()
		# The goodbye is sent into the transport now; the transport alone then
		# waits for the host while the session ends below, synchronously.
		_teardown(_say_goodbye())
		session_ended.emit(reason)
		return
	_teardown()
	session_ended.emit(reason)


## Host-only. Drops one peer; the registry replicates without it.
func kick(peer_id: int) -> bool:
	if not is_active() or not is_host() or peer_id == HOST_PEER_ID:
		return false
	if not bool(_registry.call("has", peer_id)):
		return false
	rpc_id(peer_id, "_rpc_session_ended", "kicked")
	_linger_then_disconnect(peer_id)
	_registry.call("remove", peer_id)
	_broadcast_registry()
	peer_left.emit(peer_id)
	if _realms != null:
		_realms.call("reconcile")
	return true


## Not a client. True for solo and for a process with no session at all -- see
## this file's header for why that, and not `multiplayer.is_server()`, is what
## the D100 autosave sites ask.
func is_host() -> bool:
	return _mode != "client" and not _preparing_client


func is_active() -> bool:
	return _mode != ""


## True once there is somebody else in the session -- what D97's interim
## `enter_realm()` refusal and D105's sleep vote both key off.
func is_multi_peer() -> bool:
	return peer_count() > 1


# --- realms (Wave 6 lane 6.A) ----------------------------------------------------

## The host's shell manager, `/root/Game/Session/Realms`. Never null after
## `_ready()`; a caller still checks, because a `Session` reached through
## `Object.call()` before its first frame is a real state.
func realms() -> Node:
	return _realms


## Which realm a peer is standing in, from the replicated registry. THE answer
## to that question for anybody but the local player -- D97 is explicit that
## nothing authoritative reads `Game.current_realm`, and from this lane on
## that global is only ever true of this process.
func realm_of(peer_id: int) -> String:
	if not is_active():
		return _local_realm() if peer_id == local_peer_id() else ""
	var row: Dictionary = _registry.call("row", peer_id)
	return str(row.get("realm", ""))


## Every peer standing in `realm`, ordered by peer id.
func peers_in_realm(realm: String) -> Array:
	var out: Array = []
	for entry: Variant in peers():
		if entry is Dictionary and str((entry as Dictionary).get("realm", "")) == realm:
			out.append(int((entry as Dictionary).get("peer_id", 0)))
	return out


## Every realm somebody is standing in right now, ordered. What
## `realm_shells.gd` reconciles against.
func occupied_realms() -> Array:
	var seen: Dictionary = {}
	for entry: Variant in peers():
		if entry is Dictionary:
			var realm := str((entry as Dictionary).get("realm", ""))
			if not realm.is_empty():
				seen[realm] = true
	var out: Array = seen.keys()
	out.sort()
	return out


## Directive rule 16, this end of it. `game_state.gd::enter_realm()` calls this
## BEFORE it swaps the scene, and that ordering is the deliverable: the host
## takes this peer's body out of the realm it is leaving while the peer is
## still standing in it, so nobody is left drawing a trainer who has gone.
##
## Solo and session-less: nothing to tell anybody, and no shells to keep, so
## this is a no-op and a crossing is exactly what it always was.
func announce_realm(from_realm: String, to_realm: String) -> void:
	if not is_active() or from_realm == to_realm:
		return
	if realm_transition != null and bool(realm_transition.call("owns_announcement", from_realm, to_realm)):
		return
	if is_host():
		_apply_realm_change(HOST_PEER_ID, from_realm, to_realm)
		return
	# Compatibility for announcements outside Game's controlled client travel.
	# Game.enter_realm is asynchronous; its coordinator owns the actual drain
	# and membership commit when a client transition is active.
	rpc_id(HOST_PEER_ID, "_rpc_realm_changed", from_realm, to_realm)


## Client -> host, ledger channel. Reliable: a lost realm change would leave
## the host simulating the wrong world for this peer indefinitely.
@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_realm_changed(from_realm: String, to_realm: String) -> void:
	if not is_host():
		return
	var sender := multiplayer.get_remote_sender_id()
	if not bool(_registry.call("has", sender)):
		return
	# The host trusts the peer about where IT is standing and nothing else:
	# `from_realm` is taken from the registry, not from the packet, so a peer
	# cannot claim to have left a realm it was never in.
	_apply_realm_change(sender, str(_registry.call("row", sender).get("realm", "")), to_realm)


## The one place a realm change lands, whoever moved. Registry first (it is
## what `realm_shells.gd` and the per-realm spawners read), then the
## replication, then the shells, then the signal.
func _apply_realm_change(peer_id: int, from_realm: String, to_realm: String) -> void:
	if from_realm == to_realm:
		return
	_registry.call("set_realm", peer_id, to_realm)
	# BEFORE the shells reconcile. `trainer_spawn.gd` listens for this and
	# withdraws the moving peer's body from the realm it has left. Coordinated
	# client departures may keep the old host node invisibly as a cache target
	# until destination readiness, then reconcile it normally.
	peer_realm_changed.emit(peer_id, from_realm, to_realm)
	_broadcast_registry()
	if _realms != null:
		_realms.call("reconcile")


## Called by RealmTransition only after the mover has built and acknowledged
## its destination receiver. This is deliberately local to the host: its
## authoritative spawners own the old body and replicate the eventual free.
func settle_realm_departure(peer_id: int, from_realm: String, to_realm: String) -> void:
	if not is_active() or not is_host():
		return
	peer_realm_departure_settled.emit(peer_id, from_realm, to_realm)


## Peers in the session. 1 when solo or session-less: the local player is
## always one peer, and a caller dividing by this must never get zero.
func peer_count() -> int:
	if not is_active():
		return 1
	return maxi(1, int(_registry.call("size")))


func peers() -> Array:
	if not is_active():
		return [PEER_REGISTRY.make_row(HOST_PEER_ID, _local_character_id(),
			_local_display_name(), _local_realm(), _local_appearance_id())]
	return _registry.call("rows")


func registry() -> RefCounted:
	return _registry


func registry_fingerprint() -> int:
	return int(_registry.call("fingerprint"))


func local_peer_id() -> int:
	if not is_active():
		return HOST_PEER_ID
	return multiplayer.get_unique_id()


## Deliverable 3's gate: false on a joiner that has not yet applied the host's
## world. Always true on a host and on a session-less process.
func snapshot_ready() -> bool:
	return bool(_box.get("snapshot", true))


## Unlike `snapshot_ready()`, this remains false after a failed join tears its
## socket down and the session-less process becomes safe to act again. Tests and
## admission UI can therefore distinguish an explicit pre-snapshot refusal from
## a successful handshake followed by a later disconnect.
func handshake_snapshot_applied() -> bool:
	return bool(_box.get("handshake_snapshot_applied", false))


func mode() -> String:
	return _mode


# --- handshake ----------------------------------------------------------------

## Client -> host, ledger channel. The joiner's character summary.
@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_hello(summary: Dictionary) -> void:
	if not is_host():
		return
	var sender := multiplayer.get_remote_sender_id()
	# The first refusal owns this transport peer until its queued reason flushes.
	# Ignore repeated hellos without resetting that deadline: otherwise a sender
	# could be admitted during the short flush window and then disconnected when
	# the old rejection timer expires.
	if _rejected_disconnect_frames.has(sender):
		return
	if _closing_frames > 0:
		# The host is saving and closing; nothing admitted now would ever hear
		# `session_ended`.
		_reject_hello(sender, "host_closing", "The host is closing this world.")
		return
	if _transport_kind == "steam":
		var game := _game()
		var lobby := game.get_node_or_null(^"SteamLobby") if game != null else null
		var reason := "The friends lobby is unavailable."
		if lobby != null and lobby.has_method("admission_error"):
			reason = str(lobby.call("admission_error", sender, summary))
		if not reason.is_empty():
			var code := "incompatible_version" \
				if reason == STEAM_PROTOCOL_REFUSAL else "steam_lobby_refused"
			_reject_hello(sender, code, reason)
			return
	# Build/content compatibility precedes identity and capacity, so a
	# mismatched joiner hears the specific reason even when the session is
	# full, and nothing about this world is prepared for it.
	var compat: Dictionary = BUILD_FINGERPRINT.compare(
		BUILD_FINGERPRINT.current(), summary.get("build", null))
	if not bool(compat.get("ok", false)):
		_reject_hello(sender, str(compat.get("code", "incompatible_version")),
			str(compat.get("reason", "")))
		return
	var raw_character_id: Variant = summary.get("character_id", null)
	var verdict: Dictionary = _registry.call(
		"admission_verdict", sender, raw_character_id, _capacity if _capacity > 0 else max_peers())
	if not bool(verdict.get("ok", false)):
		_reject_hello(sender, str(verdict.get("code", "host_refused")),
			str(verdict.get("reason", "The host refused this connection.")))
		return
	var character_id: String = raw_character_id
	var display_name := str(summary.get("display_name", ""))
	var realm := str(summary.get("realm", "meadows"))
	var appearance_id := str(summary.get("appearance_id", "trainer"))
	var added: Dictionary = _registry.call(
		"add", sender, character_id, display_name, realm, appearance_id)
	if added.is_empty():
		# Defence in depth if registry state changes between the verdict and add.
		_reject_hello(sender, "character_in_use",
			"That character is already connected to this world.")
		return
	if realm_transition != null and bool(realm_transition.call("prepare_joined_sender", sender)):
		return
	_finish_peer_hello(sender)


func _reject_hello(sender: int, code: String, reason: String) -> void:
	# Reliable and on the ledger channel, matching every other terminal session
	# reason. Keep the peer alive for the same measured frame flush used by a
	# coordinated host close; an immediate disconnect can drop the queued reason.
	rpc_id(sender, "_rpc_admission_rejected", code, reason)
	_linger_then_disconnect(sender)
	print("[session] refused peer %d (%s): %s" % [sender, code, reason])


## Host -> one unadmitted joiner. No character/world save occurs: a failed
## handshake must not create or overwrite durable state.
@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_admission_rejected(code: String, reason: String) -> void:
	if is_host():
		return
	_box["failed"] = true
	_box["host_rejected"] = true
	_box["failure_reason"] = reason
	_box["ended"] = code
	_teardown()
	session_ended.emit(code)


func _finish_peer_hello(sender: int) -> void:
	if not is_host() or not bool(_registry.call("has", sender)):
		return
	if _snapshot_sends.has(sender):
		# A repeated hello cannot replace the immutable baseline or reset the
		# acknowledgement cursor of the transfer already serving this peer.
		return
	var row: Dictionary = _registry.call("row", sender)
	var character_id := str(row.get("character_id", ""))
	var display_name := str(row.get("display_name", ""))
	var realm := str(row.get("realm", ""))
	print("[session] peer %d joined as '%s' (%s) in %s" % [sender, display_name, character_id, realm])
	# Capture one immutable baseline before BEGIN. Registry and later ledger
	# deltas share BEGIN's reliable channel; chunks use the independent snapshot
	# channel and cannot broaden that boundary through cross-channel assumptions.
	var snapshot := _world_snapshot().duplicate(true)
	if not _start_snapshot_send(sender, snapshot):
		return
	_broadcast_registry()
	peer_joined.emit(sender, character_id)
	# The joiner may be arriving into a realm this process is not standing in
	# (a rejoin carries the character's last realm forward, `peer_registry
	# .gd::add`). Standing its shell up is this call, not a special case.
	if _realms != null:
		_realms.call("reconcile")


func _start_snapshot_send(peer_id: int, snapshot: Dictionary) -> bool:
	var transfer_id := _next_snapshot_transfer_id
	_next_snapshot_transfer_id += 1
	if _next_snapshot_transfer_id <= 0:
		_next_snapshot_transfer_id = 1
	var codec: RefCounted = SNAPSHOT_TRANSFER.new()
	var encoded: Dictionary = codec.call("encode_snapshot", snapshot, transfer_id)
	if not bool(encoded.get("ok", false)):
		_abort_host_snapshot(peer_id, str(encoded.get("error", "World snapshot could not be encoded.")))
		return false
	_snapshot_sends[peer_id] = {
		"transfer_id": transfer_id,
		"chunks": encoded.get("chunks", []),
		"next_index": 0,
		"awaiting_index": -1,
		"deadline_ms": Time.get_ticks_msec() \
			+ int(float(_cfg("handshake_timeout_s", 60.0)) * 1000.0),
	}
	var begin_error := rpc_id(peer_id, "_rpc_snapshot_begin", encoded.get("descriptor", {}))
	if begin_error != OK:
		_abort_host_snapshot(peer_id, "The host could not send the world snapshot descriptor.")
		return false
	return _send_next_snapshot_chunk(peer_id)


func _send_next_snapshot_chunk(peer_id: int) -> bool:
	if not _snapshot_sends.has(peer_id):
		return false
	var state: Dictionary = _snapshot_sends[peer_id]
	if int(state.get("awaiting_index", -1)) >= 0:
		return true
	var chunks: Array = state.get("chunks", [])
	var index := int(state.get("next_index", 0))
	if index >= chunks.size():
		_snapshot_sends.erase(peer_id)
		return true
	state["awaiting_index"] = index
	_snapshot_sends[peer_id] = state
	var send_error := rpc_id(peer_id, "_rpc_snapshot_chunk",
		int(state.get("transfer_id", 0)), index, chunks[index])
	if send_error != OK:
		_abort_host_snapshot(peer_id, "The host could not send the world snapshot data.")
		return false
	return true


@rpc("any_peer", "call_remote", "reliable", CHANNEL_SNAPSHOT)
func _rpc_snapshot_chunk_ack(transfer_id: int, index: int) -> void:
	if not is_host():
		return
	var sender := multiplayer.get_remote_sender_id()
	if not _snapshot_sends.has(sender):
		return
	var state: Dictionary = _snapshot_sends[sender]
	if transfer_id != int(state.get("transfer_id", 0)) \
			or index != int(state.get("awaiting_index", -1)):
		_abort_host_snapshot(sender, "The world snapshot acknowledgement was invalid.")
		return
	state["awaiting_index"] = -1
	state["next_index"] = index + 1
	_snapshot_sends[sender] = state
	_send_next_snapshot_chunk(sender)


@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_snapshot_begin(descriptor: Dictionary) -> void:
	_receive_snapshot_begin(descriptor, true)


func _receive_snapshot_begin(descriptor: Dictionary, send_ack: bool) -> bool:
	if is_host() or _bootstrap_boundary:
		return false
	if not bool(_snapshot_receive.call("begin", descriptor)):
		_fail_snapshot_receive(str(_snapshot_receive.call("last_error")), send_ack)
		return false
	_snapshot_receive_id = int(descriptor.get("transfer_id", 0))
	_bootstrap_boundary = true
	if _early_snapshot_chunk.is_empty():
		return true
	var early := _early_snapshot_chunk
	_early_snapshot_chunk = {}
	return _receive_snapshot_chunk(int(early.get("transfer_id", 0)),
		int(early.get("index", -1)), early.get("bytes", PackedByteArray()), send_ack)


@rpc("authority", "call_remote", "reliable", CHANNEL_SNAPSHOT)
func _rpc_snapshot_chunk(transfer_id: int, index: int, bytes: PackedByteArray) -> void:
	_receive_snapshot_chunk(transfer_id, index, bytes, true)


func _receive_snapshot_chunk(transfer_id: int, index: int, bytes: PackedByteArray,
		send_ack: bool) -> bool:
	if is_host():
		return false
	if not _bootstrap_boundary:
		if transfer_id <= 0 or index != 0 or bytes.is_empty() \
				or bytes.size() > SNAPSHOT_TRANSFER.DEFAULT_CHUNK_BYTES:
			_fail_snapshot_receive("World snapshot data arrived before a valid descriptor.", send_ack)
			return false
		if not _early_snapshot_chunk.is_empty():
			var same := transfer_id == int(_early_snapshot_chunk.get("transfer_id", 0)) \
				and index == int(_early_snapshot_chunk.get("index", -1)) \
				and bytes == (_early_snapshot_chunk.get("bytes", PackedByteArray()) as PackedByteArray)
			if not same:
				_fail_snapshot_receive("Conflicting world snapshot data arrived before its descriptor.", send_ack)
			return same
		_early_snapshot_chunk = {
			"transfer_id": transfer_id,
			"index": index,
			"bytes": bytes.duplicate(),
		}
		return true
	if not bool(_snapshot_receive.call("accept_chunk", transfer_id, index, bytes)):
		_fail_snapshot_receive(str(_snapshot_receive.call("last_error")), send_ack)
		return false
	if bool(_snapshot_receive.call("is_ready")):
		if send_ack:
			_pending_snapshot_ack = {"transfer_id": transfer_id, "index": index}
		return _finalize_snapshot_receive()
	if send_ack and not _send_snapshot_ack(transfer_id, index):
		return false
	return true


func _send_snapshot_ack(transfer_id: int, index: int) -> bool:
	if _peer == null:
		return false
	var send_error := rpc_id(HOST_PEER_ID, "_rpc_snapshot_chunk_ack", transfer_id, index)
	if send_error == OK:
		return true
	_fail_snapshot_receive("The world snapshot acknowledgement could not be sent.", false)
	return false


@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_snapshot_abort(transfer_id: int, reason: String) -> void:
	if not is_host():
		return
	var sender := multiplayer.get_remote_sender_id()
	var state: Dictionary = _snapshot_sends.get(sender, {})
	if int(state.get("transfer_id", 0)) == transfer_id:
		_abort_host_snapshot(sender, reason, false)


@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_snapshot_failed(reason: String) -> void:
	if not is_host():
		_fail_snapshot_receive(reason, false)


func _abort_host_snapshot(peer_id: int, reason: String, notify: bool = true) -> void:
	_snapshot_sends.erase(peer_id)
	if notify and _peer != null:
		rpc_id(peer_id, "_rpc_snapshot_failed", reason)
	if bool(_registry.call("remove", peer_id)):
		_broadcast_registry()
		peer_left.emit(peer_id)
		if _realms != null:
			_realms.call("reconcile")
	_linger_then_disconnect(peer_id)
	push_warning("[session] snapshot for peer %d failed: %s" % [peer_id, reason])


func _fail_snapshot_receive(reason: String, notify_host: bool) -> void:
	var message := reason.strip_edges()
	if message.is_empty():
		message = "The world snapshot could not be verified."
	var transfer_id := _snapshot_receive_id
	_box["failed"] = true
	_box["failure_reason"] = message
	_box["ended"] = "snapshot_failed"
	if notify_host and _peer != null and transfer_id > 0:
		rpc_id(HOST_PEER_ID, "_rpc_snapshot_abort", transfer_id, message)
	_clear_snapshot_bootstrap()
	if _peer != null:
		_teardown()


func _finalize_snapshot_receive() -> bool:
	# BEGIN and registry are ordered on the ledger channel, but the independent
	# snapshot channel may finish first. Readiness waits for both boundaries.
	if not bool(_snapshot_receive.call("is_ready")) or not _bootstrap_registry_received:
		return true
	var data: Dictionary = _snapshot_receive.call("snapshot")
	var game := _game()
	if game == null or not game.has_method("apply_world_snapshot"):
		_fail_snapshot_receive("The received world snapshot could not be applied.", true)
		return false
	var ledger_rpc := get_node_or_null(^"LedgerRpc")
	if not _bootstrap_deltas.is_empty() \
			and (ledger_rpc == null or not ledger_rpc.has_method("apply_remote_delta")):
		_fail_snapshot_receive("Queued world changes could not be applied after the snapshot.", true)
		return false
	game.call("apply_world_snapshot", data)
	if not _latest_bootstrap_registry.is_empty():
		_apply_registry(_latest_bootstrap_registry)
	for delta: Dictionary in _bootstrap_deltas:
		ledger_rpc.call("apply_remote_delta", delta)
	_box["snapshot"] = true
	_box["handshake_snapshot_applied"] = true
	print("[session] snapshot applied (%d keys, day %d)" % [data.size(), int(data.get("day", 1))])
	var pending_ack := _pending_snapshot_ack.duplicate()
	_clear_snapshot_bootstrap()
	snapshot_applied.emit()
	if not pending_ack.is_empty() and not _send_snapshot_ack(
			int(pending_ack.get("transfer_id", 0)), int(pending_ack.get("index", -1))):
		return false
	return true


## Called by LedgerRpc. True means the delta is owned by this bootstrap queue
## and must not be applied by the ordinary receiver path.
func queue_bootstrap_delta(delta: Dictionary) -> bool:
	if not _bootstrap_boundary or bool(_box.get("snapshot", false)):
		return false
	var encoded := var_to_bytes(delta)
	var next_count := _bootstrap_deltas.size() + 1
	var next_bytes := _bootstrap_delta_bytes + encoded.size()
	if encoded.is_empty() \
			or next_count > int(_cfg("snapshot_delta_queue_max_entries", 4096)) \
			or next_bytes > int(_cfg("snapshot_delta_queue_max_bytes", 8 * 1024 * 1024)):
		_fail_snapshot_receive(
			"Too many world changes arrived while the initial snapshot was loading.", true)
		return true
	_bootstrap_deltas.append(delta.duplicate(true))
	_bootstrap_delta_bytes = next_bytes
	return true


func _clear_snapshot_bootstrap() -> void:
	_snapshot_receive.call("reset")
	_snapshot_receive_id = 0
	_early_snapshot_chunk = {}
	_bootstrap_boundary = false
	_bootstrap_deltas.clear()
	_bootstrap_delta_bytes = 0
	_latest_bootstrap_registry = {}
	_bootstrap_registry_received = false
	_pending_snapshot_ack = {}


## Host -> everyone, ledger channel. The registry, whole (peer_registry.gd's
## header explains why whole and not a delta).
@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_registry(payload: Dictionary) -> void:
	if not is_host() and _bootstrap_boundary and not bool(_box.get("snapshot", false)):
		_latest_bootstrap_registry = payload.duplicate(true)
		_bootstrap_registry_received = true
		if bool(_snapshot_receive.call("is_ready")):
			_finalize_snapshot_receive()
		return
	_apply_registry(payload)


func _apply_registry(payload: Dictionary) -> void:
	# The realms BEFORE the load, so a client can tell which peers actually
	# moved. Without this a client learns of a realm change only as a body
	# that stopped updating: `peer_realm_changed` is what its own world scene
	# reconciles what it draws against, and only the host reaches
	# `_apply_realm_change()`.
	var before: Dictionary = {}
	for entry: Variant in (_registry.call("rows") as Array):
		if entry is Dictionary:
			before[int((entry as Dictionary).get("peer_id", 0))] = str((entry as Dictionary).get("realm", ""))
	_registry.call("load_data", payload)
	for entry: Variant in (_registry.call("rows") as Array):
		if not (entry is Dictionary):
			continue
		var row: Dictionary = entry
		var id := int(row.get("peer_id", 0))
		if not before.has(id):
			continue
		var was := str(before[id])
		var now := str(row.get("realm", ""))
		if was != now:
			peer_realm_changed.emit(id, was, now)


## Host -> everyone, ledger channel. D105: `day` and `clock_elapsed_seconds` are
## host truth. The client writes them into its own `WorldState` and resumes its
## live sky from the replicated number; `Game.advance_day()` refuses on a client
## so the local `world_look.gd` day-roll accumulator can never move the day.
@rpc("authority", "call_remote", "unreliable_ordered", CHANNEL_LEDGER)
func _rpc_clock(day: int, elapsed: float) -> void:
	var game := _game()
	if game == null or is_host() or _bootstrap_boundary:
		return
	game.call("apply_host_clock", day, elapsed)


## Same global transport as the day clock: it exists while a client changes
## realms, before the destination's weather node can receive scene RPCs.
@rpc("authority", "call_remote", "unreliable_ordered", CHANNEL_LEDGER)
func _rpc_realm_environment(state: Dictionary) -> void:
	var game := _game()
	if game != null and not is_host() and not _bootstrap_boundary:
		game.set("realm_environment", state)


## Hazard decisions originate in the host's realm simulation. The transport is
## global because a client and host may be standing in different world scenes.
func publish_stormwood_strike(event: Dictionary) -> void:
	if not is_host():
		return
	stormwood_strike_received.emit(event.duplicate(true))
	if is_active():
		rpc("_rpc_stormwood_strike", event)


@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_stormwood_strike(event: Dictionary) -> void:
	if not is_host():
		stormwood_strike_received.emit(event.duplicate(true))


func request_stormwood_arch_travel(arch_id: String) -> void:
	if is_host():
		_dispatch_stormwood_arch(local_peer_id(), arch_id)
	elif is_active():
		rpc_id(HOST_PEER_ID, "_rpc_stormwood_arch_request", arch_id)


func request_stormwood_encounter(intent: Dictionary) -> void:
	var completing := str(intent.get("kind", "")) in ["disengage", "finalized_death_withdrawal"]
	if not _stormwood_transition_allowed(HOST_PEER_ID, completing):
		return
	if is_host():
		_dispatch_stormwood_encounter(local_peer_id(), intent)
	elif is_active():
		rpc_id(HOST_PEER_ID, "_rpc_stormwood_encounter_request", intent)


@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_stormwood_encounter_request(intent: Dictionary) -> void:
	if is_host():
		_dispatch_stormwood_encounter(multiplayer.get_remote_sender_id(), intent)


func _dispatch_stormwood_encounter(peer: int, intent: Dictionary) -> void:
	if realm_of(peer) != "stormwood":
		return
	# Requests sent before the sender installs closure must still run before
	# its ledger fence. Receiver gating permits those through requests_closed.
	if not _stormwood_transition_allowed(peer, true):
		return
	var hub := get_tree().get_first_node_in_group("stormwood_encounter_hub")
	if hub != null:
		hub.dispatch(peer, intent)


func send_stormwood_encounter(peer: int, event: Dictionary) -> void:
	if not is_host():
		return
	if not _stormwood_transition_allowed(peer, true):
		return
	if peer == local_peer_id():
		stormwood_encounter_message.emit(event.duplicate(true))
	elif is_active() and realm_of(peer) == "stormwood":
		rpc_id(peer, "_rpc_stormwood_encounter_message", event)


func _stormwood_transition_allowed(peer: int, completing: bool) -> bool:
	return realm_transition == null or bool(realm_transition.call(
		"scene_rpc_allowed", "stormwood", peer, completing))


@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_stormwood_encounter_message(event: Dictionary) -> void:
	if not is_host():
		stormwood_encounter_message.emit(event)


@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_stormwood_arch_request(arch_id: String) -> void:
	if is_host():
		_dispatch_stormwood_arch(multiplayer.get_remote_sender_id(), arch_id)


func _dispatch_stormwood_arch(peer_id: int, arch_id: String) -> void:
	if realm_of(peer_id) != "stormwood":
		return
	var runtime := get_tree().get_first_node_in_group("stormwood_arch_runtime")
	if runtime == null:
		return
	var verdict: Dictionary = runtime.travel_for_peer(peer_id, arch_id)
	if peer_id == local_peer_id():
		stormwood_arch_arrival.emit(verdict)
	elif is_active():
		rpc_id(peer_id, "_rpc_stormwood_arch_arrival", verdict)


@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_stormwood_arch_arrival(event: Dictionary) -> void:
	if not is_host():
		stormwood_arch_arrival.emit(event)


## Client -> host. Best effort: a deliberate leave frees the seat at once.
@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_goodbye() -> void:
	if not is_host():
		return
	var sender := multiplayer.get_remote_sender_id()
	if bool(_registry.call("has", sender)):
		_departing_peers[sender] = true
		# Close from this side, after the goodbye has been read, so the
		# leaving client's disconnect cannot discard it. See GOODBYE_LINGER_S.
		if _peer != null:
			_peer.disconnect_peer(sender)


## Returns whether a goodbye went out; the caller then waits for the host to
## close the link (or GOODBYE_LINGER_S) before tearing down. A goodbye that is
## lost anyway only means the seat is held for the reconnect window.
func _say_goodbye() -> bool:
	# Only an admitted client holds a seat worth freeing. A failed or
	# unfinished join tears down at once, so the title can host or join again
	# without waiting on a goodbye nobody will answer.
	if _peer == null or not is_inside_tree() or multiplayer.multiplayer_peer != _peer \
			or not bool(_box.get("connected", false)) \
			or not bool(_box.get("handshake_snapshot_applied", false)):
		return false
	rpc_id(HOST_PEER_ID, "_rpc_goodbye")
	return true


## Host -> everyone (or one kicked peer), ledger channel.
@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_session_ended(reason: String) -> void:
	if is_host():
		return
	_box["ended"] = reason
	_save_character_here()
	_teardown()
	session_ended.emit(reason)
	_return_to_title(reason)


# --- transport callbacks --------------------------------------------------------

func _on_peer_connected(peer_id: int) -> void:
	_configure_transport_timeout(peer_id)
	# Nothing to do until the joiner says hello: the registry row is built from
	# the character summary, not from an id arriving on its own.
	print("[session] transport: peer %d connected" % peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	_rejected_disconnect_frames.erase(peer_id)
	# A joiner whose world snapshot was never acknowledged never played here;
	# it gets no held seat (it can still rejoin like anyone else).
	var mid_snapshot := _snapshot_sends.has(peer_id)
	_snapshot_sends.erase(peer_id)
	var departed := bool(_departing_peers.get(peer_id, false)) or mid_snapshot
	_departing_peers.erase(peer_id)
	if realm_transition != null:
		realm_transition.call("peer_disconnected", peer_id)
	if not is_host():
		return
	var lost_character := str((_registry.call("row", peer_id) as Dictionary).get("character_id", ""))
	if bool(_registry.call("remove", peer_id)):
		if not departed and _closing_frames == 0 and peer_id != HOST_PEER_ID:
			var window_ms := int(1000.0 * float(_cfg("reconnect_window_s", 120.0)))
			if window_ms > 0 and bool(_registry.call("reserve", lost_character,
					Time.get_ticks_msec() + window_ms)):
				print("[session] holding a seat for '%s' for %d s"
					% [lost_character, window_ms / 1000])
		_broadcast_registry()
		peer_left.emit(peer_id)
		print("[session] peer %d left; %d remain" % [peer_id, peer_count()])
		# Deliverable 5, and the case that sank D97's first design: the peer
		# who just vanished may have been the only one in its realm, and its
		# shell holds world state nothing else does. `reconcile()` tears that
		# shell down THROUGH the host's own world save, so a disconnect
		# mid-fight in an otherwise empty realm loses nothing.
		if _realms != null:
			_realms.call("reconcile")


func _on_connected_to_server() -> void:
	_configure_transport_timeout(HOST_PEER_ID)
	_box["connected"] = true


## ENet's stock 5 s minimum timeout is shorter than a legitimate procedural
## realm crossing. During a split-realm transition both processes can be busy:
## the client builds its destination while the host stands up the matching
## simulation shell. Each build yields frames and is bounded by Game's 120 s
## readiness deadline, but a reliable packet sent immediately before one of
## those builds can otherwise age past ENet's minimum and tear down a healthy
## session. Keep transport tolerance above Game's bounded 120 s loading window. The
## network smoke's independent 15 s heartbeat remains the freeze detector.
func _configure_transport_timeout(peer_id: int) -> void:
	if not transport_uses_enet_timeouts(_peer):
		return
	if not timeout_peer_is_physical(is_host(), peer_id):
		return
	var enet_peer := _peer as ENetMultiplayerPeer
	var transport_peer := enet_peer.get_peer(peer_id)
	if transport_peer == null:
		return
	transport_peer.set_timeout(
		int(_cfg("peer_timeout_limit", 32)),
		int(_cfg("peer_timeout_min_ms", 135_000)),
		int(_cfg("peer_timeout_max_ms", 180_000)))


static func timeout_peer_is_physical(hosting: bool, peer_id: int) -> bool:
	# ENet clients receive logical peer_connected events for fellow clients,
	# but their only physical remote connection is the server. get_peer() logs
	# an error for a relayed ID before its null result could be checked.
	return peer_id > 0 and (peer_id != HOST_PEER_ID if hosting else peer_id == HOST_PEER_ID)


func _on_connection_failed() -> void:
	_box["failed"] = true
	_teardown()


func _on_server_disconnected() -> void:
	# A host refusal tears down from its reason RPC. Ignore the later transport
	# edge rather than replacing that specific reason with `host_gone`.
	if _mode != "client":
		return
	if _box.get("ended", "") == "":
		_box["ended"] = "host_gone"
	_save_character_here()
	_teardown()
	session_ended.emit("host_gone")
	_return_to_title("host_gone")


# --- host clock (D105) -----------------------------------------------------------

func _process(delta: float) -> void:
	_poll_lingering_peer()
	if _closing_frames > 0:
		if _closing_frames > 1:
			_closing_frames -= 1
			return
		if not _close_flushed():
			return
		_finish_closing()
		return
	_flush_rejected_peers()
	_expire_snapshot_sends()
	# A joiner sends its character summary the moment ENet reports the link up.
	# Done here rather than straight from `_on_connected_to_server` so the rpc
	# goes out on an ordinary frame with the peer fully installed.
	if _mode == "client" and not _pending_hello.is_empty() and bool(_box.get("connected", false)):
		var summary := _pending_hello
		_pending_hello = {}
		print("[session] connected as peer %d; sending hello" % multiplayer.get_unique_id())
		rpc_id(HOST_PEER_ID, "_rpc_hello", summary)
	if not is_active() or not is_host() or int(_registry.call("size")) <= 1:
		return
	_clock_accum += delta
	var interval := float(_cfg("clock_sync_interval_s", 1.0))
	if _clock_accum < interval:
		return
	_clock_accum = 0.0
	var game := _game()
	if game == null:
		return
	rpc("_rpc_clock", int(game.get("day")), float(game.get("clock_elapsed_seconds")))
	var environment: Variant = game.get("realm_environment")
	if environment is Dictionary:
		rpc("_rpc_realm_environment", environment)


## Hold one peer's link open until its terminal reason is delivered. See
## REFUSAL_LINGER_S.
func _linger_then_disconnect(peer_id: int) -> void:
	_rejected_disconnect_frames[peer_id] = {
		"frames": CLOSE_FLUSH_FRAMES,
		"deadline_ms": Time.get_ticks_msec() + int(
			1000.0 * float(_cfg("refusal_linger_s", REFUSAL_LINGER_S))),
	}


## Service a leaving client's detached transport until the host has closed it
## (so the goodbye was read) or the bound passes, then close it.
func _poll_lingering_peer() -> void:
	if _lingering_peer == null:
		return
	_lingering_peer.poll()
	if _lingering_peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED \
			and Time.get_ticks_msec() < _lingering_deadline_ms:
		return
	_lingering_peer.close()
	_lingering_peer = null


func _finish_closing() -> void:
	var reason := _closing_reason
	_closing_frames = 0
	_closing_deadline_ms = 0
	_closing_reason = ""
	_teardown()
	session_ended.emit(reason)


## The final frame of a host close waits here until every remote peer has
## closed its side, or the deadline passes, so a dead or silent client cannot
## hold the host open.
func _close_flushed() -> bool:
	if _peer == null or not is_inside_tree() or multiplayer.multiplayer_peer != _peer:
		return true
	if multiplayer.get_peers().is_empty():
		return true
	return Time.get_ticks_msec() >= _closing_deadline_ms


func _flush_rejected_peers() -> void:
	if _rejected_disconnect_frames.is_empty():
		return
	var now := Time.get_ticks_msec()
	for raw_peer: Variant in _rejected_disconnect_frames.keys():
		var peer_id := int(raw_peer)
		var state: Dictionary = _rejected_disconnect_frames[raw_peer]
		var frames := int(state.get("frames", 0)) - 1
		if frames > 0 or now < int(state.get("deadline_ms", 0)):
			state["frames"] = maxi(frames, 0)
			continue
		_rejected_disconnect_frames.erase(raw_peer)
		if _peer != null:
			_peer.disconnect_peer(peer_id)


func _expire_snapshot_sends() -> void:
	if _snapshot_sends.is_empty() or not is_active() or not is_host():
		return
	var now := Time.get_ticks_msec()
	for raw_peer: Variant in _snapshot_sends.keys():
		var peer_id := int(raw_peer)
		var state: Dictionary = _snapshot_sends.get(raw_peer, {})
		if now > int(state.get("deadline_ms", now + 1)):
			_abort_host_snapshot(peer_id,
				"The world snapshot transfer timed out before the client acknowledged it.")


# --- internals -------------------------------------------------------------------

func _broadcast_registry() -> void:
	if not is_host() or not is_active():
		return
	if _registry.call("size") > 1:
		rpc("_rpc_registry", _registry.call("save_data"))


func _world_snapshot() -> Dictionary:
	var game := _game()
	if game == null:
		return {}
	# Through `Game`, not straight off `Game.world`: the four scene-facing sync
	# seams (buildings, satchels, harvest, clock) have to run first or the
	# snapshot describes a world one build behind the one the host is standing
	# in.
	if game.has_method("world_snapshot"):
		return game.call("world_snapshot")
	return {}


## Deliverable 4/D100: the host, and only the host, writes the world.
func _save_world_here() -> void:
	var game := _game()
	if game == null:
		return
	game.call("save_game", int(game.call("autosave_slot")))


## Deliverable 4/D100's other half: every peer writes its own character.
##
## D100's autosave ownership at the one site that is not `Game.autosave_here()`:
## the host writes its world (through the slot save, which writes the split pair
## with it), and a client writes ONLY its own portable character file.
##
## Lane 1.C wrote the second half. Before it, this printed "no character file to
## write yet" and a client left a session having recorded nothing at all -- the
## fog it had walked off, the creatures it had levelled and the satchel it had
## filled all went with the process.
##
## `_capture_player_pose()` first, for the same reason `game_state.gd::save_game()`
## calls it before every slot write: a character file whose pose is wherever the
## trainer last happened to be captured drops them somewhere else on the next
## Continue, which is exactly the thing a portable character must not do.
func _save_character_here() -> void:
	var game := _game()
	if game == null:
		return
	if is_host():
		game.call("save_game", int(game.call("autosave_slot")))
		return
	if not client_character_save_ready():
		print("[session] client leave: handshake never applied a snapshot; portable character unchanged")
		return
	var save_system: Variant = game.get("save_system")
	if save_system == null:
		push_warning("[session] client leave: no Game.save_system to write a character with")
		return
	if game.has_method("_capture_player_pose"):
		game.call("_capture_player_pose")
	var character_id := _local_character_id()
	if bool((save_system as RefCounted).call("save_character", game, character_id)):
		print("[session] client leave: wrote character '%s' (no world file -- D100)" % character_id)
	else:
		push_warning("[session] client leave: could not write character '%s'" % character_id)


## A caller who joins AS a named character makes this process that character.
##
## FINDING this fixes, found by row 21: `join()` put the caller's
## `character_id` into `_pending_hello` and nowhere else, so the registry row,
## the world and the other peers all knew this peer as (say)
## `reconnect-smoke-character` while its own `PlayerState.character_id` stayed
## empty. `_local_character_id()` then MINTED a `peer-<pid>-<usec>` id on the way
## out, and `_save_character_here()` wrote the character file under THAT --
## a file the next join by the announced id could never find. The write and the
## read were addressing two different names for one trainer.
##
## Only ever a stamp, never a clear: an empty argument leaves whatever this
## process already had, so `join()` with no summary keeps minting exactly as it
## did.
func _adopt_character_id(wanted_id: String) -> void:
	if wanted_id.is_empty():
		return
	var game := _game()
	if game == null:
		return
	var local: Variant = game.get("local")
	if local == null:
		return
	(local as RefCounted).set("character_id", wanted_id)


## D100's portable half, on the way back IN, and the other half of
## `_save_character_here()` above. **§17 item 21.**
##
## `character_save.gd::apply()` was written by lane 1.C as "the entry point for
## the multiplayer paths that have a character id and no slot at all" and had no
## caller: every peer WROTE `user://characters/<id>/character.json` on the way
## out and nothing ever read one back, so a rejoiner arrived as whatever its
## process still happened to hold in memory. A peer whose process restarted --
## the case the file exists for -- arrived as a blank trainer.
##
## Called from `join()` rather than after the host's snapshot, for two reasons:
## the character half names no world (that is the whole point of the split, see
## `character_save.gd`'s header), so it does not need the world to exist yet;
## and the hello this peer is about to send carries its display name and realm,
## which have to be the RESTORED ones or the registry row advertises a trainer
## nobody is playing.
##
## `false`, never fatal, on every miss: no id, no save system, no file. Joining
## as a fresh trainer is the correct outcome for a character that has never been
## saved, which is every first join, and it must not be an error.
##
## **Only when the caller NAMED a character.** An empty `wanted_id` returns
## immediately and does not fall back to `_local_character_id()`, because the
## other caller on this tree is `scripts/mp/join_driver.gd`, which dials with no
## summary at all -- and `title_screen.gd::_begin_join()` has already loaded slot
## 0 by then. Restoring over the top of a slot the player just chose to continue
## would replace their party with whatever the character file last held, which is
## the one thing this must not do. When that screen grows the character picker its
## own comment promises, it will name an id and come through here.
##
## The HOST never comes through here at all: `host()` does not call it.
func _restore_character_here(wanted_id: String) -> bool:
	if wanted_id.is_empty():
		return false
	var game := _game()
	if game == null:
		return false
	var character_id := wanted_id
	var save_system: Variant = game.get("save_system")
	if save_system == null:
		return false
	var characters: Variant = (save_system as RefCounted).call("characters")
	if characters == null:
		return false
	if not bool((characters as RefCounted).call("has", character_id)):
		print("[session] join: no character file for '%s'; arriving as a fresh trainer"
			% character_id)
		return false
	if not bool((characters as RefCounted).call("apply", game, character_id)):
		push_warning("[session] join: could not apply character '%s'" % character_id)
		return false
	print("[session] join: restored character '%s' from disk (D100 portable half)"
		% character_id)
	return true


## `linger_transport`: a client that just sent its goodbye. The session state is
## torn down exactly as always, but the transport is detached and handed to
## `_poll_lingering_peer()` instead of being closed under the goodbye.
func _teardown(linger_transport: bool = false) -> void:
	var had_transport := _peer != null
	if realm_transition != null:
		realm_transition.call("reset")
	# Before the peer goes away, not after: `realm_shells.gd::_tear_down()`
	# asks `Game.is_host()` whether it may write the world, and that answer
	# flips the moment `_mode` is cleared below.
	if _realms != null:
		_realms.call("release_all")
	if is_inside_tree() and multiplayer != null \
			and multiplayer.multiplayer_peer == _peer and _peer != null:
		multiplayer.multiplayer_peer = null
	if _peer != null:
		if linger_transport:
			if _lingering_peer != null:
				_lingering_peer.close()
			_lingering_peer = _peer
			_lingering_deadline_ms = Time.get_ticks_msec() + int(
				1000.0 * float(_cfg("goodbye_linger_s", GOODBYE_LINGER_S)))
		else:
			_peer.close()
	_peer = null
	_mode = ""
	_transport_kind = ""
	_preparing_client = false
	_capacity = 0
	_registry.call("clear")
	_box["connected"] = false
	_box["snapshot"] = true
	_pending_hello = {}
	_closing_frames = 0
	_closing_deadline_ms = 0
	_rejected_disconnect_frames.clear()
	_departing_peers.clear()
	_snapshot_sends.clear()
	_clear_snapshot_bootstrap()
	_clock_accum = 0.0
	if had_transport:
		transport_closed.emit()


func _return_to_title(reason: String) -> void:
	var game := _game()
	if game != null and game.has_method("push_world_message"):
		game.call("push_world_message",
			"The host closed the world." if reason != "kicked" else "You were removed from the world.")
	var tree := get_tree()
	if tree == null:
		return
	tree.change_scene_to_file(TITLE_SCENE)


func _game() -> Node:
	return get_parent()


func _local_character_id() -> String:
	var game := _game()
	if game == null:
		return ""
	var local: Variant = game.get("local")
	if local == null:
		return ""
	var id := str((local as RefCounted).get("character_id"))
	if id.is_empty():
		# The title normally creates identity before a session starts. Automation
		# and older entry points still need the same stable, slot-independent form.
		id = CHARACTER_IDENTITY.mint()
		(local as RefCounted).set("character_id", id)
	return id


func _local_display_name() -> String:
	var game := _game()
	if game == null:
		return "Trainer"
	var local: Variant = game.get("local")
	if local == null:
		return "Trainer"
	var n := str((local as RefCounted).get("display_name"))
	return n if not n.is_empty() else "Trainer"


func _local_appearance_id() -> String:
	var game := _game()
	if game == null:
		return "trainer"
	var local: Variant = game.get("local")
	if not local is Object:
		return "trainer"
	var appearance := str((local as Object).get("chosen_character"))
	return appearance if not appearance.is_empty() else "trainer"


func _local_realm() -> String:
	var game := _game()
	if game == null:
		return "meadows"
	return str(game.get("current_realm"))
