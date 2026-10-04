extends RefCounted

## F37 uses the admitted F28 creature record; level alone never grants Dive.
const CONFIG := "res://data/config/ripplet_traversal.json"
const BREAKTHROUGH := preload("res://scripts/creatures/breakthrough.gd")
static var _configuration: Dictionary = {}

static func config() -> Dictionary:
	if _configuration.is_empty():
		_configuration = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	return _configuration

static func owned(admitted: Dictionary, uid: String) -> Dictionary:
	var found: Dictionary = {}
	for row: Dictionary in admitted.get("party", []):
		if row.get("uid") == uid:
			if not found.is_empty(): return {}
			found = row
	return found if found.get("species_id") == "ripplet" and not found.get("fainted", true) and not found.get("resting", true) else {}

static func can_dive(admitted: Dictionary, uid: String) -> bool:
	var card := owned(admitted, uid)
	if card.is_empty(): return false
	var personal: Variant = admitted.get("redesign_character")
	if not personal is Dictionary or not personal.get("creatures") is Dictionary: return false
	var record: Variant = personal.creatures.get(uid)
	if not record is Dictionary or not record.get("breakthroughs") is Array: return false
	var tiers: Array = record.breakthroughs
	# F28 stores sequential completed tiers, never cap levels. Its validator
	# refuses missing prefixes, duplicates, strings and fractional tiers.
	var cap := BREAKTHROUGH.level_cap(tiers)
	var feast: Dictionary = BREAKTHROUGH.feasts().get("items", {}).get("feast_t3_water", {})
	var required := int(feast.get("tier", 0))
	var level: Variant = card.get("level")
	var saved_cap: Variant = record.get("cap_level")
	return cap > 0 and required > 0 and tiers.size() >= required \
		and (saved_cap is int or saved_cap is float) and is_finite(float(saved_cap)) and float(saved_cap) == float(cap) \
		and (level is int or level is float) and is_finite(float(level)) and float(level) == floorf(float(level)) \
		and float(level) >= float(feast.get("breaks_level", 30)) and float(level) <= float(cap)

static func local_record(game: Node) -> Dictionary:
	return game.local.save_data() if game != null and game.local != null else {}

static func route_speed(at: Vector3, diving: bool) -> float:
	var cfg := config()
	var speed := float(cfg.surface_speed_m_s)
	if not diving: return speed
	for route: Dictionary in cfg.routes:
		var a := Vector3(float(route.from[0]), at.y, float(route.from[2]))
		var b := Vector3(float(route.to[0]), at.y, float(route.to[2]))
		var nearest := a + (b - a) * clampf((at - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
		if at.distance_to(nearest) <= float(route.radius_m): return float(route.speed_m_s)
	return speed

static func action(intent: Dictionary, actor: Dictionary) -> Dictionary:
	if actor.get("realm") != "water" or str(actor.get("character_id", "")).is_empty(): return deny("Reach Tidewake first.")
	var uid := str(intent.get("creature_uid", ""))
	var admitted: Dictionary = actor.get("admitted", {})
	if admitted.get("character_id") != actor.get("character_id"): return deny("Use your own admitted Ripplet.")
	if owned(admitted, uid).is_empty() or actor.get("combat", true): return deny("Your own awake Ripplet can carry you outside combat.")
	if not actor.get("motion_valid", true): return deny("Wait for Ripplet's position to settle.")
	var command := str(intent.get("action", ""))
	if command not in ["mount", "dive", "surface"]: return deny("That traversal action is unknown.")
	if command != "mount" and (actor.get("mounted_uid") != uid or not actor.get("in_water", false)): return deny("Ride Ripplet into deep water first.")
	if command == "dive" and not can_dive(admitted, uid): return deny("Ripplet learns Dive at its L30 breakthrough feast.")
	if command == "dive" and (not actor.get("dive_clearance", false) or actor.get("sealed", true)): return deny("Find open deep water before diving.")
	if command == "mount" and not actor.get("mount_reachable", false): return deny("Move closer to your deployed Ripplet.")
	return {"ok": true, "reason": "", "uid": uid, "action": command}

static func deny(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}

static func valid_motion(previous: Vector3, current: Vector3, seconds: float, flow_speed: float) -> bool:
	if not previous.is_finite() or not current.is_finite() or not is_finite(seconds) or seconds <= 0.0: return false
	var maximum := float(config().surface_speed_m_s)
	for route: Dictionary in config().routes: maximum = maxf(maximum, float(route.speed_m_s))
	return Vector2(current.x-previous.x,current.z-previous.z).length() <= (maximum + maxf(0.0, flow_speed)) * seconds + float(config().position_slack_m)
