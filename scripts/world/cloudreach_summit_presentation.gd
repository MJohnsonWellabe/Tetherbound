extends Node3D

const FINALE := preload("res://scripts/world/cloudreach_finale_controller.gd")
const HAZARDS := preload("res://shaders/cloudreach_summit_hazards.gdshader")
const RELAY := preload("res://assets/environment/team_tether/relay_apparatus.glb")
const BOUNDS := preload("res://scripts/world/building_prefabs.gd")
const SCAFFOLD:=preload("res://assets/environment/team_tether/hall/team_tether_scaffold_tower.glb")
const WALL_MACHINE:=preload("res://assets/environment/team_tether/hall/rift_siphon_wall_machine.glb")
const PIPE_VALVE:=preload("res://assets/environment/team_tether/hall/tt_pipe_valve.glb")
const BOILER:=preload("res://assets/environment/team_tether/hall/team_tether_boiler_chimney.glb")
var config: Dictionary
var finale: Node3D
var _hazards: ShaderMaterial
var _relays: Dictionary = {}
var _bindings: Dictionary = {}
var _relay_beacons: Dictionary = {}


func build(world: Node3D) -> void:
	config = FINALE.read_config()
	position = FINALE.vec(config.arena_origin)
	(world.get("_cover_exclusions") as Array).append({"centre":position,"half":Vector2.ONE*38.0,"rotation":0.0})
	_clear_arena_dressing(world)
	var materials: Dictionary = world.get("_materials")
	var paving := _paving_material()
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = float(config.arena_radius_m)
	floor_mesh.bottom_radius = float(config.arena_radius_m) + 2.0
	floor_mesh.height = 2.0
	floor_mesh.radial_segments = 96
	var floor := MeshInstance3D.new()
	floor.name = "CollisionBearingSummitDeck"
	floor.mesh = floor_mesh
	floor.material_override = paving
	# The regional crown also reaches y=1160. Lift this authored paving 15cm
	# above it, with collision following, to avoid a screen full of z-fighting.
	floor.position.y = -0.85
	add_child(floor)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = float(config.arena_radius_m)
	cylinder.height = 2.0
	shape.shape = cylinder
	body.add_child(shape)
	floor.add_child(body)
	world.call("register_runtime_surface", {"kind":"ellipse", "centre":Vector2(position.x,position.z), "half":Vector2.ONE*float(config.arena_radius_m), "height":position.y+0.15})
	world.call("_box", world, "SummitArenaApproach", Vector3(100,1159.85,5400), Vector3(12,0.6,62), paving, true)
	world.call("register_runtime_surface", {"kind":"rect","centre":Vector2(100,5400),"half":Vector2(6,31),"height":1160.15})
	for lee: Dictionary in config.lee_pockets:
		var at := FINALE.vec(lee.offset)
		var safe_material := paving.duplicate() as ShaderMaterial
		safe_material.set_shader_parameter("tint",Color("#80938a"))
		world.call("_cylinder", self, str(lee.id)+"SafeFloor", at+Vector3.UP*0.18, float(lee.radius_m), 0.05, safe_material)
		world.call("_box", self, str(lee.id)+"Windbreak", at+Vector3(0,1.8,4.4), Vector3(6,3.6,1.2), materials.masonry, true)
		world.call("_box",self,str(lee.id)+"WeatheredCoping",at+Vector3(0,3.58,4.4),Vector3(6.2,0.26,1.4),materials.masonry_trim,false)
	for relay: Dictionary in config.relays:
		var model := RELAY.instantiate() as Node3D
		model.name = "EngineRelay_"+str(relay.id)
		var bounds_tool := BOUNDS.new()
		var bounds: AABB = bounds_tool.combined_aabb(model)
		var factor := 3.0 / maxf(bounds.size.y,0.01)
		model.scale = Vector3.ONE*factor
		var relay_at := FINALE.vec(relay.offset)
		var outward := Vector3(relay_at.x,0,relay_at.z).normalized()
		var machinery_at:=relay_at+outward*3.5
		var mount:=Node3D.new()
		mount.name="InstalledRelayMount_"+str(relay.id)
		mount.position=machinery_at+Vector3.UP*0.15
		mount.rotation.y=atan2(outward.x,outward.z)
		add_child(mount)
		model.position=-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*factor
		mount.add_child(model)
		_relays[str(relay.id)] = mount
		# Match the real housing footprint. Both actor and ordinary SpringArm now
		# respect it; camera/actor penetration is not hidden by a fixture angle.
		var housing:=StaticBody3D.new()
		housing.name="RelayHousingCollision"
		var housing_shape:=CollisionShape3D.new()
		var housing_cylinder:=CylinderShape3D.new()
		housing_cylinder.radius=maxf(bounds.size.x,bounds.size.z)*factor*0.52
		housing_cylinder.height=3.0
		housing_shape.shape=housing_cylinder
		housing_shape.position.y=1.5
		housing.add_child(housing_shape)
		mount.add_child(housing)
		world.call("_cylinder", self, "RelayMount_"+str(relay.id), machinery_at+Vector3.UP*0.15, 2.4, 0.10, paving)
		var tangent:=Vector3(outward.z,0,-outward.x)
		var core_at:=relay_at+outward*0.5+tangent*1.35
		_install(PIPE_VALVE,self,core_at+Vector3.UP*0.15,1.0,atan2(outward.x,outward.z))
		var beacon := MeshInstance3D.new()
		beacon.name="ExposedCore_"+str(relay.id)
		var core:=SphereMesh.new()
		core.radius=0.32
		core.height=0.9
		core.radial_segments=6
		core.rings=3
		beacon.mesh=core
		var crystal:=StandardMaterial3D.new()
		crystal.albedo_color=Color("#237f85")
		crystal.metallic=0.30
		crystal.roughness=0.34
		crystal.emission_enabled=true
		crystal.emission=Color("#338e94")
		crystal.emission_energy_multiplier=0.32
		beacon.material_override=crystal
		beacon.position=core_at+Vector3.UP*2.6
		add_child(beacon)
		var pipe_metal:=StandardMaterial3D.new()
		pipe_metal.albedo_color=Color("#465a52")
		pipe_metal.metallic=0.70
		pipe_metal.roughness=0.64
		world.call("_cylinder_between",self,"CoreConduit_"+str(relay.id),core_at+Vector3.UP*0.9,beacon.position,0.10,pipe_metal)
		world.call("_cylinder_between",self,"MountFeedPipe_"+str(relay.id),core_at+Vector3.UP*0.7,machinery_at+Vector3.UP*0.7,0.12,pipe_metal)
		_relay_beacons[str(relay.id)]=beacon
	# A coherent rear machinery spine grounds the three relay stations without
	# putting equipment in the central fight lane or the authored lee pockets.
	for side: float in [-1.0,1.0]:
		_install(SCAFFOLD,self,Vector3(side*13,0.15,30),6.5,0.0)
		world.call("_box",self,"SpineMasonryFoot",Vector3(side*13,0.35,30),Vector3(5.5,0.4,5.5),paving,false)
	_install(WALL_MACHINE,self,Vector3(0,0.15,33),4.5,0.0)
	_build_occupied_perimeter(world,materials)
	var overlay := MeshInstance3D.new()
	overlay.name = "LiveHazardTelegraphs"
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE*72.0
	overlay.mesh = plane
	overlay.position.y = 0.24
	_hazards = ShaderMaterial.new()
	_hazards.shader = HAZARDS
	_hazards.set_shader_parameter("origin",position)
	_hazards.set_shader_parameter("wind_offsets",Vector3(config.wind.lane_offsets_m[0],config.wind.lane_offsets_m[1],config.wind.lane_offsets_m[2]))
	_hazards.set_shader_parameter("wind_half_width",config.wind.lane_half_width_m)
	_hazards.set_shader_parameter("wind_rotation",config.wind.rotation_degrees_per_second)
	_hazards.set_shader_parameter("wind_cycle",Vector3(config.wind.cycle_seconds,config.wind.telegraph_seconds,config.wind.recovery_window_seconds))
	_hazards.set_shader_parameter("arc_rotation",config.relay_arc.rotation_degrees_per_second)
	_hazards.set_shader_parameter("arc_cycle",Vector3(config.relay_arc.cycle_seconds,config.relay_arc.telegraph_seconds,config.relay_arc.recovery_window_seconds))
	_hazards.set_shader_parameter("arc_shape",Vector3(config.relay_arc.inner_radius_m,config.relay_arc.outer_radius_m,config.relay_arc.sector_half_angle_degrees))
	for i in 3:
		var lee: Dictionary = config.lee_pockets[i]
		var at := FINALE.vec(lee.offset)
		_hazards.set_shader_parameter("lee%d"%i,Vector3(at.x,at.z,float(lee.radius_m)))
	overlay.material_override = _hazards
	add_child(overlay)
	_build_state_bindings(world,materials)


func _install(scene: PackedScene,parent: Node3D,at: Vector3,height: float,yaw: float) -> void:
	var model:=scene.instantiate() as Node3D
	var bounds: AABB=BOUNDS.new().combined_aabb(model)
	var anchor:=Node3D.new()
	anchor.position=at
	anchor.rotation.y=yaw
	parent.add_child(anchor)
	var factor:=height/maxf(bounds.size.y,0.01)
	model.scale=Vector3.ONE*factor
	model.position=-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*factor
	anchor.add_child(model)


func _paving_material() -> ShaderMaterial:
	var material:=ShaderMaterial.new()
	material.shader=preload("res://shaders/cloudreach_arena_paving.gdshader")
	material.set_shader_parameter("albedo_tex",preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_BaseColor.png"))
	material.set_shader_parameter("soil_tex",preload("res://assets/environment/terrain/stylised/dirt_path_Color.png"))
	material.set_shader_parameter("tint",Color("#8f8a70"))
	material.set_shader_parameter("origin",position)
	return material


func _build_occupied_perimeter(world: Node3D,materials: Dictionary) -> void:
	# Define the work court beyond the existing 36 m fight deck. Nothing here
	# changes collision, lee pockets, relay offers or hazard dimensions.
	var root:=Node3D.new()
	root.name="OccupiedArenaPerimeter"
	add_child(root)
	for index in 24:
		var angle:=TAU*index/24.0
		var outward:=Vector3(sin(angle),0,cos(angle))
		# Clear southern entry and northern recovery/afterward path, each 22 m.
		if absf(outward.x)<0.30:
			continue
		var segment:=Node3D.new()
		segment.name="PerimeterBay%02d"%index
		segment.position=outward*39.8
		segment.rotation.y=angle
		root.add_child(segment)
		world.call("_castle_piece",segment,"RetainedMasonry",preload("res://assets/buildings/quaternius_castle/TallWallBricks.obj"),
			Vector3(0,-1.6,0),Vector3(10.8,5.6 if index%3==0 else 3.8,2.6),materials.stone)
		world.call("_box",segment,"ServiceWallFoot",Vector3(0,-0.8,0),Vector3(11,1.6,3.2),materials.masonry,false)
		if index%3==0:
			world.call("_hang_cloudreach_banner",segment,Vector3(0,2.2,-1.4),Vector2(1.6,2.8),0.0)
	# Asymmetric occupied bays, all beyond the relay/camera circulation ring.
	for side: float in [-1.0,1.0]:
		if side<0:
			_install(BOILER,root,Vector3(-34,0.15,21),7.0,0.35)
		else:
			world.call("_place_local_prop",root,"wagon",Vector3(34,0.15,21),2.4,16)
		world.call("_place_local_prop",root,"crate",Vector3(side*31.5,0.15,20),1.15,side*12)
		world.call("_place_local_prop",root,"barrel",Vector3(side*33,0.15,17.5),1.25,side*28)
		world.call("_place_local_prop",root,"workbench",Vector3(side*29,0.15,25),1.1,side*70)
		world.call("_box",root,"MachineryServiceFoot",Vector3(side*34,-0.05,21),Vector3(6,0.4,7),materials.masonry,false)


func _clear_arena_dressing(world: Node3D) -> void:
	# Regional scatter predates the arena footprint. Remove only the generated
	# nature roots occupying this fight floor, never terrain or content nodes.
	for pattern in ["RouteTree*","RouteRock*","WindTree*","BeddedRock*","LandingTree*"]:
		for node: Node3D in world.find_children(pattern,"Node3D",true,false):
			var offset := node.global_position-position
			if Vector2(offset.x,offset.z).length()<40.0 and absf(offset.y)<12.0:
				node.get_parent().remove_child(node)
				node.queue_free()


func _build_state_bindings(world: Node3D, materials: Dictionary) -> void:
	for key in ["fly_routes","upper_routes","natural_anchor_wind","anchor_drone","waterward_overlook","returning_travelers","shrine_lights"]:
		_bindings[key] = []
	for record in [["fly_routes",Vector3(400,618,3250)],["upper_routes",Vector3(-400,784,3890)]]:
		var visual := world.call("_cylinder",world,str(record[0])+"Streamer",record[1],0.18,5.0,materials.heart) as Node3D
		_bindings[record[0]].append(visual)
	for model: Node3D in _relays.values():
		var light := OmniLight3D.new()
		light.light_color = Color("#50b9c4")
		light.light_energy = 1.1
		light.omni_range = 9.0
		light.position = model.position+Vector3.UP*3.0
		add_child(light)
		_bindings.anchor_drone.append(light)
	var shrine_light := OmniLight3D.new()
	shrine_light.name = "HighRoostRestorationLight"
	shrine_light.position = Vector3(1110,1058,2940)
	shrine_light.light_color = Color("#80d5cf")
	shrine_light.light_energy = 2.0
	shrine_light.omni_range = 23.0
	world.add_child(shrine_light)
	_bindings.shrine_lights.append(shrine_light)
	var water := MeshInstance3D.new()
	water.name = "DistantWaterwardNonEnterable"
	var plane := PlaneMesh.new()
	plane.size = Vector2(1200,1000)
	water.mesh = plane
	water.position = Vector3(-420,840,6850)
	var water_material := StandardMaterial3D.new()
	water_material.albedo_color = Color("#538fa9")
	water_material.roughness = 0.4
	water.material_override = water_material
	water.set_meta("enterable",false)
	world.add_child(water)
	_bindings.waterward_overlook.append(water)


func atmosphere_bindings() -> Dictionary:
	return _bindings


func bind_finale(controller: Node3D) -> void:
	finale = controller
	finale.connect("presentation_changed",_present)
	_present(finale.call("presentation_state"))


func _present(_state: Dictionary) -> void:
	if finale == null:
		return
	var flags: RefCounted = get_node("/root/Game").get("progression")
	for spec: Dictionary in config.relays:
		var model: Node3D = _relays[str(spec.id)]
		model.rotation.z = deg_to_rad(8.0) if bool(flags.call("has",str(spec.flag_id))) else 0.0
		(_relay_beacons[str(spec.id)] as Node3D).visible = not bool(flags.call("has",str(spec.flag_id)))


func _process(_delta: float) -> void:
	if finale == null or _hazards == null:
		return
	_hazards.set_shader_parameter("elapsed",finale.get("elapsed"))
	var phase := str(finale.get("phase"))
	_hazards.set_shader_parameter("phase", 1 if phase=="crosswind_command" else (2 if phase in ["anchor_overload","break_the_eye"] else 0))
