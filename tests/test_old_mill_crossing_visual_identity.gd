extends "res://tests/test_case.gd"

## Focused contract for the production Old Mill approach. This pins the
## relationship the visual pass creates instead of asserting subjective image
## quality: a player approaches a real mill clearing, meets a physical sign
## with the canonical name, and does not receive the neighbouring river-region
## name at the same stand.

const MILL_CROSSING := preload("res://scripts/world/mill_crossing.gd")
const MAP_PATH := "res://data/config/map_landmarks.json"
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const VEGETATION_PATH := "res://data/config/bands/band3_the_river_lock/vegetation.json"
const TELEPORT_PATH := "res://data/config/debug_teleport_spots.json"
const CAPTURE_PATH := "res://tools/capture_old_mill_crossing_identity.gd"
const MILL_SOURCE_PATH := "res://scripts/world/mill_crossing.gd"


func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _entry(rows: Array, id: String) -> Dictionary:
	for raw: Variant in rows:
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == id:
			return raw as Dictionary
	return {}


func test_canonical_name_is_shared_by_crossing_landmark_and_player_destination() -> void:
	var terrain := _read_json(TERRAIN_PATH)
	var crossing := _entry(terrain.get("crossings", []) as Array, "old_mill_crossing")
	var map := _read_json(MAP_PATH)
	var landmark := _entry(map.get("landmarks", []) as Array, "old_mill_crossing")
	var arrival := _entry(map.get("regions", []) as Array, "old_mill_crossing_region")
	assert_eq(str(crossing.get("label", "")), "Old Mill Crossing")
	assert_eq(str(landmark.get("display_name", "")), "Old Mill Crossing")
	assert_eq(str(arrival.get("display_name", "")), "Old Mill Crossing")
	assert_true(float(arrival.get("radius", 0.0)) >= 34.0,
		"the canonical south-bank stand is outside the Old Mill arrival region")

	var destination_name := ""
	for biome_raw: Variant in _read_json(TELEPORT_PATH).get("biomes", []):
		for band_raw: Variant in (biome_raw as Dictionary).get("bands", []):
			for spot_raw: Variant in (band_raw as Dictionary).get("spots", []):
				var spot := spot_raw as Dictionary
				if str(spot.get("display_name", "")) == "Old Mill Crossing":
					destination_name = str(spot.get("display_name", ""))
	assert_eq(destination_name, "Old Mill Crossing",
		"the Settings destination drifted from the map and physical crossing name")


func test_mill_and_sign_sightlines_are_scoped_clearings_not_bald_footprints() -> void:
	var vegetation := _read_json(VEGETATION_PATH)
	var mill_clear := false
	var sign_clear := false
	var approach_lens_clear := false
	var exact_trunk_lens := false
	for raw: Variant in vegetation.get("clearings", []):
		var row := raw as Dictionary
		var id := str(row.get("id", ""))
		var at := Vector2(float(row.get("x", INF)), float(row.get("z", INF)))
		if id == "old_mill_building" and at.distance_to(Vector2(-162.1, 4210.6)) < 0.2:
			mill_clear = float(row.get("radius", 0.0)) >= 15.0
		if id == "old_mill_sign" and at.distance_to(Vector2(-158.8, 4189.5)) < 0.2:
			sign_clear = float(row.get("radius", 0.0)) <= 5.0
		if id == "old_mill_approach_lens" and at.distance_to(Vector2(-157.0, 4199.0)) < 0.2:
			approach_lens_clear = float(row.get("radius", 0.0)) >= 9.5
		if id == "old_mill_south_arrival_trunk_lens" \
				and at.distance_to(Vector2(-155.38, 4183.53)) < 0.02:
			var radius := float(row.get("radius", 0.0))
			exact_trunk_lens = radius >= 0.9 and radius <= 1.1
	assert_true(mill_clear, "the installed-kit mill has no tree/sapling sightline clearing")
	assert_true(sign_clear, "the approach sign has no tightly scoped sightline clearing")
	assert_true(approach_lens_clear,
		"the ordinary south-bank camera-to-wheel lens still permits a full tree obstruction")
	assert_true(exact_trunk_lens,
		"the measured fresh-bake trunk is not removed by a tightly bounded centre lens")

	for raw: Variant in vegetation.get("footprints", []):
		var row := raw as Dictionary
		var at := Vector2(float(row.get("x", INF)), float(row.get("z", INF)))
		assert_true(at.distance_to(Vector2(-162.1, 4210.6)) > 5.0,
			"the mill identity pass used a footprint and would strip its meadow ground cover")


func test_old_mill_builds_one_physical_canonical_sign_off_the_route() -> void:
	var world := FakeGroundWorld.new()
	var crossing: Node3D = MILL_CROSSING.new()
	crossing.name = "MillCrossing"
	world.add_child(crossing)
	# Exercise only the visual identity addition. Full crossing construction also
	# wires the global story ledger and therefore belongs to traversal tests.
	crossing.set("_centre", Vector2(-152.0, 4203.0))
	crossing.set("_across", Vector2(0.0, 1.0))
	crossing.set("_crossing", {"label": "Old Mill Crossing"})
	crossing.call("_build_approach_sign", world)
	var sign := world.get_node_or_null("OldMillCrossingSign") as Node3D
	assert_true(sign != null, "the ordinary approach has no physical Old Mill Crossing sign")
	if sign == null:
		world.free()
		return
	assert_eq(int(sign.call("placed")), 1,
		"the crossing sign should carry one canonical destination arm")
	var road_x := float((crossing.call("near_point", 13.5) as Vector2).x)
	assert_true(absf(sign.position.x - road_x) >= 6.0,
		"the identity sign was placed in the bridge walking line")
	world.free()


func test_old_mill_builds_one_exposed_hero_wheel_on_the_prefab_drive_line() -> void:
	var crossing: Node3D = MILL_CROSSING.new()
	var mill := Node3D.new()
	mill.name = "Mill"
	crossing.add_child(mill)
	crossing.call("_build_visible_mill_wheel", mill)
	var wheel := mill.get_node_or_null("OldMillWaterWheel") as Node3D
	assert_true(wheel != null, "the crossing has no readable water-wheel hero shape")
	if wheel != null:
		assert_true(wheel.get_parent() == mill,
			"the hero wheel is detached from the mill it is meant to power")
		assert_true(wheel.position.distance_to(Vector3(-7.25, 2.15, 0.0)) < 0.01,
			"the R7 hero wheel drifted back behind the smooth lower-wall plane")
		assert_true(absf(wheel.rotation.y + PI * 0.5) < 0.01,
			"the hero wheel no longer shares the prefab wheel's wall plane")
		assert_true(wheel.get_node_or_null("Rim") != null, "the hero wheel has no circular rim")
		var paddles := 0
		for child: Node in wheel.get_children():
			if child.name.begins_with("Paddle"):
				paddles += 1
		assert_eq(paddles, 10, "the hero wheel does not carry a readable paddle rhythm")
		assert_true(wheel.find_children("*", "CollisionObject3D", true, false).is_empty(),
			"the overlay wheel duplicated or changed the prefab's authoritative collision")
	crossing.free()


func test_old_mill_wheel_turns_and_loading_activity_belongs_to_the_mill() -> void:
	var crossing: Node3D = MILL_CROSSING.new()
	var mill := Node3D.new()
	mill.name = "Mill"
	crossing.add_child(mill)
	crossing.call("_build_visible_mill_wheel", mill)
	crossing.call("_build_grounded_mill_foundation", mill)
	crossing.call("_build_millrace", mill)
	crossing.call("_build_loading_activity", mill)
	var yard := mill.get_node_or_null("OldMillLoadingActivity") as Node3D
	assert_true(yard != null, "the working mill has no loading activity at its door")
	if yard != null:
		assert_eq(yard.get_child_count(), 10,
			"the compact flour load changed into an empty or cluttered yard")
		for wanted in ["FlourBagA", "FlourBagB", "FlourBagC", "FlourBagD",
				"LoadingCrateA", "LoadingCrateB", "MealBarrel", "HandCart",
				"BarrelRack", "MillBucket"]:
			assert_true(yard.get_node_or_null(wanted) != null,
				"the mill loading story lost %s" % wanted)
		assert_true(yard.find_children("*", "CollisionObject3D", true, false).is_empty(),
			"visual loading activity changed the bridge or mill collision route")
	var wheel := mill.get_node_or_null("OldMillWaterWheel") as Node3D
	var before := wheel.rotation.z if wheel != null else 0.0
	crossing.call("_process", 1.0)
	assert_true(wheel != null and wheel.rotation.z > before + 0.2,
		"the hero wheel remains inert scenery instead of working machinery")
	var race := mill.get_node_or_null("OldMillHeadrace") as Node3D
	assert_true(race != null, "the attached wheel has no visible water supply")
	if race != null:
		for wanted in ["HeadpondWater", "HeadpondSill", "HeadpondOuterRail", "HeadpondInnerRail",
				"TroughBed", "RunningWater", "HeadraceWaterMid", "HeadraceWaterLower",
				"SourceIntakeWater", "SourceIntakeCrossbeam",
				"SluiceGate", "FeedDrop", "PaddleContact", "WheelSplash", "TailraceBed", "TailraceWater",
				"WheelDischarge", "TailraceMid", "TailraceMouth", "TailraceOutfall",
				"FeedFoam", "TailraceFoam"]:
			assert_true(race.get_node_or_null(wanted) != null,
				"the millrace lost its %s" % wanted)
		var feed := race.get_node_or_null("FeedDrop") as MeshInstance3D
		var contact := race.get_node_or_null("PaddleContact") as MeshInstance3D
		assert_true(feed != null and wheel != null and absf(feed.position.x - wheel.position.x) < 0.02
				and feed.position.z < -0.9,
			"the water feed no longer meets the wheel's upstream paddle envelope")
		if feed != null and contact != null and wheel != null:
			var contact_from_axle := Vector2(contact.position.z - wheel.position.z,
				contact.position.y - wheel.position.y)
			var feed_mesh := feed.mesh as BoxMesh
			var contact_mesh := contact.mesh as BoxMesh
			assert_true(absf(contact.position.x - wheel.position.x) < 0.02
					and contact_from_axle.length() < 2.65
					and contact_from_axle.y > 0.0 and contact_from_axle.x < 0.0,
				"the visible contact sheet does not occupy the upper-upstream wheel quadrant")
			assert_true(feed.position.y - feed_mesh.size.y * 0.5
					< contact.position.y + contact_mesh.size.y * 0.5
					and absf(feed.position.z - contact.position.z)
					< (feed_mesh.size.z + contact_mesh.size.z) * 0.5,
				"the headrace fall stops before reaching the visible paddle contact")
		var headwater := race.get_node_or_null("RunningWater") as MeshInstance3D
		var tailwater := race.get_node_or_null("TailraceWater") as MeshInstance3D
		assert_true(headwater != null and (headwater.mesh as BoxMesh).size.z >= 1.5,
			"the headrace no longer establishes a readable upstream supply")
		assert_true(tailwater != null and tailwater.position.z > 2.0
				and (tailwater.mesh as BoxMesh).size.z >= 2.0,
			"the wheel no longer releases into a readable downstream tailrace")
		var headpond := race.get_node_or_null("HeadpondWater") as MeshInstance3D
		assert_true(headpond != null and wheel != null and (headpond.mesh as BoxMesh).size.x >= 2.0
				and (headpond.mesh as BoxMesh).size.y >= 0.20
				and headpond.position.y > wheel.position.y + 2.5,
			"the R10 water source is not a broad, thick headpond above the wheel")
		for aligned_name in ["HeadpondWater", "RunningWater", "FeedDrop", "PaddleContact",
				"WheelDischarge", "TailraceWater", "TailraceOutfall"]:
			var aligned := race.get_node_or_null(aligned_name) as Node3D
			assert_true(aligned != null and wheel != null
					and absf(aligned.position.x - wheel.position.x) < 0.02,
				"the R7 hydraulic chain left the exposed wheel drive line at %s" % aligned_name)
		assert_true(headwater != null and tailwater != null
				and headwater.position.z < feed.position.z
				and feed.position.z < tailwater.position.z,
			"the millrace lost its upstream -> wheel -> downstream causal order")
		assert_true(feed != null and wheel != null and feed.position.y > wheel.position.y + 1.5,
			"the visible feed no longer contacts the exposed upper wheel quadrant")
		for i in 4:
			assert_true(race.get_node_or_null("HeadpondPlank%02d" % i) != null,
				"the elevated headpond lost supporting basin plank %d" % i)
		var discharge := race.get_node_or_null("WheelDischarge") as MeshInstance3D
		assert_true(discharge != null and discharge.position.z > 1.5
				and discharge.position.y > tailwater.position.y,
			"the wheel contact no longer visibly discharges into the downstream race")
		var head_material := headwater.material_override as StandardMaterial3D
		assert_true(head_material != null
				and head_material.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA
				and not head_material.emission_enabled
				and head_material.albedo_color.a < 0.75,
			"the headrace water reverted to an opaque emissive bright-blue slab")
		for support_name in ["HeadracePierFoot", "HeadracePierShaft", "HeadracePierCap",
				"HeadraceWallBearer"]:
			assert_true(race.get_node_or_null(support_name) != null,
				"the compact headrace load path lost %s" % support_name)
		var trough_bed := race.get_node_or_null("TroughBed") as MeshInstance3D
		var headrace_mid := race.get_node_or_null("HeadraceWaterMid") as MeshInstance3D
		var headrace_lower := race.get_node_or_null("HeadraceWaterLower") as MeshInstance3D
		assert_true(trough_bed != null and (trough_bed.mesh as BoxMesh).size.x <= 2.0
				and (trough_bed.mesh as BoxMesh).size.y <= 0.16,
			"the headrace reverted to a broad obstructive underside slab")
		for water_name in ["RunningWater", "HeadraceWaterMid", "HeadraceWaterLower",
				"TailraceWater", "TailraceMid", "TailraceMouth"]:
			var ribbon := race.get_node_or_null(water_name) as MeshInstance3D
			assert_true(ribbon != null and (ribbon.mesh as BoxMesh).size.x >= 1.7
					and (ribbon.mesh as BoxMesh).size.y >= 0.20,
				"R10 water ribbon became thin or visually disconnected at %s" % water_name)
		assert_true(headwater != null and headrace_mid != null and headrace_lower != null
				and headwater.position.y > headrace_mid.position.y
				and headrace_mid.position.y > headrace_lower.position.y,
			"the segmented headrace does not visibly descend toward the wheel")
		assert_true(race.find_children("*", "CollisionObject3D", true, false).is_empty(),
			"visual millrace changed the bridge or mill collision route")
		var mill_source := FileAccess.get_file_as_string(MILL_SOURCE_PATH)
		assert_false(mill_source.contains("Rock_Medium_")
				or mill_source.contains("Prop_Support.gltf")
				or mill_source.contains("HeadraceBent")
				or mill_source.contains("TroughRail"),
			"R10 restored the oversized feet, paired bents or rails that tangled the wheel")
	assert_true(wheel != null and wheel.get_node_or_null("DriveShaft") != null,
		"the wheel axle no longer visibly transfers power into the mill wall")
	var foundation := mill.get_node_or_null("OldMillGroundedFoundation") as Node3D
	assert_true(foundation != null, "the mill remains unsupported over the river cut")
	if foundation != null:
		assert_eq(foundation.get_child_count(), 12,
			"the simplified foundation regained a broad wall or rubble obstruction")
		for pier_side in ["Upstream", "Downstream"]:
			for course in 5:
				var pier := foundation.get_node_or_null(
					"BatteredPier%s%02d" % [pier_side, course]) as MeshInstance3D
				assert_true(pier != null, "the open foundation lost a battered corner pier")
				if pier != null and course > 0:
					var lower := foundation.get_node_or_null(
						"BatteredPier%s%02d" % [pier_side, course - 1]) as MeshInstance3D
					assert_true(lower != null and (pier.mesh as BoxMesh).size.x
							< (lower.mesh as BoxMesh).size.x
							and (pier.mesh as BoxMesh).size.z < (lower.mesh as BoxMesh).size.z,
						"foundation courses do not batter inward above their grounded toe")
			assert_true(foundation.get_node_or_null("GroundedToe%s" % pier_side) != null,
				"a separated foundation pier has no grounded toe")
		assert_true(wheel != null and wheel.position.x < -6.5,
			"the wheel has slipped behind the compact corner piers")
		assert_true(foundation.find_children("*", "CollisionObject3D", true, false).is_empty(),
			"visual mill foundation changed the accepted crossing collision")
	crossing.free()


func test_old_mill_installs_exactly_two_supported_warm_practicals_off_route() -> void:
	var world := FakeGroundWorld.new()
	var crossing: Node3D = MILL_CROSSING.new()
	world.add_child(crossing)
	var mill := Node3D.new()
	mill.name = "Mill"
	mill.position = Vector3(-162.1, 0.0, 4210.6)
	world.add_child(mill)
	crossing.call("_build_practical_lights", world, mill)
	var lights := world.get_node_or_null("OldMillPracticalLights") as Node3D
	assert_true(lights != null, "Old Mill has no localized night practical root")
	if lights == null:
		world.free()
		return
	assert_eq(lights.get_child_count(), 2, "Old Mill should install exactly two practicals")
	for holder_raw: Node in lights.get_children():
		var holder := holder_raw as Node3D
		assert_true(holder.get_node_or_null("LanternFixture") != null,
			"a practical is a light without an installed visible lantern source")
		var ember := holder.get_node_or_null("VisibleEmber") as MeshInstance3D
		assert_true(ember != null, "a practical has no small visible warm emitter")
		if ember != null:
			var ember_material := ember.material_override as StandardMaterial3D
			assert_true(ember_material != null and ember_material.emission_energy_multiplier <= 1.5,
				"visible practical emitter will tonemap back to a stark white orb")
			assert_true(ember_material != null and ember_material.albedo_color.r \
					> ember_material.albedo_color.b * 2.5,
				"visible practical emitter no longer carries an amber surface")
		var pool := holder.get_node_or_null("WarmPool") as OmniLight3D
		assert_true(pool != null, "a practical has no bounded warm pool")
		if pool != null:
			assert_true(pool.omni_range >= 5.0 and pool.omni_range <= 7.0,
				"Old Mill practical range escaped the local 5-7m night treatment")
			assert_true(pool.light_energy >= 2.0 and pool.light_energy <= 2.5,
				"Old Mill practical is too weak for its bounded pool or has become a floodlight")
			assert_true(pool.light_color.r > pool.light_color.b * 2.5,
				"Old Mill practical drifted away from warm amber")
		assert_true(holder.find_children("*", "CollisionObject3D", true, false).is_empty(),
			"visual practical added collision to the crossing")
	var race_light := lights.get_node_or_null("WheelRacePractical") as Node3D
	assert_true(race_light != null,
		"the existing second practical no longer lights the wheel/race mechanism")
	assert_true(lights.get_node_or_null("SouthWorkbenchPractical") == null,
		"the second bounded pool drifted back to unrelated grass instead of the mechanism")
	world.free()


func test_old_mill_capture_keeps_ecology_but_prevents_elapsed_roamer_obstruction() -> void:
	var source := FileAccess.get_file_as_string(CAPTURE_PATH)
	assert_true(source.contains('const CAPTURE_SERIAL := "final-old-mill-10"'),
		"Old Mill evidence was not serialized for the R10 physical rebuild")
	assert_true(source.contains('"03-hydraulic-sequence-south-bank"')
			and source.contains('Vector2(-184.0, 4194.0)'),
		"the R10 capture lost its reachable southwest broadside composition")
	assert_true(source.contains("_verify_r10_projection"),
		"the R10 capture can complete without checking its repair in the live frame")
	for required in ["OldMillGroundedFoundation", "GroundedToeUpstream", "HeadpondWater", "TroughBed",
			"HeadracePierShaft", "HeadracePierFoot", "RunningWater", "HeadraceWaterMid", "HeadraceWaterLower",
			"SourceIntakeWater", "FeedDrop", "PaddleContact", "OldMillWaterWheel",
			"WheelDischarge", "TailraceWater", "TailraceMid", "TailraceMouth", "TailraceOutfall"]:
		assert_true(source.contains(required),
			"the R10 projection contract does not require %s" % required)
	assert_true(source.contains('"r10_visual_proof"'),
		"the capture manifest frames omit their R10 projection measurements")
	for expected in ["01-south-arrival-day", "01-south-arrival-night",
			"02-gate-and-wheel-day", "02-gate-and-wheel-night",
			"03-hydraulic-sequence-south-bank-day", "03-hydraulic-sequence-south-bank-night",
			"04-crossing-axis-day", "04-crossing-axis-night"]:
		assert_true(source.contains('"%s"' % expected),
			"the R10 fail-closed capture does not require %s" % expected)
	assert_true(source.contains("hydraulic_segment_lengths_px")
			and source.contains("hydraulic_vertical_drop_px")
			and source.contains("wheel_foundation_overlap_share")
			and source.contains("wheel_broadside_roundness")
			and source.contains("wheel_broadside_alignment")
			and source.contains("visible water ribbon breaks"),
		"the hydraulic view does not reject a flat, broken, edge-on or enveloped mechanism")
	assert_true(source.contains("camera.is_position_behind(centre)"),
		"the R10 hydraulic verifier accepts a source or outfall behind the proof camera")
	assert_true(source.contains("vertical_drop < 110.0")
			and source.contains("foundation_overlap >= 0.35")
			and source.contains("broadside_alignment < 0.72")
			and source.contains("gap > 8.0")
			and source.contains("source_point.y < contact_point.y")
			and source.contains("contact_point.y < discharge_point.y")
			and source.contains("hydraulic_world_heights_m"),
		"the R10 correction weakened continuity, descent or wheel-exposure gates")
	assert_true(source.contains("revive_at_home"),
		"the production capture does not reset elapsed roamers to authored ecology homes")
	assert_true(source.contains("_near_wildlife_blocker"),
		"the capture does not fail closed when a giant live resident still blocks a frame")
	assert_false(source.contains("body.queue_free()"),
		"the capture deletes ecology instead of retaining production wildlife")
	assert_false(source.contains("body.visible = false"),
		"the capture hides a production subject instead of controlling only movement")


class FakeGroundWorld extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0
