extends SceneTree

## F38 L4 / P2-005 (close-1024): writes the OFF candidate colour maps for the
## Meadows terrain. Colour only: it reads each shipped region's own colour and
## height maps and writes a varied copy of the colour map as a PNG beside
## nothing else. Heights, control, collision, vegetation placement and the bake
## fingerprints are untouched; `meadows_colour_candidate.gd` swaps these in at
## runtime only while `terrain_presentation.json colour_candidate.enabled`.
##
## Usage: godot --headless --path . --script tools/bake_meadows_colour_candidate.gd

const SOURCE_DIR := "res://data/terrain/playground"
const PRESENTATION := "res://data/config/terrain_presentation.json"


func _initialize() -> void:
	var cfg: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(PRESENTATION)) as Dictionary).get("colour_candidate", {})
	var out_dir := str(cfg.get("dir", "res://data/terrain/playground_colour_candidate"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var clover := _noise(int(cfg.get("seed", 2205)), 1.0 / float(cfg.get("clover_scale_m", 14.0)))
	var moss := _noise(int(cfg.get("seed", 2205)) + 17, 1.0 / float(cfg.get("moss_scale_m", 22.0)))
	var spacing := float(cfg.get("vertex_spacing", 2.0))
	var written := 0
	for file: String in DirAccess.get_files_at(SOURCE_DIR):
		if not file.ends_with(".res"):
			continue
		var region: Resource = ResourceLoader.load(SOURCE_DIR.path_join(file), "", ResourceLoader.CACHE_MODE_IGNORE)
		if region == null:
			continue
		var location: Vector2i = region.get("location")
		var colour: Image = (region.get("color_map") as Image).duplicate()
		var height: Image = region.get("height_map")
		if colour.is_compressed():
			colour.decompress()
		if colour.has_mipmaps():
			colour.clear_mipmaps()
		colour.convert(Image.FORMAT_RGBA8)
		_vary(colour, height, location, spacing, clover, moss, cfg)
		colour.save_png(ProjectSettings.globalize_path(out_dir.path_join("colour_%d_%d.png" % [location.x, location.y])))
		written += 1
	print("meadows colour candidate: %d region colour maps -> %s" % [written, out_dir])
	quit(0 if written > 0 else 1)


static func _noise(seed: int, frequency: float) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	noise.fractal_octaves = 2
	return noise


## Per pixel, in the colour map's own multiplier space (near white):
## clover patches lean cool green, moss/value breaks darken, existing soil
## (paths, aprons) spreads a soft worn halo, and steep ground (outcrop bases)
## greys and darkens. Alpha (Terrain3D's roughness channel) is preserved.
static func _vary(colour: Image, height: Image, location: Vector2i, spacing: float,
		clover: FastNoiseLite, moss: FastNoiseLite, cfg: Dictionary) -> void:
	var size := colour.get_size()
	var source := colour.duplicate() as Image
	var soil := Color(str(cfg.get("soil_reference", "#d1b37e")))
	var clover_tint := Color(str(cfg.get("clover_tint", "#c4dbb0")))
	var moss_tint := Color(str(cfg.get("moss_tint", "#a9bd8e")))
	var worn_tint := Color(str(cfg.get("worn_tint", "#d8c49a")))
	var rock_tint := Color(str(cfg.get("rock_tint", "#b3b1a6")))
	var clover_amount := float(cfg.get("clover_strength", 0.55))
	var moss_amount := float(cfg.get("moss_strength", 0.4))
	var worn_amount := float(cfg.get("worn_strength", 0.45))
	var rock_amount := float(cfg.get("rock_strength", 0.45))
	var worn_reach := int(cfg.get("worn_reach_px", 2))
	var rock_start := deg_to_rad(float(cfg.get("rock_start_deg", 18.0)))
	var rock_full := deg_to_rad(float(cfg.get("rock_full_deg", 32.0)))
	# Soil mask once, then a separable max dilation for the worn halo.
	var soil_mask := PackedFloat32Array()
	soil_mask.resize(size.x * size.y)
	for z in size.y:
		for x in size.x:
			soil_mask[z * size.x + x] = _soilness(source.get_pixel(x, z), soil)
	var near := _dilate(_dilate(soil_mask, size, worn_reach, true), size, worn_reach, false)
	for z in size.y:
		for x in size.x:
			var c := source.get_pixel(x, z)
			var wx := (location.x * size.x + x) * spacing
			var wz := (location.y * size.y + z) * spacing
			var soil_here := soil_mask[z * size.x + x]
			var out := c
			if soil_here < 0.5:
				var cl := smoothstep(0.15, 0.45, clover.get_noise_2d(wx, wz))
				var ms := smoothstep(0.2, 0.55, moss.get_noise_2d(wx, wz))
				out = out.lerp(Color(c.r * clover_tint.r, c.g * clover_tint.g, c.b * clover_tint.b, c.a), cl * clover_amount)
				out = out.lerp(Color(c.r * moss_tint.r, c.g * moss_tint.g, c.b * moss_tint.b, c.a), ms * moss_amount)
				out = out.lerp(Color(worn_tint.r, worn_tint.g, worn_tint.b, c.a), near[z * size.x + x] * (1.0 - soil_here) * worn_amount)
			var steep := smoothstep(rock_start, rock_full, _slope(height, x, z, spacing))
			if steep > 0.0:
				out = out.lerp(Color(c.r * rock_tint.r, c.g * rock_tint.g, c.b * rock_tint.b, c.a), steep * rock_amount)
			out.a = c.a
			colour.set_pixel(x, z, out)


static func _dilate(values: PackedFloat32Array, size: Vector2i, reach: int, horizontal: bool) -> PackedFloat32Array:
	var out := values.duplicate()
	for z in size.y:
		for x in size.x:
			var best := 0.0
			for d in range(-reach, reach + 1):
				var sx := clampi(x + d, 0, size.x - 1) if horizontal else x
				var sz := z if horizontal else clampi(z + d, 0, size.y - 1)
				best = maxf(best, values[sz * size.x + sx])
			out[z * size.x + x] = best
	return out


## 0 for ground far from the bake's soil tone, 1 at it.
static func _soilness(c: Color, soil: Color) -> float:
	var d := Vector3(c.r - soil.r, c.g - soil.g, c.b - soil.b).length()
	return 1.0 - smoothstep(0.06, 0.18, d)


static func _slope(height: Image, x: int, z: int, spacing: float) -> float:
	var size := height.get_size()
	var x0 := clampi(x - 1, 0, size.x - 1)
	var x1 := clampi(x + 1, 0, size.x - 1)
	var z0 := clampi(z - 1, 0, size.y - 1)
	var z1 := clampi(z + 1, 0, size.y - 1)
	var dx := (height.get_pixel(x1, z).r - height.get_pixel(x0, z).r) / (spacing * float(x1 - x0))
	var dz := (height.get_pixel(x, z1).r - height.get_pixel(x, z0).r) / (spacing * float(z1 - z0))
	return atan(sqrt(dx * dx + dz * dz))
