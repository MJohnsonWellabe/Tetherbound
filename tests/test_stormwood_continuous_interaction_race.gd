extends "res://tests/test_case.gd"

const SOURCE_PATH := "res://tests/smoke_stormwood_continuous.gd"


func test_roaming_wild_button_edge_is_resolved_without_counting_target_activation() -> void:
	var source := FileAccess.get_file_as_string(SOURCE_PATH).replace("\r\n", "\n")
	assert_true(source.contains("_activated_provider_id == director.get_instance_id()"))
	assert_true(source.contains("and bool(manager.call(\"is_fighting\"))"))
	assert_true(source.contains("_fight_current_encounter(\"%s competing wild\" % label)"))
	assert_true(source.contains("_ensure_usable_ally(\"retrying %s\" % label)"))
	assert_true(source.contains("break\n\t\t\t\t\t\t_fail(\"%s press activated competing provider"))
	assert_true(source.find("_activated_provider_id == wanted_id") \
		< source.find("_activated_provider_id == director.get_instance_id()"))


func test_requested_provider_remains_the_only_success_path() -> void:
	var source := FileAccess.get_file_as_string(SOURCE_PATH).replace("\r\n", "\n")
	var start := source.find("func _activate_node(")
	var finish := source.find("func _on_arbiter_activated", start)
	assert_true(start >= 0)
	assert_true(finish > start)
	var method := source.substr(start, finish - start)
	assert_eq(method.count("return true"), 1)
	assert_true(method.contains("if _activated_provider_id == wanted_id:\n\t\t\t\t\t\treturn true"))
	assert_true(method.contains("every other competitor remains a hard failure"))


func test_wrapper_binds_a_unique_scratch_save_before_yield_and_reset() -> void:
	var source := FileAccess.get_file_as_string(SOURCE_PATH).replace("\r\n", "\n")
	assert_true(source.contains("TEST_SAVE_DIR_PREFIX := \"user://stormwood_continuous_chapter_entry\""))
	assert_true(source.contains("OS.get_process_id()"),
		"two separate smoke processes must not share a scratch save tree")
	assert_true(source.contains("Time.get_ticks_usec()"),
		"parallel/repeated runs must not reuse a scratch world or character journal")
	var bind := source.find("game.set(\"save_system\", SAVE_GAME.new(test_save_dir))")
	var first_yield := source.find("await process_frame", source.find("func _run()"))
	var reset := source.find("game.call(\"reset_for_new_game\")", source.find("func _run()"))
	assert_true(bind >= 0)
	assert_true(bind < first_yield, "scratch saver must bind before the harness yields")
	assert_true(bind < reset, "scratch saver must bind before the harness resets live state")
