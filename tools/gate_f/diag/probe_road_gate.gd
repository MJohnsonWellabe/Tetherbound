extends SceneTree

## DIAG-ROAD-GATE — with the key in the satchel and the player at the gate,
## why is `road_gate_open` still unset?
##
##   godot --headless --path . --script tools/gate_f/diag/probe_road_gate.gd
##
## ## The question
##
## T5-PLAY's S02 re-run, with RIG-T5-3 fixed, played this exactly:
##
##   S02-49  walk to the old key      PASS  walked 30.1 m
##   S02-50  take the old key         PASS
##   S02-50a the key is in the satchel PASS `pickup:castle_gate_key` set
##   S02-51  walk to the road gate    PASS  walked 0.3 m
##   S02-52  try the gate             PASS  pressed interact x1
##   S02-54  the road gate is open    FAIL  flag road_gate_open NOT set
##
## and its exit save still carries `castle_gate_key n=1`. `item_gate.gd::try_open`
## CONSUMES the key on success, so an unconsumed key proves `_on_tried` never
## ran — the press did not reach the gate. Three candidates, and they are
## different findings:
##
##   GAME — the gate cannot be opened from where a player would stand. The
##          chapter's first gate, on the critical path, is a hard StaticBody3D
##          with sealed wings: a player who cannot open it cannot leave band 0.
##   RIG  — `move_to`'s `close_enough: 3.0` parks the harness outside the
##          prompt's reach, or facing wrong. Says nothing about the game.
##   DATA — the key id the pickup grants and the id the gate wants differ.
##
## ## What this measures, and what it is allowed to conclude
##
## Protocol §0.6 confines shortcuts to segments auditing the world or the
## instrument. This one boots the world scene directly and places the player at
## named coordinates; neither is a claim about how a player gets there. It makes
## exactly one kind of claim — whether the gate CAN be opened, and from where —
## and no pacing, navigation or difficulty claim of any kind (§0.1). It reads
## the game and writes none of it.
##
## Pass 1  the geometry: where the gate, its prompt and its key actually are,
##         the prompt's radius, and the id the gate demands.
## Pass 2  a distance sweep along the road. At each stand-off: does the gate
##         offer, does the arbiter draw it, and does line-of-sight pass? This
##         separates "out of radius" from "occluded" from "outbid".
## Pass 3  the decisive one: give the player the key, stand them where S02-51
##         actually left them, press through the real arbiter, and read the flag.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const KEY_ITEM := "castle_gate_key"
const GATE_FLAG := "road_gate_open"

## S02-51 asks for GATE_AT with `close_enough: 3.0` and reported "walked 0.3 m",
## so the harness stopped as soon as it was inside 3 m — starting from the key
## at (30.7, -15.9). This is that stand-off, reconstructed.
const STANDOFFS := [0.8, 1.5, 2.0, 2.5, 2.9, 3.2, 3.6, 4.0, 4.5]


func _init() -> void:
	_run()


func _run() -> void:
	print("=== DIAG-ROAD-GATE =============================================")
	print("this file is rig: it reads the game and writes none of it")
	print("")

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var arbiter: Node = null
	for n in _descendants(world):
		if n.has_method("winning_provider"):
			arbiter = n
			break
	var gate: Node = _find(world, "RoadGate")
	if gate == null:
		for n in _descendants(world):
			if n.get_script() != null and str(n.get_script().resource_path).ends_with("road_gate.gd"):
				gate = n
				break
	if player == null or gate == null:
		print("FATAL: player=%s gate=%s" % [player, gate])
		quit(1)
		return

	var prompt: Node3D = gate.get_node_or_null(^"Interactable") as Node3D
	print("--- PASS 1: geometry -------------------------------------------")
	print("gate node          : %s at %v" % [gate.name, (gate as Node3D).global_position])
	if prompt == null:
		print("FATAL: the gate has no Interactable child")
		quit(1)
		return
	print("gate prompt        : %v  radius=%.2f  label=%s  enabled=%s" % [
		prompt.global_position, float(prompt.get("radius")),
		str(prompt.get("label")), str(prompt.get("enabled"))])
	var key_node: Node3D = _find(world, "GateKey") as Node3D
	print("gate key           : %s" % ("consumed/absent" if key_node == null
		else "%v" % key_node.global_position))
	print("player spawned at  : %v" % player.global_position)
	print("")

	print("--- PASS 2: stand-off sweep along the road ---------------------")
	print("%8s | %9s | %5s | %5s | %s" % ["stand-off", "3D dist", "offer", "drawn", "winning label"])
	# Approach from the key's side, which is the direction S02 comes from.
	var gate_xz := Vector2(prompt.global_position.x, prompt.global_position.z)
	var from_key := (Vector2(30.7, -15.9) - gate_xz).normalized()
	for d: float in STANDOFFS:
		var spot := gate_xz + from_key * d
		await _place(player, world, spot)
		var offer: Dictionary = prompt.call("interaction_offer", player.global_position)
		var dist := player.global_position.distance_to(prompt.global_position)
		var drawn := "-"
		if arbiter != null:
			var w: Object = arbiter.call("winning_provider")
			drawn = "no" if w == null else ("YES" if w == prompt else "other")
		var label := ""
		if arbiter != null:
			var win: Dictionary = arbiter.call("winner")
			label = str(win.get("label", ""))
		print("%8.1f | %9.2f | %5s | %5s | %s" % [
			d, dist, "YES" if not offer.is_empty() else "no", drawn, label])
	print("")

	print("--- PASS 3: key in hand, press where S02 stood ------------------")
	var game := root.get_node_or_null(^"/root/Game")
	if game == null:
		print("FATAL: no /root/Game autoload")
		quit(1)
		return
	var inventory: RefCounted = game.get("inventory")
	var progression: RefCounted = game.get("progression")
	inventory.call("add", KEY_ITEM, 1)
	print("granted %s; inventory now holds %d" % [KEY_ITEM, int(inventory.call("count", KEY_ITEM))])
	print("flag %s before: %s" % [GATE_FLAG, progression.call("has", GATE_FLAG)])

	# 2.9 m is where `close_enough: 3.0` leaves the harness; 0.8 m is arm's
	# reach. If the first fails and the second passes, the finding is the
	# stand-off, not the gate.
	for d: float in [2.9, 0.8]:
		var spot := gate_xz + from_key * d
		await _place(player, world, spot)
		var fired := false
		if arbiter != null:
			fired = bool(arbiter.call("activate"))
		for i in 60:
			await physics_frame
		print("at %.1f m: arbiter.activate()=%s  flag %s=%s  key held=%d" % [
			d, fired, GATE_FLAG, progression.call("has", GATE_FLAG),
			int(inventory.call("count", KEY_ITEM))])
		if bool(progression.call("has", GATE_FLAG)):
			break
	print("")
	print("=== END ========================================================")
	quit(0)


## Put the player on the ground at an x/z and let physics settle. Facing is set
## toward the gate, because `_has_line_of_sight` casts from the prompt to the
## player and a body between them is the whole question.
func _place(player: CharacterBody3D, world: Node, at: Vector2) -> void:
	var y := 2.0
	if world.has_method("ground_height_at"):
		var g: float = world.call("ground_height_at", at.x, at.y)
		if not is_nan(g):
			y = g + 1.0
	player.global_position = Vector3(at.x, y, at.y)
	player.velocity = Vector3.ZERO
	for i in 30:
		await physics_frame


func _find(node: Node, name: String) -> Node:
	if node.name == name:
		return node
	for c in node.get_children():
		var hit := _find(c, name)
		if hit != null:
			return hit
	return null


func _descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for c in node.get_children():
		out.append(c)
		out.append_array(_descendants(c))
	return out
