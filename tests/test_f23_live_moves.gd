extends "res://tests/test_move_commit_runtime.gd"

const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const MASTERY := preload("res://scripts/creatures/move_mastery.gd")
const MOVES := preload("res://scripts/creatures/move_db.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const WILD := preload("res://scripts/creatures/wild_creature.gd")
const ULTIMATES := preload("res://scripts/vfx/ultimates/ultimate_library.gd")

class TapManager extends "res://scripts/combat/combat_manager.gd":
	var arm_edge := false
	var arm_held := false
	var face_held := false
	var face_edge := ""
	var refusals: Array[String] = []
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
	# The existing host self-cast consumers use the same admitted start. Keep
	# this logic witness separate from mounted gameplay/visual acceptance.
	for move_id: String in ["veil", "hearten"]:
		before_each()
		var rec: Dictionary = host.record(id)
		rec.opponent["card"] = {"uid":"opponent"}
		rec.opponent["body_generation"] = 1
		var owned := _new_owned()
		owned.move_utility = move_id
		owned.known_moves.append(move_id)
		var frozen := MASTERY.freeze_action(MASTERY.owned_record(owned), "utility",
			{"character_id":"owner_a", "creature_uid":owned.uid, "encounter_id":id,
			"generation":1, "action":1}, [], MOVES.load_default())
		assert_true(frozen.ok)
		var move := MANAGER.host_move_profile(MOVES.load_default(), "player_utility",
			move_id, 0.5, 0.5, 1.0, 0.0, frozen.move)
		assert_true(MANAGER.live_move_supported("utility", move_id))
		assert_eq(move.power, 0.0, "self utility never deals creature or trainer damage")
		assert_eq(move.base_power, 0.0)
		var admitted: Dictionary = host.authorize_move_start(
			{"encounter_id":id, "action":1, "slot":"utility"}, 1, owned, _binding(), move, WIND, 1000)
		assert_true(admitted.ok, str(admitted))
		var strike_at := int(host.move_commit(id, 1, 1).strike_at_ms)
		var cast_resources: Dictionary = rec.participants[1].move_resources["creature_a"].duplicate(true)
		assert_eq(cast_resources.wind, 76.0)
		var before: Dictionary = rec.duplicate(true)
		assert_false(host.resolve_self_utility(id, 1, 1, _binding(), Vector3.ZERO, 100.0, 100.0, strike_at - 1, 2000).ok)
		assert_eq(rec, before, "early self-cast leaves the admitted original unchanged")
		var replacement := _binding()
		replacement.body_instance_id = 52
		assert_false(host.resolve_self_utility(id, 1, 1, replacement, Vector3.ZERO, 100.0, 100.0, strike_at, 2000).ok)
		assert_eq(rec, before, "replacement body cannot finish the original cast")
		var resolved: Dictionary = host.resolve_self_utility(id, 1, 1, _binding(), Vector3.ZERO, 100.0, 100.0, strike_at, 2000)
		assert_true(resolved.ok, str(resolved))
		assert_false(resolved.delta.hit)
		assert_eq(resolved.delta.utility_receipt.original.binding, _binding())
		assert_eq(resolved.delta.utility_receipt.original.opponent, {"uid":"opponent", "body_generation":1})
		assert_eq(resolved.delta.utility_receipt.source_uid, "creature_a")
		assert_eq(resolved.delta.utility_receipt.target_uid, "creature_a")
		assert_eq(rec.participants[1].move_resources["creature_a"], cast_resources, "self resolution preserves all resource values and absolute cooldown deadlines")
		assert_eq(rec.opponent.hp, before.opponent.hp, "self cast leaves hostile HP unchanged")
		before = rec.duplicate(true)
		assert_false(host.resolve_self_utility(id, 1, 1, _binding(), Vector3.ZERO, 100.0, 100.0, strike_at + 1, 2001).ok)
		assert_eq(rec, before, "replayed self cast cannot refresh its status")
		assert_true(host.credit_move_hit(id, 1, 1, 0.0).is_empty())
		assert_eq(rec, before, "no landed debit means no energy, ultimate or mastery credit")
		if move_id == "veil":
			assert_almost_eq(host.self_utility_movement(id, "creature_a", Vector3.ZERO, 2000, _binding()), 1.4, 0.00001)
			assert_eq(host.self_utility_movement(id, "creature_a", Vector3.ZERO, 3500, _binding()), 1.0)
			assert_eq(host.self_utility_movement(id, "creature_a", Vector3.ZERO, 2000, replacement), 1.0)
			assert_false(bool(move.utility.get("invulnerable", false)))
			assert_eq(move.utility.damage_reduction, 0.0)
		else:
			assert_almost_eq(host.self_utility_power(id, "creature_a", 2000, _binding()), 1.15, 0.00001)
			assert_eq(host.self_utility_power(id, "creature_a", 6000, _binding()), 1.0)
			assert_eq(host.self_utility_power(id, "creature_a", 2000, replacement), 1.0)
			assert_true(_start(2, 2500).ok)
			assert_true(_arrive(2, 2800).ok)
			assert_true(host.credit_move_hit(id, 1, 2, 0.0).is_empty())
			assert_almost_eq(host.self_utility_power(id, "creature_a", 2500, _binding()), 1.15, 0.00001)
			var landed: Dictionary = host.credit_move_hit(id, 1, 2, 2.0, "opponent", 200.0, 1, 100.0, _binding(), 2500)
			assert_false(landed.get("utility_consumed", {}).is_empty())
			assert_eq(host.self_utility_power(id, "creature_a", 2500, _binding()), 1.0)
			assert_true(host.credit_move_hit(id, 1, 2, 2.0, "opponent", 200.0, 1, 100.0, _binding(), 2500).is_empty())

func test_ultimate_requires_real_landed_meter_spends_once_and_freezes_growth() -> void:
	var saved_visual_config := ULTIMATES.config()
	var enabled_visuals := saved_visual_config.duplicate(true)
	enabled_visuals.enabled = true # Disclosed mechanics fixture; no visual acceptance.
	ULTIMATES._config = enabled_visuals
	for signature_id: String in enabled_visuals.visuals:
		assert_true(MANAGER.live_move_supported("ultimate", signature_id), "authored signature mounted: " + signature_id)
		var owned := _new_owned()
		owned.move_ultimate = signature_id
		if not owned.known_moves.has(signature_id): owned.known_moves.append(signature_id)
		var frozen := MASTERY.freeze_action(MASTERY.owned_record(owned), "ultimate",
			{"character_id":"owner_a", "creature_uid":owned.uid, "encounter_id":id,
			"generation":1, "action":1}, [], MOVES.load_default())
		assert_true(frozen.ok, signature_id)
		var move := MANAGER.host_move_profile(MOVES.load_default(), "player_ultimate",
			signature_id, 0.5, 0.5, 1.0, 0.0, frozen.move)
		var before: Dictionary = host.record(id).duplicate(true)
		assert_eq(host.authorize_move_start({"encounter_id":id, "action":1, "slot":"ultimate"},
			1, owned, _binding(), move, WIND, 1000).code, "ultimate_not_ready",
			"authored enabled signature reaches the meter gate: " + signature_id)
		assert_eq(host.record(id), before, "empty-meter signature refuses without spending")
	assert_false(MANAGER.live_move_supported("ultimate", "ultimate_unknown"))
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
	for signature_id: String in saved_visual_config.visuals:
		assert_false(MANAGER.live_move_supported("ultimate", signature_id), "disabled signature refuses: " + signature_id)
	var before: Dictionary = host.record(id).duplicate(true)
	assert_eq(_new_start("ultimate", 1, 1000).code, "move_not_mounted")
	assert_eq(host.record(id), before)
	assert_true(host.move_commit(id, 1).is_empty())
	ULTIMATES._config = saved_visual_config

func test_unsupported_utility_and_low_wind_refuse_without_spending() -> void:
	var owned := _new_owned()
	owned.move_utility = "heal_pulse"
	owned.known_moves.append("heal_pulse")
	var frozen := MASTERY.freeze_action(MASTERY.owned_record(owned), "utility",
		{"character_id": "owner_a", "creature_uid": owned.uid, "encounter_id": id,
		"generation": 1, "action": 1}, [], MOVES.load_default())
	assert_true(frozen.get("ok") == true)
	var move := MANAGER.host_move_profile(MOVES.load_default(), "player_utility",
		"heal_pulse", 0.5, 0.5, 1.0, 0.0, frozen.move)
	assert_true(MANAGER.live_move_supported("utility", "heal_pulse"))
	var before: Dictionary = host.record(id).duplicate(true)
	assert_eq(host.authorize_move_start({"encounter_id": id, "action": 1, "slot": "utility"},
		1, owned, _binding(), move, WIND, 1000).code, "heal_scope_unavailable")
	assert_eq(host.record(id), before)
	assert_true(host.move_commit(id, 1, 1).is_empty())
	assert_true(host.move_resource_snapshot(id, 1, owned.uid).is_empty())
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
	var action := 2
	for control_id: String in ["slow_field", "bramble_trap", "sap"]:
		var owned := _new_owned()
		owned.move_utility = control_id
		owned.known_moves.append(control_id)
		var frozen := MASTERY.freeze_action(MASTERY.owned_record(owned), "utility",
			{"character_id":"owner_a", "creature_uid":owned.uid, "encounter_id":id,
			"generation":1, "action":action}, [], MOVES.load_default())
		assert_true(frozen.ok)
		var control := MANAGER.host_move_profile(MOVES.load_default(), "player_utility",
			control_id, 0.5, 0.5, 1.0, 0.0, frozen.move)
		assert_true(MANAGER.live_move_supported("utility", control_id))
		assert_eq(control.power, 0.0)
		assert_eq(control.base_power, 0.0)
		var landed := context.duplicate(true)
		landed.action_id = control.action_id
		landed["target_point"] = Vector3.RIGHT
		var before: Dictionary = body.get("_landed_utility_state").duplicate(true)
		var miss := landed.duplicate(true)
		miss.geometry_connected = false
		assert_false(body.apply_landed_utility(control, miss))
		assert_eq(body.get("_landed_utility_state"), before)
		if control_id != "sap":
			miss.geometry_connected = true
			miss.target_point = Vector3(50.0, 0.0, 0.0)
			assert_false(body.apply_landed_utility(control, miss))
			assert_eq(body.get("_landed_utility_state"), before, "field point remains bounded by frozen caster range")
		var hp_before := float(body.instance.hp)
		assert_true(body.apply_landed_utility(control, landed))
		assert_false(body.apply_landed_utility(control, landed), "same control receipt cannot apply twice")
		assert_eq(float(body.instance.hp), hp_before, "control consumer never adds the generic minimum damage")
		var state: Dictionary = body.get("_landed_utility_state")
		assert_eq(state.receipts[control.action_id].source_uid, "creature_a")
		assert_eq(state.receipts[control.action_id].target_uid, str(body.instance.uid))
		if control_id == "slow_field":
			assert_eq(body.utility_movement_multiplier(), 0.5)
			body.position = Vector3(10.0, 0.0, 0.0)
			assert_eq(body.utility_movement_multiplier(), 1.0, "slow applies only inside its authored field")
			body.position = Vector3.ZERO
		elif control_id == "bramble_trap":
			var effects := preload("res://scripts/combat/utility_effects.gd")
			assert_false(effects.stage_trap_trigger(state, "creature_a", str(body.instance.uid), Vector3.RIGHT, true, hp_before, true, 1000).ok)
			var triggered: Dictionary = effects.stage_trap_trigger(state, "creature_a", str(body.instance.uid), Vector3.RIGHT, true, hp_before, true, 1001)
			assert_true(triggered.ok, str(triggered))
			assert_false(effects.stage_trap_trigger(triggered.state, "creature_a", str(body.instance.uid), Vector3.RIGHT, true, hp_before, true, 1002).ok)
			assert_eq(triggered.state.statuses[str(body.instance.uid)].root.expires_at_ms, 1401, "boss root retains authored resistance")
		else:
			assert_almost_eq(body.utility_damage_multiplier(), 1.1, 0.00001)
			body.set("_utility_clock_ms", 4501.0)
			assert_eq(body.utility_damage_multiplier(), 1.0, "Sap expires without extending on receipt replay")
			assert_eq(body.utility_movement_multiplier(), 1.0, "expired Slow Field no longer affects movement")
		assert_true(body.protected_heavy_committed(), "non-damaging control does not cancel the protected tell")
		action += 1
	body.free()
