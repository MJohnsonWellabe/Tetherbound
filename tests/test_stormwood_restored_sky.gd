extends "res://tests/test_case.gd"

## F10#4 (coordinator 13:20, #356): after the Long Storm the Struck
## Sentinel's strike cools to a scar with its light out, and the aftermath
## sky lifts toward restored light inside WO-F10-08's purple band.

const SENTINEL := preload("res://scripts/world/stormwood_struck_sentinel.gd")
const SURGE := preload("res://scripts/world/stormwood_surge.gd")


func test_the_sentinel_scar_cools_and_its_light_goes_out() -> void:
	var sentinel: Node3D = SENTINEL.new()
	sentinel.call("build")
	var scar := sentinel.get_node("LightningSplitScar")
	var afterglow := sentinel.get_node("StrikeAfterglow") as OmniLight3D
	var segment := scar.get_node("Scar00") as MeshInstance3D
	var material := segment.material_override as StandardMaterial3D
	assert_true(material.emission_enabled and afterglow.visible, "the live strike glows before the storm ends")
	sentinel.call("set_storm_ended", true)
	var cooled := Color(str(SENTINEL.aftermath_scar_config().colour))
	assert_eq(material.albedo_color.to_html(false), cooled.to_html(false), "the scar cools to the aftermath seam colour")
	assert_almost_eq(material.emission_energy_multiplier, 0.0, 0.0001, "no strike glow once the storm has ended")
	assert_false(afterglow.visible, "the afterglow light is out")
	for child: Node in scar.get_children():
		var m := (child as MeshInstance3D).material_override as StandardMaterial3D
		assert_almost_eq(m.emission_energy_multiplier, 0.0, 0.0001, "%s cooled" % child.name)
	sentinel.call("set_storm_ended", false)
	assert_true(material.emission_enabled and afterglow.visible, "clearing the flag restores the live strike")
	assert_eq(material.albedo_color.to_html(false), SENTINEL.COL_SCAR.to_html(false))
	sentinel.free()


func test_the_aftermath_sky_is_lifted_from_break_and_stays_purple() -> void:
	var surge := SURGE.new()
	var brk: Dictionary = surge._resolved(surge.presentation_for("break"))
	for phase: String in ["calm", "building", "break", "fading"]:
		var after: Dictionary = surge._resolved(surge.presentation_for(phase, true))
		assert_true(float(after.sun_energy_mult) > float(brk.sun_energy_mult) * 2.5, "%s aftermath key light lifted" % phase)
		assert_true(float(after.ambient_energy_mult) > float(brk.ambient_energy_mult), "%s aftermath ambient lifted" % phase)
		assert_true(float(after.fog_density_add) < float(brk.fog_density_add) * 0.25, "%s aftermath fog thinned" % phase)
		assert_true(float(after.ceiling_contrast) < float(brk.ceiling_contrast), "%s aftermath deck softer than Break" % phase)
		assert_true(float(after.ceiling_rim) >= 0.4 and float(after.ceiling_thin_glow) >= 0.25, "%s breaking light on the deck" % phase)
		var hue := (after.sky_top as Color).h * 360.0
		assert_true(hue >= 235.0 and hue <= 290.0, "%s aftermath stays purple (hue %.0f)" % [phase, hue])
	surge.free()
