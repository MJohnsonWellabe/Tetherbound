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
	assert_eq(PROGRESSION.scope_of(CLIMAX.ANSWER_WORLD_PREFIX + "0123abcd"), PROGRESSION.SCOPE_PLAYER,
		"which world an answer was given in travels with the character who gave it")


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


func test_a_strangers_acceptance_does_not_veto_a_full_refusal() -> void:
	# A character carries its personal receipt between worlds. If it joins a
	# world where every participant refused, its acceptance there is not an
	# answer to THIS freeing and must not take the herd display down.
	var world := [CLIMAX.resolution_flag(false, ME), CLIMAX.resolution_flag(false, FRIEND),
		CLIMAX.resolution_flag(true, "stranger")]
	assert_true(CLIMAX.all_refused([ME, FRIEND], ME, world),
		"only a participant's acceptance removes the herd display")


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
	# Standing at one prompt must never make the other live as well.
	var reach := sqrt(radius * radius - height * height)
	assert_true(float(choice.get("min_separation", 0.0)) > 2.0 * reach,
		"the two prompts can both be live from one spot; a press there answers whichever wins")
	for key: String in ["accept_offset", "refuse_offset", "near_offset"]:
		var offset := float(choice.get(key, 0.0))
		assert_true(sqrt(offset * offset + height * height) > radius,
			"'%s' puts its prompt in reach of where the player already stands" % key)


# --- coordinator review of #221 (8edc5c4d) ------------------------------------

func test_a_guest_joining_a_solo_freed_world_is_offered_nothing() -> void:
	# The host freed the Stag alone, so no fight journal exists. A guest who
	# never fought joins: the empty journal is not proof it fought.
	assert_false(CLIMAX.may_receive(FRIEND, [], false, true),
		"a client reading an empty journal is not the solo fighter")
	assert_true(CLIMAX.may_receive(ME, [], false, false),
		"the peer that holds the world still gets its own solo offer")


func test_an_empty_journal_before_the_snapshot_syncs_offers_a_client_nothing_yet() -> void:
	# Before the host's snapshot lands, a real participant's client reads an
	# empty journal. It must wait, not be offered or refused; once the journal
	# arrives with its id it is offered.
	assert_false(CLIMAX.may_receive(FRIEND, [], false, true))
	assert_true(CLIMAX.may_receive(FRIEND, [ME, FRIEND], false, true),
		"once the journal names it, the client is offered its own")


func test_migration_never_runs_for_a_client_or_in_company() -> void:
	# settled, live, client, multi_peer, participants_empty, any_receipt
	assert_true(CLIMAX.should_migrate(true, false, false, false, true, false),
		"a settled pre-F05 solo world migrates once")
	assert_false(CLIMAX.should_migrate(true, false, true, false, true, false),
		"a joining guest (a client) never migrates: it was never offered anything")
	assert_false(CLIMAX.should_migrate(true, false, false, true, true, false),
		"with other peers present nobody migrates")
	assert_false(CLIMAX.should_migrate(true, false, false, false, false, false),
		"a world with a fight journal is not a solo world")
	assert_false(CLIMAX.should_migrate(true, true, false, false, true, false),
		"a world with a live F05 answer needs no migration")
	assert_false(CLIMAX.should_migrate(true, false, false, false, true, true),
		"a world that already holds a receipt is not migrated again")
	assert_false(CLIMAX.should_migrate(false, false, false, false, true, false),
		"an unsettled world has nothing to migrate")


func test_an_empty_journal_herd_display_is_the_same_for_every_peer() -> void:
	var world := [CLIMAX.resolution_flag(false, ME)]
	assert_eq(CLIMAX.all_refused([], ME, world), CLIMAX.all_refused([], FRIEND, world),
		"host and a joining guest read one world the same way")
	assert_true(CLIMAX.all_refused([], FRIEND, world),
		"the only recorded answer is a refusal: full refusal, whoever asks")


# --- the participant journal (found by the two-peer witness) -------------------

func test_the_journal_names_every_warden_fighter_pending_or_accepted() -> void:
	var journal := {
		"a": {"source": "trainer:warden_aldis:coins", "status": "accepted", "character_id": ME},
		"b": {"source": "trainer:warden_aldis:item:revive", "status": "accepted", "character_id": ME},
		"c": {"source": "trainer:warden_aldis:item:revive", "status": "pending", "character_id": FRIEND},
		"d": {"source": "trainer:stronghold_elite:coins", "status": "accepted", "character_id": "stranger"},
		"e": {"source": "trainer:warden_aldis:coins", "status": "accepted", "character_id": ""},
	}
	var fighters: Array = CLIMAX.participants_from(journal, "warden_aldis")
	fighters.sort()
	var expected := [ME, FRIEND]
	expected.sort()
	assert_eq(fighters, expected,
		"both fighters, once each; a pending payout still proves the fight; other trainers and blank ids never count")


func test_the_climax_reads_the_journal_from_the_world_not_a_missing_method() -> void:
	# The reader used to call `world_snapshot()` on WorldState, which has none,
	# so the list was always empty. Pin that the journal lives where it reads.
	var world_state: Script = load("res://autoload/world_state.gd")
	var world: Object = world_state.new()
	assert_true("reward_deliveries" in world, "WorldState holds the reward journal the climax reads")
	assert_false(world.has_method("world_snapshot"),
		"WorldState has no world_snapshot(); reading the journal through it returns nothing")


## Coordinator review of 710fbcda, item 1 (BLOCKING). A Warden fight a CLIENT
## starts journals nobody, so in company an empty journal cannot tell the
## fighter from the bystander. It offers nobody; alone, it is still the solo
## freeing and the one player there is offered.
func test_an_empty_journal_in_company_offers_nobody() -> void:
	assert_false(CLIMAX.may_receive(ME, [], false, false, true),
		"a host in company with an empty journal is not handed the creature")
	assert_false(CLIMAX.may_receive(FRIEND, [], false, true, true),
		"nor is the guest (who may have fought) handed it on nobody's say-so")
	assert_true(CLIMAX.may_receive(ME, [], false, false, false),
		"alone, an empty journal is the solo freeing and the player is offered")
	assert_true(CLIMAX.may_receive(FRIEND, [ME, FRIEND], false, true, true),
		"a journaled participant in company is offered as before")
	assert_false(CLIMAX.may_receive("character-cccc", [ME, FRIEND], false, false, true),
		"a non-participant in company is still offered nothing")


## Item 2 (MAJOR). An answer's world receipt belongs only to the world it was
## given in; the once-per-character rule itself still travels.
func test_an_answer_is_only_recorded_in_the_world_it_was_given_in() -> void:
	assert_true(CLIMAX.answered_in_this_world([], "world-b", true),
		"an answer GIVEN here this session is this world's (a settle here is not an answer: the caller passes _answered_here, which only _record_resolution sets)")
	assert_true(CLIMAX.answered_in_this_world(["world-a"], "world-a", false),
		"a reconnect to the world the answer was given in resubmits its receipt")
	assert_false(CLIMAX.answered_in_this_world(["world-a"], "world-b", false),
		"world A's answer is never written into world B")
	assert_false(CLIMAX.answered_in_this_world([], "world-b", false),
		"an answer with no world tag is written into no world")
	assert_false(CLIMAX.answered_in_this_world(["world-a"], "", false),
		"a world with no identity yet records nothing carried in")
	assert_false(CLIMAX.may_receive(ME, [ME], true, false, true),
		"and the character who answered in world A is still not offered again in B")


## Re-review B2: the flag the reconcile passes must be set by answering, never
## by settling. Asserted on the source, because the regression was exactly a
## settle setting the "answered" flag the world check reads.
func test_settling_is_never_mistaken_for_answering_here() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/stronghold_climax.gd")
	var settle := source.substr(source.find("func _settle() -> void:"))
	settle = settle.substr(0, settle.find("\nfunc ", 10))
	assert_false(settle.contains("_answered_here"), "_settle() must not mark this world as answered")
	var record := source.substr(source.find("func _record_resolution(accepted: bool) -> void:"))
	record = record.substr(0, record.find("\nfunc ", 10))
	assert_true(record.contains("_answered_here = true"), "only answering marks this world as answered")


## Re-review: the caged creature is only removed once EVERY recorded
## participant has answered, not at the first settle.
func test_the_creature_leaves_only_when_every_participant_has_answered() -> void:
	var one := [CLIMAX.resolution_flag(false, ME)]
	assert_false(CLIMAX.all_answered([ME, FRIEND], one), "FRIEND is still mid-offer")
	one.append(CLIMAX.resolution_flag(true, FRIEND))
	assert_true(CLIMAX.all_answered([ME, FRIEND], one), "both answered")
	assert_true(CLIMAX.all_answered([], []), "a solo world's one answer is its settle")
