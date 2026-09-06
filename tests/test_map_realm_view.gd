extends "res://tests/test_case.gd"

## OP-0905-27 (docs/owner/OWNER_PLAYTEST_2026-09-05.md): "the map should show
## all the regions you've uncovered so meadows and clouds together." Pins
## `scripts/ui/tab_map.gd`'s realm-view selector -- which realm's MapState the
## full map tab reads for a given poll/draw, when the Meadows<->Cloudreach
## crossing marker appears, and that the player's own marker/objective diamond
## only draw in the realm the player actually stands in.
##
## D02 scope ("pure logic only... not rendering"): `_draw_map()`'s own
## `canvas.draw_*` calls are only legal inside an engine-dispatched `_draw()`
## notification -- calling it directly here, with no live Viewport ever
## queuing that redraw, would fail on the very first draw call with "Drawing
## is only allowed inside NOTIFICATION_DRAW". This exercises the SELECTION
## logic the draw path reads from instead: which MapState `_map_state()`
## resolves to, whether the crossing/player markers WOULD be drawn, where the
## crossing sits -- never the drawing itself. `TAB.new()` is never added to a
## SceneTree and `build()` is never called; every function under test only
## needs `menu.get("game")` (`menu_tab.gd::state()`), matching the plain-Node
## game double `tests/test_realm_map_persistence.gd` already uses for the same
## autoload, and `tests/smoke_cloudreach_act_one.gd`'s own
## `GAME_MENU.new(); menu.set("game", ...); tab.set("menu", menu)` wiring.

const GAME := preload("res://autoload/game_state.gd")
const GAME_MENU := preload("res://scripts/ui/game_menu.gd")
const TAB := preload("res://scripts/ui/tab_map.gd")
const CLOUDREACH_AT := Vector3(1400, 1000, 5500)

var _nodes: Array[Node] = []


func after_each() -> void:
	for node: Node in _nodes:
		node.free()
	_nodes.clear()


func _game() -> Node:
	var game := GAME.new()
	game.reset_for_new_game()
	_nodes.append(game)
	return game


func _tab(game: Node) -> Node:
	var menu := GAME_MENU.new()
	menu.set("game", game)
	_nodes.append(menu)
	var tab := TAB.new()
	tab.set("menu", menu)
	_nodes.append(tab)
	return tab


func test_meadows_is_the_only_available_realm_until_cloudreach_is_reachable() -> void:
	var game := _game()
	var tab := _tab(game)
	assert_eq(tab.call("_available_realms"), ["meadows"],
		"Cloudreach must not appear in the selector before anything unlocks it")
	assert_eq(str(tab.call("_display_realm")), "meadows")
	assert_false(bool(tab.call("_realm_link_visible")),
		"no crossing marker on the Meadows map before Cloudreach exists")

	game.progression.set_flag("realm_key_cloudreach")
	assert_eq(tab.call("_available_realms"), ["meadows", "cloudreach"],
		"the Warden's key flag (D110) makes Cloudreach a selectable realm")
	assert_true(bool(tab.call("_realm_link_visible")),
		"the crossing marker appears on the Meadows map once Cloudreach is reachable")


func test_cloudreachs_own_discovery_alone_unlocks_the_selector_without_any_flag() -> void:
	var game := _game()
	var cloud: RefCounted = game.realm_map_for("cloudreach")
	cloud.mark_visited(CLOUDREACH_AT)
	var tab := _tab(game)
	assert_true(bool(tab.call("_cloudreach_unlocked")),
		"real discovery already sitting in Cloudreach's own MapState unlocks the selector "
		+ "even with no progression flag set (a debug-teleported or migrated save)")


func test_standing_in_cloudreach_unlocks_the_selector_and_defaults_the_view_there() -> void:
	var game := _game()
	game.current_realm = "cloudreach" # Scene authorization belongs to enter_realm(); the test only needs the fact.
	game.bind_realm_map()
	var tab := _tab(game)
	assert_true(bool(tab.call("_cloudreach_unlocked")))
	assert_eq(str(tab.call("_display_realm")), "cloudreach",
		"default selection is the realm the player is actually in")


func test_switching_the_view_reads_the_other_realms_map_state_without_moving_the_active_map() -> void:
	var game := _game()
	game.progression.set_flag("realm_key_cloudreach")
	var cloud: RefCounted = game.realm_map_for("cloudreach")
	cloud.mark_visited(CLOUDREACH_AT)
	var tab := _tab(game)

	assert_eq(str(tab.call("_display_realm")), "meadows", "default view is the player's own realm")
	assert_eq(tab.call("_map_state"), game.map,
		"default view reads the SAME instance the rest of the game treats as active")

	tab.call("_on_realm_button_pressed", "cloudreach")
	assert_eq(str(tab.call("_display_realm")), "cloudreach")
	var viewed: RefCounted = tab.call("_map_state")
	assert_eq(viewed, cloud, "switched view reads Cloudreach's own MapState instance")
	assert_ne(viewed, game.map, "switching the VIEW never reassigns the single active game.map")
	assert_true(bool(viewed.is_discovered(CLOUDREACH_AT)),
		"the drawn map state carries Cloudreach's own real discovery, not an empty stand-in")
	assert_eq(str(game.current_realm), "meadows",
		"looking at Cloudreach on the map does not move the player's own realm")

	tab.call("_on_realm_button_pressed", "meadows")
	assert_eq(str(tab.call("_display_realm")), "meadows")
	assert_eq(tab.call("_map_state"), game.map, "switching back restores the default view")


func test_player_marker_and_objective_only_draw_in_the_players_own_realm() -> void:
	var game := _game()
	game.progression.set_flag("realm_key_cloudreach")
	var tab := _tab(game)

	assert_true(bool(tab.call("_should_draw_player_marker")),
		"player stands in Meadows and the default view is Meadows")
	tab.call("_on_realm_button_pressed", "cloudreach")
	assert_false(bool(tab.call("_should_draw_player_marker")),
		"viewing Cloudreach while the player's own body is still in Meadows must hide the marker")
	tab.call("_on_realm_button_pressed", "meadows")
	assert_true(bool(tab.call("_should_draw_player_marker")), "switching back restores the marker")


func test_realm_link_points_are_read_from_the_shared_transition_source() -> void:
	var tab := _tab(_game())

	var meadows_point: Variant = tab.call("_realm_link_point", "meadows")
	assert_true(meadows_point is Vector2, "the Meadows-side crossing point must resolve to a real position")
	if meadows_point is Vector2:
		assert_almost_eq((meadows_point as Vector2).x, -33.5, 0.01,
			"must match data/config/realm_transitions.json's meadows_cloudreach_gate.position[0]")
		assert_almost_eq((meadows_point as Vector2).y, 7502.0, 0.01,
			"must match data/config/realm_transitions.json's meadows_cloudreach_gate.position[1]")

	var cloud_point: Variant = tab.call("_realm_link_point", "cloudreach")
	assert_true(cloud_point is Vector2, "the Cloudreach-side crossing point must resolve to a real position")
	if cloud_point is Vector2:
		assert_almost_eq((cloud_point as Vector2).x, 0.0, 0.01,
			"must match data/config/cloudreach_world.json's meadows_entry position, x")
		assert_almost_eq((cloud_point as Vector2).y, -260.0, 0.01,
			"must be the entry's world Z (position[2]), not its Y")


func test_realm_link_labels_and_icon_come_from_map_json_and_name_the_destination() -> void:
	var game := _game()
	game.progression.set_flag("realm_key_cloudreach")
	var tab := _tab(game)

	var cfg: Dictionary = tab.call("_realm_link_config")
	assert_eq(str(cfg.get("icon", "")), "gate", "map.json's realm_link.icon must resolve to a vendored icon")
	assert_true(ResourceLoader.exists("res://assets/ui/icons/map/%s.png" % str(cfg.get("icon", ""))),
		"the configured realm_link icon must be a real vendored file (CLAUDE.md: no new Meadows art)")

	assert_eq(str(tab.call("_other_realm", "meadows")), "cloudreach")
	assert_eq(str(tab.call("_other_realm", "cloudreach")), "meadows")
	assert_eq(str(tab.call("_realm_display_name", "meadows")), "Meadows")
	assert_eq(str(tab.call("_realm_display_name", "cloudreach")), "Cloudreach Cliffs")
