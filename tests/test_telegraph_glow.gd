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
