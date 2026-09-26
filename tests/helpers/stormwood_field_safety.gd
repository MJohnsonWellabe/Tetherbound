extends RefCounted

## What a player walking Stormwood does about lightning, for the earned F11
## witness walkers (the continuous prefix Segment and the Crown-chain helpers).
##
## - Reads the production strike warnings (`Session.stormwood_strike_received`,
##   the same events that draw the magenta ring) and, while a live warning's
##   3 m radius holds the trainer, steers the stick straight out of it.
## - Logs every warning, dodge, hit (damage and the trainer's health left) and
##   finalized death with what the walker was doing at the time.
## - After a death, walks back to the dropped satchel and takes everything out
##   of it through its own "Open Satchel" prompt and storage panel.
##
## Nothing here moves the trainer, writes health, or grants items.

const MARGIN_M := 1.5
const WARNING_FRAMES := 240

var tree: SceneTree
var world: Node3D
var game: Node
var player: CharacterBody3D
var camera: Node3D
var drive_stick: Callable
var radius_m := 3.0
var phase := ""
var counts := {"warnings": 0, "threats": 0, "dodge_frames": 0, "hits": 0, "damage": 0.0, "deaths": 0,
	"satchel_recoveries": 0, "satchel_stacks": 0}
var _warnings: Dictionary = {}
var _pending_satchel := false
var _recovering := false


func attach(p_tree: SceneTree, p_world: Node3D, p_game: Node, p_player: CharacterBody3D,
		p_camera: Node3D, p_drive_stick: Callable) -> void:
	tree = p_tree
	world = p_world
	game = p_game
	player = p_player
	camera = p_camera
	drive_stick = p_drive_stick
	var lightning := world.get_node_or_null(^"StormwoodLightning")
	if lightning != null:
		radius_m = float(lightning.get("rules").config.strike.radius_m)
	var session: Node = game.get("session")
	if session != null and not session.stormwood_strike_received.is_connected(_on_strike):
		session.stormwood_strike_received.connect(_on_strike)
	var death := tree.get_first_node_in_group(&"player_death")
	if death != null and death.has_signal("finalized_death") \
			and not death.finalized_death.is_connected(_on_death):
		death.finalized_death.connect(_on_death)


func detach() -> void:
	var session: Node = game.get("session") if game != null else null
	if session != null and session.stormwood_strike_received.is_connected(_on_strike):
		session.stormwood_strike_received.disconnect(_on_strike)
	var death := tree.get_first_node_in_group(&"player_death") if tree != null else null
	if death != null and death.finalized_death.is_connected(_on_death):
		death.finalized_death.disconnect(_on_death)


func _on_strike(event: Dictionary) -> void:
	var id := int(event.get("id", -1))
	match str(event.get("kind", "")):
		"warning":
			counts.warnings += 1
			_warnings[id] = {"at": event.get("at", Vector3.ZERO), "frame": Engine.get_physics_frames()}
		"impact":
			_warnings.erase(id)
			var session: Node = game.get("session")
			var hits: Dictionary = event.get("hits", {})
			if session != null and hits.has(session.local_peer_id()):
				var effect: Dictionary = hits[session.local_peer_id()]
				var vitals: RefCounted = player.get("vitals")
				counts.hits += 1
				counts.damage += float(effect.get("damage", 0.0))
				print("F11 STRIKE HIT during '%s' at %s damage=%.1f health_left=%.1f/%.1f" % [phase,
					str(player.global_position), float(effect.get("damage", 0.0)),
					float(vitals.get("health")) if vitals != null else -1.0,
					float(vitals.get("max_health")) if vitals != null else -1.0])


func _on_death() -> void:
	counts.deaths += 1
	_pending_satchel = true
	print("F11 TRAINER DEATH during '%s' at %s; strikes so far %s" % [phase, str(player.global_position),
		JSON.stringify(counts)])


## The centre of a live warning whose radius (plus a margin) holds the trainer.
func threat() -> Variant:
	var now := Engine.get_physics_frames()
	var here := player.global_position
	for id: Variant in _warnings.keys():
		var row: Dictionary = _warnings[id]
		if now - int(row.frame) > WARNING_FRAMES:
			_warnings.erase(id)
			continue
		var at: Vector3 = row.at
		if Vector2(here.x - at.x, here.z - at.z).length() <= radius_m + MARGIN_M:
			return at
	return null


## One physics frame of stepping out of a warning. False when none threatens.
func dodge_step(toward: Vector3 = Vector3.INF) -> bool:
	var at: Variant = threat()
	if at == null:
		return false
	counts.dodge_frames += 1
	var away := player.global_position - (at as Vector3)
	away.y = 0.0
	if away.length() < 0.2:
		# Standing on the centre: step sideways relative to the way ahead.
		var ahead := (toward - player.global_position) if toward.is_finite() else Vector3.FORWARD
		ahead.y = 0.0
		away = ahead.cross(Vector3.UP)
	if away.length_squared() < 0.0001:
		away = Vector3.RIGHT
	var local := (camera.call("planar_basis") as Basis).inverse() * away.normalized()
	drive_stick.call(local.x, local.z)
	await tree.physics_frame
	return true


func needs_recovery() -> bool:
	return _pending_satchel and not _recovering


## Walk back to this trainer's newest satchel and take everything out of it.
## `walk` is the caller's own `_walk_xz(point, label, tolerance) -> bool`;
## `activate` its `(body, prompt, preferred, label) -> bool` prompt driver.
func recover(walk: Callable, activate: Callable) -> bool:
	_recovering = true
	var ok := await _recover(walk, activate)
	_recovering = false
	return ok


func _recover(walk: Callable, activate: Callable) -> bool:
	var satchel: Node3D = null
	for _frame in 600:
		for node: Node in tree.get_nodes_in_group(&"death_satchel"):
			if world.is_ancestor_of(node) and bool(node.call("can_open")):
				satchel = node as Node3D
		if satchel != null:
			break
		await tree.physics_frame
	if satchel == null:
		print("F11 SATCHEL none found after the death")
		return false
	var prompt := satchel.get_node_or_null(^"Interactable") as Node3D
	var at := Vector2(satchel.global_position.x, satchel.global_position.z)
	print("F11 SATCHEL walking back to %s from %s" % [str(satchel.global_position), str(player.global_position)])
	if not bool(await walk.call(at + Vector2(0.0, -1.2), "own death satchel", 1.0)):
		return false
	if not bool(await activate.call(satchel, prompt, at + Vector2(0.0, -1.2), "own death satchel")):
		return false
	# The satchel can be freed under us: the ledger removes an emptied
	# satchel, and a reload or realm change rebuilds the world. Never touch
	# a freed instance; the panel is the satchel script's shared screen.
	var panel: Node = null
	for _frame in 60:
		if not is_instance_valid(satchel):
			print("F11 SATCHEL was freed before its panel opened")
			return false
		panel = satchel.get("_panel") as Node
		if panel != null and bool(panel.call("is_open")):
			break
		await tree.process_frame
	if panel == null or not is_instance_valid(panel) or not bool(panel.call("is_open")):
		print("F11 SATCHEL panel did not open")
		return false
	# Ordinary pad input on the open panel: focus the satchel's column (the
	# right-hand one; the trainer's own satchel is on the left), then A takes
	# the focused stack. The panel refocuses the same column after each move.
	var taken := 0
	for _press in 32:
		if not is_instance_valid(panel) or not bool(panel.call("is_open")):
			break
		var rows: Array = panel.get("_withdraw_rows")
		if rows.is_empty():
			break
		if not rows.has(tree.root.gui_get_focus_owner()):
			await _ui_tap(&"ui_right")
		if not rows.has(tree.root.gui_get_focus_owner()):
			print("F11 SATCHEL pad right did not focus the satchel column (focus=%s)" % str(tree.root.gui_get_focus_owner()))
			return false
		var before := rows.size()
		await _ui_tap(&"ui_accept")
		var moved := false
		for _frame in 60:
			if not is_instance_valid(panel) or not bool(panel.call("is_open")) \
					or (panel.get("_withdraw_rows") as Array).size() < before:
				moved = true
				break
			await tree.process_frame
		if not moved:
			print("F11 SATCHEL pad A on a satchel row took nothing")
			return false
		taken += 1
	if is_instance_valid(panel) and bool(panel.call("is_open")):
		await _ui_tap(&"menu_cancel")
	for _frame in 30:
		if not is_instance_valid(panel) or not bool(panel.call("is_open")):
			break
		await tree.process_frame
	if is_instance_valid(panel) and bool(panel.call("is_open")):
		print("F11 SATCHEL pad B did not close the satchel panel")
		return false
	_pending_satchel = false
	counts.satchel_recoveries += 1
	counts.satchel_stacks += taken
	print("F11 SATCHEL recovered %d stack(s); knife x%d axe x%d pickaxe x%d" % [taken,
		int(game.get("inventory").call("count", "knife")), int(game.get("inventory").call("count", "axe")),
		int(game.get("inventory").call("count", "pickaxe"))])
	return true


## One ordinary pad press on a panel, as an action event held across three
## process frames so the focused Button sees both halves.
func _ui_tap(action: StringName) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		event.strength = 1.0 if pressed else 0.0
		Input.parse_input_event(event)
		for _frame in 4:
			await tree.process_frame
