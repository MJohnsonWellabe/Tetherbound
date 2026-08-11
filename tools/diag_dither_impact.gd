extends SceneTree

## SCRATCH — counts how many of the ~512x512 baked pixels the new dither-based
## _path_control actually changes vs the old hard >=0.5 threshold. Deleted
## before shipping.

const Heightfield = preload("res://scripts/world/playground_heightfield.gd")


func _control_for(slope_degrees: float, cfg: Dictionary, ids: Dictionary) -> Dictionary:
	var soil_at := float(cfg.get("soil_slope_deg", 24.0))
	var rock_at := float(cfg.get("rock_slope_deg", 38.0))
	var blend := maxf(0.001, float(cfg.get("blend_deg", 7.0)))
	var grass: int = ids["grass"]
	var soil: int = ids["soil"]
	var rock: int = ids["rock"]
	if slope_degrees <= soil_at:
		return {"base": grass, "overlay": soil, "blend": 0.0}
	if slope_degrees < soil_at + blend:
		return {"base": grass, "overlay": soil, "blend": smoothstep(soil_at, soil_at + blend, slope_degrees)}
	if slope_degrees <= rock_at:
		return {"base": soil, "overlay": rock, "blend": 0.0}
	if slope_degrees < rock_at + blend:
		return {"base": soil, "overlay": rock, "blend": smoothstep(rock_at, rock_at + blend, slope_degrees)}
	return {"base": rock, "overlay": rock, "blend": 0.0}


func _path_control_old(natural: Dictionary, path_weight: float, ids: Dictionary) -> Dictionary:
	var path_tex: int = int(ids.get("path", ids["soil"]))
	if path_weight >= 0.999:
		return {"base": path_tex, "overlay": path_tex, "blend": 0.0}
	var dominant: int = natural["overlay"] if float(natural["blend"]) >= 0.5 else natural["base"]
	if dominant == path_tex:
		return {"base": path_tex, "overlay": path_tex, "blend": 0.0}
	return {"base": path_tex, "overlay": dominant, "blend": 1.0 - path_weight}


func _path_control_new(natural: Dictionary, path_weight: float, ids: Dictionary, dither: float) -> Dictionary:
	var path_tex: int = int(ids.get("path", ids["soil"]))
	if path_weight >= 0.999:
		return {"base": path_tex, "overlay": path_tex, "blend": 0.0}
	var dominant: int = natural["overlay"] if float(natural["blend"]) >= dither else natural["base"]
	if dominant == path_tex:
		return {"base": path_tex, "overlay": path_tex, "blend": 0.0}
	return {"base": path_tex, "overlay": dominant, "blend": 1.0 - path_weight}


func _init() -> void:
	var config: Dictionary = Heightfield.load_config()
	var field = Heightfield.new(config)
	var colour_cfg: Dictionary = config.get("colour", {})
	var textures: Array = config.get("textures", [])
	var ids := {}
	for i in textures.size():
		ids[str(textures[i].get("name", ""))] = i

	var world_size := int(config.get("world_size", 512))
	var spacing := float(config.get("vertex_spacing", 1.0))
	var size := int(world_size / spacing)
	var origin := -0.5 * size * spacing

	var painted := 0
	var fractional_pw := 0
	var natural_in_transition_and_fractional_pw := 0
	var differs := 0
	var first_diffs: Array[String] = []

	for pixel_z in size:
		var world_z := origin + pixel_z * spacing
		for pixel_x in size:
			var world_x := origin + pixel_x * spacing
			var slope: float = field.slope_degrees_at(world_x, world_z, spacing)
			var natural := _control_for(slope, colour_cfg, ids)
			var pw: float = field.path_factor(world_x, world_z)
			if pw <= 0.0:
				continue
			painted += 1
			if pw < 0.999:
				fractional_pw += 1
				if float(natural["blend"]) > 0.001 and float(natural["blend"]) < 0.999:
					natural_in_transition_and_fractional_pw += 1
			var dither: float = field.path_dominant_dither(world_x, world_z)
			var old_c := _path_control_old(natural, pw, ids)
			var new_c := _path_control_new(natural, pw, ids, dither)
			if float(natural["blend"]) > 0.001 and float(natural["blend"]) < 0.999 and first_diffs.size() < 30:
				first_diffs.append("x=%.1f z=%.1f slope=%.2f pw=%.3f natural_blend=%.3f dither=%.3f old(ov=%d,bl=%.3f) new(ov=%d,bl=%.3f)" % [
					world_x, world_z, slope, pw, natural["blend"], dither,
					old_c["overlay"], old_c["blend"], new_c["overlay"], new_c["blend"]
				])
			if old_c["overlay"] != new_c["overlay"] or absf(old_c["blend"] - new_c["blend"]) > 0.0001:
				differs += 1

	print("painted pixels: %d" % painted)
	print("fractional path_weight pixels (in fade band): %d" % fractional_pw)
	print("fade-band pixels where natural blend is ALSO fractional (the overlap zone): %d" % natural_in_transition_and_fractional_pw)
	print("pixels where old vs new _path_control actually DIFFER: %d" % differs)
	print("")
	for line in first_diffs:
		print(line)

	quit(0)
