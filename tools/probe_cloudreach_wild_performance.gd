extends SceneTree

## Bounded production-world CPU/frame diagnostic, not a frame-budget acceptance.
## All authored sites stay configured. The player is a noncolliding stationary
## fixture; ordinary 60Hz wild AI/physics is never accelerated or reconfigured.
## Run alone, without --fixed-fps (that flag decouples simulation from wall time):
## godot --headless --path . --script tools/probe_cloudreach_wild_performance.gd
## -- --output=res://ralph/reports/CLOUDREACH-PRODUCTION-INTEGRATION-0905/wild-performance-headless.json
const WORLD := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const SITES := ["lower_cliff_foragers", "causeway_watch", "ravine_wind"]
const PHASES := ["sleeping", "active_idle", "roaming_uninstrumented", "roaming_instrumented"]
var output := "res://ralph/reports/CLOUDREACH-PRODUCTION-INTEGRATION-0905/wild-performance-headless.json"
var seed_value := 1594702062
var warmup_seconds := 3.0
var sample_seconds := 10.0
var world: Node3D
var player: CharacterBody3D
var director: Node
var camera: Camera3D
var members: Array = []
var measuring := false
var process_ms: Array[float] = []
var physics_ms: Array[float] = []
var frame_ms: Array[float] = []
var previous_frame_usec := 0
var sampled_physics_ticks := 0
var active_body_ticks := 0
var moving_body_ticks := 0
var max_displacement := 0.0
var report := {"phases": [], "failures": []}


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		elif arg.begins_with("--seed="): seed_value = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--warmup-seconds="): warmup_seconds = maxf(1, float(arg.trim_prefix("--warmup-seconds=")))
		elif arg.begins_with("--sample-seconds="): sample_seconds = maxf(3, float(arg.trim_prefix("--sample-seconds=")))
	_run.call_deferred()


func check(ok: bool, label: String) -> void:
	if not ok:
		report.failures.append(label)
		push_error("WILD PERFORMANCE: " + label)


func frames(count: int) -> void:
	for i in count:
		await physics_frame


func _sample_process() -> void:
	if not measuring: return
	var now := Time.get_ticks_usec()
	if previous_frame_usec > 0:
		frame_ms.append((now - previous_frame_usec) / 1000.0)
	previous_frame_usec = now
	process_ms.append(float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0)


func _sample_physics() -> void:
	if not measuring: return
	sampled_physics_ticks += 1
	physics_ms.append(float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0)
	for wild: CharacterBody3D in members:
		if wild.is_physics_processing():
			active_body_ticks += 1
			if Vector2(wild.velocity.x, wild.velocity.z).length() > 0.1:
				moving_body_ticks += 1
		max_displacement = maxf(max_displacement, wild.global_position.distance_to(wild.get("home")))


func distribution(values: Array[float]) -> Dictionary:
	if values.is_empty(): return {"count": 0}
	var ordered := values.duplicate()
	ordered.sort()
	var total := 0.0
	for value in ordered: total += value
	var result := {"count": ordered.size(), "mean": total / ordered.size(), "max": ordered[-1]}
	for percentile in [50, 90, 95, 99]:
		result["p%d" % percentile] = ordered[clampi(ceili(ordered.size() * percentile / 100.0) - 1, 0, ordered.size() - 1)]
	return result


func supported(wild: Node3D) -> bool:
	var position := wild.global_position
	var ground: Vector3 = director.call("_wild_support", position, float(wild.call("body_radius")) + 0.25, wild)
	return ground.is_finite() and position.is_finite() and absf(position.y - ground.y) < 0.8


func save_report() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		check(false, "cannot write probe output " + output)
		return
	file.store_string(JSON.stringify(report, "\t"))


func reset_residents(id: String) -> void:
	# Fixture resets ONLY between windows; same real body/instance/home and a
	# reproducible wander RNG. Never reset an active fight or change AI tuning.
	for ordinal in members.size():
		var wild: CharacterBody3D = members[ordinal]
		check(not wild.get("engaged"), id + " has no engaged body to reset")
		if wild.get("engaged"): continue
		wild.call("place_on_ground", wild.get("home"))
		wild.velocity = Vector3.ZERO
		wild.set("_requested", Vector3.ZERO)
		wild.set("_target", wild.get("home"))
		wild.set("_pause_left", 0.01)
		var rng: RandomNumberGenerator = wild.get("_rng")
		rng.seed = hash("wild_performance:%s:%d:%d" % [id, seed_value, ordinal])


func phase(id: String, name: String, centre: Vector3) -> void:
	director.call("set_wild_diagnostics_enabled", false)
	reset_residents(id)
	var height := 300.0 if name == "sleeping" else (2.0 if name == "active_idle" else 30.0)
	player.global_position = centre + Vector3.UP * height
	var instrumented := name != "roaming_uninstrumented"
	director.call("set_wild_diagnostics_enabled", instrumented)
	await frames(ceili(warmup_seconds * Engine.physics_ticks_per_second))
	# Include neither placement nor warmup in measured support counters.
	director.call("reset_wild_diagnostics")
	process_ms.clear(); physics_ms.clear(); frame_ms.clear()
	previous_frame_usec = 0
	sampled_physics_ticks = 0
	active_body_ticks = 0
	moving_body_ticks = 0
	max_displacement = 0
	var start_positions: Array = []
	for wild: Node3D in members: start_positions.append(str(wild.global_position))
	print("WILD PERFORMANCE PHASE_START " + JSON.stringify({"site": id, "phase": name, "pid": OS.get_process_id(), "ticks_usec": Time.get_ticks_usec()}))
	var started := Time.get_ticks_usec()
	measuring = true
	await frames(ceili(sample_seconds * Engine.physics_ticks_per_second))
	measuring = false
	var wall := (Time.get_ticks_usec() - started) / 1000000.0
	var counters: Dictionary = director.call("wild_diagnostics_snapshot")
	director.call("set_wild_diagnostics_enabled", false)
	var simulated := sampled_physics_ticks / float(Engine.physics_ticks_per_second)
	var data := {"site": id, "phase": name, "warmup_sim_seconds": warmup_seconds,
		"sample_wall_seconds": wall, "sample_sim_seconds": simulated,
		"physics_ticks": sampled_physics_ticks, "residents": members.size(),
		"active_body_ticks": active_body_ticks, "moving_body_ticks": moving_body_ticks,
		"maximum_displacement_from_home_m": max_displacement, "start_positions": start_positions,
		"process_time_ms": distribution(process_ms), "physics_time_ms": distribution(physics_ms),
		"frame_interval_ms": distribution(frame_ms), "diagnostics": counters,
		"support_ms_per_physics_tick": counters.support_usec / 1000.0 / maxi(1, sampled_physics_ticks),
		"support_ms_per_wall_second": counters.support_usec / 1000.0 / maxf(0.001, wall),
		"rays_per_sim_second": counters.rays / maxf(0.001, simulated), "bodies": []}
	for wild: Node3D in members:
		var safe := supported(wild) # Assertion outside the measurement window.
		check(safe, id + "/" + name + " ends grounded: " + str(wild.name))
		data.bodies.append({"name": str(wild.name), "node_id": wild.get_instance_id(),
			"instance_id": wild.get("instance").get_instance_id(), "home": str(wild.get("home")),
			"position": str(wild.global_position), "species": wild.get("species_id"),
			"level": wild.get("instance").get("level"), "supported": safe})
	check(process_ms.size() >= 60 and sampled_physics_ticks >= 120, id + "/" + name + " has enough frame samples")
	if name == "sleeping": check(active_body_ticks == 0, id + " sleeping control is really asleep")
	else: check(active_body_ticks >= sampled_physics_ticks * members.size() - members.size(), id + "/" + name + " all residents active")
	if name.begins_with("roaming"):
		check(moving_body_ticks > 20 and max_displacement > 0.6, id + "/" + name + " contains actual roaming")
	if not instrumented:
		check(counters.support_calls == 0 and counters.rays == 0 and counters.support_usec == 0, "disabled diagnostics do no counter/timing work")
	elif name == "roaming_instrumented":
		check(counters.support_calls > 0 and counters.rays > 0 and counters.support_usec > 0, id + " exact support diagnostics populated")
	report.phases.append(data)
	save_report()
	print("WILD PERFORMANCE PHASE_END " + JSON.stringify(data))


func _run() -> void:
	var started := Time.get_ticks_usec()
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	Engine.max_fps = 60
	var game := root.get_node("Game")
	game.set("save_system", SAVE.new("user://cloudreach_wild_performance_%d" % OS.get_process_id()))
	game.call("reset_for_new_game")
	game.set("current_realm", "cloudreach")
	game.set("world_seed", seed_value)
	OS.set_environment("TB_WORLD_SEED", str(seed_value))
	game.get("party").call("add", SPECIES.spawn("sparkit"))
	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	player = world.get_node("Player")
	player.collision_layer = 0
	player.set_physics_process(false)
	player.visible = false
	director = world.get_node("EncounterDirector")
	camera = Camera3D.new()
	world.add_child(camera)
	camera.current = true
	await frames(12)
	check(not director.call("wild_diagnostics_snapshot").enabled, "production diagnostics default off")
	check(director.get("encounter_config").wild_sites.size() == 6, "all six authored wild sites retained")
	report["metadata"] = {"pid": OS.get_process_id(), "seed": director.call("world_seed"),
		"display_server": DisplayServer.get_name(), "engine": Engine.get_version_info().string,
		"boot_wall_seconds": (Time.get_ticks_usec() - started) / 1000000.0,
		"physics_hz": Engine.physics_ticks_per_second, "max_fps": Engine.max_fps,
		"time_scale": Engine.time_scale, "warmup_seconds": warmup_seconds, "sample_seconds": sample_seconds,
		"scope": "same world and camera per site, actual six-site config, real residents, fixed seed and between-window home/RNG reset",
		"measurement": "Engine Performance.TIME_PROCESS/TIME_PHYSICS_PROCESS plus support wall timer; NOT isolated OS CPU or GPU time",
		"overhead": "instrumented support includes two clock reads, counters and a script ray proxy; compare roaming_uninstrumented; sampler overhead common to all windows",
		"prerequisite": "Engage requires a deployed ally; this roaming-only fixture intentionally leaves its party undeployed",
		"phase_order": PHASES}
	process_frame.connect(_sample_process)
	physics_frame.connect(_sample_physics)
	for id: String in SITES:
		var site: Dictionary = director.call("find_id", director.get("encounter_config").wild_sites, id)
		var raw: Array = site.position
		var centre := Vector3(raw[0], raw[1], raw[2])
		player.global_position = centre + Vector3.UP * 30
		camera.global_position = centre + Vector3(14, 11, 20)
		camera.look_at(centre + Vector3.UP * 1.2)
		await frames(8)
		members = director.get("_site_members").get(id, [])
		check(members.size() == int(site.count), id + " admits actual configured population")
		if members.size() != int(site.count): continue
		var before: Array = []
		for wild: Node3D in members: before.append([wild.get_instance_id(), wild.get("instance").get_instance_id(), wild.get("home")])
		for phase_name: String in PHASES: await phase(id, phase_name, centre)
		for ordinal in members.size():
			var wild: Node3D = members[ordinal]
			check(before[ordinal] == [wild.get_instance_id(), wild.get("instance").get_instance_id(), wild.get("home")], id + " retains exact resident identity across phases")
	director.call("set_wild_diagnostics_enabled", false)
	report["complete"] = true
	report["total_wall_seconds"] = (Time.get_ticks_usec() - started) / 1000000.0
	save_report()
	print("CLOUDREACH WILD PERFORMANCE COMPLETE: %d phases, %d failures; %s" % [report.phases.size(), report.failures.size(), output])
	world.queue_free()
	await process_frame
	quit(0 if report.failures.is_empty() else 1)
