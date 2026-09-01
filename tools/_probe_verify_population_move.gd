extends SceneTree

## OWNER-0901-VILLAGE-POPULATION, 2026-09-01. Ground/slope/clearance re-check
## for the three villagers moved to thin the square's core cluster (Garrick,
## Old Perrin, Lark -- see their own `_why` entries in village_npcs.json).
##
##   godot --headless --path . --script tools/_probe_verify_population_move.gd
##
## Same method tools/_probe_civilian_placement.gd already established: real
## terrain (playground_heightfield.gd, analytic, no bake needed), the same
## building-clearance formula village.gd::_ground_clear_radius uses, and
## distance to every other already-placed villager (village_npcs.json,
## current on-disk values, read live rather than copied).

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const VILLAGE_NPCS_CONFIG := "res://data/config/village_npcs.json"

const BUILDINGS := {
	"well": [10.0, -10.0, 15.0, 3.53],
	"workshop": [2.0, 2.0, -125.0, 5.85],
	"wagon": [6.5, -1.5, -150.0, 0.70],
	"cottage_a": [18.0, -2.0, -135.0, 4.51],
	"cottage_b": [21.0, -14.0, -70.0, 3.74],
	"fence_run_1": [14.0, -20.0, 55.0, 2.70],
	"fence_run_2": [19.5, -25.5, 55.0, 2.70],
	"fence_run_3": [3.0, -18.0, 100.0, 2.70],
	"square_oak_a": [25.5, -9.5, 40.0, 0.70],
	"square_oak_b": [1.0, 10.5, 160.0, 0.70],
	"inn": [-1.5, -9.0, 90.0, 7.08],
	"mill": [-382.0, 514.0, 0.0, 5.46],
	"ranger_station": [-350.0, 507.0, 75.0, 4.51],
}

const CANDIDATES := ["Garrick", "Old Perrin", "Lark"]


func _init() -> void:
	var config: Dictionary = HEIGHTFIELD.load_config()
	if config.is_empty():
		push_error("no terrain config")
		quit(1)
		return
	var field: RefCounted = HEIGHTFIELD.new(config)

	var villagers := _load_villagers()
	if villagers.is_empty():
		push_error("no villagers loaded from %s" % VILLAGE_NPCS_CONFIG)
		quit(1)
		return

	var all_ok := true
	for cand_name: String in CANDIDATES:
		if not villagers.has(cand_name):
			push_error("%s not found in %s" % [cand_name, VILLAGE_NPCS_CONFIG])
			all_ok = false
			continue
		var pos: Array = villagers[cand_name]
		var x: float = pos[0]
		var z: float = pos[1]
		var ok := true
		var notes: Array[String] = []

		var ground: float = field.call("height_at", x, z)
		if is_nan(ground):
			ok = false
			notes.append("NO GROUND")
		var slope: float = field.call("slope_degrees_at", x, z, 1.0)
		if slope > 25.0:
			ok = false
			notes.append("SLOPE %.1fdeg" % slope)

		var pf: float = field.call("path_factor", x, z)

		var nearest_building := ""
		var nearest_building_margin := INF
		for b_name: String in BUILDINGS.keys():
			var b: Array = BUILDINGS[b_name]
			var d: float = Vector2(x, z).distance_to(Vector2(b[0], b[1]))
			var margin: float = d - b[3]
			if margin < nearest_building_margin:
				nearest_building_margin = margin
				nearest_building = b_name
		if nearest_building_margin < 0.5:
			ok = false
			notes.append("INSIDE/TOUCHING %s (margin %.2fm)" % [nearest_building, nearest_building_margin])

		var nearest_person := ""
		var nearest_person_dist := INF
		for p_name: String in villagers.keys():
			if p_name == cand_name:
				continue
			var p: Array = villagers[p_name]
			var d: float = Vector2(x, z).distance_to(Vector2(p[0], p[1]))
			if d < nearest_person_dist:
				nearest_person_dist = d
				nearest_person = p_name
		if nearest_person_dist < 3.0:
			ok = false
			notes.append("TOO CLOSE to %s (%.2fm)" % [nearest_person, nearest_person_dist])

		print("%-14s (%.1f, %.1f)  ground=%.2f slope=%.1fdeg path_factor=%.2f  nearest_building=%s(margin %.2fm)  nearest_person=%s(%.2fm)  %s  %s" % [
			cand_name, x, z, ground, slope, pf,
			nearest_building, nearest_building_margin,
			nearest_person, nearest_person_dist,
			"OK" if ok else "FAIL",
			", ".join(notes)
		])
		if not ok:
			all_ok = false

	print("\n=== %s ===" % ("ALL CLEAR" if all_ok else "SOME CANDIDATES NEED TO MOVE"))
	quit(0 if all_ok else 1)


func _load_villagers() -> Dictionary:
	var out: Dictionary = {}
	var file := FileAccess.open(VILLAGE_NPCS_CONFIG, FileAccess.READ)
	if file == null:
		return out
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return out
	var listed: Variant = (parsed as Dictionary).get("villagers", [])
	if listed is Array:
		for entry: Variant in (listed as Array):
			if entry is Dictionary and (entry as Dictionary).has("position"):
				out[str((entry as Dictionary).get("name", ""))] = (entry as Dictionary)["position"]
	return out
