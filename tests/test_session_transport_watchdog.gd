extends "res://tests/test_case.gd"

## The host drops a hard-killed guest itself once the guest's liveness
## heartbeat has been silent for peer_timeout_max_ms, instead of trusting ENet.
##
## Root cause (smoke_net_f48_cut_key, intermittent; CI run 41956342047): ENet
## re-checks a peer's timeout only when the OLDEST in-flight reliable command's
## retransmit timer expires, and that timer doubles on every resend. Fresh
## pings queue behind it, so a dead guest stayed STATE_CONNECTED past 200 s and
## its registry row never cleared. Measured on loopback at 1/10 scale
## (max 18 s, 1 s pings): ENet alone dropped the dead peer at ~23 s, every run.
##
## Here ENet's own timeouts are set far beyond the test so only the session's
## watchdog (the production helpers) can produce the drop. Real ENet loopback.
const SESSION := preload("res://scripts/net/session.gd")
const CEILING_MS := 600
const TICK_MS := 50

func _pair() -> Dictionary:
	for attempt in 20:
		var port := 42000 + randi() % 8000
		var server := ENetMultiplayerPeer.new()
		if server.create_server(port, 4) != OK: continue
		var client := ENetMultiplayerPeer.new()
		if client.create_client("127.0.0.1", port) != OK:
			server.close()
			continue
		var connected: Array[int] = []
		server.peer_connected.connect(func(id: int) -> void: connected.append(id))
		var started := Time.get_ticks_msec()
		while connected.is_empty() and Time.get_ticks_msec() - started < 3000:
			server.poll()
			client.poll()
			OS.delay_msec(5)
		if connected.is_empty():
			server.close()
			client.close()
			continue
		return {"server": server, "client": client, "id": connected[0]}
	return {}

## Drives the host side the way session._tick_transport_liveness does. When
## `alive` the guest keeps polling and "heartbeats" (records itself heard);
## otherwise it dies after its last reliable traffic. Returns ms to the
## ordinary peer_disconnected, or -1 if none within `limit_ms`.
func _run(alive: bool, limit_ms: int) -> int:
	var pair := _pair()
	if pair.is_empty(): return -2
	var server: ENetMultiplayerPeer = pair.server
	var client: ENetMultiplayerPeer = pair.client
	var id: int = pair.id
	# ENet alone could not drop it inside this test.
	server.get_peer(id).set_timeout(32, 60_000, 60_000)
	var dropped := [false]
	server.peer_disconnected.connect(func(gone: int) -> void: if gone == id: dropped[0] = true)
	var heard := {}
	var started := Time.get_ticks_msec()
	SESSION.silent_transport_peers(heard, [id], true, started, CEILING_MS) # peer_connected
	# The host's last reliable traffic to the guest, as at the cut.
	for burst in 4:
		server.set_target_peer(id)
		server.transfer_mode = MultiplayerPeer.TRANSFER_MODE_RELIABLE
		server.put_packet(PackedByteArray([4, 5, 6]))
	var last_tick := started
	while not dropped[0] and Time.get_ticks_msec() - started < limit_ms:
		var now := Time.get_ticks_msec()
		if alive:
			client.poll()
			while client.get_available_packet_count() > 0: client.get_packet()
		if now - last_tick >= TICK_MS:
			last_tick = now
			if alive: heard[id] = now # its _rpc_transport_alive arrived
			SESSION.ping_transport_peers(server, true, [id])
			for silent: int in SESSION.silent_transport_peers(heard, [id], true, now, CEILING_MS):
				heard.erase(silent)
				assert_true(SESSION.drop_transport_peer(server, silent), "the watchdog ends the silent peer's ENet link")
		server.poll()
		OS.delay_msec(2)
	var elapsed := Time.get_ticks_msec() - started
	server.close()
	client.close()
	return elapsed if dropped[0] else -1

func test_dead_guest_dropped_at_ceiling_through_peer_disconnected() -> void:
	for trial in 3:
		var ms := _run(false, 10 * CEILING_MS)
		assert_true(ms != -2, "loopback ENet pair connected")
		assert_true(ms >= CEILING_MS, "not before the ceiling (trial %d: %d ms)" % [trial, ms])
		assert_true(ms >= 0 and ms <= CEILING_MS + TICK_MS + 150,
			"dead guest: peer_disconnected %d ms after it died, within ceiling %d + tick %d" % [ms, CEILING_MS, TICK_MS])

func test_live_guest_never_dropped() -> void:
	var ms := _run(true, 4 * CEILING_MS)
	assert_true(ms != -2, "loopback ENet pair connected")
	assert_eq(ms, -1, "a guest that keeps heartbeating is kept for four ceilings")

func test_silent_transport_peers_rules() -> void:
	var heard := {}
	assert_eq(SESSION.silent_transport_peers(heard, [1, 7, 9], true, 1000, 500), [], "first sight starts the clock")
	assert_false(heard.has(1), "the host never tracks itself")
	assert_eq(heard, {7: 1000, 9: 1000}, "each physical guest is tracked from first sight")
	heard[9] = 1400
	assert_eq(SESSION.silent_transport_peers(heard, [1, 7, 9], true, 1499, 500), [], "just under the ceiling is kept")
	assert_eq(SESSION.silent_transport_peers(heard, [1, 7, 9], true, 1500, 500), [7], "silent for the ceiling is dropped; a heard peer is kept")
	assert_eq(SESSION.silent_transport_peers(heard, [9], true, 1500, 500), [], "")
	assert_false(heard.has(7), "a peer that is gone from the transport is forgotten")
	assert_eq(SESSION.silent_transport_peers({7: 0}, [7], true, 10_000_000, 0), [], "ceiling 0 disables the watchdog")
	assert_eq(SESSION.silent_transport_peers({}, [5, 6], false, 0, 500), [], "a client watches no relayed ids")
	assert_false(SESSION.drop_transport_peer(OfflineMultiplayerPeer.new(), 2), "nothing to drop on a non-ENet transport")
