extends "res://tests/test_case.gd"

## A dead peer (killed process: no ENet disconnect) is dropped within the
## configured peer_timeout_max_ms when the session pings its physical peers.
## Real ENet over loopback; the session's helper is the production code path.
## ENet re-checks a timeout only when a reliable command's retransmit timer
## expires, and those timers double without bound, so without the ping the
## drop can land well past the maximum (smoke_net_f48_cut_key, intermittent).
const SESSION := preload("res://scripts/net/session.gd")
# Same min:max ratio as data/config/multiplayer.json (135 s : 180 s).
const MIN_MS := 300
const MAX_MS := 400
const PING_EVERY_MS := 50
var _last_rto := 0

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

## Returns ms from the dead peer's last send to its drop, or -1 past `limit_ms`.
func _drop_ms(ping: bool, limit_ms: int) -> int:
	var pair := _pair()
	if pair.is_empty(): return -2
	var server: ENetMultiplayerPeer = pair.server
	var client: ENetMultiplayerPeer = pair.client
	var id: int = pair.id
	var dropped := [false]
	server.peer_disconnected.connect(func(gone: int) -> void: if gone == id: dropped[0] = true)
	server.get_peer(id).set_timeout(32, MIN_MS, MAX_MS)
	# Warm the round-trip estimate the way a live session does.
	var warm := Time.get_ticks_msec()
	while Time.get_ticks_msec() - warm < 400:
		server.set_target_peer(id)
		server.transfer_mode = MultiplayerPeer.TRANSFER_MODE_RELIABLE
		server.put_packet(PackedByteArray([1, 2, 3]))
		server.poll()
		client.poll()
		while client.get_available_packet_count() > 0: client.get_packet()
		OS.delay_msec(10)
	var stats := server.get_peer(id)
	var rto := int(stats.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME) + 4 * stats.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME_VARIANCE))
	# The guest process dies: it is never serviced again (no ACK, no
	# disconnect). The host's last traffic to it goes out, then the host idles,
	# as it does while it waits for a cut guest.
	for burst in 4:
		server.set_target_peer(id)
		server.transfer_mode = MultiplayerPeer.TRANSFER_MODE_RELIABLE
		server.put_packet(PackedByteArray([4, 5, 6]))
	server.poll()
	var started := Time.get_ticks_msec()
	var last_ping := started
	while not dropped[0] and Time.get_ticks_msec() - started < limit_ms:
		if ping and Time.get_ticks_msec() - last_ping >= PING_EVERY_MS:
			assert_eq(SESSION.ping_transport_peers(server, true, [id]), 1, "the session pings the one physical peer")
			last_ping = Time.get_ticks_msec()
		server.poll()
		OS.delay_msec(2)
	_last_rto = rto
	var elapsed := Time.get_ticks_msec() - started
	server.close()
	client.close()
	return elapsed if dropped[0] else -1

func test_dead_peer_dropped_within_max_when_pinged() -> void:
	for trial in 3:
		var ms := _drop_ms(true, 8 * MAX_MS)
		assert_true(ms != -2, "loopback ENet pair connected")
		assert_true(ms >= 0, "the dead peer was dropped at all (trial %d)" % trial)
		# Bound: the maximum, plus one ping's own retransmit timer, plus the
		# ping interval (and a little loop/poll slack).
		var bound := MAX_MS + _last_rto + PING_EVERY_MS + 60
		assert_true(ms <= bound,
			"pinged: dropped %d ms after it died, within %d ms (maximum %d + rto %d + ping %d)" % [ms, bound, MAX_MS, _last_rto, PING_EVERY_MS])

func test_unpinged_drop_for_reference() -> void:
	# Not asserted against the maximum: without the ping the drop time depends
	# on where the doubling retransmit timers land (the bug). Recorded so a run
	# shows the contrast.
	for trial in 3:
		var ms := _drop_ms(false, 16 * MAX_MS)
		print("TRANSPORT LIVENESS reference without ping: %s (maximum %d ms, rto %d ms)" % ["not dropped in %d ms" % (16 * MAX_MS) if ms == -1 else "%d ms" % ms, MAX_MS, _last_rto])
		assert_true(ms != -2, "loopback ENet pair connected")

func test_ping_skips_non_enet_and_relayed_ids() -> void:
	assert_eq(SESSION.ping_transport_peers(OfflineMultiplayerPeer.new(), true, [2, 3]), 0, "offline peer: nothing to ping")
	var pair := _pair()
	if pair.is_empty():
		assert_true(false, "loopback ENet pair connected")
		return
	var server: ENetMultiplayerPeer = pair.server
	assert_eq(SESSION.ping_transport_peers(server, true, [1, pair.id]), 1, "the host never pings itself, only the physical guest")
	(pair.client as ENetMultiplayerPeer).close()
	server.close()
