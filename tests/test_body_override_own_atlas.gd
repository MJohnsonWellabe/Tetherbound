extends "res://tests/test_case.gd"

## Correctness fix (LANE-BEINGS, 13 Nov 2026): a body texture override
## (`body_albedo_override`) replaces only surfaces that use the rig's body
## atlas. villager_female has a second textured surface (Shins, its own
## `shins_tex` atlas); the override used to paint the body atlas over those
## UVs, smearing coat cloth onto the legs. Single-atlas rigs are unchanged.
## Second fix in the same path: the painted-hair material cache was keyed by
## model, hair colour and body only, so a character built with a body override
## AFTER one without it (village Tam, then tournament Tam) reused the plain
## material and lost the override. The test builds them in that order.

const MODEL := preload("res://scripts/characters/character_model.gd")
const OVERRIDE := "res://assets/characters/villager_female/villager_female_lod0_texture_0_vis1.png"


func _albedos(holder: Node) -> Dictionary:
	var out := {}
	for instance: MeshInstance3D in holder.find_children("*", "MeshInstance3D", true, false):
		if instance.mesh == null:
			continue
		for surface in instance.mesh.get_surface_count():
			var material := instance.get_active_material(surface) as BaseMaterial3D
			if material != null and material.albedo_texture != null:
				out["%s/%d" % [instance.name, surface]] = material.albedo_texture
	return out


func _built(cfg: Dictionary) -> Node:
	var holder := Node3D.new()
	holder.set_script(MODEL)
	assert_true(bool(holder.call("build_from_config", cfg)), "the rig builds")
	return holder


func test_override_reaches_the_body_but_not_the_shins() -> void:
	var base := MODEL.config_for("villager_smith")
	assert_true(str(base.get("model", "")).ends_with("villager_female_lod0.glb"))
	var plain := _built(base)
	var before := _albedos(plain)
	var cfg := base.duplicate(true)
	cfg["body_albedo_override"] = OVERRIDE
	var coated := _built(cfg)
	var after := _albedos(coated)
	var override_tex := load(OVERRIDE) as Texture2D
	var body_hits := 0
	var kept := 0
	for key: String in after:
		if after[key] == override_tex:
			body_hits += 1
		elif before.has(key) and after[key] == before[key]:
			kept += 1
	assert_true(body_hits >= 1, "the body surface wears the override")
	assert_true(kept >= 1, "the shin surface keeps its own atlas (%s)" % str(after.keys()))
	plain.free()
	coated.free()


func test_a_single_atlas_rig_still_takes_the_override_everywhere() -> void:
	var base := MODEL.config_for("officer_b")
	var cfg := base.duplicate(true)
	cfg["body_albedo_override"] = "res://assets/characters/officer_b/officer_b_lod0_texture_0_vis1.png"
	var holder := _built(cfg)
	var override_tex := load(str(cfg.body_albedo_override)) as Texture2D
	var albedos := _albedos(holder)
	assert_true(albedos.size() >= 1)
	for key: String in albedos:
		assert_true(albedos[key] == override_tex, "%s wears the override" % key)
	holder.free()
