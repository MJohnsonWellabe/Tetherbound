extends "res://tests/test_case.gd"

## F18-reported co-op gap: an ordinary guest shrine press did nothing. A
## guest's request must carry the refreshed character revision (personal view
## requested and completed first), and the host's later saved decision must
## reach the player. Detached hall and session doubles; no transport proof
## (the F18 net smoke covers the live path once the portal runtime is on).
const HALL := preload("res://scripts/world/crossing_hall.gd")

class SessionDouble extends Node:
	signal homestead_personal_view_completed
	signal homestead_action_completed(op: String, intent: Dictionary, result: Dictionary)
	var host := false
	var runtime := true
	var answer_view := true
	var calls: Array[String] = []
	var revision := -1
	var sent_revision := -2
	func is_host() -> bool: return host
	func portal_runtime_ready() -> bool: return runtime
	func homestead_personal_view() -> Dictionary:
		calls.append("view")
		if answer_view:
			revision = 7
			homestead_personal_view_completed.emit()
		return {"registry_revision": revision}
	func request_relic_hang(biome: String) -> Dictionary:
		calls.append("hang:" + biome)
		sent_revision = revision
		if host:
			return {"ok": false, "code": "personal_relic_required", "resolved": true}
		return {"ok": false, "resolved": false, "code": "awaiting_saved_decision"}

class GameDouble extends Node:
	var session: Node
	var messages: Array[String] = []
	func push_world_message(text: String) -> void: messages.append(text)


func _rig(host: bool) -> Array:
	var game := GameDouble.new()
	var session := SessionDouble.new()
	session.host = host
	game.session = session
	return [HALL.new(), game, session]


func test_guest_refreshes_view_before_sending_and_hears_the_host_decision() -> void:
	var rig := _rig(false)
	var hall: Node3D = rig[0]
	var game: GameDouble = rig[1]
	var session: SessionDouble = rig[2]
	hall.call("hang_relic", "meadows", game)
	assert_eq(session.calls, ["view", "hang:meadows"] as Array[String], "the view is refreshed before the request")
	assert_eq(session.sent_revision, 7, "the request carries the refreshed revision, never -1")
	assert_true(game.messages.is_empty(), "no message while the host decides")
	session.homestead_action_completed.emit("relic_hang", {"biome": "meadows"}, {"ok": false, "code": "personal_relic_required"})
	assert_eq(game.messages, ["You have no relic for this shrine yet."] as Array[String], "the host's refusal reaches the guest")
	hall.call("hang_relic", "meadows", game)
	assert_eq(session.calls.size(), 4, "a decided press does not lock later presses")
	hall.free()
	game.free()
	session.free()


func test_guest_with_no_view_reply_does_not_send_a_stale_request() -> void:
	var rig := _rig(false)
	var session: SessionDouble = rig[2]
	session.answer_view = false
	rig[0].call("hang_relic", "meadows", rig[1])
	assert_eq(session.calls, ["view"] as Array[String], "nothing is sent until the view arrives")
	rig[0].free()
	rig[1].free()
	session.free()


func test_host_sends_directly_and_surfaces_refusal() -> void:
	var rig := _rig(true)
	var hall: Node3D = rig[0]
	var game: GameDouble = rig[1]
	var session: SessionDouble = rig[2]
	hall.call("hang_relic", "meadows", game)
	assert_eq(session.calls, ["hang:meadows"] as Array[String])
	assert_eq(game.messages, ["You have no relic for this shrine yet."] as Array[String])
	# The same host display may arrive on join, reload or later polling. It
	# must repaint the physical relic without inventing a local hang/receipt.
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/crossing_hall.json"))
	hall.set("_config", config.duplicate(true))
	hall.call("_build_pedestal", config.pedestals[0])
	var baseline: Node3D = hall.get("_pedestals").meadows
	assert_true(baseline.get_node_or_null(^"MeadowsRelicDisplay") == null, "shipping candidate remains off")
	baseline.free()
	hall.call("_build_pedestal", config.pedestals[2])
	var cloud_baseline: Node3D = hall.get("_pedestals").cloudreach
	assert_true(cloud_baseline.get_node_or_null(^"CloudreachRelicDisplay") == null, "Cloudreach shipping candidate remains off")
	cloud_baseline.free()
	hall.get("_pedestals").clear()
	config.meadows_relic_visual.enabled = true
	config.cloudreach_relic_visual.enabled = true
	hall.set("_config", config)
	hall.call("_build_pedestal", config.pedestals[0])
	var pedestal: Node3D = hall.get("_pedestals").meadows
	var relic := pedestal.get_node(^"MeadowsRelicDisplay") as Node3D
	var children: int = pedestal.get_child_count()
	hall.call("_build_pedestal", config.pedestals[2])
	var cloud_pedestal: Node3D = hall.get("_pedestals").cloudreach
	var wings := cloud_pedestal.get_node(^"CloudreachRelicDisplay") as Node3D
	var cloud_children: int = cloud_pedestal.get_child_count()
	assert_eq(wings.get_child_count(), 6, "reuse all six existing Cloudreach feathers")
	var feather_index := 0
	for side: float in [-1.0, 1.0]:
		for feather in 3:
			var piece := wings.get_child(feather_index) as MeshInstance3D
			assert_eq(piece.position, Vector3(side * (0.12 + feather * 0.12), 0.15 - feather * 0.07, 0), "existing feather position")
			assert_eq(piece.scale, Vector3(0.13, 0.45 - feather * 0.05, 0.12), "existing feather scale")
			assert_true(is_equal_approx(piece.rotation.z, side * 0.65), "existing feather roll")
			var sphere := piece.mesh as SphereMesh
			assert_eq(sphere.radius, 0.5)
			assert_eq(sphere.height, 1.0)
			assert_eq(sphere.radial_segments, 12)
			assert_eq(sphere.rings, 6)
			feather_index += 1
	assert_false(relic.visible, "empty pedestal has no phantom reward")
	assert_false(wings.visible, "empty Cloudreach pedestal has no phantom reward")
	var saved := {"shrine_display":{"meadows":true}}
	var before: Dictionary = saved.duplicate(true)
	hall.call("apply_display", saved)
	assert_true(relic.visible, "saved host hang produces a physical display")
	assert_false(wings.visible, "a Meadows hang does not display Cloudreach")
	assert_eq(saved, before, "presentation never mutates the host display")
	hall.call("apply_display", saved)
	assert_eq(pedestal.get_child_count(), children, "replayed view does not duplicate the relic")
	assert_eq(session.calls, ["hang:meadows"] as Array[String], "repainting never sends a hang")
	var cloud_saved := {"shrine_display":{"cloudreach":true}}
	var cloud_before: Dictionary = cloud_saved.duplicate(true)
	hall.call("apply_display", cloud_saved)
	assert_true(wings.visible, "saved Cloudreach host hang displays the Wings")
	assert_false(relic.visible, "Cloudreach host state does not retain a stale Meadows display")
	assert_eq(cloud_saved, cloud_before, "Cloudreach presentation never mutates the host view")
	hall.call("apply_display", cloud_saved)
	assert_eq(cloud_pedestal.get_child_count(), cloud_children, "replayed Cloudreach view does not duplicate the Wings")
	assert_eq(session.calls, ["hang:meadows"] as Array[String], "Cloudreach repaint never sends a hang")
	hall.call("apply_display", {})
	assert_false(relic.visible, "an empty restored view removes the stale display")
	assert_false(wings.visible, "empty restored host state clears Cloudreach display")
	assert_false(bool(cloud_pedestal.get_meta("relic_displayed")))
	assert_false(bool(pedestal.get_meta("relic_displayed")))
	hall.free()
	game.free()
	session.free()


func test_disabled_portal_runtime_explains_instead_of_sending() -> void:
	var rig := _rig(false)
	var game: GameDouble = rig[1]
	var session: SessionDouble = rig[2]
	session.runtime = false
	rig[0].call("hang_relic", "meadows", game)
	assert_true(session.calls.is_empty(), "no request while the shrine runtime is off")
	assert_eq(game.messages.size(), 1)
	rig[0].free()
	game.free()
	session.free()
