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
## Named materials a prop entry may wear (`skin`): the installed arches and
## railings are white plaster, which read as a picket fence on dark stone.
var _skins_by_name: Dictionary = {}


func build(interior: Node3D, rules: Dictionary) -> void:
	var cfg: Dictionary = rules.get("interior_dressing", {})
	if not bool(cfg.get("enabled", false)):
		return
	var colours: Dictionary = rules.get("colours", {})
	var skins := {
		Color(str(colours.get("stone", "#4c5857"))).to_html(false): _masonry(cfg.get("stone", {})),
		Color(str(colours.get("floor", "#77817a"))).to_html(false): _masonry(cfg.get("floor", {})),
	}
	if cfg.has("metal"):
		skins[Color(str(colours.get("metal", "#697676"))).to_html(false)] = _masonry(cfg.metal)
	if cfg.has("channel_water"):
		skins[Color(str(colours.get("channel", "#347c89"))).to_html(false)] = _water(cfg.channel_water)
	receipt["reskinned"] = _reskin(interior, skins)
	receipt["members"] = _structure(interior, rules, cfg.get("structure", {}))
	receipt["lanterns"] = _lanterns(interior, rules, cfg.get("lanterns", {}))
	receipt["fall_wall"] = _fall_wall(interior, cfg.get("fall_wall", {}))
	receipt["ledges"] = _ledges(interior, cfg.get("ledges", []), _masonry(cfg.get("stone", {})))
	_skins_by_name = {
		"stone": _masonry(cfg.get("structure", {}).get("trim", cfg.get("stone", {}))),
		"metal": _masonry(cfg.get("metal", {})) if cfg.has("metal") else null,
	}
	receipt["props"] = _props(interior, cfg.get("props", []))
	receipt["machines"] = _machines(interior, cfg.get("machines", {}))
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


## Board: the Heart Chamber is a multi-level hall (galleries, a bridge before
## the falls). Stone ledges in the wall masonry, out of reach and without
## colliders, carry the installed balcony railings and vines placed by
## `_props`. Each entry: {at: [x, y, z], size: [x, y, z]} interior-local.
func _ledges(interior: Node3D, entries: Array, stone: StandardMaterial3D) -> int:
	var placed := 0
	for entry: Dictionary in entries:
		var mesh := MeshInstance3D.new()
		mesh.name = "VeilfallLedge"
		var box := BoxMesh.new()
		box.size = _vec(entry.get("size", [1, 1, 1]))
		mesh.mesh = box
		mesh.material_override = stone
		mesh.position = _vec(entry.get("at", [0, 0, 0]))
		interior.add_child(mesh)
		placed += 1
	return placed


## Installed props at authored interior-local spots, dressing each room for
## what it is named for. Entry: {model, at, yaw_deg, scale, rows?}. A `row`
## repeats the prop `count` times along `step` (railings, arches, vines).
## Presentation only: no colliders are added, and every spot is kept against a
## wall or up on a ledge, outside the Heart Chamber's fight ring.
func _props(interior: Node3D, entries: Array) -> int:
	var placed := 0
	var scenes: Dictionary = {}
	for entry: Dictionary in entries:
		var path := str(entry.get("model", ""))
		if not scenes.has(path):
			scenes[path] = load(path)
		var scene: PackedScene = scenes[path]
		if scene == null:
			continue
		var at := _vec(entry.get("at", [0, 0, 0]))
		var step := _vec(entry.get("step", [0, 0, 0]))
		for index in int(entry.get("count", 1)):
			var node: Node3D = scene.instantiate()
			node.name = "VeilfallProp"
			interior.add_child(node)
			node.position = at + step * index
			node.rotation = Vector3(deg_to_rad(float(entry.get("pitch_deg", 0.0))),
				deg_to_rad(float(entry.get("yaw_deg", 0.0))), deg_to_rad(float(entry.get("roll_deg", 0.0))))
			node.scale = Vector3.ONE * float(entry.get("scale", 1.0))
			var skin: Variant = _skins_by_name.get(str(entry.get("skin", "")))
			if skin is Material:
				for found: Node in node.find_children("*", "MeshInstance3D", true, false) + ([node] if node is MeshInstance3D else []):
					(found as MeshInstance3D).material_override = skin
			placed += 1
	return placed


func _vec(raw: Variant) -> Vector3:
	var a: Array = raw if raw is Array else [0, 0, 0]
	return Vector3(float(a[0]), float(a[1]), float(a[2]))



## Owner ruling 22:25 (#356 5860380772): kitbash the Pump Hall and Sluice from
## installed families. The judge (r1, r2): "rooms named for their function
## carry no pump, pipe, gear or sluice gate". Machines are primitives wearing
## the installed Quaternius metal / wood-trim textures and a brass trim, laid
## out by `machines` in water_veilfall.json: `pipes` runs, `pumps` (tank,
## riser, gear), `gears` wall wheels, `sluice_gates` (posts, lintel, winch
## drums). No colliders; controls, prompts and grilles are untouched.
func _machines(interior: Node3D, cfg: Dictionary) -> int:
	if not bool(cfg.get("enabled", false)):
		return 0
	var metal := _masonry(cfg.get("metal", {}))
	var wood := _masonry(cfg.get("wood", {}))
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color(str(cfg.get("brass", "#b08a4e")))
	brass.metallic = 0.7
	brass.roughness = 0.35
	var placed := 0
	for run: Dictionary in cfg.get("pipes", []):
		var a := _vec(run.from)
		var b := _vec(run.to)
		var radius := float(run.get("radius_m", 0.22))
		placed += _pipe(interior, a, b, radius, metal)
		var flange_every := float(run.get("flange_every_m", 5.0))
		var length := a.distance_to(b)
		var steps := int(floor(length / flange_every))
		for i in range(1, steps + 1):
			var at := a.lerp(b, float(i) * flange_every / length)
			placed += _pipe(interior, at - (b - a).normalized() * 0.08, at + (b - a).normalized() * 0.08, radius * 1.45, brass)
	for pump: Dictionary in cfg.get("pumps", []):
		var at := _vec(pump.at)
		var tank_r := float(pump.get("tank_radius_m", 0.9))
		var tank_h := float(pump.get("tank_height_m", 2.4))
		placed += _pipe(interior, at, at + Vector3.UP * tank_h, tank_r, wood)
		for band in [0.18, 0.5, 0.82]:
			var y: float = tank_h * float(band)
			placed += _pipe(interior, at + Vector3.UP * (y - 0.06), at + Vector3.UP * (y + 0.06), tank_r * 1.04, metal)
		placed += _pipe(interior, at + Vector3.UP * tank_h, at + Vector3.UP * float(pump.get("riser_top_m", 11.5)), 0.28, metal)
		placed += _gear(interior, at + _vec(pump.get("gear_offset", [1.3, 1.4, 0])), float(pump.get("gear_radius_m", 1.0)), Vector3.RIGHT, metal, brass)
	for gear: Dictionary in cfg.get("gears", []):
		placed += _gear(interior, _vec(gear.at), float(gear.get("radius_m", 1.6)), _vec(gear.get("axis", [1, 0, 0])), metal, brass)
	for gate: Dictionary in cfg.get("sluice_gates", []):
		var z := float(gate.z)
		var half := float(gate.width_m) * 0.5
		var height := float(gate.get("height_m", 8.5))
		var base := float(gate.get("base_y", 0.0))
		for side in [-1, 1]:
			placed += _slab(interior, Vector3(side * half, (height + base) * 0.5, z), Vector3(0.9, height - base, 0.9), wood)
			placed += _gear(interior, Vector3(side * (half - 0.6), height - 1.6, z - 0.7), 1.1, Vector3.BACK, metal, brass)
		placed += _slab(interior, Vector3(0, height, z), Vector3(half * 2.0 + 0.9, 0.8, 1.0), wood)
		for x in gate.get("drums_x", [-4.0, 4.0]):
			placed += _pipe(interior, Vector3(float(x) - 1.0, height + 0.8, z), Vector3(float(x) + 1.0, height + 0.8, z), 0.45, metal)
	return placed


func _pipe(parent: Node3D, a: Vector3, b: Vector3, radius: float, material: Material) -> int:
	var length := a.distance_to(b)
	if length < 0.01:
		return 0
	var mesh := MeshInstance3D.new()
	mesh.name = "VeilfallMachine"
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = length
	cyl.radial_segments = 16
	mesh.mesh = cyl
	mesh.material_override = material
	parent.add_child(mesh)
	var up := (b - a) / length
	var basis := Basis.IDENTITY
	if absf(up.dot(Vector3.UP)) < 0.999:
		var x := up.cross(Vector3.UP).normalized()
		basis = Basis(x, up, x.cross(up))
	elif up.y < 0.0:
		basis = Basis(Vector3.RIGHT, PI)
	mesh.transform = Transform3D(basis, (a + b) * 0.5)
	return 1


func _slab(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> int:
	var mesh := MeshInstance3D.new()
	mesh.name = "VeilfallMachine"
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	mesh.position = at
	parent.add_child(mesh)
	return 1


## A toothed wheel: a disc, a hub and eight teeth, facing along `axis`.
func _gear(parent: Node3D, at: Vector3, radius: float, axis: Vector3, metal: Material, brass: Material) -> int:
	var n := axis.normalized()
	var placed := _pipe(parent, at - n * 0.12, at + n * 0.12, radius, metal)
	placed += _pipe(parent, at - n * 0.2, at + n * 0.2, radius * 0.28, brass)
	var u := n.cross(Vector3.UP if absf(n.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT).normalized()
	var v := n.cross(u)
	for i in 8:
		var angle := TAU * i / 8.0
		var dir := u * cos(angle) + v * sin(angle)
		placed += _pipe(parent, at + dir * radius * 0.95, at + dir * (radius + 0.28), 0.14, metal)
	return placed
