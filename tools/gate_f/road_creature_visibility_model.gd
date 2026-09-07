class_name RoadCreatureVisibilityModel
extends RefCounted

## ROAD, owner playtest 2026-09-07.
##
## `Camera3D.far` is not an honest answer to "can I see a creature?": the Meadows
## camera clips at 2 km while the repository's rendered CP-2 measurement says a
## one-metre creature occupies about 15 px at 40 m under the shipped 70-degree,
## 720p exploration view. This model uses that measured projected-size floor,
## samples each authored route every 10 m, and counts only bodies in the forward
## 180-degree horizontal cone. A larger authored body therefore qualifies farther
## away; a small one has to stand close enough to still read as an animal.

const SAMPLE_STEP_M := 10.0
const VIEWPORT_HEIGHT_PX := 720.0
const VERTICAL_FOV_DEG := 70.0
const MIN_VISIBLE_HEIGHT_PX := 15.0
const REFERENCE_BODY_HEIGHT_M := 1.0
const REFERENCE_DISTANCE_M := 40.0
const REFERENCE_PROJECTED_HEIGHT_PX := 15.0
const REQUIRED_VISIBLE := 2

const MEADOWS_TERRAIN := "res://data/config/terrain_playground.json"
const MEADOWS_TABLES := "res://data/config/spawn_tables.json"
const SPECIES_DATA := "res://data/creatures/species.json"
const CLOUDREACH_WORLD := "res://data/config/cloudreach_world.json"
const CLOUDREACH_CHAPTER := "res://data/config/cloudreach_chapter.json"
const CLOUDREACH_ENCOUNTERS := "res://data/config/cloudreach_encounters.json"
const STORMWOOD_WORLD := "res://data/config/stormwood_world.json"
const STORMWOOD_ENCOUNTERS := "res://data/config/stormwood_encounters.json"

## The main Cloudreach road is authored as several named pieces around one required
## Fly out-and-back. These are the grounded chapter-spine pieces, not optional loops.
const CLOUDREACH_MAIN_ROUTE_IDS: Array[String] = [
	"arrival_gate_road",
	"lower_cliff_road",
	"broken_causeway_main",
	"windscar_floor_loop",
	"windscar_counterweight_pass",
	"upper_summit_road",
]


static func evaluate_all() -> Dictionary:
	var species := _species_heights()
	return {
		"criterion": {
			"sample_step_m": SAMPLE_STEP_M,
			"viewport_height_px": VIEWPORT_HEIGHT_PX,
			"vertical_fov_deg": VERTICAL_FOV_DEG,
			"minimum_projected_height_px": MIN_VISIBLE_HEIGHT_PX,
			"reference_body_height_m": REFERENCE_BODY_HEIGHT_M,
			"reference_distance_m": REFERENCE_DISTANCE_M,
			"reference_projected_height_px": REFERENCE_PROJECTED_HEIGHT_PX,
			"forward_cone_deg": 180.0,
			"required_visible": REQUIRED_VISIBLE,
		},
		"meadows": _evaluate_meadows(species),
		"cloudreach": _evaluate_cloudreach(species),
		"stormwood": _evaluate_stormwood(species),
	}


static func all_routes_pass(result: Dictionary) -> bool:
	for realm_id: String in ["meadows", "cloudreach", "stormwood"]:
		for route: Dictionary in result.get(realm_id, []):
			if int(route.get("failing_samples", 0)) > 0:
				return false
	return true


static func _evaluate_meadows(species: Dictionary) -> Array[Dictionary]:
	var terrain := _json(MEADOWS_TERRAIN)
	var tables: Dictionary = _json(MEADOWS_TABLES).get("tables", {})
	var bodies: Array[Dictionary] = []
	for path: String in _meadows_spawn_paths():
		for spawn: Dictionary in _json(path).get("spawns", []):
			# The owner reproduction is a fresh game's first daytime/clear-weather
			# road run. A night-only or rain/fog-only cluster cannot satisfy it.
			if str(spawn.get("time", "day")) == "night":
				continue
			var weather: Array = spawn.get("weather", [])
			if not weather.is_empty() and not weather.has("clear"):
				continue
			var height := _height_for(str(spawn.get("species", "")), species)
			var table_id := str(spawn.get("table", ""))
			if not table_id.is_empty():
				height = _min_meadows_table_height(tables.get(table_id, {}), species)
			bodies.append(_body(
				_point3(spawn.get("centre", [])),
				int(spawn.get("count", 1)),
				height,
				"order:%d" % int(spawn.get("order", -1))
			))
	var out: Array[Dictionary] = []
	for band: Dictionary in terrain.get("trail", {}).get("bands", []):
		out.append(_evaluate_route(
			str(band.get("id", "unknown_band")),
			_points_xz(band.get("points", [])), bodies
		))
	return out


static func _evaluate_cloudreach(species: Dictionary) -> Array[Dictionary]:
	var world := _json(CLOUDREACH_WORLD)
	var chapter := _json(CLOUDREACH_CHAPTER)
	var encounters := _json(CLOUDREACH_ENCOUNTERS)
	var tables := _by_id(chapter.get("encounter_tables", []))
	var bodies: Array[Dictionary] = []
	for site: Dictionary in encounters.get("wild_sites", []):
		var table: Dictionary = tables.get(str(site.get("table_id", "")), {})
		bodies.append(_body(
			_point3(site.get("position", [])),
			int(site.get("count", 1)),
			_min_cloudreach_table_height(table, species),
			str(site.get("id", "unknown_site"))
		))
	var out: Array[Dictionary] = []
	for route: Dictionary in world.get("routes", []):
		var id := str(route.get("id", ""))
		if not CLOUDREACH_MAIN_ROUTE_IDS.has(id):
			continue
		out.append(_evaluate_route(id, _points_cloudreach(route.get("polyline", [])), bodies))
	return out


static func _evaluate_stormwood(species: Dictionary) -> Array[Dictionary]:
	var world := _json(STORMWOOD_WORLD)
	var encounters := _json(STORMWOOD_ENCOUNTERS)
	var tables := _by_id(encounters.get("tables", []))
	var bodies: Array[Dictionary] = []
	for cluster: Dictionary in encounters.get("wild_clusters", []):
		var table: Dictionary = tables.get(str(cluster.get("calm_table_id", "")), {})
		# stormwood_encounter_catalogue.gd deliberately expands every authored
		# site to one pair (ORDINARY_GROUP_COUNT), rather than reading a count
		# field from this catalogue.
		bodies.append(_body(
			_point3(cluster.get("position", [])),
			2,
			_min_stormwood_table_height(table, species),
			str(cluster.get("id", "unknown_cluster"))
		))
	var out: Array[Dictionary] = []
	for route: Dictionary in world.get("routes", []):
		if str(route.get("kind", "")) != "critical":
			continue
		out.append(_evaluate_route(
			str(route.get("id", "unknown_route")),
			_points_xz(route.get("points", [])), bodies
		))
	return out


static func _evaluate_route(id: String, points: Array[Vector3], bodies: Array[Dictionary]) -> Dictionary:
	var samples := _sample_route(points)
	var counts: Array[int] = []
	var failing_positions: Array[Array] = []
	var longest_run := 0
	var current_run := 0
	var minimum := 999999
	for sample: Dictionary in samples:
		var visible := 0
		for body: Dictionary in bodies:
			if _body_visible_from(body, sample):
				visible += int(body["count"])
		counts.append(visible)
		minimum = mini(minimum, visible)
		if visible < REQUIRED_VISIBLE:
			current_run += 1
			longest_run = maxi(longest_run, current_run)
			var at: Vector3 = sample["at"]
			failing_positions.append([snappedf(at.x, 0.1), snappedf(at.y, 0.1), snappedf(at.z, 0.1)])
		else:
			current_run = 0
	return {
		"id": id,
		"samples": samples.size(),
		"minimum_visible": minimum if not samples.is_empty() else 0,
		"failing_samples": failing_positions.size(),
		"longest_failing_run_m": longest_run * SAMPLE_STEP_M,
		"failing_positions": failing_positions,
		"counts": counts,
	}


static func _body_visible_from(body: Dictionary, sample: Dictionary) -> bool:
	var at: Vector3 = sample["at"]
	var delta: Vector3 = (body["at"] as Vector3) - at
	var horizontal := Vector2(delta.x, delta.z)
	var forward3: Vector3 = sample["forward"]
	var forward := Vector2(forward3.x, forward3.z)
	if horizontal.length_squared() > 0.0001 and horizontal.dot(forward) < 0.0:
		return false
	# The Meadows and Stormwood road sources carry XZ only, and Cloudreach's
	# authored route/site Y values share the same local stratum. The owner's
	# cone is horizontal; use horizontal range rather than manufacturing a
	# vertical separation from a missing road height.
	var distance := maxf(horizontal.length(), 0.1)
	var projected_px := projected_height_px(float(body["height_m"]), distance)
	return projected_px >= MIN_VISIBLE_HEIGHT_PX


static func projected_height_px(body_height_m: float, distance_m: float) -> float:
	# CP-2 measured the complete shipped render at this camera setup; preserve
	# that empirical 1m/40m/15px calibration rather than replacing it with a
	# nominal pinhole-camera estimate that disagrees with the measured frame.
	return REFERENCE_PROJECTED_HEIGHT_PX * (body_height_m / REFERENCE_BODY_HEIGHT_M) \
		* (REFERENCE_DISTANCE_M / maxf(distance_m, 0.1))


static func _sample_route(points: Array[Vector3]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if points.size() < 2:
		return out
	var walked := 0.0
	var next_sample_distance := 0.0
	var last_forward := Vector3.FORWARD
	for index in points.size() - 1:
		var a := points[index]
		var b := points[index + 1]
		var delta := b - a
		var length := delta.length()
		if length <= 0.001:
			continue
		var forward := delta / length
		last_forward = forward
		while next_sample_distance < walked + length:
			var distance_in_segment := next_sample_distance - walked
			if distance_in_segment >= 0.0:
				out.append({"at": a + forward * distance_in_segment, "forward": forward})
			next_sample_distance += SAMPLE_STEP_M
		walked += length
	if out.is_empty() or (out[-1]["at"] as Vector3).distance_to(points[-1]) > 0.01:
		out.append({"at": points[-1], "forward": last_forward})
	return out


static func _body(at: Vector3, count: int, height_m: float, id: String) -> Dictionary:
	return {"at": at, "count": count, "height_m": height_m, "id": id}


static func _species_heights() -> Dictionary:
	var out := {}
	var rows: Dictionary = _json(SPECIES_DATA).get("species", {})
	for id: String in rows:
		var row: Dictionary = rows.get(id, {})
		out[id] = float(row.get("placeholder", {}).get("height", 1.0))
	return out


static func _height_for(id: String, species: Dictionary) -> float:
	return maxf(0.1, float(species.get(id, 1.0)))


static func _min_cloudreach_table_height(table: Dictionary, species: Dictionary) -> float:
	var minimum := 999999.0
	for entry: Dictionary in table.get("entries", []):
		var id := str(entry.get("species", entry.get("placeholder_species", "")))
		minimum = minf(minimum, _height_for(id, species))
	return minimum if minimum < 999999.0 else 1.0


static func _min_meadows_table_height(table: Dictionary, species: Dictionary) -> float:
	var minimum := 999999.0
	for entry: Dictionary in table.get("entries", []):
		var id := str(entry.get("species", ""))
		minimum = minf(minimum, _height_for(id, species))
	return minimum if minimum < 999999.0 else 1.0


static func _min_stormwood_table_height(table: Dictionary, species: Dictionary) -> float:
	var minimum := 999999.0
	for role: Dictionary in table.get("roles", []):
		var id := str(role.get("species", role.get("placeholder_species", "")))
		minimum = minf(minimum, _height_for(id, species))
	return minimum if minimum < 999999.0 else 1.0


static func _meadows_spawn_paths() -> Array[String]:
	var paths: Array[String] = []
	for dir_name: String in DirAccess.get_directories_at("res://data/config/bands"):
		var path := "res://data/config/bands/%s/spawns.json" % dir_name
		if FileAccess.file_exists(path):
			paths.append(path)
	paths.sort()
	return paths


static func _by_id(rows: Array) -> Dictionary:
	var out := {}
	for row: Dictionary in rows:
		out[str(row.get("id", ""))] = row
	return out


static func _points_xz(raw: Array) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for point: Array in raw:
		if point.size() >= 2:
			out.append(Vector3(float(point[0]), 0.0, float(point[1])))
	return out


static func _points_cloudreach(raw: Array) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for encoded: Variant in raw:
		if encoded is Array and (encoded as Array).size() >= 3:
			var values := encoded as Array
			out.append(Vector3(float(values[0]), float(values[1]), float(values[2])))
		elif encoded is String:
			var fields := (encoded as String).split(" ", false)
			if fields.size() == 3:
				out.append(Vector3(float(fields[0]), float(fields[1]), float(fields[2])))
	return out


static func _point3(raw: Array) -> Vector3:
	if raw.size() < 3:
		return Vector3.ZERO
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))


static func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ROAD visibility probe cannot open " + path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is not Dictionary:
		push_error("ROAD visibility probe cannot parse " + path)
		return {}
	return parsed as Dictionary
