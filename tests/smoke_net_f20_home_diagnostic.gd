extends "res://tests/smoke_net_f20_ending.gd"

# peers: 2
# requires-flag: multiplayer.json session.redesign_portal_runtime_enabled
## Affected guest-arrival diagnostic only. This cannot close F20#4: it does
## not exercise either ending, credits or disconnect/reload acceptance path.
func _run() -> void:
	await process_frame
	heartbeat_silence_tolerance_s = 150.0
	require_peer_logs_without(["ERROR:", "SCRIPT ERROR:"], "F20 guest arrival diagnostic peer logs have no engine/script errors")
	print("F20 GUEST HOME DIAGNOSTIC: disclosed post-finale fixtures; two real peers; guest Home Key only; not F20#4 acceptance")
	if not await launch(2, "world", [], {1: ["--joiner"]}): quit(await finish()); return
	var port := int(_peers[0].hello.enet_port)
	if not await _pass(0, "host", {"port": port}): return
	if not await _pass(1, "join", {"host": "127.0.0.1", "port": port}): return
	for peer in 2:
		if not await _pass(peer, "expect_peers", {"count": 2}): return
	if not await _pass(1, "f20_return"): return
	quit(await finish())
