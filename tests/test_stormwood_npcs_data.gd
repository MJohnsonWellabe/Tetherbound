extends "res://tests/test_case.gd"

## Catalogue contacts only; this does not claim NPC runtime spawning or dialogue.
const PATH := "res://data/config/stormwood_npcs.json"
const WORLD_PATH := "res://data/config/stormwood_world.json"
const ART_PATH := "res://data/config/art.json"
const HEIGHTFIELD := preload("res://scripts/world/stormwood_heightfield.gd")


func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func test_cast_reuses_installed_profiles_and_stays_in_its_authored_region() -> void:
	var art := _read(ART_PATH)
	var bounds := {}
	for region: Dictionary in _read(WORLD_PATH).get("regions", []):
		bounds[str(region.get("id", ""))] = region.get("bounds", {})
	var ids := {}
	for npc: Dictionary in _read(PATH).get("characters", []):
		var id := str(npc.get("id", ""))
		assert_false(id.is_empty() or ids.has(id))
		ids[id] = npc
		assert_true(art.has(str(npc.get("body_profile", ""))), "%s uses an installed humanoid profile" % id)
		var position: Array = npc.get("position", [])
		var region: Dictionary = bounds.get(str(npc.get("region_id", "")), {})
		assert_eq(position.size(), 3)
		assert_false(region.is_empty(), "%s has an authored region" % id)
		if position.size() == 3 and not region.is_empty():
			assert_between(float(position[0]), float(region.min_x), float(region.max_x), id)
			assert_between(float(position[2]), float(region.min_z), float(region.max_z), id)
	assert_eq(ids.size(), 19)


func test_every_npc_has_an_actual_surface_contact_and_key_anchors_hold() -> void:
	var heightfield := HEIGHTFIELD.new(HEIGHTFIELD.load_config())
	var by_id := {}
	for npc: Dictionary in _read(PATH).get("characters", []):
		by_id[str(npc.get("id", ""))] = npc
		var position: Array = npc.get("position", [])
		if position.size() != 3:
			continue
		var terrain_y := heightfield.height_at(float(position[0]), float(position[2])) + 0.15
		if str(npc.get("surface_id", "")) == "dynamo_core":
			assert_almost_eq(float(position[1]), terrain_y + 150.0, 0.01, "Marrow is on the elevated Dynamo core")
		else:
			assert_true(str(npc.get("surface_id", "")).is_empty(), "%s may not fall back from an implicit elevated surface" % str(npc.get("id", "")))
			assert_almost_eq(float(position[1]), terrain_y, 0.01, "%s is terrain-grounded" % str(npc.get("id", "")))
	for expected: Dictionary in [
		{"id": "rodkeeper_hesk", "at": [-350, 450]}, {"id": "defector_sable", "at": [-450, 3960]},
		{"id": "trader_oswin", "at": [-680, 2310]}, {"id": "keeper_ondra", "at": [-160, 2700]},
		{"id": "officer_kestrel", "at": [-100, 5350]}, {"id": "captain_marrow", "at": [-100, 5470]},
	]:
		var npc: Dictionary = by_id.get(str(expected.id), {})
		var position: Array = npc.get("position", [])
		assert_eq([int(position[0]), int(position[2])] if position.size() == 3 else [], expected.at, str(expected.id) + " anchor")
	assert_eq(str((by_id.get("captain_marrow", {}) as Dictionary).get("surface_id", "")), "dynamo_core")
