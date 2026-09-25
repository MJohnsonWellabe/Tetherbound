extends SceneTree

## Evidence frames for F06 / C1 (the summit crown's floor, the finale arena's
## edge, the co-op road ribbons) through the production camera rig following
## the real trainer.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --fixed-fps 60 --script tools/capture_cloudreach_summit_crown.gd -- --tag=after
##
## `--tag=before|after` names the output folder, so main (before) and the
## branch (after) can be shot with the same tool. `--fixed-fps 60` makes every
## frame 1/60 s of game time although only the saved frames are drawn.
##
## Disclosed fixture: the upper-route unlock and the pre-finale flags
## (Act II complete, upper anchors disabled, Officer Voss's summit-approach
## fight won) are set directly; `summit_extraction_engine_reached` is NOT set,
## so the finale does not start. Frames 1-4 stand the trainer at a viewpoint
## (one position write each). Frame 5's walk makes one position write at its
## start on the upper summit road; everything after it is stick input
## (`move_*` actions, steered through the rig's own planar basis).
##
## Frames:
##  01 the summit-approach stand (100, 5290) looking north at the crown and
##     arena; on main the trainer falls through here -- printed, still shot.
##  02 the arena deck's southern throat seen from the plateau.
##  03 a perimeter bay and the south-west watch tower, trainer beside them.
##  04 the overlook loop's east leg near (115, 5358), looking along the road.
##  05+ a stick walk (>= 30 s of motion): up the summit road onto the crown,
##     across the plateau to the arena throat, over the deck and into the
##     deck edge at a perimeter bay, where it must be blocked. A frame every
##     2.5 s; each prints the trainer's position and is_on_floor.
const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const LANE := preload("res://tools/capture_cloudreach_lane_common.gd")
const OUT_ROOT := "res://ralph/reports/CLOUDREACH-LANE/captures/summit_crown"
const ARENA := Vector3(100.0, 1160.0, 5450.0)
const DECK_RADIUS := 36.0
const STAND := Vector3(100.0, 1160.0, 5290.0)
const WALK_FRAME_EVERY := 150 # physics frames at 60 Hz: 2.5 s
const EDGE_BEARING_DEG := 120.0 # PerimeterBay08, on walkable crown

var _game: Node
var _world: Node3D
var _player: CharacterBody3D
var _rig: Node
var _frames: Array = []
var _out := ""
var _input_values: Dictionary = {}
var _walk_frames := 0
var _walk_shots := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var tag := "after"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--tag="):
			tag = arg.trim_prefix("--tag=")
	if tag not in ["before", "after"]:
		push_error("capture: --tag must be before or after, not %s" % tag)
		quit(2)
		return
	_out = "%s/%s" % [OUT_ROOT, tag]
	print("CAPTURE summit crown tag=%s out=%s" % [tag, _out])
	# Only the saved frames are drawn; the software renderer is the slow part.
	RenderingServer.render_loop_enabled = false
	_game = root.get_node(^"Game")
	_game.call("reset_for_new_game")
	_game.set("save_system", SAVE.new("user://capture_cloudreach_summit_crown/"))
	_game.set("current_realm", "cloudreach")
	for species: String in ["galecrest", "bramblebun", "mudsnout", "terrapup", "brooktail"]:
		(_game.get("party") as RefCounted).call("add", SPECIES.spawn(species))
	var flags: RefCounted = _game.get("progression")
	for flag: String in ["realm_key_cloudreach", "cloudreach_chapter_started", "cloudreach_upper_route_unlocked",
			"cloudreach_act_ii_complete", "cloudreach_upper_anchors_disabled",
			"defeated_cloudreach_officer_voss_summit_approach"]:
		flags.call("set_flag", flag)
	_world = SCENE.instantiate()
	root.add_child(_world)
	current_scene = _world
	_player = _world.get_node(^"Player") as CharacterBody3D
	_rig = _world.get_node(^"CameraRig")
	for i in 3000:
		await process_frame
		if bool(_world.call("shell_build_complete")) and i > 20:
			break
	# Let the arrival toasts time out as they would.
	await _frames_wait(600)

	# 01: the stand. Placed 0.3 m over the drawn crown, never snapped to a
	# collider, so a missing floor shows as a fall.
	_place(STAND + Vector3.UP * 0.3)
	_aim(ARENA, -8.0)
	await _physics_wait(90)
	var at := _player.global_position
	var fell := at.y < STAND.y - 1.5
	print("CAPTURE 01 stand pos=%s on_floor=%s %s" % [at, _player.is_on_floor(),
		"FELL THROUGH THE CROWN" if fell else "standing on the crown"])
	if fell:
		# Show where the stand should have held the trainer.
		_place(STAND + Vector3.UP * 0.3)
		_aim(ARENA, -8.0)
		await _frames_wait(2)
	await _shoot("01_summit_stand_to_arena")

	# 02: the throat, from the plateau south-east of the approach.
	await _stand_and_look(Vector3(116.0, 1160.0, 5392.0), Vector3(100.0, 1160.0, 5436.0), -10.0)
	await _shoot("02_arena_throat_from_plateau")

	# 03: PerimeterBay16/17 and the south-west watch tower (62.5, 5433.5), from
	# the plateau outside the ring, trainer beside them for scale.
	await _stand_and_look(Vector3(55.0, 1160.0, 5421.0), Vector3(63.0, 1161.5, 5433.0), -6.0, 18.0)
	await _shoot("03_bay_and_watch_tower")

	# 04: the overlook loop's east leg where the co-op ribbon used to wall the
	# crown, looking up the road.
	await _stand_and_look(Vector3(112.0, 1160.8, 5356.0), Vector3(170.0, 1167.0, 5380.0), -6.0, 0.0)
	await _shoot("04_overlook_east_leg")

	await _walk_sequence()
	_release()
	LANE.contact_sheet(_frames, _out + "/_sheet_summit_crown.png", 3)
	quit(0)


## ---- 05+: the stick walk --------------------------------------------------

func _walk_sequence() -> void:
	# The one position write: on the upper summit road inside the carved
	# trench, 60 % of the way up its last segment.
	var road_a := Vector3(294.9, 1080.0, 5106.4)
	var road_b := Vector3(105.1, 1160.0, 5343.6)
	_place(road_a.lerp(road_b, 0.6) + Vector3.UP * 0.3)
	await _physics_wait(30)
	var legs: Array = [
		["road", road_a.lerp(road_b, 0.9)],
		["onto_crown", Vector3(116.0, 1160.0, 5372.0)],
		["plateau", Vector3(122.0, 1160.0, 5396.0)],
		["throat", Vector3(100.0, 1160.0, 5408.0)],
		["deck", Vector3(100.0, 1160.0, 5440.0)],
	]
	for leg: Array in legs:
		var reached := await _walk_to(leg[1] as Vector3, 1800)
		print("CAPTURE walk leg %s %s at %s on_floor=%s" % [leg[0],
			"reached" if reached else "NOT reached", _player.global_position, _player.is_on_floor()])
	# Into the deck edge at a bay: from well inside the deck straight out past
	# the masonry. It must stop at the wall, not on open plateau.
	var bearing := deg_to_rad(EDGE_BEARING_DEG)
	var outward := Vector3(sin(bearing), 0.0, cos(bearing))
	await _walk_to(ARENA + outward * 30.0, 900)
	var furthest := 0.0
	var target := ARENA + outward * 48.0
	for frame in 360:
		_steer(target - _player.global_position)
		_rig.set("yaw", LANE.yaw_towards(_player.global_position, target))
		await physics_frame
		_walk_frames += 1
		furthest = maxf(furthest, _radius())
		if _walk_frames % WALK_FRAME_EVERY == 0:
			await _walk_shot("edge_push")
	_release()
	await _walk_shot("edge_push_end")
	print("CAPTURE edge push at %.0f deg: furthest r=%.2f m (deck %.0f m) -> %s; motion %.1f s over %d walk frames" % [
		EDGE_BEARING_DEG, furthest, DECK_RADIUS,
		"BLOCKED at the masonry" if furthest < 41.0 else "NOT BLOCKED: walked out onto the plateau",
		float(_walk_frames) / 60.0, _walk_shots])


func _walk_to(target: Vector3, budget: int) -> bool:
	for frame in budget:
		var offset := target - _player.global_position
		if Vector2(offset.x, offset.z).length() < 1.2:
			return true
		_steer(offset)
		_rig.set("yaw", LANE.yaw_towards(_player.global_position, target))
		await physics_frame
		_walk_frames += 1
		if _walk_frames % WALK_FRAME_EVERY == 0:
			await _walk_shot("walk")
		if _player.global_position.y < 1000.0:
			print("CAPTURE walk FELL at %s" % _player.global_position)
			return false
	return false


func _walk_shot(label: String) -> void:
	_walk_shots += 1
	var at := _player.global_position
	print("CAPTURE walk frame %02d t=%.1fs pos=(%.2f, %.2f, %.2f) on_floor=%s arena_r=%.2f" % [
		_walk_shots, float(_walk_frames) / 60.0, at.x, at.y, at.z, _player.is_on_floor(), _radius()])
	await _shoot("%02d_%s_%02d" % [4 + _walk_shots, label, _walk_shots])


func _radius() -> float:
	var at := _player.global_position
	return Vector2(at.x - ARENA.x, at.z - ARENA.z).length()


## Stick input exactly as a pad delivers it: `move_*` action strengths in the
## rig's planar frame, so the trainer's own controller does the moving.
func _input(action: String, strength: float) -> void:
	if is_equal_approx(float(_input_values.get(action, -1.0)), strength):
		return
	_input_values[action] = strength
	var event := InputEventAction.new()
	event.action = action
	event.pressed = strength > 0.0
	event.strength = strength
	Input.parse_input_event(event)


func _steer(offset: Vector3) -> void:
	offset.y = 0.0
	if offset.length_squared() < 0.0001:
		_release()
		return
	var local := (_rig.call("planar_basis") as Basis).inverse() * offset.normalized()
	_input("move_right", maxf(local.x, 0.0))
	_input("move_left", maxf(-local.x, 0.0))
	_input("move_back", maxf(local.z, 0.0))
	_input("move_forward", maxf(-local.z, 0.0))


func _release() -> void:
	for action: String in ["move_left", "move_right", "move_forward", "move_back"]:
		_input(action, 0.0)


## ---- stands and shots ------------------------------------------------------

func _place(at: Vector3) -> void:
	_player.global_position = at
	_player.velocity = Vector3.ZERO


func _aim(target: Vector3, pitch_deg: float, off_axis_deg: float = 0.0) -> void:
	_rig.set("yaw", LANE.yaw_towards(_player.global_position, target) + deg_to_rad(off_axis_deg))
	_rig.set("pitch", deg_to_rad(pitch_deg))


## `off_axis_deg` turns the view a little so the subject sits beside the
## trainer instead of hidden behind them.
func _stand_and_look(at: Vector3, target: Vector3, pitch_deg: float = -12.0,
		off_axis_deg: float = 14.0) -> void:
	var y := float(_world.call("ground_height_near", at + Vector3.UP * 3.0))
	_place(Vector3(at.x, (y if not is_nan(y) else at.y) + 0.3, at.z))
	_aim(target, pitch_deg, off_axis_deg)
	await _physics_wait(45)
	print("CAPTURE stand pos=%s on_floor=%s" % [_player.global_position, _player.is_on_floor()])


func _shoot(name: String) -> void:
	RenderingServer.render_loop_enabled = true
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	LANE.save_frame(self, _out, name, _frames)
	RenderingServer.render_loop_enabled = false


func _frames_wait(count: int) -> void:
	for i in count:
		await process_frame


func _physics_wait(count: int) -> void:
	for i in count:
		await physics_frame
