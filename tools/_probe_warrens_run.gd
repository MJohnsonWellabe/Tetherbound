extends SceneTree

## BAND2-63-WARRENS: what a player actually meets walking the Burrow Warrens.
##
##   godot --headless --path . --script tools/_probe_warrens_run.gd
##
## `tests/smoke_warrens.gd` already proves the cave is a real place -- walls
## that stop a CharacterBody3D, a floor under the hill, a door that is shut
## until the guardian falls, a prize that pays once. It deliberately does not
## answer the questions prompt 63's evidence run asks, which are about the
## EXPERIENCE of the dungeon rather than its geometry:
##
##   * how long is it? (the lane brief's "dungeon duration", still missing)
##   * is the route through it readable, or is the deepest chamber found by
##     walking into walls?
##   * is there anything down here that says Team Tether has been working the
##     seam -- prompt 63's own required-dungeon bullet, which the band had
##     nothing for inside the cave until this pass?
##   * does the guardian read as the thing at the bottom before the fight
##     starts, or as one more Burrowback with a bigger number?
##
## So this walks the cave and reports metres and seconds rather than pass/fail.
## It is a PROBE, not a test: it prints what it found and exits 0 unless
## something is actually broken, because "the dungeon takes four minutes" is
## evidence for a report, not an assertion to pin.
##
## It drives the player through the PLAYER'S OWN CONTROLLER -- real
## `move_forward` input with the camera yawed at the next chamber -- and not by
## writing `velocity` directly the way `tests/smoke_warrens.gd::_push` does.
## That distinction cost this pass an hour and is worth writing down: the
## direct-drive version reported the player STUCK 6.5 m short of the mouth
## chamber, which looks exactly like a blocked entrance and is not one.
## `player_controller.gd::_try_step_up()` is what gets a CharacterBody3D over
## the cave's own doorway sill, it runs in `_physics_process`, and `_push`
## suspends `_physics_process` on purpose. A harness that turns off the step
## logic measures a cave nobody can walk into. Duration evidence has to come
## from the body the player actually drives.
##
## The walk speed is the player's own, read from the shipped controller config,
## so the duration below is the duration a player walking it would get and not
## an artefact of a test harness sprinting.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
## How close to a leg's destination counts as arrived. A chamber is metres
## across; standing anywhere in it is standing in it.
const ARRIVED_M := 3.0
## A leg that has not arrived by here has run into something, and the probe
## says so rather than pushing forever.
const LEG_FRAME_BUDGET := 900

var _walk_speed := 4.0
var _total_m := 0.0
var _total_s := 0.0
## `--trace` prints the body's own local position through a leg. Off by default
## because the useful output of this probe is four lines, not four hundred.
var _trace := false


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	var warrens: Node3D = world.get_node_or_null(^"BurrowWarrens") as Node3D
	if player == null or warrens == null:
		print("probe FAIL: the scene has no Player or no BurrowWarrens node")
		quit(1)
		return
	_walk_speed = _player_walk_speed()
	_trace = "--trace" in OS.get_cmdline_user_args()

	print("")
	print("=== Burrow Warrens driven run =========================================")
	print("walk speed %.1f m/s (from data/config/movement.json)" % _walk_speed)

	_report_dressing(warrens)
	_report_guardian(warrens)
	await _walk_the_route(world, player, warrens)
	_report_branch(warrens)

	print("")
	print("=== totals ============================================================")
	print("route walked: %.0f m, %.0f s at walking pace, one way, no fights" % [_total_m, _total_s])
	print("with the five resident fights and the guardian at ~45-60 s each, plus")
	print("four rootstone deposits to break out, a played clear lands around")
	print("%.0f-%.0f minutes." % [(_total_s * 2.0 + 6.0 * 45.0) / 60.0, (_total_s * 2.0 + 6.0 * 60.0 + 120.0) / 60.0])
	quit(0)


## --- the walk ---------------------------------------------------------------

## Mouth to den the way a first-time player goes: in through the entrance,
## through the hall, into the den. Each leg is pushed toward the next chamber's
## own marker, and what is measured is whether a straight push GETS there --
## a route that needs the player to hunt for the opening is a route that fails
## this even though the geometry is fine.
func _walk_the_route(world: Node, player: CharacterBody3D, warrens: Node3D) -> void:
	print("")
	print("--- route -------------------------------------------------------------")
	# Waypoints, not chamber centres alone. A passage's own side walls overlap
	# the chamber wall they cut through by `wall_thickness`, so the last metre
	# of each wall stands proud INSIDE the room as a stub at the corner of the
	# doorway. A player steers round it without noticing; a probe walking a
	# dead-straight line into the far room's centre wedges against the stub and
	# reports the dungeon impassable, which is a fact about the probe. So each
	# leg aims at the doorway first and the room second, the way a person walks
	# through a door.
	# From the road, not from the doorstep. `marker("entrance")` is three
	# metres out; the question a region asks first is whether the mouth can be
	# reached from the spine at all, and Pell's stand is where the spine puts
	# the player (trainers.json order 2001).
	# The `warren_undertrail` loop's own second point (terrain_playground.json),
	# the piece of road nearest the mouth -- not Pell's square metre, which the
	# first run of this dropped the player straight on top of.
	var road := Vector3(-380.0, 0.0, 2540.0)
	road.y = float(warrens.call("ground_height_at", road.x, road.z)) + 1.5
	var entrance: Vector3 = warrens.call("marker", "entrance")
	await _put_down(player, road)
	# The residents are aggressive by design and there are seven of them in a
	# cave 47 m deep: left running they close on the player, block the corridor
	# with their own capsules and eventually start a real fight, which takes
	# input ownership and zeroes movement. That is the RIGHT behaviour and it
	# is what makes the walk-through take longer than the number below -- but
	# it makes this leg measure "how long does a fight last", which
	# smoke_combat.gd already owns. Frozen here so the route measures the
	# ROUTE; the fight budget is added back in the totals at the end.
	_quieten_the_residents(warrens)
	await _leg(player, warrens, "approach", entrance)
	for leg: String in ["mouth", "hall", "den"]:
		for point: Vector3 in _approach(warrens, leg):
			await _leg(player, warrens, leg, point)
	# The optional branch, from the den, once the door is open.
	var progression := _progression()
	if progression != null:
		progression.call("set_flag", "warrens_cleared")
	warrens.call("grant_clear_reward")
	for point: Vector3 in _approach(warrens, "vault"):
		await _leg(player, warrens, "vault", point)


## The doorway into `chamber` (if this file knows one) and then the chamber
## itself. Doorways are derived from the shipped passage table, not guessed.
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
		var floor_y: float = float(warrens.call("marker", chamber).y)
		points.append(Vector3(mid.x, 0.0, mid.y))
	var out: Array = []
	for local: Vector3 in points:
		# `marker()` hands back global metres; the doorway is authored in the
		# cave's local frame, so it goes through the node's own transform.
		out.append(warrens.to_global(Vector3(local.x, warrens.call("marker", chamber).y \
			- warrens.global_position.y, local.z)))
	out.append(warrens.call("marker", chamber))
	return out


func _leg(player: CharacterBody3D, warrens: Node3D, chamber: String, target: Vector3) -> void:
	var start := player.global_position
	var walked := 0.0
	var frames := 0
	var rig: Node3D = _camera_rig(player)
	Input.action_press("move_forward")
	while frames < LEG_FRAME_BUDGET:
		var to_target := target - player.global_position
		to_target.y = 0.0
		if to_target.length() <= ARRIVED_M:
			break
		# Movement is camera-relative (`player_controller.gd::_apply_movement`
		# takes the rig's `planar_basis()`), so steering IS turning the camera.
		# Same yaw convention the rig's own `look_at`-style setter uses at
		# camera_rig.gd:239 -- the camera sits behind the direction of travel.
		if rig != null:
			var yaw := atan2(-to_target.x, -to_target.z)
			rig.set("yaw", yaw)
			rig.rotation = Vector3(rig.rotation.x, yaw, 0.0)
		var before := player.global_position
		await physics_frame
		walked += Vector2(player.global_position.x - before.x,
			player.global_position.z - before.z).length()
		frames += 1
		if _trace and frames % 30 == 0:
			var local: Vector3 = warrens.to_local(player.global_position)
			print("      t=%4.1fs local %6.2f, %5.2f, %6.2f  on_floor=%s on_wall=%s vel=%.1f" % [
				float(frames) / float(Engine.physics_ticks_per_second),
				local.x, local.y, local.z, str(player.is_on_floor()), str(player.is_on_wall()),
				Vector2(player.velocity.x, player.velocity.z).length()])
			if is_zero_approx(Vector2(player.velocity.x, player.velocity.z).length()):
				var space := player.get_world_3d().direct_space_state
				var query := PhysicsShapeQueryParameters3D.new()
				var sphere := SphereShape3D.new()
				sphere.radius = 1.4
				query.shape = sphere
				query.transform = Transform3D(Basis(), player.global_position + Vector3.UP)
				query.collide_with_bodies = true
				query.exclude = [player.get_rid()]
				var ray := PhysicsRayQueryParameters3D.create(
					player.global_position + Vector3.UP * 0.9,
					player.global_position + Vector3.UP * 0.9 + (target - player.global_position).normalized() * 3.0)
				ray.exclude = [player.get_rid()]
				var forward_hit := space.intersect_ray(ray)
				if not forward_hit.is_empty():
					var point: Vector3 = warrens.to_local(forward_hit["position"])
					print("        ray ahead hits %s at local %.2f, %.2f, %.2f normal %.2f, %.2f, %.2f" % [
						str((forward_hit["collider"] as Node3D).name), point.x, point.y, point.z,
						forward_hit["normal"].x, forward_hit["normal"].y, forward_hit["normal"].z])
				for hit: Dictionary in space.intersect_shape(query, 12):
					var body: Object = hit.get("collider")
					if body == null:
						continue
					var where: Vector3 = warrens.to_local((body as Node3D).global_position)
					print("        within 1.4m: %s parent %s at local %.2f, %.2f, %.2f" % [
						str((body as Node3D).name), str((body as Node3D).get_parent().name),
						where.x, where.y, where.z])
			for i in player.get_slide_collision_count():
				var hit := player.get_slide_collision(i)
				var collider := hit.get_collider()
				print("        touching %s (%s) normal %.2f, %.2f, %.2f" % [
					str(collider.name) if collider != null else "?",
					str(collider.get_parent().name) if collider != null and collider.get_parent() != null else "?",
					hit.get_normal().x, hit.get_normal().y, hit.get_normal().z])
	Input.action_release("move_forward")
	var seconds := float(frames) / float(Engine.physics_ticks_per_second)
	var remaining: float = player.global_position.distance_to(target)
	_total_m += walked
	_total_s += seconds
	var verdict := "arrived" if remaining <= ARRIVED_M else "STUCK %.1fm short" % remaining
	print("  %-6s  %5.1f m walked, %4.1f s, straight-line %5.1f m  [%s]" % [
		chamber, walked, seconds, start.distance_to(target), verdict])


## Kept, unused by the walk below, and worth keeping: it is how this pass
## measured the route BEFORE `burrow_warrens.gd::_clear_the_ground_the_cave_
## stands_on()` existed, and it is the tool for asking "would this site work
## once the scatter is told about it" at any future site.
##
## The cave moved; the baked scatter has not been told.
##
## `data/config/bands/band2_stone_and_root/vegetation.json` now authors a
## 30 m clearing at the new mouth, and it does NOT take effect until the
## coordinator re-bakes: `scatter_bake.gd::config_fingerprint()` hashes only
## the two head configs, so a band clearing changes where scatter should go
## without invalidating the bake (GATE_D_LANE_CONTRACT.md sec4, inherited by
## every lane, not this lane's to fix). The live bake therefore still has a
## `CommonTree_3` standing in the doorway, which is exactly what the first run
## of this probe walked into.
##
## So the walk below is measured against the state the re-bake will produce:
## the scatter colliders inside the authored clearing are dropped from their
## batches, which is what the bake would have done by never placing them. The
## number removed is printed, because a report that quietly simulated its own
## success would be worthless.
@warning_ignore("unused_private_class_variable")
func _simulate_the_pending_rebake(world: Node, warrens: Node3D) -> void:
	var vegetation: Node = world.get_node_or_null(^"Vegetation")
	if vegetation == null:
		return
	var batches: Variant = vegetation.get("_collision_batches")
	if not batches is Array:
		print("  (could not reach the scatter's collision batches; walking the LIVE bake)")
		return
	var mouth: Vector3 = warrens.call("marker", "mouth")
	var radius := 30.0
	var dropped := 0
	for batch: Variant in batches as Array:
		var placements: Array = (batch as Dictionary)["placements"]
		var resident: Array = (batch as Dictionary)["resident"]
		for i in range(placements.size() - 1, -1, -1):
			var spot: Vector3 = (placements[i] as Dictionary)["position"]
			if Vector2(spot.x - mouth.x, spot.z - mouth.z).length() > radius:
				continue
			if resident[i] != null:
				(resident[i] as Node).queue_free()
			resident.remove_at(i)
			placements.remove_at(i)
			dropped += 1
	print("  simulating the pending re-bake: %d scatter colliders dropped inside the" % dropped)
	print("  authored %.0fm clearing at the mouth (band2 vegetation.json order 2002)" % radius)


## Physics off, aggression off, exactly as tests/smoke_warrens.gd does it --
## and for the same reason it does NOT hide or free them: the warrens reads
## "the guardian is gone" partly from the body being invisible.
func _quieten_the_residents(warrens: Node3D) -> void:
	var bodies: Array = (warrens.call("population") as Array).duplicate()
	var guardian: Node3D = warrens.call("guardian")
	if guardian != null:
		bodies.append(guardian)
	for body: Variant in bodies:
		if not is_instance_valid(body as Node3D):
			continue
		(body as Node3D).set("aggressive", false)
		(body as Node3D).set_physics_process(false)


## The rig the player's own movement is relative to. It is a sibling in the
## playground scene rather than a child of the player, so this asks the player
## for it if it exposes one and falls back to a search from the scene root.
func _camera_rig(player: CharacterBody3D) -> Node3D:
	var named: Variant = player.get("_camera_rig")
	if named is Node3D and is_instance_valid(named as Node3D):
		return named as Node3D
	return _find_rig(player.get_parent())


func _find_rig(node: Node) -> Node3D:
	if node == null:
		return null
	for child in node.get_children():
		if child is Node3D and child.has_method("planar_basis"):
			return child as Node3D
	return null


## --- what is down there -----------------------------------------------------

## Prompt 63's required-dungeon bullet: evidence of Team Tether activity. This
## counts what actually stood up, and where it is relative to the light the
## player reads it by -- a crate in an unlit corner of a deliberately dark cave
## is a crate nobody will ever see.
func _report_dressing(warrens: Node3D) -> void:
	print("")
	print("--- Team Tether evidence inside the cave -------------------------------")
	var placer: Node3D = warrens.get_node_or_null(^"Dressing") as Node3D
	if placer == null:
		print("  NONE -- no Dressing node; the cave has no authored props at all")
		return
	var props: Array[Node3D] = []
	for child in placer.get_children():
		if child is Node3D and not child is StaticBody3D:
			props.append(child as Node3D)
	if props.is_empty():
		print("  NONE -- the Dressing node stood up empty")
		return
	var lights: Array[OmniLight3D] = []
	_collect_lights(warrens, lights)
	for prop: Node3D in props:
		var nearest := 999.0
		var energy := 0.0
		for light: OmniLight3D in lights:
			var d: float = light.global_position.distance_to(prop.global_position)
			if d < nearest:
				nearest = d
				energy = light.light_energy
		var lit := "lit" if nearest < 12.0 else "DARK"
		print("  %-18s at %6.1f, %5.1f, %6.1f   nearest light %4.1f m (energy %.2f) [%s]" % [
			prop.name, prop.global_position.x, prop.global_position.y, prop.global_position.z,
			nearest, energy, lit])
	print("  %d props placed" % props.size())


## Does the guardian read as the thing at the bottom BEFORE a single move is
## thrown? Three separate strings decide that and they live on two different
## objects -- see burrow_warrens.gd::_dress_the_guardian.
func _report_guardian(warrens: Node3D) -> void:
	print("")
	print("--- the guardian, before the fight starts ------------------------------")
	var guardian: Node3D = warrens.call("guardian")
	if guardian == null or not is_instance_valid(guardian):
		print("  no guardian placed")
		return
	var instance: Object = guardian.get("instance")
	var pivot: Node3D = guardian.call("model_pivot") as Node3D if guardian.has_method("model_pivot") else null
	print("  world prompt reads:  \"Engage %s\"" % str(guardian.get("display_name")))
	print("  combat plate reads:  \"%s\"  LEVEL %d" % [
		str(instance.call("label")) if instance != null else "?",
		int(instance.get("level")) if instance != null else 0])
	print("  species underneath:  %s (kept, so catching it does not lose what it is)" % [
		str(instance.get("display_name")) if instance != null else "?"])
	print("  silhouette scale:    %.2fx the ordinary body (collider untouched)" % [
		pivot.scale.x if pivot != null else 1.0])
	var deepest := 0
	for body: Variant in warrens.call("population"):
		var resident: Object = (body as Node3D).get("instance") if is_instance_valid(body as Node3D) else null
		if resident != null:
			deepest = maxi(deepest, int(resident.get("level")))
	print("  deepest resident:    level %d" % deepest)


func _report_branch(warrens: Node3D) -> void:
	print("")
	print("--- the optional branch ------------------------------------------------")
	print("  vault door open after the clear: %s" % str(bool(warrens.call("branch_is_open"))))
	var heartstone: Node3D = warrens.get_node_or_null(^"Heartstone") as Node3D
	print("  heartstone on its plinth: %s" % ("yes" if heartstone != null else "no (already taken this save)"))


## --- harness ----------------------------------------------------------------

func _collect_lights(node: Node, into: Array[OmniLight3D]) -> void:
	if node is OmniLight3D:
		into.append(node as OmniLight3D)
	for child in node.get_children():
		_collect_lights(child, into)


func _put_down(player: CharacterBody3D, at: Vector3) -> void:
	player.global_position = at
	player.velocity = Vector3.ZERO
	for i in 40:
		await physics_frame


func _player_walk_speed() -> float:
	var file := FileAccess.open("res://data/config/movement.json", FileAccess.READ)
	if file == null:
		return 5.0
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return 5.0
	# The one nested block movement.json keeps its walk speed in; falling back
	# to the top level rather than guessing if that shape ever changes.
	for section: Variant in (parsed as Dictionary).values():
		if section is Dictionary and (section as Dictionary).has("walk_speed"):
			return float((section as Dictionary)["walk_speed"])
	return float((parsed as Dictionary).get("walk_speed", 5.0))


func _config() -> Dictionary:
	var file := FileAccess.open("res://data/config/burrow_warrens.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _progression() -> RefCounted:
	var game := root.get_node_or_null(^"/root/Game")
	return game.get("progression") if game != null else null
