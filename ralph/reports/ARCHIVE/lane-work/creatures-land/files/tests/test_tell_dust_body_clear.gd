extends "res://tests/test_case.gd"

# P2-016 G5 (GPU): a heavy's puff trail started inside the attacker's own
# footprint and buried its body, so the flinch around it could not read.
# Puffs whose ground point falls inside the cleared circle are left out; the
# rest of the lane keeps its dust.

const STYLE := preload("res://scripts/combat/tell_style.gd")


func _count(clear: Vector3) -> int:
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = MultiMesh.new()
	instance.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	instance.multimesh.use_colors = true
	var lane := PackedVector3Array([Vector3.ZERO, Vector3(0.0, 0.0, 10.0)])
	STYLE.draw_dust(instance, [lane], {"dust_spacing_m": 0.5, "dust_max": 500, "dust_alpha": 0.9},
		1.0, 0.3, 1.0, false, clear)
	var count := instance.multimesh.instance_count
	instance.free()
	return count


func test_puffs_inside_the_attacker_footprint_are_left_out() -> void:
	var all := _count(Vector3.ZERO)
	var cleared := _count(Vector3(0.0, 0.0, 2.0))
	assert_eq(all, 20, "a 10 m lane at 0.5 m spacing carries 20 puffs")
	assert_eq(cleared, 16, "the four puffs within 2 m of the body are left out")


func test_the_shipped_style_clears_a_footprint() -> void:
	var cfg: Dictionary = preload("res://scripts/combat/combat_math.gd").config()
	var text := JSON.stringify(cfg)
	assert_true(text.contains("\"dust_body_clear\""), "combat.json names the clearance")
