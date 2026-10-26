extends "res://tests/test_case.gd"

## F38 village stands (close-1024): the trodden-earth path albedo ships OFF
## until the GPU pass judges it, and its derived texture is installed at the
## Terrain3D array's 1024 size, so turning it on is config only.

const CONFIG := "res://data/config/terrain_presentation.json"


func test_path_candidate_ships_off_and_is_installed() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var path: Dictionary = ((parsed as Dictionary).get("texture_candidates", {}) as Dictionary).get("path", {})
	assert_false(bool(path.get("enabled", true)), "path candidate OFF until judged")
	var albedo := str(path.get("albedo", ""))
	assert_true(ResourceLoader.exists(albedo), "installed: " + albedo)
	var texture := load(albedo) as Texture2D
	assert_eq(Vector2i(texture.get_size()), Vector2i(1024, 1024), "same size as the terrain texture array")
