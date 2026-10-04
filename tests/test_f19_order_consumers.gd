extends "res://tests/test_case.gd"

## Runtime data consumers, off-tree UI readers and host travel policy. These
## assertions do not claim screenshots or a played/earned campaign.
const ORDER := preload("res://scripts/data/biome_order.gd")
const QUEST := preload("res://scripts/world/quest_log.gd")
const CREDITS := preload("res://scripts/ui/regional_credits.gd")
const ARCH := preload("res://scripts/world/portal_arch.gd")
const POLICY := preload("res://scripts/net/portal_action_policy.gd")
const DATA := preload("res://scripts/data/redesign_data.gd")
const TAB := preload("res://scripts/ui/tab_map.gd")
const MENU := preload("res://scripts/ui/game_menu.gd")
const GAME := preload("res://autoload/game_state.gd")

class ReadySession extends Node:
	func portal_runtime_ready() -> bool: return true

func test_config_journal_map_and_credits_consume_the_same_new_chapter_order() -> void:
	assert_eq(ORDER.ids(false), ["meadows", "tidewake", "cloudreach", "stormwood"])
	var runtime := ["meadows", "water", "cloudreach", "stormwood"]
	var names := ["The Meadows", "Tidewake", "Cloudreach Cliffs", "The Stormwood"]
	var log := QUEST.new()
	assert_eq(log.chapter_order(), runtime)
	for index: int in runtime.size():
		log.set_realm(runtime[index])
		assert_eq(log.chapter_heading(), "Chapter %d · %s" % [index + 1, names[index]])
	var credits := CREDITS.new()
	assert_eq(credits._read_config().sections[0], {"heading": "The journey", "lines": names})
	credits.free()
	var game := GAME.new()
	game.reset_for_new_game()
	var session := ReadySession.new()
	game.session = session
	game.local.redesign_character.portal_unlocks = ["stormwood", "cloudreach", "tidewake"]
	var menu := MENU.new()
	menu.game = game
	var tab := TAB.new()
	tab.menu = menu
	assert_eq(tab._available_realms(), runtime, "map orders actual reachable destinations, ignoring unlock insertion order")
	tab.free()
	menu.free()
	session.free()
	game.free()

func test_every_live_portal_prompt_keeps_its_recommendation_in_every_travel_state() -> void:
	var levels := {"meadows": 3, "tidewake": 20, "cloudreach": 31, "stormwood": 42}
	for row: Dictionary in DATA.json("res://data/config/portals.json").arches:
		if row.kind != "live": continue
		assert_eq(int(row.recommended_level), levels[row.biome])
		for view: Dictionary in [{}, {"ready": true}, {"ready": true, "has_key": true},
			{"ready": true, "open": true}, {"ready": true, "open": true, "has_key": true},
			{"ready": true, "open": true, "character_open": true, "has_key": true}]:
			assert_true(ARCH.prompt_text(row, view).contains("Recommended Lv %d" % levels[row.biome]), "actual sign for " + row.biome + ":" + str(view))

func test_recommended_levels_never_gate_the_actual_host_portal_policy() -> void:
	var config: Dictionary = DATA.json("res://data/config/portals.json")
	var stones: Dictionary = DATA.json("res://data/config/waystones.json")
	for row: Dictionary in config.arches:
		if row.kind != "live": continue
		var policy := POLICY.new()
		policy.bind_world("world-a")
		var context := {"world_instance_id": "world-a", "character_id": "character-a", "peer_id": 2,
			"realm": "meadows", "position": Vector3.ZERO, "damage_revision": 0,
			"combat": false, "dialogue": false, "cutscene": false, "swimming": false, "flying": false, "downed": false,
			"character_unlocks": [row.biome], "world_unlocks": [], "arch_positions": {row.id: Vector3.ZERO},
			"last_waystones": {}, "waystones_activated": {}, "party_level": 1}
		var result := policy.evaluate({"kind": "portal_enter", "arch_id": row.id}, context, config, stones, 100)
		assert_true(result.get("ok", false), "an admitted level-one traveler with an unlock can enter " + row.biome)
		if result.get("ok", false):
			assert_eq(policy.consume_permit(result.prepared.travel_permit, 2, "character-a", "world-a", "meadows").get("realm"), ORDER.runtime_id(row.biome))
