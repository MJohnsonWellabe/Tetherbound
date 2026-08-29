extends SceneTree
## T1-CAST (§15 continuation). T1-CREATURE's handover left the creek_edge
## (paddlenewt) cluster's own scatter disc unverified: the fixed centre
## clears the water now, but the cluster still spreads 2 individuals across
## its own 14m radius, and an individual landing near the disc's outer edge
## could still land on lakebed deep enough to stay submerged.
##
## The scatter is NOT randomized per boot -- encounter_director.gd:284-285
## seeds a RandomNumberGenerator from `hash("wild_spawn_%d" % order)`, and
## the comment right above that line states the promise explicitly: "the
## same table must produce the same meadow every boot." So "re-render a few
## times" (the handover's own suggested next step) would show the identical
## two points every time; the deterministic fix is to reproduce
## encounter_director.gd's own placement math exactly (same seed, same
## angle/distance draw order) and check the real depth at both resulting
## points directly, which is exact rather than a render sample.
##
##   godot --headless --path . --script tools/_probe_creek_edge_scatter_depth.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

## Same defaults water.json's own water.level carries -- checked in the loop
## below directly against the live config rather than hardcoded twice.
const SPAWNS_PATH := "res://data/config/bands/band1_lower_meadows/spawns.json"
const WATER_PATH := "res://data/config/terrain_playground.json"

## Species body heights (species.json), matching T1-CREATURE's own table.
const BODY_HEIGHT := {
	"paddlenewt": 1.15,
	"mosshell": 1.40,
	"brooktail": 1.05,
}


func _init() -> void:
	var spawns_file := FileAccess.open(SPAWNS_PATH, FileAccess.READ)
	var spawns_data: Dictionary = JSON.parse_string(spawns_file.get_as_text())
	var water_file := FileAccess.open(WATER_PATH, FileAccess.READ)
	var water_data: Dictionary = JSON.parse_string(water_file.get_as_text())
	var water_level: float = float((water_data.get("water", {}) as Dictionary).get("level", -17.0))
	print("water.level = %.2f" % water_level)

	var field := HEIGHTFIELD.new(HEIGHTFIELD.load_config())

	for spawn: Dictionary in spawns_data.get("spawns", []):
		var species: String = spawn.get("species", "")
		if not BODY_HEIGHT.has(species):
			continue
		var order: int = int(spawn.get("order", -1))
		var centre_arr: Array = spawn.get("centre", [])
		var centre := Vector2(centre_arr[0], centre_arr[2])
		var radius: float = float(spawn.get("radius", 0.0))
		var count: int = int(spawn.get("count", 1))
		var body_h: float = BODY_HEIGHT[species]

		var rng := RandomNumberGenerator.new()
		rng.seed = hash("wild_spawn_%d" % order)
		print("\n%s (order %d, habitat %s), centre %s, radius %.1f, count %d" % [
			species, order, spawn.get("habitat", "?"), str(centre), radius, count])
		for n in count:
			var angle := rng.randf_range(0.0, TAU)
			var distance := radius * sqrt(rng.randf())
			var spot := centre + Vector2(sin(angle), cos(angle)) * distance
			var h: float = field.height_at(spot.x, spot.y)
			var depth: float = water_level - h
			var clears: bool = depth < body_h
			var frac_clear: float = clampf(1.0 - depth / body_h, 0.0, 1.0) if depth > 0.0 else 1.0
			print("  individual %d: dist %.1fm from centre, spot (%.1f,%.1f), terrain %.2f, depth %.2f, body %.2f -> %s (%.0f%% of body above water)" % [
				n + 1, distance, spot.x, spot.y, h, depth, body_h,
				"CLEARS" if clears else "SUBMERGED", frac_clear * 100.0])
	quit(0)
