extends "res://tests/test_case.gd"

const MINIMAP := preload("res://scripts/ui/minimap.gd")


func test_corridor_world_window_maps_to_rectangular_texture_pixels() -> void:
	var bounds := {
		"min_x": -1024.0,
		"max_x": 1024.0,
		"min_z": -512.0,
		"max_z": 7680.0,
	}
	var source := MINIMAP.terrain_source_region(
		Vector2(0.0, 0.0), 96.0, Vector2(512.0, 2048.0), bounds)

	assert_eq(source.position, Vector2(244.0, 116.0),
		"the village window must sample inside the bake at its true corridor position")
	assert_eq(source.size, Vector2(24.0, 24.0),
		"square world metres must stay square in a correctly-aspected texture")


func test_region_conversion_scales_each_axis_independently() -> void:
	var bounds := {"min_x": 0.0, "max_x": 200.0, "min_z": 0.0, "max_z": 800.0}
	var source := MINIMAP.terrain_source_region(
		Vector2(100.0, 400.0), 80.0, Vector2(100.0, 200.0), bounds)

	assert_eq(source.position, Vector2(30.0, 90.0))
	assert_eq(source.size, Vector2(40.0, 20.0),
		"non-square texture texels must be represented honestly rather than assumed to be metres")


func test_rotated_layer_uses_the_square_diagonal_to_cover_corners() -> void:
	assert_almost_eq(MINIMAP.map_layer_draw_span(90.0), 90.0 * sqrt(2.0), 0.001,
		"the movement-up layer must cover widget corners at diagonal headings")


## Both of these assert against `PLAYER_MARKER_CLEAR_RADIUS` rather than the
## pixel coordinates it happened to produce. They were written with the
## coordinates baked in (90.0 and 150.0, i.e. a radius of 30), and MAP-TERRAIN
## enlarging the player marker to 34 broke them without any behaviour changing
## -- the declutter rule was still exactly right, the literals were just a
## stale copy of one input to it. What these checks are actually for is the
## rule: push to the ring, keep the bearing, and pick a deterministic bearing
## when there is none. A future marker resize should move them for free.
func test_objective_at_player_yields_to_the_centred_player_arrow() -> void:
	var centre := Vector2(120.0, 120.0)
	var r: float = MINIMAP.PLAYER_MARKER_CLEAR_RADIUS
	assert_eq(MINIMAP.player_clear_position(centre, centre), centre + Vector2.UP * r,
		"an exactly stacked objective should move predictably upward outside the player marker")


func test_nearby_objective_keeps_its_bearing_when_decluttered() -> void:
	var centre := Vector2(120.0, 120.0)
	var r: float = MINIMAP.PLAYER_MARKER_CLEAR_RADIUS
	var displaced := MINIMAP.player_clear_position(Vector2(125.0, 120.0), centre)
	assert_eq(displaced, centre + Vector2.RIGHT * r,
		"decluttering may change icon radius but must not change its bearing")
	# The bearing claim, made as its own assertion rather than implied by the
	# coordinate: due east in, due east out, whatever the radius becomes.
	assert_eq((displaced - centre).normalized(), Vector2.RIGHT,
		"the decluttered icon must keep the bearing it arrived on")
