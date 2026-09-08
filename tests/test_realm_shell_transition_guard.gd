extends "res://tests/test_case.gd"

const REALM_SHELLS := preload("res://scripts/net/realm_shells.gd")
const CLOUDREACH_WORLD := preload("res://scripts/world/cloudreach_world.gd")


class ReadyWorld extends Node:
	var realm := "cloudreach"
	var build_finished := false
	func world_realm() -> String:
		return realm
	func shell_build_complete() -> bool:
		return build_finished


func test_shell_stand_up_waits_for_the_hosts_announced_scene() -> void:
	var scene := ReadyWorld.new()
	assert_false(REALM_SHELLS.scene_ready_for_realm(null, "cloudreach"))
	assert_false(REALM_SHELLS.scene_ready_for_realm(scene, "meadows"),
		"the old current scene must not authorize a replacement shell after announce_realm")
	assert_false(REALM_SHELLS.scene_ready_for_realm(scene, "cloudreach"),
		"a published but unfinished destination must not overlap another world build")
	scene.build_finished = true
	assert_true(REALM_SHELLS.scene_ready_for_realm(scene, "cloudreach"))
	scene.free()


func test_legacy_synchronous_world_is_ready_once_it_matches() -> void:
	var scene := Node.new()
	assert_true(REALM_SHELLS.scene_ready_for_realm(scene, "water"))
	scene.free()


func test_sliced_cloudreach_keeps_authored_landmark_traversal_crowns() -> void:
	var settlement := CLOUDREACH_WORLD.sliced_landmark_crown_specs(
		"cliffhold_settlement", "settlement")
	assert_eq(settlement[0].name, "SettlementWalkableTerrace")
	assert_eq(settlement[0].size, Vector2(48.0, 48.0))

	var observatory := CLOUDREACH_WORLD.sliced_landmark_crown_specs(
		"old_wind_observatory", "landmark")
	assert_eq(observatory[0].name, "ObservatoryWalkableCrown")
	assert_eq(observatory[0].size, Vector2(38.0, 36.0))

	var waterward := CLOUDREACH_WORLD.sliced_landmark_crown_specs(
		"waterward_overlook", "landmark")
	assert_eq(waterward.size(), 2,
		"Waterward must retain both differently sloped route-aligned crowns")
	assert_eq(waterward[0].a, Vector3(-8.0, -2.4, -28.0))
	assert_eq(waterward[0].width, 32.0)
	assert_eq(waterward[1].a, Vector3(27.7, 3.35, 4.3))
	assert_eq(waterward[1].width, 26.0)
