extends SceneTree

## Capture the real exploration HUD (the owner's Palworld-inspired layout,
## spec §6/§6.6) over live gameplay, for the visual critic loop. Loads the
## full meadows scene the way tools/survey.gd does (proven reliable under
## xvfb+opengl3 — the trap that once made a bespoke loader die silently was in
## the loader, not in loading this scene), but keeps PlaygroundHUD visible
## instead of hiding it, since the HUD is exactly what this is judging.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script tools/capture_exploration_hud.gd
##
## Five frames, per spec §6.6.6:
##   hud_full    - full HP/satiety, stamina arc hidden (idle, full)
##   hud_sprint  - stamina forced to 60% so the contextual arc shows
##   hud_lowstam - stamina forced to 8% (danger tier on the arc)
##   hud_hungry  - satiety forced to 20% -> "HUNGRY"
##   hud_lowhp   - health forced to 25% -> the HP bar's danger lerp + pulse
##
## Every frame seeds a small party and satchel directly through `Game`'s own
## public API (`make_pal`/`party.add`, the same calls `game_state.gd::
## _seed_demo` makes internally) rather than relying on the `--menu-demo`
## command-line flag this tool's own invocation does not pass — an
## unpopulated party would show nothing but "No pal out" and an all-vacant
## party strip, which is a real state but not the one worth judging the new
## layout against. No change to `autoload/game_state.gd` was needed for this.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/_diag"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 6
const VITALS_SETTLE_FRAMES := 30


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

	var written: Array[String] = []
	var failures: Array[String] = []

	# A three-quarter view over the player's shoulder, close enough that the
	# HUD's real screen-space scale is judged, not a tiny figure in a wide shot.
	var eye_xz := Vector2(-9.0, -4.0)
	var eye_h := 3.4
	camera.global_position = Vector3(eye_xz.x, field.height_at(eye_xz.x, eye_xz.y) + eye_h, eye_xz.y)
	player.global_position = Vector3(-15.0, field.height_at(-15.0, -1.0) + 0.4, -1.0)
	camera.look_at(player.global_position + Vector3.UP, Vector3.UP)

	for i in 20:
		await physics_frame

	var vitals: RefCounted = player.get("vitals") if player != null else null
	if vitals == null:
		failures.append("no player.vitals reachable -- cannot drive the vitals frames")
	else:
		# Movement/vitals ticking is driven from _physics_process, and with no
		# real input held it would fight every forced value back toward
		# whatever the controller thinks is correct within a physics step.
		# Freezing it is what makes a forced 60%/8%/20%/25% actually hold
		# still long enough to screenshot.
		player.set_physics_process(false)

	_seed_demo_state(world)

	if vitals != null:
		_reset_vitals(vitals)
		await _settle(VITALS_SETTLE_FRAMES)
		await _shoot(camera, "hud_full", written, failures)

		_reset_vitals(vitals)
		vitals.stamina = vitals.max_stamina * 0.6
		player.set("_sprinting", true) # best-effort; the arc shows regardless, stamina < 85%
		await _settle(VITALS_SETTLE_FRAMES)
		await _shoot(camera, "hud_sprint", written, failures)

		_reset_vitals(vitals)
		vitals.stamina = vitals.max_stamina * 0.08
		player.set("_sprinting", false)
		await _settle(VITALS_SETTLE_FRAMES)
		await _shoot(camera, "hud_lowstam", written, failures)

		_reset_vitals(vitals)
		vitals.satiety = vitals.max_satiety * 0.20
		await _settle(VITALS_SETTLE_FRAMES)
		await _shoot(camera, "hud_hungry", written, failures)

		_reset_vitals(vitals)
		vitals.health = vitals.max_health * 0.25
		await _settle(VITALS_SETTLE_FRAMES)
		await _shoot(camera, "hud_lowhp", written, failures)
	else:
		await _shoot(camera, "hud_full", written, failures)

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


## Back to a known-full baseline (health/stamina/satiety full, no buffs) plus
## one demo buff so every frame also exercises the vitals cluster's buff-chip
## row -- the one piece of vitals state none of the five named frames force on
## its own.
func _reset_vitals(vitals: RefCounted) -> void:
	vitals.health = vitals.max_health
	vitals.stamina = vitals.max_stamina
	vitals.satiety = vitals.max_satiety
	vitals.active_buffs.clear()
	vitals.active_buffs.append({
		"id": "berry_buff", "stat": "stamina_regen_scale", "amount": 1.1, "remaining_s": 999.0,
	})


## A party (one out, two more on the strip, one of them fainted) and a
## handful of satchel items, so the pal block, the party strip and the
## hotbar all have something real to draw. Every call here is public API
## `Game` already exposes -- no changes to `autoload/game_state.gd`.
func _seed_demo_state(world: Node) -> void:
	var game := root.get_node_or_null(^"/root/Game")
	if game == null:
		push_warning("Game autoload not found -- pal block/party strip/hotbar will show their empty states")
		return

	var inventory: RefCounted = game.get("inventory")
	if inventory != null:
		inventory.call("add", "wood", 40)
		inventory.call("add", "berries", 12)

	var party: RefCounted = game.get("party")
	if party == null or int(party.call("size")) > 0:
		return # already seeded (should not happen for a fresh boot, but idempotent)

	var seeds := [["terrapup", "Biscuit"], ["ripplet", ""], ["galewisp", "Kite"]]
	for entry in seeds:
		var pal: RefCounted = game.call("make_pal", str(entry[0]), str(entry[1]))
		if pal != null:
			party.call("add", pal)

	var active: RefCounted = party.call("at", 0)
	if active != null:
		active.take_damage(float(active.get("max_hp")) * 0.35)
		active.energy = 40.0

	var second: RefCounted = party.call("at", 1)
	if second != null:
		second.take_damage(float(second.get("max_hp"))) # fainted, for the strip's dim/danger state


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
	print("  %-16s -> %s" % [name, path])
