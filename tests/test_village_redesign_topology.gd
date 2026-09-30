extends "res://tests/test_case.gd"

const VILLAGE := "res://data/config/village.json"
const TERRAIN := "res://data/config/terrain_playground.json"
const PREFABS := "res://data/config/building_prefabs.json"


func test_actual_houses_face_the_same_straight_road_at_native_scale() -> void:
	var village := _read(VILLAGE)
	var terrain := _read(TERRAIN)
	var recipes: Dictionary = _read(PREFABS).get("prefabs", {})
	var road := PackedVector2Array()
	for entry: Dictionary in terrain.paths.approaches:
		if entry.get("id") == "village_main_street":
			for at: Array in entry.points:
				road.append(Vector2(float(at[0]), float(at[1])))
	assert_true(road.size() >= 2, "the baked main road exists")
	if road.size() < 2:
		return
	var start := road[0]
	var end := road[-1]
	var direction := (end - start).normalized()
	for point: Vector2 in road:
		assert_true(absf((point - start).cross(direction)) < .01, "one straight main road")
	var sides := {-1: 0, 1: 0}
	var count := 0
	for house: Dictionary in village.structures:
		if not bool(house.get("road_house", false)):
			continue
		count += 1
		assert_almost_eq(float(house.get("scale", 1.0)), 1.0, .001, "native installed house scale")
		var at := Vector2(float(house.at[0]), float(house.at[1]))
		var t := (at - start).dot(direction)
		assert_true(t > 0 and t < start.distance_to(end), "house lies beside the main road")
		var nearest := start + direction * t
		var side := 1 if (at - nearest).cross(direction) > 0 else -1
		sides[side] += 1
		var yaw := deg_to_rad(float(house.yaw_deg))
		var forward := Vector2(sin(yaw), cos(yaw))
		assert_true(forward.dot((nearest - at).normalized()) > .99, "actual prefab front faces the road")
		var recipe: Dictionary = recipes.get(str(house.prefab), {})
		assert_true(not recipe.is_empty(), "house uses an installed recipe")
	assert_true(count >= 8 and count <= 10, "eight to ten road houses")
	assert_true(int(sides[-1]) >= 4 and int(sides[1]) >= 4, "houses line both sides")


func test_home_exit_and_hall_connect_to_the_authored_main_road() -> void:
	var village := _read(VILLAGE)
	var plan: Dictionary = village.road_plan
	var start := Vector2(float(plan.road_start[0]), float(plan.road_start[1]))
	var end := Vector2(float(plan.road_end[0]), float(plan.road_end[1]))
	var house_position: Vector2 = preload("res://scripts/world/playground_world.gd").HOUSE_AT
	var house_marker_x := preload("res://scripts/world/grandpa_house.gd").INNER_W * .5 \
		+ preload("res://scripts/world/grandpa_house.gd").WALL_T + 1.2
	var actual_door := house_position + Vector2(house_marker_x, 0)
	assert_true(actual_door.distance_to(start) < .1, "road begins at the actual farmhouse door marker")
	var exits: Array = _read("res://data/config/village_boundary.json").gates.entries
	var found := false
	for entry: Dictionary in exits:
		if entry.id == plan.exit_gate:
			found = true
			var gate := Vector2(float(entry.at[0]), float(entry.at[1]))
			assert_true(gate.distance_to(start) < 12, "farm door is beside the existing South Bridge exit")
	assert_true(found, "the named exit exists")
	var halls: Array = village.structures.filter(func(entry: Dictionary) -> bool: return entry.prefab == "crossing_hall_shell")
	assert_eq(halls.size(), 1, "one actual Hall placement")
	if halls.size() != 1:
		return
	var hall: Dictionary = halls[0]
	var position := Vector2(float(hall.at[0]), float(hall.at[1]))
	var entrance := position + Vector2(0, -15).rotated(-deg_to_rad(float(hall.yaw_deg)))
	assert_true(entrance.distance_to(end) <= 1.1, "main road reaches the physical nave entrance")


func test_hall_entry_and_shrine_room_have_physical_walk_clearance() -> void:
	var recipe: Dictionary = _read(PREFABS).prefabs.crossing_hall_shell
	var routes := [[Vector2(0,-17),Vector2(0,-8)], [Vector2(0,0),Vector2(12,0)]]
	for route: Array in routes:
		for step: int in 61:
			var point: Vector2 = route[0].lerp(route[1], float(step)/60.0)
			for collider: Dictionary in recipe.colliders:
				var at: Array = collider.at
				var size: Array = collider.size
				if float(at[1])+float(size[1])*.5 <= .2 or float(at[1])-float(size[1])*.5 > 2.2:
					continue
				var rect := Rect2(Vector2(float(at[0])-float(size[0])*.5,float(at[2])-float(size[2])*.5),Vector2(float(size[0]),float(size[2]))).grow(.45)
				assert_true(not rect.has_point(point), "trainer capsule clears real Hall wall boxes")


func _read(path: String) -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return raw if raw is Dictionary else {}
