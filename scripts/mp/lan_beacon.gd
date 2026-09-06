extends Node

## Stage B Wave 2 lane 2.B. THE LAN BEACON: how a player finds a friend's game
## without typing an address.
##
## D95 is the transport contract -- direct IP plus a LAN beacon, no relay, no
## Steam -- and this is the beacon half of it. The host shouts a small JSON
## packet onto the local broadcast address once a second; a title screen
## sitting on "Games on this network" listens for them and ages them out.
##
## ## One file, both ends, deliberately
##
## The sender and the reader are two halves of ONE packet format. Split across
## two files they drift the first time a key is renamed, and the failure is
## silent: an unrecognised packet is indistinguishable from no host at all.
## `serve()` and `listen()` are the two modes; a node is one or the other for
## its whole life.
##
## ## What it is NOT
##
##  * Not the transport. Nothing here opens, closes or touches
##    `multiplayer.*`; the beacon only ADVERTISES a port
##    `scripts/net/session.gd` already bound. A beacon that lied would cost a
##    failed connect, never a broken session.
##  * Not authority. The address a listener stores is the one the SOCKET
##    reports the packet arrived from (`get_packet_ip()`), never an address a
##    packet claims for itself -- a broadcaster cannot talk a listener into
##    dialling a third machine.
##  * Not required. Every game is reachable by typed address whether or not a
##    beacon packet ever lands; the LAN list is a convenience over the same
##    `Session.join(ip, port)` the address prompt calls.
##
## ## The one-machine limit, stated rather than discovered
##
## Godot's `PacketPeerUDP` exposes no SO_REUSEPORT, so exactly ONE process per
## machine can `bind()` the beacon port. That is fine for the case the beacon
## exists to serve (several machines on one LAN) and it is why
## `tools/owner/`'s four-processes-on-one-box kit uses `--mp-join` on the
## command line instead of the list (see `scripts/ui/title_screen.gd`). A
## second listener on one box gets `listen_error()` -- a sentence for the
## player, not a silent empty list.

## Identifies our packets on a port somebody else's software may also be using.
## Checked before anything else in the payload is read.
const GAME_TAG := "tetherbound-lan"

## Bumped when the payload's shape changes in a way an older reader would
## misread. A listener ignores a packet whose version it does not know, which
## is the honest answer -- an unreadable advert is not a host you can join.
const PROTOCOL_VERSION := 1

## The beacon lives one port above the session's own (27015 -> 27016) unless
## `data/config/multiplayer.json`'s `session.beacon_port` names one. Derived
## rather than hard-coded so a host moved to a non-default port with
## `--mp-host 27100` advertises on 27101 and is still found.
const PORT_OFFSET := 1

## Seconds between broadcasts. One second is a list that feels live without
## being chatty: three packets of ~150 bytes a second on a LAN with three
## hosts advertising.
const BROADCAST_INTERVAL_S := 1.0

## Seconds a listener keeps a host in its list after the last packet from it.
## Four missed broadcasts, so one dropped packet never blinks a game out of
## the list, and a host that quits disappears inside five seconds rather than
## staying there to be dialled into a refusal.
const ENTRY_TTL_S := 5.0

## Bytes a single advert may occupy. A packet larger than this is not ours or
## is not honest; read and dropped rather than parsed.
const MAX_PACKET_BYTES := 1024

## Consecutive `put_packet` failures before the beacon stops trying. Three,
## because one is a blip and three in a row is a machine that cannot broadcast.
const MAX_SEND_FAILURES := 3

const CONFIG_PATH := "res://data/config/multiplayer.json"

## "" (idle), "serve" or "listen". A node never changes mode.
var _mode: String = ""
var _udp: PacketPeerUDP = null
var _port: int = 0
var _accum: float = 0.0
var _listen_error: String = ""
## Consecutive failed broadcasts. A machine with no route for
## 255.255.255.255 (a locked-down box, a CI container) would otherwise fail
## once a second forever; after this many in a row the beacon gives up and
## says so once. The game is unaffected either way -- it is still hosted and
## still joinable by typed address.
var _send_failures: int = 0

## address|port -> the last advert seen from it, plus `seen_ms`. Keyed on both
## halves because one machine can host two games on two ports.
var _found: Dictionary = {}

## The port the served session is actually on, handed in by the caller rather
## than read back off the session: `session.gd` does not expose its bound port,
## and the caller is the one that chose it (`title_screen.gd::_enter_world`).
var _served_port: int = 0


## The beacon port for a session on `session_port`. Static so the join screen
## can ask without standing a node up.
static func beacon_port_for(session_port: int) -> int:
	var configured := _config_beacon_port()
	if configured > 0:
		return configured
	return maxi(1, session_port) + PORT_OFFSET


static func _config_beacon_port() -> int:
	var f := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if f == null:
		return 0
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return 0
	var section: Variant = (parsed as Dictionary).get("session", {})
	if typeof(section) != TYPE_DICTIONARY:
		return 0
	return int((section as Dictionary).get("beacon_port", 0))


func _ready() -> void:
	# The title screen never pauses, but a host mounts this under `/root/Game`
	# and the pause menu pauses the tree -- a beacon that stopped while the
	# menu was open would drop a friend's game out of their list because
	# somebody checked their satchel.
	process_mode = Node.PROCESS_MODE_ALWAYS


## Start advertising a hosted session on `session_port`. Returns false when the
## broadcast socket could not be opened, which is not fatal to anything: the
## game is still hosted and still joinable by typed address.
func serve(session_port: int) -> bool:
	if _mode != "":
		return _mode == "serve"
	_served_port = maxi(1, session_port)
	_port = beacon_port_for(_served_port)
	var udp := PacketPeerUDP.new()
	udp.set_broadcast_enabled(true)
	var err := udp.set_dest_address("255.255.255.255", _port)
	if err != OK:
		push_warning("lan_beacon.serve: set_dest_address(255.255.255.255, %d) failed err=%d" % [_port, err])
		return false
	_udp = udp
	_mode = "serve"
	# Sent immediately as well as on the interval: a friend already sitting on
	# the LAN list should see the game appear when it opens, not up to a
	# second later.
	_accum = BROADCAST_INTERVAL_S
	print("[lan] advertising udp/%d for a session on udp/%d" % [_port, _served_port])
	return true


## Start listening for adverts for sessions whose game port is `session_port`
## (the default port, unless a caller is looking somewhere unusual). Returns
## false when the port could not be bound; `listen_error()` says why in words a
## player can act on.
func listen(session_port: int) -> bool:
	if _mode != "":
		return _mode == "listen"
	_port = beacon_port_for(maxi(1, session_port))
	var udp := PacketPeerUDP.new()
	var err := udp.bind(_port, "*")
	if err != OK:
		_listen_error = "Could not open the network listener on udp/%d. Another copy of the game on this machine may already have it." % _port
		push_warning("lan_beacon.listen: bind(%d) failed err=%d" % [_port, err])
		return false
	_udp = udp
	_mode = "listen"
	print("[lan] listening for games on udp/%d" % _port)
	return true


## Stop, whichever end this is. Safe to call twice, and safe on a node that
## never started.
func stop() -> void:
	if _udp != null:
		_udp.close()
	_udp = null
	_mode = ""
	_found.clear()


func mode() -> String:
	return _mode


func port() -> int:
	return _port


## The GAME port this beacon is advertising (as opposed to `port()`, the
## beacon's own). Also the one honest record of what `Session.host()` was
## actually asked to bind: the session does not expose its bound port, and the
## title screen -- which chose it, possibly from `--mp-host 27100` -- hands it
## here on the way into the world. `scripts/ui/tab_players.gd` reads it to tell
## a solo player the address a friend should type. 0 when nothing was served.
func served_port() -> int:
	return _served_port


func listen_error() -> String:
	return _listen_error


## Games seen recently, newest advert first within a stable address order, each
## a Dictionary of `address`, `port`, `name`, `players`, `max_players`, `day`
## and `realm`. Expired entries are dropped here rather than in `_process`, so
## a caller that polls once a second still sees a five-second TTL honoured
## exactly.
func games() -> Array:
	var now := Time.get_ticks_msec()
	var out: Array = []
	for key: Variant in _found.keys():
		var row: Dictionary = _found[key]
		if now - int(row.get("seen_ms", 0)) > int(ENTRY_TTL_S * 1000.0):
			continue
		out.append(row.duplicate(true))
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if str(a.get("address", "")) == str(b.get("address", "")):
			return int(a.get("port", 0)) < int(b.get("port", 0))
		return str(a.get("address", "")) < str(b.get("address", "")))
	return out


## A stamp that changes when the LIST changes shape or content. The join screen
## rebuilds its rows only when this moves -- rebuilding a focusable list every
## frame is how a controller cursor becomes unmovable (`menu_tab.gd`'s own
## `revision()` rule, applied to a list that arrives off a socket).
func fingerprint() -> String:
	var parts: Array[String] = []
	for row: Variant in games():
		var g: Dictionary = row
		parts.append("%s:%d/%s/%d" % [str(g.get("address", "")), int(g.get("port", 0)),
			str(g.get("name", "")), int(g.get("players", 0))])
	return "|".join(parts)


func _process(delta: float) -> void:
	match _mode:
		"serve":
			_tick_serve(delta)
		"listen":
			_tick_listen()


func _tick_serve(delta: float) -> void:
	var session := _session()
	# A host that left, or whose bind failed after all, stops advertising a
	# game nobody can join. Asked of the session every tick rather than cached
	# at `serve()`: authority is re-read, never remembered.
	if session == null or not bool(session.call("is_active")) or not bool(session.call("is_host")):
		return
	_accum += delta
	if _accum < BROADCAST_INTERVAL_S:
		return
	_accum = 0.0
	if _udp == null:
		return
	if _udp.put_packet(JSON.stringify(_advert(session)).to_utf8_buffer()) == OK:
		_send_failures = 0
		return
	_send_failures += 1
	if _send_failures >= MAX_SEND_FAILURES:
		push_warning("lan_beacon: this machine cannot broadcast on udp/%d; the game stays joinable by typed address" % _port)
		stop()


func _advert(session: Node) -> Dictionary:
	var game := _game()
	var host_name := "Trainer"
	var day := 1
	var realm := "meadows"
	if game != null:
		var local: Variant = game.get("local")
		if local != null:
			var n := str((local as RefCounted).get("display_name"))
			if not n.is_empty():
				host_name = n
		realm = str(game.get("current_realm"))
		var world: Variant = game.get("world")
		if world != null:
			day = int((world as Object).get("day"))
	return {
		"tag": GAME_TAG,
		"v": PROTOCOL_VERSION,
		"name": "%s's world" % host_name,
		"port": _served_port,
		"players": int(session.call("peer_count")),
		"max": int(session.call("max_peers")),
		"day": maxi(1, day),
		"realm": realm,
	}


func _tick_listen() -> void:
	if _udp == null:
		return
	while _udp.get_available_packet_count() > 0:
		var raw := _udp.get_packet()
		# The sender's address is taken from the socket, never from the
		# payload. Read before the size check so a malformed packet still
		# advances the socket's own notion of who sent the last one.
		var from := _udp.get_packet_ip()
		if raw.size() <= 0 or raw.size() > MAX_PACKET_BYTES:
			continue
		# A `JSON` instance rather than `JSON.parse_string`: this is a port
		# anyone on the LAN can send anything to, and `parse_string` pushes an
		# engine ERROR for every packet that is not JSON. One stray broadcaster
		# would fill the log with parse errors about somebody else's protocol.
		# `parse()` returns the failure instead of printing it.
		var reader := JSON.new()
		if reader.parse(raw.get_string_from_utf8()) != OK:
			continue
		if typeof(reader.data) != TYPE_DICTIONARY:
			continue
		var advert: Dictionary = reader.data
		if str(advert.get("tag", "")) != GAME_TAG:
			continue
		if int(advert.get("v", 0)) != PROTOCOL_VERSION:
			continue
		var advertised_port := int(advert.get("port", 0))
		if advertised_port <= 0 or advertised_port > 65535 or from.is_empty():
			continue
		var key := "%s|%d" % [from, advertised_port]
		_found[key] = {
			"address": from,
			"port": advertised_port,
			"name": str(advert.get("name", "A Tetherbound world")),
			"players": maxi(0, int(advert.get("players", 0))),
			"max_players": maxi(1, int(advert.get("max", 4))),
			"day": maxi(1, int(advert.get("day", 1))),
			"realm": str(advert.get("realm", "meadows")),
			"seen_ms": Time.get_ticks_msec(),
		}


func _game() -> Node:
	return get_node_or_null(^"/root/Game")


func _session() -> Node:
	var game := _game()
	if game == null:
		return null
	var s: Variant = game.get("session")
	return s as Node
