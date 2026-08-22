extends Node3D

## A ground campfire's glow: warm point light, flame billboards, ember
## particles and a taller smoke column, built the same "no texture asset"
## radial-gradient-billboard technique `torch_prop.gd` already proved (that
## file's own header: no flame/lantern/smoke texture exists anywhere in the
## project, and Quaternius Survival's Bonfire_Fire mesh cannot supply a
## standalone glow). NOT a copy-paste of torch_prop.gd -- that script also
## builds a handheld stick and is sized/positioned for bone-attachment; this
## is sized for a ground fire viewed from several metres and adds the OmniLight3D
## and smoke column a handheld torch has no reason to carry itself (both of
## its own callers add their own light from their own data instead).
##
## BAND1-D1 / GATE-D coordinator directive: the `trail_camp` cluster's
## approach read as "two small dark rectangles, silhouette-identical to fence
## or crate props anywhere else" from the spine. A campfire needs to be
## identifiable at range by glow and a vertical silhouette cue before a
## player is close enough to read individual props -- this is that cue.
##
## Flicker formula (two summed sine waves, not pure `sin()`, so the light
## reads as fire rather than a mechanical strobe/pulse) is the same recipe
## already shipped twice, in `scripts/player/torch.gd` and
## `scripts/build/build_piece.gd` -- copied rather than shared, since neither
## of those is a library this belongs importing from and the whole formula is
## four lines.

const FLAME_COLOUR := Color(1.0, 0.5, 0.1)
const FLAME_CORE_COLOUR := Color(1.0, 0.82, 0.32)
const SMOKE_COLOUR := Color(0.55, 0.53, 0.5, 0.35)

const FLAME_HEIGHT := 0.35
const OUTER_SIZE := 0.62
const CORE_SIZE := 0.30

const LIGHT_BASE_ENERGY := 2.6
const LIGHT_RANGE := 9.0
const FLICKER_AMOUNT := 0.35
const FLICKER_SPEED := 8.0

const GRADIENT_TEXTURE_SIZE := 32

## Smoke rises as a short stack of larger, softer, slower-fading discs so the
## column reads as a vertical smudge from a distance rather than a bright
## dot -- the specific gap the coordinator's approach-legibility note named
## ("it needs ... a vertical: smoke ... or Banner.obj").
const SMOKE_STEPS := 4
const SMOKE_BASE_HEIGHT := 0.55
const SMOKE_STEP_HEIGHT := 0.62
const SMOKE_BASE_SIZE := 0.35
const SMOKE_SIZE_GROWTH := 0.22

var _light: OmniLight3D = null
var _light_time := 0.0


func _init() -> void:
	name = "CampfireGlow"
	_build_flame()
	_build_light()
	_build_embers()
	_build_smoke()


func _process(delta: float) -> void:
	if _light == null:
		return
	_light_time += delta
	var noise := sin(_light_time * FLICKER_SPEED) * 0.6 + sin(_light_time * FLICKER_SPEED * 2.7 + 1.3) * 0.4
	_light.light_energy = LIGHT_BASE_ENERGY * (1.0 + noise * FLICKER_AMOUNT)


func _build_flame() -> void:
	var outer := _billboard_quad(OUTER_SIZE, FLAME_COLOUR, 0.0, 1.8, false)
	outer.name = "FlameOuter"
	outer.position = Vector3(0.0, FLAME_HEIGHT, 0.0)
	add_child(outer)

	var core := _billboard_quad(CORE_SIZE, FLAME_CORE_COLOUR, 0.3, 2.6, false)
	core.name = "FlameCore"
	core.position = Vector3(0.0, FLAME_HEIGHT + 0.03, 0.0)
	add_child(core)


func _build_light() -> void:
	_light = OmniLight3D.new()
	_light.name = "Glow"
	_light.light_color = Color(1.0, 0.68, 0.32)
	_light.light_energy = LIGHT_BASE_ENERGY
	_light.omni_range = LIGHT_RANGE
	_light.position = Vector3(0.0, FLAME_HEIGHT + 0.1, 0.0)
	_light.shadow_enabled = false
	add_child(_light)


func _build_embers() -> void:
	var particles := GPUParticles3D.new()
	particles.name = "Embers"
	particles.amount = 14
	particles.lifetime = 1.4
	particles.local_coords = false
	particles.position = Vector3(0.0, FLAME_HEIGHT, 0.0)

	var process_material := ParticleProcessMaterial.new()
	process_material.direction = Vector3(0.0, 1.0, 0.0)
	process_material.spread = 25.0
	process_material.initial_velocity_min = 0.3
	process_material.initial_velocity_max = 0.7
	process_material.gravity = Vector3(0.0, 0.35, 0.0)
	process_material.scale_min = 0.4
	process_material.scale_max = 1.0
	particles.process_material = process_material

	var quad := QuadMesh.new()
	quad.size = Vector2(0.05, 0.05)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.albedo_color = FLAME_COLOUR
	material.albedo_texture = _radial_gradient_texture(0.0, 1.0)
	material.emission_enabled = true
	material.emission = FLAME_COLOUR
	material.emission_energy_multiplier = 2.0
	quad.material = material
	particles.draw_pass_1 = quad

	add_child(particles)
	particles.emitting = true


## A short stack of static, alpha-blended (not additive -- smoke does not
## glow) discs, growing and softening with height, so the whole column reads
## as one smudge tapering upward rather than repeated identical dots.
func _build_smoke() -> void:
	for i in SMOKE_STEPS:
		var t := float(i) / float(SMOKE_STEPS - 1)
		var size := SMOKE_BASE_SIZE + SMOKE_SIZE_GROWTH * t
		var alpha := SMOKE_COLOUR.a * (1.0 - t * 0.6)
		var colour := Color(SMOKE_COLOUR.r, SMOKE_COLOUR.g, SMOKE_COLOUR.b, alpha)
		var disc := _billboard_quad(size, colour, 0.0, 0.0, true)
		disc.name = "Smoke%d" % i
		disc.position = Vector3(0.0, SMOKE_BASE_HEIGHT + SMOKE_STEP_HEIGHT * t, 0.0)
		add_child(disc)


func _billboard_quad(size: float, colour: Color, inner_hold: float, emission_energy: float, alpha_blend: bool) -> MeshInstance3D:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(size, size)

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX if alpha_blend else BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = colour
	material.albedo_texture = _radial_gradient_texture(inner_hold, 1.0)
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = colour
		material.emission_energy_multiplier = emission_energy

	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


## Same recipe as `torch_prop.gd::_radial_gradient_texture` -- not shared
## code, the same small cheap one.
func _radial_gradient_texture(inner_hold: float, edge_alpha: float) -> GradientTexture2D:
	var gradient := Gradient.new()
	if inner_hold > 0.0:
		gradient.offsets = PackedFloat32Array([0.0, inner_hold, 1.0])
		gradient.colors = PackedColorArray([
			Color(1.0, 1.0, 1.0, 1.0),
			Color(1.0, 1.0, 1.0, 1.0),
			Color(1.0, 1.0, 1.0, 0.0),
		])
	else:
		gradient.offsets = PackedFloat32Array([0.0, 1.0])
		gradient.colors = PackedColorArray([
			Color(1.0, 1.0, 1.0, edge_alpha),
			Color(1.0, 1.0, 1.0, 0.0),
		])

	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = GRADIENT_TEXTURE_SIZE
	texture.height = GRADIENT_TEXTURE_SIZE
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture
