extends "res://tests/test_case.gd"

## Catch throws on rising ground (ralph/reports/MEADOWS-PAYOFFS/throw-aim-slope/).
##
## Found twice. The earned opening's tutorial catch on world seed 1376461701
## lost three consecutive ASSISTED throws with `reason=ground`: the orb struck
## rising terrain just short of the assist's predicted point (closest approach
## 1.27 m against a 1.27 m hit margin), while the same step passed on six other
## seeds. And a review found the aim point itself is placed `AIM_REACH` metres
## down the camera's centre ray whether or not the ground is in the way, so on a
## slope the reticle's aim point sits inside the hill.
##
## The assist solved the low ballistic arc to the target in empty space. The
## camera sits higher than the hand, so the eye can see a creature standing
## beyond a crest that the hand's low arc flies straight into.
##
## These tests build a small real collision world (a HeightMapShape3D on a raw
## physics space -- direct ray queries are synchronous, no scene tree needed)
## and fly the orb exactly as `orb.gd::_tick_flight()` does: semi-implicit
## Euler at the physics rate, the target test before the ground raycast, the
## same `body_radius + radius` envelope.

const THROW := preload("res://scripts/combat/throw_aim.gd")
const CATCH := preload("res://scripts/combat/catch_math.gd")

## A Meadows-sized creature: body_radius 0.67 gives the report's 1.27 m
## envelope with the production orb radius of 0.60.
const BODY_RADIUS := 0.67
const HAND := Vector3(0.0, 1.5, 0.0)
## The aim camera sits behind and above the trainer (catching.json `aim`).
const EYE := Vector3(0.0, 4.0, 3.4)

var _bodies: Array[RID] = []
var _world: World3D = null


func after_each() -> void:
	for body in _bodies:
		PhysicsServer3D.free_rid(body)
	_bodies.clear()
	_world = null


func _throw_cfg() -> Dictionary:
	return CATCH.config().get("throw", {})


func _speed() -> float:
	return float(_throw_cfg().get("speed", 17.0))


func _gravity() -> float:
	return float(_throw_cfg().get("gravity", 14.0))


func _spawn_forward() -> float:
	return float(_throw_cfg().get("spawn_forward", 0.6))


func _envelope() -> float:
	return BODY_RADIUS + float(_throw_cfg().get("radius", 0.6))


## Ground along the throw (-Z), constant across it. Flat for the first 1.5 m,
## a smooth rise to a 3.55 m crest five metres out, settling onto a 3.0 m
## plateau where the creature stands eight metres from the trainer.
static func _rise_height(distance: float) -> float:
	if distance < 1.5:
		return 0.0
	if distance < 5.0:
		return 3.55 * smoothstep(1.5, 5.0, distance)
	if distance < 6.5:
		return lerpf(3.55, 3.0, (distance - 5.0) / 1.5)
	return 3.0


static func _flat_height(_distance: float) -> float:
	return 0.0


func _space(height: Callable) -> PhysicsDirectSpaceState3D:
	_world = World3D.new()
	var shape := HeightMapShape3D.new()
	shape.map_width = 61
	shape.map_depth = 61
	var data := PackedFloat32Array()
	for zi in 61:
		for _xi in 61:
			data.append(float(height.call(-(float(zi) - 30.0))))
	shape.map_data = data
	var body := PhysicsServer3D.body_create()
	PhysicsServer3D.body_set_mode(body, PhysicsServer3D.BODY_MODE_STATIC)
	PhysicsServer3D.body_set_space(body, _world.space)
	PhysicsServer3D.body_add_shape(body, shape.get_rid())
	PhysicsServer3D.body_set_state(body, PhysicsServer3D.BODY_STATE_TRANSFORM, Transform3D.IDENTITY)
	_bodies.append(body)
	# Keep the shape alive as long as the body that references it.
	_world.set_meta("shape", shape)
	return PhysicsServer3D.space_get_direct_state(_world.space)


## FAILING-FIRST SHIM (this commit only). The terrain-aware solve does not
## exist yet, so these helpers fall back to what the unchanged code does: the
## committed assist launches along `ballistic_direction()` to its point, and
## the aim point sits `AIM_REACH` down the camera's centre ray. The next commit
## replaces the shim with direct calls.
func _throw_script() -> Object:
	return THROW


func _has(name: String) -> bool:
	for method: Dictionary in (THROW as GDScript).get_script_method_list():
		if str(method.get("name", "")) == name:
			return true
	return false


func _clearance() -> Dictionary:
	return _throw_script().call("clearance_from_config", _throw_cfg()) if _has("clearance_from_config") else {}


## The launch the committed assist makes toward `point`.
func _assisted(space: PhysicsDirectSpaceState3D, point: Vector3) -> Vector3:
	if _has("assisted_launch_direction"):
		var none: Array[RID] = []
		return _throw_script().call("assisted_launch_direction", space, none, HAND, point, Vector3.FORWARD,
			_speed(), _gravity(), _spawn_forward(), _envelope(), _clearance())
	return THROW.ballistic_direction(HAND, point, Vector3.FORWARD, _speed(), _gravity())


## Where the reticle's aim point sits for a centre ray from `eye`.
func _reticle(space: PhysicsDirectSpaceState3D, eye: Vector3, forward: Vector3) -> Vector3:
	if _has("surface_aim_point"):
		var none: Array[RID] = []
		return _throw_script().call("surface_aim_point", space, none, eye, forward, THROW.AIM_REACH, HAND,
			float(_throw_cfg().get("aim_surface_min_ahead", 1.0)))
	return eye + forward * THROW.AIM_REACH


## Fly the orb as orb.gd does and say how it ended.
func _fly(space: PhysicsDirectSpaceState3D, direction: Vector3, centre: Vector3) -> Dictionary:
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	var velocity := direction.normalized() * _speed()
	var position := HAND + direction.normalized() * _spawn_forward()
	var closest := INF
	var life := 0.0
	while life < float(_throw_cfg().get("max_flight_time", 4.0)):
		life += dt
		var before := position
		velocity.y -= _gravity() * dt
		position += velocity * dt
		var offset := Geometry3D.get_closest_point_to_segment(centre, before, position).distance_to(centre)
		closest = minf(closest, offset)
		if offset <= _envelope():
			return {"hit": true, "closest": offset, "at": position}
		var query := PhysicsRayQueryParameters3D.create(before, position)
		query.collide_with_areas = false
		var hit := space.intersect_ray(query)
		if not hit.is_empty():
			return {"hit": false, "closest": closest, "at": hit["position"]}
	return {"hit": false, "closest": closest, "at": position}


func _clear_line(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	return space.intersect_ray(query).is_empty()


## The scene is the defect's shape, or the tests below prove nothing: the eye
## sees the creature over the crest, and the default low arc does not.
func test_the_constructed_rise_is_the_reported_shape() -> void:
	var space := _space(_rise_height)
	var centre := Vector3(0.0, _rise_height(8.0) + BODY_RADIUS, -8.0)
	assert_true(_clear_line(space, EYE, centre),
		"the camera must have a clear straight line to the creature's body")
	var low := THROW.ballistic_direction(HAND, centre, Vector3.FORWARD, _speed(), _gravity())
	var flight := _fly(space, low, centre)
	assert_false(bool(flight["hit"]),
		"the default low arc must meet the crest early (the seed-1376461701 shape)")


func test_assisted_throw_over_a_rise_clears_the_ground_and_reaches_the_target() -> void:
	var space := _space(_rise_height)
	var centre := Vector3(0.0, _rise_height(8.0) + BODY_RADIUS, -8.0)
	var direction := _assisted(space, centre)
	var flight := _fly(space, direction, centre)
	assert_true(bool(flight["hit"]),
		"assisted arc struck the ground at %s (closest %.2f m, envelope %.2f m) before reaching the target"
		% [flight["at"], float(flight["closest"]), _envelope()])
	assert_true(float(flight["closest"]) <= _envelope(),
		"assisted arc passed %.2f m from the centre, outside the %.2f m hit margin"
		% [float(flight["closest"]), _envelope()])
	# The LOWEST arc that clears, not a lob: the flight time a lob spends in
	# the air is time a moving creature spends walking out of the lead.
	var pitch := rad_to_deg(asin(direction.normalized().y))
	assert_true(pitch < float(_throw_cfg().get("launch_assist_clearance_max_pitch_deg", 45.0)) + 0.01,
		"cleared arc pitched %.1f deg, past the configured ceiling" % pitch)


## The reticle's aim point is where the player can SEE the centre ray land,
## not `AIM_REACH` metres down it inside the hill.
func test_reticle_on_a_slope_sits_on_the_visible_surface() -> void:
	var space := _space(_rise_height)
	var ground := Vector3(0.0, _rise_height(3.5), -3.5)
	var forward := (ground - EYE).normalized()
	var point := _reticle(space, EYE, forward)
	var seen := EYE.distance_to(point)
	var query := PhysicsRayQueryParameters3D.create(EYE, EYE + forward * THROW.AIM_REACH)
	var surface: Dictionary = space.intersect_ray(query)
	assert_false(surface.is_empty(), "the centre ray must meet the slope inside AIM_REACH")
	if surface.is_empty():
		return
	var visible := EYE.distance_to(surface["position"])
	assert_true(seen <= visible + 0.05,
		"reticle aim point %s is %.2f m down the ray, %.2f m inside the terrain the eye sees at %.2f m"
		% [point, seen, seen - visible, visible])
	assert_almost_eq(point.y, _rise_height(-point.z), 0.1,
		"reticle aim point is not on the ground surface")


## Flat ground: the assist must launch exactly as it always has.
func test_flat_ground_assisted_launch_is_unchanged() -> void:
	var space := _space(_flat_height)
	for distance: float in [4.0, 8.0, 12.0, 16.0]:
		for lateral: float in [-2.0, 0.0, 3.0]:
			var centre := Vector3(lateral, BODY_RADIUS, -distance)
			var expected := THROW.ballistic_direction(HAND, centre, Vector3.FORWARD, _speed(), _gravity())
			var direction := _assisted(space, centre)
			assert_eq(direction, expected,
				"flat-ground assisted launch changed at %.0f m / %.0f m lateral" % [distance, lateral])
			assert_true(bool(_fly(space, direction, centre)["hit"]),
				"flat-ground assisted launch no longer reaches at %.0f m" % distance)


## A reticle above the horizon never meets the ground, so its aim point stays
## the fixed reach it always was.
func test_open_sky_reticle_is_unchanged() -> void:
	var space := _space(_flat_height)
	var forward := Vector3(0.0, 0.08, -1.0).normalized()
	assert_eq(_reticle(space, EYE, forward), EYE + forward * THROW.AIM_REACH,
		"an aim point with nothing in the way moved")


## A wall no arc can clear inside the ceiling: the assist keeps the default low
## arc rather than inventing a lob or a direction the player never aimed.
func test_no_clearing_arc_keeps_the_default() -> void:
	var space := _space(func(distance: float) -> float: return 30.0 if distance > 4.0 and distance < 6.0 else 0.0)
	var centre := Vector3(0.0, BODY_RADIUS, -9.0)
	var expected := THROW.ballistic_direction(HAND, centre, Vector3.FORWARD, _speed(), _gravity())
	assert_eq(_assisted(space, centre), expected,
		"an unclearable wall must leave the default launch alone")


## Both the preview and the release read `_launch_direction()`; both paths into
## it must route through the terrain-aware solve, and the aim point through the
## surface.
func test_the_live_aim_paths_use_the_terrain_aware_solve() -> void:
	var file := FileAccess.open("res://scripts/combat/throw_aim.gd", FileAccess.READ)
	var source := file.get_as_text() if file != null else ""
	for fn: String in ["_launch_direction", "_aim_direction"]:
		var start := source.find("func %s(" % fn)
		var end := source.find("\nfunc ", start + 1)
		var body := source.substr(start, end - start) if start >= 0 else ""
		assert_true(body.contains("_terrain_clear_direction("),
			"%s() does not route through the terrain-aware launch" % fn)
	var aim_start := source.find("func _aim_direction(")
	var aim_body := source.substr(aim_start, source.find("\nfunc ", aim_start + 1) - aim_start)
	assert_true(aim_body.contains("_surface_aim_point("),
		"_aim_direction() places the aim point without the visible surface")
