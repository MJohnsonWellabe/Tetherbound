extends SceneTree
## W14-RIDING throwaway: what actually happens to a mount's vertical velocity
## across a hop. `smoke_riding` measured 0.89 m of rise from a launch that
## should reach 1.60 m against the creature's own 26 m/s^2 gravity, on open
## ground, twice. This prints the frame-by-frame truth instead of theorising.
const SCENE := "res://scenes/world/meadows_playground.tscn"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

var _log: FileAccess = null


func _mark(t: String) -> void:
	if _log == null:
		_log = FileAccess.open("user://ridejump.txt", FileAccess.WRITE)
	_log.store_line(t)
	_log.flush()


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 300:
		await physics_frame
	var director: Node = world.get_node_or_null(^"EncounterDirector")
	var riding: Node = world.get_node_or_null(^"RidingController")
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var game := root.get_node_or_null(^"/root/Game")
	var party: RefCounted = game.get("party")
	var bag: RefCounted = game.get("inventory")
	bag.call("add", "saddle", 1)

	if director.call("ally_body") != null:
		director.call("dismiss_active_creature")
		for i in 20:
			await physics_frame
	var instance: RefCounted = SPECIES.spawn("meadowhart")
	party.call("add", instance)
	for i in int(party.call("size")):
		if party.call("at", i) == instance:
			party.call("set_active", i)
			break
	await director.call("summon_active_creature")
	for i in 120:
		await physics_frame
		if director.call("ally_body") != null:
			break
	var mount: CharacterBody3D = director.call("ally_body") as CharacterBody3D
	mount.call("place_on_ground", Vector3(60.0, 0.0, 0.0))
	for i in 60:
		await physics_frame
	player.global_position = mount.global_position + mount.global_basis.x * 1.2
	for i in 20:
		await physics_frame
	_mark("mounted=%s" % str(bool(riding.call("mount"))))
	for i in 30:
		await physics_frame

	# Origin is 2.8m from the workshop (village.json). "move_back" was already
	# proven clear by smoke_riding's own stick test (10 m/s peak, 7.3m/1.5s).
	# Drive that heading for longer to get well clear before measuring the hop.
	Input.action_press("move_back")
	for i in 180:
		await physics_frame
	Input.action_release("move_back")
	for i in 60:
		await physics_frame
	_mark("after move_back: pos=(%.1f, %.1f, %.1f) on_floor=%s" % [
		mount.global_position.x, mount.global_position.y, mount.global_position.z, str(mount.is_on_floor())])

	_mark("gravity=%s speed=%s floor_max=%.1f snap=%.3f safe_margin=%.4f motion_mode=%d" % [
		str(mount.get("_gravity")), str(mount.get("_speed")),
		rad_to_deg(mount.floor_max_angle), mount.floor_snap_length,
		mount.safe_margin, mount.motion_mode])
	_mark("asked height=%.2f -> launch=%.3f" % [
		float(riding.call("ride_jump_height")),
		sqrt(2.0 * float(mount.get("_gravity")) * float(riding.call("ride_jump_height")))])

	var base := mount.global_position.y
	Input.action_press("jump")
	await physics_frame
	await physics_frame
	Input.action_release("jump")
	for i in 45:
		_mark("f%02d y=%+.3f vy=%+.3f floor=%s" % [i, mount.global_position.y - base,
			mount.velocity.y, str(mount.is_on_floor())])
		await physics_frame
	quit(0)
