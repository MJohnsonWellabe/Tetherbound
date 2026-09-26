extends "res://tests/smoke_stronghold_battle_camera.gd"

## X04 visual-verdict evidence for named Stronghold fights (F04: Warden,
## gauntlet captains). Reuses smoke_stronghold_battle_camera.gd's real path --
## Meadows playground, player stood in front of the trainer, challenge through
## the physical interact prompt and dialogue -- but takes the trainer id from
## the command line and, once the fight is live, saves production-camera
## frames at a fixed interval so the trainer's tells, recoveries and hits are
## in frame. The player does not steer; the ally's own AI and the opponent's
## AI fight. Evidence only: nothing is asserted and no state is saved.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script res://tools/art_pipeline/capture_named_fight.gd \
##     -- --trainer=warden_aldis --out=res://shots/x04/f04/warden [--frames=24] [--interval=0.5]

var _tid := ""
var _out := ""
var _frames := 24
var _interval := 0.5
var _container: Node = null

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--trainer="):
			_tid = arg.trim_prefix("--trainer=")
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--frames="):
			_frames = maxi(1, int(arg.trim_prefix("--frames=")))
		elif arg.begins_with("--interval="):
			_interval = maxf(0.1, float(arg.trim_prefix("--interval=")))
	if _tid.is_empty() or _out.is_empty() or DisplayServer.get_name() == "headless":
		push_error("needs --trainer=, --out= and a rendering display")
		quit(1)
		return
	_spec = TRAINERS.trainer(_tid)
	if _spec.is_empty():
		push_error("no trainer '%s'" % _tid)
		quit(1)
		return
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame
	await _ensure_ally()
	if not _collect_nodes():
		_report()
		return
	_stand_in_front_of_the_trainer()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s-00-before.png" % [_out, _tid])
	await _challenge()
	if not bool(_manager.call("is_fighting")):
		print("FIGHT DID NOT START vs %s" % _tid)
		quit(1)
		return
	print("fight live vs %s" % _tid)
	for i in _frames:
		var t := 0.0
		while t < _interval:
			await physics_frame
			t += 1.0 / Engine.physics_ticks_per_second
		await RenderingServer.frame_post_draw
		var path := "%s/%s-%02d.png" % [_out, _tid, i + 1]
		root.get_texture().get_image().save_png(path)
		print("frame %s fighting=%s" % [path, str(_manager.call("is_fighting"))])
		if not bool(_manager.call("is_fighting")):
			break
	for i in 90:
		await physics_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s-99-after.png" % [_out, _tid])
	quit(0)


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as SpringArm3D
	_camera = _rig.get_node_or_null(^"Camera3D") as Camera3D if _rig != null else null
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_panel = _world.get_node_or_null(^"DialoguePanel")
	if _player == null or _rig == null or _camera == null or _manager == null or _director == null or _panel == null:
		push_error("scene nodes missing")
		return false
	# Any trainer container in the world (StrongholdTrainers, WardenTrainer,
	# band trainer groups) answers body_for(id); the first that knows it wins.
	_trainer = null
	for node in _world.find_children("*", "", true, false):
		if node.has_method("body_for"):
			var body := node.call("body_for", _tid) as Node3D
			if body != null:
				_trainer = body
				_container = node
				print("trainer %s found under %s" % [_tid, _world.get_path_to(node)])
				break
	if _trainer == null:
		push_error("trainer '%s' not stood up anywhere in the world" % _tid)
		return false
	return true


## The base challenge loop, with wall-clock progress so a stalled open-world
## challenge (captains stand in the streamed Meadows, not the Stronghold) says
## where it stopped instead of timing out silently.
func _challenge() -> void:
	var t0 := Time.get_ticks_msec()
	for i in 60:
		await physics_frame
		if i % 10 == 0:
			print("challenge: settle frame %d at %d ms, paused=%s" % [i, Time.get_ticks_msec() - t0, str(paused)])
	print("challenge: settled in %d ms" % (Time.get_ticks_msec() - t0))
	var presses := 0
	for i in 900:
		if bool(_manager.call("is_fighting")):
			break
		if presses == 0 or bool(_panel.call("is_open")):
			await _press("interact")
			presses += 1
			print("challenge: press %d at %d ms, panel open=%s" % [presses, Time.get_ticks_msec() - t0, str(_panel.call("is_open"))])
			if presses == 1 and not bool(_panel.call("is_open")):
				_diagnose_and_activate()
			for n in 8:
				await physics_frame
			continue
		await physics_frame
		if i % 120 == 0:
			print("challenge: frame %d at %d ms, fighting=%s" % [i, Time.get_ticks_msec() - t0, str(_manager.call("is_fighting"))])
	print("challenge: %d presses, fighting=%s" % [presses, str(_manager.call("is_fighting"))])


## The press did not open the conversation. Say why (arbiter disabled, an
## input owner holding the screen, a different winning offer), then fire the
## arbiter's own activate() -- the same provider path a press takes -- so a
## slow software-rendered frame cannot cost a 19-minute capture.
func _diagnose_and_activate() -> void:
	var arbiter := get_first_node_in_group("interaction_arbiter")
	if arbiter == null:
		print("challenge: no interaction arbiter")
		return
	var owner: Variant = load("res://scripts/ui/input_owner.gd").call("current", self)
	var provider: Variant = arbiter.call("winning_provider")
	print("challenge: arbiter enabled=%s input_owner=%s winner=%s" % [
		str(arbiter.get("_enabled")), str(owner), str(provider)])
	print("challenge: winning offer %s" % str(arbiter.get("_winner")))
	print("challenge: activate() -> %s, panel open=%s" % [
		str(arbiter.call("activate")), str(_panel.call("is_open"))])
	if not bool(_panel.call("is_open")) and _container != null and _container.has_method("_on_challenged"):
		# The trainer container's own handler -- what its prompt's
		# interaction_activate() runs -- so the conversation and the fight
		# that follows are the production ones.
		_container.call("_on_challenged", _spec)
		print("challenge: trainer _on_challenged -> panel open=%s" % str(_panel.call("is_open")))
