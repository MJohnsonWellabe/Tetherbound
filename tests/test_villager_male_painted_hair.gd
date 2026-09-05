extends "res://tests/test_case.gd"

## N14-ROUTED-FOLLOWUPS, 2026-09-05, second half of N04-DIALOGUE-PORTRAITS's
## routed finding: "several male NPCs (Oskar, Bram, Kell, the Quarry Foreman,
## Coll) currently all share one undifferentiated plate."
##
## N04 built the mask-by-region hair recolour for `villager_female` and its brief
## scoped it there. This is the same technique on `villager_male`, and the ONE
## structural difference is what these tests are mostly about:
##
##   **the male rig has no separated hair mesh at all.**
##
## `villager_male_lod0.glb` carries `char1` and `trousers` and nothing else --
## `art.json::villager_keeper`'s own comment says so ("villager_male has no
## separable hair mesh; NP7 only cut one for villager_female"), and N04's report
## flagged "the male rig has no separable hair and no mask" as a real possibility
## that would end this work. It does not, and the distinction is the point: the
## mask is a region of the TEXTURE, found by skinning and colour, not a mesh to
## be cut. So `_apply_hair` has to reach the painted-hair recolour on a rig where
## `find_child("hair_ponytail")` returns null -- WITHOUT falling through to the
## primitive-sphere placeholder below it, which would put a ball of
## hair-coloured plastic on the five people this is meant to tell apart.
##
## Built off-tree with `build_from_config`, same as
## `tests/test_villager_female_painted_hair.gd` (D02: no scene, no render).

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const MALE_MODEL := "res://assets/characters/villager_male/villager_male_lod0.glb"
const MASK := "res://assets/characters/villager_male/villager_male_lod0_hair_mask.png"
const NPCS_PATH := "res://data/config/village_npcs.json"


func _build(cfg: Dictionary) -> Node3D:
	var model := Node3D.new()
	model.set_script(CHARACTER_MODEL)
	model.call("build_from_config", cfg)
	return model


func _male(hair: Dictionary) -> Dictionary:
	var cfg: Dictionary = CHARACTER_MODEL.config_for("villager_keeper").duplicate(true)
	cfg["hair"] = hair
	return cfg


func _body(model: Node3D) -> BaseMaterial3D:
	return model.call("body_material") as BaseMaterial3D


func _detail_colour(material: BaseMaterial3D) -> Color:
	var texture := material.detail_albedo as Texture2D
	if texture == null:
		return Color(0, 0, 0, 0)
	return texture.get_image().get_pixel(0, 0)


func test_the_male_mask_is_on_disk_and_matches_the_rig_it_was_baked_from() -> void:
	assert_eq(CHARACTER_MODEL.painted_hair_mask_path(MALE_MODEL), MASK)
	assert_true(ResourceLoader.exists(MASK), "the baked male hair mask is missing: %s" % MASK)
	var mask := load(MASK) as Texture2D
	assert_true(mask != null, "the male hair mask did not load as a texture")
	if mask != null:
		assert_eq(mask.get_width(), mask.get_height(), "the mask must be square like the texture it gates")
		assert_true(mask.get_width() >= 1024, "the mask is too small to gate a 2048 texture cleanly")


## The rig genuinely has no hair mesh -- if that ever changes, the branch these
## tests exercise stops being the one that runs, and this test says so first.
func test_the_male_rig_still_has_no_separated_hair_mesh() -> void:
	var model := _build(_male({"visible": true, "color": "#2f2320"}))
	assert_eq(model.call("find_part", "hair"), null,
		"the male rig grew a separated hair part; _apply_hair's maskless-mesh branch is no longer the one under test")
	model.free()


func test_a_hair_colour_reaches_the_painted_hair_with_no_hair_mesh_to_hang_it_on() -> void:
	var model := _build(_male({"visible": true, "color": "#2f2320"}))
	var body := _body(model)
	assert_true(body != null, "no body material built")
	if body != null:
		assert_true(body.detail_enabled,
			"the body material carries no detail layer, so every man on this rig keeps the same painted brown fringe")
		assert_eq(body.detail_blend_mode, BaseMaterial3D.BLEND_MODE_MIX)
		assert_true(body.detail_mask != null and body.detail_mask.resource_path == MASK,
			"the layer must be gated by the baked hair mask, not painted over the whole body")
		assert_eq(_detail_colour(body).to_html(false), "2f2320", "the layer should carry Oskar's near-black")
	model.free()


## The defect the ordering in `_apply_hair` exists to avoid.
func test_a_maskless_mesh_rig_does_not_grow_a_placeholder_hair_ball() -> void:
	var model := _build(_male({"visible": true, "color": "#9c8450"}))
	assert_eq(model.call("find_part", "hair"), null,
		"a primitive placeholder was attached to the Head bone; the painted recolour must win over it")
	model.free()


func test_hidden_or_uncoloured_hair_leaves_the_painted_hair_as_authored() -> void:
	for hair: Dictionary in [{"visible": false}, {"visible": true}]:
		var model := _build(_male(hair))
		var body := _body(model)
		assert_true(body != null and not body.detail_enabled,
			"a hair block with no colour (%s) still repainted the fringe" % [hair])
		model.free()


func test_two_colours_are_two_materials_and_one_colour_is_shared() -> void:
	var one := _build(_male({"visible": true, "color": "#2f2320"}))
	var two := _build(_male({"visible": true, "color": "#9c8450"}))
	var three := _build(_male({"visible": true, "color": "#2f2320"}))
	assert_ne(_body(one), _body(two), "two different hair colours share one material; both men would change together")
	assert_eq(_body(one), _body(three), "the same colour built two materials; the variant cache is not being hit")
	one.free()
	two.free()
	three.free()


## The four people this was done for actually differ, measured the way N04's
## judge measured -- not "each has a `hair` block", which a copy-paste would
## also satisfy.
func test_the_four_male_rig_villagers_each_get_a_visibly_different_colour() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(NPCS_PATH))
	assert_true(typeof(parsed) == TYPE_DICTIONARY, "village_npcs.json did not parse")
	var wanted := ["Oskar", "Bram", "Kell", "Quarry Foreman"]
	var colours: Dictionary = {}
	for raw: Variant in ((parsed as Dictionary).get("villagers", []) as Array):
		var villager: Dictionary = raw
		var name := str(villager.get("name", ""))
		if not wanted.has(name):
			continue
		var hair: Variant = villager.get("hair")
		assert_true(typeof(hair) == TYPE_DICTIONARY and (hair as Dictionary).has("color"),
			"%s is on the shared male rig with no hair colour; he reads as whoever stands next to him" % name)
		if typeof(hair) == TYPE_DICTIONARY and (hair as Dictionary).has("color"):
			colours[name] = Color(str((hair as Dictionary)["color"]))
	assert_eq(colours.size(), wanted.size(),
		"expected all four male-rig villagers to carry a hair colour, found %s" % [colours.keys()])

	# CIE76 deltaE, the metric N04's judge reported at 72px. The bar is 15: the
	# closest pair it did NOT flag on the female rig measured 14.05 there, and
	# the pair it DID flag as "the same person at speaking distance" was 6.83.
	var names: Array = colours.keys()
	for i in names.size():
		for j in range(i + 1, names.size()):
			var delta := _delta_e(colours[names[i]], colours[names[j]])
			assert_true(delta >= 15.0,
				"%s and %s are %.1f apart and will read as one man; the flagged pair on the female rig was 6.8" % [
					names[i], names[j], delta])


## A rig with no mask on disk must not grow a detail layer just because a colour
## appears in its config -- the same guard the female suite holds, restated here
## because THIS lane added a second path into `_recolour_painted_hair`.
func test_a_rig_with_no_mask_still_keeps_the_old_behaviour() -> void:
	var trainer_cfg: Dictionary = CHARACTER_MODEL.config_for("trainer").duplicate(true)
	trainer_cfg["hair"] = {"visible": true, "color": "#9c8450"}
	var trainer := _build(trainer_cfg)
	var body := _body(trainer)
	assert_true(body != null and not body.detail_enabled,
		"the trainer rig has no mask; a hair colour must not touch its one material")
	trainer.free()


func _delta_e(a: Color, b: Color) -> float:
	var la := _lab(a)
	var lb := _lab(b)
	return sqrt(pow(la.x - lb.x, 2.0) + pow(la.y - lb.y, 2.0) + pow(la.z - lb.z, 2.0))


func _lab(c: Color) -> Vector3:
	var r := _linear(c.r)
	var g := _linear(c.g)
	var b := _linear(c.b)
	var x := (r * 0.4124 + g * 0.3576 + b * 0.1805) / 0.95047
	var y := r * 0.2126 + g * 0.7152 + b * 0.0722
	var z := (r * 0.0193 + g * 0.1192 + b * 0.9505) / 1.08883
	return Vector3(116.0 * _f(y) - 16.0, 500.0 * (_f(x) - _f(y)), 200.0 * (_f(y) - _f(z)))


func _linear(c: float) -> float:
	return c / 12.92 if c <= 0.04045 else pow((c + 0.055) / 1.055, 2.4)


func _f(t: float) -> float:
	return pow(t, 1.0 / 3.0) if t > 0.008856 else (7.787 * t + 16.0 / 116.0)
