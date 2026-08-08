extends "res://tests/test_case.gd"

## The seam between the opening sequence and the party it does not own.
##
## ## What these tests are for, and what they failed to be
##
## The seam has two paths: the real `Game.party` when the autoload is running,
## and a local list when it is not. This file used to exercise the fallback path
## and NOTHING ELSE, and closed with:
##
##     var answer: bool = SEAM.has_game_state()
##     assert_true(answer or not answer)
##
## which is true for every possible value of `answer`. It asserted nothing. Under
## it, the seam looked up `/root/GameState` (the autoload is `Game`) and called
## `add_pal()` / `party()` / `party_is_full()` (the real API is `Game.party.add()`
## / `.members()` / `.is_full()`), so the real path was unreachable — the seam ran
## a phantom party beside the real one and every test here passed.
##
## So the tests below come in two halves, and the second half is the point:
##
##   - **fallback** — no `Game` in the tree, which is the unit runner's normal
##     state, because `--script` starts no autoloads.
##   - **the real party** — a `Game` node holding the genuine `autoload/party.gd`
##     is put in the tree, and the seam must BIND to it. Falling back with a
##     party present is now a failure, not an invisible default, and the API
##     translation is checked against the real class rather than against a mock
##     that would happily agree with whatever the seam guessed.
##
## The stand-in is a plain Node named `Game` carrying a real `party`, which is
## exactly what the autoload presents. Using the autoload script itself would
## drag in the pause menu, the settings file and a scene load, none of which this
## file is about — and the party it holds is the genuine `autoload/party.gd`, so
## the API translation is checked against the real class rather than against a
## mock that would agree with whatever the seam guessed.
##
## It is hung off a detached root handed to `SEAM.set_root_for_tests` rather than
## off the live tree, because `Engine.get_main_loop()` is null for the whole life
## of `tests/run_tests.gd` — see `_root_override` in the seam. The lookup being
## tested is unaffected: the seam still has to find a child named exactly `Game`,
## which is the half that was wrong.
##
## `tests/smoke_opening.gd` covers the same ground against the ACTUAL autoload in
## a booted scene. Both are worth having: this one runs in milliseconds and can
## never be skipped, that one proves project.godot really registers the name this
## file assumes.

const SEAM := preload("res://scripts/story/party_seam.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")
const PARTY := preload("res://autoload/party.gd")


## Stands where the `Game` autoload stands, holding the real party class.
class GameStandIn extends Node:
	var party: RefCounted = null


## Stands in for the scene tree's root. Detached: nothing here is in the live
## tree, and nothing here survives a test.
var _fake_root: Node = null
var _stand_in: GameStandIn = null


func before_each() -> void:
	SEAM.reset()
	_remove_the_party()


func after_each() -> void:
	SEAM.reset()
	_remove_the_party()


# --- the fallback path ------------------------------------------------------
#
# No party in the tree. This is what the opening plays on inside the unit
# runner, and what it played on for real while the seam was broken.


func test_a_chosen_pal_joins_the_party() -> void:
	var pal: RefCounted = SPECIES.spawn("terrapup")
	assert_true(SEAM.add(pal, "Biscuit"))
	assert_eq(SEAM.size(), 1)
	assert_eq(SEAM.party()[0], pal)


## The name is the whole point of the naming beat, and it has to be visible
## through `label()`, which is what the HUD, the nameplates and the party screen
## all read.
##
## It must NOT be written over `display_name`. That is the species name, and
## `tests/test_pal_nickname.gd` requires it to survive being nicknamed over: a
## party screen has to be able to tell a Terrapup nobody renamed from one the
## player deliberately named "Terrapup". The seam used to overwrite it, which is
## the same wrong guess that produced the phantom party — written before
## `nickname` existed and never revisited once it did.
func test_naming_a_pal_changes_the_name_the_game_shows() -> void:
	var pal: RefCounted = SPECIES.spawn("terrapup")
	assert_eq(pal.label(), "Terrapup", "before naming, it is its species")
	SEAM.add(pal, "Biscuit")
	assert_eq(pal.label(), "Biscuit", "the name the player typed is the name shown")
	assert_eq(pal.nickname, "Biscuit", "and it is stored as a nickname")
	assert_eq(pal.display_name, "Terrapup", "the species name must survive being nicknamed over")


func test_an_empty_name_leaves_the_species_name_alone() -> void:
	# The catch in beat 8 adds a pal without asking for a name; only the starter
	# is named. A blank must not blank the creature out.
	var pal: RefCounted = SPECIES.spawn("bramblebun")
	SEAM.add(pal)
	assert_eq(pal.label(), "Bramblebun")
	assert_eq(pal.nickname, "", "no name typed means no nickname, not an empty one")


func test_the_opening_adds_two_pals_and_the_party_holds_both() -> void:
	SEAM.add(SPECIES.spawn("terrapup"), "Biscuit")
	SEAM.add(SPECIES.spawn("bramblebun"))
	assert_eq(SEAM.size(), 2)
	assert_false(SEAM.is_full(), "two of five is not full")


## CLAUDE.md's first hard rule. The opening can never reach it, but a seam that
## silently dropped the sixth pal would hide the day it starts mattering.
func test_the_sixth_pal_is_refused_rather_than_dropped() -> void:
	for i in SEAM.PARTY_LIMIT:
		assert_true(SEAM.add(SPECIES.spawn("bramblebun")), "pal %d should fit" % i)
	assert_true(SEAM.is_full())
	assert_false(SEAM.add(SPECIES.spawn("bramblebun")), "a sixth pal must be refused")
	assert_eq(SEAM.size(), SEAM.PARTY_LIMIT, "and must not have been stored anyway")


func test_adding_nothing_is_refused() -> void:
	assert_false(SEAM.add(null))
	assert_eq(SEAM.size(), 0)


## The fallback's cap is a copy of the real one, and a copy can drift. If
## `autoload/party.gd` ever moved off five, a seam still refusing at its own
## five — or worse, at six — would be a storage system CLAUDE.md forbids twice.
func test_the_fallback_refuses_at_the_same_number_the_real_party_does() -> void:
	assert_eq(SEAM.PARTY_LIMIT, PARTY.MAX_PALS)


# --- the real party ---------------------------------------------------------
#
# The half that was missing. Every test below puts a real party where the seam
# looks first, so a seam that falls back fails instead of passing quietly.


## The assertion that replaces `assert_true(answer or not answer)`.
##
## Asking is not the point; getting the right answer is. With no party in the
## tree the seam must say so, and with one present it must say so — and it is the
## second half that the old tautology let through for the entire life of the bug,
## because `has_game_state()` was pinned to false by a node name that never
## existed.
func test_the_seam_knows_whether_the_real_party_has_landed_yet() -> void:
	assert_false(SEAM.has_game_state(), "nothing is in the tree, so there is no real party")
	_install_the_party()
	assert_true(
		SEAM.has_game_state(),
		"a party is in the tree under the name project.godot registers, and the seam cannot see it"
	)


## The failure that started all of this: a pal added through the seam has to end
## up in the party the rest of the game reads. Not in a list beside it.
func test_a_pal_added_through_the_seam_lands_in_the_real_party() -> void:
	var party := _install_the_party()
	var pal: RefCounted = SPECIES.spawn("terrapup")

	assert_true(SEAM.add(pal, "Biscuit"))
	assert_eq(int(party.size()), 1, "the pal never reached Game.party")
	assert_eq(party.members()[0], pal, "Game.party holds something else")
	assert_eq(pal.label(), "Biscuit", "the naming beat has to survive the real path too")


## The phantom party, asserted directly.
##
## With a real party present the seam must keep NOTHING of its own. If it stores
## the pal in both places the party screen looks right and the counts drift
## apart later; if it stores it only in the fallback, the pal is gone the moment
## anything reads `Game.party` — which is what shipped.
func test_the_seam_keeps_no_party_of_its_own_while_the_real_one_is_there() -> void:
	var party := _install_the_party()
	SEAM.add(SPECIES.spawn("terrapup"), "Biscuit")
	assert_eq(SEAM.size(), 1)
	assert_eq(int(party.size()), 1)

	# Take the party away. Whatever the seam had squirrelled away is now all it
	# can show, and it must have been nothing.
	_remove_the_party()
	assert_eq(SEAM.size(), 0, "the seam was keeping a second copy of the party beside the real one")


## `party()` has to read the party, not a snapshot of it. The opening adds the
## caught Bramblebun through the seam and the party screen reads `Game.party`;
## if these two ever see different lists, one of the screens is lying.
func test_the_seam_reads_the_party_rather_than_remembering_it() -> void:
	var party := _install_the_party()
	var straight_in: RefCounted = SPECIES.spawn("ripplet")
	party.add(straight_in)

	assert_eq(SEAM.size(), 1, "a pal added without the seam is still in the party the seam reports")
	assert_eq(SEAM.party()[0], straight_in)


## The list the seam hands out must not be a way into the party. `members()` is
## a copy for exactly this reason, and a seam that returned the live array would
## quietly undo the cap.
func test_what_the_seam_hands_back_cannot_be_appended_to() -> void:
	var party := _install_the_party()
	SEAM.add(SPECIES.spawn("terrapup"))

	var handed_out: Array = SEAM.party()
	handed_out.append(SPECIES.spawn("bramblebun"))
	assert_eq(int(party.size()), 1, "appending to the returned array added a pal to the party")
	assert_eq(SEAM.size(), 1)


## CLAUDE.md's first hard rule, on the path the game actually runs. The cap lives
## in `autoload/party.gd` and the seam must defer to it — the earlier version
## asked `party_is_full()`, a method that does not exist, so `is_full()` would
## have answered from the seam's own count of a list the game never sees.
func test_the_real_party_refuses_the_sixth_pal_through_the_seam() -> void:
	var party := _install_the_party()
	for i in PARTY.MAX_PALS:
		assert_true(SEAM.add(SPECIES.spawn("bramblebun")), "pal %d should fit" % i)

	assert_true(SEAM.is_full(), "five of five is full, and the real party is the one that says so")
	assert_false(SEAM.add(SPECIES.spawn("terrapup")), "a sixth pal must be refused")
	assert_eq(int(party.size()), PARTY.MAX_PALS, "and must not have been stored anyway")
	assert_eq(SEAM.size(), PARTY.MAX_PALS)


## A party that is there but does not answer to the interface is a rename or a
## refactor, and the seam must not paper over it by falling back — that is the
## original bug's exact shape. It reports no party rather than a working one, and
## pushes an error saying which method went missing.
func test_a_party_that_does_not_answer_the_interface_is_not_quietly_accepted() -> void:
	# A RefCounted with none of the party's methods, hung where the real one goes.
	_install(RefCounted.new())

	assert_false(
		SEAM.has_game_state(),
		"the seam accepted a `party` that cannot add, list or count; the opening would drop pals into nothing"
	)


## The node name is the other half of the original bug, so it gets its own test:
## a party parked under the name the seam USED to look for must not be found.
## Without this, somebody restoring `GameState` in either file would break the
## opening and nothing here would notice.
func test_a_party_under_any_other_name_is_not_the_autoload() -> void:
	_install(PARTY.new(), "GameState")
	assert_false(
		SEAM.has_game_state(),
		"the seam bound to a node called GameState; project.godot registers the autoload as Game"
	)


# --- harness ----------------------------------------------------------------


## Put a party where the seam looks, under the name project.godot registers.
##
## The name is spelled out here rather than read from the seam's own constant on
## purpose: the seam getting that name wrong is the bug, and a test that imported
## the seam's spelling of it would have agreed with the bug.
func _install_the_party() -> RefCounted:
	var party: RefCounted = PARTY.new()
	_install(party)
	return party


func _install(party: RefCounted, node_name: String = "Game") -> void:
	_remove_the_party()
	_fake_root = Node.new()
	_stand_in = GameStandIn.new()
	_stand_in.name = node_name
	_stand_in.party = party
	_fake_root.add_child(_stand_in)
	SEAM.set_root_for_tests(_fake_root)


## Freed rather than queue_freed: the unit runner never processes a frame, so a
## queued node would still be alive for every test that follows and the fallback
## tests above would silently start running against a leftover party.
func _remove_the_party() -> void:
	SEAM.set_root_for_tests(null)
	_stand_in = null
	if _fake_root != null:
		_fake_root.free()
		_fake_root = null
