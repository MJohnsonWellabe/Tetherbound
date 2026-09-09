extends SceneTree

## Loads the exact shared Terrain3D source textures used across the four biomes
## and verifies both the tracked import policy and the initialized resources.

const TEXTURES: Array[String] = [
	"res://assets/environment/terrain/stylised/meadow_grass_Color.png",
	"res://assets/environment/terrain/stylised/meadow_grass_NormalGL.png",
	"res://assets/environment/terrain/stylised/verge_grass_Color.png",
	"res://assets/environment/terrain/stylised/verge_grass_NormalGL.png",
	"res://assets/environment/terrain/stylised/rock_scree_Color.png",
	"res://assets/environment/terrain/stylised/rock_scree_NormalGL.png",
	"res://assets/environment/terrain/stylised/dirt_path_Color.png",
	"res://assets/environment/terrain/stylised/dirt_path_NormalGL.png",
	"res://assets/environment/terrain/stylised/wet_earth_Color.png",
	"res://assets/environment/terrain/stylised/wet_earth_NormalGL.png",
	"res://assets/environment/terrain/stylised/forest_floor_Color.png",
	"res://assets/environment/terrain/stylised/forest_floor_NormalGL.png",
]


func _initialize() -> void:
	var failures: Array[String] = []
	var records: Array[Dictionary] = []
	for path: String in TEXTURES:
		var import_text := FileAccess.get_file_as_string(path + ".import")
		var import_mipmaps := "mipmaps/generate=true" in import_text
		var texture := load(path) as Texture2D
		var image: Image = texture.get_image() if texture != null else null
		var mipmap_count := image.get_mipmap_count() if image != null and not image.is_empty() else -1
		var size := [texture.get_width(), texture.get_height()] if texture != null else []
		records.append({
			"path": path,
			"import_mipmaps": import_mipmaps,
			"resource_class": texture.get_class() if texture != null else "",
			"size": size,
			"image_mipmap_count": mipmap_count,
		})
		if not import_mipmaps:
			failures.append("%s: sidecar does not enable mipmaps" % path)
		if texture == null:
			failures.append("%s: did not load as Texture2D" % path)
		elif image == null or image.is_empty():
			failures.append("%s: initialized texture exposes no image" % path)
		elif mipmap_count <= 0:
			failures.append("%s: initialized image has no mipmaps" % path)
	print("TERRAIN_TEXTURE_MIPMAPS=%s" % JSON.stringify({
		"records": records,
		"failures": failures,
	}))
	quit(0 if failures.is_empty() else 1)
