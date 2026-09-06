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

const HOST_PEER_ID := PEER_REGISTRY.HOST_PEER_ID

signal peer_joined(peer_id: int, character_id: String)
signal peer_left(peer_id: int)
## Wave 6 lane 6.A. Somebody crossed a realm boundary without leaving the
## session. Emitted on every peer, from the replicated registry, so a world
## scene can reconcile what it draws without asking who moved.
signal peer_realm_changed(peer_id: int, from_realm: String, to_realm: String)
signal snapshot_applied()
signal session_ended(reason: String)

## "" (no session), "host" or "client". The single source of truth for
## `is_host()`; `multiplayer.is_server()` is only consulted inside RPC bodies,
## where a live peer is guaranteed to exist.
var _mode: String = ""
var _peer: ENetMultiplayerPeer = null
var _registry: RefCounted = PEER_REGISTRY.new()
var _config: Dictionary = {}
var _clock_accum: float = 0.0

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
var _box: Dictionary = {"connected": false, "snapshot": true, "failed": false, "ended": ""}

## The character summary `join()` was given, sent the moment ENet reports the
## connection up (`_on_connected_to_server`).
var _pending_hello: Dictionary = {}

## Frames left before a leaving host actually closes its socket. A reliable
## `session_ended` broadcast has to get off the wire before the peer under it
## goes away, and counting frames in `_process` is how that happens without
## this function becoming a coroutine.
var _closing_frames: int = 0
var _closing_reason: String = ""

## Wave 6 lane 6.A: `/root/Game/Session/Realms`, the host's headless shells.
## Mounted in `_ready()` so its node path is identical in every process, the
## same reason `LedgerRpc` is mounted with the session rather than by its
## first consumer.
var _realms: Node = null


func _ready() -> void:
	name = "Session"
	process_mode = Node.PROCESS_MODE_ALWAYS
	_config = _load_config()
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
	# create_server() counts CLIENTS, not peers: D95's cap of four is the host
	# plus three joiners.
	var err := p.create_server(use_port, maxi(1, cap - 1), int(_cfg("channel_count", 2)))
	if err != OK:
		push_warning("Session.host: could not bind udp/%d (err %d); staying offline-solo" % [use_port, err])
		return false
	_peer = p
	multiplayer.multiplayer_peer = p
	_mode = "host"
	_box["connected"] = true
	_box["snapshot"] = true
	_box["failed"] = false
	_box["ended"] = ""
	_registry.call("clear")
	_registry.call("add", HOST_PEER_ID, _local_character_id(), _local_display_name(), _local_realm())
	if _realms != null:
		_realms.call("reconcile")
	print("[session] hosting on udp/%d (cap %d, channels %d); local peer id %d"
		% [use_port, cap, int(_cfg("channel_count", 2)), multiplayer.get_unique_id()])
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
	var use_port := port if port > 0 else default_port()
	var p := ENetMultiplayerPeer.new()
	var err := p.create_client(ip, use_port, int(_cfg("channel_count", 2)))
	if err != OK:
		push_warning("Session.join: create_client(%s, %d) failed err=%d" % [ip, use_port, err])
		return false
	_peer = p
	multiplayer.multiplayer_peer = p
	_mode = "client"
	_box["connected"] = false
	_box["snapshot"] = false
	_box["failed"] = false
	_box["ended"] = ""
	_registry.call("clear")

	var summary := character_summary.duplicate(true)
	if not summary.has("character_id"):
		summary["character_id"] = _local_character_id()
	if not summary.has("display_name"):
		summary["display_name"] = _local_display_name()
	if not summary.has("realm"):
		summary["realm"] = _local_realm()
	_pending_hello = summary
	print("[session] dialling %s:%d as '%s' (%s)"
		% [ip, use_port, str(summary["display_name"]), str(summary["character_id"])])
	return true


## True once a joiner's handshake has definitively failed (connection refused,
## or the peer torn down under it). Never true on a host or a solo process.
func handshake_failed() -> bool:
	return bool(_box.get("failed", false))


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
			return
	else:
		_save_character_here()
	_teardown()
	session_ended.emit(reason)


## Host-only. Drops one peer; the registry replicates without it.
func kick(peer_id: int) -> bool:
	if not is_active() or not is_host() or peer_id == HOST_PEER_ID:
		return false
	if not bool(_registry.call("has", peer_id)):
		return false
	rpc_id(peer_id, "_rpc_session_ended", "kicked")
	_peer.disconnect_peer(peer_id)
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
	return _mode != "client"


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
	if is_host():
		_apply_realm_change(HOST_PEER_ID, from_realm, to_realm)
		return
	# The client tells the host and moves. It does NOT wait for an
	# acknowledgement: `enter_realm()` is a synchronous call reached through
	# `Object.call()`, and nothing in this file is a coroutine (see `_box`).
	# The cost is bounded and known -- for the round trip the host still holds
	# a body for this peer in the realm it has left, which the reconcile below
	# then removes. The alternative, a client that cannot walk through a gate
	# until a packet comes back, is worse and is not what rule 16 asks for.
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
	# despawns the moving peer's body out of the realm it has left, which is
	# what stops everybody still there from drawing a trainer who has gone --
	# and it has to happen while that world is still standing, because a shell
	# torn down by the reconcile takes its own spawner with it.
	peer_realm_changed.emit(peer_id, from_realm, to_realm)
	_broadcast_registry()
	if _realms != null:
		_realms.call("reconcile")


## Peers in the session. 1 when solo or session-less: the local player is
## always one peer, and a caller dividing by this must never get zero.
func peer_count() -> int:
	if not is_active():
		return 1
	return maxi(1, int(_registry.call("size")))


func peers() -> Array:
	if not is_active():
		return [PEER_REGISTRY.make_row(HOST_PEER_ID, _local_character_id(),
			_local_display_name(), _local_realm())]
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


func mode() -> String:
	return _mode


# --- handshake ----------------------------------------------------------------

## Client -> host, ledger channel. The joiner's character summary.
@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_hello(summary: Dictionary) -> void:
	if not is_host():
		return
	var sender := multiplayer.get_remote_sender_id()
	var character_id := str(summary.get("character_id", ""))
	var display_name := str(summary.get("display_name", ""))
	var realm := str(summary.get("realm", "meadows"))
	_registry.call("add", sender, character_id, display_name, realm)
	print("[session] peer %d joined as '%s' (%s) in %s" % [sender, display_name, character_id, realm])
	# The snapshot goes on its OWN channel (D95) and BEFORE the registry, so a
	# joiner can never see itself listed as present while still holding an
	# empty world.
	rpc_id(sender, "_rpc_snapshot", _world_snapshot())
	_broadcast_registry()
	peer_joined.emit(sender, character_id)
	# The joiner may be arriving into a realm this process is not standing in
	# (a rejoin carries the character's last realm forward, `peer_registry
	# .gd::add`). Standing its shell up is this call, not a special case.
	if _realms != null:
		_realms.call("reconcile")


## Host -> one joiner, snapshot channel. The whole world, as
## `WorldState.save_data()` writes it.
@rpc("authority", "call_remote", "reliable", CHANNEL_SNAPSHOT)
func _rpc_snapshot(data: Dictionary) -> void:
	var game := _game()
	if game != null and game.has_method("apply_world_snapshot"):
		game.call("apply_world_snapshot", data)
	_box["snapshot"] = true
	print("[session] snapshot applied (%d keys, day %d)" % [data.size(), int(data.get("day", 1))])
	snapshot_applied.emit()


## Host -> everyone, ledger channel. The registry, whole (peer_registry.gd's
## header explains why whole and not a delta).
@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_registry(payload: Dictionary) -> void:
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
	if game == null or is_host():
		return
	game.call("apply_host_clock", day, elapsed)


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
	# Nothing to do until the joiner says hello: the registry row is built from
	# the character summary, not from an id arriving on its own.
	print("[session] transport: peer %d connected" % peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	if not is_host():
		return
	if bool(_registry.call("remove", peer_id)):
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
	_box["connected"] = true


func _on_connection_failed() -> void:
	_box["failed"] = true
	_teardown()


func _on_server_disconnected() -> void:
	if _box.get("ended", "") == "":
		_box["ended"] = "host_gone"
	_save_character_here()
	_teardown()
	session_ended.emit("host_gone")
	_return_to_title("host_gone")


# --- host clock (D105) -----------------------------------------------------------

func _process(delta: float) -> void:
	if _closing_frames > 0:
		_closing_frames -= 1
		if _closing_frames == 0:
			_teardown()
			session_ended.emit(_closing_reason)
			_closing_reason = ""
		return
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
## HONEST GAP, recorded rather than faked: the character file does not exist
## yet. D100's split (`user://characters/<id>/character.json`) is a later lane's
## deliverable, and today the only writer is `save_game.gd`, whose file carries
## the WORLD keys too -- so calling it here is exactly the thing a client must
## not do. Until the split lands a client writes nothing on leave, which is why
## `smoke_net_host_join_leave.gd` asserts the client's autosave slot stays
## absent: that assertion is what will have to be re-pointed (not deleted) when
## the character half becomes writable.
func _save_character_here() -> void:
	var game := _game()
	if game == null:
		return
	if is_host():
		game.call("save_game", int(game.call("autosave_slot")))
		return
	print("[session] client leave: no character file to write yet (D100 split is a later lane)")


func _teardown() -> void:
	# Before the peer goes away, not after: `realm_shells.gd::_tear_down()`
	# asks `Game.is_host()` whether it may write the world, and that answer
	# flips the moment `_mode` is cleared below.
	if _realms != null:
		_realms.call("release_all")
	if multiplayer != null and multiplayer.multiplayer_peer == _peer and _peer != null:
		multiplayer.multiplayer_peer = null
	if _peer != null:
		_peer.close()
	_peer = null
	_mode = ""
	_registry.call("clear")
	_box["connected"] = false
	_box["snapshot"] = true
	_pending_hello = {}
	_closing_frames = 0
	_clock_accum = 0.0


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
		# 1.C mints these on New Character; until then a session still needs one
		# stable id per process or the registry cannot tell two joiners apart.
		# Minted here and written back so the same process keeps it.
		id = "peer-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
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


func _local_realm() -> String:
	var game := _game()
	if game == null:
		return "meadows"
	return str(game.get("current_realm"))
