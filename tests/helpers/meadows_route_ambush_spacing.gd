extends RefCounted

## F02.4 (pacing). Deterministic, offline measure of how often an AGGRESSIVE
## wild cluster can force a fight on the earned Upper Meadows -> Hall road.
##
## Why this exists: a real-save walk from Gate F S08 north along this road
## fought four aggressive Galecrest from four clusters (orders 4102, 4916,
## 4005, 4917) in 118 s / ~320 m and was then pinned by a pack
## (ralph/reports/MEADOWS-PAYOFFS/six-activities/discovery/lure-walk-receipts.log
## on ralph/f03-activity-rows, line 176). A live render shows one seed once;
## this measures every seed the same way, from the same data the director reads.
##
## THE ROUTE. `trail.bands` 3 + 4 of terrain_playground.json, band-4 entry
## (0,4760) to the Hall gate (0,7560) -- the exact polyline
## tests/helpers/meadows_earned_hall_segment.gd::departure_spine() walks past
## the river (captain bodies are joined from and returned to these points).
##
## THE ENVELOPE. A cluster member's home is scattered inside the cluster's
## `radius`; it idles up to `wander_radius` from home (the entry's own key, else
## combat.json `wild.wander_radius`); an aggressive body starts closing at
## catching.json `aggression.notice_range`. A walker anywhere on the painted
## path (half-width = paths.width/2 + paths.shoulder) can therefore be noticed
## when the road passes within
##     radius + wander_radius + notice_range + path half-width
## of the cluster centre. That is an upper bound -- the conservative side for a
## spacing rule: an envelope that does not reach the road can never force a
## fight on it, whatever the scatter and wander rolls do.
##
## THE SPECIES. Resolved exactly as encounter_director.gd does: the merged
## spawn table (band_content.gd) folded through spawn_tables.gd::plan_for() for
## the given world seed, then creature_species.gd::is_aggressive(). Seed 0 is
## the authored world; any other seed rolls table clusters.
##
## An AMBUSH POINT is the first chainage (metres along the route) at which the
## road enters a road-reaching aggressive envelope. Gaps are between
## consecutive ambush points.

const SPAWN_TABLES := preload("res://scripts/combat/spawn_tables.gd")
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CHAPTER_CURVE := preload("res://scripts/creatures/chapter_curve.gd")
const CATCH := preload("res://scripts/combat/catch_math.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")

const SPAWNS_PATH := "res://data/config/spawns.json"
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const ROUTE_BANDS: Array[String] = ["band4_upper_meadows_ironwood", "band5_stronghold_approach"]

## WORLD §3.1: "A meaningful sight, encounter or decision should occur every
## 150-250 m". A forced ambush is an encounter beat; two forced ones closer than
## the cadence's lower bound collapse into one uninterrupted fight chain (the
## receipt's defect). So consecutive ambush points must be >= 150 m apart, which
## also caps any 300 m stretch at two.
const MIN_AMBUSH_GAP_M := 150.0
const WINDOW_M := 300.0
const MAX_PER_WINDOW := 2


static func route() -> Array[Vector2]:
	var terrain: Dictionary = _json(TERRAIN_PATH)
	var out: Array[Vector2] = []
	for id: String in ROUTE_BANDS:
		for raw: Dictionary in terrain.get("trail", {}).get("bands", []):
			if str(raw.get("id", "")) != id:
				continue
			for p: Variant in raw.get("points", []):
				var v := Vector2(float((p as Array)[0]), float((p as Array)[1]))
				if out.is_empty() or out[-1] != v:
					out.append(v)
	return out


static func path_half_width() -> float:
	var paths: Dictionary = _json(TERRAIN_PATH).get("paths", {})
	return float(paths.get("width", 1.4)) * 0.5 + float(paths.get("shoulder", 1.1))


static func merged_spawns() -> Array:
	return BAND_CONTENT.load_config(SPAWNS_PATH, "spawns").get("spawns", []) as Array


static func exceptional_species() -> Array:
	var out: Array = []
	for id: Variant in SPECIES.table():
		if str(id).begins_with("_"):
			continue
		if SPECIES.definition(str(id)).has("variant_of"):
			out.append(str(id))
	return out


static func envelope_m(spawn: Dictionary, default_wander: float, notice: float, half_width: float) -> float:
	var wander := float(spawn.get("wander_radius", default_wander))
	var elder: Variant = spawn.get("elder", {})
	if elder is Dictionary and (elder as Dictionary).has("wander_radius"):
		wander = float((elder as Dictionary)["wander_radius"])
	return float(spawn.get("radius", 0.0)) + wander + notice + half_width


## First chainage at which `road` comes within `reach` of `c`, or -1.
static func entry_chainage(road: Array[Vector2], c: Vector2, reach: float) -> float:
	var walked := 0.0
	for i in road.size() - 1:
		var a := road[i]
		var b := road[i + 1]
		var length := a.distance_to(b)
		if length <= 0.0001:
			continue
		var dir := (b - a) / length
		var rel := c - a
		var along := rel.dot(dir)
		var perp_sq := rel.length_squared() - along * along
		if perp_sq <= reach * reach:
			var h := sqrt(maxf(0.0, reach * reach - perp_sq))
			var s0 := maxf(0.0, along - h)
			var s1 := minf(length, along + h)
			if s0 <= s1:
				return walked + s0
		walked += length
	return -1.0


## Shortest distance from `c` to the route centreline.
static func distance_to_route(road: Array[Vector2], c: Vector2) -> float:
	var best := INF
	for i in road.size() - 1:
		best = minf(best, c.distance_to(Geometry2D.get_closest_point_to_segment(c, road[i], road[i + 1])))
	return best


static func route_length(road: Array[Vector2]) -> float:
	var total := 0.0
	for i in road.size() - 1:
		total += road[i].distance_to(road[i + 1])
	return total


## One seed. `entries`/`cfg`/`curve`/`exceptional` may be passed in so a sweep
## does not reload the JSON 200 times.
static func measure(world_seed: int, entries: Array = [], cfg: Dictionary = {},
		curve: Dictionary = {}, exceptional: Array = []) -> Dictionary:
	if entries.is_empty():
		entries = merged_spawns()
	if cfg.is_empty():
		cfg = SPAWN_TABLES.config()
	if curve.is_empty():
		curve = CHAPTER_CURVE.config()
	var plan: Dictionary = SPAWN_TABLES.plan_for(entries, world_seed, cfg, curve, exceptional)
	var road := route()
	var half := path_half_width()
	var notice := float(CATCH.config().get("aggression", {}).get("notice_range", 14.0))
	var default_wander := float(MATH.config().get("wild", {}).get("wander_radius", 7.0))
	var ambushes: Array[Dictionary] = []
	for raw: Variant in entries:
		var spawn: Dictionary = raw
		var order := int(spawn.get("order", -1))
		var species := str(spawn.get("species", ""))
		if plan.has(order):
			species = str((plan[order] as Dictionary).get("species", species))
		if not SPECIES.is_aggressive(species):
			continue
		var centre: Array = spawn.get("centre", [])
		if centre.size() != 3:
			continue
		var c := Vector2(float(centre[0]), float(centre[2]))
		var at := entry_chainage(road, c, envelope_m(spawn, default_wander, notice, half))
		if at < 0.0:
			continue
		ambushes.append({"order": order, "species": species, "at_m": at})
	ambushes.sort_custom(func(x: Dictionary, y: Dictionary) -> bool:
		return float(x.at_m) < float(y.at_m) or (float(x.at_m) == float(y.at_m) and int(x.order) < int(y.order)))
	var gaps: Array[float] = []
	for i in range(1, ambushes.size()):
		gaps.append(float(ambushes[i].at_m) - float(ambushes[i - 1].at_m))
	var sorted_gaps := gaps.duplicate()
	sorted_gaps.sort()
	var worst := 0
	var worst_at := 0.0
	for i in ambushes.size():
		var n := 0
		for j in range(i, ambushes.size()):
			if float(ambushes[j].at_m) - float(ambushes[i].at_m) < WINDOW_M:
				n += 1
		if n > worst:
			worst = n
			worst_at = float(ambushes[i].at_m)
	var length := route_length(road)
	var short := 0
	for g: float in gaps:
		if g < MIN_AMBUSH_GAP_M:
			short += 1
	return {
		"seed": world_seed,
		"route_m": length,
		"ambushes": ambushes,
		"count": ambushes.size(),
		"per_km": ambushes.size() / (length / 1000.0) if length > 0.0 else 0.0,
		"min_gap_m": sorted_gaps[0] if not sorted_gaps.is_empty() else INF,
		"median_gap_m": _median(sorted_gaps),
		"max_gap_m": sorted_gaps[-1] if not sorted_gaps.is_empty() else INF,
		"short_gaps": short,
		"max_per_window": worst,
		"worst_window_at_m": worst_at,
	}


static func sweep(seeds: Array) -> Array[Dictionary]:
	var entries := merged_spawns()
	var cfg := SPAWN_TABLES.config()
	var curve := CHAPTER_CURVE.config()
	var exceptional := exceptional_species()
	var out: Array[Dictionary] = []
	for s: Variant in seeds:
		out.append(measure(int(s), entries, cfg, curve, exceptional))
	return out


static func summarize(results: Array[Dictionary]) -> Dictionary:
	var per_km: Array[float] = []
	var medians: Array[float] = []
	var min_gap := INF
	var max_gap := 0.0
	var worst := 0
	var worst_seed := -1
	var violating := 0
	for r: Dictionary in results:
		per_km.append(float(r.per_km))
		if float(r.median_gap_m) < INF:
			medians.append(float(r.median_gap_m))
		min_gap = minf(min_gap, float(r.min_gap_m))
		if float(r.max_gap_m) < INF:
			max_gap = maxf(max_gap, float(r.max_gap_m))
		if int(r.max_per_window) > worst:
			worst = int(r.max_per_window)
			worst_seed = int(r.seed)
		if int(r.short_gaps) > 0 or int(r.max_per_window) > MAX_PER_WINDOW:
			violating += 1
	per_km.sort()
	medians.sort()
	return {
		"seeds": results.size(),
		"per_km_min": per_km[0] if not per_km.is_empty() else 0.0,
		"per_km_median": _median(per_km),
		"per_km_max": per_km[-1] if not per_km.is_empty() else 0.0,
		"min_gap_m": min_gap,
		"median_gap_m": _median(medians),
		"max_gap_m": max_gap,
		"worst_per_300m": worst,
		"worst_seed": worst_seed,
		"violating_seeds": violating,
	}


static func line(label: String, r: Dictionary) -> String:
	return "%s count=%d per_km=%.2f min_gap=%.0fm median_gap=%.0fm max_gap=%.0fm short_gaps=%d max_per_300m=%d (at %.0fm)" % [
		label, int(r.count), float(r.per_km), float(r.min_gap_m), float(r.median_gap_m),
		float(r.max_gap_m), int(r.short_gaps), int(r.max_per_window), float(r.worst_window_at_m)]


static func summary_line(label: String, s: Dictionary) -> String:
	return "%s seeds=%d per_km[min/med/max]=%.2f/%.2f/%.2f min_gap=%.0fm median_of_median_gaps=%.0fm max_gap=%.0fm worst_per_300m=%d (seed %d) violating_seeds=%d" % [
		label, int(s.seeds), float(s.per_km_min), float(s.per_km_median), float(s.per_km_max),
		float(s.min_gap_m), float(s.median_gap_m), float(s.max_gap_m), int(s.worst_per_300m), int(s.worst_seed),
		int(s.violating_seeds)]


static func _median(sorted_values: Array) -> float:
	if sorted_values.is_empty():
		return INF
	var n := sorted_values.size()
	if n % 2 == 1:
		return float(sorted_values[n / 2])
	return (float(sorted_values[n / 2 - 1]) + float(sorted_values[n / 2])) * 0.5


static func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
