extends "res://tests/test_stormwood_varga_route.gd"

const NPC := preload("res://scripts/npc/npc_body.gd")
const TRAINER := preload("res://scripts/world/trainer_npc.gd")
const SETTLEMENTS_PATH := "res://data/config/stormwood_settlements.json"
const PREFABS_PATH := "res://data/config/building_prefabs.json"
const TERRAIN_PATH := "res://data/config/terrain_stormwood.json"

const FENN_ID := "rodline_keeper_fenn"
const SHELTER_ID := "still_grove_shelter"
const NPC_CAPSULE_RADIUS_M := 0.36
const PLAYER_CAPSULE_RADIUS_M := 0.40
const BODY_CLEARANCE_MARGIN_M := 0.20
const DOOR_APPROACH_M := 3.0
const ROOM_ENTRY_M := 2.0
const NEAR_DOOR_M := 10.0


func test_fenn_and_ondra_have_disjoint_interaction_ranges() -> void:
	var fenn := _by_id(_read(TRAINERS_PATH).get("trainers", []), FENN_ID)
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


func test_fenn_remains_grounded_and_reachable_from_the_local_conductor_road() -> void:
	var fenn := _by_id(_read(TRAINERS_PATH).get("trainers", []), FENN_ID)
	var road := _by_id(_read(WORLD_PATH).get("routes", []), "conductor_road")
	assert_eq(str(fenn.get("region_id", "")), "conductor_run")
	assert_eq(str(fenn.get("route_class", "")), "optional")
	var at := _xz(fenn.get("position", []))
	assert_almost_eq(at.x, -178.4592194978723, 0.0001)
	assert_almost_eq(at.y, 2706.5597586667554, 0.0001)
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


func test_trainers_near_settlement_doors_leave_the_player_capsule_a_clear_route() -> void:
	var trainers: Array = _read(TRAINERS_PATH).get("trainers", [])
	var structures: Array = _read(SETTLEMENTS_PATH).get("structures", [])
	var prefabs: Dictionary = _read(PREFABS_PATH).get("prefabs", {})
	var checked: Array[String] = []
	var required_separation := NPC_CAPSULE_RADIUS_M + PLAYER_CAPSULE_RADIUS_M \
		+ BODY_CLEARANCE_MARGIN_M
	for structure_value: Variant in structures:
		if not structure_value is Dictionary:
			continue
		var structure := structure_value as Dictionary
		var recipe: Dictionary = prefabs.get(str(structure.get("prefab", "")), {})
		var door: Dictionary = recipe.get("door", {})
		var door_at: Array = door.get("at", [])
		var centre: Array = structure.get("at", [])
		if door_at.size() < 3 or centre.size() < 2:
			continue
		var centre_xz := Vector2(float(centre[0]), float(centre[1]))
		var yaw := deg_to_rad(float(structure.get("yaw_deg", 0.0)))
		var threshold := Vector2(float(door_at[0]), float(door_at[2]))
		var outside := threshold + Vector2(0.0, DOOR_APPROACH_M)
		var inside := threshold - Vector2(0.0, ROOM_ENTRY_M)
		for trainer_value: Variant in trainers:
			if not trainer_value is Dictionary:
				continue
			var trainer := trainer_value as Dictionary
			var world_xz := _xz(trainer.get("position", []))
			if world_xz.distance_to(centre_xz) > NEAR_DOOR_M:
				continue
			var local := (world_xz - centre_xz).rotated(yaw)
			var separation := _segment_distance(local, outside, inside)
			var label := "%s beside %s" % [
				str(trainer.get("id", "unnamed trainer")), str(structure.get("id", "unnamed door"))]
			checked.append(label)
			assert_true(separation >= required_separation,
				"%s leaves %.3f m between centres; real capsules plus margin need %.3f m" % [
					label, separation, required_separation])
	assert_true(checked.has("%s beside %s" % [FENN_ID, SHELTER_ID]),
		"the clearance proof must exercise Fenn at the Still Grove shelter")


func test_fenn_is_beside_the_real_shelter_door_and_still_reachable() -> void:
	var fenn := _by_id(_read(TRAINERS_PATH).get("trainers", []), FENN_ID)
	var shelter := _by_id(_read(SETTLEMENTS_PATH).get("structures", []), SHELTER_ID)
	var prefabs: Dictionary = _read(PREFABS_PATH).get("prefabs", {})
	var recipe: Dictionary = prefabs.get(str(shelter.get("prefab", "")), {})
	var door_at: Array = (recipe.get("door", {}) as Dictionary).get("at", [])
	assert_false(fenn.is_empty() or shelter.is_empty() or door_at.size() < 3,
		"Fenn's reachability proof needs the authored trainer, shelter and real door")
	if fenn.is_empty() or shelter.is_empty() or door_at.size() < 3:
		return
	var shelter_at := _xz(shelter.get("at", []))
	var local := (_xz(fenn.get("position", [])) - shelter_at).rotated(
		deg_to_rad(float(shelter.get("yaw_deg", 0.0))))
	var threshold := Vector2(float(door_at[0]), float(door_at[2]))
	assert_almost_eq(local.x, -0.75, 0.0001,
		"Fenn must remain beside the door rather than drift into its centreline")
	assert_almost_eq(local.y, 4.5, 0.0001,
		"Fenn must remain on the shelter's authored front pad")
	assert_true(local.distance_to(threshold) <= TRAINER.PROMPT_RADIUS,
		"the player must be able to reach Fenn's challenge prompt from the doorway")
	var pad := _by_id(_read(TERRAIN_PATH).get("settlement_pads", []), SHELTER_ID)
	for offset in [Vector2.ZERO, Vector2(NPC_CAPSULE_RADIUS_M, 0.0),
			Vector2(-NPC_CAPSULE_RADIUS_M, 0.0), Vector2(0.0, NPC_CAPSULE_RADIUS_M),
			Vector2(0.0, -NPC_CAPSULE_RADIUS_M)]:
		assert_almost_eq(HEIGHTFIELD.settlement_pad_weight_local(local + offset, pad),
			1.0, 0.0001, "Fenn's full capsule must remain on the shelter's flat authored pad")
