extends RefCounted

## The wild creature's combat brain.
##
## Pure: it is handed a snapshot of the situation and returns what to do. No
## nodes, no timers of its own, no access to the scene. The node layer measures
## the distance, applies the movement and counts down the clocks.
##
## That split exists because this is the part of M2 most likely to be wrong.
## "The enemy never lets up", "it backs off too far", "it attacks the instant I
## finish attacking" are all things the owner will say, and each of them is a
## question about this decision table. Being able to ask that question in a unit
## test rather than by playing a fight and squinting is worth the indirection.
##
## The behaviour it implements is the smallest thing that is not a punching bag:
##
##   CLOSE      walk towards the player's creature until inside preferred range
##   TELEGRAPH  rooted, winding up, visible
##   RECOVER    rooted, vulnerable — this is the player's punish window
##   REPOSITION back off and circle, so the fight is not two creatures standing
##              in each other's faces trading hits
##
## F22 pattern selection and reactions use measured past observations only.
## The caller owns the cursor/clocks and freezes one selected profile until
## recovery finishes. No reaction cancels a committed tell or recovery.

enum Intent {
	CLOSE,
	TELEGRAPH,
	RECOVER,
	REPOSITION,
	IDLE,
	DODGE,
}


## Decide what the opponent should be doing.
##
## `state` is what it is doing now, `distance` is the horizontal gap to the
## player's creature, and the three timers are how long is left in the current beat.
## Returns the intent for this frame; the caller starts a new beat whenever the
## returned intent differs from the one it was in.
static func decide(
	state: Intent,
	distance: float,
	timer: float,
	cooldown: float,
	cfg: Dictionary
) -> Intent:
	var preferred := float(cfg.get("preferred_range", 2.1))

	match state:
		Intent.TELEGRAPH:
			# A committed wind-up runs to completion. An enemy that can cancel
			# its own telegraph makes the telegraph worthless, and the telegraph
			# is the only warning the fight gives.
			return Intent.TELEGRAPH if timer > 0.0 else Intent.RECOVER

		Intent.RECOVER:
			# Rooted until recovery ends. This is the window the player is meant
			# to punish, and shortening it under pressure would delete the only
			# reason to watch what the opponent is doing.
			return Intent.RECOVER if timer > 0.0 else Intent.REPOSITION

		Intent.REPOSITION:
			if timer > 0.0:
				return Intent.REPOSITION
			return Intent.CLOSE
		Intent.DODGE:
			return Intent.DODGE if timer > 0.0 else Intent.CLOSE

		_:
			# CLOSE or IDLE: attack if in reach and off cooldown, otherwise walk in.
			if distance <= preferred and cooldown <= 0.0:
				return Intent.TELEGRAPH
			return Intent.CLOSE


## How long the beat that was just entered should last.
static func duration_for(intent: Intent, cfg: Dictionary) -> float:
	match intent:
		Intent.TELEGRAPH:
			return float(cfg.get("telegraph", 0.55))
		Intent.RECOVER:
			return float(cfg.get("recovery", 0.75))
		Intent.REPOSITION:
			return float(cfg.get("reposition_time", 1.0))
		Intent.DODGE:
			return float(cfg.get("dodge_duration_s", 0.2))
		_:
			return 0.0


## Is the opponent rooted this frame? Rooted beats are what the player pushes
## against; if the answer were never true the fight would have no rhythm.
static func is_rooted(intent: Intent) -> bool:
	return intent == Intent.TELEGRAPH or intent == Intent.RECOVER


## Where to move, as a unit direction, given the direction towards the target.
##
## Repositioning goes backwards and sideways at once rather than straight back:
## a straight retreat is a rubber band that snaps the fight back to the same
## spot, whereas an arc moves it around the arena. `side_sign` is +1 or -1 and
## is chosen once per reposition by the caller, so the opponent commits to a
## direction instead of jittering between them.
##
## `inside_preferred` is CLOSE's waiting case (COMBAT-1): already inside
## preferred range but on cooldown. Walking in from there ends at body contact,
## so the next telegraph leaves no room to evade. Freezing there made a statue,
## and backing off made the enemy kite out of the pilot's reach; circling at the
## current distance is the header's own "circle" and does neither.
static func movement_for(intent: Intent, towards_target: Vector3, side_sign: float,
		inside_preferred := false) -> Vector3:
	var forward := Vector3(towards_target.x, 0.0, towards_target.z)
	if forward.length() < 0.001:
		return Vector3.ZERO
	forward = forward.normalized()

	match intent:
		Intent.CLOSE:
			if inside_preferred:
				return forward.cross(Vector3.UP).normalized() * signf(side_sign)
			return forward
		Intent.REPOSITION:
			var side := forward.cross(Vector3.UP).normalized() * signf(side_sign)
			return (-forward * 0.65 + side * 0.75).normalized()
		Intent.DODGE:
			return forward.cross(Vector3.UP).normalized() * signf(side_sign)
		_:
			return Vector3.ZERO


static func speed_for(intent: Intent, cfg: Dictionary, inside_preferred := false) -> float:
	match intent:
		Intent.CLOSE:
			if inside_preferred:
				return float(cfg.get("circle_speed", 1.2))
			return float(cfg.get("chase_speed", 4.6))
		Intent.REPOSITION:
			return float(cfg.get("reposition_speed", 3.8))
		Intent.DODGE:
			return float(cfg.get("dodge_distance_m", 3.0)) / maxf(0.001, float(cfg.get("dodge_duration_s", 0.2)))
		_:
			return 0.0


## Role vocabulary matches BOSSES 2.1 priority, including compound roles.
## An unmatched role is an authoring error, never a generic fallback.
static func normalize_role(role: String, patterns: Dictionary) -> String:
	var upper := role.to_upper()
	if upper in ["WALL", "CHARGER", "DIVER", "CURRENT", "ACE"]:
		return upper
	var aliases: Dictionary = patterns.get("role_aliases", {})
	for profile: String in ["WALL", "CHARGER", "DIVER", "CURRENT"]:
		for word: String in aliases.get(profile, []):
			if role.to_lower().contains(word):
				return profile
	return ""


static func species_role(species_id: String, patterns: Dictionary) -> String:
	return normalize_role(str((patterns.get("species_roles", {}) as Dictionary).get(species_id, "")), patterns)


## Only an authored named send-out may override its species to ACE.
static func context_role(patterns: Dictionary, context: Dictionary) -> String:
	var role := str(context.get("role", ""))
	var named: Dictionary = patterns.get("named", {}).get(str(context.get("pattern_id", "")), {})
	var rows: Array = named.get("sendouts", [])
	var index := int(context.get("sendout_index", 0))
	if index >= 0 and index < rows.size() and (rows[index] as Dictionary).has("role"):
		role = normalize_role(str(rows[index].role), patterns)
	return role if not role.is_empty() else species_role(str(context.get("species_id", "")), patterns)


## A named fight's sequence belongs to the fight, then to its exact send-out.
## The first Meadows wild band deliberately learns just the first role row.
static func pattern_ids(patterns: Dictionary, role: String, context: Dictionary) -> Array:
	var named_id := str(context.get("pattern_id", ""))
	if not named_id.is_empty():
		var named: Dictionary = (patterns.get("named", {}) as Dictionary).get(named_id, {})
		var rows: Array = named.get("sendouts", [])
		var index := int(context.get("sendout_index", 0))
		if index < 0 or index >= rows.size() or not rows[index] is Dictionary:
			return []
		return (rows[index] as Dictionary).get("sequence", []).duplicate()
	var roles: Dictionary = patterns.get("roles", {})
	var ids: Array = roles.get(role, [])
	if str(context.get("chapter", "meadows")) == "meadows" \
			and not bool(context.get("trainer_owned", false)) \
			and str(context.get("band", "")) == "band1_lower_meadows":
		return [ids[0]] if not ids.is_empty() else []
	return ids.duplicate()


## Returns an unspaced, immutable-at-entry strike profile. Node caller applies
## body clearance ONCE after this overlay. Cursor advances on attempt (also
## on interruption), never on frame, hit or RNG. No stat scaling here beyond the declared per-chapter power scales.
static func select_pattern(patterns: Dictionary, base: Dictionary, context: Dictionary,
		cursor: int) -> Dictionary:
	var role := context_role(patterns, context)
	var ids := pattern_ids(patterns, role, context)
	if ids.is_empty():
		return {}
	var id := str(ids[posmod(cursor, ids.size())])
	var row: Dictionary = (patterns.get("attacks", {}) as Dictionary).get(id, {})
	if row.is_empty():
		return {}
	var out := base.duplicate(true)
	out.merge(row.duplicate(true), true)
	out["pattern_attack_id"] = id
	out["combat_role"] = role
	out["pattern_id"] = str(context.get("pattern_id", ""))
	var chapter := str(context.get("chapter", "meadows"))
	var floor_row: Dictionary = (patterns.get("chapter_floors", {}) as Dictionary).get(chapter, {})
	if chapter == "meadows" and bool(context.get("after_south_bridge", false)):
		floor_row = (patterns.get("chapter_floors", {}) as Dictionary).get("meadows_late", {})
	var tell_floor := float(floor_row.get("telegraph", 0.8))
	if bool(out.get("heavy", false)):
		tell_floor = maxf(tell_floor, float(patterns.get("heavy_tell_floor_s", 1.1)))
	out["telegraph"] = maxf(tell_floor, float(out.get("telegraph", tell_floor)))
	out["recovery"] = maxf(float(floor_row.get("recovery", 0.6)), float(out.get("recovery", 0.6)))
	# COMBAT §7 ordinary wild / floor-trainer pressure, per chapter. Named
	# pattern fights keep their own authored numbers.
	# Officers, Masters and bosses keep their authored numbers (COMBAT §12.1):
	# the trainer scale reaches only bodies the director marks floor_trainer.
	if str(context.get("pattern_id", "")).is_empty():
		var key := ""
		if not bool(context.get("trainer_owned", false)): key = "wild_power_scale"
		elif bool(context.get("floor_trainer", false)): key = "trainer_power_scale"
		if not key.is_empty():
			out["power"] = float(out.get("power", 8.0)) * float((patterns.get(key, {}) as Dictionary).get(chapter, 1.0))
	var slot := str(out.get("slot", "quick"))
	out["move_id"] = str(out.get("move_override", context.get("move_" + slot, "")))
	if out.move_id.is_empty():
		return {}
	# Low-health tradeoffs are visible timing changes, confined to the role.
	if float(context.get("hp_fraction", 1.0)) <= float(patterns.get("low_hp_fraction", 0.3)):
		var tradeoff: Dictionary = (patterns.get("low_hp_tradeoffs", {}) as Dictionary).get(role, {})
		out["telegraph"] = float(out.telegraph) + float(tradeoff.get("telegraph_add_s", 0.0))
		out["reposition_time"] = maxf(0.0, float(out.get("reposition_time", 1.0)) + float(tradeoff.get("reposition_add_s", 0.0)))
		if posmod(cursor + 1, 3) == 0:
			out["recovery"] = float(out.recovery) + float(tradeoff.get("third_recovery_add_s", 0.0))
	return out


## Observation time is accumulated by the node only while the SAME visible
## state persists. These decisions cannot read a queued/future input. Dodge
## is a swept spatial move with no invulnerability, requiring a safe lane.
static func reaction(state: Intent, observation: Dictionary, patterns: Dictionary) -> String:
	if state != Intent.CLOSE and state != Intent.REPOSITION:
		return ""
	var cfg: Dictionary = patterns.get("reactions", {})
	var seen := float(observation.get("visible_for_s", 0.0))
	if seen < float(cfg.get("observation_s", 0.25)):
		return ""
	var action := str(observation.get("action", ""))
	var distance := float(observation.get("distance", INF))
	if action in ["charged_windup", "ultimate_windup"] \
			and distance > float(cfg.get("dodge_min_range_m", 3.0)) \
			and float(observation.get("dodge_cooldown_s", 0.0)) <= 0.0 \
			and bool(observation.get("safe_dodge_lane", false)):
		return "dodge"
	if state == Intent.CLOSE and action == "recovery" \
			and distance <= float(observation.get("quick_range", 0.0)) \
			and float(observation.get("attack_cooldown_s", 0.0)) <= 0.0:
		return "punish"
	return ""


## The punish still declares a complete quick tell and recovery. Reading a
## player's commitment provides opportunity; it does not buy an instant hit.
static func punish_profile(patterns: Dictionary, base: Dictionary, context: Dictionary) -> Dictionary:
	var local := context.duplicate(true)
	local.erase("pattern_id")
	var role := str(local.get("role", ""))
	var ids := pattern_ids(patterns, role, local)
	for index: int in ids.size():
		var row: Dictionary = (patterns.get("attacks", {}) as Dictionary).get(str(ids[index]), {})
		if str(row.get("slot", "")) == "quick":
			return select_pattern(patterns, base, local, index)
	return {}


## One geometry predicate serves host hit tests and named proof probes. All
## points are frozen on tell entry/heading lock by the node. A field checks a
## target once per cast receipt in the manager, not once per physics frame.
static func pattern_contains(profile: Dictionary, origin: Vector3, heading: Vector3,
		marker: Vector3, target: Vector3, target_radius: float = 0.0) -> bool:
	var offset := Vector3(target.x - origin.x, 0.0, target.z - origin.z)
	var forward := Vector3(heading.x, 0.0, heading.z).normalized()
	var shape := str(profile.get("telegraph_shape", "cone"))
	var radius := maxf(0.0, target_radius)
	match shape:
		"ring":
			return offset.length() <= float(profile.get("range", 0.0)) + radius \
				and offset.length() + radius >= float(profile.get("inner_radius_m", 0.0))
		"marker", "field":
			return Vector2(target.x - marker.x, target.z - marker.z).length() <= float(profile.get("marker_radius_m", 0.0)) + radius
		"lane":
			var along := offset.dot(forward)
			var across := absf(offset.dot(forward.cross(Vector3.UP)))
			return along >= -radius and along <= float(profile.get("lunge", 0.0)) + radius \
				and across <= float(profile.get("lane_half_width_m", 0.0)) + radius
		"fan", "cone":
			if offset.length() > float(profile.get("range", 0.0)) + radius:
				return false
			if offset.length() <= radius:
				return true
			var allowance := rad_to_deg(asin(clampf(radius / offset.length(), 0.0, 1.0)))
			var angle := rad_to_deg(acos(clampf(offset.normalized().dot(forward), -1.0, 1.0)))
			return angle <= float(profile.get("cone_degrees", 0.0)) * 0.5 + allowance
	return false


static func chapter_windows(patterns: Dictionary, context: Dictionary, profile: Dictionary) -> Dictionary:
	var key := str(context.get("chapter", "meadows"))
	if key == "meadows" and bool(context.get("after_south_bridge", false)):
		key = "meadows_late"
	var floor_row: Dictionary = (patterns.get("chapter_floors", {}) as Dictionary).get(key, {})
	var out := profile.duplicate(true)
	var tell := float(floor_row.get("telegraph", 0.8))
	if bool(out.get("heavy", false)):
		tell = maxf(tell, float(patterns.get("heavy_tell_floor_s", 1.1)))
	out["telegraph"] = maxf(tell, float(out.get("telegraph", tell)))
	out["recovery"] = maxf(float(floor_row.get("recovery", 0.6)), float(out.get("recovery", 0.6)))
	return out


## The named guardian's visible armored frontal sector rewards a flank.
## Applied to one accepted creature strike, never human/environment damage.
static func armored_front_scale(profile: Dictionary, enemy_position: Vector3,
		enemy_heading: Vector3, attacker_position: Vector3) -> float:
	if not profile.has("armored_front_degrees"):
		return 1.0
	var offset := Vector3(attacker_position.x - enemy_position.x, 0.0, attacker_position.z - enemy_position.z)
	var forward := Vector3(enemy_heading.x, 0.0, enemy_heading.z).normalized()
	if offset.length_squared() < 0.000001:
		return 1.0
	var angle := rad_to_deg(acos(clampf(offset.normalized().dot(forward), -1.0, 1.0)))
	return clampf(float(profile.get("front_damage_scale", 1.0)), 0.0, 1.0) \
		if angle <= float(profile.armored_front_degrees) * 0.5 else 1.0
