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
	var wainscot := dressing.get_node(^"WainscotWest") as MeshInstance3D
	var timber_material := wainscot.material_override as StandardMaterial3D
	assert_true(timber_material != null and timber_material.albedo_texture != null
		and timber_material.normal_texture != null and timber_material.roughness_texture != null,
		"the architectural timber returned to flat-colour blockout material")
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
	assert_true(counter_joinery != null and counter_joinery.get_child_count() >= 18,
		"the service counter lost its furniture joinery and working return")
	if counter_joinery != null:
		assert_true(counter_joinery.get_node_or_null(^"CounterDeskJoinery") == null,
			"the broad repeated-panel furniture desk returned in front of the bar")
		for detail_name: StringName in [&"CounterTopSlab", &"CounterOpenRackBack",
				&"CounterRackShelf", &"CounterCupboardDoor", &"CounterEastReturn",
				&"CounterFootRail", &"CounterBarTowel", &"AleTapStem", &"AleTapSpout"]:
			assert_true(counter_joinery.get_node_or_null(NodePath(str(detail_name))) != null,
				"%s is missing from the working-bar silhouette" % detail_name)
		var rack := counter_joinery.get_node(^"CounterOpenRackBack") as MeshInstance3D
		var cupboard := counter_joinery.get_node(^"CounterCupboardDoor") as MeshInstance3D
		assert_true((rack.mesh as BoxMesh).size.x > (cupboard.mesh as BoxMesh).size.x * 1.8,
			"the customer face returned to evenly repeated panel bays")
		assert_true(counter_joinery.find_child("*Collision*", true, false) == null,
			"presentation-only bar joinery changed the established counter collision")
	var occupation := interior.get_node_or_null(^"CommonRoomOccupation") as Node3D
	assert_true(occupation != null and occupation.get_child_count() == 8,
		"the two guest tables returned to giant empty boards")
	if occupation != null:
		assert_true(occupation.get_node_or_null(^"GuestTableApples") != null
			and occupation.get_node_or_null(^"GuestTableServingPot") != null,
			"installed food/serving clusters are missing from the tables")
		var serving_pot := occupation.get_node(^"GuestTableServingPot") as Node3D
		assert_true(serving_pot.scale.x >= 0.5 and serving_pot.scale.x <= 0.6,
			"the serving pot is no longer a believable tabletop-scale vessel")
		assert_true(occupation.get_node_or_null(^"GuestTableCrate") == null,
			"the east dining table still carries an empty shipping crate")
		assert_true(occupation.get_node_or_null(^"WestTableRunner") != null
			and occupation.get_node_or_null(^"EastTableRunner") != null,
			"the occupied dining tables lost their fitted textile runners")
		for setting_name: StringName in [&"WestNear", &"EastNear"]:
			var setting := occupation.get_node_or_null(NodePath(str(setting_name))) as Node3D
			assert_true(setting != null and setting.get_node_or_null(^"Plate") != null
				and setting.get_node_or_null(^"Tankard") != null,
				"%s no longer reads as a complete occupied place setting" % setting_name)
		assert_true(occupation.get_node_or_null(^"WestFar/SharedBowl") != null
			and occupation.get_node_or_null(^"EastFar/BreadBoard") != null,
			"far table stretches returned to repeated plate-and-mug staging")
		assert_true(occupation.get_node_or_null(^"WestFar/Plate") == null
			and occupation.get_node_or_null(^"EastFar/Tankard") == null,
			"the table pass still repeats four identical place-setting silhouettes")
		assert_true(occupation.find_child("*Collision*", true, false) == null,
			"presentation-only tabletop dressing added a new collision obstacle")
	assert_true(interior.get_node_or_null(^"CommonRoomFloorboards") == null,
		"the rejected black-grid floor treatment returned")
	var aisle_textile := interior.get_node_or_null(^"PublicRoomAisleTextile") as Node3D
	assert_true(aisle_textile != null and aisle_textile.get_child_count() == 8,
		"the broad tan center aisle lost its fitted public-room textile")
	if aisle_textile != null:
		assert_true(aisle_textile.get_node_or_null(^"WoolField") != null
			and aisle_textile.get_node_or_null(^"LongBorderL") != null
			and aisle_textile.get_node_or_null(^"LongBorderR") != null,
			"the aisle runner no longer reads as a deliberately bordered textile")
		assert_true(aisle_textile.find_child("*Collision*", true, false) == null,
			"the visual aisle textile changed the player's clear route")
	var lodging_screen := interior.get_node_or_null(^"LodgingAlcoveScreen") as Node3D
	assert_true(lodging_screen != null and lodging_screen.get_child_count() >= 25,
		"the exposed guest bed no longer has a complete lodging screen")
	if lodging_screen != null:
		assert_true(lodging_screen.get_node_or_null(^"ScreenPost1") != null
			and lodging_screen.get_node_or_null(^"ScreenPost5") != null
			and lodging_screen.find_children("ScreenRail_*", "MeshInstance3D", false, false).size() == 3,
			"the lodging divider lost its open timber frame")
		for panel_name: StringName in [&"WoolDrop1", &"WoolDrop2", &"WoolDrop3", &"WoolDrop4"]:
			var panel := lodging_screen.get_node_or_null(NodePath(str(panel_name))) as MeshInstance3D
			assert_true(panel != null and (panel.mesh as BoxMesh).size.y >= 1.65,
				"%s is missing from the guest privacy screen" % panel_name)
		for return_name: StringName in [&"ReturnPostMid", &"ReturnPostEnd",
				&"ReturnWoolDrop1", &"ReturnWoolDrop2"]:
			assert_true(lodging_screen.get_node_or_null(NodePath(str(return_name))) != null,
				"%s is missing from the screen return that blocks the table sightline" % return_name)
		var return_end := lodging_screen.get_node(^"ReturnPostEnd") as MeshInstance3D
		assert_true(return_end.position.x >= 2.05 and return_end.position.x <= 2.12,
			"the privacy return no longer screens the bed while retaining its east-wall entrance")
		# Pin the actual R12 table/service camera rays against the installed bed's
		# scaled OBJ bounds. Each extreme mattress corner must cross the opaque
		# return envelope before reaching the camera; merely having a screen node
		# did not catch R11's around-the-open-edge visibility defect.
		var table_eyes: Array[Vector3] = [Vector3(0.58, 2.0, 3.95), Vector3(0.30, 1.85, 4.12)]
		var bed_extremes: Array[Vector3] = [Vector3(1.185, 0.86, -0.335),
			Vector3(2.216, 0.86, -0.335), Vector3(1.185, 0.30, -2.465),
			Vector3(2.216, 0.30, -2.465)]
		for eye: Vector3 in table_eyes:
			for bed_point: Vector3 in bed_extremes:
				var return_t := (0.14 - eye.z) / (bed_point.z - eye.z)
				var return_hit := eye.lerp(bed_point, return_t)
				var return_blocks := return_hit.x >= 1.00 and return_hit.x <= 2.13 \
					and return_hit.y >= 0.20 and return_hit.y <= 2.14
				var long_t := (1.02 - eye.x) / (bed_point.x - eye.x)
				var long_hit := eye.lerp(bed_point, long_t)
				var long_blocks := long_hit.z >= -2.83 and long_hit.z <= 0.19 \
					and long_hit.y >= 0.20 and long_hit.y <= 2.14
				assert_true(return_blocks or long_blocks,
					"a table/service camera ray still sees around the guest privacy return")
		assert_true(lodging_screen.find_child("*Collision*", true, false) == null,
			"the visual lodging screen introduced a gameplay obstacle")
	var floor_wear := interior.get_node_or_null(^"CommonRoomFloorUseWear") as Node3D
	assert_true(floor_wear != null and floor_wear.get_child_count() == 10,
		"the exposed common-room floor returned to a spotless featureless plane")
	if floor_wear != null:
		assert_true(floor_wear.find_child("*Collision*", true, false) == null,
			"floor wear changed gameplay collision")
	interior.call("apply_interior_time", "night")
	assert_true(bar.light_energy > room.light_energy and room.light_energy > door.light_energy,
		"night practicals do not establish a warm bar-first hierarchy")
	assert_true(bar.light_color.r > bar.light_color.b and room.light_color.r > room.light_color.b,
		"the night common room still reads as cool flat daylight")
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
	# Pin the production-evidence correction directly. The repaired Inn itself is
	# now placed at 180 degrees, and the installed male rig's visible face is local
	# +Z. Matching that 180-degree building yaw faces Bram north through the bar
	# toward arriving patrons, as the current production capture proves.
	assert_almost_eq(float(bram.get("facing_deg", 0.0)), 180.0, 0.01,
		"Bram no longer uses the production-corrected patron-facing yaw")
