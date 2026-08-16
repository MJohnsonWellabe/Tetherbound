extends Node3D

## A move's travel: the bolt, wave or gust that crosses the gap between two
## creatures before the blow lands.
##
## ## What this is and, more importantly, what it is not
##
## The owner chose "long cone, visible projectile" over real travelling
## hitboxes: reach and arc decide whether a ranged move connects, exactly as
## they always have, and that decision is still made instantly by
## `combat_math.gd::in_hit_cone` on the frame of the strike. This node is the
## PERFORMANCE of that decision, not the mechanism. Nothing here can miss,
## nothing here collides, and nothing here touches damage.
##
## That has one honest consequence worth naming: a ranged move cannot be dodged
## by stepping aside once it is in the air. It was decided at the strike. What
## the travel buys is readability -- Pebble Toss at nine metres used to be a
## creature standing still while the opponent's health dropped, with no visible
## cause anywhere between them.
##
## The `arrived` signal is how the impact stays honest. `combat_manager.gd`
## holds its impact burst until this fires, so the flash goes off when the bolt
## gets there rather than the instant the button was pressed.
##
## ## Why meshes and not GPUParticles3D
##
## The same reason `impact_flash.gd` gives, and it is not a preference: the
## survey renders under software OpenGL, where particle behaviour is not
## trustworthy, and a projectile that only appears on the developer's machine
## would make every future survey a lie about how a fight reads. Unshaded and
## additive so it holds up against sunlit grass, a shadowed hillside and a
## sunset alike.

const SEGMENTS := 12
## Metres per second used when a move's `vfx` block names no speed. Fast enough
## that a bolt never feels lobbed, slow enough to be seen crossing. TUNABLE.
const DEFAULT_SPEED := 24.0
## A travel is clamped into this window however far apart the two fighters are.
## Below the floor the bolt is a single frame's flicker; above the ceiling the
## fight visibly waits for it. TUNABLE.
const MIN_TRAVEL := 0.06
const MAX_TRAVEL := 0.42

signal arrived()

var _from: Vector3 = Vector3.ZERO
var _to: Vector3 = Vector3.ZERO
var _elapsed: float = 0.0
var _travel: float = 0.2
var _colour: Color = Color("#ffd27a")
var _kind: String = "projectile"
var _done: bool = false

var _body: MeshInstance3D = null
var _mesh: ImmediateMesh = null


## Launch one. `spec` is a move's own `vfx` block from `data/moves/moves.json`.
##
## Returns the node so a caller can await `arrived`; returns null for a `kind`
## that has no travel to draw (a plain melee swing), which lets the caller ask
## unconditionally and branch on the answer instead of duplicating the
## "is this move ranged" test.
static func launch(parent: Node, from: Vector3, to: Vector3, spec: Dictionary) -> Node3D:
	var kind := str(spec.get("kind", "melee"))
	if kind == "melee" or parent == null:
		return null

	var shot := new()
	shot._kind = kind
	shot._from = from
	shot._to = to
	shot._colour = Color(str(spec.get("colour", "#ffd27a")))
	var speed := float(spec.get("speed", DEFAULT_SPEED))
	# An area move erupts where it stands rather than crossing anything, so it
	# gets the floor and reads as an immediate burst.
	var distance := from.distance_to(to) if kind != "area" else 0.0
	shot._travel = clampf(distance / maxf(speed, 0.001), MIN_TRAVEL, MAX_TRAVEL)
	parent.add_child(shot)
	shot.global_position = from
	return shot


func _ready() -> void:
	_mesh = ImmediateMesh.new()
	_body = MeshInstance3D.new()
	_body.mesh = _mesh
	_body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.vertex_color_use_as_albedo = true
	material.disable_receive_shadows = true
	material.no_depth_test = false
	_body.material_override = material
	add_child(_body)
	_redraw(0.0)


func _process(delta: float) -> void:
	if _done:
		return
	_elapsed += delta
	var t := clampf(_elapsed / maxf(_travel, 0.001), 0.0, 1.0)
	global_position = _from.lerp(_to, t)
	_redraw(t)
	if t >= 1.0:
		_done = true
		arrived.emit()
		queue_free()


## The bolt itself, rebuilt each frame in local space.
##
## Three shapes, one builder, because they differ only in how they scale with
## `t`: a `projectile` is a compact head with a tail streaming behind it, a
## `cone` widens as it advances (a wave front), and an `area` expands as a flat
## ring from where it was launched. Fading out over the last third in every case
## so nothing ever vanishes on a hard cut.
func _redraw(t: float) -> void:
	_mesh.clear_surfaces()
	var fade := 1.0 - clampf((t - 0.66) / 0.34, 0.0, 1.0)
	if fade <= 0.0:
		return
	var colour := Color(_colour.r, _colour.g, _colour.b, _colour.a * fade)
	var core := colour.lerp(Color(1, 1, 1, colour.a), 0.55)

	match _kind:
		"cone":
			# Widening wave front, drawn across the direction of travel.
			var half := lerpf(0.35, 2.2, t)
			var forward := (_to - _from).normalized()
			var side := forward.cross(Vector3.UP).normalized()
			if side.length() < 0.001:
				side = Vector3.RIGHT
			_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			_quad(-side * half + Vector3.UP * -0.25, side * half + Vector3.UP * -0.25,
					side * half * 0.6 + Vector3.UP * 0.75, -side * half * 0.6 + Vector3.UP * 0.75,
					colour, core)
			_mesh.surface_end()
		"area":
			# A flat expanding ring at the caster's feet.
			var radius := lerpf(0.2, 2.6, t)
			_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			for i in SEGMENTS:
				var a0 := TAU * float(i) / float(SEGMENTS)
				var a1 := TAU * float(i + 1) / float(SEGMENTS)
				var inner := radius * 0.72
				_quad(
					Vector3(cos(a0) * inner, 0.06, sin(a0) * inner),
					Vector3(cos(a1) * inner, 0.06, sin(a1) * inner),
					Vector3(cos(a1) * radius, 0.06, sin(a1) * radius),
					Vector3(cos(a0) * radius, 0.06, sin(a0) * radius),
					core, colour)
			_mesh.surface_end()
		_:
			# A head with a tail behind it, along the line of flight.
			var back := (_from - _to).normalized() * 1.1
			var up := Vector3.UP * 0.16
			var across := (_to - _from).normalized().cross(Vector3.UP).normalized() * 0.16
			if across.length() < 0.001:
				across = Vector3.RIGHT * 0.16
			_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			_quad(-across, across, across + back, -across + back, core, colour)
			_quad(-up, up, up + back, -up + back, core, colour)
			_mesh.surface_end()


## One quad as two triangles, `near_colour` at the first edge fading to
## `far_colour` at the second.
func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		near_colour: Color, far_colour: Color) -> void:
	_mesh.surface_set_color(near_colour)
	_mesh.surface_add_vertex(a)
	_mesh.surface_set_color(near_colour)
	_mesh.surface_add_vertex(b)
	_mesh.surface_set_color(far_colour)
	_mesh.surface_add_vertex(c)

	_mesh.surface_set_color(near_colour)
	_mesh.surface_add_vertex(a)
	_mesh.surface_set_color(far_colour)
	_mesh.surface_add_vertex(c)
	_mesh.surface_set_color(far_colour)
	_mesh.surface_add_vertex(d)
