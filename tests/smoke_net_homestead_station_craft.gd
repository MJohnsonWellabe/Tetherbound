extends "res://tests/smoke_net_crossing_hall_agreement.gd"

# peers: 2
## F31#5 (HOMESTEAD §10, RD-21): buildings are world-owned; a guest uses the
## host's station at the host's tier and keeps what they craft. Real ENet over
## loopback. The host plants a Kitchen and its Spice rack through the paid
## build press; the guest, with no attachment of its own, crafts a Small
## Potion there from ingredients it gathered through the host's ledger (each
## find a journaled reward delivery the host's character record gains once),
## through Session.homestead_submit_action;
## the potion is the guest's, the host's stock is untouched, and the guest's
## craft survives a production leave and returning-character rejoin.
## Disclosed fixtures: tests/helpers/hall_agreement_net_peer.gd (F31#5 block).
const COUNTED := ["potion_small", "berries", "fiber"]


func _run() -> void:
	await process_frame
	require_peer_logs_without(["SCRIPT ERROR", "Parse Error", "Invalid call"], "station craft peer logs have no script errors")
	world_build_allowance_floor_s["production_host"] = 150.0
	world_build_allowance_floor_s["production_join"] = 150.0
	if not await launch(2, "title"):
		quit(await finish())
		return
	_step_phase_deadline_ms = Time.get_ticks_msec() + 600000.0
	var port := int((_peers[0] as Dictionary).get("hello", {}).get("enet_port", 0))
	if not await _craft_step(0, "production_host", {"port": port, "appearance_id": "trainer", "display_name": "CraftHost"}, 9000): return
	if not await _craft_step(1, "production_join", {"host": "127.0.0.1", "port": port,
		"returning_route": false, "character": {"appearance_id": "lyra", "display_name": "CraftGuest"}}, 9000): return
	# The guest's own ingredients, gathered the ordinary co-op way: world finds
	# the smoke stands (disclosed setup), claimed through the host's ledger. A
	# guest's find pays through a journaled reward delivery, so the host's own
	# character record (what station crafts read) must gain exactly the find.
	for find: Array in [["f31_craft_berries", "berries", 4], ["f31_craft_fiber", "fiber", 1]]:
		# Both peers stand the same find, as both run the same world scene: the
		# host takes the item and count from its own copy, never the request.
		if not await _craft_step(0, "pickup_stand", {"id": find[0], "item": find[1], "realm": "meadows", "count": find[2]}): return
		if not await _craft_step(1, "pickup_stand", {"id": find[0], "item": find[1], "realm": "meadows", "count": find[2]}): return
		if not await _craft_step(1, "pickup_take", {}): return
		await step(1, "wait", {"frames": 180})
	var gathered := await _craft_data(1, "craft_count", {"ids": COUNTED})
	var crafter_id := str(gathered.get("character_id", ""))
	var held := await _craft_data(0, "craft_authority_count", {"character_id": crafter_id, "ids": COUNTED})
	if gathered.is_empty() or held.is_empty():
		await _craft_finish()
		return
	check(int(gathered.counts.berries) == 4 and int(gathered.counts.fiber) == 1, "the guest's satchel holds exactly its finds %s" % str(gathered.counts))
	check(held.counts == gathered.counts, "the host's authority record gained exactly the guest's finds %s" % str(held.counts))
	var placed := await _craft_data(0, "craft_place_kitchen", {}, 3000)
	if placed.is_empty():
		await _craft_finish()
		return
	check(int(placed.effective_tier) == 1, "the host's Kitchen stands at tier 1 with its Spice rack")
	var host_before := await _craft_data(0, "craft_count", {"ids": COUNTED})
	var crafted := await _craft_data(1, "craft_at_host_kitchen", {"kitchen_uid": placed.kitchen_uid}, 3000)
	var host_after := await _craft_data(0, "craft_count", {"ids": COUNTED})
	if crafted.is_empty() or host_before.is_empty() or host_after.is_empty():
		await _craft_finish()
		return
	check(host_before.counts == host_after.counts, "the host's own stock is untouched by the guest's craft %s" % str(host_after.counts))
	check(int(crafted.after.potion_small) == int(crafted.before.potion_small) + 1, "the guest keeps the potion it crafted")
	var guest_id := str((await _craft_data(1, "craft_count", {"ids": COUNTED})).get("character_id", ""))
	if not await _craft_step(1, "hall_leave_guest", {}): return
	if not await _craft_step(0, "expect_peers", {"count": 1}): return
	if not await _craft_step(1, "production_join", {"host": "127.0.0.1", "port": port,
		"returning_route": true, "character": {"character_id": guest_id}}, 9000): return
	var back := await _craft_data(1, "craft_count", {"ids": COUNTED})
	if not back.is_empty():
		check(str(back.character_id) == guest_id, "same saved guest character rejoined")
		check(int(back.counts.potion_small) == int(crafted.after.potion_small), "the crafted potion persisted with the guest's portable character")
		check(int(back.counts.berries) == int(crafted.after.berries) and int(back.counts.fiber) == int(crafted.after.fiber),
			"the reconnect re-granted no find %s" % str(back.counts))
		var held_back := await _craft_data(0, "craft_authority_count", {"character_id": guest_id, "ids": COUNTED})
		if not held_back.is_empty():
			check(held_back.counts == back.counts, "the host's authority record matches the guest after the reconnect %s" % str(held_back.counts))
	# F31#2 co-op rule: the guest's relic power choice is the host's to save.
	# Shipping keeps F18's portal runtime off, so the host refuses and nothing
	# changes, before and after the reconnect. The accepted path joins this
	# smoke when F18 turns the runtime on.
	var power := await _craft_data(1, "relic_power_attempt", {"heart_id": "meadows"})
	if not power.is_empty():
		check(not bool(power.runtime_ready) and power.result.get("ok") != true, "with the portal runtime off the host refuses the guest's relic power choice")
		check(str(power.local_active) == "", "a refused choice leaves the guest without a power")
	await _craft_finish()


func _craft_step(peer: int, action: String, args: Dictionary, frames: int = 3000) -> bool:
	var result := await step(peer, action, args, frames)
	var passed := str(result.get("verdict", "")) == "PASS"
	check(passed, "peer %d %s: %s" % [peer, action, str(result.get("detail", ""))])
	if not passed:
		await _craft_finish()
	return passed


func _craft_data(peer: int, action: String, args: Dictionary, frames: int = 1800) -> Dictionary:
	var result := await step(peer, action, args, frames)
	var passed := str(result.get("verdict", "")) == "PASS"
	check(passed, "peer %d %s: %s %s" % [peer, action, str(result.get("detail", "")), JSON.stringify(result.get("data", {}))])
	return result.get("data", {}) if passed else {}


func _craft_finish() -> void:
	print("F31#5 two-peer craft: host plants Kitchen + Spice rack; guest crafts at host tier and keeps output; guest saved rejoin.")
	quit(await finish())
