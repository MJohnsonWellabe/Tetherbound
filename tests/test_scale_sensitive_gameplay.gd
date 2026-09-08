extends "res://tests/test_case.gd"

const COMBAT := preload("res://scripts/combat/combat_manager.gd")
const THROW_AIM := preload("res://scripts/combat/throw_aim.gd")
const RIDING := preload("res://scripts/world/riding_controller.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")


class Fighter extends Node3D:
	var radius := 0.5
	func body_radius() -> float:
		return radius


class RoomManager extends "res://scripts/combat/combat_manager.gd":
	func _ready() -> void:
		set_physics_process(false)

	func seed(player: Node3D, wild: Node3D, ally: Node3D) -> void:
		_player = player
		_wild = wild
		_ally_body = ally

	func seed_party(creature: RefCounted) -> void:
		_party = [creature]
		_active_index = 0

	# A player close to the +Z wall, with a full formation's worth of room -Z.
	func _arena_bounds(at: Vector3) -> float:
		return 1.0 if at.z >= -10.0 and at.z <= 2.0 else -1.0


func _case_built_room_staging_uses_the_direction_that_preserves_separation() -> void:
	var fixture := Node3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(fixture)
	var player := Fighter.new()
	var wild := Fighter.new()
	var ally := Fighter.new()
	var manager := RoomManager.new()
	for node in [player, wild, ally, manager]:
		fixture.add_child(node)
	player.position = Vector3.ZERO
	wild.position = Vector3(0.0, 0.0, 1.0)
	manager.seed(player, wild, ally)
	var spots: Array[Vector3] = manager.call("_staging_spots",
		{"deploy_offset": 2.6, "separation": 5.0})
	assert_true(spots[0].z < 0.0, "the formation turns into the room's available floor")
	assert_almost_eq(spots[0].distance_to(spots[1]), 5.0, 0.001,
		"containment preserves authored fighter separation instead of crushing large bodies together")
	assert_true(manager.call("_arena_bounds", spots[0]) > 0.0)
	assert_true(manager.call("_arena_bounds", spots[1]) > 0.0)
	fixture.free()


func _case_combat_reach_uses_the_live_pair_of_gameplay_bodies() -> void:
	var fixture := Node3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(fixture)
	var manager := RoomManager.new()
	var player := Fighter.new()
	var wild := Fighter.new()
	var ally := Fighter.new()
	for node in [player, wild, ally, manager]:
		fixture.add_child(node)
	ally.radius = float(SPECIES.placeholder("terrapup").get("radius", 0.5))
	wild.radius = float(SPECIES.placeholder("galecrest").get("radius", 0.5))
	manager.seed(player, wild, ally)
	manager.seed_party(SPECIES.spawn("terrapup"))
	var expected: Dictionary = COMBAT.floor_reach_for_bodies(
		{"range": 2.6}, ally.radius, wild.radius)
	assert_almost_eq(float(manager.call("combat_move_reach", "quick")),
		float(expected.range), 0.001)
	assert_true(float(expected.range) > ally.radius + wild.radius,
		"a point-blank swing reaches across two non-overlapping large bodies")
	fixture.free()


func test_initialized_combat_geometry_contracts() -> void:
	var path := "user://scale-sensitive-gameplay-child.gd"
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_true(file != null)
	if file == null:
		return
	file.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_scale_sensitive_gameplay.gd").new()\n\ttest._case_built_room_staging_uses_the_direction_that_preserves_separation()\n\ttest._case_combat_reach_uses_the_live_pair_of_gameplay_bodies()\n\tprint("SCALE_GAMEPLAY_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures}))\n\tquit(0 if test.failures.is_empty() and test.assertion_count == 6 else 1)\n')
	file.close()
	var output: Array = []
	var absolute := ProjectSettings.globalize_path(path)
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path",
		ProjectSettings.globalize_path("res://"), "--script", absolute, "--log-file",
		ProjectSettings.globalize_path("user://scale-sensitive-gameplay-child.log")], output, true)
	DirAccess.remove_absolute(absolute)
	var combined := "\n".join(output)
	assert_eq(code, 0, combined)
	assert_false(combined.contains("SCRIPT ERROR") or combined.contains("ERROR:"), combined)
	var result: Dictionary = {}
	for line: String in combined.split("\n"):
		if line.begins_with("SCALE_GAMEPLAY_RESULT="):
			result = JSON.parse_string(line.trim_prefix("SCALE_GAMEPLAY_RESULT="))
	assert_eq(int(result.get("assertions", 0)), 6, combined)
	assert_eq(result.get("failures", ["missing result"]), [])


func test_large_target_aim_assist_never_turns_a_fifty_degree_miss_into_a_lock() -> void:
	var along := 8.0
	var huge_body_width := 6.0
	assert_almost_eq(THROW_AIM.aim_pull_weight(
		along * tan(deg_to_rad(50.0)), huge_body_width, along), 0.0, 0.0001)
	assert_true(THROW_AIM.aim_pull_weight(
		along * tan(deg_to_rad(20.0)), huge_body_width, along) > 0.0,
		"the angular cap keeps a useful near-reticle assist on a large creature")
	assert_almost_eq(THROW_AIM.aim_pull_weight(0.0, huge_body_width, along), 1.0, 0.0001)


func test_mount_range_is_measured_from_the_large_creatures_surface() -> void:
	var body_at := Vector3(10.0, 3.0, -4.0)
	assert_almost_eq(RIDING.mount_surface_distance(
		body_at + Vector3(3.0, 0.0, 0.0), body_at, 2.0), 1.0, 0.0001,
		"the prompt measures one metre of air beyond the body")
	assert_almost_eq(RIDING.mount_surface_distance(
		body_at + Vector3(1.0, 0.0, 0.0), body_at, 2.0), 0.0, 0.0001,
		"a point inside the radius is at the body surface, never negative")
	assert_true(RIDING.mount_surface_distance(
		body_at + Vector3(0.0, 20.0, 0.0), body_at, 2.0) > 4.5,
		"surface distance does not offer a ground mount to a trainer far above it")
