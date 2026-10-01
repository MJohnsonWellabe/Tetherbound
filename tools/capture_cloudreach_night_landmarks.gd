extends "res://tools/capture_visual_audit.gd"
## DRY RUN — does not count. Production camera, disclosed progression/clock/stands.

func _run_region() -> bool:
	await process_frame
	root.size = Vector2i(1920, 1080)
	await process_frame
	if root.size != Vector2i(1920, 1080):
		_skip("viewport", "requires native 1920x1080")
		return false
	return await super._run_region()

func _region_spec(region: String) -> Dictionary:
	var spec := super._region_spec(region)
	(spec.get("flags", []) as Array).erase("fly_tutorial_completed")
	return spec

func _build_rows(spec: Dictionary) -> Array:
	var rows: Array = []
	for row: Dictionary in super._build_rows(spec):
		if str(row.id) in ["place_three_bells_bridge", "place_windscar_beacon",
				"place_sky_shrine_heartstone", "place_cliffhold_settlement",
				"place_summit_eyrie_stronghold"]:
			row["times"] = ["day", "night"]
			rows.append(row)
	for view: Dictionary in [
		{"id":"place_aviary_entrance", "at":Vector3(100,1160,5296), "target":Vector3(100,1175,5350), "pitch":5.0},
		{"id":"place_aviary_interior", "at":Vector3(100,1160,5330), "target":Vector3(100,1170,5364), "pitch":14.0},
		{"id":"place_shrine_crown", "at":Vector3(1110,1050,2912), "target":Vector3(1110,1058.5,2940), "pitch":10.0},
	]:
		rows.append({"id":view.id,"label":view.id,"stands":[view.at],"target":view.target,
			"pitch_deg":view.pitch,"times":["day","night"],
			"why":"Disclosed landmark diagnostic stand/pitch, production camera, companion parked behind camera"})
	return rows

func _capture_region_row(spec: Dictionary, row: Dictionary, time: String) -> void:
	await super._capture_region_row(spec, row, time)
	var lamps := _world.find_children("ArchitecturalLight", "OmniLight3D", true, false)
	if lamps.is_empty(): return # baseline intentionally has no new fixtures
	var energies: Array = []
	for light: OmniLight3D in lamps:
		energies.append(light.light_energy)
		if (time == "day" and not is_zero_approx(light.light_energy)) or (time == "night" and light.light_energy <= 0.0):
			_skip(str(row.id), "fixture energy disagrees with captured clock")
	_log_line({"kind":"landmark_lights","subject":row.id,"time":time,"energies":energies})

func _finish(ok: bool) -> void:
	super._finish(ok and _skips.is_empty())
