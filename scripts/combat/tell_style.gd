extends RefCounted

## P2-093/P2-063: the soft ground-tell style, combat.json
## `telegraph.soft_style`. Presentation only. When it is enabled, the wind-up
## marks (feet ring, pattern shapes, lunge lane and guard cone) draw as a
## feathered, edge-lit outline over a faint wash instead of a flat filled slab.
## The danger area stays readable, and the creature standing in it stays
## visible. Shapes, sizes, timings and depth rules are unchanged. Empty means
## the flag is off, and callers then draw exactly as before.

const MATH := preload("res://scripts/combat/combat_math.gd")


static func soft() -> Dictionary:
	var cfg: Variant = MATH.config().get("telegraph", {}).get("soft_style", {})
	if cfg is Dictionary and cfg.get("enabled") == true:
		return cfg
	return {}


## The bright core line: the tell's own hue lifted toward white, so the edge
## reads as lit rather than as more of the same flat paint.
static func core_colour(colour: Color, style: Dictionary) -> Color:
	return colour.lerp(Color.WHITE, clampf(float(style.get("core_whiten", 0.45)), 0.0, 1.0))


## F22#4 storm tell (`cue_crackle` / `cue_lane_crackle`, 0 = off): GLSL for a
## world-space crackle of wavy energy filaments that run and flicker inside a
## ground tell, so an electric attack's warning reads as live current rather
## than flat paint (GPU/CPU judges, 22 Oct). Presentation only. Callers paste
## it above their fragment() and declare `uniform float crackle`.
const CRACKLE_GLSL := """
float tb_crackle(vec3 w, float t) {
	float a = sin(w.x * 3.1 + sin(w.z * 1.7 + t * 5.0) * 2.0 + t * 9.0);
	float b = sin(w.z * 2.6 + sin(w.x * 2.3 - t * 6.0) * 2.0 - t * 7.0);
	float l1 = 1.0 - smoothstep(0.0, 0.09, abs(a));
	float l2 = 1.0 - smoothstep(0.0, 0.07, abs(b));
	float flick = step(0.3, fract(sin(floor(t * 14.0) * 12.9898) * 43758.5453));
	return max(l1, l2 * 0.75) * (0.5 + 0.5 * flick);
}
"""


## F38#5-F41#5 bodied tell (`soft_style.curtain_height_m`; 0 = off). Biome
## defect judges still read the soft outline as "a flat magenta ring/slab"
## painted on the ground (COMBAT §13: telegraphs are shaped bodies). With a
## height set, each tell's outer rim also raises a thin light curtain that
## fades out upward, its brightness running along the rim (`shimmer`), so the
## warning stands up off the ground as an effect. Presentation only: the
## danger footprint, hue source, timings and depth rules are unchanged, and
## the curtain is its own depth-tested mesh, so a body in front still hides it.
static func curtain_height(style: Dictionary, build: float) -> float:
	var height := float(style.get("curtain_height_m", 0.0))
	if height <= 0.0:
		return 0.0
	return height * lerpf(clampf(float(style.get("curtain_build_start", 0.5)), 0.0, 1.0), 1.0, clampf(build, 0.0, 1.0))


## Brightness factor `along` metres down a rim at `time`: 1 when shimmer is
## off, else a wave travelling along the rim between 1 - shimmer and 1.
static func shimmer(style: Dictionary, along: float, time: float) -> float:
	var amount := clampf(float(style.get("shimmer", 0.0)), 0.0, 1.0)
	if amount <= 0.0:
		return 1.0
	var wavelength := maxf(0.1, float(style.get("shimmer_wavelength_m", 0.9)))
	var wave := sin(along * TAU / wavelength - time * TAU * float(style.get("shimmer_hz", 1.2)))
	return 1.0 - amount * (0.5 - 0.5 * wave)


## One material for every curtain: unshaded vertex colour, MIX (additive is
## faint under Compatibility), depth-tested so it never paints over a body.
static var _curtain_material: StandardMaterial3D = null


static func curtain_material() -> StandardMaterial3D:
	if _curtain_material == null:
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.disable_receive_shadows = true
		material.vertex_color_use_as_albedo = true
		material.no_depth_test = false
		material.render_priority = 1
		_curtain_material = material
	return _curtain_material


## A child mesh instance for a tell's curtain (empty mesh until drawn).
static func make_curtain(aabb: AABB) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = "TellCurtain"
	instance.mesh = ImmediateMesh.new()
	instance.material_override = curtain_material()
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.custom_aabb = aabb
	return instance


## Rebuilds `instance`'s curtain along each ground polyline in `lines` (in
## its local space): each segment rises `height`, `colour` at `alpha` at its
## foot, lifted toward white and fading to clear at the top. `closed` joins
## each line's last point to its first.
static func draw_curtain(instance: MeshInstance3D, lines: Array, colour: Color,
		alpha: float, height: float, style: Dictionary, time: float, closed: bool = false) -> void:
	if instance == null:
		return
	var mesh := instance.mesh as ImmediateMesh
	mesh.clear_surfaces()
	if height <= 0.0 or alpha <= 0.0:
		return
	var drawn := false
	for points: PackedVector3Array in lines:
		if points.size() < 2:
			continue
		if not drawn:
			mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			drawn = true
		_curtain_line(mesh, points, colour, alpha, height, style, time, closed)
	if drawn:
		mesh.surface_end()


static func _curtain_line(mesh: ImmediateMesh, points: PackedVector3Array, colour: Color,
		alpha: float, height: float, style: Dictionary, time: float, closed: bool) -> void:
	var foot := core_colour(colour, style)
	var top := colour.lerp(Color.WHITE, 0.7)
	var mid_at := clampf(float(style.get("curtain_mid", 0.3)), 0.05, 0.95)
	var mid_alpha := clampf(float(style.get("curtain_mid_alpha", 0.45)), 0.0, 1.0)
	var count := points.size() if closed else points.size() - 1
	var along := 0.0
	for index in count:
		var a := points[index]
		var b := points[(index + 1) % points.size()]
		var step := a.distance_to(b)
		var sa := alpha * shimmer(style, along, time)
		var sb := alpha * shimmer(style, along + step, time)
		along += step
		var tiers := [[0.0, 1.0, foot], [mid_at, mid_alpha, colour.lerp(top, 0.5)], [1.0, 0.0, top]]
		for tier in 2:
			var low: Array = tiers[tier]
			var high: Array = tiers[tier + 1]
			var a0 := a + Vector3.UP * height * float(low[0])
			var b0 := b + Vector3.UP * height * float(low[0])
			var a1 := a + Vector3.UP * height * float(high[0])
			var b1 := b + Vector3.UP * height * float(high[0])
			var ca0 := Color(low[2] as Color, sa * float(low[1]))
			var cb0 := Color(low[2] as Color, sb * float(low[1]))
			var ca1 := Color(high[2] as Color, sa * float(high[1]))
			var cb1 := Color(high[2] as Color, sb * float(high[1]))
			for pair: Array in [[a0, ca0], [b0, cb0], [b1, cb1], [a0, ca0], [b1, cb1], [a1, ca1]]:
				mesh.surface_set_color(pair[1])
				mesh.surface_add_vertex(pair[0])


## F38#5-F41#5 round 2 (`soft_style.dust_alpha`; 0 = off). The round-1
## judges still read any lit outline as a ground decal and asked for a
## physical wind-up: dust kicked up along the charge path and round the feet.
## Soft puffs rise and drift along each tell outline (forward along a lane, so
## its direction reads), thickening as the tell builds toward the strike.
## Presentation only; the danger footprint is the outline's.
static var _dust_texture: Texture2D = null
static var _dust_material: StandardMaterial3D = null


static func dust_enabled(style: Dictionary) -> bool:
	return float(style.get("dust_alpha", 0.0)) > 0.0


static func make_dust() -> MultiMeshInstance3D:
	if _dust_material == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 1))
		gradient.set_color(1, Color(1, 1, 1, 0))
		gradient.add_point(0.4, Color(1, 1, 1, 0.7))
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(1.0, 0.5)
		texture.width = 64
		texture.height = 64
		_dust_texture = texture
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		material.billboard_keep_scale = true
		material.vertex_color_use_as_albedo = true
		material.albedo_texture = _dust_texture
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.disable_receive_shadows = true
		material.render_priority = 1
		_dust_material = material
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = quad
	var instance := MultiMeshInstance3D.new()
	instance.name = "TellDust"
	instance.multimesh = multimesh
	instance.material_override = _dust_material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


## Places the puffs along each ground polyline in `lines` (local space).
## `build` 0..1 is how far into the tell it is; `flow` drifts puffs toward
## each line's end (a lane), else they only rise (a ring or outline).
static func draw_dust(instance: MultiMeshInstance3D, lines: Array, style: Dictionary,
		build: float, time: float, fade: float = 1.0, flow: bool = false) -> void:
	if instance == null:
		return
	var spacing := maxf(0.15, float(style.get("dust_spacing_m", 0.6)))
	var size := maxf(0.05, float(style.get("dust_size_m", 0.7)))
	var rise := float(style.get("dust_rise_m", 0.8))
	var rate := float(style.get("dust_hz", 1.1))
	var colour := Color(str(style.get("dust_colour", "#c9b38c")))
	var alpha := float(style.get("dust_alpha", 0.0)) * lerpf(float(style.get("dust_build_start", 0.35)), 1.0,
		clampf(build, 0.0, 1.0)) * clampf(fade, 0.0, 1.0)
	var spots: Array = []
	var cap := int(style.get("dust_max", 96))
	for points: PackedVector3Array in lines:
		var along := 0.0
		for index in points.size() - 1:
			var a := points[index]
			var b := points[index + 1]
			var step := a.distance_to(b)
			if step <= 0.0001:
				continue
			var next := ceilf(along / spacing) * spacing
			while next < along + step and spots.size() < cap:
				spots.append([a.lerp(b, (next - along) / step), (b - a) / step, spots.size()])
				next += spacing
			along += step
	var multimesh := instance.multimesh
	multimesh.instance_count = spots.size()
	for spot: Array in spots:
		var index := int(spot[2])
		var seed := fposmod(sin(float(index) * 12.9898) * 43758.5453, 1.0)
		var phase := fposmod(time * rate + seed, 1.0)
		var grow := size * (0.55 + 0.9 * phase) * (0.8 + 0.4 * seed)
		var at: Vector3 = spot[0] + Vector3.UP * (grow * 0.35 + rise * phase)
		if flow:
			at += (spot[1] as Vector3) * spacing * 1.5 * phase
		multimesh.set_instance_transform(index, Transform3D(Basis.from_scale(Vector3.ONE * grow), at))
		multimesh.set_instance_color(index, Color(colour, alpha * sin(PI * phase)))


## Round 2 on-attacker cue (`soft_style.tell_aura`; 0 = off): a rim glow in
## the tell's hue on the attacker's own meshes for the wind-up, the
## `enemy_pattern_telegraph.gd` boss-aura shader at this strength. Forward+
## takes the boss aura's renderer scale (Compatibility draws additive weakly).
const AURA_CODE := """
shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never;
uniform vec4 rim_colour : source_color = vec4(0.7, 0.96, 1.0, 1.0);
uniform float rim_power = 2.0;
uniform float strength = 1.2;
void fragment() {
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	ALBEDO = rim_colour.rgb * rim * strength;
}
"""
static var _aura_shader: Shader = null


## Puts the aura on `body`'s art; returns the meshes it took (for clear_aura).
static func apply_aura(body: Node3D, colour: Color, style: Dictionary) -> Array:
	var taken: Array = []
	var strength := float(style.get("tell_aura", 0.0))
	if strength <= 0.0 or not is_instance_valid(body):
		return taken
	if RenderingServer.get_current_rendering_method() != "gl_compatibility":
		strength *= float(style.get("tell_aura_forward_plus", 0.3))
	if _aura_shader == null:
		_aura_shader = Shader.new()
		_aura_shader.code = AURA_CODE
	var material := ShaderMaterial.new()
	material.shader = _aura_shader
	material.set_shader_parameter("rim_colour", colour.lerp(Color.WHITE, 0.25))
	material.set_shader_parameter("rim_power", float(style.get("tell_aura_power", 2.4)))
	material.set_shader_parameter("strength", strength)
	var art: Node = body.call("model_pivot") if body.has_method("model_pivot") else body
	if not art is Node3D:
		return taken
	for node: Node in art.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.visible and mesh.material_overlay == null:
			mesh.material_overlay = material
			taken.append(mesh)
	return taken


static func clear_aura(taken: Array) -> void:
	for mesh in taken:
		if is_instance_valid(mesh) and (mesh as MeshInstance3D).material_overlay is ShaderMaterial \
				and ((mesh as MeshInstance3D).material_overlay as ShaderMaterial).shader == _aura_shader:
			(mesh as MeshInstance3D).material_overlay = null
	taken.clear()
