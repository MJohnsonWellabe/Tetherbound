extends "res://tests/test_case.gd"

## F41#1 (LANE-BELOW6, 12 Nov 2026): the entrance ramp's body is presentation
## only. It is declared OFF until GPU-judged, and with it forced on the ramp's
## collision shape is byte-identical and the body carries no collider.

const PRESENTATION_PATH := "res://data/config/stormheart_presentation.json"
const STORMHEART := preload("res://scripts/world/stormheart_tree.gd")
const START := Vector3(0, 0.2, -120)


class ForcedTree extends STORMHEART:
	var force_ramp_body := false
	func _read_presentation() -> Dictionary:
		var presentation := super._read_presentation()
		if force_ramp_body:
			var cfg: Dictionary = (presentation.get("ramp_body_1112", {}) as Dictionary).duplicate()
			cfg["enabled"] = true
			presentation["ramp_body_1112"] = cfg
		return presentation


func _ramp_faces(tree: Node3D) -> PackedVector3Array:
	var body := tree.get_node("OuterWorksApproach") as StaticBody3D
	var shape := (body.get_child(0) as CollisionShape3D).shape as ConcavePolygonShape3D
	return shape.get_faces()


func _free_tree(tree: Node3D) -> void:
	tree.free()


func test_ramp_body_declared_off_and_presentation_only() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PRESENTATION_PATH))
	var cfg: Dictionary = (parsed as Dictionary).get("ramp_body_1112", {})
	assert_false(cfg.is_empty(), "ramp_body_1112 must be declared")
	assert_false(bool(cfg.get("enabled", true)), "ramp_body_1112 ships OFF until GPU-judged")
	assert_eq(str(cfg.get("scope", "")), "client_presentation")


func test_ramp_collision_is_unchanged_and_the_body_has_no_collider() -> void:
	var plain := ForcedTree.new()
	plain.build()
	plain.add_approach(START)
	var dressed := ForcedTree.new()
	dressed.force_ramp_body = true
	dressed.build()
	dressed.add_approach(START)
	assert_eq(_ramp_faces(dressed), _ramp_faces(plain), "the ramp's collision quad is byte-identical with the body on")
	assert_false(plain.has_node("RampBody1112"), "no body while the flag is off")
	var holder := dressed.get_node_or_null("RampBody1112")
	assert_true(holder != null, "the body is built when the flag is on")
	if holder != null:
		assert_eq(holder.find_children("*", "CollisionObject3D", true, false).size(), 0, "the body adds no collider")
		assert_true(holder.find_children("Post", "MeshInstance3D", true, false).size() >= 8, "posts line both sides")
	_free_tree(plain)
	_free_tree(dressed)
