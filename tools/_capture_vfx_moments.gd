extends SceneTree

## W09-VFX (CL-A2). Photographs the combat and reward VFX for a blind visual
## critic, through the REAL combat camera, inside a real fight -- modelled on
## `tools/_capture_combat_moments.gd`, which already stages one and whose
## header carries the reasoning this file inherits (never `--headless` with a
## rendering driver; pause the tree for the shutter because one llvmpipe
## frame outlives every sub-second effect; verify the subject is alive before
## writing a PNG named after it).
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_capture_vfx_moments.gd [-- --only=hit,ko,catch,perf]
##
## SHOT LIST (each shot twice: `-hud.png` as the game draws it, `-clean.png`
## with every CanvasLayer hidden):
##   00-squared-up     the fight open, nothing landing: the baseline the
##                     frame-energy probe (tools/_probe_vfx_frame_energy.gd)
##                     subtracts from the shots below
##   01-hit-spark      a quick attack landing: combat.json's ring plus the new
##                     spark spray and the body flash on the struck creature
##   02-knockout       the blow that empties the bar: the KO puff off the
##                     fainted creature, with the level-up flourish already
##                     rising on the winner (the ally was set one XP short)
##   03-level-up       the same moment ~20 ticks later, the flourish at its peak
##   04-catch-success  the seal on a second wild: catching.json's warm flash
##                     plus the new gold sparkle off the orb
##
## PERF (`perf`): the draw-call/primitive delta the layer costs, measured the
## way `tools/perf_render_stats.gd` measures -- structural counters from the
## RenderingServer, never llvmpipe frame time -- at the `band1_open` site that
## tool names, with a fight running there: sampled at the spark's peak and at
## the KO-plus-level-up peak, each against the same fight and camera a few
## ticks later once every effect has expired. Printed as `[perf]` lines.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/vfx"
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const VFX := preload("res://scripts/vfx/combat_vfx.gd")

const BOOT_FRAMES := 90
const NEAR_TELEPORT_SETTLE_FRAMES := 25
const FAR_TELEPORT_SETTLE_FRAMES := 45
const ENGAGE_SETTLE_FRAMES := 40
const STRIKE_RESOLVE_BOUND := 60
const EFFECT_WAIT_BOUND := 40
## Ticks into the spark before the shutter: the spray has left the core but is
## still bright. The spark lives 0.55 s = 33 ticks.
const SPARK_BITE_TICKS := 5
## Ticks into the KO puff before the shutter (0.9 s = 54 ticks).
const PUFF_BITE_TICKS := 6
## From the knockout shot to the level-up shot. The flourish is 1.5 s = 90
## ticks and began a tick after the strike; the fight's own resolve pause is
## 1.6 s, after which the winner is put away.
const LEVEL_UP_GAP_TICKS := 22
## Later into the seal than the spark: catching.json's own white flash owns
## the first third of a second and the gold sparkle is what is left after it.
const CATCH_BITE_TICKS := 16
const CATCH_RESOLVE_BOUND := 900
const RECOVERY_SETTLE_FRAMES := 20
const AIM_SETTLE_FRAMES := 15
const MAX_ATTEMPTS := 3
const RENDER_SETTLE_FRAMES := 2
const FLEE_BOUND := 90
## Where `tools/perf_render_stats.gd` stands for `band1_open`.
const BAND1_OPEN := Vector3(0.0, 0.0, 700.0)

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null

var _last_strike: Dictionary = {}
var _catch_results: Array = []
var _frame_count := 0
var _shots_written := 0
var _shots_failed := 0
var _only: PackedStringArray = []


func _init() -> void:
	_run()


func _wanted(section: String) -> bool:
	return _only.is_empty() or _only.has(section)


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run this under xvfb-run, see the header comment")
		quit(1)
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			_only = argument.substr("--only=".length()).split(",")

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

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

	if _wanted("hit") or _wanted("ko"):
		await _run_fight_moments()
	if _wanted("catch"):
		await _run_catch_moment()
	if _wanted("perf"):
		await _run_perf()

	_report()
	quit(0)


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _player == null or _rig == null or _manager == null or _director == null:
		print("FAIL: scene is missing the player, camera rig, combat manager or director")
		return false
	return true


## Same as `_capture_combat_moments.gd`: day/clear, FROZEN, so every frame is
## in the same light.
func _pin_and_freeze_clock() -> void:
	var look: Node = _world.get_node_or_null(^"WorldLook")
	var weather: Node = _world.get_node_or_null(^"WorldWeather")
	if weather != null:
		weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)
	if look != null:
		look.call("apply_time", "day")
		look.set_process(false)
		look.set_physics_process(false)
		print("[clock] pinned to day/clear and FROZEN")
	else:
		print("FAIL no WorldLook node; time-of-day cannot be pinned")


func _leave_the_farmhouse() -> void:
	var start := Vector3(48.0, 0.0, -58.0)
	start.y = float(_world.call("ground_height_at", start.x, start.z)) + 1.0
	_player.global_position = start
	_player.velocity = Vector3.ZERO


func _ensure_ally() -> void:
	if _director.call("ally_instance") == null:
		await _director.call("adopt_starter", "terrapup")
	var game := root.get_node_or_null(^"/root/Game")
	var party: RefCounted = game.get("party") if game != null else null
	var instance: RefCounted = _director.call("ally_instance")
	if party != null and instance != null and (party.call("members") as Array).is_empty():
		party.call("add", instance)


func _ensure_orbs() -> void:
	var game := root.get_node_or_null(^"/root/Game")
	var inventory: RefCounted = game.get("inventory") if game != null else null
	if inventory != null:
		inventory.call("add", "orb_basic", 8)


## --- the fight: spark, knockout, level-up ----------------------------------

func _run_fight_moments() -> void:
	print("")
	print("=== fight moments: hit spark, knockout, level-up (bramblebun cluster, band 1) ===")
	var cluster_centre := Vector3(30.0, 0.0, -40.0)
	var wild := _find_nearest_wild(cluster_centre)
	if wild == null:
		print("FAIL: no wild creature found near the bramblebun cluster")
		return
	await _teleport_player_near(wild.global_position, NEAR_TELEPORT_SETTLE_FRAMES)
	if not await _engage(wild):
		print("FAIL: could not engage the practice wild creature")
		return

	# 00: the same fight and camera with nothing landing yet -- the baseline
	# the frame-energy probe subtracts, so the effect is measured rather
	# than the creature's own bright coat.
	_aim_at_fight(wild)
	await _shoot_pair("00-squared-up")

	# 01: a landed quick attack, shot at the spark's peak.
	if _wanted("hit"):
		var landed := await _land_a_quick_attack(wild)
		if landed:
			var spark := await _wait_for_effect(VFX.NAME_HIT_SPARK)
			if spark == null:
				print("FAIL: no HitSpark appeared within %d ticks; 01-hit-spark cannot show a spark" % EFFECT_WAIT_BOUND)
			else:
				await _await_physics(SPARK_BITE_TICKS, "letting the spark open")
				_note_effects("01-hit-spark")
			if bool(_manager.call("is_fighting")) and is_instance_valid(wild):
				_aim_at_fight(wild)
				await _shoot_pair("01-hit-spark")
		else:
			print("FAIL: no quick attack landed; 01-hit-spark not captured")
		await _await_physics(RECOVERY_SETTLE_FRAMES, "recovery settle")

	# 02/03: the killing blow on a 1 HP foe, with the winner one XP short.
	if _wanted("ko") and bool(_manager.call("is_fighting")):
		_stage_the_knockout()
		var landed := await _land_a_quick_attack(wild)
		if landed:
			var puff := await _wait_for_effect(VFX.NAME_KO_PUFF)
			if puff == null:
				print("FAIL: no KoPuff appeared within %d ticks; 02-knockout cannot show a knockout" % EFFECT_WAIT_BOUND)
			else:
				await _await_physics(PUFF_BITE_TICKS, "letting the puff open")
			_note_effects("02-knockout")
			_aim_at_fight(wild)
			await _shoot_pair("02-knockout")
			await _await_physics(LEVEL_UP_GAP_TICKS, "the flourish climbing")
			_note_effects("03-level-up")
			_aim_at_fight(wild)
			await _shoot_pair("03-level-up")
		else:
			print("FAIL: no quick attack landed on the 1 HP foe; 02/03 not captured")

	await _flee_if_fighting()
	await _await_physics(40, "letting the fight close")


## The foe to one hit, the winner to one XP short of a level: the next landed
## blow is a knockout AND a level-up, which is what 02/03 photograph. Nothing
## here is a cheat the game could reach; it is the capture standing at the
## exact moment a whole fight would otherwise take twenty minutes of software
## frames to arrive at.
func _stage_the_knockout() -> void:
	var foe: RefCounted = _manager.call("enemy")
	var mine: RefCounted = _manager.call("active_creature")
	if foe != null:
		foe.hp = 1.0
	if mine != null:
		var cfg: Dictionary = PROGRESSION.config()
		mine.xp = maxi(int(mine.xp_to_next(cfg)) - 1, 0)
		mine.hp = mine.max_hp
		print("[stage] foe at 1 HP; %s at L%d with %d/%d XP" % [
			mine.label(), int(mine.level), int(mine.xp), int(mine.xp_to_next(cfg))])


func _land_a_quick_attack(wild: Node3D) -> bool:
	var attempt := 0
	while attempt < MAX_ATTEMPTS:
		attempt += 1
		var ally: Node3D = _director.call("ally_body") as Node3D
		if ally == null or wild == null or not is_instance_valid(wild):
			return false
		_aim_camera_clear(ally.global_position, wild.global_position, ally)
		var result := await _throw_a_quick_attack()
		if result.is_empty():
			print("quick attack %d/%d did not resolve" % [attempt, MAX_ATTEMPTS])
			continue
		if str(result.get("outcome", "")) != "hit":
			print("quick attack %d/%d missed; retrying" % [attempt, MAX_ATTEMPTS])
			await _await_physics(RECOVERY_SETTLE_FRAMES, "recovery before retry")
			continue
		print("quick attack landed for %.1f" % float(result.get("damage", 0.0)))
		return true
	return false


func _wait_for_effect(name: String) -> Node:
	var waited := 0
	while waited < EFFECT_WAIT_BOUND:
		var found := _live_effect(name)
		if found != null:
			print("%s present after %d ticks" % [name, waited])
			return found
		waited += 1
		_frame_count += 1
		await physics_frame
	return null


## What is alive at the shutter, printed so the log can say whether a frame
## named after an effect actually contained it.
func _note_effects(shot: String) -> void:
	var names: Array = []
	var arena: Node3D = _manager.call("arena") as Node3D
	if arena != null:
		for child in arena.get_children():
			names.append(str(child.name))
	var ally: Node3D = _director.call("ally_body") as Node3D
	if ally != null:
		for child in ally.get_children():
			if child.name == "LevelUpFlourish" or child.name == "BodyGlow":
				names.append("ally/%s" % child.name)
	var foe: Node3D = _manager.call("enemy_body") as Node3D
	if foe != null and is_instance_valid(foe):
		for child in foe.get_children():
			if child.name == "BodyGlow":
				names.append("foe/%s" % child.name)
	print("[effects] %s: %s" % [shot, ", ".join(PackedStringArray(names))])


## Aimed from a point stepped SIDEWAYS of the ally, always. Round 1's
## `_aim_camera_clear` ray test passed (the ray to the bramblebun's centre
## cleared the ally's collider over its head) while the frame still had the
## small struck creature hidden behind Terrapup's own head -- the collider is
## smaller than the model. A player nudges the stick to see around their own
## creature; this always does.
const SIDE_STEP_M := 3.0

func _aim_at_fight(wild: Node3D) -> void:
	var ally: Node3D = _director.call("ally_body") as Node3D
	if ally == null or wild == null or not is_instance_valid(wild):
		return
	var to := wild.global_position - ally.global_position
	to.y = 0.0
	if to.length() < 0.01:
		return
	var side := to.normalized().rotated(Vector3.UP, PI * 0.5) * SIDE_STEP_M
	_aim_camera(ally.global_position + side, wild.global_position)


## --- the catch --------------------------------------------------------------

func _run_catch_moment() -> void:
	print("")
	print("=== catch moment (a second bramblebun) ===")
	var cluster_centre := Vector3(30.0, 0.0, -40.0)
	var wild := _find_nearest_wild(cluster_centre)
	if wild == null:
		print("FAIL: no standing wild creature left near the cluster; 04-catch-success skipped")
		return
	await _teleport_player_near(wild.global_position, NEAR_TELEPORT_SETTLE_FRAMES)
	if not await _engage(wild):
		print("FAIL: could not engage a second wild creature; 04-catch-success skipped")
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
		print("FAIL: no catch sealed in %d throws; 04-catch-success not captured" % MAX_ATTEMPTS)
		await _flee_if_fighting()
		return
	var burst := _live_effect(VFX.NAME_CATCH_BURST)
	if burst == null:
		burst = await _wait_for_effect(VFX.NAME_CATCH_BURST)
	if burst == null:
		print("FAIL: the catch sealed but no CatchBurst appeared; 04-catch-success will not show the seal")
	else:
		await _await_physics(CATCH_BITE_TICKS, "letting the seal open")
	_note_effects("04-catch-success")
	await _shoot_pair("04-catch-success")
	var waited := 0
	while bool(_manager.call("is_fighting")) and waited < FLEE_BOUND:
		waited += 1
		_frame_count += 1
		await physics_frame


func _throw_at_the_target(wild: Node3D) -> bool:
	if not bool(_manager.call("is_aiming")):
		if not await _open_aim():
			return false
	await _await_physics(AIM_SETTLE_FRAMES, "aim settle")
	_aim_throw_at(wild)
	await _await_physics(4, "aim lock")
	await _press("combat_throw")
	return true


func _open_aim() -> bool:
	var budget := 80
	while budget > 0:
		await _press("combat_throw")
		budget -= 4
		for i in 6:
			_frame_count += 1
			await physics_frame
			budget -= 1
		if bool(_manager.call("is_aiming")):
			return true
	return false


## Ported from `tests/smoke_catching.gd::_aim_at_the_target`: lead the target
## by the release wind-up, then point the rig's yaw and pitch at it.
func _aim_throw_at(wild: Node3D) -> void:
	var camera := _rig.get_node_or_null(^"Camera3D") as Camera3D
	if camera == null or wild == null or not is_instance_valid(wild):
		return
	var eye := camera.global_position
	var velocity := Vector3.ZERO
	if wild is CharacterBody3D:
		velocity = (wild as CharacterBody3D).velocity
	var lead_time := 8.0 / float(Engine.physics_ticks_per_second) + 0.18
	var predicted: Vector3 = (wild.call("centre") as Vector3) + velocity * lead_time
	var to := predicted - eye
	_rig.set("yaw", atan2(-to.x, -to.z))
	var flat := Vector2(to.x, to.z).length()
	_rig.set("pitch", atan2(to.y, maxf(flat, 0.01)))


## --- perf ------------------------------------------------------------------

## The layer's structural cost, measured the only way that isolates it: at
## the effect's peak the tree is PAUSED, the frame is counted once with every
## VFX node drawing and once with them all lifted (bursts and the flourish
## hidden, the body-glow overlays taken off their meshes), then they are put
## back. Same fight, same camera, same tick -- the difference is this lane
## and nothing else. A first version sampled "after the effects expired"
## instead and reported +699k primitives for a fourteen-mote spark: the fight
## and the camera had moved between the two samples and the number was the
## view changing, not the spark.
func _run_perf() -> void:
	print("")
	print("=== perf: draw-call delta with a fight running at band1_open ===")
	await _teleport_player_near(BAND1_OPEN, FAR_TELEPORT_SETTLE_FRAMES)
	var wild := _find_nearest_wild(_player.global_position)
	if wild == null:
		print("FAIL: no wild creature near band1_open; perf not measured")
		return
	var distance := wild.global_position.distance_to(_player.global_position)
	print("[perf] nearest wild to band1_open is %.0f m away" % distance)
	await _teleport_player_near(wild.global_position, NEAR_TELEPORT_SETTLE_FRAMES)
	if not await _engage(wild):
		print("FAIL: could not engage near band1_open; perf not measured")
		return

	if await _land_a_quick_attack(wild):
		var spark := await _wait_for_effect(VFX.NAME_HIT_SPARK)
		if spark != null:
			await _await_physics(SPARK_BITE_TICKS, "spark peak")
		_aim_at_fight(wild)
		await _sample_pair("hit spark + body flash")
	await _await_physics(RECOVERY_SETTLE_FRAMES, "recovery settle")

	if bool(_manager.call("is_fighting")):
		_stage_the_knockout()
		if await _land_a_quick_attack(wild):
			var puff := await _wait_for_effect(VFX.NAME_KO_PUFF)
			if puff != null:
				await _await_physics(PUFF_BITE_TICKS, "puff peak")
			_aim_at_fight(wild)
			await _sample_pair("ko puff + level-up flourish + rim glow (+ spark tail)")
	await _flee_if_fighting()


## Every node this lane draws, right now: bursts under the arena, the
## flourish and glows on the two bodies.
func _vfx_nodes() -> Array:
	var out: Array = []
	var arena: Node3D = _manager.call("arena") as Node3D
	if arena != null:
		for child in arena.get_children():
			if child.name == VFX.NAME_HIT_SPARK or child.name == VFX.NAME_KO_PUFF or child.name == VFX.NAME_CATCH_BURST:
				out.append(child)
	for body: Variant in [_director.call("ally_body"), _manager.call("enemy_body")]:
		if body is Node and is_instance_valid(body):
			for child in (body as Node).get_children():
				if child.name == "LevelUpFlourish" or child.name == "BodyGlow":
					out.append(child)
	return out


func _set_vfx_drawing(nodes: Array, on: bool) -> void:
	for node: Variant in nodes:
		if not is_instance_valid(node):
			continue
		if node.has_method("suspend"):
			node.call("suspend", not on)
		elif node is Node3D:
			(node as Node3D).visible = on


## A/B/A/B inside one paused span, after a long settle.
##
## The first version sampled once with the effects drawing and once with them
## lifted and called the difference the cost. It is not: between two
## consecutive samples of a PAUSED tree at band1_open, `draw_calls` fell
## 7,315 -> 3,790 and `objects` fell 6,826 -> 3,301 -- exactly -3,525 on both,
## about half the visible scene, which cannot come from hiding two effect
## nodes. Terrain and scatter LOD keeps converging on the render side while
## the tree is paused. A second pair the same run differed by 334, again
## equal on draw calls and objects.
##
## So: settle far longer before the first sample, then alternate
## with/without/with/without and print all four. Two deltas that agree are a
## measurement; two that disagree are the scene still moving, and the reader
## can see which they got. The clean structural number for the layer itself
## comes from `tools/_probe_vfx_perf.gd`, which measures it in a bare scene
## with nothing to converge.
const PERF_SETTLE_FRAMES := 24

func _sample_pair(label: String) -> void:
	var nodes := _vfx_nodes()
	var names: Array = []
	for node: Variant in nodes:
		names.append(str(node.name))
	print("[perf] %s: %d VFX nodes alive (%s)" % [label, nodes.size(), ", ".join(PackedStringArray(names))])
	var was_paused := paused
	paused = true
	await _await_process(PERF_SETTLE_FRAMES, "perf settle (letting LOD converge)")

	var with_a := await _sample("%s, VFX drawing (A)" % label)
	_set_vfx_drawing(nodes, false)
	var without_a := await _sample("%s, VFX lifted (A)" % label)
	_set_vfx_drawing(nodes, true)
	var with_b := await _sample("%s, VFX drawing (B)" % label)
	_set_vfx_drawing(nodes, false)
	var without_b := await _sample("%s, VFX lifted (B)" % label)
	_set_vfx_drawing(nodes, true)

	paused = was_paused
	_print_delta("%s (pair A)" % label, with_a, without_a)
	_print_delta("%s (pair B)" % label, with_b, without_b)
	var drift: int = absi((int(with_a[0]) - int(without_a[0])) - (int(with_b[0]) - int(without_b[0])))
	if drift > 8:
		print("[perf] NOISE: the two pairs disagree by %d draw calls; the scene is still converging and this number is not the effect. Use tools/_probe_vfx_perf.gd." % drift)


## One structural sample of the current (paused) frame.
func _sample(label: String) -> Array:
	await _await_process(RENDER_SETTLE_FRAMES, "render settle (%s)" % label)
	await RenderingServer.frame_post_draw
	var draws := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var prims := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var objects := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
	print("[perf] %s: draw_calls=%d primitives=%d objects=%d" % [label, draws, prims, objects])
	return [draws, prims, objects]


func _print_delta(label: String, peak: Array, base: Array) -> void:
	print("[perf] DELTA %s: draw_calls=%+d primitives=%+d objects=%+d" % [
		label, int(peak[0]) - int(base[0]), int(peak[1]) - int(base[1]), int(peak[2]) - int(base[2])])


## --- shared plumbing (from _capture_combat_moments.gd) ---------------------

func _throw_a_quick_attack() -> Dictionary:
	_last_strike = {}
	await _press("combat_quick")
	var waited := 0
	while _last_strike.is_empty() and waited < STRIKE_RESOLVE_BOUND:
		waited += 1
		_frame_count += 1
		await physics_frame
	return _last_strike


func _on_hit(on_enemy: bool, amount: float) -> void:
	if not on_enemy or not _last_strike.is_empty():
		return
	_last_strike = {"outcome": "hit", "damage": amount}


func _on_missed(by_player: bool) -> void:
	if not by_player or not _last_strike.is_empty():
		return
	_last_strike = {"outcome": "miss"}


## Nearest STANDING wild: a fainted one from the previous moment is not a fight.
func _find_nearest_wild(from: Vector3) -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	for entry: Variant in _director.call("wild_creatures"):
		var body := entry as Node3D
		if body == null or not is_instance_valid(body) or not body.visible:
			continue
		var instance: Variant = body.get("instance")
		if instance != null and bool(instance.get("fainted")):
			continue
		var d := body.global_position.distance_to(from)
		if d < best_distance:
			best = body
			best_distance = d
	return best


func _teleport_player_near(spot: Vector3, settle_frames: int) -> void:
	var stand := spot + Vector3(0.0, 0.0, 4.0)
	stand.y = float(_world.call("ground_height_at", stand.x, stand.z)) + 1.0
	_player.global_position = stand
	_player.velocity = Vector3.ZERO
	_aim_camera(_player.global_position, spot)
	await _await_physics(settle_frames, "teleport settle")


func _aim_camera(from: Vector3, to: Vector3) -> void:
	var dir := to - from
	dir.y = 0.0
	if dir.length() < 0.01:
		return
	_rig.set("yaw", atan2(-dir.x, -dir.z))


func _aim_camera_clear(from: Vector3, to: Vector3, avoid: Node3D) -> void:
	_aim_camera(from, to)
	if avoid == null or not is_instance_valid(avoid) or _world == null:
		return
	var camera := _rig.get_node_or_null(^"Camera3D") as Camera3D
	if camera == null:
		return
	var space: PhysicsDirectSpaceState3D = _world.get_world_3d().direct_space_state
	var side := to - from
	side.y = 0.0
	if side.length() < 0.01:
		return
	side = side.normalized().rotated(Vector3.UP, PI * 0.5)
	for offset in [0.0, 1.6, -1.6, 2.8, -2.8]:
		if offset != 0.0:
			_aim_camera(from + side * offset, to)
			camera = _rig.get_node_or_null(^"Camera3D") as Camera3D
			if camera == null:
				return
		var query := PhysicsRayQueryParameters3D.create(camera.global_position, to)
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty() or hit.get("collider") != avoid:
			return


func _engage(wild: Node3D) -> bool:
	var attempt := 0
	while attempt < MAX_ATTEMPTS and not bool(_manager.call("is_fighting")):
		attempt += 1
		await _press("interact")
		var waited := 0
		while not bool(_manager.call("is_fighting")) and waited < 30:
			waited += 1
			_frame_count += 1
			await physics_frame
	if not bool(_manager.call("is_fighting")):
		return false
	await _await_physics(ENGAGE_SETTLE_FRAMES, "engage camera settle")
	return bool(_manager.call("is_fighting"))


func _flee_if_fighting() -> void:
	if not bool(_manager.call("is_fighting")):
		return
	if bool(_manager.call("is_aiming")):
		await _press("combat_run")
		await _await_physics(5, "leaving the aim")
	await _press("combat_run")
	var waited := 0
	while bool(_manager.call("is_fighting")) and waited < FLEE_BOUND:
		waited += 1
		_frame_count += 1
		await physics_frame


func _press(action: String) -> void:
	Input.action_press(action)
	await _await_physics(2, "press %s" % action)
	Input.action_release(action)
	await _await_physics(1, "release %s" % action)


func _shoot_pair(name: String) -> void:
	var was_paused := paused
	paused = true
	await _await_process(RENDER_SETTLE_FRAMES, "render settle (hud) for %s" % name)
	await _screenshot("%s/%s-hud.png" % [OUT_DIR, name])
	var saved: Dictionary = {}
	for child in _world.get_children():
		if child is CanvasLayer:
			saved[child] = (child as CanvasLayer).visible
			(child as CanvasLayer).visible = false
	await _await_process(RENDER_SETTLE_FRAMES, "render settle (clean) for %s" % name)
	await _screenshot("%s/%s-clean.png" % [OUT_DIR, name])
	for child: Variant in saved.keys():
		if is_instance_valid(child):
			(child as CanvasLayer).visible = bool(saved[child])
	paused = was_paused


func _live_effect(name: String) -> Node:
	var arena: Node3D = _manager.call("arena") as Node3D
	if arena == null:
		return null
	for child in arena.get_children():
		if child.name == name:
			return child
	return null


func _screenshot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		print("FAIL %s: viewport returned no image" % path)
		_shots_failed += 1
		return
	if image.save_png(path) != OK:
		print("FAIL %s: save_png" % path)
		_shots_failed += 1
		return
	print("shot: %s" % path)
	_shots_written += 1


func _await_physics(n: int, label: String) -> void:
	for i in n:
		_frame_count += 1
		if n <= 6 or (i + 1) % 10 == 0 or i + 1 == n:
			print("[frame %4d] %s (%d/%d)" % [_frame_count, label, i + 1, n])
		await physics_frame


func _await_process(n: int, label: String) -> void:
	for i in n:
		_frame_count += 1
		print("[frame %4d] %s (%d/%d)" % [_frame_count, label, i + 1, n])
		await process_frame


func _report() -> void:
	print("")
	print("=== vfx moments capture: %d frames, %d shots written, %d shots failed ===" % [
		_frame_count, _shots_written, _shots_failed])
	print("written to %s" % OUT_DIR)
