extends "res://tests/test_case.gd"

const RULE := preload("res://scripts/player/ripplet_traversal.gd")
const SUNKEN := preload("res://scripts/world/ripplet_sunken_rules.gd")
const SAVE := preload("res://scripts/save/water_traversal_save.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const WORLD := preload("res://autoload/world_state.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const UID := "creature-0123456789abcdef0123456789abcdef"
const BREAKTHROUGH := preload("res://scripts/creatures/breakthrough.gd")
const EVOLUTION := preload("res://scripts/creatures/evolution.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

func admitted(tiers: Array = []) -> Dictionary:
	return {"character_id":"f37-character", "party":[{"uid":UID,"species_id":"ripplet","level":30,"fainted":false,"resting":false}],
		"inventory":[], "redesign_character":{"creatures":{UID:{"breakthroughs":tiers,"cap_level":BREAKTHROUGH.level_cap(tiers)}}}}

func actor(tiers: Array = [1,2,3]) -> Dictionary:
	return {"peer":2,"character_id":"f37-character","realm":"water","admitted":admitted(tiers),
		"combat":false,"mounted_uid":UID,"in_water":true,"dive_clearance":true,
		"sealed":false,"mount_reachable":true,"diving":true,"position":Vector3(-215,-6.6,166)}

func test_level_thirty_is_not_the_breakthrough_and_other_creatures_never_dive() -> void:
	assert_false(RULE.can_dive(admitted(), UID))
	assert_true(RULE.can_dive(admitted([1,2,3]), UID))
	assert_false(RULE.can_dive(admitted([1,2,3]), "another-creature"))
	var other := admitted([1,2,3])
	other.party[0].species_id = "water_aquaryn"
	assert_false(RULE.can_dive(other, UID))
	other = admitted([1,2,3])
	other.party[0].resting = true
	assert_false(RULE.can_dive(other, UID))
	for tiers: Array in [[1,2], [3], [1,3], [1,2,2], [1,2,3.5], ["1",2,3], [10,20,30], [30], [1,2,3,4,5,6]]:
		assert_false(RULE.can_dive(admitted(tiers), UID), "only the actual canonical completed tier prefix grants Dive")
	other = admitted([1,2,3])
	other.redesign_character.creatures[UID].cap_level = 30
	assert_false(RULE.can_dive(other, UID), "the stored cap must match the completed history")
	other = admitted([1,2,3])
	other.party[0].level = 9
	assert_false(RULE.can_dive(other, UID))
	other = admitted([1,2,3])
	other.party.append(other.party[0].duplicate(true))
	assert_false(RULE.can_dive(other, UID), "duplicate owned UID is ambiguous")

func _species_types(id: String) -> Array:
	return [SPECIES.definition(id).get("type", "")]

func test_actual_f28_caps_survive_json_for_every_valid_completed_prefix() -> void:
	var tiers: Array = []
	assert_eq(BREAKTHROUGH.level_cap(tiers), 10)
	for row: Dictionary in BREAKTHROUGH.masters().masters:
		tiers.append(int(row.tier))
		var restored: Array = JSON.parse_string(JSON.stringify(tiers))
		assert_eq(BREAKTHROUGH.level_cap(restored), int(row.next_cap))
		assert_eq(BREAKTHROUGH.level_cap(restored), BREAKTHROUGH.level_cap(tiers))
	for malformed: Array in [[1.5], [1,3], [1,2,2], ["1"], [1,2,3,4,5,6]]:
		assert_eq(BREAKTHROUGH.level_cap(JSON.parse_string(JSON.stringify(malformed))), -1)

func test_actual_f28_water_feast_planner_produces_dive_history_without_a_level_bonus() -> void:
	# This is the real detached planner, not an earned disk/UI/transport proof.
	var current := admitted([1,2])
	current.inventory = [{"id":"feast_t3_water", "n":1}]
	current.redesign_character.transaction_receipts = []
	current.redesign_character.creatures[UID].evolution_choices = {}
	var result := BREAKTHROUGH.prepare_feed(current, UID, "feast_t3_water", "", {"in_combat":false,"owns_character":true},
		_species_types, Callable(EVOLUTION,"prepare_feast_choice"), Callable(BREAKTHROUGH,"refresh_feast_moves"))
	assert_true(result.ok)
	if not result.get("ok", false): return
	assert_eq(result.state.redesign_character.creatures[UID].breakthroughs, [1,2,3])
	assert_eq(result.state.redesign_character.creatures[UID].cap_level, 40)
	assert_eq(result.state.party[0].level, 30, "a feast grants no automatic level")
	assert_true(RULE.can_dive(result.state, UID))
	var restored: Dictionary = JSON.parse_string(JSON.stringify(result.state))
	assert_eq(BREAKTHROUGH.level_cap(restored.redesign_character.creatures[UID].breakthroughs), 40,
		"canonical integral JSON tiers retain the actual F28 cap")
	assert_true(RULE.can_dive(restored, UID), "the actual tier history survives its save representation")
	assert_eq(current.redesign_character.creatures[UID].breakthroughs, [1,2], "detached planning does not mutate its input")
	assert_false(RULE.can_dive(current, UID))

func test_host_refuses_closed_water_combat_and_missing_owned_carrier() -> void:
	var intent := {"action":"dive","creature_uid":UID}
	assert_true(RULE.action(intent,actor()).ok)
	for key: String in ["combat","sealed"]:
		var context := actor()
		context[key] = true
		assert_false(RULE.action(intent,context).ok)
	for key: String in ["in_water","dive_clearance"]:
		var context := actor()
		context[key] = false
		assert_false(RULE.action(intent,context).ok)
	var context := actor()
	context.mounted_uid = "another-creature"
	assert_false(RULE.action(intent,context).ok)
	assert_false(RULE.action(intent,actor([1,2])).ok)
	context = actor()
	context.character_id = "foreign_character"
	assert_false(RULE.action(intent,context).ok)

func test_claim_race_commits_one_durable_identity_bound_delivery() -> void:
	var world := WORLD.new()
	world.world_id = "f37-world"
	world.reward_delivery_namespace = "f37-namespace"
	var ledger := LEDGER.new()
	ledger.world = world
	var row := SUNKEN.site("lantern_arch_cache")
	var key := SUNKEN.claim_key(row,world.flags,1)
	var request := {"kind":"ripplet_sunken_claim","realm":"water","site_id":row.id,
		"creature_uid":UID,"claim_key":key,"_ripplet_actor":actor(),"_actor_character_id":"f37-character"}
	var first := ledger.commit(request,2)
	assert_true(first.ok)
	assert_true(world.flags.has(key))
	assert_eq(world.reward_deliveries.size(),1)
	var journal: Dictionary = world.reward_deliveries.values()[0]
	assert_eq(journal.character_id,"f37-character")
	assert_eq(journal.stacks,[{"id":"tide_pearl","n":3}])
	assert_false(ledger.commit(request,2).ok)
	assert_eq(world.reward_deliveries.size(),1)
	var restored := WORLD.new()
	restored.load_data(JSON.parse_string(JSON.stringify(world.save_data())))
	ledger.world = restored
	assert_false(ledger.commit(request,2).ok)
	assert_false(ledger.commit({"kind":"claim_pickup","realm":"water","flag":key},2).ok)
	assert_false(ledger.commit({"kind":"set_world_flag","realm":"water","id":key,"value":false},2).ok)
	var node_key := "cache:ripplet:lantern_pearl_bed:day:4"
	assert_false(ledger.commit({"kind":"harvest","realm":"water","flag":node_key,"item":"tide_pearl","amount":99},2).ok)
	assert_false(restored.flags.has(node_key))

func test_beds_respawn_on_host_day_and_replayed_claim_cannot_take_new_cycle() -> void:
	var flags := FLAGS.new()
	var row := SUNKEN.site("lantern_pearl_bed")
	var first := SUNKEN.claim_key(row,flags,1)
	flags.set_flag(first)
	assert_eq(SUNKEN.claim_key(row,flags,3),"")
	assert_eq(SUNKEN.claim_key(row,flags,4),"cache:ripplet:lantern_pearl_bed:day:4")
	var request := {"site_id":row.id,"creature_uid":UID,"claim_key":first}
	var context := actor()
	context.position = Vector3(-213,-6.6,175)
	assert_false(SUNKEN.evaluate(request,context,flags,4).ok)
	assert_eq(SUNKEN.claim_key(row,FLAGS.new(),0),"")
	assert_eq(SUNKEN.node_candidate(row,first,4).outputs,{"tide_pearl":4})

func test_stable_mount_uid_and_dive_budget_survive_json_without_peer_identity() -> void:
	var raw := {"version":1,"mode":2,"health_fraction":0.8,"stamina_fraction":0.37,"safe_anchor":[],
		"mount":{"party_index":0,"creature_uid":UID,"species_id":"ripplet","position":[-215,-5.7,166],"dive":{"remaining_s":3.5}}}
	var saved := SAVE.sanitise(JSON.parse_string(JSON.stringify(raw)))
	assert_eq(saved.mount.creature_uid,UID)
	assert_eq(saved.mount.dive.remaining_s,3.5)
	assert_eq(saved.stamina_fraction,0.37)
	for value: Variant in [-1,0,21,"3",NAN]:
		var broken := raw.duplicate(true)
		broken.mount.dive.remaining_s = value
		assert_true(SAVE.sanitise(broken).is_empty())
	var legacy := raw.duplicate(true)
	legacy.mount.erase("dive")
	legacy.mount.erase("creature_uid")
	assert_eq(SAVE.sanitise(legacy).mount.party_index,0)

func test_reordered_party_restores_same_individual_and_missing_uid_fails_closed() -> void:
	var saved := {"party_index":0,"creature_uid":UID,"species_id":"ripplet"}
	var party: Array = [{"uid":"other","species_id":"terrapup"},{"uid":UID,"species_id":"ripplet"}]
	assert_eq(SAVE.mount_index(saved,party),1)
	party.remove_at(1)
	assert_eq(SAVE.mount_index(saved,party),-1)
	assert_eq(SAVE.mount_index({"party_index":0,"species_id":"terrapup"},party),0)

func test_motion_budget_accepts_current_but_rejects_teleport_samples() -> void:
	assert_true(RULE.valid_motion(Vector3.ZERO,Vector3(10,0,0),1.0,3.0))
	assert_false(RULE.valid_motion(Vector3.ZERO,Vector3(50,0,0),1.0,3.0))
	assert_false(RULE.valid_motion(Vector3.ZERO,Vector3.INF,1.0,0.0))
