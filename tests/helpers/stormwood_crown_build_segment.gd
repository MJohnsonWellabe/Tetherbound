extends RefCounted

## Controller-driven Stormwood Act-II construction segment.
##
## The caller owns a live production Stormwood world whose ordinary route has
## just completed Keeper Ondra's dialogue. This helper does not grant materials,
## write progression, move the player, arm a piece, craft, or place through a
## direct method call. It gathers six authored nodes, uses the camp CraftPanel,
## uses the Build catalogue and lands one paid Crown arch through parsed pad
## input. Read-only runtime fields are inspected only to identify focused UI and
## to fail closed on the exact provider, ghost, receipt and resource deltas.

const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const SAFETY := preload("res://tests/helpers/stormwood_field_safety.gd")

const RECIPE_FLAG := "stormwood:arch_recipe_known"
const BUILT_FLAG := "stormwood:crown_arch_built"
const FOOTING_XZ := Vector2(-160.0, 2750.0)
const ENTRY_XZ := Vector2(-160.0, 2697.5)
const RODLINE_XZ := Vector2(-660.0, 2318.0)
const BUILD_MENU_GROUP := "build_menu"
const PLACE_AHEAD := 3.0
const POSITION_EPSILON := 0.75
const CHARGED_WAIT_MS := 9 * 60 * 1000

# Authored nodes are all-or-nothing. Thunderwood sites yield four apiece, so
# the honest route gathers eight, spends six on two frames, and carries two on.
const SITE_PLAN: Array[Dictionary] = [
	{"id": "stormwood_harvest_conductor_run_099", "item": "thunderwood",
		"amount": 4, "tool": "axe", "at": Vector2(-1300.0, 3030.0)},
	{"id": "stormwood_harvest_conductor_run_097", "item": "conductor_vine",
		"amount": 3, "tool": "knife", "at": Vector2(-1600.0, 3030.0)},
	{"id": "stormwood_harvest_conductor_run_092", "item": "conductor_vine",
		"amount": 3, "tool": "knife", "at": Vector2(-1600.0, 2900.0)},
	{"id": "stormwood_harvest_conductor_run_094", "item": "thunderwood",
		"amount": 4, "tool": "axe", "at": Vector2(-1300.0, 2900.0)},
	{"id": "stormwood_harvest_conductor_run_075", "item": "stormglass_crown",
		"amount": 3, "tool": "pickaxe", "at": Vector2(-1150.0, 2380.0)},
	{"id": "stormwood_harvest_conductor_run_074", "item": "stormglass_crown",
		"amount": 3, "tool": "pickaxe", "at": Vector2(-1300.0, 2380.0)},
]

var failures: Array[String] = []
var transcript: Array[String] = []
var _tree: SceneTree
var _world: Node3D
var _game: Node
var _player: CharacterBody3D
var _camera: Node3D
var _arbiter: Node
var _harvests: Node3D
var _manager: Node
var _director: Node
var _navigator: RefCounted
var _activated_provider_id := 0
## Recent tool swings and Interact presses, to name what gathered (and so
## freed) a harvest node during its approach (run 17's vine node).
var _gather_events: Array[String] = []
var _activated_provider_path := ""
var _last_combat_outcome := ""
var _safety: RefCounted
## Only the Crown segment itself walks at the real 1x clock (the Conductor
## Road and west loop, coordinator order for run 12); later segments keep
## their own declared clocks.
var _walk_real_clock := false


static func resource_contract() -> Dictionary:
	return {
		"gathered": {"stormglass_crown": 6, "thunderwood": 8, "conductor_vine": 6},
		"frame_cost": {"thunderwood": 6, "conductor_vine": 2},
		"arch_cost": {"stormglass_crown": 6, "thunderwood_frame": 2,
			"conductor_vine": 4},
		"surplus": {"thunderwood": 2, "conductor_vine": 0,
			"stormglass_crown": 0},
	}


static func site_plan() -> Array[Dictionary]:
	return SITE_PLAN.duplicate(true)


func run(tree: SceneTree, world: Node3D, game: Node) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	_player = world.get_node_or_null(^"Player") as CharacterBody3D if world != null else null
	_camera = world.get_node_or_null(^"CameraRig") as Node3D if world != null else null
	_arbiter = tree.get_first_node_in_group(&"interaction_arbiter") if tree != null else null
	_harvests = world.get_node_or_null(^"StormwoodHarvests") as Node3D if world != null else null
	_manager = world.get_node_or_null(^"CombatManager") if world != null else null
	_director = world.get_node_or_null(^"EncounterDirector") if world != null else null
	if not _preconditions_hold():
		return result()
	_navigator = NAVIGATOR.new(_tree, _player, _camera, _drive_stick)
	_walk_real_clock = true
	if not _manager.exited.is_connected(_on_combat_exited):
		_manager.exited.connect(_on_combat_exited)

	# A player who has fought the whole road to Ondra rests before setting out
	# for a named alpha: Still Grove Shelter is the camp beside Ondra, on the
	# route, and its creature bed plus a night's rest heal the party. F11
	# witness run 7 wiped at the Alpha with no rest since Ashfoot.
	if not await _rest_party_at_camp("still_grove_shelter"):
		return result()
	var before := _inventory_snapshot()
	# Follow the production conductor road to the west-loop resources. This
	# passes the Capacitor Alpha's authored road point; any proximity fight is
	# answered by the same controller combat used for incidental wilds.
	for step: Dictionary in [
		{"at": Vector2(-630.0, 2930.0), "label": "conductor road west bend"},
		{"at": Vector2(-1080.0, 3020.0), "label": "Capacitor Grove road point"},
	]:
		if not await _walk_xz(step.at, str(step.label), 2.0):
			return result()
	# The road to the grove has its own wild fights. If they left a creature
	# fainted, walk back to the same camp and rest again, as a player would.
	if _party_worn(0.75):
		for back: Vector2 in [Vector2(-630.0, 2930.0), Vector2(-160.0, 2700.0)]:
			if not await _walk_xz(back, "conductor road back to Still Grove Shelter", 2.0):
				return result()
		if not await _rest_party_at_camp("still_grove_shelter"):
			return result()
		for step: Vector2 in [Vector2(-630.0, 2930.0), Vector2(-1080.0, 3020.0)]:
			if not await _walk_xz(step, "conductor road to the Capacitor Grove again", 2.0):
				return result()
	if not await _clear_capacitor_alpha():
		return result()
	for index in 2:
		if not await _gather_site(SITE_PLAN[index]):
			return result()
	# Rejoin the authored far bend before traversing the loop's return side.
	if not await _walk_xz(Vector2(-1720.0, 3040.0), "west-loop far bend", 2.0):
		return result()
	for index in range(2, 4):
		if not await _gather_site(SITE_PLAN[index]):
			return result()
	for step: Dictionary in [
		{"at": Vector2(-1550.0, 2460.0), "label": "west-loop Crown approach"},
		{"at": Vector2(-700.0, 2300.0), "label": "Rodline road return"},
		{"at": RODLINE_XZ, "label": "Rodline Refuge"},
	]:
		if not await _walk_xz(step.at, str(step.label), 2.0):
			return result()
	if not await _wait_for_charged_window():
		return result()
	for index in range(4, SITE_PLAN.size()):
		if not await _gather_site(SITE_PLAN[index]):
			return result()
	if not await _walk_xz(Vector2(-700.0, 2300.0), "Rodline road return after Crown seams", 2.0) \
			or not await _walk_xz(RODLINE_XZ, "Rodline Refuge crafting bench", 1.5):
		return result()

	if not _assert_gather_deltas(before):
		return result()
	if not await _craft_two_frames():
		return result()
	if not await _walk_xz(Vector2(-560.0, 2480.0), "conductor road to Still Grove", 2.0) \
			or not await _walk_xz(Vector2(-160.0, 2700.0), "Still Grove road point", 2.0):
		return result()
	if not await _build_paid_crown_arch():
		return result()
	_note("BUILT the Crown arch from six live harvests, two camp crafts and one paid controller placement")
	return result()


func result() -> Dictionary:
	return {"passed": failures.is_empty() and _game != null
		and bool(_game.get("progression").call("has", BUILT_FLAG)),
		"failures": failures.duplicate(), "transcript": transcript.duplicate()}


func _preconditions_hold() -> bool:
	if _tree == null or _world == null or _game == null or _player == null \
			or _camera == null or _arbiter == null or _harvests == null \
			or _manager == null or _director == null:
		return _fail("Crown segment is missing a production world/player/camera/interaction/combat service")
	if str(_game.get("current_realm")) != "stormwood" \
			or not bool(_world.call("shell_build_complete")):
		return _fail("Crown segment requires the ready production Stormwood realm")
	var progression: RefCounted = _game.get("progression")
	if not bool(progression.call("has", RECIPE_FLAG)):
		return _fail("Crown segment requires Ondra's physically earned arch_recipe_known fact")
	if bool(progression.call("has", BUILT_FLAG)):
		return _fail("Crown segment requires an unbuilt Still Grove Crown footing")
	if bool(_game.get("free_build")) or str(_game.get("pending_build")) != "":
		return _fail("Crown segment must begin paid and outside Build mode")
	var here := Vector2(_player.global_position.x, _player.global_position.z)
	if here.distance_to(ENTRY_XZ) > 16.0:
		return _fail("Crown segment must inherit the ordinary Ondra dialogue stance; player=%s expected=%s" % [here, ENTRY_XZ])
	for item: String in ["knife", "axe", "pickaxe"]:
		if int(_game.get("inventory").call("count", item)) <= 0 \
				or int(_game.call("hotbar_slot_of", item)) < 0:
			var stacks: Array = []
			for id: String in ["knife", "axe", "pickaxe"]:
				stacks.append("%s x%d" % [id, int(_game.get("inventory").call("count", id))])
			return _fail("Crown segment requires the campaign-earned %s on the controller hotbar (inventory %s, hotbar %s, equipped '%s')" % [
				item, ", ".join(stacks), str(_game.get("local").get("hotbar")), str(_game.get("equipped_tool"))])
	for site: Dictionary in SITE_PLAN:
		var id := str(site.id)
		if bool(progression.call("has", "harvest_node:order:" + id)):
			return _fail("Crown segment requires its named production source unclaimed: " + id)
		var node := _harvests.get_node_or_null(NodePath(id)) as Node3D
		if node == null or str(node.get_meta("stormwood_item", "")) != str(site.item):
			return _fail("Crown segment cannot find its exact live production source: " + id)
	return true


func _gather_site(site: Dictionary) -> bool:
	var id := str(site.id)
	var node := _harvests.get_node_or_null(NodePath(id)) as Node3D
	if node == null:
		return _fail("production harvest node disappeared before approach: " + id)
	if not await _equip_tool(str(site.tool)):
		return false
	var before := _count(str(site.item))
	var prompt := node.get_node_or_null(^"Interactable") as Node3D
	var receipt_id := "harvest_node:order:" + id
	_gather_events.clear()
	var hold: Node = _player.get("tool_hold") as Node
	var on_swing := func() -> void:
		_gather_events.append("%d swing_started aimed=%s equipped=%s" % [Time.get_ticks_msec(),
			str(hold.call("swing_target")), str(_game.get("equipped_tool"))])
	var on_connected := func(hit: Node) -> void:
		_gather_events.append("%d swing_connected %s" % [Time.get_ticks_msec(),
			str(hit.name) if is_instance_valid(hit) else "<freed>"])
	var on_exit := func() -> void:
		var player_xz := Vector2(_player.global_position.x, _player.global_position.z)
		_note("HARVEST NODE %s left the tree during '%s': receipt=%s equipped=%s swinging=%s distance=%.2f recent=[%s]" % [
			id, str(_safety.get("phase")) if _safety != null else "?",
			str(_game.get("progression").call("has", receipt_id)), str(_game.get("equipped_tool")),
			str(hold.call("is_swinging")) if hold != null else "?",
			player_xz.distance_to(Vector2(node.global_position.x, node.global_position.z)),
			"; ".join(_gather_events.slice(-6))])
	if hold != null:
		hold.connect("swing_started", on_swing)
		hold.connect("swing_connected", on_connected)
	node.tree_exiting.connect(on_exit)
	var activated := await _activate_exact(node, prompt, site.at, id)
	if hold != null:
		hold.disconnect("swing_started", on_swing)
		hold.disconnect("swing_connected", on_connected)
	if is_instance_valid(node) and node.tree_exiting.is_connected(on_exit):
		node.tree_exiting.disconnect(on_exit)
	if not activated:
		return false
	var receipt := "harvest_node:order:" + id
	for _frame in 600:
		if bool(_game.get("progression").call("has", receipt)) \
				and _count(str(site.item)) > before:
			break
		await _tree.physics_frame
	var gained := _count(str(site.item)) - before
	if not is_instance_valid(node):
		_note("%s: node gone after the approach; receipt=%s gained=%d" % [id,
			str(_game.get("progression").call("has", receipt)), gained])
	if gained != int(site.amount) or not bool(_game.get("progression").call("has", receipt)):
		return _fail("%s did not commit its exact live yield/receipt: gained=%d expected=%d" % [
			id, gained, int(site.amount)])
	_note("GATHERED %s +%d %s through its exact live prompt" % [id, gained, str(site.item)])
	if str(site.item) == "stormglass_crown":
		var surge := _world.get_node_or_null(^"StormwoodSurge")
		if surge != null:
			_note("CROWN WINDOW after %s: %s" % [id, str(_charged_window_snapshot(surge, site.at))])
	return true


func _assert_gather_deltas(before: Dictionary) -> bool:
	var contract := resource_contract().gathered as Dictionary
	for item: String in contract:
		var gained := _count(item) - int(before.get(item, 0))
		if gained != int(contract[item]):
			return _fail("six named sources produced the wrong %s delta: gained=%d expected=%d" % [
				item, gained, int(contract[item])])
	_note("SIX sources yielded6 Crown glass/8 Thunderwood/6 vine; the indivisible wood nodes carry2 surplus")
	return true


func _craft_two_frames() -> bool:
	var camp := _world.get_node_or_null(^"StormwoodCamps/rodline_refuge") as Node3D
	var prompt := camp.get_node_or_null(^"CraftInteractable") as Node3D if camp != null else null
	if camp == null or prompt == null:
		return _fail("Rodline Refuge lacks its production CraftInteractable")
	if not await _activate_exact(camp, prompt,
			Vector2(prompt.global_position.x, prompt.global_position.z) + Vector2(0.0, -1.1),
			"Rodline Refuge crafting bench"):
		return false
	var panel: Node = null
	for _frame in 180:
		panel = camp.get("_craft_panel") as Node
		if panel != null and bool(panel.call("is_open")):
			break
		await _tree.physics_frame
	if panel == null or not bool(panel.call("is_open")):
		return _fail("ordinary craft prompt did not open the production CraftPanel")
	var recipe_ids: Array = panel.get("_recipe_ids") as Array
	var rows: Array = panel.get("_rows") as Array
	var wanted := recipe_ids.find("thunderwood_frame")
	var focus_owner := _tree.root.gui_get_focus_owner()
	var focused := rows.find(focus_owner)
	if wanted < 0 or focused < 0:
		return _fail("CraftPanel did not expose a controller-focused thunderwood_frame row")
	var action := &"ui_down" if wanted >= focused else &"ui_up"
	for _step in absi(wanted - focused):
		await _tap(action)
	if _tree.root.gui_get_focus_owner() != rows[wanted]:
		return _fail("controller focus did not land on thunderwood_frame")
	var before := _inventory_snapshot()
	await _tap(&"ui_accept")
	await _tap(&"ui_accept")
	if _count("thunderwood_frame") != int(before.thunderwood_frame) + 2 \
			or _count("thunderwood") != int(before.thunderwood) - 6 \
			or _count("conductor_vine") != int(before.conductor_vine) - 2:
		return _fail("two controller crafts did not apply the exact frame recipe: before=%s after=%s" % [
			str(before), str(_inventory_snapshot())])
	await _tap(&"menu_cancel")
	for _frame in 60:
		if not bool(panel.call("is_open")):
			break
		await _tree.physics_frame
	if bool(panel.call("is_open")):
		return _fail("ordinary menu cancel did not close CraftPanel")
	_note("CRAFTED two Thunderwood Frames through focused CraftPanel rows")
	return true


func _build_paid_crown_arch() -> bool:
	var placer := _tree.get_first_node_in_group(&"build_placer")
	if placer == null:
		return _fail("production Stormwood world has no BuildPlacer")
	if not await _turn_camera_toward(Vector3(0.0, 0.0, -1.0)):
		return false
	var forward := -(_camera.call("planar_basis") as Basis).z
	var anchor := _grounded(FOOTING_XZ)
	var stance := anchor - forward * PLACE_AHEAD
	if not await _walk_xz(Vector2(stance.x, stance.z), "Still Grove Crown build stance", 0.55):
		return false
	if not await _select_arch_from_catalogue():
		return false
	# Opening a live menu does not freeze nearby actors; reacquire the exact
	# stance and camera direction after arming before judging the ghost.
	if not await _walk_xz(Vector2(stance.x, stance.z), "armed Crown build stance", 0.55) \
			or not await _turn_camera_toward(Vector3(0.0, 0.0, -1.0)):
		return false
	for _frame in 30:
		var ghost := placer.get("_ghost") as Node3D
		if ghost != null and bool(placer.get("_ghost_ok")) \
				and ghost.global_position.distance_to(anchor) <= POSITION_EPSILON:
			break
		await _tree.physics_frame
	var live_ghost := placer.get("_ghost") as Node3D
	if live_ghost == null or not bool(placer.get("_ghost_ok")) \
			or live_ghost.global_position.distance_to(anchor) > POSITION_EPSILON:
		return _fail("controller stance did not produce a green live Crown socket ghost (reason=%s ghost=%s anchor=%s)" % [
			str(placer.get("_ghost_reason")),
			str(live_ghost.global_position) if live_ghost != null else "<none>", str(anchor)])
	var before := _inventory_snapshot()
	var records_before := (_game.get("placed_buildings") as Array).size()
	await _tap(&"build_place")
	if not await _wait_flag(BUILT_FLAG, 300):
		return _fail("paid controller placement did not publish " + BUILT_FLAG)
	var records: Array = _game.get("placed_buildings") as Array
	if records.size() != records_before + 1:
		return _fail("one build_place edge added %d records" % (records.size() - records_before))
	var record := records.back() as Dictionary
	if str(record.get("id", "")) != "stormglass_arch" \
			or str(record.get("realm", "")) != "stormwood" \
			or not bool(record.get("paid", false)) \
			or str(record.get("arch_twin", "")) != "e_crown" \
			or str(record.get("arch_footing", "")) != "still_grove":
		return _fail("placed record is not the paid linked Crown arch: " + str(record))
	if _count("stormglass_crown") != int(before.stormglass_crown) - 6 \
			or _count("thunderwood_frame") != int(before.thunderwood_frame) - 2 \
			or _count("conductor_vine") != int(before.conductor_vine) - 4:
		return _fail("Crown placement charged the wrong exact dynamic cost: before=%s after=%s" % [
			str(before), str(_inventory_snapshot())])
	return true


func _select_arch_from_catalogue() -> bool:
	var menu := _open_build_menu()
	if menu == null:
		for _attempt in 4:
			if not await _wait_for_world_input():
				break
			await _tap(&"build_shortcut")
			for _frame in 45:
				menu = _open_build_menu()
				if menu != null:
					break
				await _tree.physics_frame
			if menu != null:
				break
	if menu == null:
		return _fail("controller build_shortcut did not open the production Build catalogue")
	for _category_try in 5:
		var pieces: Array = menu.call("_current_pieces") as Array
		var wanted := -1
		for index in pieces.size():
			if str((pieces[index] as Dictionary).get("id", "")) == "stormglass_arch":
				wanted = index
				break
		if wanted >= 0:
			var cells: Array = menu.get("_cell_buttons") as Array
			var focused := cells.find(_tree.root.gui_get_focus_owner())
			if focused < 0 or wanted >= cells.size():
				return _fail("Stormglass Arch catalogue cell has no controller focus path")
			var action := &"ui_right" if wanted >= focused else &"ui_left"
			for _step in absi(wanted - focused):
				await _tap(action)
			await _tap(&"ui_accept")
			for _frame in 30:
				if str(_game.get("pending_build")) == "stormglass_arch" and _open_build_menu() == null:
					return true
				await _tree.physics_frame
			return _fail("focused Stormglass Arch accept did not arm and close the catalogue")
		await _tap(&"menu_tab_right")
		await _settle(8)
	return _fail("controller tabs could not reach the Stormglass Arch catalogue cell")


## Wait at the refuge until the charged window at the Crown seams stays open
## long enough to walk out and take both. Run 20 left on a "fading" window with
## under a minute to go and reached stormwood_harvest_conductor_run_075 after it
## closed (gained 0); run 19 happened to leave on a fresh Break. The same rule
## as the prefix's Lantern Pools wait: the runtime's own open seconds at the
## site, not any live Break/Fading.
const CROWN_ROUTE_SECONDS := 150.0


func _wait_for_charged_window() -> bool:
	var surge := _world.get_node_or_null(^"StormwoodSurge")
	if surge == null:
		return _fail("StormwoodSurge is absent before Crown glass gathering")
	var at: Vector2 = SITE_PLAN[4].at
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < CHARGED_WAIT_MS:
		var state := _charged_window_snapshot(surge, at)
		if float(state.get("open_seconds", 0.0)) >= CROWN_ROUTE_SECONDS and bool(surge.get("sheltered")):
			_note("WAITED at Rodline Refuge for a live Crown-gather window %s" % str(state))
			return true
		await _tree.physics_frame
	return _fail("Rodline Refuge did not reach a sheltered window with %.0f open seconds at the Crown seams within nine minutes (last=%s)" % [
		CROWN_ROUTE_SECONDS, str(_charged_window_snapshot(surge, at))])


## The runtime's own Surge phase at `at` and how long the charged window
## (Break, then Fading) stays open, in simulation seconds.
func _charged_window_snapshot(surge: Node, at: Vector2) -> Dictionary:
	var environment: Dictionary = _game.get("realm_environment")
	var saved: Variant = environment.get("stormwood", {})
	var raw: Variant = (saved as Dictionary).get("elapsed", 0.0) if saved is Dictionary else 0.0
	var elapsed := float(raw) if raw is float or raw is int else 0.0
	var point := Vector3(at.x, float(_world.call("ground_height_at", at.x, at.y)), at.y)
	var region := str(surge.call("region_at", point))
	var rules: RefCounted = surge.get("rules") as RefCounted
	var row: Dictionary = (rules.get("config") as Dictionary).get("regions", {}).get(region, {})
	var rod_flag := str(row.get("rod_flag", ""))
	var flags: RefCounted = _game.get("progression") as RefCounted
	var rod_disabled := not rod_flag.is_empty() and bool(flags.call("has", rod_flag))
	var aftermath := bool(flags.call("has", "stormwood:long_storm_ended"))
	var current: Dictionary = rules.call("phase_at", elapsed, region, rod_disabled, aftermath)
	var phase := str(current.get("phase", ""))
	var open := 0.0
	if phase == "fading":
		open = float(current.get("remaining", 0.0))
	elif phase == "break":
		open = float(current.get("remaining", 0.0))
		var next: Dictionary = rules.call("phase_at", elapsed + open + 0.001, region, rod_disabled, aftermath)
		if str(next.get("phase", "")) == "fading":
			open += float(next.get("remaining", 0.0))
	return {"phase": phase, "open_seconds": snappedf(open, 0.1), "elapsed": snappedf(elapsed, 0.1), "region": region}


func _activate_exact(body: Node3D, prompt: Node3D, preferred: Vector2,
		label: String) -> bool:
	if body == null or prompt == null:
		return _fail(label + " has no live production interaction provider")
	var around := Vector2(prompt.global_position.x, prompt.global_position.z)
	var candidates: Array[Vector2] = [preferred, around + Vector2(0.0, -1.1),
		around + Vector2(1.1, 0.0), around + Vector2(0.0, 1.1),
		around + Vector2(-1.1, 0.0)]
	for stance: Vector2 in candidates:
		if not is_instance_valid(prompt):
			break
		if not await _walk_xz(stance, label + " stance", 0.75, false):
			continue
		var held := 0
		for _frame in 180:
			if not is_instance_valid(prompt):
				break
			if _arbiter.call("winning_provider") == prompt:
				held += 1
				if held >= 8:
					_activated_provider_id = 0
					_activated_provider_path = ""
					_activations.clear()
					var observer := Callable(self, "_on_arbiter_activated")
					_arbiter.activated.connect(observer)
					var wanted_id := prompt.get_instance_id()
					await _tap(&"interact")
					if _arbiter.activated.is_connected(observer):
						_arbiter.activated.disconnect(observer)
					if _activated_provider_id == wanted_id:
						return true
					# A harvest node answers the press by being gathered and
					# freed (the equipped tool's swing resolves it). Run 16's
					# Thunderwood node vanished under the press this way; the
					# caller checks the receipt and the yield.
					if not is_instance_valid(prompt) or not is_instance_valid(body):
						_note("%s was consumed by the press" % label)
						return true
					if _activated_provider_id != 0:
						var winner_now := _arbiter.call("winning_provider") as Node
						var provider_node := instance_from_id(_activated_provider_id) as Node3D
						return _fail(("%s activated competing provider %s#%d (activations=%s; player=%s; wanted prompt at %s %.2f m; "
							+ "activated at %s %.2f m; winner now=%s)") % [
							label, _activated_provider_path, _activated_provider_id, str(_activations),
							str(_player.global_position), str(prompt.global_position),
							_player.global_position.distance_to(prompt.global_position),
							str(provider_node.global_position) if provider_node != null else "?",
							_player.global_position.distance_to(provider_node.global_position) if provider_node != null else -1.0,
							str(winner_now.get_path()) if winner_now != null else "<none>"])
					break
			else:
				held = 0
			await _tree.physics_frame
	var winner := _arbiter.call("winning_provider") as Node
	if not is_instance_valid(prompt) or not is_instance_valid(body):
		# Run 17: the vine node was gathered and freed during the approach,
		# not by this helper's Interact. The caller (`_gather_site`) judges
		# the receipt and the exact yield; any other caller's check fails.
		_note("%s was freed during its approach (winner=%s); the caller checks what happened" % [label,
			str(winner.get_path()) if winner != null else "<none>"])
		return true
	var own_offer: Variant = prompt.call("interaction_offer", _player.global_position) \
		if prompt.has_method("interaction_offer") else "n/a"
	return _fail("%s never won the InteractionArbiter (winner=%s offer=%s; target enabled=%s visible=%s in_tree=%s own_offer=%s player=%s prompt_at=%s distance=%.2f equipped=%s)" % [label,
		str(winner.get_path()) if winner != null else "<none>", str(_arbiter.call("winner")),
		str(prompt.get("enabled")), str(body.is_visible_in_tree()), str(body.is_inside_tree()), str(own_offer),
		str(_player.global_position), str(prompt.global_position),
		_player.global_position.distance_to(prompt.global_position), str(_game.get("equipped_tool"))])


func _walk_xz(point: Vector2, label: String, tolerance: float = 1.3,
		record_failure: bool = true) -> bool:
	if _safety == null:
		_safety = SAFETY.new()
		_safety.attach(_tree, _world, _game, _player, _camera, _drive_stick)
	_safety.set("phase", "walk to " + label)
	if not _walk_real_clock or is_equal_approx(Engine.time_scale, 1.0):
		return await _walk_xz_clocked(point, label, tolerance, record_failure)
	var previous_scale := Engine.time_scale
	var previous_hz := Engine.physics_ticks_per_second
	await _tree.process_frame
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	await _tree.process_frame
	var arrived := await _walk_xz_clocked(point, label, tolerance, record_failure)
	await _tree.process_frame
	Engine.time_scale = previous_scale
	Engine.physics_ticks_per_second = previous_hz
	return arrived


## Lightning log and satchel state for this segment (null before any walk).
func strike_counts() -> Dictionary:
	return (_safety.get("counts") as Dictionary).duplicate() if _safety != null else {}


func _walk_xz_clocked(point: Vector2, label: String, tolerance: float = 1.3,
		record_failure: bool = true) -> bool:
	var target := _grounded(point)
	var distance := Vector2(_player.global_position.x, _player.global_position.z).distance_to(point)
	var budget := maxi(1800, int(distance * 80.0))
	_navigator.call("reset")
	var walked := 0
	var held := 0
	while walked < budget:
		if Vector2(_player.global_position.x, _player.global_position.z).distance_to(point) <= tolerance:
			_drive_stick.call(0.0, 0.0)
			await _settle(4)
			return true
		if bool(_safety.call("needs_recovery")):
			if not bool(await _safety.call("recover", Callable(self, "_walk_xz"), Callable(self, "_activate_exact"))):
				return _fail("could not take back the trainer's death satchel during " + label)
			_navigator.call("reset")
			continue
		if bool(await _safety.call("dodge_step", target)):
			walked += 1
			_navigator.call("reset")
			continue
		if bool(_navigator.call("can_walk")):
			walked += 1
			held = 0
			await _navigator.call("step", target)
			continue
		_drive_stick.call(0.0, 0.0)
		if bool(_manager.call("is_fighting")):
			if not await _fight_current(label):
				return false
			_navigator.call("reset")
			continue
		held += 1
		if held > 36000:
			break
		await _tree.physics_frame
	_drive_stick.call(0.0, 0.0)
	if record_failure:
		_fail("ordinary locomotion could not reach %s (player=%s target=%s)" % [
			label, str(_player.global_position), str(target)])
	return false


var _fights_seen := 0


func _fight_current(label: String) -> bool:
	_fights_seen += 1
	if _safety != null:
		_safety.set("phase", "fight during " + label)
	_last_combat_outcome = ""
	var started := Time.get_ticks_msec()
	var previous_scale := Engine.time_scale
	var previous_hz := Engine.physics_ticks_per_second
	var ally_instance := _director.call("ally_instance") as RefCounted
	var enemy_instance := _manager.call("enemy") as RefCounted
	var counts := {"player_hits": 0, "enemy_hits": 0, "player_misses": 0,
		"enemy_misses": 0, "damage_dealt": 0.0, "damage_taken": 0.0}
	var on_hit := func(on_enemy: bool, amount: float) -> void:
		var hits := "player_hits" if on_enemy else "enemy_hits"
		var damage := "damage_dealt" if on_enemy else "damage_taken"
		counts[hits] += 1
		counts[damage] += amount
	var on_miss := func(by_player: bool) -> void:
		counts["player_misses" if by_player else "enemy_misses"] += 1
	_manager.connect("hit_landed", on_hit)
	_manager.connect("attack_missed", on_miss)
	_note("FIGHT start %s ally=%s enemy=%s" % [label,
		_fighter_snapshot(ally_instance), _fighter_snapshot(enemy_instance)])
	# The physical action cadence below is wall-clock based. Keep production
	# combat on that same clock, as with the explicit Engage edge.
	await _tree.process_frame
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	await _tree.process_frame
	var next_quick_ms := 0
	var tick := 0
	var release_tick := -1
	while bool(_manager.call("is_fighting")) and Time.get_ticks_msec() - started < 180000:
		var enemy := _manager.call("enemy_body") as Node3D
		var ally := _director.call("ally_body") as Node3D
		if enemy != null and ally != null:
			var offset := enemy.global_position - ally.global_position
			offset.y = 0.0
			_drive_stick.call(0.0, 0.0)
			if offset.length() > float(_manager.call("combat_move_reach", "quick")) * 0.8:
				var local := (_camera.call("planar_basis") as Basis).inverse() * offset.normalized()
				_drive_stick.call(local.x, local.z)
			if release_tick >= 0 and tick >= release_tick:
				_set_action(&"combat_quick", false)
				release_tick = -1
			if Time.get_ticks_msec() >= next_quick_ms and bool(_manager.call("quick_ready")):
				_set_action(&"combat_quick", true)
				release_tick = tick + 2
				next_quick_ms = Time.get_ticks_msec() + 900
		tick += 1
		await _tree.physics_frame
	_set_action(&"combat_quick", false)
	_drive_stick.call(0.0, 0.0)
	_manager.disconnect("hit_landed", on_hit)
	_manager.disconnect("attack_missed", on_miss)
	await _tree.process_frame
	Engine.time_scale = previous_scale
	Engine.physics_ticks_per_second = previous_hz
	_note("FIGHT end %s outcome=%s elapsed_ms=%d ally=%s enemy=%s strikes=%s" % [
		label, _last_combat_outcome, Time.get_ticks_msec() - started,
		_fighter_snapshot(ally_instance), _fighter_snapshot(enemy_instance), counts])
	if bool(_manager.call("is_fighting")) or _last_combat_outcome.is_empty():
		return _fail("combat during %s did not resolve and publish an outcome" % label)
	_note("RESOLVED live route encounter during %s (outcome=%s)" % [label, _last_combat_outcome])
	return true


static func _fighter_snapshot(creature: RefCounted) -> Dictionary:
	if creature == null:
		return {}
	return {"species": creature.get("species_id"), "level": creature.get("level"),
		"hp": creature.get("hp"), "max_hp": creature.get("max_hp"),
		"fainted": creature.get("fainted"), "resting": creature.get("resting")}


func _clear_capacitor_alpha() -> bool:
	const CLEAR_FLAG := "stormwood:named:capacitor_alpha:cleared"
	if bool(_game.get("progression").call("has", CLEAR_FLAG)):
		return true
	# A proximity fight may already be active after the road walk. Finish it
	# before exploration recall/cycle inputs, using the existing combat bound.
	if bool(_manager.call("is_fighting")):
		if not await _fight_current("Capacitor Alpha arrival"):
			return false
		if bool(_game.get("progression").call("has", CLEAR_FLAG)):
			_note("CLEARED the named Capacitor Alpha during its ordinary road approach")
			return true
	var body := _named_wild("capacitor_alpha")
	if body == null:
		return _fail("the live named Capacitor Alpha is absent before its durable clear fact")
	# Proximity may already have announced while no usable ally was deployed.
	# Use the ordinary explicit Engage offer too; never assume an aggressive
	# body's one-shot request will be repeated after party recovery.
	# The Alpha roams with Tanglevolt escorts, and Engage always offers the
	# nearest body. A player standing by it answers the escort first. F11
	# witness run 6 spent all four approaches refusing to press an escort's
	# Engage and never started a fight; up to eight approaches now allow the
	# escorts to be fought in turn.
	for attempt in 8:
		if not await _ensure_usable_ally("Capacitor Alpha re-engagement"):
			return false
		body = _named_wild("capacitor_alpha")
		if body == null:
			return _fail("Capacitor Alpha body retired without publishing " + CLEAR_FLAG)
		var at := Vector2(body.global_position.x, body.global_position.z)
		if not await _walk_xz(at, "Capacitor Alpha live approach %d" % (attempt + 1), 1.2):
			return false
		if bool(_game.get("progression").call("has", CLEAR_FLAG)):
			_note("CLEARED the named Capacitor Alpha during its ordinary live approach")
			return true
		if not is_instance_valid(body):
			return _fail("Capacitor Alpha retired during approach without its clear receipt")
		_note("ALPHA admission before input: " + str(_alpha_admission_snapshot(body)))
		for _frame in 180:
			if bool(_manager.call("is_fighting")):
				break
			if bool(_game.get("progression").call("has", CLEAR_FLAG)):
				break
			var escort := _director.call("_engageable") as Node3D
			if is_instance_valid(escort) and escort != body and _named_engage_ready(escort):
				_note("ENGAGING the Alpha's escort %s first (Engage offers the nearest body)" % str(escort.get_path()))
				if await _tap_named_engage(escort):
					for _settle in 60:
						if bool(_manager.call("is_fighting")):
							break
						await _tree.physics_frame
					if bool(_manager.call("is_fighting")):
						if _manager.call("enemy_body") == body:
							_note("ALPHA admitted while answering an escort")
						elif not await _fight_current("Capacitor Alpha escort"):
							return false
				break
			if _named_engage_ready(body):
				_activated_provider_id = 0
				_activated_provider_path = ""
				var observer := Callable(self, "_on_arbiter_activated")
				_arbiter.activated.connect(observer)
				var pressed := await _tap_named_engage(body)
				if _arbiter.activated.is_connected(observer):
					_arbiter.activated.disconnect(observer)
				if not pressed:
					continue
				if bool(_manager.call("is_fighting")) \
						and _manager.call("enemy_body") != body:
					return _fail("explicit named Alpha Engage admitted a different body")
				_note("ALPHA admission after input: " + str(_alpha_admission_snapshot(body)))
				break
			await _tree.physics_frame
		_note("ALPHA approach ended: " + str(_alpha_admission_snapshot(body)))
		# Resolve the encounter in the attempt that admitted it, including the
		# final approach; deferring this to the next iteration loses attempt four.
		if bool(_manager.call("is_fighting")):
			if not await _fight_current("Capacitor Alpha"):
				return false
		if await _wait_flag(CLEAR_FLAG, 180):
			_note("CLEARED the named Capacitor Alpha through its production once-only fight")
			return true
	return _fail("eight ordinary approaches did not clear the named Capacitor Alpha (body=%s distance=%.2f outcome=%s)" % [
		str(body.get_path()) if is_instance_valid(body) else "<none>",
		_player.global_position.distance_to(body.global_position) if is_instance_valid(body) else INF,
		_last_combat_outcome])


## True when a party member is fainted or the party holds less than `share`
## of its total hit points.
func _party_worn(share: float) -> bool:
	var hp := 0.0
	var most := 0.0
	for member: RefCounted in (_game.get("party").call("members") as Array):
		if bool(member.get("fainted")):
			return true
		hp += float(member.get("hp"))
		most += float(member.get("max_hp"))
	return most > 0.0 and hp < most * share


## Ordinary camp recovery: for each worn creature, one night. Interact with the
## camp's creature bed, choose that creature's row with the pad (Down, A),
## close the panel (B), then Interact with the camp's own "Rest at" prompt.
## The night completes the bedded creature's rest (full heal, revives a KO).
func _rest_party_at_camp(camp_id: String) -> bool:
	# Physical button edges must land between physics batches; at the
	# wrapper's 8x/480 Hz clock a press and release can share one batch and
	# the arbiter sees neither (run 9 pressed the bed five times for nothing).
	# `_tap_named_engage` makes the same switch for the same reason.
	var previous_scale := Engine.time_scale
	var previous_hz := Engine.physics_ticks_per_second
	await _tree.process_frame
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	await _tree.process_frame
	var rested := await _rest_nights(camp_id)
	await _tree.process_frame
	Engine.time_scale = previous_scale
	Engine.physics_ticks_per_second = previous_hz
	return rested


func _rest_nights(camp_id: String) -> bool:
	var camp := _world.get_node_or_null(NodePath("StormwoodCamps/" + camp_id)) as Node3D
	var bed := camp.get_node_or_null(^"CampCreatureBed") as Node3D if camp != null else null
	var bed_prompt := bed.get_node_or_null(^"Interactable") as Node3D if bed != null else null
	var rest_prompt := camp.get_node_or_null(^"Interactable") as Node3D if camp != null else null
	if bed_prompt == null or rest_prompt == null:
		return _fail("camp %s lacks its creature bed or rest prompt" % camp_id)
	var party: RefCounted = _game.get("party") as RefCounted
	var nights := 0
	for _night in 6:
		var index := -1
		var rows: Array[String] = []
		for i in int(party.call("size")):
			var member: RefCounted = party.call("at", i)
			rows.append("%s %d/%d%s" % [str(member.get("species_id")), int(member.get("hp")),
				int(member.get("max_hp")), " KO" if bool(member.get("fainted")) else ""])
			if index < 0 and (bool(member.get("fainted")) or float(member.get("hp")) < float(member.get("max_hp")) - 0.5):
				index = i
		if index < 0:
			break
		_note("CAMP %s night %d: %s; bedding row %d" % [camp_id, nights + 1, ", ".join(rows), index])
		if not await _activate_exact(bed, bed_prompt, Vector2(bed_prompt.global_position.x,
				bed_prompt.global_position.z - 1.1), camp_id + " creature bed"):
			return false
		var panel: Node = null
		for _frame in 60:
			panel = bed.get("_panel") as Node
			if panel != null and bool(panel.call("is_open")):
				break
			await _tree.process_frame
		if panel == null or not bool(panel.call("is_open")):
			return _fail("the creature bed did not open its rest panel")
		await _ui_tap(&"ui_up")
		await _ui_tap(&"ui_down")
		var buttons: Array = panel.get("_rows")
		for _press in 6:
			var focus := _tree.root.gui_get_focus_owner()
			if buttons.find(focus) == index:
				break
			await _ui_tap(&"ui_down" if buttons.find(focus) < index else &"ui_up")
			buttons = panel.get("_rows")
		if buttons.find(_tree.root.gui_get_focus_owner()) != index:
			return _fail("pad focus never reached bed row %d" % index)
		await _ui_tap(&"ui_accept")
		var creature: RefCounted = party.call("at", index)
		if not bool(creature.get("resting")):
			return _fail("choosing bed row %d did not bed %s" % [index, str(creature.get("species_id"))])
		await _ui_tap(&"menu_cancel")
		for _frame in 30:
			if not bool(panel.call("is_open")) and not _tree.paused:
				break
			await _tree.process_frame
		if not await _activate_exact(camp, rest_prompt, Vector2(rest_prompt.global_position.x,
				rest_prompt.global_position.z - 1.1), camp_id + " rest"):
			return false
		for _frame in 600:
			if not bool(creature.get("resting")):
				break
			await _tree.physics_frame
		if bool(creature.get("resting")) or bool(creature.get("fainted")) \
				or float(creature.get("hp")) < float(creature.get("max_hp")) - 0.5:
			return _fail("a night at %s did not complete %s's rest" % [camp_id, str(creature.get("species_id"))])
		nights += 1
	if _party_worn(0.999):
		return _fail("six nights at %s left the party worn" % camp_id)
	_note("RESTED the whole party at %s over %d night(s) with ordinary bed and rest prompts" % [camp_id, nights])
	return await _ensure_usable_ally("after resting at " + camp_id)


func _ui_tap(action: StringName) -> void:
	_set_action(action, true)
	for _frame in 3:
		await _tree.process_frame
	_set_action(action, false)
	for _frame in 5:
		await _tree.process_frame


func _named_engage_ready(body: Node3D) -> bool:
	if not is_instance_valid(body) or _director == null or _arbiter == null:
		return false
	var offer: Dictionary = _arbiter.call("winner")
	return _director.call("_engageable") == body \
		and _arbiter.call("winning_provider") == _director \
		and bool(offer.get("actionable", false))


func _tap_named_engage(body: Node3D) -> bool:
	# Match the existing Cloudreach controller driver: physical edges must land
	# between physics batches. At 8x the old press/release could both occur in
	# one batch and the arbiter observed neither (activated signal stayed empty).
	var previous_scale := Engine.time_scale
	var previous_hz := Engine.physics_ticks_per_second
	await _tree.process_frame
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	await _tree.process_frame
	# The candidate may move while clocks settle. Never press an old offer.
	var pressed := _named_engage_ready(body) and bool(_arbiter.call("enabled")) \
		and INPUT_OWNER.current(_tree) == null and not _tree.paused
	if pressed:
		await _tap(&"interact") # one press: held two physics and two process frames
	await _tree.process_frame
	Engine.time_scale = previous_scale
	Engine.physics_ticks_per_second = previous_hz
	return pressed


func _alpha_admission_snapshot(body: Node3D) -> Dictionary:
	if not is_instance_valid(body):
		return {"body": "<retired>"}
	var candidate := _director.call("_engageable") as Node3D
	var winner := _arbiter.call("winning_provider") as Node
	var owner := INPUT_OWNER.current(_tree)
	var ally := _director.call("ally_instance") as RefCounted
	return {
		"body": str(body.get_path()), "aggressive": body.get("aggressive"),
		"announced": body.get("_has_announced"), "grace": body.get("_grace_left"),
		"returning_home": body.get("_returning_home"),
		"alive": body.call("is_alive"), "visible": body.visible,
		"distance": _player.global_position.distance_to(body.global_position),
		"no_usable_ally": _director.call("no_usable_ally"),
		"ally_deployed": _director.call("ally_body") != null,
		"candidate": str(candidate.get_path()) if candidate != null else "<none>",
		"winner": str(winner.get_path()) if winner != null else "<none>",
		"offer": _arbiter.call("winner"), "fighting": _manager.call("is_fighting"),
		"arbiter_enabled": _arbiter.call("enabled"), "tree_paused": _tree.paused,
		"input_owner": str(owner.get_path()) if owner != null else "<none>",
		"interact_pressed": Input.is_action_pressed("interact"),
		"activated_provider": _activated_provider_path,
		"ally_fainted": ally.get("fainted") if ally != null else null,
		"ally_resting": ally.get("resting") if ally != null else null,
		"ally_hp": ally.get("hp") if ally != null else null,
		"manager_state": _manager.get("state"),
	}


func _named_wild(id: String) -> Node3D:
	for body: Node3D in (_director.call("wild_creatures") as Array[Node3D]):
		if is_instance_valid(body) and str(body.get_meta("stormwood_named_encounter", "")) == id:
			return body
	return null


func _ensure_usable_ally(label: String) -> bool:
	if bool(_director.call("no_usable_ally")):
		await _tap(&"party_cycle")
		for _frame in 180:
			if not bool(_director.call("no_usable_ally")):
				break
			await _tree.physics_frame
	if _director.call("ally_body") == null:
		await _tap(&"creature_recall")
		for _frame in 180:
			if _director.call("ally_body") != null:
				break
			await _tree.physics_frame
	if bool(_director.call("no_usable_ally")):
		var party: RefCounted = _game.get("party") as RefCounted
		var alive := 0
		for member: RefCounted in (party.call("members") as Array):
			if member != null and not bool(member.get("fainted")):
				alive += 1
		return _fail("ordinary party-cycle/recall left no usable ally before %s (healthy=%d)" % [
			label, alive])
	return await _lead_with_fittest(label)


## Before a deliberate fight (a named wild, a trainer, the captain) the player
## sends out the conscious party member with the most hit points left, with
## ordinary LB presses; the director's own party sync redeploys it. Road fights
## leave the lead worn and this route takes no rest. F11 witness run 4 lost the
## Capacitor Alpha with a 113/436 lead while two members stood at full health.
func _lead_with_fittest(label: String) -> bool:
	var party: RefCounted = _game.get("party") as RefCounted
	var members: Array = party.call("members")
	var best: RefCounted = null
	var rows: Array[String] = []
	for member: RefCounted in members:
		rows.append("%s %d/%d%s" % [str(member.get("species_id")), int(member.get("hp")),
			int(member.get("max_hp")), " fainted" if bool(member.get("fainted")) else ""])
		if bool(member.get("fainted")) or bool(member.get("resting")):
			continue
		if best == null or float(member.get("hp")) > float(best.get("hp")):
			best = member
	_note("PARTY before %s: %s" % [label, ", ".join(rows)])
	if best == null:
		return _fail("no conscious party member left before " + label)
	# Send-out at the real 1x/60 Hz clock with ordinary joypad LB/RB events,
	# one press at a time, waiting for each press to take effect.
	#
	# The cause of runs 12-16 (a press that changed nothing, and later "every
	# other press" dead): `_tap` held the button for two PHYSICS frames.
	# Input events are flushed once per process frame, and one process frame
	# runs several physics steps whenever it takes longer than a tick: always
	# at the wrapper's 8x/480 Hz clock, and in this heavy scene headless even
	# at 1x/60 Hz (run 14 failed there). The press and its release then
	# reached `Input` in the same flush and no physics step saw LB down; the
	# four-tick action taps lost the same race about half the time. `_tap` now
	# holds across two process frames too, and this send-out runs at 1x.
	var previous_scale := Engine.time_scale
	var previous_hz := Engine.physics_ticks_per_second
	await _tree.process_frame
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	await _tree.process_frame
	var stuck := ""
	for press in members.size():
		if party.call("active") == best:
			break
		# A player waits to see the last switch land before pressing again.
		for _frame in 240:
			if _director.call("ally_body") == null or _director.call("ally_instance") == party.call("active"):
				break
			await _tree.physics_frame
		var before: RefCounted = party.call("active")
		var frame_before := Engine.get_physics_frames()
		await _tap(&"party_cycle")
		var after: RefCounted = party.call("active")
		_note("LB press %d (joypad button, %d physics frames): active %s -> %s" % [press + 1,
			Engine.get_physics_frames() - frame_before,
			str(before.get("species_id")) if before != null else "none",
			str(after.get("species_id")) if after != null else "none"])
		if after == before:
			stuck = "LB press %d changed nothing" % (press + 1)
			break
	# LB only changes which creature is active; with nobody out (a creature
	# just rested in the camp bed is put away) the player calls it out on RB.
	if stuck.is_empty() and _director.call("ally_body") == null:
		await _tap(&"creature_recall")
	for _frame in 240:
		if _director.call("ally_instance") == best and _director.call("ally_body") != null:
			break
		await _tree.physics_frame
	await _tree.process_frame
	Engine.time_scale = previous_scale
	Engine.physics_ticks_per_second = previous_hz
	if not stuck.is_empty():
		_note("LB BINDING: %s at the 1x clock; reported, not retried" % stuck)
	if _director.call("ally_instance") != best:
		var ally: RefCounted = _director.call("ally_instance")
		var active: RefCounted = party.call("active")
		var owner := INPUT_OWNER.current(_tree)
		return _fail(("ordinary LB did not send out the fittest member before %s (best=%s active=%s ally=%s "
			+ "ally_body=%s no_usable_ally=%s arbiter_enabled=%s input_owner=%s paused=%s fighting=%s time_scale=%.1f)") % [
			label, str(best.get("species_id")), str(active.get("species_id")) if active != null else "none",
			str(ally.get("species_id")) if ally != null else "none", str(_director.call("ally_body") != null),
			str(_director.call("no_usable_ally")), str(_arbiter.call("enabled")),
			str(owner.get_path()) if owner != null else "<none>", str(_tree.paused),
			str(_manager.call("is_fighting")), Engine.time_scale])
	return true


func _equip_tool(item: String) -> bool:
	var slot := int(_game.call("hotbar_slot_of", item))
	if slot < 0:
		return _fail("campaign-earned %s is absent from the controller hotbar" % item)
	if str(_game.get("equipped_tool")) != item:
		await _tap(StringName("hotbar_%d" % (slot + 1)))
	for _frame in 90:
		if str(_game.get("equipped_tool")) == item:
			return true
		await _tree.physics_frame
	return _fail("controller hotbar did not visibly equip " + item)


func _wait_for_world_input() -> bool:
	for _frame in 900:
		if bool(_manager.call("is_fighting")):
			if not await _fight_current("Build catalogue approach"):
				return false
		if bool(_arbiter.call("enabled")) and not _tree.paused \
				and INPUT_OWNER.current(_tree) == null:
			return true
		await _tree.physics_frame
	return _fail("world input never became available for build_shortcut")


func _turn_camera_toward(world_direction: Vector3) -> bool:
	# Run 21 lost a road fight at the Still Grove road point right before this
	# turn and the stick never turned the camera. A running fight is fought
	# first (as the build menu's approach does); an armed Build ghost may own
	# input here, so only a fight or a pause is waited out.
	for _frame in 900:
		if bool(_manager.call("is_fighting")) or bool(_director.call("trainer_battle_active")):
			if not await _fight_current("Crown build stance"):
				return false
			continue
		if not _tree.paused:
			break
		await _tree.physics_frame
	# The rig reads the look stick in `_process` (render frames). Run 25 turned
	# at the wrapper's 8x/480 Hz clock and the camera drifted the wrong way
	# (forward (0.77, -0.64) -> (0.84, -0.54), wanted (0, -1)). Turn at the real
	# 1x/60 Hz clock, holding the stick across render frames, as a player does.
	var previous_scale := Engine.time_scale
	var previous_hz := Engine.physics_ticks_per_second
	await _tree.process_frame
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	await _tree.process_frame
	# A wild that won a road fight may still stand by the trainer. A player
	# resolves it first so the camera is not held on it: walk out of engage
	# range (a fight that starts on the way is fought out by the walker).
	if not await _clear_nearby_wild():
		Engine.time_scale = previous_scale
		Engine.physics_ticks_per_second = previous_hz
		return false
	var wanted := Vector2(world_direction.x, world_direction.z).normalized()
	var start_forward := -(_camera.call("planar_basis") as Basis).z
	var turned := false
	var held := &""
	for _frame in 600:
		var forward := -(_camera.call("planar_basis") as Basis).z
		if Vector2(forward.x, forward.z).normalized().dot(wanted) >= 0.995:
			turned = true
			break
		var right := -Vector3(forward.x, 0.0, forward.z).cross(world_direction).y > 0.0
		var want: StringName = &"look_right" if right else &"look_left"
		if want != held:
			_release_look()
			Input.action_press(want, 1.0)
			held = want
		await _tree.process_frame
	_release_look()
	await _tree.process_frame
	Engine.time_scale = previous_scale
	Engine.physics_ticks_per_second = previous_hz
	if turned:
		return true
	var end_forward := -(_camera.call("planar_basis") as Basis).z
	var owner := INPUT_OWNER.current(_tree)
	return _fail(("controller right stick could not face the Still Grove footing (forward %s -> %s, wanted %s; "
		+ "fighting=%s trainer_battle=%s input_owner=%s paused=%s arbiter_enabled=%s time_scale=%.1f tracking=%s)") % [
		str(start_forward), str(end_forward), str(wanted), str(_manager.call("is_fighting")),
		str(_director.call("trainer_battle_active")), str(owner.get_path()) if owner != null else "<none>",
		str(_tree.paused), str(_arbiter.call("enabled")), Engine.time_scale,
		_rig_tracking()])


## Nearest live wild within 20 m of the trainer, or null.
func _nearby_wild() -> Node3D:
	var best: Node3D = null
	var best_distance := 20.0
	for wild: Variant in (_director.get("_wild_creatures") as Array):
		if not is_instance_valid(wild) or not (wild as Node3D).visible or not bool((wild as Node3D).call("is_alive")):
			continue
		var distance := _player.global_position.distance_to((wild as Node3D).global_position)
		if distance <= best_distance:
			best = wild
			best_distance = distance
	return best


func _clear_nearby_wild() -> bool:
	var wild := _nearby_wild()
	if wild == null:
		_note("CAMERA TURN: no wild within 20 m; rig tracking=%s" % _rig_tracking())
		return true
	var start := _player.global_position
	var away := start - wild.global_position
	away.y = 0.0
	if away.length() < 0.5:
		away = Vector3(0, 0, 1)
	var fights_before := _fights_seen
	var target := start + away.normalized() * 25.0
	_note("CAMERA TURN: wild %s %.1f m away after the road fight (rig tracking=%s); walking out of engage range" % [
		str(wild.name), start.distance_to(wild.global_position), _rig_tracking()])
	await _walk_xz(Vector2(target.x, target.z), "away from the wild before the Crown turn", 2.0, false)
	if _fights_seen != fights_before:
		_note("CAMERA TURN: the wild engaged on the way and was fought out (outcome=%s)" % _last_combat_outcome)
	else:
		_note("CAMERA TURN: walked out of engage range (wild now %.1f m away)" % (
			_player.global_position.distance_to(wild.global_position) if is_instance_valid(wild) else -1.0))
	return true


func _rig_tracking() -> String:
	var tracked: Variant = _camera.get("_tracking_target")
	var target: Variant = _camera.get("_target")
	return "%s (orbit target %s)" % [
		str((tracked as Node).get_path()) if tracked is Node and is_instance_valid(tracked) else "<none>",
		str((target as Node).get_path()) if target is Node and is_instance_valid(target) else "<none>"]


func _open_build_menu() -> Node:
	for node: Node in _tree.get_nodes_in_group(BUILD_MENU_GROUP):
		if node.has_method("is_open") and bool(node.call("is_open")):
			return node
	return null


func _inventory_snapshot() -> Dictionary:
	return {"stormglass_crown": _count("stormglass_crown"),
		"thunderwood": _count("thunderwood"),
		"conductor_vine": _count("conductor_vine"),
		"thunderwood_frame": _count("thunderwood_frame")}


func _count(item: String) -> int:
	return int(_game.get("inventory").call("count", item))


func _grounded(point: Vector2) -> Vector3:
	return Vector3(point.x, float(_world.call("ground_height_at", point.x, point.y)), point.y)


func _wait_flag(id: String, frames: int) -> bool:
	for _frame in frames:
		if bool(_game.get("progression").call("has", id)):
			return true
		await _tree.physics_frame
	return false


func _tap(action: StringName) -> void:
	if action == &"interact":
		var winner := _arbiter.call("winning_provider") as Node if _arbiter != null else null
		_gather_events.append("%d interact press winner=%s" % [Time.get_ticks_msec(),
			str(winner.get_path()) if winner != null and is_instance_valid(winner) else "<none>"])
	var binding: InputEvent = null
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			binding = event
			break
	if binding == null:
		_fail("%s has no physical joypad binding" % action)
		return
	if binding is InputEventJoypadButton:
		var press := InputEventJoypadButton.new()
		press.button_index = (binding as InputEventJoypadButton).button_index
		press.pressed = true
		Input.parse_input_event(press)
		await _hold_edge(2)
		var release := press.duplicate() as InputEventJoypadButton
		release.pressed = false
		Input.parse_input_event(release)
	else:
		var motion := InputEventJoypadMotion.new()
		motion.axis = (binding as InputEventJoypadMotion).axis
		motion.axis_value = (binding as InputEventJoypadMotion).axis_value
		Input.parse_input_event(motion)
		await _hold_edge(2)
		var neutral := motion.duplicate() as InputEventJoypadMotion
		neutral.axis_value = 0.0
		Input.parse_input_event(neutral)
	await _hold_edge(4)


## Hold an input state for at least `physics` physics frames AND two process
## frames. Input events reach `Input` once per process frame; at a clock that
## runs several physics steps per process frame, waiting on physics frames
## alone let a press and its release land in the same flush, so no physics
## step saw the button down (the dead LB presses of runs 12-16).
func _hold_edge(physics: int) -> void:
	var physics_start := Engine.get_physics_frames()
	var process_start := Engine.get_process_frames()
	while Engine.get_physics_frames() - physics_start < physics \
			or Engine.get_process_frames() - process_start < 2:
		await _tree.physics_frame


func _set_action(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


func _drive_stick(x: float, y: float) -> void:
	Input.action_press(&"move_right", clampf(x, 0.0, 1.0))
	Input.action_press(&"move_left", clampf(-x, 0.0, 1.0))
	Input.action_press(&"move_back", clampf(y, 0.0, 1.0))
	Input.action_press(&"move_forward", clampf(-y, 0.0, 1.0))
	if is_zero_approx(x):
		Input.action_release(&"move_right")
		Input.action_release(&"move_left")
	if is_zero_approx(y):
		Input.action_release(&"move_back")
		Input.action_release(&"move_forward")


func _release_look() -> void:
	Input.action_release(&"look_right")
	Input.action_release(&"look_left")


func _settle(frames: int) -> void:
	for _frame in frames:
		await _tree.physics_frame


## Every provider activated during one press, in order, with where the
## trainer stood (run 26: a press held on Officer Nysa reported circuit Tavi).
var _activations: Array[String] = []


func _on_arbiter_activated(provider: Object) -> void:
	if provider == null:
		return
	_activations.append("%s@%s" % [str((provider as Node).get_path()) if provider is Node else str(provider),
		str(_player.global_position) if _player != null else "?"])
	_activated_provider_id = provider.get_instance_id()
	_activated_provider_path = str((provider as Node).get_path()) if provider is Node else str(provider)


func _on_combat_exited(outcome: String) -> void:
	_last_combat_outcome = outcome


func _note(message: String) -> void:
	transcript.append(message)
	print("STORMWOOD CROWN BUILD — ", message)


func _fail(message: String) -> bool:
	failures.append(message)
	push_error("STORMWOOD CROWN BUILD: " + message)
	return false
