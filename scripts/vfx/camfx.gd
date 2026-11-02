extends RefCounted

## Cameras-and-effects cause lane (owner 1 Nov). `data/config/camfx.json`
## holds one block per sub-cause (catch_orb, flame, fight_fade), each behind
## its own flag and OFF by default. `block(name)` is empty unless that block's
## `enabled` is true, so every caller can write `if not CAMFX.block("x").is_empty()`
## and draw exactly as before when the flag is off. Presentation only.

const CONFIG_PATH := "res://data/config/camfx.json"
const FLAME_SHADER := preload("res://shaders/camfx_flame.gdshader")

static var _config: Dictionary = {}
static var _loaded := false


static func config() -> Dictionary:
	if not _loaded:
		_loaded = true
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
		_config = parsed if parsed is Dictionary else {}
	return _config


## Test hook: replace (or with {} clear back to the file) the parsed config.
static func set_config_for_tests(value: Dictionary) -> void:
	_config = value
	_loaded = not value.is_empty()


static func block(name: String) -> Dictionary:
	var raw: Variant = config().get(name, {})
	if raw is Dictionary and (raw as Dictionary).get("enabled") == true:
		return raw
	return {}


## The flame that replaces a Bonfire's flat `Fire` cone (camfx.json `flame`).
## `footprint` is the cone's AABB in the parent's local space; the flame stands
## on its base, as tall as the cone and a little wider. Two Y-locked quads with
## different seeds give the fire depth from any side. Returns null when the
## flag is off.
static func add_flame(parent: Node3D, footprint: AABB) -> Node3D:
	var cfg := block("flame")
	if cfg.is_empty() or parent == null:
		return null
	var root := Node3D.new()
	root.name = "CamfxFlame"
	var height := footprint.size.y * float(cfg.get("height_scale", 1.0))
	var width := maxf(footprint.size.x, footprint.size.z) * float(cfg.get("width_scale", 1.15))
	root.position = Vector3(footprint.get_center().x, footprint.position.y, footprint.get_center().z)
	var inner := float(cfg.get("inner_scale", 0.62))
	for layer in 2:
		var scale_value := 1.0 if layer == 0 else inner
		var quad := QuadMesh.new()
		quad.size = Vector2(width * scale_value, height * scale_value)
		var card := MeshInstance3D.new()
		card.name = "FlameCard%d" % layer
		card.mesh = quad
		card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Quad origin is its centre: lift it so the bottom edge sits on the base.
		card.position = Vector3(0.0, height * scale_value * 0.5, 0.0)
		var material := ShaderMaterial.new()
		material.shader = FLAME_SHADER
		material.set_shader_parameter("energy", float(cfg.get("energy", 1.15)) * (1.0 if layer == 0 else 0.92))
		material.set_shader_parameter("alpha_scale", float(cfg.get("alpha", 1.0)) * (1.0 if layer == 0 else 0.8))
		material.set_shader_parameter("speed", float(cfg.get("speed", 1.0)) * (1.0 if layer == 0 else 1.3))
		material.set_shader_parameter("seed", 0.37 + 1.91 * float(layer))
		material.set_shader_parameter("core_bias", 0.0 if layer == 0 else 0.12)
		# The inner card draws after the outer so the core sits in front.
		material.render_priority = layer
		card.material_override = material
		root.add_child(card)
	parent.add_child(root)
	return root
