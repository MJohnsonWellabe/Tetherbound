extends "res://tests/test_case.gd"

## D99 / MP_STATE_SEAM.md §3 and §5 item 2: every story flag id this game can
## produce resolves to `world` or `player`, and an id the table does not name is
## a TEST FAILURE, never a runtime default.
##
## Why the failure has to live here rather than at the write: defaulting an
## unknown id either way is wrong in a way that only shows up with a second
## player. Default-world makes a friend's tutorial already done; default-player
## leaves a gate closed for the friend who did not open it. So the runtime
## behaviour is deliberately forgiving (`merged_progression.set_flag` pushes an
## error and writes to the world store so nothing stalls) and THIS file is what
## guarantees shipped data never takes that path.
##
## The sweep is over SOURCES, not over a hand-copied list: objectives.json, the
## six trainer tables, realm_hearts.json, the Cloudreach chapter/world/runtime
## data, the relay, the Warrens, meadow healing, every `flag:` effect in every
## dialogue file, and a fixture list of the writer-site literals the assumption
## inventory §8/§8b names that live in .gd constants rather than in data. A new
## trainer, a new objective or a new dialogue flag therefore fails this test
## until someone classifies it, which is exactly D99's point.

const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const CREATURE_TRADE := preload("res://scripts/trade/creature_trade.gd")
const RIDING := preload("res://scripts/world/riding_controller.gd")

const SCOPES_PATH := "res://data/progression/flag_scopes.json"
const OBJECTIVES_PATH := "res://data/progression/objectives.json"
const TRADE_PATH := "res://data/config/trade.json"

## Keys whose STRING value is a flag id, anywhere in any data file.
const FLAG_STRING_KEYS := [
	"flag", "flag_id", "defeat_flag", "unlock_flag", "requires_unlock",
	"earned_flag", "placed_flag", "entry_key_flag", "set_physical_flag",
	"clear_flag", "once_id", "retired_by", "unless_flag", "requires_flag",
	"revealed_by",
]
## Keys whose ARRAY value is a list of flag ids.
const FLAG_ARRAY_KEYS := [
	"flags", "physical_state_flags", "requires_flags", "count_flags",
	"reward_flags",
]

## The writer-site literals that live in GDScript constants rather than in a
## data file (assumption inventory §8/§8b). Each is written as the SOURCE FILE
## says it, so a rename there fails here rather than silently going unscoped.
##
## `tm_pickup.gd`'s prefix and the `wild_once_<order>` string have no helper to
## call, so their literals are pinned by reading the source -- the same
## technique lane 0.E used in `test_characterize_flag_keys.gd`.
const WRITER_SITE_LITERALS := [
	# scripts/world/cart_repair.gd
	"broken_cart_met", "band1_broken_cart_repaired",
	# scripts/world/river_nest_clear.gd
	"river_nest_doss_met", "river_nest_doss_cleared",
	# scripts/world/road_gate.gd
	"road_gate_open",
	# scripts/world/gated_crossing.gd / south_bridge.gd / mill_crossing.gd
	"south_bridge_open", "mill_crossing_restored",
	# scripts/world/realm_gate.gd
	"realm_gate_cloudreach_unlocked",
	# scripts/world/alpha_pins.gd
	"alpha_pin_intro_seen",
	# scripts/build/creature_bed.gd, scripts/build/home_progress.gd
	"creature_bed_built", "creature_bed_built_2", "creature_bed_built_3",
	"home_built", "home_materials_gathered",
	# scripts/build/player_bed.gd, scripts/world/night_rest.gd
	"player_slept_at_home",
	# scripts/world/tournament.gd
	"tournament_team_ready", "tournament_training_ready",
	"tournament_condition_ready", "tournament_team_fed",
	# scripts/world/stronghold_climax.gd
	"legendary_freed", "legendary_joined", "legendary_settled",
	# scripts/world/burrow_warrens.gd
	"warrens_cleared", "warrens_heartstone_taken",
	# scripts/save/save_game.gd::_reconcile_meadows_realm_rewards
	"realm_key_cloudreach", "realm_heart_meadows_earned",
	# scripts/world/tether_relay.gd::console_flag()'s own fallback
	"relay_disabled",
	# scripts/player/fly_controller.gd's unlock_flag fallback
	"fly_traversal_unlocked",
]

## Prefixed ids, as their own helper builds them. One representative each; the
## prefix is what the table has to name.
const PREFIXED_SAMPLES := [
	"cache:castle_gate_key",            # item_cache_pickup.gd::flag_id
	"cache:meadows:band1_orb_stash",    # the realm-qualified form
	"pickup:south_bridge_key",          # key_pickup.gd::flag_id
	"tm:tm_gust",                       # tm_pickup.gd::FLAG_PREFIX + id
	"harvest_node:village_berries_1",   # harvest_node.gd::flag_id
	"wild_once_7",                      # encounter_director.gd:417
	"warrens_once_elder_trailpup",      # burrow_warrens.gd::_once_flag_for_nickname
	"opening:beat:road",                # sequence_director.gd
	"opening:mira_visited",             # data/dialogue, `flag:` effect
	"cloudreach_payout:cloudreach_voss",  # cloudreach_physical_runtime.gd:319
]


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}


## Every .json under res://data, walked once.
func _data_files() -> Array[String]:
	var out: Array[String] = []
	_collect_json("res://data", out)
	out.sort()
	return out


func _collect_json(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var full := "%s/%s" % [dir_path, name]
		if dir.current_is_dir():
			_collect_json(full, out)
		elif name.ends_with(".json"):
			out.append(full)
		name = dir.get_next()
	dir.list_dir_end()


## Every flag id any shipped data file names, as `id -> the file that named it`.
func _data_flag_ids() -> Dictionary:
	var found: Dictionary = {}
	for path: String in _data_files():
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		_walk(parsed, path.get_file(), found)
	return found


func _walk(node: Variant, source: String, found: Dictionary) -> void:
	if typeof(node) == TYPE_DICTIONARY:
		for key: Variant in (node as Dictionary).keys():
			var value: Variant = (node as Dictionary)[key]
			if FLAG_STRING_KEYS.has(str(key)):
				_note(value, source, found)
			elif FLAG_ARRAY_KEYS.has(str(key)) and typeof(value) == TYPE_ARRAY:
				for entry: Variant in (value as Array):
					_note(entry, source, found)
			elif str(key) == "reward" and typeof(value) == TYPE_DICTIONARY:
				for entry: Variant in ((value as Dictionary).get("flags", []) as Array):
					_note(entry, source, found)
			elif str(key) == "effects" and typeof(value) == TYPE_ARRAY:
				# Dialogue effects: "flag:<id>" alongside "give:"/"beat:" ones.
				for entry: Variant in (value as Array):
					if typeof(entry) == TYPE_STRING and (entry as String).begins_with("flag:"):
						_note((entry as String).substr("flag:".length()), source, found)
			_walk(value, source, found)
	elif typeof(node) == TYPE_ARRAY:
		for entry: Variant in (node as Array):
			if typeof(entry) == TYPE_STRING and (entry as String).begins_with("flag:"):
				_note((entry as String).substr("flag:".length()), source, found)
			_walk(entry, source, found)


func _note(value: Variant, source: String, found: Dictionary) -> void:
	if typeof(value) != TYPE_STRING:
		return
	var id := value as String
	# "" is "this entry names no flag", which several schemas use on purpose.
	# `region_entered` is `cloudreach_chapter.json`'s unlock_EVENT sentinel, not
	# a flag: `cloudreach_map_state.gd::sync_navigation` branches on it by name
	# before it ever reaches a flag store.
	if id.is_empty() or id == "region_entered" or id.begins_with("_"):
		return
	if not found.has(id):
		found[id] = source


# --- the sweep ---------------------------------------------------------------

func test_every_flag_id_in_shipped_data_resolves_to_world_or_player() -> void:
	var found := _data_flag_ids()
	assert_true(found.size() > 100,
		"sanity: the sweep found %d ids, which is too few to be reading the data" % found.size())
	var unscoped: Array[String] = []
	for id: String in found.keys():
		if PROGRESSION_STATE.scope_of(id).is_empty():
			unscoped.append("%s (from %s)" % [id, str(found[id])])
	unscoped.sort()
	assert_true(unscoped.is_empty(),
		"undeclared flag ids -- classify each in data/progression/flag_scopes.json: %s"
			% ", ".join(unscoped))


func test_every_writer_site_literal_resolves() -> void:
	var unscoped: Array[String] = []
	for id: String in WRITER_SITE_LITERALS:
		if PROGRESSION_STATE.scope_of(id).is_empty():
			unscoped.append(id)
	assert_true(unscoped.is_empty(), "undeclared writer-site flag ids: %s" % ", ".join(unscoped))


func test_every_prefixed_id_resolves_through_its_prefix() -> void:
	for id: String in PREFIXED_SAMPLES:
		assert_false(PROGRESSION_STATE.scope_of(id).is_empty(),
			"'%s' matches no prefix in flag_scopes.json" % id)


func test_generated_ids_from_their_own_helpers_resolve() -> void:
	# Built by the helper that actually builds them at runtime, so a change to
	# the helper's format fails here rather than going unscoped in play.
	assert_eq(PROGRESSION_STATE.scope_of(RIDING.saddle_fitted_flag("terrapup")), "player",
		"a saddle fitted on YOUR creature is your fact, not the world's")
	var traders: Dictionary = _json(TRADE_PATH).get("creature_traders", {})
	assert_false(traders.is_empty(), "sanity: trade.json names at least one creature trader")
	for trader_id: String in traders.keys():
		for period in 3:
			var flag: String = CREATURE_TRADE.swap_flag(trader_id, period)
			assert_eq(PROGRESSION_STATE.scope_of(flag), "player",
				"'%s' -- a swap you took is your payoff" % flag)


# --- objectives.json agrees with the table ----------------------------------

func test_every_objective_entry_carries_a_scope_matching_the_table() -> void:
	var objectives := _json(OBJECTIVES_PATH)
	var checked := 0
	for list_name: String in ["main", "local"]:
		var entries: Variant = objectives.get(list_name, [])
		assert_true(typeof(entries) == TYPE_ARRAY and not (entries as Array).is_empty(),
			"sanity: objectives.json has a '%s' list" % list_name)
		for raw: Variant in (entries as Array):
			var entry := raw as Dictionary
			var flag_id := str(entry.get("flag_id", ""))
			var declared := str(entry.get("scope", ""))
			assert_false(declared.is_empty(),
				"objective '%s' carries no `scope`" % str(entry.get("id", "")))
			assert_eq(declared, PROGRESSION_STATE.scope_of(flag_id),
				"objective '%s' declares scope '%s' but the table says '%s' for '%s'"
					% [str(entry.get("id", "")), declared,
						PROGRESSION_STATE.scope_of(flag_id), flag_id])
			checked += 1
	assert_eq(checked, 33, "every objective entry was checked")


func test_objective_retired_by_and_count_flags_are_scoped_too() -> void:
	# A `retired_by` or a `count_flags` entry is read out of the same store as
	# the entry's own flag; an unscoped one would be looked up in whichever
	# store the merged view happened to try first.
	var objectives := _json(OBJECTIVES_PATH)
	for list_name: String in ["main", "local"]:
		for raw: Variant in (objectives.get(list_name, []) as Array):
			var entry := raw as Dictionary
			var retired := str(entry.get("retired_by", ""))
			if not retired.is_empty():
				assert_false(PROGRESSION_STATE.scope_of(retired).is_empty(),
					"'%s' retired_by '%s' is unscoped" % [str(entry.get("id", "")), retired])
			for counted: Variant in (entry.get("count_flags", []) as Array):
				assert_false(PROGRESSION_STATE.scope_of(str(counted)).is_empty(),
					"'%s' count_flag '%s' is unscoped" % [str(entry.get("id", "")), str(counted)])


# --- the table's own shape ---------------------------------------------------

func test_an_id_the_table_does_not_name_resolves_to_nothing() -> void:
	# The negative case, and the reason every assertion above is worth making:
	# `scope_of` genuinely answers "" rather than guessing.
	assert_eq(PROGRESSION_STATE.scope_of("a_flag_nobody_ever_declared"), "")
	assert_eq(PROGRESSION_STATE.scope_of(""), "")
	assert_eq(PROGRESSION_STATE.scope_of("openin"), "",
		"a partial prefix must not match -- prefixes end with ':' or '_' for exactly this reason")


func test_no_id_is_declared_in_both_scopes() -> void:
	# The merged view's `has()` is "either store has it", which is only EXACT
	# because an id belongs to one scope. A duplicate would make that a guess.
	var table := _json(SCOPES_PATH)
	var world_ids: Array = (table.get("world", {}) as Dictionary).get("ids", [])
	var player_ids: Array = (table.get("player", {}) as Dictionary).get("ids", [])
	for id: Variant in world_ids:
		assert_false(player_ids.has(id), "'%s' is declared in both scopes" % str(id))


func test_every_prefix_ends_with_a_separator() -> void:
	# So a prefix can never swallow an unrelated id: `home_` would otherwise
	# also claim `homestead_built`.
	var table := _json(SCOPES_PATH)
	for scope: String in ["world", "player"]:
		for raw: Variant in ((table.get(scope, {}) as Dictionary).get("prefixes", []) as Array):
			var prefix := str(raw)
			assert_true(prefix.ends_with(":") or prefix.ends_with("_"),
				"prefix '%s' ends with neither ':' nor '_'" % prefix)


func test_the_longest_matching_prefix_wins() -> void:
	# `opening:` and `opening:beat:` are both declared, both player today. The
	# resolution ORDER still has to be longest-first, because the day one of
	# them is re-scoped the shorter must not shadow the longer.
	var prefixes: Array = PROGRESSION_STATE.scoped_prefixes()
	assert_true(prefixes.size() >= 2, "sanity: the table declares prefixes")
	for i in range(1, prefixes.size()):
		assert_true(str((prefixes[i - 1] as Array)[0]).length()
				>= str((prefixes[i] as Array)[0]).length(),
			"prefixes must be offered longest-first")


func test_an_exact_id_beats_a_prefix_that_also_matches_it() -> void:
	# `creature_bed_built` is declared outright AND `creature_bed_built_` is a
	# prefix. Both say player today, so this pins the RULE rather than a value.
	assert_true(PROGRESSION_STATE.scoped_ids().has("creature_bed_built"))
	assert_eq(PROGRESSION_STATE.scope_of("creature_bed_built"), "player")
	assert_eq(PROGRESSION_STATE.scope_of("creature_bed_built_2"), "player")
