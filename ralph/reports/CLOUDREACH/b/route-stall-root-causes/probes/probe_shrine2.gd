extends "/tmp/claude-0/probe/probe_stalls.gd"

func _shrine() -> void:
	var target := Vector3(1121.0, 1050.0, 2938.5)
	var pose := Vector3(1099.003, 1051.301, 2941.399)
	await _place(pose)
	var dirs := {"recorded": Vector3(4.957, 0, -0.653), "+x": Vector3(5,0,0), "-z": Vector3(0,0,-5), "+x-z45": Vector3(3.5,0,-3.5), "-x": Vector3(-5,0,0)}
	for k in dirs:
		for lift in [0.0, 0.35]:
			var params := PhysicsTestMotionParameters3D.new()
			params.from = player.global_transform.translated(Vector3.UP * lift)
			params.motion = dirs[k] / 60.0
			params.max_collisions = 6
			var res := PhysicsTestMotionResult3D.new()
			var hit := PhysicsServer3D.body_test_motion(player.get_rid(), params, res)
			var hs := []
			for j in res.get_collision_count(): hs.append("%s n=%s" % [str((res.get_collider(j) as Node).get_path()), str(res.get_collision_normal(j))])
			print("PROBE2 dir=%s lift=%.2f hit=%s frac=%.3f cols=%s" % [k, lift, hit, res.get_travel().length() / (dirs[k] / 60.0).length(), hs])
	print("PROBE2 entombed_at=", player.call("_entombed_at", player.global_transform))
	# Walk with each geometry variant
	var pillar := world.find_child("SkyShrineHeartstone", true, false).get_node("SkyPillar") as Node3D
	var cs: CollisionShape3D = pillar.get_node("Collision").get_child(0)
	for variant in ["as_built", "pillar_starts_at_dais_top", "pillar_cylinder"]:
		if variant == "pillar_starts_at_dais_top":
			var b := BoxShape3D.new(); b.size = Vector3(2.2, 18.7, 2.2)
			cs.shape = b; cs.position = Vector3(0, 0.65, 0)
		elif variant == "pillar_cylinder":
			var c := CylinderShape3D.new(); c.radius = 1.1; c.height = 20.0
			cs.shape = c; cs.position = Vector3.ZERO
		await _place(pose)
		var zero := 0
		for f in 240:
			var off := target - player.global_position
			if Vector2(off.x, off.z).length() < 0.75: break
			_steer(off, clampf(Vector2(off.x,off.z).length()/2,0.22,1))
			await _frames(1)
			if player.get_last_motion().length() < 0.001: zero += 1
		print("PROBE2 variant=%s end=%s zero_motion_frames=%d" % [variant, player.global_position, zero])

func _place(p: Vector3) -> void:
	_release()
	await _frames(5)
	player.global_position = p
	player.velocity = Vector3.ZERO
	await _frames(10)
