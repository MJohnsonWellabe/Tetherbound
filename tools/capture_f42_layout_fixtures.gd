extends SceneTree

## Native UI layout fixtures; no earned service, co-op, save,
## station reach, handheld hardware or visual PASS evidence. All fixtures
## are disclosed here and in the output manifest. Never changes disk flags.
const SCREEN := preload("res://scripts/ui/system_screen.gd")
const DETAILS := preload("res://scripts/ui/companion_details_panel.gd")
const RESEARCH := preload("res://scripts/ui/research_log_panel.gd")
const BOUNTY := preload("res://scripts/ui/bounty_board_panel.gd")
const OVERLAY := preload("res://scripts/ui/combat_system_overlay.gd")
const ALTAR := preload("res://scripts/ui/altar_panel.gd")
const TRAITS_PANEL := preload("res://scripts/ui/altar_traits_panel.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const COMMANDS := preload("res://scripts/combat/tether_commands.gd")
var _out := ""
var _size := Vector2i(1920, 1080)
var _game: Node
var _uid := ""
var _captures: Array[String] = []
var _capture_combat := true

class AltarFixture extends Node:
	signal essence_spend_completed(id: String, result: Dictionary)
	signal essence_quote_completed(key: String, uid: String, result: Dictionary)
	var uid := ""
	var level := 1
	func station_available(_key: String) -> bool: return true
	func quote_essence_spend(_key: String, _uid: String) -> Dictionary:
		return {"ok": true, "creature_uid": uid, "level": level, "cap": 10, "expected_character_revision": 0,
			"payments": [{"id": "essence_ground", "name": "Ground Essence", "cost": 4, "available": 20},
				{"id": "tether_candy", "name": "Tether Candy", "cost": 1, "available": 1}]}
	func submit_essence_spend(_key: String, _request: Dictionary) -> void: pass
	func reconcile_essence_spend(_id: String) -> void: pass
	func invalidate_essence_quote() -> void: pass

class TraitsFixture extends Node:
	signal action_completed(result: Dictionary)
	var uid := ""
	func creature_choices() -> Array[Dictionary]: return [{"uid": uid, "name": "Terrapup"}]
	func quote(_key: String, _uid: String) -> Dictionary:
		return {"ok": true, "traits": [], "seeds": [], "unlocked_slots": [], "taught_traits": {},
			"essence_cost_per_slot": 5, "payment_items": ["essence_ground"], "release_allowed": false,
			"expected_character_revision": 0}
	func busy() -> bool: return false
	func submit(_key: String, _request: Dictionary) -> void: pass

class BountyFixture extends Node:
	signal action_completed(result: Dictionary)
	func view() -> Dictionary:
		return {"ready": true, "rows": [
			{"instance": "layout-catch", "kind": "catch_trait", "biome": "meadows", "title": "Catch a creature with Bold",
				"complete": true, "paid": false, "claimable": true, "rewards": [{"id": "essence_ground", "n": 8}]},
			{"instance": "layout-delivery", "kind": "material_delivery", "biome": "tidewake", "title": "Deliver driftwood",
				"item": "driftwood", "count": 6, "owned": 4, "claimable": true, "paid": false,
				"rewards": [{"id": "essence_water", "n": 8}]},
			{"instance": "layout-alpha", "kind": "defeat_alpha", "biome": "stormwood", "title": "Defeat an alpha",
				"complete": false, "paid": false, "claimable": false, "rewards": [{"id": "essence_electric", "n": 14}]}]}
	func claim(_instance: String) -> Dictionary: return {"ok": false, "terminal": true, "durable": false}
	func reconcile() -> void: pass

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out-dir="): _out = argument.trim_prefix("--out-dir=")
		if argument == "--size=1280x800": _size = Vector2i(1280, 800)
		if argument == "--size=1280x720": _size = Vector2i(1280, 720)
		if argument == "--skip-combat-fixture": _capture_combat = false
	if _out.is_empty() or DisplayServer.get_name() == "headless":
		push_error("Explicit --out-dir and a native display are required; do not use --headless.")
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(_out) != OK:
		quit(1)
		return
	root.size = _size
	root.content_scale_size = Vector2i.ZERO # Judge native font pixels at each requested raster.
	SCREEN.config()["enabled"] = true # In-memory fixture opt-in; shipped flag stays false.
	COMMANDS.config().feature_flags.ui_enabled = true # Presentation-only fixture opt-in.
	_game = root.get_node("Game")
	_game.call("reset_for_new_game")
	var creature: RefCounted = SPECIES.spawn("terrapup")
	_game.get("party").call("add", creature)
	_uid = str(creature.get("uid"))
	for tab: String in ["Loadout", "Mastery", "Gear"]:
		var panel := DETAILS.new()
		root.add_child(panel)
		if not panel.open(_game, _uid, tab):
			quit(1)
			return
		await _capture("altar-" + tab.to_lower())
		panel.close()
		panel.queue_free()
		await process_frame
	var level_service := AltarFixture.new()
	level_service.uid = _uid
	level_service.level = int(creature.get("level"))
	root.add_child(level_service)
	var altar := ALTAR.new()
	root.add_child(altar)
	if not altar.configure_service(level_service) or not altar.open("layout-altar"):
		push_error("Actual Altar Level surface refused to open")
		quit(1)
		return
	await _capture("altar-level")
	altar.close()
	altar.queue_free()
	await process_frame
	var traits_service := TraitsFixture.new()
	traits_service.uid = _uid
	root.add_child(traits_service)
	var traits := TRAITS_PANEL.new()
	root.add_child(traits)
	if not traits.open(traits_service, "layout-altar"):
		push_error("Actual Altar Traits surface refused to open")
		quit(1)
		return
	await _capture("altar-traits-release")
	traits.close()
	traits.queue_free()
	await process_frame
	var station: Dictionary = preload("res://tests/test_craft_station_confirm_lifetime.gd").new().call("_fixture", self, false)
	if not station.panel.is_open():
		push_error("Existing station component refused to open")
		quit(1)
		return
	await _capture("station-forge")
	station.panel.close()
	station.holder.queue_free()
	await process_frame
	var research := RESEARCH.new()
	root.add_child(research)
	if not research.open(_research_fixture):
		quit(1)
		return
	research.call("_inspect", "terrapup")
	await _capture("research-log")
	research.close()
	research.queue_free()
	await process_frame
	var board := BountyFixture.new()
	root.add_child(board)
	var bounties := BOUNTY.new()
	root.add_child(bounties)
	if not bounties.open(board):
		quit(1)
		return
	await _capture("bounty-board")
	bounties.close()
	bounties.queue_free()
	await process_frame
	if _capture_combat:
		var overlay := OVERLAY.new()
		root.add_child(overlay)
		overlay.configure(_combat_fixture)
		overlay.refresh(_uid, true)
		await _capture("combat-meters-moves")
	var file := FileAccess.open(_out.path_join("fixture-manifest.json"), FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string(JSON.stringify({"evidence_kind": "native UI layout fixtures only", "size": [_size.x, _size.y],
		"captures": _captures, "earned_service_save_coop_device_visual_pass": false,
		"fixtures": ["new-game Terrapup", "invented Altar quote", "empty trait quote", "invented research tasks",
			"invented bounty rows", "existing Forge station-confirm component"],
		"combat_fixture_captured": _capture_combat,
		"missing": ["earned services", "code-blind judge", "world/HUD composite"]}, "\t"))
	quit(0)

func _capture(name: String) -> void:
	for index: int in 8: await process_frame
	await RenderingServer.frame_post_draw
	var path := _out.path_join("f42-" + name + "-%dx%d.png" % [_size.x, _size.y])
	var image := root.get_texture().get_image()
	if image == null or image.get_size() != _size or image.save_png(path) != OK:
		push_error("Could not save " + path)
		quit(1)
		return
	_captures.append(path)
	print("FIXTURE UI CAPTURE: " + path)

func _research_fixture(_biome: String) -> Dictionary:
	return {"ready": true, "completion_percent": 33, "species": [{"species_id": "terrapup", "name": "Terrapup",
		"seen": true, "caught": true, "tasks": [{"label": "Meet Terrapup", "progress": 1, "required": 1,
			"reward_item": "essence_ground", "reward_count": 4, "paid": true},
			{"label": "Land quick moves", "progress": 4, "required": 10, "reward_item": "essence_ground", "reward_count": 8, "paid": false}]}]}

func _combat_fixture() -> Dictionary:
	var slots := {}
	for slot: String in ["quick", "charged", "utility", "dodge"]:
		slots[slot] = {"name": slot.capitalize(), "glyph": {"quick": "X", "charged": "Y", "utility": "B", "dodge": "A"}[slot], "ready": slot != "utility",
			"cooldown_total_s": 5 if slot == "utility" else 0, "cooldown_remaining_s": 2 if slot == "utility" else 0}
	return {"active": true, "input_context": "combat", "creature_uid": _uid, "ultimate_meter": 100, "ultimate_maximum": 100,
		"ultimate_armed": true, "arm_fraction": 0.6, "slots": slots,
		"commands": {"active": true, "meter": 50, "pouch_count": 2, "wild_target": true, "combo_remaining_s": 0.5,
			"unlocked_commands": ["rally", "item_throw", "tag_combo", "snare"]}}
