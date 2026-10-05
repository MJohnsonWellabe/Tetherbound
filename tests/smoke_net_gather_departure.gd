extends "res://tests/smoke_net_crossing_hall_agreement.gd"

# peers: 2
## Review G1 (review-gather-batching-r2.md): a guest's gather batch row is
## pruned once the host's owner-passive replay credits it (and the guest's ACK
## landed), not once an owner checkpoint is saved. Does a guest that departs
## immediately after the prune, then rejoins, get its owner-passive stream
## refused (a re-sent reward_delivery_applied for a pruned row ends
## unproved_delivery_input)? Real ENet over loopback:
## - host plants a Kitchen + Spice rack; both peers stand two berry nodes;
## - the guest harvests both (batched), the host polls until the batch rows are
##   pruned, and the guest leaves at once (production leave) and rejoins;
## - the rejoined guest claims a fiber find and crafts a Small Potion at the
##   host's Kitchen: a refused or dead owner stream would refuse the craft;
## - the host's authority record equals the guest's satchel, nothing doubled.
## Disclosed fixtures: tests/helpers/hall_agreement_net_peer.gd (F31#5 block).
const COUNTED := ["potion_small", "berries", "fiber"]


func _run() -> void:
	await process_frame
	require_peer_logs_without(["SCRIPT ERROR", "Parse Error", "Invalid call", "unproved_delivery_input", "owner_passive_admission_conflict"],
		"departure peer logs have no script errors and no owner-passive refusal")
	world_build_allowance_floor_s["production_host"] = 150.0
	world_build_allowance_floor_s["production_join"] = 150.0
	if not await launch(2, "title"):
		quit(await finish())
		return
	_step_phase_deadline_ms = Time.get_ticks_msec() + 600000.0
	var port := int((_peers[0] as Dictionary).get("hello", {}).get("enet_port", 0))
	if not await _dep_step(0, "production_host", {"port": port, "appearance_id": "trainer", "display_name": "GatherHost"}, 9000): return
	if not await _dep_step(1, "production_join", {"host": "127.0.0.1", "port": port,
		"returning_route": false, "character": {"appearance_id": "lyra", "display_name": "GatherGuest"}}, 9000): return
	var placed := await _dep_data(0, "craft_place_kitchen", {}, 3000)
	if placed.is_empty():
		await _dep_finish()
		return
	for node_id: String in ["g1_berry_a", "g1_berry_b"]:
		if not await _dep_step(0, "gather_node_stand", {"id": node_id, "item": "berries", "amount": 2}): return
		if not await _dep_step(1, "gather_node_stand", {"id": node_id, "item": "berries", "amount": 2}): return
		if not await _dep_step(1, "gather_node_take", {"id": node_id}): return
	var guest_id := str((await _dep_data(1, "craft_count", {"ids": COUNTED})).get("character_id", ""))
	# Poll the host until every flushed batch row is accepted, replayed and
	# pruned: the G1 window opens exactly here.
	var pruned := false
	for i in 40:
		var rows := await _dep_data(0, "gather_rows", {"character_id": guest_id}, 600)
		if not rows.is_empty() and int(rows.batch.next_seq) >= 2 and (rows.batch.open as Dictionary).is_empty() \
				and int(rows.rows) == 0 and (rows.batch.replayed as Array).is_empty():
			pruned = true
			break
		await step(1, "wait", {"frames": 30})
	check(pruned, "the guest's harvest batches flushed, were credited and pruned on the host")
	if not pruned:
		await _dep_finish()
		return
	# Depart at once, inside the window, then rejoin as the same character.
	if not await _dep_step(1, "hall_leave_guest", {}): return
	if not await _dep_step(0, "expect_peers", {"count": 1}): return
	if not await _dep_step(1, "production_join", {"host": "127.0.0.1", "port": port,
		"returning_route": true, "character": {"character_id": guest_id}}, 9000): return
	var back := await _dep_data(1, "craft_count", {"ids": COUNTED})
	var held := await _dep_data(0, "craft_authority_count", {"character_id": guest_id, "ids": COUNTED})
	if back.is_empty() or held.is_empty():
		await _dep_finish()
		return
	check(int(back.counts.berries) == 4, "the rejoined guest still holds exactly its four berries %s" % str(back.counts))
	check(held.counts == back.counts, "the host's authority record matches the rejoined guest %s" % str(held.counts))
	if not await _dep_step(0, "pickup_stand", {"id": "g1_fiber", "item": "fiber", "realm": "meadows", "count": 1}): return
	if not await _dep_step(1, "pickup_stand", {"id": "g1_fiber", "item": "fiber", "realm": "meadows", "count": 1}): return
	if not await _dep_step(1, "pickup_take", {}): return
	await step(1, "wait", {"frames": 180})
	var crafted := await _dep_data(1, "craft_at_host_kitchen", {"kitchen_uid": placed.kitchen_uid}, 3000)
	# Diagnostic: both peers' owner-passive state right after the craft.
	await _dep_data(1, "owner_passive_probe", {"character_id": guest_id})
	await _dep_data(0, "owner_passive_probe", {"character_id": guest_id})
	if not crafted.is_empty():
		check(int(crafted.after.potion_small) == int(crafted.before.potion_small) + 1,
			"the rejoined guest's owner-passive stream is alive: it crafts at the host's Kitchen")
	var final_held := await _dep_data(0, "craft_authority_count", {"character_id": guest_id, "ids": COUNTED})
	var final_back := await _dep_data(1, "craft_count", {"ids": COUNTED})
	if not final_held.is_empty() and not final_back.is_empty():
		check(final_held.counts == final_back.counts, "host authority still equals the guest after the craft %s" % str(final_held.counts))
	await _dep_finish()


func _dep_step(peer: int, action: String, args: Dictionary, frames: int = 3000) -> bool:
	var result := await step(peer, action, args, frames)
	var passed := str(result.get("verdict", "")) == "PASS"
	check(passed, "peer %d %s: %s" % [peer, action, str(result.get("detail", ""))])
	if not passed:
		await _dep_finish()
	return passed


func _dep_data(peer: int, action: String, args: Dictionary, frames: int = 1800) -> Dictionary:
	var result := await step(peer, action, args, frames)
	var passed := str(result.get("verdict", "")) == "PASS"
	check(passed, "peer %d %s: %s %s" % [peer, action, str(result.get("detail", "")), JSON.stringify(result.get("data", {}))])
	return result.get("data", {}) if passed else {}


func _dep_finish() -> void:
	print("G1 departure: guest leaves right after its batch rows are pruned, rejoins, crafts; no owner-passive refusal.")
	quit(await finish())
