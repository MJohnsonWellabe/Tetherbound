extends "res://tests/test_case.gd"

## F17#6 claude-r1 judge (Hall interior set): the companion clipped through the
## Shrine Room lectern pedestals, and turned saturated blue-violet indoors at
## 23:00. Both fixes are behind their own crossing_hall.json flag, OFF.

const FOLLOWER := preload("res://scripts/creatures/follower_creature.gd")
const HALL := preload("res://scripts/world/crossing_hall.gd")
const AMBIENT := preload("res://scripts/world/interior_creature_ambient.gd")
const CONFIG_PATH := "res://data/config/crossing_hall.json"


func _config() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))


func test_flag_ship_states() -> void:
	var config := _config()
	# F17#6 r7: the pedestal clearance ships ON with the spread Shrine Room lecterns.
	assert_eq(config.companion_pedestal_clearance.enabled, true, "pedestal clearance ships ON (F17#6 r7)")
	assert_eq(config.interior_ambient.creature_night_ambient_enabled, false, "creature night ambient ships OFF")


## --- 1. pedestal clearance -------------------------------------------------

func test_pedestal_keep_clear_covers_the_plinth_corners() -> void:
	var config := _config()
	var plinth: Array = config.stand_presentation.plinth_size_m
	var radius := HALL.pedestal_keep_clear_radius(Vector2(float(plinth[0]), float(plinth[2])), .25)
	assert_almost_eq(radius, Vector2(float(plinth[0]), float(plinth[2])).length() * .5 + .25, .0001)
	# A plinth corner is inside the circle even for a zero-size footprint.
	assert_true(FOLLOWER.keep_clear_hit([[Vector2.ZERO, radius]],
		Vector3(float(plinth[0]) * .5, 0, float(plinth[2]) * .5), 0.0))


func test_keep_clear_hit_counts_the_whole_footprint() -> void:
	var zones := [[Vector2(10, 0), 0.9]]
	assert_true(FOLLOWER.keep_clear_hit(zones, Vector3(11.5, 3.0, 0.0), 0.7), "1.5 m < 0.9 + 0.7")
	assert_false(FOLLOWER.keep_clear_hit(zones, Vector3(11.7, 0.0, 0.0), 0.7), "1.7 m clears 0.9 + 0.7")
	assert_false(FOLLOWER.keep_clear_hit([], Vector3(10, 0, 0), 5.0), "no zones, never a hit")


func test_the_indoor_station_turns_away_from_a_pedestal() -> void:
	var origin := Vector3(12.0, 0.15, 0.0)
	var first := Vector3.RIGHT
	var reach := 2.0
	var always := func(_spot: Vector3) -> bool: return true
	# Flag off (no zones): the requested flank, unchanged.
	assert_eq(FOLLOWER.first_clear_spot(origin, first, reach, [], 1.0, always), origin + Vector3(2, 0, 0))
	# A pedestal on the requested flank: the first turn clear of it.
	var zones := [[Vector2(14.0, 0.0), 0.9]]
	var spot := FOLLOWER.first_clear_spot(origin, first, reach, zones, 1.0, always)
	assert_true(spot.is_finite())
	assert_false(FOLLOWER.keep_clear_hit(zones, spot, 1.0), "the chosen spot keeps the footprint out")
	assert_almost_eq(Vector2(spot.x - origin.x, spot.z - origin.z).length(), reach, .001, "same reach")
	# Physics still has the last word.
	var blocked := func(at: Vector3) -> bool: return at.z < 0.0
	var walled := FOLLOWER.first_clear_spot(origin, first, reach, zones, 1.0, blocked)
	assert_true(walled.z < 0.0 and not FOLLOWER.keep_clear_hit(zones, walled, 1.0))


func test_between_two_pedestals_the_wider_ring_finds_room() -> void:
	# The trainer between the lecterns of a 3 m row: no first-ring spot fits a
	# large companion, the 1.75x ring does.
	var origin := Vector3(9.2, 0.15, 0.0)
	var zones := [[Vector2(9.2, -1.5), 0.89], [Vector2(9.2, 1.5), 0.89], [Vector2(9.2, -4.5), 0.89],
		[Vector2(9.2, 4.5), 0.89]]
	var always := func(_spot: Vector3) -> bool: return true
	var spot := FOLLOWER.first_clear_spot(origin, Vector3.BACK, 1.6, zones, 1.0, always)
	assert_true(spot.is_finite(), "a clear station exists")
	assert_false(FOLLOWER.keep_clear_hit(zones, spot, 1.0))


## --- 2. creature night ambient indoors -------------------------------------

func _creature(shared: StandardMaterial3D) -> Node3D:
	var root := Node3D.new()
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.material = shared
	mesh.mesh = box
	root.add_child(mesh)
	var shadow := MeshInstance3D.new()
	shadow.name = "ContactShadow"
	shadow.mesh = QuadMesh.new()
	var unshaded := StandardMaterial3D.new()
	unshaded.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow.mesh.surface_set_material(0, unshaded)
	root.add_child(shadow)
	return root


func test_indoors_at_night_only_this_creature_drops_its_sky_ambient() -> void:
	var shared := StandardMaterial3D.new()
	shared.resource_name = "species_skin"
	var indoors := _creature(shared)
	var outdoors := _creature(shared)
	var occlusion := AMBIENT.occlusion_texture(.25)
	AMBIENT.set_indoors_night(indoors, true, occlusion)
	var mesh := indoors.get_child(0) as MeshInstance3D
	var copy := mesh.get_active_material(0) as StandardMaterial3D
	assert_true(copy != shared, "a per-instance copy")
	assert_true(copy.ao_enabled and copy.ao_texture == occlusion and copy.ao_light_affect == 0.0,
		"ambient-only occlusion: direct light (lanterns) untouched")
	assert_false(shared.ao_enabled, "the species' shared material is never modified")
	assert_eq((outdoors.get_child(0) as MeshInstance3D).get_active_material(0), shared, "another creature keeps it")
	assert_true((indoors.get_child(1) as MeshInstance3D).get_surface_override_material(0) == null, "unshaded surfaces skipped")
	# Every refresh calls it again: nothing re-copied.
	AMBIENT.set_indoors_night(indoors, true, occlusion)
	assert_eq(mesh.get_active_material(0), copy, "idempotent")
	# Outside (or daybreak): exactly restored.
	AMBIENT.set_indoors_night(indoors, false, occlusion)
	assert_eq(mesh.get_active_material(0), shared)
	assert_true(mesh.get_surface_override_material(0) == null)
	assert_false(AMBIENT.is_applied(indoors))
	indoors.free()
	outdoors.free()


func test_a_material_set_meanwhile_is_kept_and_re_covered() -> void:
	var shared := StandardMaterial3D.new()
	var creature := _creature(shared)
	var mesh := creature.get_child(0) as MeshInstance3D
	var occlusion := AMBIENT.occlusion_texture(.25)
	AMBIENT.set_indoors_night(creature, true, occlusion)
	# Another system (e.g. a creature effect) replaces the surface material.
	var replaced := StandardMaterial3D.new()
	mesh.set_surface_override_material(0, replaced)
	AMBIENT.set_indoors_night(creature, true, occlusion)
	var copy := mesh.get_active_material(0) as StandardMaterial3D
	assert_true(copy != replaced and copy.ao_enabled, "re-covered from the new material")
	AMBIENT.set_indoors_night(creature, false, occlusion)
	assert_eq(mesh.get_active_material(0), replaced, "restore returns the newer material, not the old one")
	creature.free()
