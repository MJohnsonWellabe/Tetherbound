extends "res://tests/test_move_commit_runtime.gd"

const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const MASTERY := preload("res://scripts/creatures/move_mastery.gd")
const MOVES := preload("res://scripts/creatures/move_db.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const WILD := preload("res://scripts/creatures/wild_creature.gd")
const ULTIMATES := preload("res://scripts/vfx/ultimates/ultimate_library.gd")
const UTILITY := preload("res://scripts/combat/utility_effects.gd")

func test_current_wild_actor_scope_fences_moves_and_switch_without_round_rewards() -> void:
	# Detached actual Director/Manager, using the existing saved-resource Game
	# and Session fixtures. This exercises the guest record consumer only;
	# mounted host damage/heal and two-peer runtime remain separate proofs.
	var saved := preload("res://tests/test_foundation_resource_save.gd")
	var game := saved.FixtureGame.new()
	game.world = preload("res://autoload/world_state.gd").new()
	game.world.reward_delivery_namespace = "wild-health-world"
	var session := saved.FixtureSession.new()
	session.fixture = game
	game.session = session
	var director := preload("res://scripts/combat/encounter_director.gd").new()
	director.set("_session", session)
	director.set("_encounter_host", host)
	var record: Dictionary = host.record(id)
	record["wild_actor_owner"] = preload("res://scripts/net/wild_actor_scope.gd").make(
		game.world.reward_delivery_namespace, session._altar_current_epoch(), "meadows", id)
	record["ordinary_actor_vitals_pending"] = true
	director.set("_encounter", record)
	assert_true(director.uses_wild_actor_vitals(id))
	assert_true(director.uses_saved_actor_vitals(id))
	assert_false(director.uses_durable_trainer_rewards(id), "wild HP never installs trainer round rewards")
	assert_true(director.ordinary_actor_vitals_pending(id))
	for kind: String in ["move_start", "strike_intent", "burst_intent", "tether_command", "disengage"]:
		var refused: Dictionary = director._host_commit_encounter({"kind": kind, "encounter_id": id}, 1)
		assert_eq(refused.code, "pending_vitals", kind)
	var manager := MANAGER.new()
	manager.set("_encounter_link", director)
	manager.set("_encounter_id", id)
	var switch_refusals: Array[String] = []
	manager.encounter_refused.connect(func(_code: String, reason: String) -> void: switch_refusals.append(reason))
	assert_true(manager._saved_actor_vitals_owned())
	assert_false(manager._durable_trainer_reward_owned())
	assert_false(manager.request_switch(1), "wild hold reaches actual Manager switch guard")
	assert_eq(switch_refusals, ["The original health change is still being saved."])
	record.ordinary_actor_vitals_pending = false
	assert_false(director.ordinary_actor_vitals_pending(id), "exact saved broadcast releases hold")
	for field: String in ["world_namespace", "session_id", "encounter_id", "realm"]:
		var original: Dictionary = record.wild_actor_owner.duplicate(true)
		record.wild_actor_owner[field] = "foreign"
		assert_false(director.uses_saved_actor_vitals(id), field)
		assert_false(manager._saved_actor_vitals_owned(), field)
		record.wild_actor_owner = original
	assert_false(director.uses_saved_actor_vitals("foreign-encounter"))
	game.world = null
	assert_false(director.uses_saved_actor_vitals(id), "teardown cannot retain an authoritative health scope")
	manager.free()
	director.free()
	session.free()
	game.free()

func test_frozen_heal_keeps_actual_profile_uid_resources_and_self_mastery_receipt() -> void:
	for uses: int in [0, 25, 75, 150, 300]:
		var heal_host := HOST.new(1)
		var owned := _new_owned()
		owned.hp = 50.0
		owned["max_hp"] = 100.0
		owned.move_utility = "heal_pulse"
		owned.known_moves.append("heal_pulse")
		owned.move_mastery_uses["heal_pulse"] = uses
		var record: Dictionary = heal_host.open(1, "meadows", "wild", {"hp": 200.0}, owned.uid, "owner_a")
		var heal_id := str(record.encounter_id)
		var body := Node.new()
		assert_true(heal_host.bind_actor_body(heal_id, 1, "owner_a", owned, body.get_instance_id()).ok)
		var binding := _binding()
		binding.body_instance_id = body.get_instance_id()
		binding.actor_generation = 1
		var frozen := MASTERY.freeze_action(MASTERY.owned_record(owned), "utility",
			{"character_id": "owner_a", "creature_uid": owned.uid, "encounter_id": heal_id, "generation": 1, "action": 1}, [], MOVES.load_default())
		assert_true(frozen.ok)
		var move := MANAGER.host_move_profile(MOVES.load_default(), "player_utility", "heal_pulse", 0.5, 0.5, 1.0, 0.0, frozen.move)
		move["mastery_context"] = {"world_namespace": "heal-world", "session_id": "heal-session"}
		var view := {"source_uid": owned.uid, "source_generation": 1, "now_ms": Time.get_ticks_msec(), "origin": Vector3.ZERO,
			"owned": owned, "binding": binding}
		var intent := {"encounter_id": heal_id, "action": 1, "slot": "utility"}
		var original := record.duplicate(true)
		assert_eq(heal_host.authorize_move_start(intent, 1, owned, binding, move, WIND, int(view.now_ms)).code, "canonical_heal_required")
		assert_eq(record, original, "normal start cannot authorize a self-heal as a hostile arrival")
		var bundle: Dictionary = heal_host.stage_actor_heal_utility(intent, 1, view, "heal_pulse", WIND, 16, move)
		assert_true(bundle.ok, str(bundle))
		if not bundle.ok:
			body.free()
			continue
		assert_eq(record, original, "discarded world stage has no HP/Wind/action mutation")
		assert_eq(bundle.effect.receipt.action_id, move.action_id)
		assert_eq(bundle.frozen_move.mastery_rank, MASTERY.rank_from_uses(uses))
		assert_eq(bundle.frozen_move.vfx.effect_tier, MASTERY.rank_from_uses(uses))
		assert_eq(bundle.authority.move_starts["1"].binding, binding)
		assert_eq(bundle.verdict.delta.utility_cooldown_s, move.cooldown, "retained projection uses accepted clock, not changing current ticks")
		assert_eq(heal_host.stage_actor_heal_utility(intent, 1, bundle.view, "heal_pulse", WIND, 16, move), bundle,
			"complete staged resources/deadlines/verdict recheck exactly while cooldown is positive")
		assert_almost_eq(bundle.vitals_proposal.hp_after, 62.0)
		var forged := bundle.duplicate(true)
		forged.effect.receipt.hp_after = 99.0
		assert_false(heal_host.commit_actor_heal_utility(forged).ok, "changed prepared effect cannot commit")
		assert_eq(record, original)
		var committed: Dictionary = heal_host.commit_actor_heal_utility(bundle)
		assert_true(committed.ok, str(committed))
		if not committed.ok:
			body.free()
			continue
		assert_almost_eq(heal_host.actor_vitals(heal_id, 1, owned.uid, 1).hp, 62.0)
		var resources: Dictionary = heal_host.move_resource_snapshot(heal_id, 1, owned.uid)
		assert_eq(resources.wind, 76.0)
		assert_eq(resources.energy, 0.0)
		assert_eq(resources.ultimate_meter, 0.0)
		assert_eq(record.opponent, original.opponent, "self heal never changes opponent HP/poise or any opponent field")
		var started: Dictionary = heal_host.move_commit(heal_id, 1, 1)
		assert_true(started.resolved and started.credited)
		var expected_move := move.duplicate(true)
		expected_move["wind_exhausted"] = false
		assert_eq(started.move, expected_move)
		var outcome: Dictionary = heal_host.move_mastery_outcome(heal_id, 1, 1)
		if uses < 300:
			assert_true(preload("res://scripts/net/foundation_event.gd").valid_effect_mastery(outcome.outcome, heal_id))
			assert_eq(outcome.context, move.mastery_context)
			assert_eq(outcome.outcome.effect_receipt, bundle.effect.receipt)
		else: assert_true(outcome.is_empty(), "rank five saturates without another journal obligation")
		var after := record.duplicate(true)
		assert_false(heal_host.commit_actor_heal_utility(bundle).ok)
		assert_eq(record, after, "same original cannot heal/spend/credit again")
		body.free()

class TapManager extends "res://scripts/combat/combat_manager.gd":
	var arm_edge := false
	var arm_held := false
	var face_held := false
	var face_edge := ""
	var refusals: Array[String] = []
	var resolved_strikes := 0
	func _resolve_player_strike() -> void: resolved_strikes += 1
	func _ultimate_arm_pressed() -> bool: return arm_edge
	func _ultimate_arm_held() -> bool: return arm_held
	func _ultimate_face_held() -> bool: return face_held
	func _attack_pressed() -> String: return face_edge
	func _move_refusal(reason: String) -> void: refusals.append(reason)

func _new_owned(uid: String = "creature_a") -> Dictionary:
	var owned := _owned(uid)
	owned.merge({"move_utility": "snare", "move_ultimate": "ultimate_ground_current",
		"known_moves": ["pebble_toss", "earth_rend", "snare", "ultimate_ground_current"],
		"move_mastery_uses": {"snare": 75, "ultimate_ground_current": 150}}, true)
	return owned

func _frozen(slot: String, action: int, tiers: Array = []) -> Dictionary:
	var owned := _new_owned()
	var frozen := MASTERY.freeze_action(MASTERY.owned_record(owned), slot,
		{"character_id": "owner_a", "creature_uid": owned.uid, "encounter_id": id,
		"generation": 1, "action": action}, tiers, MOVES.load_default())
	assert_true(frozen.get("ok") == true, str(frozen))
	return MANAGER.host_move_profile(MOVES.load_default(), "player_" + slot,
		str(owned["move_" + slot]), 0.5, 0.5, 1.0, 0.0, frozen.move)

func _new_start(slot: String, action: int, now_ms: int, tiers: Array = []) -> Dictionary:
	return host.authorize_move_start({"encounter_id": id, "action": action, "slot": slot},
		1, _new_owned(), _binding(), _frozen(slot, action, tiers), WIND, now_ms)

func test_snare_uses_frozen_rank_and_one_landed_original_without_energy_gain() -> void:
	var start := _new_start("utility", 1, 1000)
	assert_true(start.ok)
	assert_almost_eq(start.delta.move.power, 2.25 * 1.1, 0.00001)
	assert_eq(start.delta.move.mastery_rank, 3)
	assert_eq(host.move_resource_snapshot(id, 1, "creature_a").wind, 76.0)
	assert_true(_arrive(1, 1300).ok)
	var resources: Dictionary = host.credit_move_hit(id, 1, 1, 2.0, "opponent", 200.0)
	assert_eq(resources.energy, 0.0)
	assert_eq(resources.ultimate_meter, 4.0)
	var original: Dictionary = host.move_mastery_outcome(id, 1, 1)
	assert_eq(original.outcome.action_id, start.delta.move.action_id)
	assert_eq(original.outcome.move_id, "snare")
	assert_true(host.credit_move_hit(id, 1, 1, 2.0, "opponent", 200.0).is_empty())
	assert_eq(_new_start("utility", 2, 2000).code, "cooldown")
	assert_eq(host.move_mastery_outcome(id, 1, 1), original)

func test_ultimate_requires_real_landed_meter_spends_once_and_freezes_growth() -> void:
	var saved_visual_config := ULTIMATES.config()
	var enabled_visuals := saved_visual_config.duplicate(true)
	enabled_visuals.enabled = true # Disclosed mechanics fixture; no visual acceptance.
	ULTIMATES._config = enabled_visuals
	assert_eq(_new_start("ultimate", 1, 1000, [1, 2]).code, "ultimate_not_ready")
	# Build the actual host meter with seventeen separately accepted landed hits.
	for action: int in range(1, 18):
		assert_true(_start(action, action * 2000).ok)
		assert_true(_arrive(action, action * 2000 + 300).ok)
		host.credit_move_hit(id, 1, action, 1.0)
	assert_eq(host.move_resource_snapshot(id, 1, "creature_a").ultimate_meter, 100.0)
	var fire := _new_start("ultimate", 18, 36000, [1, 2])
	assert_true(fire.ok, str(fire))
	assert_almost_eq(fire.delta.move.power, 84.0 * 1.15 * 1.2, 0.0001)
	assert_eq(fire.delta.move.breakthrough_count, 2)
	assert_eq(fire.delta.ultimate_meter, 0.0)
	assert_true(float(fire.delta.move.recovery) >= float(fire.delta.move.ultimate.presentation_seconds))
	assert_false(_new_start("ultimate", 18, 36001, [1, 2]).ok)
	assert_true(_arrive(18, 36600).ok)
	assert_eq(host.credit_move_hit(id, 1, 18, 20.0, "opponent", 200.0).ultimate_meter, 0.0)
	assert_eq(host.pending_move_mastery().size(), 1)
	ULTIMATES._config = saved_visual_config

func test_disabled_ultimate_presentation_refuses_before_any_resource_mutation() -> void:
	var saved_visual_config := ULTIMATES.config()
	var disabled_visuals := saved_visual_config.duplicate(true)
	disabled_visuals.enabled = false
	ULTIMATES._config = disabled_visuals
	assert_false(MANAGER.live_move_supported("ultimate", "ultimate_ground_current"))
	var before: Dictionary = host.record(id).duplicate(true)
	assert_eq(_new_start("ultimate", 1, 1000).code, "move_not_mounted")
	assert_eq(host.record(id), before)
	assert_true(host.move_commit(id, 1).is_empty())
	ULTIMATES._config = saved_visual_config

func test_unsupported_utility_and_low_wind_refuse_without_spending() -> void:
	var owned := _new_owned()
	owned.move_utility = "unmounted_utility"
	owned.known_moves.append("unmounted_utility")
	var move := _frozen("utility", 1)
	move.move_id = "unmounted_utility"
	var before: Dictionary = host.record(id).duplicate(true)
	assert_eq(host.authorize_move_start({"encounter_id": id, "action": 1, "slot": "utility"},
		1, owned, _binding(), move, WIND, 1000).code, "move_not_mounted")
	assert_eq(host.record(id), before)
	var short_wind := {"max": 20.0, "regen_per_second": 0.0}
	assert_eq(host.authorize_move_start({"encounter_id": id, "action": 1, "slot": "utility"},
		1, _new_owned(), _binding(), _frozen("utility", 1), short_wind, 1000).code, "insufficient_wind")
	assert_eq(host.record(id), before)

func test_ultimate_tap_sequence_rejects_a_held_chord_and_fires_only_new_edge() -> void:
	var manager := TapManager.new()
	var creature: RefCounted = SPECIES.spawn("bramblebun")
	manager.set("_party", [creature] as Array[RefCounted])
	manager.set("_party_ultimate", {str(creature.get("uid")): 100.0})
	manager.arm_edge = true
	manager.arm_held = true
	manager.face_held = true
	manager.face_edge = "quick"
	assert_true(manager._read_ultimate_taps())
	assert_false(manager.ultimate_armed())
	manager.arm_edge = false
	assert_true(manager._read_ultimate_taps())
	assert_eq(manager.get("_buffered_attack"), "")
	manager.arm_held = false
	assert_true(manager._read_ultimate_taps())
	assert_true(manager.ultimate_armed())
	assert_true(manager._read_ultimate_taps())
	assert_eq(manager.get("_buffered_attack"), "")
	manager.face_held = false
	manager.face_edge = ""
	manager._read_ultimate_taps()
	manager.face_edge = "utility"
	manager.face_held = true
	assert_true(manager._read_ultimate_taps())
	assert_eq(manager.get("_buffered_attack"), "ultimate")
	assert_false(manager.ultimate_armed())
	manager._clear_move_input()
	manager.set("_party_ultimate", {})
	manager.arm_edge = true
	assert_true(manager._read_ultimate_taps())
	assert_eq(manager.refusals, ["Ultimate not ready"])
	assert_eq(manager.get("_buffered_attack"), "")
	manager.free()

func test_root_status_uses_body_clock_and_never_cancels_protected_tell() -> void:
	var body := WILD.new()
	body.instance = SPECIES.spawn("bramblebun")
	body.engaged = true
	body.set("_intent", preload("res://scripts/combat/combat_ai.gd").Intent.TELEGRAPH)
	body.set("_selected_attack", {"heavy": true, "telegraph": 1.1})
	var move := _frozen("utility", 1)
	var context := {"action_id": move.action_id, "encounter_id": id, "generation": 1,
		"source_uid": "creature_a", "target_uid": body.instance.uid,
		"source_position": Vector3.ZERO, "target_position": Vector3.RIGHT,
		"source_hp": 100.0, "source_max_hp": 100.0, "target_hp": body.instance.hp,
		"hostile": true, "geometry_connected": true, "target_is_boss": true}
	assert_true(body.apply_landed_utility(move, context))
	assert_eq(body.utility_movement_multiplier(), 0.0)
	assert_true(body.protected_heavy_committed())
	assert_false(body.apply_landed_utility(move, context), "same effect receipt cannot apply twice")
	body.set("_utility_clock_ms", 501.0)
	assert_eq(body.utility_movement_multiplier(), 1.0, "named root uses the authored half-second")
	body.hold_ultimate_reaction(2.0)
	assert_true(body.protected_heavy_committed(), "reaction must preserve the committed heavy")
	body.free()

func test_all_authored_ultimate_presentations_share_the_same_host_admission_gate() -> void:
	var original := ULTIMATES.config()
	var enabled := original.duplicate(true)
	enabled.enabled = true # Mechanics only; native visual acceptance stays open.
	ULTIMATES._config = enabled
	for move_id: String in enabled.visuals:
		assert_true(MANAGER.live_move_supported("ultimate", move_id), move_id)
		var owned := _new_owned()
		owned.move_ultimate = move_id
		if not owned.known_moves.has(move_id): owned.known_moves.append(move_id)
		var frozen := MASTERY.freeze_action(MASTERY.owned_record(owned), "ultimate",
			{"character_id": "owner_a", "creature_uid": owned.uid, "encounter_id": id, "generation": 1, "action": 1}, [], MOVES.load_default())
		assert_true(frozen.ok, move_id)
		if not frozen.ok: continue
		var move := MANAGER.host_move_profile(MOVES.load_default(), "player_ultimate", move_id, 0.5, 0.5, 1.0, 0.0, frozen.move)
		assert_eq(host.authorize_move_start({"encounter_id": id, "action": 1, "slot": "ultimate"},
			1, owned, _binding(), move, WIND, 1000).code, "ultimate_not_ready", move_id)
	ULTIMATES._config = original

func test_self_buff_commits_without_hostile_geometry_and_keeps_original_mastery_and_own_uid() -> void:
	var owned := _new_owned()
	owned.move_utility = "veil"
	owned.known_moves.append("veil")
	var frozen := MASTERY.freeze_action(MASTERY.owned_record(owned), "utility",
		{"character_id": "owner_a", "creature_uid": owned.uid, "encounter_id": id, "generation": 1, "action": 1}, [], MOVES.load_default())
	var move := MANAGER.host_move_profile(MOVES.load_default(), "player_utility", "veil", 0.5, 0.5, 1.0, 0.0, frozen.move)
	assert_true(host.authorize_move_start({"encounter_id": id, "action": 1, "slot": "utility"}, 1, owned, _binding(), move, WIND, 1000).ok)
	assert_eq(_arrive(1, 1300).delta.target, "self", "opponent is outside Veil's zero range")
	var receipt: Dictionary = host.apply_self_utility(id, 1, 1,
		{"creature_uid": owned.uid, "hp": 100.0, "hp_max": 100.0}, Vector3.ZERO, 1300)
	assert_false(receipt.is_empty())
	assert_false(receipt.damaging)
	assert_eq(receipt.hp_before, receipt.hp_after)
	assert_true(host.apply_self_utility(id, 1, 1, {"creature_uid": owned.uid, "hp": 100.0, "hp_max": 100.0}, Vector3.ZERO, 1301).is_empty())
	host.credit_move_effect(id, 1, 1, receipt)
	var original: Dictionary = host.move_mastery_outcome(id, 1, 1)
	assert_eq(original.outcome.effect_receipt, receipt)
	host.credit_move_effect(id, 1, 1, receipt)
	assert_eq(host.move_mastery_outcome(id, 1, 1), original)
	assert_eq(host.move_resource_snapshot(id, 1, owned.uid).ultimate_meter, 0.0)
	assert_eq(host.self_utility_view(id, owned.uid, 1400).movement_remaining_s, 1.4)
	assert_eq(host.self_utility_view(id, "foreign_uid", 1400).movement_remaining_s, 0.0)
	assert_eq(host.self_utility_view(id, owned.uid, 2800).movement_remaining_s, 0.0)
	var manager := MANAGER.new()
	manager.set("_party", [SPECIES.spawn("terrapup")] as Array[RefCounted])
	var creature: RefCounted = manager.get("_party")[0]
	var view := {"creature_uid": creature.uid, "source_utility": host.self_utility_view(id, owned.uid, 1400)}
	manager._apply_move_resources(view)
	manager.get("_party_utility_movement")[creature.uid].remaining_s = 0.5
	manager._apply_move_resources(view)
	assert_eq(manager.get("_party_utility_movement")[creature.uid].remaining_s, 0.5, "duplicate authority view never extends expiry")
	manager.free()

func test_target_utilities_have_live_consumers_and_effect_expiry() -> void:
	for move_id: String in ["snare", "slow_field", "shove", "dash_strike", "bramble_trap", "sap", "quake_ring"]:
		assert_true(MANAGER.live_move_supported("utility", move_id), move_id)
		assert_true(UTILITY.valid_definition(MOVES.load_default().move(move_id)), move_id)
	var body := WILD.new()
	body.instance = SPECIES.spawn("bramblebun")
	body.engaged = true
	var context := {"action_id": "slow-original", "encounter_id": id, "generation": 0,
		"source_uid": "creature_a", "target_uid": body.instance.uid, "source_position": Vector3.ZERO,
		"target_position": Vector3.ZERO, "target_point": Vector3.ZERO, "source_hp": 100.0, "source_max_hp": 100.0,
		"target_hp": body.instance.hp, "hostile": true, "geometry_connected": true, "target_is_boss": false}
	var hp := float(body.instance.hp)
	var move: Dictionary = MOVES.load_default().move("slow_field")
	move.move_id = "slow_field"
	assert_true(body.apply_landed_utility(move, context))
	assert_eq(body.utility_movement_multiplier(), 0.5)
	assert_eq(body.instance.hp, hp, "status-only field never deals HP damage")
	context.action_id = "sap-original"
	move = MOVES.load_default().move("sap")
	move.move_id = "sap"
	assert_true(body.apply_landed_utility(move, context))
	assert_eq(body.utility_damage_multiplier("creature_a"), 1.1)
	body.set("_utility_clock_ms", 4001.0)
	assert_eq(body.utility_movement_multiplier(), 1.0)
	assert_eq(body.utility_damage_multiplier("creature_a"), 1.0)
	body.free()

func test_compensated_frame_cannot_arrive_before_accepted_monotonic_windup() -> void:
	var manager := TapManager.new()
	manager.set("_action", MANAGER.Action.WINDUP)
	manager.set("_action_timer", 0.3)
	manager.set("_pending_move", {"local_strike_at_ms": Time.get_ticks_msec() + 1000, "recovery": 0.2})
	manager._tick_action(2.0)
	assert_eq(manager.resolved_strikes, 0)
	assert_eq(manager.get("_action"), MANAGER.Action.WINDUP)
	manager.get("_pending_move").local_strike_at_ms = 0
	manager._tick_action(2.0)
	assert_eq(manager.resolved_strikes, 1)
	assert_eq(manager.get("_action"), MANAGER.Action.RECOVERY)
	manager.free()
