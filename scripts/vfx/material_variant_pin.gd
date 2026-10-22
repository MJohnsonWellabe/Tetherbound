extends RefCounted

## F25#4 launch hitch. Forward+ compiles a BaseMaterial3D shader the first time
## a material with a given feature set asks for its RID, and frees that shader
## again when the last material with those features is released. Effects are
## short-lived, so every volley re-compiled the same few variants on its
## launch frame: 10-43 ms each, 155-350 ms for four ultimates on a GTX 1060
## (Compatibility: under 1 ms). One duplicate per variant is held for the
## process, so later materials of that variant reuse the compiled shader.
## Colour, alpha value and roughness are uniforms and never make a new variant.
static var _pins: Dictionary = {}
static var _prewarmed := false


static func pin(material: Material) -> void:
	var base := material as BaseMaterial3D
	if base == null: return
	var key := variant_key(base)
	if _pins.has(key): return
	var keep := base.duplicate() as BaseMaterial3D
	keep.get_rid()
	_pins[key] = keep


## The features effect materials actually vary. Two materials with the same key
## share one compiled shader; a key that misses a feature only costs a pin.
static func variant_key(m: BaseMaterial3D) -> String:
	return "%d|%d|%d|%d|%d|%d|%d|%d" % [m.shading_mode, m.transparency, m.blend_mode, m.cull_mode,
		int(m.vertex_color_use_as_albedo), int(m.no_depth_test), int(m.emission_enabled), m.billboard_mode]


static func pinned_count() -> int:
	return _pins.size()


## The variants move_effect_geometry.material() and ultimate_geometry.material()
## build (lit/unlit x opaque/alpha) plus the emissive solid core. Idempotent.
static func prewarm() -> void:
	if _prewarmed: return
	_prewarmed = true
	for lit: bool in [false, true]:
		for alpha: bool in [false, true]:
			for emission: bool in ([false, true] if lit else [false]):
				var m := StandardMaterial3D.new()
				m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL if lit else BaseMaterial3D.SHADING_MODE_UNSHADED
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if alpha else BaseMaterial3D.TRANSPARENCY_DISABLED
				m.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
				m.cull_mode = BaseMaterial3D.CULL_DISABLED
				m.vertex_color_use_as_albedo = true
				m.no_depth_test = false
				m.emission_enabled = emission
				pin(m)
