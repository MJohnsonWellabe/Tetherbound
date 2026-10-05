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
	owned.move_utility = "heal_pulse"
	owned.known_moves.append("heal_pulse")
	var move := _frozen("utility", 1)
	move.move_id = "heal_pulse"
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
