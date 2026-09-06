extends SceneTree

## OP-0905-03 (docs/owner/OWNER_PLAYTEST_2026-09-05.md, "Bramblebun colour is
## awful"). Headless numeric coverage for `creature_body.gd`'s field-bright
## soft-knee ceiling -- a real render (`tools/_probe_grass_separation.gd`)
## needs a rendering driver and answers "does this look right against grass";
## this probe needs neither and answers "is the maths honest": does the
## brightened tint ever cross `creatures_visual.json`'s `field_bright_ceiling`,
## and does `field_degreen`'s intentional hue shift stay the shape it was
## tuned to be rather than silently growing or collapsing.
##
## Run (headless, no rendering driver -- this never touches a frame buffer):
##
##   godot --headless --path . --script tools/_probe_field_bright_values.gd
##
## Exits 0 on a clean pass, 1 if any assertion below fails.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const CREATURE_SCENE := "res://scenes/creatures/creature.tscn"
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const VISUAL := preload("res://scripts/creatures/creature_visual.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

const SETTLE_FRAMES := 60
const SPAWN_FRAMES := 30

## Species this lever is shipped on (data/creatures/species.json). Bramblebun
## carries `field_degreen` (an intentional hue shift, away from grass-green);
## Mudsnout/Terrapup do not, so their tint is a plain uniform push and their
## hue must come out exactly unchanged -- the "nothing regresses" control
## group the task brief asked for.
const SPECIES_IDS: PackedStringArray = ["bramblebun", "mudsnout", "terrapup"]

## Relative hue-preservation bound for the no-degreen species (Mudsnout,
## Terrapup): a uniform per-channel multiply can only ever change their hue
## through floating-point noise, so 5% is generous headroom, not a real
## expected shift.
const HUE_PRESERVE_TOLERANCE := 0.05

var _failures: Array[String] = []
var _world: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	CREATURE_BODY.set_field_brightness_scale(1.0)
	var ceiling := VISUAL.field_bright_ceiling()
	print("field_bright_ceiling = %.4f" % ceiling)
	print("")

	for species_id in SPECIES_IDS:
		await _probe_species(species_id, ceiling)
		print("")

	_report()


func _probe_species(species_id: String, ceiling: float) -> void:
	var body: Node3D = (load(CREATURE_SCENE) as PackedScene).instantiate() as Node3D
	body.set_script(CREATURE_BODY)
	body.set("species_id", species_id)
	_world.add_child(body)
	for i in SPAWN_FRAMES:
		await physics_frame

	var material := _first_field_bright_material(body)
	if material == null:
		_fail("%s spawned no _field_bright surface material -- field_emission must be > 0" % species_id)
		body.queue_free()
		return

	var field_emission := float(SPECIES.placeholder(species_id).get("field_emission", 0.0))
	var degreen := float(SPECIES.placeholder(species_id).get("field_degreen", 0.0))

	var tint: Color = material.albedo_color
	var tex_mean: Variant = _texture_mean(material.albedo_texture)
	var tex_max := _texture_max(material.albedo_texture)

	print("== %s (field_emission=%.3f field_degreen=%.3f) ==" % [species_id, field_emission, degreen])
	print("  tint BEFORE (unbrightened, always (1,1,1) on this white-tint colourway): (1.0000, 1.0000, 1.0000)")
	print("  tint AFTER  (albedo_color, the actual field-bright lever output):        (%.4f, %.4f, %.4f)" %
		[tint.r, tint.g, tint.b])
	var tint_max := maxf(tint.r, maxf(tint.g, tint.b))
	print("  tint max channel: %.4f  (ceiling %.4f, margin %.4f)" % [tint_max, ceiling, ceiling - tint_max])

	if tex_mean != null:
		var before: Color = tex_mean
		var after := Color(before.r * tint.r, before.g * tint.g, before.b * tint.b)
		print("  base texture mean (coat colour, unbrightened):  (%.4f, %.4f, %.4f)" %
			[before.r, before.g, before.b])
		print("  base texture max  (brightest sampled pixel):    (%.4f, %.4f, %.4f)" %
			[tex_max.r, tex_max.g, tex_max.b])
		print("  rendered-mean ESTIMATE after brightening:       (%.4f, %.4f, %.4f)" %
			[after.r, after.g, after.b])
		var after_max := maxf(after.r, maxf(after.g, after.b))
		print("  rendered-mean estimate max channel: %.4f  (1.0 = start of ACES clip range)" % after_max)

		var hue_before := _hue_degrees(before.r, before.g, before.b)
		var hue_after := _hue_degrees(after.r, after.g, after.b)
		print("  hue BEFORE: %.2f deg    hue AFTER: %.2f deg    shift: %.2f deg" %
			[hue_before, hue_after, hue_after - hue_before])

		if degreen <= 0.0:
			var rel := absf(hue_after - hue_before) / maxf(hue_before, 0.0001)
			if rel > HUE_PRESERVE_TOLERANCE:
				_fail(("%s: no field_degreen, so hue must be preserved within %.0f%% -- " +
					"got %.2f deg -> %.2f deg (%.1f%% relative shift)") %
					[species_id, HUE_PRESERVE_TOLERANCE * 100.0, hue_before, hue_after, rel * 100.0])
		else:
			# Intentional hue shift (field_degreen pulls green down relative to
			# red/blue, away from grass-green). Not "preserved" on purpose --
			# assert the shift stayed a real, bounded rotation rather than
			# collapsing to ~0 (the ceiling swallowing the gap, the exact
			# regression `_apply_field_bright_values`'s own header warns
			# about) or blowing out to something absurd.
			var shift := absf(hue_after - hue_before)
			if shift < 1.0:
				_fail(("%s: field_degreen=%.3f should produce a real hue shift away from " +
					"grass-green, but the ceiling compressed it to almost nothing (%.3f deg) -- " +
					"the anti-green-cast fix may have been silently undone") %
					[species_id, degreen, shift])
			elif shift > 90.0:
				_fail(("%s: field_degreen hue shift (%.2f deg) is implausibly large -- " +
					"check the ceiling/degreen interaction") % [species_id, shift])
			else:
				print("  (intentional field_degreen shift, not a regression -- %.2f deg, within (1, 90))" % shift)
	else:
		print("  (no readable albedo_texture -- skipping texture-based estimate/hue check)")

	if tint_max > ceiling + 0.0005:
		_fail("%s: field-bright tint max channel %.4f exceeds field_bright_ceiling %.4f" %
			[species_id, tint_max, ceiling])

	body.queue_free()


func _first_field_bright_material(node: Node) -> BaseMaterial3D:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var mesh: Mesh = instance.mesh
		for surface in (mesh.get_surface_count() if mesh != null else 0):
			var material := instance.get_active_material(surface)
			if material is BaseMaterial3D and (material as BaseMaterial3D).resource_name.contains("_field_bright"):
				return material as BaseMaterial3D
	for child in node.get_children():
		var found := _first_field_bright_material(child)
		if found != null:
			return found
	return null


## Sampled mean over the albedo texture (every Nth texel so a 1024x1024 map
## costs ~20k samples, not a million) -- Image.get_pixel is a per-call
## function-pointer hop, cheap enough at this sample count, far too slow at
## full resolution across three species.
func _texture_mean(tex: Texture2D) -> Variant:
	var img := _readable_image(tex)
	if img == null:
		return null
	var w := img.get_width()
	var h := img.get_height()
	var total := w * h
	var step := maxi(1, int(total / 20000))
	var sum_r := 0.0
	var sum_g := 0.0
	var sum_b := 0.0
	var n := 0
	var idx := 0
	for y in h:
		for x in w:
			if idx % step == 0:
				var c := img.get_pixel(x, y)
				sum_r += c.r
				sum_g += c.g
				sum_b += c.b
				n += 1
			idx += 1
	if n == 0:
		return null
	return Color(sum_r / n, sum_g / n, sum_b / n)


func _texture_max(tex: Texture2D) -> Color:
	var img := _readable_image(tex)
	if img == null:
		return Color(0, 0, 0)
	var w := img.get_width()
	var h := img.get_height()
	var total := w * h
	var step := maxi(1, int(total / 20000))
	var max_r := 0.0
	var max_g := 0.0
	var max_b := 0.0
	var idx := 0
	for y in h:
		for x in w:
			if idx % step == 0:
				var c := img.get_pixel(x, y)
				max_r = maxf(max_r, c.r)
				max_g = maxf(max_g, c.g)
				max_b = maxf(max_b, c.b)
			idx += 1
	return Color(max_r, max_g, max_b)


func _readable_image(tex: Texture2D) -> Image:
	if tex == null:
		return null
	var img := tex.get_image()
	if img == null:
		return null
	if img.is_compressed():
		img.decompress()
	if img.get_format() != Image.FORMAT_RGBA8 and img.get_format() != Image.FORMAT_RGB8:
		img.convert(Image.FORMAT_RGBA8)
	return img


## Standard HSV hue extraction, scale-invariant by construction (depends only
## on channel RATIOS) -- exactly the property "hue preserved under a uniform
## brightness push" needs, and exactly what changes when `field_degreen` pulls
## green down relative to red/blue on purpose.
func _hue_degrees(r: float, g: float, b: float) -> float:
	var mx := maxf(r, maxf(g, b))
	var mn := minf(r, minf(g, b))
	var delta := mx - mn
	if delta <= 0.000001:
		return 0.0
	var h: float
	if is_equal_approx(mx, r):
		h = fmod((g - b) / delta, 6.0)
	elif is_equal_approx(mx, g):
		h = ((b - r) / delta) + 2.0
	else:
		h = ((r - g) / delta) + 4.0
	h *= 60.0
	if h < 0.0:
		h += 360.0
	return h


func _fail(msg: String) -> void:
	_failures.append(msg)
	printerr("FAIL: %s" % msg)


func _report() -> void:
	if _failures.is_empty():
		print("_probe_field_bright_values: PASS")
		quit(0)
	else:
		for msg: String in _failures:
			print("  - %s" % msg)
		print("_probe_field_bright_values: %d failure(s)" % _failures.size())
		quit(1)
