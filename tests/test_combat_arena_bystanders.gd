extends "res://tests/test_case.gd"

## F04#1 (C3 judge 257839f5): a relay grunt stood inside Vance's charging
## Tuskroot. Set-dressing people inside a fight's ring walk out to its edge
## when the fight opens and back when it closes; people outside, and bodies
## not in the bystander group, are left alone.

const ARENA_SCRIPT := preload("res://scripts/combat/combat_arena.gd")


func test_bystanders_inside_the_ring_step_straight_out_to_its_edge() -> void:
	# Pure placement (the unit runner has no live tree for the group walk).
	var centre := Vector3(0.0, 5.0, 0.0)
	var edge := ARENA_SCRIPT.bystander_edge(centre, 12.0, Vector3(4.0, 5.2, 0.0))
	assert_true(edge.is_finite(), "the grunt in the ring walks out")
	assert_almost_eq(edge.x, 12.0, 0.001, "to the ring's edge plus the margin, straight out")
	assert_almost_eq(edge.z, 0.0, 0.001, "along the line from the fight's centre")
	assert_almost_eq(edge.y, 5.2, 0.001, "keeping their own ground height as a start")
	assert_false(ARENA_SCRIPT.bystander_edge(centre, 12.0, Vector3(20.0, 5.0, 0.0)).is_finite(),
		"a bystander already clear is left alone")
	var dead_centre := ARENA_SCRIPT.bystander_edge(centre, 12.0, centre)
	assert_almost_eq(Vector2(dead_centre.x, dead_centre.z).length(), 12.0, 0.001, "even one on the exact centre gets out")


func test_only_set_dressing_joins_the_group() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/village_npcs.gd")
	assert_true(source.contains("if not has_anything_to_say(spec):\n\t\t# Pure set dressing"),
		"village_npcs.gd adds only bodies with nothing to say")
	assert_true(source.contains("npc.add_to_group(COMBAT_ARENA.BYSTANDER_GROUP)"), "to the arena's group")


func test_the_arena_config_turns_it_on() -> void:
	var arena: Dictionary = preload("res://scripts/combat/combat_math.gd").config()["arena"]
	assert_true(bool(arena.get("clear_bystanders", false)), "fights clear set dressing from the ring")
