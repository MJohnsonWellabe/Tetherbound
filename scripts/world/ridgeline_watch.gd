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
const LOOKOUT_SCENE := preload("res://assets/environment/team_tether/hall/team_tether_scaffold_tower.glb")

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

const TIMBER := Color("#47382d")
const STONE := Color("#665f55")
const OXBLOOD := Color("#66362c")
const LANTERN := Color("#ffb663")

var _visual_height := 0.0
var _support_world: Array[Vector2] = []


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


func _build_lantern(y: float) -> void:
	var lamp := OmniLight3D.new()
	lamp.name = "WatchLantern"
	lamp.position = Vector3(3.7, y, -1.0)
	lamp.light_color = LANTERN
	lamp.light_energy = 2.0
	lamp.omni_range = 18.0
	lamp.shadow_enabled = false
	add_child(lamp)


func _box(parent: Node3D, node_name: String, size: Vector3, at: Vector3, colour: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _material(colour, 0.9)
	instance.mesh = mesh
	instance.position = at
	parent.add_child(instance)


func _material(colour: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = roughness
	material.metallic = 0.0
	return material
