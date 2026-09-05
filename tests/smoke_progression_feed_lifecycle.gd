extends SceneTree

## Cloudreach/main overlap: owned-only production events and successful/failed
## save-load reset semantics, using the real Game and an isolated save directory.
const FEED := preload("res://scripts/creatures/progression_feed.gd")
const BOND := preload("res://scripts/creatures/bond_milestones.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const SAVE := preload("res://scripts/save/save_game.gd")

var _failures: Array[String] = []
var _assertions := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	_assertions += 1
	if not condition:
		_failures.append(message)
		push_error(message)


func _run() -> void:
	await process_frame
	var game := root.get_node("Game")
	game.set_process(false)
	game.reset_for_new_game()
	var cfg := PROGRESSION.config()
	var active: RefCounted = game.make_creature("mudsnout", "Lead")
	var bench: RefCounted = game.make_creature("bramblebun", "Bench")
	var trainer: RefCounted = game.make_creature("galecrest", "Opponent")
	game.party.add(active)
	game.party.add(bench)
	game.party.set_active(0)
	trainer.gain_xp(12, cfg)
	trainer.gain_levels(1, cfg)
	BOND.credit_feed(trainer)
	_check(FEED.events().is_empty(), "an unowned opponent produces no progression feedback")
	bench.gain_xp(12, cfg)
	var events := FEED.events()
	_check(events.size() == 1 and int(events[0].creature_id) == bench.get_instance_id(),
		"a nonactive owned creature produces one shared XP event")
	var party_revision: int = game.party.revision
	bench.gain_levels(1, cfg)
	_check(FEED.events().size() == 2, "candy adds one level event and no synthetic XP")
	_check(game.party.revision == party_revision + 1, "one level transition invalidates the party UI once")
	active.set_level(12, cfg)
	_check(FEED.events().size() == 2, "the story/spawn level setter remains silent even for an owned creature")
	var save_dir := "user://test_progression_feed_lifecycle_%d_%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	var saves := SAVE.new(save_dir)
	game.save_system = saves
	_check(saves.save(game, 0), "fixture saves through the production serializer")
	var epoch := FEED.epoch()
	var before_failed := FEED.events()
	_check(not game.load_game(1), "a missing isolated save is refused")
	_check(FEED.epoch() == epoch and FEED.events() == before_failed,
		"a failed load leaves live feedback intact")
	_check(game.load_game(0), "fixture loads through Game's real restore path")
	_check(FEED.events().is_empty(), "loading does not replay earned or hydration events")
	_check(FEED.epoch() > epoch, "successful load invalidates all prior presenter cursors")
	_check(game.party.size() == 2 and int(game.party.at(1).xp) == 12,
		"owned team and banked XP survive the load")
	game.party.at(1).gain_xp(1, cfg)
	_check(FEED.events().size() == 1, "the hydrated owned creature resumes the same single event source")
	epoch = FEED.epoch()
	game.reset_for_new_game()
	_check(FEED.events().is_empty() and FEED.epoch() > epoch, "new game clears the log and changes its epoch")
	# Only this smoke's newly-created file/directory is removed.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(saves.slot_path(0)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_dir))
	print("PROGRESSION FEED LIFECYCLE %s: %d assertions" % ["PASS" if _failures.is_empty() else "FAIL", _assertions])
	quit(0 if _failures.is_empty() else 1)
