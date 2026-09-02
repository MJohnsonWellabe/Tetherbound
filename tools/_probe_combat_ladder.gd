extends SceneTree

## T3-COMBAT. Walk the whole authored trainer ladder, fighting every rung.
##
##   godot --headless --path . --script tools/_probe_combat_ladder.gd
##   godot --headless --path . --script tools/_probe_combat_ladder.gd -- --team=mixed
##   godot --headless --path . --script tools/_probe_combat_ladder.gd -- --pilot=brawler
##   godot --headless --path . --script tools/_probe_combat_ladder.gd -- --switching
##
## `docs/acceptance/MEADOWS_EXIT_CRITERION.md` §G5 asks that major fights test different
## aspects of the five, and §I1 that combat be readable and responsive. Neither
## is answerable from `trainers.json`. What a rung IS — trivial, fair, a wall —
## is a property of the fight, and the fight has a real-time piloted opponent in
## it whose telegraph, recovery and reposition decide as much as its level does.
##
## So this fights all 29 authored rungs in route order, through
## `encounter_director.begin_trainer_battle()` — the same call
## `trainer_npc.gd::_on_challenged` makes when the player accepts a challenge —
## piloted by `tools/combat_pilot.gd` through real input actions.
##
## THE PLAYER IT BRINGS is not invented. `data/config/chapter_curve.json` states,
## per region, the level and party size the chapter expects the player to arrive
## with (measured, per its own header, by `tools/_probe_pacing.py` against the
## shipped xp curve). Each rung is fought at the level that curve puts the player
## at when they reach it, interpolated across the band's own rungs, with the
## party size the curve names. A rung that is a wall at its own curve level is a
## wall in the shipping game.
##
## TWO TEAMS, because the chapter's own ladder is overwhelmingly Ground and the
## interesting question is whether that matters:
##
##   `ground` — terrapup, bramblebun, mudsnout, trailpup, meadowhart. What a
##              player who catches whatever is in front of them ends up with.
##   `mixed`  — terrapup, ripplet, galewisp, mosshell, duskhush. Ground, Water,
##              Air, Water, Air: a player who prepared.
##
## Every rung is fought at FULL HEALTH. That is the assumption most generous to
## the player — they rested before the fight — so a rung this probe calls hard
## is harder than that in play, never easier.
##
## What this does NOT model: the walk to the trainer, the conversation, the
## stronghold's own room geometry (a trainer battle staged in the playground
## fights on flat ground with `combat.json`'s full arena radius, where the
## stronghold shrinks it). Those are `tests/smoke_stronghold.gd`'s and Gate F's.
## What it models is the fight.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const PILOT := preload("res://tools/combat_pilot.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const CURVE_PATH := "res://data/config/chapter_curve.json"

const SETTLE_FRAMES := 240
## A trainer battle runs several fights back to back with a send-out beat
## between them. This bounds the whole battle, not one round.
const BATTLE_FRAME_LIMIT := 30000

## Somewhere flat with room, away from the authored clusters. Trainer creatures
## are sent out in front of the player (`_send_out_spot` with no trainer body),
## so this is where every rung is fought.
const STAGE := Vector3(48.0, 0.0, -58.0)

## The ladder, in the order a player meets it. `band` keys into
## `chapter_curve.json`; `step` is this rung's position through that band's own
## enter->exit level span, so the player levels up across a region rather than
## fighting its last trainer at its first level.
const LADDER: Array = [
	{"id": "practice_trainer", "band": 0, "step": 0.0, "kind": "local"},
	{"id": "trainer_mira", "band": 0, "step": 0.15, "kind": "local"},
	{"id": "trainer_tam", "band": 0, "step": 0.3, "kind": "local"},
	{"id": "trainer_oskar", "band": 0, "step": 0.45, "kind": "local"},
	{"id": "old_champion_bram", "band": 0, "step": 0.55, "kind": "optional"},
	{"id": "tournament_quarter_mira", "band": 0, "step": 0.7, "kind": "tournament"},
	{"id": "tournament_semi_tam", "band": 0, "step": 0.8, "kind": "tournament"},
	{"id": "tournament_final_oskar", "band": 0, "step": 0.9, "kind": "tournament"},
	{"id": "south_bridge_grunt", "band": 0, "step": 1.0, "kind": "tether"},

	{"id": "quarry_picket_dorn", "band": 1, "step": 0.0, "kind": "tether"},
	{"id": "warrens_watch_pell", "band": 1, "step": 0.35, "kind": "tether"},
	{"id": "band2_outrider_kest", "band": 1, "step": 0.7, "kind": "tether"},
	{"id": "night_watch_farro", "band": 1, "step": 1.0, "kind": "route"},

	{"id": "relay_picket_hess", "band": 2, "step": 0.0, "kind": "tether"},
	{"id": "relay_picket_orrin", "band": 2, "step": 0.2, "kind": "tether"},
	{"id": "relay_officer_dell", "band": 2, "step": 0.5, "kind": "officer"},
	{"id": "relay_captain", "band": 2, "step": 0.75, "kind": "officer"},
	{"id": "captain_riverwatch", "band": 2, "step": 1.0, "kind": "captain"},

	{"id": "pasture_drover_juno", "band": 3, "step": 0.0, "kind": "route"},
	{"id": "patrol_ridgeline", "band": 3, "step": 0.2, "kind": "tether"},
	{"id": "lost_creature_rue", "band": 3, "step": 0.4, "kind": "route"},
	{"id": "captain_field", "band": 3, "step": 0.75, "kind": "captain"},
	{"id": "captain_ridge", "band": 3, "step": 1.0, "kind": "captain"},

	{"id": "stronghold_outer_watch", "band": 4, "step": 0.0, "kind": "tether"},
	{"id": "stronghold_patrol", "band": 4, "step": 0.2, "kind": "tether"},
	{"id": "stronghold_checkpoint", "band": 4, "step": 0.4, "kind": "tether"},
	{"id": "stronghold_courtyard", "band": 4, "step": 0.6, "kind": "tether"},
	{"id": "stronghold_elite", "band": 4, "step": 0.8, "kind": "officer"},
	{"id": "warden_aldis", "band": 4, "step": 1.0, "kind": "warden"},
]

const TEAMS: Dictionary = {
	"ground": ["terrapup", "bramblebun", "mudsnout", "trailpup", "meadowhart"],
	"mixed": ["terrapup", "ripplet", "galewisp", "mosshell", "duskhush"],
}

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _game: Node = null
var _party: RefCounted = null
var _progression: RefCounted = null
var _pilot: RefCounted = null

var _team_name: String = "ground"
var _pilot_mode: String = "spacer"
var _switching: bool = false
var _only: String = ""

## T3-COMBAT drift check: where the previous round of the current battle opened.
var _last_round_spot: Vector3 = Vector3.ZERO

var _curve: Array = []
var _results: Array = []
var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	_read_arguments()
	_curve = _load_curve()
	if _curve.is_empty():
		print("PROBE FAIL: chapter_curve.json has no regions; cannot decide what the player brings")
		quit(1)
		return

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	if not _collect_nodes():
		quit(1)
		return

	await _stand_at_the_stage()
	if _director.call("ally_instance") == null:
		await _director.call("adopt_starter", str(TEAMS[_team_name][0]))

	for rung: Dictionary in LADDER:
		if _only != "" and str(rung["id"]) != _only:
			continue
		var record := await _fight_rung(rung)
		_results.append(record)
		_print_rung(record)

	_report()


func _read_arguments() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--team="):
			_team_name = argument.split("=")[1].strip_edges().to_lower()
		elif argument.begins_with("--pilot="):
			_pilot_mode = argument.split("=")[1].strip_edges().to_lower()
		elif argument.begins_with("--only="):
			_only = argument.split("=")[1].strip_edges()
		elif argument == "--switching":
			_switching = true
	if not TEAMS.has(_team_name):
		_team_name = "ground"


func _load_curve() -> Array:
	var file := FileAccess.open(CURVE_PATH, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var regions: Variant = (parsed as Dictionary).get("regions", [])
	return regions as Array if regions is Array else []


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
	_pilot.pilot = PILOT.Pilot.BRAWLER if _pilot_mode == "brawler" else PILOT.Pilot.SPACER
	_pilot.use_switching = _switching
	_pilot.listen()
	return true


func _stand_at_the_stage() -> void:
	var spot := STAGE
	spot.y = float(_world.call("ground_height_at", spot.x, spot.z)) + 1.0
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame


## One authored rung, fought to its end.
func _fight_rung(rung: Dictionary) -> Dictionary:
	var id := str(rung["id"])
	var spec: Dictionary = TRAINERS.trainer(id)
	if spec.is_empty():
		_failures.append("no trainer '%s' in the band files" % id)
		return {"id": id, "abandoned": "no such trainer"}

	var region: Dictionary = _curve[mini(int(rung["band"]), _curve.size() - 1)] as Dictionary
	var team_block: Dictionary = region.get("team", {}) as Dictionary
	var enter := int(team_block.get("enter", 5))
	var exit_level := int(team_block.get("exit", enter))
	var level := int(round(lerpf(float(enter), float(exit_level), float(rung["step"]))))
	var members := int(team_block.get("expected_members", 5))

	_build_the_party(level, members)
	await _wait_for_the_body(str(TEAMS[_team_name][0]))
	_clear_the_defeat_flag(spec)

	var opposing: Array = TRAINERS.team_of(spec)
	var top_level := 0
	for entry: Variant in opposing:
		top_level = maxi(top_level, int((entry as Dictionary).get("level", 1)))

	# Back to the same patch of ground for every rung.
	#
	# `combat_manager.gd::_stand_the_trainer_aside()` moves the trainer at the
	# start of every fight, so across a 29-rung ladder they drift — and the
	# trainer's position is where `_send_out_spot()` puts the opposing creature.
	# Six rungs in, an un-restaged run produced a round with 0 hits in either
	# direction over the full two-minute limit: the two creatures had been placed
	# somewhere they never met. Re-standing is staging, not play, and it keeps
	# every rung measured on the ground the first one was.
	await _stand_at_the_stage()

	var in_hand: RefCounted = _director.call("ally_instance")
	print("  %-24s player L%d x%d, leading with %s" % [
		id, level, int(_party.call("size")),
		"nothing" if in_hand == null else str(in_hand.get("species_id"))])

	_pilot.reset_tally()
	if not bool(_director.call("begin_trainer_battle", spec, null)):
		_failures.append("'%s' refused the challenge" % id)
		return {"id": id, "abandoned": "challenge refused"}

	var frames := 0
	var rounds := 0
	while bool(_director.call("trainer_battle_active")) and frames < BATTLE_FRAME_LIMIT:
		if bool(_manager.call("is_fighting")):
			var foe: RefCounted = _manager.call("enemy")
			var foe_name := str(foe.get("species_id")) if foe != null else "?"
			# T3-COMBAT drift check. `combat_manager._place_fighters()` anchors
			# both fighters off the trainer and `_stand_the_trainer_aside()`
			# then moves the trainer, so without an anchor every round re-forms
			# from the last one's end and the whole fight walks. In the open
			# meadow that is only untidy; inside the Warden Arena it is what put
			# his creatures under the floor (T2-FLAKE §5). Measured here per
			# round, so the fix can be shown to zero it.
			var here := _player.global_position
			var moved := 0.0 if rounds == 0 else here.distance_to(_last_round_spot)
			print("      [drift] round %d opens with the trainer at %.1f, %.1f — %.2fm from where round %d opened" % [
				rounds + 1, here.x, here.z, moved, rounds])
			_last_round_spot = here
			var round_result: Dictionary = await _pilot.fight_to_the_end()
			frames += int(round_result["frames"])
			rounds += 1
			print("      round %d vs %s: %s after %.1fs%s" % [
				rounds, foe_name, str(round_result["outcome"]),
				float(round_result["frames"]) / 60.0,
				"  (HIT THE FRAME LIMIT, %.1fm apart)" % float(round_result["final_gap"])
					if bool(round_result["timed_out"]) else ""])
			if bool(round_result["timed_out"]):
				break
		else:
			await physics_frame
			frames += 1
	Input.action_release("move_forward")

	# A round that ran out of frames leaves the battle OPEN, and
	# `can_challenge()` refuses every later trainer while one is running — so an
	# unfinished rung used to abandon all 23 rungs behind it. Disengaged through
	# the real button rather than by reaching into the director.
	await _leave_any_battle_still_running()

	for i in 40:
		await physics_frame
	var won := _defeat_flag_set(spec)

	var hp_left := 0.0
	var faints := 0
	var size := int(_party.call("size"))
	for i in size:
		var creature: RefCounted = _party.call("at", i)
		if creature == null:
			continue
		hp_left += float(creature.get("hp")) / maxf(float(creature.get("max_hp")), 1.0)
		if bool(creature.get("fainted")):
			faints += 1

	return {
		"id": id,
		"kind": str(rung["kind"]),
		"band": int(rung["band"]) + 1,
		"player_level": level,
		"party_size": size,
		"foes": opposing.size(),
		"foe_top_level": top_level,
		"won": won,
		"rounds_fought": rounds,
		"foes_felled": rounds if won else maxi(rounds - 1, 0),
		"seconds": float(frames) / 60.0,
		"party_hp_left": hp_left / maxf(float(size), 1.0),
		"faints": faints,
		"hits_dealt": _pilot.hits_dealt,
		"hits_taken": _pilot.hits_taken,
		"damage_dealt": _pilot.damage_dealt,
		"damage_taken": _pilot.damage_taken,
		"misses": _pilot.misses,
		"switches": _pilot.switches,
		"verdicts_on_enemy": _pilot.verdicts_on_enemy.duplicate(),
		"verdicts_on_ally": _pilot.verdicts_on_ally.duplicate(),
	}


## The five (or three, or four) the curve says the player has here, at full
## health, through `Game.party` — the same store the party screen writes.
## `combat_run` is the disengage a player has (`combat_manager::_flee_pressed`),
## and running from a round is one of the ways a trainer battle ends — so this
## is the same exit the player would take, not a reach into the director.
func _leave_any_battle_still_running() -> void:
	for attempt in 4:
		if not bool(_director.call("trainer_battle_active")) \
				and not bool(_manager.call("is_fighting")):
			return
		if bool(_manager.call("is_fighting")):
			await _pilot.press("combat_run")
		for i in 120:
			await physics_frame
			if not bool(_director.call("trainer_battle_active")):
				return


func _build_the_party(level: int, members: int) -> void:
	var cfg: Dictionary = PROGRESSION.config()
	var recipe: Array = TEAMS[_team_name]
	_party.call("clear")
	for i in mini(members, recipe.size()):
		var creature: RefCounted = _game.call("make_creature", str(recipe[i]))
		if creature == null:
			continue
		creature.call("set_level", level, cfg)
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


## A beaten trainer greets you instead of fighting you, so the flag has to come
## off before a rung can be fought again — for a second team, or a second pilot.
func _clear_the_defeat_flag(spec: Dictionary) -> void:
	if _progression == null:
		return
	# `progression_state.set_flag(id, false)` is the store's own documented way
	# to clear one back out, so this is not reaching past its interface.
	var flag := str(spec.get("defeat_flag", ""))
	if flag != "":
		_progression.call("set_flag", flag, false)


func _defeat_flag_set(spec: Dictionary) -> bool:
	if _progression == null:
		return false
	var flag := str(spec.get("defeat_flag", ""))
	return flag != "" and bool(_progression.call("has", flag))


func _print_rung(record: Dictionary) -> void:
	if record.has("abandoned"):
		print("  %-24s ABANDONED: %s" % [record["id"], record["abandoned"]])
		return
	print("  b%d %-24s %-10s player L%-2d x%d  vs %d creatures to L%-2d  %s" % [
		record["band"], record["id"], record["kind"], record["player_level"],
		record["party_size"], record["foes"], record["foe_top_level"],
		"WON" if record["won"] else "LOST"])
	print("        %5.1fs  felled %d/%d  party hp left %5.1f%%  faints %d  switches %d" % [
		record["seconds"], record["foes_felled"], record["foes"],
		record["party_hp_left"] * 100.0, record["faints"], record["switches"]])
	print("        hits %d dealt / %d taken, %d missed;  verdicts on foe %s, on you %s" % [
		record["hits_dealt"], record["hits_taken"], record["misses"],
		record["verdicts_on_enemy"], record["verdicts_on_ally"]])


func _report() -> void:
	print("")
	print("=== T3-COMBAT ladder: team=%s pilot=%s switching=%s ===" % [
		_team_name, _pilot_mode, _switching])
	print("TSV\tid\tkind\tband\tplayerL\tparty\tfoes\tfoeL\twon\tfelled\tseconds\thp_left\tfaints\thits\ttaken\tmissed\tswitches")
	for record: Dictionary in _results:
		if record.has("abandoned"):
			continue
		print("TSV\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\t%.1f\t%.3f\t%d\t%d\t%d\t%d\t%d" % [
			record["id"], record["kind"], record["band"], record["player_level"],
			record["party_size"], record["foes"], record["foe_top_level"],
			"1" if record["won"] else "0", record["foes_felled"], record["seconds"],
			record["party_hp_left"], record["faints"], record["hits_dealt"],
			record["hits_taken"], record["misses"], record["switches"]])
	for line in _failures:
		print("PROBLEM: %s" % line)
	quit(0)
