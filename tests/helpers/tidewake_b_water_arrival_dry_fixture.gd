extends RefCounted

## DRY RUN — does not count. A declared Water-arrival start for
## tests/smoke_four_biome_continuous.gd `--dry-run-water-fixture`, used only
## until a recorded fixture-free run exports an earned `water_arrived`
## checkpoint (then: `--resume-from=<name>:water_arrived`).
##
## Mirrors what the earned Stormwood -> Waterward handoff leaves behind and
## the Water opening checks (realm_gate_water_unlocked set, realm_key_water
## consumed, stormwood:waterward_revealed), in the same disclosed in-memory
## chapter-entry style as tests/smoke_stormwood_continuous.gd: completed
## Stormwood world facts through the production ledger, five carried
## creatures at the Tidewake entry band (one duplicate species so the earned
## swimmer preparation's farewell policy has a candidate, as in the earned
## run), carried knife/axe/pickaxe on the hotbar, then the production router
## `enter_realm("water", "water_arrival_from_stormwood")`. Everything after
## this point is the unchanged earned Water stage.
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const ENTRY_LEVEL := 55
const ENTRY_PARTY: Array[String] = ["terrapup", "bramblebun", "mudsnout", "sparkit", "sparkit"]
const COMPLETED_STORMWOOD_FLAGS: Array[String] = ["stormwood:marrow_defeated", "stormwood:legendary_freed",
	"realm_heart_stormwood_earned", "stormwood:long_storm_ended", "stormwood:legendary_offer_made",
	"stormwood:waterward_revealed", "waterward_route_revealed", "stormwood:chapter_complete",
	"realm_gate_water_unlocked"]


## Returns {world, game, player, rig} once the Water arrival is ready, or {}.
func start(tree: SceneTree, game: Node) -> Dictionary:
	await tree.process_frame
	game.call("reset_for_new_game")
	game.get("local").set("character_id", "f13-3-dry-run")
	game.get("world").set("world_id", "f13-3-dry-run-world")
	for flag: String in COMPLETED_STORMWOOD_FLAGS:
		var verdict: Dictionary = game.get("ledger").call("submit", {
			"kind": "set_world_flag", "realm": "stormwood", "id": flag, "value": true})
		if not bool(verdict.get("ok", false)):
			print("DRY RUN fixture: ledger refused %s (%s); set directly" % [flag, verdict])
			game.world.flags.set_flag(flag)
	game.local.flags.set_flag("stormwood:legendary_ceremony_settled")
	for species_id: String in ENTRY_PARTY:
		var creature: RefCounted = SPECIES.spawn(species_id)
		creature.call("set_level", ENTRY_LEVEL, PROGRESSION.config())
		game.get("party").call("add", creature)
	for item_id: String in ["knife", "axe", "pickaxe"]:
		game.get("inventory").call("add", item_id, 1)
	game.call("assign_hotbar", 0, "knife")
	game.call("assign_hotbar", 1, "axe")
	game.call("assign_hotbar", 2, "pickaxe")
	var source := Node3D.new()
	source.name = "WaterDryRunEntrySource"
	tree.root.add_child(source)
	tree.current_scene = source
	await tree.process_frame
	# realm_key_water is already consumed by the gate in the earned handoff
	# (the opening refuses a held key), so the declared start bypasses the key
	# check the physical gate already passed.
	if not await game.call("enter_realm", "water", "water_arrival_from_stormwood", true):
		print("DRY RUN fixture: production router refused the Water entry")
		return {}
	var world: Node3D = null
	for _frame in 7200:
		await tree.process_frame
		var scene := tree.current_scene
		if scene != null and scene != source and is_instance_valid(scene) \
				and scene.get_node_or_null("Player") != null \
				and str(game.get("pending_realm_entry")).is_empty() \
				and scene.has_method("shell_build_complete") and bool(scene.call("shell_build_complete")):
			world = scene
			break
	if world == null:
		return {}
	for _frame in 300:
		await tree.physics_frame
	print("DRY RUN fixture ready: realm=%s player=%s party=%d" % [game.get("current_realm"),
		(world.get_node("Player") as Node3D).global_position, int(game.get("party").call("size"))])
	return {"world": world, "game": game, "player": world.get_node_or_null(^"Player"),
		"rig": tree.get_first_node_in_group("camera_rig")}
