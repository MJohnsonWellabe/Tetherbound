extends "res://tests/test_case.gd"

## The trainer table, data/config/trainers.json (R8.1).
##
## Every failure this file guards is silent at run time. A species renamed in
## one file and not the other produces a trainer who sends out nothing and a
## battle that refuses itself. Two trainers sharing a defeat flag means beating
## one closes the other. A challenge conversation that is not in the dialogue
## table means the challenge prompt opens an empty box and the fight never
## starts. A reward naming an item that does not exist pays out nothing and
## push_errors into a log nobody is reading.
##
## Per docs/decisions/D02 the suite is pure logic only: standing a trainer on
## Terrain3D and beating them is `tests/smoke_trainer_battle.gd`'s job. This
## file owns the TABLE that test and `scripts/combat/encounter_director.gd`
## read.

const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const ITEMS_PATH := "res://data/items/items.json"
## SF34's captains: the rank palette they stand on, and the gate their Sigils
## open.
const NPC_RANKS := preload("res://scripts/characters/npc_ranks.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const ITEM_GATE := preload("res://scripts/world/item_gate.gd")


func _item_ids() -> Array:
	var file := FileAccess.open(ITEMS_PATH, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return []
	var items: Variant = (parsed as Dictionary).get("items", {})
	if items is Dictionary:
		return (items as Dictionary).keys()
	var out: Array = []
	for entry: Variant in (items as Array):
		out.append(str((entry as Dictionary).get("id", "")))
	return out


# --- the table is well-formed -------------------------------------------------

func test_the_table_has_at_least_one_trainer() -> void:
	assert_false(TRAINERS.trainers().is_empty(),
		"trainers.json lists nobody; there would be no trainer battle in the game")


func test_every_trainer_has_an_id_a_name_and_a_position() -> void:
	for entry: Variant in TRAINERS.trainers():
		var spec: Dictionary = entry
		assert_ne(str(spec.get("id", "")), "", "a trainer entry has no id")
		assert_ne(str(spec.get("name", "")), "",
			"trainer '%s' has no display name; their prompt would read 'Challenge '" % str(spec.get("id", "")))
		var at: Array = spec.get("position", [])
		assert_eq(at.size(), 2,
			"trainer '%s' has no [x, z] position" % str(spec.get("id", "")))


func test_trainer_ids_are_unique() -> void:
	var seen: Array[String] = []
	for entry: Variant in TRAINERS.trainers():
		var id := str((entry as Dictionary).get("id", ""))
		assert_false(seen.has(id), "two trainers share the id '%s'" % id)
		seen.append(id)


func test_every_trainer_has_a_team_of_real_species() -> void:
	for entry: Variant in TRAINERS.trainers():
		var spec: Dictionary = entry
		var team := TRAINERS.team_of(spec)
		assert_false(team.is_empty(),
			"trainer '%s' fields no creatures; the battle would refuse itself" % str(spec.get("id", "")))
		for member: Variant in team:
			var creature: Dictionary = member
			var id := str(creature.get("species", ""))
			assert_true(SPECIES.has(id),
				"trainer '%s' fields '%s', which is not in species.json" % [str(spec.get("id", "")), id])
			assert_true(int(creature.get("level", 0)) > 0,
				"trainer '%s' fields a level-%d creature" % [str(spec.get("id", "")), int(creature.get("level", 0))])


func test_every_team_member_can_actually_be_built() -> void:
	# The director builds these through `creature_for()`; a null here is a
	# battle that push_errors and refuses to start.
	for entry: Variant in TRAINERS.trainers():
		var spec: Dictionary = entry
		for member: Variant in TRAINERS.team_of(spec):
			var creature: RefCounted = TRAINERS.creature_for(member as Dictionary)
			assert_true(creature != null,
				"trainer '%s' has a team entry that builds no creature" % str(spec.get("id", "")))
			if creature == null:
				continue
			assert_eq(int(creature.get("level")), int((member as Dictionary).get("level", 1)),
				"a trainer's creature did not come out at its authored level")
			assert_true(float(creature.get("hp")) > 0.0,
				"a trainer's creature was built already fainted")


# --- the flags are what stop a battle being farmed ----------------------------

func test_every_trainer_has_a_defeat_flag() -> void:
	# Spec §15 and §17 P1 step 9: the flag is what records the battle as done,
	# what SC15's reward is paid against, and what SC14's bridge will read.
	for entry: Variant in TRAINERS.trainers():
		var spec: Dictionary = entry
		assert_ne(str(spec.get("defeat_flag", "")), "",
			"trainer '%s' has no defeat_flag; beating them would change nothing" % str(spec.get("id", "")))


func test_defeat_flags_are_unique() -> void:
	var seen: Array[String] = []
	for entry: Variant in TRAINERS.trainers():
		var flag := str((entry as Dictionary).get("defeat_flag", ""))
		assert_false(seen.has(flag),
			"two trainers share the defeat flag '%s'; beating one would close the other" % flag)
		seen.append(flag)


func test_a_beaten_trainer_cannot_be_challenged_again() -> void:
	var progression: RefCounted = PROGRESSION_STATE.new()
	for entry: Variant in TRAINERS.trainers():
		var spec: Dictionary = entry
		assert_false(TRAINERS.already_beaten(spec, progression),
			"trainer '%s' reads as beaten on a fresh save" % str(spec.get("id", "")))
		progression.call("set_flag", str(spec.get("defeat_flag", "")))
		assert_true(TRAINERS.already_beaten(spec, progression),
			"trainer '%s' can be re-fought after their flag is set; that is an XP faucet" % str(spec.get("id", "")))


func test_a_beaten_trainer_greets_instead_of_challenging() -> void:
	var progression: RefCounted = PROGRESSION_STATE.new()
	for entry: Variant in TRAINERS.trainers():
		var spec: Dictionary = entry
		assert_eq(TRAINERS.conversation_for(spec, progression), str(spec.get("challenge", "")),
			"trainer '%s' does not open their challenge on a fresh save" % str(spec.get("id", "")))
		progression.call("set_flag", str(spec.get("defeat_flag", "")))
		assert_eq(TRAINERS.conversation_for(spec, progression), str(spec.get("defeated", "")),
			"trainer '%s' still opens their challenge after being beaten" % str(spec.get("id", "")))


# --- what they say, and what they pay ------------------------------------------

func test_both_conversations_exist_in_the_dialogue_table() -> void:
	for entry: Variant in TRAINERS.trainers():
		var spec: Dictionary = entry
		for key: String in ["challenge", "defeated"]:
			var id := str(spec.get(key, ""))
			assert_ne(id, "", "trainer '%s' names no '%s' conversation" % [str(spec.get("id", "")), key])
			assert_true(RUNNER.has(id),
				"trainer '%s' opens '%s', which no dialogue file defines" % [str(spec.get("id", "")), id])


func test_every_reward_item_exists() -> void:
	var known := _item_ids()
	assert_false(known.is_empty(), "items.json could not be read; the reward check would pass vacuously")
	for entry: Variant in TRAINERS.trainers():
		var spec: Dictionary = entry
		for item: Variant in TRAINERS.reward_items(spec):
			var id := str((item as Dictionary).get("id", ""))
			assert_true(known.has(id),
				"trainer '%s' rewards '%s', which items.json does not define" % [str(spec.get("id", "")), id])
			assert_true(int((item as Dictionary).get("count", 0)) > 0,
				"trainer '%s' rewards zero of '%s'" % [str(spec.get("id", "")), id])


func test_reward_coins_and_xp_bonus_are_not_negative() -> void:
	for entry: Variant in TRAINERS.trainers():
		var spec: Dictionary = entry
		assert_true(TRAINERS.reward_coins(spec) >= 0,
			"trainer '%s' rewards negative coins" % str(spec.get("id", "")))
		assert_true(TRAINERS.reward_xp_bonus(spec) >= 0,
			"trainer '%s' rewards a negative xp_bonus" % str(spec.get("id", "")))


func test_at_least_one_trainer_pays_coins() -> void:
	# D39: "SC15's trainer payouts later pay coins too." A reward table that
	# never actually pays a coin would leave that promise unkept.
	var any_coins := false
	for entry: Variant in TRAINERS.trainers():
		if TRAINERS.reward_coins(entry as Dictionary) > 0:
			any_coins = true
			break
	assert_true(any_coins,
		"no trainer reward pays out any coins; D39 promised trainer payouts include coins")


func test_every_trainer_has_a_body_to_stand_up_in() -> void:
	for entry: Variant in TRAINERS.trainers():
		var spec: Dictionary = entry
		var cfg := TRAINERS.model_config(spec)
		assert_false(cfg.is_empty(),
			"trainer '%s' names an art.json/npc_ranks.json key that does not exist" % str(spec.get("id", "")))
		assert_ne(str(cfg.get("model", "")), "",
			"trainer '%s' resolves to a config with no model" % str(spec.get("id", "")))


func test_the_flow_numbers_are_sane() -> void:
	var flow := TRAINERS.flow()
	assert_true(float(flow.get("send_out_seconds", 0.0)) > 0.0,
		"send_out_seconds is zero; the next creature would appear on the same frame the last one fell")
	assert_true(float(flow.get("linger_seconds", 0.0)) > 0.0,
		"linger_seconds is zero; a beaten creature would vanish rather than fall")


# --- SC12/SC13: Mira, Oskar and Tam ---------------------------------------------

## Spec §3 Band 1 names three trainers by role; this is the id contract every
## other SC13 test below, `sequence_director.gd`'s `battle:` effect and
## `data/config/village_npcs.json`'s `greeting_when` branches all rely on.
func test_mira_oskar_and_tam_are_all_in_the_table() -> void:
	for id in ["trainer_mira", "trainer_oskar", "trainer_tam"]:
		assert_false(TRAINERS.trainer(id).is_empty(),
			"'%s' is not in trainers.json; SC13's Band 1 circuit has a hole in it" % id)


## The whole point of SC12: no fourth body. An entry naming `placed_by` must
## be excluded from `trainer_npc.gd`'s own placement loop, the same filter
## `build()` applies, checked here without booting a scene.
func test_mira_oskar_and_tam_are_placed_elsewhere_not_spawned_here() -> void:
	for id in ["trainer_mira", "trainer_oskar", "trainer_tam"]:
		var spec := TRAINERS.trainer(id)
		assert_eq(str(spec.get("placed_by", "")), "village_npcs",
			"'%s' should name village_npcs.gd as its placer, or trainer_npc.gd will stand up a second body for them" % id)
	for entry: Variant in TRAINERS.trainers():
		var spec: Dictionary = entry
		if str(spec.get("id", "")) == "practice_trainer":
			assert_eq(str(spec.get("placed_by", "")), "",
				"practice_trainer is trainer_npc.gd's OWN placed body; it must not name placed_by")


## The South Bridge Key is checked by name and not just by "some item exists":
## `gated_crossing.gd` reads `south_bridge_key` specifically, and a renamed item
## id would silently strand Gate 1.
##
## TOURNAMENT-1 moved WHO holds it. It was Oskar's (SC14); the 2026-08-22 owner
## directive puts a Team Tether grunt on the crossing so Oskar is free to be the
## tournament's final round. This test asserts BOTH halves of that move -- the
## grunt has it and Oskar no longer does -- because a half-applied move is a
## chapter with two keys or none.
func test_the_south_bridge_key_is_held_by_the_team_tether_grunt() -> void:
	var grunt_ids: Array[String] = []
	for item: Variant in TRAINERS.reward_items(TRAINERS.trainer("south_bridge_grunt")):
		grunt_ids.append(str((item as Dictionary).get("id", "")))
	assert_true(grunt_ids.has("south_bridge_key"),
		"south_bridge_grunt's reward should include south_bridge_key; got %s" % str(grunt_ids))

	var oskar_ids: Array[String] = []
	for item: Variant in TRAINERS.reward_items(TRAINERS.trainer("trainer_oskar")):
		oskar_ids.append(str((item as Dictionary).get("id", "")))
	assert_false(oskar_ids.has("south_bridge_key"),
		"trainer_oskar still hands over the South Bridge Key; the gatekeeper is the grunt now")


## And the grunt is a grunt: an existing Team Tether rank on an installed rig,
## never a new humanoid. CLAUDE.md forbids the alternative outright.
func test_the_bridge_gatekeeper_wears_the_existing_grunt_rank() -> void:
	var spec := TRAINERS.trainer("south_bridge_grunt")
	assert_false(spec.is_empty(), "south_bridge_grunt is not in trainers.json; Gate 1 has nobody on it")
	assert_eq(str(spec.get("rank", "")), "grunt",
		"the bridge gatekeeper should use npc_ranks.json's existing grunt rank")
	assert_eq(str(spec.get("config_key", "")), "",
		"a ranked NPC must not also name an art.json config_key; model_config() would ignore the rank")
	assert_ne(str(TRAINERS.model_config(spec).get("model", "")), "",
		"the grunt rank resolves to no model; nobody would be standing at the bridge")


## D39: coins are an ordinary stacking item, so a trainer paying coin is just
## another reward_items entry, id "coin" -- no separate top-level field, and no
## payout code beyond what encounter_director.gd already runs for any item.
func test_every_band_one_trainer_pays_coins_alongside_their_authored_item() -> void:
	for id in ["trainer_mira", "trainer_oskar", "trainer_tam"]:
		var ids: Array[String] = []
		for item: Variant in TRAINERS.reward_items(TRAINERS.trainer(id)):
			ids.append(str((item as Dictionary).get("id", "")))
		assert_true(ids.has("coin"), "'%s' should pay coins as part of its reward; got %s" % [id, str(ids)])


# --- SE25: the relay trainers and the relay captain -----------------------------

const RELAY_SITE_PATH := "res://data/config/relay_site.json"
const RELAY_IDS := [
	"relay_picket_hess",
	"relay_picket_orrin",
	"relay_officer_dell",
	"relay_captain",
]
## Spec §3 Band 3. Tunable, but not player-scaled and not open-ended: this is
## the band the relay is fought at, and a level outside it is a data slip
## rather than a design choice made here.
const BAND_3_MIN := 8
const BAND_3_MAX := 12


func _relay_site() -> Dictionary:
	var file := FileAccess.open(RELAY_SITE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


## Spec §12 sizes the station at "2-3 Team Tether trainer battles" plus the
## captain. Four entries, and the ids are the contract relay_site.json's gate
## and tests/smoke_relay.gd both name.
func test_the_relay_fields_three_trainers_and_a_captain() -> void:
	for id: String in RELAY_IDS:
		assert_false(TRAINERS.trainer(id).is_empty(),
			"'%s' is not in trainers.json; the relay station is short a battle" % id)


## NP2/spec §36. The rank read is the whole reason these four are `rank:` and
## not `config_key:` — grunt, grunt, officer, captain, escalating, and every
## one of them a real entry in data/config/npc_ranks.json rather than a
## misspelling that silently falls back to no body at all.
func test_the_relay_ranks_are_real_and_escalate() -> void:
	var known := NPC_RANKS.rank_ids()
	assert_false(known.is_empty(), "npc_ranks.json could not be read; this check would pass vacuously")
	var expected := {
		"relay_picket_hess": "grunt",
		"relay_picket_orrin": "grunt",
		"relay_officer_dell": "officer",
		"relay_captain": "captain",
	}
	for id: String in RELAY_IDS:
		var rank := str(TRAINERS.trainer(id).get("rank", ""))
		assert_true(known.has(rank), "'%s' names rank '%s', which npc_ranks.json does not define" % [id, rank])
		assert_eq(rank, str(expected[id]), "'%s' should stand at the '%s' rank" % [id, str(expected[id])])


## And below the Warden's, which is the other half of the backlog's own
## wording ("visibly below the Warden"). The badge is what carries the rank at
## gameplay distance (npc_ranks.json's own `_comment_badge`), so the captain's
## must be smaller than the Warden's — a captain wearing the top badge is the
## exact collision NP2's blind pass was run to catch.
func test_the_captain_outranks_his_trainers_and_is_outranked_by_the_warden() -> void:
	var sizes: Dictionary = {}
	for rank: String in ["grunt", "officer", "captain", "warden"]:
		var cfg := NPC_RANKS.config_for(rank)
		var accessories: Array = cfg.get("accessories", [])
		assert_false(accessories.is_empty(), "rank '%s' has no badge; nothing carries its rank" % rank)
		sizes[rank] = float((accessories[0] as Dictionary).get("size", 0.0))
	assert_true(float(sizes["grunt"]) < float(sizes["officer"]),
		"a grunt's badge is not smaller than an officer's")
	assert_true(float(sizes["officer"]) < float(sizes["captain"]),
		"an officer's badge is not smaller than the captain's; the relay captain would not read as outranking his own trainers")
	assert_true(float(sizes["captain"]) < float(sizes["warden"]),
		"the captain's badge is not smaller than the Warden's; he must read as visibly below him")


## NP2-grunt-wire's own invariant: grunt/officer/captain build on the grunt
## rig, and the Warden is the one rank that does NOT share a body with anyone
## else. A blind pass rejected the old ladder specifically because all four
## ranks resolved to the same `model` path (the Warden's) -- this asserts the
## fixed shape directly rather than trusting the badge/palette checks above to
## imply it, since none of those actually read `model`.
func test_the_ladder_builds_on_the_grunt_rig_and_the_warden_keeps_his_own() -> void:
	var lower_ranks := ["grunt", "officer", "captain"]
	var lower_model := ""
	for rank: String in lower_ranks:
		var cfg := NPC_RANKS.config_for(rank)
		var model := str(cfg.get("model", ""))
		assert_true(model.contains("grunt"),
			"'%s' should build on the grunt rig; got model '%s'" % [rank, model])
		if lower_model == "":
			lower_model = model
		else:
			assert_eq(model, lower_model,
				"'%s' and its fellow lower ranks should share one rig" % rank)

	var warden_model := str(NPC_RANKS.config_for("warden").get("model", ""))
	assert_true(warden_model.contains("warden"),
		"the Warden rank should build on his own rig; got model '%s'" % warden_model)
	assert_ne(warden_model, lower_model,
		"the Warden must not share a model with grunt/officer/captain -- that is the exact bug ('the Warden's exact mesh... four times') this item fixes")


func test_the_relay_teams_are_levelled_for_band_3() -> void:
	for id: String in RELAY_IDS:
		var spec := TRAINERS.trainer(id)
		for member: Variant in TRAINERS.team_of(spec):
			var level := int((member as Dictionary).get("level", 0))
			assert_true(level >= BAND_3_MIN and level <= BAND_3_MAX,
				"'%s' fields a level-%d creature; Band 3 is %d-%d" % [id, level, BAND_3_MIN, BAND_3_MAX])


## SC15's schema, and the backlog's "the captain's payout is the bigger one".
## Checked as a strict ordering rather than an absolute number so the values
## stay tunable.
func test_the_captain_is_paid_more_than_his_trainers() -> void:
	var captain := TRAINERS.trainer("relay_captain")
	var captain_coins := TRAINERS.reward_coins(captain)
	assert_true(captain_coins > 0, "the relay captain pays no coins at all")
	assert_true(TRAINERS.reward_xp_bonus(captain) > 0,
		"the relay captain pays no xp_bonus; a four-battle site should end in more than one more fight's worth of XP")
	for id: String in ["relay_picket_hess", "relay_picket_orrin", "relay_officer_dell"]:
		var spec := TRAINERS.trainer(id)
		assert_true(TRAINERS.reward_coins(spec) > 0, "'%s' pays no coins" % id)
		assert_true(TRAINERS.reward_coins(spec) < captain_coins,
			"'%s' pays as much as the captain (%d vs %d); the captain's payout is meant to be the bigger one" % [
				id, TRAINERS.reward_coins(spec), captain_coins])
		assert_false(TRAINERS.reward_items(spec).is_empty(), "'%s' rewards no item" % id)
	assert_false(TRAINERS.reward_items(captain).is_empty(), "the relay captain rewards no item")


## SE27 waits on exactly this id. Written by name because a rename here is
## silent: the captive's gate in relay_site.json simply never opens and the
## rescue becomes unreachable with no error anywhere.
func test_the_captains_defeat_flag_is_the_one_se27_waits_on() -> void:
	assert_eq(str(TRAINERS.trainer("relay_captain").get("defeat_flag", "")), "relay_captain_defeated",
		"the relay captain's defeat flag is not 'relay_captain_defeated'; SE27's captive would never be freeable")

	var site := _relay_site()
	assert_false(site.is_empty(), "relay_site.json is missing; the captive has nowhere to stand")
	var gates := 0
	for entry: Variant in (site.get("people", []) as Array):
		for raw: Variant in ((entry as Dictionary).get("greeting_when", []) as Array):
			if str((raw as Dictionary).get("if_flag", "")) == "relay_captain_defeated":
				gates += 1
	assert_eq(gates, 1,
		"exactly one branch in relay_site.json should be gated on the captain's defeat; found %d" % gates)


## The four of them are trainer_npc.gd's OWN bodies — unlike Mira, Oskar and
## Tam, nobody else is standing them up, so an accidental `placed_by` here
## would leave the whole station unpopulated.
func test_the_relay_trainers_are_placed_by_the_trainer_placer() -> void:
	for id: String in RELAY_IDS:
		assert_eq(str(TRAINERS.trainer(id).get("placed_by", "")), "",
			"'%s' names a placed_by; nothing would stand them up at the relay" % id)


## SE23 is not built yet, and the one thing that keeps the compound's own cast
## on the same patch of ground when it is, is that every position is derived
## from relay_site.json's single authored centre. This is that promise,
## written down: if somebody moves the site, this fails until they move the
## cast with it.
##
## GATE-D3, 2026-08-22: this used to check all four RELAY_IDS against the
## site's own 26m compound radius, which is exactly the failure prompt 64
## named — "the route should not jump from wilderness directly into the
## four-person relay gauntlet" is what an 18m cluster inside one small radius
## produces. Hess and Orrin are pickets on the open approach road now, well
## outside the walled compound on purpose, so they get their own generous
## bound (COMPACT_SITE_IDS keeps the strict compound check for Dell and
## Vance, who are still meant to read as one small assault together with the
## captive). APPROACH_RADIUS_M is not "unlimited" — 200m still catches an
## actual data slip (a picket left in the wrong band entirely) while covering
## the real authored distance (Hess ~140m out, Orrin ~90m out, both along the
## spine road that leads to the site, not off in the woods).
const COMPACT_SITE_IDS := ["relay_officer_dell", "relay_captain"]
const APPROACH_PICKET_IDS := ["relay_picket_hess", "relay_picket_orrin"]
const APPROACH_RADIUS_M := 200.0

func test_every_relay_position_sits_inside_the_authored_site() -> void:
	var site: Dictionary = _relay_site().get("site", {})
	assert_false(site.is_empty(), "relay_site.json names no site; SE23 has no coordinate to adopt")
	var at: Array = site.get("centre", [])
	assert_eq(at.size(), 2, "relay_site.json's site.centre is not an [x, z] pair")
	if at.size() != 2:
		return
	var centre := Vector2(float(at[0]), float(at[1]))
	var radius := float(site.get("radius", 0.0))
	assert_true(radius > 0.0, "relay_site.json's site has no radius")
	for id: String in COMPACT_SITE_IDS:
		var pos: Array = TRAINERS.trainer(id).get("position", [])
		var here := Vector2(float(pos[0]), float(pos[1]))
		assert_true(here.distance_to(centre) <= radius,
			"'%s' stands %.1fm from the relay site centre, outside its own %.0fm radius" % [
				id, here.distance_to(centre), radius])
	for id: String in APPROACH_PICKET_IDS:
		var pos: Array = TRAINERS.trainer(id).get("position", [])
		var here := Vector2(float(pos[0]), float(pos[1]))
		assert_true(here.distance_to(centre) <= APPROACH_RADIUS_M,
			"'%s' stands %.1fm from the relay site centre, outside the %.0fm approach bound" % [
				id, here.distance_to(centre), APPROACH_RADIUS_M])
	for entry: Variant in (_relay_site().get("people", []) as Array):
		var pos: Array = (entry as Dictionary).get("position", [])
		var here := Vector2(float(pos[0]), float(pos[1]))
		assert_true(here.distance_to(centre) <= radius,
			"'%s' stands %.1fm from the relay site centre, outside its own %.0fm radius" % [
				str((entry as Dictionary).get("name", "?")), here.distance_to(centre), radius])
# --- SF34: the three regional captains and their Sigils --------------------------

## id -> the Sigil that captain is the ONLY source of. Spec §3 Band 4.
const CAPTAINS := {
	"captain_field": "field_sigil",
	"captain_ridge": "ridge_sigil",
	"captain_riverwatch": "river_sigil",
}
const HALL_FLAG := "hall_approach_open"


func test_all_three_regional_captains_are_in_the_table() -> void:
	for id: String in CAPTAINS:
		assert_false(TRAINERS.trainer(id).is_empty(),
			"'%s' is not in trainers.json; the Hall approach would have two keys at most" % id)


## Each captain hands over its OWN Sigil, by name. Checked per-captain rather
## than "some sigil is paid somewhere" because two captains paying the same
## disc would leave the gate permanently sealed with every fight won.
func test_each_captain_rewards_its_own_sigil() -> void:
	for id: String in CAPTAINS:
		var ids: Array[String] = []
		for item: Variant in TRAINERS.reward_items(TRAINERS.trainer(id)):
			ids.append(str((item as Dictionary).get("id", "")))
		assert_true(ids.has(str(CAPTAINS[id])),
			"'%s' should reward %s; got %s" % [id, str(CAPTAINS[id]), str(ids)])


func test_no_two_captains_hand_over_the_same_sigil() -> void:
	var seen: Array[String] = []
	for id: String in CAPTAINS:
		for item: Variant in TRAINERS.reward_items(TRAINERS.trainer(id)):
			var item_id := str((item as Dictionary).get("id", ""))
			if item_id.ends_with("_sigil"):
				assert_false(seen.has(item_id), "two captains reward '%s'" % item_id)
				seen.append(item_id)
	assert_eq(seen.size(), 3, "the three captains between them should pay exactly three Sigils")


## SB8/NP2: the captains stand on a REAL rank palette, not an invented key.
## `model_config` resolving empty is already covered for every trainer; this
## asserts the specific thing SF34 promises -- the captain rank, plus one
## regional accent laid over it per captain, never one shared tint.
func test_every_captain_uses_the_real_captain_rank_with_its_own_accent() -> void:
	var accents: Array[String] = []
	for id: String in CAPTAINS:
		var spec := TRAINERS.trainer(id)
		assert_eq(str(spec.get("rank", "")), "captain",
			"'%s' should be on the captain rank palette" % id)
		assert_false(NPC_RANKS.config_for("captain").is_empty(),
			"npc_ranks.json has no 'captain' rank; the captains would have no body")
		var palette: Dictionary = spec.get("palette", {})
		assert_false(palette.is_empty(), "'%s' has no regional accent over the rank base" % id)
		var accent := str(palette.get("*", ""))
		assert_false(accents.has(accent),
			"'%s' shares its accent colour with another captain; spec §21 wants one accent EACH" % id)
		accents.append(accent)


## The rank's own badge survives the accent — a captain who lost the captain
## badge would read as an officer wearing a different coat.
##
## VIS-CAST amended the SHAPE of this check, not its strength. It asserted
## `accessories.size() == 1`, which was a proxy for "the badge is there" back
## when a rank could only carry one accessory. Ranks now carry a `badges` STACK
## (a brass rim seated behind the badge face, `data/config/npc_ranks.json`), so
## the size assertion started failing on a change that does not remove anything.
## The check now says what its own comment always said it was for: the rank
## badge must be PRESENT. It still fails if the badge is dropped, replaced, or
## overwritten by a site's own accessories — which is the failure it exists to
## catch — and it no longer fails merely because a rank gained a rim.
##
## `model_config` also no longer overwrites `palette` wholesale; it merges per
## surface. The old wording is corrected here because a stale test comment is
## how the next reader learns the wrong thing about the code it guards.
func test_the_captain_badge_survives_the_regional_accent() -> void:
	for id: String in CAPTAINS:
		var cfg := TRAINERS.model_config(TRAINERS.trainer(id))
		var accessories: Array = cfg.get("accessories", [])
		assert_false(accessories.is_empty(),
			"'%s' resolves to a body with no accessories at all" % id)
		var names: Array[String] = []
		for entry: Variant in accessories:
			names.append(str((entry as Dictionary).get("name", "")))
		assert_true(names.has("badge"),
			"'%s' resolves to a body with no rank badge; it wears %s" % [id, str(names)])


## §3: "roughly 10-16 entering this band -- tunable, and never player-scaled."
## The band check is deliberately loose (it is tunable); what it really guards
## is a captain accidentally authored at Band 1 levels, or scaled off anything.
func test_captain_teams_sit_in_the_bands_own_level_range() -> void:
	for id: String in CAPTAINS:
		var team: Array = TRAINERS.trainer(id).get("team", [])
		assert_true(team.size() >= 3, "'%s' fields fewer than three creatures" % id)
		for member: Variant in team:
			var level := int((member as Dictionary).get("level", 0))
			assert_true(level >= 10 and level <= 16,
				"'%s' fields a level %d creature; §3 puts this band at roughly 10-16" % [id, level])


## T3-CAPTAINS, owner-direction §8: "different aspects of team-building, not
## escalating stat blocks." There is no type-effectiveness system anywhere in
## this combat build to check that against -- `creature_instance.gd::
## effective_attack`/`effective_defence` read level, bond and buffs, never a
## type chart, and species carry a `type` tag used for flavour/habitat only.
## So "did you build a balanced five" cannot be pinned by a rock-paper-scissors
## matchup here without inventing one, which CLAUDE.md reserves as an owner
## decision. What the rosters DO already carry, and what this guards, is real
## base-stat archetype variety: Halder's team should read as the bulkiest of
## the three (average base HP+defence, not merely level), Vess's as the
## frailest and hardest-hitting. A future edit that quietly re-levels one
## captain to feel "harder" without touching its roster's shape would pass
## every other captain test in this file and still be exactly the "same
## fight, larger HP" spec §3 forbids -- this is the one check that would
## catch it.
func test_the_three_captains_read_as_different_team_shapes_not_just_levels() -> void:
	var bulk := {}
	var punch := {}
	var spread := {}
	for id: String in CAPTAINS:
		var team: Array = TRAINERS.trainer(id).get("team", [])
		var hp_total := 0.0
		var def_total := 0.0
		var atk_total := 0.0
		var member_bulk: Array[float] = []
		for member: Variant in team:
			var def: Dictionary = SPECIES.definition(str((member as Dictionary).get("species", "")))
			var this_hp := float(def.get("base_hp", 0.0))
			var this_def := float(def.get("base_defence", 0.0))
			hp_total += this_hp
			def_total += this_def
			atk_total += float(def.get("base_attack", 0.0))
			member_bulk.append(this_hp + this_def)
		var count := maxf(1.0, float(team.size()))
		bulk[id] = (hp_total + def_total) / count
		punch[id] = atk_total / count
		var lo := float(member_bulk.min()) if not member_bulk.is_empty() else 0.0
		var hi := float(member_bulk.max()) if not member_bulk.is_empty() else 0.0
		spread[id] = hi - lo
	# Halder: bulkiest team on average, the "raw strength, no trick" test.
	assert_true(float(bulk["captain_field"]) > float(bulk["captain_ridge"]) + 10.0,
		("Captain Halder's team (avg base HP+DEF %.1f) should read noticeably bulkier than "
			+ "Captain Vess's (%.1f); right now they are distinguished by level alone")
			% [float(bulk["captain_field"]), float(bulk["captain_ridge"])])
	# Vess: the other half of the same contrast -- frail, hard-hitting, and the
	# test is finishing them fast before their own attack tells.
	assert_true(float(punch["captain_ridge"]) > float(punch["captain_field"]),
		"Captain Vess's team (avg base attack %.1f) should hit harder on average than "
			% float(punch["captain_ridge"])
			+ "Captain Halder's (%.1f), the other half of the same contrast" % float(punch["captain_field"]))
	# Oreth: the roster itself is the test, not its average -- a lone bulky
	# wall alongside genuinely frailer attackers in the SAME three, so no
	# single answer (all-tank, all-glass) covers the whole fight. Pinned as
	# the widest per-member bulk spread of the three, which is what "not all
	# one type -- you'll want a plan" is actually describing mechanically.
	assert_true(float(spread["captain_riverwatch"]) > float(spread["captain_field"]),
		("Captain Oreth's team (member bulk spread %.1f) should be more internally mixed than "
			+ "Captain Halder's uniform one (%.1f); a composition test needs a roster with more than "
			+ "one shape in it") % [float(spread["captain_riverwatch"]), float(spread["captain_field"])])


## §10: "a lightweight readiness communication layer... approximate expected
## level range, whether varied types are recommended, whether it is an
## endurance sequence." Not a new stat and not a level lock -- a line in the
## challenge conversation the player already reads before the fight starts.
## Oreth's line already did this ("Not all one type -- you'll want a plan,
## not a favourite"); this pins that all three now carry their own signal and
## that the three are not interchangeable boilerplate.
func test_each_captains_challenge_signals_its_own_kind_of_readiness() -> void:
	var signal_words := {
		"captain_field": ["strongest", "trick"],
		"captain_ridge": ["breathing", "left in your five"],
		"captain_riverwatch": ["not all one type", "plan"],
	}
	var seen_lines: Array[String] = []
	for id: String in CAPTAINS:
		var challenge := str(TRAINERS.trainer(id).get("challenge", ""))
		var convo: Dictionary = RUNNER.table().get(challenge, {})
		var lines: Array = convo.get("lines", [])
		var joined := " ".join(lines).to_lower()
		assert_false(joined.is_empty(), "'%s' opens no lines at all" % challenge)
		for word: String in signal_words[id]:
			assert_true(joined.contains(word),
				"'%s' should signal its own readiness ('%s'); got: %s" % [challenge, word, joined])
		assert_false(seen_lines.has(joined), "'%s' repeats another captain's challenge text verbatim" % challenge)
		seen_lines.append(joined)


## The done-when, at the data level: sealed at 2/3, open at 3/3, using the real
## reward table and the real gate class. The scene-tree half of this is
## `tests/smoke_trainer_battle.gd`.
func test_beating_two_captains_leaves_the_hall_approach_sealed() -> void:
	var bag: RefCounted = INVENTORY.new(ITEM_DB.new())
	var progression: RefCounted = PROGRESSION_STATE.new()
	var gate: RefCounted = ITEM_GATE.new(CAPTAINS.values(), HALL_FLAG)
	for id: String in ["captain_field", "captain_ridge"]:
		for item: Variant in TRAINERS.reward_items(TRAINERS.trainer(id)):
			bag.add(str((item as Dictionary).get("id", "")), int((item as Dictionary).get("count", 1)))
	assert_eq(gate.held(bag), 2)
	assert_false(gate.try_open(bag, progression), "the Hall approach opened on two Sigils")
	assert_false(progression.has(HALL_FLAG))
	# and nothing was spent on the failed attempt
	assert_eq(bag.count("field_sigil"), 1)
	assert_eq(bag.count("ridge_sigil"), 1)


func test_beating_all_three_captains_opens_the_hall_approach() -> void:
	var bag: RefCounted = INVENTORY.new(ITEM_DB.new())
	var progression: RefCounted = PROGRESSION_STATE.new()
	var gate: RefCounted = ITEM_GATE.new(CAPTAINS.values(), HALL_FLAG)
	for id: String in CAPTAINS:
		for item: Variant in TRAINERS.reward_items(TRAINERS.trainer(id)):
			bag.add(str((item as Dictionary).get("id", "")), int((item as Dictionary).get("count", 1)))
	assert_eq(gate.held(bag), 3)
	assert_true(gate.try_open(bag, progression), "three Sigils did not open the Hall approach")
	assert_true(progression.has(HALL_FLAG))
	for sigil: Variant in CAPTAINS.values():
		assert_eq(bag.count(str(sigil)), 0, "%s was not consumed by the gate" % str(sigil))


## --- R8.3: the Warden --------------------------------------------------------
##
## The chapter's last fight is an ordinary row of this same table and that is
## the claim worth defending: no boss mode, no boss script, no second combat
## substrate. What makes him the boss is a full team and the highest levels in
## the chapter, and both are checkable here.

const WARDEN_ID := "warden_aldis"
const CLIMAX_CONFIG := "res://data/config/stronghold_climax.json"


func _climax() -> Dictionary:
	var file := FileAccess.open(CLIMAX_CONFIG, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func test_the_warden_is_an_ordinary_row_of_this_table() -> void:
	var warden := TRAINERS.trainer(WARDEN_ID)
	assert_false(warden.is_empty(), "trainers.json has no '%s'; there is no boss fight" % WARDEN_ID)
	assert_eq(str(warden.get("rank", "")), "warden",
		"the Warden does not carry npc_ranks.json's top rank; he would read as another captain")
	assert_ne(str(warden.get("challenge", "")), "", "the Warden has no challenge conversation")
	assert_true(RUNNER.has(str(warden.get("challenge", ""))),
		"the Warden's challenge conversation is not in the dialogue table")
	assert_true(RUNNER.has(str(warden.get("defeated", ""))),
		"the Warden's beaten conversation is not in the dialogue table")
	assert_false(bool(warden.get("rechallenge", false)),
		"the Warden is re-fightable; the chapter's last fight must not be an XP faucet")


## Spec §5 and §12: a FULL team of five, the only one in the chapter, met by a
## player whose own limit is the same five. And the levels are above SF34's
## captains — a boss the captains' team clears is not the end of anything.
func test_the_wardens_team_is_the_hardest_in_the_chapter() -> void:
	var warden := TRAINERS.trainer(WARDEN_ID)
	var team := TRAINERS.team_of(warden)
	assert_eq(team.size(), 5,
		"the Warden fields %d creatures; §5's five-creature limit only lands if the boss meets it" % team.size())

	var lowest := 999
	var highest := 0
	for entry: Variant in team:
		var level := int((entry as Dictionary).get("level", 0))
		lowest = mini(lowest, level)
		highest = maxi(highest, level)
		assert_true(SPECIES.definition(str((entry as Dictionary).get("species", ""))).size() > 0,
			"the Warden fields '%s', which is not in species.json" % str((entry as Dictionary).get("species", "")))

	var captain_high := 0
	for entry: Variant in TRAINERS.team_of(TRAINERS.trainer("relay_captain")):
		captain_high = maxi(captain_high, int((entry as Dictionary).get("level", 0)))
	assert_true(lowest > captain_high,
		"the Warden's weakest creature (Lv %d) is not above the relay captain's best (Lv %d)" % [lowest, captain_high])
	assert_true(highest >= lowest + 2,
		"the Warden has no ace; his team is flat at Lv %d-%d" % [lowest, highest])

	# Three types across the five, so no single answer sweeps the fight.
	var types := {}
	for entry: Variant in team:
		types[str(SPECIES.definition(str((entry as Dictionary).get("species", ""))).get("type", ""))] = true
	assert_true(types.size() >= 3,
		"the Warden's five cover only %d type(s); one counter would sweep the chapter's last fight" % types.size())


## R8.4 waits on the Warden's defeat flag and the machine is gated on it, so a
## rename here would silently make the Legendary Chamber's lever unreachable —
## or, worse, reachable with the boss still standing, which breaks §28's order.
func test_the_wardens_defeat_flag_is_what_gates_the_chamber() -> void:
	assert_eq(str(TRAINERS.trainer(WARDEN_ID).get("defeat_flag", "")), "defeated_warden")
	var flags: Dictionary = _climax().get("flags", {})
	assert_eq(str(flags.get("gate", "")), "defeated_warden",
		"stronghold_climax.json's machine gate is not the Warden's defeat flag; §28's order could be walked around")
	assert_eq(str(flags.get("legendary_freed", "")), "legendary_freed",
		"the flag SG44's world event reads is not named 'legendary_freed'")


## He is placed by the climax node from R8.2's `warden_stand` mark, not by the
## world's own trainer pass and not by the stronghold's gauntlet pass — an
## accidentally empty `placed_by` would stand a second Warden out in the
## meadow, which is a spoiler and a duplicate body at once.
func test_the_warden_is_placed_by_the_climax_and_nothing_else() -> void:
	assert_eq(str(TRAINERS.trainer(WARDEN_ID).get("placed_by", "")), "stronghold_climax")
	var warden: Dictionary = _climax().get("warden", {})
	assert_eq(str(warden.get("trainer", "")), WARDEN_ID,
		"stronghold_climax.json places a trainer id that is not in trainers.json")
	assert_eq(str(warden.get("placed_by", "")), "stronghold_climax",
		"the climax asks trainer_npc.gd for a group the Warden's row does not name")
	assert_eq(str(warden.get("mark", "")), "warden_stand",
		"the climax does not adopt R8.2's own 'warden_stand' mark; it would invent a second position")


## CLAUDE.md's hard rule, checked in data rather than trusted to a comment:
## the legendary is an EXISTING roster species. A new species id appearing
## here is a new creature mesh by another name.
func test_the_legendary_is_an_existing_roster_species() -> void:
	var legendary: Dictionary = _climax().get("legendary", {})
	var id := str(legendary.get("species", ""))
	assert_ne(id, "", "stronghold_climax.json names no legendary species")
	assert_true(SPECIES.definition(id).size() > 0,
		"the legendary is '%s', which is not in species.json — no new creature meshes (CLAUDE.md)" % id)
	assert_true(float(legendary.get("scale", 1.0)) > 1.0,
		"the legendary is not scaled above its own roster size; it would read as a wild spawn")
	assert_false((legendary.get("bound", {}) as Dictionary).is_empty(),
		"the legendary has no containment VFX; scale alone is not differentiation")
	assert_false((legendary.get("freed", {}) as Dictionary).is_empty(),
		"the legendary looks the same freed as it did bound")


## --- SH47 / D42: the chapter's pacing, pinned in data ------------------------
##
## `SH47` tuned this chapter to a 3-4 hour first completion (`D42`) by
## flattening the XP curve, doubling the per-fight award and closing two level
## gaps in the trainer table. `tools/_probe_pacing.py` is what measured it and
## what to re-run after any further tuning; the tests below are the part of
## that measurement worth failing a build over, because every one of them
## guards the same failure: the critical path stops paying for the levels the
## next thing on it expects, and the player makes up the difference by killing
## level-2-to-6 field creatures in circles. `MEADOWS_PROGRESSION_SPEC.md` §11
## names that exact activity as the one kind of grind this game must not have.

const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const WARRENS_PATH := "res://data/config/burrow_warrens.json"

## The chapter's critical-path trainers, in the order they are fought. Optional
## trainers and patrols are deliberately absent: the point of these tests is
## that the REQUIRED fights alone carry the player, so a player who skips every
## optional one is never walled.
const CRITICAL_PATH := [
	"practice_trainer", "trainer_mira", "trainer_tam", "trainer_oskar",
	# TOURNAMENT-1: the village tournament's three fought rounds and the Team
	# Tether grunt now standing where Oskar's key used to be. All four are
	# mandatory -- the bracket is Gate B's own ladder and the grunt holds the
	# only South Bridge Key in the game -- so leaving them out would understate
	# what the chapter actually pays and overstate the level jump into Band 2.
	"tournament_quarter_mira", "tournament_semi_tam", "tournament_final_oskar",
	"south_bridge_grunt",
	"relay_picket_hess", "relay_picket_orrin", "relay_officer_dell", "relay_captain",
	"captain_field", "captain_ridge", "captain_riverwatch",
	"stronghold_patrol", "stronghold_courtyard", "stronghold_elite", "warden_aldis",
]


func _warrens() -> Dictionary:
	var file := FileAccess.open(WARRENS_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


## Every enemy creature the critical path fields, in fight order, as levels —
## the trainer teams plus the Burrow Warrens' own residents and guardian, which
## are ordinary wild fights but are not optional.
func _critical_path_levels() -> Array:
	var levels: Array = []
	for id: String in CRITICAL_PATH:
		if id == "relay_picket_hess":
			var warrens: Dictionary = _warrens()
			for entry: Variant in warrens.get("spawns", []):
				for _i in range(int((entry as Dictionary).get("count", 1))):
					levels.append(int((entry as Dictionary).get("level", 1)))
			levels.append(int((warrens.get("guardian", {}) as Dictionary).get("level", 1)))
		for member: Variant in TRAINERS.team_of(TRAINERS.trainer(id)):
			levels.append(int((member as Dictionary).get("level", 1)))
	return levels


## What the critical path pays a lead creature that wins every one of its own
## fights: the per-kill award for each enemy plus every authored `xp_bonus`,
## including the warrens' clear reward.
func _critical_path_xp() -> int:
	var cfg: Dictionary = PROGRESSION.config()
	var total := 0
	for level: Variant in _critical_path_levels():
		total += PROGRESSION.xp_award_for(int(level), cfg)
	for id: String in CRITICAL_PATH:
		total += TRAINERS.reward_xp_bonus(TRAINERS.trainer(id))
	total += int((_warrens().get("clear", {}) as Dictionary).get("reward", {}).get("xp_bonus", 0))
	return total


func _cumulative_xp(from_level: int, to_level: int) -> int:
	var cfg: Dictionary = PROGRESSION.config()
	var total := 0
	for level in range(from_level, to_level):
		total += PROGRESSION.xp_to_next(level, cfg)
	return total


## THE LOAD-BEARING ONE. The fights the chapter actually contains have to pay
## for the levels the chapter actually asks for. Before `SH47` this ratio was
## 0.17: the critical path paid 5104 xp against the 30135 needed to reach the
## Warden-ready band, and the player found the other 83% by grinding the field.
func test_the_critical_path_alone_pays_for_the_warden_ready_level() -> void:
	var cfg: Dictionary = PROGRESSION.config()
	var starter := int((cfg.get("level", {}) as Dictionary).get("starter_level", 3))
	var warden_ace := 0
	for member: Variant in TRAINERS.team_of(TRAINERS.trainer(WARDEN_ID)):
		warden_ace = maxi(warden_ace, int((member as Dictionary).get("level", 1)))
	# Level with the Warden's ace, not above it: the boss is allowed to be the
	# hardest fight in the chapter, it is not allowed to be unreachable.
	var needed := _cumulative_xp(starter, warden_ace)
	var paid := _critical_path_xp()
	assert_true(paid >= needed,
		("the critical path pays %d xp but reaching L%d from the L%d starter costs %d — "
		+ "the gap is made up by grinding wild creatures, which is §11's 'bad grind'")
		% [paid, warden_ace, starter, needed])


## The curve must not compound out of reach. With a LINEAR award, a cost curve
## of `base * L^e` makes one level cost proportionally more fights as L rises;
## at the pre-SH47 exponent of 1.6 a level cost 10.9 level-matched fights at L5
## and 33.7 at L19. The chapter does not contain 33 fights per level and never
## will, so the exponent is what has to give.
func test_a_level_never_costs_more_than_six_level_matched_fights() -> void:
	var cfg: Dictionary = PROGRESSION.config()
	for level in range(3, 23):
		var cost: int = PROGRESSION.xp_to_next(level, cfg)
		var award: int = PROGRESSION.xp_award_for(level, cfg)
		assert_true(float(cost) / float(maxi(award, 1)) <= 6.0,
			"L%d costs %.1f level-matched fights (%d xp at %d each); the chapter's own bands do not contain that many"
			% [level, float(cost) / float(maxi(award, 1)), cost, award])


## Monotonicity is the one property `progression.gd::xp_to_next` promises in
## its own header, and flattening the exponent must not have broken it.
func test_each_level_still_costs_strictly_more_than_the_last() -> void:
	var cfg: Dictionary = PROGRESSION.config()
	for level in range(1, int((cfg.get("level", {}) as Dictionary).get("cap", 50))):
		assert_true(PROGRESSION.xp_to_next(level + 1, cfg) > PROGRESSION.xp_to_next(level, cfg),
			"L%d costs no more than L%d; the curve is flat or inverted there" % [level + 1, level])


## No step on the critical path may jump more than four levels above the last
## thing the player was asked to beat. A bigger step is a wall, and a wall in a
## game with no level requirement anywhere is answered the only way it can be:
## by grinding the field until it goes away. The two this caught were Band 1's
## level-7 gate handing the player to a level-18 warren guardian, and the
## regional captains' level-16 cap handing them to a level-22 gauntlet.
func test_no_step_on_the_critical_path_jumps_more_than_four_levels() -> void:
	var levels: Array = _critical_path_levels()
	var high := 0
	for i in levels.size():
		var level := int(levels[i])
		assert_true(level <= high + 4,
			"fight %d fields a level %d creature after a peak of %d; that is a %d-level wall"
			% [i, level, high, level - high])
		high = maxi(high, level)


## Spec §8's shape: the Warden is the culmination. A gauntlet trainer standing
## above the boss they guard inverts the whole approach, and it was literally
## true before `SH47` — the elite fielded 21 and 22 against the Warden's 20.
func test_nothing_in_the_stronghold_out_levels_the_warden() -> void:
	var warden_ace := 0
	for member: Variant in TRAINERS.team_of(TRAINERS.trainer(WARDEN_ID)):
		warden_ace = maxi(warden_ace, int((member as Dictionary).get("level", 1)))
	for id: String in ["stronghold_patrol", "stronghold_courtyard", "stronghold_elite"]:
		for member: Variant in TRAINERS.team_of(TRAINERS.trainer(id)):
			assert_true(int((member as Dictionary).get("level", 1)) < warden_ace,
				"%s fields a level %d creature against the Warden's own ace at %d"
				% [id, int((member as Dictionary).get("level", 1)), warden_ace])
