extends RefCounted

## Combat arithmetic, with no dependency on the scene tree.
##
## Every number a fight resolves passes through here, and nothing here knows
## about nodes, input or rendering. That is what makes it testable headlessly,
## the same split as scripts/player/player_vitals.gd.
##
## Kept as static functions rather than an instance, because none of it has
## state: damage is a function of the numbers handed to it and nothing else.

const CONFIG_PATH := "res://data/config/combat.json"

static var _config: Dictionary = {}


static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("combat.json missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_config = parsed
	return _config


## Damage for one hit, before variance.
##
## `power * scale * attack / (attack + defence) * move_power`.
##
## Bounded deliberately. A raw attack/defence ratio explodes as defence
## approaches zero and produces one-shot kills that read as a bug rather than as
## a strong attack. This form is monotonic in both inputs, always positive, and
## with the default scale of 2 an attacker deals exactly the move's power
## against an equal defender — which makes move power a number a designer can
## reason about instead of an arbitrary coefficient.
##
## `move_power` is D30's named-move multiplier (data/moves/moves.json's own
## `power` field), layered on top of `power` rather than replacing it — `power`
## stays whatever combat.json's `player_quick`/`enemy` blocks say a plain hit is
## worth, and `move_power` is what a specific named move does to that. It could
## not be called `power` too: GDScript will not accept two parameters with the
## same name, and the existing one is documented and called positionally
## throughout combat_manager.gd, so it keeps its name and the new multiplier
## takes this one instead. Every move ships at 1.0 (D30), so
## `move_power * power == power` for every call site that does not pass it.
static func base_damage(power: float, attack: float, defence: float, move_power: float = 1.0) -> float:
	var cfg: Dictionary = config().get("damage", {})
	var scale := float(cfg.get("scale", 2.0))
	var minimum := float(cfg.get("minimum", 1.0))

	var total := attack + defence
	if total <= 0.0:
		return maxf(minimum, power * move_power * scale * 0.5)
	return maxf(minimum, power * move_power * scale * attack / total)


## Damage with the random spread applied. `roll` is 0..1, supplied by the
## caller so tests can pin it and the result stays reproducible. `move_power`
## is the same D30 multiplier `base_damage` takes; see its comment.
static func rolled_damage(
	power: float, attack: float, defence: float, roll: float, move_power: float = 1.0
) -> float:
	var cfg: Dictionary = config().get("damage", {})
	var variance := float(cfg.get("variance", 0.1))
	var minimum := float(cfg.get("minimum", 1.0))
	# roll 0 -> lowest, 0.5 -> exact, 1 -> highest.
	var multiplier := 1.0 + (clampf(roll, 0.0, 1.0) * 2.0 - 1.0) * variance
	return maxf(minimum, base_damage(power, attack, defence, move_power) * multiplier)


## --- aiming ---------------------------------------------------------------
##
## Attacks are aimed and can miss (docs/decisions/D07). Whether a hit connects
## is decided here, as arithmetic over positions, rather than by a physics query
## — so it is unit-testable, deterministic, and cannot behave differently
## because of what collision layer something happens to be on.

## Does an attack from `origin` facing `facing` reach `target`?
##
## Range is measured on the horizontal plane only. Height differences on a
## hillside would otherwise cause misses the player cannot see the reason for,
## and there is no jumping in a fight for that to interact with.
static func in_hit_cone(
	origin: Vector3, facing: Vector3, target: Vector3,
	reach: float, cone_degrees: float
) -> bool:
	var to := target - origin
	to.y = 0.0
	var distance := to.length()
	if distance > reach:
		return false
	# Standing inside somebody always connects. Without this, two creatures
	# overlapping produce a zero-length direction and every attack whiffs, which
	# reads as the game being broken at exactly the moment it is most frantic.
	if distance < 0.001:
		return true

	var aim := Vector3(facing.x, 0.0, facing.z)
	if aim.length() < 0.001:
		return false
	var angle := rad_to_deg(aim.normalized().angle_to(to / distance))
	return angle <= cone_degrees * 0.5


## Convenience for the common case: read reach and arc from a move's config
## block, so callers do not each re-read the same two keys.
static func move_connects(move: Dictionary, origin: Vector3, facing: Vector3, target: Vector3) -> bool:
	return in_hit_cone(
		origin, facing, target,
		float(move.get("range", 2.6)),
		float(move.get("cone_degrees", 90.0))
	)


static func max_energy() -> float:
	return float(config().get("energy", {}).get("max", 100.0))


static func energy_per_quick() -> float:
	return float(config().get("energy", {}).get("gain_per_quick", 26.0))


static func charged_cost() -> float:
	return float(config().get("energy", {}).get("charged_cost", 100.0))


## Energy after landing a quick attack, clamped to the maximum. `multiplier`
## is Best Creature's "energy" ability (GAME_DESIGN.md §12) layered on top of
## the flat per-hit gain; every existing caller omits it and gets exactly
## today's `energy_per_quick()`.
static func energy_after_quick(current: float, multiplier: float = 1.0) -> float:
	return minf(max_energy(), current + energy_per_quick() * multiplier)


static func can_use_charged(current_energy: float) -> bool:
	return current_energy >= charged_cost()


## Energy after a charged attack. Returns the input unchanged when there was
## not enough, so a refused attack never spends: the caller checks
## `can_use_charged` first and this is the second line of defence.
static func energy_after_charged(current: float) -> float:
	if not can_use_charged(current):
		return current
	return maxf(0.0, current - charged_cost())


## How many quick attacks are needed from empty to afford one charged attack.
## Exposed because it is the single most important number in the fight's feel:
## too many and the charged attack never happens, too few and it is just a
## better quick attack.
static func quicks_to_charge() -> int:
	var per := energy_per_quick()
	if per <= 0.0:
		return 0
	return int(ceil(charged_cost() / per))
