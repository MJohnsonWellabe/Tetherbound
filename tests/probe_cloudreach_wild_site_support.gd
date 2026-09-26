extends SceneTree

## Read-only support probe for Cloudreach ground wild sites. Boots the real
## Cloudreach scene with its production runtime mounted, then, per site,
## spawns every species pair its table can roll through the production
## director's own `spawn_wild` (same offsets/anchor as `_spawn_available_sites`)
## and reports whether the whole site is supported. With --search it also scans
## nearby points for one that supports every pair and prints the closest.
##
##   godot --headless --path . --script tests/probe_cloudreach_wild_site_support.gd \
##     -- --sites=road_visibility_windscar_floor_loop_05,road_visibility_windscar_floor_loop_06 --search
##
## Prints `[site_support] <id> ok=<bool> ...` and `[site_search] <id> best=[x,y,z] moved=<m>`.

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")

var _director: Node


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var ids: Array = []
	var search := false
	var repair := false
	var tries := {}
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--sites="):
			ids = Array(arg.trim_prefix("--sites=").split(",", false))
		elif arg == "--search":
			search = true
		elif arg == "--repair":
			repair = true
		elif arg.begins_with("--try="):
			# --try=<site id>:x,y,z|x,y,z  authored candidates, resolved the way
			# the runtime resolves a site (world._resource_position).
			var spec := arg.trim_prefix("--try=")
			tries[spec.get_slice(":", 0)] = Array(spec.get_slice(":", 1).split("|", false))
	# The production runtime (CloudreachRuntime) mounts only when the Game is
	# in the Cloudreach realm; its modules (perches, aerie, battle yards,
	# summit) register the surfaces some sites stand on.
	var game := root.get_node("Game")
	game.call("reset_for_new_game")
	for flag: String in ["warden_defeated", "realm_key_cloudreach", "realm_gate_cloudreach_unlocked",
			"fly_traversal_unlocked", "windscar_aerie_prepared", "sky_shrine_reached",
			"cloudreach_upper_route_unlocked"]:
		game.get("progression").call("set_flag", flag)
	game.set("current_realm", "cloudreach")
	var world := SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 20:
		await physics_frame
	_director = world.get_node("CloudreachRuntime").get("director")
	# Clear whatever proximity spawning already placed, so only probe bodies
	# occupy the ground.
	for wild: Variant in (_director.get("_wild_creatures") as Array).duplicate():
		if is_instance_valid(wild):
			(wild as Node).queue_free()
	(_director.get("_wild_creatures") as Array).clear()
	(_director.get("_wild_homes") as Dictionary).clear()
	await physics_frame
	var config: Dictionary = _director.get("encounter_config")
	var chapter: Dictionary = _director.get("chapter")
	var failed := 0
	var repairs := {}
	for raw: Variant in config.get("wild_sites", []):
		var site: Dictionary = raw
		var id := str(site.get("id", ""))
		if (not ids.is_empty() and not ids.has(id)) or str(site.get("placement_mode", "ground")) != "ground":
			continue
		var table: Dictionary = _director.call("find_id", chapter.get("encounter_tables", []), str(site["table_id"]))
		var species: Array[String] = []
		for entry: Dictionary in table.get("entries", []):
			species.append(str(entry.get("placeholder_species", "")))
		var centre := _vec3(site["position"])
		if tries.has(id):
			for raw_try: String in tries[id]:
				var parts := raw_try.split(",")
				var authored := Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
				var resolved: Vector3 = world.call("_resource_position", authored)
				var tried := _site_supported(site, resolved, species)
				print("[site_try] %s authored=%s resolved=%s ok=%s" % [id, authored, resolved, tried.ok])
			continue
		var result := _site_supported(site, centre, species)
		print("[site_support] %s ok=%s centre=%s detail=%s" % [id, result.ok, centre, result.detail])
		if not result.ok:
			failed += 1
			if search:
				_search(site, centre, species)
			if repair:
				var fixed := _repair(site, centre, species, world)
				if fixed.is_finite():
					repairs[id] = [snappedf(fixed.x, 0.001), snappedf(fixed.y, 0.001), snappedf(fixed.z, 0.001)]
					print("[site_repair] %s to=%s moved=%.2f" % [id, fixed, centre.distance_to(fixed)])
				else:
					print("[site_repair] %s none" % id)
	print("[site_support] failed_sites=%d" % failed)
	if repair:
		print("[site_repair_json] " + JSON.stringify(repairs))
	quit(0)


func _site_supported(site: Dictionary, centre: Vector3, species: Array[String]) -> Dictionary:
	var count := int(site.get("count", 1))
	var radius := float(site.get("radius_m", 4.0))
	var bad: Array[String] = []
	# Every ordered combination the table can roll for this site.
	var combos: Array = [[]]
	for _i in count:
		var next: Array = []
		for combo: Array in combos:
			for s in species:
				next.append(combo + [s])
		combos = next
	for combo: Array in combos:
		var spawned: Array[Node3D] = []
		for index in count:
			var angle := index * TAU / maxi(1, count)
			var at := centre + Vector3(cos(angle), 0, sin(angle)) * radius * 0.5
			var wild: Node3D = _director.call("spawn_wild", str(combo[index]), at,
				{"name": "Probe_%d" % index, "site_anchor": centre, "aggressive": false, "wander_radius": radius})
			if wild == null:
				bad.append("%s#%d" % [combo[index], index])
			else:
				spawned.append(wild)
		for wild in spawned:
			(_director.get("_wild_creatures") as Array).erase(wild)
			(_director.get("_wild_homes") as Dictionary).erase(wild)
			wild.free()
	return {"ok": bad.is_empty(), "detail": ",".join(bad)}


func _search(site: Dictionary, centre: Vector3, species: Array[String]) -> void:
	var world: Node = _director.get("realm_world")
	var best := Vector3.INF
	for ring in range(1, 9):
		var r := ring * 2.0
		var steps := 8 * ring
		for i in steps:
			var angle := i * TAU / steps
			var probe := centre + Vector3(cos(angle) * r, 0, sin(angle) * r)
			probe.y = float(world.call("ground_height_near", probe))
			if not is_finite(probe.y):
				continue
			if bool(_site_supported(site, probe, species).ok):
				best = probe
				break
		if best.is_finite():
			break
	print("[site_search] %s best=%s moved=%.2f" % [str(site.get("id", "")), best,
		centre.distance_to(best) if best.is_finite() else -1.0])


## Road-shoulder repair: slide the centre toward the nearest point of its
## nearest ground route (same side, same station first), onto the route's own
## collision ribbon, which is the surface `ground_height_near` registers.
func _repair(site: Dictionary, centre: Vector3, species: Array[String], world: Node) -> Vector3:
	var best_d := INF
	var nearest := Vector3.INF
	var along := Vector3.ZERO
	for raw: Variant in (world.call("config_data") as Dictionary).get("routes", []):
		var polyline: Array = (raw as Dictionary).get("polyline", [])
		for i in polyline.size() - 1:
			var a := _vec3(polyline[i])
			var b := _vec3(polyline[i + 1])
			var ab := Vector2(b.x - a.x, b.z - a.z)
			if ab.length_squared() < 0.01:
				continue
			var t := clampf(Vector2(centre.x - a.x, centre.z - a.z).dot(ab) / ab.length_squared(), 0.0, 1.0)
			var point := a.lerp(b, t)
			var d := Vector2(centre.x - point.x, centre.z - point.z).length()
			if d < best_d:
				best_d = d
				nearest = point
				along = Vector3(ab.x, 0, ab.y).normalized()
	if best_d > 12.0:
		return Vector3.INF
	var lateral := Vector3(centre.x - nearest.x, 0, centre.z - nearest.z)
	lateral = lateral.normalized() if lateral.length() > 0.01 else Vector3.ZERO
	for shift in [0.0, 2.0, -2.0, 4.0, -4.0, 6.0, -6.0]:
		for offset in [2.5, 2.0, 1.5, 1.0, 0.5]:
			var probe: Vector3 = nearest + along * shift + lateral * offset
			probe.y = float(world.call("ground_height_near", Vector3(probe.x, centre.y, probe.z)))
			if not is_finite(probe.y):
				continue
			if bool(_site_supported(site, probe, species).ok):
				return probe
	return Vector3.INF


func _vec3(raw: Variant) -> Vector3:
	var a: Array = raw
	return Vector3(float(a[0]), float(a[1]), float(a[2]))
