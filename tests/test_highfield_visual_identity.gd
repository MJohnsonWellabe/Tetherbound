extends "res://tests/test_case.gd"

const PROPS_PATH := "res://data/config/bands/band4_upper_meadows_ironwood/props.json"
const PASTURE_IDENTITY := preload("res://scripts/world/highfield_pasture_identity.gd")


class GroundFixture extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 2.0


func test_highfield_has_an_open_stock_gate_and_working_drover_story() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROPS_PATH))
	assert_true(parsed is Dictionary, "Band 4 props did not parse")
	if not parsed is Dictionary:
		return
	var target: Dictionary = {}
	for raw: Variant in (parsed as Dictionary).get("clusters", []):
		if raw is Dictionary and str((raw as Dictionary).get("name", "")) == "highfield_drove_gate":
			target = raw as Dictionary
			break
	assert_false(target.is_empty(), "Highfield has no authored pasture identity")
	if target.is_empty():
		return
	var fence_count := 0
	var west_edge := -INF
	var east_edge := INF
	var has_wagon := false
	for raw: Variant in target.get("props", []):
		if not raw is Dictionary:
			continue
		var prop := raw as Dictionary
		var model := str(prop.get("model", ""))
		var at: Array = prop.get("at", [])
		if model.begins_with("Prop_WoodenFence") and at.size() >= 2:
			fence_count += 1
			var x := float(at[0])
			if x < 400.0:
				west_edge = maxf(west_edge, x)
			elif x > 400.0:
				east_edge = minf(east_edge, x)
		has_wagon = has_wagon or model == "Prop_Wagon"
	assert_true(fence_count >= 12, "Highfield stock boundary is too sparse to read")
	assert_true(east_edge - west_edge >= 12.0,
		"Highfield fence closed the player/herd lane through its hero gate")
	assert_true(has_wagon, "Highfield has fencing but no working drover story")
	assert_false(JSON.stringify(target).contains("#7a2430"),
		"friendly Highfield scenery leaked Team Tether oxblood")


func test_highfield_has_one_safe_vertical_pasture_identity() -> void:
	var world := GroundFixture.new()
	var identity := PASTURE_IDENTITY.new()
	world.add_child(identity)
	assert_true(bool(identity.call("build", world)), "Highfield pasture identity failed to build")
	var tree := identity.get_node_or_null(^"HighfieldShadeTree") as Node3D
	assert_true(tree != null, "Highfield still has no dominant natural silhouette")
	var stats := identity.call("stats") as Dictionary
	assert_true(float(stats.hero_height_m) >= 24.0 and float(stats.hero_width_m) >= 18.0,
		"Highfield hero tree is too small to unify herd, gate and camp")
	var hero_at: Vector2 = stats.get("hero_at", Vector2.INF)
	assert_eq(hero_at, PASTURE_IDENTITY.HERO_AT,
		"pasture identity drifted off the gate/camp backplane")
	assert_true(hero_at.distance_to(Vector2(377.5, 5855.3)) >= 45.0
		and hero_at.distance_to(Vector2(425.0, 5844.0)) >= 55.0,
		"pasture tree crowds a live Meadowhart encounter")
	var collision := identity.get_node_or_null(^"HighfieldShadeTreeCollision/CollisionShape3D") as CollisionShape3D
	assert_true(collision != null and collision.shape is CylinderShape3D,
		"hero tree uses a canopy-sized box or has no gameplay collision")
	if collision != null and collision.shape is CylinderShape3D:
		assert_true((collision.shape as CylinderShape3D).radius <= 1.75,
			"hero-tree collision blocks the open pasture around its trunk")
	var lanterns := identity.get_node_or_null(^"HighfieldDroverLanterns") as Node3D
	assert_true(lanterns != null and int(stats.lantern_count) == 2,
		"Highfield vertical identity disappears at night")
	assert_true(FileAccess.get_file_as_string("res://scripts/world/playground_world.gd").contains(
		'highfield_identity.name = "HighfieldPastureIdentity"'),
		"production Meadows does not build the Highfield identity")
	world.free()
