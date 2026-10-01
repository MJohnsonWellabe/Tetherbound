extends "res://tests/test_case.gd"

const RULE := preload("res://scripts/player/ripplet_traversal.gd")
const SUNKEN := preload("res://scripts/world/ripplet_sunken_rules.gd")
const SAVE := preload("res://scripts/save/water_traversal_save.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const WORLD := preload("res://autoload/world_state.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const UID := "creature-0123456789abcdef0123456789abcdef"

func admitted(tiers: Array = []) -> Dictionary:
	return {"character_id":"f37-character", "party":[{"uid":UID,"species_id":"ripplet","level":30,"fainted":false,"resting":false}],
		"inventory":[], "redesign_character":{"creatures":{UID:{"breakthroughs":tiers}}}}

func actor(tiers: Array = [30]) -> Dictionary:
	return {"peer":2,"character_id":"f37-character","realm":"water","admitted":admitted(tiers),
		"combat":false,"mounted_uid":UID,"in_water":true,"dive_clearance":true,
		"sealed":false,"mount_reachable":true,"diving":true,"position":Vector3(-215,-6.6,166)}

func test_level_thirty_is_not_the_breakthrough_and_other_creatures_never_dive() -> void:
	assert_false(RULE.can_dive(admitted(), UID))
	assert_true(RULE.can_dive(admitted([10,20,30]), UID))
	assert_false(RULE.can_dive(admitted([30]), "another-creature"))
	var other := admitted([30])
	other.party[0].species_id = "water_aquaryn"
	assert_false(RULE.can_dive(other, UID))
	other = admitted([30])
	other.party[0].resting = true
	assert_false(RULE.can_dive(other, UID))

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
	assert_false(RULE.action(intent,actor([10,20])).ok)

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
