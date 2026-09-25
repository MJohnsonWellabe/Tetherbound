extends SceneTree

## Evidence frames for WO-2 (F07): the couriers' thanks at Galefoot and a
## surveyed aerie's stamina-only landing rest, through the production camera.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script tools/capture_cloudreach_activity_payoffs.gd
##
## Disclosed fixture, the same as tests/smoke_cloudreach_activity_rewards.gd:
## the courier chain's first two step flags and the High Perches survey are
## seeded, the trainer is stood at each viewpoint, and the aerie landing is the
## Fly `landed` signal emitted with the trainer on the ring. The claim itself is
## the ordinary interact press.
const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const LANE := preload("res://tools/capture_cloudreach_lane_common.gd")
const OUT := "res://ralph/reports/CLOUDREACH-LANE/captures/activity_payoffs"
const REPORT_EFFECT := "cloudreach:side:packs_on_the_wrong_side:report_to_neri"

var _game: Node
var _world: Node3D
var _player: CharacterBody3D
var _rig: Node
var _frames: Array = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_game = root.get_node(^"Game")
	_game.call("reset_for_new_game")
	_game.set("save_system", SAVE.new("user://capture_cloudreach_activity_payoffs/"))
	_game.set("current_realm", "cloudreach")
	for species: String in ["galecrest", "bramblebun", "mudsnout", "terrapup", "brooktail"]:
		(_game.get("party") as RefCounted).call("add", SPECIES.spawn(species))
	var flags: RefCounted = _game.get("progression")
	for flag: String in ["realm_key_cloudreach", "cloudreach_chapter_started", "cloudreach_crisis_learned",
			"causeway_survivors_reconnected", "side_courier_pack_recovered", "side_courier_medicine_delivered"]:
		flags.call("set_flag", flag)
	_world = SCENE.instantiate()
	root.add_child(_world)
	current_scene = _world
	_player = _world.get_node(^"Player") as CharacterBody3D
	_rig = _world.get_node(^"CameraRig")
	for i in 600:
		await process_frame
		if _world.get_node_or_null(^"EncounterDirector") != null and i > 20:
			break
	await _frames_wait(20)
	_game.call("save_game", 0)
	var physical: Node = _world.get_node(^"CloudreachChapter").get("_physical")

	# Stands chosen by probing a ring around each subject for floor, a clear
	# trainer capsule and line of sight from the rig's camera position.
	var thanks := Vector3(-288.0, 180.0, 516.0)
	var thanks_stand := Vector3(-282.0, 180.03, 516.0)
	await _stand_and_look(thanks_stand, thanks)
	LANE.save_frame(self, OUT, "01_galefoot_before_report", _frames)
	physical.call("consume_dialogue_effect", REPORT_EFFECT)
	await _frames_wait(15)
	await _stand_and_look(thanks_stand, thanks)
	LANE.save_frame(self, OUT, "02_galefoot_thanks_offered", _frames)
	await _stand_and_look(thanks + Vector3(1.4, 0.0, 0.0), thanks, 30.0)
	LANE.save_frame(self, OUT, "03_galefoot_thanks_prompt", _frames)
	Input.action_press("interact")
	await _frames_wait(2)
	Input.action_release("interact")
	await _frames_wait(20)
	LANE.save_frame(self, OUT, "04_galefoot_after_claim", _frames)

	flags.call("set_flag", "fly_traversal_unlocked")
	flags.call("set_flag", "side_aerie_high_perches_surveyed")
	var aerie := Vector3(900.0, 1020.0, 2700.0)
	await _stand_and_look(Vector3(907.0, 1020.13, 2700.0), aerie)
	LANE.save_frame(self, OUT, "05_high_perches_surveyed_aerie", _frames)
	await _stand_and_look(aerie + Vector3(1.5, 0.0, 0.0), aerie + Vector3(-12.0, 0.0, 0.0))
	var vitals: RefCounted = _player.get("vitals")
	vitals.set("stamina", 12.0)
	await _frames_wait(20)
	LANE.save_frame(self, OUT, "06_aerie_landing_before_low_stamina", _frames)
	(_player.get("fly_controller") as Node).emit_signal("landed", _player.global_position, "galecrest")
	await _frames_wait(20)
	LANE.save_frame(self, OUT, "07_aerie_landing_after_stamina_restored", _frames)
	LANE.contact_sheet(_frames, OUT + "/_sheet_activity_payoffs.png", 3)
	quit(0)


## `off_axis_deg` turns the view a little so the subject sits beside the
## trainer instead of hidden behind them.
func _stand_and_look(at: Vector3, target: Vector3, off_axis_deg: float = 16.0) -> void:
	var y := float(_world.call("ground_height_near", at + Vector3.UP * 3.0))
	_player.global_position = Vector3(at.x, (y if not is_nan(y) else at.y) + 0.3, at.z)
	_player.velocity = Vector3.ZERO
	_rig.set("yaw", LANE.yaw_towards(_player.global_position, target) + deg_to_rad(off_axis_deg))
	_rig.set("pitch", deg_to_rad(-12.0))
	await _frames_wait(30)


func _frames_wait(count: int) -> void:
	for i in count:
		await process_frame
