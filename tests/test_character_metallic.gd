extends "res://tests/test_case.gd"

## `GF-B-010`: an NPC rendered as an unlit black silhouette in daylight beside a
## correctly lit player and a correctly lit crate.
##
## The cause was not the scene's sun, which is where the Phase B backlog's own
## RC-5 cluster pointed. glTF 2.0's default for an ABSENT `metallicFactor` is
## **1.0**, and every one of the six humanoid rigs' .glb materials omits it, so
## Godot imports each body as a fully-rough METAL: no diffuse term at all, and a
## specular lobe that roughness 1.0 spreads to nothing. The props and creatures
## in the same frame omit `metallicFactor` too and are fine, because they ship
## an ORM texture whose blue channel multiplies that 1.0 back down to dielectric.
## The six rigs are the only class in the project that carries a metallic factor
## with no texture to modulate it.
##
## So this pins the property, not the pixel: a body surface with no metallic
## texture must build dielectric. `tools/_probe_npc_metallic_ab.gd` is the
## rendered half of the same claim and cannot run in a unit test (D02: pure
## logic, no rendering).
##
## Deliberately asserts against `config_for()`'s REAL production configs rather
## than a hand-made dict -- the defect was in what the shipped rigs import as,
## and a fixture would have passed throughout.

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const NPC_RANKS := preload("res://scripts/characters/npc_ranks.gd")

## Every humanoid the player can be standing next to. `trainer` is the player's
## own body as well as every trainer NPC's.
const RIGS := [
	"trainer", "grandpa", "villager_farmer", "villager_keeper",
	"villager_smith", "villager_quarryman", "villager_ranger", "warden", "grunt",
]


func _build(cfg: Dictionary) -> Node3D:
	var model := Node3D.new()
	model.set_script(CHARACTER_MODEL)
	model.call("build_from_config", cfg)
	return model


## Every MeshInstance3D surface under the built character, as
## `[node_name, surface_index, material]`.
func _surfaces(node: Node, out: Array) -> Array:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		if instance.mesh != null:
			for surface in instance.mesh.get_surface_count():
				out.append([instance.name, surface, instance.get_active_material(surface)])
	for child in node.get_children():
		_surfaces(child, out)
	return out


func test_every_rig_body_surface_builds_dielectric() -> void:
	for key: String in RIGS:
		var cfg := CHARACTER_MODEL.config_for(key)
		if cfg.is_empty():
			_fail("no '%s' block in data/config/art.json" % key)
			continue
		var model := _build(cfg)
		for entry: Array in _surfaces(model, []):
			var material: Variant = entry[2]
			if not material is BaseMaterial3D:
				continue
			var m := material as BaseMaterial3D
			# A surface that ships a real metallic/ORM map keeps whatever that
			# map says -- the correction is only for the ones with nothing to
			# modulate the factor.
			if m.metallic_texture != null:
				continue
			assert_true(is_zero_approx(m.metallic),
				"'%s' surface %s[%d] builds at metallic %.2f with no metallic texture; a cloth-and-skin body with no diffuse term renders as a black silhouette in daylight" % [
					key, entry[0], int(entry[1]), m.metallic])
		model.free()


## The correction must not reach a surface that deliberately asked for metal.
## `npc_ranks.json`'s badges are struck metal on purpose -- see
## `character_model.gd::_shared_variant_material()`'s `finish` branch, which
## exists because a matte primitive photographed as a debug colour swatch.
func test_a_rank_badge_that_asks_for_metal_still_gets_it() -> void:
	var found_any := false
	for rank: Variant in NPC_RANKS.rank_ids():
		var cfg: Dictionary = NPC_RANKS.config_for(str(rank))
		if cfg.is_empty():
			continue
		var model := _build(cfg)
		for entry: Array in _surfaces(model, []):
			if not str(entry[0]).begins_with("accessory_badge"):
				continue
			var material: Variant = entry[2]
			if not material is BaseMaterial3D:
				continue
			found_any = true
			assert_true((material as BaseMaterial3D).metallic > 0.0,
				"'%s' badge %s built at metallic 0; the rank read depends on a specular falloff" % [
					str(rank), str(entry[0])])
		model.free()
	assert_true(found_any, "no rank in npc_ranks.json attached a badge to assert against")


## The correction rides in `_shared_variant_material()`, which is also the
## palette path -- so a rank whose palette declares a colour must still land it.
## This is the guard against "fixed the metal, lost the tint".
func test_correcting_metal_leaves_the_rank_palette_alone() -> void:
	var cfg: Dictionary = NPC_RANKS.config_for("grunt")
	if cfg.is_empty() or not cfg.has("palette"):
		_fail("no grunt rank palette in data/config/npc_ranks.json to check against")
		return
	var expected := Color(str((cfg.get("palette", {}) as Dictionary).get("*", "#ffffff")))
	var model := _build(cfg)
	var material: Variant = model.call("body_material")
	if material == null or not material is BaseMaterial3D:
		_fail("the grunt rank built with no body material")
	else:
		assert_true((material as BaseMaterial3D).albedo_color.is_equal_approx(expected),
			"the grunt rank's body albedo is %s, not the %s its palette declares" % [
				(material as BaseMaterial3D).albedo_color, expected])
	model.free()


## An untinted rig must render exactly the colour its painted texture carries.
## `_apply_palette()` now walks EVERY character rather than returning early for
## the four rigs that declare no tint, so this pins the identity multiply: the
## walk must correct the metal without touching the colour.
func test_an_untinted_rig_keeps_a_white_albedo_multiplier() -> void:
	var model := _build(CHARACTER_MODEL.config_for("trainer"))
	var material: Variant = model.call("body_material")
	if material == null or not material is BaseMaterial3D:
		_fail("the trainer built with no body material")
	else:
		assert_true((material as BaseMaterial3D).albedo_color.is_equal_approx(Color(1, 1, 1, 1)),
			"the trainer declares no tint, so its albedo multiplier must stay white; got %s" % [
				(material as BaseMaterial3D).albedo_color])
	model.free()
