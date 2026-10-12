extends "res://tools/art_pipeline/capture_named_fight.gd"

## F04#6 visual-proof frames: each Meadows named-fight win's aftermath, live
## and again after a real save -> free world -> load -> rebuilt world.
##
## Why a new tool: `capture_named_fight.gd --resolve=won --face-trainer`
## frames a trainer's live aftermath (struck standard, stand-down, victory
## tokens) but not the world changes that follow a win somewhere else in the
## world (the Hall shutters, the relay console's drain fade, Old Mill Crossing,
## the Warrens vault door), and nothing frames any of them after a reload.
## This file reuses that tool's challenge, resolve and aftermath path and adds
## those sites plus the reload pass. Evidence only: nothing is asserted.
##
## Live, per trainer (order matters: Dell before Vance):
##   `<tid>-00-before`, `<tid>-NN` (two in-fight frames), `<tid>-rNN` (the
##   resolve), `<tid>-aNN` (aftermath, facing the trainer), `<tid>-99-after`;
##   for stronghold_elite and warden_aldis also `<tid>-shutter-before/after`.
## After Vance: `relay_console-*` (the console press and its 12 s drain fade)
## and `mill_crossing-*` (the gate opened with the gear the rescue gives).
## Last: `warrens_vault-*` (the guardian won by tools/combat_pilot.gd input,
## then the den facing the vault door while it sinks).
## Reload pass (`reload/`): the same sites in a rebuilt world from the saved
## slot.
##
## DISCLOSED shortcuts, each also printed to the log:
## - trainer fights are ended by combat_manager's own `_begin_resolve("won")`
##   (the capture_named_fight.gd shortcut); everything after is production;
## - the relay console is pressed by calling the relay's `_on_console_used()`
##   (what its interaction prompt runs) with the player stood at the console;
## - `mill_bridge_gear` is put in the inventory directly (the captive rescue
##   that hands it over is not walked) and the gate is tried through
##   `gated_crossing.gd::_on_tried()` (what its prompt runs);
## - stand spots are teleports; the guardian fight starts with the player
##   placed in the den and the director's aggressive-engage entry (the same
##   fixture placement tests/smoke_warrens.gd declares), the ally is a
##   level-30 fixture Terrapup enrolled in Game.party.
##
##   XDG_DATA_HOME=$(mktemp -d) xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/capture_f04_6_aftermaths.gd -- --out=/abs/dir \
##     [--trainers=relay_officer_dell,...] [--no-guardian] [--no-reload]

const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const AFTERMATH := preload("res://scripts/world/trainer_aftermath.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const COMBAT_PILOT := preload("res://tools/combat_pilot.gd")
const SAVE_DIR := "user://f04_6_aftermath_capture/"
const SLOT := 5
const DEFAULT_TRAINERS := ["relay_officer_dell", "relay_captain", "captain_riverwatch",
	"captain_field", "captain_ridge", "stronghold_elite", "warden_aldis"]
const SHUTTERS := {
	"stronghold_elite": "BlastShutter_defeated_stronghold_elite",
	"warden_aldis": "BlastShutter_defeated_warden",
}
const GUARDIAN_LEVEL := 30
const STAND_RADII := [6.0, 9.0, 12.0, 4.0]

var _root_out := ""
var _game: Node = null


func _run() -> void:
	var ids: Array = DEFAULT_TRAINERS.duplicate()
	var guardian := true
	var reload := true
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_root_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--trainers="):
			ids = Array(arg.trim_prefix("--trainers=").split(",", false))
		elif arg == "--no-guardian":
			guardian = false
		elif arg == "--no-reload":
			reload = false
	if _root_out.is_empty() or DisplayServer.get_name() == "headless":
		push_error("needs --out=<absolute dir> and a rendering display")
		quit(1)
		return
	_resolve_won = true
	_face_trainer = true
	_keep_alive = true
	_frames = 2
	_interval = 0.6
	_after_frames = 10
	# _run starts from _init, before the autoloads are in the tree.
	await process_frame
	_game = root.get_node_or_null(^"/root/Game")
	if _game == null:
		push_error("no Game autoload")
		quit(1)
		return
	_game.call("reset_for_new_game")
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	_game.set("save_system", SAVE_GAME.new(SAVE_DIR))
	await _boot_world()
	await _ensure_ally()
	_enrol_ally()
	_set_out("live")
	for id: String in ids:
		_tid = id
		_spec = TRAINERS.trainer(_tid)
		if _spec.is_empty():
			print("SKIP %s: no such trainer" % _tid)
			continue
		if SHUTTERS.has(_tid):
			await _frame_shutter("shutter-before")
		if _tid == "warden_aldis":
			if _collect_nodes():
				await _frame_warden_banners("banners-before")
		elif _collect_nodes():
			await _frame_site_object("site-before")
		if not await _capture_one():
			print("FAIL live %s: capture_one returned false" % _tid)
		await _frame_site_object("site-after")
		if _tid == "warden_aldis":
			await _frame_warden_banners("banners-after")
		elif SHUTTERS.has(_tid):
			await _frame_shutter("shutter-after")
		if _tid == "relay_captain":
			await _relay_console(true)
			await _mill_crossing(true)
	if guardian:
		await _warrens_vault(true)
	if not reload:
		quit(0)
		return
	# A real round trip: the saved slot is read back into Game and a second
	# world is built from nothing, as a Continue does.
	print("reload: save_game(%d) -> %s" % [SLOT, str(_game.call("save_game", SLOT))])
	_world.queue_free()
	for i in 12:
		await physics_frame
	print("reload: load_game(%d) -> %s" % [SLOT, str(_game.call("load_game", SLOT))])
	await _boot_world()
	_set_out("reload")
	for id: String in ids:
		_tid = id
		_spec = TRAINERS.trainer(_tid)
		if _spec.is_empty() or not _collect_nodes():
			continue
		_stand_in_front_of_the_trainer()
		if not await _settle_on_ground():
			continue
		for i in 45:
			await physics_frame
		_look_at_trainer()
		for i in 20:
			await physics_frame
		await _save("reload")
		if SHUTTERS.has(_tid):
			await _frame_shutter("shutter-reload")
		if _tid == "relay_captain":
			await _relay_console(false)
			await _mill_crossing(false)
	if guardian:
		await _warrens_vault(false)
	quit(0)


func _boot_world() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as SpringArm3D
	_camera = _rig.get_node_or_null(^"Camera3D") as Camera3D if _rig != null else null
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_panel = _world.get_node_or_null(^"DialoguePanel")


func _set_out(phase: String) -> void:
	_out = _root_out.path_join(phase)
	DirAccess.make_dir_recursive_absolute(_out)


## The production wild start admits only an ally the character owns; the real
## starter ceremony enrols it in Game.party (tests/smoke_warrens.gd fixture).
func _enrol_ally() -> void:
	var ally: RefCounted = _director.call("ally_instance")
	var party: RefCounted = _game.get("party")
	if ally != null and party != null and (party.call("members") as Array).is_empty():
		party.call("add", ally)


## Stand the player on floor near `target` with a clear line to it, then turn
## the production rig toward it. Tries rings of spots around the target and
## takes the first whose floor is near the target's own level.
func _stand_facing(target: Vector3, prefer_from: Vector3 = Vector3.INF) -> bool:
	var space := _player.get_world_3d().direct_space_state
	var candidates: Array[Vector3] = []
	if prefer_from.is_finite():
		candidates.append(prefer_from)
	for radius: float in STAND_RADII:
		for k in 12:
			var a := TAU * float(k) / 12.0
			candidates.append(target + Vector3(sin(a), 0.0, cos(a)) * radius)
	for spot: Vector3 in candidates:
		var down := PhysicsRayQueryParameters3D.create(
			Vector3(spot.x, target.y + 6.0, spot.z), Vector3(spot.x, target.y - 8.0, spot.z))
		down.exclude = [_player.get_rid()]
		var hit := space.intersect_ray(down)
		if hit.is_empty() or absf((hit.position as Vector3).y - target.y) > 3.0:
			continue
		var eye := (hit.position as Vector3) + Vector3.UP * 1.6
		var sight := PhysicsRayQueryParameters3D.create(eye, target + Vector3.UP * 0.5)
		sight.exclude = [_player.get_rid()]
		var blocked := space.intersect_ray(sight)
		if not blocked.is_empty() and (blocked.position as Vector3).distance_to(target) > 1.5:
			continue
		_player.global_position = (hit.position as Vector3) + Vector3.UP * 0.2
		_player.velocity = Vector3.ZERO
		var to := target - _player.global_position
		to.y = 0.0
		if to.length() > 0.05:
			_rig.set("yaw", atan2(-to.x, -to.z))
		for i in 30:
			await physics_frame
		_rig.set("yaw", atan2(-to.x, -to.z))
		for i in 15:
			await physics_frame
		return true
	print("NO STAND SPOT near %s" % str(target))
	return false


func _frame_shutter(tag: String) -> void:
	var shutter := _world.find_child(str(SHUTTERS[_tid]), true, false) as Node3D
	if shutter == null:
		print("NO SHUTTER %s for %s" % [str(SHUTTERS[_tid]), _tid])
		return
	print("shutter %s visible=%s at %s" % [shutter.name, str(shutter.is_visible_in_tree()), str(shutter.global_position)])
	if await _stand_facing(shutter.global_position):
		await _save(tag)


func _relay_console(live: bool) -> void:
	var relay: Node3D = null
	for node: Node in _world.find_children("*", "Node3D", true, false):
		if node.has_method("console_flag"):
			relay = node as Node3D
			break
	var console := relay.find_child("Console", true, false) as Node3D if relay != null else null
	if console == null:
		print("NO RELAY CONSOLE")
		return
	var keep := _tid
	_tid = "relay_console"
	if not await _stand_facing(console.global_position):
		_tid = keep
		return
	if not live:
		await _save("reload")
		await _frame_relay_yard(relay, "reload-yard")
		_tid = keep
		return
	await _save("before-press")
	print("relay console: DISCLOSED _on_console_used() (the prompt's own handler), flag before=%s" % str(relay.call("console_flag")))
	relay.call("_on_console_used")
	var t := 0.0
	for at: float in [0.5, 3.0, 6.0, 9.0, 12.0, 14.0]:
		while t < at:
			await physics_frame
			t += 1.0 / Engine.physics_ticks_per_second
		await _save("press+%04.1fs" % at)
	await _frame_relay_yard(relay, "yard-after")
	_tid = keep


func _frame_relay_yard(relay: Node3D, tag: String) -> void:
	if await _stand_facing(relay.global_position):
		await _save(tag)


func _mill_crossing(live: bool) -> void:
	var mill: Node3D = null
	for node: Node in _world.find_children("*", "Node3D", true, false):
		if node.has_method("crossing_centre") and str(node.get("flag_id")) == "mill_crossing_restored":
			mill = node as Node3D
			break
	if mill == null:
		print("NO MILL CROSSING")
		return
	var keep := _tid
	_tid = "mill_crossing"
	var centre2: Vector2 = mill.call("crossing_centre")
	var near2: Vector2 = mill.call("near_point", 10.0)
	var centre := Vector3(centre2.x, mill.global_position.y, centre2.y)
	var near := Vector3(near2.x, mill.global_position.y, near2.y)
	if not await _stand_facing(centre, near):
		_tid = keep
		return
	if not live:
		await _save("reload")
		_tid = keep
		return
	await _save("before")
	var inventory: RefCounted = _game.get("inventory")
	inventory.call("add", "mill_bridge_gear", 1)
	print("mill crossing: DISCLOSED gear granted directly; _on_tried() (the prompt's own handler)")
	mill.call("_on_tried")
	for at in [10, 60]:
		for i in at:
			await physics_frame
		await _save("tried+%dframes" % at)
	print("mill crossing open=%s" % str(mill.call("is_open")))
	_tid = keep


func _warrens_vault(live: bool) -> void:
	var warrens := _world.get_node_or_null(^"BurrowWarrens") as Node3D
	if warrens == null:
		print("NO WARRENS")
		return
	_tid = "warrens_vault"
	var door := warrens.find_child("VaultDoorBody", true, false) as Node3D
	var den: Vector3 = warrens.call("marker", "den")
	if not live:
		if door != null and await _stand_facing(door.global_position, den):
			await _save("reload")
		print("reload: guardian present=%s" % str(warrens.call("guardian") != null))
		return
	var guardian := warrens.call("guardian") as Node3D
	if guardian == null or door == null:
		print("NO GUARDIAN or VAULT DOOR (guardian=%s door=%s)" % [str(guardian), str(door)])
		return
	var ally: RefCounted = _director.call("ally_instance")
	var progression := {}
	var file := FileAccess.open("res://data/config/progression.json", FileAccess.READ)
	if file != null:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		progression = parsed if parsed is Dictionary else {}
	ally.call("set_level", GUARDIAN_LEVEL, progression)
	ally.call("heal_fully")
	for resident: Node3D in warrens.call("population"):
		if is_instance_valid(resident):
			resident.set("aggressive", false)
			resident.set_physics_process(false)
	guardian.global_position = warrens.call("marker", "guardian")
	if await _stand_facing(door.global_position, den):
		await _save("before")
	_player.global_position = den + Vector3.UP
	_player.velocity = Vector3.ZERO
	print("warrens: DISCLOSED den placement + director aggressive-engage entry; level-%d fixture ally" % GUARDIAN_LEVEL)
	_director.call("_on_wild_wants_to_engage", guardian)
	for i in 120:
		if bool(_manager.call("is_fighting")):
			break
		await physics_frame
	if not bool(_manager.call("is_fighting")):
		print("FAIL warrens: fight did not start")
		return
	var pilot := COMBAT_PILOT.new(self, _manager, _director, _rig)
	pilot.pilot = COMBAT_PILOT.Pilot.SPACER
	pilot.listen()
	var result: Dictionary = await pilot.fight_to_the_end()
	print("warrens: pilot outcome=%s hits_dealt=%d" % [str(result.get("outcome", "")), pilot.hits_dealt])
	# The door sinks over open_seconds (1.4 s) from the clear; frame the den
	# toward it straight away and through the sink.
	var to := door.global_position - _player.global_position
	to.y = 0.0
	_rig.set("yaw", atan2(-to.x, -to.z))
	for at in [2, 20, 45, 80, 140]:
		for i in at:
			await physics_frame
		await _save("cleared+%dframes" % at)
	if await _stand_facing(door.global_position, den):
		await _save("after")


## The trainer's own site after the win: the fallen standard's cloth, the
## Sigil stone and the site's touch, framed from the road side of the post.
func _frame_site(tag: String) -> void:
	if _trainer == null or not is_instance_valid(_trainer):
		return
	var points: Array[Vector3] = []
	for key: String in [AFTERMATH.FALLEN_META, AFTERMATH.STONE_META, AFTERMATH.TOUCH_META]:
		if not _trainer.has_meta(key):
			continue
		var node: Variant = _trainer.get_meta(key)
		if node is Node3D and is_instance_valid(node) and (node as Node3D).is_visible_in_tree():
			var box := RENDER_BOUNDS.measure(node as Node3D)
			if box.size != Vector3.ZERO:
				points.append(box.get_center())
	if points.is_empty():
		return
	var centre := Vector3.ZERO
	for p: Vector3 in points:
		centre += p
	centre /= float(points.size())
	centre.y = _trainer.global_position.y
	var home: Transform3D = _trainer.get_meta(AFTERMATH.HOME_META) if _trainer.has_meta(AFTERMATH.HOME_META) else _trainer.global_transform
	var yaw := home.basis.get_euler().y
	var from := centre + Vector3(sin(yaw), 0.0, cos(yaw)) * 7.5
	print("site %s: %d aftermath pieces around %s" % [_tid, points.size(), str(centre)])
	# The player's own creature follows into the shot; put it away first with
	# the ordinary recall input so the site itself is in frame.
	await _press("creature_recall")
	for i in 30:
		await physics_frame
	if await _stand_facing(centre, from):
		await _save(tag)
	if _director != null and _director.has_method("summon_active_creature") and _director.call("ally_body") == null:
		await _director.call("summon_active_creature")


## F04#6 r8: each fight's own site object, framed before the fight and after
## it from ONE capture camera per trainer (cached on the first frame), so the
## pair differs only by what the win changed. Staging, disclosed: the follower
## is put away (the director's own dismiss) and the HUD is hidden for these
## two frames only.
var _site_cams: Dictionary = {}
var _site_centres: Dictionary = {}

func _frame_site_object(tag: String) -> void:
	if _trainer == null or not is_instance_valid(_trainer):
		return
	if not _site_cams.has(_tid):
		var points: Array[Vector3] = []
		for key: String in [AFTERMATH.SITE_BEFORE_META, AFTERMATH.STONE_META]:
			if not _trainer.has_meta(key):
				continue
			var node: Variant = _trainer.get_meta(key)
			if node is Node3D and is_instance_valid(node):
				var box := RENDER_BOUNDS.measure(node as Node3D)
				if box.size != Vector3.ZERO:
					points.append(box.get_center())
		if points.is_empty():
			print("site %s: no site object" % _tid)
			return
		var centre := Vector3.ZERO
		for p: Vector3 in points:
			centre += p
		centre /= float(points.size())
		var home: Transform3D = _trainer.get_meta(AFTERMATH.HOME_META) if _trainer.has_meta(AFTERMATH.HOME_META) else _trainer.global_transform
		var yaw := home.basis.get_euler().y
		var forward := Vector3(sin(yaw), 0.0, cos(yaw))
		var right := Vector3(-cos(yaw), 0.0, sin(yaw))
		var eye := centre + forward * 6.5 - right * 1.5 + Vector3.UP * 3.0
		var cam_xform := Transform3D(Basis(), eye).looking_at(centre + Vector3.UP * 0.7, Vector3.UP)
		_site_cams[_tid] = cam_xform
		_site_centres[_tid] = centre
		print("site %s: camera %s -> %s" % [_tid, str(eye), str(centre)])
	# r8 render: nearby ground detail streams around the PLAYER, so a before
	# frame taken with the player elsewhere showed Vance's paved yard as blurred
	# grass. Stand the player at the site first (hidden for the frame itself).
	if tag.ends_with("before") and _site_centres.has(_tid):
		var at: Vector3 = _site_centres[_tid]
		await _stand_facing(at, at + Vector3(1.5, 0.0, 1.5))
		for i in 60:
			await physics_frame
	if _director != null and _director.call("ally_body") != null and _director.has_method("dismiss_active_creature"):
		_director.call("dismiss_active_creature")
		for i in 30:
			await physics_frame
	# r8 render: the gameplay rig re-took the camera, so the pair was framed
	# from two different places with the HUD prompt in one. The rig is paused,
	# the site camera re-asserted every frame, and every UI layer hidden.
	var layers: Array[CanvasLayer] = []
	for node: Node in root.find_children("*", "CanvasLayer", true, false):
		var layer := node as CanvasLayer
		if layer.visible:
			layers.append(layer)
			layer.visible = false
	var rig_mode := _rig.process_mode if _rig != null else Node.PROCESS_MODE_INHERIT
	if _rig != null:
		_rig.process_mode = Node.PROCESS_MODE_DISABLED
	var cam := Camera3D.new()
	cam.name = "SiteCaptureCamera"
	cam.fov = 60.0
	root.add_child(cam)
	cam.global_transform = _site_cams[_tid]
	var previous := root.get_viewport().get_camera_3d()
	# Staging, disclosed: the player is hidden for the site pair (r8 render:
	# the trainer walked into Vance's after frame), and the first frame of a
	# pair waits for terrain textures to stream in, so the before frame is not
	# a blurred low-detail ground under the same camera.
	var player_was_visible := _player != null and _player.visible
	if _player != null:
		_player.visible = false
	var settle := 240 if tag.ends_with("before") else 30
	for i in settle:
		cam.current = true
		await process_frame
	# r8 render: after the fight the conversation camera's talk shot (narrower
	# FOV) re-took the view between the check and the grab. Pause the tree for
	# the frame itself: rendering continues, no other camera logic runs.
	paused = true
	cam.current = true
	for i in 3:
		await process_frame
	cam.current = true
	print("site %s %s: camera=%s current=%s" % [_tid, tag, str(cam.global_position),
		str(root.get_viewport().get_camera_3d() == cam)])
	await _save(tag)
	paused = false
	if _player != null and player_was_visible:
		_player.visible = true
	for layer: CanvasLayer in layers:
		if is_instance_valid(layer):
			layer.visible = true
	if _rig != null:
		_rig.process_mode = rig_mode
	if previous != null and is_instance_valid(previous):
		previous.current = true
	cam.queue_free()
	if _director != null and _director.has_method("summon_active_creature") and _director.call("ally_body") == null:
		await _director.call("summon_active_creature")


## The Warden arena's banner wall (gone once he is beaten), framed from the
## arena floor: target the wall at standing height, not the banner tops.
func _frame_warden_banners(tag: String) -> void:
	var stronghold: Node = null
	for node: Node in _world.find_children("*", "Node3D", true, false):
		if node.get("_warden_banners") != null:
			stronghold = node
			break
	if stronghold == null:
		print("NO STRONGHOLD BANNERS")
		return
	var banners: Array = stronghold.get("_warden_banners")
	if banners.is_empty():
		return
	var centre := Vector3.ZERO
	for b: Variant in banners:
		centre += (b as Node3D).global_position
	centre /= float(banners.size())
	var floor_y := _trainer.global_position.y if _trainer != null else centre.y
	var target := Vector3(centre.x, floor_y + 1.0, centre.z)
	var from := _trainer.global_position if _trainer != null else Vector3.INF
	print("warden banners: %d, visible=%s" % [banners.size(), str((banners[0] as Node3D).is_visible_in_tree())])
	if await _stand_facing(target, from):
		_rig.set("pitch", deg_to_rad(18.0))
		for i in 20:
			await physics_frame
		await _save(tag)
