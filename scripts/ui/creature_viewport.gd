extends SubViewportContainer

## A live, orbitable 3D view of one creature, for the TEAM screen's centre column
## (spec §8.2).
##
## Lifts `scripts/ui/starter_picker.gd::_build_preview`'s construction almost
## verbatim — own_world_3d SubViewport, a warm key + cool rim light, `creature.tscn`
## fitted and framed from `body_height()`/`body_radius()` — rather than
## reinventing creature-preview lighting a second time. The one thing added is
## interactivity: the starter orbs only ever auto-spin, this widget also reads
## the right stick (and a mouse drag, for keyboard/mouse testing) so a player
## can actually look a party member over.
##
## Defensive by design, not by afterthought: `set_species()` can be called
## from a headless test with no renderer worth the name behind it, and
## `smoke_menu.gd` must stay green either way. If `creature.tscn` fails to build a
## real model the widget falls back to a flat colour chip — see `_fallback` —
## and never raises past that.

const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

const VIEWPORT_SIZE := Vector2i(420, 460)

## Radians/second. Matches starter_picker's SPIN_SPEED — a slow living-thing
## turntable when nobody is touching the stick.
const IDLE_SPIN_SPEED := 0.5

## Radians/second at full stick deflection.
const STICK_ORBIT_SPEED := 2.4
## Radians per pixel of mouse drag.
const MOUSE_ORBIT_SPEED := 0.012

## Below this the stick reads as centred. Controller sticks rest with a
## nonzero float even undriven; without a deadzone the preview would drift on
## its own on a menu screen where nothing else in the scene is moving to hide
## it.
const STICK_DEADZONE := 0.18

## Godot's JoyAxis enum: LEFT_X=0, LEFT_Y=1, RIGHT_X=2, RIGHT_Y=3. Read as raw
## axis indices rather than through an input action — there is no bound
## action for "look" inside a menu, and this agent may not add one to
## project.godot's input map.
const JOY_AXIS_RIGHT_X := 2

var _world: Node3D = null
var _viewport: SubViewport = null
var _turntable: Node3D = null
var _body: Node3D = null
var _species_id: String = ""
## OF27: tracked alongside `_species_id` so a same-species swap (releasing a
## shiny creature and having a non-shiny one of the same species scroll into
## its spot, or vice versa -- rare, but not impossible with a five-creature
## party) still rebuilds the preview instead of `set_species` short-circuiting
## on the species id matching.
var _shiny: bool = false
var _dragging: bool = false
var _drag_device: int = -1


func _ready() -> void:
	custom_minimum_size = Vector2(VIEWPORT_SIZE)
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_world()


func _build_world() -> void:
	for child in get_children():
		child.queue_free()

	_viewport = SubViewport.new()
	_viewport.size = VIEWPORT_SIZE
	# Its own World3D, exactly for the reason starter_picker's has one: without
	# it this preview and its lights would render into the meadow behind the
	# menu instead of the dark backdrop built for it below.
	_viewport.own_world_3d = true
	add_child(_viewport)

	_world = Node3D.new()
	_viewport.add_child(_world)

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	# Dark, plain, and cooler than the starter orbs' warm amber — this is a
	# party roster, not the mystery of an unopened orb.
	env.background_color = Color(0.05, 0.07, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.90, 0.92, 0.95)
	env.ambient_light_energy = 2.0
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env_node.environment = env
	_world.add_child(env_node)

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-35.0), deg_to_rad(35.0), 0.0)
	key.light_energy = 2.0
	_world.add_child(key)

	var rim := DirectionalLight3D.new()
	rim.rotation = Vector3(deg_to_rad(-20.0), deg_to_rad(200.0), 0.0)
	rim.light_energy = 1.3
	rim.light_color = Color(0.78, 0.87, 1.0)
	_world.add_child(rim)

	# The turntable is what orbit spins — the camera stays put and looks at
	# the pivot, exactly like starter_picker's camera does, so reframing on a
	# species change is one look_at_from_position call, not a rotation reset.
	_turntable = Node3D.new()
	_world.add_child(_turntable)


## Build (or rebuild) the preview for `species_id`. Safe to call repeatedly —
## the previous body is discarded first. Never throws: a bad or unknown
## species id, a missing model, or no renderer at all all resolve to SOME
## visible content (a flat capsule, or the colour-chip fallback), because a
## blank centre column reads as broken and this tab must never crash on it.
func set_species(species_id: String, shiny: bool = false) -> void:
	if species_id == _species_id and shiny == _shiny and _body != null and is_instance_valid(_body):
		return
	_species_id = species_id
	_shiny = shiny
	_clear_body()

	if species_id == "":
		return

	var body: Node3D = null
	var height := 1.0
	var radius := 0.4
	if not Engine.is_editor_hint():
		body = _try_build_body(species_id, shiny)
	if body != null:
		height = float(body.call("body_height")) if body.has_method("body_height") else 1.0
		radius = float(body.call("body_radius")) if body.has_method("body_radius") else 0.4
		_body = body
	else:
		var look: Dictionary = SPECIES.placeholder(species_id)
		height = float(look.get("height", 1.0))
		radius = float(look.get("radius", 0.4))
		_body = _fallback(look)

	_frame_camera(height, radius)


func _try_build_body(species_id: String, shiny: bool = false) -> Node3D:
	var instance: Node3D = CREATURE_SCENE.instantiate() as Node3D
	if instance == null:
		return null
	instance.name = "TeamPreview_%s" % species_id
	instance.set_script(CREATURE_BODY)
	_turntable.add_child(instance)
	instance.call("setup", species_id, shiny)
	instance.set_physics_process(false)
	instance.rotation.y = deg_to_rad(200.0)
	return instance


## The last-resort fallback: a plain sphere in the species' placeholder
## colour. Reached when `creature.tscn` cannot be instanced at all (as could
## happen headless with a stripped-down renderer) — a coloured shape still
## says "this is the creature in slot N", where an empty viewport says nothing.
func _fallback(look: Dictionary) -> Node3D:
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	var radius: float = float(look.get("radius", 0.5))
	sphere.radius = radius
	sphere.height = radius * 2.0
	mesh_instance.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(str(look.get("colour", "#cccccc")))
	material.roughness = 0.85
	mesh_instance.material_override = material
	mesh_instance.position = Vector3(0.0, radius, 0.0)
	_turntable.add_child(mesh_instance)
	return mesh_instance


func _clear_body() -> void:
	if _body != null and is_instance_valid(_body):
		_body.queue_free()
	_body = null
	for child in _turntable.get_children():
		child.queue_free()


func _frame_camera(height: float, radius: float) -> void:
	for child in _world.get_children():
		if child is Camera3D:
			child.queue_free()
	var camera := Camera3D.new()
	camera.fov = 32.0
	camera.current = true
	_world.add_child(camera)
	var distance := maxf(height, radius * 2.2) * 2.4 + 0.8
	var eye := Vector3(0.0, height * 0.55, distance)
	camera.look_at_from_position(eye, Vector3(0.0, height * 0.5, 0.0), Vector3.UP)


## --- orbit -------------------------------------------------------------

func _process(delta: float) -> void:
	if _turntable == null or not is_visible_in_tree():
		return

	var yaw := IDLE_SPIN_SPEED * delta

	# Right stick, any connected pad. Polled rather than routed through an
	# input action — see JOY_AXIS_RIGHT_X's own note.
	for device in Input.get_connected_joypads():
		var x := Input.get_joy_axis(device, JOY_AXIS_RIGHT_X)
		if absf(x) > STICK_DEADZONE:
			yaw += x * STICK_ORBIT_SPEED * delta
			break

	_turntable.rotate_y(yaw)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mb.pressed
	elif event is InputEventMouseMotion and _dragging and _turntable != null:
		_turntable.rotate_y(-(event as InputEventMouseMotion).relative.x * MOUSE_ORBIT_SPEED)
