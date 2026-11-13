extends "res://tests/test_case.gd"

## Bug fix pin (12 Nov): the Stormward Overlook streamers were flat 2 m by
## 4.5 m cards at head height (a blank pale pane over half the route frame) and
## the beacon glows were default 1 m white spheres.

const OVERLOOK := preload("res://scripts/world/cloudreach_stormward_overlook.gd")
const CONFIG := "res://data/config/cloudreach_stormward_overlook_visual.json"


func test_pane_fix_is_on_with_its_reason() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var fix: Dictionary = cfg.get("pane_fix_1112", {})
	assert_true(bool(fix.get("enabled", false)))
	assert_true(str(fix.get("_why_on", "")).contains("walk_02_day"))


func test_streamers_are_narrow_pennants_and_glows_are_small() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var presentation: Node3D = OVERLOOK.new()
	presentation.build({})
	var streamers := 0
	var glows := 0
	for child: Node in presentation.get_children():
		var role := str(child.get_meta("stormward_role", ""))
		if role == "direction_streamer":
			var box: AABB = (child as MeshInstance3D).mesh.get_aabb()
			var spec: Dictionary = (cfg.banners as Array)[streamers]
			assert_true(box.size.x < 1.1, "streamer is a narrow pennant")
			# Hung from the same top edge as the old card.
			var old_top := float(spec.position[1]) + float(spec.size[1]) * 0.5
			var top := (child as Node3D).position.y + box.end.y
			assert_true(absf(top - old_top) < 0.01)
			streamers += 1
		elif role == "beacon_glow":
			var sphere := (child as MeshInstance3D).mesh as SphereMesh
			assert_true(sphere.radius <= 0.35, "glow is an ember, not a 1 m ball")
			var material := (child as MeshInstance3D).material_override as StandardMaterial3D
			assert_true(material.emission_energy_multiplier <= 1.5)
			glows += 1
	assert_eq(streamers, 2)
	assert_eq(glows, 2)
	presentation.free()
