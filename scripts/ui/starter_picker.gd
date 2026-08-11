extends CanvasLayer

## The starter choice, previewed in orbs while still indoors with Grandpa.
##
## Replaces walking up to three creatures stood outside the door — the earlier
## staging docs/OPENING_SEQUENCE.md called "physical, not a menu" — with a
## picker that opens the moment his briefing ends: three orbs, each holding a
## live view of the creature inside it. Owner directive, 2026-08-11 (`SA0-orbs`):
## "the starters should be in orbs and you preview them while talking to
## Grandpa." The reversal is recorded in docs/OPENING_SEQUENCE.md and
## data/config/opening.json, not just here.
##
## Modal, built the same way as name_prompt.gd: polled state, no pushed
## copies, no idea what a "beat" is — the sequence director is the only thing
## that knows that. This node knows species ids and orbs and nothing else.
##
## Each orb is a real creature body inside its own SubViewport, the same
## construction tools/preview_creatures.gd uses to render a species in
## isolation for the art survey — just live and slowly turning instead of
## baked to a PNG, and `own_world_3d = true` so three creatures and three
## lights do not leak into the meadow's own World3D or each other's.

const SPECIES := preload("res://scripts/pals/pal_species.gd")
const PAL_SCENE := preload("res://scenes/pals/pal.tscn")
const PAL_BODY := preload("res://scripts/pals/pal_body.gd")

## Frames of deafness after opening, for the reason dialogue_panel.gd and
## name_prompt.gd both give: the press that closed the conversation and the
## press that would move the cursor can land in the same physics frame.
const OPEN_GUARD_FRAMES := 2

const VIEWPORT_SIZE := Vector2i(240, 240)
## Radians/second. Slow enough to read as a living thing rather than a
## fairground ride; fast enough that standing still for a couple of seconds
## shows every side of it.
const SPIN_SPEED := 0.5

const ORB_BG := Color(0.07, 0.08, 0.06, 0.92)
const ORB_BG_SELECTED := Color(0.30, 0.24, 0.09, 0.95)
const ORB_BORDER := Color(0.55, 0.60, 0.50, 0.55)
const ORB_BORDER_SELECTED := Color(0.90, 0.75, 0.30, 0.95)

const OUTLINE := Color(0.03, 0.04, 0.05, 0.95)
const OUTLINE_SIZE := 6

signal chosen(index: int)

var _open: bool = false
var _guard: int = 0
var _species: Array[String] = []
var _index: int = 0
## The live preview bodies, spun every frame while open. Parallel to
## `_species` and `_slots`.
var _bodies: Array[Node3D] = []
var _slots: Array[PanelContainer] = []
var _restore_mouse: int = Input.MOUSE_MODE_CAPTURED

@onready var _root: Control = $Root
@onready var _title: Label = $Root/Title
@onready var _orbs: HBoxContainer = $Root/Orbs
@onready var _hint: Label = $Root/Hint


func _ready() -> void:
	_make_text_legible($Root)
	_root.visible = false


func _make_text_legible(node: Node) -> void:
	if node is Label:
		var label := node as Label
		label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
		label.add_theme_color_override("font_outline_color", OUTLINE)
	for child in node.get_children():
		_make_text_legible(child)


func is_open() -> bool:
	return _open


## `species` is read straight off data/config/opening.json's `starters.species`
## by the sequence director — this node never reads config itself, the same
## split dialogue_panel.gd keeps from dialogue_runner.gd.
func open(species: Array[String]) -> void:
	_species = species.duplicate()
	_index = 0
	_open = true
	_guard = OPEN_GUARD_FRAMES
	_title.text = "Three orbs, three companions. Choose one."
	_hint.text = "[<-] [->] look    [A] choose"
	_restore_mouse = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_orbs()
	_root.visible = true


func close() -> void:
	if not _open:
		return
	_open = false
	_root.visible = false
	Input.mouse_mode = _restore_mouse as Input.MouseMode
	_free_orbs()


func _free_orbs() -> void:
	for child in _orbs.get_children():
		child.queue_free()
	_bodies.clear()
	_slots.clear()


func _build_orbs() -> void:
	_free_orbs()
	for i in _species.size():
		var built := _build_orb_shell(_species[i])
		var slot: PanelContainer = built[0]
		var viewport: SubViewport = built[1]
		# The shell goes into the live tree BEFORE the creature is built inside
		# it, not after — pal_body.gd::setup() gates its mesh-building on
		# `is_inside_tree()`, and tools/preview_creatures.gd's own header names
		# the exact failure of getting this order backwards: everything appears
		# to work, `open()` returns, and every orb is silently empty. Caught
		# rendering this picker for the first time — the fix this task's own
		# blind-visual-judge pass exists to catch.
		_orbs.add_child(slot)
		var body := _build_preview(viewport, _species[i])
		_bodies.append(body)
		_slots.append(slot)
	_refresh_selection()


## The container structure only — no camera, no light, no creature. Callers
## must add the returned slot to a live tree before populating `viewport`.
func _build_orb_shell(id: String) -> Array:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(VIEWPORT_SIZE) + Vector2(24.0, 64.0)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 6)
	slot.add_child(column)

	var view_container := SubViewportContainer.new()
	view_container.custom_minimum_size = Vector2(VIEWPORT_SIZE)
	view_container.stretch = true
	column.add_child(view_container)

	var viewport := SubViewport.new()
	viewport.size = VIEWPORT_SIZE
	# Its own World3D, or the preview's light and creature would render straight
	# into the meadow behind this panel — and the meadow's own sun would light
	# the orb instead of the flat key light built for it below.
	viewport.own_world_3d = true
	view_container.add_child(viewport)

	var label := Label.new()
	label.text = _display_name(id)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	column.add_child(label)

	return [slot, viewport]


## A single creature, lit flatly and centred, the way
## tools/preview_creatures.gd builds one for the art survey — `PAL_SCENE`
## instantiated first so `$Collision/$Model/$Body/$Head` resolve, the script
## attached before `add_child`, `setup()` called after. `viewport` must
## already be inside the live tree (see `_build_orbs`).
func _build_preview(viewport: SubViewport, id: String) -> Node3D:
	var world := Node3D.new()
	viewport.add_child(world)

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	# Warm dark amber — inside the orb, not the meadow outside it.
	env.background_color = Color(0.16, 0.12, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.86, 0.90)
	env.ambient_light_energy = 1.6
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env_node.environment = env
	world.add_child(env_node)

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-35.0), deg_to_rad(35.0), 0.0)
	key.light_energy = 1.4
	world.add_child(key)

	var body: Node3D = PAL_SCENE.instantiate()
	body.name = "Preview_%s" % id
	body.set_script(PAL_BODY)
	world.add_child(body)
	body.call("setup", id)
	# Frozen — nothing here needs gravity or a floor, only the model. Spun by
	# hand in `_process` instead of moved.
	body.set_physics_process(false)
	body.rotation.y = deg_to_rad(200.0)

	var camera := Camera3D.new()
	camera.fov = 34.0
	camera.current = true
	world.add_child(camera)

	var height := float(body.call("body_height")) if body.has_method("body_height") else 1.0
	var radius := float(body.call("body_radius")) if body.has_method("body_radius") else 0.4
	var distance := maxf(height, radius * 2.2) * 2.4 + 0.6
	var eye := Vector3(0.0, height * 0.55, distance)
	# `look_at_from_position()` rather than `position` + `look_at()`: harmless
	# either way now that `_build_orbs` puts the shell in the tree first, but
	# it sets the transform in one call with no assumption about tree state,
	# which is one fewer thing to get wrong if this ever gets reordered again.
	camera.look_at_from_position(eye, Vector3(0.0, height * 0.5, 0.0), Vector3.UP)

	return body


func _display_name(id: String) -> String:
	return str(SPECIES.definition(id).get("display_name", id))


## --- input --------------------------------------------------------------

func _physics_process(_delta: float) -> void:
	if not _open:
		return
	if _guard > 0:
		_guard -= 1
		return
	if Input.is_action_just_pressed("ui_right"):
		_move(1)
	elif Input.is_action_just_pressed("ui_left"):
		_move(-1)
	elif Input.is_action_just_pressed("menu_confirm"):
		_confirm()


func _move(delta: int) -> void:
	var target := clampi(_index + delta, 0, _species.size() - 1)
	if target == _index:
		return
	_index = target
	_refresh_selection()


func _confirm() -> void:
	var index := _index
	close()
	chosen.emit(index)


func _refresh_selection() -> void:
	for i in _slots.size():
		var selected := i == _index
		var style := StyleBoxFlat.new()
		style.bg_color = ORB_BG_SELECTED if selected else ORB_BG
		style.border_color = ORB_BORDER_SELECTED if selected else ORB_BORDER
		var width := 4 if selected else 2
		style.border_width_left = width
		style.border_width_right = width
		style.border_width_top = width
		style.border_width_bottom = width
		# Near-circular: the panel is square-ish, so a corner radius over half
		# its width rounds it into an orb rather than a rounded rectangle.
		var radius := int(VIEWPORT_SIZE.x * 0.5) + 12
		style.corner_radius_top_left = radius
		style.corner_radius_top_right = radius
		style.corner_radius_bottom_left = radius
		style.corner_radius_bottom_right = radius
		_slots[i].add_theme_stylebox_override("panel", style)


## The turntable. Only while open — a picker that spins in the background
## after `close()` is a leaked node, not a preview.
func _process(delta: float) -> void:
	if not _open:
		return
	for body in _bodies:
		if body != null and is_instance_valid(body):
			body.rotate_y(SPIN_SPEED * delta)
