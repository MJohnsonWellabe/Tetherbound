extends "res://tests/test_case.gd"

## LANE-THINGS, 13 Nov 2026: CombatHUD's prompt row must not repeat a world
## verb during a fight. In realms with no SequenceDirector the interaction
## arbiter stays live in a fight, so a harvest node beside the fighters kept
## winning it and "Gather Reef Stone" drew across the Tidewake fight HUD.
const HUD := "res://scripts/ui/combat_hud.gd"


func _draw_prompt_body() -> String:
	var code := FileAccess.get_file_as_string(HUD)
	var start := code.find("func _draw_prompt() -> void:")
	assert_true(start >= 0, "the prompt row is still drawn by _draw_prompt")
	return code.substr(start, code.find("\nfunc ", start + 1) - start)


func test_the_row_draws_only_lines_the_encounter_director_owns() -> void:
	var body := _draw_prompt_body()
	assert_true(body.contains("if not bool(_director.call(\"owns_active_prompt\")):"),
		"the ownership check runs in and out of a fight")
	assert_false(body.contains("if not fighting and not bool(_director.call(\"owns_active_prompt\")):"),
		"the check is no longer skipped while fighting")


func test_the_hud_script_still_parses() -> void:
	var script: GDScript = load(HUD)
	assert_true(script != null and script.can_instantiate())
