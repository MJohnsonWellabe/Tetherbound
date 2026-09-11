extends "res://tests/test_case.gd"

const MODEL := "res://assets/creatures/tetherbound/skyrill/models/creature_skyrill_lod0.glb"
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")


func test_replacement_is_compact_and_keeps_all_gameplay_clips() -> void:
	var packed := load(MODEL) as PackedScene
	assert_true(packed != null, "Skyrill replacement imports as a PackedScene")
	if packed == null:
		return
	var art := packed.instantiate() as Node3D
	assert_true(art != null)
	if art == null:
		return
	var box: AABB = BOUNDS.measure(art)
	assert_between(box.size.y, 0.85, 1.05, "raw replacement stays near its authored metre scale")
	var footprint := maxf(box.size.x, box.size.z)
	assert_between(footprint / box.size.y, 1.7, 2.5,
		"compact sail-backed lizard cannot regress to the former broad-winged envelope")

	var players: Array[Node] = art.find_children("*", "AnimationPlayer", true, false)
	assert_eq(players.size(), 1, "replacement has one animation controller")
	if players.size() == 1:
		var player := players[0] as AnimationPlayer
		for clip: String in ["idle", "walk", "run", "attack", "hit", "faint"]:
			assert_true(player.has_animation(clip), "replacement carries %s" % clip)
	art.free()
