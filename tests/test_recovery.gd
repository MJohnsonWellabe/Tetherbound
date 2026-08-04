extends "res://tests/test_case.gd"

## Fainting, and the two ways back from it.
##
## GAME_DESIGN.md §16 is the whole specification and it is four lines long. Every
## test here is one of them:
##
##   * a pal at 0 HP passes out and is unavailable
##   * it DOES NOT auto-revive with time in the field — and, crucially, not by a
##     fight ending either, which is what this build did until M6
##   * a special revival item brings it back, and is spent doing so
##   * a pal bed at home brings it back, over time
##
## Plus the two things that make those survivable rather than cruel: recovery
## survives a save and a reload, and the all-pals-down state reports itself
## instead of being a game that refuses every button.
##
## Pure logic, per docs/decisions/D02. The beds are real `RestStation`s built
## from the real `pieces.json` — the same trick `tests/test_stations.gd` uses —
## so these break if the DATA stops agreeing with the code and not only if the
## code does. Nothing here needs a scene; a resting pal's visible BODY does, and
## that is a smoke's job.

const RECOVERY := preload("res://scripts/pals/recovery.gd")
const HOME := preload("res://scripts/pals/home.gd")
const PARTY := preload("res://scripts/pals/party.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")
const INSTANCE := preload("res://scripts/pals/pal_instance.gd")
const STATION := preload("res://scripts/building/station.gd")
const DIRECTOR := preload("res://scripts/combat/encounter_director.gd")
const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const DEFS := preload("res://scripts/items/item_defs.gd")
## For data/config/combat.json, where the defenceless-trainer numbers live.
const MATH := preload("res://scripts/combat/combat_math.gd")


## A stand-in for a wild creature. `Hunt` takes an `Object`, keys its cooldowns
## by it and never asks what it is — the same deliberate ignorance a `RestStation`
## has about its sleepers — so the cheapest possible thing will do.
class Creature extends RefCounted:
	pass

const CATALOGUE := "res://data/building/pieces.json"
const PAL_BED := "pal_bed_straw"
const BED := "bed_simple"

const A_SPECIES := "starter_ground"

## Everything built by hand in a test, freed afterwards. `Node`s are not
## reference-counted and a test that leaks one leaks it for the whole run.
var _built: Array[Node] = []


func after_each() -> void:
	for node: Node in _built:
		if is_instance_valid(node):
			node.free()
	_built.clear()


# --- fixtures -------------------------------------------------------------

## A pal with no trait, so a random roll cannot move a number being asserted.
## `tests/test_party.gd` explains this at length; same reasoning.
func _pal(id: String = A_SPECIES) -> RefCounted:
	var pal: RefCounted = SPECIES.spawn(id)
	pal.assign_trait("")
	return pal


func _downed_pal() -> RefCounted:
	var pal := _pal()
	pal.take_damage(pal.max_hp * 2.0)
	return pal


func _party_of(count: int) -> RefCounted:
	var party: RefCounted = PARTY.new()
	for i in count:
		party.add(_pal())
	return party


func _pieces() -> Dictionary:
	var file := FileAccess.open(CATALOGUE, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	var out: Dictionary = {}
	if parsed is Dictionary:
		for id: String in (parsed as Dictionary).get("pieces", {}).keys():
			if not id.begins_with("_"):
				out[id] = (parsed as Dictionary)["pieces"][id]
	return out


## A real station from the real catalogue, standing at a real place.
func _station(piece_id: String, at: Vector3 = Vector3.ZERO) -> Node:
	var piece: Dictionary = _pieces().get(piece_id, {})
	var station: Node = STATION.create(piece)
	if station != null:
		station.call("setup", piece_id, STATION.config_of(piece), at)
		_built.append(station)
	return station


## A home with a trainer's bed and `pal_beds` pal beds beside it.
func _home(pal_beds: int = 1, at: Vector3 = Vector3.ZERO) -> Node:
	var home: Node = HOME.new()
	_built.append(home)
	home.call("register", _station(BED, at))
	for i in pal_beds:
		home.call("register", _station(PAL_BED, at + Vector3(2.0 + float(i) * 2.0, 0.0, 0.0)))
	return home


func _recovery(party: RefCounted, home: Node) -> Node:
	var recovery: Node = RECOVERY.new()
	_built.append(recovery)
	recovery.call("bind", party, home, null)
	return recovery


## Run `seconds` of game time through recovery in sixty-hertz steps, the way the
## game would. One big delta would hide an ordering bug — a revive that only
## works when the whole wait arrives in a single frame is not a recovery system.
func _run(recovery: Node, seconds: float) -> void:
	var step := 1.0 / 60.0
	var elapsed := 0.0
	while elapsed < seconds:
		recovery.call("tick", step)
		elapsed += step


# --- a faint is real ------------------------------------------------------

func test_a_pal_at_zero_hp_is_down_and_unavailable() -> void:
	# §16, the first two lines. Everything else in this file is only interesting
	# because these two are true.
	var pal := _pal()
	assert_true(pal.is_available(), "a fresh pal should be deployable")
	assert_true(pal.take_damage(pal.max_hp * 2.0), "the killing blow should report itself")
	assert_true(pal.fainted)
	assert_false(pal.is_available(), "a fainted pal is unavailable")
	assert_almost_eq(pal.hp, 0.0, 0.001)


func test_a_fainted_pal_keeps_its_level_and_its_xp() -> void:
	# The design documents do not settle this. §16 lists what a faint costs —
	# consciousness, availability, and the time or the item to undo it — and
	# progression is not on the list; §22 settles the same question for the PLAYER
	# ("no XP loss, no level loss"). Taking levels off a pal you cannot replace,
	# in a party of five, would be a second punishment nobody asked for.
	var pal := _pal()
	pal.grant_xp(pal.xp_for_next_level() + 7)
	var level: int = pal.level
	var xp: int = pal.xp
	var attack: float = pal.attack
	pal.take_damage(pal.max_hp * 2.0)
	assert_true(pal.fainted)
	assert_eq(pal.level, level, "fainting took a level")
	assert_eq(pal.xp, xp, "fainting took progress towards the next level")
	assert_almost_eq(pal.attack, attack, 0.001, "fainting changed what the pal is worth")


func test_healing_cannot_undo_a_faint() -> void:
	# The back door §16 forbids. `heal()` is for a pal that is still standing;
	# `revive()` is the only way out of `fainted`, and every caller of it has paid
	# either an item or a stay in a bed.
	var pal := _downed_pal()
	assert_almost_eq(pal.heal(9999.0), 0.0, 0.001, "a fainted pal was healed")
	assert_true(pal.fainted, "healing cleared the faint flag")
	assert_almost_eq(pal.hp, 0.0, 0.001)


func test_a_revived_pal_never_comes_back_on_nothing() -> void:
	# A pal revived onto zero HP faints again to the next scratch, which reads as
	# the revive having failed.
	var pal := _downed_pal()
	assert_true(pal.revive(0.0))
	assert_false(pal.fainted)
	assert_true(pal.hp > 0.0, "revived onto %f HP" % pal.hp)
	assert_false(pal.revive(0.5), "a standing pal cannot be revived again")


# --- a fight ending is not a cure -----------------------------------------

func test_a_fight_ending_does_not_heal_the_party() -> void:
	# THE REGRESSION GUARD FOR THIS WHOLE MILESTONE.
	#
	# `encounter_director._on_combat_exited()` used to finish by restoring every
	# pal in the party, with a comment admitting it was a placeholder for M6. It
	# is the reason §16 was unreachable: nothing in the game could leave a pal in
	# the state four separate guards test for. Asserted against the source because
	# the function needs a manager, a party and a world to be called at all, and a
	# rule this easy to reintroduce deserves a check that cannot be satisfied by
	# accident.
	var source := FileAccess.get_file_as_string("res://scripts/combat/encounter_director.gd")
	assert_false(source.is_empty(), "could not read the encounter director")
	assert_false(source.contains("heal_fully"),
		"the director heals pals again; §16 says recovery comes from an item or a bed")
	assert_false(source.contains(".heal("),
		"the director heals pals again; recovery belongs to scripts/pals/recovery.gd")


func test_one_pal_going_down_does_not_take_the_others_with_it() -> void:
	# The same rule from the pal's side, and without a scene: the only things that
	# touch `fainted` are damage and the two revives. A roster that goes through a
	# fight and comes out the other side is exactly the roster it was.
	var party := _party_of(3)
	var deployed: RefCounted = party.at(0)
	deployed.take_damage(deployed.max_hp * 2.0)
	var roster: Array = party.members()
	assert_true((roster[0] as RefCounted).fainted, "the pal that lost is not down")
	assert_eq(PARTY.standing_in(roster).size(), 2, "losing one pal took others with it")


# --- unavailable, everywhere it matters -----------------------------------

func test_a_downed_pal_cannot_be_switched_to() -> void:
	# `combat_manager.Switchboard` steps OVER a fainted member rather than landing
	# on one — §16's "unavailable" inside a fight.
	var party := _party_of(3)
	var board: RefCounted = MANAGER.Switchboard.new()
	board.configure({"cooldown": 0.0})
	party.at(1).take_damage(party.at(1).max_hp * 2.0)
	assert_eq(board.target(party, 1), 2, "the switch landed on the pal that is down")

	party.at(2).take_damage(party.at(2).max_hp * 2.0)
	assert_eq(board.target(party, 1), -1, "there is nobody left to switch to")
	assert_eq(board.refusal(party, 1), MANAGER.Switchboard.REFUSED_ALL_DOWN,
		"a switch with nobody standing must say so rather than fail quietly")


func test_the_party_knows_when_everyone_is_down() -> void:
	var party := _party_of(2)
	assert_false(party.all_down(), "a healthy party is not down")
	party.at(0).take_damage(party.at(0).max_hp * 2.0)
	assert_false(party.all_down(), "one pal down is not the whole party down")
	assert_eq(party.first_standing_index(), 1)
	party.at(1).take_damage(party.at(1).max_hp * 2.0)
	assert_true(party.all_down(), "every pal is fainted and the party says otherwise")
	assert_eq(party.first_standing_index(), -1)
	assert_eq(party.standing().size(), 0)


func test_an_empty_party_is_not_the_same_as_a_party_that_is_all_down() -> void:
	# Owning nothing and having lost everything are different situations with
	# different things to say. A new player told to go and rest pals they do not
	# have is being sent to look for a bug.
	assert_false(PARTY.new().all_down(), "an empty party reported itself as wiped out")
	assert_false(PARTY.none_standing([]))


# --- the player is told, not stonewalled ----------------------------------

func test_the_all_down_prompt_names_both_ways_out() -> void:
	# The moment this milestone exists to create: five unconscious creatures and a
	# trainer standing in a field. §16 gives exactly two answers and the player has
	# to be handed both of them, because every other button in the game is now
	# refusing them.
	var party := _party_of(2)
	for pal: Variant in party.members():
		(pal as RefCounted).take_damage((pal as RefCounted).max_hp * 2.0)

	var line: String = DIRECTOR.prompt_for(party.active(), party.members(), "Meadow Hopper")
	assert_false(line.is_empty(), "a wiped-out party got no message at all")
	assert_true(line.to_lower().contains("bed"), "the prompt never mentions a bed: '%s'" % line)
	assert_true(line.contains(DEFS.display_name("revival_draught")),
		"the prompt never names the revival item: '%s'" % line)
	assert_false(line.contains("Engage"),
		"the prompt still offers a fight nobody can take: '%s'" % line)


func test_a_downed_deployed_pal_points_at_the_party_menu() -> void:
	# One pal down out of several is a different message: there IS something to
	# do, and it is one button away.
	var party := _party_of(3)
	party.at(0).take_damage(party.at(0).max_hp * 2.0)
	var line: String = DIRECTOR.prompt_for(party.active(), party.members(), "Meadow Hopper")
	assert_true(line.contains(party.at(0).display()), "the message does not say which pal: '%s'" % line)
	assert_true(line.contains("[Y]"), "the message does not say how to send another out: '%s'" % line)


func test_a_healthy_party_still_gets_the_engage_prompt() -> void:
	# The regression half: none of the above may swallow the ordinary line.
	var party := _party_of(2)
	assert_eq(DIRECTOR.prompt_for(party.active(), party.members(), "Meadow Hopper"),
		DIRECTOR.PROMPT_ENGAGE % "Meadow Hopper")
	assert_eq(DIRECTOR.prompt_for(party.active(), party.members(), ""), "",
		"a prompt appeared with nothing in range to engage")


# --- route one: the revival item ------------------------------------------

func test_the_revival_item_exists_as_an_item() -> void:
	# §16 calls it an item, so it is one — in items.json, with a name and a stack
	# limit, rather than a special case hidden in the recovery code.
	var id: String = _recovery(_party_of(1), _home()).call("revival_item")
	assert_true(DEFS.has(id), "the revival item '%s' is not in items.json" % id)
	assert_false(DEFS.display_name(id).is_empty())
	assert_true(DEFS.stack_limit(id) >= 1)
	assert_false(DEFS.is_durable(id), "the revival item is not a tool")


func test_a_revival_item_brings_a_pal_back_and_is_consumed() -> void:
	var party := _party_of(1)
	var recovery := _recovery(party, _home())
	var pal: RefCounted = party.at(0)
	pal.take_damage(pal.max_hp * 2.0)

	var before: int = int(recovery.call("revival_items_left"))
	assert_true(before > 0, "the player starts with no revival items; the route is unreachable")
	assert_true(bool(recovery.call("revive_with_item", pal)), "the draught did nothing")
	assert_false(pal.fainted, "the pal is still down after a revival item")
	assert_true(pal.hp > 0.0)
	assert_eq(int(recovery.call("revival_items_left")), before - 1, "the item was not consumed")


func test_a_revival_item_is_not_spent_on_a_pal_that_is_standing() -> void:
	# Checked against the creature BEFORE it is consumed, so a misfired button
	# costs nothing.
	var party := _party_of(1)
	var recovery := _recovery(party, _home())
	var before: int = int(recovery.call("revival_items_left"))
	assert_false(bool(recovery.call("revive_with_item", party.at(0))))
	assert_eq(str(recovery.call("last_refusal")), RECOVERY.REFUSED_NOT_DOWN)
	assert_eq(int(recovery.call("revival_items_left")), before, "a wasted press ate an item")


func test_the_revival_items_run_out() -> void:
	# There is no recipe and no drop table. That is the point: the draughts are
	# finite, and running out is what makes the pal beds matter.
	var party := _party_of(1)
	var recovery := _recovery(party, _home())
	var pal: RefCounted = party.at(0)
	var stock: int = int(recovery.call("revival_items_left"))
	for i in stock:
		pal.take_damage(pal.max_hp * 2.0)
		assert_true(bool(recovery.call("revive_with_item", pal)), "draught %d refused" % i)
	pal.take_damage(pal.max_hp * 2.0)
	assert_false(bool(recovery.call("revive_with_item", pal)), "the stock never ran out")
	assert_eq(str(recovery.call("last_refusal")), RECOVERY.REFUSED_NO_ITEM)
	assert_true(pal.fainted, "a refused revive brought the pal back anyway")


# --- route two: the pal bed at home ---------------------------------------

func test_resting_at_a_bed_revives_a_pal_over_time_and_not_instantly() -> void:
	# The heart of §16's second route. Instant recovery at a bed is the blanket
	# heal again with extra steps, so the wait is asserted as hard as the revival.
	var party := _party_of(1)
	var recovery := _recovery(party, _home())
	var pal: RefCounted = party.at(0)
	pal.take_damage(pal.max_hp * 2.0)

	assert_true(bool(recovery.call("rest", pal)), "a fainted pal could not be put to bed")
	assert_true(bool(recovery.call("is_resting", pal)))

	var wait: float = float(recovery.call("revive_seconds"))
	assert_true(wait > 0.0, "recovery at a bed is instant; the faint costs nothing")
	_run(recovery, wait * 0.5)
	assert_true(pal.fainted, "the pal woke up halfway through its recovery")

	_run(recovery, wait * 0.5 + 0.5)
	assert_false(pal.fainted, "the pal never came round at all")
	assert_true(pal.hp > 0.0)
	assert_true(pal.hp < pal.max_hp, "a bed revived the pal straight to full health")


func test_a_bed_goes_on_healing_after_the_pal_is_conscious_and_then_lets_it_go() -> void:
	# §16: beds also speed normal HP recovery. And a pal that is finished gets up,
	# rather than occupying one of five beds forever.
	var party := _party_of(1)
	var recovery := _recovery(party, _home())
	var pal: RefCounted = party.at(0)
	pal.take_damage(pal.max_hp * 0.6)
	var hurt: float = pal.hp

	assert_true(bool(recovery.call("rest", pal)))
	_run(recovery, 1.0)
	assert_true(pal.hp > hurt, "a bed did not heal a hurt pal at all")
	assert_true(bool(recovery.call("is_resting", pal)), "the pal got up before it was healed")

	_run(recovery, 120.0)
	assert_almost_eq(pal.hp, pal.max_hp, 0.001, "the pal never reached full health")
	assert_false(bool(recovery.call("is_resting", pal)), "a fully healed pal is still in its bed")


func test_a_pal_at_full_health_is_not_put_to_bed() -> void:
	var party := _party_of(1)
	var recovery := _recovery(party, _home())
	assert_false(bool(recovery.call("rest", party.at(0))))
	assert_eq(str(recovery.call("last_refusal")), RECOVERY.REFUSED_NOTHING_TO_DO)


func test_one_pal_per_bed_and_the_refusal_says_to_build_another() -> void:
	# Capacity is one, by data. Five pals therefore need five beds, and the answer
	# to a full base is a refusal the player can act on rather than a queue.
	var party := _party_of(2)
	var recovery := _recovery(party, _home(1))
	for pal: Variant in party.members():
		(pal as RefCounted).take_damage((pal as RefCounted).max_hp * 2.0)

	assert_true(bool(recovery.call("rest", party.at(0))))
	assert_false(bool(recovery.call("rest", party.at(1))), "two pals fitted in one bed")
	assert_eq(str(recovery.call("last_refusal")), RECOVERY.REFUSED_NO_BED)

	var roomier := _recovery(party, _home(2, Vector3(60.0, 0.0, 0.0)))
	assert_true(bool(roomier.call("rest", party.at(1))), "a second bed did not take the second pal")


func test_a_pal_bed_is_never_told_to_work() -> void:
	# CLAUDE.md, twice over: pals do not perform base jobs. Recovery is the system
	# most able to break that by accident, because "put creatures in buildings" is
	# the shape of a work roster. `begin_rest` is called INTO the bed from here and
	# the bed answers questions; it is never handed a task and produces nothing.
	var bed := _station(PAL_BED)
	for verb: String in ["assign", "work", "produce", "staff", "set_worker", "output"]:
		assert_false(bed.has_method(verb), "a pal bed grew a '%s' method" % verb)
	assert_false(_recovery(_party_of(1), _home()).has_method("assign"),
		"recovery grew an assignment verb")


# --- home -----------------------------------------------------------------

func test_without_a_bed_of_your_own_there_is_no_home() -> void:
	# §16 says a pal recovers in its pal bed AT HOME, and §20's tutorial has the
	# player build shelter and a bed first. A pal bed dropped in a field is not a
	# recovery point, and the refusal has to say which of the two is missing.
	var home: Node = HOME.new()
	_built.append(home)
	assert_false(bool(home.call("has_home")))
	assert_eq(home.call("home_point"), HOME.NOWHERE, "a home appeared without a bed in it")

	home.call("register", _station(PAL_BED, Vector3(3.0, 0.0, 0.0)))
	assert_false(bool(home.call("has_home")), "a pal bed alone made a home")
	assert_eq(home.call("pal_beds_at_home").size(), 0, "a pal bed was at a home that does not exist")

	var party := _party_of(1)
	var recovery := _recovery(party, home)
	party.at(0).take_damage(party.at(0).max_hp * 2.0)
	assert_false(bool(recovery.call("rest", party.at(0))))
	assert_eq(str(recovery.call("last_refusal")), RECOVERY.REFUSED_NO_HOME)


func test_the_most_recently_placed_bed_is_home() -> void:
	# Two beds. The last one placed wins — the rule every game in this genre has
	# already taught the player, and the only one that survives a reload for free,
	# because `structures.load_data()` replays placements in order.
	var home: Node = HOME.new()
	_built.append(home)
	home.call("register", _station(BED, Vector3(10.0, 0.0, 0.0)))
	assert_eq(home.call("home_point"), Vector3(10.0, 0.0, 0.0))
	home.call("register", _station(BED, Vector3(-40.0, 0.0, 5.0)))
	assert_eq(home.call("home_point"), Vector3(-40.0, 0.0, 5.0), "building a second bed did not move home")
	assert_eq(home.call("respawn_point"), Vector3(-40.0, 0.0, 5.0), "§20: the bed is the respawn point")


func test_a_pal_bed_across_the_meadow_is_not_at_home() -> void:
	var home := _home(1)
	var far := _station(PAL_BED, Vector3(400.0, 0.0, 0.0))
	home.call("register", far)
	assert_eq(home.call("pal_beds").size(), 2, "both pal beds exist")
	assert_eq(home.call("pal_beds_at_home").size(), 1, "a pal bed 400m away counted as home")
	assert_false(bool(home.call("is_at_home", Vector3(400.0, 0.0, 0.0))))
	assert_true(bool(home.call("is_at_home", Vector3.ZERO)))


func test_demolishing_the_bed_a_pal_is_asleep_in_gets_it_up() -> void:
	# The crash this avoids is a pal holding a freed node. The design point is
	# that recovery stops rather than continuing against a bed that is gone.
	var party := _party_of(1)
	var home := _home(1)
	var recovery := _recovery(party, home)
	var pal: RefCounted = party.at(0)
	pal.take_damage(pal.max_hp * 2.0)
	assert_true(bool(recovery.call("rest", pal)))

	var bed: Node = home.call("pal_beds_at_home")[0]
	bed.call("release")
	home.call("forget", bed)
	recovery.call("tick", 1.0 / 60.0)

	assert_false(bool(recovery.call("is_resting", pal)), "the pal is still asleep in a bed that is gone")
	assert_true(pal.fainted, "a demolished bed finished a recovery it never paid for")


# --- bringing them home ---------------------------------------------------

func test_walking_home_puts_a_hurt_pal_to_bed_and_leaving_gets_it_up() -> void:
	# There is no rest button — the verbs a screen can offer live in scripts/ui
	# and the input map is a file of its own. The trigger is the one the player
	# already performs, and it is symmetrical: a pal cannot be asleep in a bed the
	# trainer has walked two hundred metres away from.
	var party := _party_of(1)
	var home := _home(1)
	var recovery := _recovery(party, home)
	var pal: RefCounted = party.at(0)
	pal.take_damage(pal.max_hp * 0.5)

	recovery.call("attend", Vector3(200.0, 0.0, 0.0))
	assert_false(bool(recovery.call("is_resting", pal)), "a pal went to bed from across the meadow")

	recovery.call("attend", Vector3(1.0, 0.0, 1.0))
	assert_true(bool(recovery.call("is_resting", pal)), "coming home did not put a hurt pal to bed")

	recovery.call("attend", Vector3(200.0, 0.0, 0.0))
	assert_false(bool(recovery.call("is_resting", pal)), "leaving home left a pal asleep behind you")


func test_the_fainted_get_the_bed_before_the_merely_scratched() -> void:
	# One bed, two pals, and only one of them is unconscious. Spending the bed on
	# the scratched one would leave the other down with nothing left to recover in.
	var party := _party_of(2)
	var recovery := _recovery(party, _home(1))
	party.at(0).take_damage(party.at(0).max_hp * 0.2)
	party.at(1).take_damage(party.at(1).max_hp * 2.0)

	recovery.call("attend", Vector3.ZERO)
	assert_true(bool(recovery.call("is_resting", party.at(1))), "the unconscious pal did not get the bed")
	assert_false(bool(recovery.call("is_resting", party.at(0))), "the scratched pal took the only bed")


# --- persistence ----------------------------------------------------------

func test_a_pal_left_resting_is_still_resting_after_a_reload() -> void:
	# `SaveDirector` autosaves on a timer, so without this a player who stood
	# still through an autosave and a reload would find §16's cost quietly
	# cancelled — or, worse, their pal woken and still unconscious.
	var party := _party_of(2)
	var home := _home(2)
	var recovery := _recovery(party, home)
	var pal: RefCounted = party.at(1)
	pal.take_damage(pal.max_hp * 2.0)
	assert_true(bool(recovery.call("rest", pal)))
	_run(recovery, 10.0)
	var slept: float = float(recovery.call("seconds_rested", pal))
	assert_true(slept >= 9.9, "ten seconds of resting recorded %.2f" % slept)

	var records: Dictionary = recovery.call("save_data")

	# A second session: the same party (restored through its own domain), the same
	# beds (restored through structures), and a recovery that has to find both.
	var reloaded_party: RefCounted = PARTY.from_records(party.to_records())
	var reloaded_home := _home(2)
	var reloaded := _recovery(reloaded_party, reloaded_home)
	reloaded.call("load_data", records)

	var back: RefCounted = reloaded_party.at(1)
	assert_true(back.fainted, "the pal came back conscious; the save cancelled the recovery")
	assert_true(bool(reloaded.call("is_resting", back)), "the pal was not put back in its bed")
	assert_almost_eq(float(reloaded.call("seconds_rested", back)), slept, 0.01,
		"the reloaded pal restarted its recovery from zero")

	# And it finishes on the other side of the reload rather than resetting.
	_run(reloaded, float(reloaded.call("revive_seconds")) - slept + 0.5)
	assert_false(back.fainted, "the restored recovery never completed")


func test_the_revival_items_survive_a_reload() -> void:
	var party := _party_of(1)
	var recovery := _recovery(party, _home())
	var pal: RefCounted = party.at(0)
	pal.take_damage(pal.max_hp * 2.0)
	recovery.call("revive_with_item", pal)
	var left: int = int(recovery.call("revival_items_left"))

	var reloaded := _recovery(party, _home())
	reloaded.call("load_data", recovery.call("save_data"))
	assert_eq(int(reloaded.call("revival_items_left")), left,
		"a reload handed the player their spent draughts back")


func test_a_save_whose_party_shrank_loses_one_nap_and_not_the_save() -> void:
	# Save files are text files on a Windows machine, and a pal can be released
	# between one session and the next.
	var party := _party_of(2)
	var recovery := _recovery(party, _home(2))
	for pal: Variant in party.members():
		(pal as RefCounted).take_damage((pal as RefCounted).max_hp * 2.0)
		recovery.call("rest", pal as RefCounted)
	var records: Dictionary = recovery.call("save_data")
	assert_eq((records["resting"] as Array).size(), 2)

	# One pal fewer, and the one that is left comes back as it was saved: down.
	var smaller := _party_of(1)
	smaller.at(0).take_damage(smaller.at(0).max_hp * 2.0)
	var reloaded := _recovery(smaller, _home(2))
	reloaded.call("load_data", records)
	assert_eq(int(reloaded.call("resting_count")), 1,
		"a record pointing past the end of the party was not dropped cleanly")


# --- with nothing left to fight with, the meadow comes for you -------------
#
# An OWNER AMENDMENT to GAME_DESIGN.md §14's trainer-safety rule, for the case
# §16 left open: every owned pal fainted and the player unharmed. The trainer is
# not stopped and not teleported, and still cannot fight — but they are now a
# target, and getting home is the answer.
#
# `encounter_director.Hunt` is where that is decided, and it is decidable from a
# clock, a distance and a flag, so all of it is provable here. The one rule that
# absolutely must hold is the last one: a player who heals a pal and is still
# being chased will read the game as broken.


func _hunt(overrides: Dictionary = {}) -> RefCounted:
	# Built from the SHIPPING config, so these break if the data stops agreeing
	# with the code and not only if the code does.
	var cfg: Dictionary = MATH.config().get("defenceless", {}).duplicate(true)
	for key: String in overrides.keys():
		cfg[key] = overrides[key]
	var hunt: RefCounted = DIRECTOR.Hunt.new()
	hunt.configure(cfg)
	return hunt


func test_a_defenceless_trainer_is_not_hit_the_instant_the_last_pal_drops() -> void:
	# There MUST be a head start. Being swarmed the moment you lose, with no
	# chance to run, is a different and worse experience from being hunted while
	# you retreat.
	var hunt := _hunt()
	assert_true(hunt.grace_seconds > 0.0, "there is no grace period at all")
	assert_false(hunt.tick(1.0 / 60.0, true), "a blow was allowed on the first frame")
	assert_true(hunt.grace_left() > 0.0)

	var open := false
	for i in int(hunt.grace_seconds * 60.0) + 4:
		open = hunt.tick(1.0 / 60.0, true)
	assert_true(open, "the grace period never ran out; the trainer is never in danger")


func test_a_hunter_strikes_on_a_cooldown_rather_than_every_frame() -> void:
	var hunt := _hunt()
	var creature := Creature.new()
	while not hunt.tick(1.0 / 60.0, true):
		pass

	assert_true(hunt.may_strike(creature, true, 1.0), "a hunter in reach could not strike")
	hunt.struck(creature)
	assert_false(hunt.may_strike(creature, true, 1.0), "the same creature struck twice in a frame")

	var waited := 0.0
	while not hunt.may_strike(creature, true, 1.0) and waited < hunt.strike_interval * 3.0:
		hunt.tick(1.0 / 60.0, true)
		waited += 1.0 / 60.0
	assert_true(waited >= hunt.strike_interval - 0.05,
		"the cooldown was %.2fs, not the configured %.2fs" % [waited, hunt.strike_interval])
	assert_true(hunt.may_strike(creature, true, 1.0), "the hunter never came back for a second blow")


func test_a_hunter_out_of_reach_lands_nothing() -> void:
	var hunt := _hunt()
	while not hunt.tick(1.0 / 60.0, true):
		pass
	assert_true(hunt.strike_range > 0.0)
	assert_false(hunt.may_strike(Creature.new(), true, hunt.strike_range + 0.5),
		"a creature reached the trainer from outside its reach")
	assert_true(hunt.may_strike(Creature.new(), true, hunt.strike_range - 0.1))


func test_only_the_dangerous_species_hunts_a_defenceless_trainer() -> void:
	# §14: peaceful pals never initiate. A Meadow Hopper mauling you the moment
	# you are weak would read as the whole meadow turning rather than as the
	# Thornback being dangerous. Which species hunt is DATA — `hunters` in
	# data/config/combat.json — and the shipping answer is the aggressive ones.
	var hunt := _hunt()
	while not hunt.tick(1.0 / 60.0, true):
		pass
	assert_true(hunt.only_aggressive,
		"every species hunts a defenceless trainer; the peaceful ones are supposed not to")
	assert_false(hunt.may_strike(Creature.new(), false, 0.5), "a peaceful creature attacked the trainer")
	assert_true(hunt.may_strike(Creature.new(), true, 0.5))

	# And the policy really is data, not a constant in the code.
	var everything := _hunt({"hunters": DIRECTOR.Hunt.HUNTERS_ALL})
	while not everything.tick(1.0 / 60.0, true):
		pass
	assert_true(everything.may_strike(Creature.new(), false, 0.5),
		"the 'all' policy in combat.json changes nothing")


func test_the_hunt_ends_the_moment_a_pal_is_available_again() -> void:
	# THE RULE THAT MATTERS MOST. A player who has just spent a revival draught
	# and is still being chased will read the game as broken, and would be right.
	var party := _party_of(2)
	var recovery := _recovery(party, _home())
	for pal: Variant in party.members():
		(pal as RefCounted).take_damage((pal as RefCounted).max_hp * 2.0)

	var hunt := _hunt()
	var open := false
	for i in int(hunt.grace_seconds * 60.0) + 4:
		open = hunt.tick(1.0 / 60.0, PARTY.none_standing(party.members()))
	assert_true(open, "a party with every pal fainted was never in danger")

	var creature := Creature.new()
	assert_true(hunt.may_strike(creature, true, 0.5))
	hunt.struck(creature)

	# One draught, one pal on its feet.
	assert_true(bool(recovery.call("revive_with_item", party.at(1))))
	assert_false(PARTY.none_standing(party.members()))
	assert_false(hunt.tick(1.0 / 60.0, PARTY.none_standing(party.members())),
		"the trainer is still being hunted with a pal standing")
	assert_almost_eq(hunt.grace_left(), hunt.grace_seconds, 0.001,
		"the head start was not given back; losing the pal again would be instant")


func test_recovering_a_pal_at_a_bed_ends_the_hunt_too() -> void:
	# The other of §16's two routes, and it has to end the hunt exactly the same
	# way — otherwise walking home and resting is a fix that does not read as one.
	var party := _party_of(1)
	var recovery := _recovery(party, _home())
	var pal: RefCounted = party.at(0)
	pal.take_damage(pal.max_hp * 2.0)

	var hunt := _hunt()
	while not hunt.tick(1.0 / 60.0, PARTY.none_standing(party.members())):
		pass

	recovery.call("rest", pal)
	_run(recovery, float(recovery.call("revive_seconds")) + 0.5)
	assert_false(pal.fainted, "the pal never came round")
	assert_false(hunt.tick(1.0 / 60.0, PARTY.none_standing(party.members())),
		"a pal recovered at its bed did not call the hunt off")


func test_a_hunted_trainer_actually_bleeds() -> void:
	# The damage lands on the trainer's real health, through the one entry point
	# anything other than a fall may use.
	var vitals: RefCounted = load("res://scripts/player/player_vitals.gd").new()
	vitals.configure({})
	var full: float = vitals.health
	var hunt := _hunt()
	assert_true(hunt.damage > 0.0, "a blow from a hunter does no damage")

	assert_almost_eq(vitals.take_damage(hunt.damage), hunt.damage, 0.001)
	assert_almost_eq(vitals.health, full - hunt.damage, 0.001, "the trainer did not lose health")
	assert_true(vitals.health_fraction() < 1.0, "the health bar would not move")

	# It kills, eventually. Death itself is M9's — this only proves the state is
	# survivable-until-it-is-not rather than cosmetic.
	for i in 200:
		vitals.take_damage(hunt.damage)
	assert_true(vitals.is_dead(), "a trainer can be hunted forever and never fall")
	assert_almost_eq(vitals.take_damage(hunt.damage), 0.0, 0.001, "a downed trainer kept taking damage")


func test_the_trainer_still_cannot_fight_back() -> void:
	# CLAUDE.md, hard rule: "Human cannot fight." The amendment is that the
	# trainer can be HURT, and that is the whole of it — no weapon, no attack, no
	# way into Combat Mode for the human. This is the guard on the difference.
	var player: Node = load("res://scripts/player/player_controller.gd").new()
	_built.append(player)
	assert_true(player.has_method("hurt"), "nothing can damage the trainer at all")
	for verb: String in ["attack", "swing", "fire", "strike", "equip_weapon", "deal_damage"]:
		assert_false(player.has_method(verb),
			"the trainer grew a '%s' method; the human does not fight" % verb)


func test_a_hunted_trainer_is_told_to_run() -> void:
	# The message changes when something is actually on you: reading a menu is no
	# longer the first thing to do.
	var party := _party_of(1)
	party.at(0).take_damage(party.at(0).max_hp * 2.0)
	var line: String = DIRECTOR.prompt_for(party.active(), party.members(), "", "Thornback")
	assert_true(line.contains("Thornback"), "the prompt does not say what is on you: '%s'" % line)
	assert_true(line.to_lower().contains("run"), "the prompt does not say to run: '%s'" % line)
	assert_true(line.contains(DEFS.display_name("revival_draught")),
		"the prompt stopped naming the way out: '%s'" % line)


func test_every_hunt_number_comes_from_data() -> void:
	var cfg: Dictionary = MATH.config().get("defenceless", {})
	for key: String in [
		"enabled", "hunters", "grace_seconds", "strike_range", "strike_interval", "damage",
	]:
		assert_true(cfg.has(key), "data/config/combat.json has no defenceless.%s" % key)
	assert_true(float(cfg["grace_seconds"]) > 0.0,
		"no head start: the trainer is hit the instant their last pal drops")
	assert_true(float(cfg["damage"]) > 0.0, "being hunted is cosmetic")


# --- the tunables are tunable ---------------------------------------------

func test_every_recovery_number_comes_from_data() -> void:
	# CLAUDE.md: tunables live in data/config. "Recovering takes too long" and
	# "fainting costs nothing" are the two things the owner is most likely to say
	# about this system, and both have to be answerable without touching code.
	var config: Dictionary = INSTANCE.config().get("recovery", {})
	for key: String in [
		"bed_revive_seconds", "bed_revive_hp_fraction", "bed_hp_per_second",
		"home_radius", "home_leave_slack", "revival_item",
		"revival_item_hp_fraction", "starting_revival_items",
	]:
		assert_true(config.has(key), "data/config/party.json has no recovery.%s" % key)
	assert_true(float(config["bed_revive_seconds"]) > 0.0,
		"a bed that revives instantly is the blanket heal with extra steps")
	assert_true(float(config["bed_revive_hp_fraction"]) < 1.0,
		"a bed that revives to full health makes its own healing pointless")
