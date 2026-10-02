extends "res://tests/test_case.gd"

## Detached preview composition controls. Paid host admission, physical
## placement and heartbeat timing require ROOT's native run.
const PLACER := preload("res://scripts/build/build_placer.gd")
const RULES := preload("res://scripts/build/station_rules.gd")

class PersonalViewDouble extends Node:
	var calls := 0
	var view: Dictionary = {"redesign_character": {"attachment_recipes": []}}
	func homestead_personal_view() -> Dictionary:
		calls += 1
		return view.duplicate(true)

class GameDouble extends Node:
	var session: Node

func test_base_station_ghosts_do_not_refresh_admission_or_send_personal_view_requests() -> void:
	var game: Node = GameDouble.new()
	var producer: Node = PersonalViewDouble.new()
	game.set("session", producer)
	var cfg := RULES.config()
	for id: String in RULES.STATION_IDS:
		var attachment := RULES.attachment(cfg, id)
		assert_true(attachment.is_empty())
		assert_true(PLACER._station_preview_personal_view(game, attachment).is_empty())
	assert_eq(producer.get("calls"), 0)
	game.free()
	producer.free()

func test_attachment_preview_still_reads_current_personal_recipe_and_refuses_missing_unlock() -> void:
	var game: Node = GameDouble.new()
	var producer: Node = PersonalViewDouble.new()
	game.set("session", producer)
	var cfg := RULES.config()
	cfg.runtime_enabled = true # Disclosed detached policy input; shipping data unchanged.
	var attachment := RULES.attachment(cfg, "forge_tidewake")
	assert_false(attachment.is_empty())
	if not attachment.is_empty():
		var first := PLACER._station_preview_personal_view(game, attachment)
		assert_eq(producer.get("calls"), 1)
		assert_eq(RULES.placement(cfg, [], "forge_tidewake", "meadows", Vector3(-16,0,25), 0,
			first.redesign_character, "b1").code, "attachment_recipe_unknown")
		producer.get("view").redesign_character.attachment_recipes.append("forge_tidewake")
		var next := PLACER._station_preview_personal_view(game, attachment)
		assert_eq(producer.get("calls"), 2)
		assert_eq(next.redesign_character.attachment_recipes, ["forge_tidewake"])
		assert_eq(first.redesign_character.attachment_recipes, [], "preview retains a detached original view")
	game.free()
	producer.free()
