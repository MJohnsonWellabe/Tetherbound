extends "res://tests/test_case.gd"

## A speaker identity may carry `portrait_replaces` (village_npcs.gd
## variant_identity, LANE-BEINGS 13 Nov 2026): its plate stands in only for
## lines drawn with that base plate, so other speakers keep their own faces.
## Without the key the identity plate covers every line, as before.

const PANEL := preload("res://scripts/ui/dialogue_panel.gd")


func test_the_panel_scopes_a_replacing_plate_to_its_base_plate() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/dialogue_panel.gd")
	assert_true(source.contains("portrait_replaces"), "the panel reads portrait_replaces")
	assert_true(source.contains("if not replaces.is_empty() and str(line.get(\"portrait\", \"\")) != replaces:"),
		"only lines drawn with the replaced plate take the identity plate")
	assert_true(source.contains("var replaces := str(_identity.get(\"portrait_replaces\", \"\"))"),
		"an identity without the key keeps covering every line")
