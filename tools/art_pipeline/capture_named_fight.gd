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
##     -- --trainer=warden_aldis[,captain_field,...] --out=res://shots/x04/f04/warden \
##     [--frames=24] [--interval=0.5] [--resolve=won --after-frames=16]
##
## `--resolve=won` ends each fight through combat_manager's own resolve call
## after the in-fight frames and keeps saving (`-aNN`) through the defeat
## line and the world's aftermath: F04's "distinct aftermath" evidence.

var _tid := ""
var _out := ""
var _frames := 24
var _interval := 0.5
var _container: Node = null
var _resolve_won := false
var _after_frames := 16

func _run() -> void:
	var ids: PackedStringArray = []
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--trainer="):
			ids = arg.trim_prefix("--trainer=").split(",", false)
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--frames="):
			_frames = maxi(1, int(arg.trim_prefix("--frames=")))
		elif arg.begins_with("--interval="):
			_interval = maxf(0.1, float(arg.trim_prefix("--interval=")))
		elif arg == "--resolve=won":
			_resolve_won = true
		elif arg.begins_with("--after-frames="):
			_after_frames = maxi(1, int(arg.trim_prefix("--after-frames=")))
	if ids.is_empty() or _out.is_empty() or DisplayServer.get_name() == "headless":
		push_error("needs --trainer=, --out= and a rendering display")
		quit(1)
		return
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame
	await _ensure_ally()
	var failures := 0
	# Several trainers share one world load: the open-world boot is ~15 min
	# under software GL, the fights themselves under two.
	for id in ids:
		_tid = id
		_spec = TRAINERS.trainer(_tid)
		if _spec.is_empty():
			push_error("no trainer '%s'" % _tid)
			failures += 1
			continue
		if not await _capture_one():
			failures += 1
	quit(1 if failures > 0 else 0)


func _save(tag: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "%s/%s-%s.png" % [_out, _tid, tag]
	root.get_texture().get_image().save_png(path)
	print("frame %s fighting=%s panel=%s" % [path, str(_manager.call("is_fighting")),
		str(_panel.call("is_open"))])


func _wait_interval() -> void:
	var t := 0.0
	while t < _interval:
		await physics_frame
		t += 1.0 / Engine.physics_ticks_per_second


func _capture_one() -> bool:
	if not _collect_nodes():
		return false
	# A previous capture in this run may have left the ally hurt or fainted,
	# which would turn the next challenge into the "no usable creature" line.
	var ally: Variant = _director.call("ally_instance")
	if ally != null:
		ally.call("heal_fully")
	_stand_in_front_of_the_trainer()
	if not await _settle_on_ground():
		return false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	for i in 30:
		await physics_frame
	if _player.global_position.y < _trainer.global_position.y - 3.0:
		print("PLAYER FELL at %s vs %s" % [str(_player.global_position), _tid])
		return false
	await _save("00-before")
	await _challenge()
	if not bool(_manager.call("is_fighting")):
		print("FIGHT DID NOT START vs %s" % _tid)
		return false
	print("fight live vs %s" % _tid)
	for i in _frames:
		await _wait_interval()
		await _save("%02d" % (i + 1))
		if not bool(_manager.call("is_fighting")):
			break
	if _resolve_won and bool(_manager.call("is_fighting")):
		# Evidence for the AFTERMATH, not the fight: the capture cannot pilot
		# a level-3 starter through a captain, so the fight is resolved as won
		# through the same call smoke_stronghold_battle_camera.gd uses, and
		# everything after it -- defeat line, reward, world change -- is the
		# production path.
		# `_begin_resolve("won")` settles the CURRENT enemy; a trainer then
		# sends out the next one, and `is_fighting()` reads false for the
		# moment between them. So the loop ends on the trainer's own
		# defeat flag -- the thing the aftermath hangs off -- not on the gap.
		var progression: RefCounted = _container.call("_progression") if _container != null else null
		var k := 0
		while k < 160 and not TRAINERS.already_beaten(_spec, progression):
			if bool(_manager.call("is_fighting")):
				_manager.call("_begin_resolve", "won")
			await _wait_interval()
			if k % 2 == 0:
				await _save("r%02d" % (k / 2 + 1))
			k += 1
		print("resolved %s after %d steps: beaten=%s fighting=%s" % [_tid, k,
			str(TRAINERS.already_beaten(_spec, progression)), str(_manager.call("is_fighting"))])
		for i in _after_frames:
			await _wait_interval()
			await _save("a%02d" % (i + 1))
			if bool(_panel.call("is_open")) and i % 3 == 2:
				await _press("interact")
		for i in 40:
			if not bool(_panel.call("is_open")):
				break
			await _press("interact")
			for n in 8:
				await physics_frame
	for i in 90:
		await physics_frame
	await _save("99-after")
	return true


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


## A far trainer's terrain collision streams in after the teleport; a player
## dropped there first falls through and `world_perimeter_corridor` returns
## them to spawn -- the fight then runs somewhere the camera is not. Wait for
## a downward ray at the stand spot to hit, and stand on what it hit.
func _settle_on_ground() -> bool:
	var spot := _player.global_position
	var space := _player.get_world_3d().direct_space_state
	for i in 1800:
		_player.global_position = spot + Vector3.UP * 0.5
		_player.velocity = Vector3.ZERO
		var query := PhysicsRayQueryParameters3D.create(spot + Vector3.UP * 40.0,
			spot + Vector3.DOWN * 40.0)
		query.exclude = [_player.get_rid()]
		var hit := space.intersect_ray(query)
		if not hit.is_empty():
			_player.global_position = (hit.position as Vector3) + Vector3.UP * 0.2
			_player.velocity = Vector3.ZERO
			print("ground under %s after %d frames at y=%.2f (trainer y=%.2f)" % [
				_tid, i, (hit.position as Vector3).y, _trainer.global_position.y])
			return true
		await physics_frame
	print("NO GROUND under the stand spot for %s" % _tid)
	return false
