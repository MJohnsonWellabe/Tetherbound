extends "res://tests/helpers/net_harness.gd"

## C2/F25#4 native stress capture. Three owned companions and one ordinary
## shared wild are four production combat bodies, with three real ENet owners.
## Rank-5 loadouts and initial endurance HP are synthetic pre-admission setup;
## normal move inputs, cooldowns, energy, collision/hits and wild AI run live.
## This records a workload and its frame rate, not an earned progression proof
## or a guarantee that the wild produces a fourth named F25 effect.
## Run the coordinator headless; --peer-exe=<release exe> launches all peers
## from that same executable/PCK (which must include the C2 peer script).
## Optional --out=<absolute fresh evidence directory> uses harness isolation.

const C2_PEER_SCRIPT := "res://tests/helpers/f25_four_creature_peer.gd"
const WARMUP_SECONDS := 10.0
const MEASUREMENT_SECONDS := 60.0
const WORKLOAD := [
	{"species": "cindercub", "quick": "ember_bite", "charged": "fireball", "slot": "charged"},
	{"species": "tempestwing", "quick": "quick_flit", "charged": "gust_burst", "slot": "charged"},
	{"species": "ripplet", "quick": "ripple_jab", "charged": "undertow", "slot": "charged"},
]

var _c2_peer_exe := ""
var _c2_peer_ids: Array[String] = []
var _c2_setup: Array[Dictionary] = []
var _c2_status: Dictionary = {}
var _c2_summary: Dictionary = {}
var _c2_output := ""
var _c2_measurements_valid := false

func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--peer-exe="):
			_c2_peer_exe = arg.trim_prefix("--peer-exe=")
		elif arg.begins_with("--out="):
			OS.set_environment("TB_NET_OUT_DIR", arg.trim_prefix("--out="))
	_run_c2()

func _init_budgets() -> void:
	super._init_budgets()
	# Three simultaneous cold worlds have a separate bounded hello allowance.
	_budgets["hello_budget_s"] = 600.0

func _spawn_peer(i: int, role: String, control_port: int, enet_port: int,
		scene: String, home: String, log_path: String, extra_args: Array) -> int:
	var exe := OS.get_executable_path() if _c2_peer_exe.is_empty() else _c2_peer_exe
	if not FileAccess.file_exists(exe):
		check(false, "peer executable exists: " + exe)
		return -1
	var args: Array = []
	if i == 0:
		args.append_array(["--rendering-method", "forward_plus", "--rendering-driver", "vulkan",
			"--resolution", "1920x1080", "--fullscreen"])
	else:
		args.append("--headless")
	# A release executable finds its adjacent PCK; --path would silently turn
	# that into a source-project run. Editor peers all use this checkout.
	if _c2_peer_exe.is_empty():
		args.append_array(["--path", ProjectSettings.globalize_path("res://")])
	if _is_windows():
		args.append_array(["--log-file", log_path])
	args.append_array(["--script", C2_PEER_SCRIPT, "--", "--role=%s" % role,
		"--peer=%d" % i, "--control-port=%d" % control_port,
		"--enet-port=%d" % enet_port, "--scene=%s" % scene,
		"TB_NET_RUN_ID=%s" % _run_id])
	for extra: Variant in extra_args:
		args.append(str(extra))
	# Keep the existing harness's private save roots, argv ownership token,
	# deterministic world seed and direct child PID/exec cleanup contract.
	OS.set_environment("XDG_DATA_HOME", home)
	if _is_windows():
		OS.set_environment("APPDATA", home)
	OS.set_environment("TB_NET_RUN_ID", _run_id)
	var seed := OS.get_environment("TB_NET_WORLD_SEED")
	OS.set_environment("TB_WORLD_SEED", seed if not seed.is_empty() else "0")
	if _is_windows():
		return OS.create_process(exe, args)
	var parts: Array[String] = [_shq(exe)]
	for arg: Variant in args:
		parts.append(_shq(str(arg)))
	return OS.create_process("/bin/sh", ["-c", "exec %s >%s 2>&1" %
		[" ".join(parts), _shq(log_path)]])

func _c2_step(peer: int, action: String, args: Dictionary = {}) -> Dictionary:
	var result: Dictionary = await step(peer, action, args)
	check(str(result.get("verdict", "")) == "PASS", "peer %d %s: %s" %
		[peer, action, str(result.get("detail", "missing verdict"))])
	return result

func _c2_ok() -> bool:
	return failures.is_empty() and _fatal_reason.is_empty()

func _c2_dict_probe(peer: int, what: String) -> Dictionary:
	var value: Variant = await probe(peer, what)
	check(value is Dictionary, "peer %d returned %s evidence" % [peer, what])
	return value as Dictionary if value is Dictionary else {}

func _run_c2() -> void:
	require_peer_logs_without(["SCRIPT ERROR:", "ERROR:"], "C2 peers emit no engine or script errors")
	if not await launch(3, "world", [], {1: ["--joiner"], 2: ["--joiner"]}):
		await _finish_c2()
		return
	_c2_output = _run_dir.path_join("native-host")
	check(_peers.size() == 3, "three child processes tracked by the existing harness")
	for i in 3:
		check(str(await probe(i, "input_context")) == "world", "peer %d ready in world" % i)
		var prepared: Dictionary = await _c2_step(i, "f25_prepare", WORKLOAD[i].duplicate(true))
		_c2_setup.append({"peer_index": i, "workload": WORKLOAD[i], "prepare": prepared})
	if not _c2_ok():
		await _finish_c2()
		return

	await _c2_step(0, "host")
	var hosted: Dictionary = await _c2_dict_probe(0, "session")
	var port := int(hosted.get("enet_port", 0))
	check(port > 0, "host reports its real ENet port")
	if not _c2_ok():
		await _finish_c2()
		return
	for i in [1, 2]:
		await _c2_step(i, "join", {"host": "127.0.0.1", "port": port})
		if not _c2_ok():
			await _finish_c2()
			return
	for i in 3:
		await _c2_step(i, "expect_peers", {"count": 3})
		var session: Dictionary = await _c2_dict_probe(i, "session")
		var peer_id := int(session.get("peer_id", 0))
		check(peer_id == 1 if i == 0 else peer_id > 1, "peer %d has real ENet identity %d" % [i, peer_id])
		check(not _c2_peer_ids.has(str(peer_id)), "peer %d has a distinct ENet identity" % i)
		_c2_peer_ids.append(str(peer_id))
		await _c2_step(i, "deploy_creature")
	if not _c2_ok():
		await _finish_c2()
		return

	var staged: Dictionary = await _c2_step(0, "f25_stage_wild", {"species": "cindercub"})
	_c2_setup.append({"staged_wild": staged})
	if not _c2_ok():
		await _finish_c2()
		return
	await _c2_step(0, "engage_wild")
	var fight: Dictionary = await _c2_dict_probe(0, "encounter")
	var encounter_id := str(fight.get("id", ""))
	check(not encounter_id.is_empty() and str(fight.get("kind", "")) == "wild",
		"host opened a real shared wild encounter")
	var staged_data: Dictionary = staged.get("data", {})
	var opponent_card: Dictionary = fight.get("opponent_card", {})
	check(not str(staged_data.get("uid", "")).is_empty() and
		str(opponent_card.get("uid", "")) == str(staged_data.get("uid", "")),
		"encounter opponent is the exact staged endurance wild")
	var position: Variant = fight.get("opponent_pos")
	check(position is Array and (position as Array).size() == 3, "host reports opponent position")
	if not _c2_ok():
		await _finish_c2()
		return
	var here: Array = position
	for i in [1, 2]:
		# One-off setup travel, entirely before input bots and measurement.
		await _c2_step(i, "teleport", {"at": [float(here[0]) + (-2.5 if i == 1 else 2.5),
			float(here[1]) + 1.0, float(here[2])]})
		var announced: Dictionary = await _c2_dict_probe(i, "encounter")
		for _poll in 16:
			if (announced.get("joinable", []) as Array).has(encounter_id):
				break
			await _c2_step(i, "wait", {"frames": 15})
			announced = await _c2_dict_probe(i, "encounter")
		check((announced.get("joinable", []) as Array).has(encounter_id),
			"peer %d received the actual encounter announcement" % i)
		if not _c2_ok():
			await _finish_c2()
			return
		await _c2_step(i, "join_encounter", {"encounter_id": encounter_id})
		var joined: Dictionary = await _c2_dict_probe(i, "encounter")
		check(str(joined.get("bound_id", "")) == encounter_id and bool(joined.get("fighting", false)),
			"peer %d bound to the same live production fight" % i)
		if not _c2_ok():
			await _finish_c2()
			return
	var admitted: Dictionary = await _c2_dict_probe(0, "encounter")
	check(_same_peer_ids(admitted.get("participants", [])), "host admits exactly all three real owners")
	check(str(admitted.get("phase", "")) == "active", "three-owner fight is active before timing")
	if not _c2_ok():
		await _finish_c2()
		return

	# Clients start first and outlast the host window. No setup command runs
	# once the host is armed; the native host excludes its ten-second warmup.
	for i in [1, 2]:
		await _c2_step(i, "f25_arm", {"duration_seconds": 90.0, "warmup_seconds": WARMUP_SECONDS,
			"measurement_seconds": 80.0, "sample": false, "output_dir": ""})
	await _c2_step(0, "f25_arm", {"duration_seconds": WARMUP_SECONDS + MEASUREMENT_SECONDS,
		"warmup_seconds": WARMUP_SECONDS, "measurement_seconds": MEASUREMENT_SECONDS,
		"sample": true, "output_dir": _c2_output})
	if not _c2_ok():
		await _finish_c2()
		return
	var deadline := Time.get_ticks_msec() + 180000
	while Time.get_ticks_msec() < deadline and _c2_ok():
		_c2_status = await _c2_dict_probe(0, "f25_status")
		if bool(_c2_status.get("done", false)):
			break
		var next_poll := Time.get_ticks_msec() + 1000
		while Time.get_ticks_msec() < next_poll and _c2_ok():
			await process_frame
			_pump_once()
	check(bool(_c2_status.get("done", false)), "native host completed its bounded live sample")
	if _c2_ok():
		_validate_c2_capture()
	await _finish_c2()

func _same_peer_ids(raw: Variant) -> bool:
	if not raw is Array or (raw as Array).size() != 3:
		return false
	var seen: Array[String] = []
	for value: Variant in raw:
		var key := str(value)
		if not _c2_peer_ids.has(key) or seen.has(key):
			return false
		seen.append(key)
	return seen.size() == 3

func _validate_c2_capture() -> void:
	_c2_summary = _c2_status.get("summary", {})
	check((_c2_status.get("failures", []) as Array).is_empty() and
		(_c2_summary.get("failures", []) as Array).is_empty(), "peer reports no fixture failures")
	var settings: Dictionary = _c2_summary.get("settings", {})
	check(str(settings.get("renderer", "")) == "forward_plus", "measured host uses Forward+")
	check(str(settings.get("display", "")).to_lower() not in ["headless", "dummy"] and
		not str(settings.get("display", "")).is_empty(), "measured host has a native display")
	check(str(settings.get("preset", "")) == "Medium", "measured host uses Medium")
	check(settings.get("resolution", []) == [1920, 1080] and bool(settings.get("fullscreen", false)),
		"measured native host is fullscreen at 1920x1080")
	check(float(_c2_summary.get("warmup_seconds", -1)) == WARMUP_SECONDS,
		"native host excludes ten seconds of warmup")
	check(float(_c2_summary.get("measurement_seconds", 0)) >= MEASUREMENT_SECONDS and
		int(_c2_summary.get("sample_count", 0)) > 0, "native host records at least sixty seconds of frames")
	check(_same_peer_ids(_c2_summary.get("peer_ids", [])), "capture identifies all three admitted ENet owners")
	check(int(_c2_summary.get("participants_min", -1)) == 3 and
		int(_c2_summary.get("combat_bodies_min", -1)) == 4 and
		int(_c2_summary.get("visible_bodies_min", -1)) == 4,
		"census sustains exactly three participants and four live visible bodies")
	for field: String in ["rank5_launches_by_peer", "damage_by_peer"]:
		var counts: Dictionary = _c2_summary.get(field, {})
		check(counts.size() == 3, field + " has exactly three owner entries")
		for peer_id: String in _c2_peer_ids:
			check(int(counts.get(peer_id, 0)) > 0, field + " proves owner " + peer_id)
	var initial_hp := float(_c2_summary.get("host_hp_before", -1))
	var final_hp := float(_c2_summary.get("host_hp_after", -1))
	check(is_finite(initial_hp) and is_finite(final_hp) and initial_hp > final_hp and final_hp > 0,
		"real authoritative opponent HP decreases while the opponent stays alive")
	check(int(_c2_summary.get("particle_cap", -1)) == 384 and
		int(_c2_summary.get("particle_peak", -1)) >= 0 and
		int(_c2_summary.get("particle_peak", 385)) <= 384, "production encounter particle budget stays within 384")
	check(int(_c2_summary.get("scene_lights_cap", -1)) == 4 and
		int(_c2_summary.get("scene_lights_peak", 5)) <= 4 and
		int(_c2_summary.get("mesh_bodies_per_effect_peak", 13)) <= 12,
		"production light and body caps are retained")
	for field: String in ["average_fps", "one_percent_low_fps", "minimum_fps"]:
		var value := float(_c2_summary.get(field, -1))
		check(is_finite(value) and value > 0.0, field + " is a finite measured value")
	check(FileAccess.file_exists(_c2_output.path_join("results.json")), "raw frame, launch, impact and census evidence exists")
	check(FileAccess.file_exists(_c2_output.path_join("native-after.png")), "native frame capture exists")
	if _c2_ok():
		_validate_c2_raw()
	_c2_measurements_valid = _c2_ok()

func _validate_c2_raw() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_c2_output.path_join("results.json")))
	check(parsed is Dictionary, "native raw report is valid JSON")
	if not parsed is Dictionary:
		return
	var raw: Dictionary = parsed
	check(raw.get("summary", {}) == _c2_summary, "raw report and control-channel summary agree")
	var frames: Array = raw.get("wall_frame_seconds", [])
	check(frames.size() == int(_c2_summary.get("sample_count", -1)), "all measured frame samples are retained")
	var elapsed := 0.0
	var valid_frames := not frames.is_empty()
	for frame: Variant in frames:
		var seconds := float(frame)
		if not is_finite(seconds) or seconds <= 0.0:
			valid_frames = false
		elapsed += seconds
	check(valid_frames and elapsed >= MEASUREMENT_SECONDS, "raw finite frame intervals span the full sixty seconds")
	var launches: Array = raw.get("launches", [])
	var actions: Dictionary = {}
	var launched: Dictionary = {}
	var valid_launches := not launches.is_empty()
	for value: Variant in launches:
		if not value is Dictionary:
			valid_launches = false
			continue
		var row: Dictionary = value
		var owner := str(row.get("peer_id", ""))
		var index := _c2_peer_ids.find(owner)
		var action_id := str(row.get("action_id", ""))
		var pieces := action_id.split(":")
		var binding: Dictionary = row.get("actor_binding", {})
		var move_id := str(row.get("move_id", ""))
		if (index < 0 or pieces.size() < 3 or pieces[pieces.size() - 2] != owner or
				int(row.get("rank", -1)) != 5 or row.get("valid") != true or
				str(row.get("presentation_script", "")) != "res://scripts/vfx/move_effect.gd" or binding.is_empty()):
			valid_launches = false
			continue
		if move_id != str(WORKLOAD[index].quick) and move_id != str(WORKLOAD[index].charged):
			valid_launches = false
			continue
		actions[action_id] = owner
		launched[owner] = int(launched.get(owner, 0)) + 1
	check(valid_launches, "raw launches retain real owner/action identities, frozen rank5, named moves and production effects")
	var damaged: Dictionary = {}
	var impacts: Array = raw.get("impacts", [])
	for value: Variant in impacts:
		if not value is Dictionary:
			continue
		var impact: Dictionary = value
		var action_id := str(impact.get("action_id", ""))
		var damage := float(impact.get("applied_damage", impact.get("damage", 0.0)))
		if actions.has(action_id) and is_finite(damage) and damage > 0.0:
			var owner := str(actions[action_id])
			damaged[owner] = int(damaged.get(owner, 0)) + 1
	for owner: String in _c2_peer_ids:
		check(int(launched.get(owner, 0)) > 0 and int(damaged.get(owner, 0)) > 0,
			"raw rank5 launch and matching positive host damage prove owner " + owner)
	var census: Array = raw.get("census", [])
	var valid_census := not census.is_empty()
	for value: Variant in census:
		if not value is Dictionary:
			valid_census = false
			continue
		var row: Dictionary = value
		if (not _same_peer_ids(row.get("participants", [])) or int(row.get("combat_bodies", -1)) != 4 or
				int(row.get("visible_bodies", -1)) != 4 or float(row.get("hp", -1)) <= 0 or
				int(row.get("particles", -1)) < 0 or int(row.get("particles", 385)) > 384):
			valid_census = false
	check(valid_census, "every retained census has all owners, four live visible bodies and bounded particles")

func _finish_c2() -> void:
	var code: int = await finish()
	# finish() includes forbidden-log checks and owned PID teardown. Persist
	# the final failures even when setup/timing exits early; never mark a skip.
	if not _run_dir.is_empty():
		var report := FileAccess.open(_run_dir.path_join("f25-result.json"), FileAccess.WRITE)
		if report == null:
			check(false, "coordinator can write final C2 evidence")
			code = 1
		else:
			report.store_string(JSON.stringify({"run_id": _run_id, "exit_code": code,
				"measurements_valid": _c2_measurements_valid and code == 0,
				"performance_acceptance": "requires review of the recorded frame rate; no threshold invented by this fixture",
				"scope": "isolated rank5 initial-endurance loadout, three real peers + one ordinary shared wild; normal live input/AI/hits",
				"peer_executable": OS.get_executable_path() if _c2_peer_exe.is_empty() else _c2_peer_exe,
				"peer_script": C2_PEER_SCRIPT, "peer_ids": _c2_peer_ids, "setup": _c2_setup,
				"native_output": _c2_output, "host_status": _c2_status,
				"summary": _c2_summary, "failures": failures, "fatal": _fatal_reason}, "\t"))
			report.close()
	quit(code)
