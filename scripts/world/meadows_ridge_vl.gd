extends RefCounted

## Visual lane (3 Nov), F38#24 / P2-014 "Meadows mountains": the Blender ridge
## ring (assets/props/vl-1103/meadows_ridge) as one continuous, naturalistic
## ridge backdrop in place of the two procedural horizon rings. Config:
## data/config/meadows_ridge_vl.json, OFF until judged. OFF: nothing here runs
## and horizon_ranges.gd builds exactly what it built before. ON: the ridge is
## added under HorizonRanges (so it follows the camera like the rings) and the
## named procedural layers are not built. Presentation only: no collider, no
## shadow, no camera or gameplay change.
const CONFIG := "res://data/config/meadows_ridge_vl.json"
const SHADER := preload("res://shaders/meadows_ridge_far.gdshader")
const NODE_NAME := "MeadowsRidgeVL"


static func settings() -> Dictionary:
	if not FileAccess.file_exists(CONFIG):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	return parsed if parsed is Dictionary else {}


static func enabled(config: Dictionary = {}) -> bool:
	var source := config if not config.is_empty() else settings()
	return bool(source.get("enabled", false))


## The procedural layer names ON leaves unbuilt; empty when OFF.
static func replaced_layers(config: Dictionary = {}) -> Array:
	var source := config if not config.is_empty() else settings()
	if not bool(source.get("enabled", false)):
		return []
	return source.get("replace_layers", []) as Array


## Builds the ridge under `parent` (HorizonRanges, whose local origin is the
## camera-centred ring base). Returns null when OFF or the model is missing.
static func build(parent: Node3D, config: Dictionary = {}) -> Node3D:
	var cfg := config if not config.is_empty() else settings()
	if not bool(cfg.get("enabled", false)) or parent == null or parent.has_node(NODE_NAME):
		return null
	var packed := load(str(cfg.get("model", ""))) as PackedScene
	if packed == null:
		push_warning("meadows_ridge_vl: model missing: " + str(cfg.get("model", "")))
		return null
	var model := packed.instantiate() as Node3D
	model.name = NODE_NAME
	model.position = Vector3(0.0, -float(cfg.get("sink_m", 0.0)), 0.0)
	model.rotation.y = deg_to_rad(float(cfg.get("yaw_deg", 0.0)))
	var vertical := float(cfg.get("height_scale", 1.0))
	var across := float(cfg.get("scale_xz", 1.0))
	model.scale = Vector3(across, vertical, across)
	var shader_cfg: Dictionary = cfg.get("shader", {}) as Dictionary
	_apply_far_material(model, shader_cfg)
	# `back_layer` (F38#24, LANE-LAND-MT 13 Nov, OFF until judged): a second
	# copy of the same continuous ridge, set further out, taller, turned and
	# hazier, so the skyline reads as two ranges in depth instead of one card
	# (LANE-JUDGE G-rescore-f38-24-after-952: "flat painted cards with little
	# aerial layering"). It is a child of the front ridge, so it follows the
	# camera with it and sync_fog reaches its materials too. Keep the back
	# copy's scale_xz at or under 1.0: the ridge's back edge is 1945 m and the
	# gameplay camera's far plane is 2000 m.
	var back: Dictionary = cfg.get("back_layer", {}) as Dictionary
	if bool(back.get("enabled", false)):
		var far_model := packed.instantiate() as Node3D
		far_model.name = NODE_NAME + "Back"
		var back_xz := float(back.get("scale_xz", 1.0)) / maxf(across, 0.01)
		far_model.scale = Vector3(back_xz, float(back.get("height_scale", 1.0)) / maxf(vertical, 0.01), back_xz)
		far_model.rotation.y = deg_to_rad(float(back.get("yaw_deg", 0.0)))
		far_model.position = Vector3(0.0, -float(back.get("sink_m", 0.0)) / maxf(vertical, 0.01), 0.0)
		var back_shader := shader_cfg.duplicate()
		back_shader.merge(back.get("shader", {}) as Dictionary, true)
		_apply_far_material(far_model, back_shader)
		model.add_child(far_model)
	parent.add_child(model)
	return model


## Replaces every surface of `model` with the far ridge shader, carrying the
## source albedo atlas and the given shader values.
static func _apply_far_material(model: Node3D, shader_cfg: Dictionary) -> void:
	for raw: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := raw as MeshInstance3D
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		mesh.extra_cull_margin = 200.0
		if mesh.mesh == null:
			continue
		for surface in mesh.mesh.get_surface_count():
			var source := mesh.get_active_material(surface) as BaseMaterial3D
			var far := ShaderMaterial.new()
			far.shader = SHADER
			if source != null and source.albedo_texture != null:
				far.set_shader_parameter("albedo_tex", source.albedo_texture)
			for key: String in shader_cfg:
				if key.begins_with("_"):
					continue
				var value: Variant = shader_cfg[key]
				far.set_shader_parameter(key, Color(str(value)) if value is String else value)
			mesh.set_surface_override_material(surface, far)


## Copies the live environment fog into the ridge materials (called from
## HorizonRanges._process only while the ridge exists).
static func sync_fog(ridge: Node3D, environment: Environment, base_y_world: float) -> void:
	if ridge == null or environment == null:
		return
	for raw: Node in ridge.find_children("*", "MeshInstance3D", true, false):
		var mesh := raw as MeshInstance3D
		if mesh.mesh == null:
			continue
		for surface in mesh.mesh.get_surface_count():
			var far := mesh.get_surface_override_material(surface) as ShaderMaterial
			if far == null:
				continue
			var colour := environment.fog_light_color.srgb_to_linear()
			far.set_shader_parameter("fog_colour", Vector3(colour.r, colour.g, colour.b))
			far.set_shader_parameter("fog_density", environment.fog_density)
			far.set_shader_parameter("fog_enabled", environment.fog_enabled)
			far.set_shader_parameter("base_y_world", base_y_world)
