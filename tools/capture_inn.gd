extends SceneTree

## R7.9's own blind-critique render: exterior, doorway approach and interior
## frames of the inn, and nothing else in the settlement.
##
## Windows production command (real Compatibility renderer; no --headless):
##   & 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe' `
##     --path . --rendering-driver opengl3 --resolution 1280x720 `
##     --script tools/capture_inn.gd
##
## Deliberately NOT tools/capture_buildings.gd's whole-settlement survey.
## ralph/NOTES.md's own R7.8 record: a narrowly-scoped visual check is both
## faster to write and immune to the world's coming relocation if the camera
## reads its framing off the actually-placed node's own global_transform
## rather than a hand-typed world coordinate. `village.json`'s `at`/`yaw_deg`
## for the inn are read here only to FIND the placed node by name prefix
## (the same way smoke_traversal.gd's own VILLAGE_DOOR_PREFABS check does);
## every camera position below is derived from that node's live transform and
## its interior's own `bar_position()`, never from a second copy of the
## coordinate.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/BROAD-VISUAL-0910/INN-COMMON-ROOM-R10"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const NPC_TRACK_FRAMES := 72
const FOV := 70.0


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

	var hud: CanvasLayer = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false
	# Water's warning tint is intentionally not part of PlaygroundHUD. A static
	# capture camera can outlive player setup/respawn transitions and would then
	# photograph that full-screen blue/red warning instead of the location. This
	# proof is about the Inn, so suppress the feedback layer explicitly just as
	# we suppress the ordinary HUD above.
	var submersion_overlay := world.find_child("SubmersionOverlay", true, false) as CanvasLayer
	if submersion_overlay != null:
		submersion_overlay.visible = false

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var look: Node = world.get_node_or_null(^"WorldLook")
	if look != null:
		look.call("apply_time", "day")
		# Software-rendered frames take long enough that the passive world clock
		# can walk a nominal day proof into sunset before the interior views. Pin
		# the authored preset for the whole batch, as the canonical location
		# capture does, so lighting changes are judged at the time in the filename.
		if look.has_method("set_clock_frozen"):
			look.call("set_clock_frozen", true)

	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var inn := _find_inn(world)
	if inn == null:
		push_error("no placed 'inn_*' node under Village; nothing to shoot")
		quit(1)
		return

	var interior: Node3D = inn.get_node_or_null(^"Interior") as Node3D
	var door_local := Vector3(0.0, 0.0, 5.0) # building_prefabs.json's own inn.door.at
	var door_global: Vector3 = inn.to_global(door_local)
	var bar_global: Vector3 = interior.call("bar_position") if interior != null else inn.global_position

	# The capture owns its camera, so hide the player without relocating them.
	# Parking a disabled CharacterBody hundreds of metres below the world still
	# leaves the world's water hazard free to read that position; over a long
	# software-rendered batch it advances into the red drowning overlay and
	# contaminates every later frame. The opening spawn is safe, and visibility
	# is all this harness needed to suppress in the first place.
	if player != null:
		player.visible = false
		player.set_process(false)
		player.set_physics_process(false)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	var front_offset := Vector3(0, 0, 1).rotated(Vector3.UP, inn.rotation.y)
	var side_offset := Vector3(1, 0, 0).rotated(Vector3.UP, inn.rotation.y)

	var viewpoints: Array[Dictionary] = [
		{
			"name": "01-inn-exterior-front",
			"eye": inn.global_position + front_offset * 11.0 - side_offset * 2.5 + Vector3(0, 1.9, 0),
			"target": inn.global_position + Vector3(0, 3.0, 0),
		},
		{
			"name": "02-inn-exterior-corner",
			"eye": inn.global_position + front_offset * 9.0 - side_offset * 8.0 + Vector3(0, 2.0, 0),
			"target": inn.global_position + Vector3(0, 3.0, 0),
		},
		{
			"name": "03-inn-doorway",
			"eye": door_global + front_offset * 6.0 + Vector3(0, 1.6, 0),
			"target": door_global + Vector3(0, 1.4, 0),
		},
		{
			# A customer-side, speaking-distance proof of Bram and the whole bar
			# identity together. The previous overview left him tiny and could not
			# verify the corrected facing direction from the actual production rig.
			"name": "04-inn-bram-bar",
			"eye": door_global.lerp(bar_global, 0.62) + Vector3(0, 1.62, 0),
			"target": bar_global + Vector3(0, 1.25, 0),
		},
		{
			# R7.9 round 3: the first two passes of this viewpoint shifted eye
			# AND target by the same side offset, which is a parallel slide,
			# not a turn -- the camera kept looking straight down the
			# bar-to-door axis and never actually turned toward the guest
			# tables sitting off that axis at local x=+-1.5. Framed here in
			# the room's own local space (inn.to_global(), the same seam
			# bar_position()/door_global already use) from near the door,
			# looking back across both tables toward the bar.
			"name": "05-inn-interior-tables",
			"eye": inn.to_global(Vector3(0.58, 2.0, 3.95)),
			"target": inn.to_global(Vector3(0.42, 0.95, 0.25)),
			"fov": 64.0,
		},
		{
			# A three-quarter patron-height proof aimed across the table surfaces
			# and central route. The broad overview cannot establish whether the
			# fitted runners, serving pieces and place settings actually read as
			# table-scale occupation rather than foreground clutter.
			"name": "06-inn-table-service",
			"eye": inn.to_global(Vector3(0.30, 1.85, 4.12)),
			"target": inn.to_global(Vector3(0.52, 0.66, 1.05)),
			"fov": 64.0,
		},
	]

	var records: Array[Dictionary] = []
	var failures: Array[String] = []

	# Both clocks matter inside too: Bram's face, the visible candle and the
	# localized hospitality light all need proof after the common-room balance
	# change. This is twelve frames total (six compositions x two times).
	for time: String in ["day", "night"]:
		if look != null:
			look.call("apply_time", time)
			if look.has_method("set_clock_frozen"):
				look.call("set_clock_frozen", true)
		for i in 24:
			await physics_frame
		for entry: Variant in viewpoints:
			var view: Dictionary = entry
			var base_name: String = str(view["name"])
			var name := "%s-%s" % [base_name, time]
			camera.fov = float(view.get("fov", FOV))
			camera.global_position = view["eye"]
			camera.look_at(view["target"], Vector3.UP)

			# NPCBody tracks the actual Player inside 22m. A hidden player left at
			# spawn is therefore not inert: Bram turns toward that off-camera ghost
			# and presents his back no matter which authored rest yaw is tested.
			# Seat the hidden, physics-disabled player on verified live ground at
			# the patron camera's x/z so production tracking shows the face an
			# actual customer sees. This is ordinary runtime behavior, not a pose
			# injection; the player's y is always a real ground sample.
			if player != null:
				var patron_ground := float(world.call("ground_height_at",
					camera.global_position.x, camera.global_position.z))
				if is_nan(patron_ground):
					failures.append("%s: no live ground under patron camera" % name)
					continue
				player.global_position = Vector3(camera.global_position.x,
					patron_ground + 0.05, camera.global_position.z)

			for i in NPC_TRACK_FRAMES:
				await physics_frame
			for i in POSE_FRAMES:
				await process_frame
			await RenderingServer.frame_post_draw

			var image := root.get_texture().get_image()
			if image == null:
				failures.append("%s: viewport returned no image" % name)
				continue

			var path := "%s/%s.png" % [OUT_DIR, name]
			var error := image.save_png(path)
			if error != OK:
				failures.append("%s: save_png failed (%d)" % [name, error])
				continue

			records.append({
				"frame": name,
				"time": time,
				"image_size": [image.get_width(), image.get_height()],
				"camera_global": [camera.global_position.x, camera.global_position.y, camera.global_position.z],
			})
			print("  %-32s -> %s" % [name, path])

	var manifest := {
		"schema_version": 1,
		"production_scene": SCENE,
		"named_location": "The Village Inn / Bram",
		"fixture_disclosure": "Production Meadows scene and authored village NPCs. Fixed camera only; authored day/night clock frozen, HUD and independent SubmersionOverlay hidden. Player is hidden/physics-disabled and seated on verified live ground at each patron camera x/z so production NPCBody tracking faces the actual viewer rather than an off-camera spawn ghost. No NPC pose, progress, encounter, weather or lighting injection.",
		"expected_frame_count": viewpoints.size() * 2,
		"complete": failures.is_empty() and records.size() == viewpoints.size() * 2,
		"frames": records,
		"failures": failures,
		"capture_finished_utc": Time.get_datetime_string_from_system(true),
	}
	var manifest_file := FileAccess.open("%s/manifest.json" % OUT_DIR, FileAccess.WRITE)
	if manifest_file == null:
		failures.append("manifest could not be written")
	else:
		manifest_file.store_string(JSON.stringify(manifest, "\t") + "\n")
		manifest_file.close()

	print("")
	print("%d frames -> %s" % [records.size(), OUT_DIR])
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")

	if not failures.is_empty():
		print("")
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


## The inn is built at runtime by village.gd from village.json's `structures`
## list; its node name is "inn_<index>", the same naming convention
## smoke_traversal.gd's own VILLAGE_DOOR_PREFABS check relies on.
func _find_inn(world: Node) -> Node3D:
	var village: Node = world.get_node_or_null(^"Village")
	if village == null:
		return null
	for child in village.get_children():
		if (child as Node).name.begins_with("inn_"):
			return child as Node3D
	return null
