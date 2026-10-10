extends "res://tools/net/peer_runner.gd"

## The peer process of the two-peer proof command
## (`tools/net/run_two_peer_proof.sh`, runner `tests/smoke_net_proof_two_peer.gd`).
##
## Exactly `peer_runner.gd` -- every step and probe, the heartbeat, the control
## channel -- plus the proof steps in `tools/net/proof_steps.gd` (named saves,
## screenshots, save capture and checks, F11). Kept as its own script so the
## shared peer runner every smoke uses is unchanged; only the proof runner
## launches this one.

const PROOF_STEPS := preload("res://tools/net/proof_steps.gd")
## The Stormwood lane's own proof steps (F11#3), in their own file.
const STORMWOOD_STEPS := preload("res://tools/net/proof_steps_stormwood.gd")
## The Tidewake lane's reward-pocket claim steps (F13#2), in their own file.
const TIDEWAKE_POCKET_STEPS := preload("res://tools/net/proof_steps_tidewake_pockets.gd")
const F37_STEPS := preload("res://tools/net/proof_steps_f37.gd")
const F48_STEPS := preload("res://tools/net/proof_steps_f48.gd")
## CI segment checkpoints (tests/helpers/ci_segments.gd).
const SEGMENT_STEPS := preload("res://tools/net/proof_steps_segments.gd")
const F25_BOOT := preload("res://tools/lookdev_capture_bootstrap.gd")
const F25_GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")
const F25_BUDGET := preload("res://scripts/vfx/move_effect_budget.gd")
const F25_LIBRARY := preload("res://scripts/vfx/move_effect_library.gd")
var _f25_meta: Dictionary = {}
var _f25_profile: Dictionary = {}
var _f25_rows: Array[Array] = []
var _f25_actions: Dictionary = {}
var _f25_verdicts: Array[Dictionary] = []
var _f25_bodies: Dictionary = {}
var _f25_expected: Dictionary = {}
var _f25_manager: WeakRef
var _f25_director: WeakRef
var _f25_encounter := ""
var _f25_output := ""
var _f25_running := false
var _f25_started := false
var _f25_error := ""
var _f25_start_usec := 0
var _f25_previous_usec := 0
var _f25_overlap := 0
var _f25_peak_particles := 0
var _f25_peak_lights := 0


func _initialize() -> void:
	if _parse_args().has("f25-measured-peer"):
		_f25_meta = F25_BOOT.prepare(self)
		if _f25_meta.is_empty() or _f25_meta.get("preset") != "Medium" or str(_parse_args().get("peer")) != "0":
			quit(2)
			return
		_f25_output = str(_parse_args().get("output", ""))
		# Enable before boot/warmup: timing readiness never discards timed rows.
		RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	await super()


func _execute_step(msg: Dictionary) -> Dictionary:
	var action := str(msg.get("action", ""))
	if action == "f25_frame_start": return _f25_start(msg.get("args", {}))
	if action == "f25_frame_stop": return _f25_stop()
	if action.begins_with("f48_"):
		if action == "f48_fixture_trainer_fight":
			# This dispatch bypasses the base win_trainer_battle branch. Carry its
			# actual outer budget into diagnostic retention only; execution bounds
			# remain with the coordinator and the original input driver.
			_trainer_fight_command_budget_frames = int(msg.get("budget_frames", NET_STEP_BUDGET_FRAMES))
		return await F48_STEPS.step(self, action, msg.get("args", {}))
	if action.begins_with("f37_"):
		return await F37_STEPS.step(self, action, msg.get("args", {}))
	if SEGMENT_STEPS.handles(action):
		return SEGMENT_STEPS.run(self, action, msg.get("args", {}))
	var stormwood := STORMWOOD_STEPS.handles(action)
	var pockets := TIDEWAKE_POCKET_STEPS.handles(action)
	if not stormwood and not pockets and not PROOF_STEPS.handles(action):
		return await super(msg)
	var before := _physics_count
	var args := msg.get("args", {}) as Dictionary
	var out: Dictionary
	if pockets:
		out = await TIDEWAKE_POCKET_STEPS.run(self, action, args)
	elif stormwood:
		out = await STORMWOOD_STEPS.run(self, action, args)
	else:
		out = await PROOF_STEPS.run(self, action, args)
	out["frames_used"] = _physics_count - before
	return out


## Passive collector attached only to the opt-in native host. Reads production
## signals and budget pools; it cannot submit actions or change combat state.
func _f25_start(args: Dictionary) -> Dictionary:
	if _f25_started or _f25_meta.is_empty() or DisplayServer.get_name() == "headless" \
			or RenderingServer.get_current_rendering_method() != "forward_plus" or F25_GRAPHICS.selected() != "Medium" \
			or root.size != Vector2i(1920, 1080) or not get_multiplayer().is_server():
		return {"verdict": "FAIL", "detail": "F25 requires one fresh native host Forward+ Medium 1080p collector"}
	_f25_profile = (args.get("profile", {}) as Dictionary).duplicate(true)
	var owned: Array = _f25_profile.get("owned", [])
	var manager := _combat_manager()
	var director := _encounter_director()
	if owned.size() != 4 or manager == null or director == null or not bool(manager.call("is_fighting")):
		return {"verdict": "FAIL", "detail": "F25 needs a real active admitted four-creature encounter"}
	var record: Dictionary = director.call("encounter_record")
	var participants: Dictionary = record.get("participants", {})
	_f25_encounter = str(record.get("encounter_id", ""))
	if participants.size() != 4 or _f25_encounter.is_empty() or str(record.get("phase", "")) != "active":
		return {"verdict": "FAIL", "detail": "F25 encounter does not hold four active participants"}
	for peer: Variant in participants:
		var character := str((participants[peer] as Dictionary).get("character_id", ""))
		var expected: Dictionary = {}
		for input: Dictionary in owned:
			if str(input.get("character_id", "")) == character: expected = input
		var body := director.call("deployed_body_for", int(peer)) as Node3D
		var card: Dictionary = director.call("_creature_card_for", int(peer))
		if expected.is_empty() or not is_instance_valid(body) or str(card.get("creature_uid", "")) != str(expected.get("creature_uid", "")):
			return {"verdict": "FAIL", "detail": "F25 participant/deployed owned UID differs from reviewed input"}
		_f25_bodies[character] = weakref(body)
		_f25_expected[character] = expected
	var camera := root.get_camera_3d()
	var environment := current_scene.get_node_or_null(^"WorldEnvironment") as WorldEnvironment
	if camera == null or environment == null or environment.environment == null:
		return {"verdict": "FAIL", "detail": "F25 actual world camera/environment missing"}
	var values := F25_GRAPHICS.values()
	for feature: String in F25_GRAPHICS.FEATURES:
		var property := "volumetric_fog_enabled" if feature == "volumetric_fog" else feature + "_enabled"
		if bool(environment.environment.get(property)) != bool(values.get(feature, false)):
			return {"verdict": "FAIL", "detail": "F25 actual environment differs from production Medium: " + feature}
	if DirAccess.dir_exists_absolute(_f25_output) or DirAccess.make_dir_recursive_absolute(_f25_output) != OK:
		return {"verdict": "FAIL", "detail": "F25 output must be fresh and writable"}
	_f25_meta["graphics_values"] = values
	_f25_meta["window_size"] = [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y]
	_f25_meta["camera_path"] = str(camera.get_path())
	_f25_meta["camera_position"] = [camera.global_position.x, camera.global_position.y, camera.global_position.z]
	_f25_meta["camera_far"] = camera.far
	_f25_meta["godot_version"] = Engine.get_version_info()
	_f25_meta["process_id"] = OS.get_process_id()
	_f25_meta["run_id"] = OS.get_environment("TB_NET_RUN_ID")
	_f25_meta["save_home"] = OS.get_user_data_dir()
	_f25_meta["encounter_id"] = _f25_encounter
	_f25_manager = weakref(manager)
	_f25_director = weakref(director)
	manager.connect("attack_launched", _f25_launch)
	manager.connect("impact_confirmed", _f25_impact)
	director.connect("host_strike_finished", _f25_host_verdict)
	_f25_start_usec = Time.get_ticks_usec()
	_f25_previous_usec = _f25_start_usec
	_f25_started = true
	_f25_running = true
	RenderingServer.frame_post_draw.connect(_f25_frame)
	return {"verdict": "PASS", "detail": "Passive native frame window attached; four authentic deployed participants"}


func _f25_launch(on_enemy: bool, launch: Dictionary, presentation: Node3D) -> void:
	if not _f25_running or not on_enemy or str(launch.get("encounter_id", "")) != _f25_encounter: return
	if _f25_actions.size() >= 512:
		_f25_error = "action witness overflow"
		return
	var move: Dictionary = launch.get("move", {})
	var binding: Dictionary = move.get("actor_binding", {})
	var character := str(binding.get("character_id", ""))
	if not _f25_expected.has(character): return
	var expected: Dictionary = _f25_expected[character]
	var matches := str(binding.get("creature_uid", "")) == str(expected.creature_uid) \
		and str(launch.get("move_id", "")) == str(expected.move_id) and str(move.get("slot", "")) == str(expected.slot) \
		and int(move.get("mastery_rank", -1)) == int(expected.mastery_rank) and int(move.get("breakthrough_count", -1)) == int(expected.breakthrough_count)
	var id := str(launch.get("action_id", ""))
	if id.is_empty() or _f25_actions.has(id):
		_f25_error = "missing or duplicate actual launch identity"
		return
	_f25_actions[id] = {"action_id": id, "character_id": character, "creature_uid": str(binding.get("creature_uid", "")),
		"move_id": str(launch.get("move_id", "")), "slot": str(move.get("slot", "")), "mastery_rank": int(move.get("mastery_rank", -1)),
		"breakthrough_count": int(move.get("breakthrough_count", -1)), "reviewed_move_matches": matches,
		"launch_usec": Time.get_ticks_usec() - _f25_start_usec, "contact_usec": -1, "applied_damage": -1.0,
		"presentation": weakref(presentation) if is_instance_valid(presentation) else null}


func _f25_impact(on_enemy: bool, receipt: Dictionary, _position: Vector3) -> void:
	if not _f25_running or not on_enemy: return
	var id := str(receipt.get("action_id", ""))
	if not _f25_actions.has(id): return
	var row: Dictionary = _f25_actions[id]
	if int(row.contact_usec) >= 0: _f25_error = "duplicate actual impact"
	row.contact_usec = Time.get_ticks_usec() - _f25_start_usec
	row.applied_damage = float(receipt.get("applied_damage", receipt.get("damage", -1.0)))


func _f25_host_verdict(intent: Dictionary, peer: int, verdict: Dictionary) -> void:
	if not _f25_running: return
	if _f25_verdicts.size() >= 512:
		_f25_error = "host verdict witness overflow"
		return
	_f25_verdicts.append({"peer": peer, "move_id": str(intent.get("move_id", "")), "ok": bool(verdict.get("ok", false)),
		"code": str(verdict.get("code", "")), "usec": Time.get_ticks_usec() - _f25_start_usec})


## Frustum/node witness only, explicitly not an occlusion/pixel visual verdict.
func _f25_visible(node: Node, camera: Camera3D) -> bool:
	if not is_instance_valid(node) or node.is_queued_for_deletion(): return false
	if node is Node3D and not (node as Node3D).is_visible_in_tree(): return false
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var mesh := node as MeshInstance3D
		var centre := mesh.global_transform * mesh.get_aabb().get_center()
		if not camera.is_position_behind(centre) and root.get_visible_rect().has_point(camera.unproject_position(centre)) \
				and camera.global_position.distance_to(centre) < camera.far: return true
	for child: Node in node.get_children():
		if _f25_visible(child, camera): return true
	return false


func _f25_frame() -> void:
	if not _f25_running: return
	var now := Time.get_ticks_usec()
	var camera := root.get_camera_3d()
	var director := _f25_director.get_ref() as Node
	if camera == null or not is_instance_valid(director):
		_f25_error = "camera or encounter owner disappeared"
		_f25_detach()
		return
	var record: Dictionary = director.call("encounter_record")
	if str(record.get("encounter_id", "")) != _f25_encounter or str(record.get("phase", "")) != "active" \
			or (record.get("participants", {}) as Dictionary).size() != 4:
		_f25_error = "measured admitted four-participant encounter ended or changed"
		_f25_detach()
		return
	var visible_bodies := 0
	for ref: WeakRef in _f25_bodies.values():
		if _f25_visible(ref.get_ref() as Node, camera): visible_bodies += 1
	var visible_authors := {}
	for row: Dictionary in _f25_actions.values():
		if not bool(row.reviewed_move_matches) or not row.presentation is WeakRef: continue
		if _f25_visible((row.presentation as WeakRef).get_ref() as Node, camera): visible_authors[row.character_id] = true
	if visible_authors.size() == 4 and visible_bodies == 4: _f25_overlap += 1
	var particles := F25_BUDGET.used(_f25_encounter)
	var lights := F25_BUDGET.lights_used()
	_f25_peak_particles = maxi(_f25_peak_particles, particles)
	_f25_peak_lights = maxi(_f25_peak_lights, lights)
	var rid := root.get_viewport_rid()
	var cpu := RenderingServer.viewport_get_measured_render_time_cpu(rid)
	var gpu := RenderingServer.viewport_get_measured_render_time_gpu(rid)
	if not is_finite(gpu) or gpu <= 0.0 or not is_finite(cpu) or cpu <= 0.0: _f25_error = "real viewport CPU/GPU timing unavailable, zero or nonfinite"
	_f25_rows.append([(now - _f25_start_usec) / 1000.0, (now - _f25_previous_usec) / 1000.0,
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		cpu, gpu, RenderingServer.get_frame_setup_time_cpu(), visible_bodies, visible_authors.size(), particles, lights])
	_f25_previous_usec = now
	if _f25_rows.size() >= int(_f25_profile.get("max_frames", 0)) or (now - _f25_start_usec) / 1000000.0 >= float(_f25_profile.get("max_seconds", 0.0)):
		_f25_error = "bounded collector window exhausted before explicit stop"
		_f25_detach()


func _f25_detach() -> void:
	_f25_running = false
	if RenderingServer.frame_post_draw.is_connected(_f25_frame): RenderingServer.frame_post_draw.disconnect(_f25_frame)
	if _f25_manager != null:
		var manager := _f25_manager.get_ref() as Node
		if is_instance_valid(manager):
			if manager.is_connected("attack_launched", _f25_launch): manager.disconnect("attack_launched", _f25_launch)
			if manager.is_connected("impact_confirmed", _f25_impact): manager.disconnect("impact_confirmed", _f25_impact)
	if _f25_director != null:
		var director := _f25_director.get_ref() as Node
		if is_instance_valid(director) and director.is_connected("host_strike_finished", _f25_host_verdict): director.disconnect("host_strike_finished", _f25_host_verdict)


func _f25_percentiles(column: int) -> Dictionary:
	var values: Array[float] = []
	for row: Array in _f25_rows: values.append(float(row[column]))
	values.sort()
	if values.is_empty(): return {"p95": 0.0, "p99": 0.0, "max": 0.0}
	return {"p95": values[clampi(int(ceil(values.size() * 0.95)) - 1, 0, values.size() - 1)],
		"p99": values[clampi(int(ceil(values.size() * 0.99)) - 1, 0, values.size() - 1)], "max": values.back()}


func _f25_stop() -> Dictionary:
	if not _f25_started: return {"verdict": "FAIL", "detail": "F25 native collector was never started"}
	_f25_detach()
	var accepted := {}
	var actions: Array[Dictionary] = []
	for row: Dictionary in _f25_actions.values():
		var value := row.duplicate()
		value.erase("presentation")
		actions.append(value)
		if bool(row.reviewed_move_matches) and int(row.contact_usec) >= 0 and is_finite(float(row.applied_damage)) and float(row.applied_damage) > 0.0:
			accepted[row.character_id] = true
	var limits := F25_LIBRARY.config()
	var stats := {"wall_ms": _f25_percentiles(1), "process_ms": _f25_percentiles(2), "physics_ms": _f25_percentiles(3),
		"render_cpu_ms": _f25_percentiles(4), "render_gpu_ms": _f25_percentiles(5), "setup_cpu_ms": _f25_percentiles(6)}
	var passed := _f25_error.is_empty() and _f25_rows.size() >= int(_f25_profile.get("min_frames", 0)) \
		and _f25_overlap >= int(_f25_profile.get("min_overlap_frames", 0)) and accepted.size() == 4 \
		and _f25_peak_particles <= int(limits.get("encounter_particle_cap", 0)) and _f25_peak_lights <= int(limits.get("scene_light_cap", 0)) \
		and float(stats.wall_ms.p95) <= float(_f25_profile.get("frame_budget_ms", 0.0)) \
		and float(stats.render_gpu_ms.p95) <= float(_f25_profile.get("frame_budget_ms", 0.0))
	var manifest := {"verdict": "PASS" if passed else "FAIL", "error": _f25_error, "metadata": _f25_meta,
		"reviewed_profile": _f25_profile, "profile_sha256": JSON.stringify(_f25_profile).sha256_text(), "frames": _f25_rows.size(),
		"overlap_frames": _f25_overlap, "accepted_characters": accepted.keys(), "actions": actions, "host_verdicts": _f25_verdicts,
		"stats": stats, "peak_particles": _f25_peak_particles, "peak_lights": _f25_peak_lights,
		"particle_cap": int(limits.get("encounter_particle_cap", 0)), "light_cap": int(limits.get("scene_light_cap", 0)),
		"scope": "One physical adapter, four same-machine processes; native host viewport with three headless guests. Node/frustum overlap is not a blind visual verdict or Ally hardware proof.",
		"timing": "Godot measured viewport CPU/GPU milliseconds; raw zero/unavailable rows fail. Wall/process/physics/setup are separate, not substituted GPU values.",
		"fixtures_outside_window": ["existing arena placement and trainer challenge/admission", "original F48 HP ceiling completion only after explicit collector stop"],
		"collector_cost": "Passive signal storage and bounded visible-node traversal in the window; CSV/JSON writing after stop; no screenshot/readback"}
	var csv := FileAccess.open(_f25_output.path_join("frames.csv"), FileAccess.WRITE)
	var json := FileAccess.open(_f25_output.path_join("manifest.json"), FileAccess.WRITE)
	if csv == null or json == null: return {"verdict": "FAIL", "detail": "F25 could not retain raw failed/pass artifacts"}
	csv.store_csv_line(PackedStringArray(["elapsed_ms", "wall_ms", "process_ms", "physics_ms", "render_cpu_ms", "render_gpu_ms", "setup_cpu_ms", "visible_owned_bodies", "visible_move_authors", "particle_leases", "effect_lights"]))
	for row: Array in _f25_rows:
		var cells := PackedStringArray()
		for value: Variant in row: cells.append(str(value))
		csv.store_csv_line(cells)
	json.store_string(JSON.stringify(manifest, "\t"))
	csv.flush()
	json.flush()
	var retained := csv.get_error() == OK and json.get_error() == OK
	csv.close()
	json.close()
	return {"verdict": "PASS" if passed and retained else "FAIL", "detail": "F25 frames=%d four-author overlap=%d accepted=%d error=%s; %s"
		% [_f25_rows.size(), _f25_overlap, accepted.size(), _f25_error, _f25_output], "data": manifest}
