extends "res://tests/test_case.gd"

## OWNER-0912 / C3 village replan regression coverage. The opening settlement
## is a five-person street, not a ring of idle bodies around the well. The
## south-leg buildings require their own baked-terrain slice. This file pins
## the complete source authoring; the integration lane still owes that bake and
## production visual acceptance.

const BOUNDARY := preload("res://scripts/world/village_boundary.gd")
const VILLAGE_PATH := "res://data/config/village.json"
const PEOPLE_PATH := "res://data/config/village_npcs.json"
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const VEGETATION_PATH := "res://data/config/bands/band1_lower_meadows/vegetation.json"
const DIALOGUE_PATH := "res://data/dialogue/village.json"
const RELAY_DIALOGUE_PATH := "res://data/dialogue/relay.json"
const SHOP_INTERIOR_PATH := "res://scripts/world/shop_interior.gd"

const OPENING_FIVE := ["Mira", "Oskar", "Tam", "Bram", "Halda"]
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
		"the village boundary contains exactly its five opening functions, not an idle crowd")


func test_every_resited_villager_is_retained_at_their_authored_route_role() -> void:
	assert_eq(_people().size(), 19, "the replan resites the installed cast instead of deleting people")
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
	var inn := _structure("inn")
	var cottage := _structure("cottage_b")
	var workshop := _structure("workshop")
	var shop := _structure("cottage_a")
	assert_eq(inn.get("at", []), [-6.0, -14.0], "the inn fronts the west street leg")
	assert_eq(float(inn.get("yaw_deg", 0.0)), 90.0, "the inn door faces east along the street")
	assert_eq(cottage.get("at", []), [19.0, -18.0], "the stone cottage frames the bend")
	assert_eq(float(cottage.get("yaw_deg", 0.0)), -110.0, "the cottage door turns back toward the street")
	assert_eq(workshop.get("at", []), [2.0, 12.0], "Tam's workshop stands west of the south leg")
	assert_eq(float(workshop.get("yaw_deg", 0.0)), 90.0, "the workshop bay faces east onto the street")
	assert_eq(shop.get("at", []), [18.0, 4.0], "Mira's shop stands east of the south leg")
	assert_eq(float(shop.get("yaw_deg", 0.0)), -90.0, "Mira's real door faces west onto the street")
	var doorstep_positions: Array[Vector2] = []
	for raw: Variant in (_json(VILLAGE_PATH).get("structures", []) as Array):
		if raw is Dictionary and str((raw as Dictionary).get("prefab", "")) == "doorstep":
			var at: Array = (raw as Dictionary).get("at", []) as Array
			doorstep_positions.append(Vector2(float(at[0]), float(at[1])))
	assert_true(Vector2(0.1, -14.0) in doorstep_positions, "the inn threshold moved with its door")
	assert_true(Vector2(15.72, -18.13) in doorstep_positions, "the cottage threshold moved with its door")
	assert_true(Vector2(13.87, 5.0) in doorstep_positions, "Mira's threshold moved with the shop door")


func test_south_street_has_one_continuous_hidden_road_to_trailgate() -> void:
	var paths := _json(TERRAIN_PATH).get("paths", {}) as Dictionary
	var street: Dictionary = {}
	for raw: Variant in (paths.get("approaches", []) as Array):
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == "village_south_street":
			street = raw as Dictionary
	assert_false(street.is_empty(), "the well-to-TrailGate street is authored as painted ground")
	assert_eq(street.get("points", []), [[10.0, -10.0], [11.5, 2.0], [14.0, 20.0]],
		"the south street turns at the fixed well and meets the existing TrailGate waypoint")


func test_south_street_buildings_share_level_ground_and_matching_aprons() -> void:
	var pad := _terrain_flat(Vector2(10.0, 8.0))
	assert_false(pad.is_empty(), "the shop/workshop street has a dedicated level pad")
	assert_true(float(pad.get("radius", 0.0)) >= 15.0, "the shared pad covers both rotated footprints")
	assert_eq(float(pad.get("height", INF)), 0.9, "the new pad shares the square's explicit height")
	for expected: Dictionary in [
		{"centre": Vector2(2.0, 12.0), "yaw": 90.0},
		{"centre": Vector2(18.0, 4.0), "yaw": -90.0},
		{"centre": Vector2(19.0, -18.0), "yaw": -110.0},
		{"centre": Vector2(-6.0, -14.0), "yaw": 90.0},
	]:
		var apron := _apron(expected.centre)
		assert_false(apron.is_empty(), "the moved building at %s has a worked-soil apron" % expected.centre)
		assert_eq(float(apron.get("yaw_deg", INF)), float(expected.yaw),
			"the apron at %s mirrors the production building rotation" % expected.centre)


func test_fences_define_working_yards_without_cutting_the_street() -> void:
	var fence_poses: Dictionary = {}
	for raw: Variant in (_json(VILLAGE_PATH).get("structures", []) as Array):
		if raw is Dictionary and str((raw as Dictionary).get("prefab", "")) == "fence_run":
			fence_poses[_at(raw as Dictionary)] = float((raw as Dictionary).get("yaw_deg", INF))
	assert_eq(fence_poses.get(Vector2(28.0, 4.0), INF), 90.0,
		"Oskar's pen has a rear rail parallel to the shop wall")
	assert_eq(fence_poses.get(Vector2(-10.0, 15.0), INF), 90.0,
		"Tam's rear yard has a west rail")
	assert_eq(fence_poses.get(Vector2(-7.0, 18.0), INF), 0.0,
		"Tam's rear rails meet as a readable L")
	for at: Vector2 in [Vector2(28.0, 4.0), Vector2(-10.0, 15.0), Vector2(-7.0, 18.0)]:
		assert_true(at.distance_to(Vector2(12.0, at.y)) >= 11.0,
			"yard rail at %s remains outside the south-street walking lane" % at)


func test_the_five_villagers_belong_to_visible_street_functions() -> void:
	assert_eq(_point(_person("Mira")), Vector2(19.4, 4.0), "Mira remains inside her moved shop")
	assert_eq(float(_person("Mira").get("facing_deg", INF)), -90.0, "Mira faces her west street door")
	assert_eq(_point(_person("Oskar")), Vector2(25.0, 4.0), "Oskar stands in the visible creature pen")
	assert_eq(_point(_person("Tam")), Vector2(8.0, 12.0), "Tam stands at his workshop bay")
	assert_eq(_point(_person("Bram")), Vector2(-10.39, -14.0), "Bram remains at the moved inn bar")
	assert_eq(_point(_person("Halda")), Vector2(23.5, 11.5), "Halda remains at the tournament board")


func test_every_moved_building_has_scatter_and_ground_cover_exclusion() -> void:
	var clearing := _vegetation_entry("clearings", Vector2(10.0, 8.0))
	assert_true(float(clearing.get("radius", 0.0)) >= 17.0,
		"the south street clears random trees and rocks around its buildings")
	for expected: Dictionary in [
		{"centre": Vector2(-6.0, -14.0), "radius": 7.8},
		{"centre": Vector2(2.0, 12.0), "radius": 7.5},
		{"centre": Vector2(18.0, 4.0), "radius": 6.0},
		{"centre": Vector2(19.0, -18.0), "radius": 5.3},
	]:
		var footprint := _vegetation_entry("footprints", expected.centre)
		assert_true(float(footprint.get("radius", 0.0)) >= float(expected.radius),
			"the moved building at %s rejects even clearing-exempt ground cover" % expected.centre)


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
	assert_eq(shop.find_children("*", "Label3D", true, false).size(), 0,
		"Mira's shop presentation contains no label billboard")
	shop.free()
