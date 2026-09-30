extends "res://tests/test_case.gd"

const FEEDBACK := preload("res://scripts/combat/hit_feedback.gd")

func test_replayed_hits_refuse_but_legitimate_out_of_order_impacts_and_issuers_are_independent() -> void:
	var history: Dictionary = {}
	assert_true(FEEDBACK.admit(history, {"action_id":"fight:1:3"}))
	assert_false(FEEDBACK.admit(history, {"action_id":"fight:1:3"}))
	assert_true(FEEDBACK.admit(history, {"action_id":"fight:1:2"}), "earlier travelling hit may arrive after a later contact hit")
	assert_false(FEEDBACK.admit(history, {"action_id":"fight:1:2"}))
	assert_true(FEEDBACK.admit(history, {"action_id":"fight:2:1"}))
	assert_false(FEEDBACK.admit(history, {"action_id":"fight:1:bad"}))
	var before := history.duplicate(true)
	assert_true(FEEDBACK.admit(history, {"action_id":"fight:1:4"}, false))
	assert_eq(history, before, "preview never consumes the host receipt")
	var next := 3 + int(FEEDBACK.config().get("receipt_sequence_window", 256))
	assert_true(FEEDBACK.admit(history, {"action_id":"fight:1:%d" % next}))
	assert_false(FEEDBACK.admit(history, {"action_id":"fight:1:3"}), "evicted old replay remains refused")

func test_weighted_feedback_is_immutable_and_preserves_host_damage() -> void:
	var light := FEEDBACK.receipt("fight:1:1", "pebble_toss", {}, "quick", 17.25, 1.0, false, Vector3.RIGHT)
	var heavy := FEEDBACK.receipt("fight:1:2", "stone_rush", {}, "charged", 17.25, 1.0, false, Vector3.RIGHT)
	assert_true(light.is_read_only())
	assert_true(heavy.knockback_m > light.knockback_m)
	assert_true(heavy.hitstop_seconds > light.hitstop_seconds)
	assert_eq(light.damage, 17.25, "presentation never rerolls host damage")
	assert_eq(light.direction, Vector3.RIGHT)
	assert_eq(FEEDBACK.weight_for({"slot": "charged"}, "quick"), "heavy", "incoming named moves use their authored weight even through the enemy quick fallback")

func test_frozen_launch_rejects_replacement_actors_generation_and_realm() -> void:
	var launch := FEEDBACK.launch("fight:2:4", "fight", "owned-1", "wild-1", "stone_rush", "charged", Vector3.ZERO, Vector3.RIGHT, 0.2, 7)
	assert_true(launch.is_read_only())
	assert_true(FEEDBACK.launch_matches(launch, "fight", "owned-1", "wild-1", 7))
	assert_false(FEEDBACK.launch_matches(launch, "next-fight", "owned-1", "wild-1", 7))
	assert_false(FEEDBACK.launch_matches(launch, "fight", "replacement-owned", "wild-1", 7))
	assert_false(FEEDBACK.launch_matches(launch, "fight", "owned-1", "replacement-wild", 7))
	assert_false(FEEDBACK.launch_matches(launch, "fight", "owned-1", "wild-1", 8), "same UID cannot reuse an old body generation")

func test_giant_and_profile_reductions_apply_once() -> void:
	var normal := FEEDBACK.receipt("a", "stone_rush", {}, "charged", 20.0, 1.0, false, Vector3.RIGHT)
	var giant := FEEDBACK.receipt("b", "stone_rush", {}, "charged", 20.0, 1.0, false, Vector3.RIGHT, float(FEEDBACK.config().giant_height_m), 0.5)
	assert_almost_eq(giant.knockback_m, normal.knockback_m * float(FEEDBACK.config().giant_knockback_scale) * 0.5, 0.00001)
	assert_true(FEEDBACK.impulse_for(giant) < FEEDBACK.impulse_for(normal))

func test_critical_effective_resisted_and_ordinary_numbers_differ() -> void:
	var plain := FEEDBACK.receipt("a", "", {}, "quick", 20.0, 1.0, false, Vector3.RIGHT)
	var crit := FEEDBACK.receipt("b", "", {}, "quick", 20.0, 1.25, true, Vector3.RIGHT)
	var strong := FEEDBACK.receipt("c", "", {}, "quick", 20.0, 1.25, false, Vector3.RIGHT)
	var weak := FEEDBACK.receipt("d", "", {}, "quick", 20.0, 0.8, false, Vector3.RIGHT)
	var base := FEEDBACK.number_style(plain, true)
	assert_true(FEEDBACK.number_style(crit, true).font_px > base.font_px)
	assert_true(FEEDBACK.number_style(strong, true).font_px > base.font_px)
	assert_true(FEEDBACK.number_style(weak, true).font_px < base.font_px)
	assert_true(FEEDBACK.number_style(crit, true).colour != base.colour)
	assert_true(FEEDBACK.number_style(plain, false).font_px < base.font_px)


func test_flash_styles_share_host_crit_type_facts_and_resisted_reads_weaker() -> void:
	var plain := FEEDBACK.receipt("a", "", {}, "quick", 20.0, 1.0, false, Vector3.RIGHT)
	var crit := FEEDBACK.receipt("b", "", {}, "quick", 20.0, 1.25, true, Vector3.RIGHT)
	var effective := FEEDBACK.receipt("c", "", {}, "quick", 20.0, 1.25, false, Vector3.RIGHT)
	var resisted := FEEDBACK.receipt("d", "", {}, "quick", 20.0, 0.8, false, Vector3.RIGHT)
	assert_true(FEEDBACK.flash_style(crit).strength_scale > FEEDBACK.flash_style(plain).strength_scale)
	assert_true(FEEDBACK.flash_style(effective).strength_scale > FEEDBACK.flash_style(plain).strength_scale)
	assert_true(FEEDBACK.flash_style(resisted).strength_scale < FEEDBACK.flash_style(plain).strength_scale)
	assert_ne(FEEDBACK.flash_style(crit).colour, FEEDBACK.flash_style(effective).colour)
	assert_eq(FEEDBACK.style_key(crit), "critical", "crit owns combined crit/effective flash and number identity")
	assert_eq(crit.impact_audio_owner, "receipt")

func test_rumble_off_and_weight_do_not_modify_host_receipt_or_timing() -> void:
	var motion := preload("res://scripts/ui/motion_prefs.gd")
	var prefs_type := preload("res://scripts/ui/key_bindings.gd")
	var path := "user://__test_f21_rumble.json"
	var old := motion.rumble_percent()
	var prefs := prefs_type.new(path)
	motion.set_rumble_percent(40)
	motion.store_to(prefs)
	assert_true(bool(prefs.save()))
	motion.set_rumble_percent(100)
	var restored := prefs_type.new(path)
	assert_eq(restored.load_overrides(), prefs_type.LOAD_OK)
	motion.load_from(restored)
	assert_eq(motion.rumble_percent(), 40, "device preference survives actual settings file")
	var heavy := FEEDBACK.receipt("heavy", "fireball", {"slot": "charged"}, "charged", 20.0, 1.0, false, Vector3.RIGHT)
	var normal := FEEDBACK.rumble_spec(heavy, 1.0)
	var reduced := FEEDBACK.rumble_spec(heavy, motion.rumble_scale())
	assert_almost_eq(reduced.strong, normal.strong * 0.4, 0.00001)
	assert_eq(reduced.seconds, normal.seconds, "amplitude preference never changes receipt timing")
	motion.set_rumble_percent(-1)
	assert_eq(motion.rumble_percent(), 0)
	assert_true(FEEDBACK.rumble_spec(heavy, motion.rumble_scale()).is_empty())
	assert_true(FEEDBACK.rumble_spec({"weight": "light"}, 1.0).is_empty())
	assert_eq(heavy.damage, 20.0)
	assert_true(heavy.is_read_only())
	motion.set_rumble_percent(200)
	assert_eq(motion.rumble_percent(), 100)
	motion.set_rumble_percent(old)
	if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

class IncomingHeartStub extends RefCounted:
	var placed := true
	func is_placed(id: String, _progression: RefCounted) -> bool:
		return placed and id == "placed-heart"
	func heart(_id: String) -> Dictionary:
		return {"power": {"incoming_damage_multiplier": 0.75}}

func test_host_defensive_poise_break_bonus_expiry_and_peer_scope() -> void:
	var cfg := {"max": 20.0, "regen_delay": 0.1, "regen_per_second": 20.0,
		"stagger_seconds": 0.2, "crit_scale": 1.5}
	var struck := FEEDBACK.defence_state("owned-a", 0, cfg)
	var untouched := FEEDBACK.defence_state("owned-b", 0, cfg)
	var first := FEEDBACK.resolve_defence_hit(struck, 25.0, 1.0, 0, 0.03, cfg)
	assert_false(first.critical)
	assert_true(first.staggered)
	assert_eq(first.poise, 0.0)
	assert_almost_eq(first.stagger_left, 0.2, 0.00001)
	assert_almost_eq(first.quiet_left, 0.1, 0.00001, "quiet beat follows presentation stagger as before")
	var bonus := FEEDBACK.resolve_defence_hit(struck, 8.0, 0.5, 100, 0.12, cfg)
	assert_true(bonus.critical)
	assert_eq(bonus.damage, 6.0, "one host relic multiplier and one host critical multiplier")
	assert_eq(untouched.poise, 20.0)
	assert_false(untouched.critical_ready)
	assert_eq(untouched.target_uid, "owned-b")
	var expired := FEEDBACK.resolve_defence_hit(struck, 1.0, 1.0, 1000, 0.03, cfg)
	assert_false(expired.critical, "expired bonus cannot survive a later strike")
	assert_false(expired.staggered)
	assert_true(expired.poise > 0.0, "host regen resumes after its frozen stagger/quiet intervals")
	var receipt := FEEDBACK.receipt("f:enemy:1", "root_nibble", {}, "quick", 8.0, 0.8, false, Vector3.LEFT)
	var resolved := FEEDBACK.with_defence(receipt, bonus)
	assert_true(resolved.is_read_only())
	assert_true(resolved.critical)
	assert_eq(resolved.damage, 6.0)
	assert_eq(resolved.type_mult, 0.8)
	assert_eq(receipt.damage, 8.0, "pre-resolution receipt remains detached")

func test_host_relic_resolution_ignores_numeric_peer_claims_and_unplaced_identity() -> void:
	var director := preload("res://scripts/combat/encounter_director.gd")
	var hearts := IncomingHeartStub.new()
	var progression := RefCounted.new()
	var card := {"active_relic_id": "placed-heart", "incoming_damage_multiplier": 0.01}
	assert_eq(director.validate_card_incoming_multiplier(card, hearts, progression), 0.75)
	hearts.placed = false
	assert_eq(director.validate_card_incoming_multiplier(card, hearts, progression), 1.0)
	hearts.placed = true
	assert_eq(director.validate_card_incoming_multiplier({"active_relic_id": "forged-heart"}, hearts, progression), 1.0)
	assert_eq(director.validate_card_incoming_multiplier(card, null, progression), 1.0)
