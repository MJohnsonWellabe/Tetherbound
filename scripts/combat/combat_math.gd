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
##
## `type_mult` is T3-TYPECHART's type-effectiveness multiplier, layered on in
## exactly the same shape and for the same reason: it defaults to 1.0, so every
## call site that does not pass one is byte-for-byte unchanged. It is a
## MULTIPLIER RATHER THAN A TERM on purpose — a flat +N would be worth
## everything at level 3 and nothing at level 20, which is the same argument
## `creature_instance.gd::boost_hp` makes in the opposite direction for elixirs.
##
## Deliberately NOT looked up here. This function is arithmetic over the
## numbers it is handed and knows nothing about species, moves or the chart;
## `scripts/combat/type_chart.gd` owns the lookup and `combat_manager.gd`
## performs it, which is what keeps the multiplier that gets APPLIED and the
## one the HUD TELLS THE PLAYER ABOUT the same single value.
static func base_damage(
	power: float, attack: float, defence: float, move_power: float = 1.0,
	type_mult: float = 1.0
) -> float:
	var cfg: Dictionary = config().get("damage", {})
	var scale := float(cfg.get("scale", 2.0))
	var minimum := float(cfg.get("minimum", 1.0))

	var total := attack + defence
	if total <= 0.0:
		return maxf(minimum, power * move_power * type_mult * scale * 0.5)
	return maxf(minimum, power * move_power * type_mult * scale * attack / total)


## Damage with the random spread applied. `roll` is 0..1, supplied by the
## caller so tests can pin it and the result stays reproducible. `move_power`
## and `type_mult` are the same two multipliers `base_damage` takes; see its
## comment.
##
## The type multiplier goes in BEFORE the variance roll rather than after, so
## the spread stays a proportion of the hit that was actually dealt. Applied
## afterwards it would be arithmetically identical here — but the moment
## anything clamps or rounds between the two it would stop being, and a hit's
## variance being a fixed band around the neutral damage rather than around its
## own is not what `variance`'s config comment promises ("every hit lands
## between 90% and 110%").
static func rolled_damage(
	power: float, attack: float, defence: float, roll: float, move_power: float = 1.0,
	type_mult: float = 1.0
) -> float:
	var cfg: Dictionary = config().get("damage", {})
	var variance := float(cfg.get("variance", 0.1))
	var minimum := float(cfg.get("minimum", 1.0))
	# roll 0 -> lowest, 0.5 -> exact, 1 -> highest.
	var multiplier := 1.0 + (clampf(roll, 0.0, 1.0) * 2.0 - 1.0) * variance
	return maxf(minimum, base_damage(power, attack, defence, move_power, type_mult) * multiplier)


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
## Owner playtest 2026-09-29 ("combat seemed a little slow"): the authored
## timings of a player move scaled by combat.json `player_pace`, and the charged
## attack's arc widened by its bonus. Pure; `block` is "player_quick" or
## "player_charged". A missing block leaves the profile untouched.
static func with_player_pace(profile: Dictionary, block: String) -> Dictionary:
	var pace: Dictionary = config().get("player_pace", {}) as Dictionary
	if pace.is_empty():
		return profile
	var scaled := profile.duplicate(true)
	for pair in [["windup", "windup_scale"], ["recovery", "recovery_scale"], ["cooldown", "cooldown_scale"]]:
		if scaled.has(pair[0]):
			scaled[pair[0]] = float(scaled[pair[0]]) * clampf(float(pace.get(pair[1], 1.0)), 0.3, 2.0)
	if block == "player_charged" and scaled.has("cone_degrees"):
		scaled["cone_degrees"] = minf(180.0, float(scaled["cone_degrees"]) + float(pace.get("charged_cone_bonus_degrees", 0.0)))
	return scaled


## Degrees a striker may turn toward its target just before the hit test
## (combat.json `strike_reaim`); 0 when disabled.
static func strike_reaim_degrees(is_quick: bool) -> float:
	var cfg: Dictionary = config().get("strike_reaim", {}) as Dictionary
	if not bool(cfg.get("enabled", false)):
		return 0.0
	return maxf(0.0, float(cfg.get("quick_max_degrees" if is_quick else "charged_max_degrees", 0.0)))


## `facing` turned toward `target` (flat) by at most `max_degrees`. Returns the
## input unchanged when it already faces the target, either vector is flat-zero,
## or `max_degrees` is 0.
static func reaimed_facing(origin: Vector3, facing: Vector3, target: Vector3, max_degrees: float) -> Vector3:
	var aim := Vector3(facing.x, 0.0, facing.z)
	var to := Vector3(target.x - origin.x, 0.0, target.z - origin.z)
	if max_degrees <= 0.0 or aim.length() < 0.001 or to.length() < 0.001:
		return facing
	aim = aim.normalized()
	to = to.normalized()
	var angle := aim.angle_to(to)
	if angle <= 0.0001:
		return facing
	var limit := deg_to_rad(max_degrees)
	if angle <= limit:
		return to
	var turn_sign := 1.0 if aim.cross(to).y >= 0.0 else -1.0
	return aim.rotated(Vector3.UP, turn_sign * limit)


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
