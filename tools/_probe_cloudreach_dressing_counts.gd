## NOTE: patterns are `*Name*`, not `Name*`. Godot renames colliding siblings
## to the internal `@Name@N` form (add_child's default force_readable_name is
## false), so exactly one node per parent keeps the clean name and a `Name*`
## search silently reports 1 where there are 20.
##
## CLOUDREACH-DRESS-0906 scratch probe: did each half of this round's dressing
## actually place anything? A silently-skipped pass (a null prefab loader, a
## settlement node that did not resolve, a config block read under the wrong
## key) looks identical to a working one in a smoke test that only asserts the
## old counters, and identical again in a render nobody has measured yet.
##   godot --headless --path . --script tools/_probe_cloudreach_dressing_counts.gd
extends SceneTree

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	if game != null and game.has_method("reset_for_new_game"):
		game.call("reset_for_new_game")
		game.set("current_realm", "cloudreach")
	var world := SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	for _f in 8:
		await process_frame

	var look := world.get_node_or_null(^"CloudreachLook")
	if look != null:
		print("C8 settlement: modules=%d ridge_lashings=%d cloth_banners=%d overrides=%d guy_ropes=%d timber=%s" % [
			look.call("settlement_module_count"), look.call("settlement_ridge_lashing_count"),
			look.call("settlement_cloth_banner_count"), look.call("settlement_material_override_count"),
			look.call("settlement_guy_rope_count"), look.call("settlement_timber_colour")])
	for pattern: String in [
		"*CliffBalcony*", "*WindwardSupport*", "*SupportFooting*", "*CliffVine*", "*RidgeLashing*",
		"*RidgeWeightLog*", "*TerraceRail*", "*TerraceStore*", "*MarkedWindblownTetherBanner*",
		"*WindBanner*", "*AviaryMembranePanel*", "*AviaryLogPerch*", "*AviaryRoostingBird*",
		"*AviaryHandlingCable*", "*AviaryHangingCloth*", "*AviaryWallLantern*", "*AviaryLanternLight*",
		"*AviaryFloorTreatment*", "*AviaryFloorLitter*", "*AviaryStore*", "*AviaryRopeCoil*",
		"*AviaryChainCoil*", "*ArenaWornCentre*", "*ArenaHazardInlay*", "*ArenaScuff*",
		"*ArenaBrazierLight*", "*GatePostFooting*", "*GatePostBrazierStand*", "*GatePostBrazierHead*",
		"*AviaryPerchLeg*", "*AviaryCage*",
	]:
		print("  %-32s %d" % [pattern, world.find_children(pattern, "", true, false).size()])
	for node: Node in world.find_children("*WindBanner*", "", true, false):
		print("  WindBanner found: %s [%s]" % [world.get_path_to(node), node.get_class()])
	var landmarks := world.get_node_or_null(^"Landmarks")
	if landmarks != null:
		print("  Landmarks children: %s" % [landmarks.get_children().map(func(n: Node) -> String: return str(n.name))])
	var interior := world.find_child("AviaryInterior", true, false)
	if interior != null:
		var names: Array[String] = []
		for c: Node in interior.get_children():
			names.append(str(c.name))
		print("  AviaryInterior has %d children: %s" % [names.size(), ", ".join(names.slice(0, 40))])
	var terrace := world.find_child("Terrace_*", true, false)
	if terrace != null:
		var tn: Array[String] = []
		for c: Node in terrace.get_children():
			tn.append(str(c.name))
		print("  %s has %d children: %s" % [terrace.name, tn.size(), ", ".join(tn)])
	quit(0)
