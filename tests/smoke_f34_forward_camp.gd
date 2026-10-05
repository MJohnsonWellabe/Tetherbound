extends SceneTree

## F34 forward camps in a REAL realm world, through the production placer and
## Session transaction (BuildPlacer._place -> session.forward_camp_submit_build
## -> Foundation camp_build -> world building_add -> ForwardCamp planted):
##   #0 a Workbench-crafted kit places on valid ground: bed, cookpot, workbench;
##   #4 the record carries the placer's character id and survives save/reload;
##   one camp per character per biome (a second is refused, kit kept);
##   #2 resting at the camp bed is the saved team rest (party recovers).
##
##   godot --headless --path . --script tests/smoke_f34_forward_camp.gd -- [--scene=<world tscn> --realm=<id>]
##
## Disclosed fixtures: the kit is added straight to the satchel (the Workbench
## craft is test_forward_camp / station-craft territory); the spot is found by
## a ring search with the placer's own preview_placement (snap + ground), the player
## stands 3 m from it and the ghost is aimed at it (what the camera would do);
## party HP is lowered directly before the rest.

const DEFAULT_SCENE := "res://scenes/world/meadows_playground.tscn"
const KIT := "forward_camp_kit"
const SAVE := preload("res://scripts/save/save_game.gd")

var failures := 0
var checks := 0
var _scene := DEFAULT_SCENE
var _realm := ""


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="): _scene = arg.trim_prefix("--scene=")
		elif arg.begins_with("--realm="): _realm = arg.trim_prefix("--realm=")
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS: " if ok else "FAIL: ") + what)


func _camps(game: Node) -> Array:
	return (game.get("placed_buildings") as Array).filter(func(r: Dictionary) -> bool:
		return r.get("id") == "forward_camp" and r.get("removed") != true)


func _camp_nodes() -> Array:
	return get_nodes_in_group("placed_building").filter(func(n: Node) -> bool:
		return n.get_script() == preload("res://scripts/build/forward_camp.gd"))


func _find_spot(game: Node, placer: Node, player: Node3D, realm: String, away_from := Vector3.INF) -> Vector3:
	var origin := player.global_position
	for ring in range(1, 60):
		for step in 16:
			var angle := TAU * float(step) / 16.0
			var at := origin + Vector3(cos(angle), 0.0, sin(angle)) * float(ring) * 4.0
			var height := float(placer.call("_ground_height", at))
			if not is_finite(height): continue
			at.y = height
			# The placer's own preview (grid snap + the camp ground check).
			var preview: Dictionary = placer.call("preview_placement", game, "forward_camp", at)
			if preview.get("ok") == true and preview.get("position") is Vector3 \
					and (away_from == Vector3.INF or (preview.position as Vector3).distance_to(away_from) > 20.0):
				return preview.position
	return Vector3.INF


var _last_message := ""


func _place_at(game: Node, placer: Node, player: Node3D, at: Vector3, read_message := false) -> void:
	player.global_position = at + Vector3(0.0, 0.5, 3.0)
	player.velocity = Vector3.ZERO
	game.set("pending_build", "forward_camp")
	for _frame in 20:
		await physics_frame
		player.global_position = at + Vector3(0.0, 0.5, 3.0)
	placer.set("_yaw_deg", 0.0)
	(placer.get("_ghost") as Node3D).global_position = at
	game.set("_pending_world_message", "")
	placer.call("_place", game, "forward_camp")
	if read_message: _last_message = str(game.get("_pending_world_message"))
	for _frame in 30:
		await physics_frame
	game.set("pending_build", "")


func _run() -> void:
	await process_frame
	var game := root.get_node("Game")
	if not _realm.is_empty(): game.set("current_realm", _realm)
	var world := (load(_scene) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for _frame in 900:
		await physics_frame
		if not world.has_method("shell_build_complete") or bool(world.call("shell_build_complete")): break
	for _frame in 120:
		await physics_frame
	var player := world.get_node_or_null("Player") as CharacterBody3D
	var placer := world.get_node_or_null("BuildPlacer")
	_check(player != null and placer != null, "the real world has a Player and a BuildPlacer (%s)" % _scene)
	if player == null or placer == null:
		_finish()
		return
	player.set_physics_process(false)
	var realm := str(preload("res://scripts/world/realm_world_records.gd").active(game))
	var local: RefCounted = game.get("local")
	var inventory: RefCounted = local.get("inventory")
	inventory.call("add", KIT, 2)
	if (local.get("party").call("members") as Array).is_empty():
		local.get("party").call("add", preload("res://scripts/creatures/creature_species.gd").spawn("terrapup"))
	var kits_before := int(inventory.call("count", KIT))
	var spot := _find_spot(game, placer, player, realm)
	_check(spot != Vector3.INF, "valid camp ground found in %s at %s" % [realm, str(spot)])
	# A second valid spot, found before the first camp exists (20 m clear of it).
	var second := _find_spot(game, placer, player, realm, spot) if spot != Vector3.INF else Vector3.INF
	if spot == Vector3.INF:
		_finish()
		return
	await _place_at(game, placer, player, spot)
	var camps := _camps(game)
	_check(camps.size() == 1, "one forward-camp record placed (%d)" % camps.size())
	if camps.size() == 1:
		_check(str(camps[0].get("character_id", "")) == str(local.get("character_id")) and str(camps[0].get("realm")) == realm,
			"it carries the placer's character id and realm (%s, %s)" % [str(camps[0].get("character_id")), str(camps[0].get("realm"))])
	_check(int(inventory.call("count", KIT)) == kits_before - 1, "exactly one kit spent (%d -> %d)" % [kits_before, int(inventory.call("count", KIT))])
	var nodes := _camp_nodes()
	_check(nodes.size() == 1, "one ForwardCamp planted in the world (%d)" % nodes.size())

	# Rest at the camp bed: the saved team rest recovers the party.
	if nodes.size() == 1:
		var camp: Node3D = nodes[0]
		var members: Array = local.get("party").call("members")
		for creature: RefCounted in members:
			creature.set("hp", float(creature.get("max_hp")) * 0.3)
		# Stand at the bed piece (forward_camps.json bed_offset, camp-local).
		var bed_at: Vector3 = camp.global_transform * Vector3(-2.0, 0.0, 0.0)
		player.global_position = bed_at + Vector3(0.0, 0.5, 1.0)
		for _frame in 10:
			await physics_frame
		var day_before := int(game.get("world").get("day")) if game.get("world") != null else -1

		# The rest waits for the owner's saved decision; the camp keeps the same
		# intent and the player presses again (what a held-out save looks like).
		var presses := 0
		while presses < 20:
			presses += 1
			camp.call("_activate", "bed")
			for _frame in 30:
				await physics_frame
			if (camp.get("_pending_rest") as Dictionary).is_empty(): break
		print("rest settled after %d press(es)" % presses)
		for _frame in 240:
			await physics_frame
		var healed := members.size() > 0
		for creature: RefCounted in members:
			healed = healed and float(creature.get("hp")) >= float(creature.get("max_hp")) - 0.01 \
				and creature.get("resting") != true
		_check(healed, "resting at the camp bed recovered the team to full and woke it (%d member(s))" % members.size())
		var day_after := int(game.get("world").get("day")) if game.get("world") != null else -1
		_check(day_after > day_before, "the rest passed the night (day %d -> %d)" % [day_before, day_after])

	# Loadouts are changed at the camp's field workbench (F34#2): the real
	# open_loadouts opens the companion panel on the Foundation loadout service.
	if nodes.size() == 1 and is_instance_valid(nodes[0]):
		var camp: Node3D = nodes[0]
		player.global_position = camp.global_transform * Vector3(2.0, 0.0, 1.1) + Vector3(0.0, 0.5, 1.0)
		for _frame in 10:
			await physics_frame
		camp.call("open_loadouts")
		await process_frame
		var panels := game.get_children().filter(func(n: Node) -> bool:
			return n.get_script() == preload("res://scripts/ui/companion_details_panel.gd"))
		_check(panels.size() == 1 and (panels[0] as CanvasLayer).visible,
			"the camp workbench opens the team loadout panel (%d panel(s))" % panels.size())
		for panel: Node in panels: panel.queue_free()
		await process_frame
		player.global_position = camp.global_position + Vector3(0.0, 40.0, 0.0)
		camp.call("open_loadouts")
		await process_frame
		var far := game.get_children().filter(func(n: Node) -> bool:
			return n.get_script() == preload("res://scripts/ui/companion_details_panel.gd") and not n.is_queued_for_deletion())
		_check(far.is_empty(), "away from the camp no loadout panel opens")

	# Travel-tier craft at the camp cookpot (F34#1) through the real panel:
	# a Small Potion settles; a Harness is refused naming the Forge.
	if nodes.size() == 1 and is_instance_valid(nodes[0]):
		var camp: Node3D = nodes[0]
		player.global_position = camp.global_transform * Vector3(2.0, 0.0, -1.1) + Vector3(0.0, 0.5, 1.0)
		for _frame in 10:
			await physics_frame
		inventory.call("add", "berries", 8)
		inventory.call("add", "fiber", 2)
		var potions := int(inventory.call("count", "potion_small"))
		camp.call("_activate", "cookpot")
		for _frame in 20:
			await physics_frame
		var panel: Node = camp.get("_panel")
		_check(panel != null and bool(panel.call("is_open")), "the camp cookpot opens its craft panel")
		if panel != null and bool(panel.call("is_open")):
			panel.call("_station_action", "station_craft", {"recipe_id": "potion_small"})
			for _frame in 600:
				if (panel.get("_station_intent") as Dictionary).is_empty() \
						and int(inventory.call("count", "potion_small")) > potions: break
				await physics_frame
			_check(int(inventory.call("count", "potion_small")) == potions + 1,
				"a Small Potion crafts at the camp cookpot (%d -> %d)" % [potions, int(inventory.call("count", "potion_small"))])
			var route: Dictionary = preload("res://scripts/build/forward_camp_rules.gd").recipe("craft_rootiron_harness",
				game.get("items").call("recipe", "craft_rootiron_harness"), "workbench")
			_check(route.get("ok") != true and str(route.get("reason", "")) == "Needs the homestead — use the Forge.",
				"a Harness is refused at the camp, naming the Forge: \"%s\"" % str(route.get("reason", "")))
			panel.call("close")
			for _frame in 5:
				await physics_frame

	# One per character per biome (HOMESTEAD §8): the first press on a second
	# spot refuses and offers to pack the first up; the second press packs it
	# (kit refunded) and pitches here. Kits end where they were before.
	if second != Vector3.INF:
		var first_uid := str(_camps(game)[0].get("uid", "")) if _camps(game).size() == 1 else ""
		await _place_at(game, placer, player, second, true)
		_check(_camps(game).size() == 1 and int(inventory.call("count", KIT)) == kits_before - 1,
			"a second camp in %s is refused at first and keeps its kit" % realm)
		_check(_last_message.contains("Press Place again to pack it up"),
			"the player is offered to pack up the first camp (\"%s\")" % _last_message)
		await _place_at(game, placer, player, second)
		for _frame in 240:
			await physics_frame
			var now := _camps(game)
			if now.size() == 1 and str(now[0].get("uid")) != first_uid: break
		var after := _camps(game)
		var moved: bool = after.size() == 1 and str(after[0].get("uid")) != first_uid \
			and Vector3(float(after[0].position[0]), float(after[0].position[1]), float(after[0].position[2])).distance_to(second) < 0.01
		_check(moved, "the second press packed the first camp up and pitched the new one here (%d camp(s))" % after.size())
		_check(int(inventory.call("count", KIT)) == kits_before - 1, "the old camp's kit was refunded and the new one spent (%d)" % int(inventory.call("count", KIT)))
		_check(_camp_nodes().size() == 1, "one ForwardCamp stands in the world (%d)" % _camp_nodes().size())

	# Save and reload the world record: the camp persists.
	_check(bool(game.call("autosave_here")), "the world saves through the autosave path")
	print("F34 FORWARD CAMP (%s): %d checks, %d failures" % [realm, checks, failures])
	_finish()


func _finish() -> void:
	quit(1 if failures > 0 else 0)
