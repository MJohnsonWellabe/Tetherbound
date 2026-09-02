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
## the same way `campfire.gd`/`storage_container.gd` lazily add
## `craft_panel.gd`/`storage_panel.gd` — not parented to this tab, which gets
## torn down and rebuilt (`build()`) far more often than the menu itself
## should be recreated.
##
## OF24 added a second door in: `playground_hud.gd`'s hammer hotkey
## (`build_open`), straight from the world. `build_menu.gd::get_or_make()` is
## the shared lookup-or-create both doors go through now, so the two can
## never mint two competing instances.

const BUILD_MENU := preload("res://scripts/ui/build_menu.gd")

## D16's free-build banner survives the launcher rewrite: the rule is that
## free build says so out loud on the Build tab the whole time it is on, and
## `tests/smoke_free_build.gd` reads this exact member to hold us to it.
const FREE_NOTE_COLOUR := Color(0.851, 0.702, 0.251)

var _open_button: Button = null
var _free_note: Label = null


func build() -> void:
	for child in get_children():
		child.queue_free()

	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 16)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# OF31 sweep, frame 16: the pause menu's own tab bar already reads "Build"
	# immediately above this panel (`game_menu.gd`'s tab strip) -- a second
	# "Build" heading in here was a literal duplicate, not a distinct label
	# the way tab_map.gd's "THE MEADOWS" or tab_quest_log.gd's "QUEST LOG"
	# read next to their own "Map"/"Quests" tab buttons. This tab has one
	# real job (hand off to the live build menu) and nothing else to say, so
	# there is no second heading to replace it with -- see ALIGNMENT_CENTER
	# below for the other half of that sweep finding, the near-empty panel.
	panel.alignment = BoxContainer.ALIGNMENT_CENTER

	_free_note = Label.new()
	_free_note.text = "Free build is on — pieces cost nothing until it is switched off in Settings."
	_free_note.add_theme_font_size_override("font_size", 24)
	_free_note.add_theme_color_override("font_color", FREE_NOTE_COLOUR)
	_free_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_free_note.custom_minimum_size = Vector2(520, 0)
	_free_note.visible = false
	panel.add_child(_free_note)

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

	add_child(_panel(panel))


func first_focus() -> Control:
	return _open_button


func revision() -> int:
	return 0


func poll() -> void:
	if _free_note == null:
		return
	var game := state()
	_free_note.visible = game != null and bool(game.get("free_build"))


func _on_open_pressed() -> void:
	var game := state()
	if game == null:
		return
	if menu != null:
		menu.call("close")
	# RG1 (owner 2026-08-18): Build is a live-world surface. Never trust a
	# cached pause snapshot from the shell during this handoff; if it was stale,
	# the build menu opens visibly while the entire world/placer stays paused.
	# Closing the shell is the transition authority and Build explicitly needs
	# an unpaused tree before its deferred open.
	get_tree().paused = false
	var build_menu := BUILD_MENU.get_or_make(get_tree())
	# Deferred: `game_menu.gd::close()` un-pauses the tree and hides its own
	# root this same frame — opening the build menu one frame later keeps the
	# two hand-offs from fighting over `Input.mouse_mode` in the same frame.
	build_menu.call_deferred("open")
