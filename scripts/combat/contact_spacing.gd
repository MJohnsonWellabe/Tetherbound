extends RefCounted

## COMBAT §5 contact spacing: two fighters never stand inside each other.
##
## Tidewake F14#0/#1 (Tess, Nerissa), Meadows F04#2/#7 and Stormwood F10#2
## failed C3 on the same frame: after a strike the ally and the opponent
## overlap at 4.7-6.6 m, the ally's body stands in front of the opponent's
## head, and no camera can separate two bodies that occupy the same space.
## The capsules never overlap (they collide); the RENDERED bodies do, because
## art is fitted to a footprint up to `footprint_allowance` times longer than
## the collider, and a strike's lunge carries the body up to the capsule.
##
## The rule: at contact range the pair keeps a minimum separation of the two
## rendered half-extents along the line between them plus a visible clearance,
## floored at the colliders' own sum (COMBAT §5: body size is not range). The
## opponent's `preferred_range` floors at the same separation (`pair_need`),
## so it walks to where the bodies clear. Every reach -- the player's
## (`combat_manager.floor_reach_for_bodies`, `host_move_profile`) and the
## opponent's (`wild_creature.spaced_config_for`) -- floors at the pair's
## LONGEST possible separation (`pair_reach_need`, each body's longest
## half-extent) plus 0.5 m, so no hold-apart and no turn of either body can
## carry a target out of a strike that would have reached it.
##
## Resolution is a soft positional correction on each body's own physics tick,
## swept with `move_and_collide` so it slides on terrain and never passes
## through geometry, and applied before the arena's own hold (so the ring still
## wins). The ALLY yields: it takes the whole correction at once. The OPPONENT
## holds its ground and yields only a deficit that has outlived
## `foe_yield_after_s` (the ally is pinned against a wall or the ring). That
## asymmetry is what makes it multiplayer-native: the opponent's position is
## host-authoritative everywhere, a guest only ever corrects its own locally
## piloted body against the host's proxy, and host, guest and solo apply the
## same distances. A body in a combat burst (the ally's dash, a CHARGER's
## travelling lunge) is exempt until the burst ends, so a lunge that reaches
## its target still reaches it and the lane still decides the hit.
##
## Static and stateless so tests and every body read one copy.

const MATH := preload("res://scripts/combat/combat_math.gd")

const ROLE_NONE := &""
const ROLE_ALLY := &"ally"
const ROLE_FOE := &"foe"


static func config() -> Dictionary:
	var cfg: Variant = MATH.config().get("contact_spacing", {})
	return cfg if cfg is Dictionary else {}


static func enabled(cfg: Dictionary = config()) -> bool:
	return bool(cfg.get("enabled", true))


## The rendered footprint's reach along one body-local horizontal direction.
## The footprint is treated as an ellipse with the fitted art's half-width
## (`half_x`) and half-length (`half_z`), so a long creature met head-on
## stands further out than the same creature met broadside.
static func directional_extent(half_x: float, half_z: float, local_dir: Vector2) -> float:
	if local_dir.length_squared() <= 0.000001:
		return maxf(half_x, half_z)
	var d := local_dir.normalized()
	return sqrt(half_x * half_x * d.x * d.x + half_z * half_z * d.y * d.y)


## Upper bound on any separation, so a malformed model cannot push a fight
## across its arena.
static func max_separation(cfg: Dictionary = config()) -> float:
	return float(cfg.get("max_separation_m", 12.0))


## Minimum centre-to-centre distance for a pair, in metres: the two rendered
## extents plus the visible clearance, never inside the colliders.
static func min_separation(extent_a: float, extent_b: float, radius_a: float, radius_b: float,
		cfg: Dictionary = config()) -> float:
	var wanted := extent_a + extent_b + float(cfg.get("visible_clearance_m", 0.6))
	var floor_at := radius_a + radius_b
	return maxf(minf(wanted, max_separation(cfg)), floor_at)


static func _radius(body: Node) -> float:
	return float(body.call("body_radius")) if body != null and body.has_method("body_radius") else 0.5


## The separation two live bodies keep as they stand now (directional). The
## opponent's `preferred_range` floors at this, so it walks to where the two
## bodies clear rather than into the other one. 0 when either is missing or
## the rule is off, which leaves every caller on its old numbers.
static func pair_need(a: Node, b: Node, cfg: Dictionary = config()) -> float:
	if not enabled(cfg) or a == null or b == null or not is_instance_valid(a) or not is_instance_valid(b) \
			or not a is Node3D or not b is Node3D:
		return 0.0
	var ea := float(a.call("contact_extent_towards", (b as Node3D).global_position)) \
		if a.has_method("contact_extent_towards") and (a as Node3D).is_inside_tree() else _radius(a)
	var eb := float(b.call("contact_extent_towards", (a as Node3D).global_position)) \
		if b.has_method("contact_extent_towards") and (b as Node3D).is_inside_tree() else _radius(b)
	return min_separation(ea, eb, _radius(a), _radius(b), cfg)


## The largest separation the pair can ever ask for, whichever way either body
## turns (each body's longest rendered half-extent). Every reach floors at this
## plus 0.5 m, so a body that turns mid-tell cannot be pushed out of a strike.
static func pair_reach_need(a: Node, b: Node, cfg: Dictionary = config()) -> float:
	if not enabled(cfg) or a == null or b == null or not is_instance_valid(a) or not is_instance_valid(b):
		return 0.0
	var ea := float(a.call("contact_half_length")) if a.has_method("contact_half_length") else _radius(a)
	var eb := float(b.call("contact_half_length")) if b.has_method("contact_half_length") else _radius(b)
	return min_separation(ea, eb, _radius(a), _radius(b), cfg)


## How much of an existing deficit this body takes this tick, 0..1.
static func share_for(role: StringName, deficit_age_s: float, cfg: Dictionary = config()) -> float:
	if role == ROLE_ALLY:
		return 1.0
	if role == ROLE_FOE and deficit_age_s >= float(cfg.get("foe_yield_after_s", 0.35)):
		return clampf(float(cfg.get("foe_yield_share", 1.0)), 0.0, 1.0)
	return 0.0


## The horizontal correction for the body at `mine` against the body at
## `theirs`. `closing_speed` is how fast this body is walking INTO the other
## (metres per second, >= 0): the step always covers at least that, so holding
## the stick into an opponent is a stop, not a slow creep through it.
## `fallback_dir` separates two bodies whose centres coincide.
static func correction(mine: Vector3, theirs: Vector3, need: float, share: float,
		closing_speed: float, delta: float, fallback_dir: Vector3,
		cfg: Dictionary = config()) -> Vector3:
	var offset := Vector3(mine.x - theirs.x, 0.0, mine.z - theirs.z)
	var distance := offset.length()
	var deficit := need - distance
	if deficit <= float(cfg.get("tolerance_m", 0.01)) or share <= 0.0:
		return Vector3.ZERO
	var away := offset / distance if distance > 0.0001 else Vector3(fallback_dir.x, 0.0, fallback_dir.z)
	if away.length_squared() <= 0.000001:
		away = Vector3.BACK
	away = away.normalized()
	var max_step := maxf(float(cfg.get("push_speed_mps", 6.0)), maxf(closing_speed, 0.0)) * maxf(delta, 0.0)
	return away * minf(deficit * share, max_step)
