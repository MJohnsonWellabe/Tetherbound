extends SceneTree

## Evidence frames for the F07#2 chain-bridge stall fix: the Windscar chain
## bridge deck where it passes UNDER the windscar_counterweight_pass shoulder
## (the old stall point, (-397.5, 446.9, 2931.5)), through the production
## CameraRig following the real trainer standing on the deck.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --fixed-fps 60 --script tools/capture_cloudreach_chainbridge.gd \
##     -- --tag=after
##
## Frames (ralph/reports/CLOUDREACH-LANE/chainbridge-stall/captures/<tag>/):
##   01  on the deck approaching the crossing, looking along the deck;
##   02  on the deck under the counterweight-pass shoulder (the stall point);
##   03  past the crossing, looking back along the deck;
##   04  from the bridge's west landing, the whole crossing in view.
## Each record (manifest.json) logs where the trainer and camera stand and
## what collider is underfoot; the frames themselves are the visual evidence.
##
## Disclosed fixture: `realm_key_cloudreach` and `fly_traversal_unlocked` are
## seeded; the trainer is stood at each viewpoint (a relocation, not a walk)
## and the rig is aimed the way a player's stick would aim it. Never combine
## `--headless` with a rendering driver (WORKFLOW §7).
const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SAVE := preload("res://scripts/save/save_game.gd")
const LANE := preload("res://tools/capture_cloudreach_lane_common.gd")
const OUT_ROOT := "res://ralph/reports/CLOUDREACH-LANE/chainbridge-stall/captures"
const DECK_A := Vector3(-520.0, 430.0, 2720.0)
const DECK_B := Vector3(-300.0, 460.0, 3100.0)
const STALL_T := 0.557

var _game: Node
var _world: Node3D
var _player: CharacterBody3D
var _rig: Node
var _fly: Node
var _frames: Array = []
var _out := OUT_ROOT + "/after"
var _records: Array = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--tag="):
			_out = OUT_ROOT + "/" + argument.trim_prefix("--tag=")
	if DisplayServer.get_name() == "headless":
		push_error("capture: needs a rendering display")
		quit(1)
		return
	RenderingServer.render_loop_enabled = false
	_game = root.get_node(^"Game")
	_game.call("reset_for_new_game")
	_game.set("save_system", SAVE.new("user://capture_cloudreach_chainbridge/"))
	_game.set("current_realm", "cloudreach")
	_game.set("pending_realm_entry", "")
	_game.set("saved_player_pose", {})
	var flags: RefCounted = _game.get("progression")
	for flag: String in ["realm_key_cloudreach", "fly_traversal_unlocked"]:
		flags.call("set_flag", flag)
	_world = SCENE.instantiate()
	root.add_child(_world)
	current_scene = _world
	_player = _world.get_node(^"Player") as CharacterBody3D
	_rig = _world.get_node(^"CameraRig")
	_fly = _player.get("fly_controller")
	for i in 3600:
		await process_frame
		if bool(_world.call("shell_build_complete")) and i > 20:
			break
	if not bool(_world.call("shell_build_complete")):
		push_error("capture: Cloudreach did not build")
		quit(1)
		return
	await _frames_wait(600)
	var along := (DECK_B - DECK_A)
	await _stand_and_look(_deck(0.36), _deck(0.75) + Vector3.UP * 6.0, 0.0, -6.0)
	await _shoot("01_approaching_the_crossing")
	await _stand_and_look(_deck(STALL_T), _deck(0.80) + Vector3.UP * 20.0, 0.0, 4.0)
	await _shoot("02_under_the_shoulder")
	await _stand_and_look(_deck(0.74), _deck(0.40) + Vector3.UP * 6.0, 0.0, -6.0)
	await _shoot("03_looking_back")
	await _stand_and_look(_deck(0.08), _deck(STALL_T) + Vector3.UP * 20.0, 12.0, -4.0)
	await _shoot("04_from_the_west_landing")
	print("CAPTURE deck direction %s" % along.normalized())
	LANE.contact_sheet(_frames, _out + "/_sheet.png", 2)
	var file := FileAccess.open(_out + "/manifest.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"records": _records,
			"fixture": "Production Cloudreach world, player, CameraRig and WorldLook; trainer stood on the chain-bridge deck at each viewpoint; realm_key_cloudreach + fly_traversal_unlocked seeded."}, "\t") + "\n")
		file.close()
	quit(0)


func _deck(t: float) -> Vector3:
	return DECK_A.lerp(DECK_B, t)


func _stand_and_look(at: Vector3, target: Vector3, off_axis_deg: float, pitch_deg: float) -> void:
	var y := float(_world.call("ground_height_near", at + Vector3.UP * 3.0))
	if _fly != null:
		if bool(_fly.call("is_flying")):
			_fly.call("recover_to_anchor", "capture relocation")
		_fly.call("clear_recovery_anchor")
	_player.global_position = Vector3(at.x, (y if not is_nan(y) else at.y) + 0.3, at.z)
	_player.velocity = Vector3.ZERO
	_rig.set("yaw", LANE.yaw_towards(_player.global_position, target) + deg_to_rad(off_axis_deg))
	_rig.set("pitch", deg_to_rad(pitch_deg))
	await _frames_wait(40)


func _shoot(name: String) -> void:
	RenderingServer.render_loop_enabled = true
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	LANE.save_frame(self, _out, name, _frames)
	RenderingServer.render_loop_enabled = false
	var space := _player.get_world_3d().direct_space_state
	var down := PhysicsRayQueryParameters3D.create(_player.global_position + Vector3.UP * 0.5,
		_player.global_position + Vector3.DOWN * 4.0)
	down.exclude = [_player.get_rid()]
	var hit := space.intersect_ray(down)
	var camera := _world.get_node(^"CameraRig/Camera3D") as Camera3D
	var record := {"frame": name, "player": str(_player.global_position),
		"camera": str(camera.global_position),
		"standing_on": str((hit.get("collider") as Node).get_path()) if hit.has("collider") else "",
		"on_floor": _player.is_on_floor()}
	_records.append(record)
	print("CAPTURE record " + JSON.stringify(record))


func _frames_wait(count: int) -> void:
	for i in count:
		await process_frame
