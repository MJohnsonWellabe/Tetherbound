extends SceneTree

## Scratch probe (lane 2.B): does the LAN beacon's LISTEN half actually read a
## packet, key it on the sender's socket address, and age it out? Not committed.

const BEACON := preload("res://scripts/mp/lan_beacon.gd")

var checks := 0
var fails := 0

func _ok(c: bool, m: String) -> void:
	checks += 1
	if not c:
		fails += 1
	print(("PASS: " if c else "FAIL: ") + m)

func _initialize() -> void:
	_run()

func _run() -> void:
	var port := BEACON.beacon_port_for(27015)
	_ok(port == 27016, "beacon port derives from the session port (%d)" % port)

	var listener := BEACON.new()
	root.add_child(listener)
	_ok(bool(listener.call("listen", 27015)), "listen() bound udp/%d (%s)" % [port, str(listener.call("listen_error"))])
	_ok(str(listener.call("mode")) == "listen", "listener mode is 'listen'")
	_ok((listener.call("games") as Array).is_empty(), "no games before any packet")

	var sender := PacketPeerUDP.new()
	_ok(sender.set_dest_address("127.0.0.1", port) == OK, "scratch sender aimed at the beacon port")

	# A well-formed advert, then three that must all be ignored.
	var good := {"tag": "tetherbound-lan", "v": 1, "name": "Ada's world", "port": 27015,
		"players": 2, "max": 4, "day": 3, "realm": "meadows"}
	sender.put_packet(JSON.stringify(good).to_utf8_buffer())
	sender.put_packet(JSON.stringify({"tag": "somebody-else", "v": 1, "port": 27015}).to_utf8_buffer())
	sender.put_packet(JSON.stringify({"tag": "tetherbound-lan", "v": 99, "port": 27015}).to_utf8_buffer())
	sender.put_packet("not json at all".to_utf8_buffer())
	for i in 20:
		await process_frame

	var games: Array = listener.call("games")
	_ok(games.size() == 1, "exactly one advert survived the four packets (%d)" % games.size())
	if games.size() == 1:
		var g: Dictionary = games[0]
		_ok(str(g.get("address", "")) == "127.0.0.1",
			"the address comes from the SOCKET, not the payload (%s)" % str(g.get("address", "")))
		_ok(int(g.get("port", 0)) == 27015, "the advertised game port survived (%d)" % int(g.get("port", 0)))
		_ok(str(g.get("name", "")) == "Ada's world", "the host's name survived")
		_ok(int(g.get("players", 0)) == 2 and int(g.get("max_players", 0)) == 4, "players 2/4")
		_ok(int(g.get("day", 0)) == 3, "day 3")
	_ok(str(listener.call("fingerprint")) == "127.0.0.1:27015/Ada's world/2",
		"fingerprint names the row (%s)" % str(listener.call("fingerprint")))

	# TTL: nothing new arrives, so after ENTRY_TTL_S the list empties itself.
	var deadline := Time.get_ticks_msec() + int(BEACON.ENTRY_TTL_S * 1000.0) + 500
	while Time.get_ticks_msec() < deadline:
		await process_frame
	_ok((listener.call("games") as Array).is_empty(), "the entry aged out after %.0f s" % BEACON.ENTRY_TTL_S)
	_ok(str(listener.call("fingerprint")) == "", "and the fingerprint went empty with it")

	listener.call("stop")
	_ok(str(listener.call("mode")) == "", "stop() puts the beacon back to idle")

	# A second listener on the SAME port must fail with a sentence, not silence.
	var first := BEACON.new()
	root.add_child(first)
	first.call("listen", 27015)
	var second := BEACON.new()
	root.add_child(second)
	var second_ok := bool(second.call("listen", 27015))
	_ok(not second_ok, "a second listener on one machine is refused")
	_ok(not str(second.call("listen_error")).is_empty(),
		"and says why: %s" % str(second.call("listen_error")))

	print("assertions run: %d, failed: %d" % [checks, fails])
	quit(1 if fails > 0 else 0)
