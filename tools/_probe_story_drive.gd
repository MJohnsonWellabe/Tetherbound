extends SceneTree

## What is the player TOLD, at every rung of the chapter, and by whom?
##
##   godot --headless --path . --script tools/_probe_story_drive.gd
##
## T5-STORY-2's instrument. The lane's question is not whether the chapter's
## beats exist -- they do -- but whether a player moving through them ever knows
## why they are doing the next thing. That is a question about the guidance
## SURFACES, and it has never been read end to end: `smoke_gate_a_opening_segment.gd`
## plays the first fifteen minutes and stops at the tutorial catch, and the Gate F
## protocol samples the tracked objective as telemetry without ever asking whether
## the string it recorded would help anyone.
##
## So this stands the real Meadows up, takes the LIVE `Game.progression` store,
## and walks the chapter's own flags in `objectives.json` order -- the same ids
## the shipping systems set, listed in that file's own `_comment_gateb_flags`.
## At each rung it reads, through the game's own readers and nothing else:
##
##   * the tracked HUD line             -- scripts/debug/gate_f_probe.gd::tracked_objective()
##   * the tracked hint                 -- quest_log.gd::tracked_hint()
##   * the guided quest-log rows        -- quest_log.gd::guided_entries()
##   * what every village NPC would say -- village_npcs.gd::greeting_for()
##
## Nothing here reimplements a reader. `quest_log.gd` is instantiated once and
## handed the live progression, exactly as the HUD does it; `greeting_for` is
## already static and pure and is called as-is. A probe that parsed
## objectives.json itself would be measuring a second copy of the game.
##
## HONEST ABOUT WHAT THIS IS. This does not fight the captains or beat the
## Warden: it advances the same flags those fights write, in the order they write
## them, and asks what the shipping guidance says at each point. That makes it
## evidence about the GUIDANCE, which is this lane's subject, and it is not
## evidence that the fights are reachable -- Gate F owns that. Every line it
## prints is a string the shipping build would put on a real player's screen.

const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"
const PROBE := preload("res://scripts/debug/gate_f_probe.gd")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const VILLAGE_NPCS := preload("res://scripts/world/village_npcs.gd")
const SETTLE_FRAMES := 240

## The chapter, as the flags the shipping systems actually set, in the order a
## player sets them. Taken from `objectives.json`'s own rung order plus the
## intermediate flags its `count_flags` lists -- so a rung that counts 3 sub-fights
## is walked one sub-fight at a time, the way a player meets it.
const CHAPTER: Array = [
	["opening:beat:choose", "heard Grandpa out"],
	["opening:beat:return_starter", "chose and named a starter"],
	["opening:beat:walk_out", "showed Grandpa the starter; the door opens"],
	["opening:beat:road", "caught the first wild creature"],
	["road_gate_open", "opened the village gate"],
	# Mira's visit is a REQUIRED opening beat, not optional colour: Grandpa's
	# `grandpa_after_first_catch` sends the player to her by name and the beat
	# machine waits on `opening:mira_visited`. Her conversation sets all three of
	# these on one line. Without them a probe walks the chapter as a player who
	# never met her, and every villager ladder answers the wrong question.
	["mira_shop_open", "met Mira; the stall and the Orb recipe open"],
	["recipe_orb_basic", "learned the Basic Orb recipe"],
	["opening:mira_visited", "the opening's Mira beat closes"],
	["tam_tools_given", "took Tam's tools"],
	["oskar_trade_open", "Oskar explained the swap"],
	["tournament_team_ready", "team of five assembled"],
	# The training rung's own `how` line names these three: "Villagers who offer
	# a fight are the training". A player arrives at the tournament having beaten
	# them, so their ladders are past the challenge branch by here.
	["defeated_mira", "beat Mira"],
	["defeated_oskar", "beat Oskar"],
	["defeated_tam", "beat Tam"],
	["tournament_training_ready", "trained the team"],
	["home_materials_gathered", "gathered camp materials"],
	["home_built", "made camp"],
	["creature_bed_built", "built a Creature Bed"],
	["player_slept_at_home", "rested at camp"],
	["tournament_team_fed", "fed the team"],
	["tournament_entered", "entered the tournament"],
	["tournament_won", "won the tournament"],
	["south_bridge_open", "beat the grunt at South Bridge"],
	["warrens_cleared", "cleared the Burrow Warrens"],
	["relay_captain_defeated", "beat the Relay Captain"],
	["captive_rescued", "found the captive at the relay"],
	["relay_disabled", "shut the Tether Relay down"],
	["mill_crossing_restored", "restored the Old Mill Crossing"],
	["defeated_captain_field", "beat the Field captain"],
	["defeated_captain_ridge", "beat the Ridge captain"],
	["defeated_captain_riverwatch", "beat the Riverwatch captain"],
	["hall_approach_open", "the Hall approach opens"],
	["defeated_stronghold_patrol", "beat the Hall patrol"],
	["defeated_stronghold_courtyard", "beat the courtyard guard"],
	["defeated_stronghold_elite", "beat the elite"],
	["defeated_warden", "defeated the Meadows Warden"],
	["legendary_freed", "shut down the machine"],
	["legendary_settled", "settled the final five"],
	["meadows_acknowledged", "walked back through a healed Meadows"],
]

var _log: RefCounted = null
var _probe: RefCounted = null
var _progression: RefCounted = null
var _villagers: Array = []
## rung index -> what the guidance said. Kept so the summary can count silence
## without re-walking the chapter.
var _said: Array = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for _i in SETTLE_FRAMES:
		await physics_frame
	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("STORY-DRIVE FAIL: no Game autoload; nothing to read")
		quit(1)
		return
	_progression = game.get("progression") as RefCounted
	if _progression == null:
		print("STORY-DRIVE FAIL: Game has no progression store")
		quit(1)
		return
	_log = QUEST_LOG.new()
	_probe = PROBE.new(self)
	_villagers = _load_villagers()
	print("STORY-DRIVE: real Meadows up; %d villagers loaded; walking %d chapter flags"
		% [_villagers.size(), CHAPTER.size()])
	print("")

	_report("00", "a brand-new save, before anything", "")
	for index in CHAPTER.size():
		var step: Array = CHAPTER[index] as Array
		_progression.call("set_flag", str(step[0]), true)
		await process_frame
		_report("%02d" % (index + 1), str(step[1]), str(step[0]))
	_summarise()
	quit(0)


## One rung: everything the shipping build would tell the player at this point.
##
## Reported TWICE, because the chapter has two of them and they differ.
## `tournament_team_fed` is the chain's one volatile flag and `tournament.gd`'s
## `_process` rewrites it from the live team once a second, forever, with no gate
## on whether the tournament is still relevant. So the tracked line a player sees
## depends on whether their team happens to be hungry at that moment:
##
##   HUNGRY: what the live world actually says, flag left wherever the game put it.
##   FED   : the same read with `tournament_team_fed` forced true first, which is
##           what the chapter INTENDED to say at this rung.
##
## Neither is hypothetical -- both are reachable states of a shipping save, and a
## three-hour chapter with a ~1.1/min satiety drain spends a lot of time in the
## first one.
func _report(ordinal: String, what_just_happened: String, flag: String) -> void:
	print("--- %s  after: %s%s" % [
		ordinal, what_just_happened, "" if flag.is_empty() else "   [%s]" % flag])
	var hungry := str((_probe.call("tracked_objective") as Dictionary).get("text", ""))
	print("    tracked (hungry) : %s" % ("(none -- the chapter is finished)" if hungry.is_empty() else hungry))
	# Force the volatile flag and read again. This does not stop the live
	# tournament node clearing it a second later; it only asks what the chain
	# would say if the team had just eaten.
	_progression.call("set_flag", "tournament_team_fed", true)
	var tracked: Dictionary = _probe.call("tracked_objective")
	var line := str(tracked.get("text", ""))
	var hint := str(_log.call("tracked_hint", _progression))
	var guided: Array = _log.call("guided_entries", _progression)
	print("    tracked (fed)    : %s" % ("(none -- the chapter is finished)" if line.is_empty() else line))
	print("    quest-log hint   : %s" % ("(NONE AUTHORED)" if hint.is_empty() else hint))
	print("    guided rows      : %d of %d authored, current rung index %d" % [
		guided.size(), (_log.get("_main") as Array).size(),
		int(_log.call("current_index", _progression))])
	var voices := _who_speaks_to_this()
	if voices.is_empty():
		print("    village voices   : nobody in the village has a line about this")
	else:
		for voice: String in voices:
			print("    village voice    : %s" % voice)
	_said.append({"line": line, "hint": hint, "voice": voices.size(), "hungry": hungry})


## Which villagers would open a DIFFERENT conversation than their default right
## now -- i.e. who in the world has actually noticed what the player just did.
##
## Read through `village_npcs.gd::greeting_for()`, the same static resolver the
## live villager uses, against the live progression store.
func _who_speaks_to_this() -> Array:
	var out: Array = []
	for raw: Variant in _villagers:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var spec := raw as Dictionary
		var chosen := str(VILLAGE_NPCS.greeting_for(spec, _progression))
		var default := str(spec.get("greeting", ""))
		if chosen != default:
			out.append("%s -> %s" % [str(spec.get("name", "?")), chosen])
	return out


func _load_villagers() -> Array:
	var file := FileAccess.open("res://data/config/village_npcs.json", FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var villagers: Variant = (parsed as Dictionary).get("villagers", [])
	return villagers as Array if typeof(villagers) == TYPE_ARRAY else []


## The one number this probe exists to produce: how much of the chapter the
## player walks with a tracked line and no concrete direction under it.
func _summarise() -> void:
	var no_hint := 0
	var no_voice := 0
	var counted := 0
	for raw: Variant in _said:
		var row := raw as Dictionary
		if str(row.get("line", "")).is_empty():
			continue
		counted += 1
		if str(row.get("hint", "")).is_empty():
			no_hint += 1
		if int(row.get("voice", 0)) == 0:
			no_voice += 1
	print("")
	print("STORY-DRIVE SUMMARY")
	print("  rungs walked with an open objective : %d" % counted)
	print("  of those, with NO 'how' line        : %d" % no_hint)
	print("  of those, with NO village voice     : %d" % no_voice)
	var pinned := 0
	for raw: Variant in _said:
		var row := raw as Dictionary
		if str(row.get("hungry", "")) != str(row.get("line", "")):
			pinned += 1
	print("  rungs where a HUNGRY team is shown a")
	print("  DIFFERENT tracked line than the rung : %d" % pinned)
