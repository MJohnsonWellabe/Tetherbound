extends SceneTree

## W17-DENSITY-B2-B3. Per-band content census, from the data the world is
## built from, in seconds rather than a world boot.
##
##   godot --headless --path . --script tools/_probe_band_density.gd
##
## ## What it answers
##
## The owner's "there isn't enough to do anywhere... nothing to take you off
## the path" (OWNER_PLAYTEST_2026-09-04) and the addendum's §C measurements:
## per band, the wild clusters and heads, the harvest nodes, the authored
## pickups split critical-vs-optional and by family, all as per-km figures
## against the band's own spine length so bands of different extent compare;
## and the worst gap between points of interest along the spine, computed the
## way `tools/_probe_gate_f_corridor.gd` computes it (step the spine, count a
## thing "met" the first time it is within NOTICE_M of the walker) but from
## authored positions rather than a booted tree.
##
## ## Why a second census beside the corridor probe
##
## `_probe_gate_f_corridor.gd` is the runtime truth -- it sees the creatures
## that actually stood up, with their time/weather gates applied -- and takes
## ~10 minutes and a world boot. It does not know about `pickups.json` (it
## predates it) and it cannot be run by a lane that has changed a JSON file
## and wants a number in the same minute. This reads the same files the world
## reads (`band_content.gd`'s merge, `band_pickups.gd`'s loader) and reports
## the AUTHORED density; run the corridor probe afterwards for the runtime
## confirmation and quote both. Where they disagree, the corridor probe wins.
##
## Night/weather-gated clusters are counted in the totals and reported
## separately, because a gated cluster is not a daytime pull (the corridor
## probe hides them the same way).

const BAND_CONTENT := preload("res://scripts/data/band_content.gd")
const BAND_PICKUPS := preload("res://scripts/world/band_pickups.gd")

const TERRAIN_CFG := "res://data/config/terrain_playground.json"
const STEP_M := 4.0
## Same notice radius as the corridor probe, for the same reason: "would a
## player walking here notice it and could they choose to go to it".
const NOTICE_M := 30.0
const WALK_MPS := 4.0

var _bands: Array = []


func _init() -> void:
	_run()


func _run() -> void:
	_load_bands()
	var spawns: Array = BAND_CONTENT.load_config("res://data/config/spawns.json", "spawns").get("spawns", []) as Array
	var harvest: Array = BAND_CONTENT.load_config("res://data/config/harvest.json", "nodes").get("nodes", []) as Array
	var trainers: Array = BAND_CONTENT.load_config("res://data/config/trainers.json", "trainers").get("trainers", []) as Array
	var props: Array = BAND_CONTENT.load_config("res://data/config/props.json", "clusters").get("clusters", []) as Array
	var pickups: Array = BAND_PICKUPS.load_all()

	print("BAND DENSITY CENSUS (authored data; run tools/_probe_gate_f_corridor.gd for the runtime confirmation)")
	print("")
	for band: Variant in _bands:
		var spec: Dictionary = band
		var id: String = spec["id"]
		var index: int = spec["index"]
		var z_lo: float = spec["z_lo"]
		var z_hi: float = spec["z_hi"]
		var spine: Array = spec["points"]
		var length: float = spec["length"]
		var km := length / 1000.0

		var points: Array = []
		var clusters := 0
		var heads := 0
		var gated := 0
		var alphas := 0
		var species := {}
		for entry: Variant in spawns:
			var s: Dictionary = entry
			var centre: Array = s.get("centre", [0.0, 0.0, 0.0]) as Array
			var z := float(centre[2])
			if not _in_band(z, z_lo, z_hi, index):
				continue
			clusters += 1
			heads += int(s.get("count", 0))
			species[str(s.get("species", ""))] = true
			if s.has("alpha") or s.has("elder"):
				alphas += 1
			var is_gated := s.has("time") or s.has("weather")
			if is_gated:
				gated += 1
			points.append({"at": Vector2(float(centre[0]), z), "kind": "wild", "gated": is_gated,
				"what": "wild %s x%d%s" % [str(s.get("species", "")), int(s.get("count", 0)), " (gated)" if is_gated else ""]})

		var nodes := 0
		var by_item := {}
		for entry: Variant in harvest:
			var h: Dictionary = entry
			var at: Array = h.get("at", [0.0, 0.0]) as Array
			var z := float(at[1])
			if not _in_band(z, z_lo, z_hi, index):
				continue
			nodes += 1
			var item := str(h.get("item", ""))
			by_item[item] = int(by_item.get(item, 0)) + 1
			points.append({"at": Vector2(float(at[0]), z), "kind": "gather", "gated": false, "what": "gather %s" % item})

		var trainer_count := 0
		for entry: Variant in trainers:
			var t: Dictionary = entry
			var pos: Array = t.get("position", [0.0, 0.0]) as Array
			var z := float(pos[1])
			if not _in_band(z, z_lo, z_hi, index):
				continue
			trainer_count += 1
			points.append({"at": Vector2(float(pos[0]), z), "kind": "trainer", "gated": false, "what": "trainer %s" % str(t.get("id", ""))})

		var prop_clusters := 0
		var rests := 0
		for entry: Variant in props:
			var c: Dictionary = entry
			var at := _cluster_at(c)
			if at == Vector2.INF or not _in_band(at.y, z_lo, z_hi, index):
				continue
			prop_clusters += 1
			var kind := "props"
			if c.has("rest"):
				rests += 1
				kind = "rest"
			points.append({"at": at, "kind": kind, "gated": false, "what": "%s %s" % [kind, str(c.get("name", ""))]})

		var pickup_count := 0
		var critical := 0
		var optional := 0
		var tiers := {}
		var families := {}
		var pickup_points: Array = []
		for entry: Variant in pickups:
			var p: Dictionary = entry
			if str(p["band"]) != id:
				continue
			pickup_count += 1
			var tier := str(p["tier"])
			tiers[tier] = int(tiers.get(tier, 0)) + 1
			if tier == "critical":
				critical += 1
			else:
				optional += 1
			var family := _family(str(p["item"]))
			families[family] = int(families.get(family, 0)) + 1
			pickup_points.append({"at": p["pos"] as Vector2, "kind": "pickup", "gated": false,
				"what": "pickup %s (%s)" % [str(p["item"]), tier]})

		var without := _walk(spine, points, false)
		var with_pickups := _walk(spine, points + pickup_points, false)
		var daytime := _walk(spine, points + pickup_points, true)

		print("== %s ==  spine %.0f m (~%.1f min)" % [id, length, length / WALK_MPS / 60.0])
		print("  wild:    %3d clusters (%d gated night/weather, %d alpha/elder), %3d heads, %d species  -> %.1f clusters/km, %.1f heads/km" % [
			clusters, gated, alphas, heads, species.size(), clusters / km, heads / km])
		print("  harvest: %3d nodes  -> %.1f/km   %s" % [nodes, nodes / km, _counts(by_item)])
		print("  pickups: %3d  (%d critical, %d optional)  tiers %s  families %s  -> %.1f/km" % [
			pickup_count, critical, optional, _counts(tiers), _counts(families), pickup_count / km])
		print("  trainers %d, prop clusters %d (%d rest)" % [trainer_count, prop_clusters, rests])
		print("  spine walk: met %d things, worst gap %.0f m (all authored, no pickups)" % [without["met"], without["worst"]])
		print("              met %d things, worst gap %.0f m (with pickups)" % [with_pickups["met"], with_pickups["worst"]])
		print("              met %d things, worst gap %.0f m (with pickups, gated clusters hidden = daytime, clear)" % [daytime["met"], daytime["worst"]])
		print("DENSITY-METRIC band=%s metres=%.0f clusters=%d heads=%d gated=%d alphas=%d species=%d clusters_per_km=%.1f heads_per_km=%.1f harvest=%d harvest_per_km=%.1f pickups=%d critical=%d optional=%d good=%d great=%d rare=%d recovery=%d trainers=%d props=%d worst_gap_m=%.0f worst_gap_daytime_m=%.0f worst_gap_no_pickups_m=%.0f" % [
			id, length, clusters, heads, gated, alphas, species.size(), clusters / km, heads / km, nodes, nodes / km,
			pickup_count, critical, optional, int(families.get("good_candy", 0)), int(families.get("great_candy", 0)),
			int(families.get("rare_candy", 0)), int(families.get("recovery", 0)) + int(families.get("mushroom", 0)),
			trainer_count, prop_clusters, with_pickups["worst"], daytime["worst"], without["worst"]])
		print("")
	quit(0)


## A cluster's z decides its band, by the band's spine extent; a cluster past
## the last band's end belongs to the last band, before the first to the
## first (the corridor probe reads the same seams the same way).
func _in_band(z: float, z_lo: float, z_hi: float, index: int) -> bool:
	if index == 0 and z < z_lo:
		return true
	if index == _bands.size() - 1 and z > z_hi:
		return true
	# Seams: the band's last point is the next band's first, so a thing on the
	# seam line belongs to the earlier band.
	return z > z_lo and z <= z_hi if index > 0 else z <= z_hi


func _cluster_at(cluster: Dictionary) -> Vector2:
	if cluster.has("rest"):
		var at: Array = (cluster["rest"] as Dictionary).get("at", []) as Array
		if at.size() == 2:
			return Vector2(float(at[0]), float(at[1]))
	var props: Array = cluster.get("props", []) as Array
	if props.is_empty():
		return Vector2.INF
	var first: Array = (props[0] as Dictionary).get("at", []) as Array
	if first.size() != 2:
		return Vector2.INF
	return Vector2(float(first[0]), float(first[1]))


func _family(item: String) -> String:
	if item.ends_with("_candy"):
		return item
	if item.ends_with("_mushroom"):
		return "mushroom"
	return "recovery"


func _counts(dict: Dictionary) -> String:
	var keys := dict.keys()
	keys.sort()
	var parts: Array[String] = []
	for key: Variant in keys:
		parts.append("%s=%d" % [str(key), int(dict[key])])
	return " ".join(parts)


## Step the spine and count things met, the corridor probe's own method.
func _walk(spine: Array, points: Array, hide_gated: bool) -> Dictionary:
	var seen := {}
	var travelled := 0.0
	var last := 0.0
	var worst := 0.0
	var met := 0
	for leg in range(spine.size() - 1):
		var a: Vector2 = spine[leg]
		var b: Vector2 = spine[leg + 1]
		var length := a.distance_to(b)
		var steps := maxi(1, int(length / STEP_M))
		for s in range(steps):
			var here := a.lerp(b, float(s) / float(steps))
			travelled += length / float(steps)
			for i in points.size():
				if seen.has(i):
					continue
				var point: Dictionary = points[i]
				if hide_gated and bool(point["gated"]):
					continue
				if here.distance_to(point["at"] as Vector2) > NOTICE_M:
					continue
				seen[i] = true
				met += 1
				worst = maxf(worst, travelled - last)
				last = travelled
	# The tail after the last thing met is a gap the walker crosses too.
	worst = maxf(worst, travelled - last)
	return {"met": met, "worst": worst}


func _load_bands() -> void:
	var file := FileAccess.open(TERRAIN_CFG, FileAccess.READ)
	var cfg: Dictionary = JSON.parse_string(file.get_as_text())
	var trail: Dictionary = cfg.get("trail", {}) as Dictionary
	var index := 0
	for band: Variant in (trail.get("bands", []) as Array):
		var spec: Dictionary = band
		var points: Array = []
		var lo := INF
		var hi := -INF
		var length := 0.0
		for raw: Variant in (spec.get("points", []) as Array):
			var p := Vector2(float((raw as Array)[0]), float((raw as Array)[1]))
			if not points.is_empty():
				length += (points[-1] as Vector2).distance_to(p)
			points.append(p)
			lo = minf(lo, p.y)
			hi = maxf(hi, p.y)
		_bands.append({"id": str(spec.get("id", "")), "index": index, "points": points,
			"z_lo": lo, "z_hi": hi, "length": length})
		index += 1
