extends "res://tests/test_case.gd"

## F38 village stands (close-1024): the trodden-earth path albedo shipped OFF
## until the GPU pass judged it (MH6, +0.56 / +0.56). It is ON only with its
## GPU evidence recorded beside the switch, and its derived texture is
## installed at the Terrain3D array's 1024 size.

const CONFIG := "res://data/config/terrain_presentation.json"


func test_path_candidate_is_on_only_with_gpu_evidence_and_is_installed() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var path: Dictionary = ((parsed as Dictionary).get("texture_candidates", {}) as Dictionary).get("path", {})
	assert_true(bool(path.get("enabled", false)), "path candidate ON after GPU MH6")
	assert_true(str(path.get("_why_on", "")).contains("GPU MH6"), "ON carries its GPU verdict")
	var albedo := str(path.get("albedo", ""))
	assert_true(ResourceLoader.exists(albedo), "installed: " + albedo)
	var texture := load(albedo) as Texture2D
	assert_eq(Vector2i(texture.get_size()), Vector2i(1024, 1024), "same size as the terrain texture array")
