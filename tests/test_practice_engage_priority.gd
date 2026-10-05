extends "res://tests/test_case.gd"

## F01#4 (ralph/reports/INTEGRATION/reproof/f01-current/row4-5/VERDICT.md,
## terrapup run 1). The engage offer was the nearest live wild in range, so an
## ambient Mudsnout 2.56 m away took the opening's practice fight from the
## practice Bramblebun 5.3 m away. During the opening's practice beats the
## practice species now wins the offer; on every other beat, and whenever no
## practice creature is in range, the nearest creature still wins.
##
## Pure pieces only (the unit runner has no SceneTree): the selection rule
## `encounter_director.gd::choose_engage_target()` and the beat gate
## `sequence_director.gd::practice_engage_species_for()`, read against the
## shipping opening.json.

const ENCOUNTER := preload("res://scripts/combat/encounter_director.gd")
const SEQUENCE := preload("res://scripts/story/sequence_director.gd")
const BEATS := preload("res://scripts/story/opening_beats.gd")

const RANGE := 6.0

var _mudsnout: Node3D
var _bramblebun: Node3D
var _far_bramblebun: Node3D


func before_each() -> void:
	_mudsnout = Node3D.new()
	_bramblebun = Node3D.new()
	_far_bramblebun = Node3D.new()


func after_each() -> void:
	for body: Node3D in [_mudsnout, _bramblebun, _far_bramblebun]:
		if is_instance_valid(body):
			body.free()


func _reproof_field() -> Array:
	return [
		{"body": _mudsnout, "distance": 2.56, "species": "mudsnout"},
		{"body": _bramblebun, "distance": 5.33, "species": "bramblebun"},
	]


func test_the_practice_species_wins_over_a_nearer_ambient_wild() -> void:
	assert_eq(ENCOUNTER.choose_engage_target(_reproof_field(), RANGE, "bramblebun"), _bramblebun,
		"the measured reproof field offers the practice Bramblebun, not the nearer Mudsnout")


func test_without_a_priority_the_nearest_wild_still_wins() -> void:
	assert_eq(ENCOUNTER.choose_engage_target(_reproof_field(), RANGE, ""), _mudsnout,
		"outside the practice beats the ordinary nearest-creature rule is unchanged")


func test_an_out_of_range_practice_creature_never_blocks_the_ordinary_choice() -> void:
	var field := [
		{"body": _mudsnout, "distance": 2.56, "species": "mudsnout"},
		{"body": _far_bramblebun, "distance": RANGE + 0.5, "species": "bramblebun"},
	]
	assert_eq(ENCOUNTER.choose_engage_target(field, RANGE, "bramblebun"), _mudsnout,
		"a practice creature beyond engage range is not offered and does not hide the nearer wild")


func test_the_nearest_practice_creature_wins_among_several() -> void:
	var field := [
		{"body": _far_bramblebun, "distance": 5.9, "species": "bramblebun"},
		{"body": _mudsnout, "distance": 1.0, "species": "mudsnout"},
		{"body": _bramblebun, "distance": 4.0, "species": "bramblebun"},
	]
	assert_eq(ENCOUNTER.choose_engage_target(field, RANGE, "bramblebun"), _bramblebun)


func test_nothing_in_range_offers_nothing() -> void:
	var field := [{"body": _mudsnout, "distance": RANGE + 1.0, "species": "mudsnout"}]
	assert_eq(ENCOUNTER.choose_engage_target(field, RANGE, "bramblebun"), null)
	assert_eq(ENCOUNTER.choose_engage_target([], RANGE, "bramblebun"), null)


func test_the_shipping_config_prefers_the_practice_species_only_on_its_beats() -> void:
	var encounter := BEATS.encounter()
	var species := str(encounter.get("species", ""))
	assert_eq(species, "bramblebun", "opening.json names the practice species")
	var beats: Variant = encounter.get("practice_engage_priority_beats", null)
	assert_true(beats is Array and not (beats as Array).is_empty(),
		"opening.json declares the practice priority beats as a tunable")
	for beat: String in BEATS.order():
		var wanted := species if (beats as Array).has(beat) else ""
		assert_eq(SEQUENCE.practice_engage_species_for(beat, encounter), wanted,
			"beat '%s' practice priority" % beat)
	assert_eq(SEQUENCE.practice_engage_species_for(BEATS.WALK_OUT, encounter), species)
	assert_eq(SEQUENCE.practice_engage_species_for(BEATS.ENCOUNTER, encounter), species)
	assert_eq(SEQUENCE.practice_engage_species_for(BEATS.ROAD, encounter), "",
		"the priority ends at the first catch")
	for beat: Variant in beats as Array:
		assert_true(BEATS.has(str(beat)), "priority beat '%s' is a real opening beat" % str(beat))


func test_an_empty_beat_list_disables_the_priority() -> void:
	var encounter := {"species": "bramblebun", "practice_engage_priority_beats": []}
	assert_eq(SEQUENCE.practice_engage_species_for(BEATS.ENCOUNTER, encounter), "")
	assert_eq(SEQUENCE.practice_engage_species_for(BEATS.ENCOUNTER, {"species": "bramblebun"}), "")
