extends Node3D

## F13#5 / F14#1: the Veilfall interior art pass (Heart Chamber and the three
## rooms before it), presentation only.
##
## The code-blind C3 judge read Nerissa's fight room as a grey blockout: flat
## single-colour boxes under one cold point light, a pale prism and a banner
## seen edge-on as a "stray blue slab" (`f14_c3_judge/VERDICT_r1.md`, V-TW-12).
## The Veilfall stronghold board's Heart Chamber is dressed grey masonry with
## arches, blue emblem banners, warm torches against a cool crystal, and falling
## water inside the hall. This layer maps that onto what `water_veilfall.gd`
## already builds, using only installed families:
##   * stone/floor boxes take the Quaternius uneven-brick masonry texture
##     (world triplanar, so no UVs are authored on primitive boxes);
##   * `interior_structure.gd`'s bays, course, ribs and corners give the halls
##     their middle scale (no colliders; never past its 0.5 m clamp);
##   * `Lantern_Wall` fixtures with a small warm light along the side walls;
##   * a falling-water wall behind the crystal (the exterior curtain shader).
## Nothing here collides, moves a collider, prompt, captain, Guardian or gate.
## Host simulation shells (no renderer) skip it.

const STRUCTURE := preload("res://scripts/world/interior_structure.gd")

var receipt: Dictionary = {}
var _textures: Dictionary = {}


func build(interior: Node3D, rules: Dictionary) -> void:
	var cfg: Dictionary = rules.get("interior_dressing", {})
	if not bool(cfg.get("enabled", false)):
		return
	var colours: Dictionary = rules.get("colours", {})
	var skins := {
		Color(str(colours.get("stone", "#4c5857"))).to_html(false): _masonry(cfg.get("stone", {})),
		Color(str(colours.get("floor", "#77817a"))).to_html(false): _masonry(cfg.get("floor", {})),
	}
	if cfg.has("channel_water"):
		skins[Color(str(colours.get("channel", "#347c89"))).to_html(false)] = _water(cfg.channel_water)
	receipt["reskinned"] = _reskin(interior, skins)
	receipt["members"] = _structure(interior, rules, cfg.get("structure", {}))
	receipt["lanterns"] = _lanterns(interior, rules, cfg.get("lanterns", {}))
	receipt["fall_wall"] = _fall_wall(interior, cfg.get("fall_wall", {}))
	_room_light(interior, cfg.get("room_light", {}))


## Every box `water_veilfall.gd` built in a stone or floor colour wears the
## masonry instead. Matched by its authored colour, so machinery, brass, the
## channel water and the banners keep their own materials.
func _reskin(node: Node, skins: Dictionary) -> int:
	var count := 0
	for child: Node in node.get_children():
		if child is MeshInstance3D and (child as MeshInstance3D).mesh is BoxMesh:
			var box: BoxMesh = (child as MeshInstance3D).mesh
			var old := box.material as StandardMaterial3D
			if old != null:
				var key := old.albedo_color.to_html(false)
				if skins.has(key):
					(child as MeshInstance3D).material_override = skins[key]
					count += 1
		count += _reskin(child, skins)
	return count


func _masonry(cfg: Dictionary) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = _texture(str(cfg.get("albedo", "")))
	material.albedo_color = Color(str(cfg.get("tint", "#ffffff")))
	var normal_path := str(cfg.get("normal", ""))
	if not normal_path.is_empty():
		material.normal_enabled = true
		material.normal_texture = _texture(normal_path)
		material.normal_scale = float(cfg.get("normal_scale", 0.8))
	material.roughness = float(cfg.get("roughness", 0.8))
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_triplanar_sharpness = 6.0
	material.uv1_scale = Vector3.ONE * float(cfg.get("uv_scale", 0.35))
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return material


## The pump troughs' water: dark, glossy and faintly lit from below, instead
## of a flat opaque cyan slab.
func _water(cfg: Dictionary) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(str(cfg.get("colour", "#1d4a55")))
	material.roughness = float(cfg.get("roughness", 0.04))
	material.metallic = float(cfg.get("metallic", 0.2))
	material.metallic_specular = 1.0
	material.emission_enabled = true
	material.emission = Color(str(cfg.get("glow", "#123a44")))
	material.emission_energy_multiplier = float(cfg.get("glow_energy", 0.35))
	return material


func _texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if not _textures.has(path):
		_textures[path] = load(path)
	return _textures[path]


## The shared constructed-interior grammar at masonry settings: bays with
## capitals on every long wall, a mid-height course, ceiling ribs landed on
## the bays and corner posts. Doorways are the room joints the halls share.
func _structure(interior: Node3D, rules: Dictionary, cfg: Dictionary) -> int:
	if not bool(cfg.get("enabled", false)):
		return 0
	var height := float(rules.get("wall_height_m", 12.0))
	var chambers: Array = []
	for room: Dictionary in rules.get("rooms", []):
		chambers.append({
			"id": str(room.get("id", "")),
			"centre": Vector3(float(room.center_xz[0]), 0.0, float(room.center_xz[1])),
			"size": Vector2(float(room.size_xz[0]), float(room.size_xz[1])),
			"height": height, "open": false,
		})
	var doorways: Array = []
	for door: Array in cfg.get("doorways", []):
		doorways.append([Vector3(float(door[0]), 0.0, float(door[1])), float(door[2])])
	var tints: Dictionary = cfg.get("tints", {})
	var trim_cfg: Dictionary = cfg.get("trim", {})
	var materials: Dictionary = {}
	return STRUCTURE.new().dress(interior, {
		"chambers": chambers, "doorways": doorways, "openings": [],
		"floor_y": 0.0, "config": cfg,
		"material_for": func(role: String) -> StandardMaterial3D:
			var tint := str(tints.get(role, trim_cfg.get("tint", "#ffffff")))
			if not materials.has(tint):
				var spec := trim_cfg.duplicate()
				spec["tint"] = tint
				materials[tint] = _masonry(spec)
			return materials[tint],
	})


## Warm fixtures along both side walls of every room, facing into it. Only the
## small glass insert emits (the dock lanterns' finding: a fully emissive
## fixture bleaches its own silhouette).
func _lanterns(interior: Node3D, rules: Dictionary, cfg: Dictionary) -> int:
	if not bool(cfg.get("enabled", false)):
		return 0
	var scene: PackedScene = load(str(cfg.get("model", "")))
	if scene == null:
		return 0
	var thickness := float(rules.get("wall_thickness_m", 1.0))
	var spacing := float(cfg.get("spacing_m", 9.0))
	var placed := 0
	for room: Dictionary in rules.get("rooms", []):
		var centre := Vector3(float(room.center_xz[0]), 0.0, float(room.center_xz[1]))
		var width := float(room.size_xz[0])
		var length := float(room.size_xz[1])
		var count := maxi(1, int(round(length / spacing)))
		for side in [-1, 1]:
			for index in count:
				var z := centre.z - length * 0.5 + (index + 0.5) * length / count
				var at := Vector3(side * (width * 0.5 - thickness * 0.5), float(cfg.get("height_m", 3.4)), z)
				_lantern(interior, scene, at, -side, cfg)
				placed += 1
	return placed


func _lantern(interior: Node3D, scene: PackedScene, at: Vector3, facing_x: int, cfg: Dictionary) -> void:
	var fixture: Node3D = scene.instantiate()
	fixture.name = "VeilfallLantern"
	interior.add_child(fixture)
	fixture.position = at
	# The installed fixture's glass sits along its local +Z: turn +Z into the room.
	fixture.rotation.y = PI * 0.5 * facing_x
	fixture.scale = Vector3.ONE * float(cfg.get("scale", 2.2))
	var housing := StandardMaterial3D.new()
	housing.albedo_color = Color(str(cfg.get("housing_colour", "#4d4032")))
	housing.roughness = 0.7
	for found: Node in fixture.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := found as MeshInstance3D
		if mesh_instance.mesh != null:
			for surface in mesh_instance.mesh.get_surface_count():
				mesh_instance.set_surface_override_material(surface, housing)
	var glass := MeshInstance3D.new()
	glass.name = "LanternGlass"
	var box := BoxMesh.new()
	box.size = Vector3(0.18, 0.24, 0.18)
	glass.mesh = box
	glass.position = Vector3(0.0, 0.32, 0.807)
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(str(cfg.get("glass_colour", "#ffbc66")))
	glow.emission_enabled = true
	glow.emission = Color(str(cfg.get("glow_colour", "#ff9e36")))
	glow.emission_energy_multiplier = float(cfg.get("glow_energy", 1.2))
	glass.material_override = glow
	fixture.add_child(glass)
	var light := OmniLight3D.new()
	light.light_color = Color(str(cfg.get("light_colour", "#ffb870")))
	light.light_energy = float(cfg.get("light_energy", 1.6))
	light.omni_range = float(cfg.get("light_range_m", 8.0))
	light.shadow_enabled = false
	interior.add_child(light)
	light.position = at + Vector3(facing_x * 1.2, 0.2, 0.0)


## The board's Heart Chamber has the falls inside the hall. A falling-water
## sheet on the back wall behind the crystal, with the exterior curtain's own
## shader and a flat ground line (the chamber floor), plus a lit plunge channel.
func _fall_wall(interior: Node3D, cfg: Dictionary) -> bool:
	if not bool(cfg.get("enabled", false)):
		return false
	var width := float(cfg.get("width_m", 16.0))
	var height := float(cfg.get("height_m", 12.0))
	var at_raw: Array = cfg.get("centre", [0.0, 6.0, 123.3])
	var at := Vector3(float(at_raw[0]), float(at_raw[1]), float(at_raw[2]))
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/waterfall_curtain.gdshader")
	material.set_shader_parameter("water_colour", Color(str(cfg.get("colour", "#e6f6f8"))))
	for key in ["opacity_min", "opacity_max", "flow_speed", "edge_feather", "ground_feather_m", "albedo_min", "albedo_max"]:
		if cfg.has(key):
			material.set_shader_parameter(key, float(cfg[key]))
	var floor_world := interior.global_position.y + at.y - height * 0.5 - 1.0
	var heights := Image.create(2, 1, false, Image.FORMAT_RF)
	heights.set_pixel(0, 0, Color(floor_world, 0, 0))
	heights.set_pixel(1, 0, Color(floor_world, 0, 0))
	material.set_shader_parameter("ground_heights", ImageTexture.create_from_image(heights))
	material.set_shader_parameter("ground_span", Vector2(interior.global_position.x + at.x - width * 0.5,
		interior.global_position.x + at.x + width * 0.5))
	var sheet := MeshInstance3D.new()
	sheet.name = "HeartChamberFallWall"
	var plane := PlaneMesh.new()
	plane.size = Vector2(width, height)
	plane.material = material
	sheet.mesh = plane
	sheet.rotation.x = PI * 0.5
	sheet.position = at
	sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	interior.add_child(sheet)
	var pool := MeshInstance3D.new()
	pool.name = "HeartChamberPlungeChannel"
	var slab := BoxMesh.new()
	slab.size = Vector3(width, 0.06, float(cfg.get("channel_depth_m", 2.2)))
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(str(cfg.get("channel_colour", "#2f7d8c")))
	water.roughness = 0.08
	water.metallic_specular = 0.9
	water.emission_enabled = true
	water.emission = Color(str(cfg.get("channel_glow", "#1d5866")))
	water.emission_energy_multiplier = 0.5
	slab.material = water
	pool.mesh = slab
	pool.position = Vector3(at.x, 0.04, at.z - float(cfg.get("channel_depth_m", 2.2)) * 0.5)
	interior.add_child(pool)
	var light := OmniLight3D.new()
	light.light_color = Color(str(cfg.get("light_colour", "#9fd6e6")))
	light.light_energy = float(cfg.get("light_energy", 1.4))
	light.omni_range = float(cfg.get("light_range_m", 16.0))
	light.shadow_enabled = false
	interior.add_child(light)
	light.position = at + Vector3(0.0, -2.0, -3.0)
	return true


## The rooms' own fill lights were a single cold white at energy 2.0, which is
## what flattened every wall to one mid-grey. Dimmer and cooler, so the warm
## fixtures and the crystal carry the value range.
func _room_light(interior: Node3D, cfg: Dictionary) -> void:
	if cfg.is_empty():
		return
	for child: Node in interior.get_children():
		if child is OmniLight3D and child.name.begins_with("RoomFill"):
			(child as OmniLight3D).light_color = Color(str(cfg.get("colour", "#9fb4c4")))
			(child as OmniLight3D).light_energy = float(cfg.get("energy", 1.1))
