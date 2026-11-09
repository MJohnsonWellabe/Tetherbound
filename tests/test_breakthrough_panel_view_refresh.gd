extends "res://tests/test_case.gd"

## Guest feast-feed race (smoke_net_f48_coop_loop, LANE-MESHY 9 Nov): a guest's
## feed list was built from the pre-cook personal view (no dish in its
## inventory), and the post-cook view never refreshed it, so the Pup row had no
## enabled feed button. view_arrived() now also rebuilds when the arriving view
## differs from the one the list was built from.

const PANEL := preload("res://scripts/masters/breakthrough_panel.gd")

class FakeService extends Node:
	var state: Dictionary = {}
	func view() -> Dictionary:
		return state

class CountingPanel extends "res://scripts/masters/breakthrough_panel.gd":
	var rebuilds := 0
	func _rebuild() -> void:
		rebuilds += 1
		_built_view_key = view_key(_service.call("view"))
		_awaiting_view = (_service.call("view") as Dictionary).is_empty()


func _panel(service: Node, state: Dictionary) -> CountingPanel:
	var panel := CountingPanel.new()
	panel.set("_service", service)
	panel.show()
	(service as FakeService).state = state
	panel._rebuild()
	panel.rebuilds = 0
	return panel


func test_identical_view_keeps_the_shown_list() -> void:
	var service := FakeService.new()
	var panel := _panel(service, {"inventory": [{"id": "berries", "count": 4}]})
	panel.view_arrived()
	assert_eq(panel.rebuilds, 0, "an identical view never rebuilds (no loop, buttons kept)")
	panel.free(); service.free()


func test_newer_view_rebuilds_a_list_built_from_an_older_one() -> void:
	var service := FakeService.new()
	var panel := _panel(service, {"inventory": [{"id": "berries", "count": 4}]})
	service.state = {"inventory": [{"id": "feast_t1_ground", "count": 1}]}
	panel.view_arrived()
	assert_eq(panel.rebuilds, 1, "the post-cook view refreshes the feed list")
	panel.view_arrived()
	assert_eq(panel.rebuilds, 1, "and the same view again does not rebuild twice")
	panel.free(); service.free()


func test_pending_action_and_hidden_panel_never_rebuild() -> void:
	var service := FakeService.new()
	var panel := _panel(service, {"inventory": []})
	panel.set("_pending_action", "feast_feed")
	service.state = {"inventory": [{"id": "feast_t1_ground", "count": 1}]}
	panel.view_arrived()
	assert_eq(panel.rebuilds, 0, "a pending action waits for its own completion rebuild")
	panel.set("_pending_action", "")
	panel.hide()
	panel.view_arrived()
	assert_eq(panel.rebuilds, 0, "a closed panel never rebuilds")
	panel.free(); service.free()


func test_list_built_without_a_view_still_rebuilds() -> void:
	var service := FakeService.new()
	var panel := _panel(service, {})
	service.state = {"inventory": []}
	panel.view_arrived()
	assert_eq(panel.rebuilds, 1)
	assert_eq(PANEL.view_key({}), "")
	panel.free(); service.free()
