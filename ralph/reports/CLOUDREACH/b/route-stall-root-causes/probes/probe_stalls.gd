extends SceneTree

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const FLAGS: Array[String] = ["warden_defeated", "realm_key_cloudreach",
	"realm_heart_meadows_earned", "realm_heart_meadows_placed", "realm_gate_cloudreach_unlocked",
	"cloudreach_chapter_started", "cloudreach_crisis_learned",
	"storm_anchor_lower_west_mapped", "cloudreach_lower_anchors_investigated",
	"defeated_cloudreach_senn", "causeway_survivors_reconnected",
	"completed_cloudreach_maela_trial_battle", "windscar_aerie_prepared",
	"cloudreach_act_i_complete", "fly_traversal_unlocked", "sky_shrine_reached"]

var game: Node
var world: Node3D
var player: CharacterBody3D
var mode := "shrine"

func _init() -> void:
	_run.call_deferred()

func _frames(n: int) -> void:
	for i in n:
		await physics_frame

func _input_a(action: String, s: float) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = s > 0
	e.strength = s
	Input.parse_input_event(e)

func _steer(offset: Vector3, strength: float = 1.0) -> void:
	offset.y = 0
	var local := (world.get_node("CameraRig").planar_basis() as Basis).inverse() * offset.normalized() * strength
	_input_a("move_right", maxf(local.x,0)); _input_a("move_left",maxf(-local.x,0))
	_input_a("move_back",maxf(local.z,0)); _input_a("move_forward",maxf(-local.z,0))

func _release() -> void:
	for a in ["move_left","move_right","move_forward","move_back"]: _input_a(a, 0)

func _cols() -> Array:
	var out := []
	for i in player.get_slide_collision_count():
		var c := player.get_slide_collision(i)
		for j in c.get_collision_count():
			out.append("%d.%d %s n=%s d=%.4f" % [i, j, str(c.get_collider(j).get_path()).get_file() if c.get_collider(j) is Node else "?", str(c.get_normal(j)), c.get_depth()])
	return out

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="): mode = arg.trim_prefix("--mode=")
	game = root.get_node("Game")
	game.reset_for_new_game()
	var flags := FLAGS.duplicate()
	if mode != "shrine": flags.append("cloudreach_upper_route_unlocked")
	for f in flags: game.progression.set_flag(f)
	for species in ["sparkit", "mudsnout", "bramblebun", "terrapup", "brooktail"]:
		var m: RefCounted = SPECIES.spawn(species)
		m.set_level(25, PROGRESSION.config())
		game.party.add(m)
	game.current_realm = "cloudreach"
	var t0 := Time.get_ticks_msec()
	world = SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	print("PROBE built in ", Time.get_ticks_msec()-t0, " ms; engine=", ProjectSettings.get_setting("physics/3d/physics_engine"), " server=", PhysicsServer3D.get_class())
	player = world.get_node("Player")
	await _frames(20)
	var enc: Dictionary = world.get_node("CloudreachRuntime").director.encounter_config
	for site in enc.get("wild_sites", []):
		print("PROBE site ", site.id, " resolved=", site.position)
	for p in [Vector3(970,1050,3450), Vector3(220,556,3333), Vector3(900,1020,2700)]:
		print("PROBE ground_height_near ", p, " = ", world.ground_height_near(p), " resolve=", world.call("_resource_position", p))
	print("PROBE safe_margin=", player.safe_margin, " max_slides=", player.max_slides, " floor_snap=", player.floor_snap_length)
	if mode == "shrine": await _shrine()
	elif mode == "b2": await _b2()
	quit(0)

func _wilds_near(at: Vector3, r: float) -> Array:
	var out := []
	for n in world.get_children():
		if n is CharacterBody3D and n != player and n.global_position.distance_to(at) < r:
			out.append("%s sp=%s pos=%s home=%s rad=%.2f vis=%s phys=%s" % [n.name, str(n.get("species_id")), str(n.global_position), str(n.get("home")), float(n.call("body_radius")) if n.has_method("body_radius") else -1.0, n.visible, n.is_physics_processing()])
	return out

func _shrine() -> void:
	var target := Vector3(1121.0, 1050.0, 2938.5)
	# Static geometry near the recorded pose
	var shrine := world.find_child("SkyShrineHeartstone", true, false) as Node3D
	print("PROBE shrine root ", shrine.global_position if shrine else "none")
	for c in shrine.get_children():
		if c is Node3D and c.has_node("Collision"):
			var cs: CollisionShape3D = c.get_node("Collision").get_child(0)
			if cs and cs.shape is BoxShape3D:
				print("PROBE shrine box ", c.name, " centre=", c.global_position, " size=", (cs.shape as BoxShape3D).size)
	var starts := [Vector3(1099.003, 1051.301, 2941.399), Vector3(1099.0, 1051.35, 2943.0), Vector3(1098.9, 1051.35, 2941.5), Vector3(1099.0, 1051.35, 2941.2), Vector3(1110, 1051.35, 2940)]
	for s in starts:
		_release()
		await _frames(5)
		player.global_position = s
		player.velocity = Vector3.ZERO
		await _frames(10)
		print("PROBE === start ", s, " settled ", player.global_position, " on_floor=", player.is_on_floor(), " wilds<40m=", _wilds_near(s, 40))
		# direct test_move diagnostics at the pose
		var params := PhysicsTestMotionParameters3D.new()
		params.from = player.global_transform
		params.motion = Vector3(4.957, 0, -0.653) / 60.0
		params.max_collisions = 6
		var res := PhysicsTestMotionResult3D.new()
		var hit := PhysicsServer3D.body_test_motion(player.get_rid(), params, res)
		var hs := []
		for j in res.get_collision_count(): hs.append("%s n=%s depth=%.4f" % [str((res.get_collider(j) as Node).get_path()).get_file() if res.get_collider(j) is Node else "?", str(res.get_collision_normal(j)), res.get_collision_depth(j)])
		print("PROBE test_motion hit=", hit, " travel=", res.get_travel(), " rem=", res.get_remainder(), " cols=", hs)
		var stuck := 0
		for f in 300:
			var off := target - player.global_position
			if Vector2(off.x, off.z).length() < 0.75: break
			_steer(off, clampf(Vector2(off.x,off.z).length()/2,0.22,1))
			await _frames(1)
			var lm := player.get_last_motion()
			if lm.length() < 0.001: stuck += 1
			if f % 15 == 0 or (lm.length() < 0.001 and stuck < 6):
				print("PROBE f=%d pos=%s vel=%s lm=%s wall=%s floor=%s wanted=%s deflect=%s cols=%s" % [f, player.global_position, player.velocity, lm, player.is_on_wall(), player.is_on_floor(), player.get("_wanted_dir"), player.get("_deflect"), _cols()])
		print("PROBE end pos=", player.global_position, " zero_motion_frames=", stuck)

func _b2() -> void:
	var target := Vector3(120, 520, 3380)
	var start := Vector3(300, 586, 3296.4)
	player.global_position = start
	player.velocity = Vector3.ZERO
	await _frames(60)
	print("PROBE b2 settled ", player.global_position, " floor=", player.is_on_floor())
	print("PROBE wilds ", _wilds_near(Vector3(220,556,3333), 60))
	Engine.time_scale = 1.0
	var last := player.global_position
	for f in 3600:
		var off := target - player.global_position
		if Vector2(off.x, off.z).length() < 1.0: break
		_steer(off)
		await _frames(1)
		if f % 60 == 0:
			var mob := []
			for i in player.get_slide_collision_count():
				var c := player.get_slide_collision(i)
				if c.get_collider() is CharacterBody3D: mob.append("%s n=%s" % [c.get_collider().name, c.get_normal()])
			print("PROBE b2 f=%d pos=%s moved=%.2f mobile=%s cols=%s" % [f, player.global_position, player.global_position.distance_to(last), mob, _cols()])
			last = player.global_position
			if f % 300 == 0: print("PROBE wilds ", _wilds_near(player.global_position, 30))
	print("PROBE b2 end ", player.global_position, " wilds ", _wilds_near(Vector3(220,556,3333), 60))
	# lateral road width at the site: rays across route direction
	var dir := (Vector3(120,520,3380) - Vector3(373,610,3262.5)); dir.y = 0; dir = dir.normalized()
	var side := Vector3.UP.cross(dir)
	var space := world.get_world_3d().direct_space_state
	for k in range(-10, 11):
		var p := Vector3(220,556,3333) + side * k
		var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP*10, p + Vector3.DOWN*20, 1)
		var h := space.intersect_ray(q)
		print("PROBE lateral k=%d hit=%s" % [k, str(h.get("position","none")) + " " + (str((h.collider as Node).name) if h.has("collider") else "") + " n=" + str(h.get("normal",""))])
