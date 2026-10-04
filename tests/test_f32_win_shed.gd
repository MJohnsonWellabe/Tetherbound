extends "res://tests/test_case.gd"

## F32#4 win shed, composed inside F27's host wild-defeat stage (essence.gd
## stage_defeat): an ordinary wild win pays its configured shed item from a
## host-derived deterministic roll, exactly once (the defeat receipt), never
## on a miss or outside the species' realms, and a full satchel skips the
## shed rather than refusing the victory XP and essence.
const E := preload("res://scripts/creatures/essence.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const RULES := preload("res://scripts/world/death_satchel_rules.gd")
const SHED := preload("res://scripts/world/shed_drop_rules.gd")
const CHARACTER := "f32-shed-owner"
const NAMESPACE := "f32-shed-world"


func _player() -> RefCounted:
	var player := preload("res://autoload/player_state.gd").new()
	player.configure(preload("res://autoload/item_db.gd").new())
	player.character_id = CHARACTER
	var card: RefCounted = SPECIES.spawn("terrapup")
	player.party.add(card)
	card.set("level", 5)
	card.call("_apply_level_stats", PROGRESSION.config())
	return player


func _admitted(player: RefCounted) -> Dictionary:
	var record := RECORD.portable_projection(player.save_data())
	assert_eq(RECORD.errors(record, CHARACTER), [], "canonical admitted record")
	return record


func _event(record: Dictionary, event_id: String, realm: String, species: String = "galecrest") -> Dictionary:
	var wild_player := preload("res://autoload/player_state.gd").new()
	wild_player.configure(preload("res://autoload/item_db.gd").new())
	wild_player.character_id = "wild"
	wild_player.party.add(SPECIES.spawn(species))
	var enemy: Dictionary = RECORD.portable_projection(wild_player.save_data()).party[0]
	enemy.uid = "wild-" + species
	enemy.level = 5
	enemy.hp = 0
	enemy.fainted = true
	var uid: String = record.party[0].uid
	var event := {"event_id": event_id, "world_namespace": NAMESPACE, "encounter_id": "enc-" + event_id,
		"enemy_uid": enemy.uid, "enemy_record": enemy, "active_uid": uid, "eligible_uids": [uid],
		"kind": "wild_defeat", "xp_mode": "hybrid", "realm": realm, "shed": {}}
	# As host_wild_defeat_event: the shed is decided once and frozen in the event.
	event.shed = E.defeat_shed(event, CHARACTER)
	return event


## Independent recomputation of the documented host roll.
func _roll(event: Dictionary) -> float:
	var digest := JSON.stringify([event.world_namespace, event.event_id, event.enemy_uid, CHARACTER]).sha256_text()
	return float(("0x" + digest.substr(0, 8)).hex_to_int()) / 4294967296.0


func _find(record: Dictionary, hit: bool) -> Dictionary:
	var chance := float(SHED.read().wild_win_chance)
	for i in 400:
		var event := _event(record, "wild_defeat:shed-%d" % i, "cloudreach")
		if (_roll(event) < chance) == hit: return event
	return {}


func _stage(record: Dictionary, event: Dictionary, revision: int = 2) -> Dictionary:
	return E.stage_defeat(record, CHARACTER, event, revision, E.config(), PROGRESSION.config())


func _count(record: Dictionary, item: String) -> int:
	return RULES.inventory_from(record.inventory).count(item)


func test_configured_cloudreach_galecrest_win_sheds_skyplume_once() -> void:
	var before := _admitted(_player())
	var event := _find(before, true)
	assert_false(event.is_empty(), "some host identity rolls under the configured chance")
	var staged := _stage(before, event)
	assert_true(staged.get("ok") == true and staged.get("duplicate") == false, str(staged))
	assert_eq(staged.shed_outputs, {"skyplume": 1})
	assert_eq(_count(staged.state, "skyplume"), _count(before, "skyplume") + 1)
	assert_eq(_count(staged.state, "essence_air"), _count(before, "essence_air") + 1, "victory essence is still paid")
	# Retry/recompute from the same admitted record reproduces it exactly.
	var retried := _stage(before, event)
	assert_eq(retried.shed_outputs, staged.shed_outputs)
	assert_true(E._equivalent(retried.state, staged.state), "deterministic host roll, no reroll on retry")
	# Replay against the committed record (reload/reconnect) pays nothing again.
	var replay := _stage(staged.state, event, 3)
	assert_true(replay.get("ok") == true and replay.get("duplicate") == true, str(replay))
	assert_false(replay.has("state"))


func test_misses_wrong_realms_and_unlisted_species_shed_nothing() -> void:
	var before := _admitted(_player())
	var miss := _find(before, false)
	assert_false(miss.is_empty())
	var missed := _stage(before, miss)
	assert_true(missed.get("ok") == true, str(missed))
	assert_eq(missed.shed_outputs, {}, "a roll at or over the chance sheds nothing")
	var hit := _find(before, true)
	var meadows := _event(before, hit.event_id, "meadows")
	assert_eq(meadows.shed, {}, "galecrest sheds only in its configured realms")
	assert_eq(_stage(before, meadows).shed_outputs, {})
	var bramble := _event(before, hit.event_id, "cloudreach", "bramblebun")
	assert_eq(_stage(before, bramble).get("shed_outputs"), {}, "a species without a shed profile pays none")


func test_nine_key_legacy_event_validates_without_shed_and_keeps_its_receipt() -> void:
	var before := _admitted(_player())
	var hit := _find(before, true)
	var legacy := hit.duplicate(true)
	legacy.erase("realm")
	legacy.erase("shed")
	var old := _stage(before, legacy)
	assert_true(old.get("ok") == true, str(old))
	assert_eq(old.shed_outputs, {})
	assert_eq(old.receipt, _stage(before, hit).receipt, "realm is not part of the defeat receipt signature")
	# An unknown realm never refuses the win: it simply sheds nothing.
	var unknown := _event(before, hit.event_id, "not-a-realm")
	var paid := _stage(before, unknown)
	assert_true(paid.get("ok") == true and paid.shed_outputs.is_empty(), str(paid))


func test_frozen_shed_is_used_as_is_and_malformed_sheds_are_refused() -> void:
	var before := _admitted(_player())
	var hit := _find(before, true)
	# A later config change cannot alter a frozen decision: the row pays what
	# the host froze, even where a fresh roll would now differ.
	var frozen := _find(before, false)
	frozen.shed = {"skyplume": 1}
	assert_eq(_stage(before, frozen).shed_outputs, {"skyplume": 1})
	for bad: Variant in [{"skyplume": 1000}, {"not_an_item": 1}, {"skyplume": 0}, ["skyplume"]]:
		var event := hit.duplicate(true)
		event.shed = bad
		assert_eq(_stage(before, event).get("code"), "invalid_defeat_event", "refuses frozen shed " + str(bad))


func test_full_satchel_skips_the_shed_but_pays_victory_xp_and_essence() -> void:
	var player := _player()
	player.inventory.add("essence_air", 1) # The essence payout can still stack here.
	player.inventory.add("wood", 100000) # Every other slot is full.
	var before := _admitted(player)
	var event := _find(before, true)
	var staged := _stage(before, event)
	assert_true(staged.get("ok") == true, "a full bag never refuses the win: " + str(staged))
	assert_eq(staged.shed_outputs, {}, "no room, no shed")
	assert_eq(_count(staged.state, "skyplume"), 0)
	assert_eq(_count(staged.state, "essence_air"), 2)
	var uid: String = before.party[0].uid
	var xp_before := int(before.party[0].get("xp", 0))
	var after_card: Dictionary = staged.state.party[0]
	assert_true(int(after_card.level) > 5 or int(after_card.xp) > xp_before, "victory XP is still paid for " + uid)
