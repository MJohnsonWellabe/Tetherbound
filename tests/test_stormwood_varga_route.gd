extends "res://tests/test_case.gd"

const HEIGHTFIELD := preload("res://scripts/world/stormwood_heightfield.gd")
const TRAINERS_PATH := "res://data/config/stormwood_trainers.json"
const NPCS_PATH := "res://data/config/stormwood_npcs.json"
const WORLD_PATH := "res://data/config/stormwood_world.json"
const CHAPTER_PATH := "res://data/config/stormwood_chapter.json"


func test_varga_is_grounded_on_the_authored_first_ascent() -> void:
	var trainers := _read(TRAINERS_PATH)
	var world := _read(WORLD_PATH)
	var varga := _by_id(trainers.get("trainers", []), "lieutenant_varga_rodline_bridge")
	var road := _by_id(world.get("routes", []), "conductor_road")
	assert_false(varga.is_empty(), "critical Varga trainer must remain authored")
	assert_false(road.is_empty(), "conductor road must remain authored")
	var at := _xz(varga.get("position", []))
	var points: Array = road.get("points", [])
	assert_true(points.size() >= 2, "conductor road needs its Rodline ascent")
	if varga.is_empty() or points.size() < 2:
		return
	assert_eq(at, Vector2(-630.0, 2390.0))
	assert_almost_eq(_segment_distance(at, _xz(points[0]), _xz(points[1])), 0.0, 0.01,
		"Varga must stand on the first exposed conductor-road segment")
	# The trainer catalogue's established grounding contract includes 0.15 m
	# clearance (test_stormwood_trainers_data). The relocation must preserve it;
	# expecting raw terrain height here contradicted that existing contract.
	assert_almost_eq(float((varga.get("position", []) as Array)[1]),
		float(HEIGHTFIELD.new().height_at(at.x, at.y)) + 0.15, 0.001,
		"authored Y must preserve the catalogue clearance above the production heightfield")


func test_varga_prompt_is_distinct_without_creating_dead_travel() -> void:
	var trainers := _read(TRAINERS_PATH)
	var npcs := _read(NPCS_PATH)
	var chapter := _read(CHAPTER_PATH)
	var varga := _by_id(trainers.get("trainers", []), "lieutenant_varga_rodline_bridge")
	var bryn := _by_id(npcs.get("characters", []), "warden_elect_bryn")
	var story_varga := _by_id(npcs.get("characters", []), "tether_lieutenant_varga")
	assert_false(varga.is_empty() or bryn.is_empty() or story_varga.is_empty(),
		"both story people and the critical trainer must remain authored")
	if varga.is_empty() or bryn.is_empty() or story_varga.is_empty():
		return
	var at := _xz(varga.get("position", []))
	var from_bryn := at.distance_to(_xz(bryn.get("position", [])))
	assert_true(from_bryn >= 20.0, "Varga's challenge prompt must not overlap Bryn")
	assert_true(from_bryn <= 120.0,
		"Act II must not open with a dead-travel gap over the playable-first limit")
	assert_true(at.distance_to(_xz(story_varga.get("position", []))) >= 20.0,
		"trainer Varga must not overlap the separate authored story greeting")
	var objective := _by_id(_act_objectives(chapter, "act_ii"), "stormwood_varga_defeated")
	assert_true(str(objective.get("how", "")).contains("exposed ascent beyond Rodline"),
		"the physical placement must keep matching the visible objective")


func _act_objectives(chapter: Dictionary, id: String) -> Array:
	for act: Dictionary in chapter.get("acts", []):
		if str(act.get("id", "")) == id:
			return act.get("objectives", []) as Array
	return []


func _by_id(rows: Array, id: String) -> Dictionary:
	for row: Variant in rows:
		if row is Dictionary and str((row as Dictionary).get("id", "")) == id:
			return row as Dictionary
	return {}


func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _xz(raw: Array) -> Vector2:
	if raw.size() >= 3:
		return Vector2(float(raw[0]), float(raw[2]))
	if raw.size() >= 2:
		return Vector2(float(raw[0]), float(raw[1]))
	return Vector2.INF


func _segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	var span := b - a
	if span.length_squared() <= 0.0001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(span) / span.length_squared(), 0.0, 1.0)
	return point.distance_to(a + span * t)
