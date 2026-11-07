extends "res://tests/test_case.gd"

## F38#1 rest_faint_settled (creatures_visual.json, creature_animator.gd
## play_terminal): a species resting on its faint clip starts at the clip's
## settled end when ON, and replays the collapse from the start when OFF.

const RUNS_IN_INITIALIZED_TREE := true
const BODY := preload("res://scripts/creatures/creature_body.gd")
const VISUAL := preload("res://scripts/creatures/creature_visual.gd")
const SCENE := preload("res://scenes/creatures/creature.tscn")
const KEY := "rest_faint_settled"

var _saved: Variant = null


func before_each() -> void:
	_saved = (VISUAL.config().get(KEY, {}) as Dictionary).duplicate(true)


func after_each() -> void:
	VISUAL.config()[KEY] = _saved


func _rest_position(enabled: bool) -> float:
	(VISUAL.config()[KEY] as Dictionary)["enabled"] = enabled
	var tree := Engine.get_main_loop() as SceneTree
	var body := SCENE.instantiate()
	body.set_script(BODY)
	tree.root.add_child(body)
	body.call("setup", "veridian", false)
	await tree.process_frame
	body.call("play_rest")
	var player: AnimationPlayer = (body.get("_animator") as Object).get("_player")
	var clip := String(player.current_animation)
	var position := player.current_animation_position
	var length := player.get_animation(clip).length if clip != "" else 0.0
	body.free()
	return position / maxf(length, 0.001)


func test_off_replays_and_on_starts_at_the_settled_end() -> void:
	var off: float = await _rest_position(false)
	assert_true(off < 0.2, "OFF: the faint-clip rest starts near the clip start (%.2f)" % off)
	var on: float = await _rest_position(true)
	assert_true(on > 0.95, "ON: the faint-clip rest starts at the settled end (%.2f)" % on)
