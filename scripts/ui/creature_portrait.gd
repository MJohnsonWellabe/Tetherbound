extends RefCounted
## Dedicated portraits win. Water's temporary portraits follow its explicit
## installed body source until a species-specific portrait lands.
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const DIRECTORY := "res://assets/ui/portraits/creatures/"

static func resolve(species_id: String) -> String:
	if species_id.is_empty():
		return ""
	var dedicated := DIRECTORY + species_id + ".png"
	if ResourceLoader.exists(dedicated):
		return dedicated
	var definition := SPECIES.definition(species_id)
	var base := str(definition.get("variant_of", ""))
	if base.is_empty():
		base = str(definition.get("water_placeholder", {}).get("source_species", ""))
	return DIRECTORY + base + ".png" if not base.is_empty() else dedicated
