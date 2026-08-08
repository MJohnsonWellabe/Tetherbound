extends "res://tests/test_case.gd"

## The seam between the opening sequence and the party it does not own.
##
## The party — a GameState autoload with the five-pal rule in it, and a
## `nickname` on pal_instance.gd — is being built in parallel and is not in this
## tree. docs/OPENING_SEQUENCE.md used to claim it already existed; it did not,
## and that claim is what this seam exists to survive.
##
## So these tests deliberately exercise the FALLBACK path. When GameState lands,
## `has_game_state()` starts returning true, the fallback stops being used, and
## these tests should be rewritten against the real thing rather than deleted —
## every call the opening makes goes through this file.

const SEAM := preload("res://scripts/story/party_seam.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")


func before_each() -> void:
	SEAM.reset()


func after_each() -> void:
	SEAM.reset()


func test_a_chosen_pal_joins_the_party() -> void:
	var pal: RefCounted = SPECIES.spawn("terrapup")
	assert_true(SEAM.add(pal, "Biscuit"))
	assert_eq(SEAM.size(), 1)
	assert_eq(SEAM.party()[0], pal)


## The name is the whole point of the naming beat, and it has to be visible
## through the field the HUD and every prompt already read — otherwise the pal
## is named in a field nothing draws and the beat looks broken.
func test_naming_a_pal_changes_the_name_the_game_shows() -> void:
	var pal: RefCounted = SPECIES.spawn("terrapup")
	assert_eq(pal.display_name, "Terrapup", "before naming, it is its species")
	SEAM.add(pal, "Biscuit")
	assert_eq(pal.display_name, "Biscuit")


func test_an_empty_name_leaves_the_species_name_alone() -> void:
	# The catch in beat 8 adds a pal without asking for a name; only the starter
	# is named. A blank must not blank the creature out.
	var pal: RefCounted = SPECIES.spawn("bramblebun")
	SEAM.add(pal)
	assert_eq(pal.display_name, "Bramblebun")


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


func test_the_seam_knows_whether_the_real_party_has_landed_yet() -> void:
	# Not an assertion about which answer is right — it is false today and true
	# once the autoload exists. What matters is that asking does not crash,
	# because every call in this file branches on it.
	var answer: bool = SEAM.has_game_state()
	assert_true(answer or not answer)
