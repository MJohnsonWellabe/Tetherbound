extends SceneTree

## Bounded renderer/import/budget preview, not an earned combat-path witness.
## Run only after F16 and after restoring references in the lane checkout.
## --effect=stone_throw|fireball|sky_lightning --rank=1..5 --count=1..4
const LIBRARY := preload("res://scripts/vfx/move_effect_library.gd")
const BUDGET := preload("res://scripts/vfx/move_effect_budget.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var arena := Node3D.new()
	root.add_child(arena)
	current_scene = arena
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(24.0, 24.0)
	floor.mesh = plane
	var ground := StandardMaterial3D.new()
	ground.albedo_color = Color("#526346")
	floor.material_override = ground
	arena.add_child(floor)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -25, 0)
	sun.light_energy = 1.2
	arena.add_child(sun)
	var camera := Camera3D.new()
	arena.add_child(camera)
	camera.position = Vector3(0, 5, 14)
	camera.look_at(Vector3(0, 1.5, 0), Vector3.UP)
	camera.current = true
	var effect_id := "stone_throw"
	var rank := 1
	var simultaneous := 4
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--effect="): effect_id = arg.trim_prefix("--effect=")
		if arg.begins_with("--rank="): rank = clampi(int(arg.trim_prefix("--rank=")), 1, 5)
		if arg.begins_with("--count="): simultaneous = clampi(int(arg.trim_prefix("--count=")), 1, 4)
	if LIBRARY.resolve({"archetype": effect_id}, rank).is_empty():
		push_error("Unknown preview archetype")
		quit(1)
		return
	# In-memory diagnostic opt-in. The shipped data remains flag-off.
	LIBRARY.config()["enabled"] = true
	var arrivals := [0]
	var nodes: Array[Node3D] = []
	for i in simultaneous:
		var z := float(i) * 2.0 - float(simultaneous - 1)
		var node := LIBRARY.launch(arena, Vector3(-3, 1.5, z), Vector3(3, 1.5, z),
			{"archetype": effect_id}, {"action_id": "preview:%d" % i, "encounter_id": "preview",
			"travel_seconds": 0.7, "mastery_rank": rank, "seed": 21 + i, "target_ground": Vector3(3, 0.04, z)})
		if node == null:
			quit(1)
			return
		node.connect("arrived", func() -> void: arrivals[0] += 1)
		nodes.append(node)
	var peak_slots := 0
	var peak_frame_ms := 0.0
	var frame_count := 0
	var output := "user://move-effects-preview"
	DirAccess.make_dir_recursive_absolute(output)
	var started := Time.get_ticks_usec()
	while Time.get_ticks_usec() - started < 1500000:
		await process_frame
		frame_count += 1
		peak_slots = maxi(peak_slots, BUDGET.used("preview"))
		peak_frame_ms = maxf(peak_frame_ms, float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0)
		if DisplayServer.get_name() != "headless" and frame_count in [8, 20, 35]:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/%s-r%d-f%d.png" % [output, effect_id, rank, frame_count])
	var passed := int(arrivals[0]) == simultaneous and peak_slots <= int(LIBRARY.config().encounter_particle_cap) and BUDGET.used("preview") == 0
	print("F25 bounded preview scope=synthetic_arena effect=%s rank=%d arrivals=%d/%d peak_slots=%d cpu_process_peak_ms=%.2f fps=%d renderer=%s; no acceptance/Medium hardware claim" % [effect_id, rank, int(arrivals[0]), simultaneous, peak_slots, peak_frame_ms, int(Performance.get_monitor(Performance.TIME_FPS)), RenderingServer.get_current_rendering_method()])
	quit(0 if passed else 1)
