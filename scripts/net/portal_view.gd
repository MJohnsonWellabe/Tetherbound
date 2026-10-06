extends RefCounted

## Shared prompt state is derived from the traveler's portable character and
## the current host world. A personal unlock never changes that world's tier.
static func build(player: RefCounted, world: RefCounted, arch: Dictionary) -> Dictionary:
	var biome: String = arch.biome
	var personal: bool = biome == "meadows" or player.redesign_character.portal_unlocks.has(biome)
	var shared: bool = biome == "meadows" or world.redesign_world.portal_unlocks.has(biome)
	var stirred := false
	for row: Variant in player.satchel_escrow.values():
		if preload("res://scripts/net/portal_delivery.gd").valid(row, player.character_id) \
			and row.biome == "biome5" and row.status == "settled": stirred = true
	var label := "biome entry"
	var last: String = str(player.redesign_character.last_waystones.get(biome, ""))
	if biome == "meadows" and not preload("res://scripts/net/portal_action_policy.gd").meadows_waystone_return(
			preload("res://scripts/data/redesign_data.gd").json("res://data/config/portals.json")):
		last = ""
	if not last.is_empty() and player.redesign_character.waystones_activated.get(biome, []).has(last):
		var stone: Dictionary = preload("res://scripts/net/portal_action_policy.gd")._find_stone(
			preload("res://scripts/world/waystone.gd").load_config(), last)
		if stone.get("biome") == biome: label = str(stone.display_name)
	return {"ready": not player.character_id.is_empty(),
		"open": arch.kind == "live" and (personal or shared),
		"character_open": personal, "world_open": shared,
		"has_key": not str(arch.key_item).is_empty() and player.inventory.count(arch.key_item) == 1,
		"character_stirred": stirred, "fifth_arch_stirred": stirred or world.redesign_world.fifth_arch_stirred,
		"destination_label": label, "recommended_level": arch.get("recommended_level", 0)}
