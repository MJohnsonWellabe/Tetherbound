extends "res://tests/helpers/net_harness.gd"

# peers: 2

const COMBAT_MANAGER := preload("res://scripts/combat/combat_manager.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

## Stage B Wave 4 lane 4.C. THE player-visible outcome of the lane: two people
## fight one creature together, and neither of them can hit the other.
##
##   tools/net/run_net_smoke.sh shared_wild_fight
##
## ## What it asserts
##
## Peer 0 hosts and engages a wild creature through the production press. The
## host mints an encounter record (`docs/specs/MP_ENCOUNTER_PROTOCOL.md` §3) and
## announces it; peer 1 sees the announcement and JOINS the live fight (§6) --
## no reset, and the opponent does not get its health back. Both players then
## land a strike, and the health bar both of them are drawing is THE SAME
## NUMBER, because both are rendering the host's record rather than each
## decrementing a local copy.
##
## Then the rule the lane exists for (§5): peer 1 swings at peer 0's creature.
## The host REFUSES it with `friendly_target`, and peer 0's creature takes
## nothing. **Both halves are asserted.** A silent no-op -- a targeting bug that
## resolved onto the teammate and then rolled zero -- would pass the second half
## while failing the player, who would be left unable to tell "I swung at my
## friend" from "the game dropped my input".
##
## ## Why the friendly strike is submitted rather than pressed
##
## A button press always faces the opponent: `combat_manager.gd::_start_action()`
## calls `face_towards(_wild.centre())` on the way into the wind-up. So a swing
## aimed at a teammate cannot be produced by pressing a button, which is exactly
## why §5's refusal is a HOST rule and not a UI one -- 4.C must not rely on the
## UI never offering it. The harness's `strike` arm submits a `strike_intent`
## through `submit_encounter_intent()`, the same door `combat_manager.gd` itself
## submits through, with a facing of its choosing: what a modified client could
## say, said out loud.
##
## ## The geometry, and why the numbers are what they are
##
## Everything is placed relative to the OPPONENT'S OWN POSITION as the host
## reports it in the record, re-read before each phase, because the creature is
## a live AI and moves between them.
##
##   phase 1  peer 0's creature at opponent + (0, 0, -4.0)   facing +Z
##            peer 1's creature at opponent + (0, 0, +4.0)   facing -Z
##            Both inside the authored 9 m quick range while remaining clear of
##            body overlap; each faces directly AWAY from the other, so neither
##            is in the other's arc and both strikes are ordinary hits.
##
##   phase 2  victim about 8m outward from the live opponent; striker another
##            3.0m inward on that same radial line, facing outward at victim
##            8 m is chosen against the opponent's own `chase_speed` of
##            4.6 m/s: the whole of phase 2 is about 0.6 s of settling, so the
##            creature can close at most ~2.7 m of it and is still some 5 m
##            away -- comfortably outside its 3.25 m reach -- when peer 0's HP
##            is read. The bar is that peer 0's creature took NOTHING, and a
##            blow from the opponent landing inside the window would fail this
##            for a reason that is not the one under test. It is inside the
##            11 m arena radius, measured from an arena centred between the two
##            fighters, so `combat_arena.hold_inside()` never yanks anybody.
const NEAR_Z := 4.0
const AWAY_X := 8.0
const APART_Z := 3.0
## Frames each placement is given to settle. `remote_creature.gd` interpolates
## with a 0.08 s half-life, so 20 frames is about four half-lives -- and the
## window is deliberately short, for the reason phase 2's comment gives.
const PLACE_SETTLE := 20
const STRIKE_SETTLE := 15
## The host record is sampled at 10 Hz while the guest proxy interpolates; a
## cross-peer position read is therefore a bounded proximity check, not an
## exact equality. The shared harness uses 1.5 m for near/rest state.
const PROXY_POSE_TOLERANCE_M := 1.5
## How many swings each player gets at a creature that is actively running
## around. See the loop's own comment for why this is a swing budget and not a
## retry budget.
const SWINGS := 5

## How many times to ask peer 1 for the host's verdict on its friendly swing
## before calling it lost. Each poll is a coordinator round trip to the peer, so
## this is generous in wall-clock without being a fixed wait: a refusal that
## arrives on the first poll costs one, and the assertion below still fails if
## none ever arrives. Sized so the loop outlasts 7.A's jitter profile (150 ms
## delay / 30 ms jitter) rather than only loopback.
const REFUSAL_POLLS := 40

## How many times to re-read both peers' opponent hp before calling them
## divergent. Replication of the record's hp is not instantaneous and this smoke
## must not pretend it is; see the assertion's own comment for the measurement
## that forced this. A pair that agrees on the first read costs one poll.
const HP_CONVERGE_POLLS := 40
## The host wild runs its normal windup/strike clock. Wait for those real cues
## after join rather than emitting a synthetic event or shortening combat time.
const HOST_CUE_POLLS := 120


func _initialize() -> void:
	if "--guardian" in OS.get_cmdline_user_args():
		_run_guardian()
	else:
		_run()


func _init_budgets() -> void:
	super._init_budgets()
	if "--guardian" in OS.get_cmdline_user_args():
		# Two complete Meadows builds can exceed the ordinary startup bound
		# while the owner's other work has CPU priority. Gameplay bounds stay.
		_budgets["hello_budget_s"] = 360.0


func _run_guardian() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return
	var port := 0
	var hosted: Dictionary = await step(0, "host", {})
	if str(hosted.get("verdict", "")) == "PASS":
		port = int(((await probe(0, "session")) as Dictionary).get("enet_port", 0))
	check(port > 0, "guardian witness hosted a shared Meadows world")
	var joined: Dictionary = await step(1, "join", {"host": "127.0.0.1", "port": port})
	check(str(joined.get("verdict", "")) == "PASS", "guardian witness joined the hosted Meadows world")
	for peer in 2:
		for species: String in ["terrapup", "trailpup", "bramblebun", "burrowback", "meadowhart"]:
			var granted: Dictionary = await step(peer, "party_grant", {"species": species, "level": 16})
			check(str(granted.get("verdict", "")) == "PASS", "peer %d received retained level-16 %s" % [peer, species])
		var deployed: Dictionary = await step(peer, "deploy_creature", {})
		check(str(deployed.get("verdict", "")) == "PASS", "peer %d deployed its retained creature" % peer)
		var staged: Dictionary = await step(peer, "warrens_guardian", {"mode": "stage"})
		check(str(staged.get("verdict", "")) == "PASS", "peer %d resolved the authored Warren Guardian" % peer)
	var before_rewards: Array = []
	for peer in 2:
		before_rewards.append(await probe(peer, "trainer_reward", {"trainer": "warrens_cleared",
			"sources": ["trainer:warrens_cleared:coins", "trainer:warrens_cleared:item:rootstone", "trainer:warrens_cleared:item:orb_greater", "trainer:warrens_cleared:item:revive", "trainer:warrens_cleared:item:hide_vest"],
			"items": ["coin", "rootstone", "orb_greater", "revive", "hide_vest"]}))
	var state: Dictionary = (await step(0, "warrens_guardian", {})).get("data", {}) as Dictionary
	var markers: Dictionary = state.get("markers", {}) as Dictionary
	var entrance := _vec(markers.get("entrance", []))
	check(entrance != Vector3.INF and not bool(state.get("branch_open", true)), "guardian starts present behind a closed vault branch")
	if entrance == Vector3.INF:
		quit(await finish())
		return
	await step(0, "teleport", {"at": [entrance.x, entrance.y + 1.5, entrance.z], "settle": 60})
	for key: String in ["mouth", "hall"]:
		var at := _vec(markers.get(key, []))
		var walked: Dictionary = await step(0, "move_to", {"x": at.x, "z": at.z, "close_enough": 3.0, "budget_frames": 1800})
		check(str(walked.get("verdict", "")) == "PASS", "host walked the authored Warrens %s leg" % key)
		if str(walked.get("verdict", "")) != "PASS":
			quit(await finish())
			return
	# The guardian's own aggression stops this input approach immediately; the
	# narrow stage verifies the combat body is this exact authored guardian.
	var approached: Dictionary = await step(0, "warrens_guardian", {"mode": "approach", "budget_frames": 1800})
	check(str(approached.get("verdict", "")) == "PASS" and bool((approached.get("data", {}) as Dictionary).get("guardian_engaged", false)), "host's input approach immediately admitted the exact Warren Guardian")
	var host: Dictionary = await _encounter(0)
	var encounter_id := str(host.get("id", ""))
	check(str(host.get("opponent_species", "")) == "burrowback" and not encounter_id.is_empty(), "natural Warrens approach admitted the guardian's shared wild record")
	var opponent := _vec(host.get("opponent_pos", []))
	var ally_at := _vec(host.get("my_creature_pos", []))
	check(ally_at != Vector3.INF and ally_at.distance_to(opponent) < 12.0,
		"host's piloted companion deployed into the guardian fight rather than remaining at the cave entrance")
	# EARNED APPROACH. The guest used to be teleported onto the fight. It now
	# walks the same authored legs the host walked -- entrance, mouth, hall --
	# on its own input, and only then closes the last few metres to the
	# guardian. Being carried to a fight proves the fight; walking in proves the
	# approach, which is what `STATE`'s "earned Warrens approach/exit beyond the
	# prepared segment" is asking for.
	#
	# The entrance seat itself stays disclosed: the kilometres of Meadows spine
	# that reach the Warrens belong to `test_meadows_earned_warrens_segment.gd`,
	# not to this file.
	var guest_entrance := _vec(markers.get("entrance", []))
	await step(1, "teleport", {"at": [guest_entrance.x + 1.5, guest_entrance.y + 1.5, guest_entrance.z], "settle": 45})
	var guest_previous := guest_entrance
	for key: String in ["mouth", "hall"]:
		var guest_at := _vec(markers.get(key, []))
		if not await _walk_warrens_leg(1, guest_at, guest_previous, "%s leg" % key):
			quit(await finish())
			return
		check(true, "guest walked the authored Warrens %s leg on its own legs" % key)
		guest_previous = guest_at
	if not await _walk_warrens_leg(1, opponent, guest_previous, "approach to the guardian"):
		quit(await finish())
		return
	check(true, "guest reached the guardian by ordinary movement")
	var guest_admission := await _encounter(1)
	# Aggression can have submitted admission without receiving the host reply
	# yet. Observe the actual binding before attempting a second join request.
	for _admission_poll in 120:
		if bool(guest_admission.get("fighting", false)):
			break
		await process_frame
		guest_admission = await _encounter(1)
	var joined_fight: Dictionary
	if bool(guest_admission.get("fighting", false)) and str(guest_admission.get("bound_id", "")) == encounter_id:
		joined_fight = {"verdict": "PASS", "detail": "ordinary guardian aggression already joined the host record"}
	else:
		joined_fight = await step(1, "join_encounter", {"encounter_id": encounter_id})
	check(str(joined_fight.get("verdict", "")) == "PASS", "guest joined the exact guardian record")
	print("guardian guest admission: ", joined_fight)
	if str(joined_fight.get("verdict", "")) != "PASS":
		print("guardian rejected guest state: ", guest_admission)
		quit(await finish())
		return
	var guest_peer_id := int(((await probe(1, "session")) as Dictionary).get("peer_id", 0))
	var guest_strike_before := int((await _encounter(0)).get("host_now_ms", 0))
	var guest_button: Dictionary = await step(1, "guardian_pilot", {"until_hit": true, "encounter_id": encounter_id}, 2400)
	check(str(guest_button.get("verdict", "")) == "PASS", "guest moved and attacked through ordinary combat input (%s)" % str(guest_button.get("detail", "")))
	var guest_receipt: Dictionary = {}
	for _poll in REFUSAL_POLLS:
		guest_receipt = _fresh_accepted_receipt(await _encounter(0), encounter_id, guest_peer_id, guest_strike_before)
		if not guest_receipt.is_empty():
			break
	check(not guest_receipt.is_empty(), "host accepted the guest's fresh normal-button strike on the exact guardian record")
	if guest_receipt.is_empty():
		print("guardian guest hit rejected; host state: ", await _encounter(0))
		quit(await finish())
		return
	print("guardian before both pilots: ", await _encounter(0))
	var pilots: Array = await race([
		{"peer": 0, "action": "guardian_pilot", "args": {"encounter_id": encounter_id}, "budget_frames": 7800},
		{"peer": 1, "action": "guardian_pilot", "args": {"encounter_id": encounter_id}, "budget_frames": 7800},
	])
	var both_won := pilots.size() == 2
	for pilot_result: Dictionary in pilots:
		var verdict: Dictionary = pilot_result.get("verdict", {}) as Dictionary
		var won := str(verdict.get("verdict", "")) == "PASS"
		check(won, "peer %d input pilot completed the guardian (%s)" % [int(pilot_result.get("peer", -1)), str(verdict.get("detail", ""))])
		both_won = both_won and won
	if not both_won:
		quit(await finish())
		return
	for _settle in 180:
		await process_frame
	for peer in 2:
		var story: Dictionary = await probe(peer, "story", {"world_flags": ["warrens_cleared"]}) as Dictionary
		var after: Dictionary = (await step(peer, "warrens_guardian", {})).get("data", {}) as Dictionary
		check(bool((story.get("world", {}) as Dictionary).get("warrens_cleared", false)) and bool(after.get("branch_open", false)), "peer %d received the cleared Warrens fact and opened live branch" % peer)
		var reward: Dictionary = await probe(peer, "trainer_reward", {"trainer": "warrens_cleared",
			"sources": ["trainer:warrens_cleared:coins", "trainer:warrens_cleared:item:rootstone", "trainer:warrens_cleared:item:orb_greater", "trainer:warrens_cleared:item:revive", "trainer:warrens_cleared:item:hide_vest"],
			"items": ["coin", "rootstone", "orb_greater", "revive", "hide_vest"]}) as Dictionary
		var stock: Dictionary = reward.get("satchel", {}) as Dictionary
		var before_stock: Dictionary = ((before_rewards[peer] as Dictionary).get("satchel", {}) as Dictionary)
		check(int(stock.get("coin", 0)) == int(before_stock.get("coin", 0)) + 90 and int(stock.get("rootstone", 0)) == int(before_stock.get("rootstone", 0)) + 5 and int(stock.get("orb_greater", 0)) == int(before_stock.get("orb_greater", 0)) + 2 and int(stock.get("revive", 0)) == int(before_stock.get("revive", 0)) + 1 and int(stock.get("hide_vest", 0)) == int(before_stock.get("hide_vest", 0)) + 1, "peer %d received the full authored guardian receipt" % peer)
		var reload: Dictionary = await step(peer, "save_reload_here", {})
		check(str(reload.get("verdict", "")) == "PASS", "peer %d retained its five creature identities through production reload" % peer)
	var characters: Array[String] = []
	for peer in 2:
		characters.append(str(((await probe(peer, "character_restore")) as Dictionary).get("live_character_id", "")))
	characters.sort()
	check(characters.size() == 2 and not characters[0].is_empty() and characters[0] != characters[1],
		"guardian rewards address two distinct persistent characters")
	var host_world: Dictionary = {}
	var guest_world: Dictionary = {}
	for _attempt in 60:
		host_world = await probe(0, "world_snapshot") as Dictionary
		guest_world = await probe(1, "world_snapshot") as Dictionary
		if host_world.get("reward_deliveries", {}) == guest_world.get("reward_deliveries", {}) and _guardian_sources_accepted(host_world, characters):
			break
		await process_frame
	check(_guardian_sources_accepted(host_world, characters), "each guardian reward source has accepted receipts for the exact two stable character IDs")
	check(host_world.get("reward_deliveries", {}) == guest_world.get("reward_deliveries", {}),
		"both peers retain the same guardian delivery journal")

	# EARNED EXIT. A cleared dungeon nobody can leave is not cleared. Both peers
	# walk back out the way they came in -- hall, mouth, entrance -- on ordinary
	# input, after the fight, the rewards and the reload. This is the second
	# half of STATE's "earned Warrens approach/exit"; the segment used to end
	# with both peers standing in the guardian's chamber.
	var exit_markers: Dictionary = ((await step(0, "warrens_guardian", {})).get("data", {}) as Dictionary).get("markers", {}) as Dictionary
	for peer in 2:
		var left := true
		var came_from := Vector3.INF
		for key: String in ["hall", "mouth", "entrance"]:
			var out_at := _vec(exit_markers.get(key, []))
			if out_at == Vector3.INF:
				left = false
				break
			if not await _walk_warrens_leg(peer, out_at, came_from, "%s on the way out" % key):
				left = false
				break
			came_from = out_at
		check(left, "peer %d walked out of the cleared Warrens on its own legs" % peer)
	check(await assert_all_hashes_equal(600),
		"both peers still hold one shared world after leaving the cleared Warrens")
	quit(await finish())


## Walk one authored Warrens leg, unwedging if the cave catches this peer.
##
## `move_to` drives ordinary movement input in a straight line; it does not
## path-find. Inside a cave that is usually fine and occasionally is not -- a
## peer clips a corner and stops with the target still ten metres off. Measured
## here: the guest reached the guardian on one run and stopped 9.80 m short on
## the next, and on the way out stopped 13.69 m short of the mouth.
##
## So back off toward where this peer came from and try the leg again, which is
## what a player does when they snag on a corner. The assertion is unchanged --
## the peer must still arrive under its own movement -- and the number of
## attempts is reported so a leg that needs several is visible rather than
## silent.
func _walk_warrens_leg(peer: int, target: Vector3, retreat: Vector3, label: String) -> bool:
	var detail := ""
	for attempt in 3:
		var walked: Dictionary = await step(peer, "move_to",
			{"x": target.x + (1.5 if peer == 1 else -1.5), "z": target.z,
			 "close_enough": 4.0, "budget_frames": 2400})
		detail = str(walked.get("detail", ""))
		if str(walked.get("verdict", "")) == "PASS":
			if attempt > 0:
				print("warrens: peer %d needed %d attempts for %s" % [peer, attempt + 1, label])
			return true
		if retreat == Vector3.INF:
			break
		# Unwedge: step back the way it came, then take the leg again.
		await step(peer, "move_to", {"x": retreat.x, "z": retreat.z,
			"close_enough": 6.0, "budget_frames": 900})
	check(false, "peer %d walked the Warrens %s (%s)" % [peer, label, detail])
	return false


func _guardian_sources_accepted(world: Dictionary, expected: Array[String]) -> bool:
	var deliveries: Dictionary = world.get("reward_deliveries", {}) as Dictionary
	for source: String in ["trainer:warrens_cleared:coins", "trainer:warrens_cleared:item:rootstone", "trainer:warrens_cleared:item:orb_greater", "trainer:warrens_cleared:item:revive", "trainer:warrens_cleared:item:hide_vest"]:
		var accepted: Array[String] = []
		for raw: Variant in deliveries.values():
			if raw is Dictionary and str((raw as Dictionary).get("source", "")) == source and str((raw as Dictionary).get("status", "")) == "accepted":
				accepted.append(str((raw as Dictionary).get("character_id", "")))
		accepted.sort()
		if accepted != expected:
			return false
	return true


func _fresh_accepted_receipt(state: Dictionary, encounter_id: String, peer_id: int,
		not_before_ms: int) -> Dictionary:
	for raw: Variant in (state.get("host_strike_receipts", []) as Array):
		if raw is Dictionary:
			var receipt := raw as Dictionary
			if str(receipt.get("encounter_id", "")) == encounter_id and int(receipt.get("peer_id", 0)) == peer_id \
					and int(receipt.get("host_now_ms", -1)) >= not_before_ms and bool(receipt.get("ok", false)):
				return receipt.duplicate(true)
	return {}


func _run() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return

	# --- the handshake, copied verbatim from smoke_net_movement_two_peers.gd ---
	check(_peers.size() == 2, "coordinator tracked 2 peers")
	for i in 2:
		var ctx = await probe(i, "input_context")
		check(str(ctx) == "world", "peer %d input_context is 'world' (got '%s')" % [i, str(ctx)])

	var session = await probe(0, "session")
	var have_session := session is Dictionary and bool((session as Dictionary).get("available", false))
	check(have_session,
		"a Session exists to host/join (lane 2.A); without it there are no remote bodies to see")
	if not have_session:
		quit(await finish())
		return

	var hosted: Dictionary = await step(0, "host", {})
	check(str(hosted.get("verdict", "")) == "PASS",
		"peer 0 hosted a world (%s)" % str(hosted.get("detail", "")))
	var host_session = await probe(0, "session")
	var host_peer_id := int((host_session as Dictionary).get("peer_id", 1)) \
		if host_session is Dictionary else 1
	var port := int((host_session as Dictionary).get("enet_port", 0)) if host_session is Dictionary else 0
	var joined: Dictionary = await step(1, "join", {"host": "127.0.0.1", "port": port})
	check(str(joined.get("verdict", "")) == "PASS",
		"peer 1 joined peer 0's world on port %d (%s)" % [port, str(joined.get("detail", ""))])
	var guest_session: Variant = await probe(1, "session")
	var guest_peer_id := int((guest_session as Dictionary).get("peer_id", 0)) \
		if guest_session is Dictionary else 0
	check(guest_peer_id > 1, "the joiner has a real ENet peer id for host action authority")
	for i in 2:
		var seen: Dictionary = await step(i, "expect_peers", {"count": 2})
		check(str(seen.get("verdict", "")) == "PASS",
			"peer %d's registry holds both players (%s)" % [i, str(seen.get("detail", ""))])
	# --- end of the copied handshake block ------------------------------------

	# Both players need a creature out before either can fight with one.
	for i in 2:
		var deployed: Dictionary = await step(i, "deploy_creature", {})
		check(str(deployed.get("verdict", "")) == "PASS",
			"peer %d deployed its own creature (%s)" % [i, str(deployed.get("detail", ""))])

	# --- peer 0 starts a fight ------------------------------------------------
	var engaged: Dictionary = await step(0, "engage_wild", {})
	check(str(engaged.get("verdict", "")) == "PASS",
		"peer 0 engaged a wild creature (%s)" % str(engaged.get("detail", "")))
	if str(engaged.get("verdict", "")) != "PASS":
		quit(await finish())
		return

	var host_view: Dictionary = await _encounter(0)
	var encounter_id := str(host_view.get("id", ""))
	check(not encounter_id.is_empty(), "the host minted an encounter record for that fight")
	check(str(host_view.get("kind", "")) == "wild",
		"and it is a wild encounter (got '%s')" % str(host_view.get("kind", "")))
	check(str(host_view.get("realm", "")) != "",
		"stamped with an explicit realm (D97), got '%s'" % str(host_view.get("realm", "")))
	var full_hp := float(host_view.get("opponent_hp", -1.0))
	check(full_hp > 0.0, "the record carries the opponent's hit points (%.1f)" % full_hp)

	# --- peer 1 joins it (§6) -------------------------------------------------
	var guest_before: Dictionary = await _encounter(1)
	check((guest_before.get("joinable", []) as Array).has(encounter_id),
		"peer 1 was told the fight exists and can be joined (announced ids: %s)"
			% str(guest_before.get("joinable", [])))

	# Travel to the host's fight before joining. Admission now creates a
	# dedicated host-card proxy; it must not select or move an ambient wild.
	var here := _vec(host_view.get("opponent_pos", []))
	check(here != Vector3.INF, "the announcement says where the fight is happening")
	if here == Vector3.INF:
		quit(await finish())
		return
	var travelled: Dictionary = await step(1, "teleport",
		{"at": [here.x - 2.5, here.y + 1.0, here.z]})
	check(str(travelled.get("verdict", "")) == "PASS",
		"peer 1 travelled to the fight (%s)" % str(travelled.get("detail", "")))

	var joined_fight: Dictionary = await step(1, "join_encounter", {"encounter_id": encounter_id})
	check(str(joined_fight.get("verdict", "")) == "PASS",
		"peer 1 joined the fight already in progress (%s)" % str(joined_fight.get("detail", "")))

	var after_join_host: Dictionary = await _encounter(0)
	check((after_join_host.get("participants", []) as Array).size() == 2,
		"the host's record now holds 2 participants (got %d)"
			% (after_join_host.get("participants", []) as Array).size())
	check(str(after_join_host.get("phase", "")) == "active",
		"joining did not change the phase (got '%s')" % str(after_join_host.get("phase", "")))
	check(float(after_join_host.get("opponent_hp", -1.0)) <= full_hp + 0.001,
		"and it did not refill the opponent -- no reset for the player already fighting")
	var guest_after: Dictionary = await _encounter(1)
	check(str(guest_after.get("bound_id", "")) == encounter_id,
		"peer 1's fight is bound to the SAME record (got '%s')" % str(guest_after.get("bound_id", "")))
	# The joining peer must render the host's actual opponent presentation. The
	# record fields above alone would also pass with a stale ambient wild body.
	check(str(guest_after.get("presentation_script", ""))
		== "res://scripts/creatures/shared_opponent_proxy.gd",
		"peer 1 uses the shared-opponent presentation proxy (got '%s')"
			% str(guest_after.get("presentation_script", "")))
	check(str(guest_after.get("presentation_species", ""))
		== str(after_join_host.get("opponent_species", "")),
		"peer 1's presentation species matches the host record (guest '%s', host '%s')"
			% [str(guest_after.get("presentation_species", "")),
				str(after_join_host.get("opponent_species", ""))])
	var guest_centre := _vec(guest_after.get("presentation_centre", []))
	var guest_target_centre := _vec(guest_after.get("presentation_target_centre", []))
	check(guest_centre != Vector3.INF and guest_target_centre != Vector3.INF
		and guest_centre.distance_to(guest_target_centre) <= PROXY_POSE_TOLERANCE_M,
		"peer 1's presentation centre follows its last host pose (target %s, actual %s)"
			% [str(guest_target_centre), str(guest_centre)])
	check(not bool(guest_after.get("presentation_engaged", true)),
		"peer 1's shared presentation proxy has no local enemy AI")
	check(int(guest_after.get("presentation_last_pose_seq", 0)) >= 1,
		"peer 1 applied at least one host presentation pose")
	check(int(guest_after.get("presentation_body_generation", 0)) > 0,
		"peer 1 applied the host opponent body generation")
	var cue_seen := false
	for _poll in HOST_CUE_POLLS:
		var cue_view := await _encounter(1)
		if int(cue_view.get("presentation_telegraph_count", 0)) > 0 \
				and int(cue_view.get("presentation_strike_count", 0)) > 0:
			cue_seen = true
			break
	check(cue_seen,
		"peer 1 received a real host telegraph and strike cue within %d polls" % HOST_CUE_POLLS)

	# --- both land a strike, and the bar is one number ------------------------
	var hp_before := float(after_join_host.get("opponent_hp", -1.0))
	for mover in 2:
		var host_hp := hp_before
		var swings := 0
		# Up to SWINGS swings, each one a fresh read of where the host holds the
		# opponent, a step back into reach of it, and a real `strike_intent`.
		#
		# NOT a weakened assertion, and the reason is worth stating because "run
		# it again until it passes" is exactly the shape of one. The opponent is
		# a live AI that chases whichever creature it is engaged with at
		# `chase_speed` 4.6 m/s, so between the frame this smoke reads its
		# position and the frame the host resolves the swing it has genuinely
		# moved -- and a swing at where a creature was a moment ago genuinely
		# misses, which is `docs/decisions/D07`'s whole point ("attacks are aimed
		# and can miss"). A player who misses swings again. The claim under test
		# is that peer `mover` CAN land a blow on the shared opponent and that
		# both peers then read the same bar, not that any particular swing of a
		# moving target connects; a peer whose strikes never reached the host, or
		# were refused, or landed only on its own copy, fails this in every
		# swing.
		while swings < SWINGS and host_hp >= hp_before - 0.001:
			swings += 1
			var view: Dictionary = await _encounter(0)
			var opponent := _vec(view.get("opponent_pos", []))
			check(opponent != Vector3.INF, "the record says where the host holds the opponent")
			if opponent == Vector3.INF:
				break
			# Each creature stands on its own side of the opponent, facing it --
			# and therefore facing directly away from the other player's
			# creature, so neither is ever in the other's arc here.
			var side := -NEAR_Z if mover == 0 else NEAR_Z
			var stand := opponent + Vector3(0.0, 0.0, side)
			var placed: Dictionary = await step(mover, "place_creature",
				{"at": [stand.x, stand.y, stand.z],
				 "face": [opponent.x, opponent.y, opponent.z], "settle": PLACE_SETTLE})
			check(str(placed.get("verdict", "")) == "PASS",
				"peer %d stood its creature beside the opponent (%s)"
					% [mover, str(placed.get("detail", ""))])

			# The facing is taken from the LAST possible read, so a swing that
			# misses missed because the creature moved, not because the smoke
			# aimed at a stale number it could have refreshed.
			var fresh := _vec((await _encounter(0)).get("opponent_pos", []))
			var aim_at := opponent if fresh == Vector3.INF else fresh
			var toward := aim_at - stand
			var struck: Dictionary = await step(mover, "strike",
				{"facing": [toward.x, toward.y, toward.z], "slot": "quick",
				 "settle": STRIKE_SETTLE})
			check(str(struck.get("verdict", "")) == "PASS",
				"peer %d swung at the opponent (%s)" % [mover, str(struck.get("detail", ""))])
			host_hp = float((await _encounter(0)).get("opponent_hp", -1.0))

		check(host_hp < hp_before - 0.001,
			"peer %d landed a blow on the shared opponent within %d swings: %.1f -> %.1f on the host"
				% [mover, swings, hp_before, host_hp])
		# §3: the record's hp is THE hit points, and both peers render it. A
		# client that decremented its own copy "for responsiveness" would
		# diverge here by exactly one blow.
		#
		# CONVERGENCE, not instantaneous equality -- and the difference is the
		# whole claim rather than a softened one. Measured under the harness
		# proxy at 150 ms delay / 30 ms jitter / 1 % loss: host 96.698 against
		# guest 104.595, because a single read of the guest taken immediately
		# after the host's is a read of a value one round trip behind. Asserting
		# equality there is asserting ZERO LATENCY, which no session on a real
		# LAN provides and which this smoke is not entitled to demand.
		#
		# What host authority actually promises is that the number the guest
		# ends up drawing is the HOST'S number, not one it computed itself. So
		# the guest is polled until it agrees, and the assertion still fails --
		# loudly, with the final gap -- if it never does. A client that
		# decremented its own copy would sit at a different value forever and
		# fail this on the last poll exactly as it failed on the first.
		#
		# The host is re-read every iteration on purpose: the fight is live, so
		# a host value that moved mid-poll would otherwise look like a guest
		# that failed to catch up.
		var guest_hp := -1.0
		var hp_polls := 0
		while hp_polls < HP_CONVERGE_POLLS:
			hp_polls += 1
			host_hp = float((await _encounter(0)).get("opponent_hp", -1.0))
			guest_hp = float((await _encounter(1)).get("opponent_hp", -1.0))
			if absf(guest_hp - host_hp) < 0.001:
				break
		check(absf(guest_hp - host_hp) < 0.001,
			"both peers draw the same health bar after it, within %d poll(s) (host %.3f, guest %.3f, gap %.3f)"
				% [hp_polls, host_hp, guest_hp, absf(guest_hp - host_hp)])
		hp_before = host_hp

	# --- host action/replay/cooldown authority --------------------------------
	# First let the previous real swing's host deadline elapse. The probe reads
	# host time, so coordinator polling latency cannot turn this into a guess.
	var prior_authority := await _await_host_action_ready(guest_peer_id)
	check(int(prior_authority.get("host_now_ms", 0)) >= int(prior_authority.get("deadline_ms", 0)),
		"the prior real move reached its host-owned deadline")
	var action_stage: Dictionary = await _encounter(0)
	var action_target := _vec(action_stage.get("opponent_pos", []))
	var action_origin := _vec((await _encounter(1)).get("my_creature_pos", []))
	# Deliberately whiff the authority strike outward, away from the opponent.
	# The host trainer and ally are on the opposite side in this staging, so
	# the charged action can commit its lock without changing opponent HP.
	var action_facing := action_origin - action_target
	action_facing.y = 0.0
	check(action_target != Vector3.INF and action_origin != Vector3.INF
		and action_facing.length_squared() > 0.0001,
		"the authority strike has real host target and client body positions")
	# Use the authored charged profile for the accepted action: its 1.2-second
	# host lock is long enough to make this proof insensitive to coordinator and
	# CI scheduling jitter. The next intent is submitted immediately, before any
	# coordinator probe. Both travel reliable and ordered on CHANNEL_LEDGER, so
	# the host must arbitrate 9001 before 9002 and must arbitrate both inside the
	# same host-owned lock. The guest's forged zero cooldown remains the claim.
	var forged: Dictionary = await step(1, "strike", {
		"facing": [action_facing.x, action_facing.y, action_facing.z], "slot": "charged",
		"action": 9001, "cooldown": 0.0, "cooldown_multiplier": 0.0,
		"damage": 999999.0, "settle": 1,
	})
	check(str(forged.get("verdict", "")) == "PASS", "client sent a forged rapid-action payload")
	var rapid: Dictionary = await step(1, "strike", {
		"facing": [action_facing.x, action_facing.y, action_facing.z], "slot": "quick",
		"action": 9002, "cooldown": 0.0, "cooldown_multiplier": 0.0, "settle": 1,
	})
	check(str(rapid.get("verdict", "")) == "PASS", "client sent a fresh id before host cooldown")
	var rapid_refusal := await _await_refusal("cooldown")
	check(str(rapid_refusal.get("code", "")) == "cooldown",
		"host refused a fresh rapid intent against its own deadline")
	var accepted_authority := await _await_host_action(guest_peer_id, 9001)
	check(int(accepted_authority.get("last_action", 0)) == 9001,
		"host accepted the fresh monotonic action")
	check(int(accepted_authority.get("cooldown_ms", 0)) >= 1200,
		"host retained its resolved charged-move lock instead of the forged zero cooldown")
	var accepted_deadline := int(accepted_authority.get("deadline_ms", 0))

	var replayed: Dictionary = await step(1, "strike", {
		"facing": [action_facing.x, action_facing.y, action_facing.z], "slot": "quick",
		"action": 9001, "cooldown": 0.0, "settle": 1,
	})
	check(str(replayed.get("verdict", "")) == "PASS", "client replayed the accepted action id")
	var replay_refusal := await _await_refusal("replayed_action")
	check(str(replay_refusal.get("code", "")) == "replayed_action",
		"host refused the replay even if its original cooldown elapsed")
	var held_authority := await _host_authority(guest_peer_id)
	check(int(held_authority.get("last_action", 0)) == 9001
		and int(held_authority.get("deadline_ms", 0)) == accepted_deadline,
		"refused replay/rapid intents changed neither accepted action nor deadline")
	await _await_host_action_ready(guest_peer_id)

	# --- §5: peer 1 swings at peer 0's creature -------------------------------
	var stage: Dictionary = await _encounter(0)
	var opponent_now := _vec(stage.get("opponent_pos", []))
	if opponent_now == Vector3.INF:
		check(false, "the record still says where the opponent is")
		quit(await finish())
		return
	var victim_spot := opponent_now + Vector3(AWAY_X, 0.0, 0.0)
	var v_placed: Dictionary = await step(0, "place_creature",
		{"at": [victim_spot.x, victim_spot.y, victim_spot.z], "settle": PLACE_SETTLE})
	check(str(v_placed.get("verdict", "")) == "PASS",
		"peer 0's creature stepped clear of the opponent (%s)" % str(v_placed.get("detail", "")))
	# Peer 1's creature is placed relative to where peer 0's creature ACTUALLY
	# came to rest, not to where it was asked to stand. A body dropped onto
	# sloping ground settles and slides -- measured at over 2 m across a
	# 20-frame settle. Put the striker between the live opponent and the victim:
	# its teammate is directly outward while the opponent is behind it. The old
	# fixed +Z offset left the opponent near the strike-cone boundary, so live
	# movement could either put the opponent in the cone or slide the teammate
	# out of a narrow one; neither geometry proves the friendly-target rule.
	var placement_state := await _encounter(0)
	var settled := _vec(placement_state.get("my_creature_pos", []))
	var placement_opponent := _vec(placement_state.get("opponent_pos", []))
	var outward := settled - placement_opponent
	outward.y = 0.0
	var radial_valid := settled != Vector3.INF and placement_opponent != Vector3.INF \
		and outward.length_squared() > 0.0001
	check(radial_valid,
		"the settled victim defines an outward line from the live opponent")
	if not radial_valid:
		quit(await finish())
		return
	var striker_spot := settled - outward.normalized() * APART_Z
	var s_placed: Dictionary = await step(1, "place_creature",
		{"at": [striker_spot.x, striker_spot.y, striker_spot.z], "settle": PLACE_SETTLE})
	check(str(s_placed.get("verdict", "")) == "PASS",
		"peer 1's creature stood next to it (%s)" % str(s_placed.get("detail", "")))

	var victim_before: Dictionary = await _encounter(0)
	var victim_hp := float(victim_before.get("my_creature_hp", -1.0))
	var opponent_hp_before_friendly := float(victim_before.get("opponent_hp", -1.0))
	var friendly_not_before_ms := int(victim_before.get("host_now_ms", 0))
	var victim_struck_before := _struck_count(victim_before, host_peer_id)
	check(victim_hp > 0.0, "peer 0's creature is alive to be swung at (%.1f hp)" % victim_hp)
	check(opponent_hp_before_friendly > 0.0,
		"the shared opponent is alive before the friendly-strike check (%.1f hp)"
			% opponent_hp_before_friendly)

	# The facing is derived from where the two creatures ACTUALLY ended up, not
	# from where they were asked to stand. Bodies settle onto sloping ground and
	# slide while they do, and a swing aimed at the intended spot rather than
	# the real one can miss its own target's cone -- which would fail this for
	# the wrong reason, and would fail it by NOT refusing, i.e. in exactly the
	# direction that looks like the feature working.
	var victim_at := _vec(victim_before.get("my_creature_pos", []))
	var striker_at := _vec((await _encounter(1)).get("my_creature_pos", []))
	check(victim_at != Vector3.INF and striker_at != Vector3.INF,
		"both creatures report where they are standing")
	var at_teammate := victim_at - striker_at
	at_teammate.y = 0.0
	# A diagnostic bound, not the claim. Its only job is to make "the swing
	# never reached the teammate" legible if the refusal assertion below fails:
	# a swing that fell short would be refused by nothing, which reads exactly
	# like the feature working. Ask the same body-size floor the host uses. The
	# old fixed 4.0 m diagnostic became smaller than two non-overlapping
	# road-scale Terrapups even though the production swing grew with them.
	var radius := float(SPECIES.placeholder("terrapup").get("radius", 0.5))
	var quick: Dictionary = COMBAT_MANAGER.floor_reach_for_bodies(
		{"range": 2.6}, radius, radius)
	var actual_reach := float(quick.get("range", 0.0))
	check(at_teammate.length() <= actual_reach + 0.05,
		"the two creatures are within the host's %.2f m swing reach (%.2f m apart)"
			% [actual_reach, at_teammate.length()])

	# Aim THROUGH the teammate: along the striker->teammate line, to a point
	# beyond it. The strike helper derives facing from the local live origin, so
	# a point beyond the victim keeps that vector aligned when the host's remote
	# body has a small remaining proxy offset. The host still resolves the live
	# teammate body and must refuse the action as friendly_target.
	#
	# It used to aim along the placement's outward radial instead. Once the
	# victim slid off that radial while settling, the line passed beside it, and
	# a quick move with a narrow cone missed its own teammate. CI 35955599022:
	# pebble_toss has a 26 degree cone, the teammate stood 17 degrees off the
	# facing at 1.52 m, the host scored an ordinary whiff, and the action id was
	# spent. The rule under test was never exercised.
	var friendly_target := victim_at + at_teammate.normalized() * 3.0
	var friendly: Dictionary = await step(1, "strike",
		{"target": [friendly_target.x, friendly_target.y, friendly_target.z], "slot": "quick",
			"settle": STRIKE_SETTLE})
	check(str(friendly.get("verdict", "")) == "PASS",
		"peer 1's swing at its teammate reached the host (%s)" % str(friendly.get("detail", "")))
	check(int((friendly.get("data", {}) as Dictionary).get("submitted_action", 0)) == 9003,
		"the friendly strike uses the next automatic action id after explicit authority/replay probes")

	# POLLED, not read once after a fixed settle. This was a flake and a jitter
	# failure and they were the same defect.
	#
	# The refusal is the HOST's answer and it comes back over the wire, so the
	# only thing `STRIKE_SETTLE` frames buys is "probably long enough on
	# loopback". Measured: this smoke ran 5 of 7 on one branch against 6 of 7 on
	# its untouched base, and under 7.A's proxy at 150 ms delay / 30 ms jitter
	# / 1 % loss it lost the refusal MESSAGE every time while the safety itself
	# held (7.A finding F7, recorded and deliberately not tuned). Both were one
	# read landing before the answer arrived.
	#
	# This is a fix at the cause and NOT a widened tolerance: the assertion
	# still fails if the refusal never comes, if it comes with the wrong code,
	# or if it comes without a sentence. What it no longer does is fail because
	# a round trip took longer than a quarter of a second. Same shape as the
	# `engage` binding poll in `peer_runner.gd::_step_engage` -- on a client,
	# `submit()` answers `{"ok": false, "pending": true}` and the verdict
	# follows a round trip later, so a single read of a host's answer is the
	# "pending is not a refusal" trap wearing a different hat.
	var refusal: Dictionary = {}
	var refusal_polls := 0
	# The preceding replay proof deliberately leaves `replayed_action` in the
	# client's last-refusal snapshot. Submission is asynchronous and does not
	# clear that snapshot. Wait for this phase's expected host verdict, rather
	# than treating the old non-empty response as the new strike's answer.
	# The bounded poll still fails on a missing or wrong friendly verdict.
	while refusal_polls < REFUSAL_POLLS:
		refusal_polls += 1
		refusal = ((await _encounter(1)).get("refusal", {}) as Dictionary)
		if str(refusal.get("code", "")) == "friendly_target":
			break
	# HALF ONE: the host said no, out loud, with the code §5 names.
	check(str(refusal.get("code", "")) == "friendly_target",
		"the host refused it with `friendly_target` after %d poll(s) (got code '%s', reason '%s')"
			% [refusal_polls, str(refusal.get("code", "")), str(refusal.get("reason", ""))])
	check(not str(refusal.get("reason", "")).is_empty(),
		"and gave the striker a sentence a player can be shown")

	# The client's last-refusal field above remains a player-facing acceptance
	# requirement. The host receipt independently identifies the exact action it
	# answered, so the preceding replayed_action snapshot cannot be mistaken for
	# action 9003. This reuses the host read that already sampled victim HP below:
	# no poll count, settle, placement, input or observation window is widened.
	var host_verdict_view: Dictionary = await _encounter(0)
	var host_receipt := _host_strike_receipt(host_verdict_view, encounter_id,
		guest_peer_id, 9003, friendly_not_before_ms)
	check(not host_receipt.is_empty(),
		"the host retained a fresh encounter/action-correlated receipt for friendly action 9003 "
			+ "(not_before=%d receipts=%s)" % [friendly_not_before_ms,
				str(host_verdict_view.get("host_strike_receipts", []))])
	check(str(host_receipt.get("outcome", "")) == "refused"
		and not bool(host_receipt.get("ok", true))
		and str(host_receipt.get("code", "")) == "friendly_target",
		"the correlated host verdict refused action 9003 as friendly_target (%s)"
			% str(host_receipt))
	check(bool(host_receipt.get("geometry_available", false)),
		"action 9003 reached host arbitration and carries its geometry")
	var receipt_origin := _vec(host_receipt.get("host_origin", []))
	var receipt_facing := _vec(host_receipt.get("facing", []))
	var receipt_move: Dictionary = host_receipt.get("move", {}) as Dictionary
	var opponent_candidate := _strike_candidate(host_receipt, 0, "opponent")
	var friendly_candidate := _strike_candidate(host_receipt, host_peer_id, "creature")
	check(receipt_origin != Vector3.INF and receipt_facing != Vector3.INF
		and not receipt_move.is_empty(),
		"the host receipt names its exact origin, facing and resolved move (%s)"
			% str(host_receipt))
	check(not friendly_candidate.is_empty()
		and bool(friendly_candidate.get("eligible", false))
		and bool(friendly_candidate.get("connects", false))
		and _vec(friendly_candidate.get("position", [])) != Vector3.INF,
		"the host saw peer 0's creature as a connected friendly candidate (%s)"
			% str(host_receipt.get("candidates", [])))
	check(not opponent_candidate.is_empty()
		and bool(opponent_candidate.get("eligible", false))
		and not bool(opponent_candidate.get("connects", true))
		and _vec(opponent_candidate.get("position", [])) != Vector3.INF,
		"the host saw the live opponent outside friendly action 9003 (%s)"
			% str(host_receipt.get("candidates", [])))

	# HALF TWO: the teammate took nothing. Asserted alongside the refusal and
	# never instead of it -- a silent no-op passes this line while hiding a
	# targeting bug, which is the whole reason both halves are here.
	var victim_after := float(host_verdict_view.get("my_creature_hp", -1.0))
	var victim_struck_after := _struck_count(host_verdict_view, host_peer_id)
	check(absf(victim_after - victim_hp) < 0.001,
		("peer 0's creature took nothing from it (%.3f before, %.3f after; "
			+ "enemy struck_count %d -> %d)"
			) % [victim_hp, victim_after, victim_struck_before, victim_struck_after])
	check(victim_struck_after == victim_struck_before,
		"the host recorded no opponent blow during the friendly-action window (%d -> %d)"
			% [victim_struck_before, victim_struck_after])

	# And the opponent took nothing either: a refused strike is refused BEFORE
	# any roll, so there is no blow for it to have landed somewhere else.
	#
	# Baseline THIS phase immediately before the friendly strike, not from the
	# earlier two-player damage phase. The authority checks between those phases
	# deliberately submit the outward action 9001 and require the host to accept
	# its charged lock. It is a legal whiff, so it cannot change opponent HP;
	# `victim_before` is read after that authority sequence resolves and after
	# both phase-2 placements, isolating the later refused friendly strike.
	var opponent_after := float((await _encounter(0)).get("opponent_hp", -1.0))
	check(absf(opponent_after - opponent_hp_before_friendly) < 0.001,
		"and the opponent took nothing from it either (%.3f before, %.3f after)"
			% [opponent_hp_before_friendly, opponent_after])

	# --- shared-wild lifetime: host flee, independent B, then rejoin A --------
	# A host flee is the real combat_run input. The guest remains in A, so its
	# host runtime must continue issuing the same AI cues after A loses peer 0.
	var a_before_flee := await _runtime(0, encounter_id)
	check(bool(a_before_flee.get("active_runtime", false)),
		"A has a live host authority runtime before the host flees")
	var host_flee_a := await step(0, "press", {"action": "combat_run"})
	check(str(host_flee_a.get("verdict", "")) == "PASS",
		"host fled wild encounter A through combat_run (%s)" % str(host_flee_a.get("detail", "")))
	var host_inactive_after_a := false
	for _inactive_poll in 120:
		var host_after_flee := await _encounter(0)
		if not bool(host_after_flee.get("fighting", true)):
			host_inactive_after_a = true
			break
		await step(0, "wait", {"frames": 4})
	check(host_inactive_after_a, "host manager finished A's flee before another fight starts")
	var a_after_flee := await _runtime(0, encounter_id)
	var a_participants: Array[int] = []
	for raw_a_peer: Variant in (a_after_flee.get("participants", []) as Array):
		a_participants.append(int(raw_a_peer))
	check(bool(a_after_flee.get("active_runtime", false))
		and str(a_after_flee.get("phase", "")) == "active"
		and (a_participants.has(guest_peer_id))
		and not a_participants.has(host_peer_id),
		"A remains active for the guest after host flee (runtime=%s participants=%s)"
			% [str(a_after_flee) , str(a_participants)])
	var a_body_id := int(a_after_flee.get("body_instance_id", 0))
	var guest_cues_before := await _encounter(1)
	var guest_telegraphs_before := int(guest_cues_before.get("presentation_telegraph_count", 0))
	var guest_strikes_before := int(guest_cues_before.get("presentation_strike_count", 0))
	var host_strikes_before := int(a_after_flee.get("strike_count", 0))
	var cue_continued := false
	for _cue_poll in HOST_CUE_POLLS:
		var guest_cues := await _encounter(1)
		var a_live := await _runtime(0, encounter_id)
		if int(guest_cues.get("presentation_telegraph_count", 0)) > guest_telegraphs_before \
				and int(guest_cues.get("presentation_strike_count", 0)) > guest_strikes_before \
				and int(a_live.get("strike_count", 0)) > host_strikes_before:
			cue_continued = true
			break
	check(cue_continued,
		"guest observed A's real host telegraph/strike cues after host flee")

	# The host is no longer in A, so it may start a separate ordinary wild B.
	# Explicitly NOT A's body: the host is still standing beside the creature it
	# just fled, so an unqualified engage stages B onto A and the "second"
	# encounter comes back with the first one's id.
	var engaged_b := await step(0, "engage_wild", {"exclude_body_id": a_body_id})
	check(str(engaged_b.get("verdict", "")) == "PASS",
		"host started a second ordinary wild fight B (%s)" % str(engaged_b.get("detail", "")))
	var b_view := await _encounter(0)
	var b_id := str(b_view.get("id", ""))
	check(not b_id.is_empty() and b_id != encounter_id,
		"B has a distinct encounter id from A (A '%s', B '%s')" % [encounter_id, b_id])
	var b_before := await _runtime(0, b_id)
	var b_hp_before := float(b_before.get("hp", -1.0))
	var b_body_id := int(b_before.get("body_instance_id", 0))
	check(bool(b_before.get("active_runtime", false)) and b_hp_before > 0.0,
		"B has its own active runtime and untouched HP (%.3f)" % b_hp_before)
	check(b_body_id > 0 and b_body_id != a_body_id,
		"B uses a distinct ordinary wild body from A (A %d, B %d)" % [a_body_id, b_body_id])
	# A's host body may have moved while its AI continued; refresh the explicit
	# per-ID pose immediately before the guest's real strike attempts.
	var a_before_guest_strike := await _runtime(0, encounter_id)
	var a_centre := _vec(a_before_guest_strike.get("body_centre", []))
	var a_hp_before_guest_strike := float(a_before_guest_strike.get("hp", -1.0))
	var a_after_guest_strike: Dictionary = a_before_guest_strike
	check(a_centre != Vector3.INF, "A runtime still exposes its real host body position")
	var b_hp_before_guest_a := float(b_before.get("hp", -1.0))
	var guest_a_hit := false
	for _guest_swing in 3:
		var a_attempt := await _runtime(0, encounter_id)
		a_centre = _vec(a_attempt.get("body_centre", []))
		var a_hp_before_attempt := float(a_attempt.get("hp", -1.0))
		check(a_centre != Vector3.INF,
			"A exposes a fresh host body centre for guest swing %d" % (_guest_swing + 1))
		var guest_a_place := await step(1, "place_creature",
			{"at": [a_centre.x - 4.5, a_centre.y, a_centre.z],
			 "face": [a_centre.x, a_centre.y, a_centre.z], "settle": PLACE_SETTLE})
		check(str(guest_a_place.get("verdict", "")) == "PASS",
			"guest positioned against A after the host fled (%s)" % str(guest_a_place.get("detail", "")))
		# Use the player's ordinary combat input here. CombatManager aims at the
		# currently rendered proxy at wind-up time, so a moving authority body
		# cannot cross behind a cardinal direction captured before placement.
		var guest_a_strike := await step(1, "press", {"action": "combat_quick"})
		check(str(guest_a_strike.get("verdict", "")) == "PASS",
			"guest swung at A while host was in B (%s)" % str(guest_a_strike.get("detail", "")))
		await step(1, "wait", {"frames": 45})
		a_after_guest_strike = await _runtime(0, encounter_id)
		if float(a_after_guest_strike.get("hp", -1.0)) < a_hp_before_attempt - 0.001:
			guest_a_hit = true
			break
	check(guest_a_hit,
		"guest strike changed A's host HP after host flee (before %.3f after %.3f receipts=%s)"
			% [a_hp_before_guest_strike, float(a_after_guest_strike.get("hp", -1.0)),
			str(a_after_guest_strike.get("strike_receipts", []))])
	var b_after_guest_a := await _runtime(0, b_id)
	check(absf(float(b_after_guest_a.get("hp", -1.0)) - b_hp_before_guest_a) < 0.001,
		"guest's A strike did not change B HP while host fought B")
	var host_flee_b := await step(0, "press", {"action": "combat_run"})
	check(str(host_flee_b.get("verdict", "")) == "PASS",
		"host fled B normally before rejoining A (%s)" % str(host_flee_b.get("detail", "")))
	var b_after := {}
	for _b_done_poll in 120:
		b_after = await _runtime(0, b_id, b_body_id)
		if not bool(b_after.get("active_runtime", true)):
			break
		await step(0, "wait", {"frames": 4})
	check(not bool(b_after.get("active_runtime", true)),
		"B's last participant retirement removed its host runtime")
	check(bool((b_after.get("ambient_body", {}) as Dictionary).get("valid", false))
		and absf(float((b_after.get("ambient_body", {}) as Dictionary).get("hp", -1.0)) - b_hp_before) < 0.001,
		"B's real ambient body survived last-leave with retained HP")

	# With B fully retired and the manager inactive, the host may rejoin A. A's
	# HP must be the guest-preserved value; joining must not mint/reset it.
	var host_rejoin_a := await step(0, "join_encounter", {"encounter_id": encounter_id})
	check(str(host_rejoin_a.get("verdict", "")) == "PASS",
		"host rejoined old encounter A after retiring B (%s)" % str(host_rejoin_a.get("detail", "")))
	var a_rejoined := await _runtime(0, encounter_id)
	check(bool(a_rejoined.get("active_runtime", false))
		and int(a_rejoined.get("body_instance_id", 0)) == a_body_id
		and int(a_rejoined.get("body_generation", 0)) == int(a_after_flee.get("body_generation", -1))
		and absf(float(a_rejoined.get("hp", -1.0)) - float(a_after_guest_strike.get("hp", -1.0))) < 0.001,
		"A rejoin preserved its live HP rather than resetting it (%s)" % str(a_rejoined))
	# Joining installs CombatManager's 0.25 s input guard. Give the host real
	# physics frames to clear it before the final leave sequence; a coordinator
	# round trip is wall time and does not prove the simulation guard elapsed.
	await step(0, "wait", {"frames": 30})

	# Last-participant retirement of A: guest first, host second. The final
	# explicit runtime read proves the authority engine is disposed once nobody
	# remains; the pure host contract covers the retained HP rule independently.
	# What the GUEST thinks it is doing, read immediately before it presses.
	var guest_before_flee: Variant = await probe(1, "encounter")

	# PRESS UNTIL IT TAKES, which is what a player does and what this leg used
	# to assume away. `combat_manager.gd::begin()` arms a 0.25 s `_input_guard`
	# every time a manager binds a fight, and `_process` skips
	# `_read_player_input()` entirely while that guard is up. `_flee_pressed()`
	# reads `Input.is_action_just_pressed`, an EDGE -- so a single injected
	# press that landed inside a guard window used to be GONE. The manager now
	# buffers a Run seen while input is unread (guard, hitstop) for
	# `flow.flee_buffer`; the retry below stays as a player's natural re-press.
	#
	# Measured: this leg failed roughly one run in two, locally and in CI, and
	# the instrumented failure showed the guest bound to the right encounter
	# with `fighting: true` while the host ledger still listed it as a
	# participant sixty polls later. The press was injected into a guarded
	# frame and swallowed. A real player whose disengage does not register
	# presses again; nothing about the rule under test says it must land on the
	# first frame it is offered.
	#
	# The assertion is unchanged and un-relaxed: the guest's withdrawal must
	# still reach the host ledger before the host's final leave. Only the
	# assumption that one edge survives an arbitrary guard window is dropped.
	var guest_flee_a := {}
	var guest_leave_settled := {}
	var guest_left_runtime := false
	var guest_flee_presses := 0
	for _guest_flee_attempt in 12:
		guest_flee_a = await step(1, "press", {"action": "combat_run"})
		if str(guest_flee_a.get("verdict", "")) != "PASS":
			break
		guest_flee_presses += 1
		for _guest_leave_poll in 10:
			guest_leave_settled = await _runtime(0, encounter_id, a_body_id)
			var settled_participants: Array[int] = []
			for raw_peer: Variant in (guest_leave_settled.get("participants", []) as Array):
				settled_participants.append(int(raw_peer))
			if bool(guest_leave_settled.get("active_runtime", false)) \
					and settled_participants.size() == 1 and settled_participants.has(host_peer_id) \
					and not settled_participants.has(guest_peer_id):
				guest_left_runtime = true
				break
			await step(0, "wait", {"frames": 2})
		if guest_left_runtime:
			break
	check(str(guest_flee_a.get("verdict", "")) == "PASS",
		"guest withdrew from rejoined A (%s)" % str(guest_flee_a.get("detail", "")))
	check(guest_left_runtime,
		"guest final withdrawal reached host ledger before host final leave after %d press(es) (guest saw %s) (%s)"
			% [guest_flee_presses, str(guest_before_flee), str(guest_leave_settled)])
	var host_flee_a_last := await step(0, "press", {"action": "combat_run"})
	check(str(host_flee_a_last.get("verdict", "")) == "PASS",
		"host withdrew as A's last participant (%s)" % str(host_flee_a_last.get("detail", "")))
	var a_hp_before_last_leave := float(a_rejoined.get("hp", -1.0))
	var a_done := {}
	for _a_done_poll in 120:
		a_done = await _runtime(0, encounter_id, a_body_id)
		if not bool(a_done.get("active_runtime", true)):
			break
		await step(0, "wait", {"frames": 4})
	check(not bool(a_done.get("active_runtime", true)),
		"A's last-participant withdrawal removed its host runtime (%s)" % str(a_done))
	check(bool((a_done.get("ambient_body", {}) as Dictionary).get("valid", false))
		and absf(float((a_done.get("ambient_body", {}) as Dictionary).get("hp", -1.0)) - a_hp_before_last_leave) < 0.001,
		"A's real ambient body survived final last-leave with retained HP")

	quit(await finish())


## This peer's view of the fight, from `tools/net/peer_runner.gd`'s `encounter`
## probe: the record it is rendering, its own creature, and the last refusal it
## was given.
func _encounter(peer: int) -> Dictionary:
	var value = await probe(peer, "encounter")
	return value if value is Dictionary else {}


func _runtime(peer: int, encounter_id: String, ambient_instance_id: int = 0) -> Dictionary:
	var value = await probe(peer, "encounter", {"encounter_id": encounter_id,
		"ambient_instance_id": ambient_instance_id})
	if not (value is Dictionary):
		return {}
	var row: Dictionary = value.get("requested_runtime", {}) as Dictionary
	if value.has("ambient_body"):
		row["ambient_body"] = value.get("ambient_body")
	return row


func _host_authority(peer_id: int) -> Dictionary:
	var state := await _encounter(0)
	for raw: Variant in (state.get("strike_authority", []) as Array):
		if raw is Dictionary and int((raw as Dictionary).get("peer_id", 0)) == peer_id:
			var out := (raw as Dictionary).duplicate(true)
			out["host_now_ms"] = int(state.get("host_now_ms", 0))
			return out
	return {"peer_id": peer_id, "last_action": 0, "accepted_at_ms": 0,
		"deadline_ms": 0, "cooldown_ms": 0, "host_now_ms": int(state.get("host_now_ms", 0))}


## Find only the host receipt that can answer this submission. Encounter, peer
## and action exclude any older action's row; host time excludes a same-numbered
## row retained from before this phase's pre-submit probe.
func _host_strike_receipt(state: Dictionary, wanted_encounter: String, peer_id: int,
		action: int, not_before_ms: int) -> Dictionary:
	for raw: Variant in (state.get("host_strike_receipts", []) as Array):
		if not (raw is Dictionary):
			continue
		var receipt: Dictionary = raw
		if str(receipt.get("encounter_id", "")) != wanted_encounter \
				or int(receipt.get("peer_id", 0)) != peer_id \
				or int(receipt.get("action", 0)) != action \
				or int(receipt.get("host_now_ms", -1)) < not_before_ms:
			continue
		return receipt.duplicate(true)
	return {}


func _strike_candidate(receipt: Dictionary, owner_peer_id: int, role: String) -> Dictionary:
	for raw: Variant in (receipt.get("candidates", []) as Array):
		if raw is Dictionary and int((raw as Dictionary).get("owner_peer_id", 0)) == owner_peer_id \
				and str((raw as Dictionary).get("role", "")) == role:
			return (raw as Dictionary).duplicate(true)
	return {}


## JSON object keys are strings even when the host record used an integer ENet
## peer id, so accept either representation without changing the probe shape.
func _struck_count(state: Dictionary, peer_id: int) -> int:
	var counts: Dictionary = state.get("struck_counts", {}) as Dictionary
	if counts.has(peer_id):
		return int(counts[peer_id])
	return int(counts.get(str(peer_id), 0))


func _await_host_action(peer_id: int, action: int) -> Dictionary:
	var last: Dictionary = {}
	for poll in REFUSAL_POLLS:
		last = await _host_authority(peer_id)
		if int(last.get("last_action", 0)) == action:
			return last
	return last


func _await_host_action_ready(peer_id: int) -> Dictionary:
	var last: Dictionary = {}
	for poll in REFUSAL_POLLS:
		last = await _host_authority(peer_id)
		if int(last.get("host_now_ms", 0)) >= int(last.get("deadline_ms", 0)):
			return last
	return last


func _await_refusal(code: String) -> Dictionary:
	var last: Dictionary = {}
	for poll in REFUSAL_POLLS:
		last = ((await _encounter(1)).get("refusal", {}) as Dictionary)
		if str(last.get("code", "")) == code:
			return last
	return last


## An `[x, y, z]` from a probe. `Vector3.INF` when the field is missing, so
## "the record said nothing" is distinguishable from "the origin".
static func _vec(value: Variant) -> Vector3:
	if not (value is Array) or (value as Array).size() != 3:
		return Vector3.INF
	var a: Array = value
	return Vector3(float(a[0]), float(a[1]), float(a[2]))
