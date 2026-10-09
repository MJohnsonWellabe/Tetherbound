extends "res://tests/test_case.gd"

## Named Stormwood fights keep baked trunk and rock colliders out of the
## resident's full idle/wander envelope (fitted body diagonal, 2 m idle motion,
## ordinary wander), read from the committed production scatter bake. This is
## the Glass Field approach guard applied to every named fight, so a forest
## re-bake cannot silently put a trunk inside an arena.
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const BAKE := preload("res://scripts/world/scatter_bake.gd")
const SCATTER := preload("res://scripts/world/stormwood_scatter.gd")
const REGION_SIZE := 512.0


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary


func _envelope(species_id: String, wander: float) -> float:
	var look: Dictionary = _json("res://data/creatures/species.json").species[species_id].placeholder
	var model := (load(str(look.model)) as PackedScene).instantiate() as Node3D
	var box := BOUNDS.measure(model)
	model.free()
	var fit := minf(float(look.height) / box.size.y, float(look.radius) * 2.0 * float(look.footprint_allowance) / maxf(box.size.x, box.size.z))
	var half_x := maxf(absf(box.position.x), absf(box.end.x)) * fit
	var half_z := maxf(absf(box.position.z), absf(box.end.z)) * fit
	return Vector2(half_x, half_z).length() + 2.0 + wander


func _nearest_baked_collider(at: Vector2, reach: float) -> float:
	var config := SCATTER.config()
	var layers := {}
	var drained := {}
	var regions := {}
	for corner: Vector2 in [at + Vector2(-reach, -reach), at + Vector2(reach, -reach), at + Vector2(-reach, reach), at + Vector2(reach, reach)]:
		regions[BAKE.region_of(corner, REGION_SIZE)] = true
	for region: Vector2i in regions:
		var file := FileAccess.open("res://data/scatter/stormwood/region_%d_%d.bin" % [region.x, region.y], FileAccess.READ)
		if file != null:
			BAKE._read_region(file, layers, drained)
	var nearest := INF
	for layer: String in layers:
		var spec: Dictionary = config.layers[layer]
		if not bool(spec.get("collides", false)):
			continue
		for entry: Dictionary in layers[layer]:
			var point: Vector3 = entry.placement.position
			nearest = minf(nearest, at.distance_to(Vector2(point.x, point.z)) - float(spec.collision_radius) * float(entry.placement.scale))
	return nearest


func test_every_named_fight_arena_is_clear_of_baked_colliders() -> void:
	assert_true(BAKE.is_fresh("stormwood", int(SCATTER.config().seed), SCATTER.fingerprint()),
		"the committed Stormwood scatter bake matches its sources")
	var wander := float(_json("res://data/config/combat.json").wild.wander_radius)
	var named: Array = _json("res://data/config/stormwood_encounters.json").named_encounters
	var sites: Array = (SCATTER.config().encounter_clearings as Dictionary).sites
	assert_eq(sites.size(), named.size(), "every named fight has a scatter clearing")
	for row: Dictionary in named:
		var at := Vector2(float(row.position[0]), float(row.position[2]))
		var site_found := false
		for site: Dictionary in sites:
			if str(site.id) == str(row.id):
				site_found = Vector2(float(site.at[0]), float(site.at[1])).is_equal_approx(at)
		assert_true(site_found, "%s's scatter clearing sits on its authored position" % row.id)
		var envelope := _envelope(str(row.placeholder_species), wander)
		var nearest := _nearest_baked_collider(at, envelope + 40.0)
		assert_true(nearest > envelope, "%s: nearest baked collider %.2f m inside the %.2f m wildlife envelope" % [
			row.id, nearest, envelope])
