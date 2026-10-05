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
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--wait-s="):
			# Let the world clock reach the hours under study before measuring.
			var until := Time.get_ticks_msec() + int(float(arg.trim_prefix("--wait-s=")) * 1000.0)
			while Time.get_ticks_msec() < until:
				await process_frame
	var census := _animation_census()
	_report["animation_census"] = census
	if OS.get_cmdline_user_args().has("--soak"):
		await _soak()
		_save()
		quit(0)
		return
	if OS.get_cmdline_user_args().has("--walk"):
		await _walk_rows(route)
		_save()
		print("PERF CPU %s -> %s" % [_biome_id, _out_path])
		quit(0)
		return
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
	if OS.get_cmdline_user_args().has("--bisect"):
		await _bisect()
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


## Disable processing for one family of world children (or one autoload) at
## a time; the wall-time drop against the bracketing baseline is that
## family's main-thread cost. Families group numbered siblings.
func _bisect() -> void:
	var families := {}
	for child: Node in _world.get_children():
		var family := _family(str(child.name))
		if not families.has(family):
			families[family] = []
		(families[family] as Array).append(child)
	for child: Node in root.get_children():
		if child != _world:
			families["/root/" + str(child.name)] = [child]
	var rows: Array = []
	for family: String in families:
		var members: Array = families[family]
		var nodes := 0
		for node: Node in members:
			nodes += 1 + node.find_children("*", "", true, false).size()
			if nodes >= 20:
				break
		if nodes < 20 and not family.begins_with("/root/"):
			continue
		var before := await _wall(90)
		var modes: Array = []
		for node: Node in members:
			modes.append(node.process_mode)
			node.process_mode = Node.PROCESS_MODE_DISABLED
		var without := await _wall(90)
		for index in members.size():
			(members[index] as Node).process_mode = modes[index]
		var after := await _wall(90)
		var saved := (before + after) * 0.5 - without
		rows.append({"family": family, "members": members.size(), "wall_ms_saved": saved,
			"baseline_wall_ms": (before + after) * 0.5})
		if absf(saved) >= 1.0:
			print("PERF CPU BISECT %s (%d) saves %.2f ms of %.2f" % [family, members.size(), saved,
				(before + after) * 0.5])
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.wall_ms_saved) > float(b.wall_ms_saved))
	_report["bisect"] = rows


func _wall(frames: int) -> float:
	for _frame in 5:
		await process_frame
	var started := Time.get_ticks_usec()
	for _frame in frames:
		await process_frame
	return float(Time.get_ticks_usec() - started) / 1000.0 / frames


static func _family(node_name: String) -> String:
	var parts := node_name.split("_")
	if parts.size() > 1 and parts[0] == "Wild":
		return "Wild"
	var out: Array[String] = []
	for part: String in parts:
		if part.is_valid_int():
			break
		out.append(part)
	var joined := "_".join(out)
	while joined.length() > 0 and joined.right(1).is_valid_int():
		joined = joined.left(-1)
	return joined if joined != "" else node_name


## Walk the trainer along the F26 route at walking pace (position driven, so
## every streaming system sees ordinary movement) and record frame wall time:
## mean, p99 and max. Then repeat with one suspect family disabled at a time.
const WALK_SPEED := 5.0
const WALK_SUSPECTS := ["GrassField", "Vegetation", "Terrain", "EncounterDirector", "Water",
	"River", "PlaygroundHUD", "InteractionArbiter", "WorldAudio", "WorldLook", "Village",
	"VillageNPCs", "CameraRig", "/root/Game"]


## Stand still for ten minutes of wall time with nothing toggled; every 30 s
## record frame wall time and the counts a per-frame leak would grow.
func _soak() -> void:
	var rows: Array = []
	for sample in 20:
		var started := Time.get_ticks_usec()
		var frames := 0
		while Time.get_ticks_usec() - started < 30000000:
			await process_frame
			frames += 1
		var groups := {}
		for group: String in ["creature_voice", "interaction_provider", "remote_trainer"]:
			groups[group] = get_nodes_in_group(group).size()
		var row := {"t_s": (sample + 1) * 30, "ms_per_frame": 30000.0 / maxf(1.0, frames),
			"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
			"resources": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
			"orphans": Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
			"static_mem_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
			"groups": groups}
		var look := _world.get_node_or_null(^"WorldLook")
		if look != null and look.has_method("hour"):
			row["hour"] = float(look.call("hour"))
		rows.append(row)
		print("PERF CPU SOAK t=%ds %.2f ms/frame nodes=%d objects=%d orphans=%d mem=%.0fMB hour=%s" % [
			row.t_s, row.ms_per_frame, row.nodes, row.objects, row.orphans, row.static_mem_mb,
			str(row.get("hour", "?"))])
	_report["soak"] = rows


func _walk_rows(route: Dictionary) -> void:
	var points: Array[Vector3] = []
	var raws: Array = [route.start]
	raws.append_array(route.waypoints)
	for raw: Array in raws:
		var at := Vector3(float(raw[0]), 0.0, float(raw[raw.size() - 1]))
		at.y = float(raw[1]) if raw.size() == 3 else float(_world.call("ground_height_at", at.x, at.z))
		points.append(at)
	var rows: Array = []
	var base := await _walk(points)
	base["label"] = "walk_baseline"
	rows.append(base)
	print("PERF CPU WALK baseline mean=%.2f p99=%.2f max=%.2f ms" % [base.mean_ms, base.p99_ms, base.max_ms])
	for suspect: String in WALK_SUSPECTS:
		var node: Node = root.get_node_or_null(NodePath(suspect.trim_prefix("/root/"))) if suspect.begins_with("/root/") \
			else _world.get_node_or_null(NodePath(suspect))
		if node == null:
			continue
		var mode := node.process_mode
		node.process_mode = Node.PROCESS_MODE_DISABLED
		var row := await _walk(points)
		node.process_mode = mode
		row["label"] = "walk_without_" + suspect
		rows.append(row)
		print("PERF CPU WALK without %s mean=%.2f p99=%.2f max=%.2f ms" % [suspect, row.mean_ms, row.p99_ms, row.max_ms])
	var again := await _walk(points)
	again["label"] = "walk_baseline_again"
	rows.append(again)
	print("PERF CPU WALK baseline_again mean=%.2f p99=%.2f max=%.2f ms" % [again.mean_ms, again.p99_ms, again.max_ms])
	_report["walk"] = rows


func _walk(points: Array[Vector3]) -> Dictionary:
	var frames: Array[float] = []
	var previous := Time.get_ticks_usec()
	for leg in range(points.size() - 1):
		var from := points[leg]
		var to := points[leg + 1]
		var length := Vector2(to.x - from.x, to.z - from.z).length()
		var travelled := 0.0
		while travelled < length:
			await process_frame
			var now := Time.get_ticks_usec()
			var dt := float(now - previous) / 1000.0
			previous = now
			frames.append(dt)
			# Pace by simulated 60 Hz time, not wall time: the same distance
			# per frame on every run, whatever this CPU's frame rate.
			travelled = minf(length, travelled + WALK_SPEED / 60.0)
			var at := from.lerp(to, travelled / maxf(length, 0.001))
			at.y = float(_world.call("ground_height_at", at.x, at.z))
			_player.global_position = at + Vector3.UP * TRAINER_CLEARANCE
			_player.velocity = Vector3.ZERO
	# Walk back to the start so every row begins at the same place.
	_player.global_position = points[0] + Vector3.UP * TRAINER_CLEARANCE
	for _frame in 30:
		await process_frame
	frames.sort()
	var total := 0.0
	for value: float in frames:
		total += value
	return {"frames": frames.size(), "mean_ms": total / maxf(1.0, frames.size()),
		"p99_ms": frames[int(frames.size() * 0.99)] if not frames.is_empty() else 0.0,
		"max_ms": frames.back() if not frames.is_empty() else 0.0}


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
