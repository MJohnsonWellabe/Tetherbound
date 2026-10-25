extends "res://scripts/world/water_veilfall_tiered_r2.gd"
## P2-010 claude-r1: a crag kitbashed from INSTALLED rock meshes (stylized
## Rock_Medium boulders, fluted limestone spire columns, rock_tallA pinnacles)
## instead of authored blockout slabs. An irregular multi-peak massif is
## sampled on a jittered grid; each exposed column is stacked from randomly
## rotated/scaled pieces and capped with boulders or pinnacles, so no straight
## cone or slab edge survives. A notch follows the accepted r2 water path and
## a corridor keeps the authored approach to the entrance clear.
## Render-only: no terrain, collision, actor, route, gate or camera change.
## Independent OFF flag; the r2 water (inherited _stream/_spray) is reused.
const KITBASH_CONFIG := "res://data/config/water_veilfall_crag_kitbash.json"
const CRAG_SHADER := preload("res://shaders/water_veilfall_crag.gdshader")
const TERRAIN_HEIGHT := preload("res://scripts/world/terrain_height.gd")

var _k: Dictionary
var _noise := FastNoiseLite.new()
var _water_w: PackedFloat32Array = []
var _water_y: PackedFloat32Array = []
var _pieces: Dictionary = {}
var _transforms: Dictionary = {}
var _realm: Node3D


static func enabled() -> bool:
	var cfg: Variant = JSON.parse_string(FileAccess.get_file_as_string(KITBASH_CONFIG))
	return cfg is Dictionary and bool(cfg.get("crag_kitbash_enabled", false))


func build(world: Node3D, veilfall: Node3D, preview: Dictionary = {}) -> void:
	var cfg: Variant = preview if not preview.is_empty() else JSON.parse_string(FileAccess.get_file_as_string(KITBASH_CONFIG))
	if not cfg is Dictionary or not bool(cfg.get("crag_kitbash_enabled", false)) or bool(world.get("simulation_only")):
		return
	_k = cfg
	# close-1024 `veilfall_family_candidate` (ON since rf1): the crown crags'
	# shader colours toward the shipped limestone, so the mountain is one rock family.
	var family: Dictionary = preload("res://scripts/world/tidewake_look_profile.gd").settings().get(
		"veilfall_family_candidate", {}).get("crag_kitbash", {})
	if not family.is_empty():
		_k = preload("res://scripts/world/tidewake_look_profile.gd").merge(_k, family)
	# F13#5: one reference-backed upper cliff candidate, using the same slot,
	# fitting, random sequence and near-entrance restore as its installed piece.
	var look := preload("res://scripts/world/tidewake_look_profile.gd").settings()
	var hero: Dictionary = look.get("veilfall_buttress", {})
	var slot := int(hero.get("pinnacle_index", -1))
	if bool(look.get("enabled", false)) and slot >= 0 and slot < _k.pinnacles.size():
		_k = _k.duplicate(true)
		_k.pieces["hero_buttress"] = {"path": str(hero.model)}
		_k.pinnacles[slot]["piece"] = "hero_buttress"
	_realm = world
	# The accepted r2 water geometry and frame come from its own config.
	_cfg = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	# Same r2 water material and builder; the path may be smoothed into one
	# continuous cascade (no flat runs that read as horizontal seams).
	if _k.has("water_path_override"):
		_cfg.water_path = _k.water_path_override
		_cfg.spray = _k.get("spray_override", _cfg.spray)
	for row: Dictionary in _cfg.water_path:
		_water_w.append(float(row.at[2]))
		_water_y.append(float(row.at[1]))
	_noise.seed = int(_k.seed)
	_noise.frequency = 1.0 / float(_k.outline_noise_period_m)
	_noise.fractal_octaves = 3
	for id: String in _k.pieces:
		var spec: Dictionary = _k.pieces[id]
		var mesh := _load_mesh(str(spec.path))
		if mesh == null:
			push_error("Veilfall kitbash missing installed piece " + str(spec.path))
			return
		_pieces[id] = {"mesh": mesh, "aabb": mesh.get_aabb()}
		_transforms[id] = []
	var material := ShaderMaterial.new()
	material.shader = CRAG_SHADER
	_apply_shader(material, _k.crag_shader)
	material.set_shader_parameter("rock_albedo", load(str(_k.rock_texture)))
	preload("res://scripts/world/tidewake_material_family.gd").shader(material, "stone")
	_place(world)
	for id: String in _pieces:
		_multimesh(id, material)
	var core := material.duplicate() as ShaderMaterial
	core.set_shader_parameter("crevice_darken", float(_k.core_darken))
	core.set_shader_parameter("far_lift_m", float(_k.core_far_lift_m))
	_core(world, core)
	# The entrance curtain stays for the player near it, but from a distance
	# it read as a flat white card on the crag face: limit its draw range.
	var passage := veilfall.get_node_or_null("WaterfallPassage")
	if passage != null:
		for child: Node in passage.get_children():
			if child is MeshInstance3D:
				_ranged[child] = [(child as MeshInstance3D).visibility_range_end, float(_k.curtain_visible_to_m)]
				(child as MeshInstance3D).visibility_range_end = float(_k.curtain_visible_to_m)
	for path: String in _k.get("near_only_nodes", []):
		var near := veilfall.get_node_or_null(path) as Node3D
		if near != null:
			for child: Node in near.find_children("*", "GeometryInstance3D", true, false):
				_ranged[child] = [(child as GeometryInstance3D).visibility_range_end, float(_k.near_only_range_m)]
				(child as GeometryInstance3D).visibility_range_end = float(_k.near_only_range_m)
	for path: String in _k.hide_nodes:
		var previous := veilfall.get_node_or_null(path) as Node3D
		if previous != null:
			previous.visible = false
	var water := ShaderMaterial.new()
	water.shader = FALL_SHADER
	_apply_shader(water, _cfg.water_shader)
	water.set_shader_parameter("centre_xz", Vector2(float(_cfg.centre_xz[0]), float(_cfg.centre_xz[1])))
	_stream(water)
	var mist := ShaderMaterial.new()
	mist.shader = SPRAY_SHADER
	_apply_shader(mist, _cfg.mist_shader)
	_spray(mist)
	var far := veilfall.get_node_or_null("VeilfallFarSilhouette")
	if far != null:
		for fogged: ShaderMaterial in [water, mist, material, core]:
			far.call("register_fogged", fogged)
	_near_restore_setup(veilfall)


## Net-improvement guard: near the entrance the kitbash gave the close
## cascade view a dark slab and closed the lit passage. Inside
## `near_restore_m` of the entrance everything this pass changed is undone
## (own geometry hidden, hidden nodes shown, draw ranges restored), so the
## close view renders exactly as with the flag off.
var _restore_anchor: Node3D
var _restored := false
var _hidden_previous: Array[Node3D] = []
var _ranged: Dictionary = {}


func _near_restore_setup(veilfall: Node3D) -> void:
	_restore_anchor = veilfall.get_node_or_null("WaterfallPassage") as Node3D
	if _restore_anchor == null or float(_k.get("near_restore_m", 0.0)) <= 0.0:
		return
	for path: String in _k.hide_nodes:
		var previous := veilfall.get_node_or_null(path) as Node3D
		if previous != null:
			_hidden_previous.append(previous)
	set_process(true)


func _process(_delta: float) -> void:
	if _restore_anchor == null:
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var offset := camera.global_position - _restore_anchor.global_position
	var distance := Vector2(offset.x, offset.z).length()
	var radius := float(_k.near_restore_m)
	var near := distance < radius if not _restored else distance < radius + float(_k.near_restore_hysteresis_m)
	if near == _restored:
		return
	_restored = near
	for child: Node in get_children():
		if child is Node3D:
			(child as Node3D).visible = not near
	for previous: Node3D in _hidden_previous:
		previous.visible = near
	for instance: GeometryInstance3D in _ranged:
		if is_instance_valid(instance):
			var ranges: Array = _ranged[instance]
			instance.visibility_range_end = float(ranges[0]) if near else float(ranges[1])


## The r2 water as only its viewer-facing half-sheet (outward on drops, up on
## shelves). The full translucent tube showed its back faces through the
## front at every bend as bright horizontal rings.
func _stream(material: ShaderMaterial) -> void:
	var path: Array = _cfg.water_path
	var lengths: Array[float] = [0.0]
	for i in range(1, path.size()):
		lengths.append(lengths[-1] + _point(path[i].at).distance_to(_point(path[i - 1].at)))
	var across := Vector3(float(_cfg.across_xz[0]), 0.0, float(_cfg.across_xz[1]))
	var sides := int(_k.get("water_sheet_sides", 6))
	var rings: Array = []
	for i in path.size():
		var centre := _point(path[i].at)
		var tangent := (_point(path[mini(i + 1, path.size() - 1)].at) - _point(path[maxi(0, i - 1)].at)).normalized()
		var depth := across.cross(tangent).normalized()
		var ring: Array = []
		for j in sides + 1:
			var angle := PI * float(j) / float(sides)
			var side := cos(angle)
			ring.append({"at": centre + across * side * float(path[i].width_m) * 0.5 + depth * sin(angle) * float(_cfg.water_thickness_m) * 0.5, "uv": Vector2((side + 1.0) * 0.5, lengths[i]), "remaining": lengths[-1] - lengths[i]})
		rings.append(ring)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1, rings.size()):
		for j in sides:
			_water_triangle(surface, rings[i - 1][j], rings[i][j], rings[i][j + 1], across, float(path[i].width_m))
			_water_triangle(surface, rings[i - 1][j], rings[i][j + 1], rings[i - 1][j + 1], across, float(path[i].width_m))
	_mesh("ConnectedLipLedgePlunge", surface, material)


func piece_count() -> int:
	var total := 0
	for id: String in _transforms:
		total += (_transforms[id] as Array).size()
	return total


static func _apply_shader(material: ShaderMaterial, values: Dictionary) -> void:
	for key: String in values:
		if key.begins_with("_"):
			continue
		var value: Variant = values[key]
		material.set_shader_parameter(key, Color(str(value)) if value is String else value)


static func _load_mesh(path: String) -> Mesh:
	var resource := load(path)
	if resource is Mesh:
		return resource
	if resource is PackedScene:
		var node := (resource as PackedScene).instantiate()
		var found := node.find_children("*", "MeshInstance3D", true, false)
		var mesh: Mesh = (node as MeshInstance3D).mesh if node is MeshInstance3D else null
		if mesh == null and not found.is_empty():
			mesh = (found[0] as MeshInstance3D).mesh
		node.free()
		return mesh
	return null


## Massif height (metres above sea) at a local (across, outward) point, before
## the water notch. Bodies are noisy-outlined mesas; max() joins them.
func _massif(u: float, w: float) -> float:
	var height := 0.0
	for body: Dictionary in _k.bodies:
		var dx := (u - float(body.centre[0])) / float(body.radii[0])
		var dz := (w - float(body.centre[1])) / float(body.radii[1])
		var d := sqrt(dx * dx + dz * dz)
		d *= 1.0 + float(_k.outline_noise_amount) * _noise.get_noise_2d(u + float(body.centre[0]) * 3.0, w)
		if d >= 1.0:
			continue
		var shoulder := float(body.shoulder)
		var rise := clampf((1.0 - d) / maxf(0.01, 1.0 - shoulder), 0.0, 1.0)
		var top := float(body.top) * (1.0 + float(_k.top_noise_amount) * _noise.get_noise_2d(u * 1.7 + 500.0, w * 1.7))
		height = maxf(height, top * pow(rise, float(body.power)))
	var step := float(_k.terrace_step_m)
	if step > 0.0 and height > step:
		var stepped := floorf(height / step) * step + step * pow(fposmod(height, step) / step, 4.0)
		height = lerpf(height, stepped, float(_k.terrace_blend))
	return height


## Half the accepted water's own width at this outward distance.
func _water_half_width(w: float) -> float:
	var path: Array = _cfg.water_path
	if w <= _water_w[0]:
		return float(path[0].width_m) * 0.5
	for index in range(1, _water_w.size()):
		if w <= _water_w[index]:
			var t := (w - _water_w[index - 1]) / maxf(0.001, _water_w[index] - _water_w[index - 1])
			return lerpf(float(path[index - 1].width_m), float(path[index].width_m), t) * 0.5
	return float(path[-1].width_m) * 0.5


func _water_cap(w: float) -> float:
	if w < float(_k.notch_start_outward_m):
		return INF
	if w <= _water_w[0]:
		return _water_y[0]
	for index in range(1, _water_w.size()):
		if w <= _water_w[index]:
			var t := (w - _water_w[index - 1]) / maxf(0.001, _water_w[index] - _water_w[index - 1])
			return lerpf(_water_y[index - 1], _water_y[index], t)
	return -INF


## Height the crag may reach at (u, w): massif with the water gorge and the
## authored approach corridor carved out.
func _target(u: float, w: float) -> float:
	var height := _massif(u, w)
	# Mantle: every steep (unwalkable) part of the cone is encrusted, so no
	# smooth cone surface survives between the bodies.
	if _realm != null:
		var ground := _ground(_realm, u, w)
		if ground > float(_k.mantle_min_ground_y):
			var relief := float(_k.mantle_relief_m) * (1.0 + 0.6 * _noise.get_noise_2d(u * 2.3 - 900.0, w * 2.3))
			# Radial buttress spurs: ridged angular noise, strongest mid-slope,
			# so the flanks break into ribs and the outline into shoulders.
			var r := Vector2(u, w).length()
			var angle := atan2(w, u)
			var ridge := 1.0 - absf(_noise.get_noise_2d(angle * float(_k.ridge_count) * 40.0, r * 0.35 + 300.0))
			ridge = pow(ridge, float(_k.ridge_sharpness))
			var band := smoothstep(float(_k.ridge_inner_m), float(_k.ridge_inner_m) + 60.0, r) * (1.0 - smoothstep(float(_k.ridge_outer_m) - 50.0, float(_k.ridge_outer_m), r))
			relief += ridge * band * float(_k.ridge_height_m)
			height = maxf(height, ground + relief * smoothstep(float(_k.mantle_min_ground_y), float(_k.mantle_full_ground_y), ground))
		var step := float(_k.ledge_step_m)
		if step > 0.0 and height > ground + 4.0:
			var stepped := floorf(height / step) * step + step * pow(fposmod(height, step) / step, 5.0)
			# Cover tapers toward the shore so the base flares into a skirt
			# instead of standing as vertical walls on the beach.
			var cover := minf(float(_k.mantle_min_cover_m), ground * float(_k.mantle_cover_per_m)) if ground > float(_k.mantle_min_ground_y) else 3.0
			height = maxf(ground + cover, lerpf(height, stepped, float(_k.ledge_blend)))
	var from_falls := absf(u - float(_cfg.water_path[0].at[0]))
	var half := _water_half_width(w) + float(_k.notch_half_width_m)
	if from_falls < half + float(_k.notch_bank_m):
		var cap := _water_cap(w) - float(_k.notch_clearance_m)
		var bank := smoothstep(half, half + float(_k.notch_bank_m), from_falls)
		if cap == -INF:
			# Past the plunge: nothing may stand in front of the falling water.
			height = height if bank > 0.99 else 0.0
		elif cap != INF:
			height = minf(height, lerpf(cap, height, bank))
	for corridor: Dictionary in _k.clear_corridors:
		var a := Vector2(float(corridor.from[0]), float(corridor.from[1]))
		var b := Vector2(float(corridor.to[0]), float(corridor.to[1]))
		var p := Vector2(u, w)
		var t := clampf((p - a).dot(b - a) / maxf(0.001, (b - a).length_squared()), 0.0, 1.0)
		if p.distance_to(a.lerp(b, t)) < float(corridor.radius_m):
			return 0.0
	return height


func _world(u: float, w: float) -> Vector2:
	var across := Vector2(float(_cfg.across_xz[0]), float(_cfg.across_xz[1]))
	var outward := Vector2(float(_cfg.outward_xz[0]), float(_cfg.outward_xz[1]))
	return Vector2(float(_cfg.centre_xz[0]), float(_cfg.centre_xz[1])) + across * u + outward * w


func _ground(world: Node3D, u: float, w: float) -> float:
	var xz := _world(u, w)
	# Raw terrain: world.ground_height_at answers with the Veilfall interior's
	# built floors under the mountain first, which sank the skin below the
	# visible slope along those footprints.
	var terrain: Variant = world.get("terrain")
	var y := float(TERRAIN_HEIGHT.height_at(terrain, xz.x, xz.y)) if terrain != null else float(world.call("ground_height_at", xz.x, xz.y))
	return y if is_finite(y) else -8.0


func _place(world: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_k.seed)
	var g := float(_k.grid_m)
	var extent: Array = _k.extent_m
	var u := float(extent[0])
	while u <= float(extent[1]):
		var w := float(extent[2])
		while w <= float(extent[3]):
			var pu := u + rng.randf_range(-0.35, 0.35) * g
			var pw := w + rng.randf_range(-0.35, 0.35) * g
			_column(world, rng, pu, pw, g)
			w += g
		u += g
	for pinnacle: Dictionary in _k.pinnacles:
		var at: Array = pinnacle.at
		var base := _target(float(at[0]), float(at[1]))
		if base <= 0.0:
			continue
		_add(str(pinnacle.piece), float(at[0]), float(at[1]), base - float(pinnacle.sink_m), float(pinnacle.width_m), float(pinnacle.height_m), rng)


func _footprint_target(u: float, w: float, radius: float) -> float:
	var top := _target(u, w)
	var reach := radius * 0.7
	for offset: Vector2 in [Vector2(reach, 0), Vector2(-reach, 0), Vector2(0, reach), Vector2(0, -reach)]:
		top = minf(top, _target(u + offset.x, w + offset.y) + radius * 0.6)
	return top


func _corridor_distance(u: float, w: float) -> float:
	var nearest := INF
	for corridor: Dictionary in _k.clear_corridors:
		var a := Vector2(float(corridor.from[0]), float(corridor.from[1]))
		var b := Vector2(float(corridor.to[0]), float(corridor.to[1]))
		var p := Vector2(u, w)
		var t := clampf((p - a).dot(b - a) / maxf(0.001, (b - a).length_squared()), 0.0, 1.0)
		nearest = minf(nearest, p.distance_to(a.lerp(b, t)) - float(corridor.radius_m))
	return nearest


func _column(world: Node3D, rng: RandomNumberGenerator, u: float, w: float, g: float) -> void:
	var radius := g * rng.randf_range(0.55, 0.8)
	# Beside the walk corridor, smaller pieces stand right up to its edge
	# instead of leaving a wide band of bare slope.
	var clear := _corridor_distance(u, w)
	if clear < radius:
		if clear < float(_k.corridor_min_piece_m):
			return
		radius = clear
	var top := _footprint_target(u, w, radius)
	var ground := _ground(world, u, w)
	# Nothing stands on open sea: only where the crag itself rises.
	if top < float(_k.min_crag_top_m) or Vector2(u, w).length() > float(_k.max_radius_m):
		return
	if top - ground < float(_k.min_relief_m):
		_talus(rng, u, w, ground, g)
		return
	# Only the exposed part of a column is built: a neighbour that stands as
	# tall hides this one's flank, and the inset core fills any crevice.
	var lowest := top
	for offset: Vector2 in [Vector2(g, 0), Vector2(-g, 0), Vector2(0, g), Vector2(0, -g), Vector2(g, g) * 0.7, Vector2(-g, g) * 0.7, Vector2(g, -g) * 0.7, Vector2(-g, -g) * 0.7]:
		lowest = minf(lowest, maxf(_target(u + offset.x, w + offset.y), _ground(world, u + offset.x, w + offset.y)))
	# Every column is rooted in the ground: no piece overhangs empty air.
	var bottom := ground - float(_k.footing_sink_m) if bool(_k.root_columns) else maxf(ground - float(_k.footing_sink_m), lowest - g * 0.9)
	var slope := (top - lowest) / g
	var cap_height := 0.0
	if slope < float(_k.ledge_slope_max):
		# Shelf or crown: a broad boulder cap, sometimes a pinnacle.
		var cap_width := minf(g * rng.randf_range(0.95, 1.3), radius * 2.0)
		cap_height = cap_width * rng.randf_range(0.35, 0.6)
		var piece := "boulder_%d" % rng.randi_range(1, 3)
		if top > float(_k.pinnacle_min_y) and rng.randf() < float(_k.pinnacle_chance):
			_add("pinnacle", u, w, top - cap_height * 0.5, g * rng.randf_range(0.5, 0.8), g * rng.randf_range(1.0, 1.8), rng)
		_add(piece, u, w, top - cap_height, cap_width, cap_height * 1.15, rng)
	# Fluted columns stacked from the cap down to the exposed bottom.
	var y := top - cap_height * 0.6
	var guard := 0
	while y > bottom and guard < 40:
		var width := minf(g * rng.randf_range(1.15, 1.75), radius * 2.2)
		var height := width * rng.randf_range(1.2, 2.4)
		var piece := "spire_%d" % rng.randi_range(1, 3)
		# Near the foot a lone pointed spire read as a regular saw-tooth row
		# along the island base: only boulders there.
		if rng.randf() < float(_k.boulder_column_share) or y - height < ground + float(_k.spire_min_above_ground_m):
			# Rounded installed boulders stood tall break the boxy column read.
			piece = "boulder_%d" % rng.randi_range(1, 3)
			height = width * rng.randf_range(0.9, 1.6)
		_add(piece, u + rng.randf_range(-0.15, 0.15) * g, w + rng.randf_range(-0.15, 0.15) * g, y - height, width, height, rng)
		y -= height * float(_k.stack_step)
		guard += 1


func _talus(rng: RandomNumberGenerator, u: float, w: float, ground: float, g: float) -> void:
	if ground < float(_k.talus_min_y) or rng.randf() > float(_k.talus_chance):
		return
	if _target(u, w) <= 0.0 and _massif(u, w) > 0.0:
		return
	for corridor: Dictionary in _k.clear_corridors:
		var a := Vector2(float(corridor.from[0]), float(corridor.from[1]))
		var b := Vector2(float(corridor.to[0]), float(corridor.to[1]))
		var p := Vector2(u, w)
		var t := clampf((p - a).dot(b - a) / maxf(0.001, (b - a).length_squared()), 0.0, 1.0)
		if p.distance_to(a.lerp(b, t)) < float(corridor.radius_m) + g:
			return
	var width := g * rng.randf_range(0.6, 1.1)
	_add("boulder_%d" % rng.randi_range(1, 3), u, w, ground - width * 0.25, width, width * rng.randf_range(0.4, 0.7), rng)


## Place one installed piece so its AABB spans [bottom, bottom + height] in Y
## and `width` across, randomly turned and leaned.
func _add(id: String, u: float, w: float, bottom: float, width: float, height: float, rng: RandomNumberGenerator) -> void:
	var aabb: AABB = _pieces[id].aabb
	var scale := Vector3(width * rng.randf_range(0.8, 1.25) / maxf(0.01, aabb.size.x), height / maxf(0.01, aabb.size.y), width * rng.randf_range(0.7, 1.3) / maxf(0.01, aabb.size.z))
	var lean := deg_to_rad(float(_k.lean_deg))
	if id.begins_with("boulder"):
		# Blobby boulders read best tumbled freely; no repeated facing.
		lean = deg_to_rad(float(_k.boulder_tumble_deg))
	var basis := Basis.from_euler(Vector3(rng.randf_range(-lean, lean), rng.randf() * TAU, rng.randf_range(-lean, lean))) * Basis.from_scale(scale)
	var xz := _world(u, w)
	var centre := aabb.get_center()
	var origin := Vector3(xz.x, bottom + height * 0.5, xz.y) - basis * centre
	(_transforms[id] as Array).append(Transform3D(basis, origin))


func _multimesh(id: String, material: Material) -> void:
	var rows: Array = _transforms[id]
	if rows.is_empty():
		return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = _pieces[id].mesh
	multimesh.instance_count = rows.size()
	for index in rows.size():
		multimesh.set_instance_transform(index, rows[index])
	var instance := MultiMeshInstance3D.new()
	instance.name = "Crag_" + id
	instance.multimesh = multimesh
	instance.material_override = material
	add_child(instance)


## Inset heightfield under the pieces so gaps read as dark crevices, never sky.
func _core(world: Node3D, material: Material) -> void:
	var g := float(_k.core_grid_m)
	var extent: Array = _k.extent_m
	var columns := int((float(extent[1]) - float(extent[0])) / g) + 1
	var rows := int((float(extent[3]) - float(extent[2])) / g) + 1
	var heights: Array = []
	var far_only: Array = []
	var soft: Array = []
	var lifts: Array = []
	for i in columns:
		var line: Array[float] = []
		var far_line: Array[bool] = []
		var soft_line: Array[bool] = []
		var lift_line: Array[float] = []
		for j in rows:
			var u := float(extent[0]) + g * i
			var w := float(extent[2]) + g * j
			var ground := _ground(world, u, w)
			# Eroded (neighbourhood minimum) so interpolated core slopes stay
			# behind the column faces instead of bridging in front of them.
			var top := _target(u, w)
			var reach := float(_k.grid_m) * 0.7
			for offset: Vector2 in [Vector2(reach, 0), Vector2(-reach, 0), Vector2(0, reach), Vector2(0, -reach)]:
				top = minf(top, _target(u + offset.x, w + offset.y))
			top -= float(_k.core_inset_m)
			if top <= ground + 1.0:
				# Drape: steep bare cone outside the walk corridor wears the
				# same dark rock skin, so no smooth cone face reads between
				# pieces. Walkable low ground and the corridor stay terrain.
				var inside := Vector2(u, w).length() < float(_k.max_radius_m)
				var walk := _corridor_distance(u, w) <= 2.0
				var drape := ground > float(_k.drape_min_ground_y) and not walk and inside
				# The walk corridor gets a thin rock-path skin (a hand's depth),
				# so it reads as a worn ledge path, not a pale cone strip.
				var path := walk and ground > float(_k.path_skin_min_ground_y) and inside and w > float(_k.path_skin_from_outward_m)
				# Entrance stand and passage gorge: natural terrain up close,
				# a rock skin only from distance (separate far-only mesh).
				var gorge := walk and inside and not path and ground > float(_k.path_skin_min_ground_y)
				# Low open ground next to the drape: the drape's foot dips into
				# it, so its lower edge follows the terrain, not grid teeth.
				var fringe := not walk and inside and not drape and ground > float(_k.drape_fringe_min_ground_y)
				if drape:
					top = ground + float(_k.drape_offset_m)
				elif path or gorge:
					top = ground + float(_k.path_skin_offset_m)
				elif fringe:
					top = ground - float(_k.drape_fringe_sink_m)
				else:
					top = ground - 4.0
				far_line.append(gorge)
				soft_line.append(drape or fringe)
				lift_line.append(0.0 if fringe else 1.0)
			else:
				far_line.append(false)
				soft_line.append(true)
				lift_line.append(1.0)
			line.append(top)
		heights.append(line)
		far_only.append(far_line)
		soft.append(soft_line)
		lifts.append(lift_line)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var far_surface := SurfaceTool.new()
	far_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var far_count := 0
	for i in columns - 1:
		for j in rows - 1:
			var corners: Array[Vector3] = []
			var weights: Array[float] = []
			var raised := true
			var far := false
			var softened := true
			var any_up := false
			for c: Vector2i in [Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i + 1, j + 1), Vector2i(i, j + 1)]:
				var xz := _world(float(extent[0]) + g * c.x, float(extent[2]) + g * c.y)
				var y: float = heights[c.x][c.y]
				far = far or bool(far_only[c.x][c.y])
				# Only cells raised at every corner: a partly raised cell at a
				# cleared edge would draw a straight-edged dark slab.
				var up := y > _ground(world, float(extent[0]) + g * c.x, float(extent[2]) + g * c.y)
				raised = raised and up
				any_up = any_up or up
				softened = softened and bool(soft[c.x][c.y])
				corners.append(Vector3(xz.x, y, xz.y))
				weights.append(float(lifts[c.x][c.y]))
			# A partly raised cell is drawn only where drape meets open low
			# ground (it dips under the terrain there); never at a corridor.
			if not raised and not (softened and any_up):
				continue
			var target_surface := far_surface if far else surface
			far_count += 1 if far else 0
			_lift_triangle(target_surface, [corners[0], corners[1], corners[2]], [weights[0], weights[1], weights[2]])
			_lift_triangle(target_surface, [corners[0], corners[2], corners[3]], [weights[0], weights[2], weights[3]])
	var mesh := MeshInstance3D.new()
	mesh.name = "CragCore"
	mesh.mesh = surface.commit()
	mesh.material_override = material
	add_child(mesh)
	if far_count > 0:
		var far_mesh := MeshInstance3D.new()
		far_mesh.name = "CragGorgeFarSkin"
		# Visibility range is measured from the node, so place the node at the
		# skin's own centre and express its vertices relative to it.
		var arrays := far_surface.commit_to_arrays()
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var centre := Vector3.ZERO
		for v: Vector3 in vertices:
			centre += v
		centre /= float(maxi(1, vertices.size()))
		for k in vertices.size():
			vertices[k] -= centre
		arrays[Mesh.ARRAY_VERTEX] = vertices
		var far_array_mesh := ArrayMesh.new()
		far_array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		far_mesh.mesh = far_array_mesh
		far_mesh.position = centre
		far_mesh.material_override = material
		far_mesh.visibility_range_begin = float(_k.gorge_skin_visible_from_m)
		add_child(far_mesh)


## Core triangle facing up; vertex colour red carries the far-lift weight
## (0 on the fringe that dips under open ground, so the distance lift that
## keeps the skin above Terrain3D's distant LOD does not raise its foot back
## out of the terrain as a stepped edge).
static func _lift_triangle(surface: SurfaceTool, points: Array, weights: Array) -> void:
	var a: Vector3 = points[0]
	var b: Vector3 = points[1]
	var c: Vector3 = points[2]
	var wb: float = weights[1]
	var wc: float = weights[2]
	var normal := (b - a).cross(c - a)
	if normal.y < 0.0:
		var swap := b
		b = c
		c = swap
		wb = weights[2]
		wc = weights[1]
		normal = -normal
	var order := [[a, float(weights[0])], [b, wb], [c, wc]]
	for row: Array in order:
		var point: Vector3 = row[0]
		surface.set_normal(normal.normalized())
		surface.set_color(Color(float(row[1]), 1.0, 1.0, 1.0))
		surface.set_uv(Vector2(point.x, point.z))
		surface.add_vertex(point)
