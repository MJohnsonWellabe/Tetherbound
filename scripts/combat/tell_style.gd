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
