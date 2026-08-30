extends SceneTree

## T1-VILLAGERS, 2026-08-30. Evidence for the body-allocation rebalance: the
## village square and the Team Tether cast, in the real Meadows, on real grass,
## at the distance a player actually stands to read a face.
##
## Two things are being photographed, and they need different framings:
##
## 1. THE SQUARE, from a standing player's eye at conversation range. The
##    question is whether the named cast (Mira, Tam, Oskar, Bram) reads as
##    specific people or as two meshes repainted, standing next to walk-ons
##    that each got their own body.
## 2. THE TETHER CAST, as a rank ladder. Two questions at once, and one can
##    hide the other: rank must read at a glance (badge/palette ladder) AND
##    two officers must stop being the same person. A lineup answers both in
##    one frame in a way four separate portraits cannot.
##
## `tools/capture_check.gd` runs at every shutter -- this project has committed
## whole rounds of evidence shot without the grass field, and the frames do not
## say so themselves. Its known hole (a camera below the terrain passed it once)
## is covered by eyeballing every frame, not by trusting the check.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_t1_villagers.gd
##
## NEVER --headless alongside a real rendering driver.
##
## `--stage` picks which set to shoot, so a re-render of one half does not pay
## for the other half's four-minute scene stand-up twice:
##
##   --stage=square   the village square only
##   --stage=tether   the Team Tether cast only
##   --stage=all      both (default)

const NPC := preload("res://scripts/npc/npc_body.gd")
const TRAINER_NPC := preload("res://scripts/world/trainer_npc.gd")
const CAPTURE_CHECK := preload("res://tools/capture_check.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
## Overridable with `--out=<res:// dir>` so the same tool shoots the before and
## the after state into separate folders on either side of the data change,
## from the same camera rules. A rebalance is only arguable against a matched
## pair of frames.
var OUT_DIR := "res://ralph/reports/T1-VILLAGERS/shots"

## ~4s/physics_frame under xvfb+llvmpipe with this scene's full scatter/grass
## load. Same figure `_capture_t1_variants_inworld.gd` measured on this box.
const SETTLE_FRAMES := 120
const POSE_FRAMES := 12

## Conversation range. `village_npcs.gd::add_prompt` offers its "Greet <name>"
## prompt at 3.8m, so this is the distance the player is standing at the moment
## they are actually looking at this person's face -- not a portrait distance
## chosen to flatter the model.
const TALK_RANGE := 3.8
const EYE_HEIGHT := 1.62
## Chest, not eyes: framing on the eye line crops the costume, and the costume
## is what this pass is about.
const LOOK_HEIGHT := 1.25

## The named cast the player deals with all chapter, then the walk-ons standing
## in the same square, so the comparison is inside one frame set at one range.
const SQUARE_SUBJECTS := [
	{"npc": "Mira", "file": "mira"},
	{"npc": "Tam", "file": "tam"},
	{"npc": "Oskar", "file": "oskar"},
	{"npc": "Bram", "file": "bram"},
	{"npc": "Sela", "file": "sela"},
	{"npc": "Quarry Foreman", "file": "quarry-foreman"},
	{"npc": "Wilhelm", "file": "walkon-wilhelm-innkeeper"},
	{"npc": "Ada", "file": "walkon-ada-craftsperson"},
	{"npc": "Garrick", "file": "walkon-garrick-farmer"},
	{"npc": "Old Perrin", "file": "walkon-perrin-historian"},
]

## The rank ladder plus the two officers the allocation question is about.
## `base` is the per-trainer override `npc_ranks.gd::config_for` reads; "" takes
## the rank's own default body.
const TETHER_LINEUP := [
	{"label": "grunt", "rank": "grunt", "base": ""},
	{"label": "officer-dell", "rank": "officer", "base": "officer_a"},
	{"label": "officer-ness", "rank": "officer", "base": "officer_b"},
	{"label": "captain", "rank": "captain", "base": "captain_a"},
	{"label": "warden", "rank": "warden", "base": ""},
]
const LINEUP_GAP := 1.35
## Further back than TALK_RANGE: five bodies shoulder to shoulder do not fit in
## a 48-degree frame at conversation distance, and the rank read this frame is
## testing is a read-across-a-clearing read anyway, not a read-in-conversation
## one.
const LINEUP_RANGE := 8.4

var _world: Node = null
var _camera: Camera3D = null
var _spawned: Array = []


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run under xvfb-run")
		quit(1)
		return

	var stage := "all"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--stage="):
			stage = arg.substr("--stage=".length())
		elif arg.begins_with("--out="):
			OUT_DIR = arg.substr("--out=".length())

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var boot_start := Time.get_ticks_msec()
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
		if i % 20 == 0:
			print("[t1-villagers] settle frame %d/%d (%.1fs)" % [
				i, SETTLE_FRAMES, (Time.get_ticks_msec() - boot_start) / 1000.0])
	print("[t1-villagers] Meadows stood up (%.1fs)" % ((Time.get_ticks_msec() - boot_start) / 1000.0))

	_camera = Camera3D.new()
	_world.add_child(_camera)
	_camera.fov = 48.0
	_camera.make_current()

	# The HUD is a real part of the game and belongs in gameplay evidence, but
	# this pass is about faces and costumes: the minimap, the objective card and
	# the party strip between them cover most of the right half of a 1280x800
	# frame, and the first round put the "Get up" prompt across a villager's
	# chest. Hidden for these shots only.
	_hide_hud()
	# Both of these were caught by `capture_check.gd` on the first framed round,
	# which is the entire reason that file exists. Neither is cosmetic:
	# Terrain3D streams LOD around whatever camera it was handed, so a capture
	# camera that never registers itself photographs terrain resolved for a
	# gameplay camera standing somewhere else; and a weather node still ticking
	# drifts the sky and light between the first shot of a pass and the last,
	# which would make a before/after pair disagree for a reason that has
	# nothing to do with the bodies in it.
	_pin_terrain_and_weather()
	# The player avatar spawns in the square and stood between the camera and
	# two subjects in the first round. Parked well outside the village rather
	# than freed, so nothing that holds a reference to it breaks mid-run.
	_park_player()

	if stage == "all" or stage == "square":
		await _shoot_square()
	if stage == "all" or stage == "tether":
		await _shoot_tether()

	print("Frames written to %s" % OUT_DIR)
	quit(0)


# --- the square -------------------------------------------------------------

## By name across the whole world, not by path under a holder. There is more
## than one node in this scene answering `placed()` (villagers AND trainers),
## so picking "the holder" by duck-typing picks whichever comes first in the
## tree -- which on the first run was the trainer holder, and every villager
## lookup under it missed.
func _find_body(display_name: String) -> Node3D:
	var hits := _world.find_children(display_name, "", true, false)
	for node in hits:
		if node is Node3D and node.has_method("setup_from_config"):
			return node as Node3D
	return hits[0] as Node3D if not hits.is_empty() and hits[0] is Node3D else null


func _shoot_square() -> void:
	var names: Array[String] = []
	for node in _world.find_children("*", "", true, false):
		if node.has_method("setup_from_config"):
			names.append(node.name)
	print("[t1-villagers] NPC bodies in the scene (%d): %s" % [names.size(), ", ".join(names)])

	# The square wide shot first, so the individual portraits below are read
	# against the group they actually stand in. The centroid of everyone
	# standing in the square, shot from outside it -- the first round aimed at
	# Mira from a fixed offset and got a house.
	var square_bodies: Array[Node3D] = []
	for subject: Dictionary in SQUARE_SUBJECTS:
		var found := _find_body(str(subject["npc"]))
		if found != null:
			square_bodies.append(found)
	if not square_bodies.is_empty():
		var centre := Vector3.ZERO
		for b in square_bodies:
			centre += b.global_position
		centre /= float(square_bodies.size())
		await _shoot_from(centre + Vector3(-2.0, 0.0, 19.0), centre, "00-village-square-wide")

	for subject: Dictionary in SQUARE_SUBJECTS:
		var body := _find_body(str(subject["npc"]))
		if body == null:
			print("[t1-villagers] MISSING villager '%s'" % subject["npc"])
			continue
		await _shoot_from(_stand_for(body), body.global_position, "square-%s" % subject["file"])


# --- the tether cast --------------------------------------------------------

func _shoot_tether() -> void:
	for node in _spawned:
		if is_instance_valid(node):
			node.queue_free()
	_spawned.clear()
	await process_frame

	# The open north field the practice trainer stands in: real grass, real
	# light, and a 22m vegetation clearing so a tree does not stand in the
	# lineup.
	var centre := Vector3(13.0, 0.0, 9.0)
	centre.y = _ground(centre)
	# Lay the row across the camera's view, not along it.
	var right := Vector3.RIGHT
	var camera_at := centre + Vector3(0.0, 0.0, LINEUP_RANGE)

	for i in TETHER_LINEUP.size():
		var entry: Dictionary = TETHER_LINEUP[i]
		var cfg := TRAINER_NPC.model_config({"rank": entry["rank"], "base": entry["base"]})
		if cfg.is_empty():
			print("[t1-villagers] FAIL no config for %s" % entry["label"])
			continue
		var body: Node3D = NPC.new()
		body.name = "T1Villagers_%s" % entry["label"]
		_world.add_child(body)
		if not bool(body.call("setup_from_config", cfg, null)):
			print("[t1-villagers] FAIL body build for %s" % entry["label"])
			body.queue_free()
			continue
		var at := centre + right * ((i - (TETHER_LINEUP.size() - 1) / 2.0) * LINEUP_GAP)
		if not bool(body.call("stand_at", at.x, at.z)):
			print("[t1-villagers] FAIL no ground under %s" % entry["label"])
		# Face the camera, which is on +Z from the row.
		body.rotation.y = 0.0
		_spawned.append(body)

	for i in POSE_FRAMES:
		await physics_frame

	await _shoot_from(camera_at, centre, "10-tether-rank-ladder")

	# Then the two officers alone at conversation range, which is the frame the
	# "two characters, one body" question is actually decided in.
	for i in TETHER_LINEUP.size():
		var entry: Dictionary = TETHER_LINEUP[i]
		if i >= _spawned.size():
			break
		var body: Node3D = _spawned[i]
		if not is_instance_valid(body):
			continue
		await _shoot_from(
			body.global_position + Vector3(0.0, 0.0, TALK_RANGE),
			body.global_position,
			"11-tether-%s" % entry["label"])


# --- shutter ----------------------------------------------------------------

func _hide_hud() -> void:
	var hidden := 0
	for node in _world.find_children("*", "CanvasLayer", true, false):
		(node as CanvasLayer).visible = false
		hidden += 1
	for node in root.find_children("*", "CanvasLayer", true, false):
		(node as CanvasLayer).visible = false
		hidden += 1
	print("[t1-villagers] hid %d HUD layer(s) for these frames" % hidden)


func _pin_terrain_and_weather() -> void:
	# By CLASS, not by name, for the same reason `capture_check.gd::_find_terrain`
	# does it that way: `playground_world.gd` names its instance "Terrain", so a
	# by-name lookup for "Terrain3D" silently finds nothing.
	for node in _world.find_children("*", "", true, false):
		if node.get_class() == "Terrain3D":
			node.call("set_camera", _camera)
			print("[t1-villagers] terrain now streaming around the capture camera")
			break
	for node in _world.find_children("WorldWeather", "", true, false):
		node.set_process(false)
		print("[t1-villagers] pinned WorldWeather for the pass")
		break


func _park_player() -> void:
	for node in _world.find_children("*", "", true, false):
		if node.is_in_group("player") and node is Node3D:
			(node as Node3D).global_position = Vector3(0.0, -400.0, 600.0)
			print("[t1-villagers] parked the player avatar out of frame")
			return


## Where to stand to see this person. The first round shot four subjects from
## behind and one from inside a wall, because it trusted the NPC's own
## `facing_deg` and nothing else: a villager posed to face a building has the
## player standing in that building.
##
## So the angle is chosen, not assumed. Candidates sweep the full circle from
## the NPC's own front, and the first one with an unobstructed line to the
## chest wins -- which is also, in practice, the side the player can actually
## walk up to them from.
func _stand_for(body: Node3D) -> Vector3:
	var chest := body.global_position + Vector3(0.0, LOOK_HEIGHT, 0.0)
	# +basis.z, NOT -basis.z. Godot's own convention is that -Z is forward, but
	# these rigs are authored facing +Z and imported with `model_yaw: 0.0`, so
	# the engine convention is the wrong one to trust here. Established by
	# render, not by reading: the Tether lineup below poses its bodies at
	# `rotation.y = 0` and shoots them from +Z, and those frames show faces. The
	# first two rounds of this tool used -basis.z and photographed the backs of
	# four villagers' heads.
	var front := body.global_transform.basis.z
	var space: PhysicsDirectSpaceState3D = _world.get_world_3d().direct_space_state
	# The subject's OWN colliders, so the sightline test is not failed by the
	# person it is testing the sightline to. npc_body.gd builds its collider as
	# a child, so excluding `body` itself is not enough -- that is what sent
	# every candidate angle to the fallback and stood the camera in a wall.
	var mine: Array[RID] = []
	for node in body.find_children("*", "CollisionObject3D", true, false):
		mine.append((node as CollisionObject3D).get_rid())
	if body is CollisionObject3D:
		mine.append((body as CollisionObject3D).get_rid())

	# Range is searched as well as angle, because some of this cast is INDOORS.
	# Mira is the case that forced it: OF31 moved the merchant behind her own
	# counter inside cottage_a, so every 3.8m stand around her is on the far
	# side of a wall and the first framed round photographed the inside of that
	# wall at 1280x800. Stepping in to 2.4m puts the camera in the room with
	# her, which is also where the player stands to use the shop.
	#
	# Full range first at every angle, then closer -- an outdoor villager is
	# still shot at conversation distance, and only someone with no clear line
	# at 3.8m gets the tighter framing.
	var ranges: Array[float] = [TALK_RANGE, 2.9, 2.4]
	var turns: Array[float] = [0.0, 30.0, -30.0, 60.0, -60.0, 90.0, -90.0, 130.0, -130.0, 180.0]
	for range_m in ranges:
		# 0 first, so a villager whose front IS clear is shot from the front.
		for turn in turns:
			var dir := front.rotated(Vector3.UP, deg_to_rad(turn))
			var stand := body.global_position + dir * range_m
			var eye := stand
			eye.y = _ground(stand) + EYE_HEIGHT
			# Cast OUT from the chest, so a camera that ended up inside a
			# building is rejected by the wall between them rather than missed
			# because the ray started on the far side of it.
			var query := PhysicsRayQueryParameters3D.create(chest, eye)
			query.exclude = mine
			var hit: Dictionary = space.intersect_ray(query)
			if hit.is_empty():
				if range_m < TALK_RANGE:
					print("[t1-villagers] '%s' has no clear line at %.1fm; shot at %.1fm" % [
						body.name, TALK_RANGE, range_m])
				return stand
	print("[t1-villagers] no clear angle on '%s' at any range; shooting the front anyway" % body.name)
	return body.global_position + front * TALK_RANGE


func _shoot_from(stand: Vector3, target: Vector3, file: String) -> void:
	var eye := stand
	eye.y = _ground(stand) + EYE_HEIGHT
	var look := target
	look.y = _ground(target) + LOOK_HEIGHT
	_camera.global_position = eye
	_camera.look_at(look, Vector3.UP)
	for i in 4:
		await physics_frame

	var problems := CAPTURE_CHECK.warn_only(self, _camera)
	if not problems.is_empty():
		print("[t1-villagers] %s: capture_check flagged %d issue(s) -- see above" % [
			file, problems.size()])

	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "%s/%s.png" % [OUT_DIR, file]
	if image == null or image.save_png(path) != OK:
		print("FAIL %s" % path.get_file())
		return
	print("wrote %s (capture_check %s)%s" % [
		path.get_file(),
		"clean" if problems.is_empty() else "FLAGGED",
		_measure(image, look)])


## Mean luminance of the torso as RENDERED, not as authored. The number this
## project has been arguing about (Team Tether bodies "at about 30.6/255 in
## daylight") is only meaningful measured off a real daylight frame at a real
## viewing distance, so it is taken at the shutter, from the same image being
## written, in the patch the camera is already aimed at.
func _measure(image: Image, chest: Vector3) -> String:
	if _camera.is_position_behind(chest):
		return ""
	var at := _camera.unproject_position(chest)
	var half := 14
	var x0 := int(clampf(at.x - half, 0.0, float(image.get_width() - 1)))
	var x1 := int(clampf(at.x + half, 0.0, float(image.get_width() - 1)))
	var y0 := int(clampf(at.y - half, 0.0, float(image.get_height() - 1)))
	var y1 := int(clampf(at.y + half, 0.0, float(image.get_height() - 1)))
	if x1 <= x0 or y1 <= y0:
		return ""
	var total := 0.0
	var count := 0
	for y in range(y0, y1):
		for x in range(x0, x1):
			var c := image.get_pixel(x, y)
			# Rec. 709, on the sRGB values a player's monitor actually shows.
			total += 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			count += 1
	if count == 0:
		return ""
	return "  torso luma %.1f/255 (%d px at chest)" % [total / count * 255.0, count]


func _ground(at: Vector3) -> float:
	if _world != null and _world.has_method("ground_height_at"):
		return float(_world.call("ground_height_at", at.x, at.z))
	return 0.0
