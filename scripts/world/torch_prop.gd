extends Node3D

## The handheld torch's visible prop -- OF24, owner clarification: "what I was
## really talking about is one you carry around to light the way", after
## discovering `scripts/player/torch.gd` had been an invisible SpotLight since
## R0.11. The owner had never actually SEEN a torch.
##
## Built from primitives, not sourced from any vendored pack: the props dirs
## (assets/props/**, assets/environment/**) carry no torch/brand/lantern mesh
## at all (checked before writing this -- `find -iname "*torch*" -o -iname
## "*flame*" -o -iname "*lantern*"` across assets/ turns up nothing but the
## Quaternius Survival bonfire, whose "Fire" surface shares one ArrayMesh with
## its log geometry and cannot be pulled out standalone). CLAUDE.md/D24
## forbids a Meshy generation with no owner-supplied reference board for it,
## so this is geometry: a tapered cylinder stick, a flame built the same
## radial-gradient-billboard way `vegetation_harvest_point.gd`'s glint halo
## already proved (no flame texture exists anywhere in the project either,
## and this sidesteps needing one), and a handful of GPUParticles3D embers
## using that identical technique.
##
## Reused as-is by both OF24 callers, which is why the light itself is NOT
## built here: the carried torch (scripts/player/torch.gd, bone-attached to
## the trainer rig) and the free ground buildable (data/items/buildables.json
## `torch`, placed generically by scripts/build/build_piece.gd) each add
## their OWN OmniLight3D from their own data source (movement.json's `torch`
## block; the buildable's own `light` block) -- this scene only has to be
## geometry both can hang a light off, at the SAME local point either way
## (`flame_local_position()` below), so the glow always starts from where the
## flame visibly is.
##
## The stick's colour is not invented: `Kd 0.384608 0.289962 0.254778`,
## copied straight from the Quaternius Survival bonfire's own "Wood" material
## (assets/props/quaternius_survival/Bonfire_Fire.mtl) -- an existing pack's
## own colour data, reused rather than picked fresh.

const WOOD_COLOUR := Color(0.384608, 0.289962, 0.254778)
const FLAME_COLOUR := Color(1.0, 0.55, 0.12)
const FLAME_CORE_COLOUR := Color(1.0, 0.85, 0.35)

const STICK_HEIGHT := 0.78
const STICK_RADIUS_BASE := 0.022
const STICK_RADIUS_TIP := 0.014

const HALO_SIZE := 0.22
const CORE_SIZE := 0.10
const GRADIENT_TEXTURE_SIZE := 32

## Local Y the flame sits at, above the stick's own base -- both callers'
## lights read this through `flame_local_position()` instead of re-deriving
## it, so a future retune of the flame's height cannot silently desync the
## light from the geometry it is meant to be coming out of.
const FLAME_HEIGHT := STICK_HEIGHT + 0.06


func _init() -> void:
	name = "TorchProp"
	_build_stick()
	_build_flame()
	_build_embers()


func _build_stick() -> void:
	var mesh := CylinderMesh.new()
	mesh.height = STICK_HEIGHT
	mesh.top_radius = STICK_RADIUS_TIP
	mesh.bottom_radius = STICK_RADIUS_BASE
	mesh.radial_segments = 8

	var material := StandardMaterial3D.new()
	material.albedo_color = WOOD_COLOUR
	material.roughness = 0.9

	var instance := MeshInstance3D.new()
	instance.name = "Stick"
	instance.mesh = mesh
	instance.material_override = material
	instance.position = Vector3(0.0, STICK_HEIGHT * 0.5, 0.0)
	add_child(instance)


## Two billboard quads sampling a procedural radial-gradient texture --
## `vegetation_harvest_point.gd::_build_halo()`'s exact technique, additive
## blended so the flame actually fades to nothing at its edge instead of
## hard-cutting at a quad's own square silhouette. A wide, soft warm-orange
## outer glow plus a small bright yellow-white core reads as a flame shape at
## handheld distance without needing a texture asset at all.
func _build_flame() -> void:
	var outer := _billboard_quad(HALO_SIZE, FLAME_COLOUR, 0.0, 1.4)
	outer.name = "FlameOuter"
	outer.position = Vector3(0.0, FLAME_HEIGHT, 0.0)
	add_child(outer)

	var core := _billboard_quad(CORE_SIZE, FLAME_CORE_COLOUR, 0.35, 2.2)
	core.name = "FlameCore"
	core.position = Vector3(0.0, FLAME_HEIGHT + 0.015, 0.0)
	add_child(core)


## A handful of small emissive points drifting up off the flame, the same
## soft-gradient billboard reused as `draw_pass_1` instead of a hard-edged
## primitive -- consistent with the flame right above it rather than two
## different "no texture" workarounds in the same prop.
func _build_embers() -> void:
	var particles := GPUParticles3D.new()
	particles.name = "Embers"
	particles.amount = 8
	particles.lifetime = 1.0
	particles.local_coords = false
	particles.position = Vector3(0.0, FLAME_HEIGHT, 0.0)

	var process_material := ParticleProcessMaterial.new()
	process_material.direction = Vector3(0.0, 1.0, 0.0)
	process_material.spread = 20.0
	process_material.initial_velocity_min = 0.22
	process_material.initial_velocity_max = 0.48
	process_material.gravity = Vector3(0.0, 0.4, 0.0)
	process_material.scale_min = 0.4
	process_material.scale_max = 0.9
	particles.process_material = process_material

	var quad := QuadMesh.new()
	quad.size = Vector2(0.045, 0.045)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.albedo_color = FLAME_COLOUR
	material.albedo_texture = _radial_gradient_texture(0.0)
	material.emission_enabled = true
	material.emission = FLAME_COLOUR
	material.emission_energy_multiplier = 2.0
	quad.material = material
	particles.draw_pass_1 = quad

	add_child(particles)
	particles.emitting = true


func _billboard_quad(size: float, colour: Color, inner_hold: float, emission_energy: float) -> MeshInstance3D:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(size, size)

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = colour
	material.albedo_texture = _radial_gradient_texture(inner_hold)
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = emission_energy

	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


## Same helper as `vegetation_harvest_point.gd::_build_radial_gradient_texture`
## -- not shared code (that one is a private method on an unrelated script,
## and this prop has no reason to depend on it), just the same small, cheap
## recipe: a radial `GradientTexture2D`, opaque out to `inner_hold`, fading to
## fully transparent at the edge.
func _radial_gradient_texture(inner_hold: float) -> GradientTexture2D:
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
			Color(1.0, 1.0, 1.0, 1.0),
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


## The local point a caller's OmniLight3D should sit at to look like it is
## coming from the flame rather than floating apart from it. Both OF24
## callers (scripts/player/torch.gd, scripts/build/build_piece.gd) read this
## instead of re-deriving `FLAME_HEIGHT`.
func flame_local_position() -> Vector3:
	return Vector3(0.0, FLAME_HEIGHT, 0.0)
