extends "res://tests/test_case.gd"

## SB9 — autoload/progression_state.gd, the flag store behind objective/
## completion/world-state tracking.
##
## Every failure here is one the player would meet as broken story state: a
## gate that stays locked after the key is used, an objective that "unfinds"
## itself, or a flag that quietly does not survive a save. Pure logic, no
## scene tree — the same split test_map_state.gd and test_inventory.gd draw.

const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")

var progression: RefCounted = null


func before_each() -> void:
	progression = PROGRESSION_STATE.new()


func test_a_fresh_store_has_nothing_set() -> void:
	assert_false(progression.has("bridge_unlocked"))
	assert_false(progression.completed("trainer_mira_defeated"))
	assert_eq(progression.all_set(), [])


func test_set_flag_makes_has_true() -> void:
	progression.set_flag("bridge_unlocked")
	assert_true(progression.has("bridge_unlocked"))


func test_completed_is_the_same_query_as_has() -> void:
	progression.set_flag("trainer_mira_defeated")
	assert_true(progression.completed("trainer_mira_defeated"))
	assert_false(progression.completed("trainer_oskar_defeated"))


func test_set_flag_defaults_to_true() -> void:
	progression.set_flag("captive_rescued")
	assert_true(progression.has("captive_rescued"))


func test_set_flag_with_false_clears_it() -> void:
	progression.set_flag("stronghold_unlocked")
	assert_true(progression.has("stronghold_unlocked"))
	progression.set_flag("stronghold_unlocked", false)
	assert_false(progression.has("stronghold_unlocked"))


func test_clearing_an_unset_flag_is_a_harmless_no_op() -> void:
	progression.set_flag("never_set", false)
	assert_false(progression.has("never_set"))


func test_setting_an_already_set_flag_does_not_bump_revision() -> void:
	progression.set_flag("warden_defeated")
	var revision_after_first_set: int = progression.revision
	progression.set_flag("warden_defeated")
	assert_eq(progression.revision, revision_after_first_set)


func test_clearing_an_already_unset_flag_does_not_bump_revision() -> void:
	var before: int = progression.revision
	progression.set_flag("dungeon_cleared", false)
	assert_eq(progression.revision, before)


func test_set_flag_bumps_revision_on_a_real_change() -> void:
	var before: int = progression.revision
	progression.set_flag("dungeon_cleared")
	assert_true(progression.revision > before)


func test_all_set_lists_every_flag_currently_set_and_nothing_cleared() -> void:
	progression.set_flag("a")
	progression.set_flag("b")
	progression.set_flag("c")
	progression.set_flag("b", false)
	var flags: Array = progression.all_set()
	assert_eq(flags.size(), 2)
	assert_true(flags.has("a"))
	assert_true(flags.has("c"))
	assert_false(flags.has("b"))


func test_save_data_lists_exactly_the_set_flags() -> void:
	progression.set_flag("sigil_lower")
	progression.set_flag("sigil_upper")
	var data: Dictionary = progression.save_data()
	var flags: Array = data.get("flags", [])
	assert_eq(flags.size(), 2)
	assert_true(flags.has("sigil_lower"))
	assert_true(flags.has("sigil_upper"))


func test_load_data_round_trips_through_save_data() -> void:
	progression.set_flag("south_bridge_open")
	progression.set_flag("mill_crossing_restored")
	var data: Dictionary = progression.save_data()

	var reloaded: RefCounted = PROGRESSION_STATE.new()
	reloaded.load_data(data)
	assert_true(reloaded.has("south_bridge_open"))
	assert_true(reloaded.has("mill_crossing_restored"))
	assert_false(reloaded.has("never_set"))


func test_load_data_replaces_whatever_was_already_set() -> void:
	progression.set_flag("stale_flag")
	progression.load_data({"flags": ["fresh_flag"]})
	assert_false(progression.has("stale_flag"))
	assert_true(progression.has("fresh_flag"))


func test_load_data_tolerates_an_empty_dictionary() -> void:
	progression.set_flag("will_be_cleared")
	progression.load_data({})
	assert_eq(progression.all_set(), [])


func test_load_data_ignores_non_string_and_empty_entries() -> void:
	progression.load_data({"flags": ["real_flag", 7, "", null, true]})
	assert_eq(progression.all_set(), ["real_flag"])
