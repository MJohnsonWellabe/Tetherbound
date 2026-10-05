extends "res://tests/test_case.gd"

## Rejoin admission (coordinator 2026-10-05; F01 op10/op11, F18 render
## 37365638014) on the real CharacterAuthority:
## - deliver-then-leave: the held record misses host-accepted payouts whose
##   owner-passive inputs never replayed; the host rebuilds them from its OWN
##   world rows (amounts never read from the declaration) and admits;
## - an already-absorbed payout is never applied a second time;
## - an offline portable change (a solo catch) re-admits the current record at
##   a higher revision when nothing here is owed; with an open host duty the
##   held record stays and nothing is adopted.
## Disclosed fixtures: a fresh character with one spawned creature (as in
## test_creature_gear), world rows written straight into a deliveries table.

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


func test_deliver_then_leave_is_rebuilt_from_host_rows_and_never_twice() -> void:
	var record := _record()
	var deliveries := {}
	var authority := _authority(record, deliveries)
	var character: String = record.character_id
	# Two finds the owner applied, saved and ACKed (accepted), then left before
	# their owner-passive inputs replayed; one still pending (not in its satchel).
	var first := _row("pickup:a", "berries", 3, "accepted")
	var second := _row("pickup:b", "fiber", 2, "accepted")
	var pending := _row("pickup:c", "stone", 5, "pending")
	deliveries[first.delivery_id] = first
	deliveries[second.delivery_id] = second
	deliveries[pending.delivery_id] = pending
	var declared := _with(_with(record, "berries", 3), "fiber", 2)
	# Passive drift on the card is the owner-passive readmit's business, not this one.
	declared.party[0].nourishment = float(declared.party[0].get("nourishment", 100.0)) - 7.0
	var result: Dictionary = authority.call("rejoin_admission", character, declared, deliveries)
	assert_eq(result.get("code"), "replayed_deliveries", "rebuilt from the host's accepted rows: %s" % str(result))
	var held: Dictionary = authority.call("state", character)
	var core := preload("res://scripts/net/owner_passive_replay.gd")
	assert_true(preload("res://scripts/creatures/essence.gd")._equivalent(core._core(held), core._core(declared)),
		"the held record now matches the owner's (inventory from host rows)")
	assert_eq(int(authority.call("revision", character)), 0, "no revision change: only replayed payouts")
	# A later rewrite of the record (any _replace_record caller) keeps the set.
	authority.call("_replace_record", character, 0, authority.call("state", character))
	# Rejoining again with the same satchel adds nothing (absorbed, never twice).
	assert_eq((authority.call("rejoin_admission", character, declared, deliveries) as Dictionary).get("code"), "held",
		"the same rows are never applied a second time")
	# The same amounts again (found offline) are NOT explained by those rows a
	# second time: that is an offline change, not a host-proven payout.
	var doubled := _with(_with(declared, "berries", 3), "fiber", 2)
	assert_eq((authority.call("rejoin_admission", character, doubled, deliveries) as Dictionary).get("code"), "readmitted_portable",
		"absorbed rows are never counted twice, even after a record rewrite")


func test_a_payout_replayed_live_is_absorbed_and_not_rebuilt_again() -> void:
	var record := _record()
	var deliveries := {}
	var authority := _authority(record, deliveries)
	var character: String = record.character_id
	var row := _row("pickup:a", "berries", 3, "accepted")
	deliveries[row.delivery_id] = row
	var after := _with(record, "berries", 3)
	assert_true(authority.call("apply_owner_reward_delivery", character, authority.call("state", character), after, row.delivery_id),
		"the live owner-passive replay applies the payout")
	var leftover := _row("pickup:z", "berries", 3, "accepted")
	deliveries[leftover.delivery_id] = leftover
	# The owner holds exactly the one payout; the second accepted row must not
	# make the host think it holds two.
	var result: Dictionary = authority.call("rejoin_admission", character, after, deliveries)
	assert_eq(result.get("code"), "held", "an absorbed payout is not rebuilt again: %s" % str(result))


func test_offline_catch_readmits_the_current_portable_record_once_nothing_is_owed() -> void:
	var record := _record()
	var deliveries := {}
	var authority := _authority(record, deliveries)
	var character: String = record.character_id
	var declared := record.duplicate(true)
	var caught: Dictionary = declared.party[0].duplicate(true)
	caught.uid = "creature-%s" % "a1b2c3d4e5f60718293a4b5c6d7e8f90"
	declared.party.append(caught)
	assert_true(AUTHORITY.errors(declared, character).is_empty(), "the offline record passes first-join rules: %s" % str(AUTHORITY.errors(declared, character)))
	# An open host duty keeps the held record.
	authority.get("_loadout_pending")[character] = {"uid": "x"}
	var busy: Dictionary = authority.call("rejoin_admission", character, declared, deliveries)
	assert_eq(busy.get("code"), "host_duties_unsettled", "nothing is adopted while a host duty is open")
	assert_eq((authority.call("state", character) as Dictionary).party.size(), 1, "held record unchanged")
	authority.get("_loadout_pending").erase(character)
	var readmit: Dictionary = authority.call("rejoin_admission", character, declared, deliveries)
	assert_eq(readmit.get("code"), "readmitted_portable", "the current portable record is admitted: %s" % str(readmit))
	assert_eq((authority.call("state", character) as Dictionary).party.size(), 2, "with its offline catch")
	assert_eq(int(authority.call("revision", character)), 1, "at a higher revision, so a stale request is refused")


func test_a_declaration_behind_the_held_record_is_never_readmitted() -> void:
	# Review H2: a restored backup would re-earn what this world already paid.
	var record := _record()
	var deliveries := {}
	var authority := _authority(record, deliveries)
	var character: String = record.character_id
	var held: Dictionary = authority.call("state", character)
	held.redesign_character.transaction_receipts.append("craft:%s:%s" % [character, "0123456789abcdef0123456789abcdef"])
	authority.call("_replace_record", character, 1, held)
	authority.call("record_personal_flag", character, "home_key_given", true)
	var backup := record.duplicate(true) # older: lacks the receipt and the flag
	var caught: Dictionary = backup.party[0].duplicate(true)
	caught.uid = "creature-%s" % "b1b2c3d4e5f60718293a4b5c6d7e8f90"
	backup.party.append(caught)
	var result: Dictionary = authority.call("rejoin_admission", character, backup, deliveries, ["home_key_given"])
	assert_eq(result.get("code"), "declaration_behind_held", "a missing held receipt refuses: %s" % str(result))
	var newer := backup.duplicate(true)
	newer.redesign_character.transaction_receipts = held.redesign_character.transaction_receipts.duplicate()
	result = authority.call("rejoin_admission", character, newer, deliveries, [])
	assert_eq(result.get("code"), "declaration_behind_held", "a missing host-recorded personal flag refuses: %s" % str(result))
	result = authority.call("rejoin_admission", character, newer, deliveries, ["home_key_given"])
	assert_eq(result.get("code"), "readmitted_portable", "receipts and flags at least the held ones: admitted")


func test_a_windowed_kind_the_declaration_compacted_is_not_behind() -> void:
	var record := _record()
	var authority := _authority(record, {})
	var character: String = record.character_id
	var windows := preload("res://scripts/creatures/receipt_windows.gd")
	var window: int = windows.window("groom")
	var held: Dictionary = authority.call("state", character)
	held.redesign_character.transaction_receipts.append("groom:oldest")
	authority.call("_replace_record", character, 1, held)
	var declared := record.duplicate(true)
	for i in window: declared.redesign_character.transaction_receipts.append("groom:newer-%d" % i)
	assert_eq(authority.call("declaration_behind", character, declared, []), "", "a full newer window compacted the old receipt")
	declared.redesign_character.transaction_receipts.pop_back()
	assert_true(str(authority.call("declaration_behind", character, declared, [])).begins_with("receipt"), "below the window it is behind")


func test_home_key_rows_and_duplicate_payouts_are_never_credited_again() -> void:
	var record := _record()
	var deliveries := {}
	var authority := _authority(record, deliveries)
	var character: String = record.character_id
	var key_row := REWARD.make_record("world-1", NS, "home_key:grant:" + character, character, "home_key", 1, "home_key_given")
	key_row.status = "accepted"
	assert_false(AUTHORITY.owner_applied_row(key_row, character), "the Home Key grant is a host CAS, never a rebuilt payout")
	var row := _row("pickup:a", "berries", 3, "accepted")
	var after := _with(record, "berries", 3)
	assert_true(authority.call("apply_owner_reward_delivery", character, authority.call("state", character), after, row.delivery_id))
	assert_false(authority.call("apply_owner_reward_delivery", character, authority.call("state", character),
		_with(after, "berries", 3), row.delivery_id), "the same payout id is refused a second time")
	var snapshot: Dictionary = authority.call("snapshot_record", character)
	authority.call("_replace_record", character, 9, record)
	authority.call("restore_record", character, snapshot)
	assert_eq(int(authority.call("revision", character)), 0, "a refused hello restores the exact held record")
	assert_true(preload("res://scripts/creatures/essence.gd")._equivalent(authority.call("state", character), after), "with its state")
