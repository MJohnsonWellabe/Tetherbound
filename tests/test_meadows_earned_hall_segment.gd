extends "res://tests/test_case.gd"
const SEGMENT := preload("res://tests/helpers/meadows_earned_hall_segment.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")

class Director extends Node:
	var trainer := "captain_riverwatch"
	func trainer_battle_id() -> String:
		return trainer

class Combat extends Node:
	var creature: RefCounted
	func enemy() -> RefCounted:
		return creature


func test_missing_context_cannot_claim_hall_progress() -> void:
	var observed: Dictionary = await SEGMENT.new().run(null, null, null)
	assert_false(observed.passed)
	assert_false(observed.completed)
	assert_eq(observed.receipts, [])
	assert_false(observed.failures.is_empty())


func test_authored_foot_spine_visits_captains_in_order_then_the_sigil_gate() -> void:
	var terrain := SEGMENT._read(SEGMENT.TERRAIN)
	var road := SEGMENT.departure_spine(terrain)
	assert_eq(road[0], Vector2(-152, 4235), "begin beyond the paid Mill crossing")
	assert_eq(road[-1], Vector2(0, 7560))
	var previous := -1
	for id: String in SEGMENT.CAPTAIN_IDS:
		var spec: Dictionary = SEGMENT.TRAINERS.trainer(id)
		var position := Vector2(spec.position[0], spec.position[1])
		var at := SEGMENT.nearest_index(road, position)
		assert_true(at > previous)
		assert_eq(road[at], position, "actual captain lies on the authored spine")
		previous = at
	assert_true(SEGMENT.nearest_index(road, Vector2(63.6, 7400)) > previous)
	assert_eq(SEGMENT.departure_spine({}), [])
	var broken := terrain.duplicate(true)
	for row: Dictionary in broken.trail.bands:
		if row.id == "band4_upper_meadows_ironwood":
			row.points[0] = [99, 99]
	assert_eq(SEGMENT.departure_spine(broken), [], "do not silently bridge disconnected road bands")


func test_gauntlet_resolves_current_trainers_and_requires_each_owned_shutter() -> void:
	var config := SEGMENT._read(SEGMENT.HALL_CONFIG)
	var stages := SEGMENT.gauntlet_path(config)
	assert_eq(stages.size(), 3)
	assert_eq([stages[0].trainer, stages[1].trainer, stages[2].trainer],
		["stronghold_patrol", "stronghold_courtyard", "stronghold_elite"])
	assert_eq([stages[0].from, stages[1].from, stages[2].from], ["outer_works", "courtyard", "tether_approach"])
	assert_eq(stages[-1].to, "warden_arena", "the Warden and legendary chamber remain subsequent work")
	for index in 3:
		var missing := config.duplicate(true)
		missing.passages[index].erase("gated_by_flag")
		assert_eq(SEGMENT.gauntlet_path(missing), [], "missing passage lock must fail: " + str(index))
		var wrong_guard := config.duplicate(true)
		wrong_guard.gauntlet[index].trainer = "warden_aldis"
		assert_eq(SEGMENT.gauntlet_path(wrong_guard), [], "a different guard cannot unlock this chamber")
	assert_eq(SEGMENT.gauntlet_path({}), [])


func test_three_sigil_spend_is_exact_and_needs_actual_disabled_leaf() -> void:
	var before := {"field_sigil": 1, "ridge_sigil": 1, "river_sigil": 1}
	var after := {"field_sigil": 0, "ridge_sigil": 0, "river_sigil": 0}
	assert_true(SEGMENT.sigil_paid_receipt(before, after, true, true, true))
	assert_false(SEGMENT.sigil_paid_receipt(before, before, true, true, true))
	assert_false(SEGMENT.sigil_paid_receipt(before, after, false, true, true))
	assert_false(SEGMENT.sigil_paid_receipt(before, after, true, false, true))
	assert_false(SEGMENT.sigil_paid_receipt(before, after, true, true, false))
	for id: String in SEGMENT.SIGILS:
		var unspent := after.duplicate()
		unspent[id] = 1
		assert_false(SEGMENT.sigil_paid_receipt(before, unspent, true, true, true))
		var preowned := before.duplicate()
		preowned[id] = 2
		assert_false(SEGMENT.sigil_paid_receipt(preowned, after, true, true, true))
	assert_true(SEGMENT.keys_match(["river_sigil", "ridge_sigil", "field_sigil"]))
	assert_false(SEGMENT.keys_match(["river_sigil", "river_sigil", "field_sigil"]))
	assert_false(SEGMENT.keys_match(["field_sigil"]))
	var rewarded := {}
	for id: String in SEGMENT.CAPTAIN_IDS:
		var items := SEGMENT.reward_items(SEGMENT.TRAINERS.trainer(id).reward)
		for key: String in SEGMENT.SIGILS:
			if items.has(key):
				rewarded[key] = int(rewarded.get(key, 0)) + int(items[key])
	assert_eq(rewarded, before, "the three current captains really pay exactly these gate keys")


func test_gate_waypoints_follow_live_rotation_and_require_opposite_road_sides() -> void:
	var at := Transform3D(Basis(Vector3.UP, deg_to_rad(-28.6)), Vector3(63.6, 8, 7400))
	var points := SEGMENT.gate_crossing_points(at, Vector2(80, 7370), Vector2(20, 7480))
	assert_eq(points.size(), 2)
	var centre := Vector2(at.origin.x, at.origin.z)
	# Vector2 uses float32: one ULP at world z=7400 is 0.000488m.
	assert_almost_eq(points[0].distance_to(centre), 6.0, 0.0005)
	assert_almost_eq(points[1].distance_to(centre), 6.0, 0.0005)
	assert_true((points[1] - points[0]).normalized().dot(Vector2(at.basis.z.x, at.basis.z.z)) > 0.999)
	var reverse := SEGMENT.gate_crossing_points(at, Vector2(20, 7480), Vector2(80, 7370))
	assert_true(reverse[0].is_equal_approx(points[1]))
	assert_true(reverse[1].is_equal_approx(points[0]))
	assert_eq(SEGMENT.gate_crossing_points(at, Vector2(80, 7370), Vector2(85, 7360)), [])


func test_shutter_receipt_checks_fixture_mesh_and_real_collision_fields_fail_closed() -> void:
	var hold := Node3D.new()
	var flag := "defeated_stronghold_patrol"
	assert_false(SEGMENT.shutter_receipt(hold, flag, true), "missing physical shutter must never look open")
	var body := StaticBody3D.new()
	body.name = "BlastShutterBody_" + flag
	hold.add_child(body)
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	mesh.name = "BlastShutter_" + flag
	hold.add_child(mesh)
	assert_true(SEGMENT.shutter_receipt(hold, flag, false))
	assert_false(SEGMENT.shutter_receipt(hold, flag, true))
	shape.disabled = true
	assert_false(SEGMENT.shutter_receipt(hold, flag, true), "collision alone cannot claim the visible door opened")
	mesh.visible = false
	assert_true(SEGMENT.shutter_receipt(hold, flag, true))
	assert_false(SEGMENT.shutter_receipt(hold, flag, false))
	shape.shape = null
	assert_false(SEGMENT.shutter_receipt(hold, flag, true))
	hold.free()


func test_room_axis_and_door_waypoints_share_one_existing_budget() -> void:
	assert_eq(SEGMENT.room_frames_remaining(0), 600)
	assert_eq(SEGMENT.room_frames_remaining(170), 430)
	assert_eq(SEGMENT.room_frames_remaining(599), 1)
	assert_eq(SEGMENT.room_frames_remaining(600), 0)
	assert_eq(SEGMENT.room_frames_remaining(601), 0)
	assert_eq(SEGMENT.room_frames_remaining(-1), 0)
	assert_eq(SEGMENT.ENTRANCE_FRAMES, 950)
	assert_true(SEGMENT.captain_within_deadline(8999))
	assert_false(SEGMENT.captain_within_deadline(9000))


func test_named_admission_rejects_another_trainer_and_out_of_order_opponents() -> void:
	var segment := SEGMENT.new()
	var director := Director.new()
	var combat := Combat.new()
	var creature := CREATURE.new()
	creature.species_id = "mosshell"
	creature.level = 13
	combat.creature = creature
	segment._director = director
	segment._combat = combat
	segment._captain_active = true
	segment._named_trainer = "captain_riverwatch"
	segment._captain_spec = SEGMENT.TRAINERS.trainer(segment._named_trainer)
	director.trainer = "relay_captain"
	segment._on_entered()
	assert_eq(segment._captain_rounds, 0)
	assert_false(segment.result().failures.is_empty())
	segment._failures.clear()
	director.trainer = "captain_riverwatch"
	segment._on_entered()
	assert_eq(segment._captain_rounds, 1)
	assert_eq(segment.result().failures, [])
	segment._on_entered()
	assert_eq(segment._captain_rounds, 1, "a duplicate first opponent cannot count as the next round")
	assert_false(segment.result().failures.is_empty())
	segment._failures.clear()
	creature.species_id = "trailpup"
	creature.level = 14
	segment._on_entered()
	assert_eq(segment._captain_rounds, 2)
	assert_eq(segment.result().failures, [])
	director.free()
	combat.free()
