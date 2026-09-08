extends RefCounted

const MATH := preload("res://scripts/combat/combat_math.gd")
const WILD := preload("res://scripts/creatures/wild_creature.gd")

## Stage the bodies at the same clearance the live enemy AI uses. A fixed
## centre gap can put scaled creatures inside one another before the input.
static func distance_for(mine: float, theirs: float) -> float:
	return float(WILD.spaced_config_for(MATH.config().get("enemy", {}),
		mine, theirs).get("preferred_range", 0.0))
