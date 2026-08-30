extends SceneTree

## CAN YOU SEE THE STREAM FROM ITS OWN BANK? Answered analytically, in seconds,
## against `playground_heightfield.gd` rather than against a render.
##
##   godot --headless --path . --script tools/_probe_stream_sightline.gd
##
## The stream has now failed the same complaint twice -- "the capture stands at
## the stream's authored bank point and the frame shows only meadow grass"
## (JUDGE-VISUAL-2026-08-29 subject 6), then again after T1-GROUND-2 wired the
## missing bank reeds. Both rounds cost a full boot-and-render to find out. The
## question is pure geometry, though: from the eye the capture tool actually
## poses, is the line to the water surface clear, or does the ground in between
## rise through it?
##
## The heightfield reads `terrain_playground.json` directly and needs no baked
## terrain, so this answers in seconds against edited config -- which means the
## channel's cross-section can be tuned to a PASS before a single region is
## re-baked, instead of after.
##
## The camera stand is not invented here. It is recomputed exactly as
## `tools/_capture_ground_and_sky.gd::_capture_stream` and `_arrive_water` do:
## the middle authored point, the perpendicular to the local flow, the bank at
## `width/2 + shoulder + 6.0` out, and the camera a further `WATER_BACK` behind
## it looking back at the centreline.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

## `_capture_ground_and_sky.gd`'s own constants, mirrored. If either moves
## there, this probe is answering about a camera that no longer exists.
const WATER_BACK := 2.0
const EYE_HEIGHT := 1.6

## Samples along the sightline. The channel is metres wide, so decimetre
## resolution is far finer than anything that could occlude it.
const STEPS := 240

## grass_field.json height_near..height_far; the mid of that range is what a
## blade between the eye and the water actually stands.
const GRASS_HEIGHT := 0.51


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--sweep":
			_sweep()
			quit(0)
			return
	_one(HEIGHTFIELD.load_config(), true)
	quit(0)


## Tightest clearance over a grid of cross-sections, so the channel can be
## tuned to a PASS before a single region is re-baked. The bar is not zero:
## the grass field's blades run 0.40-0.62m and the field only stands off the
## water by `width/2 + shoulder`, so anywhere the sightline clears the GROUND
## by less than a blade's height it is still occluded -- by grass, which a
## ground-only geometry check would have called a pass. `shoulder` is in the
## sweep for exactly that reason: it is the one number that moves where the
## grass stops, and widening the carve without it buys a channel you still
## cannot see across.
func _sweep() -> void:
	var base := HEIGHTFIELD.load_config()
	print("tightest sightline clearance, metres. Needs to beat the grass it")
	print("looks across: blades are 0.40-0.62m and stand off the water by")
	print("width/2 + shoulder, so a value under ~0.62 near the blade line is")
	print("a pass on the ground and a fail in the frame.")
	print("")
	print("  depth  carve  water shoulder  over-gnd over-grass  (at offset)")
	for spec: Array in [
		[0.7, 5.0, 2.4, 1.2],
		[1.1, 12.0, 3.4, 1.2],
		[1.1, 16.0, 3.4, 1.2], [1.4, 16.0, 3.4, 1.2], [1.4, 20.0, 3.4, 1.2],
		[1.1, 16.0, 5.0, 1.2], [1.4, 16.0, 5.0, 1.2], [1.4, 20.0, 5.0, 1.2],
		[1.4, 20.0, 6.5, 1.2], [1.7, 20.0, 6.5, 1.2], [1.4, 24.0, 6.5, 1.2],
		[1.4, 20.0, 5.0, 2.6], [1.4, 24.0, 5.0, 2.6], [1.7, 24.0, 6.5, 2.6],
	]:
		var cfg := base.duplicate(true)
		var stream: Dictionary = cfg["water"]["stream"]
		stream["carve_depth"] = spec[0]
		stream["carve_width"] = spec[1]
		stream["width"] = spec[2]
		stream["shoulder"] = spec[3]
		var got := _one(cfg, false)
		print("  %5.2f  %5.1f  %5.1f %8.1f  %8.3f %8.3f   %.2fm off%s" % [
			spec[0], spec[1], spec[2], spec[3],
			got["worst"], got["worst_grass"], got["worst_grass_at"],
			"   <- today" if spec[0] == 0.7 else ""])


func _one(config: Dictionary, verbose: bool) -> Dictionary:
	var field := HEIGHTFIELD.new(config)
	var stream: Dictionary = config.get("water", {}).get("stream", {})
	var points: Array = stream.get("points", [])
	if points.size() < 3:
		print("no usable water.stream.points")
		return {"worst": 0.0, "worst_at": 0.0}

	var width := float(stream.get("width", 2.4))
	var shoulder := float(stream.get("shoulder", 1.2))
	var carve_depth := float(stream.get("carve_depth", 0.7))
	var carve_width := float(stream.get("carve_width", 5.0))
	var surface_depth := float(_load_json("res://data/config/water.json")
		.get("stream", {}).get("surface_depth", 0.35))
	if verbose:
		print("stream cross-section: water %.1fm wide, carve %.2fm deep over %.1fm, surface %.2fm above bed" % [
			width, carve_depth, carve_width, surface_depth])

	var idx := clampi(points.size() / 2, 1, points.size() - 2)
	var centre := _vec(points[idx])
	var flow := (_vec(points[idx + 1]) - _vec(points[idx - 1])).normalized()
	var perp := Vector2(-flow.y, flow.x)
	var half_width := width * 0.5 + shoulder
	var bank := centre + perp * (half_width + 6.0)
	var cam_xz := bank + (bank - centre).normalized() * WATER_BACK

	var bed: float = field.height_at(centre.x, centre.y)
	var water_y := bed + surface_depth
	var eye_ground: float = field.height_at(cam_xz.x, cam_xz.y)
	var eye := Vector3(cam_xz.x, eye_ground + EYE_HEIGHT, cam_xz.y)
	if verbose:
		print("  centreline (%.1f, %.1f) bed %.3fm, water surface %.3fm" % [
			centre.x, centre.y, bed, water_y])
		print("  bank stand %.1fm off the centreline, ground %.3fm" % [
			bank.distance_to(centre), field.height_at(bank.x, bank.y)])
		print("  camera %.1fm off, ground %.3fm, eye %.3fm" % [
			cam_xz.distance_to(centre), eye_ground, eye.y])

	# The cross-section the player is actually looking across, and the sightline
	# over it. `clearance` is how far the eye-to-water ray passes ABOVE the
	# ground at each step: negative anywhere means the ground occludes the
	# water and the frame shows meadow, which is the reported defect stated as
	# a number.
	var target := Vector3(centre.x, water_y, centre.y)
	var worst := INF
	var worst_at := 0.0
	# The occluder is not the ground, it is the ground PLUS whatever stands on
	# it. grass_field.json's blades run height_near 0.40 to height_far 0.62m
	# and the field only stands off the water by `stream_factor`'s own
	# half-width (width/2 + shoulder) -- so a sightline that clears the dirt by
	# 20cm at 5m off is looking straight into half a metre of grass, and a
	# ground-only check calls that a pass. This is the number that decides.
	var grass_free := half_width
	var worst_grass := INF
	var worst_grass_at := 0.0
	if verbose:
		print("")
		print("  offset   ground   sightline   clearance")
	for i in STEPS + 1:
		var t := float(i) / float(STEPS)
		var at := eye.lerp(target, t)
		var ground: float = field.height_at(at.x, at.z)
		var clearance := at.y - ground
		var off := Vector2(at.x, at.z).distance_to(centre)
		if t > 0.02 and clearance < worst:
			worst = clearance
			worst_at = off
		var over_grass: float = clearance - (0.0 if off <= grass_free else GRASS_HEIGHT)
		if t > 0.02 and over_grass < worst_grass:
			worst_grass = over_grass
			worst_grass_at = off
		if verbose and i % 20 == 0:
			print("  %6.2fm %8.3f %11.3f %11.3f" % [off, ground, at.y, clearance])

	if not verbose:
		return {"worst": worst, "worst_at": worst_at,
			"worst_grass": worst_grass, "worst_grass_at": worst_grass_at}
	print("")
	print("  tightest clearance %.3fm, at %.2fm off the centreline" % [worst, worst_at])
	if worst > 0.15:
		print("  VERDICT: the water surface is VISIBLE from the capture's own stand.")
	elif worst > 0.0:
		print("  VERDICT: marginal -- clear by less than 15cm, which grass will close.")
	else:
		print("  VERDICT: OCCLUDED. The ground rises %.3fm through the sightline." % -worst)
		print("  Widen `carve_width` (moves the rim back and opens the cross-section)")
		print("  before reaching for `carve_depth`, which hides the water further down.")
	print("  tightest clearance over GROUND+GRASS %.3fm, at %.2fm off" % [
		worst_grass, worst_grass_at])
	return {"worst": worst, "worst_at": worst_at,
		"worst_grass": worst_grass, "worst_grass_at": worst_grass_at}


func _vec(raw: Variant) -> Vector2:
	var arr: Array = raw
	return Vector2(float(arr[0]), float(arr[1]))


func _load_json(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}
