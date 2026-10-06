extends "res://tests/test_case.gd"

## F18#5 earned loop (portals on): a trainer standing where the Workbench's
## own Craft prompt wins was refused, because the host measured reach from
## the station root while the prompt is offered at its prompt_offset. The
## host now measures from the station's interaction_origin (the prompt point).
## The unit runner has no SceneTree, so the station is an origin double.
const SESSION := preload("res://scripts/net/session.gd")
const RULES := preload("res://scripts/build/station_rules.gd")

class PromptedStation extends Node3D:
	var prompt_point := Vector3.ZERO
	func interaction_origin() -> Vector3: return prompt_point


func test_host_reach_is_measured_where_the_station_prompt_is_offered() -> void:
	var cfg := RULES.config()
	var offset: Array = cfg.pieces.workbench.prompt_offset
	var root := Vector3(-6.0, 0.9, 18.0) # The earned loop's paid Workbench, yaw 0.
	var station := PromptedStation.new()
	station.position = root
	station.prompt_point = root + Vector3(offset[0], offset[1], offset[2])
	var session := SESSION.new()
	assert_eq(session._station_interaction_origin(station), station.prompt_point, "the host reach point is the prompt's own point")
	# Where the earned loop stood: inside the prompt's radius, outside the root's.
	var trainer := Vector3(-6.01, 0.9, 21.3)
	var radius := float(cfg.interaction_radius_m)
	assert_true(trainer.distance_to(station.prompt_point) <= radius, "the prompt is usable from here")
	assert_true(trainer.distance_to(root) > radius, "the old root measure refused it")
	session.free()
	station.free()
