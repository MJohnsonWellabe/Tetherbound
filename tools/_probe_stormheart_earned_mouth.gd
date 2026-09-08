extends SceneTree

## Isolated diagnostic: shipped Stormheart approach/ring/rails and actual Player.
## No campaign terrain, save, grants, combat or progression. Starting placement
## is a geometry fixture, never an earned campaign receipt. --fixed-only is
## the strict CI mode: one open-mouth attempt, nonzero unless core is reached.
const TREE := preload("res://scripts/world/stormheart_tree.gd")
const PLAYER := preload("res://scenes/player/player.tscn")
const FIELD := preload("res://scripts/world/stormwood_heightfield.gd")
const NAV := preload("res://tests/helpers/stick_navigator.gd")
const FRAME_BUDGET := 6000
const TOLERANCE := 3.5
var fixture_failures: Array[String] = []

class CameraBasis extends Node3D:
	var yaw := 0.0
	var pitch := 0.0
	func planar_basis() -> Basis: return Basis.IDENTITY

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scale_before := Engine.time_scale
	var hz_before := Engine.physics_ticks_per_second
	await process_frame
	Engine.time_scale = 4.0
	Engine.physics_ticks_per_second = 60
	await process_frame
	if not OS.get_cmdline_user_args().has("--open-mouth-only") \
			and not OS.get_cmdline_user_args().has("--fixed-only"):
		await _case(false)
	await _case(true)
	_stick(0,0)
	await process_frame
	Engine.time_scale = scale_before
	Engine.physics_ticks_per_second = hz_before
	print("DIAGNOSTIC terminal fixture_failures=",fixture_failures)
	quit(0 if fixture_failures.is_empty() else 1)

func _case(open_mouth: bool) -> void:
	var label := "open-mouth proposal" if open_mouth else "current outside-ring route"
	var world := Node3D.new()
	world.name = "StormheartGeometryFixture"
	root.add_child(world)
	var rig := CameraBasis.new()
	rig.name = "CameraRig"
	world.add_child(rig)
	var field := FIELD.new()
	var trunk := TREE.new()
	trunk.name = "StormheartTree"
	trunk.simulation_only = true # Production shell retains identical collision.
	trunk.position = Vector3(-100,field.height_at(-100,5470),5470)
	world.add_child(trunk)
	trunk.build()
	var foot := Vector3(-100,field.height_at(-100,5350)+0.2,5350)
	trunk.add_approach(foot)
	var approach := trunk.to_global(Vector3(0,6,-40))
	var player := PLAYER.instantiate() as CharacterBody3D
	player.camera_rig_path = NodePath("../CameraRig")
	world.add_child(player)
	# Half a metre inside the actual approach surface avoids a fabricated
	# support floor at its otherwise terrain-supported open endpoint.
	player.position = foot.lerp(approach,0.5 / foot.distance_to(approach))+Vector3.UP*0.1
	for frame in 30: await physics_frame
	var capsule := (player.get_node("Collision") as CollisionShape3D).shape as CapsuleShape3D
	print("FIXTURE ",label," start=",player.global_position," floor=",player.is_on_floor(),
		" capsule_radius=",capsule.radius," height=",capsule.height,
		" floor_limit=",rad_to_deg(player.floor_max_angle)," trunk=",trunk.global_position,
		" foot=",foot," approach=",approach," contacts=",_contacts(player))
	if not player.is_on_floor():
		fixture_failures.append(label+": initial fixture lacks actual ramp support")
		world.queue_free()
		await process_frame
		return
	var nav := NAV.new(self,player,rig,_stick)
	var started := Engine.get_physics_frames()
	var began_ms := Time.get_ticks_msec()
	var stage := 0
	var last_progress := 0.0
	var furthest := 0.0
	var reached := false
	var contacts_seen: Dictionary = {}
	var target := approach
	while Engine.get_physics_frames()-started < FRAME_BUDGET:
		var frames := Engine.get_physics_frames()-started
		if stage == 0 and player.global_position.distance_to(approach) < TOLERANCE:
			stage = 1 if open_mouth else 3
			nav.reset()
		if stage == 1 and player.global_position.distance_to(trunk.to_global(Vector3(-4,6,-26))) < 0.8:
			stage = 2
			nav.reset()
		if stage == 2 and player.global_position.distance_to(trunk.to_global(trunk.ascent_point(0))) < 0.8:
			stage = 3
			nav.reset()
		var progress := clampf((player.global_position.y-(trunk.global_position.y+6.0))/144.0,0,1)
		furthest = maxf(furthest,progress)
		if stage == 3 and furthest >= 0.998 and player.is_on_floor() \
				and player.global_position.distance_to(trunk.core_anchor()) <= TOLERANCE:
			reached = true
			break
		var fraction := minf(1.0,maxf(progress+0.008,last_progress+0.002))
		match stage:
			0: target = approach
			1: target = trunk.to_global(Vector3(-4,6,-26))
			2: target = trunk.to_global(trunk.ascent_point(0))
			3: target = trunk.to_global(trunk.ascent_point(fraction))
		last_progress = maxf(last_progress,progress)
		for row: Dictionary in _contacts(player): contacts_seen[row.body] = true
		if frames % 450 == 0:
			print("WALK ",label," frames=",frames," stage=",stage," player=",player.global_position,
				" target=",target," progress=",progress," floor=",player.is_on_floor()," contacts=",_contacts(player))
		if nav.can_walk(): await nav.step(target)
		else: await physics_frame
	_stick(0,0)
	print("RESULT ",label," reached=",reached," frames=",Engine.get_physics_frames()-started,
		" elapsed_ms=",Time.get_ticks_msec()-began_ms," stage=",stage," player=",player.global_position,
		" target=",target," core_distance=",player.global_position.distance_to(trunk.core_anchor()),
		" furthest=",furthest," grounded=",player.is_on_floor()," unstick_count=",player.get("_unstick_count"),
		" contacts_seen=",contacts_seen.keys()," final_contacts=",_contacts(player))
	if OS.get_cmdline_user_args().has("--fixed-only") and not reached:
		fixture_failures.append("actual Player did not reach core within the shared 6000-frame bound")
	world.queue_free()
	await process_frame

func _contacts(player: CharacterBody3D) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for index in player.get_slide_collision_count():
		var hit := player.get_slide_collision(index)
		var collider := hit.get_collider() as Node
		rows.append({"body":str(collider.name) if collider != null else "<none>","normal":hit.get_normal()})
	return rows

func _stick(x: float, z: float) -> void:
	for action in ["move_left","move_right","move_forward","move_back"]: Input.action_release(action)
	if x<0: Input.action_press("move_left",-x)
	if x>0: Input.action_press("move_right",x)
	if z<0: Input.action_press("move_forward",-z)
	if z>0: Input.action_press("move_back",z)
