extends TestCase

const DRIVER := preload("res://tools/gate_f/bedroll_placement_driver.gd")

class Fixture extends RefCounted:
	var state := {"ok": true, "realm": "meadows", "pending_build": "bedroll",
		"player_position": Vector3(0, 0, 3), "camera_yaw_deg": 0.0,
		"ghost_id": "bedroll", "ghost_position": Vector3.ZERO, "ghost_ok": true, "ghost_reason": "",
		"buildings": [{"uid": "tent-1", "id": "tent", "realm": "meadows", "position": Vector3.ZERO, "yaw_deg": 0.0}]}
	var steps: Array = []
	var presses := 0
	var releases := 0
	var mode := "success"
	func read() -> Dictionary:
		return state.duplicate(true)
	func step(kind: String, target: Vector3) -> Dictionary:
		steps.append([kind, target])
		if mode == "stuck":
			return {"ok": true}
		if kind == "walk":
			state.player_position = target
		if kind == "face":
			var toward: Vector3 = target - state.player_position
			state.camera_yaw_deg = rad_to_deg(atan2(-toward.x, -toward.z))
		if mode == "tent_removed":
			state.buildings = []
		return {"ok": true}
	func press() -> Dictionary:
		presses += 1
		if mode == "refused":
			return {"ok": false, "why": "physical binding unavailable"}
		if mode == "ignored":
			return {"ok": true}
		state.buildings.append({"uid": "bedroll-new", "id": "bedroll",
			"realm": "stormwood" if mode == "wrong_realm" else "meadows",
			"position": Vector3(8, 0, 0) if mode == "outside" else Vector3.ZERO, "yaw_deg": 0.0})
		return {"ok": true}
	func release() -> void:
		releases += 1


func test_success_requires_new_committed_bedroll_and_balances_wait_units() -> void:
	var fixture := Fixture.new()
	fixture.state.player_position = Vector3(7, 0, 4)
	fixture.state.camera_yaw_deg = 70.0
	var result := await DRIVER.execute(fixture.read, fixture.step, fixture.press, fixture.release, 80)
	assert_true(result.ok)
	assert_eq(result.tent_uid, "tent-1")
	assert_eq(result.bedroll_uid, "bedroll-new")
	assert_eq(fixture.presses, 1)
	assert_eq(result.physics_frames, fixture.steps.size() + 2)
	assert_eq(result.process_frames, 2)
	assert_true(fixture.releases >= 2)
	assert_true(int(result.physics_frames) <= int(DRIVER.budget(80).physics_frames))
	assert_true(fixture.steps.any(func(row: Array) -> bool: return row[0] == "walk"))
	assert_true(fixture.steps.any(func(row: Array) -> bool: return row[0] == "face"))


func test_input_receipt_without_correct_new_readback_never_passes() -> void:
	for mode in ["ignored", "outside", "wrong_realm", "refused"]:
		var fixture := Fixture.new()
		fixture.mode = mode
		var result := await DRIVER.execute(fixture.read, fixture.step, fixture.press, fixture.release, 40)
		assert_false(result.ok, mode)
		assert_eq(fixture.presses, 1, mode)
		assert_true(int(result.physics_frames) <= 40, mode)
		assert_eq(result.physics_frames, fixture.steps.size() + 2, mode)
		assert_true(fixture.releases >= 2, mode)


func test_existing_bedroll_is_not_proof_that_ignored_input_placed_one() -> void:
	var fixture := Fixture.new()
	fixture.mode = "ignored"
	fixture.state.buildings.append({"uid": "old-bed", "id": "bedroll", "realm": "meadows", "position": Vector3.ZERO, "yaw_deg": 0.0})
	var result := await DRIVER.execute(fixture.read, fixture.step, fixture.press, fixture.release, 40)
	assert_false(result.ok)
	assert_eq(result.bedroll_uid, "")


func test_four_stances_share_one_budget_without_fourfold_expansion() -> void:
	var fixture := Fixture.new()
	fixture.mode = "stuck"
	fixture.state.player_position = Vector3(50, 0, 50)
	var result := await DRIVER.execute(fixture.read, fixture.step, fixture.press, fixture.release, 80)
	assert_false(result.ok)
	assert_eq(result.stances, 4)
	assert_eq(result.physics_frames, 58) # 80 minus 20 readback and 2 tap, shared.
	assert_eq(fixture.steps.size(), 58)
	assert_eq(result.process_frames, 0)
	assert_eq(fixture.presses, 0)


func test_invalid_ghost_removed_tent_and_cost_abort_never_press() -> void:
	for mode in ["invalid_ghost", "tent_removed", "interrupted", "not_armed"]:
		var fixture := Fixture.new()
		fixture.mode = mode
		if mode == "invalid_ghost":
			fixture.state.ghost_ok = false
			fixture.state.ghost_reason = "not enough materials"
		if mode == "not_armed":
			fixture.state.pending_build = "campfire"
		var result := await DRIVER.execute(fixture.read, fixture.step, fixture.press, fixture.release, 80,
			func() -> bool: return mode == "interrupted")
		assert_false(result.ok, mode)
		assert_eq(fixture.presses, 0, mode)
		assert_true(fixture.releases >= 2, mode)


func test_canonical_record_rejects_removed_foreign_or_unmatched_nodes() -> void:
	var record := {"id": "tent", "uid": "paid-tent", "realm": "meadows", "position": [0, 0, 0]}
	assert_true(DRIVER.canonical(record, "tent", "meadows", Vector3.ZERO, "meadows"))
	assert_false(DRIVER.canonical(record, "tent", "stormwood", Vector3.ZERO, "meadows"))
	assert_false(DRIVER.canonical(record, "tent", "meadows", Vector3(3, 0, 0), "meadows"))
	assert_false(DRIVER.canonical(record, "bedroll", "meadows", Vector3.ZERO, "meadows"))
	record.removed = true
	assert_false(DRIVER.canonical(record, "tent", "meadows", Vector3.ZERO, "meadows"))
	record.removed = false
	record.uid = ""
	assert_false(DRIVER.canonical(record, "tent", "meadows", Vector3.ZERO, "meadows"))
