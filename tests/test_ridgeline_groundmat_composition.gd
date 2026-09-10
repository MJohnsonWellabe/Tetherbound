extends "res://tests/test_case.gd"

const VEGETATION := preload("res://scripts/world/vegetation.gd")
const RULES := preload("res://scripts/world/scatter_rules.gd")
const BAKE := preload("res://scripts/world/scatter_bake.gd")
const CLOVER_1 := "res://assets/environment/stylized_nature/Clover_1.gltf"
const CLOVER_2 := "res://assets/environment/stylized_nature/Clover_2.gltf"
const PLANT := "res://assets/environment/stylized_nature/Plant_1_Big.gltf"


class FieldFixture extends RefCounted:
	var path_value := 0.0
	var stream_value := 0.0
	var river_value := 0.0
	var height_calls := 0

	func height_at(x: float, z: float) -> float:
		height_calls += 1
		return x * 0.01 + z * 0.001

	func slope_degrees_at(_x: float, _z: float, _step: float = 1.0) -> float:
		return 2.0

	func path_factor(_x: float, _z: float) -> float:
		return path_value

	func stream_factor(_x: float, _z: float) -> float:
		return stream_value

	func river_factor(_x: float, _z: float) -> float:
		return river_value

	func nearest_point_on_paths(_x: float, _z: float) -> Vector2:
		return Vector2.INF

	func water_level() -> float:
		return -100.0


func _config() -> Dictionary:
	var file := FileAccess.open(VEGETATION.RIDGELINE_GROUNDMAT_VISUAL_PATH, FileAccess.READ)
	assert_true(file != null, "runtime-only Ridgeline composition config is missing")
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else {}
	if file != null:
		file.close()
	assert_true(parsed is Dictionary, "Ridgeline composition config is not a JSON object")
	return parsed as Dictionary


func _subject(field: FieldFixture = FieldFixture.new()) -> Node3D:
	var subject := VEGETATION.new()
	subject.set("_field", field)
	subject.set("_ridgeline_groundmat_visual", _config())
	subject.set("_footprint_radii", {CLOVER_1: 0.42, CLOVER_2: 0.44, PLANT: 1.56})
	return subject


func _placement(position: Vector3, scale: float = 0.35) -> Dictionary:
	return {"position": position, "scale": scale, "yaw": 0.4, "model": CLOVER_1}


func _groundmat_layer() -> Dictionary:
	return RULES.config().get("layers", {}).get("groundmat", {})


func test_runtime_config_does_not_invalidate_the_committed_scatter_bake() -> void:
	var seed := int(RULES.config().get("seed", -1))
	assert_true(BAKE.is_fresh("playground", seed),
		"adding the separate presentation config changed a fingerprint input or the committed bake was already stale")
	assert_false(VEGETATION.RIDGELINE_GROUNDMAT_VISUAL_PATH.contains("vegetation.json"),
		"the presentation config must remain outside the scatter fingerprint inputs")


func test_only_the_two_clovers_inside_the_zone_move() -> void:
	var field := FieldFixture.new()
	var subject := _subject(field)
	var original := Vector3(-230.0, 5.0, 6518.0)
	var moved: Vector3 = subject.call("_ridgeline_groundmat_position", CLOVER_1, _placement(original), _groundmat_layer())
	assert_ne(moved, original, "an eligible Clover_1 inside Ridgeline should compose")
	var moved_two: Vector3 = subject.call("_ridgeline_groundmat_position", CLOVER_2, _placement(original), _groundmat_layer())
	assert_ne(moved_two, original, "an eligible Clover_2 inside Ridgeline should compose")
	var calls_before_noops := field.height_calls
	var plant: Vector3 = subject.call("_ridgeline_groundmat_position", PLANT, _placement(original), _groundmat_layer())
	assert_eq(plant, original, "Plant_1_Big must retain its baked transform")
	var outside := Vector3(-250.0, 5.0, 6600.0)
	assert_eq(subject.call("_ridgeline_groundmat_position", CLOVER_1, _placement(outside), _groundmat_layer()), outside,
		"a clover outside the local zone must retain its exact baked transform")
	assert_eq(field.height_calls, calls_before_noops,
		"outside-zone clovers and non-clover models must not pay for terrain validation")
	subject.free()


func test_composition_is_bounded_and_preserves_the_terrain_offset() -> void:
	var field := FieldFixture.new()
	var subject := _subject(field)
	var ground := field.height_at(-230.0, 6518.0)
	var original := Vector3(-230.0, ground + 0.37, 6518.0)
	var moved: Vector3 = subject.call("_ridgeline_groundmat_position", CLOVER_1, _placement(original), _groundmat_layer())
	var displacement := Vector2(original.x, original.z).distance_to(Vector2(moved.x, moved.z))
	assert_between(displacement, 0.001, 6.0, "the local compositor may move an eligible clover by at most six metres")
	assert_almost_eq(moved.y - field.height_at(moved.x, moved.z), 0.37, 0.0001,
		"the clover's baked terrain offset must survive the XZ composition")
	subject.free()


func test_invalid_route_or_rock_destination_falls_back_exactly() -> void:
	var field := FieldFixture.new()
	field.path_value = 0.03
	var subject := _subject(field)
	var original := Vector3(-230.0, 5.0, 6518.0)
	assert_eq(subject.call("_ridgeline_groundmat_position", CLOVER_1, _placement(original), _groundmat_layer()), original,
		"a displayed destination over the conservative path threshold must use the exact baked point")
	field.path_value = 0.0
	var clear_position: Vector3 = subject.call("_ridgeline_groundmat_position", CLOVER_1, _placement(original), _groundmat_layer())
	var exclusions: Array = subject.get("_ridgeline_rock_exclusions")
	exclusions.append({"centre": Vector2(clear_position.x, clear_position.z), "radius": 1.0})
	assert_eq(subject.call("_ridgeline_groundmat_position", CLOVER_1, _placement(original), _groundmat_layer()), original,
		"a displayed destination overlapping a cached rock footprint must use the exact baked point")
	subject.free()


func test_zone_feather_reaches_an_exact_zero_at_the_boundary() -> void:
	var subject := _subject()
	var boundary := Vector3(-250.0, 5.0, 6590.0)
	assert_eq(subject.call("_ridgeline_groundmat_position", CLOVER_1, _placement(boundary), _groundmat_layer()), boundary,
		"the zone boundary must return the exact baked point")
	var near_edge := Vector3(-250.0, 5.0, 6589.0)
	var moved: Vector3 = subject.call("_ridgeline_groundmat_position", CLOVER_1, _placement(near_edge), _groundmat_layer())
	var inner := Vector3(-250.0, 5.0, 6583.0)
	var inner_moved: Vector3 = subject.call("_ridgeline_groundmat_position", CLOVER_1, _placement(inner), _groundmat_layer())
	var near_displacement := Vector2(near_edge.x, near_edge.z).distance_to(Vector2(moved.x, moved.z))
	var inner_displacement := Vector2(inner.x, inner.z).distance_to(Vector2(inner_moved.x, inner_moved.z))
	assert_true(near_displacement > 0.0 and near_displacement < inner_displacement,
		"the smooth feather should reduce displacement continuously on approach to its exact-zero boundary")
	subject.free()
