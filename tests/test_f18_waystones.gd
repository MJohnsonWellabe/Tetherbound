extends "res://tests/test_case.gd"

## Required portable/CAS rules, using the production character codec and
## existing journal. Detached contexts are disclosed; no transport claim.
const ACTIONS := preload("res://scripts/net/foundation_actions.gd")
const DELIVERY := preload("res://scripts/net/foundation_delivery.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const PLAYER := preload("res://autoload/player_state.gd")
const WORLD := preload("res://autoload/world_state.gd")
const VIEW := preload("res://scripts/net/portal_view.gd")
const DATA := preload("res://scripts/data/redesign_data.gd")
const AUTHORITY := preload("res://scripts/net/character_authority.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
func _current() -> Dictionary:
	var player := PLAYER.new()
	player.configure(preload("res://autoload/item_db.gd").new())
	player.character_id = "stone-owner"
	return RECORD.portable_projection(player.save_data())

func _stone() -> Dictionary:
	return DATA.json("res://data/config/waystones.json").waystones[0]

func _context(revision: int = 0) -> Dictionary:
	var stone := _stone()
	return {"character_id": "stone-owner", "expected_revision": revision,
		"in_range": true, "in_combat": false, "foundation_runtime_authorized": true,
		"validated_touch": true, "source_key": "waystone:" + str(stone.id),
		"touch_id": "host-minted-touch", "realm": stone.realm_id, "world_namespace": "stone-world"}

func _intent() -> Dictionary:
	return {"waystone_id": _stone().id, "touch_id": "host-minted-touch"}

func test_touch_preserves_inventory_party_and_other_biomes_and_journal_replays_once() -> void:
	var current := _current()
	current.redesign_character.last_waystones.stormwood = "stormwood_entry"
	current.redesign_character.waystones_activated.stormwood = ["stormwood_entry"]
	var proposal := ACTIONS.stage(current, 0, "waystone_touch", _intent(), _context(), RECORD.errors)
	assert_true(proposal.get("ok") == true, str(proposal))
	if proposal.get("ok") != true: return
	assert_eq(proposal.state.inventory, current.inventory)
	assert_eq(proposal.state.party, current.party)
	assert_eq(proposal.state.redesign_character.last_waystones.stormwood, "stormwood_entry")
	assert_eq(proposal.state.redesign_character.last_waystones[_stone().biome], _stone().id)
	assert_eq(proposal.state.redesign_character.waystones_activated[_stone().biome], [_stone().id])
	proposal.character_revision = 1
	var row := DELIVERY.make_record("world-file", "stone-world", "epoch", proposal, null, RECORD.errors)
	assert_false(row.is_empty())
	if row.is_empty(): return
	var decoded: Dictionary = JSON.parse_string(JSON.stringify(row))
	assert_true(DELIVERY.valid(decoded, RECORD.errors, current.character_id, "stone-world", "world-file"))
	assert_eq(DELIVERY.owner_plan(current, decoded, RECORD.errors).state, proposal.state)
	assert_true(DELIVERY.owner_plan(proposal.state, decoded, RECORD.errors).duplicate)
	var wrong_owner := current.duplicate(true)
	wrong_owner.character_id = "another-player"
	assert_false(DELIVERY.owner_plan(wrong_owner, decoded, RECORD.errors).ok)
	var unrelated := current.duplicate(true)
	unrelated.inventory[0] = {"id": "wood", "n": 1}
	assert_false(DELIVERY.owner_plan(unrelated, decoded, RECORD.errors).ok)

func test_only_host_validated_canonical_touch_can_change_a_character() -> void:
	for field: String in ["in_range", "foundation_runtime_authorized", "validated_touch"]:
		var context := _context()
		context[field] = false
		assert_false(ACTIONS.stage(_current(), 0, "waystone_touch", _intent(), context, RECORD.errors).ok, field)
	for field: String in ["character_id", "realm", "source_key", "touch_id"]:
		var context := _context()
		context[field] = "forged"
		assert_false(ACTIONS.stage(_current(), 0, "waystone_touch", _intent(), context, RECORD.errors).ok, field)
	var intent := _intent()
	intent.position = [0, 0, 0]
	assert_false(ACTIONS.stage(_current(), 0, "waystone_touch", intent, _context(), RECORD.errors).ok)

func test_touch_failed_world_save_rolls_back_and_reloaded_decision_waits_for_owner_save() -> void:
	var before := _current()
	var authority := AUTHORITY.new()
	assert_true(authority.bind_world("stone-world"))
	assert_true(authority.seed_admitted_character(before, before.character_id).ok)
	var token := authority.stage_character_action(before.character_id, 0, "waystone_touch", _intent(), _context())
	assert_true(token.ok)
	if not token.ok: return
	assert_true(authority.finish_creature_training(token, false))
	assert_eq(authority.state(before.character_id), before)
	assert_eq(authority.revision(before.character_id), 0)
	token = authority.stage_character_action(before.character_id, 0, "waystone_touch", _intent(), _context())
	var row := DELIVERY.make_record("stone-slot", "stone-world", "stone-session", token, null, RECORD.errors)
	assert_false(row.is_empty())
	if row.is_empty(): return
	var restored: Dictionary = JSON.parse_string(JSON.stringify(row))
	var restarted := AUTHORITY.new()
	assert_true(restarted.bind_world("stone-world"))
	assert_true(restarted.seed_admitted_character(before, before.character_id).ok)
	assert_true(restarted.recover_durable_training(before.character_id, {restored.delivery_id: restored}).ok)
	assert_true(ESSENCE._equivalent(restarted.state(before.character_id), row.after))
	assert_false(restarted.acknowledge_creature_training(before.character_id, restored))
	var first := DELIVERY.owner_plan(before, restored, RECORD.errors)
	var repeat := DELIVERY.owner_plan(first.state, restored, RECORD.errors)
	assert_true(first.ok and first.requires_owner_save)
	assert_true(repeat.ok and repeat.duplicate and repeat.requires_owner_save)
	assert_eq(first.state, repeat.state)
	restored.status = "accepted"
	assert_true(restarted.acknowledge_creature_training(before.character_id, restored))
	assert_false(restarted.creature_training_is_pending(before.character_id))

func test_view_distinguishes_host_unlock_from_portable_unlock_and_names_last_stone() -> void:
	var player := PLAYER.new()
	player.configure(preload("res://autoload/item_db.gd").new())
	player.character_id = "stone-owner"
	var world := WORLD.new()
	var arch: Dictionary = DATA.json("res://data/config/portals.json").arches[1]
	world.redesign_world.portal_unlocks = ["tidewake"]
	var view := VIEW.build(player, world, arch)
	assert_true(view.open)
	assert_false(view.character_open)
	assert_true(view.world_open)
	player.redesign_character.portal_unlocks = ["tidewake"]
	world.redesign_world.portal_unlocks.clear()
	view = VIEW.build(player, world, arch)
	assert_true(view.open and view.character_open)
	assert_false(view.world_open)
	assert_eq(view.destination_label, "biome entry")
	for stone: Dictionary in DATA.json("res://data/config/waystones.json").waystones:
		if stone.biome != "tidewake": continue
		player.redesign_character.last_waystones.tidewake = stone.id
		player.redesign_character.waystones_activated.tidewake = [stone.id]
		assert_eq(VIEW.build(player, world, arch).destination_label, stone.display_name)
		break
