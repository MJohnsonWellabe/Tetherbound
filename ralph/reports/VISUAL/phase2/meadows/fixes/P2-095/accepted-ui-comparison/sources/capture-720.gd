extends "res://tools/phase2_capture_locations.gd"

## Production-scene visual fixture for placed camp, bed, building and craft
## station presentation. Uses BuildPlacer._spawn_building, the production
## player and camera, and the production CraftPanel. No build costs, placement
## validation, sleep, recipe execution, save or progression are demonstrated.

const OPEN_STANDS := {
	"meadows": Vector2(-25.0, 1300.0),
	"water": Vector2(35.707, 98.104),
	"cloudreach": Vector2(-15.5, -202.0),
	"stormwood": Vector2(-320.0, 240.0),
}

class StressPanel extends "res://scripts/ui/craft_panel.gd":
	func _known_ids() -> Array:
		var ids: Array = _items().recipe_ids()
		ids.sort()
		return ids

const STRESS_CASES := [
	{"id":"cloudreach_pickaxe_bracing", "stock":"windworn_heartwood"},
	{"id":"saddle", "stock":"rootstone"},
	{"id":"reinforce_axe", "stock":"rootstone"},
	{"id":"water_trail_preserve", "stock":"cloudberry"},
]
var _expected_raster := Vector2i(1920,1080)
var _stress := false
var _case_id := ""
var _ui_receipt: Dictionary = {}
var _craft_panel: CanvasLayer

func _parse_args() -> bool:
	_stress = OS.get_cmdline_user_args().has("--craft-stress")
	if OS.get_cmdline_user_args().has("--craft-raster=720"):
		_expected_raster = Vector2i(1280,720)
	if _stress != (_expected_raster == Vector2i(1280,720)):
		push_error("This bounded package uses720 only for the four explicit stress cases")
		return false
	return super._parse_args()


func _load_plan() -> bool:
	_planned = [{"frame_id": "%s__system__build_suite" % _biome_id}]
	return true


func _begin_manifest() -> void:
	super._begin_manifest()
	_manifest["expected_raster"] = [_expected_raster.x,_expected_raster.y]
	_manifest["synthetic_catalogue_stress"] = _stress
	_manifest["resolved_user_data_dir"] = OS.get_user_data_dir()
	_manifest["settings_present_at_start"] = FileAccess.file_exists("user://settings.json")
	_manifest["fixture_disclosure"] = "Visual-only production-scene fixture: player debug-travels to an open authored spot; BuildPlacer creates real tent, campfire, bedroll, floor, wall and workbench nodes near the player; CraftPanel opened directly. No placement cost, interaction, sleep, recipe result or saved state proof."


func _finish(_complete: bool) -> void:
	if _stress:
		_planned.assign(STRESS_CASES.map(func(spec: Dictionary) -> Dictionary: return {"frame_id":"%s__craft_stress__%s" % [_biome_id,str(spec.id)]}))
		_manifest["planned_frame_ids"] = _planned.map(func(spec: Dictionary) -> String: return str(spec.frame_id))
	super._finish(_failures.is_empty() and _records.size() == (4 if _stress else 1))


func _capture_row(_row: Dictionary) -> void:
	if root.size != _expected_raster or root.content_scale_size != Vector2i(1920,1080):
		_failures.append("Unexpected actual raster or authored canvas: %s / %s" % [root.size,root.content_scale_size])
		return
	var game := root.get_node_or_null(^"Game")
	var placer := _world.find_child("BuildPlacer", true, false)
	if game == null or placer == null or not placer.has_method("_spawn_building"):
		_failures.append("production BuildPlacer unavailable")
		return
	var stand: Vector2 = OPEN_STANDS[_biome_id]
	if not bool(game.call("debug_teleport_to", stand.x, stand.y, _biome_id, "")):
		_failures.append("debug travel to open build stand failed")
		return
	for _frame in ARRIVE_FRAMES:
		await physics_frame
	var stand_y := float(_world.call("ground_height_at", stand.x, stand.y))
	if is_nan(stand_y):
		_failures.append("open build stand has no terrain")
		return
	_player.global_position = Vector3(stand.x, stand_y + TRAINER_CLEARANCE, stand.y)
	_player.velocity = Vector3.ZERO
	var heading := Vector2(0.0, 1.0)
	var yaw := capture_yaw(heading)
	_player.rotation.y = atan2(heading.x, heading.y)
	_rig.call("set_target", _player)
	_rig.set("pitch", deg_to_rad(-12.0))
	_rig.set("yaw", yaw)
	_rig.rotation = Vector3(deg_to_rad(-12.0), yaw, 0.0)
	_rig.global_position = _player.global_position
	_camera.make_current()
	_player.reset_physics_interpolation()
	_rig.reset_physics_interpolation()
	_camera.reset_physics_interpolation()
	for _frame in POPULATE_FRAMES:
		await physics_frame
	var observed := await _pin_time("day")
	if observed.is_empty():
		return
	var forward := -_camera.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	if forward.length() < 0.5:
		forward = Vector3.FORWARD
	var side := Vector3(-forward.z, 0.0, forward.x)
	var anchor := _player.global_position + forward * 5.0
	var ground := float(_world.call("ground_height_at", anchor.x, anchor.z))
	if is_nan(ground):
		ground = _player.global_position.y - 0.3
	anchor.y = ground
	var active: Array[Node3D] = []
	var tent := _place(placer, game, "tent", anchor, active)
	_place(placer, game, "campfire", anchor + side * 3.0, active)
	if tent == null:
		_failures.append("tent could not be created")
		return
	await _settle()
	await _shoot("camp", "camp", "placed camp tent and campfire visual fixture")
	_clear(active)
	await _settle()
	_place(placer, game, "bedroll", anchor + side * 3.0, active)
	await _settle()
	await _shoot("bed", "bed", "placed bedroll visual fixture")
	_clear(active)
	await _settle()
	_place(placer, game, "floor", anchor, active)
	_place(placer, game, "wall", anchor + side * 2.0, active)
	await _settle()
	await _shoot("building", "building", "placed floor and wall visual fixture")
	_clear(active)
	await _settle()
	_place(placer, game, "workbench", anchor, active)
	await _settle()
	placer.call("_open_craft_panel")
	_craft_panel = placer.get("_craft_panel") as CanvasLayer
	if _craft_panel == null:
		_failures.append("craft capture requires the production CraftPanel")
		return
	if _stress:
		_craft_panel.call("close")
		_craft_panel = StressPanel.new()
		root.add_child(_craft_panel)
		_manifest["stress_disclosure"] = "Synthetic presentation-only catalogue exposure via _known_ids override on production CraftPanel; no unlock flags or world progression granted. Each image has only the named ingredient filling24legal slots, all other inventory slots empty. No crafting transaction is invoked. Refusal text is staged for fit."
	var readable_rows := OS.get_cmdline_user_args().has("--craft-readable-preview")
	var readable_hints := OS.get_cmdline_user_args().has("--craft-hints-preview")
	if readable_rows or readable_hints:
		_craft_panel.call("close")
		if readable_rows:
			_craft_panel.set("_readable_recipe_rows", true)
		if readable_hints:
			_craft_panel.set("_readable_action_hints", true)
		_craft_panel.call("_build")
		_craft_panel.call("open")
		_manifest["craft_readable_preview"] = readable_rows
		_manifest["craft_hints_preview"] = readable_hints
	if _stress:
		_craft_panel.call("open")
		await _capture_stress_cases()
		return
	await _settle()
	if not await _position_defect_rows():
		return
	await _shoot("crafting", "crafting", "workbench and production CraftPanel directly opened")
	_write_manifest()


func _place(placer: Node, game: Node, id: String, at: Vector3, active: Array[Node3D]) -> Node3D:
	var piece := placer.call("_spawn_building", game, id) as Node3D
	if piece == null:
		_failures.append("failed to create %s" % id)
		return null
	piece.global_position = at
	active.append(piece)
	return piece


func _clear(active: Array[Node3D]) -> void:
	for piece: Node3D in active:
		if is_instance_valid(piece):
			piece.queue_free()
	active.clear()


func _settle() -> void:
	for _frame in 16:
		await physics_frame
	for _frame in 3:
		await process_frame


func _shoot(state: String, system: String, note: String) -> void:
	if state != "crafting":
		return
	_hide_hud()
	if state == "crafting":
		if not is_instance_valid(_craft_panel):
			_failures.append("craft panel unavailable when saving the frame")
			return
		_craft_panel.visible = true
	await RenderingServer.frame_post_draw
	if not _collect_ui_receipt():
		# Invalid captures are diagnostic evidence, never successful frame records.
		var failure_path := "%s/FAILED_%s.jpg" % [_output_dir,_case_id]
		var failure_image := root.get_texture().get_image()
		var saved := false
		if failure_image != null and not failure_image.is_empty():
			saved = failure_image.save_jpg(failure_path,0.87) == OK
		_manifest["failed_ui_capture"] = {"acceptance_evidence":false,"image":failure_path,"image_saved":saved,"ui":_ui_receipt.duplicate(true),"failures":_failures.duplicate()}
		_write_manifest()
		return
	var frame_id := "%s__craft_stress__%s" % [_biome_id,_case_id] if _stress else "%s__system__%s" % [_biome_id, state]
	var path := "%s/%s.jpg" % [_output_dir, frame_id]
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.get_width() != _expected_raster.x or image.get_height() != _expected_raster.y or image.save_jpg(path, 0.87) != OK:
		_failures.append("%s: viewport save failed" % frame_id)
		return
	_records.append({
		"frame_id": frame_id, "identity": "%s__system__build_suite" % _biome_id,
		"destination_display_name": system, "system": system, "view": "ui" if state == "crafting" else "normal",
		"time": "day", "file": path, "note": note, "ui":_ui_receipt.duplicate(true),
		"player_position": _vec3(_player.global_position),
		"camera_position": _vec3(_camera.global_position),
	})
	_write_manifest()


## Capture-only scroll/focus: same authored recipes and selection in both sets.
func _position_defect_rows() -> bool:
	for _frame in 3:
		await process_frame
	var ids: Array = _craft_panel.get("_recipe_ids")
	var rows: Array = _craft_panel.get("_rows")
	var costs: Array = _craft_panel.get("_cost_labels")
	var scroll := _craft_panel.get("_list_scroll") as ScrollContainer
	var first := ids.find("hoe")
	var selected := ids.find("ironwood_haft_axe")
	if first < 0 or selected < 0 or ids.find("ironwood_haft_pickaxe") < 0 or scroll == null:
		_failures.append("Expected Hoe and both Ironwood Haft recipes missing")
		return false
	(rows[selected] as Button).grab_focus()
	for _frame in 2:
		await process_frame
	scroll.scroll_vertical = int((rows[first] as Control).position.y)
	for _frame in 2:
		await process_frame
	var visible_rows: Array[Dictionary] = []
	var fully_visible_ids: Array[String] = []
	var wood_stone := false
	var required_labels_ok := true
	var viewport := scroll.get_global_rect()
	for index: int in rows.size():
		var row := rows[index] as Control
		if not viewport.intersects(row.get_global_rect()):
			continue
		var labels: Array[String] = []
		var label_geometry: Array[Dictionary] = []
		for node: Node in row.find_children("*", "Label", true, false):
			var label := node as Label
			labels.append(label.text)
			var rect := label.get_global_rect()
			var font_height := label.get_theme_font("font").get_height(label.get_theme_font_size("font_size"))
			var contained := row.get_global_rect().grow(0.5).encloses(rect) and viewport.grow(0.5).encloses(rect)
			var readable_geometry := label.is_visible_in_tree() and label.get_visible_line_count() > 0 and rect.size.y + 0.5 >= font_height and contained
			if bool(_craft_panel.get("_readable_recipe_rows")) and label.get_visible_line_count() < label.get_line_count():
				readable_geometry = false
			label_geometry.append({"text":label.text,"rect":str(rect),"height":rect.size.y,"font_height":font_height,"visible_line_count":label.get_visible_line_count(),"contained":contained,"readable_geometry":readable_geometry})
			if str(ids[index]) in ["hoe", "ironwood_haft_axe", "ironwood_haft_pickaxe"]:
				required_labels_ok = required_labels_ok and readable_geometry
		if str(ids[index]) in ["hoe", "ironwood_haft_axe", "ironwood_haft_pickaxe"] and label_geometry.size() != 2:
			required_labels_ok = false
		var row_rect := row.get_global_rect()
		var full_vertical := row_rect.position.y >= viewport.position.y - 0.5 and row_rect.end.y <= viewport.end.y + 0.5
		var cost_label := costs[index] as Label
		var cost := cost_label.text
		var cost_rect := cost_label.get_global_rect()
		var cost_full_vertical := full_vertical and cost_rect.position.y >= row_rect.position.y - 0.5 and cost_rect.end.y <= row_rect.end.y + 0.5
		wood_stone = wood_stone or (cost_full_vertical and cost.contains("Wood") and cost.contains("Stone"))
		if full_vertical:
			fully_visible_ids.append(str(ids[index]))
		visible_rows.append({"recipe_id":str(ids[index]),"labels":labels,"label_geometry":label_geometry,"cost_text":cost,
			"full_vertical":full_vertical,"cost_full_vertical":cost_full_vertical,
			"row_rect":str(row_rect),"cost_rect":str(cost_rect),"visible_rect":str(viewport.intersection(row_rect))})
	_manifest["craft_visible_rows"] = visible_rows
	_manifest["craft_selected_recipe"] = str(ids[int(_craft_panel.get("_selected"))])
	_manifest["craft_readable_preview"] = bool(_craft_panel.get("_readable_recipe_rows"))
	_manifest["craft_hints_preview"] = bool(_craft_panel.get("_readable_action_hints"))
	_manifest["craft_scroll_vertical"] = scroll.scroll_vertical
	_manifest["fixture_defect_focus"] = "Actual Hoe Wood/Stone preview and both Ironwood Haft names; scroll/focus only, no craft/progression injection"
	if not required_labels_ok or not fully_visible_ids.has("ironwood_haft_axe") or not fully_visible_ids.has("ironwood_haft_pickaxe") or not wood_stone:
		_failures.append("Target names/costs lack full visible font lines inside recipe rows and scroll viewport")
		return false
	return true


func _capture_stress_cases() -> void:
	var inventory: RefCounted = root.get_node("Game").get("inventory")
	var db: RefCounted = root.get_node("Game").get("items")
	var saved: Array = []
	for slot in inventory.slot_count():
		saved.append(inventory.stack_at(slot))
	_craft_panel.set_process(false)
	var ids: Array = _craft_panel.get("_recipe_ids")
	for spec: Dictionary in STRESS_CASES:
		_case_id = str(spec.id)
		var index := ids.find(_case_id)
		if index < 0:
			_failures.append("Actual catalogue lacks stress recipe:"+_case_id)
			break
		for slot in inventory.slot_count():
			inventory.set_slot(slot,null)
		var maximum: int = db.stack_size(str(spec.stock)) * inventory.slot_count()
		if inventory.add(str(spec.stock),maximum) != 0 or inventory.count(str(spec.stock)) != maximum:
			_failures.append("Legal stock fixture rejected:"+str(spec.stock))
			break
		# Rebuild after stock changes so baseline and candidate see identical counts.
		_craft_panel.call("_build")
		# Focus callbacks require the rebuilt row geometry to have settled.
		for _layout_frame in 6:
			await process_frame
		_craft_panel.call("_select",index)
		(_craft_panel.get("_status") as Label).text = "Not enough materials for %s." % str(db.recipe(_case_id).get("name",_case_id))
		var rows: Array = _craft_panel.get("_rows")
		(rows[index] as Button).grab_focus()
		for _frame in 6:
			await process_frame
		await _shoot("crafting","crafting","Synthetic catalogue/one-item legal maximum stock, staged refusal text; no earned progression or craft transaction")
		if not _failures.is_empty():
			break
	for slot in inventory.slot_count():
		inventory.set_slot(slot,null if (saved[slot] as Dictionary).is_empty() else saved[slot])


func _collect_ui_receipt() -> bool:
	if root.size != _expected_raster or root.content_scale_size != Vector2i(1920,1080):
		_failures.append("Actual raster/canvas changed before capture")
		return false
	var ids: Array = _craft_panel.get("_recipe_ids")
	var index := int(_craft_panel.get("_selected"))
	var expected := _case_id if _stress else "ironwood_haft_axe"
	if index < 0 or index >= ids.size() or str(ids[index]) != expected:
		_failures.append("Wrong selected recipe before capture")
		return false
	var candidate := bool(_craft_panel.get("_readable_recipe_rows"))
	var inventory: RefCounted = root.get_node("Game").get("inventory")
	var stock: Array = []
	for slot in inventory.slot_count():
		var value: Dictionary = inventory.stack_at(slot)
		if not value.is_empty():
			stock.append({"slot":slot,"id":str(value.id),"n":int(value.n)})
	var display_size := DisplayServer.window_get_size()
	_ui_receipt = {"selected_recipe":expected,"window":[root.size.x,root.size.y],"display_window":[display_size.x,display_size.y],"canvas":[root.content_scale_size.x,root.content_scale_size.y],"stretch":str(root.get_stretch_transform()),"rows_preview":candidate,"hints_preview":bool(_craft_panel.get("_readable_action_hints")),"stock":stock,"labels":[]}
	var db: RefCounted = root.get_node("Game").get("items")
	var expected_detail := str(db.recipe(expected).get("name",expected))
	var actual_detail := (_craft_panel.get("_center_name") as Label).text
	_ui_receipt["detail_recipe_name"] = actual_detail
	_ui_receipt["expected_detail_recipe_name"] = expected_detail
	if actual_detail != expected_detail:
		_failures.append("Selected recipe detail does not match requested recipe")
		return false
	if display_size != _expected_raster:
		_failures.append("Actual display window size differs from requested raster")
		return false
	var outer := (_craft_panel.get("_root") as Node).find_children("*","PanelContainer",true,false)[0] as Control
	var outer_rect := (root.get_stretch_transform() * outer.get_global_transform_with_canvas()) * Rect2(Vector2.ZERO,outer.size)
	var inset := minf(minf(outer_rect.position.x,outer_rect.position.y),minf(root.size.x-outer_rect.end.x,root.size.y-outer_rect.end.y))
	_ui_receipt["panel_screen_rect"] = str(outer_rect)
	_ui_receipt["panel_inset_px"] = inset
	if candidate and inset < 32.0-0.5:
		_failures.append("Candidate panel has less than32px actual safe inset")
		return false
	var row: Control = _craft_panel.get("_rows")[index]
	var scroll: ScrollContainer = _craft_panel.get("_list_scroll")
	var scrollbar := scroll.get_v_scroll_bar()
	_ui_receipt["selection_geometry"] = {"selected_index":index,"row_path":str(row.get_path()),"row_rect":str(row.get_global_rect()),"scroll_rect":str(scroll.get_global_rect()),"scroll_value":scrollbar.value,"scroll_max":scrollbar.max_value,"scroll_page":scrollbar.page,"focused":root.gui_get_focus_owner() == row,"row_visible":row.is_visible_in_tree(),"row_contained":scroll.get_global_rect().grow(0.5).encloses(row.get_global_rect())}
	# Baseline text truncation is allowed; an off-screen/unfocused requested row is not.
	if not _ui_receipt.selection_geometry.focused or not _ui_receipt.selection_geometry.row_visible or not _ui_receipt.selection_geometry.row_contained:
		_failures.append("Requested selected recipe row is not focused and fully visible")
	for node: Node in row.find_children("*","Label",true,false):
		if not _check_ui_label(node as Label,18.0,row.get_global_rect().intersection(scroll.get_global_rect()),candidate):
			return false
	var safe_logical := Rect2(Vector2(48,48),Vector2(1824,984))
	for node: Node in (_craft_panel.get("_ingredients_col") as Node).find_children("*","Label",true,false):
		if not _check_ui_label(node as Label,22.0,safe_logical,candidate):
			return false
	for key: String in ["_center_name","_output_line","_status","_craft_hint"]:
		var label: Label = _craft_panel.get(key)
		if label.text.is_empty():
			continue
		var floor_px := 24.0 if key == "_center_name" else (20.0 if key == "_craft_hint" else 18.0)
		if not _check_ui_label(label,floor_px,safe_logical,candidate):
			return false
	for node: Node in (_craft_panel.get("_root") as Node).find_children("*","Label",true,false):
		var label := node as Label
		if label.text == "Ingredients" or label.text.begins_with("Leave:"):
			if not _check_ui_label(label,24.0 if label.text == "Ingredients" else 20.0,safe_logical,candidate):
				return false
	return _failures.is_empty()


func _check_ui_label(label: Label, floor_px: float, bounds: Rect2, strict: bool) -> bool:
	var transform := root.get_stretch_transform() * label.get_global_transform_with_canvas()
	var font_size := label.get_theme_font_size("font_size")
	var font_height := label.get_theme_font("font").get_height(font_size)
	var font_px := font_size * transform.get_scale().abs().y
	var rect := label.get_global_rect()
	var full := label.get_visible_line_count() >= label.get_line_count() and bounds.grow(0.5).encloses(rect)
	var role := "other_label"
	var selected_row: Node = _craft_panel.get("_rows")[int(_craft_panel.get("_selected"))]
	if selected_row.is_ancestor_of(label):
		role = "selected_row_cost" if (_craft_panel.get("_cost_labels") as Array).has(label) else "selected_row_name"
	for key: String in ["_center_name","_output_line","_status","_craft_hint"]:
		if _craft_panel.get(key) == label:
			role = key
	var metric := {"node_path":str(label.get_path()),"role":role,"text":label.text,"font_size":font_size,"font_height":font_height,"font_px":font_px,"required_font_px":floor_px,"logical_rect":str(rect),"bounds":str(bounds),"screen_rect":str(transform*Rect2(Vector2.ZERO,label.size)),"transform":str(transform),"line_count":label.get_line_count(),"visible_line_count":label.get_visible_line_count(),"visible_in_tree":label.is_visible_in_tree(),"clip_text":label.clip_text,"autowrap_mode":label.autowrap_mode,"max_lines_visible":label.max_lines_visible,"complete_contained":full}
	_ui_receipt.labels.append(metric)
	# Baseline clipping/small-font defects are evidence, not capture failures.
	if not label.is_visible_in_tree() or label.get_visible_line_count() < 1 or label.size.y + 0.5 < font_height or (strict and (not full or font_px+0.01 < floor_px)):
		_failures.append("Selected UI label failed actual geometry:"+label.text)
		return false
	return true
