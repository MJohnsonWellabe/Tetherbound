extends "res://tests/test_case.gd"

## OWNER-0912 safeguards updated to settled F17: one straight home-to-Hall
## road, eight facing homes and the seven named service residents. Historical
## method names are retained; their doorway, terrain, exclusion, fence and
## story safeguards apply to the actual authored layout, not retired poses.

const BOUNDARY := preload("res://scripts/world/village_boundary.gd")
const VILLAGE_PATH := "res://data/config/village.json"
const PEOPLE_PATH := "res://data/config/village_npcs.json"
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const VEGETATION_PATH := "res://data/config/bands/band1_lower_meadows/vegetation.json"
const DIALOGUE_PATH := "res://data/dialogue/village.json"
const RELAY_DIALOGUE_PATH := "res://data/dialogue/relay.json"
const SHOP_INTERIOR_PATH := "res://scripts/world/shop_interior.gd"

const OPENING_FIVE := ["Mira", "Oskar", "Tam", "Bram", "Halda", "Nessa", "Maren"]
const HOUSE_IDS := ["mira_shop", "tam_workshop", "bram_inn", "halda_house",
	"research_house", "oskar_house", "alder_house", "orchard_house"]
const ROUTE_ROLES := {
	"Quarry Foreman": Vector2(392.0, 1792.0),
	"Wilhelm": Vector2(341.0, 932.0),
	"Corin": Vector2(-150.0, 4232.0),
	"Ada": Vector2(-262.0, 2258.0),
	"Garrick": Vector2(-45.0, 185.0),
	"Old Perrin": Vector2(-378.0, 352.0),
	"Tobin": Vector2(-28.0, 1298.0),
	"Lark": Vector2(-32.0, 4062.0),
	"Ren": Vector2(334.0, 5704.0),
	"Sela": Vector2(-348.0, 505.0),
}


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "%s parses as a JSON object" % path)
	return parsed as Dictionary if parsed is Dictionary else {}


func _people() -> Array:
	return _json(PEOPLE_PATH).get("villagers", []) as Array


func _person(name: String) -> Dictionary:
	for raw: Variant in _people():
		if raw is Dictionary and str((raw as Dictionary).get("name", "")) == name:
			return raw as Dictionary
	return {}


func _point(spec: Dictionary) -> Vector2:
	var at: Array = spec.get("position", []) as Array
	return Vector2(float(at[0]), float(at[2] if at.size() >= 3 else at[1]))


func _structure(prefab: String) -> Dictionary:
	for raw: Variant in (_json(VILLAGE_PATH).get("structures", []) as Array):
		if raw is Dictionary and str((raw as Dictionary).get("prefab", "")) == prefab:
			return raw as Dictionary
	return {}


func _at(spec: Dictionary, key: String = "at") -> Vector2:
	var raw: Array = spec.get(key, []) as Array
	return Vector2(float(raw[0]), float(raw[1])) if raw.size() >= 2 else Vector2.INF


func _terrain_flat(centre: Vector2) -> Dictionary:
	for raw: Variant in (_json(TERRAIN_PATH).get("flats", []) as Array):
		if raw is Dictionary and _at(raw as Dictionary, "centre") == centre:
			return raw as Dictionary
	return {}


func _apron(centre: Vector2) -> Dictionary:
	var block := _json(TERRAIN_PATH).get("building_aprons", {}) as Dictionary
	for raw: Variant in (block.get("footprints", []) as Array):
		if raw is Dictionary and _at(raw as Dictionary, "centre") == centre:
			return raw as Dictionary
	return {}


func _vegetation_entry(kind: String, centre: Vector2) -> Dictionary:
	for raw: Variant in (_json(VEGETATION_PATH).get(kind, []) as Array):
		if not raw is Dictionary:
			continue
		var entry := raw as Dictionary
		if Vector2(float(entry.get("x", INF)), float(entry.get("z", INF))) == centre:
			return entry
	return {}



func _identified(id: String) -> Dictionary:
	var result := {}
	var count := 0
	for row: Dictionary in _json(VILLAGE_PATH).get("structures", []):
		if str(row.get("id", "")) == id:
			result = row
			count += 1
	assert_eq(count, 1, "%s must have exactly one actual structure" % id)
	return result

func _road_segment() -> Array[Vector2]:
	var plan: Dictionary = _json(VILLAGE_PATH).get("road_plan", {})
	return [_at(plan, "road_start"), _at(plan, "road_end")]

func _segment_distance(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> float:
	if Geometry2D.segment_intersects_segment(a, b, c, d) != null:
		return 0.0
	return minf(minf(a.distance_to(Geometry2D.get_closest_point_to_segment(a, c, d)),
		b.distance_to(Geometry2D.get_closest_point_to_segment(b, c, d))),
		minf(c.distance_to(Geometry2D.get_closest_point_to_segment(c, a, b)),
			d.distance_to(Geometry2D.get_closest_point_to_segment(d, a, b))))

func _collider_radius(prefab: String) -> float:
	var recipe: Dictionary = _json("res://data/config/building_prefabs.json").get("prefabs", {}).get(prefab, {})
	assert_false(recipe.is_empty(), "the installed prefab must exist")
	var bound := 0.0
	for box: Dictionary in recipe.get("colliders", []):
		var at: Array = box.get("at", [0, 0, 0])
		var size: Array = box.get("size", [0, 0, 0])
		var corner := Vector2(absf(float(at[0])) + float(size[0]) * 0.5,
			absf(float(at[2])) + float(size[2]) * 0.5)
		bound = maxf(bound, corner.length())
	assert_true(bound > 0.0, "the real home must retain physical collision")
	return bound

func test_opening_village_keeps_exactly_five_functional_people_inside() -> void:
	var outline := BOUNDARY.outline(BOUNDARY.load_config())
	var inside: Array[String] = []
	for raw: Variant in _people():
		var spec := raw as Dictionary
		if BOUNDARY.contains(outline, _point(spec)):
			inside.append(str(spec.get("name", "")))
	inside.sort()
	var expected: Array[String] = []
	for name: String in OPENING_FIVE:
		expected.append(name)
	expected.sort()
	assert_eq(inside, expected,
		"the village boundary retains exactly its seven named F17 service residents")


func test_every_resited_villager_is_retained_at_their_authored_route_role() -> void:
	assert_eq(_people().size(), 20,
		"the replan retains the installed cast; F17 returns Nessa to the Research House service")
	for name: String in ROUTE_ROLES:
		var spec := _person(name)
		assert_false(spec.is_empty(), "%s remains in the cast" % name)
		if not spec.is_empty():
			assert_eq(_point(spec), ROUTE_ROLES[name], "%s stands at the authored route role" % name)
	assert_true(_person("Sela").has("place_when"), "Sela still appears only after her rescue")


func test_camp_hammer_moves_to_tam_before_the_foreman_leaves() -> void:
	var conversations := _json(DIALOGUE_PATH).get("conversations", {}) as Dictionary
	var tam := conversations.get("village_tam_tools", {}) as Dictionary
	var encoded := JSON.stringify(tam)
	assert_true(encoded.contains("give:hammer:1"), "Tam hands over the real camp hammer")
	assert_true(encoded.contains("flag:camp_hammer_given"), "Tam advances the opening hammer flag")
	var foreman := _person("Quarry Foreman")
	assert_false(JSON.stringify(foreman.get("greeting_when", [])).contains("village_quarry_foreman_hammer"),
		"the relocated Foreman no longer owns a village-only prerequisite handoff")


func test_selas_rescue_testimony_is_short_and_keeps_the_story_payload() -> void:
	var rescue := ((_json(RELAY_DIALOGUE_PATH).get("conversations", {}) as Dictionary)
		.get("relay_captive_freed", {}) as Dictionary)
	var lines := rescue.get("lines", []) as Array
	assert_true(lines.size() <= 4, "Sela's rescue speech no longer becomes a seven-screen wall of text")
	var encoded := JSON.stringify(lines)
	assert_true(encoded.contains("give:mill_bridge_gear:1") and encoded.contains("flag:captive_rescued"),
		"trimming Sela does not remove the bridge gear or rescue flag")
	assert_true(encoded.contains("Warden") and encoded.contains("seams"),
		"trimming Sela preserves the route reveal and the authored-seam testimony")
	var home := ((_json(DIALOGUE_PATH).get("conversations", {}) as Dictionary)
		.get("village_rescued_ranger_home", {}) as Dictionary)
	assert_true((home.get("lines", []) as Array).size() <= 2,
		"Sela's repeat greeting stays brief after the rescue")


func test_both_street_legs_place_buildings_and_thresholds_at_their_authored_roles() -> void:

	var road := _road_segment()
	assert_true(road[0].distance_to(road[1]) > 70.0, "one substantial through-road connects the destinations")
	var sides := [0, 0]
	for id: String in HOUSE_IDS:
		var house := _identified(id)
		var centre := _at(house)
		var nearest := Geometry2D.get_closest_point_to_segment(centre, road[0], road[1])
		var yaw := float(house.get("yaw_deg", INF))
		var front := Vector2(sin(deg_to_rad(yaw)), cos(deg_to_rad(yaw)))
		assert_true(front.dot((nearest - centre).normalized()) > 0.99,
			"%s's native +Z facade must face the actual road" % id)
		sides[0 if centre.y < road[0].y else 1] += 1
		var threshold := _identified(id + "_threshold")
		var approach := _at(threshold)
		assert_true((approach - centre).dot(front) > 0.0,
			"%s's real threshold must be on its public front" % id)
		assert_true(approach.distance_to(nearest) < centre.distance_to(nearest),
			"%s's threshold brings the doorway closer to the street" % id)
	assert_eq(sides, [4, 4], "eight homes form two facing rows")


func test_south_street_has_one_continuous_hidden_road_to_trailgate() -> void:

	var paths: Dictionary = _json(TERRAIN_PATH).get("paths", {})
	var plan: Dictionary = _json(VILLAGE_PATH).get("road_plan", {})
	var street := {}
	for row: Dictionary in paths.get("approaches", []):
		if str(row.get("id", "")) == "village_south_street":
			street = row
	assert_false(street.is_empty(), "the physical through-road retains its TrailGate side lane")
	var points: Array = street.get("points", [])
	assert_true(points.size() >= 2)
	if points.size() < 2:
		return
	var road := _road_segment()
	var start := Vector2(float(points[0][0]), float(points[0][1]))
	assert_true(start.distance_to(Geometry2D.get_closest_point_to_segment(start, road[0], road[1])) < 0.01,
		"the gate lane must actually connect to the village street")
	# Gate actor position is the canonical boundary gate; accept only its actual crossing.
	var outline := BOUNDARY.load_config()
	var found := false
	for candidate: Dictionary in outline.get("gates", {}).get("entries", []):
		if str(candidate.get("name", candidate.get("id", ""))) == "TrailGate":
			var at: Array = candidate.get("at", [])
			if at.size() == 2:
				found = Vector2(float(points.back()[0]), float(points.back()[1])).distance_to(Vector2(float(at[0]), float(at[1]))) < 0.1
	assert_true(found, "the painted lane must reach the real TrailGate")
	var home := {}
	for route: Dictionary in paths.get("routes", []):
		if str(route.get("label", "")) == "Grandpa's House":
			home = route
	assert_false(home.is_empty(), "the real home remains connected")
	var home_points: Array = home.get("points", [])
	assert_true(home_points.size() >= 2)
	if home_points.size() >= 2:
		assert_true(plan.get("home_door", []) in home_points, "home route reaches the actual farmhouse door")


func test_south_street_buildings_share_level_ground_and_matching_aprons() -> void:

	var flats: Array = _json(TERRAIN_PATH).get("flats", [])
	for id: String in HOUSE_IDS:
		var house := _identified(id)
		var centre := _at(house)
		var radius := _collider_radius(str(house.prefab))
		var covered := false
		for flat: Dictionary in flats:
			if _at(flat, "centre").distance_to(centre) + radius <= float(flat.get("radius", 0.0)):
				assert_eq(float(flat.get("height", INF)), 0.9, "homes share the street's level ground")
				covered = true
		assert_true(covered, "%s's actual complete collision footprint must stand on flattened ground" % id)
		var apron := _apron(centre)
		assert_false(apron.is_empty(), "%s retains worked-soil footing" % id)
		assert_eq(float(apron.get("yaw_deg", INF)), float(house.get("yaw_deg", 0.0)),
			"each real apron follows its building's actual orientation")


func test_fences_define_working_yards_without_cutting_the_street() -> void:

	var road := _road_segment()
	var fences: Array[Dictionary] = []
	for row: Dictionary in _json(VILLAGE_PATH).get("structures", []):
		if str(row.get("prefab", "")) == "fence_run":
			fences.append(row)
	assert_true(fences.size() >= 2, "working yards retain enclosing rail composition")
	var recipe: Dictionary = _json("res://data/config/building_prefabs.json").get("prefabs", {}).get("fence_run", {})
	var plan: Dictionary = _json(VILLAGE_PATH).get("road_plan", {})
	var road_half_width := float(plan.get("width_m", 0.0)) * 0.5
	assert_true(road_half_width > 0.0, "the authored walking band must have positive width")
	# A rail crossing the road can have both endpoints outside it. The whole
	# segment, including the road's finite endpoints, must retain clearance.
	assert_eq(_segment_distance(Vector2(40, 10.925), Vector2(40, 17.075), road[0], road[1]), 0.0,
		"a perpendicular rail through the walking band must be rejected")
	assert_true(absf(_segment_distance(Vector2(7, 10), Vector2(7, 18), road[0], road[1]) - 1.3) < 0.001,
		"the nearest road endpoint must count even when both rail endpoints are farther away")
	for row: Dictionary in fences:
		var yaw := deg_to_rad(float(row.get("yaw_deg", 0.0)))
		var direction := Vector2(cos(yaw), -sin(yaw))
		for box: Dictionary in recipe.get("colliders", []):
			var offset: Array = box.get("at", [])
			var size: Array = box.get("size", [])
			assert_true(offset.size() == 3 and size.size() == 3, "the actual rail collision box must be defined")
			if offset.size() != 3 or size.size() != 3:
				continue
			var centre := _at(row) + Vector2(float(offset[0]), float(offset[2])).rotated(-yaw)
			var half_length := float(size[0]) * 0.5
			var half_thickness := float(size[2]) * 0.5
			assert_true(half_length > 0.0 and half_thickness > 0.0, "the rail retains its actual solid dimensions")
			var first := centre - direction * half_length
			var last := centre + direction * half_length
			assert_true(_segment_distance(first, last, road[0], road[1]) > road_half_width + half_thickness,
				"the actual whole solid yard rail must stay outside the full walking band")
	assert_true(absf(float(fences[0].get("yaw_deg", 0)) - float(fences[1].get("yaw_deg", 0))) == 90.0,
		"the retained working yard has a readable perpendicular enclosure")


func test_the_five_villagers_belong_to_visible_street_functions() -> void:

	var homes := {"Mira": "mira_shop", "Oskar": "oskar_house", "Tam": "tam_workshop",
		"Bram": "bram_inn", "Nessa": "research_house", "Maren": "research_house"}
	for name: String in homes:
		var person := _person(name)
		assert_false(person.is_empty(), "%s remains at their actual service" % name)
		assert_true(_point(person).distance_to(_at(_identified(homes[name]))) <= 8.0,
			"%s belongs to the actual named home frontage/interior" % name)
		assert_false(str(person.get("greeting", "")).is_empty(), "each resident retains their playable service conversation")
	var tournament: Dictionary = _json("res://data/config/tournament.json")
	var arena: Array = tournament.get("board", {}).get("position", [])
	assert_eq(arena.size(), 2)
	if arena.size() == 2:
		assert_true(_point(_person("Halda")).distance_to(Vector2(float(arena[0]), float(arena[1]))) <= 6.0,
			"Halda remains beside the real tournament service")


func test_every_moved_building_has_scatter_and_ground_cover_exclusion() -> void:

	var vegetation := _json(VEGETATION_PATH)
	for id: String in HOUSE_IDS:
		var house := _identified(id)
		var centre := _at(house)
		var radius := _collider_radius(str(house.prefab))
		var covered := false
		for clearing: Dictionary in vegetation.get("clearings", []):
			var at := Vector2(float(clearing.get("x", INF)), float(clearing.get("z", INF)))
			covered = covered or at.distance_to(centre) + radius <= float(clearing.get("radius", 0.0))
		assert_true(covered, "%s clears random solid scatter over its full physical footprint" % id)
		var footprint := _vegetation_entry("footprints", centre)
		assert_true(float(footprint.get("radius", 0.0)) >= radius,
			"%s excludes even clearing-exempt ground cover over its actual collision envelope" % id)


func test_miras_shop_uses_an_installed_trade_crest_not_placeholder_text() -> void:
	assert_true(ResourceLoader.exists("res://assets/props/quaternius_fantasy/Shield_Wooden.gltf"),
		"Mira's crest uses the installed village prop family")
	var source := FileAccess.get_file_as_string(SHOP_INTERIOR_PATH)
	assert_false(source.contains("Label3D.new()"), "the tiny billboard-text shop sign must not return")
	assert_false(source.contains("ShopSignBoard"), "the flat box sign must not return")
	var script := load(SHOP_INTERIOR_PATH) as GDScript
	assert_true(script != null, "the shop interior parses")
	if script == null:
		return
	var shop := script.new() as Node3D
	shop.call("build")
	assert_true(shop.get_node_or_null(^"ShopTradeCrest/InstalledWoodenShield") != null,
		"the physical wooden crest is mounted over Mira's real door")
	assert_true(shop.get_node_or_null(^"ShopTradeCrest/TradeCoinMedallion") != null,
		"the crest carries a readable merchant emblem without text")
	assert_true(shop.get_node_or_null(^"ShopTradeCrest/TradeCoinMountingRim") != null,
		"the trade coin has a contrasting installed mounting rim at street distance")
	assert_true(shop.get_node_or_null(^"ShopTradeCrest/TradeCoinStackLeft") != null \
		and shop.get_node_or_null(^"ShopTradeCrest/TradeCoinStackRight") != null,
		"the crest uses a three-coin relief instead of another blank circular face")
	var crest_light := shop.get_node_or_null(^"TradeCrestWarmPool") as OmniLight3D
	assert_true(crest_light != null, "Mira's exterior crest has a dedicated night practical")
	if crest_light != null:
		assert_true(crest_light.omni_range <= 4.5, "the crest light remains facade-local")
	assert_eq(shop.find_children("*", "Label3D", true, false).size(), 0,
		"Mira's shop presentation contains no label billboard")
	shop.free()


func test_relic_circle_keeps_human_scale_beside_the_south_street() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/playground_world.gd")
	assert_true(source.contains('shrine.set("presentation_footprint_m", 3.0)'),
		"house-scale relic stones must not pinch off Mira's street")
	assert_true(source.contains('shrine.set("presentation_height_m", 2.4)'),
		"the home relic circle stays subordinate to village buildings")
