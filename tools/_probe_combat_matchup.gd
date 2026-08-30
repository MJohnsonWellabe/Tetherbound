extends SceneTree

## T3-COMBAT. Does the type chart READ, in a fight, to a person playing it?
##
##   godot --headless --path . --script tools/_probe_combat_matchup.gd
##   godot --headless --path . --script tools/_probe_combat_matchup.gd -- --pilot=brawler
##
## The question this exists to answer is not "is the multiplier applied" —
## `tests/test_type_chart.gd` owns that, and `tests/smoke_combat.gd` proves the
## manager consults the chart at all. The question is the one on
## `ralph/MEADOWS_EXIT_CRITERION.md` §I1: **type matchups are legible in the
## moment.** A player who brings the wrong creature must find that out *during*
## the fight, in time to do something about it, rather than by losing.
##
## That is only answerable from played fights, because the thing being measured
## is a difference between fights: the same creature, the same level, the same
## pilot, against three opponents that differ only in what the chart says about
## them. If advantage, neutral and disadvantage produce the same fight, the
## chart is invisible however correct its arithmetic is.
##
## So every row below is a real staged encounter in `meadows_playground.tscn`:
## the wild creature is spawned through `encounter_director.spawn_wild()` — the
## same call the meadow's own clusters come from — the trainer WALKS the last
## stretch on the stick, engages with `interact`, and the fight is piloted with
## `combat_quick` / `combat_charged` presses through `tools/combat_pilot.gd`.
## Nothing here calls a damage function.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const PILOT := preload("res://tools/combat_pilot.gd")
const CHART := preload("res://scripts/combat/type_chart.gd")
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")

const SETTLE_FRAMES := 240

## Open meadow, and known walkable: this is the spot `tests/smoke_combat.gd`
## already walks the trainer out of the farmhouse to, near the practice cluster.
## Every staged encounter happens here, one at a time, with the previous
## opponent freed first — so each row is measured on the same ground and the
## terrain is not a variable between rows.
const STAGE := Vector3(48.0, 0.0, -58.0)
## How far from the stage any other wild creature may be standing when a row
## begins. Anything nearer is put to sleep for the row, because
## `_engageable()` picks the NEAREST creature and a wandering neighbour would
## silently substitute itself for the opponent under test.
const CLEAR_RADIUS := 26.0

## The matchups. Deliberately NOT a mirror: the whole complaint that opened this
## lane is that `smoke_combat.gd` draws the same species on both sides, and a
## mirror fight cannot show whether the chart does anything at all.
##
## One attacker, three defenders, one level, one pilot. The ONLY thing that
## differs across the first three rows is what `type_chart.json` says, which is
## what makes the three fights comparable and the comparison meaningful.
const ROWS: Array = [
	# Water into Ground: 1.25. The chart's most common player-side advantage.
	{"ally": "ripplet", "foe": "burrowback", "level": 12, "note": "advantage 1.25 (water->ground)"},
	# Water into Water: 1.00, and the defender is the same shape of creature.
	{"ally": "ripplet", "foe": "mosshell", "level": 12, "note": "neutral 1.00 (water->water)"},
	# Air into Ground: 0.80. The tax.
	{"ally": "galewisp", "foe": "burrowback", "level": 12, "note": "resisted 0.80 (air->ground)"},
	# The same defender met by the attacker that is neutral into it, so the
	# 0.80 row above has a same-defender control and not only a same-attacker one.
	{"ally": "trailpup", "foe": "burrowback", "level": 12, "note": "neutral 1.00 (ground->ground)"},
	# The chapter's only double weakness (T3-MATCHUPS): Water into Ground/Fire.
	{"ally": "ripplet", "foe": "ashtusk", "level": 12, "note": "double advantage 1.5625 (water->ground/fire)"},
	# And a mirror, kept ONLY as the control that shows what a fight with no
	# type information in it looks like — the fight `smoke_combat.gd` was
	# grading the whole system on.
	{"ally": "burrowback", "foe": "burrowback", "level": 12, "note": "mirror (the old smoke matchup)"},
]

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _game: Node = null
var _party: RefCounted = null
var _pilot: RefCounted = null

var _pilot_mode: String = "spacer"
var _results: Array = []
var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	_read_arguments()

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	if not _collect_nodes():
		_report()
		return

	# One creature to start with, so a body exists for the party sync to swap.
	if _director.call("ally_instance") == null:
		await _director.call("adopt_starter", str(ROWS[0]["ally"]))

	for row: Dictionary in ROWS:
		var result := await _fight_row(row)
		_results.append(result)
		_print_row(result)

	_report()


func _read_arguments() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--pilot="):
			_pilot_mode = argument.split("=")[1].strip_edges().to_lower()


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_game = root.get_node_or_null(^"Game")
	if _player == null or _rig == null or _manager == null or _director == null or _game == null:
		_failures.append("the playground is missing the player, rig, manager, director or Game")
		return false
	_party = _game.get("party") as RefCounted
	if _party == null:
		_failures.append("no party on the Game autoload")
		return false
	_pilot = PILOT.new(self, _manager, _director, _rig)
	_pilot.pilot = PILOT.Pilot.BRAWLER if _pilot_mode == "brawler" else PILOT.Pilot.SPACER
	_pilot.listen()
	return true


## One staged, non-mirror encounter, start to finish.
func _fight_row(row: Dictionary) -> Dictionary:
	var ally_species := str(row["ally"])
	var foe_species := str(row["foe"])
	var level := int(row["level"])

	await _leave_any_fight_still_running()
	await _stand_the_player_at_the_stage()
	_quiet_the_neighbours()
	await _give_the_player(ally_species, level)

	var ally: RefCounted = _director.call("ally_instance")
	if ally == null or str(ally.get("species_id")) != ally_species:
		return _abandoned(row, "could not put a %s in the player's hands (holding '%s')"
			% [ally_species, "nothing" if ally == null else str(ally.get("species_id"))])

	var spot := _player.global_position + Vector3(8.0, 0.0, 0.0)
	spot.y = float(_world.call("ground_height_at", spot.x, spot.z))
	var foe_body: Node3D = _director.call("spawn_wild", foe_species, spot, {
		"level": level, "wander_radius": 0.5, "name": "StagedFoe_%s" % foe_species,
	}) as Node3D
	if foe_body == null:
		return _abandoned(row, "spawn_wild('%s') produced nothing" % foe_species)
	for i in 20:
		await physics_frame

	# Walk there. Not a teleport: an opponent the trainer cannot reach is not an
	# encounter, and the walk is the part of the loop this probe shares with the
	# player.
	var engage_range := float(_combat_config().get("flow", {}).get("engage_range", 6.0))
	var walk_from := _player.global_position
	# The BODY, not its position: an aggressive species closes on the trainer
	# while the trainer is walking at it, and a snapshotted coordinate is a spot
	# it has already left.
	var closed: float = await _pilot.walk_trainer_to(
		_player, foe_body, engage_range * 0.6, 900)
	if closed > engage_range:
		_retire(foe_body)
		return _abandoned(row, "could not walk within engage range: %.1fm away after covering %.1fm from %s"
			% [closed, walk_from.distance_to(_player.global_position), str(walk_from)])

	# An aggressive opponent may already have opened the fight on the approach;
	# that is a legitimate way in (GAME_DESIGN §14) and does not need a press.
	if not bool(_manager.call("is_fighting")):
		await _engage()
	if not bool(_manager.call("is_fighting")):
		_retire(foe_body)
		return _abandoned(row, "the engage press did not open a fight")
	if _manager.call("enemy_body") != foe_body:
		var wrong: Node3D = _manager.call("enemy_body") as Node3D
		_failures.append("row %s vs %s engaged '%s' instead of the staged opponent"
			% [ally_species, foe_species, wrong.name if wrong != null else "<null>"])

	var foe: RefCounted = _manager.call("enemy")
	var foe_max_hp := float(foe.get("max_hp"))
	var ally_max_hp := float(ally.get("max_hp"))
	# The arrow the HUD is showing the player at the moment they commit, read
	# from the manager's own accessor -- the same number `combat_hud.gd` draws.
	var arrow: int = int(_manager.call("active_matchup"))

	_pilot.reset_tally()
	var outcome: Dictionary = await _pilot.fight_to_the_end()
	for i in 30:
		await physics_frame

	var record := {
		"ally": ally_species,
		"foe": foe_species,
		"level": level,
		"note": str(row["note"]),
		"outcome": str(outcome["outcome"]),
		"timed_out": bool(outcome["timed_out"]),
		"seconds": float(outcome["frames"]) / 60.0,
		"hits_dealt": _pilot.hits_dealt,
		"hits_taken": _pilot.hits_taken,
		"damage_dealt": _pilot.damage_dealt,
		"damage_taken": _pilot.damage_taken,
		"misses": _pilot.misses,
		"ally_hp_left": float(ally.get("hp")) / maxf(ally_max_hp, 1.0),
		"foe_max_hp": foe_max_hp,
		"ally_max_hp": ally_max_hp,
		"hud_arrow": arrow,
		"chart_arrow": _independent_arrow(ally, foe_species),
		"verdicts_on_enemy": _pilot.verdicts_on_enemy.duplicate(),
		"verdicts_on_ally": _pilot.verdicts_on_ally.duplicate(),
		"quick": _pilot.quick_thrown,
		"charged": _pilot.charged_thrown,
	}
	# Damage per landed hit is the number that decides whether the chart is
	# FELT. It is the thing a player can perceive without a HUD: how many swings
	# this took.
	record["damage_per_hit"] = _pilot.damage_dealt / maxf(float(_pilot.hits_dealt), 1.0)
	record["swings_to_kill"] = float(_pilot.hits_dealt)

	_retire(foe_body)
	for i in 30:
		await physics_frame
	return record


## The arrow computed here from the raw data, so the HUD is graded rather than
## trusted. Same shape as `tests/smoke_combat.gd`'s independent lookup.
func _independent_arrow(ally: RefCounted, foe_species: String) -> int:
	var definition: Dictionary = SPECIES.definition(foe_species)
	var moves: RefCounted = MOVE_DB.load_default()
	var quick := CHART.multiplier_dual(
		str(moves.call("type_of", str(ally.get("move_quick")))),
		str(definition.get("type", "")), str(definition.get("type_secondary", "")))
	var charged := CHART.multiplier_dual(
		str(moves.call("type_of", str(ally.get("move_charged")))),
		str(definition.get("type", "")), str(definition.get("type_secondary", "")))
	return CHART.classify(maxf(quick, charged))


func _abandoned(row: Dictionary, why: String) -> Dictionary:
	_failures.append("%s vs %s: %s" % [str(row["ally"]), str(row["foe"]), why])
	return {"ally": str(row["ally"]), "foe": str(row["foe"]), "abandoned": why}


## A row cannot be set up while a fight is running: `_sync_active_creature()`
## refuses to swap the deployed creature mid-fight, and rightly so. An aggressive
## species that opened a fight on the previous row's approach is the way this
## happens, so the previous fight is left through the real disengage button
## rather than by reaching into the manager.
func _leave_any_fight_still_running() -> void:
	if not bool(_manager.call("is_fighting")):
		return
	await _pilot.press("combat_run")
	for i in 180:
		await physics_frame
		if not bool(_manager.call("is_fighting")):
			break


func _stand_the_player_at_the_stage() -> void:
	var spot := STAGE
	spot.y = float(_world.call("ground_height_at", spot.x, spot.z)) + 1.0
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame


## Put every other wild creature near the stage to sleep for the row. They are
## not deleted — the meadow's own population is not this probe's to edit — only
## moved out of `_engageable()`'s reach, so the fight measured is the fight
## staged.
func _quiet_the_neighbours() -> void:
	for body: Variant in (_director.call("wild_creatures") as Array):
		var wild := body as Node3D
		if wild == null or not is_instance_valid(wild):
			continue
		if wild.global_position.distance_to(STAGE) > CLEAR_RADIUS:
			continue
		wild.global_position = wild.global_position + Vector3(0.0, 0.0, 120.0)
		wild.set("home", wild.global_position)


## Take a used opponent out of the staging area.
##
## MOVED, not freed. `encounter_director.gd` keeps its own respawn clock keyed
## on the body (`_faint_timers`), and freeing a body it is still counting down
## on floods `_tick_respawn` with invalid-instance errors every frame for the
## rest of the run. Its lifecycle is its own; this only needs the body out of
## `_engageable()`'s reach, which is exactly what `_quiet_the_neighbours` does
## to the meadow's own population.
func _retire(body: Node3D) -> void:
	if body == null or not is_instance_valid(body):
		return
	body.global_position = body.global_position + Vector3(0.0, 0.0, 200.0)
	body.set("home", body.global_position)


## Swap the player's active creature to `species` at `level`, through the party
## the way the party screen does it, and wait for the director to bring the new
## body out.
func _give_the_player(species: String, level: int) -> void:
	var cfg: Dictionary = PROGRESSION.config()
	var creature: RefCounted = _game.call("make_creature", species)
	if creature == null:
		return
	creature.call("set_level", level, cfg)
	creature.set("hp", float(creature.get("max_hp")))
	creature.set("energy", 0.0)

	_party.call("clear")
	_party.call("add", creature)
	_party.call("set_active", 0)
	# The director syncs on the party's revision counter in `_process`, so this
	# waits for the swap rather than assuming it.
	for i in 90:
		await physics_frame
		var out: RefCounted = _director.call("ally_instance")
		if out != null and str(out.get("species_id")) == species:
			break
	# Full health at the bell. Otherwise row N is fought on row N-1's leftovers
	# and the comparison this probe exists to make is meaningless.
	var ally: RefCounted = _director.call("ally_instance")
	if ally != null:
		ally.set("hp", float(ally.get("max_hp")))
		ally.set("energy", 0.0)
		ally.set("fainted", false)


func _engage() -> void:
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	for i in 30:
		await physics_frame


func _combat_config() -> Dictionary:
	return (load("res://scripts/combat/combat_math.gd") as GDScript).call("config")


func _print_row(record: Dictionary) -> void:
	if record.has("abandoned"):
		print("  %-12s vs %-12s  ABANDONED: %s" % [record["ally"], record["foe"], record["abandoned"]])
		return
	print("  %-11s vs %-11s L%-3d %-40s" % [
		record["ally"], record["foe"], record["level"], record["note"]])
	print("      outcome %-8s in %5.1fs   arrow HUD %+d / chart %+d" % [
		record["outcome"], record["seconds"], record["hud_arrow"], record["chart_arrow"]])
	print("      swings to kill %3d   damage/hit %5.1f   foe max hp %5.1f" % [
		int(record["swings_to_kill"]), record["damage_per_hit"], record["foe_max_hp"]])
	print("      took %3d hits for %5.1f damage; ally left at %4.1f%% hp" % [
		record["hits_taken"], record["damage_taken"], record["ally_hp_left"] * 100.0])
	print("      verdicts to the player: on foe %s, on ally %s" % [
		record["verdicts_on_enemy"], record["verdicts_on_ally"]])


func _report() -> void:
	print("")
	print("=== T3-COMBAT matchup probe (%s pilot) ===" % _pilot_mode)
	for record: Dictionary in _results:
		if record.has("abandoned"):
			continue
		print("ROW\t%s\t%s\t%d\t%s\t%.2f\t%d\t%.2f\t%d\t%.2f\t%d\t%d" % [
			record["ally"], record["foe"], record["level"], record["outcome"],
			record["seconds"], int(record["swings_to_kill"]), record["damage_per_hit"],
			record["hits_taken"], record["ally_hp_left"], record["hud_arrow"],
			record["chart_arrow"]])
	if not _failures.is_empty():
		for line in _failures:
			print("PROBLEM: %s" % line)
	quit(0)
