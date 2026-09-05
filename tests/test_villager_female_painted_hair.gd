extends "res://tests/test_case.gd"

## N04-DIALOGUE-PORTRAITS, 2026-09-05. Eight villagers share the
## `villager_female` rig and, until this, one face: the per-NPC hair colour
## reached only the separated ponytail at the nape (D81's finding, confirmed
## in-engine and by two code-blind judges). `character_model.gd::_apply_hair`
## now also lays the colour over the hair PAINTED into the body texture --
## the fringe and cap a player sees from the front -- through the body
## material's detail layer, gated by the rig's baked hair mask.
##
## Built off-tree with `build_from_config` exactly as
## `test_character_hair_split.gd` does (D02: no scene, no render). What is
## asserted is the material the rig actually carries, not a config field:
## which surfaces got the layer, what colour it carries, what mask gates it,
## and that two colours make two materials while one colour is shared.

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")

const FEMALE_MODEL := "res://assets/characters/villager_female/villager_female_lod0.glb"
const MASK := "res://assets/characters/villager_female/villager_female_lod0_hair_mask.png"


func _build(cfg: Dictionary) -> Node3D:
	var model := Node3D.new()
	model.set_script(CHARACTER_MODEL)
	model.call("build_from_config", cfg)
	return model


func _female(hair: Dictionary) -> Dictionary:
	return {"model": FEMALE_MODEL, "height": 1.75, "tint": "#ffffff", "hair": hair}


func _body(model: Node3D) -> BaseMaterial3D:
	return model.call("body_material") as BaseMaterial3D


func _hair(model: Node3D) -> BaseMaterial3D:
	var part: MeshInstance3D = model.call("find_part", "hair")
	return part.get_active_material(0) as BaseMaterial3D if part != null else null


func _detail_colour(material: BaseMaterial3D) -> Color:
	var texture := material.detail_albedo as Texture2D
	if texture == null:
		return Color(0, 0, 0, 0)
	return texture.get_image().get_pixel(0, 0)


func test_the_mask_is_on_disk_and_matches_the_rig_it_was_baked_from() -> void:
	assert_eq(CHARACTER_MODEL.painted_hair_mask_path(FEMALE_MODEL), MASK)
	assert_true(ResourceLoader.exists(MASK), "the baked hair mask is missing: %s" % MASK)
	var mask := load(MASK) as Texture2D
	assert_true(mask != null, "the hair mask did not load as a texture")
	if mask != null:
		assert_eq(mask.get_width(), mask.get_height(), "the mask must be square like the texture it gates")
		assert_true(mask.get_width() >= 1024, "the mask is too small to gate a 2048 texture cleanly")
	assert_eq(CHARACTER_MODEL.painted_hair_mask_path(""), "")


func test_a_hair_colour_reaches_the_painted_hair_on_the_body_not_only_the_ponytail() -> void:
	var model := _build(_female({"visible": true, "color": "#8f8f96"}))
	var body := _body(model)
	assert_true(body != null, "no body material built")
	if body != null:
		assert_true(body.detail_enabled, "the body material carries no detail layer, so the fringe keeps its painted brown")
		assert_eq(body.detail_blend_mode, BaseMaterial3D.BLEND_MODE_MIX)
		assert_true(body.detail_mask != null and body.detail_mask.resource_path == MASK,
			"the layer must be gated by the baked hair mask, not painted over the whole body")
		assert_eq(_detail_colour(body).to_html(false), "8f8f96", "the layer should carry Halda's iron grey")
		# The face is on the SAME material. Only the masked region may change:
		# the albedo multiply stays the identity, so skin is untouched.
		assert_eq(body.albedo_color.to_html(false), "ffffff", "the whole-body multiply must stay white; the face is on this material")
	var hair := _hair(model)
	assert_true(hair != null, "the ponytail material is missing")
	if hair != null:
		assert_true(hair.detail_enabled, "the ponytail should carry the same layer so nape and fringe agree")
		assert_eq(_detail_colour(hair).to_html(false), "8f8f96")
	model.free()


func test_two_colours_are_two_materials_and_one_colour_is_shared() -> void:
	var halda := _build(_female({"visible": true, "color": "#8f8f96"}))
	var mira := _build(_female({"visible": true, "color": "#5c3a22"}))
	var another_halda := _build(_female({"visible": true, "color": "#8f8f96"}))
	assert_ne(_body(halda), _body(mira), "two hair colours must not share one body material")
	assert_ne(_detail_colour(_body(halda)).to_html(false), _detail_colour(_body(mira)).to_html(false))
	assert_eq(_body(halda), _body(another_halda), "the same colour should share one cached material, not mint a second")
	halda.free()
	mira.free()
	another_halda.free()


func test_no_colour_or_hidden_hair_leaves_the_painted_hair_as_authored() -> void:
	var plain := _build(_female({"visible": true}))
	assert_false(_body(plain).detail_enabled, "no colour asked for, so nothing should be laid over the painted hair")
	plain.free()
	var hidden := _build(_female({"visible": false, "color": "#8f8f96"}))
	assert_false(_body(hidden).detail_enabled, "hidden hair is the rig's own look; recolouring it would be invented")
	hidden.free()


func test_the_art_json_villagers_each_get_their_own_painted_hair_colour() -> void:
	# The real configs, the real colours: farmer, smith and ranger differ in
	# art.json, and now differ on the body material the world draws.
	var seen: Dictionary = {}
	for key: String in ["villager_farmer", "villager_smith", "villager_ranger"]:
		var cfg := CHARACTER_MODEL.config_for(key)
		if cfg.is_empty():
			_fail("no %s in art.json" % key)
			continue
		var model := _build(cfg)
		var body := _body(model)
		assert_true(body != null and body.detail_enabled, "%s's body carries no painted-hair layer" % key)
		if body != null:
			var wanted := Color(str((cfg.get("hair", {}) as Dictionary).get("color", ""))).to_html(false)
			assert_eq(_detail_colour(body).to_html(false), wanted, "%s's layer is not its art.json hair colour" % key)
			seen[_detail_colour(body).to_html(false)] = key
		model.free()
	assert_eq(seen.size(), 3, "farmer, smith and ranger should land three different colours, got %s" % str(seen))


func test_a_rig_with_no_mask_keeps_the_old_behaviour() -> void:
	# Grandpa has no hair block; the trainer rig has no mask. Neither may grow
	# a detail layer just because a colour appears in its config.
	var grandpa := _build(CHARACTER_MODEL.config_for("grandpa"))
	var body := _body(grandpa)
	assert_true(body != null and not body.detail_enabled, "grandpa's body grew a painted-hair layer with no mask on disk")
	grandpa.free()
	var trainer_cfg := CHARACTER_MODEL.config_for("trainer").duplicate(true)
	trainer_cfg["hair"] = {"visible": true, "color": "#8f8f96"}
	var trainer := _build(trainer_cfg)
	var trainer_body := _body(trainer)
	assert_true(trainer_body != null and not trainer_body.detail_enabled,
		"the trainer rig has no mask; a hair colour must not touch its one material")
	trainer.free()
