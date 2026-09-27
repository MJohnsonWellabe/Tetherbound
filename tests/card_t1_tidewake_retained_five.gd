extends "res://tests/smoke_water_hop_walked.gd"

## Chapter exit card T1 "Tidewake retained-five water route" (docs/ACCEPTANCE.md
## §6.2): "From the S3 save, a human swimmer with the original five and no swim
## mount crosses every mandatory gap with >=20% stamina after 15% steering
## deviation. Shore/anchor, drowning, combat pause, mount/dismount, reload and
## host/guest state agree; optional mounted routes remain labelled and cannot
## bypass story gates."
##
## ONE continuous process, in this order (each phase prints `CARD ITEM` lines
## with EXPECTED and OBSERVED):
##   A  arrival   declared Water-arrival start (no earned S3 save exists; see
##                tests/helpers/tidewake_b_water_arrival_dry_fixture.gd), with the
##                ORIGINAL FIVE (smoke_water_swimming.gd ORIGINAL_FIVE) in place of
##                the fixture's own belt; production `enter_realm`.
##   B  mount     no party member is a compatible swim mount; the production
##                RidingController refuses to mount; MountedSwimming never takes a
##                body; every mount-only route is labelled optional (off the main
##                path, needs saddle + Swim Stone the player does not hold).
##   C  chain     every mandatory sheltered hop (7 routes, 24 hops) swum by real
##                input along a ~15% commanded zigzag from the arrival point, level-0
##                swim efficiency, no position write, no stamina write; island
##                walks between routes by left stick (same method as
##                smoke_water_hop_walked.gd, whose helpers this reuses).
##   D  fight     mid-swim wild fight with the original five: Engage by the
##                interact press, stamina frozen through the fight (COMBAT_PAUSED),
##                won through production combat, drain resumes at the configured rate.
##   E  drowning  exhaustion fixture mid-water -> gradual drowning -> the swimmer
##                returns to the safe shore by input; drowning stops and stamina
##                regenerates on dry land; the earned safe landing is the shore.
##   F  reload    swims back out, the character is written mid-water through
##                SaveGame, the world is destroyed and rebuilt from the disk
##                record: pose, stamina, safe landing, party and no-mount state
##                agree; then the swimmer continues by input to land.
##
## Disclosed shortcuts (all listed again in the evidence SUMMARY):
##   * declared arrival fixture (Stormwood completion flags via the ledger,
##     realm_key_water treated as spent), original five at L41-44;
##   * each chained route's `required_departure_flag` set at start (story
##     objectives are not earned here), and before phase D every dock
##     `unlock_flag` (as smoke_water_combat_pause.gd) so the closed-gate tide race
##     does not ring the salt_crown rest shoal;
##   * swimming XP cleared after every chain movement frame (level-0 pin);
##   * ONE position write after the chain: onto the authored dry rest shoal
##     tidal_cradle_to_salt_crown_rest_03 beside the only proven surface wild pair;
##   * the wild's hp capped at ENEMY_HP_CEILING once engaged (enemy_hp_ceiling);
##   * the stamina=0 exhaustion fixture in phase E and again in phase F.
##
##   godot --headless --path . --script tests/card_t1_tidewake_retained_five.gd
##       [-- --skip-chain]   (phases A,B,D,E,F only; for iteration, not a card pass)
const FIXTURE := preload("res://tests/helpers/tidewake_b_water_arrival_dry_fixture.gd")
const SITE_ID := "road_visibility_tidal_cradle_to_salt_crown_sheltered_04"
const FIGHT_ANCHOR := "tidal_cradle_to_salt_crown_rest_03"
const ENEMY_HP_CEILING := 12.0
const HUMAN := 1
const PAUSED := 3
const MEASURE_FRAMES := 120
const RATE_TOLERANCE := 0.1

var director: Node
var manager: Node
var vitals: RefCounted
var items: Array[String] = []
var failed_items := 0


func _run() -> void:
	create_timer(5200.0).timeout.connect(func() -> void:
		if not finished:
			_fail("5200 second watchdog expired"))
	var skip_chain := OS.get_cmdline_user_args().has("--skip-chain")
	game = root.get_node("Game")
	var started := Time.get_ticks_msec()

	# ---- A: arrival ------------------------------------------------------------
	var arrival: Dictionary = await FIXTURE.new().start(self, game, ORIGINAL_FIVE)
	if not _expect(not arrival.is_empty(), "declared Water arrival did not come up"):
		return
	game.save_system = SAVE.new("user://card_t1_%d/" % Time.get_ticks_usec())
	if not _bind(arrival.world):
		return
	party_species.clear()
	for member: RefCounted in game.party.call("members"):
		party_species.append(str(member.species_id))
	var want: Array[String] = []
	for entry: Dictionary in ORIGINAL_FIVE:
		want.append(str(entry.species))
	var skills: RefCounted = game.local.skills
	var level_zero := true
	for skill: String in PLAYER_SKILLS:
		level_zero = level_zero and skills.level(skill) == 0
	var arrival_at := player.global_position
	var route0_departure := _anchor("first_shore_to_reedhaven_departure")
	_item("A1 arrival", "production enter_realm(water, water_arrival_from_stormwood) lands on first_shore, dry",
		"realm=%s at=%s dist_to_route0_departure=%.2fm on_floor=%s swimming=%s" % [game.current_realm, arrival_at,
			Vector2(arrival_at.x - route0_departure.x, arrival_at.z - route0_departure.z).length(), player.is_on_floor(), swimming.is_swimming()],
		str(game.current_realm) == "water" and player.is_on_floor() and not swimming.is_swimming())
	_item("A2 original five", "party == %s, five members, level-0 human skills" % [want],
		"party=%s level0=%s" % [_party_label(), level_zero], party_species == want and level_zero)

	# ---- B: no swim mount; optional mounted routes labelled -------------------
	var swimmers: Array[String] = []
	for member: RefCounted in game.party.call("members"):
		if _is_swim_mount(str(member.species_id)):
			swimmers.append(str(member.species_id))
	_item("B1 no owned swimmer", "no party member declares a compatible swim_mount",
		"compatible swim mounts in party=%s" % [swimmers], swimmers.is_empty())
	await director.summon_active_creature()
	await _frames(30)
	var riding: Node = world.get_node("RidingController")
	var ally: Node3D = director.ally_body()
	var near := ally != null and is_instance_valid(ally)
	if near:
		# Stand the trainer beside the deployed ally by stick so reach is not the refusal reason.
		await navigator.walk_to(ally.global_position, 600, 1.5)
		_stick(0, 0)
		await _frames(10)
	var mounted: bool = riding.call("mount")
	await _frames(30)
	var mounted_body: Variant = world.get_node("MountedSwimming").get("body")
	_item("B2 mount refused", "production RidingController.mount() refuses (no tack, no swimmer); MountedSwimming takes no body",
		"ally=%s mount()=%s is_mounted=%s mounted_swim_body=%s" % [ally.get("species_id") if near else "none", mounted,
			riding.call("is_mounted"), mounted_body], near and not mounted and not bool(riding.call("is_mounted"))
			and (mounted_body == null or not is_instance_valid(mounted_body)))
	var labelled: Array[String] = []
	var unlabelled: Array[String] = []
	var bag: RefCounted = game.get("inventory")
	for raw: Variant in config.get("water_routes", []):
		var route: Dictionary = raw
		if not bool(route.get("requires_compatible_active_swim_mount", false)):
			continue
		var ok: bool = not bool(route.get("main_path", true)) and str(route.get("intended_traversal", "")) == "swim_mount" \
			and (route.get("required_equipment", []) as Array).has("swim_saddle") \
			and (route.get("required_personal_flags", []) as Array).has("water_swim_stone_earned")
		(labelled if ok else unlabelled).append(str(route.id))
	var holds_saddle := int(bag.call("count", "swim_saddle")) > 0
	var holds_stone := bool(game.local.flags.has("water_swim_stone_earned"))
	_item("B3 optional mounted routes labelled", "every mount-only route: main_path=false, intended_traversal=swim_mount, needs swim_saddle + water_swim_stone_earned (player holds neither)",
		"labelled=%d %s unlabelled=%s holds_saddle=%s holds_stone=%s" % [labelled.size(), labelled, unlabelled, holds_saddle, holds_stone],
		labelled.size() >= 7 and unlabelled.is_empty() and not holds_saddle and not holds_stone)
	await director.dismiss_active_creature()
	await _frames(30)

	# ---- C: every mandatory sheltered hop from the arrival --------------------
	if skip_chain:
		_item("C chain", "every mandatory sheltered hop >=20%", "SKIPPED (--skip-chain; not a card pass)", false)
	else:
		if not await _chain():
			return

	# ---- D: mid-swim fight pauses stamina -----------------------------------------
	for dock: Dictionary in config.docks:
		if not str(dock.get("unlock_flag", "")).is_empty():
			game.world.flags.set_flag(str(dock.unlock_flag))
	var anchor := _anchor(FIGHT_ANCHOR)
	anchor.y = float(world.call("ground_height_at", anchor.x, anchor.z)) + 0.15
	player.global_position = anchor # disclosed: the one post-chain position write
	player.velocity = Vector3.ZERO
	position_writes += 1
	print("FIXTURE position_write at=%s (%s)" % [anchor, FIGHT_ANCHOR])
	await _frames(60)
	if not _expect(player.is_on_floor() and not swimming.is_swimming() and swimming.state.has_safe_landing,
		"rest_03 landing settled dry with an earned safe landing"):
		return
	var landing: Vector3 = swimming.state.safe_landing
	await director.summon_active_creature()
	await _frames(20)
	var pair: Array = []
	for _frame in 240:
		pair = director._site_members.get(SITE_ID, [])
		if pair.size() >= 1:
			break
		await physics_frame
	if not _expect(pair.size() >= 1 and director.ally_body() != null, "surface wild pair %s spawned (%d) and ally deployed" % [SITE_ID, pair.size()]):
		return
	var wild: Node3D = pair[0]
	var swim_start: float = await _swim_until_offered(wild)
	if swim_start < 0.0:
		return
	await _tap(&"interact")
	for _frame in 60:
		if manager.is_fighting():
			break
		await physics_frame
	var engaged: bool = manager.is_fighting() and manager.enemy_body() == wild
	await _frames(3)
	var paused_at := {"stamina": float(vitals.stamina), "health": float(vitals.health), "position": player.global_position}
	var modes := {}
	for _frame in MEASURE_FRAMES:
		await physics_frame
		modes[int(swimming.state.mode)] = true
	var frozen: bool = modes.keys() == [PAUSED] and float(vitals.stamina) == float(paused_at.stamina) \
		and float(vitals.health) == float(paused_at.health)
	_item("D1 combat pause", "Engage mid-swim with the original five: swim mode COMBAT_PAUSED(3), stamina and health frozen for %d frames" % MEASURE_FRAMES,
		"engaged=%s ally=%s modes=%s stamina %.3f->%.3f health %.2f->%.2f" % [engaged, director.ally_body().get("species_id") if director.ally_body() != null else "none",
			modes.keys(), paused_at.stamina, vitals.stamina, paused_at.health, vitals.health], engaged and frozen)
	var won := await _finish_fight(wild)
	var fight_end := player.global_position
	await _frames(2)
	var resume_stamina: float = vitals.stamina
	var drift := Vector2(fight_end.x - paused_at.position.x, fight_end.z - paused_at.position.z).length()
	await _frames(MEASURE_FRAMES)
	var expected_drain := float(_human_config().stamina_drain_per_s) * float(MEASURE_FRAMES) / float(Engine.physics_ticks_per_second)
	var drained := resume_stamina - float(vitals.stamina)
	_item("D2 fight won, drain resumes", "wild faints (victory); swimmer back to HUMAN(1) at the surface, no teleport; drain resumes at configured %.3f/%d frames +-10%%" % [expected_drain, MEASURE_FRAMES],
		"won=%s mode=%d drift=%.3fm resumed_from=%.3f(paused %.3f) drained=%.3f" % [won, swimming.state.mode, drift, resume_stamina, paused_at.stamina, drained],
		won and int(swimming.state.mode) == HUMAN and drift < 0.1 and absf(resume_stamina - float(paused_at.stamina)) < 0.2
			and absf(drained - expected_drain) <= expected_drain * RATE_TOLERANCE)

	# ---- E: drowning, then the safe shore ---------------------------------------
	if not _expect(swimming.is_swimming(), "still swimming after the fight"):
		return
	vitals.stamina = 0.0 # disclosed exhaustion fixture
	var drown_start: float = vitals.health
	await _frames(60)
	var drown_loss := drown_start - float(vitals.health)
	var drowning_seen: bool = swimming.snapshot().drowning
	var min_health := float(vitals.health)
	for target: Vector3 in [landing]:
		var reached := false
		for _frame in 3000:
			var offset := target - player.global_position
			offset.y = 0.0
			if offset.length() <= 0.8 and player.is_on_floor() and not swimming.is_swimming():
				reached = true
				break
			camera.set("yaw", atan2(-offset.x, -offset.z))
			_action(true)
			await physics_frame
			min_health = minf(min_health, float(vitals.health))
			if float(vitals.health) <= 0.0:
				break
		_action(false)
		if not reached:
			_item("E1 drowning -> safe shore", "reach the safe landing alive", "did not reach: at=%s health=%.2f" % [player.global_position, vitals.health], false)
			_finish()
			return
	var ashore_health: float = vitals.health
	var ashore_stamina: float = vitals.stamina
	await _frames(120)
	_item("E1 drowning -> safe shore", "stamina 0 mid-water drowns gradually (health falls, not instant death); swimming back by input reaches the earned safe landing alive",
		"drowning=%s lost %.2f HP in 60 frames, min_health=%.2f, ashore at %s health=%.2f" % [drowning_seen, drown_loss, min_health,
			player.global_position, ashore_health], drowning_seen and drown_loss > 0.5 and min_health > 0.0 and ashore_health > 0.0)
	_item("E2 dry-land recovery", "on dry land: not drowning, health not falling, stamina regenerating; safe landing is the shore",
		"drowning=%s health %.2f->%.2f stamina %.2f->%.2f safe_landing_delta=%.3fm" % [swimming.snapshot().drowning, ashore_health, vitals.health,
			ashore_stamina, vitals.stamina, swimming.state.safe_landing.distance_to(landing)],
		not bool(swimming.snapshot().drowning) and float(vitals.health) >= ashore_health and float(vitals.stamina) > ashore_stamina + 10.0
			and swimming.state.safe_landing.distance_to(landing) < 0.5)

	# ---- F: mid-water save, world rebuilt, continue ---------------------------
	for _frame in 1800:
		if float(vitals.stamina) >= float(vitals.max_stamina):
			break
		await physics_frame
	await director.dismiss_active_creature()
	await _frames(20)
	var out_to: Vector3 = wild.global_position if is_instance_valid(wild) else paused_at.position
	for _frame in 900:
		var offset: Vector3 = out_to - player.global_position
		offset.y = 0.0
		if swimming.is_swimming() and offset.length() < 20.0:
			break
		if offset.length() < 1.0:
			break
		camera.set("yaw", atan2(-offset.x, -offset.z))
		_action(true)
		await physics_frame
	_action(false)
	await _frames(20)
	if not _expect(swimming.is_swimming(), "phase F: swam back out into deep water"):
		return
	paused = true
	var saved_pos := player.global_position
	var saved_stamina: float = vitals.stamina
	var saved_health: float = vitals.health
	var saved_landing: Vector3 = swimming.state.safe_landing
	var saved_party := _party_label()
	var character_id := str(game.local.character_id)
	game.call("_capture_player_pose")
	var wrote: bool = game.save_system.save_character(game, character_id)
	var disk: Dictionary = game.save_system.characters().read(character_id)
	var old: WeakRef = weakref(world)
	current_scene = null
	world.queue_free()
	await process_frame
	await process_frame
	var destroyed := old.get_ref() == null
	game.local.reset()
	game.local.load_data(disk)
	# The party comes back from the same disk record through SaveGame's own
	# party decoder, not from the live Game.party that survived the teardown.
	game.party.call("clear")
	var cleared := int(game.party.call("size")) == 0
	game.save_system._array_to_party(disk.get("party", []), game.party)
	print("CARD reload party_cleared=%s disk_party=%d restored=%s" % [cleared, (disk.get("party", []) as Array).size(), _party_label()])
	var rebuilt: Node3D = WORLD.instantiate()
	root.add_child(rebuilt)
	current_scene = rebuilt
	for _frame in 1200:
		await process_frame
		if bool(rebuilt.call("shell_build_complete")):
			break
	if not _expect(bool(rebuilt.call("shell_build_complete")) and _bind(rebuilt), "rebuilt Water world"):
		return
	var restored_pos := player.global_position
	_item("F1 reload mid-water", "SaveGame writes the swimming character; destroyed world; rebuilt world restores same character, midwater pose (<0.15m), stamina, health, safe landing, original five, unmounted, swimming",
		"wrote=%s aquatic=%s destroyed=%s id=%s pos_delta=%.3fm stamina %.2f/%.2f health %.2f/%.2f landing_delta=%.3fm party=%s (was %s) swimming=%s mounted=%s" % [
			wrote, disk.get("player_pose", {}).get("aquatic") is Dictionary, destroyed, game.local.character_id,
			restored_pos.distance_to(saved_pos), vitals.stamina, saved_stamina, vitals.health, saved_health,
			swimming.state.safe_landing.distance_to(saved_landing), _party_label(), saved_party, swimming.is_swimming(),
			world.get_node("RidingController").call("is_mounted")],
		wrote and destroyed and str(game.local.character_id) == character_id and restored_pos.distance_to(saved_pos) < 0.15
			and absf(float(vitals.stamina) - saved_stamina) < 0.5 and absf(float(vitals.health) - saved_health) < 0.5
			and swimming.state.safe_landing.distance_to(saved_landing) < 0.15 and _party_label() == saved_party
			and swimming.is_swimming() and not bool(world.get_node("RidingController").call("is_mounted")))
	paused = false
	await _frames(30)
	var continued_min := float(vitals.stamina)
	var reached_land := false
	for _frame in 3000:
		var offset: Vector3 = saved_landing - player.global_position
		offset.y = 0.0
		if offset.length() <= 0.8 and player.is_on_floor() and not swimming.is_swimming():
			reached_land = true
			break
		camera.set("yaw", atan2(-offset.x, -offset.z))
		_action(true)
		await physics_frame
		continued_min = minf(continued_min, float(vitals.stamina))
	_action(false)
	_item("F2 continue after reload", "real input swims the reloaded character back to the saved safe landing; stamina drains normally (no refill), ends dry",
		"reached=%s at=%s min_stamina=%.2f (resumed at %.2f) health=%.2f" % [reached_land, player.global_position, continued_min, saved_stamina, vitals.health],
		reached_land and continued_min < saved_stamina and float(vitals.health) > 0.0)
	print("CARD elapsed_s=%.1f position_writes_total=%d" % [float(Time.get_ticks_msec() - started) / 1000.0, position_writes])
	_finish()


func _bind(scene: Node3D) -> bool:
	world = scene
	player = world.get_node("Player")
	camera = world.get_node("CameraRig")
	swimming = player.get("swim_controller")
	config = world.get("config")
	director = world.get_node("EncounterDirector")
	manager = world.get_node("CombatManager")
	vitals = player.get("vitals")
	navigator = NAV.new(self, player, camera, _stick)
	return _expect(swimming != null and director != null and manager != null, "production Water nodes present")


## Phase C: same method as smoke_water_hop_walked.gd `_run`, starting from the
## arrival instead of a position write.
func _chain() -> bool:
	var routes: Array[Dictionary] = []
	for edge: String in EDGES:
		var route := _route("%s_sheltered" % edge)
		if not _expect(bool(route.get("main_path", false)) and str(route.get("intended_traversal", "")) == "human_level_0"
			and not bool(route.get("requires_compatible_active_swim_mount", true)), "%s is not mandatory level-0" % edge):
			return false
		routes.append(route)
	var mandatory: Array[String] = []
	for raw: Variant in config.water_routes:
		if bool((raw as Dictionary).get("main_path", false)):
			mandatory.append(str((raw as Dictionary).id))
	print("CARD mandatory main_path routes=%d %s" % [mandatory.size(), mandatory])
	var flags: Array[String] = []
	for route: Dictionary in routes:
		var flag := str(route.get("required_departure_flag", ""))
		if not flag.is_empty():
			game.world.flags.call("set_flag", flag, true)
			flags.append(flag)
	print("FIXTURE departure_flags=%s" % ",".join(flags))
	var worst := INF
	var worst_label := ""
	var hops := 0
	var walk_total := 0.0
	var summary: Array[String] = []
	tracking = true
	for route_index in routes.size():
		var route: Dictionary = routes[route_index]
		var route_id := str(route.id)
		var target := _anchor(str(route.from_anchor))
		var gap := Vector2(player.global_position.x - target.x, player.global_position.z - target.z).length()
		if gap > 1.0:
			var walked: Variant = await _walk_island(target, "%s island walk" % route_id)
			if walked == null:
				return false
			walk_total += float(walked.metres)
			print("ISLAND WALK to=%s walked_m=%.2f legs=%d confined_resets=%d stamina_pct_after=%.2f" % [route.from_anchor,
				float(walked.metres), int(walked.legs), int(walked.resets), float(vitals.stamina)])
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
				return false
			boundaries.append(found)
		boundaries.append(path.size() - 1)
		var per_hop: Array[String] = []
		for hop in boundaries.size() - 1:
			var hop_path: Array[Vector3] = []
			for vertex in range(boundaries[hop], boundaries[hop + 1] + 1):
				hop_path.append(path[vertex])
			var label := "%s hop %d" % [route_id, hop + 1]
			_stick(0.0, 0.0)
			await _frames(4)
			var snap := Vector2(player.global_position.x - hop_path[0].x, player.global_position.z - hop_path[0].z).length()
			if not _expect(snap <= 1.0 and player.is_on_floor() and not swimming.is_swimming(), "%s: start %.3fm off or not dry" % [label, snap]):
				return false
			var arrive_pct := float(vitals.stamina) / float(vitals.max_stamina) * 100.0
			var rest_frames := 0
			while float(vitals.stamina) < float(vitals.max_stamina) and rest_frames < 1800:
				await physics_frame
				rest_frames += 1
			var skills: RefCounted = game.local.skills
			skills.load_data({"revealed": skills.revealed})
			if not _original_five_unmounted(label):
				return false
			var health_before: float = vitals.health
			observed_swim_distance = 0.0
			hop_minimum_stamina = float(vitals.stamina)
			pinned_minimum_efficiency = 1.0
			var hop_length := _polyline_length(hop_path[0], hop_path.slice(1))
			var commanded := _path_zigzag(hop_path, STEER_RATIO)
			var ratio := _polyline_length(hop_path[0], commanded) / hop_length
			if not _expect(ratio >= 1.14 and ratio <= 1.17, "%s: steering ratio %.3f" % [label, ratio]):
				return false
			for point: Vector3 in commanded:
				if not await _move_to(point, 0.8, 1200, true):
					return false
			await _frames(20)
			var fraction := hop_minimum_stamina / float(vitals.max_stamina)
			if fraction < worst:
				worst = fraction
				worst_label = label
			hops += 1
			var ok: bool = fraction >= 0.20 and player.is_on_floor() and not swimming.is_swimming() \
				and is_equal_approx(float(vitals.health), health_before) and observed_swim_distance > 1.0 \
				and is_equal_approx(pinned_minimum_efficiency, 1.0) \
				and Vector2(swimming.state.safe_landing.x - hop_path[-1].x, swimming.state.safe_landing.z - hop_path[-1].z).length() < 0.1
			print("WALKED HOP id=%s hop=%d from=%s to=%s path_m=%.3f steer_ratio_vs_path=%.3f actual_swim_m=%.3f arrive_pct=%.2f rest_frames=%d min_stamina_pct=%.2f pinned_min_efficiency=%.4f start_snap_m=%.3f safe_landing_earned=%s result=%s" % [
				route_id, hop + 1, stops[hop], stops[hop + 1], hop_length, ratio, observed_swim_distance, arrive_pct, rest_frames,
				fraction * 100.0, pinned_minimum_efficiency, snap,
				Vector2(swimming.state.safe_landing.x - hop_path[-1].x, swimming.state.safe_landing.z - hop_path[-1].z).length() < 0.1,
				"PASS" if ok else "FAIL"])
			per_hop.append("%.2f" % (fraction * 100.0))
			if not _expect(ok, "%s failed (min %.2f%%)" % [label, fraction * 100.0]):
				return false
			if not _original_five_unmounted(label + " (arrival)"):
				return false
		summary.append("%s hops=[%s]" % [route_id, " / ".join(per_hop)])
	tracking = false
	for line: String in summary:
		print("ROUTE " + line)
	_item("C1 every mandatory sheltered hop", "7 sheltered main-path routes (24 hops) from the arrival, 15%% zigzag, level-0, original five unmounted: every hop min stamina >=20%%, ends on the authored safe landing, no position/stamina write",
		"hops=%d worst=%.2f%% (%s) position_writes=%d island_walk_m=%.1f max_gain_per_frame=%.4f" % [hops, worst * 100.0, worst_label,
			position_writes, walk_total, max_gain_per_frame], hops == 24 and worst >= 0.20 and position_writes == 0)
	return true


## Real stick toward the wild; returns the stamina when the Engage offer wins, or -1.
func _swim_until_offered(wild: Node3D) -> float:
	var arbiter: Node = world.get_node("InteractionArbiter")
	var swim_frames := 0
	for _frame in 2400:
		var offset := wild.global_position - player.global_position
		offset.y = 0.0
		if swimming.is_swimming():
			swim_frames += 1
		if swimming.is_swimming() and swim_frames > 90 and director._engageable() == wild and arbiter.winning_provider() == director:
			_stick(0, 0)
			await _frames(2)
			return float(vitals.stamina)
		var direction := offset.normalized() if offset.length() > 2.0 else Vector3.ZERO
		var local: Vector3 = camera.planar_basis().inverse() * direction
		_stick(local.x, local.z)
		await physics_frame
	_stick(0, 0)
	_fail("never reached an Engage offer: player=%s wild=%s swimming=%s" % [player.global_position, wild.global_position, swimming.is_swimming()])
	return -1.0


func _finish_fight(wild: Node3D) -> bool:
	var tick := 0
	var all_paused := true
	while manager.is_fighting() and tick < 3600:
		var enemy: RefCounted = manager.enemy()
		if enemy != null and float(enemy.hp) > ENEMY_HP_CEILING:
			enemy.hp = ENEMY_HP_CEILING # disclosed hp ceiling
		var foe: Node3D = manager.enemy_body()
		var ally: Node3D = director.ally_body()
		if is_instance_valid(foe) and is_instance_valid(ally):
			var offset := foe.global_position - ally.global_position
			offset.y = 0.0
			if offset.length() > manager.combat_move_reach("quick") * 0.8:
				var local: Vector3 = camera.planar_basis().inverse() * offset.normalized()
				_stick(local.x, local.z)
			else:
				_stick(0, 0)
		if tick % 20 == 0:
			Input.action_press("combat_quick")
		elif tick % 20 == 2:
			Input.action_release("combat_quick")
		if int(swimming.state.mode) != PAUSED:
			all_paused = false
		tick += 1
		await physics_frame
	Input.action_release("combat_quick")
	_stick(0, 0)
	print("CARD fight frames=%d paused_throughout=%s wild_alive=%s" % [tick, all_paused, is_instance_valid(wild) and bool(wild.call("is_alive"))])
	return not manager.is_fighting() and all_paused and is_instance_valid(wild) and not bool(wild.call("is_alive"))


func _human_config() -> Dictionary:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_swimming.json"))
	return parsed.human


func _tap(action: StringName) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	down.strength = 1.0
	Input.parse_input_event(down)
	await process_frame
	await _frames(4)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame
	await _frames(8)


func _item(id: String, expected: String, observed: String, ok: bool) -> void:
	if not ok:
		failed_items += 1
	var line := "CARD ITEM %s | EXPECTED %s | OBSERVED %s | %s" % [id, expected, observed, "PASS" if ok else "FAIL"]
	items.append(line)
	print(line)


func _finish() -> void:
	_action(false)
	_stick(0, 0)
	finished = true
	print("---- CARD T1 SUMMARY ----")
	for line: String in items:
		print(line)
	print("CARD T1 %s items=%d failed=%d assertions=%d" % ["PASS" if failed_items == 0 else "FAIL", items.size(), failed_items, assertions])
	quit(0 if failed_items == 0 else 1)


func _fail(message: String) -> bool:
	if finished:
		return false
	_item("ABORT", "run completes", message, false)
	_finish()
	return false
