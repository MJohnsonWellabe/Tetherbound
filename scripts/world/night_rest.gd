extends Node

## What "rest until morning" DOES, in exactly one place -- and, from Stage B
## Wave 5 lane 5.D, WHO HAS TO BE ASLEEP before it happens.
##
## This body used to live only in `scripts/build/camp.gd::_on_rest()` /
## `_pass_the_night()`, on the camp the PLAYER builds. T4-REGIONS' audit
## (`ralph/reports/REGION_AUDIT_2026-08-30.md`, "Camps are set dressing")
## measured the consequence: every AUTHORED camp in the Meadows -- `trail_camp`
## with a bed and a lit bonfire, `ranger_camp` with a bed and an anvil,
## `riverwatch_rest` which is literally named "rest" -- was non-interactable
## scenery, because the only rest in the game was bolted to one buildable. The
## world advertised rest spots that could not be used while the real one was
## portable, which taught the player to walk to a camp and be refused.
##
## `scripts/world/rest_point.gd` is the authored-camp side of the fix. It calls
## this. So do `grandpa_house.gd` and `player_bed.gd`. Four callers, one
## definition of what a night costs and pays, so a change to resting can never
## again apply to only half the camps in the world.
##
## The fade is the same two-node canvas the opening's wake uses, built here
## rather than reached for, because a camp can exist in a world with no
## sequence director.
##
## # D105: sleep is a vote, and the clock is host truth
##
## `rest()` is still the one entry point every bed calls, and SOLO IS UNCHANGED:
## a process with nobody else in its session takes `_rest_alone()`, which is
## byte-for-byte the fade + `pass_the_night()` this file always ran. There is no
## vote to hold and no waiting.
##
## With a second player in the session, `rest()` instead registers this peer as
## sleeping and returns. The HOST tallies; the night falls only when every
## connected, non-downed peer is in a bed, and then every peer runs
## `pass_the_night()` on ITS OWN process -- its own trainer's vitals, its own
## creatures' bed rests, its own `player_slept_at_home`, its own sky. The DAY
## itself is host truth (D105): `Game.advance_day()` already refuses on a
## client, so a client's `pass_the_night()` returns the day it is holding and
## the real number arrives in `_rpc_night_falls`, applied through
## `Game.apply_host_clock()` -- the same seam the once-a-second clock
## replication in `session.gd` uses. A client never advances the day itself.
##
## ## Why this script is a Node now
##
## The tally needs RPCs, and an RPC only resolves when the node holding it sits
## at an IDENTICAL path in every process (`ledger_rpc.gd`'s header says the same
## thing). `attach()` mounts one instance of this script at
## `/root/Game/Session/SleepVote` and is idempotent, so any rest path can call
## it without coordinating who mounts it first and nothing in `game_state.gd`
## had to change. The static entry points (`rest`, `pass_the_night`) are
## untouched by that and every existing caller -- including
## `tools/gate_f/probe_daynight_after_rest.gd` -- keeps calling them the same
## way. Nothing instantiates this script for its own sake.
##
## ## Authority is asked per call, never cached
##
## Godot installs `OfflineMultiplayerPeer` by default: with no session
## `multiplayer.is_server()` is **true** and `get_unique_id()` is **1**, so a
## guard shaped "am I the server" passes in every headless test, capture tool
## and editor run and proves nothing. Every question here goes to the session
## instead (`Game.is_host()`, `Game.is_multi_peer()`), and is asked at the
## moment it matters rather than answered once in `_ready()`.
##
## ## Who is still up
##
## `peer_registry.gd` has carried a `sleeping` field on every row since Wave 2,
## replicated whole with the rest of the registry, explicitly so this wave would
## add behaviour rather than a new field on the wire. That field IS the host's
## tally -- there is no second copy here to disagree with it -- and because the
## registry is broadcast, every peer can derive "who is still up" locally. That
## is why the one line of feedback a sleeping player sees costs no RPC of its
## own.

const SESSION := preload("res://scripts/net/session.gd")

const FADE_SECONDS := 1.2

## `/root/Game/Session/SleepVote`. Same-path-in-every-process is the whole
## requirement; the name is a constant so `attach()` and the tests agree.
const NODE_NAME := "SleepVote"

const CHANNEL_LEDGER := SESSION.CHANNEL_LEDGER
const HOST_PEER_ID := SESSION.HOST_PEER_ID

## A client re-sends its "I am in bed" until the host answers -- see
## `_process()`. One second between tries, and ten tries before the peer gives
## up and stands back up rather than waiting on a night that is never coming.
const RESEND_FRAMES := 60
const RESEND_LIMIT := 10


## Fade out, pass the night, fade back in.
##
## `host` is any node in the live tree -- it owns the tween and the fade layer,
## and it is where the player search starts. It does NOT have to be a child of
## the world: `_find_player()` walks up.
##
## D105: with somebody else in the session this instead casts a vote and
## returns. `is_host()` is consulted as well as `is_multi_peer()` because a
## joiner that beds down inside the handshake window (registry not yet
## replicated, so `peer_count()` still reads 1) is a client all the same, and a
## client must never take the solo path -- it would run a night whose day
## `advance_day()` correctly refuses to move.
static func rest(host: Node) -> void:
	var game := host.get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; the night cannot pass")
		return
	if bool(game.call("is_multi_peer")) or not bool(game.call("is_host")):
		var vote := attach(game)
		if vote != null:
			vote.call("bed_down", host)
			return
	_rest_alone(host, game)


## Today's rest, unchanged: the solo path, and the path every peer runs on its
## own process once the vote passes.
static func _rest_alone(host: Node, game: Node, host_day: int = 0) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 15
	var rect := ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	host.add_child(layer)

	var tween := host.create_tween()
	tween.tween_property(rect, "color:a", 1.0, FADE_SECONDS * 0.5)
	tween.tween_callback(func() -> void: pass_the_night(host, game, host_day))
	tween.tween_interval(0.4)
	tween.tween_property(rect, "color:a", 0.0, FADE_SECONDS * 0.5)
	tween.tween_callback(layer.queue_free)


## The night itself, with no fade around it. Separate so a test (and the
## capture tools) can pass a night without waiting on a tween.
##
## `host_day` is D105's half: 0 means "this process decides", which is what solo
## and the host do (`Game.advance_day()`). A positive number is the day the HOST
## arrived at, handed to a client through `_rpc_night_falls`; a client writes it
## with `Game.apply_host_clock()` and never derives one itself.
static func pass_the_night(host: Node, game: Node = null, host_day: int = 0) -> int:
	if game == null:
		game = host.get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; the night cannot pass")
		return 0
	# `host_day > 0` means the day has ALREADY been decided -- by the host, at
	# the moment the vote passed, so that the number it broadcast and the number
	# it keeps are the same one. Calling `advance_day()` again here would move
	# the host's day twice for one night. On a client it would not (D105:
	# `game_state.gd::advance_day` refuses on a client and hands back the day
	# this peer is already holding), which is exactly the kind of asymmetry that
	# reads fine until somebody hosts.
	var day := host_day if host_day > 0 else int(game.call("advance_day"))
	# GATEB-FLAGS: `player_slept_at_home`, data/progression/objectives.json's
	# ladder. Set here, on the actual completed rest, not on the interact
	# prompt firing -- the objective asks for the sleep itself, not the
	# attempt to start one.
	#
	# Set from an AUTHORED camp too, deliberately. The flag's id says "home"
	# but the rung it clears reads "Rest at camp and let a creature recover",
	# and a player who walks their injured team out to the trail camp, beds
	# one down and sleeps has done that lesson in full. Clearing the objective
	# only for the buildable would be the same "walk to a camp and be refused"
	# defect in a different costume.
	#
	# MP_STATE_SEAM.md §3: written to THE SLEEPER'S OWN store, named explicitly
	# (`Game.player_flags()`), not through the merged view. The actor here is
	# "whoever bedded down", and from Wave 5 this runs on EVERY peer's own
	# process once the vote passes (D105, sleep is a vote) -- routing one write
	# by scope would then credit the host's rest to the host alone. Solo there
	# is exactly one player and this is byte-for-byte today's behaviour.
	var sleeper_flags: RefCounted = game.call("player_flags") if game.has_method("player_flags") \
		else game.get("progression") as RefCounted
	if sleeper_flags != null:
		sleeper_flags.call("set_flag", "player_slept_at_home")
	# Gate A creature-bed contract: sleep completes only pals physically put
	# to bed. Non-resting party members keep their current HP, which is the
	# meaningful preparation tradeoff the bed is supposed to create.
	#
	# Per-peer by construction: `Game.party` is this process's own five, so a
	# co-op night heals each player's own bedded creatures on their own machine
	# and nobody's team is completed by somebody else lying down.
	game.call("complete_creature_bed_rests")
	# The trainer too -- find them by the vitals they carry.
	var player := _find_player(host)
	if player != null:
		var vitals: RefCounted = player.get("vitals")
		if vitals != null and vitals.has_method("rest"):
			vitals.call("rest")
	# "rest to morning" (R5.1) -- by group rather than a direct reference, so a
	# camp in a scene with no day/night setup (a test scene, say) still rests
	# fine with nothing to reset. `reset_to_morning()` also writes the morning
	# clock back onto `Game`, which is why the day is the only number
	# `_rpc_night_falls` has to carry.
	for look: Node in host.get_tree().get_nodes_in_group("day_cycle"):
		if look.has_method("reset_to_morning"):
			look.call("reset_to_morning")
	# D105: the host's day, written the one way a client is allowed to receive
	# it. `apply_host_clock()` is a no-op on the host, so this line is inert on
	# the process that just advanced the day itself. `-1.0` leaves the clock
	# alone: `reset_to_morning()` above already put this peer at dawn, and
	# overwriting that with the host's elapsed seconds would drag the sleeper
	# back to whatever fraction of a second the host was at.
	if host_day > 0:
		game.call("apply_host_clock", host_day, -1.0)
		day = int(game.get("day"))
	# R3.1. "Frequent autosave" -- resting is the natural checkpoint this game
	# already asks the player to return to, the same precedent survival games
	# with a sleep beat use for it.
	#
	# D100/lane 2.A: routed, not called directly. This is one of the four
	# autosave sites, and on a client the world half is not this process's to
	# write -- `Game.autosave_here()` writes the world only when
	# `Session.is_host()`, and each peer's own character always. Solo is a
	# one-peer session, so solo behaviour is byte-for-byte what it was.
	game.call("autosave_here")
	print("[rest] rested; day %d" % day)
	return day


## The trainer, from anywhere in the world's subtree.
##
## `camp.gd` could read `get_parent().get_node_or_null(^"Player")` because a
## placed camp is a direct child of the world. An authored rest point is three
## levels down (world -> Props -> cluster group -> here), so this walks up
## until it finds the ancestor that owns a "Player" child -- the same shape
## `props.gd::_ground_height()` already uses to find `ground_height_at`.
static func _find_player(host: Node) -> Node:
	var node: Node = host
	while node != null:
		var player := node.get_node_or_null(^"Player")
		if player != null:
			return player
		node = node.get_parent()
	return null


# --- D105: the vote ------------------------------------------------------------
#
# Everything below runs only on the mounted `/root/Game/Session/SleepVote`
# instance, and only when there is a second player in the session.

## True while THIS peer is lying down waiting for the others. Local, never
## replicated -- the replicated answer is the registry's `sleeping` field, and
## keeping two writable copies of one fact is how they come to disagree.
var _sleeping_here: bool = false

## The bed (or house, or authored camp) this peer bedded down at. Kept because
## `pass_the_night()` searches UP from it for the Player, and this node sits
## under `/root/Game`, which is not above the world.
var _bed: Node = null

var _resend_frames: int = 0
var _resend_left: int = 0

## The registry fingerprint this peer last rendered its feedback line from, so a
## replicated change repaints once instead of every frame.
var _seen_fingerprint: int = 0
var _last_line: String = ""


## Find or mount the vote under the session. Returns the node, or `null` when
## there is no `Game` to hang it off. Idempotent.
static func attach(game: Node) -> Node:
	if game == null:
		return null
	var parent: Node = game.get("session") as Node
	if parent == null:
		parent = game
	var existing := parent.get_node_or_null(NodePath(NODE_NAME))
	if existing != null:
		return existing
	var node: Node = (load("res://scripts/world/night_rest.gd") as GDScript).new()
	node.name = NODE_NAME
	parent.add_child(node)
	return node


func _ready() -> void:
	name = NODE_NAME
	process_mode = Node.PROCESS_MODE_ALWAYS
	var session := _session()
	if session != null:
		# A peer that drops while asleep must not hold the night open, and a
		# peer that drops while AWAKE must not hold it open either -- both are
		# the same re-tally, so both arrive here.
		if session.has_signal("peer_left") and not session.is_connected("peer_left", _on_roster_changed):
			session.connect("peer_left", _on_roster_changed)
		if session.has_signal("peer_joined") and not session.is_connected("peer_joined", _on_peer_joined):
			session.connect("peer_joined", _on_peer_joined)


## Lie down, or (a second interaction with the bed) get back up. A vote nobody
## can leave is a trap: the player who changed their mind would otherwise be
## stuck standing next to a bed with no way to withdraw.
##
## Deliberately no fade while waiting. The world stays playable until the night
## actually falls, so a player whose friend is still fighting something has not
## been locked into a black screen by a button press.
func bed_down(bed: Node) -> void:
	var game := _game()
	if game == null:
		return
	if _sleeping_here:
		_stand_up(game)
		return
	_sleeping_here = true
	_bed = bed
	if bool(game.call("is_host")):
		_resend_left = 0
		_set_sleeping(_local_peer_id(), true)
		_evaluate()
	else:
		_resend_left = RESEND_LIMIT
		_resend_frames = RESEND_FRAMES
		_send_intent(true)
	_repaint(true)


func is_sleeping_here() -> bool:
	return _sleeping_here


## Who this peer believes is still up, by display name, from the replicated
## registry. Public because the net smoke asserts on it and because a HUD lane
## may later want it; it reads, it never decides.
##
## A peer that is lying down never counts ITSELF as up, even before the host's
## registry broadcast has come back marking it asleep -- otherwise the very
## first line a client sees after pressing the bed says it is waiting for
## itself.
func awake_names() -> Array:
	var out: Array = []
	var me := _local_peer_id() if _sleeping_here else 0
	for raw: Variant in _rows():
		var row: Dictionary = raw
		if int(row["peer_id"]) == me:
			continue
		if bool(row.get("sleeping", false)) or bool(row.get("downed", false)):
			continue
		var who := str(row.get("display_name", "")).strip_edges()
		out.append(who if not who.is_empty() else "Trainer %d" % int(row.get("peer_id", 0)))
	return out


func _stand_up(game: Node) -> void:
	_sleeping_here = false
	_bed = null
	_resend_left = 0
	if bool(game.call("is_host")):
		_set_sleeping(_local_peer_id(), false)
	else:
		_send_intent(false)
	_last_line = ""
	game.call("push_world_message", "You get up again.")


# --- host side ------------------------------------------------------------------

## HOST ONLY. Does the night fall yet?
##
## It does when at least one peer is in a bed and NOBODY who could still vote is
## up. A downed player is not counted as up (rule 5): a friend who cannot be
## revived would otherwise hold the night hostage. A peer that has left is not
## counted at all -- it is no longer in the registry, which is what makes a
## disconnect-while-asleep resolve instead of hanging.
func _evaluate() -> void:
	var game := _game()
	if game == null or not bool(game.call("is_host")):
		return
	var sleeping := 0
	var awake := 0
	for raw: Variant in _rows():
		var row: Dictionary = raw
		if bool(row.get("sleeping", false)):
			sleeping += 1
		elif not bool(row.get("downed", false)):
			awake += 1
	if sleeping == 0:
		return
	if awake > 0:
		_repaint(false)
		return
	_night_falls(game)


## HOST ONLY. Decide the day, tell everyone, clear the tally, then pass the
## night on this process too.
##
## The order is load-bearing. The day is advanced FIRST and the same number is
## what goes on the wire and what the host's own `pass_the_night()` is handed --
## the host's night runs behind a 0.6 s fade, and broadcasting `Game.day` after
## starting that fade would send the day the host had not left yet. The
## night-falls RPC goes out BEFORE the cleared registry, on the same reliable
## ordered channel, so a sleeping client learns the night fell before it learns
## nobody is marked asleep any more and never flashes "waiting for" at a world
## that is already morning.
func _night_falls(game: Node) -> void:
	var day := int(game.call("advance_day"))
	if _can_rpc() and bool(game.call("is_multi_peer")):
		rpc("_rpc_night_falls", day)
	var registry: RefCounted = _registry()
	if registry != null:
		for raw: Variant in _rows():
			var row: Dictionary = raw
			registry.call("set_flag", int(row["peer_id"]), "sleeping", false)
		_broadcast_registry()
	_night_here(day)


## Write one peer's vote into the registry -- the host's only tally -- and
## replicate it, so every peer can render who is still up without an RPC of its
## own. `peer_registry.gd::set_flag` accepts exactly `sleeping` and `downed`.
func _set_sleeping(peer_id: int, sleeping: bool) -> void:
	var registry: RefCounted = _registry()
	if registry == null:
		return
	if bool(registry.call("set_flag", peer_id, "sleeping", sleeping)):
		_broadcast_registry()


func _broadcast_registry() -> void:
	var session := _session()
	if session != null and session.has_method("_broadcast_registry"):
		session.call("_broadcast_registry")


func _on_roster_changed(_peer_id: int = 0) -> void:
	_evaluate()


func _on_peer_joined(_peer_id: int = 0, _character_id: String = "") -> void:
	_evaluate()


# --- rpc --------------------------------------------------------------------------

## Client -> host. The sender id comes from the transport, never from the
## payload, so a peer cannot cast somebody else's vote.
@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_sleeping(sleeping: bool) -> void:
	var game := _game()
	if game == null or not bool(game.call("is_host")):
		return
	_set_sleeping(multiplayer.get_remote_sender_id(), sleeping)
	_evaluate()


## Host -> everyone. The vote passed; `day` is the number the host arrived at.
@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_night_falls(day: int) -> void:
	var game := _game()
	if game == null or bool(game.call("is_host")):
		return
	_night_here(day)


# --- applying the night on this peer -------------------------------------------------

func _night_here(host_day: int) -> void:
	var game := _game()
	if game == null:
		return
	var bed := _bed if (_bed != null and is_instance_valid(_bed) and _bed.is_inside_tree()) else _fallback_bed()
	_sleeping_here = false
	_bed = null
	_resend_left = 0
	_last_line = ""
	if bed == null:
		# No live node to hang a fade on (a downed player whose body went away,
		# a peer mid scene change). The night still has to happen for this peer
		# or its day would diverge from the host's, so it happens without one.
		pass_the_night(self, game, host_day)
		return
	_rest_alone(bed, game, host_day)


## A peer that never bedded down (rule 5's downed player) still needs somewhere
## for `pass_the_night()` to start its Player search: the world root, which IS
## the ancestor that owns a "Player" child.
func _fallback_bed() -> Node:
	var tree := get_tree()
	return null if tree == null else tree.current_scene


# --- the one line of feedback ----------------------------------------------------

## "Waiting for Ana." on the peer that just lay down, repainted when the
## replicated registry actually changes. One line, no panel.
func _repaint(force: bool) -> void:
	if not _sleeping_here:
		return
	var game := _game()
	if game == null:
		return
	var names := awake_names()
	var line := ""
	if names.is_empty():
		line = "You settle in for the night."
	elif names.size() == 1:
		line = "You lie down. Waiting for %s." % str(names[0])
	else:
		line = "You lie down. Waiting for %d others." % names.size()
	if not force and line == _last_line:
		return
	_last_line = line
	game.call("push_world_message", line)


# --- the client's retry ------------------------------------------------------------

## Two jobs, both only while this peer is lying down.
##
## The retry exists because this node is mounted lazily: a client that beds down
## first can send its vote to a host that has not mounted its own copy yet, and
## an RPC to a node that does not exist is dropped in silence. Re-sending until
## the host answers turns that race into a delay instead of a night that never
## comes. It gives up after `RESEND_LIMIT` tries rather than waiting forever.
##
## The repaint polls the registry fingerprint rather than a signal because
## `session.gd` does not emit one for a replicated registry, and this is one
## integer compare on a peer that is asleep.
func _process(_delta: float) -> void:
	if not _sleeping_here:
		return
	var game := _game()
	if game == null:
		return
	if not bool(game.call("is_host")) and _resend_left > 0:
		_resend_frames -= 1
		if _resend_frames <= 0:
			_resend_frames = RESEND_FRAMES
			_resend_left -= 1
			if _resend_left <= 0:
				game.call("push_world_message", "Nobody answered. You get up again.")
				_sleeping_here = false
				_bed = null
				_last_line = ""
				return
			_send_intent(true)
	var session := _session()
	if session == null:
		return
	var fingerprint := int(session.call("registry_fingerprint"))
	if fingerprint == _seen_fingerprint:
		return
	_seen_fingerprint = fingerprint
	_repaint(false)


func _send_intent(sleeping: bool) -> void:
	if not _can_rpc():
		return
	rpc_id(HOST_PEER_ID, "_rpc_sleeping", sleeping)


# --- internals ----------------------------------------------------------------------

## Every registry row, each one guaranteed to carry `peer_id` before anything
## reads it. `peer_registry.gd::make_row`/`load_data` build every row with every
## key, but a row that arrived malformed would read `int(null) == 0` here and
## silently become "peer 0", which is a vote nobody cast.
func _rows() -> Array:
	var session := _session()
	if session == null:
		return []
	var out: Array = []
	for raw: Variant in (session.call("peers") as Array):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = raw
		if not row.has("peer_id") or int(row["peer_id"]) == 0:
			continue
		out.append(row)
	return out


func _registry() -> RefCounted:
	var session := _session()
	if session == null:
		return null
	return session.call("registry") as RefCounted


func _local_peer_id() -> int:
	var session := _session()
	if session == null:
		return HOST_PEER_ID
	return int(session.call("local_peer_id"))


## False solo and in every headless test, where `rpc()` with no peer is an
## error rather than a no-op.
func _can_rpc() -> bool:
	if not is_inside_tree():
		return false
	var api := multiplayer
	return api != null and api.has_multiplayer_peer()


func _session() -> Node:
	var game := _game()
	if game == null:
		return null
	return game.get("session") as Node


func _game() -> Node:
	return get_node_or_null(^"/root/Game")
