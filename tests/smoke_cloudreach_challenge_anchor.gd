extends SceneTree

const DIRECTOR := preload("res://scripts/world/cloudreach_scene_encounters.gd")

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var body := Node3D.new()
	root.add_child(body)
	body.position = Vector3(395,610,3245)
	var prompt := Node3D.new()
	body.add_child(prompt)
	DIRECTOR.sync_challenge_anchor(prompt,body)
	var expected := Vector3(396.5,611.05,3245)
	var passed := prompt.global_position.is_equal_approx(expected)
	for yaw: float in [0.5,1.7,-2.4,PI]:
		body.rotation.y = yaw
		await process_frame
		passed = passed and prompt.global_position.is_equal_approx(expected)
	body.position += Vector3(7,0,-4)
	DIRECTOR.sync_challenge_anchor(prompt,body)
	passed = passed and prompt.global_position.is_equal_approx(expected+Vector3(7,0,-4))
	body.queue_free()
	await process_frame
	print("CLOUDREACH CHALLENGE ANCHOR %s: real top-level transform survives NPC facing and tracks relocation" % ("PASS" if passed else "FAIL"))
	quit(0 if passed else 1)
