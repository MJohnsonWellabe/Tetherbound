extends CanvasLayer

## The real exploration HUD (`ENVIRONMENT_AND_UI_BIBLE.md` §16-18, EV9).
##
## Draws only what the bible keeps on screen while exploring: health and
## stamina (faded out when neither is doing anything interesting), the party
## and orb counts, `HD2`'s quick-access item hotbar, and the one contextual
## interact prompt. Everything else —
## the raw movement/input telemetry this HUD used to dump permanently — is
## still here, because M1 tuning still needs it, but it now lives behind an
## F3 toggle instead of covering a third of the screen by default.
##
## Sized for the Ally: the project authors at 1920x1080 and stretches
## canvas_items, so text set here is at real handheld pixel density.
##
## No objective line yet: the bible asks for "concise current objective," but
## there is no objective/quest state to read (`SB9`/`SB11`, both still open).
## Wiring a label to nothing would just be a permanent blank box, which is the
## opposite of what §16 asks for ("hide/fade what is not relevant"). A
## follow-on EV9 slice adds the line once that state exists. Same reasoning
## for the compass: §16 says "if it exists," and it does not yet.

## Dark blue-gray translucent panel, thin pale border, teal accent — the
## visual language §16 asks for. No prior HUD panel establishes this; this is
## the first one, so later screens (inventory, crafting) match against it
## rather than the other way round.
const PANEL_BG := Color(0.07, 0.09, 0.13, 0.78)
const PANEL_BORDER := Color(0.55, 0.85, 0.86, 0.65)
## Deliberately more saturated and bluer than PANEL_BORDER — the two read as
## the same colour at a glance otherwise, and the stamina fill needs to stand
## out from its own panel's border, not match it.
const ACCENT_TEAL := Color(0.16, 0.58, 0.76)
const HEALTH_FULL := Color(0.38, 0.64, 0.30)
const HEALTH_LOW := Color(0.74, 0.24, 0.20)
const TRACK := Color(0.05, 0.05, 0.06, 0.85)

## Same treatment combat_hud.gd uses for anything floating over the world with
## no panel behind it — measured contrast on unplated white text there was
## below the large-text minimum, and the party/orb/prompt labels here sit over
## the same kind of unpredictable backdrop.
const OUTLINE := Color(0.03, 0.04, 0.05, 0.95)
const OUTLINE_SIZE := 6
const SHADOW := Color(0.0, 0.0, 0.0, 0.55)
const SHADOW_OFFSET := Vector2(0.0, 2.0)

## A bar at rest fades to this rather than to zero: gone-and-back-again on
## every full heal reads as a layout pop, faint-but-present does not. Blind
## visual review flagged the first value tried (0.28) as unreadable — the fill
## and track blended into each other and the low-alpha edges read as a
## rendering artefact rather than a calm bar.
const FADE_ALPHA := 0.55
const FADE_SPEED := 2.2

const READOUT_INTERVAL := 0.1

## F3 cycles OFF -> PERF -> FULL rather than toggling.
##
## PERF is the mode you leave up while playing: frame time and the render
## counters and nothing else. FULL adds the M1 movement block and the input
## diagnostics, which are ~25 lines of text that push the perf numbers off the
## bottom of the Label and are irrelevant to a performance session.
const DEBUG_OFF := 0
const DEBUG_PERF := 1
const DEBUG_FULL := 2

## ~2 seconds of frames at 60 Hz. The window has to be long enough that an
## occasional spike still shows up in `max` a moment later, and short enough
## that walking from a clear field into the tree line moves the numbers while
## you are still looking at the tree line.
const FRAME_WINDOW := 120

const MB := 1048576.0

const PARTY := preload("res://autoload/party.gd")
const ORB_ITEM_ID := "orb_basic"
const INPUT_GLYPH := preload("res://scripts/ui/input_glyph.gd")

## HD2: a real quick-access item hotbar. GAME_DESIGN.md 19's "quick tool
## selection" is scoped separately (`tool_cycle`, R2.1/EV9's own history) --
## this is the first general CONSUMABLE band the spec asks for, so it gets
## its own five input actions (`hotbar_1`..`hotbar_5`) rather than reusing
## that one.
##
## Deliberately does NOT read `autoload/inventory.gd`'s satchel through a
## second entry point: the five slots shown here ARE satchel slots 0-4, the
## same "first row doubles as the quick-select band" slots that file's own
## header comment already reserved for exactly this ("nothing reads it yet
## ... so the grid and the future hotbar cannot disagree about which slots
## they mean"). Moving a stack onto/off of slot 0-4 in the backpack tab
## moves it in or out of the hotbar for free, with no separate "assign to
## hotbar" step to build or explain.
const HOTBAR_SLOTS := 5
## Action name IS the glyph id (input_glyph.gd's GLYPHS dict uses the same
## keys), so one list serves both jobs.
const HOTBAR_ACTIONS := ["hotbar_1", "hotbar_2", "hotbar_3", "hotbar_4", "hotbar_5"]

const HOTBAR_MESSAGE_SECONDS := 2.2

@export var player_path: NodePath
@export var arbiter_path: NodePath

## Seconds a pad must be connected with every raw axis pinned near zero before
## the debug view suggests the Ally-specific cause. Long enough that a player
## who is simply reading the screen before touching the stick does not get an
## irrelevant warning; short enough to answer "why won't it move" quickly.
const STUCK_AXES_HINT_AFTER := 3.0
const STUCK_AXES_EPSILON := 0.05

var _player: CharacterBody3D = null
var _arbiter: Node = null
var _game: Node = null
## -1 rather than 0 so the first frame always writes both labels; a real count
## of zero would otherwise leave them showing the scene's placeholder text.
var _last_pals := -1
var _last_orbs := -1
var _since_readout := 0.0
var _peak_fall := 0.0
var _last_damage := 0.0
var _debug_level := DEBUG_OFF

## Frame times in milliseconds, as a fixed-size ring.
##
## Pre-sized and written by index on purpose: an overlay that allocates every
## frame measures itself. Nothing here scans the ring — that happens inside the
## 0.1 s throttle, so the min/max pass runs ten times a second, not sixty.
var _frame_ms := PackedFloat32Array()
var _frame_head := 0
var _frame_filled := 0

## Which adapter and driver are ACTUALLY live, resolved once at boot.
##
## The single most load-bearing line in the readout. `fallback_to_angle`
## defaults true and Godot carries a device blocklist that can force ANGLE on,
## while `fallback_to_native` can quietly put a failed ANGLE start back on
## native OpenGL. So the driver the project asked for and the driver that is
## running are two different facts, and until this line existed only one of them
## was visible. Under ANGLE the adapter name contains "ANGLE (... Direct3D11
## ...)"; under native WGL it is the bare adapter string.
var _hardware_line := ""

## Tracks whether a connected pad has EVER reported a non-trivial axis value.
## A single frame's reading cannot tell "not touching the stick right now"
## apart from "the stick physically cannot reach Godot" — this can, given a
## few seconds.
var _pad_connected_for := 0.0
var _max_raw_axis_seen := 0.0

@onready var _health_bar: ProgressBar = $Root/VitalsPanel/Margin/Bars/HealthRow/Health
@onready var _stamina_bar: ProgressBar = $Root/VitalsPanel/Margin/Bars/StaminaRow/Stamina
@onready var _health_label: Label = $Root/VitalsPanel/Margin/Bars/HealthRow/HealthLabel
@onready var _stamina_label: Label = $Root/VitalsPanel/Margin/Bars/StaminaRow/StaminaLabel
@onready var _party_label: Label = $Root/StatusPanel/Margin/Rows/Party
@onready var _orbs_label: Label = $Root/StatusPanel/Margin/Rows/Orbs
@onready var _prompt_label: RichTextLabel = $Root/Prompt
@onready var _debug_readout: Label = $Root/DebugReadout
@onready var _hotbar_slots: Array[RichTextLabel] = [
	$Root/HotbarPanel/Margin/Layout/Slots/Slot1,
	$Root/HotbarPanel/Margin/Layout/Slots/Slot2,
	$Root/HotbarPanel/Margin/Layout/Slots/Slot3,
	$Root/HotbarPanel/Margin/Layout/Slots/Slot4,
	$Root/HotbarPanel/Margin/Layout/Slots/Slot5,
]
@onready var _hotbar_message: Label = $Root/HotbarPanel/Margin/Layout/Message

## What each slot last rendered, so `_update_hotbar` only writes a Label when
## its text actually changed -- the same discipline `_update_status` already
## uses, for the same reason (an outlined RichTextLabel re-shapes on every
## assignment; this polls every frame while `_update_status` only changes on
## a pickup).
var _hotbar_last_text: Array[String] = ["", "", "", "", ""]
var _hotbar_message_until := 0.0

var _health_fill: StyleBoxFlat = null
var _stamina_fill: StyleBoxFlat = null


func _ready() -> void:
	_player = get_node_or_null(player_path) as CharacterBody3D
	if _player == null:
		push_warning("HUD has no player; readout will stay empty")
	elif _player.has_signal("landed"):
		_player.connect("landed", _on_landed)

	_arbiter = get_node_or_null(arbiter_path)
	if _arbiter != null and _arbiter.has_signal("prompt_changed"):
		_arbiter.connect("prompt_changed", _on_prompt_changed)

	_style_panel($Root/VitalsPanel)
	_style_panel($Root/StatusPanel)
	_style_panel($Root/HotbarPanel)
	_health_fill = _fill_style(HEALTH_FULL)
	_stamina_fill = _fill_style(ACCENT_TEAL)
	_dress_bar(_health_bar, _health_fill)
	_dress_bar(_stamina_bar, _stamina_fill)
	_make_text_legible(_health_label)
	_make_text_legible(_stamina_label)
	_make_text_legible(_party_label)
	_make_text_legible(_orbs_label)
	_make_text_legible(_prompt_label)
	for slot in _hotbar_slots:
		_make_text_legible(slot)
	_make_text_legible(_hotbar_message)

	_frame_ms.resize(FRAME_WINDOW)
	_hardware_line = "%s | %s | driver %s" % [
		RenderingServer.get_video_adapter_name(),
		str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "?")),
		"/".join(OS.get_video_adapter_driver_info()),
	]

	_debug_readout.visible = _debug_level != DEBUG_OFF

	# Seeded from the arbiter rather than blanked, because `prompt_changed`
	# only fires on a CHANGE: if the arbiter published before this HUD
	# connected, waiting for the next edge would leave the prompt blank while
	# the player stands in front of something interactable.
	_prompt_label.text = str(_arbiter.call("prompt")) if _arbiter != null else ""


func _style_panel(panel: PanelContainer) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL_BG
	box.border_color = PANEL_BORDER
	box.border_width_left = 2
	box.border_width_right = 2
	box.border_width_top = 2
	box.border_width_bottom = 2
	box.corner_radius_top_left = 14
	box.corner_radius_top_right = 14
	box.corner_radius_bottom_left = 14
	box.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", box)


func _fill_style(colour: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = colour
	box.corner_radius_top_left = 8
	box.corner_radius_top_right = 8
	box.corner_radius_bottom_left = 8
	box.corner_radius_bottom_right = 8
	return box


func _dress_bar(bar: ProgressBar, fill: StyleBoxFlat) -> void:
	var track := _fill_style(TRACK)
	bar.add_theme_stylebox_override("background", track)
	bar.add_theme_stylebox_override("fill", fill)


## Same walk combat_hud.gd uses: outline and shadow every label under `node`,
## whatever gets added later.
func _make_text_legible(node: Node) -> void:
	if node is Label or node is RichTextLabel:
		var control := node as Control
		control.add_theme_constant_override("outline_size", OUTLINE_SIZE)
		control.add_theme_color_override("font_outline_color", OUTLINE)
		control.add_theme_color_override("font_shadow_color", SHADOW)
		control.add_theme_constant_override("shadow_offset_x", int(SHADOW_OFFSET.x))
		control.add_theme_constant_override("shadow_offset_y", int(SHADOW_OFFSET.y))
	for child in node.get_children():
		_make_text_legible(child)


func _on_landed(impact_speed: float, damage: float) -> void:
	_peak_fall = maxf(_peak_fall, impact_speed)
	_last_damage = damage


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_debug_level = (_debug_level + 1) % 3
		_debug_readout.visible = _debug_level != DEBUG_OFF


## The readout runs BEFORE the player checks, not after them.
##
## It used to sit at the bottom of this function behind two early returns for a
## null player and null vitals, so a scene with no player — a capture tool, a
## test harness — could not show a frame-time readout at all. Frame time is a
## property of the frame, not of the player.
func _process(delta: float) -> void:
	if _debug_level != DEBUG_OFF:
		_sample_frame(delta)
		_since_readout += delta
		if _since_readout >= READOUT_INTERVAL:
			_since_readout = 0.0
			_debug_readout.text = _debug_text()

	_update_status()
	_read_hotbar_input()
	if _player == null:
		return
	var vitals: RefCounted = _player.get("vitals")
	if vitals == null:
		return

	_update_vitals(vitals, delta)


## One array write and two integers. Everything expensive is in `_perf_lines`,
## which only runs on the throttle.
func _sample_frame(delta: float) -> void:
	_frame_ms[_frame_head] = delta * 1000.0
	_frame_head = (_frame_head + 1) % FRAME_WINDOW
	_frame_filled = mini(_frame_filled + 1, FRAME_WINDOW)


## What the frame cost, and what it was spent on.
##
## This exists because three performance fixes have shipped on this project
## without a single frame-time measurement from the device they were for
## (`SA1`, `SA1-lod`, the shadow-atlas cut — all still "on-device confirmation
## open"). Software rendering cannot measure frame time honestly (`D06`), so the
## only instrument that can settle any of it is one the owner can read on the
## Ally.
##
## `min`/`max` are here rather than an average alone because the three shapes a
## bad frame time comes in need three different fixes and are indistinguishable
## from the average:
##
##   - steady 24 ms          -> throughput. Draw fewer things, or draw them smaller.
##   - 16 ms with 60 ms spikes -> a hitch. Streaming, a shader compile, an allocation.
##   - a hard 16.7/33.3 split  -> vsync half-rate. Nothing about the scene matters.
func _perf_lines() -> Array[String]:
	var worst := 0.0
	var best := 0.0
	var total := 0.0
	if _frame_filled > 0:
		best = _frame_ms[0]
		for i in _frame_filled:
			var ms: float = _frame_ms[i]
			total += ms
			worst = maxf(worst, ms)
			best = minf(best, ms)
	var avg: float = total / float(_frame_filled) if _frame_filled > 0 else 0.0

	var vp := get_viewport()
	var scale: float = vp.scaling_3d_scale if vp != null else 1.0
	var size: Vector2i = vp.get_visible_rect().size if vp != null else Vector2i.ZERO

	# The vsync mode is READ BACK, not echoed from what was requested. Windows
	# OpenGL can silently refuse mailbox/adaptive and fall back to plain vsync,
	# and a knob whose effect cannot be seen is how a fourth blind fix gets
	# shipped.
	var vsync := -1
	if DisplayServer.get_name() != "headless":
		vsync = int(DisplayServer.window_get_vsync_mode())

	return [
		"perf (F3 again for movement/input, once more to hide)",
		"",
		"fps        %d      frame %.1f ms   min %.1f   max %.1f" % [
			Engine.get_frames_per_second(), avg, best, worst,
		],
		"draw calls %d      primitives %d" % [
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		],
		"video mem  %.0f MB   textures %.0f MB" % [
			Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / MB,
			Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / MB,
		],
		"static mem %.0f MB   nodes %d" % [
			Performance.get_monitor(Performance.MEMORY_STATIC) / MB,
			int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		],
		"cpu        process %.2f ms   physics %.2f ms" % [
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		],
		"3d scale   %.2f  (%d x %d)   msaa %d" % [
			scale, int(size.x * scale), int(size.y * scale),
			int(vp.msaa_3d) if vp != null else 0,
		],
		"vsync      %d      max_fps %d" % [vsync, Engine.max_fps],
		_hardware_line,
	]


## Driven by the arbiter's signal, not polled.
##
## This used to run every idle frame: a dynamic `call("prompt")` plus a
## RichTextLabel text assignment, sixty times a second, for a string that
## changes a few times a minute. RichTextLabel re-parses and re-lays out on
## every assignment, which made it the most expensive thing this HUD did.
##
## The arbiter has emitted `prompt_changed` only on an actual change since it
## was written (`interaction_arbiter.gd:157`) — the HUD was simply polling past
## it.
func _on_prompt_changed(text: String) -> void:
	_prompt_label.text = text


## Looked up by path rather than through the `Game` global, matching
## sequence_director.gd's convention, so a HUD instanced without the autoload
## running (a capture tool, an isolated test scene) just shows nothing here
## instead of crashing.
##
## The lookup is CACHED, and the two Labels are only written when their number
## actually changes. Both ran unconditionally every frame before: a scene-tree
## path resolve, two dynamic `call()`s and two `Label.text` assignments, sixty
## times a second, for values that change on a pickup. Each label carries a
## 6 px outline and a shadow, so an assignment is a full text re-shape and an
## outlined re-render, not a pointer swap.
##
## Caching a path lookup is not the same as reaching for the bare autoload name
## — the null path is still the one that keeps an isolated scene alive, and it
## is re-resolved if the node ever goes away.
func _update_status() -> void:
	if not is_instance_valid(_game):
		_game = get_node_or_null(^"/root/Game")
	if _game == null:
		return
	var party: RefCounted = _game.get("party")
	var inventory: RefCounted = _game.get("inventory")
	if party == null or inventory == null:
		return

	var pals := int(party.call("size"))
	if pals != _last_pals:
		_last_pals = pals
		_party_label.text = "Pals  %d / %d" % [pals, PARTY.MAX_PALS]

	var orbs := int(inventory.call("count", ORB_ITEM_ID))
	if orbs != _last_orbs:
		_last_orbs = orbs
		_orbs_label.text = "Orbs  %d" % orbs

	_update_hotbar(inventory)
	if _hotbar_message_until > 0.0 and Time.get_ticks_msec() / 1000.0 >= _hotbar_message_until:
		_hotbar_message_until = 0.0
		_hotbar_message.visible = false


## HD2. The hotbar mirrors satchel slots 0-4 directly -- see the header
## comment on HOTBAR_SLOTS. `db` is looked up fresh each call the same way
## `_inventory`/`_party` do it below; this file has no cached RefCounted
## pattern of its own to match yet.
func _update_hotbar(inventory: RefCounted) -> void:
	var db: RefCounted = _game.get("items")
	if db == null:
		return
	for i in HOTBAR_SLOTS:
		var stack: Dictionary = inventory.call("stack_at", i)
		var glyph := INPUT_GLYPH.icon(HOTBAR_ACTIONS[i], 28)
		var text: String
		if stack.is_empty():
			text = "%s\n[color=#666a63]-[/color]" % glyph
		else:
			var id := str(stack.get("id", ""))
			var name := str(db.call("item_name", id))
			var colour: Color = db.call("colour", id)
			var tool_max: int = int(inventory.call("max_durability_at", i))
			var count_text: String
			if tool_max > 0:
				count_text = "%d/%d" % [int(inventory.call("durability_at", i)), tool_max]
			else:
				count_text = "x%d" % int(stack.get("n", 0))
			text = "%s\n[color=#%s]%s %s[/color]" % [glyph, colour.to_html(false), name, count_text]
		if text != _hotbar_last_text[i]:
			_hotbar_last_text[i] = text
			_hotbar_slots[i].text = text


## HD2's "usable directly without opening the full backpack." Mirrors
## `tab_backpack.gd::_read_use()`'s two real cases (free tool repair, a heal
## consumable) rather than sharing code with it -- that tab's use verb opens
## a modal target picker and holds the whole pause-menu shell deaf while it
## is up (`menu.hold_input`), neither of which exists or makes sense for a
## HUD drawn live over real-time exploration. A picker mid-run would BE the
## extra menu this item exists to skip.
##
## The design call this makes instead: a heal item applies to whichever
## living pal is hurt worst, same as this project's use verb did before
## `OF2` added the picker for the deliberate, considered backpack case.
## Recorded here and in DONE.md rather than silently reverting OF2 --
## `OF2`'s own picker is untouched and still the only way to choose a
## specific pal when more than one is hurt.
##
## KNOWN GAP: not gated off during combat. `playground_hud.gd` keeps
## processing while a fight is live (`combat_hud.gd` draws on top of it, it
## does not replace it) and there is no scene-global "a fight is on" flag
## this file can reach without new cross-system plumbing (`CombatManager` is
## wired to `encounter_director.gd` by a scene-local NodePath, not the `Game`
## autoload). A player could free-heal from the hotbar mid-fight today.
## Flagged rather than silently shipped or silently blocked on; the real fix
## is a `Game`-visible "in combat" flag, which is bigger than this item.
func _read_hotbar_input() -> void:
	if _game == null:
		return
	for i in HOTBAR_SLOTS:
		if Input.is_action_just_pressed(HOTBAR_ACTIONS[i]):
			_use_hotbar_slot(i)
			return


func _use_hotbar_slot(index: int) -> void:
	var inventory: RefCounted = _game.get("inventory")
	var db: RefCounted = _game.get("items")
	if inventory == null or db == null:
		return
	var stack: Dictionary = inventory.call("stack_at", index)
	if stack.is_empty():
		return
	var id := str(stack.get("id", ""))

	if str(db.call("kind", id)) == "tool":
		var maximum := int(inventory.call("max_durability_at", index))
		if maximum > 0:
			var current := int(inventory.call("durability_at", index))
			if current >= maximum:
				_show_hotbar_message("%s is already in good repair." % str(db.call("item_name", id)))
			else:
				inventory.call("repair_tool", index)
				_show_hotbar_message("%s repaired, free." % str(db.call("item_name", id)))
			return

	var heal := float((db.call("definition", id) as Dictionary).get("heal", 0.0))
	if heal <= 0.0:
		_show_hotbar_message("%s is not something you can use here." % str(db.call("item_name", id)))
		return

	var party: RefCounted = _game.get("party")
	if party == null or int(party.call("size")) == 0:
		_show_hotbar_message("Nobody on the belt yet.")
		return

	var target: RefCounted = null
	var worst_deficit := 0.0
	for i in int(party.call("size")):
		var pal: RefCounted = party.call("at", i)
		if pal == null:
			continue
		var deficit: float = float(pal.get("max_hp")) - float(pal.get("hp"))
		if deficit > worst_deficit:
			worst_deficit = deficit
			target = pal

	if target == null:
		_show_hotbar_message("Everybody's already at full health.")
		return

	var restored := float(target.call("heal", heal))
	inventory.call("remove", id, 1)
	_show_hotbar_message("%s recovers %d." % [str(target.call("label")), int(restored)])


func _show_hotbar_message(text: String) -> void:
	_hotbar_message.text = text
	_hotbar_message.visible = true
	_hotbar_message_until = Time.get_ticks_msec() / 1000.0 + HOTBAR_MESSAGE_SECONDS


## Health and stamina bars fade to FADE_ALPHA when full and idle, full opacity
## the moment either one is doing anything worth looking at.
func _update_vitals(vitals: RefCounted, delta: float) -> void:
	var health_fraction: float = vitals.health_fraction()
	var stamina_fraction: float = vitals.stamina_fraction()

	_health_bar.value = health_fraction * 100.0
	_stamina_bar.value = stamina_fraction * 100.0
	_health_fill.bg_color = HEALTH_FULL.lerp(HEALTH_LOW, 1.0 - health_fraction)

	var sprinting: bool = bool(_player.call("is_sprinting")) if _player.has_method("is_sprinting") else false
	var health_relevant := health_fraction < 0.999
	var stamina_relevant := stamina_fraction < 0.999 or sprinting

	_fade_toward(_health_bar, 1.0 if health_relevant else FADE_ALPHA, delta)
	_fade_toward(_stamina_bar, 1.0 if stamina_relevant else FADE_ALPHA, delta)


func _fade_toward(control: Control, target: float, delta: float) -> void:
	var current: float = control.modulate.a
	var next: float = move_toward(current, target, FADE_SPEED * delta)
	control.modulate.a = next


## Perf block FIRST, always.
##
## The Label is 868x500 at font size 22, which is about nineteen lines, and the
## movement plus input blocks already overflow that on their own. Whatever is
## last gets clipped, so the numbers this readout was extended for must not be
## last.
func _debug_text() -> String:
	var lines: Array[String] = _perf_lines()
	if _debug_level != DEBUG_FULL:
		return "\n".join(lines)

	if _player != null:
		var speed: float = _player.call("ground_speed")
		var sprinting: bool = _player.call("is_sprinting")
		var pos: Vector3 = _player.global_position
		lines.append_array([
			"",
			"--- movement ---",
			"speed      %.2f m/s%s" % [speed, "   SPRINT" if sprinting else ""],
			"vertical   %+.2f m/s" % _player.velocity.y,
			"grounded   %s" % ("yes" if _player.is_on_floor() else "NO"),
			"position   %.0f, %.0f, %.0f" % [pos.x, pos.y, pos.z],
		])
		var vitals: RefCounted = _player.get("vitals")
		if vitals != null:
			lines.append_array([
				"stamina    %.0f / %.0f" % [vitals.stamina, vitals.max_stamina],
				"health     %.0f / %.0f" % [vitals.health, vitals.max_health],
				"worst landing  %.1f m/s  (%.0f damage)" % [_peak_fall, _last_damage],
			])
	lines.append_array(_input_diagnostics())
	return "\n".join(lines)


## Live input diagnostics.
##
## On screen rather than in a log, because "the controller does nothing" is
## otherwise indistinguishable from four different causes: the handheld sitting
## in desktop/mouse mode so the sticks emit no joypad events at all, the pad
## enumerating without an SDL mapping, a wrong axis or button in the input map,
## or the window simply not having focus. Each of those looks identical from the
## outside and each shows up differently here.
##
## Keyboard values are shown alongside the pad on purpose: if WASD moves the
## capsule and the sticks do not, the game is fine and the problem is upstream
## of Godot.
func _input_diagnostics() -> Array[String]:
	var lines: Array[String] = ["", "--- input ---"]

	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		lines.append("controller  NONE DETECTED BY GODOT")
		lines.append("  the handheld is probably in desktop/mouse mode,")
		lines.append("  or the window does not have focus")
		_pad_connected_for = 0.0
		_max_raw_axis_seen = 0.0
	else:
		for device_id in pads:
			lines.append("controller  %d: %s" % [device_id, Input.get_joy_name(device_id)])
			if not Input.is_joy_known(device_id):
				lines.append("  NOT a standard mapping: buttons/axes may be wrong")

	var move := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	lines.append("move  %+.2f %+.2f     look  %+.2f %+.2f" % [move.x, move.y, look.x, look.y])

	# Raw axes, bypassing the input map. If these move while `move` above stays
	# zero, the pad is fine and the input map bindings are wrong.
	if not pads.is_empty():
		var device: int = pads[0]
		var lx: float = Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
		var ly: float = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
		var rx: float = Input.get_joy_axis(device, JOY_AXIS_RIGHT_X)
		var ry: float = Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y)
		lines.append("raw axes  L %+.2f %+.2f   R %+.2f %+.2f" % [lx, ly, rx, ry])

		_max_raw_axis_seen = maxf(_max_raw_axis_seen, maxf(
			maxf(absf(lx), absf(ly)), maxf(absf(rx), absf(ry))))
		# On a handheld the readout is throttled to READOUT_INTERVAL, not every
		# frame, so this advances in those same steps.
		_pad_connected_for += READOUT_INTERVAL

		# A pad Godot can name and still never hears from is exactly what the
		# ROG Ally's own "Desktop Mode" produces: the sticks drive the mouse
		# cursor instead of sending joypad axis events, so the device enumerates
		# fine and every axis reads a permanent 0.00. Command Center's own
		# Gamepad Mode is the fix, and it is not a Tetherbound setting — the
		# game has no way to flip it for the player.
		if _pad_connected_for >= STUCK_AXES_HINT_AFTER and _max_raw_axis_seen < STUCK_AXES_EPSILON:
			lines.append("  raw axes have not moved at all since the pad was seen.")
			lines.append("  On ROG Ally: Command Center -> Gamepad Mode (not Desktop")
			lines.append("  Mode) — desktop mode sends the sticks to Windows as a")
			lines.append("  mouse, not to the game as a controller.")

	lines.append("jump %s  sprint %s  interact %s" % [
		_held("jump"), _held("sprint"), _held("interact")
	])
	lines.append("")
	lines.append("pad: left stick move, right stick look, A jump, L3 sprint")
	lines.append("keyboard: WASD move, mouse look, Space jump, Shift sprint")
	return lines


func _held(action: String) -> String:
	return "[X]" if Input.is_action_pressed(action) else "[ ]"
