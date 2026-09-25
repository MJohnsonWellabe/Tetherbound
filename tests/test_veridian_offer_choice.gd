extends "res://tests/test_case.gd"

# F05 (ROADMAP §3) / ACCEPTANCE §6.1 F05 and M4: the Veridian offer is a
# per-character choice. With room on the belt AND at five a character may accept
# or refuse; either answer is a durable personal receipt, so a reload or rejoin
# never offers the same freeing twice; and each answer is also a world receipt
# keyed by stable character id, which is how the world knows every eligible
# participant refused (WORLD §3.2's herd display) without reading anybody's
# private save.
#
# The node's own stage machine needs a live world and runs in
# `tests/smoke_veridian_offer_choice.gd`. What is here is the rule, pure.

const CLIMAX := preload("res://scripts/world/stronghold_climax.gd")
const PROGRESSION := preload("res://autoload/progression_state.gd")
const CONFIG_PATH := "res://data/config/stronghold_climax.json"

const ME := "character-aaaa"
const FRIEND := "character-bbbb"


func _config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	return parsed as Dictionary if parsed is Dictionary else {}


func test_a_refusal_is_a_resolution_and_is_never_offered_again() -> void:
	# `may_receive`'s third input is "this character has answered", and the
	# climax now answers it from EITHER receipt. A refusal that left the input
	# false would re-offer the creature on the next load -- the defect this
	# work order closes.
	assert_false(CLIMAX.may_receive(ME, [], true), "a solo refuser is not offered again")
	assert_false(CLIMAX.may_receive(ME, [ME, FRIEND], true), "a co-op refuser is not offered again")
	assert_true(CLIMAX.may_receive(FRIEND, [ME, FRIEND], false),
		"one participant's refusal does not answer for the other")


func test_the_refusal_receipt_is_personal_and_the_resolution_receipt_is_world() -> void:
	var flags: Dictionary = _config().get("flags", {})
	var refused := str(flags.get("legendary_refused", ""))
	assert_eq(refused, "legendary_refused", "the climax config names the personal refusal receipt")
	PROGRESSION.reload_scopes()
	assert_eq(PROGRESSION.scope_of(refused), PROGRESSION.SCOPE_PLAYER,
		"a refusal belongs to the character who made it, not to the world")
	assert_eq(PROGRESSION.scope_of(str(flags.get("legendary_joined", ""))), PROGRESSION.SCOPE_PLAYER,
		"an acceptance belongs to the character who made it")
	for accepted: bool in [true, false]:
		var receipt := CLIMAX.resolution_flag(accepted, ME)
		assert_eq(PROGRESSION.scope_of(receipt), PROGRESSION.SCOPE_WORLD,
			"'%s' is a world receipt every peer mirrors" % receipt)


func test_resolution_receipts_name_the_character_and_the_answer() -> void:
	assert_eq(CLIMAX.resolution_flag(true, ME), "legendary_resolution:accepted:%s" % ME)
	assert_eq(CLIMAX.resolution_flag(false, FRIEND), "legendary_resolution:refused:%s" % FRIEND)
	assert_ne(CLIMAX.resolution_flag(true, ME), CLIMAX.resolution_flag(false, ME),
		"the two answers are distinguishable after the fact")
	assert_eq(CLIMAX.resolution_flag(false, ""), "legendary_resolution:refused:solo",
		"a save predating stable ids still records one answer")


func test_solo_refusal_is_a_full_refusal() -> void:
	var world := [CLIMAX.resolution_flag(false, ME)]
	assert_true(CLIMAX.all_refused([], ME, world), "the only player refused; the herd display is owed")
	assert_false(CLIMAX.all_refused([], ME, []), "an unanswered solo offer is not a refusal")


func test_solo_acceptance_is_never_a_full_refusal() -> void:
	assert_false(CLIMAX.all_refused([], ME, [CLIMAX.resolution_flag(true, ME)]))


func test_mixed_co_op_answers_are_not_a_full_refusal() -> void:
	var world := [CLIMAX.resolution_flag(false, ME), CLIMAX.resolution_flag(true, FRIEND)]
	assert_false(CLIMAX.all_refused([ME, FRIEND], ME, world),
		"any acceptance means the herd display is absent")


func test_every_participant_must_answer_before_a_full_refusal() -> void:
	var world := [CLIMAX.resolution_flag(false, ME)]
	assert_false(CLIMAX.all_refused([ME, FRIEND], ME, world),
		"a participant who disconnected before answering has not refused yet")
	world.append(CLIMAX.resolution_flag(false, FRIEND))
	assert_true(CLIMAX.all_refused([ME, FRIEND], ME, world),
		"both participants refused; the herd display is owed")


func test_a_non_participant_answer_does_not_count() -> void:
	var world := [CLIMAX.resolution_flag(false, ME), CLIMAX.resolution_flag(false, "stranger")]
	assert_false(CLIMAX.all_refused([ME, FRIEND], ME, world),
		"a stranger's receipt cannot stand in for a participant's")


func test_the_choice_announces_both_answers_as_final_and_neither_prompt_starts_live() -> void:
	var choice: Dictionary = _config().get("choice", {})
	assert_false(choice.is_empty(), "the climax config has no accept/refuse choice")
	assert_true(str(choice.get("announce", "")).contains("final"),
		"the character hears that the answer is irreversible before either prompt is pressed")
	assert_ne(str(choice.get("accept_label", "")), "", "no accept prompt label")
	assert_ne(str(choice.get("refuse_label", "")), "", "no refuse prompt label")
	var radius := float(choice.get("radius", 0.0))
	var height := float(choice.get("height", 0.0))
	assert_true(radius > 0.0, "the prompts need a radius")
	# The radius is measured in 3D from the player's feet to the prompt, which
	# stands `height` up. Measured defect: at radius 1.0 / height 1.1 neither
	# prompt could be reached from anywhere, so the choice was unanswerable.
	assert_true(height < radius * 0.75,
		"a prompt %.2f m up with a %.2f m radius leaves no ground to press it from" % [height, radius])
	# Neither prompt may be live where the player stands when the offer lands,
	# or a press meant for the dialogue answers an irreversible question.
	for key: String in ["accept_offset", "refuse_offset"]:
		var offset := float(choice.get(key, 0.0))
		assert_true(sqrt(offset * offset + height * height) > radius,
			"'%s' puts its prompt in reach of where the player already stands" % key)
