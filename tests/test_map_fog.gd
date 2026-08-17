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
