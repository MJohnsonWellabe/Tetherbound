extends CanvasLayer

## M1 debug HUD: health, stamina, and the numbers needed to tune movement —
## plus, since the owner playtest that reported "I don't know how to pull out a
## tool to chop or anything", the moment-to-moment feedback layer for the world
## outside combat:
##
##   THE TOOL LINE (bottom-left): what is in hand and the button that cycles it,
##   routed through `ui_style.verb()` so the glyph language is the combat HUD's.
##
##   THE CONTEXT LINE (bottom-centre): what the trainer is facing and whether
##   the thing in hand can work it — the refusal tokens `harvestable.gd` and
##   `tools.gd` mint finally shown instead of dying in their signals.
##
##   TOASTS (right column, `toasts.gd`): XP, level-ups, pickups, the autosave
##   tick, refusals. One queue; see that file for the coalescing rules.
##
##   COUNTER POPS AND ITEM ARCS: a "+3 Wood" that pops at the tree that gave it
##   up, and a small coloured mote that arcs from the prop to the trainer. The
##   prop's own shake/sink/pop lives in `harvestable.gd`, which owns the
##   MultiMesh index.
##
## EVERYTHING HERE CONNECTS, NOTHING DECIDES. The signals existed before this
## file listened: `swung`/`refused`/`equipped_changed` on Tools,
## `xp_awarded`/`pal_levelled` on EncounterDirector, `wrote` on SaveDirector,
## `refused` on TrainerInventory. Tools and Harvestable are created at runtime
## by `build_mode._mount_field_systems()` several frames after this node's
## `_ready`, so wiring is discovered lazily and retried rather than done once.
##
## Sized for the Ally: the project authors at 1920x1080 and stretches
## canvas_items, so text set here is at real handheld pixel density.

const STYLE := preload("res://scripts/ui/ui_style.gd")
const DEFS := preload("res://scripts/items/item_defs.gd")

const READOUT_INTERVAL := 0.1
## How often to look for the runtime-mounted systems until they are all found.
const WIRE_INTERVAL := 0.5

## Counter pops rise for this long; arcs fly for this long. TUNABLE.
const POP_LIFE := 1.1
const ARC_LIFE := 0.55

## What an arcing yield mote looks like, per item. Anything unlisted gets the
## pale fallback rather than nothing.
const ARC_COLOURS := {
	"wood": Color(0.55, 0.38, 0.20),
	"stone": Color(0.58, 0.58, 0.60),
	"fiber": Color(0.46, 0.62, 0.30),
	"berries": Color(0.76, 0.26, 0.30),
}
const ARC_FALLBACK := Color(0.90, 0.85, 0.60)

@export var player_path: NodePath

var _player: CharacterBody3D = null
var _since_readout := 0.0
var _peak_fall := 0.0
var _last_damage := 0.0

var _since_wire := WIRE_INTERVAL
var _tools: Node = null
var _encounter: Node = null
var _save: Node = null
var _bag: Node = null

## Rising "+3 Wood" labels and flying yield motes:
## `{label, at, age}` / `{node, from, age}`.
var _pops: Array[Dictionary] = []
var _arcs: Array[Dictionary] = []

@onready var _root: Control = $Root
@onready var _health_bar: ProgressBar = $Root/Bars/Health
@onready var _stamina_bar: ProgressBar = $Root/Bars/Stamina
@onready var _readout: Label = $Root/Readout
@onready var _tool_line: RichTextLabel = $Root/ToolLine
@onready var _context_line: RichTextLabel = $Root/ContextLine
@onready var _toasts: Control = $Root/Toasts


func _ready() -> void:
	STYLE.make_legible(_root)
	_player = get_node_or_null(player_path) as CharacterBody3D
	if _player == null:
		push_warning("HUD has no player; readout will stay empty")
		return
	if _player.has_signal("landed"):
		_player.connect("landed", _on_landed)


## Hand this HUD its systems directly instead of waiting for discovery — the
## seam `tools/preview_feedback.gd` uses, kept for the reason `tools.bind()`
## gives: a system that can only be wired through a full scene cannot be
## photographed without one.
func bind_feedback(tools: Node, encounter: Node = null, save: Node = null, bag: Node = null) -> void:
	if tools != null:
		_tools = tools
		_connect_tools()
	if encounter != null:
		_encounter = encounter
		_connect_encounter()
	if save != null:
		_save = save
		_connect_save()
	if bag != null:
		_bag = bag
		_connect_bag()


func _on_landed(impact_speed: float, damage: float) -> void:
	_peak_fall = maxf(_peak_fall, impact_speed)
	_last_damage = damage


func _process(delta: float) -> void:
	# The feedback layer runs even with no vitals to read, which is what lets
	# the preview tool photograph it around a bare CharacterBody3D.
	_feedback(delta)

	if _player == null:
		return
	var vitals: RefCounted = _player.get("vitals")
	if vitals == null:
		return

	_health_bar.value = vitals.health_fraction() * 100.0
	_stamina_bar.value = vitals.stamina_fraction() * 100.0

	# Throttled: rebuilding this string every frame is wasted work and makes the
	# numbers flicker too fast to read while tuning.
	_since_readout += delta
	if _since_readout < READOUT_INTERVAL:
		return
	_since_readout = 0.0

	var speed: float = _player.call("ground_speed")
	var sprinting: bool = _player.call("is_sprinting")
	var pos: Vector3 = _player.global_position

	var lines: Array[String] = [
		"M1 movement playground",
		"",
		"speed      %.2f m/s%s" % [speed, "   SPRINT" if sprinting else ""],
		"vertical   %+.2f m/s" % _player.velocity.y,
		"grounded   %s" % ("yes" if _player.is_on_floor() else "NO"),
		"position   %.0f, %.0f, %.0f" % [pos.x, pos.y, pos.z],
		"",
		"stamina    %.0f / %.0f" % [vitals.stamina, vitals.max_stamina],
		"health     %.0f / %.0f" % [vitals.health, vitals.max_health],
		"worst landing  %.1f m/s  (%.0f damage)" % [_peak_fall, _last_damage],
	]
	lines.append_array(_food_lines(vitals))
	lines.append_array(_input_diagnostics())
	_readout.text = "\n".join(lines)


## --- the feedback layer ------------------------------------------------------


func _feedback(delta: float) -> void:
	_since_wire += delta
	if _since_wire >= WIRE_INTERVAL:
		_since_wire = 0.0
		_wire()
		_update_tool_line()
		_update_context_line()
	_advance_pops(delta)
	_advance_arcs(delta)


## Find the systems this HUD narrates, as they appear. Tools, Harvestable and
## Doors are mounted by `build_mode._mount_field_systems()` a few frames after
## boot, so a single look in `_ready` finds nothing and stays deaf all session
## — the exact "works invisibly" failure this layer exists to end.
func _wire() -> void:
	var world := get_parent()
	if world == null:
		return
	if _tools == null:
		_tools = world.get_node_or_null(^"Tools")
		if _tools != null:
			_connect_tools()
	if _encounter == null:
		_encounter = world.get_node_or_null(^"EncounterDirector")
		if _encounter != null:
			_connect_encounter()
	if _save == null:
		_save = world.get_node_or_null(^"SaveDirector")
		if _save != null:
			_connect_save()
	if _bag == null:
		_bag = world.get_node_or_null(^"TrainerInventory")
		if _bag != null:
			_connect_bag()


func _connect_tools() -> void:
	if _tools.has_signal("swung") and not _tools.is_connected("swung", _on_swung):
		_tools.connect("swung", _on_swung)
	if _tools.has_signal("refused") and not _tools.is_connected("refused", _on_refused):
		_tools.connect("refused", _on_refused)
	if _tools.has_signal("equipped_changed") and not _tools.is_connected("equipped_changed", _on_equipped_changed):
		_tools.connect("equipped_changed", _on_equipped_changed)


func _connect_encounter() -> void:
	if _encounter.has_signal("xp_awarded") and not _encounter.is_connected("xp_awarded", _on_xp_awarded):
		_encounter.connect("xp_awarded", _on_xp_awarded)
	if _encounter.has_signal("pal_levelled") and not _encounter.is_connected("pal_levelled", _on_pal_levelled):
		_encounter.connect("pal_levelled", _on_pal_levelled)


func _connect_save() -> void:
	if _save.has_signal("wrote") and not _save.is_connected("wrote", _on_saved):
		_save.connect("wrote", _on_saved)


func _connect_bag() -> void:
	if _bag.has_signal("refused") and not _bag.is_connected("refused", _on_refused):
		_bag.connect("refused", _on_refused)


## --- what the signals say ----------------------------------------------------


func _on_swung(result: Dictionary) -> void:
	var item := str(result.get("item", ""))
	var count := int(result.get("count", 0))
	if count <= 0:
		return
	_toasts.call("pickup", item, count)
	var at: Variant = result.get("position")
	if at is Vector3:
		_pop_counter("+%d %s" % [count, DEFS.display_name(item)], at)
		_spawn_arc(at, item)
	if bool(result.get("tool_broke", false)):
		_toasts.call("info", "%s broke!" % DEFS.display_name(str(result.get("tool", ""))))


func _on_refused(reason: String) -> void:
	_toasts.call("refusal", reason)


func _on_equipped_changed(_item_id: String) -> void:
	_update_tool_line()
	_update_context_line()


func _on_xp_awarded(pal: RefCounted, amount: int, _deployed: bool) -> void:
	if pal != null and pal.has_method("display"):
		_toasts.call("xp", str(pal.call("display")), amount)


func _on_pal_levelled(pal: RefCounted, level: int, _gained: int) -> void:
	if pal != null and pal.has_method("display"):
		_toasts.call("level_up", str(pal.call("display")), level)


func _on_saved(reason: String) -> void:
	_toasts.call("saved", reason)


## --- the tool line -----------------------------------------------------------


## "Axe  [RB] Cycle tool", bottom-left, always — the owner could not find the
## tools because nothing on screen admitted they existed. Hidden only while the
## trainer's hands are not their own (a fight, build mode, a menu), which is
## `tools.can_act()`'s one question.
func _update_tool_line() -> void:
	if _tools == null:
		_tool_line.text = ""
		return
	var acting := not _tools.has_method("can_act") or bool(_tools.call("can_act"))
	_tool_line.visible = acting
	if not acting:
		_context_line.visible = false
		return

	var held := str(_tools.call("equipped_name"))
	var broken := _tools.has_method("is_broken") and bool(_tools.call("is_broken"))
	var name_colour := STYLE.WARN if broken else STYLE.INK
	var line := "[color=#%s][b]%s[/b][/color]" % [name_colour, held]
	if broken:
		line += " [color=#%s]broken[/color]" % STYLE.WARN
	else:
		var whole := float(_tools.call("durability_fraction"))
		if whole < 0.995:
			var wear_colour := STYLE.WARN if whole < 0.34 else STYLE.INK_DIM
			line += " [color=#%s]%d%%[/color]" % [wear_colour, int(round(whole * 100.0))]
	# Through `ui_style.verb()`, like every other prompt row, so the glyph
	# language stays one language and pad glyphs land here for free.
	line += "   " + STYLE.verb("RB", "Cycle tool", true)
	_tool_line.text = line


## --- the context line --------------------------------------------------------


## What is in front of the trainer and whether the swing would land — the
## `needs_tool` / `wrong_tool` / `spent` refusals shown BEFORE the button is
## pressed instead of after.
func _update_context_line() -> void:
	if _tools == null or not _tools.has_method("target"):
		_context_line.text = ""
		return
	if not _tool_line.visible:
		_context_line.visible = false
		return
	var text := _context_text()
	_context_line.visible = not text.is_empty()
	_context_line.text = "[center]%s[/center]" % text


func _context_text() -> String:
	var seen: Dictionary = _tools.call("target")
	if seen.is_empty():
		return ""
	var prop := str(seen.get("display_name", ""))

	if bool(seen.get("spent", false)):
		var left := int(ceil(float(seen.get("regrow_left", 0.0))))
		return "[color=#%s]%s — stripped, back in %d:%02d[/color]" % [
			STYLE.INK_DIM, prop, left / 60, left % 60
		]

	var wanted := str(seen.get("tool", ""))
	var equipped := str(_tools.call("equipped"))
	var broken := _tools.has_method("is_broken") and bool(_tools.call("is_broken"))
	var named := "[color=#%s][b]%s[/b][/color]" % [STYLE.INK, prop]

	# The right thing is in hand (or the prop wants none): the swing verb,
	# shared with combat on purpose — same physical button, same glyph.
	if wanted.is_empty() or (equipped == wanted and not broken):
		return "%s — %s" % [named, STYLE.verb("A", "Gather", true)]

	if equipped == wanted and broken:
		return "%s — [color=#%s]%s is broken[/color]  %s" % [
			named, STYLE.WARN, DEFS.display_name(wanted), STYLE.verb("RB", "Cycle tool", true)
		]

	# Bare hands on a prop that merely PREFERS a tool: hands work, say so, and
	# say what would work better.
	if equipped.is_empty() and bool(seen.get("hand_ok", false)):
		return "%s — %s  [color=#%s]a %s yields more[/color]" % [
			named, STYLE.verb("A", "Gather", true), STYLE.INK_DIM, DEFS.display_name(wanted)
		]

	# The wrong thing is in hand. If the right one is in the bag, the cycle
	# button fixes it; if not, no amount of cycling will, and the hint saying
	# otherwise would be a lie.
	var carried: Array = _tools.call("hand_cycle")
	if carried.has(wanted):
		return "%s — needs %s  %s" % [
			named, _an(DEFS.display_name(wanted)), STYLE.verb("RB", "Cycle tool", true)
		]
	return "%s — [color=#%s]needs %s (you carry none)[/color]" % [
		named, STYLE.WARN, _an(DEFS.display_name(wanted))
	]


func _an(noun: String) -> String:
	var article := "an" if not noun.is_empty() and "aeiouAEIOU".contains(noun[0]) else "a"
	return "%s %s" % [article, noun]


## --- counter pops ------------------------------------------------------------


## "+3 Wood", popped at the prop that gave it up and rising away. World-anchored
## through the live camera each frame, so it stays on the tree while the camera
## orbits; with no camera (headless) it sits at the lower third, which nobody
## will ever see but keeps the math total.
func _pop_counter(text: String, at: Vector3) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color("#" + STYLE.GOOD))
	STYLE.make_legible(label)
	_root.add_child(label)
	_pops.append({"label": label, "at": at + Vector3.UP * 1.8, "age": 0.0})


func _advance_pops(delta: float) -> void:
	if _pops.is_empty():
		return
	var camera := get_viewport().get_camera_3d() if get_viewport() != null else null
	var still: Array[Dictionary] = []
	for pop in _pops:
		var label: Label = pop["label"]
		if label == null or not is_instance_valid(label):
			continue
		pop["age"] = float(pop["age"]) + delta
		var age := float(pop["age"])
		if age >= POP_LIFE:
			label.queue_free()
			continue

		var screen := _root.size * Vector2(0.5, 0.66)
		var at: Vector3 = pop["at"]
		if camera != null and not camera.is_position_behind(at):
			screen = camera.unproject_position(at)

		# Pop in (overshoot), rise, fade out.
		var grow := 1.0
		if age < 0.15:
			grow = lerpf(0.4, 1.2, age / 0.15)
		elif age < 0.3:
			grow = lerpf(1.2, 1.0, (age - 0.15) / 0.15)
		label.pivot_offset = label.size * 0.5
		label.scale = Vector2.ONE * grow
		label.position = screen - label.size * 0.5 - Vector2(0.0, age * 46.0)
		var alpha := 1.0 if age < 0.6 else 1.0 - (age - 0.6) / (POP_LIFE - 0.6)
		label.modulate = Color(1.0, 1.0, 1.0, alpha)
		still.append(pop)
	_pops = still


## --- item arcs ---------------------------------------------------------------


## A small coloured mote that leaves the prop and flies to the trainer: the
## yield seen TRAVELLING into the bag, which is the difference between "I
## chopped and a number moved somewhere" and "I got the wood".
func _spawn_arc(from: Vector3, item: String) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var world := _player.get_parent()
	if world == null:
		return
	var mote := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.12
	ball.height = 0.24
	mote.mesh = ball
	var coat := StandardMaterial3D.new()
	coat.albedo_color = ARC_COLOURS.get(item, ARC_FALLBACK)
	coat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mote.material_override = coat
	world.add_child(mote)
	var start := from + Vector3.UP * 1.2
	mote.global_position = start
	_arcs.append({"node": mote, "from": start, "age": 0.0})


func _advance_arcs(delta: float) -> void:
	if _arcs.is_empty():
		return
	var still: Array[Dictionary] = []
	for arc in _arcs:
		var mote: MeshInstance3D = arc["node"]
		if mote == null or not is_instance_valid(mote):
			continue
		arc["age"] = float(arc["age"]) + delta
		var u := float(arc["age"]) / ARC_LIFE
		if u >= 1.0 or _player == null or not is_instance_valid(_player):
			mote.queue_free()
			continue
		var from: Vector3 = arc["from"]
		var to: Vector3 = _player.global_position + Vector3.UP * 1.0
		var mid := (from + to) * 0.5 + Vector3.UP * 1.4
		# One quadratic bezier: lift off the prop, drop into the trainer.
		mote.global_position = from.lerp(mid, u).lerp(mid.lerp(to, u), u)
		mote.scale = Vector3.ONE * (1.0 - 0.5 * u)
		still.append(arc)
	_arcs = still


## What the trainer has eaten, and how long it has left.
##
## On the debug readout because M9's food buffs are otherwise only visible on a
## screen the player has to open, and a buff nobody can see while playing is a
## buff nobody can tell is working. The maxima above already move when a meal
## lands; this says WHY they moved.
##
## The "no meal" line is not padding. Every survival game the owner has played
## puts a hunger meter about here, and the only way to say this one does not have
## one is to say so where they would look for it — GAME_DESIGN.md §18 and
## CLAUDE.md both make food a bonus and forbid the meter.
func _food_lines(vitals: RefCounted) -> Array[String]:
	var lines: Array[String] = ["", "--- fed ---"]
	var buffs: Array = vitals.food_buffs()
	if buffs.is_empty():
		lines.append("no meal in effect  (that costs you nothing)")
		return lines
	for entry: Variant in buffs:
		var meal: Dictionary = entry
		var left := int(maxf(0.0, float(meal.get("left", 0.0))))
		lines.append("%-14s %d:%02d  +%.0f hp  +%.0f stam  +%.0f/s" % [
			str(meal.get("item", "")), left / 60, left % 60,
			float(meal.get("max_health", 0.0)),
			float(meal.get("max_stamina", 0.0)),
			float(meal.get("stamina_regen", 0.0)),
		])
	return lines


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
		lines.append("raw axes  L %+.2f %+.2f   R %+.2f %+.2f" % [
			Input.get_joy_axis(device, JOY_AXIS_LEFT_X),
			Input.get_joy_axis(device, JOY_AXIS_LEFT_Y),
			Input.get_joy_axis(device, JOY_AXIS_RIGHT_X),
			Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y),
		])

	lines.append("jump %s  sprint %s  interact %s" % [
		_held("jump"), _held("sprint"), _held("interact")
	])
	lines.append("")
	lines.append("pad: left stick move, right stick look, A jump, L3 sprint")
	lines.append("keyboard: WASD move, mouse look, Space jump, Shift sprint")
	return lines


func _held(action: String) -> String:
	return "[X]" if Input.is_action_pressed(action) else "[ ]"
