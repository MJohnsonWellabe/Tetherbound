extends SceneTree

## Production UI inventory from a real biome scene at the native 1920x1080
## review raster. Fixtures stock a small party and satchel so panels have
## content; they do not write saves or change game code.

const SCENES := {
	"meadows": "res://scenes/world/meadows_playground.tscn",
	"water": "res://scenes/world/water_archipelago.tscn",
	"cloudreach": "res://scenes/world/cloudreach_cliffs.tscn",
	"stormwood": "res://scenes/world/stormwood.tscn",
}
const MENU_DATA := "res://data/config/menu.json"

var _biome := ""
var _output := ""
var _seed := 2042
var _map_cycle := false
var _records: Array[Dictionary] = []
var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Phase 2 UI capture requires a rendering display")
		quit(1)
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--biome="):
			_biome = arg.trim_prefix("--biome=")
		elif arg.begins_with("--output="):
			_output = arg.trim_prefix("--output=")
		elif arg.begins_with("--seed="):
			_seed = int(arg.trim_prefix("--seed="))
		elif arg == "--map-cycle":
			_map_cycle = true
	if not SCENES.has(_biome) or not _output.begins_with("res://ralph/reports/VISUAL/phase2/"):
		push_error("Use --biome and --output under the Phase 2 evidence directory")
		quit(1)
		return
	seed(_seed)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output))
	var game := root.get_node_or_null(^"Game")
	if game == null:
		push_error("Game autoload unavailable")
		quit(1)
		return
	if game.has_method("reset_for_new_game"):
		game.call("reset_for_new_game")
	game.set("current_realm", _biome)
	var world := (load(str(SCENES[_biome])) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	var deadline := Time.get_ticks_msec() + 900000
	while world.has_method("shell_build_complete") and not bool(world.call("shell_build_complete")):
		if Time.get_ticks_msec() > deadline:
			push_error("World build timed out")
			quit(1)
			return
		await process_frame
	for frame in 30:
		await physics_frame
	var camera := world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	if camera != null:
		camera.make_current()
	var look := world.get_node_or_null(^"WorldLook")
	if look != null and look.has_method("apply_time"):
		look.call("apply_time", "day")
		look.set_process(false)
	_stock_fixture(game)
	var menu: Node = game.call("menu")
	if menu == null:
		push_error("Game menu unavailable")
		quit(1)
		return
	await _shoot("exploration_hud", "HUD in exploration", world)
	var menu_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MENU_DATA))
	if not menu_data is Dictionary:
		push_error("Menu data invalid")
		quit(1)
		return
	for raw_tab: Variant in (menu_data as Dictionary).get("tabs", []):
		if not raw_tab is Dictionary:
			continue
		var tab_id := str((raw_tab as Dictionary).get("id", ""))
		if _map_cycle and tab_id != "map":
			continue
		if tab_id.is_empty():
			continue
		menu.call("close")
		if not bool(menu.call("open", tab_id)):
			_failures.append("Could not open %s" % tab_id)
			continue
		for frame in 6:
			await process_frame
		await _shoot("menu_%s" % tab_id, "Menu %s" % tab_id, world)
		if _map_cycle and tab_id == "map":
			await _shoot_map_cycle(menu, world)
		if tab_id == "settings":
			await _shoot_settings_sections(menu, world)
	menu.call("close")
	var manifest := {
		"biome": _biome, "scene": SCENES[_biome], "seed": _seed,
		"display_server": DisplayServer.get_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(),
		"resolution": [root.size.x, root.size.y],
		"fixture": "Stocked party and satchel in production scene; no save or progression proof",
		"frames": _records, "failures": _failures,
		"complete": _failures.is_empty(),
	}
	var file := FileAccess.open("%s/manifest.json" % _output, FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t") + "\n")
	file.close()
	quit(0 if _failures.is_empty() else 1)


func _shoot_map_cycle(menu: Node, world: Node) -> void:
	var bodies: Array = menu.get("_bodies")
	var tab: Node = bodies[int(menu.get("_index"))]
	var buttons: Dictionary = tab.get("_realm_buttons")
	var destinations: Array = buttons.keys()
	# Switch away first, then explicitly select the production realm.
	destinations.erase(_biome)
	destinations.append(_biome)
	for realm: String in destinations:
		if not buttons.has(realm):
			_failures.append("No map region button for %s" % realm)
			continue
		var button := buttons[realm] as Button
		if not button.disabled:
			button.pressed.emit()
		for frame in 8:
			await process_frame
		var displayed := str(tab.call("_display_realm"))
		if displayed != realm:
			_failures.append("Map selection %s displayed %s" % [realm, displayed])
		var previous_count := _records.size()
		await _shoot("map_selected_%s" % realm, "Explicit map region selection: %s" % realm, world)
		if _records.size() > previous_count:
			_records[-1]["selected_realm"] = displayed
			_records[-1]["selected_button_disabled"] = button.disabled
			_records[-1]["available_realms"] = buttons.keys()


func _shoot_settings_sections(menu: Node, world: Node) -> void:
	var bodies: Array = menu.get("_bodies")
	var index := int(menu.get("_index"))
	if index < 0 or index >= bodies.size():
		_failures.append("Settings tab body unavailable")
		return
	var tab := bodies[index] as Node
	var scroll := tab.get("_scroll") as ScrollContainer
	if scroll == null:
		_failures.append("Settings scroll container unavailable")
		return
	for label_and_id: Dictionary in [
		{"label": "Controls", "id": "settings_controls"},
		{"label": "Quick items", "id": "quick_bindings"},
	]:
		var heading: Control = null
		for candidate: Node in tab.find_children("*", "Label", true, false):
			if (candidate as Label).text.strip_edges() == str(label_and_id.label):
				heading = candidate as Control
				break
		if heading == null:
			_failures.append("Settings label %s unavailable" % str(label_and_id.label))
			continue
		scroll.ensure_control_visible(heading)
		for frame in 4:
			await process_frame
		await _shoot(str(label_and_id.id), str(label_and_id.label), world)


func _stock_fixture(game: Node) -> void:
	var party: Variant = game.get("party")
	if party is Object and int((party as Object).call("size")) == 0:
		var creature: Variant = game.call("make_creature", "terrapup")
		if creature != null:
			(party as Object).call("add", creature)
	var inventory: Variant = game.get("inventory")
	if inventory is Object:
		for item_id: String in ["orb_basic", "potion_small", "wood", "stone", "fiber", "berries"]:
			(inventory as Object).call("add", item_id, 3)


func _shoot(frame_id: String, subject: String, world: Node) -> void:
	for frame in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.get_width() != 1920 or image.get_height() != 1080:
		_failures.append("%s: expected 1920x1080 image" % frame_id)
		return
	var path := "%s/%s.jpg" % [_output, frame_id]
	if image.save_jpg(path, 0.87) != OK:
		_failures.append("%s: save failed" % frame_id)
		return
	_records.append({"id": frame_id, "subject": subject, "path": path,
		"scene": str(SCENES[_biome]), "camera": "production CameraRig/Camera3D",
		"ui": true, "player_present": world.get_node_or_null(^"Player") != null})
	print("PHASE2 UI %s -> %s" % [frame_id, path])
