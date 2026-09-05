extends "res://tests/test_case.gd"

## Pure-data contract for Cloudreach's Phase 2 authored macro layout.
##
## Runtime terrain, collisions and actual traversal remain smoke-test work. This
## suite makes the intended chapter shape machine-checkable before builders and
## loaders consume it: six canonical regions, a large 3D extent, valid authored
## positions, landmarks in every region, explicit bridges/transitions, and a
## grounded route graph that cannot quietly turn the Fly-only High Roost into a
## walking shortcut.

const CONFIG_PATH := "res://data/config/cloudreach_world.json"
const EXPECTED_REGION_IDS := [
	"gate_lower_cliffs",
	"broken_causeways",
	"windscar_ravine",
	"high_roost_sky_shrine",
	"upper_cloudreach",
	"summit_final_stronghold",
]
const EARLY_GROUND_REGIONS := [
	"gate_lower_cliffs",
	"broken_causeways",
	"windscar_ravine",
]
const LATE_GROUND_REGIONS := [
	"upper_cloudreach",
	"summit_final_stronghold",
]
const FLY_REGION := "high_roost_sky_shrine"
const FLY_UNLOCK := "fly_traversal_unlocked"
const UPPER_UNLOCK := "cloudreach_upper_route_unlocked"

var _cached_config: Dictionary = {}


func _config() -> Dictionary:
	if not _cached_config.is_empty():
		return _cached_config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_cached_config = parsed as Dictionary
	return _cached_config


func _list(key: String) -> Array:
	var value: Variant = _config().get(key, [])
	if value is Array:
		return value as Array
	return []


func _entry(entries: Array, id: String) -> Dictionary:
	for candidate: Variant in entries:
		if candidate is Dictionary and str((candidate as Dictionary).get("id", "")) == id:
			return candidate as Dictionary
	return {}


func _world_bounds() -> Dictionary:
	var realm: Dictionary = _config().get("realm", {})
	return realm.get("world_bounds", {}) as Dictionary


func _is_point(value: Variant) -> bool:
	return value is Array and (value as Array).size() == 3


func _inside(point: Array, bounds: Dictionary) -> bool:
	if point.size() != 3:
		return false
	return (
		float(point[0]) >= float(bounds.get("min_x", INF))
		and float(point[0]) <= float(bounds.get("max_x", -INF))
		and float(point[1]) >= float(bounds.get("min_y", INF))
		and float(point[1]) <= float(bounds.get("max_y", -INF))
		and float(point[2]) >= float(bounds.get("min_z", INF))
		and float(point[2]) <= float(bounds.get("max_z", -INF))
	)


func _region_ids() -> Array[String]:
	var out: Array[String] = []
	for value: Variant in _list("regions"):
		if value is Dictionary:
			out.append(str((value as Dictionary).get("id", "")))
	return out


func _route_length(route: Dictionary) -> float:
	var points: Array = route.get("polyline", [])
	var total := 0.0
	for index in range(1, points.size()):
		if not _is_point(points[index - 1]) or not _is_point(points[index]):
			continue
		var previous: Array = points[index - 1]
		var current: Array = points[index]
		total += Vector3(float(previous[0]), float(previous[1]), float(previous[2])).distance_to(
			Vector3(float(current[0]), float(current[1]), float(current[2])))
	return total


func _ground_reachable(enabled_unlocks: Array[String]) -> Array[String]:
	var reached: Array[String] = ["gate_lower_cliffs"]
	var changed := true
	while changed:
		changed = false
		for value: Variant in _list("routes"):
			var route := value as Dictionary
			if str(route.get("traversal_mode", "")) != "ground":
				continue
			var required := str(route.get("requires_unlock", ""))
			if not required.is_empty() and not enabled_unlocks.has(required):
				continue
			var from_id := str(route.get("from_region_id", ""))
			var to_id := str(route.get("to_region_id", ""))
			if reached.has(from_id) and not reached.has(to_id):
				reached.append(to_id)
				changed = true
			if bool(route.get("bidirectional", false)) and reached.has(to_id) and not reached.has(from_id):
				reached.append(from_id)
				changed = true
	return reached


func test_config_is_readable_and_identifies_cloudreach() -> void:
	assert_false(_config().is_empty(), "%s is missing or invalid JSON" % CONFIG_PATH)
	assert_eq(int(_config().get("schema_version", 0)), 1, "loader schema changed without a migration")
	var realm: Dictionary = _config().get("realm", {})
	assert_eq(str(realm.get("id", "")), "cloudreach_cliffs")
	assert_eq(str(realm.get("display_name", "")), "Cloudreach Cliffs")
	assert_eq(str(realm.get("grounded_unlock_id", "")), UPPER_UNLOCK)


func test_exact_six_directive_regions_are_authored_in_order() -> void:
	assert_eq(_region_ids(), EXPECTED_REGION_IDS,
		"the directive's six-region chapter order is part of the world-data contract")
	for index in EXPECTED_REGION_IDS.size():
		var region := _entry(_list("regions"), EXPECTED_REGION_IDS[index])
		assert_eq(int(region.get("order", 0)), index + 1,
			"region '%s' has drifted out of chapter order" % EXPECTED_REGION_IDS[index])
		assert_false(str(region.get("display_name", "")).is_empty(),
			"region '%s' has no player-facing name" % EXPECTED_REGION_IDS[index])


func test_authored_extent_is_large_and_vertical_enough_for_a_real_chapter() -> void:
	var bounds := _world_bounds()
	var width := float(bounds.get("max_x", 0.0)) - float(bounds.get("min_x", 0.0))
	var depth := float(bounds.get("max_z", 0.0)) - float(bounds.get("min_z", 0.0))
	var height := float(bounds.get("max_y", 0.0)) - float(bounds.get("min_y", 0.0))
	assert_true(width >= 3000.0, "%.0fm-wide Cloudreach would be a showcase, not a chapter" % width)
	assert_true(depth >= 6000.0, "%.0fm-deep Cloudreach would be a showcase, not a chapter" % depth)
	assert_true(height >= 1500.0, "%.0fm of vertical extent cannot sell the directive's scale" % height)
	var spine_length := 0.0
	for id in ["lower_cliff_road", "broken_causeway_main", "windscar_counterweight_pass", "upper_summit_road"]:
		spine_length += _route_length(_entry(_list("routes"), id))
	assert_true(spine_length >= 5000.0,
		"the authored grounded chapter spine is only %.0fm long" % spine_length)


func test_region_positions_and_bounds_are_valid_and_inside_the_realm() -> void:
	var world := _world_bounds()
	for value: Variant in _list("regions"):
		var region := value as Dictionary
		var id := str(region.get("id", "?"))
		var bounds: Dictionary = region.get("bounds", {})
		assert_true(
			float(bounds.get("min_x", 0.0)) < float(bounds.get("max_x", 0.0))
			and float(bounds.get("min_y", 0.0)) < float(bounds.get("max_y", 0.0))
			and float(bounds.get("min_z", 0.0)) < float(bounds.get("max_z", 0.0)),
			"region '%s' has inverted or empty bounds" % id)
		for axis in ["x", "y", "z"]:
			assert_true(
				float(bounds.get("min_%s" % axis, INF)) >= float(world.get("min_%s" % axis, -INF))
				and float(bounds.get("max_%s" % axis, -INF)) <= float(world.get("max_%s" % axis, INF)),
				"region '%s' escapes the realm on %s" % [id, axis])
		var position: Variant = region.get("position", [])
		assert_true(_is_point(position), "region '%s' needs a 3D [x, y, z] position" % id)
		if _is_point(position):
			assert_true(_inside(position as Array, bounds), "region '%s' position is outside its bounds" % id)


func test_landmark_ids_are_unique_and_every_region_has_a_valid_landmark() -> void:
	var seen: Array[String] = []
	var counts: Dictionary = {}
	for value: Variant in _list("landmarks"):
		var landmark := value as Dictionary
		var id := str(landmark.get("id", ""))
		var region_id := str(landmark.get("region_id", ""))
		assert_false(id.is_empty(), "a landmark has no id")
		assert_false(seen.has(id), "landmark id '%s' is duplicated" % id)
		seen.append(id)
		var region := _entry(_list("regions"), region_id)
		assert_false(region.is_empty(), "landmark '%s' names unknown region '%s'" % [id, region_id])
		var position: Variant = landmark.get("position", [])
		assert_true(_is_point(position), "landmark '%s' needs a 3D [x, y, z] position" % id)
		if _is_point(position) and not region.is_empty():
			assert_true(_inside(position as Array, region.get("bounds", {}) as Dictionary),
				"landmark '%s' is outside its authored region" % id)
		counts[region_id] = int(counts.get(region_id, 0)) + 1
	for region_id in EXPECTED_REGION_IDS:
		assert_true(int(counts.get(region_id, 0)) >= 1,
			"region '%s' has no recognizable landmark" % region_id)


func test_routes_reference_regions_and_keep_every_authored_point_in_bounds() -> void:
	var region_ids := _region_ids()
	var valid_modes := ["ground", "fly"]
	for value: Variant in _list("routes"):
		var route := value as Dictionary
		var id := str(route.get("id", "?"))
		var from_id := str(route.get("from_region_id", ""))
		var to_id := str(route.get("to_region_id", ""))
		assert_true(region_ids.has(from_id), "route '%s' has unknown source '%s'" % [id, from_id])
		assert_true(region_ids.has(to_id), "route '%s' has unknown destination '%s'" % [id, to_id])
		assert_true(valid_modes.has(str(route.get("traversal_mode", ""))),
			"route '%s' has no supported traversal mode" % id)
		var points: Array = route.get("polyline", [])
		assert_true(points.size() >= 2, "route '%s' has no authored path" % id)
		for point: Variant in points:
			assert_true(_is_point(point), "route '%s' has a non-3D path point" % id)
			if _is_point(point):
				assert_true(_inside(point as Array, _world_bounds()),
					"route '%s' has a path point outside Cloudreach" % id)
		if points.size() >= 2 and region_ids.has(from_id) and region_ids.has(to_id):
			assert_true(_inside(points[0] as Array, (_entry(_list("regions"), from_id).get("bounds", {}) as Dictionary)),
				"route '%s' does not start in its source region" % id)
			assert_true(_inside(points[-1] as Array, (_entry(_list("regions"), to_id).get("bounds", {}) as Dictionary)),
				"route '%s' does not finish in its destination region" % id)


func test_bridges_are_authored_on_real_routes_with_measured_spans() -> void:
	var route_ids: Array[String] = []
	var bridge_ids: Array[String] = []
	for value: Variant in _list("routes"):
		route_ids.append(str((value as Dictionary).get("id", "")))
	assert_true(_list("bridges").size() >= 5, "Cloudreach needs a bridge network, not one token bridge")
	for value: Variant in _list("bridges"):
		var bridge := value as Dictionary
		var id := str(bridge.get("id", ""))
		assert_false(id.is_empty(), "a bridge has no id")
		assert_false(bridge_ids.has(id), "bridge id '%s' is duplicated" % id)
		bridge_ids.append(id)
		assert_true(route_ids.has(str(bridge.get("route_id", ""))),
			"bridge '%s' is not attached to an authored route" % id)
		assert_true(float(bridge.get("width_m", 0.0)) >= 3.0, "bridge '%s' is not player-safe width" % id)
		var endpoints: Array = bridge.get("endpoints", [])
		assert_eq(endpoints.size(), 2, "bridge '%s' needs two endpoints" % id)
		if endpoints.size() != 2 or not _is_point(endpoints[0]) or not _is_point(endpoints[1]):
			continue
		var a: Array = endpoints[0]
		var b: Array = endpoints[1]
		var measured := Vector3(float(a[0]), float(a[1]), float(a[2])).distance_to(
			Vector3(float(b[0]), float(b[1]), float(b[2])))
		assert_almost_eq(float(bridge.get("length_m", 0.0)), measured, 2.0,
			"bridge '%s' length does not match its authored endpoints" % id)


func test_meadows_entry_and_return_points_are_explicit_and_safe() -> void:
	var transitions: Dictionary = _config().get("transition_points", {})
	for key in ["meadows_entry", "meadows_return"]:
		assert_true(transitions.has(key), "Cloudreach has no '%s' transition point" % key)
		var point: Dictionary = transitions.get(key, {})
		assert_eq(str(point.get("region_id", "")), "gate_lower_cliffs")
		assert_eq(str(point.get("peer_realm_id", "")), "meadows")
		assert_false(str(point.get("peer_anchor_id", "")).is_empty(),
			"transition '%s' cannot resolve its Meadows endpoint" % key)
		assert_true(bool(point.get("save_anchor", false)),
			"transition '%s' is not safe to persist" % key)
		var position: Variant = point.get("position", [])
		assert_true(_is_point(position), "transition '%s' has no 3D point" % key)
		if _is_point(position):
			assert_true(_inside(position as Array, (_entry(_list("regions"), "gate_lower_cliffs").get("bounds", {}) as Dictionary)),
				"transition '%s' is outside the entry region" % key)
	var entry: Dictionary = transitions.get("meadows_entry", {})
	var returning: Dictionary = transitions.get("meadows_return", {})
	assert_eq(str(entry.get("role", "")), "entry_from_meadows")
	assert_eq(str(entry.get("requires_flag", "")), "realm_key_cloudreach")
	assert_eq(str(returning.get("role", "")), "return_to_meadows")
	assert_eq(str(returning.get("requires_flag", "")), "",
		"returning to Meadows must not introduce a new lock")


func test_high_roost_is_visible_early_but_fly_only() -> void:
	var roost := _entry(_list("regions"), FLY_REGION)
	var access: Dictionary = roost.get("access", {})
	assert_eq(str(access.get("mode", "")), "fly_only")
	assert_eq(str(access.get("requires_unlock", "")), FLY_UNLOCK)
	assert_true(bool(access.get("blocks_ground_route", false)))
	var visible_from: Array = access.get("visible_from_region_ids", [])
	assert_true(visible_from.has("broken_causeways"), "High Roost is not foreshadowed from the Causeways")
	assert_true(visible_from.has("windscar_ravine"), "High Roost is not visible before the Fly crossing")
	var shrine := _entry(_list("landmarks"), "sky_shrine_heartstone")
	assert_eq(str(shrine.get("region_id", "")), FLY_REGION)
	assert_eq(str(shrine.get("requires_traversal", "")), "fly")
	assert_eq(str(shrine.get("requires_unlock", "")), FLY_UNLOCK)


func test_fly_route_and_gate_protect_high_roost() -> void:
	var fly_routes: Array[Dictionary] = []
	for value: Variant in _list("routes"):
		var route := value as Dictionary
		if str(route.get("from_region_id", "")) == FLY_REGION or str(route.get("to_region_id", "")) == FLY_REGION:
			fly_routes.append(route)
	assert_eq(fly_routes.size(), 1, "High Roost needs one intentional access route, not accidental graph edges")
	if not fly_routes.is_empty():
		assert_eq(str(fly_routes[0].get("traversal_mode", "")), "fly")
		assert_eq(str(fly_routes[0].get("requires_unlock", "")), FLY_UNLOCK)
	var gate := _entry(_list("gates"), "high_roost_fly_gate")
	assert_eq(str(gate.get("required_traversal", "")), "fly")
	assert_eq(str(gate.get("requires_unlock", "")), FLY_UNLOCK)
	assert_true((gate.get("protects_region_ids", []) as Array).has(FLY_REGION))


func test_ground_graph_stops_at_windscar_before_the_authored_unlock() -> void:
	var reached := _ground_reachable([])
	for region_id in EARLY_GROUND_REGIONS:
		assert_true(reached.has(region_id), "open ground graph cannot reach '%s'" % region_id)
	assert_false(reached.has(FLY_REGION), "High Roost leaked into the grounded graph")
	for region_id in LATE_GROUND_REGIONS:
		assert_false(reached.has(region_id),
			"'%s' is reachable on foot before the Sky Shrine unlock" % region_id)


func test_authored_unlock_connects_upper_and_summit_without_using_high_roost_as_a_road() -> void:
	var reached := _ground_reachable([UPPER_UNLOCK])
	for region_id in EARLY_GROUND_REGIONS + LATE_GROUND_REGIONS:
		assert_true(reached.has(region_id), "unlocked ground graph cannot reach '%s'" % region_id)
	assert_false(reached.has(FLY_REGION), "High Roost became a walking shortcut after the upper route unlocked")
	var crossings := 0
	for value: Variant in _list("routes"):
		var route := value as Dictionary
		if str(route.get("traversal_mode", "")) != "ground":
			continue
		var from_id := str(route.get("from_region_id", ""))
		var to_id := str(route.get("to_region_id", ""))
		assert_true(from_id != FLY_REGION and to_id != FLY_REGION,
			"ground route '%s' turns the Fly-only region into a road" % str(route.get("id", "?")))
		var crosses_gate: bool = (
			(EARLY_GROUND_REGIONS.has(from_id) and LATE_GROUND_REGIONS.has(to_id))
			or (EARLY_GROUND_REGIONS.has(to_id) and LATE_GROUND_REGIONS.has(from_id))
		)
		if crosses_gate:
			crossings += 1
			assert_eq(str(route.get("requires_unlock", "")), UPPER_UNLOCK,
				"early-to-late ground crossing bypasses the authored unlock")
	assert_eq(crossings, 1, "the upper route should have one legible, authored ground gate")


func test_sky_shrine_authors_the_upper_route_unlock() -> void:
	var upper_unlock := _entry(_list("unlocks"), UPPER_UNLOCK)
	assert_false(upper_unlock.is_empty(), "upper route flag has no authored unlock source")
	assert_eq(str(upper_unlock.get("granted_at_landmark_id", "")), "sky_shrine_heartstone")
	var shrine := _entry(_list("landmarks"), "sky_shrine_heartstone")
	assert_eq(str(shrine.get("region_id", "")), FLY_REGION)
	assert_eq(str(shrine.get("requires_traversal", "")), "fly",
		"the upper-route unlock no longer preserves the mid-chapter Fly gate")
	var counterweight := _entry(_list("gates"), "upper_counterweight_gate")
	assert_eq(str(counterweight.get("requires_unlock", "")), UPPER_UNLOCK)
	assert_eq(counterweight.get("protects_region_ids", []), LATE_GROUND_REGIONS)
