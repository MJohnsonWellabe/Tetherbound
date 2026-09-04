extends "res://tests/test_case.gd"

const BAND_CONTENT := preload("res://scripts/data/band_content.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const DIALOGUE := preload("res://scripts/story/dialogue_runner.gd")
const REALM_HEARTS := preload("res://autoload/realm_heart_state.gd")
const PROGRESSION := preload("res://autoload/progression_state.gd")

const WARDEN_ID := "warden_aldis"
const KEY_FLAG := "realm_key_cloudreach"
const HEART_FLAG := "realm_heart_meadows_earned"


func test_the_warden_grants_durable_realm_entitlements_not_inventory_items() -> void:
	var spec: Dictionary = TRAINERS.trainer(WARDEN_ID)
	assert_false(spec.is_empty(), "the Meadows Warden is missing")
	var flags: Array[String] = TRAINERS.reward_flags(spec)
	assert_true(flags.has(KEY_FLAG), "the Warden does not grant the Cloudreach Realm Key")
	assert_true(flags.has(HEART_FLAG), "the Warden does not grant the Heart of Meadows")
	for item: Variant in TRAINERS.reward_items(spec):
		var id := str((item as Dictionary).get("id", ""))
		assert_false(id == KEY_FLAG or id == HEART_FLAG,
			"realm entitlements must not be losable to a full or dropped satchel")


func test_the_warden_names_the_realm_rewards_automatically_after_victory() -> void:
	var spec: Dictionary = TRAINERS.trainer(WARDEN_ID)
	var conversation := str(spec.get("victory_conversation", ""))
	assert_ne(conversation, "", "the player must not have to challenge the defeated Warden again to hear the handoff")
	var runner: RefCounted = DIALOGUE.new()
	assert_true(runner.start(conversation), "the Warden's realm-reward conversation is missing")
	var words := ""
	while runner.is_active():
		words += " " + str(runner.line().get("text", ""))
		runner.advance()
	assert_true(words.contains("Realm Key"))
	assert_true(words.contains("Heart of Meadows"))
	assert_true(words.contains("Cloudreach"))


func test_the_grants_make_the_heart_and_cloudreach_gate_available() -> void:
	var progression: RefCounted = PROGRESSION.new()
	for flag: String in TRAINERS.reward_flags(TRAINERS.trainer(WARDEN_ID)):
		progression.set_flag(flag)
	var hearts: RefCounted = REALM_HEARTS.new()
	assert_true(hearts.is_earned("meadows", progression))
	assert_eq(hearts.entry_key_for_realm("cloudreach"), KEY_FLAG)
	assert_true(progression.has(hearts.entry_key_for_realm("cloudreach")))
