extends RefCounted

## F33#3 / owner ruling RD-14 (STATE item 13): Stormwood's charged ground, the
## authored glass sink where the storm is always live (stormwood_surge_rules
## in_glass_sink), deals LIGHT contact damage to the trainer only: never to
## creatures, never lethal on the ordinary route (a health floor). Rootiron and
## Stormglass trainer gear reduce it (terrain_damage_reduction).
##
## Host-authoritative and personal, the same split as Stormwood lightning: the
## host alone decides, per tick, which trainers stand on charged ground and
## publishes a base hit per peer; each receiver applies its own worn gear and
## the floor to its own vitals. Tunables: stormwood_surge.json charged_ground.

## Host: base hits for this tick. `actors` maps peer -> {"position": Vector3,
## "ground_y": float, "in_fight": bool}. A trainer committed to a fight is
## spared (the creature is never targeted), as lightning spares it.
static func host_hits(rules: RefCounted, actors: Dictionary, cfg: Dictionary) -> Dictionary:
	var hits := {}
	var damage := float(cfg.get("damage_per_tick", 0.0))
	if not is_finite(damage) or damage <= 0.0:
		return hits
	for peer: Variant in actors:
		var row: Dictionary = actors[peer]
		var at: Vector3 = row.get("position", Vector3.INF)
		if row.get("in_fight") == true or not at.is_finite():
			continue
		if absf(at.y - float(row.get("ground_y", INF))) > float(cfg.get("contact_height_m", 1.5)):
			continue # Flying or falling: no contact.
		if rules.call("in_glass_sink", at):
			hits[peer] = {"damage": damage}
	return hits


## Receiver: this trainer's health after one charged-ground hit. Worn gear
## reduces it; it never takes health below the floor (and never heals one
## already below it).
static func health_after(health: float, max_health: float, damage: float, terrain_reduction: float, cfg: Dictionary) -> float:
	if not is_finite(health) or not is_finite(damage) or damage <= 0.0:
		return health
	var floor_hp := maxf(0.0, max_health) * clampf(float(cfg.get("health_floor_fraction", 0.3)), 0.05, 1.0)
	if health <= floor_hp:
		return health
	var taken := damage * (1.0 - clampf(terrain_reduction, 0.0, 1.0))
	return maxf(floor_hp, health - taken)
