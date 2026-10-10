extends "res://tools/capture_lookdev_route.gd"

## CPU-side frame-time probe over the fixed F26 lookdev route. Same world
## mount, same InputMap walk, same live clock/weather; it only drops the
## renderer requirement and the PNG stills so a hosted runner can compare
## physics/process time of two commits on one machine. Not an fps claim.
## --biome=<route> --source-commit=<sha> --output=user://<fresh>
## Optional --ablate=wilds: stop every wild creature's physics first, to
## attribute how much of the physics step the wild bodies cost.
## Optional --attribute=process|physics: before the route, stand at its start
## and switch each script's nodes off in turn for a few frames, printing how
## much of the step that script's nodes were costing (largest first).
## Optional --ab-lod=<creature_physics_lod.json block> --rounds=N: walk the
## route 2N times in one process, alternating that block's `enabled` off/on,
## so both sides are measured on the same runner in the same scene.
var _ablate := ""
var _attribute := ""
var _ab_lod := ""
var _rounds := 2
const ATTRIBUTE_FRAMES := 60


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--biome="):
			_biome_id = arg.trim_prefix("--biome=")
		elif arg.begins_with("--source-commit="):
			_source_commit = arg.trim_prefix("--source-commit=")
		elif arg.begins_with("--output="):
			_output_dir = arg.trim_prefix("--output=").trim_suffix("/")
		elif arg.begins_with("--ablate="):
			_ablate = arg.trim_prefix("--ablate=")
		elif arg.begins_with("--attribute="):
			_attribute = arg.trim_prefix("--attribute=")
		elif arg.begins_with("--ab-lod="):
			_ab_lod = arg.trim_prefix("--ab-lod=")
		elif arg.begins_with("--rounds="):
			_rounds = maxi(1, int(arg.trim_prefix("--rounds=")))
	var config: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROUTES_PATH))
	if not config is Dictionary or not config.get("routes", {}).has(_biome_id) or _output_dir == "":
		print("PHYSICS PROBE needs a known --biome and --output")
		quit(2)
		return
	_capture = config.capture
	_route = config.routes[_biome_id]
	_preset = "Low"
	_presets.assign(["Low"])
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir)) != OK:
		quit(1)
		return
	seed(int(_capture.seed))
	if not await _mount_production_world() or not _prepare_capture_shell():
		print("PHYSICS PROBE mount failed: %s" % [_failures])
		quit(1)
		return
	if _ablate == "wilds":
		node_added.connect(_stop_wild)
		_stop_wilds(_world)
	if _attribute in ["process", "physics"]:
		await _attribute_scripts(_attribute == "physics")
	if _ab_lod != "":
		await _run_ab()
		quit(0 if _failures.is_empty() else 1)
		return
	await _capture_route_case()
	_print_summary()
	quit(0 if _failures.is_empty() else 1)


func _run_ab() -> void:
	var lod: Dictionary = load("res://scripts/creatures/creature_body.gd").call("physics_lod_config")
	if not lod.get(_ab_lod) is Dictionary:
		_failures.append("unknown creature_physics_lod block " + _ab_lod)
		return
	var block: Dictionary = lod[_ab_lod]
	var original: bool = bool(block.get("enabled", false))
	var totals := {false: [0.0, 0.0, 0], true: [0.0, 0.0, 0]}
	for r in _rounds:
		for enabled: bool in [false, true]:
			block["enabled"] = enabled
			await _capture_route_case()
			_print_summary("%s=%s round=%d " % [_ab_lod, enabled, r])
			totals[enabled][0] += _mean(_column("physics_ms"))
			totals[enabled][1] += _mean(_column("process_ms"))
			totals[enabled][2] += 1
	block["enabled"] = original
	for enabled: bool in [false, true]:
		var n := maxi(1, int(totals[enabled][2]))
		print("PHYSICS PROBE AB biome=%s %s=%s rounds=%d physics_mean=%.3f process_mean=%.3f"
			% [_biome_id, _ab_lod, enabled, n, totals[enabled][0] / n, totals[enabled][1] / n])


func _column(key: String) -> Array[float]:
	var out: Array[float] = []
	for sample: Dictionary in _samples:
		out.append(float(sample[key]))
	return out


func _attribute_scripts(physics: bool) -> void:
	var start := _route_point(_route.start)
	_player.global_position = start + Vector3.UP * float(_capture.floor_clearance_m)
	_player.velocity = Vector3.ZERO
	_rig.global_position = _player.global_position
	for frame in int(_capture.warmup_frames):
		await process_frame
	var groups := {}
	for node: Node in _all_nodes(_world):
		var on := node.is_physics_processing() if physics else node.is_processing()
		var script: Script = node.get_script() as Script
		if on and script != null:
			var key := script.resource_path if script.resource_path != "" else "<inner>" + str(node.get_class())
			if not groups.has(key):
				groups[key] = []
			groups[key].append(node)
	# Each script's off window is bracketed by on windows on both sides, so a
	# slow drift in the scene's own cost does not read as a saving.
	var baseline := await _mean_step(physics)
	var before := baseline
	var rows: Array = []
	for key: String in groups:
		_switch(groups[key], physics, false)
		var without := await _mean_step(physics)
		_switch(groups[key], physics, true)
		var after := await _mean_step(physics)
		rows.append([(before + after) * 0.5 - without, key, groups[key].size()])
		before = after
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	print("PHYSICS PROBE ATTRIBUTE %s baseline=%.3f scripts=%d" % ["physics" if physics else "process", baseline, rows.size()])
	for row: Array in rows.slice(0, 25):
		print("PHYSICS PROBE ATTRIBUTE saved_ms=%.3f nodes=%d script=%s" % [row[0], row[2], row[1]])


## The encounter director re-arms wild physics every frame, so a wild body is
## held off through its process mode instead.
func _switch(nodes: Array, physics: bool, on: bool) -> void:
	for node: Node in nodes:
		if not is_instance_valid(node):
			continue
		if physics:
			node.set_physics_process(on)
			if node.has_method("defer_engage"):
				node.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
		else:
			node.set_process(on)


func _mean_step(physics: bool) -> float:
	var total := 0.0
	for frame in ATTRIBUTE_FRAMES:
		await process_frame
		total += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS if physics else Performance.TIME_PROCESS)
	return total * 1000.0 / ATTRIBUTE_FRAMES


func _route_still(_label: String) -> void:
	pass


func _stop_wilds(node: Node) -> void:
	_stop_wild(node)
	for child: Node in node.get_children():
		_stop_wilds(child)


func _stop_wild(node: Node) -> void:
	if node is CharacterBody3D and node.has_method("defer_engage"):
		node.set_physics_process(false)
		node.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)


func _print_summary(label: String = "") -> void:
	var physics := _column("physics_ms")
	var process := _column("process_ms")
	var wall := _column("wall_ms")
	var wilds := 0
	var active := 0
	for node: Node in _all_nodes(_world):
		if node is CharacterBody3D and node.has_method("defer_engage"):
			wilds += 1
			active += 1 if node.is_physics_processing() else 0
	print(("PHYSICS PROBE " + label + "biome=%s ablate=%s samples=%d waypoints=%d/%d wilds=%d active=%d "
		% [_biome_id, _ablate, _samples.size(), _waypoints_reached, _route.waypoints.size(), wilds, active]
		+ "physics_mean=%.3f physics_p95=%.3f process_mean=%.3f process_p95=%.3f wall_mean=%.3f failures=%s"
		% [_mean(physics), _p95(physics), _mean(process), _p95(process), _mean(wall), _failures]))


func _all_nodes(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child: Node in node.get_children():
		out.append_array(_all_nodes(child))
	return out


static func _mean(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += value
	return total / values.size()


static func _p95(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[mini(sorted.size() - 1, int(sorted.size() * 0.95))]
