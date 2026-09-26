extends "res://tests/test_case.gd"

## ROADMAP F07 (ACCEPTANCE §6.1 F07, card C2, rule A7): a resource node is a
## preparation opportunity only if a traveller on the chapter's roads reaches
## and notices it where it was authored. Four gatherables (ravine, cliffhold,
## observatory and summit) used to sit 100-160 m out in the sky beside no road.
## At runtime `cloudreach_world.gd::_resource_position` silently re-homed them
## onto whichever road segment its snap rule ranked nearest -- for the ravine
## ore, a rope-bridge deck the data never named.
##
## Pure data: reads the chapter, world, visual and recipe JSON and never
## touches a SceneTree (`tests/run_tests.gd` runs from `SceneTree._init`).
##
## This file ports the two runtime rules the placement depends on and asserts
## the RESOLVED position:
## - `_surfaces`, as registered before `_build_resource_patches` runs in the
##   solo build: region crown ellipses, transition ledges, route landing pads,
##   road collision ribbons (cut around bridges, joined to the pad edges),
##   bridge decks, landmark crowns and the Stormward steps;
## - `_resource_position`: `ground_height_near` (the containing surface whose
##   height is closest to the authored Y) keeps the authored XZ when that height
##   is within 45 m; otherwise the node snaps to the nearest road/deck segment
##   at a fixed sideways offset.
## Every gatherable must be KEPT (never snapped) and its authored Y must match
## the kept surface, so a floating or buried authored Y fails here.

const PATCH := preload("res://scripts/world/cloudreach_resource_patch.gd")
const WORLD_PATH := "res://data/config/cloudreach_world.json"
const VISUAL_PATH := "res://data/config/cloudreach_visual.json"
const RECIPES_PATH := "res://data/recipes/recipes_cloudreach.json"

## `_resource_position` constants.
const KEEP_HEIGHT_M := 45.0
const LIFT_M := 0.06
const SNAP_T_MIN := 0.06
const SNAP_T_MAX := 0.94
const SNAP_SIDEWAYS_MAX_M := 2.6
const SNAP_HEIGHT_WEIGHT := 5.0
## Authored Y may differ from the surface it is kept on by at most this.
const AUTHORED_Y_TOLERANCE_M := 1.0
## `path_visible_width_m` 4.2 -> the drawn trail's half-width.
const TRAIL_HALF_WIDTH_M := 2.1

## The F07 moves. Each stands on its road's collision ribbon, just outside the
## drawn trail, on a stretch that previously offered no preparation.
const MOVED_NODES := {
	"cr_node_cliffglass_ravine": "windscar_floor_loop",
	"cr_node_cloudberry_cliffhold": "windscar_counterweight_pass",
	"cr_node_cliffglass_observatory": "upper_summit_road",
	"cr_node_cliffglass_summit": "summit_overlook_loop",
}

var _chapter: Dictionary
var _world: Dictionary
var _visual: Dictionary
var _surfaces: Array[Dictionary] = []


func before_each() -> void:
	_chapter = PATCH.load_config(PATCH.CHAPTER_PATH)
	_world = PATCH.load_config(WORLD_PATH)
	_visual = PATCH.load_config(VISUAL_PATH)
	_surfaces = _build_surfaces()


func test_every_gatherable_node_is_kept_where_it_is_authored() -> void:
	assert_true(_surfaces.size() > 60, "surface model did not load")
	var nodes: Array[Dictionary] = PATCH.gatherable_nodes()
	assert_true(nodes.size() >= 10, "gatherable nodes did not load")
	for node: Dictionary in nodes:
		var id := str(node.get("id", ""))
		var authored := _placed_position(node)
		var resolved := _resolve(authored)
		assert_true(bool(resolved["kept"]),
			"%s at %s has no ground; the runtime snaps it %.1f m to %s" % [
				id, authored, _flat_distance(authored, resolved["position"]),
				str(resolved["surface"].get("source", "?"))])
		if bool(resolved["kept"]):
			var gap := (resolved["position"] as Vector3).y - LIFT_M - authored.y
			assert_true(absf(gap) <= AUTHORED_Y_TOLERANCE_M,
				"%s authored Y %.1f is %.1f m off the %s surface it stands on" % [
					id, authored.y, gap, str(resolved["surface"].get("source", "?"))])


func test_f07_nodes_stand_on_their_road_at_the_trail_verge() -> void:
	var found := 0
	for node: Dictionary in PATCH.gatherable_nodes():
		var id := str(node.get("id", ""))
		if not MOVED_NODES.has(id):
			continue
		found += 1
		var route_id := str(MOVED_NODES[id])
		var resolved := _resolve(_placed_position(node))
		var surface: Dictionary = resolved["surface"]
		assert_true(bool(resolved["kept"]), "%s is snapped, not kept" % id)
		assert_eq(str(surface.get("source", "")), "road:" + route_id, id + " left its road")
		var offset := _segment_distance(resolved["position"], surface["a"], surface["b"])
		assert_true(offset > TRAIL_HALF_WIDTH_M and offset <= float(surface["half_width"]),
			"%s is %.1f m off %s's centreline, not at the trail verge" % [id, offset, route_id])
	assert_eq(found, MOVED_NODES.size(), "an F07 node is no longer a gatherable")


func test_chapter_start_recipes_find_their_ingredients_on_ungated_ground() -> void:
	# A recipe unlocked at chapter start must be craftable before any story
	# unlock wherever the resource tier says the ingredient grows on ungated
	# ground. Ingredients whose habitats are all gated (sunleaf: High Roost and
	# Upper Cloudreach) wait by design; encounter rewards come from creatures.
	var resources := {}
	for raw: Variant in _chapter.get("resource_tier", {}).get("resources", []):
		resources[str((raw as Dictionary).get("id", ""))] = raw
	var ungated_sources := {}
	for node: Dictionary in PATCH.gatherable_nodes():
		var resolved := _resolve(_placed_position(node))
		if bool(resolved["kept"]) and str(resolved["surface"].get("gate", "?")).is_empty():
			ungated_sources[str(node.get("resource_id", ""))] = true
	var recipes: Dictionary = PATCH.load_config(RECIPES_PATH).get("recipes", {})
	var checked := 0
	for recipe_id: String in recipes:
		var recipe: Dictionary = recipes[recipe_id]
		if str(recipe.get("unlocked_by", "")) != "cloudreach_chapter_started":
			continue
		for raw: Variant in recipe.get("cost", []):
			var ingredient := str((raw as Dictionary).get("id", ""))
			if not resources.has(ingredient):
				continue
			var resource: Dictionary = resources[ingredient]
			if str(resource.get("gather_method", "")) == "encounter_reward" \
					or not _grows_on_ungated_ground(resource):
				continue
			checked += 1
			assert_true(ungated_sources.has(ingredient),
				"%s needs %s but every %s node is behind a story unlock" % [
					recipe_id, ingredient, ingredient])
	assert_true(checked >= 8, "no chapter-start recipe ingredients were checked")


func test_every_node_region_id_matches_the_bounds_that_contain_it() -> void:
	var legal := {}
	for raw: Variant in _chapter.get("resource_tier", {}).get("resources", []):
		legal[str((raw as Dictionary).get("id", ""))] = (raw as Dictionary).get("region_ids", [])
	for raw: Variant in _chapter.get("resource_tier", {}).get("nodes", []):
		var node := raw as Dictionary
		var id := str(node.get("id", ""))
		var region_id := str(node.get("region_id", ""))
		var at := _placed_position(node)
		var region := _find(_world.get("regions", []), region_id)
		assert_false(region.is_empty(), "%s names unknown region %s" % [id, region_id])
		assert_true(_inside_bounds(at, region.get("bounds", {})),
			"%s at %s lies outside %s's bounds" % [id, at, region_id])
		var habitats: Array = legal.get(str(node.get("resource_id", "")), [])
		assert_true(habitats.has(region_id),
			"%s places %s outside its resource habitat" % [id, str(node.get("resource_id", ""))])


func test_only_encounter_rewards_are_left_unplaced() -> void:
	# The placement tests walk `gatherable_nodes()`; anything that skips must be
	# a creature drop that is never hand-placed in the world.
	var methods := {}
	for raw: Variant in _chapter.get("resource_tier", {}).get("resources", []):
		methods[str((raw as Dictionary).get("id", ""))] = str((raw as Dictionary).get("gather_method", ""))
	for raw: Variant in _chapter.get("resource_tier", {}).get("nodes", []):
		var node := raw as Dictionary
		if str(node.get("respawn_policy", "")) == "world_day_regrow":
			continue
		assert_eq(methods.get(str(node.get("resource_id", "")), ""), "encounter_reward",
			"%s is not gatherable but is not an encounter reward" % str(node.get("id", "")))


# -- port of cloudreach_world.gd's surface registry and _resource_position ----


func _build_surfaces() -> Array[Dictionary]:
	var surfaces: Array[Dictionary] = []
	var landmass: Dictionary = _visual.get("landmass", {})
	# `_build_regions`: one rotated crown ellipse per region.
	for raw: Variant in _world.get("regions", []):
		var spec := raw as Dictionary
		var bounds: Dictionary = spec.get("bounds", {})
		var min_x := float(bounds.get("min_x", 0.0))
		var max_x := float(bounds.get("max_x", min_x + 40.0))
		var min_z := float(bounds.get("min_z", 0.0))
		var max_z := float(bounds.get("max_z", min_z + 40.0))
		var at := _vec(spec.get("position", []))
		var size := Vector2(
			clampf((max_x - min_x) * float(landmass.get("region_width_factor", 0.30)),
				float(landmass.get("min_width_m", 260.0)), float(landmass.get("max_width_m", 560.0))),
			clampf((max_z - min_z) * float(landmass.get("region_depth_factor", 0.28)),
				float(landmass.get("min_depth_m", 220.0)), float(landmass.get("max_depth_m", 460.0))))
		surfaces.append({"kind": "ellipse", "centre": Vector2(at.x, at.z), "half": size * 0.30,
			# `_mesa`'s own rotation for seed = region order.
			"rotation": deg_to_rad(float(posmod(int(spec.get("order", 0)) * 23, 36)) - 18.0),
			"height": at.y, "source": "region:" + str(spec.get("id", "")),
			"gate": str(spec.get("access", {}).get("requires_unlock", ""))})
	# `_build_transition_ledges`.
	var transitions: Variant = _world.get("transition_points", {})
	if transitions is Dictionary:
		for raw: Variant in (transitions as Dictionary).values():
			var at := _vec((raw as Dictionary).get("position", []))
			surfaces.append({"kind": "rect", "centre": Vector2(at.x, at.z), "half": Vector2(21.0, 21.0),
				"height": at.y, "source": "transition", "gate": ""})
	# `_build_routes`: ground routes only; per route its pads, then its ribbons.
	var pad_keys := {}
	for raw: Variant in _world.get("routes", []):
		var spec := raw as Dictionary
		if str(spec.get("traversal_mode", "ground")) != "ground":
			continue
		var route_id := str(spec.get("id", ""))
		var gate := str(spec.get("requires_unlock", ""))
		var collision_width := minf(float(spec.get("width_m", 7.5)),
			float(landmass.get("path_collision_width_m", 7.0)))
		var cap_half := maxf(float(landmass.get("landing_size_m", 16.0)), collision_width * 2.25) * 0.41
		var points: Array[Vector3] = []
		for point: Variant in spec.get("polyline", []):
			points.append(_vec(point))
		for pad: Vector3 in points:
			if _bridge_interior_point(route_id, pad):
				continue
			var key := "%.1f,%.1f" % [pad.x, pad.z]
			if pad_keys.has(key):
				continue
			pad_keys[key] = true
			surfaces.append({"kind": "rect", "centre": Vector2(pad.x, pad.z),
				"half": Vector2.ONE * cap_half, "height": pad.y + 0.03,
				"source": "pad:" + route_id, "gate": gate})
		for i in points.size() - 1:
			for section: Dictionary in _ground_sections(route_id, points[i], points[i + 1]):
				var a: Vector3 = section["a"]
				var b: Vector3 = section["b"]
				if a.is_equal_approx(points[i]):
					a = _landing_join(points[i], points[i + 1], cap_half)
				if b.is_equal_approx(points[i + 1]):
					b = _landing_join(points[i + 1], points[i], cap_half)
				surfaces.append({"kind": "segment", "a": a, "b": b, "half_width": collision_width * 0.5,
					"source": "road:" + route_id, "gate": gate})
	# `_build_bridges` / `_build_bridge_section`.
	for raw: Variant in _world.get("bridges", []):
		var spec := raw as Dictionary
		var points: Array = spec.get("deck_profile", spec.get("endpoints", []))
		var cap_half := float(landmass.get("landing_size_m", 16.0)) * 0.41
		var gate := str(spec.get("requires_unlock", ""))
		if gate.is_empty():
			gate = str(_find(_world.get("routes", []), str(spec.get("route_id", ""))).get("requires_unlock", ""))
		for i in points.size() - 1:
			var a := _vec(points[i])
			var b := _vec(points[i + 1])
			if i == 0:
				a = _landing_join(a, b, cap_half, 0.75)
			if i == points.size() - 2:
				b = _landing_join(b, a, cap_half, 0.75)
			surfaces.append({"kind": "segment", "a": a, "b": b,
				"half_width": float(spec.get("width_m", 3.2)) * 0.5,
				"source": "bridge:" + str(spec.get("id", "")), "gate": gate})
	# `_build_landmarks` (solo build).
	for raw: Variant in _world.get("landmarks", []):
		var spec := raw as Dictionary
		var at := _vec(spec.get("position", []))
		surfaces.append({"kind": "rect", "centre": Vector2(at.x, at.z), "half": Vector2(17.0, 17.0),
			"height": at.y, "source": "landmark:" + str(spec.get("id", "")),
			"gate": str(spec.get("requires_unlock", ""))})
	# `cloudreach_stormward_handoff.gd::build`, also registered before resources:
	# the summit's descent steps below the Waterward Overlook.
	var summit := _find(_world.get("regions", []), "summit_final_stronghold")
	var summit_gate := str(summit.get("access", {}).get("requires_unlock", ""))
	for i in 24:
		surfaces.append({"kind": "rect", "centre": Vector2(-420.0, 5664.0 + float(i) * 1.4),
			"half": Vector2(5.0, 0.75), "height": 1110.0 - float(i) * 0.25,
			"source": "stormward_step", "gate": summit_gate})
	return surfaces


## `_resource_position`: {position, kept, surface}.
func _resolve(authored: Vector3) -> Dictionary:
	var ground := _ground_height_near(authored)
	if not ground.is_empty() and absf(float(ground["height"]) - authored.y) <= KEEP_HEIGHT_M:
		return {"position": Vector3(authored.x, float(ground["height"]) + LIFT_M, authored.z),
			"kept": true, "surface": ground["surface"]}
	var best := Vector3.ZERO
	var best_surface := {}
	var best_distance := INF
	for surface: Dictionary in _surfaces:
		if str(surface["kind"]) != "segment":
			continue
		var a: Vector3 = surface["a"]
		var b: Vector3 = surface["b"]
		var ab := Vector2(b.x - a.x, b.z - a.z)
		var t := clampf(Vector2(authored.x - a.x, authored.z - a.z).dot(ab) / maxf(ab.length_squared(), 0.01),
			SNAP_T_MIN, SNAP_T_MAX)
		var centre := a.lerp(b, t)
		var sideways := Vector3.UP.cross(Vector3(ab.x, 0.0, ab.y).normalized())
		var candidate := centre + sideways * minf(SNAP_SIDEWAYS_MAX_M, float(surface["half_width"]) * 0.7)
		var distance := Vector2(candidate.x - authored.x, candidate.z - authored.z).length() \
			+ absf(candidate.y - authored.y) * SNAP_HEIGHT_WEIGHT
		if distance < best_distance:
			best_distance = distance
			best = candidate + Vector3.UP * LIFT_M
			best_surface = surface
	return {"position": best, "kept": false, "surface": best_surface}


## `ground_height_at(x, z, preferred_y)` + `_preferred_surface`: of every
## surface containing the point, the one whose height is nearest the authored Y.
func _ground_height_near(at: Vector3) -> Dictionary:
	var best := {}
	for surface: Dictionary in _surfaces:
		var height := NAN
		var kind := str(surface["kind"])
		if kind == "rect":
			var centre: Vector2 = surface["centre"]
			var half: Vector2 = surface["half"]
			if absf(at.x - centre.x) <= half.x and absf(at.z - centre.y) <= half.y:
				height = float(surface["height"])
		elif kind == "ellipse":
			var centre: Vector2 = surface["centre"]
			var half: Vector2 = surface["half"]
			var local := Vector2(at.x - centre.x, at.z - centre.y).rotated(-float(surface["rotation"]))
			if local.x * local.x / (half.x * half.x) + local.y * local.y / (half.y * half.y) <= 1.0:
				height = float(surface["height"])
		else:
			var a: Vector3 = surface["a"]
			var b: Vector3 = surface["b"]
			var ab := Vector2(b.x - a.x, b.z - a.z)
			if ab.length_squared() <= 0.001:
				continue
			var t := clampf(Vector2(at.x - a.x, at.z - a.z).dot(ab) / ab.length_squared(), 0.0, 1.0)
			if (Vector2(a.x, a.z) + ab * t).distance_to(Vector2(at.x, at.z)) <= float(surface["half_width"]):
				height = lerpf(a.y, b.y, t)
		if is_nan(height):
			continue
		if best.is_empty() or absf(height - at.y) < absf(float(best["height"]) - at.y):
			best = {"height": height, "surface": surface}
	return best


## `_ground_sections_for_segment`: the ground left after cutting out every
## bridge span authored on this route.
func _ground_sections(route_id: String, a: Vector3, b: Vector3) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var flat := Vector3(b.x - a.x, 0.0, b.z - a.z)
	var length_squared := flat.length_squared()
	if length_squared < 0.01:
		return result
	var cut_start := 1.0
	var cut_end := 0.0
	for raw: Variant in _world.get("bridges", []):
		var bridge := raw as Dictionary
		if str(bridge.get("route_id", "")) != route_id:
			continue
		var endpoints: Array = bridge.get("endpoints", [])
		if endpoints.size() < 2:
			continue
		var p0 := _vec(endpoints[0])
		var p1 := _vec(endpoints[1])
		var t0 := (p0 - a).dot(flat) / length_squared
		var t1 := (p1 - a).dot(flat) / length_squared
		var d0 := Vector2(p0.x - a.x - flat.x * t0, p0.z - a.z - flat.z * t0).length()
		var d1 := Vector2(p1.x - a.x - flat.x * t1, p1.z - a.z - flat.z * t1).length()
		if maxf(d0, d1) > 0.25:
			continue
		var local_start := clampf(minf(t0, t1), 0.0, 1.0)
		var local_end := clampf(maxf(t0, t1), 0.0, 1.0)
		if local_end <= 0.0 or local_start >= 1.0 or local_end - local_start < 0.015:
			continue
		cut_start = minf(cut_start, local_start)
		cut_end = maxf(cut_end, local_end)
	if cut_end <= cut_start:
		result.append({"a": a, "b": b})
		return result
	if cut_start > 0.035:
		result.append({"a": a, "b": a.lerp(b, cut_start)})
	if cut_end < 0.965:
		result.append({"a": a.lerp(b, cut_end), "b": b})
	return result


func _bridge_interior_point(route_id: String, point: Vector3) -> bool:
	for raw: Variant in _world.get("bridges", []):
		var bridge := raw as Dictionary
		if str(bridge.get("route_id", "")) != route_id:
			continue
		var profile: Array = bridge.get("deck_profile", [])
		for i in range(1, profile.size() - 1):
			if _vec(profile[i]).is_equal_approx(point):
				return true
	return false


static func _landing_join(pad: Vector3, toward: Vector3, cap_half: float, length_fraction: float = 0.2) -> Vector3:
	var flat := Vector3(toward.x - pad.x, 0, toward.z - pad.z)
	var length := flat.length()
	if length < 0.01:
		return pad
	var direction := flat / length
	var edge_distance := cap_half / maxf(absf(direction.x), absf(direction.z))
	return pad + direction * minf(edge_distance - 0.25, length * length_fraction)


# -- data helpers ------------------------------------------------------------


func _grows_on_ungated_ground(resource: Dictionary) -> bool:
	for region_id: Variant in resource.get("region_ids", []):
		var region := _find(_world.get("regions", []), str(region_id))
		if not region.is_empty() and str(region.get("access", {}).get("requires_unlock", "")).is_empty():
			return true
	return false


## Where the world actually builds the node: `cloudreach_visual.json`'s
## `resource_positions` override wins over the chapter's authored position.
func _placed_position(node: Dictionary) -> Vector3:
	var override: Variant = _visual.get("resource_positions", {}).get(str(node.get("id", "")))
	return _vec(override if override is Array else node.get("position", []))


func _segment_distance(at: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := Vector2(b.x - a.x, b.z - a.z)
	var t := clampf(Vector2(at.x - a.x, at.z - a.z).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return (Vector2(a.x, a.z) + ab * t).distance_to(Vector2(at.x, at.z))


func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _inside_bounds(at: Vector3, bounds: Dictionary) -> bool:
	return at.x >= float(bounds.get("min_x", INF)) and at.x <= float(bounds.get("max_x", -INF)) \
		and at.y >= float(bounds.get("min_y", INF)) and at.y <= float(bounds.get("max_y", -INF)) \
		and at.z >= float(bounds.get("min_z", INF)) and at.z <= float(bounds.get("max_z", -INF))


func _find(entries: Array, id: String) -> Dictionary:
	for raw: Variant in entries:
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == id:
			return raw
	return {}


func _vec(raw: Variant) -> Vector3:
	var values: Array = raw if raw is Array else []
	if values.size() != 3:
		return Vector3.INF
	return Vector3(float(values[0]), float(values[1]), float(values[2]))
