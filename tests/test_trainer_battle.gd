extends TestCase

## M13 and M14: Team Tether, the Warden, and the legendary.
##
## Scope, per D02: pure logic and data. The team's order, the tether's effect on
## the numbers, the rules the milestone is graded on, and the shape of the data
## the whole thing is authored in. Whether the Warden READS as a boss is a
## question for `tools/preview_warden.gd` and a pair of eyes, and no assertion
## here pretends otherwise.
##
## Several of these read a source file and assert about its text. That is not the
## normal way to test and it is deliberate in exactly two situations, both of
## which this milestone is full of:
##
##   * A rule that is enforced by an ARGUMENT PASSED, not by a value returned.
##     "Trainer-owned pals cannot be caught" was written, documented and unit
##     tested for four milestones while every caller passed `false` for the
##     argument that would have enforced it. A test of `can_be_caught` proves
##     nothing about that; a test that the call sites pass the real answer does.
##   * A rule about what must NOT be added. "Do not make the boss hard with a
##     bigger health bar" cannot be asserted by calling anything, because the
##     failure is a key somebody adds to a JSON file next year.

const CATCH := preload("res://scripts/combat/catch_math.gd")
const PARTY := preload("res://scripts/pals/party.gd")
const CEREMONY := preload("res://scripts/pals/release_ceremony.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")
const PAL := preload("res://scripts/pals/pal_instance.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")

const DATA := preload("res://scripts/trainers/tether_data.gd")
const ROSTER := preload("res://scripts/trainers/tether_roster.gd")
const BATTLE := preload("res://scripts/trainers/trainer_battle.gd")
const TETHER_PAL := preload("res://scripts/trainers/tether_pal.gd")

const MANAGER_SOURCE := "res://scripts/combat/combat_manager.gd"
const DIRECTOR_SOURCE := "res://scripts/combat/encounter_director.gd"
const TRAINER_SOURCE := "res://scripts/trainers/tether_trainer.gd"
const OFFER_SOURCE := "res://scripts/trainers/legendary_offer.gd"
const WILD_SOURCE := "res://scripts/pals/wild_pal.gd"

const MOUNT_PATH := "res://scripts/pals/mount.gd"

## Every trainer on the road, by id. Read from the route rather than listed here,
## so adding a fourth trainer puts it under every rule below automatically.
var _trainer_ids: Array = []


func before_each() -> void:
	ROSTER.register()
	_trainer_ids = []
	for entry: Variant in DATA.route_posts():
		_trainer_ids.append(str((entry as Dictionary).get("trainer", "")))


func _source(path: String) -> String:
	return FileAccess.get_file_as_string(path)


## A file with its comments removed.
##
## Every source assertion below is about what the CODE does, and this project
## comments heavily enough that a naive `contains()` matches the paragraph
## explaining a rule as readily as the line enforcing it — three of these tests
## failed on their own explanations the first time they ran. Documentation
## describing a hazard must not read as the hazard.
func _code(path: String) -> String:
	var out := ""
	for line in _source(path).split("\n"):
		if line.strip_edges().begins_with("#"):
			continue
		out += line + "\n"
	return out


# --- the hard rule ----------------------------------------------------------

func test_catch_math_refuses_a_creature_somebody_else_owns() -> void:
	# The rule itself, which has always been true and has never been reachable.
	assert_false(CATCH.can_be_caught(false, true), "an owned creature at full health was catchable")
	assert_false(CATCH.can_be_caught(true, true), "an owned, fainted creature was catchable")
	assert_true(CATCH.can_be_caught(false, false), "a healthy wild creature was refused")
	assert_false(CATCH.can_be_caught(true, false), "a fainted wild creature was catchable")


func test_the_combat_manager_asks_whether_the_opponent_is_owned_at_both_doors() -> void:
	# THIS IS THE TEST THAT MAKES THE RULE REAL.
	#
	# `can_be_caught(fainted, already_owned)` is called from exactly two places —
	# before the aim opens, and again when the orb lands — and until M13 both
	# passed a literal `false` for the second argument. The rule was enforced by
	# a parameter nobody ever set. So: no call site may pass a constant, and both
	# must pass the ownership question.
	var source := _code(MANAGER_SOURCE)
	assert_false(source.is_empty(), "could not read the combat manager")
	assert_false(source.contains("can_be_caught(_enemy.fainted, false)"),
		"a catch legality check passes a hard-coded false for `already_owned`; "
		+ "trainer-owned pals would be catchable again")
	assert_eq(source.count("can_be_caught("), 2,
		"the number of catch-legality checks changed; every one of them has to ask about ownership")
	assert_eq(source.count("_opponent_is_trainer_owned()"), 4,
		"the ownership question is not being asked at both doors (twice each, for the check "
		+ "and for the refusal message)")


func test_a_trainer_owned_body_says_so_and_a_wild_one_does_not() -> void:
	# The duck-typed contract the manager relies on. `tether_pal` answers by
	# HAVING the method; `wild_pal` answers by not having it — so there is no
	# boolean anybody can forget to set.
	assert_true(_has_method(TETHER_PAL, "is_trainer_owned"),
		"tether_pal does not declare is_trainer_owned; every Team Tether creature would be catchable")
	assert_false(_code(WILD_SOURCE).contains("func is_trainer_owned"),
		"wild_pal has grown an is_trainer_owned; wild creatures must answer no by not having it")


func test_every_creature_a_trainer_fields_is_built_as_a_trainer_owned_body() -> void:
	# There is one place a trainer's creature body is created, and it must use the
	# script that carries the rule. A second construction site using `wild_pal`
	# would produce a Team Tether creature the player could catch.
	var source := _code(TRAINER_SOURCE)
	assert_true(source.contains("body.set_script(TETHER_PAL)"),
		"a trainer's team is not built from tether_pal.gd")
	assert_false(source.contains("WILD_SCRIPT"),
		"a trainer builds a creature body from the wild script; it would be catchable")


func test_a_caught_trainer_pal_is_treated_as_impossible_rather_than_handled() -> void:
	# If the outcome ever arrives, the fight must stop and say so rather than
	# carrying on as though a rule had not been broken.
	assert_true(_code(TRAINER_SOURCE).contains("push_error(\"A TRAINER-OWNED PAL WAS CAUGHT."),
		"the trainer battle quietly tolerates the one outcome that must be impossible")


# --- the team, in order -----------------------------------------------------

func test_a_trainers_team_is_built_from_its_file() -> void:
	var battle: RefCounted = BATTLE.from_definition(DATA.trainer("warden_meadows"))
	assert_eq(battle.size(), 3, "the Warden does not field three creatures")
	assert_eq(battle.last_refusal(), "", "building the Warden's team was refused")
	assert_eq(battle.at(0).species_id, "wild_grazer", "the Warden's lead is not the defensive one")
	assert_eq(battle.at(2).species_id, "evolved_wolf", "the Warden's last is not the heavy")


func test_the_team_comes_out_in_order_and_never_goes_back() -> void:
	var battle: RefCounted = BATTLE.from_definition(DATA.trainer("warden_meadows"))
	assert_true(battle.open(), "the battle would not open")
	assert_eq(battle.current_index(), 0, "the battle did not open on the lead")

	battle.current().take_damage(battle.current().max_hp * 2.0)
	assert_true(battle.advance(), "the second creature never came out")
	assert_eq(battle.current_index(), 1, "the wrong creature came out second")

	battle.current().take_damage(battle.current().max_hp * 2.0)
	assert_true(battle.advance(), "the third creature never came out")
	assert_eq(battle.current_index(), 2, "the wrong creature came out third")

	battle.current().take_damage(battle.current().max_hp * 2.0)
	assert_false(battle.advance(), "a fourth creature came out of a team of three")
	assert_true(battle.is_beaten(), "the Warden is not beaten with his whole team down")


func test_a_downed_creature_is_stepped_over_rather_than_sent_back_out() -> void:
	var battle: RefCounted = BATTLE.from_definition(DATA.trainer("tether_wrangler"))
	battle.at(1).take_damage(battle.at(1).max_hp * 2.0)
	assert_true(battle.open(), "the battle would not open")
	battle.current().take_damage(battle.current().max_hp * 2.0)
	assert_true(battle.advance(), "the battle ended with a standing creature left")
	assert_eq(battle.current_index(), 2, "the battle sent out the creature that was already down")


func test_breaking_off_restores_the_trainers_team() -> void:
	# The difficulty mechanic, stated as a test because it is the difference
	# between a boss and a patience test.
	var battle: RefCounted = BATTLE.from_definition(DATA.trainer("warden_meadows"))
	battle.open()
	for i in battle.size():
		battle.at(i).take_damage(battle.at(i).max_hp * 2.0)
	assert_true(battle.is_beaten(), "the team did not go down")

	battle.restore()
	assert_eq(battle.standing(), 3, "breaking off did not put the Warden's team back")
	assert_false(battle.is_beaten(), "the Warden stayed beaten after the player broke off")
	assert_eq(battle.current_index(), 0, "the restored team does not start again from its lead")


func test_a_trainers_creature_carries_no_trait() -> void:
	# A boss whose heavy might roll Fierce or might roll Brittle is a different
	# fight each attempt, and "meaningful difficulty" is not something anyone
	# could learn.
	var battle: RefCounted = BATTLE.from_definition(DATA.trainer("warden_meadows"))
	for i in battle.size():
		assert_eq(battle.at(i).trait_id, "", "a trainer's creature rolled a trait")


func test_a_trainers_team_is_not_a_party_and_is_not_capped_at_five() -> void:
	# D13's cap is about what the PLAYER owns. Applying it here would be cargo
	# cult; giving the player a route into this list would be the real violation.
	var source := _code("res://scripts/trainers/trainer_battle.gd")
	assert_false(source.contains("MAX_PARTY"), "a trainer's team borrowed the player's cap")
	assert_false(source.contains("pals/party.gd"), "a trainer's team reaches into the player's party")
	assert_false(source.contains("is_full"), "a trainer's team has grown a capacity")


# --- meaningful difficulty, and what it is not ------------------------------

func test_the_tether_shortens_the_window_the_player_punishes() -> void:
	var base: Dictionary = MATH.config().get("enemy", {})
	var warden: Dictionary = TETHER_PAL.tethered_config(base, DATA.tether_grade("warden"))

	assert_true(float(warden["recovery"]) < float(base.get("recovery", 0.75)),
		"the Warden's creatures recover no faster than a wild one; there is no difficulty in the tether")
	assert_true(float(warden["telegraph"]) < float(base.get("telegraph", 0.55)),
		"the Warden's wind-up is no shorter than a wild creature's")
	assert_true(float(warden["attack_cooldown"]) < float(base.get("attack_cooldown", 1.1)),
		"the Warden's creatures attack no more often than a wild one")

	# The specific claim `warden_meadows.json` makes about the fight: the opening
	# still fits one quick attack and no longer fits a charged one. If the tuning
	# ever stops making that true, the argument for why the boss is hard stops
	# being true with it.
	var quick: Dictionary = MATH.config().get("player_quick", {})
	var charged: Dictionary = MATH.config().get("player_charged", {})
	var quick_cost := float(quick.get("windup", 0.18)) + float(quick.get("recovery", 0.22))
	var charged_cost := float(charged.get("windup", 0.55)) + float(charged.get("recovery", 0.5))
	assert_true(float(warden["recovery"]) > quick_cost,
		"the Warden's opening is too short for even a quick attack; that is a wall, not a window")
	assert_true(float(warden["recovery"]) < charged_cost,
		"a charged attack still fits inside the Warden's opening; spending the meter is not a decision")


func test_the_tether_touches_timings_and_nothing_else() -> void:
	# THE TEST THIS MILESTONE IS MOST LIKELY TO BE BROKEN BY LATER.
	#
	# A boss that wins by having ten times the health is a wall. The tether may
	# only change how fast a creature acts, so every key it writes has to be a
	# timing or a speed, and no stat may move.
	var base: Dictionary = MATH.config().get("enemy", {})
	var warden: Dictionary = TETHER_PAL.tethered_config(base, DATA.tether_grade("warden"))
	const TIMING_KEYS := [
		"telegraph", "recovery", "reposition_time",
		"attack_cooldown", "first_attack_delay",
		"chase_speed", "reposition_speed",
	]
	for key: String in base.keys():
		if TIMING_KEYS.has(key):
			continue
		assert_eq(warden.get(key), base.get(key), "the tether changed '%s', which is not a timing" % key)
	assert_eq(warden.get("power"), base.get("power"), "the tether raised the opponent's damage")


func test_no_trainer_can_be_given_a_stat_multiplier_by_data() -> void:
	# The failure this guards is a key added to a JSON file, so the assertion is
	# about the files. A team entry may name a species, a level and a tether, and
	# nothing else that could scale a stat.
	const FORBIDDEN := ["hp", "attack", "defence", "power", "multiplier", "scale", "boost"]
	for id: String in _trainer_ids:
		var definition := DATA.trainer(id)
		assert_false(definition.is_empty(), "trainer '%s' has no file" % id)
		for entry: Variant in definition.get("team", []):
			for key: String in (entry as Dictionary).keys():
				if key.begins_with("_"):
					continue
				assert_true(["species", "level", "tether", "nickname"].has(key),
					"trainer '%s' fields a creature with an unexpected key '%s'" % [id, key])
				for word: String in FORBIDDEN:
					assert_false(key.to_lower().contains(word),
						"trainer '%s' has a stat knob '%s'; difficulty must be timing, not stats" % [id, key])


func test_the_tether_grades_only_hold_timing_multipliers() -> void:
	var grades: Dictionary = DATA.config().get("tether_grades", {})
	assert_true(grades.size() >= 3, "the tether grades are missing")
	const ALLOWED := ["beat_scale", "cooldown_scale", "chase_scale", "live"]
	for name: String in grades.keys():
		if name.begins_with("_"):
			continue
		for key: String in (grades[name] as Dictionary).keys():
			if key.begins_with("_"):
				continue
			assert_true(ALLOWED.has(key),
				"tether grade '%s' has key '%s', which is not one of the timing multipliers" % [name, key])


func test_the_wardens_levels_are_a_small_edge_over_the_road_below_him() -> void:
	# Damage is bounded — `power * 2 * attack / (attack + defence)` — so a level
	# raises an opponent's defence and its health together and multiplies
	# time-to-kill faster than it raises the threat. A level-14 heavy would be a
	# forty-hit sponge that could not kill anybody, which is the wall this
	# milestone is required not to build.
	var highest := 0
	for entry: Variant in DATA.trainer("warden_meadows").get("team", []):
		highest = maxi(highest, int((entry as Dictionary).get("level", 1)))
	assert_between(float(highest), 6.0, 12.0,
		"the Warden's levels have drifted; above about 12 the fight becomes a sponge")

	var picket := 0
	for entry: Variant in DATA.trainer("tether_picket").get("team", []):
		picket = maxi(picket, int((entry as Dictionary).get("level", 1)))
	assert_true(picket < highest, "the first picket fields creatures as strong as the Warden's")


func test_the_first_creature_the_player_ever_meets_on_this_road_is_untethered() -> void:
	# The picket teaches the FORMAT before it teaches the difficulty.
	var lead: Dictionary = (DATA.trainer("tether_picket").get("team", [])[0] as Dictionary)
	assert_eq(str(lead.get("tether", "")), "none",
		"the player's first trainer battle opens against a tethered creature")
	var grade := DATA.tether_grade("none")
	assert_almost_eq(float(grade.get("beat_scale", 0.0)), 1.0, 0.0001,
		"the 'none' grade is not actually untethered")


# --- the route --------------------------------------------------------------

func test_the_route_is_authored_and_every_post_names_a_trainer_that_exists() -> void:
	assert_true(_trainer_ids.size() >= 3, "the stronghold route has fewer than three posts")
	for id: String in _trainer_ids:
		assert_false(DATA.trainer(id).is_empty(), "the route names trainer '%s', which has no file" % id)


func test_every_species_team_tether_fields_is_in_the_species_table() -> void:
	for id: String in _trainer_ids:
		for entry: Variant in DATA.trainer(id).get("team", []):
			var species := str((entry as Dictionary).get("species", ""))
			assert_true(SPECIES.has(species),
				"trainer '%s' fields '%s', which is not a species" % [id, species])


func test_the_warden_stands_below_the_bluff_rather_than_on_it() -> void:
	# The bluff's flanks were measured before the route was authored: the shelf at
	# its foot runs 14-19 degrees and is walkable, and from z=136 north the flank
	# goes 30, then 43, then 50 degrees against the controller's 45-degree limit.
	# `settlement.json` puts the ruin at z=178 on the summit precisely because it
	# cannot be climbed. A Warden authored past the shelf would be a boss the
	# player can see and cannot reach.
	var warden_post: Dictionary = {}
	for entry: Variant in DATA.route_posts():
		if str((entry as Dictionary).get("trainer", "")) == "warden_meadows":
			warden_post = entry
	assert_false(warden_post.is_empty(), "the Warden is not on the route")
	var at: Array = warden_post.get("at", [0.0, 0.0])
	assert_true(float(at[1]) < 136.0,
		"the Warden's post is past the last walkable ground before the bluff's flank")
	assert_true(float(at[1]) > 118.0, "the Warden is nowhere near the stronghold")


func test_the_legendary_is_freed_below_the_flank_too() -> void:
	var cfg := DATA.legendary()
	var at: Array = cfg.get("at", [0.0, 0.0])
	var approach: Array = cfg.get("approach", at)
	assert_true(float(at[1]) < 137.0, "the legendary is tethered on ground the player cannot stand on")
	assert_true(float(approach[1]) < float(at[1]),
		"the freed legendary walks up the bluff rather than down to the player")


# --- the legendary ----------------------------------------------------------

func test_the_legendary_is_a_real_species_and_survives_a_save() -> void:
	# The whole reason `tether_roster` exists. `pal_instance.from_record` rebuilds
	# a saved pal by asking the species table for its id, so a legendary that is
	# not in the table would join the party, save, and vanish on the next load.
	var id := str(DATA.legendary().get("species", ""))
	assert_true(SPECIES.has(id), "the legendary is not in the species table")

	var pal: RefCounted = SPECIES.spawn(id, 0.0)
	assert_ne(pal, null, "the legendary could not be spawned")
	pal.set_level(9)
	pal.rename("Test")
	var restored: RefCounted = PAL.from_record(pal.to_record())
	assert_ne(restored, null, "the legendary did not survive a save round trip")
	assert_eq(restored.species_id, id, "the restored legendary is a different species")
	assert_eq(restored.level, 9, "the restored legendary lost its level")


func test_the_legendary_is_ground_and_is_the_strongest_thing_in_the_region() -> void:
	# §28: Ground type. And it arrives after the boss, so it may be the best
	# creature in the biome without unbalancing anything it was the reward for.
	var id := str(DATA.legendary().get("species", ""))
	assert_eq(SPECIES.type_of(id), "ground", "§28 asks for a Ground legendary")
	var definition := SPECIES.definition(id)
	for other: String in SPECIES.ids():
		if other == id:
			continue
		assert_true(float(definition.get("base_hp", 0.0)) >= float(SPECIES.definition(other).get("base_hp", 0.0)),
			"'%s' is tougher than the region's legendary" % other)


func test_the_legendary_cannot_be_caught_by_arithmetic_as_well_as_by_fiction() -> void:
	var id := str(DATA.legendary().get("species", ""))
	assert_almost_eq(SPECIES.catch_rate(id), 0.0, 0.0001,
		"the legendary has a catch rate; it is freed and offers to join, it is never thrown at")


func test_the_legendary_placeholder_says_it_is_a_placeholder() -> void:
	# CLAUDE.md forbids judging creature appeal on placeholder art, and the way
	# that rule fails is a stand-in nobody remembers is one. This creature has no
	# model on purpose — a scaled-up stag would photograph as a legendary and then
	# sit in the game being one.
	var id := str(DATA.legendary().get("species", ""))
	var name := SPECIES.display_name(id).to_lower()
	assert_true(name.contains("placeholder") or name.contains("unmodelled"),
		"the legendary's name does not say it is unfinished: '%s'" % SPECIES.display_name(id))
	assert_eq(str(SPECIES.placeholder(id).get("model", "")), "",
		"the legendary has been given a model; if that is real art, rename it and delete this assertion")


func test_the_legendary_is_the_regions_best_mount() -> void:
	# M14's "superior ride ability", against M12's actual contract: riding reads
	# `rideable` and `ride.speed_scale` straight off the species.
	var id := str(DATA.legendary().get("species", ""))
	assert_true(bool(SPECIES.definition(id).get("rideable", false)),
		"§28's ultimate riding mount is not rideable")
	if not ResourceLoader.exists(MOUNT_PATH):
		assert_true(float((SPECIES.definition(id).get("ride", {}) as Dictionary).get("speed_scale", 0.0)) > 1.0,
			"the legendary declares no speed advantage and there is no mount system to check it against")
		return

	var mount: GDScript = load(MOUNT_PATH) as GDScript
	var canter: float = float(mount.call("ride_speed", id, false))
	var best_other := 0.0
	for other: String in SPECIES.ids():
		if other == id or not bool(SPECIES.definition(other).get("rideable", false)):
			continue
		best_other = maxf(best_other, float(mount.call("ride_speed", other, true)))
	assert_true(best_other > 0.0, "no other mount to compare the legendary against")
	# The claim in the data: it does at a free canter what the best ordinary
	# mount only manages on a gallop it cannot hold.
	assert_true(canter > best_other,
		"the legendary's canter (%.1f) is not faster than the best other mount's gallop (%.1f); "
		% [canter, best_other] + "§28's 'substantially better traversal' is not true")


func test_the_legendarys_offer_goes_through_the_partys_own_door() -> void:
	# There must be exactly one way a pal enters the party, and the legendary
	# must use it. D13: a second route is an exception to the five-pal cap.
	var offer := _code(OFFER_SOURCE)
	assert_true(offer.contains("_director.call(\"offer_pal\", _instance)"),
		"the legendary does not hand itself to the encounter director")
	assert_false(offer.contains(".add("), "the legendary reaches into the party directly")
	assert_false(offer.contains("pals/party.gd"), "the legendary loads the party itself")

	var director := _code(DIRECTOR_SOURCE)
	assert_true(director.contains("func offer_pal(instance: RefCounted) -> void:\n\t_keep(instance)"),
		"offer_pal does not go through the same _keep() a catch goes through")


func test_a_full_party_refuses_the_legendary_with_the_token_the_ceremony_opens_on() -> void:
	# The end-to-end claim of M14's third bullet, in the two objects that decide
	# it. `release_prompt.gd` opens the ceremony on `party_full` and on nothing
	# else, so this is the whole contract between the legendary and the ceremony.
	var party: RefCounted = PARTY.new()
	for i in PARTY.MAX_PARTY:
		party.add(SPECIES.spawn("wild_pup", 0.0))
	assert_true(party.is_full(), "the test party is not full")

	var legendary: RefCounted = SPECIES.spawn(str(DATA.legendary().get("species", "")), 0.0)
	assert_false(party.add(legendary), "a sixth pal was accepted")
	assert_eq(party.last_refusal(), PARTY.REFUSED_PARTY_FULL,
		"the refusal token is not the one release_prompt opens the ceremony on")

	var ceremony: RefCounted = CEREMONY.open(party, legendary)
	assert_ne(ceremony, null, "the release ceremony would not open for the legendary")
	assert_eq(ceremony.count(), 6, "the ceremony does not present six")
	assert_eq(ceremony.at(ceremony.newcomer_index()), legendary,
		"the legendary is not the newcomer in the ceremony")


func test_the_legendary_can_be_the_one_released_and_the_offer_is_not_repeated() -> void:
	# D16: the newcomer is one of the six and can be the one that leaves. That is
	# harsh for a legendary and it is the design — an exception here would make
	# the ceremony optional for the creature it matters most for.
	var party: RefCounted = PARTY.new()
	for i in PARTY.MAX_PARTY:
		party.add(SPECIES.spawn("wild_pup", 0.0))
	var legendary: RefCounted = SPECIES.spawn(str(DATA.legendary().get("species", "")), 0.0)
	var ceremony: RefCounted = CEREMONY.open(party, legendary)
	assert_true(ceremony.choose(ceremony.newcomer_index()), "the legendary could not be chosen")
	var outcome: Dictionary = ceremony.resolve()
	assert_eq(outcome.get("released"), legendary, "releasing the newcomer released somebody else")
	assert_eq(party.size(), PARTY.MAX_PARTY, "the party changed size")
	assert_eq(party.index_of(legendary), -1, "the released legendary is still in the party")

	assert_true(_code(OFFER_SOURCE).contains("_resolved = true"),
		"the legendary's offer is not one-shot; it could be accepted twice")


# --- the reserved accent ----------------------------------------------------

func test_the_tether_accent_exists_and_has_exactly_one_reader() -> void:
	# `palette.json` reserves the Team Tether colour project-wide, and a
	# reservation is only worth having while there is one door to it.
	for id: String in ["tether_oxblood", "tether_cloth", "tether_iron", "tether_live"]:
		assert_ne(DATA.accent(id), Color.MAGENTA, "palette.json has no accent '%s'" % id)

	var offenders: Array[String] = []
	for path in _gd_files("res://scripts"):
		if path.begins_with("res://scripts/trainers/"):
			continue
		# The comments in `map_canvas`, `ui_style` and `release_screen` all NAME
		# the reserved colour to say they are deliberately not using it, which is
		# the reservation working as intended. What must not appear is a LOOKUP,
		# so the file is read with its prose removed.
		var text := _code(path)
		if text.contains("accent") and text.contains("tether_"):
			offenders.append(path)
	assert_eq(offenders.size(), 0,
		"the reserved Team Tether accent is read outside scripts/trainers/: %s" % [offenders])


func _gd_files(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full := "%s/%s" % [dir_path, entry]
		if dir.current_is_dir():
			if not entry.begins_with("."):
				out.append_array(_gd_files(full))
		elif entry.ends_with(".gd"):
			out.append(full)
		entry = dir.get_next()
	dir.list_dir_end()
	return out


func _has_method(script: GDScript, name: String) -> bool:
	for entry: Dictionary in script.get_script_method_list():
		if str(entry.get("name", "")) == name:
			return true
	return false
