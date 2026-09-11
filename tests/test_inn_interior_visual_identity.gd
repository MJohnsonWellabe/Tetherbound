extends "res://tests/test_case.gd"

const INTERIOR := preload("res://scripts/world/inn_interior.gd")
const VILLAGERS_PATH := "res://data/config/village_npcs.json"


func test_common_room_has_timber_architectural_depth_without_blocking_the_door() -> void:
	var root := Node3D.new()
	var interior := INTERIOR.new()
	root.add_child(interior)
	interior.call("build")
	var dressing := interior.get_node_or_null(^"CommonRoomTimberDressing") as Node3D
	assert_true(dressing != null, "the inn common room is still an uninterrupted pale box")
	if dressing == null:
		root.free()
		return
	assert_true(dressing.get_node_or_null(^"WainscotWest") != null,
		"the long guest wall has no timber depth")
	assert_true(dressing.get_node_or_null(^"WainscotBar") != null,
		"the bar wall has no grounded lower course")
	assert_true(dressing.find_child("CeilingTie_*", false, false) != null,
		"the common room has no overhead timber rhythm")
	assert_true(dressing.get_node_or_null(^"DoorWainscotL") != null
		and dressing.get_node_or_null(^"DoorWainscotR") != null,
		"the two door returns are not framed independently")
	assert_true(dressing.get_node_or_null(^"DoorWainscot") == null,
		"a solid wainscot panel blocks the inn threshold")
	for light_name: StringName in [&"BarLight", &"RoomLight", &"DoorLight"]:
		var light := interior.get_node_or_null(NodePath(str(light_name))) as OmniLight3D
		assert_true(light != null, "%s is missing" % light_name)
	var bar := interior.get_node(^"BarLight") as OmniLight3D
	var room := interior.get_node(^"RoomLight") as OmniLight3D
	var door := interior.get_node(^"DoorLight") as OmniLight3D
	assert_true(bar.light_color.r > bar.light_color.b and bar.omni_range < room.omni_range,
		"the hospitality warmth is not localized to the bar")
	assert_true(room.light_color.b > room.light_color.r and door.light_color.b > door.light_color.r,
		"the window and doorway fills no longer balance the red timber/plaster palette")
	assert_true(room.light_energy <= 2.0 and door.light_energy <= 1.5,
		"the cool fill is strong enough to flatten the authored material contrast")
	assert_true(FileAccess.get_file_as_string("res://scripts/world/inn_interior.gd").contains(
		'COL_RUG := Color("#315849")'),
		"the room lost its green textile break and returned to all-red furnishings")
	var counter_joinery := interior.get_node_or_null(^"CounterJoinery") as Node3D
	assert_true(counter_joinery != null and counter_joinery.get_child_count() == 4,
		"the service counter returned to one undetailed primitive face")
	var occupation := interior.get_node_or_null(^"CommonRoomOccupation") as Node3D
	assert_true(occupation != null and occupation.get_child_count() == 2,
		"the two guest tables returned to giant empty boards")
	if occupation != null:
		assert_true(occupation.get_node_or_null(^"GuestTableApples") != null
			and occupation.get_node_or_null(^"GuestTableCrate") != null,
			"installed tavern storage/food clusters are missing from the tables")
		assert_true(occupation.find_child("*Collision*", true, false) == null,
			"presentation-only tabletop dressing added a new collision obstacle")
	root.free()


func test_bram_faces_the_customer_lane_instead_of_the_stock_wall() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(VILLAGERS_PATH))
	assert_true(parsed is Dictionary, "village NPC data did not parse")
	if not parsed is Dictionary:
		return
	var bram: Dictionary = {}
	for raw: Variant in (parsed as Dictionary).get("villagers", []):
		if raw is Dictionary and str((raw as Dictionary).get("name", "")) == "Bram":
			bram = raw as Dictionary
			break
	assert_false(bram.is_empty(), "Bram is no longer placed in the Inn")
	if bram.is_empty():
		return
	# Pin the production-evidence correction directly. Inferring a visible face
	# from Basis vectors is what allowed R1's wrong -90 value to pass: the
	# imported male rig's authored mesh convention is not encoded in this data.
	# The same ten-frame tool is the visual proof that +90 shows his face.
	assert_almost_eq(float(bram.get("facing_deg", 0.0)), 90.0, 0.01,
		"Bram no longer uses the production-corrected patron-facing yaw")
