extends "res://tests/test_case.gd"

## Stormwood's four authored TM pockets use the shared TM/item/teaching path.
## This pins the electric entries to a real compatible species, rather than
## only asserting that their data keys happen to exist.
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")
const TM_DB := preload("res://scripts/creatures/tm_db.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")

const STORMWOOD_TMS := {
	"tm_static_snap": {"move": "static_snap", "slot": "quick"},
	"tm_voltaic_whip": {"move": "voltaic_whip", "slot": "charged"},
	"tm_thunder_break": {"move": "thunder_break", "slot": "charged"},
	"tm_stormfall": {"move": "stormfall", "slot": "charged"},
}

var moves: RefCounted
var tms: RefCounted
var items: RefCounted


func before_each() -> void:
	moves = MOVE_DB.new()
	tms = TM_DB.new()
	items = ITEM_DB.new()


func test_stormwood_tms_are_single_use_electric_discs_with_real_moves() -> void:
	for tm_id: String in STORMWOOD_TMS:
		var expected: Dictionary = STORMWOOD_TMS[tm_id]
		assert_true(tms.has(tm_id), "%s has a TM definition" % tm_id)
		assert_eq(items.kind(tm_id), "tm", "%s is a carryable TM item" % tm_id)
		assert_eq(items.stack_size(tm_id), 1, "%s is one teaching disc" % tm_id)
		assert_eq(str(tms.move_id(tm_id)), str(expected["move"]), "%s names its move" % tm_id)
		assert_eq(moves.slot(str(expected["move"])), str(expected["slot"]), "%s uses its move slot" % tm_id)
		assert_true(TEACHING.can_learn("electric", tm_id, tms), "%s accepts electric creatures" % tm_id)
		assert_false(TEACHING.can_learn("ground", tm_id, tms), "%s rejects incompatible creatures" % tm_id)


func test_stormwood_tms_teach_sparkit_the_declared_slots() -> void:
	for tm_id: String in STORMWOOD_TMS:
		var expected: Dictionary = STORMWOOD_TMS[tm_id]
		var sparkit: RefCounted = SPECIES.spawn("sparkit")
		var before_quick := str(sparkit.get("move_quick"))
		var before_charged := str(sparkit.get("move_charged"))
		assert_true(TEACHING.teach(sparkit, tm_id, tms, moves), "%s teaches a real electric creature" % tm_id)
		if str(expected["slot"]) == "quick":
			assert_eq(str(sparkit.get("move_quick")), str(expected["move"]), "%s replaces Sparkit's quick move" % tm_id)
			assert_eq(str(sparkit.get("move_charged")), before_charged, "%s leaves Sparkit's charged move alone" % tm_id)
		else:
			assert_eq(str(sparkit.get("move_charged")), str(expected["move"]), "%s replaces Sparkit's charged move" % tm_id)
			assert_eq(str(sparkit.get("move_quick")), before_quick, "%s leaves Sparkit's quick move alone" % tm_id)
