extends SceneTree

## Controller contract for the real code-built Craft panel. Test input
## uses synthetic joypad events through the live InputMap, not a hardware pad.

const CRAFT_PANEL := preload("res://scripts/ui/craft_panel.gd")

## Synthetic layout coverage only: expose the real merged recipe catalogue
## without granting any progression or changing production unlock rules.
class CataloguePanel extends "res://scripts/ui/craft_panel.gd":
	func _known_ids() -> Array:
		var ids: Array = _items().recipe_ids()
		ids.sort()
		return ids

var _failures: Array[String] = []
var _game: Node = null
var _panel: CanvasLayer = null
var _layout_measurements: Array[Dictionary] = []
var _layout_cases: Array[Dictionary] = []


func _init() -> void:
	_run()


func _run() -> void:
	if OS.get_cmdline_user_args().has("--baseline-presentation") and OS.get_cmdline_user_args().has("--readable-recipe-rows"):
		_fail("Baseline and readable presentation modes are mutually exclusive")
		_report()
		return
	for i in 10:
		await physics_frame
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_fail("Game autoload is missing")
		_report()
		return
	var inventory: RefCounted = _game.get("inventory")
	inventory.call("add", "wood", 12)
	inventory.call("add", "stone", 12)
	inventory.call("add", "berries", 8)
	inventory.call("add", "fiber", 4)

	_panel = CRAFT_PANEL.new()
	root.add_child(_panel)
	if OS.get_cmdline_user_args().has("--baseline-presentation"):
		_panel.set("_readable_recipe_rows", false)
		_panel.set("_readable_action_hints", false)
		_panel.call("_build")
	if OS.get_cmdline_user_args().has("--readable-recipe-rows"):
		root.size = Vector2i(1920, 1080)
		_panel.set("_readable_recipe_rows", true)
		_panel.set("_readable_action_hints", true)
		_panel.call("_build")
	for i in 8:
		await physics_frame
	_panel.call("open")
	for i in 6:
		await physics_frame

	var rows: Array = _panel.get("_rows")
	var ids: Array = _panel.get("_recipe_ids")
	if rows.is_empty() or ids.is_empty():
		_fail("Craft opened with no recipe rows")
		_report()
		return
	if root.get_viewport().gui_get_focus_owner() != rows[0]:
		_fail("Craft did not focus its first recipe on entry")
	if OS.get_cmdline_user_args().has("--readable-recipe-rows"):
		_assert_readable_row_geometry(rows, ids)

	if rows.size() > 1:
		await _tap_pad(JOY_BUTTON_DPAD_DOWN)
		if root.get_viewport().gui_get_focus_owner() != rows[1]:
			_fail("synthetic D-pad Down did not move between Craft recipes")
		await _tap_pad(JOY_BUTTON_DPAD_UP)
		if root.get_viewport().gui_get_focus_owner() != rows[0]:
			_fail("synthetic D-pad Up did not return to the first Craft recipe")

	var potion_index := ids.find("potion_small")
	if potion_index < 0:
		_fail("baseline Small Potion is absent from the known Craft recipes")
	else:
		for i in potion_index:
			await _tap_pad(JOY_BUTTON_DPAD_DOWN)
		if root.get_viewport().gui_get_focus_owner() != rows[potion_index]:
			_fail("synthetic D-pad could not reach the Small Potion recipe")
		var potion_before := int(inventory.call("count", "potion_small"))
		var berries_before := int(inventory.call("count", "berries"))
		var cost_before := (_panel.get("_cost_labels")[potion_index] as Label).text
		await _tap_pad(JOY_BUTTON_A)
		if int(inventory.call("count", "potion_small")) != potion_before + 1:
			_fail("synthetic A on Small Potion produced no potion")
		if int(inventory.call("count", "berries")) >= berries_before:
			_fail("synthetic A crafted a potion without spending berries")
		if root.get_viewport().gui_get_focus_owner() != rows[potion_index]:
			_fail("Craft lost focus after inventory/cost labels refreshed")
		if OS.get_cmdline_user_args().has("--readable-recipe-rows"):
			var cost_after := (_panel.get("_cost_labels")[potion_index] as Label).text
			if cost_after == cost_before or not cost_after.contains("Berries (have %d)" % inventory.count("berries")) or not cost_after.contains("Fiber (have %d)" % inventory.count("fiber")):
				_fail("Small Potion row did not refresh owned berries/fiber after the synthetic A craft")

	await _tap_pad(JOY_BUTTON_B)
	if bool(_panel.call("is_open")):
		_fail("synthetic B did not close Craft")
	if paused:
		_fail("closing Craft left the tree paused")
	if OS.get_cmdline_user_args().has("--readable-recipe-rows"):
		await _check_catalogue_rasters(inventory)

	_report()


func _assert_readable_row_geometry(rows: Array, ids: Array) -> void:
	for id: String in ["hoe", "ironwood_haft_axe", "ironwood_haft_pickaxe"]:
		var index := ids.find(id)
		if index < 0:
			_fail("Readable-row fixture is missing %s" % id)
			continue
		var row := rows[index] as Control
		var labels := row.find_children("*", "Label", true, false)
		if labels.size() != 2:
			_fail("%s must have a name and a cost label" % id)
		for node: Node in labels:
			var label := node as Label
			var font_height := label.get_theme_font("font").get_height(label.get_theme_font_size("font_size"))
			if label.get_visible_line_count() < 1 or label.size.y + 0.5 < font_height:
				_fail("%s label lacks one full font line: %s (height %.2f, font %.2f)" % [id, label.text, label.size.y, font_height])
			if not row.get_global_rect().grow(0.5).encloses(label.get_global_rect()):
				_fail("%s label extends outside its row: %s" % [id, label.text])


func _check_catalogue_rasters(inventory: RefCounted) -> void:
	var saved_slots: Array = []
	for slot in inventory.slot_count():
		saved_slots.append(inventory.stack_at(slot))
	var db: RefCounted = _game.get("items")
	var checks := 0
	for raster: Vector2i in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		root.content_scale_size = Vector2i(1920, 1080)
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.size = raster
		var panel := CataloguePanel.new()
		root.add_child(panel)
		panel.set_process(false)
		panel.set("_readable_recipe_rows", true)
		panel.set("_readable_action_hints", true)
		panel.call("_build")
		panel.call("open")
		var ids: Array = panel.get("_recipe_ids")
		var rows: Array = panel.get("_rows")
		for index in ids.size():
			if index > 0:
				await _tap_pad(JOY_BUTTON_DPAD_DOWN)
			if root.gui_get_focus_owner() != rows[index]:
				_fail("Synthetic joypad input could not reach catalogue recipe %s at%s" % [ids[index], raster])
			var recipe: Dictionary = db.recipe(str(ids[index]))
			var costs: Array = recipe.get("cost", [])
			# At most one ingredient occupies the whole real24-slot satchel.
			# Choose the longest item label, never impossible simultaneous maxima.
			var max_item := ""
			for entry: Dictionary in costs:
				var item_id := str(entry.get("id", ""))
				if str(db.item_name(item_id)).length() > str(db.item_name(max_item)).length():
					max_item = item_id
			for filled in [false, true]:
				for slot in inventory.slot_count():
					inventory.set_slot(slot, null)
				if filled and not max_item.is_empty():
					inventory.add(max_item, db.stack_size(max_item) * inventory.slot_count())
				panel.call("_select", index)
				panel.call("_poll")
				(panel.get("_status") as Label).text = "Not enough materials for %s." % str(recipe.get("name", ids[index]))
				for _frame in 5:
					await process_frame
				var row := rows[index] as Control
				var row_scale := (root.get_stretch_transform() * row.get_global_transform_with_canvas()).get_scale().abs()
				var focused_style := (row as Button).get_theme_stylebox("focus") as StyleBoxFlat
				var normal_style := (row as Button).get_theme_stylebox("normal") as StyleBoxFlat
				var focus_edge := minf(focused_style.border_width_left * row_scale.x, focused_style.border_width_top * row_scale.y)
				if row.size.y * row_scale.y < 44.0 or (focus_edge < 2.0 and focused_style.bg_color == normal_style.bg_color):
					_fail("%s focus height/edge/filled-state floor failed" % ids[index])
				if index == 0 and not filled:
					print("craft raster actual: window=%s canvas=%s viewport=%s stretch=%s canvasitem_screen=%s row_raster_scale=%s focus_edge=%.3f filled_state=%s" % [root.size, root.content_scale_size, root.get_visible_rect(), root.get_stretch_transform(), row.get_screen_transform(), row_scale, focus_edge, focused_style.bg_color != normal_style.bg_color])
				for node: Node in row.find_children("*", "Label", true, false):
					_check_stress_label(node as Label, row.get_global_rect(), 18.0, raster, str(ids[index]))
					if not (panel.get("_list_scroll") as ScrollContainer).get_global_rect().grow(0.5).encloses((node as Label).get_global_rect()):
						_fail("%s focused label is outside scroll viewport" % ids[index])
				var safe := Rect2(Vector2(48, 48), Vector2(1824, 984))
				var outer := (panel.get("_root") as Node).find_children("*", "PanelContainer", true, false)[0] as Control
				var outer_screen := (root.get_stretch_transform() * outer.get_global_transform_with_canvas()) * Rect2(Vector2.ZERO, outer.size)
				var inset := minf(minf(outer_screen.position.x, outer_screen.position.y), minf(root.size.x-outer_screen.end.x, root.size.y-outer_screen.end.y))
				_layout_cases.append({"recipe":ids[index],"window":str(root.size),"count_mode":"one_item_max" if filled else "empty","max_item":max_item,"owned":inventory.count(max_item),"panel_screen_rect":str(outer_screen),"panel_inset_px":inset,"focus_height_px":row.size.y*row_scale.y,"focus_edge_px":focus_edge,"focus_filled_state":focused_style.bg_color != normal_style.bg_color})
				if inset < 32.0 - 0.5:
					_fail("%s panel safe inset is only%.3fpx at%s" % [ids[index], inset, raster])
				for node: Node in (panel.get("_root") as Node).find_children("*", "Label", true, false):
					var label := node as Label
					if label.text == "Ingredients" or label.text.begins_with("Leave:"):
						_check_stress_label(label, safe, 24.0 if label.text == "Ingredients" else 20.0, raster, str(ids[index]))
				for node: Node in (panel.get("_ingredients_col") as Node).find_children("*", "Label", true, false):
					_check_stress_label(node as Label, safe, 22.0, raster, str(ids[index]))
				for key: String in ["_center_name", "_output_line", "_status", "_craft_hint"]:
					var floor_px := 24.0 if key == "_center_name" else (20.0 if key == "_craft_hint" else 18.0)
					_check_stress_label(panel.get(key) as Label, safe, floor_px, raster, str(ids[index]))
				checks += 1
		panel.call("close")
		panel.queue_free()
		for _frame in 3:
			await process_frame
	for slot in inventory.slot_count():
		inventory.set_slot(slot, null if (saved_slots[slot] as Dictionary).is_empty() else saved_slots[slot])
	print("craft catalogue synthetic layout: %d recipe/count/raster cases; no earned progression proof" % checks)


func _check_stress_label(label: Label, bounds: Rect2, floor_px: float, raster: Vector2i, id: String) -> void:
	var font_size := label.get_theme_font_size("font_size")
	var font_height := label.get_theme_font("font").get_height(font_size)
	# Headless CanvasItem.get_screen_transform omits window stretching; combine
	# the actual Viewport stretch with the item's actual canvas transform.
	var screen_transform := root.get_stretch_transform() * label.get_global_transform_with_canvas()
	var raster_scale := screen_transform.get_scale().abs().y
	var screen_rect := screen_transform * Rect2(Vector2.ZERO, label.size)
	var safe_rect := Rect2(Vector2(32, 32), Vector2(root.size) - Vector2(64, 64))
	_layout_measurements.append({"recipe":id,"text":label.text,"window":str(root.size),"canvas":str(root.content_scale_size),"screen_transform":str(screen_transform),"screen_rect":str(screen_rect),"logical_rect":str(label.get_global_rect()),"logical_bounds":str(bounds),"font_px":font_size*raster_scale,"line_count":label.get_line_count(),"visible_line_count":label.get_visible_line_count()})
	if font_size * raster_scale + 0.01 < floor_px or label.get_visible_line_count() < 1 or label.get_line_count() > label.get_visible_line_count() or label.size.y + 0.5 < font_height or not bounds.grow(0.5).encloses(label.get_global_rect()) or not safe_rect.grow(0.5).encloses(screen_rect):
		_fail("%s @%s: font/visible-line/bounds failure: %s, rect=%s, rasterfont=%.2f" % [id, raster, label.text, label.get_global_rect(), font_size * raster_scale])


func _tap_pad(button_index: int) -> void:
	var down := InputEventJoypadButton.new()
	down.button_index = button_index
	down.pressed = true
	Input.parse_input_event(down)
	for i in 3:
		await physics_frame
	var up := InputEventJoypadButton.new()
	up.button_index = button_index
	up.pressed = false
	Input.parse_input_event(up)
	for i in 5:
		await physics_frame


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--layout-report="):
			var file := FileAccess.open(arg.trim_prefix("--layout-report="), FileAccess.WRITE)
			if file == null:
				_fail("Cannot write requested layout receipt")
			else:
				file.store_string(JSON.stringify({"synthetic_headless_layout_only":true,"failures":_failures,"cases":_layout_cases,"measurements":_layout_measurements}, "\t"))
	print("")
	if _failures.is_empty():
		print("craft panel controller: OK -- navigate, craft, refresh focus, and close use synthetic joypad input.")
		quit(0)
		return
	for line in _failures:
		print("craft panel controller FAIL: %s" % line)
	quit(1)
