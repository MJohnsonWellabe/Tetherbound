extends "res://tests/test_case.gd"

# ROADMAP Phase 1 item 6: "Qualify six Meadows activities."
#
# Its criteria are "visible lure, distinct action/decision, useful reward for an
# unchanged five, acknowledgement, saved completion and normal-play
# reachability", with at least one per principal region.
#
# Three of those are JUDGEMENT -- whether a reward is useful to an unchanged
# five, whether an action is distinct, and whether too many endings are generic
# chests. Those belong to the owner and are deliberately NOT asserted here; a
# test that scored them would be inventing an answer.
#
# The rest are checkable, and were not checked anywhere. MEADOWS-PAYOFFS records
# the herd activity as "unqualified toward the six-activity floor" with no
# mechanism to say when that changes. This is that mechanism.

const OBJECTIVES := "res://data/progression/objectives.json"
const FLAG_SCOPES := "res://data/progression/flag_scopes.json"

## The floor ROADMAP item 6 sets.
const REQUIRED_ACTIVITIES := 6


func _read(path: String) -> Variant:
	var text := FileAccess.get_file_as_string(path)
	return JSON.parse_string(text)


func _local_activities() -> Array:
	var data: Variant = _read(OBJECTIVES)
	if data is not Dictionary:
		return []
	var out: Array = []
	for raw: Variant in ((data as Dictionary).get("local", []) as Array):
		if raw is Dictionary:
			out.append(raw)
	return out


func test_the_chapter_carries_at_least_the_six_activity_floor() -> void:
	# A `counts_as_activity: false` row is a story log line (first Ironwood
	# completes on a required Sigil captain) and does not count toward the floor.
	var activities := _local_activities().filter(func(row: Dictionary) -> bool:
		return bool(row.get("counts_as_activity", true)))
	assert_true(activities.size() >= REQUIRED_ACTIVITIES,
		"ROADMAP item 6 sets a floor of %d optional activities; objectives.json carries %d that count"
			% [REQUIRED_ACTIVITIES, activities.size()])


func test_every_activity_is_discovered_rather_than_listed_from_the_start() -> void:
	# The "visible lure" half that a file can actually check: the log must not
	# hand the player a list of what the designer put in the world. Each row
	# names the thing that reveals it.
	for row: Dictionary in _local_activities():
		assert_false(str(row.get("revealed_by", "")).is_empty(),
			"activity '%s' has no `revealed_by`, so it appears in the log before the player has found it"
				% str(row.get("id", "")))


func test_every_activity_tells_the_player_what_it_is() -> void:
	for row: Dictionary in _local_activities():
		var label := str(row.get("label", ""))
		assert_false(label.is_empty(),
			"activity '%s' has no label; the quest log would show a blank line" % str(row.get("id", "")))
		assert_true(label.length() > 8,
			"activity '%s' label '%s' says too little to act on" % [str(row.get("id", "")), label])


func test_every_activity_completes_into_a_declared_durable_flag() -> void:
	# "Saved completion": the flag that ticks the activity has to exist AND have
	# a declared scope, or it is neither durable nor reliably shared.
	var scopes: Variant = _read(FLAG_SCOPES)
	assert_true(scopes is Dictionary, "flag_scopes.json must parse")
	for row: Dictionary in _local_activities():
		var flag := str(row.get("flag_id", ""))
		var id := str(row.get("id", ""))
		assert_false(flag.is_empty(), "activity '%s' names no completion flag" % id)
		assert_false(str(row.get("scope", "")).is_empty(),
			"activity '%s' declares no scope for '%s'; world and character facts persist differently"
				% [id, flag])


func test_no_activity_shares_its_completion_flag_with_another() -> void:
	# One fact, one flag. Two activities on one flag means finishing either
	# ticks both, and the second can never be finished again.
	var seen := {}
	for row: Dictionary in _local_activities():
		var flag := str(row.get("flag_id", ""))
		assert_false(seen.has(flag),
			"activities '%s' and '%s' share completion flag '%s'"
				% [str(seen.get(flag, "")), str(row.get("id", "")), flag])
		seen[flag] = str(row.get("id", ""))


func test_the_activities_are_spread_across_the_chapter_not_stacked_in_one_band() -> void:
	# ROADMAP: "At least one activity per principal region." Checked as the
	# weaker, objective form -- they must not all sit in one band -- because
	# which bands count as principal is a design call.
	var bands := {}
	for row: Dictionary in _local_activities():
		var id := str(row.get("id", ""))
		var band := id.split("_")[0] if id.contains("_") else id
		bands[band] = true
	assert_true(bands.size() >= 3,
		"every optional activity would sit in %d band(s) (%s); the chapter needs them spread"
			% [bands.size(), str(bands.keys())])


# --- F03-a: the qualification record, asserted column by column --------------
#
# ACCEPTANCE F03: for at least six of WORLD §11's eight selected Meadows
# activities a player can see the lure, perform a distinct optional action,
# receive a useful once-only reward and acknowledgement, and reload saved
# completion; one qualified activity per principal region; no story gate
# requires a detour; exact source IDs and rejected candidates recorded.
#
# `QUALIFIED` below mirrors the table in ralph/reports/MEADOWS-PAYOFFS/REPORT.md
# ("F03 activity qualification record"). Every FILE-CHECKABLE column of each row
# is asserted from the shipping data it names: the lure exists in world config,
# the reward is non-empty and routed through a once-only receipt, the
# acknowledgement line exists, and the completion flag has a declared scope.
# The runtime half (ordinary approach, the action performed, reload) is proven
# by the witnesses the report lists -- this file does not pretend to be those.
# Usefulness to an unchanged five and "distinct" remain judgement, as above.

const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const DIALOGUE := preload("res://scripts/story/dialogue_runner.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const ENCOUNTER_REWARDS := preload("res://scripts/net/encounter_rewards.gd")
const HERD_VISIT := preload("res://scripts/world/meadowhart_herd_visit.gd")
const RIVER_NEST := preload("res://scripts/world/river_nest_clear.gd")
const BURROW_WARRENS := preload("res://scripts/world/burrow_warrens.gd")
const ALPHA_PINS := preload("res://scripts/world/alpha_pins.gd")
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")

const WARRENS_CONFIG := "res://data/config/burrow_warrens.json"
const REUNION_CONFIG := "res://data/config/lost_companion_reunion.json"
const MAP_LANDMARKS := "res://data/config/map_landmarks.json"
const SPAWNS_CONFIG := "res://data/config/spawns.json"
## Read as text for Doss's placement constant, the way test_chapter_rewards.gd
## reads TM_AT: preloading the world script would pull the whole world in.
const WORLD_SCRIPT_PATH := "res://scripts/world/playground_world.gd"

## WORLD §11 Meadows' principal regions.
const PRINCIPAL_REGIONS := [
	"lower_meadows", "stone_and_root", "river_lock", "upper_meadows", "hall_approach",
]

## WORLD §11's eight selected Meadows activities, by the id this record uses.
const WORLD_EIGHT := [
	"band1_old_champion", "band1_meadowhart_herd", "band1_broken_cart",
	"band2_night_watch", "band2_warrens_vault_elder", "band3_river_nest",
	"band4_lost_creature", "band5_hall_alpha_galecrest",
]

## The six candidates counted toward F03. `kind` selects which shipping source
## owns each column. `local_row` says objectives.json must carry the row. A
## `conditional` entry passes every file-checkable column but has an open
## runtime question (its reason); it is not counted as qualified outright.
const QUALIFIED := [
	{"id": "band1_old_champion", "region": "lower_meadows", "kind": "trainer",
		"trainer": "old_champion_bram", "flag": "defeated_old_bram",
		"reveal": "old_champion_met", "reveal_conversation": "old_champion_challenge",
		"ack": "old_champion_beaten", "local_row": true},
	{"id": "band1_meadowhart_herd", "region": "lower_meadows", "kind": "herd",
		"flag": "band1_meadowhart_herd_found",
		"reveal": "band1_meadowhart_herd_met", "reveal_conversation": "meadowhart_herd_sighting",
		"ack": "meadowhart_herd_found", "local_row": true},
	{"id": "band2_warrens_vault_elder", "region": "stone_and_root", "kind": "warrens_elder",
		"nickname": "Elder Trailpup", "flag": "warrens_once_elder_trailpup",
		"reveal": "warrens_cleared", "local_row": true},
	{"id": "band3_river_nest", "region": "river_lock", "kind": "doss",
		"flag": "river_nest_doss_cleared", "reveal": "river_nest_doss_met",
		"reveal_conversation": "river_nest_doss_challenge",
		"ack": "river_nest_doss_defeated", "local_row": true,
		"conditional": "passes alone on current main (smoke_local_requests --only=doss), but its repeat step fails when run after herd/bram/juno in one session: order-dependent, open"},
	{"id": "band4_lost_creature", "region": "upper_meadows", "kind": "trainer",
		"trainer": "lost_creature_rue", "flag": "defeated_lost_creature_rue",
		"reveal": "lost_creature_rue_met", "reveal_conversation": "pasture_drover_juno_challenge",
		"ack": "lost_creature_rue_defeated", "local_row": true},
	{"id": "band5_hall_alpha_galecrest", "region": "hall_approach", "kind": "alpha",
		"order": 5001, "flag": "wild_once_5001", "reveal": "hall_approach_open", "local_row": true,
		"conditional": "optionality unproven: 18m from the spine in the chapter's largest aggressive cluster"},
]

## Recorded rejections (reasons in the report). Two are WORLD §11 candidates;
## two are the optional extras §11 says may raise the count only if they fully
## qualify.
const REJECTED := {
	"band1_broken_cart": "WORLD specifies no currency/item payout; cart_repair.gd pays 25 coins -- open owner question",
	"band2_night_watch": "no reward/acknowledgement/reload witness; the 'at night' lure is not implemented on the trainer",
	"band4_first_ironwood": "completes on a required Sigil captain's defeat flag",
	"band1_pond_alpha_1900": "no once-only completion reward beyond the catch/fight itself; no acknowledgement",
}

const MIN_QUALIFIED := 6


func _json_dict(path: String) -> Dictionary:
	var parsed: Variant = _read(path)
	return parsed as Dictionary if parsed is Dictionary else {}


func _local_row(id: String) -> Dictionary:
	for row: Dictionary in _local_activities():
		if str(row.get("id", "")) == id:
			return row
	return {}


func _conversation_lines(id: String) -> Array:
	var conversation: Variant = DIALOGUE.table().get(id, {})
	if conversation is not Dictionary:
		return []
	var lines: Variant = (conversation as Dictionary).get("lines", [])
	return lines as Array if lines is Array else []


func _conversation_text(id: String) -> String:
	var parts: PackedStringArray = []
	for line: Variant in _conversation_lines(id):
		parts.append(str((line as Dictionary).get("text", "")) if line is Dictionary else str(line))
	return " ".join(parts)


func _conversation_sets_flag(id: String, flag: String) -> bool:
	for line: Variant in _conversation_lines(id):
		if line is Dictionary and str((line as Dictionary).get("effect", "")) == "flag:" + flag:
			return true
	return false


func _warrens_spawn(nickname: String) -> Dictionary:
	for raw: Variant in (_json_dict(WARRENS_CONFIG).get("spawns", []) as Array):
		if raw is Dictionary and str((raw as Dictionary).get("nickname", "")) == nickname:
			return raw as Dictionary
	return {}


func _band_spawn(order: int) -> Dictionary:
	var merged := BAND_CONTENT.load_config(SPAWNS_CONFIG, "spawns")
	for raw: Variant in (merged.get("spawns", []) as Array):
		if raw is Dictionary and int((raw as Dictionary).get("order", -1)) == order:
			return raw as Dictionary
	return {}


## The once-only receipt spec encounter_director.gd::_award_once_completion_reward
## builds from a named wild's `completion_reward`, so the grant check below runs
## through the same shipping receipt builder that pays it.
func _once_spec(once_id: String, completion: Dictionary) -> Dictionary:
	return {
		"id": once_id,
		"name": str(completion.get("title", "")),
		"reward": {
			"coins": int(completion.get("coins", 0)),
			"items": (completion.get("items", []) as Array).duplicate(true),
			"xp_bonus": int(completion.get("xp_bonus", 0)),
		},
	}


func _vault_once_flag(nickname: String) -> String:
	# Ask the shipping script for its own spelling of the once flag rather than
	# re-deriving it here; an unmounted instance runs no _ready().
	var warrens: Node = BURROW_WARRENS.new()
	var flag := str(warrens.call("_once_flag_for_nickname", nickname))
	warrens.free()
	return flag


## Asserts that `grants` is a non-empty set of per-participant receipts, all
## keyed by the stable `trainer:<id>:` source the ledger journals once.
func _assert_once_receipts(activity: String, receipt_id: String, grants: Array) -> void:
	assert_false(grants.is_empty(), "%s pays nothing through its receipt builder" % activity)
	for raw: Variant in grants:
		var source := str((raw as Dictionary).get("source", ""))
		assert_true(source.begins_with("trainer:%s:" % receipt_id),
			"%s grant '%s' is not keyed by its once-only receipt id '%s'" % [activity, source, receipt_id])


func _assert_items_exist(activity: String, items: Array, db: RefCounted) -> int:
	var real := 0
	for raw: Variant in items:
		var entry := raw as Dictionary if raw is Dictionary else {}
		var id := str(entry.get("id", ""))
		assert_true(bool(db.call("has", id)), "%s rewards unknown item '%s'" % [activity, id])
		assert_true(int(entry.get("count", 0)) > 0, "%s rewards a non-positive count of '%s'" % [activity, id])
		real += 1
	return real


## Record consistency only: this checks the record's own tables (counted,
## rejected, WORLD's eight) agree with each other. It reads no shipping data, so
## it cannot show the six-activity floor is met; the data tests below and the
## runtime witnesses in MEADOWS-PAYOFFS carry that.
func test_the_f03_record_is_internally_consistent() -> void:
	# Qualified outright and conditional are kept apart: this record does not
	# claim the six-floor is met while any candidate is conditional.
	var outright := QUALIFIED.filter(func(row: Dictionary) -> bool: return not row.has("conditional"))
	var conditional := QUALIFIED.filter(func(row: Dictionary) -> bool: return row.has("conditional"))
	for row: Dictionary in conditional:
		assert_false(str(row["conditional"]).strip_edges().is_empty(),
			"conditional activity '%s' records no reason" % row["id"])
	assert_eq(outright.size(), 4, "the record counts Bram, herd, vault Elder and Juno as qualified outright")
	assert_true(outright.size() + conditional.size() >= MIN_QUALIFIED,
		"F03 needs at least %d candidates; the record has %d outright and %d conditional"
			% [MIN_QUALIFIED, outright.size(), conditional.size()])
	var regions := {}
	var ids := {}
	for row: Dictionary in QUALIFIED:
		var id := str(row["id"])
		assert_false(ids.has(id), "activity '%s' is counted twice" % id)
		ids[id] = true
		assert_false(REJECTED.has(id), "activity '%s' is both qualified and rejected" % id)
		assert_true(PRINCIPAL_REGIONS.has(str(row["region"])),
			"activity '%s' names unknown region '%s'" % [id, row["region"]])
		regions[str(row["region"])] = true
	for region: String in PRINCIPAL_REGIONS:
		assert_true(regions.has(region), "no qualified activity in principal region '%s'" % region)
	# Every one of WORLD's eight has a disposition: counted or rejected.
	assert_eq(WORLD_EIGHT.size(), 8, "WORLD §11 selects eight Meadows activities")
	for id: String in WORLD_EIGHT:
		assert_true(ids.has(id) or REJECTED.has(id), "WORLD §11 candidate '%s' has no disposition" % id)


func test_every_qualified_activity_saves_a_declared_once_only_completion() -> void:
	var checked := 0
	for row: Dictionary in QUALIFIED:
		var id := str(row["id"])
		var flag := str(row["flag"])
		var scope := PROGRESSION_STATE.scope_of(flag)
		assert_true(scope == "world" or scope == "player",
			"%s completes on '%s', which flag_scopes.json does not declare, so it is not saved" % [id, flag])
		var reveal := str(row.get("reveal", ""))
		if not reveal.is_empty():
			assert_ne(PROGRESSION_STATE.scope_of(reveal), "",
				"%s's discovery flag '%s' has no declared scope" % [id, reveal])
		var local := _local_row(id)
		if bool(row["local_row"]):
			assert_false(local.is_empty(), "%s has no `local` row in objectives.json" % id)
		if not local.is_empty():
			# A landed row must tick on the same fact this record counts.
			assert_eq(str(local.get("flag_id", "")), flag, "%s's objective row completes on another flag" % id)
			assert_eq(str(local.get("scope", "")), scope, "%s's objective row declares the wrong scope" % id)
			if not reveal.is_empty():
				assert_eq(str(local.get("revealed_by", "")), reveal,
					"%s's objective row is revealed by a different fact" % id)
		checked += 1
	assert_eq(checked, QUALIFIED.size(), "a qualified activity skipped the saved-completion check")


func test_every_qualified_activity_pays_a_real_once_only_reward() -> void:
	var db: RefCounted = ITEM_DB.new()
	var rewarded := 0
	for row: Dictionary in QUALIFIED:
		var id := str(row["id"])
		var flag := str(row["flag"])
		match str(row["kind"]):
			"trainer":
				var spec := TRAINERS.trainer(str(row["trainer"]))
				assert_false(spec.is_empty(), "%s: trainer '%s' is not placed" % [id, row["trainer"]])
				if spec.is_empty():
					continue
				assert_eq(str(spec.get("defeat_flag", "")), flag, "%s: the fight does not set the counted flag" % id)
				assert_false(bool(spec.get("rechallenge", false)), "%s: a rechallengeable trainer is not once-only" % id)
				assert_true(TRAINERS.reward_coins(spec) > 0 or not TRAINERS.reward_items(spec).is_empty(),
					"%s: the trainer pays nothing" % id)
				_assert_items_exist(id, TRAINERS.reward_items(spec), db)
				_assert_once_receipts(id, str(spec["id"]), ENCOUNTER_REWARDS.grants(spec, "meadows", [1]))
			"herd":
				var visit: Dictionary = HERD_VISIT.definition().get("visit", {}) as Dictionary
				var item := str(visit.get("reward_item", ""))
				assert_true(bool(db.call("has", item)), "%s rewards unknown item '%s'" % [id, item])
				assert_true(int(visit.get("reward_count", 0)) > 0, "%s pays a zero count" % id)
				assert_false(str(visit.get("reward_source", "")).is_empty(),
					"%s has no stable reward source, so its payout is not once-only" % id)
				assert_eq(HERD_VISIT.COMPLETE_FLAG, flag, "%s: the visit completes on another flag" % id)
			"warrens_elder":
				var spawn := _warrens_spawn(str(row["nickname"]))
				assert_false(spawn.is_empty(), "%s: no '%s' in burrow_warrens.json" % [id, row["nickname"]])
				var completion: Dictionary = spawn.get("completion_reward", {}) as Dictionary
				assert_true(_assert_items_exist(id, completion.get("items", []) as Array, db) > 0,
					"%s: the Elder carries no completion reward" % id)
				assert_eq(_vault_once_flag(str(row["nickname"])), flag,
					"%s: burrow_warrens.gd fires a different once flag" % id)
				_assert_once_receipts(id, flag, ENCOUNTER_REWARDS.grants(_once_spec(flag, completion), "meadows", [1]))
			"doss":
				assert_true(RIVER_NEST.REWARD_COINS > 0, "%s pays no coins" % id)
				assert_true(bool(db.call("has", RIVER_NEST.REWARD_ITEM_ID)),
					"%s rewards unknown item '%s'" % [id, RIVER_NEST.REWARD_ITEM_ID])
				assert_true(RIVER_NEST.REWARD_ITEM_COUNT > 0, "%s pays a zero item count" % id)
				assert_eq(RIVER_NEST.FLAG_ID, flag, "%s: the repair completes on another flag" % id)
			"alpha":
				var order := int(row["order"])
				var spawn := _band_spawn(order)
				var alpha: Dictionary = spawn.get("alpha", {}) as Dictionary
				var completion: Dictionary = alpha.get("completion_reward", {}) as Dictionary
				assert_true(_assert_items_exist(id, completion.get("items", []) as Array, db) > 0,
					"%s: spawn order %d's alpha carries no completion reward" % [id, order])
				assert_eq(ALPHA_PINS._once_flag_for(order), flag, "%s: the alpha fires a different once flag" % id)
				_assert_once_receipts(id, flag, ENCOUNTER_REWARDS.grants(_once_spec(flag, completion), "meadows", [1]))
			_:
				_fail("%s has unknown kind '%s'" % [id, row["kind"]])
				continue
		rewarded += 1
	assert_eq(rewarded, QUALIFIED.size(), "a qualified activity skipped the reward check")


func test_every_qualified_activity_acknowledges_the_player() -> void:
	var acknowledged := 0
	for row: Dictionary in QUALIFIED:
		var id := str(row["id"])
		match str(row["kind"]):
			"trainer":
				var spec := TRAINERS.trainer(str(row["trainer"]))
				assert_eq(str(spec.get("defeated", "")), str(row["ack"]),
					"%s: the trainer's post-win conversation is not the recorded acknowledgement" % id)
			"herd":
				var visit: Dictionary = HERD_VISIT.definition().get("visit", {}) as Dictionary
				assert_eq(str(visit.get("acknowledgement", "")), str(row["ack"]),
					"%s: the visit plays a different acknowledgement" % id)
			"doss":
				assert_eq(RIVER_NEST.CLEARED_CONVERSATION, str(row["ack"]),
					"%s: Doss's cleared conversation is not the recorded acknowledgement" % id)
				assert_true(_conversation_text(str(row["ack"])).contains(str(RIVER_NEST.REWARD_COINS)),
					"%s: Doss's thanks no longer names the %d coins actually paid" % [id, RIVER_NEST.REWARD_COINS])
			"warrens_elder":
				var completion: Dictionary = _warrens_spawn(str(row["nickname"])).get("completion_reward", {}) as Dictionary
				assert_false(str(completion.get("acknowledgement", "")).strip_edges().is_empty(),
					"%s: the Elder's receipt has no acknowledgement line" % id)
			"alpha":
				var alpha: Dictionary = _band_spawn(int(row["order"])).get("alpha", {}) as Dictionary
				var completion: Dictionary = alpha.get("completion_reward", {}) as Dictionary
				assert_false(str(completion.get("acknowledgement", "")).strip_edges().is_empty(),
					"%s: the alpha's receipt has no acknowledgement line" % id)
		if row.has("ack"):
			assert_false(_conversation_lines(str(row["ack"])).is_empty(),
				"%s: acknowledgement conversation '%s' does not exist" % [id, row["ack"]])
		acknowledged += 1
	assert_eq(acknowledged, QUALIFIED.size(), "a qualified activity skipped the acknowledgement check")


func test_the_lost_companion_is_acknowledged_by_juno_on_the_counted_fact() -> void:
	# The rescue's acknowledgement is the world consequence, not only the
	# patrol's defeated line: Juno and the reunited display both key off the
	# same flag the record counts, so nothing pays or presents twice.
	var flag := "defeated_lost_creature_rue"
	var juno := TRAINERS.trainer("pasture_drover_juno")
	var after: Dictionary = juno.get("dialogue_after", {}) as Dictionary
	assert_eq(str(after.get("flag", "")), flag, "Juno's reunited dialogue keys off another fact")
	for state: String in ["challenge", "defeated"]:
		assert_false(_conversation_lines(str(after.get(state, ""))).is_empty(),
			"Juno's reunited '%s' conversation is missing" % state)
	var reunion := _json_dict(REUNION_CONFIG)
	assert_eq(str(reunion.get("defeat_flag", "")), flag, "the reunion display keys off another fact")
	assert_eq(str(reunion.get("patrol_trainer_id", "")), "lost_creature_rue")
	assert_eq(str(reunion.get("owner_trainer_id", "")), "pasture_drover_juno")


func test_every_qualified_activity_has_its_lure_in_world_data() -> void:
	var lured := 0
	for row: Dictionary in QUALIFIED:
		var id := str(row["id"])
		if row.has("reveal_conversation"):
			var reveal_id := str(row["reveal_conversation"])
			if str(row["kind"]) == "doss":
				# Doss's met fact is written by the script on greeting.
				assert_false(_conversation_lines(reveal_id).is_empty(), "%s: '%s' is missing" % [id, reveal_id])
				assert_eq(RIVER_NEST.MET_FLAG, str(row["reveal"]), "%s: greeting Doss sets another fact" % id)
				assert_eq(RIVER_NEST.BLOCKED_CONVERSATION, reveal_id, "%s: Doss opens a different request" % id)
			else:
				assert_true(_conversation_sets_flag(reveal_id, str(row["reveal"])),
					"%s: '%s' never reveals '%s'" % [id, reveal_id, row["reveal"]])
		match str(row["kind"]):
			"trainer":
				var spec := TRAINERS.trainer(str(row["trainer"]))
				var at: Variant = spec.get("position", [])
				assert_true(at is Array and (at as Array).size() == 2,
					"%s: trainer '%s' has no world position" % [id, row["trainer"]])
				assert_false(_conversation_lines(str(spec.get("challenge", ""))).is_empty(),
					"%s: the trainer has no challenge conversation to meet" % id)
			"herd":
				var definition := HERD_VISIT.definition()
				var herd := HERD_VISIT.herd_spawn(definition)
				assert_eq(str(herd.get("species", "")), "meadowhart", "%s: the visit's spawn is not the herd" % id)
				assert_true(int(herd.get("count", 0)) >= 1, "%s: the herd spawn is empty" % id)
				var visit: Dictionary = definition.get("visit", {}) as Dictionary
				var found := false
				for raw: Variant in (_json_dict(MAP_LANDMARKS).get("landmarks", []) as Array):
					var landmark := raw as Dictionary if raw is Dictionary else {}
					if str(landmark.get("id", "")) == str(visit.get("landmark_id", "")):
						found = int(landmark.get("spawn_order", -1)) == int(visit.get("spawn_order", -2))
				assert_true(found, "%s: the personal landmark does not resolve to the herd's spawn" % id)
			"warrens_elder":
				var spawn := _warrens_spawn(str(row["nickname"]))
				assert_eq(str(spawn.get("chamber", "")), "vault", "%s: the Elder is not in the side vault" % id)
				assert_false(bool(spawn.get("aggressive", true)),
					"%s: an aggressive Elder is a pull, not a chosen optional action" % id)
				assert_false((((spawn.get("alpha", {}) as Dictionary).get("aura_light", {})) as Dictionary).is_empty(),
					"%s: the Elder has no visible aura to lure the player" % id)
				var config := _json_dict(WARRENS_CONFIG)
				var gated_branch := false
				for raw: Variant in (config.get("passages", []) as Array):
					var passage := raw as Dictionary if raw is Dictionary else {}
					if str(passage.get("from", "")) == "den" and str(passage.get("to", "")) == "vault":
						gated_branch = bool(passage.get("gated", false))
				assert_true(gated_branch, "%s: the vault is not the gated side branch off the den" % id)
				assert_eq(str((config.get("clear", {}) as Dictionary).get("flag", "")), str(row["reveal"]),
					"%s: the branch opens on a different fact" % id)
				var prize: Dictionary = config.get("prize", {}) as Dictionary
				assert_eq(str(prize.get("chamber", "")), "vault", "%s: the Heartstone left the vault" % id)
				assert_ne(PROGRESSION_STATE.scope_of(str(prize.get("flag", ""))), "",
					"%s: the Heartstone pickup's claim flag has no declared scope" % id)
			"doss":
				var source := FileAccess.get_file_as_string(WORLD_SCRIPT_PATH)
				assert_true(source.contains("const RIVER_NEST_AT := Vector2("),
					"%s: Doss has no authored world position" % id)
				assert_true(source.contains("_build_river_nest_clear()"),
					"%s: the world no longer mounts Doss" % id)
			"alpha":
				var order := int(row["order"])
				var pinned := false
				for cluster: Dictionary in ALPHA_PINS.build_clusters():
					if int(cluster.get("order", -1)) == order:
						pinned = str(cluster.get("once_id", "")) == str(row["flag"])
				assert_true(pinned, "%s: spawn order %d is not a map-pinned alpha" % [id, order])
		lured += 1
	assert_eq(lured, QUALIFIED.size(), "a qualified activity skipped the lure check")


func _main_route_flags() -> Dictionary:
	var out := {}
	var data: Variant = _read(OBJECTIVES)
	for raw: Variant in ((data as Dictionary).get("main", []) as Array):
		var entry := raw as Dictionary if raw is Dictionary else {}
		for key: String in ["flag_id", "retired_by", "revealed_by"]:
			var value := str(entry.get(key, ""))
			if not value.is_empty():
				out[value] = str(entry.get("id", ""))
		for counted: Variant in (entry.get("count_flags", []) as Array):
			out[str(counted)] = str(entry.get("id", ""))
		var beacon: Dictionary = entry.get("beacon", {}) as Dictionary
		for step: Variant in (beacon.get("steps", []) as Array):
			if step is Dictionary and not str((step as Dictionary).get("until_flag", "")).is_empty():
				out[str((step as Dictionary)["until_flag"])] = str(entry.get("id", ""))
	return out


func test_no_qualified_activity_gates_or_is_credited_by_the_main_route() -> void:
	# "No story gate requires a detour", and WORLD's rule that an optional
	# activity is never counted as a main-route victory: a qualified completion
	# flag must not appear anywhere the main objectives read.
	var main := _main_route_flags()
	assert_true(main.size() >= 10, "only %d main-route flags were read; this check went quiet" % main.size())
	for row: Dictionary in QUALIFIED:
		var flag := str(row["flag"])
		assert_false(main.has(flag),
			"%s completes on '%s', which main objective '%s' also reads" % [row["id"], flag, main.get(flag, "")])


func test_a_local_row_credited_by_the_main_route_is_recorded_as_rejected() -> void:
	# band4_first_ironwood completes on defeated_captain_field, a required Sigil
	# captain. Any such row must stay out of the counted six and carry a
	# recorded rejection.
	var main := _main_route_flags()
	var qualified_ids := {}
	for row: Dictionary in QUALIFIED:
		qualified_ids[str(row["id"])] = true
	for local: Dictionary in _local_activities():
		var id := str(local.get("id", ""))
		if main.has(str(local.get("flag_id", ""))):
			assert_false(qualified_ids.has(id), "%s is main-route credit but counted as qualified" % id)
			assert_true(REJECTED.has(id), "%s is main-route credit and has no recorded rejection" % id)
			assert_false(bool(local.get("counts_as_activity", true)),
				"%s is main-route credit, so objectives.json must mark it counts_as_activity: false" % id)
	assert_true(REJECTED.size() >= 2, "the record lists no rejected candidates")
	for id: String in REJECTED:
		assert_false(str(REJECTED[id]).strip_edges().is_empty(), "rejection of '%s' records no reason" % id)
