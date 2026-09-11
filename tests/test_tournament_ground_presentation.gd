extends "res://tests/test_case.gd"

## Focused contract for the visual-only Practice Meadow hierarchy. The large
## relic circle remains where the owner asked for it; this pins the tournament
## layer that differentiates the field without changing its gameplay surface.

const CONFIG_PATH := "res://data/config/tournament_ground_presentation.json"
const SCRIPT_PATH := "res://scripts/world/tournament_ground_presentation.gd"
const TOURNAMENT_PATH := "res://scripts/world/tournament.gd"
const BOUNDARY_PATH := "res://data/config/village_boundary.json"
const PROPS_PATH := "res://data/config/bands/band1_lower_meadows/props.json"
const REALMS_PATH := "res://data/config/realm_transitions.json"
const ROUTE_A := Vector2(27.5, -16.0)
const ROUTE_B := Vector2(14.0, 20.0)
const BRYN := Vector2(13.0, 9.0)
const HALDA := Vector2(23.5, 11.5)
const PRACTICE_BERRY := Vector2(28.0, 6.0)


func _config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	assert_true(file != null, "presentation config remains installed")
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	return parsed as Dictionary if parsed is Dictionary else {}


func _source(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _point(raw: Array) -> Vector2:
	return Vector2(float(raw[0]), float(raw[1]))


func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((point - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
	return point.distance_to(a + ab * t)


func _boundary_clearance(point: Vector2) -> float:
	var outline := (_read_json(BOUNDARY_PATH).get("outline", {}) as Dictionary).get("points", []) as Array
	var nearest := INF
	for index in outline.size():
		nearest = minf(nearest, _distance_to_segment(point,
			_point(outline[index] as Array), _point(outline[(index + 1) % outline.size()] as Array)))
	return nearest


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	return parsed as Dictionary if parsed is Dictionary else {}


func _tournament_prop_points() -> Array[Vector2]:
	var found: Array[Vector2] = []
	for raw: Variant in _read_json(PROPS_PATH).get("clusters", []):
		var cluster := raw as Dictionary
		if str(cluster.get("name", "")) != "tournament_ground":
			continue
		for raw_prop: Variant in cluster.get("props", []):
			found.append(_point((raw_prop as Dictionary).get("at", []) as Array))
	return found


func _shrine_centres() -> Array[Vector2]:
	var shrine := _read_json(REALMS_PATH).get("meadows_heart_shrine", {}) as Dictionary
	var centre := _point(shrine.get("position", []) as Array)
	var basis := Basis(Vector3.UP, deg_to_rad(float(shrine.get("yaw_deg", 0.0))))
	var north := basis * Vector3(0.0, 0.0, -6.2)
	var root := centre + Vector2(north.x, north.z)
	var result: Array[Vector2] = [root]
	for local: Vector3 in [Vector3(6.2, 0.0, 6.2), Vector3(0.0, 0.0, 12.4), Vector3(-6.2, 0.0, 6.2)]:
		var rotated: Vector3 = basis * local
		result.append(root + Vector2(rotated.x, rotated.z))
	return result


func test_training_ground_has_one_primary_canopy_and_a_readable_lists_ring() -> void:
	var cfg := _config()
	var arena := cfg.get("arena", {}) as Dictionary
	var canopy := cfg.get("marshal_canopy", {}) as Dictionary
	assert_eq(_point(arena.get("centre", []) as Array), Vector2(20.0, 10.0),
		"the marking follows the existing tournament fight centre")
	assert_true(float(arena.get("radius_x_m", 0.0)) >= 6.5,
		"the lists ellipse reads at field scale across its broad axis")
	assert_true(float(arena.get("radius_z_m", 0.0)) >= 5.5,
		"the lists ellipse encloses the fight floor along its short axis")
	assert_ne(float(arena.get("radius_x_m", 0.0)), float(arena.get("radius_z_m", 0.0)),
		"the lists is a composed ellipse rather than another circular shrine motif")
	assert_true(int(arena.get("segments", 0)) >= 64,
		"enough sampled segments keep the terrain-conforming ribbon smooth")
	assert_true(float(arena.get("ribbon_width_m", 0.0)) >= 0.5,
		"the packed-earth ribbon stays wider than ordinary path-edge noise")
	assert_true(float(arena.get("lift_m", 1.0)) <= 0.05,
		"the ribbon hugs terrain instead of becoming a raised cream slab")
	assert_true(ResourceLoader.exists(str(arena.get("albedo_texture", ""))),
		"the ribbon uses the installed packed-earth terrain texture")
	assert_true(float(canopy.get("fit_height_m", 0.0)) > 4.0,
		"the singular timber canopy outranks the four-metre shrine silhouettes")
	assert_eq(str(canopy.get("model", "")), "Stall_Empty",
		"the primary hierarchy uses the installed authored stall, not primitive boxes")
	assert_true(float(canopy.get("width_scale", 0.0)) >= 1.5,
		"the same singular stall keeps an event-scale frontage")
	assert_eq((canopy.get("accent_models", []) as Array).size(), 2,
		"two installed cloth accents frame the bracket under the eaves")
	assert_true(ResourceLoader.exists("%s/%s.gltf" % [canopy.get("dir", ""), canopy.get("model", "")]),
		"the marshal stall asset is installed")
	for accent: Variant in canopy.get("accent_models", []):
		assert_true(ResourceLoader.exists("%s/%s.gltf" % [canopy.get("dir", ""), accent]),
			"canopy accent %s is installed" % accent)
	var canopy_at := _point(canopy.get("at", []) as Array)
	assert_true(_distance_to_segment(canopy_at, ROUTE_A, ROUTE_B) >= 3.5,
		"the visual-only marshal backdrop keeps the board's authored road-side clearance")
	var canopy_boundary_clearance := _boundary_clearance(canopy_at)
	assert_true(canopy_boundary_clearance >= 2.0,
		"the marshal backdrop at %s remains inside the visible village boundary (%.2fm)" % [canopy_at, canopy_boundary_clearance])
	for shrine_at in _shrine_centres():
		assert_true(canopy_at.distance_to(shrine_at) >= 5.5,
			"the marshal backdrop stays clear of every shrine body")


func test_equipment_is_asymmetric_installed_and_outside_the_fight_floor() -> void:
	var cfg := _config()
	var arena := cfg.get("arena", {}) as Dictionary
	var centre := _point(arena.get("centre", []) as Array)
	var radius := maxf(float(arena.get("radius_x_m", 0.0)), float(arena.get("radius_z_m", 0.0)))
	var names := {}
	var existing_props := _tournament_prop_points()
	var shrine_centres := _shrine_centres()
	for raw: Variant in cfg.get("equipment", []):
		var prop := raw as Dictionary
		var name := str(prop.get("name", ""))
		assert_false(names.has(name), "%s is a unique training silhouette" % name)
		names[name] = true
		var at := _point(prop.get("at", []) as Array)
		assert_true(at.distance_to(centre) > radius + 0.5,
			"%s remains outside the marked fight floor" % name)
		assert_true(at.distance_to(PRACTICE_BERRY) >= 6.0,
			"%s leaves a measured six-metre read around the practice berry" % name)
		assert_true(at.distance_to(BRYN) >= 8.0, "%s stays clear of Bryn" % name)
		assert_true(at.distance_to(HALDA) >= 8.0, "%s stays clear of Halda" % name)
		assert_true(_distance_to_segment(at, ROUTE_A, ROUTE_B) >= 8.0,
			"%s stays clear of the real tournament-field route" % name)
		assert_true(_boundary_clearance(at) >= 2.0,
			"%s remains at least two metres inside the visible boundary" % name)
		for occupied in existing_props:
			assert_true(at.distance_to(occupied) >= 6.0,
				"%s stays clear of existing tournament furniture" % name)
		for shrine_at in shrine_centres:
			assert_true(at.distance_to(shrine_at) >= 6.0,
				"%s stays clear of every shrine collision disc" % name)
		assert_true(float(prop.get("scale", 0.0)) >= 1.2,
			"%s is deliberately legible from the lists" % name)
		var asset := "%s/%s.gltf" % [str(prop.get("dir", "")), str(prop.get("model", ""))]
		assert_true(ResourceLoader.exists(asset), "%s uses an installed asset" % name)
	assert_eq(names.size(), 3, "the equipment reads as one varied practice group")


func test_presentation_is_visual_only_and_mounted_by_the_existing_tournament() -> void:
	var cfg := _config()
	assert_true(load(SCRIPT_PATH) is Script, "presentation script parses as a production resource")
	assert_true(load(TOURNAMENT_PATH) is Script, "the mounted tournament script still parses")
	assert_false(bool(cfg.get("collision_enabled", true)),
		"the presentation contract explicitly forbids new collision")
	var source := _source(SCRIPT_PATH)
	assert_true(source.contains("SurfaceTool.new()"),
		"one sampled ArrayMesh surface builds the continuous lists ribbon")
	assert_true(source.contains("TournamentListsRibbon"),
		"the lists is emitted as one named presentation mesh")
	assert_false(source.contains("ListMark_"),
		"the rejected repeated cream slab segments cannot return")
	assert_true(source.contains("_terrain_point(world, outer_0") and source.contains("_terrain_point(world, inner_1"),
		"both ribbon edges sample authored terrain through the entire ellipse")
	assert_false(source.contains("StaticBody3D.new()"), "presentation creates no static body")
	assert_false(source.contains("CollisionShape3D.new()"), "presentation creates no collision shape")
	assert_false(source.contains("Area3D.new()"), "presentation creates no interaction area")
	assert_false(source.contains("INTERACTABLE.new()"), "presentation creates no prompt")
	var tournament_source := _source(TOURNAMENT_PATH)
	assert_true(tournament_source.contains("GROUND_PRESENTATION"),
		"the production tournament mounts the hierarchy")
	assert_true(tournament_source.contains("_build_board()"),
		"the existing bracket board remains built")
