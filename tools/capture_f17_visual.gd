extends "res://tests/smoke_crossing_hall_circuit.gd"

## Native F17 views on the existing physical Hall circuit. The inherited
## post-opening fixture and initial placement are disclosed; all later travel
## and camera turns use the real controller bindings. No image resizing.
const GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")
var _output := ""
var _preset := ""
var _source := ""
var _views: Array[Dictionary] = []
var _output_created_here := false
var _paired_high := false
var _captured_companion: Node3D
var _captured_member: RefCounted
var _companion_required := false
var _farm_diagnostic_only := false
var _hall_stills_only := false
var _hall_stills_finished := false
var _relic_hang_witness := false
var _relic_biome := "meadows"
## Process-only evidence position option; no gameplay/save/authority writes.
var _relic_doorway_view := false
var _relic_doorway_boundary := Vector3.ZERO
var _relic_view_hall: Node3D
var _relic_hung := false
var _relic_witness: Dictionary = {}
const HALL_STILL_LABELS: Array[String] = ["inside Hall nave", "pedestal meadows", "companion in Shrine Room"]
var _expected_resolution := Vector2i(1920, 1080)


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			_output = argument.trim_prefix("--output=")
		elif argument.begins_with("--preset="):
			_preset = argument.trim_prefix("--preset=")
		elif argument.begins_with("--source-commit="):
			_source = argument.trim_prefix("--source-commit=")
		elif argument == "--paired-high":
			_paired_high = true
		elif argument == "--farm-diagnostic-only":
			_farm_diagnostic_only = true
		elif argument == "--hall-stills-only":
			_hall_stills_only = true
		elif argument == "--hall-relic-hang-witness":
			_relic_hang_witness = true
		elif argument.begins_with("--hall-relic-biome="):
			_relic_biome = argument.trim_prefix("--hall-relic-biome=")
		elif argument == "--hall-relic-doorway-view":
			_relic_doorway_view = true
		elif argument.begins_with("--expected-resolution="):
			var dimensions := argument.trim_prefix("--expected-resolution=").split("x")
			_expected_resolution = Vector2i(int(dimensions[0]), int(dimensions[1])) if dimensions.size() == 2 else Vector2i.ZERO
	var pattern := RegEx.new()
	pattern.compile("^[0-9a-f]{40}$")
	var renderer := "gl_compatibility" if _preset == "Low" else "forward_plus"
	# The inherited run waits for startup only after this preflight. Observe
	# the initialized native window before checking its CLI-requested raster.
	await process_frame
	if DisplayServer.get_name() == "headless" or not GRAPHICS.PRESETS.has(_preset) \
			or relic_witness_spec(_relic_biome).is_empty() or (_relic_biome != "meadows" and not _relic_hang_witness) \
			or (_relic_doorway_view and (not _relic_hang_witness or not _hall_stills_only)) \
			or (_farm_diagnostic_only and _hall_stills_only) \
			or (_paired_high and _preset != "Medium") \
			or (_expected_resolution != Vector2i(1920, 1080) and not (_preset == "Low" and _expected_resolution == Vector2i(1280, 720))) \
			or RenderingServer.get_current_rendering_method() != renderer \
			or DisplayServer.window_get_size() != _expected_resolution \
			or root.size != _expected_resolution \
			or pattern.search(_source) == null or not _output.is_absolute_path() \
			or DirAccess.dir_exists_absolute(_output):
		var facts := {"display": DisplayServer.get_name(), "preset": _preset,
			"relic_biome": _relic_biome,
			"paired_high": _paired_high, "renderer": RenderingServer.get_current_rendering_method(),
			"required_renderer": renderer, "expected_resolution": [_expected_resolution.x, _expected_resolution.y],
			"window_resolution": [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
			"root_resolution": [root.size.x, root.size.y], "source_valid": pattern.search(_source) != null,
			"output_absolute": _output.is_absolute_path(), "output_exists": DirAccess.dir_exists_absolute(_output)}
		_finish_failure("require matching native raster (1080p or Low720), preset/renderer, exact source and fresh absolute output; observed=" + JSON.stringify(facts))
		return
	if DirAccess.make_dir_recursive_absolute(_output) != OK:
		_finish_failure("could not create fresh evidence directory")
		return
	_output_created_here = true
	if GRAPHICS.choose(_preset) != OK:
		_finish_failure("could not select preset")
		return
	if _relic_hang_witness and not _prepare_relic_fixture():
		_finish_failure(_failed)
		return
	await super._run()


func _capture(label: String) -> void:
	if _relic_hang_witness:
		if label not in _hung_relic_labels():
			_release_all()
			return
		if label == "pedestal " + _relic_biome and not _relic_hung:
			if not await _hang_fixture_relic():
				_finish_failure(_failed)
				return
		if label == _relic_view_label():
			if _relic_doorway_view and not _doorway_nave_position_valid():
				_finish_failure("doorway witness must remain at its ordinary target on the actual nave side of the partition")
				return
			var target := root.get_node_or_null(str(_relic_witness.get("pedestal", ""))) as Node3D
			if target == null:
				_finish_failure("hung relic's actual pedestal disappeared before doorway view")
				return
			await _look_stick_to(_yaw_toward(_xz(), Vector2(target.global_position.x, target.global_position.z)))
	if _hall_stills_only and label not in HALL_STILL_LABELS:
		if not (_relic_hang_witness and label in _hung_relic_labels()):
			_release_all()
			return
	await _capture_matrix(label)
	if not _failed.is_empty():
		# Preserve the first capture failure before the inherited walk can
		# continue and replace it with a later travel failure.
		_finish_failure(_failed)
		return
	if _farm_diagnostic_only and label == "actual farmhouse doorway":
		_write_manifest(false)
		print("F17 partial farm-door light diagnostic; complete=false; no Hall circuit, motion or acceptance claim")
		quit(0 if _failed.is_empty() else 1)


## Disclosed capture fixture: one held selected relic, not a completed boss or
## earned boundary. Only ordinary Use may produce hung state/receipt/display.
static func relic_witness_spec(biome: String) -> Dictionary:
	if biome == "meadows":
		return {"boss": "warden_aldis", "mount": "MeadowsRelicDisplay",
			"candidate": "--hall-relic-display-candidate", "baseline": "--hall-relic-display-baseline"}
	if biome == "cloudreach":
		return {"boss": "captain_veyra_storm_anchor", "mount": "CloudreachRelicDisplay",
			"candidate": "--hall-cloudreach-relic-candidate", "baseline": "--hall-cloudreach-relic-baseline"}
	if biome == "stormwood":
		return {"boss": "captain_marrow_dynamo_core", "mount": "StormwoodRelicDisplay",
			"candidate": "--hall-stormwood-relic-candidate", "baseline": "--hall-stormwood-relic-baseline"}
	return {}


func _hung_relic_labels() -> Array[String]:
	var labels: Array[String] = []
	labels.append("pedestal " + _relic_biome)
	labels.append(_relic_view_label())
	return labels


func _relic_view_label() -> String:
	return "hung relic from shrine doorway" if _relic_doorway_view else "hung relic from nave"


static func relic_doorway_stand(door: Vector3) -> Vector3:
	# The existing controller arrival tolerance is .6m. Approach from the
	# gallery toward a target .9m into the nave, preserving that tolerance.
	return door - Vector3(.9, 0, 0)


func _doorway_nave_position_valid() -> bool:
	if not is_instance_valid(_relic_view_hall):
		return false
	var actual := _relic_view_hall.to_local(_player.global_position)
	var target := relic_doorway_stand(_relic_doorway_boundary)
	return is_finite(actual.x) and actual.x < _relic_doorway_boundary.x \
		and Vector2(actual.x, actual.z).distance_to(Vector2(target.x, target.z)) <= .75


func _prepare_relic_fixture() -> bool:
	var args := OS.get_cmdline_user_args()
	var game := root.get_node_or_null(^"Game")
	var session: Node = game.get("session") if game != null else null
	var spec := relic_witness_spec(_relic_biome)
	if spec.is_empty() or not _hall_stills_only or _farm_diagnostic_only or not args.has(spec.get("candidate", "")) \
			or args.has(spec.get("baseline", "")) or session == null \
			or session.call("is_active") == true or session.call("is_host") != true \
			or session.call("portal_runtime_ready") != true:
		_failed = "hung witness requires explicit mounted candidate ON, bounded Hall mode and unchanged solo host portal runtime"
		return false
	var personal: Dictionary = (game.get("local").get("redesign_character") as Dictionary).duplicate(true)
	var display: Dictionary = game.get("world").get("redesign_world")
	var grant := preload("res://scripts/net/encounter_rewards.gd").chapter_hand_off(str(spec.boss), _relic_biome)
	if grant.get("relic_biome") != _relic_biome or not (personal.get("relics_held", []) as Array).is_empty() \
			or not (personal.get("relics_hung", []) as Array).is_empty() \
			or not (display.get("shrine_display", {}) as Dictionary).is_empty():
		_failed = "held-relic fixture requires fresh empty personal/world shrine state and authored " + _relic_biome + " hand-off"
		return false
	var save_dir := _output.path_join("held-relic-fixture-save")
	if DirAccess.dir_exists_absolute(save_dir):
		_failed = "held-relic fixture save directory already exists"
		return false
	game.set("save_system", preload("res://scripts/save/save_game.gd").new(save_dir))
	(personal.relics_held as Array).append(_relic_biome)
	game.get("local").set("redesign_character", personal)
	_relic_witness = {"fixture": "one personal held %s relic from authored %s hand-off; no boss win/key/hung flag/world display/receipt grant" % [_relic_biome, spec.boss],
		"biome": _relic_biome, "save_dir": save_dir, "candidate_arg": spec.candidate, "hung": false}
	return true


func _hang_fixture_relic() -> bool:
	_release_all()
	var session: Node = _game.get("session")
	var local: RefCounted = _game.get("local")
	var world: RefCounted = _game.get("world")
	var character := str(local.get("character_id"))
	var receipt := "relic_hang:" + _relic_biome + ":" + character
	var held: Array = local.get("redesign_character").get("relics_held", [])
	var pedestals := get_nodes_in_group("crossing_hall_pedestals")
	var pedestal: Node3D
	for node: Node3D in pedestals:
		if node.get_meta("biome", "") == _relic_biome:
			if pedestal != null:
				_failed = "hung witness found duplicate " + _relic_biome + " pedestal"
				return false
			pedestal = node
	var mount := pedestal.get_node_or_null(str(relic_witness_spec(_relic_biome).mount)) as Node3D if pedestal != null else null
	if character.is_empty() or session.call("is_host") != true or not _player.is_on_floor() \
			or held.count(_relic_biome) != 1 or mount == null or mount.visible \
			or not (world.get("redesign_world").get("shrine_display", {}) as Dictionary).is_empty() \
			or local.get("redesign_character").get("transaction_receipts", []).has(receipt) \
			or not bool(_game.call("save_game", 0)):
		_failed = "hung witness requires hidden mounted candidate, grounded real body, held relic and fresh production fixture save"
		return false
	var world_namespace := str(world.get("reward_delivery_namespace"))
	var party := _relic_party_uids()
	var director := _world.get_node_or_null("EncounterDirector")
	if director == null:
		_failed = "hung witness lacks ordinary companion director"
		return false
	if director.call("ally_body") == null:
		await _press("creature_recall")
	for frame in 180:
		if _companion_ready(director): break
		await physics_frame
	if not _companion_ready(director):
		_failed = "hung witness did not retain the healthy actually owned companion"
		return false
	_captured_companion = director.call("ally_body") as Node3D
	_captured_member = director.call("ally_instance") as RefCounted
	_companion_required = true
	var travel := preload("res://tests/helpers/f49_portal_travel.gd").new(self, _game)
	if not await travel.hang_relic(_relic_biome):
		_failed = "ordinary real pedestal hang refused: " + str(travel.failures)
		return false
	# The production success opens the power modal. Cancel with parsed pad
	# edges on process frames so the panel's own pause/input release executes.
	_pad_press("menu_cancel", 1.0)
	Input.flush_buffered_events()
	for frame in 3: await process_frame
	_pad_release("menu_cancel")
	Input.flush_buffered_events()
	for frame in 30: await process_frame
	var saver: RefCounted = _game.get("save_system")
	var disk_world: Dictionary = saver.call("worlds").call("read", str(world.get("world_id")))
	var disk_character: Dictionary = saver.call("characters").call("read", character)
	var personal: Dictionary = local.get("redesign_character")
	var disk_personal: Dictionary = disk_character.get("redesign_character", {})
	if INPUT_OWNER.current(self) != null or not _player.is_on_floor() \
			or str(local.get("character_id")) != character or str(world.get("reward_delivery_namespace")) != world_namespace \
			or _relic_party_uids() != party or not _companion_ready(director) \
			or (personal.relics_held as Array).has(_relic_biome) or (personal.relics_hung as Array).count(_relic_biome) != 1 \
			or (personal.transaction_receipts as Array).count(receipt) != 1 \
			or world.get("redesign_world").get("shrine_display", {}).get(_relic_biome) != true \
			or disk_world.get("redesign_world", {}).get("shrine_display", {}).get(_relic_biome) != true \
			or disk_character.get("character_id") != character \
			or (disk_personal.get("relics_held", []) as Array).has(_relic_biome) \
			or (disk_personal.get("relics_hung", []) as Array).count(_relic_biome) != 1 \
			or (disk_personal.get("transaction_receipts", []) as Array).count(receipt) != 1 \
			or not mount.is_visible_in_tree() or not bool(pedestal.get_meta("relic_displayed", false)):
		_failed = "ordinary hang did not retain owner/world/party, release input and mount exactly one saved relic"
		return false
	_relic_witness.merge({"hung": true, "character_id": character, "world_namespace": world_namespace,
		"receipt": receipt, "party_uids": party, "disk_world_display": disk_world.get("redesign_world", {}).get("shrine_display", {}),
		"disk_held": disk_personal.get("relics_held", []), "disk_hung": disk_personal.get("relics_hung", []),
		"disk_receipt_count": (disk_personal.get("transaction_receipts", []) as Array).count(receipt),
		"world_file": saver.call("worlds").call("path_for", str(world.get("world_id"))),
		"character_file": saver.call("characters").call("path_for", character),
		"pedestal": str(pedestal.get_path()), "mount": str(mount.get_path()), "mount_visible": mount.is_visible_in_tree()}, true)
	_relic_hung = true
	return true


func _relic_party_uids() -> Array[String]:
	var ids: Array[String] = []
	for member: RefCounted in _game.get("party").call("members"):
		ids.append(str(member.get("uid")))
	return ids


func _capture_matrix(label: String) -> void:
	_release_all()
	var look := _world.get_node_or_null("WorldLook")
	var weather := _world.get_node_or_null("WorldWeather")
	if look == null or weather == null:
		_failed = "production light/weather nodes are missing"
		return
	look.call("set_clock_frozen", true)
	weather.call("set_weather", "clear")
	var camera := _rig.get_node_or_null("Camera3D") as Camera3D
	if camera == null or not camera.current:
		_failed = "ordinary production camera is not current"
		return
	for frame in 20:
		await process_frame
	var body_at := _player.global_position
	var yaw := float(_rig.get("yaw"))
	var camera_at := camera.global_transform
	var camera_reference_ready := false
	var weather_processing := weather.is_processing()
	weather.set_process(false)
	for weather_name: String in ["clear", "rain"]:
		weather.call("set_weather", weather_name)
		for frame in 120:
			await process_frame
		for time_name: String in ["day", "night"]:
			look.call("apply_time", time_name)
			for preset: String in _capture_presets():
				if GRAPHICS.choose(preset) != OK:
					_failed = "could not apply capture preset " + preset
					weather.set_process(weather_processing)
					return
				look.call("refresh_graphics")
				for frame in 12:
					await process_frame
				var body_delta := _player.global_position.distance_to(body_at)
				var yaw_delta := absf(angle_difference(float(_rig.get("yaw")), yaw))
				var camera_delta := camera.global_position.distance_to(camera_at.origin)
				var camera_angle := camera.global_basis.get_rotation_quaternion().angle_to(camera_at.basis.get_rotation_quaternion())
				if body_delta > .005 or yaw_delta > .001 \
						or (camera_reference_ready and (camera_delta > .005 or camera_angle > .001)):
					_failed = "ordinary body/camera pose changed between paired time/weather/preset views; observed=" + JSON.stringify({
						"label": label, "time": time_name, "weather": weather_name, "preset": preset,
						"body_delta_m": body_delta, "yaw_delta_rad": yaw_delta,
						"camera_delta_m": camera_delta, "camera_angle_rad": camera_angle,
						"camera_reference_ready": camera_reference_ready})
					weather.set_process(weather_processing)
					return
				if not camera_reference_ready:
					# Normal idle follow/recovery uses the existing first weather and
					# preset settle window before the first view. Never rebase a pair.
					camera_at = camera.global_transform
					camera_reference_ready = true
				if not await _save_view(label, time_name, weather_name):
					weather.set_process(weather_processing)
					return
				if label == "actual farmhouse doorway" and time_name == "night":
					if not await _capture_house_light_off(label, time_name, weather_name):
						weather.set_process(weather_processing)
						return
	if GRAPHICS.choose(_preset) != OK:
		_failed = "could not restore travel preset " + _preset
	weather.call("set_weather", "clear")
	weather.set_process(weather_processing)
	look.call("apply_time", "day")
	look.call("refresh_graphics")


func _save_view(label: String, time_name: String, weather_name: String = "clear", motion: bool = false, diagnostic: String = "") -> bool:
	await RenderingServer.frame_post_draw
	var captured_ms := Time.get_ticks_msec()
	if _relic_doorway_view and label == _relic_view_label() and not _doorway_nave_position_valid():
		_failed = "actual doorway/nave position changed before native capture"
		return false
	if _relic_hang_witness:
		var mount := root.get_node_or_null(str(_relic_witness.get("mount", ""))) as Node3D
		if not _relic_hung or mount == null or not mount.is_visible_in_tree() \
				or str(_game.get("local").get("character_id")) != _relic_witness.get("character_id") \
				or str(_game.get("world").get("reward_delivery_namespace")) != _relic_witness.get("world_namespace") \
				or _relic_party_uids() != _relic_witness.get("party_uids"):
			_failed = "actual owned hung relic display changed before native capture"
			return false
	if _companion_required and not _companion_ready(_world.get_node_or_null("EncounterDirector")):
		_failed = "the same healthy visible companion was not retained through its still/motion capture"
		return false
	if str(_world.get_node("WorldWeather").call("weather")) != weather_name:
		_failed = "observed weather differs from capture label " + weather_name
		return false
	var pixels := root.get_viewport().get_texture().get_image()
	if pixels == null or pixels.is_empty() or pixels.get_size() != _expected_resolution:
		_failed = "native original image is missing or wrong resolution"
		return false
	var extension := "jpg" if motion else "png"
	var filename := "%04d-%s-%s-%s-%s.%s" % [_views.size(), label.validate_filename().replace(" ", "-"), time_name, weather_name, GRAPHICS.selected().to_lower(), extension]
	var saved := pixels.save_jpg(_output.path_join(filename), .95) if motion else pixels.save_png(_output.path_join(filename))
	if saved != OK:
		_failed = "could not save native original image"
		return false
	var camera := _rig.get_node("Camera3D") as Camera3D
	var director := _world.get_node_or_null("EncounterDirector")
	var ally := director.call("ally_body") as Node3D if director != null else null
	_views.append({"label": label, "time": time_name, "weather": weather_name, "image": filename,
		"body": _coordinates(_player.global_position), "camera": _coordinates(camera.global_position),
		"camera_basis": [_coordinates(camera.global_basis.x), _coordinates(camera.global_basis.y), _coordinates(camera.global_basis.z)],
		"on_floor": _player.is_on_floor(), "preset": GRAPHICS.selected(), "motion_sample": motion,
		"encoding": "native-resolution JPEG95" if motion else "native-resolution PNG",
		"features": GRAPHICS.values(), "elapsed_ms": captured_ms, "diagnostic": diagnostic,
		"equipped_tool": str(_game.get("equipped_tool")), "nearby_lights": _nearby_lights(),
		"companion": {"path": str(ally.get_path()), "body": _coordinates(ally.global_position)} if is_instance_valid(ally) else {}})
	# Best-effort partial metadata; an external kill during a rewrite may still
	# interrupt it. Only the completed circuit can set complete=true.
	_write_manifest(false)
	return _failed.is_empty()


func _nearby_lights() -> Array[Dictionary]:
	var lights: Array[Dictionary] = []
	var capsule := (_player.get_node("Collision") as CollisionShape3D).shape as CapsuleShape3D
	for light: OmniLight3D in _world.find_children("*", "OmniLight3D", true, false):
		# Conservative intersection candidates include lights above the foot
		# origin that can reach the actual capsule's shoulders.
		if light.global_position.distance_to(_player.global_position) <= light.omni_range + capsule.height:
			lights.append({"path": str(light.get_path()), "position": _coordinates(light.global_position),
				"visible": light.is_visible_in_tree(), "energy": light.light_energy,
				"range": light.omni_range, "attenuation": light.omni_attenuation,
				"colour": [light.light_color.r, light.light_color.g, light.light_color.b],
				"shadows": light.shadow_enabled})
	return lights


func _capture_house_light_off(label: String, time_name: String, weather_name: String) -> bool:
	var house := _world.get_node_or_null("GrandpaHouse")
	if house == null:
		_failed = "actual farmhouse missing from light-spill diagnostic"
		return false
	var lights := house.find_children("*", "OmniLight3D", true, false)
	if lights.is_empty():
		_failed = "actual farmhouse lights missing from light-spill diagnostic"
		return false
	var energies: Array[float] = []
	var body_at := _player.global_position
	var camera := _rig.get_node("Camera3D") as Camera3D
	var camera_at := camera.global_transform
	for light: OmniLight3D in lights:
		energies.append(light.light_energy)
		light.light_energy = 0.0
	for frame in 12:
		await process_frame
	var saved := false
	if _player.global_position.distance_to(body_at) > .005 \
			or camera.global_position.distance_to(camera_at.origin) > .005 \
			or camera.global_basis.get_rotation_quaternion().angle_to(camera_at.basis.get_rotation_quaternion()) > .001:
		_failed = "body/camera changed during paired farmhouse-light-off diagnostic"
	else:
		saved = await _save_view(label + " diagnostic house lights off", time_name, weather_name, false, "farmhouse-light-off; diagnosis only, excluded from acceptance")
	for index in lights.size():
		(lights[index] as OmniLight3D).light_energy = energies[index]
	for frame in 12:
		await process_frame
	return saved


func _companion_ready(director: Node) -> bool:
	if director == null:
		return false
	var ally := director.call("ally_body") as Node3D
	var member := director.call("ally_instance") as RefCounted
	if not is_instance_valid(ally) or not ally.is_visible_in_tree() \
			or not is_instance_valid(member) or member != (_game.get("party") as RefCounted).call("active") \
			or float(member.get("hp")) <= 0.0 or bool(member.get("fainted")):
		return false
	return (_captured_companion == null or ally == _captured_companion) \
		and (_captured_member == null or member == _captured_member)


func _after_hall_arrival(hall: Node3D) -> bool:
	# The ordinary reverse view shows the inhabited road from its destination.
	var original_yaw := float(_rig.get("yaw"))
	await _look_stick_to(original_yaw + PI)
	if absf(angle_difference(float(_rig.get("yaw")), original_yaw + PI)) > deg_to_rad(3.0):
		_failed = "ordinary look-stick did not reach reverse view"
		_write_manifest(false)
		return false
	await _capture("village reverse from nave")
	await _look_stick_to(original_yaw)
	if absf(angle_difference(float(_rig.get("yaw")), original_yaw)) > deg_to_rad(3.0):
		_failed = "ordinary look-stick did not restore forward view"
		_write_manifest(false)
		return false
	if not await super._after_hall_arrival(hall):
		_write_manifest(false)
		return false
	var director := _world.get_node_or_null("EncounterDirector")
	if director == null:
		_failed = "production companion director is missing"
		_write_manifest(false)
		return false
	if director.call("ally_body") == null:
		await _press("creature_recall")
	for frame in 180:
		if _companion_ready(director):
			break
		await physics_frame
	if not _companion_ready(director):
		_failed = "physical recall did not retain the healthy active creature's visible body"
		_write_manifest(false)
		return false
	_captured_companion = director.call("ally_body") as Node3D
	_captured_member = director.call("ally_instance") as RefCounted
	_companion_required = true
	await _capture("companion in Shrine Room")
	if not _failed.is_empty():
		_write_manifest(false)
		return false
	if _relic_hang_witness:
		var stands: Dictionary = {}
		for pedestal: Node3D in get_nodes_in_group("crossing_hall_pedestals"):
			stands[str(pedestal.get_meta("biome", ""))] = pedestal
		var route := _gallery_route(hall, stands)
		_relic_view_hall = hall
		_relic_doorway_boundary = route.get("door", Vector3.ZERO)
		var view_at := relic_doorway_stand(_relic_doorway_boundary) if _relic_doorway_view else Vector3.ZERO
		var view_via: Vector3 = route.get("door", Vector3.ZERO) if _relic_doorway_view else Vector3.ZERO
		if not _relic_hung or route.is_empty() \
				or not await _walk_to_target(hall, hall.to_global(route.door), route.aisle, "hung relic return through shrine doorway") \
				or not await _walk_to_target(hall, hall.to_global(view_at), view_via, _relic_view_label()):
			_write_manifest(false)
			return false
	if _hall_stills_only:
		var labels: Array[String] = _hung_relic_labels() if _relic_hang_witness else HALL_STILL_LABELS
		for expected_label: String in labels:
			var count := 0
			for view: Dictionary in _views:
				if str(view.label) == expected_label:
					count += 1
			if count != 4 * _capture_presets().size():
				_failed = "bounded Hall still matrix incomplete: " + expected_label
				_write_manifest(false)
				return false
		_hall_stills_finished = true
		_write_manifest(false)
		print("F17 bounded Hall stills: physical8+8 and recall retained; selected%dlabels complete; no full visual matrix/motion claim" % labels.size())
		return _failed.is_empty()
	# Observe thirty wall-clock seconds of the live interior without disabling
	# rendering or advancing the clock. Original frames retain HUD and actors.
	var weather := _world.get_node("WorldWeather")
	weather.call("set_weather", "clear")
	weather.set_process(false)
	for preset: String in _capture_presets():
		if GRAPHICS.choose(preset) != OK:
			_failed = "could not apply motion preset " + preset
			_write_manifest(false)
			return false
		_world.get_node("WorldLook").call("refresh_graphics")
		for frame in 12:
			await process_frame
		if not await _save_view("live interior motion", "day", "clear", true):
			_write_manifest(false)
			return false
		var began := int(_views[-1]["elapsed_ms"])
		var next_sample := Time.get_ticks_msec() + 100
		while Time.get_ticks_msec() - began < 30000:
			await process_frame
			if Time.get_ticks_msec() >= next_sample:
				if not await _save_view("live interior motion", "day", "clear", true):
					_write_manifest(false)
					return false
				# Record actual timestamps; slow rendering is retained, never
				# presented as smooth fixed-rate motion by the video packager.
				next_sample = Time.get_ticks_msec() + 100
		if not await _save_view("live interior motion", "day", "clear", true):
			_write_manifest(false)
			return false
	_write_manifest(_failed.is_empty())
	return _failed.is_empty()


func _write_manifest(complete: bool) -> void:
	var file := FileAccess.open(_output.path_join("manifest.json"), FileAccess.WRITE)
	if file == null:
		_failed = "could not save visual manifest"
		return
	file.store_string(JSON.stringify({"source": _source, "complete": complete and not _farm_diagnostic_only and not _hall_stills_only,
		"presets": _capture_presets(), "renderer": RenderingServer.get_current_rendering_method(),
		"resolution": [_expected_resolution.x, _expected_resolution.y], "views": _views, "failure": _failed,
		"shortcuts": ["inherited post-opening flags and starter", "one inherited initial farmhouse placement", "injected physical joypad bindings including ordinary companion recall", "production frozen day/night and selected clear/rain weather; weather scheduler held only for stationary capture", "separately marked farmhouse-light-off diagnostic restores all original light energies; excluded from acceptance"],
		"diagnostic_only": _farm_diagnostic_only,
		"hall_stills_only": _hall_stills_only, "hall_stills_finished": _hall_stills_finished,
		"relic_hang_witness": _relic_hang_witness, "relic_hang": _relic_witness,
		"relic_doorway_view": _relic_doorway_view,
		"scope": "disclosed held-relic fixture, ordinary host hang and saved receipt, mounted candidate ON at pedestal and nave with same healthy companion/production camera; no earned boundary, boss, co-op, device, full matrix or whole criterion claim" if _relic_hang_witness else "partial farm-door light diagnostic only; no Hall circuit, motion or acceptance claim" if _farm_diagnostic_only else "bounded3existing Hall still labels with physical8+8/recall; no full visual matrix/motion/wholecriterion claim" if _hall_stills_only else "physical village/Hall circuit and native views; independent visual verdict required; no earned opening, device, fight or multiplayer proof"}, "\t") + "\n")
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		_failed = "could not finish writing visual manifest"


func _coordinates(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _capture_presets() -> Array[String]:
	return capture_presets(_preset, _paired_high)


static func capture_presets(preset: String, paired_high: bool) -> Array[String]:
	# A conditional expression produces an untyped Array even when each arm
	# contains strings. Godot rejects assigning that Variant to Array[String]
	# at runtime; check-only cannot establish this branch's execution.
	var presets: Array[String] = []
	if paired_high:
		presets.append("Medium")
		presets.append("High")
	else:
		presets.append(preset)
	return presets


func _release_all() -> void:
	super._release_all()
	Input.flush_buffered_events()


func _look_stick_to(wanted: float) -> void:
	for frame in 240:
		var error := rad_to_deg(angle_difference(float(_rig.get("yaw")), wanted))
		_pad_release("look_left")
		_pad_release("look_right")
		Input.flush_buffered_events()
		if absf(error) < 3.0:
			break
		_pad_press("look_left" if error > 0.0 else "look_right", clampf(absf(error) / STEER_FULL_DEG, .35, 1.0))
		Input.flush_buffered_events()
		await physics_frame
	_pad_release("look_left")
	_pad_release("look_right")
	Input.flush_buffered_events()
	await process_frame


func _finish_failure(reason: String) -> void:
	if _output_created_here:
		_failed = reason
		_write_manifest(false)
	super._finish_failure(reason)
