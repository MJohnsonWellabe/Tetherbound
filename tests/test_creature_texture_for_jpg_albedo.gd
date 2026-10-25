extends "res://tests/test_case.gd"

# Installed Meshy lod0 GLBs extract their albedo as `..._Image_0.jpg`, and their
# vivid/shiny/alpha repaints live at `<sp>_extracted_base_color_<suffix>.png`.
# The close-1024 remake lookup (`<albedo>_<suffix>.png` beside a .jpg) must not
# hide those: review of #717 found every .jpg-albedo species losing its colourway.

const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const GALECREST_ALBEDO := "res://assets/creatures/tetherbound/galecrest/models/creature_galecrest_lod0_Image_0.jpg"
const GALECREST_DIR := "res://assets/creatures/tetherbound/galecrest/models/"
const STORMTRAIL_ALBEDO := "res://assets/creatures/tetherbound/trailpup/candidate_nat1024/models/creature_trailpup_nat1024_Image_0.jpg"


func test_installed_jpg_albedo_still_finds_its_extracted_colourways() -> void:
	var albedo := load(GALECREST_ALBEDO) as Texture2D
	assert_true(albedo != null, "galecrest's installed albedo loads")
	if albedo == null:
		return
	for suffix in ["vivid", "shiny", "alpha"]:
		var found: Texture2D = CREATURE_BODY._texture_for(albedo, "galecrest", suffix)
		assert_true(found != null, "galecrest %s colourway resolves" % suffix)
		if found != null:
			assert_eq(found.resource_path,
				GALECREST_DIR + "galecrest_extracted_base_color_%s.png" % suffix)


func test_remake_jpg_albedo_prefers_its_own_variant_texture() -> void:
	if not ResourceLoader.exists(STORMTRAIL_ALBEDO):
		return
	var albedo := load(STORMTRAIL_ALBEDO) as Texture2D
	var found: Texture2D = CREATURE_BODY._texture_for(albedo, "stormtrail", "stormtrail")
	assert_true(found != null, "the remake's stormtrail repaint beside the .jpg resolves")
	if found != null:
		assert_eq(found.resource_path, STORMTRAIL_ALBEDO.get_basename() + "_stormtrail.png")
