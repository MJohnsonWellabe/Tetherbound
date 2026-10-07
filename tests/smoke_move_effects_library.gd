extends SceneTree

## Actual production effect-node batch in a synthetic arena. No combat, HP or
## result fixture mutation. Cannot certify the required four-creature fight.
## --batch=identities|mastery|library|profile|clock --out=<directory> --medium
## --identity=<id>:r<rank> selects one explicit identity for an affected rerun.
## --stage=arena|meadows: identity/mastery captures default to the configured
## stage (production Meadows day look, installed ground and nature family, a
## posed attacker of the move's type). arena keeps the earlier flat backdrop.
const LIBRARY := preload("res://scripts/vfx/move_effect_library.gd")
const LEGACY := preload("res://scripts/vfx/legacy_move_travel.gd")
const BUDGET := preload("res://scripts/vfx/move_effect_budget.gd")
const CREATURE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const AUDIO := preload("res://scripts/audio/audio_manager.gd")
const WORLD_LOOK := preload("res://scripts/world/world_look.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const ULTIMATES := preload("res://scripts/vfx/ultimates/ultimate_library.gd")
const COMBAT_VFX := preload("res://scripts/vfx/combat_vfx.gd")
const GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")
var _arena: Node3D
var _target: CharacterBody3D
var _attackers: Dictionary = {}
var _current_attacker: Node3D = null
var _stage := ""
var _target_x := 3.0
var _archetype_filter: Array = []
var _rank_filter: Array = []
## world stage only: the shipped terrain height source and the loaded world.
var _field: RefCounted = null
var _world: Node = null
var _relocated: Array = []
var _ultimate_filter: Array = []
var _breakthrough_filter: Array = []
## Diagnostic close-ups: --camera=px,py,pz:lx,ly,lz (arena-local position and
## look-at) replaces the stage camera; --no-autoframe keeps it for ultimates.
var _camera_override := ""
var _no_autoframe := false
var _moves: Dictionary
var _scenarios: Dictionary
var _records: Array[Dictionary] = []
var _failures: Array[String] = []
var _out := "user://move-effects-preview"
var _batch := "identities"
var _medium := false
var _light_lifecycle: Dictionary = {}
var _ultimate_override_assertions := 0
var _identity := ""

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--batch="): _batch = arg.trim_prefix("--batch=")
		if arg.begins_with("--out="): _out = arg.trim_prefix("--out=")
		if arg == "--medium": _medium = true
		if arg.begins_with("--identity="): _identity = arg.trim_prefix("--identity=")
		if arg.begins_with("--stage="): _stage = arg.trim_prefix("--stage=")
		if arg.begins_with("--camera="): _camera_override = arg.trim_prefix("--camera=")
		if arg == "--no-autoframe": _no_autoframe = true
		if arg.begins_with("--ultimates="): _ultimate_filter = Array(arg.trim_prefix("--ultimates=").split(","))
		if arg.begins_with("--breakthroughs="):
			for count: String in arg.trim_prefix("--breakthroughs=").split(","): _breakthrough_filter.append(int(count))
		# Affected-subset reruns: --archetypes=a,b narrows the mastery batch,
		# --ranks=1,3 narrows mastery and identities; full runs pass neither.
		if arg.begins_with("--archetypes="): _archetype_filter = Array(arg.trim_prefix("--archetypes=").split(","))
		if arg.begins_with("--ranks="):
			for rank: String in arg.trim_prefix("--ranks=").split(","): _rank_filter.append(int(rank))
	if _batch not in ["identities", "mastery", "library", "profile", "clock", "ultimates"]:
		push_error("Unknown effect batch"); quit(1); return
	if _batch in ["identities", "mastery", "profile", "ultimates"] and DisplayServer.get_name() == "headless":
		push_error("Identity/performance evidence requires a native display"); quit(1); return
	if OS.get_cmdline_user_args().has("--with-vfx-units"):
		var output: Array = []
		var exit_code := OS.execute(OS.get_executable_path(), PackedStringArray([
			"--headless", "--path", ProjectSettings.globalize_path("res://"),
			"--audio-driver", "Dummy", "--script", "res://tests/run_tests.gd", "--",
			"--only=test_move_effects.gd"]), output, true)
		for chunk: Variant in output: print(str(chunk))
		if exit_code != 0:
			push_error("Existing move-effects units failed before capture"); quit(1); return
	_scenarios = JSON.parse_string(FileAccess.get_file_as_string("res://assets/vfx/proof_scenarios.json"))
	if not _identity.is_empty():
		var known_identity := false
		for case: Dictionary in _scenarios.identities:
			for rank: int in _scenarios.ranks:
				if _identity == "%s:r%d" % [str(case.id), rank]: known_identity = true
		if _batch != "identities" or not known_identity:
			push_error("Named identity must select one configured identity/rank in the identities batch"); quit(1); return
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/moves/moves.json"))
	_moves = data.moves
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_out)):
		push_error("Use a fresh output directory; existing evidence preserved"); quit(1); return
	if DirAccess.make_dir_recursive_absolute(_out) != OK:
		push_error("Cannot create output"); quit(1); return
	# Honor the engine's requested resolution (hosted default 1280x720).
	# The actual viewport size is retained in the evidence report below.
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
	if _batch == "identities":
		# The light-pool lifecycle is synthetic and independent of the
		# backdrop; run it on the bare arena before any heavy stage loads.
		LIBRARY.config()["enabled"] = true # Process-local diagnostic opt-in only.
		for i in int(_scenarios.warmup_frames): await process_frame
		await _exercise_light_lifecycle()
	if _stage.is_empty():
		_stage = str((_scenarios.get("stage", {}) as Dictionary).get("default", "arena")) if _batch in ["identities", "mastery", "ultimates"] else "arena"
	if _stage not in ["arena", "meadows", "world"]:
		push_error("Unknown stage " + _stage); quit(1); return
	if _stage == "meadows":
		if not _build_meadows_stage(floor, sun, world_environment, camera): return
	if _stage == "world":
		if not await _build_world_stage(floor, sun, world_environment, camera): return
	if not _camera_override.is_empty():
		var parts := _camera_override.split(":")
		var at := parts[0].split_floats(",")
		var look := parts[1].split_floats(",")
		camera.position = Vector3(at[0], at[1], at[2])
		camera.look_at(_arena.to_global(Vector3(look[0], look[1], look[2])), Vector3.UP)
	if _batch in ["identities", "mastery", "ultimates"]:
		# Production creature scene/script/model, with no encounter, AI or HP
		# transaction. This establishes visible target coverage only.
		_target = CREATURE.instantiate() as CharacterBody3D
		_target.set_script(CREATURE_BODY)
		_arena.add_child(_target)
		_target.call("setup", str(_scenarios.get("target_species", "mudsnout")))
		_target.set_physics_process(false)
		if _stage in ["meadows", "world"]: _target_x = float((_scenarios.stage as Dictionary).get("target_x", 3.0))
		_target.position = Vector3(_target_x, _local_ground_y(_target_x, 0.0), 0)
		_target.rotation.y = -PI * 0.5
		if not bool(_target.call("has_model")):
			push_error("Identity evidence requires the actual production creature model"); quit(1); return
	if _medium:
		if RenderingServer.get_current_rendering_method() != "forward_plus":
			push_error("Medium requires actual Forward+"); quit(1); return
		if GRAPHICS.choose("Medium") != OK:
			push_error("Cannot select authored Medium preset"); quit(1); return
		if _stage == "world":
			var look := _world.get_node_or_null(^"WorldLook")
			if look == null or not look.has_method("refresh_graphics"):
				push_error("World stage requires the live production preset owner"); quit(1); return
			look.call("refresh_graphics")
			# The synthetic arena Environment has been removed on this stage.
			# Refresh and inspect the Environment that the loaded world owns.
			var holder := look.get_node_or_null(look.get("environment_path")) as WorldEnvironment
			if holder == null or holder.environment == null:
				push_error("World stage Medium environment missing"); quit(1); return
			environment = holder.environment
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
	if _batch == "ultimates":
		await _run_ultimates()
	elif _batch == "identities":
		for case: Dictionary in _scenarios.identities:
			for rank: int in _scenarios.ranks:
				if not _rank_filter.is_empty() and rank not in _rank_filter: continue
				if _identity.is_empty() or _identity == "%s:r%d" % [str(case.id), rank]:
					await _exercise(case, rank, 1, true)
	else:
		if _batch == "clock":
			await _exercise({"id": "legacy-clock", "archetype": "stone_throw", "move_id": "pebble_toss", "legacy": true}, 1, 1, false)
		for archetype: String in LIBRARY.config().archetypes:
			if not _archetype_filter.is_empty() and archetype not in _archetype_filter: continue
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
				for rank in range(1, 6):
					if _rank_filter.is_empty() or rank in _rank_filter: await _exercise(case, rank, 1, true)
			else:
				await _exercise(case, 5 if _batch == "profile" else 1, 4 if _batch == "profile" else 1, false)
	var report := {"scope": "production_effect_nodes_synthetic_arena", "batch": _batch,
		"renderer": RenderingServer.get_current_rendering_method(), "resolution": [root.size.x, root.size.y],
		"display": DisplayServer.get_name(), "adapter": RenderingServer.get_video_adapter_name(),
		"engine": Engine.get_version_info(),
		"target": {"species": str(_scenarios.get("target_species", "mudsnout")), "production_model": _target != null, "scope": "posed production body; no encounter or HP authority"},
		"medium_features": _medium, "cases": _records, "failures": _failures,
		"light_lifecycle": _light_lifecycle, "ultimate_override_assertions": _ultimate_override_assertions, "selected_identity": _identity,
		"archetype_filter": _archetype_filter, "rank_filter": _rank_filter, "stage": _stage,
		"relocated_world_characters": _relocated,
		"limits": ["No combat/damage authority exercised", "Wall-frame intervals include CPU/GPU/present/OS scheduling",
			"No Ally or four-creature-fight acceptance claim", "Identity duration slowed for readable frames; host timing requires separate player witness"]}
	var file := FileAccess.open(_out.path_join("results.json"), FileAccess.WRITE)
	if file == null: _failures.append("Cannot write results")
	else:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	print("F25 batch=%s cases=%d failures=%d renderer=%s out=%s scope=synthetic_no_combat" % [_batch, _records.size(), _failures.size(), RenderingServer.get_current_rendering_method(), _out])
	quit(0 if _failures.is_empty() else 1)

## Real production effect nodes exercise the finite light pool before frames.
## This is synthetic lifetime/audio observation, never HP/host acceptance.
func _exercise_light_lifecycle() -> void:
	var checks := {"initial_lights_empty": BUDGET.lights_used() == 0}
	var cap := int(LIBRARY.config().get("scene_light_cap", 0))
	checks["authored_scene_cap_four"] = cap == 4
	var previous_logging := AUDIO.logging_enabled
	AUDIO.logging_enabled = true
	var audio_start := AUDIO.recent().size()
	var cancelled: Array[Node3D] = []
	var cancel_arrivals := [0]
	for i in 5:
		var frozen := _frozen_move("fireball", _moves.fireball.vfx, 1, "light-cancel:%d" % (i + 1), "light-cancel-%d" % i, i + 1)
		var context := {"travel_seconds": 0.05, "current_actor": frozen.actor_binding,
			"source_ground": Vector3(-5, 0.04, -8), "target_ground": Vector3(2, 0.04, -8)}
		var effect := LIBRARY.launch(_arena, Vector3(-5, 2, -8), Vector3(2, 2, -8), frozen, context)
		if effect != null:
			cancelled.append(effect)
			effect.connect("arrived", func() -> void: cancel_arrivals[0] += 1)
	checks["cancel_five_actual_nodes"] = cancelled.size() == 5
	checks["cancel_global_cap"] = BUDGET.lights_used() == 4
	var actual_lights := 0
	for effect in cancelled:
		for child: Node in effect.get_children():
			if child is OmniLight3D: actual_lights += 1
	checks["cancel_actual_light_nodes"] = actual_lights == 4
	var hidden := true
	for effect in cancelled:
		effect.call("cancel_presentation")
		for child: Node in effect.get_children():
			if child is OmniLight3D and child.visible: hidden = false
	checks["cancel_hides_lights_immediately"] = hidden
	await process_frame
	await process_frame
	var removed := true
	for effect in cancelled:
		if is_instance_valid(effect): removed = false
	checks["cancel_frees_actual_nodes"] = removed
	checks["cancel_reclaims_lights"] = BUDGET.lights_used() == 0
	var particles_empty := true
	for i in 5:
		if BUDGET.used("light-cancel-%d" % i) != 0: particles_empty = false
	checks["cancel_reclaims_particles"] = particles_empty
	var natural: Array[Node3D] = []
	var natural_arrivals := [0]
	for i in 5:
		var frozen := _frozen_move("fireball", _moves.fireball.vfx, 1, "light-natural:%d" % (i + 1), "light-natural-%d" % i, i + 6)
		var context := {"travel_seconds": 0.05, "current_actor": frozen.actor_binding,
			"source_ground": Vector3(-5, 0.04, -8), "target_ground": Vector3(2, 0.04, -8)}
		var effect := LIBRARY.launch(_arena, Vector3(-5, 2, -8), Vector3(2, 2, -8), frozen, context)
		if effect != null:
			natural.append(effect)
			effect.connect("arrived", func() -> void: natural_arrivals[0] += 1)
	checks["natural_five_actual_nodes"] = natural.size() == 5
	var peak := BUDGET.lights_used()
	# Same 8 s allowance on the presentation (idle) clock the effects age on;
	# a slow software renderer cannot expire it before the nodes could finish.
	var deadline := create_timer(8.0, false)
	removed = false
	while deadline.time_left > 0.0:
		await process_frame
		peak = maxi(peak, BUDGET.lights_used())
		removed = true
		for effect in natural:
			if is_instance_valid(effect): removed = false
		if removed: break
	checks["natural_peak_bounded"] = peak == 4
	checks["natural_arrives_once_per_node"] = int(natural_arrivals[0]) == 5
	checks["natural_frees_actual_nodes"] = removed
	checks["natural_reclaims_lights"] = BUDGET.lights_used() == 0
	particles_empty = true
	for i in 5:
		if BUDGET.used("light-natural-%d" % i) != 0: particles_empty = false
	checks["natural_reclaims_particles"] = particles_empty
	checks["cancel_never_emits_arrival"] = int(cancel_arrivals[0]) == 0
	var launches := 0
	var impacts := 0
	for entry: Dictionary in AUDIO.recent().slice(audio_start):
		if str(entry.name) == "fireball:launch": launches += 1
		if str(entry.name) == "fireball:impact": impacts += 1
	checks["one_launch_voice_per_node"] = launches == 10
	# The integrated presentation contract freezes impact_audio_owner=receipt:
	# the accepted combat receipt owns the one contact cue, never this renderer.
	checks["contact_cue_deferred_to_receipt"] = impacts == 0
	AUDIO.logging_enabled = previous_logging
	_light_lifecycle = {"scope": "production_nodes_synthetic_lifetime_only",
		"checks": checks, "check_count": checks.size(), "peak_lights": peak,
		"cancel_arrivals": int(cancel_arrivals[0]), "natural_arrivals": int(natural_arrivals[0]),
		"launch_cues": launches, "impact_cues": impacts}
	for name: String in checks:
		if not bool(checks[name]): _failures.append("Light lifecycle: " + name)
	# Failure evidence is retained; cleanup cannot convert failed checks to PASS.
	for effect in natural:
		if is_instance_valid(effect): effect.call("cancel_presentation")
	await process_frame
	await process_frame

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
	# Shutter readiness per configured phase. Pre-arrival phases (launch,
	# flight) open on the presentation clock; contact opens on actual arrival;
	# later phases open on a presentation timer started by that arrival.
	var phase_ready := {}
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
		var to := _arena.to_global(Vector3(_target_x, 1.5, z))
		if capture and _target != null: to = _target.global_position + Vector3.UP * float(_target.call("body_height")) * 0.5
		var frozen := _frozen_move(move_id, spec, rank, "%s:%d" % [encounter, i], encounter, i + 1)
		var context := {"travel_seconds": travel, "current_actor": frozen.actor_binding,
			"source_ground": _ground_point(-3.0, z), "target_ground": _ground_point(_target_x, z)}
		if capture:
			context["target_visual_bounds"] = {"position": target_bounds.position, "size": target_bounds.size}
		var from := _arena.to_global(Vector3(-3, _arena.to_local(to).y, z))
		if capture and _stage in ["meadows", "world"]:
			from = _attacker_origin(case, move_id, z)
			if not from.is_finite():
				_failures.append("Attacker model missing " + encounter); return
			context["source_ground"] = _ground_point(_arena.to_local(from).x, z)
		if capture:
			transit = _transit_shutter(row, from, to, target_bounds)
			if transit.has("error"):
				_failures.append("%s %s from=%s target=%s" % [transit.error, encounter, from, target_bounds]); return
		var legacy_context := {"action_id": "%s:%d" % [encounter, i], "encounter_id": encounter, "travel_seconds": travel,
			"mastery_rank": rank, "seed": 21 + i, "target_ground": _ground_point(_target_x, z)}
		var effect: Node3D = LEGACY.launch(_arena, from, to, spec, legacy_context) if bool(case.get("legacy", false)) else LIBRARY.launch(_arena, from, to, frozen, context)
		if effect == null: _failures.append("Launch failed " + id); return
		effects.append(effect)
		# Same public presentation calls combat makes (play_attack at launch,
		# visual-pivot flinch at the hit); no HP, collision or receipt.
		var reacting := capture and _stage in ["meadows", "world"]
		if reacting and _current_attacker != null and _current_attacker.has_method("play_attack"): _current_attacker.call("play_attack")
		var away := (to - from).normalized()
		var tint: Variant = COMBAT_VFX.tint_for_type(str(_moves.get(move_id, {}).get("type", "")))
		effect.connect("arrived", func() -> void:
			if reacting and _target != null and _target.has_method("play_combat_flinch"): _target.call("play_combat_flinch", away)
			# Combat's own landed-hit feedback (spark + struck-body flash), the
			# same public call the manager makes on a hit; no HP is changed.
			if reacting and _target != null: COMBAT_VFX.hit(_arena, to, tint, true, _target, 0.35)
			arrivals[0] += 1
			arrival_frames.append(Engine.get_process_frames())
			arrival_wall.append(float(Time.get_ticks_usec() - started) / 1000000.0)
			if capture and int(arrivals[0]) == simultaneous:
				for phase: String in _scenarios.capture_phases:
					var fraction := float(_scenarios.capture_phases[phase])
					if phase == "contact": phase_ready[phase] = true
					elif phase != "flight" and fraction > 1.0:
						create_timer(travel * (fraction - 1.0), false).timeout.connect(func() -> void: phase_ready[phase] = true))
	if capture:
		# Disk capture can stretch wall time without advancing the same amount
		# of presentation time. Shutters follow its timer/contact, never a wall
		# duration inference; recorded wall timestamps retain the real stalls.
		for phase: String in _scenarios.capture_phases:
			var fraction := float(transit.fraction) if phase == "flight" else float(_scenarios.capture_phases[phase])
			if phase == "flight" or fraction < 1.0:
				create_timer(travel * fraction, false).timeout.connect(func() -> void: phase_ready[phase] = true)
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
	var timeout := maxi(2000000, int((travel + _presentation_lifetime(row) + 1) * 1000000))
	# Presentation and capture shutters use the idle simulation clock. Movie
	# encoding/material work may spend wall time without equivalent advancement.
	# Keep the same lifetime allowance on that clock for captures, plus a finite
	# wall watchdog. Noncapture profiling retains its original wall deadline.
	var capture_deadline: SceneTreeTimer = create_timer(float(timeout) / 1000000.0, false) if capture else null
	# Software renderers draw far slower than the presentation clock; the
	# authored allowance stays on that clock, the wall watchdog is configurable.
	var wall_watchdog := int(float(_scenarios.get("capture_wall_watchdog_s", 30.0)) * 1000000.0) if capture else timeout
	while Time.get_ticks_usec() - started < wall_watchdog:
		if capture and capture_deadline.time_left <= 0.0: break
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
				var ready := bool(phase_ready.get(phase, false))
				var pre_arrival := phase == "flight" or float(_scenarios.capture_phases[phase]) < 1.0
				if not ready: continue
				# Keep this observed simulation state through GPU readback. On a
				# slow renderer, awaiting the next draw otherwise advances another
				# frame and can turn a pre-contact shutter into a contact frame.
				# Both presentation and independent timers use process_always=false.
				paused = true
				await RenderingServer.frame_post_draw
				# Neutral filenames keep archetype and rank out of blind-judge
				# inputs; the private results record retains the mapping.
				var path := _out.path_join("sequence-%02d-%s.png" % [_records.size(), phase])
				print("F25 capture %s %s wall=%dms" % [encounter, phase, Time.get_ticks_msec()])
				if root.get_texture().get_image().save_png(path) != OK: _failures.append("Capture failed " + path)
				var captured_elapsed := float(Time.get_ticks_usec() - started) / 1000000.0
				captured[phase] = {"wall_seconds": captured_elapsed, "arrivals": arrivals[0],
					"simulation_paused_for_readback": true,
					"nominal_travel_fraction": float(transit.fraction) if phase == "flight" else _scenarios.capture_phases[phase]}
				if phase == "flight" and bool(transit.get("clear_transit_required", false)):
					var clear := true
					var positions: Array[Vector3] = []
					for effect: Node3D in effects:
						var bodies: Array = effect.get("_bodies")
						for body: MeshInstance3D in bodies:
							positions.append(body.global_position)
							if target_bounds.grow(float(transit.body_envelope_radius_m)).has_point(body.global_position): clear = false
					captured[phase]["actual_body_positions"] = positions
					captured[phase]["clear_of_expanded_target_bounds"] = clear
					if not clear: _failures.append("Flight body reached measured target envelope " + encounter)
				if pre_arrival and int(arrivals[0]) > 0:
					_failures.append("%s frame reached after contact %s" % [phase.capitalize(), encounter])
				if not pre_arrival and int(arrivals[0]) != simultaneous:
					_failures.append("%s frame taken before arrival %s" % [phase.capitalize(), encounter])
				if not pre_arrival and bool(row.impact.get("settle_on_ground", false)):
					var checked := 0
					for effect: Node3D in effects:
						if not is_instance_valid(effect): continue
						var motes := effect.get("_motes") as MultiMeshInstance3D
						if motes == null: continue
						var ground: Vector3 = effect.get("_context").get("target_ground")
						for mote: int in motes.multimesh.instance_count:
							var bounds := (motes.global_transform * motes.multimesh.get_instance_transform(mote)) * motes.multimesh.mesh.get_aabb()
							checked += 1
							if bounds.position.y < ground.y - 0.001:
								_failures.append("Debris penetrates frozen ground %s %s mote=%d" % [encounter, phase, mote])
					captured[phase]["grounded_debris_checked"] = checked
					if phase in ["contact", "impact"] and checked == 0:
						_failures.append("No ground-bound debris inspected %s %s" % [encounter, phase])
				paused = false
		# A capture also waits for every configured shutter; an aftermath frame
		# after the effect freed itself honestly records an empty aftermath.
		if int(arrivals[0]) == simultaneous and BUDGET.used(encounter) == 0 and int(independent_result_frame[0]) >= 0 \
				and (not capture or captured.size() == _scenarios.capture_phases.size()): break
	if int(arrivals[0]) != simultaneous: _failures.append("Missing arrival " + encounter)
	var watchdog_expired := capture and Time.get_ticks_usec() - started >= wall_watchdog
	if watchdog_expired: _failures.append("Capture wall watchdog expired " + encounter)
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
		"end_process_frame": Engine.get_process_frames(), "end_wall_seconds": float(Time.get_ticks_usec() - started) / 1000000.0,
		"lifetime_deadline_clock": "idle_simulation" if capture else "wall", "lifetime_allowance_seconds": float(timeout) / 1000000.0,
		"wall_watchdog_expired": watchdog_expired,
		"wall_frame_ms": frames, "cpu_process_ms": cpu, "p95_ms": _percentile(frames, 0.95), "p99_ms": _percentile(frames, 0.99)})
	LIBRARY.cancel_encounter(self, encounter)
	await process_frame

## Impact plus any authored aftermath (lingering chips, ground marks) the
## node keeps drawing after contact; flight-phase stages end before contact.
func _presentation_lifetime(row: Dictionary) -> float:
	var impact: Dictionary = row.impact
	var lifetime := float(impact.get("duration", 0.45))
	var stages: Dictionary = impact.get("stages", {})
	lifetime += maxf(0.0, float(stages.get("mote_linger_seconds", 0.0)))
	for kind: String in ["flash", "shockwave", "mark"]:
		if stages.get(kind) is Dictionary: lifetime = maxf(lifetime, float((stages[kind] as Dictionary).get("duration", 0.0)))
	return lifetime

func _transit_shutter(row: Dictionary, from: Vector3, to: Vector3, target_bounds: AABB) -> Dictionary:
	var result := {"fraction": float(_scenarios.capture_phases.flight), "clear_transit_required": false}
	if str(row.body.get("motion", "")) != "projectile": return result
	var profile: Dictionary = row.body
	var radius := float(row.parameters.size)
	if str(profile.shape) == "stone": radius *= 1.5 # Authored geological ridges and randomized body scale.
	if str(profile.shape) == "flame_orb": radius *= float(profile.get("card_extent_scale", 3.2)) * 0.5
	for layer: Dictionary in profile.get("layers", []):
		var extent := float(layer.get("size_scale", 1.0)) * float(layer.get("card_extent_scale", 3.2)) * 0.5
		if str(layer.get("shape", "")) == "flame_tongue":
			# Curved authored planes rotate in world space. Include their full
			# corner diagonal, curve depth and bounded vertex sway, not merely
			# projected width or the opaque portion of a generated texture.
			var layer_scale := float(layer.get("size_scale", 1.0))
			extent = extent * (sqrt(2.0) + 0.025) + layer_scale * float(layer.get("curve_depth_scale", 0.18))
		var offset: Array = layer.get("offset", [0.0, 0.0, 0.0])
		extent += Vector3(float(offset[0]), float(offset[1]), float(offset[2])).length()
		radius = maxf(radius, float(row.parameters.size) * extent)
	var body_radius := radius + float((_scenarios.transit_shutter as Dictionary).clearance_m)
	var spread := maxf(0.0, float(row.parameters.get("spread", 0.0)))
	if int(row.parameters.count) > 1:
		spread = maxf(spread, float(row.parameters.size) * float(profile.get("volley_separation_scale", 2.8)))
		spread += float(int(row.parameters.count) - 1) * 0.5 * float(profile.get("volley_stagger_m", 0.25))
	radius += spread
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
		"body_envelope_radius_m": body_radius,
		"entry_fraction": fraction, "method": str(cfg.method), "revision": "r6-separate-body-and-group-envelopes"}

func _percentile(samples: Array[float], fraction: float) -> float:
	if samples.is_empty(): return 0.0
	var sorted: Array[float] = samples.duplicate()
	sorted.sort()
	return sorted[clampi(ceili(float(sorted.size()) * fraction) - 1, 0, sorted.size() - 1)]

## Production Meadows day look (art.json + meadows_look.json through the real
## WorldLook), the installed terrain grass texture and installed nature family
## as dressing. Presentation context for judging only; no world, encounter,
## save or gameplay state is created.
func _build_meadows_stage(floor: MeshInstance3D, sun: DirectionalLight3D,
		world_environment: WorldEnvironment, camera: Camera3D) -> bool:
	var stage: Dictionary = _scenarios.get("stage", {})
	var ground := StandardMaterial3D.new()
	ground.albedo_texture = load(str(stage.ground_albedo)) as Texture2D
	ground.normal_enabled = true
	ground.normal_texture = load(str(stage.ground_normal)) as Texture2D
	ground.roughness = 0.95
	ground.uv1_scale = Vector3.ONE * float(stage.get("ground_uv_scale", 10.0))
	ground.albedo_color = Color(str(stage.get("ground_tint", "#ffffff")))
	if ground.albedo_texture == null:
		push_error("Stage ground texture missing"); quit(1); return false
	(floor.mesh as PlaneMesh).size = Vector2.ONE * float(stage.get("ground_size_m", 60.0))
	floor.material_override = ground
	for prop: Dictionary in stage.get("dressing", []):
		var packed := load(str(prop.scene)) as PackedScene
		if packed == null:
			push_error("Stage dressing missing " + str(prop.scene)); quit(1); return false
		var node := packed.instantiate() as Node3D
		_arena.add_child(node)
		var p: Array = prop.position
		node.position = Vector3(float(p[0]), float(p[1]), float(p[2]))
		node.rotation_degrees.y = float(prop.get("yaw_deg", 0.0))
		node.scale = Vector3.ONE * float(prop.get("scale", 1.0))
	sun.name = "Sun"
	world_environment.name = "Environment"
	world_environment.environment.background_mode = Environment.BG_SKY
	# WorldLook styles the sky the scene already owns, as world scenes do.
	world_environment.environment.sky = Sky.new()
	world_environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	var look := WORLD_LOOK.new()
	look.name = "WorldLook"
	look.realm_look_path = str(stage.look_path)
	look.sun_path = sun.get_path()
	look.environment_path = world_environment.get_path()
	_arena.add_child(look)
	look.call("set_clock_frozen", true)
	look.call("apply_time", str(stage.get("time", "day")))
	var cam: Dictionary = stage.camera
	camera.position = Vector3(float(cam.position[0]), float(cam.position[1]), float(cam.position[2]))
	camera.fov = float(cam.get("fov", 60.0))
	camera.look_at(Vector3(float(cam.look_at[0]), float(cam.look_at[1]), float(cam.look_at[2])), Vector3.UP)
	return true

## Posed production attacker of the case's configured species facing the
## target. Returns a launch point just in front of its measured model bounds
## at mouth height, or a non-finite vector when the production model is absent.
func _attacker_origin(case: Dictionary, move_id: String, z: float) -> Vector3:
	var stage: Dictionary = _scenarios.get("stage", {})
	var species := str(case.get("attacker_species", (stage.get("attackers_by_type", {}) as Dictionary).get(
		str(_moves.get(move_id, {}).get("type", "")), stage.get("attacker_species", "terrapup"))))
	for key: String in _attackers: (_attackers[key] as Node3D).visible = key == species
	if not _attackers.has(species):
		var body := CREATURE.instantiate() as CharacterBody3D
		body.set_script(CREATURE_BODY)
		_arena.add_child(body)
		body.call("setup", species)
		body.set_physics_process(false)
		body.position = Vector3(float(stage.get("attacker_x", -3.4)), 0, z)
		body.rotation.y = PI * 0.5
		if not bool(body.call("has_model")): return Vector3(INF, INF, INF)
		# Production creatures differ widely in length. Place the measured
		# muzzle face at the configured line so every attacker leaves the
		# same readable gap to the target instead of overlapping it.
		var placed_pivot := body.call("model_pivot") as Node3D
		var placed := _arena.global_transform.affine_inverse() * placed_pivot.global_transform * RENDER_BOUNDS.measure(placed_pivot)
		body.position.x += float(stage.get("attacker_front_x", -3.0)) - placed.end.x
		body.position.y = _local_ground_y(body.position.x, z)
		_attackers[species] = body
	var attacker := _attackers[species] as CharacterBody3D
	_current_attacker = attacker
	var pivot := attacker.call("model_pivot") as Node3D
	var bounds := _arena.global_transform.affine_inverse() * pivot.global_transform * RENDER_BOUNDS.measure(pivot)
	if not bounds.size.is_finite() or bounds.size.y <= 0.0: return Vector3(INF, INF, INF)
	return _arena.to_global(Vector3(bounds.end.x + float(stage.get("muzzle_clearance_m", 0.12)),
		bounds.position.y + bounds.size.y * float(stage.get("muzzle_height_ratio", 0.62)), z))

## The integrated presentation contract (move_presentation_contract.gd) admits
## only a frozen move row bound to one actor action. This synthetic binding
## names a proof actor and is never a combat receipt or HP authority.
func _frozen_move(move_id: String, visual: Dictionary, rank: int, action_id: String,
		encounter: String, action: int) -> Dictionary:
	var vfx := visual.duplicate(true)
	if not vfx.has("count"):
		var base: Dictionary = (LIBRARY.config().archetypes[str(vfx.archetype)] as Dictionary).get("parameters", {})
		for key: String in base: if not vfx.has(key): vfx[key] = base[key]
	vfx["mastery_owner"] = "f25"
	var binding := {"character_id": "f25-proof", "creature_uid": "f25-proof-attacker",
		"encounter_id": encounter, "generation": 1, "action": action}
	return {"vfx": vfx, "actor_binding": binding, "action_id": action_id,
		"mastery_rank": rank, "move_id": move_id}

## Arena-local ground height: real terrain on the world stage, flat otherwise.
func _local_ground_y(local_x: float, local_z: float) -> float:
	if _field == null: return 0.0
	var global := _arena.to_global(Vector3(local_x, 0.0, local_z))
	return float(_field.call("height_at", global.x, global.z)) - _arena.global_position.y

## Global contact ground a few centimetres above the surface at an arena point.
func _ground_point(local_x: float, local_z: float) -> Vector3:
	return _arena.to_global(Vector3(local_x, _local_ground_y(local_x, local_z) + 0.04, local_z))

## The shipped Meadows world (meadows_playground.tscn), loaded read-only as the
## backdrop: real Terrain3D ground, vegetation scatter, sky and WorldLook. Its
## clock and weather are frozen, its HUD/UI hidden, its follow camera, player,
## spawning and encounter systems stopped. No save, network or durable state
## is written; the arena (attacker, target, effects, camera) is posed at an
## authored open spot on the real terrain height.
func _build_world_stage(floor: MeshInstance3D, sun: DirectionalLight3D,
		world_environment: WorldEnvironment, camera: Camera3D) -> bool:
	var stage: Dictionary = _scenarios.stage
	var world_cfg: Dictionary = stage.world
	var packed := load(str(world_cfg.scene)) as PackedScene
	if packed == null:
		push_error("World stage scene missing"); quit(1); return false
	floor.queue_free()
	sun.queue_free()
	world_environment.queue_free()
	_world = packed.instantiate()
	root.add_child(_world)
	var weather := _world.get_node_or_null(^"WorldWeather")
	if weather != null and weather.has_method("set_weather"):
		weather.call("set_weather", str(world_cfg.get("weather", "clear")))
		weather.set_process(false)
		weather.set_physics_process(false)
	for path: String in ["CameraRig", "EncounterDirector", "TrainerSpawn", "SequenceDirector", "RidingController"]:
		var node := _world.get_node_or_null(NodePath(path))
		if node != null:
			node.process_mode = Node.PROCESS_MODE_DISABLED
	var player := _world.get_node_or_null(^"Player") as Node3D
	if player != null:
		player.process_mode = Node.PROCESS_MODE_DISABLED
		player.visible = false
	_field = HEIGHTFIELD.new()
	var origin: Array = world_cfg.origin
	var ox := float(origin[0])
	var oz := float(origin[1])
	_arena.global_position = Vector3(ox, float(_field.call("height_at", ox, oz)), oz)
	_arena.rotation.y = deg_to_rad(float(world_cfg.get("yaw_deg", 0.0)))
	var cam: Dictionary = world_cfg.get("camera", stage.camera)
	camera.position = Vector3(float(cam.position[0]), float(cam.position[1]), float(cam.position[2]))
	camera.position.y += _local_ground_y(camera.position.x, camera.position.z)
	camera.fov = float(cam.get("fov", 60.0))
	camera.far = 2000.0
	camera.make_current()
	var look_at := Vector3(float(cam.look_at[0]), float(cam.look_at[1]), float(cam.look_at[2]))
	look_at.y += _local_ground_y(look_at.x, look_at.z)
	camera.look_at(_arena.to_global(look_at), Vector3.UP)
	var terrain := _world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"): terrain.call("set_camera", camera)
	var settle := int(world_cfg.get("settle_frames", 240))
	for i in settle:
		await physics_frame
		if i % 30 == 0: print("F25 world settle %d/%d wall=%dms" % [i, settle, Time.get_ticks_msec()])
	var look := _world.get_node_or_null(^"WorldLook")
	if look != null:
		look.call("set_clock_frozen", true)
		look.call("apply_time", str(stage.get("time", "day")))
	# HUD and UI are not part of an effect judgement; hide every canvas layer.
	for node: Node in _world.find_children("*", "CanvasLayer", true, false):
		(node as CanvasLayer).visible = false
	# Wild/trainer bodies the opening may already have spawned stay out of shot.
	var spawned := _world.get_node_or_null(^"Spawned") as Node3D
	if spawned != null: spawned.visible = false
	# A resident character standing inside the fight area (the practice
	# trainer lives on this clearing) moves to a trainer's place behind the
	# attacker, frozen, so the line of fire is clear and a 1.80 m figure
	# stays in shot as the scale ruler. Recorded in results.
	var clear_radius := float(world_cfg.get("clear_radius_m", 6.5))
	var slot := 0
	for node: Node in _world.find_children("*", "Node3D", true, false):
		var body := node as Node3D
		var npc := body.get_script() != null and str((body.get_script() as Script).resource_path).ends_with("npc_body.gd")
		if not (npc or body is CharacterBody3D) or not body.is_visible_in_tree(): continue
		var local := _arena.to_local(body.global_position)
		if Vector2(local.x, local.z).length() > clear_radius: continue
		body.process_mode = Node.PROCESS_MODE_DISABLED
		var spot := Vector3(float(world_cfg.get("trainer_spot_x", -6.8)), 0.0, float(world_cfg.get("trainer_spot_z", 1.6)) + slot * 1.3)
		spot.y = _local_ground_y(spot.x, spot.z)
		body.global_position = _arena.to_global(spot)
		body.global_rotation.y = _arena.global_rotation.y + PI * 0.5
		_relocated.append({"node": str(body.get_path()), "to_local": spot})
		slot += 1
	for i in int(world_cfg.get("post_freeze_frames", 30)): await process_frame
	return true


## F35 batch: actual accepted-ultimate presentation nodes through the real
## ULTIMATES.launch contract (frozen F23 row + bound actor), posed between a
## production attacker and the target on the configured stage. Shutters run on
## the presentation clock at authored offsets. No meter, HP or receipt.
func _run_ultimates() -> void:
	# The existing unit runner runs before SceneTree initialization. Keep its
	# pure cases there and exercise actual launch nodes in this deferred smoke.
	var proof := preload("res://tests/test_move_effects.gd").new()
	proof.before_each()
	proof.check_actual_ultimate_override_preserves_earned_rank_and_independent_breakthrough_growth()
	proof.after_each()
	_failures.append_array(proof.failures)
	_ultimate_override_assertions = proof.assertion_count
	print("F23 actual override assertions=%d failures=%d" % [proof.assertion_count, proof.failures.size()])
	ULTIMATES.config()
	ULTIMATES._config["enabled"] = true # Process-local diagnostic opt-in only.
	var cfg: Dictionary = _scenarios.ultimate_capture
	var ids: Array = (ULTIMATES._config.visuals as Dictionary).keys()
	ids.sort()
	var counts: Array = cfg.breakthroughs if _breakthrough_filter.is_empty() else _breakthrough_filter
	for move_id: String in ids:
		if not _ultimate_filter.is_empty() and move_id not in _ultimate_filter: continue
		if not _moves.has(move_id): _failures.append("Ultimate visual without move " + move_id); continue
		for count: int in counts:
			var ranks: Array = [1] if _rank_filter.is_empty() else _rank_filter
			for rank: int in ranks: await _exercise_ultimate(move_id, int(count), cfg, rank)

func _exercise_ultimate(move_id: String, count: int, cfg: Dictionary, rank: int = 1) -> void:
	var move: Dictionary = _moves[move_id]
	var signature: Dictionary = move.get("ultimate", {})
	var duration := float(signature.get("presentation_seconds", 2.4))
	var travel := minf(float(cfg.travel_seconds), duration * 0.5)
	var encounter := "%s:b%d:r%d" % [move_id, count, rank]
	var species := move_id.trim_prefix("ultimate_")
	var case := {"id": move_id}
	if bool(signature.get("unique", false)):
		if _species_has_model(species): case["attacker_species"] = species
		else: case["attacker_fallback"] = species
	var from := _attacker_origin(case, move_id, 0.0)
	if not from.is_finite(): _failures.append("Attacker model missing " + encounter); return
	var to := _target.global_position + Vector3.UP * float(_target.call("body_height")) * 0.5
	if bool(cfg.get("auto_frame", false)) and not _no_autoframe: _frame_fight(cfg)
	var binding := {"character_id": "f35-proof", "creature_uid": "f35-proof-attacker",
		"encounter_id": encounter, "generation": 1, "action": 1}
	var spec := {"slot": "ultimate", "move_id": move_id, "action_id": encounter + ":1",
		"actor_binding": binding, "mastery_rank": rank, "breakthrough_count": count,
		"ultimate": signature.duplicate(true), "vfx": move.get("vfx", {}).duplicate(true)}
	var context := {"current_actor": binding, "travel_seconds": travel,
		"recipient_character_id": "f35-proof", "source_ground": _ground_point(_arena.to_local(from).x, 0.0),
		"target_ground": _ground_point(_target_x, 0.0)}
	var effect: Node3D = ULTIMATES.launch(_arena, from, to, spec, context)
	if effect == null: _failures.append("Ultimate launch refused " + encounter); return
	if not LIBRARY.ultimate_override(move_id).is_empty():
		var actual_row: Dictionary = effect.get("_row")
		var actual_frozen: Dictionary = effect.get("_context")
		if actual_row.get("mastery_rank") != rank or actual_frozen.get("mastery_rank") != rank:
			_failures.append("Ultimate override replaced earned mastery " + encounter)
	if _current_attacker != null and _current_attacker.has_method("play_attack"): _current_attacker.call("play_attack")
	var arrivals := [0]
	var away := (to - from).normalized()
	var tint: Variant = COMBAT_VFX.tint_for_type(str(move.get("type", "")))
	effect.connect("arrived", func() -> void:
		arrivals[0] += 1
		if _target.has_method("play_combat_flinch"): _target.call("play_combat_flinch", away)
		COMBAT_VFX.hit(_arena, to, tint, true, _target, 0.6))
	var ready := {}
	var shutters: Dictionary = cfg.shutters
	for phase: String in shutters:
		var at := float(shutters[phase]) * travel if phase in ["windup", "travel"] else (travel + float(shutters[phase]) if phase != "late" else duration - float(shutters[phase]))
		create_timer(maxf(0.0, at), false).timeout.connect(func() -> void: ready[phase] = true)
	var captured := {}
	var deadline := create_timer(duration + 1.5, false)
	var started := Time.get_ticks_usec()
	while deadline.time_left > 0.0 and captured.size() < shutters.size():
		await process_frame
		for phase: String in shutters:
			if captured.has(phase) or not bool(ready.get(phase, false)): continue
			await RenderingServer.frame_post_draw
			var path := _out.path_join("ultimate-%02d-%s.png" % [_records.size(), phase])
			print("F35 capture %s %s wall=%dms" % [encounter, phase, Time.get_ticks_msec()])
			if root.get_texture().get_image().save_png(path) != OK: _failures.append("Capture failed " + path)
			captured[phase] = {"wall_seconds": float(Time.get_ticks_usec() - started) / 1000000.0, "arrivals": arrivals[0]}
	if captured.size() != shutters.size(): _failures.append("Incomplete ultimate frames " + encounter)
	if int(arrivals[0]) != 1: _failures.append("Ultimate arrival count %d %s" % [arrivals[0], encounter])
	_records.append({"id": move_id, "mastery_rank": rank, "breakthrough_count": count, "presentation_seconds": duration,
		"travel_seconds": travel, "unique": bool(signature.get("unique", false)), "attacker": case,
		"captures": captured, "arrivals": arrivals[0]})
	if is_instance_valid(effect): effect.call("cancel_presentation")
	for i in 3: await process_frame

func _species_has_model(species: String) -> bool:
	var probe := CREATURE.instantiate() as CharacterBody3D
	probe.set_script(CREATURE_BODY)
	_arena.add_child(probe)
	probe.call("setup", species)
	var found := bool(probe.call("has_model"))
	probe.queue_free()
	return found


## Fit the camera to the posed attacker and target (legendaries are many
## times a starter's size) along the configured view direction, with
## headroom above for effects that arrive from the sky.
func _frame_fight(cfg: Dictionary) -> void:
	var camera := get_root().get_viewport().get_camera_3d()
	if camera == null or _current_attacker == null or _target == null: return
	var inverse := _arena.global_transform.affine_inverse()
	var box := AABB()
	var first := true
	for body: Node3D in [_current_attacker, _target]:
		var pivot := body.call("model_pivot") as Node3D
		var local := inverse * pivot.global_transform * RENDER_BOUNDS.measure(pivot)
		box = local if first else box.merge(local)
		first = false
	box = box.grow(float(cfg.get("frame_margin_m", 0.6)))
	box.size.y *= float(cfg.get("frame_headroom", 1.5))
	var centre := box.get_center()
	var view: Array = cfg.get("frame_view_direction", [0.05, 0.28, 1.0])
	var direction := Vector3(float(view[0]), float(view[1]), float(view[2])).normalized()
	var half_v := deg_to_rad(camera.fov) * 0.5
	var aspect := float(root.size.x) / float(root.size.y)
	var half_h := atan(tan(half_v) * aspect)
	var radius_x := box.size.x * 0.5
	var radius_y := box.size.y * 0.5
	var distance := maxf(radius_x / tan(half_h), radius_y / tan(half_v)) + box.size.z * 0.5
	camera.global_position = _arena.to_global(centre + direction * distance)
	camera.look_at(_arena.to_global(centre), Vector3.UP)
