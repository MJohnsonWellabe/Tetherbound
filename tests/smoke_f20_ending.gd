extends SceneTree

## Run in a warm isolated checkout under the shared world-smoke reservation.
## Fixture starts after a settled finale. It does not claim earned combat.
const PROOF := preload("res://tests/helpers/f20_ending_probe.gd")
var proof := PROOF.new()

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	await process_frame
	var game := root.get_node("Game")
	if not proof.fixture(game, "Solo"): finish(); return
	game.set("current_realm", "stormwood")
	game.local.set("realm", "stormwood")
	if change_scene_to_file("res://scenes/world/stormwood.tscn") != OK:
		proof.check(false, "production post-finale Stormwood scene loads"); finish(); return
	if not await proof.ending(self, game): finish(); return
	if not proof.check(game.call("save_game", 0), "completed world saves"): finish(); return
	var before := proof.retained(game)
	change_scene_to_file("res://scenes/ui/title_screen.tscn")
	for frame in 8: await process_frame
	game.call("reset_for_new_game")
	if not proof.check(game.call("load_game", 0), "production disk reload succeeds after memory reset"): finish(); return
	change_scene_to_file("res://scenes/world/meadows_playground.tscn")
	await proof.resumed(self, game, before)
	finish()

func finish() -> void:
	for failure: String in proof.failures: print("F20 FAIL ", failure)
	print("F20 SOLO: %d checks, %d failures; actual input/UI/authority/disk with disclosed post-finale fixture" % [proof.checks, proof.failures.size()])
	quit(0 if proof.failures.is_empty() else 1)
