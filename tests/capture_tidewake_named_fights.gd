extends SceneTree

## F14#1 evidence: production-camera frames of the Veilfall named fights (BOSSES
## §4.10 Officer Venn, §4.11 Captain Nerissa -- the owner's "Guardian C2/C3"
## fight) for a code-blind C3 framing/readability judge. Evidence only: nothing
## is asserted and no state is saved.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script res://tests/capture_tidewake_named_fights.gd \
##     -- --trainer=water_trainer_venn[,water_trainer_nerissa] --out=res://shots/tidewake/f14_c3 \
##     [--interval=1.0] [--max-frames=40] [--level=53]
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
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const PARTY := ["ripplet", "bramblebun", "mudsnout", "pipwing", "trailpup"]
## Nerissa stands in the Heart Chamber; these upstream pump flags let the
## interior body stand up, exactly as smoke_water_veilfall_captain.gd prepares.
const INTERIOR_FLAGS := ["water_veilfall_intake_stopped", "water_veilfall_return_opened"]
const FIGHT_CAP_S := 240.0

var _out := ""
var _interval := 1.0
var _max_frames := 40
var _level := 53
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
	if ids.is_empty() or _out.is_empty() or DisplayServer.get_name() == "headless":
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
	var file := FileAccess.open(_out.path_join("frames.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_log, "  "))
	print("TIDEWAKE C3 CAPTURE done: %d trainer(s), %d failure(s), %d frames" % [ids.size(), failures, _log.size()])
	quit(1 if failures else 0)


func _capture(world: Node3D, game: Node, id: String) -> bool:
	var director: Node = world.get_node("EncounterDirector")
	var manager: Node = world.get_node("CombatManager")
	var player: Node3D = world.local_rig()
	var deadline := Time.get_ticks_msec() + 20000
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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var saved := 0
	_fight_t = 0.0
	_tell = {}
	var next_periodic := 0.0
	var tick := 0
	var watched: Dictionary = {}
	while director.trainer_battle_active() and _fight_t < FIGHT_CAP_S and saved < _max_frames:
		var enemy: Node3D = manager.enemy_body()
		var ally: Node3D = director.ally_body()
		if is_instance_valid(enemy) and not watched.has(enemy.get_instance_id()):
			watched[enemy.get_instance_id()] = true
			enemy.telegraph_started.connect(func(seconds: float) -> void:
				_tell = {"start": _fight_t, "seconds": seconds, "late_saved": false, "start_saved": false})
		# Tell frames: the first frame of the tell and the frame before it lands.
		if not _tell.is_empty():
			if not bool(_tell.start_saved):
				_tell.start_saved = true
				saved += _save(dir, "tell-start", _fight_t, enemy, ally, _tell)
			elif not bool(_tell.late_saved) and _fight_t >= float(_tell.start) + float(_tell.seconds) - 0.1:
				_tell.late_saved = true
				saved += _save(dir, "tell-late", _fight_t, enemy, ally, _tell)
				_tell = {}
		if _fight_t >= next_periodic:
			next_periodic += _interval
			saved += _save(dir, "t", _fight_t, enemy, ally, {})
		_pilot(world, manager, enemy, ally, tick)
		tick += 1
		await physics_frame
		_fight_t += 1.0 / Engine.physics_ticks_per_second
	_release()
	print("TIDEWAKE C3 CAPTURE %s: %d frames over %.1f s, fight active=%s" % [id, saved, _fight_t,
		director.trainer_battle_active()])
	if director.trainer_battle_active():
		manager.call("_begin_resolve", "fled")
		await _frames(30)
	return saved > 0


func _save(dir: String, tag: String, t: float, enemy: Node3D, ally: Node3D, tell: Dictionary) -> int:
	var name := "%s-%06.2f.png" % [tag, t]
	var image := root.get_viewport().get_texture().get_image()
	if image == null or image.save_png(dir.path_join(name)) != OK:
		return 0
	var gap := -1.0
	if is_instance_valid(enemy) and is_instance_valid(ally):
		gap = Vector2(enemy.global_position.x - ally.global_position.x,
			enemy.global_position.z - ally.global_position.z).length()
	_log.append({"file": dir.path_join(name), "tag": tag, "fight_s": snappedf(t, 0.01),
		"opponent": str(enemy.instance.species_id) if is_instance_valid(enemy) and enemy.get("instance") != null else "",
		"tell_s": float(tell.get("seconds", 0.0)), "gap_m": snappedf(gap, 0.01)})
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
