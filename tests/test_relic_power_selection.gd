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


func test_the_owner_installs_a_saved_relic_power_choice() -> void:
	# F18 diagnostic render 37394711198: a guest's relic_power row stalled at
	# owner_action_install_conflict (live == before; the only differences from
	# after were its receipt and realm_hearts.active_id). The owner installer
	# wrote inventory, character and equipment but never the active heart, so
	# no relic power choice could ever settle on its owner.
	const TM := preload("res://tests/test_tm_teach_transaction.gd")
	const OWNER := preload("res://scripts/net/character_action_owner.gd")
	const RECORD := preload("res://scripts/net/character_record_rules.gd")
	const DELIVERY := preload("res://scripts/net/foundation_delivery.gd")
	var directory := "user://test_relic_owner_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	var player := PLAYER.new()
	player.configure(ITEMS.new())
	player.character_id = "owner_a"
	player.party.add(INSTANCE.from_species("terrapup", SPECIES.table().terrapup))
	player.redesign_character.relics_hung = ["meadows"]
	player.redesign_character.transaction_receipts = ["relic_hang:meadows:owner_a"]
	var game: Node = TM.OwnerGameFixture.new()
	game.local = player
	game.world = preload("res://autoload/world_state.gd").new()
	game.world.world_id = "relic-slot"
	game.world.reward_delivery_namespace = TM.NAMESPACE
	var session: Node = TM.OwnerSessionFixture.new()
	session.fixture = game
	game.session = session
	var writer: RefCounted = TM.BoolWriterFixture.new()
	writer.store = preload("res://scripts/save/character_save.gd").new(directory)
	game.save_system = writer
	var saved: Dictionary = player.save_data()
	saved.redesign_character = TEACHING.character_loadout_mirror(saved.party, saved.redesign_character)
	player.redesign_character = saved.redesign_character
	var before := RECORD.portable_projection(player.save_data())
	var staged := ACTIONS.stage(before, 0, "relic_power", {"heart_id": "meadows", "edit_id": EDIT},
		{"character_id": "owner_a", "expected_revision": 0, "in_range": true, "in_combat": false,
			"shrine_power": true, "realm": "meadows", "source_key": "shrine_power", "foundation_runtime_authorized": true}, RECORD.errors)
	assert_true(staged.get("ok") == true, str(staged))
	if staged.get("ok") == true:
		staged.character_revision = 1
		var row := DELIVERY.make_record("relic-slot", TM.NAMESPACE, "tm-session", staged, null, RECORD.errors)
		assert_false(row.is_empty())
		if not row.is_empty():
			game.world.reward_deliveries[row.delivery_id] = row.duplicate(true)
			var applied := OWNER.apply_owner(game, row)
			assert_true(applied.get("ok") == true and applied.get("saved") == true, "the owner installs and saves the choice: %s" % str(applied))
			assert_eq(player.hearts.active_id(), "meadows", "the chosen power is active on the owner")
			assert_true(preload("res://scripts/creatures/essence.gd")._equivalent(RECORD.portable_projection(player.save_data()), row.after))
	session.free()
	game.free()
	preload("res://tests/helpers/split_save_fixture.gd").wipe(directory)
