extends "res://tests/test_case.gd"

## F41#8 (LANE-BELOW6, 12 Nov 2026): the named villagers' post lanterns are
## declared OFF until GPU-judged, name the three villagers, and stand a step
## behind and to one side of the villager, never on top of them.

const POSTS := preload("res://scripts/world/stormwood_named_posts.gd")
const CONFIG := "res://data/config/stormwood_character_presentation.json"


func _raw() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	return (parsed as Dictionary).get("named_posts_1112", {}) if parsed is Dictionary else {}


func test_named_posts_declared_off_and_presentation_only() -> void:
	var raw := _raw()
	assert_false(raw.is_empty(), "named_posts_1112 is declared")
	assert_false(bool(raw.get("enabled", true)), "it ships OFF until GPU-judged")
	assert_eq(str(raw.get("scope", "")), "client_presentation")
	assert_true(POSTS.settings().is_empty(), "OFF returns no settings")
	for id in ["elder_maud", "rodkeeper_hesk", "warden_elect_bryn"]:
		assert_true(id in raw.get("ids", []), "%s keeps a lantern" % id)


func test_post_stands_beside_and_behind_the_villager() -> void:
	var raw := _raw()
	var at := Vector3(10.0, 2.0, -4.0)
	var post := POSTS.post_position(at, Vector3.BACK, raw)
	var away := Vector2(post.x - at.x, post.z - at.z)
	assert_true(away.length() > 1.2 and away.length() < 3.0, "a step away, not on the villager (%.2f m)" % away.length())
	assert_true((post - at).dot(Vector3.BACK) < 0.0, "behind the way the villager faces")
	assert_eq(post.y, at.y, "height is taken from the ground by the caller")
