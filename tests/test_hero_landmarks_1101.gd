extends "res://tests/test_case.gd"

## Cause lane LANDMARKS (1 Nov): the 1101 Meshy hero landmarks ship OFF, OFF
## changes nothing, and ON swaps in the mesh at the configured scale while
## every collider, trigger and old node stays in place.

const HERO := preload("res://scripts/world/hero_landmarks_1101.gd")
const CROWN := preload("res://scripts/world/stormwood_crown_arch_hero.gd")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _with_on(id: String) -> Dictionary:
	var config := HERO.settings().duplicate(true)
	var cand: Dictionary = (config[id] as Dictionary).duplicate(true)
	cand["enabled"] = true
	config[id] = cand
	return config


func _world_aabb(node: Node3D, include_root: bool = true) -> AABB:
	var box := AABB()
	var first := true
	for visual: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		if visual.mesh == null or not visual.is_visible_in_tree() or visual.name == "GlassPool":
			continue
		var t := Transform3D.IDENTITY
		var current: Node = visual
		var stop: Node = node.get_parent() if include_root else node
		while current != null and current != stop:
			if current is Node3D:
				t = (current as Node3D).transform * t
			current = current.get_parent()
		var b := t * visual.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


func _colliders(root: Node) -> int:
	return root.find_children("*", "CollisionObject3D", true, false).size()


func test_all_three_ship_off_with_a_declared_scope() -> void:
	var config := HERO.settings()
	assert_eq(str(config.get("scope", "")), "client_presentation", "new flags declare scope")
	for id: String in ["crown_arch", "glass_sink", "veilfall"]:
		assert_true(config.has(id), "%s candidate declared" % id)
		assert_false(HERO.enabled(id), "%s ships OFF" % id)
		assert_true(ResourceLoader.exists(str((config[id] as Dictionary).get("model", ""))),
			"%s model is imported" % id)


func test_crown_arch_off_leaves_the_landed_arch_settings() -> void:
	var landed := CROWN.with_round2(_json("res://data/config/crown_arch_hero.json"))
	assert_eq(HERO.crown_arch_overlay(landed), landed, "OFF must not change the hero arch")
	assert_eq(CROWN.settings(), landed, "the shipped settings are the round-2 arch")


func test_crown_arch_on_swaps_the_model_keeps_yaw_and_colliders() -> void:
	var landed := CROWN.with_round2(_json("res://data/config/crown_arch_hero.json"))
	var on := HERO.crown_arch_overlay(landed, _with_on("crown_arch"))
	assert_true(str(on.model).contains("meshy-1101/crown_arch_hero"), "ON uses the 1101 arch")
	assert_true(float(on.height_m) >= 5.5, "the arch stands at least 5.5 m")
	assert_eq(on.yaw_deg, landed.yaw_deg, "ON keeps the round-2 road-facing yaw")
	assert_eq(on.get("enabled"), landed.get("enabled"), "the switch does not leak into the arch keys")
	var arch := Node3D.new()
	var footing := StaticBody3D.new()
	footing.name = "Footing"
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	footing.add_child(shape)
	arch.add_child(footing)
	var passage := Area3D.new()
	passage.name = "Passage"
	passage.position = Vector3(0, 1.25, 0)
	arch.add_child(passage)
	var piece := Node3D.new()
	var old_mesh := MeshInstance3D.new()
	old_mesh.mesh = BoxMesh.new()
	piece.add_child(old_mesh)
	arch.add_child(piece)
	var slab := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(9, 0.4, 9)
	slab.mesh = box
	arch.add_child(slab)
	# Round 2's slab edge stones need the live tree (global transforms); they
	# are covered by test_storm_cams_candidates. This checks the model swap.
	var swap := on.duplicate(true)
	swap.erase("edge_dressing")
	assert_true(CROWN.apply(arch, piece, slab, null, swap), "ON applies the hero arch")
	var hero := arch.get_node_or_null("CrownArchHero") as Node3D
	assert_true(hero != null, "the hero arch is mounted")
	assert_almost_eq(_world_aabb(hero).size.y, float(on.height_m), 0.05, "fitted to the configured height")
	assert_false(old_mesh.visible, "the old arch visual is hidden")
	assert_true(arch.get_node_or_null("Footing") == footing and footing.get_child_count() == 1, "footing collider kept")
	assert_eq(passage.position, Vector3(0, 1.25, 0), "passage trigger untouched")
	assert_eq(_colliders(hero), 0, "the hero arch adds no collider")
	arch.free()


func test_glass_sink_off_adds_nothing() -> void:
	var world := Node3D.new()
	var sink := {"centre": [700, 2700], "floor_y": -65, "island_radius": 250}
	assert_true(HERO.dress_glass_sink(world, sink) == null, "OFF returns no node")
	assert_eq(world.get_child_count(), 0, "OFF adds nothing to the world")
	world.free()


func test_glass_sink_on_sets_the_basin_into_the_sink_without_colliders() -> void:
	var config := _with_on("glass_sink")
	var cfg: Dictionary = config.glass_sink
	var world := Node3D.new()
	var sink := {"centre": [700, 2700], "floor_y": -65, "island_radius": 250}
	var root := HERO.dress_glass_sink(world, sink, config)
	assert_true(root != null and root.get_parent() == world, "ON mounts the basin")
	var box := _world_aabb(root)
	assert_almost_eq(maxf(box.size.x, box.size.z), float(cfg.across_m), 0.5, "fitted to across_m")
	assert_almost_eq(box.end.y, float(cfg.rim_top_y), 0.1, "rim top at rim_top_y")
	assert_almost_eq(box.position.y, -65.0 - float(cfg.bury_m), 0.1, "bottom buried under the floor")
	var centre: Array = cfg.centre_xz
	assert_almost_eq(box.get_center().x, float(centre[0]), 0.5, "centred on centre_xz (x)")
	assert_almost_eq(box.get_center().z, float(centre[1]), 0.5, "centred on centre_xz (z)")
	var pool := root.get_node_or_null("GlassPool") as MeshInstance3D
	assert_true(pool != null, "the glass pool fills the open centre")
	assert_between(root.position.y + pool.position.y, -65.0, -63.0, "pool just above the floor")
	assert_eq(_colliders(root), 0, "render-only: no collider")
	assert_true(HERO.dress_glass_sink(world, sink, config) == null, "never mounted twice")
	world.free()


func _veilfall_fixture() -> Array:
	var parent := Node3D.new()
	var silhouette := MeshInstance3D.new()
	silhouette.name = "VeilfallFarSilhouette"
	silhouette.mesh = BoxMesh.new()
	parent.add_child(silhouette)
	var crag := MeshInstance3D.new()
	crag.name = "Far_Crag_A"
	crag.mesh = BoxMesh.new()
	silhouette.add_child(crag)
	var falls := Node3D.new()
	var ribbon := MeshInstance3D.new()
	ribbon.mesh = BoxMesh.new()
	falls.add_child(ribbon)
	parent.add_child(falls)
	return [parent, silhouette, crag, falls, ribbon]


func test_veilfall_off_changes_nothing() -> void:
	var f := _veilfall_fixture()
	assert_true(HERO.dress_veilfall(f[0], f[1], f[3]) == null, "OFF returns no node")
	assert_eq((f[1] as MeshInstance3D).layers, 1, "OFF keeps the cone drawn")
	assert_true((f[2] as Node3D).visible, "OFF keeps the far crags")
	assert_eq((f[4] as GeometryInstance3D).visibility_range_end, 0.0, "OFF keeps the falls at every range")
	(f[0] as Node).free()


func test_veilfall_on_replaces_the_far_cone_only_beyond_the_handoff() -> void:
	var config := _with_on("veilfall")
	var cfg: Dictionary = config.veilfall
	var f := _veilfall_fixture()
	var root := HERO.dress_veilfall(f[0], f[1], f[3], config)
	assert_true(root != null, "ON mounts the mountain")
	var box := _world_aabb(root)
	var plan := _world_aabb(root, false)
	assert_almost_eq(maxf(plan.size.x, plan.size.z), float(cfg.across_m), 1.0, "fitted to the cone footprint")
	assert_between(box.size.y, 450.0, 700.0, "about the 620 m terrain peak")
	assert_almost_eq(box.position.y, float(cfg.base_y) - float(cfg.sink_m), 0.5, "seated at sea level")
	for visual: GeometryInstance3D in root.find_children("*", "GeometryInstance3D", true, false):
		assert_eq(visual.visibility_range_begin, float(cfg.visible_from_m), "far only")
	assert_eq((f[1] as MeshInstance3D).layers, 0, "the polar-grid cone stops drawing")
	assert_false((f[2] as Node3D).visible, "the far crag copies stop drawing")
	assert_eq((f[4] as GeometryInstance3D).visibility_range_end, float(cfg.old_falls_far_hidden_from_m),
		"old fall ribbons stop only past the handoff")
	assert_eq(_colliders(root), 0, "render-only: no collider")
	(f[0] as Node).free()
