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
## Disclosed fixtures: tests/helpers/hall_agreement_net_peer.gd (F31#5 block);
## the guest is a returning saved character that already owns its starter
## (one Terrapup, peer_runner party_grant, saved with save_character_here
## before its first admission, as the F27 net smokes seed theirs), so it
## joins like a real player after the opening: a Home Key holder always
## owns a creature. The same saved character has played the opening: every
## opening:beat:<beat> flag through free_play and every onboarding
## opening:lesson:<id> seen flag are set before its save (seed_opening_complete).
## For the F31#2 relic power case it has also hung the Meadows relic
## (relics_hung plus the host's relic_hang receipt, seeded before its save:
## seed_relic_hung), and with portals on it walks the ordinary capsule path
## to the Meadows Shrine Room pedestal before choosing (relic_pedestal_stand).
const COUNTED := ["potion_small", "berries", "fiber"]


func _run() -> void:
	await process_frame
	require_peer_logs_without(["SCRIPT ERROR", "Parse Error", "Invalid call"], "station craft peer logs have no script errors")
	world_build_allowance_floor_s["production_host"] = 150.0
	world_build_allowance_floor_s["production_join"] = 150.0
	# The guest launches straight into the world (as the F27 net smokes do)
	# so it can seed its saved character before it first joins (header).
	if not await launch(2, "title", [], {1: ["--scene=world"]}):
		quit(await finish())
		return
	_step_phase_deadline_ms = Time.get_ticks_msec() + 600000.0
	var port := int((_peers[0] as Dictionary).get("hello", {}).get("enet_port", 0))
	if not await _craft_step(0, "production_host", {"port": port, "appearance_id": "trainer", "display_name": "CraftHost"}, 9000): return
	# Disclosed fixture (see header): the guest's saved character owns its
	# starter before the host first admits it.
	if not await _craft_step(1, "party_grant", {"species": "terrapup"}): return
	if not await _craft_step(1, "seed_opening_complete", {}): return
	if not await _craft_step(1, "seed_relic_hung", {"biome": "meadows"}): return
	var seeded := await _craft_data(1, "save_character_here", {})
	if seeded.is_empty():
		await _craft_finish()
		return
	if not await _craft_step(1, "production_join", {"host": "127.0.0.1", "port": port,
		"returning_route": true, "character": {"character_id": str(seeded.character_id)}}, 9000): return
	# The guest's own ingredients, gathered the ordinary co-op way through the
	# host's ledger (disclosed setup: the smoke stands the nodes and finds on
	# both peers). Harvests pay through one batched delivery, the fiber find
	# through its own delivery, so the host's own character record (what
	# station crafts read) must gain exactly what the guest gathered.
	# Berries from two harvest nodes: a guest's harvests accrue into one batch
	# and arrive as one delivery after the flush (ruling (b)).
	for node_id: String in ["f31_berry_a", "f31_berry_b"]:
		if not await _craft_step(0, "gather_node_stand", {"id": node_id, "item": "berries", "amount": 2}): return
		if not await _craft_step(1, "gather_node_stand", {"id": node_id, "item": "berries", "amount": 2}): return
		if not await _craft_step(1, "gather_node_take", {"id": node_id}): return
	await step(1, "wait", {"frames": 240})
	for find: Array in [["f31_craft_fiber", "fiber", 1]]:
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
	# F18 travel reset (coordinator): one guest Home Key trip home and its
	# arrival before the owner-gated craft. Skipped, with its reason, while the
	# portal runtime is off.
	var trip := await _craft_data(1, "craft_home_key_trip", {}, 12000)
	if bool(trip.get("skipped", false)):
		print("F31#5 craft: guest Home Key trip skipped (portal runtime off in this build)")
	else:
		check(str(trip.get("realm", "")) == "meadows", "the guest arrived home before crafting")
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
		var batched := await _craft_data(0, "gather_rows", {"character_id": guest_id})
		if not batched.is_empty():
			check(int(batched.batch.next_seq) >= 2 and (batched.batch.open as Dictionary).is_empty(),
				"the guest's harvests flushed as a batch %s" % str(batched.batch))
			check(int(batched.rows) == 0, "acked and replayed batch rows were pruned from the host world (%d left)" % int(batched.rows))
	# F31#2 co-op rule: the guest's relic power choice is the host's to save.
	# Read from the shipped portal flag: off, the host refuses with its reason
	# and nothing changes; on, it is accepted exactly once (a second identical
	# choice changes nothing more).
	if not await _craft_step(1, "relic_pedestal_stand", {"biome": "meadows"}, 9000): return
	var power := await _craft_data(1, "relic_power_attempt", {"heart_id": "meadows"})
	if not power.is_empty():
		if not bool(power.runtime_ready):
			check(power.result.get("ok") != true and not str(power.result.get("code", power.result.get("reason", ""))).is_empty(),
				"portal runtime off: the host refuses the guest's relic power choice with a reason %s" % str(power.result))
			check(str(power.local_active) == "", "a refused choice leaves the guest without a power")
		else:
			check(power.result.get("ok") == true and str(power.local_active) == "meadows",
				"portal runtime on: the host accepts the guest's relic power choice %s" % str(power.result))
			var again := await _craft_data(1, "relic_power_attempt", {"heart_id": "meadows"})
			if not again.is_empty():
				check(str(again.local_active) == "meadows" and again.result.get("receipt", "") in ["", power.result.get("receipt", "")],
					"accepted exactly once: the same choice again adds no second change %s" % str(again.result))
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
