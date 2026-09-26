extends "res://tests/test_case.gd"

## Owner direction on WO-F09-04: yellow current flowing in every Stormwood
## road and spur lane (scripts/world/stormwood_road_current.gd). Each check
## has a negative control run through the same measurement.

const CURRENT := preload("res://scripts/world/stormwood_road_current.gd")
const FIELD := preload("res://scripts/world/stormwood_heightfield.gd")
const MOTION_PREFS := preload("res://scripts/ui/motion_prefs.gd")
const WORLD_PATH := "res://data/config/stormwood_world.json"
const SURFACE_PATH := "res://data/config/stormwood_road_surface.json"
const MIN_COVERAGE := 0.98


class FixtureWorld extends Node3D:
	var simulation_only := false
	var field := FIELD.new()

	func ground_height_at(x: float, z: float) -> float:
		return field.height_at(x, z)


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary


func _route_length(route: Dictionary) -> float:
	var points: Array = route.points
	var total := 0.0
	for i in range(1, points.size()):
		total += Vector2(float(points[i - 1][0]), float(points[i - 1][1])).distance_to(Vector2(float(points[i][0]), float(points[i][1])))
	return total


## Flat ground keeps the fixture build quick; coverage does not depend on it.
func _built(simulation_only: bool) -> Array:
	var world := FixtureWorld.new()
	world.simulation_only = simulation_only
	var current := CURRENT.new()
	world.add_child(current)
	current.build(world, func(_x: float, _z: float) -> float: return 0.0)
	return [world, current]


func _coverage(current: Node, routes: Array) -> Dictionary:
	var covered := {}
	for chunk: Node in current.get_children():
		if chunk is MeshInstance3D:
			var id := str(chunk.get_meta("route", ""))
			covered[id] = float(covered.get(id, 0.0)) + float(chunk.get_meta("length_m", 0.0))
	var out := {}
	for route: Dictionary in routes:
		out[str(route.id)] = float(covered.get(str(route.id), 0.0)) / _route_length(route)
	return out


func _is_yellow_gold(colour: Color) -> bool:
	var hue := colour.h * 360.0
	return hue >= 35.0 and hue <= 65.0 and colour.s >= 0.25


func test_every_route_and_spur_is_covered_by_current_chunks() -> void:
	var routes: Array = _json(WORLD_PATH).routes
	var built := _built(false)
	var current: Node = built[1]
	var coverage := _coverage(current, routes)
	var spurs := 0
	for route: Dictionary in routes:
		assert_true(float(coverage[str(route.id)]) >= MIN_COVERAGE,
			"%s (%s): current covers %.1f%% of its length" % [route.id, route.kind, float(coverage[str(route.id)]) * 100.0])
		if str(route.kind) == "spur":
			spurs += 1
	assert_eq(spurs, 5, "all five spurs are measured")
	# Negative control: drop every spur chunk and the same measurement fails.
	for chunk: Node in current.get_children():
		if str(chunk.get_meta("route", "")).begins_with("spur_"):
			current.remove_child(chunk)
			chunk.free()
	var stripped := _coverage(current, routes)
	assert_true(float(stripped["spur_verge_ash_hollow"]) < MIN_COVERAGE, "control: a route without chunks is caught")
	(built[0] as Node).free()


## WO-F09-05: a spur's current is its own language: its chunks carry UV2.x = 1
## (the shader's one thin, dimmer crack that starts at the road edge) and a
## vertex colour in the road's yellow family (round 6); a road's carry 0.
func test_spur_current_is_a_thin_yellow_crack_and_roads_are_not_flagged() -> void:
	var built := _built(false)
	var current: Node = built[1]
	var tints := CURRENT.spur_tints()
	assert_eq(tints.size(), 5, "a tint for each of the five spurs")
	var spur_chunks := 0
	var road_chunks := 0
	for chunk: Node in current.get_children():
		if not (chunk is MeshInstance3D):
			continue
		var arrays := ((chunk as MeshInstance3D).mesh as ArrayMesh).surface_get_arrays(0)
		var uv2: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
		var colours: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		var route := str(chunk.get_meta("route", ""))
		if tints.has(route):
			spur_chunks += 1
			assert_true(uv2[0].x > 0.5 and colours[0].is_equal_approx(tints[route]), "%s: a spur chunk is flagged and tinted" % route)
			assert_true(_is_yellow_gold(tints[route]), "%s: its crack is the road's yellow family (round 6)" % route)
		else:
			road_chunks += 1
			assert_true(uv2[0].x < 0.5, "%s: a road chunk is not flagged as a spur" % route)
	assert_true(spur_chunks > 0 and road_chunks > 0, "both kinds are built")
	(built[0] as Node).free()


func test_chunks_are_range_limited_shadowless_and_have_no_collision() -> void:
	var cfg := CURRENT.config()
	var built := _built(false)
	var current: Node = built[1]
	var chunks := 0
	var bad_range := 0
	var shared := true
	var first_material: Material = null
	for child: Node in current.get_children():
		if not child is MeshInstance3D:
			continue
		chunks += 1
		var chunk := child as MeshInstance3D
		if not is_equal_approx(chunk.visibility_range_end, float(cfg.draw_distance_m)) or chunk.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			bad_range += 1
		if first_material == null:
			first_material = chunk.material_override
		shared = shared and chunk.material_override == first_material
	assert_true(chunks > 400, "%d chunks of at most %.0f m" % [chunks, float(cfg.chunk_m)])
	assert_eq(bad_range, 0, "every chunk stops drawing at %.0f m and casts no shadow" % float(cfg.draw_distance_m))
	assert_true(shared, "one shared material for every chunk")
	var colliders := current.find_children("*", "CollisionObject3D", true, false).size() + current.find_children("*", "CollisionShape3D", true, false).size()
	assert_eq(colliders, 0, "no collision anywhere in the current")
	# Negative control: the same collision scan finds a body added under it.
	var body := StaticBody3D.new()
	current.add_child(body)
	assert_eq(current.find_children("*", "CollisionObject3D", true, false).size(), 1, "control: an added collider is found")
	(built[0] as Node).free()


func test_nothing_is_built_on_a_simulation_only_world() -> void:
	var built := _built(true)
	var current: Node = built[1]
	assert_eq(current.get_child_count(), 0, "a simulation_only world gets no current")
	assert_true(current.get("material") == null, "and no material")
	(built[0] as Node).free()
	# Negative control: a presentation world does build.
	var shown := _built(false)
	assert_true((shown[1] as Node).get_child_count() > 0, "control: a presentation world builds chunks")
	(shown[0] as Node).free()


func test_reduced_motion_calms_flow_and_removes_flicker() -> void:
	var cfg := CURRENT.config()
	var was := MOTION_PREFS.reduced_motion()
	MOTION_PREFS.set_reduced_motion(true)
	var built := _built(false)
	var material: ShaderMaterial = (built[1] as Node).get("material")
	assert_almost_eq(float(material.get_shader_parameter("flow_speed")), float(cfg.reduced_motion.flow_speed_mps), 0.0001, "reduced motion: calm flow speed")
	assert_almost_eq(float(material.get_shader_parameter("flicker")), 0.0, 0.0001, "reduced motion: no flicker")
	# The live toggle is followed on the next poll.
	MOTION_PREFS.set_reduced_motion(false)
	(built[1] as Node).call("_poll")
	assert_almost_eq(float(material.get_shader_parameter("flow_speed")), float(cfg.flow_speed_mps), 0.0001, "control: full motion restores the configured flow")
	assert_true(float(material.get_shader_parameter("flicker")) > 0.0, "control: full motion flickers")
	MOTION_PREFS.set_reduced_motion(was)
	(built[0] as Node).free()


func test_colours_come_from_config_and_are_yellow_gold() -> void:
	var cfg := CURRENT.config()
	var built := _built(false)
	var material: ShaderMaterial = (built[1] as Node).get("material")
	for key: String in ["colour_core", "colour_edge"]:
		var colour := Color(str(cfg[key]))
		assert_true((material.get_shader_parameter(key) as Color).is_equal_approx(colour), "%s from config" % key)
		assert_true(_is_yellow_gold(colour), "%s %s is yellow-gold (hue %.0f)" % [key, str(cfg[key]), colour.h * 360.0])
	# Negative controls: the combat telegraph magenta and Team Tether oxblood
	# fail the same hue check.
	assert_false(_is_yellow_gold(Color("ff40e6")), "control: telegraph magenta is rejected")
	assert_false(_is_yellow_gold(Color("7a1f24")), "control: oxblood is rejected")
	(built[0] as Node).free()


func test_ribbon_stays_inside_the_painted_lane_and_flows_toward_the_dynamo() -> void:
	var cfg := CURRENT.config()
	var surface := _json(SURFACE_PATH)
	for kind: String in ["critical", "alternate", "loop", "island", "spur"]:
		var half := CURRENT.ribbon_half_width(kind, cfg, surface)
		assert_true(half > 0.0 and half <= float(surface.lane_half_width_m[kind]), "%s ribbon (%.2f m) lies within its lane" % [kind, half])
	var wide := cfg.duplicate(true)
	wide.width_fraction = 1.3
	wide.spur.width_fraction = 1.3
	assert_true(CURRENT.ribbon_half_width("spur", wide, surface) > float(surface.lane_half_width_m.spur), "control: a 1.3 fraction would leave the lane")
	var dynamo := Vector2(float(cfg.dynamo_xz[0]), float(cfg.dynamo_xz[1]))
	for route: Dictionary in _json(WORLD_PATH).routes:
		var points := CURRENT.flow_points(route, cfg)
		var closed := Vector2(float(route.points[0][0]), float(route.points[0][1])).is_equal_approx(
			Vector2(float(route.points[-1][0]), float(route.points[-1][1])))
		if closed:
			assert_true(points[0].is_equal_approx(Vector2(float(route.points[0][0]), float(route.points[0][1]))), "%s: a loop keeps polyline order" % route.id)
		else:
			assert_true(points[points.size() - 1].distance_to(dynamo) <= points[0].distance_to(dynamo), "%s flows toward the Dynamo" % route.id)
	# Negative control: a route pointing away from the Dynamo is reversed.
	var away := {"id": "away", "kind": "loop", "points": [[-100.0, 5000.0], [-100.0, 100.0]]}
	var flowed := CURRENT.flow_points(away, cfg)
	assert_true(flowed[0].is_equal_approx(Vector2(-100.0, 100.0)), "control: an outbound polyline is reversed")


func test_storm_intensity_follows_config_per_phase() -> void:
	var cfg := CURRENT.config()
	var built := _built(false)
	var current: Node = built[1]
	var material: ShaderMaterial = current.get("material")
	assert_almost_eq(float(material.get_shader_parameter("storm_intensity")), float(cfg.storm_intensity.calm), 0.0001, "starts at the Calm value")
	for phase: String in ["calm", "building", "break", "fading", "aftermath"]:
		assert_almost_eq(CURRENT.phase_intensity(phase, cfg), float(cfg.storm_intensity[phase]), 0.0001, "%s intensity from config" % phase)
	assert_true(CURRENT.phase_intensity("break", cfg) > CURRENT.phase_intensity("calm", cfg), "Break surges above Calm")
	current.call("set_storm_intensity", 3.0)
	assert_almost_eq(float(material.get_shader_parameter("storm_intensity")), 1.0, 0.0001, "clamped to 1")
	# Negative control: an unknown phase reads as Calm, not as full power.
	assert_almost_eq(CURRENT.phase_intensity("typhoon", cfg), float(cfg.storm_intensity.calm), 0.0001, "control: unknown phase is Calm")
	(built[0] as Node).free()
