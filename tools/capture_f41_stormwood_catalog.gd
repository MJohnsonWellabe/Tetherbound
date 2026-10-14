extends "res://tools/capture_stormwood_f10_matrix.gd"

## F41#0 production-camera recapture. Run once per named High/Medium preset
## against the same source SHA, output layout and capture stands. Each pass
## yields 200 matched frames: 50 distinct camera views through Calm, Building,
## Break and Fading. This deliberately does not stage aftermath or trigger a
## fight fixture. The Crown Arch witness remains with its P2-041 owner.
##
##   godot --path . --script tools/capture_f41_stormwood_catalog.gd -- \
##     --preset=High --source-commit=<40-hex-sha> \
##     --out=D:/CodexTemp/f41-stormwood/high --label=f41r0-high \
##     --phases=calm,building,break,fading --no-aftermath
##   godot --path . --script tools/capture_f41_stormwood_catalog.gd -- \
##     --preset=Medium --source-commit=<same-40-hex-sha> \
##     --out=D:/CodexTemp/f41-stormwood/medium --label=f41r0-medium \
##     --phases=calm,building,break,fading --no-aftermath
##   python tools/verify_f41_stormwood_capture.py \
##     --high-dir=D:/CodexTemp/f41-stormwood/high \
##     --medium-dir=D:/CodexTemp/f41-stormwood/medium \
##     --source-commit=<same-loaded-project-sha>
##
## Each frame's support receipt reads StormwoodSurge.phase/weather(),
## phase_at_position(), StormwoodLightning.sheltered(), the actual near-rain
## emitter, and the production CameraRig. Generic WorldWeather is not used as
## evidence. The Ashfoot inside/outside pair must prove actual roof support and
## rain suppression during Break. Captures are audit fixtures only: ordinary
## production world, real player camera and normal encounter population; no
## progression/save injection and no campaign claim.

const SPOTS_PATH := "res://data/config/debug_teleport_spots.json"
const EXPECTED_VIEWS := 50
const EXPECTED_PHASES := ["calm", "building", "break", "fading"]
const EXTRA_ANGLE_SUBJECTS := [
	"Verge Rod Station",
	"The Capacitor Grove",
	"The Fallen Giant",
	"The Glass Field",
	"The Stormheart Tree",
]
const THREE_VIEW_OFFSETS := [-90.0, 0.0, 90.0]
const SIX_VIEW_OFFSETS := [-150.0, -90.0, -30.0, 30.0, 90.0, 150.0]
const ASHFOOT_CENTER := Vector2(-365.0, 460.0)

var _requested_preset := ""
var _source_commit := ""


func _run() -> void:
	if not _validate_f41_args():
		quit(2)
		return
	await super._run()


func _validate_f41_args() -> bool:
	var output := ""
	var label := ""
	var phases := ""
	var no_aftermath := false
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--preset="):
			_requested_preset = arg.trim_prefix("--preset=")
		elif arg.begins_with("--source-commit="):
			_source_commit = arg.trim_prefix("--source-commit=")
		elif arg.begins_with("--out="):
			output = arg.trim_prefix("--out=")
		elif arg.begins_with("--label="):
			label = arg.trim_prefix("--label=")
		elif arg.begins_with("--phases="):
			phases = arg.trim_prefix("--phases=")
		elif arg == "--no-aftermath":
			no_aftermath = true
	var sha := RegEx.new()
	sha.compile("^[0-9a-f]{40}$")
	if DisplayServer.get_name() == "headless" or _requested_preset not in ["High", "Medium"]:
		push_error("F41 capture requires a rendering display and an explicit High or Medium preset")
		return false
	if sha.search(_source_commit) == null:
		push_error("F41 capture requires the exact 40-character source commit")
		return false
	var git_output: Array = []
	var project_root := ProjectSettings.globalize_path("res://")
	var git_exit := OS.execute("git", ["-C", project_root, "rev-parse", "HEAD"], git_output, true)
	if git_exit != 0 or git_output.is_empty() or str(git_output[0]).strip_edges() != _source_commit:
		push_error("F41 source commit must match the loaded project's Git HEAD")
		return false
	var status_output: Array = []
	var status_exit := OS.execute("git", ["-C", project_root, "status", "--porcelain", "--untracked-files=all"], status_output, true)
	var source_changes := str(status_output[0]).strip_edges() if not status_output.is_empty() else ""
	if status_exit != 0 or not source_changes.is_empty():
		push_error("F41 capture requires a clean tracked and untracked source tree")
		return false
	if output.is_empty() or label.is_empty():
		push_error("F41 capture requires explicit --out and --label values")
		return false
	if phases != "calm,building,break,fading" or not no_aftermath:
		push_error("F41 capture requires all four actual Surge phases and --no-aftermath")
		return false
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)):
		push_error("F41 capture output must be a fresh directory: " + output)
		return false
	return true


func _matrix_stands() -> Array:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SPOTS_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		_failures.append("F41 catalogue spots are missing or invalid")
		return []
	var stormwood: Dictionary = {}
	for biome_value: Variant in (parsed as Dictionary).get("biomes", []):
		if biome_value is Dictionary and str((biome_value as Dictionary).get("id", "")) == "stormwood":
			stormwood = biome_value
			break
	if stormwood.is_empty():
		_failures.append("F41 catalogue has no Stormwood biome")
		return []

	var views: Array = []
	for band_value: Variant in stormwood.get("bands", []):
		if not band_value is Dictionary:
			continue
		var band: Dictionary = band_value
		var spots: Array = band.get("spots", [])
		for index in spots.size():
			var spot_value: Variant = spots[index]
			if not spot_value is Dictionary:
				continue
			var spot: Dictionary = spot_value
			var name := str(spot.get("display_name", ""))
			# This exact Crown Arch view is a separate P2-041 carryover witness.
			if name == "The Crown Arch":
				continue
			var at := _parse_position(spot.get("position", null))
			if not at.is_finite():
				_failures.append("F41 has an invalid authored stand: " + name)
				continue
			var heading := _base_heading(spots, index, spot, at)
			var offsets: Array = SIX_VIEW_OFFSETS if name in EXTRA_ANGLE_SUBJECTS else THREE_VIEW_OFFSETS
			for view_index in offsets.size():
				var angle := deg_to_rad(heading + float(offsets[view_index]))
				var forward := Vector2(sin(angle), cos(angle))
				var focus_x := at.x + forward.x * 48.0
				var focus_z := at.y + forward.y * 48.0
				var ground := float(_world.call("ground_height_at", focus_x, focus_z))
				if not is_finite(ground):
					_failures.append("F41 view has no authored focus ground: " + name)
					continue
				var band_id := str(band.get("id", "stormwood"))
				var view_id := "%s_v%02d" % [_slug(band_id + "_" + name), view_index + 1]
				views.append({
					"id": view_id,
					"at": at,
					"focus": Vector3(focus_x, ground + 4.0, focus_z),
					"pitch": 2.0,
					"text": "%s, authored survey heading %d" % [name, view_index + 1],
					"support_case": "catalogue_world_view",
				})

	views.append_array(_ashfoot_shelter_stands())
	if views.size() != EXPECTED_VIEWS:
		_failures.append("F41 planned %d views; expected exactly %d (48 catalogue plus 2 shelter)" % [views.size(), EXPECTED_VIEWS])
	return views


func _parse_position(value: Variant) -> Vector2:
	var parts: PackedStringArray
	if value is String:
		parts = (value as String).strip_edges().split(" ", false)
	elif value is Array and (value as Array).size() == 2:
		parts = PackedStringArray([str((value as Array)[0]), str((value as Array)[1])])
	else:
		return Vector2(NAN, NAN)
	if parts.size() != 2 or not parts[0].is_valid_float() or not parts[1].is_valid_float():
		return Vector2(NAN, NAN)
	return Vector2(float(parts[0]), float(parts[1]))


func _base_heading(spots: Array, index: int, spot: Dictionary, at: Vector2) -> float:
	var authored: Variant = spot.get("view_heading_deg", null)
	if (typeof(authored) == TYPE_INT or typeof(authored) == TYPE_FLOAT) and is_finite(float(authored)):
		return float(authored)
	var neighbour_index := index + 1 if index < spots.size() - 1 else index - 1
	if neighbour_index < 0 or not spots[neighbour_index] is Dictionary:
		return 0.0
	var neighbour := _parse_position((spots[neighbour_index] as Dictionary).get("position", null))
	var direction := (neighbour - at).normalized()
	return rad_to_deg(atan2(direction.x, direction.y)) if direction.length_squared() > 0.0 else 0.0


func _ashfoot_shelter_stands() -> Array:
	var ground := float(_world.call("ground_height_at", ASHFOOT_CENTER.x, ASHFOOT_CENTER.y))
	if not is_finite(ground):
		_failures.append("F41 Ashfoot shelter stand has no authored ground")
		return []
	var yaw := deg_to_rad(135.0)
	var along := Vector2(sin(yaw), cos(yaw))
	var inside := ASHFOOT_CENTER + along * 0.6
	var outside := ASHFOOT_CENTER + Vector2(along.y, -along.x) * 11.0
	var focus := Vector3(ASHFOOT_CENTER.x - along.x * 6.0, ground + 1.4, ASHFOOT_CENTER.y - along.y * 6.0)
	return [
		{"id": "ashfoot_shelter_inside", "at": inside, "focus": focus, "pitch": -4.0,
			"text": "Ashfoot shelter interior; direct Stormwood roof and weather support receipt", "support_case": "shelter_inside"},
		{"id": "ashfoot_shelter_outside", "at": outside, "focus": Vector3(ASHFOOT_CENTER.x, ground + 1.4, ASHFOOT_CENTER.y), "pitch": 4.0,
			"text": "Ashfoot shelter exterior at 11 m; direct Stormwood roof and weather support receipt", "support_case": "shelter_outside"},
	]


func _matrix_pass(aftermath: bool) -> void:
	var stands := _matrix_stands()
	var phases: Array = ["calm"] if aftermath else _phases_only
	for stand: Dictionary in stands:
		await _stand(stand.at, stand.focus, float(stand.pitch))
		for phase: String in phases:
			await _enter_phase(phase, aftermath)
			_heal()
			# The direct phase/weather/shelter receipt is the F41#0 proof. The
			# random bolt wait belongs to the F10 lightning presentation pass and
			# would add an unbounded delay to every Break catalogue view.
			_hud_visible(_hud)
			var id := "%s_%s%s" % [str(stand.id), "aftermath_" if aftermath else "", phase]
			await _capture(id, "%s, %s%s" % [str(stand.text), "aftermath " if aftermath else "storm ", phase.capitalize()], true,
				{"f41_view_id": str(stand.id), "f41_support_case": str(stand.get("support_case", "catalogue_world_view"))})


func _capture(frame_id: String, description: String, full_size: bool, extra: Dictionary = {}) -> void:
	var receipt: Dictionary = await _stormwood_support_receipt(frame_id)
	if receipt.is_empty():
		return
	await super._capture(frame_id, description, full_size,
		extra.merged({"stormwood_support_receipt": receipt}, true))


func _stormwood_support_receipt(frame_id: String) -> Dictionary:
	if _surge == null or _lightning == null or _player == null or _camera == null:
		_failures.append(frame_id + ": production StormwoodSurge/StormwoodLightning/player camera is missing")
		return {}
	if frame_id.begins_with("ashfoot_shelter_"):
		# Let the actual 250 ms shelter probe and 0.6 s rain fade settle before
		# observing either side, without changing production timers.
		for _frame in 60:
			await physics_frame
	var expected_phase := frame_id.get_slice("_", frame_id.get_slice_count("_") - 1)
	var actual_phase := str(_surge.get("phase"))
	var phase_at_player := str(_surge.call("phase_at_position", _player.global_position))
	var expected_weather := "storm" if expected_phase == "break" else "rain"
	var actual_weather := str(_surge.call("weather"))
	var rain := _surge.get("_rain") as GPUParticles3D
	if actual_phase != expected_phase or phase_at_player != expected_phase:
		_failures.append(frame_id + ": direct production Surge phase does not match the requested phase")
		return {}
	if actual_weather != expected_weather or rain == null or _camera != root.get_camera_3d():
		_failures.append(frame_id + ": actual Surge weather emitter or production CameraRig binding is missing")
		return {}
	var sheltered := bool(_lightning.call("sheltered", _player.global_position, _player))
	var surge_sheltered := bool(_surge.get("sheltered"))
	if sheltered != surge_sheltered:
		_failures.append(frame_id + ": cached StormwoodSurge shelter state disagrees with the live StormwoodLightning guard")
		return {}
	var roofed := bool(_surge.get("_roofed"))
	var rain_ratio := rain.amount_ratio
	if frame_id.begins_with("ashfoot_shelter_inside_"):
		roofed = bool(_surge.get("_roofed"))
		sheltered = bool(_lightning.call("sheltered", _player.global_position, _player))
		surge_sheltered = bool(_surge.get("sheltered"))
		rain_ratio = rain.amount_ratio
		if not roofed or not sheltered or not surge_sheltered:
			_failures.append(frame_id + ": Ashfoot interior did not receive live roof and lightning shelter")
			return {}
		if expected_phase == "break" and rain_ratio > 0.05:
			_failures.append(frame_id + ": near rain was not suppressed under the actual Ashfoot roof")
			return {}
	elif frame_id.begins_with("ashfoot_shelter_outside_"):
		if roofed or sheltered or surge_sheltered:
			_failures.append(frame_id + ": Ashfoot 11 m exterior incorrectly received roof/lightning shelter")
			return {}
		if expected_phase == "break" and rain_ratio < 0.10:
			_failures.append(frame_id + ": near rain did not remain visible outside the Ashfoot roof")
			return {}
	return {
		"authority_node": str(_world.get_path_to(_surge)),
		"phase_source": "StormwoodSurge.phase and phase_at_position(player_position)",
		"phase": actual_phase,
		"phase_at_player": phase_at_player,
		"weather_source": "StormwoodSurge.weather()",
		"weather": actual_weather,
		"phase_info_at_player": _surge.call("phase_info_at", _player.global_position),
		"stormwood_lightning_sheltered": sheltered,
		"surge_cached_sheltered": surge_sheltered,
		"surge_roofed": roofed,
		"rain_amount": float(_surge.get("_rain_amount")),
		"near_rain_amount_ratio": rain_ratio,
		"production_camera_current": _camera == root.get_camera_3d(),
		"shelter_case": "inside" if frame_id.begins_with("ashfoot_shelter_inside_") else "outside" if frame_id.begins_with("ashfoot_shelter_outside_") else "world_view",
	}


func _done() -> void:
	if _frames.size() != EXPECTED_VIEWS * EXPECTED_PHASES.size():
		_failures.append("F41 recapture has %d frames; expected %d matched views" % [_frames.size(), EXPECTED_VIEWS * EXPECTED_PHASES.size()])
	for phase: String in EXPECTED_PHASES:
		var count := 0
		for frame: Dictionary in _frames:
			if str(frame.get("surge_phase", "")) == phase and frame.has("stormwood_support_receipt"):
				count += 1
		if count != EXPECTED_VIEWS:
			_failures.append("F41 phase %s has %d receipt-backed frames; expected %d" % [phase, count, EXPECTED_VIEWS])
	super._done()
