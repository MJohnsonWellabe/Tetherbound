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
	assert_between(float(stats.approach_distance_m), 12.0, 22.0,
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
	assert_eq(int(stats.shelter_panels), 2,
		"the supported service shelter lost its overlapping canvas courses")
	assert_eq(int(stats.shelter_valances), 1,
		"the shelter has no hanging edge to expose cloth thickness")
	assert_eq(int(stats.shelter_posts), 4,
		"the lean-to needs visible inner and outer support pairs")
	assert_eq(int(stats.supply_props), 4,
		"the watch has lost its installed patrol supplies")
	assert_true(float(stats.shelter_to_camp_m) > WATCH.SERVICE_SHELTER_CLEARANCE * 4.0,
		"the service shelter entered the existing camp/rest cluster")
	assert_true(float(stats.shelter_to_trainer_m) > WATCH.SERVICE_SHELTER_CLEARANCE * 4.0,
		"the service shelter entered the patrol trainer arena")
	assert_true(shelter.find_children("*", "CollisionShape3D", true, false).is_empty(),
		"presentation-only shelter added a new route collision")
	if shelter != null:
		assert_eq(shelter.find_children("ShelterPost*", "MeshInstance3D", true, false).size(), 4,
			"service roof contains unsupported corners")
		assert_true(shelter.find_children("ShelterKneeBrace*", "MeshInstance3D", true, false).size() >= 2,
			"service roof has no visible connection back to the watch")
	world.free()


func test_watchhouse_and_integrated_stair_replace_repeated_box_and_detached_ladder() -> void:
	var world := _built()
	var watch: Node3D = world.get_child(0)
	var house := watch.get_node_or_null(^"UpperWatchhouse") as Node3D
	assert_true(house != null, "lookout remains an undifferentiated repeated X-brace box")
	assert_true(int((watch.call("stats") as Dictionary).watchhouse_pieces) >= 11,
		"upper watch room is too sparse to change the scaffold silhouette")
	assert_eq(house.find_children("PitchedRoof*", "MeshInstance3D", true, false).size(), 2,
		"upper lookout has no coherent pitched cap")
	var repairs := watch.get_node_or_null(^"WatchIntegratedAccess") as Node3D
	assert_true(repairs != null, "watch has no attached ground-to-deck access")
	if repairs != null:
		assert_eq(repairs.find_children("StairTread*", "MeshInstance3D", true, false).size(), 8,
			"attached stair lost its ground-to-deck step rhythm")
		assert_eq(repairs.find_children("StairStringer*", "MeshInstance3D", true, false).size(), 2,
			"access treads are not carried by two visible stringers")
		assert_true(repairs.get_node_or_null(^"AccessLanding") != null,
			"access ends in open air instead of meeting the scaffold deck")
		assert_true(repairs.find_children("*", "CollisionShape3D", true, false).is_empty(),
			"access dressing changed the accepted undercroft collision")
	var stats: Dictionary = watch.call("stats")
	assert_true(int(stats.repair_pieces) >= 11,
		"integrated access is too sparse to connect ground and deck")
	var supports := watch.get_node(^"WatchSupports") as StaticBody3D
	assert_eq(supports.get_child_count(), 4,
		"repair history added supports or sealed the walkable undercroft")
	world.free()


func test_watch_has_two_supported_usable_night_practicals() -> void:
	var world := _built()
	var watch: Node3D = world.get_child(0)
	assert_eq(int((watch.call("stats") as Dictionary).practical_count), 2,
		"watch and service wing do not each have a night practical")
	for holder_name in ["UpperDeckPractical", "ServicePractical"]:
		var holder := watch.get_node_or_null(NodePath(holder_name)) as Node3D
		assert_true(holder != null and holder.get_node_or_null(^"WallBracket") != null,
			"%s floats without a visible bracket" % holder_name)
		assert_true(holder != null and holder.get_node_or_null(^"LanternCage") != null,
			"%s has no installed cage" % holder_name)
		var light: OmniLight3D = null
		if holder != null:
			light = holder.get_node_or_null(^"WarmPool") as OmniLight3D
		assert_true(light != null, "%s has no bounded light" % holder_name)
		assert_between(light.omni_range if light != null else 0.0, 6.0, 9.0,
			"%s spills across the whole hill" % holder_name)
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
	assert_true(source.contains("RIDGELINE-WATCH-R5-FRAMED"),
		"capture output was not bumped to a fresh R5 directory")
	assert_true(source.contains("CAPTURE_CHECK.readable_problems_for_camera"),
		"capture can still write frames whose named watch or service subject is hidden")
	assert_true(source.contains('"subject": "service"'),
		"service evidence does not identify its stricter subject gate")
	assert_true(source.contains("ROUTE_CANDIDATES") and source.contains("CANONICAL_CANDIDATES"),
		"full-watch evidence has no deterministic ordinary-gameplay camera candidates")
	assert_true(source.contains('"camera_candidate"'),
		"the manifest does not disclose which deterministic camera candidate passed")
	assert_true(source.contains('"ordinary player context"'),
		"R5 can select a scenic camera that loses the ordinary player context")
	assert_true(source.contains("CAMERA_BACK_M"),
		"R5 detached the evidence camera from the ordinary third-person player stand-off")
