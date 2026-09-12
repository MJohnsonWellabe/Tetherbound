extends "res://tests/test_case.gd"

const BROKEN_TOWER := preload("res://scripts/world/watchtower_landmark.gd")


class GroundFixture extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 2.0


func _built() -> Node3D:
	var world := GroundFixture.new()
	var tower: Node3D = BROKEN_TOWER.new()
	world.add_child(tower)
	tower.call("build", world, Vector2(40.0, 6800.0), 180.0)
	return world


func test_broken_tower_uses_installed_brick_art_not_primitive_drums() -> void:
	var world := _built()
	var tower := world.get_child(0)
	var shell := tower.get_node_or_null(^"InstalledBrickRuin")
	assert_true(shell != null, "Broken Tower has no production brick ruin")
	for name in [&"RearWall", &"WestWall", &"BrokenEastWall", &"FallenWallSection"]:
		var piece := shell.get_node_or_null(NodePath(name)) as MeshInstance3D
		assert_true(piece != null and piece.mesh != null,
			"Broken Tower is missing installed masonry piece %s" % name)
		assert_false(piece.mesh is CylinderMesh,
			"Broken Tower regressed to its cylinder placeholder")
		var textured_surfaces := 0
		for surface in piece.mesh.get_surface_count():
			var material := piece.get_active_material(surface) as StandardMaterial3D
			if material != null and material.albedo_texture != null and material.uv1_triplanar:
				textured_surfaces += 1
		assert_true(textured_surfaces >= 1,
			"Broken Tower's installed masonry is still a flat untextured surface")
	world.free()


func test_broken_tower_is_an_open_asymmetric_walkable_ruin() -> void:
	var world := _built()
	var tower := world.get_child(0)
	var shell := tower.get_node(^"InstalledBrickRuin")
	var rear := shell.get_node(^"RearWall") as MeshInstance3D
	var west := shell.get_node(^"WestWall") as MeshInstance3D
	var east := shell.get_node(^"BrokenEastWall") as MeshInstance3D
	assert_true(rear.scale.y > east.scale.y and west.scale.y > east.scale.y,
		"the ruin no longer has a clearly collapsed side")
	var body := tower.get_node_or_null(^"TowerWallCollision") as StaticBody3D
	assert_true(body != null and body.get_child_count() >= 7,
		"the visible ruin does not have bounded wall/rubble collision")
	# Three wall leaves, not a sealed cylinder: there is deliberately no front
	# collision spanning the entrance at local z < 0.
	assert_true(body.get_node_or_null(^"FrontWallCollision") == null,
		"collision sealed the ruin's walkable front mouth")
	assert_true(rear.position.z < 0.0 and
		shell.get_node(^"FallenWallSection").position.z > 0.0,
		"the open broken side no longer faces the authored route at local +Z")
	var foundation := shell.get_node_or_null(^"BrokenFoundation") as Node3D
	assert_true(foundation != null and foundation.get_child_count() >= 7,
		"the surviving tower leaves still have no believable ruin volume at their base")
	assert_true(shell.get_node_or_null(^"FracturedCrownSpur") != null,
		"the tower crown regressed to a level kit silhouette")
	# The route-facing mouth remains open between the offset foundation pieces.
	assert_true(body.get_node_or_null(^"FoundationFrontCollision") == null,
		"foundation dressing blocked the authored entrance route")
	world.free()


func test_route_arch_widens_the_silhouette_without_sealing_the_mouth() -> void:
	var world := _built()
	var tower := world.get_child(0)
	var shell := tower.get_node(^"InstalledBrickRuin") as Node3D
	var arch := shell.get_node_or_null(^"RouteArch") as MeshInstance3D
	assert_true(arch != null and arch.mesh == BROKEN_TOWER.WALL_ENTRANCE_BRICKS,
		"the road face has no installed masonry arch")
	if arch != null:
		assert_between(arch.scale.x * 1.536, 6.2, 6.7,
			"the lower route silhouette is not materially wider than one thin leaf")
		var textured := false
		for surface in arch.mesh.get_surface_count():
			var material := arch.get_active_material(surface) as StandardMaterial3D
			textured = textured or (material != null and material.albedo_texture != null)
		assert_true(textured, "the route arch returned to flat kit material")
	var body := tower.get_node(^"TowerWallCollision") as StaticBody3D
	var west := body.get_node_or_null(^"RouteArchWestPierCollision") as CollisionShape3D
	var east := body.get_node_or_null(^"RouteArchEastPierCollision") as CollisionShape3D
	assert_true(west != null and east != null, "the visible route arch has no bounded piers")
	if west != null and east != null:
		var west_box := west.shape as BoxShape3D
		var east_box := east.shape as BoxShape3D
		var opening := (east.position.x - east_box.size.x * 0.5) - \
			(west.position.x + west_box.size.x * 0.5)
		assert_true(opening >= 3.5, "route arch leaves only %.2fm for the player" % opening)
	assert_true(body.get_node_or_null(^"RouteArchLintelCollision") == null,
		"an unnecessary overhead collider turned the arch into a snag")
	world.free()


func test_watch_purpose_and_threshold_are_visible_without_new_route_collision() -> void:
	var world := _built()
	var tower := world.get_child(0)
	var shell := tower.get_node(^"InstalledBrickRuin") as Node3D
	var remnants := shell.get_node_or_null(^"WatchDeckRemnants") as Node3D
	assert_true(remnants != null, "the ruin contains no former-watch purpose")
	if remnants != null:
		assert_true(remnants.get_node_or_null(^"DeckPlank00") != null
			and remnants.get_node_or_null(^"BrokenWatchLadder/Rung06") != null,
			"the upper watch deck and broken access ladder do not read together")
		assert_true(remnants.find_children("*", "StaticBody3D", true, false).is_empty(),
			"high presentation remnants added invisible gameplay collision")
	var apron := shell.get_node_or_null(^"RouteFlagstones") as Node3D
	assert_true(apron != null and apron.get_child_count() == 4,
		"the route-facing threshold is still swallowed by undifferentiated grass")
	if apron != null:
		for child: Node in apron.get_children():
			assert_true(child is MeshInstance3D and (child as MeshInstance3D).position.y > 0.0,
				"%s was not sampled onto live terrain" % child.name)
	assert_true(tower.get_node(^"TowerWallCollision").find_child("Flagstone*", true, false) == null,
		"visual threshold stones changed the authored route collision")
	world.free()


func test_broken_tower_night_fill_has_a_visible_bounded_source() -> void:
	var world := _built()
	var tower := world.get_child(0)
	var ward := tower.get_node_or_null(
		^"InstalledBrickRuin/FadedTetherWard") as Node3D
	assert_true(ward != null, "Broken Tower night fill has no visible practical source")
	if ward != null:
		var lens := ward.get_node_or_null(^"WardLens") as MeshInstance3D
		var fill := ward.get_node_or_null(^"WardFill") as OmniLight3D
		var route_fill := ward.get_node_or_null(^"RouteFacingFill") as SpotLight3D
		assert_true(lens != null and lens.mesh != null,
			"Broken Tower ward is not visibly modeled")
		assert_true(fill != null and fill.omni_range <= 12.0,
			"Broken Tower fill is missing or spills beyond the landmark")
		assert_true(route_fill != null and route_fill.spot_range <= 24.0 and
			route_fill.spot_angle <= 58.0,
			"Broken Tower has no bounded, practical route-facing night light")
		if lens != null and lens.mesh != null:
			var material := lens.mesh.surface_get_material(0) as StandardMaterial3D
			assert_true(material != null and material.emission_enabled,
				"Broken Tower ward lens does not visibly emit")
			assert_true((lens.mesh as SphereMesh).radius <= 0.18,
				"interior ward lens returned to an oversized white orb")
	var outer := tower.get_node_or_null(
		^"InstalledBrickRuin/OuterWardRemnant") as Node3D
	assert_true(outer != null, "Broken Tower exterior has no authored night practical")
	if outer != null:
		var outer_lens := outer.get_node_or_null(^"OuterWardLens") as MeshInstance3D
		var outer_fill := outer.get_node_or_null(^"OuterWardFill") as OmniLight3D
		var facade_fill := outer.get_node_or_null(^"FacadeFill") as SpotLight3D
		var west_wash := outer.get_node_or_null(^"WestWallWash") as SpotLight3D
		var east_wash := outer.get_node_or_null(^"EastWallWash") as SpotLight3D
		assert_true(outer_lens != null and outer_lens.mesh != null,
			"Broken Tower outer practical has no visible lens")
		assert_true(outer_fill != null and outer_fill.omni_range <= 18.0,
			"Broken Tower outer practical is missing or unbounded")
		assert_true(facade_fill != null and facade_fill.spot_range <= 20.0
			and facade_fill.spot_angle <= 65.0,
			"route-side ward no longer lights the masonry it is mounted on")
		assert_true(west_wash != null and east_wash != null,
			"the ward no longer reveals both unequal surviving wall leaves")
		for wash: SpotLight3D in [west_wash, east_wash]:
			assert_true(wash.spot_range <= 16.0 and wash.spot_angle <= 48.0,
				"a Broken Tower wall wash escaped the bounded ruin footprint")
			assert_true((-wash.transform.basis.z).dot(Vector3(0.0, 0.0, -1.0)) > 0.35,
				"a Broken Tower wall wash no longer aims back into the ruin")
		if outer_lens != null and outer_lens.mesh != null:
			assert_true((outer_lens.mesh as SphereMesh).radius <= 0.15,
				"outer ward lens returned to an oversized white orb")
	world.free()


func test_bulk_wildlife_scatter_stays_out_of_the_named_ruin() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/bands/band4_upper_meadows_ironwood/spawns.json"))
	assert_true(parsed is Dictionary, "Band 4 spawns did not parse")
	if not parsed is Dictionary:
		return
	var tower := Vector2(40.0, 6800.0)
	for raw: Variant in (parsed as Dictionary).get("spawns", []):
		if not raw is Dictionary:
			continue
		var spawn := raw as Dictionary
		var centre: Array = spawn.get("centre", [])
		if centre.size() < 3:
			continue
		var disc_clearance := tower.distance_to(
			Vector2(float(centre[0]), float(centre[2]))) - float(spawn.get("radius", 0.0))
		assert_true(disc_clearance >= 30.0,
			"spawn %s can scatter inside The Broken Tower's named footprint" %
			str(spawn.get("order", "?")))
