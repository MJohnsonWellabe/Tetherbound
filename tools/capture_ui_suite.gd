extends SceneTree

## The owner's 19-shot UI screenshot suite (spec §23), the MISSING half only —
## the other twelve already live in shots/_diag/ from earlier capture tools
## (hud_*, minimap_*, combat_*, creatures_tab). This boots the meadows world exactly
## ONCE (software rendering makes that boot the expensive part) and walks every
## remaining UI state in one session: explore/prompt, the inventory trio, the
## build menu pair, the placement trio, the catch pair, and a final 720p
## exploration frame for the ROG Ally readability proxy.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script tools/capture_ui_suite.gd
##
## Same idioms as the tools this borrows from (READ FULLY before touching):
##   tools/capture_exploration_hud.gd  - settle-frames idiom, screenshot write
##   tools/capture_menu_panels.gd      - opening the game menu on a tab by id
##   tools/capture_build_menu.gd       - the build menu + placement ghost flow
##   tools/capture_catch_sequence.gd   - engaging a fight and the aim-chance stills
##   tests/smoke_free_build.gd         - free_build toggle, harvest-node lookup
##
## Twelve frames, in an order chosen to minimize state churn (explore+prompt
## first since it wants the HUD camera undisturbed; inventory and build menu
## both pause the tree so they sit together next; placement needs the tree
## live again and free_build on; catch needs a real fight; 720p last since it
## just wants one ordinary exploration frame at a different resolution):
##
##   ui_explore_prompt   - player beside a harvest node, the HUD's interact
##                         prompt line lit (spec §6/§6.6, shot 2)
##   ui_inventory         - game menu, Backpack tab, a seeded satchel (shot 5)
##   ui_inventory_selected - same screen, a non-first slot focused (shot 6)
##   ui_inventory_focus   - same slot focus, forced gamepad-glyph mode (shot 18)
##   ui_build_structures  - build menu, Structures tab (spec §12, shot 13)
##   ui_build_furniture   - build menu, Furniture tab (shot 14)
##   ui_place_grid        - a wall ghost armed, local grid lines visible (shot 17)
##   ui_place_snap        - a second wall's ghost near the first, snap dots lit (shot 15)
##   ui_place_invalid     - a ghost over a steep slope, tinted invalid/coral (shot 16)
##   ui_catch_low         - aim reticle, full-health target, low catch chance (shot 11)
##   ui_catch_high        - aim reticle, sliver-health target, high catch chance (shot 12)
##   ui_ally_720          - one exploration frame at 1280x720 (shot 19)

const SCENE := "res://scenes/world/meadows_playground.tscn"
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const CATCH := preload("res://scripts/combat/catch_math.gd")
const BUILD_MENU := preload("res://scripts/ui/build_menu.gd")
const OUT_DIR := "res://shots/_diag"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 10

## A harvest node close to spawn (data/config/harvest.json), used to trigger
## the interact prompt without a long walk.
const HARVEST_SPOT := Vector2(-8.0, 8.0)

## A steep flank of the first "rise" peak in terrain_playground.json
## (centre [140,-90], radius 78) — tools/debug_slope_probe.gd measured
## slope(1m) = 62.78 degrees right at the peak's own centre, comfortably past
## build_placer.gd's MAX_SLOPE_RISE (0.8m of corner rise) at any reasonable
## sampling radius. Used only to fail the placement legality check, not to
## stand on.
const STEEP_SPOT := Vector2(140.0, -90.0)

## Same combat-entry coordinates every other combat capture tool uses
## (capture_combat_actions.gd, capture_catch_sequence.gd) — outside Grandpa's
## farmhouse (D18), where the encounter director actually spawns a wild creature.
const COMBAT_START := Vector3(48.0, 0.0, -58.0)

var _world: Node = null
var _game: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _hud: CanvasLayer = null
var _field: RefCounted = null

var _written: Array[String] = []
var _failures: Array[String] = []
var _start_ms: int = 0


func _init() -> void:
	_run()


func _run() -> void:
	_start_ms = Time.get_ticks_msec()
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
	_log("world settled")

	_game = root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_hud = _world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	_field = HEIGHTFIELD.new()

	if _game == null or _player == null or _rig == null:
		_failures.append("missing Game autoload, Player or CameraRig -- cannot proceed")
		_finish()
		return

	# Pin the whole suite to the device the owner actually holds, not just shot
	# 18. `game_state.gd` initialises `_last_input_was_gamepad` from `not
	# Input.get_connected_joypads().is_empty()`, true from frame one on the ROG
	# Ally (an always-connected XInput pad) but false under this harness's
	# `xvfb-run` display, where no joypad is ever connected -- so
	# `ui_explore_prompt`/`ui_inventory`/`ui_inventory_selected` all fell back to
	# keyboard keycaps before shot 18's own explicit pin ever ran, for a
	# controller-first target platform. `VISUAL-CENSUS-2026-08-31.md` defect 148
	# read those three frames' bracketed/keycap glyphs as a `CLAUDE.md`
	# "controller first" violation in the shipped game; it is not one --
	# `tools/_capture_ui_survey.gd::_pin_owner_device()` already diagnosed and
	# fixed the identical gap for its own captures. Shot 18's own pin below is
	# now redundant with this one but left in place as documentation of what
	# that frame is specifically for.
	_game.set("_last_input_was_gamepad", true)

	await _phase_explore_prompt()
	await _phase_inventory()
	await _phase_build_menu()
	await _phase_placement()
	await _phase_catch()
	await _phase_720p()

	_finish()


# --- phase 1: explore + interact prompt (shot 2) ----------------------------


func _phase_explore_prompt() -> void:
	print("[explore+prompt] positioning player at a harvest node...")

	# A disconnected, controlled camera, the same reasoning
	# capture_exploration_hud.gd gives: the HUD's own screen-space scale is
	# what is being judged, not whatever the rig's live follow happens to frame.
	_rig.set_process(false)
	_rig.set_physics_process(false)
	_player.set_physics_process(false)

	var camera := Camera3D.new()
	camera.name = "UISuiteExploreCamera"
	camera.fov = 70.0
	camera.far = 2000.0
	_world.add_child(camera)
	camera.make_current()

	var offset := Vector2(6.0, -3.0) # same relative eye offset capture_exploration_hud.gd uses
	var eye_xz := HARVEST_SPOT + offset
	var eye_h := 3.4
	camera.global_position = Vector3(eye_xz.x, _field.height_at(eye_xz.x, eye_xz.y) + eye_h, eye_xz.y)

	# Stand well inside interactable.gd's 2.4m range (harvest_node.gd's setup()).
	var stand := HARVEST_SPOT + Vector2(1.0, 0.0)
	_player.global_position = Vector3(stand.x, _field.height_at(stand.x, stand.y) + 0.4, stand.y)
	camera.look_at(_player.global_position + Vector3.UP, Vector3.UP)

	# interaction_arbiter.gd recomputes on _process (idle), not physics -- give
	# it real idle frames to notice the teleport and publish the prompt.
	for i in 40:
		await process_frame

	await _shoot("ui_explore_prompt")

	# Hand the camera back to the rig's own Camera3D before anything else runs
	# -- build/catch phases below rely on the live gameplay camera following
	# the player, the same as capture_build_menu.gd / capture_catch_sequence.gd.
	_rig.set_process(true)
	_rig.set_physics_process(true)
	_player.set_physics_process(true)
	var rig_camera := _rig.get_node_or_null(^"Camera3D") as Camera3D
	if rig_camera != null:
		rig_camera.make_current()
	camera.queue_free()
	for i in 5:
		await physics_frame


# --- phase 2: inventory trio (shots 5, 6, 18) --------------------------------


func _phase_inventory() -> void:
	print("[inventory] seeding the satchel and opening the menu...")
	var inventory: RefCounted = _game.get("inventory")
	if inventory == null:
		_failures.append("inventory: Game.inventory not reachable")
		return
	inventory.call("add", "wood", 24)
	inventory.call("add", "stone", 10)
	inventory.call("add", "berries", 6)
	inventory.call("add", "potion_small", 3)
	inventory.call("add", "axe", 1)

	var menu: Node = _game.call("menu")
	if menu == null:
		_failures.append("inventory: Game.menu() not reachable")
		return

	menu.call("open", "backpack")
	for i in POSE_FRAMES:
		await process_frame
	await _shoot("ui_inventory")

	var bodies: Array = menu.get("_bodies")
	var backpack: Node = bodies[0] if not bodies.is_empty() else null
	if backpack == null:
		_failures.append("inventory: no backpack tab body")
	else:
		var buttons: Array = backpack.get("_buttons")
		# The axe slot -- a real, non-first, non-empty slot, the same
		# find_slot idiom capture_menu_panels.gd uses for its target picker.
		var slot: int = int(inventory.call("find_slot", "axe"))
		if slot <= 0 or slot >= buttons.size():
			slot = mini(3, buttons.size() - 1) # fall back to any non-first slot
		if slot >= 0 and slot < buttons.size():
			(buttons[slot] as Button).grab_focus()
			for i in POSE_FRAMES:
				await process_frame
			await _shoot("ui_inventory_selected")

			_game.set("_last_input_was_gamepad", true)
			for i in POSE_FRAMES:
				await process_frame
			await _shoot("ui_inventory_focus")
		else:
			_failures.append("inventory: no valid slot button to focus")

	menu.call("close")
	for i in 10:
		await process_frame


# --- phase 3: build menu pair (shots 13, 14) --------------------------------


func _phase_build_menu() -> void:
	print("[build menu] opening structures/furniture tabs...")
	var menu := BUILD_MENU.new()
	root.add_child(menu)
	menu.call("open")
	menu.call("_select_category", 2) # structures
	for i in POSE_FRAMES:
		await process_frame
	await _shoot("ui_build_structures")

	menu.call("_select_category", 3) # furniture
	for i in POSE_FRAMES:
		await process_frame
	await _shoot("ui_build_furniture")

	menu.call("close")
	menu.queue_free()
	for i in 10:
		await process_frame


# --- phase 4: placement trio (shots 17, 15, 16) -----------------------------


func _phase_placement() -> void:
	print("[placement] arming walls...")
	var placer := _world.get_node_or_null(^"BuildPlacer")
	if placer == null:
		_failures.append("placement: no BuildPlacer in the world")
		return

	# The one cost gate free_build is allowed to bend (docs/decisions/D16) --
	# per this task's brief, so the placement trio never fights inventory math.
	_game.set("free_build", true)

	# Stand back near the (flat, walkable) harvest spot from phase 1 for the
	# grid/snap pair.
	var stand := HARVEST_SPOT
	_player.global_position = Vector3(stand.x, _field.height_at(stand.x, stand.y) + 0.4, stand.y)
	_player.velocity = Vector3.ZERO
	_rig.set("yaw", 0.0)
	for i in 10:
		await physics_frame

	_game.set("pending_build", "wall")
	for i in POSE_FRAMES * 3:
		await physics_frame
	await _shoot("ui_place_grid")

	Input.action_press("build_place")
	await physics_frame
	await physics_frame
	Input.action_release("build_place")
	for i in 15:
		await physics_frame

	# Arm a second wall and nudge the player so the ghost lands close enough to
	# the first to trigger the neighbour-snap dots -- same nudge
	# capture_build_menu.gd uses.
	_game.set("pending_build", "wall")
	var forward: Vector3 = -_player.global_transform.basis.z
	if _rig.has_method("planar_basis"):
		forward = -(_rig.call("planar_basis") as Basis).z
	_player.global_position += forward * 0.4 + Vector3(0.3, 0.0, 0.0)
	for i in POSE_FRAMES * 3:
		await physics_frame
	await _shoot("ui_place_snap")

	_game.set("pending_build", "")
	for i in 10:
		await physics_frame

	# Teleport to the steep flank for the invalid/coral shot -- far from any
	# placed wall, so this is rejected on slope, not on the neighbour-snap
	# "unsupported" amber path.
	print("[placement] moving to steep ground for the invalid shot...")
	_player.global_position = Vector3(
		STEEP_SPOT.x - 3.0, _field.height_at(STEEP_SPOT.x - 3.0, STEEP_SPOT.y) + 0.4, STEEP_SPOT.y
	)
	_player.velocity = Vector3.ZERO
	var to := Vector2(STEEP_SPOT.x, STEEP_SPOT.y) - Vector2(_player.global_position.x, _player.global_position.z)
	_rig.set("yaw", atan2(-to.x, -to.y))
	for i in 15:
		await physics_frame

	_game.set("pending_build", "wall")
	for i in POSE_FRAMES * 3:
		await physics_frame
	if bool(placer.get("_ghost_ok")):
		_failures.append("ui_place_invalid: ghost reads as VALID at the steep spot -- terrain not steep enough")
	await _shoot("ui_place_invalid")
	_game.set("pending_build", "")
	_game.set("free_build", false)
	for i in 10:
		await physics_frame


# --- phase 5: catch pair (shots 11, 12) -------------------------------------


func _phase_catch() -> void:
	print("[catch] engaging a wild creature...")
	var director := _world.get_node_or_null(^"EncounterDirector")
	var manager := _world.get_node_or_null(^"CombatManager")
	if director == null or manager == null:
		_failures.append("catch: no EncounterDirector or CombatManager in the world")
		return

	if director.call("ally_instance") == null:
		await director.call("adopt_starter", "terrapup")

	_player.global_position = COMBAT_START
	_player.global_position.y = float(_world.call("ground_height_at", COMBAT_START.x, COMBAT_START.z)) + 1.0
	_player.velocity = Vector3.ZERO
	for i in 10:
		await physics_frame

	var debug_hud: CanvasLayer = _hud
	if debug_hud != null:
		debug_hud.visible = false

	var inventory: RefCounted = _game.get("inventory")
	if inventory != null:
		inventory.call("add", "orb_basic", 10)

	var wild: Node3D = director.call("wild_creature") as Node3D
	if wild == null:
		_failures.append("catch: the encounter director never spawned a wild creature")
		return

	var engage_range := float(MATH.config().get("flow", {}).get("engage_range", 6.0))
	for i in 1800:
		var to := wild.global_position - _player.global_position
		to.y = 0.0
		if to.length() <= engage_range * 0.6:
			break
		_rig.set("yaw", atan2(-to.x, -to.z))
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	for i in 10:
		await physics_frame

	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	for i in 30:
		await physics_frame

	if not bool(manager.call("is_fighting")):
		_failures.append("catch: could not enter combat; no frames to show")
		if debug_hud != null:
			debug_hud.visible = true
		return
	print("[catch] fighting; capturing the aim-chance stills...")

	await _capture_chance_frame(manager, wild, 1.0, "ui_catch_low")
	await _capture_chance_frame(manager, wild, 0.05, "ui_catch_high")

	# End the fight cleanly before the exploration-frame phase, per this
	# task's brief -- "acceptable to leave the fight running for both catch
	# shots then flee."
	if bool(manager.call("is_fighting")):
		Input.action_press("combat_run")
		await physics_frame
		await physics_frame
		Input.action_release("combat_run")
		for i in 60:
			await physics_frame

	if debug_hud != null:
		debug_hud.visible = true


## Same shape as capture_catch_sequence.gd::_capture_chance_frame, trimmed to
## this tool's own state (no MAX_ATTEMPTS retry loop -- these two stills only
## need the AIM state on screen, never a resolved throw).
func _capture_chance_frame(manager: Node, wild: Node3D, hp_fraction: float, frame_name: String) -> void:
	if not bool(manager.call("is_fighting")):
		_failures.append("%s: fight already over" % frame_name)
		return
	var inventory: RefCounted = _game.get("inventory")
	if inventory != null:
		inventory.call("add", "orb_basic", 10)
	var creature: RefCounted = manager.call("active_creature")
	if creature != null:
		creature.hp = creature.max_hp
	var foe: RefCounted = manager.call("enemy")
	foe.hp = clampf(foe.max_hp * hp_fraction, 1.0, foe.max_hp)

	if not await _open_aim(manager):
		_failures.append("%s: could not open aim" % frame_name)
		return
	for i in 15:
		await physics_frame
	_aim_at(wild)
	for i in 6:
		await physics_frame
	await _shoot(frame_name)
	# Cancel, not release -- this throw is never meant to fly.
	Input.action_press("combat_run")
	await physics_frame
	await physics_frame
	Input.action_release("combat_run")
	for i in 20:
		await physics_frame


func _open_aim(manager: Node) -> bool:
	for i in 240:
		if not bool(manager.call("is_fighting")):
			return false
		if not bool(manager.call("player_is_committed")):
			break
		await physics_frame
	var cooldown := float(CATCH.config().get("throw", {}).get("cooldown", 0.9))
	var budget := int(ceil(cooldown * float(Engine.physics_ticks_per_second))) + 120
	while budget > 0:
		Input.action_press("combat_throw")
		await physics_frame
		await physics_frame
		Input.action_release("combat_throw")
		await physics_frame
		budget -= 4
		for i in 6:
			await physics_frame
			budget -= 1
		if bool(manager.call("is_aiming")):
			return true
	return false


## capture_catch_sequence.gd's proven aim: straight at the leaded centre from
## the camera's eye.
func _aim_at(wild: Node3D) -> void:
	var camera := _rig.get_node_or_null(^"Camera3D") as Camera3D
	if camera == null:
		return
	var eye := camera.global_position
	var velocity := Vector3.ZERO
	if wild is CharacterBody3D:
		velocity = (wild as CharacterBody3D).velocity
	var release_windup := float(CATCH.config().get("throw", {}).get("release_windup", 0.18))
	var lead_time := 8.0 / float(Engine.physics_ticks_per_second) + release_windup
	var predicted: Vector3 = (wild.call("centre") as Vector3) + velocity * lead_time
	var to := predicted - eye
	_rig.set("yaw", atan2(-to.x, -to.z))
	var flat := Vector2(to.x, to.z).length()
	_rig.set("pitch", atan2(to.y, maxf(flat, 0.01)))


# --- phase 6: 720p exploration frame (shot 19) ------------------------------


func _phase_720p() -> void:
	print("[720p] resizing the window for the Ally readability proxy...")
	root.size = Vector2i(1280, 720)
	for i in 2:
		await process_frame
	await _shoot("ui_ally_720")


# --- plumbing ----------------------------------------------------------------


func _log(label: String) -> void:
	print("  [phase] %-28s +%.1fs" % [label, (Time.get_ticks_msec() - _start_ms) / 1000.0])


func _shoot(name: String) -> void:
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		_failures.append("%s: viewport returned no image" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	var error := image.save_png(path)
	if error != OK:
		_failures.append("%s: save_png failed (%d)" % [name, error])
		return
	_written.append(path)
	print("  %-22s -> %s  (+%.1fs)" % [name, path, (Time.get_ticks_msec() - _start_ms) / 1000.0])


func _finish() -> void:
	print("")
	print("%d/12 frames -> %s" % [_written.size(), OUT_DIR])
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")
	if not _failures.is_empty():
		print("")
		for line in _failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)
