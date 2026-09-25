extends "res://tests/test_case.gd"

## ROADMAP F07 (ACCEPTANCE §6.1 F07, card C2, rule A7): a resource node is a
## preparation opportunity only if a traveller walking the chapter's roads can
## actually reach and notice it. Three gatherables used to sit 100-160 m out in
## the sky beside no route at all -- they added nothing to route cadence and the
## runtime quietly relocated them onto whichever road segment
## `cloudreach_world.gd::_resource_position` happened to rank nearest.
##
## Pure data: reads the chapter, world and visual JSON and never touches a
## SceneTree (`tests/run_tests.gd` runs from `SceneTree._init`).
##
## The corridor mirrors the route builder, not a guess:
## - a ground route segment's walkable ground is its cliff shoulder,
##   `maxf(route_shoulder_min_half_width_m, width_m * route_shoulder_path_multiplier)`
##   either side of the centreline (`_build_route_shoulders`);
## - a segment a bridge spans has no shoulder, only that bridge's deck,
##   `width_m * 0.5` either side (`_collect_all_route_lines`);
## - a Fly-only region has no ground route; its gatherables stand on the crown
##   of one of that region's landmarks.
## A node must also sit within `_resource_position`'s 45 m height tolerance of
## that surface, or the runtime discards its authored XZ and moves it.

const PATCH := preload("res://scripts/world/cloudreach_resource_patch.gd")
const WORLD_PATH := "res://data/config/cloudreach_world.json"
const VISUAL_PATH := "res://data/config/cloudreach_visual.json"

## Builder defaults when a route or bridge authors no width of its own.
const DEFAULT_ROUTE_WIDTH_M := 7.5
const DEFAULT_BRIDGE_WIDTH_M := 3.2
const CORRIDOR_MARGIN_M := 2.0
## `_resource_position` keeps the authored XZ only within this height of ground.
const SNAP_HEIGHT_TOLERANCE_M := 45.0
## Conservative: every landmark ledge crown's flat radius is at least
## 0.47 * 44 m (`_collect_all_route_lines`), the Sky Shrine's far more.
const LANDMARK_CROWN_RADIUS_M := 20.0

## The F07 moves: each node now stands on the shoulder of one of the long,
## otherwise encounter-only stretches, beside (never on) the road ribbon.
const MOVED_NODES := {
	"cr_node_cliffglass_ravine": "windscar_counterweight_pass",
	"cr_node_cloudberry_cliffhold": "windscar_counterweight_pass",
	"cr_node_cliffglass_observatory": "upper_summit_road",
	"cr_node_cliffglass_summit": "summit_overlook_loop",
}
const MOVED_MAX_OFFSET_M := 8.0

var _chapter: Dictionary
var _world: Dictionary
var _visual: Dictionary


func before_each() -> void:
	_chapter = PATCH.load_config(PATCH.CHAPTER_PATH)
	_world = PATCH.load_config(WORLD_PATH)
	_visual = PATCH.load_config(VISUAL_PATH)


func test_every_gatherable_node_sits_in_a_walkable_route_corridor() -> void:
	var lines := _walkable_lines()
	assert_true(lines.size() > 20, "route network did not load")
	var nodes: Array[Dictionary] = PATCH.gatherable_nodes()
	assert_true(nodes.size() >= 10, "gatherable nodes did not load")
	for node: Dictionary in nodes:
		var id := str(node.get("id", ""))
		var at := _placed_position(node)
		var region := _region(str(node.get("region_id", "")))
		if str(region.get("access", {}).get("mode", "")) == "fly_only":
			assert_true(_on_region_landmark_crown(at, str(region.get("id", ""))),
				"%s at %s is on no landmark crown of its Fly-only region" % [id, at])
			continue
		var best := _nearest_line(at, lines)
		assert_true(bool(best.get("inside", false)),
			"%s at %s is %.1f m from %s (corridor %.1f m, height gap %.1f m)" % [
				id, at, float(best.get("distance", INF)), str(best.get("route_id", "none")),
				float(best.get("reach", 0.0)), float(best.get("dy", INF))])


func test_every_node_region_id_matches_the_bounds_that_contain_it() -> void:
	var legal := {}
	for raw: Variant in _chapter.get("resource_tier", {}).get("resources", []):
		legal[str((raw as Dictionary).get("id", ""))] = (raw as Dictionary).get("region_ids", [])
	for raw: Variant in _chapter.get("resource_tier", {}).get("nodes", []):
		var node := raw as Dictionary
		var id := str(node.get("id", ""))
		var region_id := str(node.get("region_id", ""))
		var at := _placed_position(node)
		var region := _region(region_id)
		assert_false(region.is_empty(), "%s names unknown region %s" % [id, region_id])
		assert_true(_inside_bounds(at, region.get("bounds", {})),
			"%s at %s lies outside %s's bounds" % [id, at, region_id])
		var habitats: Array = legal.get(str(node.get("resource_id", "")), [])
		assert_true(habitats.has(region_id),
			"%s places %s outside its resource habitat" % [id, str(node.get("resource_id", ""))])


func test_only_encounter_rewards_are_exempt_from_the_corridor() -> void:
	# The corridor test walks `gatherable_nodes()`; anything it skips must be a
	# creature drop that is never hand-placed in the world.
	var methods := {}
	for raw: Variant in _chapter.get("resource_tier", {}).get("resources", []):
		methods[str((raw as Dictionary).get("id", ""))] = str((raw as Dictionary).get("gather_method", ""))
	for raw: Variant in _chapter.get("resource_tier", {}).get("nodes", []):
		var node := raw as Dictionary
		if str(node.get("respawn_policy", "")) == "world_day_regrow":
			continue
		assert_eq(methods.get(str(node.get("resource_id", "")), ""), "encounter_reward",
			"%s is skipped by the corridor check but is not an encounter reward" % str(node.get("id", "")))


func test_far_nodes_stand_beside_the_road_on_the_long_empty_stretches() -> void:
	var road_half_width := float(_landmass().get("path_collision_width_m", 7.0)) * 0.5
	var found := 0
	for node: Dictionary in PATCH.gatherable_nodes():
		var id := str(node.get("id", ""))
		if not MOVED_NODES.has(id):
			continue
		found += 1
		var route := _route(str(MOVED_NODES[id]))
		assert_false(route.is_empty(), "%s's route %s is missing" % [id, MOVED_NODES[id]])
		var best := {"distance": INF}
		var points: Array = route.get("polyline", [])
		for i in points.size() - 1:
			var hit := _segment_hit(_placed_position(node), _vec(points[i]), _vec(points[i + 1]))
			if float(hit["distance"]) < float(best["distance"]):
				best = hit
		var distance := float(best["distance"])
		assert_true(distance > road_half_width,
			"%s blocks the %s road ribbon (%.1f m off centre)" % [id, MOVED_NODES[id], distance])
		assert_true(distance <= MOVED_MAX_OFFSET_M,
			"%s drifted %.1f m off %s" % [id, distance, MOVED_NODES[id]])
		assert_true(absf(float(best["dy"])) <= 3.0,
			"%s is %.1f m off %s's road height" % [id, float(best["dy"]), MOVED_NODES[id]])
	assert_eq(found, MOVED_NODES.size(), "an F07 node is no longer a gatherable")


# -- helpers ---------------------------------------------------------------


## Every walkable centreline with how far either side of it counts as reachable.
func _walkable_lines() -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	var bridge_points := {}
	for raw: Variant in _world.get("bridges", []):
		var bridge := raw as Dictionary
		var route_id := str(bridge.get("route_id", ""))
		var profile: Array = bridge.get("deck_profile", bridge.get("endpoints", []))
		var reach := float(bridge.get("width_m", DEFAULT_BRIDGE_WIDTH_M)) * 0.5 + CORRIDOR_MARGIN_M
		if not bridge_points.has(route_id):
			bridge_points[route_id] = []
		for i in profile.size():
			(bridge_points[route_id] as Array).append(_vec(profile[i]))
			if i + 1 < profile.size():
				lines.append({"route_id": "bridge:" + str(bridge.get("id", "")),
					"a": _vec(profile[i]), "b": _vec(profile[i + 1]), "reach": reach})
	var landmass := _landmass()
	for raw: Variant in _world.get("routes", []):
		var route := raw as Dictionary
		if str(route.get("traversal_mode", "")) != "ground":
			continue
		var route_id := str(route.get("id", ""))
		var width := float(route.get("width_m", DEFAULT_ROUTE_WIDTH_M))
		var shoulder := maxf(float(landmass.get("route_shoulder_min_half_width_m", 24.0)),
			width * float(landmass.get("route_shoulder_path_multiplier", 3.8)))
		var points: Array = route.get("polyline", [])
		for i in points.size() - 1:
			var a := _vec(points[i])
			var b := _vec(points[i + 1])
			var decked: Array = bridge_points.get(route_id, [])
			if _has_point(decked, a) and _has_point(decked, b):
				continue # A bridge span: sky either side of the deck, no shoulder.
			lines.append({"route_id": route_id, "a": a, "b": b, "reach": shoulder + CORRIDOR_MARGIN_M})
	return lines


func _nearest_line(at: Vector3, lines: Array[Dictionary]) -> Dictionary:
	var best := {"distance": INF, "inside": false}
	for line: Dictionary in lines:
		var hit := _segment_hit(at, line["a"], line["b"])
		var inside: bool = float(hit["distance"]) <= float(line["reach"]) \
			and absf(float(hit["dy"])) <= SNAP_HEIGHT_TOLERANCE_M
		# Prefer any line that contains the node; otherwise report the closest.
		if (inside and not bool(best["inside"])) or (inside == bool(best["inside"])
				and float(hit["distance"]) < float(best["distance"])):
			best = {"distance": hit["distance"], "dy": hit["dy"], "inside": inside,
				"route_id": line["route_id"], "reach": line["reach"]}
	return best


## Horizontal distance from `at` to segment a-b, and `at`'s height above the
## segment's own centreline height at that point.
func _segment_hit(at: Vector3, a: Vector3, b: Vector3) -> Dictionary:
	var flat := Vector2(b.x - a.x, b.z - a.z)
	var t := 0.0
	if flat.length_squared() > 0.0001:
		t = clampf(Vector2(at.x - a.x, at.z - a.z).dot(flat) / flat.length_squared(), 0.0, 1.0)
	var centre := a.lerp(b, t)
	return {"distance": Vector2(at.x - centre.x, at.z - centre.z).length(), "dy": at.y - centre.y}


func _on_region_landmark_crown(at: Vector3, region_id: String) -> bool:
	for raw: Variant in _world.get("landmarks", []):
		var landmark := raw as Dictionary
		if str(landmark.get("region_id", "")) != region_id:
			continue
		var centre := _vec(landmark.get("position", []))
		if Vector2(at.x - centre.x, at.z - centre.z).length() <= LANDMARK_CROWN_RADIUS_M \
				and absf(at.y - centre.y) <= SNAP_HEIGHT_TOLERANCE_M:
			return true
	return false


## Where the world actually builds the node: `cloudreach_visual.json`'s
## `resource_positions` override wins over the chapter's authored position.
func _placed_position(node: Dictionary) -> Vector3:
	var override: Variant = _visual.get("resource_positions", {}).get(str(node.get("id", "")))
	return _vec(override if override is Array else node.get("position", []))


func _inside_bounds(at: Vector3, bounds: Dictionary) -> bool:
	return at.x >= float(bounds.get("min_x", INF)) and at.x <= float(bounds.get("max_x", -INF)) \
		and at.y >= float(bounds.get("min_y", INF)) and at.y <= float(bounds.get("max_y", -INF)) \
		and at.z >= float(bounds.get("min_z", INF)) and at.z <= float(bounds.get("max_z", -INF))


func _has_point(points: Array, at: Vector3) -> bool:
	for point: Vector3 in points:
		if point.distance_to(at) < 0.5:
			return true
	return false


func _region(id: String) -> Dictionary:
	for raw: Variant in _world.get("regions", []):
		if str((raw as Dictionary).get("id", "")) == id:
			return raw
	return {}


func _route(id: String) -> Dictionary:
	for raw: Variant in _world.get("routes", []):
		if str((raw as Dictionary).get("id", "")) == id:
			return raw
	return {}


func _landmass() -> Dictionary:
	return _visual.get("landmass", {})


func _vec(raw: Variant) -> Vector3:
	var values: Array = raw if raw is Array else []
	if values.size() != 3:
		return Vector3.INF
	return Vector3(float(values[0]), float(values[1]), float(values[2]))
