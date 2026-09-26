extends RefCounted

## One Terrain3D height sampler for every realm.
##
## Terrain3D 1.0.2 `Terrain3DData::get_height` has a near-vertex shortcut:
## within 0.01 m of a vertex it returns `get_pixel(pos)` for the UNROUNDED
## position, and get_pixel floors. Just below a vertex (x = 547.995) that is
## the height of the vertex one step down and left: 0.6-0.7 m off on a
## 27-degree slope and up to 5 m on cliffs, while the collision surface is
## right. Asking for the vertex itself sends the shortcut to the vertex it
## meant, so this sampler agrees with Terrain3D's own collision
## (ralph/reports/TIDEWAKE/f13_loops_shortcuts/BRINE_ROOT_CAUSE.txt).
## Water fixed this first in water_world.gd::ground_height_at.
const NEAR_VERTEX_M := 0.02


## Ground height under (x, z), or NAN when the terrain or its data is absent.
static func height_at(terrain: Object, x: float, z: float) -> float:
	if terrain == null or not is_instance_valid(terrain):
		return NAN
	var data: Object = terrain.get("data")
	if data == null:
		return NAN
	return height_from(data, float(terrain.get("vertex_spacing")), x, z)


## The same, for a caller that already holds the Terrain3DData object.
static func height_from(data: Object, vertex_spacing: float, x: float, z: float) -> float:
	return float(data.call("get_height", query_point(vertex_spacing, x, z)))


## The point to hand `get_height`: (x, 0, z), or the vertex it lies within
## NEAR_VERTEX_M of. Pure, so the snap is testable without a terrain.
static func query_point(vertex_spacing: float, x: float, z: float) -> Vector3:
	var at := Vector3(x, 0.0, z)
	if vertex_spacing > 0.0 and is_finite(vertex_spacing):
		var vertex := Vector3(snappedf(x, vertex_spacing), 0.0, snappedf(z, vertex_spacing))
		if at.distance_to(vertex) < NEAR_VERTEX_M:
			return vertex
	return at
