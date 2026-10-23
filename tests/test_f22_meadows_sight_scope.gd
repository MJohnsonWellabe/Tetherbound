extends "res://tests/test_case.gd"

## F22#4 review (coordinator, 22 Oct): turning the sight-line fade on for the
## Meadows ('playground') for the Riverwatch captain must not change
## exploration, and must not run the fight presentation in any other Meadows
## fight.
##
## - Exploration: `near_lens_fade` bakes only the near_lens_fade block's own
##   band, for its own realms and models. A model that is only a sight-line
##   model, in a realm only the sight-line fade is on for, keeps its mesh.
## - Fights: `realm_trainers` limits the Meadows fight presentation to the
##   Riverwatch captain; Stormwood, which it does not list, allows every fight.

const VISIBILITY := preload("res://scripts/world/foliage_camera_visibility.gd")
const FIGHT_FADE := preload("res://scripts/world/foliage_fight_fade.gd")


func _sight() -> Dictionary:
	return VISIBILITY.config().get("line_of_sight_fade", {})


func test_exploration_meshes_are_untouched_by_the_sight_line_fade() -> void:
	var lens: Dictionary = VISIBILITY.config().get("near_lens_fade", {})
	var lens_models: Array = lens.get("models", []) if bool(lens.get("enabled", false)) else []
	var lens_realms: Array = lens.get("realms", []) if bool(lens.get("enabled", false)) else []
	var checked := 0
	for realm: String in _sight().get("enabled_realms", []):
		if not FIGHT_FADE.configured(realm, _sight()):
			continue
		for model: String in _sight().get("models", []):
			if realm in lens_realms and model in lens_models:
				continue  # the exploration band's own model: not this test's subject
			var mesh := BoxMesh.new()
			mesh.material = StandardMaterial3D.new()
			assert_true(VISIBILITY.near_lens_fade(mesh, model, realm) == mesh,
				"%s in %s keeps its exploration mesh" % [model.get_file(), realm])
			checked += 1
	assert_true(checked > 0, "at least one sight-only model/realm pair checked")


func test_meadows_fight_presentation_is_the_riverwatch_captain_only() -> void:
	assert_true(FIGHT_FADE.configured("playground", _sight()), "the Meadows fade materials build")
	assert_true(FIGHT_FADE.allows_fight("playground", _sight(), "captain_riverwatch"),
		"the judged Riverwatch fight runs it")
	for other: String in ["", "captain_field", "relay_captain", "warden_aldis", "captain_ridge"]:
		assert_false(FIGHT_FADE.allows_fight("playground", _sight(), other),
			"Meadows fight '%s' does not" % other)


func test_stormwood_keeps_every_fight() -> void:
	for id: String in ["", "captain_marrow", "any_trainer"]:
		assert_true(FIGHT_FADE.allows_fight("stormwood", _sight(), id), "Stormwood fight '%s' unchanged" % id)
