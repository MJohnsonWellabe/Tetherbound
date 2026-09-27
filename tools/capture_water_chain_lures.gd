extends SceneTree

## F13#3 lure receipts: for each of the six Tidewake local chains, the
## production CameraRig at its normal framing from the chain island's authored
## arrival landing (water_world.json anchors[kind=arrival]) facing the chain's
## physical lure, plus one mid-approach frame. Production Water scene, daytime,
## clock frozen. The player has already heard each lead (the chain's lead flag
## is set) so sites that wait on the lead are shown as a player who was told
## would see them; nothing else is completed. Fixtures: teleport poses and
## upstream story flags (the same set as tools/capture_water_local_chains.gd).
## Frames are written one JPG each, 1280x720, quality 0.8.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script tools/capture_water_chain_lures.gd -- --out=<dir> [--only=lantern,...]

const WORLD := preload("res://scenes/world/water_archipelago.tscn")
## The chain walk's own baked-ground planner, so each frame's log can say how
## far each lure stands from the walked route (tests/smoke_tidewake_b_chain_route.gd).
const POCKET := preload("res://tests/smoke_water_pocket_walk_claim.gd")

var world: Node3D
var game: Node
var player: CharacterBody3D
var camera: Node3D
var config: Dictionary
var labels: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _arg(name: String) -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--%s=" % name):
			return argument.trim_prefix("--%s=" % name)
	return ""


func _on(key: String) -> bool:
	var only := _arg("only")
	return only == "" or key in only.split(",")


func _landing(island_id: String) -> Vector3:
	for anchor: Dictionary in config.anchors:
		if str(anchor.island_id) == island_id and str(anchor.kind) == "arrival":
			var at: Array = anchor.safe_position
			return Vector3(float(at[0]), float(at[1]), float(at[2]))
	return Vector3.INF


func _row_at(row_id: String) -> Vector3:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_pickups.json"))
	for row: Dictionary in data.pickups + data.harvest:
		if str(row.id) == row_id:
			return Vector3(float(row.position[0]), float(row.position[1]), float(row.position[2]))
	return Vector3.INF


func _pose(at: Vector3, look_at: Vector3) -> void:
	var ground := float(world.call("ground_height_at", at.x, at.z))
	player.global_position = Vector3(at.x, maxf(ground, at.y) + 0.3, at.z)
	player.velocity = Vector3.ZERO
	var toward := Vector2(look_at.x - at.x, look_at.z - at.z)
	camera.set("yaw", atan2(-toward.x, -toward.y))


func _settle(count: int) -> void:
	for _frame in count:
		await physics_frame
		if player.global_position.y < -20.0:
			break


func _grab(file: String, label: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	var out := _arg("out")
	out = out if out.begins_with("/") else ProjectSettings.globalize_path(out)
	image.save_jpg(out.path_join(file), 0.8)
	labels.append("%s: %s player=%s" % [file, label, player.global_position])
	# Where each wayfinding lure (water_local_chains.json wayfinding_lures) lands in
	# this frame: base and 6 m-up pixel in the saved 1280x720 image, "off" when
	# outside the view (occlusion is not tested; read the frame).
	var eye := root.get_viewport().get_camera_3d()
	if eye != null:
		print("camera %s at %s forward %s fov %.1f" % [file, eye.global_position, -eye.global_basis.z, eye.fov])
		for lure: Node in world.get_node("WaterLocalChains").get_children():
			if not str(lure.name).begins_with("Lure_"):
				continue
			var base := (lure as Node3D).global_position
			var marks: Array[String] = []
			for rise: float in [0.0, 6.0]:
				var at := base + Vector3.UP * rise
				var view := root.get_visible_rect().size
				var pixel := eye.unproject_position(at)
				var inside := not eye.is_position_behind(at) and Rect2(Vector2.ZERO, view).has_point(pixel)
				pixel *= 1280.0 / view.x
				marks.append("(%d,%d)%s" % [pixel.x, pixel.y, "" if inside else "off"])
			print("  %s %s dist=%.0f base/top6m=%s" % [file, lure.name, base.distance_to(eye.global_position), " ".join(marks)])
	print("frame %s: %s player=%s" % [file, label, player.global_position])


## Two frames: arrival landing facing the lure, then `mid` of the way along
## the straight line from landing to lure (ground-projected), still facing it.
## A negative `mid` stands back beyond the landing (Lastlight: offshore on the
## sluice_isle_to_veilfall swim approach, since its lamp is 14 m from the landing).
## `stand` (optional) replaces the straight-line mid stand with an explicit
## walked-route point (Cradle: 98 m short of the nest on the chain-route
## walk's own baked-ground plan, V-TW-6).
func _approach(key: String, island: String, lure: Vector3, what: String, mid: float,
		stand: Vector3 = Vector3.INF) -> void:
	var landing := _landing(island)
	if not landing.is_finite():
		push_error("no arrival landing for " + island)
		return
	_pose(landing, lure)
	await _settle(240)
	_pose(landing, lure)
	await _settle(60)
	await _grab("%s_1_landing.jpg" % key, "%s from %s arrival landing (%.0f m)" % [what, island,
		Vector2(lure.x - landing.x, lure.z - landing.z).length()])
	var route: Array = POCKET.plan_route(world, Vector2(landing.x, landing.z), Vector2(lure.x, lure.z)).points
	route.push_front(Vector2(landing.x, landing.z))
	print("route %s: %s" % [key, " ".join(route.map(func(p: Vector2) -> String: return "(%.1f,%.1f)" % [p.x, p.y]))])
	for node: Node in world.get_node("WaterLocalChains").get_children():
		if str(node.name).begins_with("Lure_"):
			var at := Vector2((node as Node3D).global_position.x, (node as Node3D).global_position.z)
			if at.distance_to(Vector2(landing.x, landing.z)) < 400.0:
				print("  route %s %s aside=%.1f m" % [key, node.name, _aside(route, at)])
	var step := landing.lerp(lure, mid) if not stand.is_finite() else stand
	step.y = 0.0
	_pose(step, lure)
	await _settle(240)
	_pose(step, lure)
	await _settle(60)
	await _grab("%s_2_approach.jpg" % key, "%s mid-approach (%.0f m)" % [what,
		Vector2(lure.x - step.x, lure.z - step.z).length()])


## Shortest distance from `at` to the polyline `route`.
func _aside(route: Array, at: Vector2) -> float:
	var best := INF
	for index in range(1, route.size()):
		best = minf(best, at.distance_to(Geometry2D.get_closest_point_to_segment(at, route[index - 1], route[index])))
	return best


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("lure capture requires a rendering display")
		quit(1)
		return
	config = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_world.json"))
	game = root.get_node(^"Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "water")
	game.local.character_id = "lure-capture"
	for upstream: String in ["water_swim_lesson_complete", "water_dock_reedhaven_repaired",
			"water_dock_brine_steps_trial_won", "water_aquaryn_resolved",
			"water_dock_salt_crown_landing_charted",
			"water_claim:local:lantern_return:lead", "water_claim:local:gull_research:lead",
			"water_claim:local:cradle_care:lead", "water_claim:local:garden_records:lead",
			"water_claim:local:lastlight_shelter:lead"]:
		game.world.flags.set_flag(upstream)
	game.local.flags.set_flag("water_swim_lesson_briefed")
	game.local.flags.set_flag("water_swim_stone_earned")
	world = WORLD.instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for _frame in 1500:
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
	var chains: Node = world.get_node("WaterLocalChains")

	if _on("lantern"):
		await _approach("lantern", "lantern_cove", _row_at("water:lantern_cove:pickup:002"),
			"Lantern Cove rock arch / dry nook cache", 0.55)
	if _on("gull"):
		var satchel: Node3D = chains.call("site_root", "gull_research_satchel")
		await _approach("gull", "gull_rest", satchel.global_position, "Gull Rest survey satchel", 0.6)
	if _on("cradle"):
		await _approach("cradle", "tidal_cradle", _row_at("water:tidal_cradle:harvest:007"),
			"Tidal Cradle shell nest Reef Stone seam", 0.7, Vector3(740.0, 0.0, 1584.0))
	if _on("garden"):
		var wall: Node3D = chains.call("site_root", "garden_records_wall")
		await _approach("garden", "drowned_garden", wall.global_position, "Drowned Garden vault wall", 0.6)
	if _on("deep"):
		var chart: Node3D = world.get_node("WaterDocks").get_node_or_null("deep_watch_chart")
		if chart == null:
			push_error("deep_watch_chart missing")
		else:
			await _approach("deep", "deep_watch", chart.global_position, "Deep Watch chart control", 0.6)
	if _on("lastlight"):
		var lamp := Vector3(378.2, 5.092, 3817.9)
		for landmark: Dictionary in config.landmarks:
			if str(landmark.id) == "lastlight":
				lamp = Vector3(float(landmark.position[0]), float(landmark.position[1]), float(landmark.position[2]))
		await _approach("lastlight", "veilfall", lamp, "Lastlight lamp post", -2.0)

	print("LURE CAPTURE OK frames=%d\n%s" % [labels.size(), "\n".join(labels)])
	quit(0)
