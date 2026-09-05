extends SceneTree

## W17/W18-DENSITY (CL-O4, addendum §B/§C): the per-band content census the
## density lanes report against band 1, plus a site validator for the
## positions they author.
##
##   godot --headless --path . --script tools/_probe_band_density.gd
##   godot --headless --path . --script tools/_probe_band_density.gd -- --band=band4_upper_meadows_ironwood
##   godot --headless --path . --script tools/_probe_band_density.gd -- --sites=res://ralph/reports/X/sites.json
##
## ## What it measures, and how it differs from `_probe_gate_f_corridor.gd`
##
## D70's corridor probe walks the whole chapter as one route and counts what
## the SCENE holds (every spawned wild body, every placed node) so it can find
## the seams. This probe reads the AUTHORED band files instead -- spawns,
## harvest, props, trainers and the new `pickups.json` -- because the density
## lanes are editing those files and need to see the number they just moved,
## per band and per kilometre of that band's own spine, before and after.
## Both are honest about different things: the corridor probe measures what a
## player meets; this measures what a lane authored, and where it sits
## relative to the road (on the critical path, or a reason to leave it).
##
## The spine and its loops come from `terrain_playground.json`'s `trail`
## block, never transcribed, same as the corridor probe.
##
## ## Site validation
##
## Every pickup (and every `--sites` candidate) is checked on the real world:
## Terrain3D's own ground height (`playground_world.gd::ground_height_at`,
## NAN off-terrain), the headless heightfield's pad spread and worst slope
## over a 2 m pad (`tools/_probe_pickups_sites.gd`'s method), whether it sits
## inside solid scatter (`vegetation.gd::has_solid_scatter_near`, the same
## 0.8 m margin `encounter_director.gd` uses for a creature's feet), the
## river factor, its lateral distance to the spine, and the nearest other
## interact prompt (harvest node or pickup) -- `tests/test_harvest.gd` refuses
## two prompts inside 4.5 m, and a pickup beside a harvest node is the same
## contest. A site that fails any of these prints `SITE-FAIL`; the lane fixes
## the coordinate, it does not ship the row.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TERRAIN_CFG := "res://data/config/terrain_playground.json"
const BANDS_DIR := "res://data/config/bands"
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

const STEP_M := 4.0
## Same 30 m as the corridor probe: "would a player on the road notice it and
## could they choose to go to it".
const NOTICE_M := 30.0
const WALK_MPS := 4.0
## Two interact prompts closer than this contest each other
## (`tests/test_harvest.gd::MIN_SPOT_SEPARATION`).
const MIN_PROMPT_SEPARATION := 4.5
const SCATTER_MARGIN := 0.8
const MAX_PAD_SLOPE_DEG := 30.0
const MAX_PAD_SPREAD_M := 2.0

var _field: RefCounted = null
var _world: Node = null
var _vegetation: Node = null
var _bands: Array = []


func _init() -> void:
	_run()


func _run() -> void:
	var only_band := ""
	var sites_path := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--band="):
			only_band = arg.trim_prefix("--band=")
		elif arg.begins_with("--sites="):
			sites_path = arg.trim_prefix("--sites=")

	_field = HEIGHTFIELD.new()
	_load_bands()
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in 240:
		await physics_frame
	_vegetation = _world.get("_vegetation") as Node

	for band: Dictionary in _bands:
		var band_id := str(band["id"])
		if not only_band.is_empty() and band_id != only_band:
			continue
		_census(band)

	if not sites_path.is_empty():
		_validate_sites_file(sites_path)

	quit(0)


func _load_bands() -> void:
	var cfg := _read_json(TERRAIN_CFG)
	var trail: Dictionary = cfg.get("trail", {})
	var loops: Array = trail.get("loops", [])
	var index := 0
	for entry: Variant in (trail.get("bands", []) as Array):
		var band: Dictionary = entry
		index += 1
		var pts: Array = []
		for p: Variant in (band["points"] as Array):
			pts.append(Vector2(float(p[0]), float(p[1])))
		var band_loops: Array = []
		for l: Variant in loops:
			var loop: Dictionary = l
			if int(loop.get("band", -1)) != index:
				continue
			var lpts: Array = []
			for p: Variant in (loop.get("points", []) as Array):
				lpts.append(Vector2(float(p[0]), float(p[1])))
			band_loops.append({"id": str(loop.get("id", "")), "points": lpts})
		_bands.append({"id": str(band["id"]), "index": index, "points": pts, "loops": band_loops})


## --- census -------------------------------------------------------------------


func _census(band: Dictionary) -> void:
	var band_id := str(band["id"])
	var spine: Array = band["points"]
	var spine_m := _polyline_length(spine)
	var loops_m := 0.0
	for loop: Dictionary in band["loops"]:
		loops_m += _polyline_length(loop["points"])
	var z_lo: float = (spine[0] as Vector2).y
	var z_hi: float = (spine[spine.size() - 1] as Vector2).y

	var spawns: Array = _read_json("%s/%s/spawns.json" % [BANDS_DIR, band_id]).get("spawns", [])
	var harvest: Array = _read_json("%s/%s/harvest.json" % [BANDS_DIR, band_id]).get("nodes", [])
	var props: Array = _read_json("%s/%s/props.json" % [BANDS_DIR, band_id]).get("clusters", [])
	var trainers: Array = _read_json("%s/%s/trainers.json" % [BANDS_DIR, band_id]).get("trainers", [])
	var pickups: Array = _read_json("%s/%s/pickups.json" % [BANDS_DIR, band_id]).get("pickups", [])

	var creatures := 0
	var species := {}
	for s: Variant in spawns:
		var spawn: Dictionary = s
		creatures += int(spawn.get("count", 1))
		species[str(spawn.get("species", ""))] = true

	var harvest_items := {}
	for h: Variant in harvest:
		var node: Dictionary = h
		var item := str(node.get("item", ""))
		harvest_items[item] = int(harvest_items.get(item, 0)) + 1

	var tiers := {}
	var items := {}
	var candy := {"good_candy": 0, "great_candy": 0, "rare_candy": 0}
	var on_path := 0
	var off_path := 0
	for p: Variant in pickups:
		var pickup: Dictionary = p
		var tier := str(pickup.get("tier", "?"))
		tiers[tier] = int(tiers.get(tier, 0)) + 1
		var item := str(pickup.get("item", ""))
		items[item] = int(items.get(item, 0)) + 1
		if candy.has(item):
			candy[item] = int(candy[item]) + 1
		var pos: Array = pickup.get("pos", [])
		if pos.size() == 2:
			var lateral := _lateral_to(spine, Vector2(float(pos[0]), float(pos[1])))
			if lateral <= NOTICE_M:
				on_path += 1
			else:
				off_path += 1

	# Every authored thing that a player on the spine could notice, projected
	# to its chainage; the worst gap between two of them is the band's own
	# "longest stretch meeting nothing" for AUTHORED content.
	var met: Array = []
	for s: Variant in spawns:
		var spawn: Dictionary = s
		var c: Array = spawn.get("centre", [0, 0, 0])
		_note(met, spine, Vector2(float(c[0]), float(c[2])), float(spawn.get("radius", 0.0)),
			"wild %s x%d" % [str(spawn.get("species", "")), int(spawn.get("count", 1))])
	for h: Variant in harvest:
		var node: Dictionary = h
		var at: Array = node.get("at", [0, 0])
		_note(met, spine, Vector2(float(at[0]), float(at[1])), 0.0, "gather %s" % str(node.get("item", "")))
	for c: Variant in props:
		var cluster: Dictionary = c
		var centre := _cluster_centre(cluster)
		_note(met, spine, centre, 6.0, "props %s" % str(cluster.get("name", "")))
	for t: Variant in trainers:
		var trainer: Dictionary = t
		var at: Array = trainer.get("position", [0, 0])
		_note(met, spine, Vector2(float(at[0]), float(at[1])), 0.0, "trainer %s" % str(trainer.get("id", "")))
	for p: Variant in pickups:
		var pickup: Dictionary = p
		var pos: Array = pickup.get("pos", [0, 0])
		_note(met, spine, Vector2(float(pos[0]), float(pos[1])), 0.0, "pickup %s" % str(pickup.get("item", "")))
	met.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["m"]) < float(b["m"]))
	var worst_gap := 0.0
	var worst_at := 0.0
	var last := 0.0
	for row: Dictionary in met:
		var gap := float(row["m"]) - last
		if gap > worst_gap:
			worst_gap = gap
			worst_at = float(row["m"])
		last = float(row["m"])
	var tail := spine_m - last
	if tail > worst_gap:
		worst_gap = tail
		worst_at = spine_m

	var km := spine_m / 1000.0
	print("== %s ==" % band_id)
	print("  spine %.0f m (%.1f min at %.0f m/s), loops %.0f m, z %.0f..%.0f" % [spine_m, spine_m / WALK_MPS / 60.0, WALK_MPS, loops_m, z_lo, z_hi])
	print("  spawns: %d clusters / %d creatures / %d species  (%.1f clusters/km, %.1f creatures/km)" % [
		spawns.size(), creatures, species.size(), spawns.size() / km, creatures / km])
	print("  harvest: %d nodes (%.1f/km)  %s" % [harvest.size(), harvest.size() / km, str(harvest_items)])
	print("  props clusters: %d   trainers: %d" % [props.size(), trainers.size()])
	print("  pickups: %d (%.1f/km)  tiers %s  candy G/Gr/R %d/%d/%d  on-path(<=%.0fm) %d / off-path %d  items %s" % [
		pickups.size(), pickups.size() / km, str(tiers), int(candy["good_candy"]), int(candy["great_candy"]),
		int(candy["rare_candy"]), NOTICE_M, on_path, off_path, str(items)])
	print("  authored things noticeable from the spine: %d; worst gap between two of them: %.0f m at %.0f m" % [
		met.size(), worst_gap, worst_at])
	print("DENSITY-METRIC band=%s spine_m=%.0f spawns=%d creatures=%d spawns_per_km=%.1f harvest=%d harvest_per_km=%.1f pickups=%d pickups_per_km=%.1f candy_good=%d candy_great=%d candy_rare=%d pickups_on_path=%d pickups_off_path=%d noticed=%d worst_gap_m=%.0f" % [
		band_id, spine_m, spawns.size(), creatures, spawns.size() / km, harvest.size(), harvest.size() / km,
		pickups.size(), pickups.size() / km, int(candy["good_candy"]), int(candy["great_candy"]),
		int(candy["rare_candy"]), on_path, off_path, met.size(), worst_gap])

	if not pickups.is_empty():
		print("  -- pickup sites --")
		var prompts: Array = []
		for h: Variant in harvest:
			var node: Dictionary = h
			var at: Array = node.get("at", [0, 0])
			prompts.append({"at": Vector2(float(at[0]), float(at[1])), "what": "gather %s" % str(node.get("item", ""))})
		for p: Variant in pickups:
			var pickup: Dictionary = p
			var pos: Array = pickup.get("pos", [0, 0])
			prompts.append({"at": Vector2(float(pos[0]), float(pos[1])), "what": "pickup %s" % str(pickup.get("id", ""))})
		var failures := 0
		for p: Variant in pickups:
			var pickup: Dictionary = p
			var pos: Array = pickup.get("pos", [0, 0])
			var at := Vector2(float(pos[0]), float(pos[1]))
			if not _validate_site(str(pickup.get("id", "?")), at, spine, prompts, z_lo, z_hi):
				failures += 1
		print("DENSITY-METRIC band=%s pickup_sites=%d site_failures=%d" % [band_id, pickups.size(), failures])
	print("")


func _validate_sites_file(path: String) -> void:
	var sites: Array = _read_json(path).get("sites", [])
	print("== candidate sites: %s (%d) ==" % [path, sites.size()])
	var failures := 0
	for s: Variant in sites:
		var site: Dictionary = s
		var pos: Array = site.get("pos", [0, 0])
		var at := Vector2(float(pos[0]), float(pos[1]))
		var band := _band_for_z(at.y)
		var spine: Array = band.get("points", [])
		var prompts: Array = []
		if not band.is_empty():
			var band_id := str(band["id"])
			for h: Variant in _read_json("%s/%s/harvest.json" % [BANDS_DIR, band_id]).get("nodes", []):
				var node: Dictionary = h
				var hat: Array = node.get("at", [0, 0])
				prompts.append({"at": Vector2(float(hat[0]), float(hat[1])), "what": "gather %s #%s" % [str(node.get("item", "")), str(node.get("order", ""))]})
			for p: Variant in _read_json("%s/%s/pickups.json" % [BANDS_DIR, band_id]).get("pickups", []):
				var pickup: Dictionary = p
				var ppos: Array = pickup.get("pos", [0, 0])
				prompts.append({"at": Vector2(float(ppos[0]), float(ppos[1])), "what": "pickup %s" % str(pickup.get("id", ""))})
		var z_lo: float = (spine[0] as Vector2).y if not spine.is_empty() else -INF
		var z_hi: float = (spine[spine.size() - 1] as Vector2).y if not spine.is_empty() else INF
		if not _validate_site(str(site.get("id", "?")), at, spine, prompts, z_lo, z_hi):
			failures += 1
	print("DENSITY-METRIC sites=%d site_failures=%d" % [sites.size(), failures])


## One site, every check, one line. Returns false on any failure.
func _validate_site(id: String, at: Vector2, spine: Array, prompts: Array, z_lo: float, z_hi: float) -> bool:
	var ground := NAN
	if _world != null and _world.has_method("ground_height_at"):
		ground = float(_world.call("ground_height_at", at.x, at.y))
	var pad := _pad(at.x, at.y, 2.0)
	var scatter := false
	if _vegetation != null and _vegetation.has_method("has_solid_scatter_near"):
		var h := ground if not is_nan(ground) else float(pad[0])
		scatter = bool(_vegetation.call("has_solid_scatter_near", Vector3(at.x, h, at.y), SCATTER_MARGIN))
	var river := 0.0
	if _field.has_method("river_factor"):
		river = float(_field.call("river_factor", at.x, at.y))
	var lateral := _lateral_to(spine, at) if not spine.is_empty() else NAN
	var nearest := INF
	var nearest_what := ""
	for p: Dictionary in prompts:
		var d := at.distance_to(p["at"] as Vector2)
		if d < 0.01:
			continue
		if d < nearest:
			nearest = d
			nearest_what = str(p["what"])
	var problems: Array[String] = []
	if is_nan(ground):
		problems.append("no terrain under it")
	if float(pad[2]) > MAX_PAD_SLOPE_DEG:
		problems.append("slope %.0f deg" % float(pad[2]))
	if float(pad[1]) > MAX_PAD_SPREAD_M:
		problems.append("pad spread %.1f m" % float(pad[1]))
	if scatter:
		var clear := _nearest_clear(at, ground if not is_nan(ground) else float(pad[0]))
		if clear.is_empty():
			problems.append("inside solid scatter, nothing clear within %.0f m" % SUGGEST_RADII_M[-1])
		else:
			problems.append("inside solid scatter; nearest clear ground [%.1f, %.1f]" % [
				(clear["at"] as Vector2).x, (clear["at"] as Vector2).y])
	if river > 0.0:
		problems.append("river factor %.2f" % river)
	if at.y < z_lo - 1.0 or at.y > z_hi + 1.0:
		problems.append("outside band z %.0f..%.0f" % [z_lo, z_hi])
	if nearest < MIN_PROMPT_SEPARATION:
		problems.append("%.1f m from %s" % [nearest, nearest_what])
	var tag := "SITE-OK  " if problems.is_empty() else "SITE-FAIL"
	print("  %s %-34s [%7.1f,%7.1f] h=%7.2f spread=%4.2f slope=%4.1f scatter=%s lateral=%5.1f nearest=%5.1f (%s)%s" % [
		tag, id, at.x, at.y, ground, float(pad[1]), float(pad[2]), "Y" if scatter else "n", lateral,
		nearest if nearest < INF else -1.0, nearest_what, ("" if problems.is_empty() else "  <- " + ", ".join(problems))])
	return problems.is_empty()


## The nearest spot around `at` that `has_solid_scatter_near` calls clear, so a
## failing site can be moved in one round rather than guessed at again.
## Rings of 12 bearings at 2/4/6/8 m; {} when every ring is blocked.
const SUGGEST_RADII_M: Array[float] = [2.0, 4.0, 6.0, 8.0]


func _nearest_clear(at: Vector2, h: float) -> Dictionary:
	if _vegetation == null or not _vegetation.has_method("has_solid_scatter_near"):
		return {}
	for r: float in SUGGEST_RADII_M:
		for i in 12:
			var a := TAU * float(i) / 12.0
			var spot := at + Vector2(cos(a), sin(a)) * r
			if not bool(_vegetation.call("has_solid_scatter_near", Vector3(spot.x, h, spot.y), SCATTER_MARGIN)):
				return {"at": spot, "r": r}
	return {}


## --- geometry -----------------------------------------------------------------


func _note(met: Array, spine: Array, at: Vector2, radius: float, what: String) -> void:
	var proj := _project(spine, at)
	if float(proj["lateral"]) - radius <= NOTICE_M:
		met.append({"m": float(proj["m"]), "what": what})


func _lateral_to(spine: Array, at: Vector2) -> float:
	return float(_project(spine, at)["lateral"])


## Chainage along the polyline of the closest point to `at`, and the lateral
## distance to it.
func _project(pts: Array, at: Vector2) -> Dictionary:
	var best_lat := INF
	var best_m := 0.0
	var run := 0.0
	for i in range(pts.size() - 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var ab := b - a
		var seg := ab.length()
		var t := 0.0
		if seg > 0.0:
			t = clampf((at - a).dot(ab) / (seg * seg), 0.0, 1.0)
		var closest := a + ab * t
		var lat := at.distance_to(closest)
		if lat < best_lat:
			best_lat = lat
			best_m = run + seg * t
		run += seg
	return {"m": best_m, "lateral": best_lat}


func _polyline_length(pts: Array) -> float:
	var total := 0.0
	for i in range(pts.size() - 1):
		total += (pts[i] as Vector2).distance_to(pts[i + 1] as Vector2)
	return total


func _cluster_centre(cluster: Dictionary) -> Vector2:
	var sum := Vector2.ZERO
	var n := 0
	for p: Variant in (cluster.get("props", []) as Array):
		var prop: Dictionary = p
		var at: Array = prop.get("at", [])
		if at.size() == 2:
			sum += Vector2(float(at[0]), float(at[1]))
			n += 1
	return sum / float(maxi(n, 1))


func _band_for_z(z: float) -> Dictionary:
	for band: Dictionary in _bands:
		var pts: Array = band["points"]
		var lo: float = (pts[0] as Vector2).y
		var hi: float = (pts[pts.size() - 1] as Vector2).y
		if z >= lo - 1.0 and z <= hi + 1.0:
			return band
	return {}


func _slope_deg(x: float, z: float, r: float = 1.0) -> float:
	var h := float(_field.call("height_at", x, z))
	var worst := 0.0
	for off: Vector2 in [Vector2(r, 0), Vector2(-r, 0), Vector2(0, r), Vector2(0, -r)]:
		var d: float = absf(float(_field.call("height_at", x + off.x, z + off.y)) - h)
		worst = maxf(worst, rad_to_deg(atan2(d, r)))
	return worst


## [centre height, height spread over the pad, worst local slope in degrees]
func _pad(x: float, z: float, r: float) -> Array:
	var lo := 1e9
	var hi := -1e9
	var worst := 0.0
	for i in 16:
		var a := TAU * float(i) / 16.0
		for rr: float in [r * 0.5, r]:
			var px := x + cos(a) * rr
			var pz := z + sin(a) * rr
			var h := float(_field.call("height_at", px, pz))
			lo = minf(lo, h)
			hi = maxf(hi, h)
			worst = maxf(worst, _slope_deg(px, pz))
	var c := float(_field.call("height_at", x, z))
	lo = minf(lo, c)
	hi = maxf(hi, c)
	worst = maxf(worst, _slope_deg(x, z))
	return [c, hi - lo, worst]


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
