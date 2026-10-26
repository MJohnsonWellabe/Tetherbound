extends RefCounted

## r41 Crown Overlook vista (coordinator, 26 Oct: build the real vista).
## GPU SW8 judges: "no vista at crown overlook"; r40 judges: the Crown massif
## reads at 900 m as "a flat grey slab". Two flagged pieces:
## - `deck`: a raised timber lookout beside the Crown Sightline loop, its
##   ramp running back to the path, railings on three sides and a lit Meshy
##   Stormwood lantern post; deck, ramp and rails collide on every shell.
## - `massif`: a distant-only Hollow Crown silhouette (Meshy, requested 26
##   Oct), drawn beyond `visible_from_m` so play inside the Crown is
##   untouched; no collision.
const CONFIG := "res://data/config/stormwood_crown_overlook.json"
const HERO_PROP := preload("res://scripts/world/meshy_hero_prop.gd")
const LANTERN_POOLS := preload("res://scripts/world/stormwood_lantern_pools.gd")
const CUT_WOOD_SHADER := preload("res://scripts/world/stormheart_cut_wood.gdshader")
const WOOD_ATLAS := preload("res://assets/buildings/quaternius_medieval/T_WoodTrim_BaseColor.png")


static func install(world: Node3D) -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG)) if FileAccess.file_exists(CONFIG) else {}
	var draw := not bool(world.get("simulation_only"))
	var deck: Dictionary = cfg.get("deck", {})
	if bool(deck.get("enabled", false)):
		build_deck(world, deck, draw)
	var massif: Dictionary = cfg.get("massif", {})
	if draw and bool(massif.get("enabled", false)):
		_massif(world, massif)


## The deck's own frame: origin at the deck centre on its floor, +Z along
## `heading_deg` (toward the view), so the ramp runs down -Z.
static func deck_frame(world: Node3D, cfg: Dictionary) -> Transform3D:
	var at: Array = cfg.get("at", [169.0, 1992.0])
	var half: Array = cfg.get("half_m", [3.0, 3.0])
	var yaw := deg_to_rad(float(cfg.get("heading_deg", 37.0)))
	var basis := Basis(Vector3.UP, yaw)
	var high := -INF
	for u: float in [-1.0, 1.0]:
		for v: float in [-1.0, 1.0]:
			var p := Vector3(float(at[0]), 0.0, float(at[1])) + basis * Vector3(float(half[0]) * u, 0.0, float(half[1]) * v)
			high = maxf(high, float(world.call("ground_height_at", p.x, p.z)))
	return Transform3D(basis, Vector3(float(at[0]), high + float(cfg.get("height_m", 2.6)), float(at[1])))


static func build_deck(world: Node3D, cfg: Dictionary, draw: bool) -> Node3D:
	var frame := deck_frame(world, cfg)
	var root := Node3D.new()
	root.name = "CrownOverlookDeck"
	root.transform = frame
	world.add_child(root)
	var body := StaticBody3D.new()
	body.name = "CrownOverlookDeckBody"
	root.add_child(body)
	var half: Array = cfg.get("half_m", [3.0, 3.0])
	var hx := float(half[0])
	var hz := float(half[1])
	var thick := 0.25
	var wood: Material = null
	var dark: Material = null
	if draw:
		var cut := ShaderMaterial.new()
		cut.shader = CUT_WOOD_SHADER
		cut.set_shader_parameter("wood_atlas", WOOD_ATLAS)
		cut.set_shader_parameter("wood_tint", Color(str(cfg.get("wood_tint", "#a8a299"))))
		cut.set_shader_parameter("weathering", float(cfg.get("weathering", 0.8)))
		wood = cut
		var timber := StandardMaterial3D.new()
		timber.albedo_color = Color(str(cfg.get("frame_colour", "#3f3226")))
		timber.roughness = 0.85
		dark = timber
	# Floor.
	_part(body, "Floor", Vector3(hx * 2.0, thick, hz * 2.0), Vector3(0.0, -thick * 0.5, 0.0), Basis(), wood, draw, true)
	# Ramp down the back (-Z) to the path.
	var height := float(cfg.get("height_m", 2.6))
	var ramp_len := float(cfg.get("ramp_m", 7.0))
	var ramp_w := float(cfg.get("ramp_width_m", 2.2))
	var slope := atan2(height, ramp_len)
	var run := sqrt(ramp_len * ramp_len + height * height)
	var ramp_basis := Basis(Vector3.RIGHT, -slope)
	_part(body, "Ramp", Vector3(ramp_w, thick, run), Vector3(0.0, -height * 0.5 - thick * 0.5, -hz - ramp_len * 0.5), ramp_basis, wood, draw, true)
	# Rails on the front and both sides, a knee rail too.
	var rail_h := float(cfg.get("rail_height_m", 1.05))
	for rail: Array in [[Vector3(hx * 2.0, 0.1, 0.1), Vector3(0.0, rail_h, hz - 0.05)],
			[Vector3(0.1, 0.1, hz * 2.0), Vector3(-hx + 0.05, rail_h, 0.0)], [Vector3(0.1, 0.1, hz * 2.0), Vector3(hx - 0.05, rail_h, 0.0)]]:
		_part(body, "Rail", rail[0], rail[1], Basis(), dark, draw, true)
		_part(body, "KneeRail", rail[0], (rail[1] as Vector3) - Vector3(0.0, rail_h * 0.5, 0.0), Basis(), dark, draw, false)
	# Posts at the corners, down to the ground, and rail posts along the edges.
	for u: float in [-1.0, 1.0]:
		for v: float in [-1.0, 1.0]:
			var corner := Vector3(hx * u - 0.1 * u, 0.0, hz * v - 0.1 * v)
			var world_corner := frame * corner
			var drop := frame.origin.y - float(world.call("ground_height_at", world_corner.x, world_corner.z)) + 0.3
			_part(body, "Post", Vector3(0.24, drop + rail_h, 0.24), corner + Vector3(0.0, (rail_h - drop) * 0.5, 0.0), Basis(), dark, draw, true)
	if not draw:
		return root
	# The Stormwood lantern post on the front corner, lit.
	var lamp: Dictionary = cfg.get("lantern_post", {})
	if not lamp.is_empty():
		var seat := Node3D.new()
		seat.name = "OverlookLantern"
		var spot: Array = lamp.get("at", [2.4, 0.0, 2.4])
		seat.position = Vector3(float(spot[0]), 0.0, float(spot[2]))
		seat.rotation.y = deg_to_rad(float(lamp.get("turn_deg", 0.0)))
		root.add_child(seat)
		LANTERN_POOLS._hero_lantern(seat, lamp, lamp)
	return root


static func _part(body: StaticBody3D, id: String, size: Vector3, at: Vector3, basis: Basis, material: Material, draw: bool, solid: bool) -> void:
	if solid:
		var shape := BoxShape3D.new()
		shape.size = size
		var collider := CollisionShape3D.new()
		collider.name = id + "Collider"
		collider.shape = shape
		collider.transform = Transform3D(basis, at)
		body.add_child(collider)
	if not draw:
		return
	var visual := MeshInstance3D.new()
	visual.name = id
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	if material is ShaderMaterial:
		var lined := (material as ShaderMaterial).duplicate() as ShaderMaterial
		lined.set_shader_parameter("uv_metres", Vector2(size.x, size.z))
		visual.material_override = lined
	else:
		visual.material_override = material
	visual.transform = Transform3D(basis, at)
	body.add_child(visual)


static func _massif(world: Node3D, cfg: Dictionary) -> void:
	var model := HERO_PROP.load_model(str(cfg.get("model", "")))
	if model == null:
		push_warning("Crown Overlook massif: model unavailable")
		return
	var bounds := HERO_PROP.BOUNDS.measure(model)
	var factor := float(cfg.get("width_m", 520.0)) / maxf(0.01, maxf(bounds.size.x, bounds.size.z))
	model.scale = Vector3.ONE * factor
	model.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
	var holder := Node3D.new()
	holder.name = "HollowCrownSilhouette"
	var at: Array = cfg.get("at", [700.0, 2700.0])
	holder.position = Vector3(float(at[0]), float(cfg.get("base_y", 60.0)), float(at[1]))
	holder.rotation.y = deg_to_rad(float(cfg.get("yaw_deg", 0.0)))
	holder.add_child(model)
	for visual: GeometryInstance3D in model.find_children("*", "GeometryInstance3D", true, false):
		visual.visibility_range_begin = float(cfg.get("visible_from_m", 300.0))
		visual.visibility_range_begin_margin = float(cfg.get("fade_m", 40.0))
		visual.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(holder)
