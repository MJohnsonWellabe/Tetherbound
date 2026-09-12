extends "res://tests/test_case.gd"

## The Rise's discovery tree is a visual pull toward the TM cache, not a shell
## around it. `props.gd` gives every authored prop a collider from the imported
## mesh's full AABB, so a centre-to-centre check or a guessed trunk radius is not
## enough: DeadTree_2 has broad asymmetric branches, and the old shared x/z put
## every legal interaction seat inside that box.

const WORLD := preload("res://scripts/world/playground_world.gd")
const PROPS_PATH := "res://data/config/bands/band1_lower_meadows/props.json"
const MARKER_MODEL_PATH := "res://assets/environment/stylized_nature/DeadTree_2.gltf"
const MARKER_CLUSTER := "rise_cache_marker"
const MARKER_MODEL := "DeadTree_2"
const CACHE_ID := "tm_rock_throw"
const PROMPT_REACH_M := 2.4


func test_marker_full_aabb_clears_the_tm_interaction_circle() -> void:
	var marker := _marker_spec()
	assert_false(marker.is_empty(), "Rise cache marker is still authored")
	if marker.is_empty():
		return
	assert_eq(str(marker.get("model", "")), MARKER_MODEL,
		"clearance calculation follows the installed production marker")
	var at: Array = marker.get("at", [])
	assert_eq(at.size(), 2, "marker has one world x/z point")
	if at.size() != 2:
		return
	var marker_at := Vector2(float(at[0]), float(at[1]))
	var cache_at: Vector2 = WORLD.CACHE_AT.get(CACHE_ID, Vector2.INF)
	assert_true(cache_at.is_finite(), "production TM cache coordinate exists")
	var marker_extent := _model_farthest_horizontal_extent() \
		* float(marker.get("scale", 1.0))
	assert_true(marker_extent > 0.0, "installed marker exposes finite mesh bounds")
	var separation := marker_at.distance_to(cache_at)
	assert_true(separation > marker_extent + PROMPT_REACH_M,
		("marker/cache separation %.2fm must exceed full marker extent %.2fm " \
		+ "+ the production %.1fm prompt reach") % [
			separation, marker_extent, PROMPT_REACH_M])


func _marker_spec() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROPS_PATH))
	if not parsed is Dictionary:
		return {}
	for raw_cluster: Variant in (parsed as Dictionary).get("clusters", []):
		if not raw_cluster is Dictionary \
				or str((raw_cluster as Dictionary).get("name", "")) != MARKER_CLUSTER:
			continue
		for raw_prop: Variant in (raw_cluster as Dictionary).get("props", []):
			if raw_prop is Dictionary and str((raw_prop as Dictionary).get("model", "")) == MARKER_MODEL:
				return raw_prop as Dictionary
	return {}


func _model_farthest_horizontal_extent() -> float:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MARKER_MODEL_PATH))
	if not parsed is Dictionary:
		return 0.0
	var gltf := parsed as Dictionary
	var accessors: Array = gltf.get("accessors", [])
	var farthest := 0.0
	for raw_mesh: Variant in gltf.get("meshes", []):
		if not raw_mesh is Dictionary:
			continue
		for raw_primitive: Variant in (raw_mesh as Dictionary).get("primitives", []):
			if not raw_primitive is Dictionary:
				continue
			var attributes: Dictionary = (raw_primitive as Dictionary).get("attributes", {})
			var accessor_index := int(attributes.get("POSITION", -1))
			if accessor_index < 0 or accessor_index >= accessors.size() \
					or not accessors[accessor_index] is Dictionary:
				continue
			var accessor := accessors[accessor_index] as Dictionary
			var minimum: Array = accessor.get("min", [])
			var maximum: Array = accessor.get("max", [])
			if minimum.size() < 3 or maximum.size() < 3:
				continue
			for x: float in [float(minimum[0]), float(maximum[0])]:
				for z: float in [float(minimum[2]), float(maximum[2])]:
					farthest = maxf(farthest, Vector2(x, z).length())
	return farthest
