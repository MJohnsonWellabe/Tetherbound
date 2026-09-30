extends "res://tests/helpers/net_harness.gd"

# peers: 2

## F16#3: real isolated ENet peers, production split saves and title rejoin.
## Every carrier field is a disclosed nondefault storage fixture. Future
## portal/training/crafting verbs are not earned or claimed by this witness.
const STATE := preload("res://scripts/data/redesign_state.gd")

func _initialize() -> void:
	_run()

func _run() -> void:
	heartbeat_silence_tolerance_s = 150.0
	if not await launch(2, "world"):
		quit(await finish())
		return
	var host_hello: Dictionary = (_peers[0] as Dictionary).get("hello", {})
	var guest_hello: Dictionary = (_peers[1] as Dictionary).get("hello", {})
	check(host_hello.get("user_data_dir", "") != guest_hello.get("user_data_dir", ""), "two distinct isolated peer homes")
	var port := int(host_hello.get("enet_port", 0))
	if not await _pass(0, "host", {"port": port}): return
	if not await _pass(0, "foundations_state", {"mode": "seed", "marker": 1}): return
	if not await _pass(0, "foundations_state", {"mode": "roundtrip"}): return
	var host := await _carrier(0)
	check(_populated(host), "host populated all 8 world / 14 personal / 9 per-creature fields")
	if not await _pass(1, "join", {"host": "127.0.0.1", "port": port}): return
	for peer in 2:
		if not await _pass(peer, "expect_peers", {"count": 2}): return
	if not await _pass(1, "foundations_state", {"mode": "seed", "marker": 2}): return
	if not await _pass(1, "foundations_state", {"mode": "roundtrip"}): return
	var guest := await _carrier(1)
	check(_populated(guest), "guest populated every personal and per-creature field")
	check(guest.get("world", {}) == host.get("world", {}), "host snapshot carries all 8 world fields")
	check(guest.get("character", {}) != host.get("character", {}), "personal fixture payloads are distinct")
	var guest_id := str(guest.get("character_id", ""))
	check(not guest_id.is_empty() and guest_id != str(host.get("character_id", "")), "stable host and guest identities differ")
	check(int(host.get("schema", 0)) == 28 and int(guest.get("schema", 0)) == 28, "current schema 28 on both peers")
	check(not str(host.get("world_disk_sha256", "")).is_empty() and not str(guest.get("character_disk_sha256", "")).is_empty(), "production durable files exist")
	if not await _pass(1, "foundations_state", {"mode": "forge_world"}): return
	var host_after_forgery := await _carrier(0)
	check(host_after_forgery.get("world", {}) == host.get("world", {}), "guest forged world never mutates host live state")
	check(host_after_forgery.get("world_disk_sha256", "") == host.get("world_disk_sha256", ""), "guest world-save refusal preserves host disk bytes")
	if not await _pass(1, "leave", {}): return
	if not await _pass(1, "wipe_character", {}): return
	if not await _pass(1, "foundations_state", {"mode": "clear_world"}): return
	var wiped := await _carrier(1)
	check(wiped.get("character", {}) == STATE.defaults("character"), "all personal memory erased before rejoin")
	check(wiped.get("world", {}) == STATE.defaults("world"), "guest world projection erased before rejoin")
	if not await _pass(1, "production_join", {"host": "127.0.0.1", "port": port,
			"returning_route": true, "character": {"character_id": guest_id}}, 6000): return
	for peer in 2:
		if not await _pass(peer, "expect_peers", {"count": 2}): return
	var restored := await _carrier(1)
	var retained := await _carrier(0)
	check(restored.get("character_id", "") == guest_id, "actual title rejoin keeps named portable identity")
	check(restored.get("character", {}) == guest.get("character", {}), "named-ID disk rejoin restores full personal and per-creature payload")
	check(restored.get("world", {}) == host.get("world", {}), "rejoin restores host-authoritative full world payload")
	check(retained.get("character", {}) == host.get("character", {}), "host personal carrier remains its own")
	print("F16 full populated two-peer storage witness; fixtures, direct title join callback, production saves/reload/ENet disclosed")
	quit(await finish())

func _pass(peer: int, action: String, args: Dictionary, frames: int = 3000) -> bool:
	var result := await step(peer, action, args, frames)
	var passed := str(result.get("verdict", "")) == "PASS"
	check(passed, "peer %d %s %s: %s" % [peer, action, str(args.get("mode", "")), str(result.get("detail", ""))])
	if not passed: quit(await finish())
	return passed

func _carrier(peer: int) -> Dictionary:
	var result := await step(peer, "foundations_state", {"mode": "inspect"})
	check(str(result.get("verdict", "")) == "PASS", "peer %d full-carrier inspection succeeds" % peer)
	return result.get("data", {}) as Dictionary

func _populated(payload: Dictionary) -> bool:
	var world: Dictionary = payload.get("world", {})
	var personal: Dictionary = payload.get("character", {})
	if world.size() != 8 or personal.size() != 14: return false
	for key: String in world:
		if world[key] == STATE.defaults("world")[key]: return false
	for key: String in personal:
		if personal[key] == STATE.defaults("character")[key]: return false
	var creatures: Dictionary = personal.get("creatures", {})
	if creatures.size() != 1: return false
	return (creatures.values()[0] as Dictionary).size() == 9
