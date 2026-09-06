extends SceneTree

## Latency/jitter/loss injector for the net harness. Stage B Wave 0 lane 0.F.
## docs/specs/MP_NET_HARNESS_CONTRACT.md §9.
##
##   godot --headless --path . --script tools/net/udp_proxy.gd -- \
##       --listen-port=27950 --target-host=127.0.0.1 --target-port=27801 \
##       --delay-ms=150 --jitter-ms=30 --loss-pct=1
##
## A bare UDP relay between `--listen-port` (what a client joins instead of
## the host's real ENet port) and `--target-host:--target-port` (the host's
## real ENet port). Every packet either direction is queued for
## `delay-ms +/- jitter-ms` and dropped with probability `loss-pct` before
## being forwarded, so a latency-sensitive regression (contract §9: "not a
## substitute for the owner's real LAN run; a way to make it reproducible in a
## container") is a smoke a container can run.
##
## ## Scope note (contract §12 item 6, "may slip")
##
## This is the one piece of the 0.F delivery list allowed to slip to Wave 7,
## and it very nearly did -- see the lane report. What is verified here is the
## proxy's own forwarding/delay/jitter/loss behaviour against a synthetic
## sender/receiver pair (this file's own `--role=selftest`); it has NOT been
## run against a live two-peer ENet handshake, because Wave 0 has no `Session`
## to host/join through it yet (contract §1) -- 7.A
## (`smoke_net_shared_wild_fight`/`smoke_net_catch_race` at
## `delay 150 / jitter 30 / loss 1`) is where that integration actually
## happens, once there is a real join to route through this proxy's listen
## port. Wiring THIS proxy into a `net_conditions`-bearing coordinator step is
## therefore also left to whichever wave adds `net_conditions` to
## `tests/helpers/net_harness.gd`.
##
## Not per-client-authenticated or NAT-punching -- it exists to run on
## 127.0.0.1 in a CI container, not to be a general-purpose relay.

var _log := "udp_proxy"


func _initialize() -> void:
	var args := _parse_args()
	if str(args.get("role", "")) == "selftest":
		await _selftest()
		return

	var listen_port := int(args.get("listen-port", 0))
	var target_host := str(args.get("target-host", "127.0.0.1"))
	var target_port := int(args.get("target-port", 0))
	if listen_port <= 0 or target_port <= 0:
		push_error("%s: --listen-port and --target-port are required" % _log)
		quit(2)
		return

	var proxy := UdpDelayProxy.new(listen_port, target_host, target_port,
		float(args.get("delay-ms", 0.0)), float(args.get("jitter-ms", 0.0)),
		float(args.get("loss-pct", 0.0)))
	if not proxy.start():
		push_error("%s: could not bind listen port %d" % [_log, listen_port])
		quit(2)
		return
	print("%s: relaying 127.0.0.1:%d -> %s:%d (delay=%.0fms jitter=%.0fms loss=%.1f%%)" %
		[_log, listen_port, target_host, target_port,
		float(args.get("delay-ms", 0.0)), float(args.get("jitter-ms", 0.0)), float(args.get("loss-pct", 0.0))])

	while true:
		await process_frame
		proxy.pump()


func _parse_args() -> Dictionary:
	var out := {}
	for raw in OS.get_cmdline_user_args():
		var s: String = raw
		if s.begins_with("--"):
			s = s.substr(2)
		var eq := s.find("=")
		if eq >= 0:
			out[s.substr(0, eq)] = s.substr(eq + 1)
		else:
			out[s] = true
	return out


## `--role=selftest`: proves the relay's own forward/delay/jitter/loss
## behaviour with two plain `PacketPeerUDP`s standing in for "client" and
## "target" -- no ENet, no Session, nothing this file cannot verify on its
## own. Exits 0 when a burst of packets sent through the proxy arrives at the
## target, each delayed within the configured window, at roughly the
## configured loss rate; 1 otherwise.
func _selftest() -> void:
	const N := 200
	const DELAY_MS := 40.0
	const JITTER_MS := 10.0
	const LOSS_PCT := 20.0

	var target := PacketPeerUDP.new()
	if target.bind(0) != OK:
		push_error("%s selftest: could not bind target socket" % _log)
		quit(2)
		return
	var target_port := target.get_local_port()

	var proxy := UdpDelayProxy.new(0, "127.0.0.1", target_port, DELAY_MS, JITTER_MS, LOSS_PCT)
	if not proxy.start():
		push_error("%s selftest: could not bind proxy listen socket" % _log)
		quit(2)
		return
	var listen_port := proxy.listen_port()

	var client := PacketPeerUDP.new()
	client.bind(0)
	client.set_dest_address("127.0.0.1", listen_port)

	# Sending and receiving are INTERLEAVED in one loop, not two phases.
	# `headless` still paces `process_frame` to real wall-clock frame time, so
	# a separate "send all 200, then read" pair of loops takes long enough
	# (measured: ~3.3s to send 200 at one per frame) that early packets sit in
	# the target socket's OS receive buffer for the whole rest of the send
	# phase -- not because the proxy delayed them, but because nothing drained
	# the target socket while sending was still going. Measured before this
	# fix: rtt spread from 41 ms to 1814 ms for a proxy configured to delay 40
	# ms +/- 10. Draining every frame is what actually measures the proxy's
	# delay rather than this test's own loop shape.
	var sent_at := {}
	var received := {}
	var next_to_send := 0
	var deadline := Time.get_ticks_msec() + int(DELAY_MS + JITTER_MS) * 4 + 5000
	while (next_to_send < N or received.size() < N) and Time.get_ticks_msec() < deadline:
		if next_to_send < N:
			sent_at[next_to_send] = Time.get_ticks_msec()
			client.put_packet(str(next_to_send).to_utf8_buffer())
			next_to_send += 1
		await process_frame
		proxy.pump()
		while target.get_available_packet_count() > 0:
			var pkt := target.get_packet()
			var seq := int(pkt.get_string_from_utf8())
			var rtt := Time.get_ticks_msec() - int(sent_at.get(seq, Time.get_ticks_msec()))
			received[seq] = rtt

	var loss_rate := 100.0 * float(N - received.size()) / float(N)
	var bad_delay := 0
	var rtts_dbg: Array = received.values()
	rtts_dbg.sort()
	print("%s selftest debug: rtt samples min=%s p50=%s max=%s" % [_log,
		str(rtts_dbg[0]) if rtts_dbg.size() > 0 else "-",
		str(rtts_dbg[rtts_dbg.size() / 2]) if rtts_dbg.size() > 0 else "-",
		str(rtts_dbg[-1]) if rtts_dbg.size() > 0 else "-"])
	for rtt in received.values():
		# One-way delay only (this is client->target, no reply leg), so the
		# window is DELAY_MS +/- JITTER_MS plus generous frame-scheduling
		# slack -- this measures the proxy's own queue, not a real network.
		if float(rtt) < DELAY_MS - JITTER_MS - 5.0 or float(rtt) > DELAY_MS + JITTER_MS + 200.0:
			bad_delay += 1

	print("%s selftest: sent=%d received=%d loss_rate=%.1f%% (configured %.1f%%) bad_delay_samples=%d" %
		[_log, N, received.size(), loss_rate, LOSS_PCT, bad_delay])

	# Loose bounds: loss is a Bernoulli draw over N=200, and this is proving
	# the mechanism works, not pinning an exact statistic. +/-15 points around
	# the configured rate is generous enough to not flake and tight enough to
	# catch "loss does nothing" (0%) or "loss drops everything" (100%). A
	# shared CI runner can stall a single frame long enough to blow one
	# packet's window without the mechanism being wrong, so up to 2% of the
	# received samples (at least one) may miss the window before this fails.
	var bad_delay_ceiling := maxi(1, int(received.size() / 50))
	var ok := absf(loss_rate - LOSS_PCT) <= 15.0 and bad_delay <= bad_delay_ceiling and received.size() > 0
	quit(0 if ok else 1)


## The relay itself: two bound `PacketPeerUDP`s (one per direction's local
## endpoint) and a delay queue. Split out from the SceneTree script so
## `--role=selftest` and the real CLI path share one implementation exactly.
class UdpDelayProxy:
	var _listen: PacketPeerUDP
	var _target_host: String
	var _target_port: int
	var _delay_ms: float
	var _jitter_ms: float
	var _loss_pct: float
	## client_key ("ip:port") -> PacketPeerUDP bound to its own ephemeral
	## local port and pointed at the target -- so the target (a real ENet
	## server) sees each client at a distinct, stable source port, the same
	## as it would without the proxy in between.
	var _upstream: Dictionary = {}
	## client_key -> {ip, port}, so an upstream reply can be relayed back to
	## the right client.
	var _client_addr: Dictionary = {}
	## Every queued packet: {at_ms, bytes, to_upstream: bool, client_key}.
	var _queue: Array = []
	## `PacketPeerUDP` has no `is_bound()`/`poll()` (unlike `StreamPeerTCP`) --
	## it is connectionless, and `get_local_port()` on an unbound socket logs
	## an engine error rather than returning 0. Tracked here instead of probed.
	var _bound := false

	func _init(listen_port: int, target_host: String, target_port: int,
			delay_ms: float, jitter_ms: float, loss_pct: float) -> void:
		_listen = PacketPeerUDP.new()
		if listen_port > 0:
			_bound = _listen.bind(listen_port) == OK
		_target_host = target_host
		_target_port = target_port
		_delay_ms = delay_ms
		_jitter_ms = jitter_ms
		_loss_pct = loss_pct

	func start() -> bool:
		if _bound:
			return true
		_bound = _listen.bind(0) == OK
		return _bound

	func listen_port() -> int:
		return _listen.get_local_port() if _bound else 0

	func _maybe_queue(bytes: PackedByteArray, to_upstream: bool, client_key: String) -> void:
		if _loss_pct > 0.0 and randf() * 100.0 < _loss_pct:
			return
		var jitter := 0.0 if _jitter_ms <= 0.0 else randf_range(-_jitter_ms, _jitter_ms)
		var at := Time.get_ticks_msec() + int(maxf(0.0, _delay_ms + jitter))
		_queue.append({"at_ms": at, "bytes": bytes, "to_upstream": to_upstream, "client_key": client_key})

	func pump() -> void:
		# client -> proxy -> (queued) -> target
		while _listen.get_available_packet_count() > 0:
			var pkt := _listen.get_packet()
			var ip := _listen.get_packet_ip()
			var port := _listen.get_packet_port()
			var key := "%s:%d" % [ip, port]
			if not _upstream.has(key):
				var up := PacketPeerUDP.new()
				up.bind(0)
				up.set_dest_address(_target_host, _target_port)
				_upstream[key] = up
				_client_addr[key] = {"ip": ip, "port": port}
			_maybe_queue(pkt, true, key)

		# target -> proxy -> (queued) -> client
		for key in _upstream.keys():
			var up: PacketPeerUDP = _upstream[key]
			while up.get_available_packet_count() > 0:
				_maybe_queue(up.get_packet(), false, key)

		# deliver anything whose delay has elapsed
		var now := Time.get_ticks_msec()
		var remaining: Array = []
		for entry in _queue:
			var d: Dictionary = entry
			if now < int(d["at_ms"]):
				remaining.append(d)
				continue
			var key2: String = d["client_key"]
			if bool(d["to_upstream"]):
				if _upstream.has(key2):
					(_upstream[key2] as PacketPeerUDP).put_packet(d["bytes"])
			else:
				if _client_addr.has(key2):
					var addr: Dictionary = _client_addr[key2]
					_listen.set_dest_address(str(addr["ip"]), int(addr["port"]))
					_listen.put_packet(d["bytes"])
		_queue = remaining
