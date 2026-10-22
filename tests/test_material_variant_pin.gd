extends "res://tests/test_case.gd"

const PIN := preload("res://scripts/vfx/material_variant_pin.gd")
const GEOMETRY := preload("res://scripts/vfx/move_effect_geometry.gd")
const SIGNATURE := preload("res://scripts/vfx/ultimates/ultimate_geometry.gd")
const LIBRARY := preload("res://scripts/vfx/move_effect_library.gd")
const EFFECT := preload("res://scripts/vfx/move_effect.gd")


## Static pins persist across tests; each test starts from none so that every
## pin call site has to register its own variant.
func before_each() -> void:
	super()
	PIN._pins.clear()
	PIN._prewarmed = false
	LIBRARY._prewarmed = false


## F25#4: Forward+ frees a BaseMaterial3D shader variant when its last material
## is released, so short-lived effects recompiled it on every launch frame.
## Each effect material builder must pin its variant itself.
func test_effect_material_builders_pin_their_variants() -> void:
	var unlit := GEOMETRY.material(Color.RED, 1.0, false)
	assert_eq(PIN.pinned_count(), 1, "move_effect_geometry.material() pins its variant")
	assert_true(PIN._pins.has(PIN.variant_key(unlit)), "the pinned key is the material's own variant")
	var lit_alpha := SIGNATURE.material(Color.GREEN, 0.4, true)
	assert_eq(PIN.pinned_count(), 2, "ultimate_geometry.material() pins its variant")
	assert_true(PIN._pins.has(PIN.variant_key(lit_alpha)), "the signature variant is pinned")
	var again: Array = [GEOMETRY.material(Color.WHITE, 1.0, false), SIGNATURE.material(Color.BLACK, 0.4, true)]
	assert_eq(PIN.pinned_count(), 2, "a second launch of the same variants adds no pins")
	again.clear()


## A fade switches an opaque body to alpha: that new variant is pinned too.
func test_opacity_fade_pins_the_alpha_variant() -> void:
	var effect: Node3D = EFFECT.new()
	var opaque := StandardMaterial3D.new()
	opaque.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	assert_eq(PIN.pinned_count(), 0, "nothing pinned before the fade")
	effect.call("_set_opacity", opaque, 0.5)
	assert_eq(opaque.transparency, BaseMaterial3D.TRANSPARENCY_ALPHA, "the fade switches the material to alpha")
	assert_eq(PIN.pinned_count(), 1, "the fade pins the alpha variant it switched to")
	effect.call("_set_opacity", opaque, 0.25)
	assert_eq(PIN.pinned_count(), 1, "later fade steps add no pins")
	effect.free()


## The encounter director calls this while the world loads.
func test_library_prewarm_pins_every_standard_variant_and_builds_every_surface() -> void:
	LIBRARY.prewarm()
	var pinned := PIN.pinned_count()
	assert_true(pinned >= 6, "lit/unlit x opaque/alpha and the emissive variants are pinned by the library prewarm")
	for builder: Material in [GEOMETRY.material(Color.RED, 1.0, false), GEOMETRY.material(Color.RED, 0.5, true),
			SIGNATURE.material(Color.RED, 1.0, true), SIGNATURE.material(Color.RED, 0.5, false)]:
		assert_true(PIN._pins.has(PIN.variant_key(builder as BaseMaterial3D)), "prewarm covers %s" % PIN.variant_key(builder as BaseMaterial3D))
	assert_eq(PIN.pinned_count(), pinned, "no builder variant is missing from the prewarm")
	LIBRARY.prewarm()
	assert_eq(PIN.pinned_count(), pinned, "prewarm is idempotent")
	for kind: String in LIBRARY.AUTHORED_KINDS:
		assert_true(GEOMETRY.authored_material(kind, {}, Color.WHITE) is Material, kind + " builds from an empty profile")


## Colour and alpha value are uniforms; only feature flags make a variant.
func test_variant_key_ignores_uniforms_and_tracks_features() -> void:
	var a := GEOMETRY.material(Color.RED, 0.3, true)
	var b := GEOMETRY.material(Color.BLUE, 0.9, true)
	assert_eq(PIN.variant_key(a), PIN.variant_key(b), "colour and alpha value share one variant")
	var opaque := GEOMETRY.material(Color.RED, 1.0, true)
	assert_ne(PIN.variant_key(opaque), PIN.variant_key(a), "opaque and alpha are different variants")
	var emissive := opaque.duplicate() as StandardMaterial3D
	emissive.emission_enabled = true
	assert_ne(PIN.variant_key(emissive), PIN.variant_key(opaque), "emission is a separate variant")
	PIN.pin(emissive)
	assert_true(PIN._pins.has(PIN.variant_key(emissive)), "an emissive core variant can be pinned")
