extends "res://tests/test_case.gd"
const RULES := preload("res://scripts/world/water_dock_rules.gd")
const FIELD := preload("res://scripts/world/water_heightfield.gd")
const FLAGS := preload("res://autoload/progression_state.gd")

func _context(action: Dictionary) -> Dictionary:
	var field := FIELD.new()
	return {"realm":"water", "peer":8, "character_id":"dock-worker", "inventory":{"reed_fiber":6,"driftwood":4},
		"position":RULES.action_position(action, FIELD.load_config(), field.height_at)}

func test_dock_actions_require_actual_place_and_fixed_world_prerequisites() -> void:
	for action: Dictionary in RULES.load_data().actions:
		var flags := FLAGS.new()
		var context := _context(action)
		var intent := {"kind":"water_dock_action", "realm":"water", "action_id":str(action.id)}
		assert_true(context.position.is_finite(), str(action.id))
		if not action.requires_flags.is_empty():
			assert_eq(RULES.evaluate(intent, context, flags).code, "prerequisite")
		for flag: String in action.requires_flags:
			flags.set_flag(flag)
		var result := RULES.evaluate(intent, context, flags)
		assert_true(result.ok, str(action.id))
		assert_eq(result.ops[-1].id, str(action.flag))
		context.position += Vector3(20, 0, 0)
		assert_eq(RULES.evaluate(intent, context, flags).code, "too_far")
		context = _context(action)
		context.realm = "stormwood"
		assert_eq(RULES.evaluate(intent, context, flags).code, "wrong_realm")

func test_repair_costs_are_fixed_and_completed_dock_cannot_charge_again() -> void:
	var action: Dictionary = RULES.load_data().actions[0]
	var flags := FLAGS.new()
	flags.set_flag("water_swim_lesson_complete")
	var context := _context(action)
	var intent := {"realm":"water", "action_id":action.id, "cost":{}, "peer":999, "flag":"water_guardian_freed"}
	context.inventory.reed_fiber = 5
	assert_eq(RULES.evaluate(intent, context, flags).code, "materials")
	context.inventory.reed_fiber = 6
	var result := RULES.evaluate(intent, context, flags)
	assert_true(result.ok)
	assert_eq(result.ops.size(), 3)
	for op: Dictionary in result.ops:
		if op.op == "item_take":
			assert_eq(op.peers, [8])
			assert_eq(op.count, int(action.cost[op.item]))
	flags.set_flag(str(action.flag))
	var repeat := RULES.evaluate(intent, context, flags)
	assert_eq(repeat.code, "already_done")
	assert_true(repeat.ops.is_empty())
