extends SceneTree

## T5-CARE: one free-play session covering the section H loops a player
## actually lives in — gathering, opening Build, placing, dismantling, and
## dying twice.
##
##   godot --headless --path . --script tools/_play_t5_freeplay.gd
##
## One harness rather than four because the Meadows costs several minutes to
## build and the questions all want the same world: a player standing outdoors,
## post-opening, with a hammer.
##
## WHY FREE PLAY. An earlier run of `tools/_play_t5_gather_craft.gd` booted
## without `opening:beat:free_play` and reported that the player "could not walk
## 14m to the nearest harvest node in 40 seconds". That was an artifact, not a
## finding: at the wake beat `sequence_director.gd` puts the player in Grandpa's
## bed and lies them down, so the harness was driving a stick at a body that was
## asleep indoors. Recorded here because it is exactly the shape of evidence the
## exit criterion's evidence rule warns about — it looked like a damning
## gathering result and it was a harness that had not read the opening.
##
## THE CENTREPIECE is the Build press. `gate_a_build_segment.gd` records, in its
## own words, that "hammer + interact is the ONLY pad route into build mode"
## under CONTROLLER-MAP, and that the press is forfeited to any ACTIONABLE
## interaction-arbiter winner — "a wandering creature's Engage or a nearby
## harvest node's Chop is enough to swallow the only pad route into build mode".
## This world scatters 57,839 harvestable props. So the question this run exists
## to answer is: standing in an ordinary spot in the Meadows, with the hammer in
## hand, does pressing the build button open Build — or chop a bush?

const SCENE := "res://scenes/world/meadows_playground.tscn"
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const SETTLE_FRAMES := 300
const INTERACT_ACTION := "interact"
const HOTBAR_ACTIONS: Array[String] = [
	"hotbar_1", "hotbar_2", "hotbar_3", "hotbar_4", "hotbar_5",
]
## Ordinary open ground: the Practice Meadow clearing the opening builds in.
const PATCH := Vector2(30.0, -40.0)

var _game: Node
var _world: Node3D
var _player: CharacterBody3D
var _rig: Node3D
var _nav = null
var _notes: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_game = root.get_node_or_null(^"Game")
	_game.get("progression").call("set_flag", "opening:beat:free_play")
	_world = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	if _player == null or _rig == null:
		print("T5> BLOCKED: no player/rig")
		quit(1)
		return
	_nav = NAVIGATOR.new(self, _player, _rig, Callable(self, "_drive_stick"))

	await _stand_on_the_patch()
	await _gathering()
	await _the_build_press()
	await _place_and_dismantle()
	await _two_deaths()

	print("")
	print("T5> === free-play session observations ===")
	for line in _notes:
		print("T5> " + line)
	quit(0)


func _stand_on_the_patch() -> void:
	var ground := float(_world.call("ground_height_at", PATCH.x, PATCH.y))
	_player.global_position = Vector3(PATCH.x, ground + 1.0, PATCH.y)
	_player.velocity = Vector3.ZERO
	for i in 120:
		await physics_frame
	var mobile := true
	if _player.has_method("locomotion_enabled"):
		mobile = bool(_player.call("locomotion_enabled"))
	_notes.append("session: standing at %s, locomotion_enabled=%s" % [
		str(_player.global_position.round()), str(mobile)])


## Walk to the nearest harvest node and take it. Prices the trip.
func _gathering() -> void:
	var nodes: Array[Node3D] = []
	for node in _world.find_children("*", "", true, false):
		if node.has_method("resource_item") and node.has_method("resource_amount"):
			var n3 := node as Node3D
			if n3 != null:
				nodes.append(n3)
	_notes.append("I4 supply: %d harvestable nodes in the world" % nodes.size())
	var here := _player.global_position
	var best: Node3D = null
	var best_d := INF
	for n3 in nodes:
		var d := Vector2(n3.global_position.x, n3.global_position.z) \
			.distance_to(Vector2(here.x, here.z))
		if d < best_d and d > 0.5:
			best_d = d
			best = n3
	if best == null:
		_notes.append("I4: no harvest node found near the build patch")
		return
	var item := str(best.call("resource_item"))
	var yield_n := int(best.call("resource_amount"))
	_notes.append("I4: nearest node is %.1fm away and yields %d x %s" % [best_d, yield_n, item])

	var inventory: RefCounted = _game.get("inventory")
	var before := int(inventory.call("count", item))
	var target := best.global_position
	var stand := target + (here - target).normalized() * 1.5
	stand.y = _player.global_position.y
	var arrived: bool = await _nav.walk_to(stand, 2400, 1.2)
	_release_stick_actions()
	var away := Vector2(_player.global_position.x, _player.global_position.z) \
		.distance_to(Vector2(target.x, target.z))
	if not arrived:
		_notes.append("I4 VERDICT: could not reach a node %.1fm away in 40s of stick "
			% best_d + "(stopped %.1fm off)." % away)
		return
	var button := _pad_button_for(INTERACT_ACTION)
	var presses := 0
	for attempt in 8:
		await _pad(button)
		presses += 1
		if int(inventory.call("count", item)) > before:
			break
	var gained := int(inventory.call("count", item)) - before
	if gained > 0:
		_notes.append("I4 VERDICT: PASS — walked %.1fm, %d interact press(es), got %d x %s."
			% [best_d, presses, gained, item])
	else:
		_notes.append("I4 VERDICT: FAIL — standing %.1fm from the node, %d interact presses "
			% [away, presses] + "gathered nothing.")


## THE question for H1: does the only pad route into Build actually open Build?
func _the_build_press() -> void:
	var inventory: RefCounted = _game.get("inventory")
	if int(inventory.call("count", "hammer")) <= 0:
		inventory.call("add", "hammer", 1)
	var slot := int(inventory.call("find_slot", "hammer"))
	if slot < 0 or slot >= HOTBAR_ACTIONS.size():
		_notes.append("H1: the hammer is in satchel slot %d, past the %d quick-bar slots, so "
			% [slot, HOTBAR_ACTIONS.size()] + "the pad cannot draw it at all")
		return
	await _pad(_pad_button_for(HOTBAR_ACTIONS[slot]))
	var equipped := str(_game.get("equipped_tool"))
	_notes.append("H1: pressed quick-bar slot %d; equipped_tool is now '%s'" % [slot + 1, equipped])
	if equipped != "hammer":
		_notes.append("H1 VERDICT: FAIL — the quick-bar press did not put the hammer in hand.")
		return

	# Who is bidding for the interact button where the player is standing?
	var arbiter: Node = get_first_node_in_group(&"interaction_arbiter")
	var winner_name := "<none>"
	var winner_label := "<none>"
	if arbiter != null:
		var who: Variant = arbiter.call("winning_provider")
		if who is Node and is_instance_valid(who as Object):
			winner_name = (who as Node).name
		winner_label = str(arbiter.call("winner"))
	_notes.append("H1: standing on the build patch, the interaction arbiter's winner is %s (%s)" % [
		winner_name, winner_label])

	var before_open := _build_menu() != null
	await _pad(_pad_button_for(INTERACT_ACTION))
	for i in 40:
		await physics_frame
	var opened := _build_menu() != null
	if opened:
		_notes.append("H1 VERDICT: PASS — hammer in hand, one interact press opened Build.")
	else:
		_notes.append("H1 VERDICT: FAIL — hammer in hand, the interact press did NOT open Build. "
			+ "The arbiter winner (%s) took the button. Under CONTROLLER-MAP this is the ONLY "
			% winner_name + "pad route into build mode, and this world scatters ~58,000 "
			+ "harvestable props for a 'Chop' prompt to win with.")
	if opened:
		_build_menu().call("close") if _build_menu().has_method("close") else null
		for i in 10:
			await physics_frame


## Place a camp and a creature bed, then dismantle one and check the refund.
func _place_and_dismantle() -> void:
	var inventory: RefCounted = _game.get("inventory")
	for id in ["wood", "stone", "fiber"]:
		inventory.call("add", id, 200)
	var placer := _find_placer()
	if placer == null:
		_notes.append("H1/H3: no BuildPlacer in the world")
		return
	var records: Array = _game.get("placed_buildings") as Array
	var before_n := records.size()
	var wood_before := int(inventory.call("count", "wood"))

	for piece in ["camp", "creature_bed"]:
		_game.set("pending_build", piece)
		for i in 30:
			await physics_frame
		var ghost: Node3D = placer.get("_ghost") as Node3D
		var reason := str(placer.get("_ghost_reason"))
		if ghost == null:
			_notes.append("H1: arming '%s' produced no ghost" % piece)
			continue
		_notes.append("H1: '%s' ghost stands at %s, refusal reason: %s" % [
			piece, str(ghost.global_position.round()),
			"(none — placeable)" if reason.is_empty() else reason])
		await _pad(_pad_button_for("build_place"))
		for i in 20:
			await physics_frame
	_game.set("pending_build", "")
	for i in 20:
		await physics_frame

	var after: Array = _game.get("placed_buildings") as Array
	var placed := after.size() - before_n
	var wood_spent := wood_before - int(inventory.call("count", "wood"))
	_notes.append("H1: two Place presses added %d building record(s) and spent %d wood" % [
		placed, wood_spent])

	var progression: RefCounted = _game.get("progression")
	_notes.append("H1 flags: home_built=%s, creature_bed_built=%s" % [
		str(bool(progression.call("has", "home_built"))),
		str(bool(progression.call("has", "creature_bed_built")))])

	# Dismantle: aim at what was just placed and press the dismantle button.
	if placed > 0:
		var wood_pre := int(inventory.call("count", "wood"))
		var n_pre := (_game.get("placed_buildings") as Array).size()
		await _pad(_pad_button_for("build_dismantle"))
		for i in 30:
			await physics_frame
		var n_post := (_game.get("placed_buildings") as Array).size()
		var refunded := int(inventory.call("count", "wood")) - wood_pre
		if n_post < n_pre:
			_notes.append("H1 dismantle: PASS — one press removed a piece (%d -> %d records) "
				% [n_pre, n_post] + "and refunded %d wood." % refunded)
		else:
			_notes.append("H1 dismantle: one press removed nothing (%d records still standing). "
				% n_post + "Dismantle needs the player aimed at the piece from within 8m.")


## Two deaths in two places: do both satchels persist?
func _two_deaths() -> void:
	var inventory: RefCounted = _game.get("inventory")
	var spots: Array[Vector3] = []
	for i in 2:
		inventory.call("add", "wood", 10 + i)
		var here := _player.global_position
		spots.append(here)
		_player.global_position = here + Vector3.UP * 90.0
		_player.velocity = Vector3.ZERO
		for f in 400:
			await physics_frame
			if float((_player.get("vitals") as RefCounted).get("health")) <= 0.0:
				break
		for f in 240:
			await physics_frame
		(_player.get("vitals") as RefCounted).set("health", 100.0)
		# Move somewhere else for the second death so the two satchels are
		# distinguishable, the way two real deaths would be.
		if i == 0:
			_player.global_position = _player.global_position + Vector3(14.0, 0.0, 9.0)
			for f in 90:
				await physics_frame

	var satchels: Array = _game.get("death_satchels") as Array
	_notes.append("H/inventory: after two deaths, %d death satchel(s) persist" % satchels.size())
	for i in satchels.size():
		var entry: Dictionary = satchels[i]
		var pos: Array = entry.get("position", [])
		_notes.append("H/inventory:   satchel %d at (%.1f, %.1f, %.1f)" % [
			i + 1, float(pos[0]), float(pos[1]), float(pos[2])] if pos.size() == 3
			else "H/inventory:   satchel %d has no position" % (i + 1))
	if satchels.size() >= 2:
		_notes.append("H/inventory VERDICT: PASS — multiple death satchels persist, as the "
			+ "hard rule requires; neither replaced the other.")
	elif satchels.size() == 1:
		_notes.append("H/inventory VERDICT: only ONE satchel after two deaths — the second "
			+ "death did not leave one (or replaced the first).")
	var map: RefCounted = _game.get("map")
	if map != null and map.has_method("markers"):
		_notes.append("H/inventory: map markers = %s" % str(map.call("markers")).left(220))


# --- helpers ---------------------------------------------------------------

func _build_menu() -> Node:
	var found: Node = get_first_node_in_group(&"build_menu")
	return found if found != null and is_instance_valid(found) else null


func _find_placer() -> Node:
	for node in _world.find_children("*", "", true, false):
		var script := node.get_script() as Script
		if script != null and script.resource_path.ends_with("build_placer.gd"):
			return node
	return null


func _pad_button_for(action: String) -> int:
	if not InputMap.has_action(action):
		return -1
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			return button.button_index
	return -1


func _pad(button_index: int) -> void:
	if button_index < 0:
		return
	var down := InputEventJoypadButton.new()
	down.button_index = button_index
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	var up := InputEventJoypadButton.new()
	up.button_index = button_index
	up.pressed = false
	Input.parse_input_event(up)
	for i in 8:
		await process_frame


## `stick_navigator.gd`'s fourth argument is the stick DRIVER and it is called
## every frame with the x/y to hold — a no-argument callback silently means the
## navigator pushes nothing and the player never moves.
func _drive_stick(x: float, y: float) -> void:
	Input.action_press(&"move_right", clampf(x, 0.0, 1.0))
	Input.action_press(&"move_left", clampf(-x, 0.0, 1.0))
	Input.action_press(&"move_back", clampf(y, 0.0, 1.0))
	Input.action_press(&"move_forward", clampf(-y, 0.0, 1.0))


func _release_stick_actions() -> void:
	for action: StringName in [&"move_right", &"move_left", &"move_back", &"move_forward"]:
		Input.action_release(action)
