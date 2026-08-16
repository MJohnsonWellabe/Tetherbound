extends "res://tests/test_case.gd"

## SB9 — autoload/progression_state.gd, the flag store behind objective/
## completion/world-state tracking.
##
## Every failure here is one the player would meet as broken story state: a
## gate that stays locked after the key is used, an objective that "unfinds"
## itself, or a flag that quietly does not survive a save. Pure logic, no
## scene tree — the same split test_map_state.gd and test_inventory.gd draw.

const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")

var progression: RefCounted = null


func before_each() -> void:
	progression = PROGRESSION_STATE.new()


func test_a_fresh_store_has_nothing_set() -> void:
	assert_false(progression.has("bridge_unlocked"))
	assert_false(progression.completed("trainer_mira_defeated"))
	assert_eq(progression.all_set(), [])


func test_set_flag_makes_has_true() -> void:
	progression.set_flag("bridge_unlocked")
	assert_true(progression.has("bridge_unlocked"))


func test_completed_is_the_same_query_as_has() -> void:
	progression.set_flag("trainer_mira_defeated")
	assert_true(progression.completed("trainer_mira_defeated"))
	assert_false(progression.completed("trainer_oskar_defeated"))


func test_set_flag_defaults_to_true() -> void:
	progression.set_flag("captive_rescued")
	assert_true(progression.has("captive_rescued"))


func test_set_flag_with_false_clears_it() -> void:
	progression.set_flag("stronghold_unlocked")
	assert_true(progression.has("stronghold_unlocked"))
	progression.set_flag("stronghold_unlocked", false)
	assert_false(progression.has("stronghold_unlocked"))


func test_clearing_an_unset_flag_is_a_harmless_no_op() -> void:
	progression.set_flag("never_set", false)
	assert_false(progression.has("never_set"))


func test_setting_an_already_set_flag_does_not_bump_revision() -> void:
	progression.set_flag("warden_defeated")
	var revision_after_first_set: int = progression.revision
	progression.set_flag("warden_defeated")
	assert_eq(progression.revision, revision_after_first_set)


func test_clearing_an_already_unset_flag_does_not_bump_revision() -> void:
	var before: int = progression.revision
	progression.set_flag("dungeon_cleared", false)
	assert_eq(progression.revision, before)


func test_set_flag_bumps_revision_on_a_real_change() -> void:
	var before: int = progression.revision
	progression.set_flag("dungeon_cleared")
	assert_true(progression.revision > before)


func test_all_set_lists_every_flag_currently_set_and_nothing_cleared() -> void:
	progression.set_flag("a")
	progression.set_flag("b")
	progression.set_flag("c")
	progression.set_flag("b", false)
	var flags: Array = progression.all_set()
	assert_eq(flags.size(), 2)
	assert_true(flags.has("a"))
	assert_true(flags.has("c"))
	assert_false(flags.has("b"))


func test_save_data_lists_exactly_the_set_flags() -> void:
	progression.set_flag("sigil_lower")
	progression.set_flag("sigil_upper")
	var data: Dictionary = progression.save_data()
	var flags: Array = data.get("flags", [])
	assert_eq(flags.size(), 2)
	assert_true(flags.has("sigil_lower"))
	assert_true(flags.has("sigil_upper"))


func test_load_data_round_trips_through_save_data() -> void:
	progression.set_flag("south_bridge_open")
	progression.set_flag("mill_crossing_restored")
	var data: Dictionary = progression.save_data()

	var reloaded: RefCounted = PROGRESSION_STATE.new()
	reloaded.load_data(data)
	assert_true(reloaded.has("south_bridge_open"))
	assert_true(reloaded.has("mill_crossing_restored"))
	assert_false(reloaded.has("never_set"))


func test_load_data_replaces_whatever_was_already_set() -> void:
	progression.set_flag("stale_flag")
	progression.load_data({"flags": ["fresh_flag"]})
	assert_false(progression.has("stale_flag"))
	assert_true(progression.has("fresh_flag"))


func test_load_data_tolerates_an_empty_dictionary() -> void:
	progression.set_flag("will_be_cleared")
	progression.load_data({})
	assert_eq(progression.all_set(), [])


func test_load_data_ignores_non_string_and_empty_entries() -> void:
	progression.load_data({"flags": ["real_flag", 7, "", null, true]})
	assert_eq(progression.all_set(), ["real_flag"])


## --- OF30: the flags a one-time gift depends on ------------------------------

## Tam the blacksmith hands over the axe, pickaxe and knife exactly once, and
## teaches the orb recipe exactly once. Both facts live here and nowhere else —
## `village_npcs.greeting_for()` reads `tam_tools_given` to decide whether to
## offer the handover again, and `game_state.recipe_known()` reads
## `recipe_orb_basic` to decide whether the orb can be made.
##
## The store is generic and stays generic; what these two cases pin is that the
## specific ids OF30 relies on behave like every other flag through the one
## route that could quietly lose them — a save and a reload. A gift flag that
## did not survive would re-arm the handover on the next launch, and the player
## would find a second axe in a satchel that already had one.
func test_the_smiths_gift_flags_survive_a_save_and_reload() -> void:
	progression.set_flag("tam_tools_given")
	progression.set_flag("recipe_orb_basic")

	var reloaded: RefCounted = PROGRESSION_STATE.new()
	reloaded.load_data(progression.save_data())
	assert_true(reloaded.has("tam_tools_given"), "a re-loaded save would hand the tools over again")
	assert_true(reloaded.has("recipe_orb_basic"), "a re-loaded save would forget the orb recipe")


## A save written before OF30 existed has neither flag, and must read as "not
## yet" rather than as anything else — an old save meets Tam for the first time.
func test_a_save_from_before_the_blacksmith_has_neither_flag() -> void:
	progression.load_data({"flags": ["road_gate_open"]})
	assert_false(progression.has("tam_tools_given"))
	assert_false(progression.has("recipe_orb_basic"))


## --- SG46: the Meadows answers ------------------------------------------------
##
## Spec §9 asks for six different things to change when the Warden falls, and
## the failure it is guarding against is subtle: not "nothing happened", but
## "five systems reacted and the sixth quietly did not, because each of them
## reads its own flag id out of its own config file". So this section pins the
## one thing that cannot be checked by looking at any single file — that every
## consumer of the ending is keyed on the SAME flag the ending actually sets —
## and then that each branch of §9's list really exists in the data.
##
## The world half (the sky changing, the plants coming back, the barrier still
## holding) is tests/smoke_boss.gd's; it needs a built scene. This half is the
## flag logic, which needs none.

const VILLAGE_NPCS := preload("res://scripts/world/village_npcs.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")

const FREED_FLAG := "legendary_freed"


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _villager(who: String) -> Dictionary:
	for entry: Variant in (_json("res://data/config/village_npcs.json").get("villagers", []) as Array):
		if entry is Dictionary and str((entry as Dictionary).get("name", "")) == who:
			return entry
	return {}


func test_every_consumer_of_the_ending_reads_the_flag_the_ending_sets() -> void:
	var climax := _json("res://data/config/stronghold_climax.json")
	var set_flag := str((climax.get("flags", {}) as Dictionary).get("legendary_freed", ""))
	assert_eq(set_flag, FREED_FLAG,
		"the climax no longer sets '%s'; every world change below is keyed on it" % FREED_FLAG)
	assert_eq(str(_json("res://data/config/rift_collapse.json").get("flag", "")), set_flag,
		"SG44's world event listens for a different flag than the climax sets")
	assert_eq(str(_json("res://data/config/meadow_healing.json").get("flag", "")), set_flag,
		"SG46's healing listens for a different flag than the climax sets")


## §9's "the rescued NPC is back in the settlement" — SE27 already built this,
## so this is a verification, not a rebuild: she is placed in the square by the
## rescue flag and nothing about the ending may have disturbed that.
func test_the_rescued_npc_is_still_home_after_the_ending() -> void:
	var sela := _villager("Sela")
	assert_false(sela.is_empty(), "the rescued NPC is gone from the village config")
	assert_false(VILLAGE_NPCS.placement_holds(sela, progression),
		"the rescued NPC stands in the square before she has been rescued")
	progression.set_flag("captive_rescued")
	assert_true(VILLAGE_NPCS.placement_holds(sela, progression),
		"the rescued NPC is not in the settlement after the rescue")
	progression.set_flag(FREED_FLAG)
	assert_true(VILLAGE_NPCS.placement_holds(sela, progression),
		"the ending removed the rescued NPC from the village")
	assert_eq(VILLAGE_NPCS.greeting_for(sela, progression), "village_rescued_ranger_home")


## §9's "villagers acknowledge the victory". Every villager who has something to
## say about it says it FIRST, and — the part that is easy to get wrong — none
## of them loses anything they were still owed by saying it.
func test_the_villagers_acknowledge_the_victory() -> void:
	progression.set_flag("mira_shop_open")
	progression.set_flag("oskar_trade_open")
	progression.set_flag("tam_tools_given")
	progression.set_flag("recipe_orb_basic")
	var acknowledged := 0
	for who: String in ["Mira", "Oskar", "Tam", "Quarry Foreman"]:
		var spec := _villager(who)
		assert_false(spec.is_empty(), "%s is missing from village_npcs.json" % who)
		var before := VILLAGE_NPCS.greeting_for(spec, progression)
		progression.set_flag(FREED_FLAG)
		var after := VILLAGE_NPCS.greeting_for(spec, progression)
		progression.set_flag(FREED_FLAG, false)
		if after != before:
			acknowledged += 1
	assert_true(acknowledged >= 3,
		"only %d villagers say anything different after the Warden; §9 asks the region to answer" % acknowledged)


## The trap in the branch above: a victory line placed ahead of a one-time gift
## eats the gift forever. Tam's tools and Mira's stall opening are both
## one-shot, and a player can reach the ending without having taken either.
func test_the_victory_lines_do_not_swallow_a_one_time_gift() -> void:
	progression.set_flag(FREED_FLAG)
	assert_eq(VILLAGE_NPCS.greeting_for(_villager("Tam"), progression), "village_tam_tools",
		"the ending swallowed the blacksmith's one-time handover")
	assert_eq(VILLAGE_NPCS.greeting_for(_villager("Mira"), progression), "village_mira_shop_intro",
		"the ending swallowed the merchant's one-time stall opening")


## §9's "at least one outward spoke gains new dialogue", and R8.6's hook. The
## traveller at the storm road does not exist before the machinery fails and
## does after — SE27's own placement mechanism, reused rather than rebuilt.
func test_an_outward_spoke_gains_a_voice_only_after_the_ending() -> void:
	var kell := _villager("Kell")
	assert_false(kell.is_empty(), "nobody stands at the reconnected spoke; R8.6 has no voice")
	assert_false(VILLAGE_NPCS.placement_holds(kell, progression),
		"the spoke traveller is standing on the road before the Rift collapses")
	progression.set_flag(FREED_FLAG)
	assert_true(VILLAGE_NPCS.placement_holds(kell, progression),
		"the spoke traveller never appears, even after the ending")
	assert_eq(VILLAGE_NPCS.greeting_for(kell, progression), "spoke_traveller_storm_road")
	# And she is out at the spoke rather than in the square: the road's own end
	# is ~192m from the origin and the village is inside 30m of it.
	var at: Array = kell.get("position", [])
	assert_eq(at.size(), 2, "the spoke traveller has no position")
	var distance := Vector2(float(at[0]), float(at[1])).length()
	assert_true(distance > 150.0,
		"the spoke traveller stands %.0fm from the origin; that is the village, not a spoke" % distance)


## §9's "patrol density drops", and the half of it that is a rule rather than an
## effect: a trainer the player has already beaten stays beaten. The withdrawal
## list may only name real trainers with real defeat flags, and nothing in the
## ending may clear one.
func test_patrols_thin_without_unbeating_anybody() -> void:
	var patrols: Dictionary = _json("res://data/config/meadow_healing.json").get("patrols", {})
	var withdraw: Array = patrols.get("withdraw", [])
	assert_true(withdraw.size() >= 3,
		"only %d Team Tether trainers are ever withdrawn; §9's patrol density does not drop" % withdraw.size())
	for raw: Variant in withdraw:
		var spec := TRAINERS.trainer(str(raw))
		assert_false(spec.is_empty(), "the withdrawal list names '%s', who is not in trainers.json" % str(raw))
		var flag := str(spec.get("defeat_flag", ""))
		assert_ne(flag, "", "'%s' has no defeat flag, so 'already beaten' cannot be asked about them" % str(raw))
		progression.set_flag(flag)
	progression.set_flag(FREED_FLAG)
	for raw: Variant in withdraw:
		var flag := str(TRAINERS.trainer(str(raw)).get("defeat_flag", ""))
		assert_true(progression.has(flag),
			"'%s' stopped counting as beaten when the region answered" % str(raw))


## §9's "barriers deactivate". The healing sets each gate's OWN flag — the same
## one its key sets and the same one item_gate.gd reads on a reload — so a save
## written after the Warden opens them for the ordinary reason.
func test_the_barrier_flags_are_the_gates_own_flags() -> void:
	var barriers: Dictionary = _json("res://data/config/meadow_healing.json").get("barriers", {})
	var flags: Array = barriers.get("flags", [])
	assert_true(flags.has("road_gate_open"), "the road gate is never deactivated by the ending")
	assert_true(flags.has("hall_approach_open"), "the Meadows Hall approach is never deactivated by the ending")
	for raw: Variant in flags:
		progression.set_flag(str(raw))
	var reloaded: RefCounted = PROGRESSION_STATE.new()
	reloaded.load_data(progression.save_data())
	for raw: Variant in flags:
		assert_true(reloaded.has(str(raw)),
			"a gate the ending opened is shut again after a save and reload")
