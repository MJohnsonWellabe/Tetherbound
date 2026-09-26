extends SceneTree

## F12#0 walked witness (ACCEPTANCE §6.1 F12#0): "With the original five and no
## owned swimmer, level-0 human swimming finishes every mandatory Tidewake hop
## with at least 20% stamina after 15% steering deviation."
##
## Unlike `smoke_water_swimming.gd --every-hop` (one position write + forced
## rest-to-full per hop), this chains the mandatory routes CONTINUOUSLY in one
## production Water scene:
##   * ONE disclosed position write: the chain's first route departure anchor.
##   * Each hop is swum with real `move_forward` input along a ~15 percent
##     commanded zigzag of the authored polyline, with level-0 swim efficiency
##     (swimming XP cleared after every movement frame, min efficiency asserted).
##   * Between hops of one route: no position write. The next hop starts from
##     wherever the real arrival left the trainer (distance to the authored
##     start is reported and must be <= 1 m).
##   * Between routes: no position write. The trainer walks the arrival island
##     to the next route's departure anchor with real LEFT-STICK input
##     (`tests/helpers/stick_navigator.gd`), following the harness-only baked
##     ground A* plan from `tests/smoke_water_pocket_walk_claim.gd::plan_route`.
##   * No stamina write ever. At each hop start the stamina left by the previous
##     swim/walk is REPORTED (`arrive_pct`). By default the trainer then stands
##     idle on the dry shoal (no input, no write) until natural regen is full --
##     `rest_frames` reports how long; `--no-rest` swims on immediately instead.
##
## Disclosed fixtures: the original five granted into the real Game.party via
## PartySeam.add (same as `--original-five` in smoke_water_swimming.gd); every
## chained route's `required_departure_flag` set true at start (story objectives
## are NOT earned here); `current_realm = "water"`; one start position write.
##
##   godot --headless --path . --script tests/smoke_water_hop_walked.gd --
##       [--variant=sheltered|direct] [--from=<i>] [--to=<i>] [--no-rest]
## Route indices 0..6 = first_shore, reedhaven, brine_steps, shellwatch,
## tidal_cradle, salt_crown, sluice_isle. `direct` exists only for 0..3.
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const SAVE := preload("res://scripts/save/save_game.gd")
const NAV := preload("res://tests/helpers/stick_navigator.gd")
const PLANNER := preload("res://tests/smoke_water_pocket_walk_claim.gd")
const PARTY_SEAM := preload("res://scripts/story/party_seam.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const MOVEMENT_CONFIG := "res://data/config/movement.json"
const PLAYER_SKILLS := ["running", "catching", "riding", "swimming", "flying"]
const EDGES := ["first_shore_to_reedhaven", "reedhaven_to_brine_steps", "brine_steps_to_shellwatch",
	"shellwatch_to_tidal_cradle", "tidal_cradle_to_salt_crown", "salt_crown_to_sluice_isle",
	"sluice_isle_to_veilfall"]
## Same fixture as smoke_water_swimming.gd ORIGINAL_FIVE (see its comment and
## ralph/reports/TIDEWAKE/f12_every_hop_original_five/PROOF.md for provenance).
const ORIGINAL_FIVE := [
	{"species": "terrapup", "level": 44},
	{"species": "bramblebun", "level": 43},
	{"species": "mudsnout", "level": 42},
	{"species": "pipwing", "level": 42},
	{"species": "trailpup", "level": 41},
]
const STEER_RATIO := 1.155

var game: Node
var world: Node3D
var player: CharacterBody3D
var camera: Node3D
var swimming: Node
var navigator: RefCounted
var config: Dictionary
var assertions := 0
var finished := false
var observed_swim_distance := 0.0
var hop_minimum_stamina := INF
var max_gain_per_frame := 0.0
var tracking := false
var pinned_minimum_efficiency := 1.0
var position_writes := 0
var party_species: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(3300.0).timeout.connect(func() -> void:
		if not finished:
			_fail("3300 second watchdog expired"))
	var variant := _arg("--variant=", "sheltered")
	var first := int(_arg("--from=", "0"))
	var last := int(_arg("--to=", "6" if variant == "sheltered" else "3"))
	var rest := not OS.get_cmdline_user_args().has("--no-rest")
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.save_system = SAVE.new("user://smoke_water_hop_walked_%d/" % Time.get_ticks_usec())
	game.current_realm = "water"
	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 1200:
		await physics_frame
		if bool(world.call("shell_build_complete")):
			break
	if not _expect(bool(world.call("shell_build_complete")), "Water shell failed to build"):
		return
	player = world.get_node("Player")
	camera = world.get_node("CameraRig")
	swimming = player.get("swim_controller")
	config = world.get("config")
	navigator = NAV.new(self, player, camera, _stick)
	if not _expect(swimming != null, "production player has no SwimController"):
		return
	var routes: Array[Dictionary] = []
	for index in range(first, last + 1):
		var route := _route("%s_%s" % [EDGES[index], variant])
		if not _expect(not route.is_empty(), "route %s_%s is not authored" % [EDGES[index], variant]):
			return
		if not _expect(bool(route.get("main_path", false)) and str(route.get("intended_traversal", "")) == "human_level_0"
			and not bool(route.get("requires_compatible_active_swim_mount", true))
			and (route.get("required_equipment", []) as Array).is_empty(),
			"%s is not a mandatory level-0 human main-path crossing" % route.id):
			return
		routes.append(route)
	party_species = _grant_original_five()
	if party_species.is_empty():
		return
	if not _expect(world.get_node_or_null("RidingController") != null and world.get_node_or_null("MountedSwimming") != null,
		"original-five checks need production RidingController and MountedSwimming"):
		return
	# Disclosed fixture: open every chained route's departure current up front.
	var flags: Array[String] = []
	for route: Dictionary in routes:
		var flag := str(route.get("required_departure_flag", ""))
		if not flag.is_empty():
			game.world.flags.call("set_flag", flag, true)
			flags.append(flag)
			if not _expect(game.world.flags.has(flag), "departure flag fixture %s did not stick" % flag):
				return
	print("FIXTURE departure_flags=%s" % ",".join(flags))
	var vitals: RefCounted = player.get("vitals")
	var movement: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MOVEMENT_CONFIG))
	var configured_regen := float((movement.get("stamina", {}) as Dictionary).get("regen_per_second", 0.0))
	# The ONE position write of the whole chain.
	var start := _anchor(str(routes[0].from_anchor))
	start.y = float(world.call("ground_height_at", start.x, start.z)) + 0.15
	if not _expect(is_finite(start.y), "chain start has no baked height"):
		return
	player.global_position = start
	player.velocity = Vector3.ZERO
	position_writes += 1
	print("FIXTURE position_write=1 at=%s (%s)" % [start, routes[0].from_anchor])
	await _frames(45)
	if not _expect(player.is_on_floor() and not swimming.is_swimming(), "chain start did not settle dry"):
		return
	var started := Time.get_ticks_msec()
	var worst := INF
	var hop_count := 0
	var walk_total := 0.0
	var summary: Array[String] = []
	tracking = true
	for route_index in routes.size():
		var route: Dictionary = routes[route_index]
		var route_id := str(route.id)
		if route_index > 0:
			var from_xz := player.global_position
			var target := _anchor(str(route.from_anchor))
			var walked: Variant = await _walk_island(target, "%s island walk" % route_id)
			if walked == null:
				return
			walk_total += float(walked.metres)
			print("ISLAND WALK to=%s from=%s straight_m=%.2f walked_m=%.2f legs=%d spur_m=%.1f confined_resets=%d stamina_pct_after=%.2f" % [
				route.from_anchor, Vector2(from_xz.x, from_xz.z), Vector2(from_xz.x, from_xz.z).distance_to(Vector2(target.x, target.z)),
				float(walked.metres), int(walked.legs), float(walked.spur_m), int(walked.resets), float(vitals.stamina)])
		var stops: Array[String] = [str(route.from_anchor)]
		for rest_id: Variant in route.get("rest_anchor_ids", []):
			stops.append(str(rest_id))
		stops.append(str(route.to_anchor))
		var path: Array[Vector3] = [_anchor(stops[0])]
		for raw: Variant in route.get("polyline", []):
			path.append(_vector(raw as Array))
		path.append(_anchor(stops[-1]))
		var boundaries: Array[int] = [0]
		for index in range(1, stops.size() - 1):
			var rest_at := _anchor(stops[index])
			var found := -1
			for vertex in range(boundaries[-1] + 1, path.size() - 1):
				if Vector2(path[vertex].x - rest_at.x, path[vertex].z - rest_at.z).length() < 0.5:
					found = vertex
					break
			if not _expect(found > 0, "%s rest %s is not an ordered polyline vertex" % [route_id, stops[index]]):
				return
			boundaries.append(found)
		boundaries.append(path.size() - 1)
		var route_worst := INF
		var per_hop: Array[String] = []
		for hop in boundaries.size() - 1:
			var hop_path: Array[Vector3] = []
			for vertex in range(boundaries[hop], boundaries[hop + 1] + 1):
				hop_path.append(path[vertex])
			var hop_start := hop_path[0]
			var finish := hop_path[-1]
			var label := "%s hop %d %s -> %s" % [route_id, hop + 1, stops[hop], stops[hop + 1]]
			_stick(0.0, 0.0)
			await _frames(4)
			var snap := Vector2(player.global_position.x - hop_start.x, player.global_position.z - hop_start.z).length()
			if not _expect(snap <= 1.0, "%s: trainer is %.3fm from the hop start (no position write allowed)" % [label, snap]):
				return
			if not _expect(player.is_on_floor() and not swimming.is_swimming(), "%s: hop start is not dry" % label):
				return
			var arrive_pct := float(vitals.stamina) / float(vitals.max_stamina) * 100.0
			var rest_frames := 0
			if rest:
				# Natural idle rest on the dry shoal: no input, no stamina write.
				while float(vitals.stamina) < float(vitals.max_stamina) and rest_frames < 1800:
					await physics_frame
					rest_frames += 1
			var start_pct := float(vitals.stamina) / float(vitals.max_stamina) * 100.0
			var skills: RefCounted = game.local.skills
			skills.load_data({"revealed": skills.revealed})
			if not _expect(is_equal_approx(float(vitals.max_stamina), 100.0) and skills.level("swimming") == 0
				and is_equal_approx(float(skills.efficiency("swimming")), 1.0),
				"%s: requires level-0 swimming and 100 max stamina" % label):
				return
			if not _original_five_unmounted(label):
				return
			var health_before: float = vitals.health
			observed_swim_distance = 0.0
			hop_minimum_stamina = float(vitals.stamina)
			pinned_minimum_efficiency = 1.0
			var hop_length := _polyline_length(hop_start, hop_path.slice(1))
			var straight := Vector2(finish.x - hop_start.x, finish.z - hop_start.z).length()
			var commanded := _path_zigzag(hop_path, STEER_RATIO)
			var ratio := _polyline_length(hop_start, commanded) / hop_length
			if not _expect(ratio >= 1.14 and ratio <= 1.17, "%s: steering ratio %.3f not ~15 percent" % [label, ratio]):
				return
			var hop_msec := Time.get_ticks_msec()
			for target: Vector3 in commanded:
				if not await _move_to(target, 0.8, 1200, true):
					return
			await _frames(20)
			var fraction := hop_minimum_stamina / float(vitals.max_stamina)
			route_worst = minf(route_worst, fraction)
			worst = minf(worst, fraction)
			hop_count += 1
			var ok: bool = fraction >= 0.20 and player.is_on_floor() and not swimming.is_swimming() \
				and is_equal_approx(float(vitals.health), health_before)
			print("WALKED HOP id=%s hop=%d from=%s to=%s path_m=%.3f straight_m=%.3f steer_ratio_vs_path=%.3f steer_ratio_vs_straight=%.3f actual_swim_m=%.3f arrive_pct=%.2f rest_frames=%d start_pct=%.2f min_stamina_pct=%.2f end_pct=%.2f pinned_min_efficiency=%.4f start_snap_m=%.3f elapsed_s=%.2f result=%s" % [
				route_id, hop + 1, stops[hop], stops[hop + 1], hop_length, straight, ratio,
				_polyline_length(hop_start, commanded) / straight, observed_swim_distance, arrive_pct, rest_frames,
				start_pct, fraction * 100.0, float(vitals.stamina), pinned_minimum_efficiency, snap,
				float(Time.get_ticks_msec() - hop_msec) / 1000.0, "PASS" if ok else "FAIL"])
			per_hop.append("%.2f" % (fraction * 100.0))
			if not _expect(observed_swim_distance > 1.0, "%s: never entered swimming" % label):
				return
			if not _expect(player.is_on_floor() and not swimming.is_swimming(), "%s: end is not dry land" % label):
				return
			if not _expect(fraction >= 0.20, "%s: below 20 percent stamina: %.3f" % [label, hop_minimum_stamina]):
				return
			if not _expect(is_equal_approx(float(vitals.health), health_before), "%s: health changed" % label):
				return
			if not _expect(is_equal_approx(pinned_minimum_efficiency, 1.0), "%s: efficiency left level 0" % label):
				return
			if not _expect(Vector2(swimming.state.safe_landing.x - finish.x, swimming.state.safe_landing.z - finish.z).length() < 0.1,
				"%s: did not earn the hop end's authored safe landing" % label):
				return
			if not _original_five_unmounted(label + " (arrival)"):
				return
		summary.append("%s worst=%.2f hops=[%s]" % [route_id, route_worst * 100.0, " / ".join(per_hop)])
	tracking = false
	if not _expect(max_gain_per_frame <= configured_regen / float(Engine.physics_ticks_per_second) + 0.02,
		"stamina gained too much in one physics frame: %.4f" % max_gain_per_frame):
		return
	if not _expect(position_writes == 1, "position writes %d != 1" % position_writes):
		return
	for line: String in summary:
		print("ROUTE " + line)
	finished = true
	print("WATER HOP WALKED OK variant=%s routes=%d..%d hops=%d assertions=%d worst_min_stamina_pct=%.2f position_writes=%d island_walk_m=%.1f rest=%s party=%s max_gain_per_frame=%.4f elapsed_s=%.1f final_health=%.1f" % [
		variant, first, last, hop_count, assertions, worst * 100.0, position_writes, walk_total, rest,
		_party_label(), max_gain_per_frame, float(Time.get_ticks_msec() - started) / 1000.0, vitals.health])
	quit(0)


## Walks the current island to `target` with the stick navigator along the
## baked-ground A* plan. Returns {metres, legs, spur_m, resets} or null.
func _walk_island(target: Vector3, label: String) -> Variant:
	var here := player.global_position
	var plan: Dictionary = PLANNER.plan_route(world, Vector2(here.x, here.z), Vector2(target.x, target.z))
	var points: Array[Vector2] = plan.points
	if not _expect(points.size() >= 1, "%s: no dry baked route from %s to %s" % [label, here, target]):
		return null
	_last_stamina = -1.0
	var metres := 0.0
	var resets := 0
	var last := player.global_position
	for index in points.size():
		var point: Vector2 = points[index]
		var final := index == points.size() - 1
		var budget := maxi(900, int(Vector2(player.global_position.x, player.global_position.z).distance_to(point) * 90.0))
		var arrived: bool = await navigator.walk_to(Vector3(point.x, 0.0, point.y), budget, 0.6 if final else 1.8)
		resets += int(navigator.confined_resets())
		metres += Vector2(last.x, last.z).distance_to(Vector2(player.global_position.x, player.global_position.z))
		last = player.global_position
		if not arrived:
			_stick(0.0, 0.0)
			_expect(false, "%s: walk stalled at leg %d/%d player=%s goal=%s swimming=%s" % [
				label, index + 1, points.size(), player.global_position, point, swimming.is_swimming()])
			return null
	_stick(0.0, 0.0)
	await _frames(20)
	if not _expect(player.is_on_floor() and not swimming.is_swimming(), "%s: did not end dry" % label):
		return null
	return {"metres": metres, "legs": points.size(), "spur_m": float(plan.spur_m), "resets": resets}


var _last_stamina := -1.0


func _track_frame_gain() -> void:
	var now := float(player.get("vitals").stamina)
	if _last_stamina >= 0.0:
		max_gain_per_frame = maxf(max_gain_per_frame, now - _last_stamina)
	_last_stamina = now


func _move_to(target: Vector3, tolerance: float, frame_limit: int, pin: bool) -> bool:
	var previous := player.global_position
	_last_stamina = float(player.get("vitals").stamina)
	for _frame in frame_limit:
		var offset := target - player.global_position
		offset.y = 0.0
		if offset.length() <= tolerance:
			_action(false)
			await _frames(2)
			return true
		camera.set("yaw", atan2(-offset.x, -offset.z))
		_action(true)
		await physics_frame
		if swimming.is_swimming():
			var moved := player.global_position - previous
			moved.y = 0.0
			observed_swim_distance += moved.length()
			hop_minimum_stamina = minf(hop_minimum_stamina, float(player.get("vitals").stamina))
		_track_frame_gain()
		previous = player.global_position
		if pin:
			var skills: RefCounted = game.local.skills
			pinned_minimum_efficiency = minf(pinned_minimum_efficiency, float(skills.efficiency("swimming")))
			if skills.level("swimming") != 0 or float(skills.fraction("swimming")) > 0.0:
				skills.load_data({"revealed": skills.revealed})
		if float(player.get("vitals").health) <= 0.0:
			return _fail("died moving toward %s from %s" % [target, player.global_position])
	return _fail("movement timed out target=%s actual=%s aquatic=%s" % [target, player.global_position, swimming.snapshot()])


func _grant_original_five() -> Array[String]:
	var granted: Array[String] = []
	if not _expect(PARTY_SEAM.has_game_state() and int(game.party.call("size")) == 0,
		"original-five fixture must start from the fresh game's empty Game.party"):
		return []
	var skills: RefCounted = game.local.skills
	for skill: String in PLAYER_SKILLS:
		if not _expect(skills.level(skill) == 0, "requires a level-0 human; %s is %d" % [skill, skills.level(skill)]):
			return []
	var cfg: Dictionary = PROGRESSION.config()
	for entry: Dictionary in ORIGINAL_FIVE:
		var species := str(entry.species)
		if not _expect(SPECIES.has(species) and not species.begins_with("water_"), "%s is not a pre-Tidewake species" % species):
			return []
		var creature: RefCounted = SPECIES.spawn(species)
		creature.call("set_level", int(entry.level), cfg)
		if not _expect(bool(PARTY_SEAM.add(creature)), "PartySeam.add refused %s" % species):
			return []
		granted.append(species)
	if not _expect(int(game.party.call("size")) == 5 and bool(game.party.call("is_full")), "party is not exactly five"):
		return []
	for member: RefCounted in game.party.call("members"):
		if not _expect(not _is_swim_mount(str(member.species_id)), "%s is a compatible swim mount" % member.species_id):
			return []
	print("FIXTURE original_five party=%s" % _party_label())
	return granted


func _is_swim_mount(species_id: String) -> bool:
	return bool((SPECIES.definition(species_id).get("swim_mount", {}) as Dictionary).get("compatible", false))


func _original_five_unmounted(label: String) -> bool:
	var now: Array[String] = []
	for member: RefCounted in game.party.call("members"):
		now.append(str(member.species_id))
		if not _expect(not _is_swim_mount(str(member.species_id)), "%s: %s is a swim mount" % [label, member.species_id]):
			return false
	if not _expect(now == party_species, "%s: party is no longer the original five: %s" % [label, now]):
		return false
	var riding := world.get_node("RidingController")
	if not _expect(not bool(riding.call("is_mounted")) and riding.call("mount_body") == null, "%s: player is mounted" % label):
		return false
	var director := world.get_node_or_null("EncounterDirector")
	var ally: Variant = director.call("ally_body") if director != null else null
	if ally != null and is_instance_valid(ally) and not _expect(not _is_swim_mount(str(ally.get("species_id"))),
		"%s: deployed ally is a swim mount" % label):
		return false
	var body: Variant = world.get_node("MountedSwimming").get("body")
	return _expect(body == null or not is_instance_valid(body), "%s: MountedSwimming has an active body" % label)


func _party_label() -> String:
	var parts: Array[String] = []
	for member: RefCounted in game.party.call("members"):
		parts.append("%s:L%d" % [member.species_id, member.level])
	return "[" + ",".join(parts) + "]"


## Same construction as smoke_water_swimming.gd `_path_zigzag`: seven
## alternating lateral offsets at equal arc-length stations, amplitude solved so
## the commanded length is `ratio` x the authored hop polyline.
func _path_zigzag(path: Array[Vector3], ratio: float) -> Array[Vector3]:
	var low := 0.0
	var high := 0.2
	var points: Array[Vector3] = []
	var length := _polyline_length(path[0], path.slice(1))
	for _iteration in 40:
		var factor := (low + high) * 0.5
		points = _zigzag_points(path, length, factor * length)
		if _polyline_length(path[0], points) / length < ratio:
			low = factor
		else:
			high = factor
	return points


func _zigzag_points(path: Array[Vector3], length: float, amplitude: float) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for index in range(1, 8):
		var station := length * float(index) / 8.0
		var segment := 0
		while segment < path.size() - 2:
			var span := Vector2(path[segment + 1].x - path[segment].x, path[segment + 1].z - path[segment].z).length()
			if station <= span:
				break
			station -= span
			segment += 1
		var a := Vector2(path[segment].x, path[segment].z)
		var b := Vector2(path[segment + 1].x, path[segment + 1].z)
		var direction := (b - a).normalized()
		var centre := a + direction * station
		var offset := Vector2(-direction.y, direction.x) * amplitude * (1.0 if index % 2 == 1 else -1.0)
		points.append(Vector3(centre.x + offset.x, 0.0, centre.y + offset.y))
	points.append(path[-1])
	return points


func _polyline_length(start: Vector3, points: Array[Vector3]) -> float:
	var length := 0.0
	var previous := Vector2(start.x, start.z)
	for point: Vector3 in points:
		var next := Vector2(point.x, point.z)
		length += previous.distance_to(next)
		previous = next
	return length


func _action(pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = "move_forward"
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


func _stick(x: float, y: float) -> void:
	for axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
		var event := InputEventJoypadMotion.new()
		event.axis = axis
		event.axis_value = x if axis == JOY_AXIS_LEFT_X else y
		Input.parse_input_event(event)


func _anchor(id: String) -> Vector3:
	for anchor: Dictionary in config.anchors:
		if str(anchor.id) == id:
			return _vector(anchor.safe_position)
	return Vector3.INF


func _route(id: String) -> Dictionary:
	for raw: Variant in config.get("water_routes", []):
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == id:
			return raw as Dictionary
	return {}


func _arg(prefix: String, fallback: String) -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix).strip_edges()
	return fallback


func _vector(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))


func _frames(count: int) -> void:
	for _frame in count:
		await physics_frame


func _expect(condition: bool, message: String) -> bool:
	assertions += 1
	return true if condition else _fail(message)


func _fail(message: String) -> bool:
	_action(false)
	_stick(0.0, 0.0)
	finished = true
	push_error("WATER HOP WALKED: " + message)
	print("FAIL: " + message)
	quit(1)
	return false
