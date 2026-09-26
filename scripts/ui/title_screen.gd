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
const REJOIN_POSE := preload("res://scripts/mp/rejoin_pose.gd")
const JOIN_DRIVER := preload("res://scripts/mp/join_driver.gd")
const CHARACTER_IDENTITY := preload("res://scripts/save/character_identity.gd")
## Optional by design: release exports without the Steam/GodotSteam pieces must
## still boot and keep Solo plus the established ENet/LAN fallback usable.
## Loaded only after ResourceLoader confirms the adapter is present so this UI
## can also be exercised on those builds.
const STEAM_LOBBY_PATH := "res://scripts/net/steam_lobby.gd"
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
var _character_box: VBoxContainer
var _title_panel: PanelContainer
var _action_scroll: ScrollContainer
var _join_box: VBoxContainer
var _lan_list: VBoxContainer
var _status: Label
var _new_button: Button
var _load_button: Button
var _join_button: Button
var _join_friend_button: Button
var _host_friends_button: Button
var _quit_button: Button

## What B/menu_cancel should do while `_character_box` is open -- the join
## flow wants to return to the join screen, everything else wants the main
## menu, and this is the one field that lets `_unhandled_input()`'s single
## shared handler know which. Set by `_show_character_select()`, read there.
var _character_back: Callable = Callable()
## The character option the player picked. `PlayerState.chosen_character` is
## set alongside this (both call sites below) the moment it is known, since
## that is what actually decides the player's body via `art.json`; this copy
## is kept for a future consumer (a starting cosmetic/loadout difference)
## that does not exist yet.
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
## A fresh trainer names THEMSELVES after choosing a body. This is a separate
## instance from `_address_prompt`: the two prompts can never be open together,
## but their close callbacks return to different screens and must not share
## state. Both still use the one handheld keyboard scene.
var _player_name_prompt: CanvasLayer = null

## The port `_enter_world()` hosts on. -1 means "whatever the session config
## says", which is what every button on this screen wants; `--mp-host 27100`
## is the only thing that moves it.
var _host_port := -1

## The same new/load screens serve Solo and friends hosting. This bit is set
## only by the explicit Host for Friends choice and is cleared by every route
## back to the main menu, so cancelling a host attempt can never silently turn
## the next Solo press into a Steam host.
var _friends_host_mode := false
var _steam_lobby: Node = null
var _pending_invite_id := 0
var _joining_lobby_id := 0
var _steam_lobby_ready := false
var _steam_character_pending: Dictionary = {}
var _steam_retry_waiting_for_callback := false
var _selected_portable_character_id := ""
var _seen_steam_revision := -1


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
	_initialize_steam_optional()
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
	var launch_lobby := parse_connect_lobby(cmdline_tokens())
	if launch_lobby > 0:
		_pending_invite_id = launch_lobby
		_show_friend_invite()
		return
	_poll_pending_steam_invite()
	if _pending_invite_id > 0:
		_show_friend_invite()
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


## Steam launches an accepted cold invite with `+connect_lobby <uint64>`.
## Keep parsing pure, strict and separate from the legacy `--mp-*` parser so
## the owner/CI ENet launch flags retain their exact behavior.
static func parse_connect_lobby(arguments: PackedStringArray) -> int:
	for i in arguments.size():
		var token := arguments[i]
		var value := ""
		if token.begins_with("+connect_lobby="):
			value = token.substr("+connect_lobby=".length())
		elif token == "+connect_lobby" and i + 1 < arguments.size():
			value = arguments[i + 1]
		else:
			continue
		if value.is_valid_int():
			var lobby_id := int(value)
			return lobby_id if lobby_id > 0 else 0
		return 0
	return 0


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
	_title_panel = panel
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
	spacer.custom_minimum_size.y = 8
	root_box.add_child(spacer)

	# Six top-level actions fit the 1280x800 handheld target without shrinking
	# legibility. Godot scrolls a focused button into view automatically, so the
	# same container remains controller operable as each submenu changes height.
	_action_scroll = ScrollContainer.new()
	_action_scroll.follow_focus = true
	_action_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_action_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_action_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_action_scroll.custom_minimum_size.y = 250
	root_box.add_child(_action_scroll)
	var action_stack := VBoxContainer.new()
	action_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action_scroll.add_child(action_stack)

	_main_box = VBoxContainer.new()
	_main_box.add_theme_constant_override("separation", 14)
	_main_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_stack.add_child(_main_box)
	_new_button = _button("Start New Game")
	_load_button = _button("Load Game")
	_host_friends_button = _button("Host for Friends")
	_join_friend_button = _button("Join Friend")
	# The ENet/LAN flow remains as the advanced fallback and automation seam.
	# It is named as LAN here so address entry is never presented as satisfying
	# the invitation path.
	_join_button = _button("Join a Game on LAN")
	_quit_button = _button("Quit Game")
	_main_box.add_child(_new_button)
	_main_box.add_child(_load_button)
	_main_box.add_child(_host_friends_button)
	_main_box.add_child(_join_friend_button)
	_main_box.add_child(_join_button)
	_main_box.add_child(_quit_button)
	_new_button.pressed.connect(_on_new_pressed)
	_load_button.pressed.connect(_show_load_slots)
	_host_friends_button.pressed.connect(_show_host_friends_choices)
	_join_friend_button.pressed.connect(_show_friend_invite)
	_join_button.pressed.connect(_show_join)
	_quit_button.pressed.connect(func() -> void: get_tree().quit())

	_load_box = VBoxContainer.new()
	_load_box.visible = false
	_load_box.add_theme_constant_override("separation", 10)
	_load_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_stack.add_child(_load_box)

	_confirm_box = VBoxContainer.new()
	_confirm_box.visible = false
	_confirm_box.add_theme_constant_override("separation", 12)
	_confirm_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_stack.add_child(_confirm_box)

	_join_box = VBoxContainer.new()
	_join_box.visible = false
	_join_box.add_theme_constant_override("separation", 10)
	_join_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_stack.add_child(_join_box)

	_character_box = VBoxContainer.new()
	_character_box.visible = false
	_character_box.add_theme_constant_override("separation", 10)
	_character_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_stack.add_child(_character_box)
	_character_box.visibility_changed.connect(func() -> void:
		_title_panel.anchor_right = 0.945 if _character_box.visible else 0.445
		_title_panel.offset_right = 0.0)

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
##
## Each card shows an installed portrait and proper name. Optional atlas regions
## crop existing full-body portraits without introducing another image asset.
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

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	_character_box.add_child(row)

	var options := _load_character_options()
	var first: Button = null
	for raw: Variant in options:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var option := raw as Dictionary
		var id := str(option.get("id", ""))
		var display_name := str(option.get("display_name", id if not id.is_empty() else "Character"))
		var portrait_path := str(option.get("portrait", ""))
		var card := _button("")
		card.name = "Character_" + id
		card.set_meta("character_id", id)
		card.tooltip_text = display_name
		card.accessibility_name = display_name
		card.custom_minimum_size = Vector2(188, 224)
		card.add_theme_stylebox_override("normal", UITokens.panel_box(Color("#142c25"), Color("#507361")))
		card.add_theme_stylebox_override("hover", UITokens.panel_box(Color("#234337"), Color("#d4b96f")))
		card.add_theme_stylebox_override("focus", UITokens.panel_box_accent(Color("#f0ce77"), Color.TRANSPARENT))
		card.pressed.connect(func() -> void: on_chosen.call(id))
		row.add_child(card)
		var contents := VBoxContainer.new()
		contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		contents.offset_left = 20
		contents.offset_right = -20
		contents.offset_top = 18
		contents.offset_bottom = -18
		contents.alignment = BoxContainer.ALIGNMENT_CENTER
		contents.add_theme_constant_override("separation", 12)
		contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(contents)

		if not portrait_path.is_empty():
			var portrait := TextureRect.new()
			portrait.custom_minimum_size = Vector2(140, 140)
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var image: Texture2D = load(portrait_path) as Texture2D
			var crop: Array = option.get("portrait_region", [])
			if image != null and crop.size() == 4:
				var atlas := AtlasTexture.new()
				atlas.atlas = image
				atlas.region = Rect2(float(crop[0]), float(crop[1]), float(crop[2]), float(crop[3]))
				image = atlas
			if image != null:
				portrait.texture = image
			contents.add_child(portrait)
		var name_label := Label.new()
		name_label.text = display_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 26)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contents.add_child(name_label)
		if first == null:
			first = card
	if options.is_empty():
		var empty := Label.new()
		empty.text = "No character options are configured."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_character_box.add_child(empty)

	var back := _button("Back")
	back.pressed.connect(func() -> void: on_back.call())
	_character_box.add_child(back)
	var cards := row.get_children()
	for index in cards.size():
		var card := cards[index] as Button
		card.focus_neighbor_left = card.get_path_to(cards[(index - 1 + cards.size()) % cards.size()])
		card.focus_neighbor_right = card.get_path_to(cards[(index + 1) % cards.size()])
		card.focus_neighbor_bottom = card.get_path_to(back)
		card.focus_neighbor_top = card.get_path_to(card)
	if first != null:
		back.focus_neighbor_top = back.get_path_to(first)
	(first if first != null else back).grab_focus()
	UITokens.make_text_legible(_character_box)


func _start_new_game_with_character(character_id: String) -> void:
	_pending_character_option_id = character_id
	_prompt_for_player_name(character_id, func(chosen_name: String) -> void:
		_finish_new_game_with_identity(character_id, chosen_name)
	)


func _finish_new_game_with_identity(character_id: String, chosen_name: String) -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		_status.text = "Game state failed to start."
		return
	_pending_character_option_id = character_id
	# Set BEFORE reset_for_new_game(). PlayerState deliberately preserves the
	# identity fields across its run-state reset. Minting here guarantees Session
	# registers this genuinely fresh trainer by the id its saves will retain.
	_set_fresh_player_identity(game, character_id, chosen_name)
	game.call("reset_for_new_game")
	_enter_world("Starting new game…")


## The player-facing name choice shared by fresh solo/host and fresh-join
## paths. It reuses the established on-screen keyboard, so this remains fully
## operable on the handheld target as well as with a physical keyboard.
func _prompt_for_player_name(character_id: String, on_confirmed: Callable) -> void:
	if _player_name_prompt != null:
		return
	_player_name_prompt = NAME_PROMPT_SCENE.instantiate() as CanvasLayer
	add_child(_player_name_prompt)
	_player_name_prompt.connect("confirmed", func(chosen_name: String) -> void:
		_free_player_name_prompt()
		on_confirmed.call(chosen_name)
	)
	_player_name_prompt.connect("cancelled", _free_player_name_prompt)
	_player_name_prompt.call("open_entry", "Choose Your Trainer Name",
		_default_name_for_character(character_id), NAME_ENTRY.ROWS, NAME_ENTRY.MAX_LENGTH,
		"every trainer needs a name", true)


func _default_name_for_character(character_id: String) -> String:
	for raw: Variant in _load_character_options():
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == character_id:
			var configured := str((raw as Dictionary).get("display_name", "")).strip_edges()
			if not configured.is_empty():
				return configured
	return "Trainer"


func _free_player_name_prompt() -> void:
	if _player_name_prompt == null:
		return
	_player_name_prompt.queue_free()
	_player_name_prompt = null


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


# --- Steam friends ---------------------------------------------------------------

func _initialize_steam_optional() -> void:
	var game := _game()
	if game == null or not ResourceLoader.exists(STEAM_LOBBY_PATH):
		return
	var adapter: Variant = load(STEAM_LOBBY_PATH)
	if adapter == null or not adapter.has_method("ensure"):
		return
	var mounted: Variant = adapter.call("ensure", game)
	if mounted is Node:
		_steam_lobby = mounted as Node
	else:
		return
	if _steam_lobby.has_signal("invite_received"):
		_steam_lobby.connect("invite_received", _on_steam_invite_received)
	if _steam_lobby.has_signal("lobby_ready"):
		_steam_lobby.connect("lobby_ready", _on_steam_lobby_ready)
	if _steam_lobby.has_signal("changed"):
		_steam_lobby.connect("changed", _on_steam_changed)
	# Optional initialization is intentionally quiet. A machine without Steam
	# should see an explanation only after choosing a Steam action, while Solo
	# and LAN remain ordinary working choices.
	if _steam_lobby.has_method("initialize"):
		_steam_lobby.call("initialize")
	_seen_steam_revision = _steam_revision()


func _show_host_friends_choices() -> void:
	if not _steam_available():
		_status.text = _steam_error("Steam friends are unavailable in this build. You can still play Solo or use Join a Game on LAN.")
		_host_friends_button.grab_focus()
		return
	_friends_host_mode = true
	_main_box.visible = false
	_load_box.visible = false
	_character_box.visible = false
	_join_box.visible = false
	_clear(_confirm_box)
	_confirm_box.visible = true

	var heading := Label.new()
	heading.text = "Host for Friends"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 26)
	_confirm_box.add_child(heading)
	var detail := Label.new()
	detail.text = "Choose the world your friends will join. The lobby opens after that world finishes loading."
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_box.add_child(detail)

	var fresh := _button("Start a New World")
	var existing := _button("Load a Saved World")
	existing.disabled = _load_button.disabled
	var back := _button("Back")
	fresh.pressed.connect(_on_new_pressed)
	existing.pressed.connect(_show_load_slots)
	back.pressed.connect(_show_main)
	_confirm_box.add_child(fresh)
	_confirm_box.add_child(existing)
	_confirm_box.add_child(back)
	(fresh if not fresh.disabled else existing if not existing.disabled else back).grab_focus()
	UITokens.make_text_legible(_confirm_box)


func _show_friend_invite() -> void:
	_poll_pending_steam_invite()
	_main_box.visible = false
	_load_box.visible = false
	_confirm_box.visible = false
	_character_box.visible = false
	_stop_lan_listener()
	_clear(_join_box)
	_join_box.visible = true

	var heading := Label.new()
	heading.text = "Join Friend"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 26)
	_join_box.add_child(heading)
	var explanation := Label.new()
	explanation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.add_theme_font_size_override("font_size", 20)
	_join_box.add_child(explanation)

	var join: Button = null
	if _pending_invite_id > 0:
		explanation.text = _steam_status("A friend invited you to their world. Choose Join, then pick the portable character you want to bring.")
		join = _button("Join Friend")
		join.pressed.connect(_accept_friend_invite)
		_join_box.add_child(join)
	else:
		explanation.text = _steam_error("No friend invitation is waiting. Accept an invitation or use Steam Join Game, then return here.")
	var back := _button("Not Now" if _pending_invite_id > 0 else "Back")
	back.pressed.connect(_dismiss_friend_invite if _pending_invite_id > 0 else _show_main)
	_join_box.add_child(back)
	(join if join != null else back).grab_focus()
	UITokens.make_text_legible(_join_box)


func _accept_friend_invite() -> void:
	if _pending_invite_id <= 0 or not _steam_available():
		_status.text = _steam_error("That invitation is no longer available.")
		_show_friend_invite()
		return
	_joining_lobby_id = _pending_invite_id
	_steam_lobby_ready = false
	_remember_steam_retry()
	if not _steam_lobby.has_method("request_join") \
			or not bool(_steam_lobby.call("request_join", _joining_lobby_id)):
		_status.text = _steam_error("That friend’s lobby could not be joined.")
		_joining_lobby_id = 0
		_show_friend_invite()
		return
	if _steam_lobby.has_method("clear_pending_invite"):
		_steam_lobby.call("clear_pending_invite")
	_pending_invite_id = 0
	_show_portable_character_select()


func _show_portable_character_select() -> void:
	_main_box.visible = false
	_load_box.visible = false
	_confirm_box.visible = false
	_join_box.visible = false
	_clear(_character_box)
	_character_box.visible = true
	_character_back = _cancel_steam_join

	var heading := Label.new()
	heading.text = "Choose a Character to Bring"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 26)
	_character_box.add_child(heading)
	var detail := Label.new()
	detail.text = "Your character, team of up to five, equipment, and personal progress travel with you. Your own world does not."
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_character_box.add_child(detail)

	var game := _game()
	var characters: Variant = null
	if game != null:
		var save_system: Variant = game.get("save_system")
		if save_system is Object and (save_system as Object).has_method("characters"):
			characters = (save_system as Object).call("characters")
	var first: Button = null
	if characters is Object and (characters as Object).has_method("list_ids"):
		for raw_id: Variant in (characters as Object).call("list_ids") as Array:
			var character_id := str(raw_id)
			var state: Dictionary = (characters as Object).call("state", character_id)
			if state.is_empty():
				continue
			var display_name := str(state.get("display_name", "Trainer")).strip_edges()
			if display_name.is_empty():
				display_name = "Trainer"
			var party: Variant = state.get("party", [])
			var party_size := (party as Array).size() if party is Array else 0
			var realm := str(state.get("realm", "meadows")).capitalize()
			var pick := _button("%s — %d Pals · %s" % [display_name, party_size, realm])
			pick.set_meta("character_id", character_id)
			pick.pressed.connect(func() -> void: _choose_portable_character(character_id))
			_character_box.add_child(pick)
			if first == null:
				first = pick
			if character_id == _selected_portable_character_id:
				first = pick

	var create := _button("Create a New Character")
	create.pressed.connect(func() -> void:
		_show_character_select(_choose_new_steam_appearance, _show_portable_character_select))
	_character_box.add_child(create)
	var back := _button("Back")
	back.pressed.connect(_cancel_steam_join)
	_character_box.add_child(back)
	(first if first != null else create).grab_focus()
	UITokens.make_text_legible(_character_box)


func _choose_portable_character(character_id: String) -> void:
	_selected_portable_character_id = character_id
	_steam_character_pending = {"kind": "existing", "character_id": character_id}
	_remember_steam_retry()
	_status.text = _steam_status("Character selected. Waiting for the friend lobby…")
	_start_pending_steam_join()


func _choose_new_steam_appearance(appearance_id: String) -> void:
	_pending_character_option_id = appearance_id
	_prompt_for_player_name(appearance_id, func(chosen_name: String) -> void:
		_steam_character_pending = {
			"kind": "new",
			"appearance_id": appearance_id,
			"display_name": chosen_name,
		}
		_remember_steam_retry()
		_status.text = _steam_status("Character ready. Waiting for the friend lobby…")
		_start_pending_steam_join()
	)


func _on_steam_lobby_ready() -> void:
	_steam_lobby_ready = true
	_start_pending_steam_join()


func _start_pending_steam_join() -> void:
	if not _steam_lobby_ready or _steam_character_pending.is_empty():
		return
	var game := _game()
	if game == null:
		_status.text = "Game state failed to start."
		return

	# A guest imports no local world. Clear the transient run first, then apply
	# exactly the portable character the player selected. This is deliberately
	# separate from `_begin_join()`, whose legacy LAN continuation honors slot 0.
	if not prepare_steam_character(game, _steam_character_pending):
		_status.text = "That portable character could not be loaded. Choose another character."
		_steam_character_pending = {}
		_show_portable_character_select()
		return

	var summary := steam_character_summary(game)
	if str(summary.get("character_id", "")).is_empty():
		# Session normally mints this during join. The Steam adapter needs the
		# stable id in hand before it creates the peer, so mint the same durable
		# form here for a deliberately new character.
		var local: Variant = game.get("local")
		var fresh_id: String = CHARACTER_IDENTITY.mint()
		(local as Object).set("character_id", fresh_id)
		summary["character_id"] = fresh_id
	var driver := _mount_join_driver(game)
	driver.call("begin_steam", summary)
	_remember_steam_retry()
	_go_to_world("Joining your friend…")


static func steam_character_summary(game: Object) -> Dictionary:
	if game == null:
		return {}
	var local: Variant = game.get("local")
	if not local is Object:
		return {}
	return {
		"character_id": str((local as Object).get("character_id")),
		"display_name": str((local as Object).get("display_name")),
		"realm": str(game.get("current_realm")),
		"appearance_id": str((local as Object).get("chosen_character")),
	}


## Purely owns the local-state side of a Steam join. It intentionally has no
## lobby calls, making the world/character boundary directly regression-testable.
static func prepare_steam_character(game: Object, selection: Dictionary) -> bool:
	if game == null:
		return false
	game.call("reset_for_new_game")
	if str(selection.get("kind", "")) == "new":
		_set_fresh_player_identity(game, str(selection.get("appearance_id", "trainer")),
			str(selection.get("display_name", "Trainer")))
		return true
	if str(selection.get("kind", "")) != "existing":
		return false
	var save_system: Variant = game.get("save_system")
	if not save_system is Object or not (save_system as Object).has_method("characters"):
		return false
	var characters: Variant = (save_system as Object).call("characters")
	return characters is Object and bool((characters as Object).call("apply", game,
		str(selection.get("character_id", ""))))


func _cancel_steam_join() -> void:
	if _steam_lobby != null and _steam_lobby.has_method("cancel_join"):
		_steam_lobby.call("cancel_join")
	_joining_lobby_id = 0
	_steam_lobby_ready = false
	_steam_character_pending = {}
	_steam_retry_waiting_for_callback = false
	_show_main()


func _remember_steam_retry() -> void:
	var game := _game()
	if game == null or _joining_lobby_id <= 0:
		return
	game.set_meta(&"steam_join_retry", {
		"lobby_id": _joining_lobby_id,
		"selection": _steam_character_pending.duplicate(true),
	})


func _dismiss_friend_invite() -> void:
	_pending_invite_id = 0
	if _steam_lobby != null and _steam_lobby.has_method("clear_pending_invite"):
		_steam_lobby.call("clear_pending_invite")
	_show_main()


func _show_failed_friend_join(message: String) -> void:
	_main_box.visible = false
	_load_box.visible = false
	_confirm_box.visible = false
	_character_box.visible = false
	_stop_lan_listener()
	_clear(_join_box)
	_join_box.visible = true
	var heading := Label.new()
	heading.text = "Join Friend"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 26)
	_join_box.add_child(heading)
	var reason := Label.new()
	reason.text = message
	reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_join_box.add_child(reason)
	var game := _game()
	var saved: Dictionary = game.get_meta(&"steam_join_retry", {}) if game != null else {}
	var saved_selection: Variant = saved.get("selection", {})
	var saved_lobby_id := int(saved.get("lobby_id", 0))
	var pending_reason := _steam_retry_pending_reason(saved_lobby_id)
	_steam_retry_waiting_for_callback = not pending_reason.is_empty()
	var retry: Button = null
	if steam_retry_is_actionable(pending_reason):
		retry = _button("Retry with the Same Character" \
			if saved_selection is Dictionary and not (saved_selection as Dictionary).is_empty() \
			else "Retry")
		retry.pressed.connect(_retry_failed_friend_join)
		_join_box.add_child(retry)
	var back := _button("Back")
	back.pressed.connect(_dismiss_failed_friend_join)
	_join_box.add_child(back)
	if retry != null:
		retry.grab_focus()
	else:
		back.grab_focus()
	UITokens.make_text_legible(_join_box)


func _retry_failed_friend_join() -> void:
	var game := _game()
	var retry: Dictionary = game.get_meta(&"steam_join_retry", {}) if game != null else {}
	var lobby_id := int(retry.get("lobby_id", 0))
	var selection: Variant = retry.get("selection", {})
	if lobby_id <= 0 or not selection is Dictionary or not _steam_available():
		_status.text = _steam_error("That friend lobby can no longer be retried.")
		return
	_joining_lobby_id = lobby_id
	_steam_character_pending = (selection as Dictionary).duplicate(true)
	_selected_portable_character_id = str(_steam_character_pending.get("character_id", ""))
	_steam_lobby_ready = false
	if not bool(_steam_lobby.call("request_join", lobby_id)):
		_joining_lobby_id = 0
		_status.text = _steam_error("That friend lobby could not be rejoined yet.")
		return
	_status.text = _steam_status("Rejoining your friend’s lobby…")
	if _steam_character_pending.is_empty():
		_show_portable_character_select()


func _dismiss_failed_friend_join() -> void:
	var game := _game()
	if game != null:
		game.remove_meta(&"steam_join_retry")
	_cancel_steam_join()


func _on_steam_invite_received(lobby_id: int) -> void:
	if lobby_id <= 0 or _joining_lobby_id > 0:
		return
	_pending_invite_id = lobby_id
	# Never replace either on-screen keyboard. Its B button owns backspace and
	# cancellation, and a new network callback cannot steal that input context.
	if _address_prompt != null or _player_name_prompt != null:
		_status.text = "Friend invitation received. Finish this entry to respond."
		return
	if _main_box.visible:
		_show_friend_invite()
	else:
		_status.text = "Friend invitation received. Return to the title choices to respond."


func _on_steam_changed() -> void:
	_seen_steam_revision = _steam_revision()
	if _joining_lobby_id <= 0:
		if _steam_retry_waiting_for_callback:
			var game := _game()
			var saved: Dictionary = game.get_meta(&"steam_join_retry", {}) if game != null else {}
			var lobby_id := int(saved.get("lobby_id", 0))
			if _steam_retry_pending_reason(lobby_id).is_empty():
				_steam_retry_waiting_for_callback = false
				_show_failed_friend_join(
					"Steam finished the previous request. You can retry joining your friend.")
		return
	var failure := _steam_error("")
	if pending_steam_join_has_failure(_joining_lobby_id, failure):
		_remember_steam_retry()
		_joining_lobby_id = 0
		_steam_lobby_ready = false
		_show_failed_friend_join(failure)
		return
	# A lobby can become ready, then lose its host while the player is still
	# choosing a character.  Failure wins over that cached readiness: carrying
	# the old flag into `_start_pending_steam_join()` would reset the selected
	# character and build a world for a lobby that has already gone away.
	if _steam_lobby_ready:
		return
	_status.text = _steam_status(_status.text)


## Kept pure for the focused invite UI regression: a later native failure must
## invalidate a previously received ready callback while this title owns a
## pending friend join.
static func pending_steam_join_has_failure(joining_lobby_id: int, error: String) -> bool:
	return joining_lobby_id > 0 and not error.strip_edges().is_empty()


static func steam_retry_is_actionable(pending_reason: String) -> bool:
	return pending_reason.strip_edges().is_empty()


func _steam_retry_pending_reason(lobby_id: int) -> String:
	if _steam_lobby != null and _steam_lobby.has_method("retry_pending_reason"):
		return str(_steam_lobby.call("retry_pending_reason", lobby_id)).strip_edges()
	return ""


func _poll_pending_steam_invite() -> void:
	if _steam_lobby == null or _joining_lobby_id > 0:
		return
	if _steam_lobby.has_method("pending_invite_id"):
		var found := int(_steam_lobby.call("pending_invite_id"))
		if found > 0:
			_pending_invite_id = found


func _steam_available() -> bool:
	if _steam_lobby == null:
		_initialize_steam_optional()
	if _steam_lobby == null or not _steam_lobby.has_method("initialize"):
		return false
	return bool(_steam_lobby.call("initialize"))


func _steam_error(fallback: String) -> String:
	if _steam_lobby != null and _steam_lobby.has_method("last_error"):
		var message := str(_steam_lobby.call("last_error")).strip_edges()
		if not message.is_empty():
			return message
	return fallback


func _steam_status(fallback: String) -> String:
	if _steam_lobby != null and _steam_lobby.has_method("status_text"):
		var message := str(_steam_lobby.call("status_text")).strip_edges()
		if not message.is_empty():
			return message
	return fallback


func _steam_revision() -> int:
	if _steam_lobby != null and _steam_lobby.has_method("revision"):
		return int(_steam_lobby.call("revision"))
	return 0


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
## resumes either this machine's local autosave or its current portable guest
## character is a returning player and gets no new-game step for the same
## reason Load Game never shows this screen.
func _join_via(address: String, port: int) -> void:
	var game := _game()
	if game != null and (bool(game.call("has_save", 0)) or _has_portable_returning_character(game)):
		_begin_join(address, port, 0.0)
		return
	_show_character_select(func(character_id: String) -> void:
		_pending_character_option_id = character_id
		_prompt_for_player_name(character_id, func(chosen_name: String) -> void:
			_set_fresh_player_identity(game, character_id, chosen_name)
			_begin_join(address, port, 0.0)
		)
	, _show_join)


## Game is deliberately the project's only autoload; PlayerState is its
## `local` container, not a second `/root/PlayerState` singleton.
static func _set_chosen_character(game: Object, character_id: String) -> void:
	if game == null:
		return
	var local: Variant = game.get("local")
	if local is Object:
		(local as Object).set("chosen_character", character_id if not character_id.is_empty() else "trainer")


## Stamp the choices made by a fresh trainer, including a new portable id.
## PlayerState.reset() deliberately preserves these identity fields, so this
## survives the reset that follows on the ordinary new-game path.
static func _set_fresh_player_identity(game: Object, character_id: String, display_name: String) -> void:
	if game == null:
		return
	var local: Variant = game.get("local")
	if not local is Object:
		return
	(local as Object).set("character_id", CHARACTER_IDENTITY.mint())
	(local as Object).set("chosen_character", character_id if not character_id.is_empty() else "trainer")
	var cleaned := display_name.strip_edges()
	while cleaned.contains("  "):
		cleaned = cleaned.replace("  ", " ")
	if cleaned.length() > NAME_ENTRY.MAX_LENGTH:
		cleaned = cleaned.substr(0, NAME_ENTRY.MAX_LENGTH)
	(local as Object).set("display_name", cleaned if not cleaned.is_empty() else "Trainer")


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

	# Prefer the local autosave the player already chose. A returning guest has
	# no world autosave (clients never write one), so its portable character is
	# the second continuation source. Only a machine with neither starts fresh.
	if bool(game.call("has_save", 0)):
		game.call("load_game", 0)
	elif not _restore_portable_returning_character(game):
		# A new guest has neither a local autosave nor a portable character.
		# Keep the existing fresh-character path, including the choice made by
		# `_join_via` immediately before this call.
		game.call("reset_for_new_game")
	else:
		print("[title] restored returning guest character before joining")

	# Owner ruling 2026-09-26 (MULTIPLAYER Return-home placement): the saved pose
	# is resumed only in the SAME host world, which is unknown until the host
	# snapshot arrives. Take it off the live character before the world builds
	# (so no world ever places a pose from somewhere else) and let
	# `rejoin_pose.gd` decide against the snapshot's instance.
	_mount_rejoin_pose(game, rejoin_pose_candidate(game))
	game.set("saved_player_pose", {})
	# A loaded home slot also queues its fly/traversal state (safe anchor,
	# stamina) for the next world; that belongs to the slot's world too.
	if game.has_meta("pending_fly_load"):
		game.remove_meta("pending_fly_load")

	var driver := _mount_join_driver(game)
	driver.call("begin", address, port if port > 0 else _configured_port(), retry_for_s)
	_go_to_world("Joining %s…" % address)


## The pose this character last saved and the world instance it saved it in,
## read from its own character file -- the one record that pairs the two (a
## loaded home slot has already dropped a foreign pose). {} for a new character.
static func rejoin_pose_candidate(game: Node) -> Dictionary:
	var local: Variant = game.get("local") if game != null else null
	var save_system: Variant = game.get("save_system") if game != null else null
	if local == null or not save_system is Object or not (save_system as Object).has_method("characters"):
		return {}
	var characters: Variant = (save_system as Object).call("characters")
	var character_id := str((local as RefCounted).get("character_id"))
	if character_id.is_empty() or not characters is Object:
		return {}
	var saved: Dictionary = (characters as Object).call("read", character_id)
	if saved.is_empty():
		return {}
	return {"pose": saved.get("player_pose", {}), "world_instance_id": saved.get("last_world_instance_id", null)}


func _mount_rejoin_pose(game: Node, candidate: Dictionary) -> void:
	var existing := game.get_node_or_null(^"RejoinPose")
	if existing != null:
		existing.free()
	var helper: Node = REJOIN_POSE.new()
	helper.name = "RejoinPose"
	helper.call("configure", candidate)
	game.add_child(helper)


## A client writes only its portable character file on disconnect. It has no
## world autosave for the branch above, but its live character id survives the
## return to title and addresses the file to resume. Missing or unreadable
## files are a new-character join and leave the established picker behavior.
func _restore_portable_returning_character(game: Node) -> bool:
	if not _has_portable_returning_character(game):
		return false
	var local: Variant = game.get("local")
	var save_system: Variant = game.get("save_system")
	var character_id := str((local as RefCounted).get("character_id"))
	var characters: Variant = (save_system as RefCounted).call("characters")
	return bool((characters as RefCounted).call("apply", game, character_id))


func _has_portable_returning_character(game: Node) -> bool:
	var local: Variant = game.get("local")
	var save_system: Variant = game.get("save_system")
	if local == null or save_system == null:
		return false
	var character_id := str((local as RefCounted).get("character_id"))
	if character_id.is_empty():
		return false
	var characters: Variant = (save_system as RefCounted).call("characters")
	if characters == null or not bool((characters as RefCounted).call("has", character_id)):
		return false
	# `has()` is a recoverable-path check. Parse too, without applying, so a
	# corrupt portable file does not suppress the new-character picker.
	return not ((characters as RefCounted).call("state", character_id) as Dictionary).is_empty()


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
	var was_steam := driver.has_method("target") and str(driver.call("target")) == "friend’s world"
	driver.free()
	if message.is_empty():
		if game.has_meta(&"steam_join_retry"):
			game.remove_meta(&"steam_join_retry")
		return false
	_status.text = message
	if was_steam:
		_show_failed_friend_join(message)
	else:
		_show_join()
	return true


func _process(_delta: float) -> void:
	if _join_box.visible and _lan != null:
		_refresh_lan_list()
	_poll_pending_steam_invite()
	var revision := _steam_revision()
	if revision != _seen_steam_revision:
		_seen_steam_revision = revision
		_on_steam_changed()
	# A runtime invitation becomes an explicit title choice. Do not replace a
	# sub-flow or either text prompt; the status line tells those players to
	# finish/back out, and the invitation remains pending.
	if _pending_invite_id > 0 and _joining_lobby_id == 0 \
			and _main_box != null and _main_box.visible \
			and _address_prompt == null and _player_name_prompt == null:
		_show_friend_invite()


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
	if _friends_host_mode:
		if not _steam_available() or not _steam_lobby.has_method("begin_host_after_world") \
				or not bool(_steam_lobby.call("begin_host_after_world")):
			_status.text = _steam_error("A friends-only lobby could not be prepared. Your world has not been opened.")
			_set_buttons_disabled(false)
			return
		# SteamLobby owns the delayed peer/lobby creation after the destination
		# world settles. Do not briefly bind ENet or advertise a LAN address on
		# this route: Session must have one transport, with one honest identity.
		game.set_meta(&"steam_host_requested", true)
		_go_to_world(message)
		return
	if game != null and game.has_meta(&"steam_host_requested"):
		game.remove_meta(&"steam_host_requested")
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
	_friends_host_mode = false
	_confirm_box.visible = false
	_character_box.visible = false
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
	# Not while a text prompt is up: B is that panel's backspace, and it
	# closes itself (`name_prompt.gd::_cancel`) once there is nothing left to
	# delete. Two readers of one button is one of them acting on a press the
	# player aimed at the other.
	if _address_prompt != null or _player_name_prompt != null:
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
	if event.is_action_pressed("menu_cancel") and _join_box.visible:
		var game := _game()
		if _pending_invite_id > 0:
			_dismiss_friend_invite()
		elif game != null and game.has_meta(&"steam_join_retry"):
			_dismiss_failed_friend_join()
		else:
			_show_main()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("menu_cancel") \
			and (_load_box.visible or _confirm_box.visible or _character_box.visible
				or _join_box.visible):
		_show_main()
		get_viewport().set_input_as_handled()
