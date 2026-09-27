extends "res://tools/capture_visual_audit.gd"

func _region_spec(region: String) -> Dictionary:
	var spec: Dictionary = super._region_spec(region)
	# Retired flag is not declared in current production scope.
	(spec.get("flags", []) as Array).erase("fly_tutorial_completed")
	return spec

# Local evidence adapter: unchanged production audit boot/camera/clock/fixtures.
# Adds material/entrance and interior stands to the existing overview.
func _build_rows(spec: Dictionary) -> Array:
	var rows: Array = []
	for row: Dictionary in super._build_rows(spec):
		if str(row.id) in ["env_summit_final_stronghold_0", "env_gate_lower_cliffs_0", "env_high_roost_sky_shrine_0"]:
			if str(row.id) != "env_summit_final_stronghold_0":
				row["times"] = ["day", "night"]
			rows.append(row)
	for view: Dictionary in [
		{"id":"place_aviary_entrance", "at":Vector3(100,1160,5296), "target":Vector3(100,1175,5350), "pitch":5.0},
		{"id":"place_aviary_interior", "at":Vector3(100,1160,5330), "target":Vector3(100,1170,5364), "pitch":14.0},
		{"id":"place_aviary_reverse", "at":Vector3(100,1160,5402), "target":Vector3(100,1175,5350), "pitch":5.0},
	]:
		rows.append({"id":view.id, "label":view.id, "stands":[view.at], "target":view.target,
			"pitch_deg":view.pitch, "times":["day","night"],
			"why":"Authored diagnostic stand at summit crown; real production rig at disclosed reachable pitch; companion parked behind camera by base place fixture"})
	return rows
