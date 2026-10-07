extends "res://tests/test_case.gd"

## F18 #4 (multiplayer-wide 37312829965): a guest's accepted portal/Home Key
## arrival confirms the travel-baseline reset to its owner-passive replay, as
## a fly landing does. Without it the guest's next discovery was refused as
## travel_baseline_mismatch and every later owner-gated action with it.
const ARRIVAL := preload("res://scripts/net/foundation_portal_arrival.gd")

class Lifecycle extends Node:
	var body: Node3D
	func remote_body(_peer: int) -> Node3D: return body

class SessionProbe extends Node:
	var confirmed: Array = []
	func owner_passive_travel_reset_confirmed(peer: int, realm: String, anchor: Vector3, arrival_endpoint: bool = false) -> void:
		confirmed.append([peer, realm, anchor, arrival_endpoint])

func test_an_accepted_guest_arrival_confirms_the_travel_reset_at_its_body() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		# Default discovery runs before the engine installs its main loop.
		# Re-enter this same case through the existing runner's lifecycle mode;
		# its exact native assertion count also rejects an aborted test body.
		if OS.get_cmdline_user_args().has("--initialized"):
			assert_true(false, "initialized runner must supply the actual SceneTree")
			return
		var output: Array = []
		var code := OS.execute(OS.get_executable_path(), ["--headless", "--path",
			ProjectSettings.globalize_path("res://"), "--script",
			ProjectSettings.globalize_path("res://tests/run_tests.gd"), "--", "--initialized",
			"--only=test_portal_arrival_travel_reset.gd::test_an_accepted_guest_arrival_confirms_the_travel_reset_at_its_body"], output, true)
		var combined := "\n".join(output).replace("\r", "")
		var lines := combined.split("\n")
		print(combined)
		assert_eq(code, 0, combined)
		assert_eq(lines.count("1 tests, 7 assertions, 0 failed"), 1, "all seven original native assertions: " + combined)
		assert_eq(lines.count("  ok    test_portal_arrival_travel_reset.gd :: test_an_accepted_guest_arrival_confirms_the_travel_reset_at_its_body"),
			1, "exactly the requested native case completed: " + combined)
		for marker: String in ["SCRIPT ERROR", "ERROR:", "Parse Error", "ObjectDB instances", "resources still in use", "instances were leaked"]:
			assert_false(combined.contains(marker), combined)
		return
	var session := SessionProbe.new()
	var composition := Node.new()
	composition.name = "FoundationComposition"
	session.add_child(composition)
	var lifecycle := Lifecycle.new()
	lifecycle.name = "TravelLifecycle"
	composition.add_child(lifecycle)
	var body := Node3D.new()
	lifecycle.add_child(body)
	body.position = Vector3(12.0, 1.5, -4.0)
	lifecycle.body = body
	# The production proof reads global_position. Keep this existing fixture
	# inside the actual tree so the coordinate read is valid and nonzero.
	tree.root.add_child(session)
	ARRIVAL._confirm_travel_reset(session, 7, "meadows")
	assert_eq(session.confirmed.size(), 1)
	assert_eq(session.confirmed[0][0], 7)
	assert_eq(session.confirmed[0][1], "meadows")
	assert_eq(session.confirmed[0][2], body.global_position, "the host's actual live body anchor")
	assert_eq(session.confirmed[0][2], Vector3(12.0, 1.5, -4.0), "never an out-of-tree zero transform")
	assert_true(session.confirmed[0][3], "an arrival-sourced proof")
	lifecycle.body = null
	ARRIVAL._confirm_travel_reset(session, 7, "meadows")
	assert_eq(session.confirmed.size(), 1, "no body, no proof")
	session.free()
