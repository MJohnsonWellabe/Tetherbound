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
const SUPPLY_BAG := preload("res://assets/props/quaternius_fantasy/Bag.gltf")
const SUPPLY_CART := preload("res://assets/props/quaternius_fantasy/Stall_Cart_Empty.gltf")

const SITE := Vector2(-247.0, 6483.0)
const CANONICAL_VIEW := Vector2(-250.0, 6490.0)
## The walked route's camp-edge arrival. It remains outside the structure but
## inside the authored patrol clearing, so production scatter cannot replace
## the named-location view with a wall of trunks as it did in R3.
const ORDINARY_APPROACH := Vector2(-253.0, 6469.0)
const CAMP_CENTRE := Vector2(-241.8, 6468.5)
const PATROL_TRAINER := Vector2(-235.0, 6470.0)

const MODEL_SCALE := 1.55
const SUPPORT_X := 4.55
const SUPPORT_Z := 1.15
const SUPPORT_SIZE := Vector3(0.52, 10.8, 0.52)
const MAST_HEIGHT := 5.2
const MIN_VISUAL_HEIGHT := 14.0
const SERVICE_SHELTER_CENTRE := Vector2(7.0, -0.7)
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
var _shelter_valances := 0
var _supply_props := 0
var _repair_pieces := 0
var _watchhouse_pieces := 0
var _practical_count := 0


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
	_build_upper_watchhouse(frame_top)
	_build_service_shelter(world)
	_build_integrated_access(world, frame_top)
	# The GLB's measured render box includes projecting joinery above its
	# visible central deck. Sink the mast into that joinery so it reads as one
	# structure from below instead of hovering over the perch.
	_build_signal_mast(frame_top + 0.75)
	_build_practicals(frame_top)
	_visual_height = frame_top + 0.55 + MAST_HEIGHT
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
		"shelter_valances": _shelter_valances,
		"supply_props": _supply_props,
		"repair_pieces": _repair_pieces,
		"watchhouse_pieces": _watchhouse_pieces,
		"practical_count": _practical_count,
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
	# R3's west canopy read as a loose plane among the trees. The service wing
	# now faces the established camp and is visibly carried by inner and outer
	# posts, headers and braces. Two thick canvas courses overlap at a central
	# seam; exposed rafters make the lean-to legible from below.
	var shelter := Node3D.new()
	shelter.name = "WatchServiceShelter"
	add_child(shelter)
	var roof_centre := Vector3(SERVICE_SHELTER_CENTRE.x, 3.22, SERVICE_SHELTER_CENTRE.y)
	for index in 2:
		var roof := _box(shelter, "CanvasRoof%02d" % index,
			Vector3(5.45, 0.20, 2.02),
			roof_centre + Vector3(0.0, 0.0, -0.90 + float(index) * 1.80),
			CANVAS_FADED if index == 0 else CANVAS)
		roof.rotation.z = deg_to_rad(-8.0)
		_shelter_panels += 1
	for local_z in [-2.48, 1.08]:
		var edge := _box(shelter, "ShelterEdgeBeam", Vector3(5.62, 0.18, 0.18),
			Vector3(SERVICE_SHELTER_CENTRE.x, 3.13, local_z), TIMBER)
		edge.rotation.z = deg_to_rad(-8.0)
		for local_x in [4.72, 9.32]:
			var at := SITE + Vector2(local_x, local_z)
			var foot_y := float(world.call("ground_height_at", at.x, at.y)) - position.y
			var roof_y := 3.55 if local_x < 6.0 else 2.90
			var post_height := maxf(2.25, roof_y - foot_y)
			_box(shelter, "ShelterPost%s%s" % ["Inner" if local_x < 6.0 else "Outer",
				"South" if local_z < 0.0 else "North"],
				Vector3(0.22, post_height, 0.22),
				Vector3(local_x, foot_y + post_height * 0.5, local_z), TIMBER)
			_shelter_posts += 1
		var brace := _box(shelter, "ShelterKneeBrace%s" % ("South" if local_z < 0.0 else "North"),
			Vector3(1.45, 0.16, 0.16), Vector3(5.25, 2.88, local_z), TIMBER)
		brace.rotation.z = deg_to_rad(-38.0)
	var seam := _box(shelter, "CanvasValance", Vector3(5.34, 0.34, 0.10),
		Vector3(7.0, 3.04, 1.10), CANVAS_FADED)
	seam.rotation.z = deg_to_rad(-8.0)
	_shelter_valances = 1
	for rafter_z in [-1.72, -0.70, 0.32]:
		var rafter := _box(shelter, "ShelterRafter", Vector3(5.45, 0.12, 0.14),
			Vector3(7.0, 3.08, rafter_z), TIMBER)
		rafter.rotation.z = deg_to_rad(-8.0)

	_ground_prop(world, shelter, "WatchSupplyCrate", SUPPLY_CRATE,
		Vector2(6.15, -0.75), 18.0, 0.90)
	_ground_prop(world, shelter, "WatchSupplyBarrel", SUPPLY_BARREL,
		Vector2(7.20, 0.30), -12.0, 0.86)
	_ground_prop(world, shelter, "WatchSupplyBag", SUPPLY_BAG,
		Vector2(5.75, 0.22), 24.0, 0.78)
	_ground_prop(world, shelter, "WatchPatrolCart", SUPPLY_CART,
		Vector2(8.35, -0.70), -76.0, 0.56)


## A roofed watch room turns the upper scaffold bay into the place a patrol
## actually occupies. Four corner posts, waist-high windbreaks and a broad
## pitched cap preserve sightlines while replacing the repeated two-box read.
func _build_upper_watchhouse(frame_top: float) -> void:
	var house := Node3D.new()
	house.name = "UpperWatchhouse"
	add_child(house)
	for x in [-4.35, 4.35]:
		for z in [-1.42, 1.42]:
			_box(house, "WatchhousePost", Vector3(0.24, 3.15, 0.24),
				Vector3(x, frame_top - 0.75, z), TIMBER)
			_watchhouse_pieces += 1
	for z_index in 2:
		var z := -1.46 if z_index == 0 else 1.46
		_box(house, "WindbreakRail%s" % ("South" if z < 0.0 else "North"), Vector3(8.75, 1.05, 0.16),
			Vector3(0.0, frame_top - 1.72, z), STONE)
		_box(house, "WindowHeader%s" % ("South" if z < 0.0 else "North"), Vector3(9.2, 0.18, 0.20),
			Vector3(0.0, frame_top + 0.50, z), TIMBER)
		_watchhouse_pieces += 2
	for x in [-2.36, 2.36]:
		var roof := _box(house, "PitchedRoof%s" % ("West" if x < 0.0 else "East"), Vector3(4.92, 0.20, 3.70),
			Vector3(x, frame_top + 1.08, 0.0), CANVAS_FADED)
		roof.rotation.z = deg_to_rad(14.0 if x < 0.0 else -14.0)
		_watchhouse_pieces += 1
	_box(house, "RoofRidge", Vector3(0.24, 0.24, 3.86),
		Vector3(0.0, frame_top + 1.68, 0.0), TIMBER)
	_watchhouse_pieces += 1


## R3's free-standing vertical ladder is replaced by a broad stair whose two
## stringers begin on the south ground and terminate at a real scaffold deck.
## The access reads as part of the same structure and remains visual-only.
func _build_integrated_access(world: Node, frame_top: float) -> void:
	var repairs := Node3D.new()
	repairs.name = "WatchIntegratedAccess"
	add_child(repairs)
	var start_z := -6.0
	var end_z := -1.45
	var stair_x := 3.45
	var start_world := SITE + Vector2(stair_x, start_z)
	var start_y := float(world.call("ground_height_at", start_world.x, start_world.y)) - position.y + 0.18
	var landing_y := maxf(4.8, frame_top * 0.50)
	for index in 8:
		var t := float(index) / 7.0
		_box(repairs, "StairTread%02d" % index, Vector3(2.45, 0.15, 0.72),
			Vector3(stair_x, lerpf(start_y, landing_y, t), lerpf(start_z, end_z, t)), TIMBER)
		_repair_pieces += 1
	var dz := end_z - start_z
	var dy := landing_y - start_y
	var stringer_length := sqrt(dz * dz + dy * dy)
	for x in [2.38, 4.52]:
		var stringer := _box(repairs, "StairStringer%s" % ("West" if x < 3.0 else "East"), Vector3(0.18, 0.18, stringer_length),
			Vector3(x, (start_y + landing_y) * 0.5, (start_z + end_z) * 0.5), TIMBER)
		stringer.rotation.x = -atan2(dy, dz)
		_repair_pieces += 1
	_box(repairs, "AccessLanding", Vector3(3.05, 0.20, 1.15),
		Vector3(stair_x, landing_y, -1.10), TIMBER)
	_repair_pieces += 1


func _build_practicals(frame_top: float) -> void:
	_add_supported_lantern("UpperDeckPractical", Vector3(3.55, frame_top - 0.95, -1.70), 2.2, 8.0)
	_add_supported_lantern("ServicePractical", Vector3(6.20, 2.62, -2.30), 2.0, 7.0)


func _add_supported_lantern(node_name: String, at: Vector3,
		energy: float, light_range: float) -> void:
	var holder := Node3D.new()
	holder.name = node_name
	holder.position = at
	add_child(holder)
	_box(holder, "WallBracket", Vector3(0.72, 0.14, 0.14),
		Vector3(-0.28, 0.18, 0.0), TIMBER)
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
	lamp.name = "WarmPool"
	lamp.position = source.position
	lamp.light_color = LANTERN
	lamp.light_energy = energy
	lamp.omni_range = light_range
	lamp.shadow_enabled = false
	holder.add_child(lamp)
	_practical_count += 1


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
