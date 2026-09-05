extends Node3D

## Cloudreach Cliffs' data-driven world shell.
##
## The chapter's macro layout lives in `data/config/cloudreach_world.json`.
## This node turns that authored region/route graph into solid, traversable
## cliff plates, ramps, suspended bridges and landmark silhouettes.  It is a
## deliberately separate world builder rather than another branch inside the
## Meadows' 1,700-line runtime composer.

const CONFIG_PATH := "res://data/config/cloudreach_world.json"
const VISUAL_CONFIG_PATH := "res://data/config/cloudreach_visual.json"
const REALM_ID := "cloudreach"
const CHAPTER_RUNTIME := preload("res://scripts/world/cloudreach_chapter.gd")
const REALM_GATE := preload("res://scripts/world/realm_gate.gd")
const GROUND_COVER := preload("res://scripts/world/cloudreach_ground_cover.gd")
const RESOURCE_PATCH := preload("res://scripts/world/cloudreach_resource_patch.gd")
const BUILDING_PREFABS := preload("res://scripts/world/building_prefabs.gd")
const ROUTE_DETAIL_SCENES := {
	"bush": preload("res://assets/environment/stylized_nature/Bush_Common.gltf"),
	"flowers": preload("res://assets/environment/stylized_nature/Bush_Common_Flowers.gltf"),
	"rock": preload("res://assets/environment/stylized_nature/Rock_Medium_1.gltf"),
	"rock_low": preload("res://assets/environment/stylized_nature/Rock_Medium_3.gltf"),
	"paving": preload("res://assets/environment/stylized_nature/RockPath_Round_Wide.gltf"),
	"fence": preload("res://assets/buildings/quaternius_medieval/Prop_WoodenFence_Extension2.gltf"),
	"wagon": preload("res://assets/buildings/quaternius_medieval/Prop_Wagon.gltf"),
	"crate": preload("res://assets/props/quaternius_fantasy/Crate_Wooden.gltf"),
	"barrel": preload("res://assets/props/quaternius_fantasy/Barrel.gltf"),
	"bench": preload("res://assets/props/quaternius_fantasy/Bench.gltf"),
	"workbench": preload("res://assets/props/quaternius_fantasy/Workbench.gltf"),
	"bucket": preload("res://assets/props/quaternius_fantasy/Bucket_Wooden_1.gltf"),
	"apples": preload("res://assets/props/quaternius_fantasy/FarmCrate_Apple.gltf"),
	"bag": preload("res://assets/props/quaternius_fantasy/Bag.gltf"),
}
const NATURE_TREES: Array[PackedScene] = [
	preload("res://assets/environment/stylized_nature/CommonTree_1.gltf"),
	preload("res://assets/environment/stylized_nature/CommonTree_2.gltf"),
	preload("res://assets/environment/stylized_nature/CommonTree_3.gltf"),
	preload("res://assets/environment/stylized_nature/CommonTree_4.gltf"),
	preload("res://assets/environment/stylized_nature/CommonTree_5.gltf"),
]
const WIND_TREES: Array[PackedScene] = [
	preload("res://assets/environment/stylized_nature/TwistedTree_2.gltf"),
	preload("res://assets/environment/stylized_nature/TwistedTree_4.gltf"),
]
const NATURE_ROCKS: Array[PackedScene] = [
	preload("res://assets/environment/stylized_nature/Rock_Medium_1.gltf"),
	preload("res://assets/environment/stylized_nature/Rock_Medium_2.gltf"),
	preload("res://assets/environment/stylized_nature/Rock_Medium_3.gltf"),
]
const CLOUDREACH_LEAF_TEXTURE := preload(
	"res://assets/environment/stylized_nature/derived/Leaves_NormalTree_C_desat55_b100.png")
const CASTLE_GATE := preload("res://assets/buildings/quaternius_castle/WallEntranceBricks.obj")
const CASTLE_TOWER := preload("res://assets/buildings/quaternius_castle/SmallSquareTowerBricks.obj")
const CASTLE_WALL := preload("res://assets/buildings/quaternius_castle/TallWallBricks.obj")
const TETHER_PYLON := preload("res://assets/environment/team_tether/tether_pylon.glb")
const RELAY_APPARATUS := preload("res://assets/environment/team_tether/relay_apparatus.glb")
const GEOLOGY_SHADER := preload("res://shaders/cloudreach_cliff.gdshader")
const TRAIL_SHADER := preload("res://shaders/cloudreach_trail.gdshader")
const MASONRY_SHADER := preload("res://shaders/cloudreach_masonry.gdshader")
const WORLD_RUNTIME := preload("res://scripts/world/cloudreach_world_runtime.gd")
const ENVIRONMENT_MATERIALS:=preload("res://scripts/world/cloudreach_environment_materials.gd")
const BRIDGE_KIT:=preload("res://scripts/world/cloudreach_bridge_kit.gd")

@onready var _player: CharacterBody3D = $Player
@onready var _camera_rig: Node3D = $CameraRig

var _config: Dictionary = {}
var _visual_config: Dictionary = {}
var _surfaces: Array[Dictionary] = []
var _cover_patches: Array[Dictionary] = []
var _materials: Dictionary = {}
var _tree_palette_materials: Dictionary = {}
var _region_count := 0
var _landmark_count := 0
var _progression_revision := -1
var _progression_gates: Array[Dictionary] = []
var _yard_visual_config: Dictionary={}
var _building_prefabs: RefCounted
var _cover_exclusions: Array[Dictionary] = []
var _realm_map: RefCounted
var _surface_cells: Dictionary = {}
var _surface_index_count := -1
const SURFACE_CELL_M := 128.0


func _build_horizon_ranges() -> void:
	var root := Node3D.new()
	root.name = "DistantHighlandRanges"
	add_child(root)
	for range_spec: Dictionary in _visual_config.get("horizon_ranges", []):
		var at := _vec3(range_spec.get("position", []))
		var size := _vec3(range_spec.get("size", []))
		var group := Node3D.new()
		group.name = str(range_spec.get("id", "FarRange"))
		root.add_child(group)
		for cluster in 7:
			var angle := float(cluster) * 2.399 + float(range_spec.get("seed", 0))
			var portion := 0.34 + 0.09 * float(cluster % 3)
			var cluster_size := Vector3(size.x*portion,size.y*(0.34+0.11*(cluster%4)),size.z*portion)
			var base:=at+Vector3(cos(angle)*size.x*0.34,-size.y*0.5,sin(angle)*size.z*0.34)
			# Installed asymmetrical closed rock geometry, overlapping down to the
			# common range base. No kilometre-high tabletop perimeter or new floor.
			_visual_rock_mass(group,"RangeCrag%d"%cluster,base,cluster_size,
				int(range_spec.get("seed",0))+cluster*17,2600.0)


func _visual_rock_mass(parent: Node3D,label: String,base: Vector3,size: Vector3,
		seed_value: int,visible_distance: float=1600.0) -> Node3D:
	var root:=Node3D.new()
	root.name=label
	root.position=base
	root.rotation.y=float(posmod(seed_value*37,360))*PI/180.0
	parent.add_child(root)
	var rock:=NATURE_ROCKS[posmod(seed_value,3)].instantiate() as Node3D
	var bounds: AABB=BUILDING_PREFABS.new().combined_aabb(rock)
	rock.scale=size/bounds.size
	rock.position=-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*rock.scale
	root.add_child(rock)
	for mesh: MeshInstance3D in rock.find_children("*","MeshInstance3D",true,false):
		mesh.material_override=_materials["cliff"]
	_set_geometry_visibility(root,visible_distance)
	return root


func _ready() -> void:
	add_to_group("progression_restore")
	_config = _read_json(CONFIG_PATH)
	_visual_config = _read_json(VISUAL_CONFIG_PATH)
	var look := get_node_or_null(^"WorldLook")
	if look != null:
		var local_look: Dictionary = (look.get("_config") as Dictionary).duplicate(true)
		var sky_profile: Dictionary = _visual_config.get("sky_profile", {})
		(local_look.get("sky", {}) as Dictionary).merge(sky_profile, true)
		for preset: Dictionary in local_look.get("times", {}).values():
			if not preset.has("sky"):
				preset["sky"] = {}
			(preset["sky"] as Dictionary).merge(sky_profile, true)
		look.set("_config", local_look)
		look.call("set_weather", _visual_config.get("atmosphere", {}))
	if _config.is_empty():
		push_error("Cloudreach world config missing or invalid: %s" % CONFIG_PATH)
		return
	_build_materials()
	_build_cloud_sea()
	_build_horizon_ranges()
	_build_regions()
	_build_transition_ledges()
	_build_routes()
	_build_progression_gates()
	_build_bridges()
	_build_landmarks()
	_build_return_gate()
	_build_authored_route_details()
	_build_resource_patches()
	var arrival_beats:=preload("res://scripts/world/cloudreach_arrival_beats.gd").new()
	arrival_beats.name="ArrivalRoadObservation"
	add_child(arrival_beats)
	arrival_beats.call("build",self,_visual_config.get("arrival_beats",{}))
	var runtime := WORLD_RUNTIME.new()
	runtime.name = "CloudreachRuntime"
	add_child(runtime)
	runtime.call("build_environment", self)
	_build_ground_cover()
	_place_player()
	_realm_map = _game().call("bind_realm_map", REALM_ID, _player.global_position)
	var chapter := CHAPTER_RUNTIME.new()
	chapter.name = "CloudreachChapter"
	add_child(chapter)
	runtime.call("mount", self, chapter, _realm_map)
	_capture_mouse_if_free()
	get_window().focus_entered.connect(_capture_mouse_if_free)
	_sync_progression_gates(_game())


func _process(_delta: float) -> void:
	var game := _game()
	var progression: Variant = game.get("progression") if game != null else null
	var revision := int((progression as RefCounted).get("revision")) if progression is RefCounted else -1
	if revision != _progression_revision:
		_sync_progression_gates(game)


func restore_progression_from_game(game: Node) -> void:
	_progression_revision = -1
	_sync_progression_gates(game)


func region_count() -> int:
	return _region_count


func landmark_count() -> int:
	return _landmark_count


func config_data() -> Dictionary:
	return _config.duplicate(true)


func map_terrain_texture() -> Texture2D:
	return _realm_map.call("bake_terrain", self) as Texture2D if _realm_map != null else null


func register_runtime_surface(surface: Dictionary) -> void:
	_surfaces.append(surface)


## The same terrain-independent contract authored objects use in the Meadows.
## Legacy x/z callers take the highest plate; authored 3D placements use
## ground_height_near() to select their intended road in a stack of cliffs.
func ground_height_at(x: float, z: float, preferred_y: float = NAN) -> float:
	if _surface_index_count != _surfaces.size():
		_rebuild_surface_index()
	var best := -INF
	for surface: Dictionary in _surface_cells.get(Vector2i(floori(x/SURFACE_CELL_M),floori(z/SURFACE_CELL_M)), []):
		var kind := str(surface.get("kind", "rect"))
		if kind == "rect":
			var centre: Vector2 = surface.get("centre", Vector2.ZERO)
			var half: Vector2 = surface.get("half", Vector2.ZERO)
			if absf(x - centre.x) <= half.x and absf(z - centre.y) <= half.y:
				best = _preferred_surface(best, float(surface.get("height", -INF)), preferred_y)
		elif kind == "ellipse":
			var centre: Vector2 = surface.get("centre", Vector2.ZERO)
			var half: Vector2 = surface.get("half", Vector2.ONE)
			var local := Vector2(x - centre.x, z - centre.y).rotated(
				-float(surface.get("rotation", 0.0)))
			if half.x > 0.01 and half.y > 0.01 \
					and local.x * local.x / (half.x * half.x) \
					+ local.y * local.y / (half.y * half.y) <= 1.0:
				best = _preferred_surface(best, float(surface.get("height", -INF)), preferred_y)
		elif kind == "segment":
			var a: Vector3 = surface.get("a", Vector3.ZERO)
			var b: Vector3 = surface.get("b", Vector3.ZERO)
			var ab := Vector2(b.x - a.x, b.z - a.z)
			var length_sq := ab.length_squared()
			if length_sq <= 0.001:
				continue
			var point := Vector2(x - a.x, z - a.z)
			var t := clampf(point.dot(ab) / length_sq, 0.0, 1.0)
			var nearest := Vector2(a.x, a.z) + ab * t
			if nearest.distance_to(Vector2(x, z)) <= float(surface.get("half_width", 1.0)):
				best = _preferred_surface(best, lerpf(a.y, b.y, t), preferred_y)
	return NAN if best == -INF else best


func _rebuild_surface_index() -> void:
	_surface_cells.clear()
	for surface: Dictionary in _surfaces:
		var low: Vector2
		var high: Vector2
		if str(surface.get("kind", "rect")) == "segment":
			var a: Vector3 = surface.a
			var b: Vector3 = surface.b
			var width := Vector2.ONE*float(surface.get("half_width",1.0))
			low = Vector2(minf(a.x,b.x),minf(a.z,b.z))-width
			high = Vector2(maxf(a.x,b.x),maxf(a.z,b.z))+width
		else:
			var centre: Vector2 = surface.get("centre",Vector2.ZERO)
			var half: Vector2 = surface.get("half",Vector2.ONE)
			# Conservative rotated-ellipse extent: exact shape evaluation remains
			# below. The broad phase may overinclude, never exclude real ground.
			if str(surface.get("kind","rect")) == "ellipse":
				half = Vector2.ONE*maxf(half.x,half.y)
			low=centre-half
			high=centre+half
		for cx in range(floori(low.x/SURFACE_CELL_M),floori(high.x/SURFACE_CELL_M)+1):
			for cz in range(floori(low.y/SURFACE_CELL_M),floori(high.y/SURFACE_CELL_M)+1):
				var key:=Vector2i(cx,cz)
				if not _surface_cells.has(key):
					_surface_cells[key]=[]
				_surface_cells[key].append(surface)
	_surface_index_count=_surfaces.size()


## An authored Y disambiguates stacked roads. Never pull a lower-road NPC or
## pickup onto the highest cliff sharing its x/z. No ground still returns NAN.
func ground_height_near(at: Vector3) -> float:
	return ground_height_at(at.x, at.z, at.y)


static func _preferred_surface(current: float, candidate: float, preferred_y: float) -> float:
	if is_nan(preferred_y):
		return maxf(current, candidate)
	return candidate if absf(candidate - preferred_y) < absf(current - preferred_y) else current


func entry_anchor(anchor_id: String) -> Dictionary:
	var points: Variant = _config.get("transition_points", {})
	if not points is Dictionary:
		return {}
	for value: Variant in (points as Dictionary).values():
		if value is Dictionary and str((value as Dictionary).get("id", "")) == anchor_id:
			return (value as Dictionary).duplicate(true)
	return {}


func _build_materials() -> void:
	# Reuse the exact Meadows terrain family. World-space triplanar projection
	# keeps the texture scale coherent across cliff walls, caps and sloping
	# route ribbons without requiring UVs on every generated landform.
	var surface: Dictionary = _visual_config.get("surface", {})
	var cliff_surface: Dictionary = surface.get("cliff", {})
	_materials["cliff"] = _textured_material(_surface_tint(cliff_surface, "#c9865f"), Color("#c9865f"))
	_materials["cliff_high"] = _textured_material(_surface_tint(cliff_surface, "#e3ac79"), Color("#e3ac79"))
	_materials["cliff_mid"] = _textured_material(_surface_tint(cliff_surface, "#ad704f"), Color("#ad704f"))
	_materials["cliff_deep"] = _textured_material(_surface_tint(cliff_surface, "#82594a"), Color("#82594a"))
	_materials["cliff_shadow"] = _material(Color("#3f2b2a"), 1.0)
	_materials["upland"] = _textured_material(surface.get("upland", {}), Color("#e8dfbf"))
	_materials["upland_dry"] = _textured_material(surface.get("upland_dry", {}), Color("#e4d5aa"))
	_materials["path"] = _textured_material(surface.get("path", {}), Color("#caa77f"))
	_materials["stone"] = _textured_material(_surface_tint(cliff_surface, "#906955"), Color("#906955"))
	_materials["stone_light"] = _textured_material(_surface_tint(cliff_surface, "#cbae82"), Color("#cbae82"))
	_materials["wood"] = _textured_material({"albedo":"res://assets/buildings/quaternius_medieval/T_WoodTrim_BaseColor.png","normal":"res://assets/buildings/quaternius_medieval/T_WoodTrim_Normal.png","tint":"#9b8b71","uv_scale":0.45,"normal_depth":0.35},Color.WHITE)
	_materials["rope"] = _material(Color("#8f7048"), 1.0)
	_materials["leaf"] = _material(Color("#4f623d"), 0.94)
	_materials["leaf_gold"] = _material(Color("#8f8744"), 0.94)
	_materials["tether"] = _material(Color("#651f2b"), 0.82)
	_materials["heart"] = _emissive_material(Color("#5ee0c2"), 1.35)
	_materials["wind_veil"] = _wind_veil_material()
	_materials["cloud"] = _cloud_material()
	_materials["cloud_bank"] = _emissive_material(Color("#d4e2e5"), 0.12)
	for material_key: String in ["masonry", "masonry_trim"]:
		var masonry := ENVIRONMENT_MATERIALS.masonry(material_key=="masonry_trim")
		_materials[material_key] = masonry
	_materials["bronze"] = _material(Color("#81704b"), 0.72)
	var timber:=ShaderMaterial.new()
	timber.shader=preload("res://shaders/cloudreach_timber.gdshader")
	_materials["weathered_timber"]=timber
	var geology := ShaderMaterial.new()
	geology.shader = GEOLOGY_SHADER
	geology.set_shader_parameter("rock_texture", preload("res://assets/environment/terrain/Rock030_Color.jpg"))
	geology.set_shader_parameter("rock_normal", preload("res://assets/environment/terrain/Rock030_NormalGL.jpg"))
	for key: String in ["cliff", "cliff_high", "cliff_mid", "cliff_deep"]:
		_materials[key] = geology
	var trail := ShaderMaterial.new()
	trail.shader = TRAIL_SHADER
	trail.set_shader_parameter("grass_texture",preload("res://assets/environment/terrain/stylised/meadow_grass_Color.png"))
	trail.set_shader_parameter("dirt_texture", load(str(surface.get("path", {}).get("albedo", "res://assets/environment/terrain/stylised/dirt_path_Color.png"))))
	_materials["trail"] = trail
	ENVIRONMENT_MATERIALS.turf_parameters(trail,false)
	trail.set_shader_parameter("tint",Color("#9b805f"))
	var trail_dry:=trail.duplicate() as ShaderMaterial
	ENVIRONMENT_MATERIALS.turf_parameters(trail_dry,true)
	_materials["trail_dry"]=trail_dry
	_materials["upland"]=ENVIRONMENT_MATERIALS.ground(false)
	_materials["upland_dry"]=ENVIRONMENT_MATERIALS.ground(true)


func _build_cloud_sea() -> void:
	var realm: Dictionary = _config.get("realm", {})
	var bounds: Dictionary = realm.get("world_bounds", {})
	var width := maxf(900.0, float(bounds.get("max_x", 450.0)) - float(bounds.get("min_x", -450.0)) + 500.0)
	var depth := maxf(1200.0, float(bounds.get("max_z", 800.0)) - float(bounds.get("min_z", -200.0)) + 500.0)
	var y := float(bounds.get("min_y", -100.0)) + 18.0
	_box(self, "CloudSea", Vector3.ZERO + Vector3(0.0, y, 300.0), Vector3(width, 3.0, depth), _materials["cloud"], false)
	var banks := Node3D.new()
	banks.name = "CloudBanks"
	add_child(banks)
	# The former stretched SphereMesh puffs read as dark/white floating debris
	# from several real gameplay angles. Keep the cloud sea and atmospheric fog;
	# authored sky banks return only with a proper soft-cloud material.


func _build_regions() -> void:
	var root := Node3D.new()
	root.name = "CliffRegions"
	add_child(root)
	for raw: Variant in _config.get("regions", []):
		if not raw is Dictionary:
			continue
		var spec := raw as Dictionary
		var bounds: Dictionary = spec.get("bounds", {})
		var min_x := float(bounds.get("min_x", 0.0))
		var max_x := float(bounds.get("max_x", min_x + 40.0))
		var min_z := float(bounds.get("min_z", 0.0))
		var max_z := float(bounds.get("max_z", min_z + 40.0))
		var authored := _vec3(spec.get("position", []))
		var top := authored.y
		var bottom := float(_visual_config.get("landmass", {}).get("geology_base_y", -210.0))
		# Bounds express the region's full navigation/visibility envelope, not a
		# single tabletop. A compact authored mesa at the region anchor plus the
		# route-ledges below produces separated vertical silhouettes instead of
		# six overlapping rectangular continents.
		var landmass: Dictionary = _visual_config.get("landmass", {})
		var size := Vector3(
			clampf((max_x - min_x) * float(landmass.get("region_width_factor", 0.30)),
				float(landmass.get("min_width_m", 260.0)), float(landmass.get("max_width_m", 560.0))),
			maxf(18.0, top - bottom),
			clampf((max_z - min_z) * float(landmass.get("region_depth_factor", 0.28)),
				float(landmass.get("min_depth_m", 220.0)), float(landmass.get("max_depth_m", 460.0))))
		var centre := Vector3(authored.x, (top + bottom) * 0.5, authored.z)
		var node := Node3D.new()
		node.name = _safe_name(str(spec.get("id", "Region")))
		root.add_child(node)
		var region_mass := _mesa(node, "CliffMass", centre, size, _materials["cliff"],
			_materials["upland_dry"] if int(spec.get("order", 0)) >= 5 else _materials["upland"], true,
			int(spec.get("order", 0)))
		_add_cliff_strata(node, centre, size, top)
		_add_satellite_crags(node, centre, size, top, int(spec.get("order", 0)))
		_add_wind_vegetation(node,
			Rect2(centre.x - size.x * 0.5, centre.z - size.z * 0.5, size.x, size.z),
			top, int(spec.get("order", 0)))
		_cover_patches.append({
			"kind": "ellipse", "centre": Vector3(centre.x, top, centre.z),
			# Conservative inside the rotated irregular crown; no grass can hang
			# in the air at the ellipse corners.
			"half": Vector2(size.x, size.z) * 0.34,
			"seed": int(spec.get("order", 0)) * 101,
			"dry": int(spec.get("order", 0)) >= 5,
		})
		# Match the real rotated irregular crown conservatively. The old enclosing
		# rectangle reported invisible corner air as ground, which could place a
		# loaded player or an evidence camera beside a floating island.
		_surfaces.append({"kind": "ellipse", "centre": Vector2(centre.x, centre.z),
			"half": Vector2(size.x, size.z) * 0.30,
			"rotation": region_mass.rotation.y, "height": top})
		_region_count += 1


func _build_transition_ledges() -> void:
	var root := Node3D.new()
	root.name = "RealmTransitionLedges"
	add_child(root)
	var points: Variant = _config.get("transition_points", {})
	if not points is Dictionary:
		return
	for raw: Variant in (points as Dictionary).values():
		if not raw is Dictionary:
			continue
		var at := _vec3((raw as Dictionary).get("position", []))
		_mesa(root, _safe_name(str((raw as Dictionary).get("id", "Transition"))),
			at - Vector3.UP * 8.0, Vector3(42.0, 16.0, 42.0), _materials["cliff"],
			_materials["upland"], true, int(absf(at.x + at.z)))
		_surfaces.append({"kind": "rect", "centre": Vector2(at.x, at.z), "half": Vector2(21.0, 21.0), "height": at.y})
		_cover_patches.append({"kind": "ellipse", "centre": at, "half": Vector2(17.0, 17.0),
			"seed": int(absf(at.x + at.z)) + 501, "dry": false})


func _add_cliff_strata(parent: Node3D, centre: Vector3, size: Vector3, top: float) -> void:
	# Bedded, asymmetric spurs attach to the actual massif; no unsupported bars
	# across an enclosing rectangle. Their crowns make readable rocky shelves.
	for i in 7:
		var angle := float(i) * 2.399 + centre.z * 0.013
		var shelf_top := top - 12.0 - float(i % 3) * 24.0
		var shelf_depth := shelf_top - float(_visual_config.get("landmass", {}).get("geology_base_y", -210.0))
		var at := Vector3(centre.x + cos(angle) * size.x * 0.37,
			shelf_top - shelf_depth * 0.5, centre.z + sin(angle) * size.z * 0.37)
		_visual_rock_mass(parent,"BeddedSpur%d"%i,at-Vector3.UP*shelf_depth*0.5,
			Vector3(size.x*(0.25+0.06*(i%2)),shelf_depth,size.z*0.25),i*31+int(top))


func _add_satellite_crags(parent: Node3D, centre: Vector3, size: Vector3, top: float, order: int) -> void:
	# Three asymmetric companions stop each region reading as one isolated stamp
	# and give the long approach views overlapping silhouettes at different
	# depths. They are visual geology outside the walkable top, not secret paths.
	# Keep companions lateral/back from each region's main south-to-north
	# approach. A former front-centre crag hid both Cliffhold and the Summit from
	# their authored roads, turning destination vistas into blank walls.
	const OFFSETS := [Vector2(-0.62, -0.12), Vector2(0.60, 0.36)]
	for i in OFFSETS.size():
		var offset: Vector2 = OFFSETS[(i + order) % OFFSETS.size()]
		var crag_top := top - 18.0 - float((i + order) % 3) * 14.0
		var crag_height := crag_top - float(_visual_config.get("landmass", {}).get("geology_base_y", -210.0))
		var at := Vector3(
			centre.x + offset.x * size.x,
			crag_top - crag_height * 0.5,
			centre.z + offset.y * size.z)
		_visual_rock_mass(parent,"SatelliteCrag%d"%i,at-Vector3.UP*crag_height*0.5,
			Vector3(size.x*(0.23+i*0.04),crag_height,size.z*(0.25+i*0.04)),order*7+i)


func _add_wind_vegetation(parent: Node3D, rect: Rect2, top: float, order: int) -> void:
	var nature: Dictionary = _visual_config.get("nature", {})
	var centre := rect.get_center()
	var half := rect.size * 0.5
	var tree_count := maxi(12, int(nature.get("tree_count_base", 27))
		- order * int(nature.get("tree_count_order_falloff", 2)))
	for i in tree_count:
		# Golden-angle groups are biased into three groves, leaving authored open
		# sky between them instead of distributing one tree every N metres.
		var grove := i % 3
		var grove_angle := float(grove) * TAU / 3.0 + float(order) * 0.61
		var angle := grove_angle + sin(float(i * 17 + order * 5)) * 0.42
		var radius := 0.22 + 0.40 * sqrt(fmod(float(i) * 0.6180339 + float(order) * 0.17, 1.0))
		var at := Vector3(centre.x + cos(angle) * half.x * radius, top,
			centre.y + sin(angle) * half.y * radius)
		if _inside_settlement_clearance(at):
			continue
		var tree_scene := WIND_TREES[order % WIND_TREES.size()] if i == 0 \
			else NATURE_TREES[(i + order) % NATURE_TREES.size()]
		var tree := tree_scene.instantiate() as Node3D
		tree.name = "WindTree%d" % i
		tree.position = at
		# Keep trunks planted and readable; wind character comes from clustered
		# crowns and the asset silhouettes, not from visibly uprooting whole trees.
		tree.rotation = Vector3(0.0, angle + 0.4,
			deg_to_rad(-0.5 - float((i + order) % 4) * 0.8))
		var scale_min := float(nature.get("tree_scale_min", 1.12))
		var scale_max := float(nature.get("tree_scale_max", 1.92))
		var scale_value := lerpf(scale_min, scale_max,
			float(posmod(i * 7 + order * 3, 11)) / 10.0)
		if i == 0:
			# Twisted trees are natively 16–19 m tall, versus 7–9 m for the
			# common canopy, so their final multiplier must be smaller.
			scale_value = 0.82 + float(order % 3) * 0.07
		tree.scale = Vector3.ONE * scale_value
		_apply_tree_palette(tree, i + order * 17)
		parent.add_child(tree)
		_set_geometry_visibility(tree, float(nature.get("tree_visibility_range_m", 1050.0)))
	for i in int(nature.get("rock_count", 16)):
		var angle := fmod(float(i) * 2.071 + float(order) * 0.39, TAU)
		var radius := 0.24 + 0.38 * sqrt(fmod(float(i) * 0.4142 + 0.13 * order, 1.0))
		var at := Vector3(centre.x + cos(angle) * half.x * radius, top - 0.18,
			centre.y + sin(angle) * half.y * radius)
		var rock := NATURE_ROCKS[(i * 2 + order) % NATURE_ROCKS.size()].instantiate() as Node3D
		rock.name = "BeddedRock%d" % i
		rock.position = at
		rock.rotation.y = angle
		rock.scale = Vector3.ONE * lerpf(float(nature.get("rock_scale_min", 0.85)),
			float(nature.get("rock_scale_max", 1.75)), float(posmod(i * 5 + order, 9)) / 8.0)
		parent.add_child(rock)
		_set_geometry_visibility(rock, float(nature.get("rock_visibility_range_m", 820.0)))


func _build_routes() -> void:
	var root := Node3D.new()
	root.name = "AuthoredRoutes"
	add_child(root)
	for raw: Variant in _config.get("routes", []):
		if not raw is Dictionary:
			continue
		var spec := raw as Dictionary
		if str(spec.get("traversal_mode", "ground")) != "ground":
			continue
		var points: Array[Vector3] = []
		for point: Variant in spec.get("polyline", []):
			points.append(_vec3(point))
		var width := float(spec.get("width_m", 7.5))
		var landmass: Dictionary = _visual_config.get("landmass", {})
		var collision_width := minf(width, float(landmass.get("path_collision_width_m", 7.0)))
		var visible_width := minf(collision_width - 0.8,
			float(landmass.get("path_visible_width_m", 4.2)))
		_build_route_shoulders(root, spec, points, width)
		var route_name_lower := str(spec.get("id", "")).to_lower()
		var landing_top: Material = _materials["upland_dry"] if (
			route_name_lower.contains("upper") or route_name_lower.contains("summit")
		) else _materials["upland"]
		for i in points.size():
			var pad := points[i]
			if _bridge_interior_point(str(spec.get("id","")),pad):
				continue # The continuous deck owns its internal bend, not a flat land cap.
			var landing_size := maxf(float(landmass.get("landing_size_m", 16.0)),
				collision_width * 2.25)
			_mesa(root, "%s_Ledge%d" % [_safe_name(str(spec.get("id", "Route"))), i],
			pad - Vector3.UP * 22.0, Vector3(landing_size * 1.5, 44.0, landing_size * 1.5),
				_materials["cliff"], landing_top, false,
				i * 19 + absi(str(spec.get("id", "Route")).hash()))
			# A shallow walkable cap bridges the several sloped path boxes meeting
			# here. The irregular cliff below carries the silhouette; this cap keeps
			# the joint from exposing a sky crack at player eye height.
			_box(root, "%s_LedgeCap%d" % [_safe_name(str(spec.get("id", "Route"))), i],
				pad - Vector3.UP * 0.42, Vector3(landing_size * 0.82, 0.84, landing_size * 0.82),
				landing_top, true)
			_add_landing_nature(root, points, i, pad, landing_size,
				i * 43 + absi(str(spec.get("id", "Route")).hash()))
			_cover_patches.append({"kind":"ellipse","centre":pad,"half":Vector2.ONE*landing_size*0.40,
				"inner_clear_fraction":0.38,"seed":i*137+absi(str(spec.id).hash()),"dry":false})
			_surfaces.append({"kind": "rect", "centre": Vector2(pad.x, pad.z),
				"half": Vector2.ONE * landing_size * 0.41, "height": pad.y})
		for i in points.size() - 1:
			var route_label := "%s_%d" % [_safe_name(str(spec.get("id", "Route"))), i]
			var sections := _ground_sections_for_segment(str(spec.get("id", "")),
				points[i], points[i + 1])
			for section_index in sections.size():
				var section: Dictionary = sections[section_index]
				var section_a: Vector3 = section["a"]
				var section_b: Vector3 = section["b"]
				# A ramp running to the CENTRE of a level landing intersects its
				# vertical side below the top: the first arrival joint had a 0.58 m
				# wall that stopped an ordinary stick-held walk. Join the ramp to
				# the cap edge at cap height, leaving bridge cut endpoints intact.
				var cap_half := maxf(float(landmass.get("landing_size_m", 16.0)),
					collision_width * 2.25) * 0.41
				if section_a.is_equal_approx(points[i]):
					section_a = _landing_join(points[i], points[i + 1], cap_half)
				if section_b.is_equal_approx(points[i + 1]):
					section_b = _landing_join(points[i + 1], points[i], cap_half)
				# Keep one forgiving collision ribbon for controller traversal, but
				# let the visible trail meander and breathe inside it. Bridge intervals
				# are omitted completely so the authored span and drop are real.
				_segment_box(root, "%sGround%d" % [route_label, section_index], section_a,
					section_b, collision_width, 0.72, landing_top, true)
				_path_ribbon(root, "%sTrail%d" % [route_label, section_index], section_a,
					section_b, visible_width,
					i * 97 + section_index * 31 + absi(str(spec.get("id", "Route")).hash()))
				_cover_exclusions.append({"kind": "segment", "a": section_a, "b": section_b,
					"half_width": visible_width * 0.55 + 0.2})
				_surfaces.append({"kind": "segment", "a": section_a, "b": section_b,
					"half_width": collision_width * 0.5, "height": section_a.y})
				_cover_patches.append({"kind":"segment","a":section_a,"b":section_b,
					"half_width":collision_width*0.5,"path_half_width":visible_width*0.5-0.15,
					"surface_offset_y":0.025,"seed":absi(route_label.hash())+section_index,"dry":false})


static func _landing_join(pad: Vector3, toward: Vector3, cap_half: float, length_fraction: float = 0.2) -> Vector3:
	var flat := Vector3(toward.x - pad.x, 0, toward.z - pad.z)
	var length := flat.length()
	if length < 0.01:
		return pad
	var direction := flat / length
	var edge_distance := cap_half / maxf(absf(direction.x), absf(direction.z))
	return pad + direction * minf(edge_distance - 0.25, length * length_fraction)


func _bridge_interior_point(route_id: String, point: Vector3) -> bool:
	for bridge: Dictionary in _config.get("bridges",[]):
		if str(bridge.get("route_id",""))!=route_id:
			continue
		var profile: Array=bridge.get("deck_profile",[])
		for i in range(1,profile.size()-1):
			if _vec3(profile[i]).is_equal_approx(point):
				return true
	return false


func _add_landing_nature(parent: Node3D, points: Array[Vector3], index: int,
		pad: Vector3, landing_size: float, seed_value: int) -> void:
	if points.size() < 2 or posmod(seed_value, 4) == 0 or _inside_settlement_clearance(pad):
		return
	var previous := points[maxi(0, index - 1)]
	var following := points[mini(points.size() - 1, index + 1)]
	var flat := Vector3(following.x - previous.x, 0.0, following.z - previous.z)
	if flat.length_squared() < 0.01:
		return
	var right := Vector3.UP.cross(flat.normalized()).normalized()
	var side := -1.0 if posmod(seed_value, 2) == 0 else 1.0
	var tree := NATURE_TREES[posmod(seed_value, NATURE_TREES.size())].instantiate() as Node3D
	tree.name = "LandingTree%03d" % posmod(seed_value, 1000)
	tree.position = pad + right * side * landing_size * 0.33 - Vector3.UP * 0.12
	tree.rotation.y = float(posmod(seed_value * 17, 41)) / 41.0 * TAU
	tree.rotation.z = deg_to_rad(-0.8 - float(posmod(seed_value, 3)) * 0.6)
	tree.scale = Vector3.ONE * (1.32 + float(posmod(seed_value * 7, 7)) * 0.085)
	_apply_tree_palette(tree, seed_value)
	parent.add_child(tree)
	var nature: Dictionary = _visual_config.get("nature", {})
	_set_geometry_visibility(tree, float(nature.get("tree_visibility_range_m", 1050.0)))


func _build_route_shoulders(root: Node3D, spec: Dictionary, points: Array[Vector3], width: float) -> void:
	var route_name := _safe_name(str(spec.get("id", "Route")))
	var shoulder_root := Node3D.new()
	shoulder_root.name = "%sCliffShoulders" % route_name
	root.add_child(shoulder_root)
	var landmass: Dictionary = _visual_config.get("landmass", {})
	var serial := 0
	for segment_index in points.size() - 1:
		var original_a := points[segment_index]
		var original_b := points[segment_index + 1]
		var half_width := maxf(float(landmass.get("route_shoulder_min_half_width_m", 24.0)),
			width * float(landmass.get("route_shoulder_path_multiplier", 3.8)))
		var route_is_dry := route_name.to_lower().contains("upper") \
			or route_name.to_lower().contains("summit")
		var sections := _ground_sections_for_segment(str(spec.get("id", "")),
			original_a, original_b)
		for section: Dictionary in sections:
			var a: Vector3 = section["a"]
			var b: Vector3 = section["b"]
			_route_ridge(shoulder_root, "Ridge%03d" % serial, a, b, half_width,
				segment_index + int(spec.get("order", 0)) * 17 + serial,
				_materials["upland_dry"] if route_is_dry else _materials["upland"], landmass)
			_add_route_edge_nature(shoulder_root, a, b, half_width, serial)
			var cover_config: Dictionary = _visual_config.get("ground_cover", {})
			var cover_chunks := maxi(1, int(ceilf(a.distance_to(b)
				/ float(cover_config.get("route_cover_chunk_m", 120.0)))))
			for chunk in cover_chunks:
				var chunk_a := a.lerp(b, float(chunk) / float(cover_chunks))
				var chunk_b := a.lerp(b, float(chunk + 1) / float(cover_chunks))
				_cover_patches.append({
					"kind": "segment", "a": chunk_a, "b": chunk_b,
					# The ribbon's narrowest generated station is 0.58x. Sampling
					# inside 0.52x leaves margin even between different-width stations.
					"half_width": half_width * 0.52,
					"path_half_width": float(landmass.get("path_visible_width_m", 4.2)) * 0.5,
					"seed": serial * 3701 + chunk * 101 + absi(route_name.hash()),
					"surface_offset_y": -0.70,
					"dry": route_is_dry,
				})
			serial += 1


## Split an authored ground segment around every bridge assigned to its route.
## The first foundation pass placed bridge meshes over a continuous land ribbon,
## so no causeway actually exposed sky or danger. Keeping the cut here makes the
## same gap authoritative for cliff mass, trail visuals, cover, and collision.
func _ground_sections_for_segment(route_id: String, a: Vector3, b: Vector3) -> Array[Dictionary]:
	var delta := b - a
	var flat_delta:=Vector3(delta.x,0,delta.z)
	var length_squared := flat_delta.length_squared()
	if length_squared < 0.01:
		return []
	var cut_start := 1.0
	var cut_end := 0.0
	for raw: Variant in _config.get("bridges", []):
		if not raw is Dictionary:
			continue
		var bridge := raw as Dictionary
		if str(bridge.get("route_id", "")) != route_id:
			continue
		var endpoints: Variant = bridge.get("endpoints", [])
		if not endpoints is Array or (endpoints as Array).size() < 2:
			continue
		var p0 := _vec3((endpoints as Array)[0])
		var p1 := _vec3((endpoints as Array)[1])
		var t0 := (p0 - a).dot(flat_delta) / length_squared
		var t1 := (p1 - a).dot(flat_delta) / length_squared
		var distance0 := Vector2(p0.x-a.x-flat_delta.x*t0,p0.z-a.z-flat_delta.z*t0).length()
		var distance1 := Vector2(p1.x-a.x-flat_delta.x*t1,p1.z-a.z-flat_delta.z*t1).length()
		# The route now authors the exact bridge endpoints. Only remove ground
		# which actually overlaps that deck, not nearby approach segments whose
		# projections happen to be within 145m of one endpoint.
		if maxf(distance0, distance1) > 0.25:
			continue
		var local_start := clampf(minf(t0, t1), 0.0, 1.0)
		var local_end := clampf(maxf(t0, t1), 0.0, 1.0)
		if local_end <= 0.0 or local_start >= 1.0 or local_end - local_start < 0.015:
			continue
		cut_start = minf(cut_start, local_start)
		cut_end = maxf(cut_end, local_end)
	var result: Array[Dictionary] = []
	if cut_end <= cut_start:
		result.append({"a": a, "b": b})
		return result
	if cut_start > 0.035:
		result.append({"a": a, "b": a.lerp(b, cut_start)})
	if cut_end < 0.965:
		result.append({"a": a.lerp(b, cut_end), "b": b})
	return result


func _build_ground_cover() -> void:
	var cover := GROUND_COVER.new()
	cover.name = "ProceduralGroundCover"
	add_child(cover)
	cover.call("build", _cover_patches, _visual_config.get("ground_cover", {}), _cover_exclusions)


func _inside_settlement_clearance(at: Vector3) -> bool:
	for landmark: Dictionary in _config.get("landmarks", []):
		if str(landmark.get("category", "")) != "settlement":
			continue
		var centre := _vec3(landmark.get("position", []))
		if absf(at.y - centre.y) < 12.0 and Vector2(at.x - centre.x, at.z - centre.z).length() < 36.0:
			return true
	return false


func _inside_landmark_vista(at: Vector3) -> bool:
	for landmark: Dictionary in _config.get("landmarks", []):
		var centre := _vec3(landmark.get("position", []))
		if absf(at.y - centre.y) < 160.0 and Vector2(at.x - centre.x, at.z - centre.z).length() < 170.0:
			return true
	return false


func _build_resource_patches() -> void:
	var root := Node3D.new()
	root.name = "CloudreachResources"
	add_child(root)
	for spec: Dictionary in RESOURCE_PATCH.gatherable_nodes():
		var authored := _vec3(spec.get("position", []))
		var placement_override: Variant = _visual_config.get("resource_positions", {}).get(str(spec.get("id", "")))
		if placement_override is Array:
			authored = _vec3(placement_override)
		var at := _resource_position(authored)
		var patch := RESOURCE_PATCH.new()
		patch.name = str(spec.get("id", "Resource"))
		root.add_child(patch)
		patch.position = at
		patch.setup(spec)
		patch.set_meta("authored_position", _vec3(spec.get("position", [])))
		_cover_exclusions.append({"centre": at, "half": Vector2.ONE * 1.4, "rotation": 0.0})


func _resource_position(authored: Vector3) -> Vector3:
	var y := ground_height_near(authored)
	if not is_nan(y) and absf(y - authored.y) <= 45.0:
		return Vector3(authored.x, y + 0.06, authored.z)
	# Content coordinates predate the compact crowns. Bind each gatherable to
	# the nearest real path of its intended elevation, never the highest XZ.
	var best := Vector3.ZERO
	var best_distance := INF
	for surface: Dictionary in _surfaces:
		if str(surface.get("kind", "")) != "segment":
			continue
		var a: Vector3 = surface["a"]
		var b: Vector3 = surface["b"]
		var ab := Vector2(b.x - a.x, b.z - a.z)
		var t := clampf(Vector2(authored.x - a.x, authored.z - a.z).dot(ab) / maxf(ab.length_squared(), 0.01), 0.06, 0.94)
		var centre := a.lerp(b, t)
		var sideways := Vector3.UP.cross(Vector3(ab.x, 0.0, ab.y).normalized())
		var candidate := centre + sideways * minf(2.6, float(surface.get("half_width", 1.0)) * 0.7)
		var distance := Vector2(candidate.x - authored.x, candidate.z - authored.z).length() + absf(candidate.y - authored.y) * 5.0
		if distance < best_distance:
			best_distance = distance
			best = candidate + Vector3.UP * 0.06
	return best


func _route_ridge(parent: Node3D, label: String, a: Vector3, b: Vector3,
		half_width: float, seed_value: int, top_material: Material, config: Dictionary) -> void:
	var flat := Vector3(b.x - a.x, 0.0, b.z - a.z)
	if flat.length_squared() < 0.01:
		return
	var forward := flat.normalized()
	var right := Vector3.UP.cross(forward).normalized()
	var spacing := float(config.get("route_station_spacing_m", 48.0))
	var station_count := clampi(int(ceilf(flat.length() / maxf(spacing, 8.0))) + 1, 3, 28)
	var left_top: Array[Vector3] = []
	var right_top: Array[Vector3] = []
	var left_track: Array[Vector3] = []
	var right_track: Array[Vector3] = []
	var left_upper: Array[Vector3] = []
	var right_upper: Array[Vector3] = []
	var left_lower: Array[Vector3] = []
	var right_lower: Array[Vector3] = []
	var left_bottom: Array[Vector3] = []
	var right_bottom: Array[Vector3] = []
	for i in station_count:
		var t := float(i) / float(station_count - 1)
		var centre := a.lerp(b, t) - Vector3.UP * 0.72
		var irregular := 0.84 + 0.18 * sin(float(i * 13 + seed_value * 7))
		irregular += 0.08 * cos(float(i * 5 + seed_value * 3))
		var width_here := half_width * irregular
		var left := centre - right * width_here
		var right_edge := centre + right * width_here
		left_track.append(centre - right * half_width * 0.53)
		right_track.append(centre + right * half_width * 0.53)
		left.y -= 4.0 + 9.0 * (1.0 + sin(float(i) * 1.71 + seed_value))
		right_edge.y -= 4.0 + 9.0 * (1.0 + cos(float(i) * 2.13 + seed_value))
		var depth_mix := 0.5 + 0.5 * sin(float(i * 11 + seed_value * 17))
		var depth := maxf(centre.y - float(config.get("geology_base_y", -210.0)),
			lerpf(float(config.get("route_cliff_depth_min_m", 36.0)),
			float(config.get("route_cliff_depth_max_m", 92.0)), depth_mix))
		left_top.append(left)
		right_top.append(right_edge)
		# A ridge is a mountain cross-section, not a retaining wall. Broad,
		# uneven shoulders step into talus below the narrow traversable crest.
		var upper_push := 1.65 + 0.75 * sin(float(i) * 1.37 + seed_value * 0.73)
		var lower_push := 3.5 + 1.7 * cos(float(i) * 1.83 + seed_value * 0.39)
		var shelf_depth := 35.0 + depth_mix * 35.0
		var talus_depth := depth * (0.38 + depth_mix * 0.22)
		if i > 0 and i < station_count - 1 and sin(float(i * 11 + seed_value)) > -0.35 and not _inside_landmark_vista(centre):
			var side := -1.0 if sin(float(i * 7 + seed_value * 3)) > 0 else 1.0
			var relief := 3.0 + depth_mix * 8.0
			var spur_height := depth + relief
			var spur_width := maxf(65.0, half_width * (2.8 + depth_mix * 1.6))
			var spur_at := Vector3(centre.x, centre.y + relief - spur_height * 0.5, centre.z)
			spur_at += right * side * (half_width + spur_width * 0.40)
			_mesa(parent, "%sRockShoulder%d" % [label, i], spur_at,
				Vector3(spur_width, spur_height, spur_width * (0.7 + depth_mix * 0.5)),
				_materials["cliff_mid"], _materials["cliff_high"], false, seed_value + i * 7, true)
			if posmod(i + seed_value, 3) == 0:
				var shelf := centre + right * side * (half_width + 8.0) - Vector3.UP * 8.0
				_mesa(parent, "%sRootedShelf%d" % [label, i], shelf - Vector3.UP * 9.0,
					Vector3(23, 18, 21), _materials["cliff"], _materials["upland"], true, seed_value + i)
				var tree := NATURE_TREES[posmod(seed_value + i, NATURE_TREES.size())].instantiate() as Node3D
				tree.position = shelf
				tree.scale = Vector3.ONE * 0.9
				_apply_tree_palette(tree, seed_value + i)
				parent.add_child(tree)
				_set_geometry_visibility(tree, 950.0)
		left_upper.append(centre + (left - centre) * upper_push - Vector3.UP * shelf_depth)
		right_upper.append(centre + (right_edge - centre) * upper_push - Vector3.UP * (shelf_depth * 0.85))
		left_lower.append(centre + (left - centre) * lower_push - Vector3.UP * talus_depth)
		right_lower.append(centre + (right_edge - centre) * lower_push - Vector3.UP * (talus_depth * 0.9))
		var foot_width := maxf(half_width * 4.0, depth * (0.40 + depth_mix * 0.20))
		left_bottom.append(Vector3(centre.x, centre.y - depth, centre.z) - right * foot_width)
		right_bottom.append(Vector3(centre.x, centre.y - depth * 0.94, centre.z) + right * foot_width * 1.15)

	var mesh := ArrayMesh.new()
	var top_tool := SurfaceTool.new()
	top_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	top_tool.set_material(top_material)
	for i in station_count - 1:
		_add_surface_triangle(top_tool, left_track[i], left_track[i + 1], right_track[i])
		_add_surface_triangle(top_tool, right_track[i], left_track[i + 1], right_track[i + 1])
		_add_surface_triangle(top_tool, left_top[i], left_top[i + 1], left_track[i])
		_add_surface_triangle(top_tool, left_track[i], left_top[i + 1], left_track[i + 1])
		_add_surface_triangle(top_tool, right_track[i], right_track[i + 1], right_top[i])
		_add_surface_triangle(top_tool, right_top[i], right_track[i + 1], right_top[i + 1])
	top_tool.generate_normals()
	top_tool.commit(mesh)

	var upper_tool := SurfaceTool.new()
	upper_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	upper_tool.set_material(_materials["cliff_high"])
	for i in station_count - 1:
		_add_geological_face(upper_tool, left_top[i + 1], left_top[i], left_upper[i + 1], left_upper[i], -right, -right, 5.0)
		_add_geological_face(upper_tool, right_top[i], right_top[i + 1], right_upper[i], right_upper[i + 1], right, right, 5.0)
	# All cliff bands now share one geological material; submit one surface.
	var middle_tool := upper_tool
	for i in station_count - 1:
		_add_geological_face(middle_tool, left_upper[i + 1], left_upper[i], left_lower[i + 1], left_lower[i], -right, -right, 9.0)
		_add_geological_face(middle_tool, right_upper[i], right_upper[i + 1], right_lower[i], right_lower[i + 1], right, right, 9.0)
	var deep_tool := upper_tool
	for i in station_count - 1:
		_add_geological_face(deep_tool, left_lower[i + 1], left_lower[i], left_bottom[i + 1], left_bottom[i], -right, -right, 15.0)
		_add_geological_face(deep_tool, right_lower[i], right_lower[i + 1], right_bottom[i], right_bottom[i + 1], right, right, 15.0)
	# End faces prevent the ribbon's first/last station reading as a sliced box.
	_add_surface_triangle(deep_tool, left_top[0], right_top[0], left_bottom[0])
	_add_surface_triangle(deep_tool, left_bottom[0], right_top[0], right_bottom[0])
	var last := station_count - 1
	_add_surface_triangle(deep_tool, left_top[last], left_bottom[last], right_top[last])
	_add_surface_triangle(deep_tool, left_bottom[last], right_bottom[last], right_top[last])
	deep_tool.generate_normals()
	deep_tool.commit(mesh)

	var ridge := MeshInstance3D.new()
	ridge.name = label
	ridge.mesh = mesh
	ridge.visibility_range_end = 1900.0
	ridge.visibility_range_end_margin = 160.0
	parent.add_child(ridge)


func _add_surface_triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	# Geometry recipes above use outward cross products. Godot's front faces
	# are clockwise, so submit their reverse. The previous winding rendered
	# crowns/path ribbons only from below and exposed the inner cliff walls.
	tool.set_uv(Vector2(a.x, a.z) * 0.04)
	tool.add_vertex(a)
	tool.set_uv(Vector2(c.x, c.z) * 0.04)
	tool.add_vertex(c)
	tool.set_uv(Vector2(b.x, b.z) * 0.04)
	tool.add_vertex(b)


func _geological_point(point: Vector3, outward: Vector3, amount: float) -> Vector3:
	# Continuous displacement in world space keeps adjacent faces stitched.
	# The slow bend makes shelf lines wander instead of forming uniform stripes.
	var bend := sin(point.x * 0.023 + point.z * 0.017) * 1.4
	var bed:=fposmod((point.y+bend*3.5)/13.0,1.0)
	var shelf:=0.55-smoothstep(0.15,0.72,bed)
	var fracture:=sin(point.x*0.071-point.z*0.059+point.y*0.033)
	return point+outward*(shelf*0.9+fracture*0.6)*amount


func _add_geological_face(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		out_a: Vector3, out_b: Vector3, relief: float) -> void:
	# Equal row fractions on every neighboring face prevent T-junction cracks.
	var rows := 20
	var columns := clampi(int(a.distance_to(b) / 20.0), 1, 5)
	for row in rows:
		var v0 := float(row) / rows
		var v1 := float(row + 1) / rows
		for column in columns:
			var u0 := float(column) / columns
			var u1 := float(column + 1) / columns
			var n0 := out_a.lerp(out_b, u0).normalized()
			var n1 := out_a.lerp(out_b, u1).normalized()
			var p00 := _geological_point(a.lerp(b, u0).lerp(c.lerp(d, u0), v0), n0, relief * sin(PI * v0))
			var p10 := _geological_point(a.lerp(b, u1).lerp(c.lerp(d, u1), v0), n1, relief * sin(PI * v0))
			var p01 := _geological_point(a.lerp(b, u0).lerp(c.lerp(d, u0), v1), n0, relief * sin(PI * v1))
			var p11 := _geological_point(a.lerp(b, u1).lerp(c.lerp(d, u1), v1), n1, relief * sin(PI * v1))
			_add_surface_triangle(tool, p00, p10, p01)
			_add_surface_triangle(tool, p01, p10, p11)


func _path_ribbon(parent: Node3D, label: String, a: Vector3, b: Vector3,
		width: float, seed_value: int) -> void:
	var flat := Vector3(b.x - a.x, 0.0, b.z - a.z)
	if flat.length_squared() < 0.01:
		return
	var right := Vector3.UP.cross(flat.normalized()).normalized()
	var up := _segment_basis(a, b).y
	var stations := clampi(int(ceilf(flat.length() / 5.0)) + 1, 5, 180)
	var left: Array[Vector3] = []
	var right_edge: Array[Vector3] = []
	for i in stations:
		var t := float(i) / float(stations - 1)
		var envelope := sin(PI * t)
		var wander := sin(t * TAU * 1.35 + float(seed_value % 29)) * width * 0.18 * envelope
		wander += sin(t * TAU * 3.1 + float(seed_value % 11)) * width * 0.08 * envelope
		var half_here := width * (0.43 + 0.08 * sin(t * TAU * 2.4 + float(seed_value % 17)))
		half_here += width * 0.03 * sin(t * TAU * 4.0 + seed_value)
		var centre := a.lerp(b, t) + right * wander + up * 0.06
		left.append(centre - right * half_here)
		right_edge.append(centre + right * half_here)
	var mesh := ArrayMesh.new()
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(_materials["trail_dry"] if minf(parent.to_global(a).y,parent.to_global(b).y)>=700.0 else _materials["trail"])
	for i in stations - 1:
		_add_trail_triangle(tool, left[i], left[i + 1], right_edge[i], Vector2(0, i), Vector2(0, i + 1), Vector2(1, i))
		_add_trail_triangle(tool, right_edge[i], left[i + 1], right_edge[i + 1], Vector2(1, i), Vector2(0, i + 1), Vector2(1, i + 1))
	tool.generate_normals()
	tool.commit(mesh)
	var trail := MeshInstance3D.new()
	trail.name = label
	trail.mesh = mesh
	trail.visibility_range_end = 1200.0
	trail.visibility_range_end_margin = 100.0
	parent.add_child(trail)


func _add_trail_triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ua: Vector2, ub: Vector2, uc: Vector2) -> void:
	tool.set_uv(ua)
	tool.add_vertex(a)
	tool.set_uv(uc)
	tool.add_vertex(c)
	tool.set_uv(ub)
	tool.add_vertex(b)


func _add_route_edge_nature(parent: Node3D, a: Vector3, b: Vector3,
		half_width: float, serial: int) -> void:
	var nature: Dictionary = _visual_config.get("nature", {})
	var flat := Vector3(b.x - a.x, 0.0, b.z - a.z)
	if flat.length_squared() < 0.01:
		return
	var forward := flat.normalized()
	var right := Vector3.UP.cross(forward).normalized()
	# A route segment can be several hundred metres long. Populate it in
	# readable edge clusters rather than putting one tiny grove at its midpoint.
	var cluster_count := clampi(int(ceilf(flat.length() / 74.0)), 3, 9)
	for cluster in cluster_count:
		var t := float(cluster + 1) / float(cluster_count + 1)
		# The route ridge's walkable top sits below the authored spline. Keep all
		# imported nature rooted into that same generated surface.
		var anchor := a.lerp(b, t) - Vector3.UP * 0.72
		if _inside_settlement_clearance(anchor):
			continue
		var side := -1.0 if (serial + cluster) % 2 == 0 else 1.0
		var rock := NATURE_ROCKS[(serial + cluster) % NATURE_ROCKS.size()].instantiate() as Node3D
		rock.name = "RouteRock%03d_%d" % [serial, cluster]
		rock.position = anchor + right * side * half_width * 0.46 - Vector3.UP * 0.32
		rock.rotation.y = float(posmod(serial * 17 + cluster * 11, 31)) / 31.0 * TAU
		rock.scale = Vector3.ONE * (1.0 + float(posmod(serial * 7 + cluster * 5, 9)) * 0.10)
		parent.add_child(rock)
		_set_geometry_visibility(rock, float(nature.get("rock_visibility_range_m", 820.0)))
		for grove_tree in 2:
			# Skip occasional trees to preserve windswept openings and sightlines.
			if posmod(serial * 3 + cluster * 5 + grove_tree, 7) == 0:
				continue
			var tree := NATURE_TREES[(serial + cluster + grove_tree) % NATURE_TREES.size()].instantiate() as Node3D
			tree.name = "RouteTree%03d_%d_%d" % [serial, cluster, grove_tree]
			tree.position = (
				anchor + right * side * half_width * (0.39 + grove_tree * 0.08)
				+ forward * (float(grove_tree) - 0.5) * 10.0
			)
			tree.position.y += (b.y - a.y) / flat.length() * (float(grove_tree) - 0.5) * 10.0 - 0.08
			tree.rotation = Vector3(0.0,
				float(posmod(serial * 13 + cluster * 7 + grove_tree * 19, 37)) / 37.0 * TAU,
				deg_to_rad(-0.4 - float(grove_tree) * 1.1))
			tree.scale = Vector3.ONE * (1.28
				+ float(posmod(serial * 5 + cluster * 3 + grove_tree * 3, 8)) * 0.085)
			_apply_tree_palette(tree, serial * 31 + cluster * 7 + grove_tree)
			parent.add_child(tree)
			_set_geometry_visibility(tree, float(nature.get("tree_visibility_range_m", 1050.0)))


func _set_geometry_visibility(root_node: Node, distance: float) -> void:
	if root_node is GeometryInstance3D:
		var geometry := root_node as GeometryInstance3D
		geometry.visibility_range_end = distance
		geometry.visibility_range_end_margin = minf(120.0, distance * 0.14)
	for child: Node in root_node.get_children():
		_set_geometry_visibility(child, distance)


## Small, individually authored places along the road. Imported meshes retain
## their production materials; the shared prefab utility measures real bounds
## so barrels, wagons and shrubs agree with the 1.80 m trainer.
func _build_authored_route_details() -> void:
	var root := Node3D.new()
	root.name = "AuthoredRouteDetails"
	add_child(root)
	var detail: Dictionary = _visual_config.get("route_details", {})
	var bounds_tool := BUILDING_PREFABS.new()
	for raw: Dictionary in detail.get("pockets", []):
		var pocket := Node3D.new()
		pocket.name = str(raw.get("id", "Pocket"))
		root.add_child(pocket)
		var anchor := _vec3(raw.get("anchor", []))
		var forward := _vec3(raw.get("forward", [0.0, 0.0, 1.0])).normalized()
		forward.y = 0.0
		forward = forward.normalized()
		var right := Vector3.UP.cross(forward)
		for item: Dictionary in raw.get("items", []):
			var asset := str(item.get("asset", "rock"))
			var packed := ROUTE_DETAIL_SCENES.get(asset) as PackedScene
			if packed == null:
				continue
			var offset: Array = item.get("offset", [0.0, 0.0])
			var at := anchor + right * float(offset[0]) + forward * float(offset[1])
			var ground := _route_detail_ground(at)
			if is_nan(ground):
				push_warning("Cloudreach detail %s/%s has no supporting surface" % [pocket.name, asset])
				continue
			var model := packed.instantiate() as Node3D
			var bounds: AABB = bounds_tool.combined_aabb(model)
			var span := maxf(bounds.size.x, bounds.size.z) if item.has("width_m") else bounds.size.y
			var size_m := float(item.get("width_m", item.get("height_m", 1.0)))
			var scale_value := size_m / maxf(span, 0.01)
			var placement := Node3D.new()
			placement.name = "%s%02d" % [asset.capitalize(), pocket.get_child_count()]
			placement.position = Vector3(at.x, ground - float(item.get("bury_m", 0.04)), at.z)
			placement.rotation.y = atan2(forward.x, forward.z) + deg_to_rad(float(item.get("yaw_deg", 0.0)))
			pocket.add_child(placement)
			model.scale = Vector3.ONE * scale_value
			model.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * scale_value
			placement.add_child(model)
			if asset == "bush" or asset == "flowers":
				_apply_tree_palette(model, pocket.get_child_count())
			_set_geometry_visibility(placement, float(detail.get("visibility_range_m", 320.0)))


## Route shoulders are visual ground, while the controller collision ribbon is
## narrower. Use the same conservative shoulder samples as ground cover, and
## reject unrelated stacked plateaus rather than floating a prop across a gap.
func _route_detail_ground(at: Vector3) -> float:
	var ground := ground_height_at(at.x, at.z)
	if not is_nan(ground) and absf(ground - at.y) < 8.0:
		return ground
	for patch: Dictionary in _cover_patches:
		if str(patch.get("kind", "")) != "segment":
			continue
		var a: Vector3 = patch["a"]
		var b: Vector3 = patch["b"]
		var ab := Vector2(b.x - a.x, b.z - a.z)
		var t := Vector2(at.x - a.x, at.z - a.z).dot(ab) / maxf(ab.length_squared(), 0.01)
		if t < 0.0 or t > 1.0:
			continue
		var centre := a.lerp(b, t)
		if Vector2(at.x - centre.x, at.z - centre.z).length() > float(patch["half_width"]):
			continue
		var height := centre.y + float(patch.get("surface_offset_y", -0.72))
		if absf(height - at.y) < 8.0:
			return height
	return NAN


## Reuse the Meadows' desaturated green leaf sheet on the installed Quaternius
## trees. The source twisted-tree sheet is crimson and the raw common sheet is
## fluorescent; both break the project's one-nature-family palette. Surface
## overrides preserve the imported meshes, LOD chains, alpha mode and shadows.
func _apply_tree_palette(root_node: Node, seed_value: int) -> void:
	if root_node is MeshInstance3D:
		var instance := root_node as MeshInstance3D
		if instance.mesh != null:
			for surface in instance.mesh.get_surface_count():
				var source := instance.mesh.surface_get_material(surface) as StandardMaterial3D
				if source == null:
					continue
				var key_name := source.resource_name.to_lower()
				if not key_name.contains("leaves") and not key_name.contains("bark"):
					continue
				var variant := posmod(seed_value, 3)
				var cache_key := "%s|%d" % [source.resource_path if source.resource_path != "" \
					else source.resource_name, variant]
				var material := _tree_palette_materials.get(cache_key) as StandardMaterial3D
				if material == null:
					material = source.duplicate(true) as StandardMaterial3D
					if key_name.contains("leaves"):
						material.albedo_texture = CLOUDREACH_LEAF_TEXTURE
						material.albedo_color = [Color("#eef1d5"), Color("#b9cbb5"),
							Color("#ded39a")][variant]
					else:
						material.albedo_color = [Color("#adb5ad"), Color("#929e96"),
							Color("#a6ac96")][variant]
					material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
					_tree_palette_materials[cache_key] = material
				instance.set_surface_override_material(surface, material)
	for child: Node in root_node.get_children():
		_apply_tree_palette(child, seed_value)


func _build_bridges() -> void:
	var root := Node3D.new()
	root.name = "SuspendedBridges"
	add_child(root)
	for spec: Dictionary in _config.get("bridges", []):
		var points: Array = spec.get("deck_profile",spec.get("endpoints",[]))
		if points.size()<2:
			continue
		var bridge:=Node3D.new()
		bridge.name=_safe_name(str(spec.get("id","Bridge")))
		root.add_child(bridge)
		for i in points.size()-1:
			var section:=Node3D.new()
			section.name="DeckSection%d"%i
			bridge.add_child(section)
			var a:=_vec3(points[i])
			var b:=_vec3(points[i+1])
			var cap_half:=float(_visual_config.get("landmass",{}).get("landing_size_m",16.0))*0.41
			if i==0:
				a=_landing_join(a,b,cap_half,0.75)
			if i==points.size()-2:
				b=_landing_join(b,a,cap_half,0.75)
			_build_bridge_section(section,spec,a,b)
		for end_index in [0,points.size()-1]:
			var endpoint:=_vec3(points[end_index])
			var neighbor:=_vec3(points[1] if end_index==0 else points[points.size()-2])
			var away:=Vector3(endpoint.x-neighbor.x,0,endpoint.z-neighbor.z).normalized()
			var right:=Vector3.UP.cross(away)
			for side: float in [-1.0,1.0]:
				for layer in 2:
					var foot:=endpoint+away*(3.0+layer*5.5)+right*side*(6.0+layer*2.5)
					_visual_rock_mass(bridge,"RootedAbutmentShoulder",foot-Vector3.UP*(18.0+layer*9.0),
						Vector3(13.0+layer*5.0,17.2+layer*8.0,16.0),2111+end_index*13+layer*5+int(side))
				var verge:=endpoint+away*8+right*side*5.0
				var ground:=_route_detail_ground(verge)
				if not is_nan(ground) and absf(ground-verge.y)<2.0:
					verge.y=ground+0.08
					_plant_floor_pocket(bridge,verge,Vector2(1.6,2.3),2217+end_index+int(side),endpoint.y>700)


func _build_bridge_section(bridge: Node3D, spec: Dictionary, a: Vector3, b: Vector3) -> void:
	var width := float(spec.get("width_m", 3.2))
	var length := a.distance_to(b)
	var count := clampi(int(ceilf(length / 4.5)), 8, 72)
	var bridge_type := str(spec.get("type", "rope_suspension"))
	var stone_bridge := bridge_type.contains("stone")
	_segment_box(bridge, "WalkableDeck", a, b, width, 0.42,
		_materials["stone"] if stone_bridge else _materials["wood"], true)
	if not stone_bridge:
		BRIDGE_KIT.build_deck(bridge,a,b,width)
	var plank_mesh := BoxMesh.new()
	plank_mesh.size = Vector3(width, 0.16, length / float(count) * 0.86)
	plank_mesh.material = _materials["masonry_trim"] if stone_bridge else _materials["wood"]
	var plank_instances := MultiMesh.new()
	plank_instances.transform_format = MultiMesh.TRANSFORM_3D
	plank_instances.mesh = plank_mesh
	plank_instances.instance_count = count
	var planks := MultiMeshInstance3D.new()
	planks.name = "BatchedDeckPlanks"
	planks.multimesh = plank_instances
	bridge.add_child(planks)
	planks.visible=stone_bridge
	var deck_basis := _segment_basis(a, b)
	for i in count:
		var t := (float(i) + 0.5) / float(count)
		var p := a.lerp(b, t)
		plank_instances.set_instance_transform(i, Transform3D(deck_basis, p + deck_basis.y * 0.12))
	if not stone_bridge:
		var rope_segments := clampi(int(ceilf(length / 18.0)), 8, 32)
		var tangent := (b - a).normalized()
		var right := Vector3.UP.cross(tangent).normalized()
		for i in rope_segments:
			var t := float(i) / float(rope_segments)
			var next_t := float(i + 1) / float(rope_segments)
			for side: float in [-1.0, 1.0]:
				var sag_a := a.lerp(b, t) + right * width * 0.62 * side + Vector3.UP * (1.75 - 0.85 * sin(PI * t))
				var q := a.lerp(b, next_t) + right * width * 0.62 * side + Vector3.UP * (1.75 - 0.85 * sin(PI * next_t))
				_cylinder_between(bridge, "Rope%02d" % i, sag_a, q, 0.055, _materials["rope"])
	for endpoint: Vector3 in [a, b]:
		var tangent := (b - a).normalized()
		var right := Vector3.UP.cross(tangent).normalized()
		for side: float in [-1.0, 1.0]:
			var post_at:=endpoint+right*width*0.62*side
			_box(bridge,"SquaredTimberPost",post_at+Vector3.UP*1.15,Vector3(0.28,2.3,0.28),_materials["wood"],false)
			for band_y in [0.25,1.6]:
				_box(bridge,"PostIronBinding",post_at+Vector3.UP*band_y,Vector3(0.33,0.13,0.33),_materials["bronze"],false)
			_cylinder_between(bridge,"SplayedTimberBrace",post_at+Vector3.UP*0.9,post_at+tangent*1.2,0.075,_materials["wood"])
			for wrap in 3:
				var lashing:=TorusMesh.new()
				lashing.inner_radius=0.14
				lashing.outer_radius=0.19
				lashing.rings=8
				lashing.ring_segments=6
				var tie:=MeshInstance3D.new()
				tie.mesh=lashing
				tie.material_override=_materials["rope"]
				tie.position=post_at+Vector3.UP*(1.7+wrap*0.065)
				bridge.add_child(tie)
	_surfaces.append({"kind": "segment", "a": a, "b": b, "half_width": width * 0.5, "height": a.y})


func _build_progression_gates() -> void:
	var root := Node3D.new()
	root.name = "TraversalGates"
	add_child(root)
	for raw: Variant in _config.get("gates", []):
		if not raw is Dictionary:
			continue
		var spec := raw as Dictionary
		var at := _vec3(spec.get("position", []))
		var required := str(spec.get("requires_unlock", ""))
		var flight := str(spec.get("required_traversal", "ground")) == "fly"
		var gate := Node3D.new()
		gate.name = _safe_name(str(spec.get("id", "TraversalGate")))
		gate.position = at
		gate.rotation.y = _gate_yaw_for(required, at)
		root.add_child(gate)
		var opening_width := 22.0 if flight else 16.0
		var opening_height := 18.0 if flight else 7.5
		if not flight:
			_box(gate, "LeftPier", Vector3(-opening_width * 0.58, opening_height * 0.5, 0.0),
				Vector3(2.0, opening_height + 3.0, 2.2), _materials["masonry"], true)
			_box(gate, "RightPier", Vector3(opening_width * 0.58, opening_height * 0.5, 0.0),
				Vector3(2.0, opening_height + 3.0, 2.2), _materials["masonry"], true)
			_box(gate, "Counterweight", Vector3(0.0, opening_height + 1.1, 0.0),
				Vector3(opening_width + 4.0, 2.2, 2.2), _materials["masonry_trim"], true)
		var barrier := StaticBody3D.new()
		barrier.name = "LockedTraversalBarrier"
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(opening_width, opening_height, 1.2)
		shape_node.shape = shape
		shape_node.position.y = opening_height * 0.5
		barrier.add_child(shape_node)
		gate.add_child(barrier)
		var veil := Node3D.new()
		veil.name = "LockedWindVeil"
		veil.position.y = opening_height * 0.5
		gate.add_child(veil)
		for layer in 3:
			var stream:=MeshInstance3D.new()
			stream.name="LockedCrosswindLayer%d"%layer
			var veil_mesh:=PlaneMesh.new()
			veil_mesh.orientation=PlaneMesh.FACE_Z
			veil_mesh.size=Vector2(opening_width,opening_height)
			stream.mesh=veil_mesh
			stream.position.z=(layer-1)*0.65
			var wind:=ShaderMaterial.new()
			wind.shader=preload("res://shaders/cloudreach_locked_wind.gdshader")
			wind.set_shader_parameter("phase",layer*2.1)
			stream.material_override=wind
			veil.add_child(stream)
		_progression_gates.append({"flag": required, "shape": shape_node, "veil": veil})


func _gate_yaw_for(required_flag: String, at: Vector3) -> float:
	for raw: Variant in _config.get("routes", []):
		if not raw is Dictionary or str((raw as Dictionary).get("requires_unlock", "")) != required_flag:
			continue
		var line: Variant = (raw as Dictionary).get("polyline", [])
		if not line is Array or (line as Array).size() < 2:
			continue
		for i in (line as Array).size()-1:
			var a := _vec3((line as Array)[i])
			var b := _vec3((line as Array)[i+1])
			var closest:=Geometry3D.get_closest_point_to_segment(at,a,b)
			if closest.distance_to(at)<2.0:
				return atan2(b.x - a.x, b.z - a.z)
	return 0.0


func _sync_progression_gates(game: Node) -> void:
	var progression: Variant = game.get("progression") if game != null else null
	_progression_revision = int((progression as RefCounted).get("revision")) if progression is RefCounted else -1
	for record: Dictionary in _progression_gates:
		var flag := str(record.get("flag", ""))
		var opened := flag == "" or (progression is RefCounted and bool((progression as RefCounted).call("has", flag)))
		var shape := record.get("shape") as CollisionShape3D
		var veil := record.get("veil") as Node3D
		if shape != null:
			shape.set_deferred("disabled", opened)
		if veil != null:
			veil.visible = not opened


func _build_landmarks() -> void:
	var root := Node3D.new()
	root.name = "Landmarks"
	add_child(root)
	for raw: Variant in _config.get("landmarks", []):
		if not raw is Dictionary:
			continue
		var spec := raw as Dictionary
		var at := _vec3(spec.get("position", []))
		var landmark := Node3D.new()
		landmark.name = _safe_name(str(spec.get("id", "Landmark")))
		landmark.position = at
		root.add_child(landmark)
		var settlement := str(spec.get("category", "")) == "settlement"
		var ledge_size := Vector3(92.0, 100.0, 86.0) if settlement else Vector3(46.0, 72.0, 44.0)
		if str(spec.get("id", "")) == "sky_shrine_heartstone":
			# The old 72 m cap stopped in the air above its parent highland crown.
			# Carry this exceptional Fly-only pinnacle down into the cloud valley.
			ledge_size = Vector3(132.0, at.y + 210.0, 126.0)
		var ledge:=_mesa(landmark, "LandmarkLedge", Vector3(0.0, -ledge_size.y * 0.5 + 0.10, 0.0), ledge_size,
			_materials["cliff"], _materials["upland_dry"] if at.y>=700.0 else _materials["upland"], not settlement, _landmark_count + 31)
		if settlement:
			(ledge.get_node("StratifiedCliffBody") as MeshInstance3D).visible=false
			_build_articulated_settlement_skirt(landmark,at.y>=700.0)
			# The last approach reaches terrace height at z=490. Keep its collision
			# inside that level approach while the geological skirt extends farther.
			_box(landmark, "SettlementWalkableTerrace", Vector3(0, -0.22, 0),
				Vector3(48, 0.44, 48), _materials["upland_dry"], true).visible = false
		_surfaces.append({"kind": "rect", "centre": Vector2(at.x, at.z), "half": Vector2(17.0, 17.0), "height": at.y})
		_cover_patches.append({"kind": "ellipse", "centre": at, "half": Vector2(25.5,25.5) if settlement else Vector2(16.5, 15.5),
			"inner_clear_fraction": 0.42, "seed": _landmark_count * 71 + 809,
			"dry": at.y >= 790.0})
		var landmark_id := str(spec.get("id", ""))
		var identity := (landmark_id + " " + str(spec.get("category", ""))).to_lower()
		if landmark_id == "realm_gate_crag":
			_build_realm_gate_crag(landmark)
		elif landmark_id == "three_bells_bridge":
			_build_three_bells(landmark)
		elif landmark_id == "broken_skyroad_arch":
			_build_broken_arch(landmark)
		elif landmark_id == "windscar_beacon":
			_build_windscar_beacon(landmark)
		elif landmark_id == "windscar_flight_aerie":
			_build_flight_aerie(landmark)
		elif landmark_id == "high_roost_perches":
			_build_high_perches(landmark)
		elif landmark_id == "old_wind_observatory":
			_build_observatory(landmark)
		elif landmark_id == "waterward_overlook":
			_build_waterward_overlook(landmark)
		elif identity.contains("settlement") or identity.contains("village"):
			_build_cliff_settlement(landmark)
		elif identity.contains("shrine") or identity.contains("roost"):
			_build_sky_shrine(landmark)
		elif identity.contains("stronghold") or identity.contains("summit"):
			_build_summit_stronghold(landmark)
		else:
			_build_wayfinder(landmark)
		# A landmark must never outlive its supporting geology in the distance;
		# otherwise tiny towers/perches hang in the sky above a culled plateau.
		_set_geometry_visibility(landmark, 2400.0)
		_landmark_count += 1


func _build_articulated_settlement_skirt(root: Node3D,dry: bool) -> void:
	# Appearance only: the unchanged 48m square collision terrace remains the
	# authoritative floor. A flat inner crown covers that square completely;
	# inset sloping turf and overlapping rock shoulders replace the rounded stack.
	var crown:=SurfaceTool.new()
	crown.begin(Mesh.PRIMITIVE_TRIANGLES)
	crown.set_material(_materials["upland_dry"] if dry else _materials["upland"])
	var subsoil:=SurfaceTool.new()
	subsoil.begin(Mesh.PRIMITIVE_TRIANGLES)
	subsoil.set_material(_materials["cliff"])
	for i in 48:
		var a:=TAU*i/48.0
		var b:=TAU*(i+1)/48.0
		var ra:=24.1/maxf(absf(cos(a)),absf(sin(a)))
		var rb:=24.1/maxf(absf(cos(b)),absf(sin(b)))
		var p:=Vector3(cos(a)*ra,0.11,sin(a)*ra)
		var q:=Vector3(cos(b)*rb,0.11,sin(b)*rb)
		var outer_a:=Vector3(cos(a)*(ra+9.0+3.0*sin(a*3)), -10.0-7.0*sin(a*2+1),sin(a)*(ra+9.0+3.0*sin(a*3)))
		var outer_b:=Vector3(cos(b)*(rb+9.0+3.0*sin(b*3)), -10.0-7.0*sin(b*2+1),sin(b)*(rb+9.0+3.0*sin(b*3)))
		_add_surface_triangle(crown,Vector3(0,0.11,0),q,p)
		_add_surface_triangle(crown,p,q,outer_a)
		_add_surface_triangle(crown,q,outer_b,outer_a)
		# The turf is the roof of a solid geological volume, never a floating
		# sheet between boulders. Close every outer edge down behind the crags.
		var base_a:=Vector3(outer_a.x*1.05,-92.0,outer_a.z*1.05)
		var base_b:=Vector3(outer_b.x*1.05,-92.0,outer_b.z*1.05)
		_add_geological_face(subsoil,outer_a,outer_b,base_a,base_b,
			Vector3(cos(a),0,sin(a)),Vector3(cos(b),0,sin(b)),2.0)
	crown.generate_normals()
	var turf:=MeshInstance3D.new()
	turf.name="IrregularTurfToRockCrown"
	turf.mesh=crown.commit()
	root.add_child(turf)
	subsoil.generate_normals()
	var core:=MeshInstance3D.new()
	core.name="ClosedSettlementSubsoil"
	core.mesh=subsoil.commit()
	root.add_child(core)
	for i in 12:
		var angle:=TAU*i/12.0+0.12
		var radius:=30.0+4.0*sin(angle*3)
		var height:=86.0+9.0*sin(angle*2+0.7)
		_visual_rock_mass(root,"SettlementRootedButtress%02d"%i,
			Vector3(cos(angle)*radius,-height-4.0,sin(angle)*radius),
			Vector3(29.0+5.0*(i%3),height,28.0),1043+i*17,1800.0)
		if i%2==0:
			var contact:=Vector3(cos(angle)*21.5,0.12,sin(angle)*21.5)
			_plant_floor_pocket(root,contact,Vector2(2.6,3.0),1211+i,dry)


func _build_return_gate() -> void:
	var points: Dictionary = _config.get("transition_points", {})
	var raw: Variant = points.get("meadows_return", {})
	if not raw is Dictionary:
		return
	var spec := raw as Dictionary
	var gate: Node3D = REALM_GATE.new()
	gate.name = "MeadowsReturnRealmGate"
	gate.position = _vec3(spec.get("position", []))
	gate.rotation.y = deg_to_rad(float(spec.get("facing_yaw_deg", 180.0)))
	gate.call("setup", "meadows", str(spec.get("peer_anchor_id", "meadows_cloudreach_gate_return")),
		"The Meadows", "realm_key_cloudreach", "realm_gate_cloudreach_unlocked")
	add_child(gate)


func _build_cliff_settlement(root: Node3D) -> void:
	_cover_exclusions.append({"centre": root.global_position + Vector3(0, 0, -10),
		"half": Vector2(7, 7), "rotation": 0.0})
	# A tall windwatch anchors the cluster at route-view distance; the houses
	# then read as an inhabited terrace instead of five same-sized boxes.
	var upper_settlement := root.global_position.y > 700.0
	var watch := Vector3(-20, 0, 18) if upper_settlement else Vector3(-22, 0, 15)
	var watch_height := 19.0 if upper_settlement else 16.0
	_castle_piece(root, "WindwatchTower", CASTLE_TOWER, watch, Vector3(10.0, watch_height, 10.0), _materials["stone_light"])
	_box(root, "WindwatchCrown", watch + Vector3.UP * (watch_height - 0.2), Vector3(11.0, 1.0, 11.0), _materials["wood"], false)
	_box(root,"WindwatchSplayedFoot",watch+Vector3.UP*0.65,Vector3(10.5,1.3,10.5),_materials["masonry"],false)
	for side: float in [-1.0, 1.0]:
		_box(root, "WindBanner", watch + Vector3(side * 4.6, watch_height - 2.8, 0),
			Vector3(0.18, 4.2, 2.4), _materials["leaf_gold"], false)
	if _building_prefabs == null:
		_building_prefabs = BUILDING_PREFABS.new()
		_building_prefabs.call("load_recipes")
	var settlement: Dictionary = _visual_config.get("settlement", {})
	for house: Dictionary in settlement.get("houses", []):
		var prefab := str(house["prefab"])
		var model := _building_prefabs.call("instantiate", prefab) as Node3D
		if model == null:
			continue
		model.name = "Terrace_%s_%d" % [prefab, root.get_child_count()]
		model.position = _vec3(house.get("lower_position",house["position"]) if not upper_settlement else house["position"])
		model.rotation.y = deg_to_rad(float(house.get("lower_yaw_deg",house.get("yaw_deg",0.0)) if not upper_settlement else house.get("yaw_deg",0.0)))
		root.add_child(model)
		# The kit roof is a thin tile shell. Its underside must also cover the
		# rafters when a cliff approach sees the eaves from below.
		for roof_mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
			if not str(roof_mesh.get_path()).contains("Roof_RoundTiles"):
				continue
			for surface_index in roof_mesh.mesh.get_surface_count():
				var roof_material:=roof_mesh.get_active_material(surface_index) as StandardMaterial3D
				if roof_material!=null:
					var solid_roof:=roof_material.duplicate() as StandardMaterial3D
					solid_roof.cull_mode=BaseMaterial3D.CULL_DISABLED
					roof_mesh.set_surface_override_material(surface_index,solid_roof)
		var bounds: AABB = _building_prefabs.call("combined_aabb", model)
		# A complete foundation is essential here: the source prefab is assembled
		# wall-by-wall and the former 17 m ledge cut through its outer rooms.
		_box(model, "ContinuousStoneFloor", Vector3(bounds.get_center().x, -0.10, bounds.get_center().z),
			Vector3(bounds.size.x, 0.22, bounds.size.z), _materials["stone_light"], true)
		_cover_exclusions.append({"centre": model.global_position,
			"half": Vector2(bounds.size.x, bounds.size.z) * 0.5 + Vector2.ONE * 1.0,
			"rotation": model.global_rotation.y})
		# Reuse the prefab's authored wall boxes, including its open doorway.
		for collider: Dictionary in _building_prefabs.call("colliders", prefab):
			var body := StaticBody3D.new()
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = _vec3(collider.get("size", [1.0, 1.0, 1.0]))
			shape.shape = box
			shape.position = _vec3(collider.get("at", [0.0, 0.0, 0.0]))
			body.add_child(shape)
			model.add_child(body)
		_set_geometry_visibility(model, float(settlement.get("visibility_range_m", 850.0)))
		var doorway:=model.to_global(Vector3(1,0.18,4.1 if prefab=="cottage_a" else 3.1))
		var local_door:=root.to_local(doorway)
		var hub:=Vector3(0,0.18,-1)
		_path_ribbon(root,"WornHouseThreshold",local_door,hub,2.4,root.get_child_count()*13)
		var threshold:=MeshInstance3D.new()
		threshold.name="DoorstepWearPatch"
		var threshold_plane:=PlaneMesh.new()
		threshold_plane.size=Vector2(4.8,4.8)
		threshold.mesh=threshold_plane
		threshold.position=local_door
		threshold.material_override=ENVIRONMENT_MATERIALS.worn_ground(doorway,2.8)
		root.add_child(threshold)
	_build_settlement_yard(root)
	_build_settlement_precinct(root,watch)
	_path_ribbon(root,"WornArrivalToSharedYard",Vector3(0,0.18,-24),Vector3(0,0.18,-1),4.1,991)


func _plant_floor_pocket(parent: Node3D,at: Vector3,half: Vector2,seed_value: int,dry: bool) -> void:
	_cover_patches.append({"kind":"ellipse","centre":parent.to_global(at),"half":half,
		"seed":seed_value,"dry":dry})
	_place_local_prop(parent,"bush",at+Vector3(half.x*0.22,0,-half.y*0.18),1.1+0.16*(seed_value%3),seed_value%180)
	_place_local_prop(parent,"flowers",at+Vector3(-half.x*0.23,0,half.y*0.12),0.62,seed_value%90)
	_place_local_prop(parent,"rock_low",at+Vector3(half.x*0.4,-0.08,half.y*0.3),0.6,seed_value%120)


func _build_settlement_precinct(root: Node3D,watch: Vector3) -> void:
	# Connected inhabited edges, with the communal centre and all real door/
	# dialogue lanes left untouched. These sit on the existing terrace crown.
	var dry:=root.global_position.y>=700.0
	for side: float in [-1.0,1.0]:
		for i in 4:
			var edge:=Vector3(side*22.0,0.12,-20.0+i*10.0)
			_box(root,"TerraceRetainingCourse",edge+Vector3(0,-0.4,0),Vector3(1.1,0.9,9.6),_materials["masonry"],false)
			if i!=1:
				_place_local_prop(root,"fence",edge,1.12,90)
			if i%2==0:
				_plant_floor_pocket(root,edge+Vector3(-side*2.7,0,1.3),Vector2(2.5,4.5),713+i+int(side)*21,dry)
	for at: Vector3 in [Vector3(-14,0.14,-15),Vector3(14,0.14,-16),Vector3(-16,0.14,18),Vector3(2,0.14,22)]:
		_plant_floor_pocket(root,at,Vector2(3.2,3.8),int(at.x*7+at.z*11),dry)
	_path_ribbon(root,"WornWatchPrecinctConnection",Vector3(1,0.15,14),watch+Vector3(-6,0.15,-4),3.2,931)
	# Shared worn-ground shader gives the tower foot the same soil-and-turf
	# transition as the communal yard instead of an isolated raw platform.
	var apron:=MeshInstance3D.new()
	apron.name="WatchMaintenanceApron"
	var plane:=PlaneMesh.new()
	plane.size=Vector2(13,12)
	apron.mesh=plane
	apron.position=watch+Vector3(0,0.16,0)
	apron.material_override=ENVIRONMENT_MATERIALS.worn_ground(root.to_global(apron.position),7.0)
	root.add_child(apron)
	_place_local_prop(root,"workbench",watch+Vector3(-6,0.14,1.5),1.15,90)
	_place_local_prop(root,"crate",watch+Vector3(-6.2,0.14,3.2),0.75,18)


func _place_local_prop(parent: Node3D, asset: String, at: Vector3, height: float, yaw: float = 0.0) -> void:
	var packed := ROUTE_DETAIL_SCENES.get(asset) as PackedScene
	if packed == null:
		return
	var model := packed.instantiate() as Node3D
	var bounds_tool := BUILDING_PREFABS.new()
	var bounds: AABB = bounds_tool.combined_aabb(model)
	var scale_value := height / maxf(bounds.size.y, 0.01)
	var placement := Node3D.new()
	placement.name = asset.capitalize() + str(parent.get_child_count())
	placement.position = at
	placement.rotation.y = deg_to_rad(yaw)
	parent.add_child(placement)
	model.scale = Vector3.ONE * scale_value
	model.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * scale_value
	placement.add_child(model)
	if asset == "bush" or asset == "flowers":
		_apply_tree_palette(model, parent.get_child_count())
	_set_geometry_visibility(placement, 480.0)


func _build_settlement_yard(parent: Node3D) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(ENVIRONMENT_MATERIALS.worn_ground(parent.global_position+Vector3(0,0,-2),16.0))
	var centre := Vector3(0, 0.17, -2)
	for i in 32:
		var a := float(i) * TAU / 32.0
		var b := float(i + 1) * TAU / 32.0
		var p := centre + Vector3(cos(a) * (12.5 + sin(a * 5.0)), 0, sin(a) * (15.0 + cos(a * 3.0)))
		var q := centre + Vector3(cos(b) * (12.5 + sin(b * 5.0)), 0, sin(b) * (15.0 + cos(b * 3.0)))
		_add_surface_triangle(tool, centre, q, p)
	tool.generate_normals()
	var yard := MeshInstance3D.new()
	yard.name = "WornCommunalYard"
	yard.mesh = tool.commit()
	parent.add_child(yard)
	for prop: Dictionary in _visual_config.get("settlement_dressing", []):
		_place_local_prop(parent, str(prop["asset"]), _vec3(prop["at"]), float(prop["height"]), float(prop.get("yaw", 0)))
	for side: float in [-1.0, 1.0]:
		for i in 3:
			_place_local_prop(parent, "fence", Vector3(side * 21.0, 0.14, -13.0 + i * 4.0), 1.05, 90)
			_place_local_prop(parent, "flowers", Vector3(side * (17.0 + i * 1.3), 0.14, 13.0 + i * 1.5), 0.5 + i * 0.12, i * 41)
		_place_local_prop(parent, "bush", Vector3(side * 19.0, 0.14, 15.0), 1.25, side * 37)
		_cover_patches.append({"kind": "ellipse", "centre": parent.global_position + Vector3(side * 18.0, 0.14, 13.0),
			"half": Vector2(6.0, 7.0), "seed": int(parent.global_position.y) + int(side) * 11, "dry": false})
		for i in 2:
			_cover_patches.append({"kind": "ellipse", "centre": parent.global_position + Vector3(side * (9.0 + i * 7.0), 0.14, -26.0 + i * 7.0),
				"half": Vector2(4.7, 6.0), "seed": 541 + i + int(side) * 17, "dry": false})
		_place_local_prop(parent, "flowers", Vector3(side * 14.0, 0.14, -22.0), 0.65, side * 42)
		_place_local_prop(parent, "rock_low", Vector3(side * 15.2, 0.04, -21.0), 0.5, side * 71)
	if parent.global_position.y > 700.0:
		for i in 3:
			_cover_patches.append({"kind": "ellipse", "centre": parent.global_position + Vector3(20.0 + i * 5.0, 0.14, 4.0 + i * 6.0),
				"half": Vector2(4.5, 5.0), "seed": 842 + i * 13, "dry": false})
		_place_local_prop(parent, "flowers", Vector3(26, 0.14, 10), 0.75, 32)
		_place_local_prop(parent, "rock_low", Vector3(24, 0.04, 8), 0.8, 71)


func _build_realm_gate_crag(root: Node3D) -> void:
	# The gate is deliberately above the arrival road; carry that elevation with
	# one readable cliff tower so the reveal is a grounded destination, not a
	# black frame apparently floating in empty sky.
	_mesa(root, "GateFoundationCrag", Vector3(0.0, -20.0, 2.0),
		Vector3(44.0, 40.0, 42.0), _materials["cliff"], _materials["upland"], false, 211)
	_castle_piece(root, "AncientCarvedGateway", CASTLE_GATE, Vector3(0, 0, 2), Vector3(28, 27, 6), _materials["stone_light"])
	for side: float in [-1.0, 1.0]:
		_castle_piece(root, "GateWatchPillar", CASTLE_TOWER, Vector3(side * 12, 0, 2), Vector3(7, 33, 7), _materials["stone"])
	_box(root, "RealmKeyGlow", Vector3(0.0, 26.0, 1.7), Vector3(7.0, 0.45, 0.35), _materials["heart"], false)


func _build_three_bells(root: Node3D) -> void:
	for side: float in [-1.0, 1.0]:
		_box(root, "BellPier", Vector3(side * 12.0, 8.0, 0.0), Vector3(3.2, 16.0, 4.0), _materials["stone"], false)
		_box(root,"BellPierFoot",Vector3(side*12,0.8,0),Vector3(4.2,1.6,5.0),_materials["masonry"],false)
		_cylinder_between(root,"BellFrameKneeBrace",Vector3(side*11,12,0),Vector3(side*6.5,15.3,0),0.28,_materials["weathered_timber"])
	_box(root, "BellBeam", Vector3(0.0, 16.0, 0.0), Vector3(28.0, 2.0, 2.1), _materials["weathered_timber"], false)
	for yoke_x in [-12.0,-7.0,0.0,7.0,12.0]:
		_box(root,"BellBeamIronStrap",Vector3(yoke_x,16,0),Vector3(0.23,2.14,2.24),_materials["bronze"],false)
	for i in 3:
		var x := (float(i) - 1.0) * 7.0
		_cylinder(root, "BellRope%d" % i, Vector3(x, 12.9, 0.0), 0.08, 4.4, _materials["rope"])
		_box(root,"BellYoke%d"%i,Vector3(x,10.65,0),Vector3(1.45,0.3,0.45),_materials["weathered_timber"],false)
		_build_hollow_bell(root,Vector3(x,10.5,0),i)


func _build_hollow_bell(parent: Node3D,at: Vector3,index: int) -> void:
	var root:=Node3D.new()
	root.name="SkyBell%d"%index
	root.position=at
	parent.add_child(root)
	var profile: Array[Vector2]=[Vector2(0.26,0),Vector2(0.55,-0.22),Vector2(0.67,-0.75),Vector2(0.88,-1.45),Vector2(1.32,-1.85),Vector2(1.35,-2.0)]
	var bronze:=(_materials["bronze"] as StandardMaterial3D).duplicate() as StandardMaterial3D
	bronze.albedo_color=Color("#8f7950")
	bronze.metallic=0.65
	bronze.roughness=0.55
	bronze.cull_mode=BaseMaterial3D.CULL_DISABLED
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(bronze)
	for row in profile.size()-1:
		for column in 32:
			var a:=TAU*column/32.0
			var b:=TAU*(column+1)/32.0
			var p:=Vector3(cos(a)*profile[row].x,profile[row].y,sin(a)*profile[row].x)
			var q:=Vector3(cos(b)*profile[row].x,profile[row].y,sin(b)*profile[row].x)
			var r:=Vector3(cos(a)*profile[row+1].x,profile[row+1].y,sin(a)*profile[row+1].x)
			var s:=Vector3(cos(b)*profile[row+1].x,profile[row+1].y,sin(b)*profile[row+1].x)
			_add_surface_triangle(tool,p,q,r)
			_add_surface_triangle(tool,q,s,r)
	tool.generate_normals()
	var shell:=MeshInstance3D.new()
	shell.name="HollowFlaredBronzeShell"
	shell.mesh=tool.commit()
	root.add_child(shell)
	var rim:=MeshInstance3D.new()
	var lip:=TorusMesh.new()
	lip.inner_radius=1.21
	lip.outer_radius=1.42
	lip.rings=32
	lip.ring_segments=8
	rim.mesh=lip
	rim.material_override=bronze
	rim.position.y=-1.94
	root.add_child(rim)
	_cylinder(root,"SuspendedClapper",Vector3(0,-1.17,0),0.12,1.7,_materials["bronze"])
	_cylinder(root,"ClapperHead",Vector3(0,-1.99,0),0.27,0.30,bronze)


func _build_broken_arch(root: Node3D) -> void:
	_box(root, "WestArchPier", Vector3(-10.0, 10.0, 0.0), Vector3(5.0, 20.0, 6.0), _materials["stone"], false)
	_box(root, "EastArchPier", Vector3(10.0, 7.0, 0.0), Vector3(5.0, 14.0, 6.0), _materials["stone"], false)
	_box(root, "WestArchCrown", Vector3(-4.0, 20.0, 0.0), Vector3(10.0, 3.0, 6.0), _materials["stone_light"], false,
		Basis(Vector3.FORWARD, deg_to_rad(-8.0)))
	_box(root, "FallenArchCrown", Vector3(8.0, 2.0, 8.0), Vector3(12.0, 3.0, 5.0), _materials["stone_light"], false,
		Basis(Vector3.FORWARD, deg_to_rad(17.0)))


func _build_windscar_beacon(root: Node3D) -> void:
	_cylinder(root, "BeaconPlinth", Vector3(0.0, 2.0, 0.0), 8.0, 4.0, _materials["stone"])
	_cylinder(root, "BeaconTower", Vector3(0.0, 15.0, 0.0), 3.8, 26.0, _materials["stone_light"])
	_box(root, "BeaconCrossarm", Vector3(0.0, 25.0, 0.0), Vector3(18.0, 1.0, 1.4), _materials["wood"], false)
	_cylinder(root, "BeaconFire", Vector3(0.0, 30.0, 0.0), 1.8, 7.0, _materials["heart"])


func _build_flight_aerie(root: Node3D) -> void:
	# This is visual paving on the real y=610 approach, not a second unwalkable
	# 2.4m-high display plinth swallowing the mentor/player's lower bodies.
	_cylinder(root, "AerieDais", Vector3(0.0, 0.04, 0.0), 15.0, 0.16, _materials["masonry"])
	for i in 5:
		var angle := TAU * float(i) / 5.0 + 0.35
		var height := 12.0 + float(i % 3) * 4.0
		_cylinder(root, "AeriePerch%d" % i,
			Vector3(cos(angle) * 11.0, height * 0.5 + 0.25, sin(angle) * 8.0),
			0.38, height, _materials["weathered_timber"])
		var foot:=Vector3(cos(angle)*11.0,0.25,sin(angle)*8.0)
		_cylinder(root,"PerchStoneSocket",foot,0.9,0.7,_materials["masonry"])
		_box(root,"PerchRestArm",foot+Vector3.UP*(height-0.8),Vector3(3.8,0.24,0.65),_materials["weathered_timber"],false,Basis(Vector3.UP,angle))
		_cylinder_between(root,"PerchKneeBrace",foot+Vector3.UP*(height-2.6),foot+Vector3.UP*(height-0.8)+Vector3(cos(angle),0,-sin(angle))*1.6,0.12,_materials["weathered_timber"])
	_box(root, "LaunchStone", Vector3(0.0, 0.07, -13.0), Vector3(12.0, 0.14, 12.0), _materials["path"], false)


func _build_high_perches(root: Node3D) -> void:
	for i in 6:
		var angle := TAU * float(i) / 6.0 + 0.2
		var height := 16.0 + float(posmod(i * 7, 5)) * 5.0
		_cylinder(root, "RoostNeedle%d" % i,
			Vector3(cos(angle) * (8.0 + float(i % 2) * 5.0), height * 0.5,
				sin(angle) * (7.0 + float((i + 1) % 2) * 5.0)),
			1.8 + float(i % 2), height, _materials["stone"])
		_box(root, "PerchCap%d" % i,
			Vector3(cos(angle) * (8.0 + float(i % 2) * 5.0), height,
				sin(angle) * (7.0 + float((i + 1) % 2) * 5.0)),
			Vector3(8.0, 0.8, 4.0), _materials["wood"], false,
			Basis(Vector3.UP, angle))


func _build_observatory(root: Node3D) -> void:
	_cylinder(root, "ObservatoryTower", Vector3(0.0, 10.0, 0.0), 8.5, 20.0, _materials["stone"])
	var dome := MeshInstance3D.new()
	dome.name = "WindDome"
	dome.position = Vector3(0.0, 21.0, 0.0)
	var sphere := SphereMesh.new()
	sphere.radius = 8.8
	sphere.height = 10.0
	dome.mesh = sphere
	dome.scale = Vector3(1.0, 0.58, 1.0)
	dome.material_override = _materials["stone_light"]
	root.add_child(dome)
	_cylinder(root, "WeatherSpire", Vector3(0.0, 32.0, 0.0), 0.75, 16.0, _materials["tether"])
	_box(root, "WindVane", Vector3(0.0, 38.0, 0.0), Vector3(12.0, 0.6, 1.2), _materials["leaf_gold"], false)


func _build_waterward_overlook(root: Node3D) -> void:
	_box(root, "OverlookDeck", Vector3(0.0, 1.0, -6.0), Vector3(30.0, 2.0, 18.0), _materials["stone_light"], false)
	for side: float in [-1.0, 1.0]:
		_box(root, "WaterwardPillar", Vector3(side * 10.0, 10.0, 1.0), Vector3(3.0, 20.0, 3.0), _materials["stone"], false)
	_box(root, "WaterwardLintel", Vector3(0.0, 19.0, 1.0), Vector3(23.0, 2.5, 3.5), _materials["stone"], false)
	_box(root, "WaterwardGlow", Vector3(0.0, 16.0, 0.7), Vector3(8.0, 0.4, 0.3), _materials["heart"], false)


func _build_sky_shrine(root: Node3D) -> void:
	_cover_exclusions.append({"centre": root.global_position + Vector3(0, 0, -10), "half": Vector2(4.5, 9), "rotation": 0.0})
	for step in 3:
		var height := 0.34 * (step + 1)
		_box(root, "ShrineApproachStep", Vector3(0, height * 0.5, -12.4 + step * 0.8), Vector3(7.0, height, 1.0), _materials["masonry_trim"], true)
	_box(root, "Dais", Vector3(0.0, 0.65, 0.0), Vector3(26.0, 1.3, 20.0), _materials["masonry_trim"], true)
	for x in [-9.5, 9.5]:
		_box(root, "SkyPillar", Vector3(x, 10.0, 2.5), Vector3(2.2, 20.0, 2.2), _materials["masonry"], true)
		for band in [1.8, 6.5, 15.0, 18.2]:
			_box(root, "CarvedPillarCourse", Vector3(x, band, 2.5), Vector3(3.0, 0.7, 3.0), _materials["masonry_trim"], false)
		_box(root, "PillarFoot", Vector3(x, 2.0, 2.5), Vector3(4.3, 1.4, 4.3), _materials["masonry"], false)
	_box(root, "SkyLintel", Vector3(0.0, 19.0, 2.5), Vector3(23.0, 2.0, 2.5), _materials["masonry"], true)
	_castle_piece(root, "InnerSanctuaryArch", CASTLE_GATE, Vector3(0, 1.3, 3.7), Vector3(16, 14, 2.8), _materials["stone_light"])
	for i in 7:
		_box(root, "LintelWindCarving", Vector3(-7.2 + i * 2.4, 19.1, 1.0), Vector3(1.3, 0.45, 0.3), _materials["bronze"], false,
			Basis(Vector3.FORWARD, deg_to_rad(22.0 if i % 2 == 0 else -22.0)))
	for x in [-9.5, 9.5]:
		_castle_piece(root, "SanctuaryFinial", CASTLE_TOWER, Vector3(x, 20.0, 2.5), Vector3(3.2, 5.0, 3.2), _materials["stone"])
	var heart := MeshInstance3D.new()
	heart.name = "HeartSocketGlow"
	heart.position = Vector3(0.0, 8.5, 0.0)
	var crystal := SphereMesh.new()
	crystal.radius = 1.2
	crystal.height = 3.8
	crystal.radial_segments = 8
	crystal.rings = 4
	heart.mesh = crystal
	var gem_material := _emissive_material(Color("#318f91"), 0.25)
	gem_material.metallic = 0.45
	gem_material.roughness = 0.27
	heart.material_override = gem_material
	root.add_child(heart)
	for i in 2:
		var ring := MeshInstance3D.new()
		ring.name = "AncientWindArmature%d" % i
		var torus := TorusMesh.new()
		torus.inner_radius = 2.65
		torus.outer_radius = 2.88
		torus.rings = 32
		torus.ring_segments = 8
		ring.mesh = torus
		ring.material_override = _materials["bronze"]
		ring.position = Vector3(0, 8.5, 0)
		ring.rotation = Vector3(deg_to_rad(90), deg_to_rad(28.0 if i == 0 else -38.0), deg_to_rad(i * 35.0))
		root.add_child(ring)
	for side: float in [-1.0, 1.0]:
		_cylinder_between(root, "SuspensionArm", Vector3(side * 2.7, 8.5, 0), Vector3(side * 7.5, 11, 2.8), 0.18, _materials["bronze"])
		_place_local_prop(root, "rock_low", Vector3(side * 11.0, 1.3, -7.0), 0.8, side * 25)
		_place_local_prop(root, "flowers", Vector3(side * 11.4, 1.3, -6.0), 0.55, side * 50)
	_cylinder(root, "HeartstonePedestal", Vector3(0, 2.2, 0), 2.7, 1.8, _materials["masonry"])
	for side: float in [-1.0,1.0]:
		# The low retaining wings connect stair and sanctuary foundation. Their
		# planting is on the existing level shrine crown, outside the steps.
		for i in 3:
			_box(root,"ShrineRetainingWing",Vector3(side*(7.5+i*3.2),0.42,-13.0+i*1.8),
				Vector3(3.5,0.84,1.0),_materials["masonry"],false)
		_plant_floor_pocket(root,Vector3(side*11.0,0.12,-15.0),Vector2(5.2,3.2),831+int(side)*23,true)
		_plant_floor_pocket(root,Vector3(side*15.0,0.12,-3.0),Vector2(3.5,5.0),865+int(side)*17,true)
		_place_local_prop(root,"bench",Vector3(side*9.0,0.12,-18.0),0.95,0)


func _build_summit_stronghold(root: Node3D) -> void:
	# Two articulated wings and a high gate bridge replace the solid cuboid that
	# filled the whole final-approach frame. The open central throat is readable
	# from the road and gives the eventual pre-boss route a physical entrance.
	for side: float in [-1.0, 1.0]:
		_box(root, "SummitWing", Vector3(side * 13.5, 13.0, 0.0),
			Vector3(15.0, 26.0, 34.0), _materials["stone"], true).visible = false
		_castle_piece(root, "SummitMasonryWing", CASTLE_WALL, Vector3(side * 13.5, 0, 0),
			Vector3(15, 28, 34), _materials["stone"])
		_box(root, "WingButtress", Vector3(side * 22.0, 7.5, 8.0),
			Vector3(4.0, 15.0, 10.0), _materials["cliff_mid"], true)
	_box(root, "GateBridge", Vector3(0.0, 25.0, 0.0),
		Vector3(14.0, 7.0, 34.0), _materials["stone_light"], true).visible = false
	_castle_piece(root, "SummitGatehouse", CASTLE_GATE, Vector3(0, 0, -14),
		Vector3(27, 34, 7), _materials["stone_light"])
	_box(root, "UpperKeep", Vector3(0.0, 36.0, -3.0),
		Vector3(24.0, 15.0, 22.0), _materials["masonry"], true)
	for band in [29.0, 35.0, 42.0]:
		_box(root, "UpperKeepCornice", Vector3(0, band, -3), Vector3(25.0, 0.7, 23.0), _materials["masonry_trim"], false)
	_box(root, "GateThreshold", Vector3(0.0, 0.08, -19.0),
		Vector3(9.0, 0.16, 12.0), _materials["masonry_trim"], true)
	for corner in [Vector3(-24.0, 17.0, -20.0), Vector3(24.0, 17.0, -20.0), Vector3(-24.0, 17.0, 20.0), Vector3(24.0, 17.0, 20.0)]:
		_castle_piece(root, "SummitWatchtower", CASTLE_TOWER, corner - Vector3.UP * 17,
			Vector3(13, 39, 13), _materials["stone"])
		var pylon := TETHER_PYLON.instantiate() as Node3D
		var bounds_tool := BUILDING_PREFABS.new()
		var bounds: AABB = bounds_tool.combined_aabb(pylon)
		var scale_value := 6.5 / maxf(bounds.size.y, 0.01)
		pylon.scale = Vector3.ONE * scale_value
		pylon.position = corner + Vector3.UP * 22 - Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * scale_value
		root.add_child(pylon)
	for x in [-10.0, -3.3, 3.3, 10.0]:
		_box(root, "Crenellation", Vector3(x, 45.0, -3.0),
			Vector3(3.5, 3.5, 24.0), _materials["masonry"], false)
	for side: float in [-1.0, 1.0]:
		_hang_cloudreach_banner(root,Vector3(side*8.5,22.0,-17.3),Vector2(3.8,11.0),PI)
	var summit_pylon := TETHER_PYLON.instantiate() as Node3D
	summit_pylon.name = "OccupiedSummitPylon"
	var pylon_bounds_tool := BUILDING_PREFABS.new()
	var pylon_bounds: AABB = pylon_bounds_tool.combined_aabb(summit_pylon)
	var pylon_scale := 18.0 / maxf(pylon_bounds.size.y, 0.01)
	summit_pylon.scale = Vector3.ONE * pylon_scale
	summit_pylon.position = Vector3(0, 47.0, -3) - Vector3(pylon_bounds.get_center().x, pylon_bounds.position.y, pylon_bounds.get_center().z) * pylon_scale
	root.add_child(summit_pylon)
	_box(root, "TetherCrown", Vector3(0.0, 47.0, -3.0),
		Vector3(29.0, 2.2, 24.0), _materials["masonry_trim"], false)
	_develop_stronghold_spaces(root)


func _develop_stronghold_spaces(root: Node3D) -> void:
	_cover_exclusions.append({"centre": root.global_position + Vector3(0, 0, -25), "half": Vector2(9, 46), "rotation": 0.0})
	_cover_exclusions.append({"centre": root.global_position + Vector3(0, 0, 32), "half": Vector2(18, 24), "rotation": 0.0})
	var court_bounce := OmniLight3D.new()
	court_bounce.name = "CourtyardSkyBounce"
	court_bounce.position = Vector3(0, 8, 40)
	court_bounce.light_color = Color("#c9d4d9")
	court_bounce.light_energy = 2.0
	court_bounce.omni_range = 25.0
	root.add_child(court_bounce)
	for side: float in [-1.0, 1.0]:
		for z in [-20.0, 20.0]:
			for band in [2.0, 9.0, 21.0, 33.0]:
				_box(root, "TowerMasonryCourse", Vector3(side * 24.0, band, z), Vector3(14.0, 0.8, 14.0), _materials["masonry_trim"], false)
			_box(root, "TowerSplayedBase", Vector3(side * 24.0, 1.6, z), Vector3(16, 3.2, 16), _materials["masonry"], false)
		for z in [-23.8, 23.8]:
			_hang_cloudreach_banner(root,Vector3(side*15,17,z),Vector2(3.2,10),PI if z<0 else 0.0)
			_box(root, "BannerCrossbar", Vector3(side * 15, 22.2, z), Vector3(4, 0.35, 0.5), _materials["wood"], false)
		for step in 4:
			_box(root, "GateButtressCourse", Vector3(side * (8.7 + step * 0.25), 1.4 + step * 3, -19.0),
				Vector3(2.4 - step * 0.3, 2.8, 3.5), _materials["masonry_trim"], false)
		_castle_piece(root, "RearCourtyardArcade", CASTLE_GATE, Vector3(side * 12.5, 0, 22.0), Vector3(15, 12, 3.5), _materials["stone_light"])
		_place_local_prop(root, "crate", Vector3(side * 16.5, 0.15, 29), 1.1, side * 20)
		_place_local_prop(root, "barrel", Vector3(side * 18.0, 0.15, 31), 1.3, side * 40)
		_place_local_prop(root, "fence", Vector3(side * 20.0, 0.15, 36), 1.2, 90)
		var light := OmniLight3D.new()
		light.name = "CourtyardBrazierLight"
		light.position = Vector3(side * 10.0, 4.0, 25.0)
		light.light_color = Color("#ffc17a")
		light.light_energy = 3.0
		light.omni_range = 22.0
		root.add_child(light)
		_cylinder(root, "BrazierStand", Vector3(side * 10.0, 1.5, 25.0), 0.45, 3.0, _materials["bronze"])
		_cylinder(root, "BrazierCoals", Vector3(side * 10.0, 3.1, 25.0), 0.72, 0.3, _emissive_material(Color("#ed9a4c"), 1.5))
	var apparatus := RELAY_APPARATUS.instantiate() as Node3D
	var tool := BUILDING_PREFABS.new()
	var bounds: AABB = tool.combined_aabb(apparatus)
	var scale_value := 6.0 / maxf(bounds.size.y, 0.01)
	apparatus.scale = Vector3.ONE * scale_value
	apparatus.position = Vector3(-8, 0.15, 29) - Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * scale_value
	root.add_child(apparatus)
	for i in 7:
		_place_local_prop(root, "paving", Vector3(sin(i * 1.7) * 0.45, 0.16, -47.0 + i * 3.3), 0.16, i * 29)
	# Defensive/work edges lead from the approach to the gate rather than
	# leaving the facade at the end of an empty plane. Preserve the 18 m lane.
	for side: float in [-1.0,1.0]:
		for i in 4:
			var at:=Vector3(side*(15.0+i*0.8),0.0,-26.0-i*7.5)
			_box(root,"ApproachRetainingEdge",at+Vector3(0,0.45,0),Vector3(1.4,0.9,7.7),_materials["masonry"],false)
			if i%2==0:
				_plant_floor_pocket(root,at+Vector3(side*3.4,0.12,0),Vector2(3.0,5.5),941+i+int(side)*21,true)
		_place_local_prop(root,"wagon",Vector3(side*18,0.12,-34),2.2,side*7)
		_place_local_prop(root,"crate",Vector3(side*20,0.12,-38),1.05,side*28)
		_place_local_prop(root,"barrel",Vector3(side*21.3,0.12,-37),1.1,18)


func _build_wayfinder(root: Node3D) -> void:
	_cylinder(root, "AncientMarker", Vector3(0.0, 7.0, 0.0), 2.1, 14.0, _materials["stone_light"])
	_cylinder(root, "MarkerLight", Vector3(0.0, 15.0, 0.0), 0.8, 2.0, _materials["heart"])


func _hang_cloudreach_banner(parent: Node3D, at: Vector3, size: Vector2, yaw: float) -> void:
	var banner:=MeshInstance3D.new()
	banner.name="MarkedWindblownTetherBanner"
	var cloth:=PlaneMesh.new()
	cloth.orientation=PlaneMesh.FACE_Z
	cloth.size=size
	cloth.subdivide_width=6
	cloth.subdivide_depth=14
	banner.mesh=cloth
	banner.material_override=ENVIRONMENT_MATERIALS.banner(size,at.x*0.13+at.z*0.07)
	banner.position=at
	banner.rotation.y=yaw
	parent.add_child(banner)


func _castle_piece(parent: Node3D, label: String, mesh: Mesh, at: Vector3, size: Vector3, material: Material) -> void:
	var bounds := mesh.get_aabb()
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.material_override = _materials["masonry_trim"] if material == _materials["stone_light"] else _materials["masonry"]
	instance.scale = size / bounds.size
	instance.position = at - Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * instance.scale
	parent.add_child(instance)


func _place_player() -> void:
	var game := get_node_or_null(^"/root/Game")
	var pending := str(game.call("pending_entry_for", REALM_ID)) if game != null and game.has_method("pending_entry_for") else ""
	if pending == "" and game != null and game.has_method("apply_loaded_player_pose") and bool(game.call("apply_loaded_player_pose")):
		return
	var anchor := entry_anchor(pending)
	if anchor.is_empty():
		var points: Dictionary = _config.get("transition_points", {})
		var fallback: Variant = points.get("meadows_entry", {})
		anchor = (fallback as Dictionary).duplicate(true) if fallback is Dictionary else {}
	var spot := _vec3(anchor.get("position", [0.0, 5.0, 0.0]))
	var floor_y := ground_height_at(spot.x, spot.z)
	if not is_nan(floor_y):
		spot.y = floor_y + 0.15
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	var yaw := deg_to_rad(float(anchor.get("facing_yaw_deg", 0.0)))
	var model := _player.get_node_or_null(^"Model") as Node3D
	if model != null:
		model.rotation.y = yaw
	if _camera_rig != null:
		_camera_rig.set("yaw", yaw)
	if pending != "" and game != null and game.has_method("complete_realm_entry"):
		_settle_realm_arrival.call_deferred(game)


func _settle_realm_arrival(game: Node) -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	if is_instance_valid(game):
		game.call("complete_realm_entry", REALM_ID)


func _capture_mouse_if_free() -> void:
	var game := _game()
	if game != null and game.has_method("menu"):
		var menu: Object = game.call("menu")
		if menu != null and bool(menu.call("is_open")):
			return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _game() -> Node:
	return get_node_or_null(^"/root/Game")


func _segment_box(parent: Node, label: String, a: Vector3, b: Vector3, width: float, thickness: float, material: Material, collision: bool) -> Node3D:
	var length := a.distance_to(b)
	return _box(parent, label, a.lerp(b, 0.5) - _segment_basis(a, b).y * thickness * 0.5,
		Vector3(width, thickness, length), material, collision, _segment_basis(a, b))


func _segment_basis(a: Vector3, b: Vector3) -> Basis:
	var forward := (b - a).normalized()
	var right := Vector3.UP.cross(forward).normalized()
	if right.length_squared() < 0.001:
		right = Vector3.RIGHT
	var up := forward.cross(right).normalized()
	return Basis(right, up, forward)


func _box(parent: Node, label: String, centre: Vector3, size: Vector3, material: Material, collision: bool, basis: Basis = Basis.IDENTITY) -> Node3D:
	var root := Node3D.new()
	root.name = label
	root.position = centre
	root.basis = basis
	parent.add_child(root)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	root.add_child(mesh)
	if collision:
		var body := StaticBody3D.new()
		body.name = "Collision"
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		shape_node.shape = shape
		body.add_child(shape_node)
		root.add_child(body)
	return root


func _mesa(
		parent: Node,
		label: String,
		centre: Vector3,
		size: Vector3,
		side_material: Material,
		top_material: Material,
		collision: bool,
		seed_value: int,
		rugged_crown: bool = false
	) -> Node3D:
	var root := Node3D.new()
	root.name = label
	root.position = centre
	root.rotation.y = deg_to_rad(float(posmod(seed_value * 23, 36)) - 18.0)
	parent.add_child(root)

	# An irregular three-ring cliff profile replaces the early CylinderMesh
	# placeholder. The top retains a broad playable crown; the wall overhangs,
	# pinches and tapers independently so a long route reads as geology rather
	# than a row of identical hanging prisms.
	if label.contains("RockShoulder") and not collision and _overlaps_battle_yard(centre,size):
		return root # Keep a real clear yard/vista, not a noncolliding rock intruder.
	var sides := 48 + posmod(seed_value, 6)
	var eroded_crown := label == "CliffMass"
	var top_ring: Array[Vector3] = []
	var core_ring: Array[Vector3] = []
	var upper_ring: Array[Vector3] = []
	var lower_ring: Array[Vector3] = []
	var bottom_ring: Array[Vector3] = []
	for i in sides:
		var angle := TAU * float(i) / float(sides)
		var irregular := 0.87 + 0.10 * sin(angle * 3.0 + float(seed_value))
		irregular += 0.055 * cos(angle * 7.0 - float(seed_value) * 0.7)
		var top_point := Vector3(cos(angle) * size.x * 0.47 * irregular,
			size.y * 0.5, sin(angle) * size.z * 0.47 * irregular)
		if rugged_crown:
			top_point.y -= minf(size.y*0.12,13.0)*(0.8+0.4*sin(angle*3.0+seed_value))
		elif eroded_crown:
			top_point.y -= (0.52 + 0.48 * sin(angle * 3.0 + seed_value * 0.8)) * minf(size.y * 0.15, 48.0)
		core_ring.append(Vector3(cos(angle) * size.x * 0.32, size.y * 0.5,
			sin(angle) * size.z * 0.32))
		var upper_push := 1.04 + 0.18 * sin(angle * 4.0 + seed_value)
		var lower_push := 1.24 + 0.27 * cos(angle * 3.0 - seed_value * 0.7)
		# A constant Y per ring made every kilometre-scale face read as a clean
		# geological cutaway. Offset the strata independently around the perimeter
		# so the material transitions follow an eroded, rising/falling shelf line.
		# The playable crown stays level; only the visual wall profile changes.
		var upper_jitter := sin(angle * 3.0 + seed_value * 5) * minf(size.y * 0.045, 23.0)
		var lower_jitter := sin(angle * 4.0 + seed_value * 17) * minf(size.y * 0.038, 38.0)
		top_ring.append(top_point)
		upper_ring.append(Vector3(top_point.x * upper_push, top_point.y - size.y * 0.26 + upper_jitter,
			top_point.z * upper_push))
		lower_ring.append(Vector3(top_point.x * lower_push, top_point.y - size.y * 0.65 + lower_jitter,
			top_point.z * lower_push))
		bottom_ring.append(Vector3(top_point.x * (1.55 + 0.22 * sin(angle * 3.0 + seed_value)),
			-size.y * 0.5, top_point.z * (1.55 + 0.20 * cos(angle * 5.0 - seed_value))))

	var mesh := ArrayMesh.new()
	var top_tool := SurfaceTool.new()
	top_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	top_tool.set_material(top_material)
	var crown := Vector3(0.0, size.y * 0.5 + 0.03, 0.0)
	if rugged_crown:
		crown.y -= minf(size.y*0.09,9.0)
	for i in sides:
		var next := (i + 1) % sides
		if eroded_crown:
			_add_surface_triangle(top_tool, crown, core_ring[next] + Vector3.UP * 0.03, core_ring[i] + Vector3.UP * 0.03)
			_add_surface_triangle(top_tool, core_ring[i] + Vector3.UP * 0.03, core_ring[next] + Vector3.UP * 0.03, top_ring[i] + Vector3.UP * 0.03)
			_add_surface_triangle(top_tool, top_ring[i] + Vector3.UP * 0.03, core_ring[next] + Vector3.UP * 0.03, top_ring[next] + Vector3.UP * 0.03)
		else:
			_add_surface_triangle(top_tool, crown, top_ring[next] + Vector3.UP * 0.03,
				top_ring[i] + Vector3.UP * 0.03)
	top_tool.generate_normals()
	top_tool.commit(mesh)

	var upper_tool := SurfaceTool.new()
	upper_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	upper_tool.set_material(_materials["cliff_high"] if side_material != _materials["cliff_shadow"] else side_material)
	for i in sides:
		var next := (i + 1) % sides
		_add_geological_face(upper_tool, top_ring[i], top_ring[next], upper_ring[i], upper_ring[next],
			Vector3(top_ring[i].x, 0, top_ring[i].z).normalized(), Vector3(top_ring[next].x, 0, top_ring[next].z).normalized(), minf(size.x * 0.055, 15.0))
	var middle_tool := upper_tool
	for i in sides:
		var next := (i + 1) % sides
		_add_geological_face(middle_tool, upper_ring[i], upper_ring[next], lower_ring[i], lower_ring[next],
			Vector3(top_ring[i].x, 0, top_ring[i].z).normalized(), Vector3(top_ring[next].x, 0, top_ring[next].z).normalized(), minf(size.x * 0.07, 25.0))
	var lower_tool := upper_tool
	for i in sides:
		var next := (i + 1) % sides
		_add_geological_face(lower_tool, lower_ring[i], lower_ring[next], bottom_ring[i], bottom_ring[next],
			Vector3(top_ring[i].x, 0, top_ring[i].z).normalized(), Vector3(top_ring[next].x, 0, top_ring[next].z).normalized(), minf(size.x * 0.09, 35.0))
	lower_tool.generate_normals()
	lower_tool.commit(mesh)

	var mass := MeshInstance3D.new()
	mass.name = "StratifiedCliffBody"
	mass.mesh = mesh
	mass.visibility_range_end = 2600.0
	mass.visibility_range_end_margin = 220.0
	root.add_child(mass)
	if rugged_crown:
		_build_crown_outcrops(root,size,seed_value)
	if label == "CliffMass" or label == "LandmarkLedge" or label.contains("RockShoulder"):
		_build_embedded_rock_shelves(root, size, seed_value)

	if collision:
		var points := PackedVector3Array()
		for point: Vector3 in top_ring:
			points.append(point)
		for point: Vector3 in bottom_ring:
			points.append(point)
		var body := StaticBody3D.new()
		body.name = "Collision"
		var shape_node := CollisionShape3D.new()
		if eroded_crown:
			shape_node.shape = mesh.create_trimesh_shape()
		else:
			var shape := ConvexPolygonShape3D.new()
			shape.points = points
			shape_node.shape = shape
		body.add_child(shape_node)
		root.add_child(body)
	return root


func _overlaps_battle_yard(at: Vector3, size: Vector3) -> bool:
	if _yard_visual_config.is_empty():
		_yard_visual_config=_read_json("res://data/config/cloudreach_scene_runtime.json")
	for yard: Dictionary in _yard_visual_config.get("battle_yards",[]):
		var centre:=_vec3(yard.road_position)+_vec3(yard.outward).normalized()*25.0
		if absf(at.x-centre.x)<size.x*0.65+18.0 and absf(at.z-centre.z)<size.z*0.65+18.0 and at.y+size.y*0.5>centre.y-4.0 and at.y-size.y*0.5<centre.y+10.0:
			return true
	return false


func _build_crown_outcrops(parent: Node3D, size: Vector3, seed_value: int) -> void:
	# Overlapping installed rock silhouettes replace the giant fan-shaped bare
	# shoulders. The lower procedural mass remains their rooted geological base.
	for i in 5:
		var angle:=i*2.399+seed_value*0.71
		var width:=clampf(size.x*(0.27+0.05*(i%2)),9.0,39.0)
		var height:=width*(0.7+0.23*(i%3))
		var rock:=NATURE_ROCKS[posmod(seed_value+i,3)].instantiate() as Node3D
		var bounds: AABB=BUILDING_PREFABS.new().combined_aabb(rock)
		rock.scale=Vector3(width,height,width*0.82)/bounds.size
		rock.rotation.y=angle
		rock.position=Vector3(cos(angle)*size.x*0.19,size.y*0.5-height*0.7-6.0,sin(angle)*size.z*0.19)-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*rock.scale
		parent.add_child(rock)
		for mesh: MeshInstance3D in rock.find_children("*","MeshInstance3D",true,false):
			mesh.material_override=_materials["cliff"]
		_set_geometry_visibility(rock,1500.0)


func _build_embedded_rock_shelves(parent: Node3D, size: Vector3, seed_value: int) -> void:
	# Production-family outcrops break the generated cliff skin into recognizable
	# eroded blocks. Their inner halves are buried into the supporting mass.
	for i in 9:
		var angle := float(i) * TAU / 9.0 + float(seed_value) * 0.23
		var depth := 8.0 + float(i % 3) * minf(22.0, size.y * 0.10)
		var width := clampf(size.x * 0.24, 14.0, 52.0)
		var height := width * (0.35 + float(i % 2) * 0.14)
		var rock := NATURE_ROCKS[posmod(i + seed_value, NATURE_ROCKS.size())].instantiate() as Node3D
		var bounds_tool := BUILDING_PREFABS.new()
		var bounds: AABB = bounds_tool.combined_aabb(rock)
		rock.scale = Vector3(width, height, width * 0.70) / bounds.size
		rock.rotation.y = angle + 0.35
		rock.position = Vector3(cos(angle) * size.x * 0.40, size.y * 0.5 - depth - height * 0.5, sin(angle) * size.z * 0.40)
		rock.name = "EmbeddedCliffOutcrop%d" % i
		parent.add_child(rock)
		for mesh: MeshInstance3D in rock.find_children("*", "MeshInstance3D", true, false):
			mesh.material_override = _materials["cliff"]
		_set_geometry_visibility(rock, 1250.0)
	# Sparse vegetated shelves give the cliffs a human-readable scale and show
	# that the crowns and outcrops belong to the same living upland landscape.
	for i in 3:
		var angle := float(i) * 2.399 + seed_value * 0.23
		var shelf_width := clampf(size.x * 0.22, 16.0, 44.0)
		var shelf_height := minf(18.0, size.y * 0.12)
		var shelf_top := size.y * 0.5 - 12.0 - i * 19.0
		var shelf := Vector3(cos(angle) * size.x * 0.44, shelf_top, sin(angle) * size.z * 0.44)
		_mesa(parent, "VegetatedGeologicalShelf%d" % i, shelf - Vector3.UP * shelf_height * 0.5,
			Vector3(shelf_width, shelf_height, shelf_width * 0.78), _materials["cliff"], _materials["upland"], true, seed_value + 131 + i)
		_cover_patches.append({"kind":"ellipse","centre":parent.to_global(shelf),
			"half":Vector2(shelf_width*0.30,shelf_width*0.23),"seed":seed_value*31+i,"dry":false})
		var tree := NATURE_TREES[posmod(i + seed_value, NATURE_TREES.size())].instantiate() as Node3D
		tree.position = shelf - Vector3.UP * 0.10
		tree.scale = Vector3.ONE * (0.92 + i * 0.16)
		_apply_tree_palette(tree, seed_value + i)
		parent.add_child(tree)
		_set_geometry_visibility(tree, 1050.0)


func _cylinder(parent: Node, label: String, centre: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.position = centre
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius * 1.08
	cylinder.height = height
	mesh.mesh = cylinder
	mesh.material_override = material
	parent.add_child(mesh)
	return mesh


func _cylinder_between(parent: Node, label: String, a: Vector3, b: Vector3, radius: float, material: Material) -> void:
	var delta := b - a
	if delta.length_squared() < 0.001:
		return
	var node := _cylinder(parent, label, a.lerp(b, 0.5), radius, delta.length(), material)
	var up := delta.normalized()
	var right := up.cross(Vector3.FORWARD).normalized()
	if right.length_squared() < 0.001:
		right = Vector3.RIGHT
	var forward := right.cross(up).normalized()
	node.basis = Basis(right, up, forward)


func _material(colour: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = roughness
	return material


func _textured_material(raw: Variant, fallback_tint: Color) -> StandardMaterial3D:
	var spec: Dictionary = raw as Dictionary if raw is Dictionary else {}
	var material := _material(Color(str(spec.get("tint", fallback_tint.to_html()))), 0.96)
	var albedo_path := str(spec.get("albedo", ""))
	var normal_path := str(spec.get("normal", ""))
	var albedo := load(albedo_path) as Texture2D if albedo_path != "" else null
	var normal := load(normal_path) as Texture2D if normal_path != "" else null
	if albedo != null:
		material.albedo_texture = albedo
	if normal != null:
		material.normal_enabled = true
		material.normal_texture = normal
		material.normal_scale = float(spec.get("normal_depth", 0.3))
	var uv_scale := float(spec.get("uv_scale", 0.2))
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_triplanar_sharpness = 6.0
	material.uv1_scale = Vector3.ONE * uv_scale
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return material


func _surface_tint(raw: Dictionary, tint: String) -> Dictionary:
	var result := raw.duplicate(true)
	result["tint"] = tint
	return result


func _emissive_material(colour: Color, energy: float) -> StandardMaterial3D:
	var material := _material(colour, 0.48)
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = energy
	return material


func _wind_veil_material() -> StandardMaterial3D:
	var material := _emissive_material(Color(0.33, 0.78, 0.84, 0.24), 0.55)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color.a = 0.24
	return material


func _cloud_material() -> StandardMaterial3D:
	var material := _emissive_material(Color(0.67, 0.77, 0.82, 1.0), 0.18)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _vec3(raw: Variant) -> Vector3:
	if raw is Array and (raw as Array).size() >= 3:
		return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	return Vector3.ZERO


func _safe_name(raw: String) -> String:
	var words := raw.replace("-", "_").split("_", false)
	var result := ""
	for word: String in words:
		result += word.capitalize().replace(" ", "")
	return result if result != "" else "CloudreachNode"
