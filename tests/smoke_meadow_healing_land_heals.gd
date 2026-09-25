extends SceneTree

## F05, owner decision "the land heals", on the PRODUCTION Meadows world.
##
##   godot --headless --path . --script tests/smoke_meadow_healing_land_heals.gd
##
## 1. Boots `meadows_playground.tscn`, sets `legendary_freed` live (the path the
##    Warden's machinery takes) and asserts the three effects `meadow_healing.gd`
##    owns: (A) the regreen overlay exists and FADES (not a snap) to full, (C)
##    the quarry/relay/approach pylons lie on the ground with their colliders
##    laid down and their cables hidden while the severed spokes still stand,
##    (B) the returning Meadowhart herd stands inert on the Highfield.
## 2. Writes a REAL save (`Game.save_game`), throws the world away, clears the
##    flag store, `Game.load_game`s the slot the way a title-screen Continue
##    does (before the scene exists) and boots a fresh world: the same three
##    effects must be re-derived from the saved flag in their END state at
##    build (snap, no fade, no fall).

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const SLOT := 6
const FLAG := "legendary_freed"
const FADE_TIMEOUT_MS := 40000

var _failures: Array[String] = []
var _game: Node = null


func _init() -> void:
	_run()


func _fail(message: String) -> void:
	_failures.append(message)
	print("  FAIL: %s" % message)


func _run() -> void:
	var world := await _boot_world()
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		print("land-heals FAIL: no Game autoload")
		quit(1)
		return
	var healing: Node = world.get_node_or_null(^"MeadowHealing")
	if healing == null:
		print("land-heals FAIL: the world built no MeadowHealing")
		quit(1)
		return
	if bool(healing.call("applied")):
		print("land-heals FAIL: '%s' was already set on boot" % FLAG)
		quit(1)
		return
	var spokes_before := _spoke_pylon_transforms(world)

	# --- 1. live: the flag lands ---------------------------------------------
	_game.get("progression").call("set_flag", FLAG)
	while not bool(healing.call("applied")):
		await process_frame
	var report: Dictionary = healing.call("report")
	print("live report: %s" % str(report))
	var alpha_start := float(healing.call("regreen_alpha_now"))
	if alpha_start >= 0.5:
		_fail("(live) the regreen started at alpha %.2f: the live flag must FADE it in, not snap" % alpha_start)
	var started := Time.get_ticks_msec()
	var mid_seen := false
	while float(healing.call("regreen_alpha_now")) < 0.999 and Time.get_ticks_msec() - started < FADE_TIMEOUT_MS:
		var a := float(healing.call("regreen_alpha_now"))
		if a > 0.05 and a < 0.95:
			mid_seen = true
		await process_frame
	# Let the last staggered pylon land.
	var settle := Time.get_ticks_msec()
	while Time.get_ticks_msec() - settle < 6000:
		await process_frame
	print("(live) regreen reached alpha %.3f after %.1f s; mid-fade frame seen: %s" % [
		float(healing.call("regreen_alpha_now")), float(Time.get_ticks_msec() - started) / 1000.0, str(mid_seen)])
	if not mid_seen:
		_fail("(live) never saw a mid-fade regreen frame")
	_check_end_state(world, healing, "live")
	_check_spokes_untouched(world, spokes_before, "live")

	# --- 2. a real save, and a Continue into a fresh world --------------------
	_fill_party()
	if not bool(_game.call("save_game", SLOT)):
		_fail("Game.save_game(%d) failed" % SLOT)
		_finish()
		return
	await _clear_world()
	_game.get("progression").call("load_data", {})
	if bool(_game.get("progression").call("has", FLAG)):
		_fail("clearing the flag store did not clear '%s'" % FLAG)
	if not bool(_game.call("load_game", SLOT)):
		_fail("Game.load_game(%d) failed after a save that succeeded" % SLOT)
		_finish()
		return
	if not bool(_game.get("progression").call("has", FLAG)):
		_fail("the saved slot did not bring '%s' back" % FLAG)
	var fresh: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(fresh)
	current_scene = fresh
	var reloaded: Node = null
	for i in 20000:
		reloaded = fresh.get_node_or_null(^"MeadowHealing")
		if reloaded != null and bool(reloaded.call("applied")):
			break
		await process_frame
	if reloaded == null or not bool(reloaded.call("applied")):
		_fail("(reload) the fresh world never re-applied the healing from the saved flag")
		_finish()
		return
	# The very frame it applied: a load must SNAP -- alpha 1 and pylons already
	# down, not starting a fade or a fall.
	var snap_alpha := float(reloaded.call("regreen_alpha_now"))
	if snap_alpha < 0.999:
		_fail("(reload) the regreen was at alpha %.2f when applied: a load must snap to the healed state" % snap_alpha)
	print("reload report: %s" % str(reloaded.call("report")))
	_check_end_state(fresh, reloaded, "reload")
	var live_count := int(report.get("pylons_toppled", 0))
	var reload_report: Dictionary = reloaded.call("report")
	for key: String in ["regreened", "pylons_toppled", "cables_hidden", "herd_returned"]:
		if int(reload_report.get(key, -1)) != int(report.get(key, -2)):
			_fail("(reload) '%s' is %d after the reload but was %d live -- the world is not re-derived identically"
				% [key, int(reload_report.get(key, -1)), int(report.get(key, -2))])
	for i in 30:
		await physics_frame
	_check_end_state(fresh, reloaded, "reload+30")
	print("pylons toppled: %d" % live_count)
	var dir := DirAccess.open("user://saves/")
	if dir != null:
		dir.remove("slot_%d.json" % SLOT)
	_finish()


func _check_end_state(world: Node, healing: Node, tag: String) -> void:
	var report: Dictionary = healing.call("report")
	# (A)
	var skin: MeshInstance3D = healing.call("regreen_node")
	if skin == null or not skin.visible or skin.mesh == null:
		_fail("(%s) no visible regreen overlay" % tag)
	elif int(report.get("regreened", 0)) <= 0:
		_fail("(%s) the regreen painted no quads" % tag)
	if float(healing.call("regreen_alpha_now")) < 0.999:
		_fail("(%s) regreen alpha %.2f, not fully in" % [tag, float(healing.call("regreen_alpha_now"))])
	# (C)
	var pylons: Array = healing.call("toppled_pylons")
	if pylons.size() < 10:
		_fail("(%s) only %d pylons fell" % [tag, pylons.size()])
	var worst_tip := 0.0
	var worst_up := -1.0
	for raw: Variant in pylons:
		var pylon := raw as MeshInstance3D
		if pylon == null or not is_instance_valid(pylon):
			_fail("(%s) a toppled pylon was freed" % tag)
			continue
		var up := pylon.global_transform.basis.y.normalized().dot(Vector3.UP)
		worst_up = maxf(worst_up, up)
		var local := pylon.mesh.get_aabb()
		var top := pylon.global_transform * Vector3(local.get_center().x, local.end.y, local.get_center().z)
		var ground := float(world.call("ground_height_at", top.x, top.z))
		if not is_nan(ground):
			if absf(top.y - ground) > absf(worst_tip):
				worst_tip = top.y - ground
		for sibling: Node in pylon.get_parent().get_children():
			var body := sibling as StaticBody3D
			if body == null:
				continue
			# A collider left standing would still be upright; the one laid down
			# with its pylon is not.
			if body.global_transform.basis.y.normalized().dot(Vector3.UP) > 0.9 \
					and _near_original(body, pylon):
				_fail("(%s) %s/%s left a standing collider at %s" % [tag, pylon.get_parent().name,
					pylon.name, str(body.global_position)])
	if worst_up > 0.45:
		_fail("(%s) a toppled pylon is still %.0f deg from lying down" % [tag, rad_to_deg(acos(clampf(worst_up, -1.0, 1.0)))])
	if absf(worst_tip) > 2.0:
		_fail("(%s) a fallen pylon's tip is %.2f m off the terrain" % [tag, worst_tip])
	print("(%s) %d pylons down; max up.y %.2f; worst tip-to-ground %.2f m" % [tag, pylons.size(), worst_up, worst_tip])
	var visible_cables := 0
	for node: Node in _all(world):
		var name := str(node.name)
		if not (name.begins_with("Conduit_") or name.begins_with("DangleStub_")):
			continue
		var parent_name := str(node.get_parent().name)
		if parent_name == "TetherConduits" or parent_name == "ApproachConduits" \
				or parent_name.begins_with("Conduits_") or parent_name == "CableLinks" \
				or parent_name == "HallCableLanding":
			if (node as Node3D).visible:
				visible_cables += 1
	if visible_cables > 0:
		_fail("(%s) %d cable pieces still hang where a pylon fell" % [tag, visible_cables])
	if int(report.get("cables_hidden", 0)) <= 0:
		_fail("(%s) no cable pieces were hidden" % tag)
	# (B)
	var herd: Node3D = healing.call("herd_return")
	if herd == null:
		_fail("(%s) no HighfieldHerdReturn holder" % tag)
		return
	var bodies := herd.get_children()
	if bodies.size() < 6:
		_fail("(%s) only %d of the herd came back" % [tag, bodies.size()])
	for raw: Node in bodies:
		var body := raw as CharacterBody3D
		if body == null:
			_fail("(%s) %s is not a creature body" % [tag, raw.name])
			continue
		if str(body.get("species_id")) != "meadowhart":
			_fail("(%s) %s is a '%s'" % [tag, body.name, str(body.get("species_id"))])
		if body.is_physics_processing() or body.collision_layer != 0:
			_fail("(%s) %s is not inert (physics %s, layer %d)" % [tag, body.name, str(body.is_physics_processing()), body.collision_layer])
		if Vector2(body.global_position.x - 400.0, body.global_position.z - 5900.0).length() > 65.0:
			_fail("(%s) %s stands off the Highfield at %s" % [tag, body.name, str(body.global_position)])
		var ground := float(world.call("ground_height_at", body.global_position.x, body.global_position.z))
		if not is_nan(ground) and absf(body.global_position.y - ground) > 1.5:
			_fail("(%s) %s floats/sinks %.2f m" % [tag, body.name, body.global_position.y - ground])
	var display: Node3D = healing.call("herd_display")
	if display != null and str(display.get("species_id")) != "veridian":
		_fail("(%s) herd_display() returned a '%s', not the Veridian" % [tag, str(display.get("species_id"))])
	print("(%s) %d of the herd back on the Highfield, inert" % [tag, bodies.size()])


func _near_original(body: Node3D, pylon: Node3D) -> bool:
	# The collider that belonged to this pylon was laid down with it; any
	# upright collider within 3 m of the fallen pylon's base region is the
	# invisible wall this checks for.
	var box := pylon.global_transform * (pylon as MeshInstance3D).mesh.get_aabb()
	var centre := box.get_center()
	return Vector2(body.global_position.x - centre.x, body.global_position.z - centre.z).length() \
		< maxf(box.size.x, box.size.z) * 0.5 + 1.0


func _spoke_pylon_transforms(world: Node) -> Dictionary:
	var out := {}
	var spokes := world.get_node_or_null(^"SeveredSpokes")
	if spokes == null:
		return out
	for node: Node in _all(spokes):
		if node is MeshInstance3D and str(node.name).begins_with("Pylon_"):
			out[str(spokes.get_path_to(node))] = (node as Node3D).global_transform
	return out


func _check_spokes_untouched(world: Node, before: Dictionary, tag: String) -> void:
	var after := _spoke_pylon_transforms(world)
	if before.is_empty():
		print("(%s) no severed-spoke pylons in this world to compare" % tag)
		return
	for key: String in before.keys():
		if not after.has(key) or not (after[key] as Transform3D).is_equal_approx(before[key] as Transform3D):
			_fail("(%s) severed-spoke pylon %s moved; the spokes are meant to stay standing" % [tag, key])
	print("(%s) %d severed-spoke pylons left standing" % [tag, before.size()])


func _fill_party() -> void:
	var party: RefCounted = _game.get("party")
	if int(party.call("size")) > 0:
		return
	for species: String in ["terrapup", "mudsnout", "bramblebun"]:
		var creature: RefCounted = _game.call("make_creature", species, species.capitalize())
		if creature != null:
			party.call("add", creature)


func _all(root_node: Node) -> Array[Node]:
	var out: Array[Node] = []
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		out.append(node)
		for child in node.get_children():
			stack.append(child)
	return out


func _clear_world() -> void:
	for child in root.get_children():
		if child.name != "Game":
			child.queue_free()
	for i in 4:
		await process_frame


func _boot_world() -> Node:
	await _clear_world()
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame
	return world


func _finish() -> void:
	print("")
	if _failures.is_empty():
		print("meadow land-heals smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)
