extends SceneTree

## F07#0 Waycamp payoff (ruling (a), #356 14:00), in the production world: a
## companion bedded in Galefoot's sheltered bed (-21) with the shelter complete
## is paid the bed's rest XP twice by `game_state.complete_creature_bed_rests()`;
## a companion in another bed, or before the shelter, once. The bonus is on
## the creature before the sleep autosave, so saving at that instant (quit
## after sleep) and reloading keeps it. Fixture start (disclosed): flags and
## bed assignments written directly; the sleep is the production call.
##
##   godot --headless --path . --script tests/smoke_cloudreach_sheltered_rest.gd

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SAVE := preload("res://scripts/save/save_game.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const SLOT := 0

var _game: Node
var _world: Node
var _failures: Array[String] = []
var _checks := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_game = root.get_node(^"Game")
	_game.call("reset_for_new_game")
	_game.set("save_system", SAVE.new("user://cloudreach_sheltered_rest_smoke/"))
	_game.set("current_realm", "cloudreach")
	var party: RefCounted = _game.get("party")
	for species: String in ["sparkit", "mudsnout"]:
		party.call("add", SPECIES.spawn(species))
	for flag: String in ["realm_key_cloudreach", "cloudreach_chapter_started", "cloudreach_crisis_learned"]:
		_game.progression.set_flag(flag)
	await _load_world()
	var rest_xp: int = PROGRESSION.rest_xp(PROGRESSION.config())
	var sheltered: RefCounted = party.call("at", 0)
	var elsewhere: RefCounted = party.call("at", 1)

	# Before the shelter: both beds pay rest XP once.
	var night := await _night({sheltered: -21, elsewhere: -25})
	_check(night[0] == rest_xp and night[1] == rest_xp, "before the shelter, the Galefoot bed pays rest XP once (%s)" % str(night))

	_game.progression.set_flag("side_waycamp_shelter_complete")
	night = await _night({sheltered: -21, elsewhere: -25})
	_check(night[0] == rest_xp * 2, "the sheltered bed pays rest XP twice (%d, rest_xp %d)" % [night[0], rest_xp])
	_check(night[1] == rest_xp, "another camp's bed still pays once (%d)" % night[1])

	# Quit after sleep: save at the instant the night completes, reload.
	var expected_xp := int(sheltered.get("xp"))
	var expected_level := int(sheltered.get("level"))
	_check(bool(_game.call("save_game", SLOT)), "save right after the night")
	_world.queue_free()
	for _i in 4:
		await process_frame
	_check(bool(_game.call("load_game", SLOT)), "reload")
	await _load_world()
	var reloaded: RefCounted = (_game.get("party") as RefCounted).call("at", 0)
	_check(int(reloaded.get("xp")) == expected_xp and int(reloaded.get("level")) == expected_level,
		"the sheltered bonus survives quit-after-sleep and reload (xp %d/%d)" % [int(reloaded.get("xp")), expected_xp])
	print("CLOUDREACH SHELTERED REST %s checks=%d failures=%d %s" % ["OK" if _failures.is_empty() else "FAIL", _checks, _failures.size(), str(_failures)])
	quit(0 if _failures.is_empty() else 1)


## Bed each companion, run the production night, return the XP each gained.
func _night(beds: Dictionary) -> Array:
	var before: Array = []
	for creature: RefCounted in beds:
		creature.set("resting", true)
		creature.set("rest_bed_index", int(beds[creature]))
		before.append(_progress(creature))
	_game.call("complete_creature_bed_rests")
	var out: Array = []
	var i := 0
	for creature: RefCounted in beds:
		out.append(_progress(creature) - int(before[i]))
		i += 1
	for _f in 3:
		await process_frame
	return out


## XP earned, as (level, xp) -- a few rest XP never crosses a level here, and
## a level-up would show as a large jump, never a silent match.
func _progress(creature: RefCounted) -> int:
	return int(creature.get("level")) * 100000 + int(creature.get("xp"))


func _load_world() -> void:
	_world = SCENE.instantiate()
	root.add_child(_world)
	current_scene = _world
	for _i in 30:
		await process_frame


func _check(ok: bool, label: String) -> void:
	_checks += 1
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures.append(label)
