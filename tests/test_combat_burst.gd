extends "res://tests/test_case.gd"

const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const BODY := preload("res://scripts/creatures/creature_body.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const HOST := preload("res://scripts/net/encounter_host.gd")
const DIRECTOR := preload("res://scripts/combat/encounter_director.gd")
const STORMWOOD_HUB := preload("res://scripts/world/stormwood_encounter_hub.gd")
const STORMWOOD_FIGHT := preload("res://scripts/combat/stormwood_hosted_trainer.gd")
const WATER_ALPHA := preload("res://scripts/combat/water_alpha.gd")


class IdleThrow extends Node:
	var busy := false
	func is_busy() -> bool:
		return busy
	func is_aiming() -> bool:
		return busy


class RecordingBody extends Node3D:
	var bursts: Array = []
	func begin_combat_burst(direction: Vector3, distance: float, duration: float,
			action: int = 0) -> bool:
		bursts.append({"direction": direction, "distance": distance,
			"duration": duration, "action": action})
		return true
	func cancel_combat_burst() -> void:
		pass


class RecordingTransport extends Node:
	var intents: Array[Dictionary] = []
	func submit(intent: Dictionary) -> Dictionary:
		intents.append(intent.duplicate(true))
		return {"ok": false, "pending": true}


class RecordingStormSession extends Node:
	var intents: Array[Dictionary] = []
	func request_stormwood_encounter(intent: Dictionary) -> void:
		intents.append(intent.duplicate(true))
	func local_peer_id() -> int:
		return 2


class RecordingDirector extends "res://scripts/combat/encounter_director.gd":
	var intents: Array[Dictionary] = []
	func _is_host() -> bool:
		return false
	func _can_encounter_rpc() -> bool:
		return true
	func _send_realm_rpc(_peer: int, _method: String, arguments: Array,
			_completing: bool = false) -> bool:
		intents.append((arguments[0] as Dictionary).duplicate(true))
		return true


func _manager_fixture() -> Dictionary:
	var manager := MANAGER.new()
	var creature: RefCounted = SPECIES.spawn("terrapup")
	creature.nourishment = 100.0
	var party: Array[RefCounted] = [creature]
	var body := RecordingBody.new()
	var throw := IdleThrow.new()
	manager.set("_party", party)
	manager.set("_active_index", 0)
	manager.set("_ally_body", body)
	manager.set("_throw", throw)
	manager.set("state", MANAGER.State.ACTIVE)
	manager.call("_initialize_wind")
	return {"manager": manager, "body": body, "throw": throw}


func _host_fixture() -> Dictionary:
	var host := HOST.new(1)
	var rec: Dictionary = host.open(2, "meadows", "wild", {
		"species_id": "bramblebun", "hp": 30.0, "hp_max": 30.0,
		"position": [5.0, 0.0, 0.0]})
	return {"host": host, "id": str(rec.encounter_id),
		"profile": {"max": 100.0, "regen_per_second": 20.0}}


func _authorize(fixture: Dictionary, action: int, now_ms: int,
		direction: Variant = [1.0, 0.0, 0.0], cost: float = 30.0) -> Dictionary:
	return fixture.host.authorize_burst(fixture.id, 2, {
		"kind": "burst_intent", "encounter_id": fixture.id,
		"action": action, "direction": direction,
	}, fixture.profile, cost, now_ms, 3.0, 0.2, 0.6)


func test_baseline_telegraph_and_burst_tuning_match_owner_decision() -> void:
	assert_true(DIRECTOR != null and STORMWOOD_HUB != null and STORMWOOD_FIGHT != null
		and WATER_ALPHA != null, "every hosted transport parses with burst authority")
	var cfg: Dictionary = MATH.config()
	assert_almost_eq(float((cfg.enemy as Dictionary).telegraph), 0.8, 0.001)
	assert_almost_eq(float((cfg.burst as Dictionary).distance), 3.0, 0.001)
	assert_almost_eq(float((cfg.burst as Dictionary).duration), 0.2, 0.001)
	assert_true(float((cfg.wind as Dictionary).burst_cost) > 0.0)
	var a_is_jump := false
	for event: InputEvent in InputMap.action_get_events("jump"):
		if event is InputEventJoypadButton \
				and (event as InputEventJoypadButton).button_index == JOY_BUTTON_A:
			a_is_jump = true
	assert_true(a_is_jump, "the pad A button reaches combat through the existing jump action")


func test_every_hosted_transport_stamps_burst_in_the_shared_action_stream() -> void:
	var ordinary := RecordingDirector.new()
	ordinary.submit_encounter_intent({"kind": "strike_intent"})
	ordinary.submit_encounter_intent({"kind": "burst_intent", "direction": [1.0, 0.0, 0.0]})
	ordinary.submit_encounter_intent({"kind": "strike_intent"})
	assert_eq(int(ordinary.intents[0].action), 1)
	assert_eq(int(ordinary.intents[1].action), 2)
	assert_eq(int(ordinary.intents[2].action), 3)
	ordinary.free()

	var water := WATER_ALPHA.new()
	var water_transport := RecordingTransport.new()
	water.transport = water_transport
	water.submit_encounter_intent({"kind": "strike_intent"})
	water.submit_encounter_intent({"kind": "burst_intent", "direction": [1.0, 0.0, 0.0]})
	water.submit_encounter_intent({"kind": "strike_intent"})
	assert_eq(int(water_transport.intents[0].action), 1)
	assert_eq(int(water_transport.intents[1].action), 2)
	assert_eq(int(water_transport.intents[2].action), 3)
	water.free()
	water_transport.free()

	var hub := STORMWOOD_HUB.new()
	var storm_session := RecordingStormSession.new()
	hub.session = storm_session
	hub.submit_encounter_intent({"kind": "strike_intent"})
	hub.submit_encounter_intent({"kind": "burst_intent", "direction": [0.0, 0.0, -1.0]})
	assert_eq(int(storm_session.intents[0].action), 1)
	assert_eq(int(storm_session.intents[1].action), 2)
	hub.free()
	storm_session.free()


func test_solo_burst_uses_direction_spends_once_and_commits_for_duration() -> void:
	var fixture := _manager_fixture()
	var manager: Node = fixture.manager
	var before := float(manager.wind_value())
	assert_true(manager.request_burst(Vector3(-2.0, 0.0, 1.0)))
	assert_eq(int(manager.get("_action")), MANAGER.Action.BURST)
	assert_almost_eq(float(manager.wind_value()), before - float(manager.wind_cost("burst")), 0.001)
	var bursts: Array = fixture.body.bursts
	assert_eq(bursts.size(), 1)
	var row: Dictionary = bursts[0]
	assert_true((row.direction as Vector3).is_equal_approx(Vector3(-2.0, 0.0, 1.0).normalized()))
	assert_almost_eq(float(row.distance), 3.0, 0.001)
	assert_almost_eq(float(row.duration), 0.2, 0.001)
	manager.call("_tick_action", 0.19)
	assert_eq(int(manager.get("_action")), MANAGER.Action.BURST)
	manager.call("_tick_action", 0.02)
	assert_eq(int(manager.get("_action")), MANAGER.Action.READY)
	manager.free()
	fixture.body.free()
	fixture.throw.free()


func test_burst_cannot_start_without_wind_or_cancel_any_committed_action() -> void:
	var fixture := _manager_fixture()
	var manager: Node = fixture.manager
	for action in [MANAGER.Action.WINDUP, MANAGER.Action.RECOVERY, MANAGER.Action.STAGGER]:
		manager.set("_action", action)
		manager.set("_pending_move", {"sentinel": action})
		assert_false(manager.request_burst(Vector3.RIGHT))
		assert_eq(int(manager.get("_action")), action)
		assert_eq(int((manager.get("_pending_move") as Dictionary).sentinel), action)
	manager.set("_action", MANAGER.Action.READY)
	fixture.throw.busy = true
	assert_false(manager.request_burst(Vector3.RIGHT), "throw/aim owns A while it is busy")
	fixture.throw.busy = false
	(manager.get("_party_wind") as Array)[0] = float(manager.wind_cost("burst")) - 0.01
	assert_false(manager.request_burst(Vector3.RIGHT), "a burst requires its full Wind cost")
	assert_eq(fixture.body.bursts.size(), 0)
	manager.free()
	fixture.body.free()
	fixture.throw.free()


func test_burst_adds_no_invulnerability_contract_or_hit_bypass() -> void:
	var body := BODY.new()
	var property_names: Array[String] = []
	for row: Dictionary in body.get_property_list():
		property_names.append(str(row.get("name", "")))
	assert_false(property_names.has("invulnerable"))
	assert_false(property_names.has("invincible"))
	assert_false(body.has_method("set_invulnerable"))
	assert_false(body.has_method("set_invincible"))
	body.free()


func test_host_normalizes_direction_spends_absolute_wind_and_replay_is_safe() -> void:
	var fixture := _host_fixture()
	var accepted := _authorize(fixture, 1, 1000, [4.0, 99.0, 0.0])
	assert_true(bool(accepted.ok))
	assert_eq(accepted.kind, "burst_intent")
	assert_eq((accepted.delta as Dictionary).direction, [1.0, 0.0, 0.0])
	assert_almost_eq(float(accepted.delta.wind), 70.0, 0.001)
	assert_eq(int(accepted.delta.accepted_action), 1)
	var replay := _authorize(fixture, 1, 2000)
	assert_false(bool(replay.ok))
	assert_eq(str(replay.code), "replayed_action")
	assert_true(float(replay.delta.wind) >= 70.0,
		"replay can observe host-clock regen but cannot spend Wind twice")


func test_host_refuses_insufficient_wind_and_malformed_direction() -> void:
	var fixture := _host_fixture()
	var tired := _authorize(fixture, 1, 1000, [1.0, 0.0, 0.0], 101.0)
	assert_false(bool(tired.ok))
	assert_eq(str(tired.code), "insufficient_wind")
	assert_almost_eq(float(tired.delta.wind), 100.0, 0.001)
	for bad in [[], [0.0, 0.0, 0.0], ["east", 0.0, 0.0], [NAN, 0.0, 1.0]]:
		var refused := _authorize(fixture, 2, 1000, bad)
		assert_false(bool(refused.ok))
		assert_eq(str(refused.code), "malformed")


func test_burst_and_strike_share_one_monotonic_action_lock() -> void:
	var fixture := _host_fixture()
	assert_true(bool(_authorize(fixture, 5, 1000).ok))
	var strike := {"kind": "strike_intent", "encounter_id": fixture.id,
		"action": 6, "move": {"range": 2.6, "cone_degrees": 90.0,
			"cooldown": 0.4, "windup": 0.18, "recovery": 0.22},
		"facing": Vector3.RIGHT}
	var cooling: Dictionary = fixture.host.validate_strike(strike, 2,
		{"now_ms": 1199, "origin": Vector3.ZERO, "bodies": []})
	assert_false(bool(cooling.ok))
	assert_eq(str(cooling.code), "cooldown")
	var accepted: Dictionary = fixture.host.validate_strike(strike, 2,
		{"now_ms": 1200, "origin": Vector3.ZERO, "bodies": []})
	assert_true(bool(accepted.ok))
	var replayed_burst := _authorize(fixture, 5, 2000)
	assert_false(bool(replayed_burst.ok))
	assert_eq(str(replayed_burst.code), "replayed_action")

	var second := _host_fixture()
	var first_strike := strike.duplicate(true)
	first_strike.encounter_id = second.id
	first_strike.action = 10
	assert_true(bool((second.host.validate_strike(first_strike, 2,
		{"now_ms": 5000, "origin": Vector3.ZERO, "bodies": []}) as Dictionary).ok))
	var burst_during_attack := _authorize(second, 11, 5199)
	assert_false(bool(burst_during_attack.ok))
	assert_eq(str(burst_during_attack.code), "cooldown")
