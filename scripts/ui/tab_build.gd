extends "res://scripts/ui/menu_tab.gd"

## The pause menu's entry point into the real build screen, `build_menu.gd`
## (`docs/decisions/D34`, spec 12).
##
## Used to be a flat catalogue list drawn entirely in here — that list is
## gone. `build_menu.gd` is the Valheim-style panel now: category tabs, a
## dense thumbnail grid, a resource strip. This tab's only job left is the
## handoff: close the pause menu (which paused the tree and hid the world)
## and open the build menu (which does neither), so a player who came in
## through Settings-adjacent muscle memory still lands somewhere real.
##
## `build_menu.gd` is instantiated lazily and added under `get_tree().root`,
## the same way `camp.gd`/`storage_container.gd` lazily add
## `craft_panel.gd`/`storage_panel.gd` — not parented to this tab, which gets
## torn down and rebuilt (`build()`) far more often than the menu itself
## should be recreated.

const BUILD_MENU := preload("res://scripts/ui/build_menu.gd")

var _open_button: Button = null
var _build_menu: CanvasLayer = null


func build() -> void:
	for child in get_children():
		child.queue_free()

	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 16)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var title := Label.new()
	title.text = "Build"
	title.add_theme_font_size_override("font_size", 36)
	panel.add_child(title)

	var blurb := Label.new()
	blurb.text = "Pick what to place from the full build menu — categories, a piece grid, and what it costs, all in one screen you can see the world through."
	blurb.add_theme_font_size_override("font_size", 24)
	blurb.add_theme_color_override("font_color", Color(0.6, 0.62, 0.55))
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.custom_minimum_size = Vector2(520, 0)
	panel.add_child(blurb)

	_open_button = Button.new()
	_open_button.text = "  Open Build Menu"
	_open_button.custom_minimum_size = Vector2(320, 66)
	_open_button.focus_mode = Control.FOCUS_ALL
	_open_button.pressed.connect(_on_open_pressed)
	panel.add_child(_open_button)

	# A gap this pass does not close (task brief): there is no exploration
	# hotkey that jumps straight to the build menu yet — the pause menu's
	# Build tab is the only door in today. Noted rather than silently worked
	# around with a new input action this agent was not asked to add.
	var gap_note := Label.new()
	gap_note.text = "(no hammer hotkey yet — this button is the only way in)"
	gap_note.add_theme_font_size_override("font_size", 19)
	gap_note.add_theme_color_override("font_color", Color(0.5, 0.51, 0.48))
	panel.add_child(gap_note)

	add_child(_panel(panel))


func first_focus() -> Control:
	return _open_button


func revision() -> int:
	return 0


func poll() -> void:
	pass


func _on_open_pressed() -> void:
	var game := state()
	if game == null:
		return
	if menu != null:
		menu.call("close")
	var build_menu := _get_or_make_build_menu()
	# Deferred: `game_menu.gd::close()` un-pauses the tree and hides its own
	# root this same frame — opening the build menu one frame later keeps the
	# two hand-offs from fighting over `Input.mouse_mode` in the same frame.
	build_menu.call_deferred("open")


func _get_or_make_build_menu() -> CanvasLayer:
	if _build_menu != null and is_instance_valid(_build_menu):
		return _build_menu
	_build_menu = BUILD_MENU.new()
	get_tree().root.add_child(_build_menu)
	return _build_menu
