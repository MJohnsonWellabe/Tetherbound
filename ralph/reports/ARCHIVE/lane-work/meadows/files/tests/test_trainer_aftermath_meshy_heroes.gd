extends "res://tests/test_case.gd"

## F04#6 r31: the Meshy aftermath heroes are an OFF overlay of whole sites.
## Off, the judged visual_candidate_sites ship unchanged; on, each listed site
## is replaced and every other site is untouched.

const AFTERMATH := preload("res://scripts/world/trainer_aftermath.gd")


func _models(entry: Dictionary) -> Array:
	var out: Array = []
	for piece: Dictionary in (entry.get("site_object", {}) as Dictionary).get("pieces", []):
		out.append(piece.get("model"))
	return out


func test_shipping_config_keeps_the_heroes_off() -> void:
	AFTERMATH._config = {}
	var cfg := AFTERMATH.config()
	assert_false(bool(cfg.get("meshy_heroes_enabled", true)), "r31 heroes stay OFF until judged")
	assert_false(_models(AFTERMATH.for_trainer("captain_field")).has("meadows_field_tent"))


func test_enabled_heroes_replace_only_their_sites() -> void:
	AFTERMATH._config = {}
	var cfg := AFTERMATH.config().duplicate(true)
	cfg["meshy_heroes_enabled"] = true
	AFTERMATH._config = cfg
	assert_true(_models(AFTERMATH.for_trainer("captain_field")).has("meadows_field_tent"))
	assert_true(_models(AFTERMATH.for_trainer("captain_ridge")).has("meadows_ridge_pylon"))
	assert_true(_models(AFTERMATH.for_trainer("captain_riverwatch")).has("meadows_riverwatch_hut"))
	# Vance's site is not in the overlay and keeps its judged pieces.
	var vance := _models(AFTERMATH.for_trainer("relay_captain"))
	assert_true(vance.has("broken_tether_cage"))
	AFTERMATH._config = {}
