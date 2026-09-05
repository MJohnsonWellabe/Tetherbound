extends SceneTree

## Explicit unlocked aerie checkpoint. Actual double-Jump and flight-controller
## inputs produce this airborne frame; no mid-flight pose writes or fake carrier.
const SCENE:=preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES:=preload("res://scripts/creatures/creature_species.gd")
const OUTPUT:="res://ralph/reports/CLOUDREACH-ENV-CORRECTION-0904/round3"

func _init() -> void:
	_run.call_deferred()

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame

func _action(name: String,pressed: bool) -> void:
	var event:=InputEventAction.new()
	event.action=name
	event.pressed=pressed
	Input.parse_input_event(event)

func _run() -> void:
	root.size=Vector2i(1280,800)
	root.content_scale_size=Vector2i(1920,1200)
	var game:=root.get_node("Game")
	game.call("reset_for_new_game")
	game.set("current_realm","cloudreach")
	game.get("progression").call("set_flag","realm_key_cloudreach")
	game.get("progression").call("set_flag","fly_traversal_unlocked")
	game.get("party").call("add",SPECIES.spawn("galecrest"))
	var world:=SCENE.instantiate()
	root.add_child(world)
	current_scene=world
	await _frames(12)
	var runtime:=world.get_node_or_null("CloudreachRuntime")
	if runtime==null or not bool(runtime.get("_mounted")):
		push_error("Refuse incomplete production Fly evidence")
		quit(1)
		return
	var player:=world.get_node("Player") as CharacterBody3D
	var rig:=world.get_node("CameraRig")
	player.global_position=Vector3(400,610.25,3250)
	player.velocity=Vector3.ZERO
	rig.global_position=player.global_position+Vector3.UP*1.55
	rig.set("yaw",atan2(-710.0,310.0))
	await _frames(12)
	_action("jump",true)
	await _frames(3)
	_action("jump",false)
	await _frames(6)
	_action("jump",true)
	await _frames(3)
	_action("jump",false)
	var fly: Node=player.get("fly_controller")
	if not fly.call("is_flying"):
		push_error("Actual double Jump did not launch production Fly")
		quit(1)
		return
	var target:=Vector3(535,760,3170)
	var reached:=false
	var history: Array[Dictionary]=[]
	for frame in 2400:
		var offset:=target-player.global_position
		if offset.length()<6.0:
			reached=true
			break
		var flat:=Vector3(offset.x,0,offset.z)
		var local: Vector3=(rig.call("planar_basis") as Basis).inverse()*flat.normalized()*clampf(flat.length()/12.0,0,1)
		Input.action_press("move_right",maxf(local.x,0))
		Input.action_press("move_left",maxf(-local.x,0))
		Input.action_press("move_back",maxf(local.z,0))
		Input.action_press("move_forward",maxf(-local.z,0))
		# A zero-strength action_press still owns the pressed action. Release the
		# real action once high enough so this fixture does not command endless lift.
		if offset.y>2:
			Input.action_press("jump")
		else:
			Input.action_release("jump")
		await physics_frame
		if frame%60==0 or not fly.call("is_flying"):
			var contacts: Array[String]=[]
			for index in player.get_slide_collision_count():
				var collision:=player.get_slide_collision(index)
				contacts.append(str(collision.get_collider().get_path())+" normal="+str(collision.get_normal()))
			var sample: Dictionary={"frame":frame,"position":str(player.global_position),"velocity":str(player.velocity),"state":fly.get("state"),"denial":fly.get("last_denial"),"stamina":player.get("vitals").get("stamina"),"contacts":contacts}
			history.append(sample)
			print("FLY TRACE ",JSON.stringify(sample))
		if not fly.call("is_flying"):
			break
	for action in ["move_right","move_left","move_back","move_forward","jump"]:
		Input.action_release(action)
	if not reached or not fly.call("is_flying"):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
		var diagnostic:=FileAccess.open(OUTPUT+"/fly-diagnostic.json",FileAccess.WRITE)
		diagnostic.store_string(JSON.stringify({"target":str(target),"updrafts":str(fly.get("updrafts")),"history":history},"  "))
		push_error("Production flight did not reach the actual airborne evidence stand")
		quit(1)
		return
	var pad:=InputEventJoypadMotion.new()
	pad.axis=JOY_AXIS_RIGHT_X
	pad.axis_value=0.5
	Input.parse_input_event(pad)
	await _frames(1)
	pad=InputEventJoypadMotion.new()
	pad.axis=JOY_AXIS_RIGHT_X
	pad.axis_value=0
	Input.parse_input_event(pad)
	var draws:=0.0
	var primitives:=0.0
	var started:=Time.get_ticks_usec()
	for frame in 24:
		await RenderingServer.frame_post_draw
		draws+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		primitives+=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT+"/shots"))
	root.get_texture().get_image().save_png(OUTPUT+"/shots/10-real-fly-silhouette.png")
	var file:=FileAccess.open(OUTPUT+"/fly-performance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"fixture":"Explicit unlocked aerie start; real double-Jump/input flight afterward","position":str(player.global_position),"flying":fly.call("is_flying"),"draw_calls":draws/24.0,"primitives":primitives/24.0,"measured_frame_ms":float(Time.get_ticks_usec()-started)/24000.0,"adapter":RenderingServer.get_video_adapter_name()},"  "))
	print("CLOUDREACH REAL FLY VISUAL PASS at ",player.global_position)
	quit(0)
