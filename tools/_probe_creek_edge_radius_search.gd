extends SceneTree
## T1-CAST scratch: search candidate radii for orders 6/7/8 against the REAL
## encounter_director.gd scatter formula (same seed, same angle/distance draw
## order), without editing spawns.json yet -- so the actual seeded
## individual(s)' depth can be checked for each candidate before committing
## to one. Not a shipped tool; superseded by re-running
## tools/_probe_creek_edge_scatter_depth.gd against the real committed radius
## once chosen.
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const WATER_PATH := "res://data/config/terrain_playground.json"

const CASES := [
	{"order": 6, "species": "paddlenewt", "centre": Vector2(-378.0296, 528.0823), "count": 2, "body": 1.15, "candidates": [0.2, 0.3, 0.4, 0.5, 0.7, 1.0]},
	{"order": 7, "species": "mosshell", "centre": Vector2(-371.2711, 562.9456), "count": 1, "body": 1.40, "candidates": [1.0, 1.5, 2.0, 2.5, 3.0]},
	{"order": 8, "species": "brooktail", "centre": Vector2(-356.1437, 516.158), "count": 1, "body": 1.05, "candidates": [1.0, 1.5, 2.0, 2.5, 3.0]},
]


func _init() -> void:
	var water_file := FileAccess.open(WATER_PATH, FileAccess.READ)
	var water_data: Dictionary = JSON.parse_string(water_file.get_as_text())
	var water_level: float = float((water_data.get("water", {}) as Dictionary).get("level", -17.0))
	var field := HEIGHTFIELD.new(HEIGHTFIELD.load_config())

	for c: Dictionary in CASES:
		print("\n%s (order %d), centre %s, body %.2f" % [c["species"], c["order"], str(c["centre"]), c["body"]])
		for radius: float in c["candidates"]:
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("wild_spawn_%d" % int(c["order"]))
			var line := "  radius %.1f:" % radius
			for n in int(c["count"]):
				var angle := rng.randf_range(0.0, TAU)
				var distance := radius * sqrt(rng.randf())
				var spot: Vector2 = c["centre"] + Vector2(sin(angle), cos(angle)) * distance
				var h: float = field.height_at(spot.x, spot.y)
				var depth: float = water_level - h
				var body_h: float = c["body"]
				var frac: float = clampf(1.0 - depth / body_h, 0.0, 1.0) if depth > 0.0 else 1.0
				line += "  ind%d dist=%.2f depth=%.2f clear=%.0f%%" % [n + 1, distance, depth, frac * 100.0]
			print(line)
	quit(0)
