extends SceneTree

## OP21-11/OP21-12 visual evidence. Two frames at the Ally's real panel
## resolution (1280x800), not the 1920x1080 authoring canvas everything else
## in `tools/` renders at:
##
##   hud_hotbar_legend - hotbar + the relocated, enlarged exploration legend
##   hud_party_cycle   - a real `cycle_active()` mid-transition, with
##                        `party_strip.gd`'s new OP21-12 banner showing
##
##   xvfb-run -a -s "-screen 0 1280x800x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/capture_hud_op21.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/_diag"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 6


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return

	var world: Node = packed.instantiate()
	root.add_child(world)

	for i in SETTLE_FRAMES:
		await physics_frame

	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	var field: RefCounted = HEIGHTFIELD.new()

	var camera := Camera3D.new()
	camera.fov = 70.0
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var eye_xz := Vector2(-9.0, -4.0)
	var eye_h := 3.4
	camera.global_position = Vector3(eye_xz.x, field.height_at(eye_xz.x, eye_xz.y) + eye_h, eye_xz.y)
	player.global_position = Vector3(-15.0, field.height_at(-15.0, -1.0) + 0.4, -1.0)
	camera.look_at(player.global_position + Vector3.UP, Vector3.UP)

	for i in 20:
		await physics_frame

	if player != null:
		player.set_physics_process(false)

	var party: RefCounted = _seed_demo_state(world)

	var written: Array[String] = []
	var failures: Array[String] = []

	await _settle(30)
	await _shoot(camera, "hud_hotbar_legend", written, failures)

	if party != null:
		# A real cycle through the live path, not a call into party_strip.gd
		# directly -- the HUD's own `_process` notices `Party.revision` change
		# the same way a real d-pad press would and fires `flash_cycle()`.
		party.call("cycle_active", 1)
		# Just past the reveal tween, well inside CYCLE_BANNER_SECONDS (1.3s
		# at 60fps ~= 78 frames) so the banner is caught mid-hold, not at the
		# instant it appears or after it has already faded.
		await _settle(20)
		await _shoot(camera, "hud_party_cycle", written, failures)

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")

	if not failures.is_empty():
		print("")
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


func _settle(frames: int) -> void:
	for i in frames:
		await process_frame


## Five real creatures (the strip's full five slots), one out and hurt, one
## fainted, so both the creature block and the party strip's dim/danger
## states have something real to draw -- and `cycle_active()` below has more
## than one eligible member to actually move between.
func _seed_demo_state(world: Node) -> RefCounted:
	var game := root.get_node_or_null(^"/root/Game")
	if game == null:
		push_warning("Game autoload not found -- HUD will show its empty states")
		return null

	var inventory: RefCounted = game.get("inventory")
	if inventory != null:
		inventory.call("add", "wood", 40)
		inventory.call("add", "berries", 12)

	var party: RefCounted = game.get("party")
	if party == null:
		return null
	if int(party.call("size")) > 0:
		return party

	var seeds := [
		["terrapup", "Biscuit"], ["ripplet", ""], ["galewisp", "Kite"],
		["mudsnout", ""], ["bramblebun", ""],
	]
	for entry in seeds:
		var creature: RefCounted = game.call("make_creature", str(entry[0]), str(entry[1]))
		if creature != null:
			party.call("add", creature)

	var active: RefCounted = party.call("at", 0)
	if active != null:
		active.take_damage(float(active.get("max_hp")) * 0.35)

	var third: RefCounted = party.call("at", 2)
	if third != null:
		third.take_damage(float(third.get("max_hp"))) # fainted, for the strip's dim/danger state

	return party


func _shoot(camera: Camera3D, name: String, written: Array[String], failures: Array[String]) -> void:
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		failures.append("%s: viewport returned no image" % name)
		return

	var path := "%s/%s.png" % [OUT_DIR, name]
	var error := image.save_png(path)
	if error != OK:
		failures.append("%s: save_png failed (%d)" % [name, error])
		return

	written.append(path)
	print("  %-20s -> %s" % [name, path])
