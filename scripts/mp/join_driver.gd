extends Node

## Stage B Wave 2 lane 2.B. THE JOIN, once the world is standing.
##
## Mounted under `/root/Game` by `scripts/ui/title_screen.gd`, which then loads
## the world scene and is freed. This node is what survives that and does the
## actual dialling.
##
## ## Why the world is built FIRST, and the socket opened second
##
## Measured, not guessed (`ralph/reports/MP-2B-JOINUI-0906/REPORT.md`): a peer
## holding a live ENet connection does NOT survive building the Meadows. That
## build is one blocking frame of ~85 s (spike S2,
## `ralph/reports/MP-0D-SPIKE-HOSTCOST-0905/`) during which nothing services
## the socket, and ENet's own peer timeout is tens of seconds -- so a joiner
## that connected on the title screen and then loaded the world arrived in it
## already disconnected, was sent back to the title by
## `session.gd::_on_server_disconnected`, dialled again, and looped forever at
## about ninety seconds a lap.
##
## So the order is inverted: the joiner enters the world with NO session at all
## (which the codebase supports everywhere -- a session-less process is
## `is_host()` true, one peer, and simply cannot be joined), pays the build
## cost while there is no connection to lose, and dials from the far side.
## `game_state.gd::apply_world_snapshot()` was already written for exactly this
## arrival: "a joiner whose Meadows is already standing has to be told which
## one-shot pickups are gone and which fences exist, not merely handed the
## data."
##
## The alternative fix -- a longer ENet peer timeout -- lives in
## `scripts/net/session.gd`, which lane 2.A owns and this lane does not touch.
## It is recorded as a handover rather than reached for.
##
## ## Two failures, two messages
##
## They send the player to different fixes and are never collapsed into one
## "could not join":
##
##   * the connect never lands -- nothing is listening at that address. Wrong
##     address, or a host who has not opened their world.
##   * the connect lands and the world snapshot never arrives -- the address
##     was right and the host is not ready.
##
## Told apart by ENet's own timing rather than by reading `session.gd`'s
## private state: ENet reports an unreachable host well inside the session
## config's `connect_timeout_s`, so a dial still silent after that window is a
## dial that connected.

const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"

## Frames to let the freshly-loaded world settle before dialling. The world's
## own `_ready` has finished by the time `current_scene` changes, but its
## children spread their first work over the next frames, and a snapshot
## applied into a half-settled scene is the kind of thing that works until it
## does not.
const SETTLE_FRAMES := 30

## Seconds between re-dials while retrying. Long enough not to spin the
## socket, short enough that a client is in the world within a couple of
## seconds of the host becoming ready.
const RETRY_INTERVAL_S := 2.0

signal joined()
signal failed(message: String)

var _address := ""
var _port := 0
var _state := ""
var _settle := 0
var _retry_until_ms := 0.0
var _retry_at_ms := 0.0
var _connect_deadline_ms := 0.0
var _handshake_deadline_ms := 0.0
var _last_error := ""


func _ready() -> void:
	name = "JoinDriver"
	# The pause menu pauses the tree, and a player who opens their satchel
	# while a dial is in flight must not stall it.
	process_mode = Node.PROCESS_MODE_ALWAYS


## Start. Called by the title screen BEFORE it changes to the world scene;
## nothing is dialled until that scene is actually up (`_process`).
##
## `retry_for_s` > 0 keeps re-dialling both kinds of failure until then, which
## only the `--mp-join` launcher asks for: `tools/owner/` starts a host and
## three clients in the same second and every one of them is inside its own
## world build. A player who typed an address gets the answer instead.
func begin(address: String, port: int, retry_for_s: float) -> void:
	_address = address
	_port = port
	_state = "waiting_for_world"
	_settle = SETTLE_FRAMES
	_last_error = ""
	_retry_until_ms = Time.get_ticks_msec() + retry_for_s * 1000.0 if retry_for_s > 0.0 else 0.0


## The message the last attempt failed with, for the title screen to show once
## the player is back on it. Empty while a join is in flight or succeeded.
func last_error() -> String:
	return _last_error


func target() -> String:
	return "%s:%d" % [_address, _port]


func is_running() -> bool:
	return _state != ""


func _process(_delta: float) -> void:
	match _state:
		"waiting_for_world":
			_tick_waiting()
		"dialling":
			_tick_dialling()


func _tick_waiting() -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	# Still the title screen: the change has not landed yet. Asked by group
	# rather than by script path, the way everything else in this repo finds
	# that screen.
	if tree.current_scene.is_in_group(&"title_screen"):
		return
	_settle -= 1
	if _settle > 0:
		return
	print("[join] world is up; dialling %s" % target())
	_dial()


func _dial() -> void:
	var session := _session()
	if session == null:
		_fail("This build has no multiplayer session to join with.")
		return
	var config: Dictionary = session.call("config")
	var now := float(Time.get_ticks_msec())
	_connect_deadline_ms = now + float(config.get("connect_timeout_s", 20.0)) * 1000.0
	_handshake_deadline_ms = _connect_deadline_ms + float(config.get("handshake_timeout_s", 60.0)) * 1000.0
	_retry_at_ms = 0.0
	_state = "dialling"
	if not bool(session.call("join", _address, _port)):
		_retry_or_fail("Could not open a connection to %s. Check the address." % target())


## Polled, never awaited: `Session` is deliberately coroutine-free and every
## caller polls it a frame at a time.
func _tick_dialling() -> void:
	var session := _session()
	if session == null:
		_fail("The multiplayer session went away mid-join.")
		return
	var now := float(Time.get_ticks_msec())

	# Checked FIRST, and both halves of it. `handshake_failed()` is the honest
	# "this will never finish"; `is_active()` false after a dial means the peer
	# was torn down under us. Neither can be inferred from `snapshot_ready()`,
	# which `_teardown()` puts back to TRUE on the way out -- it answers "may
	# this process act in the world", and a process with no session may.
	if bool(session.call("handshake_failed")) or not bool(session.call("is_active")):
		_retry_or_fail("No game answered at %s. Check the address, and that the host has their world open." % target())
		return

	if bool(session.call("snapshot_ready")):
		_state = ""
		_retry_until_ms = 0.0
		_last_error = ""
		print("[join] joined %s; the host's world is applied" % target())
		var game := _game()
		if game != null and game.has_method("push_world_message"):
			game.call("push_world_message", "You joined the world.")
		joined.emit()
		return

	if now > _handshake_deadline_ms:
		_retry_or_fail("Reached %s, but their world never arrived. The host may not be ready — ask them to load their game, then try again." % target())


func _retry_or_fail(message: String) -> void:
	var now := float(Time.get_ticks_msec())
	if _retry_until_ms > 0.0 and now < _retry_until_ms:
		if _retry_at_ms <= 0.0:
			_retry_at_ms = now + RETRY_INTERVAL_S * 1000.0
			print("[join] %s is not ready yet; retrying (%s)" % [target(), message])
		elif now >= _retry_at_ms:
			_dial()
		return
	_fail(message)


## Give up. The socket is closed properly rather than abandoned -- a title
## screen holding a half-open client peer would make the next Start New Game
## host into a session it was already a client of -- and the player is put back
## where they can do something about it, carrying the reason with them
## (`title_screen.gd` reads `last_error()` on its way up).
func _fail(message: String) -> void:
	_state = ""
	_retry_until_ms = 0.0
	_last_error = message
	push_warning("join failed: %s" % message)
	var session := _session()
	if session != null and bool(session.call("is_active")) and str(session.call("mode")) == "client":
		session.call("leave", "join_failed")
	failed.emit(message)
	var tree := get_tree()
	if tree != null:
		tree.change_scene_to_file(TITLE_SCENE)


func _game() -> Node:
	return get_node_or_null(^"/root/Game")


func _session() -> Node:
	var game := _game()
	if game == null:
		return null
	var s: Variant = game.get("session")
	return s as Node
