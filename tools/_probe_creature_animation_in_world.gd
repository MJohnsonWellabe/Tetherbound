extends SceneTree

## DO THE CREATURES ACTUALLY MOVE IN THE REAL WORLD?
##
##   godot --headless --path . --script tools/_probe_creature_animation_in_world.gd
##
## T1-RIG-3. The lane before this one (`ralph/T1-CREATURE-RIG`) rigged the five
## new creature meshes and proved it with two kinds of evidence, neither of
## which is the one that matters: a Blender-side posed render
## (`blender/pose_check.py`), and `tools/preview_creatures.gd`, which stages a
## species alone on an empty stage. Both can pass while the creature stands
## frozen in the shipping world — a stale import cache, a species.json clip
## name that does not match the pack, or an animator that is built but never
## ticked would all look identical in those two tools and identical to a
## statue in the Meadows.
##
## So this boots `meadows_playground.tscn` itself, spawns each species through
## the real `encounter_director.spawn_wild()` path, and then asks the only
## question that settles it: **does a bone move between one frame and the
## next?** Not "is there an AnimationPlayer", not "is a clip named idle
## present", not "did play() get called" — a real skeleton pose delta, sampled
## off the live node in the live world.
##
## Headless and unrendered on purpose. Animation is driven by the physics/
## process tick, not by drawing, so this needs no viewport and costs none of
## the render throughput this container is desperately short of (see
## `ralph/reports/handover-T1-CREATURE-RIG-2026-08-30.md`'s note on llvmpipe).
## Rendered frames are still required as evidence and are a separate tool's
## job; this is the instrument that says WHERE to point them.

const SCENE := "res://scenes/world/meadows_playground.tscn"

## The five this lane owns, plus two controls. The controls matter: if
## `terrapup` (an original, long-shipping, known-animating creature) also reads
## as frozen, the fault is in this probe or in the world, not in the five.
const SUBJECTS := [
	"sparkit",
	"cindercub",
	"shadelet",
	"frostclaw",
	"bramblebun",
]
const CONTROLS := ["terrapup", "pipwing"]

const SETTLE_FRAMES := 90
## Long enough for a cross-fade (0.15s) to finish and a slow idle to travel a
## measurable distance, short enough to keep the whole run inside a minute.
const SAMPLE_FRAMES := 60
## A bone that moves less than this across the whole sample window is not
## animating; it is numerical noise on a static pose. Metres.
const MOVED_EPSILON := 0.0005

var _world: Node = null
var _director: Node = null
var _player: Node3D = null
var _rows: Array[Dictionary] = []


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_director = _world.get_node_or_null(^"EncounterDirector")
	_player = _world.get_node_or_null(^"Player") as Node3D
	if _director == null or _player == null:
		print("FATAL: scene is missing EncounterDirector or Player")
		quit(1)
		return

	for species in CONTROLS:
		await _measure(species, true)
	for species in SUBJECTS:
		await _measure(species, false)

	_report()
	quit(0)


## Spawn one species beside the player and watch its skeleton.
##
## Measured twice, because the two failure modes are different and a creature
## can have one without the other: standing still (does the IDLE clip play?)
## and under a real movement request (does locomotion resolve, and does the
## body's own speed reach the animator?).
func _measure(species: String, is_control: bool) -> void:
	var spot := _player.global_position + Vector3(6.0, 0.0, 6.0)
	var wild: Node3D = _director.call("spawn_wild", species, spot, {
		"name": "Probe_%s" % species,
	}) as Node3D
	if wild == null:
		_rows.append({"species": species, "control": is_control, "error": "spawn_wild returned null"})
		return

	# Let the model instantiate and the animator get built and start a clip.
	for i in 10:
		await physics_frame

	var row := {
		"species": species,
		"control": is_control,
		"has_model": bool(wild.get("_has_model")),
		"animator": wild.get("_animator") != null,
	}

	var player_node := _find_animation_player(wild)
	row["animation_player"] = player_node != null
	if player_node != null:
		row["clips"] = player_node.get_animation_list().size()

	var skeleton := _find_skeleton(wild)
	row["skeleton"] = skeleton != null
	if skeleton != null:
		row["bones"] = skeleton.get_bone_count()

	# --- idle: no movement requested at all ---
	row["idle_clip"] = ""
	row["idle_motion"] = 0.0
	if skeleton != null:
		var before := _pose_signature(skeleton)
		for i in SAMPLE_FRAMES:
			await physics_frame
		row["idle_motion"] = _pose_delta(before, _pose_signature(skeleton))
		if player_node != null:
			row["idle_clip"] = player_node.current_animation
			row["idle_playing"] = player_node.is_playing()

	# --- locomotion: drive it the way the game's own AI drives it ---
	row["walk_clip"] = ""
	row["walk_motion"] = 0.0
	if skeleton != null:
		var before_walk := _pose_signature(skeleton)
		for i in SAMPLE_FRAMES:
			wild.call("request_move", Vector3(1.0, 0.0, 0.0))
			await physics_frame
		row["walk_motion"] = _pose_delta(before_walk, _pose_signature(skeleton))
		if player_node != null:
			row["walk_clip"] = player_node.current_animation
			row["walk_playing"] = player_node.is_playing()

	# --- the combat one-shots ---
	#
	# Locomotion is only two of the six roles the game drives. `combat_manager`
	# pokes `play_attack`/`play_hit`/`play_faint` on the body for the other
	# three, and a creature that idles and walks correctly can still stand
	# frozen through every swing it throws — which is the half of "moves in the
	# real game" a wander-and-look-at-it check would never reach.
	# PEAK deviation, not start-versus-end. A one-shot is a round trip: the
	# creature rears up, strikes, and settles back into the pose it started
	# from. Comparing only the two endpoints of the window scores a perfectly
	# good attack as zero motion whenever the clip finished and locomotion
	# resumed inside the sample — which is exactly what the first version of
	# this check did, and it reported `shadelet`'s hit as "drove no bones" on a
	# clip that drives bones fine. Sampling every frame and keeping the furthest
	# the skeleton ever got from where it started measures the swing itself.
	for role: String in ["attack", "hit", "faint"]:
		if skeleton == null:
			break
		wild.call("revive_animation")
		var before_shot := _pose_signature(skeleton)
		wild.call("play_%s" % role)
		var peak := 0.0
		var peak_clip := ""
		for i in SAMPLE_FRAMES:
			await physics_frame
			var here := _pose_delta(before_shot, _pose_signature(skeleton))
			if here > peak:
				peak = here
				if player_node != null:
					peak_clip = player_node.current_animation
		row["%s_motion" % role] = peak
		row["%s_clip" % role] = peak_clip
	wild.call("revive_animation")

	_rows.append(row)
	wild.queue_free()
	await physics_frame


func _find_animation_player(node: Node) -> AnimationPlayer:
	var found: Array[Node] = node.find_children("*", "AnimationPlayer", true, false)
	return null if found.is_empty() else found[0] as AnimationPlayer


func _find_skeleton(node: Node) -> Skeleton3D:
	var found: Array[Node] = node.find_children("*", "Skeleton3D", true, false)
	return null if found.is_empty() else found[0] as Skeleton3D


## Every bone's full local pose, in the skeleton's own space.
##
## Skeleton-local on purpose: the body is also walking across the terrain
## during the locomotion sample, and a global-space signature would report that
## translation as "the bones moved" even for a creature frozen in a rest pose
## being slid along the ground. That is exactly the false pass this probe
## exists to prevent.
##
## ROTATION, not just position — the first version of this probe sampled
## `get_bone_pose_position` alone and reported six of seven creatures frozen,
## including `terrapup`, which has animated correctly since it shipped. That
## was the probe being wrong, not the world: a skeletal clip animates bone
## ROTATION almost exclusively, and a rig whose bones only ever rotate has a
## bit-identical position signature in every frame of a perfectly good walk
## cycle. `pipwing` was the only creature that "passed" because a bird rig's
## wing clips happen to carry translation keys as well. Sampling the whole
## local transform is the fix; the control disagreeing with its own known
## history is what caught it.
func _pose_signature(skeleton: Skeleton3D) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for i in skeleton.get_bone_count():
		out.append(skeleton.get_bone_pose(i))
	return out


func _pose_delta(a: Array[Transform3D], b: Array[Transform3D]) -> float:
	if a.size() != b.size() or a.is_empty():
		return 0.0
	var total := 0.0
	for i in a.size():
		total += a[i].origin.distance_to(b[i].origin)
		# Basis columns cover rotation and scale together, which is what a clip
		# actually drives. Summed as three vector distances so one number can be
		# compared against one epsilon.
		for axis in 3:
			total += (a[i].basis[axis] - b[i].basis[axis]).length()
	return total


func _report() -> void:
	print("")
	print("=== CREATURE ANIMATION IN THE REAL WORLD (meadows_playground.tscn) ===")
	print("")
	print("species        ctl model anim aplr skel bone idle_move  idle_clip  walk_move  walk_clip")
	var failures: Array[String] = []
	for row in _rows:
		if row.has("error"):
			print("%-14s ERROR %s" % [row["species"], row["error"]])
			failures.append("%s: %s" % [row["species"], row["error"]])
			continue
		print("%-14s %-3s %-5s %-4s %-4s %-4s %-4s %9.4f  %-9s %9.4f  %-9s" % [
			row["species"],
			"y" if row["control"] else "-",
			"y" if row["has_model"] else "NO",
			"y" if row["animator"] else "NO",
			"y" if row["animation_player"] else "NO",
			"y" if row["skeleton"] else "NO",
			str(row.get("bones", 0)),
			row["idle_motion"],
			row["idle_clip"],
			row["walk_motion"],
			row["walk_clip"],
		])
		print("               combat one-shots: attack %.4f (%s)  hit %.4f (%s)  faint %.4f (%s)" % [
			row.get("attack_motion", 0.0), row.get("attack_clip", ""),
			row.get("hit_motion", 0.0), row.get("hit_clip", ""),
			row.get("faint_motion", 0.0), row.get("faint_clip", ""),
		])
		if float(row["idle_motion"]) < MOVED_EPSILON:
			failures.append("%s: IDLE pose never changed (frozen in world)" % row["species"])
		if float(row["walk_motion"]) < MOVED_EPSILON:
			failures.append("%s: LOCOMOTION pose never changed (frozen in world)" % row["species"])
		for role: String in ["attack", "hit", "faint"]:
			if float(row.get("%s_motion" % role, 0.0)) < MOVED_EPSILON:
				failures.append("%s: %s one-shot drove no bones (combat would show a statue)" % [
					row["species"], role.to_upper()])

	print("")
	if failures.is_empty():
		print("PASS — every species animates in the real world.")
	else:
		print("FAIL — %d problem(s):" % failures.size())
		for f in failures:
			print("  - %s" % f)
	print("")
