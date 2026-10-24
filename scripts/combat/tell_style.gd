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
