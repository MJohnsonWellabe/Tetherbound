extends RefCounted

## Small, strict JSON Schema reader for the deliberately bounded schemas in
## data/schema. All supported constraints are checked recursively; unsupported
## keywords fail closed instead of treating an unchecked document as valid.
const ROOT := "res://data/schema/"
const DOMAINS: Array[String] = ["essences", "tether_candy", "material_tiers", "stations", "attachments", "gear_tiers", "traits", "masters", "feasts", "evolution_lines", "portals", "keys", "waystones", "level_caps"]
const KEYWORDS: Array[String] = ["$schema", "$id", "description", "type", "properties", "required", "additionalProperties", "items", "minItems", "maxItems", "uniqueItems", "oneOf", "enum", "const", "minimum", "maximum", "minLength"]

static func json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))

static func validate(value: Variant, schema: Dictionary, path: String = "$") -> Array[String]:
	var errors: Array[String] = []
	for key: Variant in schema:
		if not KEYWORDS.has(str(key)):
			errors.append("%s: unsupported schema keyword %s" % [path, key])
	var kind := str(schema.get("type", ""))
	var valid_type := true
	match kind:
		"object": valid_type = value is Dictionary
		"array": valid_type = value is Array
		"string": valid_type = value is String
		"boolean": valid_type = value is bool
		"number": valid_type = (value is int or value is float) and is_finite(float(value))
		"integer": valid_type = (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value))
		"": pass
		_: errors.append("%s: unknown schema type %s" % [path, kind])
	if not valid_type:
		errors.append("%s: expected %s" % [path, kind])
		return errors
	if schema.has("oneOf"):
		var matches := 0
		for branch: Dictionary in schema.oneOf:
			if validate(value, branch, path).is_empty(): matches += 1
		if matches != 1: errors.append("%s: identity must match exactly one authored contract" % path)
	if schema.has("const") and value != schema.const:
		errors.append("%s: expected constant %s" % [path, schema.const])
	if schema.has("enum") and not (schema.enum as Array).has(value):
		errors.append("%s: unknown id/value %s" % [path, value])
	if value is Dictionary:
		var properties: Dictionary = schema.get("properties", {})
		for key: Variant in schema.get("required", []):
			if not value.has(key): errors.append("%s: missing %s" % [path, key])
		for key: Variant in value:
			if properties.has(key):
				errors.append_array(validate(value[key], properties[key], "%s.%s" % [path, key]))
			elif schema.get("additionalProperties", true) is Dictionary:
				errors.append_array(validate(value[key], schema.additionalProperties, "%s.%s" % [path, key]))
			elif schema.get("additionalProperties", true) == false:
				errors.append("%s: unknown field %s" % [path, key])
	if value is Array:
		if bool(schema.get("uniqueItems", false)):
			var seen: Array = []
			for element: Variant in value:
				if seen.has(element): errors.append("%s: duplicate array member" % path)
				seen.append(element)
		if value.size() < int(schema.get("minItems", 0)) or value.size() > int(schema.get("maxItems", 2147483647)):
			errors.append("%s: invalid item count %d" % [path, value.size()])
		if schema.has("items"):
			for i: int in value.size():
				errors.append_array(validate(value[i], schema.items, "%s[%d]" % [path, i]))
	if value is String and value.length() < int(schema.get("minLength", 0)):
		errors.append("%s: missing/empty id" % path)
	if value is int or value is float:
		if float(value) < float(schema.get("minimum", -INF)) or float(value) > float(schema.get("maximum", INF)):
			errors.append("%s: number outside allowed range" % path)
	return errors

static func load_catalog(domain: String, path: String = "") -> Dictionary:
	if not DOMAINS.has(domain):
		return _failure(["unknown schema domain %s" % domain])
	var schema: Variant = json(ROOT + domain + ".schema.json")
	var source := path if not path.is_empty() else ROOT + domain + ".json"
	var value: Variant = json(source)
	if not schema is Dictionary:
		return _failure(["missing schema %s" % domain])
	var errors := validate(value, schema)
	if not errors.is_empty(): return _failure(errors)
	errors.append_array(_relations(domain, value))
	if value is Array:
		var seen: Dictionary = {}
		for row: Variant in value:
			if not row is Dictionary: continue
			var id := str(row.get("id", ""))
			if seen.has(id): errors.append("duplicate id %s" % id)
			seen[id] = true
			if domain in ["material_tiers", "gear_tiers", "portals", "waystones", "attachments"]:
				var live := preload("res://scripts/data/biome_order.gd").ids(false).has(str(row.get("biome", "")))
				if str(row.get("status", "")) != ("live" if live else "reserved"):
					errors.append("%s has incorrect biome reservation" % id)
	if not errors.is_empty(): return _failure(errors)
	return {"ok": true, "data": value, "errors": []}


## A schema's strings describe shape; this manifest check resolves identities
## and foreign keys. Later lanes extend the catalog explicitly when authoring
## their runtime content. Reserved rows do not authorize runtime availability.
static func _relations(domain: String, value: Variant) -> Array[String]:
	var errors: Array[String] = []
	var manifest: Variant = json(ROOT + domain + ".json")
	if not value is Array or not manifest is Array: return errors
	var known: Dictionary = {}
	for row: Dictionary in manifest: known[str(row.id)] = row
	var biome_ids := preload("res://scripts/data/biome_order.gd").ids()
	var identity_keys: Array[String] = ["type", "tier", "biome", "status", "station_id", "attachment_slots", "level", "cap_level", "breaks_level", "source", "target", "extra_ingredient", "key_id", "entry_id", "kind", "effect"]
	for row: Variant in value:
		if not row is Dictionary: continue
		var id := str(row.get("id", ""))
		if not known.has(id):
			errors.append("unknown %s id %s" % [domain, id])
			continue
		var expected: Dictionary = known[id]
		for key: String in identity_keys:
			if expected.has(key) and row.get(key) != expected[key]:
				errors.append("%s: unknown or inconsistent %s" % [id, key])
		if domain in ["material_tiers", "gear_tiers"]:
			var tier := int(row.get("tier", 0))
			if tier < 1 or tier > biome_ids.size() or str(row.get("biome", "")) != biome_ids[tier - 1]:
				errors.append("%s: tier/biome does not match biome order" % id)
			if id != ("tier_%d" if domain == "material_tiers" else "gear_tier_%d") % tier:
				errors.append("%s: tier id mismatch" % id)
		if domain == "level_caps" and id != "cap_%d" % int(row.get("level", 0)):
			errors.append("%s: cap id mismatch" % id)
		if domain == "attachments" and id != "%s_%s" % [row.get("station_id", ""), row.get("biome", "")]:
			errors.append("%s: attachment identity mismatch" % id)
		if domain in ["portals", "waystones"]:
			var biome := str(row.get("biome", ""))
			if str(row.get("entry_id", "")) != biome + "_entry": errors.append("%s: entry biome mismatch" % id)
			if domain == "portals" and (id != "portal_" + biome or str(row.get("key_id", "")) != "portal_key_" + biome):
				errors.append("%s: portal/key biome mismatch" % id)
			if domain == "waystones" and id != biome + "_entry": errors.append("%s: waystone biome mismatch" % id)
		if domain in ["masters", "feasts"]:
			var tier := int(row.get("tier", 0))
			var cap_key := "cap_level" if domain == "masters" else "breaks_level"
			if int(row.get(cap_key, 0)) != tier * 10: errors.append("%s: tier/cap mismatch" % id)
			if domain == "masters" and str(row.get("feast_id", "")) != "feast_t%d" % tier: errors.append("%s: feast tier mismatch" % id)
		if domain == "material_tiers":
			var items: Dictionary = json("res://data/items/items.json").get("items", {})
			var proposals: Dictionary = json("res://data/config/water_crafting.json").get("item_registration_proposals", {})
			var proposal_ids: Array = proposals.keys() if proposals is Dictionary else []
			# Only named RD-33 additions are accepted before F32 registers items.
			var planned: Array[String] = ["driftwood", "reed_fiber", "reef_stone", "sluice_metal", "tide_bloom", "tide_pearl", "rootiron_ingot", "tidesteel_ingot", "skyglass_ingot", "stormglass_plate"]
			for raw: Variant in row.get("raws", []):
				if not items.has(str(raw)) and not planned.has(str(raw)) and not proposal_ids.has(str(raw)):
					errors.append("%s: material absent from runtime or approved future registry" % raw)
			var refined := str(row.get("refined", ""))
			if not refined.is_empty() and not items.has(refined) and not planned.has(refined): errors.append("%s: unknown refined material" % id)
			if row.get("raws") != expected.get("raws") or row.get("refined") != expected.get("refined"):
				errors.append("%s: unknown material foreign id" % id)
		for field: String in ["slots", "attuned_types"]:
			if expected.has(field) and row.get(field) != expected[field]:
				errors.append("%s: incomplete or duplicate %s" % [id, field])
		if domain == "gear_tiers":
			if row.get("slots") != ["harness", "charm"]: errors.append("%s: Harness and Charm required once each" % id)
		if domain == "feasts":
			var type_ids: Array = ["ground", "water", "air", "electric", "fire", "dark", "ice", "psychic"]
			var supplied: Variant = row.get("attuned_types", [])
			if not supplied is Array or supplied.size() != type_ids.size(): errors.append("%s: eight distinct types required" % id)
			else:
				for type_id: String in type_ids:
					if supplied.count(type_id) != 1: errors.append("%s: missing/duplicate attuned type %s" % [id, type_id])
		if domain == "evolution_lines":
			if id != "%s_%s" % [row.get("source", ""), row.get("target", "")]: errors.append("%s: evolution identity mismatch" % id)
			var species: Dictionary = json("res://data/creatures/species.json").get("species", {})
			if not species.has(str(row.get("source", ""))): errors.append("%s: unknown source species" % id)
			var target := str(row.get("target", ""))
			if not species.has(target) and not (target == "stormursa" and row.get("enabled") == false):
				errors.append("%s: unknown or unavailable evolution target" % id)
			var extra := str(row.get("extra_ingredient", ""))
			var items: Dictionary = json("res://data/items/items.json").get("items", {})
			if not extra.is_empty() and not items.has(extra): errors.append("%s: unknown ingredient" % id)
	# Every fixed slot must appear once. Traits/evolution definitions are a finite
	# manifest too; a missing id is an authoring error, not an empty gameplay row.
	var found: Array[String] = []
	for row: Variant in value:
		if row is Dictionary: found.append(str(row.get("id", "")))
	for id: Variant in known:
		if not found.has(str(id)): errors.append("missing %s id %s" % [domain, id])
	return errors

## Lookups are typed refusals, never an empty row mistaken for a free recipe.
static func lookup(domain: String, id: String, source_path: String = "") -> Dictionary:
	var catalog := load_catalog(domain, source_path)
	if not catalog.ok: return catalog
	var value: Variant = catalog.data
	if value is Array:
		for row: Dictionary in value:
			if str(row.get("id", "")) == id:
				return {"ok": true, "data": row.duplicate(true), "errors": []}
	elif value is Dictionary and str(value.get("id", "")) == id:
		return {"ok": true, "data": value.duplicate(true), "errors": []}
	return _failure(["unknown %s id %s" % [domain, id]])

static func _failure(errors: Array) -> Dictionary:
	push_error("Redesign data refused: %s" % "; ".join(errors))
	return {"ok": false, "code": "invalid_data", "errors": errors}
