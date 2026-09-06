extends Control

## Gate A front door. This is deliberately a tiny scene with no Terrain3D,
## vegetation or world scripts behind it: launch becomes interactive before the
## expensive Meadows exists, then New/Load transitions into the real world.

const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"
const THEME_PATH := "res://assets/ui/theme/tetherbound_theme.tres"
const EXPORT_VERIFY_FLAG := "--verify-export"
const UITokens := preload("res://scripts/ui/ui_tokens.gd")
## The game's ONE on-screen keyboard, reused rather than reinvented for the
## address prompt -- see `_prompt_for_address()` and `name_prompt.gd::open_entry`.
const NAME_PROMPT_SCENE := preload("res://scenes/ui/name_prompt.tscn")
const NAME_ENTRY := preload("res://scripts/ui/name_entry.gd")
const LAN_BEACON := preload("res://scripts/mp/lan_beacon.gd")
const JOIN_DRIVER := preload("res://scripts/mp/join_driver.gd")
## Character-choice step. `data/config/characters.json` -- one entry today,
## and this screen is the whole reason a second one is a JSON row rather than
## a UI rewrite. See `_load_character_options()`/`_show_character_select()`.
const CHARACTERS_CONFIG_PATH := "res://data/config/characters.json"


## ## THE COMMAND-LINE MULTIPLAYER FLAGS (lane 2.B)
##
## Parsed here, in the game's main scene, because this is the one screen every
## launch passes through and hosting already happens here (`_enter_world()`).
## Both flags route through the SAME `Session.host()` / `Session.join()` the
## buttons below call -- a second code path into the session would rot the
## moment one of them learned something the other did not.
##
##   --mp-host [port]           Start a NEW game, host it, and go straight in.
##                              `port` is optional and defaults to
##                              `data/config/multiplayer.json`'s `session.port`
##                              (27015). Hosting a SAVED world has no flag: the
##                              title screen's Load button already hosts.
##
##   --mp-join <address[:port]>  Load this machine's autosave (or start a fresh
##                              character when there is none), dial that host,
##                              and go in once the world snapshot lands. The
##                              port defaults to `session.port`.
##
## Both accept `--flag value` and `--flag=value`, and both are read from
## `OS.get_cmdline_args()` AND `OS.get_cmdline_user_args()` (the tokens after a
## bare `--`), for the reason `tools/gate_f/operator_harness.gd` gives: half
## the tools in this repo pass flags one way and half the other, and a flag
## that only works one of those ways is a flag that looks broken.
##
##   godot --path . -- --mp-host 27015
##   Tetherbound.exe --mp-join 192.168.1.24
##   Tetherbound.exe --mp-join=192.168.1.24:27015
##
## `--mp-join` is patient on purpose: `tools/owner/` launches one host and
## three clients in the same second, and the host's Meadows takes ~85 s to
## build, so a dial that is refused keeps re-dialling until
## `CMDLINE_JOIN_RETRY_S`. A player who typed an address gets the answer
## immediately instead; patience is the launcher's need, not theirs.
const HOST_FLAG := "--mp-host"
const JOIN_FLAG := "--mp-join"
## Seconds `--mp-join` keeps re-dialling before it gives up. Long enough to
## outwait a host that is building its own Meadows (~85 s, spike S2) plus a
## slow machine's margin. `scripts/mp/join_driver.gd` owns the interval between
## attempts and the dial itself.
const CMDLINE_JOIN_RETRY_S := 180.0


## A lightweight Meadows vista for the front door.  The approved key-art board
## lives under docs/ and is deliberately excluded from exports, while building
## the real Terrain3D world here would recreate the long blank boot RG25 fixed.
## These flat, layered silhouettes borrow the board's value structure and
## landmark language without introducing a second world scene or a new asset.
class MeadowsBackdrop extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
		queue_redraw()


	func _draw() -> void:
		var view := size
		if view.x <= 0.0 or view.y <= 0.0:
			return

		# A deep upper sky and warm horizon give the screen an authored time of
		# day while retaining enough darkness for the menu's pale lettering.
		var sky_top := Color("#071820")
		var sky_bottom := Color("#4f857f")
		for band in 36:
			var from := float(band) / 36.0
			var to := float(band + 1) / 36.0
			draw_rect(Rect2(0.0, view.y * from, view.x, view.y * (to - from) + 1.0),
				sky_top.lerp(sky_bottom, pow(from, 0.78)))

		var horizon := view.y * 0.49
		var sun_at := Vector2(view.x * 0.76, view.y * 0.235)
		draw_circle(sun_at, view.y * 0.075, Color(Color("#e9c978"), 0.16))
		draw_circle(sun_at, view.y * 0.047, Color(Color("#f4d68a"), 0.72))

		# Distant mountain, foothills and near meadow use separated values so the
		# scene still reads at handheld scale instead of collapsing into one green.
		_polygon([
			Vector2(0.0, horizon + view.y * 0.06),
			Vector2(view.x * 0.36, horizon + view.y * 0.02),
			Vector2(view.x * 0.49, horizon - view.y * 0.08),
			Vector2(view.x * 0.59, horizon - view.y * 0.19),
			Vector2(view.x * 0.66, horizon - view.y * 0.04),
			Vector2(view.x * 0.72, horizon - view.y * 0.12),
			Vector2(view.x * 0.80, horizon + view.y * 0.01),
			Vector2(view.x, horizon - view.y * 0.04),
			Vector2(view.x, view.y), Vector2(0.0, view.y),
		], Color("#385b5b"))
		_polygon([
			Vector2(0.0, horizon + view.y * 0.12),
			Vector2(view.x * 0.18, horizon + view.y * 0.06),
			Vector2(view.x * 0.38, horizon + view.y * 0.12),
			Vector2(view.x * 0.58, horizon + view.y * 0.035),
			Vector2(view.x * 0.77, horizon + view.y * 0.10),
			Vector2(view.x, horizon + view.y * 0.02),
			Vector2(view.x, view.y), Vector2(0.0, view.y),
		], Color("#416d4d"))
		_polygon([
			Vector2(0.0, horizon + view.y * 0.26),
			Vector2(view.x * 0.25, horizon + view.y * 0.16),
			Vector2(view.x * 0.49, horizon + view.y * 0.21),
			Vector2(view.x * 0.71, horizon + view.y * 0.105),
			Vector2(view.x, horizon + view.y * 0.18),
			Vector2(view.x, view.y), Vector2(0.0, view.y),
		], Color("#315c3e"))
		_polygon([
			Vector2(0.0, view.y * 0.86), Vector2(view.x * 0.22, view.y * 0.78),
			Vector2(view.x * 0.45, view.y * 0.86), Vector2(view.x * 0.65, view.y * 0.70),
			Vector2(view.x * 0.82, view.y * 0.76), Vector2(view.x, view.y * 0.69),
			Vector2(view.x, view.y), Vector2(0.0, view.y),
		], Color("#1d3e2f"))

		# A widening trail is the composition's pull into the Meadows, with the
		# distant pylon marking the adventure beyond the welcoming foreground.
		_polygon([
			Vector2(view.x * 0.72, horizon + view.y * 0.10),
			Vector2(view.x * 0.745, horizon + view.y * 0.105),
			Vector2(view.x * 0.64, view.y), Vector2(view.x * 0.47, view.y),
		], Color(Color("#b69b68"), 0.72))
		_draw_pylon(Vector2(view.x * 0.79, horizon + view.y * 0.055), view.y * 0.17)
		_draw_tree(Vector2(view.x * 0.91, view.y * 0.61), view.y * 0.30, Color("#142f25"))
		_draw_tree(Vector2(view.x * 0.84, view.y * 0.70), view.y * 0.19, Color("#214632"))
		_draw_tree(Vector2(view.x * 0.69, view.y * 0.68), view.y * 0.15, Color("#274d35"))

		# Meadow flowers remain restrained highlights; they add scale and warmth
		# without turning the lightweight screen into procedural confetti.
		for flower in [
			Vector2(0.70, 0.83), Vector2(0.75, 0.88), Vector2(0.82, 0.82),
			Vector2(0.87, 0.91), Vector2(0.93, 0.84), Vector2(0.78, 0.94),
		]:
			var point := Vector2(view.x * flower.x, view.y * flower.y)
			draw_line(point, point + Vector2(0.0, view.y * 0.018), Color("#5f8e55"), 3.0)
			draw_circle(point, maxf(3.0, view.y * 0.0045), Color("#efd17d"))


	func _polygon(points: Array[Vector2], color: Color) -> void:
		draw_colored_polygon(PackedVector2Array(points), color)


	func _draw_tree(at: Vector2, height: float, color: Color) -> void:
		var trunk_w := height * 0.075
		draw_rect(Rect2(at.x - trunk_w * 0.5, at.y - height * 0.52, trunk_w, height * 0.52), Color("#493a2b"))
		draw_circle(at - Vector2(height * 0.13, height * 0.58), height * 0.23, color)
		draw_circle(at + Vector2(height * 0.12, -height * 0.64), height * 0.27, color.lightened(0.04))
		draw_circle(at + Vector2(0.0, -height * 0.82), height * 0.22, color.lightened(0.08))


	func _draw_pylon(at: Vector2, height: float) -> void:
		var iron := Color("#263943")
		draw_line(at, at - Vector2(0.0, height * 0.70), iron, maxf(4.0, height * 0.045))
		draw_line(at - Vector2(height * 0.18, height * 0.13), at - Vector2(0.0, height * 0.70), iron, maxf(3.0, height * 0.03))
		draw_line(at + Vector2(height * 0.18, -height * 0.13), at - Vector2(0.0, height * 0.70), iron, maxf(3.0, height * 0.03))
		var crystal := PackedVector2Array([
			at - Vector2(0.0, height), at + Vector2(height * 0.09, -height * 0.82),
			at - Vector2(0.0, height * 0.66), at - Vector2(height * 0.09, height * 0.82),
		])
		draw_colored_polygon(crystal, Color(Color("#55c9c8"), 0.84))
		var crystal_outline := crystal.duplicate()
		crystal_outline.append(crystal[0])
		draw_polyline(crystal_outline, Color(Color("#a5f0df"), 0.70), 2.0)

var _main_box: VBoxContainer
var _load_box: VBoxContainer
var _confirm_box: VBoxContainer
var _join_box: VBoxContainer
## The character-choice step, shown before a new game actually starts. Built
## fresh every time `_show_character_select()` opens it, the same pattern
## `_load_box`/`_join_box` already use for their own per-visit rows.
var _character_box: VBoxContainer
var _lan_list: VBoxContainer
var _status: Label
var _new_button: Button
var _load_button: Button
var _join_button: Button
var _quit_button: Button

## What B/menu_cancel should do while `_character_box` is open -- the join
## flow wants to return to the join screen, everything else wants the main
## menu, and this is the one field that lets `_unhandled_input()`'s single
## shared handler know which. Set by `_show_character_select()`, read there.
var _character_back: Callable = Callable()
## The character option the player picked, kept for a future consumer (a
## starting cosmetic/loadout difference) that does not exist yet -- today's
## one option makes every choice the same, so nothing reads this yet. Not
## threaded into `PlayerState`/`character_save.gd` for that reason: there is
## nothing there for it to change.
var _pending_character_option_id: String = ""

## The LAN listener, alive only while the join screen is on. A child of this
## screen, so leaving the screen frees the socket rather than leaving it bound
## for the rest of the process.
var _lan: Node = null
## What the LAN list currently DRAWS. Rows are rebuilt only when this changes:
## a focusable list rebuilt every frame destroys the focused node every frame,
## which on a controller means the cursor cannot be moved at all (the rule
## `scripts/ui/menu_tab.gd`'s header sets, applied to a list arriving off a
## socket).
var _lan_drawn := ""

## The address prompt, instanced on demand. Freed when it closes.
var _address_prompt: CanvasLayer = null

## The port `_enter_world()` hosts on. -1 means "whatever the session config
## says", which is what every button on this screen wants; `--mp-host 27100`
## is the only thing that moves it.
var _host_port := -1


func _ready() -> void:
	add_to_group(&"title_screen")
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var theme: Theme = load(THEME_PATH)
	if theme != null:
		theme = theme
		self.theme = theme
	_build()
	_refresh_load_button()
	# Release verification launches the exported project through its real main
	# scene.  The title is now that main scene, so explicitly preserve the
	# verifier's old contract by taking only its private command-line path into a
	# clean Meadows run.  Normal players still stop here and choose New or Load.
	if should_enter_export_verification(OS.get_cmdline_args()):
		# This is a new exported process, so Game is already clean.  Entering the
		# world directly also keeps the verifier independent of title-button save
		# policy; the world's EXPORT-CHECK remains the sole pass/fail authority.
		_enter_world("Verifying export…")
		return
	# A join that failed sent the player back here. Its reason is shown before
	# anything else, and BEFORE the command-line flags below -- a launcher that
	# re-read `--mp-join` here would dial straight back into the failure it was
	# just told about, forever.
	if _report_failed_join():
		return
	# Lane 2.B. The owner kit's unattended launch, and the same two entry points
	# a player reaches with the buttons above. Checked after the export verifier
	# so nothing about that contract moves.
	var multiplayer_flags := parse_multiplayer_flags(cmdline_tokens())
	if not multiplayer_flags.is_empty():
		_apply_multiplayer_flags(multiplayer_flags)
		return
	_new_button.grab_focus()


static func should_enter_export_verification(arguments: PackedStringArray) -> bool:
	return arguments.has(EXPORT_VERIFY_FLAG)


## Every command-line token this process was given, from both places Godot
## keeps them. See the flag documentation at the top of this file.
static func cmdline_tokens() -> PackedStringArray:
	var out := PackedStringArray()
	out.append_array(OS.get_cmdline_args())
	out.append_array(OS.get_cmdline_user_args())
	return out


## `{}`, or `{"mode": "host", "port": int}`, or
## `{"mode": "join", "address": String, "port": int}`. `port` is 0 for "the
## session config's default", which is resolved late (in `_apply_multiplayer_flags`)
## rather than here, so this function stays pure and testable with no session,
## no autoloads and no file reads.
##
## Static, and takes its tokens as an argument, for the same reason
## `should_enter_export_verification` above does: a flag reader that can only
## be exercised by launching the game is a flag reader nothing checks.
static func parse_multiplayer_flags(arguments: PackedStringArray) -> Dictionary:
	for i in arguments.size():
		var token := arguments[i]
		var value := ""
		var flag := token
		var split := token.split("=", true, 1)
		if split.size() == 2:
			flag = split[0]
			value = split[1]
		elif i + 1 < arguments.size() and not arguments[i + 1].begins_with("--"):
			value = arguments[i + 1]
		if flag == HOST_FLAG:
			# The port is OPTIONAL here, so a bare `--mp-host` followed by some
			# other tool's non-flag token must not swallow it as a port.
			return {"mode": "host", "port": _port_from(value)}
		if flag == JOIN_FLAG:
			var target := split_address(value, 0)
			if target.is_empty():
				push_warning("%s needs an address, e.g. %s 192.168.1.24:27015" % [JOIN_FLAG, JOIN_FLAG])
				return {}
			target["mode"] = "join"
			return target
	return {}


static func _port_from(value: String) -> int:
	if not value.is_valid_int():
		return 0
	var port := int(value)
	return port if port > 0 and port <= 65535 else 0


## `"192.168.1.24:27015"` -> `{"address": "192.168.1.24", "port": 27015}`, and
## `"192.168.1.24"` -> that address with `fallback_port`. `{}` when there is no
## address at all, or the port is not a port.
##
## Splits on the LAST colon so a future IPv6 literal in brackets still finds
## its port; a bare IPv6 address with no brackets is not supported and would be
## read as host plus port, which is the same thing every tool that takes
## `host:port` does.
static func split_address(raw: String, fallback_port: int) -> Dictionary:
	var text := raw.strip_edges()
	if text.is_empty():
		return {}
	var address := text
	var port := fallback_port
	var colon := text.rfind(":")
	if colon > 0:
		var tail := text.substr(colon + 1)
		var parsed := _port_from(tail)
		if parsed <= 0:
			return {}
		address = text.substr(0, colon)
		port = parsed
	address = address.strip_edges().trim_prefix("[").trim_suffix("]")
	if address.is_empty():
		return {}
	return {"address": address, "port": port}


func _build() -> void:
	var backdrop := MeadowsBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	# The asymmetric layout leaves the Meadows vista visible as a destination,
	# instead of covering the entire identity of the game with a centred modal.
	var shade := ColorRect.new()
	shade.anchor_right = 0.56
	shade.anchor_bottom = 1.0
	shade.color = Color(Color("#071510"), 0.38)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.055
	panel.anchor_right = 0.445
	panel.anchor_top = 0.085
	panel.anchor_bottom = 0.915
	panel.add_theme_stylebox_override("panel", UITokens.panel_box(Color(Color("#0d1c18"), 0.94), Color(Color("#7ba284"), 0.86)))
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 42)
	margin.add_theme_constant_override("margin_bottom", 38)
	panel.add_child(margin)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 16)
	margin.add_child(root_box)

	var region := Label.new()
	region.text = "THE MEADOWS"
	region.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	region.add_theme_font_size_override("font_size", 22)
	region.add_theme_color_override("font_color", Color("#d4b96f"))
	root_box.add_child(region)

	var title := Label.new()
	title.text = "TETHERBOUND"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load(UITokens.FONT_PATH))
	title.add_theme_font_size_override("font_size", 70)
	title.add_theme_color_override("font_color", Color("#f2ead5"))
	root_box.add_child(title)

	var rule := ColorRect.new()
	rule.custom_minimum_size.y = 2
	rule.color = Color(Color("#d4b96f"), 0.72)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_box.add_child(rule)

	var subtitle := Label.new()
	subtitle.text = "Build your team of five. Explore the Meadows."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 23)
	subtitle.add_theme_color_override("font_color", Color("#b8cbbf"))
	root_box.add_child(subtitle)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.custom_minimum_size.y = 12
	root_box.add_child(spacer)

	_main_box = VBoxContainer.new()
	_main_box.add_theme_constant_override("separation", 14)
	root_box.add_child(_main_box)
	_new_button = _button("Start New Game")
	_load_button = _button("Load Game")
	# Lane 2.B: the front door directive item 2 ("join up to three") was
	# missing. Everything under it worked and nothing on this screen could
	# reach it.
	_join_button = _button("Join a Game")
	_quit_button = _button("Quit Game")
	_main_box.add_child(_new_button)
	_main_box.add_child(_load_button)
	_main_box.add_child(_join_button)
	_main_box.add_child(_quit_button)
	_new_button.pressed.connect(_on_new_pressed)
	_load_button.pressed.connect(_show_load_slots)
	_join_button.pressed.connect(_show_join)
	_quit_button.pressed.connect(func() -> void: get_tree().quit())

	_load_box = VBoxContainer.new()
	_load_box.visible = false
	_load_box.add_theme_constant_override("separation", 10)
	root_box.add_child(_load_box)

	_confirm_box = VBoxContainer.new()
	_confirm_box.visible = false
	_confirm_box.add_theme_constant_override("separation", 12)
	root_box.add_child(_confirm_box)

	_join_box = VBoxContainer.new()
	_join_box.visible = false
	_join_box.add_theme_constant_override("separation", 10)
	root_box.add_child(_join_box)

	_character_box = VBoxContainer.new()
	_character_box.visible = false
	_character_box.add_theme_constant_override("separation", 10)
	root_box.add_child(_character_box)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 18)
	_status.add_theme_color_override("font_color", Color("#d2c392"))
	root_box.add_child(_status)

	var footer := Label.new()
	footer.text = "A  SELECT     D-PAD  NAVIGATE"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 18)
	footer.add_theme_color_override("font_color", Color("#8fa9a0"))
	root_box.add_child(footer)

	UITokens.make_text_legible(root_box)


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 58)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 24)
	return button


func _refresh_load_button() -> void:
	var game := get_node_or_null(^"/root/Game")
	var any := false
	if game != null:
		for slot in 5:
			if bool(game.call("has_save", slot)):
				any = true
				break
	_load_button.disabled = not any


func _on_new_pressed() -> void:
	var game := get_node_or_null(^"/root/Game")
	var has_existing := false
	if game != null:
		for slot in 5:
			if bool(game.call("has_save", slot)):
				has_existing = true
				break
	if not has_existing:
		_show_character_select(_start_new_game_with_character, _show_main)
		return
	_show_new_confirmation()


func _show_new_confirmation() -> void:
	_main_box.visible = false
	_load_box.visible = false
	_clear(_confirm_box)
	_confirm_box.visible = true
	var text := Label.new()
	text.text = "Start a fresh game? Existing saves stay available, but the autosave will be replaced once this new run saves progress."
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_box.add_child(text)
	var go := _button("Start Fresh Game")
	var back := _button("Back")
	_confirm_box.add_child(go)
	_confirm_box.add_child(back)
	go.pressed.connect(func() -> void: _show_character_select(_start_new_game_with_character, _show_main))
	back.pressed.connect(_show_main)
	go.grab_focus()


## `data/config/characters.json`'s `characters` array, or `[]` if the file is
## missing/malformed -- `_show_character_select()` then draws "No character
## options are configured" rather than a broken screen, the same fallback
## `_show_load_slots()` gives an empty save list.
func _load_character_options() -> Array:
	var file := FileAccess.open(CHARACTERS_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var list: Variant = (parsed as Dictionary).get("characters", [])
	return list if list is Array else []


## The character-choice step every new-game path shows before the world is
## entered (owner directive: even with one option today, build the picker so
## a second is a JSON row, not a rewrite). Picking a row IS confirming it --
## the same one-press pattern `_show_load_slots()` already uses for a save
## slot -- so this screen never needs a separate Confirm button.
##
## `on_chosen` receives the picked option's `id` and does whatever starting a
## game from here actually means (a fresh solo/host game, or continuing a
## join once a character exists); `on_back` is what B/`menu_cancel` and this
## screen's own Back button do, which differs by how this screen was reached
## (main menu for a new game, the join screen for an empty-save join).
func _show_character_select(on_chosen: Callable, on_back: Callable) -> void:
	_main_box.visible = false
	_load_box.visible = false
	_confirm_box.visible = false
	_join_box.visible = false
	_clear(_character_box)
	_character_box.visible = true
	_character_back = on_back

	var heading := Label.new()
	heading.text = "Choose Your Character"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 26)
	_character_box.add_child(heading)

	var options := _load_character_options()
	var first: Button = null
	for raw: Variant in options:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var option := raw as Dictionary
		var id := str(option.get("id", ""))
		var display_name := str(option.get("display_name", id if not id.is_empty() else "Character"))
		var tagline := str(option.get("tagline", ""))
		var button := _button(display_name if tagline.is_empty() else "%s — %s" % [display_name, tagline])
		button.pressed.connect(func() -> void: on_chosen.call(id))
		_character_box.add_child(button)
		if first == null:
			first = button
	if options.is_empty():
		var empty := Label.new()
		empty.text = "No character options are configured."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_character_box.add_child(empty)

	var back := _button("Back")
	back.pressed.connect(func() -> void: on_back.call())
	_character_box.add_child(back)
	(first if first != null else back).grab_focus()
	UITokens.make_text_legible(_character_box)


func _start_new_game_with_character(character_id: String) -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		_status.text = "Game state failed to start."
		return
	_pending_character_option_id = character_id
	game.call("reset_for_new_game")
	_enter_world("Starting new game…")


func _show_load_slots() -> void:
	_main_box.visible = false
	_confirm_box.visible = false
	_character_box.visible = false
	_clear(_load_box)
	_load_box.visible = true
	var heading := Label.new()
	heading.text = "Choose a save"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 26)
	_load_box.add_child(heading)
	var game := get_node_or_null(^"/root/Game")
	var first: Button = null
	for slot in 5:
		var info: Dictionary = game.call("save_slot_info", slot) if game != null else {}
		var label := "Autosave" if slot == 0 else "Save %d" % slot
		var button := _button(label)
		if info.is_empty():
			button.text = "%s — Empty" % label
			button.disabled = true
		else:
			# D100's "Legacy saves" mark: a slot from an older build, which
			# this load will split into a world and a character without
			# touching the slot file itself.
			var legacy := " (Legacy)" if bool(info.get("legacy", false)) else ""
			button.text = "%s%s — Day %d · %d Pals" % [
				label, legacy, int(info.get("day", 1)), int(info.get("party_size", 0))]
			var chosen := slot
			button.pressed.connect(func() -> void: _load_slot(chosen))
			if first == null:
				first = button
		_load_box.add_child(button)
	var back := _button("Back")
	back.pressed.connect(_show_main)
	_load_box.add_child(back)
	(first if first != null else back).grab_focus()


func _load_slot(slot: int) -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null or not bool(game.call("load_game", slot)):
		_status.text = "That save could not be loaded."
		return
	_enter_world("Loading realm…")


# --- joining (lane 2.B) ---------------------------------------------------------

## The join screen: a live list of games advertising themselves on this
## network, and a typed address for everything else (D95 -- direct IP plus a
## LAN beacon, no relay, no Steam).
func _show_join() -> void:
	_main_box.visible = false
	_load_box.visible = false
	_confirm_box.visible = false
	_character_box.visible = false
	_join_box.visible = true
	_clear(_join_box)
	_lan_drawn = ""

	var heading := Label.new()
	heading.text = "Join a Game"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 26)
	_join_box.add_child(heading)

	_lan_list = VBoxContainer.new()
	_lan_list.add_theme_constant_override("separation", 8)
	_join_box.add_child(_lan_list)

	var typed := _button("Enter an Address")
	typed.pressed.connect(_prompt_for_address)
	_join_box.add_child(typed)

	var back := _button("Back")
	back.pressed.connect(_show_main)
	_join_box.add_child(back)

	_start_lan_listener()
	_refresh_lan_list()
	typed.grab_focus()
	UITokens.make_text_legible(_join_box)


func _start_lan_listener() -> void:
	if _lan != null:
		return
	_lan = LAN_BEACON.new()
	_lan.name = "LanListener"
	add_child(_lan)
	if not bool(_lan.call("listen", _configured_port())):
		_status.text = str(_lan.call("listen_error"))


func _stop_lan_listener() -> void:
	if _lan == null:
		return
	_lan.call("stop")
	_lan.queue_free()
	_lan = null
	_lan_drawn = ""


## Rebuilt only when the advertised set actually changes -- see `_lan_drawn`.
func _refresh_lan_list() -> void:
	if _lan_list == null or not is_instance_valid(_lan_list):
		return
	var games: Array = _lan.call("games") if _lan != null else []
	var fingerprint: String = str(_lan.call("fingerprint")) if _lan != null else ""
	if fingerprint == _lan_drawn and _lan_list.get_child_count() > 0:
		return
	_lan_drawn = fingerprint

	# Which button had the cursor, by the game it names rather than by index:
	# a list that reorders under a stick would otherwise move the cursor to a
	# different game than the one the player was looking at.
	var focused := ""
	var focus_owner := get_viewport().gui_get_focus_owner() if get_viewport() != null else null
	if focus_owner != null and focus_owner.get_parent() == _lan_list:
		focused = str(focus_owner.get_meta("join_key", ""))

	_clear(_lan_list)
	if games.is_empty():
		var searching := Label.new()
		searching.text = "Searching this network for games…"
		searching.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		searching.add_theme_font_size_override("font_size", 20)
		searching.add_theme_color_override("font_color", Color("#9db3a8"))
		_lan_list.add_child(searching)
		UITokens.make_text_legible(_lan_list)
		return
	for entry: Variant in games:
		var game: Dictionary = entry
		var address := str(game.get("address", ""))
		var port := int(game.get("port", 0))
		var key := "%s:%d" % [address, port]
		var full := int(game.get("players", 0)) >= int(game.get("max_players", 4))
		var button := _button("%s — Day %d · %d/%d players%s" % [
			str(game.get("name", "A Tetherbound world")), int(game.get("day", 1)),
			int(game.get("players", 0)), int(game.get("max_players", 4)),
			"  (full)" if full else ""])
		button.set_meta("join_key", key)
		# A full world is SHOWN and refused, not hidden: a player looking for
		# their friend's game has to be able to see that they found it.
		button.disabled = full
		button.pressed.connect(func() -> void: _join_via(address, port))
		_lan_list.add_child(button)
		if key == focused:
			button.grab_focus()
	UITokens.make_text_legible(_lan_list)


## The address prompt. `name_prompt.tscn` is the game's ONE on-screen keyboard
## (a ROG Ally has no other), opened here on its address grid rather than
## copied into a second panel -- `name_prompt.gd::open_entry` is the seam.
func _prompt_for_address() -> void:
	if _address_prompt != null:
		return
	_address_prompt = NAME_PROMPT_SCENE.instantiate() as CanvasLayer
	add_child(_address_prompt)
	_address_prompt.connect("confirmed", _on_address_confirmed)
	_address_prompt.connect("cancelled", _on_address_cancelled)
	_address_prompt.call("open_entry", "Host address", "", NAME_ENTRY.ADDRESS_ROWS,
		NAME_ENTRY.ADDRESS_MAX_LENGTH, "the address of the machine hosting the game", true)


func _free_address_prompt() -> void:
	if _address_prompt == null:
		return
	_address_prompt.queue_free()
	_address_prompt = null


func _on_address_cancelled() -> void:
	_free_address_prompt()
	if _join_box.visible:
		_show_join()


func _on_address_confirmed(typed: String) -> void:
	_free_address_prompt()
	var target := split_address(typed, _configured_port())
	if target.is_empty():
		_status.text = "\"%s\" is not an address. Try 192.168.1.24, or 192.168.1.24:27015." % typed
		_show_join()
		return
	_join_via(str(target.get("address", "")), int(target.get("port", 0)))


## The two manual, player-pressed ways into `_begin_join()` (a LAN row, a typed
## address) both route through here instead of calling it directly, so both
## get the character-choice step this screen owns -- `--mp-join`'s own call
## site further down deliberately does not, because that flag is the
## launcher's unattended path (`tools/owner/`, `smoke_net_join_by_address.gd`)
## and has nobody at the keyboard to show a picker to.
##
## Only shown when this machine is about to MINT a character: an address that
## resumes this machine's own existing autosave (`_begin_join()`'s own
## `has_save(0)` branch below) is a returning player, not a new one, and gets
## no new-game step for the same reason Load Game never shows this screen.
func _join_via(address: String, port: int) -> void:
	var game := _game()
	if game != null and bool(game.call("has_save", 0)):
		_begin_join(address, port, 0.0)
		return
	_show_character_select(func(character_id: String) -> void:
		_pending_character_option_id = character_id
		_begin_join(address, port, 0.0)
	, _show_join)


## Start a join. THE WORLD IS BUILT FIRST AND THE SOCKET OPENED SECOND, which
## is not the obvious order and is the one that works: a live ENet connection
## does not survive the Meadows build (~85 s in one blocking frame, spike S2),
## so a joiner that dialled here and then loaded the world arrived in it
## already disconnected. `scripts/mp/join_driver.gd`'s header carries the
## measurement and the reasoning; this screen hands the dial to it and gets out
## of the way, because this node does not survive the scene change and the dial
## has to happen on the other side of it.
##
## `retry_for_s` > 0 is the launcher's patience; see `CMDLINE_JOIN_RETRY_S`.
func _begin_join(address: String, port: int, retry_for_s: float) -> void:
	var game := _game()
	var session: Node = game.get("session") if game != null else null
	if game == null or session == null:
		_status.text = "This build has no multiplayer session to join with."
		return

	# The joiner brings a character. D100's per-character file does not exist
	# yet (`session.gd::_save_character_here` records that gap), so the honest
	# available answer is: continue this machine's autosave if there is one,
	# and mint a fresh character if there is not. A client never writes a
	# world file, so neither choice can damage the save it started from. When
	# the character split lands this becomes a character picker.
	if bool(game.call("has_save", 0)):
		game.call("load_game", 0)
	else:
		game.call("reset_for_new_game")

	var driver := _mount_join_driver(game)
	driver.call("begin", address, port if port > 0 else _configured_port(), retry_for_s)
	_go_to_world("Joining %s…" % address)


## The driver lives under `/root/Game`, beside the beacon, because it has to
## outlive this screen. One at a time: a second dial replaces the first rather
## than racing it.
func _mount_join_driver(game: Node) -> Node:
	var existing := game.get_node_or_null(^"JoinDriver")
	if existing != null:
		existing.free()
	var driver := JOIN_DRIVER.new()
	driver.name = "JoinDriver"
	game.add_child(driver)
	return driver


## A join that failed put the player back here and left its reason on the
## driver. Shown once, then the driver is freed -- it is not a place messages
## accumulate.
func _report_failed_join() -> bool:
	var game := _game()
	if game == null:
		return false
	var driver := game.get_node_or_null(^"JoinDriver")
	if driver == null:
		return false
	var message := str(driver.call("last_error"))
	driver.free()
	if message.is_empty():
		return false
	_status.text = message
	_show_join()
	return true


func _process(_delta: float) -> void:
	if _join_box.visible and _lan != null:
		_refresh_lan_list()


# --- the command line -------------------------------------------------------------

## `--mp-host` / `--mp-join`, through the same two entry points the buttons
## use. Documented at the top of this file, which is where they are parsed.
func _apply_multiplayer_flags(flags: Dictionary) -> void:
	var game := _game()
	if game == null:
		push_error("title_screen: %s/%s need /root/Game and it is not there" % [HOST_FLAG, JOIN_FLAG])
		return
	match str(flags.get("mode", "")):
		"host":
			_host_port = int(flags.get("port", 0))
			if _host_port <= 0:
				_host_port = -1
			print("[title] %s: new game, hosting on udp/%d" % [HOST_FLAG,
				_host_port if _host_port > 0 else _configured_port()])
			game.call("reset_for_new_game")
			_enter_world("Hosting…")
		"join":
			print("[title] %s: dialling %s:%d" % [JOIN_FLAG, str(flags.get("address", "")),
				int(flags.get("port", 0)) if int(flags.get("port", 0)) > 0 else _configured_port()])
			_begin_join(str(flags.get("address", "")), int(flags.get("port", 0)), CMDLINE_JOIN_RETRY_S)


# --- shared -----------------------------------------------------------------------

func _game() -> Node:
	return get_node_or_null(^"/root/Game")


## The session's configured port, asked of the session rather than restated
## here, so `data/config/multiplayer.json` stays the only place the number
## lives.
func _configured_port() -> int:
	var game := _game()
	var session: Node = game.get("session") if game != null else null
	if session == null:
		return 27015
	return int(session.call("default_port"))


func _enter_world(message: String) -> void:
	_status.text = message
	_set_buttons_disabled(true)
	await get_tree().process_frame
	var game := get_node_or_null(^"/root/Game")
	# D95/lane 2.A, deliverable 8: SOLO IS A ONE-PEER SESSION. Both Start New
	# Game and Load land here, so hosting here is the one place a world becomes
	# playable -- there is no second, session-less code path into the world for
	# a multiplayer change to forget about. A failed bind (another Godot already
	# on the port) is deliberately non-fatal: `Session.host()` warns and returns
	# false, `is_host()` stays true, and the player gets an ordinary solo game
	# that simply cannot be joined.
	var session: Node = game.get("session") if game != null else null
	if session != null and not bool(session.call("is_active")):
		session.call("host", _host_port)
	_serve_beacon(session)
	_go_to_world(message)


## Lane 2.B: a hosted world advertises itself on the LAN so a friend does not
## have to be told an address (D95). Mounted under `/root/Game` rather than on
## this screen because the beacon has to outlive the title -- this node is
## freed the moment the world scene loads. Never mounted on a joiner, and it
## stops advertising by itself if the session ends.
func _serve_beacon(session: Node) -> void:
	if session == null or not bool(session.call("is_active")) or not bool(session.call("is_host")):
		return
	var game := _game()
	if game == null or game.get_node_or_null(^"LanBeacon") != null:
		return
	var beacon := LAN_BEACON.new()
	beacon.name = "LanBeacon"
	game.add_child(beacon)
	beacon.call("serve", _host_port if _host_port > 0 else _configured_port())


## The scene change itself, shared by the host path above and the joiner in
## `_poll_join()`. A joiner MUST NOT pass through `_enter_world()`: hosting
## there would take a client's own session down and stand a second one up.
func _go_to_world(message: String) -> void:
	_status.text = message
	_stop_lan_listener()
	var game := _game()
	var scene := WORLD_SCENE
	if game != null and game.has_method("current_realm_scene"):
		var configured := str(game.call("current_realm_scene"))
		if configured != "":
			scene = configured
	get_tree().change_scene_to_file(scene)


func _show_main() -> void:
	_confirm_box.visible = false
	_load_box.visible = false
	_stop_lan_listener()
	_join_box.visible = false
	_character_box.visible = false
	_main_box.visible = true
	_status.text = ""
	_refresh_load_button()
	_new_button.grab_focus()


func _set_buttons_disabled(value: bool) -> void:
	for node in find_children("*", "Button", true, false):
		(node as Button).disabled = value


func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	# Not while the address prompt is up: B is that panel's backspace, and it
	# closes itself (`name_prompt.gd::_cancel`) once there is nothing left to
	# delete. Two readers of one button is one of them acting on a press the
	# player aimed at the other.
	if _address_prompt != null:
		return
	if event.is_action_pressed("menu_cancel") and _character_box.visible:
		# Routes to the join screen or the main menu depending on how this
		# screen was reached -- see `_character_back`'s own field comment.
		if _character_back.is_valid():
			_character_back.call()
		else:
			_show_main()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("menu_cancel") \
			and (_load_box.visible or _confirm_box.visible or _join_box.visible):
		_show_main()
		get_viewport().set_input_as_handled()
