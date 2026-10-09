extends "res://tests/test_case.gd"

## N07-VFX-POLISH (D87). The wind-up ring: its colour stays out of the band
## `data/config/palette.json` reserves for Team Tether, and the ring itself is
## a depth-tested mark lifted off the ground at the foe's feet.
##
## The colour test reads the REAL config through the same `config()` the
## manager uses, not a literal, so a future retune that drifts back into the
## reserved red fails here rather than in a blind judge's write-up. The ring
## test spawns the real node through the same static `begin()` the manager
## calls and walks it through its life by hand, the way `test_combat_vfx.gd`
## walks a burst: the unit runner never processes a frame, so `_ready()` and
## `_physics_process()` are called directly and "freed" is
## `is_queued_for_deletion()`.
##
## Seen red 2026-09-05 with `telegraph.colour` set back to `#ff5a3c`
## ("telegraph.colour #ff5a3c is 1.2 degrees of hue from reserved oxblood
## #6b2a20") and with `no_depth_test` set back to true ("the ring must be
## depth-tested"); restored.

const TELEGRAPH_GLOW := preload("res://scripts/combat/telegraph_glow.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
class SlopedBody extends Node3D:
	var ground_calls := 0
	var ground_offset := 0.0
	func body_radius() -> float: return 2.0
	func _ground_height(x: float, _z: float) -> float:
		ground_calls += 1
		return x * 0.5 + ground_offset
	func active() -> bool: return true


class CountingGlow extends TELEGRAPH_GLOW:
	var vertices_sampled := 0
	func _ground_vertex(offset: Vector3) -> Vector3:
		vertices_sampled += 1
		return super._ground_vertex(offset)


func test_unchanged_dry_ring_skips_vertices_but_pulse_and_move_redraw() -> void:
	var glow := CountingGlow.new()
	glow.call("_ready")
	glow.call("_draw_ring", 3.0, 0.7)
	var count := glow.vertices_sampled
	glow.call("_draw_ring", 3.0, 0.7)
	assert_eq(glow.vertices_sampled, count, "unchanged unqueried aim rebuilds nothing")
	glow.call("_draw_ring", 3.2, 0.6)
	assert_true(glow.vertices_sampled > count, "radius/alpha pulse is retained")
	count = glow.vertices_sampled
	glow.position += Vector3.RIGHT
	glow.call("_draw_ring", 3.2, 0.6)
	assert_true(glow.vertices_sampled > count, "moved aim redraws")
	glow.free()


func test_ground_ring_keeps_resampling_changed_heights_on_same_body() -> void:
	var parent := Node3D.new()
	var body := SlopedBody.new()
	parent.add_child(body)
	var glow := TELEGRAPH_GLOW.begin(parent, Vector3.ZERO, Color.CYAN, 1.1, 0.6)
	glow.call("_ready")
	glow.call("follow_state", body, body.active)
	glow.call("_draw_ring", 3.0, 0.7)
	var mesh: ImmediateMesh = glow.get("_ring_mesh")
	var before: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var calls := body.ground_calls
	body.ground_offset = 1.0
	glow.call("_draw_ring", 3.0, 0.7)
	assert_true(body.ground_calls > calls, "same source may report changed ground")
	assert_true(mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] != before)
	body.ground_offset = 0.0
	glow.call("_draw_ring", 3.2, 0.6)
	assert_true(body.ground_calls > calls, "the pulse resamples its changed ground points")
	assert_true(mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] != before)
	calls = body.ground_calls
	glow.position += Vector3(2.0, 0.0, 1.0)
	glow.call("_draw_ring", 3.2, 0.6)
	assert_true(body.ground_calls > calls, "moving the same-sized ring resamples")
	var points: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var supports: Array[bool] = []
	var inner_present := false
	var outer_present := false
	var raised_present := false
	for point: Vector3 in points:
		var radius := Vector2(point.x, point.z).length()
		var elevation: float = (glow.position + point).y - ((glow.position.x + point.x) * 0.5 + 0.08)
		var inner := absf(radius - 3.2 * 0.72) < 0.001
		var outer := absf(radius - 3.2) < 0.001
		assert_between(radius, 3.2 * 0.72 - 0.001, 3.2 + 0.001, "moved crest retains its full ground footprint")
		if inner or outer:
			assert_almost_eq(elevation, 0.0, 0.001, "both skirts follow the new ground exactly")
			inner_present = inner_present or inner
			outer_present = outer_present or outer
		else:
			assert_between(elevation, 0.001, 3.2 * 0.28 * 0.5 + 0.001, "crest is raised but stays within half the band width")
			raised_present = true
		supports.append(inner or outer)
	assert_true(inner_present and outer_present and raised_present, "grounded skirts and raised body are all present")
	assert_eq(points.size() % 3, 0)
	for first: int in range(0, points.size() - 2, 3):
		assert_true(supports[first] or supports[first + 1] or supports[first + 2], "every face meets its ground skirt")
		assert_false(supports[first] and supports[first + 1] and supports[first + 2], "no flat replacement face")
	parent.free()


func test_shared_ground_point_is_sampled_once_and_cache_expires_each_rebuild() -> void:
	var parent := Node3D.new()
	var body := SlopedBody.new()
	parent.add_child(body)
	var glow := TELEGRAPH_GLOW.begin(parent, Vector3.ZERO, Color.CYAN, 1.1, 0.6)
	glow.call("_ready")
	glow.call("follow_state", body, body.active)
	# A collapsed ring repeats the same point in all strip vertices.
	glow.call("_draw_ring", 0.0, 0.7)
	assert_eq(body.ground_calls, 1, "one sample for one distinct ground point")
	glow.call("_draw_ring", 0.0, 0.6)
	assert_eq(body.ground_calls, 2, "a changed rebuild never inherits old ground heights")
	parent.free()


func test_state_ring_clears_body_footprint_and_follows_sloped_ground() -> void:
	var parent := Node3D.new()
	var body := SlopedBody.new()
	parent.add_child(body)
	var glow := TELEGRAPH_GLOW.begin(parent, Vector3.ZERO, Color.CYAN, 1.1, 0.6)
	glow.call("_ready")
	glow.call("follow_state", body, body.active)
	glow.call("_physics_process", 0.01)
	var mesh: ImmediateMesh = glow.get("_ring_mesh")
	var points: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert_true(points.size() > 0)
	var outer_radius := 0.0
	for point: Vector3 in points:
		outer_radius = maxf(outer_radius, Vector2(point.x, point.z).length())
	assert_between(outer_radius, 3.0, 3.6 + 0.001, "the pulse keeps its original radius envelope")
	var inner_radius := outer_radius * 0.72
	var clears_body := true
	var inner_present := false
	var outer_present := false
	var raised_present := false
	var supports: Array[bool] = []
	for point: Vector3 in points:
		var radius := Vector2(point.x, point.z).length()
		if radius <= body.body_radius(): clears_body = false
		var world_point: Vector3 = glow.position + point
		var elevation: float = world_point.y - (world_point.x * 0.5 + 0.08)
		var inner := absf(radius - inner_radius) < 0.001
		var outer := absf(radius - outer_radius) < 0.001
		assert_between(radius, inner_radius - 0.001, outer_radius + 0.001)
		if inner or outer:
			assert_almost_eq(elevation, 0.0, 0.001, "the skirts conform to the slope rather than float above it")
			inner_present = inner_present or inner
			outer_present = outer_present or outer
		else:
			assert_between(elevation, 0.001, (outer_radius - inner_radius) * 0.5 + 0.001, "no submerged or excessively raised crest")
			raised_present = true
		supports.append(inner or outer)
	assert_true(clears_body, "the ring must remain outside the live body footprint throughout its pulse")
	assert_true(inner_present and outer_present and raised_present, "both grounded edges support a raised crest")
	assert_eq(points.size() % 3, 0)
	for first: int in range(0, points.size() - 2, 3):
		assert_true(supports[first] or supports[first + 1] or supports[first + 2], "every face attaches to grounded geometry")
		assert_false(supports[first] and supports[first + 1] and supports[first + 2], "each face belongs to the raised section")
	parent.free()

class SeabedBody extends Node3D:
	func body_radius() -> float: return 2.0
	func _ground_height(_x: float, _z: float) -> float: return -3.0
	func active() -> bool: return true

class SeaWorld extends RefCounted:
	func water_depth_at(at: Vector3) -> float: return maxf(0.0, 0.0 - at.y)


## F14#0 (Tidecoil): over water the ring sits on the surface, not on the
## seabed the opaque surface hides. A world without water keeps it on ground.
func test_state_ring_rides_the_water_surface_over_a_seabed() -> void:
	for with_water in [true, false]:
		var parent := Node3D.new()
		var body := SeabedBody.new()
		parent.add_child(body)
		var glow := TELEGRAPH_GLOW.begin(parent, Vector3(0, -3, 0), Color.CYAN, 1.1, 0.6)
		if with_water:
			glow.set("water_depth_source", SeaWorld.new())
		glow.call("_ready")
		glow.call("follow_state", body, body.active)
		glow.call("_physics_process", 0.01)
		var mesh: ImmediateMesh = glow.get("_ring_mesh")
		var points: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var want := (0.0 if with_water else -3.0) + 0.08
		assert_true(points.size() > 0)
		var outer_radius := 0.0
		for point: Vector3 in points:
			outer_radius = maxf(outer_radius, Vector2(point.x, point.z).length())
		assert_between(outer_radius, 3.0, 3.6 + 0.001, "water does not enlarge the pulse footprint")
		var inner_radius := outer_radius * 0.72
		var inner_present := false
		var outer_present := false
		var raised_present := false
		var supports: Array[bool] = []
		for point: Vector3 in points:
			var radius := Vector2(point.x, point.z).length()
			var elevation: float = (glow.position + point).y - want
			var inner := absf(radius - inner_radius) < 0.001
			var outer := absf(radius - outer_radius) < 0.001
			assert_between(radius, inner_radius - 0.001, outer_radius + 0.001)
			if inner or outer:
				assert_almost_eq(elevation, 0.0, 0.001, "skirt at %.2f m (%s)" % [want, "water surface over a 3 m seabed" if with_water else "dry ground"])
				inner_present = inner_present or inner
				outer_present = outer_present or outer
			else:
				assert_between(elevation, 0.001, (outer_radius - inner_radius) * 0.5 + 0.001, "crest is supported above the visible surface")
				raised_present = true
			supports.append(inner or outer)
		assert_true(inner_present and outer_present and raised_present, "water and dry cases retain both skirts and the raised body")
		assert_eq(points.size() % 3, 0)
		for first: int in range(0, points.size() - 2, 3):
			assert_true(supports[first] or supports[first + 1] or supports[first + 2], "no detached face above water/ground")
			assert_false(supports[first] and supports[first + 1] and supports[first + 2], "no flattened water/ground replacement")
		var aabb: AABB = (glow.get("_ring") as MeshInstance3D).custom_aabb
		assert_true(aabb.end.y >= 3.1, "the ring's bounds reach a surface 3 m above the creature's feet")
		parent.free()

const PALETTE_PATH := "res://data/config/palette.json"
## The two oxblood values the world actually paints (road_gate.gd's gate and
## the stronghold banner in building_prefabs.json) plus palette.json's own
## `tether_oxblood`. Reserved-band membership is hue AND saturation: the
## palette's near-black #332228 is only 0.33 saturated, so a colour that far
## from any of these in hue, or barely saturated at all, is outside the band.
const RESERVED_HEXES := ["#6b2a20", "#7a2430"]
const MIN_HUE_DISTANCE_DEG := 25.0
const TICK := 1.0 / 60.0


static func _hue_distance_deg(a: Color, b: Color) -> float:
	var d: float = absf(a.h - b.h) * 360.0
	return minf(d, 360.0 - d)


func test_the_telegraph_colour_stays_out_of_the_reserved_oxblood_band() -> void:
	var cfg: Dictionary = MATH.config().get("telegraph", {})
	assert_true(cfg.has("colour"), "combat.json telegraph block names no colour")
	var colour := Color(str(cfg.get("colour", "")))
	var reserved: Array = RESERVED_HEXES.duplicate()
	var file := FileAccess.open(PALETTE_PATH, FileAccess.READ)
	assert_true(file != null, "palette.json missing")
	if file != null:
		var palette: Variant = JSON.parse_string(file.get_as_text())
		if palette is Dictionary:
			var accent: Dictionary = (palette as Dictionary).get("accent", {})
			if accent.has("tether_oxblood"):
				reserved.append(str(accent["tether_oxblood"]))
	assert_true(colour.s >= 0.3, "a warning ring this pale (sat %.2f) would not read at all" % colour.s)
	for hex: Variant in reserved:
		var oxblood := Color(str(hex))
		var distance := _hue_distance_deg(colour, oxblood)
		assert_true(distance >= MIN_HUE_DISTANCE_DEG,
			"telegraph.colour %s is %.1f degrees of hue from reserved oxblood %s (needs %.0f)" % [
				colour.to_html(false), distance, str(hex), MIN_HUE_DISTANCE_DEG])


func test_the_ring_spawns_lifted_depth_tested_and_frees_after_its_beat() -> void:
	var parent := Node3D.new()
	var feet := Vector3(3.0, 1.25, -2.0)
	var colour := Color("#ffbe47")
	var glow: Node3D = TELEGRAPH_GLOW.begin(parent, feet, colour, 1.1, 0.55)
	assert_true(glow != null and glow.get_parent() == parent, "begin() must parent the ring under the host it was given")
	assert_almost_eq(glow.position.x, feet.x, 0.0001, "the ring sits at the foe's feet in x")
	assert_almost_eq(glow.position.z, feet.z, 0.0001, "the ring sits at the foe's feet in z")
	assert_true(glow.position.y > feet.y + 0.01,
		"the ring must sit above the ground it marks (y %.3f against feet %.3f) or the terrain wins the depth test" % [glow.position.y, feet.y])
	assert_true(glow.position.y - feet.y <= 0.2, "lifted a hair, not floated: %.3f m" % (glow.position.y - feet.y))
	assert_eq(glow.get("_colour"), colour, "the ring keeps the colour it was handed")

	glow.call("_ready")
	var ring: MeshInstance3D = null
	for child in glow.get_children():
		if child is MeshInstance3D:
			ring = child
	assert_true(ring != null, "the ring built no mesh instance")
	if ring == null:
		parent.free()
		return
	var material := ring.material_override as StandardMaterial3D
	assert_true(material != null, "the ring has no material")
	if material != null:
		assert_false(material.no_depth_test,
			"the ring must be depth-tested: drawn through the ally's back it reads as a mark on the friendly creature (W09 round 1)")
		assert_true(material.vertex_color_use_as_albedo, "the ring's colour arrives through vertex colour")
		assert_eq(material.blend_mode, BaseMaterial3D.BLEND_MODE_MIX, "MIX, not ADD: additive is invisible under the Compatibility renderer")

	# One tick in it draws; a whole beat in it is gone.
	glow.call("_physics_process", TICK)
	var mesh := ring.mesh as ImmediateMesh
	assert_true(mesh != null and mesh.get_surface_count() == 1, "one tick into the beat the ring has a drawn surface")
	assert_false(glow.is_queued_for_deletion(), "the ring freed itself one tick into a 0.55 s beat")
	var elapsed := TICK
	while elapsed < 0.55 + TICK and not glow.is_queued_for_deletion():
		glow.call("_physics_process", TICK)
		elapsed += TICK
	assert_true(glow.is_queued_for_deletion(), "the ring must free itself when the beat ends")
	parent.free()
