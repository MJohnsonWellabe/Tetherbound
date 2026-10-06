extends "res://tests/test_case.gd"

## Rejoin admission on the real CharacterAuthority, owner ruling 2026-10-05:
## "guest wins unless behind". A returning owner whose record differs:
## - NOT behind (every receipt, personal flag and payout this world recorded is
##   in it): its declaration is adopted at a higher revision -- offline catches,
##   an accepted legendary, guest-side grants (rejoin_audit.md) are kept;
## - BEHIND (a rollback or restored backup): the held record wins, first
##   folding this world's own journaled payouts (whole rows, never twice), and
##   the folded rows are handed to the owner to settle (unconfirmed_folds).
## Disclosed fixtures: a fresh character with one spawned creature (as in
## test_creature_gear), world rows written straight into a deliveries table,
## settled ids passed as the hello's settled_deliveries.

const AUTHORITY := preload("res://scripts/net/character_authority.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const REWARD := preload("res://scripts/net/reward_delivery.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const NS := "0123456789abcdef0123456789abcdef"

var _items: RefCounted


func _record() -> Dictionary:
	if _items == null: _items = ITEM_DB.new()
	var player := preload("res://autoload/player_state.gd").new()
	player.configure(_items)
	player.character_id = "character-rejoin-owner"
	player.party.add(preload("res://scripts/creatures/creature_species.gd").spawn("terrapup"))
	return RECORD.portable_projection(player.save_data())


func _authority(record: Dictionary, deliveries: Dictionary) -> RefCounted:
	var authority: RefCounted = AUTHORITY.new()
	assert_true(authority.call("bind_world", NS), "world bound")
	assert_true(bool((authority.call("seed_admitted_character", record, record.character_id) as Dictionary).get("ok")), "first admission")
	authority.call("seed_absorbed_deliveries", record.character_id, deliveries)
	return authority


func _row(source: String, item: String, count: int, status: String) -> Dictionary:
	var row := REWARD.make_record("world-1", NS, source, "character-rejoin-owner", item, count)
	row.status = status
	return row


func _with(record: Dictionary, item: String, count: int) -> Dictionary:
	var out := record.duplicate(true)
	var bag := preload("res://scripts/world/death_satchel_rules.gd").inventory_from(out.inventory)
	bag.call("add", item, count)
	out.inventory = preload("res://scripts/world/death_satchel_rules.gd").slots(bag)
	return out


func _veridian_declared(record: Dictionary) -> Dictionary:
	# The legendary built exactly as stronghold_climax builds it, joined to the
	# owner's own belt on its side.
	if _items == null: _items = ITEM_DB.new()
	var player := preload("res://autoload/player_state.gd").new()
	player.configure(_items)
	player.load_data(record.duplicate(true))
	var spec: Dictionary = preload("res://scripts/data/redesign_data.gd").json("res://data/config/stronghold_climax.json").get("legendary", {})
	var creature: RefCounted = preload("res://scripts/world/stronghold_climax.gd").TRAINER_NPCS.creature_for({"species": str(spec.get("species", "veridian")), "level": int(spec.get("level", 1))})
	player.party.add(creature)
	return RECORD.portable_projection(player.save_data())



func _caught(record: Dictionary, hex: String) -> Dictionary:
	var out := record.duplicate(true)
	var catch: Dictionary = out.party[0].duplicate(true)
	catch.uid = "creature-" + hex
	out.party.append(catch)
	return out


func test_a_declaration_not_behind_is_adopted_with_its_offline_catch() -> void:
	var record := _record()
	var authority := _authority(record, {})
	var character: String = record.character_id
	var declared := _caught(record, "a1b2c3d4e5f60718293a4b5c6d7e8f90")
	var result: Dictionary = authority.call("rejoin_admission", character, declared, {}, [], [])
	assert_eq(result.get("code"), "readmitted_portable", "guest wins: %s" % str(result))
	assert_eq((authority.call("state", character) as Dictionary).party.size(), 2, "with its offline catch")
	assert_eq(int(authority.call("revision", character)), 1, "at a higher revision, so a stale request is refused")
	assert_eq((authority.call("rejoin_admission", character, declared, {}, [], []) as Dictionary).get("code"), "held", "the same record again: nothing to do")


func test_an_accepted_legendary_is_kept_because_the_guest_wins() -> void:
	# #544 regression (veridian_choices): installed on the guest's side only.
	var record := _record()
	var authority := _authority(record, {})
	var character: String = record.character_id
	var declared := _veridian_declared(record)
	assert_eq((authority.call("rejoin_admission", character, declared, {}, [], []) as Dictionary).get("code"), "readmitted_portable")
	var held: Dictionary = authority.call("state", character)
	assert_eq(str(held.party[1].species_id), "veridian", "the Veridian is in this world's record")


func test_a_missing_receipt_is_behind_and_the_held_record_wins() -> void:
	var record := _record()
	var authority := _authority(record, {})
	var character: String = record.character_id
	var held: Dictionary = authority.call("state", character)
	held.redesign_character.transaction_receipts.append("craft:%s:%s" % [character, "0123456789abcdef0123456789abcdef"])
	authority.call("_replace_record", character, 1, held)
	var backup := _caught(record, "b1b2c3d4e5f60718293a4b5c6d7e8f90") # older file, plus a catch
	var result: Dictionary = authority.call("rejoin_admission", character, backup, {}, [], [])
	assert_eq(result.get("code"), "held_wins", "behind: %s" % str(result))
	assert_true(str(result.get("detail", "")).begins_with("receipt"), "a missing receipt (%s)" % str(result.get("detail", "")))
	assert_eq((authority.call("state", character) as Dictionary).party.size(), 1, "the held record stands")
	assert_eq(int(authority.call("revision", character)), 1)


func test_a_missing_release_receipt_is_behind() -> void:
	var record := _record()
	var authority := _authority(record, {})
	var character: String = record.character_id
	var held: Dictionary = authority.call("state", character)
	held.redesign_character.release_receipts.append("release:%s:%s" % [character, "fedcba9876543210fedcba9876543210"])
	authority.call("_replace_record", character, 1, held)
	var result: Dictionary = authority.call("rejoin_admission", character, _caught(record, "c1b2c3d4e5f60718293a4b5c6d7e8f90"), {}, [], [])
	assert_eq(result.get("code"), "held_wins")
	assert_true(str(result.get("detail", "")).begins_with("release_receipts"), str(result.get("detail", "")))


func test_a_missing_personal_flag_is_behind() -> void:
	var record := _record()
	var authority := _authority(record, {})
	var character: String = record.character_id
	authority.call("record_personal_flag", character, "home_key_given", true)
	var declared := _caught(record, "d1b2c3d4e5f60718293a4b5c6d7e8f90")
	var result: Dictionary = authority.call("rejoin_admission", character, declared, {}, [], [])
	assert_eq(result.get("code"), "held_wins", "a host-recorded flag missing: %s" % str(result))
	assert_eq(str(result.get("detail", "")), "personal_flag home_key_given")
	assert_eq((authority.call("rejoin_admission", character, declared, {}, ["home_key_given"], []) as Dictionary).get("code"), "readmitted_portable",
		"with the flag it is not behind")


func test_a_missing_absorbed_or_accepted_payout_is_behind() -> void:
	var record := _record()
	var deliveries := {}
	var authority := _authority(record, deliveries)
	var character: String = record.character_id
	var live := _row("pickup:live", "berries", 3, "accepted")
	deliveries[live.delivery_id] = live
	var after := _with(record, "berries", 3)
	assert_true(authority.call("apply_owner_reward_delivery", character, authority.call("state", character), after, live.delivery_id), "absorbed live")
	var declared := _caught(after, "e1b2c3d4e5f60718293a4b5c6d7e8f90")
	var result: Dictionary = authority.call("rejoin_admission", character, declared, deliveries, [], [])
	assert_eq(result.get("code"), "held_wins", "an absorbed payout the owner no longer holds: %s" % str(result))
	assert_true(str(result.get("detail", "")).begins_with("payout"))
	var acked := _row("pickup:acked", "fiber", 2, "accepted") # ACKed (owner saved it), never replayed
	deliveries[acked.delivery_id] = acked
	result = authority.call("rejoin_admission", character, declared, deliveries, [], [live.delivery_id])
	assert_eq(result.get("code"), "held_wins", "an accepted payout the owner no longer holds is behind too")
	# A pruned row's id is gone from both sides: never behind for it.
	deliveries.erase(live.delivery_id)
	result = authority.call("rejoin_admission", character, _with(declared, "fiber", 2), deliveries, [], [acked.delivery_id])
	assert_eq(result.get("code"), "readmitted_portable", "holding every live payout it is not behind: %s" % str(result))


func test_deliver_then_leave_adopts_the_owner_record_and_absorbs_its_payouts_once() -> void:
	var record := _record()
	var deliveries := {}
	var authority := _authority(record, deliveries)
	var character: String = record.character_id
	var first := _row("pickup:a", "berries", 3, "accepted")
	var lost_ack := _row("pickup:b", "fiber", 2, "pending") # applied and saved; its ACK lost
	deliveries[first.delivery_id] = first
	deliveries[lost_ack.delivery_id] = lost_ack
	var declared := _with(_with(record, "berries", 3), "fiber", 2)
	var result: Dictionary = authority.call("rejoin_admission", character, declared, deliveries, [], [first.delivery_id, lost_ack.delivery_id])
	assert_eq(result.get("code"), "readmitted_portable", "%s" % str(result))
	assert_eq(result.get("applied"), [first.delivery_id, lost_ack.delivery_id], "both now absorbed")
	var bag := preload("res://scripts/world/death_satchel_rules.gd").inventory_from((authority.call("state", character) as Dictionary).inventory)
	assert_eq(int(bag.call("count", "berries")), 3, "exactly once")
	assert_false(authority.call("apply_owner_reward_delivery", character, authority.call("state", character), _with(declared, "berries", 3), first.delivery_id),
		"a replay of it later is refused (never twice)")


func test_behind_folds_this_worlds_payouts_whole_and_never_twice() -> void:
	var record := _record()
	var deliveries := {}
	var authority := _authority(record, deliveries)
	var character: String = record.character_id
	authority.call("record_personal_flag", character, "home_key_given", true) # makes the backup behind
	var row := _row("pickup:fold", "berries", 2, "accepted")
	deliveries[row.delivery_id] = row
	var big := REWARD.make_record("world-1", NS, "gather:big", character, "", 0)
	big.status = "pending"
	big.stacks = [{"id": "potion_small", "n": 1}, {"id": "orb_basic", "n": 1}]
	deliveries[big.delivery_id] = big
	# A nearly full held satchel: the two-stack row cannot land whole.
	var held: Dictionary = authority.call("state", character)
	var bag := preload("res://scripts/world/death_satchel_rules.gd").inventory_from([])
	var stone := int(preload("res://scripts/world/death_satchel_rules.gd").db().call("stack_size", "stone"))
	for slot in int(bag.call("slot_count")) - 2: bag.call("set_slot", slot, {"id": "stone", "n": stone})
	held.inventory = preload("res://scripts/world/death_satchel_rules.gd").slots(bag)
	authority.call("_replace_record", character, 0, held)
	var result: Dictionary = authority.call("rejoin_admission", character, _caught(record, "f1b2c3d4e5f60718293a4b5c6d7e8f90"), deliveries, [], [])
	assert_eq(result.get("code"), "held_wins")
	assert_eq(result.get("applied"), [row.delivery_id], "the fitting row folds; the half-fitting one does not")
	var after := preload("res://scripts/world/death_satchel_rules.gd").inventory_from((authority.call("state", character) as Dictionary).inventory)
	assert_eq(int(after.call("count", "berries")), 2)
	assert_eq(int(after.call("count", "potion_small")) + int(after.call("count", "orb_basic")), 0, "no partial stack")
	assert_eq((authority.call("unconfirmed_folds", character) as Array).map(func(r: Dictionary) -> String: return r.delivery_id), [row.delivery_id],
		"handed to the owner to settle")
	authority.call("rejoin_admission", character, _caught(record, "f1b2c3d4e5f60718293a4b5c6d7e8f90"), deliveries, [], [])
	assert_eq(int(preload("res://scripts/world/death_satchel_rules.gd").inventory_from((authority.call("state", character) as Dictionary).inventory).call("count", "berries")), 2,
		"a second rejoin folds nothing again")


func test_an_open_host_transaction_never_swaps_the_record() -> void:
	var record := _record()
	var authority := _authority(record, {})
	var character: String = record.character_id
	authority.get("_loadout_pending")[character] = {"uid": "x"}
	var result: Dictionary = authority.call("rejoin_admission", character, _caught(record, "a2b2c3d4e5f60718293a4b5c6d7e8f90"), {}, [], [])
	assert_eq(result.get("code"), "host_duties_unsettled")
	assert_eq((authority.call("state", character) as Dictionary).party.size(), 1, "the held record stays while it settles")


func test_a_windowed_kind_the_declaration_compacted_is_not_behind() -> void:
	var record := _record()
	var authority := _authority(record, {})
	var character: String = record.character_id
	var window: int = preload("res://scripts/creatures/receipt_windows.gd").window("groom")
	var held: Dictionary = authority.call("state", character)
	held.redesign_character.transaction_receipts.append("groom:oldest")
	authority.call("_replace_record", character, 1, held)
	var declared := record.duplicate(true)
	for i in window: declared.redesign_character.transaction_receipts.append("groom:newer-%d" % i)
	assert_eq(authority.call("declaration_behind", character, declared, [], [], {}), "", "a full newer window compacted it")
	declared.redesign_character.transaction_receipts.pop_back()
	assert_true(str(authority.call("declaration_behind", character, declared, [], [], {})).begins_with("receipt"), "below the window it is behind")


func test_home_key_rows_are_never_credited_by_a_fold() -> void:
	var record := _record()
	var authority := _authority(record, {})
	var character: String = record.character_id
	var key_row := REWARD.make_record("world-1", NS, "home_key:grant:" + character, character, "home_key", 1, "home_key_given")
	key_row.status = "accepted"
	assert_false(AUTHORITY.owner_applied_row(key_row, character), "the Home Key grant is a host CAS, never folded")
	var snapshot: Dictionary = authority.call("snapshot_record", character)
	authority.call("_replace_record", character, 9, _caught(record, "b2b2c3d4e5f60718293a4b5c6d7e8f90"))
	authority.get("_vitals_pending")[character] = {"uid": "x"}
	authority.call("restore_record", character, snapshot)
	assert_false((authority.get("_vitals_pending") as Dictionary).has(character), "a refused hello restores the maps")
	assert_eq(int(authority.call("revision", character)), 0, "and the exact held record")


func test_an_open_host_row_is_never_read_as_behind() -> void:
	# Review H1: a wild win's training row staged the receipt into the held
	# record; the owner left before its ACK. Its declaration lacks the receipt
	# only because it is mid-transaction: nothing is adopted or folded.
	var record := _record()
	var deliveries := {}
	var authority := _authority(record, deliveries)
	var character: String = record.character_id
	var held: Dictionary = authority.call("state", character)
	held.redesign_character.transaction_receipts.append("defeat:%s:%s" % [character, "0123456789abcdef0123456789abcdef"])
	authority.call("_replace_record", character, 1, held)
	deliveries["creature_training:x"] = {"kind": "creature_training", "character_id": character, "status": "pending", "delivery_id": "creature_training:x"}
	var gather := _row("gather:open", "berries", 2, "pending")
	deliveries[gather.delivery_id] = gather
	var result: Dictionary = authority.call("rejoin_admission", character, _caught(record, "a3b2c3d4e5f60718293a4b5c6d7e8f90"), deliveries, [], [])
	assert_eq(result.get("code"), "host_duties_unsettled", "%s" % str(result))
	assert_eq((authority.call("state", character) as Dictionary).inventory, held.inventory, "nothing folded")
	assert_true((authority.call("unconfirmed_folds", character) as Array).is_empty())
	authority.get("_training_pending")[character] = {"uid": "x"}
	deliveries.erase("creature_training:x")
	assert_eq((authority.call("rejoin_admission", character, _caught(record, "a3b2c3d4e5f60718293a4b5c6d7e8f90"), deliveries, [], []) as Dictionary).get("code"),
		"host_duties_unsettled", "the authority's own open training lock too")


func test_an_owed_payout_counts_as_held_but_is_never_absorbed() -> void:
	# Review H2: a full bag ACKs a payout as grant_due; it settles and replays
	# later, so it must not be absorbed (its replay would be refused).
	var record := _record()
	var deliveries := {}
	var owed_row := _row("pickup:owed", "berries", 2, "accepted")
	deliveries[owed_row.delivery_id] = owed_row
	var authority: RefCounted = AUTHORITY.new()
	authority.call("bind_world", NS)
	authority.call("seed_admitted_character", record, record.character_id)
	authority.call("seed_absorbed_deliveries", record.character_id, deliveries, [owed_row.delivery_id])
	var character: String = record.character_id
	assert_false((authority.call("_absorbed", character) as Dictionary).has(owed_row.delivery_id), "first join: an owed payout is not absorbed")
	var declared := _caught(record, "a4b2c3d4e5f60718293a4b5c6d7e8f90")
	var result: Dictionary = authority.call("rejoin_admission", character, declared, deliveries, [], [], [owed_row.delivery_id])
	assert_eq(result.get("code"), "readmitted_portable", "owed counts as present, not behind: %s" % str(result))
	assert_eq(result.get("applied"), [], "and is not absorbed on adoption either")
	var after := _with(authority.call("state", character), "berries", 2)
	assert_true(authority.call("apply_owner_reward_delivery", character, authority.call("state", character), after, owed_row.delivery_id),
		"its later settle replays normally")


func test_an_unconfirmed_fold_stays_required_after_its_row_is_pruned() -> void:
	# Review M2: a behind rejoin folded gather row G (marked replayed, then
	# pruned); the owner left before confirming. The same backup must still be
	# behind, never adopted without G.
	var record := _record()
	var deliveries := {}
	var authority := _authority(record, deliveries)
	var character: String = record.character_id
	authority.call("record_personal_flag", character, "home_key_given", true)
	var g := _row("gather:g", "berries", 2, "accepted")
	deliveries[g.delivery_id] = g
	var backup := _caught(record, "a5b2c3d4e5f60718293a4b5c6d7e8f90")
	assert_eq((authority.call("rejoin_admission", character, backup, deliveries, [], []) as Dictionary).get("code"), "held_wins")
	deliveries.erase(g.delivery_id) # pruned
	var result: Dictionary = authority.call("rejoin_admission", character, backup, deliveries, ["home_key_given"], [])
	assert_eq(result.get("code"), "held_wins", "still behind on the unconfirmed fold: %s" % str(result))
	assert_true(str(result.get("detail", "")).begins_with("payout"))
	assert_eq((authority.call("rejoin_admission", character, backup, deliveries, ["home_key_given"], [g.delivery_id]) as Dictionary).get("code"),
		"readmitted_portable", "once the owner holds it settled it is not behind")
