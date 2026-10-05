extends "res://tests/test_case.gd"

## Rejoin admission (coordinator 2026-10-05; F01 op10/op11, F18 render
## 37365638014) on the real CharacterAuthority:
## - deliver-then-leave: the held record misses host-accepted payouts whose
##   owner-passive inputs never replayed; the host rebuilds them from its OWN
##   world rows (amounts never read from the declaration) and admits;
## - an already-absorbed payout is never applied a second time;
## - an offline portable change (a solo catch, an older backup) never replaces
##   the held record (owner ruling STATE §0: the host world's held record wins
##   inside it); this world's own accepted payouts are still folded into it.
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
	# their owner-passive inputs replayed. (A pending row folds too: see
	# test_a_row_lands_whole_or_not_at_all_and_pending_rows_fold_too.)
	var first := _row("pickup:a", "berries", 3, "accepted")
	var second := _row("pickup:b", "fiber", 2, "accepted")
	deliveries[first.delivery_id] = first
	deliveries[second.delivery_id] = second
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
	# second time: that is an offline change, and the held record wins.
	var doubled := _with(_with(declared, "berries", 3), "fiber", 2)
	assert_eq((authority.call("rejoin_admission", character, doubled, deliveries) as Dictionary).get("code"), "held_wins",
		"absorbed rows are never counted twice, even after a record rewrite")
	assert_true(preload("res://scripts/creatures/essence.gd")._equivalent(core._core(authority.call("state", character)), core._core(declared)),
		"and the held record is unchanged by the offline amounts")


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


func test_an_offline_catch_never_replaces_the_held_record() -> void:
	var record := _record()
	var deliveries := {}
	var authority := _authority(record, deliveries)
	var character: String = record.character_id
	var declared := record.duplicate(true)
	var caught: Dictionary = declared.party[0].duplicate(true)
	caught.uid = "creature-%s" % "a1b2c3d4e5f60718293a4b5c6d7e8f90"
	declared.party.append(caught)
	var result: Dictionary = authority.call("rejoin_admission", character, declared, deliveries)
	assert_eq(result.get("code"), "held_wins", "the held record wins inside this world: %s" % str(result))
	assert_true(str(result.get("detail", "")).contains("party"), "the difference is named (%s)" % str(result.get("detail", "")))
	assert_eq((authority.call("state", character) as Dictionary).party.size(), 1, "the offline catch is not adopted")
	assert_eq(int(authority.call("revision", character)), 0, "the held revision is unchanged")


func test_accepted_payouts_fold_into_the_held_record_even_with_an_offline_change() -> void:
	# Deliver-then-leave AND an offline catch: the host's own accepted payout
	# still lands in the held record (never twice); the catch does not.
	var record := _record()
	var deliveries := {}
	var authority := _authority(record, deliveries)
	var character: String = record.character_id
	var row := _row("pickup:a", "berries", 3, "accepted")
	deliveries[row.delivery_id] = row
	var declared := _with(record, "berries", 3)
	var caught: Dictionary = declared.party[0].duplicate(true)
	caught.uid = "creature-%s" % "c1b2c3d4e5f60718293a4b5c6d7e8f90"
	declared.party.append(caught)
	var result: Dictionary = authority.call("rejoin_admission", character, declared, deliveries)
	assert_eq(result.get("code"), "held_wins", "the catch keeps the held record: %s" % str(result))
	assert_eq(result.get("applied", []), [row.delivery_id], "the accepted payout was folded in")
	var held: Dictionary = authority.call("state", character)
	assert_eq(held.party.size(), 1, "without the offline catch")
	var bag := preload("res://scripts/world/death_satchel_rules.gd").inventory_from(held.inventory)
	assert_eq(int(bag.call("count", "berries")), 3, "with the payout")
	assert_eq((authority.call("rejoin_admission", character, declared, deliveries) as Dictionary).get("applied", []), [],
		"rejoining again folds nothing a second time")
	assert_eq(int(preload("res://scripts/world/death_satchel_rules.gd").inventory_from((authority.call("state", character) as Dictionary).inventory).call("count", "berries")), 3,
		"still exactly one payout")


func test_an_older_backup_never_replaces_the_held_record() -> void:
	var record := _record()
	var authority := _authority(record, {})
	var character: String = record.character_id
	var held: Dictionary = authority.call("state", character)
	held.redesign_character.transaction_receipts.append("craft:%s:%s" % [character, "0123456789abcdef0123456789abcdef"])
	authority.call("_replace_record", character, 1, held)
	var result: Dictionary = authority.call("rejoin_admission", character, record.duplicate(true), {})
	assert_eq(result.get("code"), "held_wins", "a backup lacking a held receipt keeps the held record: %s" % str(result))
	assert_eq((authority.call("state", character) as Dictionary).redesign_character.transaction_receipts.size(),
		held.redesign_character.transaction_receipts.size(), "the held receipt stays")


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
	authority.get("_vitals_pending")[character] = {"uid": "x"}
	authority.call("restore_record", character, snapshot)
	assert_false((authority.get("_vitals_pending") as Dictionary).has(character), "the vitals map is restored with it")
	assert_eq(int(authority.call("revision", character)), 0, "a refused hello restores the exact held record")
	assert_true(preload("res://scripts/creatures/essence.gd")._equivalent(authority.call("state", character), after), "with its state")


func test_a_row_lands_whole_or_not_at_all_and_pending_rows_fold_too() -> void:
	# Review M1: a multi-stack row that only partly fits never leaves a partial
	# stack in the held record (it would be paid again on the next rejoin).
	# Review M3: a pending row (the owner's ACK lost to the disconnect) is
	# host-authored, so it folds as well and is handed to the owner to settle.
	var record := _record()
	var deliveries := {}
	var authority := _authority(record, deliveries)
	var character: String = record.character_id
	var held: Dictionary = authority.call("state", character)
	# Every slot full but one, with full stacks (stone), so of a two-stack row
	# only the first stack fits.
	var bag := preload("res://scripts/world/death_satchel_rules.gd").inventory_from([])
	var stone := int(preload("res://scripts/world/death_satchel_rules.gd").db().call("stack_size", "stone"))
	for slot in int(bag.call("slot_count")) - 1: bag.call("set_slot", slot, {"id": "stone", "n": stone})
	held.inventory = preload("res://scripts/world/death_satchel_rules.gd").slots(bag)
	authority.call("_replace_record", character, 0, held)
	var two_stacks := REWARD.make_record("world-1", NS, "gather:big", "character-rejoin-owner", "", 0)
	two_stacks.status = "accepted"
	two_stacks.stacks = [{"id": "potion_small", "n": 1}, {"id": "orb_basic", "n": 1}]
	deliveries[two_stacks.delivery_id] = two_stacks
	var pending := _row("pickup:p", "berries", 1, "pending")
	deliveries[pending.delivery_id] = pending
	var declared := record.duplicate(true)
	declared.party[0].level = int(declared.party[0].level) + 1
	var result: Dictionary = authority.call("rejoin_admission", character, declared, deliveries)
	var after_bag := preload("res://scripts/world/death_satchel_rules.gd").inventory_from((authority.call("state", character) as Dictionary).inventory)
	assert_false((result.get("applied", []) as Array).has(two_stacks.delivery_id), "the half-fitting row is not folded: %s" % str(result))
	assert_eq(int(after_bag.call("count", "potion_small")) + int(after_bag.call("count", "orb_basic")), 0, "and no partial stack of it is held")
	assert_true((result.get("applied", []) as Array).has(pending.delivery_id), "the pending row folded")
	# Re-review H1: the rows to settle are computed from durable state, so a
	# record rewrite (recover_durable_vitals in the real hello) and a second
	# rejoin still hand them to the owner, until its ACK makes them accepted.
	var ids := func() -> Array: return (authority.call("folded_pending", character, deliveries) as Array).map(func(r: Dictionary) -> String: return r.delivery_id)
	assert_eq(ids.call(), [pending.delivery_id], "folded_pending names the pending row the held record holds")
	authority.call("_replace_record", character, 1, authority.call("state", character))
	assert_eq(ids.call(), [pending.delivery_id], "after a record rewrite")
	authority.call("rejoin_admission", character, declared, deliveries)
	assert_eq(ids.call(), [pending.delivery_id], "and on a second rejoin that folds nothing new")
	deliveries[pending.delivery_id].status = "accepted"
	assert_eq(ids.call(), [], "the owner's ACK (accepted) ends it")
