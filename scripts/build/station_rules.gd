extends RefCounted

## Pure F31 policy over canonical placed_buildings. No node registry, grants,
## world writes or receipts. Foundation calls this again inside its paid stage.
const DATA := preload("res://scripts/data/redesign_data.gd")
const PLOT := preload("res://scripts/build/home_plot_rules.gd")
const CONFIG := "res://data/config/stations.json"
const STATION_IDS := ["workbench","forge","kitchen","altar","den","farm"]
const UPGRADE_STATIONS := ["forge","kitchen","altar","den"]
const BIOME_IDS := ["meadows","tidewake","cloudreach","stormwood","biome5","biome6","biome7","biome8"]
static var _cached: Dictionary = {}
static var _loaded := false

static func config() -> Dictionary:
	if not _loaded:
		_loaded = true
		_cached = _load_config()
	return _cached.duplicate(true)

static func _load_config() -> Dictionary:
	var raw: Variant = DATA.json(CONFIG)
	if not raw is Dictionary: return {}
	var schema: Variant = DATA.json("res://data/schema/stations.schema.json")
	var catalog := DATA.load_catalog("stations")
	if not schema is Dictionary or catalog.get("ok") != true \
			or not PLOT.config_valid(raw, schema, catalog.data): return {}
	for key: String in ["runtime_enabled", "craft_runtime_enabled", "farm_runtime_enabled", "den_runtime_enabled"]:
		if not raw.get(key) is bool: return {}
	for key: String in ["maximum_place_distance_m", "maximum_slope_rise_m", "ground_tolerance_m", "placement_clearance_m", "attachment_spacing_m", "attachment_snap_tolerance_m", "attachment_maximum_height_difference_m", "interaction_radius_m"]:
		if not number(raw.get(key)) or float(raw[key]) <= 0.0: return {}
	for key: String in ["forge","den","greenhouse"]:
		if not raw.get(key) is Dictionary or not raw[key].get("runtime_enabled") is bool: return {}
	if not number(raw.forge.get("maximum_manual_units")) or raw.forge.maximum_manual_units < 1 \
			or float(raw.forge.maximum_manual_units) != floor(float(raw.forge.maximum_manual_units)): return {}
	if not number(raw.den.get("comfort_bonus_per_tier")) or raw.den.comfort_bonus_per_tier < 0: return {}
	if not raw.get("pieces") is Dictionary or not raw.get("attachments") is Array: return {}
	for station: Dictionary in raw.stations:
		if not raw.pieces.get(station.id) is Dictionary \
				or not PLOT.numbers(raw.pieces[station.id].get("size_m"), 3) \
				or not PLOT.numbers(raw.pieces[station.id].get("prompt_offset"), 3): return {}
		for n: Variant in raw.pieces[station.id].size_m:
			if float(n) <= 0.0: return {}
	var attachments := DATA.load_catalog("attachments")
	if attachments.get("ok") != true or raw.attachments.size() != attachments.data.size(): return {}
	for i: int in raw.attachments.size():
		var row: Variant = raw.attachments[i]
		if not row is Dictionary: return {}
		for key: String in ["id", "station_id", "biome", "tier", "status", "display_name"]:
			if row.get(key) != attachments.data[i][key]: return {}
		if not row.get("registered") is bool or row.registered != (row.status == "live") or not PLOT.numbers(row.get("size_m"), 3): return {}
		for n: Variant in row.size_m:
			if float(n) <= 0.0: return {}
		if row.status == "live" and not valid_cost(row.get("cost")): return {}
	return raw

static func number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func valid_cost(value: Variant) -> bool:
	if not value is Array or value.is_empty(): return false
	var seen := {}
	for row: Variant in value:
		if not row is Dictionary or not row.get("id") is String or row.id.is_empty() \
				or seen.has(row.id) or not number(row.get("n")) \
				or float(row.n) != floor(float(row.n)) or row.n <= 0: return false
		seen[row.id] = true
	return true

static func attachment(cfg: Dictionary, id: String) -> Dictionary:
	for row: Dictionary in cfg.get("attachments", []):
		if row.id == id: return row.duplicate(true)
	return {}

static func station(cfg: Dictionary, id: String) -> bool:
	for row: Dictionary in cfg.get("stations", []):
		if row.id == id: return true
	return false

static func managed(cfg: Dictionary, id: String) -> bool:
	return station(cfg, id) or not attachment(cfg, id).is_empty() or cfg.get("auxiliary_buildables",[]).has(id)

static func homestead_id(id: String) -> bool:
	# Identity survives invalid/missing config, so new IDs never fall through
	# to the legacy free/local building debit path.
	if STATION_IDS.has(id) or id == "greenhouse": return true
	for station_id: String in UPGRADE_STATIONS:
		for biome: String in BIOME_IDS:
			if id == station_id+"_"+biome: return true
	return false

## ItemDB's canonical loader uses this projection. The JSON `buildables`
## array remains the complete legacy catalogue, including its Workbench.
## No proposed typed cost or procedural piece enters that active catalogue
## until the exact runtime switch is enabled; the overlay never edits input.
static func active_catalogue(catalogue: Dictionary, cfg: Dictionary) -> Array:
	var raw: Variant = catalogue.get("buildables",[])
	var legacy: Array = raw.duplicate(true) if raw is Array else []
	var enabled: Variant = cfg.get("runtime_enabled")
	if not enabled is bool or enabled != true: return legacy
	var typed: Variant = catalogue.get("homestead_buildables")
	if not typed is Array: return legacy
	var result := legacy.duplicate(true)
	var seen := {}
	for row: Variant in typed:
		if not row is Dictionary or not row.get("id") is String or seen.has(row.id) \
				or not homestead_id(row.id) or not valid_cost(row.get("cost")): return legacy
		var id: String = row.id
		var attached := attachment(cfg,id)
		if not station(cfg,id) and not cfg.get("auxiliary_buildables",[]).has(id) \
				and attached.get("status") != "live": return legacy
		seen[id]=true
		var replace_at := -1
		for index: int in result.size():
			if result[index] is Dictionary and result[index].get("id") == id:
				replace_at=index
				break
		if replace_at >= 0: result[replace_at]=row.duplicate(true)
		else: result.append(row.duplicate(true))
	return result

static func bounds_config(cfg: Dictionary, id: String) -> Dictionary:
	var def: Dictionary = cfg.pieces.get(id, attachment(cfg, id))
	if not PLOT.numbers(def.get("size_m"), 3): return {}
	var size: Array = def.size_m
	var out := cfg.duplicate(true)
	out.altar.model_min = [-float(size[0])*0.5, 0.0, -float(size[2])*0.5]
	out.altar.model_max = [float(size[0])*0.5, float(size[1]), float(size[2])*0.5]
	out.altar.placement_clearance_m = cfg.placement_clearance_m
	return out

static func pose(cfg: Dictionary, id: String, realm: String, at: Vector3, yaw: float) -> Dictionary:
	if cfg.is_empty(): return deny("station_data_invalid")
	var bounds := bounds_config(cfg, id)
	if bounds.is_empty(): return deny("station_data_invalid")
	return PLOT.placement(bounds, realm, at, yaw)

static func record(cfg: Dictionary, records: Array, uid: String) -> Dictionary:
	if cfg.is_empty(): return deny("station_data_invalid")
	if not uid.begins_with("b") or not uid.substr(1).is_valid_int() \
			or int(uid.substr(1)) <= 0 or str(int(uid.substr(1))) != uid.substr(1): return deny("station_uid_invalid")
	var found := -1
	for i: int in records.size():
		if records[i] is Dictionary and records[i].get("uid") == uid:
			if found >= 0: return deny("station_uid_duplicate")
			found = i
	if found < 0: return deny("station_gone")
	var row: Dictionary = records[found]
	var def := attachment(cfg,str(row.get("id","")))
	if not def.is_empty() and (def.get("status") != "live" or def.get("registered") != true): return deny("attachment_reserved")
	if not managed(cfg, str(row.get("id", ""))) or row.get("paid") != true \
			or not row.get("paid") is bool or row.get("removed", false) != false \
			or not row.get("removed", false) is bool or not PLOT.numbers(row.get("position"), 3) \
			or not number(row.get("yaw_deg")): return deny("station_record_invalid")
	var p: Array = row.position
	var legal := pose(cfg, row.id, str(row.get("realm", "")), Vector3(p[0], p[1], p[2]), row.yaw_deg)
	if legal.get("ok") != true: return legal
	return {"ok": true, "record": row.duplicate(true), "index": found,
		"key": "%s:meadows:%s" % [row.id, uid]}

static func socket(cfg: Dictionary, parent: Dictionary, tier: int) -> Vector3:
	var size: Array = cfg.pieces[parent.id].size_m
	var x := float(size[0])*0.5 + float(cfg.attachment_spacing_m)
	var z := float(size[2])*0.5 + float(cfg.attachment_spacing_m)
	var points: Array[Vector3] = [Vector3(-x,0,0), Vector3(0,0,z), Vector3(x,0,0), Vector3(0,0,-z),
		Vector3(-x,0,z), Vector3(x,0,z), Vector3(x,0,-z), Vector3(-x,0,-z)]
	var p: Array = parent.position
	return Vector3(p[0],p[1],p[2]) + Basis(Vector3.UP, deg_to_rad(float(parent.yaw_deg))) * points[tier-1]

## Tier is derived per actual station UID; no global character or host tier
## supplies geometry. A later attachment never substitutes for an earlier one.
static func effective_tier(cfg: Dictionary, records: Array, uid: String) -> Dictionary:
	var parent := record(cfg, records, uid)
	if parent.get("ok") != true or not station(cfg, str(parent.get("record", {}).get("id", ""))): return deny("station_gone")
	var slots := {}
	for raw: Variant in records:
		if not raw is Dictionary or raw.get("parent_uid") != uid or raw.get("removed", false) == true: continue
		var def := attachment(cfg, str(raw.get("id", "")))
		if def.is_empty() or def.station_id != parent.record.id or def.status != "live" \
				or slots.has(int(def.tier)): return deny("attachment_record_invalid")
		var checked := record(cfg, records, str(raw.get("uid", "")))
		if checked.get("ok") != true or raw.get("slot") != def.tier: return deny("attachment_record_invalid")
		var p: Array = raw.position
		var expected := socket(cfg, parent.record, int(def.tier))
		if Vector2(p[0],p[2]).distance_to(Vector2(expected.x,expected.z)) > float(cfg.attachment_snap_tolerance_m) \
				or absf(float(p[1])-expected.y) > float(cfg.attachment_maximum_height_difference_m) \
				or absf(wrapf(float(raw.yaw_deg)-float(parent.record.yaw_deg),-180,180)) > 0.01: return deny("attachment_pose_invalid")
		slots[int(def.tier)] = true
	var tier := 0
	for i: int in range(1, 9):
		if slots.has(i) and i != tier+1: return deny("attachment_tier_gap")
		if slots.has(i): tier = i
	return {"ok": true, "effective_tier": tier, "slots": slots}

static func placement(cfg: Dictionary, records: Array, id: String, realm: String,
		at: Vector3, yaw: float, personal: Dictionary, parent_uid: String = "") -> Dictionary:
	if cfg.get("runtime_enabled") != true: return deny("station_disabled")
	var legal := pose(cfg,id,realm,at,yaw)
	if legal.get("ok") != true: return legal
	if id == "greenhouse":
		for raw: Variant in records:
			if raw is Dictionary and raw.get("id") == id and raw.get("removed",false) == false: return deny("greenhouse_already_built")
		if not parent_uid.is_empty(): return deny("attachment_parent_invalid")
		return {"ok":true,"parent_uid":"","slot":0}
	var def := attachment(cfg,id)
	if def.is_empty():
		if not parent_uid.is_empty(): return deny("attachment_parent_invalid")
		return {"ok": true, "parent_uid": "", "slot": 0}
	if def.status != "live": return deny("attachment_reserved")
	if def.tier > 1 and not personal.get("attachment_recipes", []).has(id): return deny("attachment_recipe_unknown")
	var parent := record(cfg,records,parent_uid)
	if parent.get("ok") != true or parent.record.id != def.station_id: return deny("attachment_parent_invalid")
	var tier := effective_tier(cfg,records,parent_uid)
	if tier.get("ok") != true: return tier
	if tier.slots.has(int(def.tier)): return deny("attachment_slot_occupied")
	if int(def.tier) != int(tier.effective_tier)+1: return deny("attachment_previous_tier")
	var expected := socket(cfg,parent.record,int(def.tier))
	if Vector2(at.x,at.z).distance_to(Vector2(expected.x,expected.z)) > float(cfg.attachment_snap_tolerance_m) \
			or absf(at.y-expected.y) > float(cfg.attachment_maximum_height_difference_m) \
			or absf(wrapf(yaw-float(parent.record.yaw_deg),-180,180)) > 0.01: return deny("attachment_snap_required")
	return {"ok": true,"parent_uid":parent_uid,"slot":int(def.tier)}

static func dismantle(cfg: Dictionary, records: Array, uid: String) -> Dictionary:
	var target := record(cfg,records,uid)
	if target.get("ok") != true: return target
	var def := attachment(cfg,target.record.id)
	for raw: Variant in records:
		if not raw is Dictionary or raw.get("removed",false) == true: continue
		if raw.get("parent_uid") == uid: return deny("remove_attachments_first")
		if not def.is_empty() and raw.get("parent_uid") == target.record.get("parent_uid") \
				and int(raw.get("slot",0)) > int(def.tier): return deny("remove_later_attachment_first")
	return target # Foundation validates full refund room and paid provenance.

## Foundation supplies the complete HOST admitted party projection while its
## existing mutation fence is held. UI may not certify a guest's resting state.
static func validate_resting_owners(target: Dictionary, parties: Array,
		complete_host_projection: bool) -> Dictionary:
	if target.get("ok") != true: return target
	if target.record.id != "den": return target
	if not complete_host_projection: return deny("den_owners_unavailable")
	for party: Variant in parties:
		if not party is Array or party.size() > 5: return deny("den_owners_unavailable")
		for row: Variant in party:
			if not row is Dictionary or not row.get("resting") is bool: return deny("den_owners_unavailable")
			if row.resting and row.get("rest_bed_index") == target.index: return deny("wake_companions_before_dismantle")
	return target

static func recipe_route(cfg: Dictionary, id: String, recipe: Dictionary) -> Dictionary:
	if recipe.has("feast_id") or id.begins_with("ascension_") or id.begins_with("feast_"): return deny("use_ascension_feast_consumer")
	var station_id := str(recipe.get("station_id", ""))
	var routed: Dictionary = cfg.recipe_routes.get("recipes",{}).get(id,{})
	if station_id.is_empty() and not routed.is_empty(): station_id=str(routed.station_id)
	if station_id.is_empty():
		station_id = str(cfg.recipe_routes.default_station)
		var output: String = str(recipe.get("output",{}).get("id",""))
		if cfg.recipe_routes.kitchen_outputs.has(output): station_id = "kitchen"
		for prefix: String in cfg.recipe_routes.forge_recipe_prefixes:
			if id.begins_with(prefix): station_id = "forge"
	if not station(cfg,station_id): return deny("recipe_station_invalid")
	var tier: Variant = recipe.get("station_tier", routed.get("tier",cfg.recipe_routes.minimum_tier_by_station.get(station_id,0)))
	if not number(tier) or float(tier) != floor(float(tier)) or tier < 0 or tier > 4: return deny("recipe_tier_invalid")
	return {"ok":true,"station_id":station_id,"required_tier":int(tier)}

static func deny(code: String) -> Dictionary:
	return {"ok":false,"code":code,"reason":reason(code)}

static func reason(code: String) -> String:
	return {"station_home_only":"Build this at Grandpa's homestead, clear of the house, road and crop beds.",
		"station_disabled":"Homestead stations are awaiting integration.",
		"station_host_only":"Only the host can build homestead stations in a shared world for now.",
		"station_materials":"You need the listed materials to build this.","attachment_recipe_unknown":"Hang the previous biome's relic in the Shrine Room.",
		"attachment_slot_occupied":"That biome's attachment is already built.","attachment_previous_tier":"Build the previous attachment first.",
		"attachment_snap_required":"Place the attachment at its station's marked socket.","attachment_reserved":"This biome is reserved for later.",
		"remove_attachments_first":"Dismantle this station's attachments first.","remove_later_attachment_first":"Dismantle the later attachment first.",
		"wake_companions_before_dismantle":"Wake every companion resting here before dismantling the Den.",
		"den_owners_unavailable":"The host cannot confirm that every companion has left this Den."}.get(code,"The station is unavailable; return to the homestead and try again.")
