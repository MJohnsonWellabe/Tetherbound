extends SceneTree

## SCRATCH — instrumenting EV4-textures' "path edges going up a slope read as
## stepped" complaint before guessing at a fix. Deleted before shipping.
##
## Walks "The Rise" route (climbs the hillside toward the rises peak at
## 140,-90) and prints slope/dominant/blend at each metre along the
## centreline and at the path's shoulder edge, to see whether the natural
## grass/soil/rock "dominant" pick flips unevenly as the path climbs.

const Heightfield = preload("res://scripts/world/playground_heightfield.gd")

# Copied verbatim from build_playground_terrain.gd's _control_for/_path_control
# (that file extends SceneTree and re-bakes on instantiation, so it cannot be
# preloaded and .new()'d here without side effects). Read-only diagnostic.


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


func _path_control(natural: Dictionary, path_weight: float, ids: Dictionary) -> Dictionary:
	var path_tex: int = int(ids.get("path", ids["soil"]))
	if path_weight >= 0.999:
		return {"base": path_tex, "overlay": path_tex, "blend": 0.0}
	var dominant: int = natural["overlay"] if float(natural["blend"]) >= 0.5 else natural["base"]
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

	var routes: Array = config.get("paths", {}).get("routes", [])
	var rise_route: Dictionary = {}
	for r in routes:
		if str(r.get("label", "")) == "The Rise":
			rise_route = r
			break
	if rise_route.is_empty():
		print("no Rise route found")
		quit(1)
		return

	var points: Array = rise_route["points"]

	print("=== centreline (path_weight, slope, dominant, blend) ===")
	var prev_dominant := -1
	for i in range(points.size() - 1):
		var a := Vector2(float(points[i][0]), float(points[i][1]))
		var b := Vector2(float(points[i + 1][0]), float(points[i + 1][1]))
		var steps := int(a.distance_to(b))
		for s in steps:
			var t := float(s) / float(steps)
			var p := a.lerp(b, t)
			prev_dominant = _sample(field, colour_cfg, ids, p.x, p.y, "", prev_dominant)

	print("\n=== transverse scan at one point on the rise segment (perpendicular offsets, 0.1m steps) ===")
	# Segment 3: (85,-48) -> (118,-72), well up the slope toward the peak.
	var seg_a := Vector2(85.0, -48.0)
	var seg_b := Vector2(118.0, -72.0)
	var mid := seg_a.lerp(seg_b, 0.5)
	var dir := (seg_b - seg_a).normalized()
	var perp := Vector2(-dir.y, dir.x)
	var prev_dom2 := -1
	for off in range(-40, 41):
		var offset := float(off) * 0.1
		var p := mid + perp * offset
		prev_dom2 = _sample(field, colour_cfg, ids, p.x, p.y, "off=%.1f" % offset, prev_dom2)

	quit(0)


func _sample(field, colour_cfg: Dictionary, ids: Dictionary, x: float, z: float, label: String, prev_dominant: int) -> int:
	var slope: float = field.slope_degrees_at(x, z, 1.0)
	var natural: Dictionary = _control_for(slope, colour_cfg, ids)
	var pw: float = field.path_factor(x, z)
	var control := natural
	if pw > 0.0:
		control = _path_control(natural, pw, ids)
	var dominant: int = natural["overlay"] if float(natural["blend"]) >= 0.5 else natural["base"]
	var flip := " <<< FLIP" if prev_dominant != -1 and dominant != prev_dominant else ""
	print("%s x=%.1f z=%.1f slope=%.2f pw=%.3f dominant=%d natural(b=%d,ov=%d,bl=%.3f) final(b=%d,ov=%d,bl=%.3f)%s" % [
		label, x, z, slope, pw, dominant, natural["base"], natural["overlay"], natural["blend"],
		control["base"], control["overlay"], control["blend"], flip
	])
	return dominant
