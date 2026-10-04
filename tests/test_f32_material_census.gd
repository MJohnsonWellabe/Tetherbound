extends "res://tests/test_case.gd"

## F32#0 registry census (the engine walk-and-gather proof is
## tests/smoke_f32_material_sites.gd --ordinary per realm). Every raw of each
## live tier is either a registered renewable site in its own biome or a shed
## item that biome's wild species drop.
const SITES := preload("res://scripts/world/renewable_site_catalog.gd")
const SHED := preload("res://scripts/world/shed_drop_rules.gd")
const REALM := {"meadows": "meadows", "tidewake": "water", "cloudreach": "cloudreach", "stormwood": "stormwood"}

func test_every_live_tier_raw_is_gatherable_in_its_biome() -> void:
	assert_eq(SITES.validation_errors(), {}, "canonical registry valid with every enabled block")
	var tiers: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/schema/material_tiers.json"))
	var shed := SHED.read()
	var live := 0
	for tier: Dictionary in tiers:
		if tier.status != "live": continue
		live += 1
		var realm: String = REALM[tier.biome]
		var site_items := {}
		for site: Dictionary in SITES.sites_for(realm):
			for item: String in site.outputs: site_items[item] = true
		var shed_items := {}
		for species: String in shed.species:
			if (shed.species[species].wild_realms as Array).has(realm): shed_items[shed.species[species].item] = true
		for raw: String in tier.raws:
			assert_true(site_items.has(raw) or shed_items.has(raw), "%s raw %s has a %s site or shed source" % [tier.id, raw, realm])
	assert_eq(live, 4, "four live tiers")

func test_meadows_sunleaf_and_tidewake_pearl_candidates_are_live() -> void:
	assert_eq(SITES.additional_materials_for("meadows").size(), 3)
	assert_eq(SITES.additional_materials_for("water").size(), 3)
	for site: Dictionary in SITES.additional_materials_for("water"):
		assert_eq(site.outputs, {"tide_pearl": 2})
