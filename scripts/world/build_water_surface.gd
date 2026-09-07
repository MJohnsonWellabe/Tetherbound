extends SceneTree

const FIELD := preload("res://scripts/world/water_heightfield.gd")


func _init() -> void:
	var config := FIELD.load_config()
	var visual: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_visual.json"))
	var field := FIELD.new(config)
	var bounds: Dictionary = config.world_bounds
	var spacing := float(visual.water.height_texture_spacing_m)
	var width := ceili((float(bounds.max_x) - float(bounds.min_x)) / spacing)
	var height := ceili((float(bounds.max_z) - float(bounds.min_z)) / spacing)
	var image := Image.create_empty(width, height, false, Image.FORMAT_RF)
	var low := float(bounds.min_y)
	var high := float(bounds.max_y)
	for z in height:
		for x in width:
			var wx := float(bounds.min_x) + (x + 0.5) * spacing
			var wz := float(bounds.min_z) + (z + 0.5) * spacing
			image.set_pixel(x, z, Color(clampf((field.height_at(wx, wz) - low) / (high - low), 0.0, 1.0), 0, 0, 1))
	var result := ResourceSaver.save(image, "res://data/terrain/water/surface_height.res", ResourceSaver.FLAG_COMPRESS)
	print("Water surface height image %dx%d, save=%d" % [width, height, result])
	quit(0 if result == OK else 1)
