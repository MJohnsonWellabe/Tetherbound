extends "res://tests/test_case.gd"

const SAVE_FIXTURE := preload("res://tests/test_save_format.gd")
var fixture: RefCounted


func before_each() -> void:
	fixture = SAVE_FIXTURE.new()
	fixture.before_each()


func after_each() -> void:
	fixture.after_each()


func test_completed_legacy_save_recovers_only_earned_rewards() -> void:
	var written: RefCounted = fixture._game(false)
	written.progression.set_flag("defeated_warden")
	assert_true(fixture.saver.save(written, 1))
	var path: String = fixture.saver.slot_path(1)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	data["version"] = 16
	data.erase("realm_hearts")
	data.erase("current_realm")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	var restored: RefCounted = fixture._game(false)
	assert_true(fixture.saver.load_slot(restored, 1))
	assert_true(restored.progression.has("realm_key_cloudreach"))
	assert_true(restored.realm_hearts.is_earned("meadows", restored.progression))
	assert_false(restored.realm_hearts.is_placed("meadows", restored.progression))
	assert_false(restored.progression.has("realm_gate_cloudreach_unlocked"))
	assert_eq(restored.realm_hearts.active_id(), "")
	assert_eq(restored.realm_hearts.stamina_capacity_multiplier(), 1.0)
	var revision: int = restored.progression.revision
	fixture.saver._reconcile_meadows_realm_rewards(restored.progression)
	assert_eq(restored.progression.revision, revision, "reconciliation must be idempotent")
	assert_true(fixture.saver.save(restored, 1))
	assert_true(fixture.saver.load_slot(restored, 1))
	assert_eq(restored.realm_hearts.active_id(), "")
	assert_false(restored.realm_hearts.is_placed("meadows", restored.progression))


func test_already_upgraded_completed_save_is_repaired_without_losing_selection() -> void:
	var written: RefCounted = fixture._game(false)
	written.progression.set_flag("defeated_warden")
	written.progression.set_flag("realm_heart_meadows_earned")
	written.realm_hearts.place("meadows", written.progression)
	written.realm_hearts.activate("meadows", written.progression)
	assert_true(fixture.saver.save(written, 1))
	var restored: RefCounted = fixture._game(false)
	assert_true(fixture.saver.load_slot(restored, 1))
	assert_true(restored.progression.has("realm_key_cloudreach"))
	assert_eq(restored.realm_hearts.active_id(), "meadows")
	assert_eq(restored.realm_hearts.stamina_capacity_multiplier(), 2.0)


func test_earned_unplaced_heart_and_key_survive_disk_round_trip() -> void:
	var written: RefCounted = fixture._game(false)
	written.progression.set_flag("realm_key_cloudreach")
	written.progression.set_flag("realm_heart_meadows_earned")
	assert_true(fixture.saver.save(written, 1))
	var restored: RefCounted = fixture._game(false)
	assert_true(fixture.saver.load_slot(restored, 1))
	assert_true(restored.progression.has("realm_key_cloudreach"))
	assert_true(restored.realm_hearts.is_earned("meadows", restored.progression))
	assert_false(restored.realm_hearts.is_placed("meadows", restored.progression))
	assert_eq(restored.realm_hearts.active_id(), "")


func test_unfinished_meadows_save_does_not_receive_warden_rewards() -> void:
	var written: RefCounted = fixture._game(false)
	assert_true(fixture.saver.save(written, 1))
	assert_true(fixture.saver.load_slot(written, 1))
	assert_false(written.progression.has("realm_key_cloudreach"))
	assert_false(written.realm_hearts.is_earned("meadows", written.progression))
