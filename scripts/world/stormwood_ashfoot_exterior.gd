extends RefCounted

## r38 Ashfoot exterior (GPU SW9 outside judges: "a small Meadows-style
## cottage on a uniform grass carpet with an empty flat horizon"). A grove of
## the Ash Road's storm-canopy trees closes the open horizon behind the
## shelter (trunk colliders on every shell), and the ranger station gets
## Stormwood dressing: a copper lightning rod on the ridge with its ground
## cable, the Stormwood lantern post at the window wall, a rain barrel and a
## crate. Presentation only apart from the trunk colliders; nothing durable.
const CONFIG := "res://data/config/stormwood_ashfoot_exterior.json"
const LANTERN_POOLS := preload("res://scripts/world/stormwood_lantern_pools.gd")
const HERO_PROP := preload("res://scripts/world/meshy_hero_prop.gd")
const KIT := "res://assets/props/quaternius_fantasy/%s.gltf"


static func install(world: Node3D) -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG)) if FileAccess.file_exists(CONFIG) else {}
	if not bool(cfg.get("enabled", false)):
		return
	var root := Node3D.new()
	root.name = "AshfootExterior"
	world.add_child(root)
	var simulation_only := bool(world.get("simulation_only"))
	LANTERN_POOLS._grove(world, root, cfg.get("grove", {}), simulation_only)
	if simulation_only:
		return
	_dress(world, root, cfg.get("dressing", {}))


## Pieces in the shelter's own frame ([x, y, z] building-local metres, the
## prefab's door on +z and the window wall on +x), set on the ground there.
static func _dress(world: Node3D, root: Node3D, cfg: Dictionary) -> void:
	if not bool(cfg.get("enabled", false)):
		return
	var at: Array = cfg.get("shelter_at", [-365.0, 460.0])
	var frame := Transform3D(Basis(Vector3.UP, deg_to_rad(float(cfg.get("shelter_yaw_deg", 135.0)))), Vector3(float(at[0]), 0.0, float(at[1])))
	var ground := func(local: Vector3) -> Vector3:
		var p := frame * Vector3(local.x, 0.0, local.z)
		p.y = float(world.call("ground_height_at", p.x, p.z)) + local.y
		return p
	var copper := StandardMaterial3D.new()
	copper.albedo_color = Color(str(cfg.get("copper", "#a8744a")))
	copper.metallic = 0.8
	copper.roughness = 0.35
	# Lightning rod: a mast on the ridge and a cable down the window wall.
	var rod: Array = cfg.get("rod", [0.0, 6.2, 1.6, 2.6])
	var base := frame * Vector3(float(rod[0]), 0.0, float(rod[2]))
	var shelter_ground := float(world.call("ground_height_at", float(at[0]), float(at[1])))
	var mast_foot := Vector3(base.x, shelter_ground + float(rod[1]), base.z)
	_cylinder(root, "LightningRod", mast_foot + Vector3.UP * float(rod[3]) * 0.5, float(rod[3]), 0.035, copper)
	_cylinder(root, "LightningRodTip", mast_foot + Vector3.UP * (float(rod[3]) + 0.12), 0.25, 0.012, copper)
	var cable_top := frame * Vector3(2.12, 0.0, float(rod[2]))
	cable_top.y = shelter_ground + 3.0
	var cable_foot: Vector3 = ground.call(Vector3(2.15, 0.0, float(rod[2])))
	_cylinder(root, "RodCable", (cable_top + cable_foot) * 0.5, cable_top.distance_to(cable_foot), 0.02, copper)
	# The Stormwood lantern post (Meshy, Lantern Pools) at the window wall.
	var post_cfg: Dictionary = cfg.get("lantern_post", {})
	var post := HERO_PROP.load_model(str(post_cfg.get("model", "")))
	if post != null:
		HERO_PROP.fit_height(post, float(post_cfg.get("height_m", 2.6)), 0.0)
		var holder := Node3D.new()
		holder.name = "AshfootLanternPost"
		var local: Array = post_cfg.get("at", [3.1, 0.0, -1.2])
		holder.position = ground.call(Vector3(float(local[0]), 0.0, float(local[2])))
		holder.rotation.y = deg_to_rad(float(cfg.get("shelter_yaw_deg", 135.0)) + float(post_cfg.get("yaw_deg", 90.0)))
		holder.add_child(post)
		root.add_child(holder)
		var light := OmniLight3D.new()
		light.light_color = Color(str(post_cfg.get("light_colour", "#ffb066")))
		light.light_energy = float(post_cfg.get("light_energy", 1.2))
		light.omni_range = float(post_cfg.get("light_range_m", 6.0))
		light.position = holder.position + Vector3.UP * float(post_cfg.get("light_y_m", 2.1))
		root.add_child(light)
	for raw: Variant in cfg.get("kit", []):
		var piece: Dictionary = raw
		var scene := load(KIT % str(piece.get("model", ""))) as PackedScene
		if scene == null:
			continue
		var prop := scene.instantiate() as Node3D
		var local: Array = piece.get("at", [0.0, 0.0, 0.0])
		prop.position = ground.call(Vector3(float(local[0]), 0.0, float(local[2])))
		prop.rotation.y = deg_to_rad(float(cfg.get("shelter_yaw_deg", 135.0)) + float(piece.get("yaw_deg", 0.0)))
		prop.scale = Vector3.ONE * float(piece.get("scale", 1.0))
		root.add_child(prop)


static func _cylinder(root: Node3D, id: String, at: Vector3, height: float, radius: float, material: Material) -> void:
	var visual := MeshInstance3D.new()
	visual.name = id
	var mesh := CylinderMesh.new()
	mesh.height = height
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.radial_segments = 8
	visual.mesh = mesh
	visual.material_override = material
	visual.position = at
	root.add_child(visual)
