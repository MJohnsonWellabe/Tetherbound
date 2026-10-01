extends Node

const REDESIGN_STATE := preload("res://scripts/data/redesign_state.gd")

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
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const TRAINING_WORLD := preload("res://autoload/world_state.gd")
const CHARACTER_AUTHORITY := preload("res://scripts/net/character_authority.gd")
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

var _altar_epoch := Crypto.new().generate_random_bytes(16).hex_encode()
var _altar_host_epoch := ""
var _altar_host_namespace := ""
var _altar_stations: Dictionary = {} # Weak mounted nodes, never placement truth.
var _altar_quote_request: Dictionary = {}
var _altar_spend_request: Dictionary = {}
var _owner_training_retry: Dictionary = {} # Only weak refs + exact row identity, no balances.
var _owner_training_install := false
var _training_bootstrap_waiting := false
var _character_authority: RefCounted = CHARACTER_AUTHORITY.new()


signal altar_essence_quote_completed(key: String, owned_uid: String, quote_id: String, result: Dictionary)
signal altar_essence_spend_completed(key: String, spend_id: String, result: Dictionary)
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

## Admitted peers whose character took a held reconnect seat at hello.
var _reserved_rejoins: Dictionary = {}

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
	add_to_group(preload("res://scripts/ui/input_owner.gd").GROUP)
	add_to_group("story_modal")
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
	_close_lingering_peer()
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
	_close_lingering_peer()
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
	# Build the proof from the restored portable document, never caller summary
	# fields or later per-action packet inventory/rank proposals.
	var admission_game := _game()
	if admission_game != null and admission_game.get("local") != null:
		summary["portable_authority"] = CHARACTER_AUTHORITY.portable_projection(admission_game.get("local").save_data())
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


## Why the last session ended ("host_gone" when the host link dropped without
## the host's own reason, else the reason the host or this peer gave). Empty
## while a session is live or before the first one; a new session clears it.
func end_reason() -> String:
	return str(_box.get("ended", ""))


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


## Seats the host is holding for players inside the reconnect window
## (`reconnect_window_s`). Admission already counts them; the Players tab and
## the Steam invite need to as well, or they offer a seat nobody can take.
## Always 0 on a client, which keeps no reservations.
func held_seat_count() -> int:
	if not is_active() or not is_host():
		return 0
	return int(_registry.call("reservation_count"))


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
	if not _bind_character_authority():
		_reject_hello(sender, "world_not_ready", "The host world is not ready to admit this character.")
		return
	var portable: Variant = summary.get("portable_authority")
	var authority_errors := CHARACTER_AUTHORITY.errors(portable, character_id)
	if not authority_errors.is_empty():
		_reject_hello(sender, "invalid_character", "That portable character could not be admitted. Your files remain unchanged.")
		return
	if bool(_registry.call("has_reservation", character_id)):
		_reserved_rejoins[sender] = true
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
	var seeded: Dictionary = _character_authority.call("seed_admitted_character", portable, character_id)
	if bool(seeded.get("ok", false)):
		seeded = _character_authority.call("recover_durable_vitals", character_id, _game().get("world").reward_deliveries)
	if bool(seeded.get("ok", false)):
		seeded = _character_authority.call("recover_durable_training", character_id, _game().get("world").reward_deliveries)
	if not bool(seeded.get("ok", false)):
		_registry.call("remove", sender)
		_reject_hello(sender, "invalid_character", "That portable character could not be admitted. Your files remain unchanged.")
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
	rpc_id(sender, "_rpc_altar_epoch", _altar_epoch, str(_game().get("world").reward_delivery_namespace), str(row.get("character_id", "")))
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
	# Reject the whole bootstrap before any world, registry or queued-delta
	# mutation. WorldState's void loader refusal must never be acknowledged.
	var redesign_errors := REDESIGN_STATE.validate("world",
		data.get("redesign_world", REDESIGN_STATE.defaults("world")))
	redesign_errors.append_array(preload("res://scripts/net/actor_vitals_delivery.gd").world_errors(
		data.get("reward_deliveries", {}), str(data.get("reward_delivery_namespace", "")), str(data.get("world_id", ""))))
	redesign_errors.append_array(TRAINING_WORLD.training_world_errors(data.get("reward_deliveries", {}), str(data.get("reward_delivery_namespace", "")), str(data.get("world_id", "")), data.get("placed_buildings", [])))
	if not redesign_errors.is_empty():
		_fail_snapshot_receive("The received world snapshot contains invalid redesign data.", true)
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
	if preload("res://scripts/net/actor_vitals_delivery.gd").has_pending_owner(game.get("world").reward_deliveries, _local_character_id()) \
			and (ledger_rpc == null or not ledger_rpc.has_method("reconcile_actor_vitals_before_ready") \
			or not bool(ledger_rpc.call("reconcile_actor_vitals_before_ready"))):
		_fail_snapshot_receive("Your accepted vitality receipt could not be saved. It remains recoverable on the host.", true)
		return false
	if ledger_rpc != null and not bool(ledger_rpc.call("reconcile_creature_training_before_ready")):
		_training_bootstrap_waiting = true
		return true # Existing bootstrap stays closed; exact saved decision resumes it.
	_training_bootstrap_waiting = false
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
		# Retire existing scene senders while this endpoint still has channels.
		# ENet removes it only on a later poll; cached Sync visibility must not
		# keep targeting the disconnecting endpoint in that interval.
		if realm_transition != null:
			realm_transition.call("_refresh_scopes")
		# Close from this side, after the goodbye has been read, so the
		# leaving client's disconnect cannot discard it. See GOODBYE_LINGER_S.
		if _peer != null:
			_peer.disconnect_peer(sender)


## The existing goodbye lifetime, read by the scene replication coordinator.
## It is not an admission, world-readiness or held-seat decision.
func peer_is_departing(peer_id: int) -> bool:
	return bool(_departing_peers.get(peer_id, false))


## Returns whether a goodbye went out. The caller then tears the session down
## at once and leaves only the old transport polling (`_lingering_peer`) until
## the host closes it. A goodbye that is lost anyway only means the seat is
## held for the reconnect window.
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
	# A character that came back through its own held seat keeps it even if a
	# flaky link drops it again mid-snapshot -- the case the seat exists for.
	var mid_snapshot := _snapshot_sends.has(peer_id) and not _reserved_rejoins.has(peer_id)
	_snapshot_sends.erase(peer_id)
	_reserved_rejoins.erase(peer_id)
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
	_bind_training_container_guards()
	if portal_runtime_ready() and is_host():
		var portal_context := _host_portal_context(local_peer_id())
		if not portal_context.is_empty(): _portal_policy.call("cancel_invalid", portal_context)
	if _training_bootstrap_waiting:
		var training_transport := get_node_or_null(^"LedgerRpc")
		if training_transport != null:
			training_transport.call("reconcile_creature_training_before_ready")
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
func _exit_tree() -> void:
	_close_lingering_peer()


## A new join closes a leaving transport that is still waiting on the host, so
## its disconnect reaches the host ahead of the new hello: a fast rejoin cannot
## collide with its own old registry row (`character_in_use`). If that loses
## the goodbye, the host holds the seat and the same character reclaims it.
func _close_lingering_peer() -> void:
	if _lingering_peer != null:
		_lingering_peer.close()
		_lingering_peer = null


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
	_reserved_rejoins.clear()
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


## Shared detached truth for protected keys and the host combat roster.
## Equipment comes from the one admitted personal record; legacy realm power
## is inactive in this read view until protected personal hang is implemented.
func admitted_character_state(peer_id: int) -> Dictionary:
	if not is_host() or not _bind_character_authority():
		return {}
	var character := _authority_character(peer_id)
	if character.is_empty():
		return {}
	if peer_id == local_peer_id():
		var game := _game()
		if game != null and game.get("local") != null:
			var portable := CHARACTER_AUTHORITY.portable_projection(game.get("local").save_data())
			var refreshed: Dictionary = _character_authority.call("refresh_host_local", portable, character)
			if not bool(refreshed.get("ok", false)):
				return {}
			var recovered: Dictionary = _character_authority.call("recover_durable_vitals", character, game.get("world").reward_deliveries)
			if not bool(recovered.get("ok", false)):
				return {}
	var training_recovered: Dictionary = _character_authority.call("recover_durable_training", character, _game().get("world").reward_deliveries)
	if training_recovered.get("ok") != true: return {}
	var game_for_portals := _game()
	if game_for_portals != null and game_for_portals.get("world") != null:
		var portals: Dictionary = _character_authority.call("recover_durable_portals", character, game_for_portals.get("world").reward_deliveries)
		if portals.get("ok") != true: return {}
	return _character_authority.call("actor_stat_state", character)


func admitted_character_revision(peer_id: int) -> int:
	if admitted_character_state(peer_id).is_empty():
		return -1
	return int(_character_authority.call("revision", _authority_character(peer_id)))


## Internal host contact CAS, never an RPC or a client numeric rank.
func host_commit_creature_mastery(peer_id: int, creature_uid: String,
		expected_character_revision: int, expected_uses: Dictionary, expected_receipts: Dictionary,
		next_uses: Dictionary, next_receipts: Dictionary) -> Dictionary:
	if admitted_character_state(peer_id).is_empty():
		return {"ok": false, "code": "not_admitted", "revision": -1}
	return _character_authority.call("commit_creature_mastery", _authority_character(peer_id), creature_uid,
		expected_character_revision, expected_uses, expected_receipts, next_uses, next_receipts)


func host_commit_creature_loadout(peer_id: int, creature_uid: String,
		expected_character_revision: int, expected_loadout_revision: int, expected_last_edit: Dictionary,
		next_loadout: Dictionary, next_loadout_revision: int, next_edit_receipt: Dictionary) -> Dictionary:
	if admitted_character_state(peer_id).is_empty():
		return {"ok": false, "code": "not_admitted", "revision": -1}
	return _character_authority.call("commit_creature_loadout", _authority_character(peer_id), creature_uid,
		expected_character_revision, expected_loadout_revision, expected_last_edit,
		next_loadout, next_loadout_revision, next_edit_receipt)


func admitted_pending_loadout(peer_id: int) -> Dictionary:
	if admitted_character_state(peer_id).is_empty():
		return {}
	return _character_authority.call("pending_creature_loadout", _authority_character(peer_id))


## Internal service door. The authority result receiver sends a reliable ACK
## only after the portable write; the service binds its actual RPC sender.
func host_ack_creature_loadout(peer_id: int, creature_uid: String,
		loadout_revision: int, edit_receipt: Dictionary) -> bool:
	if admitted_character_state(peer_id).is_empty():
		return false
	return bool(_character_authority.call("acknowledge_creature_loadout", _authority_character(peer_id),
		creature_uid, loadout_revision, edit_receipt))


## Private owner transport proof only. No RPC, balance or persisted bag: this
## remembers which validated host receipt was applied while its bool save
## refused. Weak identity prevents another PlayerState reusing that proof.
var _owner_vitals_retries: Dictionary = {}


func _owner_vitals_retry_key(player: RefCounted, world: RefCounted, uid: String) -> String:
	return "%s\n%s\n%s" % [world.get("reward_delivery_namespace"), player.get("character_id"), uid]


func _owner_vitals_retry_receipt(player: RefCounted, world: RefCounted, uid: String) -> Dictionary:
	var raw: Variant = _owner_vitals_retries.get(_owner_vitals_retry_key(player, world, uid))
	if not raw is Dictionary or raw.player.get_ref() != player or raw.world.get_ref() != world:
		return {}
	return raw.row.duplicate(true)


func _retain_owner_vitals_retry(player: RefCounted, world: RefCounted, row: Dictionary) -> bool:
	var actor := preload("res://scripts/net/actor_vitals_delivery.gd")
	var character := str(player.get("character_id"))
	var world_namespace := str(world.get("reward_delivery_namespace"))
	if character.is_empty() or not actor.valid(row, character, world_namespace) \
			or row.world_id != str(world.get("world_id")) \
			or not actor.equivalent(world.get("reward_deliveries").get(row.delivery_id), row):
		return false
	var key := _owner_vitals_retry_key(player, world, row.creature_uid)
	var config: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/character_authority.json"))
	var limit: Variant = config.get("owner_vitals_retry_limit", 0) if config is Dictionary else 0
	if not (limit is int or limit is float) or not is_finite(float(limit)) \
			or float(limit) != floor(float(limit)) or float(limit) < 1.0 or float(limit) > 16384.0 \
			or (not _owner_vitals_retries.has(key) and _owner_vitals_retries.size() >= int(limit)):
		return false # Never evict an unsaved proof to accept a replay.
	_owner_vitals_retries[key] = {"player": weakref(player), "world": weakref(world), "row": row.duplicate(true)}
	return true


func _clear_owner_vitals_retry(player: RefCounted, world: RefCounted, row: Dictionary) -> void:
	var key := _owner_vitals_retry_key(player, world, row.creature_uid)
	var prior := _owner_vitals_retry_receipt(player, world, row.creature_uid)
	if not prior.is_empty() and int(prior.journal_revision) <= int(row.journal_revision):
		_owner_vitals_retries.erase(key)


## Every ordinary autosave uses the same snapshot preparation. An accepted
## unsaved HP value without its exact marker must never become a new portable
## disk baseline. The prepared receiver installs that marker before writing.
func _owner_vitals_snapshot_allowed(player: RefCounted, payload: Dictionary) -> bool:
	var actor := preload("res://scripts/net/actor_vitals_delivery.gd")
	for proof: Dictionary in _owner_vitals_retries.values():
		if proof.player.get_ref() != player:
			continue
		var row: Dictionary = proof.row
		if str(player.get("character_id")) != row.character_id \
				or (payload.has("character_id") and payload.character_id != row.character_id) \
				or not payload.get("party") is Array \
				or not payload.get("satchel_escrow") is Dictionary:
			return false
		var marker: Variant = payload.satchel_escrow.get(row.delivery_id)
		var expected := row.duplicate(true)
		expected.status = "settled"
		if not actor.equivalent(marker, expected):
			return false
		var found := false
		for owned: Variant in payload.party:
			if owned is Dictionary and owned.get("uid") == row.creature_uid:
				if found or not actor.equivalent(owned.get("hp"), row.hp) \
						or not actor.equivalent(owned.get("max_hp"), row.max_hp) or owned.get("fainted") != row.fainted:
					return false
				found = true
		if not found:
			return false
	return true


## Host EncounterHost caller only; packet values never reach this door.
func host_commit_creature_vitals(peer_id: int, creature_uid: String,
		expected_character_revision: int, expected_hp: float, expected_fainted: bool,
		next_hp: float, next_fainted: bool, host_receipt: Dictionary) -> Dictionary:
	if not is_host() or _authority_character(peer_id).is_empty() \
			or (_character_authority.call("state", _authority_character(peer_id)) as Dictionary).is_empty():
		return {"ok": false, "code": "not_admitted", "revision": -1}
	var character := _authority_character(peer_id)
	var stage: Dictionary = _character_authority.call("stage_creature_vitals", character, creature_uid,
		expected_character_revision, expected_hp, expected_fainted, next_hp, next_fainted, host_receipt)
	if not bool(stage.get("ok", false)) or bool(stage.get("duplicate", false)):
		return stage
	var accepted: Dictionary = _character_authority.call("staged_creature_vitals", stage)
	var transport := get_node_or_null(^"LedgerRpc")
	if transport == null:
		_character_authority.call("finish_creature_vitals", stage, false)
		return {"ok": false, "code": "ledger_not_prepared", "durable": false}
	var durable: Dictionary = transport.call("journal_actor_vitals_prepared", peer_id, character, accepted)
	var saved := bool(durable.get("ok", false))
	if not bool(_character_authority.call("finish_creature_vitals", stage, saved)):
		return {"ok": false, "code": "authority_stage_changed", "durable": saved}
	if not saved:
		return durable
	stage.erase("token")
	stage["accepted"] = accepted.duplicate(true)
	stage.accepted.durable = true
	stage["durable"] = true
	return stage


## Called only AFTER the exact pure EncounterHost actor commit. Publication
## may invoke owner saves or signals; it must never run inside the frozen CAS.
func host_finalize_creature_vitals(peer_id: int, creature_uid: String, receipt: Dictionary) -> bool:
	if not is_host():
		return false
	var transport := get_node_or_null(^"LedgerRpc")
	if transport == null:
		return false
	return bool(transport.call("publish_actor_vitals", peer_id, _authority_character(peer_id), creature_uid, receipt))


func admitted_pending_vitals(peer_id: int) -> Dictionary:
	if admitted_character_state(peer_id).is_empty():
		return {}
	return _character_authority.call("pending_creature_vitals", _authority_character(peer_id))


func host_ack_creature_vitals(peer_id: int, creature_uid: String,
		character_revision: int, receipt: Dictionary) -> bool:
	if admitted_character_state(peer_id).is_empty():
		return false
	return bool(_character_authority.call("acknowledge_creature_vitals", _authority_character(peer_id),
		creature_uid, character_revision, receipt))


func admitted_portal_keys(peer_id: int) -> Dictionary:
	if admitted_character_state(peer_id).is_empty():
		return {}
	return _character_authority.call("protected_keys", _authority_character(peer_id), _accepted_world_deliveries())


## Explicit staging for the existing synchronous LedgerRpc world-save boundary.
func host_stage_portal_debit(peer_id: int, biome: String, receipt: String) -> Dictionary:
	if admitted_character_state(peer_id).is_empty():
		return {"ok": false, "code": "not_admitted"}
	return _character_authority.call("stage_portal_debit", _authority_character(peer_id),
		biome, receipt, _accepted_world_deliveries())


func host_commit_portal_debit(stage: Dictionary) -> bool:
	return is_host() and bool(_character_authority.call("commit_portal_debit", stage))


func host_finish_portal_debit(stage: Dictionary, world_saved: bool) -> bool:
	return is_host() and bool(_character_authority.call("finish_portal_debit", stage, world_saved))


func _accepted_world_deliveries() -> Array:
	var game := _game()
	if game == null or game.get("world") == null:
		return []
	var records: Variant = game.get("world").get("reward_deliveries")
	return records.values() if records is Dictionary else []


func _authority_character(peer_id: int) -> String:
	if peer_id == local_peer_id():
		return _local_character_id()
	var row: Dictionary = _registry.call("row", peer_id)
	return str(row.get("character_id", ""))


func _bind_character_authority() -> bool:
	var game := _game()
	if game == null or game.get("world") == null:
		return false
	var raw: Variant = game.get("world").get("reward_delivery_namespace")
	# Existing Game snapshot bootstrap owns world identity creation. Use its
	# same host-only seam once when the identity is not yet established.
	if not raw is String or raw.is_empty():
		_world_snapshot()
		raw = game.get("world").get("reward_delivery_namespace")
	if not raw is String or not bool(_character_authority.call("bind_world", raw)): return false
	_character_authority.call("bind_portal_pending_reader", _pending_portal_for)
	return true


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


func _altar_current_epoch() -> String:
	if is_host(): return _altar_epoch
	var game := _game()
	return _altar_host_epoch if game != null and game.get("world") != null and game.get("world").reward_delivery_namespace == _altar_host_namespace else ""


@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_altar_epoch(epoch: String, world_namespace: String, character: String) -> void:
	if is_host() or not _altar_hex_id(epoch) or character != _local_character_id() or world_namespace.is_empty(): return
	_altar_host_epoch = epoch
	_altar_host_namespace = world_namespace


static func _altar_hex_id(raw: Variant) -> bool:
	if not raw is String or raw.length() != 32: return false
	for code: int in raw.to_utf8_buffer():
		if not (code >= 48 and code <= 57) and not (code >= 97 and code <= 102): return false
	return true


func _altar_envelope(op: String, key: String) -> Dictionary:
	var game := _game()
	if game == null or game.get("world") == null or _altar_current_epoch().is_empty(): return {}
	return {"op": op, "session_epoch": _altar_current_epoch(),
		"world_namespace": game.get("world").reward_delivery_namespace,
		"character_id": _local_character_id(), "station_key": key}


func _altar_envelope_matches(peer: int, envelope: Dictionary, fields: Array) -> bool:
	if not is_host() or envelope.size() != fields.size(): return false
	for field: String in fields:
		if not envelope.has(field): return false
	var character := _authority_character(peer)
	return not character.is_empty() and (peer == local_peer_id() or bool(_registry.call("has", peer))) \
		and envelope.character_id == character and envelope.session_epoch == _altar_epoch \
		and envelope.world_namespace == _game().get("world").reward_delivery_namespace \
		and ESSENCE._opaque_id(envelope.station_key)


## Trusted builder registration stores a weak node only. Each use rechecks
## committed UID, realm, ID, pose and the owning Homestead placement policy.
func _register_altar_station_node(key: String, building: Node3D) -> bool:
	if _altar_station_record(key, building).is_empty(): return false
	var prior: WeakRef = _altar_stations.get(key)
	if prior != null and prior.get_ref() != null and prior.get_ref() != building: return false
	_altar_stations[key] = weakref(building)
	return true


func _unregister_altar_station_node(key: String, building: Node3D) -> void:
	var prior: WeakRef = _altar_stations.get(key)
	if prior != null and prior.get_ref() == building: _altar_stations.erase(key)


func _altar_station_record(key: String, building: Node3D) -> Dictionary:
	var game := _game()
	if game == null or not is_instance_valid(building) or not building.is_inside_tree() \
			or not building.is_in_group("placed_building") or building.get_meta("building_id", "") != "altar" \
			or building.get_meta("realm", "") != "meadows" or not key.begins_with("altar:meadows:"): return {}
	var uid := key.trim_prefix("altar:meadows:")
	if not ESSENCE._component(uid) or not game.get("items").call("buildable", "altar") is Dictionary \
			or (game.get("items").call("buildable", "altar") as Dictionary).is_empty(): return {}
	var selected: Dictionary = {}
	for raw: Variant in game.get("world").placed_buildings:
		if raw is Dictionary and raw.get("uid") == uid:
			if not selected.is_empty(): return {}
			selected = raw.duplicate(true)
	if selected.get("id") != "altar" or selected.get("realm", "meadows") != "meadows" \
			or selected.get("removed", false) != false: return {}
	var position: Variant = selected.get("position")
	var yaw: Variant = selected.get("yaw_deg")
	if not position is Array or position.size() != 3 or not (yaw is int or yaw is float) \
			or not is_finite(float(yaw)): return {}
	for coordinate: Variant in position:
		if not (coordinate is int or coordinate is float) or not is_finite(float(coordinate)): return {}
	var authored := Vector3(float(position[0]), float(position[1]), float(position[2]))
	if building.global_position.distance_to(authored) > 0.01 \
			or absf(wrapf(rad_to_deg(building.global_rotation.y) - float(yaw), -180.0, 180.0)) > 0.01: return {}
	# Deliberately closed until the canonical owning build/plot validator is
	# wired. No duplicated farmhouse bounds or synthetic station fallback.
	if not game.has_method("altar_placement_is_authorized") \
			or game.call("altar_placement_is_authorized", selected, building) != true: return {}
	# Pending paid placement may register its real node after durable world publication; owner mutation/readiness guards still prevent its use.
	if TRAINING_WORLD.altar_paid_provenance(game.get("world").reward_deliveries, game.get("world").reward_delivery_namespace, game.get("world").world_id, selected, "", false).is_empty(): return {}
	return selected


func _altar_station_for_peer(peer: int, key: String) -> bool:
	var weak: WeakRef = _altar_stations.get(key)
	var building := weak.get_ref() as Node3D if weak != null else null
	if _altar_station_record(key, building).is_empty(): return false
	var transport := get_node_or_null(^"LedgerRpc")
	if transport == null: return false
	var context: Dictionary = transport.call("_water_actor_context", peer, {})
	if context.get("character_id") != _authority_character(peer) or context.get("realm") != "meadows" \
			or not context.get("position") is Vector3: return false
	if _altar_peer_in_combat(peer): return false
	var radius: Variant = ESSENCE.config().get("altar_interaction_radius_m")
	return (radius is int or radius is float) and is_finite(float(radius)) and float(radius) > 0.0 \
		and (context.position as Vector3).distance_to(building.global_position) <= float(radius)


func altar_station_available(key: String) -> bool:
	if ESSENCE.config().get("altar_runtime_enabled") != true or not ESSENCE.config().get("altar_runtime_enabled") is bool: return false
	if _owner_training_mutation_blocked(_game().get("local")) or not snapshot_ready(): return false
	if is_host(): return _altar_station_for_peer(local_peer_id(), key) and not admitted_character_state(local_peer_id()).is_empty()
	var weak: WeakRef = _altar_stations.get(key)
	return not _altar_current_epoch().is_empty() and weak != null \
		and not _altar_station_record(key, weak.get_ref() as Node3D).is_empty()


func quote_altar_essence_spend(key: String, uid: String, quote_id: String) -> Dictionary:
	if not _altar_hex_id(quote_id) or not ESSENCE._component(uid): return {"ok": false, "code": "invalid_quote"}
	var envelope := _altar_envelope("altar_quote", key)
	if envelope.is_empty(): return {"ok": false, "code": "authority_missing"}
	envelope["owned_uid"] = uid
	envelope["quote_id"] = quote_id
	_altar_quote_request = envelope.duplicate(true)
	if is_host(): return _handle_altar_quote(local_peer_id(), envelope)
	if not is_active(): return {"ok": false, "code": "authority_missing"}
	rpc_id(HOST_PEER_ID, "_rpc_altar_quote", envelope)
	return {"ok": false, "pending": true, "code": "quote_pending"}


func _handle_altar_quote(peer: int, envelope: Dictionary) -> Dictionary:
	if ESSENCE.config().get("altar_runtime_enabled") != true or not ESSENCE.config().get("altar_runtime_enabled") is bool: return {"ok": false, "code": "altar_not_ready"}
	if not _altar_envelope_matches(peer, envelope, ["op", "session_epoch", "world_namespace", "character_id", "station_key", "owned_uid", "quote_id"]) \
			or envelope.op != "altar_quote" or not _altar_hex_id(envelope.quote_id) \
			or not ESSENCE._component(envelope.owned_uid) or not _altar_station_for_peer(peer, envelope.station_key):
		return {"ok": false, "code": "station_unavailable"}
	if admitted_character_state(peer).is_empty(): return {"ok": false, "code": "not_admitted"}
	var character := _authority_character(peer)
	# Refresh/bind above uses the existing local owner, but prices and stage
	# ALWAYS use its full protected record, not the masked combat read view.
	return ESSENCE.quote_spend(_character_authority.call("state", character), character,
		envelope.owned_uid, int(_character_authority.call("revision", character)), ESSENCE.config(), PROGRESSION.config())


@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_altar_quote(envelope: Dictionary) -> void:
	if not is_host(): return
	var peer := multiplayer.get_remote_sender_id()
	var result := _handle_altar_quote(peer, envelope)
	if bool(_registry.call("has", peer)): rpc_id(peer, "_rpc_altar_quote_result", envelope, result)


@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_altar_quote_result(envelope: Dictionary, result: Dictionary) -> void:
	if is_host() or not ESSENCE._equivalent(envelope, _altar_quote_request) \
			or envelope.get("session_epoch") != _altar_current_epoch() \
			or envelope.get("character_id") != _local_character_id() \
			or envelope.get("world_namespace") != _game().get("world").reward_delivery_namespace: return
	_altar_quote_request = {}
	altar_essence_quote_completed.emit(envelope.station_key, envelope.owned_uid, envelope.quote_id, result.duplicate(true))


func submit_altar_essence_spend(key: String, intent: Dictionary) -> Dictionary:
	return _send_altar_spend("altar_spend", key, intent)


func reconcile_altar_essence_spend(key: String, intent: Dictionary) -> Dictionary:
	return _send_altar_spend("altar_reconcile", key, intent)


func _send_altar_spend(op: String, key: String, intent: Dictionary) -> Dictionary:
	var envelope := _altar_envelope(op, key)
	if envelope.is_empty(): return {"ok": false, "resolved": false, "code": "decision_unavailable"}
	envelope["intent"] = intent.duplicate(true)
	_altar_spend_request = envelope.duplicate(true)
	if is_host(): return _handle_altar_spend(local_peer_id(), envelope)
	if not is_active(): return {"ok": false, "resolved": false, "code": "decision_unavailable"}
	rpc_id(HOST_PEER_ID, "_rpc_altar_spend", envelope)
	return {"ok": false, "resolved": false, "code": "awaiting_saved_decision"}


func _handle_altar_spend(peer: int, envelope: Dictionary) -> Dictionary:
	var refuse := {"ok": false, "resolved": true, "durable": false, "saved": false, "code": "invalid_spend"}
	if not _altar_envelope_matches(peer, envelope, ["op", "session_epoch", "world_namespace", "character_id", "station_key", "intent"]) \
			or not envelope.op in ["altar_spend", "altar_reconcile"] or not envelope.intent is Dictionary: return refuse
	var intent: Dictionary = envelope.intent
	if intent.size() != 5 or not _altar_hex_id(intent.get("spend_id")): return refuse
	for field: String in ["creature_uid", "expected_level", "payment_item", "expected_character_revision"]:
		if not intent.has(field): return refuse
	var character := _authority_character(peer)
	var world: RefCounted = _game().get("world")
	var id := ESSENCE.training_delivery_id(world.reward_delivery_namespace, character)
	var row: Variant = world.reward_deliveries.get(id)
	if row is Dictionary and row.action_id == intent.spend_id:
		if not ESSENCE._equivalent(row.intent, intent): return refuse
		return _training_decision(peer, row)
	# An old spend may be superseded only after it was durably accepted.
	# Its complete eight-part receipt remains in the SAME personal history.
	if admitted_character_state(peer).is_empty(): return {"ok": false, "resolved": false, "code": "decision_unavailable"}
	var full: Dictionary = _character_authority.call("state", character)
	var revision := int(_character_authority.call("revision", character))
	var proposal := ESSENCE.stage_core_spend(full, character, revision, intent, ESSENCE.config(),
		PROGRESSION.config(), TEACHING.available_moves, TEACHING.character_loadout_mirror)
	if proposal.get("duplicate") == true and row is Dictionary and row.status == "accepted" and TRAINING_WORLD.training_row_valid(row, world.reward_delivery_namespace, world.world_id) and row.after.redesign_character.transaction_receipts.has(proposal.receipt):
		return {"ok": true, "resolved": true, "durable": true, "saved": true, "receipt": proposal.receipt,
			"character_revision": int(intent.expected_character_revision) + 1, "journal_revision": row.journal_revision}
	if proposal.get("duplicate") == true or envelope.op == "altar_reconcile":
		return {"ok": false, "resolved": false, "code": "decision_unavailable"}
	if proposal.get("ok") != true:
		refuse.code = proposal.get("code", "invalid_spend")
		return refuse
	if ESSENCE.config().get("altar_runtime_enabled") != true or not ESSENCE.config().get("altar_runtime_enabled") is bool:
		refuse.code = "altar_not_ready"
		return refuse
	if peer != local_peer_id() and (ESSENCE.config().get("altar_remote_spend_enabled") != true or not ESSENCE.config().get("altar_remote_spend_enabled") is bool):
		refuse.code = "remote_training_baseline_not_ready"
		return refuse
	if not _altar_station_for_peer(peer, envelope.station_key):
		refuse.code = "station_unavailable"
		return refuse
	var saver: RefCounted = _game().get("save_system")
	if saver == null: return refuse
	saver.call("finish_fallback") # All callbacks BEFORE re-freezing actual identity/state.
	if saver.call("fallback_busy") == true or not _altar_envelope_matches(peer, envelope,
		["op", "session_epoch", "world_namespace", "character_id", "station_key", "intent"]) \
		or not _altar_station_for_peer(peer, envelope.station_key) or admitted_character_state(peer).is_empty(): return refuse
	full = _character_authority.call("state", character)
	revision = int(_character_authority.call("revision", character))
	proposal = ESSENCE.stage_core_spend(full, character, revision, intent, ESSENCE.config(),
		PROGRESSION.config(), TEACHING.available_moves, TEACHING.character_loadout_mirror)
	var transport := get_node_or_null(^"LedgerRpc")
	var committed := ESSENCE.commit_host_training(_character_authority, transport, peer, character,
		"altar_spend", intent.spend_id, intent, proposal)
	if committed.get("durable") != true:
		refuse.code = committed.get("code", "training_journal_failed")
		return refuse
	transport.call("publish_creature_training", peer, character, committed.receipt)
	return {"ok": false, "resolved": false, "durable": true, "saved": false,
		"receipt": committed.receipt, "code": "awaiting_saved_decision"}


@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_altar_spend(envelope: Dictionary) -> void:
	if not is_host(): return
	var peer := multiplayer.get_remote_sender_id()
	var result := _handle_altar_spend(peer, envelope)
	if bool(_registry.call("has", peer)): rpc_id(peer, "_rpc_altar_spend_result", envelope, result)


@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_altar_spend_result(envelope: Dictionary, result: Dictionary) -> void:
	if is_host() or not ESSENCE._equivalent(envelope, _altar_spend_request) \
			or envelope.get("session_epoch") != _altar_current_epoch() \
			or envelope.get("character_id") != _local_character_id() \
			or envelope.get("world_namespace") != _game().get("world").reward_delivery_namespace: return
	# A reply is correlation/presentation only, never a portable state import.
	if result.get("ok") == true:
		var row := _owner_training_row()
		if row.is_empty() or _training_decision(local_peer_id(), row).get("ok") != true \
				or not row.after.redesign_character.transaction_receipts.has(result.get("receipt")): return
	altar_essence_spend_completed.emit(envelope.station_key, envelope.intent.spend_id, result.duplicate(true))


func host_ack_creature_training(peer: int, row: Dictionary) -> bool:
	var world: RefCounted=_game().get("world")
	if row.get("status")!="accepted" or not ESSENCE._equivalent(world.reward_deliveries.get(row.get("delivery_id")),row): return false
	var character := _authority_character(peer)
	if character.is_empty() or character != row.get("character_id"): return false
	if _character_authority.call("creature_training_is_pending", character) != true:
		# A recovered saved marker is history, not permission to rewrite live HP.
		return _character_authority.call("acknowledge_creature_training", character, row) == true
	if _character_authority.call("creature_training_pending_matches", character, row) != true: return false
	if row.get("kind") == "altar_building": return _character_authority.call("acknowledge_creature_training", character, row) == true
	var bundle: Dictionary=_training_actor_baseline_proposals(peer,row)
	if bundle.get("ok")!=true: return false
	# Private actor commits have no publishing/reentrant callback. All proposed
	# changes were checked before the accepted row's writer and again here.
	for proposal: Dictionary in bundle.proposals:
		if proposal.host.call("commit_actor_training_baseline",proposal.stage,row,bundle.admitted,
			bundle.revision,world.reward_deliveries,world.reward_delivery_namespace,world.world_id)!=true: return false
	return _character_authority.call("acknowledge_creature_training",_authority_character(peer),row)==true


func _training_decision(peer: int, row: Dictionary) -> Dictionary:
	var world: RefCounted = _game().get("world")
	if not TRAINING_WORLD.training_row_valid(row, world.reward_delivery_namespace, world.world_id) \
			or row.character_id != _authority_character(peer) \
			or not ESSENCE._equivalent(world.reward_deliveries.get(row.delivery_id), row):
		return {"ok": false, "resolved": false, "code": "decision_unavailable"}
	if row.status != "accepted" or (is_host() and _character_authority.call("creature_training_is_pending", str(row.character_id)) == true):
		return {"ok": false, "resolved": false, "durable": true, "saved": false,
			"receipt": row.receipt, "code": "awaiting_saved_decision"}
	if peer == local_peer_id() and not _game().get("local").redesign_character.transaction_receipts.has(row.receipt):
		return {"ok": false, "resolved": false, "code": "decision_unavailable"}
	return {"ok": true, "resolved": true, "durable": true, "saved": true, "receipt": row.receipt,
		"character_revision": row.character_revision, "journal_revision": row.journal_revision}


func _deliver_training_decision(peer: int, row: Dictionary) -> void:
	if not is_host(): return
	if peer == local_peer_id():
		_settle_owner_training_accepted(_game().get("local"), _game().get("world"), row)
	elif bool(_registry.call("has", peer)):
		rpc_id(peer, "_rpc_training_decision", _altar_epoch, row.delivery_id, int(row.journal_revision), row.receipt)


@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_training_decision(epoch: String, id: String, revision: int, receipt: String) -> void:
	if is_host() or epoch != _altar_current_epoch(): return
	# Host published its saved accepted delta first on this SAME channel.
	# While bootstrap is closed that delta is queued; finish the existing path.
	if _training_bootstrap_waiting:
		_finalize_snapshot_receive()
	var row := _owner_training_row()
	if row.get("delivery_id") == id and row.get("journal_revision") == revision and row.get("receipt") == receipt:
		_settle_owner_training_accepted(_game().get("local"), _game().get("world"), row)


## One local pending identity points at the durable row already in WorldState.
## It stores no party/inventory/balance or alternative receipt history.
func _owner_training_row() -> Dictionary:
	var game := _game()
	if game == null or not game.get("local") is RefCounted or not game.get("world") is RefCounted: return {}
	var world: RefCounted = game.get("world")
	var character := str(game.get("local").character_id)
	return TRAINING_WORLD.training_owner_row(world.reward_deliveries, world.reward_delivery_namespace, world.world_id, character)


func _owner_training_mutation_blocked(player: RefCounted) -> bool:
	var game := _game()
	if game == null or player == null or player != game.get("local"): return false
	var row := _owner_training_row()
	if _pending_portal_for(str(player.character_id)): return true
	if is_host() and _character_authority.call("creature_training_is_pending", str(player.character_id)) == true:
		return true
	if row.is_empty(): return not _owner_training_retry.is_empty() # Missing recovery truth cannot unlock.
	if row.status == "pending": return true
	return not _owner_training_retry.is_empty()


## Compose the existing input-owner and story-modal graph; closing Altar UI
## cannot unlock movement/menu/care while a real saved decision is pending.
func owns_input() -> bool:
	return _game() != null and _owner_training_mutation_blocked(_game().get("local"))


func is_open() -> bool:
	return owns_input()


func _bind_training_container_guards() -> void:
	var game := _game()
	if game == null or not game.get("local") is RefCounted: return
	var player: RefCounted = game.get("local")
	var inv: Variant = player.get("inventory")
	var party: Variant = player.get("party")
	if inv is RefCounted and inv.has_method("bind_owner_mutation_guard"):
		inv.call("bind_owner_mutation_guard", _owner_training_mutation_blocked.bind(player),
			_owner_training_inventory_write_allowed.bind(player))
	if party is RefCounted and party.has_method("bind_owner_mutation_guard"):
		party.call("bind_owner_mutation_guard", _owner_training_mutation_blocked.bind(player))


func _retain_owner_training_retry(player: RefCounted, world: RefCounted, row: Dictionary) -> bool:
	var game := _game()
	if game == null or game.get("local") != player or game.get("world") != world \
			or not ESSENCE._equivalent(_owner_training_row(), row) or row.status != "pending": return false
	if not _owner_training_retry.is_empty() and (_owner_training_retry.player.get_ref() != player \
		or _owner_training_retry.world.get_ref() != world or _owner_training_retry.receipt != row.receipt): return false
	_owner_training_retry = {"player": weakref(player), "world": weakref(world),
		"delivery_id": row.delivery_id, "journal_revision": row.journal_revision, "receipt": row.receipt,
		"saved": _owner_training_retry.get("saved", false)}
	_bind_training_container_guards()
	return true


func _begin_owner_training_install(player: RefCounted, world: RefCounted, row: Dictionary) -> bool:
	if _owner_training_retry.is_empty() or _owner_training_retry.player.get_ref() != player \
			or _owner_training_retry.world.get_ref() != world or _owner_training_retry.receipt != row.receipt \
			or not ESSENCE._equivalent(_owner_training_row(), row): return false
	_owner_training_install = true
	return true


func _end_owner_training_install() -> void:
	_owner_training_install = false


func _owner_training_inventory_write_allowed(index: int, stack: Variant, player: RefCounted) -> bool:
	if _owner_portal_inventory_write_allowed(index, stack, player): return true
	var row := _owner_training_row()
	return _owner_training_install and not _owner_training_retry.is_empty() \
		and _owner_training_retry.player.get_ref() == player and row.status == "pending" \
		and _owner_training_retry.receipt == row.receipt and index >= 0 and index < row.after.inventory.size() \
		and ESSENCE._equivalent(row.after.inventory[index], stack)


func _mark_owner_training_saved(player: RefCounted, world: RefCounted, row: Dictionary) -> bool:
	if _owner_training_retry.is_empty() or _owner_training_retry.player.get_ref() != player \
			or _owner_training_retry.world.get_ref() != world or _owner_training_retry.receipt != row.receipt \
			or not ESSENCE._equivalent(_owner_training_row(), row) \
			or not ESSENCE._equivalent(ESSENCE.training_projection(player.call("save_data")), row.after): return false
	_owner_training_retry.saved = true
	return true


func _owner_training_snapshot_allowed(player: RefCounted, payload: Dictionary) -> bool:
	if _pending_portal_for(str(player.character_id)):
		return not _owner_portal_conflicting_transaction(player) and _owner_portal_snapshot_allowed(player, payload)
	if not _owner_training_mutation_blocked(player): return true
	var row := _owner_training_row()
	return not row.is_empty() and payload.get("character_id") == player.get("character_id") \
		and ESSENCE._equivalent(ESSENCE.training_projection(payload), row.after) \
		and payload.redesign_character.transaction_receipts.has(row.receipt)


func _settle_owner_training_accepted(player: RefCounted, world: RefCounted, row: Dictionary) -> bool:
	if _game() == null or _game().get("local") != player or _game().get("world") != world \
			or row.get("status") != "accepted" or not ESSENCE._equivalent(_owner_training_row(), row) \
			or not player.redesign_character.transaction_receipts.has(row.receipt): return false
	if is_host() and _character_authority.call("creature_training_is_pending", str(player.character_id)) == true: return false
	if not _owner_training_retry.is_empty():
		if _owner_training_retry.player.get_ref() != player or _owner_training_retry.world.get_ref() != world \
			or _owner_training_retry.receipt != row.receipt or _owner_training_retry.saved != true \
			or not ESSENCE._equivalent(ESSENCE.training_projection(player.call("save_data")), row.after): return false
		_owner_training_retry = {}
	if not _altar_spend_request.is_empty() and _altar_spend_request.get("intent", {}).get("spend_id") == row.action_id:
		var request := _altar_spend_request.duplicate(true)
		_altar_spend_request = {}
		altar_essence_spend_completed.emit(request.station_key, row.action_id,
			_training_decision(local_peer_id(), row))
	return true


func _altar_peer_in_combat(peer: int) -> bool:
	var root := get_tree().current_scene
	if root == null: return true
	var nodes: Array[Node] = [root]
	var found_host := false
	var found_local_manager := false
	while not nodes.is_empty():
		var node: Node = nodes.pop_back()
		for child: Node in node.get_children(): nodes.append(child)
		var script: Script = node.get_script()
		if script != null and script.resource_path == "res://scripts/combat/encounter_director.gd":
			var host: Variant = node.get("_encounter_host")
			if host is RefCounted and host.has_method("record") and host.has_method("is_participant"):
				found_host = true
				var records: Variant = host.get("encounters")
				if not records is Dictionary: return true
				for id: Variant in records:
					var record: Variant = records[id]
					if not record is Dictionary: return true
					if record.get("phase") != "done" and host.call("is_participant", str(id), peer) == true: return true
		if peer == local_peer_id() and script != null and script.resource_path == "res://scripts/combat/combat_manager.gd":
			if not node.has_method("is_fighting"): return true
			found_local_manager = true
			if node.call("is_fighting") == true: return true
	return not found_host if peer != local_peer_id() else not found_local_manager


func _training_actor_baseline_proposals(peer: int, training: Dictionary) -> Dictionary:
	var game:=_game()
	if not is_host() or game==null or game.get("world")==null or get_tree().current_scene==null: return {"ok":false}
	var world: RefCounted=game.get("world")
	var character:=_authority_character(peer)
	if character.is_empty() or character!=training.get("character_id") \
		or not TRAINING_WORLD.training_row_valid(training,world.reward_delivery_namespace,world.world_id): return {"ok":false}
	var admitted: Dictionary=_character_authority.call("state",character)
	var revision:=int(_character_authority.call("revision",character))
	var nodes: Array[Node]=[get_tree().current_scene]
	var seen: Dictionary={}
	var proposals: Array[Dictionary]=[]
	while not nodes.is_empty():
		var node: Node=nodes.pop_back()
		for child: Node in node.get_children(): nodes.append(child)
		var script: Script=node.get_script()
		if script==null or not script.resource_path in ["res://scripts/combat/encounter_director.gd","res://scripts/combat/stormwood_encounter_director.gd"]: continue
		var host: Variant=node.get("_encounter_host")
		if not host is RefCounted or not host.has_method("stage_actor_training_baseline"): return {"ok":false}
		if seen.has(host.get_instance_id()): continue
		seen[host.get_instance_id()]=true
		var stage: Dictionary=host.call("stage_actor_training_baseline",training,admitted,revision,world.reward_delivery_namespace,world.world_id)
		if stage.get("ok")!=true: return {"ok":false,"code":stage.get("code")}
		proposals.append({"host":host,"stage":stage})
	return {"ok":not proposals.is_empty(),"proposals":proposals,"admitted":admitted,"revision":revision}

func training_actor_baseline_ready(peer: int, training: Dictionary) -> bool:
	if training.get("kind") == "altar_building": return TRAINING_WORLD.altar_build_row_valid(training, _game().get("world").reward_delivery_namespace, _game().get("world").world_id) and training.character_id == _authority_character(peer)
	return _training_actor_baseline_proposals(peer,training).get("ok")==true


## OFF until the coherent paid placement+mounted training path is proved.
## Method presence does not authorize a free or client-priced placement.
func altar_canonical_producer_available() -> bool:
	var cfg := ESSENCE.config()
	var game := _game()
	return cfg.get("altar_runtime_enabled") is bool and cfg.altar_runtime_enabled == true \
		and cfg.get("altar_building_runtime_enabled") is bool and cfg.altar_building_runtime_enabled == true \
		and not TRAINING_WORLD.altar_recipe().is_empty() and game != null and game.get("world") != null \
		and not str(game.get("world").reward_delivery_namespace).is_empty() \
		and get_node_or_null(^"LedgerRpc") != null and game.has_method("altar_placement_is_authorized")


func altar_building_placement_available() -> bool:
	var cfg := ESSENCE.config()
	return cfg.get("altar_building_runtime_enabled") is bool and cfg.altar_building_runtime_enabled == true \
		and cfg.get("altar_runtime_enabled") is bool and cfg.altar_runtime_enabled == true \
		and not TRAINING_WORLD.altar_recipe().is_empty() and _game() != null and snapshot_ready() \
		and not _owner_training_mutation_blocked(_game().get("local")) \
		and (is_host() or cfg.get("altar_remote_spend_enabled") == true)


## Existing place/dismantle ingress calls this only after sender resolution.
## Request supplies a pose or UID, never stock, recipe, character or proposed state.
func host_altar_building(peer: int, request: Dictionary) -> Dictionary:
	var refusal := {"ok": false, "pending": false, "kind": request.get("kind", ""), "peer": peer,
		"code": "altar_not_ready", "reason": "Altar building is not ready yet.", "txn_id": request.get("txn_id", ""), "delta": {"ops": []}}
	if not is_host() or not _altar_hex_id(request.get("txn_id")) or request.get("realm") != "meadows": return refusal
	var game := _game()
	var character := _authority_character(peer)
	if game == null or character.is_empty(): return refusal
	var world: RefCounted = game.get("world")
	if not ESSENCE._integer(world.next_building_uid, 1, 2147483646): return refusal
	var id := TRAINING_WORLD.altar_build_id(world.reward_delivery_namespace, character, request.txn_id)
	var prior: Variant = world.reward_deliveries.get(id)
	if prior is Dictionary:
		# Reconcile the frozen ID before probing a now-removed building or stock.
		if not TRAINING_WORLD.altar_build_row_valid(prior, world.reward_delivery_namespace, world.world_id) \
			or not ESSENCE._equivalent(prior.intent.request, request):
			refusal.code = "building_receipt_conflict"
			return refusal
		var transport := get_node_or_null(^"LedgerRpc")
		if transport != null: transport.call("_process_creature_training", prior)
		return {"ok": true, "pending": true, "kind": prior.action, "peer": peer, "code": "duplicate",
			"reason": "", "txn_id": prior.action_id, "uid": prior.intent.record.uid, "delta": {"ops": []}}
	if not altar_building_placement_available() or peer != local_peer_id():
		# Actual remote full-state care/buff drift remains a closed dependency.
		return refusal
	var saver: RefCounted = game.get("save_system")
	if saver == null: return refusal
	saver.call("finish_fallback")
	if saver.call("fallback_busy") == true or _authority_character(peer) != character \
		or not altar_building_placement_available() or _altar_peer_in_combat(peer) \
		or admitted_character_state(peer).is_empty(): return refusal
	var actor: Node3D = game.call("_find_player") as Node3D
	if not is_instance_valid(actor) or not actor.is_inside_tree() or not actor.global_position.is_finite() \
		or game.get("current_realm") != "meadows": return refusal
	var full: Dictionary = _character_authority.call("state", character)
	var revision := int(_character_authority.call("revision", character))
	var record: Dictionary = {}
	var placer: Node
	for node: Node in get_tree().get_nodes_in_group("build_placer"):
		if node.is_inside_tree() and get_tree().current_scene.is_ancestor_of(node) \
			and node.get_script() != null and node.get_script().resource_path == "res://scripts/build/build_placer.gd":
			if placer != null: return refusal
			placer = node
	if placer == null: return refusal
	if request.get("kind") == "place_building":
		if request.size() != 7 or request.get("id") != "altar" or request.get("paid") != true \
			or not request.get("position") is Array or request.position.size() != 3 \
			or not (request.get("yaw_deg") is int or request.get("yaw_deg") is float) \
			or not is_finite(float(request.yaw_deg)): return refusal
		for cell: Variant in request.position:
			if not (cell is int or cell is float) or not is_finite(float(cell)): return refusal
		var position := Vector3(float(request.position[0]), float(request.position[1]), float(request.position[2]))
		var inv := preload("res://scripts/world/death_satchel_rules.gd").inventory_from(full.inventory)
		var plan: Dictionary = placer.call("validate_altar_placement", game, "meadows", position, float(request.yaw_deg), inv, actor)
		if plan.get("ok") != true or not ESSENCE._equivalent(plan.get("cost"), TRAINING_WORLD.altar_recipe()): return refusal
		record = {"id": "altar", "realm": "meadows", "uid": "b%d" % int(world.next_building_uid),
			"position": plan.position.duplicate(true), "yaw_deg": plan.yaw_deg, "paid": true}
	elif request.get("kind") == "dismantle":
		if request.size() != 4 or not request.get("uid") is String: return refusal
		var key := "altar:meadows:" + request.uid
		var weak: WeakRef = _altar_stations.get(key)
		var building := weak.get_ref() as Node3D if weak != null else null
		if not is_instance_valid(building) or not _altar_station_for_peer(peer, key): return refusal
		var resolved: Dictionary = placer.call("resolve_altar_station", game, key, building)
		if resolved.get("ok") != true: return refusal
		record = resolved.record.duplicate(true)
		if TRAINING_WORLD.altar_paid_provenance(world.reward_deliveries, world.reward_delivery_namespace, world.world_id, record, character).is_empty(): return refusal
	else: return refusal
	var proposal := TRAINING_WORLD.altar_build_transition(full, character, revision, request.kind,
		request.txn_id, record, world.reward_delivery_namespace)
	if proposal.is_empty():
		refusal.code = "building_stock_or_receipt_refused"
		return refusal
	var stage: Dictionary = _character_authority.call("stage_altar_building", character, proposal)
	if stage.get("ok") != true:
		refusal.code = stage.get("code", "building_stage_refused")
		return refusal
	var transport := get_node_or_null(^"LedgerRpc")
	var result: Dictionary = transport.call("journal_altar_building_prepared", peer, stage, request) if transport != null else {}
	if _character_authority.call("finish_creature_training", stage, result.get("durable") == true) != true: return refusal
	if result.get("durable") != true:
		refusal.code = result.get("code", "building_journal_failed")
		return refusal
	transport.call("publish_altar_building", peer, character, result.delivery_id, stage.receipt)
	return result.verdict


## Cost/refund-only owner import. Party/body objects are never replaced or
## rewritten by a building delivery. Every replay still performs a bool save.
func apply_altar_building_owner(row: Dictionary) -> Dictionary:
	var game := _game()
	var saver: RefCounted = game.get("save_system") if game != null else null
	if saver == null or not saver.has_method("save_character_prepared"): return {"ok": false}
	saver.call("finish_fallback")
	if saver.call("fallback_busy") == true or game != _game(): return {"ok": false}
	var player: RefCounted = game.get("local")
	var world: RefCounted = game.get("world")
	if not TRAINING_WORLD.altar_build_row_valid(row, world.reward_delivery_namespace, world.world_id) \
		or row.character_id != player.get("character_id") or row.status != "pending" \
		or not ESSENCE._equivalent(world.reward_deliveries.get(row.delivery_id), row): return {"ok": false}
	var snapshot: Dictionary = player.call("save_data")
	var projected := ESSENCE.training_projection(snapshot)
	var applied: bool = snapshot.redesign_character.transaction_receipts.has(row.receipt)
	if not ESSENCE._equivalent(projected, row.after if applied else row.before): return {"ok": false}
	if not _retain_owner_training_retry(player, world, row) or not _begin_owner_training_install(player, world, row): return {"ok": false}
	if not applied:
		for index: int in row.after.inventory.size():
			var stack: Variant = row.after.inventory[index]
			if not ESSENCE._equivalent(snapshot.inventory[index], stack):
				player.get("inventory").call("set_slot", index, stack.duplicate(true) if stack is Dictionary else null)
		player.set("redesign_character", row.after.redesign_character.duplicate(true))
	_end_owner_training_install()
	if not ESSENCE._equivalent(ESSENCE.training_projection(player.call("save_data")), row.after) \
		or saver.call("save_character_prepared", game, str(player.character_id)) != true:
		return {"ok": false, "pending": true, "code": "owner_building_save_failed"}
	if not _mark_owner_training_saved(player, world, row): return {"ok": false, "saved": true}
	return {"ok": true, "saved": true}

## Actual owning world and SAME prepared writers, including offline solo.
## Presence alone is not capability: the coherent runtime opt-in stays OFF.
func _host_wild_training_context() -> Dictionary:
	var unavailable := {"ready": false}
	var game := _game()
	var cfg := ESSENCE.config()
	if not is_host() or game == null or game.get("session") != self \
		or not cfg.get("wild_victory_runtime_enabled") is bool or cfg.wild_victory_runtime_enabled != true \
		or not game.get("world") is RefCounted or not game.get("local") is RefCounted \
		or not _bind_character_authority(): return unavailable
	var world: RefCounted = game.get("world")
	var saver: RefCounted = game.get("save_system")
	var transport := get_node_or_null(^"LedgerRpc")
	if saver == null or not saver.has_method("save_world_prepared") \
		or not saver.has_method("save_character_prepared") or transport == null \
		or not transport.has_method("journal_creature_training_prepared") \
		or not ESSENCE._opaque_id(world.get("world_id")) \
		or not ESSENCE._opaque_id(world.get("reward_delivery_namespace")) \
		or not ESSENCE._opaque_id(_altar_epoch): return unavailable
	return {"ready": true, "world_id": str(world.world_id),
		"world_namespace": str(world.reward_delivery_namespace), "session_id": _altar_epoch}


## Resolve the real mounted runtime's ORIGINAL retained capture, never a
## claimed dead enemy/participant packet. Combat owns this read-only seam.
## Missing source/lifecycle producer closes this actual door.
func _retained_host_wild_source(frozen: Dictionary) -> Dictionary:
	var context := _host_wild_training_context()
	if context.get("ready") != true or get_tree().current_scene == null \
		or frozen.get("world_id") != context.world_id \
		or frozen.get("world_namespace") != context.world_namespace \
		or frozen.get("session_id") != context.session_id \
		or not frozen.get("record") is Dictionary: return {}
	var id: Variant = frozen.record.get("encounter_id")
	if not id is String or id.is_empty(): return {}
	var nodes: Array[Node] = [get_tree().current_scene]
	var found: Dictionary = {}
	while not nodes.is_empty():
		var node: Node = nodes.pop_back()
		for child: Node in node.get_children(): nodes.append(child)
		if node.get_script() == null or node.get_script().resource_path != "res://scripts/combat/encounter_director.gd": continue
		if not node.has_method("host_wild_victory_source"): continue
		var retained: Variant = node.call("host_wild_victory_source", id)
		if not retained is Dictionary or not ESSENCE._equivalent(retained, frozen): continue
		if not found.is_empty(): return {} # Never resolve an ambiguous host.
		var host: Variant = node.get("_encounter_host")
		if not host is RefCounted or not host.has_method("record"): return {}
		var current: Dictionary = host.call("record", id)
		if current.get("phase") != "done" or current.get("kind") != "wild" \
			or not current.get("opponent") is Dictionary or not frozen.record.get("opponent") is Dictionary \
			or not ESSENCE._equivalent(current.opponent, frozen.record.opponent) \
			or not current.get("participants") is Dictionary: return {}
		# Departure may move lifetime records to the existing retained map;
		# initial solo scope intentionally requires the actual current owner.
		found = {"director": node, "host": host, "current": current}
	return found


## Host-internal only; no reward RPC and no new source/balance store. The
## combat runtime retains ORIGINAL source through refusal, disconnect and
## terminal rendering. Existing saved rows are the only durable recovery.
func _commit_host_wild_victory(frozen: Dictionary) -> Dictionary:
	var refused := {"ok": false, "durable": false, "resolved": false, "code": "wild_training_unavailable"}
	var source := _retained_host_wild_source(frozen)
	if source.is_empty() or not frozen.get("record", {}).get("participants") is Dictionary \
		or not frozen.get("deployments") is Array: return refused
	var participants: Dictionary = frozen.record.participants
	# Current full-state care/bond/condition reconciliation remains a remote
	# activation blocker. Do not pay only the host and silently discard peers.
	if participants.size() != 1 or not participants.has(local_peer_id()):
		refused.code = "remote_training_baseline_not_ready"
		return refused
	var peer := local_peer_id()
	var character := _authority_character(peer)
	var participant: Variant = participants[peer]
	if character.is_empty() or not participant is Dictionary \
		or participant.get("character_id") != character: return refused
	var game := _game()
	var saver: RefCounted = game.get("save_system")
	if saver == null: return refused
	saver.call("finish_fallback") # Callbacks before refreezing source/state.
	if saver.call("fallback_busy") == true or _authority_character(peer) != character \
		or _retained_host_wild_source(frozen).is_empty() \
		or admitted_character_state(peer).is_empty(): return refused
	var world: RefCounted = game.get("world")
	var full: Dictionary = _character_authority.call("state", character)
	var revision := int(_character_authority.call("revision", character))
	var proposal := ESSENCE.stage_captured_host_victory(full, character, revision, peer, frozen,
		ESSENCE.config(), PROGRESSION.config(), TEACHING.available_moves, TEACHING.character_loadout_mirror)
	if proposal.get("ok") != true: return proposal
	var id := ESSENCE.training_delivery_id(world.reward_delivery_namespace, character)
	var old: Variant = world.reward_deliveries.get(id)
	var transport := get_node_or_null(^"LedgerRpc")
	if proposal.get("duplicate") == true:
		# A later accepted row can supersede this original event, but only its
		# exact immutable personal receipt proves prior durable application.
		if not TRAINING_WORLD.training_row_valid(old, world.reward_delivery_namespace, world.world_id) \
			or not old.after.redesign_character.transaction_receipts.has(proposal.receipt): return refused
		if old.get("action_id") == frozen.get("source_id"):
			if old.status == "pending" and transport != null: transport.call("_process_creature_training", old)
			return {"ok": true, "durable": true, "resolved": old.status == "accepted",
				"receipt": proposal.receipt, "delivery_id": old.delivery_id}
		if old.status != "accepted": return refused
		return {"ok": true, "durable": true, "resolved": true, "receipt": proposal.receipt,
			"code": "previous_saved_event"}
	if transport == null or proposal.get("action") != "wild_defeat" \
		or proposal.get("action_id") != frozen.get("source_id"): return refused
	var committed := ESSENCE.commit_host_training(_character_authority, transport, peer, character,
		"wild_defeat", proposal.action_id, proposal.intent, proposal)
	if committed.get("durable") != true: return committed
	# Same typed owner importer/real bool-save/receipt-only ACK as Altar.
	# Return only transfer durability; completion UI never causes a second XP.
	transport.call("publish_creature_training", peer, character, committed.receipt)
	return {"ok": true, "durable": true, "resolved": false, "receipt": committed.receipt,
		"delivery_id": committed.delivery_id, "code": "awaiting_saved_decision"}

## Appended to the existing Session; all state remains its existing admission
## registry, WorldState.reward_deliveries and the owner's transaction receipts.
const PORTAL_POLICY := preload("res://scripts/net/portal_action_policy.gd")
const PORTAL_RECEIPT := preload("res://scripts/net/portal_delivery.gd")
var _portal_policy: RefCounted = PORTAL_POLICY.new()
var _portal_request_serial := 0
var _portal_requests: Dictionary = {}
var _portal_waiters: Dictionary = {}


func portal_runtime_ready() -> bool:
	return config().get("redesign_portal_runtime_enabled", false) == true


func portal_character_state() -> Dictionary:
	var game := _game()
	if game == null or game.get("local") == null: return {}
	var player: RefCounted = game.get("local")
	return {"character_id": player.character_id,
		"waystones_activated": player.redesign_character.waystones_activated.duplicate(true),
		"last_waystones": player.redesign_character.last_waystones.duplicate(true)}


func portal_view(arch_id: String) -> Dictionary:
	var unavailable := {"ready": false, "open": false, "has_key": false, "fifth_arch_stirred": false}
	var game := _game()
	if not portal_runtime_ready() or game == null or game.get("local") == null or game.get("world") == null: return unavailable
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/portals.json"))
	if not raw is Dictionary: return unavailable
	var arch := PORTAL_POLICY._find_arch(raw, arch_id)
	if arch.is_empty(): return unavailable
	var player: RefCounted = game.get("local")
	var world: RefCounted = game.get("world")
	var biome: String = arch.biome
	var stirred := false
	for row: Variant in player.satchel_escrow.values():
		if PORTAL_RECEIPT.valid(row, player.character_id) and row.biome == "biome5" and row.status == "settled": stirred = true
	return {"ready": not player.character_id.is_empty(), "open": arch.kind == "live" and
		(biome == "meadows" or world.redesign_world.portal_unlocks.has(biome) or player.redesign_character.portal_unlocks.has(biome)),
		"has_key": not str(arch.key_item).is_empty() and player.inventory.count(arch.key_item) == 1,
		"fifth_arch_stirred": stirred or world.redesign_world.fifth_arch_stirred,
		"destination_label": preload("res://scripts/data/biome_order.gd").display_name(biome),
		"recommended_level": arch.get("recommended_level", 0)}


func request_portal_action(payload: Dictionary) -> Dictionary:
	if not portal_runtime_ready() or not PORTAL_POLICY.valid_payload(payload): return {"ok": false, "reason": "Travel is not ready yet."}
	var game := _game()
	if game == null or game.get("world") == null or game.get("local") == null: return {"ok": false, "reason": "Your character is not ready."}
	var world: RefCounted = game.get("world")
	var character := str(game.get("local").character_id)
	var generation := _altar_current_epoch()
	if character.is_empty() or world.reward_delivery_namespace.is_empty() or generation.is_empty(): return {"ok": false, "reason": "Your character is still joining."}
	_portal_request_serial += 1
	var id := "%s:%d" % [generation, _portal_request_serial]
	var frozen := {"request_id": id, "world_instance_id": world.reward_delivery_namespace,
		"session_epoch": generation, "character_id": character, "payload": payload.duplicate(true)}
	_portal_requests[id] = frozen.duplicate(true)
	if is_host(): _host_portal_action.call_deferred(local_peer_id(), frozen)
	else: _send_portal_action.call_deferred(frozen)
	return {"ok": true, "request_id": id}


func _send_portal_action(frozen: Dictionary) -> void:
	if is_host() or not is_active() or frozen.session_epoch != _altar_current_epoch(): return
	rpc_id(HOST_PEER_ID, "_rpc_portal_action", frozen.duplicate(true))


@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_portal_action(envelope: Dictionary) -> void:
	if is_host(): _host_portal_action(multiplayer.get_remote_sender_id(), envelope)


func _portal_envelope_valid(peer: int, envelope: Dictionary) -> bool:
	var game := _game()
	return (is_host() and portal_runtime_ready() and game != null and game.get("world") != null and
		envelope.size() == 5 and envelope.get("request_id") is String and envelope.request_id.length() <= 192 and
		envelope.request_id.begins_with(_altar_epoch + ":") and envelope.get("session_epoch") == _altar_epoch and
		envelope.get("character_id") == _authority_character(peer) and not str(envelope.character_id).is_empty() and
		envelope.get("world_instance_id") == game.get("world").reward_delivery_namespace and
		envelope.get("payload") is Dictionary and PORTAL_POLICY.valid_payload(envelope.payload))


func _host_portal_action(peer: int, envelope: Dictionary) -> void:
	if not _portal_envelope_valid(peer, envelope): return
	var context := _host_portal_context(peer)
	if context.is_empty():
		_portal_reply(peer, envelope, {"ok": false, "reason": "Your authoritative travel state is not ready."})
		return
	var cfg: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/portals.json"))
	var stones: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/waystones.json"))
	if not cfg is Dictionary or not stones is Dictionary: return
	_portal_policy.call("bind_world", envelope.world_instance_id)
	var result: Dictionary = _portal_policy.call("evaluate", envelope.payload.duplicate(true), context, cfg, stones, Time.get_ticks_msec())
	if result.get("ok") != true:
		_portal_reply(peer, envelope, result)
		return
	match str(envelope.payload.kind):
		"portal_unlock":
			_commit_portal_unlock(peer, envelope, result.prepared)
		"waystone_touch":
			_commit_waystone_touch(peer, envelope, result.prepared)
		"home_key_begin", "home_key_cancel":
			_portal_reply(peer, envelope, result)
		"home_key_finish", "portal_enter":
			# Consume and carry only the host-minted destination permit. The
			# actual movement/grounded durable arrival consumer is a separate
			# gate; an issued permit cannot be reported as an arrival success.
			_portal_reply(peer, envelope, {"ok": false, "reason": "The grounded arrival consumer is not ready."})


func _commit_portal_unlock(peer: int, envelope: Dictionary, result: Dictionary) -> void:
	var game := _game()
	var saver: RefCounted = game.get("save_system")
	if saver == null or not bool(saver.call("finish_fallback")) or saver.call("fallback_busy") == true:
		_portal_reply(peer, envelope, {"ok": false, "reason": "Your save is still being written."})
		return
	# Flush can deliver callbacks, so re-read all current binding/state before
	# freezing the debit; no mutable envelope survives across that callback.
	if not _portal_envelope_valid(peer, envelope) or _host_portal_context(peer).is_empty(): return
	var receipt := PORTAL_RECEIPT.receipt(envelope.world_instance_id, result.biome, envelope.character_id)
	var existing: Variant = game.get("world").reward_deliveries.get(receipt)
	var ledger: Node = get_node_or_null("LedgerRpc")
	if ledger == null: return
	_portal_waiters[receipt] = {"peer": peer, "envelope": envelope.duplicate(true)}
	if PORTAL_RECEIPT.valid(existing, envelope.character_id, envelope.world_instance_id):
		ledger.call("publish_portal_delivery", peer, envelope.character_id, receipt)
		if existing.status == "accepted": _portal_delivery_accepted(peer, existing)
		return
	var stage := host_stage_portal_debit(peer, result.biome, receipt)
	if stage.get("ok") != true or stage.get("duplicate") == true or not host_commit_portal_debit(stage):
		if stage.get("ok") == true and stage.get("duplicate") != true: host_finish_portal_debit(stage, false)
		_portal_waiters.erase(receipt)
		_portal_reply(peer, envelope, {"ok": false, "reason": "Your protected key is not ready to spend."})
		return
	var journal: Dictionary = ledger.call("journal_portal_delivery_prepared", peer, envelope.character_id, result.biome, int(stage.key_slot))
	var saved := journal.get("ok") == true and journal.get("durable") == true
	host_finish_portal_debit(stage, saved)
	if not saved:
		_portal_waiters.erase(receipt)
		_portal_reply(peer, envelope, {"ok": false, "reason": "The portal could not save. Your key is safe."})
		return
	ledger.call("publish_portal_delivery", peer, envelope.character_id, receipt)


func _portal_delivery_accepted(peer: int, row: Dictionary) -> void:
	var waiter: Dictionary = _portal_waiters.get(row.get("receipt"), {})
	if waiter.is_empty() or waiter.peer != peer or not _portal_envelope_valid(peer, waiter.envelope): return
	var game := _game()
	var canonical: Variant = game.get("world").reward_deliveries.get(row.receipt)
	if row.status != "accepted" or not PORTAL_RECEIPT.equivalent(canonical, row): return
	_portal_waiters.erase(row.receipt)
	_portal_reply(peer, waiter.envelope, {"ok": true, "durable": true, "receipt": row.receipt, "biome": row.biome})


func _commit_waystone_touch(peer: int, envelope: Dictionary, result: Dictionary) -> void:
	# Remote portable CAS waits for its typed owner mutation protocol. A
	# client-supplied activated set is never imported into admitted authority.
	if peer != local_peer_id():
		_portal_reply(peer, envelope, {"ok": false, "reason": "Your waystone save is not ready."})
		return
	var game := _game()
	var saver: RefCounted = game.get("save_system")
	if saver == null or saver.call("fallback_busy") == true: return
	var player: RefCounted = game.get("local")
	if _owner_training_mutation_blocked(player): return
	var before: Dictionary = player.redesign_character.duplicate(true)
	var biome: String = result.waystone.biome
	var stone: String = result.waystone.id
	var active: Array = player.redesign_character.waystones_activated.get(biome, []).duplicate()
	var first := not active.has(stone)
	if first: active.append(stone)
	player.redesign_character.waystones_activated[biome] = active
	player.redesign_character.last_waystones[biome] = stone
	if not bool(saver.call("save_character_prepared", game, player.character_id)):
		player.redesign_character = before
		_portal_reply(peer, envelope, {"ok": false, "reason": "Your waystone could not save. Touch it again."})
		return
	_portal_reply(peer, envelope, {"ok": true, "durable": true, "waystone_id": stone, "first_activation": first})


func _portal_reply(peer: int, envelope: Dictionary, result: Dictionary) -> void:
	if not _portal_envelope_valid(peer, envelope): return
	var reply := result.duplicate(true)
	if reply.get("prepared") is Dictionary:
		for key: Variant in reply.prepared:
			if key not in ["request_id", "kind", "character_id", "world_instance_id", "session_epoch", "ok", "durable"]: reply[key] = reply.prepared[key]
		reply.erase("prepared")
	reply.merge({"request_id": envelope.request_id, "kind": envelope.payload.kind,
		"character_id": envelope.character_id, "world_instance_id": envelope.world_instance_id,
		"session_epoch": envelope.session_epoch}, true)
	if peer == local_peer_id(): _receive_portal_reply.call_deferred(reply)
	else: rpc_id(peer, "_rpc_portal_result", reply)


@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_portal_result(reply: Dictionary) -> void:
	if not is_host(): _receive_portal_reply(reply)


func _receive_portal_reply(reply: Dictionary) -> void:
	var frozen: Dictionary = _portal_requests.get(reply.get("request_id"), {})
	var game := _game()
	if frozen.is_empty() or game == null or game.get("world") == null or game.get("local") == null: return
	if (reply.get("character_id") != frozen.character_id or reply.get("world_instance_id") != frozen.world_instance_id or
		reply.get("session_epoch") != frozen.session_epoch or reply.get("kind") != frozen.payload.kind or
		frozen.character_id != game.get("local").character_id or frozen.world_instance_id != game.get("world").reward_delivery_namespace or
		frozen.session_epoch != _altar_current_epoch()): return
	_portal_requests.erase(frozen.request_id)
	game.emit_signal("portal_action_result", reply.duplicate(true))


func _portal_world_node(realm: String) -> Node3D:
	var scene := get_tree().current_scene
	var node: Node3D = scene as Node3D if realm == _local_realm() else realms().call("shell", realm) as Node3D
	if node == null or (node.has_method("shell_build_complete") and node.call("shell_build_complete") != true): return null
	return node


func _host_portal_context(peer: int) -> Dictionary:
	if not is_host() or not portal_runtime_ready(): return {}
	var admitted := admitted_character_state(peer)
	if admitted.is_empty(): return {}
	# Remote panels, traversal and trainer hazard revision currently have no
	# host-approved lifecycle. Absence must not become safe=false. This closed
	# door remains explicit until their owning real producers are integrated.
	if peer != local_peer_id(): return {}
	var game := _game()
	var player := game.call("find_player") as CharacterBody3D
	var realm := _local_realm()
	var world_node := _portal_world_node(realm)
	if player == null or world_node == null or not world_node.is_ancestor_of(player): return {}
	var swim: Node = player.get("swim_controller")
	var fly: Node = player.get("fly_controller")
	var downed := game.get_node_or_null("DownedState")
	var vitals: RefCounted = player.get("vitals")
	if swim == null or fly == null or downed == null or vitals == null: return {}
	var input_owner := preload("res://scripts/ui/input_owner.gd").current(get_tree())
	var key := game.get_node_or_null("HomeKey")
	var dialogue := false
	var cutscene := input_owner != null and input_owner != key
	for node: Node in get_tree().get_nodes_in_group("progression_restore"):
		if world_node.is_ancestor_of(node) and node.has_method("is_fading") and node.call("is_fading") == true: cutscene = true
	for node: Node in get_tree().get_nodes_in_group("story_modal"):
		if node.has_method("is_open") and node.call("is_open") == true: dialogue = true
	var combat := false
	var directors: Array[Node] = []
	for node: Node in world_node.find_children("*", "Node", true, false):
		if node.has_method("trainer_battle_active") and node.has_method("encounter_record"): directors.append(node)
	if directors.is_empty(): return {}
	for director: Node in directors:
		if director.call("trainer_battle_active") == true: combat = true
		var manager: Node = director.get("_manager")
		if manager != null and manager.has_method("is_fighting") and manager.call("is_fighting") == true: combat = true
		var host_record: RefCounted = director.get("_encounter_host")
		if host_record != null:
			for record: Variant in host_record.get("encounters").values():
				if record is Dictionary and record.get("realm") == realm and record.get("phase") in ["active", "catching", "resolving"] and record.get("participants", {}).has(peer): combat = true
	var positions: Dictionary = {}
	var arches: Dictionary = {}
	for hall: Node in get_tree().get_nodes_in_group("crossing_halls"):
		if world_node.is_ancestor_of(hall):
			for id: String in ["home", "tidewake", "cloudreach", "stormwood", "biome5", "biome6", "biome7", "biome8"]:
				var arch: Node3D = hall.call("arch", id)
				if arch != null: arches[id] = arch.global_position
	for stone: Node in get_tree().get_nodes_in_group("waystones"):
		if world_node.is_ancestor_of(stone) and stone.get("realm_id") == realm:
			var id := str(stone.get("waystone_id"))
			if positions.has(id): return {}
			positions[id] = (stone as Node3D).global_position
	var personal: Dictionary = _character_authority.call("state", admitted.character_id)
	return {"world_instance_id": game.get("world").reward_delivery_namespace, "character_id": admitted.character_id,
		"peer_id": peer, "realm": realm, "position": player.global_position, "damage_revision": vitals.get("damage_revision"),
		"combat": combat, "dialogue": dialogue, "cutscene": cutscene, "swimming": bool(swim.call("is_swimming")),
		"flying": bool(fly.call("is_flying")), "downed": bool(downed.call("is_downed")),
		"home_key_owned": game.get("local").inventory.count("home_key") == 1,
		"character_unlocks": personal.redesign_character.portal_unlocks.duplicate(),
		"world_unlocks": game.get("world").redesign_world.portal_unlocks.duplicate(),
		"character_stirred": _character_authority.call("character_fifth_stirred", admitted.character_id),
		"owned_portal_keys": admitted_portal_keys(peer), "last_waystones": personal.redesign_character.last_waystones.duplicate(true),
		"waystones_activated": personal.redesign_character.waystones_activated.duplicate(true),
		"waystone_positions": positions, "arch_positions": arches}


func home_key_refusal() -> String:
	if not portal_runtime_ready(): return "The Home Key is not ready yet."
	if not is_host(): return "Your authoritative travel state is not ready."
	var context := _host_portal_context(local_peer_id())
	if context.is_empty(): return "Your travel state is not ready."
	return PORTAL_POLICY.refusal(context)

## Read-only pending predicate over the one durable world carrier. Unknown
## matching rows fail closed; this is not a new pending store or inventory.
func _pending_portal_for(character: String) -> bool:
	var game := _game()
	if game == null or game.get("world") == null: return true
	var world: RefCounted = game.get("world")
	for row: Variant in world.reward_deliveries.values():
		if row is Dictionary and row.get("kind") == "portal_unlock" and row.get("character_id") == character:
			if not PORTAL_RECEIPT.valid(row, character, world.reward_delivery_namespace) or row.status not in ["accepted"]: return true
	return false


var _owner_portal_install: Dictionary = {}

func _owner_portal_conflicting_transaction(player: RefCounted) -> bool:
	var row := _owner_training_row()
	return not _owner_training_retry.is_empty() or (not row.is_empty() and row.status == "pending") or (is_host() and _character_authority.call("creature_training_is_pending", player.character_id) == true)


func _begin_owner_portal_install(player: RefCounted, world: RefCounted, row: Dictionary, slot: int) -> bool:
	var game := _game()
	if game == null or player != game.get("local") or world != game.get("world") or not _owner_portal_install.is_empty() or _owner_portal_conflicting_transaction(player): return false
	if not PORTAL_RECEIPT.valid(row, player.character_id, world.reward_delivery_namespace) or row.status != "pending" or not PORTAL_RECEIPT.equivalent(world.reward_deliveries.get(row.receipt), row): return false
	if slot < 0 or player.inventory.stack_at(slot) != {"id": row.item, "n": 1}: return false
	_owner_portal_install = {"player": weakref(player), "world": weakref(world), "receipt": row.receipt, "slot": slot, "item": row.item, "rollback": false}
	return true


func _end_owner_portal_install() -> void:
	_owner_portal_install.clear()


func _owner_portal_inventory_write_allowed(index: int, stack: Variant, player: RefCounted) -> bool:
	var game := _game()
	if game == null or _owner_portal_install.is_empty() or _owner_portal_install.player.get_ref() != player or _owner_portal_install.world.get_ref() != game.get("world") or index != _owner_portal_install.slot: return false
	var row: Variant = game.get("world").reward_deliveries.get(_owner_portal_install.receipt)
	if not PORTAL_RECEIPT.valid(row, player.character_id, game.get("world").reward_delivery_namespace) or row.status != "pending": return false
	return stack == {"id": _owner_portal_install.item, "n": 1} if _owner_portal_install.rollback else stack == null


func _owner_portal_snapshot_allowed(player: RefCounted, payload: Dictionary) -> bool:
	var game := _game()
	if game == null or player != game.get("local"): return false
	var world: RefCounted = game.get("world")
	for row: Variant in world.reward_deliveries.values():
		if not row is Dictionary or row.get("kind") != "portal_unlock" or row.get("character_id") != player.character_id or row.get("status") != "pending": continue
		if not PORTAL_RECEIPT.valid(row, player.character_id, world.reward_delivery_namespace): return false
		var expected := row.duplicate(true)
		expected.status = "settled"
		if not PORTAL_RECEIPT.equivalent(payload.get("satchel_escrow", {}).get(row.receipt), expected): return false
		if not payload.get("redesign_character", {}).get("transaction_receipts", []).has(row.receipt): return false
		for stack: Variant in payload.get("inventory", []):
			if stack is Dictionary and stack.get("id") == row.item: return false
	return true
