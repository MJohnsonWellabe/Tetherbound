extends "res://tests/test_case.gd"

const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const MODELS := {
	"torrentoad": "res://assets/creatures/tetherbound/torrentoad/models/creature_torrentoad_lod0.glb",
	"abyssal_guardian": "res://assets/creatures/tetherbound/abyssal_guardian/models/creature_abyssal_guardian_lod0.glb",
}
const CLIPS := ["idle", "walk", "run", "attack", "hit", "faint"]


func test_replacements_import_with_complete_gameplay_animation_sets() -> void:
	for species: String in MODELS:
		var packed := load(MODELS[species]) as PackedScene
		assert_true(packed != null, "%s replacement imports" % species)
		if packed == null:
			continue
		var art := packed.instantiate() as Node3D
		var players: Array[Node] = art.find_children("*", "AnimationPlayer", true, false)
		assert_eq(players.size(), 1, "%s has one animation controller" % species)
		if players.size() == 1:
			var player := players[0] as AnimationPlayer
			for clip: String in CLIPS:
				assert_true(player.has_animation(clip), "%s carries %s" % [species, clip])
		art.free()


func test_torrentoad_is_squat_and_abyssal_is_long_bodied() -> void:
	var frog := (load(MODELS.torrentoad) as PackedScene).instantiate() as Node3D
	var frog_box: AABB = BOUNDS.measure(frog)
	assert_true(maxf(frog_box.size.x, frog_box.size.z) > frog_box.size.y * 1.6,
		"Torrentoad keeps its broad low frog silhouette")
	frog.free()

	var abyssal := (load(MODELS.abyssal_guardian) as PackedScene).instantiate() as Node3D
	var abyssal_box: AABB = BOUNDS.measure(abyssal)
	assert_true(maxf(abyssal_box.size.x, abyssal_box.size.z) > abyssal_box.size.y * 2.3,
		"Abyssal Guardian keeps its long low swimming silhouette")
	abyssal.free()
