extends RefCounted

## F31#3 presentation projection only, currently uncalled. Reads the existing
## F16 catalog and HOST world/current-character snapshots. This does not
## authenticate a body, authorize a blueprint, install an attachment or write
## progression. Canonical placement must revalidate all of those separately.
## blueprint is the owning service's actual catalog row, never a client cost.
## An absent/unregistered row cannot display its requirements as satisfied.

const DATA := preload("res://scripts/data/redesign_data.gd")


static func describe(station_id: String, host_world: Dictionary,
		host_character: Dictionary, blueprint: Dictionary = {}) -> Dictionary:
	var station := DATA.lookup("stations", station_id)
	if not bool(station.get("ok", false)):
		return _unavailable()
	var slots: int = int(station["data"]["attachment_slots"])
	if slots == 0:
		# Workbench/Farm unlocks have their own kit/Greenhouse work orders.
		# Do not invent an attachment track for these stations.
		return {"ok": true, "visible": false, "requirements_satisfied": false}
	var redesign: Variant = host_world.get("redesign_world")
	var personal: Variant = host_character.get("redesign_character")
	if not _identity(host_world.get("world_id")) or not _identity(host_character.get("character_id")) \
			or not redesign is Dictionary or not redesign.get("station_tiers") is Dictionary \
			or not personal is Dictionary or not _ids(personal.get("attachment_recipes")):
		return _unavailable()
	var tier: Variant = redesign["station_tiers"].get(station_id, 0)
	if not _integer(tier, 0) or int(tier) > slots:
		return _unavailable()
	if int(tier) == slots:
		return {"ok": true, "visible": false, "requirements_satisfied": false}
	var catalog := DATA.load_catalog("attachments")
	if not bool(catalog.get("ok", false)):
		return _unavailable()
	var target := {}
	for row: Dictionary in catalog["data"]:
		if row["station_id"] == station_id and int(row["tier"]) == int(tier) + 1:
			if not target.is_empty():
				return _unavailable()
			target = row.duplicate(true)
	if target.is_empty():
		return _unavailable()
	# Exactly one authored adjacent target; never expose the whole tier tree.
	var view := {"ok": true, "visible": true, "station_id": station_id,
		"attachment_id": target["id"], "name": target["display_name"], "tier": target["tier"],
		"requirements_satisfied": false, "missing_requirement": "", "unlocks": ""}
	if target["status"] == "reserved":
		view["missing_requirement"] = "Reserved for a future biome."
		return view
	var blueprint_available := _blueprint_matches(blueprint, target)
	if blueprint_available:
		view["unlocks"] = blueprint["unlocks"]
	# Own host tier is a read context, never a recipe grant to this guest.
	# Meadows is available from the start by RD-20; later recipes are personal.
	if int(target["tier"]) > 1 and not (personal["attachment_recipes"] as Array).has(target["id"]):
		view["missing_requirement"] = "Hang the previous biome's relic in the Shrine Room."
		return view
	if not blueprint_available:
		view["missing_requirement"] = "This attachment blueprint is not available yet."
		return view
	var counts := _inventory_counts(host_character.get("inventory"))
	if not bool(counts.get("ok", false)):
		view["missing_requirement"] = "The character's material counts are unavailable."
		return view
	# The canonical authored cost order determines the ONE missing requirement.
	# Counts sum the actual saved stacks; null slots are ordinary empty slots.
	for need: Dictionary in blueprint["cost"]:
		var missing := int(need["n"]) - int(counts["items"].get(need["id"], 0))
		if missing > 0:
			view["missing_requirement"] = "Needs %d %s: %s" % [missing, need["name"], need["source_hint"]]
			return view
	view["requirements_satisfied"] = true
	return view # Presentation only: not placement authorization or paid success.


static func _blueprint_matches(blueprint: Dictionary, target: Dictionary) -> bool:
	if blueprint.get("id") != target["id"] or blueprint.get("station_id") != target["station_id"] \
			or not _integer(blueprint.get("tier"), 1) or int(blueprint["tier"]) != int(target["tier"]) \
			or typeof(blueprint.get("registered")) != TYPE_BOOL or blueprint["registered"] != true \
			or not _identity(blueprint.get("unlocks")) or not blueprint.get("cost") is Array \
			or (blueprint["cost"] as Array).is_empty():
		return false
	var seen := {}
	for need: Variant in blueprint["cost"]:
		if not need is Dictionary or not _identity(need.get("id")) or seen.has(need["id"]) \
				or not _integer(need.get("n"), 1) or not _identity(need.get("name")) \
				or not _identity(need.get("source_hint")):
			return false
		seen[need["id"]] = true
	return true


static func _inventory_counts(inventory: Variant) -> Dictionary:
	if not inventory is Array:
		return {"ok": false}
	var items := {}
	for row: Variant in inventory:
		if row == null:
			continue
		if not row is Dictionary or not _identity(row.get("id")) or not _integer(row.get("n"), 1):
			return {"ok": false}
		var id: String = row["id"]
		# Refuse overflow rather than wrapping a huge material total into ready.
		var previous: int = int(items.get(id, 0))
		var added: int = int(row["n"])
		if previous > 9223372036854775807 - added:
			return {"ok": false}
		items[id] = previous + added
	return {"ok": true, "items": items}


static func _ids(value: Variant) -> bool:
	if not value is Array:
		return false
	var seen := {}
	for id: Variant in value:
		if not _identity(id) or seen.has(id):
			return false
		seen[id] = true
	return true


static func _identity(value: Variant) -> bool:
	return value is String and not value.strip_edges().is_empty()


static func _integer(value: Variant, minimum: int) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) \
		and float(value) == float(int(value)) and int(value) >= minimum


static func _unavailable() -> Dictionary:
	return {"ok": false, "visible": false, "requirements_satisfied": false}
