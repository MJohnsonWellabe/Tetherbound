extends "res://tests/test_case.gd"

## WO-F09-04: Stormwood's routes are painted into the committed Terrain3D
## control map as the `path` texture slot (stormwood_road_surface.json), so a
## player sees the road and every pocket spur on the ground, and grass_field's
## grass (which refuses that slot) stays off them. Every check reads the
## COMMITTED region files, not a re-run of the bake, and each main check has a
## negative control that runs the same measurement on data it must reject.

const BAKER := preload("res://scripts/world/build_stormwood_terrain.gd")
const FIELD := preload("res://scripts/world/stormwood_heightfield.gd")
const POCKETS := preload("res://scripts/world/stormwood_pockets.gd")
const DATA_DIR := "res://data/terrain/stormwood"
const REGION_M := 512.0
const TRAINER_M := 1.8
## Share of centreline samples that must land on a painted texel.
const CENTRELINE_MIN := 0.97
## Painted full width may differ from 2 x lane_half_width_m by this much on
## average: the lattice is 2 m and the edge wanders by design.
const WIDTH_TOLERANCE_M := 0.9

var _regions := {}


class FixtureWorld extends Node3D:
	var simulation_only := false
	var field := FIELD.new()

	func ground_height_at(x: float, z: float) -> float:
		return field.height_at(x, z)


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary


func _routes() -> Array:
	return _json(BAKER.WORLD_PATH).routes


func _surface() -> Dictionary:
	return _json(BAKER.SURFACE_PATH)


func _path_id() -> int:
	return BAKER.texture_id(str(_surface().texture))


func _xz(raw: Array) -> Vector2:
	return Vector2(float(raw[0]), float(raw[1]))


## Committed region resource covering world `at`, cached.
func _region(at: Vector2) -> Resource:
	var loc := Vector2i(floori(at.x / REGION_M), floori(at.y / REGION_M))
	if not _regions.has(loc):
		var name := "terrain3d%s%02d%s%02d.res" % ["-" if loc.x < 0 else "_", absi(loc.x), "-" if loc.y < 0 else "_", absi(loc.y)]
		var region: Resource = load("%s/%s" % [DATA_DIR, name])
		_regions[loc] = [region, (region.get("control_map") as Image).get_data() if region != null else PackedByteArray(),
			(region.get("height_map") as Image).get_data() if region != null else PackedByteArray()]
	return _regions[loc][0]


## Committed control texel nearest world `at` (the texel Terrain3D reads there).
func _control(at: Vector2) -> int:
	var texel := Vector2(roundf(at.x / 2.0) * 2.0, roundf(at.y / 2.0) * 2.0)
	var loc := Vector2i(floori(texel.x / REGION_M), floori(texel.y / REGION_M))
	if _region(texel) == null:
		return -1
	var bytes: PackedByteArray = _regions[loc][1]
	var px := int(roundf((texel.x - loc.x * REGION_M) / 2.0))
	var pz := int(roundf((texel.y - loc.y * REGION_M) / 2.0))
	return bytes.decode_u32((pz * 256 + px) * 4)


func _committed_is_path(at: Vector2) -> bool:
	var value := _control(at)
	return value >= 0 and (value >> 27) & 0x1F == _path_id() and value & 1 == 0


func _segments(route: Dictionary) -> Array:
	var out: Array = []
	var points: Array = route.points
	for i in range(1, points.size()):
		out.append([_xz(points[i - 1]), _xz(points[i])])
	return out


func _distance_to_routes(at: Vector2, routes: Array, skip_id: String = "") -> float:
	var nearest := INF
	for route: Dictionary in routes:
		if str(route.id) == skip_id:
			continue
		for seg: Array in _segments(route):
			nearest = minf(nearest, Geometry2D.get_closest_point_to_segment(at, seg[0], seg[1]).distance_to(at))
	return nearest


## Fraction of 2 m centreline samples of `route` that `is_path` accepts.
func _centreline_fraction(route: Dictionary, is_path: Callable) -> float:
	var hits := 0
	var total := 0
	for seg: Array in _segments(route):
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		var steps := maxi(1, ceili(a.distance_to(b) / 2.0))
		for n in steps:
			total += 1
			if bool(is_path.call(a.lerp(b, float(n) / steps))):
				hits += 1
	return float(hits) / maxf(1.0, float(total))


## Painted full width across `route` measured perpendicular at stations every
## 10 m, 0.25 m steps out from the centreline until the first unpainted
## sample. Stations near a vertex, a spur's flare or another route are
## skipped so only this lane's own edge is measured.
func _mean_width(route: Dictionary, routes: Array, is_path: Callable, reach: float) -> float:
	var widths: Array[float] = []
	var flare_end := float(_surface().junction.flare_length_m) + 4.0
	var run := 0.0
	for seg: Array in _segments(route):
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		var length := a.distance_to(b)
		var dir := (b - a) / length
		var side := dir.orthogonal()
		var s := 12.0
		while s < length - 12.0:
			var centre := a + dir * s
			if (str(route.kind) != "spur" or run + s > flare_end) \
					and _distance_to_routes(centre, routes, str(route.id)) > reach * 2.0 + 6.0:
				var width := 0.0
				for sign: float in [-1.0, 1.0]:
					var out := 0.25
					while out < reach * 3.0 and bool(is_path.call(centre + side * sign * out)):
						out += 0.25
					width += out - 0.25
				widths.append(width)
			s += 10.0
		run += length
	var total := 0.0
	for w in widths:
		total += w
	return total / maxf(1.0, float(widths.size())) if not widths.is_empty() else NAN


func _max_reach() -> float:
	var surface := _surface()
	var widest := 0.0
	for kind: String in surface.lane_half_width_m:
		if not kind.begins_with("_"):
			widest = maxf(widest, float(surface.lane_half_width_m[kind]))
	return widest + float(surface.junction.flare_m) + float(surface.edge.wander_m) + float(surface.edge.fringe_m) * 0.5


# --------------------------------------------------------------------- tests

func test_surface_config_names_a_real_slot_and_every_route_kind() -> void:
	var surface := _surface()
	assert_eq(BAKER.validate_surface(surface, _routes()), "", "the committed config is valid")
	assert_eq(_path_id(), 3, "'path' is terrain_playground.json slot 3 (the dirt path texture)")
	assert_true(float(surface.lane_half_width_m.spur) < float(surface.lane_half_width_m.critical), "a spur is narrower than a road")
	assert_true(float(surface.lane_half_width_m.spur) * 2.0 >= TRAINER_M * 2.0, "a spur is still at least two trainers wide")
	# Negative controls: an unknown route kind and an unknown slot are refused.
	var extra := _routes().duplicate(true)
	extra.append({"id": "stray", "kind": "goat_track", "points": [[0, 0], [10, 0]]})
	assert_ne(BAKER.validate_surface(surface, extra), "", "control: a route kind with no lane width fails the bake")
	var wrong := surface.duplicate(true)
	wrong.texture = "tarmac"
	assert_ne(BAKER.validate_surface(wrong, _routes()), "", "control: a texture that is not a slot fails the bake")


func test_every_route_centreline_is_painted_path() -> void:
	var committed := Callable(self, "_committed_is_path")
	var routes := _routes()
	assert_eq(routes.size(), 15, "all 15 authored routes, 5 of them spurs")
	for route: Dictionary in routes:
		var fraction := _centreline_fraction(route, committed)
		assert_true(fraction >= CENTRELINE_MIN, "%s (%s): %.1f%% of its centreline is the path slot" % [route.id, route.kind, fraction * 100.0])
	# Negative control: the same routes moved 40 m sideways are not a road.
	var moved := 0.0
	for route: Dictionary in routes:
		var shifted := route.duplicate(true)
		var seg: Array = _segments(route)[0]
		var side: Vector2 = ((seg[1] as Vector2) - (seg[0] as Vector2)).normalized().orthogonal() * 40.0
		for point: Array in shifted.points:
			point[0] = float(point[0]) + side.x
			point[1] = float(point[1]) + side.y
		moved = maxf(moved, _centreline_fraction(shifted, committed))
	assert_true(moved < CENTRELINE_MIN * 0.5, "control: routes shifted 40 m sideways are at most %.1f%% path" % (moved * 100.0))
	# Negative control: the pre-WO heights-only control data (every texel the
	# default auto texel) fails the same check.
	var unpainted := func(at: Vector2) -> bool: return false
	assert_true(_centreline_fraction(routes[0], unpainted) < CENTRELINE_MIN, "control: an unpainted control map fails")


## Off-route samples on a 58 m grid farther than `clear` from every route:
## [checked, painted sample positions].
func _off_route_paint(routes: Array, clear: float, is_path: Callable) -> Array:
	var checked := 0
	var painted: Array[String] = []
	var z := 13.0
	while z < 6144.0:
		var x := -2547.0
		while x < 2048.0:
			var at := Vector2(x, z)
			if _distance_to_routes(at, routes) > clear:
				checked += 1
				if bool(is_path.call(at)):
					painted.append(str(at))
			x += 58.0
		z += 58.0
	return [checked, painted]


func test_ground_well_off_every_route_is_not_path() -> void:
	var routes := _routes()
	var clear := _max_reach() + 2.0
	var committed := Callable(self, "_committed_is_path")
	var result := _off_route_paint(routes, clear, committed)
	assert_true(int(result[0]) > 5000, "%d samples more than %.1f m from any route" % [int(result[0]), clear])
	assert_eq((result[1] as Array).size(), 0, "no off-route texel is path: %s" % str((result[1] as Array).slice(0, 5)))
	# Negative control: the committed data plus one stray painted patch 60 m
	# across, far from any road, is caught by the same check.
	var stray := func(at: Vector2) -> bool:
		return committed.call(at) or at.distance_to(Vector2(1500.0, 505.0)) < 60.0
	var caught := _off_route_paint(routes, clear, stray)
	assert_true((caught[1] as Array).size() > 0, "control: a stray painted patch is found (%d samples)" % (caught[1] as Array).size())


func test_spurs_are_painted_to_their_mouth_and_stop_there() -> void:
	var cfg := POCKETS.config()
	var committed := Callable(self, "_committed_is_path")
	for pocket: Dictionary in cfg.pockets:
		var spur := POCKETS.spur(pocket)
		var points: Array = spur.points
		var end := _xz(points[points.size() - 1])
		var start := _xz(points[0])
		var up := (end - start).normalized()
		assert_true(end.distance_to(POCKETS.FRAME.mouth(pocket, cfg)) <= 0.5, "%s: the spur ends at the mouth" % pocket.id)
		var last := 0
		for back in range(0, 13):
			if _committed_is_path(end - up * float(back)):
				last += 1
		assert_true(last >= 12, "%s: the last 12 m to the mouth is path (%d/13 samples)" % [pocket.id, last])
		assert_true(_committed_is_path(end), "%s: the texel at the mouth is path" % pocket.id)
		# Negative control: 12 m past the mouth, inside the pocket and away
		# from the lane's rounded end, is not painted -- the check can fail.
		assert_false(_committed_is_path(end + up * 12.0), "control: %s's pocket interior 12 m past the mouth is not path" % pocket.id)
		# And the spur is painted from its junction: its first 20 m.
		var first := 0
		for n in range(0, 21):
			if _committed_is_path(start + up * float(n)):
				first += 1
		assert_true(first >= 20, "%s: the spur's first 20 m from the road is path (%d/21)" % [pocket.id, first])


func test_painted_width_matches_config_per_route_kind() -> void:
	var surface := _surface()
	var routes := _routes()
	var committed := Callable(self, "_committed_is_path")
	var by_kind := {}
	for route: Dictionary in routes:
		var half := float(surface.lane_half_width_m[str(route.kind)])
		var mean := _mean_width(route, routes, committed, half)
		if is_nan(mean):
			continue
		if not by_kind.has(route.kind):
			by_kind[route.kind] = []
		(by_kind[route.kind] as Array).append(mean)
	for kind: String in ["critical", "loop", "spur"]:
		assert_true(by_kind.has(kind), "measured at least one %s route" % kind)
	for kind: String in by_kind:
		var total := 0.0
		for w: float in by_kind[kind]:
			total += w
		var mean := total / float((by_kind[kind] as Array).size())
		var want := float(surface.lane_half_width_m[kind]) * 2.0
		assert_true(absf(mean - want) <= WIDTH_TOLERANCE_M, "%s lanes are %.2f m wide on the ground (config %.2f m)" % [kind, mean, want])
		# Negative control: the same measurement rejects double the width.
		assert_true(absf(mean - want * 2.0) > WIDTH_TOLERANCE_M, "control: %s lanes are not %.2f m wide" % [kind, want * 2.0])
	# Negative control: a synthetic lane of a known wrong width is measured as
	# that width, so the measurement follows the paint rather than the config.
	var spur: Dictionary = {}
	for route: Dictionary in routes:
		if str(route.kind) == "spur":
			spur = route
			break
	var seg: Array = _segments(spur)[0]
	var narrow := func(at: Vector2) -> bool:
		return Geometry2D.get_closest_point_to_segment(at, seg[0], seg[1]).distance_to(at) <= 0.6
	var measured := _mean_width(spur, routes, narrow, 2.0)
	assert_true(absf(measured - float(surface.lane_half_width_m.spur) * 2.0) > WIDTH_TOLERANCE_M,
		"control: a 1.2 m synthetic lane measures %.2f m, not the config width" % measured)


func test_spur_junction_flares_so_the_y_reads() -> void:
	var cfg := POCKETS.config()
	var surface := _surface()
	var routes := _routes()
	for pocket: Dictionary in cfg.pockets:
		var spur := POCKETS.spur(pocket)
		var points: Array = spur.points
		var start := _xz(points[0])
		var up := (_xz(points[1]) - start).normalized()
		var side := up.orthogonal()
		var near := _width_at(start + up * 7.0, side)
		var far := _width_at(start + up * 30.0, side)
		assert_true(near >= far + 1.0, "%s: 7 m up the spur the lane is %.1f m wide, 30 m up %.1f m" % [pocket.id, near, far])
	# The flare is the config's: the bake's half-width function at the junction.
	var segment: Dictionary = BAKER.lane_segments([POCKETS.spur(cfg.pockets[0])], surface)[0]
	assert_almost_eq(BAKER.lane_half_width(segment, 0.0), float(surface.lane_half_width_m.spur) + float(surface.junction.flare_m), 0.001)
	assert_almost_eq(BAKER.lane_half_width(segment, 40.0), float(surface.lane_half_width_m.spur), 0.001)
	# Negative control: with no flare configured the half-width is flat.
	var flat := surface.duplicate(true)
	flat.junction.flare_m = 0.0
	var plain: Dictionary = BAKER.lane_segments([POCKETS.spur(cfg.pockets[0])], flat)[0]
	assert_almost_eq(BAKER.lane_half_width(plain, 0.0), BAKER.lane_half_width(plain, 40.0), 0.001, "control: no flare, no Y")
	assert_true(routes.size() > 0)


func _width_at(centre: Vector2, side: Vector2) -> float:
	var width := 0.0
	for sign: float in [-1.0, 1.0]:
		var out := 0.25
		while out < 10.0 and _committed_is_path(centre + side * sign * out):
			out += 0.25
		width += out - 0.25
	return width


func test_bake_manifest_is_fresh_and_covers_routes_and_surface() -> void:
	var manifest := _json("%s/manifest.json" % DATA_DIR)
	assert_eq(int(manifest.regions), 108, "a full-world bake")
	var hashes: Dictionary = manifest.dependency_hashes
	for path: String in [BAKER.WORLD_PATH, BAKER.SURFACE_PATH, BAKER.TEXTURES_PATH, BAKER.SCRIPT_PATH]:
		assert_true(hashes.has(path), "the fingerprint covers %s" % path)
	assert_eq(int(manifest.dependency_fingerprint), BAKER.current_fingerprint(), "the committed bake is fresh for this checkout")
	# Negative control: moving one spur point by 1 m stales the fingerprint.
	var sources := {}
	for path: String in BAKER.dependency_paths():
		sources[path] = FileAccess.get_file_as_string(path)
	var world_text := str(sources[BAKER.WORLD_PATH])
	var moved := world_text.replace("[-335.0,369.2]", "[-336.0,369.2]")
	assert_ne(moved, world_text, "control setup: the spur point is in the file")
	sources[BAKER.WORLD_PATH] = moved
	assert_ne(BAKER.dependency_fingerprint(sources), int(manifest.dependency_fingerprint), "control: a moved route stales the bake")


func test_committed_heights_still_match_the_heightfield() -> void:
	var field := FIELD.new()
	var checked := 0
	var worst := 0.0
	var z := 7.0
	while z < 6144.0:
		var x := -2555.0
		while x < 2048.0:
			var texel := Vector2(roundf(x / 2.0) * 2.0, roundf(z / 2.0) * 2.0)
			var loc := Vector2i(floori(texel.x / REGION_M), floori(texel.y / REGION_M))
			if _region(texel) != null:
				var bytes: PackedByteArray = _regions[loc][2]
				var px := int(roundf((texel.x - loc.x * REGION_M) / 2.0))
				var pz := int(roundf((texel.y - loc.y * REGION_M) / 2.0))
				worst = maxf(worst, absf(bytes.decode_float((pz * 256 + px) * 4) - field.height_at(texel.x, texel.y)))
				checked += 1
			x += 97.0
		z += 97.0
	assert_true(checked > 2500, "%d height samples" % checked)
	assert_true(worst < 0.001, "painting the surface left every sampled height on the heightfield (worst %.5f m)" % worst)
	# Negative control: a heightfield 1 m higher does not match.
	var raised_cfg := FIELD.load_config()
	raised_cfg.base_height = float(raised_cfg.base_height) + 1.0
	var raised := FIELD.new(raised_cfg)
	var texel := Vector2(-600.0, 1000.0)
	var loc := Vector2i(floori(texel.x / REGION_M), floori(texel.y / REGION_M))
	_region(texel)
	var bytes: PackedByteArray = _regions[loc][2]
	var index := (int(roundf((texel.y - loc.y * REGION_M) / 2.0)) * 256 + int(roundf((texel.x - loc.x * REGION_M) / 2.0))) * 4
	assert_true(absf(bytes.decode_float(index) - raised.height_at(texel.x, texel.y)) > 0.5, "control: a shifted heightfield is caught")


func test_junction_marker_size_and_emission_come_from_config() -> void:
	var cfg := POCKETS.config()
	var style := POCKETS.spur_lamp_style(cfg)
	var lamp: Dictionary = cfg.spur_marker.lamp
	for key: String in lamp:
		assert_eq(style[key], lamp[key], "spur_marker.lamp.%s overrides mouth_lure" % key)
	var world := FixtureWorld.new()
	var pockets := POCKETS.new()
	world.add_child(pockets)
	pockets.build(world)
	for pocket: Dictionary in cfg.pockets:
		var holder := pockets.get_node_or_null("Pocket_%s/SpurLamp" % str(pocket.id)) as Node3D
		assert_true(holder != null, "%s has a junction lamp" % pocket.id)
		if holder == null:
			continue
		var measured := _lamp_measure(holder)
		assert_almost_eq(measured.post_height, float(style.post_height_m) + 0.4, 0.001, "%s: post height from config" % pocket.id)
		assert_almost_eq(measured.post_width, float(style.post_width_m), 0.001, "%s: post width from config" % pocket.id)
		assert_almost_eq(measured.lantern_scale, float(style.lantern_scale), 0.001, "%s: lantern scale from config" % pocket.id)
		assert_almost_eq(measured.emission, float(style.flame_emission_energy), 0.001, "%s: flame emission from config" % pocket.id)
		assert_true(measured.unshaded, "%s: the flame is unshaded so it keeps its colour by day" % pocket.id)
		assert_almost_eq(measured.halo, float(style.halo_radius_m) * 2.0, 0.001, "%s: glow billboard size from config" % pocket.id)
		assert_almost_eq(measured.light_energy, float(style.light_energy), 0.001, "%s: light energy from config" % pocket.id)
		assert_true(measured.head_m >= TRAINER_M * 2.4, "%s: the lantern head is %.2f m up, about 2.5x the trainer" % [pocket.id, measured.head_m])
		var collider := pockets.get_node("Pocket_%s/SpurPost" % str(pocket.id)) as CollisionShape3D
		assert_almost_eq((collider.shape as BoxShape3D).size.x, float(style.post_width_m), 0.001, "%s: the junction collider matches its post" % pocket.id)
		# The mouth lamps keep the mouth_lure size.
		var mouth := pockets.get_node("Pocket_%s/MouthLamp0" % str(pocket.id)) as Node3D
		var mouth_measured := _lamp_measure(mouth)
		assert_almost_eq(mouth_measured.post_height, float(cfg.mouth_lure.post_height_m) + 0.4, 0.001, "%s: mouth lamps unchanged" % pocket.id)
		# Negative control: the mouth lamp (no override) fails the 2.5x check.
		assert_false(mouth_measured.head_m >= TRAINER_M * 2.4, "control: the %.2f m mouth lamp head is below 2.4x the trainer" % mouth_measured.head_m)
	world.free()


func _lamp_measure(holder: Node3D) -> Dictionary:
	var post := holder.get_node("Post") as MeshInstance3D
	var flame := holder.get_node("AmberFlame") as MeshInstance3D
	var flame_material := flame.material_override as StandardMaterial3D
	var halo := holder.get_node_or_null("DaylightHalo") as MeshInstance3D
	var light := holder.get_node("WarmMouthLight") as OmniLight3D
	return {
		"post_height": (post.mesh as BoxMesh).size.y,
		"post_width": (post.mesh as BoxMesh).size.x,
		"lantern_scale": (holder.get_node("Lantern") as Node3D).scale.x,
		"emission": flame_material.emission_energy_multiplier,
		"unshaded": flame_material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED,
		"halo": (halo.mesh as QuadMesh).size.x if halo != null else 0.0,
		"light_energy": light.light_energy,
		"head_m": flame.position.y,
	}
