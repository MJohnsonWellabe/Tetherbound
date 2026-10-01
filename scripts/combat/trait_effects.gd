extends RefCounted

## Shared CombatManager/EncounterHost use these same consumer formulas on
## canonical creature projections. Prediction/presentation never authors
## damage. All baselines already include IVs, bond and ordinary buffs.
const TRAITS := preload("res://scripts/creatures/traits.gd")

static func damage(creature: Variant, slot: String, baseline: float, cfg: Dictionary = {}) -> float:
	var effect: String = {"quick":"quick_power","charged":"charged_power","ultimate":"ultimate_power"}.get(slot,"")
	return TRAITS.apply_value(creature,effect,baseline,cfg)

static func move_profile(creature: Variant, baseline: Dictionary, cfg: Dictionary = {}) -> Dictionary:
	var result := baseline.duplicate(true)
	if result.has("cooldown"):
		result.cooldown = TRAITS.apply_value(creature,"cooldown",float(result.cooldown),cfg)
	return result

static func stat(creature: Variant, effect: String, baseline: float, cfg: Dictionary = {}) -> float:
	if not effect in ["wind_regen","defence","combat_speed","healing","poise","max_hp"]: return baseline
	return TRAITS.apply_value(creature,effect,baseline,cfg)

static func wind_cost(creature: Variant, slot: String, baseline: float, cfg: Dictionary = {}) -> float:
	return TRAITS.apply_value(creature,"burst_cost",baseline,cfg) if slot == "burst" else baseline
