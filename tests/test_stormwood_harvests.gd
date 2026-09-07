extends "res://tests/test_case.gd"

## Catalogue-level coverage. Mounting is intentionally tested separately by
## the integration owner because Stormwood items are not in ItemDB yet.

const DATA_PATH := "res://data/config/stormwood_harvests.json"
const WORLD_PATH := "res://data/config/stormwood_world.json"
const TRAINERS_PATH := "res://data/config/stormwood_trainers.json"
const NPCS_PATH := "res://data/config/stormwood_npcs.json"
const SURGE_PATH := "res://data/config/stormwood_surge.json"
const RUNTIME := preload("res://scripts/world/stormwood_harvest_runtime.gd")
const RESOURCES := ["stormglass", "thunderwood", "conductor_vine", "glowmoss", "voltcap"]
const REGIONS := ["cinder_verge", "glowmoss_hollows", "conductor_run", "hollow_crown", "deepwood", "dynamo"]


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _sites() -> Array:
	return _json(DATA_PATH).get("sites", []) as Array


func _regions() -> Dictionary:
	var out := {}
	for raw: Variant in (_json(WORLD_PATH).get("regions", []) as Array):
		var region: Dictionary = raw
		out[str(region.get("id", ""))] = region
	return out


func test_authored_count_distribution_and_stable_ids() -> void:
	var counts := {}
	var ids: Array[String] = []
	for raw: Variant in _sites():
		var site: Dictionary = raw
		var id := str(site.get("id", ""))
		assert_false(id.is_empty(), "a harvest site has no stable id")
		assert_false(ids.has(id), "duplicate harvest id '%s'" % id)
		ids.append(id)
		var region := str(site.get("region_id", ""))
		counts[region] = int(counts.get(region, 0)) + 1
	assert_true(_sites().size() >= 210, "Stormwood §13 requires at least 210 authored harvest nodes")
	for region in REGIONS:
		assert_true(int(counts.get(region, 0)) >= 25, "%s has fewer than 25 harvest sites" % region)


func test_every_site_is_in_its_region_uses_existing_models_and_names_one_resource() -> void:
	var regions := _regions()
	for raw: Variant in _sites():
		var site: Dictionary = raw
		var region: Dictionary = regions.get(str(site.get("region_id", "")), {})
		var bounds: Dictionary = region.get("bounds", {})
		var point: Array = site.get("position", []) as Array
		assert_eq(point.size(), 2, "%s needs realm-local X/Z coordinates" % str(site.get("id", "")))
		if point.size() == 2:
			assert_true(float(point[0]) >= float(bounds.get("min_x", INF)) and float(point[0]) <= float(bounds.get("max_x", -INF)), "%s is outside its region X bounds" % str(site.get("id", "")))
			assert_true(float(point[1]) >= float(bounds.get("min_z", INF)) and float(point[1]) <= float(bounds.get("max_z", -INF)), "%s is outside its region Z bounds" % str(site.get("id", "")))
		var item := str(site.get("item", ""))
		assert_true(RESOURCES.has(item) or item == "stormglass_crown", "%s has an unsupported gathered item" % str(site.get("id", "")))
		assert_true(ResourceLoader.exists(str(site.get("model", ""))), "%s names a missing installed model" % str(site.get("id", "")))
		assert_true(float(site.get("model_scale", 0.0)) > 0.0, "%s has no positive model scale" % str(site.get("id", "")))


func test_charged_stormglass_phase_and_grade_contracts() -> void:
	var charged := 0
	var charged_by_region := {}
	for raw: Variant in _sites():
		var site: Dictionary = raw
		if not bool(site.get("charged", false)):
			continue
		charged += 1
		var region := str(site.get("region_id", ""))
		charged_by_region[region] = int(charged_by_region.get(region, 0)) + 1
		assert_true(["stormglass", "stormglass_crown"].has(str(site.get("item", ""))), "charged site is not stormglass")
		assert_eq(site.get("availability", []), ["break", "fading"], "charged site is available outside Break/Fading")
		if str(site.get("grade", "")) == "crown":
			assert_true(["conductor_run", "hollow_crown"].has(region), "Crown-grade stormglass is outside Capacitor Grove/Crown")
	assert_true(charged >= 24, "Stormwood §13 requires at least 24 charged nodes")
	for region in ["cinder_verge", "glowmoss_hollows", "conductor_run", "hollow_crown", "deepwood", "dynamo"]:
		assert_true(int(charged_by_region.get(region, 0)) >= 3, "%s needs at least three charged nodes" % region)


func test_first_two_region_charged_stormglass_lives_in_safe_marked_clearings() -> void:
	var charged_by_region := {}
	for raw: Variant in _sites():
		var site: Dictionary = raw
		if bool(site.get("charged", false)) and str(site.get("region_id", "")) in ["cinder_verge", "glowmoss_hollows"] \
				and str(site.get("item", "")) == "stormglass":
			var region := str(site.region_id)
			if not charged_by_region.has(region):
				charged_by_region[region] = []
			(charged_by_region[region] as Array).append(site)
	var verge_in_clearings := 0
	for clearing_raw: Variant in (_json(SURGE_PATH).get("marked_clearings", []) as Array):
		var clearing: Dictionary = clearing_raw
		var region := str(clearing.get("region_id", ""))
		if region not in ["cinder_verge", "glowmoss_hollows"]:
			continue
		var at: Array = clearing.get("at", []) as Array
		var nearby := 0
		for raw_site: Variant in (charged_by_region.get(region, []) as Array):
			var point: Array = (raw_site as Dictionary).get("position", []) as Array
			if point.size() == 2 and at.size() == 2 and Vector2(float(point[0]) - float(at[0]), float(point[1]) - float(at[1])).length() <= float(clearing.get("radius", 0.0)):
				nearby += 1
		if region == "cinder_verge":
			verge_in_clearings += nearby
		else:
			assert_true(nearby >= 2, "%s needs at least two charged Stormglass sites" % str(clearing.get("id", "")))
	assert_true(verge_in_clearings >= 4, "Verge needs four charged Stormglass sites across safe marked clearings")


func test_sparkfur_is_not_authored_as_a_harvest_or_hunting_node() -> void:
	assert_eq(str(_json(DATA_PATH).get("excluded_resource", "")), "sparkfur")
	for raw: Variant in _sites():
		assert_ne(str((raw as Dictionary).get("item", "")), "sparkfur")


func test_sites_keep_clear_of_authored_camps_people_and_critical_landmarks() -> void:
	var sensitive: Array = []
	for raw: Variant in (_json(WORLD_PATH).get("landmarks", []) as Array):
		var landmark: Dictionary = raw
		if ["camp", "settlement", "stronghold", "story"].has(str(landmark.get("category", ""))):
			sensitive.append({"id": str(landmark.get("id", "")), "position": landmark.get("position", []), "clearance": 80.0})
	for path in [TRAINERS_PATH, NPCS_PATH]:
		for raw: Variant in (_json(path).get("trainers", _json(path).get("npcs", [])) as Array):
			var person: Dictionary = raw
			sensitive.append({"id": str(person.get("id", "")), "position": person.get("position", []), "clearance": 50.0})
	for raw: Variant in _sites():
		var site: Dictionary = raw
		var point: Array = site.get("position", []) as Array
		if point.size() != 2:
			continue
		for raw_sensitive: Variant in sensitive:
			var anchor: Dictionary = raw_sensitive
			var at: Array = anchor.get("position", []) as Array
			if at.size() != 3:
				continue
			var distance := Vector2(float(point[0]) - float(at[0]), float(point[1]) - float(at[2])).length()
			assert_true(distance >= float(anchor.get("clearance", 0.0)), "%s intrudes on %s" % [str(site.get("id", "")), str(anchor.get("id", ""))])


func test_runtime_records_the_host_authority_contract() -> void:
	var gap := RUNTIME.authority_contract()
	assert_eq(str(gap.get("intent_kind", "")), "stormwood_harvest")
	assert_true(str(gap.get("harvest_override", "")).contains("harvest_node.gd::_on_gathered"))
	assert_true(str(gap.get("ledger_override", "")).contains("world_ledger.gd::_stormwood_harvest"))
