extends "res://tests/test_case.gd"

const RECORDER := preload("res://tests/capture_tidewake_named_fights.gd")
const CAPTURE := preload("res://tools/phase2_capture_tidewake_fights.gd")
const F40_FIGHT := preload("res://tools/capture_cloudreach_f40_fight.gd")


func test_budget_stop_never_becomes_victory_even_at_won_boundary() -> void:
	var won := {"ok": true, "outcomes": ["won"], "xp_progress": [{"index": 0}]}
	for active: bool in [false, true]:
		var timed := RECORDER.capture_terminal_result(active, 300.0, 300.0, 20, 100, won, 0)
		assert_false(timed.ok)
		assert_eq(timed.reason, "time_cap")
		var full := RECORDER.capture_terminal_result(active, 100.0, 300.0, 100, 100, won, 0)
		assert_false(full.ok)
		assert_eq(full.reason, "frame_cap")
	assert_true(RECORDER.capture_terminal_result(false, 299.0, 300.0, 99, 100, won, 0).ok)


func test_observer_rejection_and_image_failure_survive_terminal_export() -> void:
	for outcome: String in ["lost", "fled", "no signal"]:
		var result := RECORDER.capture_terminal_result(false, 20, 300, 10, 100,
			{"ok": false, "why": outcome, "outcomes": [outcome]}, 0)
		assert_false(result.ok)
		assert_eq(result.reason, outcome)
	assert_false(RECORDER.capture_terminal_result(false, 20, 300, 10, 100, {"ok": false, "why": ""}, 0).ok)
	assert_false(RECORDER.capture_terminal_result(false, 20, 300, 10, 100, {"ok": true}, 1).ok)
	assert_false(RECORDER.capture_terminal_result(false, 20, 300, 0, 100, {"ok": true}, 0).ok)


func _shown_receipt() -> Dictionary:
	return {"visible": true, "hud_visible": true, "tree_paused": false, "modals": [],
		"banner": "Victory rewards | Venn's reward: 10 coins | Ripplet +XP",
		"events": [{"kind": "reward_summary", "seq": 12, "receipt": "Venn's reward: 10 coins"}],
		"queued": 0, "pause_started": -1.0}


func test_receipt_must_be_new_visible_from_expected_trainer_and_in_banner() -> void:
	var state := _shown_receipt()
	var receipt := CAPTURE.fresh_receipt(state, 11, "Venn's reward: ")
	assert_eq(receipt.seq, 12)
	receipt.receipt = "changed copy"
	assert_eq(state.events[0].receipt, "Venn's reward: 10 coins")
	assert_eq(CAPTURE.fresh_receipt(state, 12, "Venn's reward: "), {})
	assert_eq(CAPTURE.fresh_receipt(state, 11, "Nerissa's reward: "), {})
	state.banner = "Victory rewards | +XP"
	assert_eq(CAPTURE.fresh_receipt(state, 11, "Venn's reward: "), {})
	state = _shown_receipt()
	state.events = []
	assert_eq(CAPTURE.fresh_receipt(state, 11, "Venn's reward: "), {})


func test_hidden_paused_or_modal_receipt_is_not_a_captureable_receipt() -> void:
	for key: String in ["visible", "hud_visible"]:
		var state := _shown_receipt()
		state[key] = false
		assert_eq(CAPTURE.fresh_receipt(state, 11, "Venn's reward: "), {})
	var paused_state := _shown_receipt()
	paused_state.tree_paused = true
	assert_eq(CAPTURE.fresh_receipt(paused_state, 11, "Venn's reward: "), {})
	var modal_state := _shown_receipt()
	modal_state.modals = ["/root/World/DialoguePanel"]
	assert_eq(CAPTURE.fresh_receipt(modal_state, 11, "Venn's reward: "), {})


func test_hidden_panel_is_expired_only_after_queue_and_pause_clear() -> void:
	var state := _shown_receipt()
	state.visible = false
	assert_false(CAPTURE.naturally_expired(state), "hidden but still carrying receipt")
	state.events = []
	assert_true(CAPTURE.naturally_expired(state))
	for override: Dictionary in [{"queued": 1}, {"pause_started": 1.0}, {"tree_paused": true},
			{"hud_visible": false}, {"modals": ["dialogue"]}]:
		var blocked := state.duplicate(true)
		blocked.merge(override, true)
		assert_false(CAPTURE.naturally_expired(blocked))


func test_partial_failure_keeps_valid_images_without_claiming_lifecycle_complete() -> void:
	var raw := [{"file": "res://shots/t.png", "tag": "t", "camera": [1, 2, 3]}]
	var phases := [{"id": "venn-win", "file": "res://shots/win.png", "phase": "win",
		"receipt_state": {"visible": true}}]
	var manifest := CAPTURE.lifecycle_manifest(raw, phases, ["aftermath image save failed"], "water_trainer_venn")
	assert_false(manifest.complete)
	assert_eq(manifest.missing_phases, ["aftermath", "receipt-expired"])
	assert_eq(manifest.frames.size(), 2)
	assert_eq(manifest.frames[1].file, "res://shots/win.png")
	manifest.frames[1].receipt_state.visible = false
	assert_true(phases[0].receipt_state.visible, "manifest cannot alter prior frame state")
	manifest.frames[0].camera[0] = 999
	assert_eq(raw[0].camera[0], 1)
	var diagnostic := CAPTURE.lifecycle_manifest([{"file": "res://shots/diagnostic.png", "tag": "diagnostic"}], [], ["time_cap"], "water_trainer_venn")
	assert_eq(diagnostic.missing_phases, ["win", "aftermath", "receipt-expired"])
	assert_false(diagnostic.complete)


func test_complete_requires_all_three_saved_phases_and_no_failures() -> void:
	var phases := []
	for phase: String in ["win", "aftermath", "receipt-expired"]:
		phases.append({"id": phase, "file": "res://shots/" + phase + ".png", "phase": phase})
	assert_true(CAPTURE.lifecycle_manifest([], phases, [], "water_trainer_venn").complete)
	assert_false(CAPTURE.lifecycle_manifest([], phases, ["manifest failure"], "water_trainer_venn").complete)


func test_f40_fight_manifest_accepts_exact_json_resolution_roundtrip() -> void:
	var graphics := {"resolution": [1920, 1080], "renderer": "forward_plus"}
	var receipt := {"complete": true, "fight_id": "captain_veyra_storm_anchor",
		"resolution": [1920, 1080], "rendering_method": "forward_plus"}
	var decoded: Variant = JSON.parse_string(JSON.stringify(receipt))
	assert_eq(typeof(decoded.resolution[0]), TYPE_FLOAT)
	assert_true(F40_FIGHT.fight_manifest_matches(receipt, graphics))
	assert_true(F40_FIGHT.fight_manifest_matches(decoded, graphics))
	for resolution: Variant in [null, [], [1920], [1920, 1080, 1], [1080, 1920],
			[1920.5, 1080], ["1920", 1080], [true, 1080], [NAN, 1080], [INF, 1080]]:
		var malformed: Dictionary = receipt.duplicate(true)
		malformed.resolution = resolution
		assert_false(F40_FIGHT.fight_manifest_matches(malformed, graphics))
	for override: Dictionary in [{"complete": false}, {"complete": "true"},
			{"fight_id": "wrong"}, {"rendering_method": "gl_compatibility"}]:
		var malformed: Dictionary = receipt.duplicate(true)
		malformed.merge(override, true)
		assert_false(F40_FIGHT.fight_manifest_matches(malformed, graphics))
	for key: String in ["complete", "fight_id", "resolution", "rendering_method"]:
		var missing: Dictionary = receipt.duplicate(true)
		missing.erase(key)
		assert_false(F40_FIGHT.fight_manifest_matches(missing, graphics))
	assert_false(F40_FIGHT.fight_manifest_matches(null, graphics))
	assert_false(F40_FIGHT.fight_manifest_matches(receipt, {}))
	assert_false(F40_FIGHT.fight_manifest_matches(receipt,
		{"resolution": [1920.0, 1080.0], "renderer": "forward_plus"}))
