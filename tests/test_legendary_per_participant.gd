extends "res://tests/test_case.gd"

# Owner decision, superseding CLAUDE.md's former "one durable recipient per
# world offer": **every participant in the fight that freed the legendary
# receives their own offer, and each participant who accepts keeps their own.**
# A non-participant receives nothing, and no character is offered the same
# freeing twice.
#
# Before this, `stronghold_climax.gd::_hand_over_the_legendary()` added the
# creature to the LOCAL party unconditionally, with no session, host, ledger or
# authority seam anywhere in the file, while the climax is built on BOTH peers
# (measured, identical geometry on host and guest, in
# `ralph/reports/MEADOWS-PAYOFFS/hall-coop`). See that lane's
# LEGENDARY-RECIPIENT.md for the finding this rule answers.

const CLIMAX := preload("res://scripts/world/stronghold_climax.gd")

const ME := "character-aaaa"
const FRIEND := "character-bbbb"
const STRANGER := "character-cccc"


func test_a_participant_receives_their_own_offer() -> void:
	assert_true(CLIMAX.may_receive(ME, [ME, FRIEND], false),
		"a character who fought the Warden receives their own offer")


func test_every_participant_receives_one_not_just_the_first() -> void:
	# The whole point of the amended rule: the second participant is not
	# refused because somebody else already took it.
	assert_true(CLIMAX.may_receive(ME, [ME, FRIEND], false))
	assert_true(CLIMAX.may_receive(FRIEND, [ME, FRIEND], false),
		"the second participant is not refused because the first already has one")


func test_a_non_participant_receives_nothing() -> void:
	assert_false(CLIMAX.may_receive(STRANGER, [ME, FRIEND], false),
		"a peer who did not fight the Warden gets no offer, however close it stands")


func test_no_character_is_offered_the_same_freeing_twice() -> void:
	assert_false(CLIMAX.may_receive(ME, [ME, FRIEND], true),
		"a character that already resolved this freeing is never offered it again")


func test_a_solo_freeing_still_grants() -> void:
	# A solo run publishes no shared reward receipts at all, so the participant
	# set is empty. Refusing on an empty set would strand every solo ending,
	# which is the regression this guards.
	assert_true(CLIMAX.may_receive(ME, [], false),
		"a solo player still receives the legendary they just freed")
	assert_true(CLIMAX.may_receive("", [], false),
		"a save predating stable character ids still resolves its solo ending")


func test_a_solo_freeing_is_still_only_offered_once() -> void:
	assert_false(CLIMAX.may_receive(ME, [], true),
		"idempotency holds solo as well as in co-op")


func test_an_unknown_character_is_refused_when_others_did_fight() -> void:
	# The dangerous direction. An empty id must not match a populated
	# participant list by accident, or every peer would qualify.
	assert_false(CLIMAX.may_receive("", [ME, FRIEND], false),
		"an unidentified character cannot claim a place in a known participant set")
