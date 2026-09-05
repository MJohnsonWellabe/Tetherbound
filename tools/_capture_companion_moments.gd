extends SceneTree

## W12-COMPANION-0904: the three companion-presence moments, photographed in
## the real Meadows with the real follower body, for a code-blind critic.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_capture_companion_moments.gd
##
## NEVER `--headless` with a rendering driver: that combination hangs forever
## (docs/AGENT_WORKFLOW.md section 7). This tool renders, so it never uses it.
##
## THE QUESTION THE SHEET HAS TO ANSWER is whether the creature reads as
## REACTING TO ITS SITUATION rather than looping a generic idle. A single
## still cannot answer that on its own -- a creature mid-idle and a creature
## mid-reaction photograph identically often enough that
## `tools/_capture_creature_animation_world.gd` shoots everything in pairs for
## exactly this reason. So each moment here is shot as a PAIR a fixed interval
## apart, from one fixed camera, and the tool prints the measured pixel
## difference between the two frames. The contact sheet the judge sees is the
## six frames together.
##
## THE THREE MOMENTS, each a state `companion_presence.gd` actually owns and
## each staged by putting the creature in the real situation rather than by
## calling its reaction directly:
##
##   01-acknowledgment — the trainer stands still beside their creature until
##                        the layer's own still-delay elapses and the creature
##                        turns, walks up and dips its head.
##   02-hurt            — the same creature at 15% HP: slower gait, head low,
##                        the periodic flinch. Staged by setting the party
##                        member's `hp`, which is what a lost exchange does.
##   03-camp            — beside a real lit campfire built by the game's own
##                        `campfire.gd`, where the layer rolls the creature
##                        partway toward its rest pose and slows its idle.
##
## The pairs are shot with the tree PAUSED (rendering is independent of the
## pause) so a sub-second pose is photographable at all -- one llvmpipe frame
## at this resolution costs seconds of simulated time, and the moment would
## otherwise always be over before the shutter opened. Between the A and B of
## a pair the layer is ticked directly by a fixed delta rather than being
## waited out, so the interval is an exact, repeatable distance into the
## reaction instead of however far the frame rate happened to carry it.
##
## Frames land in `res://shots/companion/`; sheet them with
## `godot --headless --path . --script tools/contact_sheet.gd -- --dir=res://shots/companion`.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/companion"
const CAMPFIRE := preload("res://scripts/build/campfire.gd")

const BOOT_FRAMES := 90
const SETTLE_FRAMES := 25
const RENDER_SETTLE_FRAMES := 2
## Seconds of reaction between the A and B of a pair, ticked into the layer.
const PAIR_SECONDS := 0.35
const PAIR_TICK := 0.05

## Open, flat ground in Lower Meadows, the same stand
## `_capture_creature_animation_world.gd` uses: a plain field, so nothing in
## frame competes with the creature.
const STAGE := Vector2(-430.0, 470.0)
const EYE_HEIGHT := 1.6

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _director: Node = null
var _body: Node3D = null
var _presence: Node = null
var _creature: RefCounted = null

var _frames := 0
var _written := 0
var _failed := 0


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run this under xvfb-run, see the header comment")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	await _await_physics(BOOT_FRAMES, "boot")

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _player == null or _rig == null or _director == null:
		print("FAIL: the scene is missing the player, camera rig or encounter director")
		quit(1)
		return
	_pin_the_clock()
	await _stage_the_trainer()
	if not await _deploy_the_creature():
		_report()
		quit(1)
		return

	await _shoot_acknowledgment()
	await _shoot_hurt()
	await _shoot_camp()

	_report()
	quit(0 if _failed == 0 else 1)


## Pinned to day/clear and frozen, so all six frames are in the same light and
## nothing but the creature differs between them.
func _pin_the_clock() -> void:
	var weather: Node = _world.get_node_or_null(^"WorldWeather")
	if weather != null:
		weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)
	var look: Node = _world.get_node_or_null(^"WorldLook")
	if look != null:
		look.call("apply_time", "day")
		look.set_process(false)
		look.set_physics_process(false)
	else:
		print("FAIL: no WorldLook; the light will drift between moments")


func _stage_the_trainer() -> void:
	var spot := Vector3(STAGE.x, 0.0, STAGE.y)
	spot.y = float(_world.call("ground_height_at", spot.x, spot.z)) + 1.0
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	await _await_physics(SETTLE_FRAMES, "trainer settle")


func _deploy_the_creature() -> bool:
	if _director.call("ally_instance") == null:
		await _director.call("adopt_starter", "terrapup")
	var game := root.get_node_or_null(^"/root/Game")
	var party: RefCounted = game.get("party") if game != null else null
	var instance: RefCounted = _director.call("ally_instance")
	if party != null and instance != null and (party.call("members") as Array).is_empty():
		party.call("add", instance)
	_creature = instance
	_body = _director.call("ally_body") as Node3D
	if _body == null:
		print("FAIL: no follower body; there is no companion to photograph")
		return false
	_presence = _body.call("presence") if _body.has_method("presence") else null
	if _presence == null:
		print("FAIL: the follower has no Presence layer; this tool has no subject")
		return false
	await _await_physics(SETTLE_FRAMES, "creature settle")
	return true


## Waits (in real physics frames, so the creature actually walks) for the
## layer to enter `state`, up to `limit` frames. Prints what it got.
func _wait_for_state(state: String, limit: int) -> bool:
	for i in limit:
		_frames += 1
		await physics_frame
		if str(_presence.call("state")) == state:
			print("[state] '%s' after %d frames" % [state, i + 1])
			return true
	print("FAIL: '%s' did not start within %d frames (state='%s', blocked='%s')" % [
		state, limit, str(_presence.call("state")), str(_presence.call("blocked_reason"))])
	return false


func _shoot_acknowledgment() -> void:
	print("")
	print("=== 01 acknowledgment: the trainer stands still and the creature comes to them ===")
	_player.velocity = Vector3.ZERO
	# The still-delay is the layer's own; wait it out in real frames rather
	# than forcing the state, so what is photographed is the real trigger.
	if not await _wait_for_state("acknowledge", 900):
		return
	# Let the walk-up finish so the frame shows the creature AT the trainer.
	for i in 90:
		_frames += 1
		await physics_frame
		if str(_presence.call("state")) != "acknowledge":
			break
	_aim_at_the_creature()
	await _shoot_pair("01-acknowledgment")


func _shoot_hurt() -> void:
	print("")
	print("=== 02 hurt: the same creature at 15% HP ===")
	_creature.set("hp", float(_creature.get("max_hp")) * 0.15)
	# Walk the trainer a few metres so the creature follows at its hurt gait
	# and the frame is a moving creature, not a posed one.
	var away := _player.global_position + Vector3(6.0, 0.0, 0.0)
	away.y = float(_world.call("ground_height_at", away.x, away.z)) + 1.0
	_player.global_position = away
	for i in 60:
		_frames += 1
		await physics_frame
	if not bool(_presence.call("is_hurt")):
		print("FAIL: the layer does not report the creature as hurt; 02 will not show what its name says")
	_aim_at_the_creature()
	await _shoot_pair("02-hurt")
	_creature.set("hp", float(_creature.get("max_hp")))


func _shoot_camp() -> void:
	print("")
	print("=== 03 camp: beside a real lit campfire ===")
	var fire: Node3D = CAMPFIRE.new()
	fire.name = "CompanionCampfire"
	_world.add_child(fire)
	# Between the creature and the camera's eye, so the fire is IN the shot:
	# round 1 put it behind the lens and the critic saw "a two-centimetre
	# sliver of orange at the very bottom edge, cropped by the HUD".
	var toward := _body.global_position - _player.global_position
	toward.y = 0.0
	toward = toward.normalized() if toward.length() > 0.1 else Vector3.FORWARD
	var spot := _player.global_position + toward * 3.0 \
		+ toward.rotated(Vector3.UP, PI * 0.5) * 2.2
	spot.y = float(_world.call("ground_height_at", spot.x, spot.z))
	fire.global_position = spot
	fire.call("build_real")
	# The creature has to STOP before it can settle -- the layer does not even
	# scan for a camp while it is closing the gap -- so give it real frames.
	for i in 120:
		_frames += 1
		await physics_frame
		if bool(_presence.call("is_camp_near")):
			break
	if not bool(_presence.call("is_camp_near")):
		print("FAIL: the campfire is not seen as a camp source; 03 will not show a rest pose")
	for i in 240:
		_frames += 1
		await physics_frame
		if bool(_presence.call("is_camped")):
			print("[state] camped after %d frames" % (i + 1))
			break
	if not bool(_presence.call("is_camped")):
		print("FAIL: the creature never settled at the camp within 240 frames")
	_aim_at_the_creature()
	await _shoot_pair("03-camp")


## The real CameraRig, yawed onto the creature from the trainer's own eye --
## the view the player has of their companion, not a survey camera.
func _aim_at_the_creature() -> void:
	if _body == null or not is_instance_valid(_body):
		return
	var to := _body.global_position - _player.global_position
	to.y = 0.0
	if to.length() < 0.01:
		return
	_rig.set("yaw", atan2(-to.x, -to.z))


## A pair, `PAIR_SECONDS` of reaction apart, with the tree paused so the pose
## does not move under the shutter. The layer is ticked by hand between the
## two exposures: an exact interval, repeatable, and cheap.
func _shoot_pair(name: String) -> void:
	var was_paused := paused
	paused = true
	await _await_process(RENDER_SETTLE_FRAMES, "render settle A for %s" % name)
	var a := await _screenshot("%s/%s-a.png" % [OUT_DIR, name])
	var ticks := int(PAIR_SECONDS / PAIR_TICK)
	for i in ticks:
		_presence.call("tick", PAIR_TICK)
	# Advance the creature's own AnimationPlayer by hand as well. The pause that
	# makes a sub-second pose photographable also stops the idle, and round 1
	# paid for that: the hurt and camp pairs came back PIXEL-IDENTICAL and a
	# code-blind critic correctly called the creature "a prop, not a companion"
	# on that evidence. The continuous states (hurt, camp) hold a fixed pose
	# over a playing clip, so without this the instrument could only ever show
	# life in the states that move the pivot.
	_advance_animation(PAIR_SECONDS)
	await _await_process(RENDER_SETTLE_FRAMES, "render settle B for %s" % name)
	var b := await _screenshot("%s/%s-b.png" % [OUT_DIR, name])
	paused = was_paused
	if a != null and b != null:
		print("[pair] %s: %.3f%% of pixels differ across %.2fs of reaction" % [
			name, _difference_percent(a, b), PAIR_SECONDS])


## Steps the creature's AnimationPlayer forward while the tree is paused, at
## whatever speed scale the presence layer has set on it (a resting or hurt
## creature idles slower, and the pair should show that rather than hide it).
func _advance_animation(seconds: float) -> void:
	if _body == null or not is_instance_valid(_body):
		return
	var pivot: Node3D = _body.call("model_pivot") as Node3D
	if pivot == null:
		return
	var players: Array[Node] = pivot.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		print("FAIL: the creature has no AnimationPlayer; the pair cannot show it moving")
		return
	var player := players[0] as AnimationPlayer
	print("[anim] '%s' advanced %.2fs at speed x%.2f" % [
		player.current_animation, seconds, player.speed_scale])
	player.advance(seconds * player.speed_scale)


## Fraction of pixels that changed between two frames, as a percentage. The
## number a still cannot give: a creature looping an idle and a creature
## mid-reaction differ here, and a frozen one does not.
func _difference_percent(a: Image, b: Image) -> float:
	if a.get_size() != b.get_size():
		return -1.0
	var changed := 0
	var total := 0
	# Every fourth pixel in each direction: 16x cheaper, same answer to two
	# decimal places on a 1280x720 frame.
	for y in range(0, a.get_height(), 4):
		for x in range(0, a.get_width(), 4):
			total += 1
			var pa := a.get_pixel(x, y)
			var pb := b.get_pixel(x, y)
			if absf(pa.r - pb.r) + absf(pa.g - pb.g) + absf(pa.b - pb.b) > 0.02:
				changed += 1
	return 0.0 if total == 0 else 100.0 * float(changed) / float(total)


func _screenshot(path: String) -> Image:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		print("FAIL %s: the viewport returned no image" % path)
		_failed += 1
		return null
	if image.save_png(path) != OK:
		print("FAIL %s: save_png" % path)
		_failed += 1
		return null
	print("shot: %s" % path)
	_written += 1
	return image


func _await_physics(n: int, label: String) -> void:
	for i in n:
		_frames += 1
		print("[frame %4d] %s (%d/%d)" % [_frames, label, i + 1, n])
		await physics_frame


func _await_process(n: int, label: String) -> void:
	for i in n:
		_frames += 1
		print("[frame %4d] %s (%d/%d)" % [_frames, label, i + 1, n])
		await process_frame


func _report() -> void:
	print("")
	print("=== companion moments: %d frames, %d shots written, %d failed ===" % [
		_frames, _written, _failed])
