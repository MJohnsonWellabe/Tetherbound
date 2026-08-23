extends "res://tests/test_case.gd"

## OW3 — owner playtest: "The full map is rendered before I explore
## anything." Spec §16: the map "reveals explored areas/landmarks" and
## "does not reveal everything automatically."
##
## `autoload/map_state.gd` already tracked a real fog grid and
## `scripts/ui/tab_map.gd`/`scripts/ui/minimap.gd` already painted an
## "unexplored" overlay over it — but that overlay's own `FOG_UNDISCOVERED`
## constant was translucent (55% on the full map, 95% on the minimap), so the
## baked terrain underneath showed through dimly across the WHOLE world
## regardless of how little the player had actually walked. Translucent fog
## that lets the whole map's shape read through is still "reveals everything
## automatically," just at reduced contrast — which is exactly the owner
## report above.
##
## This does not re-render a frame (`test_case.gd`/D02: pure logic only, no
## scenes/rendering — that is `tools/capture_map_tab.gd`'s job and a human
## eye's). It reads the literal constant both draw paths use to paint
## unexplored ground, the same way `test_map_icons.gd` reads production JSON
## rather than re-deriving it: whatever alpha this constant holds IS what a
## player sees, so asserting on it directly is asserting on the real bug
## rather than a proxy for it.

const TAB_MAP_PATH := "res://scripts/ui/tab_map.gd"
const MINIMAP_PATH := "res://scripts/ui/minimap.gd"


func _fog_undiscovered_alpha(script_path: String) -> float:
	var script: Script = load(script_path)
	var consts: Dictionary = script.get_script_constant_map()
	var colour: Color = consts.get("FOG_UNDISCOVERED", Color(0, 0, 0, 0))
	return colour.a


func test_full_map_hides_unexplored_ground_completely() -> void:
	var alpha := _fog_undiscovered_alpha(TAB_MAP_PATH)
	assert_eq(alpha, 1.0,
		"tab_map.gd's FOG_UNDISCOVERED must be fully opaque (got alpha=%.2f) — anything less lets unexplored terrain show through, which is the exact 'full map is rendered before I explore anything' report" % alpha)


func test_minimap_hides_unexplored_ground_completely() -> void:
	var alpha := _fog_undiscovered_alpha(MINIMAP_PATH)
	assert_eq(alpha, 1.0,
		"minimap.gd's FOG_UNDISCOVERED must be fully opaque (got alpha=%.2f) — spec §16 forbids the map ever revealing everything automatically, on either screen" % alpha)


## Discovered cells must stay fully see-through, or walking around would
## never actually reveal anything either — the other half of the same
## contract, pinned so a future "fix" cannot swing the opposite way and make
## FOG_DISCOVERED opaque too.
func test_discovered_ground_stays_fully_visible_on_both_screens() -> void:
	for path in [TAB_MAP_PATH, MINIMAP_PATH]:
		var script: Script = load(path)
		var consts: Dictionary = script.get_script_constant_map()
		var colour: Color = consts.get("FOG_DISCOVERED", Color(1, 1, 1, 1))
		assert_eq(colour.a, 0.0,
			"%s's FOG_DISCOVERED must be fully transparent (got alpha=%.2f)" % [path, colour.a])


## --- the starting reveal (owner directive 2026-08-22 section 3) -------------
##
## "The village and the roads out of it start revealed... The player does not
## start blind in their own home town."
##
## The two halves have to be asserted together, because each one alone is
## satisfiable by the wrong answer: "something is revealed" is satisfied by
## revealing the whole map, and "most of the map is hidden" is satisfied by
## revealing nothing, which is the state this directive was written about. The
## owner's ruling was recorded in ralph/BLOCKED.md on 2026-08-22 and then never
## implemented -- both commits that closed that entry touched only BLOCKED.md,
## so a fresh save kept opening a black rectangle. Nothing failed, because
## nothing asked.

const MAP_STATE := preload("res://autoload/map_state.gd")
const LANDMARKS_PATH := "res://data/config/map_landmarks.json"


func _fresh_map() -> RefCounted:
	var state: RefCounted = MAP_STATE.new()
	var file := FileAccess.open(LANDMARKS_PATH, FileAccess.READ)
	assert_true(file != null, "map_landmarks.json is missing")
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary, "map_landmarks.json did not parse as a dictionary")
	state.call("configure", parsed as Dictionary)
	return state


func test_a_fresh_save_starts_with_the_village_and_its_roads_revealed() -> void:
	var state := _fresh_map()
	# The village square, and a point out along each of Band 0's four roads.
	# These are read from the same authored routes the seed is sampled from, so
	# moving a road moves the assertion with it rather than stranding it.
	var known := [
		Vector3(10.0, 0.0, -10.0),    # the square
		Vector3(-18.0, 0.0, -15.0),   # west, toward Grandpa's house
		Vector3(30.0, 0.0, -40.0),    # south-east
		Vector3(-32.0, 0.0, 32.0),    # north-west, toward the pond
		Vector3(45.0, 0.0, -22.0),    # east, toward the road gate
	]
	for at: Vector3 in known:
		assert_true(bool(state.call("is_discovered", at)),
			"a fresh save leaves (%.0f, %.0f) dark; the owner's 2026-08-22 ruling is that the village and the roads out of it start revealed" % [at.x, at.z])


func test_the_starting_reveal_does_not_hand_over_the_rest_of_the_chapter() -> void:
	var state := _fresh_map()
	# Everything the player has to actually travel to. If a future widening of
	# the seed swallows these, the map has gone back to "reveals everything
	# automatically", which spec sec16 forbids outright.
	var unwalked := [
		Vector3(0.0, 0.0, 1330.0),    # the South Bridge
		Vector3(350.0, 0.0, 3760.0),  # the Tether Relay
		Vector3(0.0, 0.0, 7560.0),    # Meadows Hall
	]
	for at: Vector3 in unwalked:
		assert_false(bool(state.call("is_discovered", at)),
			"a fresh save already reveals (%.0f, %.0f); the starting reveal is the village and its roads, not the chapter" % [at.x, at.z])
	var fraction := float(state.call("discovered_fraction"))
	assert_true(fraction > 0.0,
		"a fresh save reveals nothing at all -- this is the black-rectangle state the owner reported as OP21-15")
	assert_true(fraction < 0.05,
		"a fresh save reveals %.1f%% of the world; the seed is meant to be the home town, not a head start" % (fraction * 100.0))
