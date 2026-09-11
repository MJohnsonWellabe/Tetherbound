extends TestCase

const MODEL := preload("res://assets/creatures/tetherbound/torrentoad/models/creature_torrentoad_lod0.glb")


func test_attack_carries_framewise_root_grounding_curve() -> void:
	var art := MODEL.instantiate()
	var players: Array[Node] = art.find_children("*", "AnimationPlayer", true, false)
	assert_false(players.is_empty())
	if players.is_empty():
		art.free()
		return
	var player := players[0] as AnimationPlayer
	assert_true(player.has_animation("attack"))
	var attack := player.get_animation("attack")
	assert_true(attack != null)
	if attack == null:
		art.free()
		return
	var root_track := -1
	for track: int in attack.get_track_count():
		if attack.track_get_type(track) == Animation.TYPE_POSITION_3D \
				and str(attack.track_get_path(track)).ends_with(":root"):
			root_track = track
			break
	assert_true(root_track >= 0)
	if root_track < 0:
		art.free()
		return
	var key_count := attack.track_get_key_count(root_track)
	assert_true(key_count >= 24)
	assert_almost_eq(attack.track_get_key_time(root_track, 0), 0.0, 0.0001)
	assert_almost_eq(attack.track_get_key_time(root_track, key_count - 1), attack.length, 0.0001)
	var first := attack.track_get_key_value(root_track, 0) as Vector3
	var peak := first.y
	for key: int in key_count:
		peak = maxf(peak, (attack.track_get_key_value(root_track, key) as Vector3).y)
	assert_true(first.y > 0.19)
	assert_true(peak > 0.35)
	assert_almost_eq((attack.track_get_key_value(root_track, key_count - 1) as Vector3).y, 0.0, 0.001)
	art.free()


func test_torrentoad_colourway_preserves_source_anatomy() -> void:
	var file := FileAccess.open("res://data/creatures/four_biome_colourways.json", FileAccess.READ)
	assert_true(file != null)
	if file == null:
		return
	var parsed := JSON.parse_string(file.get_as_text()) as Dictionary
	var torrentoad := (parsed.get("species", {}) as Dictionary).get("torrentoad", {}) as Dictionary
	var rules := torrentoad.get("vivid_rules", []) as Array
	assert_eq(rules.size(), 1)
	assert_true((rules[0] as Dictionary).has("match"))
	assert_true(((rules[0] as Dictionary).get("match", {}) as Dictionary).is_empty())
	assert_almost_eq(float((rules[0] as Dictionary).get("sat_scale", 0.0)), 1.0)
	assert_eq((torrentoad.get("overlays", []) as Array).size(), 1)
