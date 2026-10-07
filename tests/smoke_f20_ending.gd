extends SceneTree

## Run in a warm isolated checkout under the shared world-smoke reservation.
## Fixture starts after a settled finale. It does not claim earned combat.
const PROOF := preload("res://tests/helpers/f20_ending_probe.gd")
var proof := PROOF.new()
var _completed := false
var _credits_only := false

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	await process_frame
	_credits_only = OS.get_cmdline_user_args().has("--through-credits")
	var game := root.get_node("Game")
	if not proof.fixture(game, "Solo"): finish(); return
	var order_ui_only := OS.get_cmdline_user_args().has("--order-ui-only")
	var order_journal_only := OS.get_cmdline_user_args().has("--order-journal-only")
	if order_ui_only and order_journal_only:
		proof.check(false, "order UI and journal extension endpoints are exclusive")
		finish()
		return
	if order_ui_only or order_journal_only:
		if change_scene_to_file("res://scenes/world/meadows_playground.tscn") != OK:
			proof.check(false, "order UI fixture loads the production Meadows scene")
		else:
			if order_journal_only:
				_completed = await proof.order_journals(self, game)
			else:
				_completed = await proof.order_ui(self, game)
		for failure: String in proof.failures: print("F19 ORDER UI FAIL ", failure)
		print("F19 ORDER UI RESULT " + JSON.stringify({"passed":_completed and proof.failures.is_empty(),
			"setup":"existing disclosed post-finale fixture with personal portal unlocks",
			"endpoint":"journals" if order_journal_only else "map-and-signs",
			"earned_campaign":false,"ending_criterion_proof":false,"checks":proof.checks,"failures":proof.failures}))
		quit(0 if _completed and proof.failures.is_empty() else 1)
		return
	game.set("current_realm", "stormwood")
	game.local.set("realm", "stormwood")
	if change_scene_to_file("res://scenes/world/stormwood.tscn") != OK:
		proof.check(false, "production post-finale Stormwood scene loads"); finish(); return
	if not await proof.ending(self, game): finish(); return
	if not proof.check(game.call("save_game", 0), "completed world saves"): finish(); return
	var before := proof.retained(game)
	if not proof.check(proof.retained_valid(before), "completed character snapshot captured before memory reset"): finish(); return
	change_scene_to_file("res://scenes/ui/title_screen.tscn")
	for frame in 8: await process_frame
	game.call("reset_for_new_game")
	if not proof.check(game.call("load_game", 0), "production disk reload succeeds after memory reset"): finish(); return
	change_scene_to_file("res://scenes/world/meadows_playground.tscn")
	var resumed_result: Variant = await proof.resumed(self, game, before, not _credits_only)
	proof.check(resumed_result == true, "all credits, reload and once-only revisit checks reached their final result" if _credits_only
		else "all reload and completed-world continuation checks reached their final result")
	_completed = resumed_result == true
	finish()

func finish() -> void:
	if not _completed and proof.failures.is_empty():
		proof.check(false, "ending proof aborted before all required phases completed")
	for failure: String in proof.failures: print("F20 FAIL ", failure)
	print("F20 SOLO: %d checks, %d failures; actual input/UI/authority/disk with disclosed post-finale fixture" % [proof.checks, proof.failures.size()])
	print("F20 SOLO ENDPOINT " + JSON.stringify({"requested": "credits_and_reload" if _credits_only else "full_continuation",
		"passed": _completed and proof.failures.is_empty(), "continuation_content_run": proof.continuation_content_entered,
		"counts_as_f20_3_proof": _completed and proof.failures.is_empty() and not _credits_only,
		"earned_finale": false, "setup": "disclosed post-finale fixture"}))
	quit(0 if proof.failures.is_empty() else 1)
