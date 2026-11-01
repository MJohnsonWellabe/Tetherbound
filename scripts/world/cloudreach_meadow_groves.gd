extends RefCounted

## Cause lane meadow_groves (flag-off; `data/config/cloudreach_cause.json`).
##
## 1 Nov GPU judges, across the F40 catalogue: "uniform grass carpet of
## identical blades", "flat uniform lawn". Every grass pass fills every turf
## surface at one density and one height band, so a Cloudreach crown reads as
## a mown lawn to the rim. After those passes, one world-space field (about
## 90 m features) sorts the turf into three kinds of ground:
##
## - clearings: shorter, thinner grass (the turf ground shows between);
## - meadow: unchanged;
## - groves: clumps of installed CommonTree and Bush pieces in the field's
##   high cores, with longer grass at their fringe.
##
## A second field places installed Rock_Medium outcrops on the meadow, with the
## grass cleared from under each stone. Routes, settlements, landmark vistas
## and cover exclusions stay clear (the look pass's own tests). One pass over
## the tuft buffers at build; no per-frame work, no collider, no save field.

const COVER_SHADER := preload("res://shaders/cloudreach_ground_cover.gdshader")
const TREES: Array[PackedScene] = [
	preload("res://assets/environment/stylized_nature/CommonTree_1.gltf"),
	preload("res://assets/environment/stylized_nature/CommonTree_2.gltf"),
	preload("res://assets/environment/stylized_nature/CommonTree_3.gltf"),
	preload("res://assets/environment/stylized_nature/CommonTree_4.gltf"),
	preload("res://assets/environment/stylized_nature/CommonTree_5.gltf"),
]
const BUSHES: Array[PackedScene] = [
	preload("res://assets/environment/stylized_nature/Bush_Common.gltf"),
	preload("res://assets/environment/stylized_nature/Bush_Common_Flowers.gltf"),
]
const ROCKS: Array[PackedScene] = [
	preload("res://assets/environment/stylized_nature/Rock_Medium_1.gltf"),
	preload("res://assets/environment/stylized_nature/Rock_Medium_2.gltf"),
	preload("res://assets/environment/stylized_nature/Rock_Medium_3.gltf"),
]
const CLEAR_CELL_M := 8.0

var _spec: Dictionary = {}
var _field := FastNoiseLite.new()
var _outcrop := FastNoiseLite.new()


func _init(spec: Dictionary) -> void:
	_spec = spec
	var seed_value := int(spec.get("seed", 40111))
	for noise: FastNoiseLite in [_field, _outcrop]:
		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		noise.fractal_type = FastNoiseLite.FRACTAL_FBM
		noise.fractal_octaves = 2
	_field.seed = seed_value
	_field.frequency = float(spec.get("field_frequency", 0.011))
	_outcrop.seed = seed_value + 7
	_outcrop.frequency = float(spec.get("outcrop_frequency", 0.019))


func field_at(x: float, z: float) -> float:
	return _field.get_noise_2d(x, z)


func outcrop_at(x: float, z: float) -> float:
	return _outcrop.get_noise_2d(x, z)


## (clearing weight, grove weight) for a field value, each 0..1.
static func zone_weights(f: float, spec: Dictionary) -> Vector2:
	var clearing := float(spec.get("clearing_below", -0.28))
	var clearing_band := maxf(0.001, float(spec.get("clearing_band", 0.14)))
	var grove := float(spec.get("grove_above", 0.34))
	var grove_band := maxf(0.001, float(spec.get("grove_band", 0.12)))
	return Vector2(1.0 - smoothstep(clearing - clearing_band, clearing + clearing_band, f),
		smoothstep(grove - grove_band, grove + grove_band, f))


## Height multiplier for a tuft at field value `f`.
static func height_factor(f: float, spec: Dictionary) -> float:
	var w := zone_weights(f, spec)
	return lerpf(1.0, float(spec.get("clearing_height", 0.5)), w.x) \
		* lerpf(1.0, float(spec.get("fringe_height", 1.3)), w.y)


## Whether a clearing thins out the tuft rooted at (x, z): a positional hash,
## so the result never depends on build order.
static func thinned(x: float, z: float, f: float, spec: Dictionary) -> bool:
	var keep := lerpf(1.0, float(spec.get("clearing_keep", 0.6)), zone_weights(f, spec).x)
	if keep >= 1.0:
		return false
	return fposmod(sin(x * 12.9898 + z * 78.233) * 43758.5453, 1.0) >= keep


## Edits one TRANSFORM_3D MultiMesh buffer in place (12 floats per instance,
## rows of the 3x4 transform). `to_world` maps instance origins to world;
## `cleared` is a CLEAR_CELL_M grid of [Vector3 centre, radius] lists.
## Returns {"scaled": n, "collapsed": n}.
func edit_buffer(buffer: PackedFloat32Array, to_world: Transform3D, cleared: Dictionary) -> Dictionary:
	var scaled := 0
	var collapsed := 0
	var count := int(buffer.size() / 12.0)
	for i in count:
		var b := i * 12
		var local := Vector3(buffer[b + 3], buffer[b + 7], buffer[b + 11])
		var at := to_world * local
		var collapse := false
		var cell: Variant = cleared.get(Vector2i(floori(at.x / CLEAR_CELL_M), floori(at.z / CLEAR_CELL_M)))
		if cell != null:
			for entry: Array in cell:
				var centre: Vector3 = entry[0]
				if Vector2(at.x - centre.x, at.z - centre.z).length() < float(entry[1]):
					collapse = true
					break
		var f := field_at(at.x, at.z)
		if not collapse and thinned(at.x, at.z, f, _spec):
			collapse = true
		if collapse:
			for k: int in [0, 1, 2, 4, 5, 6, 8, 9, 10]:
				buffer[b + k] = 0.0
			collapsed += 1
			continue
		var h := height_factor(f, _spec)
		if not is_equal_approx(h, 1.0):
			buffer[b + 4] *= h
			buffer[b + 5] *= h
			buffer[b + 6] *= h
			scaled += 1
	return {"scaled": scaled, "collapsed": collapsed}


static func add_clear(cleared: Dictionary, centre: Vector3, radius: float) -> void:
	for cx in range(floori((centre.x - radius) / CLEAR_CELL_M), floori((centre.x + radius) / CLEAR_CELL_M) + 1):
		for cz in range(floori((centre.z - radius) / CLEAR_CELL_M), floori((centre.z + radius) / CLEAR_CELL_M) + 1):
			var key := Vector2i(cx, cz)
			if not cleared.has(key):
				cleared[key] = []
			(cleared[key] as Array).append([centre, radius])


## The whole pass. `look` is the realm's CloudreachLook node (its exclusion,
## route, settlement and raycast helpers), `world` the built realm.
func build(look: Node3D, world: Node3D) -> Dictionary:
	var root := Node3D.new()
	root.name = "CauseMeadowGroves"
	look.add_child(root)
	var cleared := {}
	var sites := _plan_sites(look, world)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_spec.get("seed", 40111)) + 3
	var visible := float(_spec.get("visible_m", 950.0))
	var trees := 0
	var rocks := 0
	for site: Dictionary in sites:
		var at: Vector3 = site.at
		if str(site.kind) == "grove":
			trees += _plant_grove(look, world, root, at, rng, visible, cleared)
		else:
			rocks += _plant_outcrop(look, world, root, at, rng, visible, cleared)
	var result := {"groves": 0, "outcrops": 0, "trees": trees, "rocks": rocks, "scaled": 0, "collapsed": 0}
	for site: Dictionary in sites:
		result[str(site.kind) + "s"] = int(result[str(site.kind) + "s"]) + 1
	for instances: MultiMeshInstance3D in tuft_instances(world):
		var multimesh := instances.multimesh
		var buffer := multimesh.buffer
		if buffer.size() < 12:
			continue
		var edit := edit_buffer(buffer, _xform(instances), cleared)
		multimesh.buffer = buffer
		result.scaled = int(result.scaled) + int(edit.scaled)
		result.collapsed = int(result.collapsed) + int(edit.collapsed)
	return result


## Every ordinary grass tuft batch (the cover shader, not leaf-cut shrubs).
static func tuft_instances(world: Node) -> Array[MultiMeshInstance3D]:
	var out: Array[MultiMeshInstance3D] = []
	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child: Node in node.get_children():
			stack.append(child)
		var instances := node as MultiMeshInstance3D
		if instances == null or instances.multimesh == null:
			continue
		if instances.multimesh.transform_format != MultiMesh.TRANSFORM_3D:
			continue
		var material := instances.material_override as ShaderMaterial
		if material == null or material.shader != COVER_SHADER:
			continue
		var leaf: Variant = material.get_shader_parameter("leaf_cut")
		if leaf != null and float(leaf) > 0.0:
			continue
		out.append(instances)
	return out


func _plan_sites(look: Node3D, world: Node3D) -> Array[Dictionary]:
	var sites: Array[Dictionary] = []
	var patches: Variant = look.get("_ellipse_patches_cache")
	if not patches is Array:
		return sites
	var spacing := maxf(8.0, float(_spec.get("site_spacing_m", 22.0)))
	var max_groves := int(_spec.get("max_groves", 260))
	var max_outcrops := int(_spec.get("max_outcrops", 200))
	var grove_chance := float(_spec.get("grove_site_chance", 0.55))
	var outcrop_chance := float(_spec.get("outcrop_site_chance", 0.5))
	var grove_above := float(_spec.get("grove_above", 0.34)) + float(_spec.get("grove_band", 0.12)) * 0.5
	var outcrop_above := float(_spec.get("outcrop_above", 0.52))
	var route_clear := float(_spec.get("route_clear_m", 6.0))
	var groves := 0
	var outcrops := 0
	var taken := {}
	for raw: Variant in patches:
		if not raw is Dictionary:
			continue
		var patch: Dictionary = raw
		var centre: Vector3 = patch.get("centre", Vector3.ZERO)
		var half: Vector2 = patch.get("half", Vector2.ONE)
		for gx in range(floori((centre.x - half.x) / spacing), floori((centre.x + half.x) / spacing) + 1):
			for gz in range(floori((centre.z - half.y) / spacing), floori((centre.z + half.y) / spacing) + 1):
				if groves >= max_groves and outcrops >= max_outcrops:
					return sites
				var key := Vector2i(gx, gz)
				if taken.has(key):
					continue
				# Jittered grid point, hashed from the cell: build-order free.
				var h1 := fposmod(sin(gx * 127.1 + gz * 311.7) * 43758.5453, 1.0)
				var h2 := fposmod(sin(gx * 269.5 + gz * 183.3) * 43758.5453, 1.0)
				var h3 := fposmod(sin(gx * 419.2 + gz * 371.9) * 43758.5453, 1.0)
				var x := (gx + 0.2 + h1 * 0.6) * spacing
				var z := (gz + 0.2 + h2 * 0.6) * spacing
				var u := Vector2((x - centre.x) / maxf(half.x, 1.0), (z - centre.z) / maxf(half.y, 1.0))
				if u.length() > 0.92:
					continue
				var f := field_at(x, z)
				var kind := ""
				if f >= grove_above and h3 < grove_chance and groves < max_groves:
					kind = "grove"
				elif outcrop_at(x, z) >= outcrop_above and f < grove_above and h3 < outcrop_chance \
						and outcrops < max_outcrops:
					kind = "outcrop"
				if kind.is_empty():
					continue
				var probe := Vector3(x, centre.y, z)
				if bool(look.call("_excluded", probe)) or bool(look.call("_near_route", probe, route_clear)) \
						or bool(look.call("_inside_settlement", probe)):
					continue
				if world.has_method("_inside_landmark_vista") and bool(world.call("_inside_landmark_vista", probe)):
					continue
				var hit: Dictionary = look.call("_raycast_down", Vector2(x, z), centre.y)
				if not bool(look.call("_is_turf_top", hit)):
					continue
				var ground: Vector3 = hit.get("position")
				if absf(ground.y - centre.y) > 60.0:
					continue
				taken[key] = true
				sites.append({"kind": kind, "at": ground})
				if kind == "grove":
					groves += 1
				else:
					outcrops += 1
	return sites


func _plant_grove(look: Node3D, world: Node3D, root: Node3D, at: Vector3, rng: RandomNumberGenerator,
		visible: float, cleared: Dictionary) -> int:
	var radius := float(_spec.get("grove_radius_m", 9.0))
	var tree_range: Array = _spec.get("trees_per_grove", [3, 6])
	var bush_range: Array = _spec.get("bushes_per_grove", [2, 4])
	var tree_scale: Array = _spec.get("tree_scale", [0.9, 1.45])
	var bush_scale: Array = _spec.get("bush_scale", [1.1, 1.8])
	var route_clear := float(_spec.get("route_clear_m", 6.0))
	var planted := 0
	var trees := rng.randi_range(int(tree_range[0]), int(tree_range[1]))
	var bushes := rng.randi_range(int(bush_range[0]), int(bush_range[1]))
	for i in trees + bushes:
		var is_tree := i < trees
		var angle := rng.randf_range(0.0, TAU)
		var r := radius * sqrt(rng.randf()) * (1.0 if is_tree else 1.25)
		var x := at.x + cos(angle) * r
		var z := at.z + sin(angle) * r
		var yaw := rng.randf_range(0.0, TAU)
		var size := rng.randf_range(float((tree_scale if is_tree else bush_scale)[0]),
			float((tree_scale if is_tree else bush_scale)[1]))
		var pick := rng.randi()
		var ground := _turf_point(look, Vector3(x, at.y, z), route_clear * (1.0 if is_tree else 0.6))
		if ground == Vector3.INF:
			continue
		var scenes := TREES if is_tree else BUSHES
		var node := scenes[pick % scenes.size()].instantiate() as Node3D
		node.name = ("GroveTree%d" if is_tree else "GroveBush%d") % root.get_child_count()
		node.position = ground
		node.rotation.y = yaw
		node.scale = Vector3.ONE * size
		if is_tree and world.has_method("_apply_tree_palette"):
			world.call("_apply_tree_palette", node, pick % 97)
		root.add_child(node)
		_set_visibility(node, visible)
		if is_tree:
			add_clear(cleared, ground, 0.9 * size)
			planted += 1
	return planted


func _plant_outcrop(look: Node3D, world: Node3D, root: Node3D, at: Vector3, rng: RandomNumberGenerator,
		visible: float, cleared: Dictionary) -> int:
	var count_range: Array = _spec.get("rocks_per_outcrop", [2, 4])
	var scale_range: Array = _spec.get("rock_scale", [1.6, 3.6])
	var embed := float(_spec.get("rock_embed", 0.45))
	var clear := float(_spec.get("outcrop_clear_m", 3.5))
	var route_clear := float(_spec.get("route_clear_m", 6.0))
	var placed := 0
	var count := rng.randi_range(int(count_range[0]), int(count_range[1]))
	for i in count:
		var size := rng.randf_range(float(scale_range[0]), float(scale_range[1])) * (1.0 if i == 0 else 0.6)
		var offset := Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * (0.0 if i == 0 else size * 1.1)
		var yaw := rng.randf_range(0.0, TAU)
		var pick := rng.randi()
		var ground := _turf_point(look, at + Vector3(offset.x, 0.0, offset.y), route_clear)
		if ground == Vector3.INF:
			continue
		var rock := ROCKS[pick % ROCKS.size()].instantiate() as Node3D
		rock.name = "OutcropRock%d" % root.get_child_count()
		if world.has_method("apply_stone_palette"):
			world.call("apply_stone_palette", rock)
		# Same seat as the look pass's stone clusters (embed x 1.6 x scale).
		rock.position = ground - Vector3.UP * (embed * 1.6 * size)
		rock.rotation.y = yaw
		rock.scale = Vector3.ONE * size
		root.add_child(rock)
		_set_visibility(rock, visible)
		add_clear(cleared, ground, clear * size / float(scale_range[1]) + 1.0)
		placed += 1
	return placed


func _turf_point(look: Node3D, probe: Vector3, route_clear: float) -> Vector3:
	if bool(look.call("_excluded", probe)) or bool(look.call("_near_route", probe, route_clear)) \
			or bool(look.call("_inside_settlement", probe)):
		return Vector3.INF
	var hit: Dictionary = look.call("_raycast_down", Vector2(probe.x, probe.z), probe.y, 40.0, 40.0)
	if not bool(look.call("_is_turf_top", hit)):
		return Vector3.INF
	return hit.get("position")


static func _set_visibility(node: Node, distance: float) -> void:
	for geometry: GeometryInstance3D in node.find_children("*", "GeometryInstance3D", true, false):
		geometry.visibility_range_end = distance


static func _xform(node: Node3D) -> Transform3D:
	if node.is_inside_tree():
		return node.global_transform
	var result := node.transform
	var parent := node.get_parent()
	while parent != null:
		if parent is Node3D:
			result = (parent as Node3D).transform * result
		parent = parent.get_parent()
	return result
