extends "res://tests/test_case.gd"

## Meadows -> Tidewake hand-off under the redesign rule (RD-10, RD-17,
## RD-20/RD-21; F18#2, F19#2). Rewritten from the legacy
## test_meadows_cloudreach_handoff, which asserted the world-scoped Cloudreach
## realm-key flag and the physical Storm Road crossing. The Warden now hands
## each participant their own Tidewake Portal Key as a real, protected
## inventory item; the Heart of Meadows stays a durable flag; the victory
## conversation names Tidewake; and the only way in is the Hall's Tidewake arch.

const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const DIALOGUE := preload("res://scripts/story/dialogue_runner.gd")
const REWARDS := preload("res://scripts/net/encounter_rewards.gd")
const ACTIONS := preload("res://scripts/net/foundation_actions.gd")
const STATE := preload("res://scripts/data/redesign_state.gd")
const BAGS := preload("res://scripts/world/death_satchel_rules.gd")
const BIOME_ORDER := preload("res://scripts/data/biome_order.gd")

const WARDEN_ID := "warden_aldis"
const KEY_ITEM := "tidewake_portal_key"
const HEART_FLAG := "realm_heart_meadows_earned"


func _participant(character: String) -> Dictionary:
	return {"character_id": character, "inventory": [], "redesign_character": STATE.defaults("character")}


func test_the_warden_hands_each_participant_their_own_tidewake_portal_key() -> void:
	var row := REWARDS.chapter_hand_off(WARDEN_ID, "meadows")
	assert_eq(row.get("portal_key_item"), KEY_ITEM)
	assert_eq(row.get("next_biome"), "tidewake")
	var context := {"source_key": "boss:" + WARDEN_ID, "realm": "meadows", "world_namespace": "namespace-a",
		"validated_host_outcome": "win", "encounter_id": "warden-fight",
		"participants": ["character-a", "character-b"],
		"boss_settlement_world_flags": row.get("delivery_requires_world_flags", []).duplicate()}
	var intent := {"trainer_id": WARDEN_ID, "biome": "meadows", "encounter_id": "warden-fight"}
	for character: String in ["character-a", "character-b"]:
		var staged := ACTIONS._relic(_participant(character), "boss_relic", intent, context)
		assert_true(staged.get("ok", false), "participant " + character + " receives the hand-off")
		if not staged.get("ok", false): continue
		assert_eq(BAGS.inventory_from(staged.state.inventory).count(KEY_ITEM), 1,
			"each participant holds their own Tidewake Portal Key item")
		assert_eq(staged.state.redesign_character.relics_held, ["meadows"])
	assert_eq(ACTIONS._relic(_participant("spectator"), "boss_relic", intent, context).get("code"),
		"actual_boss_participant_required", "a non-participant receives nothing")


func test_the_tidewake_key_is_a_protected_character_item_and_the_heart_stays_durable() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/items/items.json"))
	var items: Dictionary = raw.get("items", raw) if raw is Dictionary else {}
	var key: Dictionary = items.get(KEY_ITEM, {})
	assert_eq(key.get("kind"), "key")
	assert_eq(key.get("portal_biome"), "tidewake")
	assert_eq(key.get("scope"), "character")
	for flag: String in ["droppable", "sellable", "tradeable", "death_satchel"]:
		assert_eq(key.get(flag), false, KEY_ITEM + " must not be " + flag)
	var spec: Dictionary = TRAINERS.trainer(WARDEN_ID)
	assert_true(TRAINERS.reward_flags(spec).has(HEART_FLAG), "the Warden grants the Heart of Meadows")
	for item: Variant in TRAINERS.reward_items(spec):
		assert_ne(str((item as Dictionary).get("id", "")), HEART_FLAG,
			"the Heart must not be losable to a full or dropped satchel")


func test_the_warden_names_tidewake_automatically_after_victory() -> void:
	var spec: Dictionary = TRAINERS.trainer(WARDEN_ID)
	var conversation := str(spec.get("victory_conversation", ""))
	assert_ne(conversation, "", "the player must not have to challenge the defeated Warden again to hear the handoff")
	var runner: RefCounted = DIALOGUE.new()
	assert_true(runner.start(conversation), "the Warden's hand-off conversation is missing")
	var words := ""
	while runner.is_active():
		words += " " + str(runner.line().get("text", ""))
		runner.advance()
	assert_true(words.contains("Tidewake Portal Key"))
	assert_true(words.contains("Crossing Hall"))
	assert_true(words.contains("Heart of Meadows"))
	assert_false(words.contains("Cloudreach"), "RD-10: Tidewake, not Cloudreach, follows the Meadows")
	assert_false(words.contains("Realm Key"), "RD-17: no physical realm-key crossing is named")


func test_only_the_tidewake_arch_takes_the_key_and_physical_crossings_are_retired() -> void:
	var portals: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/portals.json"))
	var takers: Array[String] = []
	for arch: Dictionary in portals.arches:
		if arch.get("key_item") == KEY_ITEM: takers.append(str(arch.id))
	assert_eq(takers, ["tidewake"] as Array[String])
	assert_true(BIOME_ORDER.portal_runtime_ready(null), "shipped config runs the portal runtime")
	assert_false(BIOME_ORDER.legacy_physical_crossings(null), "RD-17: no physical crossing leads between biomes")
