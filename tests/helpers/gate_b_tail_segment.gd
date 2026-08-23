extends RefCounted

## Gate B's TAIL, as one reusable segment: house -> creature bed -> camp ->
## the nights that make a team rested -> the marshal's entry gate -> the three
## fought rounds -> the objective that points at the South Bridge.
##
## `tests/smoke_gate_b_continuous.gd` plays Gate B from the title screen, and
## until the village walk lands it has never got past Mira's door -- so
## everything downstream of the village had never executed inside that run at
## all. This file is that downstream half, extracted so it can be driven from a
## SYNTHESIZED post-village state in a couple of minutes
## (`tests/smoke_gate_b_tail.gd`) instead of only ever at the end of a
## thirty-minute continuous run.
##
## It is deliberately HARDER than the tail the continuous file used to assert:
##
## * the creature bed and the camp are PLACED, through the real build menu and
##   the real placer, out of the materials the authored gather route actually
##   supplies -- the old tail called `build_real()` on whatever bed it could
##   find in the world, which is a bed the player never built;
## * the team is brought into condition by SLEEPING, one creature per bed per
##   night, through `camp.gd`'s own rest -- not by calling
##   `creature_condition.note_rest_completed()` on the party;
## * the tournament is entered through the marshal's own `greeting_when`
##   ladder, which means `tournament_condition_ready` has to be true for real;
## * the three rounds are FOUGHT, through `encounter_director`;
## * Gate B ends where `ralph/ACTIVE_GAME_PLAN.md` says it ends -- on the
##   OBJECTIVE to leave for the South Bridge, not on the bridge already open.

const BUILD_SEGMENT := preload("res://tests/helpers/gate_a_build_segment.gd")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const TOURNAMENT := preload("res://scripts/world/tournament.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const VILLAGE_NPCS := preload("res://scripts/world/village_npcs.gd")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const CONDITION := preload("res://scripts/creatures/creature_condition.gd")
const HOME_PROGRESS := preload("res://scripts/build/home_progress.gd")
const PROMPTS := preload("res://scripts/world/prompt_arbiter.gd")
const COMBAT_CONFIG := "res://data/config/combat.json"
const VILLAGERS_PATH := "res://data/config/village_npcs.json"
## What the team eats. `items.json`'s berries carry the `creature_food` block
## and grow all over the meadow the gather route already walks.
const FOOD_ITEM := "berries"

## Where the bed and the camp go: offsets from the Practice Meadow build patch
## the house itself is raised on. Tried in order; the first one whose LIVE
## ghost reads green wins, so a house footprint that shifts by a metre does not
## turn into a placement failure with no diagnosis.
## Candidate offsets from the build patch, tried in order until a LIVE ghost
## reads green at one. Beds carry far more candidates than camps because THREE
## of them go down (owner directive 2026-08-23 §1) and each one spends a spot:
## with four candidates and three beds, a single red ghost would end the run.
const FIXTURE_SPOTS := {
	"creature_bed": [
		Vector2(-5.0, 0.0), Vector2(-5.0, 3.0), Vector2(-7.0, -2.0), Vector2(0.0, -5.0),
		Vector2(-8.0, 2.0), Vector2(-3.0, -6.0), Vector2(-9.0, -5.0), Vector2(-2.0, 5.0),
		Vector2(-10.0, 0.0), Vector2(-6.0, 6.0), Vector2(-11.0, -3.0), Vector2(-4.0, 8.0),
	],
	"camp": [Vector2(5.0, 0.0), Vector2(5.0, 3.0), Vector2(7.0, -2.0), Vector2(0.0, 6.0)],
}
const BUILD_PATCH_XZ := BUILD_SEGMENT.BUILD_PATCH_XZ
const PLACE_AHEAD := 3.0
## How close a walk has to get. Loose enough that the stick's own minimum
## strength does not oscillate around the target for the whole frame budget.
const MOVE_EPSILON := 0.35
## The floor under a leg's frame budget (`_walk_to()` derives the rest from the
## leg's own length). GATEB-COORD raised it from 900: fifteen seconds is plenty
## of walking in open meadow and nothing like enough around the build patch,
## where three creature beds, a camp and a house now stand within a few metres
## of each other and the navigator spends most of its frames sliding round
## them rather than closing on the target.
const MOVE_FRAME_LIMIT := 3600

## The tournament ground. `trainers.json`'s own vetted-clear practice spot, the
## same one `smoke_tournament_bracket.gd` fights on and for the same reason:
## the opponent's fallback spawn has to have somewhere legal to stand.
const ARENA_XZ := Vector2(13.0, 9.0)

const HOTBAR_ACTIONS: Array[StringName] = [&"hotbar_1", &"hotbar_2", &"hotbar_3", &"hotbar_4"]
const ROUND_FRAME_LIMIT := 9000
const STALL_FRAMES := 900

var failures: Array[String] = []
var transcript: Array[String] = []

var _tree: SceneTree
var _world: Node3D
var _game: Node
var _player: CharacterBody3D
var _rig: Node3D
var _progression: RefCounted
var _party: RefCounted
var _panel: Node
var _manager: Node
var _director: Node
var _arbiter: Node
var _bed: Node3D
## One per entrant (owner directive 2026-08-23 §1). `_bed` stays as the first
## of them so the panel-driving helpers keep one obvious default.
var _beds: Array[Node3D] = []
## Offsets from `FIXTURE_SPOTS` that already carry something.
var _spent_spots: Array = []
## Travel, built lazily because the bindings it needs are resolved after
## `run()` starts. See `stick_navigator.gd`.
var _nav = null  # stick_navigator.gd; untyped so its methods read as methods
var _camp: Node3D
var _felled := 0
var _exit_connected := false
var _engage_distance := 3.6

var _move_x_axis: JoyAxis = JOY_AXIS_LEFT_X
var _move_y_axis: JoyAxis = JOY_AXIS_LEFT_Y
var _move_x_sign := 1.0
var _move_y_sign := 1.0


## `stage_arena`: put the player on the tournament ground before the fights
## rather than walking them there. The walk from the Practice Meadow back
## through the village is `gate_a_npc_gather_segment.gd`'s territory and is
## owned by another lane; this segment is about what happens at each END of
## that walk.
## `skip_house` exists for ITERATION ONLY and is never set by the continuous
## run: the controller house is ten minutes of walking on a loaded box, and a
## defect in the bed/camp/nights/bracket half should not cost ten minutes to see
## twice. `tests/smoke_gate_b_tail.gd` sets it from GATEB_TAIL_SKIP_HOUSE and
## says so in its own output, so a passing run that skipped it cannot be
## mistaken for a passing run that did not.
func run(tree: SceneTree, world: Node3D, game: Node, player: CharacterBody3D,
		rig: Node3D, stage_arena: bool = true, skip_house: bool = false) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	_player = player
	_rig = rig
	_progression = _game.get("progression")
	_party = _game.get("party")
	if _progression == null or _party == null:
		_fail("the tail segment was handed a Game with no progression/party")
		return _result()
	if not _collect_nodes():
		return _result()
	_resolve_move_bindings()
	_load_engage_distance()

	if skip_house:
		if not await _stand_in_the_house_that_was_granted():
			return _result()
	elif not await _raise_the_house():
		return _result()
	if not await _place_the_creature_beds():
		return _result()
	if not await _place_the_camp():
		return _result()
	if not await _sleep_the_team_into_condition():
		return _result()
	_feed_the_team()
	if not await _enter_the_tournament():
		return _result()
	if not await _fight_the_bracket():
		return _result()
	_the_objective_points_at_the_bridge(stage_arena)
	return _result()


func _collect_nodes() -> bool:
	_panel = _world.get_node_or_null(^"DialoguePanel")
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_arbiter = _tree.get_first_node_in_group(&"interaction_arbiter")
	if _panel == null or _manager == null or _director == null:
		_fail("the world has no dialogue panel, combat manager or encounter director; "
			+ "the tournament cannot be signed up for or fought")
		return false
	return true


func _load_engage_distance() -> void:
	var file := FileAccess.open(COMBAT_CONFIG, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	var quick: Dictionary = (parsed as Dictionary).get("player_quick", {})
	_engage_distance = maxf(float(quick.get("lunge", 3.6)), float(quick.get("range", 2.6)))


## --- 1: the house -------------------------------------------------------------

func _raise_the_house() -> bool:
	var built: Dictionary = await BUILD_SEGMENT.new().run(_tree, _world, _player, _rig)
	if not bool(built.get("passed", false)):
		for line: Variant in (built.get("failures", []) as Array):
			_fail("house: %s" % str(line))
		for line: Variant in (built.get("transcript", []) as Array):
			transcript.append("house | %s" % str(line))
		return false
	if not _flag("home_built"):
		_fail("the house went up and 'home_built' is unset")
		return false
	transcript.append("raised the small home; %s left" % _stock())
	_objective_should_read("Creature Bed", "home_built")
	return true


## The HUD's one tracked line, after a beat has landed. A beat that fires its
## flag without the objective moving is a beat the player cannot see they
## finished, and `data/progression/objectives.json` is the game's own record of
## where they are.
func _objective_should_read(fragment: String, after: String) -> void:
	var tracked := str(QUEST_LOG.new().call("tracked_text", _progression))
	if not tracked.contains(fragment):
		_fail("'%s' is done and the tracked objective reads '%s'; it should have moved on to "
			% [after, tracked] + "the beat that says '%s'" % fragment)


## Iteration mode. The house is REGISTERED rather than raised -- the same
## `register_building` bookkeeping a real placement performs, read back by
## `build_placer.restore_from_game()`, which is the production call site that
## decides `home_built`. Its exact material cost is still spent, so everything
## downstream sees the stock a real house leaves behind.
func _stand_in_the_house_that_was_granted() -> bool:
	var placer := _tree.get_first_node_in_group(&"build_placer")
	if placer == null:
		_fail("no BuildPlacer in the world")
		return false
	var i := 0
	for id: String in HOME_PROGRESS.required_pieces().keys():
		for _copy in int(HOME_PROGRESS.required_pieces()[id]):
			# Ten metres off the patch centre, so the granted shell does not sit
			# on the cells the bed and the camp are placed in below.
			_game.call("register_building", id, Vector3(
				BUILD_PATCH_XZ.x - 12.0 + i * 2.0, 0.0, BUILD_PATCH_XZ.y + 10.0), 0.0, false)
			i += 1
	var inventory: RefCounted = _game.get("inventory")
	inventory.call("remove", "wood", 39)
	inventory.call("remove", "stone", 34)
	placer.call("restore_from_game", _game)
	if not _flag("home_built"):
		_fail("the required home pieces are registered and restore_from_game did not set home_built")
		return false
	# Dropped rather than placed, for the reason `smoke_gate_b_tail.gd`'s own
	# staging records: `ground_height_at()` answers for the terrain, and a body
	# put at terrain height inside anything standing on it is wedged.
	var y := float(_world.call("ground_height_at", BUILD_PATCH_XZ.x, BUILD_PATCH_XZ.y)) + 6.0
	_player.global_position = Vector3(BUILD_PATCH_XZ.x, y, BUILD_PATCH_XZ.y)
	_player.velocity = Vector3.ZERO
	for _f in 180:
		await _tree.physics_frame
		if _player.is_on_floor():
			break
	for _f in 20:
		await _tree.physics_frame
	transcript.append("ITERATION MODE: the house was registered, not raised; %s left" % _stock())
	return true


## --- 2/3: the bed and the camp, out of what the gather route supplies ---------

## OWNER DIRECTIVE 2026-08-23 §1: three creature beds before the tournament,
## one per entrant.
##
## `tournament.gd::condition_ready()` asks the `min_party_size` STRONGEST
## entrants to be rested and `creature_bed.gd` holds exactly one occupant, so
## one bed meant three consecutive nights to field a team -- which is what this
## segment used to play. Three beds is one night, and the raised gather budget
## (`gate_a_material_route.gd::TARGET_STOCK`, 69/42/34) is what pays for them.
func _place_the_creature_beds() -> bool:
	var wanted := TOURNAMENT.required_party_size()
	for index in wanted:
		var bed := await _place_fixture("creature_bed")
		if bed == null:
			_fail("only %d of %d creature beds went up; the owner directive is one bed "
				% [_beds.size(), wanted] + "per entrant and the gather budget pays for them")
			return false
		_beds.append(bed)
		if not _flag("creature_bed_built"):
			_fail("a creature bed was placed by the player and 'creature_bed_built' is unset")
			return false
	_bed = _beds[0]
	transcript.append("placed %d creature beds through the build menu, one per entrant; %s left"
		% [_beds.size(), _stock()])
	_objective_should_read("Sleep until", "creature_bed_built")
	return true


func _place_the_camp() -> bool:
	_camp = await _place_fixture("camp")
	if _camp == null:
		return false
	transcript.append("placed the camp the player sleeps at; %s left" % _stock())
	return true


## Arm `id` through the real catalogue, walk to a candidate spot, and place it
## only once the LIVE ghost reads green there.
func _place_fixture(id: String) -> Node3D:
	var spots: Array = FIXTURE_SPOTS.get(id, [Vector2.ZERO])
	for offset: Variant in spots:
		# Three beds means this runs three times, and a spot that already holds
		# one is not a candidate for the next -- its ghost would read red and
		# cost a whole walk to find that out.
		if _spent_spots.has(offset):
			continue
		var at: Vector2 = BUILD_PATCH_XZ + (offset as Vector2)
		var target := Vector3(at.x, _player.global_position.y, at.y)
		if not await _stow_piece():
			return null
		if not await _walk_to(target - _forward() * PLACE_AHEAD, "%s stance at %s" % [id, at]):
			continue
		if not await _select_piece(id):
			return null
		await _settle(10)
		var placer := _tree.get_first_node_in_group(&"build_placer")
		if placer == null:
			_fail("no BuildPlacer in the world; nothing can be built")
			return null
		if not bool(placer.get("_ghost_ok")):
			transcript.append("%s ghost is red at %s; trying the next spot" % [id, at])
			continue
		var before: Array[Node] = _tree.get_nodes_in_group(&"placed_building")
		await _tap(&"build_place")
		await _settle(12)
		for node: Node in _tree.get_nodes_in_group(&"placed_building"):
			if before.has(node):
				continue
			if str(node.get_meta("building_id", "")) == id:
				_spent_spots.append(offset)
				await _stow_piece()
				return node as Node3D
		_fail("a green %s ghost at %s placed nothing" % [id, at])
		return null
	_fail("no candidate spot near the build patch took a %s; the player has nowhere to put it" % id)
	return null


## --- 4: the nights ------------------------------------------------------------

## Every entrant into its own bed, then ONE night.
##
## OWNER DIRECTIVE 2026-08-23 §1. This used to put one creature to bed, sleep,
## and repeat -- three nights to field three rested entrants, because the
## authored budget bought a single bed. With three beds the team goes to bed
## together and the chapter costs one night, which is what the tournament's own
## "come back rested" is asking for.
func _sleep_the_team_into_condition() -> bool:
	var wanted := TOURNAMENT.required_party_size()
	var entrants: Array[RefCounted] = []
	for index in wanted:
		var creature: RefCounted = _party.call("at", index)
		if creature == null:
			_fail("party slot %d is empty; the tournament team is not fielded" % index)
			return false
		if not await _assign_to_bed(index):
			return false
		entrants.append(creature)
	var day_before := int(_game.get("day"))
	if not await _sleep_at_camp():
		return false
	if int(_game.get("day")) != day_before + 1:
		_fail("a night at the camp did not advance the day (%d -> %d)"
			% [day_before, int(_game.get("day"))])
		return false
	for index in entrants.size():
		var creature := entrants[index]
		if not bool(creature.get("rested")):
			_fail(("%s slept in its own creature bed through the night and did not come out "
				+ "rested; %d beds were placed for %d entrants")
				% [str(creature.call("label")), _beds.size(), wanted])
			return false
		transcript.append("bed %d: %s rested (%s)" % [index + 1,
			str(creature.call("label")), CONDITION.label(creature, CONDITION.config())])
	transcript.append("one night in three beds put the whole team in condition")
	if not _flag("player_slept_at_home"):
		_fail("the player slept at their own camp and 'player_slept_at_home' is unset")
		return false
	_objective_should_read("Enter the village tournament", "player_slept_at_home")
	return true


## `index` selects both the party slot AND the bed it sleeps in: one bed per
## entrant is the whole point of the directive, and re-using bed 0 three times
## would put the same occupant to bed three times over.
func _assign_to_bed(index: int) -> bool:
	var bed: Node3D = _beds[index] if index < _beds.size() else _bed
	var prompt := bed.get_node_or_null(^"Interactable") as Node3D
	if prompt == null:
		_fail("the placed creature bed has no interaction prompt")
		return false
	if not await _walk_to_prompt(prompt, "creature bed %d" % (index + 1)):
		return false
	await _tap(&"interact")
	var panel := await _wait_for_panel("creature_bed_panel.gd")
	if panel == null:
		_fail("interacting with the creature bed opened no rest panel")
		return false
	if not await _focus_the_row_for(panel, index):
		await _tap(&"menu_cancel")
		return false
	await _tap(&"ui_accept")
	await _settle(6)
	var creature: RefCounted = _party.call("at", index)
	if creature == null or not bool(creature.get("resting")):
		_fail("the bed panel's own A press did not put party slot %d to bed" % index)
		await _tap(&"menu_cancel")
		return false
	await _tap(&"menu_cancel")
	await _settle(8)
	if _tree.paused:
		_fail("the creature-bed panel left the world paused")
		return false
	return true


## Move the panel's focus onto the row for party slot `index`, on the d-pad.
##
## GATEB-COORD. This used to press `ui_down` exactly `index` times from
## wherever the panel opened, which is only right when the panel opens on row
## 0. It does not, once a creature is already asleep: `creature_bed_panel.gd`
## builds one row per party slot and DISABLES a creature that is resting in
## another bed, then focuses "the first row that can actually act". So with
## three beds (owner directive 2026-08-23 §1) the second bed's panel opens
## already on slot 1, one press of down lands on slot 2, and the run put the
## wrong creature to bed and said so:
##
##   the bed panel's own A press did not put party slot 1 to bed
##
## Reading the focused row and stepping until it is the wanted one is what a
## player does, and it does not care where the panel opened.
func _focus_the_row_for(panel: Node, index: int) -> bool:
	var rows: Array = panel.get("_rows")
	if rows.is_empty() or index >= rows.size():
		_fail("the creature bed panel offered %d rows; party slot %d has none"
			% [rows.size(), index])
		return false
	var wanted := rows[index] as Button
	if wanted.disabled:
		_fail(("the creature bed panel's row for party slot %d is disabled ('%s'); "
			+ "with one bed per entrant every slot should still be choosable")
			% [index, wanted.text.strip_edges()])
		return false
	for _step in rows.size() * 2:
		if _focused_row(panel) == index:
			return true
		await _tap(&"ui_down")
		await _settle(4)
	_fail("could not move the bed panel's focus onto party slot %d; it sits on %d"
		% [index, _focused_row(panel)])
	return false


func _focused_row(panel: Node) -> int:
	var viewport := panel.get_viewport()
	if viewport == null:
		return -1
	return (panel.get("_rows") as Array).find(viewport.gui_get_focus_owner())


func _sleep_at_camp() -> bool:
	var prompt := _camp.get_node_or_null(^"Interactable") as Node3D
	if prompt == null:
		_fail("the placed camp has no 'Rest until morning' prompt")
		return false
	if not await _walk_to_prompt(prompt, "camp bedroll"):
		return false
	await _tap(&"interact")
	# `camp.gd` fades out over FADE_SECONDS and passes the night at the tween's
	# midpoint; the whole fade back in is longer again.
	var waited := 0.0
	while waited < 6.0:
		await _tree.process_frame
		waited += 1.0 / 60.0
	return true


## The other half of "well rested, well fed and happy".
##
## `nourishment` drains on REAL time (1.1 a minute, every party member, benched
## included), and a creature starts at 70 of 100 against a `fed_at` of 0.55. A
## short probe never notices; a thirty-minute continuous run drains 33 points
## and arrives at the marshal with a team that is rested, happy and HUNGRY --
## the entry gate then refuses a player who did everything the chapter asked.
## Feeding is what a player does about that, so the tail does it too.
##
## The two lines `tab_backpack.gd::_on_target_row()` runs for a food item, and
## the same allowance `smoke_tournament_bracket.gd` makes: driving the backpack
## UI proves the backpack, which is its own harness's job, not this one's.
func _feed_the_team() -> void:
	var items: RefCounted = _game.get("items")
	var inventory: RefCounted = _game.get("inventory")
	var food: Dictionary = (items.call("definition", FOOD_ITEM) as Dictionary).get("creature_food", {})
	if food.is_empty():
		_fail("'%s' carries no creature_food block; there is nothing to feed a team" % FOOD_ITEM)
		return
	var eaten := 0
	for entry: Dictionary in TOURNAMENT.entrants(_party):
		var creature: RefCounted = entry.get("creature")
		var cfg: Dictionary = CONDITION.config()
		for _bite in 12:
			if CONDITION.is_fed(creature, cfg):
				break
			if int(inventory.call("count", FOOD_ITEM)) <= 0:
				# The meadow is full of these and the route walks past them; a
				# tail that stopped here would be failing on the gathering
				# segment's beat, not on its own.
				inventory.call("add", FOOD_ITEM, 8)
				transcript.append("granted %d %s; gathering food is the route's own beat" % [8, FOOD_ITEM])
			if not bool(CONDITION.feed(creature, cfg, food).get("accepted", false)):
				break
			inventory.call("remove", FOOD_ITEM, 1)
			eaten += 1
	if eaten > 0:
		transcript.append("fed the entrants %d %s before the sign-up" % [eaten, FOOD_ITEM])


## --- 5: the entry gate --------------------------------------------------------

func _enter_the_tournament() -> bool:
	await _let_the_board_poll()
	for id: String in ["tournament_team_ready", "tournament_training_ready"]:
		if not _flag(id):
			_fail("the team does not satisfy '%s'; tournament.gd watches the party and writes it" % id)
			return false
	if not _flag("tournament_condition_ready"):
		_fail(("a team that slept %d nights in a placed creature bed is still not in condition: %s. "
			+ "This is the gate the marshal reads, so the tournament cannot be entered.")
			% [TOURNAMENT.required_party_size(), str(TOURNAMENT.readiness_report(_party))])
		return false
	transcript.append("the team is rested, fed and happy; tournament_condition_ready is set")

	var chosen := VILLAGE_NPCS.greeting_for(_villager(TOURNAMENT.marshal_name()), _progression)
	if chosen != "tournament_halda_signup":
		_fail("a ready team greeting %s should be offered 'tournament_halda_signup'; her ladder chose '%s'"
			% [TOURNAMENT.marshal_name(), chosen])
		return false
	await _play("tournament_halda_signup")
	if not _flag("tournament_entered"):
		_fail("the sign-up conversation played and 'tournament_entered' is unset")
		return false
	transcript.append("signed into the draw through the marshal's own ladder")
	_objective_should_read("Win the village tournament", "tournament_entered")
	return true


## --- 6: the three rounds ------------------------------------------------------

func _fight_the_bracket() -> bool:
	_stand_on_the_tournament_ground()
	for entry: Variant in TOURNAMENT.rounds():
		if not await _fight_and_win(entry as Dictionary):
			return false
	if not _flag("tournament_won"):
		_fail("all three rounds were fought and 'tournament_won' is unset")
		return false
	if not _flag("recipe_saddle"):
		_fail("the tournament was won and the saddle pattern was never granted")
		return false
	if not bool(_game.call("recipe_known", "saddle")):
		_fail("'recipe_saddle' is set and the saddle recipe still does not read as known")
		return false
	transcript.append("won the bracket; the saddle pattern is known")
	return true


func _stand_on_the_tournament_ground() -> void:
	var y := float(_world.call("ground_height_at", ARENA_XZ.x, ARENA_XZ.y)) + 1.0
	_player.global_position = Vector3(ARENA_XZ.x, y, ARENA_XZ.y)
	_player.velocity = Vector3.ZERO
	_rig.set("yaw", 0.0)


func _fight_and_win(spec: Dictionary) -> bool:
	var label := str(spec.get("label", "?"))
	var trainer_id := str(spec.get("trainer", ""))
	var won_flag := str(spec.get("won_flag", ""))
	var trainer := TRAINERS.trainer(trainer_id)
	if trainer.is_empty():
		_fail("%s names trainer '%s', which trainers.json does not define" % [label, trainer_id])
		return false

	var chosen := VILLAGE_NPCS.greeting_for(_villager(TOURNAMENT.marshal_name()), _progression)
	var conversation := str(spec.get("conversation", ""))
	if chosen != conversation:
		_fail("before the %s the marshal should offer '%s'; her ladder chose '%s'"
			% [label, conversation, chosen])
		return false
	await _play(conversation)
	for _i in 12:
		await _tree.process_frame
	if not bool(_director.call("trainer_battle_active")):
		_fail("'%s' closed and no %s battle started" % [conversation, label])
		return false
	if str(_director.call("trainer_battle_id")) != trainer_id:
		_fail("'%s' started a battle against '%s' rather than '%s'"
			% [conversation, str(_director.call("trainer_battle_id")), trainer_id])
		return false
	if not _exit_connected:
		_manager.connect("exited", func(outcome: String) -> void:
			if outcome == "won":
				_felled += 1)
		_exit_connected = true

	var team_size: int = TRAINERS.team_of(trainer).size()
	var felled_before := _felled
	var frames := 0
	var last_hp := INF
	var felled_at_progress := _felled
	var stalled := 0
	while bool(_director.call("trainer_battle_active")) and frames < ROUND_FRAME_LIMIT:
		frames += 1
		if not bool(_manager.call("is_fighting")):
			stalled += 1
			if stalled > STALL_FRAMES:
				_fail("%s stalled: no fight running for %d frames (%d of %d felled)"
					% [label, stalled, _felled - felled_before, team_size])
				return false
			await _tree.physics_frame
			continue
		# Not here to prove a stand-in team out-fights a level-11 Meadowhart;
		# here to prove the BRACKET runs after a real night's sleep. Same
		# allowance `smoke_tournament_bracket.gd` and `smoke_village_trainer.gd`
		# both make, in their own words.
		var piloted: RefCounted = _manager.call("active_creature")
		if piloted != null and piloted.hp_fraction() < 0.5:
			piloted.hp = piloted.max_hp
		var opponent: Node3D = _manager.call("enemy_body") as Node3D
		var ally: Node3D = _director.call("ally_body") as Node3D
		if opponent == null or ally == null:
			stalled += 1
			if stalled > STALL_FRAMES:
				_fail("%s stalled: %s for %d frames" % [label,
					"no opponent body" if opponent == null else "no ally body", stalled])
				return false
			await _tree.physics_frame
			continue
		var enemy: RefCounted = _manager.call("enemy")
		var enemy_hp: float = float(enemy.get("hp")) if enemy != null else INF
		if enemy_hp < last_hp or _felled > felled_at_progress:
			last_hp = enemy_hp
			felled_at_progress = _felled
			stalled = 0
		else:
			stalled += 1
			if stalled > STALL_FRAMES:
				_fail(("%s stalled: %d frames with no damage -- %.1f HP left, %.1fm away, "
					+ "piloted=%s hp=%s fainted=%s resting=%s, %d of %d felled") % [
					label, stalled, enemy_hp,
					ally.global_position.distance_to(opponent.global_position),
					str(piloted.get("species_id")) if piloted != null else "<none>",
					str(piloted.get("hp")) if piloted != null else "-",
					str(piloted.get("fainted")) if piloted != null else "-",
					str(piloted.get("resting")) if piloted != null else "-",
					_felled - felled_before, team_size])
				return false
		var to := opponent.global_position - ally.global_position
		to.y = 0.0
		_rig.set("yaw", atan2(-to.x, -to.z))
		if to.length() > _engage_distance:
			Input.action_press("move_forward")
			await _tree.physics_frame
			Input.action_release("move_forward")
		elif bool(_manager.call("charged_ready")):
			await _tap(&"combat_charged")
		elif bool(_manager.call("quick_ready")):
			await _tap(&"combat_quick")
		else:
			Input.action_press("move_forward")
			await _tree.physics_frame
			Input.action_release("move_forward")

	if frames >= ROUND_FRAME_LIMIT:
		_fail("%s never resolved after %d action frames" % [label, ROUND_FRAME_LIMIT])
		return false
	for _i in 60:
		await _tree.physics_frame
	if not _flag(won_flag):
		_fail("%s ended and '%s' was never set" % [label, won_flag])
		return false
	await _let_the_board_poll()
	transcript.append("%s: won in %d frames; the board now reads '%s'"
		% [label, frames, TOURNAMENT.status_line(_progression)])
	return true


## --- 7: where Gate B ends ------------------------------------------------------

## `ralph/ACTIVE_GAME_PLAN.md`: Gate B ends on "objective to leave for South
## Bridge". Not on the bridge already open -- crossing it is Gate C's first
## beat, and a run that sets `south_bridge_open` itself CONSUMES the objective
## Gate B is supposed to finish pointing at.
func _the_objective_points_at_the_bridge(_staged: bool) -> void:
	var quests := QUEST_LOG.new()
	var tracked := str(quests.call("tracked_text", _progression))
	if not tracked.contains("South Bridge"):
		_fail("the tournament is won and the tracked objective reads '%s'; the chapter never "
			% tracked + "tells the player to leave for the South Bridge")
		return
	transcript.append("objective handed off: '%s'" % tracked)


## --- plumbing ------------------------------------------------------------------

func _flag(id: String) -> bool:
	return bool(_progression.call("has", id))


func _stock() -> String:
	var inventory: RefCounted = _game.get("inventory")
	return "wood %d / stone %d / fiber %d" % [int(inventory.call("count", "wood")),
		int(inventory.call("count", "stone")), int(inventory.call("count", "fiber"))]


func _villager(person: String) -> Dictionary:
	var file := FileAccess.open(VILLAGERS_PATH, FileAccess.READ)
	if file == null:
		_fail("%s is missing; there is no marshal" % VILLAGERS_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("%s is not a JSON object" % VILLAGERS_PATH)
		return {}
	for entry: Variant in ((parsed as Dictionary).get("villagers", []) as Array):
		if entry is Dictionary and str((entry as Dictionary).get("name", "")) == person:
			return entry as Dictionary
	_fail("village_npcs.json has no villager called '%s'" % person)
	return {}


func _play(conversation_id: String) -> void:
	if not bool(_panel.call("start", conversation_id)):
		_fail("the dialogue panel refused to start '%s'" % conversation_id)
		return
	var guard := 0
	while bool(_panel.call("is_open")) and guard < 64:
		await _tree.process_frame
		_panel.call("advance")
		guard += 1
	await _tree.process_frame
	await _tree.process_frame
	if guard >= 64:
		_fail("'%s' never closed" % conversation_id)


func _let_the_board_poll() -> void:
	for _i in 12:
		await _tree.process_frame


func _wait_for_panel(script_tail: String) -> Node:
	for _i in 90:
		await _tree.process_frame
		for node: Node in _tree.root.find_children("*", "CanvasLayer", true, false):
			var script: Script = node.get_script() as Script
			if script == null or not str(script.resource_path).ends_with(script_tail):
				continue
			if node.has_method("is_open") and bool(node.call("is_open")):
				return node
	return null


func _walk_to_prompt(prompt: Node3D, what: String) -> bool:
	if not await _stow_piece():
		return false
	# The hammer has to leave the hand first, and since OWNER DIRECTIVE
	# 2026-08-23 §3 that is not a precaution but a requirement: Build OWNS
	# Interact while the hammer is out, so walking up to a bed or a bedroll
	# with the hammer still equipped reopens the catalogue every time rather
	# than sometimes. `_stow_hammer()` is what a player does about it.
	if not await _stow_hammer():
		return false
	if not await _walk_to(prompt.global_position, "the %s" % what, 1.4):
		return false
	for _i in 120:
		await _tree.physics_frame
		if _arbiter == null:
			return true
		if _arbiter.has_method("winning_provider") and _arbiter.call("winning_provider") == prompt:
			return true
	_fail("standing 1.4m from the %s never won the interaction prompt; its offer reads '%s'"
		% [what, str(_arbiter.call("prompt")) if _arbiter.has_method("prompt") else "?"])
	return false


func _stow_hammer() -> bool:
	if str(_game.get("equipped_tool")) != "hammer":
		return true
	var slot := int(_game.call("hotbar_slot_of", "hammer"))
	if slot < 0 or slot >= HOTBAR_ACTIONS.size():
		_fail("the hammer is in hand and on no reachable quick slot; it cannot be put away")
		return false
	await _tap(HOTBAR_ACTIONS[slot])
	await _settle(8)
	if str(_game.get("equipped_tool")) == "hammer":
		_fail("the quick-slot press did not put the hammer away")
		return false
	return true


## CONTROLLER-MAP retired `build_open`'s pad button; hammer-in-hand plus
## Interact is the only pad route into the catalogue
## (`playground_hud.gd::_hammer_opens_the_catalogue`).
func _select_piece(id: String) -> bool:
	var menu := _open_build_menu()
	if menu == null:
		if _joy_binding_for(&"build_open") != null:
			await _tap(&"build_open")
		else:
			# The hammer route deliberately FORFEITS Interact whenever anything
			# actionable is winning arbitration -- that is
			# `_hammer_opens_the_catalogue()`'s own rule, so the same button can
			# still talk to people and pick berries. A stance that happens to
			# sit inside a bush's or a door's prompt radius therefore harvests
			# instead of opening Build, and the press is gone. Step out of every
			# offer FIRST; a player reading "[X] Gather" where they wanted the
			# catalogue does the same.
			if not await _clear_of_every_offer():
				return false
			if not await _hammer_in_hand():
				return false
			await _tap(&"interact")
		await _settle(14)
		menu = _open_build_menu()
	if menu == null:
		_fail("Build did not open from the controller's own route into the catalogue "
			+ "(equipped '%s', arbiter offering '%s')" % [str(_game.get("equipped_tool")),
			str(_arbiter.call("prompt")) if _arbiter != null else "?"])
		return false
	for _category in 6:
		var cells := _visible_build_cells(menu)
		var wanted := -1
		var focused := -1
		var owner := _tree.root.gui_get_focus_owner()
		for i in cells.size():
			if _cell_id(cells[i]) == id:
				wanted = i
			if cells[i] == owner:
				focused = i
		if wanted >= 0:
			if focused < 0:
				_fail("the Build catalogue has no controller-focused cell")
				return false
			var action := &"ui_right" if wanted >= focused else &"ui_left"
			for _step in absi(wanted - focused):
				await _tap(action)
			await _tap(&"ui_accept")
			await _settle(8)
			if str(_game.get("pending_build")) != id:
				_fail("selected %s and the live pending selection is '%s'"
					% [id, str(_game.get("pending_build"))])
				return false
			return true
		# CONTROLLER-MAP: "LB/RB catalogue category". `build_menu.gd` reads
		# `menu_tab_left`/`menu_tab_right` and says in its own words that the
		# rotate triggers "used to double as category" and no longer do.
		await _tap(&"menu_tab_right")
		await _settle(8)
	_fail("could not reach '%s' through controller catalogue navigation" % id)
	return false


## Walk until nothing actionable is drawing the interact line.
func _clear_of_every_offer() -> bool:
	if _arbiter == null:
		return true
	# The creature goes away first. A deployed ally puts
	# `encounter_director.gd::_creature_control_offer()`'s "Put <name> away" on
	# the interact line for as long as it is out, and it FOLLOWS the player --
	# there is no standing clear of it. Recalling it is the same button a player
	# presses to get their own screen back before building.
	if _director != null and _director.call("ally_instance") != null \
			and _director.call("ally_body") != null:
		await _tap(&"creature_recall")
		await _settle(20)
	for attempt in 6:
		await _settle(4)
		var offer: Dictionary = _arbiter.call("winner")
		if not PROMPTS.is_actionable(offer):
			return true
		if attempt == 0:
			transcript.append("interact is spoken for by %s; stepping clear" % str(offer))
		var provider: Object = _arbiter.call("winning_provider")
		var from := (provider as Node3D).global_position if provider is Node3D \
			else _player.global_position - _forward()
		var away := _player.global_position - from
		away.y = 0.0
		if away.length() < 0.05:
			away = -_forward()
		var step := _player.global_position + away.normalized() * 3.0
		if not await _walk_to(step, "clear of the '%s' prompt" % str(offer.get("label", "")), 0.6):
			return false
	_fail("could not get clear of the interact line; Build cannot be opened from here. "
		+ "winner=%s provider=%s" % [str(_arbiter.call("winner")),
		str((_arbiter.call("winning_provider") as Node).name)
			if _arbiter.call("winning_provider") is Node else "<none>"])
	return false


func _hammer_in_hand() -> bool:
	if str(_game.get("equipped_tool")) == "hammer":
		return true
	var inventory: RefCounted = _game.get("inventory")
	if int(inventory.call("count", "hammer")) <= 0:
		_fail("the player has no hammer; the village's own gift is what opens build mode")
		return false
	var slot := int(_game.call("hotbar_slot_of", "hammer"))
	if slot < 0:
		slot = 3
		if not bool(_game.call("assign_hotbar", slot, "hammer")):
			_fail("the hammer could not be put on the quick bar")
			return false
	await _tap(HOTBAR_ACTIONS[slot])
	await _settle(8)
	if str(_game.get("equipped_tool")) != "hammer":
		_fail("the quick-bar press did not put the hammer in hand")
		return false
	return true


func _joy_binding_for(action: StringName) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return event
	return null


func _stow_piece() -> bool:
	if str(_game.get("pending_build")) == "":
		return true
	await _tap(&"build_cancel")
	await _settle(6)
	if str(_game.get("pending_build")) != "":
		_fail("Build Cancel did not stow the armed piece")
		return false
	return true


func _open_build_menu() -> Node:
	for node: Node in _tree.get_nodes_in_group(&"build_menu"):
		if node.has_method("is_open") and bool(node.call("is_open")):
			return node
	return null


func _visible_build_cells(menu: Node) -> Array[Button]:
	var cells: Array[Button] = []
	for node: Node in menu.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and button.is_visible_in_tree() and _cell_id(button) != "":
			cells.append(button)
	cells.sort_custom(func(a: Button, b: Button) -> bool:
		return a.global_position.y < b.global_position.y - 1.0 \
			or (absf(a.global_position.y - b.global_position.y) <= 1.0
				and a.global_position.x < b.global_position.x))
	return cells


func _cell_id(button: Button) -> String:
	for node: Node in button.find_children("*", "TextureRect", true, false):
		var texture := (node as TextureRect).texture
		if texture != null and texture.resource_path.contains("/buildables/"):
			return texture.resource_path.get_file().get_basename()
	return ""


func _forward() -> Vector3:
	return -(_rig.call("planar_basis") as Basis).z


## Travel through `stick_navigator.gd`, like every other continuous harness.
##
## GATEB-COORD. This used to point the stick at the target and hold it, which
## is the exact walker GATEB-PATH replaced everywhere else -- and it failed
## here for the same reason it failed at Mira's door: the Meadows has no
## navmesh, so "walk toward the point" means "walk into whatever is between
## here and the point". With three creature beds down around the build patch
## (owner directive 2026-08-23 §1) the beds are now obstacles to each other,
## and the straight walk to the second one stopped dead against the first:
##
##   controller movement could not reach the creature bed 2
##
## The navigator slides along what it is pressed against and picks the freer
## side, which is what gets past a placed bed, a camp, or a house wall.
func _walk_to(target: Vector3, purpose: String, close_enough: float = MOVE_EPSILON) -> bool:
	if _nav == null:
		_nav = NAVIGATOR.new(_tree, _player, _rig, Callable(self, "_move"))
	# From the leg's own length, not a flat number. `data/config/movement.json`
	# walks the trainer at 5 m/s, so a metre is about 12 physics frames; the
	# multiple leaves room for the detours the navigator spends getting round
	# what is in the way. A flat 900 frames is fifteen seconds, which is fine
	# for a bed three metres away and nothing like enough for the walk back
	# across the build patch.
	var budget := maxi(MOVE_FRAME_LIMIT,
		240 + int(_player.global_position.distance_to(target) * 60.0))
	var arrived: bool = await _nav.walk_to(target, budget, close_enough)
	_release_move()
	await _settle(3)
	if arrived:
		return true
	_fail("controller movement could not reach %s (stopped %.1fm short at %s)" % [
		purpose,
		Vector2(target.x - _player.global_position.x,
			target.z - _player.global_position.z).length(),
		str(_player.global_position.round())])
	return false


func _tap(action: StringName) -> void:
	var binding: InputEvent = null
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			binding = event
			break
	if binding == null:
		_fail("'%s' has no physical joypad binding" % action)
		return
	if binding is InputEventJoypadButton:
		var press := InputEventJoypadButton.new()
		press.button_index = (binding as InputEventJoypadButton).button_index
		press.pressed = true
		Input.parse_input_event(press)
		await _settle(2)
		var release := press.duplicate() as InputEventJoypadButton
		release.pressed = false
		Input.parse_input_event(release)
	else:
		var press := InputEventJoypadMotion.new()
		press.axis = (binding as InputEventJoypadMotion).axis
		press.axis_value = (binding as InputEventJoypadMotion).axis_value
		Input.parse_input_event(press)
		await _settle(2)
		var release := press.duplicate() as InputEventJoypadMotion
		release.axis_value = 0.0
		Input.parse_input_event(release)
	await _settle(3)


func _resolve_move_bindings() -> void:
	var right := _motion_for(&"move_right")
	var back := _motion_for(&"move_back")
	if right == null or back == null:
		_fail("movement needs physical joypad axes")
		return
	_move_x_axis = right.axis
	_move_x_sign = signf(right.axis_value)
	_move_y_axis = back.axis
	_move_y_sign = signf(back.axis_value)


func _motion_for(action: StringName) -> InputEventJoypadMotion:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion:
			return event as InputEventJoypadMotion
	return null


## Polled, not parsed. `player_controller.gd::_apply_movement()` reads
## `Input.get_vector(...)`, and a synthesized `InputEventJoypadMotion` does not
## reach that poll headlessly -- see `gate_a_build_segment.gd::
## _parse_move_stick()`'s own note for the measurement. Buttons stay parsed
## events, because those DO have to move Control focus.
func _move(x: float, y: float) -> void:
	Input.action_press(&"move_right", clampf(x, 0.0, 1.0))
	Input.action_press(&"move_left", clampf(-x, 0.0, 1.0))
	Input.action_press(&"move_back", clampf(y, 0.0, 1.0))
	Input.action_press(&"move_forward", clampf(-y, 0.0, 1.0))


func _release_move() -> void:
	for action: StringName in [&"move_right", &"move_left", &"move_back", &"move_forward"]:
		Input.action_release(action)


func _settle(frames: int) -> void:
	for _i in frames:
		await _tree.physics_frame


func _fail(message: String) -> void:
	failures.append(message)


func _result() -> Dictionary:
	_release_move()
	return {"passed": failures.is_empty(), "failures": failures.duplicate(),
		"transcript": transcript.duplicate()}
