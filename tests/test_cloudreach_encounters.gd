extends "res://tests/test_case.gd"

const DIRECTOR := preload("res://scripts/combat/cloudreach_encounter_director.gd")
const TRAINER := preload("res://scripts/world/trainer_npc.gd")
const MODEL := preload("res://scripts/characters/character_model.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const SURFACE := preload("res://scripts/combat/cloudreach_combat_surface.gd")
const VEYRA := "captain_veyra_storm_anchor"
const VEYRA_FLAG := "captain_veyra_defeated"
const VEYRA_COINS_SOURCE := "trainer:captain_veyra_storm_anchor:coins"
const VEYRA_CANDY_SOURCE := "trainer:captain_veyra_storm_anchor:item:rare_candy"
## F07#4: the captain tier's flat `xp_bonus` is a third, item-less component.
const VEYRA_XP_SOURCE := "trainer:captain_veyra_storm_anchor:xp"
## A joiner's peer id: never 1 (only the listen server is 1).
const GUEST_PEER := 424242
const NATIVE_WILD_SITE_IDS: Array[String] = [
	"lower_cliff_foragers", "causeway_watch", "ravine_wind",
	"roost_perches", "upper_scouts", "summit_watch",
]


## `Game.progression` stand-in: the same `has`/`set_flag` surface the director
## reads, with no autoload (`--script` boots none).
class FlagStore extends RefCounted:
	var flags: Dictionary = {}

	func has(id: String) -> bool:
		return flags.has(id)

	func set_flag(id: String, value: bool = true) -> void:
		if value:
			flags[id] = true
		else:
			flags.erase(id)


## The real Cloudreach `_record_trainer_defeat()` and the real base §7 session
## path, with only the session, ledger and satchel edges stubbed.
class PayoutDirector:
	extends "res://scripts/combat/cloudreach_encounter_director.gd"
	var multi := false
	var host := false
	## Whether the chapter/finale adapter's write is already visible locally
	## when `trainer_victory` returns (solo/host commit; a client's is pending).
	var adapter_commits := true
	var store := FlagStore.new()
	var intents: Array[Dictionary] = []
	var victories: Array = []
	var told: Array = []
	var told_xp: Array = []
	var solo_pays := 0
	## source -> {peer: true}; `world_ledger.gd::_reward_grant()`'s per-recipient
	## per-source receipt, so a repeat grant is `already_taken` with no `paid`.
	var receipts: Dictionary = {}
	var paid_log: Array = []
	## Encounter intents a CLIENT sends to the host (the host-journaled
	## `trainer_victory` route); host and solo paths never send.
	var sent: Array = []

	func _is_multi_peer() -> bool:
		return multi

	func _can_encounter_rpc() -> bool:
		return multi and not host

	func _send_realm_rpc(peer: int, method: String, arguments: Array, _completing: bool = false) -> bool:
		sent.append({"peer": peer, "method": method, "arguments": arguments.duplicate(true)})
		return true

	func _is_host() -> bool:
		return multi and host

	func _encounter_realm() -> String:
		return "cloudreach"

	func _progression() -> RefCounted:
		return store

	func _pay_trainer_reward(_spec: Dictionary) -> void:
		solo_pays += 1

	func _trainer_reward_line(_spec: Dictionary) -> String:
		return ""

	func _tell_participant_they_were_paid(peer_id: int, payload: Dictionary) -> void:
		told.append(peer_id)
		told_xp.append(int(payload.get("xp", 0)))

	func _submit_reward_intent(intent: Dictionary) -> Dictionary:
		intents.append(intent.duplicate(true))
		if str(intent.get("kind", "")) == "set_world_flag":
			if _is_host():
				store.set_flag(str(intent.get("id", "")))
				return {"ok": true, "pending": false, "code": "noop", "paid": []}
			return {"ok": false, "pending": true, "code": "", "paid": []}
		var source := str(intent.get("source", ""))
		var seen: Dictionary = receipts.get(source, {})
		var paid: Array = []
		for raw: Variant in (intent.get("peers", []) as Array):
			var peer := int(raw)
			if not seen.has(peer):
				seen[peer] = true
				paid.append(peer)
				paid_log.append("%s|%d" % [source, peer])
		receipts[source] = seen
		if paid.is_empty():
			return {"ok": false, "pending": false, "code": "already_taken", "paid": []}
		return {"ok": true, "pending": false, "code": "", "paid": paid}

	func adapter(id: String) -> void:
		victories.append(id)
		if adapter_commits:
			store.set_flag(str((trainer_specs[id] as Dictionary)["defeat_flag"]))


func _veyra_director(multi: bool, host: bool, adapter_commits: bool) -> PayoutDirector:
	var director := PayoutDirector.new()
	director.setup(null)
	director.multi = multi
	director.host = host
	director.adapter_commits = adapter_commits
	director.trainer_victory.connect(director.adapter)
	return director


func _intents_of(director: PayoutDirector, kind: String) -> Array:
	var out: Array = []
	for intent: Dictionary in director.intents:
		if str(intent.get("kind", "")) == kind:
			out.append(intent)
	return out


func test_host_run_veyra_pays_each_participant_once_through_the_session_path() -> void:
	var director := _veyra_director(true, true, true)
	var spec: Dictionary = director.trainer_specs[VEYRA]
	assert_eq(str(spec["defeat_flag"]), VEYRA_FLAG)
	director._encounter_host = RefCounted.new()
	director._trainer_battle_participants = {1: true, GUEST_PEER: true}
	director._record_trainer_defeat(spec)
	assert_eq(director.victories, [VEYRA], "the finale hook still fires exactly once")
	assert_eq(director.solo_pays, 0, "the host does not also pay itself a local satchel reward")
	var facts := _intents_of(director, "set_world_flag")
	assert_eq(facts.size(), 1, "the world fact is submitted once")
	assert_eq(str((facts[0] as Dictionary).get("id", "")), VEYRA_FLAG)
	var grants := _intents_of(director, "reward_grant")
	assert_eq(grants.size(), 3, "one reward_grant per component: coins, rare_candy and the xp receipt")
	var xp_bonus := int((spec["reward"] as Dictionary).get("xp_bonus", 0))
	assert_true(xp_bonus > 0, "the captain tier carries the F07#4 xp_bonus")
	var sources: Array = []
	for grant: Dictionary in grants:
		sources.append(str(grant["source"]))
		assert_eq(grant["peers"], [1, GUEST_PEER], "every participant is named on %s" % grant["source"])
		assert_eq(str(grant["realm"]), "cloudreach")
		if str(grant["source"]) == VEYRA_COINS_SOURCE:
			assert_eq(str(grant["item"]), "coin")
			assert_eq(int(grant["count"]), 150, "Veyra's authored coins, not divided")
		elif str(grant["source"]) == VEYRA_XP_SOURCE:
			assert_false(grant.has("item"), "the xp receipt carries no item; each peer applies its own bonus")
		else:
			assert_eq(str(grant["item"]), "rare_candy")
			assert_eq(int(grant["count"]), 1)
	sources.sort()
	assert_eq(sources, [VEYRA_COINS_SOURCE, VEYRA_CANDY_SOURCE, VEYRA_XP_SOURCE])
	assert_eq(director.paid_log.size(), 6, "three components x two participants, each once")
	var told := director.told.duplicate()
	told.sort()
	assert_eq(told, [1, GUEST_PEER], "each participant is told once, the guest included")
	assert_eq(director.told_xp, [xp_bonus, xp_bonus], "each participant is owed the whole bonus, not a split")
	director.free()


func test_repeat_veyra_defeat_pays_nobody_again() -> void:
	var director := _veyra_director(true, true, true)
	var spec: Dictionary = director.trainer_specs[VEYRA]
	director._encounter_host = RefCounted.new()
	director._trainer_battle_participants = {1: true, GUEST_PEER: true}
	director._record_trainer_defeat(spec)
	var intents_after_first := director.intents.size()
	director._record_trainer_defeat(spec)
	assert_eq(director.intents.size(), intents_after_first, "the world guard stops a repeat before any intent")
	assert_eq(director.victories.size(), 1, "the finale hook is once-only")
	assert_eq(director.told.size(), 2)
	assert_eq(director.solo_pays, 0)
	# Even with the world flag somehow cleared, the per-participant receipts
	# refuse a second grant: nobody is paid or told twice.
	director.store.set_flag(VEYRA_FLAG, false)
	director._record_trainer_defeat(spec)
	assert_eq(director.paid_log.size(), 6, "receipts refuse every second grant")
	assert_eq(director.told.size(), 2, "nobody is told they were paid twice")
	assert_eq(director.solo_pays, 0)
	director.free()


func test_solo_veyra_defeat_is_unchanged_single_local_payout() -> void:
	for adapter_commits: bool in [true, false]:
		var director := _veyra_director(false, false, adapter_commits)
		var spec: Dictionary = director.trainer_specs[VEYRA]
		director._record_trainer_defeat(spec)
		assert_eq(director.solo_pays, 1, "solo pays once (adapter_commits=%s)" % adapter_commits)
		assert_true(director.store.has(VEYRA_FLAG))
		assert_true(director.intents.is_empty(), "solo submits no intents at all")
		director._record_trainer_defeat(spec)
		assert_eq(director.solo_pays, 1, "a solo repeat pays nothing")
		assert_eq(director.victories.size(), 1)
		director.free()


func test_client_run_veyra_fight_is_sent_to_the_host_and_pays_nothing_locally() -> void:
	# A client's own trainer battle has no encounter record of its own to pay
	# from. Under the host-journaled rule (every participant is paid and
	# journaled by the host, whoever started the fight) the client sends one
	# `trainer_victory` intent naming only the trainer; the host resolves the
	# sender's character, pays it and writes the world fact. The client pays
	# itself nothing and writes neither a reward nor the world fact.
	for adapter_commits: bool in [true, false]:
		var director := _veyra_director(true, false, adapter_commits)
		var spec: Dictionary = director.trainer_specs[VEYRA]
		director._record_trainer_defeat(spec)
		assert_eq(director.solo_pays, 0, "the client pays itself nothing (adapter_commits=%s)" % adapter_commits)
		assert_true(_intents_of(director, "reward_grant").is_empty(), "a client never submits reward_grant")
		assert_true(_intents_of(director, "set_world_flag").is_empty(),
			"the client does not write the world fact; the host does")
		assert_eq(director.sent.size(), 1, "exactly one request goes to the host")
		if director.sent.size() == 1:
			var request: Dictionary = director.sent[0]
			assert_eq(int(request["peer"]), 1, "addressed to the host")
			assert_eq(str(request["method"]), "_rpc_encounter_intent")
			assert_eq((request["arguments"] as Array)[0].get("kind"), "trainer_victory")
			assert_eq((request["arguments"] as Array)[0].get("trainer_id"), VEYRA,
				"naming only the trainer, never a character or recipient")
			assert_false((request["arguments"] as Array)[0].has("character_id"))
			assert_false((request["arguments"] as Array)[0].has("peers"))
		assert_true(director.told.is_empty())
		director._record_trainer_defeat(spec)
		assert_eq(director.solo_pays, 0, "a client repeat pays nothing")
		assert_eq(director.sent.size(), 1, "a client repeat sends nothing new to the host")
		assert_eq(director.victories.size(), 1)
		director.free()


func test_seven_trainers_use_real_species_models_curve_and_rewards() -> void:
	var chapter := DIRECTOR.read_json(DIRECTOR.CHAPTER_PATH)
	var data := DIRECTOR.read_json(DIRECTOR.CONFIG_PATH)
	var items: Dictionary = DIRECTOR.read_json("res://data/items/items.json")["items"]
	assert_eq(data["trainers"].size(), 7)
	var ids: Array = []
	var maela_skyplume := false
	for placement: Dictionary in data["trainers"]:
		var authored := DIRECTOR.find_id(chapter["trainer_ladder"], str(placement["id"]))
		var spec := DIRECTOR.trainer_spec(authored, placement, data)
		assert_false(ids.has(spec["id"]))
		ids.append(spec["id"])
		assert_eq(spec["defeat_flag"], authored["defeat_flag"])
		assert_false(spec["rechallenge"])
		assert_false(MODEL.config_for(str(spec["config_key"])).is_empty())
		assert_true(spec["position"].size() == 3)
		assert_false(spec["requires_flags"].is_empty())
		assert_between(TRAINER.team_of(spec).size(), 2, 3)
		for entry: Dictionary in TRAINER.team_of(spec):
			var member := TRAINER.creature_for(entry)
			assert_true(member != null)
			assert_eq(member.get("level"), entry["level"])
			assert_false(member.get("combat_override").is_empty())
			assert_false(entry.has("hp_multiplier"))
		for item: Dictionary in TRAINER.reward_items(spec):
			assert_true(items.has(str(item["id"])))
			if str(spec["id"]) == "keeper_maela_trial" and str(item["id"]) == "skyplume" and int(item.get("count", 0)) == 2:
				maela_skyplume = true
		var flags := FLAGS.new()
		flags.set_flag(str(spec["defeat_flag"]))
		var loaded := FLAGS.new()
		loaded.load_data(flags.save_data())
		assert_true(TRAINER.already_beaten(spec, loaded))
	assert_true(maela_skyplume, "Maela's creature trial is the guaranteed playable Skyplume source")


func test_wild_tables_are_replaceable_deterministic_and_within_real_level_ranges() -> void:
	var chapter := DIRECTOR.read_json(DIRECTOR.CHAPTER_PATH)
	var data := DIRECTOR.read_json(DIRECTOR.CONFIG_PATH)
	var native_ids: Array[String] = []
	var authored_ids: Dictionary = {}
	for site: Dictionary in data["wild_sites"]:
		var id := str(site.get("id", ""))
		assert_false(id.is_empty(), "every Cloudreach wild site has a deterministic ID")
		assert_false(authored_ids.has(id), "Cloudreach wild site IDs remain unique: %s" % id)
		authored_ids[id] = true
		if NATIVE_WILD_SITE_IDS.has(id):
			native_ids.append(id)
		else:
			assert_true(not str(site.get("_why_road_visibility_0907", "")).is_empty()
					or not str(site.get("_why_air_patrol_visibility_0907", "")).is_empty(),
				"%s is an explicit ROAD/air-patrol addition, not silent ecology inflation" % id)
			assert_true(int(site.get("count", 0)) >= 2,
				"%s contributes the required visible creature pair" % id)
		var table := DIRECTOR.find_id(chapter["encounter_tables"], str(site["table_id"]))
		assert_false(table.is_empty())
		assert_true(table["catchable"])
		assert_true(table["replaceable"])
		for index in range(10):
			var rolled := DIRECTOR.roll_wild(table, 404, index)
			assert_eq(rolled, DIRECTOR.roll_wild(table, 404, index))
			assert_true(SPECIES.has(str(rolled["species"])))
			assert_between(float(rolled["level"]), float(table["level_range"][0]), float(table["level_range"][1]))
	native_ids.sort()
	var expected_native := NATIVE_WILD_SITE_IDS.duplicate()
	expected_native.sort()
	assert_eq(native_ids, expected_native,
		"the original six-site Cloudreach ecology contract remains present by identity")


func test_road_sightline_creatures_cannot_body_block_the_trainer_corridor() -> void:
	var trainer := CharacterBody3D.new()
	var wild := CharacterBody3D.new()
	DIRECTOR.keep_trainer_corridor_clear(wild, trainer)
	assert_true(wild.get_collision_exceptions().has(trainer),
		"ROAD creature ignores only the trainer body")
	assert_true(trainer.get_collision_exceptions().has(wild),
		"trainer has the reciprocal ROAD creature exception")
	wild.free()
	trainer.free()
