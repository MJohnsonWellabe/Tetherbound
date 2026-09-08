extends "res://tests/smoke_net_stormwood_hosted_trainers.gd"

# peers: 2

## Focused two-process proof that a remote Stormwood player's personal Spark
## selection reaches the host-owned trainer timer without becoming a per-swing
## number. The ordinary hosted-trainer smoke owns roster/reward completion;
## this one stops after comparing the same charged move under inactive,
## Livewire, and released states.

const SPARK_EARNED := "realm_heart_stormwood_earned"
const SPARK_PLACED := "realm_heart_stormwood_placed"
const EARLY_TARGET_MS := 350
const EARLY_MINIMUM_MS := 180
const ELAPSED_MARGIN_MS := 60
const REJECTION_DELIVERY_MARGIN_MS := 250


func _initialize() -> void:
	_run_livewire()


func _run_livewire() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return
	var hosted := await step(0, "host")
	check(str(hosted.get("verdict", "")) == "PASS", "peer 0 started the real listen host")
	if str(hosted.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	var session: Dictionary = await _session(0)
	var joined := await step(1, "join", {
		"host": "127.0.0.1", "port": int(session.get("enet_port", 0)),
	})
	check(str(joined.get("verdict", "")) == "PASS", "peer 1 joined peer 0")
	if str(joined.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	var client_session := await _session(1)
	_client_peer_id = int(client_session.get("peer_id", 0))
	check(_client_peer_id > 0 and _client_peer_id != int(session.get("peer_id", 0)),
		"client has a distinct real ENet peer id")

	for flag in [STORMWOOD_KEY, STORMWOOD_GATE]:
		var granted := await step(0, "story_flag", {"flag": flag, "scope": "world"})
		check(str(granted.get("verdict", "")) == "PASS",
			"host committed Stormwood prerequisite '%s'" % flag)
		for peer in 2:
			var seen := await step(peer, "wait_flag", {"flag": flag})
			check(str(seen.get("verdict", "")) == "PASS",
				"peer %d received '%s'" % [peer, flag])

	var entered := await step(1, "enter_realm", {"realm": STORMWOOD}, REALM_STEP_BUDGET)
	check(str(entered.get("verdict", "")) == "PASS", "client entered Stormwood")
	if str(entered.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	var shells := await _await_stormwood_shell()
	var storm: Dictionary = ((shells.get("realms", {}) as Dictionary).get(STORMWOOD, {})) as Dictionary
	check(bool(storm.get("ready", false)), "host Stormwood simulation shell is ready")
	var runtime := await _await_client_stormwood_runtime()
	check(bool(runtime.get("available", false)), "client Stormwood combat runtime is ready")
	if not bool(runtime.get("available", false)):
		quit(await finish())
		return

	# The Spark is one shared placed fact, while its active selection remains
	# this client's. Keep it inactive for the first timing measurement.
	var bound := await step(1, "heart_bind", {
		"heart": "stormwood", "name": "Spark of the Stormwood", "realm": STORMWOOD,
	})
	check(str(bound.get("verdict", "")) == "PASS", "client bound the real Stormwood shrine")
	var earned := await step(0, "heart_earn", {"heart": "stormwood", "realm": STORMWOOD})
	check(str(earned.get("verdict", "")) == "PASS", "host earned the Spark through the ledger")
	for peer in 2:
		var seen := await step(peer, "wait_flag", {"flag": SPARK_EARNED, "scope": "world"})
		check(str(seen.get("verdict", "")) == "PASS", "peer %d sees the earned Spark" % peer)
	var placed := await step(1, "heart_place")
	check(str(placed.get("verdict", "")) == "PASS", "client placed the Spark through the shrine")
	for peer in 2:
		var seen := await step(peer, "wait_flag", {"flag": SPARK_PLACED, "scope": "world"})
		check(str(seen.get("verdict", "")) == "PASS", "peer %d sees the placed Spark" % peer)
	var inactive: Variant = await probe(1, "realm_heart", {"heart": "stormwood"})
	check(inactive is Dictionary and str((inactive as Dictionary).get("active", "")).is_empty(),
		"the Spark starts placed but personally inactive")

	# Sparkit's Arc Lash commits for 0.90 s while the authored charged cooldown
	# is 1.20 s. That leaves a clean timing window: at 1.00 s Livewire is ready
	# and the inactive/released baseline is not.
	var party_seeded := await step(1, "party_grant", {"species": "sparkit", "level": 33})
	check(str(party_seeded.get("verdict", "")) == "PASS", "client owns a chapter-ready creature")
	var deployed := await step(1, "deploy_creature", {"species": "sparkit"})
	check(str(deployed.get("verdict", "")) == "PASS", "client deployed before choosing Livewire")
	var prepared := await step(1, "stormwood_hosted_start", {
		"trainer": TRAINER, "prepare_only": true,
	})
	check(str(prepared.get("verdict", "")) == "PASS", "client prepared beside Tamsin")
	if str(prepared.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	var prepared_data: Dictionary = prepared.get("data", {}) as Dictionary
	var client_actor_at := _vec(prepared_data.get("client_actor_pos", []))
	var client_trainer_at := _vec(prepared_data.get("client_trainer_pos", []))
	var client_challenge_distance := client_actor_at.distance_to(client_trainer_at) \
		if client_actor_at != Vector3.INF and client_trainer_at != Vector3.INF else INF
	check(client_challenge_distance <= CHALLENGE_RADIUS_M,
		("settled client actor is inside Tamsin's %.1fm production challenge radius: "
		+ "actor=%s trainer=%s distance=%.2f") % [CHALLENGE_RADIUS_M,
			str(client_actor_at), str(client_trainer_at), client_challenge_distance])
	if client_challenge_distance > CHALLENGE_RADIUS_M:
		quit(await finish())
		return
	var admitted := await _await_host_actor_ready(client_actor_at)
	var host_actor_at := _vec(admitted.get("host_actor_pos", []))
	var host_trainer_at := _vec(admitted.get("trainer_pos", []))
	var replication_error := host_actor_at.distance_to(client_actor_at) \
		if host_actor_at != Vector3.INF and client_actor_at != Vector3.INF else INF
	var host_challenge_distance := host_actor_at.distance_to(host_trainer_at) \
		if host_actor_at != Vector3.INF and host_trainer_at != Vector3.INF else INF
	check(replication_error <= ACTOR_REPLICATION_M,
		("host shell mirrors the settled client actor within %.1fm: client=%s host=%s error=%.2f")
			% [ACTOR_REPLICATION_M, str(client_actor_at), str(host_actor_at), replication_error])
	check(host_challenge_distance <= CHALLENGE_RADIUS_M,
		("host actor is independently inside Tamsin's %.1fm production challenge radius: "
		+ "actor=%s trainer=%s distance=%.2f") % [CHALLENGE_RADIUS_M,
			str(host_actor_at), str(host_trainer_at), host_challenge_distance])
	if replication_error > ACTOR_REPLICATION_M or host_challenge_distance > CHALLENGE_RADIUS_M:
		quit(await finish())
		return
	var started := await step(1, "stormwood_hosted_start", {
		"trainer": TRAINER, "request_only": true,
	})
	check(str(started.get("verdict", "")) == "PASS", "remote client started host-owned Tamsin")
	var host_state := await _await_hosted(0, true)
	var client_state := await _await_hosted(1, true)
	var charged := str((client_state.get("local_card", {}) as Dictionary).get("charged", ""))
	check(not charged.is_empty(), "the deployed card has an authored charged move")
	# Keep one real opponent alive across all three timing comparisons. This
	# timing fixture keeps the target stationary as well: movement during the
	# network staging round trip otherwise produces legitimate accepted misses.
	# Every strike, timer, hit check and verdict uses production authority.
	# The ordinary hosted-trainer smoke retains the moving enemy AI coverage.
	var health := await step(0, "stormwood_hosted_fixture_health", {
		"trainer": TRAINER, "hp": 100000.0, "stationary_target": true,
	})
	check(str(health.get("verdict", "")) == "PASS", "fixture kept one hosted round alive")
	host_state = await _await_hosted(0, true)
	var aimed := await _stage_client_for_current_opponent()
	check(str(aimed.get("verdict", "")) == "PASS", "client and host agree on strike geometry")
	if str(aimed.get("verdict", "")) != "PASS" or charged.is_empty():
		quit(await finish())
		return

	# Inactive: anchor every assertion to the host's own accepted action and
	# deadline. Coordinator polling can take arbitrary time without changing
	# whether the next intent arrived before or after that deadline.
	var first := await _charged(801, charged, host_state, 2)
	check(str(first.get("verdict", "")) == "PASS", "sent the first inactive charged action")
	var after_first := await _await_host_action(801)
	check(_hp(after_first) < _hp(host_state), "host accepted the inactive baseline strike")
	var inactive_authority := _authority(after_first)
	check(str(inactive_authority.get("active_relic_id", "")).is_empty()
		and is_equal_approx(float(inactive_authority.get("cooldown_multiplier", -1.0)), 1.0),
		"host resolved the placed-but-inactive Spark to the authored cooldown")
	var before_inactive_deadline := await _await_before_host_deadline(
		int(inactive_authority.get("deadline_ms", 0)))
	check(_safe_early(before_inactive_deadline),
		"coordinator reached a safe pre-deadline window on the host clock")
	var early := await _charged(802, charged, after_first, 8)
	check(str(early.get("verdict", "")) == "PASS", "sent a fresh pre-cooldown action")
	var after_early := await _await_host_time(
		int(inactive_authority.get("deadline_ms", 0)) + REJECTION_DELIVERY_MARGIN_MS)
	check(_hp(after_early) == _hp(after_first) and _seq(after_early) == _seq(after_first),
		"default host deadline refused the fresh early action")
	check(int(_authority(after_early).get("last_accepted_action", 0)) == 801,
		"the refused early action did not advance host authority")

	# Activate while the same creature remains deployed. EncounterDirector sees
	# RealmHeartState.revision and refreshes the existing deployment card; the
	# host derives 0.75 from its own placed Spark data.
	await _await_after_host_deadline(int(inactive_authority.get("deadline_ms", 0)))
	if not await _restage_for_strike("elapsed baseline"):
		quit(await finish())
		return
	var baseline_ready := await _charged(803, charged, after_early, 2)
	check(str(baseline_ready.get("verdict", "")) == "PASS", "sent the elapsed baseline action")
	var after_baseline := await _await_host_action(803)
	check(_hp(after_baseline) < _hp(after_early), "default cooldown accepts after 1.2 s")
	var activated := await step(1, "heart_activate", {"heart": "stormwood"})
	check(str(activated.get("verdict", "")) == "PASS", "client personally activated Livewire")
	var livewire_ready := await _await_host_relic("stormwood", 0.75)
	check(str(_authority(livewire_ready).get("active_relic_id", "")) == "stormwood"
		and is_equal_approx(float(_authority(livewire_ready).get("cooldown_multiplier", 0.0)), 0.75),
		"host received the refreshed Spark identity and resolved its own 0.75 value")
	await _await_after_host_deadline(int(_authority(after_baseline).get("deadline_ms", 0)))
	if not await _restage_for_strike("first Livewire"):
		quit(await finish())
		return
	var livewire_first := await _charged(804, charged, after_baseline, 2)
	check(str(livewire_first.get("verdict", "")) == "PASS", "sent the first Livewire action")
	var after_livewire_first := await _await_host_action(804)
	check(_hp(after_livewire_first) < _hp(after_baseline), "the first Livewire action landed")
	var livewire_authority := _authority(after_livewire_first)
	check(str(livewire_authority.get("active_relic_id", "")) == "stormwood"
		and is_equal_approx(float(livewire_authority.get("cooldown_multiplier", 0.0)), 0.75),
		"the accepted action records the host-resolved Livewire state")
	await _await_after_host_deadline(int(livewire_authority.get("deadline_ms", 0)))
	if not await _restage_for_strike("second Livewire"):
		quit(await finish())
		return
	var livewire := await _charged(805, charged, after_livewire_first, 8)
	check(str(livewire.get("verdict", "")) == "PASS", "sent a fresh Livewire action")
	var after_livewire := await _await_host_action(805)
	check(_hp(after_livewire) < _hp(after_livewire_first),
		"host accepted the same charged move after its validated Livewire deadline (%s)"
			% _geometry_detail(after_livewire.get("charged_geometry", {}) as Dictionary))

	# Releasing the one active relic refreshes the card again and restores the
	# authored timer; a stale action id remains covered by the ordinary hosted
	# trainer smoke, so this uses another fresh id.
	var released := await step(1, "heart_activate", {"heart": "stormwood", "release": true})
	check(str(released.get("verdict", "")) == "PASS", "client released Livewire")
	var released_ready := await _await_host_relic("", 1.0)
	check(str(_authority(released_ready).get("active_relic_id", "")).is_empty()
		and is_equal_approx(float(_authority(released_ready).get("cooldown_multiplier", 0.0)), 1.0),
		"host saw the release and restored its authored multiplier")
	await _await_after_host_deadline(int(_authority(after_livewire).get("deadline_ms", 0)))
	if not await _restage_for_strike("released baseline"):
		quit(await finish())
		return
	var release_first := await _charged(806, charged, after_livewire, 2)
	check(str(release_first.get("verdict", "")) == "PASS", "sent a baseline action after release")
	var after_release_first := await _await_host_action(806)
	check(_hp(after_release_first) < _hp(after_livewire), "released baseline action landed")
	var release_authority := _authority(after_release_first)
	var before_release_deadline := await _await_before_host_deadline(
		int(release_authority.get("deadline_ms", 0)))
	check(_safe_early(before_release_deadline),
		"released baseline reached a safe pre-deadline host window")
	var release_early := await _charged(807, charged, after_release_first, 8)
	check(str(release_early.get("verdict", "")) == "PASS", "sent a fresh action after release")
	var after_release_early := await _await_host_time(
		int(release_authority.get("deadline_ms", 0)) + REJECTION_DELIVERY_MARGIN_MS)
	check(_hp(after_release_early) == _hp(after_release_first)
		and _seq(after_release_early) == _seq(after_release_first),
		"releasing Livewire restored the host's authored deadline refusal")
	check(int(_authority(after_release_early).get("last_accepted_action", 0)) == 806,
		"the released early action did not advance host authority")

	quit(await finish())


func _restage_for_strike(label: String) -> bool:
	# The host-owned opponent keeps moving while the smoke waits on cooldown
	# deadlines and relic replication.  Reconcile both real bodies immediately
	# before an action expected to land so this timing proof cannot turn into an
	# unrelated cone/position miss.
	var aimed := await _stage_client_for_current_opponent()
	check(str(aimed.get("verdict", "")) == "PASS",
		"%s strike geometry is current on client and host" % label)
	if str(aimed.get("verdict", "")) != "PASS":
		return false
	# Position convergence alone did not prove a hit: two CI runs accepted action
	# 805 while leaving HP unchanged.  Wait for the HOST's actual charged profile
	# to connect against its current body centre, facing, and opponent centre.
	# This is read-only; action/cooldown authority still advances only when the
	# subsequent raw strike traverses Session and the production hosted fight.
	var current := await _await_host_charged_geometry()
	var geometry: Dictionary = current.get("charged_geometry", {}) as Dictionary
	var connects := bool(geometry.get("connects", false))
	check(connects, "%s host charged cone is live (%s)" % [label, _geometry_detail(geometry)])
	return connects


func _await_host_charged_geometry() -> Dictionary:
	var last: Dictionary = {}
	for tick in 180:
		var raw: Variant = await probe(0, "stormwood_hosted_trainer", {
			"trainer": TRAINER, "peer": _client_peer_id,
		})
		last = raw as Dictionary if raw is Dictionary else {}
		var geometry: Dictionary = last.get("charged_geometry", {}) as Dictionary
		if bool(geometry.get("available", false)) and bool(geometry.get("connects", false)):
			return last
		await step(0, "wait", {"frames": 1})
	return last


static func _geometry_detail(geometry: Dictionary) -> String:
	if not bool(geometry.get("available", false)):
		return "unavailable: %s" % str(geometry.get("reason", "no reason"))
	return "distance=%.3fm/%.3fm angle=%.2fdeg/%.2fdeg origin=%s facing=%s target=%s" % [
		float(geometry.get("distance_m", INF)), float(geometry.get("range_m", 0.0)),
		float(geometry.get("angle_degrees", INF)),
		float(geometry.get("cone_degrees", 0.0)) * 0.5,
		str(geometry.get("origin", [])), str(geometry.get("facing", [])),
		str(geometry.get("target", [])),
	]


func _charged(action: int, move_id: String, state: Dictionary, settle: int) -> Dictionary:
	return await step(1, "stormwood_hosted_raw_strike", {
		"trainer": TRAINER,
		"encounter_id": str((state.get("record", {}) as Dictionary).get("id", "")),
		"slot": "charged", "move_id": move_id, "action": action,
		"realm": STORMWOOD, "damage": 999999.0, "settle": settle,
	})


func _await_host_action(action: int) -> Dictionary:
	var last: Dictionary = {}
	for tick in 180:
		var raw: Variant = await probe(0, "stormwood_hosted_trainer", {
			"trainer": TRAINER, "peer": _client_peer_id,
		})
		last = raw as Dictionary if raw is Dictionary else {}
		if int(_authority(last).get("last_accepted_action", 0)) == action:
			return last
		await step(0, "wait", {"frames": 1})
	return last


func _await_host_relic(relic_id: String, multiplier: float) -> Dictionary:
	var last: Dictionary = {}
	for tick in 180:
		var raw: Variant = await probe(0, "stormwood_hosted_trainer", {
			"trainer": TRAINER, "peer": _client_peer_id,
		})
		last = raw as Dictionary if raw is Dictionary else {}
		var authority := _authority(last)
		if str(authority.get("active_relic_id", "")) == relic_id \
				and is_equal_approx(float(authority.get("cooldown_multiplier", -1.0)), multiplier):
			return last
		await step(0, "wait", {"frames": 1})
	return last


func _await_before_host_deadline(deadline_ms: int) -> Dictionary:
	var last: Dictionary = {}
	for tick in 180:
		var raw: Variant = await probe(0, "stormwood_hosted_trainer", {
			"trainer": TRAINER, "peer": _client_peer_id,
		})
		last = raw as Dictionary if raw is Dictionary else {}
		var remaining := deadline_ms - int(_authority(last).get("host_now_ms", 0))
		if remaining <= EARLY_TARGET_MS:
			return last
		await step(0, "wait", {"frames": 1})
	return last


func _await_after_host_deadline(deadline_ms: int) -> Dictionary:
	return await _await_host_time(deadline_ms + ELAPSED_MARGIN_MS)


func _await_host_time(wanted_ms: int) -> Dictionary:
	var last: Dictionary = {}
	for tick in 180:
		var raw: Variant = await probe(0, "stormwood_hosted_trainer", {
			"trainer": TRAINER, "peer": _client_peer_id,
		})
		last = raw as Dictionary if raw is Dictionary else {}
		if int(_authority(last).get("host_now_ms", 0)) >= wanted_ms:
			return last
		await step(0, "wait", {"frames": 1})
	return last


static func _authority(state: Dictionary) -> Dictionary:
	return state.get("host_authority", {}) as Dictionary


static func _safe_early(state: Dictionary) -> bool:
	var authority := _authority(state)
	var remaining := int(authority.get("deadline_ms", 0)) \
		- int(authority.get("host_now_ms", 0))
	return remaining >= EARLY_MINIMUM_MS and remaining <= EARLY_TARGET_MS
