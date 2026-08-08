extends SceneTree

## Photograph Team Tether. M13's visual language and M14's Warden.
##
##   xvfb-run -a -s "-screen 0 1600x900x24" /opt/godot/godot --path . \
##     --rendering-driver opengl3 --resolution 1600x900 \
##     --script tools/preview_warden.gd
##
## CLAUDE.md is explicit that a boss, a biome and a stronghold cannot be judged
## on assertions, and `docs/decisions/D15` and D06 exist because this project has
## repeatedly shipped systems whose tests all passed and whose frames were wrong
## — the release ceremony's appraisal panel cut in half, the impact flash that
## rendered nothing twelve times in a row, the meadow that was rendering rock.
## `tests/test_trainer_battle.gd` can prove that the Warden's creatures recover
## 25% faster. It cannot tell anyone whether he looks like a boss.
##
## Two halves, because they answer different questions:
##
##   STUDIO — the Warden against the trainer against a 1.8m ruler, plus the
##   banner, the barricade and the tether rig up close. Answers: is he actually
##   1.96m, does the retarget drive him, does oxblood read as oxblood, is the
##   cable a cable.
##
##   IN THE WORLD — his post from down the road with the ruin on the skyline,
##   the tether rig behind him, a battle in progress, and the moment the cable is
##   cut. Answers: does the post read as Team Tether at distance, does the fight
##   read, and is the legendary's placeholder honestly a placeholder.
##
## THE LIMITS, which belong in any critique made from these frames:
##   * Compatibility renderer under software rasterisation. Composition,
##     silhouette and colour are trustworthy. Lighting quality and frame times
##     are not.
##   * The legendary is an UNMODELLED PLACEHOLDER — a capsule with a snout. Its
##     appeal cannot be judged from these frames and nothing here pretends it
##     can. What the frames CAN answer about it: is it obviously not final, is it
##     the right size, and does it read as a captive rather than as equipment.

const DATA := preload("res://scripts/trainers/tether_data.gd")
const ROSTER := preload("res://scripts/trainers/tether_roster.gd")
const DRESS := preload("res://scripts/trainers/tether_dress.gd")
const TETHER_MODEL := preload("res://scripts/trainers/tether_trainer_model.gd")
const PLAYER_MODEL := preload("res://scripts/player/trainer_model.gd")

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/warden"

## A CEILING on how long to wait for the world, not a fixed wait.
##
## Under software rendering a physics frame costs as much as the frame it is
## rendered with, so a flat 300-frame settle is a quarter of an hour of real time
## whether the world was ready after twenty of them or not. This tool waits for
## the CONDITION it actually needs — Team Tether standing on the road — and this
## is only the point at which it gives up and says so.
const SETTLE_LIMIT := 900
const POSE_FRAMES := 2
## Frames to let the player and the camera settle after being placed.
const PLACE_FRAMES := 12

var _written: Array[String] = []
var _notes: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	ROSTER.register()
	await _studio()
	await _in_the_world()

	print("")
	print("%d frames -> %s" % [_written.size(), OUT_DIR])
	for line in _notes:
		print("  note  %s" % line)
	print("Software rendering: composition and colour only. The legendary is an unmodelled placeholder.")
	quit(0)


# --- studio ------------------------------------------------------------------

func _studio() -> void:
	var world := Node3D.new()
	root.add_child(world)
	# ONE FRAME BEFORE ANYTHING IS BUILT ONTO IT.
	#
	# `_init()` runs before the SceneTree's root has finished entering the tree,
	# so a node added here is not `is_inside_tree()` yet — and every world-space
	# `global_position` assignment against it silently resolves to the origin.
	# The second pass of this tool photographed exactly that: a banner meant to be
	# six metres to the side standing inside a trainer, and a tether cable drawn
	# across the whole frame from the world origin.
	await process_frame
	_studio_light(world)

	var card := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	card.mesh = plane
	var grey := StandardMaterial3D.new()
	grey.albedo_color = Color(0.30, 0.32, 0.31)
	card.material_override = grey
	world.add_child(card)

	# Left to right: the player's own trainer at 1.80m, then the whole road in
	# ascending order — the wrangler at 1.53m, the picket at 1.80m, the Warden at
	# 1.96m. The picket standing beside the player's own trainer is the point of
	# the arrangement: it is the SAME BODY wearing a different flag, which is §3's
	# "do not write them as universally cartoonish" said in a silhouette, and the
	# Warden is visibly not one of them.
	_reference_trainer(world, Vector3(-2.6, 0.0, 0.0))
	_tether_trainer(world, DATA.trainer("tether_wrangler"), Vector3(-0.9, 0.0, 0.0))
	_tether_trainer(world, DATA.trainer("tether_picket"), Vector3(0.5, 0.0, 0.0))
	_tether_trainer(world, DATA.trainer("warden_meadows"), Vector3(2.0, 0.0, 0.0))

	# Posts at the two heights that matter, so "he is 1.96m against a 1.80m
	# trainer" and "he is floating above the ground" are different pictures rather
	# than the same one.
	_ruler(world, Vector3(-3.5, 0.0, 0.0), 1.80, Color(0.88, 0.89, 0.91))
	_ruler(world, Vector3(2.9, 0.0, 0.0), 1.96, Color(0.88, 0.89, 0.91))

	# The dressing, well clear of the figures — the first pass put a banner
	# between the camera and the Warden's head.
	DRESS.banner(world, Vector3(6.0, 0.0, 0.0), Vector3.FORWARD)
	DRESS.barricade(world, Vector3(8.4, 0.0, 0.0), Vector3.RIGHT, Callable())
	var pylon := DRESS.pylon(world, Vector3(11.4, 0.0, -0.6))
	DRESS.cable(world, pylon.global_position + Vector3.UP * 1.9, Vector3(14.0, 1.3, 0.5))
	DRESS.cable(world, pylon.global_position + Vector3.UP * 1.9, Vector3(14.0, 1.0, -0.7))

	var camera := Camera3D.new()
	camera.fov = 42.0
	world.add_child(camera)
	camera.make_current()

	# The models load, retarget twenty-five clips and start their idle. Under
	# software rendering that is not instant, and a frame taken too early
	# photographs a bind pose — which is indistinguishable from a retarget that
	# failed, and is exactly the false negative `preview_trainer.gd` was written
	# to avoid.
	for i in 150:
		await physics_frame

	camera.position = Vector3(-0.3, 1.30, 6.6)
	camera.look_at(Vector3(-0.3, 1.00, 0.0), Vector3.UP)
	await _capture("01-the-four-of-them")

	camera.position = Vector3(2.0, 1.25, 3.4)
	camera.look_at(Vector3(2.0, 1.05, 0.0), Vector3.UP)
	await _capture("02-the-warden-close")

	camera.position = Vector3(10.0, 2.4, 7.4)
	camera.look_at(Vector3(10.0, 1.1, 0.0), Vector3.UP)
	await _capture("03-the-dressing")

	world.queue_free()
	await process_frame


func _reference_trainer(world: Node3D, at: Vector3) -> void:
	var node := Node3D.new()
	node.set_script(PLAYER_MODEL)
	world.add_child(node)
	node.position = at
	# NOT turned around. The first pass rotated all three by 180 degrees on the
	# assumption that a character faces -Z, and photographed three backs. These
	# models face the camera as imported, which is also what `model_yaw: 0` in
	# their data files says.
	# `trainer_model` drives its clips off a `CharacterBody3D` it has not got
	# here, so it would hold a bind pose. Posed by hand, mid-clip: frame zero of
	# most libraries is very close to the bind pose, which is the pose a BROKEN
	# retarget also produces.
	var anim := _animation_player(node)
	if anim != null and anim.has_animation("Idle_A"):
		anim.play("Idle_A")
		anim.seek(0.5, true)
	else:
		_notes.append("the reference trainer has no Idle_A; the leftmost figure is in its bind pose")


func _tether_trainer(world: Node3D, definition: Dictionary, at: Vector3) -> void:
	var node := Node3D.new()
	node.set_script(TETHER_MODEL)
	node.call("configure", definition)
	world.add_child(node)
	node.position = at


func _ruler(world: Node3D, at: Vector3, height: float, colour: Color) -> void:
	var post := MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(0.05, height, 0.05)
	post.mesh = bar
	var pale := StandardMaterial3D.new()
	pale.albedo_color = colour
	post.material_override = pale
	world.add_child(post)
	post.position = at + Vector3(0.0, height * 0.5, 0.0)


func _studio_light(world: Node3D) -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.17, 0.19, 0.22)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.76, 0.79, 0.84)
	e.ambient_light_energy = 1.4
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = e
	world.add_child(env)

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-38.0), deg_to_rad(-28.0), 0.0)
	key.light_energy = 1.5
	world.add_child(key)


# --- in the world ------------------------------------------------------------

func _in_the_world() -> void:
	var packed: PackedScene = load(SCENE)
	if packed == null:
		_notes.append("could not load %s; no in-world frames" % SCENE)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)

	# Waited on rather than counted. The route raises its posts only once the
	# terrain can answer for the ground under them, and how many frames that takes
	# depends on the machine.
	var route: Node = null
	var waited := 0
	while waited < SETTLE_LIMIT:
		route = world.get_node_or_null(^"StrongholdRoute")
		if route != null and not (route.call("trainers") as Array).is_empty():
			break
		await physics_frame
		waited += 1
	if route == null or (route.call("trainers") as Array).is_empty():
		_notes.append("Team Tether never appeared on the road within %d frames" % waited)
		return
	print("  the road was raised after %d frames" % waited)

	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var director := world.get_node_or_null(^"EncounterDirector")
	var manager := world.get_node_or_null(^"CombatManager")
	var rig := world.get_node_or_null(^"CameraRig") as Node3D
	if player == null or route == null or director == null or manager == null:
		_notes.append("the world is missing the player, the route, the director or the manager")
		return

	# The M1 debug readout covers a third of the frame and is not what anybody
	# should be looking at here. The combat HUD stays: whether a trainer battle
	# reads is exactly the question.
	var debug_hud := world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if debug_hud != null:
		debug_hud.visible = false

	var warden: Node3D = route.call("trainer_by_id", "warden_meadows")
	if warden == null:
		_notes.append("the Warden was not raised on the road; no in-world frames of him")
		return

	# Down the road, looking north at the gate with the bluff and the ruin behind
	# it. The frame that answers whether a post reads as Team Tether from a
	# distance without a marker, which is what the reserved accent is FOR.
	await _place(player, rig, warden.global_position + Vector3(4.0, 0.0, -26.0), warden.global_position)
	await _capture("04-the-gate-from-the-road")

	await _place(player, rig, warden.global_position + Vector3(2.0, 0.0, -9.0), warden.global_position)
	await _capture("05-the-warden-and-the-rig")

	# The legendary on the line, from the side, with the pylon and both cables.
	var offer: Node3D = route.call("legendary_offer")
	if offer == null:
		_notes.append("no legendary rig was raised")
	else:
		var creature: Node3D = offer.call("body")
		if creature != null:
			await _place(player, rig, creature.global_position + Vector3(9.0, 0.0, -4.0), creature.global_position)
			await _capture("06-the-legendary-on-the-line")

	# A trainer battle in progress. Walked to, challenged, and photographed once
	# the first creature is actually out and the arena has opened — waited on
	# STATE rather than on a frame count, because a fixed wait under software
	# rendering reliably photographs the beat before the one it is named after.
	await _place(player, rig, warden.global_position + Vector3(1.5, 0.0, -6.0), warden.global_position)
	if not bool(route.call("try_engage")):
		_notes.append("the Warden refused the challenge; no battle frames")
	else:
		var opening := 0
		while not bool(manager.call("is_fighting")) and opening < 600:
			await physics_frame
			opening += 1
		if not bool(manager.call("is_fighting")):
			_notes.append("the battle never opened after the challenge was accepted")
		else:
			for i in 30:
				await physics_frame
			await _capture("07-a-trainer-battle")
			_notes.append("battle opened against %s" % str((manager.call("enemy") as RefCounted).display_name))

			# Pressing Throw at a creature somebody else owns. The refusal is the
			# hard rule arriving as a sentence the player can read, and it is the
			# only place in the game that sentence appears.
			var refused := [""]
			manager.connect("catch_refused", func(reason: String) -> void: refused[0] = reason)
			manager.call("_try_throw")
			for i in 6:
				await physics_frame
			if refused[0].is_empty():
				_notes.append("THROWING AT A TRAINER'S PAL WAS NOT REFUSED — the hard rule has a hole in it")
			else:
				_notes.append("throw refused with: \"%s\"" % refused[0])
			await _capture("08-you-cannot-catch-it")

	# The tether cut. Driven directly rather than by winning the fight: this
	# frame is about what the rig looks like when it goes dark, and fighting three
	# tethered creatures to get to it under software rendering would take longer
	# than the whole rest of this tool.
	if offer != null:
		offer.call("cut_the_tether")
		# Long enough for the freed creature to walk down off the shelf.
		for i in 200:
			await physics_frame
		var creature: Node3D = offer.call("body")
		if creature != null:
			await _place(player, rig, creature.global_position + Vector3(5.0, 0.0, -6.0), creature.global_position)
			await _capture("09-the-tether-is-cut")
			_notes.append("legendary prompt after the cut: \"%s\"" % str(offer.call("prompt_line")))


## Stand the player somewhere and point the camera at something.
##
## The player is MOVED rather than walked: the Warden's post is 130 metres up a
## road that the smoke suite already proves is walkable, and walking it under
## software rendering costs minutes per frame for nothing this tool is asking
## about.
func _place(player: CharacterBody3D, rig: Node3D, at: Vector3, look_at: Vector3) -> void:
	var world := player.get_parent()
	var height := at.y
	if world != null and world.has_method("ground_height_at"):
		var ground: float = float(world.call("ground_height_at", at.x, at.z))
		if not is_nan(ground):
			height = ground
	player.global_position = Vector3(at.x, height + 0.2, at.z)
	player.velocity = Vector3.ZERO
	if rig != null:
		var to := look_at - player.global_position
		rig.set("yaw", atan2(-to.x, -to.z))
		rig.set("pitch", deg_to_rad(-6.0))
	for i in PLACE_FRAMES:
		await physics_frame


func _capture(name: String) -> void:
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		_notes.append("%s: the viewport returned no image" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	if image.save_png(path) != OK:
		_notes.append("%s: save_png failed" % name)
		return
	_written.append(path)
	print("  %-28s -> %s" % [name, path])


func _animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _animation_player(child)
		if found != null:
			return found
	return null
