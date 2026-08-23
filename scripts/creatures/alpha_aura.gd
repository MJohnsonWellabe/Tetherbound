extends Node3D

## CREATURE-IDENTITY-2. The idle presence effect that marks a cluster's ALPHA.
##
## WILD-ECOLOGY (prompt 60) already spawns cluster leaders with a level bonus
## and a size multiplier, and the encounter director already names them
## `Alpha_<species>` -- but nothing about them LOOKED different, and a 1.3x
## size difference is only legible when an ordinary member of the same species
## happens to be standing beside it. Off the road, alone in a clearing, the
## player walked into a harder fight with no warning that was available before
## the first exchange. That is a presentation gap, not a balance one: the
## encounter is fine, the player just could not see it coming.
##
## So: a slow ring of motes drifting up around the animal, permanently, while
## it idles. Quiet enough not to read as a combat telegraph (which is a fast
## pulse in a warning colour -- see combat/telegraph_glow.gd), obvious enough at
## the distance a player decides whether to approach.
##
## Mesh-based, camera-facing, MIX-blended, physics-clocked. Every one of those
## is a lesson this project has already paid for, in combat/impact_flash.gd and
## combat/telegraph_glow.gd's own headers:
##
##   * GPUParticles3D behaviour is not trustworthy under the software renderer
##     the surveys capture with, so an effect built from particles cannot be
##     judged from a rendered frame -- and a visual-affecting change that cannot
##     be judged from a frame cannot ship under ralph/conventions.md.
##   * Additive blending renders at a fraction of its nominal strength under the
##     Compatibility renderer, which made a whole effect invisible once.
##   * A flat-on-the-ground ring is the one shape in this codebase that has an
##     open "never actually draws" mystery against it (telegraph_glow.gd's own
##     comment). Camera-facing billboards are its working siblings, so this is
##     built as billboards.
##   * An ImmediateMesh has no bounds until it first draws, so it can be culled
##     before it gets to say how big it is. State the AABB up front.
##
## Everything here is per-frame arithmetic over a fixed count of motes; there is
## no allocation in the loop and no physics.

## How many motes orbit the creature. Small on purpose: this has to survive a
## cluster of several alphas on screen without becoming the scene's brightest
## object.
const MOTES := 7
## Seconds for one full drift from the feet to the top of the rise.
const RISE_PERIOD := 2.6
## Seconds for one full revolution of the ring.
const ORBIT_PERIOD := 7.0
## Wedges in one mote's fan. Eight is enough for a shape this small to read as
## round rather than as a polygon.
const MOTE_SEGMENTS := 8

var _colour: Color = Color("#ffd479")
var _radius: float = 0.6
var _height: float = 1.0
var _life: float = 0.0

var _mesh: ImmediateMesh = null
var _instance: MeshInstance3D = null


## `radius` and `height` are the alpha's own gameplay body size, so the aura
## grows with the animal it belongs to rather than being one fixed size that
## swamps a bramblebun and disappears on a tuskroot.
static func attach(body: Node3D, radius: float, height: float, colour: Color) -> Node3D:
	var aura := new()
	aura.name = "AlphaAura"
	aura._radius = maxf(radius, 0.15)
	aura._height = maxf(height, 0.3)
	aura._colour = colour
	body.add_child(aura)
	return aura


func _ready() -> void:
	_mesh = ImmediateMesh.new()
	_instance = MeshInstance3D.new()
	_instance.mesh = _mesh
	_instance.material_override = _material()
	_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var reach: float = maxf(_radius * 3.0, _height * 1.5)
	_instance.custom_aabb = AABB(Vector3.ONE * -reach, Vector3.ONE * reach * 2.0)
	add_child(_instance)


func _material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.disable_receive_shadows = true
	material.vertex_color_use_as_albedo = true
	# Unlike impact_flash.gd's burst, this is NOT between two intersecting
	# bodies -- it orbits outside the animal's own silhouette. So it keeps depth
	# testing, and a mote passing behind the creature is correctly hidden. That
	# occlusion is most of what makes the ring read as being around the animal
	# in space rather than painted over it.
	material.no_depth_test = false
	return material


func _physics_process(delta: float) -> void:
	_life += delta
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var basis := camera.global_transform.basis
	var right: Vector3 = basis.x
	var up: Vector3 = basis.y

	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in MOTES:
		# Each mote gets its own phase so the ring never pulses in unison,
		# which is what would make it read as a telegraph.
		var offset: float = float(index) / float(MOTES)
		var rise: float = fmod(_life / RISE_PERIOD + offset, 1.0)
		var angle: float = TAU * (offset + _life / ORBIT_PERIOD)
		# Fade in off the ground and out at the top, so motes appear and vanish
		# rather than popping.
		var fade: float = sin(rise * PI)
		if fade <= 0.01:
			continue
		var swell: float = 1.0 - 0.35 * rise
		var centre := Vector3(cos(angle) * _radius * swell,
			_height * (0.08 + rise * 0.95),
			sin(angle) * _radius * swell)
		var size: float = _radius * 0.11 * (0.6 + 0.4 * fade)
		var colour := Color(_colour.r, _colour.g, _colour.b, fade * 0.7)
		_disc(centre, right * size, up * size, colour)
	_mesh.surface_end()


## A soft mote: an opaque centre fanned out to a fully transparent rim.
##
## The first version drew flat quads, and a flat quad with a constant alpha and
## no texture is exactly what that sounds like -- a rendered frame of an alpha
## burrowback came back with pale, hard-edged SQUARES floating beside the
## animal, which reads as a rendering fault rather than as an effect. The fade
## has to live in the geometry because a texture is not an option here: the
## effect is an ImmediateMesh drawn from vertex colours, and giving it an image
## would mean shipping and importing a sprite for seven dots.
func _disc(centre: Vector3, right: Vector3, up: Vector3, colour: Color) -> void:
	var rim := Color(colour.r, colour.g, colour.b, 0.0)
	for i in MOTE_SEGMENTS:
		var a0: float = TAU * float(i) / float(MOTE_SEGMENTS)
		var a1: float = TAU * float(i + 1) / float(MOTE_SEGMENTS)
		_mesh.surface_set_color(colour)
		_mesh.surface_add_vertex(centre)
		_mesh.surface_set_color(rim)
		_mesh.surface_add_vertex(centre + right * cos(a0) + up * sin(a0))
		_mesh.surface_set_color(rim)
		_mesh.surface_add_vertex(centre + right * cos(a1) + up * sin(a1))
