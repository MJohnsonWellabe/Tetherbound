extends TestCase

const MODEL := preload("res://assets/creatures/tetherbound/torrentoad/models/creature_torrentoad_lod0.glb")


func test_replacement_attack_stays_in_place_without_a_root_lift() -> void:
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
	var root_position_track := -1
	var animated_bone_tracks := 0
	for track: int in attack.get_track_count():
		var path := str(attack.track_get_path(track))
		if attack.track_get_type(track) == Animation.TYPE_POSITION_3D \
				and path.ends_with(":root"):
			root_position_track = track
		if attack.track_get_type(track) == Animation.TYPE_ROTATION_3D \
				and path.contains("Skeleton3D:"):
			animated_bone_tracks += 1
	# The former mesh needed a sampled positive-Y correction because its source
	# attack floated. The replacement animation is authored in place: gameplay
	# owns body translation, while the skeleton supplies the anticipation and
	# strike. Its exported root channel may exist, but every key must remain at
	# the origin; reintroducing a positive-Y curve would lift this grounded frog.
	if root_position_track >= 0:
		var root_start := attack.track_get_key_value(root_position_track, 0) as Vector3
		for key: int in attack.track_get_key_count(root_position_track):
			var position := attack.track_get_key_value(root_position_track, key) as Vector3
			assert_almost_eq(position.distance_to(root_start), 0.0, 0.0001)
	assert_true(animated_bone_tracks >= 5)
	assert_true(attack.length >= 0.9)
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
	assert_eq((torrentoad.get("overlays", []) as Array).size(), 0)
