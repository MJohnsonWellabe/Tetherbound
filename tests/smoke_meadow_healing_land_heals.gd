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
const SLOT := 4
const FLAG := "legendary_freed"
const FADE_TIMEOUT_MS := 40000
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

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
	if OS.get_cmdline_user_args().has("--bake-falls"):
		# OFFLINE: print the `pylons.falls` table for meadow_healing.json.
		var table: Dictionary = healing.call("bake_fall_table")
		print("FALLS_JSON:" + JSON.stringify(table))
		print("FALLS_REASONS:" + JSON.stringify(healing.call("bake_reasons")))
		quit(0)
		return
	var spokes_before := _spoke_pylon_transforms(world)
	_check_table_covers_the_world(world)

	# --- 0. before: the machine is live, the land lies drained ------------------
	var drained: Array = healing.call("drain_nodes")
	if drained.size() < 3:
		_fail("(before) %d drain meshes; expected at least one per station group" % drained.size())
	for raw: Variant in drained:
		var skin := raw as MeshInstance3D
		if skin == null or not skin.visible or skin.mesh == null:
			_fail("(before) drain mesh %s is not standing" % (str(skin.name) if skin != null else "null"))
	if float(healing.call("drain_alpha_now")) < 0.999:
		_fail("(before) the drain stands at alpha %.2f, not 1" % float(healing.call("drain_alpha_now")))
	print("(before) the land lies drained: %d drain meshes at alpha %.2f" % [drained.size(), float(healing.call("drain_alpha_now"))])

	# --- 1. live: the flag lands ---------------------------------------------
	_game.get("progression").call("set_flag", FLAG)
	while not bool(healing.call("applied")):
		await process_frame
	var report: Dictionary = healing.call("report")
	print("live report: %s" % str(report))
	if not bool(healing.call("holding_presentation")):
		_fail("(live) the heal payoff is not holding the presentation (X03 presentation_hold)")
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
	if bool(healing.call("holding_presentation")):
		_fail("(live) the heal payoff still holds the presentation after its fades")
	for raw: Variant in (healing.call("drain_nodes") as Array):
		if (raw as MeshInstance3D).visible:
			_fail("(live) drain mesh %s still stands after the fade" % str((raw as MeshInstance3D).name))
	print("(live) the drain lifted: alpha %.3f, %d meshes hidden" % [float(healing.call("drain_alpha_now")), (healing.call("drain_nodes") as Array).size()])
	_check_end_state(world, healing, "live")
	var live_poses := _pylon_poses(world, healing)
	_check_spokes_untouched(world, spokes_before, "live")

	# --- 2. a real save, and a Continue into a fresh world --------------------
	# Saved from a DIFFERENT place than the live run stood (home spawn): the
	# reload boots with the player at the relay, so vegetation colliders,
	# streaming and everything else local to the player differ. The pylons
	# must not.
	var player := world.get_node_or_null(^"Player") as Node3D
	if player == null:
		_fail("no Player to move before saving")
	else:
		var relay := Vector3(346.5, 0.0, 3749.1 + 30.0)
		relay.y = float(world.call("ground_height_at", relay.x, relay.z)) + 0.5
		player.global_position = relay
		for i in 30:
			await physics_frame
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
	if bool(reloaded.call("holding_presentation")):
		_fail("(reload) a load held the presentation")
	if not (reloaded.call("drain_nodes") as Array).is_empty():
		_fail("(reload) a load after the freeing built the drain (%d meshes)" % (reloaded.call("drain_nodes") as Array).size())
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
	# Per pylon, not only per count: every pylon must lie exactly where it lay
	# in the live world.
	var reload_poses := _pylon_poses(fresh, reloaded)
	for key: String in live_poses.keys():
		if not reload_poses.has(key):
			_fail("(reload) %s fell live but not after the reload" % key)
		elif not _same_pose(live_poses[key] as Transform3D, reload_poses[key] as Transform3D):
			_fail("(reload) %s lies differently after the reload: live %s, reload %s"
				% [key, str(live_poses[key]), str(reload_poses[key])])
	for key: String in reload_poses.keys():
		if not live_poses.has(key):
			_fail("(reload) %s fell after the reload but not live" % key)
	var reloaded_player := fresh.get_node_or_null(^"Player") as Node3D
	var where := reloaded_player.global_position if reloaded_player != null else Vector3.INF
	if reloaded_player == null or Vector2(where.x - 346.5, where.z - 3779.1).length() > 20.0:
		_fail("(reload) the player did not come back at the relay (%s): the different-position reload was not exercised" % str(where))
	print("(reload) %d fallen pylons compared per pylon against the live world; reloaded player at %s" % [live_poses.size(), str(where)])
	for i in 30:
		await physics_frame
	_check_end_state(fresh, reloaded, "reload+30")
	print("pylons toppled: %d" % live_count)
	_finish()


func _check_end_state(world: Node, healing: Node, tag: String) -> void:
	var report: Dictionary = healing.call("report")
	# (A)
	var skins: Array = healing.call("regreen_nodes")
	if skins.size() != 3:
		_fail("(%s) %d regreen meshes, expected one per station group (3)" % [tag, skins.size()])
	for raw: Variant in skins:
		var skin := raw as MeshInstance3D
		if skin == null or not skin.visible or skin.mesh == null:
			_fail("(%s) a regreen overlay is missing or hidden" % tag)
	if int(report.get("regreened", 0)) <= 0:
		_fail("(%s) the regreen painted no quads" % tag)
	if float(healing.call("regreen_alpha_now")) < 0.999:
		_fail("(%s) regreen alpha %.2f, not fully in" % [tag, float(healing.call("regreen_alpha_now"))])
	# (C)
	var pylons: Array = healing.call("toppled_pylons")
	# The owner decision is "the dark pylons are down": every pylon in the
	# baked fall table falls, live and after reload. A stale table entry (a
	# moved pylon, re-baked terrain) that leaves one standing fails HERE rather
	# than only warning at runtime (re-review of f2e0761a, blocking 1).
	var table: Dictionary = ((_healing_config().get("pylons", {}) as Dictionary).get("falls", {}) as Dictionary)
	if pylons.size() != table.size():
		_fail("(%s) %d pylons fell; the fall table has %d" % [tag, pylons.size(), table.size()])
	if int(report.get("pylons_left_standing", -1)) != 0:
		_fail("(%s) %d pylon(s) left standing" % [tag, int(report.get("pylons_left_standing", -1))])
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
		# Rests ON the ground, not half-buried along its width: the top's
		# centre line sits above the terrain, and its underside (centre minus
		# half its lying thickness) is not floating.
		var b := pylon.global_transform.basis
		var half_depth := 0.5 * (absf(b.x.y) * local.size.x + absf(b.z.y) * local.size.z)
		if not is_nan(ground):
			var centre_gap := top.y - ground
			var underside := centre_gap - half_depth
			if absf(underside) > absf(worst_tip):
				worst_tip = underside
			if centre_gap < 0.2 * half_depth or underside > 1.0:
				_fail("(%s) %s/%s top rests badly: centre line %.2f m, underside %.2f m off the ground (half depth %.2f)"
					% [tag, pylon.get_parent().name, pylon.name, centre_gap, underside, half_depth])
		_check_walkable(world, pylon, tag)
	if worst_up > 0.45:
		_fail("(%s) a toppled pylon is still %.0f deg from lying down" % [tag, rad_to_deg(acos(clampf(worst_up, -1.0, 1.0)))])
	print("(%s) %d pylons down (%d left standing); max up.y %.2f; worst top-underside-to-ground %.2f m" % [tag,
		pylons.size(), int(report.get("pylons_left_standing", -1)), worst_up, worst_tip])
	_check_colliders_removed(pylons, tag)
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


## Every fallen pylon must lie clear of every road band (half-width +
## shoulder, across its whole box out to the tip) and must overlap no fixed
## static collider -- ApproachRamp above all. Checked from the pylon's actual
## final transform, independently of the direction search.
func _check_walkable(world: Node, pylon: MeshInstance3D, tag: String) -> void:
	var xform := pylon.global_transform
	# The root (one base width out from the pivot) lies where the standing
	# pylon already stood; check what the fall newly covers.
	var full := pylon.mesh.get_aabb()
	var sc := xform.basis.get_scale()
	var trim := minf(maxf(full.size.x * sc.x, full.size.z * sc.z) / sc.y, full.size.y * 0.5)
	var local := AABB(full.position + Vector3(0, trim, 0), full.size - Vector3(0, trim, 0))
	var points: Array[Vector2] = []
	var steps := maxi(int(ceil((xform.basis.y * local.size.y).length())), 1)
	for s in steps + 1:
		var y := local.position.y + local.size.y * float(s) / float(steps)
		for u: float in [0.0, 1.0]:
			for w: float in [0.0, 1.0]:
				var point := xform * Vector3(local.position.x + local.size.x * u, y,
					local.position.z + local.size.z * w)
				points.append(Vector2(point.x, point.z))
	var label := "%s/%s" % [pylon.get_parent().name, pylon.name]
	for raw: Variant in (_heightfield().call("road_bands") as Array):
		var band: Dictionary = raw
		# The carriageway: a fallen pylon has no collider, so lying on a shoulder
		# blocks nothing.
		var clearance := float(band["half"])
		var line: PackedVector2Array = band["line"]
		for point: Vector2 in points:
			var d := _polyline_distance(point, line)
			if d < clearance:
				_fail("(%s) %s lies %.2f m from a road band's centreline (carriageway half-width %.2f)"
					% [tag, label, d, clearance])
				return
	var space := (world as Node3D).get_world_3d().direct_space_state
	var scale := xform.basis.get_scale()
	var shape := BoxShape3D.new()
	shape.size = Vector3(local.size.x * scale.x, local.size.y * scale.y, local.size.z * scale.z)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(xform.basis.orthonormalized(), xform * local.get_center())
	for hit: Dictionary in space.intersect_shape(query, 32):
		var other := hit.get("collider") as Node
		if other == null or not other is StaticBody3D or other is AnimatableBody3D:
			continue
		if other.is_queued_for_deletion():
			continue
		if str(other.name).contains("ApproachRamp"):
			_fail("(%s) %s lies through the ApproachRamp" % [tag, label])
			continue
		var skip := false
		var node: Node = other
		while node != null:
			if node.is_in_group("placed_building") or node.has_method("open_permanently") \
					or str(node.name) == "Vegetation":
				skip = true
			node = node.get_parent()
		if not skip:
			_fail("(%s) %s overlaps static body %s" % [tag, label, str(world.get_path_to(other))])
	_walk_checked += 1


var _walk_checked := 0


## `collider: remove` is the default: no pylon that fell may keep a collider.
## A holder's only StaticBody3D children are its pylons' colliders, so each
## holder keeps exactly as many as it has pylons still standing.
func _check_colliders_removed(pylons: Array, tag: String) -> void:
	var fallen_by_holder := {}
	for raw: Variant in pylons:
		var pylon := raw as Node3D
		if pylon == null or not is_instance_valid(pylon):
			continue
		var holder := pylon.get_parent()
		fallen_by_holder[holder] = int(fallen_by_holder.get(holder, 0)) + 1
	var checked := 0
	for holder: Node in fallen_by_holder.keys():
		var bodies := 0
		var standing := 0
		for child: Node in holder.get_children():
			if child is StaticBody3D and not child.is_queued_for_deletion():
				bodies += 1
			elif child is MeshInstance3D and str(child.name).begins_with("Pylon_"):
				standing += 1
		standing -= int(fallen_by_holder[holder])
		checked += 1
		if bodies != standing:
			_fail("(%s) %s keeps %d colliders for %d standing pylons -- a fallen pylon kept its collider"
				% [tag, holder.name, bodies, standing])
	print("(%s) colliders checked in %d holders; %d fallen pylons checked clear of roads and static bodies"
		% [tag, checked, _walk_checked])
	_walk_checked = 0


## Every pylon in every falling holder is in the authored `pylons.falls`
## table, and the pylons authored to stay standing (null) are exactly
## EXPECTED_STANDING -- a new one is a decision to record, not a surprise.
const EXPECTED_STANDING: Array[String] = []


func _check_table_covers_the_world(world: Node) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/meadow_healing.json"))
	var block: Dictionary = (parsed as Dictionary).get("pylons", {})
	var table: Dictionary = block.get("falls", {})
	var patterns: Array = block.get("holders", [])
	var seen := 0
	for node: Node in _all(world):
		var matched := false
		for raw: Variant in patterns:
			matched = matched or str(node.name).match(str(raw))
		if not matched:
			continue
		for child: Node in node.get_children():
			if child is MeshInstance3D and str(child.name).begins_with("Pylon_"):
				seen += 1
				var key := "%s/%s" % [node.name, child.name]
				if not table.has(key):
					_fail("pylon %s is not in pylons.falls -- re-bake the table" % key)
	var standing: Array[String] = []
	for key: String in table.keys():
		if table[key] == null:
			standing.append(key)
	standing.sort()
	if standing != EXPECTED_STANDING:
		_fail("authored left-standing pylons are %s, expected %s" % [str(standing), str(EXPECTED_STANDING)])
	if table.size() != seen:
		_fail("pylons.falls has %d entries for %d pylons in the world" % [table.size(), seen])
	print("pylons.falls covers %d pylons; %d authored to stay standing %s" % [seen, standing.size(), str(standing)])


func _pylon_poses(world: Node, healing: Node) -> Dictionary:
	var out := {}
	for raw: Variant in (healing.call("toppled_pylons") as Array):
		var pylon := raw as Node3D
		if pylon != null and is_instance_valid(pylon):
			out[str(world.get_path_to(pylon))] = pylon.global_transform
	return out


func _same_pose(a: Transform3D, b: Transform3D) -> bool:
	return a.origin.distance_to(b.origin) < 0.02 and a.basis.x.distance_to(b.basis.x) < 0.02 \
		and a.basis.y.distance_to(b.basis.y) < 0.02 and a.basis.z.distance_to(b.basis.z) < 0.02


var _field: RefCounted = null


func _heightfield() -> RefCounted:
	if _field == null:
		_field = HEIGHTFIELD.new()
	return _field


func _polyline_distance(point: Vector2, line: PackedVector2Array) -> float:
	var nearest := INF
	for i in line.size() - 1:
		var a := line[i]
		var along := line[i + 1] - a
		var t := 0.0
		if along.length_squared() >= 0.0001:
			t = clampf((point - a).dot(along) / along.length_squared(), 0.0, 1.0)
		nearest = minf(nearest, point.distance_to(a + along * t))
	return nearest


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


func _healing_config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/meadow_healing.json"))
	return parsed if parsed is Dictionary else {}
