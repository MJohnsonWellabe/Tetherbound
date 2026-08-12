extends Node3D

## The visual event of a blow landing.
##
## The blind critic measured this and the number is worth keeping: counting
## bright warm pixels at the moment of contact, `combat/05-quick-attack-lands`
## held **10 pixels**, `combat/06` held 295, and `palworld-01` held 24,623 —
## about ten thousand times more visual energy for the same beat. Its summary
## was that the only difference between the frame before a hit and the frame of
## the hit was that the health bar got shorter.
##
## So: a burst that occupies real screen area, at the point of contact, for
## about a third of a second. A ring that expands and fades, a core that flashes
## and shrinks, and a handful of radial streaks — all unshaded and additive, so
## they read at the same strength against sunlit grass, a shadowed hillside and
## a sunset.
##
## Built from meshes rather than GPUParticles3D on purpose. The survey renders
## under software OpenGL, where particle behaviour is not something to rely on,
## and a burst that only appears on the developer's machine is worse than none:
## it would make every future survey a lie about how the fight reads.
##
## Everything here is TUNABLE presentation in data/config/combat.json.

const SEGMENTS := 28
const STREAKS := 9

var _life: float = 0.0
var _duration: float = 0.34
var _radius: float = 1.5
var _colour: Color = Color("#ffd27a")
var _core_colour: Color = Color("#fff6df")

var _ring: MeshInstance3D = null
var _core: MeshInstance3D = null
var _streaks: MeshInstance3D = null
var _ring_mesh: ImmediateMesh = null
var _streak_mesh: ImmediateMesh = null


## `strength` scales the whole burst — a charged attack should not look like a
## quick one, because the difference between them is the only reason to build
## energy.
static func burst(parent: Node, at: Vector3, colour: Color, radius: float, duration: float, strength: float) -> Node3D:
	var flash := new()
	flash._colour = colour
	flash._radius = radius * strength
	flash._duration = duration
	parent.add_child(flash)
	flash.global_position = at
	return flash


func _ready() -> void:
	_ring_mesh = ImmediateMesh.new()
	_streak_mesh = ImmediateMesh.new()

	_ring = _billboard(_ring_mesh, _colour)
	_streaks = _billboard(_streak_mesh, _colour)

	# The core is a real sphere rather than a billboard: at the instant of
	# contact it sits between two bodies, and a flat quad there flickers as it
	# intersects them.
	var sphere := SphereMesh.new()
	sphere.radius = _radius * 0.22
	sphere.height = _radius * 0.44
	sphere.radial_segments = 10
	sphere.rings = 6
	_core = MeshInstance3D.new()
	_core.mesh = sphere
	_core.material_override = _additive(_core_colour)
	_core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_core)


func _billboard(mesh: Mesh, colour: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _additive(colour)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# An ImmediateMesh has no surfaces until the first frame draws one, so its
	# computed bounds start empty and the instance can be culled before it ever
	# gets to say how big it is. Stating the extent up front removes the question.
	var reach := _radius * 3.0
	node.custom_aabb = AABB(Vector3.ONE * -reach, Vector3.ONE * reach * 2.0)
	add_child(node)
	return node


## Unshaded, alpha-blended, depth-test off.
##
## Depth test off so a burst between two intersecting bodies is not swallowed by
## whichever mesh happens to be nearer. A hit that lands behind a creature's
## shoulder still has to read as a hit.
##
## MIX rather than ADD, which is the third thing that made this effect invisible.
## Additive blending renders at a fraction of its nominal strength under the
## Compatibility renderer the survey is forced onto: the burst drew correctly —
## right surfaces, right alpha, right camera, node visible — and came out as a
## barely perceptible smudge, which took a rendered close-up to see at all.
## Straight alpha does what it says on both pipelines. An effect that only
## exists on one renderer cannot be reviewed.
func _additive(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.disable_receive_shadows = true
	material.albedo_color = colour
	# No vertex colours: that one stays ruled out. With vertex-colour alpha the
	# burst rendered as a barely-visible smudge under additive blending and as
	# NOTHING under alpha blending, which is the signature of the alpha arriving
	# at the shader near zero. Opacity is one value on the material, set once
	# per frame, so there is exactly one place it can be wrong.
	#
	# `no_depth_test` IS set now, reversing the earlier call. A real captured
	# combat frame (`R9.4-remainder-9-combat`, a genuinely blind critic) showed
	# nothing at all at the moment of contact, on the real Terrain3D scene,
	# despite the exact same mesh/material rendering correctly in an isolated
	# test scene with a plain ground plane. The burst originates at the
	# creature's COLLISION centre (pal_body.gd's `centre()`), and pal_body's own
	# header already documents that the visual mesh is fitted to the collider
	# with slack ("a footprint allowance") — so on a creature whose model reads
	# larger than its collider, a depth-tested burst can end up entirely behind
	# the creature's own near-facing surface, occluded by the very thing it is
	# supposed to be a reaction to. A hit flash has one job; being hidden by the
	# hit target defeats it, and unlike the arena boundary or the orb (which sit
	# apart from any mesh that could occlude them) this effect is drawn AT one.
	material.no_depth_test = true
	return material


## Advanced on the PHYSICS clock, not the render clock.
##
## A 0.26-second effect driven by `_process` is gone inside a single frame when
## the renderer is running at a few frames a second, which is exactly what the
## survey harness does under software OpenGL. The burst fired correctly twelve
## times in a row and appeared in none of the captured frames.
##
## The fixed timestep also makes the effect reproducible: "five physics frames
## after the hit" is the same moment in every run, so two survey sheets are
## comparable. Presentation that only looks right at a particular frame rate is
## presentation nobody can review.
func _physics_process(delta: float) -> void:
	_life += delta
	var t: float = _life / maxf(0.001, _duration)
	if t >= 1.0:
		queue_free()
		return

	# Fast out, slow settle. A linear expansion reads as a growing circle; an
	# eased one reads as something having happened.
	var eased: float = 1.0 - pow(1.0 - t, 3.0)
	var fade: float = pow(1.0 - t, 2.4)

	_draw_ring(_radius * (0.3 + eased * 0.7), fade)
	_draw_streaks(_radius * (0.35 + eased * 1.0), fade)

	var core: float = maxf(0.001, (1.0 - eased) * 1.4)
	_core.scale = Vector3.ONE * core
	(_core.material_override as StandardMaterial3D).albedo_color = Color(
		_core_colour.r, _core_colour.g, _core_colour.b, fade
	)


## A camera-facing ring. Built each frame because it changes each frame, and an
## ImmediateMesh of thirty vertices is cheaper to rebuild than to interpolate.
func _draw_ring(radius: float, alpha: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var basis := camera.global_transform.basis
	var right := basis.x
	var up := basis.y

	_ring_mesh.clear_surfaces()
	(_ring.material_override as StandardMaterial3D).albedo_color = Color(
		_colour.r, _colour.g, _colour.b, alpha
	)
	_ring_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var inner: float = radius * 0.45
	for i in SEGMENTS + 1:
		var angle: float = TAU * float(i) / float(SEGMENTS)
		var direction: Vector3 = right * cos(angle) + up * sin(angle)
		_ring_mesh.surface_add_vertex(direction * inner)
		_ring_mesh.surface_add_vertex(direction * radius)
	_ring_mesh.surface_end()


## Radial streaks, unevenly spaced. Even spacing reads as a gear rather than as
## a spray, which is the same reason the scatter clusters its props.
func _draw_streaks(reach: float, alpha: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var basis := camera.global_transform.basis
	var right := basis.x
	var up := basis.y

	_streak_mesh.clear_surfaces()
	(_streaks.material_override as StandardMaterial3D).albedo_color = Color(
		_core_colour.r, _core_colour.g, _core_colour.b, alpha
	)
	_streak_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in STREAKS:
		# Deterministic from the index, so a survey frame is reproducible and two
		# runs of the same fight look the same.
		var angle: float = TAU * float(i) / float(STREAKS) + float(i * i) * 0.37
		var length: float = reach * (0.55 + 0.45 * fmod(float(i) * 0.618, 1.0))
		var direction: Vector3 = right * cos(angle) + up * sin(angle)
		var side: Vector3 = (right * -sin(angle) + up * cos(angle)) * reach * 0.055

		_streak_mesh.surface_add_vertex(direction * reach * 0.3 + side)
		_streak_mesh.surface_add_vertex(direction * reach * 0.3 - side)
		_streak_mesh.surface_add_vertex(direction * length)
	_streak_mesh.surface_end()
