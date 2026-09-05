extends "res://tools/_capture_vfx_moments.gd"

## N07-VFX-POLISH (0905 follow-up). Photographs the two moments this lane
## retunes, through the REAL combat camera, inside a real fight, exactly the
## way `tools/_capture_vfx_moments.gd` does -- this file is that tool with two
## extra shots, not a second capture harness. Every helper (boot, engage,
## teleport, aim, shutter-under-pause, screenshot) is inherited unchanged.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_capture_vfx_polish_0905.gd \
##     [-- --only=telegraph,catch --out=res://shots/vfx_polish/before]
##
## SHOT LIST (each shot twice: `-hud.png`, `-clean.png`):
##   05-telegraph          the wild creature's wind-up ring (telegraph_glow.gd,
##                         combat.json `telegraph.colour`) a few ticks into
##                         the beat, from the side so both bodies are in frame
##   06-telegraph-behind   the same tick from the combat camera's own view
##                         behind the ally -- the framing W09's round-1 judge
##                         saw the ring "across the creature's chest" in
##   07-telegraph-control  the same side framing once the beat has ended and
##                         nothing is drawing: what the pixel probe subtracts
##   04a-catch-seal        the seal 3 ticks in: catching.json `vfx.caught`
##                         (impact_flash.gd) at its peak, before the gold
##                         sparkle has left the orb
##   04-catch-success      the seal 16 ticks in, W09's own shot, unchanged
##
## The tree is PAUSED for every shutter (inherited `_shoot_pair`), so the two
## telegraph views are the same physics tick and the seal shots are the ticks
## their names say.

const TELEGRAPH_GLOW := preload("res://scripts/combat/telegraph_glow.gd")
## Ticks into the 0.55 s beat before the shutter: the ring has expanded past
## half its radius and is still above half opacity.
const TELEGRAPH_BITE_TICKS := 4
## The AI's first strike is authored at 1.0 s after the fight opens
## (combat.json `enemy.first_attack`), after the walk-in; this is a bound.
const TELEGRAPH_WAIT_BOUND := 420
## The seal flash lives 0.55 s = 33 ticks; three ticks in it is near peak.
const SEAL_BITE_TICKS := 3

var _out_dir: String = "res://shots/vfx_polish"


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run this under xvfb-run, see the header comment")
		quit(1)
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			_only = argument.substr("--only=".length()).split(",")
		elif argument.begins_with("--out="):
			_out_dir = argument.substr("--out=".length())
	if not _out_dir.begins_with("res://"):
		_out_dir = "res://" + _out_dir
	_out_dir = _out_dir.rstrip("/")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	print("[out] %s" % _out_dir)

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	await _await_physics(BOOT_FRAMES, "boot")

	if not _collect_nodes():
		quit(1)
		return
	_pin_and_freeze_clock()
	_manager.connect("hit_landed", _on_hit)
	_manager.connect("attack_missed", _on_missed)
	_manager.connect("catch_resolved", func(success: bool, _shakes: int) -> void: _catch_results.append(success))

	_leave_the_farmhouse()
	await _ensure_ally()
	_ensure_orbs()
	if _director.call("ally_instance") == null:
		print("FAIL: the player has no creature to fight with; nothing below this point can run")
		_report()
		quit(1)
		return

	if _wanted("telegraph"):
		await _run_telegraph_moment()
	if _wanted("catch"):
		await _run_catch_moment_polish()

	_report()
	quit(0)


## --- the telegraph -----------------------------------------------------------

func _run_telegraph_moment() -> void:
	print("")
	print("=== telegraph moment (bramblebun cluster, band 1) ===")
	var cluster_centre := Vector3(30.0, 0.0, -40.0)
	var wild := _find_nearest_wild(cluster_centre)
	if wild == null:
		print("FAIL: no wild creature found near the bramblebun cluster; 05/06/07 skipped")
		return
	await _teleport_player_near(wild.global_position, NEAR_TELEPORT_SETTLE_FRAMES)
	if not await _engage(wild):
		print("FAIL: could not engage the practice wild creature; 05/06/07 skipped")
		return
	# Keep both bodies standing through the whole beat: the ally is never
	# piloted here, so it takes the blow; give it the bar to take it.
	var mine: RefCounted = _manager.call("active_creature")
	if mine != null:
		mine.hp = mine.max_hp

	# The rig applies `yaw` in `_process`, which a paused tree never runs, so
	# an aim set at the shutter is an aim the frame never sees (the first
	# before-round shot 05 and 06 identical for exactly this reason). Aim
	# from the side NOW and keep re-aiming through the wait, so the camera has
	# arrived before the beat starts.
	_aim_at_fight(wild)
	var glow := await _wait_for_telegraph(wild)
	if glow == null:
		print("FAIL: no TelegraphGlow appeared within %d ticks; 05/06 cannot show the wind-up" % TELEGRAPH_WAIT_BOUND)
	else:
		await _await_physics(TELEGRAPH_BITE_TICKS, "letting the ring open")
		_print_glow(glow, "05")
	_note_effects_named("05-telegraph")
	if bool(_manager.call("is_fighting")) and is_instance_valid(wild):
		await _shoot_pair_to("05-telegraph")
	# 06: the combat camera's own view from behind the ally, at the start of
	# the ring's NEXT pulse (PULSE_PERIOD 0.32 s) so it is as bright as 05 was.
	# The yaw needs an unpaused process frame to land; those cost up to eight
	# ticks each under llvmpipe, so wait on the ring's own clock rather than
	# counting ticks.
	if glow != null and is_instance_valid(glow) and bool(_manager.call("is_fighting")):
		var ally: Node3D = _director.call("ally_body") as Node3D
		if ally != null:
			_aim_camera(_player.global_position, ally.global_position)
		await _await_process(1, "letting the behind-aim land")
		var guard := 0
		while is_instance_valid(glow) and guard < 40:
			var life := float(glow.get("_life"))
			var phase: float = fmod(life, 0.32)
			if life >= 0.30 and phase <= 0.09:
				break
			guard += 1
			_frame_count += 1
			await physics_frame
		if is_instance_valid(glow):
			_print_glow(glow, "06")
			_note_effects_named("06-telegraph-behind")
			await _shoot_pair_to("06-telegraph-behind")
		else:
			print("FAIL: the ring expired before 06-telegraph-behind could be shot")

	# The control: the same side framing with the beat over and nothing
	# drawing under the wild creature.
	# Same lesson as above: aim from the side first, then let the settle
	# frames carry the yaw to the rig before the shutter.
	if is_instance_valid(wild):
		_aim_at_fight(wild)
	var waited := 0
	while waited < 60 and _live_telegraph() != null:
		waited += 1
		_frame_count += 1
		await physics_frame
	await _await_physics(RECOVERY_SETTLE_FRAMES, "recovery settle")
	if bool(_manager.call("is_fighting")) and is_instance_valid(wild):
		_aim_at_fight(wild)
		await _await_process(1, "letting the side-aim land")
		_note_effects_named("07-telegraph-control")
		await _shoot_pair_to("07-telegraph-control")

	await _flee_if_fighting()
	await _await_physics(40, "letting the fight close")


func _live_telegraph() -> Node:
	var arena: Node3D = _manager.call("arena") as Node3D
	if arena == null:
		return null
	for child in arena.get_children():
		if child.get_script() == TELEGRAPH_GLOW:
			return child
	return null


func _wait_for_telegraph(wild: Node3D) -> Node:
	var waited := 0
	while waited < TELEGRAPH_WAIT_BOUND and bool(_manager.call("is_fighting")):
		var found := _live_telegraph()
		if found != null:
			print("TelegraphGlow present after %d ticks (winding_up=%s)" % [
				waited, str(_manager.call("enemy_is_winding_up"))])
			return found
		waited += 1
		_frame_count += 1
		if waited % 10 == 0 and is_instance_valid(wild):
			_aim_at_fight(wild)
		if waited % 30 == 0:
			print("[frame %4d] waiting for the wind-up (%d/%d)" % [_frame_count, waited, TELEGRAPH_WAIT_BOUND])
		await physics_frame
	return null


func _print_glow(glow: Node, shot: String) -> void:
	if not is_instance_valid(glow):
		print("FAIL: the TelegraphGlow expired before shot %s" % shot)
		return
	print("[telegraph %s] colour=%s radius=%.2f duration=%.2f life=%.3f at=%s" % [
		shot, (glow.get("_colour") as Color).to_html(false), float(glow.get("_radius")),
		float(glow.get("_duration")), float(glow.get("_life")),
		str((glow as Node3D).global_position)])


## The inherited `_note_effects` lists arena children by name; the telegraph
## ring has no authored name, so name it here by script.
func _note_effects_named(shot: String) -> void:
	var names: Array = []
	var arena: Node3D = _manager.call("arena") as Node3D
	if arena != null:
		for child in arena.get_children():
			if child.get_script() == TELEGRAPH_GLOW:
				names.append("TelegraphGlow")
			else:
				names.append(str(child.name))
	print("[effects] %s: %s" % [shot, ", ".join(PackedStringArray(names))])


## --- the catch, with the seal's own peak frame --------------------------------

func _run_catch_moment_polish() -> void:
	print("")
	print("=== catch moment (a second bramblebun): seal peak + W09's 16-tick shot ===")
	var cluster_centre := Vector3(30.0, 0.0, -40.0)
	var wild := _find_nearest_wild(cluster_centre)
	if wild == null:
		print("FAIL: no standing wild creature left near the cluster; 04a/04 skipped")
		return
	await _teleport_player_near(wild.global_position, NEAR_TELEPORT_SETTLE_FRAMES)
	if not await _engage(wild):
		print("FAIL: could not engage a second wild creature; 04a/04 skipped")
		return

	var caught := false
	for attempt in MAX_ATTEMPTS:
		if not bool(_manager.call("is_fighting")):
			break
		var foe: RefCounted = _manager.call("enemy")
		var mine: RefCounted = _manager.call("active_creature")
		if foe != null:
			foe.hp = foe.max_hp * 0.08
		if mine != null:
			mine.hp = mine.max_hp
		var before := _catch_results.size()
		if not await _throw_at_the_target(wild):
			print("throw %d/%d never left the hand" % [attempt + 1, MAX_ATTEMPTS])
			continue
		var waited := 0
		while _catch_results.size() == before and waited < CATCH_RESOLVE_BOUND and bool(_manager.call("is_fighting")):
			waited += 1
			_frame_count += 1
			if waited % 20 == 0:
				print("[frame %4d] waiting for the catch to resolve (%d/%d)" % [_frame_count, waited, CATCH_RESOLVE_BOUND])
			await physics_frame
		if _catch_results.size() > before and bool(_catch_results[-1]):
			caught = true
			break
		print("throw %d/%d did not catch" % [attempt + 1, MAX_ATTEMPTS])
		await _await_physics(RECOVERY_SETTLE_FRAMES, "after a failed catch")

	if not caught:
		print("FAIL: no catch sealed in %d throws; 04a/04 not captured" % MAX_ATTEMPTS)
		await _flee_if_fighting()
		return
	# `catch_resolved` is emitted on the same tick the seal flash and the
	# sparkle are spawned, so the burst is live now or never.
	var burst := _live_effect(VFX.NAME_CATCH_BURST)
	if burst == null:
		burst = await _wait_for_effect(VFX.NAME_CATCH_BURST)
	if burst == null:
		print("FAIL: the catch sealed but no CatchBurst appeared; the seal shots will not show the sparkle")
	var ticks_in := 0
	await _await_physics(SEAL_BITE_TICKS, "letting the seal flash open")
	ticks_in += SEAL_BITE_TICKS
	_note_effects_named("04a-catch-seal")
	await _shoot_pair_to("04a-catch-seal")
	await _await_physics(CATCH_BITE_TICKS - ticks_in, "letting the sparkle open")
	_note_effects_named("04-catch-success")
	await _shoot_pair_to("04-catch-success")
	var waited := 0
	while bool(_manager.call("is_fighting")) and waited < FLEE_BOUND:
		waited += 1
		_frame_count += 1
		await physics_frame


## The inherited `_shoot_pair` writes under the base tool's own OUT_DIR
## constant; this one writes under `--out=` so a before and an after round
## can sit side by side without either clobbering W09's frames.
func _shoot_pair_to(name: String) -> void:
	var was_paused := paused
	paused = true
	await _await_process(RENDER_SETTLE_FRAMES, "render settle (hud) for %s" % name)
	await _screenshot("%s/%s-hud.png" % [_out_dir, name])
	var saved: Dictionary = {}
	for child in _world.get_children():
		if child is CanvasLayer:
			saved[child] = (child as CanvasLayer).visible
			(child as CanvasLayer).visible = false
	await _await_process(RENDER_SETTLE_FRAMES, "render settle (clean) for %s" % name)
	await _screenshot("%s/%s-clean.png" % [_out_dir, name])
	for child: Variant in saved.keys():
		if is_instance_valid(child):
			(child as CanvasLayer).visible = bool(saved[child])
	paused = was_paused


func _report() -> void:
	print("")
	print("=== vfx polish capture: %d frames, %d shots written, %d shots failed ===" % [
		_frame_count, _shots_written, _shots_failed])
	print("written to %s" % _out_dir)
