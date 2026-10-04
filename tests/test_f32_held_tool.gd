extends "res://tests/test_case.gd"

## F32: a held tool the character no longer owns, or has worn out, gathers as
## bare hands instead of voiding the host's whole resource context (which
## locked the player out of every later gather, tool-less ones included).
const RESOURCES := preload("res://scripts/net/foundation_resources.gd")
const ACTIONS := preload("res://scripts/world/f32_source_actions.gd")

func test_owned_working_tool_is_kept() -> void:
	assert_eq(RESOURCES.effective_tool("axe", [{"id": "axe", "n": 1}]), "axe")
	assert_eq(RESOURCES.effective_tool("", [{"id": "axe", "n": 1}]), "")

func test_unowned_or_worn_tool_gathers_as_bare_hands() -> void:
	assert_eq(RESOURCES.effective_tool("knife", [{"id": "axe", "n": 1}]), "", "dropped/traded/satchelled tool")
	assert_eq(RESOURCES.effective_tool("axe", []), "")
	assert_eq(RESOURCES.effective_tool("axe", [{"id": "axe", "n": 1, "durability": 0}]), "", "worn-out tool")

func test_bare_hands_still_refuse_tool_sites_with_a_clear_reason() -> void:
	assert_eq(ACTIONS.refusal_text("equipped_tool_required"), "You need the right tool in hand to gather this.")
