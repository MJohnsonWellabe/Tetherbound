extends "res://tests/test_case.gd"

## The Master/Kitchen chooser names each companion: an empty nickname used to
## leave the row blank, and two unnamed creatures of one species read alike.
const PANEL := preload("res://scripts/masters/breakthrough_panel.gd")

func test_unnamed_companions_show_species_and_same_names_carry_their_slot() -> void:
	var cards := [{"nickname": "Bud", "species_id": "terrapup"}, {"nickname": "", "species_id": "bramblebun"},
		{"nickname": "", "species_id": "mudsnout"}, {"nickname": "", "species_id": "bramblebun"}, {"species_id": "pipwing"}]
	assert_eq(PANEL.party_labels(cards), ["Bud", "Bramblebun (2)", "Mudsnout", "Bramblebun (4)", "Pipwing"] as Array[String])

func test_a_nickname_matching_another_row_is_also_disambiguated() -> void:
	var cards := [{"nickname": "Mudsnout", "species_id": "terrapup"}, {"nickname": "  ", "species_id": "mudsnout"}]
	assert_eq(PANEL.party_labels(cards), ["Mudsnout (1)", "Mudsnout (2)"] as Array[String])
