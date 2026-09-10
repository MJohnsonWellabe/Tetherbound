extends RefCounted

const ART_CONFIG_PATH := "res://data/config/art.json"
static var _foliage_backlight_strength := -1.0


## The installed nature family builds leaves and flowers as two-sided cutout
## surfaces. Their glTFs carry useful geometric normals but no normal or light-
## transmission texture, so a face turned away from the sun receives only the
## scene ambient and a close bush can collapse into one dark silhouette.
## StandardMaterial3D backlight is the built-in thin-surface response: it
## transfers direct light to the reverse side while leaving the source albedo,
## front lighting and shadows intact. Keep the material-name gate explicit so
## MASK-imported bark (some tree glTFs use it) cannot enter this treatment.
static func apply_thin_foliage_backlight(material_name: String,
		material: BaseMaterial3D) -> bool:
	if not is_thin_foliage_material(material_name):
		return false
	var strength := foliage_backlight_strength()
	if strength <= 0.0:
		return false
	material.backlight_enabled = true
	material.backlight = Color(strength, strength, strength, 1.0)
	return true


static func is_thin_foliage_material(material_name: String) -> bool:
	var key := material_name.to_lower()
	return key == "leaves" or key.begins_with("leaves_") or key == "flowers"


static func foliage_backlight_strength() -> float:
	if _foliage_backlight_strength >= 0.0:
		return _foliage_backlight_strength
	_foliage_backlight_strength = 0.0
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ART_CONFIG_PATH))
	if parsed is Dictionary:
		var environment: Dictionary = (parsed as Dictionary).get("environment", {})
		_foliage_backlight_strength = clampf(
			float(environment.get("foliage_backlight_strength", 0.0)), 0.0, 1.0)
	return _foliage_backlight_strength

## One dielectric rule, in one place: a surface that imports as METAL with nothing to
## modulate it is a glTF export omission, not an art decision.
##
## glTF 2.0's default for an ABSENT `metallicFactor` is **1.0**, not 0, so any
## pack that ships materials without one imports every surface as a metal. A
## metal has no diffuse term at all; with the format's equally-default
## `roughnessFactor` of 1.0 the specular lobe is spread over the whole
## hemisphere and returns almost nothing, so the object renders as a black
## silhouette in full daylight whichever way the sun points.
##
## Most of this project's assets are saved from that by an ORM /
## metallic-roughness texture whose blue channel multiplies the factor back down
## — the Quaternius props, every Tetherbound creature. The ones with a factor and
## NO texture are the defect class, and this is the test for it.
##
## Found as `GF-B-010` on the six humanoid rigs, where every NPC and the player
## rendered as a cut-out. `scripts/characters/character_model.gd` applies the
## same rule inline rather than calling this, because there it has to compose
## with the palette tint and the shared-variant material cache — see
## `_shared_variant_material()`'s own comment, which is the long-form version of
## the paragraph above. This file is for everything that instantiates a .glb and
## draws it as it came.
##
## The same defect is why `ralph/BLOCKED.md` records the `environment/nature`
## pack as not rendering correctly through `props.gd`: its 27 models all ship
## `metallicFactor` absent with no ORM map. `data/config/bands/*/props.json`
## carries several `_why` notes routing around it ("renders with an untextured
## near-white placeholder material", "one of only two models in that pack that
## render correctly"). It was the material, not the models.


## Every BaseMaterial3D under `node` that carries metallic with no metallic
## texture, corrected to a dielectric via a surface override. Returns how many
## surfaces were changed, so a caller can log or assert on it.
##
## Override rather than mutating the material in place: an imported material is
## shared by every instance of that scene, and writing to it would reach into
## resources this call was not given. Roughness is deliberately untouched — the
## same absent-default 1.0, but a fully rough dielectric is correct matte wood,
## stone or cloth, and picking a sheen for a whole vendored pack is a look
## decision that a correctness fix does not license.
static func make_dielectric(node: Node) -> int:
	var corrected := 0
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		if instance.mesh != null:
			for surface in instance.mesh.get_surface_count():
				var source: Material = instance.get_active_material(surface)
				if not source is BaseMaterial3D:
					continue
				var base := source as BaseMaterial3D
				if base.metallic <= 0.0 or base.metallic_texture != null:
					continue
				var fixed: BaseMaterial3D = base.duplicate()
				fixed.metallic = 0.0
				instance.set_surface_override_material(surface, fixed)
				corrected += 1
	for child in node.get_children():
		corrected += make_dielectric(child)
	return corrected
