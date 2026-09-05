extends SceneTree

## GATE-E — the chapter's finale, walked end to end in one boot.
##
##   godot --headless --path . --script tests/smoke_gate_e_finale.gd
##
## Two files already cover halves of this and neither covers the join between
## them, which is where a finale actually fails:
##
##   * `smoke_stronghold.gd` proves the ROUTE — five spaces, floors, doorways,
##     a shutter, three trainers placed and challengeable. It fights nobody,
##     and says so.
##   * `smoke_boss.gd` picks up AT the Warden: it teleports the player in front
##     of him with a level-1 starter and drives the ending from there. It never
##     walks in, never fights the gauntlet, never touches the recovery point,
##     and never leaves the stronghold afterwards.
##
## So the thing prompt 69 actually asks for — "start at Hall entry with a
## realistic fresh-run team and play continuously through post-win
## acknowledgment" — was covered nowhere, and every seam between those two
## files was untested. This is that run, in order, in one world:
##
##   arrive at the Hall with a FULL five -> walk in from the entrance ->
##   patrol fight -> walk to the courtyard -> courtyard fight -> walk to the
##   Tether Approach -> rest a fainted creature at the recovery point ->
##   elite fight -> the shutter lifts -> read the reveal -> the Warden ->
##   pull the lever -> the legendary is freed and offers to join -> the belt is
##   full, so R4.10's release ceremony takes the decision -> the roster
##   decision is RECORDED -> the region answers -> a post-victory villager
##   acknowledges it and the chapter's objective chain terminates.
##
## The team is five creatures at finale levels, which is the other half of what
## the two existing files do not do: `smoke_boss.gd`'s one level-1 starter can
## never reach the five-creature decision, and the five-creature decision is
## the chapter's whole point (CLAUDE.md's hard cap, prompts 46/67).
##
## Fights are driven through the ordinary prompt -> conversation ->
## `encounter_director.begin_trainer_battle()` path and won with the same
## allowance `smoke_boss.gd` and `smoke_trainer_battle.gd` both make — the
## player's creature is topped up and the opponent's HP pulled low, because
## this test is about the finale's WIRING and not about its balance. Every
## faint, send-out, defeat flag and payout still goes through production code.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")

const SETTLE_FRAMES := 300
## Per fight, not for the whole run. Same reasoning as smoke_boss's budget:
## a director that never resolves has to fail with a diagnosis instead of
## hanging CI.
const BATTLE_FRAME_LIMIT := 9000
## See smoke_boss.gd's CONSECUTIVE_MISS_LIMIT — a real whiff and a stalled
## fight look identical from a frame budget alone, so they are separated here
## the same way.
const CONSECUTIVE_MISS_LIMIT := 25
## Loop iterations with NO progress of any kind before the fight is declared
## stalled and reported with its state (prompt 34). Generously above the
## longest legitimate quiet stretch in a fight — the 1.6s send-out beat between
## a trainer's creatures is ~96 physics frames, and that beat counts as
## progress anyway because the fight state changes across it.
const STALL_FRAMES := 900
## How far below its room's floor a fighter may be before the fight is being
## held somewhere the room is not. Generous: the floor marker is the slab's
## top and a body's origin sits at its feet, so a legitimate difference is
## centimetres. The failure this catches was seven metres.
const ROOM_FLOOR_TOLERANCE_M := 2.5
## How often the both-fighters-in-the-room check is repeated inside a fight.
## Cheap (two vector reads), and often enough that a body which falls out of the
## room is named as that rather than reported later as a mysterious stall.
const FLOOR_CHECK_EVERY := 300
## Physics frames one walk between two marks gets. The longest leg on the route
## is 32m centre to centre at 4 m/s.
const WALK_FRAMES := 700
## Frames the climax's stage machine gets to walk its own order.
const SEQUENCE_FRAMES := 900
## Frames spent resting at the recovery point. The bed heals over
## `progression.json`'s `creature_bed.full_heal_seconds` (120s), so this is
## deliberately a PARTIAL rest: what is under test is that the bed accepts a
## creature and really recovers it, not that a smoke test can sit still for two
## game-minutes.
const REST_FRAMES := 600

## The gauntlet, in the order the player meets it, with the room each fight
## stands in. Hard-coded here on purpose for the same reason smoke_stronghold
## hard-codes the route: a test that read the order out of the config the
## builder reads could not catch the order changing.
const GAUNTLET := [
	{"trainer": "stronghold_patrol", "room": "outer_works", "flag": "defeated_stronghold_patrol"},
	{"trainer": "stronghold_courtyard", "room": "courtyard", "flag": "defeated_stronghold_courtyard"},
	{"trainer": "stronghold_elite", "room": "tether_approach", "flag": "defeated_stronghold_elite"},
]
const WARDEN_ID := "warden_aldis"
const ELITE_FLAG := "defeated_stronghold_elite"
const WARDEN_FLAG := "defeated_warden"
const FREED_FLAG := "legendary_freed"
const SETTLED_FLAG := "legendary_settled"
const ACKNOWLEDGED_FLAG := "meadows_acknowledged"
const REVEAL_FLAG := "learned_legendary_is_the_source"
## What a player arriving at Meadows Hall has already done. Set directly: this
## file covers the FINALE segment, and re-playing the preceding three hours to
## reach it would be a different (and much slower) test.
const ARRIVED_AT_THE_HALL := [
	# T3-COMBAT: the three opening beats BEFORE the first catch. T5-STORY-2 added
	# `opening_hear_grandpa`, `opening_take_starter` and `opening_show_grandpa`
	# to the head of `data/progression/objectives.json`'s `main` chain, and this
	# list was written against the chain as it stood before them. That is the
	# exact failure the comment below already describes, one rung earlier: with
	# them unset, `tracked_text()` returned "Go down and hear Grandpa out." at
	# the climax, `_run()` bailed at its `_failures.is_empty()` guard straight
	# after `_bring_a_full_five_to_the_hall()`, and **the finale never reached
	# the Warden at all** on any branch carrying that story work. Taken from the
	# data rather than guessed: these are rungs 0-2's own `flag_id` values.
	"opening:beat:choose", "opening:beat:return_starter", "opening:beat:walk_out",
	"opening:beat:road", "road_gate_open",
	# TUTORIAL-CHAIN (OP23-04) added two rungs to the opening ladder and made
	# the bed rung a count of three (owner directives 2026-08-23 sections 1
	# and 2). A player standing in front of Meadows Hall has walked all of
	# them -- they took Tam's tools, they slept their team in three beds and
	# they fed them before signing up -- so this list carries them.
	#
	# Not optional bookkeeping: `quest_log.gd::tracked_text()` reports the
	# FIRST unset rung, so one missing flag here puts the village back on the
	# HUD at the climax. That is exactly how this was caught -- CI run
	# 32653572764 failed with "the tracked objective on arrival at Meadows
	# Hall is 'Meet Tam in the village and take his tools.'"
	"tam_tools_given",
	"tournament_team_ready",
	"tournament_training_ready", "home_materials_gathered", "home_built",
	"creature_bed_built", "creature_bed_built_2", "creature_bed_built_3",
	"player_slept_at_home", "tournament_team_fed", "tournament_entered",
	"tournament_won", "south_bridge_open", "warrens_cleared",
	"relay_captain_defeated", "captive_rescued", "relay_disabled",
	"mill_crossing_restored", "defeated_captain_field", "defeated_captain_ridge",
	"defeated_captain_riverwatch", "hall_approach_open",
]
## The five the player brings in. Species that exist in species.json, at levels
## the chapter curve puts a prepared team at by the Hall.
const FINALE_TEAM := [
	{"species": "terrapup", "name": "Bracket", "level": 20},
	{"species": "mudsnout", "name": "Trowel", "level": 19},
	{"species": "bramblebun", "name": "Hedge", "level": 18},
	{"species": "terrapup", "name": "Second", "level": 18},
	{"species": "mudsnout", "name": "Kettle", "level": 17},
]

var _failures: Array[String] = []
var _world: Node = null
var _game: Node = null
var _player: CharacterBody3D = null
var _manager: Node = null
var _director: Node = null
var _panel: Node = null
var _hold: Node3D = null
var _climax: Node = null
var _menu: CanvasLayer = null
var _party: RefCounted = null
var _tab: Node = null

var _quick_hits := 0
var _quick_misses := 0
var _consecutive_misses := 0
var _freed_writes := 0


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame

	if not _collect_nodes():
		_report()
		return
	await _bring_a_full_five_to_the_hall()
	if not _failures.is_empty():
		_report()
		return

	await _walk_in_from_the_entrance()
	await _fight_the_gauntlet()
	await _the_shutter_lifted_behind_the_elite()
	await _read_the_reveal_before_he_speaks()
	await _fight_the_warden()
	await _pull_the_lever()
	await _the_full_belt_takes_the_decision()
	_the_decision_is_recorded()
	await _the_region_answers()
	await _the_meadows_acknowledges_it()
	_report()


func _collect_nodes() -> bool:
	_game = root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_panel = _world.get_node_or_null(^"DialoguePanel")
	_hold = _world.get_node_or_null(^"Stronghold") as Node3D
	_climax = _world.get_node_or_null(^"StrongholdClimax")
	if _game == null or _player == null or _manager == null or _director == null or _panel == null:
		_fail("the scene is missing the Game autoload, the player, the manager, the director or the panel")
		return false
	if _hold == null:
		_fail("the world built no Stronghold; there is no finale to walk")
		return false
	if _climax == null:
		_fail("the world built no StrongholdClimax; the chapter has no ending")
		return false
	_menu = _game.call("menu")
	_party = _game.get("party")
	if _menu == null or _party == null:
		_fail("the Game autoload has no menu or no party")
		return false
	for i in (_menu.get("_tabs") as Array).size():
		if str(((_menu.get("_tabs") as Array)[i] as Dictionary).get("id", "")) == "creatures":
			_tab = (_menu.get("_bodies") as Array)[i]
	if _tab == null:
		_fail("no creatures tab is registered; the release ceremony has nowhere to happen")
		return false
	return true


## Prompt 67's premise, made real before anything is fought: five creatures the
## player would have reasons to keep. Without a FULL belt the finale's central
## decision cannot happen at all, and `smoke_boss.gd`'s single starter is why
## nothing until now walked that path continuously.
func _bring_a_full_five_to_the_hall() -> void:
	var progression := _progression()
	for flag: String in ARRIVED_AT_THE_HALL:
		progression.call("set_flag", flag)

	# The active companion goes through the director, exactly as the opening
	# hands the player their starter.
	if _director.call("ally_instance") == null:
		await _director.call("adopt_starter", str(FINALE_TEAM[0]["species"]))
	for i in int(_party.call("size")):
		var starter: RefCounted = _party.call("at", i)
		if starter != null:
			starter.set("nickname", str(FINALE_TEAM[0]["name"]))
	for spec: Dictionary in FINALE_TEAM:
		if bool(_party.call("is_full")):
			break
		var creature: RefCounted = _game.call("make_creature", str(spec["species"]), str(spec["name"]))
		if creature == null:
			_fail("could not build '%s' from species.json" % str(spec["species"]))
			return
		_party.call("add", creature)
	# Levels, so the fights below are the chapter's fights and not a level-1
	# starter's. Set on the instance the same way `creature_for` levels a
	# trainer's own creature.
	var cfg := _progression_config()
	for i in int(_party.call("size")):
		var creature: RefCounted = _party.call("at", i)
		if creature == null:
			continue
		var level := int(FINALE_TEAM[mini(i, FINALE_TEAM.size() - 1)]["level"])
		if creature.has_method("set_level"):
			creature.call("set_level", level, cfg)
		else:
			creature.set("level", level)
		creature.set("hp", float(creature.get("max_hp")))

	if not bool(_party.call("is_full")):
		_fail("the finale team is %d, not the five the decision needs" % int(_party.call("size")))
		return
	print("arrived at the Hall with %d creatures" % int(_party.call("size")))
	var line := str(_quest_line())
	if not line.to_lower().contains("hall"):
		_fail("the tracked objective on arrival at Meadows Hall is '%s'" % line)
	else:
		print("tracked objective on arrival: '%s'" % line)


## SG38's way in: a real walk from the entrance up the ramp into the Outer
## Works, not a teleport into the first room.
func _walk_in_from_the_entrance() -> void:
	var entrance: Vector3 = _hold.call("marker", "entrance")
	var first: Vector3 = _hold.call("marker", "outer_works")
	await _put_down(entrance + Vector3(0.0, 1.5, 0.0))
	# 1400 frames, not the default 700: at this walker's 4 m/s that is 93 m
	# against a 53.2 m causeway, so the budget is no longer what decides the
	# result. See `_walk_toward`'s own note.
	await _walk_toward(first, 4.0, 1400)
	var short := _player.global_position.distance_to(first)
	# 6 m, not 14. GATE-F-LEG-S10AB, 2026-08-31: the Outer Works is 24 m deep,
	# and its mouth wall sits 13.2 m from the chamber's own centre -- so a
	# 14 m tolerance passes a player who never got through the doorway at all.
	# That is not hypothetical. The approach ramp reached floor height one wall
	# thickness too far in, leaving a 0.34 m riser across the mouth, and S10a's
	# own walk measured the player pinned at 13.6 m from this same point,
	# oscillating along the outside of the wall for about a hundred seconds of
	# play. 13.6 is inside 14.0, so this check passed the entire time the front
	# door was effectively shut. 6 m is comfortably inside the room and still
	# leaves the walker its own slack.
	if short > 6.0:
		_fail("walking in from the entrance never reached the Outer Works (%.1fm short)" % short)
	else:
		print("walked in from the entrance; %.1fm from the Outer Works' centre" % short)


## The three fights, in the three rooms, with the recovery opportunity between
## the second and the last — which is where §8 puts it, and the whole reason it
## is there is that a player should reach the elite able to fight.
func _fight_the_gauntlet() -> void:
	for step: Dictionary in GAUNTLET:
		var room: String = str(step["room"])
		var id: String = str(step["trainer"])
		await _walk_toward(_hold.call("marker", room) as Vector3, 3.0)
		if id == "stronghold_elite":
			await _rest_at_the_recovery_point()
		var body := _gauntlet_body(id)
		if body == null:
			_fail("gauntlet trainer '%s' is not standing in the world" % id)
			return
		await _walk_toward(body.global_position, 3.0)
		await _challenge_and_win(id, body, room)
		if not bool(_progression().call("has", str(step["flag"]))):
			_fail("'%s' was fought but '%s' was never set" % [id, str(step["flag"])])
			return
		print("  beat %s; tracked objective now '%s'" % [id, _quest_line()])
	var line := str(_quest_line())
	if not line.to_lower().contains("warden"):
		_fail("with the gauntlet down the tracked objective is '%s', not the Warden" % line)


## SG38's recovery opportunity, driven the way a player drives it: a creature is
## down, the bed's own prompt is used, and the bed really brings it back.
##
## GATE-E found this broken on `main` and it is the reason this assertion is
## here rather than in a data test — the authored bed carried no build index at
## all, so `assign_creature()` refused every creature and the chapter's one
## pre-Warden rest opened a panel that could do nothing.
func _rest_at_the_recovery_point() -> void:
	var bed: Node3D = _hold.call("recovery_point")
	if bed == null:
		_fail("there is no recovery point before the elite")
		return
	await _walk_toward(bed.global_position, 3.0)
	var prompt := bed.get_node_or_null(^"Interactable")
	if prompt == null:
		_fail("the recovery point offers no prompt; it cannot be used")
		return

	# Knock the last one on the belt out, the way the courtyard fight might
	# have.
	var index := int(_party.call("size")) - 1
	var creature: RefCounted = _party.call("at", index)
	if creature == null:
		_fail("no creature to rest")
		return
	creature.set("hp", 0.0)
	creature.set("fainted", true)

	prompt.call("interaction_activate")
	for i in 20:
		await process_frame
	var rest_panel := _rest_panel()
	if rest_panel == null or not bool(rest_panel.call("is_open")):
		_fail("using the recovery point opened no rest panel")
		return
	# Close it before resting. The panel pauses the tree while it is up, and
	# `game_state.gd::_tick_creature_bed_recovery` is what actually heals -- an
	# earlier version of this test left the panel open and measured 600 frames
	# of exactly nothing, which is also what a player staring at the panel gets.
	await _press("menu_cancel")
	for i in 10:
		await process_frame
	if bool(rest_panel.call("is_open")):
		_fail("the rest panel could not be closed by the cancel button")
		return
	if not bool(bed.call("assign_creature", index)):
		_fail("the recovery point refused to take a fainted creature; the rest before the elite does nothing")
		return
	for i in REST_FRAMES:
		await physics_frame
	var hp := float(creature.get("hp"))
	if hp <= 0.0 or bool(creature.get("fainted")):
		_fail("%.0f frames in the recovery bed left the creature at %.1f hp, fainted=%s"
			% [REST_FRAMES, hp, str(creature.get("fainted"))])
		return
	if not bool(bed.call("is_occupied")):
		_fail("the bed is not showing the creature as resting in it")
	# Take them back before the elite: an occupied bed keeps the creature
	# unavailable, which is the cost the rest is meant to have.
	bed.call("wake_creature_early")
	for i in 10:
		await physics_frame
	print("  rested a fainted creature at the recovery point: %.1f/%.0f hp back"
		% [hp, float(creature.get("max_hp"))])


## R8.2's shutter, checked from the player's side rather than from the flag's:
## the elite has fallen, so the way to the Warden is open now and was not
## before. `smoke_stronghold.gd` proves the shut half by walking at it; this
## proves the open half arrived through a fight rather than through a set_flag.
func _the_shutter_lifted_behind_the_elite() -> void:
	if not bool(_progression().call("has", ELITE_FLAG)):
		_fail("the elite's flag is not set; the shutter question is meaningless")
		return
	for i in 12:
		await physics_frame
	if not bool(_hold.call("door_is_open", ELITE_FLAG)):
		_fail("the elite fell and the Warden Arena's shutter is still down")
	else:
		print("the shutter lifted once the elite fell")


## SG40, in its authored place: the reveal is read on the threshold, BEFORE the
## Warden speaks. §28's order, and the readout is the environmental half of it.
func _read_the_reveal_before_he_speaks() -> void:
	var readout := _world.find_child("TetherReadout", true, false) as Node3D
	if readout == null:
		_fail("no Tether readout in the world; the reveal has nothing to be read from")
		return
	if bool(_progression().call("has", WARDEN_FLAG)):
		_fail("the Warden is already beaten; the reveal is being read out of order")
	await _walk_toward(readout.global_position, 3.0)
	var prompt := readout.get_node_or_null(^"ReadoutPrompt")
	if prompt == null or not bool(prompt.get("enabled")):
		_fail("the readout offers no live prompt; the reveal is unreachable")
		return
	prompt.call("interaction_activate")
	for i in 30:
		await process_frame
		if bool(_panel.call("is_open")):
			break
	if not bool(_panel.call("is_open")):
		_fail("reading the readout opened no conversation")
		return
	for i in 200:
		if not bool(_panel.call("is_open")):
			break
		await _press("interact")
	if bool(_panel.call("is_open")):
		_fail("the reveal conversation never closed")
		return
	if not bool(_progression().call("has", REVEAL_FLAG)):
		_fail("the reveal was read and '%s' was never set" % REVEAL_FLAG)
	else:
		print("read the reveal on the threshold, before the Warden")


func _fight_the_warden() -> void:
	var body: Node3D = _climax.call("warden_body") as Node3D
	if body == null:
		_fail("the Warden was never stood up in the world")
		return
	await _walk_toward(body.global_position, 3.0)
	await _challenge_and_win(WARDEN_ID, body, "warden_arena")
	if not bool(_progression().call("has", WARDEN_FLAG)):
		_fail("the Warden fight ended and '%s' was never set" % WARDEN_FLAG)
		return
	if bool(_director.call("can_challenge", TRAINERS.trainer(WARDEN_ID))):
		_fail("the Warden can be fought again; the chapter's last fight is farmable")
	print("beat the Warden; tracked objective now '%s'" % _quest_line())


## R8.4 in §28's order. The lever is live only now, and pulling it runs the
## chamber sequence: freed, then the voluntary offer to join, then the decision,
## then the machinery failing.
func _pull_the_lever() -> void:
	_watch_the_freed_flag()
	var prompt := _world.find_child("MachinePrompt", true, false)
	if prompt == null:
		_fail("no machine control in the Legendary Chamber; the legendary can never be freed")
		return
	await _walk_toward(_hold.call("marker", "machine_foot") as Vector3, 4.0)
	for i in 30:
		await physics_frame
	if not bool(prompt.get("enabled")):
		_fail("the machine is still refused with the Warden beaten; the legendary can never be freed")
		return
	_the_legendary_is_inside_the_machine()
	# Ask the prompt for a REAL offer from where the player is actually standing,
	# before activating it.
	#
	# GATE-F-LEG-S10AB, 2026-08-31. This beat used to go straight from the
	# `enabled` flag to `interaction_activate()`, which is a call no player can
	# make: it skips the distance entirely. So this test proved the Warden gate
	# and never once proved the button could be pressed — and it could not.
	# `stronghold.json`'s `machine_foot` mark sat at the chamber centre, which is
	# the machine's own axis, inside a base collider of radius 5.6, while the
	# prompt's radius is 4.2. 5.6 > 4.2: there was nowhere in the room a player
	# could stand and be offered it, and freeing the legendary — objective 25/27,
	# the chapter's second-to-last beat — was unreachable in the shipped build.
	# Measured in S10b: the walk stopped 7.2 m short against the machine's face.
	var offer: Dictionary = prompt.call("interaction_offer", _player.global_position)
	if offer.is_empty():
		_fail(("standing %.1f m from the machine control, the player is offered nothing. "
			+ "The lever is in the room and out of reach.")
			% _player.global_position.distance_to(prompt.global_position))
		return
	print("  machine control offered at %.1f m: '%s'" % [
		_player.global_position.distance_to(prompt.global_position),
		str(offer.get("label", ""))])
	prompt.call("interaction_activate")

	for i in SEQUENCE_FRAMES:
		await physics_frame
		if bool(_panel.call("is_open")):
			await _press("interact")
			continue
		if bool(_progression().call("has", FREED_FLAG)):
			break
	if not bool(_progression().call("has", FREED_FLAG)):
		_fail("the lever was pulled and '%s' was never set" % FREED_FLAG)
		return
	if _freed_writes > 1:
		_fail("'%s' was set %d times; every world change keyed on it would fire twice"
			% [FREED_FLAG, _freed_writes])
	var legendary: Node3D = _climax.call("legendary_body") as Node3D
	if legendary != null and legendary.get_node_or_null(^"ContainmentVFX") != null:
		_fail("the containment cage is still standing around a freed legendary")
	print("the legendary is freed and '%s' is set once" % FREED_FLAG)


## OP-0904-8 (owner: "The legendary should be in the machine not in a ring
## outside the machine"). Before the lever, the bound creature stands INSIDE
## the machine's measured cage: on the machine's own axis, above the dais the
## mesh carries there, under its crown -- measured off the installed mesh by
## `stronghold_climax.gd::_measure_cage`, not off a mark.
func _the_legendary_is_inside_the_machine() -> void:
	var legendary: Node3D = _climax.call("legendary_body") as Node3D
	if legendary == null:
		_fail("no bound legendary in the chamber before the lever")
		return
	var measure: Dictionary = _climax.call("cage_measure")
	if measure.is_empty():
		_fail("the climax found no machine to stand the legendary inside; it is in the ring on the floor again")
		return
	var axis: Vector3 = measure["axis"]
	var off := Vector2(legendary.global_position.x - axis.x, legendary.global_position.z - axis.z).length()
	var up := legendary.global_position.y - axis.y
	var dais := float(measure["dais_top"])
	var crown := float(measure["crown_under"])
	if off > 1.0:
		_fail("the bound legendary stands %.1f m off the machine's axis; it should be inside the machine" % off)
	if up < dais - 0.05 or up > crown:
		_fail("the bound legendary stands %.2f m up the machine; the cage void is %.2f..%.2f m" % [up, dais, crown])
	var machine: Node3D = _hold.call("machine") as Node3D
	if machine != null and legendary.global_position.distance_to(machine.global_position) > 6.0:
		_fail("the bound legendary is %.1f m from the machine" % legendary.global_position.distance_to(machine.global_position))
	print("the legendary is bound inside the machine: %.2f m off axis, %.2f m up (dais %.2f, crown %.2f)" % [
		off, up, dais, crown])


## After the freeing, the creature has STEPPED OUT of the machine (the visual
## half of the freeing, prompt 69's "physically legible"), and the Hall's
## garrison has stood down (CL-G5): the sentries and the camp gone, every
## fire and lamp on the gate face dark.
func _the_legendary_stepped_out_and_the_garrison_withdrew() -> void:
	# The ending is where the sequence LEAVES it, so let the sequence finish:
	# the machinery-fails lines are still on screen when the region answers.
	for i in SEQUENCE_FRAMES:
		if str(_climax.get("_stage")) == "done":
			break
		await physics_frame
		if bool(_panel.call("is_open")):
			await _press("interact")
	if str(_climax.get("_stage")) != "done":
		_fail("the climax never finished its sequence; it is stuck at stage '%s'" % str(_climax.get("_stage")))
	var legendary: Node3D = _climax.call("legendary_body") as Node3D
	var measure: Dictionary = _climax.call("cage_measure")
	if legendary != null and not measure.is_empty():
		var axis: Vector3 = measure["axis"]
		var off := Vector2(legendary.global_position.x - axis.x, legendary.global_position.z - axis.z).length()
		var up := legendary.global_position.y - axis.y
		# Clear of the machine's own measured plinth, and standing on the
		# chamber floor rather than on the base -- the first version of this
		# assertion allowed 2.0 m off axis at 2.0 m up, which is ON the
		# plinth, and the print is what caught it.
		# Two independent facts, neither of them the code's own arithmetic:
		# the body's position is OUTSIDE the machine mesh's own bounds, and it
		# is on the chamber floor rather than up on the base. The first
		# version of this assertion allowed 2.0 m off axis at 2.0 m up, which
		# is standing ON the plinth, and the smoke's own print caught it.
		var machine: Node3D = _hold.call("machine") as Node3D
		var outside := true
		if machine != null:
			var box := AABB()
			var seeded := false
			# MESHES ONLY. `Light3D` is a `VisualInstance3D` too, and the
			# machine's `CoreLight` is an omni of range 26 -- so a
			# `VisualInstance3D` sweep merges a 52 m cube into the machine's
			# "footprint" and swallows the whole chamber. Measured: a creature
			# standing 10.8 m off the axis on the chamber floor, correctly
			# clear of a 6.2 m plinth, was reported as inside the machine.
			for child in machine.find_children("*", "MeshInstance3D", true, false):
				var mesh := child as MeshInstance3D
				if mesh.mesh == null:
					continue
				var here: AABB = mesh.global_transform * mesh.get_aabb()
				box = here if not seeded else box.merge(here)
				seeded = true
			if seeded:
				var at := legendary.global_position + Vector3.UP * 0.5
				outside = not Rect2(Vector2(box.position.x, box.position.z),
					Vector2(box.size.x, box.size.z)).has_point(Vector2(at.x, at.z))
		if not outside:
			_fail("the freed legendary is standing inside the machine's own footprint (%.1f m off axis, %.2f m up)" % [off, up])
		elif up > 0.6:
			_fail("the freed legendary is standing %.2f m up; the chamber floor is the machine's own base height" % up)
		else:
			print("the freed legendary stepped out of the machine: %.1f m off axis, %.2f m up, clear of its footprint" % [off, up])
	var watcher: Node = _climax.call("garrison_withdrawal")
	if watcher == null:
		_fail("the climax hung no garrison watcher off the Hall; the occupation can never withdraw")
		return
	if not bool(watcher.call("withdrawn")):
		_fail("the legendary is freed and the Hall's garrison never withdrew")
		return
	var report: Dictionary = watcher.call("withdrawal_report")
	var sentries: Node3D = _hold.find_child("GateSentries", false, false) as Node3D
	if sentries != null and sentries.visible:
		_fail("the gate sentries are still standing at the Hall after the machinery died")
	var camp: Node3D = _hold.find_child("GarrisonCamp", false, false) as Node3D
	if camp != null and camp.visible:
		_fail("the garrison camp is still pitched at the Hall after the machinery died")
	var fires: Node = _hold.find_child("HallBraziers", false, false)
	var lit := 0
	if fires != null:
		for light in fires.find_children("*", "Light3D", true, false):
			if (light as Light3D).visible:
				lit += 1
	if lit > 0:
		_fail("%d of the Hall's braziers are still burning after the garrison withdrew" % lit)
	if int(report.get("withdrawn", 0)) <= 0 or int(report.get("lights_out", 0)) <= 0:
		_fail("the withdrawal report is empty (%s); nothing visibly changed at the Hall" % str(report))
	print("the garrison withdrew: %s" % str(report))


## The chapter's decision, on the belt it was designed for. Five creatures with
## names, levels and history; a sixth that offers to join; and no sixth holder
## anywhere in the game (CLAUDE.md's hard rule). The ceremony is driven on real
## input, the same way `smoke_release.gd` drives it.
func _the_full_belt_takes_the_decision() -> void:
	for i in SEQUENCE_FRAMES:
		await process_frame
		if _game.get("pending_catch") != null and bool(_menu.call("is_open")):
			break
		if bool(_panel.call("is_open")):
			await _press("interact")
	if _game.get("pending_catch") == null:
		_fail("a full belt met the legendary and no decision was ever offered")
		return
	if int(_party.call("size")) != 5:
		_fail("the party holds %d before the ceremony resolved; the cap broke"
			% int(_party.call("size")))
		return
	if not bool(_menu.call("is_open")):
		_fail("the pending legendary never opened the release ceremony")
		return
	for i in 12:
		await process_frame
	if str(_tab.get("_release_stage")) != "choose":
		_fail("the ceremony opened but is not in its choose beat (stage '%s')"
			% str(_tab.get("_release_stage")))
		return

	# Give up the fifth. A real answer to a real question — and the identity
	# prompt 67 asks the ceremony to show has to be on screen while it is asked.
	var giving_up: RefCounted = _party.call("at", 4)
	var name_given_up := str(giving_up.call("label"))
	(_tab.get("_rows")[4] as Button).grab_focus()
	await process_frame
	await _press("ui_accept")
	if str(_tab.get("_release_stage")) != "confirm":
		_fail("choosing a belt row did not open the farewell question")
		return
	var body_label: Label = _tab.get("_farewell_body")
	if body_label == null or body_label.text.find("Lv ") < 0 or body_label.text.find("bond") < 0:
		_fail("the farewell question does not restate what is being given up: '%s'"
			% (body_label.text if body_label != null else ""))
	await _press("ui_down")
	await _press("ui_accept")
	if str(_tab.get("_release_stage")) != "done":
		_fail("confirming the release did not reach the goodbye beat")
		return
	await _press("ui_accept")
	for i in 20:
		await process_frame
	# Out of the menu and back into the world. Not a formality: the menu pauses
	# the tree, and everything left in the finale -- the climax's own stage
	# machine, the dialogue effect drain, the world's healing -- runs on
	# `_process`. A run that left the menu up measured every one of those as
	# broken.
	await _press("menu_cancel")
	for i in 20:
		await process_frame
	if bool(_menu.call("is_open")) or paused:
		_fail("the ceremony ended and the menu/pause never gave the world back")
		return

	if int(_party.call("size")) != 5:
		_fail("the resolved belt holds %d; the five-creature limit is a hard rule"
			% int(_party.call("size")))
		return
	if _game.get("pending_catch") != null:
		_fail("the ceremony closed with the legendary still on the seam")
	var kept := false
	var still_there := false
	for member: Variant in (_party.call("members") as Array):
		if str((member as RefCounted).get("species_id")) == "veridian":
			kept = true
		if member == giving_up:
			still_there = true
	if not kept:
		_fail("the released creature went and the legendary never took the holder")
	if still_there:
		_fail("'%s' was released and is still on the belt" % name_given_up)
	print("the decision resolved: '%s' released, the legendary on a belt of five"
		% name_given_up)


## GATE-E's own flag, and the reason it exists: `legendary_joined` answers "did
## it end up on the belt", which is only ONE of the two legal endings. The chain
## needs "is the decision over", and that is this.
func _the_decision_is_recorded() -> void:
	if not bool(_progression().call("has", SETTLED_FLAG)):
		_fail(("the roster decision was made and '%s' was never set; the objective chain stalls here "
			+ "(climax stage '%s', joined=%s)") % [SETTLED_FLAG, str(_climax.get("_stage")),
			str(_progression().call("has", "legendary_joined"))])
		return
	var line := str(_quest_line())
	if line.to_lower().contains("walks with you"):
		_fail("the roster objective is still tracked after the decision: '%s'" % line)
	else:
		print("the roster decision is recorded; tracked objective now '%s'" % line)


## §9 / SG46. The Meadows must not be identical to how it was an hour ago.
func _the_region_answers() -> void:
	var healing := _world.get_node_or_null(^"MeadowHealing")
	if healing == null:
		_fail("the world built no MeadowHealing node; the Meadows never answers")
		return
	if not bool(healing.call("applied")):
		_fail("the Warden fell, the machinery died, and the region did not respond")
		return
	var report: Dictionary = healing.call("report")
	if int(report.get("regrown", 0)) <= 0:
		_fail("nothing grew back around the drain stations after the machinery died")
	print("the region answered: %d plants back, %d tether lights out, %d barriers open, %d patrols withdrawn"
		% [int(report.get("regrown", 0)), int(report.get("lights_killed", 0)),
			int(report.get("barriers_opened", 0)), int(report.get("patrols_withdrawn", 0))])
	await _the_legendary_stepped_out_and_the_garrison_withdrew()


## The last beat prompt 69 names, and the one the chapter had no way to reach:
## somebody in the world says out loud that it changed, and the objective chain
## terminates on it. Driven through the real panel and the real effect drain —
## the same route a villager's greeting takes — rather than by setting the flag.
func _the_meadows_acknowledges_it() -> void:
	if bool(_progression().call("has", ACKNOWLEDGED_FLAG)):
		_fail("'%s' was already set before anybody was spoken to" % ACKNOWLEDGED_FLAG)
		return
	if not bool(_panel.call("start", "village_mira_freed")):
		_fail("the post-victory conversation could not be started")
		return
	for i in 200:
		if not bool(_panel.call("is_open")):
			break
		await _press("interact")
	for i in 30:
		await process_frame
	if not bool(_progression().call("has", ACKNOWLEDGED_FLAG)):
		_fail("a post-victory villager was heard and '%s' was never set; the chapter's last objective cannot complete"
			% ACKNOWLEDGED_FLAG)
		return
	var line := str(_quest_line())
	if line != "":
		_fail("the chapter is over and the HUD is still tracking '%s'" % line)
	else:
		print("the Meadows acknowledged the victory and the objective chain terminated")


## --- fighting ---------------------------------------------------------------

## Walk up, take the challenge through the real prompt and the real
## conversation, then fight the whole team down.
func _challenge_and_win(id: String, body: Node3D, room: String) -> void:
	var spec: Dictionary = TRAINERS.trainer(id)
	if spec.is_empty():
		_fail("trainers.json has no '%s'" % id)
		return
	await _stand_in_front_of(body)
	if not bool(_director.call("can_challenge", spec)):
		_fail("the director refuses to let '%s' be challenged" % id)
		return
	var offered := str(_director.call("prompt"))
	if not offered.contains(str(spec.get("name", ""))):
		_fail("standing in front of '%s' offered no challenge prompt (got '%s')" % [id, offered])

	var presses := 0
	for i in 1400:
		if bool(_manager.call("is_fighting")):
			break
		if presses == 0 or bool(_panel.call("is_open")):
			await _press("interact")
			presses += 1
			for n in 6:
				await physics_frame
			continue
		await physics_frame
	if not bool(_manager.call("is_fighting")):
		_fail("'%s''s challenge never opened a fight" % id)
		return
	if str(_director.call("trainer_battle_id")) != id:
		_fail("the running battle is '%s', not '%s'" % [str(_director.call("trainer_battle_id")), id])
		return
	await _fight_to_the_end(id, room)


func _fight_to_the_end(id: String, room: String) -> void:
	var frames := 0
	var hits_at_start := _quick_hits
	var misses_at_start := _quick_misses
	## Prompt 34's acceptance 3 and 6: a fight that stops progressing has to
	## fail QUICKLY, naming the state it stopped in, rather than spending the
	## whole budget arriving at "never resolved" — which is a sentence that
	## tells the next investigation nothing. Progress is any of: a swing landed
	## or missed, either side's HP moved, the fight state changed, or the two
	## bodies got closer. None of that for this many iterations is a stall.
	var last_progress := 0
	var was := {"gap": INF, "theirs": -1.0, "state": -1, "attacks": -1}
	_consecutive_misses = 0
	_manager.connect("attack_missed", _on_attack_missed)
	_manager.connect("hit_landed", _on_hit_landed)
	var floored := false
	while bool(_director.call("trainer_battle_active")) and frames < BATTLE_FRAME_LIMIT:
		frames += 1
		if not bool(_manager.call("is_fighting")):
			last_progress = frames
			await physics_frame
			continue
		var mine: RefCounted = _manager.call("active_creature")
		if mine != null:
			mine.hp = mine.max_hp
		# T2-FLAKE: ask the director which body is IN the fight, the same way the
		# ally is asked for one line down. This used to be
		# `find_child("TrainerCreature_%s_*")`, which returns the oldest match in
		# tree order -- and `encounter_director._on_trainer_round_ended()` leaves
		# each beaten creature standing in the world for a beat before clearing
		# it, so from round two onward that wildcard matched a CORPSE while the
		# live creature fought on unmeasured. Everything downstream read the
		# wrong body: the floor check below, the closing-distance gap, and the
		# stall report's "opponent at x,y,z".
		var opponent: Node3D = _director.call("trainer_body") as Node3D
		var ally: Node3D = _director.call("ally_body") as Node3D
		if opponent == null or ally == null:
			await physics_frame
			continue

		# GATE-E. Both fighters have to be standing in the ROOM the fight was
		# started in. They were not: every stronghold fight opened seven metres
		# below its own floor, on the terrain under the building, because every
		# placement in combat resolved the ground as the terrain (see
		# scripts/world/built_floor.gd). Down there whether the ally can close
		# at all depends on which side of a revetment support each body lands
		# on — fine locally, wedged on GitHub's runner, which is exactly the
		# shape prompt 34 describes. Checked ONCE per fight, as soon as both
		# bodies exist, so the failure names the cause instead of the symptom.
		#
		# Re-checked periodically rather than only at the start: a body can also
		# LEAVE the floor mid-fight (measured on a probe that teleported into a
		# wall band -- the ally was at the floor on the first frame and 6.6m
		# under it eighty frames later), and a fighter that falls out of the room
		# halfway through is the same defect arriving late. Only the first
		# failure is reported; after that the fight is already condemned.
		if not floored and frames % FLOOR_CHECK_EVERY == 1:
			floored = _both_fighters_are_in_the_room(id, room, ally, opponent)

		var theirs: RefCounted = opponent.get("instance")
		if theirs != null and theirs.hp > 6.0:
			theirs.hp = 6.0
		var to := opponent.global_position - ally.global_position
		to.y = 0.0
		var rig := _world.get_node_or_null(^"CameraRig") as Node3D
		if rig != null:
			rig.set("yaw", atan2(-to.x, -to.z))

		var gap := to.length()
		var attacks := _quick_hits + _quick_misses
		var state := int(_manager.get("state"))
		var their_hp := float(theirs.get("hp")) if theirs != null else -1.0
		if attacks != int(was["attacks"]) or state != int(was["state"]) \
				or not is_equal_approx(their_hp, float(was["theirs"])) \
				or gap < float(was["gap"]) - 0.05:
			last_progress = frames
		was["attacks"] = attacks
		was["state"] = state
		was["theirs"] = their_hp
		was["gap"] = minf(float(was["gap"]), gap)

		var reach := _floored_quick_range(ally, opponent)
		if frames - last_progress > STALL_FRAMES:
			_fail(_stalled_report(id, room, frames, ally, opponent, gap, reach,
				hits_at_start, misses_at_start))
			_disconnect_fight_signals()
			return

		# See smoke_boss.gd's own note: gating the approach on a guessed constant
		# is what stalled `verify-boss` for two runs. The floor is recomputed
		# from the two bodies' radii, the same way the real swing computes it.
		if gap > reach:
			Input.action_press("move_forward")
			await physics_frame
			Input.action_release("move_forward")
		elif bool(_manager.call("quick_ready")):
			await _press("combat_quick")
			if _consecutive_misses >= CONSECUTIVE_MISS_LIMIT:
				_fail(("the player's quick attack whiffed %d times in a row against '%s' (%.2fm away) "
					+ "-- a real miss, not the fight stalling") % [_consecutive_misses, id, gap])
				_disconnect_fight_signals()
				return
		else:
			await physics_frame
	_disconnect_fight_signals()
	if bool(_director.call("trainer_battle_active")):
		_fail(("'%s''s fight never resolved inside %d frames (%d quick attacks landed, %d missed, "
			+ "%d consecutive at the end)") % [id, BATTLE_FRAME_LIMIT, _quick_hits - hits_at_start,
			_quick_misses - misses_at_start, _consecutive_misses])
		return
	if not bool(_player.call("locomotion_enabled")):
		_fail("exploration never came back after '%s''s fight" % id)


## The fight is happening where the player started it, not under the building.
## Returns true once it has reported a failure, so it reports each fight's
## first fall-through and then stops.
func _both_fighters_are_in_the_room(id: String, room: String, ally: Node3D,
		opponent: Node3D) -> bool:
	if _hold == null or room == "":
		return true
	var floor_y: float = (_hold.call("marker", room) as Vector3).y
	for pair: Array in [["the player's creature", ally], ["'%s''s creature" % id, opponent]]:
		var who: String = str(pair[0])
		var body := pair[1] as Node3D
		var drop := floor_y - body.global_position.y
		if drop > ROOM_FLOOR_TOLERANCE_M:
			# T1-HALL-REBUILD: the position and the building's own claim at that
			# position are part of the message now. This failure is INTERMITTENT
			# (two consecutive failures then seven consecutive passes on an
			# identical tree, 2026-08-30), and without the coordinates there is
			# nothing in the log to tell the next reader whether the fighter
			# drifted outside the claimed footprint or the claim itself is
			# wrong -- which is the difference between a combat-placement bug
			# and a building bug. One run that reproduces it is worth a lot more
			# with them than without.
			# T2-FLAKE adds the body's NAME and every other creature body in the
			# world beside it. The position and the floor claim answered the
			# previous question (drifted outside the footprint, or a wrong
			# claim: neither -- it is inside a claim it is not standing on).
			# The next question is which body this is, because until this run
			# the check searched for it by name and could match a corpse.
			_fail(("%s ('%s') is fighting '%s' %.1fm BELOW '%s''s floor (y=%.2f against a floor at "
				+ "y=%.2f) -- the fight is under the building, not in the room "
				+ "[at %.1f, %.2f, %.1f; the building's floor claim there is %.2f; "
				+ "creature bodies in the world: %s]")
				% [who, body.name, id, drop, room, body.global_position.y, floor_y,
				body.global_position.x, body.global_position.y, body.global_position.z,
				float(_hold.call("built_floor_height_at", body.global_position.x,
					body.global_position.z)),
				_creature_bodies_with_heights()])
			return true
	return false


## Every trainer creature body standing in the world, with its height.
##
## T2-FLAKE. `_on_trainer_round_ended()` leaves a beaten creature in the world
## for a beat, so during a multi-creature battle there is more than one body
## with the same name prefix. When the floor check fires, which of them it fired
## on is the whole question, and a list of all of them answers it in the run
## that reproduces rather than in the one after.
func _creature_bodies_with_heights() -> String:
	var seen: Array[String] = []
	for child in _world.get_children():
		if not str(child.name).begins_with("TrainerCreature_"):
			continue
		var body := child as Node3D
		if body == null:
			continue
		seen.append("%s y=%.2f%s" % [body.name, body.global_position.y,
			" (live)" if body == _director.call("trainer_body") else ""])
	return ", ".join(seen) if not seen.is_empty() else "none"


## Everything worth knowing about a fight that stopped moving, in one line.
func _stalled_report(id: String, room: String, frames: int, ally: Node3D, opponent: Node3D,
		gap: float, reach: float, hits_at_start: int, misses_at_start: int) -> String:
	var floor_y: float = (_hold.call("marker", room) as Vector3).y if _hold != null and room != "" else NAN
	return ("'%s''s fight stopped progressing for %d iterations (%d in). "
		+ "ally at %.1f,%.2f,%.1f; %s at %.1f,%.2f,%.1f; room floor y=%.2f; "
		+ "flat gap %.2fm against a reach of %.2fm; dy %.2fm; quick_ready=%s; state=%d; "
		+ "%d landed / %d missed in this fight") % [
		id, STALL_FRAMES, frames,
		ally.global_position.x, ally.global_position.y, ally.global_position.z,
		opponent.name, opponent.global_position.x, opponent.global_position.y,
		opponent.global_position.z, floor_y, gap, reach,
		opponent.global_position.y - ally.global_position.y,
		str(_manager.call("quick_ready")), int(_manager.get("state")),
		_quick_hits - hits_at_start, _quick_misses - misses_at_start]


func _disconnect_fight_signals() -> void:
	if _manager.is_connected("attack_missed", _on_attack_missed):
		_manager.disconnect("attack_missed", _on_attack_missed)
	if _manager.is_connected("hit_landed", _on_hit_landed):
		_manager.disconnect("hit_landed", _on_hit_landed)


func _on_attack_missed(by_player: bool) -> void:
	if not by_player:
		return
	_quick_misses += 1
	_consecutive_misses += 1


func _on_hit_landed(on_enemy: bool, _amount: float) -> void:
	if not on_enemy:
		return
	_quick_hits += 1
	_consecutive_misses = 0


func _floored_quick_range(ally: Node3D, opponent: Node3D) -> float:
	var base := float(MATH.config().get("player_quick", {}).get("range", 2.6))
	var mine := 0.5
	var theirs := 0.5
	if ally != null and ally.has_method("body_radius"):
		mine = float(ally.call("body_radius"))
	if opponent != null and opponent.has_method("body_radius"):
		theirs = float(opponent.call("body_radius"))
	var clearance := float(MATH.config().get("enemy", {}).get("body_clearance", 1.8))
	return maxf(base, (mine + theirs) * clearance + 0.5)


## --- harness ----------------------------------------------------------------

## The creature-bed rest panel, which `creature_bed.gd` parks on the scene root
## rather than under the bed. Found by script path so a renamed node cannot
## silently turn this check into a no-op.
func _rest_panel() -> Node:
	for child in root.get_children():
		var script := child.get_script() as Script
		if script != null and script.resource_path.ends_with("creature_bed_panel.gd"):
			return child
	return null


func _gauntlet_body(id: String) -> Node3D:
	var trainers: Node3D = _hold.call("trainers_node")
	if trainers == null:
		return null
	return trainers.call("body_for", id) as Node3D


## Walk, on real collision, until within `stop` metres or the budget runs out.
## Same direct-drive technique smoke_stronghold/smoke_warrens document: the
## controller's own `_physics_process` is suspended for the push, because two
## `move_and_slide()` calls a frame with two velocities is a race.
## `budget` overrides WALK_FRAMES for a walk that is simply longer than the
## default covers. GATE-F-LEG-S10AB: WALK_FRAMES is 700 and this walker moves at
## 4 m/s, so it can cover 46.7 m — and the causeway from `entrance` to the Outer
## Works' centre is 53.2 m. The walk-in was running out of budget several metres
## short and the old 14 m tolerance passed it anyway.
func _walk_toward(target: Vector3, stop: float, budget: int = WALK_FRAMES) -> void:
	_player.set_physics_process(false)
	for i in budget:
		var to := target - _player.global_position
		to.y = 0.0
		if to.length() <= stop:
			break
		var flat := to.normalized()
		_player.velocity.x = flat.x * 4.0
		_player.velocity.z = flat.z * 4.0
		_player.velocity.y = 0.0 if _player.is_on_floor() else _player.velocity.y - 0.5
		_player.move_and_slide()
		await physics_frame
	_player.set_physics_process(true)
	_face(target)
	for i in 8:
		await physics_frame


## The last two metres of an approach, placed rather than walked.
##
## The walk above gets the player to the trainer through the real route; this
## puts them on the trainer's OWN front at the distance the challenge prompt is
## offered from, which is what `smoke_boss.gd` does for the same reason. Walking
## the final approach blind lands on whichever side of the body the path came
## in on, and from behind a trainer the interaction arbiter hands back the
## nearest other offer instead ("Put Bracket away", measured) -- a test failure
## about approach geometry, not about the fight this file is here to drive.
func _stand_in_front_of(body: Node3D) -> void:
	var facing := body.rotation.y
	var spot := body.global_position + Vector3(sin(facing), 0.0, cos(facing)) * 2.6
	var ground := float(_world.call("ground_height_at", spot.x, spot.z))
	# Inside the stronghold the terrain is metres BELOW the built floor, so the
	# body's own y is the authority there and the terrain sample is the fallback.
	spot.y = body.global_position.y + 1.0
	if _hold == null and not is_nan(ground):
		spot.y = ground + 1.0
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	_face(body.global_position)
	for i in 60:
		await physics_frame


func _face(target: Vector3) -> void:
	var to := target - _player.global_position
	to.y = 0.0
	if to.length() < 0.01:
		return
	var rig := _world.get_node_or_null(^"CameraRig") as Node3D
	if rig != null:
		rig.set("yaw", atan2(-to.x, -to.z))


func _put_down(at: Vector3) -> void:
	_player.global_position = at
	_player.velocity = Vector3.ZERO
	for i in 40:
		await physics_frame


func _quest_line() -> String:
	var log_reader: RefCounted = _game.get("quest_log")
	if log_reader == null:
		return ""
	return str(log_reader.call("tracked_text", _progression()))


func _watch_the_freed_flag() -> void:
	var progression := _progression()
	if progression == null or not progression.has_signal("flag_set"):
		return
	progression.connect("flag_set", func(flag: String) -> void:
		if flag == FREED_FLAG:
			_freed_writes += 1)


func _progression() -> RefCounted:
	return _game.get("progression") as RefCounted if _game != null else null


func _progression_config() -> Dictionary:
	var file := FileAccess.open("res://data/config/progression.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _press(action: String) -> void:
	Input.action_press(action)
	_send(action, true)
	await process_frame
	await process_frame
	Input.action_release(action)
	_send(action, false)
	for i in 4:
		await process_frame


func _send(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("gate E finale smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)
