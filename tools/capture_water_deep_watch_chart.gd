extends SceneTree

## Production-camera receipt for side_water_deep_watch_chart (F13): Orsen's
## Deep Watch lead, the locked Tidecoil cache and its HUD refusal, the chart
## table refusal, the cache after resolution, Orsen's chart lead and his
## acknowledgement. Production Water scene, CameraRig, PlaygroundHUD and
## DialoguePanel. Fixtures: teleport poses; upstream dock facts as in
## smoke_water_dock_actions; Tidecoil resolved by the director's won-fight
## terminal handler on its real named body (no fight played).
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script tools/capture_water_deep_watch_chart.gd -- --sheet=<jpg>

const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const CLAIM := preload("res://scripts/world/ledger_claim.gd")
const GATED := "water:deep_watch:pickup:002"
const TIDECOIL_ID := "water_deep_watch_tidecoil"
const TIDECOIL_SITE := Vector3(1483.196, -0.5075, 3427.917)

var world: Node3D
var game: Node
var player: CharacterBody3D
var camera: Node3D
var frames: Array[Image] = []
var labels: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _arg(name: String) -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--%s=" % name):
			return argument.trim_prefix("--%s=" % name)
	return ""


func _pose(at: Vector3, look_at: Vector3) -> void:
	player.global_position = Vector3(at.x, float(world.ground_height_at(at.x, at.z)) + 0.1, at.z)
	player.velocity = Vector3.ZERO
	var toward := Vector2(look_at.x - at.x, look_at.z - at.z)
	camera.set("yaw", atan2(-toward.x, -toward.y))


func _settle(count: int = 90) -> void:
	for _frame in count:
		await physics_frame


func _grab(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	frames.append(image)
	labels.append(label)
	var each := _arg("frames_dir")
	if not each.is_empty():
		image.save_jpg(each.path_join("frame_%d.jpg" % frames.size()), 0.85)


## The HUD polls the world-message queue on idle frames; wait for the toast
## itself (not physics ticks) so the frame shows what the player reads.
func _await_toast() -> void:
	var hud: Node = world.get_node("PlaygroundHUD")
	var message: Label = hud.get("_hotbar_message")
	for _frame in 120:
		await process_frame
		if message.visible and not message.text.is_empty():
			break
	# Capture-only fixture: the toast's 2.2 s wall-clock hold is shorter than a
	# few software-GL frames under xvfb, so hold it long enough to be framed.
	hud.set("_hotbar_message_until", Time.get_ticks_msec() / 1000.0 + 30.0)
	for _frame in 3:
		await process_frame
	print("toast visible=%s text=%s" % [message.is_visible_in_tree(), message.text])


func _release_toast() -> void:
	world.get_node("PlaygroundHUD").set("_hotbar_message_until", 0.001)


func _orsen_line(containing: String, label: String, expected: String) -> void:
	var chapter: Node = world.get_node("WaterChapter")
	var npcs: Node = world.get_node("WaterNPCs")
	var panel: Node = world.get_node("DialoguePanel")
	var orsen: Node3D = chapter.npc_bodies.get("water_orsen")
	_pose(orsen.global_position + Vector3(2.2, 0.0, 1.0), orsen.global_position)
	await _settle(60)
	if not bool(npcs.call("start_conversation", "water_orsen")):
		push_error("Orsen conversation did not start")
		return
	var conversation := str(npcs.get("_active_conversation"))
	if conversation != expected:
		push_error("Orsen chose %s, expected %s" % [conversation, expected])
	for _guard in 10:
		if str(panel.call("runner").call("line").get("text", "")).contains(containing):
			break
		panel.call("advance")
		await _settle(10)
	await _settle(150)
	await _grab(label + " [" + conversation + "]")
	while bool(panel.call("is_open")):
		panel.call("advance")
		await _settle(5)


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("deep watch capture requires a rendering display")
		quit(1)
		return
	game = root.get_node(^"Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "water")
	game.local.character_id = "deep-watch-capture"
	for upstream: String in ["water_dock_brine_steps_trial_won", "water_aquaryn_resolved",
			"water_dock_salt_crown_landing_charted"]:
		game.world.flags.set_flag(upstream)
	world = WORLD.instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for _frame in 1200:
		await physics_frame
		if bool(world.call("shell_build_complete")):
			break
	var look := world.get_node_or_null(^"WorldLook")
	if look != null:
		look.call("apply_time", "day")
		if look.has_method("set_clock_frozen"):
			look.call("set_clock_frozen", true)
	player = world.get_node(^"Player") as CharacterBody3D
	camera = world.get_node(^"CameraRig") as Node3D
	var pickups: Node = world.get_node("WaterPickups")
	var docks: Node = world.get_node("WaterDocks")
	var director: Node = world.get_node("EncounterDirector")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_pickups.json"))
	var cache_at := Vector3.INF
	for row: Dictionary in data.pickups:
		if str(row.id) == GATED:
			cache_at = Vector3(float(row.position[0]), 0.0, float(row.position[2]))
	var stand_at := cache_at + Vector3(6.0, 0.0, 3.0)

	await _orsen_line("Deep Watch", "1 Orsen names Deep Watch", "water_orsen_pre")

	_pose(stand_at, cache_at)
	await _settle(120)
	pickups.call("refresh")
	var refusal: Dictionary = CLAIM.submit(pickups, {"kind": "water_personal_pickup", "realm": "water", "pickup_id": GATED, "personal_claimed": false})
	print("cache refusal: ", refusal.get("code", ""), " / ", refusal.get("reason", ""), " pending msg=", game.get("_pending_world_message"))
	await _await_toast()
	await _grab("2 Locked cache withheld + host refusal toast (spawned=%s)" % str(pickups.call("node_for", GATED) != null))
	_release_toast()

	var chart: Node3D = docks.get_node("deep_watch_chart")
	_pose(chart.global_position + Vector3(3.0, 0.0, 2.0), chart.global_position)
	await _settle(90)
	for child: Node in chart.get_children():
		if child.has_method("interaction_activate"):
			child.call("interaction_activate")
	await _await_toast()
	await _grab("3 Chart table refuses before Tidecoil")
	_release_toast()

	var stand := Vector3.INF
	for distance: float in [30.0, 40.0, 50.0, 60.0, 70.0, 80.0]:
		var candidate := TIDECOIL_SITE + (Vector3(1350.0, 0.0, 3500.0) - TIDECOIL_SITE).normalized() * distance
		if float(world.ground_height_at(candidate.x, candidate.z)) >= 0.8:
			stand = candidate
			break
	_pose(stand, TIDECOIL_SITE)
	var body: Node3D = null
	for _frame in 300:
		await physics_frame
		for wild: Variant in director.get("_wild_creatures"):
			if is_instance_valid(wild) and str((wild as Node).get_meta("water_named_encounter", "")) == TIDECOIL_ID:
				body = wild as Node3D
		if body != null:
			break
	if body == null:
		push_error("Tidecoil body never resident")
		quit(1)
		return
	director.set("_engaged_with", body)
	director.call("_on_combat_exited", "won")
	await _settle(30)

	_pose(stand_at, cache_at)
	await _settle(150)
	await _grab("4 Cache streams in after resolution (spawned=%s)" % str(pickups.call("node_for", GATED) != null))

	await _orsen_line("chart table", "5 Orsen gives the chart lead", "water_orsen_deep_watch_chart_lead")

	_pose(chart.global_position + Vector3(3.0, 0.0, 2.0), chart.global_position)
	await _settle(90)
	for child: Node in chart.get_children():
		if child.has_method("interaction_activate"):
			child.call("interaction_activate")
	await _settle(30)
	await _orsen_line("charted", "6 Orsen acknowledges the chart (charted=%s)" % str(game.world.flags.has("water_dock_deep_watch_current_charted")), "water_orsen_deep_watch_charted")

	var width := frames[0].get_width() / 2
	var height := frames[0].get_height() / 2
	var sheet := Image.create(width * 3, height * 2, false, Image.FORMAT_RGB8)
	for index in frames.size():
		var small := frames[index].duplicate() as Image
		small.resize(width, height, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(small, Rect2i(0, 0, width, height), Vector2i((index % 3) * width, (index / 3) * height))
	var target := _arg("sheet")
	target = target if target.begins_with("/") else ProjectSettings.globalize_path(target)
	sheet.save_jpg(target, 0.85)
	print("DEEP WATCH CAPTURE OK frames=%d\n%s" % [frames.size(), "\n".join(labels)])
	quit(0)
