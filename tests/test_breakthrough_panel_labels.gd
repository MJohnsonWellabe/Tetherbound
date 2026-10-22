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

## A long cook list ran past the view and down-focus stopped at the 14th row.
## Rows chain explicitly, skip disabled rows, and the scroll follows focus.
func test_rows_chain_focus_past_the_visible_list() -> void:
	var panel = PANEL.new()
	panel._ready()
	for index in 20:
		panel._button("Row %d" % index, func() -> void: pass, index == 5)
	panel._link_focus()
	var rows: Array = panel._list.get_children().filter(func(n: Node) -> bool: return n is Button and not n.disabled)
	assert_eq(rows.size(), 19)
	for index in rows.size() - 1:
		assert_eq(rows[index].get_node(rows[index].focus_neighbor_bottom), rows[index + 1])
		assert_eq(rows[index + 1].get_node(rows[index + 1].focus_neighbor_top), rows[index])
	assert_true((panel.get_child(1) as ScrollContainer).follow_focus)
	panel.free()

## The controller's B is menu_cancel; the chooser used to close only on the
## built-in ui_cancel, which has no pad binding, so a pad could not leave it.
func test_controller_cancel_closes_the_chooser() -> void:
	for action: StringName in [&"menu_cancel", &"ui_cancel"]:
		var press := InputEventAction.new()
		press.action = action
		press.pressed = true
		assert_true(PANEL.is_cancel(press), str(action))
	var accept := InputEventAction.new()
	accept.action = &"ui_accept"
	accept.pressed = true
	assert_false(PANEL.is_cancel(accept))
