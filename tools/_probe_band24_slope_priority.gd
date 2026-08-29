extends SceneTree
## T1-CAST (§15 continuation). T1-CREATURE's handover named the exact gap:
## "sample 2 of 55 blindly" vs "check the 5 that are actually near rock" --
## and asked for a prioritisation check computed from the terrain, not
## guessed, before spending render budget. Band 2/4's own props.json carry
## only 1-2 authored rock-prop clusters each (quarry_station,
## ridge_patrol_camp) -- far too few points to explain 130+ spawn clusters
## worth of risk. The REAL rock-background driver is `vegetation.json`'s
## global "rocks" scatter layer, which places boulders procedurally by SLOPE
## everywhere in the world (min_slope_deg 6, max_slope_deg 44, see that
## file's own `_comment_slope`) -- not from an authored point list. So the
## sharp, computed signal for "this spawn is likely to have a creature
## standing in front of rock scatter" is the terrain slope AT the spawn's
## own centre: inside [6,44] degrees, rock is the layer's design intent;
## the higher within that band, the denser/larger the boulders scale_min/
## scale_max draws (scale still scales with slope proximity only loosely,
## but higher slope is strictly more likely to clear min_slope_deg with
## margin, i.e. more consistently seeded across the clump_radius=11m footprint
## rather than only at its edge).
##
## This is a lightweight terrain-only probe (like tools/_probe_sigil_gorge.gd)
## -- no scene load, seconds not minutes -- so it is meant to run BEFORE any
## render, to turn "sample blindly" into "render the top N".
##
##   godot --headless --path . --script tools/_probe_band24_slope_priority.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const ROCK_MIN_SLOPE := 6.0
const ROCK_MAX_SLOPE := 44.0

const BANDS := [
	["band2_stone_and_root", "res://data/config/bands/band2_stone_and_root/spawns.json"],
	["band4_upper_meadows_ironwood", "res://data/config/bands/band4_upper_meadows_ironwood/spawns.json"],
]


func _init() -> void:
	var field: RefCounted = HEIGHTFIELD.new(HEIGHTFIELD.load_config())
	for band: Array in BANDS:
		var band_name: String = band[0]
		var path: String = band[1]
		var f := FileAccess.open(path, FileAccess.READ)
		var data: Dictionary = JSON.parse_string(f.get_as_text())
		var spawns: Array = data.get("spawns", [])
		var rows: Array = []
		for spawn: Dictionary in spawns:
			var centre: Array = spawn.get("centre", [])
			if centre.size() < 3:
				continue
			var x: float = centre[0]
			var z: float = centre[2]
			var slope: float = field.slope_degrees_at(x, z)
			var in_rock_band: bool = slope >= ROCK_MIN_SLOPE and slope <= ROCK_MAX_SLOPE
			rows.append({
				"order": spawn.get("order", -1),
				"species": spawn.get("species", "?"),
				"centre": Vector2(x, z),
				"slope": slope,
				"in_rock_band": in_rock_band,
			})
		rows.sort_custom(func(a, b): return a["slope"] > b["slope"])
		print("=== %s: %d spawns, ranked by terrain slope at centre (rock scatter band %.0f-%.0f deg) ===" % [band_name, rows.size(), ROCK_MIN_SLOPE, ROCK_MAX_SLOPE])
		var in_band_count := 0
		for row: Dictionary in rows:
			if row["in_rock_band"]:
				in_band_count += 1
		print("%d of %d spawn centres fall inside the rock scatter slope band" % [in_band_count, rows.size()])
		print("%6s %-14s %20s %8s %10s" % ["order", "species", "centre", "slope", "in_band"])
		for row: Dictionary in rows.slice(0, 12):
			print("%6d %-14s %20s %8.1f %10s" % [row["order"], row["species"], str(row["centre"]), row["slope"], row["in_rock_band"]])
		print("")
	quit(0)
