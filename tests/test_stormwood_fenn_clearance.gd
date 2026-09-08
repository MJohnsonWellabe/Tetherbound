extends "res://tests/test_stormwood_varga_route.gd"

const NPC := preload("res://scripts/npc/npc_body.gd")
const TRAINER := preload("res://scripts/world/trainer_npc.gd")


func test_fenn_and_ondra_have_disjoint_interaction_ranges() -> void:
	var fenn := _by_id(_read(TRAINERS_PATH).get("trainers", []), "rodline_keeper_fenn")
	var ondra := _by_id(_read(NPCS_PATH).get("characters", []), "keeper_ondra")
	assert_false(fenn.is_empty() or ondra.is_empty())
	if fenn.is_empty() or ondra.is_empty():
		return
	var body := NPC.new()
	var story_radius := float(body.add_prompt("Talk to Keeper Ondra").get("radius"))
	body.free()
	var clearance := TRAINER.PROMPT_RADIUS + story_radius
	assert_true(_xz(fenn.position).distance_to(_xz(ondra.position)) > clearance,
		"Fenn must not compete anywhere inside Ondra's normal interaction range")


func test_fenn_remains_grounded_on_the_local_conductor_road_shoulder() -> void:
	var fenn := _by_id(_read(TRAINERS_PATH).get("trainers", []), "rodline_keeper_fenn")
	var road := _by_id(_read(WORLD_PATH).get("routes", []), "conductor_road")
	assert_eq(str(fenn.get("region_id", "")), "conductor_run")
	assert_eq(str(fenn.get("route_class", "")), "optional")
	var at := _xz(fenn.get("position", []))
	assert_eq(at, Vector2(-180.0, 2705.0))
	var points: Array = road.get("points", [])
	var distance := INF
	for i in range(points.size() - 1):
		distance = minf(distance, _segment_distance(at, _xz(points[i]), _xz(points[i + 1])))
	assert_true(distance <= float(fenn.encounter_anchor.max_route_distance_m),
		"optional Fenn remains reachable from the authored road")
	var field := HEIGHTFIELD.new()
	var root_y := float(fenn.position[1])
	assert_almost_eq(root_y, field.height_at(at.x, at.y) + 0.15, 0.001)
	# npc_body's existing 0.36 m capsule footprint must not begin buried.
	for offset in [Vector2(0.36, 0), Vector2(-0.36, 0), Vector2(0, 0.36), Vector2(0, -0.36)]:
		assert_true(root_y > field.height_at(at.x + offset.x, at.y + offset.y))
