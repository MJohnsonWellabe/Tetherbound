extends "res://tests/test_case.gd"

## OWNER-0912 / C3 village replan regression coverage. The opening settlement
## is a five-person street, not a ring of idle bodies around the well. The
## south-leg buildings require their own baked-terrain slice; this file first
## pins the independent no-bake work: the west leg and the people distribution.

const BOUNDARY := preload("res://scripts/world/village_boundary.gd")
const VILLAGE_PATH := "res://data/config/village.json"
const PEOPLE_PATH := "res://data/config/village_npcs.json"
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


func test_west_leg_buildings_and_thresholds_follow_the_street() -> void:
	var inn := _structure("inn")
	var cottage := _structure("cottage_b")
	assert_eq(inn.get("at", []), [-6.0, -14.0], "the inn fronts the west street leg")
	assert_eq(float(inn.get("yaw_deg", 0.0)), 90.0, "the inn door faces east along the street")
	assert_eq(cottage.get("at", []), [19.0, -18.0], "the stone cottage frames the bend")
	assert_eq(float(cottage.get("yaw_deg", 0.0)), -110.0, "the cottage door turns back toward the street")
	var doorstep_positions: Array[Vector2] = []
	for raw: Variant in (_json(VILLAGE_PATH).get("structures", []) as Array):
		if raw is Dictionary and str((raw as Dictionary).get("prefab", "")) == "doorstep":
			var at: Array = (raw as Dictionary).get("at", []) as Array
			doorstep_positions.append(Vector2(float(at[0]), float(at[1])))
	assert_true(Vector2(0.1, -14.0) in doorstep_positions, "the inn threshold moved with its door")
	assert_true(Vector2(15.72, -18.13) in doorstep_positions, "the cottage threshold moved with its door")


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
