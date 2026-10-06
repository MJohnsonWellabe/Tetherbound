extends "res://tests/test_case.gd"

## F18: after a guest spends a portal key, the host's admitted record carries
## the same settled escrow row the owner wrote, so the next full-record owner
## action (a homecoming acknowledgement) does not conflict on its baseline.

const AUTHORITY := preload("res://scripts/net/character_authority.gd")
const DELIVERY := preload("res://scripts/net/portal_delivery.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const PLAYER := preload("res://autoload/player_state.gd")
const ITEMS := preload("res://autoload/item_db.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const INSTANCE := preload("res://scripts/creatures/creature_instance.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const INSTANCE_ID := "f18markerworld"


func _player() -> RefCounted:
	var player := PLAYER.new()
	player.configure(ITEMS.new())
	player.character_id = "owner_a"
	player.party.add(INSTANCE.from_species("terrapup", SPECIES.table().terrapup))
	player.inventory.set_slot(3, {"id": "fifth_portal_key", "n": 1})
	return player


func _portable(player: RefCounted) -> Dictionary:
	var saved: Dictionary = player.save_data()
	saved.redesign_character = TEACHING.character_loadout_mirror(saved.party, saved.redesign_character)
	return AUTHORITY.portable_projection(saved)


func _row(status: String) -> Dictionary:
	var id := DELIVERY.receipt(INSTANCE_ID, "biome5", "owner_a")
	return {"version": DELIVERY.VERSION, "kind": DELIVERY.KIND, "status": status, "biome": "biome5",
		"item": "fifth_portal_key", "character_id": "owner_a", "world_id": "slot-0",
		"world_instance_id": INSTANCE_ID, "receipt": id, "key_slot": 3}


## The host's debit, then the owner's own settlement of the same journal row.
func _spent() -> Dictionary:
	var player := _player()
	var authority = AUTHORITY.new()
	assert_true(authority.bind_world(INSTANCE_ID))
	assert_true(authority.seed_admitted_character(_portable(player), "owner_a").ok)
	var receipt: String = _row("pending").receipt
	var stage: Dictionary = authority.stage_portal_debit("owner_a", "biome5", receipt)
	assert_true(stage.get("ok") == true and stage.get("duplicate") != true, "the host debits the admitted key")
	assert_true(authority.commit_portal_debit(stage))
	assert_true(authority.finish_portal_debit(stage, true))
	# portal_delivery.settle_owner: key gone, receipt kept, settled escrow row.
	player.inventory.set_slot(3, null)
	player.redesign_character.transaction_receipts.append(receipt)
	var settled := _row("settled")
	player.satchel_escrow[receipt] = settled
	return {"authority": authority, "owner": _portable(player)}


func test_accepted_spend_mirrors_the_owner_settled_row() -> void:
	var spent := _spent()
	var authority = spent.authority
	var owner: Dictionary = spent.owner
	assert_false(ESSENCE.owner_matches_after(owner, authority.state("owner_a")),
		"without the marker the owner's record and the host's differ (the F20 stall)")
	var before_revision: int = authority.revision("owner_a")
	assert_true(authority.promote_settled_portal_marker("owner_a", _row("accepted")))
	assert_true(ESSENCE.owner_matches_after(owner, authority.state("owner_a")),
		"the host's admitted record now matches the owner's own settled record")
	assert_eq(authority.revision("owner_a"), before_revision, "receipt metadata at the same revision")
	assert_true(authority.promote_settled_portal_marker("owner_a", _row("accepted")), "a reconcile repeat is idempotent")
	assert_true(authority.character_fifth_stirred("owner_a"), "the fifth stir reads from the same settled row")


func test_only_an_accepted_debited_row_is_mirrored() -> void:
	var player := _player()
	var authority = AUTHORITY.new()
	assert_true(authority.bind_world(INSTANCE_ID))
	assert_true(authority.seed_admitted_character(_portable(player), "owner_a").ok)
	var before: Dictionary = authority.state("owner_a")
	assert_false(authority.promote_settled_portal_marker("owner_a", _row("accepted")), "no debit, no marker")
	assert_true(AUTHORITY.equivalent(authority.state("owner_a"), before))
	var spent := _spent()
	authority = spent.authority
	before = authority.state("owner_a")
	assert_false(authority.promote_settled_portal_marker("owner_a", _row("pending")), "a pending row is not settled yet")
	assert_false(authority.promote_settled_portal_marker("owner_b", _row("accepted")), "another character's row")
	var foreign := _row("accepted")
	foreign.world_instance_id = "otherworld"
	foreign.receipt = DELIVERY.receipt("otherworld", "biome5", "owner_a")
	assert_false(authority.promote_settled_portal_marker("owner_a", foreign), "another world's row")
	assert_true(AUTHORITY.equivalent(authority.state("owner_a"), before), "refusals leave the record untouched")
