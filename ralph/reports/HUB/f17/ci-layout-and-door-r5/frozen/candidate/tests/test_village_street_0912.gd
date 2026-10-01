extends "res://tests/test_case.gd"

## RD-29/F17 supersedes the 0912 two-leg street. Keep the named opening
## functions, installed cast, door/road alignment, level collision footprints,
## working-yard clearance and scatter exclusions on the accepted eastward road.
## Existing test entrypoints remain; actual traversal/visual proof stays OPEN.

const BOUNDARY := preload("res://scripts/world/village_boundary.gd")
const VILLAGE_PATH := "res://data/config/village.json"
const PEOPLE_PATH := "res://data/config/village_npcs.json"
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const VEGETATION_PATH := "res://data/config/bands/band1_lower_meadows/vegetation.json"
const DIALOGUE_PATH := "res://data/dialogue/village.json"
const RELAY_DIALOGUE_PATH := "res://data/dialogue/relay.json"
const SHOP_INTERIOR_PATH := "res://scripts/world/shop_interior.gd"

const OPENING_FIVE := ["Mira", "Oskar", "Tam", "Bram", "Halda"]
const VILLAGE_FUNCTIONS := ["Mira", "Oskar", "Tam", "Bram", "Halda", "Maren", "Nessa"]
const PREFABS_PATH := "res://data/config/building_prefabs.json"
const ROAD_HOUSES := {
	"mira_shop": {"prefab": "cottage_a", "at": Vector2(26.0, 2.0), "yaw": 0.0, "threshold": Vector2(27.0, 7.9), "radius": 6.0},
	"tam_workshop": {"prefab": "workshop", "at": Vector2(26.0, 26.0), "yaw": 180.0, "threshold": Vector2(26.0, 19.1), "radius": 7.5},
	"bram_inn": {"prefab": "inn", "at": Vector2(44.0, 2.0), "yaw": 0.0, "threshold": Vector2(44.0, 10.6), "radius": 7.8},
	"halda_house": {"prefab": "cottage_b", "at": Vector2(44.0, 26.0), "yaw": 180.0, "threshold": Vector2(43.0, 21.1), "radius": 5.3},
	"research_house": {"prefab": "cottage_a", "at": Vector2(62.0, 2.0), "yaw": 0.0, "threshold": Vector2(63.0, 7.9), "radius": 5.37},
	"oskar_house": {"prefab": "cottage_b", "at": Vector2(62.0, 26.0), "yaw": 180.0, "threshold": Vector2(61.0, 21.1), "radius": 4.61},
	"alder_house": {"prefab": "cottage_b", "at": Vector2(80.0, 2.0), "yaw": 0.0, "threshold": Vector2(81.0, 6.9), "radius": 4.61},
	"orchard_house": {"prefab": "cottage_a", "at": Vector2(80.0, 26.0), "yaw": 180.0, "threshold": Vector2(79.0, 20.1), "radius": 5.37},
}
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


func _structure_id(id: String) -> Dictionary:
	for raw: Dictionary in _json(VILLAGE_PATH).get("structures", []):
		if str(raw.get("id", "")) == id:
			return raw
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


func test_opening_village_keeps_exactly_five_functional_people_inside() -> void:
	var outline := BOUNDARY.outline(BOUNDARY.load_config())
	var inside: Array[String] = []
	for raw: Variant in _people():
		var spec := raw as Dictionary
		if BOUNDARY.contains(outline, _point(spec)):
			inside.append(str(spec.get("name", "")))
	inside.sort()
	var expected: Array[String] = []
	for name: String in VILLAGE_FUNCTIONS:
		expected.append(name)
		assert_false(_person(name).is_empty(), "%s retains a real village function" % name)
	expected.sort()
	assert_eq(inside, expected, "RD-29 retains the five opening functions and the named research-house residents")
	for name: String in OPENING_FIVE:
		assert_true(inside.has(name), "the original opening function %s remains inside the locked perimeter" % name)


func test_every_resited_villager_is_retained_at_their_authored_route_role() -> void:
	assert_eq(_people().size(), 20,
		"the replan retains the installed cast; RD-29 gives Nessa a village research-house role")
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
	var count := 0
	for raw: Dictionary in _json(VILLAGE_PATH).get("structures", []):
		if bool(raw.get("road_house", false)):
			count += 1
	assert_eq(count, 8, "RD-29 retains its eight independently authored road houses")
	for id: String in ROAD_HOUSES:
		var expected: Dictionary = ROAD_HOUSES[id]
		var house := _structure_id(id)
		assert_false(house.is_empty(), "%s is present" % id)
		assert_eq(str(house.get("prefab", "")), str(expected.prefab), "%s keeps its installed family and role" % id)
		assert_eq(_at(house), expected.at, "%s occupies its RD-29 road parcel" % id)
		assert_eq(float(house.get("yaw_deg", INF)), float(expected.yaw), "%s faces the public road" % id)
		var yaw := deg_to_rad(float(house.get("yaw_deg", 0.0)))
		var toward_road := (Vector2(_at(house).x, 14.0) - _at(house)).normalized()
		assert_true(Vector2(sin(yaw), cos(yaw)).dot(toward_road) > 0.99, "the native front points toward the road")
		var threshold := _structure_id(id + "_threshold")
		assert_eq(str(threshold.get("prefab", "")), "doorstep", "each house has a physical threshold")
		assert_eq(_at(threshold), expected.threshold, "the threshold follows the house's actual front")
		assert_eq(float(threshold.get("yaw_deg", INF)), float(expected.yaw), "the threshold rotation follows its doorway")


func test_south_street_has_one_continuous_hidden_road_to_trailgate() -> void:
	var paths := _json(TERRAIN_PATH).get("paths", {}) as Dictionary
	var street: Dictionary = {}
	var main: Dictionary = {}
	for raw: Dictionary in paths.get("approaches", []):
		if str(raw.get("id", "")) == "village_south_street":
			street = raw
		if str(raw.get("id", "")) == "village_main_street":
			main = raw
	assert_false(street.is_empty(), "the road to TrailGate remains painted")
	assert_eq(street.get("points", []), [[13.79, 14.0], [13.79, 22.4]], "the exit leg joins the current road and actual gate centre")
	assert_eq(main.get("points", []), [[8.3, 14.0], [91.0, 14.0]], "one straight road leads from the farm door to the Hall")
	var grandpa_route: Dictionary = {}
	var inn_route: Dictionary = {}
	for raw: Dictionary in paths.get("routes", []):
		if str(raw.get("label", "")) == "Grandpa's House":
			grandpa_route = raw
		if str(raw.get("label", "")) == "The Inn":
			inn_route = raw
	assert_false(grandpa_route.is_empty(), "Grandpa's actual door remains connected")
	assert_eq(grandpa_route.get("points", []), [[8.3, 14.0], [13.79, 14.0]], "the house route starts at its translated production marker")
	assert_eq(inn_route.get("points", []), [[46.0, 14.0], [46.0, 10.6], [44.0, 10.6]], "the inn approach reaches its actual threshold")
	assert_true(Vector2(46.0, 14.0).distance_to(Vector2(34.0, 5.0)) >= 4.0, "the inn turn remains clear of the well canopy and bucket")


func test_south_street_buildings_share_level_ground_and_matching_aprons() -> void:
	for centre: Vector2 in [Vector2(24.0, 14.0), Vector2(48.0, 14.0), Vector2(72.0, 14.0), Vector2(96.0, 14.0)]:
		var pad := _terrain_flat(centre)
		assert_false(pad.is_empty(), "the current road has its actual level pad")
		assert_true(float(pad.get("radius", 0.0)) >= 20.0, "the level pads cover the road's two-sided buildings")
		assert_eq(float(pad.get("height", INF)), 0.9, "buildings join the road without a terrain step")
	var flats: Array = _json(TERRAIN_PATH).get("flats", [])
	var prefabs: Dictionary = _json(PREFABS_PATH).get("prefabs", {})
	for id: String in ROAD_HOUSES:
		var expected: Dictionary = ROAD_HOUSES[id]
		var house := _structure_id(id)
		var apron := _apron(expected.at)
		assert_false(apron.is_empty(), "%s has a worked-soil apron" % id)
		assert_eq(float(apron.get("yaw_deg", INF)), float(expected.yaw), "the apron rotates with the building")
		var rotation := Basis(Vector3.UP, deg_to_rad(float(expected.yaw)))
		var checked := 0
		var recipe: Dictionary = prefabs.get(str(expected.prefab), {})
		for collider: Dictionary in recipe.get("colliders", []):
			var at: Array = collider.get("at", [])
			var size: Array = collider.get("size", [])
			if at.size() != 3 or size.size() != 3 or float(at[1]) - float(size[1]) * 0.5 > 0.1:
				continue
			checked += 1
			for x_sign: float in [-1.0, 1.0]:
				for z_sign: float in [-1.0, 1.0]:
					var local := Vector3(float(at[0]) + x_sign * float(size[0]) * 0.5, 0.0, float(at[2]) + z_sign * float(size[2]) * 0.5)
					var offset := rotation * local
					var corner: Vector2 = expected.at + Vector2(offset.x, offset.z)
					var level := false
					for flat: Dictionary in flats:
						if float(flat.get("height", INF)) == 0.9 and corner.distance_to(_at(flat, "centre")) <= float(flat.get("radius", 0.0)):
							level = true
					assert_true(level, "%s ground collider corner %s stands on full-flatten ground" % [id, corner])
		assert_true(checked >= 4, "the check covers each actual ground-level wall collider")


func test_fences_define_working_yards_without_cutting_the_street() -> void:
	var fence_poses: Dictionary = {}
	for raw: Dictionary in _json(VILLAGE_PATH).get("structures", []):
		if str(raw.get("prefab", "")) == "fence_run":
			fence_poses[_at(raw)] = float(raw.get("yaw_deg", INF))
	assert_eq(fence_poses.get(Vector2(-9.0, -28.5), INF), 0.0, "the berry yard retains its north working rail")
	assert_eq(fence_poses.get(Vector2(-12.0, -25.5), INF), 90.0, "the berry yard retains its west working rail")
	assert_false(fence_poses.has(Vector2(-11.0, -9.5)), "the orphan rail cannot return across the public approach")
	var road_start := Vector2(8.3, 14.0)
	var road_end := Vector2(91.0, 14.0)
	for at: Vector2 in fence_poses:
		var rotation := Basis(Vector3.UP, deg_to_rad(float(fence_poses[at])))
		for sign_value: float in [-1.0, 1.0]:
			var offset := rotation * Vector3(sign_value * 3.075, 0.0, 0.0)
			var endpoint := at + Vector2(offset.x, offset.z)
			assert_true(endpoint.distance_to(Geometry2D.get_closest_point_to_segment(endpoint, road_start, road_end)) > 3.0,
				"the complete yard rail stays outside the road and player capsule")


func test_the_five_villagers_belong_to_visible_street_functions() -> void:
	assert_eq(_point(_person("Mira")), Vector2(26.0, 0.6), "Mira stands behind her actual shop counter")
	assert_eq(float(_person("Mira").get("facing_deg", INF)), float(_structure_id("mira_shop").get("yaw_deg", INF)), "Mira faces arriving patrons")
	assert_eq(_point(_person("Oskar")), Vector2(62.0, 20.0), "Oskar stands on his road-facing parcel approach")
	assert_eq(_point(_person("Tam")), Vector2(26.0, 20.0), "Tam stands at his actual workshop bay")
	assert_eq(_point(_person("Bram")), Vector2(44.0, -2.39), "Bram remains at the installed bar")
	assert_eq(float(_person("Bram").get("facing_deg", INF)), float(_structure_id("bram_inn").get("yaw_deg", INF)), "Bram faces the customer lane through the bar")
	assert_eq(_point(_person("Halda")), Vector2(88.5, 46.5), "Halda stands at the current tournament lawn")
	assert_eq(_point(_person("Nessa")), Vector2(62.0, 7.0), "Nessa retains the research-house gift role")
	assert_eq(_point(_person("Maren")), Vector2(66.0, 7.0), "Maren retains the named research-house role")


func test_every_moved_building_has_scatter_and_ground_cover_exclusion() -> void:
	var clearings: Array = _json(VEGETATION_PATH).get("clearings", [])
	var prefabs: Dictionary = _json(PREFABS_PATH).get("prefabs", {})
	for centre: Vector2 in [Vector2(26.0, 14.0), Vector2(50.0, 14.0), Vector2(74.0, 14.0)]:
		assert_true(float(_vegetation_entry("clearings", centre).get("radius", 0.0)) >= 22.0,
			"the current road retains its full random-obstruction clearings")
	for id: String in ROAD_HOUSES:
		var expected: Dictionary = ROAD_HOUSES[id]
		var footprint := _vegetation_entry("footprints", expected.at)
		assert_true(float(footprint.get("radius", 0.0)) >= float(expected.radius), "%s rejects clearing-exempt ground cover" % id)
		# Clearings and ground-cover footprints are different shapes. Check the
		# actual wall footprint against the overlapping road clearings, rather
		# than requiring each larger circular grass exclusion to fit one disk.
		var rotation := Basis(Vector3.UP, deg_to_rad(float(expected.yaw)))
		var recipe: Dictionary = prefabs.get(str(expected.prefab), {})
		var checked := 0
		for collider: Dictionary in recipe.get("colliders", []):
			var at: Array = collider.get("at", [])
			var size: Array = collider.get("size", [])
			if at.size() != 3 or size.size() != 3 or float(at[1]) - float(size[1]) * 0.5 > 0.1:
				continue
			checked += 1
			for x_sign: float in [-1.0, 1.0]:
				for z_sign: float in [-1.0, 1.0]:
					var offset := rotation * Vector3(float(at[0]) + x_sign * float(size[0]) * 0.5, 0.0, float(at[2]) + z_sign * float(size[2]) * 0.5)
					var corner: Vector2 = expected.at + Vector2(offset.x, offset.z)
					var cleared := false
					for clearing: Dictionary in clearings:
						var centre := Vector2(float(clearing.get("x", INF)), float(clearing.get("z", INF)))
						if centre.distance_to(corner) <= float(clearing.get("radius", 0.0)):
							cleared = true
					assert_true(cleared, "%s ground wall corner rejects random trees and rocks" % id)
		assert_true(checked >= 4, "scatter checks every actual ground wall")


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
