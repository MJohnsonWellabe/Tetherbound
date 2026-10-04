extends "res://tests/test_case.gd"

## F32#5: a resource refusal never reaches the HUD as a raw code.
const ACTIONS := preload("res://scripts/world/f32_source_actions.gd")

func test_contention_refusals_read_as_sentences() -> void:
	for code: String in ["stale_stock", "source_or_revision_changed", "regrowing", "equipped_tool_required", "something_unknown"]:
		var text := ACTIONS.refusal_reason({"ok": false, "code": code, "reason": code}, "fallback")
		assert_ne(text, code, code + " is replaced")
		assert_true(text.contains(" ") and text.ends_with("."), code + " reads as a sentence: " + text)
	assert_eq(ACTIONS.refusal_reason({"ok": false, "code": "stale_stock"}, "x"), "Someone else gathered this first.")

func test_existing_sentences_and_pending_fallbacks_are_kept() -> void:
	assert_eq(ACTIONS.refusal_reason({"ok": false, "code": "unregistered_source", "reason": "That resource is unavailable."}, "x"),
		"That resource is unavailable.")
	assert_eq(ACTIONS.refusal_reason({"ok": true, "owner_saved": false}, "Gathering is awaiting settlement."),
		"Gathering is awaiting settlement.")
