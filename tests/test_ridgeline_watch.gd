extends "res://tests/test_case.gd"

const WATCH := preload("res://scripts/world/ridgeline_watch.gd")


class GroundFixture extends Node3D:
	func ground_height_at(x: float, z: float) -> float:
		return 2.0 + x * 0.002 + z * 0.0003


func _built() -> Node3D:
	var world := GroundFixture.new()
	var watch: Node3D = WATCH.new()
	world.add_child(watch)
	assert_true(bool(watch.call("build", world)), "Ridgeline Watch failed its production build path")
	return world


func test_named_watch_builds_a_dominant_installed_asset_silhouette() -> void:
	var world := _built()
	var watch: Node3D = world.get_child(0)
	assert_true(watch.get_node_or_null(^"LookoutFrame") != null,
		"the named watch has no installed scaffold frame")
	assert_true(watch.get_node_or_null(^"SignalMast") != null,
		"the watch has no skyline signal mast")
	var stats: Dictionary = watch.call("stats")
	assert_true(float(stats.visual_height_m) >= WATCH.MIN_VISUAL_HEIGHT,
		"the lookout is too short to own the Ridgeline skyline")
	assert_eq(int(stats.support_count), 4, "the lookout must stand on four bounded supports")
	world.free()


func test_canonical_position_and_ordinary_approach_both_see_the_same_watch() -> void:
	var world := _built()
	var stats: Dictionary = world.get_child(0).call("stats")
	assert_between(float(stats.canonical_distance_m), 6.0, 12.0,
		"the canonical named-location position is not beside the lookout")
	assert_between(float(stats.approach_distance_m), 25.0, 45.0,
		"the ordinary locations-pass approach is not an establishing distance")
	world.free()


func test_support_collision_preserves_camp_trainer_and_canonical_arrival() -> void:
	var world := _built()
	var watch: Node3D = world.get_child(0)
	var supports: Array[Vector2] = watch.call("support_world_positions")
	for support in supports:
		assert_true(support.distance_to(WATCH.CANONICAL_VIEW) > 3.0,
			"a support blocks the canonical Settings arrival")
		assert_true(support.distance_to(WATCH.PATROL_TRAINER) > 8.0,
			"a support intrudes into the patrol trainer arena")
		assert_true(support.distance_to(WATCH.CAMP_CENTRE) > 8.0,
			"a support intrudes into the existing camp/rest cluster")
	var body := watch.get_node_or_null(^"WatchSupports") as StaticBody3D
	assert_true(body != null, "the lookout has no bounded support collision")
	assert_eq(body.get_child_count() if body != null else 0, 4,
		"collision must stay on the four supports, not seal the undercroft")
	world.free()


func test_asymmetric_service_shelter_adds_lived_structure_without_invading_encounters() -> void:
	var world := _built()
	var watch: Node3D = world.get_child(0)
	var shelter := watch.get_node_or_null(^"WatchServiceShelter") as Node3D
	assert_true(shelter != null, "the repeated scaffold box has no asymmetric service wing")
	var stats: Dictionary = watch.call("stats")
	assert_eq(int(stats.shelter_panels), 15,
		"the service shelter returned to three long flat canvas planes")
	assert_eq(int(stats.shelter_valances), 5,
		"the shelter has no hanging edge to expose cloth thickness")
	assert_eq(int(stats.shelter_posts), 2,
		"the lean-to must stay tied to the watch with only two outer posts")
	assert_eq(int(stats.supply_props), 2,
		"the watch has lost its installed patrol supplies")
	assert_true(float(stats.shelter_to_camp_m) > WATCH.SERVICE_SHELTER_CLEARANCE * 4.0,
		"the service shelter entered the existing camp/rest cluster")
	assert_true(float(stats.shelter_to_trainer_m) > WATCH.SERVICE_SHELTER_CLEARANCE * 4.0,
		"the service shelter entered the patrol trainer arena")
	assert_true(shelter.find_children("*", "CollisionShape3D", true, false).is_empty(),
		"presentation-only shelter added a new route collision")
	if shelter != null:
		var panels := shelter.find_children("WeatheredCanvas_*", "MeshInstance3D", true, false)
		assert_eq(panels.size(), 15, "weathered roof lost its segmented folded surface")
		var lowest := INF
		var highest := -INF
		var rolls := {}
		for raw: Node in panels:
			var panel := raw as MeshInstance3D
			lowest = minf(lowest, panel.position.y)
			highest = maxf(highest, panel.position.y)
			rolls[snappedf(panel.rotation.z, 0.001)] = true
		assert_true(highest - lowest >= 0.40 and rolls.size() >= 5,
			"segmented canvas still collapses into one thin flat roof line")
	world.free()


func test_repair_history_breaks_the_repeated_x_box_without_new_supports() -> void:
	var world := _built()
	var watch: Node3D = world.get_child(0)
	var repairs := watch.get_node_or_null(^"WatchRepairHistory") as Node3D
	assert_true(repairs != null, "lookout remains an undifferentiated repeated X-brace box")
	if repairs != null:
		var windbreak := repairs.get_node_or_null(^"UpperWindbreak") as Node3D
		var ladder := repairs.get_node_or_null(^"EastAccessLadder") as Node3D
		assert_true(windbreak != null and ladder != null,
			"lookout repair history lacks two different face functions")
		if windbreak != null:
			assert_eq(windbreak.find_children("WindbreakPlank*", "MeshInstance3D",
				true, false).size(), 4, "upper bay windbreak returned to one flat slab")
		if ladder != null:
			assert_eq(ladder.find_children("LadderRung*", "MeshInstance3D",
				true, false).size(), 7, "east face has no readable access rhythm")
		assert_true(repairs.find_children("*", "CollisionShape3D", true, false).is_empty(),
			"repair overlays changed the accepted undercroft collision")
	var stats: Dictionary = watch.call("stats")
	assert_true(int(stats.repair_pieces) >= 15,
		"repair overlays are too sparse to break both repeated scaffold levels")
	var supports := watch.get_node(^"WatchSupports") as StaticBody3D
	assert_eq(supports.get_child_count(), 4,
		"repair history added supports or sealed the walkable undercroft")
	world.free()


func test_watch_light_has_an_installed_cage_and_visible_source() -> void:
	var world := _built()
	var watch: Node3D = world.get_child(0)
	assert_true(watch.get_node_or_null(^"InstalledWatchLantern/LanternCage") != null,
		"the lookout light is still an invisible OmniLight")
	assert_true(watch.get_node_or_null(^"InstalledWatchLantern/VisibleWarmSource") != null,
		"the installed lantern has no visible warm source")
	var light := watch.get_node_or_null(^"InstalledWatchLantern/WatchLantern") as OmniLight3D
	assert_true(light != null, "the installed lantern has no bounded light")
	assert_between(light.omni_range if light != null else 0.0, 6.0, 10.0,
		"the lookout lamp spills across the whole hill instead of lighting its deck")
	world.free()


func test_production_world_wires_the_named_node_separately_from_broken_tower() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/playground_world.gd")
	assert_true(source.contains('ridgeline_watch.name = "RidgelineWatch"'),
		"the production Meadows scene does not build the named Ridgeline Watch node")
	assert_true(source.contains('watchtower.name = "RuinedWatchtower"'),
		"the separate Broken Tower landmark was accidentally replaced")


func test_capture_hides_hud_and_freezes_the_player() -> void:
	var source := FileAccess.get_file_as_string("res://tools/capture_ridgeline_watch_identity.gd")
	assert_true(source.contains('^"PlaygroundHUD"'), "the evidence harness no longer targets the HUD")
	assert_true(source.contains('overlay.set("visible", false)'), "HUD still dominates watch evidence")
	assert_true(source.contains("player.process_mode = Node.PROCESS_MODE_DISABLED"),
		"the evidence player is not frozen")
	assert_true(source.contains(".velocity = Vector3.ZERO"),
		"player locomotion velocity survives evidence placement")
