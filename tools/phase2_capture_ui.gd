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
var _map_zoom_samples := false
var _paired_720 := false
var _tabs: Array[String] = []
var _idle_hud := false
var _build_states := false
var _save_state := false
var _idle_observation: Dictionary = {}
var _records: Array[Dictionary] = []
var _failures: Array[String] = []
var _stage := "boot"


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
		elif arg == "--map-zoom-samples":
			_map_zoom_samples = true
		elif arg == "--paired-720":
			_paired_720 = true
		elif arg.begins_with("--tabs="):
			for id: String in arg.trim_prefix("--tabs=").split(",", false):
				_tabs.append(id.strip_edges())
		elif arg == "--idle-hud":
			_idle_hud = true
		elif arg == "--build-states":
			_build_states = true
		elif arg == "--save-state":
			_save_state = true
	if not SCENES.has(_biome) or not _output.begins_with("res://ralph/reports/VISUAL/phase2/"):
		push_error("Use --biome and --output under the Phase 2 evidence directory")
		quit(1)
		return
	var menu_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MENU_DATA))
	if not menu_data is Dictionary:
		push_error("Menu data invalid")
		quit(1)
		return
	var available_tabs: Array[String] = []
	for definition: Variant in (menu_data as Dictionary).get("tabs", []):
		if definition is Dictionary:
			available_tabs.append(str(definition.get("id", "")))
	for requested: String in _tabs:
		if requested.is_empty() or requested not in available_tabs:
			push_error("Requested capture tab is unavailable: " + requested)
			quit(1)
			return
	if (_map_cycle or _map_zoom_samples) and not _tabs.is_empty() and "map" not in _tabs:
		push_error("Map evidence flags require map in the requested tab set")
		quit(1)
		return
	if _build_states and ((_map_cycle and _tabs.is_empty()) or (not _tabs.is_empty() and "build" not in _tabs)):
		push_error("Build state evidence requires build in the requested tab set")
		quit(1)
		return
	if _save_state and ((_map_cycle and _tabs.is_empty()) or (not _tabs.is_empty() and "save" not in _tabs)):
		push_error("Save state evidence requires save in the requested tab set")
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
	if _idle_hud:
		# Observe the real temporary roster reveal expire; never hide UI for a shot.
		var hud := world.get_node_or_null(^"PlaygroundHUD")
		var strip: Control = hud.get("_party_strip") as Control if hud != null else null
		var idle_deadline := Time.get_ticks_msec() + 300000
		# Use the real handheld raster while observing the capped per-frame
		# timer on Mesa. The timer and widget state are never advanced by us.
		root.size = Vector2i(1280, 720)
		var observed_frames := 0
		var observation_started := Time.get_ticks_msec()
		_stage = "observing_natural_roster_expiry"
		_write_manifest(false)
		while strip != null and strip.visible and Time.get_ticks_msec() < idle_deadline:
			await process_frame
			observed_frames += 1
			_idle_observation = {"raster": [root.size.x, root.size.y],
				"frames": observed_frames, "elapsed_ms": Time.get_ticks_msec() - observation_started,
				"visible": strip.visible, "fade_timer": strip.get("_fade_timer"),
				"pinned": strip.get("_pinned"), "readable_presentation": strip.get("_readable_presentation")}
			if observed_frames % 20 == 0:
				_write_manifest(false)
		root.size = Vector2i(1920, 1080)
		_write_manifest(false)
		if strip == null or strip.visible:
			_failures.append("Real exploration roster did not reach its natural idle state")
		else:
			await _shoot("exploration_hud_idle", "HUD after natural temporary roster expiry", world)
	for raw_tab: Variant in (menu_data as Dictionary).get("tabs", []):
		if not raw_tab is Dictionary:
			continue
		var tab_id := str((raw_tab as Dictionary).get("id", ""))
		if not _tabs.is_empty() and tab_id not in _tabs:
			continue
		if _map_cycle and _tabs.is_empty() and tab_id != "map":
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
		if tab_id == "map" and _map_zoom_samples:
			await _shoot_map_zoom_samples(menu, world)
		if tab_id == "settings":
			await _shoot_settings_sections(menu, world)
		if tab_id == "build" and _build_states:
			await _shoot_build_states(menu, world, game)
		if tab_id == "save" and _save_state:
			await _shoot_populated_save(menu, world, game)
	_stage = "closing_menu"
	_write_manifest(false)
	menu.call("close")
	_stage = "finished"
	_write_manifest(_failures.is_empty())
	quit(0 if _failures.is_empty() else 1)


## Retain truthful partial receipts if a hosted cap interrupts a later stage.
## Completion still requires the entire requested capture to finish.
func _write_manifest(complete: bool) -> void:
	var manifest := {
		"biome": _biome, "scene": SCENES[_biome], "seed": _seed,
		"display_server": DisplayServer.get_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(),
		"resolution": [root.size.x, root.size.y],
		"fixture": "Stocked party and satchel in production scene; no save or progression proof",
		"map_cycle": _map_cycle,
		"map_zoom_samples": _map_zoom_samples,
		"paired_720": _paired_720,
		"requested_tabs": _tabs,
		"natural_idle_hud": _idle_hud,
		"natural_idle_observation": _idle_observation,
		"build_preference_states": _build_states,
		"populated_save_state": _save_state,
		"map_landmarks_sha256": FileAccess.get_sha256("res://data/config/map_landmarks.json"),
		"input_contexts_sha256": FileAccess.get_sha256("res://data/config/input_contexts.json"),
		"project_sha256": FileAccess.get_sha256("res://project.godot"),
		"frames": _records, "failures": _failures,
		"stage": _stage, "elapsed_ms": Time.get_ticks_msec(),
		"complete": complete,
	}
	var file := FileAccess.open("%s/manifest.json" % _output, FileAccess.WRITE)
	if file == null:
		_failures.append("UI capture manifest could not be opened")
		push_error(_failures.back())
		return
	file.store_string(JSON.stringify(manifest, "\t") + "\n")
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		_failures.append("UI capture manifest could not be flushed")
		push_error(_failures.back())


## Exercise the existing preference button and real Build banner, without
## inventing stock, unlocking recipes or claiming controller navigation.
func _shoot_build_states(menu: Node, world: Node, game: Node) -> void:
	var original := bool(game.get("free_build"))
	for enabled: bool in [false, true]:
		if not await _choose_free_build(menu, game, enabled):
			break
		menu.call("close")
		if not bool(menu.call("open", "build")):
			_failures.append("Could not reopen Build for preference state")
			break
		for frame in 6:
			await process_frame
		var bodies: Array = menu.get("_bodies")
		var index := int(menu.get("_index"))
		var tab: Node = bodies[index] if index >= 0 and index < bodies.size() else null
		var banner: Label = tab.get("_free_note") as Label if tab != null else null
		if banner == null or banner.visible != enabled or bool(game.get("free_build")) != enabled:
			_failures.append("Build preference state and real banner disagree")
			break
		await _shoot("menu_build_free_%s" % ("on" if enabled else "off"),
			"Real Build banner; Settings button activation, free build %s" % ("on" if enabled else "off"), world)
	if not await _choose_free_build(menu, game, original):
		_failures.append("Could not restore original free-build preference")
	menu.call("close")


func _choose_free_build(menu: Node, game: Node, enabled: bool) -> bool:
	if bool(game.get("free_build")) == enabled:
		return true
	menu.call("close")
	if not bool(menu.call("open", "settings")):
		_failures.append("Could not open Settings for Build state capture")
		return false
	for frame in 6:
		await process_frame
	var bodies: Array = menu.get("_bodies")
	var index := int(menu.get("_index"))
	var tab: Node = bodies[index] if index >= 0 and index < bodies.size() else null
	var button: Button = tab.get("_free_build_button") as Button if tab != null else null
	if button == null or button.disabled:
		_failures.append("Existing Free build preference button unavailable")
		return false
	button.pressed.emit()
	if bool(game.get("free_build")) != enabled:
		_failures.append("Existing Free build button did not select requested state")
		return false
	return true


## Produce a real UI-written checkpoint from the existing disclosed stock.
## Never overwrite a slot or claim an earned journey or reload proof.
func _shoot_populated_save(menu: Node, world: Node, game: Node) -> void:
	var bodies: Array = menu.get("_bodies")
	var index := int(menu.get("_index"))
	var tab: Node = bodies[index] if index >= 0 and index < bodies.size() else null
	var rows: Array = tab.get("_rows") if tab != null else []
	var slot := -1
	for candidate in range(1, rows.size()):
		if not bool(game.call("has_save", candidate)):
			slot = candidate
			break
	if slot < 0:
		_failures.append("No empty manual save slot; capture refuses to overwrite")
		return
	var button: Button = rows[slot].get("save") as Button
	if button == null or button.disabled:
		_failures.append("Existing manual Save button unavailable")
		return
	button.pressed.emit()
	for frame in 6:
		await process_frame
	if not bool(game.call("has_save", slot)):
		_failures.append("Real Save button did not write its empty manual slot")
		return
	var info: Dictionary = game.call("save_slot_info", slot)
	var party: Object = game.get("party")
	if party == null or int(info.get("party_size", -1)) != int(party.call("size")):
		_failures.append("Written manual save summary does not match the captured party")
		return
	var before := _records.size()
	await _shoot("menu_save_populated", "Real manual Save button wrote empty slot %d; disclosed stock, not earned play" % (slot + 1), world)
	for record_index in range(before, _records.size()):
		_records[record_index]["save_slot"] = slot
		_records[record_index]["save_slot_info"] = info.duplicate(true)
	_write_manifest(false)


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


## Observe the existing map at each supported zoom without changing survey
## data, discovered landmarks or the remembered player zoom. Direct view-state
## adjustment is disclosed; these images do not prove controller navigation.
func _shoot_map_zoom_samples(menu: Node, world: Node) -> void:
	var bodies: Array = menu.get("_bodies")
	var index := int(menu.get("_index"))
	if index < 0 or index >= bodies.size():
		_failures.append("Map tab body unavailable")
		return
	var tab := bodies[index] as Node
	var canvas := tab.get("_canvas") as Control
	if canvas == null:
		_failures.append("Map canvas unavailable")
		return
	var original_zoom := float(tab.get("_zoom"))
	for zoom_level: float in [4.0, 8.0, 16.0, 32.0]:
		tab.set("_zoom", zoom_level)
		tab.call("_clamp_pan")
		canvas.queue_redraw()
		await _shoot("menu_map_zoom_%d" % int(zoom_level),
			"Map at %dx; direct view-state fixture, original fog and discoveries" % int(zoom_level), world)
	tab.set("_zoom", original_zoom)
	tab.call("_clamp_pan")
	canvas.queue_redraw()


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
		print("PHASE2 UI settings heading search: ", label_and_id.id)
		var heading: Control = null
		for candidate: Node in tab.find_children("*", "Label", true, false):
			if (candidate as Label).text.strip_edges() == str(label_and_id.label):
				heading = candidate as Control
				break
		if heading == null:
			print("PHASE2 UI settings heading unavailable: ", label_and_id.id)
			_failures.append("Settings label %s unavailable" % str(label_and_id.label))
			continue
		print("PHASE2 UI settings scroll begin: ", label_and_id.id, " heading=", heading.get_path())
		scroll.ensure_control_visible(heading)
		# Minimal visibility can leave only the heading at the bottom. Align the
		# section start to the viewport so its actual binding rows are captured.
		for frame in 2:
			await process_frame
		scroll.scroll_vertical += int(heading.global_position.y - scroll.global_position.y)
		print("PHASE2 UI settings scroll returned: ", label_and_id.id)
		for frame in 4:
			await process_frame
		print("PHASE2 UI settings deferred frames complete: ", label_and_id.id)
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
	await _shoot_raster(frame_id, subject, world, Vector2i(1920, 1080))
	if _paired_720:
		await _shoot_raster(frame_id + "_1280x720", subject, world, Vector2i(1280, 720))
		root.size = Vector2i(1920, 1080)
		for frame in 4:
			await process_frame


func _shoot_raster(frame_id: String, subject: String, world: Node, size: Vector2i) -> void:
	root.size = size
	for frame in 4:
		await process_frame
	print("PHASE2 UI draw wait: ", frame_id)
	await RenderingServer.frame_post_draw
	print("PHASE2 UI draw completed: ", frame_id)
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.get_size() != size:
		_failures.append("%s: expected %dx%d image" % [frame_id, size.x, size.y])
		return
	var path := "%s/%s.jpg" % [_output, frame_id]
	if image.save_jpg(path, 0.87) != OK:
		_failures.append("%s: save failed" % frame_id)
		return
	_records.append({"id": frame_id, "subject": subject, "path": path,
		"scene": str(SCENES[_biome]), "camera": "production CameraRig/Camera3D",
		"resolution": [image.get_width(), image.get_height()],
		"ui": true, "elapsed_ms": Time.get_ticks_msec(),
		"player_present": world.get_node_or_null(^"Player") != null})
	print("PHASE2 UI %s -> %s" % [frame_id, path])
	_stage = "captured:" + frame_id
	_write_manifest(false)
