extends "res://tests/test_case.gd"

const PIN := preload("res://scripts/vfx/material_variant_pin.gd")
const GEOMETRY := preload("res://scripts/vfx/move_effect_geometry.gd")
const SIGNATURE := preload("res://scripts/vfx/ultimates/ultimate_geometry.gd")

## F25#4: Forward+ frees a BaseMaterial3D shader variant when its last material
## is released, so short-lived effects recompiled it on every launch frame.
## The materials of a second launch must find their variants still pinned.
func test_effect_material_variants_stay_pinned_across_launches() -> void:
	PIN.prewarm()
	var prewarmed := PIN.pinned_count()
	var first: Array = [GEOMETRY.material(Color.RED, 1.0, false), GEOMETRY.material(Color.BLUE, 0.5, true),
		SIGNATURE.material(Color.GREEN, 1.0, true), SIGNATURE.material(Color.GREEN, 0.4, false)]
	assert_eq(PIN.pinned_count(), prewarmed, "prewarm already covers every effect geometry material variant")
	first.clear()
	var second: Array = [GEOMETRY.material(Color.WHITE, 1.0, false), GEOMETRY.material(Color.BLACK, 0.4, true),
		SIGNATURE.material(Color.YELLOW, 1.0, true), SIGNATURE.material(Color.YELLOW, 0.4, false)]
	assert_eq(PIN.pinned_count(), prewarmed, "a second launch of the same variants adds no pins")
	for material: StandardMaterial3D in second:
		assert_true(PIN._pins.has(PIN.variant_key(material)), "variant %s stays pinned after the first launch is released" % PIN.variant_key(material))


## The encounter director calls this while the world loads; every authored
## surface must build from an empty profile without errors, twice.
func test_library_prewarm_builds_every_authored_surface_once() -> void:
	var library := preload("res://scripts/vfx/move_effect_library.gd")
	library.prewarm()
	var pinned := PIN.pinned_count()
	assert_true(pinned >= 6, "standard lit/unlit x opaque/alpha and emissive variants are pinned")
	library.prewarm()
	assert_eq(PIN.pinned_count(), pinned, "prewarm is idempotent")
	for kind: String in library.AUTHORED_KINDS:
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
