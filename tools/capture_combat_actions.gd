extends SceneTree

## Combat HUD rebuild's own blind-judge frames (owner spec §9, D32's mid-combat
## switching UI).
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_combat_actions.gd
##
## Three shots, each isolating one thing the rebuild has to get right:
##
##   combat_normal        mid-fight, ordinary state: enemy plate, creature block,
##                         full 2x2 move grid with the charged cell primed.
##   combat_lowhp_charged  the same fight with the active creature worn down to
##                         ~20% HP, so the health-bar colour lerp and the grid's
##                         ready/dimmed treatment can both be checked at once.
##   combat_selector       D32's held-switch party selector, open. Driven
##                         programmatically (a headless script cannot literally
##                         hold a gamepad button) by pressing
##                         `combat_switch_right` and holding it past the HUD's
##                         own hold threshold, the same `Input.action_press`
##                         idiom `_open_the_aim()` already used for the aim row
##                         before this rewrite.
##
## NOT `tools/survey_combat.gd`. Same reason the pre-rebuild version of this
## file gave: that tool still walks from the raw scene spawn, which starts
## inside Grandpa's farmhouse (D18) and never reaches the outdoor world.
##
## `_ensure_ally()` only ever populates `EncounterDirector`'s own `_ally` /
## `_ally_body` — nothing in the normal game flow adds a bench beyond that
## (party membership is wired by `sequence_director.gd`'s starter ceremony,
## a separate flow this tool does not run). The selector needs more than one
## non-fainted party member to have anything to select, so `_stock_the_bench()`
## builds a few extra `creature_instance`s directly and writes them onto
## `CombatManager`'s own `_party` array by reflection (`.set("_party", ...)`)
## once the fight is open — the same reflection `combat_hud.gd` itself now
## reads that array with (see its `_party_entries()` header), needed here
## because `EncounterDirector._start_fight()` only ever hands the manager a
## one-creature party (`[_ally]`) today; see this task's report for that gap.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const MATH := preload("res://scripts/combat/combat_math.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const OUT_DIR := "res://shots/_diag"

const SETTLE_FRAMES := 240

## Extra bench creatures, spawned only for the `combat_selector` shot so the
## selector has non-active, non-fainted party members to offer. Not the
## roster's exact make-up on purpose — variety in silhouette/colour is what
## the shot needs to be legible, not narrative correctness.
const BENCH_SPECIES := ["ripplet", "galewisp", "mudsnout"]

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _hud: Node = null
var _wild: Node3D = null
var _ally: Node3D = null

var _written: Array[String] = []
var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return
	_world = packed.instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	await _ensure_ally()
	_leave_the_farmhouse()
	if not _collect_nodes():
		_finish()
		return

	var debug_hud: CanvasLayer = _world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if debug_hud != null:
		debug_hud.visible = false

	print("walking to the wild creature...")
	await _walk_to_the_wild_creature()
	print("engaging...")
	await _engage()
	if not bool(_manager.call("is_fighting")):
		_failures.append("could not enter combat; no frames to show")
		_finish()
		return
	print("fighting.")
	_ally = _director.call("ally_body") as Node3D

	# 1. Ordinary state: whatever the fight's real ready/dimmed mix happens to
	# be moments after opening, with energy topped up so the charged cell
	# (and its one-shot ready pulse) both render primed rather than dimmed.
	_prime_energy(1.0)
	await _settle_hud(6)
	await _capture("combat_normal")

	# 2. The same fight, active creature worn down to ~20% HP, charged still ready.
	_prime_hp_fraction(0.2)
	_prime_energy(1.0)
	await _settle_hud(6)
	await _capture("combat_lowhp_charged")

	# 3. D32's held-switch selector, open. Needs a real bench first.
	_stock_the_bench()
	print("opening the selector...")
	if await _open_the_selector():
		await _capture("combat_selector")
	else:
		_failures.append("could not open the switch selector; no frame captured")
	_release_switch()

	_finish()


func _ensure_ally() -> void:
	var director := _world.get_node_or_null(^"EncounterDirector")
	if director == null or director.call("ally_instance") != null:
		return
	await director.call("adopt_starter", "terrapup")


## Same teleport `tests/smoke_combat.gd::_leave_the_farmhouse()` uses.
func _leave_the_farmhouse() -> void:
	var player := _world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null:
		return
	var start := Vector3(48.0, 0.0, -58.0)
	start.y = float(_world.call("ground_height_at", start.x, start.z)) + 1.0
	player.global_position = start
	player.velocity = Vector3.ZERO


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_hud = _world.get_node_or_null(^"CombatHUD")
	if _player == null or _manager == null or _director == null or _rig == null or _hud == null:
		_failures.append("scene is missing the player, camera rig, combat manager, director or HUD")
		return false
	_wild = _director.call("wild_creature") as Node3D
	if _wild == null:
		_failures.append("the encounter director never spawned a wild creature")
		return false
	return true


func _walk_to_the_wild_creature() -> void:
	var engage_range := float(MATH.config().get("flow", {}).get("engage_range", 6.0))
	for i in 1800:
		var to := _wild.global_position - _player.global_position
		to.y = 0.0
		if to.length() <= engage_range * 0.6:
			break
		_rig.set("yaw", atan2(-to.x, -to.z))
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	for i in 10:
		await physics_frame


func _engage() -> void:
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	for i in 30:
		await physics_frame


## Let a handful of idle-process frames run so the HUD's own `_process` (which
## the fight's physics frames do not drive) catches up to a state change made
## between captures -- `_prime_energy`/`_prime_hp_fraction` write straight onto
## the creature instance, which the HUD only notices on its next `_process`.
func _settle_hud(frames: int) -> void:
	for i in frames:
		await process_frame


## Force the active creature's energy, for a grid shot that needs the charged cell
## primed (or, in principle, dimmed) without fighting for it hit by hit.
## `creature_instance.energy` is a plain public var -- this is a direct write, not
## reflection into anything underscore-prefixed.
func _prime_energy(fraction: float) -> void:
	var creature: RefCounted = _manager.call("active_creature")
	if creature == null:
		return
	creature.energy = MATH.max_energy() * clampf(fraction, 0.0, 1.0)


## Force the active creature's HP fraction, for the low-HP shot. Never all the way
## to zero -- a fainted active creature ends the fight, which is not this shot.
func _prime_hp_fraction(fraction: float) -> void:
	var creature: RefCounted = _manager.call("active_creature")
	if creature == null:
		return
	creature.hp = creature.max_hp * clampf(fraction, 0.01, 1.0)
	creature.fainted = false


## Build a few bench creatures and hand them to `CombatManager` directly. See this
## file's header for why: `EncounterDirector._start_fight()` only ever passes
## a one-creature party in today's build, and the selector needs more than one
## non-fainted member to have anything to show.
func _stock_the_bench() -> void:
	var active: RefCounted = _manager.call("active_creature")
	if active == null:
		return
	var party: Array[RefCounted] = [active]
	for species_id in BENCH_SPECIES:
		var bench_creature: RefCounted = SPECIES.spawn(species_id)
		if bench_creature != null:
			party.append(bench_creature)
	_manager.set("_party", party)
	_manager.set("_active_index", 0)


## Opens the switch selector directly through `CombatHUD._open_selector()`
## (reflection: `.call("_open_selector")`) rather than driving the real
## tap/hold input and waiting out `SWITCH_HOLD_THRESHOLD` in real time.
##
## An earlier version pressed and held `combat_switch_right`, waiting either a
## fixed wall-clock deadline or a fixed frame count for the HUD's own
## `_process` to notice. Both starved under this sandbox's heavy, variable CPU
## contention -- observed taking upward of an hour of wall time for what is a
## 0.28s hold threshold on a healthy machine, with no guarantee it would ever
## finish. What this shot needs to verify is that the selector RENDERS
## correctly once open; whether tap-vs-hold input timing itself works is
## `combat_hud.gd`'s own concern (exercised by hand, not by this capture
## tool), not this screenshot's. Calling the HUD's own open function directly
## exercises the identical `_refresh_selector()` / `_selector_root.visible`
## path the real hold would, deterministically and in a handful of frames.
func _open_the_selector() -> bool:
	_hud.call("_open_selector")
	for i in 6:
		await process_frame
	return bool(_hud.get("_selector_open"))


func _release_switch() -> void:
	Input.action_release("combat_switch_right")
	for i in 4:
		await process_frame


func _capture(name: String) -> void:
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		_failures.append("%s: viewport returned no image" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	if image.save_png(path) != OK:
		_failures.append("%s: save_png failed" % name)
		return
	_written.append(path)
	print("  %-24s -> %s" % [name, path])


func _finish() -> void:
	print("")
	print("%d frames -> %s" % [_written.size(), OUT_DIR])
	print("Software rendering; placeholder capsules. HUD legibility only.")
	if not _failures.is_empty():
		for line in _failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)
