extends SceneTree

## One-off clearance probe for repositioning Lark clear of the practice
## meadow's bramblebun spawn cluster (data/config/bands/band1_lower_meadows/
## spawns.json order 0: centre [30,-40], radius 15.0, wander_radius 7.0 per
## data/config/combat.json's "wild" block) -- found colliding with S03's
## catch-ladder engage prompt (attempt 7, ralph/reports/gate-f-run-
## 20260902T053310Z-s03enginefix). Reuses tools/_probe_civilian_placement.gd's
## own method and clearance constants (terrain, buildings, occupied people)
## so a new position is checked the same way the existing ones were.
##
##   godot --headless --path . --script tools/_probe_lark_clearance.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

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
}

# Every currently-authored villager near this corridor (village_npcs.json,
# current positions on this branch), so a new Lark position cannot land on
# top of one of them either.
const PEOPLE := {
	"Garrick": [6.0, -34.0],
	"Old Perrin": [-15.0, -5.0],
	"Tobin": [80.0, -33.0],
	"Ren": [26.0, -19.0],
	"Tam": [8.0, -16.0],
	"Bryn": [13.0, 9.0],
}

# Practice meadow bramblebun cluster, data/config/bands/band1_lower_meadows/
# spawns.json order 0.
const CLUSTER_CENTRE := Vector2(30.0, -40.0)
const CLUSTER_RADIUS := 15.0
const WANDER_RADIUS := 7.0
const GREET_RADIUS := 3.8

# Candidates: further down the same Practice Meadow road Lark already
# stands beside (terrain_playground.json paths.routes [10,-10]->[18,-24]->
# [30,-40]->South Bridge), offset the same 5.5m perpendicular his own
# 2026-09-01 move already used, at increasing distance down the [30,-40]
# leg toward South Bridge.
const CANDIDATES := {
	"current": [19.6, -35.3],
	"cand_a": [24.0, -47.0],
	"cand_b": [28.0, -55.0],
	"cand_c": [32.0, -62.0],
}


func _init() -> void:
	var config: Dictionary = HEIGHTFIELD.load_config()
	if config.is_empty():
		push_error("no terrain config")
		quit(1)
		return
	var field: RefCounted = HEIGHTFIELD.new(config)

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

		var cluster_dist := Vector2(x, z).distance_to(CLUSTER_CENTRE)
		var cluster_margin := cluster_dist - CLUSTER_RADIUS - WANDER_RADIUS - GREET_RADIUS
		if cluster_margin < 0.0:
			ok = false
			notes.append("INSIDE bramblebun cluster worst-case reach (margin %.2fm)" % cluster_margin)

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
		for p_name: String in PEOPLE.keys():
			var p: Array = PEOPLE[p_name]
			var d: float = Vector2(x, z).distance_to(Vector2(p[0], p[1]))
			if d < nearest_person_dist:
				nearest_person_dist = d
				nearest_person = p_name
		if nearest_person_dist < 3.0:
			ok = false
			notes.append("TOO CLOSE to %s (%.2fm)" % [nearest_person, nearest_person_dist])

		print("%-10s (%.1f, %.1f)  ground=%.2f slope=%.1fdeg  cluster_dist=%.2fm margin=%.2fm  nearest_building=%s(%.2fm)  nearest_person=%s(%.2fm)  %s  %s" % [
			cand_name, x, z, ground, slope, cluster_dist, cluster_margin,
			nearest_building, nearest_building_margin,
			nearest_person, nearest_person_dist,
			"OK" if ok else "FAIL",
			", ".join(notes)
		])

	quit(0)
