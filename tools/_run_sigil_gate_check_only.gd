extends SceneTree

## SCRATCH: runs ONLY `_check_sigil_gate` from tests/smoke_traversal.gd,
## verbatim, against a freshly booted world -- so the real acceptance check
## (real player physics, real gate collision, real config-derived gap) can be
## exercised without paying for the rest of smoke_traversal.gd's much slower
## checks (the multi-hundred-metre four-leg walk, the river, the quarry...),
## which is what made a full run of that suite hang for 65 minutes on a
## previous pass. Every function body below is copied unmodified from
## tests/smoke_traversal.gd (SC14/GATE-D5/CHOKE-POINTS lineage) -- see that
## file for the full history/reasoning comments, trimmed here for size.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const THROUGH_THE_FLOOR := -80.0
const TERRAIN_CONFIG := "res://data/config/terrain_playground.json"

const SIGIL_CAUSEWAY_MIN_X := 57.0
const SIGIL_CAUSEWAY_MAX_X := 70.0
const SIGIL_GATE_START_BACK := 12.0
const SIGIL_GATE_WALK_FRAMES := 420
const SIGIL_GATE_BLOCKED_M := 1.0
const SIGIL_GATE_CROSSED_M := 8.0
const SIGIL_GATE_OFFSET_OUTSIDE_LEAF := 1.0
const SIGIL_GATE_OFFSET_NEAR_GORGE := 1.0

var _playground_world_script: GDScript = null


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame
	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null:
		print("FAIL: no Player node")
		quit(1)
		return
	var start := Vector3(60.0, 0.0, -60.0)
	start.y = float(world.call("ground_height_at", start.x, start.z)) + 1.0
	player.global_position = start
	player.velocity = Vector3.ZERO
	for i in 30:
		await physics_frame

	var failures: Array[String] = []
	await _check_sigil_gate(world, player, failures)

	print("")
	if failures.is_empty():
		print("SIGIL GATE CHECK: PASS")
	else:
		print("SIGIL GATE CHECK: FAIL (%d)" % failures.size())
		for f in failures:
			print("  - %s" % f)
	quit(0 if failures.is_empty() else 1)


func _check_sigil_gate(world: Node, player: CharacterBody3D, failures: Array[String]) -> void:
	var gate: Node3D = world.get_node_or_null(^"SigilGate") as Node3D
	if gate == null:
		failures.append("no SigilGate in the scene; spec Band 4's last gate is not built")
		return
	var camera_rig: Node3D = world.get_node_or_null(^"CameraRig") as Node3D
	if camera_rig == null:
		failures.append("no CameraRig in the scene; cannot aim a walk at the Sigil Gate")
		return
	var prompt: Node3D = gate.get_node_or_null(^"Interactable") as Node3D
	if prompt == null:
		failures.append("the Sigil Gate has no Interactable; it cannot be tried at all")
		return
	var body: Node = gate.get_node_or_null(^"GateCollision")
	var shape: CollisionShape3D = null
	if body != null:
		for child in body.get_children():
			if child is CollisionShape3D:
				shape = child as CollisionShape3D
				break
	var box: BoxShape3D = shape.shape as BoxShape3D if shape != null else null
	if box == null:
		failures.append("the Sigil Gate has no box collider; nothing would ever stop a player at it")
		return
	if shape.disabled:
		failures.append("the Sigil Gate's collider is disabled before anyone opens it")
		return

	var yaw := shape.global_rotation.y
	var scaled: Vector3 = box.size * shape.global_transform.basis.get_scale()
	var half_x: float = absf(scaled.x * cos(yaw)) * 0.5 + absf(scaled.z * sin(yaw)) * 0.5
	var leaf_min := shape.global_position.x - half_x
	var leaf_max := shape.global_position.x + half_x
	if leaf_min > SIGIL_CAUSEWAY_MIN_X + 0.5 or leaf_max < SIGIL_CAUSEWAY_MAX_X - 0.5:
		failures.append(
			("the Sigil Gate leaf spans world-x %.1f..%.1f but the causeway it must close is %.1f..%.1f"
				+ " -- %.1fm of open ground beside it, which a player simply walks around") % [
				leaf_min, leaf_max, SIGIL_CAUSEWAY_MIN_X, SIGIL_CAUSEWAY_MAX_X,
				maxf(0.0, leaf_min - SIGIL_CAUSEWAY_MIN_X) + maxf(0.0, SIGIL_CAUSEWAY_MAX_X - leaf_max)])
	var game := root.get_node_or_null(^"Game")
	if game == null:
		failures.append("no Game autoload; the Sigil Gate has no inventory or flag store to read")
		return
	var inventory: RefCounted = game.get("inventory")
	var progression: RefCounted = game.get("progression")

	if bool(gate.call("is_open")):
		failures.append("the Sigil Gate started open on a fresh world; it is not a gate")
		return

	var gate_xz := Vector2(gate.global_position.x, gate.global_position.z)
	var across := Vector2(gate.global_transform.basis.x.x, gate.global_transform.basis.x.z).normalized()
	var along := Vector2(-across.y, across.x)
	if along.y < 0.0:
		along = -along

	var leaf_half: float = box.size.x * 0.5
	var gap := _sigil_causeway_gap(gate_xz, across)
	if gap == Vector2.ZERO:
		failures.append("could not read the Sigil Gate's flanking gorges from terrain_playground.json; the causeway width is unknown")
		return
	print("  Sigil Gate: leaf collider half-width %.2fm; open causeway runs %.2fm..%.2fm either side of centre (%.1fm total)" % [
		leaf_half, gap.x, gap.y, gap.y - gap.x])
	if gap.x < -leaf_half - 0.1 or gap.y > leaf_half + 0.1:
		print("  NOTE: the leaf covers %.1fm of a %.1fm gap -- the shoulders either side are open, uncarved ground" % [
			leaf_half * 2.0, gap.y - gap.x])

	var offsets: Array[float] = [
		0.0,
		leaf_half + SIGIL_GATE_OFFSET_OUTSIDE_LEAF, -(leaf_half + SIGIL_GATE_OFFSET_OUTSIDE_LEAF),
		gap.y - SIGIL_GATE_OFFSET_NEAR_GORGE, gap.x + SIGIL_GATE_OFFSET_NEAR_GORGE,
	]

	for id: String in playground_world_gd().SIGIL_ITEM_IDS:
		var carried := int(inventory.call("count", id))
		if carried > 0:
			inventory.call("remove", id, carried)
	prompt.call("interaction_activate")
	await physics_frame
	if bool(gate.call("is_open")):
		failures.append("the Sigil Gate opened without any Sigils")
	if bool(progression.call("has", "hall_approach_open")):
		failures.append("trying the locked Sigil Gate set its open flag anyway")

	var worst_locked := -INF
	var worst_locked_label := ""
	for offset: float in offsets:
		for forward in [true, false]:
			var reached: float = await _walk_at_the_sigil_gate(world, player, camera_rig, gate_xz, across, along, offset, forward)
			var label := "%+.1fm off centre, %s" % [offset, "south->north" if forward else "north->south"]
			print("  Sigil Gate, locked, %s: reached %+.1fm past the gate" % [label, reached])
			if reached > worst_locked:
				worst_locked = reached
				worst_locked_label = label
	if worst_locked > SIGIL_GATE_BLOCKED_M:
		failures.append("the locked Sigil Gate can be walked past (%s, %.1fm past the gate) -- the causeway is not sealed" % [
			worst_locked_label, worst_locked])

	for id: String in playground_world_gd().SIGIL_ITEM_IDS:
		inventory.call("add", id, 1)
	prompt.call("interaction_activate")
	await physics_frame
	if not bool(gate.call("is_open")):
		failures.append("the Sigil Gate stayed shut with all three Sigils in the satchel")
		return
	for id: String in playground_world_gd().SIGIL_ITEM_IDS:
		if int(inventory.call("count", id)) != 0:
			failures.append("'%s' was not consumed opening the Sigil Gate" % id)
	if not bool(progression.call("has", "hall_approach_open")):
		failures.append("the open Sigil Gate did not set hall_approach_open; a reload would relock it")

	var best_open := -INF
	for forward in [true, false]:
		var reached: float = await _walk_at_the_sigil_gate(world, player, camera_rig, gate_xz, across, along, 0.0, forward)
		print("  Sigil Gate, unlocked, centre, %s: reached %+.1fm past the gate" % [
			"south->north" if forward else "north->south", reached])
		best_open = maxf(best_open, reached)
	if best_open < SIGIL_GATE_CROSSED_M:
		failures.append("could not cross the open Sigil Gate through its own centre (only %.1fm past the gate)" % best_open)
	if player.global_position.y < THROUGH_THE_FLOOR:
		failures.append("fell into a gorge while crossing the open Sigil Gate")


func playground_world_gd() -> GDScript:
	if _playground_world_script == null:
		_playground_world_script = load("res://scripts/world/playground_world.gd")
	return _playground_world_script


func _sigil_causeway_gap(gate_xz: Vector2, across: Vector2) -> Vector2:
	var cfg := _terrain_config()
	if cfg.is_empty():
		return Vector2.ZERO
	var by_id := {}
	for entry: Variant in cfg.get("crossings", []):
		by_id[str((entry as Dictionary).get("id", ""))] = entry
	var west: Dictionary = by_id.get("sigil_gate_gorge_west", {})
	var east: Dictionary = by_id.get("sigil_gate_gorge_east", {})
	if west.is_empty() or east.is_empty():
		return Vector2.ZERO
	var a := _carve_near_edge(west.get("carve", {}), gate_xz, across)
	var b := _carve_near_edge(east.get("carve", {}), gate_xz, across)
	if is_nan(a) or is_nan(b):
		return Vector2.ZERO
	return Vector2(minf(a, b), maxf(a, b))


func _carve_near_edge(carve: Dictionary, gate_xz: Vector2, across: Vector2) -> float:
	if carve.is_empty():
		return NAN
	var centre := Vector2(float(carve["centre"][0]), float(carve["centre"][1]))
	var axis := Vector2.RIGHT.rotated(deg_to_rad(float(carve.get("axis_deg", 0.0))))
	var reach: float = float(carve.get("half_length", 0.0)) + float(carve.get("end_fade", 0.0))
	var u := (centre - gate_xz).dot(across)
	var span := reach * absf(axis.dot(across))
	return u - signf(u) * span


func _walk_at_the_sigil_gate(world: Node, player: CharacterBody3D, camera_rig: Node3D,
		gate_xz: Vector2, across: Vector2, along: Vector2, offset: float, forward: bool) -> float:
	var travel: Vector2 = along if forward else -along
	var start_xz: Vector2 = gate_xz + across * offset - travel * SIGIL_GATE_START_BACK
	var ground: float = float(world.call("ground_height_at", start_xz.x, start_xz.y))
	if is_nan(ground):
		return -INF
	player.global_position = Vector3(start_xz.x, ground + 1.0, start_xz.y)
	player.velocity = Vector3.ZERO
	var outward := Vector3(travel.x, 0.0, travel.y)
	camera_rig.set("yaw", Vector3(0.0, 0.0, -1.0).signed_angle_to(outward, Vector3.UP))
	for i in 10:
		await physics_frame

	var best := -INF
	Input.action_press("move_forward")
	for i in SIGIL_GATE_WALK_FRAMES:
		await physics_frame
		var here := player.global_position
		var depth: float = travel.dot(Vector2(here.x, here.z) - gate_xz)
		best = maxf(best, depth)
	Input.action_release("move_forward")
	for i in 20:
		await physics_frame
	return best


func _terrain_config() -> Dictionary:
	var f := FileAccess.open(TERRAIN_CONFIG, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}
