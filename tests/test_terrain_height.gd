extends "res://tests/test_case.gd"

## terrain_height.gd: every realm's Terrain3D sampler snaps a query within
## NEAR_VERTEX_M of a vertex onto that vertex, so Terrain3D 1.0.2's
## near-vertex get_height shortcut reads the vertex meant, not its neighbour.

const HEIGHT := preload("res://scripts/world/terrain_height.gd")


class FakeData:
	extends RefCounted
	var asked: Array[Vector3] = []
	func get_height(at: Vector3) -> float:
		asked.append(at)
		return at.x + at.z * 1000.0


class FakeTerrain:
	extends RefCounted
	var data: RefCounted = FakeData.new()
	var vertex_spacing := 2.0


func test_query_just_below_a_vertex_asks_for_the_vertex() -> void:
	assert_eq(HEIGHT.query_point(2.0, 547.995, 100.004), Vector3(548.0, 0.0, 100.0))


func test_query_away_from_a_vertex_is_unchanged() -> void:
	assert_eq(HEIGHT.query_point(2.0, 547.5, 101.0), Vector3(547.5, 0.0, 101.0))
	# Exactly NEAR_VERTEX_M off is outside the snap.
	assert_eq(HEIGHT.query_point(2.0, 548.0 - HEIGHT.NEAR_VERTEX_M, 100.0),
		Vector3(548.0 - HEIGHT.NEAR_VERTEX_M, 0.0, 100.0))


func test_unusable_spacing_never_snaps() -> void:
	assert_eq(HEIGHT.query_point(0.0, 547.995, 100.0), Vector3(547.995, 0.0, 100.0))
	assert_eq(HEIGHT.query_point(NAN, 547.995, 100.0), Vector3(547.995, 0.0, 100.0))


func test_height_at_reads_the_snapped_vertex_through_terrain_data() -> void:
	var terrain := FakeTerrain.new()
	assert_eq(HEIGHT.height_at(terrain, 3.996, 6.0), 4.0 + 6000.0)
	assert_eq((terrain.data as FakeData).asked, [Vector3(4.0, 0.0, 6.0)])


func test_missing_terrain_or_data_is_nan() -> void:
	assert_true(is_nan(HEIGHT.height_at(null, 1.0, 1.0)))
	var terrain := FakeTerrain.new()
	terrain.data = null
	assert_true(is_nan(HEIGHT.height_at(terrain, 1.0, 1.0)))
