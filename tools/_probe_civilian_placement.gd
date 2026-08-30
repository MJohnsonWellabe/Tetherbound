extends SceneTree

## T1-CREATURE-RIG / PRIORITY 2. Clearance probe for the 15 unplaced civilian
## NPC bodies (T3-INSTALL's "single largest remaining install opportunity").
##
##   godot --headless --path . --script tools/_probe_civilian_placement.gd
##
## Same method village_npcs.json's own `_comment_positions` describes: real
## terrain (playground_heightfield.gd, analytic, no bake needed) plus real
## building footprints (building_prefabs.json's own module extents, the exact
## formula village.gd::_ground_clear_radius uses) plus distance to every
## already-authored person in village_npcs.json/trainers.json. No eyeballing.
##
## Reports, per candidate: ground height (NaN = no ground), slope, path_factor
## (how "on the road" the spot reads), nearest building clearance margin, and
## nearest already-placed person's distance. A FAIL on any of those means the
## candidate needs to move before it goes in village_npcs.json/trainers.json.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

# name -> [x, z, yaw_deg, radius]  (radius = half-diagonal of the prefab's own
# module extent + 0.7m CLEAR_MARGIN, matching village.gd's own formula)
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

# Every already-authored body near the candidates below (village_npcs.json +
# band1 trainers.json), so a new NPC cannot land on top of one that exists.
const OCCUPIED := {
	"Mira": [18.99, -1.01],
	"Oskar": [22.0, -6.0],
	"Tam": [8.0, -16.0],
	"Quarry Foreman": [0.0, -6.0],
	"Sela": [16.0, -10.0],
	"Bram": [-5.89, -9.0],
	"Halda": [23.5, 11.5],
	"Bryn": [13.0, 9.0],
}

# name -> [x, z]. FINAL 15 positions (village_npcs.json/trainers.json values).
const CANDIDATES := {
	"innkeeper": [-8.0, -3.0],
	"inn_helper": [-9.0, -16.0],
	"trader": [9.0, 4.0],
	"craftsperson": [-3.0, 7.0],
	"creature_caretaker": [26.0, -3.0],
	"farmer": [8.0, -22.0],
	"local_historian": [6.0, -13.0],
	"young_trainer": [5.0, 15.0],
	"rival_trainer": [27.2, -29.6],
	"wandering_trainer": [-38.0, 40.0],
	"lost_traveler": [80.0, -33.0],
	"field_researcher": [-343.0, 501.0],
	"alpha_tracker": [-390.0, 524.0],
	"courier": [17.0, -17.0],
	"former_tether_member": [26.0, -19.0],
}


func _init() -> void:
	var config: Dictionary = HEIGHTFIELD.load_config()
	if config.is_empty():
		push_error("no terrain config")
		quit(1)
		return
	var field: RefCounted = HEIGHTFIELD.new(config)

	var all_ok := true
	for cand_name: String in CANDIDATES.keys():
		var pos: Array = CANDIDATES[cand_name]
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
		var all_positions := OCCUPIED.duplicate()
		for other_name: String in CANDIDATES.keys():
			if other_name != cand_name:
				all_positions[other_name] = CANDIDATES[other_name]
		for p_name: String in all_positions.keys():
			var p: Array = all_positions[p_name]
			var d: float = Vector2(x, z).distance_to(Vector2(p[0], p[1]))
			if d < nearest_person_dist:
				nearest_person_dist = d
				nearest_person = p_name
		if nearest_person_dist < 3.0:
			ok = false
			notes.append("TOO CLOSE to %s (%.2fm)" % [nearest_person, nearest_person_dist])

		print("%-22s (%.1f, %.1f)  ground=%.2f slope=%.1fdeg path_factor=%.2f  nearest_building=%s(margin %.2fm)  nearest_person=%s(%.2fm)  %s  %s" % [
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
