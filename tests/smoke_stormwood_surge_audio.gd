extends SceneTree

## F10 #5 audio witness (AUDIO §4.3, §9, §12.1): the production Stormwood
## world, its real Surge clock and its real host lightning, observed by the
## realm's StormwoodSurgeAudio node. It proves WIRING AND TIMING only: every
## Surge phase cue fires once on entering its phase, every Break strike has a
## spatial warning at the strike's ground position telegraph_seconds before
## impact, strikes are spaced 4-8 s, no warning fires outside Break, the
## release bed opens once, and the cue log is empty after realm teardown.
## It does NOT prove that anything was heard: no Stormwood asset exists, the
## observer plays a cue only when its asset exists, and every row here records
## played=false. The MISSING ASSETS list below is the asset gap.
##
## Disclosed fixtures and time controls:
## - The trainer is stood on open, unsheltered Conductor Run / Deepwood ground
##   (found by the lightning's own `exposed()` check) and re-pinned there every
##   frame, and its health is refilled every frame, so real strikes keep
##   landing on it for the whole Break without a death/recovery teleport.
## - The Surge clock (Game.realm_environment.stormwood.elapsed, the value the
##   host Surge itself advances) is set to a few seconds before each phase
##   boundary; every boundary and the whole 120 s Break then run in real time.
## - The Long Storm's end is committed through the ledger's set_world_flag.
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const STORMWOOD_SCENE := preload("res://scenes/world/stormwood.tscn")
const OBSERVER := preload("res://scripts/world/stormwood_surge_audio.gd")
const TEST_SAVE_DIR := "user://stormwood_surge_audio_smoke"
const OUT_DIR := "user://f10_audio_witness"
const LEAD_S := 4.0
const FRAME_TOL_S := 0.25

var _failures: Array[String] = []
var _passes := 0
var _done := false
var _world: Node3D
var _player: CharacterBody3D
var _spot := Vector3.ZERO
var _game: Node
var _lightning: Node
var _draws: Array[float] = []
var _last_next := -1.0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(900.0).timeout.connect(func() -> void:
		_expect(false, "900 second watchdog expired")
		_finish())
	_game = root.get_node_or_null(^"Game")
	await process_frame
	_game.call("reset_for_new_game")
	_game.set("save_system", SAVE_GAME.new(TEST_SAVE_DIR))
	_game.set("current_realm", "stormwood")
	_game.call("bind_realm_map")
	_world = STORMWOOD_SCENE.instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	while not bool(_world.call("shell_build_complete")):
		await process_frame
	var surge: Node = _world.get_node("StormwoodSurge")
	_lightning = _world.get_node("StormwoodLightning")
	var observer: Node = _world.get_node_or_null("StormwoodSurgeAudio")
	_expect(observer != null and observer.get_script() == OBSERVER, "StormwoodSurgeAudio is mounted by the production Stormwood world")
	if observer == null:
		_finish()
		return
	_player = _world.get_node("Player") as CharacterBody3D
	var strike_cfg: Dictionary = _lightning.get("rules").config.strike
	var telegraph := float(strike_cfg.telegraph_seconds)
	var interval_min := float(strike_cfg.interval_min)
	var interval_max := float(strike_cfg.interval_max)
	print("LIGHTNING CONFIG telegraph_seconds=%.3f interval=%.1f..%.1f" % [telegraph, interval_min, interval_max])
	if not is_equal_approx(telegraph, 1.2):
		print("!! FLAG: strike.telegraph_seconds is %.3f, not the AUDIO §4.3 1.2 s" % telegraph)
	if not (is_equal_approx(interval_min, 4.0) and is_equal_approx(interval_max, 8.0)):
		print("!! FLAG: strike interval is %.1f..%.1f, not the AUDIO §4.3 4-8 s" % [interval_min, interval_max])

	# Open, exposed ground on a standard-length Surge region.
	var found := false
	for z in [2300.0, 2500.0, 2800.0, 3100.0, 3400.0, 3700.0, 4000.0, 4300.0, 4600.0]:
		for x in [-2200.0, -1800.0, -1400.0, -1000.0, -600.0, -200.0, 200.0]:
			var at := Vector3(x, 0.0, z)
			at.y = float(_world.call("ground_height_near", at))
			var region := str(surge.call("region_at", at))
			if not region in ["conductor_run", "deepwood"]:
				continue
			_player.global_position = at + Vector3.UP * 0.1
			_player.velocity = Vector3.ZERO
			for _i in 10:
				await physics_frame
			if bool(_lightning.call("exposed", at, _player)):
				_spot = at
				found = true
				break
		if found:
			break
	_expect(found, "an open, exposed trainer stance found by the lightning's own exposed() (%s, %s)" % [
		str(_spot), str(surge.call("region_at", _spot)) if found else "-"])
	if not found:
		_finish()
		return

	# Calm from the start of the cycle (the realm-entry bed), then each
	# boundary crossed in real time.
	_set_clock(0.0)
	await _hold_until(8.0)
	_set_clock(240.0 - LEAD_S)
	await _hold_until(248.0)
	_set_clock(330.0 - LEAD_S)
	_draws.clear()
	_last_next = float(_lightning.get("_next"))
	await _hold_until(450.0 + 8.0, true)
	var draws := _draws.duplicate()
	# The Long Storm ends: the release bed opens once.
	var ledger: Node = _game.get("ledger")
	var flag_ok := bool(ledger.call("submit", {"kind": "set_world_flag", "realm": "stormwood",
		"id": OBSERVER.LONG_STORM_ENDED, "value": true}).get("ok", false))
	_expect(flag_ok, "the Long Storm's end committed through the ledger")
	await _hold_frames(30)
	# Replay the last impact through the replicated event: a duplicate must
	# not fire a second strike chain.
	var cues_before: Array = (observer.get("cue_log") as Array).duplicate(true)
	var last_impact: Dictionary = {}
	for row: Dictionary in cues_before:
		if str(row.cue) == "sw_strike_crack":
			last_impact = row
	if not last_impact.is_empty():
		var p: Array = last_impact.position
		_game.get_node("Session").emit_signal("stormwood_strike_received",
			{"id": int(last_impact.strike_id), "kind": "impact", "at": Vector3(p[0], p[1], p[2]), "hits": {}})
		_game.get_node("Session").emit_signal("stormwood_strike_received",
			{"id": int(last_impact.strike_id), "kind": "warning", "at": Vector3(p[0], p[1], p[2])})
	var cues: Array = (observer.get("cue_log") as Array).duplicate(true)
	_expect(cues.size() == cues_before.size(), "a replayed impact/warning id fires no second cue (%d -> %d rows)" % [cues_before.size(), cues.size()])

	_check(cues, draws, telegraph, interval_min, interval_max)
	_write(cues, draws, telegraph)

	# Teardown: the realm leaves the tree; the observer clears and disconnects.
	var session: Node = _game.get_node("Session")
	root.remove_child(_world)
	var cleared: bool = (observer.get("cue_log") as Array).is_empty()
	var disconnected: bool = not session.stormwood_strike_received.is_connected(Callable(observer, "_on_strike"))
	_expect(cleared, "the cue log is empty after realm teardown")
	_expect(disconnected, "the observer is disconnected from the replicated lightning event after teardown")
	_world.free()
	_world = null
	_finish()


func _set_clock(seconds: float) -> void:
	var environment: Dictionary = _game.get("realm_environment")
	var storm: Dictionary = (environment.get("stormwood", {}) as Dictionary).duplicate(true)
	storm["elapsed"] = seconds
	environment["stormwood"] = storm
	_game.set("realm_environment", environment)


func _clock() -> float:
	return float((_game.get("realm_environment") as Dictionary).get("stormwood", {}).get("elapsed", 0.0))


func _pin() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_player.global_position = _spot + Vector3.UP * 0.1
	_player.velocity = Vector3.ZERO
	var vitals: Variant = _player.get("vitals")
	if vitals is Object:
		(vitals as Object).set("health", float((vitals as Object).get("max_health")))


func _hold_until(clock: float, watch_draws: bool = false) -> void:
	while _clock() < clock and not _done:
		await process_frame
		_pin()
		if watch_draws:
			# The host scheduler redraws `_next` from interval_min..max after
			# each countdown; an upward jump is one scheduled strike slot,
			# whether or not a warning follows (read-only observation).
			var now := float(_lightning.get("_next"))
			if now > _last_next + 0.5:
				_draws.append(_clock())
			_last_next = now


func _hold_frames(frames: int) -> void:
	for _i in frames:
		await process_frame
		_pin()


func _check(cues: Array, draws: Array, telegraph: float, interval_min: float, interval_max: float) -> void:
	var beds := cues.filter(func(r: Dictionary) -> bool: return not str(r.cue).begins_with("sw_strike"))
	var bed_ids: Array = beds.map(func(r: Dictionary) -> String: return str(r.cue))
	_expect(bed_ids == ["sw_surge_calm_bed", "sw_surge_building_bed", "sw_surge_break_bed", "sw_surge_fading_decay", "sw_release_forest_sky_bed"],
		"phase cues fire exactly once each, in order Calm, Building, Break, Fading, release: %s" % str(bed_ids))
	var boundaries := {"sw_surge_building_bed": 240.0, "sw_surge_break_bed": 330.0, "sw_surge_fading_decay": 450.0}
	for row: Dictionary in beds:
		if boundaries.has(str(row.cue)):
			var at := float(boundaries[str(row.cue)])
			_expect(float(row.surge_clock_s) >= at and float(row.surge_clock_s) <= at + FRAME_TOL_S,
				"%s fires at its phase boundary (clock %.3f, boundary %.0f)" % [row.cue, float(row.surge_clock_s), at])
	var warnings := {}
	var impacts := {}
	var warning_order: Array = []
	for row: Dictionary in cues:
		if str(row.cue) == "sw_strike_warning":
			warnings[int(row.strike_id)] = row
			warning_order.append(row)
		elif str(row.cue) == "sw_strike_crack":
			impacts[int(row.strike_id)] = row
	var layers_ok := true
	for layer: String in ["sw_strike_body", "sw_strike_decay"]:
		var ids: Array = cues.filter(func(r: Dictionary) -> bool: return str(r.cue) == layer).map(func(r: Dictionary) -> int: return int(r.strike_id))
		ids.sort()
		var crack_ids: Array = impacts.keys()
		crack_ids.sort()
		layers_ok = layers_ok and ids == crack_ids
	_expect(layers_ok, "every impact fires its strike, body and decay layers once each")
	_expect(warnings.size() >= 8, "real Break strikes happened (%d warnings, %d impacts)" % [warnings.size(), impacts.size()])
	var bad_phase := warning_order.filter(func(r: Dictionary) -> bool: return str(r.phase) != "break")
	_expect(bad_phase.is_empty(), "no strike warning fires in Calm, Building or Fading (%d outside Break)" % bad_phase.size())
	var impacts_outside := 0
	var orphan := 0
	var deltas: Array[float] = []
	var pos_ok := true
	for id: int in impacts:
		var impact: Dictionary = impacts[id]
		if str(impact.phase) != "break":
			impacts_outside += 1
		if not warnings.has(id):
			orphan += 1
			continue
		var warning: Dictionary = warnings[id]
		var wp: Array = warning.position
		var ip: Array = impact.position
		pos_ok = pos_ok and Vector3(wp[0], wp[1], wp[2]).distance_to(Vector3(ip[0], ip[1], ip[2])) < 0.001
		deltas.append(float(impact.surge_clock_s) - float(warning.surge_clock_s))
	_expect(orphan == 0, "every strike has a warning with its id (%d without)" % orphan)
	_expect(pos_ok, "every warning's position equals its strike's position")
	# A Break-end warning may resolve just after the boundary; that impact
	# still belongs to a Break warning and is reported, not hidden.
	print("IMPACTS RESOLVING OUTSIDE BREAK (from a Break warning): %d" % impacts_outside)
	var dmin := 999.0
	var dmax := -1.0
	for d: float in deltas:
		dmin = minf(dmin, d)
		dmax = maxf(dmax, d)
	_expect(not deltas.is_empty() and dmin >= telegraph - 0.001 and dmax <= telegraph + FRAME_TOL_S,
		"warning -> strike is telegraph_seconds %.2f (+ one frame): min %.3f max %.3f s over %d strikes" % [telegraph, dmin, dmax, deltas.size()])
	var gaps: Array[float] = []
	for i in range(1, warning_order.size()):
		gaps.append(float(warning_order[i].surge_clock_s) - float(warning_order[i - 1].surge_clock_s))
	var draw_gaps: Array[float] = []
	for i in range(1, draws.size()):
		draw_gaps.append(float(draws[i]) - float(draws[i - 1]))
	var gmin := 999.0
	var gmax := -1.0
	for g: float in gaps:
		gmin = minf(gmin, g)
		gmax = maxf(gmax, g)
	var dgmin := 999.0
	var dgmax := -1.0
	for g: float in draw_gaps:
		dgmin = minf(dgmin, g)
		dgmax = maxf(dgmax, g)
	print("STRIKE SPACING warnings: n=%d min=%.3f max=%.3f  scheduler slots: n=%d min=%.3f max=%.3f" % [
		gaps.size(), gmin, gmax, draw_gaps.size(), dgmin, dgmax])
	print("STRIKE SPACING gaps: %s" % str(gaps.map(func(g: float) -> String: return "%.2f" % g)))
	_expect(not gaps.is_empty() and gmin >= interval_min - FRAME_TOL_S and gmax <= interval_max + FRAME_TOL_S,
		"Break strike spacing is within %.0f-%.0f s (measured %.3f..%.3f)" % [interval_min, interval_max, gmin, gmax])
	var played_wrong := cues.filter(func(r: Dictionary) -> bool: return bool(r.played) and not bool(r.asset_present))
	_expect(played_wrong.is_empty(), "no cue claims playback without its asset")
	var caption_ok := cues.all(func(r: Dictionary) -> bool: return not str(r.caption).contains("{"))
	_expect(caption_ok, "every caption is resolved (direction wedge filled)")


func _write(cues: Array, draws: Array, telegraph: float) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var contract: Dictionary = OBSERVER.load_config()
	var file := FileAccess.open(OUT_DIR.path_join("cue_log.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"telegraph_seconds": telegraph, "scheduler_slots_clock_s": draws, "cues": cues}, "  "))
	file.close()
	var fired := {}
	for row: Dictionary in cues:
		fired[str(row.cue)] = int(fired.get(str(row.cue), 0)) + 1
	var missing: Array[Dictionary] = []
	for cue: Dictionary in OBSERVER.all_cues(contract):
		if not ResourceLoader.exists(str(cue.asset_path)):
			missing.append(cue)
	var md := "# Stormwood Surge audio witness: cue timeline\n\n"
	md += "Headless, production Stormwood world, real Surge clock and host lightning. `surge_clock_s` is the replicated Surge clock; `t_msec` is `Time.get_ticks_msec()`. `played` is false for every row: no asset exists, so nothing was heard. This proves wiring and timing only.\n\n"
	md += "| # | surge clock s | t_msec | phase | cue | strike | position | asset present | played | caption |\n|---|---:|---:|---|---|---:|---|---|---|---|\n"
	var n := 0
	for row: Dictionary in cues:
		n += 1
		var pos := "-"
		if row.position is Array:
			pos = "(%.1f, %.1f, %.1f)" % [row.position[0], row.position[1], row.position[2]]
		md += "| %d | %.3f | %d | %s%s | `%s` | %s | %s | %s | %s | %s |\n" % [n, float(row.surge_clock_s), int(row.t_msec),
			"aftermath " if bool(row.aftermath) else "", row.phase, row.cue, str(row.strike_id) if int(row.strike_id) >= 0 else "-",
			pos, row.asset_present, row.played, str(row.caption).replace("|", "/")]
	var out := FileAccess.open(OUT_DIR.path_join("cue_timeline.md"), FileAccess.WRITE)
	out.store_string(md)
	out.close()
	var mm := "# Stormwood Surge audio: missing assets\n\nEvery cue in `data/config/stormwood_audio.json` whose intended asset does not exist. None was generated, synthesized or copied in. The observer plays each cue automatically once its file lands at this path.\n\n"
	mm += "| asset path | cue | bus | positional | fired in witness | AUDIO §4.3 row |\n|---|---|---|---|---:|---|\n"
	print("")
	print("=================== MISSING ASSETS (%d) ===================" % missing.size())
	for cue: Dictionary in missing:
		print("  MISSING %s  <- cue %s (%s)" % [cue.asset_path, cue.id, cue.spec_row])
		mm += "| `%s` | `%s` | %s | %s | %d | %s |\n" % [cue.asset_path, cue.id, cue.bus, cue.positional, int(fired.get(str(cue.id), 0)), cue.spec_row]
	print("  No Stormwood Surge/lightning cue was heard: every row played=false.")
	print("============================================================")
	var mf := FileAccess.open(OUT_DIR.path_join("MISSING_ASSETS.md"), FileAccess.WRITE)
	mf.store_string(mm)
	mf.close()
	print("WITNESS WRITTEN %s" % ProjectSettings.globalize_path(OUT_DIR))


func _expect(condition: bool, message: String) -> void:
	if condition:
		_passes += 1
		print("  PASS: ", message)
	else:
		_failures.append(message)
		print("  FAIL: ", message)


func _finish() -> void:
	if _done:
		return
	_done = true
	var absolute := ProjectSettings.globalize_path(TEST_SAVE_DIR)
	if DirAccess.dir_exists_absolute(absolute):
		for file: String in DirAccess.get_files_at(absolute):
			DirAccess.remove_absolute(absolute.path_join(file))
		DirAccess.remove_absolute(absolute)
	print("STORMWOOD SURGE AUDIO WITNESS %s: %d passed, %d failed (wiring and timing only; no audio played)" % [
		"OK" if _failures.is_empty() else "FAILED", _passes, _failures.size()])
	quit(0 if _failures.is_empty() else 1)
