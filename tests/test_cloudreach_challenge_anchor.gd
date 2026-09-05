extends "res://tests/test_case.gd"

const DIRECTOR := preload("res://scripts/world/cloudreach_scene_encounters.gd")


func test_challenge_does_not_orbit_when_npc_faces_the_player() -> void:
	var body := Transform3D(Basis.IDENTITY,Vector3(395,610,3245))
	var expected := Vector3(396.5,611.05,3245)
	assert_true(DIRECTOR.challenge_anchor_at(body).is_equal_approx(expected))
	for yaw: float in [0.5,1.7,-2.4,PI]:
		body.basis = Basis(Vector3.UP,yaw)
		assert_true(DIRECTOR.challenge_anchor_at(body).is_equal_approx(expected))
	body.origin += Vector3(7,0,-4)
	assert_true(DIRECTOR.challenge_anchor_at(body).is_equal_approx(expected+Vector3(7,0,-4)))
