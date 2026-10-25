extends "res://tests/test_case.gd"

## Fights close-1025 (`effect_banner.stagger_by_owner`): the player's own
## stagger line sits beside the player's panel, but the next type verdict is
## about the enemy plate's matchup and goes back under it.

const COMBAT_HUD_SCENE := preload("res://scenes/combat/combat_hud.tscn")
const RUNS_IN_INITIALIZED_TREE := true


func test_a_type_verdict_after_your_own_stagger_returns_under_the_enemy_plate() -> void:
	var hud: Node = COMBAT_HUD_SCENE.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(hud)
	var banner: Label = hud.get("_effect_banner")
	assert_true(banner != null, "the HUD builds its verdict banner")
	# As _on_staggered leaves it for the player's own creature.
	hud.set("_effect_banner_mine", true)
	hud.call("_on_hit_effectiveness", true, 1)
	assert_false(bool(hud.get("_effect_banner_mine")), "a type verdict clears the player-side placement")
	assert_eq(banner.anchor_left, 1.0, "and the banner is anchored under the enemy plate again")
	hud.free()
