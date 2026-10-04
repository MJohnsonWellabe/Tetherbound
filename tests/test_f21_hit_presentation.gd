extends "res://tests/test_case.gd"

## F21#0/#1/#3 (COMBAT §11, UX §18). The solo and incoming hit paths freeze the
## same `hit_feedback` receipt the host path does, so every landed hit carries
## weight-scaled knockback and hitstop and reaches the HUD as a world-space
## number; crit, super-effective and resisted numbers read differently; heavy,
## crit and ultimate impacts rumble and shake, each behind its own setting.

const COMBAT := preload("res://scripts/combat/combat_manager.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const FEEDBACK := preload("res://scripts/combat/hit_feedback.gd")
const MOTION := preload("res://scripts/ui/motion_prefs.gd")
const KEY_BINDINGS := preload("res://scripts/ui/key_bindings.gd")
const TEXT := preload("res://scripts/ui/text_prefs.gd")
const COMBAT_HUD_SCENE := preload("res://scenes/combat/combat_hud.tscn")
const TEST_PATH := "user://__test_f21_hit_presentation.json"


class CombatBody extends Node3D:
	var instance: RefCounted = null
	var profile: Dictionary = {}
	var impulses: Array[float] = []
	func body_radius() -> float: return 0.6
	func centre() -> Vector3: return position
	func combat_config() -> Dictionary: return profile
	func facing() -> Vector3: return Vector3.BACK
	func add_impulse(_direction: Vector3, strength: float) -> void: impulses.append(strength)
	func play_attack() -> void: pass
	func play_hit() -> void: pass
	func play_faint() -> void: pass


func after_each() -> void:
	MOTION.set_damage_numbers_mode("on")
	MOTION.set_rumble_percent(100)
	TEXT.set_text_percent(100)
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


func _creature(type_id: String) -> RefCounted:
	var creature: RefCounted = CREATURE.from_species("guardian", {
		"display_name": "Guardian", "type": type_id, "base_hp": 100.0,
		"base_attack": 20.0, "base_defence": 20.0})
	creature.move_quick = "gale_peck"
	creature.move_charged = "earth_fist"
	creature.hp = 1000.0
	return creature


func _fight() -> Dictionary:
	var manager := COMBAT.new()
	var enemy := _creature("ground")
	var ally := _creature("water")
	var wild := CombatBody.new()
	wild.instance = enemy
	wild.profile = {"move_id": "earth_fist", "power": 12.0, "range": 5.0, "cone_degrees": 360.0, "lunge": 0.0}
	var ally_body := CombatBody.new()
	ally_body.instance = ally
	ally_body.position = Vector3(0.0, 0.0, 2.0)
	var arena := Node3D.new()
	manager.set("_moves", MOVE_DB.new())
	manager.set("_enemy", enemy)
	manager.set("_wild", wild)
	manager.set("_ally_body", ally_body)
	manager.set("_arena", arena)
	manager.set("_party", [ally] as Array[RefCounted])
	manager.set("_active_index", 0)
	manager.set("_encounter_id", "test")
	manager.set("state", COMBAT.State.ACTIVE)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	manager.set("_rng", rng)
	var impacts: Array = []
	manager.impact_confirmed.connect(func(on_enemy: bool, receipt: Dictionary, where: Vector3) -> void:
		impacts.append({"on_enemy": on_enemy, "receipt": receipt, "where": where}))
	return {"manager": manager, "wild": wild, "ally_body": ally_body, "arena": arena, "impacts": impacts}


func _free(fight: Dictionary) -> void:
	for key: String in ["manager", "wild", "ally_body", "arena"]:
		(fight[key] as Node).free()


func _expected_impulse(weight: String) -> float:
	var spec: Dictionary = FEEDBACK.config().get("weights", {}).get(weight, {})
	return float(MATH.config().get("creature_movement", {}).get("impulse_damping", 0.0)) * float(spec.get("knockback_m", 0.0))


func test_solo_hit_on_the_player_freezes_a_weighted_receipt_and_reaches_the_hud() -> void:
	var fight := _fight()
	var manager: Node = fight.manager
	var flash_was := bool(MATH.config().get("impact", {}).get("enabled", true))
	MATH.config().get("impact", {})["enabled"] = false
	manager.call("_on_enemy_strike")
	MATH.config().get("impact", {})["enabled"] = flash_was
	var impacts: Array = fight.impacts
	assert_eq(impacts.size(), 1, "one landed incoming hit, one confirmed receipt")
	if impacts.size() == 1:
		var receipt: Dictionary = impacts[0].receipt
		assert_false(bool(impacts[0].on_enemy))
		assert_eq(str(receipt.move_id), "earth_fist")
		assert_eq(str(receipt.weight), FEEDBACK.weight_for(MOVE_DB.new().move("earth_fist"), "quick"))
		assert_almost_eq((fight.ally_body as CombatBody).impulses[0], _expected_impulse(str(receipt.weight)), 0.0001,
			"knockback comes from the receipt's move weight, not the legacy lunge share")
		assert_almost_eq(float(manager.get("_hitstop_left")), float(receipt.hitstop_seconds), 0.0001)
		assert_true((impacts[0].where as Vector3).is_finite())
	_free(fight)


func test_coop_host_hit_on_the_player_uses_the_weighted_receipt_impulse() -> void:
	# Legacy session payload (no receipt): the hit builds one locally, and the
	# knockback follows its move weight exactly as the solo path does.
	var fight := _fight()
	var manager: Node = fight.manager
	var flash_was := bool(MATH.config().get("impact", {}).get("enabled", true))
	MATH.config().get("impact", {})["enabled"] = false
	manager.call("apply_host_enemy_hit", {"damage": 5.0, "move_id": "earth_fist", "lunge": 3.4, "type_mult": 1.0})
	MATH.config().get("impact", {})["enabled"] = flash_was
	var impacts: Array = fight.impacts
	var impulses: Array[float] = (fight.ally_body as CombatBody).impulses
	assert_eq(impacts.size(), 1, "the co-op incoming hit reached the HUD channel")
	assert_eq(impulses.size(), 1, "one push per landed hit")
	if impacts.size() == 1 and impulses.size() == 1:
		var weight := str(impacts[0].receipt.weight)
		assert_almost_eq(impulses[0], _expected_impulse(weight), 0.0001,
			"co-op knockback comes from the receipt's weight, not lunge*0.4")
	_free(fight)


func test_receiptless_hitstop_reads_the_single_feedback_table() -> void:
	var manager := COMBAT.new()
	var weights: Dictionary = FEEDBACK.config().get("weights", {})
	assert_false(MATH.config().has("hitstop"), "one hitstop table: impact.feedback only")
	assert_almost_eq(float(manager.call("_hitstop_seconds", true, false)), float(weights.light.hitstop_seconds), 0.0001)
	assert_almost_eq(float(manager.call("_hitstop_seconds", false, false)), float(weights.heavy.hitstop_seconds), 0.0001)
	assert_almost_eq(float(manager.call("_hitstop_seconds", true, true)),
		float(FEEDBACK.config().get("critical_hitstop_seconds", 0.0)), 0.0001)
	manager.free()


func test_solo_player_strike_uses_slot_weight_for_knockback_and_hitstop() -> void:
	for slot: String in ["quick", "charged"]:
		var fight := _fight()
		var manager: Node = fight.manager
		manager.set("_pending_move", {"is_quick": slot == "quick", "slot": slot, "power": 9.0, "vfx": {}})
		var flash_was := bool(MATH.config().get("impact", {}).get("enabled", true))
		MATH.config().get("impact", {})["enabled"] = false
		manager.call("_perform_player_strike", true)
		MATH.config().get("impact", {})["enabled"] = flash_was
		var impacts: Array = fight.impacts
		var weight := str(FEEDBACK.config().get("slot_weights", {}).get(slot, "light"))
		assert_eq(impacts.size(), 1, "%s: the contact reached the HUD channel" % slot)
		if impacts.size() == 1:
			assert_true(bool(impacts[0].on_enemy))
			assert_eq(str(impacts[0].receipt.weight), weight)
		assert_almost_eq((fight.wild as CombatBody).impulses[0], _expected_impulse(weight), 0.0001, slot)
		var hitstop := float(FEEDBACK.config().get("weights", {}).get(weight, {}).get("hitstop_seconds", 0.0))
		assert_almost_eq(float(manager.get("_hitstop_left")), hitstop, 0.0001, slot)
		_free(fight)
	assert_true(_expected_impulse("heavy") > _expected_impulse("light"), "a heavy hit throws further")


func test_crit_sharp_rumble_and_class_shake_follow_their_settings() -> void:
	var light_crit := {"weight": "light", "critical": true}
	assert_false(FEEDBACK.rumble_spec(light_crit, 1.0).is_empty(), "a stagger-crit rumbles even on a quick move")
	assert_true(FEEDBACK.rumble_spec({"weight": "medium"}, 1.0).is_empty(), "ordinary light/medium hits never rumble")
	assert_true(FEEDBACK.shake_scale({"weight": "light"}) == 0.0)
	assert_true(FEEDBACK.shake_scale(light_crit) > 0.0)
	assert_true(FEEDBACK.shake_scale({"weight": "ultimate"}) > FEEDBACK.shake_scale({"weight": "heavy"}))
	MOTION.set_rumble_percent(0)
	assert_true(FEEDBACK.rumble_spec(light_crit, MOTION.rumble_scale()).is_empty(), "rumble Off silences crits too")


func test_damage_number_setting_cycles_and_survives_a_relaunch() -> void:
	assert_eq(MOTION.damage_numbers_mode(), "on", "numbers default on")
	MOTION.set_damage_numbers_mode(MOTION.next_damage_numbers_mode())
	assert_eq(MOTION.damage_numbers_mode(), "own")
	var first: RefCounted = KEY_BINDINGS.new(TEST_PATH)
	MOTION.store_to(first)
	assert_true(bool(first.call("save")))
	MOTION.set_damage_numbers_mode("on")
	var second: RefCounted = KEY_BINDINGS.new(TEST_PATH)
	assert_eq(int(second.call("load_overrides")), KEY_BINDINGS.LOAD_OK)
	MOTION.load_from(second)
	assert_eq(MOTION.damage_numbers_mode(), "own")
	MOTION.set_damage_numbers_mode("bogus")
	assert_eq(MOTION.damage_numbers_mode(), "on", "an unknown stored value falls back to On")


## The unit runner has no scene tree, so the HUD is driven out of tree: no
## camera, so labels stay hidden; placement is proven by the in-engine capture.
func _hud() -> Node:
	return COMBAT_HUD_SCENE.instantiate()


func _receipt(extra: Dictionary) -> Dictionary:
	var base := {"action_id": "t:1", "move_id": "", "target_uid": "foe", "weight": "light",
		"damage": 10.0, "type_mult": 1.0, "critical": false}
	base.merge(extra, true)
	return base


func test_hud_numbers_style_by_class_honour_own_only_and_fade_out() -> void:
	var hud := _hud()
	var ahead := Vector3(0.0, 0.0, -6.0)
	var numbers: Array = hud.get("_damage_numbers")
	hud.call("_on_impact_confirmed", true, _receipt({"target_uid": "a"}), ahead)
	hud.call("_on_impact_confirmed", true, _receipt({"target_uid": "b", "critical": true}), ahead)
	hud.call("_on_impact_confirmed", true, _receipt({"target_uid": "c", "type_mult": 0.8}), ahead)
	numbers = hud.get("_damage_numbers")
	assert_eq(numbers.size(), 3)
	if numbers.size() == 3:
		var plain: Label = numbers[0]
		var crit: Label = numbers[1]
		var weak: Label = numbers[2]
		assert_eq(plain.text, "10", "an ordinary hit shows its damage")
		assert_true(crit.get_theme_font_size("font_size") > plain.get_theme_font_size("font_size"))
		assert_true(weak.get_theme_font_size("font_size") < plain.get_theme_font_size("font_size"))
		assert_ne(crit.get_theme_color("font_color"), plain.get_theme_color("font_color"))
	# Merge: a second hit on the same target inside the window adds, no new label.
	hud.call("_on_impact_confirmed", true, _receipt({"target_uid": "a", "damage": 5.0}), ahead)
	assert_eq((hud.get("_damage_numbers") as Array).size(), 3)
	assert_eq((hud.get("_damage_numbers") as Array)[0].text, "15")
	# Own only hides a peer's hit; Off hides everything.
	MOTION.set_damage_numbers_mode("own")
	hud.call("_on_impact_confirmed", true, _receipt({"target_uid": "d", "own_hit": false}), ahead)
	assert_eq((hud.get("_damage_numbers") as Array).size(), 3)
	MOTION.set_damage_numbers_mode("off")
	hud.call("_on_impact_confirmed", false, _receipt({"target_uid": "e"}), ahead)
	assert_eq((hud.get("_damage_numbers") as Array).size(), 3)
	hud.call("_tick_damage_numbers", float(FEEDBACK.config().get("numbers", {}).get("duration_seconds", 0.8)) + 0.01)
	assert_eq((hud.get("_damage_numbers") as Array).size(), 0, "numbers fade out and free after their duration")
	hud.free()


func test_hud_numbers_follow_text_size_and_keep_fading_in_relay_mode() -> void:
	var hud := _hud()
	var ahead := Vector3(0.0, 0.0, -6.0)
	hud.call("_on_impact_confirmed", true, _receipt({"target_uid": "a"}), ahead)
	TEXT.set_text_percent(150)
	hud.call("_on_impact_confirmed", true, _receipt({"target_uid": "b"}), ahead)
	var numbers: Array = hud.get("_damage_numbers")
	assert_eq(numbers.size(), 2)
	if numbers.size() == 2:
		var normal := (numbers[0] as Label).get_theme_font_size("font_size")
		var large := (numbers[1] as Label).get_theme_font_size("font_size")
		assert_eq(large, int(round(float(normal) * 1.5)), "UX §8 text size scales hit numbers")
	# A relay objective takes the HUD mid-flight: numbers still age and free.
	hud.call("set_world_presentation_mode", "relays")
	hud.call("_process", float(FEEDBACK.config().get("numbers", {}).get("duration_seconds", 0.8)) + 0.01)
	assert_eq((hud.get("_damage_numbers") as Array).size(), 0, "relay mode never freezes a number on screen")
	hud.free()
