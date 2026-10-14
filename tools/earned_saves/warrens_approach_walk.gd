extends SceneTree

## CARD:M2 Warrens-approach reachability walk (13 Oct). Loads a production
## save through the title's Load list, places the trainer on the South
## Bridge's far bank (DISCLOSED shortcut: the bridge/camp pieces are proven
## separately), then drives ordinary stick input with the earned Warrens
## helper's own walker (wild fights live, its own _fight/_prepare) along the
## helper's exact route minus the quarry harvest: Band2 road to the undertrail,
## the undertrail with its spike bypass, the staging pose past the ramp foot
## (`staging_run`), the bank check, and the walk up the ramp to the live
## entrance marker. Nothing is written to the save.
##   godot --headless --path . --script tools/earned_saves/warrens_approach_walk.gd -- --from=<dir with save/>
const SAVE := preload("res://scripts/save/save_game.gd")
const SEGMENT := preload("res://tests/helpers/meadows_earned_warrens_segment.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const CHECKPOINTS := preload("res://tests/helpers/four_biome_checkpoints.gd")
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const START := Vector2(0.0, 1360.0) # Band2 road[0], the bridge's far bank.


func _init() -> void:
	_run.call_deferred()


func _done(ok: bool, why: String) -> void:
	print("WARRENS WALK RESULT %s %s" % ["PASS" if ok else "FAIL", why])
	quit(0 if ok else 1)


func _run() -> void:
	var from := ""
	var scale := 1.0
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--from="): from = ProjectSettings.globalize_path(arg.trim_prefix("--from="))
		elif arg.begins_with("--scale="): scale = float(arg.trim_prefix("--scale="))
	var working := OS.get_user_data_dir().path_join("warrens_walk_%d" % Time.get_ticks_usec())
	if from.is_empty() or not CHECKPOINTS.copy_tree(from.path_join("save"), working):
		_done(false, "usage: --from=<dir with save/>")
		return
	var game := root.get_node("Game")
	game.set("save_system", SAVE.new(working))
	var title := (load(TITLE_SCENE) as PackedScene).instantiate()
	root.add_child(title)
	current_scene = title
	for _i in 10: await process_frame
	(title.get("_load_button") as Button).pressed.emit()
	await process_frame
	for node: Node in (title.get("_load_box") as Node).get_children():
		if node is Button and (node as Button).text.begins_with("Autosave") and not (node as Button).disabled:
			(node as Button).pressed.emit()
	var world: Node3D
	for _frame in 7200:
		await process_frame
		var scene := current_scene
		if scene != null and scene != title and is_instance_valid(scene) and scene.get_node_or_null("Player") != null \
				and str(game.get("pending_realm_entry")).is_empty() and bool(game.call("_realm_scene_ready", scene, str(game.get("current_realm")))):
			world = scene as Node3D
			break
	if world == null or str(game.get("current_realm")) != "meadows":
		_done(false, "the save never reached a ready Meadows world")
		return
	for _i in 300: await physics_frame
	var warrens := world.get_node_or_null("BurrowWarrens") as Node3D
	for _i in 3600:
		if warrens != null and bool(warrens.get("_arena_definition_ready")): break
		await physics_frame
	var player := world.get_node("Player") as CharacterBody3D
	var ground := float(world.call("ground_height_at", START.x, START.y))
	player.global_position = Vector3(START.x, ground + 0.3, START.y)
	player.velocity = Vector3.ZERO
	print("WARRENS WALK DISCLOSED teleport to the South Bridge far bank %s (shortcut; no flag/item/party write)" % player.global_position)
	for _i in 120: await physics_frame
	Engine.time_scale = scale
	var seg: RefCounted = SEGMENT.new()
	seg._tree = self
	seg._world = world
	seg._game = game
	seg._player = player
	seg._rig = world.get_node_or_null("CameraRig") as Node3D
	seg._warrens = warrens
	seg._director = world.get_node_or_null("EncounterDirector")
	seg._combat = world.get_node_or_null("CombatManager")
	seg._arbiter = get_first_node_in_group("interaction_arbiter")
	seg._config = seg._read(SEGMENT.WARRENS)
	seg._initial_ids = seg._party_ids()
	seg._input = SEGMENT.INPUTS.new()
	seg._input._tree = self
	seg._nav = SEGMENT.NAV.new(self, player, seg._rig, seg._stick)
	seg._combat.connect("entered", seg._on_entered)
	seg._combat.connect("hit_landed", seg._on_hit)
	seg._combat.connect("exited", seg._on_exit)
	var started := Time.get_ticks_msec()
	var ok: bool = await _route(seg)
	seg._stick(0.0, 0.0)
	var entrance: Vector3 = warrens.call("marker", "entrance")
	var gap := player.global_position.distance_to(entrance)
	print("WARRENS WALK receipts=%s" % JSON.stringify(seg._receipts))
	print("WARRENS WALK end player=%s entrance=%s gap=%.2f wall_s=%d failures=%s party=%s scale=%.1f" % [
		player.global_position, entrance, gap, (Time.get_ticks_msec() - started) / 1000, str(seg._failures),
		str(seg._party_hp()), scale])
	CHECKPOINTS.remove_tree(working)
	_done(ok and seg._failures.is_empty() and gap <= 1.5, "gap=%.2f" % gap)


func _route(seg: RefCounted) -> bool:
	var terrain: Dictionary = seg._read(SEGMENT.TERRAIN)
	var road: Array[Vector2] = SEGMENT.trail_points(terrain, "bands", "band2_stone_and_root")
	var undertrail: Array[Vector2] = SEGMENT.trail_points(terrain, "loops", "warren_undertrail")
	var stops: Array[Dictionary] = SEGMENT.rootstone_stops(seg._read(SEGMENT.HARVEST))
	var quarry_centre := Vector2.ZERO
	for row: Dictionary in stops: quarry_centre += SEGMENT._v2(row.at)
	quarry_centre /= float(stops.size())
	var quarry_join := SEGMENT.nearest_index(road, quarry_centre)
	var warren_join := SEGMENT.nearest_index(road, undertrail[0])
	if not await seg._prepare():
		return false
	for index in range(quarry_join):
		if not await seg._walk_ground(road[index]): return false
	print("WARRENS WALK at the quarry join %s (quarry harvest skipped: not part of this walk)" % road[quarry_join])
	if not await seg._around_station(seg._v2p(), road[quarry_join + 1]): return false
	for index in range(quarry_join + 1, warren_join + 1):
		if not await seg._walk_ground(road[index]): return false
	var warrens: Node3D = seg._warrens
	var entrance: Vector3 = warrens.call("marker", "entrance")
	var mouth: Vector3 = warrens.call("marker", "mouth")
	var run: float = SEGMENT.staging_run(warrens, seg._config, entrance)
	var outside: Vector3 = SEGMENT.outside_approach(entrance, mouth, run)
	print("WARRENS WALK staging run=%.2f outside=%s ground=%.2f" % [run, outside,
		float(seg._world.call("ground_height_at", outside.x, outside.z))])
	for index in range(SEGMENT.nearest_index(undertrail, Vector2(outside.x, outside.z)) + 1):
		if not await seg._around("spike_bypass", SEGMENT.SPIKE_KNOT, SEGMENT.SPIKE_CLEAR_M, SEGMENT.SPIKE_BYPASS, seg._v2p(), undertrail[index]) \
				or not await seg._walk_ground(undertrail[index]):
			return false
	if not await seg._walk_staging(Vector2(outside.x, outside.z)):
		return false
	print("WARRENS WALK STAGED at %s (outside %s)" % [seg._player.global_position, outside])
	if not await seg._off_the_bank(entrance, mouth, outside):
		return false
	if not await seg._walk_ground(Vector2(outside.x, outside.z), SEGMENT.RAMP_AXIS_RADIUS_M):
		return false
	print("WARRENS WALK ON AXIS at %s" % seg._player.global_position)
	return await seg._walk(entrance)
