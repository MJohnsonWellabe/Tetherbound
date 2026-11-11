extends "res://tests/test_case.gd"

## F40#11 terrace edge clouds (GPU High 5.26 -> 5.99, G-newapproach-edge-cards):
## the island mist banks draw as soft cards of the installed cumulus texture.


func test_island_mist_ships_as_cumulus_cards_with_its_verdict() -> void:
	var roots: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/cloudreach_visual.json")) as Dictionary).island_roots
	assert_eq(str(roots.mist_style), "cumulus_cards", "the judged mist style ships")
	assert_true(str(roots.get("_mist_style_why_on", "")).contains("5.26 -> 5.99"), "the style records its GPU verdict")
	assert_true((roots.low_mist as Dictionary).get("enabled") == true, "the low collar the cards were judged with stays ON")


func test_the_card_path_uses_the_installed_cumulus_texture() -> void:
	assert_true(ResourceLoader.exists("res://assets/environment/cloudreach/cloud_bank_v1.png"), "the cumulus texture is installed")
	var source := FileAccess.get_file_as_string("res://scripts/world/cloudreach_world.gd")
	assert_true(source.contains("\"cumulus_cards\""), "the world builds the cumulus_cards style")
	assert_true(source.contains("proximity_fade_enabled = true"), "cards fade against solid ground")
	assert_true(source.contains("DISTANCE_FADE_PIXEL_ALPHA"), "cards fade near the camera")
