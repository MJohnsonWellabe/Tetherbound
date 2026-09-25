extends SceneTree

## Production-camera receipts for the five Tidewake local chains built in F13
## (side_water_lantern_return, _gull_research, _cradle_care, _garden_records,
## _lastlight_shelter): each chain's lead line, its place (cache, satchel,
## nest seam, vault wall, built shelter), and its return/acknowledgement line.
## Production Water scene, CameraRig, PlaygroundHUD and DialoguePanel; every
## chain record is committed through WaterLocalChains and the host rule.
## Fixtures: teleport poses; upstream flags (lesson complete + briefed,
## Reedhaven repaired, Aquaryn trial settled); Lantern/Gull/Garden candies and
## the Cradle seam are taken by their production bodies; the Lastlight
## materials are added to the satchel and the companion is bedded with the
## production bed's assign_creature(). One sheet per chain (3 frames).
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script tools/capture_water_local_chains.gd -- --out=<dir>

const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

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
	print("frame %d: %s" % [frames.size(), label])


## Greet through the speaker's real prompt (Edda's is routed by the Guardian
## gate), frame the line containing `containing`, then deliver the rest so any
## guarded chain step is requested exactly as in play.
func _line(npc: String, containing: String, label: String) -> void:
	var chapter: Node = world.get_node("WaterChapter")
	var npcs: Node = world.get_node("WaterNPCs")
	var panel: Node = world.get_node("DialoguePanel")
	var body: Node3D = chapter.npc_bodies.get(npc)
	var side := Vector3(2.2, 0.0, 1.0)
	player.global_position = body.global_position + side + Vector3(0.0, 0.1, 0.0)
	player.velocity = Vector3.ZERO
	camera.set("yaw", atan2(side.x, side.z))
	await _settle(60)
	body.call("prompt_node").emit_signal("activated")
	if not bool(panel.call("is_open")):
		push_error("%s conversation did not start" % npc)
		return
	var conversation := str(npcs.get("_active_conversation"))
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
	await _settle(10)


func _claim(row_id: String, offset: Vector3) -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_pickups.json"))
	var at := Vector3.INF
	for row: Dictionary in data.pickups + data.harvest:
		if str(row.id) == row_id:
			at = Vector3(float(row.position[0]), 0.0, float(row.position[2]))
	_pose(at + offset, at)
	var pickups: Node = world.get_node("WaterPickups")
	for _frame in 120:
		await physics_frame
	pickups.call("refresh")
	await _settle(30)


func _take(row_id: String, tool: Variant = null) -> void:
	var node: Node = world.get_node("WaterPickups").call("node_for", row_id)
	if node == null:
		push_error("row not resident: " + row_id)
		return
	if tool == null:
		node.call("_on_picked_up")
	else:
		node.call("gather", tool)
	await _settle(20)


func _site(step: String) -> Node3D:
	return world.get_node("WaterLocalChains").call("site_root", step)


func _sheet(name: String, from: int) -> void:
	var width := frames[from].get_width() / 2
	var height := frames[from].get_height() / 2
	var sheet := Image.create(width * 3, height, false, Image.FORMAT_RGB8)
	for index in 3:
		var small := frames[from + index].duplicate() as Image
		small.resize(width, height, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(small, Rect2i(0, 0, width, height), Vector2i(index * width, 0))
	var out := _arg("out")
	out = out if out.begins_with("/") else ProjectSettings.globalize_path(out)
	sheet.save_jpg(out.path_join("_sheet_%s.jpg" % name), 0.8)


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("local chain capture requires a rendering display")
		quit(1)
		return
	game = root.get_node(^"Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "water")
	game.local.character_id = "local-chain-capture"
	for upstream: String in ["water_swim_lesson_complete", "water_dock_reedhaven_repaired",
			"water_dock_brine_steps_trial_won", "water_aquaryn_resolved"]:
		game.world.flags.set_flag(upstream)
	game.local.flags.set_flag("water_swim_lesson_briefed")
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

	# 1. Lantern Cove return.
	await _line("water_pell", "arch", "Lantern 1 Pell points to the arch")
	await _claim("water:lantern_cove:pickup:002", Vector3(5.0, 0.0, 4.0))
	await _grab("Lantern 2 Candy I in the nook beneath the arch")
	await _take("water:lantern_cove:pickup:002")
	await _line("water_pell", "back on your own strength", "Lantern 3 Pell hears the swim back")
	_sheet("lantern_return", 0)

	# 2. Gull Rest research.
	await _line("water_adair", "Gull Rest", "Gull 1 Adair names Gull Rest")
	var satchel := _site("gull_research_satchel")
	_pose(satchel.global_position + Vector3(2.5, 0.0, 2.0), satchel.global_position)
	await _settle(150)
	await _grab("Gull 2 Survey satchel and its prompt")
	satchel.get_node("Prompt").call("interaction_activate")
	await _settle(20)
	await _line("water_adair", "sheltered crossing", "Gull 3 Adair charts the crossing")
	_sheet("gull_research", 3)

	# 3. Tidal Cradle care (Aquaryn's trial settled, not caught).
	await _line("water_otto", "shell nest", "Cradle 1 Otto points to the shell nest")
	game.inventory.add("pickaxe", 1)
	await _claim("water:tidal_cradle:harvest:007", Vector3(3.5, 0.0, 3.0))
	await _grab("Cradle 2 Reef Stone seam in the dry nest")
	await _take("water:tidal_cradle:harvest:007", "pickaxe")
	await _line("water_otto", "Riverdrake", "Cradle 3 Otto's habitat lead and berries")
	_sheet("cradle_care", 6)

	# 4. Drowned Garden records.
	await _line("water_edda", "Drowned Garden", "Garden 1 Edda points to the vault")
	var wall := _site("garden_records_wall")
	_pose(wall.global_position + Vector3(1.5, 0.0, 5.5), wall.global_position)
	await _settle(150)
	await _grab("Garden 2 Vault wall and its prompt")
	_pose(wall.global_position + Vector3(0.0, 0.0, 1.8), wall.global_position)
	await _settle(60)
	wall.get_node("Prompt").call("interaction_activate")
	await _settle(20)
	await _line("water_edda", "shared landing", "Garden 3 Edda explains the docks")
	_sheet("garden_records", 9)

	# 5. Lastlight shelter.
	await _line("water_halen", "Lastlight", "Shelter 1 Halen reveals the sheltered way")
	var supply := _site("lastlight_shelter_supply")
	game.inventory.add("driftwood", 4)
	game.inventory.add("reed_fiber", 4)
	_pose(supply.global_position + Vector3(0.0, 0.0, -1.5), supply.global_position)
	await _settle(60)
	supply.get_node("Prompt").call("interaction_activate")
	await _settle(30)
	var bed: Node3D = world.get_node("WaterCamps").get_node("water_camp_veilfall_creature_bed")
	if game.local.party.size() == 0:
		game.local.party.add(SPECIES.spawn("water_mosshell"))
	player.global_position = bed.global_position + Vector3(1.2, 0.1, 0.0)
	await _settle(10)
	bed.call("assign_creature", 0)
	await _settle(90)
	_pose(bed.global_position + Vector3(5.0, 0.0, 6.5), bed.global_position)
	await _settle(150)
	await _grab("Shelter 2 Sheltered creature bed with a resting companion (rested=%s)"
		% str(game.world.flags.has("water_claim:local:lastlight_shelter:rested")))
	await _line("water_halen", "slept dry", "Shelter 3 Halen's acknowledgement")
	_sheet("lastlight_shelter", 12)

	print("LOCAL CHAIN CAPTURE OK frames=%d\n%s" % [frames.size(), "\n".join(labels)])
	quit(0)
