extends Node3D

## The Ridgeline Watch's actual lookout, beside the existing patrol camp.
##
## `map_landmarks.json` names the region at (-250, 6490), while the authored
## patrol camp and optional trainer stand around (-242, 6470).  Until this
## node, the named place contained only that low camp dressing; the chapter's
## actual ruined stone tower is a different landmark, The Broken Tower, more
## than four hundred metres away.  This lookout gives the Ridgeline Watch its
## own silhouette without duplicating that ruin.
##
## Art comes from the already-installed Team Tether Hall kit.  Its scaffold is
## used at a larger lookout scale and capped with a procedural signal mast.
## Collision belongs only to four timber supports: the
## undercroft, the camp approach and the canonical debug-teleport position all
## remain walkable.

const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const IMPORTED_MATERIALS := preload("res://scripts/world/imported_materials.gd")
const LOOKOUT_SCENE := preload("res://assets/environment/team_tether/hall/team_tether_scaffold_tower.glb")
const WALL_LANTERN := preload("res://assets/props/quaternius_fantasy/Lantern_Wall.gltf")
const SUPPLY_CRATE := preload("res://assets/props/quaternius_fantasy/Crate_Wooden.gltf")
const SUPPLY_BARREL := preload("res://assets/props/quaternius_fantasy/Barrel.gltf")

const SITE := Vector2(-247.0, 6483.0)
const CANONICAL_VIEW := Vector2(-250.0, 6490.0)
## Western footpath approach: far enough to prove the signal silhouette,
## close enough to remain an ordinary on-foot view rather than an aerial.
const ORDINARY_APPROACH := Vector2(-271.0, 6470.0)
const CAMP_CENTRE := Vector2(-241.8, 6468.5)
const PATROL_TRAINER := Vector2(-235.0, 6470.0)

const MODEL_SCALE := 1.55
const SUPPORT_X := 4.55
const SUPPORT_Z := 1.15
const SUPPORT_SIZE := Vector3(0.52, 10.8, 0.52)
const MAST_HEIGHT := 5.2
const MIN_VISUAL_HEIGHT := 14.0
const SERVICE_SHELTER_CENTRE := Vector2(-7.0, -0.7)
const SERVICE_SHELTER_CLEARANCE := 3.0

const TIMBER := Color("#47382d")
const STONE := Color("#665f55")
const OXBLOOD := Color("#66362c")
const LANTERN := Color("#ffb663")
const CANVAS := Color("#4e493d")
const CANVAS_FADED := Color("#655c49")

var _visual_height := 0.0
var _support_world: Array[Vector2] = []
var _shelter_posts := 0
var _shelter_panels := 0
var _supply_props := 0


func build(world: Node) -> bool:
	if world == null or not world.has_method("ground_height_at"):
		push_error("Ridgeline Watch needs a world with ground_height_at()")
		return false
	var centre_ground := float(world.call("ground_height_at", SITE.x, SITE.y))
	if is_nan(centre_ground):
		push_error("no ground under Ridgeline Watch at %.0f, %.0f" % [SITE.x, SITE.y])
		return false
	position = Vector3(SITE.x, centre_ground, SITE.y)

	var frame := LOOKOUT_SCENE.instantiate() as Node3D
	if frame == null:
		push_error("Ridgeline Watch scaffold failed to instantiate")
		return false
	frame.name = "LookoutFrame"
	var bounds: AABB = RENDER_BOUNDS.measure(frame)
	if bounds.size == Vector3.ZERO:
		frame.free()
		push_error("Ridgeline Watch scaffold has no render bounds")
		return false
	frame.scale = Vector3.ONE * MODEL_SCALE
	frame.position.y = -bounds.position.y * MODEL_SCALE
	add_child(frame)

	var frame_top := (bounds.position.y + bounds.size.y) * MODEL_SCALE + frame.position.y
	_build_support_collision(world)
	_build_footings(world)
	_build_service_shelter(world)
	# The GLB's measured render box includes projecting joinery above its
	# visible central deck. Sink the mast into that joinery so it reads as one
	# structure from below instead of hovering over the perch.
	_build_signal_mast(frame_top - 1.8)
	_build_lantern(frame_top + 0.2)
	_visual_height = frame_top - 1.8 + MAST_HEIGHT
	return true


func stats() -> Dictionary:
	return {
		"site": SITE,
		"canonical_distance_m": SITE.distance_to(CANONICAL_VIEW),
		"approach_distance_m": SITE.distance_to(ORDINARY_APPROACH),
		"camp_clearance_m": SITE.distance_to(CAMP_CENTRE),
		"trainer_clearance_m": SITE.distance_to(PATROL_TRAINER),
		"visual_height_m": _visual_height,
		"support_count": _support_world.size(),
		"shelter_posts": _shelter_posts,
		"shelter_panels": _shelter_panels,
		"supply_props": _supply_props,
		"shelter_to_camp_m": (SITE + SERVICE_SHELTER_CENTRE).distance_to(CAMP_CENTRE),
		"shelter_to_trainer_m": (SITE + SERVICE_SHELTER_CENTRE).distance_to(PATROL_TRAINER),
	}


func support_world_positions() -> Array[Vector2]:
	return _support_world.duplicate()


func _build_support_collision(world: Node) -> void:
	var body := StaticBody3D.new()
	body.name = "WatchSupports"
	add_child(body)
	_support_world.clear()
	for local_x in [-SUPPORT_X, SUPPORT_X]:
		for local_z in [-SUPPORT_Z, SUPPORT_Z]:
			var at := SITE + Vector2(local_x, local_z)
			var foot_y := float(world.call("ground_height_at", at.x, at.y)) - position.y
			var shape := CollisionShape3D.new()
			shape.name = "Support_%s_%s" % ["W" if local_x < 0.0 else "E", "S" if local_z < 0.0 else "N"]
			var box := BoxShape3D.new()
			box.size = SUPPORT_SIZE
			shape.shape = box
			shape.position = Vector3(local_x, foot_y + SUPPORT_SIZE.y * 0.5, local_z)
			body.add_child(shape)
			_support_world.append(at)


func _build_footings(world: Node) -> void:
	var material := _material(STONE, 0.95)
	var holder := Node3D.new()
	holder.name = "StoneFootings"
	add_child(holder)
	for at in _support_world:
		var foot_y := float(world.call("ground_height_at", at.x, at.y)) - position.y
		var footing := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.58
		mesh.bottom_radius = 0.72
		mesh.height = 0.48
		mesh.radial_segments = 8
		mesh.material = material
		footing.mesh = mesh
		footing.position = Vector3(at.x - SITE.x, foot_y + 0.24, at.y - SITE.y)
		holder.add_child(footing)


func _build_signal_mast(base_y: float) -> void:
	var holder := Node3D.new()
	holder.name = "SignalMast"
	add_child(holder)
	# Carry the signal pole down through the open upper bay. From the canonical
	# arrival the skyline pole must visibly belong to the scaffold, not end in
	# the patch of sky above its top rail.
	_box(holder, "MastFoot", Vector3(0.30, 2.8, 0.30),
		Vector3(0.0, base_y - 1.25, 0.0), TIMBER)
	_box(holder, "Mast", Vector3(0.24, MAST_HEIGHT, 0.24),
		Vector3(0.0, base_y + MAST_HEIGHT * 0.5 - 0.2, 0.0), TIMBER)
	_box(holder, "CrossArm", Vector3(3.0, 0.18, 0.18),
		Vector3(0.0, base_y + MAST_HEIGHT - 1.0, 0.0), TIMBER)
	# Two narrow pennants survive the ordinary approach as one unmistakable
	# faction signal without turning the whole roof into an oxblood billboard.
	_box(holder, "PennantWest", Vector3(0.85, 1.9, 0.08),
		Vector3(-1.02, base_y + MAST_HEIGHT - 2.0, 0.0), OXBLOOD)
	_box(holder, "PennantEast", Vector3(0.62, 1.45, 0.08),
		Vector3(1.12, base_y + MAST_HEIGHT - 1.75, 0.0), OXBLOOD)


func _build_service_shelter(world: Node) -> void:
	# The watch was a repeated brace cage with no sign that a patrol could use
	# it. A low service lean-to breaks that symmetry and connects the lookout
	# to the existing camp with installed supplies, without entering its rest or
	# trainer clearances. Three unequal canvas strips avoid one blockout slab.
	var shelter := Node3D.new()
	shelter.name = "WatchServiceShelter"
	add_child(shelter)
	var roof_y := 3.15
	for panel in 3:
		var roof := _box(shelter, "WeatheredCanvas_%02d" % panel,
			Vector3(5.25 - float(panel) * 0.12, 0.11, 1.12),
			Vector3(SERVICE_SHELTER_CENTRE.x, roof_y + float(panel % 2) * 0.035,
				SERVICE_SHELTER_CENTRE.y - 1.25 + float(panel) * 1.25),
			CANVAS_FADED if panel == 1 else CANVAS)
		roof.rotation.z = deg_to_rad(7.0)
		_shelter_panels += 1
	for edge_z in [-2.55, 1.15]:
		var edge := _box(shelter, "ShelterEdgeBeam", Vector3(5.45, 0.16, 0.16),
			Vector3(SERVICE_SHELTER_CENTRE.x, roof_y - 0.03, edge_z), TIMBER)
		edge.rotation.z = deg_to_rad(7.0)
	for local_z in [-2.35, 0.95]:
		var local_x := -9.35
		var at := SITE + Vector2(local_x, local_z)
		var foot_y := float(world.call("ground_height_at", at.x, at.y)) - position.y
		var post_height := maxf(2.3, roof_y - foot_y)
		_box(shelter, "ShelterOuterPost", Vector3(0.20, post_height, 0.20),
			Vector3(local_x, foot_y + post_height * 0.5, local_z), TIMBER)
		_shelter_posts += 1

	_ground_prop(world, shelter, "WatchSupplyCrate", SUPPLY_CRATE,
		Vector2(-7.85, -0.85), 18.0, 0.90)
	_ground_prop(world, shelter, "WatchSupplyBarrel", SUPPLY_BARREL,
		Vector2(-8.35, 0.35), -12.0, 0.86)


func _build_lantern(y: float) -> void:
	var holder := Node3D.new()
	holder.name = "InstalledWatchLantern"
	holder.position = Vector3(3.7, y, -1.0)
	add_child(holder)
	var lantern := WALL_LANTERN.instantiate() as Node3D
	if lantern != null:
		lantern.name = "LanternCage"
		lantern.rotation.y = deg_to_rad(-90.0)
		lantern.scale = Vector3.ONE * 0.38
		IMPORTED_MATERIALS.make_dielectric(lantern)
		holder.add_child(lantern)
	var source := MeshInstance3D.new()
	source.name = "VisibleWarmSource"
	var source_mesh := SphereMesh.new()
	source_mesh.radius = 0.065
	source_mesh.height = 0.13
	source_mesh.material = _emissive_material(LANTERN)
	source.mesh = source_mesh
	source.position = Vector3(0.0, 0.13, 0.20)
	holder.add_child(source)
	var lamp := OmniLight3D.new()
	lamp.name = "WatchLantern"
	lamp.position = source.position
	lamp.light_color = LANTERN
	lamp.light_energy = 1.7
	lamp.omni_range = 8.0
	lamp.shadow_enabled = false
	holder.add_child(lamp)


func _ground_prop(world: Node, parent: Node3D, node_name: String, scene: PackedScene,
		local_at: Vector2, yaw_deg: float, scale_value: float) -> void:
	var prop := scene.instantiate() as Node3D
	if prop == null:
		return
	prop.name = node_name
	IMPORTED_MATERIALS.make_dielectric(prop)
	var bounds := RENDER_BOUNDS.measure(prop)
	var world_at := SITE + local_at
	var ground_y := float(world.call("ground_height_at", world_at.x, world_at.y)) - position.y
	prop.position = Vector3(local_at.x, ground_y - bounds.position.y * scale_value - 0.04, local_at.y)
	prop.rotation.y = deg_to_rad(yaw_deg)
	prop.scale = Vector3.ONE * scale_value
	parent.add_child(prop)
	_supply_props += 1


func _box(parent: Node3D, node_name: String, size: Vector3, at: Vector3,
		colour: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _material(colour, 0.9)
	instance.mesh = mesh
	instance.position = at
	parent.add_child(instance)
	return instance


func _material(colour: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = roughness
	material.metallic = 0.0
	return material


func _emissive_material(colour: Color) -> StandardMaterial3D:
	var material := _material(colour, 0.35)
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = 1.25
	return material
