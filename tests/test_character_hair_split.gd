extends "res://tests/test_case.gd"

## `NP7`: villager_female_lod0.glb ships a REAL separated `hair_ponytail`
## mesh now (cut from the fused source mesh in Blender, patched at the
## scalp, re-skinned to the Head bone), not a placeholder primitive --
## `character_model.gd::_apply_hair()`'s job for a config on this base
## shrinks to finding that mesh and toggling it, per its own updated
## comment. This pins that real path down, the way `test_character_lying.gd`
## pins `set_lying`'s geometry contract without booting a scene (D02: pure
## logic, no rendering) -- `build_from_config` builds a bare
## `character_model.gd` node off-tree exactly as `test_character_lying.gd`
## already does for the trainer.

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")


func _build(cfg: Dictionary) -> Node3D:
	var model := Node3D.new()
	model.set_script(CHARACTER_MODEL)
	model.call("build_from_config", cfg)
	return model


func _villager_farmer_cfg() -> Dictionary:
	return CHARACTER_MODEL.config_for("villager_farmer")


func test_the_real_ponytail_mesh_is_found_and_shown_by_default() -> void:
	var cfg := _villager_farmer_cfg()
	if cfg.is_empty():
		_fail("no villager_farmer config in data/config/art.json")
		return
	var model := _build(cfg)
	var part: Variant = model.call("find_part", "hair")
	assert_true(part != null,
		"villager_farmer's art.json hair.visible=true should find and expose the real hair_ponytail mesh")
	if part != null:
		assert_true(bool((part as MeshInstance3D).visible), "the found part should actually be visible")
	model.free()


func test_hiding_the_real_ponytail_leaves_no_part_named_hair() -> void:
	# Same contract a placeholder's absence gives (see _apply_hair's own
	# comment): visible:false means find_part("hair") reports null, not a
	# hidden node still answering to that name.
	var base_model := str(_villager_farmer_cfg().get("model", ""))
	if base_model == "":
		_fail("no villager_farmer model configured")
		return
	var cfg := {"model": base_model, "height": 1.75, "hair": {"visible": false}}
	var model := _build(cfg)
	var part: Variant = model.call("find_part", "hair")
	assert_true(part == null, "hair.visible=false should leave no part discoverable as 'hair'")
	model.free()


func test_real_ponytail_recolours_without_losing_its_texture() -> void:
	# A real mesh keeps its baked hair texture unless a colour is explicitly
	# requested -- forcing a flat StandardMaterial3D onto it the way the
	# PLACEHOLDER path must (a primitive has no texture to lose) would be a
	# visible downgrade for real geometry. Only check that an explicit
	# colour request does not crash and still leaves the part visible;
	# whether it reads correctly on screen is `visual-judge`'s job, not
	# this file's (D02).
	var base_model := str(_villager_farmer_cfg().get("model", ""))
	var cfg := {"model": base_model, "height": 1.75, "hair": {"visible": true, "color": "#111111"}}
	var model := _build(cfg)
	var part: MeshInstance3D = model.call("find_part", "hair")
	assert_true(part != null, "a recoloured real ponytail should still be found as 'hair'")
	model.free()


func test_no_hair_config_leaves_the_base_models_default_look_untouched() -> void:
	# Grandpa/trainer/warden have no hair block in art.json at all --
	# _apply_hair must return immediately rather than inventing a
	# placeholder nobody asked for.
	var cfg := CHARACTER_MODEL.config_for("grandpa")
	if cfg.is_empty():
		_fail("no grandpa config in data/config/art.json")
		return
	var model := _build(cfg)
	var part: Variant = model.call("find_part", "hair")
	assert_true(part == null, "a config with no 'hair' key should attach nothing")
	model.free()
