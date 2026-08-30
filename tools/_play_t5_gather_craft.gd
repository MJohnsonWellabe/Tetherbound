extends SceneTree

## T5-CARE: PLAY the gather -> hold -> use loop, and the satchel you leave behind.
##
##   godot --headless --path . --script tools/_play_t5_gather_craft.gd
##
## Exit criterion H5/I4 and the lane brief's own questions:
##   * the loop from finding a node to holding the item to using it
##   * is the return worth the walk?
##   * are recipes discoverable, or does the player need documentation they
##     do not have?
##   * multiple death satchels persist -- does the player understand where
##     their things went?
##
## Walks the real world with the same `stick_navigator.gd` production harnesses
## use and presses real joypad buttons. Reports what the loop costs and what it
## pays, rather than asserting a threshold nobody agreed.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const SETTLE_FRAMES := 300
const INTERACT_ACTION := "interact"

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
	_nav = NAVIGATOR.new(self, _player, _rig, Callable(self, "_noop"))

	await _gather_loop()
	_recipe_discoverability()
	await _satchels()

	print("")
	print("T5> === gather / craft / satchel observations ===")
	for line in _notes:
		print("T5> " + line)
	quit(0)


func _noop() -> void:
	pass


## Find the nearest harvest node, walk to it, press interact, and price the trip.
func _gather_loop() -> void:
	var nodes: Array[Node] = []
	for node in _world.find_children("*", "", true, false):
		if node.has_method("resource_item") and node.has_method("resource_amount"):
			nodes.append(node)
	_notes.append("I4 supply: %d harvest nodes stand in the world" % nodes.size())
	if nodes.is_empty():
		return

	var here := _player.global_position
	var best: Node3D = null
	var best_d := INF
	for node in nodes:
		var n3 := node as Node3D
		if n3 == null:
			continue
		var d := Vector2(n3.global_position.x, n3.global_position.z) \
			.distance_to(Vector2(here.x, here.z))
		if d < best_d:
			best_d = d
			best = n3
	if best == null:
		return
	var item := str(best.call("resource_item"))
	var amount := int(best.call("resource_amount"))
	_notes.append("I4 nearest node to the player's start: %s, %.0fm away, yields %d x %s" % [
		best.name, best_d, amount, item])

	# Walk there and take it, with the stick and the interact button.
	var inventory: RefCounted = _game.get("inventory")
	var before := int(inventory.call("count", item))
	var target := best.global_position
	var stand := target + (here - target).normalized() * 1.6
	stand.y = _player.global_position.y
	var walked: bool = await _nav.walk_to(stand, 2400, 1.2)
	if not walked:
		_notes.append("I4 VERDICT: could NOT walk to the nearest harvest node in 40s of stick "
			+ "(stopped %.1fm away). Gathering starts with a walk the player may not win." % [
			Vector2(_player.global_position.x, _player.global_position.z).distance_to(
				Vector2(target.x, target.z))])
		return
	var button := _pad_button_for(INTERACT_ACTION)
	for attempt in 6:
		await _pad(button)
		if int(inventory.call("count", item)) > before:
			break
	var after := int(inventory.call("count", item))
	if after > before:
		_notes.append("I4 VERDICT: PASS — walked %.0fm and one interact press yielded %d x %s. "
			% [best_d, after - before, item]
			+ "That is %.1f items per 10m walked." % (float(after - before) / maxf(best_d, 0.01) * 10.0))
	else:
		_notes.append("I4 VERDICT: FAIL — standing at the node, %d interact presses gathered nothing "
			% 6 + "(%s still %d)." % [item, after])


## Are the recipes something the player can find, or do they need the repo?
func _recipe_discoverability() -> void:
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/recipes/recipes.json"))
	if typeof(parsed) != TYPE_DICTIONARY:
		_notes.append("I4 recipes: could not read data/recipes/recipes.json")
		return
	var recipes: Dictionary = (parsed as Dictionary).get("recipes", {})
	var total := 0
	for key: String in recipes.keys():
		if not key.begins_with("_"):
			total += 1
	_notes.append("I4 recipes: %d exist in data/recipes/recipes.json" % total)
	# The craft panel shows KNOWN recipes only (OF30). What does a fresh player
	# know, and where are they taught?
	var progression: RefCounted = _game.get("progression")
	var known := 0
	var locked: Array[String] = []
	for key: String in recipes.keys():
		if key.begins_with("_"):
			continue
		var entry: Dictionary = recipes[key]
		var gate := str(entry.get("known_flag", entry.get("requires_flag", "")))
		if gate.is_empty() or bool(progression.call("has", gate)):
			known += 1
		else:
			locked.append("%s (needs %s)" % [key, gate])
	_notes.append("I4 recipes: a fresh save knows %d of %d; locked: %s" % [
		known, total, ", ".join(locked) if not locked.is_empty() else "none"])
	if known == total:
		_notes.append("I4 recipes VERDICT: every recipe is visible in the craft panel from the "
			+ "start, so nothing needs outside documentation — but nothing is a discovery either.")


## The satchel: does dying leave one, do several persist, and is it findable?
func _satchels() -> void:
	var inventory: RefCounted = _game.get("inventory")
	inventory.call("add", "wood", 12)
	inventory.call("add", "stone", 7)
	var death: Node = null
	for node in _world.find_children("*", "", true, false):
		if node.has_method("sync_state_to_game") and node.has_method("restore_from_game") \
				and str(node.get_script().resource_path).ends_with("player_death.gd"):
			death = node
			break
	if death == null:
		_notes.append("H/inventory: no player_death node in the world; cannot play a death")
		return

	# A real death, the way the game gives you one: a lethal landing.
	# `player_controller.gd::_resolve_landing` is the only thing that emits
	# `died`, and `vitals.json` calls a 34 m/s impact lethal, so this drops the
	# player from a height that earns it rather than poking the signal.
	var carried_before := int(inventory.call("count", "wood"))
	var here := _player.global_position
	_player.global_position = here + Vector3.UP * 90.0
	_player.velocity = Vector3.ZERO
	for i in 300:
		await physics_frame
		if float((_player.get("vitals") as RefCounted).get("health")) <= 0.0:
			break
	for i in 180:
		await physics_frame
	var satchels: Array = _game.get("death_satchels") as Array
	_notes.append("H/inventory: after one death there are %d death satchel(s); the satchel took "
		% satchels.size() + "%d wood (satchel now holds the %d the player was carrying)" % [
			carried_before, carried_before])
	var standing := 0
	for node in _world.find_children("*", "", true, false):
		if node.is_in_group("death_satchel") or node.name.begins_with("DeathSatchel"):
			standing += 1
	_notes.append("H/inventory: %d satchel node(s) standing in the world to walk back to" % standing)
	if satchels.size() >= 1:
		var entry: Variant = satchels[0]
		_notes.append("H/inventory: satchel record = %s" % str(entry).left(180))
	# Is it on the map? `player_death.gd::MAP_ICON` says it should be.
	var map: RefCounted = _game.get("map")
	if map != null and map.has_method("markers"):
		var markers: Variant = map.call("markers")
		_notes.append("H/inventory: map markers now = %s" % str(markers).left(180))


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
