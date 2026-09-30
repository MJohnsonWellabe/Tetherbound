extends SceneTree

## Actual production effect-node batch in a synthetic arena. No combat, HP or
## result fixture mutation. Cannot certify the required four-creature fight.
## --batch=identities|mastery|library|profile|clock --out=<directory> --medium
const LIBRARY := preload("res://scripts/vfx/move_effect_library.gd")
const LEGACY := preload("res://scripts/vfx/legacy_move_travel.gd")
const BUDGET := preload("res://scripts/vfx/move_effect_budget.gd")
const CREATURE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
var _arena: Node3D
var _target: CharacterBody3D
var _moves: Dictionary
var _scenarios: Dictionary
var _records: Array[Dictionary] = []
var _failures: Array[String] = []
var _out := "user://move-effects-preview"
var _batch := "identities"
var _medium := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--batch="): _batch = arg.trim_prefix("--batch=")
		if arg.begins_with("--out="): _out = arg.trim_prefix("--out=")
		if arg == "--medium": _medium = true
	if _batch not in ["identities", "mastery", "library", "profile", "clock"]:
		push_error("Unknown effect batch"); quit(1); return
	if _batch in ["identities", "mastery", "profile"] and DisplayServer.get_name() == "headless":
		push_error("Identity/performance evidence requires a native display"); quit(1); return
	_scenarios = JSON.parse_string(FileAccess.get_file_as_string("res://assets/vfx/proof_scenarios.json"))
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/moves/moves.json"))
	_moves = data.moves
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_out)):
		push_error("Use a fresh output directory; existing evidence preserved"); quit(1); return
	if DirAccess.make_dir_recursive_absolute(_out) != OK:
		push_error("Cannot create output"); quit(1); return
	root.size = Vector2i(1920, 1080)
	_arena = Node3D.new()
	root.add_child(_arena)
	current_scene = _arena
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(24, 24)
	floor.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#526346")
	floor.material_override = material
	_arena.add_child(floor)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -25, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	_arena.add_child(sun)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#839bb3")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#b8c9da")
	environment.ambient_light_energy = 0.65
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	_arena.add_child(world_environment)
	var camera := Camera3D.new()
	_arena.add_child(camera)
	camera.position = Vector3(0, 5, 14)
	camera.look_at(Vector3(0, 1.5, 0), Vector3.UP)
	camera.current = true
	if _batch in ["identities", "mastery"]:
		# Production creature scene/script/model, with no encounter, AI or HP
		# transaction. This establishes visible target coverage only.
		_target = CREATURE.instantiate() as CharacterBody3D
		_target.set_script(CREATURE_BODY)
		_arena.add_child(_target)
		_target.call("setup", str(_scenarios.get("target_species", "mudsnout")))
		_target.set_physics_process(false)
		_target.position = Vector3(3, 0, 0)
		_target.rotation.y = -PI * 0.5
		if not bool(_target.call("has_model")):
			push_error("Identity evidence requires the actual production creature model"); quit(1); return
	if _medium:
		if RenderingServer.get_current_rendering_method() != "forward_plus":
			push_error("Medium requires actual Forward+"); quit(1); return
		var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/art.json"))
		var cfg: Dictionary = art.get("graphics_presets", {}).get("Medium", {})
		if cfg.is_empty():
			push_error("Authored Medium missing; lookdev dependency required"); quit(1); return
		environment.volumetric_fog_enabled = bool(cfg.volumetric_fog)
		environment.ssao_enabled = bool(cfg.ssao)
		environment.ssil_enabled = bool(cfg.ssil)
		environment.glow_enabled = bool(cfg.glow)
		environment.volumetric_fog_density = float(cfg.volumetric_fog_density)
		environment.volumetric_fog_length = float(cfg.volumetric_fog_length)
		environment.volumetric_fog_sky_affect = float(cfg.volumetric_fog_sky_affect)
		var shadow: Dictionary = art.graphics_presets.shadow_quality_options[cfg.shadow_quality]
		RenderingServer.directional_shadow_atlas_set_size(int(shadow.atlas_size), false)
		RenderingServer.directional_soft_shadow_filter_set_quality(int(shadow.filter_quality) as RenderingServer.ShadowQuality)
		var distance: Dictionary = art.graphics_presets.draw_distance_options[cfg.draw_distance]
		root.mesh_lod_threshold = float(distance.lod_threshold)
		camera.far = float(distance.far)
	LIBRARY.config()["enabled"] = true # Process-local diagnostic opt-in only.
	for i in int(_scenarios.warmup_frames): await process_frame
	if _batch == "identities":
		for case: Dictionary in _scenarios.identities:
			for rank: int in _scenarios.ranks: await _exercise(case, rank, 1, true)
	else:
		if _batch == "clock":
			await _exercise({"id": "legacy-clock", "archetype": "stone_throw", "move_id": "pebble_toss", "legacy": true}, 1, 1, false)
		for archetype: String in LIBRARY.config().archetypes:
			var case := {"id": archetype, "archetype": archetype}
			var chosen := ""
			var count := 0
			for id: String in _moves:
				var spec: Dictionary = _moves[id].get("vfx", {})
				if str(spec.get("archetype", "")) != archetype: continue
				var row := LIBRARY.resolve(spec, 5)
				if int(row.parameters.count) > count:
					count = int(row.parameters.count)
					chosen = id
			if not chosen.is_empty(): case["move_id"] = chosen
			if _batch == "mastery":
				for rank in range(1, 6): await _exercise(case, rank, 1, true)
			else:
				await _exercise(case, 5 if _batch == "profile" else 1, 4 if _batch == "profile" else 1, false)
	var report := {"scope": "production_effect_nodes_synthetic_arena", "batch": _batch,
		"renderer": RenderingServer.get_current_rendering_method(), "resolution": [root.size.x, root.size.y],
		"display": DisplayServer.get_name(), "adapter": RenderingServer.get_video_adapter_name(),
		"engine": Engine.get_version_info(),
		"target": {"species": str(_scenarios.get("target_species", "mudsnout")), "production_model": _target != null, "scope": "posed production body; no encounter or HP authority"},
		"medium_features": _medium, "cases": _records, "failures": _failures,
		"limits": ["No combat/damage authority exercised", "Wall-frame intervals include CPU/GPU/present/OS scheduling",
			"No Ally or four-creature-fight acceptance claim", "Identity duration slowed for readable frames; host timing requires separate player witness"]}
	var file := FileAccess.open(_out.path_join("results.json"), FileAccess.WRITE)
	if file == null: _failures.append("Cannot write results")
	else:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	print("F25 batch=%s cases=%d failures=%d renderer=%s out=%s scope=synthetic_no_combat" % [_batch, _records.size(), _failures.size(), RenderingServer.get_current_rendering_method(), _out])
	quit(0 if _failures.is_empty() else 1)

func _exercise(case: Dictionary, rank: int, simultaneous: int, capture: bool) -> void:
	var id := str(case.id)
	var move_id := str(case.get("move_id", ""))
	var spec := {"archetype": str(case.archetype)}
	if not move_id.is_empty():
		if not _moves.has(move_id):
			_failures.append("Missing required actual move " + move_id); return
		spec = _moves[move_id].vfx.duplicate(true)
	var row := LIBRARY.resolve(spec, rank)
	if row.is_empty(): _failures.append("Unresolved " + id); return
	var encounter := "%s:r%d" % [id, rank]
	var travel := float(_scenarios.identity_travel_seconds) if capture else LIBRARY.travel_seconds(Vector3(-3, 1.5, 0), Vector3(3, 1.5, 0), spec)
	var arrivals := [0]
	var arrival_wall: Array[float] = []
	var arrival_frames: Array[int] = []
	var independent_result_frame := [-1]
	var flight_ready := [false]
	var impact_ready := [false]
	var target_bounds := AABB()
	if capture and _target != null:
		var pivot := _target.call("model_pivot") as Node3D
		if pivot == null:
			_failures.append("Production model pivot missing " + encounter); return
		target_bounds = pivot.global_transform * RENDER_BOUNDS.measure(pivot)
		if not target_bounds.position.is_finite() or not target_bounds.size.is_finite() or target_bounds.size.x <= 0.0 or target_bounds.size.y <= 0.0 or target_bounds.size.z <= 0.0:
			_failures.append("Production model bounds invalid " + encounter); return
	var transit := {}
	var effects: Array[Node3D] = []
	var started := Time.get_ticks_usec()
	for i in simultaneous:
		var z := float(i) * 2 - float(simultaneous - 1)
		var to := Vector3(3, 1.5, z)
		if capture and _target != null: to = _target.global_position + Vector3.UP * float(_target.call("body_height")) * 0.5
		var context := {"action_id": "%s:%d" % [encounter, i], "encounter_id": encounter, "travel_seconds": travel,
			 "mastery_rank": rank, "seed": 21 + i, "target_ground": Vector3(3, 0.04, z)}
		if capture:
			context["target_visual_bounds"] = {"position": target_bounds.position, "size": target_bounds.size}
			transit = _transit_shutter(row, Vector3(-3, to.y, z), to, target_bounds)
			if transit.has("error"):
				_failures.append(str(transit.error) + " " + encounter); return
		var effect: Node3D = LEGACY.launch(_arena, Vector3(-3, to.y, z), to, spec, context) if bool(case.get("legacy", false)) else LIBRARY.launch(_arena, Vector3(-3, to.y, z), to, spec, context)
		if effect == null: _failures.append("Launch failed " + id); return
		effects.append(effect)
		effect.connect("arrived", func() -> void:
			arrivals[0] += 1
			arrival_frames.append(Engine.get_process_frames())
			arrival_wall.append(float(Time.get_ticks_usec() - started) / 1000000.0)
			if capture and int(arrivals[0]) == simultaneous:
				create_timer(travel * maxf(0.0, float(_scenarios.capture_phases.impact) - 1.0), false).timeout.connect(func() -> void: impact_ready[0] = true))
	if capture:
		# Disk capture can stretch wall time without advancing the same amount
		# of presentation time. Shutters follow its timer/contact, never a wall
		# duration inference; recorded wall timestamps retain the real stalls.
		create_timer(travel * float(transit.fraction), false).timeout.connect(func() -> void: flight_ready[0] = true)
	# Same separate idle timer combat owns; it never waits for the node. This
	# local clock proof makes no HP mutation and cannot replace player evidence.
	create_timer(travel, false).timeout.connect(func() -> void:
		independent_result_frame[0] = Engine.get_process_frames()
		if int(arrivals[0]) != simultaneous: _failures.append("Contact not ready at independent schedule " + encounter))
	var frames: Array[float] = []
	var cpu: Array[float] = []
	var captured := {}
	var peak := BUDGET.used(encounter)
	var previous := Time.get_ticks_usec()
	var timeout := maxi(2000000, int((travel + float(row.impact.duration) + 1) * 1000000))
	while Time.get_ticks_usec() - started < timeout:
		await process_frame
		var now := Time.get_ticks_usec()
		var elapsed := float(now - started) / 1000000.0
		if not capture:
			frames.append(float(now - previous) / 1000.0)
			cpu.append(float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0)
		previous = now
		peak = maxi(peak, BUDGET.used(encounter))
		if capture and DisplayServer.get_name() != "headless":
			for phase: String in _scenarios.capture_phases:
				if captured.has(phase): continue
				var ready: bool = bool(flight_ready[0]) if phase == "flight" else (bool(impact_ready[0]) if phase == "impact" else int(arrivals[0]) == simultaneous)
				if not ready: continue
				await RenderingServer.frame_post_draw
				# Neutral filenames keep archetype and rank out of blind-judge
				# inputs; the private results record retains the mapping.
				var path := _out.path_join("sequence-%02d-%s.png" % [_records.size(), phase])
				if root.get_texture().get_image().save_png(path) != OK: _failures.append("Capture failed " + path)
				var captured_elapsed := float(Time.get_ticks_usec() - started) / 1000000.0
				captured[phase] = {"wall_seconds": captured_elapsed, "arrivals": arrivals[0],
					"nominal_travel_fraction": float(transit.fraction) if phase == "flight" else _scenarios.capture_phases[phase]}
				if phase == "flight" and bool(transit.get("clear_transit_required", false)):
					var clear := true
					var positions: Array[Vector3] = []
					for effect: Node3D in effects:
						var bodies: Array = effect.get("_bodies")
						for body: MeshInstance3D in bodies:
							positions.append(body.global_position)
							if target_bounds.grow(float(transit.envelope_radius_m)).has_point(body.global_position): clear = false
					captured[phase]["actual_body_positions"] = positions
					captured[phase]["clear_of_expanded_target_bounds"] = clear
					if not clear: _failures.append("Flight body reached measured target envelope " + encounter)
				if phase == "flight" and int(arrivals[0]) > 0:
					_failures.append("Flight frame reached after contact " + encounter)
				if phase != "flight" and int(arrivals[0]) != simultaneous:
					_failures.append("Contact/impact frame taken before arrival " + encounter)
		if int(arrivals[0]) == simultaneous and BUDGET.used(encounter) == 0 and int(independent_result_frame[0]) >= 0: break
	if int(arrivals[0]) != simultaneous: _failures.append("Missing arrival " + encounter)
	if peak > int(LIBRARY.config().encounter_particle_cap): _failures.append("Budget overflow " + encounter)
	if BUDGET.used(encounter) != 0: _failures.append("Lease remains " + encounter)
	for frame: int in arrival_frames:
		if frame != int(independent_result_frame[0]): _failures.append("Presentation/schedule frame mismatch " + encounter)
	if capture and captured.size() != _scenarios.capture_phases.size(): _failures.append("Incomplete identity frames " + encounter)
	_records.append({"id": id, "move_id": move_id, "rank": rank, "simultaneous": simultaneous,
		"resolved_count": row.parameters.count, "resolved_size": row.parameters.size, "travel_seconds": travel,
		"transit_shutter": transit, "target_visual_bounds": {"position": target_bounds.position, "size": target_bounds.size},
		"arrivals": arrivals[0], "arrival_wall_seconds": arrival_wall, "particle_budget": row.budget,
		"arrival_process_frames": arrival_frames, "independent_schedule_process_frame": independent_result_frame[0],
		"peak_slots": peak, "end_slots": BUDGET.used(encounter), "captures_at_wall_seconds": captured,
		"wall_frame_ms": frames, "cpu_process_ms": cpu, "p95_ms": _percentile(frames, 0.95), "p99_ms": _percentile(frames, 0.99)})
	LIBRARY.cancel_encounter(self, encounter)
	await process_frame

func _transit_shutter(row: Dictionary, from: Vector3, to: Vector3, target_bounds: AABB) -> Dictionary:
	var result := {"fraction": float(_scenarios.capture_phases.flight), "clear_transit_required": false}
	if str(row.body.get("motion", "")) != "projectile": return result
	var profile: Dictionary = row.body
	var radius := float(row.parameters.size)
	if str(profile.shape) == "stone": radius *= 1.5 # Authored geological ridges and randomized body scale.
	if str(profile.shape) == "flame_orb": radius *= float(profile.get("card_extent_scale", 3.2)) * 0.5
	for layer: Dictionary in profile.get("layers", []):
		var extent := float(layer.get("size_scale", 1.0)) * float(layer.get("card_extent_scale", 3.2)) * 0.5
		var offset: Array = layer.get("offset", [0.0, 0.0, 0.0])
		extent += Vector3(float(offset[0]), float(offset[1]), float(offset[2])).length()
		radius = maxf(radius, float(row.parameters.size) * extent)
	radius += maxf(0.0, float(row.parameters.get("spread", 0.0)))
	var cfg: Dictionary = _scenarios.transit_shutter
	radius += float(cfg.clearance_m)
	var expanded := target_bounds.grow(radius)
	if expanded.has_point(from): return {"error": "No independently clear transit origin"}
	var entry: Variant = expanded.intersects_segment(from, to)
	if not entry is Vector3: return {"error": "Transit does not intersect measured target envelope"}
	var fraction := from.distance_to(entry as Vector3) / maxf(0.001, from.distance_to(to))
	var shutter := minf(float(cfg.maximum_fraction), fraction * float(cfg.before_entry_scale))
	if shutter < float(cfg.minimum_fraction): return {"error": "No usable clear transit interval"}
	return {"fraction": shutter, "clear_transit_required": true, "envelope_radius_m": radius,
		"entry_fraction": fraction, "method": str(cfg.method), "revision": "r5-measured-clear-transit"}

func _percentile(samples: Array[float], fraction: float) -> float:
	if samples.is_empty(): return 0.0
	var sorted: Array[float] = samples.duplicate()
	sorted.sort()
	return sorted[clampi(ceili(float(sorted.size()) * fraction) - 1, 0, sorted.size() - 1)]
