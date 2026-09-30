extends "res://tests/test_case.gd"

const MASTERY := preload("res://scripts/creatures/move_mastery.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const MOVES := preload("res://scripts/creatures/move_db.gd")

class Individual extends RefCounted:
	var uid := "companion-1"
	var known_moves: Array[String] = ["pebble_toss"]
	var move_mastery_uses: Dictionary = {}
	var move_mastery_receipts: Dictionary = {}
	var move_quick := "pebble_toss"
	var move_charged := "stone_rush"
	var move_utility := ""
	var move_ultimate := ""
	var loadout_revision := 0
	var loadout_last_edit: Dictionary = {}

func test_invalid_config_and_portable_document_cannot_forge_known_moves_or_uses() -> void:
	var good := {"rank_thresholds":[0,25,75,150,300],"damage_per_rank":.05,"max_known_moves":128}
	assert_true(MASTERY.valid_config(good))
	for thresholds: Array in [[],[0,25,75,300],[0,25,25,150,300],[1,25,75,150,300],[0,25,75,150,INF],[0,25.5,75,150,300],[0,25,75,150,301]]:
		var bad := good.duplicate(true)
		bad.rank_thresholds = thresholds
		assert_false(MASTERY.valid_config(bad), "invalid config fails closed before any hit")
	for field: String in ["damage_per_rank","max_known_moves"]:
		var bad := good.duplicate(true)
		bad[field] = INF
		assert_false(MASTERY.valid_config(bad))
	assert_true(MASTERY.valid_document(["pebble_toss"], {"pebble_toss":1}, {"pebble_toss":["fight:1:1"]}, ["pebble_toss"]))
	assert_false(MASTERY.valid_document(["invented_nuke"], {}, {}, ["invented_nuke"]), "host allowed list alone cannot register a nonexistent move")
	assert_false(MASTERY.valid_document(["stone_rush"], {}, {}, ["pebble_toss"]), "real but unlearned move refused")
	assert_false(MASTERY.valid_document(["pebble_toss"], {"pebble_toss":2}, {"pebble_toss":["fight:1:1","fight:1:1"]}, ["pebble_toss"]))
	assert_false(MASTERY.valid_document(["pebble_toss"], {"pebble_toss":2}, {"pebble_toss":["fight:1:1"]}, ["pebble_toss"]))

func test_threshold_crossing_freezes_old_rank_and_replay_cannot_credit_again() -> void:
	var creature := Individual.new()
	var receipts: Array[String] = []
	for index: int in 24: receipts.append("previous:%d" % index)
	creature.move_mastery_uses = {"pebble_toss":24}
	creature.move_mastery_receipts = {"pebble_toss":receipts}
	var before := creature.move_mastery_receipts.duplicate(true)
	var frozen_rank := MASTERY.rank_for(creature,"pebble_toss")
	var event := _event("fight:1:25")
	var proposed := MASTERY.stage_landed_use(creature,event)
	assert_true(proposed.ok)
	assert_eq(creature.move_mastery_receipts,before,"staging does not mutate live character")
	assert_eq(creature.move_mastery_uses.pebble_toss,24)
	creature.move_mastery_uses = proposed.uses
	creature.move_mastery_receipts = proposed.receipts
	assert_eq(frozen_rank,1,"same-action damage and presentation freeze rank before credit")
	assert_eq(MASTERY.rank_for(creature,"pebble_toss"),2,"next action uses earned new rank")
	assert_false(MASTERY.stage_landed_use(creature,event).ok,"reliable delivery/rejoin cannot award same action twice")
	for key: String in ["snapshot_replay","applied_damage","target_hp_before","attacker_uid","target_uid"]:
		var invalid := _event("fight:1:new")
		invalid[key] = {"snapshot_replay":true,"applied_damage":0.0,"target_hp_before":0.0,"attacker_uid":"different-companion","target_uid":"companion-1"}[key]
		assert_false(MASTERY.stage_landed_use(creature,invalid).ok)
	var overkill := _event("fight:1:overkill")
	overkill.applied_damage = 101.0
	assert_false(MASTERY.stage_landed_use(creature,overkill).ok,"caller must pass clamped actual HP debit")
	var preserved := creature.move_mastery_uses.duplicate(true)
	creature.move_mastery_uses.pebble_toss = 26
	assert_false(MASTERY.stage_landed_use(creature,_event("fight:1:new")).ok,"partial or inconsistent imported history fails closed")
	creature.move_mastery_uses = preserved

func test_saturation_retains_every_credited_identity_and_all_rank_thresholds() -> void:
	var creature := Individual.new()
	for count: int in 301:
		var old := creature.move_mastery_uses.duplicate(true)
		var result := MASTERY.stage_landed_use(creature,_event("fight:1:%d" % count))
		if count < 300:
			assert_true(result.ok)
			creature.move_mastery_uses = result.uses
			creature.move_mastery_receipts = result.receipts
		else:
			assert_false(result.ok)
			assert_eq(creature.move_mastery_uses,old,"rank5 saturation has no eviction/replay window")
	assert_eq(creature.move_mastery_receipts.pebble_toss.size(),300)
	for index: int in 300:
		assert_false(MASTERY.stage_landed_use(creature,_event("fight:1:%d" % index)).ok)
	for uses: int in [0,24,25,74,75,149,150,299,300]:
		assert_eq(MASTERY.rank_from_uses(uses), 1 if uses<25 else 2 if uses<75 else 3 if uses<150 else 4 if uses<300 else 5)

func test_mastery_launch_metadata_is_frozen_without_changing_geometry_or_timing() -> void:
	var feedback := preload("res://scripts/combat/hit_feedback.gd")
	var first := feedback.launch("fight:1:1","fight","companion-1","wild-1","pebble_toss","quick",Vector3.ZERO,Vector3.RIGHT,.2,7,Vector3.INF,AABB(),1)
	var fifth := feedback.launch("fight:1:1","fight","companion-1","wild-1","pebble_toss","quick",Vector3.ZERO,Vector3.RIGHT,.2,7,Vector3.INF,AABB(),5)
	assert_true(fifth.is_read_only())
	assert_eq(fifth.mastery_rank,5)
	for key: String in ["from","to","travel_seconds","body_generation","seed"]:
		assert_eq(fifth[key],first[key],"mastery never changes tells, reach or host schedule")
	var receipt := feedback.receipt("fight:1:1","pebble_toss",{},"quick",9.0,1.0,false,Vector3.RIGHT)
	var frozen := feedback.with_launch(receipt,fifth,{"archetype":"stone_throw"})
	assert_eq(frozen.mastery_rank,5)
	assert_true(frozen.is_read_only())
	assert_eq(frozen.damage,9.0,"presentation rank never rerolls gameplay damage")

func _event(action_id: String) -> Dictionary:
	return {"action_id":action_id,"move_id":"pebble_toss","attacker_uid":"companion-1","target_uid":"wild-1","target_hp_before":100.0,"applied_damage":7.0}

func test_whole_party_preflight_refuses_later_bad_row_and_mirror_preserves_other_records() -> void:
	var creature := preload("res://scripts/creatures/creature_instance.gd").from_species("terrapup",preload("res://scripts/creatures/creature_species.gd").definition("terrapup"))
	var party := preload("res://autoload/party.gd").new()
	party.add(creature)
	var saver := preload("res://scripts/save/save_game.gd").new()
	var entries: Array = saver._party_to_array(party)
	var character := preload("res://scripts/data/redesign_state.gd").defaults("character")
	assert_true(TEACHING.party_loadout_errors(entries,character).is_empty())
	var before := entries.duplicate(true)
	var bad := entries[0].duplicate(true)
	bad.loadout_revision = .5
	entries.append(bad)
	assert_false(TEACHING.party_loadout_errors(entries,character).is_empty(),"a later invalid row refuses the whole party")
	assert_eq(entries[0],before[0],"preflight never applies a prior good row")
	assert_false(TEACHING.party_loadout_errors(before,{"creatures":[]}).is_empty(),"hostile carrier fails closed")
	var mirror := TEACHING.character_loadout_mirror(before,character)
	assert_true(preload("res://scripts/data/redesign_state.gd").validate("character",mirror,[creature.uid]).is_empty())
	mirror.creatures[creature.uid].cap_level = 30
	mirror.creatures[creature.uid].breakthroughs = [1,2]
	mirror.creatures[creature.uid].taught_traits = {"1":"hardy"}
	var preserved := TEACHING.character_loadout_mirror(before,mirror)
	assert_eq(preserved.creatures[creature.uid].cap_level,30)
	assert_eq(preserved.creatures[creature.uid].breakthroughs,[1,2])
	assert_eq(preserved.creatures[creature.uid].taught_traits,{"1":"hardy"},"move mirror preserves other lane's earned records")
	assert_eq(character.creatures,{},"detached projection leaves live carrier untouched")
	var identity := MASTERY.new_action_identity("encounter:1:hit:1")
	assert_true(identity!=MASTERY.new_action_identity("encounter:1:hit:1"),"a recreated manager's counter cannot collide in the same process; callers freeze one allocation per accepted action")
	assert_true(identity!= "encounter:1:hit:1" and identity.length()<=160)

func test_portable_loadout_preflight_is_whole_and_detached_without_resetting_v28() -> void:
	var moves := MOVES.load_default()
	var allowed := ["pebble_toss","stone_rush"]
	assert_true(TEACHING.stage_saved_loadout({"uid":"companion-1"},allowed,moves).needs_defaults,
		"existing v28 without additive fields takes explicit caller default path, no schema reset")
	var saved := {"uid":"companion-1","known_moves":allowed.duplicate(),
		"move_mastery_uses":{"pebble_toss":1},"move_mastery_receipts":{"pebble_toss":["session:fight:1"]},
		"move_quick":"pebble_toss","move_charged":"stone_rush","move_utility":"","move_ultimate":"",
		"loadout_revision":0,"loadout_last_edit":{}}
	var staged := TEACHING.stage_saved_loadout(saved,allowed,moves)
	assert_true(staged.ok)
	staged.values.known_moves.clear()
	assert_eq(saved.known_moves,allowed,"preflight never lends mutable portable arrays to live application")
	for field: String in ["known_moves","move_mastery_uses","move_mastery_receipts","move_utility","move_ultimate","loadout_revision","loadout_last_edit"]:
		var partial := saved.duplicate(true)
		partial.erase(field)
		assert_false(TEACHING.stage_saved_loadout(partial,allowed,moves).ok,"partially saved generation refuses whole load")
	for replacement: Dictionary in [{"move_quick":"invented_nuke"},{"move_charged":"pebble_toss"},
		{"loadout_revision":.5},{"loadout_revision":INF},{"loadout_revision":1,"loadout_last_edit":{}}]:
		var invalid := saved.duplicate(true)
		invalid.merge(replacement,true)
		assert_false(TEACHING.stage_saved_loadout(invalid,allowed,moves).ok)
	var edited := saved.duplicate(true)
	edited.loadout_revision = 1.0
	edited.loadout_last_edit = {"edit_id":"camp-edit:1","expected_revision":0.0,"creature_uid":"companion-1",
		"quick":"pebble_toss","charged":"stone_rush","utility":""}
	assert_true(TEACHING.stage_saved_loadout(edited,allowed,moves).ok,"JSON whole-number floats retain exact transaction history")
	edited.loadout_last_edit.creature_uid = "companion-2"
	assert_false(TEACHING.stage_saved_loadout(edited,allowed,moves).ok,"another creature cannot import the edit receipt")

func test_station_edit_stages_compare_and_swap_and_refuses_wrong_scope_or_replay_collision() -> void:
	var creature := Individual.new()
	creature.known_moves.append("stone_rush")
	var moves := MOVES.load_default()
	var context := {"owned_creature_uids":["companion-1"],"station_kind":"altar","within_reach":true,"in_combat":false}
	var request := {"edit_id":"altar-edit:1","expected_revision":0,"creature_uid":"companion-1",
		"quick":"pebble_toss","charged":"stone_rush","utility":""}
	var staged := TEACHING.stage_loadout_edit(creature,request,context,moves)
	assert_true(staged.ok)
	assert_eq(creature.loadout_revision,0,"pure staging cannot commit before durable transaction succeeds")
	for replacement: Dictionary in [{"owned_creature_uids":["companion-2"]},{"station_kind":"backpack"},
		{"within_reach":false},{"in_combat":true}]:
		var wrong := context.duplicate(true)
		wrong.merge(replacement,true)
		assert_false(TEACHING.stage_loadout_edit(creature,request,wrong,moves).ok)
	creature.loadout_revision = staged.revision
	creature.loadout_last_edit = staged.receipt.duplicate(true)
	assert_true(TEACHING.stage_loadout_edit(creature,request,context,moves).replayed,
		"same committed request receives original revision without a second mutation")
	var colliding := request.duplicate(true)
	colliding.quick = "stone_rush"
	assert_false(TEACHING.stage_loadout_edit(creature,colliding,context,moves).ok,"same edit identity cannot name a different command")
	var stale := request.duplicate(true)
	stale.edit_id = "altar-edit:2"
	assert_false(TEACHING.stage_loadout_edit(creature,stale,context,moves).ok,"concurrent stale request cannot overwrite committed slots")
