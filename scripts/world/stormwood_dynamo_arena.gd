extends Node3D

## Kitbashed mechanics on the Stormheart Tree's existing top floor. Arena-local
## coordinates are shared by rendered banks, plates, and authoritative rules.
const RULES := preload("res://scripts/world/stormwood_dynamo_rules.gd")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const PYLON_MATERIALS := preload("res://scripts/world/tether_pylon_materials.gd")
const PLATE_ALBEDO := preload("res://assets/props/quaternius_fantasy/T_Trim_Metal_BaseColor.png")
const PLATE_NORMAL := preload("res://assets/props/quaternius_fantasy/T_Trim_Metal_Normal.png")
const PLATE_ORM := preload("res://assets/props/quaternius_fantasy/T_Trim_Metal_ORM.png")
# Bucket_Metal's authored twelve-sided metal cap, fitted from its actual UVs.
# The radius stays two atlas pixels inside every edge of that UV island.
const PLATE_CAP_UV_CENTER := Vector2(0.8671874454, 0.8603515526)
const PLATE_CAP_UV_RADIUS := 0.1186379366
# Its outer metal lip uses this full-width trim band (two-pixel edge inset).
const PLATE_LIP_UV_MIN := 0.0070266724
const PLATE_LIP_UV_MAX := 0.0476037264
var rules: RefCounted
var _banks: Array[Dictionary] = []
var _plates: Array[MeshInstance3D] = []
var _readout: Label3D
var _presentation: Dictionary = {}

func build(policy: RefCounted, simulation_only: bool = false) -> void:
	rules = policy
	_presentation = rules.config.get("presentation", {})
	for i in int(rules.config.bank_count):
		var point: Vector2 = rules.bank_position(i)
		var bank := Node3D.new()
		bank.name = "CapacitorBank%d" % i
		bank.position = Vector3(point.x, 0, point.y)
		add_child(bank)
		var conduit := StaticBody3D.new()
		conduit.name = "ExposedConduit"
		conduit.collision_layer = 32
		conduit.collision_mask = 0
		conduit.set_meta("dynamo_conduit", i)
		var shape := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 1.25
		shape.shape = sphere
		shape.position.y = 1.25
		conduit.add_child(shape)
		bank.add_child(conduit)
		if simulation_only:
			continue
		var packed := load("res://assets/environment/team_tether/tether_pylon.glb") as PackedScene
		var prop := packed.instantiate() as Node3D
		PYLON_MATERIALS.apply(prop, true)
		var bounds := BOUNDS.measure(prop)
		var factor := 7.0 / maxf(0.1, bounds.size.y)
		prop.scale = Vector3.ONE * factor
		prop.position.y = -bounds.position.y * factor
		bank.add_child(prop)
		var light := OmniLight3D.new()
		light.position.y = 4
		light.omni_range = 14
		light.light_color = Color("b5a0ff")
		bank.add_child(light)
		var lane := MeshInstance3D.new()
		lane.name = "DischargeLane%d" % i
		var mesh := PlaneMesh.new()
		mesh.size = Vector2(float(rules.config.arena_radius_m) * 2, float(rules.config.lane_half_width_m) * 2)
		lane.mesh = mesh
		lane.position.y = 0.09
		lane.rotation.y = -TAU * float(i) / float(rules.config.bank_count)
		var material := _glow(Color("8876d8"), 0.1)
		# Keep the entire authoritative lane visible, with the existing hazard
		# colour and firing emission, while allowing the real wood floor to read.
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = float(_presentation.lane_idle_alpha)
		lane.material_override = material
		add_child(lane)
		_banks.append({"node":bank, "lane":lane, "material":material, "light":light})
	if not simulation_only:
		for raw: Array in rules.config.plates:
			var plate := MeshInstance3D.new()
			plate.name = "GroundedRodPlate%d" % _plates.size()
			var mesh := CylinderMesh.new()
			mesh.top_radius = float(rules.config.plate_radius_m)
			mesh.bottom_radius = mesh.top_radius
			mesh.height = 0.12
			plate.mesh = _finished_plate_mesh(mesh)
			plate.position = Vector3(float(raw[0]), 0.14, float(raw[1]))
			var metal := _plate_material()
			metal.albedo_color = Color(str(_presentation.plate_surface_colour))
			metal.metallic = float(_presentation.plate_metallic)
			metal.roughness = float(_presentation.plate_roughness)
			plate.material_override = metal
			# Seen edge-on from across the core a 12 cm plate collapses into a
			# flat strip at the floor seam; it draws only where it reads as a plate.
			# Outside the encounter it draws only where it reads as a plate;
			# while anyone is engaged every safe plate stays visible.
			# The same mint safe-ground cue outlines the same 3.5 m plate.
			# This is render-only: the existing cylinder, seat and rule stay intact.
			var rim := MeshInstance3D.new()
			rim.name = "GroundedPlateRim"
			var ring := TorusMesh.new()
			ring.inner_radius = mesh.top_radius - float(_presentation.plate_rim_width_m)
			ring.outer_radius = mesh.top_radius
			ring.rings = 48
			ring.ring_segments = 8
			rim.mesh = _finished_rim_mesh(ring)
			rim.position.y = 0.09
			var cue := _plate_material()
			# The lip is the plate's own metal trim; the mint safe-ground cue
			# is its glow. Albedo mint read as a flat painted strip at range.
			cue.albedo_color = Color(str(_presentation.plate_surface_colour))
			cue.emission_enabled = true
			cue.emission = Color("63d4b0")
			cue.emission_energy_multiplier = float(_presentation.get("plate_rim_emission", 0.45))
			# A lit, rounded metal lip rather than flat painted mint.
			cue.metallic = float(_presentation.plate_metallic)
			cue.roughness = float(_presentation.plate_roughness)
			rim.material_override = cue
			plate.add_child(rim)
			add_child(plate)
			_plates.append(plate)
		# BOSSES §4.7's visible countdown and 0/4 progress, shown in the arena
		# above the core rather than in the shared HUD.
		_readout = Label3D.new()
		_readout.name = "ConduitCountdown"
		_readout.position = Vector3(0, 9.0, 0)
		_readout.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_readout.font_size = 96
		_readout.outline_size = 18
		_readout.modulate = Color("d9d0ff")
		_readout.no_depth_test = true
		add_child(_readout)
	show_state(rules.bank_state())

## "2/4 · 18" while the core is exposed; empty otherwise.
static func readout_text(state: Dictionary, phase: String, bank_count: int) -> String:
	if phase != "break_core":
		return ""
	return "Conduits %d/%d · %d s" % [int(state.get("struck", 0)), bank_count,
		ceili(float(state.get("window_left", 0.0)))]

## The arena controller has a fixed authored anchor, while the actual tree
## deck seats on the terrain heightfield. The warning is a floor overlay:
## anchoring it to the controller sliced through the captive cobra's coils.
## Keep the existing 9 cm clearance, lane footprint/material and hazard rules;
## only derive this visual's world height from the physical deck.
func seat_discharge_lanes(deck_world_height: float) -> void:
	for row: Dictionary in _banks:
		var lane: MeshInstance3D = row.lane
		var at: Vector3 = lane.global_position
		at.y = deck_world_height + 0.09
		lane.global_position = at

## Keep the exact cylinder vertices, normals and indices. Only finish UVs
## and the matching cap tangent basis change; there is no new walk collider.
static func _finished_plate_mesh(source: CylinderMesh) -> ArrayMesh:
	var arrays: Array = source.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
	for i in vertices.size():
		if absf(normals[i].y) > 0.5:
			uv[i] = PLATE_CAP_UV_CENTER + Vector2(vertices[i].x, vertices[i].z) * (PLATE_CAP_UV_RADIUS / source.top_radius)
			tangents[i * 4] = 1.0
			tangents[i * 4 + 1] = 0.0
			tangents[i * 4 + 2] = 0.0
			tangents[i * 4 + 3] = -signf(normals[i].y)
		else:
			uv[i].y = lerpf(PLATE_LIP_UV_MIN, PLATE_LIP_UV_MAX, 0.5 - vertices[i].y / source.height)
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_TANGENT] = tangents
	var finish := ArrayMesh.new()
	finish.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return finish

static func _finished_rim_mesh(source: TorusMesh) -> ArrayMesh:
	var arrays: Array = source.surface_get_arrays(0)
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	for i in uv.size():
		uv[i].y = lerpf(PLATE_LIP_UV_MIN, PLATE_LIP_UV_MAX, uv[i].y)
	arrays[Mesh.ARRAY_TEX_UV] = uv
	var finish := ArrayMesh.new()
	finish.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return finish

static func _plate_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = PLATE_ALBEDO
	material.normal_enabled = true
	material.normal_texture = PLATE_NORMAL
	material.roughness_texture = PLATE_ORM
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	material.metallic_texture = PLATE_ORM
	material.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
	material.ao_enabled = true
	material.ao_texture = PLATE_ORM
	material.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.metallic = 1.0
	material.roughness = 1.0
	return material

func _glow(colour: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = energy
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material

## The safe plates are an encounter cue. Idle, a 12 cm plate seen edge-on from
## across the core collapsed into a flat strip at the floor seam (F41#5 judge),
## so idle plates show only within `plate_visible_range_m` of the camera;
## engaged, every plate shows. Plain visibility, not a renderer range: a
## self-fading visibility range also hid the near plate on Compatibility.
func _process(_delta: float) -> void:
	var owner_dynamo := get_parent()
	var participants: Variant = owner_dynamo.get("participants") if owner_dynamo != null else null
	var engaged := participants is Array and not (participants as Array).is_empty()
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	var reach := float(_presentation.get("plate_visible_range_m", 34.0))
	for plate: MeshInstance3D in _plates:
		plate.visible = engaged or camera == null \
			or camera.global_position.distance_to(plate.global_position) <= reach


func show_state(state: Dictionary) -> void:
	if _readout != null:
		_readout.text = readout_text(state, str(rules.phase), int(rules.config.bank_count))
		_readout.visible = not _readout.text.is_empty()
	for i in _banks.size():
		var row: Dictionary = _banks[i]
		var active := i == int(state.get("bank", -1))
		var firing := active and str(state.get("state", "")) == "fire"
		var charge := float(state.get("charge", 0.0)) if active else 0.0
		row.light.light_energy = 3.0 if firing else charge * 1.6
		row.lane.visible = active and str(state.get("state", "")) != "recovery"
		row.material.emission_energy_multiplier = 4.0 if firing else charge * 0.7
		row.material.albedo_color.a = float(_presentation.lane_fire_alpha) if firing else \
			lerpf(float(_presentation.lane_idle_alpha), float(_presentation.lane_charge_alpha), charge)
