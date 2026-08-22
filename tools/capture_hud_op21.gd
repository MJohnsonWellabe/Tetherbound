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

## HUD-LAYOUT: 240 -> 60. `ralph/conventions.md` and this project's own
## CLAUDE.md task headers both name this exact cold-boot cost as the
## dominant bottleneck for this tool -- 129k scattered props settling under
## software (llvmpipe) rendering, worse still under CI/container CPU
## contention with sibling lanes -- and both say to prefer a lighter render
## over eating the multi-minute (measured: 40+ minute) cost. This capture
## only needs the HUD layer settled and the player/camera posed, not full
## terrain physics convergence; 60 frames was enough in practice for both
## shots to read cleanly. Raise it again if a future capture shows visible
## settling artifacts (props still falling, water not leveled) that 240 was
## masking.
const SETTLE_FRAMES := 60
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

	# OP21-glyphs: simulate an Ally session, not an empty headless one. This
	# harness ran with NO joypad attached, so `game_state.gd::_last_input_was_gamepad`
	# initialised false (`not Input.get_connected_joypads().is_empty()`, and
	# the list is empty here) and every `input_glyph.gd::icon()` call fell back
	# to keyboard keycaps for the whole capture -- a real Ally player, pad
	# already connected at boot, gets `true` on frame one and never sees a
	# keycap at all (see that field's own header comment: "Starts true if a pad
	# is already connected"). `Input.get_connected_joypads()` reflects real OS
	# device enumeration and cannot be faked in a headless container, but
	# injecting one real `InputEventJoypadButton` reproduces the state that
	# matters -- `_last_input_was_gamepad` only cares about event TYPE, not
	# device connectivity, so this is not a hack around the check, it is the
	# same signal a physical A-button tap would send.
	var press := InputEventJoypadButton.new()
	press.device = 0
	press.button_index = JOY_BUTTON_A
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventJoypadButton.new()
	release.device = 0
	release.button_index = JOY_BUTTON_A
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame

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
		# One process frame so `playground_hud.gd::_process` (which polls,
		# does not react to a signal) actually notices the revision change and
		# calls `flash_cycle()` before the shot -- the previous version of
		# this harness settled straight into the shot from the SAME awaited
		# frame the property changed on, which on some frame-ordering runs
		# caught the banner not-yet-drawn. `CYCLE_BANNER_SECONDS` is 1.3s
		# (~78 frames at 60fps); this still fires the shot well inside that
		# window, just after (not possibly before) the banner text lands.
		await process_frame
		await _settle(20)
		_diagnose_cycle_banner(world)
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


## HUD-LAYOUT: root-causing "the cycle banner works in an isolated harness
## but never appears in the real full-world capture" (CLAUDE.md task header).
## Walks the real mounted `PlaygroundHUD` for the party strip's cycle banner
## and prints every state that could hide a Control that is otherwise
## logically "showing" -- visibility (local AND resolved-through-ancestors,
## since those can disagree the moment ANY ancestor is hidden or faded),
## alpha at every level of the chain up to the viewport, its computed global
## rect against the actual viewport rect (an off-screen position is invisible
## for a reason no visibility flag would ever show), and sibling draw order
## (a later sibling always wins the same pixels).
func _diagnose_cycle_banner(world: Node) -> void:
	var hud := world.get_node_or_null(^"PlaygroundHUD")
	if hud == null:
		print("[diag] PlaygroundHUD not found under world")
		return
	var strip: Node = hud.get_node_or_null(^"Root/PartyStrip")
	if strip == null:
		print("[diag] Root/PartyStrip not found -- party strip did not mount")
		return
	var banner: Node = null
	for child in strip.get_children():
		if child is RichTextLabel:
			banner = child
			break
	if banner == null:
		print("[diag] party strip has no RichTextLabel child (cycle banner) to inspect")
		return

	var banner_ctrl := banner as Control
	var strip_ctrl := strip as Control
	print("[diag] cycle banner: visible=%s in_tree_visible=%s text=%s" % [
		banner_ctrl.visible, banner_ctrl.is_visible_in_tree(), banner_ctrl.text,
	])
	print("[diag] cycle banner: local rect=%s global rect=%s modulate=%s" % [
		Rect2(banner_ctrl.position, banner_ctrl.size), banner_ctrl.get_global_rect(), banner_ctrl.modulate,
	])
	print("[diag] party strip: visible=%s in_tree_visible=%s position=%s modulate=%s z_index=%s sibling_index=%d of %d" % [
		strip_ctrl.visible, strip_ctrl.is_visible_in_tree(), strip_ctrl.position, strip_ctrl.modulate,
		strip_ctrl.z_index, strip_ctrl.get_index(), strip_ctrl.get_parent().get_child_count(),
	])

	var viewport_rect := root.get_visible_rect()
	print("[diag] viewport rect=%s  banner inside viewport=%s" % [
		viewport_rect, viewport_rect.intersects(banner_ctrl.get_global_rect()),
	])

	# Walk every ancestor up to the CanvasLayer, printing anything that could
	# suppress a logically-visible child -- a hidden or near-zero-alpha
	# ancestor is invisible even while the child itself reports true/1.0.
	var node: Node = strip
	while node != null and not (node is CanvasLayer):
		if node is CanvasItem:
			var ci := node as CanvasItem
			print("[diag] ancestor %s (%s): visible=%s modulate=%s" % [
				node.name, node.get_class(), ci.visible, ci.modulate,
			])
		node = node.get_parent()
	if node is CanvasLayer:
		print("[diag] CanvasLayer %s: layer=%d" % [node.name, (node as CanvasLayer).layer])

	# Sibling CanvasLayers -- a higher `layer` draws on top of everything in
	# a lower one, regardless of tree order within either.
	for sibling in world.get_children():
		if sibling is CanvasLayer:
			print("[diag] world CanvasLayer %s: layer=%d" % [sibling.name, (sibling as CanvasLayer).layer])
