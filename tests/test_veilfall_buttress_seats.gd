extends "res://tests/test_case.gd"

## close-1024 fc4: the Veilfall flank buttresses carry trimesh collision, so
## every seat must stay well clear of the authored hikes, anchors and the gate.
const HEIGHTFIELD := preload("res://scripts/world/water_heightfield.gd")
const MIN_TRAIL_CLEARANCE_M := 40.0


func test_every_buttress_seat_is_clear_of_the_walked_routes() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/tidewake_look.json"))
	var seats: Array = raw.get("veilfall_buttress_candidate", [])
	assert_true(seats.size() > 0, "the candidate is in the file")
	var field: RefCounted = HEIGHTFIELD.shared()
	for spec: Dictionary in seats:
		var at: Array = spec.position_xz_m
		var clear := float(field.call("_nearest_trail_distance", float(at[0]), float(at[1])))
		assert_true(clear >= MIN_TRAIL_CLEARANCE_M,
			"%s sits %.1f m from a walked route" % [spec.get("id", "?"), clear])
		assert_true(bool(spec.get("trimesh_collider", false)), "collision matches the drawn buttress")
