extends "res://tests/test_case.gd"

## OPTION-B village layout (owner decision 2026-09-29, "the shape of the village
## still hasn't changed"): one straight main street at x = 10.5 with houses on
## both sides and a small green around the well. Everything here is read from
## the same data files the game and the terrain bake read, so host and guests
## get the identical layout (nothing is generated per peer).
##
## Rules pinned:
##  * the main street polyline is straight within 0.5 m of x = 10.5;
##  * the well is on the street axis and is the centre of the declared green;
##  * the inn no longer covers the (0,0) spawn;
##  * no two building footprints overlap;
##  * every villager, trainer and beacon in the village is outside every
##    building footprint (a shopkeeper who stands inside the shop his own
##    footprint encloses, and a beacon over an enterable house, are the named
##    exceptions) and reachable from a road or the green;
##  * the pond, rise, trail and stoneyard exits and Grandpa's door stay
##    connected to the main street over the road polylines (1.5 m join);
##  * neither moved building (inn, stone cottage) blocks the street.

const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const VILLAGE_PATH := "res://data/config/village.json"
const NPCS_PATH := "res://data/config/village_npcs.json"
const TRAINERS_PATH := "res://data/config/bands/band1_lower_meadows/trainers.json"
const OBJECTIVES_PATH := "res://data/progression/objectives.json"

const STREET_ID := "village_main_street"
const AXIS_X := 10.5
const STRAIGHT_TOLERANCE_M := 0.5
const JOIN_TOLERANCE_M := 1.5
## Villager, trainer and beacon positions this pass moved or created must sit
## within this distance of a road centreline or the green's edge.
const MOVED_REACH_M := 3.0
## Villagers and beacons this pass did not move keep their authored spots (the
## owner listed them as fixed). They must still be a short walk from a road.
const FIXED_REACH_M := 13.0
## Only positions inside the village fence's neighbourhood are checked.
const VILLAGE_BOX := Rect2(-45.0, -45.0, 90.0, 90.0)
## The (0,0) spawn: data/config/terrain_playground.json spawn_pad centre.
const SPAWN := Vector2.ZERO
## Shopkeepers who stand inside their own building's footprint.
const INTERIOR_PEOPLE := ["Mira", "Bram"]
## Beacons that name a walk-in house rather than a person outside it.
const INTERIOR_BEACON_NAMES := ["Grandpa", "Grandpa's Village", "Your first creature"]
## Trainers and NPCs whose spot moved with this change.
const MOVED_PEOPLE := ["Bram"]
const MOVED_TRAINER_IDS := ["trainer_oskar", "trainer_tam"]

var _terrain: Dictionary = {}
var _village: Dictionary = {}
## id -> PackedVector2Array
var _roads: Dictionary = {}
var _footprints: Array = []


func before_each() -> void:
	super.before_each()
	_terrain = _json(TERRAIN_PATH)
	_village = _json(VILLAGE_PATH)
	_roads = _load_roads()
	_footprints = _load_footprints()


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "%s parses as a JSON object" % path)
	return parsed as Dictionary if parsed is Dictionary else {}


func _v(raw: Variant) -> Vector2:
	var a := raw as Array
	return Vector2(float(a[0]), float(a[1]))


func _line(raw: Variant) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Variant in (raw as Array):
		out.append(_v(p))
	return out


## Every road polyline the terrain bake paints in the village, keyed by id or
## label: paths.routes, paths.approaches and the band-1 spine.
func _load_roads() -> Dictionary:
	var out := {}
	var paths := _terrain.get("paths", {}) as Dictionary
	for raw: Variant in (paths.get("routes", []) as Array):
		var r := raw as Dictionary
		out[str(r.get("id", r.get("label", "")))] = _line(r.get("points", []))
	for raw: Variant in (paths.get("approaches", []) as Array):
		var r := raw as Dictionary
		out[str(r.get("id", r.get("label", "")))] = _line(r.get("points", []))
	for raw: Variant in ((_terrain.get("trail", {}) as Dictionary).get("bands", []) as Array):
		var b := raw as Dictionary
		if str(b.get("id", "")) == "band1_lower_meadows":
			var pts := _line(b.get("points", []))
			# The spine runs 1300 m to the South Bridge; only its village end matters.
			out["band1_lower_meadows"] = PackedVector2Array([pts[0], pts[1]])
	return out


## Building footprints as the terrain bake sees them: [{name, centre, yaw,
## poly}], the far-away mill and ranger station left out.
func _load_footprints() -> Array:
	var out: Array = []
	for raw: Variant in ((_terrain.get("building_aprons", {}) as Dictionary).get("footprints", []) as Array):
		var fp := raw as Dictionary
		var centre := _v(fp.get("centre", []))
		if not VILLAGE_BOX.has_point(centre):
			continue
		out.append({
			"why": str(fp.get("_why", "")),
			"centre": centre,
			"half": _v(fp.get("half_extents", [])),
			"yaw": float(fp.get("yaw_deg", 0.0)),
			"poly": _rect(centre, _v(fp.get("half_extents", [])), float(fp.get("yaw_deg", 0.0)), 0.0),
		})
	return out


func _rect(centre: Vector2, half: Vector2, yaw_deg: float, grow: float) -> PackedVector2Array:
	var yaw := deg_to_rad(yaw_deg)
	var h := half + Vector2(grow, grow)
	var poly := PackedVector2Array()
	for c: Vector2 in [Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)]:
		poly.append(centre + Vector2(c.x * cos(yaw) + c.y * sin(yaw), -c.x * sin(yaw) + c.y * cos(yaw)))
	return poly


func _fp_named(fragment: String) -> Dictionary:
	for fp: Variant in _footprints:
		if str((fp as Dictionary)["why"]).to_lower().contains(fragment):
			return fp as Dictionary
	return {}


func _is_well(fp: Dictionary) -> bool:
	return (fp["centre"] as Vector2).distance_to(_well()) < 0.01


func _structure(prefab: String) -> Dictionary:
	for raw: Variant in (_village.get("structures", []) as Array):
		if str((raw as Dictionary).get("prefab", "")) == prefab:
			return raw as Dictionary
	return {}


func _well() -> Vector2:
	return _v(_structure("well").get("at", []))


func _green() -> Dictionary:
	return ((_terrain.get("paths", {}) as Dictionary).get("village_topology", {}) as Dictionary).get("green", {}) as Dictionary


func _dist_to_line(p: Vector2, line: PackedVector2Array) -> float:
	var best := INF
	for i in range(line.size() - 1):
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, line[i], line[i + 1])))
	return best


func _dist_to_roads(p: Vector2) -> float:
	var best := INF
	for id: String in _roads:
		best = minf(best, _dist_to_line(p, _roads[id] as PackedVector2Array))
	return best


func _dist_to_green(p: Vector2) -> float:
	var g := _green()
	return maxf(0.0, p.distance_to(_v(g.get("centre", [0, 0]))) - float(g.get("radius_m", 0.0)))


func _reach(p: Vector2) -> float:
	return minf(_dist_to_roads(p), _dist_to_green(p))


## --- the shape ---------------------------------------------------------------

func test_the_main_street_exists_and_is_straight_at_x_10_5() -> void:
	assert_true(_roads.has(STREET_ID), "paths.approaches carries %s" % STREET_ID)
	var street: PackedVector2Array = _roads.get(STREET_ID, PackedVector2Array())
	assert_true(street.size() >= 2, "the main street has at least two points")
	var length := 0.0
	for i in range(street.size()):
		assert_true(absf(street[i].x - AXIS_X) <= STRAIGHT_TOLERANCE_M,
			"main street point %d (%.2f,%.2f) is within %.1f m of x=%.1f" % [i, street[i].x, street[i].y, STRAIGHT_TOLERANCE_M, AXIS_X])
		if i > 0:
			length += street[i - 1].distance_to(street[i])
	assert_true(length >= 15.0, "the main street is a real street, not a stub (%.1f m)" % length)
	var north_end := minf(street[0].y, street[street.size() - 1].y)
	assert_true(north_end <= -14.0 and north_end >= -18.0,
		"the street starts at the north side lane, z about -16 (starts z=%.1f)" % north_end)


func test_the_well_stands_on_the_street_axis_at_the_centre_of_the_green() -> void:
	var well := _well()
	assert_true(absf(well.x - AXIS_X) <= 1.0, "the well is on the street axis (x=%.2f)" % well.x)
	var street: PackedVector2Array = _roads.get(STREET_ID, PackedVector2Array())
	assert_true(_dist_to_line(well, street) <= 1.0, "the well is on the street polyline")
	var green := _green()
	assert_false(green.is_empty(), "paths.village_topology.green is declared")
	assert_eq(_v(green.get("centre", [0, 0])), well, "the well is the centre of the green")
	var radius := float(green.get("radius_m", 0.0))
	assert_true(radius >= 3.5 and radius <= 5.0, "the green is small, about 4 m (%.1f m)" % radius)


func test_the_inn_faces_the_green_and_no_longer_covers_the_spawn() -> void:
	var inn := _fp_named("inn")
	assert_false(inn.is_empty(), "the inn has an apron footprint")
	if inn.is_empty():
		return
	assert_false(Geometry2D.is_point_in_polygon(SPAWN, inn["poly"] as PackedVector2Array),
		"the (0,0) spawn lies outside the inn footprint")
	var placed := _structure("inn")
	assert_eq(_v(placed.get("at", [])), inn["centre"], "the inn apron mirrors village.json")
	assert_eq(float(placed.get("yaw_deg", 0.0)), 90.0, "the inn is turned 90 degrees to face the green")
	var moved := _v(placed.get("at", [])).distance_to(Vector2(-1.5, -2.0))
	assert_almost_eq(moved, 4.1, 0.15, "the inn moved about 4.1 m")
	# The spawn also keeps clear of the inn's own doorstep.
	assert_true(SPAWN.distance_to(_v(_doorstep_near(_v(placed.get("at", []))).get("at", [0, 0]))) >= 3.0,
		"the spawn is not on the inn's doorstep")


func _doorstep_near(centre: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_d := INF
	for raw: Variant in (_village.get("structures", []) as Array):
		var s := raw as Dictionary
		if str(s.get("prefab", "")) != "doorstep":
			continue
		var d := _v(s.get("at", [])).distance_to(centre)
		if d < best_d:
			best_d = d
			best = s
	return best


func test_the_stone_cottage_faces_the_street_from_the_greens_east_side() -> void:
	var cottage := _structure("cottage_b")
	var at := _v(cottage.get("at", []))
	assert_almost_eq(at.distance_to(Vector2(19.0, -18.0)), 12.0, 0.1, "the cottage moved 12.0 m")
	assert_true(at.x > _well().x + float(_green().get("radius_m", 0.0)), "the cottage stands east of the green")
	assert_eq(float(cottage.get("yaw_deg", 0.0)), -90.0, "the cottage door faces west, toward the street")
	var step := _doorstep_near(at)
	assert_true(_v(step.get("at", [])).x < at.x, "the doorstep is on the street side of the cottage")


func test_no_two_building_footprints_overlap() -> void:
	assert_true(_footprints.size() >= 6, "the village's footprints are authored (%d)" % _footprints.size())
	for i in range(_footprints.size()):
		for j in range(i + 1, _footprints.size()):
			var a := _footprints[i] as Dictionary
			var b := _footprints[j] as Dictionary
			var hit := Geometry2D.intersect_polygons(a["poly"] as PackedVector2Array, b["poly"] as PackedVector2Array)
			assert_true(hit.is_empty(),
				"footprints at %s and %s overlap" % [str(a["centre"]), str(b["centre"])])


func test_neither_moved_building_blocks_the_main_street() -> void:
	var street: PackedVector2Array = _roads.get(STREET_ID, PackedVector2Array())
	var painted_half := 1.5
	for fragment: String in ["inn", "cottage_b"]:
		var fp := _fp_named(fragment)
		assert_false(fp.is_empty(), "%s has an apron footprint" % fragment)
		if fp.is_empty():
			continue
		var band := _rect((fp["centre"] as Vector2), (fp["half"] as Vector2), float(fp["yaw"]), painted_half)
		for i in range(street.size() - 1):
			var poly := Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([street[i], street[i + 1]]), band)
			assert_true(poly.is_empty(),
				"the %s footprint (with a %.1f m street half-width) clips the main street" % [fragment, painted_half])


## --- people and markers ------------------------------------------------------

func _people() -> Array:
	var out: Array = []
	for raw: Variant in (_json(NPCS_PATH).get("villagers", []) as Array):
		var v := raw as Dictionary
		var p := _v(v.get("position", [0, 0]))
		if VILLAGE_BOX.has_point(p):
			out.append({"name": str(v.get("name", "")), "at": p, "moved": str(v.get("name", "")) in MOVED_PEOPLE})
	for raw: Variant in (_json(TRAINERS_PATH).get("trainers", []) as Array):
		var t := raw as Dictionary
		var p := _v(t.get("position", [0, 0]))
		if VILLAGE_BOX.has_point(p):
			out.append({"name": "trainer:%s" % str(t.get("id", "")), "at": p,
				"moved": str(t.get("id", "")) in MOVED_TRAINER_IDS})
	return out


func _beacons(node: Variant, out: Array) -> void:
	if node is Dictionary:
		var beacon: Variant = (node as Dictionary).get("beacon", null)
		if beacon is Dictionary and (beacon as Dictionary).has("position"):
			out.append({"id": str((node as Dictionary).get("id", "")), "name": str((beacon as Dictionary).get("display_name", "")),
				"at": _v((beacon as Dictionary)["position"])})
		for value: Variant in (node as Dictionary).values():
			_beacons(value, out)
	elif node is Array:
		for value: Variant in (node as Array):
			_beacons(value, out)


func _footprint_containing(p: Vector2) -> Dictionary:
	for fp: Variant in _footprints:
		if _is_well(fp as Dictionary):
			continue
		if Geometry2D.is_point_in_polygon(p, (fp as Dictionary)["poly"] as PackedVector2Array):
			return fp as Dictionary
	return {}


func test_every_villager_and_trainer_is_outside_buildings_and_reachable() -> void:
	var people := _people()
	assert_true(people.size() >= 6, "the village roster is found (%d)" % people.size())
	for person: Variant in people:
		var who := person as Dictionary
		var at := who["at"] as Vector2
		var inside := _footprint_containing(at)
		var name := str(who["name"])
		if name in INTERIOR_PEOPLE:
			assert_false(inside.is_empty(), "%s stands inside the building he keeps" % name)
		else:
			assert_true(inside.is_empty(), "%s at %s stands inside a building footprint" % [name, str(at)])
		if not inside.is_empty():
			continue
		var limit := MOVED_REACH_M if bool(who["moved"]) else FIXED_REACH_M
		assert_true(_reach(at) <= limit,
			"%s at %s is %.1f m from a road or the green (max %.1f m)" % [name, str(at), _reach(at), limit])


func test_bram_moved_with_the_inn_and_his_door_meets_the_green() -> void:
	var inn := _structure("inn")
	var inn_at := _v(inn.get("at", []))
	var bram := Vector2.ZERO
	for p: Variant in _people():
		if str((p as Dictionary)["name"]) == "Bram":
			bram = (p as Dictionary)["at"]
	# inn_interior.gd::bar_position() is local (0,0,-4.39): under yaw 90 that is 4.39 m west of the inn centre.
	assert_almost_eq(bram.distance_to(inn_at), 4.39, 0.05, "Bram stands at the moved inn's bar")
	var step := _v(_doorstep_near(inn_at).get("at", [0, 0]))
	assert_true(_dist_to_green(step) <= MOVED_REACH_M, "the inn door opens onto the green (%.1f m)" % _dist_to_green(step))


func test_every_village_beacon_is_outside_buildings_and_reachable() -> void:
	var beacons: Array = []
	_beacons(_json(OBJECTIVES_PATH), beacons)
	var checked := 0
	for raw: Variant in beacons:
		var b := raw as Dictionary
		var at := b["at"] as Vector2
		if not VILLAGE_BOX.has_point(at):
			continue
		checked += 1
		var inside := _footprint_containing(at)
		if not inside.is_empty():
			assert_true(str(b["name"]) in INTERIOR_BEACON_NAMES,
				"objective %s: the beacon '%s' at %s sits inside a building footprint" % [b["id"], b["name"], str(at)])
			continue
		assert_true(_reach(at) <= FIXED_REACH_M,
			"objective %s: beacon '%s' at %s is %.1f m from a road or the green" % [b["id"], b["name"], str(at), _reach(at)])
	assert_true(checked >= 5, "village beacons were found (%d)" % checked)
	# No beacon points at a thing this change moved: the well, the inn, Bram or the stone cottage.
	for raw: Variant in beacons:
		var b := raw as Dictionary
		var label := (str(b["name"]) + " " + str(b["id"])).to_lower()
		for moved: String in ["well", "inn", "bram", "stone cottage"]:
			assert_false(label.contains(moved),
				"objective %s names %s; a marker on a moved thing must be re-pointed and pinned here" % [b["id"], moved])


## --- connectivity ------------------------------------------------------------

func _joined(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	for p: Vector2 in [a[0], a[a.size() - 1]]:
		if _dist_to_line(p, b) <= JOIN_TOLERANCE_M:
			return true
	for p: Vector2 in [b[0], b[b.size() - 1]]:
		if _dist_to_line(p, a) <= JOIN_TOLERANCE_M:
			return true
	return false


func _component(seed_id: String) -> Dictionary:
	var seen := {seed_id: true}
	var queue: Array[String] = [seed_id]
	while not queue.is_empty():
		var cur: String = queue.pop_back()
		for other: String in _roads:
			if seen.has(other):
				continue
			if _joined(_roads[cur] as PackedVector2Array, _roads[other] as PackedVector2Array):
				seen[other] = true
				queue.append(other)
	return seen


func test_every_exit_stays_connected_to_the_main_street() -> void:
	var reach := _component(STREET_ID)
	for id: String in ["village_pond_leg", "village_rise_leg", "village_stoneyard_lane", "village_berry_lane",
			"village_south_street", "band1_lower_meadows", "Grandpa's House", "The Inn", "village_green_walk"]:
		assert_true(_roads.has(id), "%s is a road" % id)
		assert_true(reach.has(id), "%s is connected to the main street (1.5 m join)" % id)
	# The exits themselves: the fence exits keep their old ends, all reachable from Grandpa's door.
	for pair: Array in [
			["village_pond_leg", Vector2(-21.0, 21.0)],
			["village_rise_leg", Vector2(38.72, -19.85)],
			["village_stoneyard_lane", Vector2(14.6, -31.0)]]:
		var line: PackedVector2Array = _roads[pair[0]]
		var end := line[line.size() - 1]
		assert_true(end.distance_to(pair[1] as Vector2) <= 0.01, "%s keeps its exit at %s" % [pair[0], str(pair[1])])
	var berry: PackedVector2Array = _roads["village_berry_lane"]
	assert_true(berry[berry.size() - 1].distance_to(Vector2(-7.2, -20.5)) <= 2.5, "Berry Lane still ends in the berry field")
	var grandpa: PackedVector2Array = _roads["Grandpa's House"]
	assert_true(grandpa[grandpa.size() - 1].distance_to(Vector2(-16.5, -16.0)) <= 0.01, "Grandpa's door end is unchanged")


func test_the_trail_gate_is_reached_over_village_roads() -> void:
	# TrailGate is the fence leaf the band-1 spine leaves through; the spine's
	# first leg must join the main street's road network, and the south street
	# must retrace it.
	var reach := _component(STREET_ID)
	assert_true(reach.has("band1_lower_meadows"), "the band-1 spine to TrailGate joins the main street network")
	var south: PackedVector2Array = _roads["village_south_street"]
	var end := south[south.size() - 1]
	assert_true(end.distance_to(Vector2(14.0, 20.0)) <= 0.01, "South Street meets the existing TrailGate waypoint")
