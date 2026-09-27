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
	var offroad: Array = []
	var offroad_at := {}
	var near := {}
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--sites="):
			ids = Array(arg.trim_prefix("--sites=").split(",", false))
		elif arg == "--search":
			search = true
		elif arg == "--repair":
			repair = true
		elif arg.begins_with("--offroad="):
			# --offroad=<id>,<id>: nearest supported point >= ROAD_CLEAR_M from
			# every ground route line, searched around the runtime-resolved centre.
			offroad = Array(arg.trim_prefix("--offroad=").split(",", false))
		elif arg.begins_with("--offroad-at="):
			# --offroad-at=<id>@x,y,z|<id>@x,y,z: search around this anchor instead.
			for pair: String in arg.trim_prefix("--offroad-at=").split("|", false):
				var xyz := pair.get_slice("@", 1).split(",")
				offroad_at[pair.get_slice("@", 0)] = Vector3(float(xyz[0]), float(xyz[1]), float(xyz[2]))
				offroad.append(pair.get_slice("@", 0))
		elif arg.begins_with("--near="):
			# --near=<id>@x,y,z@radius: every supported point (road allowed)
			# within radius of the anchor, nearest first.
			var parts := arg.trim_prefix("--near=").split("@")
			var xyz := parts[1].split(",")
			near[parts[0]] = {"at": Vector3(float(xyz[0]), float(xyz[1]), float(xyz[2])), "r": float(parts[2])}
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
	var authored := {}
	var raw_config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_encounters.json"))
	for raw_site: Dictionary in raw_config.get("wild_sites", []):
		authored[str(raw_site.get("id", ""))] = _vec3(raw_site.get("position", [0, 0, 0]))
	var chapter: Dictionary = _director.get("chapter")
	var failed := 0
	var repairs := {}
	for raw: Variant in config.get("wild_sites", []):
		var site: Dictionary = raw
		var id := str(site.get("id", ""))
		if not ids.is_empty() and not ids.has(id):
			continue
		if str(site.get("placement_mode", "ground")) == "air_patrol":
			var air := _air_patrol_supported(site, chapter)
			print("[site_support] %s ok=%s air_patrol detail=%s" % [id, air.ok, air.detail])
			if not air.ok:
				failed += 1
			continue
		if str(site.get("placement_mode", "ground")) != "ground":
			continue
		var table: Dictionary = _director.call("find_id", chapter.get("encounter_tables", []), str(site["table_id"]))
		var species: Array[String] = []
		for entry: Dictionary in table.get("entries", []):
			species.append(str(entry.get("placeholder_species", "")))
		var centre := _vec3(site["position"])
		if near.has(id):
			var anchor: Vector3 = near[id].at
			var r: float = near[id].r
			var found := 0
			var gx := -r
			while gx <= r:
				var gz := -r
				while gz <= r:
					var p := Vector3(anchor.x + gx, anchor.y, anchor.z + gz)
					if Vector2(gx, gz).length() <= r:
						var y := float(world.call("ground_height_near", p))
						if is_finite(y) and absf(y - anchor.y) <= 45.0:
							p.y = y
							if bool(_site_supported(site, p, species).ok):
								found += 1
								print("[site_near] %s ok at=%s from_anchor=%.1f" % [id, p, Vector2(gx, gz).length()])
					gz += 4.0
				gx += 4.0
			print("[site_near] %s found=%d" % [id, found])
			continue
		if tries.has(id):
			for raw_try: String in tries[id]:
				var parts := raw_try.split(",")
				var tried_at := Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
				var resolved: Vector3 = world.call("_resource_position", tried_at)
				var tried := _site_supported(site, resolved, species)
				print("[site_try] %s authored=%s resolved=%s ok=%s road_clear_m=%.1f" % [id, tried_at, resolved,
					tried.ok, _road_clearance(world, resolved)])
			continue
		var result := _site_supported(site, centre, species)
		print("[site_support] %s ok=%s centre=%s road_clear_m=%.1f detail=%s" % [id, result.ok, centre,
			_road_clearance(world, centre), result.detail])
		if offroad.has(id):
			_offroad_search(site, species, world, offroad_at.get(id, centre))
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


## Every member of an air patrol, for every species its table can roll,
## through the production `_spawn_air_patrol`: it must exist and hold its
## planned flight position.
func _air_patrol_supported(site: Dictionary, chapter: Dictionary) -> Dictionary:
	var table: Dictionary = _director.call("find_id", chapter.get("encounter_tables", []), str(site["table_id"]))
	var bad: Array[String] = []
	for entry: Dictionary in table.get("entries", []):
		var species := str(entry.get("placeholder_species", ""))
		for index in int(site.get("count", 1)):
			var wild: Node3D = _director.call("_spawn_air_patrol", species, site, index, 25)
			var plan: Dictionary = _director.call("air_patrol_member_plan", site, index)
			if wild == null:
				bad.append("%s#%d:null" % [species, index])
				continue
			if wild.global_position.distance_to(plan.get("position", Vector3.INF)) > 0.5:
				bad.append("%s#%d:at %s" % [species, index, wild.global_position])
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


const ROAD_CLEAR_M := 10.0


## Horizontal clearance from `at` to the nearest ground route's walkable edge
## (route line distance minus its half width), same-stratum lines only.
func _road_clearance(world: Node, at: Vector3) -> float:
	if (world.get("_all_route_lines") as Array).is_empty():
		world.call("_collect_all_route_lines")
	var best := INF
	for line: Dictionary in world.get("_all_route_lines"):
		var hit: Dictionary = world.call("_line_point_xz", line, at)
		if absf(float(hit["height"]) - at.y) > 12.0:
			continue
		best = minf(best, float(hit["distance"]) - float(line["half_width"]))
	return best


func _offroad_search(site: Dictionary, species: Array[String], world: Node, authored: Vector3) -> void:
	var candidates: Array = []
	var step := 5.0
	for gx in range(-60, 61):
		for gz in range(-60, 61):
			var p := Vector3(authored.x + gx * step, authored.y, authored.z + gz * step)
			var y := float(world.call("ground_height_near", p))
			if not is_finite(y) or absf(y - authored.y) > 45.0:
				continue
			p.y = y
			if _road_clearance(world, p) < ROAD_CLEAR_M:
				continue
			candidates.append(p)
	candidates.sort_custom(func(a: Vector3, b: Vector3) -> bool:
		return a.distance_squared_to(authored) < b.distance_squared_to(authored))
	var tested := 0
	for p: Vector3 in candidates:
		tested += 1
		if tested > 80:
			break
		if bool(_site_supported(site, p, species).ok):
			print("[site_offroad] %s best=%s from_authored=%.1f road_clear_m=%.1f candidates=%d" % [
				str(site.id), p, p.distance_to(authored), _road_clearance(world, p), candidates.size()])
			return
	print("[site_offroad] %s none candidates=%d tested=%d" % [str(site.id), candidates.size(), tested])


func _vec3(raw: Variant) -> Vector3:
	var a: Array = raw
	return Vector3(float(a[0]), float(a[1]), float(a[2]))
