extends "res://tools/net/peer_runner.gd"

## C2 opt-in stress fixture. Three real ENet participants and one shared wild.
## Only initial HP/loadouts are prepared; no timed damage, energy, cooldown,
## AI, geometry or graphics feature is bypassed. Input uses the existing tap.
const F25_LIBRARY := preload("res://scripts/vfx/move_effect_library.gd")
const F25_BUDGET := preload("res://scripts/vfx/move_effect_budget.gd")
const F25_GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")

var _f25_running := false
var _f25_done := false
var _f25_sample := false
var _f25_measuring := false
var _f25_summary: Dictionary = {}
var _f25_failures: Array[String] = []
var _f25_frames: Array[float] = []
var _f25_launches: Array[Dictionary] = []
var _f25_impacts: Array[Dictionary] = []
var _f25_launch_peer: Dictionary = {}
var _f25_launch_counts: Dictionary = {}
var _f25_damage_counts: Dictionary = {}
var _f25_census: Array[Dictionary] = []
var _f25_expected_uid := ""
var _f25_particles_peak := 0
var _f25_lights_peak := 0
var _f25_effects_peak := 0
var _f25_body_peak := 0

func _initialize() -> void:
	F25_LIBRARY.config()["enabled"] = true
	if str(_parse_args().get("role", "")) == "host":
		if F25_GRAPHICS.choose("Medium") != OK:
			push_error("F25 Medium preference could not be selected")
			quit(2)
			return
	super._initialize()

func _execute_step(msg: Dictionary) -> Dictionary:
	var args: Dictionary = msg.get("args", {})
	match str(msg.get("action", "")):
		"f25_prepare": return await _f25_prepare(args)
		"f25_stage_wild": return _f25_stage_wild(args)
		"f25_arm":
			if _f25_running or _f25_done:
				return {"verdict":"FAIL", "detail":"fixture is single-use"}
			var manager := _combat_manager()
			if manager == null or not manager.call("is_fighting"):
				return {"verdict":"FAIL", "detail":"arm requires a real fight"}
			var active: RefCounted = manager.call("active_creature")
			if active == null or str(active.get("uid")) != _f25_expected_uid:
				return {"verdict":"FAIL", "detail":"deployed creature differs from prepared owned UID"}
			_f25_running = true
			_f25_sample = bool(args.get("sample", false))
			manager.connect("attack_launched", _f25_on_launch)
			manager.connect("impact_confirmed", _f25_on_impact)
			_f25_run(args)
			return {"verdict":"PASS", "detail":"normal input bot armed"}
	return await super._execute_step(msg)

func _execute_probe(msg: Dictionary) -> Variant:
	if str(msg.get("what", "")) == "f25_status":
		return {"done":_f25_done, "summary":_f25_summary, "failures":_f25_failures}
	return await super._execute_probe(msg)

func _f25_endurance(creature: RefCounted) -> void:
	var cfg: Dictionary = NET_PROGRESSION.config()
	var growth: Dictionary = cfg.get("level", {}).get("growth_per_level", {})
	var factor: float = NET_PROGRESSION.stat_at_level(1.0, int(creature.get("level")), float(growth.get("hp", 0.0)))
	factor *= NET_PROGRESSION.individuality_multiplier(float(creature.get("iv_hp")), cfg)
	creature.set("base_hp", 1000000.0 / factor)
	creature.call("recompute_stats_from_base", cfg)
	creature.set("hp", creature.get("max_hp"))

func _f25_prepare(args: Dictionary) -> Dictionary:
	if _session() != null and _session().call("is_active"):
		return {"verdict":"FAIL", "detail":"prepare must precede admission"}
	var grant: Dictionary = await _step_party_grant({"species":str(args.get("species", "cindercub")), "level":1})
	if grant.get("verdict") != "PASS": return grant
	var game := root.get_node(^"Game")
	var party: RefCounted = game.get("party")
	var creature: RefCounted = party.call("at", int(party.call("size")) - 1)
	_f25_endurance(creature)
	var known: Array[String] = []
	for move: Variant in creature.get("known_moves"): known.append(str(move))
	var mastery: Dictionary = creature.get("move_mastery_uses").duplicate(true)
	for slot: String in ["quick", "charged"]:
		var move_id := str(args.get(slot, creature.get("move_" + slot)))
		if move_id.is_empty():
			return {"verdict":"FAIL", "detail":"missing named " + slot}
		if not known.has(move_id): known.append(move_id)
		creature.set("move_" + slot, move_id)
		mastery[move_id] = 300
	creature.set("known_moves", known)
	creature.set("move_mastery_uses", mastery)
	creature.set("loadout_revision", int(creature.get("loadout_revision")) + 1)
	if not party.call("set_active", int(party.call("size")) - 1):
		return {"verdict":"FAIL", "detail":"active creature refused"}
	var local: RefCounted = game.get("local")
	var saved: Dictionary = local.call("save_data")
	local.set("redesign_character", TEACHING.character_loadout_mirror(saved.get("party", []), local.get("redesign_character")))
	_f25_expected_uid = str(creature.get("uid"))
	return {"verdict":"PASS", "detail":"isolated pre-admission rank5 endurance fixture", "data":{
		"uid":_f25_expected_uid, "species":creature.get("species_id"), "hp":creature.get("hp"),
		"quick":creature.get("move_quick"), "charged":creature.get("move_charged")}}

func _f25_stage_wild(args: Dictionary) -> Dictionary:
	var director := _encounter_director()
	var player := _probe.call("player") as Node3D
	if _role != "host" or director == null or player == null or _combat_manager().call("is_fighting"):
		return {"verdict":"FAIL", "detail":"wild staging requires idle host world"}
	var wild: Node3D = director.call("spawn_wild", str(args.get("species", "cindercub")),
		player.global_position + Vector3(0, 0, -3), {"level":1, "wander_radius":0.0, "aggressive":false, "name":"F25_TestWild"})
	if wild == null: return {"verdict":"FAIL", "detail":"ordinary wild spawn refused"}
	var creature: RefCounted = wild.get("instance")
	_f25_endurance(creature)
	return {"verdict":"PASS", "detail":"ordinary wild staged before opening", "data":{
		"uid":creature.get("uid"), "species":creature.get("species_id"), "hp":creature.get("hp"),
		"position":[wild.global_position.x,wild.global_position.y,wild.global_position.z]}}

func _f25_peer_key(action_id: String) -> String:
	var pieces := action_id.split(":")
	return pieces[pieces.size()-2] if pieces.size() >= 3 else "invalid"

func _f25_on_launch(on_enemy: bool, launch: Dictionary, presentation: Node3D) -> void:
	if not _f25_measuring or not _f25_sample or not on_enemy: return
	var action_id := str(launch.get("action_id", ""))
	var peer := _f25_peer_key(action_id)
	var rank := int(launch.get("mastery_rank", -1))
	var script_path := ""
	if is_instance_valid(presentation):
		var script: Script = presentation.get_script()
		if script != null: script_path = script.resource_path
	var valid := script_path == "res://scripts/vfx/move_effect.gd" and rank == 5
	_f25_launches.append({"action_id":action_id,"peer_id":peer,"rank":rank,"move_id":launch.get("move_id"),
		"actor_binding":launch.get("attacker_binding",{}),"presentation_script":script_path,"valid":valid})
	if valid:
		_f25_launch_peer[action_id] = peer
		_f25_launch_counts[peer] = int(_f25_launch_counts.get(peer,0)) + 1
	else: _f25_failures.append("invalid rank5 production effect launch " + action_id)

func _f25_on_impact(on_enemy: bool, impact: Dictionary, _where: Vector3) -> void:
	if not _f25_measuring or not _f25_sample or not on_enemy: return
	var action_id := str(impact.get("action_id", ""))
	_f25_impacts.append(impact.duplicate(true))
	if _f25_launch_peer.has(action_id) and float(impact.get("applied_damage",impact.get("damage",0))) > 0.0:
		var peer := str(_f25_launch_peer[action_id])
		_f25_damage_counts[peer] = int(_f25_damage_counts.get(peer,0)) + 1

func _f25_bot() -> void:
	while _f25_running:
		var manager := _combat_manager()
		if manager != null and manager.call("is_fighting"):
			var ally: Node3D = _encounter_director().call("ally_body")
			var enemy: Node3D = manager.call("enemy_body")
			var move := Vector3.ZERO
			if is_instance_valid(ally) and is_instance_valid(enemy):
				move = enemy.global_position-ally.global_position
				move.y = 0
				if move.length() > float(manager.call("combat_move_reach","quick"))*0.85:
					var rig := _probe.call("camera_rig") as Node3D
					var planar: Basis = rig.call("planar_basis") if rig != null and rig.has_method("planar_basis") else Basis.IDENTITY
					var local := planar.inverse()*move.normalized()
					_drive_left(local.x,local.z)
				else: _drive_left(0,0)
			var action := ""
			if manager.call("charged_ready"): action = "combat_charged"
			elif manager.call("quick_ready"): action = "combat_quick"
			if not action.is_empty():
				var result: Dictionary = await _step_press({"action":action})
				if result.get("verdict") != "PASS": _f25_failures.append(str(result.get("detail")))
		await create_timer(0.10).timeout
	_drive_left(0,0)

func _f25_take_census() -> void:
	var director := _encounter_director()
	var record: Dictionary = director.call("encounter_record")
	var manager := _combat_manager()
	var bodies: Array = get_nodes_in_group(&"deployed_creature")
	var enemy: Node3D = manager.call("enemy_body")
	var live := 0
	var visible := 0
	var on_screen := 0
	var camera := root.get_camera_3d()
	var body_rows: Array[Dictionary] = []
	var owners: Dictionary = {}
	for body: Node3D in bodies:
		if not body.is_visible_in_tree(): continue
		var peer := int(body.get("owner_peer_id"))
		var card: Dictionary = director.call("_creature_card_for",peer)
		var binding: Dictionary = director.call("_strike_actor_binding",str(record.get("encounter_id","")),peer,body)
		if binding.is_empty() or str(binding.get("creature_uid","")) != str(card.get("creature_uid","")):
			_f25_failures.append("visible body lacks admitted creature binding")
			continue
		if owners.has(peer): _f25_failures.append("duplicate visible body for one owner")
		owners[peer] = true
		if float(card.get("hp",0)) > 0: live += 1
		visible += 1
		var centre: Vector3 = body.call("centre") if body.has_method("centre") else body.global_position
		if camera != null and not camera.is_position_behind(centre) and Rect2(Vector2.ZERO,Vector2(root.size)).has_point(camera.unproject_position(centre)):
			on_screen += 1
		body_rows.append({"owner_peer_id":peer,"uid":card.get("creature_uid"),"binding":binding,
			"hp":card.get("hp"),"species":card.get("species_id"),"position":[body.global_position.x,body.global_position.y,body.global_position.z]})
	if is_instance_valid(enemy):
		var opponent: Dictionary = record.get("opponent",{})
		if float(opponent.get("hp",0)) > 0: live += 1
		if enemy.is_visible_in_tree(): visible += 1
		var centre: Vector3 = enemy.call("centre") if enemy.has_method("centre") else enemy.global_position
		if camera != null and not camera.is_position_behind(centre) and Rect2(Vector2.ZERO,Vector2(root.size)).has_point(camera.unproject_position(centre)):
			on_screen += 1
		body_rows.append({"opponent":true,"uid":opponent.get("card",{}).get("uid"),"hp":opponent.get("hp"),
			"position":[enemy.global_position.x,enemy.global_position.y,enemy.global_position.z]})
	var particles := F25_BUDGET.used(str(record.get("encounter_id", "")))
	_f25_particles_peak = maxi(_f25_particles_peak, particles)
	_f25_lights_peak = maxi(_f25_lights_peak, F25_BUDGET.lights_used())
	var effects := get_nodes_in_group(&"move_effect_presentation")
	_f25_effects_peak = maxi(_f25_effects_peak, effects.size())
	for effect: Node in effects:
		var mesh_bodies: Array = effect.get("_bodies")
		_f25_body_peak = maxi(_f25_body_peak, mesh_bodies.size())
	_f25_census.append({"time_us":Time.get_ticks_usec(),"participants":record.get("participants",{}).keys(),
		"combat_bodies":live,"visible_bodies":visible,"on_screen_centres":on_screen,"bodies":body_rows,"hp":record.get("opponent",{}).get("hp",-1),
		"particles":particles,"effects":effects.size()})

func _f25_run(args: Dictionary) -> void:
	_f25_bot()
	var warmup := float(args.get("warmup_seconds",10.0))
	var seconds := float(args.get("measurement_seconds",60.0))
	await create_timer(warmup).timeout
	if _f25_sample:
		var before_out := str(args.get("output_dir",""))
		if not before_out.is_empty():
			DirAccess.make_dir_recursive_absolute(before_out)
			await RenderingServer.frame_post_draw
			if root.get_texture().get_image().save_png(before_out.path_join("native-before.png")) != OK:
				_f25_failures.append("native before screenshot save failed")
	_f25_measuring = true
	var manager := _combat_manager()
	var before: Dictionary = _encounter_director().call("encounter_record")
	var initial_hp := float(before.get("opponent",{}).get("hp",-1))
	var start := Time.get_ticks_usec()
	var previous := start
	while previous - start < int(seconds * 1000000.0):
		await process_frame
		var now := Time.get_ticks_usec()
		if _f25_sample:
			_f25_frames.append(float(now-previous)/1000000.0)
			_f25_take_census()
		previous = now
	_f25_measuring = false
	_f25_running = false
	var ended := Time.get_ticks_usec()
	var final_record: Dictionary = _encounter_director().call("encounter_record")
	var participants: Array = final_record.get("participants",{}).keys()
	var participants_min := 999
	var bodies_min := 999
	var visible_min := 999
	var on_screen_min := 999
	for census: Dictionary in _f25_census:
		participants_min = mini(participants_min,census.participants.size())
		bodies_min = mini(bodies_min,int(census.combat_bodies))
		visible_min = mini(visible_min,int(census.visible_bodies))
		on_screen_min = mini(on_screen_min,int(census.on_screen_centres))
	var total := 0.0
	for frame: float in _f25_frames: total += frame
	var sorted := _f25_frames.duplicate()
	sorted.sort()
	var slow_count := maxi(1,int(ceil(float(sorted.size())*0.01)))
	var slow_total := 0.0
	for i in mini(slow_count,sorted.size()): slow_total += sorted[sorted.size()-1-i]
	var final_hp := float(final_record.get("opponent",{}).get("hp",-1))
	if _f25_sample:
		if participants_min != 3 or bodies_min != 4 or visible_min != 4: _f25_failures.append("three participants/four live visible bodies not sustained")
		if final_hp >= initial_hp: _f25_failures.append("shared host HP did not decrease")
		if _f25_launch_counts.size() != 3 or _f25_damage_counts.size() != 3: _f25_failures.append("rank5 effect launches and matching impacts from every participant not established")
		if _f25_particles_peak > 384 or _f25_lights_peak > 4 or _f25_body_peak > 12: _f25_failures.append("effect allocation cap exceeded")
		if F25_GRAPHICS.selected() != "Medium" or RenderingServer.get_current_rendering_method() != "forward_plus": _f25_failures.append("native Medium Forward+ not active")
		if root.size != Vector2i(1920,1080): _f25_failures.append("native1080 viewport not established")
		if DisplayServer.window_get_mode()!=DisplayServer.WINDOW_MODE_FULLSCREEN: _f25_failures.append("fullscreen not active")
		if on_screen_min != 4: _f25_failures.append("all four creature centres not continuously on screen")
	_f25_summary = {"failures":_f25_failures,"peer_ids":participants,"rank5_launches_by_peer":_f25_launch_counts,
		"damage_by_peer":_f25_damage_counts,"damage_counter_scope":"matching production impact receipts with positive damage; HP delta verified separately",
		"participants_min":participants_min,"combat_bodies_min":bodies_min,"visible_bodies_min":visible_min,
		"on_screen_centres_min":on_screen_min,"census_scope":"every rendered process callback; projected centres are not occlusion or full silhouette proof",
		"instrumentation_scope":"wall FPS includes required headless participant simulation, control heartbeat/world-hash and per-frame census overhead; fixture file/PNG writes outside timed window",
		"sample_count":_f25_frames.size(),"warmup_seconds":warmup,"measurement_seconds":float(previous-start)/1000000.0,
		"recording_elapsed_seconds":float(ended-start)/1000000.0,
		"host_hp_before":initial_hp,"host_hp_after":final_hp,"particle_peak":_f25_particles_peak,"particle_cap":384,
		"scene_lights_peak":_f25_lights_peak,"scene_lights_cap":4,"mesh_bodies_per_effect_peak":_f25_body_peak,
		"effects_peak":_f25_effects_peak,"average_fps":float(_f25_frames.size())/total if total>0 else 0,
		"one_percent_low_fps":float(slow_count)/slow_total if slow_total>0 else 0,
		"minimum_fps":1.0/float(sorted.back()) if not sorted.is_empty() else 0,
		"settings":{"renderer":RenderingServer.get_current_rendering_method(),"display":DisplayServer.get_name(),
			"resolution":[root.size.x,root.size.y],"fullscreen":DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN,
			"preset":F25_GRAPHICS.selected(),"features":F25_GRAPHICS.values()},
		"scope":"three real ENet companions + one shared production wild; rank5 library process-only; initial endurance HP; normal input and AI; no fourth named F25 attack guaranteed"}
	if _f25_sample:
		var out := str(args.get("output_dir",""))
		if out.is_empty(): _f25_failures.append("missing output directory")
		else:
			DirAccess.make_dir_recursive_absolute(out)
			var report := FileAccess.open(out.path_join("results.json"),FileAccess.WRITE)
			if report == null: _f25_failures.append("cannot write evidence")
			else:
				report.store_string(JSON.stringify({"summary":_f25_summary,"wall_frame_seconds":_f25_frames,
					"launches":_f25_launches,"impacts":_f25_impacts,"census":_f25_census},"\t"))
				report.close()
			await RenderingServer.frame_post_draw
			if root.get_texture().get_image().save_png(out.path_join("native-after.png")) != OK:
				_f25_failures.append("native screenshot save failed")
	_f25_done = true
