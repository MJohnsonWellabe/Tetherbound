extends SceneTree

## F14#1 evidence: production-camera frames of the Veilfall named fights (BOSSES
## §4.10 Officer Venn, §4.11 Captain Nerissa -- the owner's "Guardian C2/C3"
## fight) for a code-blind C3 framing/readability judge. Evidence only: nothing
## is asserted and no state is saved.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script res://tests/capture_tidewake_named_fights.gd \
##     -- --trainer=water_trainer_venn[,water_trainer_nerissa] --out=res://shots/tidewake/f14_c3 \
##     [--interval=1.0] [--max-frames=40] [--level=53] [--pilot=QUICK|READER|MASHER] [--cap-s=240]
##
## Path: the actual Water world (water_archipelago.tscn); a legal five-member
## party of the original five at the given level (Ripplet lead); the player
## stood in front of the trainer; the production summon; the challenge through
## the real prompt. The camera is the production CameraRig; the HUD is live.
## Frames: one every --interval seconds of the fight, plus TELL frames synced
## to the opponent's own telegraph (its first frame and the frame before the
## strike), so the tell and the response space around it are both on record.
## A frames.json beside the images logs each frame's fight time, opponent,
## tell length and the ally/opponent gap.
## --pilot=READER drives the fight with the shared READER policy (the in-world
## C2 smoke's pilot), so a capture reaches the whole roster, including
## Nerissa's final Riptusk and its heavy tell. QUICK (the default) is the
## captain smoke's close-and-tap loop.
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const SMOKE := preload("res://tests/smoke_tidewake_named_inworld_c2.gd")
const PARTY := ["ripplet", "bramblebun", "mudsnout", "pipwing", "trailpup"]
## Nerissa stands in the Heart Chamber; these upstream pump flags let the
## interior body stand up, exactly as smoke_water_veilfall_captain.gd prepares.
const INTERIOR_FLAGS := ["water_veilfall_intake_stopped", "water_veilfall_return_opened"]
var _fight_cap_s := 240.0
const TELL_START_LAG_S := 0.1
var _policy := "QUICK"
## Disclosed world-flag fixture for a trainer's own `requires_flags` gate
## (e.g. Calder needs `water_dock_salt_crown_landing_charted`).
var _extra_flags: PackedStringArray = []
var _reader: RefCounted
## --render-only-saves: the render loop is off during the fight and turned on
## only for the few frames around each saved image. llvmpipe drawing every
## physics tick at 1080p ran ~200x slower than the fight clock; the fight
## itself (physics, AI, pilot, camera _process) is unchanged.
var _sparse := false
## --wild=aquaryn,tidecoil: F14#0's named wilds. Aquaryn is engaged through
## WaterAlpha.request_engage() (smoke_water_alpha_runtime.gd); Tidecoil by the
## ordinary interact prompt beside its Deep Watch reef shore, the stand
## tidewake_b_tidecoil_fight.gd walks to. Fixture (disclosed): placement.
var _wilds: PackedStringArray = []
## --hits-per-opponent=N: also save a frame HIT_LAG_S after a landed hit (each
## way), so impact VFX and hit reactions are on record, not only wind-ups.
var _hits_per_opponent := 2
const HIT_LAG_S := 0.08
var _hit_at := -1.0
const TIDECOIL_SHORE := Vector3(1465.6, 0.0, 3437.4)
const SPARSE_WARM_FRAMES := 3

var _out := ""
var _interval := 1.0
var _max_frames := 40
var _level := 53
## Tell pairs (start + late) saved per opponent, so the frame budget spans the
## whole roster instead of the first opponent's opening seconds.
var _tells_per_opponent := 2
var _log: Array = []
## Members, not locals: a GDScript lambda captures locals by value, so the
## telegraph signal writes these for the capture loop to read.
var _tell: Dictionary = {}
var _fight_t := 0.0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var ids: PackedStringArray = []
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--trainer="): ids = arg.trim_prefix("--trainer=").split(",", false)
		elif arg.begins_with("--out="): _out = arg.trim_prefix("--out=")
		elif arg.begins_with("--interval="): _interval = maxf(0.2, float(arg.trim_prefix("--interval=")))
		elif arg.begins_with("--max-frames="): _max_frames = maxi(4, int(arg.trim_prefix("--max-frames=")))
		elif arg.begins_with("--level="): _level = int(arg.trim_prefix("--level="))
		elif arg.begins_with("--tells-per-opponent="): _tells_per_opponent = maxi(0, int(arg.trim_prefix("--tells-per-opponent=")))
		elif arg.begins_with("--pilot="): _policy = arg.trim_prefix("--pilot=").to_upper()
		elif arg.begins_with("--cap-s="): _fight_cap_s = maxf(30.0, float(arg.trim_prefix("--cap-s=")))
		elif arg.begins_with("--flags="): _extra_flags = arg.trim_prefix("--flags=").split(",", false)
		elif arg == "--render-only-saves": _sparse = true
		elif arg.begins_with("--hits-per-opponent="): _hits_per_opponent = maxi(0, int(arg.trim_prefix("--hits-per-opponent=")))
		elif arg.begins_with("--wild="): _wilds = arg.trim_prefix("--wild=").split(",", false)
	if (ids.is_empty() and _wilds.is_empty()) or _out.is_empty() or DisplayServer.get_name() == "headless":
		push_error("needs --trainer=, --out= and a rendering display")
		quit(1)
		return
	await process_frame
	var game := root.get_node("Game")
	game.current_realm = "water"
	game.local.character_id = "tidewake-c3-capture"
	game.world.world_id = "tidewake-c3-capture-world"
	game.save_system = SAVE.new("user://tidewake_c3_capture_%d/" % Time.get_ticks_usec())
	for id: String in PARTY:
		var creature: RefCounted = SPECIES.spawn(id)
		creature.set_level(_level, PROGRESSION.config())
		game.local.party.add(creature)
	for flag: String in INTERIOR_FLAGS:
		game.world.flags.set_flag(flag)
	for flag: String in _extra_flags:
		game.world.flags.set_flag(flag)
		print("TIDEWAKE C3 CAPTURE fixture flag: " + flag)
	var world: Node3D = load("res://scenes/world/water_archipelago.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	var deadline := Time.get_ticks_msec() + 1800000
	while not world.shell_build_complete() and Time.get_ticks_msec() < deadline:
		await process_frame
	if not world.shell_build_complete():
		push_error("Water world did not finish building")
		quit(1)
		return
	var failures := 0
	for id: String in ids:
		if not await _capture(world, game, id):
			failures += 1
	for wild: String in _wilds:
		if not await _capture_wild(world, game, wild):
			failures += 1
	var file := FileAccess.open(_out.path_join("frames.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_log, "  "))
	print("TIDEWAKE C3 CAPTURE done: %d trainer(s), %d failure(s), %d frames" % [ids.size(), failures, _log.size()])
	quit(1 if failures else 0)


func _capture(world: Node3D, game: Node, id: String) -> bool:
	var director: Node = world.get_node("EncounterDirector")
	var manager: Node = world.get_node("CombatManager")
	var player: Node3D = world.local_rig()
	# Water trainers stand up only inside a peer's activation range
	# (water_combat.json activation_distance_m), so go to the authored spot first.
	var spec: Dictionary = director.trainer_specs.get(id, {})
	if spec.has("position"):
		var at: Array = spec.position
		var near := Vector3(float(at[0]), 0.0, float(at[2]) + 6.0)
		near.y = float(world.ground_height_at(near.x, near.z)) + 0.3
		player.global_position = near
		player.velocity = Vector3.ZERO
	var deadline := Time.get_ticks_msec() + 60000
	while not director.trainer_nodes.has(id) and Time.get_ticks_msec() < deadline:
		await process_frame
	var trainer: Node3D = director.trainer_nodes.get(id)
	if trainer == null:
		push_error("trainer %s not stood up" % id)
		return false
	# In front of the trainer, facing it, as the captain smoke stands.
	player.global_position = trainer.global_position + trainer.global_basis.z * 2.7 + Vector3(0, 0.1, 0)
	player.velocity = Vector3.ZERO
	await _frames(20)
	if not await director.summon_active_creature():
		push_error("summon failed before %s" % id)
		return false
	await _frames(12)
	var prompt: Node3D = director.trainer_prompts.get(id)
	if prompt == null or prompt.interaction_offer(player.global_position).is_empty():
		player.global_position = trainer.global_position + Vector3(0, 0.1, -2.7)
		await _frames(12)
	if prompt == null or prompt.interaction_offer(player.global_position).is_empty():
		push_error("no challenge prompt in reach for %s" % id)
		return false
	prompt.interaction_activate()
	await _frames(3)
	var dialogue: Node = world.get_node_or_null("DialoguePanel")
	for step in 30:
		if manager.is_fighting() or dialogue == null or not dialogue.is_open():
			break
		dialogue.advance()
		await _frames(3)
	if not (director.trainer_battle_id() == id and manager.is_fighting()):
		push_error("challenge did not start the %s fight" % id)
		return false
	var dir := _out.path_join(id.trim_prefix("water_trainer_"))
	return await _record(world, game, dir, id, director.trainer_battle_active)


## The fight loop shared by trainers and named wilds: periodic and tell frames
## while `active` holds, piloted by the chosen policy.
func _record(world: Node3D, game: Node, dir: String, label: String, active: Callable) -> bool:
	var director: Node = world.get_node("EncounterDirector")
	var manager: Node = world.get_node("CombatManager")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var saved := 0
	_fight_t = 0.0
	_tell = {}
	var next_periodic := 0.0
	var tick := 0
	var watched: Dictionary = {}
	_reader = null
	if _policy != "QUICK":
		_reader = SMOKE.WorldPilot.new()
		_reader.rig = world.get_node("CameraRig")
		_reader._tally = {"hits": 0, "incoming_hits": 0, "misses": 0, "max_hit_frac": 0.0, "events": [],
			"player_windup_cancellations": 0, "charged_interrupts": 0, "stagger_events": 0,
			"burst_uses": 0, "charged_uses": 0, "quick_uses": 0}
		for index in game.local.party.size():
			var member: RefCounted = game.local.party.at(index)
			_reader._entry_maxima[member.get_instance_id()] = float(member.max_hp)
		manager.hit_landed.connect(_reader._on_hit)
		manager.state_changed.connect(_reader._on_state_changed)
	var hits_seen: Dictionary = {}
	var on_hit := func(_on_enemy: bool, _amount: float) -> void:
		var foe: Node3D = manager.enemy_body()
		var key := foe.get_instance_id() if is_instance_valid(foe) else 0
		if int(hits_seen.get(key, 0)) < _hits_per_opponent and _hit_at < 0.0:
			hits_seen[key] = int(hits_seen.get(key, 0)) + 1
			_hit_at = _fight_t + HIT_LAG_S
	manager.hit_landed.connect(on_hit)
	_hit_at = -1.0
	if _sparse:
		RenderingServer.render_loop_enabled = false
	while bool(active.call()) and _fight_t < _fight_cap_s and saved < _max_frames:
		var enemy: Node3D = manager.enemy_body()
		var ally: Node3D = director.ally_body()
		if is_instance_valid(enemy) and not watched.has(enemy.get_instance_id()):
			watched[enemy.get_instance_id()] = 0
			var uid := enemy.get_instance_id()
			enemy.telegraph_started.connect(func(seconds: float) -> void:
				if int(watched.get(uid, 0)) >= _tells_per_opponent:
					return
				watched[uid] = int(watched.get(uid, 0)) + 1
				_tell = {"start": _fight_t, "seconds": seconds, "late_saved": false, "start_saved": false})
		# Tell frames: early in the tell and the frame before it lands. The
		# early frame waits TELL_START_LAG_S: the viewport image is the frame
		# already rendered, and the HUD cue and ground ring appear on the next
		# process frame after the telegraph signal, so a same-tick grab shows
		# the pre-tell frame (the first code-blind judge read that as "no cue").
		if not _tell.is_empty():
			if not bool(_tell.start_saved) and _fight_t >= float(_tell.start) + TELL_START_LAG_S:
				_tell.start_saved = true
				saved += await _save(dir, "tell-start", _fight_t, enemy, ally, _tell)
			elif not bool(_tell.late_saved) and (_fight_t >= float(_tell.start) + float(_tell.seconds) - 0.1
					or not _winding_up(enemy)):
				# Only a tell still winding up is a "tell-late" frame. A READER
				# pilot often interrupts the wind-up (STAGGERED) or the blow has
				# resolved: that frame is kept, honestly tagged "tell-ended".
				_tell.late_saved = true
				saved += await _save(dir, "tell-late" if _winding_up(enemy) else "tell-ended", _fight_t, enemy, ally, _tell)
				_tell = {}
		if _hit_at >= 0.0 and _fight_t >= _hit_at:
			_hit_at = -1.0
			saved += await _save(dir, "hit", _fight_t, enemy, ally, {})
		if _fight_t >= next_periodic:
			next_periodic += _interval
			saved += await _save(dir, "t", _fight_t, enemy, ally, {})
		# A save waits for a render, and the opponent can be swapped out (and
		# freed) meanwhile: re-read both bodies before piloting.
		enemy = manager.enemy_body()
		ally = director.ally_body()
		if not (is_instance_valid(enemy) and is_instance_valid(ally)):
			enemy = null
			ally = null
		if _reader != null:
			_reader.bind(manager, ally as CharacterBody3D, enemy as CharacterBody3D)
			if manager.is_fighting() and enemy != null:
				_reader.step(_policy)
		else:
			_pilot(world, manager, enemy, ally, tick)
		tick += 1
		await physics_frame
		_fight_t += 1.0 / Engine.physics_ticks_per_second
	RenderingServer.render_loop_enabled = true
	manager.hit_landed.disconnect(on_hit)
	_release()
	if _reader != null:
		_reader._release_attack()
		_reader._release_move()
	print("TIDEWAKE C3 CAPTURE %s: %d frames over %.1f s, fight active=%s" % [label, saved, _fight_t,
		bool(active.call())])
	if bool(active.call()):
		manager.call("_begin_resolve", "fled")
		await _frames(30)
	return saved > 0


## Grabs a frame rendered AFTER the requested moment. The viewport texture is
## the last completed render, and under software GL one rendered frame can
## span several physics ticks, so a same-tick grab can show a frame from
## before the telegraph began (both F14 judges read "no cue at tell start").
func _winding_up(enemy: Node3D) -> bool:
	return is_instance_valid(enemy) and enemy.has_method("is_winding_up") and bool(enemy.call("is_winding_up"))


func _save(dir: String, tag: String, t: float, enemy: Node3D, ally: Node3D, tell: Dictionary) -> int:
	if _sparse:
		RenderingServer.render_loop_enabled = true
		for i in SPARSE_WARM_FRAMES:
			await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var name := "%s-%06.2f.png" % [tag, t]
	var image := root.get_viewport().get_texture().get_image()
	if _sparse:
		RenderingServer.render_loop_enabled = false
	if image == null or image.save_png(dir.path_join(name)) != OK:
		return 0
	var gap := -1.0
	if is_instance_valid(enemy) and is_instance_valid(ally):
		gap = Vector2(enemy.global_position.x - ally.global_position.x,
			enemy.global_position.z - ally.global_position.z).length()
	_log.append({"file": dir.path_join(name), "tag": tag, "fight_s": snappedf(t, 0.01),
		"opponent": str(enemy.instance.species_id) if is_instance_valid(enemy) and enemy.get("instance") != null else "",
		"tell_s": float(tell.get("seconds", 0.0)), "gap_m": snappedf(gap, 0.01),
		"camera": _pose(root.get_viewport().get_camera_3d()), "ally": _pose(ally), "enemy": _pose(enemy)})
	return 1


## The captain smoke's plain pilot: close to quick range and tap quick. It is
## not a reader; the frames are for framing and readability, not C2.
func _pilot(world: Node3D, manager: Node, enemy: Node3D, ally: Node3D, tick: int) -> void:
	_release()
	if not (is_instance_valid(enemy) and is_instance_valid(ally) and manager.is_fighting()):
		return
	var offset: Vector3 = enemy.global_position - ally.global_position
	offset.y = 0
	if offset.length() > 2.3:
		var direction: Vector3 = world.get_node("CameraRig").planar_basis().inverse() * offset.normalized()
		if direction.x < 0: Input.action_press("move_left", -direction.x)
		else: Input.action_press("move_right", direction.x)
		if direction.z < 0: Input.action_press("move_forward", -direction.z)
		else: Input.action_press("move_back", direction.z)
	if tick % 24 == 0: Input.action_press("combat_quick")


func _release() -> void:
	for action: String in ["move_left", "move_right", "move_forward", "move_back", "combat_quick"]:
		Input.action_release(action)


func _frames(count: int) -> void:
	for frame in count:
		await physics_frame


## Position plus the world's ground height under it, so a frame whose camera
## is below or inside terrain is visible in frames.json without the image.
func _pose(node: Node3D) -> Array:
	if not is_instance_valid(node):
		return []
	var at := node.global_position
	var ground := float(current_scene.call("ground_height_at", at.x, at.z)) if current_scene != null and current_scene.has_method("ground_height_at") else NAN
	return [snappedf(at.x, 0.01), snappedf(at.y, 0.01), snappedf(at.z, 0.01), snappedf(ground, 0.01)]



func _capture_wild(world: Node3D, game: Node, wild: String) -> bool:
	var director: Node = world.get_node("EncounterDirector")
	var manager: Node = world.get_node("CombatManager")
	var player: Node3D = world.local_rig()
	var body: Node3D = null
	if wild == "aquaryn":
		var alpha: Node = world.get_node("WaterAlpha")
		body = alpha.get("body")
		player.global_position = body.global_position + Vector3(7, 0, 0)
		player.global_position.y = float(world.ground_height_at(player.global_position.x, player.global_position.z)) + 0.2
		await _frames(20)
		if not await director.summon_active_creature():
			push_error("summon failed before Aquaryn")
			return false
		await _frames(12)
		alpha.call("request_engage")
	elif wild == "tidecoil":
		# Two-strike rule (owner, 18:46): the walked approach failed twice in
		# this harness, so the disclosed shortcut is a placement on the first
		# dry ground (>1 m) between the body and the island centre, and the
		# director's own fight start once the lead is out.
		var shore := TIDECOIL_SHORE
		shore.y = float(world.ground_height_at(shore.x, shore.z)) + 0.2
		player.global_position = shore
		for _frame in 600:
			await physics_frame
			for candidate: Variant in director.get("_wild_creatures"):
				if is_instance_valid(candidate) and str((candidate as Node).get_meta("water_named_encounter", "")) == "water_deep_watch_tidecoil":
					body = candidate
			if body != null:
				break
		if body == null:
			push_error("named Tidecoil body never resident")
			return false
		var inland := Vector3(1350.0, 0.0, 3500.0) - body.global_position
		inland.y = 0.0
		inland = inland.normalized()
		var stand := body.global_position
		for step in 80:
			stand = body.global_position + inland * (4.0 + step)
			stand.y = float(world.ground_height_at(stand.x, stand.z))
			if stand.y > 1.0:
				break
		player.global_position = stand + Vector3.UP * 0.2
		player.velocity = Vector3.ZERO
		await _frames(30)
		if not await director.summon_active_creature():
			push_error("summon failed before Tidecoil at %s" % stand)
			return false
		await _frames(12)
		director.call("_start_fight", body)
	else:
		push_error("unknown --wild=%s" % wild)
		return false
	if not manager.is_fighting():
		push_error("the %s fight did not start" % wild)
		return false
	var dir := _out.path_join(wild)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	return await _record(world, game, dir, wild, manager.is_fighting)
