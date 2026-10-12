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
