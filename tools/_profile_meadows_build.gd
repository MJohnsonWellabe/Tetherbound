extends SceneTree
## Realm-load profiling: builds the Meadows world once, as a joining guest's
## realm swap does (headless, like the two-peer proofs), and quits. Timings
## land in user://boot_log.txt via BOOT_LOG.phase.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	await process_frame
	var builds := 2 if OS.get_cmdline_user_args().has("--rebuild") else 1
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--harvest-stream-radius="): # performance.json override, this process only
			preload("res://scripts/world/performance_config.gd").config()["harvest_point_stream_radius_m"] = float(arg.get_slice("=", 1))
	for build in builds:
		await _build_once(build)
	quit(0)


func _build_once(build: int) -> void:
	var started := Time.get_ticks_msec()
	var world := (load("res://scenes/world/meadows_playground.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	while not (world.has_method("shell_build_complete") and bool(world.call("shell_build_complete"))):
		await process_frame
		if Time.get_ticks_msec() - started > 600000: break
	print("MEADOWS_BUILD_MS build=%d %d" % [build, Time.get_ticks_msec() - started])
	for node: Node in world.find_children("Bank*", "MeshInstance3D", true, false):
		var mesh := (node as MeshInstance3D).mesh
		if mesh != null and mesh.get_surface_count() > 0:
			print("BANK_DIGEST build=%d %s %d" % [build, node.name, hash(var_to_bytes(mesh.surface_get_arrays(0)))])
	var vegetation := world.get_node_or_null(^"Vegetation")
	if vegetation != null:
		var keys: Array = (vegetation.get("_harvest_lookup") as Dictionary).keys()
		keys.sort()
		var collision := 0
		var collision_digest := 0
		for batch: Dictionary in vegetation.get("_collision_batches"):
			for placement: Dictionary in batch["placements"]:
				collision += 1
				collision_digest = hash([collision_digest, placement["position"]])
		var positions := 0
		var positions_digest := 0
		var mesh_ids: Array = (vegetation.get("_instance_positions") as Dictionary).keys()
		mesh_ids.sort()
		for id: Variant in mesh_ids:
			var arr: PackedVector3Array = vegetation.get("_instance_positions")[id]
			positions += arr.size()
			positions_digest = hash([positions_digest, id, hash(var_to_bytes(arr))])
		print("VEG_DIGEST harvest_keys=%d keys_hash=%d harvest_points=%d solid=%d collision=%d collision_hash=%d positions=%d positions_hash=%d" % [
			keys.size(), hash(keys), int(vegetation.get("_harvest_points")), int(vegetation.get("_solid")),
			collision, collision_digest, positions, positions_digest])
	world.queue_free()
	for _frame in 30:
		await process_frame
