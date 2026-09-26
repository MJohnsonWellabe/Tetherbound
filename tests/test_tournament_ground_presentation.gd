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
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
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


## F01-a/b: the tournament field's route is no longer a hard-coded copy of the
## old spine leg (27.5,-16)->(14,20) (that leg was removed; the spine now
## continues South Street from (11.5,2)). Clearance is measured against every
## road the terrain actually paints -- paths.routes, paths.approaches and the
## Lower Meadows spine -- read from the live config.
func _road_lines() -> Array:
	var terrain := _read_json(TERRAIN_PATH)
	var paths := terrain.get("paths", {}) as Dictionary
	var raw_lines: Array = []
	for entry: Variant in (paths.get("routes", []) as Array) + (paths.get("approaches", []) as Array):
		raw_lines.append((entry as Dictionary).get("points", []))
	for entry: Variant in ((terrain.get("trail", {}) as Dictionary).get("bands", []) as Array):
		if str((entry as Dictionary).get("id", "")) == "band1_lower_meadows":
			raw_lines.append((entry as Dictionary).get("points", []))
	return raw_lines


func _road_clearance(point: Vector2) -> float:
	var nearest := INF
	for line: Variant in _road_lines():
		var pts := line as Array
		for index in pts.size() - 1:
			nearest = minf(nearest, _distance_to_segment(point, _point(pts[index] as Array), _point(pts[index + 1] as Array)))
	return nearest


func test_the_tournament_field_route_is_read_from_the_real_roads() -> void:
	assert_false(_road_lines().is_empty(), "the terrain config authors roads; clearance checks would be vacuous")
	var centre := _point((_config().get("arena", {}) as Dictionary).get("centre", []) as Array)
	assert_true(_road_clearance(centre) <= 12.0,
		"a real road (South Street / the Lower Meadows spine) still serves the tournament field (%.1fm)" % _road_clearance(centre))


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
	assert_between(float(canopy.get("light_energy", 0.0)), 2.0, 2.5,
		"the canopy's local night source models the roof and hanging cloth")
	assert_true(float(canopy.get("light_range_m", 99.0)) <= 5.0,
		"canopy readability stays in a bounded local pool")
	assert_between(float(canopy.get("light_below_roof_m", 99.0)), 0.5, 0.8,
		"the local source remains close enough to model the cloth above it")
	assert_true(ResourceLoader.exists("%s/%s.gltf" % [canopy.get("dir", ""), canopy.get("model", "")]),
		"the marshal stall asset is installed")
	for accent: Variant in canopy.get("accent_models", []):
		assert_true(ResourceLoader.exists("%s/%s.gltf" % [canopy.get("dir", ""), accent]),
			"canopy accent %s is installed" % accent)
	var canopy_at := _point(canopy.get("at", []) as Array)
	assert_true(_road_clearance(canopy_at) >= 3.5,
		"the visual-only marshal backdrop keeps the board's authored road-side clearance")
	var canopy_boundary_clearance := _boundary_clearance(canopy_at)
	assert_true(canopy_boundary_clearance >= 2.0,
		"the marshal backdrop at %s remains inside the visible village boundary (%.2fm)" % [canopy_at, canopy_boundary_clearance])
	for shrine_at in _shrine_centres():
		assert_true(canopy_at.distance_to(shrine_at) >= 5.5,
			"the marshal backdrop stays clear of every shrine body")
	var source := _source(SCRIPT_PATH)
	assert_true(source.contains('spec.get("light_energy"')
		and source.contains('spec.get("light_range_m"')
		and source.contains('spec.get("light_below_roof_m"'),
		"production canopy consumes all bounded night-cloth light tunables")


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
		assert_true(_road_clearance(at) >= 8.0,
			"%s stays clear of the real tournament-field route" % name)
		assert_true(_boundary_clearance(at) >= 2.0,
			"%s remains at least two metres inside the visible boundary" % name)
		for occupied in existing_props:
			assert_true(at.distance_to(occupied) >= 6.0,
				"%s stays clear of existing tournament furniture" % name)
		for shrine_at in shrine_centres:
			assert_true(at.distance_to(shrine_at) >= 6.0,
				"%s stays clear of every shrine collision disc" % name)
		var fit_height := float(prop.get("fit_height_m", 0.0))
		assert_true(fit_height >= 1.3,
			"%s has an explicit perceptual height instead of an incomparable raw asset scale" % name)
		if name == "PracticeDummy":
			assert_true(fit_height >= 2.2, "the practice dummy reads at human height")
		elif name == "PracticeWeaponStand":
			assert_true(fit_height >= 1.9, "the weapon rack reads at human height")
		elif name == "PracticeShield":
			assert_true(fit_height >= 1.3, "the shield remains readable beside the taller props")
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
	assert_true(source.contains("PRESENTATION_BOUNDS.measure(prop)"),
		"equipment is fitted from visible bounds rather than raw imported units")
	assert_true(source.contains("ground - bounds.position.y * scale_factor"),
		"fitted equipment is seated on authored terrain")
	assert_false(source.contains("StaticBody3D.new()"), "presentation creates no static body")
	assert_false(source.contains("CollisionShape3D.new()"), "presentation creates no collision shape")
	assert_false(source.contains("Area3D.new()"), "presentation creates no interaction area")
	assert_false(source.contains("INTERACTABLE.new()"), "presentation creates no prompt")
	var tournament_source := _source(TOURNAMENT_PATH)
	assert_true(tournament_source.contains("GROUND_PRESENTATION"),
		"the production tournament mounts the hierarchy")
	assert_true(tournament_source.contains("_build_board()"),
		"the existing bracket board remains built")


func test_equipment_night_light_has_an_installed_visible_source_and_safe_footprint() -> void:
	var cfg := _config()
	var lamp := cfg.get("equipment_light", {}) as Dictionary
	var at := _point(lamp.get("at", []) as Array)
	assert_true(_road_clearance(at) >= 8.0,
		"the standing light remains clear of the real tournament route")
	assert_true(_boundary_clearance(at) >= 2.0,
		"the standing light remains inside the visible village boundary")
	assert_true(at.distance_to(PRACTICE_BERRY) >= 6.0,
		"the standing light leaves the practice berry readable")
	for shrine_at in _shrine_centres():
		assert_true(at.distance_to(shrine_at) >= 6.0,
			"the standing light stays clear of every shrine body")
	for key: String in ["stand_model", "head_model"]:
		assert_true(ResourceLoader.exists("%s/%s.gltf" % [lamp.get("dir", ""), lamp.get(key, "")]),
			"the standing light's %s is an installed authored asset" % key)
	assert_true(float(lamp.get("light_range_m", 0.0)) <= 7.0,
		"equipment light is bounded to the local verge")
	var source := _source(SCRIPT_PATH)
	assert_true(source.contains("PracticeVisibleFlame"),
		"the warm light has a visible emissive source")
	assert_true(source.contains("InstalledCandleStand") and source.contains("InstalledTorchHead"),
		"the visible source is mounted on the installed standing-light pair")


## Oxblood/red is Team Tether's alone (ART_DIRECTION). The kit's MI_Banner cloth
## is oxblood through its COLOR_0 vertex colours and the lists ring's old
## multiplier rendered maroon over the dirt texture; both now take Meadows ochre.
func test_tournament_cloth_and_ring_are_not_team_tether_red() -> void:
	var cfg := _config()
	var ring_colour := Color(str((cfg.get("arena", {}) as Dictionary).get("colour", "#ff0000")))
	var canopy := cfg.get("marshal_canopy", {}) as Dictionary
	var cloth := str(canopy.get("cloth_tint", ""))
	assert_true(not cloth.is_empty(), "the canopy cloth declares its non-red Meadows tint")
	for pair: Array in [["lists ring", ring_colour], ["canopy cloth", Color(cloth if not cloth.is_empty() else "#ff0000")]]:
		var c: Color = pair[1]
		assert_true(not (c.r > c.g * 1.6 and c.r > c.b * 1.6),
			"%s colour %s is not a red/oxblood hue" % [pair[0], c.to_html(false)])
	var source := _source(SCRIPT_PATH)
	assert_true(source.contains("vertex_color_use_as_albedo = false"),
		"the canopy drops the kit's oxblood vertex tint on MI_Banner surfaces")
