extends SceneTree

## Regression for OWNER_DIRECTIVE_2026-09-12 Tier 0 #15. The shipped window
## renders the 1920x1080 UI canvas into 1280x720; controller focus remains on
## the creature row, so the detail pane must reveal both move rows itself.

const WINDOW_SIZE := Vector2i(1280, 720)
const CONTENT_SIZE := Vector2i(1920, 1080)
const TAB_CREATURES := preload("res://scripts/ui/tab_creatures.gd")
## The production shell's 96/56 safe margins and header/tab/status/footer
## chrome leave this logical Content rect at 16:9. Keeping the authored size
## explicit makes this a geometry check, independent of headless display DPI.
const TEAM_CONTENT_SIZE := Vector2(1688, 641)

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	var scale_x := float(WINDOW_SIZE.x) / float(CONTENT_SIZE.x)
	var scale_y := float(WINDOW_SIZE.y) / float(CONTENT_SIZE.y)
	if not is_equal_approx(scale_x, scale_y):
		_fail("1280x720 does not preserve the shipped 1920x1080 content aspect")
		return _report()
	var host := Control.new()
	host.size = TEAM_CONTENT_SIZE
	root.add_child(host)
	var body: Control = TAB_CREATURES.new()
	host.add_child(body)
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.call("build")

	# Exercise the tallest move-adjacent summary seen in normal play. These
	# strings use the real labels and wrapping widths; no font is mocked.
	(body.get("_detail_name") as Label).text = "Layout Test     Lv 50"
	(body.get("_detail_type_label") as Label).text = "Ground"
	(body.get("_detail_hp") as Label).text = "HP  999 / 999"
	(body.get("_detail_stats") as Label).text = "ATK 999    DEF 999"
	(body.get("_detail_traits") as Label).text = "Traits: Gentle, Sturdy"
	(body.get("_detail_trait_desc") as Label).text = \
		"Easygoing around the trainer and the rest of the team.  //  Shrugs off knocks that would stagger others."
	(body.get("_detail_xp") as Label).text = "EXP  999 / 1000"
	(body.get("_detail_xp_next") as Label).text = "Next level: 1 EXP"
	(body.get("_move_quick_name") as Label).text = "Pebble Toss"
	(body.get("_move_quick_tag") as Label).text = "QUICK  ·  GROUND"
	(body.get("_move_quick_sub") as Label).text = "Power x1.0   Energy +26"
	(body.get("_move_charged_name") as Label).text = "Stone Rush"
	(body.get("_move_charged_tag") as Label).text = "CHARGED  ·  GROUND"
	(body.get("_move_charged_sub") as Label).text = "Power x2.4   Cost 100"
	var rows: Array = body.get("_rows")
	await process_frame
	(rows[0] as Button).grab_focus()
	for i in 6:
		await process_frame

	if rows.is_empty() or root.gui_get_focus_owner() != rows[0]:
		_fail("controller focus did not remain on the selected creature row")

	var detail: Control = body.get("_detail_panel")
	var scroll := detail.get_parent() as ScrollContainer
	var quick_icon: Control = body.get("_move_quick_icon")
	var charged_sub: Control = body.get("_move_charged_sub")
	if scroll == null or quick_icon == null or charged_sub == null:
		_fail("Team detail move geometry is missing")
		return _report()

	var viewport_rect := scroll.get_global_rect()
	var move_top := quick_icon.get_global_rect().position.y
	var move_bottom := charged_sub.get_global_rect().end.y
	print("  geometry moves %.1f..%.1f, pane %.1f..%.1f, scroll %d" % [
		move_top, move_bottom, viewport_rect.position.y, viewport_rect.end.y,
		scroll.scroll_vertical,
	])
	var edge_gap := float(TAB_CREATURES.MOVE_STATS_EDGE_GAP)
	if move_top < viewport_rect.position.y - 0.5 \
			or move_bottom > viewport_rect.end.y - edge_gap + 0.5:
		_fail("full move block is outside the visible detail pane: moves %.1f..%.1f, pane %.1f..%.1f" % [
			move_top, move_bottom, viewport_rect.position.y, viewport_rect.end.y,
		])

	_report()


func _fail(message: String) -> void:
	_failures.append(message)
	print("  FAIL  %s" % message)


func _report() -> void:
	if _failures.is_empty():
		print("Team power-move layout at 1280x720: OK")
		quit(0)
	else:
		print("%d failure(s)" % _failures.size())
		quit(1)
