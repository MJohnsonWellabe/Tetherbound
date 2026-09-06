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
const DROPPED_ITEM_SPAWNER := preload("res://scripts/world/dropped_item_spawner.gd")
const TRADE_OFFER := preload("res://scripts/ui/trade_offer.gd")
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
const AVIARY := preload("res://scripts/world/cloudreach_aviary.gd")
const AVIARY_CONFIG_PATH := "res://data/config/cloudreach_aviary.json"

## D101. `$Player` is an instance of `scenes/player/local_rig.tscn` — this
## process's one local rig, in the `local_player` group — and `$CameraRig` is
## its camera, authored as a root-level sibling because `camera_rig.gd` sets
## `top_level = true` and follows by code. Remote peers' trainers stand under
## `Spawned/Trainers` and are reachable from neither path. `local_rig()` and
## `local_camera_rig()` below are the public door.
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
var _all_route_lines: Array[Dictionary] = []
var _all_pad_points: Array[Dictionary] = []
var _all_crown_reference_lines: Array[Dictionary] = []
var _built_pad_keys: Dictionary = {}
const SURFACE_CELL_M := 128.0


## D101 deliverable 5 — the one door onto this process's local rig and its
## camera. Same contract as `playground_world.gd::local_rig()`.
func local_rig() -> CharacterBody3D:
	return _player


func local_camera_rig() -> Node3D:
	return _camera_rig


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
	# D107, lane 3.E. The two nodes item trading needs standing in every
	# process before anybody presses anything: the spawner that draws a
	# committed `item_dropped` op as a stack on the ground, and the offer
	# transport, whose node path has to be identical on both peers or its RPCs
	# do not resolve at all. Both are idempotent.
	DROPPED_ITEM_SPAWNER.attach(self, REALM_ID)
	TRADE_OFFER.attach(get_node_or_null(^"/root/Game"))

	_config = _read_json(CONFIG_PATH)
	_visual_config = _read_json(VISUAL_CONFIG_PATH)
	var look := get_node_or_null(^"WorldLook")
	if look != null:
		var local_look: Dictionary = (look.get("_config") as Dictionary).duplicate(true)
		var sky_profile: Dictionary = _visual_config.get("sky_profile", {})
		(local_look.get("sky", {}) as Dictionary).merge(sky_profile, true)
		merge_sky_profile_into_times(local_look.get("times", {}), sky_profile)
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


## Lay this realm's sky profile over every time-of-day preset in `art.json`'s
## `times` block. `times` carries `_`-prefixed comment strings beside the preset
## dictionaries (`world_look.gd::times_available()` skips them the same way), and
## a typed `for preset: Dictionary in ... .values()` loop over that block throws
## on the first string and aborts the whole calling function -- which, from
## `_ready()`, left the entire Cloudreach world unbuilt on `main` (found by the
## Stage B host-cost spike, `ralph/reports/MP-0D-SPIKE-HOSTCOST-0905/`).
## Mutates `times` in place; returns how many presets were merged.
static func merge_sky_profile_into_times(times: Variant, sky_profile: Dictionary) -> int:
	if not times is Dictionary:
		return 0
	var merged := 0
	for key in (times as Dictionary).keys():
		if str(key).begins_with("_"):
			continue
		var preset: Variant = (times as Dictionary)[key]
		if not preset is Dictionary:
			continue
		if not (preset as Dictionary).has("sky"):
			(preset as Dictionary)["sky"] = {}
		((preset as Dictionary)["sky"] as Dictionary).merge(sky_profile, true)
		merged += 1
	return merged


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
	# CLIFF-ART-0906: every uniform of cloudreach_cliff.gdshader is TUNABLE
	# from `visual.geology` (data/config/cloudreach_visual.json). The
	# defaults below are the shipped tan-hoodoo look the blind judges read
	# as off-board ("banded tan hoodoos vs the board's grey-green granite");
	# the config carries the candidate palettes so a look can be A/B'd by
	# data alone. Textures are paths; colours are "#rrggbb"; floats as-is.
	var geo_cfg: Dictionary = _visual_config.get("geology", {})
	var rock_albedo := str(geo_cfg.get("albedo", "res://assets/environment/terrain/Rock030_Color.jpg"))
	var rock_normal := str(geo_cfg.get("normal", "res://assets/environment/terrain/Rock030_NormalGL.jpg"))
	geology.set_shader_parameter("rock_texture", load(rock_albedo))
	geology.set_shader_parameter("rock_normal", load(rock_normal))
	for colour_key: String in ["stone_light", "stone_dark", "strata_ochre_tint", "ledge_moss_tint"]:
		if geo_cfg.has(colour_key):
			var c := Color(str(geo_cfg[colour_key]))
			geology.set_shader_parameter(colour_key, Vector3(c.r, c.g, c.b))
	for float_key: String in ["texture_scale", "strata_period_m", "strata_strength", "strata_ochre_strength",
			"ledge_moss_strength", "ledge_lighten", "ledge_normal_threshold", "crevice_strength", "crevice_scale"]:
		if geo_cfg.has(float_key):
			geology.set_shader_parameter(float_key, float(geo_cfg[float_key]))
	for key: String in ["cliff", "cliff_high", "cliff_mid", "cliff_deep"]:
		_materials[key] = geology
	var trail := ShaderMaterial.new()
	trail.shader = TRAIL_SHADER
	trail.set_shader_parameter("grass_texture",preload("res://assets/environment/terrain/stylised/meadow_grass_Color.png"))
	trail.set_shader_parameter("dirt_texture", load(str(surface.get("path", {}).get("albedo", "res://assets/environment/terrain/stylised/dirt_path_Color.png"))))
	_materials["trail"] = trail
	ENVIRONMENT_MATERIALS.turf_parameters(trail,false)
	# Dusty tan rather than pumpkin (blind verdict round 1, defect 13).
	trail.set_shader_parameter("tint",Color("#9a8c72"))
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
		var summit_region := str(spec.get("id", "")) == "summit_final_stronghold"
		var region_mass := _mesa(node, "CliffMass", centre, size, _materials["cliff"],
			_materials["upland_dry"] if int(spec.get("order", 0)) >= 5 else _materials["upland"],
			not summit_region, int(spec.get("order", 0)))
		if summit_region:
			# The eroded outer ring falls as much as 48 m below the y=1160 crown.
			# Its former whole-mass trimesh therefore crossed the authored final
			# road at a 48-degree face around t=.465 and stopped an ordinary held
			# stick. Keep that tall geology as the summit silhouette, while the
			# authored road, loop, landing caps and arena retain the real edge/fall
			# contract. This thin inset support closes only the intended join from
			# the road's y=1160 landing to the arena approach; it creates no route
			# around the ascent and has no tall geological side to intercept it.
			var crown := _segment_box(node, "SummitWalkableCrown",
				Vector3(100.0, 1160.0, 5350.0), Vector3(100.0, 1160.0, 5376.0),
				12.0, 0.42, _materials["upland_dry"], true)
			var crown_visual := crown.get_child(0) as MeshInstance3D
			if crown_visual != null:
				crown_visual.visible = false
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
		apply_stone_palette(rock)
		rock.name = "BeddedRock%d" % i
		rock.position = at
		rock.rotation.y = angle
		rock.scale = Vector3.ONE * lerpf(float(nature.get("rock_scale_min", 0.85)),
			float(nature.get("rock_scale_max", 1.75)), float(posmod(i * 5 + order, 9)) / 8.0)
		parent.add_child(rock)
		_set_geometry_visibility(rock, float(nature.get("rock_visibility_range_m", 820.0)))


## Every ground route's own polyline, gathered before any shoulder is built so
## a shoulder vertex can be tested against every *other* route's actual road
## (see `_walkable_height`) instead of a per-segment "near this hub" guess.
## Replaces the earlier fork/hub-apron
## heuristic entirely (CAUSEWAY-HUB-0906): that guess had to fully disable an
## entire segment's shoulder collision near a detected sharp fork, which
## over-excluded far more of the shoulder than the crossing road actually
## covered, leaving real holes. Per-vertex clipping only drops the exact
## vertices that sit on or near another route's own road, wherever that
## happens along the network -- an ordinary crossing needs no special
## detection at all.
func _collect_all_route_lines() -> void:
	# The ground-truth road network every walkable crown and shoulder conforms
	# to (R2, CLOUDREACH-GROUND-0906). It is the REAL ribbon/deck geometry, not
	# the authored polyline: `_build_routes` shortens every ribbon to the pad's
	# cap edge (`_landing_join`) and leaves the cap itself flat, so the surface a
	# walker actually stands on is `pad -> join` flat at pad height, then
	# `join -> join` on a steeper straight than centre-to-centre. Easing a crown
	# or shoulder toward the centre-to-centre polyline instead left it 0.5-2 m
	# under the ribbon at every climbing pad rim (measured by the ground-truth
	# probe: 661 of 819 mismatches sat on pad crowns), which is the "walking
	# half in the ground" the owner reported. Bridge decks are joined the same
	# way `_build_bridges` joins them (0.75 fraction) and count as routes.
	_all_route_lines.clear()
	_all_pad_points.clear()
	var landmass: Dictionary = _visual_config.get("landmass", {})
	for raw: Variant in _config.get("routes", []):
		if not raw is Dictionary:
			continue
		var spec := raw as Dictionary
		if str(spec.get("traversal_mode", "ground")) != "ground":
			continue
		var route_id := str(spec.get("id", "Route"))
		var width := float(spec.get("width_m", 7.5))
		var collision_width := minf(width, float(landmass.get("path_collision_width_m", 7.0)))
		var half_width := collision_width * 0.5
		var landing_size := maxf(float(landmass.get("landing_size_m", 16.0)), collision_width * 2.25)
		var cap_half := landing_size * 0.41
		var flat_radius := landing_size * float(landmass.get("landing_flat_fraction", 0.82))
		var points: Array[Vector3] = []
		for point: Variant in spec.get("polyline", []):
			points.append(_vec3(point))
		for i in points.size() - 1:
			for section: Dictionary in _ground_sections_for_segment(route_id, points[i], points[i + 1]):
				var section_a: Vector3 = section["a"]
				var section_b: Vector3 = section["b"]
				if section_a.is_equal_approx(points[i]):
					section_a = _landing_join(points[i], points[i + 1], cap_half)
					_append_route_line(route_id, points[i], section_a, half_width)
				if section_b.is_equal_approx(points[i + 1]):
					section_b = _landing_join(points[i + 1], points[i], cap_half)
					_append_route_line(route_id, section_b, points[i + 1], half_width)
				_append_route_line(route_id, section_a, section_b, half_width)
		for pad: Vector3 in points:
			if not _bridge_interior_point(route_id, pad):
				_all_pad_points.append({"position": pad, "flat_radius": flat_radius,
					"cap_radius": _pad_cap_radius(pad, cap_half)})
	for raw: Variant in _config.get("bridges", []):
		if not raw is Dictionary:
			continue
		var bridge := raw as Dictionary
		var profile: Array = bridge.get("deck_profile", bridge.get("endpoints", []))
		if profile.size() < 2:
			continue
		var cap_half := float(landmass.get("landing_size_m", 16.0)) * 0.41
		var deck_half_width := float(bridge.get("width_m", 3.2)) * 0.5
		var deck_id := "bridge:%s" % str(bridge.get("id", "Bridge"))
		var stone_bridge := str(bridge.get("type", "")).contains("stone")
		for i in profile.size() - 1:
			var a := _vec3(profile[i])
			var b := _vec3(profile[i + 1])
			if i == 0:
				a = _landing_join(a, b, cap_half, 0.75)
			if i == profile.size() - 2:
				b = _landing_join(b, a, cap_half, 0.75)
			# Matches `_build_bridge_section`'s deck lift for stone paving.
			var lift := _segment_basis(a, b).y * (0.2 if stone_bridge else 0.0)
			_append_route_line(deck_id, a + lift, b + lift, deck_half_width)
	# Landmark ledges are flat crowns too (see `_build_landmarks`): a shoulder
	# running onto one conforms to it exactly as to a landing pad.
	for raw: Variant in _config.get("landmarks", []):
		if not raw is Dictionary:
			continue
		var spec := raw as Dictionary
		var landmark_id := str(spec.get("id", ""))
		var at := _vec3(spec.get("position", []))
		if landmark_id == "waterward_overlook":
			# Its two route-aligned hidden crown strips (see `_build_landmarks`)
			# are the floor here; the landing pad crown and shoulders conform
			# to them exactly as to a road.
			_append_route_line("crown:" + landmark_id, at + Vector3(-8.0, -2.4, -28.0), at, 16.0)
			_append_route_line("crown:" + landmark_id, at + Vector3(27.7, 3.35, 4.3), at, 13.0)
		if str(spec.get("category", "")) == "settlement":
			# `SettlementWalkableTerrace` (48x48, flat at the landmark height)
			# is the floor; shoulders running onto it rise to meet it.
			_append_route_line("crown:" + landmark_id, at + Vector3(-24.0, 0.0, 0.0),
				at + Vector3(24.0, 0.0, 0.0), 24.0)
			continue
		var ledge_size := Vector3(46.0, 72.0, 44.0)
		if landmark_id == "sky_shrine_heartstone":
			ledge_size = Vector3(132.0, at.y + 210.0, 126.0)
		var ledge_y := -0.08 if landmark_id == "old_wind_observatory" else 0.10
		if landmark_id == "old_wind_observatory":
			# `ObservatoryWalkableCrown` (38x36, flat at the landmark height) is
			# the floor on top of this ledge; register it as a wide reference
			# surface so the ledge crown and shoulders sit flush under it.
			_append_route_line("crown:" + landmark_id, at + Vector3(-19.0, 0.0, 0.0),
				at + Vector3(19.0, 0.0, 0.0), 18.0)
		_all_pad_points.append({
			"position": Vector3(at.x, at.y + ledge_y, at.z),
			"flat_radius": minf(ledge_size.x, ledge_size.z) * 0.47,
			"cap_radius": _landmark_cap_radius(landmark_id),
		})
	_all_crown_reference_lines = _all_route_lines


## A landing pad's flat cap radius -- zero on the waterward overlook, whose
## hidden crown strips slope straight through the pad centre (a flat cap
## there stood 0.2-0.8 m under the strip the walker is actually on).
func _pad_cap_radius(pad: Vector3, default_cap: float) -> float:
	for raw: Variant in _config.get("landmarks", []):
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == "waterward_overlook" \
				and _vec3((raw as Dictionary).get("position", [])).is_equal_approx(pad):
			return 0.0
	return default_cap


## The radius inside which a landmark ledge's crown stays flat at its authored
## height: the half-extent of its hidden walkable-crown box where one exists
## (`ObservatoryWalkableCrown`, 38x36), else the ordinary landing cap.
func _landmark_cap_radius(landmark_id: String) -> float:
	if landmark_id == "old_wind_observatory":
		return 18.0
	if landmark_id == "waterward_overlook":
		return 0.0
	return float(_visual_config.get("landmass", {}).get("landing_size_m", 16.0)) * 0.41


func _append_route_line(route_id: String, a: Vector3, b: Vector3, half_width: float) -> void:
	if Vector2(b.x - a.x, b.z - a.z).length_squared() < 0.01:
		return
	_all_route_lines.append({
		"route_id": route_id,
		"a": a,
		"b": b,
		"half_width": half_width,
		"min_x": minf(a.x, b.x), "max_x": maxf(a.x, b.x),
		"min_z": minf(a.z, b.z), "max_z": maxf(a.z, b.z),
	})


## Widest lateral influence any road/deck line has on a walkable vertex:
## pinned inside half_width + 1 m, eased back to natural over the next 6 m.
const LINE_PIN_MARGIN_M := 1.0
const LINE_EASE_M := 6.0
const PAD_EASE_M := 6.0


## The nearest point (XZ) on any road ribbon or bridge deck line and that
## line's walking-surface height there. `lines` is normally
## `_all_route_lines`; callers with a spatially culled subset pass it instead.
func _nearest_route_line(world_point: Vector3, lines: Array[Dictionary]) -> Dictionary:
	var best_d := INF
	var best_h := 0.0
	var best_half_width := 0.0
	# Among the lines whose own width covers the point, the HIGHEST is the
	# collider the walker actually stands on (a climbing ribbon leaving a
	# settlement terrace, the overlook's east strip over its west strip near
	# their shared centre); it wins outright over the "most inside" ranking.
	var pinned := false
	var pinned_h := -INF
	var pinned_d := 0.0
	var pinned_half_width := 0.0
	for line: Dictionary in lines:
		var reach: float = float(line["half_width"]) + LINE_PIN_MARGIN_M + LINE_EASE_M
		if world_point.x < float(line["min_x"]) - reach or world_point.x > float(line["max_x"]) + reach \
				or world_point.z < float(line["min_z"]) - reach or world_point.z > float(line["max_z"]) + reach:
			continue
		var a: Vector3 = line["a"]
		var b: Vector3 = line["b"]
		var flat := Vector2(b.x - a.x, b.z - a.z)
		var len2 := flat.length_squared()
		var t_raw := 0.0
		if len2 > 0.0001:
			t_raw = ((world_point.x - a.x) * flat.x + (world_point.z - a.z) * flat.y) / len2
		var t := clampf(t_raw, 0.0, 1.0)
		var proj := Vector2(a.x + flat.x * t, a.z + flat.y * t)
		var d := Vector2(world_point.x, world_point.z).distance_to(proj)
		# Rank by how far INSIDE a line's own width the point sits, not by raw
		# centreline distance: a wide hidden crown box (the observatory's 38 m
		# square, the overlook's sloped strips) must win over a narrow ribbon
		# that happens to run closer to its centre, because that box is the
		# collider actually on top there.
		var h := lerpf(a.y, b.y, t)
		var half_width := float(line["half_width"])
		# A line COVERS a point only within its own length (a box, not a
		# capsule): with rounded ends the flat pad->join stub kept "covering"
		# the road up to 4.5 m past the join at pad height, and as the highest
		# covering line it held the summit ledge's crown flat over the
		# descending ribbon there -- a 0.7 m step the summit walk stuck on
		# (round 8). Past an end the line still eases (below), never pins.
		var overrun := 0.5 / maxf(sqrt(len2), 0.5)
		var within_length := t_raw >= -overrun and t_raw <= 1.0 + overrun
		if within_length and d < half_width + LINE_PIN_MARGIN_M:
			if h > pinned_h:
				pinned = true
				pinned_h = h
				pinned_d = d
				pinned_half_width = half_width
		if d - half_width < best_d - best_half_width or is_inf(best_d):
			best_d = d
			best_h = h
			best_half_width = half_width
	if pinned:
		return {"distance": pinned_d, "height": pinned_h, "half_width": pinned_half_width}
	return {"distance": best_d, "height": best_h, "half_width": best_half_width}


## R2: a walkable vertex within reach of a road ribbon / bridge deck takes
## that line's height (plus `lift`) inside half_width + 1 m and eases back to
## `natural_y` over the next 6 m, so along any road corridor the surface IS the
## road and a walker never meets a step at a crown rim or shoulder edge.
## `down_only` (crowns) never raises the vertex above its authored height.
func _line_eased_height(world_point: Vector3, natural_y: float, lines: Array[Dictionary],
		down_only: bool, lift: float) -> float:
	var nearest := _nearest_route_line(world_point, lines)
	var d: float = nearest["distance"]
	if is_inf(d):
		return natural_y
	var reach: float = float(nearest["half_width"]) + LINE_PIN_MARGIN_M
	var target: float = float(nearest["height"]) + lift
	var eased := natural_y
	if d < reach:
		eased = target
	elif d < reach + LINE_EASE_M:
		eased = lerpf(target, natural_y, (d - reach) / LINE_EASE_M)
	return minf(natural_y, eased) if down_only else eased


## The rendered (and collided -- R1) height of a flat pad/landmark crown at a
## world XZ point: authored height inside the cap radius, then eased down to
## meet any road/deck within reach (R2). `_mesa` emits its crown rings from
## exactly this function and shoulders conform to it, so the three agree.
## OWNER 2026-09-06: "that completely flat green ground shouldn't exist".
##
## Only a `CliffMass` mesa got an eroded crown (`_mesa`'s `eroded_crown`);
## every other crown emitted a single fan from one apex vertex to its rim,
## which is a mathematically flat disc. That is the owner's flat green ground
## and the same root as the blind judge's "a perfectly flat, edge-lit green
## plane" (CLOUDREACH-GROUND-0906 JUDGE-after2, defect 3).
##
## The relief goes in the HEIGHT MODEL rather than in the mesh emitters,
## because `_mesa` builds its visible crown AND its collision copy from
## `_crown_height_at`, and every shoulder conforms to the same function
## (`_walkable_height`). One change moves all three together; a change in the
## emitters would move the render away from the collider and reopen exactly
## the hole/sink class OP-0905-24/25 closed.
##
## It is suppressed to nothing wherever something authored owns the ground:
##
##   * inside a settlement clearance -- buildings sit at an authored y;
##   * approaching the rim, so the crown still meets its cliff edge cleanly
##     and the eroded shelf line below it is unchanged;
##   * near any road or deck line -- and that one is free, because the caller
##     hands this to `_line_eased_height`, which lerps to the road's own
##     height within `reach + LINE_EASE_M` and so flattens the relief back out
##     under the player's feet wherever a route actually runs.
##
## Amplitude scales with the crown's own radius: a 30 m landing pad reads as a
## pad, and only the wide crowns that fill a frame get metres of roll.
func _crown_relief_at(pad: Dictionary, world_point: Vector3,
		lines: Array[Dictionary] = [] as Array[Dictionary]) -> float:
	var cfg: Dictionary = _crown_relief_config()
	if cfg.is_empty():
		return 0.0
	var centre: Vector3 = pad["position"]
	var flat_radius := maxf(float(pad.get("flat_radius", 0.0)), 1.0)
	if flat_radius < float(cfg.get("min_radius_m", 40.0)):
		return 0.0
	var r := Vector2(world_point.x - centre.x, world_point.z - centre.z).length()
	var rim_fade := clampf(float(cfg.get("rim_fade_fraction", 0.78)), 0.0, 0.99)
	if r >= flat_radius:
		return 0.0
	var edge := 1.0
	if r > flat_radius * rim_fade:
		edge = 1.0 - smoothstep(0.0, 1.0, (r - flat_radius * rim_fade) / maxf(flat_radius * (1.0 - rim_fade), 0.01))
	if edge <= 0.0:
		return 0.0
	if bool(cfg.get("respect_settlements", true)) and _inside_settlement_clearance(world_point):
		return 0.0
	# Roads and bridge decks own their own height. `_crown_height_at`'s caller
	# flattens the relief back out near them for free through
	# `_line_eased_height`, but `_emit_mesa_top` has no such easing, so the
	# suppression lives here where both paths get it. Without it a region
	# crown would roll straight through an authored road ribbon, which is the
	# hole/sink class OP-0905-24/25 closed.
	if not lines.is_empty():
		var nearest := _nearest_route_line(world_point, lines)
		var d: float = nearest["distance"]
		if not is_inf(d):
			var reach: float = float(nearest["half_width"]) + LINE_PIN_MARGIN_M
			if d < reach:
				return 0.0
			if d < reach + LINE_EASE_M:
				edge *= smoothstep(0.0, 1.0, (d - reach) / LINE_EASE_M)
	var reference := maxf(float(cfg.get("reference_radius_m", 150.0)), 1.0)
	var amplitude := float(cfg.get("amplitude_m", 4.5)) * minf(1.0, flat_radius / reference)
	var long_m := maxf(float(cfg.get("long_wavelength_m", 74.0)), 1.0)
	var short_m := maxf(float(cfg.get("short_wavelength_m", 31.0)), 1.0)
	var short_mix := clampf(float(cfg.get("short_amplitude_fraction", 0.34)), 0.0, 1.0)
	# Deterministic and continuous across mesa boundaries: sampled in WORLD xz,
	# not in the pad's local frame, so two crowns that touch do not step where
	# they meet.
	var long_wave := sin(world_point.x / long_m) * cos(world_point.z / long_m * 1.13)
	var short_wave := sin(world_point.z / short_m * 1.07 + 2.1) * cos(world_point.x / short_m + 0.7)
	return amplitude * edge * lerpf(long_wave, short_wave, short_mix)


func _crown_relief_config() -> Dictionary:
	var cfg: Dictionary = _visual_config.get("crown_relief", {})
	if not bool(cfg.get("enabled", true)):
		return {}
	return cfg


func _crown_height_at(pad: Dictionary, world_point: Vector3, lines: Array[Dictionary]) -> float:
	var centre: Vector3 = pad["position"]
	var r := Vector2(world_point.x - centre.x, world_point.z - centre.z).length()
	var natural := centre.y + _crown_relief_at(pad, world_point, lines)
	if r <= float(pad["cap_radius"]):
		return natural
	# Up as well as down: a road that leaves the pad climbing stands above the
	# flat disc past the cap, and if the crown stayed flat the walker would be
	# carried on the invisible ribbon box 0.3-0.7 m above the visible crown
	# (probe, round 1: ~350 pad samples). The crown is the road's surface
	# wherever the road runs over it.
	return _line_eased_height(world_point, natural, lines, false, 0.0)


func _nearest_pad(world_point: Vector3, pads: Array[Dictionary]) -> Dictionary:
	var best: Dictionary = {}
	var best_inside := INF
	for pad: Dictionary in pads:
		var centre: Vector3 = pad["position"]
		var inside := Vector2(world_point.x - centre.x, world_point.z - centre.z).length() \
			- float(pad["flat_radius"])
		if inside < best_inside:
			best_inside = inside
			best = pad
	return best


## The shared clamp for every shoulder (ridge) vertex: first toward any road
## or deck line, then onto any pad/landmark crown whose disc it lies on (it
## takes the crown's own top height there) or eases to over the 6 m past the
## crown rim. Shoulder, crown and ribbon thereby meet within centimetres
## wherever they overlap, instead of stepping.
func _walkable_height(world_point: Vector3, natural_y: float, lines: Array[Dictionary],
		pads: Array[Dictionary]) -> float:
	var eased := _line_eased_height(world_point, natural_y, lines, false, 0.03)
	var pad := _nearest_pad(world_point, pads)
	if pad.is_empty():
		return eased
	var centre: Vector3 = pad["position"]
	var r := Vector2(world_point.x - centre.x, world_point.z - centre.z).length()
	var flat_radius: float = pad["flat_radius"]
	if r >= flat_radius + PAD_EASE_M:
		return eased
	# 0.01 above the crown's rendered surface height, i.e. 2 cm UNDER its
	# +0.03 top: a shoulder pinned exactly onto the crown z-fought with it as
	# light dry-turf bands across a green pad wherever a dry route's shoulder
	# crossed a green route's crown (05-upper-cloudreach-cliffhold, scratch
	# capture after round 2). The crown is the drawn surface inside its disc;
	# the collider difference is 2 cm.
	var crown_top := _crown_height_at(pad, world_point, lines) + 0.01
	if r <= flat_radius:
		return crown_top
	return lerpf(crown_top, eased, (r - flat_radius) / PAD_EASE_M)


## Height of this route's own ribbon/cap surface under a point on its line.
func _own_route_height(route_id: String, world_point: Vector3, fallback_y: float) -> float:
	var best_d := INF
	var best_h := fallback_y
	for line: Dictionary in _all_route_lines:
		if str(line["route_id"]) != route_id:
			continue
		var a: Vector3 = line["a"]
		var b: Vector3 = line["b"]
		var flat := Vector2(b.x - a.x, b.z - a.z)
		var len2 := flat.length_squared()
		var t := 0.0
		if len2 > 0.0001:
			t = clampf(((world_point.x - a.x) * flat.x + (world_point.z - a.z) * flat.y) / len2, 0.0, 1.0)
		var d := Vector2(world_point.x, world_point.z).distance_to(Vector2(a.x + flat.x * t, a.z + flat.y * t))
		if d < best_d:
			best_d = d
			best_h = lerpf(a.y, b.y, t)
	return best_h


## The lines/pads that can influence any vertex inside an XZ rectangle --
## a per-ridge cull so the per-vertex clamp stays cheap.
func _lines_near(min_x: float, max_x: float, min_z: float, max_z: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for line: Dictionary in _all_route_lines:
		var reach: float = float(line["half_width"]) + LINE_PIN_MARGIN_M + LINE_EASE_M
		if float(line["max_x"]) + reach < min_x or float(line["min_x"]) - reach > max_x \
				or float(line["max_z"]) + reach < min_z or float(line["min_z"]) - reach > max_z:
			continue
		out.append(line)
	return out


func _pads_near(min_x: float, max_x: float, min_z: float, max_z: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for pad: Dictionary in _all_pad_points:
		var centre: Vector3 = pad["position"]
		var reach: float = float(pad["flat_radius"]) + PAD_EASE_M
		if centre.x + reach < min_x or centre.x - reach > max_x \
				or centre.z + reach < min_z or centre.z - reach > max_z:
			continue
		out.append(pad)
	return out


## True when a point lies inside any road/deck line's or pad's influence zone
## (used to densify the shoulder mesh only where the clamp can bend it).
func _near_walkable_feature(world_point: Vector3, lines: Array[Dictionary],
		pads: Array[Dictionary], margin: float) -> bool:
	var nearest := _nearest_route_line(world_point, lines)
	if not is_inf(float(nearest["distance"])) \
			and float(nearest["distance"]) < float(nearest["half_width"]) + LINE_PIN_MARGIN_M + LINE_EASE_M + margin:
		return true
	for pad: Dictionary in pads:
		var centre: Vector3 = pad["position"]
		if Vector2(world_point.x - centre.x, world_point.z - centre.z).length() \
				< float(pad["flat_radius"]) + PAD_EASE_M + margin:
			return true
	return false


func _build_routes() -> void:
	var root := Node3D.new()
	root.name = "AuthoredRoutes"
	add_child(root)
	_collect_all_route_lines()
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
			# A pad shared by two routes (every route junction) is built ONCE:
			# two coincident crowns at the same height z-fought as alternating
			# light/dark wedges in the rendered frames (05-upper-cloudreach-
			# cliffhold, where windscar_counterweight_pass's green turf met
			# upper_plateau_circuit's dry turf on the same disc).
			var pad_key := "%.1f,%.1f" % [pad.x, pad.z]
			if _built_pad_keys.has(pad_key):
				continue
			_built_pad_keys[pad_key] = true
			var landing_size := maxf(float(landmass.get("landing_size_m", 16.0)),
				collision_width * 2.25)
			# Ledge collision matches its own rendered top exactly (see `_mesa`),
			# so the visible mesa is the real footprint instead of a
			# silhouette-only shell floating over a much smaller flat cap.
			# Flattened (no radius jitter) out to `landing_flat_fraction` of
			# landing_size -- comfortably past every authored approach's join
			# point -- so a bridge or ramp reaching the pad from any angle
			# always finds solid, level crown instead of occasionally clipping
			# a jittered dip in the mesa's outer rim (CAUSEWAY-HUB-0906). This
			# also means every pad, including a bridge's own endpoint, now
			# collides on its own crown rather than relying solely on the cap
			# box below.
			var landing_flat_radius := landing_size \
				* float(landmass.get("landing_flat_fraction", 0.82))
			# A bridge's own deck-endpoint pad USED to keep mesa collision
			# disabled entirely, relying on its flat `LedgeCap%d` box (below)
			# alone -- the ring of crown between that small box and the
			# mesa's own (much larger) flat radius was bare, uncollidable air
			# (CLOUDREACH-CROWN-0906 ground truth: 93 of 98 holes network-wide
			# sat exactly there). The deck's collision height there is an
			# independently authored point on the deck profile, so a residual
			# few centimetres to a few tens of centimetres of mismatch between
			# it and this pad's own crown is ordinary -- but R2 now clips this
			# crown's own height toward that SAME deck (`_mesa`'s
			# `flat_top_radius_m` apron, via `_crown_height_at`, which
			# treats bridge decks as routes for this taper), so the mismatch
			# the disabled collision was working around is closed at its
			# source. Always collide the crown now, everywhere, closing the
			# ring; the LedgeCap box stays (`pad - 0.44`, always below the
			# crown's own `pad + 0.03`) so it can never poke back above it.
			_mesa(root, "%s_Ledge%d" % [_safe_name(str(spec.get("id", "Route"))), i],
			pad - Vector3.UP * 22.0, Vector3(landing_size * 1.5, 44.0, landing_size * 1.5),
				_materials["cliff"], landing_top, true,
				i * 19 + absi(str(spec.get("id", "Route")).hash()), false, landing_flat_radius,
				_pad_cap_radius(pad, landing_size * 0.41))
			# A shallow walkable cap under the crown's flat centre. It is a DISC
			# of the cap radius (the same radius the crown stays flat inside and
			# every ribbon reaches at pad height via `_landing_join`), held
			# 0.05 m under the crown, so it can never stand above the crown
			# anywhere -- the former 13 m square's corners reached 9.3 m out,
			# past the join, and stood a real step above the still-climbing
			# ribbon on every diagonal approach (summit road, probe-confirmed).
			# Collision only: the disc sits wholly under the (now everywhere
			# collidable) crown, so drawing it can only z-fight with it.
			_disc(root, "%s_LedgeCap%d" % [_safe_name(str(spec.get("id", "Route"))), i],
				pad - Vector3.UP * 0.44, landing_size * 0.41 - 0.05, 0.84, landing_top, true).get_child(0).visible = false
			_add_landing_nature(root, points, i, pad, landing_size,
				i * 43 + absi(str(spec.get("id", "Route")).hash()))
			_cover_patches.append({"kind":"ellipse","centre":pad,"half":Vector2.ONE*landing_size*0.40,
				"inner_clear_fraction":0.38,"seed":i*137+absi(str(spec.id).hash()),"dry":false})
			# The mesa's crown vertex sits at local y = size.y*0.5 + 0.03, i.e.
			# pad.y + 0.03 world -- match that here so ground_height_at() (used
			# by spawns/arrivals) doesn't disagree with the real, solid surface.
			_surfaces.append({"kind": "rect", "centre": Vector2(pad.x, pad.z),
				"half": Vector2.ONE * landing_size * 0.41, "height": pad.y + 0.03})
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
				var collision_ribbon := _segment_box(root, "%sGround%d" % [route_label, section_index], section_a,
					section_b, collision_width, 0.72, landing_top, true)
				# The broad geological crown now reaches the real walkable elevation.
				# Retain this forgiving controller collision verbatim, but do not draw
				# its box sides as a raised, ruler-straight road embankment.
				var collision_visual := collision_ribbon.get_child(0) as MeshInstance3D
				if collision_visual != null:
					collision_visual.visible = false
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
	var route_id := str(spec.get("id", "Route"))
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
			# Every shoulder collides (see `_route_ridge`): its walkable top
			# is clamped per vertex onto any road ribbon, bridge deck or
			# pad/landmark crown within reach (`_walkable_height`), rather than
			# an entire segment near a detected "hub" going collision-free.
			_route_ridge(shoulder_root, "Ridge%03d" % serial, a, b, half_width,
				segment_index + int(spec.get("order", 0)) * 17 + serial,
				_materials["upland_dry"] if route_is_dry else _materials["upland"], landmass,
				route_id)
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
					"surface_offset_y": 0.025,
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
		half_width: float, seed_value: int, top_material: Material, config: Dictionary,
		self_route_id: String = "") -> void:
	var flat := Vector3(b.x - a.x, 0.0, b.z - a.z)
	if flat.length_squared() < 0.01:
		return
	var forward := flat.normalized()
	var right := Vector3.UP.cross(forward).normalized()
	var spacing := float(config.get("route_station_spacing_m", 48.0))
	var station_count := clampi(int(ceilf(flat.length() / maxf(spacing, 6.0))) + 1, 3, 48)
	# Every road/deck line and pad/landmark crown that can bend this ridge's
	# walkable top (R2), culled once per ridge so the per-vertex clamp is cheap.
	var reach := half_width * 1.2 + 12.0
	var lines := _lines_near(minf(a.x, b.x) - reach, maxf(a.x, b.x) + reach,
		minf(a.z, b.z) - reach, maxf(a.z, b.z) + reach)
	var pads := _pads_near(minf(a.x, b.x) - reach, maxf(a.x, b.x) + reach,
		minf(a.z, b.z) - reach, maxf(a.z, b.z) + reach)
	var left_top: Array[Vector3] = []
	var right_top: Array[Vector3] = []
	var left_track: Array[Vector3] = []
	var right_track: Array[Vector3] = []
	var centres: Array[Vector3] = []
	var left_upper: Array[Vector3] = []
	var right_upper: Array[Vector3] = []
	var left_shelf_lip: Array[Vector3] = []
	var right_shelf_lip: Array[Vector3] = []
	var left_lower: Array[Vector3] = []
	var right_lower: Array[Vector3] = []
	var left_bottom: Array[Vector3] = []
	var right_bottom: Array[Vector3] = []
	for i in station_count:
		var t := float(i) / float(station_count - 1)
		var centre := a.lerp(b, t)
		# The crest follows this route's OWN ribbon/cap surface (flat inside the
		# pad cap, then the join-to-join slope -- `_collect_all_route_lines`),
		# not the centre-to-centre polyline the ribbon is shortened from; the
		# two differ by up to slope x cap radius right where a road meets its
		# pad, which is exactly where walkers were stepping/sinking.
		if self_route_id != "":
			centre.y = _own_route_height(self_route_id, centre, centre.y)
		centres.append(centre)
		var irregular := 0.84 + 0.18 * sin(float(i * 13 + seed_value * 7))
		irregular += 0.08 * cos(float(i * 5 + seed_value * 3))
		# Every segment starts and ends at a landing pad (or a landmark), whose
		# own crown is flat. Taper the outward flare and the vertical drop back
		# to the flat track over the first/last couple of stations so the
		# shoulder grows out of the pad/landmark surface instead of stepping
		# away from it. 0.53 (the track's own half-width fraction) is still >=
		# the half_width*0.5 minimum this collider is required to cover.
		var edge_taper := smoothstep(0.0, 4.0, float(mini(i, station_count - 1 - i)))
		var width_here := half_width * lerpf(0.53, irregular, edge_taper)
		var left := centre - right * width_here
		var right_edge := centre + right * width_here
		left_track.append(centre - right * half_width * 0.53)
		right_track.append(centre + right * half_width * 0.53)
		left.y -= (4.0 + 9.0 * (1.0 + sin(float(i) * 1.71 + seed_value))) * edge_taper
		right_edge.y -= (4.0 + 9.0 * (1.0 + cos(float(i) * 2.13 + seed_value))) * edge_taper
		var depth_mix := 0.5 + 0.5 * sin(float(i * 11 + seed_value * 17))
		var depth := maxf(centre.y - float(config.get("geology_base_y", -210.0)),
			lerpf(float(config.get("route_cliff_depth_min_m", 36.0)),
			float(config.get("route_cliff_depth_max_m", 92.0)), depth_mix))
		left_top.append(left)
		right_top.append(right_edge)
		# A ridge is a mountain cross-section, not a retaining wall. Broad,
		# uneven shoulders step into talus below the narrow traversable crest.
		var upper_push := 1.65 + 0.75 * sin(float(i) * 1.37 + seed_value * 0.73)
		var shelf_push := upper_push + 0.72 + 0.24 * sin(float(i) * 1.11 + seed_value)
		# Recess the next wall behind a pronounced bed lip. The former outward
		# flare made the entire face one continuous slab despite its texture.
		var lower_push := 2.10 + 0.58 * cos(float(i) * 1.83 + seed_value * 0.39)
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
		left_shelf_lip.append(centre + (left - centre) * shelf_push - Vector3.UP * (shelf_depth + 2.2))
		right_shelf_lip.append(centre + (right_edge - centre) * shelf_push - Vector3.UP * (shelf_depth * 0.85 + 2.2))
		left_lower.append(centre + (left - centre) * lower_push - Vector3.UP * talus_depth)
		right_lower.append(centre + (right_edge - centre) * lower_push - Vector3.UP * (talus_depth * 0.9))
		var foot_width := maxf(half_width * 4.0, depth * (0.40 + depth_mix * 0.20))
		left_bottom.append(Vector3(centre.x, centre.y - depth, centre.z) - right * foot_width)
		right_bottom.append(Vector3(centre.x, centre.y - depth * 0.94, centre.z) + right * foot_width * 1.15)

	# R1 + R2 (CLOUDREACH-GROUND-0906): the walkable top -- flat crest track
	# plus the slopes out to the true outer edge -- is ONE grid of rows, seven
	# vertices wide (outer edge, track edge, half track, crest, ...), every
	# vertex passed through `_walkable_height` so it conforms to any road
	# ribbon, bridge deck or pad/landmark crown within reach. A station
	# interval that lies inside such a feature's influence zone is subdivided
	# to ~4 m rows: the clamp is only ever evaluated at vertices, and with
	# 16 m stations the straight interpolation between a pinned station inside
	# a pad disc and a free one outside carried the road's rise back over the
	# flat crown (probe: 0.2-1.3 m over most pad crowns). The rendered top
	# mesh, the wall's upper attachment edge and the collision copy all come
	# from these same rows, so they can never drift apart.
	var rows: Array = []
	var row_station: Array[float] = []
	for i in station_count - 1:
		var pieces := 1
		var margin := half_width * 0.6
		if _near_walkable_feature(centres[i], lines, pads, margin) \
				or _near_walkable_feature(centres[i + 1], lines, pads, margin):
			pieces = clampi(int(ceilf(centres[i].distance_to(centres[i + 1]) / 4.0)), 1, 12)
		for piece in pieces:
			row_station.append(float(i) + float(piece) / float(pieces))
	row_station.append(float(station_count - 1))
	for station_t: float in row_station:
		var i := mini(int(floor(station_t)), station_count - 2)
		var f := station_t - float(i)
		var row: Array[Vector3] = []
		var lt := left_top[i].lerp(left_top[i + 1], f)
		var ltr := left_track[i].lerp(left_track[i + 1], f)
		var c := centres[i].lerp(centres[i + 1], f)
		var rtr := right_track[i].lerp(right_track[i + 1], f)
		var rt := right_top[i].lerp(right_top[i + 1], f)
		for raw: Vector3 in [lt, ltr, ltr.lerp(c, 0.5), c, rtr.lerp(c, 0.5), rtr, rt]:
			row.append(Vector3(raw.x, _walkable_height(raw, raw.y, lines, pads), raw.z))
		rows.append(row)
	# Walls hang from the rows' outer vertices (no separate station-only edge).
	var wall_left_top: Array[Vector3] = []
	var wall_right_top: Array[Vector3] = []
	for row_index in rows.size():
		var row: Array[Vector3] = rows[row_index]
		wall_left_top.append(row[0])
		wall_right_top.append(row[6])

	var mesh := ArrayMesh.new()
	var top_tool := SurfaceTool.new()
	top_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	top_tool.set_material(top_material)
	_emit_shoulder_top(top_tool, rows)
	top_tool.generate_normals()
	top_tool.commit(mesh)

	var upper_tool := SurfaceTool.new()
	upper_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	upper_tool.set_material(_materials["cliff_high"])
	# The first wall band attaches to every top row (so the walkable top and
	# the cliff face stay stitched where the top was densified/clamped); its
	# lower edge is interpolated on the station-spaced upper ring.
	for row_index in rows.size() - 1:
		var s0 := row_station[row_index]
		var s1 := row_station[row_index + 1]
		var i0 := mini(int(floor(s0)), station_count - 2)
		var i1 := mini(int(floor(s1)), station_count - 2)
		var lu0 := left_upper[i0].lerp(left_upper[i0 + 1], s0 - float(i0))
		var lu1 := left_upper[i1].lerp(left_upper[i1 + 1], s1 - float(i1))
		var ru0 := right_upper[i0].lerp(right_upper[i0 + 1], s0 - float(i0))
		var ru1 := right_upper[i1].lerp(right_upper[i1 + 1], s1 - float(i1))
		_add_geological_face(upper_tool, wall_left_top[row_index + 1], wall_left_top[row_index], lu1, lu0, -right, -right, 5.0)
		_add_geological_face(upper_tool, wall_right_top[row_index], wall_right_top[row_index + 1], ru0, ru1, right, right, 5.0)
	for i in station_count - 1:
		# Wide, shallow rock planes catch light above a recessed wall. They are
		# intermediate cliff structure, not tiny dressing scattered on the face.
		_add_geological_face(upper_tool, left_upper[i + 1], left_upper[i], left_shelf_lip[i + 1], left_shelf_lip[i], -right, -right, 2.0)
		_add_geological_face(upper_tool, right_upper[i], right_upper[i + 1], right_shelf_lip[i], right_shelf_lip[i + 1], right, right, 2.0)
	# All cliff bands now share one geological material; submit one surface.
	var middle_tool := upper_tool
	for i in station_count - 1:
		_add_geological_face(middle_tool, left_shelf_lip[i + 1], left_shelf_lip[i], left_lower[i + 1], left_lower[i], -right, -right, 9.0)
		_add_geological_face(middle_tool, right_shelf_lip[i], right_shelf_lip[i + 1], right_lower[i], right_lower[i + 1], right, right, 9.0)
	var deep_tool := upper_tool
	for i in station_count - 1:
		_add_geological_face(deep_tool, left_lower[i + 1], left_lower[i], left_bottom[i + 1], left_bottom[i], -right, -right, 15.0)
		_add_geological_face(deep_tool, right_lower[i], right_lower[i + 1], right_bottom[i], right_bottom[i + 1], right, right, 15.0)
	# End faces prevent the ribbon's first/last station reading as a sliced box.
	var first_row: Array[Vector3] = rows[0]
	var last_row: Array[Vector3] = rows[rows.size() - 1]
	var last := station_count - 1
	_add_surface_triangle(deep_tool, first_row[0], first_row[6], left_bottom[0])
	_add_surface_triangle(deep_tool, left_bottom[0], first_row[6], right_bottom[0])
	_add_surface_triangle(deep_tool, last_row[0], left_bottom[last], last_row[6])
	_add_surface_triangle(deep_tool, left_bottom[last], right_bottom[last], last_row[6])
	deep_tool.generate_normals()
	deep_tool.commit(mesh)

	var ridge := MeshInstance3D.new()
	ridge.name = label
	ridge.mesh = mesh
	ridge.visibility_range_end = 1900.0
	ridge.visibility_range_end_margin = 160.0
	parent.add_child(ridge)

	# The cliff-shoulder rock formation flanking the road (out to half_width)
	# used to be visual-only: grass is planted on it, so it reads as walkable
	# ground, but stepping onto it fell straight through. Its trimesh collider
	# is built from the SAME rows as the visible top (R1), so the collider can
	# never float above or sink below what the player sees; the crest sits on
	# the route's own ribbon height, matching the narrower `Ground%d` road
	# ribbon collision where the two overlap.
	var collision_mesh := ArrayMesh.new()
	var collision_tool := SurfaceTool.new()
	collision_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_emit_shoulder_top(collision_tool, rows)
	collision_tool.commit(collision_mesh)
	var body := StaticBody3D.new()
	body.name = "Collision"
	var shape_node := CollisionShape3D.new()
	shape_node.shape = collision_mesh.create_trimesh_shape()
	body.add_child(shape_node)
	ridge.add_child(body)


## The ridge's crest and shoulders as one quad grid: `rows` is a list of
## seven-vertex cross-sections (outer left edge ... crest ... outer right
## edge). Shared by the visible top mesh and its collision copy so the two can
## never drift apart.
func _emit_shoulder_top(tool: SurfaceTool, rows: Array) -> void:
	for row_index in rows.size() - 1:
		var row_a: Array[Vector3] = rows[row_index]
		var row_b: Array[Vector3] = rows[row_index + 1]
		for column in row_a.size() - 1:
			_add_surface_triangle(tool, row_a[column], row_b[column], row_a[column + 1])
			_add_surface_triangle(tool, row_a[column + 1], row_b[column], row_b[column + 1])


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
	var stations := clampi(int(ceilf(flat.length() / 1.25)) + 1, 5, 420)
	var left: Array[Vector3] = []
	var right_edge: Array[Vector3] = []
	for i in stations:
		var t := float(i) / float(stations - 1)
		var envelope := sin(PI * t)
		var wander := sin(t * TAU * 1.35 + float(seed_value % 29)) * width * 0.18 * envelope
		wander += sin(t * TAU * 3.1 + float(seed_value % 11)) * width * 0.08 * envelope
		var half_here := width * (0.43 + 0.08 * sin(t * TAU * 2.4 + float(seed_value % 17)))
		half_here += width * 0.03 * sin(t * TAU * 4.0 + seed_value)
		# Bury the full-width surface at each end and let it emerge while its soil
		# mask feathers in. Collapsing width made an icon-like arrowhead; a buried
		# irregular lobe has no transverse or triangular silhouette to catch light.
		var endpoint_distance:=minf(t,1.0-t)*flat.length()
		var endpoint_blend:=smoothstep(0.0,2.8,endpoint_distance)
		var lift:=lerpf(-0.14,0.06,endpoint_blend)
		var centre := a.lerp(b, t) + right * wander + up * lift
		left.append(centre - right * half_here)
		right_edge.append(centre + right * half_here)
	var mesh := ArrayMesh.new()
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(_materials["trail_dry"] if minf(parent.to_global(a).y,parent.to_global(b).y)>=700.0 else _materials["trail"])
	for i in stations - 1:
		var t0:=float(i)/float(stations-1)
		var t1:=float(i+1)/float(stations-1)
		var v0 := minf(t0,1.0-t0)*flat.length()
		var v1 := minf(t1,1.0-t1)*flat.length()
		_add_trail_triangle(tool, left[i], left[i + 1], right_edge[i], Vector2(0, v0), Vector2(0, v1), Vector2(1, v0))
		_add_trail_triangle(tool, right_edge[i], left[i + 1], right_edge[i + 1], Vector2(1, v0), Vector2(0, v1), Vector2(1, v1))
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
		# Imported nature roots into the same geological crown that visually owns
		# the unchanged authored collision ribbon.
		var anchor := a.lerp(b, t)
		if _inside_settlement_clearance(anchor):
			continue
		var side := -1.0 if (serial + cluster) % 2 == 0 else 1.0
		var rock := NATURE_ROCKS[(serial + cluster) % NATURE_ROCKS.size()].instantiate() as Node3D
		apply_stone_palette(rock)
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
## The stylised Rock_Medium_* kit ships a pale, near-white base colour that
## reads as wax or ice beside the trainer (blind verdict round 1, defect 7);
## every instance the world or the look pass places is retinted here to a
## cool mid-grey with full roughness so it reads as stone.
## One tinted duplicate per source material, cached: a fresh duplicate per
## instance (thousands of rocks) raised the headless renderer's
## `Parameter "material" is null` on every override, the cached one raises
## nothing (isolated in a 20-rock probe before this was written).
static var _stone_palette_cache: Dictionary = {}


static func apply_stone_palette(root_node: Node) -> void:
	for mesh_node: Node in root_node.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := mesh_node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		for surface_index in mesh_instance.mesh.get_surface_count():
			var base := mesh_instance.mesh.surface_get_material(surface_index)
			if not (base is StandardMaterial3D):
				continue
			var tinted: StandardMaterial3D = _stone_palette_cache.get(base)
			if tinted == null:
				tinted = (base as StandardMaterial3D).duplicate() as StandardMaterial3D
				tinted.albedo_color = Color("#8e918c")
				tinted.roughness = 1.0
				tinted.metallic = 0.0
				tinted.metallic_specular = 0.15
				_stone_palette_cache[base] = tinted
			mesh_instance.set_surface_override_material(surface_index, tinted)


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
	# Stone-bridge paving (the batched planks below, visible only for this
	# type) sits 0.2 m proud of the authored deck line -- 0.12 m of instance
	# offset plus half its own 0.16 m thickness. Lift the deck collider to
	# meet that visible top exactly instead of leaving a 0.2 m step at the
	# real walking surface. The rope/wood deck's own visible top (from
	# BRIDGE_KIT's thin floor modules) sits only ~0.045 m proud, already
	# inside tolerance, so it is left on the authored line.
	var deck_lift := _segment_basis(a, b).y * (0.2 if stone_bridge else 0.0)
	_segment_box(bridge, "WalkableDeck", a + deck_lift, b + deck_lift, width, 0.42,
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
		var landmark_id := str(spec.get("id", ""))
		var ledge_size := Vector3(92.0, 100.0, 86.0) if settlement else Vector3(46.0, 72.0, 44.0)
		if landmark_id == "sky_shrine_heartstone":
			# The old 72 m cap stopped in the air above its parent highland crown.
			# Carry this exceptional Fly-only pinnacle down into the cloud valley.
			ledge_size = Vector3(132.0, at.y + 210.0, 126.0)
		# `_mesa`'s collider is now built from its own crown surface only, not a
		# hull spanning the full crown-to-base height -- so it can no longer
		# meet an incoming ramp below the crown as a steep wall (the reason
		# these landmarks previously ran with collision disabled, relying
		# solely on their hidden flat "WalkableCrown" boxes). Enable it for
		# old_wind_observatory and summit_eyrie_stronghold too, closing the
		# walk-through gap between that small crown-box footprint and the
		# much larger visible cliff mass around it; the crown boxes stay and
		# still own the authored route elevation, and the ledge's crown
		# (local y=-0.08+0.03=-0.05) sits 0.05 m under ObservatoryWalkableCrown's
		# flat top (local y=0) so it never pokes above it.
		#
		# waterward_overlook stays excluded: its two route-aligned crowns
		# slope to different heights (down to local y=-2.4 on one side, up to
		# +3.35 on the other) to match the specific incoming ramp without a
		# step, and no single flat ledge height can sit under both without
		# either sinking implausibly far below the western approach or
		# resurfacing above the eastern one -- exactly the "flat slab creates
		# a step" conflict the crown boxes exist to avoid.
		# waterward_overlook now collides too: its crown rings follow the two
		# hidden sloped crown strips per vertex (`_crown_height_at` with the
		# strips registered as reference surfaces), so the old "no single flat
		# height fits both" conflict no longer applies -- and its visible crown
		# used to float up to 1 m above the strips (ground-truth probe).
		var ledge_collision := not settlement
		var ledge_y := -0.08 if landmark_id == "old_wind_observatory" else 0.10
		# Flatten every landmark crown's radius the same way a landing pad's
		# is flattened (see `_mesa`'s `flat_top_radius_m`), so an authored
		# route/ramp reaching a crown footprint never meets a jittered dip
		# short of the true collision surface. waterward_overlook is excluded:
		# its two route-aligned crown boxes intentionally slope to different
		# heights on either side of this mesa (see below), and flattening the
		# mesa crown here would only change its unrelated visible silhouette,
		# not fix or affect that residual.
		var ledge_flat_radius := minf(ledge_size.x, ledge_size.z) * 0.47
		var ledge:=_mesa(landmark, "LandmarkLedge", Vector3(0.0, -ledge_size.y * 0.5 + ledge_y, 0.0), ledge_size,
			_materials["cliff"], _materials["upland_dry"] if at.y>=700.0 else _materials["upland"], ledge_collision,
			_landmark_count + 31, false, ledge_flat_radius, _landmark_cap_radius(landmark_id))
		if settlement:
			(ledge.get_node("StratifiedCliffBody") as MeshInstance3D).visible=false
			_build_articulated_settlement_skirt(landmark,at.y>=700.0)
			# The last approach reaches terrace height at z=490. Keep its collision
			# inside that level approach while the geological skirt extends farther.
			_box(landmark, "SettlementWalkableTerrace", Vector3(0, -0.22, 0),
				Vector3(48, 0.44, 48), _materials["upland_dry"], true).visible = false
		elif landmark_id == "old_wind_observatory":
			_box(landmark, "ObservatoryWalkableCrown", Vector3(0, -0.22, 0),
				Vector3(38, 0.44, 36), _materials["upland_dry"], true).visible = false
		elif landmark_id == "waterward_overlook":
			# The restored-winds route terminates on this exact crown. Its former
			# 72m convex ledge met the rising loop well below the top and stopped a
			# held stick 17.6m before the authored endpoint. Keep that tall mass as
			# silhouette. Two thin, route-aligned crown leaves overlap the final
			# portion of each sloped loop edge; a flat slab here would itself create
			# a step wall below the y=1110 vertex. Their narrow widths preserve the
			# intended fall edges on either side of the overlook.
			# Widened (not lengthened, so the authored a->b slope/height at every
			# station along each crown is unchanged) to reach more of the
			# visible ledge disc around them and shrink the walk-through gap
			# beyond their edges. A single flat collider still cannot cover
			# the whole disc here without conflicting with one crown or the
			# other -- see the comment above -- so some of the visible edge
			# past these wider strips is still an intentional/unfixed fall;
			# tracked as a known limitation.
			var west_crown := _segment_box(landmark, "OverlookWalkableCrown",
				Vector3(-8.0, -2.4, -28.0), Vector3.ZERO, 32.0, 0.44,
				_materials["upland_dry"], true)
			var east_crown := _segment_box(landmark, "OverlookWalkableCrownEast",
				Vector3(27.7, 3.35, 4.3), Vector3.ZERO, 26.0, 0.44,
				_materials["upland_dry"], true)
			west_crown.get_child(0).visible = false
			east_crown.get_child(0).visible = false
		_surfaces.append({"kind": "rect", "centre": Vector2(at.x, at.z), "half": Vector2(17.0, 17.0), "height": at.y})
		_cover_patches.append({"kind": "ellipse", "centre": at, "half": Vector2(25.5,25.5) if settlement else Vector2(16.5, 15.5),
			# Settlement lanes are protected by their actual building, yard and
			# path exclusions below. Do not cut one circular lawn out of the middle.
			"inner_clear_fraction": 0.0 if settlement else 0.42,
			"height_scale": 0.58 if settlement else 1.0,
			"seed": _landmark_count * 71 + 809,
			"dry": at.y >= 790.0})
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
	# Installed rock forms cross the turf-to-cliff contact at different heights.
	# Their broad lips interrupt the former straight green roof wedge and cast
	# real recess shadows down the settlement face.
	for i in 10:
		var angle:=TAU*float(i)/10.0+0.31
		var width:=18.0+float(i%3)*4.0
		var height:=17.0+float((i+1)%4)*3.0
		var radius:=28.0+3.5*sin(angle*3.0)
		_visual_rock_mass(root,"SettlementCrownBreak%02d"%i,
			Vector3(cos(angle)*radius,-height+0.35-float(i%2)*1.2,sin(angle)*radius),
			Vector3(width,height,width*(0.68+0.08*(i%2))),1379+i*29,1700.0)
	for i in 5:
		var angle:=TAU*(float(i)+0.45)/5.0
		var width:=30.0+float(i%2)*7.0
		var height:=13.0+float(i%3)*3.0
		var radius:=38.0+4.0*sin(angle*2.0)
		_visual_rock_mass(root,"SettlementMidShelf%02d"%i,
			Vector3(cos(angle)*radius,-31.0-float(i%2)*9.0,sin(angle)*radius),
			Vector3(width,height,width*0.72),1523+i*31,1700.0)
	# The normal approach sees the south face nearly square-on. These staggered
	# visual-only shelves give that important face multiple readable planes;
	# they remain buried outside the unchanged 48 m collision terrace.
	for shelf: Dictionary in [
		{"at":Vector3(-14,-36,-34),"size":Vector3(42,17,25),"seed":1711},
		{"at":Vector3(15,-61,-36),"size":Vector3(46,16,27),"seed":1747},
		{"at":Vector3(-8,-82,-38),"size":Vector3(38,14,24),"seed":1783},
	]:
		_visual_rock_mass(root,"SettlementSouthFaceShelf",
			shelf["at"] as Vector3,shelf["size"] as Vector3,int(shelf["seed"]),1700.0)


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
		_exclude_local_wear_segment(root,local_door,hub,1.05)
		var threshold:=MeshInstance3D.new()
		threshold.name="DoorstepWearPatch"
		var threshold_plane:=PlaneMesh.new()
		threshold_plane.size=Vector2(4.8,4.8)
		threshold.mesh=threshold_plane
		threshold.position=local_door
		threshold.material_override=ENVIRONMENT_MATERIALS.worn_ground(doorway,2.8)
		root.add_child(threshold)
		_cover_exclusions.append({"kind":"ellipse","centre":doorway,
			"half":Vector2(1.8,1.8),"rotation":0.0})
	_build_settlement_yard(root)
	_build_settlement_precinct(root,watch)
	_path_ribbon(root,"WornArrivalToSharedYard",Vector3(0,0.18,-24),Vector3(0,0.18,-1),4.1,991)
	_exclude_local_wear_segment(root,Vector3(0,0.18,-24),Vector3(0,0.18,-1),1.85)


func _plant_floor_pocket(parent: Node3D,at: Vector3,half: Vector2,seed_value: int,dry: bool) -> void:
	_cover_patches.append({"kind":"ellipse","centre":parent.to_global(at),"half":half,
		"seed":seed_value,"dry":dry,"height_scale":0.62})
	_place_local_prop(parent,"bush",at+Vector3(half.x*0.22,0,-half.y*0.18),1.1+0.16*(seed_value%3),seed_value%180)
	_place_local_prop(parent,"flowers",at+Vector3(-half.x*0.23,0,half.y*0.12),0.62,seed_value%90)
	_place_local_prop(parent,"rock_low",at+Vector3(half.x*0.4,-0.08,half.y*0.3),0.6,seed_value%120)


func _exclude_local_wear_segment(parent: Node3D,a: Vector3,b: Vector3,half_width: float) -> void:
	_cover_exclusions.append({"kind":"segment","a":parent.to_global(a),"b":parent.to_global(b),
		"half_width":half_width})


func _build_worn_activity_patch(parent: Node3D,label: String,at: Vector3,half: Vector2,
		seed_value: int) -> void:
	# Irregular use-wear follows an actual prop group. It overlaps the shared
	# yard at one edge so it reads as lived movement, not a decorative island.
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(ENVIRONMENT_MATERIALS.worn_ground(parent.to_global(at),maxf(half.x,half.y)))
	for i in 28:
		var a:=TAU*float(i)/28.0
		var b:=TAU*float(i+1)/28.0
		var ra:=0.86+0.12*sin(a*5.0+seed_value)
		var rb:=0.86+0.12*sin(b*5.0+seed_value)
		var p:=at+Vector3(cos(a)*half.x*ra,0.19,sin(a)*half.y*ra)
		var q:=at+Vector3(cos(b)*half.x*rb,0.19,sin(b)*half.y*rb)
		_add_surface_triangle(tool,at+Vector3.UP*0.19,q,p)
	tool.generate_normals()
	var patch:=MeshInstance3D.new()
	patch.name=label
	patch.mesh=tool.commit()
	parent.add_child(patch)
	_cover_exclusions.append({"kind":"ellipse","centre":parent.to_global(at),
		"half":half*0.62,"rotation":0.0})


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
	for at: Vector3 in [Vector3(-14,0.14,-15),Vector3(-7,0.14,-18),
		Vector3(7,0.14,-18),Vector3(14,0.14,-16),Vector3(-16,0.14,18),Vector3(2,0.14,22)]:
		_plant_floor_pocket(root,at,Vector2(3.2,3.8),int(at.x*7+at.z*11),dry)
	_path_ribbon(root,"WornWatchPrecinctConnection",Vector3(1,0.15,14),watch+Vector3(-6,0.15,-4),3.2,931)
	_exclude_local_wear_segment(root,Vector3(1,0.15,14),watch+Vector3(-6,0.15,-4),1.4)
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
	_cover_exclusions.append({"kind":"ellipse","centre":root.to_global(apron.position),
		"half":Vector2(4.4,4.0),"rotation":0.0})
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
	elif asset.begins_with("rock"):
		# The roadside/landmark rocks placed through this path (authored route
		# details, the summit gate flanks) were missed by the first stone
		# retint and still rendered wax-white in the round-2 frames.
		apply_stone_palette(model)
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
	# Keep only a compact usable centre open. The surrounding short planting is
	# allowed to intrude between buildings instead of forming one empty lawn.
	_cover_exclusions.append({"kind":"ellipse","centre":parent.to_global(centre),
		"half":Vector2(6.8,8.2),"rotation":0.0})
	for prop: Dictionary in _visual_config.get("settlement_dressing", []):
		_place_local_prop(parent, str(prop["asset"]), _vec3(prop["at"]), float(prop["height"]), float(prop.get("yaw", 0)))
	# The two service groups are connected to the communal court by use-wear.
	# Their positions correspond to the installed workbench/bucket/apple and
	# barrel/bag/crate clusters; no new prop family or walking lane is introduced.
	_build_worn_activity_patch(parent,"WestWorkshopWear",Vector3(-16.0,0,-7.0),Vector2(5.5,4.3),419)
	_build_worn_activity_patch(parent,"EastSupplyWear",Vector3(15.2,0,-7.8),Vector2(5.0,4.1),557)
	_path_ribbon(parent,"WestWorkshopConnection",Vector3(-14.0,0.20,-6.0),Vector3(-6.5,0.20,-3.0),2.5,613)
	_path_ribbon(parent,"EastSupplyConnection",Vector3(13.3,0.20,-6.7),Vector3(6.5,0.20,-3.0),2.4,677)
	_exclude_local_wear_segment(parent,Vector3(-14.0,0.20,-6.0),Vector3(-6.5,0.20,-3.0),1.05)
	_exclude_local_wear_segment(parent,Vector3(13.3,0.20,-6.7),Vector3(6.5,0.20,-3.0),1.0)
	var dry:=parent.global_position.y>=700.0
	for side: float in [-1.0, 1.0]:
		for i in 3:
			_place_local_prop(parent, "fence", Vector3(side * 21.0, 0.14, -13.0 + i * 4.0), 1.05, 90)
			_place_local_prop(parent, "flowers", Vector3(side * (17.0 + i * 1.3), 0.14, 13.0 + i * 1.5), 0.5 + i * 0.12, i * 41)
		_place_local_prop(parent, "bush", Vector3(side * 19.0, 0.14, 15.0), 1.25, side * 37)
		_cover_patches.append({"kind": "ellipse", "centre": parent.global_position + Vector3(side * 18.0, 0.14, 13.0),
			"half": Vector2(6.0, 7.0), "seed": int(parent.global_position.y) + int(side) * 11,
			"dry":dry,"height_scale":0.68})
		for i in 2:
			_cover_patches.append({"kind": "ellipse", "centre": parent.global_position + Vector3(side * (9.0 + i * 7.0), 0.14, -26.0 + i * 7.0),
				"half": Vector2(6.8-i*0.6,9.0-i*0.8), "seed": 541 + i + int(side) * 17,
				"dry":dry,"height_scale":0.82})
		_place_local_prop(parent, "flowers", Vector3(side * 14.0, 0.14, -22.0), 0.65, side * 42)
		_place_local_prop(parent, "rock_low", Vector3(side * 15.2, 0.04, -21.0), 0.5, side * 71)
	if parent.global_position.y > 700.0:
		for i in 3:
			_cover_patches.append({"kind": "ellipse", "centre": parent.global_position + Vector3(20.0 + i * 5.0, 0.14, 4.0 + i * 6.0),
				"half": Vector2(4.5, 5.0), "seed": 842 + i * 13,
				"dry":dry,"height_scale":0.68})
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
	# D111 / OP-0906-05: the Summit Stronghold is a domed aviary in rustic
	# stone, not a castle keep. The keep massing (UpperKeep + cornices, the
	# four SummitWatchtowers, the Crenellation row, TetherCrown, GateBridge and
	# the SummitGatehouse castle piece) is gone; `cloudreach_aviary.gd` builds a
	# low masonry drum, four arches, a lattice dome and aviary furniture from
	# `data/config/cloudreach_aviary.json`. Kept: the two articulated route
	# wings (the throat's load-bearing collision -- the summit-overlook circuit
	# leaves this stronghold through their portals), their buttresses, the
	# gate threshold, the corner tether pylons and the banners.
	#
	# The drum is a circle of radius 27 m -- wider than the wings' outer face
	# (x = +-26) -- so the ring stands clear of both wings instead of being
	# cut into fragments by them (a 22x20 ellipse had its wall running through
	# the east wing's z 7.5 portal band); its throat arches at +-x open onto
	# the wing portals, and the dome (same 27 m radius, apex 36 m) clears the
	# lowered wing tops everywhere.
	for side: float in [-1.0, 1.0]:
		var portal_z := -1.5 if side < 0.0 else 7.5
		_build_summit_route_wing(root, side, portal_z)
		var buttress_z := 9.0 if side < 0.0 else -9.0
		_box(root, "WingButtress", Vector3(side * 22.0, 6.0, buttress_z),
			Vector3(4.0, 12.0, 10.0), _materials["cliff_mid"], true)
	_box(root, "GateThreshold", Vector3(0.0, 0.08, -19.0),
		Vector3(9.0, 0.16, 12.0), _materials["masonry_trim"], true)
	# Blind verdict (CLOUDREACH-GROUND-0906 round 1): the drum and arches in
	# the flat brown "stone" read as untextured rust slabs and the veils as
	# placeholder glass. The drum, arches and piers now wear the same mossy
	# masonry family as the kept wings, the veils are fainter, and the iron
	# is a lit graphite rather than near-black.
	var aviary_veil := _wind_veil_material()
	aviary_veil.albedo_color.a = 0.13
	aviary_veil.emission_energy_multiplier = 0.3
	var aviary_materials := {
		"masonry": _materials["masonry_trim"],
		"stone": _materials["masonry"],
		"timber": _materials["wood"],
		"iron": _material(Color("#4a4d52"), 0.55),
		"rope": _materials["rope"],
		"veil": aviary_veil,
		"lantern": _emissive_material(Color("#ffb15c"), 2.0),
	}
	var aviary: Dictionary = AVIARY.build(root, aviary_materials, _read_json(AVIARY_CONFIG_PATH))
	# Corner tether pylons: they stood on the watchtower tops; they now stand
	# on the ground at the four corners outside the drum, flanking the wings.
	for corner in [Vector3(-24.0, 0.0, -20.5), Vector3(24.0, 0.0, -20.5), Vector3(-24.0, 0.0, 20.5), Vector3(24.0, 0.0, 20.5)]:
		var pylon := TETHER_PYLON.instantiate() as Node3D
		var bounds_tool := BUILDING_PREFABS.new()
		var bounds: AABB = bounds_tool.combined_aabb(pylon)
		var scale_value := 6.5 / maxf(bounds.size.y, 0.01)
		pylon.scale = Vector3.ONE * scale_value
		pylon.position = corner - Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * scale_value
		root.add_child(pylon)
	# Banners hang on the wings' south gables, facing the approach.
	for side: float in [-1.0, 1.0]:
		_hang_cloudreach_banner(root,Vector3(side*18.5,7.5,-17.3),Vector2(3.0,8.0),PI)
	# Team Tether's machine stands in the dome's open oculus, on an iron mount
	# plate spanning the oculus ring (the pylon's own base is narrower than
	# the 12 m opening).
	var anchor: Transform3D = aviary.get("pylon_anchor", Transform3D.IDENTITY)
	# A plate the size of the oculus read as a flat black oval in the dome's
	# crown; a narrow one under the machine keeps the oculus visibly open.
	_disc(root, "TetherMountPlate", anchor.origin - Vector3.UP * 0.25, 3.2, 0.5,
		aviary_materials["iron"], false)
	var summit_pylon := TETHER_PYLON.instantiate() as Node3D
	summit_pylon.name = "OccupiedSummitPylon"
	var pylon_bounds_tool := BUILDING_PREFABS.new()
	var pylon_bounds: AABB = pylon_bounds_tool.combined_aabb(summit_pylon)
	var pylon_scale := 18.0 / maxf(pylon_bounds.size.y, 0.01)
	summit_pylon.scale = Vector3.ONE * pylon_scale
	summit_pylon.position = anchor.origin - Vector3(pylon_bounds.get_center().x, pylon_bounds.position.y, pylon_bounds.get_center().z) * pylon_scale
	root.add_child(summit_pylon)
	_develop_stronghold_spaces(root)


func _build_summit_route_wing(root: Node3D, side: float, portal_z: float) -> void:
	const WING_HALF_DEPTH := 17.0
	const PORTAL_HALF_WIDTH := 5.0
	const PORTAL_CLEAR_HEIGHT := 8.0
	# Lowered from 26/28 m (a keep's curtain wall) to sit under the aviary
	# dome: the wing is the drum's east/west gate block now, not a castle wall.
	const WING_HEIGHT := 14.0
	var portal_min := portal_z - PORTAL_HALF_WIDTH
	var portal_max := portal_z + PORTAL_HALF_WIDTH
	for span: Vector2 in [Vector2(-WING_HALF_DEPTH, portal_min), Vector2(portal_max, WING_HALF_DEPTH)]:
		var depth := span.y - span.x
		var centre_z := (span.x + span.y) * 0.5
		_box(root, "SummitWing", Vector3(side * 18.5, WING_HEIGHT * 0.5 - 1.0, centre_z),
			Vector3(15.0, WING_HEIGHT - 2.0, depth), _materials["stone"], true).visible = false
		_castle_piece(root, "SummitMasonryWing", CASTLE_WALL,
			Vector3(side * 18.5, 0.0, centre_z), Vector3(15.0, WING_HEIGHT, depth), _materials["stone"])
	# Retain the wing's silhouette and collision above the authored route,
	# while leaving controller-height clearance at the actual ground crossing.
	var lintel_height := WING_HEIGHT - PORTAL_CLEAR_HEIGHT
	_box(root, "SummitWingLintel",
		Vector3(side * 18.5, PORTAL_CLEAR_HEIGHT + lintel_height * 0.5, portal_z),
		Vector3(15.0, lintel_height, PORTAL_HALF_WIDTH * 2.0), _materials["stone"], true).visible = false
	_castle_piece(root, "SummitMasonryWingLintel", CASTLE_WALL,
		Vector3(side * 18.5, PORTAL_CLEAR_HEIGHT, portal_z),
		Vector3(15.0, lintel_height, PORTAL_HALF_WIDTH * 2.0), _materials["stone"])


func _develop_stronghold_spaces(root: Node3D) -> void:
	# Half-width 5.5 (was 9): the 18 m bare lane's straight tuft cutoff read
	# as a hard-edged terrain patch in the final-approach frame; the lane now
	# hugs the road ribbon and the trail's own feathered edge.
	_cover_exclusions.append({"centre": root.global_position + Vector3(0, 0, -25), "half": Vector2(5.5, 46), "rotation": 0.0})
	_cover_exclusions.append({"centre": root.global_position + Vector3(0, 0, 32), "half": Vector2(18, 24), "rotation": 0.0})
	var court_bounce := OmniLight3D.new()
	court_bounce.name = "CourtyardSkyBounce"
	court_bounce.position = Vector3(0, 8, 40)
	court_bounce.light_color = Color("#c9d4d9")
	court_bounce.light_energy = 2.0
	court_bounce.omni_range = 25.0
	root.add_child(court_bounce)
	# The watchtower masonry courses, splayed bases, tower banners and the
	# gatehouse buttress courses went with the keep (D111); the rear
	# courtyard arcade, braziers, props and approach edges stay.
	for side: float in [-1.0, 1.0]:
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


## A flat collidable disc (cylinder), used where a square box's corners would
## poke past a circular crown's flat cap.
func _disc(parent: Node, label: String, centre: Vector3, radius: float, height: float,
		material: Material, collision: bool) -> Node3D:
	var root := Node3D.new()
	root.name = label
	root.position = centre
	parent.add_child(root)
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 32
	mesh.mesh = cylinder
	mesh.material_override = material
	root.add_child(mesh)
	if collision:
		var body := StaticBody3D.new()
		body.name = "Collision"
		var shape_node := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
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
		rugged_crown: bool = false,
		flat_top_radius_m: float = 0.0,
		cap_radius_m: float = -1.0
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
	var yaw_basis := Basis(Vector3.UP, root.rotation.y)
	# A flat crown (landing pad / landmark ledge): its walkable disc is the
	# authored height inside `cap_radius_m`, then, ring by ring out to
	# `flat_top_radius_m`, each vertex takes `_crown_height_at` -- eased down
	# to any road ribbon or bridge deck within reach (R2). The visible top and
	# the collider are emitted from these same rings (R1).
	var crown_pad: Dictionary = {}
	var crown_lines: Array[Dictionary] = []
	var flat_rings: Array = []
	var flat_ring_radii: Array[float] = []
	if flat_top_radius_m > 0.0:
		var world_anchor := root.global_position
		# `cap_radius_m` < 0: default (half the flat radius); 0: no flat cap at
		# all -- every ring follows the reference surfaces (the waterward
		# overlook, whose hidden crown strips slope right through its centre).
		var cap := cap_radius_m if cap_radius_m >= 0.0 else flat_top_radius_m * 0.5
		cap = clampf(cap, 0.5, flat_top_radius_m - 0.5)
		crown_pad = {"position": Vector3(world_anchor.x, world_anchor.y + size.y * 0.5, world_anchor.z),
			"flat_radius": flat_top_radius_m, "cap_radius": cap}
		crown_lines = _lines_near(world_anchor.x - flat_top_radius_m - 12.0, world_anchor.x + flat_top_radius_m + 12.0,
			world_anchor.z - flat_top_radius_m - 12.0, world_anchor.z + flat_top_radius_m + 12.0)
		# Ring radii from a 2 m hub out to the rim, ~1.8 m apart, so every
		# quad is near-square. The first version fanned the apex straight out
		# to the cap ring (0.8 m x 6.5 m slivers): under the shipped renderer
		# those slivers shaded as alternating light/dark spokes from the
		# trainer's feet (blind verdict rounds 1 and 2, 05-upper-cloudreach-
		# cliffhold). Heights still come from `_crown_height_at` per ring.
		var hub := minf(2.0, cap)
		var ring_count := maxi(1, int(ceilf((flat_top_radius_m - hub) / 1.8)))
		for ring_index in ring_count:
			flat_ring_radii.append(lerpf(hub, flat_top_radius_m, float(ring_index) / float(ring_count)))
			flat_rings.append([] as Array[Vector3])
	for i in sides:
		var angle := TAU * float(i) / float(sides)
		var irregular := 0.87 + 0.10 * sin(angle * 3.0 + float(seed_value))
		irregular += 0.055 * cos(angle * 7.0 - float(seed_value) * 0.7)
		var top_point: Vector3
		if flat_top_radius_m > 0.0:
			# A landing pad or landmark ledge's walkable disc: a plain circle
			# at a fixed radius, no horizontal jitter, so its crown polygon
			# always fully covers the disc an incoming ramp/bridge/route is
			# authored to reach. A jittered radius can dip narrower than that
			# disc at some angles, leaving the true collision surface (the
			# crown) short of where a deck or ribbon actually meets it --
			# CAUSEWAY-HUB-0906. Jitter still shows just outside this radius,
			# on the descending cliff wall below the crown.
			#
			# R2 (CLOUDREACH-CROWN-0906): an approach that has not finished
			# climbing by the time it reaches this rim otherwise meets a flat,
			# already-at-height crown as a real wall (arrival-road /
			# summit-road, both confirmed by probe: the stuck point sat right
			# at/just past this exact rim, against a route OR an overlapping
			# landmark ledge sharing the same authored junction). Ease this
			# rim vertex's height DOWN toward the height of any route ribbon
			# or bridge deck within reach of it (`_crown_height_at`, which
			# also matches a still-climbing stretch of THIS pad's own
			# approach) -- never up, so nothing outside a real approach ever
			# rises. The crown's apex (`_emit_mesa_top`'s `crown` point) stays
			# pinned to the exact authored height regardless, so only the
			# rim -- and, by the fan's own linear interpolation, a narrowing
			# wedge of the disc facing the eased approach -- ever eases; the
			# rest of the disc, and every other angle around the rim, is
			# untouched and exactly as flat as before.
			# `centre` is `root`'s POSITION, which for a landmark ledge (parented
			# under a landmark node already offset to its authored world spot)
			# is only local to that parent, not the world coordinates route
			# lines are authored in. `root.global_position` is the real world
			# anchor regardless of parentage.
			var world_anchor := root.global_position
			var rim_world := world_anchor + yaw_basis * Vector3(cos(angle) * flat_top_radius_m, 0.0, sin(angle) * flat_top_radius_m)
			var eased_world_y := _crown_height_at(crown_pad, rim_world, crown_lines)
			top_point = Vector3(cos(angle) * flat_top_radius_m, eased_world_y - world_anchor.y,
				sin(angle) * flat_top_radius_m)
			for ring_index in flat_rings.size():
				var ring_radius: float = flat_ring_radii[ring_index]
				var ring_world := world_anchor + yaw_basis * Vector3(cos(angle) * ring_radius, 0.0, sin(angle) * ring_radius)
				var ring_y := _crown_height_at(crown_pad, ring_world, crown_lines)
				(flat_rings[ring_index] as Array).append(Vector3(cos(angle) * ring_radius,
					ring_y - world_anchor.y, sin(angle) * ring_radius))
		else:
			top_point = Vector3(cos(angle) * size.x * 0.47 * irregular,
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
	# The relief context for a NON-flat crown (a region CliffMass, a ledge, a
	# shelf). Built once and handed to BOTH the visible crown and its collision
	# copy below, so the two are emitted from identical geometry -- the R1
	# guarantee this file already makes for the flat crowns.
	var crown_relief: Dictionary = {}
	if flat_rings.is_empty() and not _crown_relief_config().is_empty():
		var crown_span := 0.0
		for point: Vector3 in top_ring:
			crown_span = maxf(crown_span, Vector2(point.x, point.z).length())
		var crown_world := root.global_position + Vector3(0.0, crown.y, 0.0)
		crown_relief = {
			"basis": Basis(Vector3.UP, root.rotation.y),
			"origin": root.global_position,
			"pad": {"position": crown_world, "flat_radius": crown_span,
				"cap_radius": crown_span * 0.5},
			"lines": _lines_near(root.global_position.x - crown_span - 12.0,
				root.global_position.x + crown_span + 12.0,
				root.global_position.z - crown_span - 12.0,
				root.global_position.z + crown_span + 12.0),
			"step_m": float(_crown_relief_config().get("mesh_step_m", 7.0)),
			"max_steps": int(_crown_relief_config().get("max_steps", 26)),
		}
	if flat_rings.is_empty():
		_emit_mesa_top(top_tool, sides, eroded_crown, crown, core_ring, top_ring, crown_relief)
	else:
		_emit_flat_crown(top_tool, sides, crown, flat_rings, top_ring)
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
		_build_embedded_rock_shelves(root, size, seed_value, label)

	if collision:
		# Collide with the mesa's own rendered top surface, not a convex hull
		# spanning the full crown-to-base height. A hull built from top_ring
		# and bottom_ring floats above concave dips and sinks below bumps in
		# the (possibly eroded/rugged) crown, and -- for tall masses -- its
		# deep side walls can cross an authored road passing through the
		# footprint below the crown, blocking a held stick. The walkable
		# surface is only ever the crown; nothing below it is meant to be
		# stood on, so only the crown geometry needs a collider.
		var collision_mesh := ArrayMesh.new()
		var collision_tool := SurfaceTool.new()
		collision_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		if flat_rings.is_empty():
			_emit_mesa_top(collision_tool, sides, eroded_crown, crown, core_ring, top_ring, crown_relief)
		else:
			_emit_flat_crown(collision_tool, sides, crown, flat_rings, top_ring)
		# A bare, zero-thickness crown edge is a known character-controller trap:
		# approaching from a slightly lower, similar-height surface (a bridge
		# deck or ramp meeting this mesa) can wall against the paper-thin rim
		# instead of registering as the small ordinary step it visually is
		# (CAUSEWAY-HUB-0906). A shallow skirt below the rim gives that edge
		# real thickness to climb, without reaching deep enough to cross a
		# road passing well below the crown the way the old full-depth hull did.
		#
		# Kept at, not above, the player controller's own ~0.35 m step-up
		# allowance (`STEP_HEIGHT` in player_controller.gd). A taller skirt
		# (an earlier version used 2 m) stops being a helpful "real thickness"
		# and becomes an unclimbable wall of its own wherever the approaching
		# ground is still legitimately below the crown by more than a step --
		# e.g. a road still finishing its climb right up to a landing pad,
		# which a fixed-radius flat disc can reach into no matter how the
		# taper toward it is tuned. A short skirt cannot fully hide a paper
		# edge either, but the residual is a step, not a wall.
		_emit_mesa_skirt(collision_tool, sides, top_ring, 0.3)
		collision_tool.commit(collision_mesh)
		var body := StaticBody3D.new()
		body.name = "Collision"
		var shape_node := CollisionShape3D.new()
		shape_node.shape = collision_mesh.create_trimesh_shape()
		body.add_child(shape_node)
		root.add_child(body)
	return root


## A shallow vertical rim just below the crown's outer edge, giving the
## otherwise paper-thin top surface real thickness to climb where a lower
## approach meets it -- collision-only, the visible wall is unchanged.
func _emit_mesa_skirt(tool: SurfaceTool, sides: int, top_ring: Array[Vector3], depth: float) -> void:
	for i in sides:
		var next := (i + 1) % sides
		var top_a: Vector3 = top_ring[i] + Vector3.UP * 0.03
		var top_b: Vector3 = top_ring[next] + Vector3.UP * 0.03
		var bottom_a := top_a - Vector3.UP * depth
		var bottom_b := top_b - Vector3.UP * depth
		_add_surface_triangle(tool, top_a, bottom_a, top_b)
		_add_surface_triangle(tool, top_b, bottom_a, bottom_b)


## The mesa's crown surface: a flat/eroded/rugged fan from `crown` across
## `top_ring` (and, for the eroded-crown profile, through `core_ring` as an
## intermediate contour). Shared by the visible top mesh and its collision
## copy so the two can never drift apart.
func _emit_mesa_top(tool: SurfaceTool, sides: int, eroded_crown: bool, crown: Vector3,
		core_ring: Array[Vector3], top_ring: Array[Vector3],
		relief: Dictionary = {}) -> void:
	var lift := Vector3.UP * 0.03
	if eroded_crown:
		_emit_crown_fan(tool, sides, crown, core_ring, lift, relief)
		_emit_crown_strip(tool, sides, core_ring, top_ring, lift, relief)
	else:
		_emit_crown_fan(tool, sides, crown, top_ring, lift, relief)


## An apex-to-ring cap, SUBDIVIDED rather than fanned.
##
## Both crown profiles used to reach their first contour in a single triangle
## per side: a fan from one apex vertex straight out to a ring 50-200 m away.
## However the height model varies across that span, the mesh cannot show it --
## three vertices describe a plane. That is why the crowns rendered as flat
## discs however much relief the height model carried, and it is the geometry
## behind the owner's "completely flat green ground".
func _emit_crown_fan(tool: SurfaceTool, sides: int, apex: Vector3, ring: Array[Vector3],
		lift: Vector3, relief: Dictionary) -> void:
	var steps := _crown_steps(apex, ring, relief)
	var inner: Array[Vector3] = []
	for i in sides:
		inner.append(apex)
	for step in range(1, steps + 1):
		var t := float(step) / float(steps)
		var outer: Array[Vector3] = []
		for i in sides:
			var point := apex.lerp(ring[i], t)
			outer.append(_with_crown_relief(point, relief, t))
		if step == 1:
			for i in sides:
				var next := (i + 1) % sides
				_add_surface_triangle(tool, apex, outer[next] + lift, outer[i] + lift)
		else:
			_emit_crown_strip(tool, sides, inner, outer, lift, {})
		inner = outer
	# The outermost ring must land EXACTLY on the authored contour, so the
	# crown still meets the cliff face it was built against.
	_emit_crown_strip(tool, sides, inner, ring, lift, {})


## Ring to ring. `relief` empty means the rings arrive already displaced.
func _emit_crown_strip(tool: SurfaceTool, sides: int, inner: Array[Vector3],
		outer: Array[Vector3], lift: Vector3, relief: Dictionary) -> void:
	var a := inner
	var b := outer
	if not relief.is_empty():
		var steps := _crown_steps(inner[0], outer, relief)
		var previous := inner
		for step in range(1, steps + 1):
			var t := float(step) / float(steps)
			var current: Array[Vector3] = []
			for i in sides:
				current.append(_with_crown_relief(inner[i].lerp(outer[i], t), relief, 1.0 - t)
					if step < steps else outer[i])
			_emit_crown_strip(tool, sides, previous, current, lift, {})
			previous = current
		return
	for i in sides:
		var next := (i + 1) % sides
		_add_surface_triangle(tool, a[i] + lift, a[next] + lift, b[i] + lift)
		_add_surface_triangle(tool, b[i] + lift, a[next] + lift, b[next] + lift)


## How many rings a band needs so its quads are roughly `step_m` across. A band
## no wider than one step keeps its single strip, so a small ledge is untouched.
func _crown_steps(inner_point: Vector3, outer_ring: Array[Vector3], relief: Dictionary) -> int:
	if relief.is_empty():
		return 1
	var span := 0.0
	for point: Vector3 in outer_ring:
		span = maxf(span, Vector2(point.x - inner_point.x, point.z - inner_point.z).length())
	var step_m := maxf(float(relief.get("step_m", 7.0)), 1.0)
	return clampi(int(ceilf(span / step_m)), 1, int(relief.get("max_steps", 26)))


## A local-space crown vertex, displaced by the world-space relief field.
## `blend` fades the displacement out as the vertex approaches the authored
## contour so the band still closes on the geometry it was built against.
func _with_crown_relief(local: Vector3, relief: Dictionary, blend: float) -> Vector3:
	if relief.is_empty():
		return local
	var basis: Basis = relief["basis"]
	var origin: Vector3 = relief["origin"]
	var world: Vector3 = origin + basis * local
	var offset := _crown_relief_at(relief["pad"], world, relief["lines"])
	return local + Vector3.UP * offset * clampf(blend, 0.0, 1.0)


## A flat pad/landmark crown: an apex fan to the innermost (cap) ring, then
## quad strips ring to ring out to `top_ring` (the rim). Shared by the visible
## top mesh and its collision copy (R1). Every ring vertex already carries its
## `_crown_height_at` height (R2), so the strips reproduce a road's slope
## piecewise-linearly across the disc instead of stepping at the rim.
func _emit_flat_crown(tool: SurfaceTool, sides: int, crown: Vector3, rings: Array,
		top_ring: Array[Vector3]) -> void:
	var lift := Vector3.UP * 0.03
	var chain: Array = rings.duplicate()
	chain.append(top_ring)
	var inner: Array = chain[0]
	for i in sides:
		var next := (i + 1) % sides
		_add_surface_triangle(tool, crown, inner[next] + lift, inner[i] + lift)
	for ring_index in chain.size() - 1:
		var a_ring: Array = chain[ring_index]
		var b_ring: Array = chain[ring_index + 1]
		for i in sides:
			var next := (i + 1) % sides
			_add_surface_triangle(tool, a_ring[i] + lift, a_ring[next] + lift, b_ring[i] + lift)
			_add_surface_triangle(tool, b_ring[i] + lift, a_ring[next] + lift, b_ring[next] + lift)


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
		apply_stone_palette(rock)
		var bounds: AABB=BUILDING_PREFABS.new().combined_aabb(rock)
		rock.scale=Vector3(width,height,width*0.82)/bounds.size
		rock.rotation.y=angle
		rock.position=Vector3(cos(angle)*size.x*0.19,size.y*0.5-height*0.7-6.0,sin(angle)*size.z*0.19)-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*rock.scale
		parent.add_child(rock)
		for mesh: MeshInstance3D in rock.find_children("*","MeshInstance3D",true,false):
			mesh.material_override=_materials["cliff"]
		_set_geometry_visibility(rock,1500.0)


var _crag_kit_cache: Array = []
var _crag_kit_loaded := false

## CLIFF-ART-0906. The optional modular cliff kit for the embedded outcrops,
## from `visual.geology.crag_kit` (an array of res:// scene paths). Empty
## means the shipped Quaternius boulders.
func _crag_kit() -> Array:
	if _crag_kit_loaded:
		return _crag_kit_cache
	_crag_kit_loaded = true
	var geo_cfg: Dictionary = _visual_config.get("geology", {})
	for raw in (geo_cfg.get("crag_kit", []) as Array):
		var scene := load(str(raw)) as PackedScene
		if scene != null:
			_crag_kit_cache.append(scene)
		else:
			push_warning("cloudreach geology.crag_kit: cannot load %s" % str(raw))
	return _crag_kit_cache


func _build_embedded_rock_shelves(parent: Node3D, size: Vector3, seed_value: int,
		mass_label: String) -> void:
	# Production-family outcrops break the generated cliff skin into recognizable
	# eroded blocks. Their inner halves are buried into the supporting mass.
	var monumental:=mass_label=="CliffMass" or mass_label=="LandmarkLedge"
	var outcrop_count:=13 if monumental else 9
	for i in outcrop_count:
		var angle := float(i) * TAU / float(outcrop_count) + float(seed_value) * 0.23
		var depth_step:=clampf(size.y*0.085,22.0,58.0) if monumental else minf(22.0,size.y*0.10)
		var depth := 9.0 + float(i % (5 if monumental else 3)) * depth_step
		var width := clampf(size.x * (0.29 if monumental else 0.24),
			22.0 if monumental else 14.0,78.0 if monumental else 52.0)
		width*=0.82+0.18*sin(float(i)*2.17+seed_value)
		var height := width * (0.35 + float(i % 2) * 0.14)
		# CLIFF-ART-0906 option C: `visual.geology.crag_kit` names a list of
		# modular cliff meshes (Kenney Nature Kit `cliff_*`, CC0) to stand in
		# for the Quaternius boulders as the embedded outcrops -- stepped,
		# faceted ledge blocks instead of rounded stones. They wear the same
		# geology shader as the mass, so the palette is one decision.
		var kit := _crag_kit()
		var rock: Node3D
		if kit.is_empty():
			rock = NATURE_ROCKS[posmod(i + seed_value, NATURE_ROCKS.size())].instantiate() as Node3D
			apply_stone_palette(rock)
		else:
			rock = (kit[posmod(i + seed_value, kit.size())] as PackedScene).instantiate() as Node3D
			# Kenney blocks are unit cubes with the face on +z; a 0..1 box
			# scaled to width/height reads as a cut ledge, so let them be a
			# little squarer than a boulder.
			height = width * (0.42 + float(i % 2) * 0.16)
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
	# Broad ledges, spread down the face rather than clustered under the crown,
	# give large ravine/landmark silhouettes intermediate planes and scale.
	var shelf_count:=5 if monumental else 3
	for i in shelf_count:
		var angle := float(i) * 2.399 + seed_value * 0.23
		# Preserve the three existing shelf bodies and their collision exactly.
		# The two larger, deeper additions are visual-only transition planes.
		var shelf_width := clampf(size.x * 0.22,16.0,44.0)
		var shelf_height := minf(18.0,size.y*0.12)
		var shelf_top := size.y*0.5-12.0-i*19.0
		if i>=3:
			shelf_width=clampf(size.x*0.32,28.0,86.0)*(0.82+0.16*float(i%3))
			shelf_height=minf(24.0,size.y*0.12)
			shelf_top=size.y*0.5-14.0-i*clampf(size.y*0.075,21.0,64.0)
		var shelf := Vector3(cos(angle) * size.x * 0.44, shelf_top, sin(angle) * size.z * 0.44)
		_mesa(parent, "VegetatedGeologicalShelf%d" % i, shelf - Vector3.UP * shelf_height * 0.5,
			Vector3(shelf_width, shelf_height, shelf_width * 0.78), _materials["cliff"], _materials["upland"],
			i<3, seed_value + 131 + i)
		_cover_patches.append({"kind":"ellipse","centre":parent.to_global(shelf),
			"half":Vector2(shelf_width*0.30,shelf_width*0.23),"seed":seed_value*31+i,"dry":false})
		if i%2==0 or not monumental:
			var tree := NATURE_TREES[posmod(i + seed_value, NATURE_TREES.size())].instantiate() as Node3D
			tree.position = shelf - Vector3.UP * 0.10
			tree.scale = Vector3.ONE * (0.92 + i * 0.12)
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
