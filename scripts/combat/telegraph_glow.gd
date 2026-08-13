extends Node3D

## The wind-up's own visual event, independent of the "! incoming" banner text.
##
## `R9.4-remainder-9-combat`: a blind critic covering the HUD text found the
## wind-up frame indistinguishable from ordinary standing — `combat_hud.gd`'s
## own comment already admits why, a placeholder creature has nothing built to
## show a charge-up. This is that something: a pulsing warning ring at the
## creature's feet for the exact length of the telegraph beat, so the read
## survives even with the banner covered.
##
## Same lessons `impact_flash.gd` already paid for: mesh-based rather than
## GPUParticles3D (particle behaviour is not trustworthy under the software
## renderer the survey captures with), MIX blend rather than ADD (additive
## renders at a fraction of its strength under the Compatibility renderer),
## and driven by the physics clock so the same beat looks the same in every
## survey run.

const SEGMENTS := 24
const PULSE_PERIOD := 0.32
## The glow fades to nothing in the last stretch of the beat rather than being
## cut off mid-pulse the instant the strike lands — an abrupt disappearance
## reads as a rendering glitch, not as "the warning is over."
const FADE_TAIL := 0.12

var _life: float = 0.0
var _duration: float = 0.55
var _radius: float = 1.1
var _colour: Color = Color("#ff5a3c")

var _ring: MeshInstance3D = null
var _ring_mesh: ImmediateMesh = null


## `at` is the creature's feet, not its centre — this is a ring on the ground,
## not a billboard on the body.
static func begin(parent: Node, at: Vector3, colour: Color, radius: float, duration: float) -> Node3D:
	var glow := new()
	glow._colour = colour
	glow._radius = radius
	glow._duration = duration
	parent.add_child(glow)
	glow.global_position = at
	return glow


func _ready() -> void:
	_ring_mesh = ImmediateMesh.new()
	_ring = MeshInstance3D.new()
	_ring.mesh = _ring_mesh
	_ring.material_override = _material()
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var reach := _radius * 2.5
	_ring.custom_aabb = AABB(Vector3(-reach, -0.2, -reach), Vector3(reach * 2.0, 0.4, reach * 2.0))
	add_child(_ring)


func _material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.disable_receive_shadows = true
	material.vertex_color_use_as_albedo = true
	# R9.4-remainder-9-combat-2: tried the same fix `impact_flash.gd`'s own
	# `no_depth_test` comment documents (this ring spawns "at the creature's
	# feet", overlapping its mesh footprint the same way the impact burst
	# does, while the arena boundary and target marker -- the codebase's
	# other `no_depth_test = false` ground/near effects -- both sit apart
	# from any creature mesh and never hit this). A first off-axis capture
	# (`04-enemy-winds-up-offaxis.png`, run 1) showed a fully visible,
	# unoccluded wild pal with NO ring at its feet at all, at a moment the
	# HUD's own "! incoming" text confirms the wind-up was active -- looked
	# like the same depth-loses-to-the-creature symptom.
	#
	# It was NOT. Set to true and RE-RENDERED to check (not asserted): a
	# second full survey, same unoccluded framing, still shows no ring at
	# all. Left true anyway -- it is still the correct value by the same
	# reasoning that fixed `impact_flash.gd`, and reverting it would not make
	# the ring appear or disappear either way -- but the real cause of "no
	# ring ever draws" is still open. Worth checking next: whether
	# `telegraph_started` is actually reaching `_on_enemy_telegraph`
	# (combat_manager.gd) at all for this creature/attack, before touching
	# this file's own drawing code again.
	material.no_depth_test = true
	return material


func _physics_process(delta: float) -> void:
	_life += delta
	if _life >= _duration:
		queue_free()
		return

	var phase: float = fmod(_life, PULSE_PERIOD) / PULSE_PERIOD
	var eased: float = 1.0 - pow(1.0 - phase, 2.0)
	var tail: float = clampf((_duration - _life) / FADE_TAIL, 0.0, 1.0)
	_draw_ring(_radius * (0.35 + eased * 0.65), (1.0 - eased) * tail)


## Flat on the ground rather than camera-facing: it is a mark on the terrain
## under the creature, readable from the combat camera's own downward angle
## the same way the arena boundary's ground line already is.
func _draw_ring(radius: float, alpha: float) -> void:
	var inner := radius * 0.72
	_ring_mesh.clear_surfaces()
	_ring_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in SEGMENTS + 1:
		var angle: float = TAU * float(i) / float(SEGMENTS)
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		var colour := Color(_colour.r, _colour.g, _colour.b, alpha)
		_ring_mesh.surface_set_color(colour)
		_ring_mesh.surface_add_vertex(direction * inner)
		_ring_mesh.surface_set_color(colour)
		_ring_mesh.surface_add_vertex(direction * radius)
	_ring_mesh.surface_end()
