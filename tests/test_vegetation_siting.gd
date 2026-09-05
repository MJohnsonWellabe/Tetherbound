extends "res://tests/test_case.gd"

## N02-VEGETATION-0905. Three gaps three separate 0904 lanes found in
## `scripts/world/vegetation.gd` and correctly left alone as outside their
## file ownership:
##
##  1. `PROP_OFFSET` was one constant standing a felled resource pile beside
##     placements whose own footprint spans a 10x range of scales
##     (W05-TREELINE-0904).
##  2. `has_solid_scatter_near()` saw only the COLLISION batches, so
##     non-colliding scatter -- shrubs, ferns, standing dead trees -- could
##     bury a pickup and still pass the site check (W18-DENSITY-B4-B5-0904).
##  3. `restore_drained(within)` landed with W20-SMALL-FIXES-0904 and had no
##     unit test at all; its empty-`within` case is the one arithmetic trap
##     that would silently turn the chapter-wide `legendary_freed` heal into
##     a no-op (W20-SMALL-FIXES-0904 / CL-E12).
##
## These run at the DATA level, the same way `test_harvest_permanence.gd`
## does and for the same reason: no live Terrain3D node is built, so a full
## mesh-loading `build()` is never paid for. Every method under test here
## either does not touch the instancer or is guarded against a null one.

const VEGETATION := preload("res://scripts/world/vegetation.gd")
const RULES := preload("res://scripts/world/scatter_rules.gd")


## `restore_drained()` calls `_build_batch()`, which needs a real
## Terrain3DAssets to get a mesh id and returns early without one -- so
## `_placed` would never move and the regrowth COUNT could not be observed.
## Overriding the render call is the whole point: what these tests are about
## is the partition/filter/accumulate arithmetic around it, not the
## instancer, which `smoke_relay_station.gd` already drives for real.
class CountingVegetation extends "res://scripts/world/vegetation.gd":
	var batches: Array[String] = []

	func _build_batch(model_path: String, placements: Array) -> void:
		batches.append(model_path)
		_placed += placements.size()


func _veg() -> Node3D:
	return VEGETATION.new()


func _layer(name: String) -> Dictionary:
	return (RULES.config().get("layers", {}) as Dictionary).get(name, {})


## One placement of `layer`'s first model, in the shape `scatter_rules.gd`
## returns and every consumer in `vegetation.gd` reads.
func _placement(layer_name: String, scale: float, at := Vector3.ZERO) -> Dictionary:
	var layer := _layer(layer_name)
	var models: Array = layer.get("models", [])
	return {
		"model": str(models[0]) if not models.is_empty() else "",
		"position": at,
		"scale": scale,
		"yaw": 0.0,
	}


# --- 1. PROP_OFFSET: the felled pile stands clear of what it came from ------


## The invariant the constant was written for, checked against the OTHER
## function that decides the same placement's real footprint rather than
## against a number retyped from the config: `_make_collision_shape()` builds
## the trunk/boulder collider at `collision_radius` x scale, and the pile has
## to stand outside that. On `main` at f8a47ee4 this failed for a `rocks`
## anchor (offset 1.30 m against a 2.61 m collider) and stood within 0.04 m
## of failing for a `trees` hero (1.30 against 1.26).
func test_prop_offset_clears_the_collider_of_the_thing_it_was_felled_from() -> void:
	var veg := _veg()
	for probe: Array in [
		["trees", 2.1],   # trees.heroes scale_max
		["rocks", 2.9],   # rocks.anchors scale_max
		["grove", 1.35],  # grove.heroes scale_max
		["trees", 0.5],   # trees.scale_min -- the small end must still clear
		["saplings", 0.25],
	]:
		var layer_name := str(probe[0])
		var scale := float(probe[1])
		var placement := _placement(layer_name, scale)
		var radius := float(_layer(layer_name).get("collision_radius", 0.5))
		var shape: CollisionShape3D = veg.call("_make_collision_shape", placement, radius)
		var collider := float((shape.shape as CylinderShape3D).radius)
		var offset := float(veg.call("_prop_offset_for", placement))
		assert_true(offset > collider,
			"%s at scale %.2f: pile at %.2f m is inside a %.2f m collider"
				% [layer_name, scale, offset, collider])
		shape.free()
	veg.free()


## The floor holds, so nothing that already cleared its placement moves.
## `collision_radius` x scale + `PROP_CLEARANCE` <= `PROP_OFFSET` up to scale
## 1.17 for `trees` and 0.78 for `rocks`; below that the pile lands on exactly
## the distance it landed on before this change.
func test_prop_offset_never_shrinks_below_the_old_constant() -> void:
	var veg := _veg()
	var floor_m := float(VEGETATION.PROP_OFFSET)
	for probe: Array in [["trees", 0.25], ["trees", 0.5], ["trees", 0.9], ["trees", 1.1],
		["rocks", 0.28], ["rocks", 0.7], ["saplings", 0.5]]:
		var offset := float(veg.call("_prop_offset_for", _placement(str(probe[0]), float(probe[1]))))
		assert_almost_eq(offset, floor_m, 0.0001,
			"%s at scale %.2f should still take the floor" % [probe[0], probe[1]])
	veg.free()


func test_prop_offset_grows_with_the_placements_own_scale() -> void:
	var veg := _veg()
	var small := float(veg.call("_prop_offset_for", _placement("rocks", 1.0)))
	var big := float(veg.call("_prop_offset_for", _placement("rocks", 2.9)))
	assert_true(big > small, "a scale-2.9 boulder must push its rubble further out than a scale-1.0 one")
	assert_almost_eq(big,
		float(_layer("rocks").get("collision_radius", 0.5)) * 2.9 + float(VEGETATION.PROP_CLEARANCE),
		0.0001)
	veg.free()


## `bushes` is harvestable (`harvest_fraction` 0.2) and non-colliding, so it
## has no authored footprint to derive from and must take the floor rather
## than fall through to some default radius.
func test_prop_offset_for_a_non_colliding_layer_is_the_floor() -> void:
	var veg := _veg()
	assert_almost_eq(float(veg.call("_prop_offset_for", _placement("bushes", 1.0))),
		float(VEGETATION.PROP_OFFSET), 0.0001)
	assert_almost_eq(float(veg.call("_prop_offset_for", {"model": "res://nope.glb", "scale": 9.0})),
		float(VEGETATION.PROP_OFFSET), 0.0001)
	veg.free()


# --- 2. has_solid_scatter_near sees non-colliding scatter -------------------


func _record(veg: Node3D, layer_name: String, scale: float, at: Vector3) -> void:
	veg.call("_record_soft_occluders", str(_placement(layer_name, scale).get("model")),
		_layer(layer_name), [_placement(layer_name, scale, at)])


## The W18 case, in miniature: nothing collidable anywhere near, a standing
## dead tree right there, and a site check that used to call the spot clear.
## `deadfall`'s `DeadTree_*` meshes are 5.7-6.4 m across, so at the layer's
## realised scale a pickup 2.5 m from one is under its canopy.
func test_a_standing_dead_tree_counts_as_solid_scatter() -> void:
	var veg := _veg()
	assert_false(bool(veg.call("has_solid_scatter_near", Vector3(2.5, 0.0, 0.0), 0.0)),
		"nothing has been recorded yet; the query must start clear")
	_record(veg, "deadfall", 0.805, Vector3.ZERO)  # base_scale 0.7 x scale_max 1.15
	assert_true(bool(veg.call("has_solid_scatter_near", Vector3(2.0, 0.0, 0.0), 0.0)),
		"a pickup 2.0 m from a full-size dead tree is under it")
	assert_true(bool(veg.call("has_solid_scatter_near", Vector3(2.5, 0.0, 0.0), 0.5)),
		"and at band_pickups.gd's own margin it is not close either")
	assert_false(bool(veg.call("has_solid_scatter_near", Vector3(40.0, 0.0, 0.0), 0.0)),
		"the reach is the mesh's own footprint, not unbounded")
	veg.free()


## The generalisation must not loosen the bushes-only check it replaced: a
## small bush still reaches `SOFT_OCCLUDER_FLOOR_RADIUS`, not its own smaller
## measured span.
func test_a_small_bush_still_reaches_the_floor_radius() -> void:
	var veg := _veg()
	_record(veg, "bushes", 0.405, Vector3.ZERO)  # base_scale 0.9 x scale_min 0.45
	var floor_m := float(VEGETATION.SOFT_OCCLUDER_FLOOR_RADIUS)
	assert_true(bool(veg.call("has_solid_scatter_near", Vector3(floor_m - 0.1, 0.0, 0.0), 0.0)),
		"inside the floor radius must still read as occupied")
	assert_false(bool(veg.call("has_solid_scatter_near", Vector3(floor_m + 0.1, 0.0, 0.0), 0.0)))
	veg.free()


## The caller's own margin is added to the placement's reach, not swapped for
## it -- `band_pickups.gd` passes 1.6 m and `encounter_director.gd` 0.8 m.
func test_the_callers_margin_is_added_to_the_placements_own_reach() -> void:
	var veg := _veg()
	_record(veg, "bushes", 0.405, Vector3.ZERO)
	var floor_m := float(VEGETATION.SOFT_OCCLUDER_FLOOR_RADIUS)
	assert_false(bool(veg.call("has_solid_scatter_near", Vector3(floor_m + 1.0, 0.0, 0.0), 0.0)))
	assert_true(bool(veg.call("has_solid_scatter_near", Vector3(floor_m + 1.0, 0.0, 0.0), 1.6)))
	veg.free()


## Ground cover is NOT an occluder, and this is the assertion that keeps the
## fix from swallowing the whole meadow: grass, dry grass, flowers, clover
## mats and flat path stones are placed by the thousand and are the ground
## the player stands on. If any of them entered the list, every site in the
## chapter would read as occupied at `band_pickups.gd`'s 1.6 m margin.
func test_ground_cover_is_not_treated_as_an_occluder() -> void:
	var veg := _veg()
	for layer_name: String in ["grass", "drygrass", "flowers", "groundmat", "path_stones"]:
		_record(veg, layer_name, 1.0, Vector3.ZERO)
	assert_eq(int((veg.get("_soft_occluder_positions") as PackedVector3Array).size()), 0,
		"no ground-cover layer may enter the soft-occluder list")
	assert_false(bool(veg.call("has_solid_scatter_near", Vector3.ZERO, 1.6)))
	veg.free()


## Collidable layers are already covered by `_collision_batches`; recording
## them again here would double their reach and is not what the second list
## is for.
func test_collidable_layers_are_not_recorded_as_soft_occluders() -> void:
	var veg := _veg()
	for layer_name: String in ["trees", "grove", "rocks", "saplings"]:
		_record(veg, layer_name, 1.0, Vector3.ZERO)
	assert_eq(int((veg.get("_soft_occluder_positions") as PackedVector3Array).size()), 0)
	veg.free()


## The reach comes from the model's real bounding box, so a big mesh in the
## same layer reaches further than a small one at the same scale. `deadfall`
## carries both `DeadTree_*` (6.4 m across) and `Mushroom_Common` (0.78 m).
func test_the_reach_is_measured_from_the_models_own_bounding_box() -> void:
	var veg := _veg()
	var dead := float(veg.call("_model_footprint_radius",
		"res://assets/environment/stylized_nature/DeadTree_3.gltf"))
	var mushroom := float(veg.call("_model_footprint_radius",
		"res://assets/environment/stylized_nature/Mushroom_Common.gltf"))
	assert_between(dead, 2.5, 4.0, "DeadTree_3 is 6.39 x 6.43 m in X/Z; half of that is ~3.2 m")
	assert_between(mushroom, 0.2, 0.6, "Mushroom_Common is 0.56 x 0.78 m in X/Z")
	assert_true(dead > mushroom)
	assert_almost_eq(float(veg.call("_model_footprint_radius", "res://nope.glb")), 0.0, 0.0001,
		"a model that will not load must not invent a reach")
	veg.free()


# --- 3. restore_drained: the empty-`within` trap ----------------------------


func _drain(veg: Node3D, entries: Array) -> void:
	var held: Dictionary = {}
	for raw: Variant in entries:
		var placement: Dictionary = raw
		var layer_name := str(placement.get("layer", "trees"))
		if not held.has(layer_name):
			held[layer_name] = []
		(held[layer_name] as Array).append(placement)
	veg.set("_drained", held)


func _at(x: float, z: float) -> Dictionary:
	return {"model": "res://model_a.glb", "position": Vector3(x, 0.0, z), "scale": 1.0, "yaw": 0.0}


## THE TRAP. An empty `within` means "no filter", never "no discs". The
## chapter-wide `legendary_freed` sweep calls `restore_drained()` with no
## argument at all, and a partition that read an empty list as "matches
## nothing" would turn the whole ending's regrowth into a silent no-op while
## still returning cleanly.
func test_an_empty_within_heals_everything() -> void:
	var veg := CountingVegetation.new()
	_drain(veg, [_at(0.0, 0.0), _at(500.0, 0.0), _at(0.0, 3200.0)])
	assert_eq(int(veg.call("drained_count")), 3)
	assert_eq(int(veg.call("restore_drained")), 3, "the no-argument call must put all three back")
	assert_eq(int(veg.call("drained_count")), 0, "nothing may be left held after an unfiltered heal")
	assert_eq(int(veg.call("regrown_count")), 3)
	veg.free()


func test_an_empty_within_passed_explicitly_heals_everything_too() -> void:
	var veg := CountingVegetation.new()
	_drain(veg, [_at(0.0, 0.0), _at(500.0, 0.0)])
	assert_eq(int(veg.call("restore_drained", [])), 2)
	assert_eq(int(veg.call("drained_count")), 0)
	veg.free()


## `meadow_healing.gd::heal_stations()` hands down authored discs; only what
## a disc actually covers comes back, and the rest stays held for the
## chapter-wide sweep later.
func test_a_disc_heals_only_what_it_covers_and_holds_the_rest() -> void:
	var veg := CountingVegetation.new()
	_drain(veg, [_at(0.0, 0.0), _at(10.0, 0.0), _at(900.0, 0.0)])
	var discs: Array = [{"centre": Vector2(0.0, 0.0), "radius": 20.0}]
	assert_eq(int(veg.call("restore_drained", discs)), 2)
	assert_eq(int(veg.call("drained_count")), 1, "the far placement stays drained")
	# And the chapter-wide sweep afterwards still finds it.
	assert_eq(int(veg.call("restore_drained")), 1)
	assert_eq(int(veg.call("drained_count")), 0)
	veg.free()


## A disc that covers nothing must leave `_drained` exactly as it found it --
## the early-return path, which assigns `held` rather than clearing.
func test_a_disc_that_matches_nothing_holds_everything() -> void:
	var veg := CountingVegetation.new()
	_drain(veg, [_at(0.0, 0.0), _at(10.0, 0.0)])
	var discs: Array = [{"centre": Vector2(5000.0, 5000.0), "radius": 20.0}]
	assert_eq(int(veg.call("restore_drained", discs)), 0)
	assert_eq(int(veg.call("drained_count")), 2, "a miss must not drop the held placements")
	assert_eq(int(veg.call("restore_drained")), 2)
	veg.free()


## `_regrown` ACCUMULATES across repeated partial heals. Written as
## `_regrown = _placed - before` it would report only the last call's share,
## which is wrong the moment `heal_stations()` is called more than once in a
## session -- the relay console can be pressed at each of three stations.
func test_regrown_accumulates_across_partial_heals() -> void:
	var veg := CountingVegetation.new()
	_drain(veg, [_at(0.0, 0.0), _at(10.0, 0.0), _at(900.0, 0.0), _at(910.0, 0.0)])
	assert_eq(int(veg.call("restore_drained",
		[{"centre": Vector2(0.0, 0.0), "radius": 20.0}])), 2)
	assert_eq(int(veg.call("regrown_count")), 2)
	assert_eq(int(veg.call("restore_drained",
		[{"centre": Vector2(900.0, 0.0), "radius": 20.0}])), 2)
	assert_eq(int(veg.call("regrown_count")), 4,
		"two partial heals of two plants each is four plants back, not two")
	veg.free()


## The same accumulation, from the other side: a heal that places nothing
## must not reset a count an earlier heal already earned.
func test_a_heal_that_places_nothing_does_not_reset_the_count() -> void:
	var veg := CountingVegetation.new()
	_drain(veg, [_at(0.0, 0.0), _at(900.0, 0.0)])
	assert_eq(int(veg.call("restore_drained", [{"centre": Vector2(0.0, 0.0), "radius": 20.0}])), 1)
	assert_eq(int(veg.call("regrown_count")), 1)
	assert_eq(int(veg.call("restore_drained", [{"centre": Vector2(5000.0, 0.0), "radius": 5.0}])), 0)
	assert_eq(int(veg.call("regrown_count")), 1, "a heal that found nothing must not zero the total")
	veg.free()


## A disc with no radius is not a disc. It must not silently match the world.
func test_a_zero_radius_disc_matches_nothing() -> void:
	var veg := CountingVegetation.new()
	_drain(veg, [_at(0.0, 0.0)])
	assert_eq(int(veg.call("restore_drained", [{"centre": Vector2(0.0, 0.0), "radius": 0.0}])), 0)
	assert_eq(int(veg.call("drained_count")), 1)
	veg.free()


## Idempotent, as `restore_drained`'s own contract says: the second call is a
## no-op rather than a second placement of the same instances.
func test_a_second_unfiltered_heal_is_a_no_op() -> void:
	var veg := CountingVegetation.new()
	_drain(veg, [_at(0.0, 0.0), _at(10.0, 0.0)])
	assert_eq(int(veg.call("restore_drained")), 2)
	assert_eq(int(veg.call("restore_drained")), 0)
	assert_eq(int(veg.call("regrown_count")), 2)
	veg.free()
