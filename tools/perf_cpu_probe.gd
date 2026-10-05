extends "res://tools/catalogue_survey.gd"

## PERF lane CPU probe. Headless is allowed here and intended: the Dummy
## renderer removes GPU and llvmpipe cost, leaving the main-thread process
## and physics-step cost of the real production world at an F26 route stand.
##
##   godot --headless --path . --script tools/perf_cpu_probe.gd -- \
##     --biome=meadows --output=res://ralph/reports/PERF/probe/meadows_cpu.json
##
## Each experiment toggles one suspected cost, samples, and restores it, so a
## row's delta against "baseline" is that cost on this CPU. Container CPU is
## not a device; compare rows against each other, not against a frame budget.

const ROUTES_PATH := "res://data/config/lookdev_routes.json"
const MEADOWS_OPENING_FLAGS := [
	"opening:beat:wake", "opening:beat:house", "opening:beat:choose",
	"opening:starter_granted", "opening:beat:name", "opening:beat:return_starter",
	"opening:beat:walk_out",
]

var _out_path := ""
var _frames := 240
var _report: Dictionary = {}


func _prepare_character_fixture(game: Node) -> void:
	if _biome_id != "meadows":
		return
	for flag: String in MEADOWS_OPENING_FLAGS:
		game.get("progression").call("set_flag", flag)


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--biome="):
			_biome_id = arg.trim_prefix("--biome=").strip_edges().to_lower()
		elif arg.begins_with("--output="):
			_out_path = arg.trim_prefix("--output=").strip_edges()
		elif arg.begins_with("--frames="):
			_frames = maxi(10, int(arg.trim_prefix("--frames=")))
	var config: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROUTES_PATH))
	if not SCENES.has(_biome_id) or _out_path == "" or not config is Dictionary:
		push_error("perf cpu probe: needs --biome and --output")
		quit(2)
		return
	var route: Dictionary = config.routes[_biome_id]
	if not await _mount_production_world():
		push_error(str(_failures))
		quit(1)
		return
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as SpringArm3D
	var raw: Array = route.start
	var here := Vector3(float(raw[0]), 0.0, float(raw[raw.size() - 1]))
	if raw.size() == 3:
		here.y = float(raw[1])
	else:
		var ground := float(_world.call("ground_height_at", here.x, here.z))
		here.y = resolve_capture_ground(_player, here.x, here.z, ground)
	_player.global_position = here + Vector3.UP * TRAINER_CLEARANCE
	_player.velocity = Vector3.ZERO
	if _rig != null:
		_rig.global_position = _player.global_position
	for _frame in 120:
		await process_frame
	_report = {
		"schema": "perf_cpu_probe/1",
		"biome": _biome_id,
		"stand": [here.x, here.y, here.z],
		"display_server": DisplayServer.get_name(),
		"processor_count": OS.get_processor_count(),
		"frames_per_row": _frames,
		"disclosure": "Headless Dummy renderer: CPU main-thread process and physics-step cost only.",
		"rows": [],
	}
	var census := _animation_census()
	_report["animation_census"] = census
	await _row("baseline")
	var paused := _set_dormant_animation(false)
	await _row("dormant_creature_animation_paused", {"players_paused": paused.size()})
	for player: AnimationMixer in paused:
		player.active = true
	var stopped := _set_all_animation(false)
	await _row("all_animation_paused", {"players_paused": stopped.size()})
	for player: AnimationMixer in stopped:
		player.active = true
	await _row("baseline_again")
	_save()
	print("PERF CPU %s -> %s" % [_biome_id, _out_path])
	quit(0)


func _row(label: String, extra: Dictionary = {}) -> void:
	for _frame in 20:
		await process_frame
	var process_sum := 0.0
	var physics_sum := 0.0
	var process_peak := 0.0
	var steps_before := Engine.get_physics_frames()
	var started := Time.get_ticks_usec()
	for _frame in _frames:
		await process_frame
		var p := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		process_sum += p
		process_peak = maxf(process_peak, p)
		physics_sum += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var wall_ms := float(Time.get_ticks_usec() - started) / 1000.0
	var row := {
		"label": label,
		"process_ms_avg": process_sum / _frames,
		"process_ms_peak": process_peak,
		"physics_step_ms_avg": physics_sum / _frames,
		"wall_ms_per_frame": wall_ms / _frames,
		"physics_steps_per_frame": float(Engine.get_physics_frames() - steps_before) / _frames,
	}
	row.merge(extra)
	(_report.rows as Array).append(row)
	print("PERF CPU %s %s process=%.2fms physics=%.2fms wall=%.2fms/frame" % [
		_biome_id, label, row.process_ms_avg, row.physics_step_ms_avg, row.wall_ms_per_frame])


func _owner_body(node: Node) -> CharacterBody3D:
	var at := node.get_parent()
	while at != null and at != _world:
		if at is CharacterBody3D:
			return at as CharacterBody3D
		at = at.get_parent()
	return null


func _mixers() -> Array[AnimationMixer]:
	var out: Array[AnimationMixer] = []
	for node: Node in _world.find_children("*", "AnimationMixer", true, false):
		out.append(node as AnimationMixer)
	return out


func _animation_census() -> Dictionary:
	var total := 0
	var active := 0
	var playing := 0
	var in_dormant_body := 0
	var in_body := 0
	for mixer: AnimationMixer in _mixers():
		total += 1
		if mixer.active:
			active += 1
		if mixer is AnimationPlayer and (mixer as AnimationPlayer).is_playing():
			playing += 1
		var body := _owner_body(mixer)
		if body != null:
			in_body += 1
			if not body.is_physics_processing():
				in_dormant_body += 1
	return {"mixers": total, "active": active, "playing": playing, "in_character_body": in_body,
		"in_dormant_character_body": in_dormant_body}


func _set_dormant_animation(on: bool) -> Array[AnimationMixer]:
	var changed: Array[AnimationMixer] = []
	for mixer: AnimationMixer in _mixers():
		var body := _owner_body(mixer)
		if body != null and body != _player and not body.is_physics_processing() and mixer.active != on:
			mixer.active = on
			changed.append(mixer)
	return changed


func _set_all_animation(on: bool) -> Array[AnimationMixer]:
	var changed: Array[AnimationMixer] = []
	for mixer: AnimationMixer in _mixers():
		if mixer.active != on:
			mixer.active = on
			changed.append(mixer)
	return changed


func _save() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_path.get_base_dir()))
	var file := FileAccess.open(_out_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_report, "\t") + "\n")
		file.close()
