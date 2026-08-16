extends SceneTree

## Does the build selector leave the player anything to look at?
##
##   godot --headless --path . --script tests/smoke_build_menu_footprint.gd
##
## OW11, from the owner: *"building needs to work how Valheim does. you get a
## piece then the menu disappears for you to place it. right now it's asking
## you to build through a menu and you can't see shit."*
##
## The arm-then-place half of that was already right and is not what this
## checks — `build_menu.gd::_pick` arms the piece and closes on the same press,
## and `build_placer.gd` draws a legible ghost the moment it does. What was
## wrong was the panel's footprint while you were still choosing: a fixed
## 1200x680 slab in a `CenterContainer`, which on the Ally's 1920x1080 is an
## opaque rectangle over the middle 63% of the screen — centred on exactly the
## ground the ghost is about to stand on — and mostly empty, because the grid
## was a hard ten columns however few pieces the category actually held.
##
## So this measures the two things that were wrong, at the authoring
## resolution the HUD scale rule judges at (`ENVIRONMENT_AND_UI_BIBLE` §17 —
## 1920x1080, a seven-inch handheld, not a desktop monitor):
##
##   - the centre of the screen is not covered while the menu is open
##   - the panel takes a modest share of the screen rather than most of it
##   - the grid is as wide as the category has pieces, not wider
##
## No world scene is loaded. `Game` is an autoload, which is everything
## `build_menu.gd::open` actually needs, and standing up the Meadows for a
## layout assertion costs ten minutes under software GL for nothing.

const BUILD_MENU := preload("res://scripts/ui/build_menu.gd")

## Layout settles over a couple of frames — the panel's real rect is not
## meaningful until the containers above it have run. Ten is generous.
const LAYOUT_FRAMES := 10

## The largest share of the screen the selector may cover. The docked panel
## measures about 10%; the slab it replaced measured 39%. Twenty sits well
## clear of both, so this fails on a regression toward the slab without
## pinning the exact pixel size of a panel that is allowed to grow with its
## contents.
const MAX_SCREEN_FRACTION := 0.20

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	# Autoloads are added to `root` after this script's `_init` returns, so the
	# lookup below finds nothing on frame zero however simple the test is.
	for i in LAYOUT_FRAMES:
		await process_frame

	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("FAIL: the Game autoload is not in the tree")
		quit(1)
		return

	# Headless opens a 64x64 root regardless of the project's own window size,
	# and every number below is a fraction of the screen — so the authoring
	# resolution is read from ProjectSettings and forced on, rather than
	# trusted to be there. 1920x1080 IS the handheld size (§17: the repo
	# authors at the Ally's native resolution), so this is the seven-inch
	# measurement, not a desktop one.
	var authored := Vector2i(
		int(ProjectSettings.get_setting("display/window/size/viewport_width", 1920)),
		int(ProjectSettings.get_setting("display/window/size/viewport_height", 1080)),
	)
	root.size = authored
	for i in LAYOUT_FRAMES:
		await process_frame

	var screen := Vector2(root.size)
	if screen.x <= 0.0 or screen.y <= 0.0:
		print("FAIL: viewport has no size (%s)" % screen)
		quit(1)
		return
	if screen != Vector2(authored):
		print("FAIL: viewport would not take the authored size (wanted %s, got %s)" % [authored, screen])
		quit(1)
		return

	var menu: CanvasLayer = BUILD_MENU.get_or_make(self)
	menu.call("open")
	for i in LAYOUT_FRAMES:
		await process_frame

	if not bool(menu.call("is_open")):
		_fail("the menu refused to open, so there is nothing to measure")
		_report(screen)
		return

	var panel: PanelContainer = menu.get("_panel")
	if panel == null:
		_fail("build_menu has no _panel to measure")
		_report(screen)
		return

	# Every category, not just whichever one the menu opened on: the panel
	# takes its width from the open category's grid, so the biggest category is
	# the one that decides whether this screen is honest. Measuring only the
	# default would pass a menu that balloons one tab later.
	var categories: Array = menu.get("_categories")
	if categories.is_empty():
		_fail("no categories — the catalogue is empty and nothing was measured")
		_report(screen)
		return

	var worst := Rect2()
	var worst_category := ""
	for i in categories.size():
		menu.call("_select_category", i)
		for f in LAYOUT_FRAMES:
			await process_frame
		var rect := Rect2(panel.global_position, panel.size)
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			_fail("category '%s' laid the panel out with no size (%s)" % [categories[i], rect.size])
			continue
		print("  ..    category '%s': panel %s" % [categories[i], rect])
		_check_grid_fits_its_category(menu, str(categories[i]))
		_check_focus_landed(menu, str(categories[i]))
		if rect.size.x * rect.size.y > worst.size.x * worst.size.y:
			worst = rect
			worst_category = str(categories[i])

	if worst.size.x <= 0.0:
		_fail("no category produced a measurable panel")
		_report(screen)
		return

	print("  ..    widest category is '%s'" % worst_category)
	_check_centre_is_clear(worst, screen)
	_check_footprint(worst, screen)

	_report(screen)


## The one that matters most. A build ghost stands `PLACE_AHEAD` metres in
## front of the player, which draws around the middle of the frame — so a
## selector sitting on the centre point is a selector covering the thing you
## are choosing a piece for.
func _check_centre_is_clear(rect: Rect2, screen: Vector2) -> void:
	var centre := screen * 0.5
	if rect.has_point(centre):
		_fail("the panel covers the centre of the screen: centre %s is inside %s" % [centre, rect])
	else:
		print("  ok    centre %s is clear of the panel %s" % [centre, rect])


func _check_footprint(rect: Rect2, screen: Vector2) -> void:
	var covered := rect.size.x * rect.size.y
	var fraction := covered / (screen.x * screen.y)
	if fraction > MAX_SCREEN_FRACTION:
		_fail("the panel covers %.1f%% of the screen, over the %.0f%% ceiling (%s of %s)" % [
			fraction * 100.0, MAX_SCREEN_FRACTION * 100.0, rect.size, screen,
		])
	else:
		print("  ok    the panel covers %.1f%% of the screen (%s of %s)" % [
			fraction * 100.0, rect.size, screen,
		])


## A ten-column grid holding six pieces is four columns of nothing, and that
## emptiness is most of what the slab was made of. Columns must not run past
## what the open category can fill.
func _check_grid_fits_its_category(menu: CanvasLayer, category: String) -> void:
	var grid: GridContainer = menu.get("_grid")
	if grid == null:
		_fail("build_menu has no _grid to measure")
		return
	var cells: Array = menu.get("_cell_buttons")
	var count := cells.size()
	if count <= 0:
		_fail("category '%s' drew no cells, so the grid width proves nothing" % category)
		return
	if grid.columns > count:
		_fail("category '%s': grid is %d columns wide for %d pieces — %d empty columns" % [
			category, grid.columns, count, grid.columns - count,
		])
	else:
		print("  ok    category '%s': grid is %d columns for %d pieces" % [category, grid.columns, count])


## Switching category has to leave focus ON a cell of the new category.
##
## The grid is the only thing a stick or d-pad can drive on this screen, and
## focus is what it drives — a category switch that lands focus nowhere is a
## build menu a controller cannot use, however well it is laid out. This is
## checked here because making the grid size itself to its contents means
## rebuilding it more sharply than before, and the first version of that change
## did drop focus (`Condition "!is_inside_tree()" is true` out of a deferred
## grab on a cell that had already been unparented).
func _check_focus_landed(menu: CanvasLayer, category: String) -> void:
	var focused := root.gui_get_focus_owner()
	if focused == null:
		_fail("category '%s': nothing has focus after the switch — no cell to drive" % category)
		return
	var cells: Array = menu.get("_cell_buttons")
	if not cells.has(focused):
		_fail("category '%s': focus landed on %s, which is not one of its cells" % [
			category, focused,
		])
		return
	print("  ok    category '%s': focus is on cell %d" % [category, cells.find(focused)])


func _fail(message: String) -> void:
	_failures.append(message)
	print("  FAIL  %s" % message)


func _report(screen: Vector2) -> void:
	print("")
	print("build menu footprint, measured at %s" % screen)
	if _failures.is_empty():
		print("OK")
		quit(0)
		return
	print("%d failure(s)" % _failures.size())
	quit(1)
