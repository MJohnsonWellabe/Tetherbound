extends SceneTree

## T1-RIG-2. Do the five newly-rigged creatures actually move IN THE MEADOWS?
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_capture_t1_rig2_meadows.gd
##
## NEVER add `--headless` alongside the rendering driver -- that combination
## hangs forever with no error (`docs/AGENT_WORKFLOW.md`, "Art pipeline traps
## already paid for", and `tools/_capture_creature_roster.gd`'s own header).
##
## WHY NOT A PREVIEW SCENE. `tools/preview_creatures.gd` and
## `tools/art_pipeline/blender/pose_test.py` both answer "does this rig deform",
## and the previous rig lane leaned on that pair because a full-world capture
## would not finish in its container. Neither can answer the question
## that decides whether this work shipped: a creature that plays an idle in an
## isolated stage and stands frozen in the Meadows is not rigged as far as the
## player is concerned. The animator is built in `creature_body._build_animator`
## from `species.json`'s own `animations` block and driven by
## `creature_body._physics_process` off the body's real speed -- none of which a
## bare preview stage exercises the way a wild creature wandering real terrain
## does. So this boots `meadows_playground.tscn`, spawns the five through
## `encounter_director.spawn_wild()` (its own docstring: "there is no second
## kind of wild creature"), and photographs them there.
##
## WHAT IT PROVES, AND HOW. Two independent kinds of evidence, because a
## render alone cannot distinguish "animating" from "a still creature shot
## twice", and a number alone is not a picture of the game:
##
##   1. PNG frames of the real world -- real terrain, real grass, real light --
##      through CAPTURE_CHECK.require, so a frame that silently lost the grass
##      field aborts the run instead of being committed as evidence
##      (`tools/capture_check.gd`, JUDGE-3 section 0).
##   2. A per-shot pose signature per creature: the summed translation of every
##      bone in its Skeleton3D, plus the clip its AnimationPlayer is on and how
##      far through that clip it is. A frozen creature reports the same
##      signature at every shot; an animating one does not. Written to
##      motion.json beside the frames so the claim is checkable without
##      eyeballing two PNGs.
##
## The pass/fail line is in `_verdict()`: every one of the five must change its
## pose signature across the idle sequence AND report a real clip name. That is
## deliberately stricter than "has an AnimationPlayer", which is what
## `smoke_art.gd` checks and what the pre-rig meshes already failed.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const CAPTURE_CHECK := preload("res://tools/capture_check.gd")
const OUT := "res://ralph/reports/T1-RIG-2/shots"

## The five meshes this lane rigged. `bramblebun` names the species, whose
## model this lane repointed at the redesign mesh; the other four are their own
## species ids.
const SPECIES_IDS := ["sparkit", "cindercub", "shadelet", "frostclaw", "bramblebun"]

## Open ground in Band 1's own spawn data (`data/config/bands/
## band1_lower_meadows/spawns.json`, the "open_basin" habitat cluster). Chosen
## because it is open meadow: the point of shooting here rather than on a road
## or in the village is that the grass field has to be in the frame for
## CAPTURE_CHECK to be able to tell us anything.
const BASIN := Vector2(-432.2, 485.5)

## Metres between neighbouring creatures on the line, and how far the eye stands
## back from its centre. Run 1 used 3.2m at 13m and 55 degrees and put the two
## end creatures outside the frame; these numbers are that run's measurement,
## not another guess.
const SPACING := 2.9
const STANDOFF := 11.0
const EYE_HEIGHT := 2.1
const GROUP_FOV := 64.0

## The close pass. One creature filling the frame is the only way to see whether
## a rig tears -- the group shot is where they are in the world, not what their
## surface is doing.
##
## Both numbers are multiples of the creature's OWN measured bounds rather than
## fixed metres. Run 2 used a fixed 3.6m standoff at a fixed 0.9m eye and
## produced two unusable frames out of five: these species run 0.85m (sparkit)
## to 2.0m (frostclaw), so one distance cannot frame all of them, and a 0.9m eye
## is *inside* a grass field that stands about a metre tall -- the frostclaw
## frame is mostly blades with the animal above the top of them.
const CLOSE_SIZE_MULTIPLE := 2.3
const CLOSE_FOV := 50.0
## Grass here is roughly a metre. An eye below this is shooting through the
## field rather than over it, whatever the creature's own height suggests.
const CLOSE_MIN_EYE := 1.35

## Where in the attack clip to hold the close frames. 0.35 is into the committed
## part of the swing and short of the recovery, which is where a skinning defect
## shows worst. The walk fraction is a quarter cycle past the contact pose, so
## the legs are at their widest rather than passing under the body.
const ATTACK_FRACTION := 0.35
const WALK_FRACTION := 0.25

const SPECIES_FILE := "res://data/creatures/species.json"

const BOOT_FRAMES := 40
## Game time between shots in a sequence. 20 physics frames is a third of a
## second -- enough that a walk cycle has visibly moved on, short enough that
## five llvmpipe frames per shot stay affordable in a software-rendered
## container (see the previous rig lane's handover on this box's throughput).
const GAP_FRAMES := 20
const POSE_FRAMES := 3

## Toward the camera and slightly across it. A creature walking straight away
## from the eye shows almost none of its gait; walking straight across it slides
## out of a 64-degree frame within one sequence at this standoff. Closing the
## distance means the two locomotion shots also read as movement on their own,
## without the reader having to trust that two similar frames are different.
const HEADING := Vector3(0.25, 0.0, -1.0)


var _world: Node = null
var _camera: Camera3D = null
var _creatures: Array[Node3D] = []
var _report: Dictionary = {"shots": [], "species": SPECIES_IDS}
var _failures := 0
var _driving := false
## Per creature, `species.json`'s own role -> clip-name map. Read from the data
## rather than assuming the clip is called what the role is called: that mapping
## is exactly what `creature_animator` exists to indirect, and a tool that
## hard-codes it stops testing the thing the game does.
var _clips: Array[Dictionary] = []


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run this under xvfb-run, not --headless")
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for _i in BOOT_FRAMES:
		await physics_frame
	print("[rig2] world up")

	_hide_huds()
	await _pin_day()

	var director: Node = _find_director()
	if director == null:
		print("FAIL no EncounterDirector in the world; nothing here would be a real wild creature")
		quit(1)
		return

	if not _spawn_the_five(director):
		quit(1)
		return

	_seat_camera()
	# The camera rig owns the gameplay eye and will fight ours for `current`
	# every frame it processes.
	var rig: Node = _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)

	# Sequence 1 -- idle. Nothing is driving these bodies, so `creature_body`'s
	# own speed is zero and `creature_animator.tick` resolves to the idle clip.
	# Three shots: one still frame proves nothing, two consecutive ones do.
	for i in 3:
		await _shoot("idle-%d" % i, "idle")
		await _wait(GAP_FRAMES)

	# Sequence 2 -- locomotion. `request_move` is the same call the wild AI's
	# own wander and chase use; driving it directly means the walk/run branch of
	# `creature_animator.tick` is exercised on a known heading instead of
	# waiting for the wander RNG to happen to send them somewhere.
	#
	# The heading has to be re-issued through the SHUTTER, not just up to it.
	# Run 1 drove for 20 physics frames and then let three process frames pass
	# before the shutter: `creature_body._physics_process` consumes `_requested`
	# every tick, so speed had already decayed to zero by the time the frame was
	# taken and every creature reported the idle clip at position 0.0 -- a
	# locomotion shot with no locomotion in it. `_driving` keeps the call going
	# during the pose frames.
	#
	# Two shots, and they answer different questions on purpose. `walk-live` is
	# the honest uncontrolled one: whatever each creature's animator resolved
	# from its own real speed at the shutter. Some of the five report `idle`
	# there and that is not a rig failure -- a body walked into a bush or a
	# terrain lip has a real speed of zero, `creature_animator.tick` correctly
	# calls that standing still, and run 3 caught exactly that on two of five.
	# `walk-held` then pins every one of them to the same point of its own walk
	# clip so the five walk cycles can be compared in one frame, the same
	# seek-and-pause the attack frames use.
	_driving = true
	await _drive(GAP_FRAMES)
	await _shoot("walk-live", "locomotion")
	await _drive(GAP_FRAMES)
	# The hold only survives if the body's own tick is off first. Run 4 seeked
	# and paused the walk clip and then let three process frames pass with the
	# creature still ticking: `creature_body._physics_process` ran
	# `creature_animator.tick`, measured a real speed of zero for a body pressed
	# against a bush, and played idle straight over the paused pose. Four of the
	# five held frames came out as idle at position 0. Same discipline as
	# `_attack_shot`, which had already learned this.
	_driving = false
	for creature in _creatures:
		creature.set_physics_process(false)
	await _hold_clip("walk", WALK_FRACTION)
	await _shoot("walk-held", "locomotion")
	_resume()
	for creature in _creatures:
		creature.set_physics_process(true)

	# Sequence 3 -- the combat one-shot. `play_attack` is what
	# `combat_manager.gd` calls on a real swing, so this is the clip the player
	# sees in a fight rather than a clip name read out of a file.
	await _attack_shot("attack")

	# The close pass, one creature at a time, held at its attack pose. This is
	# where a rig failure would actually be visible: the group frame is about
	# where these creatures are, this is about what their surface does when the
	# skeleton is at its most extreme. It is also the check on this lane's own
	# `repair_unweighted` change -- cindercub and frostclaw are the two meshes
	# whose stray vertices used to bind to the exporter's static `neutral_bone`,
	# and a band across the chest left behind by a rearing body is exactly the
	# artefact these frames would show.
	for i in _creatures.size():
		_seat_camera_close(_creatures[i])
		await _attack_shot("close-%s" % SPECIES_IDS[i])

	_verdict()
	quit(1 if _failures > 0 else 0)


## Every creature, its clip, and a number that changes if and only if its
## skeleton moved. Summing bone origins is crude on purpose: it cannot be
## fooled by a body that translated without deforming (the bones are read in
## the skeleton's own space, not the world's) and it needs no reference pose to
## compare against.
func _pose_signature(creature: Node3D) -> Dictionary:
	var out := {"clip": "", "position": 0.0, "bones": 0, "signature": 0.0, "paused": false}
	var skeletons: Array[Node] = creature.find_children("*", "Skeleton3D", true, false)
	if not skeletons.is_empty():
		var skeleton := skeletons[0] as Skeleton3D
		var total := 0.0
		for bone in skeleton.get_bone_count():
			var pose := skeleton.get_bone_global_pose(bone)
			total += pose.origin.x + pose.origin.y * 2.0 + pose.origin.z * 3.0
			total += pose.basis.get_euler().length()
		out["bones"] = skeleton.get_bone_count()
		out["signature"] = snappedf(total, 0.000001)
	var player := _player_of(creature)
	if player != null:
		# `current_animation` empties while the player is PAUSED, which is how
		# the held frames are taken -- run 3's attack rows all read as a blank
		# clip for that reason alone. `assigned_animation` survives the pause
		# and is the honest answer to "what is this creature posed on".
		out["clip"] = player.current_animation
		if out["clip"] == "":
			out["clip"] = player.assigned_animation
		out["paused"] = not player.is_playing()
		out["position"] = snappedf(player.current_animation_position, 0.001)
	return out


## Start the attack clip on every creature and photograph it mid-swing.
##
## The wild AI has to be held off for the length of the shot, and that is a real
## behaviour rather than a convenience: `creature_animator.cancel_hold` exists
## so that a creature driven under its own power is never left frozen on a
## finished one-shot, and `wild_creature._wander` keeps issuing small moves even
## at a zero wander radius. Run 1 left the AI ticking and two of the five had
## already been pulled back onto `walk` by the time the shutter opened. In a
## real fight the swing is not cancelled that way -- the attacker is rooted for
## its wind-up (`wild_creature.is_rooted`) -- so freezing the AI here shows the
## pose the player actually sees, not one this tool invented.
## The pose is then HELD by seeking the clip and pausing it, which is the only
## way to get a repeatable frame here: an `AnimationPlayer` advances on real
## elapsed time, and a single llvmpipe frame in this container costs seconds, so
## run 2's attack clip (0.96s long) ran to its end during the three pose frames
## for four of the five close-ups and photographed the recovery instead of the
## swing. Seeking is not staging a pose the game cannot reach -- it is the
## game's own clip, on the game's own player, stopped at a frame the player
## passes through every time a creature swings.
func _attack_shot(tag: String) -> void:
	for creature in _creatures:
		creature.set_physics_process(false)
		creature.call("play_attack")
	await _wait(2)
	await _hold_clip("attack", ATTACK_FRACTION)
	await _shoot(tag, "attack")
	_resume()
	for creature in _creatures:
		creature.set_physics_process(true)


## Pin every creature to the same point of the named clip and stop there.
##
## The clip name is resolved through `species.json`'s own role map, the same way
## `creature_animator._resolve` does at runtime, so this cannot photograph a
## clip the game would never pick.
func _hold_clip(role: String, fraction: float) -> void:
	for i in _creatures.size():
		var player := _player_of(_creatures[i])
		if player == null:
			continue
		var clip := str(_clips[i].get(role, ""))
		if clip == "" or not player.has_animation(clip):
			continue
		if player.assigned_animation != clip:
			player.play(clip)
		player.seek(player.get_animation(clip).length * fraction, true)
		player.pause()
	await physics_frame


func _resume() -> void:
	for creature in _creatures:
		var player := _player_of(creature)
		if player != null:
			player.play()


func _player_of(creature: Node3D) -> AnimationPlayer:
	var players: Array[Node] = creature.find_children("*", "AnimationPlayer", true, false)
	return players[0] as AnimationPlayer if not players.is_empty() else null


func _shoot(tag: String, phase: String) -> void:
	for _i in POSE_FRAMES:
		if _driving:
			for creature in _creatures:
				creature.call("request_move", HEADING)
		await process_frame
	await RenderingServer.frame_post_draw

	# Last thing before the shutter: refuse to write a frame that silently lost
	# a rendering system. A creature-animation claim made against a frame with
	# no grass in it is exactly the kind of evidence JUDGE-3 section 0 threw out.
	CAPTURE_CHECK.require(self, _camera)

	var entry := {"tag": tag, "phase": phase, "creatures": {}}
	for i in _creatures.size():
		entry["creatures"][SPECIES_IDS[i]] = _pose_signature(_creatures[i])
	_report["shots"].append(entry)

	var image := root.get_texture().get_image()
	if image == null:
		print("  FAIL %s: viewport returned no image" % tag)
		_failures += 1
		return
	var path := "%s/%s.png" % [OUT, tag]
	if image.save_png(path) != OK:
		print("  FAIL %s: save_png" % tag)
		_failures += 1
		return
	print("  wrote %s  (%s)" % [path.get_file(), phase])


func _wait(frames: int) -> void:
	for _i in frames:
		await physics_frame


## Hold a heading for `frames` physics ticks. `request_move` is per-frame by
## design -- `creature_body._physics_process` consumes and clears it -- so this
## has to re-issue it every tick, the same as the wild AI does.
func _drive(frames: int) -> void:
	for _i in frames:
		for creature in _creatures:
			creature.call("request_move", HEADING)
		await physics_frame


func _spawn_the_five(director: Node) -> bool:
	var field := HEIGHTFIELD.new(HEIGHTFIELD.load_config())
	var species: Dictionary = {}
	var file := FileAccess.open(SPECIES_FILE, FileAccess.READ)
	if file != null:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(parsed) == TYPE_DICTIONARY:
			species = (parsed as Dictionary).get("species", {})
	var left := -SPACING * (SPECIES_IDS.size() - 1) * 0.5
	for i in SPECIES_IDS.size():
		var id: String = SPECIES_IDS[i]
		var at := Vector2(BASIN.x + left + SPACING * i, BASIN.y)
		var spot := Vector3(at.x, float(field.height_at(at.x, at.y)) + 0.5, at.y)
		var body: Node3D = director.call("spawn_wild", id, spot, {
			"name": "Rig2_%s" % id,
			"level": 5,
			"aggressive": false,
			# Keep them on their marks: the point of the arc is that five
			# creatures are all legible in one frame, and a 7m wander radius
			# would have them out of shot by the second sequence.
			"wander_radius": 0.0,
		}) as Node3D
		if body == null:
			print("FAIL spawn_wild('%s') returned nothing" % id)
			_failures += 1
			return false
		# Face the eye. A wild creature spawns on whatever yaw its body script
		# last set, and run 1 photographed five backs -- true to the world, and
		# useless for judging a rig.
		body.look_at(Vector3(body.global_position.x, body.global_position.y,
			BASIN.y - STANDOFF), Vector3.UP)
		_creatures.append(body)
		var placeholder: Dictionary = (species.get(id, {}) as Dictionary).get("placeholder", {})
		_clips.append(placeholder.get("animations", {}))
		print("  spawned %-12s at (%.0f, %.1f, %.0f)" % [id, spot.x, body.global_position.y, spot.z])
	return true


func _seat_camera() -> void:
	var field := HEIGHTFIELD.new(HEIGHTFIELD.load_config())
	var eye_xz := BASIN + Vector2(0.0, -STANDOFF)
	var eye := Vector3(eye_xz.x, float(field.height_at(eye_xz.x, eye_xz.y)) + EYE_HEIGHT, eye_xz.y)
	if _camera == null:
		_camera = Camera3D.new()
		_camera.far = 2000.0
		_world.add_child(_camera)
	_camera.fov = GROUP_FOV
	_camera.global_position = eye
	_camera.look_at(Vector3(BASIN.x, eye.y - 1.1, BASIN.y), Vector3.UP)
	_camera.make_current()
	_bind_terrain()


## Fill the frame with one creature, framed from what it actually measures in
## the world rather than from a fixed distance and a guessed eye height.
func _seat_camera_close(creature: Node3D) -> void:
	var box := _visual_bounds(creature)
	var floor_y := box.position.y
	# Clamped because a skinned mesh's own AABB is the bind-pose bound, not the
	# posed one, and a creature carrying a VFX child reports a box far larger
	# than its body. Run 4 took its standoff straight off that number and put the
	# lens metres back, behind a grass field, looking at nothing.
	var height := clampf(box.size.y, 0.6, 2.6)
	var centre := Vector3(box.get_center().x, floor_y + height * 0.55, box.get_center().z)
	var standoff := clampf(height * CLOSE_SIZE_MULTIPLE, 2.2, 6.0)
	var eye := centre + Vector3(-0.55, 0.0, -1.0).normalized() * standoff
	# Above the grass and looking slightly down. Sparkit is 0.85m in a field that
	# stands about a metre: any eye at its own shoulder height photographs
	# blades, which is what runs 2 and 4 both did.
	eye.y = floor_y + maxf(height * 1.15, CLOSE_MIN_EYE)
	_camera.fov = CLOSE_FOV
	_camera.global_position = eye
	_camera.look_at(centre, Vector3.UP)
	_camera.make_current()
	_bind_terrain()
	print("    close: bounds h=%.2f standoff=%.2f eye_y=%.2f floor=%.2f" % [
		height, standoff, eye.y, floor_y])


## The union of every drawn MESH under this creature, in world space. Its
## `global_position` alone says nothing about how big it is or where its body
## sits relative to its origin, and these five span 0.85m to 2.0m. Meshes only:
## a `GPUParticles3D` or a decal is a `VisualInstance3D` too, and its bound is
## the effect's volume rather than the animal's.
func _visual_bounds(creature: Node3D) -> AABB:
	var box := AABB(creature.global_position, Vector3.ZERO)
	var first := true
	for node in creature.find_children("*", "MeshInstance3D", true, false):
		var visual := node as MeshInstance3D
		if not visual.visible or visual.mesh == null:
			continue
		var world := visual.global_transform * visual.get_aabb()
		box = world if first else box.merge(world)
		first = false
	return box


func _bind_terrain() -> void:
	# Terrain3D streams to whichever camera it was told about; the grass field
	# now redirects itself (`grass_field.gd::_follow_camera`), which is what
	# CAPTURE_CHECK verifies rather than assumes.
	var terrain: Node = _world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", _camera)


func _find_director() -> Node:
	var direct: Node = _world.get_node_or_null(^"EncounterDirector")
	if direct != null:
		return direct
	for node in _walk(_world):
		if node.has_method("spawn_wild"):
			return node
	return null


func _pin_day() -> void:
	var weather: Node = _world.get_node_or_null(^"WorldWeather")
	if weather != null:
		weather.call("set_weather", "clear")
	var look: Node = _world.get_node_or_null(^"WorldLook")
	if look != null:
		look.call("apply_time", "day")
	for _i in 20:
		await physics_frame
	if look != null:
		look.set_process(false)
		look.set_physics_process(false)
	if weather != null:
		weather.set_process(false)
		weather.set_physics_process(false)


func _hide_huds() -> void:
	for node in _walk(_world):
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false


func _walk(from: Node) -> Array[Node]:
	var out: Array[Node] = []
	var stack: Array[Node] = [from]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		out.append(node)
		stack.append_array(node.get_children())
	return out


## The claim this tool exists to make, stated as a pass or a failure per
## species rather than left for a reader to infer from two PNGs.
func _verdict() -> void:
	var idle: Array = _report["shots"].filter(func(s): return s["phase"] == "idle")
	print("\n[rig2] verdict -- did each creature's skeleton move in the Meadows?")
	for id: String in SPECIES_IDS:
		var signatures: Array[float] = []
		var clips: Array[String] = []
		for shot: Dictionary in idle:
			var entry: Dictionary = shot["creatures"][id]
			signatures.append(float(entry["signature"]))
			if not clips.has(str(entry["clip"])):
				clips.append(str(entry["clip"]))
		var moved := false
		for value in signatures:
			if not is_equal_approx(value, signatures[0]):
				moved = true
		var named: bool = not clips.is_empty() and clips[0] != ""
		if moved and named:
			print("  PASS %-12s clip=%s  signatures=%s" % [id, ", ".join(clips), str(signatures)])
		else:
			_failures += 1
			print("  FAIL %-12s %s  clip=%s  signatures=%s" % [
				id,
				"pose never changed" if not moved else "no clip playing",
				", ".join(clips), str(signatures)])

	var path := "%s/motion.json" % OUT
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_report, "  "))
		file.close()
		print("[rig2] wrote %s" % path)
	print("[rig2] %d failure(s)" % _failures)
