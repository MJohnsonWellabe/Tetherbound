extends "res://tests/test_case.gd"

## F31#2 / RD-20: the player carries ONE chosen relic power, chosen among
## relics they have hung. Combat reads the power only when the hang is proved
## by the host-written relic_hang receipt; the host action refuses an unhung
## choice; the Shrine screen lists only hung relics.
const AUTHORITY := preload("res://scripts/net/character_authority.gd")
const PLAYER := preload("res://autoload/player_state.gd")
const ITEMS := preload("res://autoload/item_db.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const INSTANCE := preload("res://scripts/creatures/creature_instance.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const HEARTS := preload("res://autoload/realm_heart_state.gd")
const ACTIONS := preload("res://scripts/net/foundation_actions.gd")
const PANEL := preload("res://scripts/ui/relic_power_panel.gd")
const EDIT := "0123456789abcdef0123456789abcdef"


func test_only_a_hung_relic_can_be_made_active_and_one_at_a_time() -> void:
	var hearts := HEARTS.new()
	assert_false(hearts.activate_hung("water", ["meadows"]), "Tideglass is not hung")
	assert_true(hearts.activate_hung("meadows", ["meadows"]))
	assert_true(hearts.activate_hung("water", ["meadows", "tidewake"]), "runtime id water maps to the hung tidewake relic")
	assert_eq(hearts.active_id(), "water", "the new choice replaces the old one")
	assert_eq(PANEL.choices(hearts, ["meadows", "tidewake"]), ["meadows", "water"] as Array[String], "the screen lists hung relics only")
	assert_true(PANEL.choices(hearts, []).is_empty())


func _seeded(hung: Array, receipts: Array, active: String) -> RefCounted:
	var player := PLAYER.new()
	player.configure(ITEMS.new())
	player.character_id = "owner_a"
	player.party.add(INSTANCE.from_species("terrapup", SPECIES.table().terrapup))
	player.hearts.load_data({"active_id": active})
	player.redesign_character.relics_hung = hung
	player.redesign_character.transaction_receipts = receipts
	var saved: Dictionary = player.save_data()
	saved.redesign_character = TEACHING.character_loadout_mirror(saved.party, saved.redesign_character)
	var authority := AUTHORITY.new()
	authority.bind_world("namespace_a")
	assert_true(authority.seed_admitted_character(AUTHORITY.portable_projection(saved), "owner_a").ok)
	return authority


func test_combat_sees_the_power_only_for_a_receipt_proved_hang() -> void:
	var proved := _seeded(["tidewake"], ["relic_hang:tidewake:owner_a"], "water")
	assert_eq(proved.actor_stat_state("owner_a").realm_hearts.active_id, "water", "hung by the host: the power applies")
	var claimed := _seeded(["tidewake"], [], "water")
	assert_eq(claimed.actor_stat_state("owner_a").realm_hearts.active_id, "", "an unproved claim gives no power")
	var other := _seeded(["tidewake"], ["relic_hang:tidewake:owner_a"], "meadows")
	assert_eq(other.actor_stat_state("owner_a").realm_hearts.active_id, "", "a choice whose relic is not hung gives no power")


func _current(hung: Array, receipts: Array) -> Dictionary:
	return {"character_id": "owner_a", "realm_hearts": {"active_id": ""},
		"redesign_character": {"relics_hung": hung, "transaction_receipts": receipts}}


func test_the_host_action_saves_one_choice_and_refuses_an_unhung_one() -> void:
	var context := {"shrine_power": true, "in_combat": false}
	var current := _current(["meadows"], ["relic_hang:meadows:owner_a"])
	var chosen := ACTIONS.relic_power(current, {"heart_id": "meadows", "edit_id": EDIT}, context)
	assert_true(chosen.get("ok") == true)
	assert_eq(chosen.state.realm_hearts.active_id, "meadows")
	assert_eq(ACTIONS.relic_power(current, {"heart_id": "water", "edit_id": EDIT}, context).get("code"), "relic_not_hung")
	assert_eq(ACTIONS.relic_power(_current(["meadows"], []), {"heart_id": "meadows", "edit_id": EDIT}, context).get("code"),
		"relic_not_hung", "the array alone is not proof")
	assert_eq(ACTIONS.relic_power(current, {"heart_id": "meadows", "edit_id": EDIT}, {"shrine_power": true, "in_combat": true}).get("code"),
		"actual_shrine_pedestal_required", "never mid-fight")
	assert_eq(ACTIONS.relic_power(chosen.state, {"heart_id": "meadows", "edit_id": EDIT}, context).get("code"),
		"reconcile_original_decision", "one edit applies once")


func test_a_guest_choice_waits_past_the_host_checkpoint_for_its_saved_decision() -> void:
	# Review of 0b5708c9: a guest's first reply is the host's owner-passive
	# checkpoint (unresolved). The panel and the hall's relic hang treated it
	# as final, showed its code and never heard the saved decision.
	assert_false(PANEL.reply_final({"ok": false, "resolved": false, "code": "owner_passive_checkpoint_pending"}))
	assert_false(PANEL.reply_final({"ok": false, "durable": true, "resolved": false, "code": "awaiting_saved_decision"}))
	assert_false(PANEL.reply_final({}))
	assert_true(PANEL.reply_final({"ok": true, "durable": true, "settled": true}), "the saved decision ends the wait")
	assert_true(PANEL.reply_final({"ok": false, "resolved": true, "terminal_refusal": true, "code": "relic_not_hung"}), "a resolved refusal ends it")
	assert_true(PANEL.reply_final({"ok": false, "resolved": false, "code": "owner_passive_recording_unavailable"}),
		"a refusal no decision follows still ends it (the player can try again)")
