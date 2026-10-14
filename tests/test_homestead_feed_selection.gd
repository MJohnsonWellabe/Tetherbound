extends "res://tests/test_case.gd"
const HOME := preload("res://tools/earned_saves/wip_fights/homestead_common.gd")

func test_evolution_label_names_exact_destination() -> void:
	var row := {"nickname": "Mud", "status": "Lv 10", "choice": "evolve", "target": "ashtusk",
		"item_name": "Ground Feast", "choice_required": true}
	assert_eq(HOME.feed_label(row), "Mud · Lv 10 · Evolve to ashtusk")
	assert_false(HOME.feed_label(row) == "Mud · Lv 10 · Evolve to tuskroot")
	assert_false(HOME.feed_label(row) == "Mud · Lv 10 · Evolve to ashtusk_extra")

func test_stay_and_no_offer_labels_bind_the_consumed_feast() -> void:
	var row := {"nickname": "Mud", "status": "Lv 10", "choice": "stay", "target": "",
		"item_name": "Ground Feast", "choice_required": true}
	assert_eq(HOME.feed_label(row), "Mud · Lv 10 · Ground Feast · Stay (permanent this tier)")
	assert_false(HOME.feed_label(row).contains("Water Feast"))
	row.choice_required = false
	assert_eq(HOME.feed_label(row), "Mud · Lv 10 · Ground Feast")

func test_storage_receipt_requires_conserved_transfer_to_the_chest() -> void:
	assert_true(HOME.storage_transfer_matches(8, 0, 3, 11))
	assert_true(HOME.storage_transfer_matches(8, 5, 3, 6))
	assert_false(HOME.storage_transfer_matches(8, 0, 3, 3), "a disappearing Satchel stack is not storage")
	assert_false(HOME.storage_transfer_matches(8, 5, 3, 8), "the chest must receive exactly the removed quantity")
	assert_false(HOME.storage_transfer_matches(8, 8, 3, 3), "no transfer is not success")
	assert_false(HOME.storage_transfer_matches(8, 0, -1, 7), "missing chest state is not proof")
