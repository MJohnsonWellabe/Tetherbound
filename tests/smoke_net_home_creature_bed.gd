extends "res://tests/smoke_net_crossing_hall_agreement.gd"

# peers: 2
## Home creature bed, two peers (owner ruling 2026-10-04; coordinator co-op
## rule: occupancy and heal authority need a two-peer case). Real ENet over
## loopback. Host and guest each rest their OWN portable party creature in the
## same world bed: the guest's rest is not refused by the host's resting
## creature and does not evict it, both heal to full through Game's own
## bed-recovery tick, and the guest's healed creature survives a production
## leave (portable save) and returning-character rejoin. Disclosed fixtures
## are listed in tests/helpers/hall_agreement_net_peer.gd::_home_bed_rest.


func _run() -> void:
	await process_frame
	require_peer_logs_without(["SCRIPT ERROR", "Parse Error", "Invalid call"], "home bed peer logs have no script errors")
	world_build_allowance_floor_s["production_host"] = 150.0
	world_build_allowance_floor_s["production_join"] = 150.0
	if not await launch(2, "title"):
		quit(await finish())
		return
	_step_phase_deadline_ms = Time.get_ticks_msec() + 600000.0
	var port := int((_peers[0] as Dictionary).get("hello", {}).get("enet_port", 0))
	if not await _bed_step(0, "production_host", {"port": port, "appearance_id": "trainer", "display_name": "BedHost"}, 9000): return
	if not await _bed_step(1, "production_join", {"host": "127.0.0.1", "port": port,
		"returning_route": false, "character": {"appearance_id": "lyra", "display_name": "BedGuest"}}, 9000): return
	var host := await _bed_data(0, "home_bed_rest")
	var guest := await _bed_data(1, "home_bed_rest")
	if host.is_empty() or guest.is_empty():
		await _bed_finish()
		return
	check(host.character_id != guest.character_id, "two separate admitted characters")
	check(bool(host.hosting) and not bool(guest.hosting), "actual host/client roles")
	check(int(host.bed_index) == int(guest.bed_index), "both peers rest in the same world bed (index %d)" % int(host.bed_index))
	check(not bool(guest.occupied_by_own_party_before), "the host's resting creature does not block the guest's rest")
	var host_after := await _bed_data(0, "home_bed_status")
	if not host_after.is_empty():
		check(bool(host_after.resting) and int(host_after.rest_bed_index) == int(host.bed_index), "the guest's rest did not evict the host's creature")
		check(is_equal_approx(float(host_after.hp), float(host_after.max_hp)), "host creature stays healed")
	var guest_id := str(guest.character_id)
	if not await _bed_step(1, "hall_leave_guest", {}): return
	if not await _bed_step(0, "expect_peers", {"count": 1}): return
	if not await _bed_step(1, "production_join", {"host": "127.0.0.1", "port": port,
		"returning_route": true, "character": {"character_id": guest_id}}, 9000): return
	var back := await _bed_data(1, "home_bed_status")
	if not back.is_empty():
		check(str(back.character_id) == guest_id, "same saved guest character rejoined")
		check(is_equal_approx(float(back.hp), float(back.max_hp)), "guest's home-bed heal persisted through leave and rejoin (hp %.1f / %.1f)" % [float(back.hp), float(back.max_hp)])
	await _bed_finish()


func _bed_step(peer: int, action: String, args: Dictionary, frames: int = 3000) -> bool:
	var result := await step(peer, action, args, frames)
	var passed := str(result.get("verdict", "")) == "PASS"
	check(passed, "peer %d %s: %s" % [peer, action, str(result.get("detail", ""))])
	if not passed:
		await _bed_finish()
	return passed


func _bed_data(peer: int, action: String) -> Dictionary:
	var result := await step(peer, action, {}, 1800)
	var passed := str(result.get("verdict", "")) == "PASS"
	check(passed, "peer %d %s: %s %s" % [peer, action, str(result.get("detail", "")), JSON.stringify(result.get("data", {}))])
	return result.get("data", {}) if passed else {}


func _bed_finish() -> void:
	print("Home creature bed two-peer case: real ENet join, per-character rest and heal, guest saved rejoin.")
	quit(await finish())
