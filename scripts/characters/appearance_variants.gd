extends RefCounted

## P2-055 presentation records. Regional identity mappings are deliberately
## separate; this resolver never changes a model, name, rank, or gameplay fact.
const CONFIG_PATH := "res://data/config/character_appearance_variants.json"
const PORTRAIT_ROOT := "res://assets/ui/portraits/"


static func load_config() -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	return raw if raw is Dictionary else {}


## Always return an independent copy, including disabled/unknown/mismatched
## records. Apply appearance and portrait together, never half a variant.
static func resolve(base: Dictionary, base_profile: String, variant_id: String,
		settings: Dictionary = {}) -> Dictionary:
	var result := base.duplicate(true)
	if base.is_empty() or variant_id.is_empty():
		return result
	var config := load_config() if settings.is_empty() else settings
	if not bool(config.get("enabled", false)):
		return result
	var records: Variant = config.get("variants", {})
	if not records is Dictionary:
		return result
	var raw: Variant = records.get(variant_id, {})
	if not raw is Dictionary:
		return result
	var record: Dictionary = raw
	if base_profile.is_empty() or str(record.get("expected_base_profile", "")) != base_profile:
		return result
	var model := str(base.get("model", ""))
	if model.is_empty() or str(record.get("expected_model", "")) != model:
		return result
	var portrait := str(record.get("portrait", ""))
	# A dedicated flat filename keeps portrait output inside the established
	# directory. Existence is not required: the portrait tool produces this file.
	if not portrait.begins_with(PORTRAIT_ROOT) or portrait.get_extension() != "png" \
			or portrait.get_base_dir() + "/" != PORTRAIT_ROOT \
			or portrait.get_file().get_basename().is_empty():
		return result
	# Distinct records must not silently write and display one shared plate.
	for other_id: Variant in records:
		var other: Variant = records[other_id]
		if str(other_id) != variant_id and other is Dictionary \
				and str(other.get("portrait", "")) == portrait:
			return result
	var overrides := {}
	for key: String in ["body_albedo_override", "body_emission_override"]:
		if record.has(key):
			var path: Variant = record[key]
			if not path is String or not path.begins_with("res://") or path.is_empty():
				return result
			overrides[key] = path
	if overrides.is_empty():
		return result
	for key: String in overrides:
		result[key] = overrides[key]
	result["portrait"] = portrait
	result["appearance_variant_id"] = variant_id
	return result
