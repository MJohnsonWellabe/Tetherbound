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
	var outer := tower.get_node_or_null(
		^"InstalledBrickRuin/OuterWardRemnant") as Node3D
	assert_true(outer != null, "Broken Tower exterior has no authored night practical")
	if outer != null:
		var outer_lens := outer.get_node_or_null(^"OuterWardLens") as MeshInstance3D
		var outer_fill := outer.get_node_or_null(^"OuterWardFill") as OmniLight3D
		assert_true(outer_lens != null and outer_lens.mesh != null,
			"Broken Tower outer practical has no visible lens")
		assert_true(outer_fill != null and outer_fill.omni_range <= 18.0,
			"Broken Tower outer practical is missing or unbounded")
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
