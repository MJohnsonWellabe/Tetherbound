extends Node3D

## F13#5/F39 inhabited-dock candidate, built per dock by WaterDockDressing
## only under the OFF Tidewake look gate (`dock_village` in tidewake_look.json).
## Unlike the presentation-only dressing, these are buildings: each house keeps
## its recipe wall/roof colliders and stands off the departure line on dry,
## near-level ground. Props and paths have no collision. No interaction, actor,
## route, current or durable state changes.

var _prefabs: RefCounted = null


## F13#5/F39 candidate under the existing OFF Tidewake look gate: each dock
## gains a small fishing hamlet -- installed-kit cottages with slate roofs
## and working props -- so a landing reads as where people live, not a pier
## on empty sand. Spots are [side m, landward m] from the safe anchor on the
## dressing's side (negative side is the far side of the departure line);
## a spot is skipped unless its whole footprint is dry and near level. Houses
## keep their recipe walls/roof colliders; props have none. No interaction,
## actor, route, current or durable state changes.
func build_site(site: Node3D, world: Node3D, anchor: Dictionary, cfg: Dictionary, sign: float,
		dock_index: int, dressing: Node) -> void:
	var safe_raw: Array = anchor.get("safe_position", [])
	var shore_raw: Array = anchor.get("shore_position", [])
	if safe_raw.size() < 3 or shore_raw.size() < 3:
		return
	var safe := Vector2(float(safe_raw[0]), float(safe_raw[2]))
	var forward := (Vector2(float(shore_raw[0]), float(shore_raw[2])) - safe).normalized()
	var side := Vector2(-forward.y, forward.x) * sign
	var yaw := atan2(forward.x, forward.y)
	var layouts: Array = cfg.get("layouts", [])
	if layouts.is_empty():
		return
	var layout: Dictionary = layouts[dock_index % layouts.size()]
	if _prefabs == null:
		_prefabs = preload("res://scripts/world/building_prefabs.gd").new()
		if not bool(_prefabs.call("load_recipes")):
			push_error("water dock village: no building recipes")
			return
		var holder := Node3D.new()
		holder.name = "DockVillageTemplates"
		holder.visible = false
		add_child(holder)
		_prefabs.call("set_template_holder", holder)
	var min_y := float(cfg.get("min_ground_y_m", 0.8))
	var max_step := float(cfg.get("max_footprint_step_m", 1.0))
	var retint: Dictionary = cfg.get("retint", {})
	var keep_clear: Array = (cfg.get("keep_clear", []) as Array).duplicate()
	for raw: Variant in layout.get("houses", []):
		var spec := raw as Dictionary
		var prefab := str(spec.get("prefab", ""))
		var half: Array = spec.get("half_extent_m", [2.4, 3.4])
		var house_yaw := yaw + deg_to_rad(float(spec.get("yaw_deg", 0.0)))
		for spot: Variant in spec.get("spots", []):
			var offset := spot as Array
			var centre := safe + side * float(offset[0]) - forward * float(offset[1])
			var floor_y := _footprint_floor(dressing, world, centre, house_yaw, Vector2(float(half[0]), float(half[1])),
				min_y, max_step)
			if is_nan(floor_y) or _spot_blocked(world, centre, house_yaw,
					Vector2(float(half[0]), float(half[1])), floor_y, keep_clear):
				continue
			var model_path := str(spec.get("model", ""))
			var house: Node3D = _model_building(model_path, float(spec.get("height_m", 4.0))) \
				if not model_path.is_empty() else _prefabs.call("instantiate", prefab)
			if house == null:
				break
			house.name = "DockHouse_%s" % (prefab if model_path.is_empty() else model_path.get_file().get_basename())
			if model_path.is_empty() and not retint.is_empty():
				_prefabs.call("apply_retint", house, retint)
			# Later houses keep a lane between them (shape queries cannot see a
			# body added this frame).
			keep_clear.append([centre.x, centre.y, Vector2(float(half[0]), float(half[1])).length() + 1.5])
			house.position = Vector3(centre.x, floor_y, centre.y)
			house.rotation.y = house_yaw
			site.add_child(house)
			_house_grounding(dressing, site, world, centre, house_yaw, Vector2(float(half[0]), float(half[1])),
				safe, cfg.get("house_grounding", {}))
			var body := StaticBody3D.new()
			body.name = "DockHouseBody"
			house.add_child(body)
			var boxes: Array = _prefabs.call("colliders", prefab) if model_path.is_empty() \
				else [{"at": [0.0, float(house.get_meta("fit_height", 4.0)) * 0.5, 0.0],
					"size": [float(half[0]) * 1.6, float(house.get_meta("fit_height", 4.0)), float(half[1]) * 1.6]}]
			for box: Variant in boxes:
				var b := box as Dictionary
				var shape := CollisionShape3D.new()
				var bs := BoxShape3D.new()
				var size: Array = b.get("size", [1, 1, 1])
				var at: Array = b.get("at", [0, 0, 0])
				bs.size = Vector3(float(size[0]), float(size[1]), float(size[2]))
				shape.shape = bs
				shape.position = Vector3(float(at[0]), float(at[1]), float(at[2]))
				body.add_child(shape)
			break
	for raw: Variant in layout.get("props", []):
		var spec := raw as Dictionary
		var offset: Array = spec.get("at", [0.0, 0.0])
		var at := safe + side * float(offset[0]) - forward * float(offset[1])
		var ground := float(dressing.call("_ground", world, at))
		if ground < min_y - 0.6:
			continue
		var prop := dressing.call("_fit_height", str(spec.get("model", "")), float(spec.get("height_m", 1.0)), "DockVillageProp") as Node3D
		if prop == null:
			continue
		prop.position += Vector3(at.x, ground, at.y)
		prop.rotation.y = yaw + deg_to_rad(float(spec.get("yaw_deg", 0.0)))
		if spec.has("cloth_colour"):
			dressing.call("_recolour_material", prop, str(spec.get("cloth_material", "MI_Banner")), Color(str(spec.cloth_colour)))
		site.add_child(prop)
		if bool(spec.get("lamp", false)):
			var light := OmniLight3D.new()
			light.name = "DockVillageLamp"
			light.light_color = Color(str(cfg.get("lamp_colour", "#ffc98a")))
			light.light_energy = float(cfg.get("lamp_energy", 1.6))
			light.omni_range = float(cfg.get("lamp_range_m", 8.0))
			light.shadow_enabled = false
			light.position = Vector3(at.x, ground + float(spec.get("height_m", 1.0)) * 0.8, at.y)
			site.add_child(light)


## A worn paver path from the house door toward the landing and dune grass
## tufts at the wall corners, so a house is seated in the shore, not set on it.
func _house_grounding(dressing: Node, site: Node3D, world: Node3D, centre: Vector2, yaw: float, half: Vector2,
		landing: Vector2, cfg: Dictionary) -> void:
	if cfg.is_empty():
		return
	var back := Vector2(sin(yaw), cos(yaw))
	var right := Vector2(cos(yaw), -sin(yaw))
	var door := centre + back * (half.y + 0.9) + right * 0.6
	var to_landing := landing - door
	var spacing := float(cfg.get("paver_spacing_m", 1.9))
	var steps := mini(int(to_landing.length() / spacing), int(cfg.get("max_pavers", 8)))
	for i in steps:
		var at := door + to_landing.normalized() * spacing * float(i)
		var paver := dressing.call("_fit_box", str(cfg.get("paver_model", "")), Vector3(1.5, 0.08, 1.5), "DockPathPaver") as Node3D
		if paver == null:
			break
		paver.position += Vector3(at.x, float(dressing.call("_ground", world, at)) - 0.04, at.y)
		paver.rotation.y = atan2(to_landing.x, to_landing.y) + deg_to_rad(float((i * 37) % 23) - 11.0)
		site.add_child(paver)
	var tufts: Array = cfg.get("tuft_models", [])
	if tufts.is_empty():
		return
	var index := 0
	for u: float in [-1.0, 1.0]:
		for v: float in [-1.0, 1.0]:
			for k in 2:
				var at := centre + right * u * (half.x + 0.3 + 0.5 * k) + back * v * (half.y + 0.2 - 0.9 * k)
				var tuft := dressing.call("_fit_height", str(tufts[index % tufts.size()]), float(cfg.get("tuft_height_m", 0.8)) * (0.8 + 0.25 * k), "DockHouseTuft") as Node3D
				index += 1
				if tuft == null:
					continue
				tuft.position += Vector3(at.x, float(dressing.call("_ground", world, at)), at.y)
				tuft.rotation.y = float(index) * 1.7
				site.add_child(tuft)


## A reference-backed building model (Meshy, tb/meshy-props provenance) fitted
## uniformly to `height`, feet on its origin. Its collider is one box inside the
## authored footprint (`half_extent_m`), so a walker meets a wall, not a gap.
func _model_building(path: String, height: float) -> Node3D:
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("water dock village model missing: %s" % path)
		return null
	var model := packed.instantiate() as Node3D
	var bounds := preload("res://scripts/characters/render_bounds.gd").measure(model)
	if bounds.size.y <= 0.001:
		model.free()
		return null
	var holder := Node3D.new()
	var factor := height / bounds.size.y
	model.scale = Vector3.ONE * factor
	model.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
	holder.add_child(model)
	holder.set_meta("fit_height", height)
	return holder


## Lowest ground under a rotated footprint, or NAN when any sample is wet or
## the footprint steps more than `max_step` (a house never floats or buries).
func _footprint_floor(dressing: Node, world: Node3D, centre: Vector2, yaw: float, half: Vector2, min_y: float,
		max_step: float) -> float:
	var right := Vector2(cos(yaw), -sin(yaw))
	var back := Vector2(sin(yaw), cos(yaw))
	var low := INF
	var high := -INF
	for u: float in [-1.0, 0.0, 1.0]:
		for v: float in [-1.0, 0.0, 1.0]:
			var y := float(dressing.call("_ground", world, centre + right * half.x * u + back * half.y * v))
			low = minf(low, y)
			high = maxf(high, y)
	if low < min_y or high - low > max_step:
		return NAN
	return low - 0.05




## True when a house box (above the ground step) would overlap an existing
## collider -- a gate, camp, shrine or another house -- or a keep-clear circle.
func _spot_blocked(world: Node3D, centre: Vector2, yaw: float, half: Vector2, floor_y: float,
		keep_clear: Array) -> bool:
	for raw: Variant in keep_clear:
		var entry := raw as Array
		if centre.distance_to(Vector2(float(entry[0]), float(entry[1]))) < float(entry[2]) + half.length():
			return true
	var space := world.get_world_3d().direct_space_state if world.is_inside_tree() else null
	if space == null:
		return false
	var query := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(half.x * 2.0 + 1.0, 2.0, half.y * 2.0 + 1.0)
	query.shape = box
	query.transform = Transform3D(Basis(Vector3.UP, yaw), Vector3(centre.x, floor_y + 2.4, centre.y))
	return not space.intersect_shape(query, 1).is_empty()
