extends "res://tests/test_case.gd"

## One reader per lesson card: f49's walk-time confirmer stands down while
## f20's witnessed lesson reader is active, so both never press confirm.
const F49 := preload("res://tests/helpers/f49_portal_travel.gd")
const F20 := preload("res://tests/helpers/f20_portal_travel.gd")

func test_f49_confirms_cards_unless_a_subclass_reads_them() -> void:
	assert_false(F49.new(null, null)._lessons_read_by_caller())

func test_f20_reads_cards_itself_only_while_its_reader_is_active() -> void:
	var travel = F20.new(null, null)
	assert_false(travel._lessons_read_by_caller())
	travel._lesson_active = true
	assert_true(travel._lessons_read_by_caller())
