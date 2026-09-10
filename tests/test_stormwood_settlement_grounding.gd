extends "res://tests/test_case.gd"

## The Stormwood settlements use the production heightfield, prefab collider
## footprints and door metadata together. These checks fail if a building is
## moved without its pad, if a pad stops short of a real wall or doorway, or if
## a closed/openable shell is placed without the room behind it.

const HEIGHTFIELD := preload("res://scripts/world/stormwood_heightfield.gd")
const TERRAIN_PATH := "res://data/config/terrain_stormwood.json"
const SETTLEMENT_PATH := "res://data/config/stormwood_settlements.json"
const PREFAB_PATH := "res://data/config/building_prefabs.json"
## One millimetre is already far below the player capsule's contact margin and
## Terrain3D's serialized float precision at these elevations. Test the actual
## surface displacement in metres rather than requiring an implementation
## weight to be bit-identical to 1.0.
const SURFACE_TOLERANCE_M := 0.001

var terrain_config: Dictionary
var settlement_config: Dictionary
var prefabs: Dictionary
var pads: Dictionary
var worst_bilinear_error_m := 0.0
var worst_bilinear_label := ""


func before_each() -> void:
	terrain_config = _json(TERRAIN_PATH)
	settlement_config = _json(SETTLEMENT_PATH)
	prefabs = _json(PREFAB_PATH).get("prefabs", {})
	pads = {}
	worst_bilinear_error_m = 0.0
	worst_bilinear_label = ""
	for value: Variant in terrain_config.get("settlement_pads", []):
		if value is Dictionary:
			pads[str((value as Dictionary).get("id", ""))] = value


func test_every_enterable_structure_has_one_matching_pad_and_real_interior() -> void:
	var enterable := 0
	for value: Variant in settlement_config.get("structures", []):
		if not value is Dictionary:
			continue
		var structure := value as Dictionary
		var prefab_name := str(structure.get("prefab", ""))
		var recipe: Dictionary = prefabs.get(prefab_name, {})
		var door: Dictionary = recipe.get("door", {})
		var is_open_workshop := prefab_name == "workshop"
		if door.is_empty() and not is_open_workshop:
			continue
		enterable += 1
		var id := str(structure.get("id", ""))
		assert_true(pads.has(id), "%s has no terrain foundation pad" % id)
		if not pads.has(id):
			continue
		var pad := pads[id] as Dictionary
		assert_eq(pad.get("centre", []), structure.get("at", []), "%s pad moved away from its building" % id)
		assert_almost_eq(float(pad.get("yaw_deg", 999.0)), float(structure.get("yaw_deg", 0.0)), 0.001,
			"%s pad does not rotate with its building" % id)
		if not door.is_empty():
			assert_true(not str(structure.get("interior", "")).is_empty(),
				"%s has a real door but no interior behind it" % id)
			if str(structure.get("interior", "")) == "cottage":
				var room: Dictionary = recipe.get("room", {})
				assert_true(not room.is_empty(), "%s generic interior has no prefab floorplan" % id)
				if not room.is_empty():
					var support := _support_rect(recipe)
					assert_true(float(room.get("inner_half_w", 0.0)) > 0.0 \
							and float(room.get("inner_half_w", INF)) < float(support.max_x),
						"%s interior width does not fit behind its wall colliders" % id)
					assert_true(float(room.get("inner_half_d", 0.0)) > 0.0 \
							and float(room.get("inner_half_d", INF)) < float(support.max_z),
						"%s interior depth does not fit behind its wall colliders" % id)
		elif is_open_workshop:
			_validate_workshop_dressing(id, recipe)
	assert_eq(enterable, 9, "the authored Stormwood shelter/home/workshop census changed")
	assert_eq(pads.size(), enterable, "orphan pad or enterable building without a pad")


func test_real_collider_footprints_and_three_metre_approaches_are_flat() -> void:
	var field: RefCounted = HEIGHTFIELD.new(terrain_config)
	for value: Variant in settlement_config.get("structures", []):
		if not value is Dictionary:
			continue
		var structure := value as Dictionary
		var id := str(structure.get("id", ""))
		if not pads.has(id):
			continue
		var prefab_name := str(structure.get("prefab", ""))
		var recipe: Dictionary = prefabs[prefab_name]
		var pad := pads[id] as Dictionary
		var target := float(pad["height"])
		var support := _support_rect(recipe)
		assert_false(support.is_empty(), "%s has no ground-touching authored collider footprint" % id)
		if support.is_empty():
			continue

		for local in _grid(support):
			_assert_flat_point(field, structure, pad, local, target, "%s floor" % id)

		var door: Dictionary = recipe.get("door", {})
		var threshold := Vector2(0.0, float(support.max_z))
		if not door.is_empty():
			var door_at: Array = door.get("at", [0.0, 0.0, 0.0])
			threshold = Vector2(float(door_at[0]), float(door_at[2]))
		for distance in [0.0, 1.0, 2.0, 3.0]:
			_assert_flat_point(field, structure, pad, threshold + Vector2(0.0, distance), target,
				"%s approach %.0fm" % [id, distance])
	print("Stormwood baked-equivalent bilinear max error %.6fm at %s" % [
		worst_bilinear_error_m, worst_bilinear_label])


func test_pad_edges_blend_instead_of_forming_terrain_steps() -> void:
	for value: Variant in pads.values():
		var pad := value as Dictionary
		var min_value: Array = pad["inner_min"]
		var max_value: Array = pad["inner_max"]
		var mid_z := (float(min_value[1]) + float(max_value[1])) * 0.5
		var blend := float(pad["blend_m"])
		var edge := float(max_value[0])
		assert_almost_eq(HEIGHTFIELD.settlement_pad_weight_local(Vector2(edge, mid_z), pad), 1.0, 0.0001)
		assert_almost_eq(HEIGHTFIELD.settlement_pad_weight_local(Vector2(edge + blend * 0.5, mid_z), pad), 0.5, 0.0001)
		assert_almost_eq(HEIGHTFIELD.settlement_pad_weight_local(Vector2(edge + blend, mid_z), pad), 0.0, 0.0001)


func _assert_flat_point(field: RefCounted, structure: Dictionary, pad: Dictionary,
		local: Vector2, target: float, label: String) -> void:
	var centre_value: Array = structure["at"]
	var centre := Vector2(float(centre_value[0]), float(centre_value[1]))
	var yaw := deg_to_rad(float(structure.get("yaw_deg", 0.0)))
	var world := centre + local.rotated(-yaw)
	assert_almost_eq(HEIGHTFIELD.settlement_pad_weight(world.x, world.y, pad), 1.0, 0.0001,
		label + " lies outside its authored flat")
	assert_almost_eq(float(field.call("height_at", world.x, world.y)), target, 0.0001,
		label + " is not physically level")
	# The shipped terrain stores a 2m lattice and get_height() bilinearly
	# samples its four surrounding vertices. Reconstruct that exact physical
	# surface from the four heightfield samples the baker writes. Two rotated
	# corners can sit a few centimetres into the 10m smooth blend and therefore
	# have weights around 0.99985; the meaningful result is their sub-millimetre
	# height displacement, not whether the abstract weight equals 1.0.
	var x0 := floorf(world.x / 2.0) * 2.0
	var z0 := floorf(world.y / 2.0) * 2.0
	var vertices := [Vector2(x0, z0), Vector2(x0 + 2.0, z0),
		Vector2(x0, z0 + 2.0), Vector2(x0 + 2.0, z0 + 2.0)]
	var heights: Array[float] = []
	for vertex: Vector2 in vertices:
		var height := float(field.call("height_at", vertex.x, vertex.y))
		heights.append(height)
		assert_almost_eq(height, target, SURFACE_TOLERANCE_M,
			label + " baked vertex displaces the physical floor")
	var tx := (world.x - x0) * 0.5
	var tz := (world.y - z0) * 0.5
	var bilinear := lerpf(lerpf(heights[0], heights[1], tx),
		lerpf(heights[2], heights[3], tx), tz)
	var error := absf(bilinear - target)
	if error > worst_bilinear_error_m:
		worst_bilinear_error_m = error
		worst_bilinear_label = label
	assert_almost_eq(bilinear, target, SURFACE_TOLERANCE_M,
		label + " baked-equivalent bilinear surface displaces the physical floor")


func _support_rect(recipe: Dictionary) -> Dictionary:
	var out := {"min_x": INF, "max_x": -INF, "min_z": INF, "max_z": -INF}
	for value: Variant in recipe.get("colliders", []):
		if not value is Dictionary:
			continue
		var collider := value as Dictionary
		var at: Array = collider.get("at", [])
		var size: Array = collider.get("size", [])
		if at.size() < 3 or size.size() < 3:
			continue
		if float(at[1]) - float(size[1]) * 0.5 > 0.15:
			continue
		out.min_x = minf(float(out.min_x), float(at[0]) - float(size[0]) * 0.5)
		out.max_x = maxf(float(out.max_x), float(at[0]) + float(size[0]) * 0.5)
		out.min_z = minf(float(out.min_z), float(at[2]) - float(size[2]) * 0.5)
		out.max_z = maxf(float(out.max_z), float(at[2]) + float(size[2]) * 0.5)
	return {} if float(out.min_x) > float(out.max_x) else out


func _validate_workshop_dressing(id: String, recipe: Dictionary) -> void:
	var room: Dictionary = recipe.get("room", {})
	assert_true(not room.is_empty(), "%s workshop has no shared room dimensions" % id)
	if room.is_empty():
		return
	var half_w := float(room.get("inner_half_w", 0.0))
	var half_d := float(room.get("inner_half_d", 0.0))
	var clear_half := float(room.get("clear_aisle_w", 0.0)) * 0.5
	assert_true(clear_half >= 0.8, "%s workshop aisle is narrower than 1.6m" % id)
	var dressing: Array = room.get("dressing", [])
	assert_true(dressing.size() >= 3, "%s workshop has no readable work silhouettes" % id)
	for raw: Variant in dressing:
		if not raw is Dictionary:
			continue
		var prop := raw as Dictionary
		var at: Array = prop.get("at", [])
		var size: Array = prop.get("collision_size", [])
		assert_true(at.size() >= 2 and size.size() >= 3,
			"%s workshop dressing lacks measured bounds" % id)
		if at.size() < 2 or size.size() < 3:
			continue
		var yaw := deg_to_rad(float(prop.get("yaw_deg", 0.0)))
		var half_x := absf(cos(yaw)) * float(size[0]) * 0.5 \
			+ absf(sin(yaw)) * float(size[2]) * 0.5
		var half_z := absf(sin(yaw)) * float(size[0]) * 0.5 \
			+ absf(cos(yaw)) * float(size[2]) * 0.5
		var x := float(at[0])
		var z := float(at[1])
		assert_true(absf(x) - half_x >= clear_half,
			"%s %s intrudes into the 1.6m centre aisle" % [id, str(prop.get("model", "prop"))])
		assert_true(absf(x) + half_x <= half_w and absf(z) + half_z <= half_d,
			"%s %s extends through the workshop walls" % [id, str(prop.get("model", "prop"))])


func _grid(rect: Dictionary) -> Array[Vector2]:
	var cols := maxi(1, ceili((float(rect.max_x) - float(rect.min_x)) / 2.0))
	var rows := maxi(1, ceili((float(rect.max_z) - float(rect.min_z)) / 2.0))
	var out: Array[Vector2] = []
	for row in rows + 1:
		for col in cols + 1:
			out.append(Vector2(
				lerpf(float(rect.min_x), float(rect.max_x), float(col) / cols),
				lerpf(float(rect.min_z), float(rect.max_z), float(row) / rows)
			))
	return out


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
