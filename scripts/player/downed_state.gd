extends Node

## Stage B Wave 4 lane 4.E. DOWNED: a player who goes down is a problem their
## friend can solve, not the end of the fight.
##
## Mounted once, lazily, as `/root/Game/DownedState` by
## `scripts/world/player_death.gd::build()` -- a child of the one autoload
## rather than a second autoload (the one-autoload rule), and for the same
## reason `session.gd` is: the node path has to be IDENTICAL in every process
## or the revive RPCs below do not resolve at all. `PlayerDeath` itself is a
## per-world component and is rebuilt on every scene change, so it cannot be
## the RPC endpoint; this node is built once and outlives every world.
##
## ## What this is, in one sentence per rule
##
##   1. In a MULTI-PEER session a lethal hit opens a `window_s` window instead
##      of killing: `request_down()` answers `true` and the caller stops.
##   2. A teammate standing within `revive_radius_m` taps interact once to
##      start `revive_progress_s` of proximity progress; release continues it
##      and a second tap cancels it. The HOST validates both bodies and owns
##      the three-second clock and the only completion grant.
##   3. When the window runs out this emits `downed_ended(false)` and the
##      existing satchel-drop and respawn runs UNCHANGED. This adds a stage
##      before death; it does not replace death.
##   4. SOLO HAS NO WINDOW. `request_down()` answers `false` the moment
##      `Game.is_multi_peer()` is false, and a solo death is byte-for-byte the
##      path it was before this lane. There is nobody to revive a solo player,
##      and a delay before an inevitable respawn is just a worse game.
##   5. Going down touches NOTHING outside the player who went down: no
##      encounter, no world ledger, no satchel, no world record, no pause. That
##      is directive rule 19 and it is the point of the whole feature.
##
## ## The `OfflineMultiplayerPeer` trap, and how this file stays out of it
##
## Godot installs an `OfflineMultiplayerPeer` by default, under which
## `multiplayer.is_server()` is **true** and `get_unique_id()` is **1** in a
## process with no session at all -- so any guard shaped "am I the server, if a
## peer exists" passes in every headless test, capture tool and editor run and
## is unsound. `scripts/net/trainer_spawn.gd::_is_host()` carries the full
## account of what that cost the first time.
##
## Nothing here asks the multiplayer API whether a session or host exists.
## Down-window eligibility goes through `Game.is_multi_peer()` ->
## `Session.is_multi_peer()` -> `peer_count() > 1`; host authority and
## membership go through Session's mode and replicated registry. Those answers
## are re-read when needed rather than cached at `_ready()`: `join()` swaps the
## peer under this node's feet and a cached answer would be stale across
## exactly that swap.
##
## ## A player who disconnects while downed
##
## Decided, not left to chance, in both directions:
##
##   * **They drop while down.** Their process is gone, so their window is gone
##     with it. On every remaining peer `Session.peer_left` frees their
##     `remote_trainer` body (`trainer_spawn.gd::_despawn_for`) and
##     `_forget_peer()` frees the revive prompt bolted to it, so there is no
##     body nobody can revive and no prompt nobody can clear. `_prune()` is the
##     belt to that braces: `Session.peer_left` is only emitted on the HOST,
##     so a client watching another client leave reconciles `_downed_peers`
##     against the replicated registry every frame instead.
##   * **The session collapses under them.** If the local player is downed and
##     the session drops below two peers -- the host left, everyone else quit,
##     the socket died -- the window ends IMMEDIATELY as an ordinary death.
##     Rule 4 says solo has no window, and a player left face-down forever in a
##     game that has become solo is the worst outcome of the three.

const CONFIG_PATH := "res://data/config/multiplayer.json"
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const INTERACTION_ARBITER := preload("res://scripts/world/interaction_arbiter.gd")
const PROMPT_ARBITER := preload("res://scripts/world/prompt_arbiter.gd")
const REVIVE_AUTHORITY := preload("res://scripts/net/revive_authority.gd")

## Where this mounts. Must be identical in every process; see the header.
const NODE_NAME := "DownedState"
const GAME_PATH := ^"/root/Game"

## The group `scripts/net/remote_trainer.gd` puts every peer's body in. Read
## only; this lane owns none of that file.
const REMOTE_TRAINER_GROUP := &"remote_trainer"

## The action that starts or cancels a revive. `data/config/input_contexts.json` lists
## `interact` in the `world` context; the same X the player uses for every
## other "do the thing in front of me".
const REVIVE_ACTION := &"interact"

## The prompt node bolted onto a downed teammate's body, by name so
## `_forget_peer()` can find and free exactly the one it added.
const PROMPT_NAME := "RevivePrompt"

## Metres up the downed body the prompt is hung. `interactable.gd` draws its
## sight line from its OWN position, and one drawn from a body's feet skims
## every hummock between here and the reviver.
const PROMPT_HEIGHT := 0.6

## Beats an ordinary prompt. A berry bush and a friend on the floor are not a
## close call.
const PROMPT_PRIORITY := 10
## Once progress has started, cancel must remain the arbiter's one interact
## owner even if the body prompt loses line of sight or another provider walks
## closer. Combat's strongest statement uses 100; this active action outranks it.
const CHANNEL_PROMPT_PRIORITY := 1000

## D95's ledger channel. Small reliable control traffic, which is what the
## other channel (2, the world snapshot) exists to keep clear of.
const CHANNEL_LEDGER := 1
const HOST_PEER_ID := 1
const PROGRESS_NOTICE_STEP_S := 0.1

## Emitted on the downed player's own process when the window opens.
signal downed_began()
## Emitted on the downed player's own process when the window closes.
## `revived` false means the ordinary death has to run now.
signal downed_ended(revived: bool)

var window_s: float = 45.0
var revive_progress_s: float = 3.0
var revive_move_deadzone_m: float = 0.3
## Historical compatibility alias. A revive has not required a physical hold
## since the tap-start interaction shipped; probes and old config may still
## read this name while they migrate.
var revive_hold_s: float = 3.0
var revive_radius_m: float = 2.5
var revive_health_fraction: float = 0.35
var revive_stamina_fraction: float = 0.35

## The local rig, handed over by `player_death.gd::build()` on every world.
var _player: CharacterBody3D = null
## What to run when the window closes without a revive. A stored Callable
## rather than a signal connection on purpose: `PlayerDeath` is rebuilt on
## every scene change while this node is not, and a Callable that is
## OVERWRITTEN by each new world cannot leave two dead worlds' components both
## listening and killing the player twice.
var _death_handler: Callable = Callable()

var _local_downed: bool = false
var _remaining_s: float = 0.0
## A tap starts this channel. Releasing interact does not affect it. The same
## prompt owns a second tap, which cancels without also activating a world
## object underneath it.
var _progress_s: float = 0.0
var _progress_peer: int = 0
var _progress_origin := Vector3.ZERO
var _progress_last_health: float = 0.0
var _progress_scene: Node = null
var _progress_realm: String = ""
var _progress_body: Node3D = null
var _channel_arbiter: Node = null
var _progress_attempt: int = 0
var _progress_window: int = 0

## Monotonic identities separate a late packet from the current down window or
## revive attempt. This node survives realm changes and local respawns, so the
## counters do too.
var _window_counter: int = 0
var _local_window: int = 0
var _attempt_counter: int = 0
## peer id -> latest announced down-window identity.
var _peer_windows: Dictionary = {}
var _peer_window_highwater: Dictionary = {}

## The host's pure validation clock. Clients retain one inert instance so
## tests and lifecycle code do not need a nullable service; only `_is_host()`
## may mutate it or publish its events.
var _authority: RefCounted = REVIVE_AUTHORITY.new()
var _last_progress_notice: Dictionary = {}

## Counters, for the smoke and for a bug report that has to say how many times
## something happened rather than that it did.
var _revived_count: int = 0
var _expired_count: int = 0

## peer id -> display name, the DOWNED TEAMMATES this process knows about.
## Never contains the local player: a peer only ever hears about somebody
## else's window, and its own lives in `_local_downed`.
var _downed_peers: Dictionary = {}


## Find or build the one instance, under `Game`. Idempotent: every world's
## `PlayerDeath` calls this and the second and later calls get the node the
## first one made, with its window still running if one is open.
static func mount(game: Node) -> Node:
	if game == null:
		return null
	var existing := game.get_node_or_null(NodePath(NODE_NAME))
	if existing != null:
		return existing
	var node: Node = (load("res://scripts/player/downed_state.gd") as GDScript).new()
	node.name = NODE_NAME
	game.add_child(node)
	return node


func _ready() -> void:
	name = NODE_NAME
	# The world does not stop because somebody went down (rule 19), and neither
	# does the window: a pause menu opened over a downed player must not freeze
	# the clock their friend is racing.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Frame ORDER, not just frame count. This node is a child of the `Game`
	# autoload, and autoloads are added to the root before the current scene --
	# so by default this runs BEFORE `sequence_director.gd::_refresh_lockout()`,
	# whose per-frame `set_locomotion_enabled(not modal)` would then be the last
	# write of the idle frame and a downed player would walk. A high idle
	# priority puts this last among `_process` nodes instead, and a low physics
	# priority keeps it ahead of `player_controller.gd::_physics_process`, which
	# is where the flag is actually READ.
	process_priority = 100
	process_physics_priority = -100
	_load_config()
	_configure_authority()
	_wire_session()


func _exit_tree() -> void:
	_unregister_channel_provider()


func _load_config() -> void:
	# `FileAccess` on `res://data/config/*.json`, the way every other config
	# reader in this repo does it -- not `ResourceLoader`, which would treat
	# the file as an import.
	var f := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var section: Variant = (parsed as Dictionary).get("downed", {})
	if typeof(section) != TYPE_DICTIONARY:
		return
	var cfg: Dictionary = section
	# `has()` before `get()`, every one of them. A missing key read through
	# `get()` returns null and `float(null)` is 0.0 -- which here would be a
	# zero-second window that expires on the frame it opens, i.e. the feature
	# silently not existing while every test still passed.
	if cfg.has("window_s"):
		window_s = maxf(0.0, float(cfg["window_s"]))
	if cfg.has("revive_progress_s"):
		revive_progress_s = maxf(0.0, float(cfg["revive_progress_s"]))
	elif cfg.has("revive_hold_s"):
		# Compatibility with saves/tools built while the same three-second
		# exposure was expressed as a physical hold.
		revive_progress_s = maxf(0.0, float(cfg["revive_hold_s"]))
	revive_hold_s = revive_progress_s
	if cfg.has("revive_move_deadzone_m"):
		revive_move_deadzone_m = maxf(0.0, float(cfg["revive_move_deadzone_m"]))
	if cfg.has("revive_radius_m"):
		revive_radius_m = maxf(0.0, float(cfg["revive_radius_m"]))
	if cfg.has("revive_health_fraction"):
		revive_health_fraction = clampf(float(cfg["revive_health_fraction"]), 0.01, 1.0)
	if cfg.has("revive_stamina_fraction"):
		revive_stamina_fraction = clampf(float(cfg["revive_stamina_fraction"]), 0.0, 1.0)


func _configure_authority() -> void:
	_authority.set("duration_s", revive_progress_s)
	_authority.set("radius_m", revive_radius_m)
	_authority.set("deadzone_m", revive_move_deadzone_m)


## `Session.peer_left` is the host-side half of the disconnect answer; see the
## header. Wired defensively because a bare-scene test may mount this without
## ever standing up a session.
func _wire_session() -> void:
	var session := _session()
	if session == null:
		return
	if session.has_signal("peer_left") and not session.is_connected("peer_left", _on_peer_left):
		session.connect("peer_left", _on_peer_left)
	if session.has_signal("session_ended") \
			and not session.is_connected("session_ended", _on_session_ended):
		session.connect("session_ended", _on_session_ended)


# --- the door `player_death.gd` uses -----------------------------------------

## Rebind to the world that is standing now. Called by every
## `player_death.gd::build()`, which is once per world scene.
##
## `on_expire` is what runs when a window closes with nobody having come:
## `PlayerDeath`'s ordinary drop-and-respawn. Overwriting it rather than adding
## a second listener is what keeps a scene change from leaving two worlds' death
## components both armed.
func attach_local(player: CharacterBody3D, on_expire: Callable = Callable()) -> void:
	_cancel_revive("")
	_player = player
	_death_handler = on_expire
	_wire_session()
	# A new world means every body this node knew about is gone with the old
	# scene tree. The prompts died with their bodies; drop the bookkeeping too.
	_downed_peers.clear()
	if _local_downed:
		# The player was downed and the world changed under them. Nothing can
		# revive them across that, so close the window the honest way.
		_end(false)


## Open a downed window instead of dying, if this session has anyone in it who
## could do anything about it.
##
## Returns TRUE when the caller must stop -- a window is open (or was already
## open, so a second lethal signal in the same window is swallowed rather than
## opening a second one). Returns FALSE when the caller must run its ordinary
## death, which is every solo death and every session-less process: a headless
## test, a capture tool, the editor.
func request_down() -> bool:
	if _local_downed:
		return true
	if not _multi_peer():
		return false
	if _player == null or not is_instance_valid(_player):
		return false
	_cancel_revive("")
	_window_counter += 1
	_local_window = _window_counter
	_local_downed = true
	_remaining_s = window_s
	_hold_still()
	if _is_host():
		_authority.call("note_down", _local_peer_id(), _local_window,
			_current_realm(), window_s)
	_broadcast_downed()
	var game := _game()
	if game != null and game.has_method("push_world_message"):
		game.call("push_world_message",
			"You are down. A teammate can bring you back for %d more seconds." % int(round(window_s)))
	print("[downed] local player is down; %.1f s to be revived" % _remaining_s)
	downed_began.emit()
	return true


func is_downed() -> bool:
	return _local_downed


func remaining_s() -> float:
	return _remaining_s if _local_downed else 0.0


func progress_s() -> float:
	return _progress_s


## Historical probe alias. This reports channel progress; it no longer means
## the interact action is physically held.
func hold_s() -> float:
	return _progress_s


## What a probe or a HUD needs, in one read.
func status() -> Dictionary:
	return {
		"local_downed": _local_downed,
		"remaining_s": remaining_s(),
		"progress_s": _progress_s,
		"progress_peer": _progress_peer,
		# Historical aliases retained for existing probes.
		"hold_s": _progress_s,
		"hold_peer": _progress_peer,
		"revived": _revived_count,
		"expired": _expired_count,
		"window_s": window_s,
		"revive_progress_s": revive_progress_s,
		"revive_move_deadzone_m": revive_move_deadzone_m,
		# Historical config/status alias; this is progress duration now.
		"revive_hold_s": revive_hold_s,
		"revive_radius_m": revive_radius_m,
		"downed_peers": _downed_peers.keys().map(func(k: Variant) -> int: return int(k)),
	}


# --- the frame ----------------------------------------------------------------

func _process(delta: float) -> void:
	if _local_downed:
		_cancel_revive("")
		_tick_window(delta)
		if _is_host():
			_tick_authority(delta)
		return
	_prune()
	_tick_revive(delta)
	# Local continuation guards run before the host clock. A host player who
	# moved or took damage on the completion frame must cancel before the clock
	# can grant, while remote channels still advance when the host is downed.
	if _is_host():
		_tick_authority(delta)


## Idle writes the latch last; physics re-asserts it first, before
## `player_controller.gd` reads it. See `_ready()` for the ordering, and
## `_tick_window()` for why the latch exists at all.
func _physics_process(_delta: float) -> void:
	if _local_downed:
		_hold_still()


func _tick_window(delta: float) -> void:
	# Downed is a STATE, and locomotion is a shared channel, so the latch is
	# re-asserted every frame rather than set once when the window opened.
	#
	# Measured, not assumed. `scripts/story/sequence_director.gd:800` writes
	# `set_locomotion_enabled(not modal)` on EVERY frame in which no fight is
	# running, so a single write at `request_down()` is undone within one
	# frame and a downed player walks off as normal -- which is exactly what
	# the first run of `tests/smoke_net_revive.gd` caught ("a downed peer 1
	# cannot walk away", the one failing check out of 36). Four other files
	# write the same channel (the encounter director, throw aim, the Cloudreach
	# chapter and the runtime), so deferring to whoever wrote last is not a
	# thing that can be made to work; holding the latch is.
	_hold_still()
	# Re-read authority every frame rather than trusting the answer the window
	# opened on; see the header on the `OfflineMultiplayerPeer` trap.
	if not _multi_peer():
		print("[downed] the session dropped below two peers; the window closes as a death")
		_end(false)
		return
	_remaining_s -= delta
	if _remaining_s <= 0.0:
		_remaining_s = 0.0
		print("[downed] nobody came; the ordinary death runs")
		_end(false)


## Forget any downed teammate the replicated registry no longer lists. The host
## also hears `peer_left`; a CLIENT watching another client leave does not
## (`session.gd::_on_peer_disconnected` returns early off the host), and this is
## how that case still clears.
func _prune() -> void:
	if _downed_peers.is_empty():
		return
	var live := _registry_peer_ids()
	if live.is_empty():
		# No session at all any more. Nothing left to revive.
		for peer_id: Variant in _downed_peers.keys().duplicate():
			_forget_peer(int(peer_id))
		return
	for peer_id: Variant in _downed_peers.keys().duplicate():
		if not live.has(int(peer_id)):
			_forget_peer(int(peer_id))


func _tick_revive(_delta: float) -> void:
	if _downed_peers.is_empty():
		_cancel_revive("")
		return
	# Late bodies: a `_rpc_downed` can beat the spawner's body by a frame or
	# two, so the prompt is (re)hung here rather than only on arrival.
	for peer_id: Variant in _downed_peers.keys():
		_attach_prompt(int(peer_id), str(_downed_peers[peer_id]))
	if _progress_peer == 0:
		return

	_sync_channel_provider()
	var refusal := _revive_refusal(_progress_peer)
	if not refusal.is_empty():
		_cancel_revive(refusal)
		return
	# The host owns elapsed time and completion. Local processing only keeps
	# the immediate player-side safety guards live; progress arrives in bounded
	# host notices below.
	_update_revive_prompt(_progress_peer)


# --- host authorization clock -------------------------------------------------

func _tick_authority(delta: float) -> void:
	var events: Variant = _authority.call("tick", delta, _host_views())
	if events is not Array:
		return
	for event: Variant in events:
		if event is Dictionary:
			_route_authority_event(event as Dictionary)


## Kept public within this node for focused tests: the sender identity is an
## argument only after the RPC boundary has derived it from the transport.
func _host_start_revive(reviver: int, target: int, window: int, attempt: int) -> Dictionary:
	if not _is_host() or not _registered_peer(reviver) or not _registered_peer(target):
		var rejected := {"kind": "rejected", "reviver": reviver, "target": target,
			"window": window, "attempt": attempt, "elapsed": 0.0,
			"reason": "invalid_peer"}
		_route_authority_event(rejected)
		return rejected
	var event: Variant = _authority.call("start", reviver, target, window, attempt, _host_views())
	if not (event is Dictionary):
		return {}
	_route_authority_event(event as Dictionary)
	return event as Dictionary


func _host_cancel_revive(reviver: int, attempt: int) -> void:
	if not _is_host() or not _registered_peer(reviver):
		return
	_authority.call("cancel", reviver, attempt)


func _route_authority_event(event: Dictionary) -> void:
	var kind := str(event.get("kind", ""))
	if kind == "completed":
		_clear_progress_notices(int(event.get("reviver", 0)))
		_host_grant_revive(int(event.get("target", 0)), int(event.get("window", 0)))
		return
	var reviver := int(event.get("reviver", 0))
	if reviver <= 0:
		return
	if kind == "started":
		_clear_progress_notices(reviver)
	elif kind == "cancelled" or kind == "rejected":
		_clear_progress_notices(reviver)
	if kind == "progress":
		var elapsed := float(event.get("elapsed", 0.0))
		var notice_key := "%d:%d" % [reviver, int(event.get("attempt", 0))]
		if elapsed - float(_last_progress_notice.get(notice_key, -PROGRESS_NOTICE_STEP_S)) \
				< PROGRESS_NOTICE_STEP_S:
			return
		_last_progress_notice[notice_key] = elapsed
	_send_revive_notice(reviver, event)


func _clear_progress_notices(reviver: int) -> void:
	var prefix := "%d:" % reviver
	for key: Variant in _last_progress_notice.keys():
		if str(key).begins_with(prefix):
			_last_progress_notice.erase(key)


func _send_revive_notice(reviver: int, event: Dictionary) -> void:
	if not _registered_peer(reviver):
		return
	if reviver == _local_peer_id():
		_apply_revive_notice(event)
	else:
		rpc_id(reviver, &"_rpc_revive_notice", event)


func _host_grant_revive(target: int, window: int) -> void:
	if target <= 0 or window <= 0:
		return
	if target == _local_peer_id():
		_grant_local_revive(window)
	else:
		rpc_id(target, &"_rpc_revive_grant", window)


func _apply_revive_notice(event: Dictionary) -> void:
	if int(event.get("reviver", 0)) != _local_peer_id() \
			or int(event.get("attempt", 0)) != _progress_attempt \
			or int(event.get("target", 0)) != _progress_peer \
			or int(event.get("window", 0)) != _progress_window:
		return
	var kind := str(event.get("kind", ""))
	match kind:
		"started", "duplicate", "progress":
			_progress_s = clampf(float(event.get("elapsed", 0.0)), 0.0, revive_progress_s)
			_update_revive_prompt(_progress_peer)
		"rejected", "cancelled":
			var reason := _revive_event_message(str(event.get("reason", "")))
			_cancel_revive(reason, false)


func _revive_event_message(reason: String) -> String:
	match reason:
		"busy": return "Revive unavailable: another teammate is already helping."
		"out_of_range": return "Revive cancelled: move back within %.1f m." % revive_radius_m
		"moved": return "Revive cancelled: stay still."
		"realm_changed": return "Revive cancelled: the realm changed."
		"body_replaced": return "Revive cancelled: the downed teammate's body changed."
		"window_expired", "invalid_window": return "Revive cancelled: that teammate is no longer down."
		"reviver_downed": return "Revive cancelled: you are down."
		"peer_forgotten", "invalid_peer": return "Revive cancelled: the co-op session changed."
		_: return "Revive cancelled."


func _host_views() -> Dictionary:
	var views := {}
	var session := _session()
	if session == null or not session.has_method("peers"):
		return views
	var local_id := _local_peer_id()
	for raw: Variant in (session.call("peers") as Array):
		if not (raw is Dictionary):
			continue
		var row := raw as Dictionary
		var peer_id := int(row.get("peer_id", row.get("id", 0)))
		var realm := str(row.get("realm", ""))
		var body: Node3D = _local_rig() if peer_id == local_id else _body_for(peer_id)
		var body_realm := _current_realm() if peer_id == local_id \
			else (str(body.get("net_realm")) if body != null else "")
		var valid := peer_id > 0 and not realm.is_empty() and body != null \
			and is_instance_valid(body) and body.is_inside_tree() and body_realm == realm \
			and body.global_position.is_finite()
		views[peer_id] = {"valid": valid,
			"position": body.global_position if valid else Vector3.INF,
			"realm": realm, "body_id": body.get_instance_id() if valid else 0}
	return views


## The prompt is the arbiter's winning provider, so this callback consumes the
## one interact edge. A cancellation tap therefore cannot fall through and
## activate a berry bush, door or NPC on the same frame.
func _on_revive_prompt_activated(peer_id: int) -> void:
	if peer_id == _progress_peer:
		_cancel_revive("Revive cancelled.")
		return
	if _progress_peer != 0:
		_cancel_revive("")
	var refusal := _revive_refusal(peer_id, true)
	if not refusal.is_empty():
		return
	var window := int(_peer_windows.get(peer_id, 0))
	if window <= 0:
		_push_message("Revive unavailable: that downed window is no longer current.")
		return
	var rig := _local_rig()
	_attempt_counter += 1
	_progress_attempt = _attempt_counter
	_progress_window = window
	_progress_peer = peer_id
	_progress_s = 0.0
	_progress_origin = rig.global_position
	_progress_last_health = _local_health()
	_progress_scene = get_tree().current_scene
	_progress_realm = _current_realm()
	_progress_body = _body_for(peer_id)
	_sync_channel_provider()
	_update_revive_prompt(peer_id)
	_push_message("Reviving %s. Stay close and still; tap interact again to cancel."
		% _downed_name(peer_id))
	if _is_host():
		_host_start_revive(_local_peer_id(), peer_id, window, _progress_attempt)
	else:
		rpc_id(HOST_PEER_ID, &"_rpc_revive_start", peer_id, window, _progress_attempt)


## Empty means the attempt may start/continue. This reads state every frame so
## a modal, damage, realm handoff, missing body or collapsed session cancels
## immediately instead of letting progress finish behind a different context.
func _revive_refusal(peer_id: int, starting: bool = false) -> String:
	if peer_id == 0 or not _downed_peers.has(peer_id):
		return "Revive cancelled: that teammate is no longer down."
	if not _multi_peer():
		return "Revive cancelled: the co-op session ended."
	if _local_downed:
		return "Revive cancelled: you are down."
	if not is_inside_tree() or get_tree() == null:
		return "Revive cancelled."
	if INPUT_OWNER.current(get_tree()) != null:
		return "Revive unavailable while another screen is open." if starting \
			else "Revive cancelled while another screen is open."
	var rig := _local_rig()
	if rig == null or not is_instance_valid(rig) or not rig.is_inside_tree():
		return "Revive cancelled: you are no longer active."
	if rig.has_method("locomotion_enabled") and not bool(rig.call("locomotion_enabled")):
		return "Revive cancelled: you are no longer active."
	var body := _body_for(peer_id)
	if body == null or not is_instance_valid(body) or not body.is_inside_tree():
		return "Revive cancelled: the downed teammate is gone."
	if rig.global_position.distance_to(body.global_position) > revive_radius_m:
		return "Revive cancelled: move back within %.1f m." % revive_radius_m
	var health := _local_health()
	if not is_nan(health):
		if health <= 0.0:
			return "Revive cancelled: you are down."
		if not starting and took_damage(_progress_last_health, health):
			return "Revive cancelled: you took damage."
		if not starting:
			# Monotonic checkpoint: healing raises the next frame's baseline, so
			# heal-then-damage still cancels even while health remains above the
			# value recorded at tap start.
			_progress_last_health = health
	if not starting:
		if moved_beyond_deadzone(_progress_origin, rig.global_position, revive_move_deadzone_m):
			return "Revive cancelled: stay still."
		if get_tree().current_scene != _progress_scene:
			return "Revive cancelled: the realm changed."
		if _current_realm() != _progress_realm or _peer_realm(peer_id) != _progress_realm:
			return "Revive cancelled: the realm changed."
		if body != _progress_body:
			return "Revive cancelled: the downed teammate's body changed."
	elif _peer_realm(peer_id) != _current_realm():
		return "Revive unavailable across realms."
	return ""


func _cancel_revive(message: String, notify_host: bool = true) -> void:
	if _progress_peer == 0:
		return
	var attempt := _progress_attempt
	if notify_host and attempt > 0 and _multi_peer():
		if _is_host():
			_host_cancel_revive(_local_peer_id(), attempt)
		else:
			rpc_id(HOST_PEER_ID, &"_rpc_revive_cancel", attempt)
	_clear_revive_attempt()
	if not message.is_empty():
		_push_message(message)


func _clear_revive_attempt() -> void:
	var peer_id := _progress_peer
	_unregister_channel_provider()
	_progress_s = 0.0
	_progress_peer = 0
	_progress_origin = Vector3.ZERO
	_progress_last_health = 0.0
	_progress_scene = null
	_progress_realm = ""
	_progress_body = null
	_progress_attempt = 0
	_progress_window = 0
	_restore_revive_prompt(peer_id)


func _local_health() -> float:
	var rig := _local_rig()
	if rig == null or not is_instance_valid(rig):
		return NAN
	var vitals: Variant = rig.get("vitals")
	if vitals == null:
		return NAN
	return float((vitals as RefCounted).get("health"))


func _push_message(message: String) -> void:
	var game := _game()
	if game != null and game.has_method("push_world_message"):
		game.call("push_world_message", message)


## Temporary loose provider for the active channel. Unlike the body-mounted
## prompt, it deliberately has no LOS query: once the tap is accepted, cancel
## must remain the one interact meaning until validation ends the state.
func interaction_offer(_from: Vector3) -> Dictionary:
	if _progress_peer == 0:
		return {}
	return PROMPT_ARBITER.offer(
		"Cancel revive for %s · %.1f / %.1f s"
			% [_downed_name(_progress_peer), minf(_progress_s, revive_progress_s), revive_progress_s],
		0.0, CHANNEL_PROMPT_PRIORITY, true)


func interaction_activate() -> void:
	if _progress_peer != 0:
		_cancel_revive("Revive cancelled.")


func _sync_channel_provider() -> void:
	if _progress_peer == 0 or not is_inside_tree():
		_unregister_channel_provider()
		return
	var arbiter := get_tree().get_first_node_in_group(INTERACTION_ARBITER.GROUP)
	if arbiter == _channel_arbiter and is_instance_valid(_channel_arbiter):
		return
	_unregister_channel_provider()
	if arbiter != null and arbiter.has_method("register"):
		arbiter.call("register", self)
		_channel_arbiter = arbiter


func _unregister_channel_provider() -> void:
	if _channel_arbiter != null and is_instance_valid(_channel_arbiter) \
			and _channel_arbiter.has_method("unregister"):
		_channel_arbiter.call("unregister", self)
	_channel_arbiter = null


func _current_realm() -> String:
	var game := _game()
	return str(game.get("current_realm")) if game != null else ""


func _peer_realm(peer_id: int) -> String:
	var game := _game()
	if game != null and game.has_method("realm_of_peer"):
		return str(game.call("realm_of_peer", peer_id))
	return _current_realm()


## The channel cares about deliberate ground movement. Height corrections from
## slopes, collision settling and replicated terrain never spend this budget.
static func moved_beyond_deadzone(start: Vector3, current: Vector3, deadzone_m: float) -> bool:
	return Vector2(start.x, start.z).distance_to(Vector2(current.x, current.z)) \
		> maxf(0.0, deadzone_m)


static func took_damage(start_health: float, current_health: float) -> bool:
	return not is_nan(start_health) and not is_nan(current_health) \
		and current_health < start_health - 0.001


## The downed teammate whose body is nearest the local rig and inside
## `revive_radius_m`, or 0 for none. Measured body-to-body: standing over
## somebody is a position, not a look direction.
func _nearest_downed_in_reach() -> int:
	var rig := _local_rig()
	if rig == null:
		return 0
	var best := 0
	var best_d := revive_radius_m
	for body in _remote_bodies():
		var peer_id := int(body.get("peer_id"))
		if not _downed_peers.has(peer_id):
			continue
		var d := rig.global_position.distance_to(body.global_position)
		if d <= best_d:
			best_d = d
			best = peer_id
	return best


# --- the wire -----------------------------------------------------------------

func _broadcast_downed() -> void:
	if not _multi_peer():
		return
	rpc(&"_rpc_downed", _local_display_name(), _local_window)


func _broadcast_up() -> void:
	if not _multi_peer():
		return
	rpc(&"_rpc_up")


## Somebody else went down. The SENDER id is the truth about who -- an argument
## naming a peer would be a second, forgeable answer to a question the
## transport already answers.
@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_downed(display_name: String, window: int) -> void:
	var sender := _remote_sender_id()
	if sender == 0 or sender == _local_peer_id() or window <= 0 \
			or not _registered_peer(sender):
		return
	if window <= int(_peer_window_highwater.get(sender, 0)):
		return
	_downed_peers[sender] = display_name
	_peer_windows[sender] = window
	_peer_window_highwater[sender] = window
	if _is_host():
		_authority.call("note_down", sender, window, _peer_realm(sender), window_s)
	_attach_prompt(sender, display_name)
	var game := _game()
	if game != null and game.has_method("push_world_message"):
		var who := display_name.strip_edges()
		game.call("push_world_message",
			"%s is down. Tap %s near them to start reviving."
				% [who if not who.is_empty() else "Your teammate", "interact"])
	print("[downed] peer %d is down ('%s')" % [sender, display_name])


## Somebody else is back on their feet -- revived, or dead and respawned. Both
## end the same way here: there is nothing to revive any more.
@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_up() -> void:
	var sender := _remote_sender_id()
	if sender == 0 or not _registered_peer(sender):
		return
	if _is_host():
		_authority.call("forget", sender)
	_peer_windows.erase(sender)
	_forget_peer(sender)


@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_revive_start(target: int, window: int, attempt: int) -> void:
	if not _is_host():
		return
	var sender := _remote_sender_id()
	if sender <= 0:
		return
	_host_start_revive(sender, target, window, attempt)


@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_revive_cancel(attempt: int) -> void:
	if not _is_host():
		return
	var sender := _remote_sender_id()
	if sender <= 0:
		return
	_host_cancel_revive(sender, attempt)


@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_revive_notice(event: Dictionary) -> void:
	if _remote_sender_id() != HOST_PEER_ID:
		return
	_apply_revive_notice(event)


@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_revive_grant(window: int) -> void:
	if _remote_sender_id() != HOST_PEER_ID:
		return
	_grant_local_revive(window)


## v2's direct peer completion endpoint is intentionally inert. A matching v3
## lobby is required for Steam; ENet currently has no mixed-build admission
## marker, so old packets fail closed here rather than retaining the bypass.
@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_revive() -> void:
	return


func _grant_local_revive(window: int) -> bool:
	if not _local_downed or window <= 0 or window != _local_window:
		return false
	print("[downed] host authorized revive for window %d" % window)
	_end(true)
	return true


# --- closing the window --------------------------------------------------------

func _end(revived: bool) -> void:
	if not _local_downed:
		return
	_local_downed = false
	_remaining_s = 0.0
	_broadcast_up()
	if _is_host():
		_authority.call("forget", _local_peer_id())
	_local_window = 0
	if revived:
		_revived_count += 1
		_stand_up()
		downed_ended.emit(true)
		return
	_expired_count += 1
	downed_ended.emit(false)
	# The ordinary death, unchanged: `player_death.gd` drains the satchel,
	# drops the bag and fades to the respawn exactly as it always has. It is
	# called LAST so a handler that changes the scene cannot run under a node
	# still mid-teardown of its own state.
	if _death_handler.is_valid():
		_death_handler.call()


## Keep the downed player where they fell. See `_tick_window` for why this is
## re-asserted every frame instead of written once.
func _hold_still() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _player.has_method("set_locomotion_enabled"):
		_player.call("set_locomotion_enabled", false)


func _stand_up() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var vitals: RefCounted = _player.get("vitals")
	if vitals != null and vitals.has_method("revive"):
		vitals.call("revive", revive_health_fraction, revive_stamina_fraction)
	if _player.has_method("set_locomotion_enabled"):
		_player.call("set_locomotion_enabled", true)
	var game := _game()
	if game != null and game.has_method("push_world_message"):
		game.call("push_world_message", "A teammate pulled you back to your feet.")


# --- the prompt on a downed teammate's body ------------------------------------

## Bolt an `interactable.gd` onto the downed peer's `remote_trainer` body. The
## central arbiter owns the fresh interact press and emits this prompt's
## `activated` signal, so starting/cancelling the channel cannot double-fire a
## world interaction behind it.
##
## Added as a child of a body this lane does not own, and removed again by
## name. That is deliberate and it is the whole coupling: `remote_trainer.gd`
## and `remote_trainer.tscn` belong to lane 2.C, the replicated property set is
## authored in that scene's `SceneReplicationConfig`, and nothing here writes
## to either.
func _attach_prompt(peer_id: int, display_name: String) -> void:
	var body := _body_for(peer_id)
	if body == null:
		return
	if body.get_node_or_null(NodePath(PROMPT_NAME)) != null:
		return
	var who := display_name.strip_edges()
	if who.is_empty():
		who = "your teammate"
	var prompt: Node3D = INTERACTABLE.new()
	prompt.name = PROMPT_NAME
	prompt.position = Vector3.UP * PROMPT_HEIGHT
	prompt.call("configure", "Revive %s" % who, revive_radius_m, true)
	prompt.set("priority", PROMPT_PRIORITY)
	prompt.connect("activated", _on_revive_prompt_activated.bind(peer_id))
	body.add_child(prompt)


func _update_revive_prompt(peer_id: int) -> void:
	var prompt := _prompt_for(peer_id)
	if prompt == null:
		return
	prompt.set("label", "Cancel revive for %s · %.1f / %.1f s"
		% [_downed_name(peer_id), minf(_progress_s, revive_progress_s), revive_progress_s])


func _restore_revive_prompt(peer_id: int) -> void:
	var prompt := _prompt_for(peer_id)
	if prompt != null:
		prompt.set("label", "Revive %s" % _downed_name(peer_id))


func _prompt_for(peer_id: int) -> Node:
	var body := _body_for(peer_id)
	return body.get_node_or_null(NodePath(PROMPT_NAME)) if body != null else null


func _downed_name(peer_id: int) -> String:
	var who := str(_downed_peers.get(peer_id, "")).strip_edges()
	return who if not who.is_empty() else "your teammate"


func _forget_peer(peer_id: int) -> void:
	if _progress_peer == peer_id:
		_cancel_revive("")
	_peer_windows.erase(peer_id)
	_clear_progress_notices(peer_id)
	if _is_host():
		_authority.call("forget", peer_id)
	_downed_peers.erase(peer_id)
	var body := _body_for(peer_id)
	if body == null:
		return
	var prompt := body.get_node_or_null(NodePath(PROMPT_NAME))
	if prompt == null:
		return
	body.remove_child(prompt)
	prompt.queue_free()


func _on_peer_left(peer_id: int) -> void:
	_forget_peer(peer_id)
	_peer_window_highwater.erase(peer_id)


func _on_session_ended(_reason: String) -> void:
	_cancel_revive("")
	_authority.call("reset")
	_peer_windows.clear()
	_peer_window_highwater.clear()
	_last_progress_notice.clear()
	for peer_id: Variant in _downed_peers.keys().duplicate():
		_forget_peer(int(peer_id))
	if _local_downed:
		# See the header: a window nobody can close is worse than a death.
		_end(false)


# --- reads --------------------------------------------------------------------

func _game() -> Node:
	return get_node_or_null(GAME_PATH)


func _session() -> Node:
	var game := _game()
	if game == null:
		return null
	return game.get("session") as Node


## THE authority question, asked of the session and never of `multiplayer`.
## See the header.
func _multi_peer() -> bool:
	var game := _game()
	if game == null or not game.has_method("is_multi_peer"):
		return false
	return bool(game.call("is_multi_peer"))


func _is_host() -> bool:
	var session := _session()
	return session != null and session.has_method("is_active") \
		and bool(session.call("is_active")) and session.has_method("is_host") \
		and bool(session.call("is_host"))


func _local_peer_id() -> int:
	var session := _session()
	if session != null and session.has_method("local_peer_id"):
		return int(session.call("local_peer_id"))
	return HOST_PEER_ID


func _remote_sender_id() -> int:
	if not is_inside_tree():
		return 0
	return multiplayer.get_remote_sender_id()


func _registered_peer(peer_id: int) -> bool:
	return peer_id > 0 and _registry_peer_ids().has(peer_id)


## Peer ids in the replicated registry. Empty when there is no session, which
## `_prune()` reads as "forget everybody".
func _registry_peer_ids() -> Array:
	var session := _session()
	if session == null or not session.has_method("is_active") \
			or not bool(session.call("is_active")):
		return []
	if not session.has_method("peers"):
		return []
	var raw: Variant = session.call("peers")
	if not (raw is Array):
		return []
	var out: Array = []
	for entry: Variant in (raw as Array):
		if entry is Dictionary:
			var row: Dictionary = entry
			if row.has("peer_id"):
				out.append(int(row["peer_id"]))
			elif row.has("id"):
				out.append(int(row["id"]))
	return out


func _local_rig() -> Node3D:
	if _player != null and is_instance_valid(_player):
		return _player
	var game := _game()
	if game != null and game.has_method("local_player"):
		return game.call("local_player") as Node3D
	return null


func _remote_bodies() -> Array[Node3D]:
	var out: Array[Node3D] = []
	if not is_inside_tree():
		return out
	var tree := get_tree()
	if tree == null:
		return out
	for node in tree.get_nodes_in_group(REMOTE_TRAINER_GROUP):
		if is_instance_valid(node) and node is Node3D:
			out.append(node as Node3D)
	return out


func _body_for(peer_id: int) -> Node3D:
	for body in _remote_bodies():
		if int(body.get("peer_id")) == peer_id:
			return body
	return null


func _local_display_name() -> String:
	var game := _game()
	if game == null:
		return ""
	var local: Variant = game.get("local")
	if local == null:
		return ""
	return str((local as RefCounted).get("display_name"))
