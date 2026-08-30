extends SceneTree

## T3-COMBAT. Did the captain rebalance change the FIGHTS, or only the config?
##
##   godot --headless --path . --script tools/_probe_captain_rebalance.gd
##
## `data/config/bands/band4_upper_meadows_ironwood/trainers.json` carries a
## `_why_t3_typechart_rebalance` note on both regional captains. It says the
## Field Captain's Ground x3 handed any Water challenger "a -35% exchange
## discount for the whole fight", that the Ridge Captain's Air x3 handed a
## Ground challenger the same, and that swapping the weakest member of each for
## an off-type creature of the same level breaks the sweep.
##
## That claim was verified with `tools/_probe_captain_typechart.gd`, which
## MODELS three mono-type challengers against the chart. A model can tell you the
## multiplier moved. It cannot tell you whether a player would notice, because
## what a player notices is how long the fight took and how much health it cost —
## and those depend on the AI's telegraph, the pilot's spacing, the arena and
## every other thing a spreadsheet does not have.
##
## So this fights each captain TWICE: once with the roster that shipped, and once
## with the roster that shipped BEFORE the rebalance, reconstructed from the same
## note. Same challenger team, same levels, same pilot, same ground, back to back.
## The difference between the two fights is what the rebalance actually bought.
##
## Both rosters are fought through `encounter_director.begin_trainer_battle()`,
## which takes the trainer spec as a plain Dictionary — so the "before" roster is
## a real trainer battle against a real team, not a simulation of one.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const PILOT := preload("res://tools/combat_pilot.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")

const SETTLE_FRAMES := 240
const BATTLE_FRAME_LIMIT := 30000
const STAGE := Vector3(48.0, 0.0, -58.0)

## `chapter_curve.json` puts the player at 13->16 across Band 4; the captains sit
## at the top of that span, so the challenger is level 15 for every row here.
const CHALLENGER_LEVEL := 15

## The four fights. `roster` null means "whatever `trainers.json` ships"; a list
## is the pre-rebalance roster, taken verbatim from the swap each captain's own
## `_why_t3_typechart_rebalance` note describes.
const ROWS: Array = [
	{
		"captain": "captain_field",
		"label": "shipped (duskhush/tuskroot/meadowhart — Air, Ground, Ground)",
		"roster": null,
		# The challenger the rebalance exists to stop sweeping: mono-Water.
		"team": ["ripplet", "brooktail", "paddlenewt"],
	},
	{
		"captain": "captain_field",
		"label": "pre-rebalance (burrowback/tuskroot/meadowhart — Ground x3)",
		"roster": [
			{"species": "burrowback", "level": 13},
			{"species": "tuskroot", "level": 14},
			{"species": "meadowhart", "level": 15},
		],
		"team": ["ripplet", "brooktail", "paddlenewt"],
	},
	{
		"captain": "captain_ridge",
		"label": "shipped (trailpup/duskhush/galecrest — Ground, Air, Air)",
		"roster": null,
		# Mono-Ground: the challenger the Ridge Captain's Air x3 used to feed.
		"team": ["trailpup", "terrapup", "tuskroot"],
	},
	{
		"captain": "captain_ridge",
		"label": "pre-rebalance (pipwing/duskhush/galecrest — Air x3)",
		"roster": [
			{"species": "pipwing", "level": 14},
			{"species": "duskhush", "level": 15},
			{"species": "galecrest", "level": 16},
		],
		"team": ["trailpup", "terrapup", "tuskroot"],
	},
]

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _game: Node = null
var _party: RefCounted = null
var _progression: RefCounted = null
var _pilot: RefCounted = null

var _results: Array = []
var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
	if not _collect_nodes():
		quit(1)
		return

	await _stand_at_the_stage()
	if _director.call("ally_instance") == null:
		await _director.call("adopt_starter", str((ROWS[0]["team"] as Array)[0]))

	for row: Dictionary in ROWS:
		var record := await _fight(row)
		_results.append(record)
		_print(record)

	_report()


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_game = root.get_node_or_null(^"Game")
	if _player == null or _rig == null or _manager == null or _director == null or _game == null:
		print("PROBE FAIL: the playground is missing a node the probe needs")
		return false
	_party = _game.get("party") as RefCounted
	_progression = _game.get("progression") as RefCounted
	_pilot = PILOT.new(self, _manager, _director, _rig)
	_pilot.pilot = PILOT.Pilot.SPACER
	_pilot.listen()
	return true


func _stand_at_the_stage() -> void:
	var spot := STAGE
	spot.y = float(_world.call("ground_height_at", spot.x, spot.z)) + 1.0
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame


func _fight(row: Dictionary) -> Dictionary:
	var captain := str(row["captain"])
	var spec: Dictionary = TRAINERS.trainer(captain).duplicate(true)
	if spec.is_empty():
		_failures.append("no trainer '%s'" % captain)
		return {"captain": captain, "abandoned": true}
	var roster: Variant = row["roster"]
	if roster is Array:
		spec["team"] = (roster as Array).duplicate(true)

	_build_the_party(row["team"] as Array)
	await _wait_for_the_body(str((row["team"] as Array)[0]))
	var flag := str(spec.get("defeat_flag", ""))
	if flag != "" and _progression != null:
		_progression.call("set_flag", flag, false)

	_pilot.reset_tally()
	if not bool(_director.call("begin_trainer_battle", spec, null)):
		_failures.append("'%s' (%s) refused the challenge" % [captain, str(row["label"])])
		return {"captain": captain, "abandoned": true}

	var frames := 0
	var rounds := 0
	while bool(_director.call("trainer_battle_active")) and frames < BATTLE_FRAME_LIMIT:
		if bool(_manager.call("is_fighting")):
			var result: Dictionary = await _pilot.fight_to_the_end()
			frames += int(result["frames"])
			rounds += 1
			if bool(result["timed_out"]):
				break
		else:
			await physics_frame
			frames += 1
	Input.action_release("move_forward")
	for i in 40:
		await physics_frame

	var won: bool = flag != "" and _progression != null and bool(_progression.call("has", flag))
	var hp := 0.0
	var faints := 0
	var size := int(_party.call("size"))
	for i in size:
		var creature: RefCounted = _party.call("at", i)
		if creature == null:
			continue
		hp += float(creature.get("hp")) / maxf(float(creature.get("max_hp")), 1.0)
		if bool(creature.get("fainted")):
			faints += 1

	return {
		"captain": captain,
		"label": str(row["label"]),
		"challenger": ", ".join(row["team"] as Array),
		"won": won,
		"rounds": rounds,
		"seconds": float(frames) / 60.0,
		"party_hp_left": hp / maxf(float(size), 1.0),
		"faints": faints,
		"hits_dealt": _pilot.hits_dealt,
		"hits_taken": _pilot.hits_taken,
		"damage_dealt": _pilot.damage_dealt,
		"damage_taken": _pilot.damage_taken,
		"verdicts_on_enemy": _pilot.verdicts_on_enemy.duplicate(),
		"verdicts_on_ally": _pilot.verdicts_on_ally.duplicate(),
	}


func _build_the_party(recipe: Array) -> void:
	var cfg: Dictionary = PROGRESSION.config()
	_party.call("clear")
	for species: Variant in recipe:
		var creature: RefCounted = _game.call("make_creature", str(species))
		if creature == null:
			continue
		creature.call("set_level", CHALLENGER_LEVEL, cfg)
		creature.set("hp", float(creature.get("max_hp")))
		creature.set("energy", 0.0)
		creature.set("fainted", false)
		_party.call("add", creature)
	_party.call("set_active", 0)


func _wait_for_the_body(species: String) -> void:
	for i in 120:
		await physics_frame
		var out: RefCounted = _director.call("ally_instance")
		if out != null and str(out.get("species_id")) == species and not bool(out.get("fainted")):
			return


func _print(record: Dictionary) -> void:
	if record.get("abandoned", false):
		print("  %s: ABANDONED" % record["captain"])
		return
	print("  %-14s %s" % [record["captain"], record["label"]])
	print("        challenger %s at L%d" % [record["challenger"], CHALLENGER_LEVEL])
	print("        %s in %5.1fs over %d rounds; party hp left %5.1f%%, faints %d" % [
		"WON" if record["won"] else "LOST", record["seconds"], record["rounds"],
		record["party_hp_left"] * 100.0, record["faints"]])
	print("        dealt %5.1f over %d hits, took %5.1f over %d hits" % [
		record["damage_dealt"], record["hits_dealt"],
		record["damage_taken"], record["hits_taken"]])
	print("        verdicts on them %s, on you %s" % [
		record["verdicts_on_enemy"], record["verdicts_on_ally"]])


func _report() -> void:
	print("")
	print("=== T3-COMBAT captain rebalance: shipped vs pre-rebalance, fought ===")
	for record: Dictionary in _results:
		if record.get("abandoned", false):
			continue
		print("TSV\t%s\t%s\t%s\t%.1f\t%.3f\t%d\t%.1f\t%d" % [
			record["captain"], record["label"], "won" if record["won"] else "lost",
			record["seconds"], record["party_hp_left"], record["faints"],
			record["damage_taken"], record["hits_taken"]])
	for line in _failures:
		print("PROBLEM: %s" % line)
	quit(0)
