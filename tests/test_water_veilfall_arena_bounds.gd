extends "res://tests/test_case.gd"

## F14#1 C3: the Heart Chamber's arena bound (`water_veilfall.gd::
## room_arena_bound`, CombatManager's room contract) keeps Nerissa's fight
## ring inside the banner walls' camera liners.

const VEILFALL := preload("res://scripts/world/water_veilfall.gd")


func _rules() -> Dictionary:
	var file := FileAccess.open("res://data/config/water_veilfall.json", FileAccess.READ)
	return JSON.parse_string(file.get_as_text()) as Dictionary


func _heart(rules: Dictionary) -> Dictionary:
	for room: Dictionary in rules.rooms:
		if room.id == "heart_chamber":
			return room
	return {}


func test_nerissas_ring_stops_inside_the_banner_liners() -> void:
	var rules := _rules()
	var cfg: Dictionary = rules.arena_bounds
	assert_true((cfg.rooms as Array).has("heart_chamber"))
	# Her fights form about 8 m in front of her stand, toward the entrance.
	var stand: Array = rules.captain_position
	var centre := Vector2(float(stand[0]), float(stand[2]) - 8.0)
	var radius := VEILFALL.room_arena_bound(centre, _heart(rules),
		float(cfg.side_margin_m), float(cfg.end_margin_m))
	assert_true(radius > 5.0, "room for a 7 m lane: %s" % radius)
	var liner_inner := INF
	for box: Dictionary in rules.camera_occluders:
		var at: Array = box.at
		var size: Array = box.size
		if absf(float(at[0])) > 15.0:
			liner_inner = minf(liner_inner, absf(float(at[0])) - float(size[0]) * 0.5)
	assert_true(absf(centre.x) + radius < liner_inner, "ring edge %s inside the liner at %s" % [
		absf(centre.x) + radius, liner_inner])


func test_outside_a_room_there_is_no_opinion() -> void:
	var room := {"center_xz": [0.0, 102.0], "size_xz": [42.0, 44.0]}
	assert_eq(VEILFALL.room_arena_bound(Vector2(30.0, 102.0), room, 5.0, 1.0), -1.0)
	assert_eq(VEILFALL.room_arena_bound(Vector2(0.0, 102.0), room, 5.0, 1.0), 16.0)
	assert_eq(VEILFALL.room_arena_bound(Vector2(20.5, 102.0), room, 5.0, 1.0), 0.5, "never below 0.5")
