extends SceneTree

## GATE-F-LEG-S06 isolated playtest: drives the Burrow Warrens (Band 2's
## required dungeon) for real -- real aggression, real combat, real guardian
## fight, real heartstone pickup -- from the hand-authored S05-exit seed at
## ralph/reports/gate-f-leg-s06/saves/S05-exit.json.
##
## Why this exists rather than reusing tools/gate_f/segments/S06.json as-is:
## that segment's own S06-50 step walks a HARDCODED anchor, (-420,2470),
## which is `map_landmarks.json`'s pre-BAND2-63-WARRENS region centre (now
## fixed in this same branch to (-357,2610), the site's real `site.at`). The
## segment's own S06-54 note already flags the 150m gap as an ambiguity. A
## full Gate F run of S06 got the player stuck, unrecoverably, for the rest
## of the segment trying to bridge that gap on foot in a straight line
## (`ralph/reports/.../S06/notes/S06.md`, steps S06-55 through S06-84, all
## reporting the identical frozen position (-406,-6,2488)). That is a real
## defect in the STALE MAP PIN, not in the Warrens' own approach from the
## real road -- `tools/_probe_warrens_run.gd` and
## `ralph/BAND2_WARRENS_EVIDENCE_2026-08-23.md` already proved the real
## approach walks cleanly. This script proves the REST of S06 (real combat,
## guardian, heartstone, exit) the same honest way, from the correct side of
## that now-fixed pin, without touching tools/gate_f/** (the rig lane's own
## files).
##
##   godot --headless --path . --script tools/_probe_s06_leg.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SEED_PATH := "res://ralph/reports/gate-f-leg-s06/saves/S05-exit.json"
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const GATE_F_PROBE := preload("res://scripts/debug/gate_f_probe.gd")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")

var _probe: RefCounted
var _nav: RefCounted


func _init() -> void:
	_run()


func _run() -> void:
	_probe = GATE_F_PROBE.new(self)

	# --- seed the save exactly as the Gate F run did, then load it directly
	# (SaveGame.load_slot is the real production load path; only the
	# title-screen button choreography is skipped, which this diagnostic
	# does not need to re-prove -- the harness run already did, cleanly).
	var seed_text := FileAccess.get_file_as_string("res://ralph/reports/gate-f-leg-s06/saves/S05-exit.json")
	if seed_text.is_empty():
		push_error("seed save not found at ralph/reports/gate-f-leg-s06/saves/S05-exit.json")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute("user://saves/")
	var f := FileAccess.open("user://saves/slot_4.json", FileAccess.WRITE)
	f.store_string(seed_text)
	f = null

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in 200:
		await process_frame

	var game: Node = root.get_node_or_null(^"Game")
	if game == null:
		push_error("no /root/Game autoload found")
		quit(1)
		return
	var save := SAVE_GAME.new()
	var ok := save.load_slot(game, 4)
	print("load_slot(4) -> %s" % str(ok))
	for i in 60:
		await process_frame
	# Player._ready() already ran (the world was fully settled before this
	# load), so it already tried and failed to apply a pose that did not
	# exist yet -- it does not retry on its own. Applying it explicitly is
	# this script's own job, not a gap in the production load path.
	var pose_applied: bool = bool(game.call("apply_loaded_player_pose"))
	print("apply_loaded_player_pose() -> %s" % str(pose_applied))

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	var warrens: Node3D = world.get_node_or_null(^"BurrowWarrens") as Node3D
	if player == null or warrens == null:
		push_error("scene has no Player or no BurrowWarrens node")
		quit(1)
		return
	var rig := _camera_rig(player)
	_nav = NAVIGATOR.new(self, player, rig, _parse_move_stick)

	# Deploy the active creature (RIG-11 -- a load restores the party and
	# deploys nothing).
	Input.action_press("creature_recall")
	await process_frame
	Input.action_release("creature_recall")
	for i in 30:
		await process_frame

	print("")
	print("party after load:")
	var party: Object = game.get("party")
	if party != null:
		for c: Object in (party.call("members") as Array):
			print("  %s L%d hp %.1f/%.1f atk %.1f def %.1f" % [
				str(c.get("display_name")), int(c.get("level")),
				float(c.get("hp")), float(c.get("max_hp")),
				float(c.get("attack")), float(c.get("defence"))])

	# --- walk the SAME proven waypoint chain the full Gate F run of S06
	# already walked successfully (quarry picket, then the Old Quarry: PASS
	# at 1059.5m/13485 frames for the next leg alone), rather than one long
	# straight cross-country shot -- a 1256m beeline from the bridge straight
	# to the Warrens road point, tried first, wedged solid 302m short in
	# unmapped forest and never recovered for the rest of the run. That is a
	# property of asking a naive straight-line walker to cut through terrain
	# nothing has ever proven walkable in one line, not a finding about Band
	# 2's own systems -- the road-following route below is the one every
	# prior pass (including this run's own successful S06 segment attempt)
	# has actually measured as walkable.
	var quarry_picket := Vector3(315.0, 0.0, 1668.0)
	quarry_picket.y = float(warrens.call("ground_height_at", quarry_picket.x, quarry_picket.z)) + 1.5
	var quarry := Vector3(403.0, 0.0, 1794.0)
	quarry.y = float(warrens.call("ground_height_at", quarry.x, quarry.z)) + 1.5
	var road := Vector3(-380.0, 0.0, 2540.0)
	road.y = float(warrens.call("ground_height_at", road.x, road.z)) + 1.5
	print("")
	print("=== walking the proven road chain to the Warrens' real approach ===")
	await _walk_to(player, world, quarry_picket, 18900)
	await _walk_to(player, world, quarry, 6300)
	await _walk_to(player, world, road, 18900, 6.0)

	var entrance: Vector3 = warrens.call("marker", "entrance")
	await _walk_to(player, world, entrance, 3000)
	print("region at entrance: %s" % _region_name(player))

	for leg: String in ["mouth", "hall"]:
		for point: Vector3 in _approach(warrens, leg):
			await _walk_to(player, world, point, 3000)

	print("")
	print("=== engaging the hall ===")
	await _engage_and_fight("hall residents")

	for point: Vector3 in _approach(warrens, "warren"):
		await _walk_to(player, world, point, 3000)
	print("")
	print("=== the side warren chamber (rootstone) ===")
	await _press_tap("interact", 2, 90)
	print("inventory after warren rootstone: %s" % _inventory_snapshot(game))

	for point: Vector3 in _approach(warrens, "den"):
		await _walk_to(player, world, point, 3000)
	print("")
	print("=== engaging the den (guardian's chamber, resident fight first) ===")
	await _engage_and_fight("den residents")

	print("")
	print("=== the guardian ===")
	var guardian: Node3D = warrens.call("guardian")
	# The guardian has its own small `wander_radius` (1.2-1.5m per
	# burrow_warrens.json), so a position captured once before walking can go
	# stale by the time the walk finishes. Re-reading it and retrying the
	# approach a few times catches that, rather than reporting "never
	# engaged" for what may just be an out-of-date snapshot.
	for attempt in 3:
		if bool((_probe.call("input_state") as Dictionary).get("combat_running", false)):
			break
		if guardian != null and is_instance_valid(guardian):
			await _walk_to(player, world, guardian.global_position, 1500, 3.0)
		await _engage_and_fight("the Warren Guardian (attempt %d)" % (attempt + 1), 90)
		if bool((_probe.call("input_state") as Dictionary).get("combat_running", false)) \
				or _has_flag(game, "warrens_cleared"):
			break

	print("warrens_cleared flag set: %s" % str(_has_flag(game, "warrens_cleared")))

	for point: Vector3 in _approach(warrens, "vault"):
		await _walk_to(player, world, point, 3000)
	print("")
	print("=== the vault / heartstone ===")
	await _press_tap("interact", 1, 90)
	print("inventory after heartstone: %s" % _inventory_snapshot(game))

	# Walk back out, toward the ranger camp / river.
	await _walk_to(player, world, entrance, 3000)
	var camp := Vector3(-259.0, 0.0, 2256.5)
	camp.y = float(warrens.call("ground_height_at", camp.x, camp.z)) + 1.5
	await _walk_to(player, world, camp, 12000, 6.0)
	print("region at ranger camp waypoint: %s" % _region_name(player))

	print("")
	print("=== final party state ===")
	if party != null:
		for c: Object in (party.call("members") as Array):
			print("  %s L%d hp %.1f/%.1f xp %d fainted=%s" % [
				str(c.get("display_name")), int(c.get("level")),
				float(c.get("hp")), float(c.get("max_hp")), int(c.get("xp")),
				str(bool(c.get("fainted")))])

	# Save out through the real production save path (slot 4), same slot the
	# Gate F handoff convention uses, so the artefact this leg hands off is a
	# genuine SaveGame.save() write, not a synthesised file.
	var pose_game: Node = game
	if pose_game.get("saved_player_pose") != null:
		pose_game.set("saved_player_pose", {
			"position": [player.global_position.x, player.global_position.y, player.global_position.z],
			"model_yaw": 0.0,
			"camera_yaw": 0.0,
			"camera_pitch": -0.1,
		})
	var wrote := save.save(game, 4)
	print("")
	print("save(4) -> %s" % str(wrote))
	var out_path := "res://ralph/reports/gate-f-leg-s06/saves/S06-exit.json"
	var src := FileAccess.get_file_as_string("user://saves/slot_4.json")
	var out := FileAccess.open(out_path, FileAccess.WRITE)
	out.store_string(src)
	out = null
	print("copied to %s (%d bytes)" % [out_path, src.length()])

	quit(0)


func _region_name(player: Node3D) -> String:
	return str(_probe.call("region_at", player.global_position))


func _has_flag(game: Node, flag: String) -> bool:
	var progression: Variant = game.get("progression")
	if progression == null:
		return false
	return bool((progression as Object).call("has", flag))


func _inventory_snapshot(game: Node) -> String:
	var inv: Object = game.get("inventory")
	if inv == null:
		return "(no inventory)"
	var count: int = int(inv.call("slot_count"))
	var out: Array[String] = []
	for i in count:
		var stack: Dictionary = inv.call("stack_at", i)
		if not stack.is_empty():
			out.append("%s x%d" % [str(stack.get("id", "")), int(stack.get("n", 0))])
	return ", ".join(out)


func _approach(warrens: Node3D, chamber: String) -> Array:
	var points: Array = []
	var config := _config()
	var chambers: Dictionary = {}
	for entry: Variant in config.get("chambers", []):
		chambers[str((entry as Dictionary).get("id", ""))] = entry
	for entry: Variant in config.get("passages", []):
		var passage: Dictionary = entry as Dictionary
		if str(passage.get("to", "")) != chamber:
			continue
		var from_id := str(passage.get("from", ""))
		if not chambers.has(from_id) or not chambers.has(chamber):
			continue
		var a: Array = (chambers[from_id] as Dictionary).get("at", [0.0, 0.0])
		var b: Array = (chambers[chamber] as Dictionary).get("at", [0.0, 0.0])
		var mid := Vector2((float(a[0]) + float(b[0])) * 0.5, (float(a[1]) + float(b[1])) * 0.5)
		points.append(Vector3(mid.x, 0.0, mid.y))
	var out: Array = []
	for local: Vector3 in points:
		out.append(warrens.to_global(Vector3(local.x, warrens.call("marker", chamber).y \
			- warrens.global_position.y, local.z)))
	out.append(warrens.call("marker", chamber))
	return out


func _config() -> Dictionary:
	var file := FileAccess.open("res://data/config/burrow_warrens.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _camera_rig(player: CharacterBody3D) -> Node3D:
	var named: Variant = player.get("_camera_rig")
	if named is Node3D and is_instance_valid(named as Node3D):
		return named as Node3D
	for child in player.get_parent().get_children():
		if child is Node3D and child.has_method("planar_basis"):
			return child as Node3D
	return null


## Uses tests/helpers/stick_navigator.gd -- the same obstacle-detouring
## walker the Gate F harness itself drives through (operator_harness.gd's
## `_walk_loop`), not a naive point-the-stick-and-hold line. A first version
## of this script drove the stick with a plain yaw calculation and wedged
## solid twice, in two different places, on legs `stick_navigator.gd`'s own
## header explains this exact class of failure for (a straight line into
## whatever stands in the way, with no detour). Reusing the real navigator
## instead of re-diagnosing each wedge as a new Band 2 defect.
func _walk_to(player: CharacterBody3D, world: Node, target: Vector3, budget_frames: int, close_enough: float = 3.0) -> void:
	var start := player.global_position
	var arrived: bool = await _nav.call("walk_to", target, budget_frames, close_enough)
	_release_move_stick()
	var remaining := player.global_position.distance_to(target)
	var verdict := "arrived" if arrived else "STUCK %.1fm short at %s" % [remaining, str(player.global_position)]
	print("walk to %s: %.1fm start-dist, [%s]" % [
		str(target), start.distance_to(target), verdict])


func _parse_move_stick(x: float, y: float) -> void:
	Input.action_press(&"move_right", clampf(x, 0.0, 1.0))
	Input.action_press(&"move_left", clampf(-x, 0.0, 1.0))
	Input.action_press(&"move_back", clampf(y, 0.0, 1.0))
	Input.action_press(&"move_forward", clampf(-y, 0.0, 1.0))


func _release_move_stick() -> void:
	for action: StringName in [&"move_right", &"move_left", &"move_back", &"move_forward"]:
		Input.action_release(action)


func _press_tap(action: String, times: int, settle_frames: int) -> void:
	for i in times:
		Input.action_press(action)
		await physics_frame
		Input.action_release(action)
		for j in settle_frames:
			await physics_frame


## The hall fight showed combat can already be RUNNING by the time this is
## called -- aggressive residents (every spawn in this file, guardian
## included, carries `"aggressive": true`) close distance and engage during
## the walk itself, before any interact press. So this checks first, rather
## than pressing interact unconditionally: doing so while combat is already
## live is what threw two orb_greater at the hall's own residents as catch
## attempts instead of landing melee swings.
func _engage_and_fight(label: String, quick_presses: int = 60) -> void:
	var state: Dictionary = _probe.call("input_state")
	if not bool(state.get("combat_running", false)):
		Input.action_press("interact")
		await physics_frame
		Input.action_release("interact")
		for i in 180:
			await physics_frame
		state = _probe.call("input_state")
		print("%s: input_context=%s combat_running=%s" % [label, str(_probe.call("input_context")), str(state.get("combat_running", false))])
	else:
		print("%s: combat already running (aggro engaged during the approach)" % label)
	if not bool(state.get("combat_running", false)):
		print("%s: NOT engaged after one interact press -- trying once more" % label)
		Input.action_press("interact")
		await physics_frame
		Input.action_release("interact")
		for i in 180:
			await physics_frame
		state = _probe.call("input_state")
		print("%s (retry): input_context=%s combat_running=%s" % [label, str(_probe.call("input_context")), str(state.get("combat_running", false))])
	var swings := 0
	while bool(state.get("combat_running", false)) and swings < quick_presses:
		Input.action_press("combat_quick")
		await physics_frame
		Input.action_release("combat_quick")
		for i in 20:
			await physics_frame
		state = _probe.call("input_state")
		swings += 1
	for i in 300:
		await physics_frame
	state = _probe.call("input_state")
	print("%s: fight over after %d swings, combat_running now %s" % [label, swings, str(state.get("combat_running", false))])


