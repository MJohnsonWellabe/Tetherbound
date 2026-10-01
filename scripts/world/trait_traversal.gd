extends RefCounted

const TRAITS := preload("res://scripts/creatures/traits.gd")

## Feed the actual mounted/carried owned creature; no trainer damage,
## stamina refill or new held input. Existing eligibility remains upstream.
static func speed(creature: Variant, mode: String, baseline: float, cfg: Dictionary = {}) -> float:
	var effect: String = {"ride":"ride_speed","swim":"swim_speed","fly":"fly_speed"}.get(mode,"")
	return TRAITS.apply_value(creature,effect,baseline,cfg)
