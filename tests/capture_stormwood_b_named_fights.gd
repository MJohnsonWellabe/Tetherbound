extends SceneTree

## F10#2 footage evidence (ACCEPTANCE C3, framing/readability at actual scale)
## for the six Stormwood named WILDS of BOSSES §7: hollows_alpha,
## capacitor_alpha, crown_guardian, old_rodfolk_hall_guardian,
## blackwater_elder, glass_field_alpha. Captain Marrow/Dynamo is out of scope.
##
## Real path: the production Game autoload, production scenes/world/
## stormwood.tscn with its own Player, CameraRig, HUD, EncounterDirector and
## CombatManager. Each named wild is engaged through the ordinary Engage offer
## (the interaction arbiter's winning provider must be the director and its
## candidate must be the exact named body; the press is a physical joypad
## `interact` edge). The fight then runs on production AI; this tool steers
## the ally with the ordinary move stick and `combat_quick` taps (no dodge
## verb exists: avoidance is leaving the lane with the stick) so both a hit
## and an avoidance can appear. Frames are saved from the production camera at
## a fixed game-time interval AND at exact enemy state moments: tell start
## (`telegraph_started`), mid-tell, strike (`lunge_started` / `strike_ready`)
## and recovery.
##
## Run with --fixed-fps so every rendered frame advances the same game time
## (process and physics stay in lockstep under slow software GL):
##
##   XDG_DATA_HOME=$(mktemp -d) xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 20 \
##     --script res://tests/capture_stormwood_b_named_fights.gd \
##     -- --out=/abs/dir [--ids=hollows_alpha,...] [--seconds=18] [--interval=1.0]
##
## DISCLOSED FIXTURES (evidence only; nothing is saved):
##   - Party: five level-42 creatures (Five-creature cap respected).
##   - Debug placement: the player is teleported beside each named wild's live
##     body (4.5 m, on the side away from its nearest neighbour).
##   - Other wild bodies within 25 m of the named body are hidden and stopped
##     so the Engage offer's nearest-body rule names the named wild and an
##     escort cannot pre-empt it.
##   - The Stormwood storm clock is pinned inside Calm every frame so
##     lightning/Break presentation does not confound the fight frames.
##   - The ally is healed between fights; a fight still running at the time cap
##     is ended through combat_manager's own resolve("fled") so the next one
##     can start.
##   - Gated regions (Crown island, Deepwood) are reached by placement, not by
##     their gates; the gate path is F09/F11's evidence, not this one.

const GAME := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const OCCLUSION := preload("res://scripts/combat/ally_occlusion_fade.gd")
const TEST_SAVE_DIR := "user://f10_2_named_footage"
const ALL_IDS := ["hollows_alpha", "capacitor_alpha", "crown_guardian",
	"old_rodfolk_hall_guardian", "blackwater_elder", "glass_field_alpha"]
const PARTY := ["sparkit", "mudsnout", "bramblebun", "terrapup", "brooktail"]
const PARTY_LEVEL := 42

var _out := ""
var _ids: Array = ALL_IDS.duplicate()
var _seconds := 18.0
var _interval := 1.0
var _game: Node
var _world: Node3D
var _player: CharacterBody3D
var _rig: Node3D
var _manager: Node
var _director: Node
var _arbiter: Node
var _id := ""
var _named: Node3D
var _hidden: Array[Node3D] = []
var _log: Array[String] = []

# Game-time clock: physics frames seen since the fight began.
var _phys := 0
var _fight_phys0 := 0
# Pending state-moment captures: {tag, at_phys}
var _pending: Array[Dictionary] = []
var _tell_index := 0
var _tell_open := {}
var _tells: Array[Dictionary] = []
var _hits: Array[String] = []
var _dodge_until := -1
var _dodge_dir := Vector3.ZERO


func _initialize() -> void:
	_run.call_deferred()


func _t() -> float:
	return float(_phys - _fight_phys0) / float(Engine.physics_ticks_per_second)


func _note(line: String) -> void:
	_log.append(line)
	print("F10_2 ", line)


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--ids="):
			_ids = Array(arg.trim_prefix("--ids=").split(",", false))
		elif arg.begins_with("--seconds="):
			_seconds = float(arg.trim_prefix("--seconds="))
		elif arg.begins_with("--interval="):
			_interval = float(arg.trim_prefix("--interval="))
	if _out.is_empty() or DisplayServer.get_name() == "headless":
		push_error("needs --out= and a rendering display")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_out)
	physics_frame.connect(func() -> void: _phys += 1)
	var t0 := Time.get_ticks_msec()
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_game = GAME.new()
		_game.name = "Game"
		root.add_child(_game)
	await process_frame
	_game.call("reset_for_new_game")
	_game.set("save_system", SAVE_GAME.new(TEST_SAVE_DIR))
	_game.get("local").set("character_id", "f10-2-footage")
	_game.get("world").set("world_id", "f10-2-footage-world")
	_game.set("current_realm", "stormwood")
	_game.call("bind_realm_map")
	for species_id: String in PARTY:
		var creature: RefCounted = SPECIES.spawn(species_id)
		creature.call("set_level", PARTY_LEVEL, PROGRESSION.config())
		_game.get("party").call("add", creature)
	_pin_calm()
	_world = (load("res://scenes/world/stormwood.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	while not bool(_world.call("shell_build_complete")):
		_pin_calm()
		await process_frame
	_note("world built in %d ms" % (Time.get_ticks_msec() - t0))
	_player = _world.get_node(^"Player") as CharacterBody3D
	_rig = _world.get_node(^"CameraRig") as Node3D
	_manager = _world.get_node(^"CombatManager")
	_director = _world.get_node(^"EncounterDirector")
	_arbiter = get_first_node_in_group(&"interaction_arbiter")
	for i in 600:
		_pin_calm()
		if bool(_director.get("population_ready")):
			break
		await process_frame
	_note("population_ready=%s wild=%d arbiter=%s" % [str(_director.get("population_ready")),
		(_director.call("wild_creatures") as Array).size(), str(_arbiter)])
	_manager.connect("hit_landed", _on_hit)
	_manager.connect("attack_missed", _on_miss)
	var summary: Array[Dictionary] = []
	for id: String in _ids:
		_id = id
		var row := await _capture(id)
		summary.append(row)
		_note("SUMMARY %s" % JSON.stringify(row))
	var file := FileAccess.open(_out.path_join("capture_log.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"summary": summary, "log": _log}, "\t"))
		file.close()
	_note("done in %d ms" % (Time.get_ticks_msec() - t0))
	quit(0)


func _pin_calm() -> void:
	if _game == null:
		return
	var env: Dictionary = _game.get("realm_environment")
	var storm: Variant = env.get("stormwood", {})
	var row: Dictionary = storm.duplicate(true) if storm is Dictionary else {}
	row["elapsed"] = 5.0
	row["schema_version"] = 1
	env["stormwood"] = row
	_game.set("realm_environment", env)


func _named_body(id: String) -> Node3D:
	for body: Node3D in (_director.call("wild_creatures") as Array):
		if is_instance_valid(body) and str(body.get_meta("stormwood_named_encounter", "")) == id:
			return body
	return null


func _save(tag: String) -> void:
	await RenderingServer.frame_post_draw
	var path := _out.path_join("%s-%s.png" % [_id, tag])
	root.get_texture().get_image().save_png(path)
	var enemy := _manager.call("enemy_body") as Node3D if bool(_manager.call("is_fighting")) else null
	var ally := _director.call("ally_body") as Node3D
	var cam := _rig.get_node_or_null(^"Camera3D") as Camera3D
	var sep := -1.0
	if enemy != null and ally != null:
		sep = enemy.global_position.distance_to(ally.global_position)
	var enemy_on := false
	if cam != null and enemy != null:
		enemy_on = not cam.is_position_behind(enemy.global_position) and \
			Rect2(Vector2.ZERO, Vector2(root.size)).has_point(cam.unproject_position(enemy.global_position + Vector3.UP))
	_note("frame %s t=%.2f fighting=%s sep=%.2f enemy_on_screen=%s intent=%s" % [
		path.get_file(), _t(), str(_manager.call("is_fighting")), sep, str(enemy_on),
		str(enemy.get("_intent")) if enemy != null else "-"])
	if cam != null and enemy != null and ally != null:
		_note_camera(cam, enemy, ally)
		if tag.begins_with("tell"):
			_note_aim(tag)


## Camera state beside each saved frame, and how many of the ally's three
## sample heights the foe's inscribed render ellipsoid hides from the lens.
func _note_camera(cam: Camera3D, enemy: Node3D, ally: Node3D) -> void:
	var foe_model := enemy.call("model_pivot") as Node3D if enemy.has_method("model_pivot") else null
	var ally_model := ally.call("model_pivot") as Node3D if ally.has_method("model_pivot") else null
	var hides := -1
	if foe_model != null and ally_model != null:
		var foe_bounds: AABB = RENDER_BOUNDS.measure(foe_model)
		var ally_world: AABB = ally_model.global_transform * RENDER_BOUNDS.measure(ally_model)
		var base := Vector3(ally.global_position.x, ally_world.position.y, ally.global_position.z)
		hides = OCCLUSION.hidden_points(cam.global_position, base, ally_world.size.y,
			foe_model.global_transform, foe_bounds)
	var to_foe := enemy.global_position - ally.global_position
	if foe_model != null:
		var fb: AABB = foe_model.global_transform * RENDER_BOUNDS.measure(foe_model)
		var flat := Vector3(fb.get_center().x, 0.0, fb.get_center().z) - Vector3(enemy.global_position.x, 0.0, enemy.global_position.z)
		_note("  foe radius=%.2f render_half=(%.2f, %.2f, %.2f) render_centre_off=%.2f ally_radius=%.2f flat_sep=%.2f" % [
			float(enemy.call("body_radius")), fb.size.x * 0.5, fb.size.y * 0.5, fb.size.z * 0.5, flat.length(),
			float(ally.call("body_radius")) if ally.has_method("body_radius") else -1.0,
			Vector2(to_foe.x, to_foe.z).length()])
	var axis := rad_to_deg(atan2(-to_foe.x, -to_foe.z))
	_note("  cam yaw=%.0f axis=%.0f comp_extra=%.0f clear_extra=%.0f shoulder=%.2f arm=%.2f foe_hides_ally=%d ally_px=%s" % [
		rad_to_deg(float(_rig.get("yaw"))), axis, float(_rig.call("composition_extra")),
		float(_rig.call("clearance_extra")), float(_rig.get("_shoulder")),
		float(_rig.get("spring_length")), hides, str(cam.unproject_position(ally.global_position + Vector3.UP * 0.5).round())])


func _on_telegraph(seconds: float) -> void:
	_tell_index += 1
	var n := _tell_index
	var ticks := Engine.physics_ticks_per_second
	_tell_open = {"n": n, "seconds": seconds, "start_phys": _phys}
	_note("TELL %d start t=%.2f authored_beat=%.2f" % [n, _t(), seconds])
	# Every third tell stands still (hit); the others sidestep out of the lane
	# at 25% of the tell, backing off and to one side (avoidance). Only the first four tells get frames.
	if n % 3 != 1:
		_dodge_until = _phys + int(seconds * ticks) + int(0.5 * ticks)
		_dodge_dir = Vector3.ZERO
	if n <= 4:
		_pending.append({"tag": "tell%d-a-start" % n, "at": _phys})
		_pending.append({"tag": "tell%d-b-mid" % n, "at": _phys + int(seconds * 0.5 * ticks)})
		_pending.append({"tag": "tell%d-c-late" % n, "at": _phys + int(seconds * 0.85 * ticks)})


func _on_strike_begin(kind: String) -> void:
	if _tell_open.is_empty():
		return
	var n := int(_tell_open.n)
	var measured := float(_phys - int(_tell_open.start_phys)) / float(Engine.physics_ticks_per_second)
	_tells.append({"n": n, "authored": _tell_open.seconds, "measured_tell_s": snappedf(measured, 0.001), "kind": kind})
	_note("TELL %d %s at t=%.2f measured_tell=%.3f s" % [n, kind, _t(), measured])
	_tell_open = {}
	if n <= 4:
		var ticks := Engine.physics_ticks_per_second
		_pending.append({"tag": "tell%d-d-strike" % n, "at": _phys})
		_pending.append({"tag": "tell%d-e-impact" % n, "at": _phys + int(0.2 * ticks)})
		_pending.append({"tag": "tell%d-f-recovery" % n, "at": _phys + int(0.55 * ticks)})


func _on_hit(on_enemy: bool, amount: float) -> void:
	_hits.append("%s t=%.2f %s %.1f" % [_id, _t(), "ally->enemy" if on_enemy else "enemy->ally", amount])
	_note("HIT %s t=%.2f amount=%.1f" % ["ally->enemy" if on_enemy else "enemy->ally", _t(), amount])
	if not on_enemy:
		_note_aim("at hit")


## The foe's strike geometry: its facing against the bearing to the ally, the
## reach/arc the hit test reads, and where its drawn guard cone points.
func _note_aim(when: String) -> void:
	var enemy := _manager.call("enemy_body") as Node3D if bool(_manager.call("is_fighting")) else null
	var ally := _director.call("ally_body") as Node3D
	if enemy == null or ally == null or not enemy.has_method("facing"):
		return
	var facing: Vector3 = enemy.call("facing")
	var to_ally := ally.global_position - enemy.global_position
	to_ally.y = 0.0
	var cfg: Dictionary = enemy.call("combat_config") if enemy.has_method("combat_config") else {}
	var cone := enemy.get_node_or_null(^"GuardCone") as Node3D
	var cone_off := "none"
	if cone != null:
		var z := cone.global_transform.basis.z
		z.y = 0.0
		cone_off = "%.0f reach=%.2f arc=%.0f" % [rad_to_deg(facing.signed_angle_to(z.normalized(), Vector3.UP)),
			float(cone.get_meta("reach", 0.0)), float(cone.get_meta("cone_degrees", 0.0))]
	var model := enemy.call("model_pivot") as Node3D if enemy.has_method("model_pivot") else null
	var model_off := "?"
	if model != null:
		var mz := model.global_transform.basis.z
		mz.y = 0.0
		model_off = "%.0f" % rad_to_deg(facing.signed_angle_to(mz.normalized(), Vector3.UP))
	_note("  AIM %s ally_bearing_off=%.0f dist=%.2f range=%.2f arc=%.0f move=%s cone_off=%s model_off=%s" % [when,
		rad_to_deg(facing.signed_angle_to(to_ally.normalized(), Vector3.UP)), to_ally.length(),
		float(cfg.get("range", -1.0)), float(cfg.get("cone_degrees", -1.0)), str(cfg.get("move_id", "")),
		cone_off, model_off])


func _on_miss(by_player: bool) -> void:
	_hits.append("%s t=%.2f %s miss" % [_id, _t(), "ally" if by_player else "enemy"])
	_note("MISS by %s t=%.2f" % ["ally" if by_player else "enemy", _t()])


func _tap(action: StringName) -> void:
	var binding: InputEvent = null
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			binding = event
			break
	if binding == null:
		Input.action_press(action)
		for i in 3:
			await physics_frame
		Input.action_release(action)
		return
	var press := InputEventJoypadButton.new()
	press.button_index = (binding as InputEventJoypadButton).button_index
	press.pressed = true
	Input.parse_input_event(press)
	for i in 2:
		await physics_frame
		await process_frame
	var release := press.duplicate() as InputEventJoypadButton
	release.pressed = false
	Input.parse_input_event(release)
	for i in 2:
		await physics_frame


func _stick(world_dir: Vector3) -> void:
	var x := 0.0
	var y := 0.0
	if world_dir.length() > 0.01:
		var local := (_rig.call("planar_basis") as Basis).inverse() * world_dir.normalized()
		x = local.x
		y = local.z
	_axis(&"move_right", x)
	_axis(&"move_left", -x)
	_axis(&"move_back", y)
	_axis(&"move_forward", -y)


func _axis(action: StringName, value: float) -> void:
	if value > 0.01:
		Input.action_press(action, clampf(value, 0.0, 1.0))
	else:
		Input.action_release(action)


func _ground_at(xz: Vector2, hint_y: float) -> Variant:
	var space := _player.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(Vector3(xz.x, hint_y + 60.0, xz.y),
		Vector3(xz.x, hint_y - 60.0, xz.y))
	query.exclude = [_player.get_rid()]
	var hit := space.intersect_ray(query)
	return null if hit.is_empty() else hit.position


func _capture(id: String) -> Dictionary:
	var row := {"id": id, "started": false, "tells": [], "hits": [], "frames": 0, "note": ""}
	_tell_index = 0
	_tells.clear()
	_hits.clear()
	_pending.clear()
	_tell_open = {}
	_dodge_until = -1
	for member: RefCounted in (_game.get("party").call("members") as Array):
		member.call("heal_fully")
	_named = _named_body(id)
	if _named == null:
		row.note = "named body not present in director.wild_creatures()"
		_note("NO BODY for %s" % id)
		return row
	var at := _named.global_position
	# Hide other wilds near it (disclosed fixture).
	for body in _hidden:
		if is_instance_valid(body):
			body.visible = true
			body.process_mode = Node.PROCESS_MODE_INHERIT
	_hidden.clear()
	var nearest := Vector3.ZERO
	var nearest_d := INF
	for body: Node3D in (_director.call("wild_creatures") as Array):
		if not is_instance_valid(body) or body == _named:
			continue
		var d := body.global_position.distance_to(at)
		if d < nearest_d:
			nearest_d = d
			nearest = body.global_position
		if d < 25.0:
			body.visible = false
			body.process_mode = Node.PROCESS_MODE_DISABLED
			_hidden.append(body)
	_note("%s body at %s, hid %d neighbours (nearest %.1f m)" % [id, str(at), _hidden.size(), nearest_d])
	# Stand 4.5 m from it, away from the nearest neighbour.
	var away := Vector3(at.x - nearest.x, 0.0, at.z - nearest.z)
	if away.length() < 0.1 or nearest_d == INF:
		away = Vector3(0, 0, 1)
	away = away.normalized()
	var stand := Vector2(at.x + away.x * 4.5, at.z + away.z * 4.5)
	var ground: Variant = null
	for i in 900:
		_pin_calm()
		_player.global_position = Vector3(stand.x, at.y + 2.0, stand.y)
		_player.velocity = Vector3.ZERO
		ground = _ground_at(stand, at.y)
		if ground != null:
			break
		await physics_frame
	if ground == null:
		row.note = "no ground collision at stand spot"
		return row
	_player.global_position = (ground as Vector3) + Vector3.UP * 0.2
	_player.velocity = Vector3.ZERO
	# Face the named wild with the production rig's yaw.
	var to := at - _player.global_position
	_rig.set("yaw", atan2(-to.x, -to.z))
	for i in 45:
		_pin_calm()
		await physics_frame
	if _director.call("ally_body") == null:
		await _tap(&"creature_recall")
		for i in 90:
			_pin_calm()
			if _director.call("ally_body") != null:
				break
			await physics_frame
	await _save("00-before")
	# Ordinary Engage: exact named body offered by the director as the
	# arbiter's actionable winner, one physical interact edge.
	var engaged_by := ""
	for attempt in 600:
		_pin_calm()
		if bool(_manager.call("is_fighting")):
			engaged_by = "aggressive named wild initiated" if engaged_by.is_empty() else engaged_by
			break
		var candidate := _director.call("_engageable") as Node3D
		var winner := _arbiter.call("winning_provider") as Node if _arbiter != null else null
		var offer: Dictionary = _arbiter.call("winner") if _arbiter != null else {}
		if candidate == _named and winner == _director and bool(offer.get("actionable", false)) \
				and INPUT_OWNER.current(self) == null and not paused:
			_note("%s Engage offer '%s' -> pressing interact" % [id, str(offer.get("label", ""))])
			engaged_by = "Engage press"
			await _tap(&"interact")
			for i in 30:
				if bool(_manager.call("is_fighting")):
					break
				await physics_frame
			if bool(_manager.call("is_fighting")):
				break
		if attempt % 120 == 0:
			_note("%s waiting: candidate=%s winner=%s offer=%s d=%.2f" % [id, str(candidate),
				str(winner), str(offer), _player.global_position.distance_to(_named.global_position) if is_instance_valid(_named) else -1.0])
			# Named bodies wander; re-stand beside it.
			if is_instance_valid(_named) and _player.global_position.distance_to(_named.global_position) > 5.5:
				var a := _named.global_position
				var g: Variant = _ground_at(Vector2(a.x + away.x * 4.0, a.z + away.z * 4.0), a.y)
				if g != null:
					_player.global_position = (g as Vector3) + Vector3.UP * 0.2
		await physics_frame
	if not bool(_manager.call("is_fighting")):
		row.note = "fight did not start (Engage never admitted it)"
		_note("FIGHT DID NOT START vs %s" % id)
		return row
	var enemy := _manager.call("enemy_body") as Node3D
	row.started = true
	row["engaged_by"] = engaged_by
	row["enemy_is_named"] = enemy == _named
	_note("%s fight live (%s) enemy=%s named=%s" % [id, engaged_by, str(enemy), str(enemy == _named)])
	enemy.connect("telegraph_started", _on_telegraph)
	var on_lunge := func(_h: Vector3, _d: float) -> void: _on_strike_begin("lunge_started")
	var on_strike := func() -> void: _on_strike_begin("strike_ready")
	enemy.connect("lunge_started", on_lunge)
	enemy.connect("strike_ready", on_strike)
	_fight_phys0 = _phys
	var next_interval := 0.0
	var frame_i := 0
	var next_quick := 0
	var quick_release := -1
	var ticks := Engine.physics_ticks_per_second
	while bool(_manager.call("is_fighting")) and _t() < _seconds:
		_pin_calm()
		var ally := _director.call("ally_body") as Node3D
		var foe := _manager.call("enemy_body") as Node3D
		if ally != null and foe != null:
			var offset := foe.global_position - ally.global_position
			offset.y = 0.0
			if _phys < _dodge_until and not _tell_open.is_empty() \
					and _phys - int(_tell_open.start_phys) >= int(float(_tell_open.seconds) * 0.25 * ticks):
				if _dodge_dir == Vector3.ZERO:
					# Leave the lane: back off and to one side (no dodge verb exists).
					var side := offset.normalized().cross(Vector3.UP)
					_dodge_dir = (-offset.normalized() + (side if _tell_index % 2 == 0 else -side)).normalized()
				_stick(_dodge_dir)
			elif _phys < _dodge_until and _tell_open.is_empty():
				_stick(_dodge_dir)
			elif offset.length() > float(_manager.call("combat_move_reach", "quick")) * 0.8:
				_stick(offset)
			else:
				_stick(Vector3.ZERO)
				if _phys >= next_quick and bool(_manager.call("quick_ready")):
					Input.action_press(&"combat_quick")
					quick_release = _phys + 2
					next_quick = _phys + int(0.9 * ticks)
		if quick_release >= 0 and _phys >= quick_release:
			Input.action_release(&"combat_quick")
			quick_release = -1
		var due: Array[Dictionary] = []
		for p: Dictionary in _pending:
			if _phys >= int(p.at):
				due.append(p)
		for p in due:
			_pending.erase(p)
		if not due.is_empty():
			await _save(str(due[0].tag))
			frame_i += 1
			continue
		if _t() >= next_interval:
			await _save("i%02d" % int(round(next_interval / _interval)))
			next_interval += _interval
			frame_i += 1
			continue
		await process_frame
	_stick(Vector3.ZERO)
	Input.action_release(&"combat_quick")
	row.tells = _tells.duplicate(true)
	row.hits = _hits.duplicate()
	row.frames = frame_i
	row["ended_at_s"] = snappedf(_t(), 0.01)
	row["fighting_at_end"] = bool(_manager.call("is_fighting"))
	if is_instance_valid(enemy):
		for pair in [["telegraph_started", Callable(self, "_on_telegraph")], ["lunge_started", on_lunge], ["strike_ready", on_strike]]:
			if enemy.is_connected(pair[0], pair[1]):
				enemy.disconnect(pair[0], pair[1])
	if bool(_manager.call("is_fighting")):
		_manager.call("_begin_resolve", "fled")
	for i in 240:
		_pin_calm()
		if not bool(_manager.call("is_fighting")):
			break
		await physics_frame
	await _save("99-after")
	for i in 60:
		await physics_frame
	return row
