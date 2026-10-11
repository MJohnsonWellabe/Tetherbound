extends SceneTree
const SAVE := preload("res://scripts/save/save_game.gd")
const CP := preload("res://tests/helpers/four_biome_checkpoints.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var w := "/tmp/claude-0/probe/w_%d" % Time.get_ticks_usec()
	CP.copy_tree("res://tests/fixtures/earned_saves/stormwood_arrival_generated/save", w)
	var game := root.get_node("Game")
	game.set("save_system", SAVE.new(w))
	var title := (load("res://scenes/ui/title_screen.tscn") as PackedScene).instantiate()
	root.add_child(title); current_scene = title
	for i in 10: await process_frame
	(title.get("_load_button") as Button).pressed.emit()
	await process_frame
	for n: Node in (title.get("_load_box") as Node).get_children():
		if n is Button and (n as Button).text.begins_with("Autosave"): (n as Button).pressed.emit(); break
	for f in 7200:
		await process_frame
		if current_scene != title and current_scene != null and current_scene.get_node_or_null("Player") != null and str(game.pending_realm_entry).is_empty(): break
	for i in 300: await physics_frame
	var world := current_scene as Node3D
	var seam := world.get_node_or_null("StormwoodHarvests/stormwood_harvest_cinder_verge_018") as Node3D
	print("SEAM node=", seam, " pos=", seam.global_position if seam else null)
	var at: Vector3 = seam.global_position if seam else Vector3(-762, 27, 893)
	for c: Node in world.find_children("*", "Node3D", true, false):
		var n := c as Node3D
		if n.global_position.distance_to(at) < 4.0 and (n.has_method("interaction_offer") or n.has_method("adopt_renewable_source")):
			var off: Variant = n.call("interaction_offer", at + Vector3(0, 0, -1.0)) if n.has_method("interaction_offer") else "-"
			print("NEAR ", n.get_path(), " script=", n.get_script().resource_path if n.get_script() else "", " site=", n.get("_renewable_site_id"), " enabled=", n.get("enabled"), " d=%.2f" % n.global_position.distance_to(at), " offer=", off)
	var mount := world.get_node_or_null("RenewableResources")
	print("MOUNT ", mount, " children=", mount.get_child_count() if mount else -1)
	if mount and mount.has_method("node_for"):
		for id in ["stormwood_harvest_cinder_verge_018", "order:stormwood_harvest_cinder_verge_018"]:
			print("node_for ", id, " -> ", mount.call("node_for", id))
	quit()
