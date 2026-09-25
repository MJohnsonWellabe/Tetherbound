extends SceneTree

## Production Water scene/body/input smoke. The initial fixture starts on the
## lesson's west safe landing; all subsequent movement uses real action input.
## Zero stamina is an explicit exhaustion fixture. Combat pause exercises the
## production locomotion handoff, not a complete encounter or victory path.
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const SAVE := preload("res://scripts/save/save_game.gd")
const MOVEMENT_CONFIG := "res://data/config/movement.json"
const PARTY_SEAM := preload("res://scripts/story/party_seam.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const PLAYER_SKILLS := ["running", "catching", "riding", "swimming", "flying"]
## `--original-five` fixture for ACCEPTANCE F12 ("with the original five and no
## owned swimmer"). The docs never name species, so the five are the typical
## retained party the project's own data already declares:
## data/config/chapter_curve.json `difficulty.party` -- the Ground starter
## (opening.json) plus the four most-fielded Meadows Band 1 species. Levels are
## PROGRESSION.md's Tidewake arrival: lead L44 (Stormwood exit, Tidewake "L43
## overlap"), the other four within three levels of it. None is a Water-roster
## species and none declares a compatible `swim_mount`, which is asserted.
const ORIGINAL_FIVE := [
	{"species": "terrapup", "level": 44},
	{"species": "bramblebun", "level": 43},
	{"species": "mudsnout", "level": 42},
	{"species": "pipwing", "level": 42},
	{"species": "trailpup", "level": 41},
]

var world: Node3D
var player: CharacterBody3D
var camera: Node3D
var swimming: Node
var assertions := 0
var finished := false
var observed_swim_distance := 0.0
var lesson_distance := 0.0
var route_minimum_stamina := INF
var route_max_stamina_gain_per_frame := 0.0
## Every-hop mode only: swimming XP is cleared after each movement frame so the
## drain stays at level-0 efficiency for the whole hop (a conservative fixture;
## earned levels only reduce drain). The minimum efficiency seen is asserted.
var pin_swim_level_zero := false
var pinned_minimum_efficiency := 1.0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var watchdog := 1200.0 if _every_hop_argument() else 180.0
	create_timer(watchdog).timeout.connect(func() -> void:
		if not finished:
			_fail("%d second watchdog expired" % int(watchdog)))
	var game: Node = root.get_node("Game")
	game.reset_for_new_game()
	game.save_system = SAVE.new("user://smoke_water_swimming_fixture")
	# Explicit realm fixture: this does not prove key spending or gate traversal.
	game.current_realm = "water"
	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 600:
		await physics_frame
		if bool(world.call("shell_build_complete")):
			break
	if not _expect(bool(world.call("shell_build_complete")), "Water shell failed to build"):
		return
	player = world.get_node("Player")
	camera = world.get_node("CameraRig")
	swimming = player.get("swim_controller")
	if not _expect(swimming != null, "production player has no SwimController"):
		return
	var config: Dictionary = world.get("config")
	var rest_route_id := _rest_route_argument()
	if not rest_route_id.is_empty() and _every_hop_argument():
		await _run_every_hop(game, config, rest_route_id)
		return
	if not rest_route_id.is_empty():
		await _run_rest_route(game, config, rest_route_id)
		return
	var lesson: Dictionary = config.swim_lesson
	var west := _anchor(config, str(lesson.start_anchor))
	var east := _anchor(config, str(lesson.end_anchor))
	if not _expect(west.is_finite() and east.is_finite(), "lesson safe anchors missing"):
		return
	# The only position write: set the test-owned starting fixture on real terrain.
	west.y = float(world.call("ground_height_at", west.x, west.z)) + 0.15
	if not _expect(is_finite(west.y), "west landing has no baked Terrain3D height"):
		return
	player.global_position = west
	player.velocity = Vector3.ZERO
	await _frames(45)
	if not _expect(player.is_on_floor() and not swimming.is_swimming(), "initial safe landing did not settle dry"):
		return
	if not _expect(swimming.state.has_safe_landing and Vector2(swimming.state.safe_landing.x - west.x, swimming.state.safe_landing.z - west.z).length() < 0.1, "dry west anchor was not earned for recovery"):
		return
	var vitals: RefCounted = player.get("vitals")
	var first := _vector(lesson.surface_polyline[0])
	var last := _vector(lesson.surface_polyline[-1])
	if not await _move_to(first, 0.4, 900):
		return
	if not _expect(swimming.is_swimming(), "walking off lesson beach did not enter swimming"):
		return
	var crossing_health: float = vitals.health
	var crossing_stamina: float = vitals.stamina
	observed_swim_distance = 0.0
	if not await _move_to(last, 0.4, 1500):
		return
	lesson_distance = observed_swim_distance
	if not _expect(observed_swim_distance >= 58.0, "actual lesson swim shorter than 58m: %.3f" % observed_swim_distance):
		return
	if not _expect(float(vitals.stamina) < crossing_stamina, "60m swimming did not spend real player stamina"):
		return
	if not _expect(float(vitals.stamina) / float(vitals.max_stamina) >= 0.15, "level-zero lesson left under 15 percent stamina"):
		return
	if not _expect(is_equal_approx(float(vitals.health), crossing_health), "normal lesson crossing damaged health"):
		return
	# Exhaustion fixture changes resources, never the controller or movement state.
	vitals.stamina = 0.0
	var health_before_drowning: float = vitals.health
	await _frames(60)
	if not _expect(float(vitals.health) < health_before_drowning and float(vitals.health) > 0.0,
		"zero stamina failed gradual drowning: before=%s after=%s" % [health_before_drowning, vitals.health]):
		return
	if not _expect(bool(swimming.snapshot().drowning), "drowning feedback state was not set"):
		return
	# Real slot I/O during exhaustion must not refill either resource. This is
	# a same-scene load; a separate transport test owns reconnect evidence.
	player.call("set_locomotion_enabled", false)
	await _frames(2)
	var saved_health: float = vitals.health
	if not _expect(game.save_game(1), "midwater exhausted save failed"):
		return
	vitals.stamina = vitals.max_stamina
	vitals.health = vitals.max_health
	if not _expect(game.load_game(1), "midwater exhausted load failed"):
		return
	if not _expect(is_zero_approx(float(vitals.stamina)) and is_equal_approx(float(vitals.health), saved_health), "loading restored free swimming stamina or health"):
		return
	player.call("set_locomotion_enabled", false)
	await _frames(2)
	var paused_health: float = vitals.health
	var paused_stamina: float = vitals.stamina
	await _frames(120)
	if not _expect(int(swimming.snapshot().mode) == 3, "combat locomotion handoff did not pause swimming"):
		return
	if not _expect(is_equal_approx(float(vitals.health), paused_health) and is_equal_approx(float(vitals.stamina), paused_stamina),
		"combat pause changed health or stamina"):
		return
	player.call("set_locomotion_enabled", true)
	if not await _move_to(east, 0.8, 900):
		return
	await _frames(10)
	if not _expect(not swimming.is_swimming() and not bool(swimming.snapshot().drowning), "reaching dry landing did not stop drowning"):
		return
	var landed_health: float = vitals.health
	await _frames(120)
	if not _expect(is_equal_approx(float(vitals.health), landed_health), "health continued draining on safe land"):
		return
	if not _expect(game.world.flags.has("water_swim_lesson_complete"), "physical lesson failed to commit its world objective"):
		return
	if not _expect(Vector2(swimming.state.safe_landing.x - east.x, swimming.state.safe_landing.z - east.z).length() < 0.1, "walking out of shallow water failed to earn the east recovery anchor"):
		return
	finished = true
	print("WATER SWIMMING OK assertions=%d actual_lesson_swim_m=%.3f final_health=%.3f" % [assertions, lesson_distance, vitals.health])
	quit(0)


func _run_rest_route(game: Node, config: Dictionary, route_id: String) -> void:
	var route := _route(config, route_id)
	if not _expect(not route.is_empty(), "rest-route %s is not authored" % route_id):
		return
	var rest_ids: Array = route.get("rest_anchor_ids", [])
	if not _expect(not rest_ids.is_empty(), "rest-route %s has no rest anchors" % route_id):
		return
	var final_rest := _anchor(config, str(rest_ids[-1]))
	var destination := _anchor(config, str(route.get("to_anchor", "")))
	if not _expect(final_rest.is_finite() and destination.is_finite(),
		"rest-route %s has an unresolved final rest or destination anchor" % route_id):
		return
	var vitals: RefCounted = player.get("vitals")
	if not _expect(is_equal_approx(float(vitals.max_stamina), 100.0) and
		is_equal_approx(float(vitals.stamina), 100.0),
		"rest-route fixture requires normal level-zero 100 stamina"):
		return
	var riding := world.get_node_or_null("RidingController")
	if not _expect(riding == null or not bool(riding.call("is_mounted")),
		"rest-route fixture must not begin mounted"):
		return
	if not _expect(not bool(route.get("requires_compatible_active_swim_mount", true)) and
		(route.get("required_equipment", []) as Array).is_empty(),
		"rest-route must be the authored human crossing, not a saddle route"):
		return
	# This opens only the shared departure current for the isolated hop; it is a
	# fixture, not evidence that the Sluice story objective was earned.
	var departure_flag := str(route.get("required_departure_flag", ""))
	if not departure_flag.is_empty():
		game.world.flags.call("set_flag", departure_flag, true)
	if not _expect(departure_flag.is_empty() or game.world.flags.has(departure_flag),
		"rest-route fixture did not open the authored departure current"):
		return
	# The sole position write is the final dry shoal, so this smoke proves one
	# actual human hop to Veilfall without walking the whole chapter.
	final_rest.y = float(world.call("ground_height_at", final_rest.x, final_rest.z)) + 0.15
	if not _expect(is_finite(final_rest.y), "rest-route final shoal has no baked height"):
		return
	player.global_position = final_rest
	player.velocity = Vector3.ZERO
	await _frames(45)
	if not _expect(player.is_on_floor() and not swimming.is_swimming(),
		"rest-route final shoal did not settle dry"):
		return
	var health_before: float = vitals.health
	observed_swim_distance = 0.0
	route_minimum_stamina = float(vitals.stamina)
	route_max_stamina_gain_per_frame = 0.0
	var started_msec := Time.get_ticks_msec()
	var commanded := _final_hop_zigzag(final_rest, destination)
	var direct_distance := Vector2(destination.x - final_rest.x, destination.z - final_rest.z).length()
	var commanded_distance := _horizontal_polyline_length(final_rest, commanded)
	var commanded_ratio := commanded_distance / direct_distance if direct_distance > 0.0 else 0.0
	if not _expect(commanded_ratio >= 1.14 and commanded_ratio <= 1.17,
		"rest-route command zigzag is not the intended ~15 percent steering deviation: %.3f" % commanded_ratio):
		return
	for target: Vector3 in commanded:
		if not await _move_to(target, 0.8, 900):
			return
	await _frames(20)
	if not _expect(player.is_on_floor() and not swimming.is_swimming(),
		"rest-route destination did not become dry land"):
		return
	if not _expect(route_minimum_stamina / float(vitals.max_stamina) >= 0.20,
		"rest-route consumed below the 20 percent stamina reserve before dry-land regen: %.3f" % route_minimum_stamina):
		return
	if not _expect(is_equal_approx(float(vitals.health), health_before),
		"rest-route changed health: before=%.3f after=%.3f" % [health_before, vitals.health]):
		return
	if not _expect(Vector2(swimming.state.safe_landing.x - destination.x,
		swimming.state.safe_landing.z - destination.z).length() < 0.1,
		"rest-route did not earn its authored Veilfall arrival safe landing"):
		return
	var stamina_before_regen: float = vitals.stamina
	await _frames(60)
	var stamina_after_regen: float = vitals.stamina
	var movement: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MOVEMENT_CONFIG))
	var configured_regen := float((movement.get("stamina", {}) as Dictionary).get("regen_per_second", 0.0))
	var elapsed := 60.0 / float(Engine.physics_ticks_per_second)
	if not _expect(stamina_after_regen >= stamina_before_regen and
		stamina_after_regen <= minf(float(vitals.max_stamina), stamina_before_regen + configured_regen * elapsed + 0.25),
		"rest-route dry-land regen was not continuous and bounded: %.3f -> %.3f" % [stamina_before_regen, stamina_after_regen]):
		return
	if not _expect(route_max_stamina_gain_per_frame <= configured_regen / float(Engine.physics_ticks_per_second) + 0.02,
		"rest-route stamina gained too much in one physics frame: %.4f" % route_max_stamina_gain_per_frame):
		return
	finished = true
	print("WATER REST ROUTE OK id=%s assertions=%d actual_swim_m=%.3f elapsed_s=%.3f minimum_stamina_before_regen=%.3f max_stamina_gain_per_frame=%.4f final_health=%.3f commanded_steering_ratio=%.3f" % [
		route_id, assertions, observed_swim_distance, float(Time.get_ticks_msec() - started_msec) / 1000.0,
		route_minimum_stamina, route_max_stamina_gain_per_frame, vitals.health, commanded_ratio])
	quit(0)


## Every-hop mode (`--rest-route=<id> --every-hop`). The hop list is the
## route's departure, each authored rest shoal in order, then the arrival. Each
## hop starts with one disclosed position write onto that hop's dry start,
## waits for full dry-land stamina regeneration (a player may rest on a shoal),
## then swims a ~15 percent commanded zigzag along the authored route polyline
## to the next dry stop with real movement input and level-0 swim efficiency.
func _run_every_hop(game: Node, config: Dictionary, route_id: String) -> void:
	var route := _route(config, route_id)
	if not _expect(not route.is_empty(), "every-hop %s is not authored" % route_id):
		return
	if not _expect(not bool(route.get("requires_compatible_active_swim_mount", true)) and
		(route.get("required_equipment", []) as Array).is_empty(),
		"every-hop route must be the authored human crossing, not a saddle route"):
		return
	var stops: Array[String] = [str(route.get("from_anchor", ""))]
	for rest_id: Variant in route.get("rest_anchor_ids", []):
		stops.append(str(rest_id))
	stops.append(str(route.get("to_anchor", "")))
	var path: Array[Vector3] = [_anchor(config, stops[0])]
	for raw: Variant in route.get("polyline", []):
		path.append(_vector(raw as Array))
	path.append(_anchor(config, stops[-1]))
	var boundaries: Array[int] = [0]
	for index in range(1, stops.size() - 1):
		var rest := _anchor(config, stops[index])
		var found := -1
		for vertex in range(boundaries[-1] + 1, path.size() - 1):
			if Vector2(path[vertex].x - rest.x, path[vertex].z - rest.z).length() < 0.5:
				found = vertex
				break
		if not _expect(rest.is_finite() and found > 0,
			"every-hop rest %s is not an ordered vertex of the authored polyline" % stops[index]):
			return
		boundaries.append(found)
	boundaries.append(path.size() - 1)
	for point: Vector3 in path:
		if not _expect(point.is_finite(), "every-hop %s has an unresolved anchor" % route_id):
			return
	var vitals: RefCounted = player.get("vitals")
	var original_five := _original_five_argument()
	var party_species: Array[String] = []
	if original_five:
		party_species = _grant_original_five(game)
		if party_species.is_empty():
			return
	var party: RefCounted = game.party
	var party_size := int(party.call("size")) if party != null else 0
	var riding := world.get_node_or_null("RidingController")
	if original_five and not _expect(riding != null and world.get_node_or_null("MountedSwimming") != null,
		"original-five fixture needs the production RidingController and MountedSwimming nodes"):
		return
	var departure_flag := str(route.get("required_departure_flag", ""))
	if not departure_flag.is_empty():
		game.world.flags.call("set_flag", departure_flag, true)
	if not _expect(departure_flag.is_empty() or game.world.flags.has(departure_flag),
		"every-hop fixture did not open the authored departure current"):
		return
	var movement: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MOVEMENT_CONFIG))
	var configured_regen := float((movement.get("stamina", {}) as Dictionary).get("regen_per_second", 0.0))
	var started_msec := Time.get_ticks_msec()
	var worst_fraction := INF
	route_max_stamina_gain_per_frame = 0.0
	for hop in boundaries.size() - 1:
		var hop_path: Array[Vector3] = []
		for vertex in range(boundaries[hop], boundaries[hop + 1] + 1):
			hop_path.append(path[vertex])
		var start := hop_path[0]
		var finish := hop_path[-1]
		var label := "%s hop %d %s -> %s" % [route_id, hop + 1, stops[hop], stops[hop + 1]]
		var snap_m := 0.0 if hop == 0 else Vector2(player.global_position.x - start.x,
			player.global_position.z - start.z).length()
		if hop > 0 and not _expect(snap_m <= 1.0,
			"%s: actual arrival was %.3fm from the next hop start" % [label, snap_m]):
			return
		# The sole position write for this hop: the dry start anchor on baked terrain.
		start.y = float(world.call("ground_height_at", start.x, start.z)) + 0.15
		if not _expect(is_finite(start.y), "%s: start has no baked height" % label):
			return
		player.global_position = start
		player.velocity = Vector3.ZERO
		await _frames(45)
		if not _expect(player.is_on_floor() and not swimming.is_swimming(),
			"%s: hop start did not settle dry" % label):
			return
		var regen_frames := 0
		while float(vitals.stamina) < float(vitals.max_stamina) and regen_frames < 900:
			await physics_frame
			regen_frames += 1
		if not _expect(is_equal_approx(float(vitals.stamina), float(vitals.max_stamina)),
			"%s: dry-land stamina did not refill within 900 frames: %.3f" % [label, vitals.stamina]):
			return
		var skills: RefCounted = game.local.skills
		skills.load_data({"revealed": skills.revealed})
		if not _expect(is_equal_approx(float(vitals.max_stamina), 100.0) and
			skills.level("swimming") == 0 and is_equal_approx(float(skills.efficiency("swimming")), 1.0),
			"%s: fixture requires level-zero swimming and 100 max stamina" % label):
			return
		if not _expect(riding == null or not bool(riding.call("is_mounted")),
			"%s: fixture must not be mounted" % label):
			return
		if original_five and not _original_five_still_unmounted(game, party_species, label):
			return
		var health_before: float = vitals.health
		observed_swim_distance = 0.0
		route_minimum_stamina = float(vitals.stamina)
		pinned_minimum_efficiency = 1.0
		var hop_length := _horizontal_polyline_length(start, hop_path.slice(1))
		var straight := Vector2(finish.x - start.x, finish.z - start.z).length()
		var commanded := _path_zigzag(hop_path, 1.155)
		var commanded_ratio := _horizontal_polyline_length(start, commanded) / hop_length
		if not _expect(commanded_ratio >= 1.14 and commanded_ratio <= 1.17,
			"%s: command zigzag is not ~15 percent steering deviation: %.3f" % [label, commanded_ratio]):
			return
		var hop_msec := Time.get_ticks_msec()
		pin_swim_level_zero = true
		for target: Vector3 in commanded:
			if not await _move_to(target, 0.8, 900):
				return
		pin_swim_level_zero = false
		await _frames(20)
		var fraction := route_minimum_stamina / float(vitals.max_stamina)
		worst_fraction = minf(worst_fraction, fraction)
		print("EVERY HOP id=%s hop=%d from=%s to=%s path_m=%.3f straight_m=%.3f commanded_ratio_vs_path=%.3f commanded_ratio_vs_straight=%.3f actual_swim_m=%.3f min_stamina_pct=%.2f pinned_min_efficiency=%.4f regen_frames=%d start_snap_m=%.3f elapsed_s=%.3f result=%s" % [
			route_id, hop + 1, stops[hop], stops[hop + 1], hop_length, straight, commanded_ratio,
			_horizontal_polyline_length(start, commanded) / straight, observed_swim_distance,
			fraction * 100.0, pinned_minimum_efficiency, regen_frames, snap_m,
			float(Time.get_ticks_msec() - hop_msec) / 1000.0,
			"PASS" if fraction >= 0.20 and player.is_on_floor() and not swimming.is_swimming() and
				is_equal_approx(float(vitals.health), health_before) else "FAIL"])
		if not _expect(observed_swim_distance > 1.0, "%s: hop never entered swimming" % label):
			return
		if not _expect(player.is_on_floor() and not swimming.is_swimming(),
			"%s: hop end did not become dry land" % label):
			return
		if not _expect(fraction >= 0.20,
			"%s: consumed below the 20 percent stamina reserve: %.3f" % [label, route_minimum_stamina]):
			return
		if not _expect(is_equal_approx(float(vitals.health), health_before),
			"%s: changed health: before=%.3f after=%.3f" % [label, health_before, vitals.health]):
			return
		if not _expect(is_equal_approx(pinned_minimum_efficiency, 1.0),
			"%s: swim efficiency left level zero: %.4f" % [label, pinned_minimum_efficiency]):
			return
		if not _expect(Vector2(swimming.state.safe_landing.x - finish.x,
			swimming.state.safe_landing.z - finish.z).length() < 0.1,
			"%s: did not earn the hop end's authored safe landing" % label):
			return
		if original_five and not _original_five_still_unmounted(game, party_species, label + " (arrival)"):
			return
	var stamina_before_regen: float = vitals.stamina
	await _frames(60)
	var stamina_after_regen: float = vitals.stamina
	var elapsed := 60.0 / float(Engine.physics_ticks_per_second)
	if not _expect(stamina_after_regen >= stamina_before_regen and
		stamina_after_regen <= minf(float(vitals.max_stamina), stamina_before_regen + configured_regen * elapsed + 0.25),
		"every-hop final dry-land regen was not continuous and bounded: %.3f -> %.3f" % [stamina_before_regen, stamina_after_regen]):
		return
	if not _expect(route_max_stamina_gain_per_frame <= configured_regen / float(Engine.physics_ticks_per_second) + 0.02,
		"every-hop stamina gained too much in one physics frame: %.4f" % route_max_stamina_gain_per_frame):
		return
	finished = true
	print("WATER EVERY HOP OK id=%s hops=%d assertions=%d worst_min_stamina_pct=%.2f party_size=%d party=%s elapsed_s=%.3f final_health=%.3f" % [
		route_id, boundaries.size() - 1, assertions, worst_fraction * 100.0, party_size,
		_party_label(game), float(Time.get_ticks_msec() - started_msec) / 1000.0, vitals.health])
	quit(0)


## Builds ORIGINAL_FIVE through the production party door (PartySeam.add into
## Game.party, each creature made the way adopt_starter/party_grant make one:
## SPECIES.spawn then set_level). Returns the species in party order, or an
## empty array after a failed assertion.
func _grant_original_five(game: Node) -> Array[String]:
	var granted: Array[String] = []
	if not _expect(PARTY_SEAM.has_game_state() and int(game.party.call("size")) == 0,
		"original-five fixture must start from the fresh game's empty real Game.party"):
		return []
	var skills: RefCounted = game.local.skills
	for skill: String in PLAYER_SKILLS:
		if not _expect(skills.level(skill) == 0,
			"original-five fixture requires a level-0 human; %s is level %d" % [skill, skills.level(skill)]):
			return []
	var cfg: Dictionary = PROGRESSION.config()
	for entry: Dictionary in ORIGINAL_FIVE:
		var species := str(entry.species)
		if not _expect(SPECIES.has(species) and not species.begins_with("water_"),
			"original-five species %s is not an installed pre-Tidewake species" % species):
			return []
		var creature: RefCounted = SPECIES.spawn(species)
		creature.call("set_level", int(entry.level), cfg)
		if not _expect(bool(PARTY_SEAM.add(creature)),
			"PartySeam.add refused original-five member %s" % species):
			return []
		granted.append(species)
	var members: Array = game.party.call("members")
	if not _expect(int(game.party.call("size")) == 5 and members.size() == 5 and bool(game.party.call("is_full")),
		"original-five party size is %d, not 5" % int(game.party.call("size"))):
		return []
	for index in members.size():
		var member: RefCounted = members[index]
		var entry: Dictionary = ORIGINAL_FIVE[index]
		if not _expect(str(member.species_id) == str(entry.species) and int(member.level) == int(entry.level),
			"original-five member %d is %s L%d, expected %s L%d" % [index, member.species_id, member.level, entry.species, entry.level]):
			return []
		if not _expect(not _is_compatible_swim_mount(str(member.species_id)),
			"original-five member %s is a compatible swim mount; F12 requires no owned swimmer" % member.species_id):
			return []
	print("ORIGINAL FIVE party=%s" % _party_label(game))
	return granted


## The game's own compatibility check (water_mounted_swim.gd): the species
## definition's `swim_mount.compatible`, from the merged species table that
## water_roster.json registers into.
func _is_compatible_swim_mount(species_id: String) -> bool:
	return bool((SPECIES.definition(species_id).get("swim_mount", {}) as Dictionary).get("compatible", false))


## Per-hop: still exactly the same five, none a compatible swim mount, the
## player not mounted, and MountedSwimming holding no active swim-mount body.
func _original_five_still_unmounted(game: Node, species: Array[String], label: String) -> bool:
	var members: Array = game.party.call("members")
	var now: Array[String] = []
	for member: RefCounted in members:
		now.append(str(member.species_id))
		if not _expect(not _is_compatible_swim_mount(str(member.species_id)),
			"%s: owned %s is a compatible swim mount" % [label, member.species_id]):
			return false
	if not _expect(now == species, "%s: party is no longer the original five: %s" % [label, now]):
		return false
	var riding := world.get_node("RidingController")
	if not _expect(not bool(riding.call("is_mounted")) and riding.call("mount_body") == null,
		"%s: player is mounted" % label):
		return false
	var director := world.get_node_or_null("EncounterDirector")
	var ally: Variant = director.call("ally_body") if director != null else null
	if ally != null and is_instance_valid(ally) and not _expect(not _is_compatible_swim_mount(str(ally.get("species_id"))),
		"%s: deployed ally %s is a compatible swim mount" % [label, ally.get("species_id")]):
		return false
	var mounted_swim := world.get_node("MountedSwimming")
	var active_body: Variant = mounted_swim.get("body")
	return _expect(active_body == null or not is_instance_valid(active_body),
		"%s: MountedSwimming has an active swim-mount body" % label)


func _party_label(game: Node) -> String:
	var parts: Array[String] = []
	for member: RefCounted in game.party.call("members"):
		parts.append("%s:L%d" % [member.species_id, member.level])
	return "[" + ",".join(parts) + "]"


## The ~15 percent steering deviation along an authored polyline: seven
## alternating lateral offsets at equal arc-length stations, then the end. The
## offset amplitude is solved so the commanded length is `ratio` times the
## authored path length even where the path bends.
func _path_zigzag(path: Array[Vector3], ratio: float) -> Array[Vector3]:
	var low := 0.0
	var high := 0.2
	var points: Array[Vector3] = []
	var length := _horizontal_polyline_length(path[0], path.slice(1))
	for _iteration in 40:
		var factor := (low + high) * 0.5
		points = _path_zigzag_points(path, length, factor * length)
		if _horizontal_polyline_length(path[0], points) / length < ratio:
			low = factor
		else:
			high = factor
	return points


func _path_zigzag_points(path: Array[Vector3], length: float, amplitude: float) -> Array[Vector3]:
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


func _final_hop_zigzag(from: Vector3, target: Vector3) -> Array[Vector3]:
	var start := Vector2(from.x, from.z)
	var end := Vector2(target.x, target.z)
	var delta := end - start
	var amplitude := delta.length() * 0.04
	var lateral := Vector2(-delta.y, delta.x).normalized() * amplitude
	var points: Array[Vector3] = []
	for index in range(1, 8):
		var centre := start.lerp(end, float(index) / 8.0)
		var offset := lateral if index % 2 == 1 else -lateral
		points.append(Vector3(centre.x + offset.x, 0.0, centre.y + offset.y))
	points.append(target)
	return points


func _horizontal_polyline_length(start: Vector3, points: Array[Vector3]) -> float:
	var length := 0.0
	var previous := Vector2(start.x, start.z)
	for point: Vector3 in points:
		var next := Vector2(point.x, point.z)
		length += previous.distance_to(next)
		previous = next
	return length


func _move_to(target: Vector3, tolerance: float, frame_limit: int) -> bool:
	var previous := player.global_position
	var previous_stamina := float(player.get("vitals").stamina)
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
			if route_minimum_stamina < INF:
				route_minimum_stamina = minf(route_minimum_stamina, float(player.get("vitals").stamina))
		if route_minimum_stamina < INF:
			var current_stamina := float(player.get("vitals").stamina)
			route_max_stamina_gain_per_frame = maxf(route_max_stamina_gain_per_frame,
				current_stamina - previous_stamina)
			previous_stamina = current_stamina
		previous = player.global_position
		if pin_swim_level_zero:
			_pin_swimming_level_zero()
		if float(player.get("vitals").health) <= 0.0:
			return _fail("died while moving toward %s from %s" % [target, player.global_position])
	return _fail("movement timed out target=%s actual=%s velocity=%s aquatic=%s" % [target, player.global_position, player.velocity, swimming.snapshot()])


func _pin_swimming_level_zero() -> void:
	var skills: RefCounted = root.get_node("Game").local.skills
	pinned_minimum_efficiency = minf(pinned_minimum_efficiency, float(skills.efficiency("swimming")))
	if skills.level("swimming") != 0 or float(skills.fraction("swimming")) > 0.0:
		skills.load_data({"revealed": skills.revealed})


func _action(pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = "move_forward"
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


func _anchor(config: Dictionary, id: String) -> Vector3:
	for anchor: Dictionary in config.anchors:
		if str(anchor.id) == id:
			return _vector(anchor.safe_position)
	return Vector3.INF


func _route(config: Dictionary, id: String) -> Dictionary:
	for raw: Variant in config.get("water_routes", []):
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == id:
			return raw as Dictionary
	return {}


func _rest_route_argument() -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--rest-route="):
			return argument.trim_prefix("--rest-route=").strip_edges()
	return ""


func _original_five_argument() -> bool:
	return OS.get_cmdline_user_args().has("--original-five")


func _every_hop_argument() -> bool:
	return OS.get_cmdline_user_args().has("--every-hop")


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
	finished = true
	push_error("WATER SWIMMING: " + message)
	quit(1)
	return false
