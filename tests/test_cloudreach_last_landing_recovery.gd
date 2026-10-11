extends "res://tests/test_case.gd"

## F06#2: a Cloudreach fall with no fresh standing reading (a glide that sank
## into the cloud sea) returns the trainer to Fly's last verified landing
## through `recover_to_anchor`, and falls through to the camp/entry ladder only
## when Fly holds no usable landing. Real-scene path:
## tests/smoke_cloudreach_fall_recovery.gd (stale glide phase).
const RUNTIME := preload("res://scripts/world/cloudreach_world_runtime.gd")


class FlyStub extends Node:
	var answer := true
	var reasons: Array[String] = []
	func recover_to_anchor(reason: String) -> bool:
		reasons.append(reason)
		return answer


func test_a_held_landing_recovers_through_fly() -> void:
	var body := Node3D.new()
	var fly := FlyStub.new()
	fly.name = "FlyController"
	body.add_child(fly)
	assert_true(RUNTIME.recover_to_last_landing(body), "Fly's verified landing takes the fall")
	assert_eq(fly.reasons.size(), 1, "one recovery, through Fly's own anchor ray")
	fly.answer = false
	assert_false(RUNTIME.recover_to_last_landing(body), "an anchor whose ground no longer answers leaves the ladder to act")
	body.free()


func test_no_fly_controller_leaves_the_ladder() -> void:
	var body := Node3D.new()
	assert_false(RUNTIME.recover_to_last_landing(body), "a body without Fly has no landing to return to")
	assert_false(RUNTIME.recover_to_last_landing(null), "a freed body is not recovered")
	body.free()
