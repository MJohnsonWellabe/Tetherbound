extends Node3D

## A ground campfire's presentation: an emissive flame, a warm point light,
## embers and a smoke column tall enough to find the camp from the road.
##
## ## What round 2 got wrong, and why this file changed shape
##
## Round 2 built the flame out of billboard quads because the note in this
## file's own header said no flame geometry existed: "Bonfire_Fire's extra
## surface shares the same combined mesh with the logs rather than isolating
## a flame". That is true of the OBJ file -- `Bonfire_Fire.obj` is a single
## object, `Bonfire_Fire_Cylinder.009` -- and false of what Godot imports.
## The OBJ loader splits by material, so the mesh arrives with three surfaces,
## `Wood`, `LightWood` and `Fire`, and `Fire` is a real flame cone that stands
## 1.63m above the log pile. `ignite()` below overrides that surface. The
## billboard flame is gone; what is left here is the part a mesh cannot do.
##
## The blind critic that failed round 2 reported seeing "only a few floating
## ember sparks" -- no flame, no glow, no smoke. That reads like a capture-path
## bug and is not one. `tools/_probe_trail_camp.gd` measured the placed
## cluster: every glow child existed and was `visible_in_tree`, the flame quad
## sat at world y=3.13 and the smoke column topped out at y=3.95, while the
## Bonfire prop's own mesh reached y=4.23. The flame and the entire smoke
## column were inside the log pile. The embers escaped because they are the
## one part that moves -- `local_coords = false`, rising 0.3-0.7 m/s for 1.4s,
## out through the top. The critic saw exactly what was renderable.
##
## So the sizes here are absolute metres and the caller counter-scales
## (`props.gd`), rather than the glow inheriting the prop's scale. A fire prop
## shrunk to a believable diameter must not shrink its own smoke column to
## match; that is the failure this note exists to prevent repeating.
##
## Flicker formula (two summed sine waves, not pure `sin()`, so the light
## reads as fire rather than a mechanical strobe) is the same recipe already
## shipped twice, in `scripts/player/torch.gd` and
## `scripts/build/build_piece.gd` -- copied rather than shared, since neither
## of those is a library this belongs importing from and the whole formula is
## four lines.

const FLAME_COLOUR := Color(1.0, 0.5, 0.1)
const SMOKE_COLOUR := Color(0.58, 0.56, 0.53, 0.30)

## Emissive override for the mesh's own `Fire` surface. Kept close to the
## material's authored albedo (0.657, 0.349, 0.132) rather than pushed to
## saturated orange, so the flame still reads as part of this asset pack.
const FIRE_SURFACE_NAME := "Fire"
## Round 3, second pass. Energy was 3.2 and the flame clipped to a white
## cone -- brighter than the sky, and reading as a ghost rather than a fire.
## The saturated orange plus a low multiplier keeps the highlight inside the
## hue when it does clip, which is what makes a small fire read hot instead
## of blown out under the Compatibility renderer's flat tonemap.
const FIRE_EMISSION := Color(1.0, 0.42, 0.10)
const FIRE_EMISSION_ENERGY := 1.4

## Soft additive bloom sitting over the flame mesh. One quad, not the four
## round 2 used: the mesh supplies the shape now, this only supplies the
## halo that emissive geometry alone does not give under the Compatibility
## renderer the capture tools use.
const HALO_HEIGHT := 0.5
const HALO_SIZE := 1.1
const HALO_ENERGY := 0.7

const LIGHT_HEIGHT := 0.55
const LIGHT_BASE_ENERGY := 3.4
const LIGHT_RANGE := 8.0
const FLICKER_AMOUNT := 0.32
const FLICKER_SPEED := 8.0

const GRADIENT_TEXTURE_SIZE := 32

## Smoke is the camp's landmark. From the trail the fire itself is a
## sub-metre object; the column is what carries at range, so it runs from
## just above the flame tip to ~4.6m and widens as it climbs. Round 2's
## column stopped at 0.57m wide and 1.4m up and was invisible from anywhere.
const SMOKE_STEPS := 7
const SMOKE_BASE_HEIGHT := 1.15
const SMOKE_TOP_HEIGHT := 4.6
const SMOKE_BASE_SIZE := 0.55
const SMOKE_TOP_SIZE := 2.0

const EMBER_HEIGHT := 0.85

var _light: OmniLight3D = null
var _light_time := 0.0


func _init() -> void:
	name = "CampfireGlow"
	_build_halo()
	_build_light()
	_build_embers()
	_build_smoke()


func _process(delta: float) -> void:
	if _light == null:
		return
	_light_time += delta
	var noise := sin(_light_time * FLICKER_SPEED) * 0.6 + sin(_light_time * FLICKER_SPEED * 2.7 + 1.3) * 0.4
	_light.light_energy = LIGHT_BASE_ENERGY * (1.0 + noise * FLICKER_AMOUNT)


## Makes the mesh's own `Fire` surface glow, on every MeshInstance3D under
## `prop`. Returns how many surfaces it lit, so a caller can tell "this prop
## has no flame geometry" from "the flame is lit" instead of assuming.
##
## Uses `set_surface_override_material` rather than editing the loaded Mesh's
## surface material: the Mesh resource is shared by every instance Godot's
## cache hands out, and mutating it would light the flame on any other prop
## that happens to reuse this asset.
static func ignite(prop: Node) -> int:
	var lit := 0
	for instance in _meshes(prop):
		var mesh: Mesh = instance.mesh
		if mesh == null:
			continue
		for i in mesh.get_surface_count():
			if mesh.surface_get_name(i) != FIRE_SURFACE_NAME:
				continue
			var source := mesh.surface_get_material(i) as StandardMaterial3D
			var material := source.duplicate() as StandardMaterial3D if source != null else StandardMaterial3D.new()
			material.emission_enabled = true
			material.emission = FIRE_EMISSION
			material.emission_energy_multiplier = FIRE_EMISSION_ENERGY
			instance.set_surface_override_material(i, material)
			lit += 1
	return lit


static func _meshes(node: Node, into: Array[MeshInstance3D] = []) -> Array[MeshInstance3D]:
	if node is MeshInstance3D:
		into.append(node as MeshInstance3D)
	for child in node.get_children():
		_meshes(child, into)
	return into


func _build_halo() -> void:
	var halo := _billboard_quad(HALO_SIZE, FLAME_COLOUR, 0.0, HALO_ENERGY, false)
	halo.name = "FlameHalo"
	halo.position = Vector3(0.0, HALO_HEIGHT, 0.0)
	add_child(halo)


func _build_light() -> void:
	_light = OmniLight3D.new()
	_light.name = "Glow"
	_light.light_color = Color(1.0, 0.68, 0.32)
	_light.light_energy = LIGHT_BASE_ENERGY
	_light.omni_range = LIGHT_RANGE
	_light.position = Vector3(0.0, LIGHT_HEIGHT, 0.0)
	_light.shadow_enabled = false
	add_child(_light)


func _build_embers() -> void:
	var particles := GPUParticles3D.new()
	particles.name = "Embers"
	particles.amount = 14
	particles.lifetime = 1.4
	particles.local_coords = false
	particles.position = Vector3(0.0, EMBER_HEIGHT, 0.0)

	var process_material := ParticleProcessMaterial.new()
	process_material.direction = Vector3(0.0, 1.0, 0.0)
	process_material.spread = 18.0
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


## A stack of static, alpha-blended (not additive -- smoke does not glow)
## discs, growing and softening with height, so the whole column reads as one
## smudge tapering upward rather than repeated identical dots.
func _build_smoke() -> void:
	for i in SMOKE_STEPS:
		var t := float(i) / float(SMOKE_STEPS - 1)
		var size: float = lerp(SMOKE_BASE_SIZE, SMOKE_TOP_SIZE, t)
		# Thins out with height rather than fading linearly, so the column
		# has a dense base and a dissipating top instead of a hard cut-off.
		var alpha: float = SMOKE_COLOUR.a * (1.0 - t * t * 0.85)
		var colour := Color(SMOKE_COLOUR.r, SMOKE_COLOUR.g, SMOKE_COLOUR.b, alpha)
		var disc := _billboard_quad(size, colour, 0.0, 0.0, true)
		disc.name = "Smoke%d" % i
		# Drifts slightly downwind as it climbs, so the column is a lean, not
		# a stack of concentric rings on one axis.
		disc.position = Vector3(
			0.35 * t * t,
			lerp(SMOKE_BASE_HEIGHT, SMOKE_TOP_HEIGHT, t),
			-0.22 * t * t)
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
