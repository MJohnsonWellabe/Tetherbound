extends RefCounted

## F34 policy. World carrier is placed_buildings, never a second camp store.
const DATA := preload("res://scripts/data/redesign_data.gd")
const STATIONS := preload("res://scripts/build/station_rules.gd")
const LIVE := ["meadows", "tidewake", "cloudreach", "stormwood"]
const ID := "forward_camp"
const KIT := "forward_camp_kit"
const BIOMES := preload("res://scripts/data/biome_order.gd")

static func live_realm(realm: String) -> bool:
	return LIVE.has(BIOMES.canonical_id(realm))

static func config() -> Dictionary:
	var cfg: Variant = DATA.json("res://data/config/forward_camps.json")
	if not cfg is Dictionary or cfg.get("schema_version") != 1: return {}
	if not cfg.get("runtime_enabled") is bool or cfg.get("biomes") != LIVE: return {}
	if STATIONS.config().get("forward_camp",{}).get("maximum_per_character_per_biome") != 1: return {}
	for key: String in ["size_m", "bed_offset", "cookpot_offset", "workbench_offset"]:
		if not STATIONS.PLOT.numbers(cfg.get(key), 3): return {}
	for n: Variant in cfg.size_m:
		if float(n) <= 0: return {}
	for key: String in ["interaction_radius_m", "maximum_place_distance_m", "ground_tolerance_m", "maximum_slope_rise_m", "clearance_m"]:
		if not STATIONS.number(cfg.get(key)) or float(cfg[key]) <= 0: return {}
	return cfg

static func deny(code: String, station: String = "Workbench") -> Dictionary:
	var reasons := {"camp_disabled":"Forward camps are awaiting integration.",
		"camp_limit":"Pack up your existing camp in this biome first; its kit is fully refunded.",
		"camp_ground":"Place the whole camp on clear, supported, dry ground.",
		"camp_owner":"Only the character who placed this camp can pack it up.",
		"camp_occupied":"Wake the team before packing up this camp.",
		"camp_home_only":"Needs the homestead — use the %s." % station,
		"camp_unavailable":"This camp is unavailable; wait for its saved transaction."}
	return {"ok":false,"code":code,"reason":reasons.get(code,"The camp transaction was refused; nothing was spent.")}

static func record(records: Array, uid: String) -> Dictionary:
	if not uid.begins_with("b") or not uid.substr(1).is_valid_int() or int(uid.substr(1)) <= 0 \
			or str(int(uid.substr(1))) != uid.substr(1): return deny("camp_unavailable")
	var found := -1
	for i: int in records.size():
		if records[i] is Dictionary and records[i].get("uid") == uid:
			if found >= 0: return deny("camp_unavailable")
			found=i
	if found < 0: return deny("camp_unavailable")
	var row: Dictionary = records[found]
	if row.get("id") != ID or not row.get("realm") is String or not live_realm(row.realm) or row.get("paid") != true \
			or not row.get("paid") is bool or row.get("removed",false) != false \
			or not row.get("removed",false) is bool or not row.get("character_id") is String \
			or row.character_id.is_empty() or not transaction_id(row.get("txn_id")) \
			or not STATIONS.PLOT.numbers(row.get("position"),3) or not STATIONS.number(row.get("yaw_deg")):
		return deny("camp_unavailable")
	return {"ok":true,"record":row.duplicate(true),"index":found,
		"key":"forward_camp:%s:%s" % [row.realm,uid]}

## Additive saved-world preflight hook. Foundation invokes this before live
## application; old worlds containing no camps remain valid without migration.
static func saved_errors(records: Array) -> Array[String]:
	var errors: Array[String] = []
	var slots := {}
	for raw: Variant in records:
		if not raw is Dictionary or raw.get("id") != ID: continue
		var checked: Dictionary
		if raw.get("removed",false) == true:
			var restored := records.duplicate(true)
			for row: Variant in restored:
				if row is Dictionary and row.get("uid") == raw.get("uid"): row.removed=false
			checked=record(restored,str(raw.get("uid","")))
		else: checked=record(records,str(raw.get("uid","")))
		if checked.get("ok") != true:
			errors.append("Invalid forward camp record")
			continue
		if raw.get("removed",false) == true: continue
		var key: Array = [raw.character_id,BIOMES.canonical_id(raw.realm)]
		if slots.has(key): errors.append("Duplicate character/biome forward camp")
		slots[key]=true
	return errors

static func placement(cfg: Dictionary, records: Array, character: String, realm: String,
		at: Vector3, yaw: float) -> Dictionary:
	if cfg.get("runtime_enabled") != true: return deny("camp_disabled")
	if character.is_empty() or not live_realm(realm) or not at.is_finite() or not is_finite(yaw): return deny("camp_ground")
	for row: Variant in records:
		if row is Dictionary and row.get("id") == ID and row.get("removed",false) == false:
			var checked := record(records,str(row.get("uid","")))
			if checked.get("ok") != true: return checked
			if row.character_id == character and BIOMES.canonical_id(row.realm) == BIOMES.canonical_id(realm): return deny("camp_limit")
	return {"ok":true}

static func transaction_id(raw: Variant) -> bool:
	if not raw is String or raw.length() != 32: return false
	for c: String in raw:
		if not "0123456789abcdef".contains(c): return false
	return true

static func recipe(id: String, canonical: Dictionary, part: String = "") -> Dictionary:
	# Reject power recipes even if mistakenly added to the shared allowlist.
	var route := STATIONS.recipe_route(STATIONS.config(),id,canonical)
	var station := str(route.get("station_id","workbench")).capitalize()
	if canonical.has("feast_id") or id.begins_with("ascension_") or id.begins_with("feast_"):
		return deny("camp_home_only","Kitchen")
	if canonical.has("reinforce") or canonical.has("personal_gear_tier") \
			or canonical.has("gear_id") or canonical.has("refine") or canonical.has("attachment_id"):
		return deny("camp_home_only",station)
	if not STATIONS.config().get("recipe_routes",{}).get("field_allowed",[]).has(id):
		return deny("camp_home_only",station)
	if route.get("ok") != true or route.station_id not in ["kitchen","workbench"]:
		return deny("camp_home_only",station)
	var role := "cookpot" if route.station_id == "kitchen" else "workbench"
	if not part.is_empty() and part != role: return deny("camp_wrong_part")
	return {"ok":true,"part":role,"station_id":route.station_id,"required_tier":0}

static func source_context(cfg: Dictionary, records: Array, uid: String, actor_at: Vector3,
		realm: String, character: String, revision: int, in_combat: bool, part: String) -> Dictionary:
	var source := record(records,uid)
	if cfg.get("runtime_enabled") != true or source.get("ok") != true or source.record.realm != realm \
			or part not in ["bed","cookpot","workbench"] or character.is_empty() or revision < 0 \
			or not actor_at.is_finite(): return {}
	var p: Array = source.record.position
	var o: Array = cfg[part+"_offset"]
	var origin := Vector3(p[0],p[1],p[2]) + Basis(Vector3.UP,deg_to_rad(source.record.yaw_deg))*Vector3(o[0],o[1]+0.6,o[2])
	return {"character_id":character,"expected_revision":revision,"source_key":source.key,
		"realm":realm,
		"station_kind":ID,"forward_camp":true,"homestead":false,"part":part,
		"station_id":"kitchen" if part == "cookpot" else "workbench",
		"in_range":actor_at.distance_to(origin) <= float(cfg.interaction_radius_m),
		"within_reach":actor_at.distance_to(origin) <= float(cfg.interaction_radius_m),
		"in_combat":in_combat,"effective_tier":0,"camp_index":source.index,"camp_uid":uid}
