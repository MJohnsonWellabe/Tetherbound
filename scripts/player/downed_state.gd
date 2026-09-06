extends Node

## Stage B Wave 4 lane 4.E. DOWNED: a player who goes down is a problem their
## friend can solve, not the end of the fight.
##
## Mounted once, lazily, as `/root/Game/DownedState` by
## `scripts/world/player_death.gd::build()` -- a child of the one autoload
## rather than a second autoload (the one-autoload rule), and for the same
## reason `session.gd` is: the node path has to be IDENTICAL in every process
## or the two RPCs below do not resolve at all. `PlayerDeath` itself is a
## per-world component and is rebuilt on every scene change, so it cannot be
## the RPC endpoint; this node is built once and outlives every world.
##
## ## What this is, in one sentence per rule
##
##   1. In a MULTI-PEER session a lethal hit opens a `window_s` window instead
##      of killing: `request_down()` answers `true` and the caller stops.
##   2. A teammate standing within `revive_radius_m` of the downed body and
##      HOLDING interact for `revive_hold_s` brings them back.
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
## Nothing here asks the multiplayer API whether there is a session. Every
## decision goes through `Game.is_multi_peer()` -> `Session.is_multi_peer()`
## -> `peer_count() > 1`, which is the one question that is honestly false in
## a process with no session, and it is re-read on the frame it is needed
## rather than cached at `_ready()`: `join()` swaps the peer under this node's
## feet and a cached answer would be stale across exactly that swap.
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

## Where this mounts. Must be identical in every process; see the header.
const NODE_NAME := "DownedState"
const GAME_PATH := ^"/root/Game"

## The group `scripts/net/remote_trainer.gd` puts every peer's body in. Read
## only; this lane owns none of that file.
const REMOTE_TRAINER_GROUP := &"remote_trainer"

## The action a revive is held on. `data/config/input_contexts.json` lists
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

## D95's ledger channel. Small reliable control traffic, which is what the
## other channel (2, the world snapshot) exists to keep clear of.
const CHANNEL_LEDGER := 1

## Emitted on the downed player's own process when the window opens.
signal downed_began()
## Emitted on the downed player's own process when the window closes.
## `revived` false means the ordinary death has to run now.
signal downed_ended(revived: bool)

var window_s: float = 45.0
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
## Seconds of the current revive hold. Reset the instant the reviver steps out
## of range or lets go -- a revive is a hold, not an accumulator.
var _hold_s: float = 0.0
## Which peer `_hold_s` is being spent on, so stepping from one downed friend
## to another does not inherit the first one's progress.
var _hold_peer: int = 0

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
	_wire_session()


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
	if cfg.has("revive_hold_s"):
		revive_hold_s = maxf(0.0, float(cfg["revive_hold_s"]))
	if cfg.has("revive_radius_m"):
		revive_radius_m = maxf(0.0, float(cfg["revive_radius_m"]))
	if cfg.has("revive_health_fraction"):
		revive_health_fraction = clampf(float(cfg["revive_health_fraction"]), 0.01, 1.0)
	if cfg.has("revive_stamina_fraction"):
		revive_stamina_fraction = clampf(float(cfg["revive_stamina_fraction"]), 0.0, 1.0)


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
	_player = player
	_death_handler = on_expire
	_wire_session()
	# A new world means every body this node knew about is gone with the old
	# scene tree. The prompts died with their bodies; drop the bookkeeping too.
	_downed_peers.clear()
	_hold_s = 0.0
	_hold_peer = 0
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
	_local_downed = true
	_remaining_s = window_s
	_hold_still()
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


func hold_s() -> float:
	return _hold_s


## What a probe or a HUD needs, in one read.
func status() -> Dictionary:
	return {
		"local_downed": _local_downed,
		"remaining_s": remaining_s(),
		"hold_s": _hold_s,
		"hold_peer": _hold_peer,
		"revived": _revived_count,
		"expired": _expired_count,
		"window_s": window_s,
		"revive_hold_s": revive_hold_s,
		"revive_radius_m": revive_radius_m,
		"downed_peers": _downed_peers.keys().map(func(k: Variant) -> int: return int(k)),
	}


# --- the frame ----------------------------------------------------------------

func _process(delta: float) -> void:
	if _local_downed:
		_tick_window(delta)
		return
	_prune()
	_tick_revive(delta)


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


func _tick_revive(delta: float) -> void:
	if _downed_peers.is_empty():
		_hold_s = 0.0
		_hold_peer = 0
		return
	# Late bodies: a `_rpc_downed` can beat the spawner's body by a frame or
	# two, so the prompt is (re)hung here rather than only on arrival.
	for peer_id: Variant in _downed_peers.keys():
		_attach_prompt(int(peer_id), str(_downed_peers[peer_id]))

	var target := _nearest_downed_in_reach()
	if target == 0 or not Input.is_action_pressed(REVIVE_ACTION):
		_hold_s = 0.0
		_hold_peer = 0
		return
	if target != _hold_peer:
		# Stepped from one downed friend to another: the new hold starts at
		# zero rather than inheriting the first one's progress.
		_hold_peer = target
		_hold_s = 0.0
	_hold_s += delta
	if _hold_s < revive_hold_s:
		return
	_hold_s = 0.0
	_hold_peer = 0
	print("[downed] reviving peer %d" % target)
	if _multi_peer():
		rpc_id(target, &"_rpc_revive")


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
	rpc(&"_rpc_downed", _local_display_name())


func _broadcast_up() -> void:
	if not _multi_peer():
		return
	rpc(&"_rpc_up")


## Somebody else went down. The SENDER id is the truth about who -- an argument
## naming a peer would be a second, forgeable answer to a question the
## transport already answers.
@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_downed(display_name: String) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if sender == 0 or sender == multiplayer.get_unique_id():
		return
	_downed_peers[sender] = display_name
	_attach_prompt(sender, display_name)
	var game := _game()
	if game != null and game.has_method("push_world_message"):
		var who := display_name.strip_edges()
		game.call("push_world_message",
			"%s is down. Hold %s over them to revive."
				% [who if not who.is_empty() else "Your teammate", "interact"])
	print("[downed] peer %d is down ('%s')" % [sender, display_name])


## Somebody else is back on their feet -- revived, or dead and respawned. Both
## end the same way here: there is nothing to revive any more.
@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_up() -> void:
	var sender := multiplayer.get_remote_sender_id()
	if sender == 0:
		return
	_forget_peer(sender)


## A teammate finished their hold over THIS player's body.
@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_revive() -> void:
	if not _local_downed:
		# The window already closed -- they were a moment too late, or two
		# people held at once and the first one landed. Not an error.
		return
	print("[downed] revived by peer %d" % multiplayer.get_remote_sender_id())
	_end(true)


# --- closing the window --------------------------------------------------------

func _end(revived: bool) -> void:
	if not _local_downed:
		return
	_local_downed = false
	_remaining_s = 0.0
	_broadcast_up()
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

## Bolt an `interactable.gd` onto the downed peer's `remote_trainer` body so
## the reviver can SEE the offer. Display only: the hold itself is polled in
## `_tick_revive` against the action and the distance, because a prompt tells
## you what a button does and a hold is not a press.
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
	body.add_child(prompt)
	prompt.call("configure", "Revive %s" % who, revive_radius_m, true)
	prompt.set("priority", PROMPT_PRIORITY)


func _forget_peer(peer_id: int) -> void:
	_downed_peers.erase(peer_id)
	if _hold_peer == peer_id:
		_hold_peer = 0
		_hold_s = 0.0
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


func _on_session_ended(_reason: String) -> void:
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
