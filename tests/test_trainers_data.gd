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


## Oskar's reward is checked by name and not just by "some item exists": SC14
## reads `south_bridge_key` specifically off his table entry, and a renamed
## item id here would silently strand that task.
func test_oskars_reward_names_the_south_bridge_key() -> void:
	var ids: Array[String] = []
	for item: Variant in TRAINERS.reward_items(TRAINERS.trainer("trainer_oskar")):
		ids.append(str((item as Dictionary).get("id", "")))
	assert_true(ids.has("south_bridge_key"),
		"trainer_oskar's reward should include south_bridge_key; got %s" % str(ids))


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

const NPC_RANKS := preload("res://scripts/characters/npc_ranks.gd")
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


## SE23 is not built yet, and the one thing that keeps these four and the
## captive on the same patch of ground when it is, is that every position is
## derived from relay_site.json's single authored centre. This is that promise,
## written down: if somebody moves the site, this fails until they move the
## cast with it.
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
	for id: String in RELAY_IDS:
		var pos: Array = TRAINERS.trainer(id).get("position", [])
		var here := Vector2(float(pos[0]), float(pos[1]))
		assert_true(here.distance_to(centre) <= radius,
			"'%s' stands %.1fm from the relay site centre, outside its own %.0fm radius" % [
				id, here.distance_to(centre), radius])
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


## The rank's own badge survives the accent. `model_config` overwrites the
## palette wholesale, so a captain who lost the captain badge would read as an
## officer wearing a different coat.
func test_the_captain_badge_survives_the_regional_accent() -> void:
	for id: String in CAPTAINS:
		var cfg := TRAINERS.model_config(TRAINERS.trainer(id))
		var accessories: Array = cfg.get("accessories", [])
		assert_eq(accessories.size(), 1,
			"'%s' resolves to a body with no rank badge" % id)
		assert_eq(str((accessories[0] as Dictionary).get("name", "")), "badge",
			"'%s' wears something other than the rank badge" % id)


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
